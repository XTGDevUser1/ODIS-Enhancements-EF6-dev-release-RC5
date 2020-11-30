USE [DMS]
GO

/****** Object:  StoredProcedure [dbo].[dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get]    Script Date: 01/11/2017 11:39:42 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get]
GO

USE [DMS]
GO

/****** Object:  StoredProcedure [dbo].[dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get]    Script Date: 01/11/2017 11:39:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	08/07/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- FORD for Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'FORD'
exec dbo.dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get @ProgramIDs, '09/01/2015', '09/30/2015', '1=1'

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
--select * into #tmpViewData from dbo.vw_BillingPhoneSwitchCallDetail where 1=0


-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingServiceRequestsPurchaseOrders v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + 'and v.ServiceRequestDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.IsDispatched=0' -- No Dispatch
select	@SQLString = @SQLString + 'and v.IsTransferredCallToAgero = ''1''' -- Customer Assistance
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_ServiceRequest is null ' -- Not Invoiced
--select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
--select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled


---- Build SQL String for Select
--select	@SQLString = @SQLString + 'insert into #tmpViewData '
--select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingPhoneSwitchCallDetail v '
--select	@SQLString = @SQLString + 'join #tmpPrograms pr on pr.ProgramID = v.ProgramID '
--select	@SQLString = @SQLString + 'where 1=1 '
--select	@SQLString = @SQLString + 'and convert(date, v.startdatetime) >= ''' + @RangeBeginDate + '''' -- Within the Range given
--select	@SQLString = @SQLString + 'and convert(date, v.startdatetime) <= ''' + @RangeEndDate + '''' -- Within the Range given
--select	@SQLString = @SQLString + 'and v.destinationdn like ''%8886546136''' -- System Created

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
-- Get results columns for Detail
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
select	ProgramID,
		EntityID_ServiceRequest as EntityID,
		EntityKey_ServiceRequest as EntityKey,
		ServiceRequestDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData

--select	ProgramID,
--		EntityID, -- EntityID
--		EntityKey, -- EntityKey
--		startdatetime as EntityDate,
--		cast(1 as int)as BaseQuantity,
--		cast(null as float) as BaseAmount,
--		cast(null as float) as BasePercentage,
--		----		
--		cast(null as nvarchar(50)) as ServiceCode,
--		cast(null as nvarchar(50)) as BillingCode
--from	#tmpViewData


GO


