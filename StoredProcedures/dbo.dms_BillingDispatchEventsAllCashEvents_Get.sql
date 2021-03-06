/****** Object:  StoredProcedure [dbo].[dms_BillingDispatchEventsAllCashEvents_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingDispatchEventsAllCashEvents_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingDispatchEventsAllCashEvents_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingDispatchEventsAllCashEvents_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingDispatchEventsAllCashEvents_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 ** ^1	12/31/2013	MJKrzysiak	Changed the Service Request Date to Purchase
 **								Order date in criteria
 **
 **********************************************************************/
/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code in 
('FORDCOMM_MFG', 'FORDCOMM_MFGR', 'FORD_MFG', 'FORD_MFGR')
exec dbo.dms_BillingDispatchEventsAllCashEvents_Get @ProgramIDs, '12/01/2013', '12/31/2013', '1=1'


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
--select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given ^1
select	@SQLString = @SQLString + 'and v.PurchaseOrderDate<= ''' + @RangeEndDate + '''' -- Within the Range given ^1
select	@SQLString = @SQLString + 'and v.DISPATCH = ''1''' -- Dispatch
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_PurchaseOrder is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled
select	@SQLString = @SQLString + 'and v.IsMemberPay = 1 ' -- Member Pay
--select	@SQLString = @SQLString + 'and v.IsOutOfWarranty = 1 ' -- Out-Of-Warranty <<< MJK - 10/22/13 - Removed per Kristen E.
select	@SQLString = @SQLString + 'and isnull(v.ServiceRequestCCPaymentsReceived, 0.00) = 0.00 ' -- No Credit Card
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
-- Get results columns for details
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
select	ProgramID,
		EntityID_PurchaseOrder as EntityID,
		EntityKey_PurchaseOrder as EntityKey,
		ServiceRequestDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData
GO
