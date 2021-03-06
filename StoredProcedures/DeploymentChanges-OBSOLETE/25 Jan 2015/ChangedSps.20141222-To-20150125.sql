IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Call_Summary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Call_Summary]
GO

--EXEC dms_Call_Summary @serviceRequestID = 1491
CREATE PROC dms_Call_Summary(@serviceRequestID INT = NULL)  
AS  
BEGIN 

DECLARE @MemberProductProvide AS TABLE(ID INT NOT NULL IDENTITY(1,1),
									   ProvideDetails NVARCHAR(MAX))

DECLARE @memberID AS INT
SET     @memberID = (SELECT MemberID FROM [Case] WHERE ID = (SELECT CaseID FROM ServiceRequest WHERE ID = @serviceRequestID))

INSERT INTO @MemberProductProvide
SELECT PP.Description + ' ' +
	   PP.PhoneNumber
FROM   MemberProduct MP
LEFT JOIN ProductProvider PP ON MP.ProductProviderID = PP.ID
WHERE MP.MemberID = @memberID 
AND   MP.EndDate > GETDATE()


DECLARE @programID AS INT
SET     @programID = (SELECT ProgramID FROM [Case] WHERE ID = (SELECT CaseID FROM ServiceRequest WHERE ID = @serviceRequestID))

DECLARE @ProgramConfigurationDetails AS TABLE(
	Name NVARCHAR(100) NULL,
	Value NVARCHAR(100) NULL,
	ControlType NVARCHAR(100) NULL,
	DataType NVARCHAR(100) NULL,
	Sequence INT NULL)

INSERT INTO @ProgramConfigurationDetails
EXEC [dms_programconfiguration_for_program_get]
   @programID = @programID,
   @configurationType = 'Service',
   @configurationCategory  ='Validation'


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
	, m.ClientMemberType AS Member_ClientMemberType   
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
	, sr.PrimaryServiceEligiblityMessage as Service_PrimaryServiceEligiblityMessage

	, CASE WHEN sr.IsSecondaryOverallCovered  = 1 THEN 'Covered' ELSE 'Not Covered' END AS Service_IsSecondaryOverallCovered
	, CASE WHEN sr.IsPossibleTow = 1 THEN 'Possible Tow' ELSE '' END AS Service_IsPossibleTow
	, sr.SecondaryServiceEligiblityMessage as Service_SecondaryServiceEligiblityMessage

	--, '$' + CONVERT(NVARCHAR(50),ISNULL(sr.PrimaryCoverageLimit,0)) as Service_CoverageLimit  

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

-- INSERT PRODUCT PROVIDERS
INSERT INTO @Hold(ColumnName,ColumnValue,DataType,[Sequence],GroupName)
SELECT 'Program_Provider',
	   MPP.ProvideDetails,
	   'String',
	   1,
	   'Program'
