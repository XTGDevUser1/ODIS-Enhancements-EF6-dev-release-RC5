
/****** Object:  UserDefinedFunction [dbo].[fnGetCoachNetDealerPartnerVendors]    Script Date: 08/26/2013 10:47:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnGetCoachNetDealerPartnerVendors]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnGetCoachNetDealerPartnerVendors]
GO



/****** Object:  UserDefinedFunction [dbo].[fnGetCoachNetDealerPartnerVendors]    Script Date: 08/26/2013 10:47:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
-- SELECT * FROM [dbo].[fnGetCoachNetDealerPartnerVendors] ()


CREATE FUNCTION [dbo].[fnGetCoachNetDealerPartnerVendors] ()
RETURNS TABLE 
AS
RETURN (

		SELECT DISTINCT VL.VendorID As VendorID						
		FROM	VendorLocation VL WITH (NOLOCK) 
		JOIN	VendorLocationProduct VLP WITH (NOLOCK) ON VLP.VendorLocationID = VL.ID
		JOIN	Product P WITH (NOLOCK) ON VLP.ProductID = P.ID
		WHERE	P.Name = 'CoachNet Dealer Partner'
		AND		ISNULL(VLP.IsActive,0) = 1		
)


GO

/****** Object:  UserDefinedFunction [dbo].[fnGetDirectTowVendors]    Script Date: 08/26/2013 10:47:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnGetDirectTowVendors]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnGetDirectTowVendors]
GO



/****** Object:  UserDefinedFunction [dbo].[fnGetDirectTowVendors]    Script Date: 08/26/2013 10:47:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
-- SELECT * FROM [dbo].[fnGetDirectTowVendors] ()


CREATE FUNCTION [dbo].[fnGetDirectTowVendors] ()
RETURNS TABLE 
AS
RETURN (

		SELECT DISTINCT VL.VendorID As VendorID						
		FROM	VendorLocation VL WITH (NOLOCK) 
		JOIN	VendorLocationProduct VLP WITH (NOLOCK) ON VLP.VendorLocationID = VL.ID
		JOIN	Product P WITH (NOLOCK) ON VLP.ProductID = P.ID
		WHERE	P.Name = 'Ford Direct Tow'
		AND		ISNULL(VLP.IsActive,0) = 1
		AND		VL.DealerNumber IS NOT NULL 
		AND		VL.PartsAndAccessoryCode IS NOT NULL
)


GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Call_Summary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Call_Summary]
GO

--EXEC dms_Call_Summary @serviceRequestID = 1414  
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
    -- Ignore time while comparing dates here
    -- KB: Considering Effective and Expiration Dates to calculate member status
	, CASE 
		WHEN	ISNULL(m.EffectiveDate,@minDate) <= @now AND ISNULL(m.ExpirationDate,@minDate) >= @now
		THEN	'Active'
		ELSE	'Inactive'
		END	AS Member_Status       
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
	,CASE	WHEN C.IsVehicleEligible IS NULL THEN '' 
			WHEN C.IsVehicleEligible = 1 THEN 'In Warranty'
			ELSE 'Out of Warranty' END AS Vehicle_IsEligible
-- SERVICE SECTION   
--	, 2 AS Service_DefaultNumberOfRows  
	, ISNULL(
		COALESCE(pc.Name, '') + 
		COALESCE('/' + CASE WHEN sr.IsPossibleTow = 1 THEN 'Possible Tow' END, '')
		,' ') as Service_ProductCategoryTow    
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
 UPDATE @Hold SET GroupName = 'Member', DefaultRows = 5 WHERE CHARINDEX('Member_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Vehicle', DefaultRows = 3 WHERE CHARINDEX('Vehicle_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Service' ,DefaultRows = 2 WHERE CHARINDEX('Service_',ColumnName) > 0    
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
	SET  @DefaultRows = (SELECT Sequence FROM @Hold WHERE ColumnName = 'Vehicle_IsEligible')
	IF(@DefaultRows IS NOT NULL)
	BEGIN
		SET @DefaultRows = (SELECT COUNT(*) FROM @Hold WHERE ColumnName LIKE 'Vehicle_%' AND Sequence <= @DefaultRows)
		UPDATE @Hold SET DefaultRows = @DefaultRows WHERE GroupName = 'Vehicle' 
	END
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
 WHERE id = object_id(N'[dbo].[dms_productcategoryquestions_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_productcategoryquestions_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_productcategoryquestions_get] 3,1,1,NULL
 
CREATE PROCEDURE [dbo].[dms_productcategoryquestions_get]( 
   @ProgramID int,   
   @VehicleTypeID int = NULL,
   @VehicleCategoryID int = NULL,
   @serviceRequestID INT = NULL
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

DECLARE @Questions TABLE 
(
  ProductCategoryID int,
  ProductCategoryName NVARCHAR(MAX),
  ProductCategoryQuestionID int, 
  QuestionText nvarchar(4000),
  ControlType nvarchar(50),
  DataType nvarchar(50),
  HelpText nvarchar(4000),
  IsRequired bit,
  SubQuestionID int,
  RelatedAnswer nvarchar(255),
  Sequence int,
  AnswerValue NVARCHAR(MAX) NULL, -- Answer provided for this question
  IsEnabled BIT,
  VehicleCategoryID INT NULL
)
DECLARE @relevantProductCategories TABLE
(
	ProductCategoryID INT,
	Sequence INT NULL
)

--DEBUG : FOR EF
IF(@ProgramID IS NULL)
BEGIN
	SELECT * FROM @Questions
	RETURN;
END
	INSERT INTO @relevantProductCategories
	SELECT DISTINCT ProductCategoryID,
			PC.Sequence 
	FROM	ProgramProductCategory PC
	JOIN	[dbo].[fnc_getprogramsandparents](@ProgramID) FNCP ON PC.ProgramID = FNCP.ProgramID
	AND		(VehicleTypeID = @VehicleTypeID OR VehicleTypeID IS NULL)
	-- KB: Do not consider @vehicleCategoryID here.By design, we load all the questions for a given vehicle type and show/hide questions relevant to vehiclecategory. Therefore, questions / product categories should not get filtered out here.
	--AND		(VehicleCategoryID = @vehicleCategoryID OR VehicleCategoryID IS NULL)
	WHERE	PC.IsActive = 1
	ORDER BY PC.Sequence



-- Add questions related to Tow if they are not already in the list.

IF ( (SELECT COUNT(*) FROM @relevantProductCategories R,ProductCategory PC WHERE PC.ID = R.ProductCategoryID AND PC.Name like 'Tow%') = 0)
BEGIN
	INSERT INTO @relevantProductCategories
	SELECT	PC.ID,
			PC.Sequence
	FROM ProductCategory PC WHERE Name like 'Tow%' AND PC.IsActive = 1
END

IF ( (SELECT COUNT(*) FROM @relevantProductCategories R,ProductCategory PC WHERE PC.ID = R.ProductCategoryID AND PC.Name like 'Tow%') = 0)
BEGIN
	INSERT INTO @relevantProductCategories
	SELECT	PC.ID,
			PC.Sequence
	FROM ProductCategory PC  WHERE Name like 'Tow%'	AND PC.IsActive = 1
		  
END


INSERT INTO @Questions 
SELECT DISTINCT 
	PCQ.ProductCategoryID,
	PC.Name,
	PCQ.ID, 
  PCQ.QuestionText,
  CT.Name as ControlType,
  DT.Name as DataType,
  PCQ.HelpText, 
  PCQ.IsRequired,  
  PCL.ProductCategoryQuestionID as SubQuestionID, 
  PVAL.Value as RelatedAnswer,
  PCQ.Sequence,
  NULL,
  CASE WHEN (PCV.VehicleCategoryID IS NULL OR PCV.VehicleCategoryID = @VehicleCategoryID)
		THEN CAST (1 AS BIT)
		ELSE CAST (0 AS BIT)
  END AS IsEnabled,
  PCV.VehicleCategoryID
  FROM [dbo].ProductCategoryQuestion PCQ
  /*** KB: The following join was original code from Martex
  JOIN ProductCategoryQuestionVehicleType PCV ON PCV.ProductCategoryQuestionID = PCQ.ID 
  **/
  -- KB: Changed inner join to Left join.
  --RA: Changed to check IS NULL for VehicleType and added VehicleCategory back in
  JOIN ProductCategoryQuestionVehicleType PCV ON PCV.ProductCategoryQuestionID = PCQ.ID 
	AND (PCV.VehicleTypeID IS NULL OR PCV.VehicleTypeID = @VehicleTypeID) 
	-- KB: Do not consider @vehicleCategoryID here.By design, we load all the questions for a given vehicle type and show/hide questions relevant to vehiclecategory. Therefore, questions / product categories should not get filtered out here.
	--AND (PCV.VehicleCategoryID IS NULL OR PCV.VehicleCategoryID = @VehicleCategoryID)
	AND PCV.IsActive = 1 
  JOIN ProductCategory PC ON PCQ.ProductCategoryID = PC.ID
  LEFT JOIN ControlType CT ON CT.ID = PCQ.ControlTypeID
  LEFT JOIN DataType DT on DT.ID = PCQ.DataTypeID
  LEFT JOIN ProductCategoryQuestionLink PCL on PCL.ParentProductCategoryQuestionID = PCV.ProductCategoryQuestionID
  AND PCL.IsActive = 1
  LEFT JOIN ProductCategoryQuestionValue PVAL on PVAL.ID = PCL.ProductCategoryQuestionValueID
  AND PVAL.IsActive = 1 
  WHERE PCQ.ProductCategoryID IN (SELECT ProductCategoryID FROM @relevantProductCategories )
  AND PCQ.IsActive = 1
  
  UNION ALL
  
