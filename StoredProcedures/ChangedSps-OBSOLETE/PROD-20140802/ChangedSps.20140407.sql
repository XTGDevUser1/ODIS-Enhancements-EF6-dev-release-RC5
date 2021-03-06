IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Call_Summary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Call_Summary]
GO

--EXEC dms_Call_Summary @serviceRequestID = 1314  
CREATE PROC dms_Call_Summary(@serviceRequestID INT = NULL)  
AS  
BEGIN 
	DECLARE @Hold TABLE(ColumnName NVARCHAR(MAX),ColumnValue NVARCHAR(MAX),DataType NVARCHAR(MAX),Sequence INT,GroupName NVARCHAR(MAX),DefaultRows INT NULL) 
DECLARE @ProgramDataItemValues TABLE(Name NVARCHAR(MAX),Value NVARCHAR(MAX),ScreenName NVARCHAR(MAX))       

;WITH wProgDataItemValues
AS
(
SELECT ROW_NUMBER() OVER ( PARTITION BY EntityID, RecordID, ProgramDataItemID ORDER BY CreateDate DESC) AS RowNum,
              *
FROM   ProgramDataItemValueEntity 
WHERE  RecordId = (SELECT CaseID FROM ServiceRequest WHERE ID=@serviceRequestID)
)

INSERT INTO @ProgramDataItemValues
SELECT 
        PDI.Name,
        W.Value,
        PDI.ScreenName
FROM   ProgramDataItem PDI
JOIN   wProgDataItemValues W ON PDI.ID = W.ProgramDataItemID
WHERE  W.RowNum = 1



	DECLARE @DocHandle int    
	DECLARE @XmlDocument NVARCHAR(MAX)   
	DECLARE @ProductID INT
	SET @ProductID = NULL
	SELECT  @ProductID = PrimaryProductID FROM ServiceRequest WHERE ID = @serviceRequestID

-- Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'

	SET FMTONLY OFF    
