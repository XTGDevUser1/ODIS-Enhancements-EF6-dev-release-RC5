IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Call_Summary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Call_Summary]
GO

--EXEC dms_Call_Summary @serviceRequestID = 1468  
CREATE PROC dms_Call_Summary(@serviceRequestID INT = NULL)  
AS  
BEGIN 


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
	SET FMTONLY OFF  
	-- Output Values   
	DECLARE @unformattedNumber nvarchar(50) = NULL  
	--DECLARE @memberID nvarchar(50) = NULL  
	--DECLARE @membershipID nvarchar(50) = NULL  
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
		VALUES(@memberID,@membershipID,@isMobileEnabled) 

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

		SELECT @unformattedNumber = SUBSTRING(@callBackNumber,1,@charIndex)  
		SET @charIndex = 0  
		SELECT @charIndex = CHARINDEX(' ',@unformattedNumber,0)  
		--SELECT @callBackNumber  
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
							WHERE M.IsPrimary = 1  
							   AND MS.MembershipNumber =   
						   (SELECT  MemberNumber FROM #Mobile_CallForService_Temp where membernumber IS NOT NULL AND memberNumber <> '')  
					)RR  

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

					IF @memberID IS NOT NULL
					BEGIN
						UPDATE InboundCall SET MemberID = @memberID,   
							 MobileID = (SELECT PKID FROM #Mobile_CallForService_Temp)  
						WHERE ID = @inBoundCallID  
					END
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
		
			DECLARE @memberRecordCount AS INT 
			SET @memberRecordCount = ISNULL((SELECT COUNT(M.ID)  
										 FROM [Case] C  
										 JOIN Member M ON C.MemberID = M.ID  
										 WHERE C.ContactPhoneNumber = @callBackNumber),0)
		

			IF(@memberRecordCount = 0 OR @memberRecordCount = 1) 
			BEGIN
						--DEBUG:
			--PRINT 'Mobile record not found'
			-- GET THE MEMBER DETAILS BY USING CALL BACK NUMBER  
				SELECT @memberID     = R.ID,  
				@membershipID = R.MembershipID   
				FROM  
				(  
				SELECT TOP 1 M.ID,   
				M.MembershipID  
				FROM [Case] C  
				JOIN Member M ON C.MemberID = M.ID  
				WHERE C.ContactPhoneNumber = @callBackNumber  
				ORDER BY ID DESC
				) R  
			
		
				UPDATE InboundCall 
				SET MemberID = @memberID   		
				WHERE ID = @inBoundCallID  
		
				IF ( (SELECT COUNT(*) FROM @Mobile_CallForService_Temp) > 0)
				BEGIN
					-- We already found location details in the above call, and we found member from prior cases.
					UPDATE @Mobile_CallForService_Temp 
					SET		MemberID = @memberID,
							MembershipID = @membershipID		
			
				END
				ELSE
				BEGIN		
				
					INSERT INTO @Mobile_CallForService_Temp
							([MemberID],[MembershipID],[IsMobileEnabled]) 
					VALUES(@memberID,@membershipID,@isMobileEnabled) 	
				END
			END
			ELSE
			BEGIN
				INSERT INTO @Mobile_CallForService_Temp
								([MemberID],[MembershipID],[IsMobileEnabled]) 
				SELECT    DISTINCT M.ID,   
								M.MembershipID,
								@isMobileEnabled
				FROM [Case] C  
				JOIN Member M ON C.MemberID = M.ID  
				WHERE C.ContactPhoneNumber = @callBackNumber  
				ORDER BY ID DESC
			END
		END  
	END
	           

	SELECT * FROM @Mobile_CallForService_Temp  
          
   
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
 WHERE id = object_id(N'[dbo].[dms_queue_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_queue_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_queue_list] @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB', @sortColumn='RequestNumber',@sortOrder = 'ASC'
-- EXEC [dbo].[dms_queue_list] @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB', @sortColumn='RequestNumber',@sortOrder = 'ASC', @whereClauseXML = '<ROW><Filter RequestNumberOperator="4" RequestNumberValue="4"></Filter></ROW>'
-- EXEC [dbo].[dms_queue_list] @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB', @sortColumn='RequestNumber',@sortOrder = 'ASC',@whereClauseXML = '<ROW><Filter StatusOperator="11" StatusValue="Cancelled"></Filter></ROW>'
 CREATE PROCEDURE [dbo].[dms_queue_list](   
   @userID UNIQUEIDENTIFIER = NULL  
 , @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 100    
 , @sortColumn nvarchar(100)  = ''   
 , @sortOrder nvarchar(100) = 'ASC'   
    
 )   
 AS   
 BEGIN   
    
SET NOCOUNT ON  
SET FMTONLY OFF  

CREATE TABLE #FinalResultsFiltered (  
[Case] int NULL ,  
RequestNumber int NULL ,  
Client nvarchar(100) NULL ,  
FirstName nvarchar(50)  NULL ,    
LastName nvarchar(50)  NULL , 
MiddleName   nvarchar(50)  NULL ,   
Suffix nvarchar(50)  NULL ,    
Prefix nvarchar(50)  NULL ,  
SubmittedOriginal DATETIME, 
SecondaryProductID INT NULL,   
ServiceType nvarchar(100) NULL ,  
[Status] nvarchar(100) NULL ,  
IsRedispatched BIT NULL,
AssignedToUserID INT NULL,
NextActionAssignedToUserID INT NULL,
ClosedLoop nvarchar(100) NULL ,  
PONumber nvarchar(50) NULL ,  
ISPName nvarchar(255) NULL ,  
CreateBy nvarchar(100) NULL ,  
NextAction nvarchar(MAX) NULL,  
NextActionID INT NULL,  
ClosedLoopID INT NULL,  
ServiceTypeID INT NULL,  
MemberNumber NVARCHAR(50) NULL,  
PriorityID INT NULL,  
[Priority] NVARCHAR(255) NULL,   
ScheduledOriginal DATETIME NULL,
-- KB: Added extra IDs
ProgramName NVARCHAR(50) NULL,
ProgramID INT NULL,
MemberID INT NULL,
StatusDateModified DATETIME NULL,  -- Added by Lakshmi - Queue Color
PrioritySort INT NULL,             -- Added by Phani - TFS 442
NextActionScheduledDate DATETIME NULL,     -- Added by Phani - TFS 442
ScheduleDateSort DATETIME NULL
)  
  
CREATE TABLE #FinalResultsFormatted (    
[Case] int NULL ,  
RequestNumber int NULL ,  
Client nvarchar(100) NULL ,  
Member nvarchar(max) NULL ,  
Submitted nvarchar(100) NULL ,  
SubmittedOriginal DATETIME,  
Elapsed NVARCHAR(10),  
ElapsedOriginal bigint,  
ServiceType nvarchar(100) NULL ,  
[Status] nvarchar(100) NULL ,  
AssignedTo nvarchar(100) NULL ,  
ClosedLoop nvarchar(100) NULL ,  
PONumber int NULL ,  
ISPName nvarchar(255) NULL ,  
CreateBy nvarchar(100) NULL ,  
NextAction nvarchar(MAX) NULL,  
MemberNumber NVARCHAR(50) NULL,  
[Priority] NVARCHAR(255) NULL,  
[Scheduled] nvarchar(100) NULL,  
ScheduledOriginal DATETIME  NULL,
-- KB: Added extra IDs
ProgramName NVARCHAR(50) NULL,
ProgramID INT NULL,
MemberID INT NULL,
StatusDateModified DATETIME NULL  -- Added by Lakshmi - Queue Color
)  

