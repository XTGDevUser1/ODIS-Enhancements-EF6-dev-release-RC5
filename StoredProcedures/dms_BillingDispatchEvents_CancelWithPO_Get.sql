IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_BillingDispatchEvents_CancelWithPO_Get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_BillingDispatchEvents_CancelWithPO_Get]
GO
CREATE PROCEDURE [dbo].[dms_BillingDispatchEvents_CancelWithPO_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingDispatchEventsWithOutCancels_Get
 **
 **	#	Date		Added By	Description
 **	---	----------	----------	----------------------------------------
 **		12/31/13	MJKrzysiak	Created
 **	
 ** CHANGE LOG:
 ** 
 **
 **********************************************************************/

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'HPN2TOW'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingDispatchEventsWithOutCancels_Get @ProgramIDs, '12/01/2013', '12/31/2013', '1=1'

select *
from	vw_BillingServiceRequestsPurchaseOrders
where	1=1
and		ServiceRequestDate >= '06/01/2013'
and		ServiceRequestDate <= '06/30/2013'
and		ProgramID in (select ID from dbo.Program where Code = 'TRLRCARE')

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
select	@SQLString = @SQLString + 'and v.PurchaseOrderDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DISPATCH = ''1'' ' -- Dispatch intended
select	@SQLString = @SQLString + 'and v.IsDispatched = 1 ' -- Dispatched PO
select	@SQLString = @SQLString + 'and v.IsGOA = 0 ' -- Exclude GOA POs
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_ServiceRequest is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_PurchaseOrder is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled
select	@SQLString = @SQLString + 'and v.PurchaseOrderStatus in '
select	@SQLString = @SQLString + ' (''Cancelled'') ' -- Cancelled
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
		coalesce(EntityID_PurchaseOrder, EntityID_ServiceRequest), -- If PO then use, else SR
		coalesce(EntityKey_PurchaseOrder, EntityKey_ServiceRequest),
		coalesce(PurchaseOrderDate, ServiceRequestDate) as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData
GO

