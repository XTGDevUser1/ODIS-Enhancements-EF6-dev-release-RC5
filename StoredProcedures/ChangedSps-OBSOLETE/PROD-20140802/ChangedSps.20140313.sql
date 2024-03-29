IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnIsUserConnected]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnIsUserConnected]
GO

CREATE FUNCTION dbo.fnIsUserConnected(@userName NVARCHAR(MAX)) RETURNS BIT
AS
BEGIN
	DECLARE @IsUserConnected BIT = 0

	IF((SELECT COUNT(NotificationID) FROM DesktopNotifications WHERE UserName = @userName AND IsConnected = 1) > 0)
	BEGIN
		SET @IsUserConnected = 1
	END

	RETURN @IsUserConnected
END


GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Call_Summary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Call_Summary]
GO

--EXEC dms_Call_Summary @serviceRequestID = 1431  
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
    ,(SELECT 'Agent Name:'+Value FROM @ProgramDataItemValues WHERE ScreenName='StartCall' AND Name='GlobalAssistAgent') AS Program_AgentName
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
-- SERVICE SECTION   
--	, 2 AS Service_DefaultNumberOfRows  
	, ISNULL(
		COALESCE(pc.Name, '') + 
		COALESCE('/' + CASE WHEN sr.IsPossibleTow = 1 THEN 'Possible Tow' END, '')
		,' ') as Service_ProductCategoryTow    
	, '$' + CONVERT(NVARCHAR(50),ISNULL(sr.CoverageLimit,0)) as Service_CoverageLimit  

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
 UPDATE @Hold SET DataType = 'LabelTheme' WHERE CHARINDEX('Member_Status',ColumnName) > 0    

 DELETE FROM @Hold WHERE ColumnValue IS NULL

 DECLARE @DefaultRows INT
 SET  @DefaultRows = (SELECT Sequence FROM @Hold WHERE ColumnName = 'Member_AltCallbackPhoneNumber')
 IF @DefaultRows IS NOT NULL
 BEGIN
 SET @DefaultRows = (SELECT COUNT(*) FROM @Hold WHERE ColumnName LIKE 'Member_%' AND Sequence <= @DefaultRows)
 -- Re Setting values 
 UPDATE @Hold SET DefaultRows = @DefaultRows WHERE GroupName = 'Member' 
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
 WHERE id = object_id(N'[dbo].[dms_Communication_Fax_Update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Communication_Fax_Update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dbo].[dms_Communication_Fax_Update] 'kbanda'
 CREATE PROCEDURE [dbo].[dms_Communication_Fax_Update](@userName NVARCHAR(50) = NULL)
 AS
 BEGIN
 
DECLARE @tmpRecordstoUpdate TABLE
(
CommunicationLogID INT NOT NULL,
ContactLogID INT NOT NULL,
[Status] nvarchar(255) NULL,
FaxResult nvarchar(2000) NULL,
FaxInfo nvarchar(2000)NULL,
sRank INT NOT NULL,
CommunicationLogCreateBy NVARCHAR(100) NULL
)
 
	
    -- To Update the Records in Batch
	--WITH wResult AS(
	INSERT INTO @tmpRecordstoUpdate
	SELECT	CL.ID,
			CL.ContactLogID,
			CL.[Status],
			FR.[result] AS FaxResult,
			FR.[info] AS FaxInfo,
			ROW_NUMBER() OVER(PARTITION BY FR.Billing_Code ORDER BY FR.[Date] DESC) AS 'SRank',
			CL.CreateBy
			FROM CommunicationLog CL
			 INNER JOIN FaxResult FR ON
			 FR.[billing_code] = CL.ID
			 WHERE ContactMethodID = (SELECT ID FROM ContactMethod WHERE Name = 'Fax')
			 AND [Status] = 'PENDING'

	UPDATE CommunicationLog 
	SET [Status] = T.FaxResult,
		Comments = T.FaxInfo,
		ModifyDate = getdate(),
		ModifyBy = @username 
	FROM CommunicationLog 
	JOIN @tmpRecordstoUpdate T on T.CommunicationLogID = CommunicationLog.ID
	WHERE T.sRank = 1
				 
	--UPDATE wResult SET wResult.[Status] = wResult.FaxResult,
	--				   wResult.Comments = wResult.[FaxInfo],
	--				   wResult.ModifyDate = getdate(),
	--				   wResult.ModifyBy = @userName 
	--				   WHERE SRank = 1
					   
	-- Create New Records in Batch if Contact Log ID is not NULL				   
	--;WITH wResultInsert AS(
	--SELECT CL.*,FR.[result] AS FaxResult,FR.[info] AS FaxInfo FROM CommunicationLog CL
	--		 INNER JOIN FaxResult FR ON
	--		 FR.[billing_code] = CL.ID
	--		 WHERE ContactMethodID = (SELECT ID FROM ContactMethod WHERE Name = 'Fax')
	--		 AND
	--		 [Status] IN ('SUCCESS','FAILURE')
	--		 AND ContactLogID IS NOT NULL)
	INSERT INTO ContactLogAction(ContactActionID,ContactLogID,Comments,CreateDate,CreateBy)
		   SELECT DISTINCT
		     Case FaxResult 
				WHEN 'SUCCESS' THEN (SELECT ID FROM ContactAction WHERE Name = 'Sent')
				ELSE (SELECT ID FROM ContactAction WHERE Name = 'SendFailure')
			END as ContactActionID,
		   [ContactLogID],FaxInfo,GETDATE(),@userName
		   FROM @tmpRecordstoUpdate
		   WHERE sRank = 1

	-- KB: Notifications
	-- For every communicationlog record whose status was set to FAIL, create eventlog records with event
	DECLARE @eventIDForSendPOFaxFailed INT,
			@eventDescriptionForSendPOFaxFailed NVARCHAR(255),
			@poEntityID INT,
			@contactLogActionEntityID INT,
			@idx INT = 1,
			@maxRows INT,
			@eventLogID INT,
			@sendFailureContactActionID INT

	SELECT	@eventIDForSendPOFaxFailed = ID, @eventDescriptionForSendPOFaxFailed = [Description] FROM [Event] WITH (NOLOCK) WHERE Name = 'SendPOFaxFailed'
	SELECT	@poEntityID = ID FROM Entity WHERE Name = 'PurchaseOrder'
	SELECT	@contactLogActionEntityID = ID FROM Entity WHERE Name = 'ContactLogAction'
	SELECT	@sendFailureContactActionID = ID FROM ContactAction WHERE Name = 'SendFailure'

	CREATE TABLE #tmpCommunicationLogFaxFailed
	(
		RowNum INT IDENTITY(1,1) NOT NULL,
		CommunicationLogID INT NOT NULL,
		ContactLogID INT NOT NULL,
		PurchaseOrderID INT NULL,
		PurchaseOrderNumber NVARCHAR(50) NULL,
		ServiceRequestNumber INT NULL,
		FailureReason NVARCHAR(MAX) NULL,
		CommunicationLogCreateBy NVARCHAR(100) NULL
	)

	INSERT INTO #tmpCommunicationLogFaxFailed 
	SELECT	T.CommunicationLogID,
			T.ContactLogID,
			CLL.RecordID,
			PO.PurchaseOrderNumber,
			PO.ServiceRequestID,
			T.FaxInfo,
			T.CommunicationLogCreateBy
	FROM	@tmpRecordstoUpdate T
	LEFT JOIN	ContactLogLink CLL ON T.ContactLogID = CLL.ContactLogID AND CLL.EntityID = @poEntityID
	LEFT JOIN	PurchaseOrder PO ON PO.ID = CLL.RecordID
	WHERE	T.FaxResult = 'FAILURE'
	AND		T.sRank = 1

	SELECT @maxRows = MAX(RowNum) FROM #tmpCommunicationLogFaxFailed


	--DEBUG: SELECT * FROM #tmpCommunicationLogFaxFailed

	DECLARE @purchaseOrderID INT,
			@serviceRequestID INT,
			@purchaseOrderNumber NVARCHAR(50),
			@contactLogID INT,
			@failureReason NVARCHAR(MAX),
			@commLogCreateBy NVARCHAR(100)

	WHILE ( @idx <= @maxRows )
	BEGIN
		
		SELECT	@contactLogID		= T.ContactLogID,
				@failureReason		= T.FailureReason,
				@purchaseOrderID	= T.PurchaseOrderID,
				@purchaseOrderNumber = T.PurchaseOrderNumber,
				@serviceRequestID	= T.ServiceRequestNumber,
				@commLogCreateBy	= T.CommunicationLogCreateBy
		FROM	#tmpCommunicationLogFaxFailed T WHERE T.RowNum = @idx

		-- For each communication log record related to fax failure, log an event and create link records - one per 
		INSERT INTO EventLog (	EventID,
								Source,
								Description,
								Data,
								NotificationQueueDate,
								CreateDate,
								CreateBy)
		SELECT	@eventIDForSendPOFaxFailed,
				'Communication Service',
				@eventDescriptionForSendPOFaxFailed,
				'<MessageData><PONumber>' + @purchaseOrderNumber + 
							'</PONumber><ServiceRequest>' + CONVERT(NVARCHAR(50),@serviceRequestID) + 
							'</ServiceRequest><FaxFailureReason>' + @failureReason + 
							'</FaxFailureReason><CreateByUser>' +  @commLogCreateBy
							'</CreateByUser></MessageData>',
				NULL,
				GETDATE(),
				'system'
		

		SET @eventLogID = SCOPE_IDENTITY()

		--DEBUG: SELECT @eventLogID AS EventLogID

		INSERT INTO EventLogLink ( EventLogID, EntityID, RecordID)
		SELECT	@eventLogID,
				@poEntityID,
				@purchaseOrderID

		;WITH wContactLogActions
		AS
		(
			SELECT	ROW_NUMBER() OVER ( PARTITION BY CLA.ContactActionID ORDER BY CLA.CreateDate DESC) As RowNum,
					CLA.ID As ContactLogActionID,
					CLA.ContactLogID
			FROM	ContactLogAction CLA 			
			WHERE	CLA.ContactLogID = @contactLogID
			AND		CLA.ContactActionID = @sendFailureContactActionID
		)

		INSERT INTO EventLogLink ( EventLogID, EntityID, RecordID)
		SELECT	@eventLogID,
				@contactLogActionEntityID,
				W.ContactLogActionID
		FROM	wContactLogActions W 
		WHERE	W.RowNum = 1


		SET @idx = @idx + 1
	END



	DROP TABLE #tmpCommunicationLogFaxFailed
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
-- EXEC [dbo].[dms_CurrentUser_For_Event_Get] 'kbanda'
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
			@agentUserID INT

	DECLARE @tmpCurrentUser TABLE
			(
				UserId UNIQUEIDENTIFIER NULL,
				UserName NVARCHAR(100) NULL
			)
	
	SELECT  @resendPONextActionID = ID FROM NextAction WITH (NOLOCK) WHERE Name = 'ResendPO'
	
	SELECT	@agentUserID = U.ID
	FROM	[User] U WITH (NOLOCK) 
	JOIN	aspnet_Users AU WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
	JOIN	aspnet_Applications A WITH (NOLOCK) ON A.ApplicationId = AU.ApplicationId
	WHERE	AU.UserName = 'Agent'
	AND		A.ApplicationName = 'DMS'

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
			
			IF ( (SELECT [dbo].[fnIsUserConnected](@CreateByUser) ) = 1)
			BEGIN
				
				INSERT INTO @tmpCurrentUser
				SELECT	AU.UserId,
						AU.UserName
				FROM	aspnet_Users AU WITH (NOLOCK) 
				JOIN	aspnet_Applications A WITH (NOLOCK) ON AU.ApplicationId = A.ApplicationId			
				WHERE	AU.UserName = @CreateByUser
				AND		A.ApplicationName = 'DMS'
				
			END
			ELSE
			BEGIN

				SELECT	@nextActionIDOnSR = SR.NextActionID,
						@nextActionAssignedToOnSR = SR.NextActionAssignedToUserID
				FROM	ServiceRequest SR WITH (NOLOCK) 
				WHERE ID = @ServiceRequest 

				IF @nextActionAssignedToOnSR IS NULL AND @nextActionIDOnSR IS NULL
				BEGIN
					
					UPDATE	ServiceRequest
					SET		NextActionID = @resendPONextActionID,
							NextActionAssignedToUserID = @agentUserID
					WHERE	ID = @ServiceRequest

				END
			END				
		END	
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
 WHERE id = object_id(N'[dbo].[dms_ProgramManagement_Service_Categories_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ProgramManagement_Service_Categories_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_ProgramManagement_Service_Categories_List_Get @programID = 22
 CREATE PROCEDURE [dbo].[dms_ProgramManagement_Service_Categories_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID INT  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
ProductCategoryIDOperator="-1" 
ProductCategoryNameOperator="-1" 
ProductCategoryDescriptionOperator="-1" 
ProgramIDOperator="-1" 
ProgramNameOperator="-1" 
ProgramDescriptionOperator="-1" 
VehicleCategoryIDOperator="-1" 
VehicleCategoryNameOperator="-1" 
VehicleCategoryDescriptionOperator="-1" 
VehicleTypeIDOperator="-1" 
VehicleTypeNameOperator="-1" 
vehicleTypeDescriptionOperator="-1" 
SequenceOperator="-1" 
IsActiveOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
ProductCategoryIDOperator INT NOT NULL,
ProductCategoryIDValue int NULL,
ProductCategoryNameOperator INT NOT NULL,
ProductCategoryNameValue nvarchar(100) NULL,
ProductCategoryDescriptionOperator INT NOT NULL,
ProductCategoryDescriptionValue nvarchar(100) NULL,
ProgramIDOperator INT NOT NULL,
ProgramIDValue int NULL,
ProgramNameOperator INT NOT NULL,
ProgramNameValue nvarchar(100) NULL,
ProgramDescriptionOperator INT NOT NULL,
ProgramDescriptionValue nvarchar(100) NULL,
VehicleCategoryIDOperator INT NOT NULL,
VehicleCategoryIDValue int NULL,
VehicleCategoryNameOperator INT NOT NULL,
VehicleCategoryNameValue nvarchar(100) NULL,
VehicleCategoryDescriptionOperator INT NOT NULL,
VehicleCategoryDescriptionValue nvarchar(100) NULL,
VehicleTypeIDOperator INT NOT NULL,
VehicleTypeIDValue int NULL,
VehicleTypeNameOperator INT NOT NULL,
VehicleTypeNameValue nvarchar(100) NULL,
vehicleTypeDescriptionOperator INT NOT NULL,
vehicleTypeDescriptionValue nvarchar(100) NULL,
SequenceOperator INT NOT NULL,
SequenceValue int NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue bit NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	ProductCategoryID int  NULL ,
	ProductCategoryName nvarchar(100)  NULL ,
	ProductCategoryDescription nvarchar(100)  NULL ,
	ProgramID int  NULL ,
	ProgramName nvarchar(100)  NULL ,
	ProgramDescription nvarchar(100)  NULL ,
	VehicleCategoryID int  NULL ,
	VehicleCategoryName nvarchar(100)  NULL ,
	VehicleCategoryDescription nvarchar(100)  NULL ,
	VehicleTypeID int  NULL ,
	VehicleTypeName nvarchar(100)  NULL ,
	vehicleTypeDescription nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsActive bit  NULL 
) 
CREATE TABLE #tmp_FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	ProductCategoryID int  NULL ,
	ProductCategoryName nvarchar(100)  NULL ,
	ProductCategoryDescription nvarchar(100)  NULL ,
	ProgramID int  NULL ,
	ProgramName nvarchar(100)  NULL ,
	ProgramDescription nvarchar(100)  NULL ,
	VehicleCategoryID int  NULL ,
	VehicleCategoryName nvarchar(100)  NULL ,
	VehicleCategoryDescription nvarchar(100)  NULL ,
	VehicleTypeID int  NULL ,
	VehicleTypeName nvarchar(100)  NULL ,
	vehicleTypeDescription nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsActive bit  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@ProductCategoryIDOperator','INT'),-1),
	T.c.value('@ProductCategoryIDValue','int') ,
	ISNULL(T.c.value('@ProductCategoryNameOperator','INT'),-1),
	T.c.value('@ProductCategoryNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProductCategoryDescriptionOperator','INT'),-1),
	T.c.value('@ProductCategoryDescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProgramIDOperator','INT'),-1),
	T.c.value('@ProgramIDValue','int') ,
	ISNULL(T.c.value('@ProgramNameOperator','INT'),-1),
	T.c.value('@ProgramNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProgramDescriptionOperator','INT'),-1),
	T.c.value('@ProgramDescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleCategoryIDOperator','INT'),-1),
	T.c.value('@VehicleCategoryIDValue','int') ,
	ISNULL(T.c.value('@VehicleCategoryNameOperator','INT'),-1),
	T.c.value('@VehicleCategoryNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleCategoryDescriptionOperator','INT'),-1),
	T.c.value('@VehicleCategoryDescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleTypeIDOperator','INT'),-1),
	T.c.value('@VehicleTypeIDValue','int') ,
	ISNULL(T.c.value('@VehicleTypeNameOperator','INT'),-1),
	T.c.value('@VehicleTypeNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@vehicleTypeDescriptionOperator','INT'),-1),
	T.c.value('@vehicleTypeDescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@SequenceOperator','INT'),-1),
	T.c.value('@SequenceValue','int') ,
	ISNULL(T.c.value('@IsActiveOperator','INT'),-1),
	T.c.value('@IsActiveValue','bit') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmp_FinalResults