SELECT DISTINCT 
PCQ.ProductCategoryID,
PC.Name AS ProductCategoryName,
PCQ.ID, 

  PCQ.QuestionText,
  CT.Name as ControlType,
  DT.Name as DataType,
  PCQ.HelpText, 
  PCQ.IsRequired,  
  PCL.ProductCategoryQuestionID as SubQuestionID, 
  PVAL.Value as RelatedAnswer,
  PCQ.Sequence,
  NULL,
  CASE WHEN (PCP.VehicleCategoryID IS NULL OR PCP.VehicleCategoryID = @VehicleCategoryID)
		THEN CAST (1 AS BIT)
		ELSE CAST (0 AS BIT)
  END AS IsEnabled,
  PCP.VehicleCategoryID 
  FROM [dbo].ProductCategoryQuestion PCQ
  JOIN ProductCategoryQuestionProgram PCP ON PCP.ProductCategoryQuestionID = PCQ.ID 
	AND (PCP.VehicleTypeID IS NULL OR PCP.VehicleTypeID = @VehicleTypeID )
	-- KB: Do not consider @vehicleCategoryID here.By design, we load all the questions for a given vehicle type and show/hide questions relevant to vehiclecategory. Therefore, questions / product categories should not get filtered out here.
	--AND (PCP.VehicleCategoryID IS NULL OR PCP.VehicleCategoryID = @VehicleCategoryID)
	AND PCP.IsActive = 1 
	JOIN ProductCategory PC ON PCQ.ProductCategoryID = PC.ID
  JOIN fnc_GetProgramsandParents(@ProgramID) fncP on fncP.ProgramID = PCP.ProgramID 
  LEFT JOIN ControlType CT ON CT.ID = PCQ.ControlTypeID
  LEFT JOIN DataType DT on DT.ID = PCQ.DataTypeID
  LEFT JOIN ProductCategoryQuestionLink PCL on PCL.ParentProductCategoryQuestionID = PCP.ProductCategoryQuestionID
  AND PCL.IsActive = 1
  LEFT JOIN ProductCategoryQuestionValue PVAL on PVAL.ID = PCL.ProductCategoryQuestionValueID
  AND PVAL.IsActive = 1 
  WHERE PCQ.ProductCategoryID IN (SELECT ProductCategoryID FROM @relevantProductCategories )
  AND PCQ.IsActive = 1
  ORDER BY PCQ.Sequence 

	IF @serviceRequestID IS NULL
	BEGIN  
		SELECT * FROM @Questions
		WHERE  ProductCategoryName NOT IN ('Repair','Billing')
		ORDER BY ProductCategoryID,ProductCategoryQuestionID, Sequence
	END
	ELSE
	BEGIN
		SELECT	
				Q.ProductCategoryID,
				Q.ProductCategoryName,
				Q.ProductCategoryQuestionID, 
				Q.QuestionText,
				Q.ControlType,
				Q.DataType,
				Q.HelpText,
				Q.IsRequired,
				Q.SubQuestionID,
				Q.RelatedAnswer,
				Q.Sequence,
				SR.Answer AS AnswerValue,
				Q.IsEnabled,
				Q.VehicleCategoryID
		FROM @Questions Q 
		LEFT JOIN ServiceRequestDetail SR ON Q.ProductCategoryQuestionID = SR.ProductCategoryQuestionID 
						AND SR.ServiceRequestID = @serviceRequestID
		WHERE  ProductCategoryName NOT IN ('Repair','Billing')
		ORDER BY ProductCategoryID,ProductCategoryQuestionID, Q.Sequence
				
	
	END
	


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
*  ---- for int, money, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Coverage_Information_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Coverage_Information_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_Program_Coverage_Information_List_Get @programID =100
 CREATE PROCEDURE [dbo].[dms_Program_Coverage_Information_List_Get]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID int = NULL 
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
NameOperator="-1" 
LimitOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
NameOperator INT NOT NULL,
NameValue nvarchar(50) NULL,
LimitOperator INT NOT NULL,
LimitValue nvarchar(50) NULL
)
DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Name nvarchar(50)  NULL ,
	Limit nvarchar(50)  NULL ,
	Vehicle nvarchar(50)  NULL 
) 

DECLARE @tmpFinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Name nvarchar(50)  NULL ,
	Limit nvarchar(50)  NULL ,
	Vehicle nvarchar(50)  NULL 
) 

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(NameOperator,-1),
	NameValue ,
	ISNULL(LimitOperator,-1),
	LimitValue 
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
NameOperator INT,
NameValue nvarchar(50) 
,LimitOperator INT,
LimitValue money 
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @tmpFinalResults
SELECT	pc.Name
, max(CASE
WHEN pp.ServiceCoverageLimit > 0 THEN '$' + convert(nvarchar(10),pp.ServiceCoverageLimit)
WHEN pp.ServiceCoverageLimit = 0 AND pp.IsServiceCoverageBestValue = 1 THEN 'Best Value'
WHEN pp.ServiceCoverageLimit = 0 AND pp.IsServiceCoverageBestValue = 0 THEN '$0.00'
WHEN pp.ServiceCoverageLimit >= 0 AND pp.IsReimbursementOnly = 1 THEN '$' + convert(nvarchar(10),pp.ServiceCoverageLimit) + '-' + 'Reimbursement'
WHEN pp.ServiceCoverageLimit = 0 AND pp.IsReimbursementOnly = 0 THEN 'Assit Only'
ELSE ''
END) +
coalesce(max(CASE WHEN convert(nvarchar(3),pp.ServiceMileageLimit) > 0 THEN ' - ' + convert(nvarchar(3),pp.ServiceMileageLimit) + ' miles' ELSE '' END), '')
AS Limit
, max(CASE WHEN RIGHT(p.Name,2) = 'LD' THEN 'LD' ELSE '' END) +
coalesce('-' + max(CASE WHEN RIGHT(p.Name,2) = 'MD' THEN 'MD' END),'') +
coalesce('-'+max(CASE WHEN RIGHT(p.Name,2) = 'HD' THEN 'HD' END),'') AS Vehicle
FROM	ProgramProduct pp
JOIN	Product p (NOLOCK) ON p.id = pp.ProductID
JOIN	ProductCategory pc (NOLOCK) ON pc.id = p.productcategoryid
WHERE	pc.Name NOT IN ('Info','Repair','Billing')
AND	 pp.ProgramID = @ProgramID
GROUP BY pc.Name, pc.sequence
ORDER BY pc.Sequence
INSERT INTO @FinalResults
SELECT 
	T.Name,
	T.Limit,
	T.Vehicle
FROM @tmpFinalResults T,
@tmpForWhereClause TMP 
WHERE ( 

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
	 ( TMP.LimitOperator = -1 ) 
 OR 
	 ( TMP.LimitOperator = 0 AND T.Limit IS NULL ) 
 OR 
	 ( TMP.LimitOperator = 1 AND T.Limit IS NOT NULL ) 
 OR 
	 ( TMP.LimitOperator = 2 AND T.Limit = TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 3 AND T.Limit <> TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 7 AND T.Limit > TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 8 AND T.Limit >= TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 9 AND T.Limit < TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 10 AND T.Limit <= TMP.LimitValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Limit' AND @sortOrder = 'ASC'
	 THEN T.Limit END ASC, 
	 CASE WHEN @sortColumn = 'Limit' AND @sortOrder = 'DESC'
	 THEN T.Limit END DESC ,

	 CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'ASC'
	 THEN T.Vehicle END ASC, 
	 CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'DESC'
	 THEN T.Vehicle END DESC 


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
*  ---- for int, money, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_Services_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_Services_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_Program_Management_Services_List_Get] @ProgramID =3 ,@pageSize = 25
 CREATE PROCEDURE [dbo].[dms_Program_Management_Services_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @ProgramID INT = NULL 
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
 	SET FMTONLY OFF

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
ProgramProductIDOperator="-1" 
CategoryOperator="-1" 
ServiceOperator="-1" 
StartDateOperator="-1" 
EndDateOperator="-1" 
ServiceCoverageLimitOperator="-1" 
IsServiceCoverageBestValueOperator="-1" 
MaterialsCoverageLimitOperator="-1" 
IsMaterialsMemberPayOperator="-1" 
ServiceMileageLimitOperator="-1" 
IsServiceMileageUnlimitedOperator="-1" 
IsServiceMileageOverageAllowedOperator="-1" 
IsReimbursementOnlyOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
ProgramProductIDOperator INT NOT NULL,
ProgramProductIDValue int NULL,
CategoryOperator INT NOT NULL,
CategoryValue nvarchar(100) NULL,
ServiceOperator INT NOT NULL,
ServiceValue nvarchar(100) NULL,
StartDateOperator INT NOT NULL,
StartDateValue datetime NULL,
EndDateOperator INT NOT NULL,
EndDateValue datetime NULL,
ServiceCoverageLimitOperator INT NOT NULL,
ServiceCoverageLimitValue money NULL,
IsServiceCoverageBestValueOperator INT NOT NULL,
IsServiceCoverageBestValueValue bit NULL,
MaterialsCoverageLimitOperator INT NOT NULL,
MaterialsCoverageLimitValue money NULL,
IsMaterialsMemberPayOperator INT NOT NULL,
IsMaterialsMemberPayValue bit NULL,
ServiceMileageLimitOperator INT NOT NULL,
ServiceMileageLimitValue int NULL,
IsServiceMileageUnlimitedOperator INT NOT NULL,
IsServiceMileageUnlimitedValue bit NULL,
IsServiceMileageOverageAllowedOperator INT NOT NULL,
IsServiceMileageOverageAllowedValue bit NULL,
IsReimbursementOnlyOperator INT NOT NULL,
IsReimbursementOnlyValue bit NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramProductID int  NULL ,
	Category nvarchar(100)  NULL ,
	Service nvarchar(100)  NULL ,
	StartDate datetime  NULL ,
	EndDate datetime  NULL ,
	ServiceCoverageLimit money  NULL ,
	IsServiceCoverageBestValue bit  NULL ,
	MaterialsCoverageLimit money  NULL ,
	IsMaterialsMemberPay bit  NULL ,
	ServiceMileageLimit int  NULL ,
	IsServiceMileageUnlimited bit  NULL ,
	IsServiceMileageOverageAllowed bit  NULL ,
	IsReimbursementOnly bit  NULL 
) 

CREATE TABLE #FinalResults_temp( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramProductID int  NULL ,
	Category nvarchar(100)  NULL ,
	Service nvarchar(100)  NULL ,
	StartDate datetime  NULL ,
	EndDate datetime  NULL ,
	ServiceCoverageLimit money  NULL ,
	IsServiceCoverageBestValue bit  NULL ,
	MaterialsCoverageLimit money  NULL ,
	IsMaterialsMemberPay bit  NULL ,
	ServiceMileageLimit int  NULL ,
	IsServiceMileageUnlimited bit  NULL ,
	IsServiceMileageOverageAllowed bit  NULL ,
	IsReimbursementOnly bit  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@ProgramProductIDOperator','INT'),-1),
	T.c.value('@ProgramProductIDValue','int') ,
	ISNULL(T.c.value('@CategoryOperator','INT'),-1),
	T.c.value('@CategoryValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ServiceOperator','INT'),-1),
	T.c.value('@ServiceValue','nvarchar(100)') ,
	ISNULL(T.c.value('@StartDateOperator','INT'),-1),
	T.c.value('@StartDateValue','datetime') ,
	ISNULL(T.c.value('@EndDateOperator','INT'),-1),
	T.c.value('@EndDateValue','datetime') ,
	ISNULL(T.c.value('@ServiceCoverageLimitOperator','INT'),-1),
	T.c.value('@ServiceCoverageLimitValue','money') ,
	ISNULL(T.c.value('@IsServiceCoverageBestValueOperator','INT'),-1),
	T.c.value('@IsServiceCoverageBestValueValue','bit') ,
	ISNULL(T.c.value('@MaterialsCoverageLimitOperator','INT'),-1),
	T.c.value('@MaterialsCoverageLimitValue','money') ,
	ISNULL(T.c.value('@IsMaterialsMemberPayOperator','INT'),-1),
	T.c.value('@IsMaterialsMemberPayValue','bit') ,
	ISNULL(T.c.value('@ServiceMileageLimitOperator','INT'),-1),
	T.c.value('@ServiceMileageLimitValue','int') ,
	ISNULL(T.c.value('@IsServiceMileageUnlimitedOperator','INT'),-1),
	T.c.value('@IsServiceMileageUnlimitedValue','bit') ,
	ISNULL(T.c.value('@IsServiceMileageOverageAllowedOperator','INT'),-1),
	T.c.value('@IsServiceMileageOverageAllowedValue','bit') ,
	ISNULL(T.c.value('@IsReimbursementOnlyOperator','INT'),-1),
	T.c.value('@IsReimbursementOnlyValue','bit') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults_temp
