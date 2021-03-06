IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Call_Summary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Call_Summary]
GO

--EXEC dms_Call_Summary @serviceRequestID = 1429  
CREATE PROC dms_Call_Summary(@serviceRequestID INT = NULL)  
AS  
BEGIN 
	DECLARE @Hold TABLE(ColumnName NVARCHAR(MAX),ColumnValue NVARCHAR(MAX),DataType NVARCHAR(MAX),Sequence INT,GroupName NVARCHAR(MAX),DefaultRows INT NULL)    
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
 WHERE id = object_id(N'[dbo].[dms_CCImport_CreditCardChargedTransactions]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_CCImport_CreditCardChargedTransactions] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
 CREATE PROCEDURE [dbo].[dms_CCImport_CreditCardChargedTransactions] ( 
   @processGUID UNIQUEIDENTIFIER = NULL
 ) 
 
AS
BEGIN

	DECLARE @Results AS TABLE(TotalRecordCount INT,
							  TotalRecordsIgnored INT,
							  TotalCreditCardAdded INT,
							  TotalTransactionAdded INT,
							  TotalErrorRecords INT)
							  
	-- Helpers
	DECLARE @TotalRecordCount INT	= 0
	DECLARE @TotalRecordsIgnored INT = 0
	DECLARE @TotalCreditCardAdded INT = 0
	DECLARE @TotalTransactionAdded INT = 0
	DECLARE @TotalErrorRecords INT	= 0	 			  

	-- Step 1 : Insert Records INTO Temporary Credit Card
	DECLARE @startROWParent INT 
	DECLARE @totalRowsParent INT
	
	DECLARE @purchaseOrderNumber NVARCHAR(50) 
	DECLARE @creditCardNumber NVARCHAR(50)
	DECLARE @chargedDate DATE
	DECLARE @chargedAmount MONEY
	DECLARE @transactionDate DATE
	
	DECLARE @ParentRecordID INT = NULL
	DECLARE @ChildRecordID INT = NULL
	
	DECLARE @newRecordID INT
	
	SET @startROWParent =  (SELECT MIN(RecordID) FROM TemporaryCreditCard_Import_ChargedTransactions 
												 WHERE ProcessIdentifier = @processGUID)
	SET @totalRowsParent = (SELECT MAX(RecordID) FROM TemporaryCreditCard_Import_ChargedTransactions 
												 WHERE ProcessIdentifier = @processGUID)
	
	WHILE(@startROWParent <= @totalRowsParent)  
	BEGIN	
		
		SELECT @creditCardNumber    = FINVirtualCardNumber_C_CreditCardNumber,
			   @purchaseOrderNumber = FINCFFData02_C_OriginalReferencePurchaseOrderNumber,
			   @chargedDate			= FINPostingDate_ChargeDate,
			   @chargedAmount		= FINTransactionAmount_ChargeAmount,
			   @transactionDate		= FINTransactionDate_C_IssueDate_TransactionDate
		FROM TemporaryCreditCard_Import_ChargedTransactions
		WHERE RecordID = @startROWParent

		IF(@creditCardNumber IS NULL OR @creditCardNumber = '')
		BEGIN
			INSERT INTO [Log]([Date],[Thread],[Level],[Logger], [Message]) VALUES(GETDATE(),01,'INFO','[dms_CCImport_CreditCardChargedTransactions]','Business Rule Failed for more information Use Record ID ' + CONVERT(NVARCHAR(100),@startROWParent) + ' TemporaryCreditCard_Import_ChargedTransactions')
		END
		ELSE
		BEGIN
				SET @ParentRecordID =   (SELECT tcc.ID
								 FROM TemporaryCreditCard tcc
								 WHERE right(tcc.CreditCardNumber, 5) = right(@creditCardNumber,5)
								 AND ltrim(rtrim(isnull(tcc.OriginalReferencePurchaseOrderNumber,''))) = ltrim									 (rtrim(isnull(@purchaseOrderNumber,'')))
								 AND Cast(Convert(varchar, tcc.IssueDate,101) as datetime) <= @chargedDate)
			
				IF (@ParentRecordID IS NULL)
				  BEGIN
						UPDATE TemporaryCreditCard_Import_ChargedTransactions 
						SET ExceptionMessage = 'No matching TemporaryCreditCard for input charge transaction'
						WHERE RecordID = @startROWParent
				  END
				ELSE
				  BEGIN
					UPDATE TemporaryCreditCard_Import_ChargedTransactions 
					SET TemporaryCreditCardID = @ParentRecordID WHERE RecordID = @startROWParent
					
					SET    @ChildRecordID = (SELECT tccd.ID
						   FROM TemporaryCreditCard tcc
						   JOIN TemporaryCreditCardDetail tccd
						   ON tcc.ID = tccd.TemporaryCreditCardID
						   WHERE right(isnull(tcc.CreditCardNumber,''), 5) = 
						   right(isnull(@creditCardNumber,''), 5)
						   AND tccd.TransactionDate = @transactionDate
						   AND tccd.ChargeDate = @chargedDate
						   AND tccd.TransactionType = 'Charge'
						   AND ltrim(rtrim(isnull(tcc.OriginalReferencePurchaseOrderNumber,''))) 
						   = ltrim(rtrim(isnull(@purchaseOrderNumber,'')))
						   AND tccd.ChargeAmount = @chargedAmount)
					
					IF(@ChildRecordID IS NULL)
					BEGIN
						 INSERT INTO TemporaryCreditCardDetail(TemporaryCreditCardID,
															   TransactionSequence,
															   TransactionDate,
															   TransactionType,
															   TransactionBy,
															   RequestedAmount,
															   ApprovedAmount,
															   AvailableBalance,
															   ChargeDate,
															   ChargeAmount,
															   ChargeDescription,
															   CreateDate,
															   CreateBy,
															   ModifyDate,
															   ModifyBy)
						 SELECT @ParentRecordID,
								TransactionSequence,
								FINTransactionDate_C_IssueDate_TransactionDate,
								TransactionType,
								TransactionBy,
								RequestedAmount,
								ApprovedAmount,
								AvailableBalance,
								FINPostingDate_ChargeDate,
								FINTransactionAmount_ChargeAmount,
								FINTransactionDescription_ChargeDescription,
								CreateDate,
								CreatedBy,
								ModifyDate,
								ModifiedBy
						 FROM TemporaryCreditCard_Import_ChargedTransactions
						 WHERE RecordID = @startROWParent
						 
						 SET @newRecordID = SCOPE_IDENTITY()
						 
						 UPDATE TemporaryCreditCard_Import_ChargedTransactions
						 SET TemporaryCreditCardDetailsID = @newRecordID
						 WHERE RecordID = @startROWParent
					END

			 END
		END
	
		SET @startROWParent = @startROWParent + 1
	END
	
	-- Step 3 Update Counts
	SET @TotalRecordCount = (SELECT COUNT(*) FROM TemporaryCreditCard_Import_ChargedTransactions WHERE 
							 ProcessIdentifier = @processGUID)
	
							  
	SET @TotalTransactionAdded = (SELECT COUNT(*) FROM TemporaryCreditCard_Import_ChargedTransactions
							     WHERE TemporaryCreditCardDetailsID IS NOT NULL AND ProcessIdentifier = @processGUID)
			
	SET @TotalErrorRecords = (SELECT COUNT(*) FROM TemporaryCreditCard_Import_ChargedTransactions
							     WHERE TemporaryCreditCardID IS NULL AND ProcessIdentifier = @processGUID)				     
							   
	
	-- Step 4 Insert Counts
	INSERT INTO @Results(TotalRecordCount,
						 TotalRecordsIgnored,
						 TotalCreditCardAdded,
						 TotalTransactionAdded,
						 TotalErrorRecords)
	VALUES(@TotalRecordCount,@TotalRecordsIgnored,@TotalCreditCardAdded,@TotalTransactionAdded,
	@TotalErrorRecords)
	
	-- Step 5 Show Results
	SELECT * FROM @Results
END
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_CCImport_CreditCardIssueTransactions]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_CCImport_CreditCardIssueTransactions]
GO
CREATE PROC [dbo].dms_CCImport_CreditCardIssueTransactions(@processGUID UNIQUEIDENTIFIER = NULL)
AS
BEGIN

	DECLARE @Results AS TABLE(TotalRecordCount INT,
							  TotalRecordsIgnored INT,
							  TotalCreditCardAdded INT,
							  TotalTransactionAdded INT,
							  TotalErrorRecords INT)
							  
	-- Helpers
	DECLARE @TotalRecordCount INT	= 0
	DECLARE @TotalRecordsIgnored INT = 0
	DECLARE @TotalCreditCardAdded INT = 0
	DECLARE @TotalTransactionAdded INT = 0
	DECLARE @TotalErrorRecords INT	= 0	 			  

	-- Step 1 : Insert Records INTO Temporary Credit Card
	DECLARE @startROWParent INT 
	DECLARE @totalRowsParent INT
	DECLARE @creditCardIssueNumber NVARCHAR(50) 
	DECLARE @creditCardNumber NVARCHAR(50)
	DECLARE @purchaseType NVARCHAR(50)
	DECLARE @transactionSequence INT
	DECLARE @tempLookUpID INT
	DECLARE @newRecordID INT
	
	SET @startROWParent =  (SELECT MIN(RecordID) FROM TemporaryCreditCard_Import 
												 WHERE ProcessIdentifier = @processGUID)
	SET @totalRowsParent = (SELECT MAX(RecordID) FROM TemporaryCreditCard_Import 
												 WHERE ProcessIdentifier = @processGUID)
	
	WHILE(@startROWParent <= @totalRowsParent)  
	BEGIN
		SELECT  @creditCardIssueNumber = IMP.PurchaseID_CreditCardIssueNumber,
				@creditCardNumber = IMP.CPN_PAN_CreditCardNumber,
				@purchaseType = IMP.PURCHASE_TYPE
		FROM TemporaryCreditCard_Import IMP
		WHERE RecordID = @startROWParent
		
		IF(@creditCardNumber IS NULL OR @creditCardNumber = '' OR @purchaseType != 'ISP Claims')
			BEGIN
				INSERT INTO [Log]([Date],[Thread],[Level],[Logger], [Message]) VALUES(GETDATE(),01,'INFO','dms_CCImport_CreditCardIssueTransactions','Business Rule Failed for more information Use Record ID ' + CONVERT(NVARCHAR(100),@startROWParent) + ' TemporaryCreditCard_Import')
			END
		ELSE
			BEGIN
				IF(NOT EXISTS(SELECT * FROM TemporaryCreditCard TCC WHERE 
																TCC.CreditCardIssueNumber = @creditCardIssueNumber AND 
																TCC.CreditCardNumber = @creditCardNumber))
				 BEGIN
				INSERT INTO TemporaryCreditCard(CreditCardIssueNumber,			
								CreditCardNumber,			
								PurchaseOrderID,									
								VendorInvoiceID,				
								IssueDate,					
								IssueBy,
								IssueStatus,					
								ReferencePurchaseOrderNumber,				 
								OriginalReferencePurchaseOrderNumber,					 
								ReferenceVendorNumber,
								ApprovedAmount,					
								TotalChargedAmount,
								TemporaryCreditCardStatusID,									
								ExceptionMessage,				
								Note,						
								CreateDate,
								CreateBy,						
								ModifyDate,					
								ModifyBy) 
					SELECT PurchaseID_CreditCardIssueNumber,
						   CPN_PAN_CreditCardNumber,
						   PurchaseOrderID,
						   VendorInvoiceID,
						   CREATE_DATE_IssueDate_TransactionDate,
						   USER_NAME_IssueBy_TransactionBy,
						   IssueStatus,
						   CDF_PO_ReferencePurchaseOrderNumber,
						   CDF_PO_OriginalReferencePurchaseOrderNumber,
						   CDF_ISP_Vendor_ReferenceVendorNumber,
						   ApprovedAmount,
						   TotalChargeAmount,
						   TemporaryCreditCardStatusID,
						   ExceptionMessage,
						   Note,
						   CreateDate,
						   CreateBy,
						   ModifyDate,
						   ModifyBy
					FROM TemporaryCreditCard_Import S1 WHERE S1.RecordID = @startROWParent
				
				SET @newRecordID = SCOPE_IDENTITY()	
			
				UPDATE TemporaryCreditCard_Import SET TemporaryCreditCardID = @newRecordID
				WHERE RecordID = @startROWParent
			END
			END
		
		SET @startROWParent = @startROWParent + 1
	END
	
	-- Step 2 : Insert Records Into Temporary Credit Card Details
	SET @startROWParent =  (SELECT MIN(RecordID) FROM TemporaryCreditCard_Import 
												 WHERE ProcessIdentifier = @processGUID)
	
	SET @totalRowsParent = (SELECT MAX(RecordID) FROM TemporaryCreditCard_Import 
												 WHERE ProcessIdentifier = @processGUID)
												 
	WHILE(@startROWParent <= @totalRowsParent)  
	BEGIN
		SELECT  @creditCardIssueNumber = IMP.PurchaseID_CreditCardIssueNumber,
				@creditCardNumber = IMP.CPN_PAN_CreditCardNumber,
				@transactionSequence = IMP.HISTORY_ID_TransactionSequence,
				@purchaseType = IMP.PURCHASE_TYPE
		FROM TemporaryCreditCard_Import IMP
		WHERE RecordID = @startROWParent
		
		IF(@creditCardNumber IS NOT NULL AND @creditCardNumber != '' AND @purchaseType = 'ISP Claims')
		BEGIN
			IF(NOT EXISTS(SELECT tcc.ID, tccd.ID
					FROM TemporaryCreditCard tcc
					JOIN TemporaryCreditCardDetail tccd
						ON tcc.ID = tccd.TemporaryCreditCardID
					WHERE tcc.CreditCardIssueNumber = @creditCardIssueNumber
					AND tcc.CreditCardNumber = @creditCardNumber
					AND tccd.TransactionSequence = @transactionSequence
					))
					
		BEGIN
		SET @tempLookUpID = (SELECT tcc.ID FROM TemporaryCreditCard tcc
							   WHERE tcc.CreditCardIssueNumber = @creditCardIssueNumber
							   AND tcc.CreditCardNumber = @creditCardNumber)
							   
		INSERT INTO TemporaryCreditCardDetail(  TemporaryCreditCardID,
												TransactionSequence,
												TransactionDate,
												TransactionType,
												TransactionBy,
												RequestedAmount,
												ApprovedAmount,
												AvailableBalance,
												ChargeDate,
												ChargeAmount,
												ChargeDescription,
												CreateDate,
												CreateBy,
												ModifyDate,
												ModifyBy)
		SELECT @tempLookUpID, 
			   HISTORY_ID_TransactionSequence,
			   CREATE_DATE_IssueDate_TransactionDate,
			   ACTION_TYPE_TransactionType,
			   USER_NAME_IssueBy_TransactionBy,
			   REQUESTED_AMOUNT_RequestedAmount,
			   APPROVED_AMOUNT_ApprovedAmount,
			   AVAILABLE_BALANCE_AvailableBalance,
			   ChargeDate,
			   ChargeAmount,
			   ChargeDescription,
			   CreateDate,
			   CreateBy,
			   ModifyDate,
			   ModifyBy
		FROM TemporaryCreditCard_Import WHERE RecordID = @startROWParent
		
		SET @newRecordID = SCOPE_IDENTITY()
		UPDATE TemporaryCreditCard_Import SET TemporaryCreditCardDetailsID = @newRecordID
		WHERE RecordID = @startROWParent  
		
		END
		END
		
		SET @startROWParent = @startROWParent + 1
	END
	
	-- Step 3 Update Counts
	SET @TotalRecordCount = (SELECT COUNT(*) FROM TemporaryCreditCard_Import WHERE 
							 ProcessIdentifier = @processGUID)
	
	SET @TotalRecordsIgnored = (SELECT COUNT(*) FROM TemporaryCreditCard_Import
							   WHERE TemporaryCreditCardDetailsID IS NULL AND ProcessIdentifier = @processGUID
							   AND TemporaryCreditCardID IS NULL
							   ) 
							  
	
	SET @TotalCreditCardAdded = (SELECT COUNT(*) FROM TemporaryCreditCard_Import
							     WHERE TemporaryCreditCardID IS NOT NULL AND ProcessIdentifier = @processGUID)
							     
	SET @TotalTransactionAdded = (SELECT COUNT(*) FROM TemporaryCreditCard_Import
							     WHERE TemporaryCreditCardDetailsID IS NOT NULL AND ProcessIdentifier = @processGUID)
							   
	
	-- Step 4 Insert Counts
	INSERT INTO @Results(TotalRecordCount,
						 TotalRecordsIgnored,
						 TotalCreditCardAdded,
						 TotalTransactionAdded,
						 TotalErrorRecords)
	VALUES(@TotalRecordCount,@TotalRecordsIgnored,@TotalCreditCardAdded,@TotalTransactionAdded,
	@TotalErrorRecords)
	
	-- Step 5 Show Results
	SELECT * FROM @Results