SELECT 
	PPC.ID,
	PPC.ProductCategoryID,
	PC.Name AS ProductCategoryName,
	PC.Description AS ProductCategoryDescription,
	PPC.ProgramID,
	P.Name AS ProgramName,
	P.Description AS ProgramDescription,
	PPC.VehicleCategoryID,
	VC.Name AS VehicleCategoryName,
	VC.Description AS VehicleCategoryDescription,
	PPC.VehicleTypeID,
	VT.Name AS VehicleTypeName,
	VT.Description AS vehicleTypeDescription,
	PPC.Sequence,
	PPC.IsActive
FROM ProgramProductCategory ppc
LEFT JOIN Program P ON P.ID = PPC.ProgramID
LEFT JOIN ProductCategory PC ON PC.ID = PPC.ProductCategoryID
LEFT JOIN VehicleCategory VC ON VC.ID = PPC.VehicleCategoryID
LEFT JOIN VehicleType VT ON VT.ID=PPC.VehicleTypeID
WHERE PPC.ProgramID = @programID
INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.ProductCategoryID,
	T.ProductCategoryName,
	T.ProductCategoryDescription,
	T.ProgramID,
	T.ProgramName,
	T.ProgramDescription,
	T.VehicleCategoryID,
	T.VehicleCategoryName,
	T.VehicleCategoryDescription,
	T.VehicleTypeID,
	T.VehicleTypeName,
	T.vehicleTypeDescription,
	T.Sequence,
	T.IsActive
