IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Call_Summary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Call_Summary]
GO

--EXEC dms_Call_Summary @serviceRequestID = 1398
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

--TFS : 555
DECLARE @RelatedCoverageDetails AS TABLE(ClaimNumber NVARCHAR(MAX),ProductProviderName NVARCHAR(MAX),ProductProviderPhoneNumber NVARCHAR(MAX))
IF EXISTS (SELECT * FROM ServiceRequest WHERE  ID = @serviceRequestID AND ProviderClaimNumber IS NOT NULL)
BEGIN
	INSERT INTO @RelatedCoverageDetails
	SELECT SR.ProviderClaimNumber,
		   PP.Name,
		   PP.PhoneNumber
	FROM  ServiceRequest SR
	LEFT JOIN ProductProvider PP ON SR.ProviderID = PP.ID
	WHERE SR.ID = @serviceRequestID
END


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
	LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID

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


IF EXISTS (SELECT * FROM @RelatedCoverageDetails)
BEGIN
	DECLARE @maxSequence AS INT
	SET     @maxSequence = (SELECT MAX([Sequence]) FROM @Hold WHERE GroupName = 'Service Request')
	INSERT INTO @Hold SELECT 'RelatedCoverageDetailsProviderName', ProductProviderName,'String',@maxSequence + 1,'Related Coverage',3 FROM @RelatedCoverageDetails
	INSERT INTO @Hold SELECT 'RelatedCoverageDetailsProviderPhone', ProductProviderPhoneNumber,'String',@maxSequence + 2,'Related Coverage',3 FROM @RelatedCoverageDetails
	INSERT INTO @Hold SELECT 'RelatedCoverageDetailsClaimNumber', ClaimNumber,'String',@maxSequence + 3,'Related Coverage',3 FROM @RelatedCoverageDetails
END
 
 SELECT * FROM @Hold WHERE ColumnValue IS NOT NULL ORDER BY Sequence ASC 
 
END
GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Capture_Claim_Number_Details_For_SR_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Capture_Claim_Number_Details_For_SR_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC [dms_Capture_Claim_Number_Details_For_SR_Get] 1467
 CREATE PROCEDURE [dbo].[dms_Capture_Claim_Number_Details_For_SR_Get](
	@serviceRequestId INT = NULL
)
AS 
 BEGIN  
 
 SET FMTONLY OFF
 
CREATE TABLE #FinalResults( 
      [RowNum] [bigint] NOT NULL IDENTITY(1,1),
      ID int  NULL ,
      [Description] nvarchar(100)  NULL ,
      IsCaptureClaimNumber bit  NULL
)     

CREATE TABLE #FinalResults_tmp( 
      [RowNum] [bigint] NOT NULL IDENTITY(1,1),
      ID int  NULL ,
      [Description] nvarchar(100)  NULL ,
      IsCaptureClaimNumber bit  NULL
) 

INSERT INTO #FinalResults
SELECT 
      PP.ID
    , PP.[Description]
    , PP.IsCaptureClaimNumber
FROM 
    ProductProvider PP
    JOIN MemberProduct MP WITH(NOLOCK) ON MP.ProductProviderID = PP.ID
    JOIN [Case] C WITH(NOLOCK) ON 
			(	MP.MemberID = C.MemberID      
				OR
				(MP.MemberID IS NULL AND MP.MembershipID = (SELECT MembershipID FROM Member WHERE ID = C.MemberID))
			) 
			AND 
			(mp.VIN IS NULL OR mp.VIN = C.VehicleVIN)
	JOIN ServiceRequest SR WITH(NOLOCK) ON SR.CaseID = C.ID
WHERE SR.ID = @serviceRequestId

DECLARE @productProviderDescription AS NVARCHAR(100) --= (SELECT TOP 1 [Description] FROM #FinalResults)
DECLARE @isCaptureClaimNumber AS BIT = 0
DECLARE @productProviderID AS INT 

INSERT INTO #FinalResults_tmp
SELECT ID,[Description],IsCaptureClaimNumber FROM #FinalResults 
WHERE IsCaptureClaimNumber = 1

IF((SELECT COUNT(*) FROM #FinalResults_tmp F) >0)
BEGIN
	SET @isCaptureClaimNumber = 1
	
	SET @productProviderDescription = (SELECT TOP 1 [Description] FROM #FinalResults_tmp)
	SET @productProviderID = (SELECT TOP 1 ID FROM #FinalResults_tmp)
END
ELSE
BEGIN
	SET @productProviderDescription = (SELECT TOP 1 [Description] FROM #FinalResults)
	SET @productProviderID = (SELECT TOP 1 ID FROM #FinalResults)
END



SELECT @productProviderID AS ProductProviderID,@productProviderDescription AS ProductProviderDescription, @isCaptureClaimNumber AS IsCaptureClaimNumber

DROP TABLE #FinalResults
DROP TABLE #FinalResults_tmp
 END
GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Does_Event_Log_Link_Exists_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Does_Event_Log_Link_Exists_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC [dms_Does_Event_Log_Link_Exists_Get] 1467,'ServiceRequest','EnteredProviderClaimNumber'
 CREATE PROCEDURE [dbo].[dms_Does_Event_Log_Link_Exists_Get](
	@recordId INT = NULL,
	@entityName NVARCHAR(100) = NULL,
	@eventName NVARCHAR(100) = NULL
)
AS 
 BEGIN  
SELECT ELL.*
FROM	EventLogLink ELL WITH (NOLOCK) 
JOIN	EventLog EL WITH(NOLOCK) ON ELL.EventLogID = EL.ID
JOIN	[Event] E WITH (NOLOCK) ON EL.EventID = E.ID
JOIN	Entity EN WITH (NOLOCK) ON ELL.EntityID = EN.ID
WHERE	E.Name = @eventName
AND		EN.Name = @entityName
AND		ELL.RecordID = @recordId

END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ISPSelection_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ISPSelection_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO   
-- EXEC [dbo].[dms_ISPSelection_get]  1414,null,1,1,200,0.2,0.4,0.4,0,'Location',NULL
-- EXEC [dbo].[dms_ISPSelection_get]  44022,5,1,1,50,0.4,0.1,0.5,0,'Location'
/* Debug */
--DECLARE 
--    @ServiceRequestID int  = 44022 
--    ,@ActualServiceMiles decimal(10,2)  = 5 
--    ,@VehicleTypeID int  = 1 
--    ,@VehicleCategoryID int  = 1 
--    ,@SearchRadiusMiles int  = 50 
--    ,@AdminWeight decimal(5,2)  = .1 
--    ,@PerformWeight decimal(5,2) = .2  
--    ,@CostWeight decimal(5,2)  = .7 
--    ,@IncludeDoNotUse bit  = 0 
--    ,@SearchFrom nvarchar(50) = 'Location'
--    ,@productIDs NVARCHAR(MAX) = NULL 
      
CREATE PROCEDURE [dbo].[dms_ISPSelection_get]  
      @ServiceRequestID int  = NULL 
      ,@ActualServiceMiles decimal(10,2)  = NULL 
      ,@VehicleTypeID int  = NULL 
      ,@VehicleCategoryID int  = NULL 
      ,@SearchRadiusMiles int  = NULL 
      ,@AdminWeight decimal(5,2)  = NULL 
      ,@PerformWeight decimal(5,2) = NULL  
      ,@CostWeight decimal(5,2)  = NULL 
      ,@IncludeDoNotUse bit  = NULL 
      ,@SearchFrom nvarchar(50) = NULL
      ,@productIDs NVARCHAR(MAX) = NULL -- comma separated list of product IDs.
AS  
BEGIN    
  
/* Variable Declarations */  
DECLARE       
      @ServiceLocationLatitude decimal(10,7)   
    ,@ServiceLocationLongitude decimal(10,7)    
    ,@ServiceLocationStateProvince nvarchar(2)  
    ,@ServiceLocationCountryCode nvarchar(10)   
    ,@ServiceLocationPostalCode nvarchar(20)
    ,@DestinationLocationLatitude decimal(10,7)    
    ,@DestinationLocationLongitude decimal(10,7)  
    ,@PrimaryProductID int   
    ,@SecondaryProductID int  
    ,@ProductCategoryID int  
    ,@SecondaryProductCategoryID int  
    ,@MembershipID int  
    ,@ProgramID INT  
    ,@pcAdminWeight decimal(5,2)  = NULL   
      ,@pcPerformWeight decimal(5,2) = NULL    
      ,@pcCostWeight decimal(5,2)  = NULL   
      ,@IsTireDelivery bit  
      ,@LogISPSelection bit  
      ,@LogISPSelectionFinal bit  
  
/* Set Logging On/Off */  
SET @LogISPSelection = 0  
SET @LogISPSelectionFinal = 1  
  
/* Hard-coded radius for Do-Not-Use vendor selection - Should be added to ApplicationConfiguration */  
DECLARE @DNUSearchRadiusMiles int    
SET @DNUSearchRadiusMiles = 50    
  
/* Get Current Time for log inserts */  
DECLARE @now DATETIME = GETDATE()  
  
  
/* Work table declarations *******************************************************/  
SET FMTONLY OFF  
DECLARE @ISPSelection TABLE (  
[VendorID] [int] NOT NULL,  
[VendorLocationID] [int] NOT NULL,  
[VendorLocationVirtualID] [int] NULL,  
[Latitude] [decimal](10, 7) NULL,  
[Longitude] [decimal](10, 7) NULL,  
[VendorName] [nvarchar](255) NULL,  
[VendorNumber] [nvarchar](50) NULL,  
[Source] [varchar](8) NOT NULL,  
[ContractStatus] [nvarchar](50) NOT NULL,  
[Address1] [nvarchar](100) NULL,  
[Address2] [nvarchar](100) NULL,  
[City] [nvarchar](100) NULL,  
[StateProvince] [nvarchar](10) NULL,  
[PostalCode] [nvarchar](20) NULL,  
[CountryCode] [nvarchar](2) NULL,  
[DispatchPhoneNumber] [nvarchar](50) NULL,  
[AlternateDispatchPhoneNumber] [nvarchar](50) NULL, -- TFS: 105
[FaxPhoneNumber] [nvarchar](50) NULL,   
[OfficePhoneNumber] [nvarchar](50) NULL,  
[CellPhoneNumber] [nvarchar](50) NULL, -- CR : 1226  
[AdministrativeRating] [int] NULL,  
[InsuranceStatus] [varchar](11) NOT NULL,  
[BusinessHours] [nvarchar](100) NOT NULL,  
[PaymentTypes] [nvarchar] (100) NULL,    
[Comment] [nvarchar](2000) NULL,  
[ProductID] [int] NOT NULL,  
[ProductName] [nvarchar](50) NULL,  
[ProductRating] [decimal](5, 2) NULL,  
[EnrouteMiles] [float] NULL,  
[EnrouteTimeMinutes] [int] NULL,  
[ServiceMiles] [decimal](10, 2) NULL,  
[ServiceTimeMinutes] [int] NULL,  
[ReturnMiles] [float] NULL,  
[ReturnTimeMinutes] [int] NULL,  
[EstimatedHours] [float] NULL,  
[BaseRate] [money] NULL,  
[HourlyRate] [money] NULL,  
[EnrouteRate] [money] NULL,  
[EnrouteFreeMiles] [int] NULL,  
[ServiceRate] [money] NULL,  
[ServiceFreeMiles] [int] NULL,  
[EstimatedPrice] [float] NULL,  
[WiseScore] [float] NULL,  
[CallStatus] [varchar](9) NOT NULL,  
[RejectReason] [nvarchar](255) NULL,  
[RejectComment] [nvarchar](max) NULL,  
[IsPossibleCallback] [bit] NOT NULL,
[IsPreferred] [int] NULL
)   
  
DECLARE @ISPSelectionFinalResults TABLE (  
[VendorID] [int] NOT NULL,  
[VendorLocationID] [int] NOT NULL,  
[VendorLocationVirtualID] [int] NULL,  
[Latitude] [decimal](10, 7) NULL,  
[Longitude] [decimal](10, 7) NULL,  
[VendorName] [nvarchar](255) NULL,  
[VendorNumber] [nvarchar](50) NULL,  
[Source] [varchar](8) NOT NULL,  
[ContractStatus] [nvarchar](50) NOT NULL,  
[Address1] [nvarchar](100) NULL,  
[Address2] [nvarchar](100) NULL,  
[City] [nvarchar](100) NULL,  
[StateProvince] [nvarchar](10) NULL,  
[PostalCode] [nvarchar](20) NULL,  
[CountryCode] [nvarchar](2) NULL,  
[DispatchPhoneNumber] [nvarchar](50) NULL,  
[AlternateDispatchPhoneNumber] [nvarchar](50) NULL, -- TFS: 105
[FaxPhoneNumber] [nvarchar](50) NULL,   
[OfficePhoneNumber] [nvarchar](50) NULL,  
[CellPhoneNumber] [nvarchar](50) NULL, -- CR : 1226  
[AdministrativeRating] [int] NULL,  
[InsuranceStatus] [varchar](11) NOT NULL,  
[BusinessHours] [nvarchar](100) NOT NULL,  
[PaymentTypes] [nvarchar] (100) NULL,    
[Comment] [nvarchar](2000) NULL,  
[ProductID] [int] NOT NULL,  
[ProductName] [nvarchar](50) NULL,  
[ProductRating] [decimal](5, 2) NULL,  
[EnrouteMiles] [float] NULL,  
[EnrouteTimeMinutes] [int] NULL,  
[ServiceMiles] [decimal](10, 2) NULL,  
[ServiceTimeMinutes] [int] NULL,  
[ReturnMiles] [float] NULL,  
[ReturnTimeMinutes] [int] NULL,  
[EstimatedHours] [float] NULL,  
[BaseRate] [money] NULL,  
[HourlyRate] [money] NULL,  
[EnrouteRate] [money] NULL,  
[EnrouteFreeMiles] [int] NULL,  
[ServiceRate] [money] NULL,  
[ServiceFreeMiles] [int] NULL,  
[EstimatedPrice] [float] NULL,  
[WiseScore] [float] NULL,  
[CallStatus] [varchar](9) NOT NULL,  
[RejectReason] [nvarchar](255) NULL,  
[RejectComment] [nvarchar](max) NULL,  
[IsPossibleCallback] [bit] NOT NULL,  
[AllServices] [NVARCHAR](MAX) NULL,  
[ProductSearchRadiusMiles] [int] NULL,  
[IsInProductSearchRadius] [bit] NULL,
[IsPreferred] [int] NULL  
)  
  
CREATE TABLE #ISPDoNotUse (  
[VendorID] [int] NOT NULL,  
[VendorLocationID] [int] NOT NULL,  
[VendorLocationVirtualID] [int] NULL,  
[Latitude] [decimal](10, 7) NULL,  
[Longitude] [decimal](10, 7) NULL,  
[VendorName] [nvarchar](255) NULL,  
[VendorNumber] [nvarchar](50) NULL,  
[Source] [varchar](8) NOT NULL,  
[ContractStatus] [nvarchar](50) NULL,  
[Address1] [nvarchar](100) NULL,  
[Address2] [nvarchar](100) NULL,  
[City] [nvarchar](100) NULL,  
[StateProvince] [nvarchar](10) NULL,  
[PostalCode] [nvarchar](20) NULL,  
[CountryCode] [nvarchar](2) NULL,  
[DispatchPhoneNumber] [nvarchar](50) NULL,  
[AlternateDispatchPhoneNumber] [nvarchar](50) NULL, -- TFS: 105
[FaxPhoneNumber] [nvarchar](50) NULL,   
[OfficePhoneNumber] [nvarchar](50) NULL,  
[CellPhoneNumber] [nvarchar](50) NULL, -- CR: 1226  
[AdministrativeRating] [int] NULL,  
[InsuranceStatus] [varchar](11) NULL,  
[BusinessHours] [nvarchar](100) NULL,  
[PaymentTypes] [nvarchar] (100) NULL,    
[Comment] [nvarchar](2000) NULL,  
[ProductID] [int] NULL,  
[ProductName] [nvarchar](50) NULL,  
[ProductRating] [decimal](5, 2) NULL,  
[EnrouteMiles] [float] NULL,  
[EnrouteTimeMinutes] [int] NULL,  
[ServiceMiles] [decimal](10, 2) NULL,  
[ServiceTimeMinutes] [int] NULL,  
[ReturnMiles] [float] NULL,  
[ReturnTimeMinutes] [int] NULL,  
[EstimatedHours] [float] NULL,  
[BaseRate] [money] NULL,  
[HourlyRate] [money] NULL,  
[EnrouteRate] [money] NULL,  
[EnrouteFreeMiles] [int] NULL,  
[ServiceRate] [money] NULL,  
[ServiceFreeMiles] [int] NULL,  
[EstimatedPrice] [float] NULL,  
[WiseScore] [float] NULL,  
[CallStatus] [varchar](9) NULL,  
[RejectReason] [nvarchar](255) NULL,  
[RejectComment] [nvarchar](max) NULL,  
[IsPossibleCallback] [bit] NULL  
)   
  
CREATE TABLE #IspDetail (  
[VendorID] [int] NOT NULL,  
[VendorLocationID] [int] NOT NULL,  
[VendorLocationVirtualID] [int] NULL,  
[Latitude] [decimal](10, 7) NULL,  
[Longitude] [decimal](10, 7) NULL,  
[VendorName] [nvarchar](255) NULL,  
[VendorNumber] [nvarchar](50) NULL,  
[Source] [varchar](8) NOT NULL,  
[ContractStatus] [nvarchar](50) NULL,  
[DispatchPhoneNumber] [nvarchar](50) NULL,  
[AlternateDispatchPhoneNumber] [nvarchar](50) NULL, -- TFS: 105
[AdministrativeRating] [int] NULL,  
[InsuranceStatus] [varchar](11) NOT NULL,  
[IsOpen24Hours] [bit] NULL,  
[BusinessHours] [nvarchar](100) NULL,  
--[PaymentTypes] [nvarchar] (100) NULL,    
[Comment] [nvarchar](2000) NULL,  
[EnrouteMiles] [float] NULL,  
[ServiceMiles] [decimal](10, 2) NULL,  
[ReturnMiles] [float] NULL,  
[ProductID] [int] NOT NULL,  
[ProductName] [nvarchar](50) NULL,  
[ProductRating] [decimal](5, 2) NULL,  
[RateTypeID] [int] NULL,  
[RatePrice] [money] NULL,  
[RateQuantity] [int] NULL,  
[RateTypeName] [nvarchar](50) NULL,  
[RateUnitOfMeasure] [nvarchar](50) NULL,  
[RateUnitOfMeasureSource] [nvarchar](50) NULL,  
[IsProductMatch] [int] NOT NULL,
[IsPreferred] [int] NULL  
)   
  
-- Get service information from ServiceRequest  
SELECT         
      @ServiceLocationLatitude = SR.ServiceLocationLatitude,  
    @ServiceLocationLongitude = SR.ServiceLocationLongitude,  
    @ServiceLocationStateProvince = SR.ServiceLocationStateProvince,  
    @ServiceLocationCountryCode = SR.ServiceLocationCountryCode,  
    @ServiceLocationPostalCode = SR.ServiceLocationPostalCode,
    @DestinationLocationLatitude = SR.DestinationLatitude,  
    @DestinationLocationLongitude = SR.DestinationLongitude,  
    @PrimaryProductID = SR.PrimaryProductID,  
    @SecondaryProductID = SR.SecondaryProductID,  
    @ProductCategoryID = SR.ProductCategoryID,  
   @MembershipID = m.MembershipID,  
    @ProgramID = c.ProgramID  
FROM  ServiceRequest SR  
JOIN [Case] c ON SR.CaseID = c.ID  
JOIN Member m ON c.MemberID = m.ID  
WHERE SR.ID = @ServiceRequestID  
  
SET @SecondaryProductCategoryID = (SELECT ProductCategoryID FROM Product WHERE ID = @SecondaryProductID)  
  
-- Additional condition needed to include tire stores if tire service and tire delivery selected  
SET @IsTireDelivery = ISNULL((SELECT 1 FROM ServiceRequestDetail WHERE @ProductCategoryID = 2 AND ServiceRequestID = @ServiceRequestID AND ProductCategoryQuestionID = 203 AND Answer = 'Tire Delivery'),0)  
  
-- Set program specific ISP scoring weights */  
DECLARE @ProgramConfig TABLE (  
      Name NVARCHAR(50) NULL,  
      Value NVARCHAR(255) NULL  
)  
  
;WITH wProgramConfig   
AS  
(     SELECT ROW_NUMBER() OVER ( PARTITION BY PC.Name ORDER BY PP.Sequence) AS RowNum,  
                  PP.Sequence,  
                  PC.Name,      
                  PC.Value      
      FROM fnc_GetProgramsandParents(@ProgramID) PP  
      JOIN ProgramConfiguration PC ON PP.ProgramID = PC.ProgramID AND PC.IsActive = 1  
      WHERE PC.ConfigurationTypeID = 5   
      AND         PC.ConfigurationCategoryID = 3  
)  
  
INSERT INTO @ProgramConfig  
SELECT      W.Name,  
            W.Value  
FROM  wProgramConfig W  
WHERE W.RowNum = 1  
  
SET @pcAdminWeight = NULL  
SET @pcPerformWeight = NULL  
SET @pcCostWeight = NULL  
SELECT @pcAdminWeight = CONVERT(DECIMAL(5,2),Value) FROM @ProgramConfig WHERE Name = 'DefaultAdminWeighting'  
SELECT @pcPerformWeight = CONVERT(DECIMAL(5,2),Value) FROM @ProgramConfig WHERE Name = 'DefaultPerformanceWeighting'  
SELECT @pcCostWeight = CONVERT(DECIMAL(5,2),Value) FROM @ProgramConfig WHERE Name = 'DefaultCostWeighting'  
  
-- DEBUG : SELECT @pcAdminWeight AS AdminWeight, @pcCostWeight AS CostWeight, @pcPerformWeight AS PerfWeight  
-- If one the values is not defined, then use the values from ApplicationConfiguration.  
-- In other words, if all the three values are found, then override the ones from the app config.  
IF @pcAdminWeight IS NOT NULL AND @pcCostWeight IS NOT NULL AND @pcPerformWeight IS NOT NULL  
BEGIN  
      PRINT 'Using the values from ProgramConfig'  
        
      SET @AdminWeight = @pcAdminWeight  
      SET @CostWeight = @pcCostWeight  
      SET @PerformWeight = @pcPerformWeight  
END  
    
/* Get geography values for service location and towing destination */    
DECLARE @ServiceLocation as geography    
      ,@DestinationLocation as geography    
IF (@ServiceLocationLatitude IS NOT NULL AND @ServiceLocationLongitude IS NOT NULL)  
BEGIN  
    SET @ServiceLocation = geography::Point(@ServiceLocationLatitude, @ServiceLocationLongitude, 4326)    
END  
IF (@DestinationLocationLatitude IS NOT NULL AND @DestinationLocationLongitude IS NOT NULL)  
BEGIN  
    SET @DestinationLocation = geography::Point(@DestinationLocationLatitude, @DestinationLocationLongitude, 4326)    
END  
    
/* Set Service Miles based on service and destination locations - same for all vendors */    
DECLARE @ServiceMiles decimal(10,2)    
IF @ActualServiceMiles IS NOT NULL    
SET @ServiceMiles = @ActualServiceMiles    
ELSE    
SET @ServiceMiles = ROUND(@DestinationLocation.STDistance(@ServiceLocation)/1609.344,0)    
  
/* Get Market product rates according to market location */  
CREATE TABLE #MarketRates (  
[ProductID] [int] NULL,  
[RateTypeID] [int] NULL,  
[Name] [nvarchar](50) NULL,  
[Price] [money] NULL,  
[Quantity] [int] NULL  
)  
  
INSERT INTO #MarketRates  
SELECT ProductID, RateTypeID, Name, RatePrice, RateQuantity  
FROM dbo.fnGetDefaultProductRatesByMarketLocation(@ServiceLocation, @ServiceLocationCountryCode, @ServiceLocationStateProvince)  
  
CREATE CLUSTERED INDEX IDX_MarketRates ON #MarketRates(ProductID, RateTypeID)  
  
/* Get ISP Search Radius increment (bands) based on service and location (metro or rural) */  
DECLARE @IsMetroLocation bit  
DECLARE @ProductSearchRadiusMiles int  
  
/* Determine if service location is within a Metro Market Location radius */  
SET @IsMetroLocation = ISNULL(  
      (SELECT TOP 1 1   
      FROM MarketLocation ml  
      WHERE ml.MarketLocationTypeID = (SELECT ID FROM MarketLocationType WHERE Name = 'Metro')  
      And ml.IsActive = 'TRUE'  
      and ml.GeographyLocation.STDistance(@ServiceLocation) <= ml.RadiusMiles * 1609.344)  
      ,0)  
  
SELECT @ProductSearchRadiusMiles = CASE WHEN @IsMetroLocation = 1 THEN MetroRadius ELSE RuralRadius END   
FROM ProductISPSelectionRadius r  
WHERE ProductID = @PrimaryProductID   
  
IF @ProductSearchRadiusMiles IS NULL   
      SET @ProductSearchRadiusMiles = @SearchRadiusMiles  
  
  
/* Get reference type IDs */    
DECLARE     
            @VendorEntityID int    
            ,@VendorLocationEntityID int    
            ,@ServiceRequestEntityID int    
            ,@BusinessAddressTypeID int    
            ,@DispatchPhoneTypeID int  
			,@AltDispatchPhoneTypeID int 
            ,@FaxPhoneTypeID int  
            ,@OfficePhoneTypeID int    
            ,@CellPhoneTypeID int -- CR : 1226  
            ,@PrimaryServiceProductSubTypeID int    
            ,@ActiveVendorStatusID int  
            ,@DoNotUseVendorStatusID int  
            ,@ActiveVendorLocationStatusID int  
SET @VendorEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'Vendor')    
SET @VendorLocationEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'VendorLocation')    
SET @ServiceRequestEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'ServiceRequest')    
SET @BusinessAddressTypeID = (SELECT ID FROM dbo.AddressType WHERE Name = 'Business')    
SET @DispatchPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Dispatch') 
SET @AltDispatchPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'AlternateDispatch') -- TFS : 105   
SET @FaxPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Fax')    
SET @OfficePhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Office')    
SET @CellPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Cell')  -- CR: 1226  
SET @PrimaryServiceProductSubTypeID = (Select ID From dbo.ProductSubType Where Name = 'PrimaryService')    
SET @ActiveVendorStatusID = (SELECT ID FROM dbo.VendorStatus WHERE Name = 'Active')    
SET @DoNotUseVendorStatusID = (SELECT ID FROM dbo.VendorStatus WHERE Name = 'DoNotUse')    
SET @ActiveVendorLocationStatusID = (SELECT ID FROM dbo.VendorLocationStatus WHERE Name = 'Active')    
  
    
/* Get list of ALL vendors within the Search Radius of the service location */  
SELECT V.ID VendorID  
      ,vl.ID VendorLocationID  
      ,NULL AS VendorLocationVirtualID  
      ,vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) Distance  
      ,vl.GeographyLocation  
      ,vl.Latitude  
      ,vl.Longitude  
