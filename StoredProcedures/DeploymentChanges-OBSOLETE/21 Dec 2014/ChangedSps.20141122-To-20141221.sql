IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Call_Summary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Call_Summary]
GO

--EXEC dms_Call_Summary @serviceRequestID = 1467
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
 UPDATE @Hold SET DataType = 'LabelTheme' WHERE CHARINDEX('Member_Status',ColumnName) > 0 OR CHARINDEX('Vehicle_IsEligible',ColumnName) > 0  
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
	AreaName NVARCHAR(50) NULL,
	TeamManager NVARCHAR(50) NULL,
	AgentName NVARCHAR(50) NULL)

INSERT INTO @Filters
SELECT  
	ISNULL(T.c.value('@AreaName','NVARCHAR(50)'),NULL),
	ISNULL(T.c.value('@TeamManager','NVARCHAR(50)'),NULL),
	ISNULL(T.c.value('@AgentName','NVARCHAR(50)'),NULL)
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
WHERE ((FL.AgentName IS NULL) OR (FL.AgentName IS NOT NULL AND CC.AgentUserName = FL.AgentName))

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
 WHERE id = object_id(N'[dbo].[dms_CurrentUser_For_Event_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_CurrentUser_For_Event_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_CurrentUser_For_Event_Get] 72237,4
CREATE PROCEDURE [dbo].[dms_CurrentUser_For_Event_Get](
	@eventLogID INT,
	@eventSubscriptionID INT
)
AS
BEGIN
 
	/*
		Assumption : This stored procedure would be executed for DesktopNotifications.
		Logic : 
		If the event is SendPOFaxFailure - Determine the current user as follows:
			1.	Parse EL.Data and pull out <ServiceRequest><SR.ID>  </ServiceRequest>
			2.	Join to Case from that SR.ID and get Case.AssignedToUserID
			3.	Insert one CommunicatinQueue record
			4.	If this value is blank try next one
			iv.	If no current user assigned
			1.	Parse EL.Data and pull out <CreateByUser><username></CreateByUser>
			2.	Check to see if that <username> is online
			3.	If online then Insert one CommunicatinQueue record for that user
			v.	If still no user found or online, then check the Service Request and if the NextAction fields are blank.  If blank then:
			1.	Update the associated ServiceRequest next action fields.  These will be displayed on the Queue prompting someone to take action and re-send the PO
			a.	Set ServiceRequest.NextActionID = Re-send PO
			b.	Set ServiceRequest.NextActionAssignedToUserID = ‘Agent User’

		If the event is ManualNotification, determine the curren user(s) as follows: 
			1. Get the associated EventLogLinkRecords.
			2. For each of the link records:
				2.1 If the related entity on the link record is a user and the user is online, add the user details to the list.
				
		If the event is not SendPOFaxFailure - CurrentUser = ServiceRequest.Case.AssignedToUserID.
	*/

	DECLARE @eventName NVARCHAR(255),
			@eventData XML,
			@PONumber NVARCHAR(100),
			@ServiceRequest INT,
			@FaxFailureReason NVARCHAR(MAX),
			@CreateByUser NVARCHAR(50),

			@assignedToUserIDOnCase INT,
			@nextActionIDOnSR INT,
			@nextActionAssignedToOnSR INT,
			@resendPONextActionID INT,
			@agentUserID INT,
			@nextActionPriorityID INT = NULL,
			@defaultScheduleDateInterval INT = NULL,
			@defaultScheduleDateIntervalUOM NVARCHAR(50) = NULL

	DECLARE @tmpCurrentUser TABLE
			(
				UserId UNIQUEIDENTIFIER NULL,
				UserName NVARCHAR(100) NULL
			)
	

	SELECT  @resendPONextActionID = ID FROM NextAction WITH (NOLOCK) WHERE Name = 'ResendPO'
	SELECT	@nextActionPriorityID = DefaultPriorityID FROM NextAction WITH (NOLOCK) WHERE Name = 'ResendPO'

	IF (@nextActionPriorityID IS NULL)
	BEGIN
		SELECT @nextActionPriorityID = (SELECT ID FROM ServiceRequestPriority WITH (NOLOCK) WHERE Name = 'Normal')
	END


	SELECT	@defaultScheduleDateInterval	= ISNULL(DefaultScheduleDateInterval,0),
			@defaultScheduleDateIntervalUOM = DefaultScheduleDateIntervalUOM
	FROM	NextAction WITH (NOLOCK)
	WHERE	ID = @resendPONextActionID


	--SELECT	@agentUserID = U.ID
	--FROM	[User] U WITH (NOLOCK) 
	--JOIN	aspnet_Users AU WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
	--JOIN	aspnet_Applications A WITH (NOLOCK) ON A.ApplicationId = AU.ApplicationId
	--WHERE	AU.UserName = 'Agent'
	--AND		A.ApplicationName = 'DMS'

	SELECT	@eventData = EL.Data
	FROM	EventLog EL WITH (NOLOCK)
	JOIN	Event E WITH (NOLOCK) ON EL.EventID = E.ID
	WHERE	EL.ID = @eventLogID

	SELECT	@eventName = E.Name
	FROM	EventSubscription ES WITH (NOLOCK) 
	JOIN	Event E WITH (NOLOCK) ON ES.EventID = E.ID
	WHERE	ES.ID = @eventSubscriptionID	
	
	

	SELECT	@PONumber = (SELECT  T.c.value('.','NVARCHAR(100)') FROM @eventData.nodes('/MessageData/PONumber') T(c)),
		@ServiceRequest = (SELECT  T.c.value('.','INT') FROM @eventData.nodes('/MessageData/ServiceRequest') T(c)),
		@FaxFailureReason = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventData.nodes('/MessageData/FaxFailureReason') T(c)),
		@CreateByUser = (SELECT  T.c.value('.','NVARCHAR(50)') FROM @eventData.nodes('/MessageData/CreateByUser') T(c))
		
	SELECT	@assignedToUserIDOnCase = C.AssignedToUserID
	FROM	[Case] C WITH (NOLOCK)
	JOIN	[ServiceRequest] SR WITH (NOLOCK) ON SR.CaseID = C.ID
	WHERE	SR.ID = @ServiceRequest

	IF (@eventName = 'SendPOFaxFailed')
	BEGIN	
				
		IF (@assignedToUserIDOnCase IS NOT NULL)
		BEGIN
			PRINT 'AssignedToUserID On Case is not null'
			-- Return the user details.
			INSERT INTO @tmpCurrentUser ( UserId, UserName)
			SELECT	AU.UserId,
					AU.UserName
			FROM	aspnet_Users AU WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
			WHERE	U.ID = @assignedToUserIDOnCase

		END
		ELSE 
		BEGIN
			-- TFS: 390
			--IF ( (SELECT [dbo].[fnIsUserConnected](@CreateByUser) ) = 1)
			--BEGIN
				
			--	INSERT INTO @tmpCurrentUser
			--	SELECT	AU.UserId,
			--			AU.UserName
			--	FROM	aspnet_Users AU WITH (NOLOCK) 
			--	JOIN	aspnet_Applications A WITH (NOLOCK) ON AU.ApplicationId = A.ApplicationId			
			--	WHERE	AU.UserName = @CreateByUser
			--	AND		A.ApplicationName = 'DMS'
				
			--END
			--ELSE
			--BEGIN
			PRINT 'AssignedToUserID On Case is null'
				SELECT	@nextActionIDOnSR = SR.NextActionID,
						@nextActionAssignedToOnSR = SR.NextActionAssignedToUserID
				FROM	ServiceRequest SR WITH (NOLOCK) 
				WHERE ID = @ServiceRequest 

				--IF @nextActionAssignedToOnSR IS NULL AND @nextActionIDOnSR IS NULL
				BEGIN
					PRINT 'Setting service request attributes'
					UPDATE	ServiceRequest
					SET		NextActionID = @resendPONextActionID,
							--TFS : 390
							NextActionAssignedToUserID = (SELECT DefaultAssignedToUserID FROM NextAction 
															WHERE ID = @resendPONextActionID 
														 ),
							ServiceRequestPriorityID = @nextActionPriorityID,
							NextActionScheduledDate =  CASE WHEN @defaultScheduleDateIntervalUOM = 'days'
																THEN DATEADD(dd,@defaultScheduleDateInterval,GETDATE())
															WHEN @defaultScheduleDateIntervalUOM = 'hours'
																THEN DATEADD(hh,@defaultScheduleDateInterval,GETDATE())
															WHEN @defaultScheduleDateIntervalUOM = 'minutes'
																THEN DATEADD(mi,@defaultScheduleDateInterval,GETDATE())
															WHEN @defaultScheduleDateIntervalUOM = 'seconds'
																THEN DATEADD(ss,@defaultScheduleDateInterval,GETDATE())
															ELSE NULL
															END
														
					WHERE	ID = @ServiceRequest

					; WITH wManagers
					AS
					(
						SELECT	DISTINCT AU.UserId,
								AU.UserName,
								[dbo].[fnIsUserConnected](AU.UserName) AS IsConnected
						FROM	aspnet_Users AU WITH (NOLOCK) 
						JOIN	aspnet_Applications A WITH (NOLOCK) ON AU.ApplicationId = A.ApplicationId
						JOIN	aspnet_Membership M WITH (NOLOCK) ON M.ApplicationId = A.ApplicationId AND ISNULL(M.IsApproved,0) = 1 AND ISNULL(M.IsLockedOut,0) = 0 AND M.UserID = AU.UserID
						JOIN	aspnet_UsersInRoles UR WITH (NOLOCK) ON UR.UserId = AU.UserId
						JOIN	aspnet_Roles R WITH (NOLOCK) ON UR.RoleId = R.RoleId AND R.ApplicationId = A.ApplicationId
						WHERE	A.ApplicationName = 'DMS'
						AND		R.RoleName = 'Manager'					
					)
					INSERT INTO @tmpCurrentUser (UserId, UserName)
					SELECT  W.UserId,
							W.UserName							
					FROM	wManagers W
					WHERE	ISNULL(W.IsConnected,0) = 1
			
				END				
		END	
	END
	
	ELSE IF (@eventName = 'ManualNotification' OR @eventName = 'LockedRequestComment')
	BEGIN
		
		DECLARE @userEntityID INT

		SET @userEntityID = (SELECT ID FROM Entity WHERE Name = 'User')
		;WITH wUsersFromEventLogLinks
		AS
		(
			SELECT	AU.UserId,
					AU.UserName,
					[dbo].[fnIsUserConnected](AU.UserName) IsConnected				
			FROM	EventLogLink ELL WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON ELL.RecordID = U.ID AND ELL.EntityID = @userEntityID
			JOIN	aspnet_Users AU WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
			WHERE	ELL.EventLogID = @eventLogID
		)

		INSERT INTO @tmpCurrentUser (UserId, UserName)
		SELECT	W.UserId, W.UserName
		FROM	wUsersFromEventLogLinks W
		WHERE	ISNULL(W.IsConnected,0) = 1


	END	
	ELSE
	BEGIN
		
		IF (@assignedToUserIDOnCase IS NOT NULL)
		BEGIN

			INSERT INTO @tmpCurrentUser ( UserId, UserName)
			SELECT	AU.UserId,
					AU.Username
			FROM	aspnet_Users AU WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON AU.UserId = U.aspnet_UserID
			JOIN	[aspnet_Applications] A WITH (NOLOCK) ON A.ApplicationId = AU.ApplicationId
			WHERE	A.ApplicationName = 'DMS'
			AND		U.ID = @assignedToUserIDOnCase

		END
			
	END	

	

	SELECT UserId, Username from @tmpCurrentUser