CREATE TABLE #FinalResultsSorted (  
[RowNum] [bigint] NOT NULL IDENTITY(1,1),  
[Case] int NULL ,  
RequestNumber int NULL ,  
Client nvarchar(100) NULL ,  
Member nvarchar(max) NULL ,  
Submitted nvarchar(100) NULL ,  
SubmittedOriginal DATETIME,  
Elapsed NVARCHAR(10),  
ElapsedOriginal bigint,  
ServiceType nvarchar(100) NULL ,  
[Status] nvarchar(100) NULL ,  
AssignedTo nvarchar(100) NULL ,  
ClosedLoop nvarchar(100) NULL ,  
PONumber int NULL ,  
ISPName nvarchar(255) NULL ,  
CreateBy nvarchar(100) NULL ,  
NextAction nvarchar(MAX) NULL,  
MemberNumber NVARCHAR(50) NULL,  
[Priority] NVARCHAR(255) NULL,  
[Scheduled] nvarchar(100) NULL,  
ScheduledOriginal DATETIME NULL,
-- KB: Added extra IDs
ProgramName NVARCHAR(50) NULL,
ProgramID INT NULL,
MemberID INT NULL,
StatusDateModified DATETIME NULL  -- Added by Lakshmi - Queue Color
)
  
DECLARE @openedCount BIGINT = 0  
DECLARE @submittedCount BIGINT = 0  
  
DECLARE @dispatchedCount BIGINT = 0  
--  
DECLARE @completecount BIGINT = 0  
DECLARE @cancelledcount BIGINT = 0  
  
--DECLARE @scheduledCount BIGINT = 0  
  
DECLARE @queueDisplayHours INT  
DECLARE @now DATETIME  
  
SET @now = GETDATE()  
  