INTO #tmpVendorLocation  
FROM VendorLocation vl  
JOIN Vendor V ON vl.VendorID = V.ID  
WHERE V.IsActive = 1 AND V.VendorStatusID = @ActiveVendorStatusID  
AND vl.IsActive = 1 AND vl.VendorLocationStatusID = @ActiveVendorLocationStatusID  
AND vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) <= @SearchRadiusMiles * 1609.344    
--If using zip codes, only include if zip code is serviced by the vendor location
AND (
	ISNULL(vl.IsUsingZipCodes,0) = 0
	OR
	@ServiceLocationPostalCode IS NULL
	OR
	@ServiceLocationPostalCode = 'null' --Work around for ODIS bug, TFS #456
	OR
	EXISTS(SELECT * FROM VendorLocationPostalCode vlzip
			WHERE vlZip.VendorLocationID = vl.ID AND vlZip.PostalCode = @ServiceLocationPostalCode)
	)
  
-- Include search of related Vendor Location virtual mapping points   
INSERT INTO #tmpVendorLocation  
SELECT V.ID VendorID  
      ,vl.ID VendorLocationID  
      ,vlv.ID VendorLocationVirtualID  
      ,vlv.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) Distance  
      ,vlv.GeographyLocation  
      ,vlv.Latitude  
      ,vlv.Longitude  
FROM VendorLocation vl  
JOIN Vendor V ON vl.VendorID = V.ID  
JOIN VendorLocationVirtual vlv on vlv.VendorLocationID = vl.ID --AND vlv.IsActive = 1  
WHERE V.IsActive = 1 AND V.VendorStatusID = @ActiveVendorStatusID  
AND vl.IsActive = 1 AND vl.VendorLocationStatusID = @ActiveVendorLocationStatusID  
AND vlv.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) <= @SearchRadiusMiles * 1609.344    
--If using zip codes, only include if zip code is serviced by the vendor location
AND (
	ISNULL(vl.IsUsingZipCodes,0) = 0
	--OR --Check for at least one zip code if vendor location configured to use zip codes
	--(ISNULL(vl.IsUsingZipCodes,0) = 1 AND NOT EXISTS(SELECT * FROM VendorLocationPostalCode vlzip
	--		WHERE vlZip.VendorLocationID = vl.ID))
	OR
	EXISTS(SELECT * FROM VendorLocationPostalCode vlzip
			WHERE vlZip.VendorLocationID = vl.ID AND vlZip.PostalCode = @ServiceLocationPostalCode)
	)
  
/* Index physical locations */  
CREATE NONCLUSTERED INDEX [IDX_tmpVendors_VendorLocationID] ON #tmpVendorLocation  
([VendorLocationID] ASC)  
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]  
  
/* Reduce list to only the closest location if the vendor has multiple physical or virtual locations within the Search Radius */  
DELETE #tmpVendorLocation   
FROM #tmpVendorLocation vl1  
WHERE NOT EXISTS (  
      SELECT *  
      FROM #tmpVendorLocation vl2  
      JOIN (  
            SELECT VendorID, MIN(Distance) Distance  
            FROM #tmpVendorLocation   
            GROUP BY VendorID  
            ) ClosestLocation   
            ON ClosestLocation.VendorID = vl2.VendorID and ClosestLocation.Distance = vl2.Distance  
      WHERE vl1.VendorLocationID = vl2.VendorLocationID AND  
            vl1.Distance = vl2.Distance  
      )  

  
