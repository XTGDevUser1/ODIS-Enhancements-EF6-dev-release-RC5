 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_Details_Get @VendorInvoiceID=14329
 CREATE PROCEDURE [dbo].dms_Vendor_Invoice_Details_Get( 
	@VendorInvoiceID INT =NULL
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET FMTONLY OFF
    SELECT VI.ID
	, VI.VendorInvoiceStatusID
	, VIS.Name AS VendorInvoiceStatus
	, PO.PurchaseOrderNumber
	, V.VendorNumber
	, VI.InvoiceNumber
	, VI.InvoiceAmount
	, VI.InvoiceDate
	, VI.ReceivedDate
	, VI.ReceiveContactMethodID
	, VI.ActualETAMinutes
	, VI.Last8OfVIN
	, VI.VehicleMileage
	, VI.ToBePaidDate
	, VI.ExportDate
	, VI.ExportBatchID
	, VI.BillingBusinessName
	, VI.BillingContactName
	, VI.BillingAddressLine1
	, VI.BillingAddressLine2
	, VI.BillingAddressLine3
	, VI.BillingAddressCity
	, VI.BillingAddressStateProvince
	, VI.BillingAddressPostalCode
	, VI.BillingAddressCountryCode
	, PT.Name AS PaymentType
	, VI.PaymentDate AS PaymentDate
	, VI.PaymentAmount
	, VI.PaymentNumber
	, VI.CheckClearedDate AS CheckClearedDate
	, SS.Name AS SourceSystem
	, VI.CreateBy
	, VI.CreateDate
	, VI.ModifyBy
	, VI.ModifyDate
	, VI.VendorInvoicePaymentDifferenceReasonCodeID
	, V.ID AS VendorID
	, VI.GLExpenseAccount AS GLExpenseAccount
FROM VendorInvoice VI
JOIN VendorInvoiceStatus VIS ON VIS.ID = VI.VendorInvoiceStatusID
LEFT JOIN PaymentType PT ON PT.ID = VI.PaymentTypeID
JOIN Vendor V ON V.ID = VI.VendorID
JOIN PurchaseOrder PO ON PO.ID = VI.PurchaseOrderID
JOIN PurchaseOrderStatus POS ON POS.ID = PO.PurchaseOrderStatusID
LEFT JOIN SourceSystem SS ON SS.ID = VI.SourceSystemID
WHERE VI.ID = @VendorInvoiceID
END
GO