END
	   




GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_CCImport_UpdateTempCreditCardDetails]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_CCImport_UpdateTempCreditCardDetails]
GO

--EXEC dms_CCImport_UpdateTempCreditCardDetails
CREATE PROC [dbo].[dms_CCImport_UpdateTempCreditCardDetails]
AS
BEGIN

BEGIN TRY
 

CREATE TABLE #TempCardsNotPosted (     
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
 ID int  NULL)

DECLARE @postedStatus INT
DECLARE @startROWParent INT 
DECLARE @totalRowsParent INT,
		@creditcardNumber INT,
		@totalApprovedAmount money,
		@totalChargedAmount money,
		@maxLastChargeDate datetime

SET @postedStatus = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name='Posted')

INSERT INTO #TempCardsNotPosted
SELECT DISTINCT TCCD.TemporaryCreditCardID FROM
TemporaryCreditCardDetail TCCD
JOIN TemporaryCreditCard TCC ON TCC.ID = TCCD.TemporaryCreditCardID
WHERE TCC.TemporaryCreditCardStatusID != @postedStatus

SET @startROWParent =  (SELECT MIN([RowNum]) FROM #TempCardsNotPosted)
SET @totalRowsParent = (SELECT MAX([RowNum]) FROM #TempCardsNotPosted)

WHILE(@startROWParent <= @totalRowsParent)  
BEGIN

SET @creditcardNumber = (SELECT ID FROM #TempCardsNotPosted WHERE [RowNum] = @startROWParent)
SET @maxLastChargeDate = (SELECT MAX(ChargeDate) FROM TemporaryCreditCardDetail WHERE TemporaryCreditCardID =  @creditcardNumber)

UPDATE TemporaryCreditCard
SET LastChargedDate = @maxLastChargeDate
WHERE ID =  @creditcardNumber

IF((SELECT Count(*) FROM TemporaryCreditCardDetail 
   WHERE TransactionType='Cancel' AND TemporaryCreditCardID = @creditcardNumber) > 0)
 BEGIN
	UPDATE TemporaryCreditCard 
	SET IssueStatus = 'Cancel'
	WHERE ID = @creditcardNumber
 END
 
 SET @totalApprovedAmount = (SELECT TOP 1 ApprovedAmount FROM TemporaryCreditCardDetail
							 WHERE TemporaryCreditCardID = @creditcardNumber AND TransactionType='Approve'
							 AND TransactionSequence IS NOT NULL
							 ORDER BY TransactionSequence DESC)
SET @totalChargedAmount = (SELECT SUM(ChargeAmount) FROM TemporaryCreditCardDetail
						   WHERE TemporaryCreditCardID = @creditcardNumber AND TransactionType='Charge')

UPDATE TemporaryCreditCard
SET ApprovedAmount = @totalApprovedAmount,
	TotalChargedAmount = @totalChargedAmount
WHERE ID = @creditcardNumber
						 
SET @startROWParent = @startROWParent + 1

END

DROP TABLE #TempCardsNotPosted



END TRY
BEGIN CATCH
		
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
	
END CATCH

END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Client_OpenPeriodProcess_EventLogs]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Client_OpenPeriodProcess_EventLogs] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 
CREATE PROC dms_Client_OpenPeriodProcess_EventLogs(@userName NVARCHAR(100),
												   @sessionID NVARCHAR(MAX),
												   @pageReference NVARCHAR(MAX),
												   @billingScheduleIDList NVARCHAR(MAX),
												   @billingDefinitionInvoiceIDList NVARCHAR(MAX))
AS
BEGIN
		
				DECLARE @BillingScheduleList AS TABLE(Serial INT IDENTITY(1,1), BillingScheduleID INT NULL)
				DECLARE @BillingDefinitionList AS TABLE(Serial INT IDENTITY(1,1),BillingDefinitionInvoiceID INT NULL)

				INSERT INTO @BillingScheduleList(BillingScheduleID)			   SELECT DISTINCT item from dbo.fnSplitString(@billingScheduleIDList,',')
				INSERT INTO @BillingDefinitionList(BillingDefinitionInvoiceID) SELECT item from dbo.fnSplitString(@billingDefinitionInvoiceIDList,',')
		
				DECLARE @eventLogID AS INT
				DECLARE @openBillingScheduleStatus AS INT
				DECLARE @scheduleID AS INT
				DECLARE @billingDefinitionID AS INT
				DECLARE @invoiceEntityID AS INT
				DECLARE @TotalRows AS INT
				DECLARE @ProcessingCounter AS INT = 1
				SELECT  @TotalRows = MAX(Serial) FROM @BillingScheduleList
				DECLARE @entityID AS INT 
				DECLARE @eventID AS INT
				SELECT  @entityID = ID FROM Entity WHERE Name = 'BillingSchedule'
				SELECT  @invoiceEntityID = ID FROM Entity WHERE Name = 'BillingInvoice'
				SELECT  @eventID =  ID FROM Event WHERE Name = 'OpenPeriod'
				SET @openBillingScheduleStatus = (SELECT ID From BillingScheduleStatus WHERE Name = 'OPEN')
		
				-- Create Event Logs for Billing Schedule ID List
				WHILE @ProcessingCounter <= @TotalRows
		BEGIN
			SET @scheduleID = (SELECT BillingScheduleID FROM @BillingScheduleList WHERE Serial = @ProcessingCounter)
			-- Create Event Logs Reocords
			INSERT INTO EventLog([EventID],				[SessionID],				[Source],			[Description],
								 [Data],				[NotificationQueueDate],	[CreateBy],			[CreateDate]) 
			VALUES				(@eventID,				@sessionID,					@pageReference,		 'Open Period - Billing Schedule ID = ' + CONVERT(NVARCHAR(50),@scheduleID),
								 NULL,					NULL,						@userName,			GETDATE())
			
			SET @eventLogID = SCOPE_IDENTITY()
			-- CREATE Link Records
			INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) VALUES(@eventLogID,@entityID,@scheduleID)
			

			-- CREATE LINK RECORDS FOR THE RECENTLY GENEREATED BillingInvoices.
			;WITH wGeneratedBillingInvoices
			AS
			(
				SELECT	ROW_NUMBER () OVER ( PARTITION BY BillingScheduleID, BillingDefinitionInvoiceID ORDER BY CreateDate DESC) AS RowNumber,
						ID AS BillingInvoiceID
				FROM	BillingInvoice BI WITH (NOLOCK)
				WHERE	BillingScheduleID = @scheduleID
			)

			INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) 
			SELECT	@eventLogID,@invoiceEntityID,W.BillingInvoiceID FROM wGeneratedBillingInvoices W WHERE W.RowNumber = 1


			UPDATE	BillingSchedule
			SET		ScheduleStatusID = @openBillingScheduleStatus
			WHERE	ID = @scheduleID


			SET @ProcessingCounter = @ProcessingCounter + 1
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
 WHERE id = object_id(N'[dbo].[dms_Temporary_CC_Batch_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Temporary_CC_Batch_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Temporary_CC_Batch_List]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = 'CreateDate' 
 , @sortOrder nvarchar(100) = 'DESC' 
  
 ) 
 AS 
 BEGIN 
      SET FMTONLY OFF;
     SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
      SET @whereClauseXML = '<ROW><Filter 