FROM #tmp_FinalResults T,
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
	 ( TMP.ProductCategoryIDOperator = -1 ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 0 AND T.ProductCategoryID IS NULL ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 1 AND T.ProductCategoryID IS NOT NULL ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 2 AND T.ProductCategoryID = TMP.ProductCategoryIDValue ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 3 AND T.ProductCategoryID <> TMP.ProductCategoryIDValue ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 7 AND T.ProductCategoryID > TMP.ProductCategoryIDValue ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 8 AND T.ProductCategoryID >= TMP.ProductCategoryIDValue ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 9 AND T.ProductCategoryID < TMP.ProductCategoryIDValue ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 10 AND T.ProductCategoryID <= TMP.ProductCategoryIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ProductCategoryNameOperator = -1 ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 0 AND T.ProductCategoryName IS NULL ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 1 AND T.ProductCategoryName IS NOT NULL ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 2 AND T.ProductCategoryName = TMP.ProductCategoryNameValue ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 3 AND T.ProductCategoryName <> TMP.ProductCategoryNameValue ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 4 AND T.ProductCategoryName LIKE TMP.ProductCategoryNameValue + '%') 
 OR 
	 ( TMP.ProductCategoryNameOperator = 5 AND T.ProductCategoryName LIKE '%' + TMP.ProductCategoryNameValue ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 6 AND T.ProductCategoryName LIKE '%' + TMP.ProductCategoryNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProductCategoryDescriptionOperator = -1 ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 0 AND T.ProductCategoryDescription IS NULL ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 1 AND T.ProductCategoryDescription IS NOT NULL ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 2 AND T.ProductCategoryDescription = TMP.ProductCategoryDescriptionValue ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 3 AND T.ProductCategoryDescription <> TMP.ProductCategoryDescriptionValue ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 4 AND T.ProductCategoryDescription LIKE TMP.ProductCategoryDescriptionValue + '%') 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 5 AND T.ProductCategoryDescription LIKE '%' + TMP.ProductCategoryDescriptionValue ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 6 AND T.ProductCategoryDescription LIKE '%' + TMP.ProductCategoryDescriptionValue + '%' ) 
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
	 ( TMP.ProgramDescriptionOperator = -1 ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 0 AND T.ProgramDescription IS NULL ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 1 AND T.ProgramDescription IS NOT NULL ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 2 AND T.ProgramDescription = TMP.ProgramDescriptionValue ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 3 AND T.ProgramDescription <> TMP.ProgramDescriptionValue ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 4 AND T.ProgramDescription LIKE TMP.ProgramDescriptionValue + '%') 
 OR 
	 ( TMP.ProgramDescriptionOperator = 5 AND T.ProgramDescription LIKE '%' + TMP.ProgramDescriptionValue ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 6 AND T.ProgramDescription LIKE '%' + TMP.ProgramDescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VehicleCategoryIDOperator = -1 ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 0 AND T.VehicleCategoryID IS NULL ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 1 AND T.VehicleCategoryID IS NOT NULL ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 2 AND T.VehicleCategoryID = TMP.VehicleCategoryIDValue ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 3 AND T.VehicleCategoryID <> TMP.VehicleCategoryIDValue ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 7 AND T.VehicleCategoryID > TMP.VehicleCategoryIDValue ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 8 AND T.VehicleCategoryID >= TMP.VehicleCategoryIDValue ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 9 AND T.VehicleCategoryID < TMP.VehicleCategoryIDValue ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 10 AND T.VehicleCategoryID <= TMP.VehicleCategoryIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.VehicleCategoryNameOperator = -1 ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 0 AND T.VehicleCategoryName IS NULL ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 1 AND T.VehicleCategoryName IS NOT NULL ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 2 AND T.VehicleCategoryName = TMP.VehicleCategoryNameValue ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 3 AND T.VehicleCategoryName <> TMP.VehicleCategoryNameValue ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 4 AND T.VehicleCategoryName LIKE TMP.VehicleCategoryNameValue + '%') 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 5 AND T.VehicleCategoryName LIKE '%' + TMP.VehicleCategoryNameValue ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 6 AND T.VehicleCategoryName LIKE '%' + TMP.VehicleCategoryNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VehicleCategoryDescriptionOperator = -1 ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 0 AND T.VehicleCategoryDescription IS NULL ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 1 AND T.VehicleCategoryDescription IS NOT NULL ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 2 AND T.VehicleCategoryDescription = TMP.VehicleCategoryDescriptionValue ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 3 AND T.VehicleCategoryDescription <> TMP.VehicleCategoryDescriptionValue ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 4 AND T.VehicleCategoryDescription LIKE TMP.VehicleCategoryDescriptionValue + '%') 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 5 AND T.VehicleCategoryDescription LIKE '%' + TMP.VehicleCategoryDescriptionValue ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 6 AND T.VehicleCategoryDescription LIKE '%' + TMP.VehicleCategoryDescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VehicleTypeIDOperator = -1 ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 0 AND T.VehicleTypeID IS NULL ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 1 AND T.VehicleTypeID IS NOT NULL ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 2 AND T.VehicleTypeID = TMP.VehicleTypeIDValue ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 3 AND T.VehicleTypeID <> TMP.VehicleTypeIDValue ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 7 AND T.VehicleTypeID > TMP.VehicleTypeIDValue ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 8 AND T.VehicleTypeID >= TMP.VehicleTypeIDValue ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 9 AND T.VehicleTypeID < TMP.VehicleTypeIDValue ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 10 AND T.VehicleTypeID <= TMP.VehicleTypeIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.VehicleTypeNameOperator = -1 ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 0 AND T.VehicleTypeName IS NULL ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 1 AND T.VehicleTypeName IS NOT NULL ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 2 AND T.VehicleTypeName = TMP.VehicleTypeNameValue ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 3 AND T.VehicleTypeName <> TMP.VehicleTypeNameValue ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 4 AND T.VehicleTypeName LIKE TMP.VehicleTypeNameValue + '%') 
 OR 
	 ( TMP.VehicleTypeNameOperator = 5 AND T.VehicleTypeName LIKE '%' + TMP.VehicleTypeNameValue ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 6 AND T.VehicleTypeName LIKE '%' + TMP.VehicleTypeNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.vehicleTypeDescriptionOperator = -1 ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 0 AND T.vehicleTypeDescription IS NULL ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 1 AND T.vehicleTypeDescription IS NOT NULL ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 2 AND T.vehicleTypeDescription = TMP.vehicleTypeDescriptionValue ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 3 AND T.vehicleTypeDescription <> TMP.vehicleTypeDescriptionValue ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 4 AND T.vehicleTypeDescription LIKE TMP.vehicleTypeDescriptionValue + '%') 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 5 AND T.vehicleTypeDescription LIKE '%' + TMP.vehicleTypeDescriptionValue ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 6 AND T.vehicleTypeDescription LIKE '%' + TMP.vehicleTypeDescriptionValue + '%' ) 
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

	 CASE WHEN @sortColumn = 'ProductCategoryID' AND @sortOrder = 'ASC'
	 THEN T.ProductCategoryID END ASC, 
	 CASE WHEN @sortColumn = 'ProductCategoryID' AND @sortOrder = 'DESC'
	 THEN T.ProductCategoryID END DESC ,

	 CASE WHEN @sortColumn = 'ProductCategoryName' AND @sortOrder = 'ASC'
	 THEN T.ProductCategoryName END ASC, 
	 CASE WHEN @sortColumn = 'ProductCategoryName' AND @sortOrder = 'DESC'
	 THEN T.ProductCategoryName END DESC ,

	 CASE WHEN @sortColumn = 'ProductCategoryDescription' AND @sortOrder = 'ASC'
	 THEN T.ProductCategoryDescription END ASC, 
	 CASE WHEN @sortColumn = 'ProductCategoryDescription' AND @sortOrder = 'DESC'
	 THEN T.ProductCategoryDescription END DESC ,

	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'ASC'
	 THEN T.ProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'DESC'
	 THEN T.ProgramID END DESC ,

	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'ASC'
	 THEN T.ProgramName END ASC, 
	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'DESC'
	 THEN T.ProgramName END DESC ,

	 CASE WHEN @sortColumn = 'ProgramDescription' AND @sortOrder = 'ASC'
	 THEN T.ProgramDescription END ASC, 
	 CASE WHEN @sortColumn = 'ProgramDescription' AND @sortOrder = 'DESC'
	 THEN T.ProgramDescription END DESC ,

	 CASE WHEN @sortColumn = 'VehicleCategoryID' AND @sortOrder = 'ASC'
	 THEN T.VehicleCategoryID END ASC, 
	 CASE WHEN @sortColumn = 'VehicleCategoryID' AND @sortOrder = 'DESC'
	 THEN T.VehicleCategoryID END DESC ,

	 CASE WHEN @sortColumn = 'VehicleCategoryName' AND @sortOrder = 'ASC'
	 THEN T.VehicleCategoryName END ASC, 
	 CASE WHEN @sortColumn = 'VehicleCategoryName' AND @sortOrder = 'DESC'
	 THEN T.VehicleCategoryName END DESC ,

	 CASE WHEN @sortColumn = 'VehicleCategoryDescription' AND @sortOrder = 'ASC'
	 THEN T.VehicleCategoryDescription END ASC, 
	 CASE WHEN @sortColumn = 'VehicleCategoryDescription' AND @sortOrder = 'DESC'
	 THEN T.VehicleCategoryDescription END DESC ,

	 CASE WHEN @sortColumn = 'VehicleTypeID' AND @sortOrder = 'ASC'
	 THEN T.VehicleTypeID END ASC, 
	 CASE WHEN @sortColumn = 'VehicleTypeID' AND @sortOrder = 'DESC'
	 THEN T.VehicleTypeID END DESC ,

	 CASE WHEN @sortColumn = 'VehicleTypeName' AND @sortOrder = 'ASC'
	 THEN T.VehicleTypeName END ASC, 
	 CASE WHEN @sortColumn = 'VehicleTypeName' AND @sortOrder = 'DESC'
	 THEN T.VehicleTypeName END DESC ,

	 CASE WHEN @sortColumn = 'vehicleTypeDescription' AND @sortOrder = 'ASC'
	 THEN T.vehicleTypeDescription END ASC, 
	 CASE WHEN @sortColumn = 'vehicleTypeDescription' AND @sortOrder = 'DESC'
	 THEN T.vehicleTypeDescription END DESC ,

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
DROP TABLE #tmp_FinalResults
END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ProgramManagement_VehicleTypes_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ProgramManagement_VehicleTypes_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_ProgramManagement_Service_Categories_List_Get @programID = 22
 CREATE PROCEDURE [dbo].[dms_ProgramManagement_VehicleTypes_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID INT  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
VehicleTypeOperator="-1" 
MaxAllowedOperator="-1" 
IsActiveOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
VehicleTypeOperator INT NOT NULL,
VehicleTypeValue NVARCHAR(50) NULL,
MaxAllowedOperator INT NOT NULL,
MaxAllowedValue int NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue bit NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	VehicleType NVARCHAR(50)  NULL ,
	MaxAllowed int  NULL ,
	IsActive bit  NULL 
) 
CREATE TABLE #tmp_FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	VehicleType NVARCHAR(50)  NULL ,
	MaxAllowed int  NULL ,
	IsActive bit  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@VehicleTypeOperator','INT'),-1),
	T.c.value('@VehicleTypeValue','nvarchar(50)') ,
	ISNULL(T.c.value('@MaxAllowedOperator','INT'),-1),
	T.c.value('@MaxAllowedValue','int') ,
	ISNULL(T.c.value('@IsActiveOperator','INT'),-1),
	T.c.value('@IsActiveValue','bit') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

