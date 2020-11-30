IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_invoice_or_claim_batch_statistics_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_invoice_or_claim_batch_statistics_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vendor_invoice_or_claim_batch_statistics_update] @invoicesOrClaimsXML = '<Invoices><ID>1</ID><ID>2</ID><ID>3</ID><ID>4</ID></Invoices>',@batchID = 999, @currentUser='kbanda'
 CREATE PROCEDURE [dbo].[dms_vendor_invoice_or_claim_batch_statistics_update](
	@invoicesOrClaimsXML XML,
	@batchID BIGINT,
	@batchStatus NVARCHAR(50),	
	@currentUser NVARCHAR(50),
	@entityName NVARCHAR(50),
	@unbilledBatchID BIGINT = NULL 
 )
 AS
 BEGIN
 
	DECLARE @now DATETIME = GETDATE()
	DECLARE @totalAmount money
	
	DECLARE @invoicesOrClaimsFromDB TABLE
	(	
		ID INT IDENTITY(1,1),
		RecordID INT
	)
	
	IF ( @entityName = 'VendorInvoice')
	BEGIN
		INSERT INTO @invoicesOrClaimsFromDB
		SELECT VI.ID
		FROM	VendorInvoice VI
		JOIN	(
					SELECT  T.c.value('.','INT') AS ID
					FROM @invoicesOrClaimsXML.nodes('/Invoices/ID') T(c)
				) T ON VI.ID = T.ID
				
				
		SELECT	@totalAmount = SUM(ISNULL(VI.InvoiceAmount,0))
		FROM	VendorInvoice VI
		JOIN	@invoicesOrClaimsFromDB I ON VI.ID = I.RecordID
	END
	ELSE IF ( @entityName = 'Claim')
	BEGIN
		INSERT INTO @invoicesOrClaimsFromDB
		SELECT C.ID
		FROM	Claim C
		JOIN	(
					SELECT  T.c.value('.','INT') AS ID
					FROM @invoicesOrClaimsXML.nodes('/Claims/ID') T(c)
				) T ON C.ID = T.ID
		JOIN	ClaimType CT ON C.ClaimTypeID = CT.ID
		WHERE	CT.Name <> 'FordQFC'	
			
		SELECT	@totalAmount = SUM(ISNULL(C.AmountApproved,0))
		FROM	Claim C
		JOIN	@invoicesOrClaimsFromDB I ON C.ID = I.RecordID
	
	END
	ELSE IF ( @entityName = 'BillingInvoice')
	BEGIN
		INSERT INTO @invoicesOrClaimsFromDB
		SELECT BI.ID
		FROM	BillingInvoice BI
		JOIN	(
					SELECT  T.c.value('.','INT') AS ID
					FROM @invoicesOrClaimsXML.nodes('/Invoices/ID') T(c)
				) T ON BI.ID = T.ID
			
			
		SELECT	@totalAmount = SUM(ISNULL(BIL.LineAmount,0))
		FROM	BillingInvoice BI
		JOIN	BillingInvoiceLine BIL ON BIL.BillingInvoiceID = BI.ID
		JOIN	@invoicesOrClaimsFromDB I ON BI.ID = I.RecordID
	
	END
	
	DECLARE @maxRows INT, @batchStatusID INT
	SELECT @maxRows = COUNT(*) FROM @invoicesOrClaimsFromDB
	SELECT @batchStatusID = ID FROM BatchStatus WHERE Name = @batchStatus
	
	UPDATE	Batch
	SET		BatchStatusID = @batchStatusID,
			TotalCount = @maxRows,
			TotalAmount = @totalAmount,
			ModifyBy = @currentUser,
			ModifyDate = @now
	WHERE	ID = @batchID
	
	-- KB: The following case arises in the case of BillingInvoices only.
	IF @unbilledBatchID IS NOT NULL
	BEGIN
		UPDATE	Batch
		SET		BatchStatusID = @batchStatusID,				
				ModifyBy = @currentUser,
				ModifyDate = @now
		WHERE	ID = @unbilledBatchID
		
	END
	
	
	
	SELECT @totalAmount AS TotalAmount
 
 END