SET @queueDisplayHours = 0  
SELECT @queueDisplayHours = CONVERT(INT,ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'QueueDisplayHours'  
  
DECLARE @idoc int  
IF @whereClauseXML IS NULL  
BEGIN  
SET @whereClauseXML = '<ROW><Filter  
CaseOperator="-1"  
RequestNumberOperator="-1"  
MemberOperator="-1"  
ServiceTypeOperator="-1"  
PONumberOperator="-1"  
ISPNameOperator="-1"  
CreateByOperator="-1"  
StatusOperator="-1"  
ClosedLoopOperator="-1"  
NextActionOperator="-1"  
AssignedToOperator="-1"  
></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
CaseOperator INT NOT NULL,  
CaseValue int NULL,  
RequestNumberOperator INT NOT NULL,  
RequestNumberValue int NULL,  
MemberOperator INT NOT NULL,  
MemberValue nvarchar(200) NULL,  
ServiceTypeOperator INT NOT NULL,  
ServiceTypeValue nvarchar(50) NULL,  
PONumberOperator INT NOT NULL,  
PONumberValue nvarchar(50) NULL,  
ISPNameOperator INT NOT NULL,  
ISPNameValue nvarchar(255) NULL,  
CreateByOperator INT NOT NULL,  
CreateByValue nvarchar(50) NULL,  
StatusOperator INT NOT NULL,  
StatusValue nvarchar(50) NULL,  
ClosedLoopOperator INT NOT NULL,  
ClosedLoopValue nvarchar(50) NULL,  
NextActionOperator INT NOT NULL,  
NextActionValue nvarchar(50) NULL,  
AssignedToOperator INT NOT NULL,  
AssignedToValue nvarchar(50) NULL,  
MemberNumberOperator INT NOT NULL,  
MemberNumberValue nvarchar(50) NULL,  
PriorityOperator INT NOT NULL,  
PriorityValue nvarchar(50) NULL  
)  
  
  
INSERT INTO @tmpForWhereClause  
SELECT  
ISNULL(CaseOperator,-1),  
CaseValue ,  
ISNULL(RequestNumberOperator,-1),  
RequestNumberValue ,  
ISNULL(MemberOperator,-1),  
MemberValue ,  
ISNULL(ServiceTypeOperator,-1),  
ServiceTypeValue ,  
ISNULL(PONumberOperator,-1),  
PONumberValue ,  
ISNULL(ISPNameOperator,-1),  
ISPNameValue ,  
ISNULL(CreateByOperator,-1),  
CreateByValue,  
ISNULL(StatusOperator,-1),  
StatusValue ,  
ISNULL(ClosedLoopOperator,-1),  
ClosedLoopValue,  
ISNULL(NextActionOperator,-1),  
NextActionValue,  
ISNULL(AssignedToOperator,-1),  
AssignedToValue,  
ISNULL(MemberNumberOperator,-1),  
MemberNumberValue,  
ISNULL(PriorityOperator,-1),  
PriorityValue  
  
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
CaseOperator INT,  
CaseValue int  
,RequestNumberOperator INT,  
RequestNumberValue int  
,MemberOperator INT,  
MemberValue nvarchar(200)  
,ServiceTypeOperator INT,  
ServiceTypeValue nvarchar(50)  
,PONumberOperator INT,  
PONumberValue nvarchar(50)  
,ISPNameOperator INT,  
ISPNameValue nvarchar(255)  
,CreateByOperator INT,  
CreateByValue nvarchar(50)  
,StatusOperator INT,  
StatusValue nvarchar(50),  
ClosedLoopOperator INT,  
ClosedLoopValue nvarchar(50),  
NextActionOperator INT,  
NextActionValue nvarchar(50),  
AssignedToOperator INT,  
AssignedToValue nvarchar(50),  
MemberNumberOperator INT,  
MemberNumberValue nvarchar(50),  
PriorityOperator INT,  
PriorityValue nvarchar(50)  
)  

DECLARE @CaseValue int  
DECLARE @RequestNumberValue int
DECLARE @MemberValue nvarchar(200)
DECLARE @ServiceTypeValue nvarchar(50)  
DECLARE @PONumberValue nvarchar(50)  
DECLARE @ISPNameValue nvarchar(255)  
DECLARE @CreateByValue nvarchar(50)  
DECLARE @StatusValue nvarchar(50)
DECLARE @ClosedLoopValue nvarchar(50)
DECLARE @NextActionValue nvarchar(50)
DECLARE @AssignedToValue nvarchar(50)
DECLARE @MemberNumberValue nvarchar(50)
DECLARE @PriorityValue nvarchar(50)
DECLARE @isFHT  BIT = 0

DECLARE @serviceRequestEntityID INT
DECLARE @fhtContactReasonID INT
DECLARE @dispatchStatusID INT

SET @serviceRequestEntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
SET @fhtContactReasonID = (SELECT ID FROM ContactReason WHERE Name = 'HumanTouch')
SET @dispatchStatusID = (SELECT ID FROM ServiceRequestStatus WHERE Name = 'Dispatched')

