IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ClientBillableEventProcessing_Exceptions]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ClientBillableEventProcessing_Exceptions] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

CREATE PROC dms_ClientBillableEventProcessing_Exceptions(@BillingInvoiceDetailID INT = NULL)
AS
BEGIN
select	bide.ID as ExceptionID,
		ty.[Description] as [Type],
		st.[Description] as [Status],
		se.[Description] as Severity,
		bide.InvoiceDetailExceptionComment,
		CASE 
			WHEN ISNULL(bide.InvoiceDetailExceptionComment,'')= '' THEN NULL
			ELSE 'Yes'
		END as Comment
FROM	dbo.BillingInvoiceDetailException bide with (nolock)
left join	dbo.BillingInvoiceDetailExceptionType ty with (nolock) on ty.ID = bide.InvoiceDetailExceptionTypeID
left join	dbo.BillingInvoiceDetailExceptionStatus st with (nolock) on  st.ID = bide.InvoiceDetailExceptionStatusID
left join	dbo.BillingInvoiceDetailExceptionSeverity se with (nolock) on se.ID = bide.InvoiceDetailExceptionSeverityID
WHERE	bide.BillingInvoiceDetailID = @BillingInvoiceDetailID
END