></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
BatchStatusID int NULL,
FromDate DATETIME NULL,
ToDate DATETIME NULL
)
CREATE TABLE #FinalResults( 
      [RowNum] [bigint] NOT NULL IDENTITY(1,1),
      ID int  NULL ,
      BatchType nvarchar(100)  NULL ,
      BatchStatusID int  NULL ,
      BatchStatus nvarchar(100)  NULL ,
      TotalCount int  NULL ,
      TotalAmount money  NULL ,    
      CreateDate datetime  NULL ,
      CreateBy nvarchar(100)  NULL ,
      ModifyDate datetime  NULL ,
      ModifyBy nvarchar(100)  NULL,
      CreditCardIssueNumber nvarchar(100) NULL
) 

CREATE TABLE #tmpFinalResults( 
      [RowNum] [bigint] NOT NULL IDENTITY(1,1),
      ID int  NULL ,
      BatchType nvarchar(100)  NULL ,
      BatchStatusID int  NULL ,
      BatchStatus nvarchar(100)  NULL ,
      TotalCount int  NULL ,
      TotalAmount money  NULL ,     
      CreateDate datetime  NULL ,
      CreateBy nvarchar(100)  NULL ,
      ModifyDate datetime  NULL ,
      ModifyBy nvarchar(100)  NULL,
      CreditCardIssueNumber nvarchar(100) NULL
) 