FROM   @MemberProductProvide MPP

 
    -- Group Values Based on Sequence Number    
 UPDATE @Hold SET GroupName = 'Member', DefaultRows = 6 WHERE CHARINDEX('Member_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Vehicle', DefaultRows = 3 WHERE CHARINDEX('Vehicle_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Service' ,DefaultRows = 6 WHERE CHARINDEX('Service_',ColumnName) > 0    
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
 UPDATE @Hold SET DataType = 'LabelThemeInline' WHERE CHARINDEX('Member_Status',ColumnName) > 0 
 UPDATE @Hold SET DataType = 'LabelThemeInline' WHERE CHARINDEX('Member_ClientMemberType',ColumnName) > 0 
 UPDATE @Hold SET DataType = 'LabelTheme' WHERE CHARINDEX('Vehicle_IsEligible',ColumnName) > 0
 UPDATE @Hold SET DataType = 'LabelThemeInline' WHERE CHARINDEX('Service_IsPrimaryOverallCovered',ColumnName) > 0
 UPDATE @Hold SET DataType = 'LabelThemeInline' WHERE CHARINDEX('Service_IsSecondaryOverallCovered',ColumnName) > 0   

 IF NOT EXISTS (SELECT * FROM @Hold WHERE ColumnName  = 'Service_IsPossibleTow' AND ColumnValue IS NOT NULL AND  ColumnValue != '')
 BEGIN
	DELETE FROM @Hold WHERE ColumnName  = 'Service_IsSecondaryOverallCovered'
	DELETE FROM @Hold WHERE ColumnName  = 'Service_SecondaryServiceEligiblityMessage'
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


IF NOT EXISTS (SELECT * FROM @ProgramConfigurationDetails WHERE Name = 'MemberEligibilityApplies' AND Value = 'Yes')
BEGIN
	DELETE FROM @Hold WHERE ColumnName = 'Member_Status'
END

IF NOT EXISTS(SELECT  * FROM @Hold WHERE ColumnName = 'Member_ClientMemberType') 
BEGIN
	UPDATE @Hold SET DataType = 'LabelTheme' WHERE ColumnName = 'Member_Status'
END
 
 SELECT * FROM @Hold WHERE ColumnValue IS NOT NULL ORDER BY Sequence ASC 
 
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
 WHERE id = object_id(N'[dbo].[dms_CoachingConcerns_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_CoachingConcerns_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_CoachingConcerns_List]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 

BEGIN 

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter></Filter></ROW>'
END



DECLARE @Filters AS TABLE(
	NameOperator NVARCHAR(50) NULL,
	NameType NVARCHAR(50) NULL,
	NameValue NVARCHAR(50) NULL,
	ConcernTypeList NVARCHAR(200) NULL,
	ConcernID INT NULL,
	ConcernTypeID INT NULL)

INSERT INTO @Filters
SELECT  
	ISNULL(T.c.value('@NameOperator','NVARCHAR(50)'),NULL),
	ISNULL(T.c.value('@NameType','NVARCHAR(50)'),NULL),
	ISNULL(T.c.value('@NameValue','NVARCHAR(50)'),NULL),
	ISNULL(T.c.value('@ConcernTypeList','NVARCHAR(200)'),NULL),
	ISNULL(T.c.value('@ConcernID','INT'),NULL),
	ISNULL(T.c.value('@ConcernTypeID','INT'),NULL)
FROM  @whereClauseXML.nodes('/ROW/Filter') T(c)


DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	UserName nvarchar(50)  NULL ,
	Concern nvarchar(50)  NULL ,
	Coached nvarchar(50)  NULL ,
	TeamManager nvarchar(50)  NULL ,
	Area nvarchar(50)  NULL ,
	CreateDate datetime  NULL ,
	Documents nvarchar(50)  NULL 
) 


DECLARE @QueryResults TABLE ( 
	ID int  NULL ,
	UserName nvarchar(50)  NULL ,
	Concern nvarchar(50)  NULL ,
	Coached nvarchar(50)  NULL ,
	TeamManager nvarchar(50)  NULL ,
	Area nvarchar(50)  NULL ,
	CreateDate datetime  NULL ,
	Documents nvarchar(50)  NULL 
) 


INSERT INTO @QueryResults
SELECT CC.ID,
	   CC.AgentUserName UserName,
	   C.Description Concern,
	   CASE ISNULL(CC.IsCoached,0) WHEN 0 THEN 'No' ELSE 'Yes' END Coached,
	   CC.TeamManager,
	   '' AS Area,
	   CC.CreateDate,
	   '' AS Documents
FROM CoachingConcern CC  WITH (NOLOCK)
LEFT JOIN Concern C ON CC.ConcernID = C.ID,@Filters FL
WHERE ((FL.ConcernTypeID IS NULL) OR (FL.ConcernTypeID IS NOT NULL AND CC.ConcernTypeID = FL.ConcernTypeID))
AND   ((FL.ConcernID IS NULL) OR (FL.ConcernID IS NOT NULL AND CC.ConcernID = FL.ConcernID))
AND   ((FL.ConcernTypeList IS NULL) OR (FL.ConcernTypeList IS NOT NULL AND CC.ConcernTypeID IN (select item from dbo.fnSplitString(FL.ConcernTypeList,','))))
AND   ((FL.NameValue IS NULL) OR (FL.NameType = 'User' AND FL.NameOperator = 'eq' AND CC.AgentUserName = FL.NameValue ) 
							  OR (FL.NameType = 'User' AND FL.NameOperator = 'begins' AND CC.AgentUserName LIKE FL.NameValue + '%'  )
							  OR (FL.NameType = 'User' AND FL.NameOperator = 'contains' AND CC.AgentUserName LIKE '%'  + FL.NameValue + '%')
							  OR (FL.NameType = 'User' AND FL.NameOperator = 'endwith' AND CC.AgentUserName LIKE '%' + FL.NameValue )
							  OR (FL.NameType = 'Manager' AND FL.NameOperator = 'eq' AND CC.TeamManager = FL.NameValue ) 
							  OR (FL.NameType = 'Manager' AND FL.NameOperator = 'begins' AND CC.TeamManager LIKE FL.NameValue + '%'  )
							  OR (FL.NameType = 'Manager' AND FL.NameOperator = 'contains' AND CC.TeamManager LIKE '%'  + FL.NameValue + '%')
							  OR (FL.NameType = 'Manager' AND FL.NameOperator = 'endwith' AND CC.TeamManager LIKE '%' + FL.NameValue ))

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults
SELECT 
	T.ID,
	T.UserName,
	T.Concern,
	T.Coached,
	T.TeamManager,
	T.Area,
	T.CreateDate,
	T.Documents
FROM @QueryResults T

 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'UserName' AND @sortOrder = 'ASC'
	 THEN T.UserName END ASC, 
	 CASE WHEN @sortColumn = 'UserName' AND @sortOrder = 'DESC'
	 THEN T.UserName END DESC ,

	 CASE WHEN @sortColumn = 'Concern' AND @sortOrder = 'ASC'
	 THEN T.Concern END ASC, 
	 CASE WHEN @sortColumn = 'Concern' AND @sortOrder = 'DESC'
	 THEN T.Concern END DESC ,

	 CASE WHEN @sortColumn = 'Coached' AND @sortOrder = 'ASC'
	 THEN T.Coached END ASC, 
	 CASE WHEN @sortColumn = 'Coached' AND @sortOrder = 'DESC'
	 THEN T.Coached END DESC ,

	 CASE WHEN @sortColumn = 'TeamManager' AND @sortOrder = 'ASC'
	 THEN T.TeamManager END ASC, 
	 CASE WHEN @sortColumn = 'TeamManager' AND @sortOrder = 'DESC'
	 THEN T.TeamManager END DESC ,

	 CASE WHEN @sortColumn = 'Area' AND @sortOrder = 'ASC'
	 THEN T.Area END ASC, 
	 CASE WHEN @sortColumn = 'Area' AND @sortOrder = 'DESC'
	 THEN T.Area END DESC ,

	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'
	 THEN T.CreateDate END ASC, 
	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'
	 THEN T.CreateDate END DESC 


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
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ContactLogLink_Update_For_PurchaseOrderIssuing]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ContactLogLink_Update_For_PurchaseOrderIssuing] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_ContactLogLink_Update_For_PurchaseOrderIssuing]( 
   @ServiceRequestID INT = NULL 
 , @POID Int = NULL
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
 	
	DECLARE @EID AS INT
	SET @EID = (SELECT ID FROM Entity WHERE Name  = 'PurchaseOrder')

	INSERT INTO ContactLogLink([ContactLogID],[EntityID],[RecordID]) 
	SELECT CL.ID,@EID,@POID
	FROM   ContactLog CL
          LEFT JOIN ContactMethod CM ON CL.ContactMethodID = CM.ID
          LEFT JOIN ContactType CT ON CL.ContactTypeID = CT.ID
          LEFT JOIN ContactCategory CC ON CL.ContactCategoryID = CC.ID
          LEFT JOIN ContactLogLink CLL ON CL.ID = CLL.ContactLogID
          INNER JOIN Entity E ON CLL.EntityID = E.ID
	WHERE  CT.Name  = 'Vendor'
	AND    CM.Name = 'Phone'
	AND    CC.Name = 'VendorSelection'
	AND       E.Name = 'ServiceRequest' 
	AND    CLL.RecordID = @ServiceRequestID
	AND NOT EXISTS(SELECT 1 FROM ContactLogLink CLL WHERE CLL.ContactLogID = CL.ID AND EntityID = @EID)



END
GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Get_Member_Information]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Get_Member_Information]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- exec dms_Get_Member_Information 541
CREATE PROC [dbo].[dms_Get_Member_Information](@memberID INT = NULL)
AS
BEGIN
	-- KB: Get membership ID of the current member.
	DECLARE @membershipID INT
	SELECT @membershipID = MembershipID FROM Member WHERE ID = @memberID

	DECLARE @memberEntityID INT
	SELECT @memberEntityID = ID FROM Entity WHERE Name = 'Member'

	--KB: Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'

	SET FMTONLY OFF;
	
	;WITH wResults
	AS
	(
	SELECT DISTINCT MS.ID AS MembershipID,
	M.ClientMemberType,
	MS.MembershipNumber,
	CASE MS.IsActive WHEN 1 THEN 'Active' ELSE 'Inactive' END AS MembershipStatus, -- KB: I don't think we are using this.
	P.[Description] AS Program,
	P.ID AS ProgramID,
	AD.Line1 AS Line1,
	PH.PhoneNumber AS HomePhoneNumber, 
	PW.PhoneNumber AS WorkPhoneNumber, 
	PC.PhoneNumber AS CellPhoneNumber,
	ISNULL(AD.City,'') + ' ' + ISNULL(AD.StateProvince,'') + ' ' +  ISNULL(AD.PostalCode,'') AS CityStateZip,
	CN.Name AS 'CountryName',
	M.Email,
	M.ID AS MemberID,
	CASE M.IsPrimary WHEN 1 THEN '*' ELSE '' END AS MasterMember,
	--ISNULL(M.FirstName,'') + ' ' + ISNULL(M.LastName,'') + ' ' + ISNULL(M.Suffix,'') AS MemberName,
	REPLACE(RTRIM( 
	COALESCE(M.FirstName, '') + 
	COALESCE(' ' + left(M.MiddleName,1), '') + 
	COALESCE(' ' + M.LastName, '') +
	COALESCE(' ' + M.Suffix, '')
	), ' ', ' ') AS MemberName,	
	-- KB: Considering Effective and Expiration Dates to calculate member status
	CASE WHEN ISNULL(m.EffectiveDate,@minDate) <= @now AND ISNULL(m.ExpirationDate,@minDate) >= @now
				THEN 'Active'
				ELSE 'Inactive'
	END AS MemberStatus,
	M.ExpirationDate,
	M.EffectiveDate,
	C.ID AS ClientID,
	C.Name AS ClientName,
	MS.Note AS MembershipNote	  
	FROM Member M
	LEFT JOIN Membership MS ON MS.ID = M.MembershipID
	LEFT JOIN Program P ON M.ProgramID = P.ID
	LEFT JOIN Client C ON P.ClientID = C.ID
	LEFT JOIN PhoneEntity PH ON PH.RecordID = M.ID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID 
	LEFT JOIN PhoneEntity PW ON PW.RecordID = M.ID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID 
	LEFT JOIN PhoneEntity PC ON PC.RecordID = M.ID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID 
	LEFT JOIN AddressEntity AD ON AD.RecordID = M.ID AND AD.EntityID = @memberEntityID
	LEFT JOIN Country CN ON CN.ISOCode = AD.CountryCode
	WHERE MS.ID =  @membershipID -- KB: Performing the check against the right attribute.
	)
	SELECT * FROM wResults M ORDER BY MasterMember DESC,MemberName

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
 WHERE id = object_id(N'[dbo].[dms_Members_Search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Members_Search]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter FirstNameOperator="4" FirstNameValue="jeevan"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
--EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter PhoneNumberOperator="2" PhoneNumberValue="8173078882"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
--EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter MemberNumberOperator="2" MemberNumberValue="123"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
-- EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter VINOperator="4" VINValue="K1234422323N1233"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3

CREATE PROCEDURE [dbo].[dms_Members_Search](   
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10   
 , @sortColumn nvarchar(100)  = 'MemberNumber'   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @programID INT = NULL   
 )   
 AS   
 BEGIN   
    
	SET NOCOUNT ON    
	SET FMTONLY OFF;
	-- KB : Temporary resultsets. These resultsets are used to prepare mangeable resultsets.
	CREATE TABLE #FinalResultsFiltered(     

	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	Suffix nvarchar(50)  NULL ,    
	Prefix nvarchar(50)  NULL ,    
	City nvarchar(50)  NULL ,    
	StateProvince nvarchar(50)  NULL ,    
	PostalCode nvarchar(50)  NULL ,    
	HomePhoneNumber nvarchar(50)  NULL ,    
	WorkPhoneNumber nvarchar(50)  NULL ,    
	CellPhoneNumber nvarchar(50)  NULL ,  
	ProgramID INT NULL, -- KB: ADDED IDS  
	Program nvarchar(50)  NULL ,    
	POCount INT NULL,  
	ExpirationDate DATETIME NULL,   
	EffectiveDate DATETIME NULL,
	VIN nvarchar(50)  NULL ,    
	VehicleID INT NULL, -- KB: Added VehicleID
	[StateProvinceID] INT  NULL,
	MiddleName   nvarchar(50)  NULL , 
	ClientMemberType nvarchar(200)  NULL 
	)    

	CREATE TABLE #FinalResultsFormatted(      
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,  
	VehicleID INT NULL, -- KB: Added VehicleID  
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL,
	ClientMemberType nvarchar(200)  NULL
	)    

	CREATE TABLE #FinalResultsSorted(     
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL , 
	VehicleID INT NULL, -- KB: Added VehicleID   
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL,
	ClientMemberType nvarchar(200)  NULL 
	)  
	CREATE TABLE #FinalResultsDistinct(     
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,  
	VehicleID INT NULL, -- KB: Added VehicleID  
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL,
	ClientMemberType nvarchar(200)  NULL
	)  

	CREATE TABLE #SearchPrograms (
	ProgramID int, 
	ProgramName nvarchar(200),
	ClientID int
	)
	
	INSERT INTO #SearchPrograms (ProgramID, ProgramName, ClientID)
	SELECT ProgramID, ProgramName, ClientID
	--FROM [dbo].[fnc_GetMemberSearchPrograms](9) --@programID)
	FROM [dbo].[fnc_GetMemberSearchPrograms] (@programID)
	
	CREATE CLUSTERED INDEX IDX_SearchPrograms ON #SearchPrograms(ProgramID)
	--Select * From #SearchPrograms
	--Drop table #SearchPrograms
	
	DECLARE @idoc int    
	IF @whereClauseXML IS NULL     
	BEGIN    
	SET @whereClauseXML = '<ROW><Filter     
	MemberIDOperator="-1"     
	MemberNumberOperator="-1"     
	PhoneNumberOperator="-1"     
	ProgramOperator="-1"     
	LastNameOperator="-1"     
	FirstNameOperator="-1"     
	VINOperator="-1"     
	StateOperator="-1"    
	ZipCodeOperator = "-1"   
	></Filter></ROW>'    
	END    
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML    

	DECLARE @tmpForWhereClause TABLE    
	(    
	MemberIDOperator INT NOT NULL,    
	MemberIDValue int NULL,    
	MemberNumberOperator INT NOT NULL,    
	MemberNumberValue nvarchar(50) NULL,    
	PhoneNumberOperator INT NOT NULL,    
	PhoneNumberValue nvarchar(50) NULL,    
	ProgramOperator INT NOT NULL,    
	ProgramValue nvarchar(50) NULL,    
	LastNameOperator INT NOT NULL,    
	LastNameValue nvarchar(50) NULL,    
	FirstNameOperator INT NOT NULL,    
	FirstNameValue nvarchar(50) NULL,    
	VINOperator INT NOT NULL,    
	VINValue nvarchar(50) NULL,    
	StateOperator INT NOT NULL,    
	StateValue nvarchar(50) NULL,  
	ZipCodeOperator INT NOT NULL,    
	ZipCodeValue   nvarchar(50) NULL  
	)    

	-- Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'     

	INSERT INTO @tmpForWhereClause    
	SELECT      
			ISNULL(MemberIDOperator,-1),    
			MemberIDValue ,    
			ISNULL(MemberNumberOperator,-1),    
			MemberNumberValue ,    
			ISNULL(PhoneNumberOperator,-1),    
			PhoneNumberValue ,    
			ISNULL(ProgramOperator,-1),    
			ProgramValue ,    
			ISNULL(LastNameOperator,-1),    
			LastNameValue ,    
			ISNULL(FirstNameOperator,-1),    
			FirstNameValue ,    
			ISNULL(VINOperator,-1),    
			VINValue ,    
			ISNULL(StateOperator,-1),    
			StateValue,    
			ISNULL(ZipCodeOperator,-1),    
			ZipCodeValue    
	FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (    
			MemberIDOperator INT,    
			MemberIDValue int     
			,MemberNumberOperator INT,    
			MemberNumberValue nvarchar(50)     
			,PhoneNumberOperator INT,    
			PhoneNumberValue nvarchar(50)     
			,ProgramOperator INT,    
			ProgramValue nvarchar(50)     
			,LastNameOperator INT,    
			LastNameValue nvarchar(50)     
			,FirstNameOperator INT,    
			FirstNameValue nvarchar(50)     
			,VINOperator INT,    
			VINValue nvarchar(50)     
			,StateOperator INT,    
			StateValue nvarchar(50)     
			,ZipCodeOperator INT,    
			ZipCodeValue nvarchar(50)   
	)     
	
	
	DECLARE @vinParam nvarchar(50)    
	SELECT @vinParam = VINValue FROM @tmpForWhereClause    

	DECLARE @memberEntityID INT  
	SELECT @memberEntityID = ID FROM Entity WHERE Name = 'Member'  
	--------------------- BEGIN -----------------------------    
	----   Create a temp variable or a CTE with the actual SQL search query ----------    
	----   and use that CTE in the place of <table> in the following SQL statements ---    
	--------------------- END -----------------------------    
	DECLARE @phoneNumber NVARCHAR(100)  
	SET @phoneNumber = (SELECT PhoneNumberValue FROM @tmpForWhereClause)  

	DECLARE @memberID INT
	DECLARE @memberNumber NVARCHAR(50)
	DECLARE @programCode NVARCHAR(50)
	DECLARE @firstName NVARCHAR(50)
	DECLARE @lastName NVARCHAR(50)
	DECLARE @state NVARCHAR(50)
	DECLARE @zip NVARCHAR(50)

	SELECT	@memberID = MemberIDValue,
			@memberNumber = MemberNumberValue,
			@programCode = ProgramValue,
			@firstName = FirstNameValue,
			@lastName = LastNameValue,
			@state = StateValue,
			@zip = ZipCodeValue
	FROM	@tmpForWhereClause

	
	SET FMTONLY OFF;  
	  
	IF @phoneNumber IS NULL  
	BEGIN  

	-- If vehicle is given, then let's use Vehicle in the left join (as the first table) else don't even consider vehicle table.

		IF @vinParam IS NOT NULL
		BEGIN

			SELECT	* 
			INTO	#TmpVehicle1
			FROM	Vehicle V WITH (NOLOCK)
			WHERE	V.VIN LIKE '%' + @vinParam + '%'


			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber-- PH.PhoneNumber AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber -- PW.PhoneNumber AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber -- PC.PhoneNumber AS CellPhoneNumber  
					, P.ID As ProgramID  -- KB: ADDED IDS
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate   
					, m.EffectiveDate 
					, v.VIN  
					, v.ID AS VehicleID
					, A.[StateProvinceID]
					,M.MiddleName 
					,M.ClientMemberType
			FROM #TmpVehicle1 v
			LEFT JOIN Member M WITH (NOLOCK) ON  (v.MemberID IS NULL OR v.MemberID = m.ID) 
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID AND v.MembershipID = MS.ID
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID   
			
			WHERE   ( @memberID IS NULL  OR @memberID = M.ID )
					 AND
					 (@memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%'
					 OR MS.AltMembershipNumber LIKE  '%' + @memberNumber + '%')    -- Lakshmi - Old Membership Search
					 AND
					 ( @zip is NULL OR A.PostalCode LIKE @zip +'%' )
					 AND
					 ( @programCode IS NULL OR P.Code = @programCode)
					 AND
					 ( @lastName IS NULL OR M.LastName LIKE @lastName + '%')
					 AND
					 ( @firstName IS NULL OR M.FirstName LIKE @firstName + '%')
					 AND
					 ( @vinParam IS NULL OR V.VIN LIKE '%' + @vinParam + '%')
					 AND
					 ( @state IS NULL OR A.StateProvinceID = @state)
			AND		ISNULL(M.IsActive,0) = 1
					 
			DROP TABLE #TmpVehicle1

		END -- End of Vin param check
		ELSE
		BEGIN

			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber-- PH.PhoneNumber AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber -- PW.PhoneNumber AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber -- PC.PhoneNumber AS CellPhoneNumber
					, P.ID As ProgramID  -- KB: ADDED IDS  
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate   
					, m.EffectiveDate 
					, '' AS VIN
					, NULL AS VehicleID
					, A.[StateProvinceID]
					,M.MiddleName 
					,M.ClientMemberType
			FROM Member M WITH (NOLOCK)  
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID   

			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID    
			
			WHERE   ( @memberID IS NULL  OR @memberID = M.ID )
					 AND
					 (@memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%'
					 OR MS.AltMembershipNumber LIKE  '%' + @memberNumber + '%')			-- Lakshmi - Old Membership Search
					 AND
					 ( @zip is NULL OR A.PostalCode LIKE @zip +'%' )
					 AND
					 ( @programCode IS NULL OR P.Code = @programCode)
					 AND
					 ( @lastName IS NULL OR M.LastName LIKE @lastName + '%')
					 AND
					 ( @firstName IS NULL OR M.FirstName LIKE @firstName + '%')
					 --AND
					 --( @vinParam IS NULL OR V.VIN LIKE '%' + @vinParam + '%')
					 AND
					 ( @state IS NULL OR A.StateProvinceID = @state)
			AND		ISNULL(M.IsActive,0) = 1
		END		
		
	END  -- End of Phone number is null check.
	ELSE  
	BEGIN
	
		SELECT *  
		INTO #tmpPhone  
		FROM PhoneEntity PH WITH (NOLOCK)  
		WHERE PH.EntityID = @memberEntityID   
		AND  PH.PhoneNumber = @phoneNumber   

		-- Consider VIN param.
		IF @vinParam IS NOT NULL
		BEGIN
		
			SELECT	* 
			INTO	#TmpVehicle
			FROM	Vehicle V WITH (NOLOCK)
			WHERE	V.VIN LIKE '%' + @vinParam + '%' 

			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber 
					, P.ID As ProgramID  -- KB: ADDED IDS 
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate 
					, m.EffectiveDate  
					, v.VIN
					, v.ID AS VehicleID
					, A.[StateProvinceID] 
					, M.MiddleName 
					, M.ClientMemberType
			FROM #TmpVehicle v
			LEFT JOIN Member M WITH (NOLOCK) ON  (v.MemberID IS NULL OR v.MemberID = m.ID) 
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID AND v.MembershipID = MS.ID
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID    
			--LEFT OUTER join Vehicle v WITH (NOLOCK) ON 
			--						(
			--							(v.MemberID IS NULL OR v.MemberID = m.ID) AND
			--								v.MembershipID = MS.ID

			--							--	(@vinParam IS NULL AND M.ID IS NULL) 
			--							--	OR
			--							--(@vinParam IS NOT NULL 
			--							--	AND 
			--							--	(v.MemberID = m.ID 
			--							--		OR (v.MembershipID = MS.ID AND v.MemberID IS NULL) 
			--							--		--AND V.VIN = @vinParam
			--							--	) 
			--							--) 
			--						)
			JOIN @tmpForWhereClause TMP ON 1=1  
			   
			WHERE  ( (@memberID IS NULL OR @memberID = M.ID)
					 AND
					 ( @memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%'
					 OR MS.AltMembershipNumber LIKE  '%' + @memberNumber + '%')						-- Lakshmi - Old Membership Search
					 AND
					 ( @zip is NULL OR A.PostalCode LIKE @zip +'%' )
					 AND
					 ( @programCode IS NULL OR P.Code = @programCode)
					 AND
					 ( @lastName IS NULL OR M.LastName LIKE @lastName + '%')
					 AND
					 ( @firstName IS NULL OR M.FirstName LIKE @firstName + '%')
					 AND
					 ( @vinParam IS NULL OR V.VIN LIKE '%' + @vinParam + '%')
					 AND
					 ( @state IS NULL OR A.StateProvinceID = @state)
				  )
			AND		ISNULL(M.IsActive,0) = 1

			DROP TABLE #TmpVehicle
		END -- End of Vin param check
		ELSE
		BEGIN
			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber  
					, P.ID As ProgramID  -- KB: ADDED IDS
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate
					, m.EffectiveDate   
					, '' AS VIN
					, NULL AS VehicleID  
					, A.[StateProvinceID] 
					, M.MiddleName 
					, M.ClientMemberType
			FROM	#tmpPhone PH
			JOIN	Member M WITH (NOLOCK)  ON PH.RecordID = M.ID
			JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID    

			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID    
			--LEFT OUTER join Vehicle v WITH (NOLOCK) ON 
			--						(
			--							(v.MemberID IS NULL OR v.MemberID = m.ID) AND
			--								v.MembershipID = MS.ID

			--							--	(@vinParam IS NULL AND M.ID IS NULL) 
			--							--	OR
			--							--(@vinParam IS NOT NULL 
			--							--	AND 
			--							--	(v.MemberID = m.ID 
			--							--		OR (v.MembershipID = MS.ID AND v.MemberID IS NULL) 
			--							--		--AND V.VIN = @vinParam
			--							--	) 
			--							--) 
			--						)
			JOIN @tmpForWhereClause TMP ON 1=1  
			   
			WHERE  ( (@memberID IS NULL OR @memberID = M.ID)
					 AND
					 ( @memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%'
					 OR MS.AltMembershipNumber LIKE  '%' + @memberNumber + '%')					-- Lakshmi - Old Membership Search
					 AND
					 ( @zip is NULL OR A.PostalCode LIKE @zip +'%' )
					 AND
					 ( @programCode IS NULL OR P.Code = @programCode)
					 AND
					 ( @lastName IS NULL OR M.LastName LIKE @lastName + '%')
					 AND
					 ( @firstName IS NULL OR M.FirstName LIKE @firstName + '%')
					 --AND
					 --( @vinParam IS NULL OR V.VIN LIKE '%' + @vinParam + '%')
					 AND
					 ( @state IS NULL OR A.StateProvinceID = @state)
				  )
			AND		ISNULL(M.IsActive,0) = 1
		END
	END  -- End of phone number not null check

	-- DEBUG:   
	--SELECT COUNT(*) AS Filtered FROM #FinalResultsFiltered  

	-- Do all computations  
	INSERT INTO #FinalResultsFormatted  
	SELECT   F.MemberID  
	, F.MembershipID  
	, F.MemberNumber     
	--, REPLACE(RTRIM(COALESCE(F.LastName, '')   
	-- + COALESCE(' ' + F.Suffix, '')   
	-- + COALESCE(', ' + F.FirstName, '')), ' ', ' ')   
	-- + COALESCE(' ' + F.Prefix, '') AS Name  
	,REPLACE(RTRIM( 
	COALESCE(F.FirstName, '') + 
	COALESCE(' ' + left(F.MiddleName,1), '') + 
	COALESCE(' ' + F.LastName, '') +
	COALESCE(' ' + F.Suffix, '')
	), ' ', ' ') AS MemberName
	,(ISNULL(F.City,'') + ',' + ISNULL(F.StateProvince,'') + ' ' + ISNULL(F.PostalCode,'')) AS [Address]     
	, COALESCE(F.HomePhoneNumber, F.WorkPhoneNumber, F.CellPhoneNumber, '') As PhoneNumber 
	, F.ProgramID -- KB: ADDED IDS    
	, F.Program    
	,(SELECT COUNT(*) FROM [Case] WHERE MemberID = F.MemberID) AS POCount   
	-- Ignore time while comparing the dates here  
	--,CASE WHEN F.EffectiveDate <= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0) AND F.ExpirationDate >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)   
	--  THEN 'Active'   
	--  ELSE 'Inactive'   
	-- END 
	-- KB: Considering Effective and Expiration Dates to calculate member status
	,CASE WHEN ISNULL(F.EffectiveDate,@minDate) <= @now AND ISNULL(F.ExpirationDate,@minDate) >= @now
			THEN 'Active'
			ELSE 'Inactive'
	END AS MemberStatus
	, F.LastName  
	, F.FirstName  
	,CASE WHEN ISNULL(@vinParam,'') <> ''    
	THEN  F.VIN    
	ELSE  ''    
	END AS VIN   
	, F.VehicleID  
	, F.StateProvinceID AS [State]  
	, F.PostalCode AS ZipCode  
	, F.ClientMemberType
	FROM #FinalResultsFiltered F  

	IF @phoneNumber IS NULL  
	BEGIN  

		INSERT INTO #FinalResultsSorted  
		SELECT  F.MemberID,  
		F.MembershipID,    
		F.MemberNumber,     
		F.Name,    
		F.[Address],    
		COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber,  
		F.ProgramID, -- KB: ADDED IDS     
		F.Program,    
		F.POCount,    
		F.MemberStatus,    
		F.LastName,    
		F.FirstName ,    
		F.VIN ,
		F.VehicleID,    
		F.[State] ,    
		F.ZipCode ,
		F.ClientMemberType
		FROM  #FinalResultsFormatted F   
		LEFT JOIN PhoneEntity PH WITH (NOLOCK) ON PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PH.PhoneNumber)  
		LEFT JOIN PhoneEntity PW WITH (NOLOCK) ON PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PW.PhoneNumber)  
		LEFT JOIN PhoneEntity PC WITH (NOLOCK) ON PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PC.PhoneNumber) 

		ORDER BY     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'    
		THEN F.MembershipID END ASC,     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'    
		THEN F.MembershipID END DESC ,    

		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'    
		THEN F.MemberNumber END ASC,     
		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'    
		THEN F.MemberNumber END DESC ,    

		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'    
		THEN F.Name END ASC,     
		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'    
		THEN F.Name END DESC ,    

		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'    
		THEN F.Address END ASC,     
		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'    
		THEN F.Address END DESC ,    

		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC ,    

		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,    

		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'    
		THEN F.POCount END ASC,     
		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'    
		THEN F.POCount END DESC ,    

		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'ASC'    
		THEN F.MemberStatus END ASC,     
		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'DESC'    
		THEN F.MemberStatus END DESC    

	END  
	ELSE  

	BEGIN  
	-- DEBUG  :SELECT COUNT(*) FROM #tmpPhone  

		INSERT INTO #FinalResultsSorted  
		SELECT  F.MemberID,  
		 F.MembershipID,    
		 F.MemberNumber,     
		 F.Name,    
		 F.[Address],    
		 COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber, 
		 F.ProgramID, --KB: ADDED IDS      
		 F.Program,    
		 F.POCount,    
		 F.MemberStatus,    
		 F.LastName,    
		 F.FirstName ,    
		F.VIN , 
		F.VehicleID,   
		F.[State] ,    
		F.ZipCode ,
		F.ClientMemberType
		FROM  #FinalResultsFormatted F   
		LEFT JOIN #tmpPhone PH WITH (NOLOCK) ON PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID 
		LEFT JOIN #tmpPhone PW WITH (NOLOCK) ON PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID 
		LEFT JOIN #tmpPhone PC WITH (NOLOCK) ON PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID 
		WHERE (PH.PhoneNumber = @phoneNumber OR PW.PhoneNumber = @phoneNumber OR PC.PhoneNumber=@phoneNumber)
		ORDER BY     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'    
		THEN F.MembershipID END ASC,     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'    
		THEN F.MembershipID END DESC ,    

		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'    
		THEN F.MemberNumber END ASC,     
		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'    
		THEN F.MemberNumber END DESC ,    

		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'    
		THEN F.Name END ASC,      
		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'    
		THEN F.Name END DESC ,    

		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'    
		THEN F.Address END ASC,     
		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'    
		THEN F.Address END DESC ,    

		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC ,    

		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,    

		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'    
		THEN F.POCount END ASC,     
		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'    
		THEN F.POCount END DESC ,    

		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'ASC'    
		THEN F.MemberStatus END ASC,     
		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'DESC'    
		THEN F.MemberStatus END DESC
		
		DROP TABLE #tmpPhone    
	END     
