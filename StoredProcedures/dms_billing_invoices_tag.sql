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
-- EXEC [dbo].[dms_billing_invoices_tag] @invoicesXML = '<Invoices><ID>41</ID></Invoices>',@billedBatchID = 999,@unBilledBatchID=1, @currentUser='kbanda',@eventSource='',@eventDetails=''
 -- EXEC [dbo].[dms_billing_invoices_tag] @invoicesXML = '<Invoices><ID>41</ID></Invoices>',@billedBatchID = 999,@unBilledBatchID=1, @currentUser='kbanda',@eventSource='',@eventDetails=''
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
			@BillingInvoiceDetailStatus_DELETED as int,
			
			@serviceRequestEntityID INT,
			@purchaseOrderEntityID INT,
			@claimEntityID INT,
			@vendorInvoiceEntityID INT,
			@billingInvoiceEntityID INT,
			@postInvoiceEventID INT	,
			@ServiceRequestAgentTimeEntityID INT
	
	SELECT @BillingInvoiceDetailStatus_POSTED = (SELECT ID from BillingInvoiceDetailStatus where Name = 'POSTED')
	SELECT @BillingInvoiceLineStatus_POSTED = (SELECT ID from BillingInvoiceLineStatus where Name = 'POSTED')
	SELECT @BillingInvoiceStatus_POSTED = (SELECT ID from BillingInvoiceStatus where Name = 'POSTED')
	SELECT @BillingInvoiceDisposition_LOCKED = (SELECT ID from BillingInvoiceDetailDisposition where Name = 'LOCKED')
	SELECT @BillingInvoiceDetailStatus_DELETED = (SELECT ID from BillingInvoiceDetailStatus where Name = 'DELETED')
 
 
	SELECT @serviceRequestEntityID = ID FROM Entity WHERE Name = 'ServiceRequest'
	SELECT @purchaseOrderEntityID = ID FROM Entity WHERE Name = 'PurchaseOrder'
	SELECT @claimEntityID = ID FROM Entity WHERE Name = 'Claim'
	SELECT @vendorInvoiceEntityID = ID FROM Entity WHERE Name = 'VendorInvoice'
	SELECT @billingInvoiceEntityID = ID FROM Entity WHERE Name = 'BillingInvoice'
	SELECT @ServiceRequestAgentTimeEntityID = ID FROM Entity WHERE Name = 'ServiceRequestAgentTime'
	
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
		WHERE	BI.ID = @billingInvoiceID AND BID.InvoiceDetailStatusID <> @BillingInvoiceDetailStatus_DELETED
		
		
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
		
		-- SR Agent Time
		UPDATE	ServiceRequestAgentTime
		SET		AccountingInvoiceBatchID = BID.AccountingInvoiceBatchID
		FROM	ServiceRequestAgentTime SRT
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @ServiceRequestAgentTimeEntityID AND BID.EntityKey = SRT.ID
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