;WITH wProgramConfig 
		AS
		(	SELECT ROW_NUMBER() OVER ( PARTITION BY V.Name ORDER BY PP.Sequence) AS RowNum,
					V.[Description] VehicleType,
					PV.MaxAllowed,
					PV.IsActive,
					PV.ID
			FROM fnc_GetProgramsandParents(@programID) PP
			JOIN ProgramVehicleType PV ON PV.ProgramID = PP.ProgramID 
			JOIN VehicleType V ON V.ID = PV.VehicleTypeID
			
		)
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmp_FinalResults
SELECT 
    W.ID,
    W.VehicleType,
	W.MaxAllowed,
	W.IsActive
FROM wProgramConfig W
	 WHERE	W.RowNum = 1
	 ORDER BY W.ID
		 
INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.VehicleType,
	T.MaxAllowed,
	T.IsActive
FROM #tmp_FinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.VehicleTypeOperator = -1 ) 
 OR 
	 ( TMP.VehicleTypeOperator = 0 AND T.VehicleType IS NULL ) 
 OR 
	 ( TMP.VehicleTypeOperator = 1 AND T.VehicleType IS NOT NULL ) 
 OR 
	 ( TMP.VehicleTypeOperator = 2 AND T.VehicleType = TMP.VehicleTypeValue ) 
 OR 
	 ( TMP.VehicleTypeOperator = 3 AND T.VehicleType <> TMP.VehicleTypeValue ) 
 OR 
	 ( TMP.VehicleTypeOperator = 4 AND T.VehicleType LIKE TMP.VehicleTypeValue + '%') 
 OR 
	 ( TMP.VehicleTypeOperator = 5 AND T.VehicleType LIKE '%' + TMP.VehicleTypeValue ) 
 OR 
	 ( TMP.VehicleTypeOperator = 6 AND T.VehicleType LIKE '%' + TMP.VehicleTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.MaxAllowedOperator = -1 ) 
 OR 
	 ( TMP.MaxAllowedOperator = 0 AND T.MaxAllowed IS NULL ) 
 OR 
	 ( TMP.MaxAllowedOperator = 1 AND T.MaxAllowed IS NOT NULL ) 
 OR 
	 ( TMP.MaxAllowedOperator = 2 AND T.MaxAllowed = TMP.MaxAllowedValue ) 
 OR 
	 ( TMP.MaxAllowedOperator = 3 AND T.MaxAllowed <> TMP.MaxAllowedValue ) 
 OR 
	 ( TMP.MaxAllowedOperator = 7 AND T.MaxAllowed > TMP.MaxAllowedValue ) 
 OR 
	 ( TMP.MaxAllowedOperator = 8 AND T.MaxAllowed >= TMP.MaxAllowedValue ) 
 OR 
	 ( TMP.MaxAllowedOperator = 9 AND T.MaxAllowed < TMP.MaxAllowedValue ) 
 OR 
	 ( TMP.MaxAllowedOperator = 10 AND T.MaxAllowed <= TMP.MaxAllowedValue ) 

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
	 CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'ASC'
	 THEN T.VehicleType END ASC, 
	 CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'DESC'
	 THEN T.VehicleType END DESC ,

	 CASE WHEN @sortColumn = 'MaxAllowed' AND @sortOrder = 'ASC'
	 THEN T.MaxAllowed END ASC, 
	 CASE WHEN @sortColumn = 'MaxAllowed' AND @sortOrder = 'DESC'
	 THEN T.MaxAllowed END DESC ,

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
DROP TABLE #tmp_FinalResults
END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_DeleteServiceCategoryInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_DeleteServiceCategoryInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Program_Management_DeleteServiceCategoryInformation 34
 CREATE PROCEDURE [dbo].[dms_Program_Management_DeleteServiceCategoryInformation]( 
 @id INT 
 )
 AS
 BEGIN
	DELETE FROM ProgramProductCategory WHERE ID = @id
 END
 
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_DeleteServiceInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_DeleteServiceInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Program_Management_DeleteServiceInformation 34
 CREATE PROCEDURE [dbo].[dms_Program_Management_DeleteServiceInformation]( 
 @id INT 
 )
 AS
 BEGIN
	DELETE FROM ProgramProduct WHERE ID = @id
 END
 
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_GetProgramConfiguration]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_GetProgramConfiguration] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_GetProgramConfiguration]( 
 @programConfigurationId INT
 )
 AS
 BEGIN
 SELECT 
	    ConfigurationTypeID,
	    ConfigurationCategoryID,
	    ControlTypeID,
	    DataTypeID,
	    Name,
	    Value,
	    IsActive,
	    Sequence,
	    CreateDate,
	    CreateBy,
	    ModifyDate,
	    ModifyBy
 FROM ProgramConfiguration
 WHERE ID=@programConfigurationId
 END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_GetProgramServiceCategory]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_GetProgramServiceCategory] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Program_Management_GetProgramServiceCategory 100
 CREATE PROCEDURE [dbo].[dms_Program_Management_GetProgramServiceCategory]( 
 @programServiceCategoryId INT
 )
 AS
 BEGIN
 DECLARE @maxSequnceNumber INT =0
 DECLARE @bitIsActive BIT = 0
 SET @maxSequnceNumber = (SELECT MAX(Sequence) FROM ProgramProductCategory)
 IF EXISTS (SELECT * FROM ProgramProductCategory WHERE ID = @programServiceCategoryId)
 BEGIN
	 SELECT 
		PPC.ID,
		PPC.ProductCategoryID,
		PPC.ProgramID,
		PPC.VehicleCategoryID,
		PPC.VehicleTypeID,
		PPC.Sequence,
		PPC.IsActive,
		@maxSequnceNumber+1 AS MaxSequnceNumber
	