-- DEBUG:
--SELECT * FROM #FinalResultsSorted

	-- Let's delete duplicates from #FinalResultsSorted and then insert into Distinct.
	
	;WITH wSorted 
	AS
	(
		SELECT ROW_NUMBER() OVER (PARTITION BY 
			F.MemberID,  
			F.MembershipID,    
			F.MemberNumber,     
			F.Name,    
			F.[Address],    
			F.PhoneNumber,    
			F.Program,    
			F.POCount,    
			F.MemberStatus,    
			F.VIN,
			F.VehicleID ORDER BY F.RowNum) AS sRowNumber,
			F.ClientMemberType
		FROM #FinalResultsSorted F
	)
	
	DELETE FROM wSorted WHERE sRowNumber > 1
	
	INSERT INTO #FinalResultsDistinct(
			MemberID,  
			MembershipID,    
			MemberNumber,     
			Name,    
			[Address],    
			PhoneNumber,  
			ProgramID, -- KB: ADDED IDS      
			Program,    
			POCount,    
			MemberStatus,    
			VIN,
			VehicleID,
		   ClientMemberType
	)   
	SELECT	F.MemberID,  
			F.MembershipID,    
			F.MemberNumber,     
			F.Name,    
			F.[Address],    
			F.PhoneNumber,
			F.ProgramID, -- KB: ADDED IDS        
			F.Program,    
			F.POCount,    
			F.MemberStatus,    
			F.VIN,
			F.VehicleID,
			F.ClientMemberType
			
	FROM #FinalResultsSorted F
	ORDER BY 
	CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC,
		F.RowNum  
		

	DECLARE @count INT       
	SET @count = 0       
	SELECT @count = MAX(RowNum) FROM #FinalResultsDistinct   
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



	SELECT @count AS TotalRows, F.MemberID,  
		F.MembershipID,    
	   F.MemberNumber,     
	   F.Name,    
	   F.[Address],    
	   F.PhoneNumber,  
	   F.ProgramID, -- KB: ADDED IDS      
	   F.Program,    
	   F.POCount,    
	   F.MemberStatus,    
	   F.VIN,
	   F.VehicleID ,
	   F.ClientMemberType
	   FROM    
	   #FinalResultsDistinct F WHERE RowNum BETWEEN @startInd AND @endInd    
	     
	DROP TABLE #FinalResultsFiltered  
	DROP TABLE #FinalResultsFormatted  
	DROP TABLE #FinalResultsSorted 
	DROP TABLE #FinalResultsDistinct


END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_member_contact_information_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_member_contact_information_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 	
 -- EXEC [dbo].[dms_member_contact_information_get] 541
 CREATE PROC [dbo].[dms_member_contact_information_get](@memberID INT = NULL)
 AS
 BEGIN

	SELECT AE.ID As AddressID,
		M.FirstName,
		M.LastName,
		M.ClientMemberType,
		AE.Line1 AS Address1,
		AE.Line2 AS Address2,
		AE.Line3 AS Address3,
		AE.City as City,
		AE.StateProvinceID as StateID,
		AE.StateProvince as State,
		AE.PostalCode as Zip,
		AE.CountryID as CountryID,
		AE.CountryCode as Country,
		PEH.ID as HomePhoneID,
		PEH.PhoneTypeID as HomePhoneTypeID,
		PEH.PhoneNumber as HomePhone,
		PEC.ID as CellPhoneID,
		PEC.PhoneTypeID as CellPhoneTypeID,
		PEC.PhoneNumber as CellPhone,
		PEW.ID as WorkPhoneID,
		PEW.PhoneTypeID as WorkPhoneTypeID,
		PEW.PhoneNumber as WorkPhone,
		M.Email as EMail
	FROM Member M
	LEFT JOIN AddressEntity AE  ON AE.EntityID = (Select ID From Entity where Name = 'Member') AND AE.RecordID = @MemberID AND AE.AddressTypeID = 1
	LEFT JOIN PhoneEntity PEH  ON PEH.EntityID = (Select ID From Entity where Name = 'Member') AND PEH.RecordID = @MemberID AND PEH.PhoneTypeID = (Select ID From PhoneType Where Name = 'Home')
	LEFT JOIN PhoneEntity PEC  ON PEC.EntityID = (Select ID From Entity where Name = 'Member') AND PEC.RecordID = @MemberID AND PEC.PhoneTypeID = (Select ID From PhoneType Where Name = 'Cell')
	LEFT JOIN PhoneEntity PEW ON PEW.EntityID = (Select ID From Entity where Name = 'Member') AND PEW.RecordID = @MemberID AND PEW.PhoneTypeID = (Select ID From PhoneType Where Name = 'Work')
	WHERE M.ID = @MemberID

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
 WHERE id = object_id(N'[dbo].[dms_Member_Products_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_Products_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Member_Products_Get]( 
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10    
 , @sortColumn nvarchar(100)  = ''   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @MemberID INT = NULL  
 )   
 AS   
BEGIN   
    
  SET NOCOUNT ON  
  
DECLARE @idoc int  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter   
ProductOperator="-1"   
StartDateOperator="-1"   
EndDateOperator="-1"   
StatusOperator="-1"   
ProviderOperator="-1"   
 ></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
ProductOperator INT NOT NULL,  
ProductValue nvarchar(50) NULL,  
StartDateOperator INT NOT NULL,  
StartDateValue datetime NULL,  
EndDateOperator INT NOT NULL,  
EndDateValue datetime NULL,  
StatusOperator INT NOT NULL,  
StatusValue nvarchar(50) NULL,  
ProviderOperator INT NOT NULL,  
ProviderValue nvarchar(50) NULL,  
ContractNumberOperator INT NOT NULL,  
ContractNumberValue nvarchar(100) NULL,  
VINOperator INT NOT NULL,  
VINValue nvarchar(100) NULL  
  
)  
DECLARE @FinalResults TABLE (   
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 Product nvarchar(200)  NULL ,  
 StartDate datetime  NULL ,  
 EndDate datetime  NULL ,  
 Status nvarchar(100)  NULL ,  
 Provider nvarchar(100)  NULL ,  
 PhoneNumber nvarchar(100)  NULL,  
 ContractNumber nvarchar(100)  NULL,  
 VIN  nvarchar(100)  NULL  
)   
  
DECLARE @QueryResults TABLE (   
 Product nvarchar(200)  NULL ,  
 StartDate datetime  NULL ,  
 EndDate datetime  NULL ,  
 Status nvarchar(100)  NULL ,  
 Provider nvarchar(100)  NULL ,  
 PhoneNumber nvarchar(100)  NULL,  
 ContractNumber nvarchar(100)  NULL,  
 VIN  nvarchar(100)  NULL  
)   
  
INSERT INTO @tmpForWhereClause  
SELECT    
 ISNULL(ProductOperator,-1),  
 ProductValue ,  
 ISNULL(StartDateOperator,-1),  
 StartDateValue ,  
 ISNULL(EndDateOperator,-1),  
 EndDateValue ,  
 ISNULL(StatusOperator,-1),  
 StatusValue ,  
 ISNULL(ProviderOperator,-1),  
 ProviderValue,  
 ISNULL(ContractNumberOperator,-1),  
 ContractNumberValue ,  
 ISNULL(VINOperator,-1),  
 VINValue   
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
ProductOperator INT,  
ProductValue nvarchar(50)   
,StartDateOperator INT,  
StartDateValue datetime   
,EndDateOperator INT,  
EndDateValue datetime   
,StatusOperator INT,  
StatusValue nvarchar(50)   
,ProviderOperator INT,  
ProviderValue nvarchar(50),  
ContractNumberOperator INT,  
ContractNumberValue  nvarchar(100),  
VINOperator INT,  
VINValue nvarchar(100))   
  
--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
  
INSERT INTO @QueryResults  
SELECT   P.Description AS Product  
   , MP.StartDate AS StartDate  
   , MP.EndDate AS EndDate  
   , CASE WHEN MP.EndDate < GETDATE() THEN 'Inactive' ELSE 'Active' END AS Status  
   , PP.Description AS Provider  
   , PP.PhoneNumber AS PhoneNumber  
   , MP.ContractNumber  
   , MP.VIN  
 FROM  MemberProduct MP (NOLOCK)  
 JOIN  Membership MS (NOLOCK) ON MP.MembershipID = MS.ID   
 LEFT JOIN Product P (NOLOCK) ON P.ID = MP.ProductID  
 LEFT JOIN ProductProvider PP (NOLOCK) ON PP.ID = MP.ProductProviderID  
 WHERE  MP.MemberID = @MemberID  
    OR  
    (MP.MemberID IS NULL AND MS.ID = (SELECT MembershipID FROM Member WHERE ID = @MemberID))   
 ORDER BY P.Description  
  
  
INSERT INTO @FinalResults  
SELECT   
 T.Product,  
 T.StartDate,  
 T.EndDate,  
 T.Status,  
 T.Provider,  
 T.PhoneNumber,  
 T.ContractNumber,  
 T.VIN  