INSERT INTO #tmpForWhereClause
SELECT 
      T.c.value('@BatchStatusID','int') ,
      T.c.value('@FromDate','datetime') ,
      T.c.value('@ToDate','datetime') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @batchStatusID NVARCHAR(100) = NULL,
            @fromDate DATETIME = NULL,
            @toDate DATETIME = NULL
            
SELECT      @batchStatusID = BatchStatusID, 
            @fromDate = FromDate,
            @toDate = ToDate
FROM  #tmpForWhereClause
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------


INSERT INTO #tmpFinalResults
SELECT      B.ID
            , BT.[Description] AS BatchType
            , B.BatchStatusID
            , BS.Name AS BatchStatus
            , B.TotalCount AS TotalCount
            , B.TotalAmount AS TotalAmount
            , B.CreateDate
            , B.CreateBy
            , B.ModifyDate
            , B.ModifyBy 
            , TCC.CreditCardIssueNumber
FROM  Batch B
JOIN  BatchType BT ON BT.ID = B.BatchTypeID
JOIN  BatchStatus BS ON BS.ID = B.BatchStatusID
LEFT JOIN TemporaryCreditCard TCC ON TCC.PostingBatchID = B.ID
WHERE B.BatchTypeID = (SELECT ID FROM BatchType WHERE Name = 'TemporaryCCPost')
AND         (@batchStatusID IS NULL OR @batchStatusID = B.BatchStatusID)
AND         (@fromDate IS NULL OR B.CreateDate > @fromDate)
AND         (@toDate IS NULL OR B.CreateDate < @toDate)
GROUP BY    B.ID
            , BT.[Description] 
            , B.BatchStatusID
            , BS.Name  
            , B.TotalCount
            , B.TotalAmount         
            , B.CreateDate
            , B.CreateBy
            , B.ModifyDate
            , B.ModifyBy
            , TCC.CreditCardIssueNumber
ORDER BY B.CreateDate DESC



INSERT INTO #FinalResults
SELECT 
      T.ID,
      T.BatchType,
      T.BatchStatusID,
      T.BatchStatus,
      T.TotalCount,
      T.TotalAmount,    
      T.CreateDate,
      T.CreateBy,
      T.ModifyDate,
      T.ModifyBy,
      T.CreditCardIssueNumber
      
FROM #tmpFinalResults T