DECLARE @StartMins INT = 0 
SELECT @StartMins = -1 * CONVERT(INT,ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'FordHumanTouchStartMins' 

DECLARE @EndMins INT = 0 
SELECT @EndMins = -1 * CONVERT(INT,ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'FordHumanTouchEndMins' 

-- DEBUG:
--SELECT @StartMins, @EndMins

 SELECT @CaseValue = CaseValue,
		@RequestNumberValue = RequestNumberValue,
		@MemberValue = MemberValue,
		@ServiceTypeValue = ServiceTypeValue,
		@PONumberValue = PONumberValue,
		@ISPNameValue = ISPNameValue,
		@CreateByValue = CreateByValue,
		@StatusValue = StatusValue,
		@ClosedLoopValue = ClosedLoopValue,
		@NextActionValue = NextActionValue,
		@AssignedToValue = AssignedToValue,
		@MemberNumberValue = MemberNumberValue,
		@PriorityValue = PriorityValue
 FROM	@tmpForWhereClause
  
-- Extract the status values.  
  
DECLARE @tmpStatusInput TABLE  
(  
 StatusName NVARCHAR(100)  
)  
 
DECLARE @fhtCharIndex INT = -1
SET @fhtCharIndex = CHARINDEX('FHT',@StatusValue,0)

IF (@fhtCharIndex > 0)
BEGIN
	SET @StatusValue = REPLACE(@StatusValue,'FHT','')
	SET @isFHT = 1
END


  
INSERT INTO @tmpStatusInput  
SELECT Item FROM [dbo].[fnSplitString](@StatusValue,',')  
  
  
-- Include StatusNames with '^' suffix.  
INSERT INTO @tmpStatusInput  
SELECT StatusName + '^' FROM @tmpStatusInput  

-- CR : 1244 - FHT
IF (@isFHT = 1)
BEGIN	
	-- remove FHT from the StatusValue.	
	DECLARE @cnt INT = 0
	SELECT @cnt = COUNT(*) FROM @tmpStatusInput	
	IF (@cnt = 0)
	BEGIN
		SET @StatusValue = NULL		
	END
END

  
--DEBUG: SELECT * FROM @tmpStatusInput  
  
-- For EF to generate proper classes  
IF @userID IS NULL  
BEGIN  
SELECT 0 AS TotalRows,  
F.[RowNum],  
F.[Case],  
F.RequestNumber,  
F.Client,  
F.Member,  
F.Submitted,  
  
F.Elapsed,  
  
F.ServiceType,  
F.[Status] ,  
F.AssignedTo ,  
F.ClosedLoop ,  
F.PONumber ,  
  
F.ISPName ,  
F.CreateBy ,  
F.NextAction,  
F.MemberNumber,  
F.[Priority], 
F.ProgramName, 
F.ProgramID,
F.MemberID,
@openedCount AS [OpenedCount],  
@submittedCount AS [SubmittedCount],  
@cancelledcount AS [CancelledCount],  
@dispatchedCount AS [DispatchedCount],  
@completecount AS [CompleteCount],  
F.[Scheduled],
F.ScheduledOriginal ,	-- Added by Lakshmi- Queue Color
F.StatusDateModified  -- Added by Lakshmi  - Queue Color 
FROM #FinalResultsSorted F  
RETURN;  
END  
--------------------- BEGIN -----------------------------  
---- Create a temp variable or a CTE with the actual SQL search query ----------  
---- and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
-- LOGIC : BEGIN 

IF ( @isFHT = 0 )
BEGIN 
	
	INSERT INTO #FinalResultsFiltered
	SELECT  
			  DISTINCT  
			  SR.CaseID AS [Case],  
			  SR.ID AS [RequestNumber],  
			  CL.Name AS [Client],  
			  M.FirstName,
			  M.LastName,
			  M.MiddleName,
			  M.Suffix,
			  M.Prefix,     
			-- KB: Retain original values here for sorting  
			  sr.CreateDate AS SubmittedOriginal,
			-- KB: Retain original values here for sorting   
			  SR.SecondaryProductID,
			  PC.Name AS [ServiceType],  
			  SRS.Name As [Status],
			  SR.IsRedispatched,    
			  C.AssignedToUserID,
			  SR.NextActionAssignedToUserID,
			  CLS.[Description] AS [ClosedLoop],     
			  CONVERT(int,PO.PurchaseOrderNumber) AS [PONumber],  
			  V.Name AS [ISPName],  
			  SR.CreateBy AS [CreateBy],
			--RH: Temporary fix until we remove Ford Tech from Next Action
			  CASE 
				WHEN NA.Description = 'Ford Tech' THEN 'RV Tech'
				ELSE COALESCE(NA.Description,'') 
			  END AS [NextAction],  
			  CASE 
				WHEN SR.NextActionID = (SELECT ID FROM NextAction WHERE Name = 'FordTech' AND IsActive = 1) 
					THEN (SELECT ID FROM NextAction WHERE Name = 'RVTech')
				ELSE SR.NextActionID
			  END AS NextActionID,  
			--RH: See above
			  SR.ClosedLoopStatusID as [ClosedLoopID],  
			  SR.ProductCategoryID as [ServiceTypeID],  
			  MS.MembershipNumber AS [MemberNumber],  
			  SR.ServiceRequestPriorityID AS [PriorityID],  
			  CASE 
				WHEN SRP.Name IN ('Normal','Low') THEN ''  -- Do not display Normal and Low text
				ELSE SRP.Name 
			  END AS [Priority],   
			  sr.NextActionScheduledDate AS 'ScheduledOriginal', -- This field is used for Queue Color
			  P.ProgramName,
			  P.ProgramID,
			  M.ID AS MemberID,
			  SR.StatusDateModified	,		-- Added by Lakshmi	-Queue Color
			  CASE 
				WHEN sr.ServiceRequestPriorityID = (SELECT ID FROM ServiceRequestPriority WHERE Name = 'Critical') THEN 1
				WHEN sr.ServiceRequestPriorityID = (SELECT ID FROM ServiceRequestPriority WHERE Name = 'High') THEN 2
				ELSE 3
				END PrioritySort,             -- Push critical and High to the top 
			  SR.NextActionScheduledDate,
			  CASE
				WHEN sr.NextActionScheduledDate <= DATEADD(HH,1,getdate())
				THEN sr.NextActionScheduledDate
				ELSE '1/1/2099'
				END ScheduleDateSort         -- Push items scheduled now to the top 


	FROM [Case] C WITH (NOLOCK)
	JOIN [ServiceRequest] SR WITH (NOLOCK) ON C.ID = SR.CaseID  
	JOIN [ServiceRequestStatus] SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID  
	LEFT JOIN [ServiceRequestPriority] SRP WITH (NOLOCK) ON SR.ServiceRequestPriorityID = SRP.ID  
	JOIN dbo.fnc_GetProgramsForUser(@userID) P ON C.ProgramID = P.ProgramID  
	JOIN [Client] CL WITH (NOLOCK) ON P.ClientID = CL.ID  
	JOIN [Member] M WITH (NOLOCK) ON C.MemberID = M.ID  
	JOIN Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID  
	LEFT JOIN [ProductCategory] PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID  	
	LEFT JOIN (  
	SELECT ROW_NUMBER() OVER (PARTITION BY ServiceRequestID ORDER BY CreateDate DESC) AS RowNum,  
	ID,  
	PurchaseOrderNumber,  
	ServiceRequestID,  
	VendorLocationID   
	FROM PurchaseOrder WITH (NOLOCK)   
	WHERE --IsActive = 1 AND  
	PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WITH (NOLOCK) WHERE Name in ('Pending'))   
	AND (@PONumberValue IS NULL OR @PONumberValue = PurchaseOrderNumber)  
	) PO ON SR.ID = PO.ServiceRequestID AND PO.RowNum = 1  
	LEFT JOIN [NextAction] NA WITH (NOLOCK) ON SR.NextActionID=NA.ID  
	LEFT JOIN [VendorLocation] VL WITH (NOLOCK) ON PO.VendorLocationID = VL.ID  
	LEFT JOIN [Vendor] V WITH (NOLOCK) ON VL.VendorID = V.ID  
	LEFT JOIN (  
	SELECT ROW_NUMBER() OVER (PARTITION BY ELL.RecordID ORDER BY EL.CreateDate ASC) AS RowNum,  
	ELL.RecordID,  
	EL.EventID,  
	EL.CreateDate AS [Submitted]  
	FROM EventLog EL  WITH (NOLOCK) 
	JOIN EventLogLink ELL WITH (NOLOCK) ON EL.ID = ELL.EventLogID  
	JOIN [Event] E WITH (NOLOCK) ON EL.EventID = E.ID  
	JOIN [EventCategory] EC WITH (NOLOCK) ON E.EventCategoryID = EC.ID  
	WHERE ELL.EntityID = (SELECT ID FROM Entity WITH (NOLOCK) WHERE Name = 'ServiceRequest')  
	AND E.Name = 'SubmittedForDispatch'  
	) ELOG ON SR.ID = ELOG.RecordID AND ELOG.RowNum = 1  
	LEFT OUTER JOIN ClosedLoopStatus CLS WITH (NOLOCK) on CLS.ID=SR.ClosedLoopStatusID  

	WHERE	(@RequestNumberValue IS NOT NULL AND SR.ID = @RequestNumberValue)
	OR		(@RequestNumberValue IS NULL AND DATEDIFF(HH,SR.CreateDate,@now) <= @queueDisplayHours )--and SR.IsRedispatched is null  
END
ELSE
BEGIN
	
	INSERT INTO #FinalResultsFiltered	
	SELECT  
			DISTINCT  
			SR.CaseID AS [Case],  
			SR.ID AS [RequestNumber],  
			CL.Name AS [Client],  
			M.FirstName,
			M.LastName,
			M.MiddleName,
			M.Suffix,
			M.Prefix,     
			-- KB: Retain original values here for sorting  
			sr.CreateDate AS SubmittedOriginal,
			-- KB: Retain original values here for sorting   
			SR.SecondaryProductID,
			PC.Name AS [ServiceType],  
			SRS.Name As [Status],
			SR.IsRedispatched,    
			C.AssignedToUserID,
			SR.NextActionAssignedToUserID,
			CLS.[Description] AS [ClosedLoop],     
			CONVERT(int,PO.PurchaseOrderNumber) AS [PONumber],  
			V.Name AS [ISPName],  
			SR.CreateBy AS [CreateBy],  
			--RH: Temporary fix until we remove Ford Tech from Next Action
			  CASE 
				WHEN NA.Description = 'Ford Tech' THEN 'RV Tech'
				ELSE COALESCE(NA.Description,'') 
			  END AS [NextAction],  
			  CASE 
				WHEN SR.NextActionID = (SELECT ID FROM NextAction WHERE Name = 'FordTech' AND IsActive = 1) 
					THEN (SELECT ID FROM NextAction WHERE Name = 'RVTech')
				ELSE SR.NextActionID
			  END AS NextActionID, 
			--RH: See above  
			SR.ClosedLoopStatusID as [ClosedLoopID],  
			SR.ProductCategoryID as [ServiceTypeID],  
			MS.MembershipNumber AS [MemberNumber],  
			SR.ServiceRequestPriorityID AS [PriorityID],  
			--SRP.Name AS [Priority],
			CASE 
				WHEN SRP.Name IN ('Normal','Low') THEN ''
				ELSE SRP.Name 
			END AS [Priority],   
			SR.NextActionScheduledDate AS 'ScheduledOriginal',		-- This field is used for Queue Color
			P.Name AS ProgramName,
			P.ID AS ProgramID,
			M.ID AS MemberID,
			SR.StatusDateModified	,		-- Added by Lakshmi	-Queue Color
			CASE 
				WHEN sr.ServiceRequestPriorityID = (SELECT ID FROM ServiceRequestPriority WHERE Name = 'Critical') THEN 1
				WHEN sr.ServiceRequestPriorityID = (SELECT ID FROM ServiceRequestPriority WHERE Name = 'High') THEN 2
				ELSE 3
				END PrioritySort,
			SR.NextActionScheduledDate,
			CASE
				WHEN sr.NextActionScheduledDate <= DATEADD(HH,1,getdate())
				THEN sr.NextActionScheduledDate
				ELSE '1/1/2099'
				END ScheduleDateSort
	FROM	ServiceRequest SR	
	JOIN	[ServiceRequestStatus] SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID  
	LEFT JOIN	[ServiceRequestPriority] SRP WITH (NOLOCK) ON SR.ServiceRequestPriorityID = SRP.ID 
	JOIN	[Case] C on C.ID = SR.CaseID
	JOIN	Program P on P.ID = C.ProgramID
	JOIN	[Client] CL WITH (NOLOCK) ON P.ClientID = CL.ID
	JOIN	[Member] M WITH (NOLOCK) ON C.MemberID = M.ID  
	JOIN	Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID  
	LEFT JOIN [ProductCategory] PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID    
	JOIN	PurchaseOrder PO on PO.ServiceRequestID = SR.ID 
							AND PO.PurchaseOrderStatusID IN 
							(SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued', 'Issued-Paid'))
	LEFT JOIN [NextAction] NA WITH (NOLOCK) ON SR.NextActionID=NA.ID 
	LEFT JOIN [VendorLocation] VL WITH (NOLOCK) ON PO.VendorLocationID = VL.ID  
	LEFT JOIN [Vendor] V WITH (NOLOCK) ON VL.VendorID = V.ID  
	LEFT OUTER JOIN ClosedLoopStatus CLS WITH (NOLOCK) on CLS.ID=SR.ClosedLoopStatusID 
	LEFT OUTER JOIN (
		SELECT	CLL.RecordID 
				FROM	ContactLogLink cll 
				JOIN	ContactLog cl ON cl.ID = cll.ContactLogID
				JOIN	ContactLogReason clr ON clr.ContactLogID = cl.ID
				WHERE	cll.EntityID = @serviceRequestEntityID
				AND clr.ContactReasonID = @fhtContactReasonID
	) CLSR ON CLSR.RecordID = SR.ID
	WHERE	CL.Name = 'Ford'
	AND		SR.ServiceRequestStatusID = @dispatchStatusID
	AND		@now between dateadd(mi,@StartMins,po.ETADate) and dateadd(mi,@EndMins,po.ETADate)   
	-- Filter out those SRs that has a contactlog record for HumanTouch.
	AND		CLSR.RecordID IS NULL
	
END

  
-- LOGIC : END  
  

  
  
INSERT INTO #FinalResultsFormatted  
SELECT  
T.[Case],  
T.RequestNumber,  
T.Client,  
-- CR : 1256
REPLACE(RTRIM(
  COALESCE(T.LastName,'')+  
  COALESCE(' ' + CASE WHEN T.Suffix = '' THEN NULL ELSE T.Suffix END,'')+  
  COALESCE(', '+ CASE WHEN T.FirstName = '' THEN NULL ELSE T.FirstName END,'' )+
  COALESCE(' ' + LEFT(T.MiddleName,1),'')
  ),'','') AS [Member],
--REPLACE(RTRIM(  
--  COALESCE(''+T.LastName,'')+  
--  COALESCE(''+ space(1)+ T.Suffix,'')+  
--  COALESCE(','+  space(1) + T.FirstName,'' )+  
--  COALESCE(''+ space(1) + left(T.MiddleName,1),'')  
--  ),'','') AS [Member],  
CONVERT(VARCHAR(3),DATENAME(MONTH,T.SubmittedOriginal)) + SPACE(1)+   
+''+CONVERT (VARCHAR(2),DATEPART(dd,T.SubmittedOriginal)) + SPACE(1) +   
+''+REPLACE(REPLACE(RIGHT('0'+LTRIM(RIGHT(CONVERT(VARCHAR,T.SubmittedOriginal,100),7)),7),'AM','AM'),'PM','PM')as [Submitted], 
T.SubmittedOriginal,  
CONVERT(VARCHAR(6),DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())/3600)+':'  
  +RIGHT('0'+CONVERT(VARCHAR(2),(DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())%3600)/60),2) AS [Elapsed],  
DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())/3600 + ((DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())%3600)/60) AS ElapsedOriginal,    
CASE  
	WHEN T.SecondaryProductID IS NOT NULL  
	THEN T.ServiceType + '+'  
	ELSE T.ServiceType 
END AS ServiceType,
CASE  
	WHEN T.IsRedispatched =1 then T.[Status] + '^'  
	ELSE T.[Status]  
END AS [Status],
CASE WHEN T.AssignedToUserID IS NOT NULL  
	THEN '*' + ISNULL(ASU.FirstName,'') + ' ' + ISNULL(ASU.LastName,'')  
	ELSE ISNULL(SASU.FirstName,'') + ' ' + ISNULL(SASU.LastName,'')  
END AS [AssignedTo],    
T.ClosedLoop,  
T.PONumber,  
T.ISPName,  
T.CreateBy,  
T.NextAction,  
T.MemberNumber,  
T.[Priority],  
CONVERT(VARCHAR(3),DATENAME(MONTH,T.ScheduledOriginal)) + SPACE(1)+   
  +''+CONVERT (VARCHAR(2),DATEPART(dd,T.ScheduledOriginal)) + SPACE(1) +   
  +''+REPLACE(REPLACE(RIGHT('0'+LTRIM(RIGHT(CONVERT(VARCHAR,T.ScheduledOriginal,100),7)),7),'AM','AM'),'PM','PM')as [Scheduled],