/* For the vendor locations within the Search Radius determine vendors that can provide the desired service */  
INSERT INTO #IspDetail   
SELECT     
            v.ID VendorID    
            ,vl.ID VendorLocationID   
            ,tvl.VendorLocationVirtualID   
            ,CASE WHEN tvl.VendorLocationVirtualID IS NOT NULL THEN tvl.Latitude ELSE vl.Latitude END Latitude    
            ,CASE WHEN tvl.VendorLocationVirtualID IS NOT NULL THEN tvl.Longitude ELSE vl.Longitude END Longitude    
            ,v.Name + CASE WHEN PreferredVendors.VendorID IS NOT NULL THEN ' (P)' ELSE '' END VendorName
            ,v.VendorNumber    
            ,CASE WHEN v.VendorNumber IS NULL THEN 'Internet' ELSE '' END AS [Source]  
			,CAST(CASE WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted'     
            ELSE NULL    
            END AS nvarchar(50)) AS ContractStatus 
            ---- Have to check the if the selected product is a contract rate since the vendor can be contracted but not have a rate set for the service (bad data)    
            --,CAST(CASE WHEN VendorLocationRates.Price IS NOT NULL OR DefaultVendorRates.Price IS NOT NULL THEN 'Contracted'     
            --ELSE NULL    
            --END AS nvarchar(50)) AS ContractStatus    
            --,ph.PhoneNumber DispatchPhoneNumber   
		   ,(SELECT Top 1 PhoneNumber  
			FROM dbo.[PhoneEntity]   
			WHERE RecordID = vl.ID   
			AND EntityID = @VendorLocationEntityID  
			AND PhoneTypeID = @DispatchPhoneTypeID  
			ORDER BY ID DESC   
			 ) AS DispatchPhoneNumber
			 ,(SELECT Top 1 PhoneNumber  
			FROM dbo.[PhoneEntity]   
			WHERE RecordID = vl.ID   
			AND EntityID = @VendorLocationEntityID  
			AND PhoneTypeID = @AltDispatchPhoneTypeID  
			ORDER BY ID DESC   
			 ) AS AlternateDispatchPhoneNumber  -- TFS : 105
            ,v.AdministrativeRating   
            -- Ignore time while comparing dates here  
            ,CASE WHEN v.InsuranceExpirationDate >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0) THEN 'Insured'   
            ELSE 'Not Insured' END InsuranceStatus    
            ,vl.[IsOpen24Hours]    
            ,vl.BusinessHours    
            ,vl.DispatchNote AS Comment    
            ,ROUND(tvl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END)/1609.344,1) EnrouteMiles    
            ,@ServiceMiles as ServiceMiles    
            ,ROUND(tvl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' OR @ProductCategoryID <> 1 THEN @ServiceLocation ELSE @DestinationLocation END)/1609.344,1) ReturnMiles    
            ,vlp.ProductID    
            ,p.Name ProductName    
            ,vlp.Rating ProductRating    
            ,prt.RateTypeID     
            ,COALESCE(VendorLocationRates.Price, DefaultVendorRates.Price, MarketRates.Price, 0) AS RatePrice  
            ,COALESCE(VendorLocationRates.Quantity, DefaultVendorRates.Quantity, MarketRates.Quantity, 0) AS RateQuantity  
            --,CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Price    
            --            WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Price    
            --            ELSE MarketRates.Price     
            --END AS RatePrice    
            --,CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Quantity    
            --            WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Quantity    
            --            ELSE MarketRates.Quantity     
            --END AS RateQuantity    
            , rt.Name RateTypeName    
            , rt.UnitOfMeasure RateUnitOfMeasure    
            , rt.UnitOfMeasureSource RateUnitOfMeasureSource    
            ,CASE WHEN p.ID = ISNULL(@PrimaryProductID,0) THEN 1   
                        ELSE 0   
            END IsProductMatch
            ,Case WHEN PreferredVendors.VendorID IS NOT NULL THEN 1 ELSE 0 END IsPreferred
FROM  #tmpVendorLocation tvl  
JOIN  dbo.VendorLocation vl on tvl.VendorLocationID = vl.ID   
JOIN  dbo.Vendor v  ON vl.VendorID = v.ID    
JOIN  dbo.VendorLocationProduct vlp ON vl.ID = vlp.VendorLocationID AND vlp.IsActive = 1  
JOIN  dbo.Product p ON p.ID = vlp.ProductID    
JOIN  dbo.ProductRateType prt ON prt.ProductID = p.ID AND   prt.IsOptional = 0   
JOIN  dbo.RateType rt ON prt.RateTypeID = rt.ID    
LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON
	v.ID = ContractedVendors.VendorID    
LEFT OUTER JOIN dbo.fnGetPreferredVendorsByVehicleCategory() PreferredVendors ON
	v.ID = PreferredVendors.VendorID AND p.VehicleCategoryID = PreferredVendors.VehicleCategoryID
LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() VendorLocationRates ON   
      v.ID = VendorLocationRates.VendorID AND   
      p.ID = VendorLocationRates.ProductID AND   
      prt.RateTypeID = VendorLocationRates.RateTypeID AND  
      VendorLocationRates.VendorLocationID = vl.ID   
LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() DefaultVendorRates ON   
      v.ID = DefaultVendorRates.VendorID AND   
      p.ID = DefaultVendorRates.ProductID AND   
      prt.RateTypeID = DefaultVendorRates.RateTypeID AND  
      DeFaultVendorRates.VendorLocationID IS NULL  
LEFT OUTER JOIN #MarketRates MarketRates ON p.ID = MarketRates.ProductID And MarketRates.RateTypeID = prt.RateTypeID 
	--TP: Added condition to prevent backfill of market rates for missing contracted vendor rates 
	AND NOT EXISTS (
		Select * 
		From [dbo].[fnGetCurrentProductRatesByVendorLocation]() r2 
		Where r2.VendorID = v.ID 
			and r2.ProductID = p.ID 
			and r2.RateName IN ('Base','Hourly')
			and r2.Price <> 0) 
    
WHERE   
(VendorLocationRates.RateTypeID IS NOT NULL OR DefaultVendorRates.Price IS NOT NULL OR MarketRates.Price IS NOT NULL)    
AND           
      (  
            (   vlp.ProductID = @PrimaryProductID  
                  AND  
                -- Additional condition to include tire stores if tire service and tire delivery selected  
                  (   
                    @IsTireDelivery = 0  
                    OR  
                    --If Tire delivery then Tire Repair must also have Tire Store Attributes  
                    (@IsTireDelivery = 1    
                              AND EXISTS (  
                              SELECT * FROM VendorLocationProduct vlp1   
                              JOIN Product p1 ON vlp1.ProductID = p1.ID and p1.ProductCategoryID = 2 and p1.ProductSubTypeID = 10  
                              WHERE vlp1.VendorLocationID = vl.ID)  
                    )   
                  )   
            --Additional condition for Mobile Mechanic service  
                  OR  
        (@ProductCategoryID = 8 AND vlp.ProductID IN (SELECT ID FROM Product WHERE ProductCategoryID = 8))  
  
            )  
      AND   
            -- Code to require towing service for possible tow  
            ( @SecondaryProductID IS NULL   
            OR EXISTS (SELECT * FROM VendorLocationProduct vlp2 WHERE vlp2.VendorLocationID = vl.ID and vlp2.ProductID = @SecondaryProductID)  
            )  
      )  
  
  
-- Remove duplicate results for vendorlocations that are caused by multiple product matches   
-- TP: 4/21 Removed previous record deletion logic that was no longer needed and added this logic to fix issue with mobile mechanic vendors appearing multiple times  
DELETE ISPDetail1  
FROM #IspDetail ISPDetail1   
WHERE NOT EXISTS (  
      SELECT *  
      FROM   
            (    
            Select VendorLocationID, Min(ProductID) MinProductID  
            FROM #IspDetail  
            Group by VendorLocationID   
            ) ISPDetail2   
      WHERE ISPDetail1.VendorLocationID = ISPDetail2.VendorLocationID   
            AND ISPDetail1.ProductID  = ISPDetail2.MinProductID  
      )   
  
    
 -- Select list of 'Do Not Use' vendors within the 'Do Not Use' search radius of the service location   
INSERT INTO #ISPDoNotUse   
SELECT      v.ID VendorID    
            ,vl.ID VendorLocationID   
            ,NULL   
            ,vl.Latitude    
            ,vl.Longitude    
            ,v.Name VendorName    
            ,v.VendorNumber    
            ,CASE WHEN v.VendorNumber IS NULL THEN 'Internet'   
                        ELSE 'Database'   
            END AS [Source]    
            ,'Not Contracted' AS ContractStatus    
            ,addr.Line1 Address1    
            ,addr.Line2 Address2    
            ,addr.City    
            ,addr.StateProvince    
            ,addr.PostalCode    
            ,addr.CountryCode    
            ,ph.PhoneNumber DispatchPhoneNumber 
			,aph.PhoneNumber AlternateDispatchPhoneNumber -- TFS : 105   
            ,'' AS FaxPhoneNumber    
            ,'' AS OfficePhoneNumber   
            ,'' AS CellPhoneNumber  -- CR : 1226  
            ,0 AS AdministrativeRating    
            ,'' AS InsuranceStatus    
            ,'' AS BusinessHours    
            ,'' AS PaymentTypes  
            ,'' AS Comment    
            ,0 AS ProductID    
            ,'' AS ProductName    
            ,NULL AS ProductRating    
            ,ROUND(vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END)/1609.344,1) EnrouteMiles    
            ,NULL AS EnrouteTimeMinutes  
            ,NULL AS ServiceMiles    
            ,NULL AS ServiceTimeMinutes  
            ,NULL AS ReturnMiles    
            ,NULL AS ReturnTimeMinutes  
            ,NULL AS EstimatedHours    
            ,NULL AS BaseRate  
            ,NULL AS HourlyRate  
            ,NULL AS EnrouteRate  
            ,NULL AS EnrouteFreeMiles  
            ,NULL AS ServiceRate  
            ,NULL AS ServiceFreeMiles  
            ,NULL AS EstimatedPrice    
            ,-99999 AS WiseScore    
            ,'DoNotUse' AS CallStatus    
            ,'' AS RejectReason    
            ,'' AS RejectComment    
            ,0 AS IsPossibleCallback    
FROM  dbo.VendorLocation vl     
JOIN  dbo.Vendor v ON vl.VendorID = v.ID     
JOIN  dbo.[AddressEntity] addr ON addr.EntityID = @VendorLocationEntityID AND addr.RecordID = vl.ID AND addr.AddressTypeID = @BusinessAddressTypeID    
-- TP - Eliminate join duplication due to multiple dispatch numbers  
JOIN (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @DispatchPhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) ph ON ph.RecordID = vl.ID  
 LEFT JOIN (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @AltDispatchPhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) aph ON aph.RecordID = vl.ID     
WHERE v.IsActive = 'TRUE'    
AND         v.VendorStatusID = @DoNotUseVendorStatusID  
AND         vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) <= @DNUSearchRadiusMiles * 1609.344    
AND         @IncludeDoNotUse = 'TRUE'    
ORDER BY vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END)    
  
-- DEBUG : SELECT * FROM #IspDetail  
  
-- Create ISP Selection data set from ISP Details, adding additional data items and related contact logs   
INSERT INTO @ISPSelection   
SELECT      ISP.VendorID    
            ,ISP.VendorLocationID    
            ,ISP.VendorLocationVirtualID  
            ,ISP.Latitude    
            ,ISP.Longitude    
            ,ISP.VendorName + CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN ' (virtual)' ELSE '' END AS VendorName  
            ,ISP.VendorNumber    
            ,ISP.[Source]    
            ,ISNULL(MAX(ISP.ContractStatus), 'Not Contracted') ContractStatus    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationAddress ELSE addr.Line1 END Address1    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN NULL ELSE addr.Line2 END Address2    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationCity ELSE addr.City END City    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationStateProvince ELSE addr.StateProvince END StateProvince    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationPostalCode ELSE addr.PostalCode END PostalCode    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationCountryCode ELSE addr.CountryCode END CountryCode    
            ,ISP.DispatchPhoneNumber
			,ISP.AlternateDispatchPhoneNumber -- TFS: 105   
            ,FaxPh.PhoneNumber FaxPhoneNumber  
            ,ph.PhoneNumber OfficePhoneNumber  
            ,cph.PhoneNumber CellPhoneNumber --  CR : 1226  
            ,ISP.AdministrativeRating    
            ,ISP.InsuranceStatus    
            ,CASE WHEN ISP.[IsOpen24Hours] = 1 THEN '24/7'   
            ELSE ISNULL(ISP.BusinessHours,'') END AS BusinessHours    
            ,PaymentTypes.List AS PaymentTypes  
            ,ISP.Comment    
            ,ISP.ProductID    
            ,ISP.ProductName    
            ,ISP.ProductRating    
            ,ISP.EnrouteMiles    
            ,(ISP.EnrouteMiles/40)*60 AS EnrouteTimeMinutes  
            ,ISP.ServiceMiles    
            ,(ISP.ServiceMiles/40)*60 AS ServiceTimeMinutes  
            ,ISP.ReturnMiles    
            ,(ISP.ReturnMiles/40)*60 AS ReturnTimeMinutes  
            ,MAX(1.5 + ROUND((ISP.EnrouteMiles + ISP.ServiceMiles + ISP.ReturnMiles)/40,2)) AS EstimatedHours    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Base' THEN ISP.RatePrice ELSE 0 END) AS BaseRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Hourly' THEN ISP.RatePrice ELSE 0 END) AS HourlyRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Enroute' THEN ISP.RatePrice ELSE 0 END) AS EnrouteRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'EnrouteFree' THEN ISP.RateQuantity ELSE 0 END) AS EnrouteFreeMiles    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Service' THEN ISP.RatePrice ELSE 0 END) AS ServiceRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'ServiceFree' THEN ISP.RateQuantity ELSE 0 END) AS ServiceFreeMiles    
            ,ROUND(SUM(CASE     
                                    WHEN ISP.RateUnitOfMeasure = 'Each' THEN ISP.RatePrice     
                                    WHEN ISP.RateUnitOfMeasure = 'Hour' THEN ISP.RatePrice * (1.5 + ROUND((ISP.EnrouteMiles + ISP.ServiceMiles + ISP.ReturnMiles)/40,2))    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity = 0 THEN ISP.RatePrice * ISP.EnrouteMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity = 0 THEN ISP.RatePrice * ISP.ServiceMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.EnrouteMiles THEN ISP.EnrouteMiles ELSE ISP.RateQuantity END)
    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.ServiceMiles THEN ISP.ServiceMiles ELSE ISP.RateQuantity END) 
   
                                    ELSE 0   
                              END),2) EstimatedPrice    
            ,ROUND((AdministrativeRating*@AdminWeight)+(ProductRating*@PerformWeight)-    
                        (SUM(CASE     
                                    WHEN ISP.RateUnitOfMeasure = 'Each' THEN ISP.RatePrice     
                                    WHEN ISP.RateUnitOfMeasure = 'Hour' THEN ISP.RatePrice * (1.5 + ROUND((ISP.EnrouteMiles + ISP.ServiceMiles + ISP.ReturnMiles)/40,2))    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity = 0 THEN ISP.RatePrice * ISP.EnrouteMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity = 0 THEN ISP.RatePrice * ISP.ServiceMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.EnrouteMiles THEN ISP.EnrouteMiles ELSE ISP.RateQuantity END) 
   
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.ServiceMiles THEN ISP.ServiceMiles ELSE ISP.RateQuantity END) 
   
                                    ELSE 0   
                              END) * @CostWeight),2) as WiseScore    
            ,CASE WHEN ContactLogAction.VendorLocationID IS NULL THEN 'NotCalled'    
                        WHEN ISNULL(ContactLogAction.Name,'') = '' THEN 'Called'    
                        WHEN ISNULL(ContactLogAction.Name,'') = 'Accepted' THEN 'Accepted'    
                        ELSE 'Rejected'   
            END AS CallStatus    
            ,ContactLogAction.[Description] RejectReason    
            ,ContactLogAction.[Comments] RejectComment    
            ,ISNULL(ContactLogAction.IsPossibleCallback,0) AS IsPossibleCallback    
            ,MAX(ISP.IsPreferred) IsPreferred
FROM  #IspDetail ISP    
LEFT OUTER JOIN  dbo.[VendorLocationVirtual] vlv ON vlv.ID = ISP.VendorLocationVirtualID  
LEFT OUTER JOIN  dbo.[AddressEntity] addr ON addr.EntityID = @VendorLocationEntityID AND addr.RecordID = ISP.VendorLocationID AND addr.AddressTypeID = @BusinessAddressTypeID    
-- TP - Eliminate join duplication due to multiple Fax numbers  
LEFT OUTER JOIN  (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @FaxPhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) Faxph ON Faxph.RecordID = ISP.VendorLocationID     
-- TP - Eliminate join duplication due to multiple Office numbers  
LEFT OUTER JOIN  (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @OfficePhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) ph ON ph.RecordID = ISP.VendorLocationID     
-- TP - Eliminate join duplication due to multiple Cell numbers  
LEFT OUTER JOIN  (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @CellPhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) cph ON cph.RecordID = ISP.VendorLocationID     
-- Get last ContactLog result for the current sevice request for the ISP  
LEFT OUTER JOIN (    
                              SELECT      LastISPContactLog.VendorLocationID    
                                          ,LastContactLogAction.Name    
                                          ,LastContactLogAction.[Description]    
                                          ,cl.Comments    
                                          ,ISNULL(cl.IsPossibleCallback,0) IsPossibleCallback    
                              FROM  dbo.ContactLog cl    
                              JOIN (  
                                          SELECT      ISPcll.RecordID VendorLocationID, MAX(cl.ID) ID   
                                          FROM  dbo.ContactLog cl    
                                          JOIN  dbo.ContactLogLink SRcll ON SRcll.ContactLogID = cl.ID AND SRcll.EntityID = @ServiceRequestEntityID AND SRcll.RecordID = @ServiceRequestID     
                                          JOIN dbo.ContactLogLink ISPcll ON ISPcll.ContactLogID = cl.ID AND ISPcll.EntityID = @VendorLocationEntityID    
                                          JOIN dbo.ContactLogReason clr ON clr.ContactLogID = cl.ID    
                                          JOIN dbo.ContactReason cr ON cr.ID = clr.ContactReasonID    
                                          WHERE cr.Name = 'ISP selection'    
                                          GROUP BY ISPcll.RecordID  
                                    ) LastISPContactLog ON LastISPContactLog.ID = cl.ID  
                              LEFT OUTER JOIN (    
                                          SELECT      cla.ContactLogID  
                                                      ,ca.Name  
                                                      ,ca.[Description]  
                                                      ,cla.Comments    
                                          FROM  dbo.ContactLogAction cla    
                                          JOIN  dbo.ContactAction ca ON ca.ID = cla.ContactActionID    
                                          JOIN  (    
                                                            SELECT      cla1.ContactLogID, MAX(cla1.ID) ID    
                                                            FROM      dbo.ContactLogAction cla1    
                                                            GROUP BY cla1.ContactLogID    
                                                      ) MaxContactLogAction ON MaxContactLogAction.ContactLogID = cla.ContactLogID AND MaxContactLogAction.ID = cla.ID    
                                    ) LastContactLogAction ON LastContactLogAction.ContactLogID = cl.ID   
                        ) ContactLogAction ON ContactLogAction.VendorLocationID = ISP.VendorLocationID    