-- Sanghi : ISNull is required because generating XML will ommit the columns.     
-- Two Blank Space is required.  
	DECLARE @tmpServiceLocationVendor TABLE
	(
		Line1 NVARCHAR(100) NULL,
		Line2 NVARCHAR(100) NULL,
		Line3 NVARCHAR(100) NULL,
		City NVARCHAR(100) NULL,
		StateProvince NVARCHAR(100) NULL,
		CountryCode NVARCHAR(100) NULL,
		PostalCode NVARCHAR(100) NULL,
		
		TalkedTo NVARCHAR(50) NULL,
		PhoneNumber NVARCHAR(100) NULL,
		VendorName NVARCHAR(100) NULL
	)
	INSERT INTO @tmpServiceLocationVendor	
	SELECT	TOP 1	AE.Line1, 
					AE.Line2, 
					AE.Line3, 
					AE.City, 
					AE.StateProvince, 
					AE.CountryCode, 
					AE.PostalCode,
					cl.TalkedTo,
					cl.PhoneNumber,
					V.Name As VendorName
		FROM	ContactLogLink cll
		JOIN	ContactLog cl on cl.ID = cll.ContactLogID
		JOIN	ContactLogLink cll2 on cll2.contactlogid = cl.id and cll2.entityid = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest') and cll2.RecordID = @serviceRequestID
		JOIN	VendorLocation VL ON cll.RecordID = VL.ID
		JOIN	Vendor V ON VL.VendorID = V.ID 	
		JOIN	AddressEntity AE ON AE.RecordID = VL.ID AND AE.EntityID = (SELECT ID FROM Entity WHERE name = 'VendorLocation')
		WHERE	cll.entityid = (SELECT ID FROM Entity WHERE name = 'VendorLocation')
		AND		cl.ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ServiceLocationSelection')
		ORDER BY cll.id DESC
	

  
	SET @XmlDocument = (SELECT TOP 1    

-- PROGRAM SECTION
--	1 AS Program_DefaultNumberOfRows   
	cl.Name + ' - ' + p.name as Program_ClientProgramName    
    ,(SELECT 'Case Number:'+Value FROM @ProgramDataItemValues WHERE ScreenName='StartCall' AND Name='CaseNumber') AS Program_CaseNumber
    ,(SELECT 'Agent Name:'+Value FROM @ProgramDataItemValues WHERE ScreenName='StartCall' AND Name='AgentName') AS Program_AgentName
    ,(SELECT 'Claim Number:'+ Value FROM @ProgramDataItemValues WHERE ScreenName='StartCall' AND Name='ClaimNumber') AS Program_ClaimNumber
-- MEMBER SECTION
--	, 5 AS Member_DefaultNumberOfRows
-- KB : 6/7 : TFS # 1339 : Presenting Case.Contactfirstname and Case.ContactLastName as member name and the values from member as company_name when the values differ.	
   -- Ignore time while comparing dates here
    -- KB: Considering Effective and Expiration Dates to calculate member status
	, CASE 
		WHEN	ISNULL(m.EffectiveDate,@minDate) <= @now AND ISNULL(m.ExpirationDate,@minDate) >= @now
		THEN	'Active'
		ELSE	'Inactive'
		END	AS Member_Status     
	, COALESCE(c.ContactFirstName,'') + COALESCE(' ' + c.ContactLastName,'') AS Member_Name
	, CASE
		WHEN	c.ContactFirstName <> m.Firstname
		AND		c.ContactLastName <> m.LastName
		THEN
				REPLACE(RTRIM(    
				COALESCE(m.FirstName, '') +    
				COALESCE(m.MiddleName, '') +   
				COALESCE(m.Suffix, '') + 
				COALESCE(' ' + m.LastName, '') 
				), '  ', ' ')
		ELSE
				NULL
		END as Member_CompanyName
    , ISNULL(ms.MembershipNumber,' ') AS Member_MembershipNumber
    , ISNULL((SELECT NAME FROM PhoneType WHERE ID = c.ContactPhoneTypeID),' ') as Member_CallbackPhoneTypeID    
    , ISNULL(c.ContactPhoneNumber,'') as Member_CallbackPhoneNumber    
    , ISNULL((SELECT NAME FROM PhoneType WHERE ID = c.ContactAltPhoneTypeID),' ') as Member_AltCallbackPhoneTypeID   
    , ISNULL(c.ContactAltPhoneNumber,'') as Member_AltCallbackPhoneNumber    
    , CONVERT(nvarchar(10),m.MemberSinceDate,101) as Member_MemberSinceDate
    , CONVERT(nvarchar(10),m.EffectiveDate,101) AS Member_EffectiveDate
    , CONVERT(nvarchar(10),m.ExpirationDate,101) AS Member_ExpirationDate
    , ISNULL(ae.Line1,'') AS Member_AddressLine1
    , ISNULL(ae.Line2,'') AS Member_AddressLine2
    , ISNULL(REPLACE(RTRIM(    
		COALESCE(ae.City, '') +
		COALESCE(', ' + ae.StateProvince, '') +
		COALESCE(' ' + ae.PostalCode, '') +
		COALESCE(' ' + ae.CountryCode, '') 
		), '  ', ' ')
		, ' ' ) AS Member_AddressCityStateZip
	,'Client Ref #:' + ms.ClientReferenceNumber AS Member_ReceiptNumber
-- VEHICLE SECTION
--	, 3 AS Vehicle_DefalutNumberOfRows
	,CASE	WHEN C.IsVehicleEligible IS NULL THEN '' 
			WHEN C.IsVehicleEligible = 1 THEN 'In Warranty'
			ELSE 'Out of Warranty' END AS Vehicle_IsEligible
	, ISNULL(RTRIM (
		COALESCE(c.VehicleYear + ' ', '') +    
		COALESCE(CASE c.VehicleMake WHEN 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END+ ' ', '') +    
		COALESCE(CASE C.VehicleModel WHEN 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END, '')
		), ' ') as Vehicle_YearMakeModel    
	, ISNULL(c.VehicleVIN,' ') as Vehicle_VIN    
	, ISNULL(RTRIM (
		COALESCE(c.VehicleColor + '  ' , '') +
		COALESCE(c.VehicleLicenseState + '-','') + 
		COALESCE(c.VehicleLicenseNumber, '')
		), ' ' ) AS Vehicle_Color_LicenseStateNumber
    ,ISNULL(
			COALESCE((SELECT Name FROM VehicleType WHERE ID = c.VehicleTypeID) + '-','') +
			COALESCE((SELECT Name FROM VehicleCategory WHERE ID = c.VehicleCategoryID),'') 
		,'') AS Vehicle_Type_Category
    ,ISNULL(C.[VehicleDescription],'') AS Vehicle_Description
    ,CASE WHEN C.[VehicleLength] IS NULL THEN '' ELSE CONVERT(NVARCHAR(50),C.[VehicleLength]) END AS Vehicle_Length
-- SERVICE SECTION   
--	, 2 AS Service_DefaultNumberOfRows  
	
	, CASE WHEN sr.IsPrimaryOverallCovered  = 1 THEN 'Covered' ELSE 'Not Covered' END AS Service_IsPrimaryOverallCovered
	, pc.Name as Service_ProductCategoryTow

	, CASE WHEN sr.IsSecondaryOverallCovered  = 1 THEN 'Covered' ELSE 'Not Covered' END AS Service_IsSecondaryOverallCovered
	, CASE WHEN sr.IsPossibleTow = 1 THEN 'Possible Tow' ELSE '' END AS Service_IsPossibleTow
	
	, '$' + CONVERT(NVARCHAR(50),ISNULL(sr.PrimaryCoverageLimit,0)) as Service_CoverageLimit  

-- LOCATION SECTION     
--	, 2 AS Location_DefaultNumberOfRows
	, ISNULL(sr.ServiceLocationAddress,' ') as Location_Address    
	, ISNULL(sr.ServiceLocationDescription,' ') as Location_Description  

-- DESTINATION SECTION     
--	, 2 AS Destination_DefaultNumberOfRows
	, ISNULL(sr.DestinationAddress,' ') as Destination_Address    
	, ISNULL(sr.DestinationDescription,' ') as Destination_Description 	
	, (SELECT VendorName FROM @tmpServiceLocationVendor ) AS Destination_VendorName
	, (SELECT PhoneNumber FROM @tmpServiceLocationVendor ) AS Destination_PhoneNumber
	, (SELECT TalkedTo FROM @tmpServiceLocationVendor ) AS Destination_TalkedTo
	, (SELECT ISNULL(Line1,'') FROM @tmpServiceLocationVendor ) AS Destination_AddressLine1
    , (SELECT ISNULL(Line2,'') FROM @tmpServiceLocationVendor) AS Destination_AddressLine2
    , (SELECT ISNULL(REPLACE(RTRIM(    
		COALESCE(City, '') +
		COALESCE(', ' + StateProvince, '') +
		COALESCE(' ' + PostalCode, '') +
		COALESCE(' ' + CountryCode, '') 
		), '  ', ' ')
		, ' ' ) FROM  @tmpServiceLocationVendor) AS Destination_AddressCityStateZip    
		
-- ISP SECTION
--	, 3 AS ISP_DefaultNumberOfRows
	--,CASE 
	--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NOT NULL THEN 'Contracted'
	--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NULL THEN 'Not Contracted'
	--	WHEN vc.ID IS NOT NULL THEN 'Contracted' 
	--	ELSE 'Not Contracted'
	--	END as ISP_Contracted
	, CASE
		WHEN ContractedVendors.ContractID IS NOT NULL 
			AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'
		ELSE 'Not Contracted' 
		END AS ISP_Contracted
	, ISNULL(v.Name,' ') as ISP_VendorName    
	, ISNULL(v.VendorNumber, ' ') AS ISP_VendorNumber
	--, ISNULL(peISP.PhoneNumber,' ') as ISP_DispatchPhoneNumber 
	, (SELECT TOP 1 PhoneNumber
		FROM PhoneEntity 
		WHERE RecordID = vl.ID
		AND EntityID = (Select ID From Entity Where Name = 'VendorLocation')
		AND PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')
		ORDER BY ID DESC
		) AS ISP_DispatchPhoneNumber
	, ISNULL(aeISP.Line1,'') AS ISP_AddressLine1
    , ISNULL(aeISP.Line2,'') AS ISP_AddressLine2
    , ISNULL(REPLACE(RTRIM(    
		COALESCE(aeISP.City, '') +
		COALESCE(', ' + aeISP.StateProvince, '') +
		COALESCE(' ' + aeISP.PostalCode, '') +
		COALESCE(' ' + aeISP.CountryCode, '') 
		), '  ', ' ')
		, ' ' ) AS ISP_AddressCityStateZip
	, COALESCE(ISNULL(po.PurchaseOrderNumber + '-', ' '),'') + ISNULL(pos.Name, ' ' ) AS ISP_PONumberStatus
--	, ISNULL(pos.Name, ' ' ) AS ISP_POStatus
	, COALESCE( '$' + CONVERT(NVARCHAR(10),po.PurchaseOrderAmount),'') 
		+ ' ' 
		+ ISNULL(CASE WHEN po.ID IS NOT NULL THEN PC.Name ELSE NULL END,'') AS ISP_POAmount_ProductCategory
	--, ISNULL(po.PurchaseOrderAmount, ' ' ) AS ISP_POAmount
	, 'Issued:' +
		REPLACE(CONVERT(VARCHAR(8), po.IssueDate, 10), '-', '/') + ' - ' +  
		SUBSTRING(CONVERT(VARCHAR(20), po.IssueDate, 9), 13, 8) + ' ' +  
		SUBSTRING(CONVERT(VARCHAR(30), po.IssueDate, 9), 25, 2) AS ISP_IssuedDate  
	, 'ETA:' +
		REPLACE(CONVERT(VARCHAR(8), po.ETADate, 10), '-', '/') + ' - ' +  
		SUBSTRING(CONVERT(VARCHAR(20), po.ETADate, 9), 13, 8) + ' ' +  
		SUBSTRING(CONVERT(VARCHAR(30), po.ETADate, 9), 25, 2) AS ISP_ETADate  

-- SERVICE REQUEST SECTION 
--	, 2 AS SR_DefaultNumberOfRows
	--Sanghi 03 - July - 2013 Updated Below Line.
	, CAST(CAST(ISNULL(sr.ID, ' ') AS NVARCHAR(MAX)) + ' - ' + ISNULL(srs.Name, ' ') AS NVARCHAR(MAX))  AS SR_Info 
	--, ISNULL(sr.ID,' ') as SR_ServiceRequestID      
	--,(ISNULL(srs.Name,'')) + CASE WHEN na.Name IS NULL THEN '' ELSE ' - ' + (ISNULL(na.Name,'')) END AS SR_ServiceRequestStatus
	--, ISNULL('Closed Loop: ' + cls.Name, ' ') as SR_ClosedLoopStatus
	, ISNULL(sr.CreateBy,' ') + ' ' + 
		    REPLACE(CONVERT(VARCHAR(8), sr.CreateDate, 10), '-', '/') + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(20), sr.CreateDate, 9), 13, 8) + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(30), sr.CreateDate, 9), 25, 2
			) AS SR_CreateInfo
	--, ISNULL(sr.CreateBy,' ')as SR_CreatedBy   
	--, REPLACE(CONVERT(VARCHAR(8), sr.CreateDate, 10), '-', '/') + ' - ' +  
	--	SUBSTRING(CONVERT(VARCHAR(20), sr.CreateDate, 9), 13, 8) + ' ' +  
	--	SUBSTRING(CONVERT(VARCHAR(30), sr.CreateDate, 9), 25, 2) AS SR_CreateDate
	--, ISNULL(NextAction.Name, ' ') + ISNULL(u.FirstName, ' ') + ' ' + ISNULL(u.LastName,' ') AS SR_NextActionInfo  
	, ISNULL(NextAction.Name + ' - ', ' ') + ISNULL(u.FirstName, ' ') + ' ' + ISNULL(u.LastName,' ') AS SR_NextActionName_AssignedTo
	, ISNULL( 	
			REPLACE(
			CONVERT(VARCHAR(8), sr.NextActionScheduledDate, 10), '-', '/') + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(20), sr.NextActionScheduledDate, 9), 13, 8) + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(30), sr.NextActionScheduledDate, 9), 25, 2
			) 
			, ' ') AS SR_NextActionScheduledDate
	--, ISNULL('AssignedTo: ' + u.FirstName, ' ') + ' ' + ISNULL(u.LastName,' ') AS SR_NextActionAssignedTo  

	FROM		ServiceRequest sr      
	JOIN		[Case] c on c.ID = sr.CaseID    
	LEFT JOIN	PhoneType ptContact on ptContact.ID = c.ContactPhoneTypeID    
	JOIN		Program p on p.ID = c.ProgramID    
	JOIN		Client cl on cl.ID = p.ClientID    
	JOIN		Member m on m.ID = c.MemberID    
	JOIN		Membership ms on ms.ID = m.MembershipID    
	LEFT JOIN	AddressEntity ae ON ae.EntityID = (select ID from Entity where Name = 'Membership')    
	AND			ae.RecordID = ms.ID    
	AND			ae.AddressTypeID = (select ID from AddressType where Name = 'Home')    
	LEFT JOIN	Country country on country.ID = ae.CountryID     
	LEFT JOIN	PhoneEntity peMbr ON peMbr.EntityID = (select ID from Entity where Name = 'Membership')     
	AND			peMbr.RecordID = ms.ID    
	AND			peMbr.PhoneTypeID = (select ID from PhoneType where Name = 'Home')    
	LEFT JOIN	PhoneType ptMbr on ptMbr.ID = peMbr.PhoneTypeID    
	LEFT JOIN	ProductCategory pc on pc.ID = sr.ProductCategoryID    
	LEFT JOIN	(  
				SELECT TOP 1 *  
				FROM PurchaseOrder wPO   
				WHERE wPO.ServiceRequestID = @serviceRequestID  
				AND wPO.IsActive = 1
				AND wPO.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending')
				ORDER BY wPO.IssueDate DESC  
				) po on po.ServiceRequestID = sr.ID  
	LEFT JOIN	PurchaseOrderStatus pos on pos.ID = po.PurchaseOrderStatusID  
	LEFT JOIN	VendorLocation vl on vl.ID = po.VendorLocationID    
	LEFT JOIN	Vendor v on v.ID = vl.VendorID 
	LEFT JOIN	[Contract] vc on vc.VendorID = v.ID and vc.IsActive = 1 and vc.ContractStatusID = (Select ID From ContractStatus Where Name = 'Active')
	LEFT OUTER JOIN (
				SELECT DISTINCT vr.VendorID, vr.ProductID
				FROM dbo.fnGetCurrentProductRatesByVendorLocation() vr 
				) DefaultVendorRates ON v.ID = DefaultVendorRates.VendorID And @ProductID = DefaultVendorRates.ProductID
	LEFT OUTER JOIN (
				SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID
				FROM dbo.fnGetContractedVendors() cv
				) ContractedVendors ON v.ID = ContractedVendors.VendorID
	--LEFT JOIN	PhoneEntity peISP on peISP.EntityID = (select ID from Entity where Name = 'VendorLocation')     
	--AND			peISP.RecordID = vl.ID    
	--AND			peISP.PhoneTypeID = (select ID from PhoneType where Name = 'Dispatch')  
	--LEFT JOIN	PhoneType ptISP on ptISP.ID = peISP.PhoneTypeID    
	--LEFT JOIN (
	--			SELECT TOP 1 ph.RecordID, ph.PhoneNumber
	--			FROM PhoneEntity ph 
	--			WHERE EntityID = (Select ID From Entity Where Name = 'VendorLocation')
	--			AND PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')
	--			ORDER BY ID 
	--		   )  peISP ON peISP.RecordID = vl.ID
	LEFT JOIN	AddressEntity aeISP ON aeISP.EntityID = (select ID from Entity where Name = 'VendorLocation')    
	AND			aeISP.RecordID = vl.ID    
	AND			aeISP.AddressTypeID = (select ID from AddressType where Name = 'Business')    
 -- CR # 524  
	LEFT JOIN	ServiceRequestStatus srs ON srs.ID=sr.ServiceRequestStatusID  
	LEFT JOIN	NextAction na ON na.ID=sr.NextActionID  
	LEFT JOIN	ClosedLoopStatus cls ON cls.ID=sr.ClosedLoopStatusID 
 -- End : CR # 524  
 	LEFT JOIN	VendorLocation VLD ON VLD.ID = sr.DestinationVendorLocationID
	LEFT JOIN	PhoneEntity peDestination ON peDestination.RecordID = VLD.ID AND peDestination.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')  
	LEFT JOIN	NextAction NextAction on NextAction.ID = sr.NextActionID
	LEFT JOIN	[User] u on u.ID = sr.NextActionAssignedToUserID

	WHERE		sr.ID = @ServiceRequestID    
	FOR XML PATH)    
    