ORDER BY 
       CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
      THEN T.ID END ASC, 
       CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
      THEN T.ID END DESC ,

      CASE WHEN @sortColumn = 'BatchType' AND @sortOrder = 'ASC'
      THEN T.BatchType END ASC, 
       CASE WHEN @sortColumn = 'BatchType' AND @sortOrder = 'DESC'
      THEN T.BatchType END DESC ,

      CASE WHEN @sortColumn = 'BatchStatusID' AND @sortOrder = 'ASC'
      THEN T.BatchStatusID END ASC, 
       CASE WHEN @sortColumn = 'BatchStatusID' AND @sortOrder = 'DESC'
      THEN T.BatchStatusID END DESC ,

      CASE WHEN @sortColumn = 'BatchStatus' AND @sortOrder = 'ASC'
      THEN T.BatchStatus END ASC, 
       CASE WHEN @sortColumn = 'BatchStatus' AND @sortOrder = 'DESC'
      THEN T.BatchStatus END DESC ,

      CASE WHEN @sortColumn = 'TotalCount' AND @sortOrder = 'ASC'
      THEN T.TotalCount END ASC, 
       CASE WHEN @sortColumn = 'TotalCount' AND @sortOrder = 'DESC'
      THEN T.TotalCount END DESC ,

      CASE WHEN @sortColumn = 'TotalAmount' AND @sortOrder = 'ASC'
      THEN T.TotalAmount END ASC, 
       CASE WHEN @sortColumn = 'TotalAmount' AND @sortOrder = 'DESC'
      THEN T.TotalAmount END DESC ,     

      CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'
      THEN T.CreateDate END ASC, 
       CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'
      THEN T.CreateDate END DESC ,

      CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
      THEN T.CreateBy END ASC, 
       CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
      THEN T.CreateBy END DESC ,

      CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'ASC'
      THEN T.ModifyDate END ASC, 
       CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'DESC'
      THEN T.ModifyDate END DESC ,

      CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'ASC'
      THEN T.ModifyBy END ASC, 
       CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'DESC'
      THEN T.ModifyBy END DESC ,

      CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'ASC'
      THEN T.CreditCardIssueNumber END ASC, 
       CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'DESC'
      THEN T.CreditCardIssueNumber END DESC 


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
 WHERE id = object_id(N'[dbo].[dms_Temporary_CC_Batch_Payment_Runs_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Temporary_CC_Batch_Payment_Runs_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC [dms_Temporary_CC_Batch_Payment_Runs_List_Get] @BatchID = 169 , @GLAccountName='6300-310-00'
 CREATE PROCEDURE [dbo].[dms_Temporary_CC_Batch_Payment_Runs_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @BatchID INT = NULL  
 , @GLAccountName nvarchar(11) = NULL
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
TemporaryCCIDOperator="-1" 
TemporaryCCNumberOperator="-1" 
CCIssueDateOperator="-1" 
CCIssueByOperator="-1" 
CCApproveOperator="-1" 
CCChargeOperator="-1" 
POIDOperator="-1" 
PONumberOperator="-1" 
POAmountOperator="-1" 
InvoiceIDOperator="-1" 
InvoiceNumberOperator="-1" 
InvoiceAmountOperator="-1" 
CreditCardIssueNumberOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
TemporaryCCIDOperator INT NOT NULL,
TemporaryCCIDValue int NULL,
TemporaryCCNumberOperator INT NOT NULL,
TemporaryCCNumberValue nvarchar(100) NULL,
CCIssueDateOperator INT NOT NULL,
CCIssueDateValue datetime NULL,
CCIssueByOperator INT NOT NULL,
CCIssueByValue nvarchar(100) NULL,
CCApproveOperator INT NOT NULL,
CCApproveValue money NULL,
CCChargeOperator INT NOT NULL,
CCChargeValue money NULL,
POIDOperator INT NOT NULL,
POIDValue int NULL,
PONumberOperator INT NOT NULL,
PONumberValue nvarchar(100) NULL,
POAmountOperator INT NOT NULL,
POAmountValue money NULL,
InvoiceIDOperator INT NOT NULL,
InvoiceIDValue int NULL,
InvoiceNumberOperator INT NOT NULL,
InvoiceNumberValue nvarchar(100) NULL,
InvoiceAmountOperator INT NOT NULL,
InvoiceAmountValue money NULL,
CreditCardIssueNumberOperator INT NOT NULL,
CreditCardIssueNumberValue nvarchar(100) NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	TemporaryCCID int  NULL ,
	TemporaryCCNumber nvarchar(100)  NULL ,
	CCIssueDate datetime  NULL ,
	CCIssueBy nvarchar(100)  NULL ,
	CCApprove money  NULL ,
	CCCharge money  NULL ,
	POID int  NULL ,
	PONumber nvarchar(100)  NULL ,
	POAmount money  NULL ,
	InvoiceID int  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceAmount money  NULL,
	CreditCardIssueNumber nvarchar(100)  NULL 
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	TemporaryCCID int  NULL ,
	TemporaryCCNumber nvarchar(100)  NULL ,
	CCIssueDate datetime  NULL ,
	CCIssueBy nvarchar(100)  NULL ,
	CCApprove money  NULL ,
	CCCharge money  NULL ,
	POID int  NULL ,
	PONumber nvarchar(100)  NULL ,
	POAmount money  NULL ,
	InvoiceID int  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceAmount money  NULL ,
	CreditCardIssueNumber nvarchar(100)  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@TemporaryCCIDOperator','INT'),-1),
	T.c.value('@TemporaryCCIDValue','int') ,
	ISNULL(T.c.value('@TemporaryCCNumberOperator','INT'),-1),
	T.c.value('@TemporaryCCNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CCIssueDateOperator','INT'),-1),
	T.c.value('@CCIssueDateValue','datetime') ,
	ISNULL(T.c.value('@CCIssueByOperator','INT'),-1),
	T.c.value('@CCIssueByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CCApproveOperator','INT'),-1),
	T.c.value('@CCApproveValue','money') ,
	ISNULL(T.c.value('@CCChargeOperator','INT'),-1),
	T.c.value('@CCChargeValue','money') ,
	ISNULL(T.c.value('@POIDOperator','INT'),-1),
	T.c.value('@POIDValue','int') ,
	ISNULL(T.c.value('@PONumberOperator','INT'),-1),
	T.c.value('@PONumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@POAmountOperator','INT'),-1),
	T.c.value('@POAmountValue','money') ,
	ISNULL(T.c.value('@InvoiceIDOperator','INT'),-1),
	T.c.value('@InvoiceIDValue','int') ,
	ISNULL(T.c.value('@InvoiceNumberOperator','INT'),-1),
	T.c.value('@InvoiceNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@InvoiceAmountOperator','INT'),-1),
	T.c.value('@InvoiceAmountValue','money') ,
	ISNULL(T.c.value('@CreditCardIssueNumberOperator','INT'),-1),
	T.c.value('@CreditCardIssueNumberValue','nvarchar(100)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT 
  TCC.ID AS TemporaryCCID
, TCC.CreditCardNumber AS TemporaryCCNumber
, TCC.IssueDate AS CCIssueDate
, TCC.IssueBy AS CCIssueBy
, TCC.ApprovedAmount AS CCApprove
, TCC.TotalChargedAmount AS CCCharge
, PO.ID AS POID
, PO.PurchaseOrderNumber AS PONumber
, PO.PurchaseOrderAmount AS POAmount 
, VI.ID AS InvoiceID
, VI.InvoiceNumber AS InvoiceNumber
, VI.InvoiceAmount AS InvoiceAmount
, TCC.CreditCardIssueNumber AS CreditCardIssueNumber
FROM	TemporaryCreditCard TCC
LEFT JOIN	PurchaseOrder PO ON PO.PurchaseOrderNumber = TCC.ReferencePurchaseOrderNumber
LEFT JOIN   VendorInvoice VI ON VI.PurchaseOrderID = PO.ID
WHERE TCC.PostingBatchID = @BatchID AND VI.GLExpenseAccount = @GLAccountName

INSERT INTO #FinalResults
SELECT 
	T.TemporaryCCID,
	T.TemporaryCCNumber,
	T.CCIssueDate,
	T.CCIssueBy,
	T.CCApprove,
	T.CCCharge,
	T.POID,
	T.PONumber,
	T.POAmount,
	T.InvoiceID,
	T.InvoiceNumber,
	T.InvoiceAmount,
	T.CreditCardIssueNumber
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.TemporaryCCIDOperator = -1 ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 0 AND T.TemporaryCCID IS NULL ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 1 AND T.TemporaryCCID IS NOT NULL ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 2 AND T.TemporaryCCID = TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 3 AND T.TemporaryCCID <> TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 7 AND T.TemporaryCCID > TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 8 AND T.TemporaryCCID >= TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 9 AND T.TemporaryCCID < TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 10 AND T.TemporaryCCID <= TMP.TemporaryCCIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.TemporaryCCNumberOperator = -1 ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 0 AND T.TemporaryCCNumber IS NULL ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 1 AND T.TemporaryCCNumber IS NOT NULL ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 2 AND T.TemporaryCCNumber = TMP.TemporaryCCNumberValue ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 3 AND T.TemporaryCCNumber <> TMP.TemporaryCCNumberValue ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 4 AND T.TemporaryCCNumber LIKE TMP.TemporaryCCNumberValue + '%') 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 5 AND T.TemporaryCCNumber LIKE '%' + TMP.TemporaryCCNumberValue ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 6 AND T.TemporaryCCNumber LIKE '%' + TMP.TemporaryCCNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CCIssueDateOperator = -1 ) 
 OR 
	 ( TMP.CCIssueDateOperator = 0 AND T.CCIssueDate IS NULL ) 
 OR 
	 ( TMP.CCIssueDateOperator = 1 AND T.CCIssueDate IS NOT NULL ) 
 OR 
	 ( TMP.CCIssueDateOperator = 2 AND T.CCIssueDate = TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 3 AND T.CCIssueDate <> TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 7 AND T.CCIssueDate > TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 8 AND T.CCIssueDate >= TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 9 AND T.CCIssueDate < TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 10 AND T.CCIssueDate <= TMP.CCIssueDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CCIssueByOperator = -1 ) 
 OR 
	 ( TMP.CCIssueByOperator = 0 AND T.CCIssueBy IS NULL ) 
 OR 
	 ( TMP.CCIssueByOperator = 1 AND T.CCIssueBy IS NOT NULL ) 
 OR 
	 ( TMP.CCIssueByOperator = 2 AND T.CCIssueBy = TMP.CCIssueByValue ) 
 OR 
	 ( TMP.CCIssueByOperator = 3 AND T.CCIssueBy <> TMP.CCIssueByValue ) 
 OR 
	 ( TMP.CCIssueByOperator = 4 AND T.CCIssueBy LIKE TMP.CCIssueByValue + '%') 
 OR 
	 ( TMP.CCIssueByOperator = 5 AND T.CCIssueBy LIKE '%' + TMP.CCIssueByValue ) 
 OR 
	 ( TMP.CCIssueByOperator = 6 AND T.CCIssueBy LIKE '%' + TMP.CCIssueByValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CCApproveOperator = -1 ) 
 OR 
	 ( TMP.CCApproveOperator = 0 AND T.CCApprove IS NULL ) 
 OR 
	 ( TMP.CCApproveOperator = 1 AND T.CCApprove IS NOT NULL ) 
 OR 
	 ( TMP.CCApproveOperator = 2 AND T.CCApprove = TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 3 AND T.CCApprove <> TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 7 AND T.CCApprove > TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 8 AND T.CCApprove >= TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 9 AND T.CCApprove < TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 10 AND T.CCApprove <= TMP.CCApproveValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CCChargeOperator = -1 ) 
 OR 
	 ( TMP.CCChargeOperator = 0 AND T.CCCharge IS NULL ) 
 OR 
	 ( TMP.CCChargeOperator = 1 AND T.CCCharge IS NOT NULL ) 
 OR 
	 ( TMP.CCChargeOperator = 2 AND T.CCCharge = TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 3 AND T.CCCharge <> TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 7 AND T.CCCharge > TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 8 AND T.CCCharge >= TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 9 AND T.CCCharge < TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 10 AND T.CCCharge <= TMP.CCChargeValue ) 

 ) 

 AND 

 ( 
	 ( TMP.POIDOperator = -1 ) 
 OR 
	 ( TMP.POIDOperator = 0 AND T.POID IS NULL ) 
 OR 
	 ( TMP.POIDOperator = 1 AND T.POID IS NOT NULL ) 
 OR 
	 ( TMP.POIDOperator = 2 AND T.POID = TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 3 AND T.POID <> TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 7 AND T.POID > TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 8 AND T.POID >= TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 9 AND T.POID < TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 10 AND T.POID <= TMP.POIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.PONumberOperator = -1 ) 
 OR 
	 ( TMP.PONumberOperator = 0 AND T.PONumber IS NULL ) 
 OR 
	 ( TMP.PONumberOperator = 1 AND T.PONumber IS NOT NULL ) 
 OR 
	 ( TMP.PONumberOperator = 2 AND T.PONumber = TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 3 AND T.PONumber <> TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 4 AND T.PONumber LIKE TMP.PONumberValue + '%') 
 OR 
	 ( TMP.PONumberOperator = 5 AND T.PONumber LIKE '%' + TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 6 AND T.PONumber LIKE '%' + TMP.PONumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.POAmountOperator = -1 ) 
 OR 
	 ( TMP.POAmountOperator = 0 AND T.POAmount IS NULL ) 
 OR 
	 ( TMP.POAmountOperator = 1 AND T.POAmount IS NOT NULL ) 
 OR 
	 ( TMP.POAmountOperator = 2 AND T.POAmount = TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 3 AND T.POAmount <> TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 7 AND T.POAmount > TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 8 AND T.POAmount >= TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 9 AND T.POAmount < TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 10 AND T.POAmount <= TMP.POAmountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.InvoiceIDOperator = -1 ) 
 OR 
	 ( TMP.InvoiceIDOperator = 0 AND T.InvoiceID IS NULL ) 
 OR 
	 ( TMP.InvoiceIDOperator = 1 AND T.InvoiceID IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceIDOperator = 2 AND T.InvoiceID = TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 3 AND T.InvoiceID <> TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 7 AND T.InvoiceID > TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 8 AND T.InvoiceID >= TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 9 AND T.InvoiceID < TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 10 AND T.InvoiceID <= TMP.InvoiceIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.InvoiceNumberOperator = -1 ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 0 AND T.InvoiceNumber IS NULL ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 1 AND T.InvoiceNumber IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 2 AND T.InvoiceNumber = TMP.InvoiceNumberValue ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 3 AND T.InvoiceNumber <> TMP.InvoiceNumberValue ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 4 AND T.InvoiceNumber LIKE TMP.InvoiceNumberValue + '%') 
 OR 
	 ( TMP.InvoiceNumberOperator = 5 AND T.InvoiceNumber LIKE '%' + TMP.InvoiceNumberValue ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 6 AND T.InvoiceNumber LIKE '%' + TMP.InvoiceNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.InvoiceAmountOperator = -1 ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 0 AND T.InvoiceAmount IS NULL ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 1 AND T.InvoiceAmount IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 2 AND T.InvoiceAmount = TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 3 AND T.InvoiceAmount <> TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 7 AND T.InvoiceAmount > TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 8 AND T.InvoiceAmount >= TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 9 AND T.InvoiceAmount < TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 10 AND T.InvoiceAmount <= TMP.InvoiceAmountValue ) 

 ) 



 AND 
 
 ( 
	 ( TMP.CreditCardIssueNumberOperator = -1 ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 0 AND T.CreditCardIssueNumber IS NULL ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 1 AND T.CreditCardIssueNumber IS NOT NULL ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 2 AND T.CreditCardIssueNumber = TMP.CreditCardIssueNumberValue ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 3 AND T.CreditCardIssueNumber <> TMP.CreditCardIssueNumberValue ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 4 AND T.CreditCardIssueNumber LIKE TMP.CreditCardIssueNumberValue + '%') 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 5 AND T.CreditCardIssueNumber LIKE '%' + TMP.CreditCardIssueNumberValue ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 6 AND T.CreditCardIssueNumber LIKE '%' + TMP.CreditCardIssueNumberValue + '%' ) 
 ) 

 AND 
 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'TemporaryCCID' AND @sortOrder = 'ASC'
	 THEN T.TemporaryCCID END ASC, 
	 CASE WHEN @sortColumn = 'TemporaryCCID' AND @sortOrder = 'DESC'
	 THEN T.TemporaryCCID END DESC ,

	 CASE WHEN @sortColumn = 'TemporaryCCNumber' AND @sortOrder = 'ASC'
	 THEN T.TemporaryCCNumber END ASC, 
	 CASE WHEN @sortColumn = 'TemporaryCCNumber' AND @sortOrder = 'DESC'
	 THEN T.TemporaryCCNumber END DESC ,

	 CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'ASC'
	 THEN T.CCIssueDate END ASC, 
	 CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'DESC'
	 THEN T.CCIssueDate END DESC ,

	 CASE WHEN @sortColumn = 'CCIssueBy' AND @sortOrder = 'ASC'
	 THEN T.CCIssueBy END ASC, 
	 CASE WHEN @sortColumn = 'CCIssueBy' AND @sortOrder = 'DESC'
	 THEN T.CCIssueBy END DESC ,

	 CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'ASC'
	 THEN T.CCApprove END ASC, 
	 CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'DESC'
	 THEN T.CCApprove END DESC ,

	 CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'ASC'
	 THEN T.CCCharge END ASC, 
	 CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'DESC'
	 THEN T.CCCharge END DESC ,

	 CASE WHEN @sortColumn = 'POID' AND @sortOrder = 'ASC'
	 THEN T.POID END ASC, 
	 CASE WHEN @sortColumn = 'POID' AND @sortOrder = 'DESC'
	 THEN T.POID END DESC ,

	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'
	 THEN T.PONumber END ASC, 
	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'
	 THEN T.PONumber END DESC ,

	 CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'ASC'
	 THEN T.POAmount END ASC, 
	 CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'DESC'
	 THEN T.POAmount END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceID' AND @sortOrder = 'ASC'
	 THEN T.InvoiceID END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceID' AND @sortOrder = 'DESC'
	 THEN T.InvoiceID END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN T.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN T.InvoiceNumber END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'
	 THEN T.InvoiceAmount END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'
	 THEN T.InvoiceAmount END DESC ,
	 
	 CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'ASC'
	 THEN T.CreditCardIssueNumber END ASC, 
	 CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'DESC'
	 THEN T.CreditCardIssueNumber END DESC 


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
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Temporary_CC_Split]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Temporary_CC_Split]
GO