-- Get Payment Types accepted by this vendor                        
LEFT OUTER JOIN (    
      SELECT  
         pt1.VendorLocationID,  
         List = stuff((SELECT ( ', ' + [Description] )  
                    FROM (Select vlpt.VendorLocationID, pt.Name, pt.Sequence, pt.[Description]   
                              From VendorLocationPaymentType vlpt  
                              Join PaymentType pt on vlpt.PaymentTypeID = pt.ID  
                              ) pt2  
                    WHERE pt1.VendorLocationID = pt2.VendorLocationID  
                    ORDER BY VendorLocationID, pt2.Sequence  
                        FOR XML PATH( '' )  
                  ), 1, 1, '' )  
                  FROM   
                        (Select vlpt.VendorLocationID, pt.Name  
                        From VendorLocationPaymentType vlpt  
                        Join #IspDetail ISP on ISP.VendorLocationID = vlpt.VendorLocationID  
                        Join PaymentType pt on vlpt.PaymentTypeID = pt.ID  
                        ) pt1  
      GROUP BY pt1.VendorLocationID  
      ) PaymentTypes ON PaymentTypes.VendorLocationID = ISP.VendorLocationID  
GROUP BY    
                  ISP.VendorID    
                  ,ISP.VendorLocationID    
                  ,ISP.VendorLocationVirtualID  
                  ,ISP.Latitude    
                  ,ISP.Longitude    
                  ,ISP.VendorName    
                  ,ISP.VendorNumber    
                  ,ISP.[Source]    
                  ,addr.Line1     
                  ,addr.Line2     
                  ,addr.City    
                  ,addr.StateProvince    
                  ,addr.PostalCode    
                  ,addr.CountryCode    
                  ,vlv.LocationAddress  
                  ,vlv.LocationCity    
                  ,vlv.LocationStateProvince    
                  ,vlv.LocationPostalCode    
                  ,vlv.LocationCountryCode    
                  ,ISP.DispatchPhoneNumber 
				  ,ISP.AlternateDispatchPhoneNumber   -- TFS: 105
                  ,Faxph.PhoneNumber  
                  ,ph.PhoneNumber   
                  ,cph.PhoneNumber   
                  ,ISP.AdministrativeRating    
                  ,ISP.InsuranceStatus    
                  ,ISP.[IsOpen24Hours]    
                  ,ISP.BusinessHours    
                  ,ISP.Comment    
                  ,ISP.ProductID    
                  ,ISP.ProductName    
                  ,ISP.ProductRating    
                  ,ISP.EnrouteMiles    
                  ,ISP.ServiceMiles    
                  ,ISP.ReturnMiles    
                  ,ISP.IsProductMatch    
                  ,ContactLogAction.VendorLocationID    
                  ,ContactLogAction.[Description]     
                  ,ContactLogAction.Comments     
                  ,ISNULL(ContactLogAction.Name ,'')  
                  ,ContactLogAction.IsPossibleCallback    
                  ,PaymentTypes.List  
ORDER BY   
                  WiseScore DESC  
                  ,EstimatedPrice  
                  ,EnrouteMiles  
                  ,ProductRating DESC    
   
 -- Log ISP SELECTION Results (first resultset).  
INSERT INTO ISPSelectionLog  
            ([VendorID]  
           ,[VendorLocationID]  
           ,[VendorLocationVirtualID]  
           ,[SelectionOrder]  
           ,[ServiceRadiusMiles]  
           ,[Latitude]  
           ,[Longitude]  
           ,[VendorName]  
           ,[VendorNumber]  
           ,[Source]  
           ,[ContractStatus]  
           ,[Address1]  
           ,[Address2]  
           ,[City]  
           ,[StateProvince]  
           ,[PostalCode]  
           ,[CountryCode]  
           ,[DispatchPhoneNumber]
		   ,[AlternateDispatchPhoneNumber] -- TFS: 105  
           ,[FaxPhoneNumber]  
           ,[OfficePhoneNumber]  
           ,[CellPhoneNumber]  
           ,[AdministrativeRating]  
           ,[InsuranceStatus]  
           ,[BusinessHours]  
           ,[PaymentTypes]  
           ,[Comment]  
           ,[ProductID]  
           ,[ProductName]  
           ,[ProductRating]  
           ,[EnrouteMiles]  
           ,[EnrouteTimeMinutes]  
           ,[ServiceMiles]  
           ,[ServiceTimeMinutes]  
           ,[ReturnMiles]  
           ,[ReturnTimeMinutes]  
           ,[EstimatedHours]  
           ,[BaseRate]  
           ,[HourlyRate]  
           ,[EnrouteRate]  
           ,[EnrouteFreeMiles]  
           ,[ServiceRate]  
           ,[ServiceFreeMiles]  
           ,[EstimatedPrice]  
           ,[WiseScore]  
           ,[CallStatus]  
           ,[RejectReason]  
           ,[RejectComment]  
           ,[IsPossibleCallback]  
           ,[ProductSearchRadiusMiles]  
           ,[IsInProductSearchRadius]  
           ,[ServiceRequestID]  
           ,[LogTime]  
           ,[Resultset])  
SELECT   
            VendorID    
            ,VendorLocationID    
            ,VendorLocationVirtualID  
            ,row_number() OVER(ORDER BY WiseScore DESC  
                  ,EstimatedPrice  
                  ,EnrouteMiles  
                  ,ProductRating DESC) AS SelectionOrder  
            ,@ProductSearchRadiusMiles  
            ,Latitude    
            ,Longitude    
            ,VendorName    
            ,VendorNumber    
            ,[Source]    
            ,ContractStatus    
            ,Address1    
            ,Address2    
            ,City    
            ,StateProvince    
            ,PostalCode    
            ,CountryCode    
            ,DispatchPhoneNumber   
			,AlternateDispatchPhoneNumber -- TFS: 105 
            ,FaxPhoneNumber  
            ,OfficePhoneNumber    
            ,CellPhoneNumber  
            ,AdministrativeRating    
            ,InsuranceStatus    
            ,BusinessHours    
            ,PaymentTypes  
            ,Comment    
            ,ProductID    
            ,ProductName    
            ,ProductRating    
            ,EnrouteMiles    
            ,EnrouteTimeMinutes  
            ,ServiceMiles  
            ,ServiceTimeMinutes  
            ,ReturnMiles    
            ,ReturnTimeMinutes  
            ,EstimatedHours    
            ,BaseRate  
            ,HourlyRate  
            ,EnrouteRate  
            ,EnrouteFreeMiles  
            ,ServiceRate  
            ,ServiceFreeMiles  
            ,EstimatedPrice    
            ,WiseScore    
            ,CallStatus    
			,RejectReason    
            ,RejectComment    
            ,IsPossibleCallback  
            ,@ProductSearchRadiusMiles AS ProductSearchRadiusMiles  
            ,NULL AS IsInProductSearchRadius  
            ,@ServiceRequestID  
            ,@now  
            ,'ISPSELECTION'    
 FROM @ISPSelection   
 WHERE @LogISPSelection = 1  
  
   
-- Combine ISP Selection and ISP Do Not use results     
-- Collect products in a separate query   
INSERT INTO @ISPSelectionFinalResults    
SELECT      TOP 50    
            I.VendorID    
            ,I.VendorLocationID    
            ,VendorLocationVirtualID  
            ,Latitude    
            ,Longitude    
            ,VendorName    
            ,VendorNumber    
            ,[Source]    
            ,ContractStatus    
            ,Address1    
            ,Address2    
            ,City    
            ,StateProvince    
            ,PostalCode    
            ,CountryCode    
            ,DispatchPhoneNumber  
			,AlternateDispatchPhoneNumber -- TFS: 105  
            ,FaxPhoneNumber  
            ,OfficePhoneNumber    
            ,CellPhoneNumber  
            ,AdministrativeRating    
            ,InsuranceStatus    
            ,BusinessHours    
            ,PaymentTypes  
            ,Comment    
            ,ProductID    
            ,ProductName    
            ,ProductRating    
            ,EnrouteMiles    
            ,EnrouteTimeMinutes  
            ,ServiceMiles  
            ,ServiceTimeMinutes  
            ,ReturnMiles    
            ,ReturnTimeMinutes  
            ,EstimatedHours    
            ,BaseRate  
            ,HourlyRate  
            ,EnrouteRate  
            ,EnrouteFreeMiles  
            ,ServiceRate  
            ,ServiceFreeMiles  
            ,EstimatedPrice    
            ,WiseScore    
            ,CallStatus    
            ,RejectReason    
            ,RejectComment    
            ,IsPossibleCallback  
            ,'' AS [AllServices]  
            ,@ProductSearchRadiusMiles AS ProductSearchRadiusMiles  
            ,CASE WHEN (I.EnrouteMiles <= @ProductSearchRadiusMiles) OR Top3Contracted.VendorLocationID IS NOT NULL THEN 1 ELSE 0 END AS IsInProductSearchRadius   
            ,IsPreferred
FROM  @ISPSelection I  
-- Identify top 3 contracted vendors  
LEFT OUTER JOIN (  
      SELECT TOP 3 VendorLocationID  
      FROM @ISPSelection  
      WHERE ContractStatus = 'Contracted'  
      ORDER BY EnrouteMiles ASC, WiseScore DESC  
      ) Top3Contracted ON Top3Contracted.VendorLocationID = I.VendorLocationID  
-- Apply product availability filtering (@ProductIDs list)  
WHERE EXISTS      (  
                              SELECT      *  
                              FROM  VendorLocation vl  
                              JOIN  VendorLocationProduct vlp   
                              ON          vlp.VendorLocationID = vl.ID  
                              JOIN  Product p on p.ID = vlp.ProductID   
                              WHERE vl.ID = I.VendorLocationID  
                              AND         (     ISNULL(@productIDs,'') = ''   
                                                OR    
                                                p.ID IN (SELECT item from [dbo].[fnSplitString](@productIDs,','))  
                                          )  
                        )  
  
ORDER BY IsPreferred DESC, WiseScore DESC, EstimatedPrice, EnrouteMiles, ProductRating DESC    
  
/* Add 'Do Not Use' vendors to the results (if selected above) */  
INSERT INTO @ISPSelectionFinalResults  
SELECT      TOP 100    
            I.VendorID    
            ,VendorLocationID    
            ,VendorLocationVirtualID  
            ,Latitude    
            ,Longitude    
            ,VendorName    
            ,VendorNumber    
            ,[Source]    
            ,ContractStatus    
            ,Address1    
            ,Address2    
            ,City    
            ,StateProvince    
            ,PostalCode    
            ,CountryCode    
            ,DispatchPhoneNumber  
			,AlternateDispatchPhoneNumber -- TFS: 105  
            ,FaxPhoneNumber  
            ,OfficePhoneNumber    
            ,CellPhoneNumber  
            ,AdministrativeRating    
            ,InsuranceStatus    
            ,BusinessHours    
            ,PaymentTypes  
            ,Comment    
            ,ProductID    
            ,ProductName    
            ,ProductRating    
            ,EnrouteMiles    
            ,EnrouteTimeMinutes  
            ,ServiceTimeMinutes  
            ,ReturnMiles    
            ,ReturnTimeMinutes  
            ,EstimatedHours    
            ,BaseRate  
            ,HourlyRate  
            ,EnrouteRate  
            ,EnrouteFreeMiles  
            ,ServiceRate  
            ,ServiceMiles  
            ,ServiceFreeMiles  
            ,EstimatedPrice    
            ,WiseScore    
            ,CallStatus    
            ,RejectReason    
            ,RejectComment    
            ,IsPossibleCallback  
            , '' AS [AllServices]   
            ,@ProductSearchRadiusMiles AS ProductSearchRadiusMiles  
            ,0 AS IsInProductSearchRadius  
            ,0 AS IsPreferred
FROM  #ISPDoNotUse I  
ORDER BY WiseScore DESC, EstimatedPrice, EnrouteMiles, ProductRating DESC    
   
-- Get all the products for the vendors collected in the above query.  
;WITH wVLP  
AS  
(  
      SELECT      vl.VendorID,  
                  vl.ID,   
                  [dbo].[fnConcatenate](p.Name) AS AllServices  
      FROM  VendorLocation vl  
      JOIN  VendorLocationProduct vlp on vlp.VendorLocationID = vl.ID  
      JOIN  Product p on p.ID = vlp.ProductID  
      JOIN  @ISPSelectionFinalResults ISP ON vl.ID = ISP.VendorLocationID AND vl.VendorID = ISP.VendorID  
      WHERE vlp.IsActive = 1  
      GROUP BY vl.VendorID,vl.ID  
)  
  
 -- Include 'All Services' provided by the selected ISPs in the results  
UPDATE      @ISPSelectionFinalResults  
SET         AllServices = W.AllServices  
FROM  wVLP W,  
            @ISPSelectionFinalResults ISP  
WHERE W.VendorID = ISP.VendorID  
AND         W.ID = VendorLocationID  
  
-- Remove Black Listed vendors from the result for this member  
DELETE FROM @ISPSelectionFinalResults  
WHERE VendorID IN (  
                                    SELECT VendorID  
                                    FROM MembershipBlackListVendor  
                                    WHERE MembershipID = @MembershipID  
                              )  
  
/* Insert reults into ISP Selection log */  
INSERT INTO ISPSelectionLog  
            ([VendorID]  
           ,[VendorLocationID]  
           ,[VendorLocationVirtualID]  
           ,[SelectionOrder]  
           ,[ServiceRadiusMiles]  
           ,[Latitude]  
           ,[Longitude]  
           ,[VendorName]  
           ,[VendorNumber]  
           ,[Source]  
           ,[ContractStatus]  
           ,[Address1]  
           ,[Address2]  
           ,[City]  
           ,[StateProvince]  
           ,[PostalCode]  
           ,[CountryCode]  
           ,[DispatchPhoneNumber]
		   ,[AlternateDispatchPhoneNumber] -- TFS: 105  
           ,[FaxPhoneNumber]  
           ,[OfficePhoneNumber]  
           ,[CellPhoneNumber]  
           ,[AdministrativeRating]  
           ,[InsuranceStatus]  
           ,[BusinessHours]  
           ,[PaymentTypes]  
           ,[Comment]  
           ,[ProductID]  
           ,[ProductName]  
           ,[ProductRating]  
           ,[EnrouteMiles]  
           ,[EnrouteTimeMinutes]  
           ,[ServiceMiles]  
           ,[ServiceTimeMinutes]  
           ,[ReturnMiles]  
           ,[ReturnTimeMinutes]  
           ,[EstimatedHours]  
           ,[BaseRate]  
           ,[HourlyRate]  
           ,[EnrouteRate]  
           ,[EnrouteFreeMiles]  
           ,[ServiceRate]  
           ,[ServiceFreeMiles]  
           ,[EstimatedPrice]  
           ,[WiseScore]  
           ,[CallStatus]  
           ,[RejectReason]  
           ,[RejectComment]  
           ,[IsPossibleCallback]  
           ,[ProductSearchRadiusMiles]  
           ,[IsInProductSearchRadius]  
           ,[ServiceRequestID]  
           ,[LogTime]  
           ,[Resultset])  
SELECT ISP.VendorID    
            ,ISP.VendorLocationID   
            ,ISP.VendorLocationVirtualID   
            ,row_number() OVER(ORDER BY   
                  ISP.IsInProductSearchRadius DESC,  
                  ISP.WiseScore DESC,   
    ISP.EstimatedPrice,   
                  ISP.EnrouteMiles,   
                  ISP.ProductRating DESC) AS SelectionOrder  
            ,@ProductSearchRadiusMiles  
            ,Latitude    
            ,Longitude    
            ,VendorName    
            ,VendorNumber    
            ,[Source]    
            ,ContractStatus    
            ,Address1    
            ,Address2    
            ,City    
            ,StateProvince    
            ,PostalCode    
            ,CountryCode    
            ,DispatchPhoneNumber
			,AlternateDispatchPhoneNumber -- TFS: 105    
            ,FaxPhoneNumber  
            ,OfficePhoneNumber    
            ,CellPhoneNumber  
            ,AdministrativeRating    
            ,InsuranceStatus    
            ,BusinessHours    
            ,PaymentTypes  
            ,Comment    
            ,ProductID    
            ,ProductName    
            ,ProductRating    
            ,EnrouteMiles    
            ,EnrouteTimeMinutes  
            ,ServiceMiles  
            ,ServiceTimeMinutes  
            ,ReturnMiles    
            ,ReturnTimeMinutes  
            ,EstimatedHours    
            ,BaseRate  
            ,HourlyRate  
            ,EnrouteRate  
            ,EnrouteFreeMiles  
            ,ServiceRate  
            ,ServiceFreeMiles  
            ,EstimatedPrice    
            ,WiseScore    
            ,CallStatus    
            ,RejectReason    
            ,RejectComment    
            ,IsPossibleCallback  
            ,ProductSearchRadiusMiles  
            ,IsInProductSearchRadius  
            ,@ServiceRequestID  
            ,@now  
            ,'ISPSELECTION_FINAL'    