FROM ProgramProductCategory ppc
WHERE PPC.ID = @programServiceCategoryId
END
ELSE
BEGIN 
	SELECT
		0 AS ID,
		1 AS ProductCategoryID,
		0 AS ProgramID,
		null AS VehicleCategoryID,
		null AS VehicleTypeID,
		null AS Sequence,
		@bitIsActive AS IsActive,
		@maxSequnceNumber+1 AS MaxSequnceNumber
		
END
 END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_GetProgramVehicleTypeDetails]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_GetProgramVehicleTypeDetails] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_GetProgramVehicleTypeDetails]( 
 @programVehicleTypeId INT
 )
 AS
 BEGIN
	SET FMTONLY OFF
 	SET NOCOUNT ON
 	
   SELECT ID,
          VehicleTypeID,
          MaxAllowed,
          IsActive
   FROM ProgramVehicleType
   WHERE ID=@programVehicleTypeId
 END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Program_Management_Information]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Program_Management_Information] 
END 
GO
CREATE PROC dms_Program_Management_Information(@ProgramID INT = NULL)
AS
BEGIN
	SELECT   
			   P.ID ProgramID
			 , C.ID AS ClientID
			 , C.Name AS ClientName
			 , P.ParentProgramID AS ParentID
			 , PP.Name AS ParentName
			 , P.Name AS ProgramName
			 , P.Description AS ProgramDescription
			 , P.IsActive AS IsActive
			 , P.Code AS Code
			 , P.IsServiceGuaranteed			
			 , P.CallFee
			 , P.DispatchFee
			 , P.IsAudited
			 , P.IsClosedLoopAutomated
			 , P.IsGroup
			 , P.IsWebRegistrationEnabled
			 , P.CreateBy
			 , P.CreateDate
			 , P.ModifyBy
			 , P.ModifyDate
			 , '' AS PageMode
	FROM       Program P (NOLOCK)
	JOIN       Client C (NOLOCK) ON C.ID = P.ClientID
	LEFT JOIN  Program PP (NOLOCK) ON PP.ID = P.ParentProgramID
	WHERE      P.ID = @ProgramID
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
 -- EXEC dms_Program_Management_ProgramConfigurationList @programID = 1,@pageSize=50
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_ProgramConfigurationList]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_ProgramConfigurationList] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_ProgramConfigurationList]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID INT = NULL
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
    SET FMTONLY OFF
    
DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
ProgramConfigurationIDOperator="-1" 
ConfigurationTypeOperator="-1" 
ConfigurationCategoryOperator="-1" 
NameOperator="-1" 
ValueOperator="-1" 
ControlTypeOperator="-1" 
DataTypeOperator="-1" 
IsActiveOperator="-1" 
SequenceOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

CREATE TABLE #tmpForWhereClause
(
ProgramConfigurationIDOperator INT NOT NULL,
ProgramConfigurationIDValue INT NULL,
ConfigurationTypeOperator INT NOT NULL,
ConfigurationTypeValue nvarchar(50) NULL,
ConfigurationCategoryOperator INT NOT NULL,
ConfigurationCategoryValue nvarchar(50) NULL,
NameOperator INT NOT NULL,
NameValue nvarchar(50) NULL,
ValueOperator INT NOT NULL,
ValueValue nvarchar(50) NULL,
ControlTypeOperator INT NOT NULL,
ControlTypeValue nvarchar(50) NULL,
DataTypeOperator INT NOT NULL,
DataTypeValue nvarchar(50) NULL,
SequenceOperator INT NOT NULL,
SequenceValue INT NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue nvarchar(50) NULL
)

CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramConfigurationID int  NULL ,
	ConfigurationType nvarchar(50) NULL,
	ConfigurationCategory nvarchar(50) NULL,
	Name nvarchar(MAX)  NULL ,
	Value nvarchar(MAX)  NULL ,
	IsActive nvarchar(50)  NULL ,
	ControlType nvarchar(50) NULL,
	DataType nvarchar(50) NULL,
	Sequence INT NULL
) 
DECLARE @QueryResult AS TABLE( 
	ProgramConfigurationID int  NULL ,
	ConfigurationType nvarchar(50) NULL,
	ConfigurationCategory nvarchar(50) NULL,
	Name nvarchar(MAX)  NULL ,
	Value nvarchar(MAX)  NULL ,
	IsActive nvarchar(50)  NULL ,
	ControlType nvarchar(50) NULL,
	DataType nvarchar(50) NULL,
	Sequence INT NULL
) 