T.[ScheduledOriginal],		-- This field is used for Queue Color
T.ProgramName,
T.ProgramID,
T.MemberID,
T.StatusDateModified					--Added by Lakshmi - Queue Color
FROM #FinalResultsFiltered T
LEFT JOIN [User] ASU WITH (NOLOCK) ON T.AssignedToUserID = ASU.ID  
LEFT JOIN [User] SASU WITH (NOLOCK) ON T.NextActionAssignedToUserID = SASU.ID  
WHERE (
		( @CaseValue IS NULL OR @CaseValue = T.[Case])
		AND
		( @RequestNumberValue IS NULL OR @RequestNumberValue = T.RequestNumber)
		AND
		( @ServiceTypeValue IS NULL OR @ServiceTypeValue = T.ServiceTypeID)
		AND
		( @ISPNameValue IS NULL OR T.ISPName LIKE '%' + @ISPNameValue + '%')
		AND
		( @CreateByValue IS NULL OR T.CreateBy LIKE '%' + @CreateByValue + '%')
		
		AND
		( @ClosedLoopValue IS NULL OR T.ClosedLoopID = @ClosedLoopValue)
		AND
		( @NextActionValue IS NULL OR T.NextActionID = @NextActionValue)
		AND
		( @MemberNumberValue IS NULL OR @MemberNumberValue = T.MemberNumber)
		AND 
		( @PriorityValue IS NULL OR @PriorityValue = T.PriorityID)	
		AND 
		( @PONumberValue IS NULL OR @PONumberValue = T.PONumber)		
	)