FROM @ISPSelectionFinalResults ISP  
WHERE @LogISPSelectionFinal = 1  
ORDER BY   
	  ISP.IsPreferred DESC,   
      ISP.IsInProductSearchRadius DESC,  
      ISP.WiseScore DESC,   
      ISP.EstimatedPrice,   
      ISP.EnrouteMiles,   
      ISP.ProductRating DESC   
  
/* Return results */  
SELECT      ISP.*   
FROM  @ISPSelectionFinalResults ISP  
ORDER BY      
	  ISP.IsPreferred DESC,
      ISP.IsInProductSearchRadius DESC,  
      ISP.WiseScore DESC,   
      ISP.EstimatedPrice,   
      ISP.EnrouteMiles,   
      ISP.ProductRating DESC   
  
DROP TABLE #IspDoNotUse  
DROP TABLE #IspDetail  
DROP TABLE #tmpVendorLocation  
DROP TABLE #MarketRates  
  
END  

GO
/*
	NP 02/03: Whatever the changes made to this SP has to be made to dms_Merge_Members_Search also
*/

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
 WHERE id = object_id(N'[dbo].[dms_Member_Products_Using_Category]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_Products_Using_Category] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- dms_Member_Products_Using_Category 897, 3
CREATE PROC [dbo].[dms_Member_Products_Using_Category](
	@memberID INT = NULL,
	@productCategoryID INT = NULL,
	@VIN nvarchar(50) = NULL
)
AS
BEGIN
IF (@productCategoryID IS NULL AND @VIN IS NULL)
BEGIN
	SELECT DISTINCT	ISNULL(REPLACE(RTRIM(
		COALESCE(p.Description, '') +
		COALESCE(', ' + pp.Description, '') +  
		COALESCE(', ' + pp.PhoneNumber, '') 
		), '  ', ' ')
		,'') AS [AdditionalProduct]
	, pp.Script AS [HelpText]
	
	FROM	MemberProduct mp (NOLOCK)
	JOIN	Membership ms (NOLOCK) ON mp.MembershipID = ms.ID
	JOIN	Product p (NOLOCK) ON p.ID = mp.ProductID
	JOIN	ProductProvider pp (NOLOCK) ON pp.ID = mp.ProductProviderID
	WHERE	(mp.MemberID = @memberID
				OR
				(mp.MemberID IS NULL AND ms.ID = (SELECT MembershipID FROM Member WHERE ID = @MemberID)))				
			
	ORDER BY [AdditionalProduct]
END
ELSE
BEGIN
	SELECT	DISTINCT ISNULL(REPLACE(RTRIM(
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
	ORDER BY [AdditionalProduct]
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
*  ---- for int, decimal, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Merge_Members_Search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Merge_Members_Search]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Merge_Members_Search] @whereClauseXML=N'<ROW><Filter FirstNameOperator="4" FirstNameValue="jeevan"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=NULL
--EXEC [dbo].[dms_Merge_Members_Search] @whereClauseXML=N'<ROW><Filter PhoneNumberOperator="2" PhoneNumberValue="8173078882"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
--EXEC [dbo].[dms_Merge_Members_Search] @whereClauseXML=N'<ROW><Filter MemberNumberOperator="2" MemberNumberValue="123"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
-- EXEC [dbo].[dms_Merge_Members_Search] @whereClauseXML=N'<ROW><Filter VINOperator="4" VINValue="K1234422323N1233"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3

CREATE PROCEDURE [dbo].[dms_Merge_Members_Search](   
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
	
	IF @programID IS NOT NULL
	BEGIN
	
	INSERT INTO #SearchPrograms (ProgramID, ProgramName, ClientID)
	SELECT ProgramID, ProgramName, ClientID
	--FROM [dbo].[fnc_GetMemberSearchPrograms](9) --@programID)
	FROM [dbo].[fnc_GetMemberSearchPrograms] (@programID)
	
	END
	ELSE
	BEGIN
		INSERT INTO #SearchPrograms (ProgramID, ProgramName, ClientID)
	    SELECT ID,Name,ClientID FROM Program
	END
	
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
					 (@memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%')
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
					 (@memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%')
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
					 ( @memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%')
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
					 ( @memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%')
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
	

	--INSERT INTO @VendorsInsuranceExpiring
	--SELECT	ID 
	--FROM	Vendor WITH (NOLOCK)  
	--WHERE	InsuranceExpirationDate IS NOT NULL 
	--AND		DATEDIFF (hh, GETDATE(),InsuranceExpirationDate) BETWEEN 0 AND 72
	--AND		ISNULL(IsActive,0) = 1
	
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
		
		--SELECT  
		--		@vendorNumber = V.VendorNumber, 
		--		@insuranceExpireDate = V.InsuranceExpirationDate,
		--		@vendorName =  V.Name, 	
		--		@vendorEmail = LTRIM(RTRIM(COALESCE(V.Email,''))),			
		--		@regionName = VR.Name,
		--		@contactFirstName = VR.ContactFirstName, 
		--		@contactLastName =  VR.ContactLastName, 
		--		@Email = VR.Email, 				
		--		@PhoneNumber = dbo.fnc_FormatPhoneNumber(VR.PhoneNumber, 0) , 
		--		@officePhone = dbo.fnc_FormatPhoneNumber(@vendorServicesPhoneNumber, 0) , 
		--		@faxPhone = dbo.fnc_FormatPhoneNumber(@vendorServicesFaxNumber,0)			
		--FROM    Vendor AS V WITH (NOLOCK)
		--LEFT OUTER JOIN	VendorRegion AS VR WITH (NOLOCK) ON V.VendorRegionID = VR.ID
		--WHERE     (V.ID = @vendorID)
		
		SELECT  
				@vendorNumber = V.VendorNumber, 
				@insuranceExpireDate = V.InsuranceExpirationDate,
				@vendorName =  V.Name, 	
				@vendorEmail = LTRIM(RTRIM(COALESCE(V.Email,''))),			
				@regionName = '',				--VR.Name,
				@contactFirstName = 'Larry',	--VR.ContactFirstName, 
				@contactLastName =  'Turner',	--VR.ContactLastName, 
				@Email = 'insurance@nmc.com',	--VR.Email, 				
				@PhoneNumber = '469-524-5313',	--dbo.fnc_FormatPhoneNumber(VR.PhoneNumber, 0) , 
				@officePhone = '800-285-4977',	--dbo.fnc_FormatPhoneNumber(@vendorServicesPhoneNumber, 0) , 
				@faxPhone = '800-331-1145'		--dbo.fnc_FormatPhoneNumber(@vendorServicesFaxNumber,0)			
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
		
		--SELECT  
		--		@vendorNumber = V.VendorNumber, 
		--		@insuranceExpireDate = V.InsuranceExpirationDate,
		--		@vendorName =  V.Name, 	
		--		@vendorEmail = LTRIM(RTRIM(COALESCE(V.Email,''))),			
		--		@regionName = VR.Name,
		--		@contactFirstName = VR.ContactFirstName, 
		--		@contactLastName =  VR.ContactLastName, 
		--		@Email = VR.Email, 				
		--		@PhoneNumber = dbo.fnc_FormatPhoneNumber(VR.PhoneNumber, 0) , 
		--		@officePhone = dbo.fnc_FormatPhoneNumber(@vendorServicesPhoneNumber, 0) , 
		--		@faxPhone = dbo.fnc_FormatPhoneNumber(@vendorServicesFaxNumber,0)			
		--FROM    Vendor AS V WITH (NOLOCK)
		--LEFT OUTER JOIN	VendorRegion AS VR WITH (NOLOCK) ON V.VendorRegionID = VR.ID
		--WHERE     (V.ID = @vendorID)
		
				SELECT  
				@vendorNumber = V.VendorNumber, 
				@insuranceExpireDate = V.InsuranceExpirationDate,
				@vendorName =  V.Name, 	
				@vendorEmail = LTRIM(RTRIM(COALESCE(V.Email,''))),			
				@regionName = '',				--VR.Name,
				@contactFirstName = 'Larry',	--VR.ContactFirstName, 
				@contactLastName =  'Turner',	--VR.ContactLastName, 
				@Email = 'insurance@nmc.com',	--VR.Email, 				
				@PhoneNumber = '469-524-5313',	--dbo.fnc_FormatPhoneNumber(VR.PhoneNumber, 0) , 
				@officePhone = '800-285-4977',	--dbo.fnc_FormatPhoneNumber(@vendorServicesPhoneNumber, 0) , 
				@faxPhone = '800-331-1145'		--dbo.fnc_FormatPhoneNumber(@vendorServicesFaxNumber,0)			
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

      SELECT      PC.ID,
                  PC.Name,
                  PC.Sequence,
                  CASE WHEN EL.ID IS NULL 
                        THEN CAST(0 AS BIT)
                        ELSE CAST(1 AS BIT)
                  END AS [Enabled],
                  PC.IsVehicleRequired
      FROM  ProductCategory PC 
      LEFT JOIN
      (     SELECT DISTINCT ProductCategoryID AS ID 
            FROM  ProgramProductCategory PC
            JOIN      [dbo].[fnc_getprogramsandparents](@ProgramID) FNCP ON PC.ProgramID = FNCP.ProgramID
            AND         (VehicleTypeID = @vehicleTypeID OR VehicleTypeID IS NULL)
            AND         (VehicleCategoryID = @vehicleCategoryID OR VehicleCategoryID IS NULL)

      
      ) EL ON PC.ID = EL.ID
      WHERE PC.Name NOT IN ('Billing', 'Repair', 'MemberProduct', 'ISPSelection')
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
-- EXEC  [dbo].[dms_servicerequest_get] 1467
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

SELECT DISTINCT
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
		VI.CheckClearedDate,
		PP.Name AS ProductProvider,
		PP.PhoneNumber AS ProductProviderNumber,
		SR.ProviderClaimNumber

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
LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID
LEFT JOIN [VendorInvoice] VI WITH (NOLOCK) ON PO.ID = VI.PurchaseOrderID
LEFT JOIN [PaymentType] PT WITH (NOLOCK) ON VI.PaymentTypeID = PT.ID
--LEFT Join [MemberProduct]  MP (NOLOCK) ON (
--	MP.MemberID = C.MemberID      
--				OR
--	(MP.MemberID IS NULL AND MP.MembershipID = (SELECT MembershipID FROM Member WHERE ID = C.MemberID))
--	AND 
--	(MP.VIN IS NULL OR MP.VIN = C.VehicleVIN)
--)
LEFT JOIN [ProductProvider] PP (NOLOCK) ON PP.ID = SR.ProviderID
WHERE SR.ID = @serviceRequestID


END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Contract_Status_Get]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Contract_Status_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_Vendor_Contract_Status_Get] 337
 CREATE PROCEDURE [dbo].[dms_Vendor_Contract_Status_Get]( 
  @VendorID INT = NULL
) 
 AS 
 BEGIN       
      SET NOCOUNT ON  

SELECT    
    CASE  
    WHEN ContractedVendors.ContractID IS NOT NULL   
		AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'  
    ELSE 'Not Contracted'   
		END AS ContractStatus  
    From Vendor v 
    LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID
    Where v.ID = @VendorID  
  
END  
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Info]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Info] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_Vendor_Info] 319
 CREATE PROCEDURE [dbo].[dms_Vendor_Info]( 
  @VendorLocationID INT = NULL
  ,@ServiceRequestID INT =NULL
) 
 AS 
 BEGIN   
    
      SET NOCOUNT ON  
  
     DECLARE @ProductID INT = NULL  
       
      SELECT @ProductID=PrimaryProductID   
      FROM ServiceRequest   
      WHERE ID=@ServiceRequestID  
       
      Select   DISTINCT
   v.ID  
            , v.Name as VendorName  
            , v.VendorNumber as VendorNumber  
            --, CASE   
            --WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NOT NULL THEN 'Contracted'  
            --WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NULL THEN 'Not Contracted'  
            --WHEN c.ID IS NOT NULL THEN 'Contracted'   
            --ELSE 'Not Contracted'  
            --END as ContractStatus  
   , CASE  
    WHEN ContractedVendors.ContractID IS NOT NULL   
     AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'  
    ELSE 'Not Contracted'   
     END AS ContractStatus  
            , ae.Line1 as Address1  
            , ae.Line2 as Address2  
            , REPLACE(RTRIM(  
            COALESCE(ae.City, '') +  
            COALESCE(', ' + ae.StateProvince,'') +   
            COALESCE(' ' + LTRIM(ae.PostalCode), '') +   
            COALESCE(' ' + ae.CountryCode, '')   
            ), ' ', ' ') as VendorCityStateZipCountry  
            , pe24.PhoneTypeID as DispatchPhoneType  
            , pe24.PhoneNumber as DispatchPhoneNumber  
            , peFax.PhoneTypeID as FaxPhoneType  
            , peFax.PhoneNumber as FaxPhoneNumber  
            , peOfc.PhoneTypeID as OfficePhoneType  
            , peOfc.PhoneNumber as OfficePhoneNumber  
            ,ISNULL(vl.DispatchEmail,v.Email) Email--,v.Email  
            ,v.CreateBy   
            ,v.CreateDate  
            ,v.ModifyBy  
            ,v.ModifyDate  
            ,vs.Name AS VendorStatus  
            ,COALESCE(TaxEIN,TaxSSN,'') VendorTaxID  
      From VendorLocation vl  
      Join Vendor v on v.ID = vl.VendorID  
      JOIN VendorStatus vs ON v.VendorStatusID = vs.ID  
      Left Outer Join AddressEntity ae on ae.RecordID = vl.ID and ae.EntityID = (Select ID From Entity Where Name = 'VendorLocation')   
      Left Outer Join PhoneEntity pe24 on pe24.RecordID = vl.ID and pe24.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and pe24.PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')  
      Left Outer Join PhoneEntity peFax on peFax.RecordID = vl.ID and peFax.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and peFax.PhoneTypeID = (Select ID From PhoneType Where Name = 'Fax')  
      Left Outer Join PhoneEntity peOfc on peOfc.RecordID = vl.ID and peOfc.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and peOfc.PhoneTypeID = (Select ID From PhoneType Where Name = 'Office')  
      Left Outer Join [Contract] c on c.VendorID = v.ID and c.IsActive = 1 and c.ContractStatusID = (Select ID From ContractStatus Where Name = 'Active')  
      --Left Outer Join (  
      --      SELECT DISTINCT vr.VendorID, vr.ProductID  
      --      FROM dbo.fnGetCurrentProductRatesByVendorLocation() vr   
      --      ) DefaultVendorRates ON v.ID = DefaultVendorRates.VendorID And @ProductID = DefaultVendorRates.ProductID  
      LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID
      Where vl.ID = @VendorLocationID  
  
END  
GO
  
  IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Info_Search]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Info_Search] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

  --EXEC dms_Vendor_Info_Search @DispatchPhoneNumber = '1 4695213697',@OfficePhoneNumber = '1 9254494909'  
 CREATE PROCEDURE [dbo].[dms_Vendor_Info_Search](   
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10    
 , @sortColumn nvarchar(100)  = ''   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @DispatchPhoneNumber nvarchar(50)=NULL 
 , @OfficePhoneNumber nvarchar(50)=NULL
 , @VendorSearchName nvarchar(50)=NULL  
-- , @FaxPhoneNumber nvarchar(50)  
  
--SET @DispatchPhoneNumber = '1 2146834715';  
--SET @OfficePhoneNumber = '1 5868722949'  
  
) AS   
 BEGIN   
    
  SET NOCOUNT ON  
  