END

GO


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
 WHERE id = object_id(N'[dbo].[dms_EventLogList]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_EventLogList] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_EventLogList]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC') 
 AS 
 BEGIN 
  
SET NOCOUNT ON

DECLARE @Filters AS TABLE(
	UserName NVARCHAR(50) NULL,
	FromDate DATE NULL,
	ToDate DATE NULL,
	EventCategoryID INT NULL,
	EventTypeID INT NULL,
	EventID INT NULL)

INSERT INTO @Filters
SELECT  
	ISNULL(T.c.value('@UserName','NVARCHAR(50)'),NULL),
	ISNULL(T.c.value('@FromDate','DATE'),NULL),
	ISNULL(T.c.value('@ToDate','DATE'),NULL),
	ISNULL(T.c.value('@EventCategoryID','INT'),NULL),
	ISNULL(T.c.value('@EventTypeID','INT'),NULL),
	ISNULL(T.c.value('@EventID','INT'),NULL)
FROM  @whereClauseXML.nodes('/ROW/Filter') T(c)


DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	EventLogID int  NULL ,
	SessionID nvarchar(100)  NULL ,
	Description nvarchar(MAX)  NULL ,
	Data nvarchar(MAX)  NULL ,
	CreateDate datetime  NULL ,
	CreateBy nvarchar(50)  NULL 
) 

DECLARE @QueryResult TABLE ( 
	EventLogID int  NULL ,
	SessionID nvarchar(100)  NULL ,
	Description nvarchar(MAX)  NULL ,
	Data nvarchar(MAX)  NULL ,
	CreateDate datetime  NULL ,
	CreateBy nvarchar(50)  NULL 
) 

INSERT INTO @QueryResult
SELECT	      el.ID
			, el.SessionID
			, el.Description
			, el.Data
			, el.CreateDate
			, el.CreateBy
FROM	    EventLog el WITH (NOLOCK)
JOIN	    Event e  WITH (NOLOCK) ON e.ID = el.EventID,@Filters FL
WHERE       ((FL.UserName IS NULL) OR (FL.UserName IS NOT NULL AND el.CreateBy = FL.UserName))
AND			((FL.EventCategoryID IS NULL) OR (FL.EventCategoryID IS NOT NULL AND e.EventCategoryID = FL.EventCategoryID))
AND			((FL.EventTypeID IS NULL) OR (FL.EventTypeID IS NOT NULL AND e.EventTypeID = FL.EventTypeID))
AND			((FL.EventID IS NULL) OR (FL.EventID IS NOT NULL AND e.ID = FL.EventID))
AND			((FL.FromDate IS NULL) OR (FL.FromDate IS NOT NULL AND el.CreateDate >= FL.FromDate))
AND			((FL.ToDate IS NULL) OR (FL.ToDate IS NOT NULL AND el.CreateDate <= FL.ToDate))


--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults
SELECT 
	T.EventLogID,
	T.SessionID,
	T.Description,
	T.Data,
	T.CreateDate,
	T.CreateBy
FROM @QueryResult T
WHERE ( 1 = 1 )
	 
	 ORDER BY 
	 CASE WHEN @sortColumn = 'EventLogID' AND @sortOrder = 'ASC'
	 THEN T.EventLogID END ASC, 
	 CASE WHEN @sortColumn = 'EventLogID' AND @sortOrder = 'DESC'
	 THEN T.EventLogID END DESC ,

	 CASE WHEN @sortColumn = 'SessionID' AND @sortOrder = 'ASC'
	 THEN T.SessionID END ASC, 
	 CASE WHEN @sortColumn = 'SessionID' AND @sortOrder = 'DESC'
	 THEN T.SessionID END DESC ,

	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'ASC'
	 THEN T.Description END ASC, 
	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'DESC'
	 THEN T.Description END DESC ,

	 CASE WHEN @sortColumn = 'Data' AND @sortOrder = 'ASC'
	 THEN T.Data END ASC, 
	 CASE WHEN @sortColumn = 'Data' AND @sortOrder = 'DESC'
	 THEN T.Data END DESC ,

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
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
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
SELECT	  P.Description AS Product
			, MP.StartDate AS StartDate
			, MP.EndDate AS EndDate
			, CASE WHEN MP.EndDate < GETDATE() THEN 'Inactive' ELSE 'Active' END AS Status
			, PP.Description AS Provider
			, PP.PhoneNumber AS PhoneNumber
			, MP.ContractNumber
			, MP.VIN
	FROM		MemberProduct MP (NOLOCK)
	LEFT JOIN	Product P (NOLOCK) ON P.ID = MP.ProductID
	LEFT JOIN	ProductProvider PP (NOLOCK) ON PP.ID = MP.ProductProviderID
	WHERE		MP.MemberID = @MemberID 
	ORDER BY	P.Description


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
CREATE PROC dms_Member_Products_Using_Category(@memberID INT = NULL,@productCategoryID INT = NULL)
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
JOIN	Product p (NOLOCK) ON p.ID = mp.ProductID
JOIN	ProductProvider pp (NOLOCK) ON pp.ID = mp.ProductProviderID
JOIN	MemberProductProductCategory mppc (NOLOCK) ON mppc.ProductID = p.ID AND mppc.ProductCategoryID = @productCategoryID 
WHERE	mp.MemberID = @memberID 
ORDER BY p.Description
END
GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Member_Product_Provider_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_Product_Provider_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC [dms_Member_Product_Provider_List_Get] 898
 CREATE PROCEDURE [dbo].[dms_Member_Product_Provider_List_Get](
 @memberId INT = NULL)
 AS 
 BEGIN 	
	SELECT 
		PP.*
	FROM 
		ProductProvider PP
		LEFT JOIN MemberProduct MP WITH(NOLOCK) ON MP.ProductProviderID = PP.ID	
	WHERE MP.MemberID = @memberId	
	
 END
 
 
	

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Message_Get]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Message_Get] 
END 

GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_Message_Get](@messageScope NVARCHAR(100))
AS
BEGIN
	SELECT * FROM [Message]
	WHERE MessageScope = @messageScope
	AND   IsActive = 1
	ORDER BY
	[StartDate] DESC,
	[Sequence] ASC
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
 WHERE id = object_id(N'[dbo].[dms_Message_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Message_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Message_List]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
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
MessageIDOperator="-1" 
MessageScopeOperator="-1" 
MessageTypeOperator="-1" 
SubjectOperator="-1" 
MessageTextOperator="-1" 
StartDateOperator="-1" 
EndDateOperator="-1" 
SequenceOperator="-1" 
IsActiveOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
MessageIDOperator INT NOT NULL,
MessageIDValue int NULL,
MessageScopeOperator INT NOT NULL,
MessageScopeValue nvarchar(50) NULL,
MessageTypeOperator INT NOT NULL,
MessageTypeValue nvarchar(50) NULL,
SubjectOperator INT NOT NULL,
SubjectValue nvarchar(50) NULL,
MessageTextOperator INT NOT NULL,
MessageTextValue nvarchar(50) NULL,
StartDateOperator INT NOT NULL,
StartDateValue datetime NULL,
EndDateOperator INT NOT NULL,
EndDateValue datetime NULL,
SequenceOperator INT NOT NULL,
SequenceValue int NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue BIT NULL
)
DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	MessageID int  NULL ,
	MessageScope nvarchar(50)  NULL ,
	MessageType nvarchar(50)  NULL ,
	Subject nvarchar(255)  NULL ,
	MessageText nvarchar(MAX)  NULL ,
	StartDate datetime  NULL ,
	EndDate datetime  NULL ,
	Sequence int  NULL ,
	IsActive BIT  NULL 
) 

