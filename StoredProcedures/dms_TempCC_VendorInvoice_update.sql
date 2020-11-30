IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_TempCC_VendorInvoice_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_TempCC_VendorInvoice_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_TempCC_VendorInvoice_update] 169
 CREATE PROCEDURE [dbo].[dms_TempCC_VendorInvoice_update](
 @BatchId int
 )
 AS 
 BEGIN
 
	---- Added Logic to create invoices for 'real' CCs issued to Managers to pay POs
	---- Identifies specific CC#s and creates corresponding Vendor Invoices
	---- Added here to be part of the Temp CC Post processing
	EXEC dms_Vendor_Invoice_ManagerCC_PO
	---- End Comment


    DECLARE @invoicesFromDB TABLE
	(	
		ID INT IDENTITY(1,1),
		InvoiceID INT
	)
	
	INSERT INTO @invoicesFromDB
	SELECT VI.ID
	FROM	VendorInvoice VI
	WHERE VI.ExportBatchID = @BatchId
	
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
	
	
 END
 