CREATE PROCEDURE [dbo].[dms_Temporary_CC_Split] 
	@SourceTemporaryCreditCardID int,
	@SplitTo_PurchaseOrderNumber nvarchar(50)
AS
BEGIN
	
	DECLARE	@NewTemporaryCreditCardID int,
		@NewTemporaryCreditCard_TotalChargedAmount money
		
	SELECT @NewTemporaryCreditCard_TotalChargedAmount = PurchaseOrderAmount
	FROM PurchaseOrder
	WHERE PurchaseOrderNumber = @SplitTo_PurchaseOrderNumber

	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO [DMS].[dbo].[TemporaryCreditCard]
				   ([CreditCardIssueNumber]
				   ,[CreditCardNumber]
				   ,[PurchaseOrderID]
				   ,[VendorInvoiceID]
				   ,[IssueDate]
				   ,[IssueBy]
				   ,[IssueStatus]
				   ,[ReferencePurchaseOrderNumber]
				   ,[OriginalReferencePurchaseOrderNumber]
				   ,[ReferenceVendorNumber]
				   ,[ApprovedAmount]
				   ,[TotalChargedAmount]
				   ,[TemporaryCreditCardStatusID]
				   ,[ExceptionMessage]
				   ,[Note]
				   ,[PostingBatchID]
				   ,[AccountingPeriodID]
				   ,[CreateDate]
				   ,[CreateBy]
				   ,[ModifyDate]
				   ,[ModifyBy])
		SELECT [CreditCardIssueNumber]
			  ,[CreditCardNumber]
			  ,[PurchaseOrderID]
			  ,[VendorInvoiceID]
			  ,[IssueDate]
			  ,[IssueBy]
			  ,[IssueStatus]
			  ,@SplitTo_PurchaseOrderNumber
			  ,[OriginalReferencePurchaseOrderNumber]
			  ,[ReferenceVendorNumber]
			  ,[ApprovedAmount]
			  ,@NewTemporaryCreditCard_TotalChargedAmount
			  ,[TemporaryCreditCardStatusID]
			  ,[ExceptionMessage]
			  ,[Note]
			  ,[PostingBatchID]
			  ,[AccountingPeriodID]
			  ,[CreateDate]
			  ,[CreateBy]
			  ,[ModifyDate]
			  ,[ModifyBy]
		FROM [DMS].[dbo].[TemporaryCreditCard]
		WHERE ID = @SourceTemporaryCreditCardID

		SET @NewTemporaryCreditCardID = SCOPE_IDENTITY()

		INSERT INTO [DMS].[dbo].[TemporaryCreditCardDetail]
				   ([TemporaryCreditCardID]
				   ,[TransactionSequence]
				   ,[TransactionDate]
				   ,[TransactionType]
				   ,[TransactionBy]
				   ,[RequestedAmount]
				   ,[ApprovedAmount]
				   ,[AvailableBalance]
				   ,[ChargeDate]
				   ,[ChargeAmount]
				   ,[ChargeDescription]
				   ,[CreateDate]
				   ,[CreateBy]
				   ,[ModifyDate]
				   ,[ModifyBy])
		SELECT @NewTemporaryCreditCardID
			  ,[TransactionSequence]
			  ,[TransactionDate]
			  ,[TransactionType]
			  ,[TransactionBy]
			  ,[RequestedAmount]
			  ,[ApprovedAmount]
			  ,[AvailableBalance]
			  ,[ChargeDate]
			  ,[ChargeAmount]
			  ,[ChargeDescription]
			  ,[CreateDate]
			  ,[CreateBy]
			  ,[ModifyDate]
			  ,[ModifyBy]
		FROM [DMS].[dbo].[TemporaryCreditCardDetail]
		WHERE TemporaryCreditCardID = @SourceTemporaryCreditCardID

		UPDATE TemporaryCreditCard SET TotalChargedAmount = (TotalChargedAmount - @NewTemporaryCreditCard_TotalChargedAmount)
		WHERE ID = @SourceTemporaryCreditCardID
		
		COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
	END CATCH
	
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
 WHERE id = object_id(N'[dbo].[dms_Vendor_CCProcessing_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_CCProcessing_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_Vendor_CCProcessing_List_Get] @whereClauseXML = '<ROW><Filter IDType="Vendor" IDValue="TX100532" NameValue="" NameOperator="" InvoiceStatuses="" POStatuses="" FromDate="" ToDate="" ExportType="" ToBePaidFromDate="" ToBePaidToDate=""/></ROW>'  
CREATE PROCEDURE [dbo].[dms_Vendor_CCProcessing_List_Get](     
   @whereClauseXML XML = NULL     
 , @startInd Int = 1     
 , @endInd BIGINT = 5000     
 , @pageSize int = 10000      
 , @sortColumn nvarchar(100)  = ''     
 , @sortOrder nvarchar(100) = 'ASC'     
      
 )     
 AS     
 BEGIN     
 
 SET FMTONLY OFF    
  SET NOCOUNT ON    
    
IF @whereClauseXML IS NULL     
BEGIN    
 SET @whereClauseXML = '<ROW><Filter     
NameOperator="-1"    
 ></Filter></ROW>'    
END    
    
    
CREATE TABLE #tmpForWhereClause    
(    
 IDType NVARCHAR(50) NULL,    
 IDValue NVARCHAR(100) NULL,    
 CCMatchStatuses NVARCHAR(MAX) NULL,    
 POPayStatuses NVARCHAR(MAX) NULL,    
 CCFromDate DATETIME NULL,    
 CCToDate DATETIME NULL,    
 POFromDate DATETIME NULL,    
 POToDate DATETIME NULL,
 PostingBatchID INT NULL
     
)    
    
 CREATE TABLE #FinalResults_Filtered(      
 ID int  NULL ,    
 CCRefPO nvarchar(50)  NULL ,    
 TempCC nvarchar(50) NULL,    
 CCIssueDate datetime  NULL ,    
 CCApprove money  NULL ,    
 CCCharge money  NULL ,    
 CCIssueStatus nvarchar(50)  NULL ,    
 CCMatchStatus nvarchar(50)  NULL ,    
 CCOrigPO nvarchar(50)  NULL ,    
 PONumber nvarchar(50)  NULL ,    
 PODate datetime  NULL ,    
 POPayStatus nvarchar(50)  NULL ,    
 POCC nvarchar(50)  NULL ,    
 POAmount money  NULL ,    
 InvoiceAmount money  NULL ,    
 Note nvarchar(1000)  NULL ,    
 ExceptionMessage nvarchar(200)  NULL ,    
 POId int  NULL  ,
 CreditCardIssueNumber nvarchar(50) NULL,
 PurchaseOrderStatus nvarchar(50)  NULL,
 ReferenceVendorNumber nvarchar(50) NULL,
 VendorNumber nvarchar(50) NULL,
 LastChargedDate DATETIME NULL
)     
    
 CREATE TABLE #FinalResults_Sorted (     
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
 ID int  NULL ,    
 CCRefPO nvarchar(50)  NULL ,    
 TempCC nvarchar(50) NULL,    
 CCIssueDate datetime  NULL ,    
 CCApprove money  NULL ,    
 CCCharge money  NULL ,    
 CCIssueStatus nvarchar(50)  NULL ,    
 CCMatchStatus nvarchar(50)  NULL ,    
 CCOrigPO nvarchar(50)  NULL ,    
 PONumber nvarchar(50)  NULL ,    
 PODate datetime  NULL ,    
 POPayStatus nvarchar(50)  NULL ,    
 POCC nvarchar(50)  NULL ,    
 POAmount money  NULL ,    
 InvoiceAmount money  NULL ,    
 Note nvarchar(1000)  NULL ,    
 ExceptionMessage nvarchar(200)  NULL ,    
 POId int  NULL   ,
 CreditCardIssueNumber nvarchar(50) NULL,
 PurchaseOrderStatus nvarchar(50)  NULL,
 ReferenceVendorNumber nvarchar(50) NULL,
 VendorNumber nvarchar(50) NULL,
 LastChargedDate DATETIME NULL
)     

