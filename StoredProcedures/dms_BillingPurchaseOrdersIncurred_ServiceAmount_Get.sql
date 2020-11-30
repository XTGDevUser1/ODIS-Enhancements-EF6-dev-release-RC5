IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_BillingPurchaseOrdersIncurred_ServiceAmount_Get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_BillingPurchaseOrdersIncurred_ServiceAmount_Get]
GO

CREATE PROCEDURE [dbo].[dms_BillingPurchaseOrdersIncurred_ServiceAmount_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingPurchaseOrdersIncurred_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	05/14/13	MJKrzysiak	Created
 **	
 **
 ** ^1	12/31/2013	MJKrzysiak	Added IsActive to criteria
 **
 **********************************************************************/
/**

declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from Program where Code = 'HPN2TOW'
exec dbo.dms_BillingPurchaseOrdersIncurred_Get @ProgramIDs, '12/01/2013', '12/31/2013', '1=1'
--exec dbo.dms_BillingPurchaseOrdersIncurred_Get @ProgramIDs, '01/01/2013', '01/31/2013', '1=1'


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
ALTER TABLE #tmpViewData ADD ServiceAmount money 

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.*, '
select	@SQLString = @SQLString + 'case when v.VendorInvoicePaymentDate is not null '
select	@SQLString = @SQLString + '     and isnull(v.VendorInvoicePaymentAmount,0) > 0  '
select	@SQLString = @SQLString + '     then v.VendorInvoicePaymentAmount ' 
select	@SQLString = @SQLString + '     else v.PurchaseOrderAmount end ServiceAmount '
select	@SQLString = @SQLString + 'from dbo.vw_BillingServiceRequestsPurchaseOrders v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + 'and v.PASS_THRU = ''1'' ' -- PASS THRU
select	@SQLString = @SQLString + 'and v.PurchaseOrderDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_PurchaseOrder is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled
select	@SQLString = @SQLString + 'and v.PurchaseOrderStatus in '
select	@SQLString = @SQLString + ' (''Issued'', ''Issued-Paid'') ' -- Issued
select	@SQLString = @SQLString + 'and v.PurchaseOrderIsActive = 1' -- Must be Active, not flagged as a delete ^1
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_VendorInvoice is null ' -- Not Invoiced

 
-- Add additional Criteria
if @pEventFilter is not null
begin

	select	@SQLString = @SQLString + 'and ' + @pEventFilter

end


if @Debug = 1
begin

	select	'Programs', * from @pProgramIDs
	select	@pRangeBeginDate as pRangeBeginDate,
			@pRangeEndDate as pRangeEndDate,
			@RangeBeginDate as RangeBeginDate,
			@RangeEndDate as RangeEndDate,
			@pEventFilter as pEventFilter,
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
		EntityID_PurchaseOrder as EntityID,
		EntityKey_PurchaseOrder as EntityKey,
		PurchaseOrderDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		ServiceAmount as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData
GO

