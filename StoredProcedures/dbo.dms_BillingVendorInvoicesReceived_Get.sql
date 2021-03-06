/****** Object:  StoredProcedure [dbo].[dms_BillingVendorInvoicesReceived_Get]    Script Date: 04/29/2014 02:13:21 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingVendorInvoicesReceived_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingVendorInvoicesReceived_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingVendorInvoicesReceived_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingVendorInvoicesReceived_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	09/01/13	MJKrzysiak	Created
 **	
 **	04/27/14	MJKrzysiak	^1 Changed the BaseAmount being selected
 **							from InvoiceAmount to PaymentAmount
 **
 **********************************************************************/

/**

-- For Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) (select ID from dbo.Program where Code = 'TRLRCARE')
exec dbo.dms_BillingVendorInvoicesReceived_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'


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
select * into #tmpViewData from dbo.vw_BillingVendorInvoices where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingVendorInvoices v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
--select	@SQLString = @SQLString + ' and v.ReceivedDate>= ''' + @RangeBeginDate + ''' '
select	@SQLString = @SQLString + ' and v.ReceivedDate<= ''' + @RangeEndDate + ''' '
select	@SQLString = @SQLString + ' and v.AccountingInvoiceBatchID is null ' -- Not Invoiced
select	@SQLString = @SQLString + ' and v.VendorInvoiceStatusID in ' -- Ready for Payment
select	@SQLString = @SQLString + ' (select ID from dbo.VendorInvoiceStatus '
select	@SQLString = @SQLString + ' where name in (''Received'', ''Ready For Payment'', ''Paid'')) ' 
select	@SQLString = @SQLString + ' and v.PaymentDate<= ''' + @RangeEndDate + ''' '


-- <<< NEED BILLLING STATUS TO CONTROL FLOW - Get all those where BillingStatus is not
-- select	@SQLString = @SQLString + 'and isnull(v.BillingStatus, '') = '''' <<< Turn this on when Data Available 

 
 
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
		EntityID,
		EntityKey,
		VendorInvoiceCreateDate as EntityDate,
		cast(1 as int)as BaseQuantity,
--		InvoiceAmount as BaseAmount,
		PaymentAmount as BaseAmount, -- ^1 
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData
GO