DECLARE @matchedCount BIGINT      
DECLARE @exceptionCount BIGINT      
DECLARE @postedCount BIGINT    
DECLARE @cancelledCount BIGINT 
DECLARE @unmatchedCount BIGINT 
 
SET @matchedCount = 0      
SET @exceptionCount = 0      
SET @postedCount = 0
SET @cancelledCount = 0
SET @unmatchedCount = 0    
  
  
INSERT INTO #tmpForWhereClause    
SELECT      
 T.c.value('@IDType','NVARCHAR(50)') ,    
 T.c.value('@IDValue','NVARCHAR(100)'),     
 T.c.value('@CCMatchStatuses','nvarchar(MAX)') ,    
 T.c.value('@POPayStatuses','nvarchar(MAX)') , 
 T.c.value('@CCFromDate','datetime') ,    
 T.c.value('@CCToDate','datetime') ,    
 T.c.value('@POFromDate','datetime') ,
T.c.value('@POToDate','datetime') ,    
 T.c.value('@PostingBatchID','INT')     

FROM @whereClauseXML.nodes('/ROW/Filter') T(c)    
    
    
DECLARE @idType NVARCHAR(50) = NULL,    
  @idValue NVARCHAR(100) = NULL,    
  @CCMatchStatuses NVARCHAR(MAX) = NULL,    
  @POPayStatuses NVARCHAR(MAX) = NULL,    
  @CCFromDate DATETIME = NULL,    
  @CCToDate DATETIME = NULL, 
  @POFromDate DATETIME = NULL,    
  @POToDate DATETIME = NULL,
  @PostingBatchID INT = NULL   
      
SELECT @idType = IDType,    
  @idValue = IDValue,    
  @CCMatchStatuses = CCMatchStatuses,    
  @POPayStatuses = POPayStatuses,    
  @CCFromDate = CCFromDate,    
  @CCToDate = CASE WHEN CCToDate = '1900-01-01' THEN NULL ELSE CCToDate END,  
  @POFromDate = POFromDate,
  @POToDate = CASE WHEN POToDate = '1900-01-01' THEN NULL ELSE POToDate END,  
  @PostingBatchID = PostingBatchID 
FROM #tmpForWhereClause    

INSERT INTO #FinalResults_Filtered 
SELECT	TCC.ID,
		TCC.ReferencePurchaseOrderNumber
		, TCC.CreditCardNumber
		, TCC.IssueDate
		, TCC.ApprovedAmount
		, TCC.TotalChargedAmount
		, TCC.IssueStatus
		, TCCS.Name AS CCMatchStatus
		, TCC.OriginalReferencePurchaseOrderNumber
		, PO.PurchaseOrderNumber
		, PO.IssueDate
		, PSC.Name
		, PO.CompanyCreditCardNumber
		, PO.PurchaseOrderAmount
		, CASE
			WHEN TCCS.Name = 'Posted'  THEN ''--TCC.InvoiceAmount
			WHEN TCCS.Name = 'Matched' THEN TCC.TotalChargedAmount
			ELSE ''
		  END AS InvoiceAmount
		, TCC.Note
		,TCC.ExceptionMessage
		,PO.ID
		,TCC.CreditCardIssueNumber
		,POS.Name 
		,TCC.ReferenceVendorNumber
		,V.VendorNumber
		,TCC.LastChargedDate 
FROM	TemporaryCreditCard TCC WITH(NOLOCK)
LEFT JOIN	TemporaryCreditCardStatus TCCS ON TCCS.ID = TCC.TemporaryCreditCardStatusID
LEFT JOIN	PurchaseOrder PO ON PO.PurchaseOrderNumber = TCC.ReferencePurchaseOrderNumber
LEFT JOIN	VendorLocation VL ON VL.ID = PO.VendorLocationID
LEFT JOIN   Vendor V ON V.ID = VL.VendorID
LEFT JOIN   PurchaseOrderStatus POS ON POS.ID = PO.PurchaseOrderStatusID
LEFT JOIN	PurchaseOrderPayStatusCode PSC ON PSC.ID = PO.PayStatusCodeID
WHERE
 ( ISNULL(@idType,'') = ''    
   OR    
   (@idType = 'CCMatchPO' AND TCC.ReferencePurchaseOrderNumber = @idValue )    
   OR    
   (@idType = 'Last5ofTempCC' AND RIGHT(TCC.CreditCardNumber,5) = @idValue )    
    
  )    
 AND  (    
   ( ISNULL(@CCMatchStatuses,'') = '')    
   OR    
   ( TCC.TemporaryCreditCardStatusID IN (    
           SELECT item FROM fnSplitString(@CCMatchStatuses,',')    
   ))    
  )    
  AND  (    
   ( ISNULL(@POPayStatuses,'') = '')    
   OR    
   ( PO.PayStatusCodeID IN (    
           SELECT item FROM fnSplitString(@POPayStatuses,',')    
   ))    
  )     
  AND  (    
       
   ( @CCFromDate IS NULL OR (@CCFromDate IS NOT NULL AND TCC.IssueDate >= @CCFromDate))    
    AND    
   ( @CCToDate IS NULL OR (@CCToDate IS NOT NULL AND TCC.IssueDate < DATEADD(DD,1,@CCToDate)))    
  )
  AND  (    
       
   ( @POFromDate IS NULL OR (@POFromDate IS NOT NULL AND PO.IssueDate >= @POFromDate))    
    AND    
   ( @POToDate IS NULL OR (@POToDate IS NOT NULL AND PO.IssueDate < DATEADD(DD,1,@POToDate)))    
  )
  AND ( ISNULL(@PostingBatchID,0) = 0 OR TCC.PostingBatchID = @PostingBatchID )
  