SELECT 
  PP.ID AS ProgramProductID
, PC.Name AS Category
, PR.Name AS [Service]
, PP.StartDate
, PP.EndDate
, PP.ServiceCoverageLimit
, PP.IsServiceCoverageBestValue
, PP.MaterialsCoverageLimit
, PP.IsMaterialsMemberPay
, PP.ServiceMileageLimit
, PP.IsServiceMileageUnlimited
, PP.IsServiceMileageOverageAllowed
, PP.IsReimbursementOnly
FROM ProgramProduct PP
JOIN Program P (NOLOCK) ON P.ID = PP.ProgramID
JOIN Product PR (NOLOCK) ON PR.ID = PP.ProductID
JOIN ProductCategory PC (NOLOCK) ON PC.ID = PR.ProductCategoryID
WHERE PP.ProgramID = @ProgramID
ORDER BY PC.Sequence, PR.Name
INSERT INTO #FinalResults
SELECT 
	T.ProgramProductID,
	T.Category,
	T.Service,
	T.StartDate,
	T.EndDate,
	T.ServiceCoverageLimit,
	T.IsServiceCoverageBestValue,
	T.MaterialsCoverageLimit,
	T.IsMaterialsMemberPay,
	T.ServiceMileageLimit,
	T.IsServiceMileageUnlimited,
	T.IsServiceMileageOverageAllowed,
	T.IsReimbursementOnly