FROM @QueryResults T,  
@tmpForWhereClause TMP   
WHERE (   
  
 (   
  ( TMP.ProductOperator = -1 )   
 OR   
  ( TMP.ProductOperator = 0 AND T.Product IS NULL )   
 OR   
  ( TMP.ProductOperator = 1 AND T.Product IS NOT NULL )   
 OR   
  ( TMP.ProductOperator = 2 AND T.Product = TMP.ProductValue )   
 OR   
  ( TMP.ProductOperator = 3 AND T.Product <> TMP.ProductValue )   
 OR   
  ( TMP.ProductOperator = 4 AND T.Product LIKE TMP.ProductValue + '%')   
 OR   
  ( TMP.ProductOperator = 5 AND T.Product LIKE '%' + TMP.ProductValue )   
 OR   
  ( TMP.ProductOperator = 6 AND T.Product LIKE '%' + TMP.ProductValue + '%' )   
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
  ( TMP.StatusOperator = -1 )   
 OR   
  ( TMP.StatusOperator = 0 AND T.Status IS NULL )   
 OR   
  ( TMP.StatusOperator = 1 AND T.Status IS NOT NULL )   
 OR   
  ( TMP.StatusOperator = 2 AND T.Status = TMP.StatusValue )   
 OR   
  ( TMP.StatusOperator = 3 AND T.Status <> TMP.StatusValue )   
 OR   
  ( TMP.StatusOperator = 4 AND T.Status LIKE TMP.StatusValue + '%')   
 OR   
  ( TMP.StatusOperator = 5 AND T.Status LIKE '%' + TMP.StatusValue )   
 OR   
  ( TMP.StatusOperator = 6 AND T.Status LIKE '%' + TMP.StatusValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.ProviderOperator = -1 )   
 OR   
  ( TMP.ProviderOperator = 0 AND T.Provider IS NULL )   
 OR   
  ( TMP.ProviderOperator = 1 AND T.Provider IS NOT NULL )   
 OR   
  ( TMP.ProviderOperator = 2 AND T.Provider = TMP.ProviderValue )   
 OR   
  ( TMP.ProviderOperator = 3 AND T.Provider <> TMP.ProviderValue )   
 OR   
  ( TMP.ProviderOperator = 4 AND T.Provider LIKE TMP.ProviderValue + '%')   
 OR   
  ( TMP.ProviderOperator = 5 AND T.Provider LIKE '%' + TMP.ProviderValue )   
 OR   
  ( TMP.ProviderOperator = 6 AND T.Provider LIKE '%' + TMP.ProviderValue + '%' )   
 )   
  AND   
  
 (   
  ( TMP.ContractNumberOperator = -1 )   
 OR   
  ( TMP.ContractNumberOperator = 0 AND T.ContractNumber IS NULL )   
 OR   
  ( TMP.ContractNumberOperator = 1 AND T.ContractNumber IS NOT NULL )   
 OR   
  ( TMP.ContractNumberOperator = 2 AND T.ContractNumber = TMP.ContractNumberValue )   
 OR   
  ( TMP.ContractNumberOperator = 3 AND T.ContractNumber <> TMP.ContractNumberValue )   
 OR   
  ( TMP.ContractNumberOperator = 4 AND T.ContractNumber LIKE TMP.ContractNumberValue + '%')   
 OR   
  ( TMP.ContractNumberOperator = 5 AND T.ContractNumber LIKE '%' + TMP.ContractNumberValue )   
 OR   
  ( TMP.ContractNumberOperator = 6 AND T.ContractNumber LIKE '%' + TMP.ContractNumberValue + '%' )   
 )   
 AND   
  
 (   
  ( TMP.VINOperator = -1 )   
 OR   
  ( TMP.VINOperator = 0 AND T.VIN IS NULL )   
 OR   
  ( TMP.VINOperator = 1 AND T.VIN IS NOT NULL )   
 OR   
  ( TMP.VINOperator = 2 AND T.VIN = TMP.VINValue )   
 OR   
  ( TMP.VINOperator = 3 AND T.VIN <> TMP.VINValue )   
 OR   
  ( TMP.VINOperator = 4 AND T.VIN LIKE TMP.VINValue + '%')   
 OR   
  ( TMP.VINOperator = 5 AND T.VIN LIKE '%' + TMP.VINValue )   
 OR   
  ( TMP.VINOperator = 6 AND T.VIN LIKE '%' + TMP.VINValue + '%' )   
 )   
  
 AND   
 1 = 1   
 )   
 ORDER BY   
  CASE WHEN @sortColumn = 'Product' AND @sortOrder = 'ASC'  
  THEN T.Product END ASC,   
  CASE WHEN @sortColumn = 'Product' AND @sortOrder = 'DESC'  
  THEN T.Product END DESC ,  
  
  CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'ASC'  
  THEN T.StartDate END ASC,   
  CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'DESC'  
  THEN T.StartDate END DESC ,  
  
  CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'ASC'  
  THEN T.EndDate END ASC,   
  CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'DESC'  
  THEN T.EndDate END DESC ,  
  
  CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'  
  THEN T.Status END ASC,   
  CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'  
  THEN T.Status END DESC ,  
  
  CASE WHEN @sortColumn = 'Provider' AND @sortOrder = 'ASC'  
  THEN T.Provider END ASC,   
  CASE WHEN @sortColumn = 'Provider' AND @sortOrder = 'DESC'  
  THEN T.Provider END DESC ,  
  
  CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'  
  THEN T.PhoneNumber END ASC,   
  CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'  
  THEN T.PhoneNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'ContractNumber' AND @sortOrder = 'ASC'  
  THEN T.ContractNumber END ASC,   
  CASE WHEN @sortColumn = 'ContractNumber' AND @sortOrder = 'DESC'  
  THEN T.ContractNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'VIN' AND @sortOrder = 'ASC'  
  THEN T.VIN END ASC,   
  CASE WHEN @sortColumn = 'VIN' AND @sortOrder = 'DESC'  
  THEN T.VIN END DESC   
  
  
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
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Member_Products_Using_Category]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_Products_Using_Category] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- dms_Member_Products_Using_Category 898, 3
CREATE PROC [dbo].[dms_Member_Products_Using_Category](
	@memberID INT = NULL,
	@productCategoryID INT = NULL,
	@VIN nvarchar(50) = NULL
)
AS
BEGIN
	SELECT	ISNULL(REPLACE(RTRIM(
			COALESCE(p.Description, '') +
			--COALESCE(', ' + CONVERT(VARCHAR(10),mp.StartDate,101),'') + 
			--COALESCE(' - ' + CONVERT(VARCHAR(10),mp.EndDate,101), '') +
			COALESCE(', ' + pp.Description, '') +  
			COALESCE(', ' + pp.PhoneNumber, '') 
			), '  ', ' ')
			,'') AS [AdditionalProduct]
		, pp.Script AS [HelpText]
FROM	MemberProduct mp (NOLOCK)
JOIN	Membership ms (NOLOCK) ON mp.MembershipID = ms.ID
JOIN	Product p (NOLOCK) ON p.ID = mp.ProductID
JOIN	ProductProvider pp (NOLOCK) ON pp.ID = mp.ProductProviderID
JOIN	MemberProductProductCategory mppc (NOLOCK) ON mppc.ProductID = p.ID AND mppc.ProductCategoryID = @productCategoryID 
WHERE	(mp.MemberID = @memberID
			OR
			(mp.MemberID IS NULL AND ms.ID = (SELECT MembershipID FROM Member WHERE ID = @MemberID))
			)
		AND (mp.VIN IS NULL OR mp.VIN = @VIN) 
ORDER BY p.Description
END
GO
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
  -- EXEC [dms_PO_Issue_Hagerty_EventMail_Tag_Get] 763
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
	
	, ms.MembershipNumber AS MemberNumber
	
	, ISNULL(m.FirstName,'') + ' ' + ISNULL(m.LastName,'') AS MemberName

	, c.VehicleYear + ' ' + CASE WHEN c.VehicleMake = 'Other' THEN c.VehicleMakeOther ELSE c.VehicleMake END + ' ' + CASE WHEN c.VehicleModel = 'Other' THEN c.VehicleModelOther ELSE c.VehicleModel END AS MemberVehicleDesc -- coalesce 

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
-- EXEC [dbo].[dms_program_productcategory_get] 1,NULL,NULL
 
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
		JOIN	[dbo].[fnc_getprogramsandparents](@ProgramID) FNCP ON PC.ProgramID = FNCP.ProgramID
		AND		(VehicleTypeID = @vehicleTypeID OR VehicleTypeID IS NULL)
		AND		(VehicleCategoryID = @vehicleCategoryID OR VehicleCategoryID IS NULL)

	
	) EL ON PC.ID = EL.ID
	WHERE PC.Name NOT IN ('Billing', 'Repair', 'MemberProduct')
	ORDER BY PC.Sequence

END
GO