;WITH wProgramConfig 
		AS
		(	SELECT ROW_NUMBER() OVER ( PARTITION BY PC.Name ORDER BY PP.Sequence) AS RowNum,
					PC.ID ProgramConfigurationID,
					PC.Sequence,
					PC.Name,	
					PC.Value,
					CASE ISNULL(PC.IsActive,0) WHEN 0 THEN 'No' ELSE 'Yes' END IsActiveText,
					CT.Name ControlType,
					DT.Name DataType,
					C.Name ConfigurationType,
					CC.Name ConfigurationCategory
			FROM fnc_GetProgramsandParents(@ProgramID) PP
			JOIN ProgramConfiguration PC ON PP.ProgramID = PC.ProgramID AND PC.IsActive = 1
			LEFT JOIN ConfigurationType C ON PC.ConfigurationTypeID = C.ID 
			LEFT JOIN ControlType CT ON CT.ID = PC.ControlTypeID
			LEFT JOIN DataType DT ON DT.ID = PC.DataTypeID
			LEFT JOIN ConfigurationCategory CC ON PC.ConfigurationCategoryID = CC.ID
			--WHERE	(@ConfigurationType IS NULL OR C.Name = @ConfigurationType)
			--AND		(@ConfigurationCategory IS NULL OR CC.Name = @ConfigurationCategory)
		)
INSERT INTO @QueryResult SELECT W.ProgramConfigurationID,	
								W.ConfigurationType,
								W.ConfigurationCategory,
								W.Name,
								W.Value,
								W.IsActiveText,
								W.ControlType,
								W.DataType,
								W.Sequence
						FROM	wProgramConfig W
						 WHERE	W.RowNum = 1
					   ORDER BY W.ProgramConfigurationID


INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(ProgramConfigurationIDOperator,-1),
	ProgramConfigurationIDValue ,
	ISNULL(ConfigurationTypeOperator,-1),
	ConfigurationTypeValue ,
	ISNULL(ConfigurationCategoryOperator,-1),
	ConfigurationCategoryValue ,
	ISNULL(NameOperator,-1),
	NameValue ,
	ISNULL(ValueOperator,-1),
	ValueValue,
	ISNULL(ControlTypeOperator,-1),
	ControlTypeValue , 
	ISNULL(DataTypeOperator,-1),
	DataTypeValue , 
	ISNULL(SequenceOperator,-1),
	SequenceValue,
	ISNULL(IsActiveOperator,-1),
	IsActiveValue
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
ProgramConfigurationIDOperator INT,
ProgramConfigurationIDValue int 
,ConfigurationTypeOperator INT,
ConfigurationTypeValue nvarchar(50) 
,ConfigurationCategoryOperator INT,
ConfigurationCategoryValue nvarchar(50) 
,NameOperator INT,
NameValue nvarchar(50) 
,ValueOperator INT,
ValueValue nvarchar(50) 
,ControlTypeOperator INT,
ControlTypeValue nvarchar(50) 
,DataTypeOperator INT,
DataTypeValue nvarchar(50)
,SequenceOperator INT,
SequenceValue nvarchar(50)
,IsActiveOperator INT,
IsActiveValue nvarchar(50)    
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.ProgramConfigurationID,
	T.ConfigurationType,
	T.ConfigurationCategory,
	T.Name,
	T.Value,
	T.IsActive,
	T.ControlType,
	T.DataType,
	T.Sequence