FROM #FinalResults_temp T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.ProgramProductIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 0 AND T.ProgramProductID IS NULL ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 1 AND T.ProgramProductID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 2 AND T.ProgramProductID = TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 3 AND T.ProgramProductID <> TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 7 AND T.ProgramProductID > TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 8 AND T.ProgramProductID >= TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 9 AND T.ProgramProductID < TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 10 AND T.ProgramProductID <= TMP.ProgramProductIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CategoryOperator = -1 ) 
 OR 
	 ( TMP.CategoryOperator = 0 AND T.Category IS NULL ) 
 OR 
	 ( TMP.CategoryOperator = 1 AND T.Category IS NOT NULL ) 
 OR 
	 ( TMP.CategoryOperator = 2 AND T.Category = TMP.CategoryValue ) 
 OR 
	 ( TMP.CategoryOperator = 3 AND T.Category <> TMP.CategoryValue ) 
 OR 
	 ( TMP.CategoryOperator = 4 AND T.Category LIKE TMP.CategoryValue + '%') 
 OR 
	 ( TMP.CategoryOperator = 5 AND T.Category LIKE '%' + TMP.CategoryValue ) 
 OR 
	 ( TMP.CategoryOperator = 6 AND T.Category LIKE '%' + TMP.CategoryValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ServiceOperator = -1 ) 
 OR 
	 ( TMP.ServiceOperator = 0 AND T.Service IS NULL ) 
 OR 
	 ( TMP.ServiceOperator = 1 AND T.Service IS NOT NULL ) 
 OR 
	 ( TMP.ServiceOperator = 2 AND T.Service = TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 3 AND T.Service <> TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 4 AND T.Service LIKE TMP.ServiceValue + '%') 
 OR 
	 ( TMP.ServiceOperator = 5 AND T.Service LIKE '%' + TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 6 AND T.Service LIKE '%' + TMP.ServiceValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.StartDateOperator = -1 ) 
 OR 
	 ( TMP.StartDateOperator = 0 AND T.StartDate IS NULL ) 
 OR 
	 ( TMP.StartDateOperator = 1 AND T.StartDate IS NOT NULL ) 
 OR 
	 ( TMP.StartDateOperator = 2 AND T.StartDate = TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 3 AND T.StartDate <> TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 7 AND T.StartDate > TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 8 AND T.StartDate >= TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 9 AND T.StartDate < TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 10 AND T.StartDate <= TMP.StartDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.EndDateOperator = -1 ) 
 OR 
	 ( TMP.EndDateOperator = 0 AND T.EndDate IS NULL ) 
 OR 
	 ( TMP.EndDateOperator = 1 AND T.EndDate IS NOT NULL ) 
 OR 
	 ( TMP.EndDateOperator = 2 AND T.EndDate = TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 3 AND T.EndDate <> TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 7 AND T.EndDate > TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 8 AND T.EndDate >= TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 9 AND T.EndDate < TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 10 AND T.EndDate <= TMP.EndDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ServiceCoverageLimitOperator = -1 ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 0 AND T.ServiceCoverageLimit IS NULL ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 1 AND T.ServiceCoverageLimit IS NOT NULL ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 2 AND T.ServiceCoverageLimit = TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 3 AND T.ServiceCoverageLimit <> TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 7 AND T.ServiceCoverageLimit > TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 8 AND T.ServiceCoverageLimit >= TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 9 AND T.ServiceCoverageLimit < TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 10 AND T.ServiceCoverageLimit <= TMP.ServiceCoverageLimitValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsServiceCoverageBestValueOperator = -1 ) 
 OR 
	 ( TMP.IsServiceCoverageBestValueOperator = 0 AND T.IsServiceCoverageBestValue IS NULL ) 
 OR 
	 ( TMP.IsServiceCoverageBestValueOperator = 1 AND T.IsServiceCoverageBestValue IS NOT NULL ) 
 OR 
	 ( TMP.IsServiceCoverageBestValueOperator = 2 AND T.IsServiceCoverageBestValue = TMP.IsServiceCoverageBestValueValue ) 
 OR 
	 ( TMP.IsServiceCoverageBestValueOperator = 3 AND T.IsServiceCoverageBestValue <> TMP.IsServiceCoverageBestValueValue ) 
 ) 

 AND 

 ( 
	 ( TMP.MaterialsCoverageLimitOperator = -1 ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 0 AND T.MaterialsCoverageLimit IS NULL ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 1 AND T.MaterialsCoverageLimit IS NOT NULL ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 2 AND T.MaterialsCoverageLimit = TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 3 AND T.MaterialsCoverageLimit <> TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 7 AND T.MaterialsCoverageLimit > TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 8 AND T.MaterialsCoverageLimit >= TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 9 AND T.MaterialsCoverageLimit < TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 10 AND T.MaterialsCoverageLimit <= TMP.MaterialsCoverageLimitValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsMaterialsMemberPayOperator = -1 ) 
 OR 
	 ( TMP.IsMaterialsMemberPayOperator = 0 AND T.IsMaterialsMemberPay IS NULL ) 
 OR 
	 ( TMP.IsMaterialsMemberPayOperator = 1 AND T.IsMaterialsMemberPay IS NOT NULL ) 
 OR 
	 ( TMP.IsMaterialsMemberPayOperator = 2 AND T.IsMaterialsMemberPay = TMP.IsMaterialsMemberPayValue ) 
 OR 
	 ( TMP.IsMaterialsMemberPayOperator = 3 AND T.IsMaterialsMemberPay <> TMP.IsMaterialsMemberPayValue ) 
 ) 

 AND 

 ( 
	 ( TMP.ServiceMileageLimitOperator = -1 ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 0 AND T.ServiceMileageLimit IS NULL ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 1 AND T.ServiceMileageLimit IS NOT NULL ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 2 AND T.ServiceMileageLimit = TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 3 AND T.ServiceMileageLimit <> TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 7 AND T.ServiceMileageLimit > TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 8 AND T.ServiceMileageLimit >= TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 9 AND T.ServiceMileageLimit < TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 10 AND T.ServiceMileageLimit <= TMP.ServiceMileageLimitValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsServiceMileageUnlimitedOperator = -1 ) 
 OR 
	 ( TMP.IsServiceMileageUnlimitedOperator = 0 AND T.IsServiceMileageUnlimited IS NULL ) 
 OR 
	 ( TMP.IsServiceMileageUnlimitedOperator = 1 AND T.IsServiceMileageUnlimited IS NOT NULL ) 
 OR 
	 ( TMP.IsServiceMileageUnlimitedOperator = 2 AND T.IsServiceMileageUnlimited = TMP.IsServiceMileageUnlimitedValue ) 
 OR 
	 ( TMP.IsServiceMileageUnlimitedOperator = 3 AND T.IsServiceMileageUnlimited <> TMP.IsServiceMileageUnlimitedValue ) 
 ) 

 AND 

 ( 
	 ( TMP.IsServiceMileageOverageAllowedOperator = -1 ) 
 OR 
	 ( TMP.IsServiceMileageOverageAllowedOperator = 0 AND T.IsServiceMileageOverageAllowed IS NULL ) 
 OR 
	 ( TMP.IsServiceMileageOverageAllowedOperator = 1 AND T.IsServiceMileageOverageAllowed IS NOT NULL ) 
 OR 
	 ( TMP.IsServiceMileageOverageAllowedOperator = 2 AND T.IsServiceMileageOverageAllowed = TMP.IsServiceMileageOverageAllowedValue ) 
 OR 
	 ( TMP.IsServiceMileageOverageAllowedOperator = 3 AND T.IsServiceMileageOverageAllowed <> TMP.IsServiceMileageOverageAllowedValue ) 
 ) 

 AND 

 ( 
	 ( TMP.IsReimbursementOnlyOperator = -1 ) 
 OR 
	 ( TMP.IsReimbursementOnlyOperator = 0 AND T.IsReimbursementOnly IS NULL ) 
 OR 
	 ( TMP.IsReimbursementOnlyOperator = 1 AND T.IsReimbursementOnly IS NOT NULL ) 
 OR 
	 ( TMP.IsReimbursementOnlyOperator = 2 AND T.IsReimbursementOnly = TMP.IsReimbursementOnlyValue ) 
 OR 
	 ( TMP.IsReimbursementOnlyOperator = 3 AND T.IsReimbursementOnly <> TMP.IsReimbursementOnlyValue ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ProgramProductID' AND @sortOrder = 'ASC'
	 THEN T.ProgramProductID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramProductID' AND @sortOrder = 'DESC'
	 THEN T.ProgramProductID END DESC ,

	 CASE WHEN @sortColumn = 'Category' AND @sortOrder = 'ASC'
	 THEN T.Category END ASC, 
	 CASE WHEN @sortColumn = 'Category' AND @sortOrder = 'DESC'
	 THEN T.Category END DESC ,

	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'ASC'
	 THEN T.Service END ASC, 
	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'DESC'
	 THEN T.Service END DESC ,

	 CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'ASC'
	 THEN T.StartDate END ASC, 
	 CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'DESC'
	 THEN T.StartDate END DESC ,

	 CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'ASC'
	 THEN T.EndDate END ASC, 
	 CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'DESC'
	 THEN T.EndDate END DESC ,

	 CASE WHEN @sortColumn = 'ServiceCoverageLimit' AND @sortOrder = 'ASC'
	 THEN T.ServiceCoverageLimit END ASC, 
	 CASE WHEN @sortColumn = 'ServiceCoverageLimit' AND @sortOrder = 'DESC'
	 THEN T.ServiceCoverageLimit END DESC ,

	 CASE WHEN @sortColumn = 'IsServiceCoverageBestValue' AND @sortOrder = 'ASC'
	 THEN T.IsServiceCoverageBestValue END ASC, 
	 CASE WHEN @sortColumn = 'IsServiceCoverageBestValue' AND @sortOrder = 'DESC'
	 THEN T.IsServiceCoverageBestValue END DESC ,

	 CASE WHEN @sortColumn = 'MaterialsCoverageLimit' AND @sortOrder = 'ASC'
	 THEN T.MaterialsCoverageLimit END ASC, 
	 CASE WHEN @sortColumn = 'MaterialsCoverageLimit' AND @sortOrder = 'DESC'
	 THEN T.MaterialsCoverageLimit END DESC ,

	 CASE WHEN @sortColumn = 'IsMaterialsMemberPay' AND @sortOrder = 'ASC'
	 THEN T.IsMaterialsMemberPay END ASC, 
	 CASE WHEN @sortColumn = 'IsMaterialsMemberPay' AND @sortOrder = 'DESC'
	 THEN T.IsMaterialsMemberPay END DESC ,

	 CASE WHEN @sortColumn = 'ServiceMileageLimit' AND @sortOrder = 'ASC'
	 THEN T.ServiceMileageLimit END ASC, 
	 CASE WHEN @sortColumn = 'ServiceMileageLimit' AND @sortOrder = 'DESC'
	 THEN T.ServiceMileageLimit END DESC ,

	 CASE WHEN @sortColumn = 'IsServiceMileageUnlimited' AND @sortOrder = 'ASC'
	 THEN T.IsServiceMileageUnlimited END ASC, 
	 CASE WHEN @sortColumn = 'IsServiceMileageUnlimited' AND @sortOrder = 'DESC'
	 THEN T.IsServiceMileageUnlimited END DESC ,

	 CASE WHEN @sortColumn = 'IsServiceMileageOverageAllowed' AND @sortOrder = 'ASC'
	 THEN T.IsServiceMileageOverageAllowed END ASC, 
	 CASE WHEN @sortColumn = 'IsServiceMileageOverageAllowed' AND @sortOrder = 'DESC'
	 THEN T.IsServiceMileageOverageAllowed END DESC ,

	 CASE WHEN @sortColumn = 'IsReimbursementOnly' AND @sortOrder = 'ASC'
	 THEN T.IsReimbursementOnly END ASC, 
	 CASE WHEN @sortColumn = 'IsReimbursementOnly' AND @sortOrder = 'DESC'
	 THEN T.IsReimbursementOnly END DESC 


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
DROP TABLE #FinalResults_temp
END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_program_productcategory_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_program_productcategory_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_program_productcategory_get] 3,NULL,NULL
 
CREATE PROCEDURE [dbo].[dms_program_productcategory_get]( 
   @ProgramID int, 
   @vehicleTypeID INT = NULL,
   @vehicleCategoryID INT = NULL   
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

	SELECT	PC.ID,
			PC.Name,
			PC.Sequence,
			CASE WHEN EL.ID IS NULL 
				THEN CAST(0 AS BIT)
				ELSE CAST(1 AS BIT)
			END AS [Enabled],
			PC.IsVehicleRequired
	FROM	ProductCategory PC 
	LEFT JOIN
	(	SELECT DISTINCT ProductCategoryID AS ID 
		FROM	ProgramProductCategory PC
		JOIN	[dbo].[fnc_getprogramsandparents](3) FNCP ON PC.ProgramID = FNCP.ProgramID
		AND		(VehicleTypeID = @vehicleTypeID OR VehicleTypeID IS NULL)
		AND		(VehicleCategoryID = @vehicleCategoryID OR VehicleCategoryID IS NULL)

	
	) EL ON PC.ID = EL.ID
	ORDER BY PC.Sequence

END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_questionanswer_values_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_questionanswer_values_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_questionanswer_values_get] 3,1,1
 
CREATE PROCEDURE [dbo].[dms_questionanswer_values_get]( 
   @ProgramID int,
   --@ProductCategoryID int,
   @VehicleTypeID int,
   @VehicleCategoryID int
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

DECLARE @Questions TABLE 
(
  ProductCategoryID int,
  ProductCategoryName NVARCHAR(MAX),
  ProductCategoryQuestionID int, 
  QuestionText nvarchar(4000),
  ControlType nvarchar(50),
  DataType nvarchar(50),
  HelpText nvarchar(4000),
  IsRequired bit,
  SubQuestionID int,
  RelatedAnswer nvarchar(255),
  Sequence int
)
DECLARE @relevantProductCategories TABLE
(
	ProductCategoryID INT,
	Sequence INT NULL
)
	INSERT INTO @relevantProductCategories
	SELECT DISTINCT ProductCategoryID,
			PC.Sequence 
	FROM	ProgramProductCategory PC
	JOIN	[dbo].[fnc_getprogramsandparents](@ProgramID) FNCP ON PC.ProgramID = FNCP.ProgramID
	AND		(VehicleTypeID = @VehicleTypeID OR VehicleTypeID IS NULL)
	-- KB: Do not consider @vehicleCategoryID here.By design, we load all the questions for a given vehicle type and show/hide questions relevant to vehiclecategory. Therefore, questions / product categories should not get filtered out here.
	--AND		(VehicleCategoryID = @vehicleCategoryID OR VehicleCategoryID IS NULL)
	WHERE	PC.IsActive = 1
	ORDER BY PC.Sequence 


-- Add questions related to Tow if they are not already in the list.
IF ( (SELECT COUNT(*) FROM @relevantProductCategories WHERE ProductCategoryID = 7) = 0)
BEGIN
	INSERT INTO @relevantProductCategories
	SELECT	PC.ID,
			PC.Sequence
	FROM ProductCategory PC WHERE Name like 'Tow%' AND PC.IsActive = 1
END

INSERT INTO @Questions 
SELECT DISTINCT 
	PCQ.ProductCategoryID,
	PC.Name,
	PCQ.ID, 
  PCQ.QuestionText,
  CT.Name as ControlType,
  DT.Name as DataType,
  PCQ.HelpText, 
  PCQ.IsRequired,  
  PCL.ProductCategoryQuestionID as SubQuestionID, 
  PVAL.Value as RelatedAnswer,
  PCQ.Sequence 
  FROM [dbo].ProductCategoryQuestion PCQ
  JOIN ProductCategoryQuestionVehicleType PCV ON PCV.ProductCategoryQuestionID = PCQ.ID 
	AND (PCV.VehicleTypeID IS NULL OR PCV.VehicleTypeID = @VehicleTypeID) 
	-- KB: Do not consider @vehicleCategoryID here.By design, we load all the questions for a given vehicle type and show/hide questions relevant to vehiclecategory. Therefore, questions / product categories should not get filtered out here.
	--AND (PCV.VehicleCategoryID IS NULL OR PCV.VehicleCategoryID = @VehicleCategoryID)
	AND PCV.IsActive = 1   
  JOIN ProductCategory PC ON PCQ.ProductCategoryID = PC.ID
  LEFT JOIN ControlType CT ON CT.ID = PCQ.ControlTypeID
  LEFT JOIN DataType DT on DT.ID = PCQ.DataTypeID
  LEFT JOIN ProductCategoryQuestionLink PCL on PCL.ParentProductCategoryQuestionID = PCV.ProductCategoryQuestionID
  AND PCL.IsActive = 1
  LEFT JOIN ProductCategoryQuestionValue PVAL on PVAL.ID = PCL.ProductCategoryQuestionValueID
  AND PVAL.IsActive = 1 
  WHERE PCQ.ProductCategoryID IN (SELECT ProductCategoryID FROM @relevantProductCategories )
  AND PCQ.IsActive = 1
  
  UNION ALL
  
SELECT DISTINCT 
PCQ.ProductCategoryID,
PC.Name AS ProductCategoryName,
PCQ.ID, 

  PCQ.QuestionText,
  CT.Name as ControlType,
  DT.Name as DataType,
  PCQ.HelpText, 
  PCQ.IsRequired,  
  PCL.ProductCategoryQuestionID as SubQuestionID, 
  PVAL.Value as RelatedAnswer,
  PCQ.Sequence 
  FROM [dbo].ProductCategoryQuestion PCQ
  JOIN ProductCategoryQuestionProgram PCP ON PCP.ProductCategoryQuestionID = PCQ.ID 
	AND (PCP.VehicleTypeID IS NULL OR PCP.VehicleTypeID = @VehicleTypeID )
	-- KB: Do not consider @vehicleCategoryID here.By design, we load all the questions for a given vehicle type and show/hide questions relevant to vehiclecategory. Therefore, questions / product categories should not get filtered out here.
	--AND (PCP.VehicleCategoryID IS NULL OR PCP.VehicleCategoryID = @VehicleCategoryID)
	AND PCP.IsActive = 1 
	JOIN ProductCategory PC ON PCQ.ProductCategoryID = PC.ID
  JOIN fnc_GetProgramsandParents(@ProgramID) fncP on fncP.ProgramID = PCP.ProgramID 
  LEFT JOIN ControlType CT ON CT.ID = PCQ.ControlTypeID
  LEFT JOIN DataType DT on DT.ID = PCQ.DataTypeID
  LEFT JOIN ProductCategoryQuestionLink PCL on PCL.ParentProductCategoryQuestionID = PCP.ProductCategoryQuestionID
  AND PCL.IsActive = 1
  LEFT JOIN ProductCategoryQuestionValue PVAL on PVAL.ID = PCL.ProductCategoryQuestionValueID
  AND PVAL.IsActive = 1 
  WHERE PCQ.ProductCategoryID IN (SELECT ProductCategoryID FROM @relevantProductCategories )
  AND PCQ.IsActive = 1
  ORDER BY PCQ.Sequence 
  
--SELECT * FROM @Questions 

SELECT PCV.ProductCategoryQuestionID, PCV.Value, PCV.IsPossibleTow, PCV.Sequence FROM ProductCategoryQuestionValue PCV
JOIN @Questions Q ON Q.ProductCategoryQuestionID = PCV.ProductCategoryQuestionID 
WHERE PCV.IsActive = 1
AND  Q.ProductCategoryName NOT IN ('Repair','Billing')
GROUP BY PCV.ProductCategoryQuestionID, PCV.Value, PCV.IsPossibleTow,PCV.Sequence
ORDER BY PCV.ProductCategoryQuestionID,PCV.Sequence 

END
GO
/* KB: This is procedure is not in use and the logic is moved to dms_Service_Save. The SP is retained in TFS for reference purposes only */
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_servicerequest_productids_set]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_servicerequest_productids_set] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
-- EXEC [dbo].[dms_servicerequest_productids_set] 2,5,1,1,0,3
CREATE PROCEDURE [dbo].[dms_servicerequest_productids_set]( 
	@serviceRequestID INT,
	@ProductCategoryID INT,
	@VehicleTypeID INT,
	@VehicleCategoryID INT,
	@IsPossibleTow BIT,
	@programID INT
)
AS
BEGIN