ORDER BY T.PrioritySort,T.ScheduleDateSort ,T.RequestNumber DESC



INSERT INTO #FinalResultsSorted
SELECT	T.[Case],  
		T.RequestNumber,  
		T.Client,  
		T.Member,  
		T.Submitted,  
		T.SubmittedOriginal,  
		T.Elapsed,  
		T.ElapsedOriginal,  
		T.ServiceType,  
		T.[Status],  
		T.AssignedTo,  
		T.ClosedLoop,  
		T.PONumber,  
		T.ISPName,  
		T.CreateBy,  
		T.NextAction,  
		T.MemberNumber,  
		T.[Priority],  
		T.[Scheduled],  
		T.ScheduledOriginal,
		T.ProgramName,
		T.ProgramID,
		T.MemberID,
		T.StatusDateModified				--Added by Lakshmi
FROM	#FinalResultsFormatted T
WHERE	( 
			( @MemberValue IS NULL OR  T.Member LIKE '%' + @MemberValue  + '%')
			AND
			( @AssignedToValue IS NULL OR T.AssignedTo LIKE '%' + @AssignedToValue + '%' )
			AND
			( @StatusValue IS NULL OR T.[Status] IN (       
											SELECT T.StatusName FROM @tmpStatusInput T    
											)  
										)
		)

ORDER BY  
CASE WHEN @sortColumn = 'Case' AND @sortOrder = 'ASC'  
THEN T.[Case] END ASC,  
CASE WHEN @sortColumn = 'Case' AND @sortOrder = 'DESC'  
THEN T.[Case] END DESC ,  
  
CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'ASC'  
THEN T.RequestNumber END ASC,  
CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'DESC'  
THEN T.RequestNumber END DESC ,  
  
CASE WHEN @sortColumn = 'Client' AND @sortOrder = 'ASC'  
THEN T.Client END ASC,  
CASE WHEN @sortColumn = 'Client' AND @sortOrder = 'DESC'  
THEN T.Client END DESC ,  
  
CASE WHEN @sortColumn = 'Member' AND @sortOrder = 'ASC'  
THEN T.Member END ASC,  
CASE WHEN @sortColumn = 'Member' AND @sortOrder = 'DESC'  
THEN T.Member END DESC ,  
  
CASE WHEN @sortColumn = 'Submitted' AND @sortOrder = 'ASC'  
THEN T.SubmittedOriginal END ASC,  
CASE WHEN @sortColumn = 'Submitted' AND @sortOrder = 'DESC'  
THEN T.SubmittedOriginal END DESC ,  
  
