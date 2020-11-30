USE [DMS]
GO

/****** Object:  StoredProcedure [report].[BillingClientInvoices]    Script Date: 04/18/2016 11:16:18 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[report].[BillingClientInvoices]') AND type in (N'P', N'PC'))
DROP PROCEDURE [report].[BillingClientInvoices]
GO

USE [DMS]
GO

/****** Object:  StoredProcedure [report].[BillingClientInvoices]    Script Date: 04/18/2016 11:16:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--Exec [Report].[BillingClientInvoices] 18, '9/1/2015'
CREATE PROCEDURE [report].[BillingClientInvoices]
	@ClientID int
	,@InvoiceBeginDate datetime
AS
Select
	bi.ID InvoiceID
	,bi.Name InvoiceDescription
	,bst.Name + '  ' + CONVERT(nvarchar(100),bi.ScheduleRangeBegin,101) + ' - ' + CONVERT(nvarchar(100),bi.ScheduleRangeEnd,101) InvoiceDateDescription 
from BillingInvoice bi with (nolock)
Join BillingSchedule bs with (nolock) on bs.ID = bi.BillingScheduleID
Join BillingScheduleType bst on bst.ID = bs.ScheduleTypeID
Where bi.ClientID = @ClientID
and bi.ScheduleRangeBegin = @InvoiceBeginDate
Union
Select TOP 1 NULL InvoiceID
	,'<All>' InvoiceDescription
	,bst.Name + '  ' + CONVERT(nvarchar(100),bi.ScheduleRangeBegin,101) + ' - ' + CONVERT(nvarchar(100),bi.ScheduleRangeEnd,101) InvoiceDateDescription 
from BillingInvoice bi with (nolock)
Join BillingSchedule bs with (nolock) on bs.ID = bi.BillingScheduleID
Join BillingScheduleType bst on bst.ID = bs.ScheduleTypeID
Where bi.ClientID = @ClientID
and bi.ScheduleRangeBegin = @InvoiceBeginDate
Order By InvoiceDescription

GO