--SET @ProductCategoryID = (Select ID From ProductCategory Where Name = 'Jump')
--SET @VehicleTypeID = (Select ID From VehicleType Where Name = 'Auto')
--SET @VehicleCategoryID = (Select ID From VehicleCategory Where Name = 'HeavyDuty')
--SET @IsPossibleTow = 'TRUE'
	DECLARE @tmpPrograms TABLE
	(
		LevelID INT IDENTITY(1,1),
		ProgramID INT
	)
	
	INSERT INTO @tmpPrograms
	SELECT ProgramID FROM fnc_GetProgramsandParents (@programID)

	--DEBUG: SELECT * FROM @tmpPrograms
	
	DECLARE @TowProductCategoryID int
	DECLARE @primaryProductID INT
	DECLARE @secondaryProductID INT
	DECLARE @isPrimaryServiceCovered BIT
	DECLARE @isSecondaryServiceCovered BIT

	SET @primaryProductID = NULL
	SET @secondaryProductID = NULL
	
	SET @TowProductCategoryID = (Select ID From ProductCategory Where Name = 'Tow')

	;WITH wPrimaryProducts
	AS
	(
	SELECT	ROW_NUMBER() OVER (PARTITION BY P.ID ORDER BY T.LevelID ASC) AS RowNum,
			T.ProgramID AS ProgramID,			
			p.ID AS ProductID,
			pp.ID AS ProgramProductID,
			pp.IsReimbursementOnly
	FROM	dbo.Product p
	JOIN	dbo.ProductType pt ON p.ProductTypeID = pt.ID
	JOIN	dbo.ProductSubType pst ON p.ProductSubTypeID = pst.ID
	JOIN	dbo.ProductCategory pc ON p.ProductCategoryID = pc.ID
	JOIN	dbo.ProgramProduct pp ON pp.ProductID = P.ID --AND pp.ProgramID = @programID
	JOIN	@tmpPrograms T ON pp.ProgramID = T.ProgramID
	WHERE	pt.Name = 'Service'
	AND		pst.Name = 'PrimaryService'
	AND		pc.ID = @ProductCategoryID
	AND		(p.VehicleTypeID = @VehicleTypeID OR p.VehicleTypeID IS NULL)
	AND (p.VehicleCategoryID = @VehicleCategoryID OR p.VehicleCategoryID IS NULL)
	)
	
	SELECT	@primaryProductID = ProductID,
			@isPrimaryServiceCovered = CASE WHEN ProgramProductID IS NULL OR ISNULL(IsReimbursementOnly, 0) = 1 
											THEN 0 
											ELSE 1 
										END		
	FROM wPrimaryProducts
	
	;WITH wSecondaryProducts
	AS
	(
	SELECT	ROW_NUMBER() OVER (PARTITION BY P.ID ORDER BY T.LevelID ASC) AS RowNum,
			T.ProgramID AS ProgramID,			
			p.ID AS ProductID,
			pp.ID AS ProgramProductID,
			pp.IsReimbursementOnly
	FROM	dbo.Product p
	JOIN	dbo.ProductType pt ON p.ProductTypeID = pt.ID
	JOIN	dbo.ProductSubType pst ON p.ProductSubTypeID = pst.ID
	JOIN	dbo.ProductCategory pc ON p.ProductCategoryID = pc.ID
	JOIN	dbo.ProgramProduct pp ON pp.ProductID = p.ID  -- AND pp.ProgramID = @programID
	JOIN	@tmpPrograms T ON pp.ProgramID = T.ProgramID
	WHERE	pt.Name = 'Service'
	AND		pst.Name = 'PrimaryService'
	AND		@IsPossibleTow = 'TRUE'
	AND		pc.ID = @TowProductCategoryID
	AND		(p.VehicleTypeID = @VehicleTypeID OR p.VehicleTypeID IS NULL)
	AND		(p.VehicleCategoryID = @VehicleCategoryID OR p.VehicleCategoryID IS NULL)	
	)
	
	SELECT	@secondaryProductID = ProductID,
			@isSecondaryServiceCovered = CASE WHEN ProgramProductID IS NULL OR ISNULL(IsReimbursementOnly, 0) = 1 
											THEN 0 
											ELSE 1 
										END		
	FROM wSecondaryProducts

	
	UPDATE	ServiceRequest
	SET		PrimaryProductID = @primaryProductID,
			SecondaryProductID = @secondaryProductID,
			IsPrimaryProductCovered = @isPrimaryServiceCovered,
			IsSecondaryProductCovered = @isSecondaryServiceCovered
	WHERE	ID = @serviceRequestID
	
	
END


GO
 
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Service_Save]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Service_Save]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 
CREATE PROC dms_Service_Save(@serviceRequestID INT
,@inputXML NVARCHAR(MAX)
,@userName NVARCHAR(50)
,@vehicleTypeID INT = NULL)  
AS  
BEGIN  
 DECLARE @idoc int  
 EXEC sp_xml_preparedocument @idoc OUTPUT, @inputXML  
   
 DECLARE @tmpForInput TABLE  
 (  
  ServiceRequestID INT NULL,  
  ProductCategoryQuestionID INT NOT NULL,  
  Answer NVARCHAR(MAX) NULL,  
  CreateDate DATETIME DEFAULT GETDATE(),  
  CreatedBy NVARCHAR(50) NULL,  
  ModifyDate DATETIME DEFAULT GETDATE(),  
  ModifiedBy NVARCHAR(50) NULL  
 )  
  
 INSERT INTO @tmpForInput( ProductCategoryQuestionID,  
  Answer  
    )  
 SELECT    
  ProductCategoryQuestionID,  
  Answer  
 FROM   
  OPENXML (@idoc,'/ROW/Data',1) WITH (  
   ProductCategoryQuestionID INT,  
   Answer NVARCHAR(MAX)  
  )   
   
 UPDATE @tmpForInput  
 SET  ServiceRequestID = @serviceRequestID,  
   CreatedBy    = @userName,  
   ModifiedBy    = @userName  
 
 
-- KB: Let's clear off existing values and add the new values.
 DELETE FROM ServiceRequestDetail WHERE ServiceRequestID = @serviceRequestID
   
 -- INSERT NEW Records  
 INSERT INTO  ServiceRequestDetail   
 SELECT  
  T.[ServiceRequestID],  
  T.[ProductCategoryQuestionID],  
  T.[Answer],  
  T.[CreateDate],  
  T.[CreatedBy],  
  T.[ModifyDate],  
  T.[ModifiedBy]  
 FROM @tmpForInput T   
 WHERE T.ProductCategoryQuestionID NOT IN (SELECT ProductCategoryQuestionID FROM ServiceRequestDetail WHERE ServiceRequestID = @serviceRequestID)    
  
 -- CR: 1097 : Set the product IDs based on the answers provided.
 DECLARE @vehicleCategoryID INT = NULL
 DECLARE @isPossibleTow BIT = 0
 DECLARE @productCategoryID INT = NULL
 DECLARE @programID INT = NULL
 DECLARE @pPrimaryProductID INT = NULL
 DECLARE @pSecondaryProductID INT = NULL
  
 DECLARE @primaryProductID INT = NULL
 DECLARE @secondaryProductID INT = NULL
 DECLARE @isPrimaryServiceCovered BIT = NULL
 DECLARE @isSecondaryServiceCovered BIT = NULL
 DECLARE @towProductCategoryID int = NULL
 SET @towProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tow')
 DECLARE @tmpPrograms TABLE
 (
 LevelID INT IDENTITY(1,1),
 ProgramID INT
 )
 SELECT @vehicleCategoryID = SR.VehicleCategoryID,
   @productCategoryID = SR.ProductCategoryID,
   @isPossibleTow = SR.IsPossibleTow,
   @programID = C.ProgramID
 FROM  ServiceRequest SR,
   [Case] C
 WHERE  SR.CaseID = C.ID
 AND  SR.ID = @serviceRequestID
  
 INSERT INTO @tmpPrograms
 SELECT ProgramID FROM fnc_GetProgramsandParents (@programID)
  /*
 *  Determine PrimaryProducID
 *  Get value from ServiceType dropdown
 *  Look at all the answers to those category questions and see if any have a ProductID defined.
 *  If a ProductCategoryQuestionValue.ProductID is defined for any of the answers given for this category then use that ProductID to set PrimaryProductID
 *  Right now there is only 1 question/answer that will have a product defined and that is Lockout / Do you need a locksmith? / Yes / ProductID=9
 *  If Tow is selected in the ServiceType dropdown then there might be a special type tow product defined on an answer under towing. This will go in PrimaryProductID because Tow is set as the primary service.
 */
 
 SELECT @pPrimaryProductID = W.ProductID
 FROM
 (SELECT TOP 1 PCQV.ProductID
 FROM  ProductCategoryQuestionValue PCQV
 JOIN  ServiceRequestDetail SRD ON PCQV.ProductCategoryQuestionID = SRD.ProductCategoryQuestionID AND SRD.Answer = PCQV.Value
 JOIN  ProductCategoryQuestion PCQ ON PCQV.ProductCategoryQuestionID = PCQ.ID
 WHERE  SRD.ServiceRequestID = @serviceRequestID
 AND   PCQ.ProductCategoryID = @productCategoryID
 AND   PCQV.ProductID IS NOT NULL) W
    /*Tim's SQL: Logic to select Basic Lockout over Locksmith within Lockout Product Category */
    
