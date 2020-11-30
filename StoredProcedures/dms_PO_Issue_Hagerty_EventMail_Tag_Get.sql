 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_PO_Issue_Hagerty_EventMail_Tag_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_PO_Issue_Hagerty_EventMail_Tag_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC [dms_PO_Issue_Hagerty_EventMail_Tag_Get] 310520
 CREATE PROCEDURE [dbo].[dms_PO_Issue_Hagerty_EventMail_Tag_Get]( 
  @POID Int = NULL  
 ) 
 AS 
 BEGIN 

	DECLARE @Result TABLE(ColumnName NVARCHAR(MAX),
						  ColumnValue NVARCHAR(MAX)) 

	DECLARE @XmlString AS XML

	SET @XmlString = (
	SELECT m.ID AS MemberId
	
	, ISNULL(ms.MembershipNumber,'') AS MemberNumber
	
	, ISNULL(m.FirstName,'') + ' ' + ISNULL(m.LastName,'') AS MemberName

	, ISNULL(c.VehicleYear + ' ' + CASE WHEN c.VehicleMake = 'Other' THEN c.VehicleMakeOther ELSE c.VehicleMake END + ' ' + CASE WHEN c.VehicleModel = 'Other' THEN c.VehicleModelOther ELSE c.VehicleModel END,' ') AS MemberVehicleDesc -- coalesce 

	, ISNULL(c.ContactPhoneNumber,' ') AS MemberCallback 

	, sr.ID AS SRNumber

	, CONVERT (VARCHAR(20),sr.CreateDate,100) + ' CST' AS SRCallDateTime 

	, ISNULL(pc.Name,'  ') AS SRType

	, ISNULL(sr.ServiceLocationAddress,' ') AS SRLocation

	, ISNULL(sr.DestinationAddress,' ') AS SRDestination

	, ISNULL(po.PurchaseOrderNumber,' ') AS PONumber

	, CONVERT(VARCHAR(20),po.IssueDate,100) + ' CST' AS POIssueDateTime

	, ISNULL(v.Name,' ') AS POVendor

	, CONVERT(VARCHAR(20),ISNULL(po.ETAMinutes,' ')) + ' minutes' AS SRETA
	
	, ISNULL(m.ClientMemberType, ' ') AS ClientMemberType
	 
	, ISNULL(cl.Name,' ') AS Client
	
	, '888-310-8020' AS DispatchPhone
	
	, ISNULL(p.Name,' ')  AS ProgramName
	
	,ISNULL(p.Code,' ') AS ProgramCode
	
	,ISNULL(po.AdditionalInstructions,'') AS AdditionalInstructions
	
	FROM PurchaseOrder po (NOLOCK)

	JOIN ServiceRequest sr (NOLOCK) ON sr.ID = po.ServiceRequestID

	LEFT JOIN ProductCategory pc (NOLOCK) ON pc.ID = sr.ProductCategoryID

	JOIN [Case] c (NOLOCK) ON c.ID = sr.CaseID

	JOIN Member m (NOLOCK) ON m.ID = c.MemberID

	JOIN Membership ms (NOLOCK) ON ms.ID = m.MembershipID

	JOIN VendorLocation vl (NOLOCK) ON vl.ID = po.VendorLocationID

	JOIN Vendor v (NOLOCK) ON v.ID = vl.VendorID
	
	JOIN Program p (NOLOCK) ON c.ProgramID = p.ID
	
	JOIN Client cl (NOLOCK) ON cl.ID = p.ClientID
	WHERE po.ID = @POID FOR XML AUTO)

	INSERT INTO @Result(ColumnName,ColumnValue)
    SELECT CAST(x.v.query('local-name(.)') AS NVARCHAR(MAX)) As AttributeName,
			    x.v.value('.','NVARCHAR(MAX)') AttributeValue
    FROM @XmlString.nodes('//@*') x(v)
    ORDER BY AttributeName

	SELECT * FROM @Result

END