INSERT INTO #FinalResults_Sorted    
SELECT     
 T.ID,    
 T.CCRefPO,    
 T.TempCC,    
 T.CCIssueDate,    
 T.CCApprove,    
 T.CCCharge,    
 T.CCIssueStatus,    
 T.CCMatchStatus,    
 T.CCOrigPO,    
 T.PONumber,    
 T.PODate,    
 T.POPayStatus,    
 T.POCC,    
 T.POAmount,    
 T.InvoiceAmount,    
 T.Note,    
 T.ExceptionMessage,    
 T.POId,
 T.CreditCardIssueNumber,
 T.PurchaseOrderStatus,
 T.ReferenceVendorNumber,
 T.VendorNumber,
 T.LastChargedDate
FROM #FinalResults_Filtered T    


 ORDER BY     
  CASE WHEN @sortColumn = 'CCRefPO' AND @sortOrder = 'ASC'    
  THEN T.CCRefPO END ASC,     
  CASE WHEN @sortColumn = 'CCRefPO' AND @sortOrder = 'DESC'    
  THEN T.ID END DESC ,    
    
  CASE WHEN @sortColumn = 'TempCC' AND @sortOrder = 'ASC'    
  THEN T.TempCC END ASC,     
  CASE WHEN @sortColumn = 'TempCC' AND @sortOrder = 'DESC'    
  THEN T.TempCC END DESC ,    
     
 CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'ASC'    
  THEN T.CCIssueDate END ASC,     
  CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'DESC'    
  THEN T.CCIssueDate END DESC ,    
    
  CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'ASC'    
  THEN T.CCApprove END ASC,     
  CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'DESC'    
  THEN T.CCApprove END DESC ,    
    
  CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'ASC'    
  THEN T.CCCharge END ASC,     
  CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'DESC'    
  THEN T.CCCharge END DESC ,    
    
  CASE WHEN @sortColumn = 'CCIssueStatus' AND @sortOrder = 'ASC'    
  THEN T.CCIssueStatus END ASC,     
  CASE WHEN @sortColumn = 'CCIssueStatus' AND @sortOrder = 'DESC'    
  THEN T.CCIssueStatus END DESC ,    
    
  CASE WHEN @sortColumn = 'CCMatchStatus' AND @sortOrder = 'ASC'    
  THEN T.CCMatchStatus END ASC,     
  CASE WHEN @sortColumn = 'CCMatchStatus' AND @sortOrder = 'DESC'    
  THEN T.CCMatchStatus END DESC ,    
    
  CASE WHEN @sortColumn = 'CCOrigPO' AND @sortOrder = 'ASC'    
  THEN T.CCOrigPO END ASC,     
  CASE WHEN @sortColumn = 'CCOrigPO' AND @sortOrder = 'DESC'    
  THEN T.CCOrigPO END DESC ,    
    
  CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'    
  THEN T.PONumber END ASC,     
  CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'    
  THEN T.PONumber END DESC ,    
    
  CASE WHEN @sortColumn = 'PODate' AND @sortOrder = 'ASC'    
  THEN T.PODate END ASC,     
  CASE WHEN @sortColumn = 'PODate' AND @sortOrder = 'DESC'    
  THEN T.PODate END DESC ,    
    
  CASE WHEN @sortColumn = 'POPayStatus' AND @sortOrder = 'ASC'    
  THEN T.POPayStatus END ASC,     
  CASE WHEN @sortColumn = 'POPayStatus' AND @sortOrder = 'DESC'    
  THEN T.POPayStatus END DESC ,    
    
  CASE WHEN @sortColumn = 'POCC' AND @sortOrder = 'ASC'    
  THEN T.POCC END ASC,     
  CASE WHEN @sortColumn = 'POCC' AND @sortOrder = 'DESC'    
  THEN T.POCC END DESC ,    
    
  CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'ASC'    
  THEN T.POAmount END ASC,     
  CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'DESC'    
  THEN T.POAmount END DESC ,    
    
  CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'    
  THEN T.InvoiceAmount END ASC,     
  CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'    
  THEN T.InvoiceAmount END DESC ,    
    
  CASE WHEN @sortColumn = 'Note' AND @sortOrder = 'ASC'    
  THEN T.Note END ASC,     
  CASE WHEN @sortColumn = 'Note' AND @sortOrder = 'DESC'    
  THEN T.Note END DESC    ,    
    
  CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'ASC'    
  THEN T.CreditCardIssueNumber END ASC,     
  CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'DESC'    
  THEN T.CreditCardIssueNumber END DESC,
  
  CASE WHEN @sortColumn = 'PurchaseOrderStatus' AND @sortOrder = 'ASC'    
  THEN T.PurchaseOrderStatus END ASC,     
  CASE WHEN @sortColumn = 'PurchaseOrderStatus' AND @sortOrder = 'DESC'    
  THEN T.PurchaseOrderStatus END DESC,
  
  CASE WHEN @sortColumn = 'ReferenceVendorNumber' AND @sortOrder = 'ASC'    
  THEN T.ReferenceVendorNumber END ASC,     
  CASE WHEN @sortColumn = 'ReferenceVendorNumber' AND @sortOrder = 'DESC'    
  THEN T.ReferenceVendorNumber END DESC,
  
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'    
  THEN T.VendorNumber END ASC,     
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'    
  THEN T.VendorNumber END DESC,

  CASE WHEN @sortColumn = 'LastChargedDate' AND @sortOrder = 'ASC'    
  THEN T.LastChargedDate END ASC,     
  CASE WHEN @sortColumn = 'LastChargedDate' AND @sortOrder = 'DESC'    
  THEN T.LastChargedDate END DESC
  
 --CreditCardIssueNumber
    
SELECT @matchedCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus = 'Matched'      
SELECT @exceptionCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus = 'Exception'      
SELECT @cancelledCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus= 'Cancelled'    
SELECT @postedCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus= 'Posted' 
SELECT @unmatchedCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus= 'Unmatched'    
   
    
DECLARE @count INT       
SET @count = 0       
SELECT @count = MAX(RowNum) FROM #FinalResults_Sorted    
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
    
SELECT   
   @count AS TotalRows  
 , *  
 , @matchedCount AS MatchedCount   
 , @exceptionCount AS ExceptionCount  
 , @postedCount AS PostedCount  
 , @cancelledCount AS CancellledCount
 , @unmatchedCount AS UnMatchedCount
 
FROM #FinalResults_Sorted WHERE RowNum BETWEEN @startInd AND @endInd    
    
DROP TABLE #tmpForWhereClause    
DROP TABLE #FinalResults_Filtered    
DROP TABLE #FinalResults_Sorted  

    
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
LEFT OUTER JOIN(
	  SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID
	  FROM dbo.fnGetContractedVendors() cv
	  ) ContractedVendors ON v.ID = ContractedVendors.VendorID
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
	  LEFT OUTER JOIN(  
   SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID  
   FROM dbo.fnGetContractedVendors() cv  
   ) ContractedVendors ON V.ID = ContractedVendors.VendorID   
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
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Cancelled%') 
						AND vi.ID IS NULL 
						AND tc.IssueStatus = 'Cancel'
						AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN @CancelledTemporaryCreditCardStatusID
				 --Matched
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount 
					THEN @MatchedTemporaryCreditCardStatusID
				 --Exception
				 ELSE @ExceptionTemporaryCreditCardStatusID
				 END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				 --Cancelled 
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Cancelled%') 
						AND vi.ID IS NULL 
						AND tc.IssueStatus = 'Cancel'
						AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN NULL
				 --Matched
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount 
					THEN NULL
				 --Exception: Charge more than PO Amount
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > po.PurchaseOrderAmount 
					THEN 'Charge amount exceeds PO amount'
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
			CASE WHEN tc.IssueStatus = 'Cancel' THEN @CancelledTemporaryCreditCardStatusID
				 ELSE @ExceptionTemporaryCreditCardStatusID
				 END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE WHEN tc.IssueStatus = 'Cancel' THEN NULL
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
		TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
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