IF @pPrimaryProductID IS NULL AND @productCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Lockout')
BEGIN
 SET @pPrimaryProductID = (SELECT ID FROM Product WHERE Name = 'Basic Lockout')
END
/* Select Tire Change over Tire Repair when one of the tire services is not specifically selected */
IF @pPrimaryProductID IS NULL AND @productCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tire')
BEGIN
 SET @pPrimaryProductID = (SELECT ID FROM Product WHERE Name like 'Tire Change%' AND VehicleCategoryID = @VehicleCategoryID)
END
/*  
 *  Determine SecondaryProductID
 *  If IsPossibleTow = Yes then look for a secondary product id.
 *  It turns out that we can't just pass Tow-LD every time. We have to look at some answers to Tow questions to see if there is a special type of tow needed.
 *  Look through the Tow category answers to see if any have a ProductID defined, if they do then use that to set the SecondaryProductID sent to the stored proc.
 *  Right now there is only one question: Speical Tow that has answers that will have ProductID's defined. Flatbed Tow, Enclosed Hauler, etc.
 */
 
 IF @isPossibleTow = 1
 BEGIN
  SELECT @pSecondaryProductID = W.ProductID
  FROM
  (SELECT TOP 1 PCQV.ProductID
  FROM  ProductCategoryQuestionValue PCQV
  JOIN  ProductCategoryQuestion PCQ ON PCQ.ID = PCQV.ProductCategoryQuestionID
  JOIN  ServiceRequestDetail SRD ON PCQV.ProductCategoryQuestionID = SRD.ProductCategoryQuestionID AND SRD.Answer = PCQV.Value
  WHERE  SRD.ServiceRequestID = @serviceRequestID
  AND   PCQ.ProductCategoryID = @towProductCategoryID
  AND   PCQV.ProductID IS NOT NULL
  ) W
  
 END
 
 ;WITH wPrimaryProducts
 AS
 (
  SELECT ROW_NUMBER() OVER (PARTITION BY P.ID ORDER BY T.LevelID ASC) AS RowNum,
  T.ProgramID AS ProgramID, 
  p.ID AS ProductID,
  pp.ID AS ProgramProductID,
  pp.IsReimbursementOnly
  FROM dbo.Product p
  JOIN dbo.ProductType pt ON p.ProductTypeID = pt.ID
  JOIN dbo.ProductSubType pst ON p.ProductSubTypeID = pst.ID
  JOIN dbo.ProductCategory pc ON p.ProductCategoryID = pc.ID
  JOIN dbo.ProgramProduct pp ON pp.ProductID = P.ID --AND pp.ProgramID = @programID
  JOIN @tmpPrograms T ON pp.ProgramID = T.ProgramID
  WHERE 
  (p.ID = @pPrimaryProductID)
  OR
  (
   @pPrimaryProductID IS NULL
   AND pt.Name = 'Service'
   AND pst.Name = 'PrimaryService'
   AND pc.ID = @productCategoryID
   AND (p.VehicleTypeID = @vehicleTypeID OR p.VehicleTypeID IS NULL)
   AND (p.VehicleCategoryID = @vehicleCategoryID OR p.VehicleCategoryID IS NULL)
  )
 )
 SELECT @primaryProductID = ProductID,
 @isPrimaryServiceCovered = CASE WHEN ProgramProductID IS NULL OR ISNULL(IsReimbursementOnly, 0) = 1 
         THEN 0 
         ELSE 1 
        END 
 FROM wPrimaryProducts
 ;WITH wSecondaryProducts
 AS
 (
  SELECT ROW_NUMBER() OVER (PARTITION BY P.ID ORDER BY T.LevelID ASC) AS RowNum,
  T.ProgramID AS ProgramID, 
  p.ID AS ProductID,
  pp.ID AS ProgramProductID,
  pp.IsReimbursementOnly
  FROM dbo.Product p
  JOIN dbo.ProductType pt ON p.ProductTypeID = pt.ID
  JOIN dbo.ProductSubType pst ON p.ProductSubTypeID = pst.ID
  JOIN dbo.ProductCategory pc ON p.ProductCategoryID = pc.ID
  JOIN dbo.ProgramProduct pp ON pp.ProductID = p.ID -- AND pp.ProgramID = @programID
  JOIN @tmpPrograms T ON pp.ProgramID = T.ProgramID
  WHERE 
  (p.ID = @pSecondaryProductID)
  OR
  (
   @pSecondaryProductID IS NULL
   AND pt.Name = 'Service'
   AND pst.Name = 'PrimaryService'
   AND @isPossibleTow = 'TRUE'
   AND pc.ID = @towProductCategoryID
   AND (p.VehicleTypeID = @vehicleTypeID OR p.VehicleTypeID IS NULL)
   AND (p.VehicleCategoryID = @vehicleCategoryID OR p.VehicleCategoryID IS NULL) 
  )
 )
 SELECT @secondaryProductID = ProductID,
   @isSecondaryServiceCovered = CASE WHEN ProgramProductID IS NULL OR ISNULL(IsReimbursementOnly, 0) = 1 
            THEN 0 
            ELSE 1 
           END 
 FROM wSecondaryProducts
 UPDATE ServiceRequest
 SET 
  PrimaryProductID = @primaryProductID,
  SecondaryProductID = @secondaryProductID,
  IsPrimaryProductCovered = @isPrimaryServiceCovered,
  IsSecondaryProductCovered = @isSecondaryServiceCovered
 WHERE ID = @serviceRequestID

  
   
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
 WHERE id = object_id(N'[dbo].[dms_vendor_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_vendor_list] @pageSize=5000 @whereClauseXML="<ROW>\r\n  <Filter VendorNumber=\'1,4\' />\r\n</ROW>"
 
 CREATE PROCEDURE [dbo].[dms_vendor_list](
   
 @whereClauseXML NVARCHAR(4000) = NULL 

 , @startInd Int = 1 

 , @endInd BIGINT = 5000 

 , @pageSize int = 10  

 , @sortColumn nvarchar(100)  = 'VendorName' 

 , @sortOrder nvarchar(100) = 'ASC' 

  

 ) 

 AS 

 BEGIN   
 SET FMTONLY OFF  
  SET NOCOUNT ON  
  
CREATE TABLE #FinalResultsFiltered  
(  
 ContractStatus NVARCHAR(100) NULL,  
 VendorID INT NULL,  
 VendorNumber NVARCHAR(50) NULL,  
 VendorName NVARCHAR(255) NULL,  
 City NVARCHAR(100) NULL,  
 StateProvince NVARCHAR(10) NULL,  
 CountryCode NVARCHAR(2) NULL,  
 OfficePhone NVARCHAR(50) NULL,  
 AdminRating INT NULL,  
 InsuranceExpirationDate DATETIME NULL,  
 PaymentMethod NVARCHAR(50) NULL,  
 VendorStatus NVARCHAR(50) NULL,  
 VendorRegion NVARCHAR(50) NULL,  
 PostalCode NVARCHAR(20) NULL  ,
 POCount INT NULL
)  
  
CREATE TABLE #FinalResultsSorted  
(  
 RowNum BIGINT NOT NULL IDENTITY(1,1),  
 ContractStatus NVARCHAR(100) NULL,  
 VendorID INT NULL,  
 VendorNumber NVARCHAR(50) NULL,  
 VendorName NVARCHAR(255) NULL,  
 City NVARCHAR(100) NULL,  
 StateProvince NVARCHAR(10) NULL,  
 CountryCode NVARCHAR(2) NULL,  
 OfficePhone NVARCHAR(50) NULL,  
 AdminRating INT NULL,  
 InsuranceExpirationDate DATETIME NULL,  
 PaymentMethod NVARCHAR(50) NULL,  
 VendorStatus NVARCHAR(50) NULL,  
 VendorRegion NVARCHAR(50) NULL,  
 PostalCode NVARCHAR(20) NULL ,
 POCount INT NULL 
)  
  
DECLARE @idoc int  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
VendorNameOperator NVARCHAR(50) NULL,  
VendorName NVARCHAR(MAX) NULL,  
VendorNumber NVARCHAR(50) NULL,  
CountryID INT NULL,  
StateProvinceID INT NULL,  
City nvarchar(255) NULL,  
VendorStatus NVARCHAR(100) NULL,  
VendorRegion NVARCHAR(100) NULL,  
PostalCode NVARCHAR(20) NULL,  
IsLevy BIT NULL  ,
HasPO BIT NULL
)  
  
DECLARE @VendorNameOperator NVARCHAR(50) ,  
@VendorName NVARCHAR(MAX) ,  
@VendorNumber NVARCHAR(50) ,  
@CountryID INT ,  
@StateProvinceID INT ,  
@City nvarchar(255) ,  
@VendorStatus NVARCHAR(100) ,  
@VendorRegion NVARCHAR(100) ,  
@PostalCode NVARCHAR(20) ,  
@IsLevy BIT,
@HasPO BIT   ,
@programID INT	= NULL
  
INSERT INTO @tmpForWhereClause  
SELECT    
 VendorNameOperator,  
 VendorName ,  
 VendorNumber,  
 CountryID,  
 StateProvinceID,  
 City,  
 VendorStatus,  
 VendorRegion,  
    PostalCode,  
    IsLevy ,
	HasPo
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
 VendorNameOperator NVARCHAR(50),  
 VendorName NVARCHAR(MAX),  
 VendorNumber NVARCHAR(50),   
 CountryID INT,  
 StateProvinceID INT,  
 City nvarchar(255),   
 VendorStatus NVARCHAR(100),  
 VendorRegion NVARCHAR(100),  
 PostalCode NVARCHAR(20),  
 IsLevy BIT ,
 HasPo BIT
)   
  
SELECT    
  @VendorNameOperator = VendorNameOperator ,  
  @VendorName = VendorName ,  
  @VendorNumber = VendorNumber,  
  @CountryID = CountryID,  
  @StateProvinceID = StateProvinceID,  
  @City = City,  
  @VendorStatus = VendorStatus,  
  @VendorRegion = VendorRegion,  
  @PostalCode = PostalCode,  
  @IsLevy = IsLevy  ,
  @HasPO = HasPO
FROM @tmpForWhereClause  
  
--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
-- LOGIC : START  

DECLARE @PoCount AS TABLE(VendorID INT NULL,PoCount INT NULL)
INSERT INTO @PoCount
SELECT V.ID,
	   COUNT(PO.ID) FROM PurchaseOrder PO 
	   LEFT JOIN VendorLocation VL ON PO.VendorLocationID = VL.ID
	   LEFT JOIN Vendor V ON VL.VendorID = V.ID
WHERE  PO.IsActive = 1
GROUP BY V.ID 
  