EXEC sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument    
SELECT * INTO #Temp FROM OPENXML (@DocHandle, '/row',2)      
INSERT INTO @Hold    
SELECT T1.localName ,T2.text,'String',ROW_NUMBER() OVER(ORDER BY T1.ID),'',NULL FROM #Temp T1     
INNER JOIN #Temp T2 ON T1.id = T2.parentid    
WHERE T1.id > 0    
    
    
DROP TABLE #Temp    
    -- Group Values Based on Sequence Number    
 UPDATE @Hold SET GroupName = 'Member', DefaultRows = 6 WHERE CHARINDEX('Member_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Vehicle', DefaultRows = 3 WHERE CHARINDEX('Vehicle_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Service' ,DefaultRows = 5 WHERE CHARINDEX('Service_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Location', DefaultRows = 2 WHERE CHARINDEX('Location_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Destination', DefaultRows = 2 WHERE CHARINDEX('Destination_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'ISP', DefaultRows = 10 WHERE CHARINDEX('ISP_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Program', DefaultRows = 1 WHERE CHARINDEX('Program_',ColumnName) > 0   
 UPDATE  @Hold SET GroupName = 'Service Request', DefaultRows = 2 WHERE CHARINDEX('SR_',ColumnName) > 0   
     
 --CR # 524   
      
-- UPDATE @Hold SET GroupName ='Service Request' where ColumnName in ('ServiceRequestID','ServiceRequestStatus','NextAction',  
--'ClosedLoopStatus',  
--'CreateDate','CreatedBy','SR_NextAction','SR_NextActionAssignedTo')  
 -- End : CR # 524  
   
 UPDATE @Hold SET DataType = 'Phone' WHERE CHARINDEX('PhoneNumber',ColumnName) > 0    
 UPDATE @Hold SET DataType = 'LabelTheme' WHERE CHARINDEX('Member_Status',ColumnName) > 0 OR CHARINDEX('Vehicle_IsEligible',ColumnName) > 0  
 UPDATE @Hold SET DataType = 'LabelThemeInline' WHERE CHARINDEX('Service_IsPrimaryOverallCovered',ColumnName) > 0
 UPDATE @Hold SET DataType = 'LabelThemeInline' WHERE CHARINDEX('Service_IsSecondaryOverallCovered',ColumnName) > 0   

 IF NOT EXISTS (SELECT * FROM @Hold WHERE ColumnName  = 'Service_IsPossibleTow' AND ColumnValue IS NOT NULL AND  ColumnValue != '')
 BEGIN
	DELETE FROM @Hold WHERE ColumnName  = 'Service_IsSecondaryOverallCovered'
 END

 IF NOT EXISTS (SELECT * FROM @Hold WHERE ColumnName  = 'Service_ProductCategoryTow' AND ColumnValue IS NOT NULL AND  ColumnValue != '')
 BEGIN
	DELETE FROM @Hold WHERE ColumnName  = 'Service_IsPrimaryOverallCovered'
 END

 DELETE FROM @Hold WHERE ColumnValue IS NULL

 DECLARE @DefaultRows INT
 SET  @DefaultRows = (SELECT Sequence FROM @Hold WHERE ColumnName = 'Member_AltCallbackPhoneNumber')
 IF @DefaultRows IS NOT NULL
 BEGIN
 SET @DefaultRows = (SELECT COUNT(*) FROM @Hold WHERE ColumnName LIKE 'Member_%' AND Sequence <= @DefaultRows)
 -- Re Setting values 
 UPDATE @Hold SET DefaultRows = @DefaultRows WHERE GroupName = 'Member' 
 END

 -- Sanghi - 01-04-2014 CR : 248 Increase Number of Columns to be Displayed When Warranty is Applicable.
 -- Validate Vehicle_IsEligible COLUMN 
 IF EXISTS (SELECT * FROM @Hold WHERE ColumnName = 'Vehicle_IsEligible')
 BEGIN
	UPDATE @Hold SET DefaultRows = 4 WHERE GroupName = 'Vehicle' 
 END


 -- Update Label fields
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Member Since: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Member_MemberSinceDate')
 WHERE ColumnName = 'Member_MemberSinceDate'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Effective: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Member_EffectiveDate')
 WHERE ColumnName = 'Member_EffectiveDate'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Expiration: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Member_ExpirationDate')
 WHERE ColumnName = 'Member_ExpirationDate'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'PO: ' + ColumnValue FROM @Hold WHERE ColumnName = 'ISP_PONumberStatus')
 WHERE ColumnName = 'ISP_PONumberStatus'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Length: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Vehicle_Length')
 WHERE ColumnName = 'Vehicle_Length'
 
 
 SELECT * FROM @Hold WHERE ColumnValue IS NOT NULL ORDER BY Sequence ASC 
 
	
END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Program_Management_List_Get @whereClauseXML='<ROW><Filter ClientID="1" ProgramID="5" Name="tes" NameOperator="Conains"></Filter></ROW>'
 CREATE PROCEDURE [dbo].[dms_Program_Management_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
Number=""
Name=""
NameOperator=""
ClientID=""
ProgramID=""
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
Number NVARCHAR(50) NULL,
Name NVARCHAR(50) NULL,
NameOperator NVARCHAR(50) NULL,
ClientID int NULL,
ProgramID INT NULL
)

INSERT INTO @tmpForWhereClause
SELECT  
	T.c.value('@Number','NVARCHAR(50)'),
	T.c.value('@Name','NVARCHAR(100)'),
	T.c.value('@NameOperator','NVARCHAR(50)'),
	T.c.value('@ClientID','INT'),
	T.c.value('@ProgramID','INT')
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @Number			NVARCHAR(50)= NULL,
@Name			NVARCHAR(100)= NULL,
@NameOperator	NVARCHAR(50)= NULL,
@ClientID		INT= NULL,
@ProgramID		INT= NULL

SELECT 
		@Number					= Number				
		,@NameOperator			= NameOperator				
		,@ClientID				= ClientID			
		,@ProgramID			    = ProgramID
		,@Name		            = Name
			
FROM @tmpForWhereClause

DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Sort int  NULL ,
	ClientID int  NULL ,
	ClientName nvarchar(50)  NULL ,
	ParentProgramID int  NULL ,
	ParentName nvarchar(50)  NULL ,
	ProgramID int  NULL ,
	ProgramCode nvarchar(50)  NULL ,
	ProgramName nvarchar(50)  NULL ,
	ProgramDescription nvarchar(50)  NULL ,
	ProgramIsActive bit  NULL ,
	IsAudited bit  NULL ,
	IsClosedLoopAutomated bit  NULL ,
	IsGroup bit  NULL 
) 

DECLARE @FinalResults_Temp TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Sort int  NULL ,
	ClientID int  NULL ,
	ClientName nvarchar(50)  NULL ,
	ParentProgramID int  NULL ,
	ParentName nvarchar(50)  NULL ,
	ProgramID int  NULL ,
	ProgramCode nvarchar(50)  NULL ,
	ProgramName nvarchar(50)  NULL ,
	ProgramDescription nvarchar(50)  NULL ,
	ProgramIsActive bit  NULL ,
	IsAudited bit  NULL ,
	IsClosedLoopAutomated bit  NULL ,
	IsGroup bit  NULL 
) 



--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults_Temp
SELECT
CASE
WHEN PP.ID IS NULL THEN P.ID
ELSE PP.ID
END AS Sort
, C.ID AS ClientID
, C.Name AS ClientName
, PP.ID AS ParentProgramID
, PP.Name AS ParentName
, P.ID AS ProgramID
, P.Code AS ProgramCode
, P.Name AS ProgramName
, P.Description AS ProgramDescription
, P.IsActive AS ProgramIsActive
, P.IsAudited AS IsAudited
, P.IsClosedLoopAutomated AS IsClosedLoopAutomated
, P.IsGroup AS IsGroup
--, *
FROM Program P (NOLOCK)
JOIN Client C (NOLOCK) ON C.ID = P.ClientID
LEFT JOIN Program PP (NOLOCK) ON PP.ID = P.ParentProgramID
WHERE C.Name <> 'ARS'
ORDER BY C.Name, Sort, PP.ID, P.ID

PRINT @NameOperator
PRINT 'nAME:'+@Name
INSERT INTO @FinalResults
SELECT 
	T.Sort,
	T.ClientID,
	T.ClientName,
	T.ParentProgramID,
	T.ParentName,
	T.ProgramID,
	T.ProgramCode,
	T.ProgramName,
	T.ProgramDescription,
	T.ProgramIsActive,
	T.IsAudited,
	T.IsClosedLoopAutomated,
	T.IsGroup
FROM @FinalResults_Temp T
WHERE 
(ISNULL(LEN(@Number),0) = 0 OR (@Number = CONVERT(NVARCHAR(100),T.ProgramID)  ))
AND (ISNULL(@ClientID,0) = 0 OR @ClientID = 0 OR (T.ClientID = @ClientID  ))
AND (ISNULL(@ProgramID,0) = 0 OR @ProgramID = T.ProgramID OR (T.ParentProgramID = @ProgramID  ))
AND	(ISNULL(LEN(@Name),0) = 0 OR  (
									(@NameOperator = 'Is equal to' AND @Name = T.ProgramName)
									OR
									(@NameOperator = 'Begins with' AND T.ProgramName LIKE  @Name + '%')
									OR
									(@NameOperator = 'Ends with' AND T.ProgramName LIKE  '%' + @Name)
									OR
									(@NameOperator = 'Contains' AND T.ProgramName LIKE  '%' + @Name + '%')
								))
 ORDER BY 
	 CASE WHEN @sortColumn = 'Sort' AND @sortOrder = 'ASC'
	 THEN T.Sort END ASC, 
	 CASE WHEN @sortColumn = 'Sort' AND @sortOrder = 'DESC'
	 THEN T.Sort END DESC ,

	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'ASC'
	 THEN T.ClientID END ASC, 
	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'DESC'
	 THEN T.ClientID END DESC ,

	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'ASC'
	 THEN T.ClientName END ASC, 
	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'DESC'
	 THEN T.ClientName END DESC ,

	 CASE WHEN @sortColumn = 'ParentProgramID' AND @sortOrder = 'ASC'
	 THEN T.ParentProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ParentProgramID' AND @sortOrder = 'DESC'
	 THEN T.ParentProgramID END DESC ,

	 CASE WHEN @sortColumn = 'ParentName' AND @sortOrder = 'ASC'
	 THEN T.ParentName END ASC, 
	 CASE WHEN @sortColumn = 'ParentName' AND @sortOrder = 'DESC'
	 THEN T.ParentName END DESC ,

	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'ASC'
	 THEN T.ProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'DESC'
	 THEN T.ProgramID END DESC ,

	 CASE WHEN @sortColumn = 'ProgramCode' AND @sortOrder = 'ASC'
	 THEN T.ProgramCode END ASC, 
	 CASE WHEN @sortColumn = 'ProgramCode' AND @sortOrder = 'DESC'
	 THEN T.ProgramCode END DESC ,

	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'ASC'
	 THEN T.ProgramName END ASC, 
	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'DESC'
	 THEN T.ProgramName END DESC ,

	 CASE WHEN @sortColumn = 'ProgramDescription' AND @sortOrder = 'ASC'
	 THEN T.ProgramDescription END ASC, 
	 CASE WHEN @sortColumn = 'ProgramDescription' AND @sortOrder = 'DESC'
	 THEN T.ProgramDescription END DESC ,

	 CASE WHEN @sortColumn = 'ProgramIsActive' AND @sortOrder = 'ASC'
	 THEN T.ProgramIsActive END ASC, 
	 CASE WHEN @sortColumn = 'ProgramIsActive' AND @sortOrder = 'DESC'
	 THEN T.ProgramIsActive END DESC ,

	 CASE WHEN @sortColumn = 'IsAudited' AND @sortOrder = 'ASC'
	 THEN T.IsAudited END ASC, 
	 CASE WHEN @sortColumn = 'IsAudited' AND @sortOrder = 'DESC'
	 THEN T.IsAudited END DESC ,

	 CASE WHEN @sortColumn = 'IsClosedLoopAutomated' AND @sortOrder = 'ASC'
	 THEN T.IsClosedLoopAutomated END ASC, 
	 CASE WHEN @sortColumn = 'IsClosedLoopAutomated' AND @sortOrder = 'DESC'
	 THEN T.IsClosedLoopAutomated END DESC ,

	 CASE WHEN @sortColumn = 'IsGroup' AND @sortOrder = 'ASC'
	 THEN T.IsGroup END ASC, 
	 CASE WHEN @sortColumn = 'IsGroup' AND @sortOrder = 'DESC'
	 THEN T.IsGroup END DESC 


DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM @FinalResults
SET @endInd = @startInd + @pageSize - 1
IF @startInd  > @count   
BEGIN   
	DECLARE @numOfPages INT    
	SET @numOfPages = @count / @pageSize   
	IF @count % @pageSize > 1   
	BEGIN   
		SET @numOfPages = @numOfPages + 1   
	END   
	SET @startInd = ((@numOfPages - 1) * @pageSize) + 1   
	SET @endInd = @numOfPages * @pageSize   
END

SELECT @count AS TotalRows, * FROM @FinalResults WHERE RowNum BETWEEN @startInd AND @endInd

END
GO
/*******************
* Operator Enums 
*  Conditions Enum :
* -1 - No filter
*  0 - Null
*  1 - Not Null
*  2 - Equals
*  3 - NotEquals
*  ---- for strings ---
*  4 - StartsWith
*  5 - EndsWith
*  6 - Contains
*  ---- for int, decimal, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_ProgramDataItemList]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_ProgramDataItemList] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_Program_Management_ProgramDataItemList] @programID=45
 CREATE PROCEDURE [dbo].[dms_Program_Management_ProgramDataItemList]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID INT = NULL 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
ProgramNameOperator="-1" 
ProgramDataItemIDOperator="-1" 
ScreenNameOperator="-1" 
NameOperator="-1" 
LabelOperator="-1" 
IsActiveOperator="-1" 
ControlTypeOperator="-1" 
DataTypeOperator="-1" 
SequenceOperator="-1" 
IsRequiredOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
ProgramNameOperator INT NOT NULL,
ProgramNameValue nvarchar(100) NULL,
ProgramDataItemIDOperator INT NOT NULL,
ProgramDataItemIDValue int NULL,
ScreenNameOperator INT NOT NULL,
ScreenNameValue nvarchar(100) NULL,
NameOperator INT NOT NULL,
NameValue nvarchar(100) NULL,
LabelOperator INT NOT NULL,
LabelValue nvarchar(100) NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue bit NULL,
ControlTypeOperator INT NOT NULL,
ControlTypeValue nvarchar(100) NULL,
DataTypeOperator INT NOT NULL,
DataTypeValue nvarchar(100) NULL,
SequenceOperator INT NOT NULL,
SequenceValue int NULL,
IsRequiredOperator INT NOT NULL,
IsRequiredValue bit NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramID INT NOT NULL,
	ProgramName nvarchar(100)  NULL,
	ProgramDataItemID int  NULL ,
	ScreenName nvarchar(100)  NULL ,
	Name nvarchar(100)  NULL ,
	Label nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	ControlType nvarchar(100)  NULL ,
	DataType nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsRequired bit  NULL 
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramID INT NOT NULL,
	ProgramName nvarchar(100)  NULL,
	ProgramDataItemID int  NULL ,
	ScreenName nvarchar(100)  NULL ,
	Name nvarchar(100)  NULL ,
	Label nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	ControlType nvarchar(100)  NULL ,
	DataType nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsRequired bit  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@ProgramNameOperator','INT'),-1),
	T.c.value('@ProgramNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProgramDataItemIDOperator','INT'),-1),
	T.c.value('@ProgramDataItemIDValue','int') ,
	ISNULL(T.c.value('@ScreenNameOperator','INT'),-1),
	T.c.value('@ScreenNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@NameOperator','INT'),-1),
	T.c.value('@NameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@LabelOperator','INT'),-1),
	T.c.value('@LabelValue','nvarchar(100)') ,
	ISNULL(T.c.value('@IsActiveOperator','INT'),-1),
	T.c.value('@IsActiveValue','bit') ,
	ISNULL(T.c.value('@ControlTypeOperator','INT'),-1),
	T.c.value('@ControlTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DataTypeOperator','INT'),-1),
	T.c.value('@DataTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@SequenceOperator','INT'),-1),
	T.c.value('@SequenceValue','int') ,
	ISNULL(T.c.value('@IsRequiredOperator','INT'),-1),
	T.c.value('@IsRequiredValue','bit') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT  PP.ProgramID,
		P.Name,
		PDI.ID ProgramDataItemID,
		PDI.ScreenName,
		PDI.Name,
		PDI.Label,
		PDI.IsActive,--CASE ISNULL(PC.IsActive,0) WHEN 0 THEN 'No' ELSE 'Yes' END IsActiveText,
		CT.[Description] ControlType,
		DT.[Description] DataType,
		PDI.Sequence,
		PDI.IsRequired
FROM fnc_GetProgramsandParents(@ProgramID) PP
JOIN Program P ON PP.ProgramID = P.ID
JOIN ProgramDataItem PDI ON PP.ProgramID = PDI.ProgramID AND PDI.IsActive = 1	
LEFT JOIN ControlType CT ON CT.ID = PDI.ControlTypeID
LEFT JOIN DataType DT ON DT.ID = PDI.DataTypeID
ORDER BY PDI.ScreenName,PDI.Sequence
INSERT INTO #FinalResults
SELECT 
	T.ProgramID,
	T.ProgramName,
	T.ProgramDataItemID,
	T.ScreenName,
	T.Name,
	T.Label,
	T.IsActive,
	T.ControlType,
	T.DataType,
	T.Sequence,
	T.IsRequired
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.ProgramDataItemIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 0 AND T.ProgramDataItemID IS NULL ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 1 AND T.ProgramDataItemID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 2 AND T.ProgramDataItemID = TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 3 AND T.ProgramDataItemID <> TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 7 AND T.ProgramDataItemID > TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 8 AND T.ProgramDataItemID >= TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 9 AND T.ProgramDataItemID < TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 10 AND T.ProgramDataItemID <= TMP.ProgramDataItemIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScreenNameOperator = -1 ) 
 OR 
	 ( TMP.ScreenNameOperator = 0 AND T.ScreenName IS NULL ) 
 OR 
	 ( TMP.ScreenNameOperator = 1 AND T.ScreenName IS NOT NULL ) 
 OR 
	 ( TMP.ScreenNameOperator = 2 AND T.ScreenName = TMP.ScreenNameValue ) 
 OR 
	 ( TMP.ScreenNameOperator = 3 AND T.ScreenName <> TMP.ScreenNameValue ) 
 OR 
	 ( TMP.ScreenNameOperator = 4 AND T.ScreenName LIKE TMP.ScreenNameValue + '%') 
 OR 
	 ( TMP.ScreenNameOperator = 5 AND T.ScreenName LIKE '%' + TMP.ScreenNameValue ) 
 OR 
	 ( TMP.ScreenNameOperator = 6 AND T.ScreenName LIKE '%' + TMP.ScreenNameValue + '%' ) 
 ) 
 AND 

 ( 
	 ( TMP.ProgramNameOperator = -1 ) 
 OR 
	 ( TMP.ProgramNameOperator = 0 AND T.ProgramName IS NULL ) 
 OR 
	 ( TMP.ProgramNameOperator = 1 AND T.ProgramName IS NOT NULL ) 
 OR 
	 ( TMP.ProgramNameOperator = 2 AND T.ProgramName = TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 3 AND T.ProgramName <> TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 4 AND T.ProgramName LIKE TMP.ProgramNameValue + '%') 
 OR 
	 ( TMP.ProgramNameOperator = 5 AND T.ProgramName LIKE '%' + TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 6 AND T.ProgramName LIKE '%' + TMP.ProgramNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.NameOperator = -1 ) 
 OR 
	 ( TMP.NameOperator = 0 AND T.Name IS NULL ) 
 OR 
	 ( TMP.NameOperator = 1 AND T.Name IS NOT NULL ) 
 OR 
	 ( TMP.NameOperator = 2 AND T.Name = TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 3 AND T.Name <> TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 4 AND T.Name LIKE TMP.NameValue + '%') 
 OR 
	 ( TMP.NameOperator = 5 AND T.Name LIKE '%' + TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 6 AND T.Name LIKE '%' + TMP.NameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LabelOperator = -1 ) 
 OR 
	 ( TMP.LabelOperator = 0 AND T.Label IS NULL ) 
 OR 
	 ( TMP.LabelOperator = 1 AND T.Label IS NOT NULL ) 
 OR 
	 ( TMP.LabelOperator = 2 AND T.Label = TMP.LabelValue ) 
 OR 
	 ( TMP.LabelOperator = 3 AND T.Label <> TMP.LabelValue ) 
 OR 
	 ( TMP.LabelOperator = 4 AND T.Label LIKE TMP.LabelValue + '%') 
 OR 
	 ( TMP.LabelOperator = 5 AND T.Label LIKE '%' + TMP.LabelValue ) 
 OR 
	 ( TMP.LabelOperator = 6 AND T.Label LIKE '%' + TMP.LabelValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.IsActiveOperator = -1 ) 
 OR 
	 ( TMP.IsActiveOperator = 0 AND T.IsActive IS NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 1 AND T.IsActive IS NOT NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 2 AND T.IsActive = TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 3 AND T.IsActive <> TMP.IsActiveValue ) 
 ) 

 AND 

 ( 
	 ( TMP.ControlTypeOperator = -1 ) 
 OR 
	 ( TMP.ControlTypeOperator = 0 AND T.ControlType IS NULL ) 
 OR 
	 ( TMP.ControlTypeOperator = 1 AND T.ControlType IS NOT NULL ) 
 OR 
	 ( TMP.ControlTypeOperator = 2 AND T.ControlType = TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 3 AND T.ControlType <> TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 4 AND T.ControlType LIKE TMP.ControlTypeValue + '%') 
 OR 
	 ( TMP.ControlTypeOperator = 5 AND T.ControlType LIKE '%' + TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 6 AND T.ControlType LIKE '%' + TMP.ControlTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DataTypeOperator = -1 ) 
 OR 
	 ( TMP.DataTypeOperator = 0 AND T.DataType IS NULL ) 
 OR 
	 ( TMP.DataTypeOperator = 1 AND T.DataType IS NOT NULL ) 
 OR 
	 ( TMP.DataTypeOperator = 2 AND T.DataType = TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 3 AND T.DataType <> TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 4 AND T.DataType LIKE TMP.DataTypeValue + '%') 
 OR 
	 ( TMP.DataTypeOperator = 5 AND T.DataType LIKE '%' + TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 6 AND T.DataType LIKE '%' + TMP.DataTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.SequenceOperator = -1 ) 
 OR 
	 ( TMP.SequenceOperator = 0 AND T.Sequence IS NULL ) 
 OR 
	 ( TMP.SequenceOperator = 1 AND T.Sequence IS NOT NULL ) 
 OR 
	 ( TMP.SequenceOperator = 2 AND T.Sequence = TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 3 AND T.Sequence <> TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 7 AND T.Sequence > TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 8 AND T.Sequence >= TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 9 AND T.Sequence < TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 10 AND T.Sequence <= TMP.SequenceValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsRequiredOperator = -1 ) 
 OR 
	 ( TMP.IsRequiredOperator = 0 AND T.IsRequired IS NULL ) 
 OR 
	 ( TMP.IsRequiredOperator = 1 AND T.IsRequired IS NOT NULL ) 
 OR 
	 ( TMP.IsRequiredOperator = 2 AND T.IsRequired = TMP.IsRequiredValue ) 
 OR 
	 ( TMP.IsRequiredOperator = 3 AND T.IsRequired <> TMP.IsRequiredValue ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ProgramDataItemID' AND @sortOrder = 'ASC'
	 THEN T.ProgramDataItemID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramDataItemID' AND @sortOrder = 'DESC'
	 THEN T.ProgramDataItemID END DESC ,

	 CASE WHEN @sortColumn = 'ScreenName' AND @sortOrder = 'ASC'
	 THEN T.ScreenName END ASC, 
	 CASE WHEN @sortColumn = 'ScreenName' AND @sortOrder = 'DESC'
	 THEN T.ScreenName END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Label' AND @sortOrder = 'ASC'
	 THEN T.Label END ASC, 
	 CASE WHEN @sortColumn = 'Label' AND @sortOrder = 'DESC'
	 THEN T.Label END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC ,

	 CASE WHEN @sortColumn = 'ControlType' AND @sortOrder = 'ASC'
	 THEN T.ControlType END ASC, 
	 CASE WHEN @sortColumn = 'ControlType' AND @sortOrder = 'DESC'
	 THEN T.ControlType END DESC ,

	 CASE WHEN @sortColumn = 'DataType' AND @sortOrder = 'ASC'
	 THEN T.DataType END ASC, 
	 CASE WHEN @sortColumn = 'DataType' AND @sortOrder = 'DESC'
	 THEN T.DataType END DESC ,

	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'
	 THEN T.Sequence END ASC, 
	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'
	 THEN T.Sequence END DESC ,

	 CASE WHEN @sortColumn = 'IsRequired' AND @sortOrder = 'ASC'
	 THEN T.IsRequired END ASC, 
	 CASE WHEN @sortColumn = 'IsRequired' AND @sortOrder = 'DESC'
	 THEN T.IsRequired END DESC,

	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'ASC'
	 THEN T.ProgramName END ASC, 
	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'DESC'
	 THEN T.ProgramName END DESC 


DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM #FinalResults
SET @endInd = @startInd + @pageSize - 1
IF @startInd  > @count   
BEGIN   
	DECLARE @numOfPages INT    
	SET @numOfPages = @count / @pageSize   
	IF @count % @pageSize > 1   
	BEGIN   
		SET @numOfPages = @numOfPages + 1   
	END   
	SET @startInd = ((@numOfPages - 1) * @pageSize) + 1   
	SET @endInd = @numOfPages * @pageSize   
END

SELECT @count AS TotalRows, * FROM #FinalResults WHERE RowNum BETWEEN @startInd AND @endInd

DROP TABLE #tmpForWhereClause
DROP TABLE #FinalResults
DROP TABLE #tmpFinalResults
END

GO
/*******************
* Operator Enums 
*  Conditions Enum :
* -1 - No filter
*  0 - Null
*  1 - Not Null
*  2 - Equals
*  3 - NotEquals
*  ---- for strings ---
*  4 - StartsWith
*  5 - EndsWith
*  6 - Contains
*  ---- for int, decimal, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_VerifyProgramServiceBenefit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC dms_VerifyProgramServiceBenefit 1, 1, 1, 1, 1, NULL, NULL  
CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit]  
        @ProgramID INT   
      , @ProductCategoryID INT  
      , @VehicleCategoryID INT  
      , @VehicleTypeID INT  
      , @SecondaryCategoryID INT = NULL  
      , @ServiceRequestID  INT = NULL  
      , @ProductID INT = NULL  
AS  
BEGIN   
  
 SET NOCOUNT ON    
 SET FMTONLY OFF    
   
 --KB: 
 SET @ProductID = NULL

 DECLARE @SecondaryProductID INT  
  
 /*** Determine Primary and Secondary Product IDs ***/  
 /* Ignore Vehicle related values for Product Categories not requiring a Vehicle */
 IF @ProductCategoryID IN (SELECT ID FROM ProductCategory WHERE IsVehicleRequired = 0)
	BEGIN
		SET @VehicleCategoryID = NULL
		SET @VehicleTypeID = NULL
	END
 
 /* Select Basic Lockout over Locksmith when a specific product is not provided */  
 IF @ProductID IS NULL AND @ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Lockout')  
 BEGIN  
  SET @ProductID = (SELECT ID FROM Product WHERE Name = 'Basic Lockout')  
 END  
  
 /* Select Tire Change over Tire Repair when a specific product is not provided */  
 IF @ProductID IS NULL AND @ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tire')  
 BEGIN  
  SET @ProductID = (SELECT ID FROM Product WHERE Name like 'Tire Change%' AND VehicleCategoryID = @VehicleCategoryID)  
 END  
  
 IF @ProductID IS NULL  
  SELECT @ProductID = p.ID   
  FROM  ProductCategory pc (NOLOCK)   
  JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID   
      AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')  
      AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')  
  WHERE  
  pc.ID = @ProductCategoryID   
  AND (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)  
  AND (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)  
  
  
 IF @SecondaryCategoryID IS NOT NULL  
  SELECT @SecondaryProductID = p.ID   
  FROM  ProductCategory pc (NOLOCK)   
  JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID   
      AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')  
      AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')  
  WHERE  
  pc.ID = @SecondaryCategoryID   
  AND (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)  
  AND (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)  
  
   
      SELECT ISNULL(pc.Name,'') ProductCategoryName  
            ,pc.ID ProductCategoryID  
            --,pc.Sequence  
            ,ISNULL(vc.Name,'') VehicleCategoryName  
            ,vc.ID VehicleCategoryID  
            ,pp.ProductID  
  
            ,CAST (pp.IsServiceCoverageBestValue AS BIT) AS IsServiceCoverageBestValue
            ,pp.ServiceCoverageLimit   
            ,pp.CurrencyTypeID   
            ,pp.ServiceMileageLimit   
            ,pp.ServiceMileageLimitUOM   
            --TO DO - Fix this logic  
            ,CASE WHEN pp.ServiceCoverageLimit IS NULL THEN 0   
                          WHEN pp.IsServiceCoverageBestValue = 1 THEN 1  
                          WHEN pp.ServiceCoverageLimit = 0 AND pp.IsReimbursementOnly = 1 THEN 1   
                          WHEN pp.ServiceCoverageLimit = 0 AND ISNULL(pp.ServiceMileageLimit,0) > 0 THEN 1   
                          WHEN pp.ServiceCoverageLimit = 0 AND pp.ProductID IN (SELECT p.ID FROM Product p WHERE p.ProductCategoryID IN (SELECT ID FROM ProductCategory WHERE Name IN ('Info', 'Tech', 'Concierge'))) THEN 1
                          WHEN pp.ServiceCoverageLimit > 0 THEN 1  
                          ELSE 0 END IsServiceEligible  
            ,pp.IsServiceGuaranteed   
            ,pp.ServiceCoverageDescription  
            ,pp.IsReimbursementOnly  
            ,CASE WHEN pc.ID = @SecondaryCategoryID THEN 0 ELSE 1 END AS IsPrimary  
      FROM ProgramProduct pp (NOLOCK)  
      JOIN Product p ON p.ID = pp.ProductID  
      LEFT OUTER JOIN ProductCategory pc (NOLOCK) ON pc.ID = p.ProductCategoryID  
      LEFT OUTER JOIN VehicleCategory vc (NOLOCK) ON vc.id = p.VehicleCategoryID  
      WHERE pp.ProgramID = @ProgramID  
      AND (pp.ProductID = @ProductID OR pp.ProductID = @SecondaryProductID)  
   ORDER BY   
   (CASE WHEN pc.ID = @SecondaryCategoryID THEN 0 ELSE 1 END) DESC  
   ,pc.Sequence  
     
END  
  

GO