/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_servicerequest_get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_servicerequest_get]
GO
/****** Object:  StoredProcedure [dbo].[dms_servicerequest_get]    Script Date: 07/03/2012 17:56:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC  [dbo].[dms_servicerequest_get] 1414
CREATE PROCEDURE [dbo].[dms_servicerequest_get](
   @serviceRequestID INT=NULL
)
AS
BEGIN
SET NOCOUNT ON

declare @MemberID INT=NULL
-- GET CASE ID
SET   @MemberID =(SELECT CaseID FROM [ServiceRequest](NOLOCK) WHERE ID = @serviceRequestID)
-- GET Member ID
SET @MemberID =(SELECT MemberID FROM [Case](NOLOCK) WHERE ID = @MemberID)

DECLARE @ProductID INT
SET @ProductID =NULL
SELECT  @ProductID = PrimaryProductID FROM ServiceRequest(NOLOCK) WHERE ID = @serviceRequestID

DECLARE @memberEntityID INT
DECLARE @vendorLocationEntityID INT
DECLARE @otherReasonID INT
DECLARE @dispatchPhoneTypeID INT

SET @memberEntityID = (SELECT ID FROM Entity(NOLOCK) WHERE Name ='Member')
SET @vendorLocationEntityID = (SELECT ID FROM Entity(NOLOCK) WHERE Name ='VendorLocation')
SET @otherReasonID = (Select ID From PurchaseOrderCancellationReason(NOLOCK) Where Name ='Other')
SET @dispatchPhoneTypeID = (SELECT ID FROM PhoneType(NOLOCK) WHERE Name ='Dispatch')

SELECT
		-- Service Request Data Section
		-- Column 1		
		SR.CaseID,
		C.IsDeliveryDriver,
		SR.ID AS [RequestNumber],
		SRS.Name AS [Status],
		SRP.Name AS [Priority],
		SR.CreateDate AS [CreateDate],
		SR.CreateBy AS [CreateBy],
		SR.ModifyDate AS [ModifyDate],
		SR.ModifyBy AS [ModifyBy],
		-- Column 2
		NA.Name AS [NextAction],
		SR.NextActionScheduledDate AS [NextActionScheduledDate],
		SASU.FirstName +' '+ SASU.LastName AS [NextActionAssignedTo],
		CLS.Name AS [ClosedLoop],
		SR.ClosedLoopNextSend AS [ClosedLoopNextSend],
		-- Column 3
		CASE WHEN SR.IsPossibleTow = 1 THEN PC.Name +'/Possible Tow'ELSE PC.Name +''END AS [ServiceCategory],
		CASE
			WHEN SRS.Name ='Dispatched'
				  THEN CONVERT(VARCHAR(6),DATEDIFF(SECOND,sr.CreateDate,GETDATE())/3600)+':'
						+RIGHT('0'+CONVERT(VARCHAR(2),(DATEDIFF(SECOND,sr.CreateDate,GETDATE())%3600)/60),2)
			ELSE''
		END AS [Elapsed],
		(SELECT MAX(IssueDate)FROM PurchaseOrder(NOLOCK) Where ServiceRequestID = @ServiceRequestID) AS [PoMaxIssueDate],
		(SELECT MAX(ETADate)FROM PurchaseOrder(NOLOCK) Where ServiceRequestID = @ServiceRequestID) AS [PoMaxETADate],
		SR.DataTransferDate AS [DataTransferDate],

		-- Member data  
		M.ClientMemberType,
		REPLACE(RTRIM(
		COALESCE(m.FirstName,'')+
		COALESCE(' '+left(m.MiddleName,1),'')+
		COALESCE(' '+ m.LastName,'')+
		COALESCE(' '+ m.Suffix,'')
		),'  ',' ')AS [Member],
		MS.MembershipNumber,
		C.MemberStatus,
		CL.Name AS [Client],
		P.ID AS ProgramID,
		P.Name AS [ProgramName],
		CONVERT(varchar(10),M.MemberSinceDate,101)AS [MemberSince],
		CONVERT(varchar(10),M.ExpirationDate,101)AS [ExpirationDate],
		MS.ClientReferenceNumber as [ClientReferenceNumber],
		ISNULL((SELECT NAME FROM PhoneType(NOLOCK) WHERE ID = c.ContactPhoneTypeID),'')AS [CallbackPhoneType],
		C.ContactPhoneNumber AS [CallbackNumber],
		ISNULL((SELECT NAME FROM PhoneType(NOLOCK) WHERE ID = c.ContactAltPhoneTypeID),'')AS [AlternatePhoneType],
		C.ContactAltPhoneNumber AS [AlternateNumber],
		ISNULL(MA.Line1,'')AS Line1,
		ISNULL(MA.Line2,'')AS Line2,
		ISNULL(MA.Line3,'')AS Line3,
		REPLACE(RTRIM(
			COALESCE(MA.City,'')+
			COALESCE(', '+RTRIM(MA.StateProvince),'')+
			COALESCE(' '+LTRIM(MA.PostalCode),'')+
			COALESCE(' '+ MA.CountryCode,'')
			),' ',' ')AS MemberCityStateZipCountry,

		-- Vehicle Section
		-- Vehcile 
		ISNULL(RTRIM(COALESCE(c.VehicleYear +' ','')+
		COALESCE(CASE c.VehicleMake WHEN'Other'THEN C.VehicleMakeOther ELSE C.VehicleMake END+' ','')+
		COALESCE(CASE C.VehicleModel WHEN'Other'THEN C.VehicleModelOther ELSE C.VehicleModel END,'')),' ')AS [YearMakeModel],
		VT.Name +' - '+ VC.Name AS [VehicleTypeAndCategory],
		C.VehicleColor AS [VehicleColor],
		C.VehicleVIN AS [VehicleVIN],
		COALESCE(C.VehicleLicenseState +'-','')+COALESCE(c.VehicleLicenseNumber,'')AS [License],
		C.VehicleDescription,
		-- For vehicle type = RV only  
		RVT.Name AS [RVType],
		C.VehicleChassis AS [VehicleChassis],
		C.VehicleEngine AS [VehicleEngine],
		C.VehicleTransmission AS [VehicleTransmission],
		C.VehicleCurrentMileage AS [Mileage],
		-- Location  
		SR.ServiceLocationAddress +' '+ SR.ServiceLocationCountryCode AS [ServiceLocationAddress],
		SR.ServiceLocationDescription,
		-- Destination
		SR.DestinationAddress +' '+ SR.DestinationCountryCode AS [DestinationAddress],
		SR.DestinationDescription,

		-- Service Section 
		CASE
			WHEN SR.IsPossibleTow = 1 
			THEN PC.Name +'/Possible Tow'
			ELSE PC.Name
		END AS [ServiceCategorySection],
		SR.PrimaryCoverageLimit As CoverageLimit,
		CASE
			WHEN C.IsSafe IN(NULL,1)
			THEN'Yes'
			ELSE'No'
		END AS [Safe],
		SR.PrimaryProductID,
		(SELECT Name FROM Product WHERE ID = SR.PrimaryProductID) AS PrimaryProductName,
		SR.PrimaryServiceEligiblityMessage,
		SR.SecondaryProductID,
		(SELECT Name FROM Product WHERE ID = SR.SecondaryProductID) AS SecondaryProductName,
		SR.SecondaryServiceEligiblityMessage,
		SR.IsPrimaryOverallCovered,
		SR.IsSecondaryOverallCovered,
		SR.IsPossibleTow,
		

		-- Service Q&A's


		---- Service Provider Section  
		--CASE 
		--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NOT NULL THEN 'Contracted'
		--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NULL THEN 'Not Contracted'
		--	WHEN c.ID IS NOT NULL THEN 'Contracted' 
		--	ELSE 'Not Contracted'
		--	END as ContractStatus,
		CASE
			WHEN ContractedVendors.ContractID IS NOT NULL 
				AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'
			ELSE 'Not Contracted' 
			END AS ContractStatus,
		V.Name AS [VendorName],
		V.ID AS [VendorID],
		V.VendorNumber AS [VendorNumber],
		(SELECT TOP 1 PE.PhoneNumber
			FROM PhoneEntity PE
			WHERE PE.RecordID = VL.ID
			AND PE.EntityID = @vendorLocationEntityID
			AND PE.PhoneTypeID = @dispatchPhoneTypeID
			ORDER BY PE.ID DESC
		) AS [VendorLocationPhoneNumber] ,
		VLA.Line1 AS [VendorLocationLine1],
		VLA.Line2 AS [VendorLocationLine2],
		VLA.Line3 AS [VendorLocationLine3],
		REPLACE(RTRIM(
			COALESCE(VLA.City,'')+
			COALESCE(', '+RTRIM(VLA.StateProvince),'')+
			COALESCE(' '+LTRIM(VLA.PostalCode),'')+
			COALESCE(' '+ VLA.CountryCode,'')
			),' ',' ')AS VendorCityStateZipCountry,
		-- PO data
		convert(int,PO.PurchaseOrderNumber) AS [PONumber],
		PO.LegacyReferenceNumber,
		--convert(int,PO.ID) AS [PONumber],
		POS.Name AS [POStatus],
		CASE
				WHEN PO.CancellationReasonID = @otherReasonID
				THEN PO.CancellationReasonOther 
				ELSE ISNULL(CR.Name,'')
		END AS [CancelReason],
		PO.PurchaseOrderAmount AS [POAmount],
		POPC.Name AS [ServiceType],
		PO.IssueDate AS [IssueDate],
		PO.ETADate AS [ETADate],
		PO.DataTransferDate AS [ExtractDate],

		-- Other
		CASE WHEN C.AssignedToUserID IS NOT NULL
			THEN'*'+ISNULL(ASU.FirstName,'')+' '+ISNULL(ASU.LastName,'')
			ELSE ISNULL(SASU.FirstName,'')+' '+ISNULL(SASU.LastName,'')
		END AS [AssignedTo],
		C.AssignedToUserID AS [AssignedToID],
      
      -- Vendor Invoice Details
		VI.InvoiceDate,
		CASE	WHEN PT.Name = 'ACH' 
		THEN 'ACH'
				WHEN PT.Name = 'Check'
		THEN VI.PaymentNumber
		ELSE ''
		END AS PaymentType,
		
		VI.PaymentAmount,
		VI.PaymentDate,
		VI.CheckClearedDate
FROM [ServiceRequest](NOLOCK) SR  
JOIN [Case](NOLOCK) C ON C.ID = SR.CaseID  
JOIN [ServiceRequestStatus](NOLOCK) SRS ON SR.ServiceRequestStatusID = SRS.ID  
LEFT JOIN [ServiceRequestPriority](NOLOCK) SRP ON SR.ServiceRequestPriorityID = SRP.ID   
LEFT JOIN [Program](NOLOCK) P ON C.ProgramID = P.ID   
LEFT JOIN [Client](NOLOCK) CL ON P.ClientID = CL.ID  
LEFT JOIN [Member](NOLOCK) M ON C.MemberID = M.ID  
LEFT JOIN [Membership](NOLOCK) MS ON M.MembershipID = MS.ID  
LEFT JOIN [AddressEntity](NOLOCK) MA ON M.ID = MA.RecordID  
            AND MA.EntityID = @memberEntityID
LEFT JOIN [Country](NOLOCK) MCNTRY ON MA.CountryCode = MCNTRY.ISOCode  
LEFT JOIN [Country](NOLOCK) LCNTRY ON SR.ServiceLocationCountryCode = LCNTRY.ISOCode  
LEFT JOIN [Country](NOLOCK) DCNTRY ON SR.DestinationCountryCode = DCNTRY.ISOCode  
LEFT JOIN [VehicleType](NOLOCK) VT ON C.VehicleTypeID = VT.ID  
LEFT JOIN [VehicleCategory](NOLOCK) VC ON C.VehicleCategoryID = VC.ID  
LEFT JOIN [RVType](NOLOCK) RVT ON C.VehicleRVTypeID = RVT.ID  
LEFT JOIN [ProductCategory](NOLOCK) PC ON PC.ID = SR.ProductCategoryID  
LEFT JOIN [User](NOLOCK) ASU ON C.AssignedToUserID = ASU.ID  
LEFT OUTER JOIN [User](NOLOCK) SASU ON SR.NextActionAssignedToUserID = SASU.ID  
LEFT JOIN [PurchaseOrder](NOLOCK) PO ON PO.ServiceRequestID = SR.ID  AND PO.IsActive = 1 
LEFT JOIN [PurchaseOrderStatus](NOLOCK) POS ON PO.PurchaseOrderStatusID = POS.ID
LEFT JOIN [PurchaseOrderCancellationReason](NOLOCK) CR ON PO.CancellationReasonID = CR.ID
LEFT JOIN [Product](NOLOCK) PR ON PO.ProductID = PR.ID
LEFT JOIN [ProductCategory](NOLOCK) POPC ON PR.ProductCategoryID = POPC.ID
LEFT JOIN [VendorLocation](NOLOCK) VL ON PO.VendorLocationID = VL.ID  
LEFT JOIN [AddressEntity](NOLOCK) VLA ON VL.ID = VLA.RecordID 
            AND VLA.EntityID =@vendorLocationEntityID
LEFT JOIN [Vendor](NOLOCK) V ON VL.VendorID = V.ID 
--LEFT JOIN [Contract](NOLOCK) CON on CON.VendorID = V.ID and CON.IsActive = 1 and CON.ContractStatusID = (Select ID From ContractStatus Where Name = 'Active')
LEFT JOIN [ClosedLoopStatus](NOLOCK) CLS ON SR.ClosedLoopStatusID = CLS.ID 
LEFT JOIN [NextAction](NOLOCK) NA ON SR.NextActionID = NA.ID

--Join to get information needed to determine Vendor Contract status ********************
--LEFT OUTER JOIN (
--      SELECT DISTINCT vr.VendorID, vr.ProductID
--      FROM dbo.fnGetCurrentProductRatesByVendorLocation() vr 
--      ) DefaultVendorRates ON v.ID = DefaultVendorRates.VendorID And @ProductID = DefaultVendorRates.ProductID
LEFT OUTER JOIN(
	  SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID
	  FROM dbo.fnGetContractedVendors() cv
	  ) ContractedVendors ON v.ID = ContractedVendors.VendorID 
      
LEFT JOIN [VendorInvoice] VI WITH (NOLOCK) ON PO.ID = VI.PurchaseOrderID
LEFT JOIN [PaymentType] PT WITH (NOLOCK) ON VI.PaymentTypeID = PT.ID
WHERE SR.ID = @serviceRequestID

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
 WHERE id = object_id(N'[dbo].[dms_StartCall_MemberSelections]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_StartCall_MemberSelections] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 CREATE PROCEDURE [dbo].[dms_StartCall_MemberSelections]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @memberIDCommaSeprated nvarchar(MAX) = NULL
  
 ) 
 AS 
 BEGIN 
  SET NOCOUNT OFF
  SET FMTONLY OFF

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
MemberIDOperator="-1" 
MembershipIDOperator="-1" 
MembershipNumberOperator="-1" 
MemberNameOperator="-1" 
AddressOperator="-1" 
PhoneNumberOperator="-1" 
ProgramIDOperator="-1" 
ProgramOperator="-1" 
VINOperator="-1" 
MemberStatusOperator="-1" 
POCountOperator="-1" 
 ></Filter></ROW>'
END

DECLARE @tmpForWhereClause AS TABLE
(
MemberIDOperator INT NOT NULL,
MemberIDValue int NULL,
MembershipIDOperator INT NOT NULL,
MembershipIDValue int NULL,
MembershipNumberOperator INT NOT NULL,
MembershipNumberValue nvarchar(100) NULL,
MemberNameOperator INT NOT NULL,
MemberNameValue nvarchar(100) NULL,
AddressOperator INT NOT NULL,
AddressValue nvarchar(100) NULL,
PhoneNumberOperator INT NOT NULL,
PhoneNumberValue nvarchar(100) NULL,
ProgramIDOperator INT NOT NULL,
ProgramIDValue int NULL,
ProgramOperator INT NOT NULL,
ProgramValue nvarchar(100) NULL,
VINOperator INT NOT NULL,
VINValue nvarchar(100) NULL,
MemberStatusOperator INT NOT NULL,
MemberStatusValue nvarchar(100) NULL,
POCountOperator INT NOT NULL,
POCountValue int NULL
)

DECLARE @FinalResults AS TABLE( 
		[RowNum] [bigint] NOT NULL IDENTITY(1,1),
		MemberID int  NULL ,
		MembershipID int  NULL ,
		MembershipNumber nvarchar(200)  NULL ,
		MemberName NVARCHAR(MAX)  NULL ,
		Address NVARCHAR(MAX)  NULL ,
		PhoneNumber NVARCHAR(MAX)  NULL ,
		ProgramID INT NULL ,
		Program nvarchar(200) NULL,
		VIN nvarchar(200) NULL,
		MemberStatus nvarchar(200) NULL,
		POCount INT NULL,
		ClientMemberType nvarchar(200) NULL
) 

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@MemberIDOperator','INT'),-1),
	T.c.value('@MemberIDValue','int') ,
	ISNULL(T.c.value('@MembershipIDOperator','INT'),-1),
	T.c.value('@MembershipIDValue','int') ,
	ISNULL(T.c.value('@MembershipNumberOperator','INT'),-1),
	T.c.value('@MembershipNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@MemberNameOperator','INT'),-1),
	T.c.value('@MemberNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@AddressOperator','INT'),-1),
	T.c.value('@AddressValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PhoneNumberOperator','INT'),-1),
	T.c.value('@PhoneNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProgramIDOperator','INT'),-1),
	T.c.value('@ProgramIDValue','int') ,
	ISNULL(T.c.value('@ProgramOperator','INT'),-1),
	T.c.value('@ProgramValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VINOperator','INT'),-1),
	T.c.value('@VINValue','nvarchar(100)') ,
	ISNULL(T.c.value('@MemberStatusOperator','INT'),-1),
	T.c.value('@MemberStatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@POCountOperator','INT'),-1),
	T.c.value('@POCountValue','int') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
 DECLARE @QueryResult AS TABLE( 
		MemberID int  NULL ,
		MembershipID int  NULL ,
		MembershipNumber nvarchar(200)  NULL ,
		MemberName NVARCHAR(MAX)  NULL ,
		Address NVARCHAR(MAX)  NULL ,
		PhoneNumber NVARCHAR(MAX)  NULL ,
		ProgramID INT NULL ,
		Program nvarchar(200) NULL,
		VIN nvarchar(200) NULL,
		MemberStatus nvarchar(200) NULL,
		POCount INT NULL,
		ClientMemberType nvarchar(200) NULL
)


-- Dates used while calculating member status
DECLARE @now DATETIME, @minDate DATETIME
SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
SET @minDate = '1900-01-01'     

DECLARE @MemberIDValues AS TABLE(MemberID INT NULL)
INSERT INTO @MemberIDValues SELECT item from dbo.fnSplitString(@memberIDCommaSeprated,',')

DECLARE @memberEntityID INT  
SELECT  @memberEntityID = ID FROM Entity WHERE Name = 'Member' 

SELECT * INTO #tmpPhone  
		 FROM PhoneEntity PH WITH (NOLOCK)  
		 WHERE PH.EntityID = @memberEntityID   
		 AND  PH.RecordID IN (SELECT MemberID FROM @MemberIDValues)

INSERT INTO @QueryResult
SELECT DISTINCT    	  M.ID AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber
					,REPLACE(RTRIM( COALESCE(M.FirstName, '') + 
									COALESCE(' ' + left(M.MiddleName,1), '') + 
									COALESCE(' ' + M.LastName, '') +
									COALESCE(' ' + M.Suffix, '')), ' ', ' ') 
									AS MemberName
					,(ISNULL(A.City,'') + ',' + ISNULL(A.StateProvince,'') + ' ' + ISNULL(A.PostalCode,'')) AS [Address]  
					, COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber 
					, P.ID As ProgramID  -- KB: ADDED IDS
					, P.[Description] AS Program    
					, '' AS VIN
					, CASE WHEN ISNULL(M.EffectiveDate,@minDate) <= @now AND ISNULL(M.ExpirationDate,@minDate) >= @now
					  THEN 'Active' ELSE 'Inactive' END AS MemberStatus
					,(SELECT COUNT(*) FROM [Case] WITH (NOLOCK) WHERE MemberID = M.ID) AS POCount
					,M.ClientMemberType
			FROM Member M
			LEFT JOIN Membership MS WITH (NOLOCK) ON  M.MembershipID = MS.ID
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID AND A.RecordID IN (SELECT MemberID FROM @MemberIDValues) 
			LEFT JOIN #tmpPhone PH WITH (NOLOCK) ON PH.RecordID = M.ID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID 
			LEFT JOIN #tmpPhone PW WITH (NOLOCK) ON PW.RecordID = M.ID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID 
			LEFT JOIN #tmpPhone PC WITH (NOLOCK) ON PC.RecordID = M.ID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID 
			JOIN Program P WITH (NOLOCK) ON P.ID = M.ProgramID
			WHERE M.ID IN (SELECT MemberID FROM @MemberIDValues)

DROP TABLE #tmpPhone


INSERT INTO @FinalResults
SELECT 
	T.MemberID,
	T.MembershipID,
	T.MembershipNumber,
	T.MemberName,
	T.Address,
	T.PhoneNumber,
	T.ProgramID,
	T.Program,
	T.VIN,
	T.MemberStatus,
	T.POCount,
	T.ClientMemberType
FROM @QueryResult T,
@tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.MemberIDOperator = -1 ) 
 OR 
	 ( TMP.MemberIDOperator = 0 AND T.MemberID IS NULL ) 
 OR 
	 ( TMP.MemberIDOperator = 1 AND T.MemberID IS NOT NULL ) 
 OR 
	 ( TMP.MemberIDOperator = 2 AND T.MemberID = TMP.MemberIDValue ) 
 OR 
	 ( TMP.MemberIDOperator = 3 AND T.MemberID <> TMP.MemberIDValue ) 
 OR 
	 ( TMP.MemberIDOperator = 7 AND T.MemberID > TMP.MemberIDValue ) 
 OR 
	 ( TMP.MemberIDOperator = 8 AND T.MemberID >= TMP.MemberIDValue ) 
 OR 
	 ( TMP.MemberIDOperator = 9 AND T.MemberID < TMP.MemberIDValue ) 
 OR 
	 ( TMP.MemberIDOperator = 10 AND T.MemberID <= TMP.MemberIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.MembershipIDOperator = -1 ) 
 OR 
	 ( TMP.MembershipIDOperator = 0 AND T.MembershipID IS NULL ) 
 OR 
	 ( TMP.MembershipIDOperator = 1 AND T.MembershipID IS NOT NULL ) 
 OR 
	 ( TMP.MembershipIDOperator = 2 AND T.MembershipID = TMP.MembershipIDValue ) 
 OR 
	 ( TMP.MembershipIDOperator = 3 AND T.MembershipID <> TMP.MembershipIDValue ) 
 OR 
	 ( TMP.MembershipIDOperator = 7 AND T.MembershipID > TMP.MembershipIDValue ) 
 OR 
	 ( TMP.MembershipIDOperator = 8 AND T.MembershipID >= TMP.MembershipIDValue ) 
 OR 
	 ( TMP.MembershipIDOperator = 9 AND T.MembershipID < TMP.MembershipIDValue ) 
 OR 
	 ( TMP.MembershipIDOperator = 10 AND T.MembershipID <= TMP.MembershipIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.MembershipNumberOperator = -1 ) 
 OR 
	 ( TMP.MembershipNumberOperator = 0 AND T.MembershipNumber IS NULL ) 
 OR 
	 ( TMP.MembershipNumberOperator = 1 AND T.MembershipNumber IS NOT NULL ) 
 OR 
	 ( TMP.MembershipNumberOperator = 2 AND T.MembershipNumber = TMP.MembershipNumberValue ) 
 OR 
	 ( TMP.MembershipNumberOperator = 3 AND T.MembershipNumber <> TMP.MembershipNumberValue ) 
 OR 
	 ( TMP.MembershipNumberOperator = 4 AND T.MembershipNumber LIKE TMP.MembershipNumberValue + '%') 
 OR 
	 ( TMP.MembershipNumberOperator = 5 AND T.MembershipNumber LIKE '%' + TMP.MembershipNumberValue ) 
 OR 
	 ( TMP.MembershipNumberOperator = 6 AND T.MembershipNumber LIKE '%' + TMP.MembershipNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.MemberNameOperator = -1 ) 
 OR 
	 ( TMP.MemberNameOperator = 0 AND T.MemberName IS NULL ) 
 OR 
	 ( TMP.MemberNameOperator = 1 AND T.MemberName IS NOT NULL ) 
 OR 
	 ( TMP.MemberNameOperator = 2 AND T.MemberName = TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 3 AND T.MemberName <> TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 4 AND T.MemberName LIKE TMP.MemberNameValue + '%') 
 OR 
	 ( TMP.MemberNameOperator = 5 AND T.MemberName LIKE '%' + TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 6 AND T.MemberName LIKE '%' + TMP.MemberNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.AddressOperator = -1 ) 
 OR 
	 ( TMP.AddressOperator = 0 AND T.Address IS NULL ) 
 OR 
	 ( TMP.AddressOperator = 1 AND T.Address IS NOT NULL ) 
 OR 
	 ( TMP.AddressOperator = 2 AND T.Address = TMP.AddressValue ) 
 OR 
	 ( TMP.AddressOperator = 3 AND T.Address <> TMP.AddressValue ) 
 OR 
	 ( TMP.AddressOperator = 4 AND T.Address LIKE TMP.AddressValue + '%') 
 OR 
	 ( TMP.AddressOperator = 5 AND T.Address LIKE '%' + TMP.AddressValue ) 
 OR 
	 ( TMP.AddressOperator = 6 AND T.Address LIKE '%' + TMP.AddressValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PhoneNumberOperator = -1 ) 
 OR 
	 ( TMP.PhoneNumberOperator = 0 AND T.PhoneNumber IS NULL ) 
 OR 
	 ( TMP.PhoneNumberOperator = 1 AND T.PhoneNumber IS NOT NULL ) 
 OR 
	 ( TMP.PhoneNumberOperator = 2 AND T.PhoneNumber = TMP.PhoneNumberValue ) 
 OR 
	 ( TMP.PhoneNumberOperator = 3 AND T.PhoneNumber <> TMP.PhoneNumberValue ) 
 OR 
	 ( TMP.PhoneNumberOperator = 4 AND T.PhoneNumber LIKE TMP.PhoneNumberValue + '%') 
 OR 
	 ( TMP.PhoneNumberOperator = 5 AND T.PhoneNumber LIKE '%' + TMP.PhoneNumberValue ) 
 OR 
	 ( TMP.PhoneNumberOperator = 6 AND T.PhoneNumber LIKE '%' + TMP.PhoneNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProgramIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramIDOperator = 0 AND T.ProgramID IS NULL ) 
 OR 
	 ( TMP.ProgramIDOperator = 1 AND T.ProgramID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramIDOperator = 2 AND T.ProgramID = TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 3 AND T.ProgramID <> TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 7 AND T.ProgramID > TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 8 AND T.ProgramID >= TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 9 AND T.ProgramID < TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 10 AND T.ProgramID <= TMP.ProgramIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ProgramOperator = -1 ) 
 OR 
	 ( TMP.ProgramOperator = 0 AND T.Program IS NULL ) 
 OR 
	 ( TMP.ProgramOperator = 1 AND T.Program IS NOT NULL ) 
 OR 
	 ( TMP.ProgramOperator = 2 AND T.Program = TMP.ProgramValue ) 
 OR 
	 ( TMP.ProgramOperator = 3 AND T.Program <> TMP.ProgramValue ) 
 OR 
	 ( TMP.ProgramOperator = 4 AND T.Program LIKE TMP.ProgramValue + '%') 
 OR 
	 ( TMP.ProgramOperator = 5 AND T.Program LIKE '%' + TMP.ProgramValue ) 
 OR 
	 ( TMP.ProgramOperator = 6 AND T.Program LIKE '%' + TMP.ProgramValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VINOperator = -1 ) 
 OR 
	 ( TMP.VINOperator = 0 AND T.VIN IS NULL ) 
 OR 
	 ( TMP.VINOperator = 1 AND T.VIN IS NOT NULL ) 
 OR 
	 ( TMP.VINOperator = 2 AND T.VIN = TMP.VINValue ) 
 OR 
	 ( TMP.VINOperator = 3 AND T.VIN <> TMP.VINValue ) 
 OR 
	 ( TMP.VINOperator = 4 AND T.VIN LIKE TMP.VINValue + '%') 
 OR 
	 ( TMP.VINOperator = 5 AND T.VIN LIKE '%' + TMP.VINValue ) 
 OR 
	 ( TMP.VINOperator = 6 AND T.VIN LIKE '%' + TMP.VINValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.MemberStatusOperator = -1 ) 
 OR 
	 ( TMP.MemberStatusOperator = 0 AND T.MemberStatus IS NULL ) 
 OR 
	 ( TMP.MemberStatusOperator = 1 AND T.MemberStatus IS NOT NULL ) 
 OR 
	 ( TMP.MemberStatusOperator = 2 AND T.MemberStatus = TMP.MemberStatusValue ) 
 OR 
	 ( TMP.MemberStatusOperator = 3 AND T.MemberStatus <> TMP.MemberStatusValue ) 
 OR 
	 ( TMP.MemberStatusOperator = 4 AND T.MemberStatus LIKE TMP.MemberStatusValue + '%') 
 OR 
	 ( TMP.MemberStatusOperator = 5 AND T.MemberStatus LIKE '%' + TMP.MemberStatusValue ) 
 OR 
	 ( TMP.MemberStatusOperator = 6 AND T.MemberStatus LIKE '%' + TMP.MemberStatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.POCountOperator = -1 ) 
 OR 
	 ( TMP.POCountOperator = 0 AND T.POCount IS NULL ) 
 OR 
	 ( TMP.POCountOperator = 1 AND T.POCount IS NOT NULL ) 
 OR 
	 ( TMP.POCountOperator = 2 AND T.POCount = TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 3 AND T.POCount <> TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 7 AND T.POCount > TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 8 AND T.POCount >= TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 9 AND T.POCount < TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 10 AND T.POCount <= TMP.POCountValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'
	 THEN T.MemberID END ASC, 
	 CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'
	 THEN T.MemberID END DESC ,

	 CASE WHEN @sortColumn = 'MembershipID' AND @sortOrder = 'ASC'
	 THEN T.MembershipID END ASC, 
	 CASE WHEN @sortColumn = 'MembershipID' AND @sortOrder = 'DESC'
	 THEN T.MembershipID END DESC ,

	 CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'
	 THEN T.MembershipNumber END ASC, 
	 CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'
	 THEN T.MembershipNumber END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.MemberName END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.MemberName END DESC ,

	 CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'
	 THEN T.Address END ASC, 
	 CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'
	 THEN T.Address END DESC ,

	 CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'
	 THEN T.PhoneNumber END ASC, 
	 CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'
	 THEN T.PhoneNumber END DESC ,

	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'ASC'
	 THEN T.ProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'DESC'
	 THEN T.ProgramID END DESC ,

	 CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'
	 THEN T.Program END ASC, 
	 CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'
	 THEN T.Program END DESC ,

	 CASE WHEN @sortColumn = 'VIN' AND @sortOrder = 'ASC'
	 THEN T.VIN END ASC, 
	 CASE WHEN @sortColumn = 'VIN' AND @sortOrder = 'DESC'
	 THEN T.VIN END DESC ,

	 CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'ASC'
	 THEN T.MemberStatus END ASC, 
	 CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'DESC'
	 THEN T.MemberStatus END DESC ,

	 CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'
	 THEN T.POCount END ASC, 
	 CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'
	 THEN T.POCount END DESC 


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
IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[vw_BillingInvoiceDefinitions]')   		AND type in (N'V')) 
BEGIN
DROP VIEW [dbo].[vw_BillingInvoiceDefinitions] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 

CREATE VIEW [dbo].[vw_BillingInvoiceDefinitions]
AS
Select TOP (2000000)
	c.ID ClientID
	,c.Name Client
	--,bdi.ID 
	,bdi.Name Invoice
	,bdi.PONumber ClientPONumber
	--, bdil.ID
	, bdil.Name LineItemName
	, bdil.Sequence LineItemNumber
	, bdile.Name LineItemBillingEvent
	, bdile.EventFilter LineItemBillingEventFilter
	, ProgramList.Programs
From [dbo].[BillingDefinitionInvoice] bdi
Join Client c on c.ID = bdi.ClientID
Join dbo.BillingDefinitionInvoiceLine bdil on bdil.BillingDefinitionInvoiceID = bdi.ID and bdil.IsActive = 1
Join dbo.BillingDefinitionInvoiceLineEvent bdile on bdile.BillingDefinitionInvoiceLineID = bdil.ID and bdile.IsActive = 1
Join (
	select distinct t1.BillingDefinitionInvoiceLineEventID,
	  STUFF(
			 (SELECT ', ' + '(' + convert(varchar(255), p.ID) + ') '  +  convert(varchar(255), Replace(p.Name,'&',' and '))
			  FROM BillingDefinitionInvoiceLineEventProgram t2
			  Join Program p on p.ID = t2.ProgramID
			  where t1.BillingDefinitionInvoiceLineEventID = t2.BillingDefinitionInvoiceLineEventID
			  FOR XML PATH (''))
			  , 1, 1, '')  AS Programs
	from BillingDefinitionInvoiceLineEventProgram t1
	Where t1.IsActive = 1
	) ProgramList ON ProgramList.BillingDefinitionInvoiceLineEventID = bdile.ID
Where 1=1
and bdi.IsActive = 1
Order by c.Name, bdi.Name, bdil.Sequence

GO
CREATE VIEW [dbo].[vw_ContactLogs]
AS
SELECT CL.ID ContactLogID,
	   CL.ContactCategoryID,
	   CC.Description ContactCategoryDescription,
	   CL.ContactTypeID,
	   CT.Description ContactTypeDescription,
	   CL.ContactMethodID,
	   CM.Description ContactMethodDescription,
	   CL.ContactSourceID,
	   CS.Description ContactSourceDescription,
	   CL.Company,
	   CL.TalkedTo,
	   CL.PhoneTypeID,
	   PT.Description PhoneTypeDescription,
	   CL.Email,
	   CL.Direction,
	   CL.Description,
	   CL.Data,
	   CL.Comments,
	   CL.AgentRating,
	   Cl.IsPossibleCallback,
	   CL.DataTransferDate,
	   CL.CreateDate,
	   CL.CreateBy,
	   CL.ModifyDate,
	   CL.ModifyBy,
	   CL.VendorServiceRatingAdjustment
FROM   ContactLog CL
LEFT JOIN ContactCategory CC ON CL.ContactCategoryID = CC.ID
LEFT JOIN ContactType CT ON CL.ContactTypeID = CT.ID
LEFT JOIN ContactMethod CM ON CL.ContactMethodID = CM.ID
LEFT JOIN ContactSource CS ON CL.ContactSourceID = CS.ID
LEFT JOIN PhoneType PT ON CL.PhoneTypeID = PT.ID

GO
CREATE VIEW [dbo].[vw_EventLogs]
AS
SELECT EL.ID EventLogID,
	   EL.EventID,
	   E.Description EventDescription,
	   EC.ID EventCategoryID,
	   EC.Description EventCategoryDescription,
	   EL.SessionID,
	   EL.Source,
	   EL.Description,
	   EL.Data,
	   EL.NotificationQueueDate,
	   EL.CreateDate,
	   EL.CreateBy
 FROM	   EventLog		 EL WITH(NOLOCK)
 LEFT JOIN Event		 E  WITH(NOLOCK) ON EL.EventID = E.ID
 LEFT JOIN EventCategory EC WITH(NOLOCK) ON E.EventCategoryID = EC.ID


GO

/****** Object:  View [dbo].[vw_PuchaseOrders]    Script Date: 01/07/2015 19:22:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_PuchaseOrders]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[vw_PuchaseOrders]
AS


SELECT PO.[ID]
      ,PO.[ServiceRequestID]
      ,PO.[OriginalPurchaseOrderID]
      ,PO.[ContactMethodID]
      ,CM.[Name] ContactMethodName
      ,PO.[PurchaseOrderTypeID]
      ,POT.[Name] PurchaseOrderTypeName
      ,POT.[Description] PurchaseOrderTypeDescription
      ,PO.[ProductID]
      ,P.[Name] ProductName
      ,P.[Description] ProductDescription
      ,PO.[PurchaseOrderNumber]
      ,PO.[PurchaseOrderStatusID]
      ,POS.[Name] PurchaseOrderStatusName
      ,POS.[Description] PurchaseOrderStatusDescription
      ,PO.[CancellationReasonID]
      ,POCR.[Name] PurchaseOrderCancellationReasonName
      ,POCR.[Description] PurchaseOrderCancellationReasonDescription
      ,PO.[CancellationReasonOther]
      ,PO.[CancellationComment]
      ,PO.[VehicleCategoryID]
      ,VC.[Name] VehicleCategoryName
      ,VC.[Description] VehicleCategoryDescription
      ,PO.[VendorLocationID]
      ,VL.[Email] VendorLocationEmail
      ,VL.[BusinessHours] VendorLocationBusinessHours
      ,VL.[DispatchEmail] VendorLocationDispatchEmail
      ,VL.[DealerNumber] VendorLocationDealerNumber
      ,VL.[DispatchNote] VendorLocationDispatchNote
      ,VL.[GeographyLocation] VendorLocationGeographyLocation
      ,VL.[IsOpen24Hours] VendorLocationIsOpen24Hours
      ,VL.[PartsAndAccessoryCode] VendorLocationPartsAndAccessoryCode
      ,PO.[BillingAddressTypeID]
      ,BAT.[Name] BillingAddressTypeName
      ,PO.[BillingAddressLine1]
      ,PO.[BillingAddressLine2]
      ,PO.[BillingAddressLine3]
      ,PO.[BillingAddressCity]
      ,PO.[BillingAddressStateProvince]
      ,PO.[BillingAddressPostalCode]
      ,PO.[BillingAddressCountryCode]
      ,PO.[DispatchPhoneNumber]
      ,PO.[DispatchPhoneTypeID]
      ,PO.[FaxPhoneTypeID]
      ,PO.[FaxPhoneNumber]
      ,PO.[Email]
      ,PO.[DealerIDNumber]
      ,PO.[EnrouteMiles]
      ,PO.[EnrouteFreeMiles]
      ,PO.[EnrouteTimeMinutes]
      ,PO.[ServiceMiles]
      ,PO.[ServiceFreeMiles]
      ,PO.[ServiceTimeMinutes]
      ,PO.[ReturnMiles]
      ,PO.[ReturnTimeMinutes]
      ,PO.[IsServiceCovered]
      ,PO.[CurrencyTypeID]
      ,CT.[Name] CurrencyTypeName
      ,CT.[Abbreviation] CurrencyTypeAbbreviation
      ,PO.[TaxAmount]
      ,PO.[TotalServiceAmount]
      ,PO.[MemberServiceAmount]
      ,PO.[MemberPaymentTypeID]
      ,PO.[CoachNetServiceAmount]
      ,PO.[IsMemberAmountCollectedByVendor]
      ,PO.[DispatchFee]
      ,PO.[DispatchFeeBillToID]
      ,PO.[MemberAmountDueToCoachNet]
      ,PO.[PurchaseOrderAmount]
      ,PO.[IsPayByCompanyCreditCard]
      ,PO.[CompanyCreditCardNumber]
      ,PO.[IssueDate]
      ,PO.[IsVendorAdvised]
      ,PO.[ETAMinutes]
      ,PO.[ETADate]
      ,PO.[AdditionalInstructions]
      ,PO.[LegacyReferenceNumber]
      ,PO.[ReadyForExportDate]
      ,PO.[DataTransferDate]
      ,PO.[IsActive]
      ,PO.[IsGOA]
      ,PO.[CreateDate]
      ,PO.[CreateBy]
      ,PO.[ModifyDate]
      ,PO.[ModifyBy]
      ,PO.[CoverageLimit]
      ,PO.[GOAReasonID]
      ,PO.[GOAReasonOther]
      ,PO.[GOAComment]
      ,PO.[GOAAuthorization]
      ,PO.[GOAAuthorizationDate]
      ,PO.[VendorLocationVirtualID]
      ,PO.[AccountingInvoiceBatchID]
      ,PO.[ContractStatus]
      ,PO.[AdminstrativeRating]
      ,PO.[ServiceRating]
      ,PO.[SelectionOrder]
      ,PO.[PayStatusCodeID]
      ,PO.[VendorTaxID]
      ,PO.[CoverageLimitMileage]
      ,PO.[MileageUOM]
      ,PO.[IsServiceCoverageBestValue]
      ,PO.[ServiceEligibilityMessage]
      ,PO.[IsServiceCoveredOverridden]
  FROM [dbo].[PurchaseOrder] PO
  LEFT JOIN [ServiceRequest] SR (NOLOCK) ON PO.ServiceRequestID = SR.ID
  LEFT JOIN [PurchaseOrder] PPO (NOLOCK) ON PO.OriginalPurchaseOrderID = PPO.ID
  LEFT JOIN [ContactMethod] CM (NOLOCK) ON PO.ContactMethodID = CM.ID
  LEFT JOIN [PurchaseOrderType] POT (NOLOCK) ON PO.PurchaseOrderTypeID = POT.ID
  LEFT JOIN [Product] P (NOLOCK) ON PO.ProductID = P.ID
  LEFT JOIN [PurchaseOrderStatus] POS (NOLOCK) ON PO.PurchaseOrderStatusID = POS.ID
  LEFT JOIN [PurchaseOrderCancellationReason] POCR (NOLOCK) ON PO.CancellationReasonID = POCR.ID
  LEFT JOIN [VehicleCategory] VC (NOLOCK) ON PO.VehicleCategoryID = VC.ID
  LEFT JOIN [VendorLocation] VL (NOLOCK) ON PO.VendorLocationID = VL.ID
  LEFT JOIN [AddressType] BAT (NOLOCK) ON PO.BillingAddressTypeID = BAT.ID
  LEFT JOIN [CurrencyType] CT ON PO.CurrencyTypeID = CT.ID
  








'
GO

GO
/****** Object:  View [dbo].[vw_ServiceRequests]    Script Date: 01/08/2015 11:32:25 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_ServiceRequests]'))
DROP VIEW [dbo].[vw_ServiceRequests]
GO
/****** Object:  View [dbo].[vw_ServiceRequests]    Script Date: 01/08/2015 11:32:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_ServiceRequests]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[vw_ServiceRequests]
AS
SELECT SR.[ID] ServiceRequestID
	  ,CL.[ID] ClientID
	  ,CL.[Name] ClientName
	  ,P.[ID] ProgramID
	  ,P.[Name] ProgramName
      ,SR.[ServiceRequestStatusID]
      ,SRS.[Name] ServiceRequestStatusName
      ,SRS.[Description] ServiceRequestStatusDescription
      ,SR.[ProductCategoryID]
      ,PC.[Name] ProductCategoryName
      ,pc.[Description] ProductCategoryDescription
      ,SR.[PrimaryProductID]
      ,PP.[Name] PrimaryProductName
      ,PP.[Description] PrimaryProductDescription
      ,SR.[SecondaryProductID]
      ,SP.[Name] SecondaryProductName
      ,SP.[Description] SecondaryProductDescription
      ,SR.[CaseID]
      ,C.[MemberID]
      ,C.[VehicleID]
      ,C.[CaseStatusID]
      ,CS.[Name] CaseStatusName
      ,C.[AssignedToUserID] CaseAssignedToUserID
      ,CU.[FirstName] CaseAssignedToUserFirstName
      ,CU.[LastName] CaseAssignedToUserLastName
      ,C.[ReferenceNumber] CaseReferenceNumber
      ,C.[MemberNumber] CaseMemberNumber
      ,C.[MemberStatus] CaseMemberStatus
      ,C.[CallTypeID] CaseCallTypeID
      ,CAT.[Name] CallTypeName
      ,C.[Language]
      ,C.[VehicleVIN]
      ,C.[VehicleYear]
      ,C.[VehicleMake]
      ,C.[VehicleMakeOther]
      ,C.[VehicleModel]
      ,C.[VehicleModelOther]
      ,C.[VehicleLicenseNumber]
      ,C.[VehicleLicenseState]
      ,C.[VehicleDescription]
      ,C.[VehicleColor]
      ,C.[VehicleLength]
      ,C.[VehicleHeight]
      ,C.[VehicleSource]
      ,C.[VehicleCategoryID] CaseVehicleCategoryID
      ,CVC.[Name] CaseVehicleCategoryName
      ,CVC.[Description] CaseVehicleCategoryDescription
      ,C.[VehicleTypeID]
      ,VT.[Name] VehicleTypeName
      ,C.[VehicleRVTypeID]
      ,RVT.[Name] VehicleRVTypeName
      ,C.[TrailerTypeID]
      ,TVT.[Name] TrailerTypeName
      ,C.[TrailerTypeOther]
      ,C.[TrailerSerialNumber]
      ,C.[TrailerNumberofAxles]
      ,C.[TrailerHitchTypeID]
      ,C.[TrailerHitchTypeOther]
      ,C.[TrailerBallSize]
      ,C.[TrailerBallSizeOther]
      ,C.[VehicleTireSize]
      ,C.[VehicleTireBrand]
      ,C.[VehicleTireBrandOther]
      ,C.[VehicleTransmission]
      ,C.[VehicleEngine]
      ,C.[VehicleGVWR]
      ,C.[VehicleChassis]
      ,C.[VehiclePurchaseDate]
      ,C.[VehicleWarrantyStartDate]
      ,C.[VehicleStartMileage]
      ,C.[VehicleEndMileage]
      ,C.[VehicleCurrentMileage]
      ,C.[VehicleMileageUOM]
      ,C.[VehicleIsFirstOwner]
      ,C.[VehicleIsSportUtilityRV]
      ,C.[ContactLastName]
      ,C.[ContactFirstName]
      ,C.[InboundPhoneNumber]
      ,C.[ANIPhoneTypeID]
      ,C.[ANIPhoneNumber]
      ,C.[ContactPhoneTypeID]
      ,C.[ContactPhoneNumber]
      ,C.[ContactAltPhoneTypeID]
      ,C.[ContactAltPhoneNumber]
      ,C.[IsSMSAvailable]
      ,C.[IsSafe]
      ,C.[LegacySystemID]
      ,C.[LegacySystemIDSequence]
      ,C.[CreateDate] CaseCreateDate
      ,C.[CreateBy] CaseCreateBy
      ,C.[ModifyDate] CaseModifyDate
      ,C.[ModifyBy] CaseModifyBy
      ,C.[IsDeliveryDriver] CaseIsDeliveryDriver
      ,C.[VehicleLicenseCountryID]
      ,C.[ContactEmail]
      ,C.[ReasonID]
      ,C.[VehicleWarrantyPeriod]
      ,C.[VehicleWarrantyPeriodUOM]
      ,C.[VehicleWarrantyMileage]
      ,C.[IsVehicleEligible]
      ,C.[VehicleWarrantyEndDate]
      ,M.[FirstName] MemberFirstName
      ,M.[LastName] MemberLastName
      ,M.[ClaimSubmissionNumber] MemberClaimSubmissionNumber
      ,M.[EffectiveDate] MemberEffectiveDate
      ,M.[ExpirationDate] MemberExpirationDate
      ,M.[Email] MemberEmail
      ,SR.[NextActionID]
      ,NA.[Name] NextActionName
      ,NA.[Description] NextActionDescription
      ,SR.[NextActionAssignedToUserID]
      ,U.[AgentNumber] NextActionAssignedToUserAgentNumber
      ,U.[FirstName] NextActionAssignedToUserFirstName
      ,U.[LastName] NextActionAssignedToUserLastName
      ,SR.[VehicleCategoryID]
      ,VC.[Name] VehicleCategoryName
      ,VC.[Description] VehicleCategoryDescription
      ,SR.[ServiceRequestPriorityID]
      ,SRP.[Name] ServiceRequestPriorityName
      ,SRP.[Description] ServiceRequestPriorityDescription
      ,SR.[ClosedLoopStatusID]
      ,CLS.[Name] ClosedLoopStatusName
      ,CLS.[Description] ClosedLoopStatusDescription
      ,SR.[ClosedLoopNextSend]
      ,SR.[IsPrimaryProductCovered]
      ,SR.[IsSecondaryProductCovered]
      ,SR.[MemberPaymentTypeID]
      ,PT.[Name] MemberPaymentTypeName
      ,SR.[PassengersRidingWithServiceProvider]
      ,SR.[IsEmergency]
      ,SR.[IsAccident]
      ,SR.[IsPossibleTow]
      ,SR.[ServiceLocationAddress]
      ,SR.[ServiceLocationDescription]
      ,SR.[ServiceLocationCrossStreet1]
      ,SR.[ServiceLocationCrossStreet2]
      ,SR.[ServiceLocationCity]
      ,SR.[ServiceLocationStateProvince]
      ,SR.[ServiceLocationPostalCode]
      ,SR.[ServiceLocationCountryCode]
      ,SR.[ServiceLocationLatitude]
      ,SR.[ServiceLocationLongitude]
      ,SR.[DestinationAddress]
      ,SR.[DestinationDescription]
      ,SR.[DestinationCrossStreet1]
      ,SR.[DestinationCrossStreet2]
      ,SR.[DestinationCity]
      ,SR.[DestinationStateProvince]
      ,SR.[DestinationPostalCode]
      ,SR.[DestinationCountryCode]
      ,SR.[DestinationLatitude]
      ,SR.[DestinationLongitude]
      ,SR.[DestinationVendorLocationID]
      ,SR.[ServiceMiles]
      ,SR.[ServiceTimeInMinutes]
      ,SR.[DealerIDNumber]
      ,SR.[IsDirectTowDealer]
      ,SR.[CallFee]
      ,SR.[IsRedispatched]
      ,SR.[IsDispatchThresholdReached]
      ,SR.[IsWorkedByTech]
      ,SR.[NextActionScheduledDate]
      ,SR.[LegacyReferenceNumber]
      ,SR.[ReadyForExportDate]
      ,SR.[DataTransferDate]
      , CASE 
			WHEN ISNULL(SR.[StartTabStatus],0)=0 THEN ''Not Visited''
			WHEN ISNULL(SR.[StartTabStatus],0)=1 THEN ''Visited With No Erros''
			ELSE ''Visited With Errors''
		  END  AS StartTabStatus
	   , CASE 
			WHEN ISNULL(SR.[MemberTabStatus],0)=0 THEN ''Not Visited''
			WHEN ISNULL(SR.[MemberTabStatus],0)=1 THEN ''Visited With No Erros''
			ELSE ''Visited With Errors''
		  END  AS MemberTabStatus
       , CASE 
			WHEN ISNULL(SR.[VehicleTabStatus],0)=0 THEN ''Not Visited''
			WHEN ISNULL(SR.[VehicleTabStatus],0)=1 THEN ''Visited With No Erros''
			ELSE ''Visited With Errors''
		  END  AS VehicleTabStatus
       , CASE 
			WHEN ISNULL(SR.[ServiceTabStatus],0)=0 THEN ''Not Visited''
			WHEN ISNULL(SR.[ServiceTabStatus],0)=1 THEN ''Visited With No Erros''
			ELSE ''Visited With Errors''
		  END  AS ServiceTabStatus
      , CASE 
			WHEN ISNULL(SR.[MapTabStatus],0)=0 THEN ''Not Visited''
			WHEN ISNULL(SR.[MapTabStatus],0)=1 THEN ''Visited With No Erros''
			ELSE ''Visited With Errors''
		  END  AS MapTabStatus
       , CASE 
			WHEN ISNULL(SR.[DispatchTabStatus],0)=0 THEN ''Not Visited''
			WHEN ISNULL(SR.[DispatchTabStatus],0)=1 THEN ''Visited With No Erros''
			ELSE ''Visited With Errors''
		  END  AS DispatchTabStatus
      , CASE 
			WHEN ISNULL(SR.[POTabStatus],0)=0 THEN ''Not Visited''
			WHEN ISNULL(SR.[POTabStatus],0)=1 THEN ''Visited With No Erros''
			ELSE ''Visited With Errors''
		  END  AS POTabStatus
      , CASE 
			WHEN ISNULL(SR.[PaymentTabStatus],0)=0 THEN ''Not Visited''
			WHEN ISNULL(SR.[PaymentTabStatus],0)=1 THEN ''Visited With No Erros''
			ELSE ''Visited With Errors''
		  END  AS PaymentTabStatus
     , CASE 
			WHEN ISNULL(SR.[ActivityTabStatus],0)=0 THEN ''Not Visited''
			WHEN ISNULL(SR.[ActivityTabStatus],0)=1 THEN ''Visited With No Erros''
			ELSE ''Visited With Errors''
		  END  AS ActivityTabStatus
     , CASE 
			WHEN ISNULL(SR.[FinishTabStatus],0)=0 THEN ''Not Visited''
			WHEN ISNULL(SR.[FinishTabStatus],0)=1 THEN ''Visited With No Erros''
			ELSE ''Visited With Errors''
		  END  AS FinishTabStatus
      ,SR.[CreateDate]
      ,SR.[CreateBy]
      ,SR.[ModifyDate]
      ,SR.[ModifyBy]
      ,SR.[AccountingInvoiceBatchID]
      ,SR.[StatusDateModified]
      ,SR.[PartsAndAccessoryCode]
      ,SR.[CurrencyTypeID]
      ,CT.[Name] CurrencyTypeName
      ,CT.[Abbreviation] CurrencyTypeAbbreviation
      ,SR.[PrimaryCoverageLimit]
      ,SR.[SecondaryCoverageLimit]
      ,SR.[MileageUOM]
      ,SR.[PrimaryCoverageLimitMileage]
      ,SR.[SecondaryCoverageLimitMileage]
      ,SR.[IsServiceGuaranteed]
      ,SR.[IsReimbursementOnly]
      ,SR.[IsServiceCoverageBestValue]
      ,SR.[ProgramServiceEventLimitID]
      ,SR.[PrimaryServiceCoverageDescription]
      ,SR.[SecondaryServiceCoverageDescription]
      ,SR.[PrimaryServiceEligiblityMessage]
      ,SR.[SecondaryServiceEligiblityMessage]
      ,SR.[IsPrimaryOverallCovered]
      ,SR.[IsSecondaryOverallCovered]
      ,SR.[ProviderClaimNumber]
  FROM [ServiceRequest] SR
  LEFT JOIN [ServiceRequestStatus] SRS (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID
  LEFT JOIN [ProductCategory] PC (NOLOCK) ON SR.ProductCategoryID = PC.ID
  LEFT JOIN [Product] PP (NOLOCK) ON SR.PrimaryProductID = PP.ID
  LEFT JOIN [Product] SP (NOLOCK) ON SR.SecondaryProductID = SP.ID
  LEFT JOIN [Case] C (NOLOCK) ON SR.CaseID = C.ID
  LEFT JOIN [Member] M (NOLOCK) ON C.MemberID = M.ID
  LEFT JOIN [NextAction] NA (NOLOCK) ON Sr.NextActionID = NA.ID
  LEFT JOIN [User] U (NOLOCK) ON SR.NextActionAssignedToUserID = U.ID
  LEFT JOIN [VehicleCategory] VC (NOLOCK) ON SR.VehicleCategoryID = VC.ID
  LEFT JOIN [ServiceRequestPriority] SRP ON SR.ServiceRequestPriorityID = SRP.ID
  LEFT JOIN [ClosedLoopStatus] CLS ON SR.ClosedLoopStatusID = CLS.ID
  LEFT JOIN [CurrencyType] CT ON SR.CurrencyTypeID = CT.ID
  LEFT JOIN [PaymentType] PT ON SR.MemberPaymentTypeID = PT.ID
  LEFT JOIN [Program] P (NOLOCK) ON C.ProgramID = P.ID
  LEFT JOIN [Client] CL (NOLOCK) ON P.ClientID = CL.ID
  LEFT JOIN [CaseStatus] CS (NOLOCK) ON C.CaseStatusID = CS.ID
  LEFT JOIN [User] CU (NOLOCK) ON C.AssignedToUserID = CU.ID
  LEFT JOIN [CallType] CAT (NOLOCK) ON C.CallTypeID = CAT.ID
  LEFT JOIN [VehicleCategory] CVC (NOLOCK) ON C.VehicleCategoryID = CVC.ID
  LEFT JOIN [VehicleType] VT (NOLOCK) ON C.VehicleTypeID = VT.ID
  LEFT JOIN [RVType] RVT (NOLOCK) ON C.VehicleRVTypeID = RVT.ID
  LEFT JOIN [TrailerType] TVT (NOLOCK) ON C.TrailerTypeID = TVT.ID
  

'
GO

GO
CREATE VIEW [dbo].[vw_VendorApplications]
AS
SELECT VA.[ID] VendorApplicationID
      ,VA.[VendorID]
	  , V.[VendorNumber]
      ,VA.[Name]
      ,VA.[CorporationName]
      ,VA.[VendorApplicationReferralSourceID]
	  ,VARS.[Description] VendorApplicationReferralSourceDescription
      ,VA.[Website]
      ,VA.[Email]
      ,VA.[ContactFirstName]
      ,VA.[ContactLastName]
      ,VA.[IsOpen24Hours]
      ,VA.[BusinessHours]
      ,VA.[DepartmentOfTransportationNumber]
      ,VA.[MotorCarrierNumber]
      ,VA.[IsEmployeeBackgroundChecked]
      ,VA.[IsEmployeeDrugTested]
      ,VA.[IsDriverUniformed]
      ,VA.[IsEachServiceTruckMarked]
      ,VA.[IsElectronicDispatch]
      ,VA.[IsFaxDispatch]
      ,VA.[IsEmailDispatch]
      ,VA.[IsTextDispatch]
      ,VA.[MaxTowingGVWR]
      ,VA.[TaxClassification]
      ,VA.[TaxClassificationOther]
      ,VA.[InsuranceCarrierName]
      ,VA.[ApplicationSignedByName]
      ,VA.[ApplicationSignedByTitle]
      ,VA.[ApplicationComments]
      ,VA.[CreateDate]
      ,VA.[CreateBy]
      ,VA.[ModifyDate]
      ,VA.[ModifyBy]
      ,VA.[TaxEIN]
      ,VA.[TaxSSN]
      ,VA.[W9SignedBy]
      ,VA.[TotalServiceVehicleCount]
      ,VA.[IsKeyDropAvailable]
      ,VA.[IsOvernightStayAllowed]
      ,VA.[InsuranceCertificateFileName]
  FROM [dbo].[VendorApplication] VA WITH (NOLOCK)
  LEFT JOIN [dbo].[Vendor] V WITH (NOLOCK) ON VA.VendorID = V.ID
  LEFT JOIN [dbo].[VendorApplicationReferralSource] VARS ON VA.VendorApplicationReferralSourceID = VARS.ID




GO
CREATE VIEW [dbo].[vw_VendorInvoices]
AS
SELECT VI.[ID] VendorInvoiceID
      ,VI.[PurchaseOrderID]
	  ,PO.PurchaseOrderNumber
      ,VI.[VendorID]
	  ,V.VendorNumber
      ,VI.[VendorInvoiceStatusID]
	  ,VIS.Description VendorInvoiceStatusDescription
      ,VI.[SourceSystemID]
	  ,SS.Description SourceSystemDescription
      ,VI.[InvoiceNumber]
      ,VI.[ReceivedDate]
      ,VI.[ReceiveContactMethodID]
	  ,CM.Description ContactMethodDescription
      ,VI.[InvoiceDate]
      ,VI.[InvoiceAmount]
      ,VI.[BillingBusinessName]
      ,VI.[BillingContactName]
      ,VI.[BillingAddressLine1]
      ,VI.[BillingAddressLine2]
      ,VI.[BillingAddressLine3]
      ,VI.[BillingAddressCity]
      ,VI.[BillingAddressStateProvince]
      ,VI.[BillingAddressPostalCode]
      ,VI.[BillingAddressCountryCode]
      ,VI.[ToBePaidDate]
      ,VI.[ExportDate]
      ,VI.[ExportBatchID]
      ,VI.[PaymentTypeID]
	  ,PT.Description PaymentTypeDescription
      ,VI.[PaymentDate]
      ,VI.[PaymentAmount]
      ,VI.[PaymentNumber]
      ,VI.[CheckClearedDate]
      ,VI.[ActualETAMinutes]
      ,VI.[Last8OfVIN]
      ,VI.[VehicleMileage]
      ,VI.[IsActive]
      ,VI.[CreateDate]
      ,VI.[CreateBy]
      ,VI.[ModifyDate]
      ,VI.[ModifyBy]
      ,VI.[AccountingInvoiceBatchID]
      ,VI.[VendorInvoicePaymentDifferenceReasonCodeID]
	  ,VIPDRC.Description VendorInvoicePaymentDifferenceReasonCodeDescription
      ,VI.[GLExpenseAccount]
 FROM [dbo].[VendorInvoice] VI WITH(NOLOCK)
 LEFT JOIN PurchaseOrder PO WITH(NOLOCK) ON VI.PurchaseOrderID = PO.ID
 LEFT JOIN Vendor V WITH(NOLOCK) ON VI.VendorID = V.ID	
 LEFT JOIN VendorInvoiceStatus VIS WITH(NOLOCK) ON VI.VendorInvoiceStatusID = VIS.ID
 LEFT JOIN SourceSystem SS WITH(NOLOCK) ON VI.SourceSystemID = SS.ID
 LEFT JOIN ContactMethod CM WITH(NOLOCK) ON VI.ReceiveContactMethodID = CM.ID
 LEFT JOIN PaymentType PT WITH(NOLOCK) ON VI.PaymentTypeID = PT.ID
 LEFT JOIN VendorInvoicePaymentDifferenceReasonCode VIPDRC  WITH(NOLOCK) ON VI.VendorInvoicePaymentDifferenceReasonCodeID = VIPDRC.ID




GO
CREATE VIEW [dbo].[vw_VendorLocations]
AS
SELECT VL.ID VendorLocationID,
	   VL.VendorID,
	   V.VendorNumber,
	   V.Name,
	   VL.Sequence,
	   VL.Latitude,
	   VL.Longitude,
	   VL.GeographyLocation,
	   VL.Email,
	   VL.BusinessHours,
	   VL.DealerNumber,
	   VL.IsOpen24Hours,
	   VL.IsActive,
	   VL.CreateDate,
	   VL.CreateBy,
	   VL.ModifyDate,
	   VL.ModifyBy,
	   VL.IsKeyDropAvailable,
	   VL.IsOvernightStayAllowed,
	   VL.IsDirectTow,
	   Vl.PartsAndAccessoryCode,
	   VL.VendorLocationStatusID,
	   VLS.Description VendorLocationStatusDescription,
	   VL.DispatchNote,
	   VL.IsElectronicDispatchAvailable,
	   VL.IsOvernightStorageAvailable,
	   VL.IsUsingZipCodes,
	   VL.IsAbleToCrossStateLines,
	   VL.IsAbleToCrossNationalBorders,
	   VL.DispatchEmail

	  ,AEBusiness.Line1 AS BusinessLine1
	  ,AEBusiness.Line2 AS BusinessLine2
	  ,AEBusiness.City AS BusinessCity
	  ,AEBusiness.StateProvinceID AS BusinessStateProvinceID
	  ,AEBusiness.StateProvince AS BusinessStateProvince
	  ,AEBusiness.PostalCode AS BusinessPostalCode
	  ,AEBusiness.CountryID AS BusinessCountryID
	  ,AEBusiness.CountryCode AS BusinessCountryCode

	  ,AEBilling.Line1 AS BillingLine1
	  ,AEBilling.Line2 AS BillingLine2
	  ,AEBilling.City AS BillingCity
	  ,AEBilling.StateProvinceID AS BillingStateProvinceID
	  ,AEBilling.StateProvince AS BillingStateProvince
	  ,AEBilling.PostalCode AS BillingPostalCode
	  ,AEBilling.CountryID AS BillingCountryID
	  ,AEBilling.CountryCode AS BillingCountryCode

	  ,AEOther.Line1 AS OtherLine1
	  ,AEOther.Line2 AS OtherLine2
	  ,AEOther.City AS OtherCity
	  ,AEOther.StateProvinceID AS OtherStateProvinceID
	  ,AEOther.StateProvince AS   OtherStateProvince
	  ,AEOther.PostalCode AS      OtherPostalCode
	  ,AEOther.CountryID AS       OtherCountryID
	  ,AEOther.CountryCode AS     OtherCountryCode

	  ,PECell.PhoneNumber AS CellPhone
	  ,PEFax.PhoneNumber AS FaxPhone
	  ,PEDispatch.PhoneNumber AS DispatchPhone
	  ,PEOffice.PhoneNumber AS OfficePhone
	  ,PEOther.PhoneNumber AS OtherPhone
	  ,PEAlternateDispatch.PhoneNumber AS AlternateDispatchPhone

FROM VendorLocation VL
LEFT JOIN  VendorLocationStatus VLS ON VL.VendorLocationStatusID = VLS.ID
LEFT JOIN Vendor V ON VL.VendorID = V.ID

LEFT JOIN	AddressEntity AEBusiness (NOLOCK) ON AEBusiness.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND AEBusiness.RecordID = VL.ID  AND AEBusiness.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Business')
LEFT JOIN	AddressEntity AEBilling (NOLOCK) ON AEBilling.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND AEBilling.RecordID = VL.ID  AND AEBilling.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Billing')
LEFT JOIN	AddressEntity AEOther (NOLOCK) ON AEOther.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND AEOther.RecordID = VL.ID  AND AEOther.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Other')

LEFT JOIN	PhoneEntity PECell (NOLOCK) ON PECell.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND PECell.RecordID = VL.ID 	AND PECell.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Cell')
LEFT JOIN	PhoneEntity PEFax (NOLOCK) ON PEFax.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND PEFax.RecordID = VL.ID 	AND PEFax.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Fax')
LEFT JOIN	PhoneEntity PEDispatch (NOLOCK) ON PEDispatch.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND PEDispatch.RecordID = VL.ID 	AND PEDispatch.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Dispatch')
LEFT JOIN	PhoneEntity PEOffice (NOLOCK) ON PEOffice.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND PEOffice.RecordID = VL.ID 	AND PEOffice.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Office')
LEFT JOIN	PhoneEntity PEOther (NOLOCK) ON PEOther.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND PEOther.RecordID = VL.ID 	AND PEOther.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Other')
LEFT JOIN	PhoneEntity PEAlternateDispatch (NOLOCK) ON PEAlternateDispatch.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND PEAlternateDispatch.RecordID = VL.ID 	AND PEAlternateDispatch.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'AlternateDispatch')








GO