DECLARE @vendorEntityID INT, @businessAddressTypeID INT, @officePhoneTypeID INT  
SELECT @vendorEntityID = ID FROM Entity WHERE Name = 'Vendor'  
SELECT @businessAddressTypeID = ID FROM AddressType WHERE Name = 'Business'  
SELECT @officePhoneTypeID = ID FROM PhoneType WHERE Name = 'Office'  
  
;WITH wVendorAddresses  
AS  
(   
 SELECT ROW_NUMBER() OVER ( PARTITION BY RecordID, AddressTypeID ORDER BY ID ) AS RowNum,  
   *  
 FROM AddressEntity   
 WHERE EntityID = @vendorEntityID  
 AND  AddressTypeID = @businessAddressTypeID  
),
wVendorPhone
AS

(

	SELECT ROW_NUMBER() OVER ( PARTITION BY RecordID, PhoneTypeID ORDER BY ID DESC ) AS RowNum,

			*

	FROM	PhoneEntity 

	WHERE	EntityID = @vendorEntityID

	AND		PhoneTypeID = @officePhoneTypeID

)

INSERT INTO #FinalResultsFiltered  
SELECT DISTINCT  
  --CASE WHEN C.VendorID IS NOT NULL   
  --  THEN 'Contracted'   
  --  ELSE 'Not Contracted'   
  --  END AS ContractStatus  
  --NULL As ContractStatus  
  CASE  
   WHEN ContractedVendors.ContractID IS NOT NULL   
    AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'  
   ELSE 'Not Contracted'   
  END AS ContractStatus  
  , V.ID AS VendorID  
  , V.VendorNumber AS VendorNumber  
  --, V.Name AS VendorName  
  ,v.Name +	
	CASE WHEN VPCNDP.VendorID IS NOT NULL THEN ' (P)' ELSE '' END  + 
	CASE WHEN VPFDT.VendorID IS NOT NULL 
			THEN ' (DT)' 
	ELSE '' END VendorName
  , AE.City AS City  
  , AE.StateProvince AS State  
  , AE.CountryCode AS Country  
  , PE.PhoneNumber AS OfficePhone  
  , V.AdministrativeRating AS AdminRating  
  , V.InsuranceExpirationDate AS InsuranceExpirationDate  
  , VACH.BankABANumber AS PaymentMethod -- To be calculated in the next step.  
  , VS.Name AS VendorStatus  
  , VR.Name AS VendorRegion  
  , AE.PostalCode  
  , ISNULL((SELECT PoCount FROM @PoCount POD WHERE POD.VendorID = V.ID),0) AS POCount
FROM Vendor V WITH (NOLOCK)  
--LEFT JOIN   VendorLocation VL ON V.ID = VL.VendorID
--Left Outer Join VendorProduct VPFDT ON VPFDT.VendorID = V.ID and VPFDT.ProductID = (Select ID from Product where Name = 'Ford Direct Tow') and VPFDT.IsActive = 1
--Left Outer Join VendorProduct VPCNDP on VPCNDP.VendorID = V.ID and VPCNDP.ProductID = (Select ID from Product where Name = 'CoachNet Dealer Partner') and VPCNDP.IsActive = 1
--LEFT JOIN   PurchaseOrder PO ON VL.ID = PO.VendorLocationID AND ISNULL(PO.IsActive,0) = 1
LEFT JOIN [dbo].[fnGetDirectTowVendors]() VPFDT ON VPFDT.VendorID = V.ID
LEFT JOIN [dbo].[fnGetCoachNetDealerPartnerVendors]() VPCNDP ON VPCNDP.VendorID = V.ID
LEFT JOIN wVendorAddresses AE ON AE.RecordID = V.ID AND AE.RowNum = 1  
LEFT JOIN	wVendorPhone PE ON PE.RecordID = V.ID AND PE.RowNum = 1  
LEFT JOIN VendorStatus VS ON VS.ID = V.VendorStatusID  
LEFT JOIN VendorACH VACH ON VACH.VendorID = V.ID  
LEFT JOIN VendorRegion VR ON VR.ID=V.VendorRegionID  
LEFT OUTER JOIN(  
   SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID  
   FROM dbo.fnGetContractedVendors() cv  
   ) ContractedVendors ON v.ID = ContractedVendors.VendorID   
--LEFT OUTER JOIN (SELECT VendorID, MAX(CreateDate) AS [CreateDate] FROM [Contract] WHERE IsActive = 1 GROUP BY VendorID) C ON C.VendorID = V.ID  =
WHERE V.IsActive = 1  -- Not deleted    
AND  (@VendorNumber IS NULL OR @VendorNumber = V.VendorNumber)  
AND  (@CountryID IS NULL OR @CountryID = AE.CountryID)  
AND  (@StateProvinceID IS NULL OR @StateProvinceID = AE.StateProvinceID)  
AND  (@City IS NULL OR @City = AE.City)  
AND  (@PostalCode IS NULL OR @PostalCode = AE.PostalCode)  
AND  (@IsLevy IS NULL OR @IsLevy = ISNULL(V.IsLevyActive,0))  
AND  (@VendorStatus IS NULL OR VS.ID IN (SELECT Item FROM [dbo].[fnSplitString](@VendorStatus,',') ) )  
AND  (@VendorRegion IS NULL OR VR.ID IN (SELECT Item FROM [dbo].[fnSplitString](@VendorRegion,',') ) )  
AND  (    
   (@VendorNameOperator IS NULL )  
   OR  
   (@VendorNameOperator = 'Begins with' AND V.Name LIKE  @VendorName + '%')  
   OR  
   (@VendorNameOperator = 'Is equal to' AND V.Name =  @VendorName )  
   OR  
   (@VendorNameOperator = 'Ends with' AND V.Name LIKE  '%' + @VendorName)  
   OR  
   (@VendorNameOperator = 'Contains' AND V.Name LIKE  '%' + @VendorName + '%')  
  )  
 --GROUP BY 

	--	ContractStatus,
	--	V.ID,
	--	V.VendorNumber,
	--	V.Name,
	--	AE.City,
	--	AE.StateProvince,
	--	AE.CountryCode,
	--	PE.PhoneNumber,
	--	V.AdministrativeRating,
	--	V.InsuranceExpirationDate,
	--	VACH.BankABANumber,
	--	VS.Name,
	--	VR.Name,
	--	AE.PostalCode,
	--	ContractedVendors.ContractRateScheduleID,
	--	ContractedVendors.ContractID
 --UPDATE #FinalResultsFiltered  
 --SET ContractStatus = CASE WHEN C.VendorID IS NOT NULL   
 --      THEN 'Contracted'   
 --      ELSE 'Not Contracted'   
 --      END,  
 -- PaymentMethod =  CASE  
 --      WHEN ISNULL(F.PaymentMethod,'') = '' THEN 'Check'  
 --      ELSE 'DirectDeposit'  
 --      END  
 --FROM #FinalResultsFiltered F  
 --LEFT OUTER JOIN (SELECT VendorID, MAX(CreateDate) AS [CreateDate] FROM [Contract] WHERE IsActive = 1 GROUP BY VendorID) C ON C.VendorID = F.VendorID  
   
 INSERT INTO #FinalResultsSorted  
 SELECT   ContractStatus  
  , VendorID  
  , VendorNumber  
  , VendorName  
  , City  
  , StateProvince  
  , CountryCode  
  , OfficePhone  
  , AdminRating  
  , InsuranceExpirationDate  
  , PaymentMethod  
  , VendorStatus  
  , VendorRegion  
  , PostalCode  
  , POCount
 FROM #FinalResultsFiltered T   
 WHERE	(@HasPO IS NULL OR @HasPO = 0 OR T.POCount > 0)
 ORDER BY   
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'ASC'  
  THEN T.ContractStatus END ASC,   
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'DESC'  
  THEN T.ContractStatus END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'ASC'  
  THEN T.VendorID END ASC,   
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'DESC'  
  THEN T.VendorID END DESC ,  
    
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'  
  THEN T.VendorNumber END ASC,   
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'  
  THEN T.VendorNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'ASC'  
  THEN T.VendorName END ASC,   
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'DESC'  
  THEN T.VendorName END DESC ,  
  
  CASE WHEN @sortColumn = 'City' AND @sortOrder = 'ASC'  
  THEN T.City END ASC,   
  CASE WHEN @sortColumn = 'City' AND @sortOrder = 'DESC'  
  THEN T.City END DESC ,  
    
  CASE WHEN @sortColumn = 'StateProvince' AND @sortOrder = 'ASC'  
  THEN T.StateProvince END ASC,   
  CASE WHEN @sortColumn = 'StateProvince' AND @sortOrder = 'DESC'  
  THEN T.StateProvince END DESC ,  
  
  CASE WHEN @sortColumn = 'CountryCode' AND @sortOrder = 'ASC'  
  THEN T.CountryCode END ASC,   
  CASE WHEN @sortColumn = 'CountryCode' AND @sortOrder = 'DESC'  
  THEN T.CountryCode END DESC ,  
    
  CASE WHEN @sortColumn = 'OfficePhone' AND @sortOrder = 'ASC'  
  THEN T.OfficePhone END ASC,   
  CASE WHEN @sortColumn = 'OfficePhone' AND @sortOrder = 'DESC'  
  THEN T.OfficePhone END DESC ,  
    
  CASE WHEN @sortColumn = 'AdminRating' AND @sortOrder = 'ASC'  
  THEN T.AdminRating END ASC,   
  CASE WHEN @sortColumn = 'AdminRating' AND @sortOrder = 'DESC'  
  THEN T.AdminRating END DESC ,  
    
  CASE WHEN @sortColumn = 'InsuranceExpirationDate' AND @sortOrder = 'ASC'  
  THEN T.InsuranceExpirationDate END ASC,   
  CASE WHEN @sortColumn = 'InsuranceExpirationDate' AND @sortOrder = 'DESC'  
  THEN T.InsuranceExpirationDate END DESC ,  
    
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'ASC'  
  THEN T.VendorStatus END ASC,   
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'DESC'  
  THEN T.VendorStatus END DESC ,  
    
  CASE WHEN @sortColumn = 'VendorRegion' AND @sortOrder = 'ASC'  
  THEN T.VendorRegion END ASC,   
  CASE WHEN @sortColumn = 'VendorRegion' AND @sortOrder = 'DESC'  
  THEN T.VendorRegion END DESC ,  
  --VendorRegion  
  CASE WHEN @sortColumn = 'PaymentMethod' AND @sortOrder = 'ASC'  
  THEN T.PaymentMethod END ASC,   
  CASE WHEN @sortColumn = 'PaymentMethod' AND @sortOrder = 'DESC'  
  THEN T.PaymentMethod END DESC ,  
     
  CASE WHEN @sortColumn = 'PostalCode' AND @sortOrder = 'ASC'  
  THEN T.PostalCode END ASC,   
  CASE WHEN @sortColumn = 'PostalCode' AND @sortOrder = 'DESC'  
  THEN T.PostalCode END DESC   ,
  
  CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'
	THEN T.POCount END ASC, 
	CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'
	 THEN T.POCount END DESC 

   
  