DECLARE @QueryResult TABLE ( 
	MessageID int  NULL ,
	MessageScope nvarchar(50)  NULL ,
	MessageType nvarchar(50)  NULL ,
	Subject nvarchar(255)  NULL ,
	MessageText nvarchar(MAX)  NULL ,
	StartDate datetime  NULL ,
	EndDate datetime  NULL ,
	Sequence int  NULL ,
	IsActive BIT  NULL 
) 

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(MessageIDOperator,-1),
	MessageIDValue ,
	ISNULL(MessageScopeOperator,-1),
	MessageScopeValue ,
	ISNULL(MessageTypeOperator,-1),
	MessageTypeValue ,
	ISNULL(SubjectOperator,-1),
	SubjectValue ,
	ISNULL(MessageTextOperator,-1),
	MessageTextValue ,
	ISNULL(StartDateOperator,-1),
	StartDateValue ,
	ISNULL(EndDateOperator,-1),
	EndDateValue ,
	ISNULL(SequenceOperator,-1),
	SequenceValue ,
	ISNULL(IsActiveOperator,-1),
	IsActiveValue 
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
MessageIDOperator INT,
MessageIDValue int 
,MessageScopeOperator INT,
MessageScopeValue nvarchar(50) 
,MessageTypeOperator INT,
MessageTypeValue nvarchar(50) 
,SubjectOperator INT,
SubjectValue nvarchar(50) 
,MessageTextOperator INT,
MessageTextValue nvarchar(50) 
,StartDateOperator INT,
StartDateValue datetime 
,EndDateOperator INT,
EndDateValue datetime 
,SequenceOperator INT,
SequenceValue int ,
IsActiveOperator INT,
IsActiveValue BIT
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @QueryResult
SELECT	  m.ID 
		, m.MessageScope	
		, mt.Name AS MessageType
		, m.Subject
		, m.MessageText
		, m.StartDate 
		, m.EndDate
		, m.Sequence
		, m.IsActive
FROM	Message m
JOIN	MessageType mt ON mt.ID = m.MessageTypeID
ORDER BY  m.ID DESC

INSERT INTO @FinalResults
SELECT 
	T.MessageID,
	T.MessageScope,
	T.MessageType,
	CASE WHEN LEN(T.Subject) > 50 THEN SUBSTRING(T.Subject,1,50) + '...' ELSE T.Subject END,
	CASE WHEN LEN(T.MessageText) > 50 THEN SUBSTRING(T.MessageText,1,50) + '...' ELSE T.MessageText END,
	T.StartDate,
	T.EndDate,
	T.Sequence,
	T.IsActive
