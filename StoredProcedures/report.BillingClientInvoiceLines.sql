USE [DMS]
GO

/****** Object:  StoredProcedure [report].[BillingClientInvoiceLines]    Script Date: 04/18/2016 11:15:58 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[report].[BillingClientInvoiceLines]') AND type in (N'P', N'PC'))
DROP PROCEDURE [report].[BillingClientInvoiceLines]
GO

USE [DMS]
GO

/****** Object:  StoredProcedure [report].[BillingClientInvoiceLines]    Script Date: 04/18/2016 11:15:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [report].[BillingClientInvoiceLines]
	@InvoiceID int
AS

Select bil.ID  InvoiceLineID, bil.[Description] + ' - ' + rt.Name InvoiceLineDescription
From BillingInvoice bi with (nolock)
Join BillingInvoiceLine bil with (nolock) on bi.ID = bil.BillingInvoiceID
Join RateType rt on rt.ID = bil.RateTypeID
Where bi.ID = @InvoiceID

Union
Select NULL InvoiceLineID, '<All>' InvoiceLineDescription

GO