DECLARE @idoc int  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter   
VendorIDOperator="-1"   
VendorLocationIDOperator="-1"   
SequenceOperator="-1"   
VendorNumberOperator="-1"   
VendorNameOperator="-1"   
VendorStatusOperator="-1"   
ContractStatusOperator="-1"   
Address1Operator="-1"   
VendorCityOperator="-1"   
DispatchPhoneTypeOperator="-1"   
DispatchPhoneNumberOperator="-1"   
OfficePhoneTypeOperator="-1"   
 ></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
VendorIDOperator INT NOT NULL,  
VendorIDValue int NULL,  
VendorLocationIDOperator INT NOT NULL,  
VendorLocationIDValue int NULL,  
SequenceOperator INT NOT NULL,  
SequenceValue int NULL,  
VendorNumberOperator INT NOT NULL,  
VendorNumberValue nvarchar(50) NULL,  
VendorNameOperator INT NOT NULL,  
VendorNameValue nvarchar(50) NULL,  
VendorStatusOperator INT NOT NULL,  
VendorStatusValue nvarchar(50) NULL,  
ContractStatusOperator INT NOT NULL,  
ContractStatusValue nvarchar(50) NULL,  
Address1Operator INT NOT NULL,  
Address1Value nvarchar(50) NULL,  
VendorCityOperator INT NOT NULL,  
VendorCityValue nvarchar(50) NULL,  
DispatchPhoneTypeOperator INT NOT NULL,  
DispatchPhoneTypeValue int NULL,  
DispatchPhoneNumberOperator INT NOT NULL,  
DispatchPhoneNumberValue nvarchar(50) NULL,  
OfficePhoneTypeOperator INT NOT NULL,  
OfficePhoneTypeValue int NULL  
)  
DECLARE @FinalResults TABLE (   
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 VendorID int  NULL ,  
 VendorLocationID int  NULL ,  
 Sequence int  NULL ,  
 VendorNumber nvarchar(50)  NULL ,  
 VendorName nvarchar(255)  NULL ,  
 VendorStatus nvarchar(50)  NULL ,  
 ContractStatus nvarchar(50)  NULL ,  
 Address1 nvarchar(255)  NULL ,  
 VendorCity nvarchar(255)  NULL ,  
 DispatchPhoneType int  NULL ,  
 DispatchPhoneNumber nvarchar(50)  NULL ,  
 OfficePhoneType int  NULL ,  
 OfficePhoneNumber nvarchar(50)  NULL   
)   
DECLARE @FinalResults1 TABLE (   
 --[RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 VendorID int  NULL ,  
 VendorLocationID int  NULL ,  
 Sequence int  NULL ,  
 VendorNumber nvarchar(50)  NULL ,  
 VendorName nvarchar(255)  NULL ,  
 VendorStatus nvarchar(50)  NULL ,  
 ContractStatus nvarchar(50)  NULL ,  
 Address1 nvarchar(255)  NULL ,  
 VendorCity nvarchar(255)  NULL ,  
 DispatchPhoneType int  NULL ,  
 DispatchPhoneNumber nvarchar(50)  NULL ,  
 OfficePhoneType int  NULL ,  
 OfficePhoneNumber nvarchar(50)  NULL   
)   
  
INSERT INTO @tmpForWhereClause  
SELECT    
 ISNULL(VendorIDOperator,-1),  
 VendorIDValue ,  
 ISNULL(VendorLocationIDOperator,-1),  
 VendorLocationIDValue ,  
 ISNULL(SequenceOperator,-1),  
 SequenceValue ,  
 ISNULL(VendorNumberOperator,-1),  
 VendorNumberValue ,  
 ISNULL(VendorNameOperator,-1),  
 VendorNameValue ,  
 ISNULL(VendorStatusOperator,-1),  
 VendorStatusValue ,  
 ISNULL(ContractStatusOperator,-1),  
 ContractStatusValue ,  
 ISNULL(Address1Operator,-1),  
 Address1Value ,  
 ISNULL(VendorCityOperator,-1),  
 VendorCityValue ,  
 ISNULL(DispatchPhoneTypeOperator,-1),  
 DispatchPhoneTypeValue ,  
 ISNULL(DispatchPhoneNumberOperator,-1),  
 DispatchPhoneNumberValue ,  
 ISNULL(OfficePhoneTypeOperator,-1),  
 OfficePhoneTypeValue   
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
VendorIDOperator INT,  
VendorIDValue int   
,VendorLocationIDOperator INT,  
VendorLocationIDValue int   
,SequenceOperator INT,  
SequenceValue int   
,VendorNumberOperator INT,  
VendorNumberValue nvarchar(50)   
,VendorNameOperator INT,  
VendorNameValue nvarchar(50)   
,VendorStatusOperator INT,  
VendorStatusValue nvarchar(50)   
,ContractStatusOperator INT,  
ContractStatusValue nvarchar(50)   
,Address1Operator INT,  
Address1Value nvarchar(50)   
,VendorCityOperator INT,  
VendorCityValue nvarchar(50)   
,DispatchPhoneTypeOperator INT,  
DispatchPhoneTypeValue int   
,DispatchPhoneNumberOperator INT,  
DispatchPhoneNumberValue nvarchar(50)   
,OfficePhoneTypeOperator INT,  
OfficePhoneTypeValue int   
 )   

DECLARE @VendorLocationEntityID int,
	@VendorEntityID int,
	@DispatchPhoneTypeID int,
	@OfficePhoneTypeID int
SET @VendorLocationEntityID = (Select ID From Entity Where Name = 'VendorLocation')
SET @VendorEntityID = (Select ID From Entity Where Name = 'Vendor')
SET @DispatchPhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')  
SET @OfficePhoneTypeID = (Select ID From PhoneType Where Name = 'Office')  

--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
  
INSERT INTO @FinalResults1  
  
SELECT   
  v.ID  
 ,vl.ID   
 ,vl.Sequence  
 ,v.VendorNumber   
 ,v.Name
 ,vs.Name AS VendorStatus
 ,CASE
  WHEN ContractedVendors.ContractID IS NOT NULL 
		AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'
   ELSE 'Not Contracted' 
   END
 ,ae.Line1 as Address1  
 --,ae.Line2 as Address2  
 ,REPLACE(RTRIM(  
   COALESCE(ae.City, '') +  
   COALESCE(', ' + ae.StateProvince,'') +   
   COALESCE(LTRIM(ae.PostalCode), '') +   
   COALESCE(' ' + ae.CountryCode, '')   
   ), ' ', ' ')   
 , pe24.PhoneTypeID   
 , pe24.PhoneNumber   
 , peOfc.PhoneTypeID   
 , peOfc.PhoneNumber   
FROM VendorLocation vl  
INNER JOIN Vendor v on v.ID = vl.VendorID  
JOIN VendorStatus vs on v.VendorStatusID  = vs.ID
LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID
LEFT OUTER JOIN AddressEntity ae on ae.RecordID = vl.ID and ae.EntityID = @VendorLocationEntityID    
LEFT OUTER JOIN PhoneEntity pe24 on pe24.RecordID = vl.ID and pe24.EntityID = @VendorLocationEntityID and pe24.PhoneTypeID = @DispatchPhoneTypeID   
LEFT OUTER JOIN PhoneEntity peOfc on peOfc.RecordID = v.ID and peOfc.EntityID = @VendorEntityID and peOfc.PhoneTypeID = @OfficePhoneTypeID 
LEFT OUTER JOIN [Contract] c on c.VendorID = v.ID and c.IsActive = 1 AND c.ContractStatusID = (SELECT ID FROM ContractStatus WHERE Name = 'Active')
WHERE  
v.IsActive = 1 
--AND (v.VendorNumber IS NULL OR v.VendorNumber NOT LIKE '9X%' ) --KB: VendorNumber will be NULL for newly added vendors and these are getting excluded from the possible duplicates
AND
-- TP: Matching either phone number across both phone types is valid for this search; 
--     grouped OR condition -- A match on either phone number is valid
(ISNULL(pe24.PhoneNumber,'') IN (@DispatchPhoneNumber, @OfficePhoneNumber)
 OR
 ISNULL(peOfc.PhoneNumber,'') IN (@DispatchPhoneNumber, @OfficePhoneNumber)
)

--AND (@DispatchPhoneNumber IS NULL) OR (pe24.PhoneNumber = @DispatchPhoneNumber)  
--OR (@OfficePhoneNumber IS NULL) OR (peOfc.PhoneNumber = @OfficePhoneNumber)  
--AND (@VendorSearchName IS NULL) OR (v.NAme LIKE '%'+@VendorSearchName+'%')  

INSERT INTO @FinalResults  
SELECT   
 T.VendorID,  
 T.VendorLocationID,  
 T.Sequence,  
 T.VendorNumber,  
 T.VendorName,  
 T.VendorStatus,  
 T.ContractStatus,  
 T.Address1,  
 T.VendorCity,  
 T.DispatchPhoneType,  
 T.DispatchPhoneNumber,  
 T.OfficePhoneType,  
 T.OfficePhoneNumber  
FROM @FinalResults1 T,  
@tmpForWhereClause TMP   
WHERE (   
  
 (   
  ( TMP.VendorIDOperator = -1 )   
 OR   
  ( TMP.VendorIDOperator = 0 AND T.VendorID IS NULL )   
 OR   
  ( TMP.VendorIDOperator = 1 AND T.VendorID IS NOT NULL )   
 OR   
  ( TMP.VendorIDOperator = 2 AND T.VendorID = TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 3 AND T.VendorID <> TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 7 AND T.VendorID > TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 8 AND T.VendorID >= TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 9 AND T.VendorID < TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 10 AND T.VendorID <= TMP.VendorIDValue )   
  
 )   
  
 AND   
  
 (   
  ( TMP.VendorLocationIDOperator = -1 )   
 OR   
  ( TMP.VendorLocationIDOperator = 0 AND T.VendorLocationID IS NULL )   
 OR   
  ( TMP.VendorLocationIDOperator = 1 AND T.VendorLocationID IS NOT NULL )   
 OR   
  ( TMP.VendorLocationIDOperator = 2 AND T.VendorLocationID = TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 3 AND T.VendorLocationID <> TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 7 AND T.VendorLocationID > TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 8 AND T.VendorLocationID >= TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 9 AND T.VendorLocationID < TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 10 AND T.VendorLocationID <= TMP.VendorLocationIDValue )   
  
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
  ( TMP.VendorNumberOperator = -1 )   
 OR   
  ( TMP.VendorNumberOperator = 0 AND T.VendorNumber IS NULL )   
 OR   
  ( TMP.VendorNumberOperator = 1 AND T.VendorNumber IS NOT NULL )   
 OR   
  ( TMP.VendorNumberOperator = 2 AND T.VendorNumber = TMP.VendorNumberValue )   
 OR   
  ( TMP.VendorNumberOperator = 3 AND T.VendorNumber <> TMP.VendorNumberValue )   
 OR   
  ( TMP.VendorNumberOperator = 4 AND T.VendorNumber LIKE TMP.VendorNumberValue + '%')   
 OR   
  ( TMP.VendorNumberOperator = 5 AND T.VendorNumber LIKE '%' + TMP.VendorNumberValue )   
 OR   
  ( TMP.VendorNumberOperator = 6 AND T.VendorNumber LIKE '%' + TMP.VendorNumberValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.VendorNameOperator = -1 )   
 OR   
  ( TMP.VendorNameOperator = 0 AND T.VendorName IS NULL )   
 OR   
  ( TMP.VendorNameOperator = 1 AND T.VendorName IS NOT NULL )   
 OR   
  ( TMP.VendorNameOperator = 2 AND T.VendorName = TMP.VendorNameValue )   
 OR   
  ( TMP.VendorNameOperator = 3 AND T.VendorName <> TMP.VendorNameValue )   
 OR   
  ( TMP.VendorNameOperator = 4 AND T.VendorName LIKE TMP.VendorNameValue + '%')   
 OR   
  ( TMP.VendorNameOperator = 5 AND T.VendorName LIKE '%' + TMP.VendorNameValue )   
 OR   
  ( TMP.VendorNameOperator = 6 AND T.VendorName LIKE '%' + TMP.VendorNameValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.VendorStatusOperator = -1 )   
 OR   
  ( TMP.VendorStatusOperator = 0 AND T.VendorStatus IS NULL )   
 OR   
  ( TMP.VendorStatusOperator = 1 AND T.VendorStatus IS NOT NULL )   
 OR   
  ( TMP.VendorStatusOperator = 2 AND T.VendorStatus = TMP.VendorStatusValue )   
 OR   
  ( TMP.VendorStatusOperator = 3 AND T.VendorStatus <> TMP.VendorStatusValue )   
 OR   
  ( TMP.VendorStatusOperator = 4 AND T.VendorStatus LIKE TMP.VendorStatusValue + '%')   
 OR   
  ( TMP.VendorStatusOperator = 5 AND T.VendorStatus LIKE '%' + TMP.VendorStatusValue )   
 OR   
  ( TMP.VendorStatusOperator = 6 AND T.VendorStatus LIKE '%' + TMP.VendorStatusValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.ContractStatusOperator = -1 )   
 OR   
  ( TMP.ContractStatusOperator = 0 AND T.ContractStatus IS NULL )   
 OR   
  ( TMP.ContractStatusOperator = 1 AND T.ContractStatus IS NOT NULL )   
 OR   
  ( TMP.ContractStatusOperator = 2 AND T.ContractStatus = TMP.ContractStatusValue )   
 OR   
  ( TMP.ContractStatusOperator = 3 AND T.ContractStatus <> TMP.ContractStatusValue )   
 OR   
  ( TMP.ContractStatusOperator = 4 AND T.ContractStatus LIKE TMP.ContractStatusValue + '%')   
 OR   
  ( TMP.ContractStatusOperator = 5 AND T.ContractStatus LIKE '%' + TMP.ContractStatusValue )   
 OR   
  ( TMP.ContractStatusOperator = 6 AND T.ContractStatus LIKE '%' + TMP.ContractStatusValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.Address1Operator = -1 )   
 OR   
  ( TMP.Address1Operator = 0 AND T.Address1 IS NULL )   
 OR   
  ( TMP.Address1Operator = 1 AND T.Address1 IS NOT NULL )   
 OR   
  ( TMP.Address1Operator = 2 AND T.Address1 = TMP.Address1Value )   
 OR   
  ( TMP.Address1Operator = 3 AND T.Address1 <> TMP.Address1Value )   
 OR   
  ( TMP.Address1Operator = 4 AND T.Address1 LIKE TMP.Address1Value + '%')   
 OR   
  ( TMP.Address1Operator = 5 AND T.Address1 LIKE '%' + TMP.Address1Value )   
 OR   
  ( TMP.Address1Operator = 6 AND T.Address1 LIKE '%' + TMP.Address1Value + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.VendorCityOperator = -1 )   
 OR   
  ( TMP.VendorCityOperator = 0 AND T.VendorCity IS NULL )   
 OR   
  ( TMP.VendorCityOperator = 1 AND T.VendorCity IS NOT NULL )   
 OR   
  ( TMP.VendorCityOperator = 2 AND T.VendorCity = TMP.VendorCityValue )   
 OR   
  ( TMP.VendorCityOperator = 3 AND T.VendorCity <> TMP.VendorCityValue )   
 OR   
  ( TMP.VendorCityOperator = 4 AND T.VendorCity LIKE TMP.VendorCityValue + '%')   
 OR   
  ( TMP.VendorCityOperator = 5 AND T.VendorCity LIKE '%' + TMP.VendorCityValue )   
 OR   
  ( TMP.VendorCityOperator = 6 AND T.VendorCity LIKE '%' + TMP.VendorCityValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.DispatchPhoneTypeOperator = -1 )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 0 AND T.DispatchPhoneType IS NULL )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 1 AND T.DispatchPhoneType IS NOT NULL )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 2 AND T.DispatchPhoneType = TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 3 AND T.DispatchPhoneType <> TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 7 AND T.DispatchPhoneType > TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 8 AND T.DispatchPhoneType >= TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 9 AND T.DispatchPhoneType < TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 10 AND T.DispatchPhoneType <= TMP.DispatchPhoneTypeValue )   
  
 )   
  
 AND   
  
 (   
  ( TMP.DispatchPhoneNumberOperator = -1 )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 0 AND T.DispatchPhoneNumber IS NULL )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 1 AND T.DispatchPhoneNumber IS NOT NULL )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 2 AND T.DispatchPhoneNumber = TMP.DispatchPhoneNumberValue )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 3 AND T.DispatchPhoneNumber <> TMP.DispatchPhoneNumberValue )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 4 AND T.DispatchPhoneNumber LIKE TMP.DispatchPhoneNumberValue + '%')   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 5 AND T.DispatchPhoneNumber LIKE '%' + TMP.DispatchPhoneNumberValue )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 6 AND T.DispatchPhoneNumber LIKE '%' + TMP.DispatchPhoneNumberValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.OfficePhoneTypeOperator = -1 )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 0 AND T.OfficePhoneType IS NULL )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 1 AND T.OfficePhoneType IS NOT NULL )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 2 AND T.OfficePhoneType = TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 3 AND T.OfficePhoneType <> TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 7 AND T.OfficePhoneType > TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 8 AND T.OfficePhoneType >= TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 9 AND T.OfficePhoneType < TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 10 AND T.OfficePhoneType <= TMP.OfficePhoneTypeValue )   
  
 )   
  
 AND   
 1 = 1   
 )   
 ORDER BY   
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'ASC'  
  THEN T.VendorID END ASC,   
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'DESC'  
  THEN T.VendorID END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorLocationID' AND @sortOrder = 'ASC'  
  THEN T.VendorLocationID END ASC,   
  CASE WHEN @sortColumn = 'VendorLocationID' AND @sortOrder = 'DESC'  
  THEN T.VendorLocationID END DESC ,  
  
  CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'  
  THEN T.Sequence END ASC,   
  CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'  
  THEN T.Sequence END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'  
  THEN T.VendorNumber END ASC,   
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'  
  THEN T.VendorNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'ASC'  
  THEN T.VendorName END ASC,   
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'DESC'  
  THEN T.VendorName END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'ASC'  
  THEN T.VendorStatus END ASC,   
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'DESC'  
  THEN T.VendorStatus END DESC ,  
  
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'ASC'  
  THEN T.ContractStatus END ASC,   
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'DESC'  
  THEN T.ContractStatus END DESC ,  
  
  CASE WHEN @sortColumn = 'Address1' AND @sortOrder = 'ASC'  
  THEN T.Address1 END ASC,   
  CASE WHEN @sortColumn = 'Address1' AND @sortOrder = 'DESC'  
  THEN T.Address1 END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorCity' AND @sortOrder = 'ASC'  
  THEN T.VendorCity END ASC,   
  CASE WHEN @sortColumn = 'VendorCity' AND @sortOrder = 'DESC'  
  THEN T.VendorCity END DESC ,  
  
  CASE WHEN @sortColumn = 'DispatchPhoneType' AND @sortOrder = 'ASC'  
  THEN T.DispatchPhoneType END ASC,   
  CASE WHEN @sortColumn = 'DispatchPhoneType' AND @sortOrder = 'DESC'  
  THEN T.DispatchPhoneType END DESC ,  
  
  CASE WHEN @sortColumn = 'DispatchPhoneNumber' AND @sortOrder = 'ASC'  
  THEN T.DispatchPhoneNumber END ASC,   
  CASE WHEN @sortColumn = 'DispatchPhoneNumber' AND @sortOrder = 'DESC'  
  THEN T.DispatchPhoneNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'OfficePhoneType' AND @sortOrder = 'ASC'  
  THEN T.OfficePhoneType END ASC,   
  CASE WHEN @sortColumn = 'OfficePhoneType' AND @sortOrder = 'DESC'  
  THEN T.OfficePhoneType END DESC ,  
  
  CASE WHEN @sortColumn = 'OfficePhoneNumber' AND @sortOrder = 'ASC'  
  THEN T.OfficePhoneNumber END ASC,   
  CASE WHEN @sortColumn = 'OfficePhoneNumber' AND @sortOrder = 'DESC'  
  THEN T.OfficePhoneNumber END DESC   
  
  
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
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_PO_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_PO_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_PO_Details_Get @PONumber=7770395
 CREATE PROCEDURE [dbo].[dms_Vendor_Invoice_PO_Details_Get]( 
	@PONumber nvarchar(50) =NULL
	)
