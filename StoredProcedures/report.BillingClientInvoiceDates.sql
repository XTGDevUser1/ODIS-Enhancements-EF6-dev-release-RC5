USE [DMS]
GO

/****** Object:  StoredProcedure [report].[BillingClientInvoiceDates]    Script Date: 04/18/2016 11:15:36 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[report].[BillingClientInvoiceDates]') AND type in (N'P', N'PC'))
DROP PROCEDURE [report].[BillingClientInvoiceDates]
GO

USE [DMS]
GO

/****** Object:  StoredProcedure [report].[BillingClientInvoiceDates]    Script Date: 04/18/2016 11:15:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [report].[BillingClientInvoiceDates]
	@ClientID int
AS
Select 
	bi.ClientID 
	,bst.Name BillingScheduleType
	,bi.ScheduleRangeBegin InvoiceBeginDate
	,bi.ScheduleRangeEnd InvoiceEndDate
	,bst.Name + '  ' + CONVERT(nvarchar(100),bi.ScheduleRangeBegin,101) + ' - ' + CONVERT(nvarchar(100),bi.ScheduleRangeEnd,101) InvoiceDateDescription 
From BillingInvoice bi with (nolock)
Join BillingSchedule bs with (nolock) on bs.ID = bi.BillingScheduleID
Join BillingScheduleType bst on bst.ID = bs.ScheduleTypeID
Where bi.ClientID = @ClientID
Group By 
	bi.ClientID 
	,bst.Name 
	,bi.ScheduleRangeBegin 
	,bi.ScheduleRangeEnd 
Order By bi.ScheduleRangeEnd desc

GO

