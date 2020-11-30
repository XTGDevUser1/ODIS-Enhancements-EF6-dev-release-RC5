IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_invoice_batch_details_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_invoice_batch_details_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vendor_invoice_batch_details_update] @invoicesXML = '<Invoices><ID>17</ID><ID>35</ID><ID>3</ID><ID>4</ID></Invoices>',@batchID = 999, @currentUser='kbanda',@eventSource='SQL', @eventDetails='TEST'
 CREATE PROCEDURE [dbo].[dms_vendor_invoice_batch_details_update](
	@invoicesXML XML,
	@batchID BIGINT,
	@currentUser NVARCHAR(50),
	@eventSource NVARCHAR(MAX),
	@eventName NVARCHAR(100) = 'PayInvoices',
	@eventDetails NVARCHAR(MAX),
	@entityName NVARCHAR(50) = 'VendorInvoice',
	@sessionID NVARCHAR(MAX) = NULL
 )
 AS
 BEGIN
 
	DECLARE @now DATETIME = GETDATE()
	
	DECLARE @invoicesFromDB TABLE
	(	
		ID INT IDENTITY(1,1),
		InvoiceID INT
	)
	
	INSERT INTO @invoicesFromDB
	SELECT VI.ID
	FROM	VendorInvoice VI
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @invoicesXML.nodes('/Invoices/ID') T(c)
			) T ON VI.ID = T.ID
	
	DECLARE @paidStatusID INT, 
			@payInvoicesEventID INT, 
			@vendorInvoiceEntityID INT,
			@checkPaymentTypeID INT,
			@ACHPaymentTypeID INT,
			@ACHValidStatusID INT
			
	SELECT @paidStatusID = ID FROM VendorInvoiceStatus WHERE Name = 'Paid'
	SELECT @payInvoicesEventID = ID FROM Event WHERE Name = @eventName
	SELECT @vendorInvoiceEntityID = ID FROM Entity WHERE Name = @entityName
	SELECT @checkPaymentTypeID = ID FROM PaymentType WHERE Name = 'Check'
	SELECT @ACHPaymentTypeID = ID FROM PaymentType WHERE Name = 'ACH'
	SELECT @ACHValidStatusID = ID FROM ACHStatus WHERE Name = 'Valid'
	
	UPDATE	VendorInvoice
	SET		ExportBatchID = @batchID,
			ExportDate = @now,
			ModifyBy = @currentUser,
			ModifyDate = @now,
			VendorInvoiceStatusID = @paidStatusID,
			PaymentDate = @now,
			--PaymentAmount = CASE WHEN VI.PaymentAmount IS NULL THEN VI.InvoiceAmount ELSE VI.PaymentAmount END,
			PaymentTypeID = Case WHEN ACH.ACHStatusID = @ACHValidStatusID
									THEN @ACHPaymentTypeID
									ELSE @checkPaymentTypeID
							END
	FROM	VendorInvoice VI
	JOIN	@invoicesFromDB I ON VI.ID = I.InvoiceID
	LEFT JOIN VendorACH ACH ON VI.VendorID = ACH.VendorID AND ISNULL(ACH.IsActive,0) = 1
	

	-- KB : Update GLExpenseAccount Details on VendorInvoices.
	DECLARE @glAccountFromAppConfig NVARCHAR(255)

	SET @glAccountFromAppConfig = (SELECT Value FROM ApplicationConfiguration WHERE Name = 'ISPCheckGLExpenseAccount')

	;WITH wVendorInvoiceGLExpenseAccount
	AS
	(
		SELECT	VI.ID AS VendorInvoiceID,
				PO.PurchaseOrderNumber,		
				@glAccountFromAppConfig AS AppConfigValue,
				C.ProgramID,
				C.IsDeliveryDriver,
				[dbo].[fnc_GetProgramConfigurationItemValueForProgram](C.ProgramID,
																	'Application',
																	NULL, 
																	CASE	WHEN ISNULL(C.IsDeliveryDriver,0) = 1 
																			THEN 'DeliveryDriverISPGLCheckExpenseAccount'
																			ELSE 'ISPCheckGLExpenseAccount' 
																			END) AS ProgramConfigItemValue
		FROM	VendorInvoice VI
		JOIN	@invoicesFromDB I ON VI.ID = I.InvoiceID
		JOIN	PurchaseOrder PO ON VI.PurchaseOrderID = PO.ID
		JOIN	ServiceRequest SR ON PO.ServiceRequestID = SR.ID
		JOIN	[Case] C ON SR.CaseID = C.ID
	)
	
	UPDATE	VendorInvoice
	SET		GLExpenseAccount = COALESCE(W.ProgramConfigItemValue,AppConfigValue)
	FROM	VendorInvoice VI
	JOIN	wVendorInvoiceGLExpenseAccount W ON VI.ID = W.VendorInvoiceID

	-- Event Logs.
	DECLARE @maxRows INT, @index INT = 1
	SELECT @maxRows = COUNT(*) FROM @invoicesFromDB
	
	WHILE ( @index <= @maxRows)
	BEGIN
		
		INSERT INTO EventLog
		SELECT	@payInvoicesEventID,
				@sessionID,
				@eventSource,
				@eventDetails,
				NULL,
				NULL,
				GETDATE(),
				@currentUser
				
		INSERT INTO EventLogLink
		SELECT	SCOPE_IDENTITY(),
				@vendorInvoiceEntityID,
				(SELECT InvoiceID FROM @invoicesFromDB WHERE ID = @index)			
	
		SET @index = @index + 1
	END
 
 END