FROM @QueryResult T,
@tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.MessageIDOperator = -1 ) 
 OR 
	 ( TMP.MessageIDOperator = 0 AND T.MessageID IS NULL ) 
 OR 
	 ( TMP.MessageIDOperator = 1 AND T.MessageID IS NOT NULL ) 
 OR 
	 ( TMP.MessageIDOperator = 2 AND T.MessageID = TMP.MessageIDValue ) 
 OR 
	 ( TMP.MessageIDOperator = 3 AND T.MessageID <> TMP.MessageIDValue ) 
 OR 
	 ( TMP.MessageIDOperator = 7 AND T.MessageID > TMP.MessageIDValue ) 
 OR 
	 ( TMP.MessageIDOperator = 8 AND T.MessageID >= TMP.MessageIDValue ) 
 OR 
	 ( TMP.MessageIDOperator = 9 AND T.MessageID < TMP.MessageIDValue ) 
 OR 
	 ( TMP.MessageIDOperator = 10 AND T.MessageID <= TMP.MessageIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.MessageScopeOperator = -1 ) 
 OR 
	 ( TMP.MessageScopeOperator = 0 AND T.MessageScope IS NULL ) 
 OR 
	 ( TMP.MessageScopeOperator = 1 AND T.MessageScope IS NOT NULL ) 
 OR 
	 ( TMP.MessageScopeOperator = 2 AND T.MessageScope = TMP.MessageScopeValue ) 
 OR 
	 ( TMP.MessageScopeOperator = 3 AND T.MessageScope <> TMP.MessageScopeValue ) 
 OR 
	 ( TMP.MessageScopeOperator = 4 AND T.MessageScope LIKE TMP.MessageScopeValue + '%') 
 OR 
	 ( TMP.MessageScopeOperator = 5 AND T.MessageScope LIKE '%' + TMP.MessageScopeValue ) 
 OR 
	 ( TMP.MessageScopeOperator = 6 AND T.MessageScope LIKE '%' + TMP.MessageScopeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.MessageTypeOperator = -1 ) 
 OR 
	 ( TMP.MessageTypeOperator = 0 AND T.MessageType IS NULL ) 
 OR 
	 ( TMP.MessageTypeOperator = 1 AND T.MessageType IS NOT NULL ) 
 OR 
	 ( TMP.MessageTypeOperator = 2 AND T.MessageType = TMP.MessageTypeValue ) 
 OR 
	 ( TMP.MessageTypeOperator = 3 AND T.MessageType <> TMP.MessageTypeValue ) 
 OR 
	 ( TMP.MessageTypeOperator = 4 AND T.MessageType LIKE TMP.MessageTypeValue + '%') 
 OR 
	 ( TMP.MessageTypeOperator = 5 AND T.MessageType LIKE '%' + TMP.MessageTypeValue ) 
 OR 
	 ( TMP.MessageTypeOperator = 6 AND T.MessageType LIKE '%' + TMP.MessageTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.SubjectOperator = -1 ) 
 OR 
	 ( TMP.SubjectOperator = 0 AND T.Subject IS NULL ) 
 OR 
	 ( TMP.SubjectOperator = 1 AND T.Subject IS NOT NULL ) 
 OR 
	 ( TMP.SubjectOperator = 2 AND T.Subject = TMP.SubjectValue ) 
 OR 
	 ( TMP.SubjectOperator = 3 AND T.Subject <> TMP.SubjectValue ) 
 OR 
	 ( TMP.SubjectOperator = 4 AND T.Subject LIKE TMP.SubjectValue + '%') 
 OR 
	 ( TMP.SubjectOperator = 5 AND T.Subject LIKE '%' + TMP.SubjectValue ) 
 OR 
	 ( TMP.SubjectOperator = 6 AND T.Subject LIKE '%' + TMP.SubjectValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.MessageTextOperator = -1 ) 
 OR 
	 ( TMP.MessageTextOperator = 0 AND T.MessageText IS NULL ) 
 OR 
	 ( TMP.MessageTextOperator = 1 AND T.MessageText IS NOT NULL ) 
 OR 
	 ( TMP.MessageTextOperator = 2 AND T.MessageText = TMP.MessageTextValue ) 
 OR 
	 ( TMP.MessageTextOperator = 3 AND T.MessageText <> TMP.MessageTextValue ) 
 OR 
	 ( TMP.MessageTextOperator = 4 AND T.MessageText LIKE TMP.MessageTextValue + '%') 
 OR 
	 ( TMP.MessageTextOperator = 5 AND T.MessageText LIKE '%' + TMP.MessageTextValue ) 
 OR 
	 ( TMP.MessageTextOperator = 6 AND T.MessageText LIKE '%' + TMP.MessageTextValue + '%' ) 
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
	 ( TMP.IsActiveOperator = -1 ) 
 OR 
	 ( TMP.IsActiveOperator = 0 AND T.IsActive IS NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 1 AND T.IsActive IS NOT NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 2 AND T.IsActive = TMP.IsActiveValue	 ) 
 OR 
	 ( TMP.IsActiveOperator = 3 AND T.IsActive <> TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 7 AND T.IsActive > TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 8 AND T.IsActive >= TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 9 AND T.IsActive < TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 10 AND T.IsActive <= TMP.IsActiveValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'MessageID' AND @sortOrder = 'ASC'
	 THEN T.MessageID END ASC, 
	 CASE WHEN @sortColumn = 'MessageID' AND @sortOrder = 'DESC'
	 THEN T.MessageID END DESC ,

	 CASE WHEN @sortColumn = 'MessageScope' AND @sortOrder = 'ASC'
	 THEN T.MessageScope END ASC, 
	 CASE WHEN @sortColumn = 'MessageScope' AND @sortOrder = 'DESC'
	 THEN T.MessageScope END DESC ,

	 CASE WHEN @sortColumn = 'MessageType' AND @sortOrder = 'ASC'
	 THEN T.MessageType END ASC, 
	 CASE WHEN @sortColumn = 'MessageType' AND @sortOrder = 'DESC'
	 THEN T.MessageType END DESC ,

	 CASE WHEN @sortColumn = 'Subject' AND @sortOrder = 'ASC'
	 THEN T.Subject END ASC, 
	 CASE WHEN @sortColumn = 'Subject' AND @sortOrder = 'DESC'
	 THEN T.Subject END DESC ,

	 CASE WHEN @sortColumn = 'MessageText' AND @sortOrder = 'ASC'
	 THEN T.MessageText END ASC, 
	 CASE WHEN @sortColumn = 'MessageText' AND @sortOrder = 'DESC'
	 THEN T.MessageText END DESC ,

	 CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'ASC'
	 THEN T.StartDate END ASC, 
	 CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'DESC'
	 THEN T.StartDate END DESC ,

	 CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'ASC'
	 THEN T.EndDate END ASC, 
	 CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'DESC'
	 THEN T.EndDate END DESC ,

	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'
	 THEN T.Sequence END ASC, 
	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'
	 THEN T.Sequence END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC 


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
 WHERE id = object_id(N'[dbo].[dms_Mobile_Configuration]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Mobile_Configuration] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 /*
 *	-- KB : Added two parameters - memberID and membershipID.
 *	The stored procedure will be called in two cases:
 *	1. Lookup a mobile  / prior Case record using the callback number
 *	2. The stored procedure might return multiple member records when there are multiple matching Case records.
 *	3. The application allows user to pick one member from a prior case record and this sp would then be invoked just to update the related inbound call record.
 */
CREATE PROC dms_Mobile_Configuration(@programID INT = NULL,  
          @configurationType nvarchar(50) = NULL,  
          @configurationCategory nvarchar(50) = NULL,  
          @callBackNumber nvarchar(50) = NULL,  
          @inBoundCallID INT = NULL,
		  @memberID INT = NULL,
		  @membershipID INT = NULL)  
AS  
BEGIN  
	--Declare
	--@programID INT = 286,  
	--@configurationType nvarchar(50) = 5,  
	--@configurationCategory nvarchar(50) = 3,  
	--@callBackNumber nvarchar(50) = '1 9858791084',  
	--@inBoundCallID INT = 509092,
	--@memberID INT = NULL, --16432463,
	--@membershipID INT = NULL --14802600  
		  
	SET FMTONLY OFF  
	-- Output Values   
	DECLARE @unformattedNumber nvarchar(50) = NULL  
	DECLARE @isMobileEnabled BIT = NULL  
	DECLARE @searchCaseRecords BIT = 1
	DECLARE @appOrgName NVARCHAR(100) = NULL

	-- Temporary Holders  
	DECLARE       @ProgramInformation_Temp TABLE(  
		Name  NVARCHAR(MAX),  
		Value NVARCHAR(MAX),  
		ControlType INT NULL,  
		DataType NVARCHAR(MAX) NULL,  
		Sequence INT NULL,
		ProgramLevel INT NULL)  
	 
	 -- Lakshmi - Added on 7/24/14
	 DECLARE  @GetPrograms_Temp TABLE(  
		ProgramID INT NULL )  
	 
	DECLARE @Mobile_CallForService_Temp TABLE(  
		[PKID] [int]  NULL,  
		[MemberNumber] [nvarchar](50) NULL,  
		[GUID] [nvarchar](50) NULL,  
		[FirstName] [nvarchar](50) NULL,  
		[LastName] [nvarchar](50) NULL,  
		[MemberDevicePhoneNumber] [nvarchar](20) NULL,  
		[locationLatitude] [nvarchar](10) NULL,  
		[locationLongtitude] [nvarchar](10) NULL,  
		[serviceType] [nvarchar](100) NULL,  
		[ErrorCode] [int] NULL,  
		[ErrorMessage] [nvarchar](200) NULL,  
		[DateTime] [datetime] NULL,  
		[IsMobileEnabled] BIT,  
		[MemberID] INT,  
		[MembershipID] INT)  
 

	IF ( @memberID IS NOT NULL)
		BEGIN
			
			UPDATE	InboundCall 
			SET		MemberID = @memberID   		
			WHERE	ID = @inBoundCallID 

			INSERT INTO @Mobile_CallForService_Temp
				([MemberID],[MembershipID],[IsMobileEnabled]) 
			VALUES
				(@memberID,@membershipID,@isMobileEnabled) 

		END
	ELSE
		BEGIN


			DECLARE @charIndex INT = 0  
			SELECT @charIndex = CHARINDEX('x',@callBackNumber,0)  

			IF @charIndex = 0  
				BEGIN  
					SET @charIndex = LEN(@callBackNumber)  
				END  
			ELSE  
				BEGIN  
					SET @charIndex = @charIndex -1  
				END  

		-- DEBUG:
		--PRINT @charIndex  
		--SELECT @callBackNumber
		
			SELECT @unformattedNumber = SUBSTRING(@callBackNumber,1,@charIndex)  
			SET @charIndex = 0  
			SELECT @charIndex = CHARINDEX(' ',@unformattedNumber,0)  
			SELECT @unformattedNumber = LTRIM(RTRIM(SUBSTRING(@unformattedNumber, @charIndex + 1, LEN(@unformattedNumber) - @charIndex)))  

		--DEBUG:
		--SELECT @unformattedNumber As UnformattedNumber, @callBackNumber AS CallbackNumber

	 
		-- Step 1 : Get the Program Information  
			;with wResultB AS  
			(    
				SELECT PC.Name,     
				PC.Value,     
				CT.Name AS ControlType,     
				DT.Name AS DataType,      
				PC.Sequence AS Sequence	,
				ROW_NUMBER() OVER ( PARTITION BY PC.Name ORDER BY PP.Sequence) AS [ProgramLevel]			    
				FROM ProgramConfiguration PC    
				 JOIN dbo.fnc_GetProgramsandParents(@programID)PP ON PP.ProgramID=PC.ProgramID    
				 JOIN [dbo].[fnc_GetProgramConfigurationForProgram](@programID,@configurationType) P ON P.ProgramConfigurationID = PC.ID    
				 LEFT JOIN ControlType CT ON PC.ControlTypeID = CT.ID    
				 LEFT JOIN DataType DT ON PC.DataTypeID = DT.ID    
			)  
			INSERT INTO @ProgramInformation_Temp SELECT * FROM wResultB  ORDER BY ProgramLevel, Sequence, Name   
		
			-- CR : 1225 - Start Tab - change process to lookup mobile phone number to incorporate appOrgName
			SELECT @appOrgName = Value FROM @ProgramInformation_Temp WHERE ProgramLevel = 1 AND Name = 'MobileAppOrg'
		
			--Lakshmi - Added on 7/24/2014
			INSERT INTO @GetPrograms_Temp ([ProgramID]) 
			((SELECT ProgramID FROM fnc_GetChildPrograms(@programID)
			UNION
			SELECT ProgramID FROM MemberSearchProgramGrouping
			WHERE ProgramID in(SELECT ProgramID FROM fnc_GetChildPrograms(@programID))))
		
			--DEBUG:  
			-- SELECT @appOrgName
			--SELECT * FROM @ProgramInformation_Temp  
	 
			--Step 2 :  
			-- Check Mobile is Enabled or NOT  
			IF EXISTS(SELECT * FROM @ProgramInformation_Temp WHERE Name = 'IsMobileEnabled' AND Value = 'yes')  
			BEGIN  
			--DEBUG:
			--PRINT 'Mobile config found'
				SET @isMobileEnabled = 1  
				SET @unformattedNumber  =  RTRIM(LTRIM(@unformattedNumber))  
				-- Get the Details FROM Mobile_CallForService  
				SELECT TOP 1 *  INTO #Mobile_CallForService_Temp  
					FROM Mobile_CallForService M  
					WHERE REPLACE(M.MemberDevicePhoneNumber,'-','') = @unformattedNumber  
					AND DATEDIFF(hh,M.[DateTime],GETDATE()) < 1  
					AND ISNULL(M.ErrorCode,0) = 0  
					AND appOrgName = @appOrgName -- CR : 1225 - Start Tab - change process to lookup mobile phone number to incorporate appOrgName
					ORDER BY M.[DateTime] DESC  

				IF((SELECT COUNT(*) FROM #Mobile_CallForService_Temp) >= 1)  
				BEGIN  
					--DEBUG:
					--PRINT 'Mobile record found'
				
					SET @searchCaseRecords = 0
				
					-- Try to find the member using the member number.
					
					SELECT  @memberID = RR.ID,  
					@membershipID = RR.MembershipID   
					FROM  
					(  
						SELECT TOP 1 M.ID,  
							   M.MembershipID   
							   FROM Membership MS 
						JOIN Member M ON MS.ID = M.MembershipID 
						JOIN Program P ON M.ProgramID=P.ID
						WHERE M.IsPrimary = 1 
						AND MS.MembershipNumber = 
						(SELECT MemberNumber FROM #Mobile_CallForService_Temp where membernumber IS NOT NULL AND memberNumber <> '') 
						AND (ISNULL(@ProgramID,0) = 0 OR M.ProgramID IN (SELECT * FROM @GetPrograms_Temp))  
					)RR  
					
					INSERT INTO @Mobile_CallForService_Temp
								([PKID],  
						[MemberNumber],  
						[GUID],  
						[FirstName],  
						[LastName],  
						[MemberDevicePhoneNumber],  
						[locationLatitude],  
						[locationLongtitude],  
						[serviceType],  
						[ErrorCode],  
						[ErrorMessage],  
						[DateTime],
						MemberID,
						MembershipID,
						IsMobileEnabled  
						)   
						SELECT	[PKID],  
								[MemberNumber],  
								[GUID],  
								[FirstName],  
								[LastName],  
								[MemberDevicePhoneNumber],  
								[locationLatitude],  
								[locationLongtitude],  
								[serviceType],  
								[ErrorCode],  
								[ErrorMessage],  
								[DateTime],
								@memberID,
								@membershipID,
								@isMobileEnabled
						FROM #Mobile_CallForService_Temp
	  
							
					IF((SELECT COUNT(*) FROM @Mobile_CallForService_Temp) = 1) 
					BEGIN
			        
						UPDATE InboundCall SET MemberID = @memberID,
							 MobileID = (SELECT PKID FROM #Mobile_CallForService_Temp)  
							WHERE ID = @inBoundCallID 

						-- Create a case phone location record when there is lat/long information.
						IF EXISTS(	SELECT * FROM #Mobile_CallForService_Temp   
								WHERE ISNULL(locationLatitude,'') <> ''  
								AND ISNULL(locationLongtitude,'') <> ''  
							)  
						BEGIN
							INSERT INTO CasePhoneLocation(	CaseID,  
														PhoneNumber,  
														CivicLatitude,  
														CivicLongitude,  
														IsSMSAvailable,  
														LocationDate,  
														LocationAccuracy,  
														InboundCallID,  
														PhoneTypeID,  
														CreateDate)   
														VALUES(NULL,  
														@callBackNumber,  
														(SELECT  locationLatitude FROM #Mobile_CallForService_Temp),  
														(SELECT  locationLongtitude FROM #Mobile_CallForService_Temp),  
														1,  
														(SELECT  [DateTime] FROM #Mobile_CallForService_Temp),  
														'mobile',  
														@inBoundCallID,  
														(SELECT ID FROM PhoneType WHERE Name = 'Cell'),  
														GETDATE()  
														)  
						END
					END

					IF((SELECT COUNT(*) FROM @Mobile_CallForService_Temp) > 1)
					BEGIN
						--PRINT 'Update Inbound Call'
						UPDATE InboundCall 
						SET  MobileID = (SELECT PKID FROM #Mobile_CallForService_Temp)  
						WHERE ID = @inBoundCallID  
					END
				
					IF @memberID IS NULL
					BEGIN
						-- Search in prior cases when you don't get a member using the membernumber from the mobile record.
						SET @searchCaseRecords = 1 
					END
				
					DROP TABLE #Mobile_CallForService_Temp
			
				END  
				
			END
		
			IF ( @searchCaseRecords = 1 )  
			BEGIN 
				--PRINT 'Search Case Records'
		
				INSERT INTO @Mobile_CallForService_Temp
									([MemberID],[MembershipID],[IsMobileEnabled]) 
					SELECT  DISTINCT M.ID,   
									M.MembershipID,
									@isMobileEnabled
					FROM [Case] C  
					JOIN Member M ON C.MemberID = M.ID 
					JOIN Program P ON M.ProgramID=P.ID		--Lakshmi
					WHERE C.ContactPhoneNumber = @callBackNumber 
					AND (ISNULL(@ProgramID,0) = 0 OR M.ProgramID IN (SELECT * FROM @GetPrograms_Temp))
					ORDER BY ID DESC
					
				IF((SELECT COUNT(*) FROM @Mobile_CallForService_Temp)= 0 OR (SELECT COUNT(*) FROM @Mobile_CallForService_Temp) = 1) 
				BEGIN
					--PRINT 'Update Inbound Call'
					UPDATE InboundCall 
					SET MemberID = @memberID   		
					WHERE ID = @inBoundCallID  
				END
			END  

		-- If one of the matching member IDs has an open SR then only return the associated Member, otherwise return all matching Members
		IF EXISTS (
			SELECT temp.*
			FROM @Mobile_CallForService_Temp temp
			JOIN [Case] c ON temp.MemberID = c.MemberID
			JOIN ServiceRequest sr ON c.ID = sr.CaseID
			WHERE sr.ServiceRequestStatusID IN (SELECT ID FROM ServiceRequestStatus WHERE Name IN ('Entry','Submitted','Dispatched'))
			)
			SELECT temp.*
			FROM @Mobile_CallForService_Temp temp
			JOIN [Case] c ON temp.MemberID = c.MemberID
			JOIN ServiceRequest sr ON c.ID = sr.CaseID
			WHERE sr.ServiceRequestStatusID IN (SELECT ID FROM ServiceRequestStatus WHERE Name IN ('Entry','Submitted','Dispatched'))
		ELSE
			SELECT * FROM @Mobile_CallForService_Temp     
	END     

END

GO
/****** Object:  StoredProcedure [dbo].[dms_Process_Vendor_Insurance_Expiration]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Process_Vendor_Insurance_Expiration]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Process_Vendor_Insurance_Expiration] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC [dms_Process_Vendor_Insurance_Expiration]
 CREATE PROCEDURE [dbo].[dms_Process_Vendor_Insurance_Expiration]
 AS 
 BEGIN 
 
    DECLARE @VendorsInsuranceExpired AS TABLE( 
	ID int NOT NULL IDENTITY(1,1),
	VendorID INT NOT NULL)
	
    DECLARE @VendorsInsuranceExpiring AS TABLE( 
	ID int NOT NULL IDENTITY(1,1),
	VendorID INT NOT NULL)
	

	INSERT INTO @VendorsInsuranceExpired
	SELECT	ID 
	FROM	Vendor WITH (NOLOCK) 
	WHERE	InsuranceExpirationDate IS NOT NULL 
	AND		DATEDIFF(DD,InsuranceExpirationDate,GETDATE()) = 1
	AND		ISNULL(IsActive,0) = 1
	

	INSERT INTO @VendorsInsuranceExpiring
	SELECT	ID 
	FROM	Vendor WITH (NOLOCK)  
	WHERE	InsuranceExpirationDate IS NOT NULL 
	AND		DATEDIFF (hh, GETDATE(),InsuranceExpirationDate) BETWEEN 0 AND 72
	AND		ISNULL(IsActive,0) = 1
	
	--SELECT * FROM @VendorsInsuranceExpired
	--SELECT * FROM @VendorsInsuranceExpiring
	
	
	DECLARE  @counter AS INT
	DECLARE  @maxItem AS INT
	DECLARE @vendorID AS INT
	
	SET @counter = 1

	SET @maxItem = (SELECT MAX(ID) FROM @VendorsInsuranceExpired)
	

		DECLARE @insuranceExpireDate DATETIME =NULL
		DECLARE @vendorName NVARCHAR(100) = NULL
		DECLARE @vendorNumber NVARCHAR(100) = NULL
		DECLARE @vendorEmail NVARCHAR(100) = NULL
		DECLARE @contactFirstName NVARCHAR(100) =NULL
		DECLARE @contactLastName NVARCHAR(100) = NULL
		DECLARE @regionName NVARCHAR(100) = NULL
		DECLARE @Email NVARCHAR(100) =NULL
		DECLARE @PhoneNumber NVARCHAR(100) =NULL
		DECLARE @vendorfax NVARCHAR(100) = NULL
		DECLARE @vendorRegionID INT = NULL
		DECLARE @vendorEntityID INT = NULL
		DECLARE @vendorRegionEntityID INT = NULL
		DECLARE @officePhoneTypeID INT = NULL
		DECLARE @faxPhoneTypeID INT = NULL
		
		DECLARE @officePhone NVARCHAR(100) = NULL
		DECLARE @faxPhone NVARCHAR(100) = NULL

		DECLARE @vendorServicesPhoneNumber NVARCHAR(100) = NULL,
				@vendorServicesFaxNumber NVARCHAR(100) = NULL,
				@contactLogID INT = NULL,
				@contactCategoryID INT = NULL,
				@contactTypeID INT = NULL,
				@emailContactMethodID INT = NULL,
				@faxContactMethodID INT = NULL,
				@contactSourceID INT = NULL,
				@contactReasonID INT = NULL,
				@contactActionID INT = NULL,
				@vendorInsuranceExpired_EmailTemplateID INT = NULL,
				@vendorInsuranceExpired_FaxTemplateID INT = NULL,
				@vendorInsuranceExpiring_EmailTemplateID INT = NULL,
				@vendorInsuranceExpiring_FaxTemplateID INT = NULL,
				@eventLogID BIGINT = NULL

		SET @contactCategoryID = (SELECT ID FROM ContactCategory WITH (NOLOCK) WHERE Name = 'ContactVendor')
		SET @contactTypeID = (SELECT ID FROM ContactType WITH (NOLOCK) WHERE Name = 'system')
		SET @contactCategoryID = (SELECT ID FROM ContactCategory WITH (NOLOCK) WHERE Name = 'ContactVendor')
		SET @emailContactMethodID = (SELECT ID FROM ContactMethod WITH (NOLOCK) WHERE Name = 'Email')
		SET @faxContactMethodID = (SELECT ID FROM ContactMethod WITH (NOLOCK) WHERE Name = 'Fax')
		SET @contactSourceID = (SELECT ID FROM ContactSource WITH (NOLOCK) WHERE Name = 'VendorData' AND ContactCategoryID = @contactCategoryID)
		SET @contactReasonID = (SELECT ID FROM ContactReason WITH (NOLOCK) WHERE Name = 'VendorInsurance' AND ContactCategoryID = @contactCategoryID)
		SET @contactActionID = (SELECT ID FROM ContactAction WITH (NOLOCK) WHERE Name = 'SendInsuranceExpirationNotice' AND ContactCategoryID = @contactCategoryID)

		SET @vendorInsuranceExpired_EmailTemplateID = (SELECT ID FROM Template WITH (NOLOCK) WHERE Name = 'Vendor_InsuranceExpiredEmail')
		SET @vendorInsuranceExpired_FaxTemplateID = (SELECT ID FROM Template WITH (NOLOCK) WHERE Name = 'Vendor_InsuranceExpiredFax')
		SET @vendorInsuranceExpiring_EmailTemplateID = (SELECT ID FROM Template WITH (NOLOCK) WHERE Name = 'Vendor_InsuranceExpiringEmail')
		SET @vendorInsuranceExpiring_FaxTemplateID = (SELECT ID FROM Template WITH (NOLOCK) WHERE Name = 'Vendor_InsuranceExpiringFax')
		
	
		SET	@vendorServicesPhoneNumber	= (SELECT Value FROM ApplicationConfiguration WHERE Name = 'VendorServicesPhoneNumber')
		SET	@vendorServicesFaxNumber	= (SELECT Value FROM ApplicationConfiguration WHERE Name = 'VendorServicesFaxNumber')
		SET @vendorEntityID = (SELECT ID FROM Entity where Name='Vendor')
		SELECT @faxPhoneTypeID = ID FROM PhoneType WHERE Name = 'Fax'
		
		DECLARE @messageData NVARCHAR(MAX) = NULL

	WHILE @counter <= @maxItem
	BEGIN

		-- Reset variables
		SET @insuranceExpireDate =NULL
		SET @vendorName  = NULL
		SET @vendorNumber  = NULL
		SET @vendorEmail = NULL
		SET @contactFirstName  =NULL
		SET @contactLastName  = NULL
		SET @regionName = NULL
		SET @Email =NULL
		SET @PhoneNumber =NULL
		SET @vendorRegionID = NULL
		SET @vendorRegionEntityID = NULL		
		
		SET @officePhone = NULL
		SET @faxPhone = NULL
		SET @vendorfax = NULL
		SET @contactLogID = NULL
		SET @eventLogID = NULL


		SET @vendorID = (SELECT VendorID FROM @VendorsInsuranceExpired WHERE ID = @counter)		

		PRINT '1: Processing InsuranceExpired for vendor - ' + CONVERT(NVARCHAR(100),@vendorID)

		SET @counter =  @counter + 1
		
		SELECT  
				@vendorNumber = V.VendorNumber, 
				@insuranceExpireDate = V.InsuranceExpirationDate,
				@vendorName =  V.Name, 	
				@vendorEmail = LTRIM(RTRIM(COALESCE(V.Email,''))),			
				@regionName = VR.Name,
				@contactFirstName = VR.ContactFirstName, 
				@contactLastName =  VR.ContactLastName, 
				@Email = VR.Email, 				
				@PhoneNumber = dbo.fnc_FormatPhoneNumber(VR.PhoneNumber, 0) , 
				@officePhone = dbo.fnc_FormatPhoneNumber(@vendorServicesPhoneNumber, 0) , 
				@faxPhone = dbo.fnc_FormatPhoneNumber(@vendorServicesFaxNumber,0)			
		FROM    Vendor AS V WITH (NOLOCK)
		LEFT OUTER JOIN	VendorRegion AS VR WITH (NOLOCK) ON V.VendorRegionID = VR.ID
		WHERE     (V.ID = @vendorID)
		
		SELECT @vendorfax = RS.PhoneNumber
		FROM
		(
		SELECT TOP 1 PhoneNumber
		FROM	Vendor V WITH (NOLOCK)
		LEFT JOIN PhoneEntity PE WITH (NOLOCK) ON PE.RecordID = V.ID AND PE.EntityID = @vendorEntityID AND PE.PhoneTypeID = @faxPhoneTypeID
		WHERE	V.ID = @vendorID
		) RS 
		
		--DEBUG: SELECT @vendorfax, @vendorID

		SET @messageData =  '<MessageData>'
		SET @messageData = @messageData + '<VendorName>'+ [dbo].[fnXMLEncode](ISNULL(@vendorName,''))+'</VendorName>'
		SET @messageData = @messageData + '<InsuranceExpireDate>'+ CONVERT(NVARCHAR(10),@insuranceExpireDate,101)+'</InsuranceExpireDate>'
		SET @messageData = @messageData + '<VendorNumber>'+ISNULL(@vendorNumber,'')+'</VendorNumber>'
		SET @messageData = @messageData + '<ContactFirstName>'+ [dbo].[fnXMLEncode](ISNULL(@contactFirstName,''))+'</ContactFirstName>'
		SET @messageData = @messageData + '<ContactLastName>'+ [dbo].[fnXMLEncode](ISNULL(@contactLastName,''))+'</ContactLastName>'
		SET @messageData = @messageData + '<RegionName>'+ [dbo].[fnXMLEncode](ISNULL(@regionName,''))+'</RegionName>'
		SET @messageData = @messageData + '<Email>'+ISNULL(@Email,'')+'</Email>'
		SET @messageData = @messageData + '<PhoneNumber>'+ISNULL(@PhoneNumber,'')+'</PhoneNumber>'
		SET @messageData = @messageData + '<Office>'+ISNULL(@officePhone,'')+'</Office>'
		SET @messageData = @messageData + '<fax>'+ISNULL(@faxPhone,'')+'</fax>'
		SET @messageData = @messageData + '<date>'+CONVERT(NVARCHAR(10),GETDATE(),101)+'</date>'
		SET @messageData = @messageData + '<vendorfax>' + ISNULL(dbo.fnc_FormatPhoneNumber(@vendorfax,0),'') + '</vendorfax>'
		SET @messageData = @messageData + '<vendorphone>' + 'TBD' + '</vendorphone>'
		SET @messageData =  @messageData + '</MessageData>'
		
		PRINT '1: ' + @messageData 
		
		-- 1. Create EventLog saying that an attempt was made to notify the vendor
		INSERT INTO EventLog (EventID,
						[Description],
						[Data],
						NotificationQueueDate,
						[Source],
						CreateDate,
						CreateBy)
			VALUES(
			(SELECT ID FROM [Event] WHERE Name='InsuranceExpired'),
			(SELECT [Description] FROM [Event] WHERE Name='InsuranceExpired'),
			@messageData,
			GETDATE(),
			'Vendor Insurance Expiry - Batch job',
			GETDATE(),
			'system'
			)
		SET @eventLogID = SCOPE_IDENTITY()
		INSERT INTO EventLogLink(EventLogID,EntityID,RecordID)
		VALUES(
			@eventLogID,
			@vendorEntityID,
			@vendorID
		)

		-- Check to see if a contactlog record was created in the past 12 hrs and skip the following statements if one exists.
		IF ( (SELECT [dbo].[fnCheckVendorInsuranceExpiryContactLog](@vendorID)) = 1)
		BEGIN
			-- 2. Create ContactLog
			INSERT INTO ContactLog (
									ContactCategoryID
									,ContactTypeID
									,ContactMethodID
									,ContactSourceID
									,Company									
									,PhoneTypeID
									,PhoneNumber
									,Email
									,Direction
									,Description																		
									,CreateDate
									,CreateBy									
									)
			SELECT	@contactCategoryID,
					@contactTypeID,
					CASE WHEN @vendorEmail = '' THEN @emailContactMethodID ELSE @faxContactMethodID END,
					@contactSourceID,
					@vendorName,
					CASE WHEN @vendorEmail = '' THEN @faxPhoneTypeID ELSE NULL END,
					CASE WHEN @vendorEmail = '' THEN @vendorfax ELSE NULL END,
					CASE WHEN @vendorEmail = '' THEN NULL ELSE @vendorEmail END,
					'Outbound',
					'Insurance Expiration Notice',
					GETDATE(),
					'system'

			SET @contactLogID = SCOPE_IDENTITY()

			--2.1 ContactLogLink
			INSERT INTO ContactLogLink (
											ContactLogID,
											EntityID,
											RecordID
										)

			SELECT	@contactLogID,
					@vendorEntityID,
					@vendorID
			--2.2 ContactLogAction

			INSERT INTO ContactLogAction (
											ContactLogID,
											ContactActionID,
											CreateBy,
											CreateDate									
											)
			SELECT	@contactLogID,
					@contactActionID,
					'system',
					GETDATE()

			--2.3 ContactLogReason

			INSERT INTO ContactLogReason (
											ContactLogID,
											ContactReasonID,
											CreateBy,
											CreateDate
											)
			SELECT	@contactLogID,
					@contactReasonID,
					'system',
					GETDATE()
			
			-- 3. Create CommunicationQueue record
			INSERT INTO CommunicationQueue (
											ContactLogID
											,ContactMethodID
											,TemplateID
											,MessageData
											,Subject
											,MessageText
											,Attempts
											,ScheduledDate
											,CreateDate
											,CreateBy
											,NotificationRecipient
											,EventLogID
											)
			SELECT	@contactLogID,
					CASE WHEN @vendorEmail <> '' THEN @emailContactMethodID ELSE @faxContactMethodID END,
					CASE WHEN @vendorEmail <> '' THEN @vendorInsuranceExpired_EmailTemplateID ELSE @vendorInsuranceExpired_FaxTemplateID END,
					@messageData,
					NULL,
					NULL,
					NULL,
					NULL,
					GETDATE(),
					'system',
					CASE WHEN @vendorEmail <> '' THEN @vendorEmail ELSE @vendorfax END,
					@eventLogID
		END

	END
	
	SET @counter = 1
	SET @maxItem = (SELECT MAX(ID) FROM @VendorsInsuranceExpiring)
	
	WHILE @counter <= @maxItem
	BEGIN

		-- Reset variables
		SET @insuranceExpireDate =NULL
		SET @vendorName  = NULL
		SET @vendorNumber  = NULL
		SET @vendorEmail = NULL
		SET @contactFirstName  =NULL
		SET @contactLastName  = NULL
		SET @regionName = NULL
		SET @Email =NULL
		SET @PhoneNumber =NULL
		SET @vendorRegionID = NULL
		SET @vendorRegionEntityID = NULL		
		
		SET @officePhone = NULL
		SET @faxPhone = NULL
		SET @vendorfax = NULL
		SET @contactLogID = NULL
		SET @eventLogID = NULL


		SET @vendorID = (SELECT VendorID FROM @VendorsInsuranceExpiring WHERE ID = @counter)		

		PRINT '1: Processing InsuranceExpiring for vendor - ' + CONVERT(NVARCHAR(100),@vendorID)

		SET @counter =  @counter + 1
		
		SELECT  
				@vendorNumber = V.VendorNumber, 
				@insuranceExpireDate = V.InsuranceExpirationDate,
				@vendorName =  V.Name, 	
				@vendorEmail = LTRIM(RTRIM(COALESCE(V.Email,''))),			
				@regionName = VR.Name,
				@contactFirstName = VR.ContactFirstName, 
				@contactLastName =  VR.ContactLastName, 
				@Email = VR.Email, 				
				@PhoneNumber = dbo.fnc_FormatPhoneNumber(VR.PhoneNumber, 0) , 
				@officePhone = dbo.fnc_FormatPhoneNumber(@vendorServicesPhoneNumber, 0) , 
				@faxPhone = dbo.fnc_FormatPhoneNumber(@vendorServicesFaxNumber,0)			
		FROM    Vendor AS V WITH (NOLOCK)
		LEFT OUTER JOIN	VendorRegion AS VR WITH (NOLOCK) ON V.VendorRegionID = VR.ID
		WHERE     (V.ID = @vendorID)
		
		SELECT @vendorfax = RS.PhoneNumber
		FROM
		(
		SELECT TOP 1 PhoneNumber
		FROM	Vendor V WITH (NOLOCK)
		LEFT JOIN PhoneEntity PE WITH (NOLOCK) ON PE.RecordID = V.ID AND PE.EntityID = @vendorEntityID AND PE.PhoneTypeID = @faxPhoneTypeID
		WHERE	V.ID = @vendorID
		) RS 
		
		--DEBUG: SELECT @vendorfax, @vendorID

		SET @messageData =  '<MessageData>'
		SET @messageData = @messageData + '<VendorName>'+[dbo].[fnXMLEncode](ISNULL(@vendorName,''))+'</VendorName>'
		SET @messageData = @messageData + '<InsuranceExpireDate>'+ CONVERT(NVARCHAR(10),@insuranceExpireDate,101)+'</InsuranceExpireDate>'
		SET @messageData = @messageData + '<VendorNumber>'+ISNULL(@vendorNumber,'')+'</VendorNumber>'
		SET @messageData = @messageData + '<ContactFirstName>'+[dbo].[fnXMLEncode](ISNULL(@contactFirstName,''))+'</ContactFirstName>'
		SET @messageData = @messageData + '<ContactLastName>'+[dbo].[fnXMLEncode](ISNULL(@contactLastName,''))+'</ContactLastName>'
		SET @messageData = @messageData + '<RegionName>'+ [dbo].[fnXMLEncode](ISNULL(@regionName,''))+'</RegionName>'
		SET @messageData = @messageData + '<Email>'+ISNULL(@Email,'')+'</Email>'
		SET @messageData = @messageData + '<PhoneNumber>'+ISNULL(@PhoneNumber,'')+'</PhoneNumber>'
		SET @messageData = @messageData + '<Office>'+ISNULL(@officePhone,'')+'</Office>'
		SET @messageData = @messageData + '<fax>'+ISNULL(@faxPhone,'')+'</fax>'
		SET @messageData = @messageData + '<date>'+CONVERT(NVARCHAR(10),GETDATE(),101)+'</date>'
		SET @messageData = @messageData + '<vendorfax>' + ISNULL(dbo.fnc_FormatPhoneNumber(@vendorfax,0),'') + '</vendorfax>'
		SET @messageData = @messageData + '<vendorphone>' + 'TBD' + '</vendorphone>'
		SET @messageData =  @messageData + '</MessageData>'
		
		PRINT '2: ' + @messageData 
		
		-- 1. Create EventLog saying that an attempt was made to notify the vendor
		INSERT INTO EventLog (EventID,
						[Description],
						[Data],
						NotificationQueueDate,
						[Source],
						CreateDate,
						CreateBy)
			VALUES(
			(SELECT ID FROM [Event] WHERE Name='InsuranceExpiring'),
			(SELECT [Description] FROM [Event] WHERE Name='InsuranceExpiring'),
			@messageData,
			GETDATE(),
			'Vendor Insurance Expiry - Batch job',
			GETDATE(),
			'system'
			)
		SET @eventLogID = SCOPE_IDENTITY()
		INSERT INTO EventLogLink(EventLogID,EntityID,RecordID)
		VALUES(
			@eventLogID,
			@vendorEntityID,
			@vendorID
		)

		-- Check to see if a contactlog record was created in the past 12 hrs and skip the following statements if one exists.
		IF ( (SELECT [dbo].[fnCheckVendorInsuranceExpiryContactLog](@vendorID)) = 1)
		BEGIN
			-- 2. Create ContactLog
			INSERT INTO ContactLog (
									ContactCategoryID
									,ContactTypeID
									,ContactMethodID
									,ContactSourceID
									,Company									
									,PhoneTypeID
									,PhoneNumber
									,Email
									,Direction
									,Description																		
									,CreateDate
									,CreateBy									
									)
			SELECT	@contactCategoryID,
					@contactTypeID,
					CASE WHEN @vendorEmail = '' THEN @emailContactMethodID ELSE @faxContactMethodID END,
					@contactSourceID,
					@vendorName,
					CASE WHEN @vendorEmail = '' THEN @faxPhoneTypeID ELSE NULL END,
					CASE WHEN @vendorEmail = '' THEN @vendorfax ELSE NULL END,
					CASE WHEN @vendorEmail = '' THEN NULL ELSE @vendorEmail END,
					'Outbound',
					'Insurance Expiration Notice',
					GETDATE(),
					'system'

			SET @contactLogID = SCOPE_IDENTITY()

			--2.1 ContactLogLink
			INSERT INTO ContactLogLink (
											ContactLogID,
											EntityID,
											RecordID
										)

			SELECT	@contactLogID,
					@vendorEntityID,
					@vendorID
			--2.2 ContactLogAction

			INSERT INTO ContactLogAction (
											ContactLogID,
											ContactActionID,
											CreateBy,
											CreateDate									
											)
			SELECT	@contactLogID,
					@contactActionID,
					'system',
					GETDATE()

			--2.3 ContactLogReason

			INSERT INTO ContactLogReason (
											ContactLogID,
											ContactReasonID,
											CreateBy,
											CreateDate
											)
			SELECT	@contactLogID,
					@contactReasonID,
					'system',
					GETDATE()
			
			-- 3. Create CommunicationQueue record
			INSERT INTO CommunicationQueue (
											ContactLogID
											,ContactMethodID
											,TemplateID
											,MessageData
											,Subject
											,MessageText
											,Attempts
											,ScheduledDate
											,CreateDate
											,CreateBy
											,NotificationRecipient
											,EventLogID
											)
			SELECT	@contactLogID,
					CASE WHEN @vendorEmail <> '' THEN @emailContactMethodID ELSE @faxContactMethodID END,
					CASE WHEN @vendorEmail <> '' THEN @vendorInsuranceExpiring_EmailTemplateID ELSE @vendorInsuranceExpiring_FaxTemplateID END,
					@messageData,
					NULL,
					NULL,
					NULL,
					NULL,
					GETDATE(),
					'system',
					CASE WHEN @vendorEmail <> '' THEN @vendorEmail ELSE @vendorfax END,
					@eventLogID
		END

	END
	
	-- KB: Enable the following after addressing the postlogin prompt
		
	/* 
	UPDATE
		VendorUser
	SET
		PostLoginPromptID = (SELECT ID  FROM PostLoginPrompt where Name ='InsuranceExpiring')
	FROM
		@VendorsInsuranceExpired VIE 
	INNER JOIN
		VendorUser VU
	ON 
		VU.VendorID = VIE.VendorID
    
    
	UPDATE
		VendorUser
	SET
		PostLoginPromptID = (SELECT ID  FROM PostLoginPrompt where Name ='InsuranceExpiring')
	FROM
		VendorUser VU
	INNER JOIN
		@VendorsInsuranceExpiring VIE 
	ON 
		VU.VendorID = VIE.VendorID
	*/

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
 WHERE id = object_id(N'[dbo].[dms_QA_ConcernType_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_QA_ConcernType_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_QA_ConcernType_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(50)  = '' 
 , @sortOrder nvarchar(255) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
  SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
NameOperator="-1" 
DescriptionOperator="-1" 
IsActiveOperator="-1" 
SequenceOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
NameOperator INT NOT NULL,
NameValue nvarchar(50) NULL,
DescriptionOperator INT NOT NULL,
DescriptionValue nvarchar(255) NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue bit NULL,
SequenceOperator INT NOT NULL,
SequenceValue int NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	Name nvarchar(50)  NULL ,
	Description nvarchar(255)  NULL ,
	IsActive bit  NULL ,
	Sequence int  NULL 
) 

CREATE TABLE #FinalResults_tmp( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	Name nvarchar(50)  NULL ,
	Description nvarchar(255)  NULL ,
	IsActive bit  NULL ,
	Sequence int  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@NameOperator','INT'),-1),
	T.c.value('@NameValue','nvarchar(50)') ,
	ISNULL(T.c.value('@DescriptionOperator','INT'),-1),
	T.c.value('@DescriptionValue','nvarchar(255)') ,
	ISNULL(T.c.value('@IsActiveOperator','INT'),-1),
	T.c.value('@IsActiveValue','bit') ,
	ISNULL(T.c.value('@SequenceOperator','INT'),-1),
	T.c.value('@SequenceValue','int') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults_tmp
SELECT 
	CT.ID,
	CT.Name,
	CT.[Description],
	CT.IsActive,
	CT.Sequence
FROM ConcernType CT
--WHERE Ct.IsActive = 1
INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.Name,
	T.[Description],
	T.IsActive,
	T.Sequence
FROM #FinalResults_tmp T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.IDOperator = -1 ) 
 OR 
	 ( TMP.IDOperator = 0 AND T.ID IS NULL ) 
 OR 
	 ( TMP.IDOperator = 1 AND T.ID IS NOT NULL ) 
 OR 
	 ( TMP.IDOperator = 2 AND T.ID = TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 3 AND T.ID <> TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 7 AND T.ID > TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 8 AND T.ID >= TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 9 AND T.ID < TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 10 AND T.ID <= TMP.IDValue ) 

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
	 ( TMP.DescriptionOperator = -1 ) 
 OR 
	 ( TMP.DescriptionOperator = 0 AND T.Description IS NULL ) 
 OR 
	 ( TMP.DescriptionOperator = 1 AND T.Description IS NOT NULL ) 
 OR 
	 ( TMP.DescriptionOperator = 2 AND T.Description = TMP.DescriptionValue ) 
 OR 
	 ( TMP.DescriptionOperator = 3 AND T.Description <> TMP.DescriptionValue ) 
 OR 
	 ( TMP.DescriptionOperator = 4 AND T.Description LIKE TMP.DescriptionValue + '%') 
 OR 
	 ( TMP.DescriptionOperator = 5 AND T.Description LIKE '%' + TMP.DescriptionValue ) 
 OR 
	 ( TMP.DescriptionOperator = 6 AND T.Description LIKE '%' + TMP.DescriptionValue + '%' ) 
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
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'ASC'
	 THEN T.Description END ASC, 
	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'DESC'
	 THEN T.Description END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC ,

	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'
	 THEN T.Sequence END ASC, 
	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'
	 THEN T.Sequence END DESC 


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
 WHERE id = object_id(N'[dbo].[dms_QA_Concern_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_QA_Concern_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_QA_Concern_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @concernTypeID INT = NULL 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
ConcernTypeOperator="-1" 
NameOperator="-1" 
DescriptionOperator="-1" 
SequenceOperator="-1" 
IsActiveOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
ConcernTypeOperator INT NOT NULL,
ConcernTypeValue nvarchar(50) NULL,
NameOperator INT NOT NULL,
NameValue nvarchar(50) NULL,
DescriptionOperator INT NOT NULL,
DescriptionValue nvarchar(255) NULL,
SequenceOperator INT NOT NULL,
SequenceValue int NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue bit NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	ConcernType nvarchar(50)  NULL ,
	Name nvarchar(50)  NULL ,
	Description nvarchar(255)  NULL ,
	Sequence int  NULL ,
	IsActive bit  NULL 
) 

 CREATE TABLE #FinalResults_tmp( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	ConcernType nvarchar(50)  NULL ,
	Name nvarchar(50)  NULL ,
	Description nvarchar(255)  NULL ,
	Sequence int  NULL ,
	IsActive bit  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@ConcernTypeOperator','INT'),-1),
	T.c.value('@ConcernTypeValue','nvarchar(50)') ,
	ISNULL(T.c.value('@NameOperator','INT'),-1),
	T.c.value('@NameValue','nvarchar(50)') ,
	ISNULL(T.c.value('@DescriptionOperator','INT'),-1),
	T.c.value('@DescriptionValue','nvarchar(255)') ,
	ISNULL(T.c.value('@SequenceOperator','INT'),-1),
	T.c.value('@SequenceValue','int') ,
	ISNULL(T.c.value('@IsActiveOperator','INT'),-1),
	T.c.value('@IsActiveValue','bit') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults_tmp
Select C.ID,
		CT.Description,
		C.Name,
		C.Description,
		C.Sequence,
		C.IsActive
from Concern C
LEFT OUTER JOIN ConcernType CT ON C.ConcernTypeID = CT.ID
WHERE (@concernTypeID IS NULL OR CT.ID = @concernTypeID)
ORDER BY Ct.ID
INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.ConcernType,
	T.Name,
	T.Description,
	T.Sequence,
	T.IsActive
FROM #FinalResults_tmp T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.IDOperator = -1 ) 
 OR 
	 ( TMP.IDOperator = 0 AND T.ID IS NULL ) 
 OR 
	 ( TMP.IDOperator = 1 AND T.ID IS NOT NULL ) 
 OR 
	 ( TMP.IDOperator = 2 AND T.ID = TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 3 AND T.ID <> TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 7 AND T.ID > TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 8 AND T.ID >= TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 9 AND T.ID < TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 10 AND T.ID <= TMP.IDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ConcernTypeOperator = -1 ) 
 OR 
	 ( TMP.ConcernTypeOperator = 0 AND T.ConcernType IS NULL ) 
 OR 
	 ( TMP.ConcernTypeOperator = 1 AND T.ConcernType IS NOT NULL ) 
 OR 
	 ( TMP.ConcernTypeOperator = 2 AND T.ConcernType = TMP.ConcernTypeValue ) 
 OR 
	 ( TMP.ConcernTypeOperator = 3 AND T.ConcernType <> TMP.ConcernTypeValue ) 
 OR 
	 ( TMP.ConcernTypeOperator = 4 AND T.ConcernType LIKE TMP.ConcernTypeValue + '%') 
 OR 
	 ( TMP.ConcernTypeOperator = 5 AND T.ConcernType LIKE '%' + TMP.ConcernTypeValue ) 
 OR 
	 ( TMP.ConcernTypeOperator = 6 AND T.ConcernType LIKE '%' + TMP.ConcernTypeValue + '%' ) 
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
	 ( TMP.DescriptionOperator = -1 ) 
 OR 
	 ( TMP.DescriptionOperator = 0 AND T.Description IS NULL ) 
 OR 
	 ( TMP.DescriptionOperator = 1 AND T.Description IS NOT NULL ) 
 OR 
	 ( TMP.DescriptionOperator = 2 AND T.Description = TMP.DescriptionValue ) 
 OR 
	 ( TMP.DescriptionOperator = 3 AND T.Description <> TMP.DescriptionValue ) 
 OR 
	 ( TMP.DescriptionOperator = 4 AND T.Description LIKE TMP.DescriptionValue + '%') 
 OR 
	 ( TMP.DescriptionOperator = 5 AND T.Description LIKE '%' + TMP.DescriptionValue ) 
 OR 
	 ( TMP.DescriptionOperator = 6 AND T.Description LIKE '%' + TMP.DescriptionValue + '%' ) 
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
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'ConcernType' AND @sortOrder = 'ASC'
	 THEN T.ConcernType END ASC, 
	 CASE WHEN @sortColumn = 'ConcernType' AND @sortOrder = 'DESC'
	 THEN T.ConcernType END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'ASC'
	 THEN T.Description END ASC, 
	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'DESC'
	 THEN T.Description END DESC ,

	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'
	 THEN T.Sequence END ASC, 
	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'
	 THEN T.Sequence END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC 


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
END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Insurance_Expiry_ContactLog_Check]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Insurance_Expiry_ContactLog_Check] 
 END 
 GO  

 IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnCheckVendorInsuranceExpiryContactLog]') 
AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
 DROP FUNCTION [dbo].[fnCheckVendorInsuranceExpiryContactLog]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--SELECT [dbo].[fnCheckVendorInsuranceExpiryContactLog](316)
 CREATE FUNCTION [dbo].[fnCheckVendorInsuranceExpiryContactLog] 
 (
	@vendorID INT
 )
 RETURNS BIT
 AS
 BEGIN

	DECLARE @vendorEntityID INT = NULL,		
			@clCreateDate DATETIME = NULL

	SELECT @vendorEntityID = ID FROM Entity WHERE Name = 'Vendor'


	;WITH wCL
	AS
	(
		SELECT  TOP 1 CL.CreateDate
		FROM	ContactLog CL WITH (NOLOCK)
		JOIN	ContactLogReason CLR WITH (NOLOCK) ON CLR.ContactLogID = CL.ID
		JOIN	ContactReason CR WITH (NOLOCK) ON CLR.ContactReasonID = CR.ID
		JOIN	ContactLogLink CLL WITH (NOLOCK) ON CLL.ContactLogID = CL.ID AND CLL.EntityID = @vendorEntityID AND CLL.RecordID = @vendorID
		WHERE	CR.Name = 'VendorInsurance'
		ORDER BY CL.CreateDate DESC
	)

	SELECT	@clCreateDate = W.CreateDate
	FROM	wCL W
	
	RETURN	CASE WHEN @clCreateDate IS NULL OR DATEDIFF(HH, @clCreateDate, GETDATE()) > 12 THEN CAST (1 AS BIT)
			ELSE CAST(0 AS BIT) 
			END
 END

GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnXMLEncode]') 
AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
 DROP FUNCTION [dbo].[fnXMLEncode]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--SELECT [dbo].[fnXMLEncode]('K & N')
 CREATE FUNCTION [dbo].[fnXMLEncode] 
 (
	@str NVARCHAR(MAX)
 )
 RETURNS NVARCHAR(MAX)
 AS
 BEGIN

	DECLARE @encodedString NVARCHAR(MAX) = NULL

	SET @encodedString =  (SELECT  @str FOR XML PATH(''))

	RETURN @encodedString

 END



GO
