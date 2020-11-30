/****** Object:  StoredProcedure [dbo].[dms_BillingAdditionalServicePassThru_Get]    Script Date: 09/28/2015 12:26:05 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_BillingAdditionalServicePassThru_Get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_BillingAdditionalServicePassThru_Get]
GO

/****** Object:  StoredProcedure [dbo].[dms_BillingAdditionalServicePassThru_Get]    Script Date: 09/28/2015 12:26:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[dms_BillingAdditionalServicePassThru_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'HPN2TOW'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.[dms_BillingAdditionalServicePassThru_Get] @ProgramIDs, '12/01/2013', '12/31/2013', 'ServiceCode='Customer Payout'

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
select * into #tmpViewData from dbo.vw_BillingPurchaseOrderAdditionalService where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingPurchaseOrderAdditionalService v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + 'and v.PurchaseOrderDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID is null ' -- Not Invoiced ^1
select	@SQLString = @SQLString + 'and v.PurchaseOrderStatus in ' -- ^3
select	@SQLString = @SQLString + ' (''Issued'', ''Issued-Paid'') ' -- Issued ^3


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
		EntityID_PurchaseOrder as EntityID,
		EntityKey_PurchaseOrder as EntityKey,
		PurchaseOrderDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(Amount as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData



GO