FROM @QueryResult T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.ProgramConfigurationIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 0 AND T.ProgramConfigurationID IS NULL ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 1 AND T.ProgramConfigurationID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 2 AND T.ProgramConfigurationID = TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 3 AND T.ProgramConfigurationID <> TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 7 AND T.ProgramConfigurationID > TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 8 AND T.ProgramConfigurationID >= TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 9 AND T.ProgramConfigurationID < TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 10 AND T.ProgramConfigurationID <= TMP.ProgramConfigurationIDValue ) 

 ) 
  AND 

 ( 
	 ( TMP.ConfigurationTypeOperator = -1 ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 0 AND T.ConfigurationType IS NULL ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 1 AND T.ConfigurationType IS NOT NULL ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 2 AND T.ConfigurationType = TMP.ConfigurationTypeValue ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 3 AND T.ConfigurationType <> TMP.ConfigurationTypeValue ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 4 AND T.ConfigurationType LIKE TMP.ConfigurationTypeValue + '%') 
 OR 
	 ( TMP.ConfigurationTypeOperator = 5 AND T.ConfigurationType LIKE '%' + TMP.ConfigurationTypeValue ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 6 AND T.ConfigurationType LIKE '%' + TMP.ConfigurationTypeValue + '%' ) 
 ) 
 AND 

 ( 
	 ( TMP.ConfigurationCategoryOperator = -1 ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 0 AND T.ConfigurationCategory IS NULL ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 1 AND T.ConfigurationCategory IS NOT NULL ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 2 AND T.ConfigurationCategory = TMP.ConfigurationCategoryValue ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 3 AND T.ConfigurationCategory <> TMP.ConfigurationCategoryValue ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 4 AND T.ConfigurationCategory LIKE TMP.ConfigurationCategoryValue + '%') 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 5 AND T.ConfigurationCategory LIKE '%' + TMP.ConfigurationCategoryValue ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 6 AND T.ConfigurationCategory LIKE '%' + TMP.ConfigurationCategoryValue + '%' ) 
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
	 ( TMP.IsActiveOperator = -1 ) 
 OR 
	 ( TMP.IsActiveOperator = 0 AND T.IsActive IS NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 1 AND T.IsActive IS NOT NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 2 AND T.IsActive = TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 3 AND T.IsActive <> TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 4 AND T.IsActive LIKE TMP.IsActiveValue + '%') 
 OR 
	 ( TMP.IsActiveOperator = 5 AND T.IsActive LIKE '%' + TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 6 AND T.IsActive LIKE '%' + TMP.IsActiveValue + '%' ) 
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
	 ( TMP.ValueOperator = -1 ) 
 OR 
	 ( TMP.ValueOperator = 0 AND T.Value IS NULL ) 
 OR 
	 ( TMP.ValueOperator = 1 AND T.Value IS NOT NULL ) 
 OR 
	 ( TMP.ValueOperator = 2 AND T.Value = TMP.ValueValue ) 
 OR 
	 ( TMP.ValueOperator = 3 AND T.Value <> TMP.ValueValue ) 
 OR 
	 ( TMP.ValueOperator = 4 AND T.Value LIKE TMP.ValueValue + '%') 
 OR 
	 ( TMP.ValueOperator = 5 AND T.Value LIKE '%' + TMP.ValueValue ) 
 OR 
	 ( TMP.ValueOperator = 6 AND T.Value LIKE '%' + TMP.ValueValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ProgramConfigurationID' AND @sortOrder = 'ASC'
	 THEN T.ProgramConfigurationID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramConfigurationID' AND @sortOrder = 'DESC'
	 THEN T.ProgramConfigurationID END DESC ,

	 CASE WHEN @sortColumn = 'ConfigurationType' AND @sortOrder = 'ASC'
	 THEN T.ConfigurationType END ASC, 
	 CASE WHEN @sortColumn = 'ConfigurationType' AND @sortOrder = 'DESC'
	 THEN T.ConfigurationType END DESC ,

     CASE WHEN @sortColumn = 'ConfigurationCategory' AND @sortOrder = 'ASC'
	 THEN T.ConfigurationCategory END ASC, 
	 CASE WHEN @sortColumn = 'ConfigurationCategory' AND @sortOrder = 'DESC'
	 THEN T.ConfigurationCategory END DESC ,
	 
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
	 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Value' AND @sortOrder = 'ASC'
	 THEN T.Value END ASC, 
	 CASE WHEN @sortColumn = 'Value' AND @sortOrder = 'DESC'
	 THEN T.Value END DESC ,

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
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveProgramConfiguration]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveProgramConfiguration] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveProgramConfiguration]( 
 @programConfigurationId INT,
 @configurationTypeID INT=NULL,
 @configurationCategoryID INT=NULL,
 @controlTypeID INT=NULL,
 @dataTypeID INT=NULL,
 @name nvarchar(50)=NULL,
 @value nvarchar(4000)=NULL,
 @sequence INT=NULL,
 @user nvarchar(50)=NULL,
 @modifiedOn datetime=NULL,
 @isAdd bit,
 @programID int
 )
 AS
 BEGIN
 
 IF @isAdd=1 
 BEGIN
 
	INSERT INTO ProgramConfiguration(ProgramID,ConfigurationTypeID,ConfigurationCategoryID,ControlTypeID,DataTypeID,Name,Value,IsActive,Sequence,CreateDate,CreateBy)
	VALUES(@programID,@configurationTypeID,@configurationCategoryID,@controlTypeID,@dataTypeID,@name,@value,1,@sequence,@modifiedOn,@user)
	
 END
 ELSE BEGIN
 
	UPDATE ProgramConfiguration
	SET ConfigurationTypeID=@configurationTypeID,
		ConfigurationCategoryID=@configurationCategoryID,
		ControlTypeID=@controlTypeID,
		DataTypeID=@dataTypeID,
		Name=@name,
		Value=@value,
		Sequence=@sequence,
		ModifyBy=@user,
		ModifyDate=@modifiedOn
	WHERE ID=@programConfigurationId
 END
 
 END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveProgramInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveProgramInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveProgramInformation]( 
 @programID int,
 @parentProgramID int = NULL,
 @programName nvarchar(50) = NULL,
 @programDescription nvarchar(255) = NULL,
 @programCode nvarchar(20) = NULL,
 @isActive bit = NULL,
 @isAudited bit = NULL,
 @isGroup bit = NULL,
 @isServiceGuaranteed bit = NULL,
 @isWebRegistrationEnabled bit = NULL,
 @modifiedBy nvarchar(50)  = NULL
 )
 AS
 BEGIN
	UPDATE Program
	SET ParentProgramID = @parentProgramID,
		Name = @programName,
		[Description] = @programDescription,
		Code = @programCode,
		IsActive = @isActive,
		IsAudited = @isAudited,
		IsGroup = @isGroup,
		IsServiceGuaranteed = @isServiceGuaranteed,
		IsWebRegistrationEnabled = @isWebRegistrationEnabled,
		ModifyBy = @modifiedBy,
		ModifyDate = GETDATE()
	WHERE ID=@programID
	
 END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveProgramVehicleType]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveProgramVehicleType] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveProgramVehicleType]( 
 @programVehicleId INT,
 @vehicleTypeID INT=NULL,
 @maxAllowed INT=NULL,
 @isActive bit=NULL,
 @isAdd bit,
 @programID int=NULL
 )
 AS
 BEGIN
 
 IF @isAdd=1 
 BEGIN
 
	INSERT INTO ProgramVehicleType(ProgramID,VehicleTypeID,MaxAllowed,IsActive)
	VALUES(@programID,@vehicleTypeID,@maxAllowed,@isActive)
	
 END
 ELSE BEGIN
 
	UPDATE ProgramVehicleType
	SET VehicleTypeID=@vehicleTypeID,
		MaxAllowed=@maxAllowed,
		IsActive=@isActive
	WHERE ID=@programVehicleId
 END
 
 END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveServiceCategoryInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveServiceCategoryInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveServiceCategoryInformation]( 
 @id INT ,
 @programID INT = NULL,
 @productCategoryID INT = NULL,
 @vehicleTypeID INT = NULL,
 @vehicleCategoryID INT = NULL,
 @sequence INT = NULL,
 @isActive BIT = NULL
 )
  AS
 BEGIN
 IF @id > 0 
	 BEGIN
		UPDATE ProgramProductCategory 
		SET ProductCategoryID = @productCategoryID,
			VehicleCategoryID = @vehicleCategoryID,
			VehicleTypeID = @vehicleTypeID,
			Sequence = @sequence,
			IsActive = @isActive,
			ProgramID = @programID
		WHERE ID = @id
			
	 END
 ELSE
	 BEGIN
		INSERT INTO ProgramProductCategory(
			ProductCategoryID,
			ProgramID,
			VehicleCategoryID,
			VehicleTypeID,
			Sequence,
			IsActive
		)
		VALUES(
			@productCategoryID,
			@programID,
			@vehicleCategoryID,
			@vehicleTypeID,
			@sequence,
			@isActive
		)
	 END
 END
GO
