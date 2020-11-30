IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_client_update_billinginvoicedetail_disposition]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_client_update_billinginvoicedetail_disposition] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_client_update_billinginvoicedetail_disposition] @billingeventdetailIdXML = '<BillingInvoiceDetail><ID>1</ID><ID>2</ID></BillingInvoiceDetail>',@currentUser = 'demouser',@statusId=1,@eventId=70234
 CREATE PROCEDURE [dbo].[dms_client_update_billinginvoicedetail_disposition](
	@billingeventdetailIdXML XML,
	@currentUser NVARCHAR(50),
	@statusId int,
	@eventId int
	
 )
 AS
 BEGIN
 
    SET FMTONLY OFF
	SET NOCOUNT ON
	
	DECLARE @now DATETIME = GETDATE()
	
	
	DECLARE @entityId INT
	SET @entityId = (SELECT ID FROM Entity WHERE Name='BillingInvoiceDetail')
	
	CREATE TABLE #SelectedBillingInvoiceDetail
	(	
		ID INT IDENTITY(1,1),
		BillingInvoiceDetailId INT
	)
	
	INSERT INTO #SelectedBillingInvoiceDetail
	SELECT tcc.ID
	FROM BillingInvoiceDetail tcc WITH (NOLOCK)
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @billingeventdetailIdXML.nodes('/BillingInvoiceDetail/ID') T(c)
			) T ON tcc.ID = T.ID

	CREATE CLUSTERED INDEX IDX_SelectedBillingInvoiceDetail ON #SelectedBillingInvoiceDetail(BillingInvoiceDetailId)
	
	--Insert log records
	INSERT INTO EventLogLink
	SELECT @eventId,
	       @entityId,
	       BillingInvoiceDetailId
	FROM #SelectedBillingInvoiceDetail
	
	--Update BillingInvoiceDetail
	UPDATE BillingInvoiceDetail
	SET InvoiceDetailDispositionID = @statusId,
	    ModifyBy = @currentUser,
	    ModifyDate = @now
	WHERE ID IN(SELECT BillingInvoiceDetailId FROM #SelectedBillingInvoiceDetail)
	
	DROP TABLE #SelectedBillingInvoiceDetail
	
 END
 
 GO
 
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_client_update_billingeventedetail_status]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_client_update_billingeventedetail_status] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_client_update_billingeventedetail_status] @billingeventdetailIdXML = '<BillingInvoiceDetail><ID>1</ID><ID>2</ID></BillingInvoiceDetail>',@currentUser = 'demouser',@statusId=1,@eventId=70234
 CREATE PROCEDURE [dbo].[dms_client_update_billingeventedetail_status](
	@billingeventdetailIdXML XML,
	@currentUser NVARCHAR(50),
	@statusId int,
	@eventId int
	
 )
 AS
 BEGIN
 
    SET FMTONLY OFF
	SET NOCOUNT ON
	
	DECLARE @now DATETIME = GETDATE()
	
	
	DECLARE @entityId INT
	SET @entityId = (SELECT ID FROM Entity WHERE Name='BillingInvoiceDetail')
	
	CREATE TABLE #SelectedBillingInvoiceDetailStatus
	(	
		ID INT IDENTITY(1,1),
		BillingInvoiceDetailId INT
	)
	
	INSERT INTO #SelectedBillingInvoiceDetailStatus
	SELECT tcc.ID
	FROM BillingInvoiceDetail tcc WITH (NOLOCK)
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @billingeventdetailIdXML.nodes('/BillingInvoiceDetail/ID') T(c)
			) T ON tcc.ID = T.ID

	CREATE CLUSTERED INDEX IDX_SelectedBillingInvoiceDetailStatus ON #SelectedBillingInvoiceDetailStatus(BillingInvoiceDetailId)
	
	--Insert log records
	INSERT INTO EventLogLink
	SELECT @eventId,
	       @entityId,
	       BillingInvoiceDetailId
	FROM #SelectedBillingInvoiceDetailStatus
	
	--Update BillingInvoiceDetail
	UPDATE BillingInvoiceDetail
	SET InvoiceDetailStatusID = @statusId,
	    ModifyBy = @currentUser,
	    ModifyDate = @now
	WHERE ID IN(SELECT BillingInvoiceDetailId FROM #SelectedBillingInvoiceDetailStatus)
	
	DROP TABLE #SelectedBillingInvoiceDetailStatus
	
 END
 
 GO
 
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_billing_invoices_tag]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_billing_invoices_tag] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_billing_invoices_tag] @invoicesOrClaimsXML = '<Invoices><ID>41</ID></Invoices>',@batchID = 999, @currentUser='kbanda'
 CREATE PROCEDURE [dbo].[dms_billing_invoices_tag](
	@invoicesXML XML,
	@billedBatchID BIGINT,
	@unBilledBatchID BIGINT,
	@currentUser NVARCHAR(50),
	@eventSource NVARCHAR(MAX),
	@eventName NVARCHAR(100) = 'PostInvoice',
	@eventDetails NVARCHAR(MAX),
	@entityName NVARCHAR(50) = 'BillingInvoice',
	@sessionID NVARCHAR(MAX) = NULL	
 )
 AS
 BEGIN
 
	DECLARE @now DATETIME = GETDATE()
	
	DECLARE @tblBillingInvoices TABLE
	(	
		ID INT IDENTITY(1,1),
		RecordID INT
	)
	
	INSERT INTO @tblBillingInvoices
	SELECT BI.ID
	FROM	BillingInvoice BI
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @invoicesXML.nodes('/Invoices/ID') T(c)
			) T ON BI.ID = T.ID
			
	DECLARE	@BillingInvoiceDetailStatus_POSTED as int,
			@BillingInvoiceLineStatus_POSTED as int,
			@BillingInvoiceStatus_POSTED as int,
			@BillingInvoiceDisposition_LOCKED as int,
			@BillingInvoiceStatus_DELETED as int,
			
			@serviceRequestEntityID INT,
			@purchaseOrderEntityID INT,
			@claimEntityID INT,
			@vendorInvoiceEntityID INT,
			@billingInvoiceEntityID INT,
			@postInvoiceEventID INT	
	
	SELECT @BillingInvoiceDetailStatus_POSTED = (SELECT ID from BillingInvoiceDetailStatus where Name = 'POSTED')
	SELECT @BillingInvoiceLineStatus_POSTED = (SELECT ID from BillingInvoiceLineStatus where Name = 'POSTED')
	SELECT @BillingInvoiceStatus_POSTED = (SELECT ID from BillingInvoiceStatus where Name = 'POSTED')
	SELECT @BillingInvoiceDisposition_LOCKED = (SELECT ID from BillingInvoiceDetailDisposition where Name = 'LOCKED')
	SELECT @BillingInvoiceStatus_DELETED = (SELECT ID from BillingInvoiceStatus where Name = 'DELETED')
 
 
	SELECT @serviceRequestEntityID = ID FROM Entity WHERE Name = 'ServiceRequest'
	SELECT @purchaseOrderEntityID = ID FROM Entity WHERE Name = 'PurchaseOrder'
	SELECT @claimEntityID = ID FROM Entity WHERE Name = 'Claim'
	SELECT @vendorInvoiceEntityID = ID FROM Entity WHERE Name = 'VendorInvoice'
	SELECT @billingInvoiceEntityID = ID FROM Entity WHERE Name = 'BillingInvoice'
	
	SELECT @postInvoiceEventID = ID FROM [Event] WHERE Name = 'PostInvoice'
	
	DECLARE @index INT = 1, @maxRows INT = 0, @billingInvoiceID INT = 0
	
	SELECT @maxRows = MAX(ID) FROM @tblBillingInvoices
	
	--DEBUG: SELECT @index,@maxRows
	
	WHILE (@index <= @maxRows AND @maxRows > 0)
	BEGIN
		
		
		
		SELECT @billingInvoiceID = RecordID FROM @tblBillingInvoices WHERE ID = @index
		
		--DEBUG: SELECT 'Updating statuses' As StatusMessage,@billingInvoiceID AS InvoiceID
		
		-- Update Billing Invoice.
		UPDATE	BillingInvoice 
		SET		InvoiceStatusID = @BillingInvoiceStatus_POSTED,
				AccountingInvoiceBatchID = @billedBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		WHERE	ID = @billingInvoiceID		
		
		-- Update Billing InvoiceLines
		UPDATE	BillingInvoiceLine
		SET		InvoiceLineStatusID = @BillingInvoiceLineStatus_POSTED,
				ModifyBy = @currentUser,
				ModifyDate = @now
		WHERE	BillingInvoiceID = @billingInvoiceID
		
		-- Update BillingInvoiceDetail and related entities.
		UPDATE	BillingInvoiceDetail
		SET		AccountingInvoiceBatchID = CASE WHEN ISNULL(BID.IsExcluded,0) = 1
												THEN @unBilledBatchID
												ELSE @billedBatchID
											END,
				InvoiceDetailDispositionID = @BillingInvoiceDisposition_LOCKED,
				InvoiceDetailStatusID = @BillingInvoiceDetailStatus_POSTED,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	BillingInvoiceDetail BID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID AND BID.InvoiceDetailStatusID <> @BillingInvoiceStatus_DELETED
		
		
		-- SRs
		UPDATE	ServiceRequest
		SET		AccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	ServiceRequest SR
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @serviceRequestEntityID AND BID.EntityKey = SR.ID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
				
		-- POs
		UPDATE	PurchaseOrder
		SET		AccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	PurchaseOrder PO
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @purchaseOrderEntityID AND BID.EntityKey = PO.ID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
		
		-- Claims PassThru
		UPDATE	Claim
		SET		PassthruAccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	Claim C
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @claimEntityID AND BID.EntityKey = C.ID
		JOIN	BillingDefinitionInvoiceLine BDIL ON BID.BillingDefinitionInvoiceLineID = BDIL.ID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
		AND		BDIL.Rate IS NULL
		
		-- Claims Fee
		UPDATE	Claim
		SET		FeeAccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	Claim C
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @claimEntityID AND BID.EntityKey = C.ID
		JOIN	BillingDefinitionInvoiceLine BDIL ON BID.BillingDefinitionInvoiceLineID = BDIL.ID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
		AND		BDIL.Rate IS NOT NULL
		
		-- VendorInvoice
		UPDATE	VendorInvoice
		SET		AccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	VendorInvoice VI
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @vendorInvoiceEntityID AND BID.EntityKey = VI.ID		
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
		
		
		INSERT INTO EventLog
		SELECT	@postInvoiceEventID,
				@sessionID,
				@eventSource,
				@eventDetails,
				NULL,
				NULL,
				GETDATE(),
				@currentUser
				
		INSERT INTO EventLogLink
		SELECT	SCOPE_IDENTITY(),
				@billingInvoiceEntityID,
				@billingInvoiceID			
	
		SET @index = @index + 1
		
		
	END
 
 
 END

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Call_Summary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Call_Summary]
GO

--EXEC dms_Call_Summary @serviceRequestID = 2  
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
    ,(SELECT 'Case Number - '+Value FROM @ProgramDataItemValues WHERE ScreenName='StartCall' AND Name='CaseNumber') AS Program_CaseNumber
    ,(SELECT 'Agent Name - '+Value FROM @ProgramDataItemValues WHERE ScreenName='StartCall' AND Name='GlobalAssistAgent') AS Program_AgentName
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
	,'Receipt Number : ' + ms.ClientReferenceNumber AS Member_ReceiptNumber
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