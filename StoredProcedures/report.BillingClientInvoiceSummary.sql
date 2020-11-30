USE [DMS]
GO

/****** Object:  StoredProcedure [report].[BillingClientInvoiceSummary]    Script Date: 04/26/2016 07:04:18 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[report].[BillingClientInvoiceSummary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [report].[BillingClientInvoiceSummary]
GO

USE [DMS]
GO

/****** Object:  StoredProcedure [report].[BillingClientInvoiceSummary]    Script Date: 04/26/2016 07:04:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [report].[BillingClientInvoiceSummary]
	@pBillingInvoiceID as int
as


/***

select	distinct bil.BillingInvoiceID,
		bid.Sequence
from	dbo.BillingInvoiceDetail bid
join	dbo.BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID

exec Report.[BillingClientInvoiceSummary] 17 -- @pBillingInvoiceID

***/


select	bi.ID as BillingInvoiceID,
		bi.Name,
		bi.[Description],
		bi.AccountingSystemAddressCode,
		bi.POPrefix,
		bi.PONumber,
		ity.Name as InvoiceType,
		ite.Name as InvoiceTemplate,
		bi.InvoiceDate,
		bi.ScheduleDate,
		bi.ScheduleRangeBegin,
		bi.ScheduleRangeEnd,
		bi.BillingDefinitionInvoiceID,
		bi.CanAddLines,
		bis.Name as InvoiceStatus,
		bi.AccountingSystemCustomerNumber MAS90Cust,
		---- Invoice Lines ---
		bil.ID BillingInvoiceLineID,
		bil.BillingDefinitionInvoiceLineID,
		bil.Sequence,
		bil.Name as InvoiceLineName,
		bil.[Description] as InvoiceLineDescription,
		bil.Comment,
		bil.LineQuantity,
		bil.LineCost,
		bil.LineAmount,
		bil.ProductID,
		pr.Name as ProductName,
		bil.AccountingSystemItemCode,
		bil.AccountingSystemGLCode,
		bils.Name as LineStatus,
		cast(bi.InvoiceNumber as nvarchar(10)) as InvoiceNumber,
		cl.ID as ClientID
from	dbo.BillingInvoice bi
left outer join	dbo.BillingInvoiceLine bil with (nolock) on bil.BillingInvoiceID = bi.ID
left outer join	dbo.BillingInvoiceType ity with (nolock)on ity.ID = bi.InvoiceTypeID
left outer join	dbo.BillingInvoiceTemplate ite with (nolock)on ite.ID = bi.InvoiceTemplateID
left outer join	dbo.BillingScheduleRangeType rt with (nolock)on rt.ID = bi.ScheduleRangeTypeID
left outer join dbo.Product pr with (nolock)on pr.ID = bil.ProductID
left outer join	dbo.BillingInvoiceStatus bis with (nolock) on bis.ID = bi.InvoiceStatusID
left outer join	dbo.BillingInvoiceLineStatus bils with (nolock)on bils.ID = bil.InvoiceLineStatusID
left outer join dbo.Client cl with (nolock)on cl.ID = bi.ClientID
where	1=1
and		bi.ID = isnull(@pBillingInvoiceID, bi.ID)
order by
	BillingInvoiceID,
	Sequence




GO