AS
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 SET FMTONLY OFF  
  
SELECT  PO.ID  
   , CASE  
    WHEN ISNULL(PO.IsPayByCompanyCreditCard,'') = 1 THEN 'Paid with company credit card'  
    ELSE ''  
     END AS [AlertText]  
   , PO.PurchaseOrderNumber AS [PONumber]  
   , POS.Name AS [POStatus]  
   , PO.PurchaseOrderAmount AS [POAmount]  
   , PC.Name AS [Service]  
   , PO.IssueDate AS [IssueDate]  
   , PO.ETADate AS [ETADate]  
   , PO.VendorLocationID     
   --, CASE  
   --WHEN ISNULL(CRS.ID,'') = '' THEN 'Not Contracted'  
   --ELSE 'Contracted'  
   --END AS 'ContractStatus'  
   , CASE  
    WHEN ContractedVendors.ContractID IS NOT NULL AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'  
    ELSE 'Not Contracted'   
     END AS ContractStatus  
   , V.Name AS [VendorName]  
   , V.VendorNumber AS [VendorNumber]  
   , ISNULL(PO.BillingAddressLine1,'') AS [VendorLocationLine1]  
   , ISNULL(PO.BillingAddressLine2,'') AS [VendorLocationLine2]  
   , ISNULL(PO.BillingAddressLine3,'') AS [VendorLocationLine3]   
   , ISNULL(REPLACE(RTRIM(  
      COALESCE(PO.BillingAddressCity, '') +   
      COALESCE(', ' + RTRIM(PO.BillingAddressStateProvince), '') +       
      COALESCE(' ' + PO.BillingAddressPostalCode, '') +            
      COALESCE(' ' + PO.BillingAddressCountryCode, '')   
     ), '  ', ' ')  
     ,'') AS [VendorLocationCityStZip]  
   , PO.DispatchPhoneNumber AS [DispatchPhoneNumber]  
   , PO.FaxPhoneNumber AS [FaxPhoneNumber]  
   , 'TalkedTo' AS [TalkedTo] -- TODO: Linked to ContactLog and get Talked To  
   , CL.Name AS [Client]  
   , P.Name AS [Program]  
   , MS.MembershipNumber AS [MemberNumber]  
   , C.MemberStatus  
   , REPLACE(RTRIM(  
    COALESCE(CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+  
    COALESCE(' ' + LEFT(M.MiddleName,1),'')+  
    COALESCE(' ' + CASE WHEN M.LastName = '' THEN NULL ELSE M.LastName END,'')+    
    COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')  
    ),'','') AS [CustomerName]  
   , C.ContactPhoneNumber AS [CallbackNumber]   
   , C.ContactAltPhoneNumber AS [AlternateNumber]  
   --, PO.SubTotal AS [SubTotal]  calculated from PO Details GRID  
   , PO.TaxAmount AS [Tax]  
   , PO.TotalServiceAmount AS [ServiceTotal]  
   , PO.CoachNetServiceAmount AS [CoachNetPays]  
   , PO.MemberServiceAmount AS [MemberPays]  
   , VT.Name + ' - ' + VC.Name AS [VehicleType]  
   , REPLACE(RTRIM(  
    COALESCE(C.VehicleYear,'')+  
    COALESCE(' ' + CASE WHEN C.VehicleMake = 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END,'')+  
    COALESCE(' ' + CASE WHEN C.VehicleModel = 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END,'')  
    ), '','') AS [Vehicle]  
   , ISNULL(C.VehicleVIN,'') AS [VIN]  
   , ISNULL(C.VehicleColor,'') AS [Color]  
   , REPLACE(RTRIM(  
     COALESCE(C.VehicleLicenseState + ' - ','') +  
     COALESCE(C.VehicleLicenseNumber,'')   
    ),'','') AS [License]  
   , ISNULL(C.VehicleCurrentMileage,'') AS [Mileage]  
   , ISNULL(SR.ServiceLocationAddress,'') AS [Location]  
   , ISNULL(SR.ServiceLocationDescription,'') AS [LocationDescription]  
   , ISNULL(SR.DestinationAddress,'') AS [Destination]  
   , ISNULL(SR.DestinationDescription,'') AS [DestinationDescription]  
   , PO.CreateBy  
   , PO.CreateDate  
   , PO.ModifyBy  
   , PO.ModifyDate   
   , CT.Abbreviation AS [CurrencyType]   
   , PO.IsPayByCompanyCreditCard AS IsPayByCC  
   , PO.CompanyCreditCardNumber CompanyCC  
   ,PO.VendorTaxID  
   ,PO.Email  
   ,POPS.[Description] PurchaseOrderPayStatus  
FROM  PurchaseOrder PO   
JOIN  PurchaseOrderStatus POS WITH (NOLOCK)ON POS.ID = PO.PurchaseOrderStatusID  
LEFT JOIN PurchaseOrderPayStatusCode POPS WITH (NOLOCK) ON POPS.ID = PO.PayStatusCodeID  
JOIN  ServiceRequest SR WITH (NOLOCK) ON SR.ID = PO.ServiceRequestID  
LEFT JOIN ServiceRequestStatus SRS WITH (NOLOCK) ON SRS.ID = SR.ServiceRequestStatusID  
LEFT JOIN ProductCategory PCSR ON PCSR.ID = SR.ProductCategoryID  
JOIN  [Case] C WITH (NOLOCK) ON C.ID = SR.CaseID  
JOIN  Program P WITH (NOLOCK) ON P.ID = C.ProgramID  
JOIN  Client CL WITH (NOLOCK) ON CL.ID = P.ClientID  
JOIN  Member M WITH (NOLOCK) ON M.ID = C.MemberID  
JOIN  Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID  
LEFT JOIN  Product PR WITH (NOLOCK) ON PR.ID = PO.ProductID  
LEFT JOIN  ProductCategory PC WITH (NOLOCK) ON PC.ID = PR.ProductCategoryID  
LEFT JOIN VehicleType VT WITH(NOLOCK) ON VT.ID = C.VehicleTypeID  
LEFT JOIN VehicleCategory VC WITH(NOLOCK) ON VC.ID = C.VehicleCategoryID  
LEFT JOIN RVType RT WITH (NOLOCK) ON RT.ID = C.VehicleRVTypeID  
JOIN  VendorLocation VL WITH(NOLOCK) ON VL.ID = PO.VendorLocationID  
JOIN  Vendor V WITH(NOLOCK) ON V.ID = VL.VendorID  
--LEFT JOIN [Contract] CO ON CO.VendorID = V.ID  AND CO.IsActive = 1  
--LEFT JOIN ContractRateSchedule CRS ON CRS.ContractID = V.ID AND CO.IsActive = 1  
LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID   
LEFT JOIN CurrencyType CT ON CT.ID=PO.CurrencyTypeID  
WHERE  PO.PurchaseOrderNumber = @PONumber  
   AND PO.IsActive = 1  
  
END  

GO
-- Get Vendor Billing with logic added to check for Alternate
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get @VendorLocationID=356, @POID=619
 CREATE PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get( 
	@VendorLocationID INT =NULL
	, @POID INT = NULL
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET FMTONLY OFF
SELECT V.ID
	--, CASE
	--	WHEN ISNULL(CRS.ID,'') = '' THEN 'Not Contracted'
	--	ELSE 'Contracted'
	--	END AS 'ContractStatus'
	, CASE
		WHEN ContractedVendors.ContractID IS NOT NULL AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'
		ELSE 'Not Contracted' 
		END AS ContractStatus
	, V.Name
	, V.VendorNumber
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN ''
		WHEN ISNULL(VI.ID, '') <> '' THEN VI.BillingAddressLine1
		ELSE AE.Line1
		END AS Line1
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN ''
		WHEN ISNULL(VI.ID, '') <> '' THEN VI.BillingAddressLine2
		ELSE AE.Line2
	END AS Line2
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN ''
		WHEN ISNULL(VI.ID, '') <> '' THEN VI.BillingAddressLine3
		ELSE AE.Line3
	END AS Line3
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN 'No billing address on file'
		WHEN ISNULL(VI.ID,'') <> '' THEN
		ISNULL(REPLACE(RTRIM(
			COALESCE(VI.BillingAddressCity, '') +
			COALESCE(', ' + VI.BillingAddressStateProvince, '') +
			COALESCE(' ' + VI.BillingAddressPostalCode, '') +
			COALESCE(' ' + VI.BillingAddressCountryCode, '')
		), ' ', ' ')
	,'')
	ELSE ISNULL(REPLACE(RTRIM(
			COALESCE(AE.City, '') +
			COALESCE(', ' + AE.StateProvince, '') +
			COALESCE(' ' + AE.PostalCode, '') +
			COALESCE(' ' + AE.CountryCode, '')
		), ' ', ' ')
	,'')
	END AS BillingCityStZip
	, ISNULL(REPLACE(RTRIM(
		COALESCE(V.TaxSSN,'')+
		COALESCE(V.TaxEIN,'')
		), ' ', ' ')
	,'') AS TaxID
	, PE.PhoneNumber
	, V.Email
	, (V.ContactFirstName + ' ' + V.ContactLastName) AS ContactName
	, VI.ID AS VendorInvoiceID
FROM		Vendor V
JOIN		VendorLocation VL ON VL.VendorID = V.ID
LEFT JOIN	Contract C ON C.VendorID = V.ID
			AND C.IsActive = 1
LEFT JOIN ContractRateSchedule CRS ON CRS.ContractID = V.ID
			AND C.IsActive = 1
LEFT JOIN	AddressEntity AE ON AE.RecordID = V.ID
			AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
			AND	AE.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Billing')
LEFT JOIN	PhoneEntity PE ON PE.RecordID = V.ID
			AND	PE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
			AND PE.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Office')
LEFT JOIN	VendorInvoice VI ON VI.PurchaseOrderID = @POID
LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID
WHERE VL.ID = @VendorLocationID
END
GO
GO
-- Get VendorLocation data
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_Vendor_Location_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_Vendor_Location_Details_Get @VendorLocationID=356
 CREATE PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Details_Get( 
	@VendorLocationID INT =NULL
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET FMTONLY OFF
	
	SELECT VL.ID
	 ,CASE  
    WHEN ContractedVendors.ContractID IS NOT NULL   
     AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'  
    ELSE 'Not Contracted'
		END AS 'ContractStatus'
	, V.Name
	, V.VendorNumber
	, AE.Line1
	, AE.Line2
	, AE.Line3
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN 'No billing address on file'
		ELSE ISNULL(REPLACE(RTRIM(
			COALESCE(AE.City, '') +
			COALESCE(', ' + AE.StateProvince, '') +
			COALESCE(' ' + AE.PostalCode, '') +
			COALESCE(' ' + AE.CountryCode, '')
		), ' ', ' ')
	,'')
	END AS BillingCityStZip
	, PE24.PhoneNumber AS [24HRNumber]
	, PEFax.PhoneNumber AS FaxNumber
	, 'Talked To' AS TalkedTo
	
	FROM VendorLocation VL
	JOIN Vendor V ON V.ID = VL.VendorID
	LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID
	LEFT JOIN Contract C ON C.VendorID = V.ID
	AND C.IsActive = 1
	LEFT JOIN ContractRateSchedule CRS ON CRS.ContractID = V.ID
	AND C.IsActive = 1
	LEFT JOIN AddressEntity AE ON AE.RecordID = VL.ID
	AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
	AND AE.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Business')
	LEFT JOIN PhoneEntity PE24 ON PE24.RecordID = VL.ID
	AND PE24.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
	AND PE24.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Dispatch')
	LEFT JOIN PhoneEntity PEFax ON PEFax.RecordID = VL.ID
	AND PEFax.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
	AND PEFax.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Fax')
	WHERE VL.ID = @VendorLocationID
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
HasPO BIT NULL,
IsFordDirectTow BIT NULL,
IsCNETDirectPartner BIT NULL
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
@programID INT	= NULL,
@IsFordDirectTow BIT,
@IsCNETDirectPartner BIT
  
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
	HasPo,
	IsFordDirectTow,
	IsCNETDirectPartner
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
 HasPo BIT,
 IsFordDirectTow BIT,
 IsCNETDirectPartner BIT
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
  @HasPO = HasPO,
  @IsFordDirectTow = IsFordDirectTow,
  @IsCNETDirectPartner = IsCNETDirectPartner
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
 -- ,v.Name +	
	--CASE WHEN VPCNDP.VendorID IS NOT NULL THEN ' (P)' ELSE '' END  + 
	--CASE WHEN VPFDT.VendorID IS NOT NULL 
	--		THEN ' (DT)' 
	--ELSE '' END VendorName
  , v.Name + COALESCE(F.Indicators,'') AS VendorName
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
LEFT JOIN [dbo].[fnc_GetVendorIndicators]('Vendor') F ON V.ID = F.RecordID
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
LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID  
--LEFT OUTER JOIN (SELECT VendorID, MAX(CreateDate) AS [CreateDate] FROM [Contract] WHERE IsActive = 1 GROUP BY VendorID) C ON C.VendorID = V.ID  =
WHERE V.IsActive = 1  -- Not deleted    
AND  (@VendorNumber IS NULL OR @VendorNumber = V.VendorNumber)  
AND  (@CountryID IS NULL OR @CountryID = AE.CountryID)  
AND  (@StateProvinceID IS NULL OR @StateProvinceID = AE.StateProvinceID)  
AND  (@City IS NULL OR @City = AE.City)  
AND  (@PostalCode IS NULL OR @PostalCode = AE.PostalCode)  
AND  (@IsLevy IS NULL OR @IsLevy = ISNULL(V.IsLevyActive,0))  
AND  (@IsFordDirectTow IS NULL OR (@IsFordDirectTow = 1 AND COALESCE(F.Indicators,'') LIKE '%(DT)%'))  
AND  (@IsCNETDirectPartner IS NULL OR (@IsCNETDirectPartner = 1 AND COALESCE(F.Indicators,'') LIKE '%(P)%'))  
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
 WHERE id = object_id(N'[dbo].dms_Vendor_Services_List_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Services_List_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 --EXEC dms_Vendor_Services_List_Get @VendorID=1
CREATE PROCEDURE [dbo].[dms_Vendor_Services_List_Get] @VendorID INT
AS
BEGIN
      -- SET NOCOUNT ON added to prevent extra result sets from
      -- interfering with SELECT statements.
      SET NOCOUNT ON;
DECLARE @FinalResults AS TABLE(
      SortOrder INT NULL,
      ServiceGroup NVARCHAR(255) NULL,
      ServiceName nvarchar(100)  NULL ,
      ProductID int  NULL ,
      VehicleCategorySequence int  NULL ,
      ProductCategory nvarchar(100)  NULL ,
      IsAvailByVendor bit default 0
) 

INSERT INTO @FinalResults (SortOrder, ServiceGroup,ServiceName,ProductID,VehicleCategorySequence,ProductCategory)
      SELECT 
                   CASE WHEN vc.name is NULL THEN 2 
                              ELSE 1 
                   END AS SortOrder
                  ,CASE WHEN vc.name is NULL THEN 'Other' 
                              ELSE vc.name 
                   END AS ServiceGroup
                  ,REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
                  --,ISNULL(vc.Name,'') + CASE WHEN ISNULL(vc.Name,'') <> '' THEN ' - ' ELSE '' END  + REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
                  ,p.ID AS ProductID
                  ,vc.Sequence VehicleCategorySequence
                  ,pc.Name ProductCategory                  
      FROM Product p
      JOIN ProductCategory pc on p.productCategoryid = pc.id
      JOIN ProductType pt on p.ProductTypeID = pt.ID
      JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
      LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
      LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
      WHERE pt.Name = 'Service'
      AND pst.Name IN ('PrimaryService', 'SecondaryService')
      AND p.Name Not in ('Concierge', 'Information', 'Tech')
      AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee')

      UNION
      SELECT 
                  3 AS SortOrder
                  ,'Additional' AS ServiceGroup
                  ,p.Name AS ServiceName
                  ,p.ID AS ProductID
                  ,vc.Sequence VehicleCategorySequence
                  ,pc.Name ProductCategory
      FROM  Product p
      JOIN ProductCategory pc on p.productCategoryid = pc.id
      JOIN ProductType pt on p.ProductTypeID = pt.ID
      JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
      LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
      LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
      WHERE pt.Name = 'Service'
      AND pst.Name IN ('AdditionalService')
      AND p.Name Not in ('Concierge', 'Information', 'Tech')
      AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials') 
      
      UNION
      SELECT 
                  4 AS SortOrder
                  ,'ISP Selection' AS ServiceGroup
                  ,p.Name AS ServiceName
                  ,p.ID AS ProductID
                  ,vc.Sequence VehicleCategorySequence
                  ,pc.Name ProductCategory
      FROM  Product p
      JOIN ProductCategory pc on p.productCategoryid = pc.id
      JOIN ProductType pt on p.ProductTypeID = pt.ID
      JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
      LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
      LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
      WHERE pt.Name = 'Attribute'
      AND pst.Name = 'Ranking'
      AND pc.Name = 'ISPSelection'
      
      UNION ALL
      
      SELECT 
                  5 AS SortOrder
                  ,pst.Name AS ServiceGroup 
                  ,p.Name AS ServiceName
                  ,p.ID AS ProductID
                  ,vc.Sequence VehicleCategorySequence
                  ,pc.Name ProductCategory
      FROM Product p
      Join ProductCategory pc on p.productCategoryid = pc.id
      Join ProductType pt on p.ProductTypeID = pt.ID
      Join ProductSubType pst on p.ProductSubTypeID = pst.id
      Left Outer Join VehicleCategory vc on p.VehicleCategoryID = vc.ID
      Left Outer Join VehicleType vt on p.VehicleTypeID = vt.ID
      Where pt.Name = 'Attribute'
      and pc.Name = 'Repair'
      --and pst.Name NOT IN ('Client')
      ORDER BY SortOrder, VehicleCategorySequence, ProductCategory
      

UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
WHERE VP.VendorID=@VendorID
      
SELECT * FROM @FinalResults

END
GO

GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnGetPreferredVendorsByVehicleCategory]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnGetPreferredVendorsByVehicleCategory]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Select * From [dbo].[fnGetContractedVendors]() Where VendorID = 4360   
CREATE FUNCTION [dbo].[fnGetPreferredVendorsByVehicleCategory] ()  
RETURNS TABLE   
AS  
RETURN   
(  
	select v.ID VendorID, p.VehicleCategoryID 
	from vendor v
	Join VendorProduct vp on vp.VendorID = v.ID
	Join Product p on p.ID = vp.ProductID
	Join ProductCategory pc on pc.ID = p.ProductCategoryID
	Join ProductType pt on pt.ID = p.ProductTypeID
	Join ProductSubType pst on pst.ID = p.ProductSubTypeID
	Where pc.Name = 'ISPSelection'
	and pt.Name = 'Attribute'
	and pst.Name = 'Ranking'
)  


GO



GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnServiceRequestEfforts]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnServiceRequestEfforts]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE function [dbo].[fnServiceRequestEfforts](@ServiceRequestID AS INT) RETURNS @AttempsResult TABLE(
								ID INT PRIMARY KEY NOT NULl IDENTITY(1,1),
							    RankID INT,
							    UserName NVARCHAR(50),
								EffortInSeconds NUMERIC(18,2),
								WaitingTimeInQueue NUMERIC(18,2))
