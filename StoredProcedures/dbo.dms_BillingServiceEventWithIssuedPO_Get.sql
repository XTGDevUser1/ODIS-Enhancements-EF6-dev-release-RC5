USE [DMS]
GO

/****** Object:  StoredProcedure [dbo].[dms_BillingServiceEventWithIssuedPO_Get]    Script Date: 09/21/2016 12:04:31 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_BillingServiceEventWithIssuedPO_Get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_BillingServiceEventWithIssuedPO_Get]
GO

USE [DMS]
GO

/****** Object:  StoredProcedure [dbo].[dms_BillingServiceEventWithIssuedPO_Get]    Script Date: 09/21/2016 12:04:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[dms_BillingServiceEventWithIssuedPO_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType, @EventFilter as nvarchar(2000)
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where ClientID = 14
Set @EventFilter = 'v.VINModel IN (''F-650'',''F-750'') and v.VINModelYear IN (''2016'',''2017'') and v.PurchaseOrderDate >= ''1/1/2016'' and v.POPProductCategoryDescription = ''Tow'''
exec dbo.[dms_BillingServiceEventWithIssuedPO_Get] @ProgramIDs, '9/01/2016', '9/30/2016', @EventFilter

**/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Declare local variables
declare	@Debug as int,
		@RangeBeginDate as nvarchar(20),
		@RangeEndDate as nvarchar(20),
		@SQLString as nvarchar(max)


-- Initialize Local Variables
select	@Debug = 0
select	@SQLString = ''
select	@RangeBeginDate = convert(nvarchar(20), @pRangeBeginDate, 101),
		@RangeEndDate = convert(nvarchar(20), @pRangeEndDate, 101)


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Get ProgramIDs from Programs Table variable
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if object_id('tempdb..#tmpPrograms', 'U') is not null drop table #tmpPrograms
create table #tmpPrograms
(ProgramID	int)
create unique clustered index inx_tmpPrograms1 on #tmpPrograms(ProgramID)
insert into #tmpPrograms
(ProgramID)
select	ProgramID 
from	@pProgramIDs


if @Debug = 1
begin

	select	* from #tmpPrograms
	
end


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- THIS IS THE SQL THAT DEFINES THE EVENT!
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Build temp
if object_id('tempdb..#tmpViewData', 'U') is not null drop table #tmpViewData
select * into #tmpViewData from dbo.vw_BillingServiceRequestsPurchaseOrders where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingServiceRequestsPurchaseOrders v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + 'and v.PurchaseOrderDate <= ''' + @RangeEndDate + '''' -- Within the Range given ^1
--select	@SQLString = @SQLString + 'and v.PurchaseOrderDate >= ''9/1/2016''' -- Within the Range given ^1
select	@SQLString = @SQLString + 'and v.IsDispatched = 1 ' 
select	@SQLString = @SQLString + 'and v.GOAReason IS NULL ' 
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_PurchaseOrder is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_ServiceRequest is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled
select	@SQLString = @SQLString + 'and v.PurchaseOrderStatus in '
select	@SQLString = @SQLString + ' (''Issued'', ''Issued-Paid'') ' -- Issued
select	@SQLString = @SQLString + 'and v.PurchaseOrderIsActive = 1'


-- Add additional Criteria
if @pEventFilter is not null
begin

	select	@SQLString = @SQLString + 'and ' + @pEventFilter

end


if @Debug = 1
begin

	select	'Programs', * from @pProgramIDs
	select	@pEventFilter as pEventFilter,
			@SQLString as SQLString
end


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Execute SQL String to shove data into temp
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exec(@SQLString)


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Get results columns for detail
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
select	ProgramID,
		EntityID_ServiceRequest, 
		EntityKey_ServiceRequest,
		MIN(PurchaseOrderDate) as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		MAX(ServiceCode) ServiceCode,
		MAX(ServiceCode) as BillingCode
from	#tmpViewData
GROUP BY 
		ProgramID,
		EntityID_ServiceRequest, 
		EntityKey_ServiceRequest
		






GO

