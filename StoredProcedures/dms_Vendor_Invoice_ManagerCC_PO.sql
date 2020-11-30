IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Invoice_ManagerCC_PO]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Invoice_ManagerCC_PO] 
 END 
 GO  

/****** Object:  StoredProcedure [dbo].[dms_Vendor_Invoice_ManagerCC_PO]    Script Date: 11/17/2014 12:08:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
---- Create Vendor Invoices for POs paid with Manager's real CC -- not a temporary CC 
CREATE PROCEDURE [dbo].[dms_Vendor_Invoice_ManagerCC_PO]
AS
BEGIN

	--Delay creation of invoice to allow for changes after PO is initially issued
	DECLARE @InvoiceDelayDays int
	SET @InvoiceDelayDays = 10

    DECLARE @glAccountFromAppConfig NVARCHAR(255)
	SET @glAccountFromAppConfig = (SELECT Value FROM ApplicationConfiguration WHERE Name = 'ISPCheckGLExpenseAccount')

	INSERT INTO [DMS].[dbo].[VendorInvoice]
			   ([PurchaseOrderID]
			   ,[VendorID]
			   ,[VendorInvoiceStatusID]
			   ,[SourceSystemID]
			   ,[PaymentTypeID]
			   ,[AccountingInvoiceBatchID]
			   ,[InvoiceNumber]
			   ,[ReceivedDate]
			   ,[ReceiveContactMethodID]
			   ,[InvoiceDate]
			   ,[InvoiceAmount]
			   ,[BillingBusinessName]
			   ,[BillingContactName]
			   ,[BillingAddressLine1]
			   ,[BillingAddressLine2]
			   ,[BillingAddressLine3]
			   ,[BillingAddressCity]
			   ,[BillingAddressStateProvince]
			   ,[BillingAddressPostalCode]
			   ,[BillingAddressCountryCode]
			   ,[ToBePaidDate]
			   ,[ExportDate]
			   ,[ExportBatchID]
			   ,[PaymentDate]
			   ,[PaymentAmount]
			   ,[PaymentNumber]
			   ,[CheckClearedDate]
			   ,[ActualETAMinutes]
			   ,[Last8OfVIN]
			   ,[VehicleMileage]
			   ,[IsActive]
			   ,[CreateDate]
			   ,[CreateBy]
			   ,[ModifyDate]
			   ,[ModifyBy]
			   ,[VendorInvoicePaymentDifferenceReasonCodeID]
			   ,[GLExpenseAccount])
	Select 
			   po.ID [PurchaseOrderID]
			   ,vl.[VendorID]
			   ,(Select ID FROM VendorInvoiceStatus WHERE Name = 'Paid') [VendorInvoiceStatusID]
			   ,(Select ID From SourceSystem Where Name = 'Dispatch') [SourceSystemID]
			   ,(Select ID From PaymentType Where Name = 'MasterCard') [PaymentTypeID]
			   ,NULL [AccountingInvoiceBatchID]
			   ,NULL [InvoiceNumber]
			   ,po.IssueDate [ReceivedDate]
			   ,NULL [ReceiveContactMethodID]
			   ,po.IssueDate [InvoiceDate]
			   ,po.PurchaseOrderAmount [InvoiceAmount]
			   ,v.Name [BillingBusinessName]
			   ,NULL [BillingContactName]
			   ,[BillingAddressLine1]
			   ,[BillingAddressLine2]
			   ,[BillingAddressLine3]
			   ,[BillingAddressCity]
			   ,[BillingAddressStateProvince]
			   ,[BillingAddressPostalCode]
			   ,[BillingAddressCountryCode]
			   ,po.IssueDate [ToBePaidDate]
			   ,NULL [ExportDate]
			   ,NULL [ExportBatchID]
			   ,po.IssueDate [PaymentDate]
			   ,po.PurchaseOrderAmount [PaymentAmount]
			   ,NULL [PaymentNumber]
			   ,NULL [CheckClearedDate]
			   ,NULL [ActualETAMinutes]
			   ,Right(c.VehicleVIN,8) [Last8OfVIN]
			   ,c.VehicleCurrentMileage [VehicleMileage]
			   ,1 [IsActive]
			   ,getdate() [CreateDate]
			   ,'system' [CreateBy]
			   ,NULL [ModifyDate]
			   ,NULL [ModifyBy]
			   ,NULL [VendorInvoicePaymentDifferenceReasonCodeID]
			   ,COALESCE(
					[dbo].[fnc_GetProgramConfigurationItemValueForProgram](C.ProgramID,
						'Application',
						NULL, 
						CASE	WHEN ISNULL(C.IsDeliveryDriver,0) = 1 
								THEN 'DeliveryDriverISPGLCheckExpenseAccount'
								ELSE 'ISPCheckGLExpenseAccount' 
								END)
						,@glAccountFromAppConfig) [GLExpenseAccount]
	From PurchaseOrder po 
	Join ServiceRequest sr on sr.ID = po.ServiceRequestID
	Join [Case] c on c.id = sr.CaseID
	Join VendorLocation vl on po.VendorLocationID = vl.ID
	Join Vendor v on v.ID = vl.VendorID
	where
	po.IsActive = 1
	and po.PurchaseOrderStatusID in (Select ID From PurchaseOrderStatus Where Name in ('Issued', 'Issued-Paid')) 
	and right(po.CompanyCreditCardNumber,4) in (
	---- List of CCs issued to Managers
	'6519'
	,'6501'
	,'5787'
	,'5944')
	and Not exists (
		Select * From VendorInvoice vi where vi.PurchaseOrderID = po.ID)
	and po.IssueDate < DATEADD(dd,-10, GETDATE())

END
GO