DECLARE @count INT     
SET @count = 0     
SELECT @count = MAX(RowNum) FROM #FinalResultsSorted  
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
  
SELECT @count AS TotalRows, * FROM #FinalResultsSorted WHERE RowNum BETWEEN @startInd AND @endInd  
  
END  
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_tempcc_match_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_tempcc_match_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vendor_tempcc_match_update] @tempccIdXML = '<Tempcc><ID>1</ID><ID>2</ID><ID>3</ID><ID>4</ID></Tempcc>',@currentUser = 'demouser'
 CREATE PROCEDURE [dbo].[dms_vendor_tempcc_match_update](
	@tempccIdXML XML,
	@currentUser NVARCHAR(50)
  )
 AS
 BEGIN
 
    SET FMTONLY OFF
	SET NOCOUNT ON

	DECLARE @now DATETIME = GETDATE()
	DECLARE @CCExpireDays int = 30
	DECLARE @MinCreateDate datetime

	DECLARE @Matched INT =0
		,@MatchedAmount money =0
		,@Unmatched int = 0
		,@UnmatchedAmount money = 0
		,@Posted INT=0
		,@PostedAmount money=0
		,@Cancelled INT=0
		,@CancelledAmount money=0
		,@Exception INT=0
		,@ExceptionAmount money=0
		,@MatchedIds nvarchar(max)=''

	DECLARE @MatchedTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Matched')
		,@UnMatchedTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'UnMatched')
		,@PostededTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Posted')
		,@CancelledTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Cancelled')
		,@ExceptionTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Exception')

	-- Build table of selected items
	CREATE TABLE #SelectedTemporaryCC 
	(	
		ID INT IDENTITY(1,1),
		TemporaryCreditCardID INT
	)

	INSERT INTO #SelectedTemporaryCC
	SELECT tcc.ID
	FROM TemporaryCreditCard tcc WITH (NOLOCK)
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @tempccIdXML.nodes('/Tempcc/ID') T(c)
			) T ON tcc.ID = T.ID

	CREATE CLUSTERED INDEX IDX_SelectedTemporaryCC ON #SelectedTemporaryCC(TemporaryCreditCardID)

		
	/**************************************************************************************************/
	-- Update (Reset) Selected items to Unmatched where status is not Posted
	UPDATE tc SET 
		TemporaryCreditCardStatusID = @UnmatchedTemporaryCreditCardStatusID
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = NULL
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	WHERE tcs.Name <> 'Posted'


	/**************************************************************************************************/
	--Update for Exact match on PO# and CC#
	--Conditions:
	--	PO# AND CC# match exactly
	--	PO Status is Issued or Issued Paid
	--	PO has not been deleted
	--	PO does not already have a related Vendor Invoice
	--	Temporary CC has not already been posted
	--Match Status
	--	Total CC charge amount LESS THAN or EQUAL to the PO amount
	--Exception Status
	--	Total CC charge amount GREATER THAN the PO amount
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE
				 --Cancelled 
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Cancelled', 'Issued', 'Issued-Paid')) 
						AND vi.ID IS NULL 
						AND (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
						AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN @CancelledTemporaryCreditCardStatusID
				 --Matched
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > 0
                        AND (ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount
                              OR ISNULL(tc.IsExceptionOverride,0) = 1)
					THEN @MatchedTemporaryCreditCardStatusID
				 --Cancelled	
				 WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN @CancelledTemporaryCreditCardStatusID
				 --Exception
				 ELSE @ExceptionTemporaryCreditCardStatusID
				 END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				 --Cancelled 
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Cancelled', 'Issued', 'Issued-Paid')) 
						AND vi.ID IS NULL 
						AND (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
						AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN NULL
				 --Matched
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > 0
                        AND (ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount
                              OR ISNULL(tc.IsExceptionOverride,0) = 1)
					THEN NULL
				 --Exception: PO has not been charged
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) = 0
					THEN 'Credit card has not been charged by the vendor'
				 --Exception: Charge more than PO Amount
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > po.PurchaseOrderAmount 
					THEN 'Charge amount exceeds PO amount'
				 --Cancelled	
				 WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN NULL
				 -- Other Exceptions	
				 WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 ELSE NULL
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = RIGHT(tc.CreditCardNumber,5)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID
	WHERE 1=1
	AND tcs.Name = 'Unmatched'
		
		
		
	/**************************************************************************************************/
	-- Update For No matches on PO# or CC#
	-- Conditions:
	--	No potential PO matches exist
	--  No potential CC# matches exist
	-- Cancelled Status
	--	Temporary Credit Card Issue Status is Cancelled
	-- Exception Status
	--	Temporary Credit Card Issue Status is NOT Cancelled
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE 
				WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN @CancelledTemporaryCreditCardStatusID
				ELSE @ExceptionTemporaryCreditCardStatusID
				END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN NULL
				ELSE 'No matching PO# or CC#'
				END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	WHERE  1=1
	AND tcs.Name = 'Unmatched'
	AND NOT EXISTS (
		SELECT *
		FROM PurchaseOrder po
		WHERE
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		)
	AND NOT EXISTS (
		SELECT *
		FROM PurchaseOrder po
		WHERE  
		po.PurchaseOrderNumber <> LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND po.CompanyCreditCardNumber IS NOT NULL
		AND RIGHT(RTRIM(po.CompanyCreditCardNumber),5) = RIGHT(tc.CreditCardNumber,5)
		)


	/**************************************************************************************************/
	--Update to Exception Status - PO matches and CC# does not match
	-- Conditions
	--	PO# matches exactly
	--	CC# does not match or is blank
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE
				WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN @CancelledTemporaryCreditCardStatusID
				WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN @CancelledTemporaryCreditCardStatusID
				ELSE @ExceptionTemporaryCreditCardStatusID
				END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				 --Cancelled	
				 WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN NULL
				 WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN NULL
				 --Exceptions
				 WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 WHEN RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = '' THEN 'Matching PO does not have a credit card number'
				 ELSE 'CC# Mismatch'
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND	RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) <> RIGHT(tc.CreditCardNumber,5)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID
	where tcs.Name = 'Unmatched'


	/**************************************************************************************************/
	--Update to Exception Status - PO does not match and CC# matches
	-- Conditions
	--	PO# does not match
	--	CC# matches exactly
	UPDATE tc SET
		TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 ELSE 'PO# Mismatch'
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber <> LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND	RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = RIGHT(tc.CreditCardNumber,5)
		AND po.CreateDate >= DATEADD(dd,1,tc.IssueDate)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID
	where tcs.Name = 'Unmatched'


	/**************************************************************************************************/
	-- Prepare Results
	SELECT 
		@Matched = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @MatchedTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@MatchedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @MatchedTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Unmatched = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @UnMatchedTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@UnmatchedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @UnMatchedTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Posted = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @PostededTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@PostedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @PostededTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Cancelled = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @CancelledTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@CancelledAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @CancelledTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Exception = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@ExceptionAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID

	-- Build string of 'Matched' IDs
	SELECT @MatchedIds = @MatchedIds + CONVERT(varchar(20),tc.ID) + ',' 
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	WHERE tc.TemporaryCreditCardStatusID = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Matched')

	-- Remove ending comma from string or IDs
	IF LEN(@MatchedIds) > 1 
		SET @MatchedIds = LEFT(@MatchedIds, LEN(@MatchedIds) - 1)

	DROP TABLE #SelectedTemporaryCC
	
	SELECT @Matched 'MatchedCount',
		   @MatchedAmount 'MatchedAmount',
		   --@Unmatched 'UnmatchedCount',
		   --@UnmatchedAmount 'UnmatchedAmount',
		   @Posted 'PostedCount',
		   @PostedAmount 'PostedAmount',
		   @Cancelled 'CancelledCount',
		   @CancelledAmount 'CancelledAmount',
		   @Exception 'ExceptionCount',
		   @ExceptionAmount 'ExceptionAmount',
		   @MatchedIds 'MatchedIds'
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
 -- EXEC dms_VerifyProgramServiceBenefit 1, 1, 1, 1
CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit]
        @ProgramID INT
      , @ProductCategoryID INT
      , @VehicleCategoryID INT
      , @VehicleTypeID INT = NULL
      , @SecondaryCategoryID INT = NULL
      , @ServiceRequestID  INT = NULL
AS
BEGIN 
SET NOCOUNT ON  
SET FMTONLY OFF  
      --DECLARE @ProgramID INT
      --DECLARE @ProductCategoryID INT
      --DECLARE @VehicleCategoryID INT
      --DECLARE @VehicleTypeID INT
      --SET @ProgramID = 1
      --SET @ProductCategoryID = 1
      --SET @VehicleCategoryID = 2
      --SET @VehicleTypeID = 1

      SELECT pc.Name ProductCategoryName
            ,pc.ID ProductCategoryID
            ,ISNULL(vc.Name,'') VehicleCategoryName
            ,vc.ID VehicleCategoryID
            ,MAX(CAST(pp.IsServiceCoverageBestValue AS INT)) IsServiceCoverageBestValue
            ,MAX(pp.ServiceCoverageLimit) ServiceCoverageLimit
            ,MAX(pp.CurrencyTypeID) CurrencyTypeID
            ,MAX(pp.ServiceMileageLimit) ServiceMileageLimit
            ,MAX(pp.ServiceMileageLimitUOM) ServiceMileageLimitUOM
            ,MAX(CASE WHEN pp.ServiceCoverageLimit IS NULL THEN 0 
                          WHEN pp.ServiceCoverageLimit = 0 AND pp.IsReimbursementOnly = 1 THEN 1 
                          WHEN pp.IsServiceCoverageBestValue = 1 THEN 1
                          WHEN pp.ServiceCoverageLimit > 0 THEN 1
                          ELSE 0 END) IsServiceEligible
            ,pp.IsServiceGuaranteed 
            ,pp.ServiceCoverageDescription
      FROM  ProductCategory pc (NOLOCK) 
      JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID 
                        AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')
                        AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')
      LEFT OUTER JOIN   VehicleCategory vc on vc.id = p.VehicleCategoryID
      LEFT OUTER JOIN   ProgramProduct pp on p.id = pp.productid
      WHERE pp.ProgramID = @ProgramID
      AND         pc.ID = @ProductCategoryID
      AND         (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)
      AND         (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)
      GROUP BY 
            pc.Name     
            ,pc.ID 
            ,vc.Name
            ,vc.ID
			,pp.IsServiceGuaranteed 
			,pp.ServiceCoverageDescription
END

GO