BEGIN
DECLARE @Result AS TABLE(EventLogID INT,
						 EventID INT,
						 SessionID NVARCHAR(100),
						 PageSource NVARCHAR(MAX),
						 [Description] NVARCHAR(MAX),
						 CreateDate DATETIME,
						 CreateBy NVARCHAR(50))

DECLARE @FinalResult AS TABLE(ID INT PRIMARY KEY NOT NULl IDENTITY(1,1),
						 EventLogID INT,
						 EventID INT,
						 SessionID NVARCHAR(100),
						 PageSource NVARCHAR(MAX),
						 [Description] NVARCHAR(MAX),
						 CreateDate DATETIME,
						 CreateBy NVARCHAR(50),
						 Ranking INT NULL,
						 IsKeyRecord BIT NULL,
						 IsValidRecord BIT NULL,
						 TabTimeDifference NUMERIC(18,2) NULL)

-- Filters for Events and Keys to Create Group as Entry Point
DECLARE @Keys AS TABLE (EventID INT)
DECLARE @EventFilters AS TABLE (ID INT NOT NULL IDENTITY(1,1),EventID INT,IsKey BIT NOT NULL,IsEnter BIT NULL)

INSERT INTO @Keys VALUES((SELECT ID FROM Event WHERE Name  = 'StartServiceRequest'))
INSERT INTO @Keys VALUES((SELECT ID FROM Event WHERE Name  = 'OpenServiceRequest'))
INSERT INTO @Keys VALUES((SELECT ID FROM Event WHERE Name  = 'OpenActiveRequest'))

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'StartServiceRequest'),1,NULL)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'OpenServiceRequest'),1,NULL)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'OpenActiveRequest'),1,NULL)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterStartTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveStartTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterEmergencyTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveEmergencyTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterMemberTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveMemberTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterVehicleTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveVehicleTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterServiceTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveServiceTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterMapTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveMapTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterDispatchTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveDispatchTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterPOTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeavePOTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterPaymentTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeavePaymentTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterActivityTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveActivityTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterFinishTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveFinishTab'),0,0)

-- INSERT LOGS FOR Service Request Considering RecordID for Entity SR
INSERT INTO @Result
SELECT EL.ID,
	   El.EventID,
	   EL.SessionID,
	   El.Source,
	   EL.Description,
	   EL.CreateDate,
	   EL.CreateBy	   
FROM EventLog EL
LEFT JOIN EventLogLink ELL ON EL.ID = ELL.EventLogID
WHERE ELL.EntityID =  (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
AND ELL.RecordID = @ServiceRequestID
AND EL.EventID IN (SELECT EventID FROM @EventFilters)

-- --INSERT LOGS FOR Case Considering RecordID for Entity Case
--INSERT INTO @Result
--SELECT EL.ID,
--	   El.EventID,
--	   EL.SessionID,
--	   El.Source,
--	   EL.Description,
--	   EL.CreateDate,
--	   EL.CreateBy	   
--FROM EventLog EL
--LEFT JOIN EventLogLink ELL ON EL.ID = ELL.EventLogID
--WHERE ELL.EntityID = (SELECT ID FROM Entity WHERE Name = 'Case')
--AND ELL.RecordID = (SELECT CaseID FROM ServiceRequest WHERE ID = @ServiceRequestID)
--AND EL.EventID IN (SELECT EventID FROM @EventFilters)

--- Filters Record Based On Create Date
INSERT INTO @FinalResult(EventLogID,EventID,SessionID,PageSource,[Description],CreateDate,CreateBy)
SELECT * FROM @Result ORDER BY EventLogID ASC

-- Insert Total As Dummy Later Will Update
INSERT INTO @AttempsResult VALUES(0,'Total',0,0)

----------logic #2
declare @counter int = 1
declare @val int = 1
declare @otherval int = 1
declare @eventID INT

-- Ranking Logic to Create Groups Known As Rank
WHILE @counter <= (SELECT COUNT(*) FROM @FinalResult)
BEGIN
	SELECT @eventID = EventID 
	FROM @FinalResult
	WHERE ID = @counter

	IF @eventID in (SELECT EventID FROM @Keys)
	BEGIN
		UPDATE @FinalResult SET Ranking = @val,IsKeyRecord = 1 WHERE ID = @counter
		SET @otherval = @val
		SET @val=@val+1
	END
	
	ELSE
	 BEGIN
	 UPDATE @FinalResult SET Ranking = @otherval,IsKeyRecord = 0 WHERE ID = @counter
	END
SET @counter = @counter + 1
END

-- Ranking Logic to update Valid Ranks
DECLARE @validRecordRank INT = 1
WHILE @validRecordRank <= (SELECT MAX(Ranking) FROM @FinalResult)
BEGIN
	 IF (SELECT COUNT(*) FROM @FinalResult WHERE Ranking  =  @validRecordRank) > 1
	 BEGIN
		UPDATE @FinalResult SET IsValidRecord = 1 WHERE Ranking  =  @validRecordRank
	 END
	 ELSE
	 BEGIN
		UPDATE @FinalResult SET IsValidRecord = 0 WHERE Ranking  =  @validRecordRank
	 END
	 SET @validRecordRank= @validRecordRank + 1
END


DECLARE @rankForTabTime AS INT
SET     @rankForTabTime = 1
WHILE   @rankForTabTime <= (SELECT Max(Ranking) FROM @FinalResult)
BEGIN
	 
	INSERT INTO @AttempsResult(RankID,UserName,EffortInSeconds) SELECT Ranking,CreateBy,0 FROM @FinalResult WHERE Ranking = @rankForTabTime AND IsKeyRecord = 1

    DECLARE @startID INT
	DECLARE @endID INT
	SET @startID = (SELECT TOP(1) ID FROM @FinalResult WHERE Ranking = @rankForTabTime AND IsKeyRecord = 0)
	SET @endID = (SELECT TOP(1) ID FROM @FinalResult WHERE Ranking = @rankForTabTime AND IsKeyRecord = 0 ORDER BY ID DESC)
	
	WHILE @startID <= @endID
	BEGIN
		DECLARE @curEventID INT
		SET @curEventID = (SELECT EventID FROM @FinalResult WHERE ID = @startID)
		DECLARE @eventFilterID int
		SET @eventFilterID = (SELECT ID FROM @EventFilters WHERE EventID = @curEventID AND IsEnter = 1 AND IsKey = 0)
		IF @eventFilterID IS NOT NULL
			BEGIN
				DECLARE @eventIDFromFilter int
				SET @eventIDFromFilter = (SELECT EventID FROM @EventFilters WHERE ID= @eventFilterID + 1)
				IF EXISTS (SELECT * FROM @FinalResult WHERE ID=@startID + 1 AND EventID = @eventIDFromFilter)
				BEGIN
					DECLARE @dateDIFF NUMERIC(18,2)
					SET @dateDIFF = ABS(DATEDIFF(SS,(SELECT CreateDate FROM @FinalResult WHERE ID=@startID + 1),
												(SELECT CreateDate FROM @FinalResult WHERE ID=@startID)))
					UPDATE @FinalResult
					SET TabTimeDifference = @dateDIFF
					WHERE ID = @startID
				END
			END
		
		SET @startID =  @startID + 1
	END

	UPDATE @FinalResult SET TabTimeDifference = (SELECT SUM(ABS(ISNULL(TabTimeDifference,0))) 
												 FROM @FinalResult WHERE Ranking = @rankForTabTime)
	WHERE  Ranking = @rankForTabTime AND IsKeyRecord = 1

	UPDATE @AttempsResult SET EffortInSeconds = (SELECT TabTimeDifference FROM @FinalResult WHERE Ranking = @rankForTabTime AND IsKeyRecord = 1) 
	WHERE  RankID = @rankForTabTime
	
	SET @rankForTabTime = @rankForTabTime + 1
END
UPDATE @AttempsResult SET EffortInSeconds = (SELECT SUM(EffortInSeconds) FROM @AttempsResult WHERE RankID != 0) WHERE RankID = 0

--DEBUGING PURPOSE
--SELECT * FROM @FinalResult

IF EXISTS (SELECT Ranking FROM @FinalResult WHERE Ranking > 1)
BEGIN
	DECLARE @firstRankKeyRecordCreateDate DATETIME
	SET     @firstRankKeyRecordCreateDate = (SELECT TOP 1 CreateDate FROM @FinalResult WHERE Ranking = 1 ORDER BY EventLogID DESC)
	
	DECLARE @SecondRankKeyRecordCreateDate DATETIME
	SET     @SecondRankKeyRecordCreateDate = (SELECT TOP 1 CreateDate FROM @FinalResult WHERE Ranking = 2 ORDER BY EventLogID ASC)

	UPDATE @AttempsResult SET WaitingTimeInQueue = ABS(DATEDIFF(SS,@SecondRankKeyRecordCreateDate,@firstRankKeyRecordCreateDate))
	WHERE ID = 3

	DECLARE @waitStartCounter AS INT
    SET @waitStartCounter = 4

	DECLARE @maxStartCounter AS INT
	SET @maxStartCounter = (SELECT MAX(ID) FROM @AttempsResult)

	WHILE @waitStartCounter <= @maxStartCounter
	BEGIN
		UPDATE @AttempsResult SET 
		WaitingTimeInQueue = ABS(DATEDIFF(SS,(SELECT TOP 1 CreateDate FROM @FinalResult WHERE Ranking = 
																 (SELECT RankID FROM @AttempsResult WHERE ID = @waitStartCounter) 
																  ORDER BY EventLogID ASC),(SELECT TOP 1 CreateDate FROM @FinalResult WHERE Ranking = 
																 (SELECT RankID FROM @AttempsResult WHERE ID = @waitStartCounter - 1) ORDER BY EventLogID DESC)))
		WHERE ID = @waitStartCounter
		SET @waitStartCounter = @waitStartCounter + 1
	END
END

UPDATE @AttempsResult SET WaitingTimeInQueue = ISNULL((SELECT SUM(WaitingTimeInQueue) FROM @AttempsResult A WHERE ID > 1),0) WHERE ID = 1
RETURN
END

GO