CASE WHEN @sortColumn = 'FormattedElapsedTime' AND @sortOrder = 'ASC'  
THEN T.ElapsedOriginal END ASC,  
CASE WHEN @sortColumn = 'FormattedElapsedTime' AND @sortOrder = 'DESC'  
THEN T.ElapsedOriginal END DESC ,  
  
CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'ASC'  
THEN T.ServiceType END ASC,  
CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'DESC'  
THEN T.ServiceType END DESC ,  
  
CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'  
THEN T.[Status] END ASC,  
CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'  
THEN T.[Status] END DESC ,  
  
CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'ASC'  
THEN T.AssignedTo END ASC,  
CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'DESC'  
THEN T.AssignedTo END DESC ,  
  
CASE WHEN @sortColumn = 'ClosedLoop' AND @sortOrder = 'ASC'  
THEN T.ClosedLoop END ASC,  
CASE WHEN @sortColumn = 'ClosedLoop' AND @sortOrder = 'DESC'  
THEN T.ClosedLoop END DESC ,  
  
CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'  
THEN T.PONumber END ASC,  
CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'  
THEN T.PONumber END DESC ,  
  
CASE WHEN @sortColumn = 'ISPName' AND @sortOrder = 'ASC'  
THEN T.ISPName END ASC,  
CASE WHEN @sortColumn = 'ISPName' AND @sortOrder = 'DESC'  
THEN T.ISPName END DESC ,  
  
CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'  
THEN T.CreateBy END ASC,  
CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'  
THEN T.CreateBy END DESC,  
  
CASE WHEN @sortColumn = 'Scheduled' AND @sortOrder = 'ASC'  
THEN T.ScheduledOriginal END ASC,  
CASE WHEN @sortColumn = 'Scheduled' AND @sortOrder = 'DESC'  
THEN T.ScheduledOriginal END DESC,  

CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'ASC'  
THEN T.NextAction END ASC,  
CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'DESC'  
THEN T.NextAction END DESC   
  
DECLARE @count INT  
SET @count = 0  
SELECT @count = MAX(RowNum) FROM #FinalResultsSorted  
SET @endInd = @startInd + @pageSize - 1  
IF @startInd > @count  
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
  
SELECT [Status],  
  COUNT(*) AS [Total]  
INTO #tmpStatusSummary  
FROM #FinalResultsFiltered  
WHERE [Status] IN ('Entry','Submitted','Submitted^','Dispatched','Dispatched^','Complete','Complete^','Cancelled','Cancelled^')  
GROUP BY [Status]  
--DEBUG: SELECT * FROM #tmpStatusSummary   
  
SELECT @openedCount = [Total] FROM #tmpStatusSummary WHERE [Status] = 'Entry'  
SELECT @submittedCount = SUM([Total]) FROM #tmpStatusSummary WHERE [Status] IN ('Submitted','Submitted^')  
SELECT @dispatchedCount = SUM([Total]) FROM #tmpStatusSummary WHERE [Status] in ('Dispatched', 'Dispatched^')  
SELECT @completecount = SUM([Total]) FROM #tmpStatusSummary WHERE [Status] in ('Complete', 'Complete^')  
SELECT @cancelledcount = SUM([Total]) FROM #tmpStatusSummary WHERE [Status] in ('Cancelled', 'Cancelled^')  
  
UPDATE #FinalResultsSorted SET Elapsed = NULL WHERE [Status] IN ('Complete','Complete^','Cancelled','Cancelled^')  
  
SELECT @count AS TotalRows,   
F.[RowNum],  
F.[Case],  
F.RequestNumber,  
F.Client,  
F.Member,  
F.Submitted,  
  
F.Elapsed,  
  
F.ServiceType,  
F.[Status] ,  
F.AssignedTo ,  
F.ClosedLoop ,  
F.PONumber ,  
  
F.ISPName ,  
F.CreateBy ,  
F.NextAction,  
F.MemberNumber,  
F.[Priority],  
  
  ISNULL(@openedCount,0) AS [OpenedCount],  
  ISNULL(@submittedCount,0) AS [SubmittedCount],  
  ISNULL(@dispatchedCount,0) AS [DispatchedCount],  
  ISNULL(@completecount,0) AS [CompleteCount],  
  ISNULL(@cancelledcount,0) AS [CancelledCount],  
  F.[Scheduled],
  F.ProgramName,
  F.ProgramID,
  F.MemberID,
  F.StatusDateModified,				--Added by Lakshmi - Queue Color
  F.ScheduledOriginal				--Added by Lakshmi - Queue Color
  
FROM #FinalResultsSorted F  
WHERE F.RowNum BETWEEN @startInd AND @endInd  
  
DROP TABLE #FinalResultsFiltered  
DROP TABLE #FinalResultsFormatted
DROP TABLE #FinalResultsSorted
DROP TABLE #tmpStatusSummary  
  
  
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
LEFT JOIN [Contract](NOLOCK) CON on CON.VendorID = V.ID and CON.IsActive = 1 and CON.ContractStatusID = (Select ID From ContractStatus Where Name = 'Active')
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
