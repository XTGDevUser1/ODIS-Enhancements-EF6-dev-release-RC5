CREATE VIEW [dbo].[vw_VendorInvoices]
AS
SELECT VI.[ID] VendorInvoiceID
	,VI.[PurchaseOrderID]
	,PO.PurchaseOrderNumber
	,PO.PurchaseOrderAmount
	,PO.ServiceRequestID
	,CL.ID ClientID
	,CL.Name ClientName
	,PRGM.ID ProgramID
	,PRGM.Name ProgramName
	,VI.[VendorID]
	,V.VendorNumber
	,VI.[VendorInvoiceStatusID]
	,VIS.Description VendorInvoiceStatusDescription
	,VI.[SourceSystemID]
	,SS.Description SourceSystemDescription
	,VI.[InvoiceNumber]
	,VI.[ReceivedDate]
	,VI.[ReceiveContactMethodID]
	,CM.Description ContactMethodDescription
	,VI.[InvoiceDate]
	,VI.[InvoiceAmount]
	,VI.[BillingBusinessName]
	,V.CorporationName
	,VI.[BillingContactName]
	,VI.[BillingAddressLine1]
	,VI.[BillingAddressLine2]
	,VI.[BillingAddressLine3]
	,VI.[BillingAddressCity]
	,VI.[BillingAddressStateProvince]
	,VI.[BillingAddressPostalCode]
	,VI.[BillingAddressCountryCode]
	,VI.[ToBePaidDate]
	,VI.[ExportDate]
	,VI.[ExportBatchID]
	,VI.[PaymentTypeID]
	,PT.Description PaymentTypeDescription
	,VI.[PaymentDate]
	,VI.[PaymentAmount]
	,VI.[PaymentNumber]
	,VI.[CheckClearedDate]
	,VI.[ActualETAMinutes]
	,VI.[Last8OfVIN]
	,VI.[VehicleMileage]
	,VI.[IsActive]
	,VI.[CreateDate]
	,VI.[CreateBy]
	,VI.[ModifyDate]
	,VI.[ModifyBy]
	,VI.[AccountingInvoiceBatchID]
	,VI.[VendorInvoicePaymentDifferenceReasonCodeID]
	,VIPDRC.Description VendorInvoicePaymentDifferenceReasonCodeDescription
	,VI.[GLExpenseAccount]
	,COALESCE(V.TaxClassification, TaxClassificationOther,'') [Tax Classification]
	,ISNULL(V.TaxEIN,'') [Tax EIN]
	,ISNULL(V.TaxSSN,'') [Tax SSN]
	,CASE WHEN ISNULL(Batch.BatchType, '') = 'ClientBillingUnbilled' THEN 1 ELSE 0 END IsExcludedFromBilling
FROM [dbo].[VendorInvoice] VI WITH(NOLOCK)
LEFT JOIN PurchaseOrder PO WITH(NOLOCK) ON VI.PurchaseOrderID = PO.ID
LEFT JOIN ServiceRequest SR WITH(NOLOCK) ON SR.ID = PO.ServiceRequestID
LEFT JOIN [Case] C WITH(NOLOCK) ON C.ID = SR.CaseID
LEFT JOIN Program PRGM WITH(NOLOCK) ON PRGM.ID = C.ProgramID
LEFT JOIN Client CL WITH(NOLOCK) ON  CL.ID = PRGM.ClientID
LEFT JOIN Vendor V WITH(NOLOCK) ON VI.VendorID = V.ID	
LEFT JOIN VendorInvoiceStatus VIS WITH(NOLOCK) ON VI.VendorInvoiceStatusID = VIS.ID
LEFT JOIN SourceSystem SS WITH(NOLOCK) ON VI.SourceSystemID = SS.ID
LEFT JOIN ContactMethod CM WITH(NOLOCK) ON VI.ReceiveContactMethodID = CM.ID
LEFT JOIN PaymentType PT WITH(NOLOCK) ON VI.PaymentTypeID = PT.ID
LEFT JOIN VendorInvoicePaymentDifferenceReasonCode VIPDRC  WITH(NOLOCK) ON VI.VendorInvoicePaymentDifferenceReasonCodeID = VIPDRC.ID
LEFT JOIN dbo.vw_Batches batch on batch.BatchID = vi.AccountingInvoiceBatchID
GO

