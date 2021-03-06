/****** Object:  StoredProcedure [dbo].[Address_InsertUpdate]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Address_InsertUpdate]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Address_InsertUpdate] 
 END 
 GO  

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--******************************************************************************************
--******************************************************************************************
--
--******************************************************************************************
--******************************************************************************************

CREATE PROCEDURE [dbo].[Address_InsertUpdate]
			(
				@pEntityID int,
				@pAddresstype varchar(15),
				@pLine1 varchar(100) = NULL,
				@pLine2 varchar(100) = NULL,
				@pLine3 varchar(100) = NULL,
				@pCity varchar(100) = NULL,
				@pStateProvince varchar(10) = NULL,
				@pPostalCode varchar(20) = NULL,
				@pStateProvinceID int = NULL,
				@pCountryID int = NULL,
				@pCountryCode varchar(2) = NULL,
				@pClientMemberKey varchar(50),
				@pCreateBatchID	int = NULL,
				@pCreateDate datetime = NULL,
				@pCreateBy varchar(50) = NULL,
				@pModifyBatchID	int = NULL,
				@pModifyDate datetime = NULL,
				@pModifyBy varchar(50) = NULL
			)
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT OFF

declare @RecordID as int
declare @AddressTypeID as int

if @pEntityID = 5 
begin 
	SELECT @RecordID = m.ID  
				FROM dbo.Member m with(nolock)
				where 1=1
					and m.ClientMemberKey = @pClientmemberKey
End

if @pEntityID = 6 
begin 
	SELECT @RecordID = ms.ID  
				FROM dbo.Member m with(nolock)
				join dbo.Membership ms with(nolock) on m.MembershipID = ms.id
				where 1=1
					and m.ClientMemberKey = @pClientmemberKey
End

SELECT @AddressTypeID = [ID]
			FROM dbo.AddressType ad with(nolock)
			Where 1=1
				and ad.IsActive = 1
				and ad.Name = @pAddresstype


   MERGE [dbo].[AddressEntity] AS target
    USING (select
				@pEntityID, 
				@RecordID,
				@AddressTypeID,
				@pLine1,
				@pLine2,
				@pLine3,
				@pCity,
				@pStateProvince,
				@pPostalCode,
				@pStateProvinceID,
				@pCountryID,
				@pCountryCode,
				@pCreateBatchID,
				@pCreateDate,
				@pCreateBy,
				@pModifyBatchID,
				@pModifyDate,
				@pModifyBy
			)
			as source( 
				[EntityID], 
				[RecordID],
				[AddressTypeID],
				[Line1],
				[Line2],
				[Line3],
				[City],
				[StateProvince],
				[PostalCode],
				[StateProvinceID],
				[CountryID],
				[CountryCode],
				[CreateBatchID],
				[CreateDate],
				[CreateBy],
				[ModifyBatchID],
				[ModifyDate],
				[ModifyBy]
           )
    ON (target.RecordID = source.RecordID
		AND target.EntityID = source.EntityID
		)
    
    WHEN MATCHED THEN 
        UPDATE SET 
				Line1 = source.Line1,
				Line2 = source.Line2,
				Line3 = source.Line3,
				City = source.City,
				StateProvince = source.StateProvince,
				PostalCode = source.PostalCode,
				StateProvinceID = source.StateProvinceID,
				CountryID = source.CountryID,
				CountryCode = source.CountryCode,
				ModifyBatchID = source.ModifyBatchid,
				ModifyDate = source.ModifyDate,
				ModifyBy = source.ModifyBy
	WHEN NOT MATCHED THEN	
	    INSERT	(
				[EntityID], 
				[RecordID],
				[AddressTypeID],
				[Line1],
				[Line2],
				[Line3],
				[City],
				[StateProvince],
				[PostalCode],
				[StateProvinceID],
				[CountryID],
				[CountryCode],
				[CreateBatchID],
				[CreateDate],
				[CreateBy]
				)
	    VALUES (
				source.[EntityID], 
				source.[RecordID],
				source.[AddressTypeID],
				source.[Line1],
				source.[Line2],
				source.[Line3],
				source.[City],
				source.[StateProvince],
				source.[PostalCode],
				source.[StateProvinceID],
				source.[CountryID],
				source.[CountryCode],
				source.[CreateBatchID],
				source.[CreateDate],
				source.[CreateBy]
           );
GO

/****** Object:  UserDefinedTableType [dbo].[BillingDefinitionInvoiceLineEventsTableType]    Script Date: 04/29/2014 02:13:26 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[BillingDefinitionInvoiceLineEventsTableType]')   		AND type in (N'P', N'PC')) 
 BEGIN
DROP TYPE [dbo].[BillingDefinitionInvoiceLineEventsTableType]
CREATE TYPE [dbo].[BillingDefinitionInvoiceLineEventsTableType] AS TABLE(
	[BillingDefinitionInvoiceID] [int] NULL,
	[BillingDefinitionInvoiceLineID] [int] NULL,
	[BillingDefinitionInvoiceLineEventID] [int] NULL
)
END
GO

/****** Object:  UserDefinedTableType [dbo].[BillingDefinitionInvoiceTableType]    Script Date: 04/29/2014 02:13:26 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[BillingDefinitionInvoiceTableType]')   		AND type in (N'P', N'PC')) 
 BEGIN
DROP TYPE [dbo].[BillingDefinitionInvoiceTableType]

CREATE TYPE [dbo].[BillingDefinitionInvoiceTableType] AS TABLE(
	[BillingDefinitionInvoiceID] [int] NULL
)
END
GO

/****** Object:  UserDefinedTableType [dbo].[BillingDefinitionProgramsTableType]    Script Date: 04/29/2014 02:13:26 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[BillingDefinitionProgramsTableType]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP TYPE [dbo].[BillingDefinitionProgramsTableType]

CREATE TYPE [dbo].[BillingDefinitionProgramsTableType] AS TABLE(
	[ProgramID] [int] NULL
)
END
GO
/****** Object:  UserDefinedTableType [dbo].[BillingInvoiceTableType]    Script Date: 04/29/2014 02:13:26 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[BillingInvoiceTableType]')   		AND type in (N'P', N'PC')) 
 BEGIN
DROP TYPE [dbo].[BillingInvoiceTableType]

CREATE TYPE [dbo].[BillingInvoiceTableType] AS TABLE(
	[BillingInvoiceID] [int] NULL
)
END
GO


GO
/****** Object:  StoredProcedure [dbo].[dms_BillingActiveMembers_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingActiveMembers_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingActiveMembers_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingActiveMembers_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingActiveMembers_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	05/14/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- HRZCARD for testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where code = 'HRZCARD'
exec dbo.dms_BillingActiveMembers_Get @ProgramIDs, '04/01/2013', '04/30/2013', '1=1'

-- FORD for Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where clientid = 14
exec dbo.dms_BillingActiveMembers_Get @ProgramIDs, '04/01/2013', '04/30/2013', 'VINModelYear=''2010'''

-- FORD for Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'FORDESP_MFG'
exec dbo.dms_BillingActiveMembers_Get @ProgramIDs, '09/01/2013', '09/30/2013', '1=1'


-- Queries to help in testing
select	mbr.*
from	Member mbr
join	Program pr on pr.ID = mbr.ProgramID
where	pr.Code = 'HRZCARD'
order by
		mbr.ExpirationDate desc

--begin tran
--update	Member
--set		ExpirationDate = '06/10/2020'
--where id in( 1987537, 1987555, 1987562)
----commit tran


**/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Declare local variables
declare	@Debug as int,
		@SQLString as nvarchar(max),
		@RangeBeginDate_CHAR as nvarchar(20),
		@RangeEndDate_CHAR as nvarchar(20)


-- Initialize Local Variables
select	@Debug = 0
select	@SQLString = ''
select	@RangeBeginDate_CHAR = convert(nvarchar(20), @pRangeBeginDate),
		@RangeEndDate_CHAR = convert(nvarchar(20), @pRangeEndDate)


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
select * into #tmpViewData from dbo.vw_BillingMembers where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingMembers v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + ' and convert(date, v.DMSMemberCreateDate) <= ''' + @RangeEndDate_CHAR + ''' ' -- Created on or before the CutOffDate
select	@SQLString = @SQLString + ' and v.MemberSinceDate <= ''' + @RangeEndDate_CHAR + ''' ' -- MemberSince on or before the CutOff
select	@SQLString = @SQLString + ' and v.ExpirationDate >= ''' + @RangeEndDate_CHAR + ''' ' -- Expiration Date on or after the CutOff
select	@SQLString = @SQLString + ' and isnull(v.BeginDate, ''01/01/1900'') <= ''' + @RangeEndDate_CHAR + ''' ' -- Beg Date on the Record on or before the CutOffDate
select	@SQLString = @SQLString + ' and isnull(v.EndDate, ''12/31/2099'') >= ''' + @RangeEndDate_CHAR + ''' ' -- End Date on the Record on or after the CutOffDate


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
select	distinct
		ProgramID,
		EntityID,
		EntityKey,
		ExpirationDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		----
		cast(null as nvarchar(50)) as ServiceCode,
		cast(null as nvarchar(50)) as BillingCode
from	#tmpViewData
GO

GO
/****** Object:  StoredProcedure [dbo].[dms_BillingAdministationFeeFlat_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingAdministationFeeFlat_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingAdministationFeeFlat_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingAdministationFeeFlat_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingAdministationFeeFlat_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	08/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- HRZCARD for testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where code = 'HRZCARD'
exec dbo.dms_BillingAdministationFeeFlat_Get @ProgramIDs, '04/01/2013', '04/30/2013', '1=1'


**/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Declare local variables
declare	@Debug as int,
		@SQLString as nvarchar(max),
		@RangeBeginDate_CHAR as nvarchar(20),
		@RangeEndDate_CHAR as nvarchar(20)


-- Initialize Local Variables
select	@Debug = 0
select	@SQLString = ''


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

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Get an Admin Fee
-- Include: BaseQuantity = 1
--			BaseAmount = null
--			BasePercentage = null	
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
select	ProgramID,
		ProgramID as EntityID,
		(select ID from dbo.Entity with (nolock) where Name = 'BillingProgram') as EntityKey,
		@pRangeEndDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		cast(null as nvarchar(50)) as ServiceCode,
		cast(null as nvarchar(50)) as BillingCode
from	#tmpPrograms
GO


GO
/****** Object:  StoredProcedure [dbo].[dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get] 
 END 
 GO  
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
exec dbo.dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'

-- Queries to help in testing
select	*
from	[DatamartServer].cn_datamart.dbo.vwstellarcontactcalldetail with (nolock)
where	destinationdn like ('%8886546136')
and		convert(date, startdatetime) >= '10/01/2013'
and		convert(date, startdatetime) <= '10/31/2013'

select	*
from	dbo.vw_BillingPhoneSwitchCallDetail with (nolock)
where	destinationdn like ('%8886546136')
and		convert(date, startdatetime) >= '10/01/2013'
and		convert(date, startdatetime) <= '10/31/2013'

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
select * into #tmpViewData from dbo.vw_BillingPhoneSwitchCallDetail where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingPhoneSwitchCallDetail v '
select	@SQLString = @SQLString + 'join #tmpPrograms pr on pr.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + 'and convert(date, v.startdatetime) >= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and convert(date, v.startdatetime) <= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.destinationdn like ''%8886546136''' -- System Created

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
		EntityID, -- EntityID
		EntityKey, -- EntityKey
		startdatetime as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		----		
		cast(null as nvarchar(50)) as ServiceCode,
		cast(null as nvarchar(50)) as BillingCode
from	#tmpViewData
GO
/****** Object:  StoredProcedure [dbo].[dms_BillingClaimsPaidRoadsideReimbursement_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingClaimsPaidRoadsideReimbursement_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingClaimsPaidRoadsideReimbursement_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingClaimsPaidRoadsideReimbursement_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingClaimsPaidRoadsideReimbursement_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	10/18/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**

-- For Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) (select ID from dbo.Program where Code = 'FORDCOMM_MFG')
exec dbo.dms_BillingClaimsPaidRoadsideReimbursement_Get @ProgramIDs, '09/01/2013', '09/30/2013', '1=1'


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
select * into #tmpViewData from dbo.vw_BillingClaims where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingClaims v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + ' and v.ReceivedDate<= ''' + @RangeEndDate + ''' '
select	@SQLString = @SQLString + ' and cast(v.PaymentDate as Date)<= ''' + @RangeEndDate + ''' '
select	@SQLString = @SQLString + ' and v.PassThruAccountingInvoiceBatchID is null ' -- Not Invoiced
select	@SQLString = @SQLString + ' and v.ClaimStatusID in ' -- Final states - Paid or Rejected
select	@SQLString = @SQLString + ' (select ID from dbo.ClaimStatus '
select	@SQLString = @SQLString + ' where name in (''Paid'', ''Rejected'')) ' 
select	@SQLString = @SQLString + ' and v.ClaimTypeID in ' -- Final states - Paid or Rejected
select	@SQLString = @SQLString + ' (select ID from dbo.ClaimType '
select	@SQLString = @SQLString + ' where name = ''RoadsideReimbursement'') ' 

 
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
		ReceivedDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		PaymentAmount as BaseAmount,
		cast(null as float) as BasePercentage,
		null as ServiceCode,
		null as BillingCode
from	#tmpViewData




GO
/****** Object:  StoredProcedure [dbo].[dms_BillingClaimsPaid_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingClaimsPaid_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingClaimsPaid_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingClaimsPaid_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingClaimsPaid_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	09/13/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**

-- For Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) (select ID from dbo.Program where Code = 'FORDESP_MFG')
exec dbo.dms_BillingClaimsPaid_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'


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
select * into #tmpViewData from dbo.vw_BillingClaims where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingClaims v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
--select	@SQLString = @SQLString + ' and v.ReceivedDate>= ''' + @RangeBeginDate + ''' '
select	@SQLString = @SQLString + ' and v.ReceivedDate<= ''' + @RangeEndDate + ''' '
select	@SQLString = @SQLString + ' and cast(v.PaymentDate as Date)<= ''' + @RangeEndDate + ''' '
select	@SQLString = @SQLString + ' and v.PassThruAccountingInvoiceBatchID is null ' -- Not Invoiced
select	@SQLString = @SQLString + ' and v.ClaimStatusID in ' -- Final states - Paid or Rejected
select	@SQLString = @SQLString + ' (select ID from dbo.ClaimStatus '
select	@SQLString = @SQLString + ' where name in (''Paid'', ''Rejected'')) ' 

 
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
		ReceivedDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		PaymentAmount as BaseAmount,
		cast(null as float) as BasePercentage,
		null as ServiceCode,
		null as BillingCode
from	#tmpViewData
GO

GO

GO
/****** Object:  StoredProcedure [dbo].[dms_BillingClaimsProcessedRoadsideReimbursement_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingClaimsProcessedRoadsideReimbursement_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingClaimsProcessedRoadsideReimbursement_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingClaimsProcessedRoadsideReimbursement_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingClaimsProcessedRoadsideReimbursement_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	11/06/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**

-- For Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) (select ID from dbo.Program where Code = 'FORDESP_MFG')
exec dbo.dms_BillingClaimsProcessedRoadsideReimbursement_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'


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
select * into #tmpViewData from dbo.vw_BillingClaims where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingClaims v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + ' and convert(date, v.ReceivedDate)<= ''' + @RangeEndDate + ''' '
select	@SQLString = @SQLString + ' and v.FeeAccountingInvoiceBatchID is null ' -- Not Invoiced
select	@SQLString = @SQLString + ' and v.ClaimTypeID in ' -- RS Reimb
select	@SQLString = @SQLString + ' (select ID from dbo.ClaimType '
select	@SQLString = @SQLString + ' where name = ''RoadsideReimbursement'') ' 

 
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
		ReceivedDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		PaymentAmount as BaseAmount,
		cast(null as float) as BasePercentage,
		null as ServiceCode,
		null as BillingCode
from	#tmpViewData
GO

GO

GO
/****** Object:  StoredProcedure [dbo].[dms_BillingClaimsProcessed_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingClaimsProcessed_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingClaimsProcessed_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingClaimsProcessed_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingClaimsProcessed_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	09/13/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**

-- For Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) (select ID from dbo.Program where Code = 'FORDESP_MFG')
exec dbo.dms_BillingClaimsProcessed_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'


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
select * into #tmpViewData from dbo.vw_BillingClaims where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingClaims v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
--select	@SQLString = @SQLString + ' and v.ReceivedDate>= ''' + @RangeBeginDate + ''' '
select	@SQLString = @SQLString + ' and v.ReceivedDate<= ''' + @RangeEndDate + ''' '
select	@SQLString = @SQLString + ' and v.FeeAccountingInvoiceBatchID is null ' -- Not Invoiced

 
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
		ReceivedDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		PaymentAmount as BaseAmount,
		cast(null as float) as BasePercentage,
		null as ServiceCode,
		null as BillingCode
from	#tmpViewData
GO




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
/****** Object:  StoredProcedure [dbo].[dms_BillingDispatchEventsAllManuallyCreated_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingDispatchEventsAllManuallyCreated_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingDispatchEventsAllManuallyCreated_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingDispatchEventsAllManuallyCreated_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingDispatchEventsAllManuallyCreated_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 ** CHANGE LOG:
 ** 
 ** ^1	12/31/2013	MJKrzysiak	Changed the Service Request Date to Purchase
 **								Order date in criteria
 **
 **********************************************************************/
/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'TRLRCARE'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingDispatchEventsAllManuallyCreated_Get @ProgramIDs, '12/01/2013', '12/31/2013', '1=1'

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
--select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given ^1
select	@SQLString = @SQLString + 'and v.PurchaseOrderDate<= ''' + @RangeEndDate + '''' -- Within the Range given ^1
select	@SQLString = @SQLString + 'and v.DISPATCH = ''1''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.IsMbrManuallyCreated = ''1''' -- Mbr not system created
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_PurchaseOrder is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled
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
/****** Object:  StoredProcedure [dbo].[dms_BillingDispatchEventsAll_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingDispatchEventsAll_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingDispatchEventsAll_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingDispatchEventsAll_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingDispatchEventsAll_Get
 **
 **	#	Date		Added By	Description
 **	---	----------	----------	----------------------------------------
 **		07/31/13	MJKrzysiak	Created
 **	
 ** CHANGE LOG:
 ** 
 ** ^1	12/31/2013	MJKrzysiak	Changed the Service Request Date to Purchase
 **								Order date in criteria
 **
 **********************************************************************/

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'HPN2TOW'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingDispatchEventsAll_Get @ProgramIDs, '12/01/2013', '12/31/2013', '1=1'

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
--select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given ^1
select	@SQLString = @SQLString + 'and v.PurchaseOrderDate<= ''' + @RangeEndDate + '''' -- Within the Range given ^1
select	@SQLString = @SQLString + 'and v.DISPATCH = ''1'' ' -- Within the Range given
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_PurchaseOrder is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled
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
/****** Object:  StoredProcedure [dbo].[dms_BillingDispatchEventsSystemCreated_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingDispatchEventsSystemCreated_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingDispatchEventsSystemCreated_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingDispatchEventsSystemCreated_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingDispatchEventsSystemCreated_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 ** CHANGE LOG:
 ** 
 ** ^1	12/31/2013	MJKrzysiak	Changed the Service Request Date to Purchase
 **								Order date in criteria
 **
 **********************************************************************/
/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'TRLRCARE'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingDispatchEventsSystemCreated_Get @ProgramIDs, '12/01/2013', '12/30/2013', '1=1'

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
--select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given ^1
select	@SQLString = @SQLString + 'and v.PurchaseOrderDate<= ''' + @RangeEndDate + '''' -- Within the Range given ^1
select	@SQLString = @SQLString + 'and v.DISPATCH = ''1''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.IsMbrManuallyCreated <> ''1''' -- Mbr manually created
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_PurchaseOrder is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled
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

GO
/****** Object:  StoredProcedure [dbo].[dms_BillingDispatchEventsWithOutCancels_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingDispatchEventsWithOutCancels_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingDispatchEventsWithOutCancels_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingDispatchEventsWithOutCancels_Get]
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
select	@SQLString = @SQLString + 'and v.DISPATCH = ''1'' ' -- Within the Range given
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_PurchaseOrder is null ' -- Not Invoiced
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
/****** Object:  StoredProcedure [dbo].[dms_BillingFixedAmountQuantityAndRate_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingFixedAmountQuantityAndRate_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingFixedAmountQuantityAndRate_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingFixedAmountQuantityAndRate_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingFixedAmountQuantityAndRate_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	08/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- HRZCARD for testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where code = 'HRZCARD'
exec dbo.dms_BillingFixedAmountQuantityAndRate_Get @ProgramIDs, '04/01/2013', '04/30/2013', '1=1'


**/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Declare local variables
declare	@Debug as int,
		@SQLString as nvarchar(max),
		@RangeBeginDate_CHAR as nvarchar(20),
		@RangeEndDate_CHAR as nvarchar(20)


-- Initialize Local Variables
select	@Debug = 0
select	@SQLString = ''


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

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Fixed Amount
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
select	ProgramID,
		ProgramID as EntityID,
		(select ID from dbo.Entity with (nolock) where Name = 'BillingProgram') as EntityKey,
		@pRangeEndDate as EntityDate,
		cast(null as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		cast(null as nvarchar(50)) as ServiceCode,
		cast(null as nvarchar(50)) as BillingCode
from	#tmpPrograms




GO
/****** Object:  StoredProcedure [dbo].[dms_BillingImpoundRelease_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingImpoundRelease_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingImpoundRelease_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingImpoundRelease_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingImpoundRelease_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 ** ^1	12/31/2013	MJKrzysiak	Changed the Service Request batch id
 **								to Purchase Order batch ID in criteria
 **
 ** ^2	12/31/2013	MJKrzysiak	Removed the begin date criteria...should
 **								not be in there.
 **
 ** ^3	12/31/2013	MJKrzysiak	Added criteria to match the Dispatch Fee
 **								billing event.
 **********************************************************************/
/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'HPN2TOW'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingImpoundRelease_Get @ProgramIDs, '12/01/2013', '12/31/2013', '1=1'

select	* from vw_BillingServiceRequestsPurchaseOrders
where	1=1
and		ProgramCode = 'HPN2TOW'
and		ServiceRequestDate >= '06/01/2013'
and		ServiceRequestDate <= '06/30/2013'

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
--select	@SQLString = @SQLString + 'and v.PurchaseOrderDate>= ''' + @RangeBeginDate + '''' -- Within the Range given ^2
select	@SQLString = @SQLString + 'and v.PurchaseOrderDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.IsImpoundRelease = ''1''' -- Impound Release
--select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_ServiceRequest is null ' -- Not Invoiced ^1
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_PurchaseOrder is null ' -- Not Invoiced ^1
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled
select	@SQLString = @SQLString + 'and v.PurchaseOrderStatus in ' -- ^3
select	@SQLString = @SQLString + ' (''Issued'', ''Issued-Paid'') ' -- Issued ^3
select	@SQLString = @SQLString + 'and v.PurchaseOrderIsActive = 1' -- ^3


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
		cast(PurchaseOrderAmount as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData


GO

GO
/****** Object:  StoredProcedure [dbo].[dms_BillingIncomingCallsMotorHomeCACLineFORD_MFG_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingIncomingCallsMotorHomeCACLineFORD_MFG_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingIncomingCallsMotorHomeCACLineFORD_MFG_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingIncomingCallsMotorHomeCACLineFORD_MFG_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingIncomingCallsMotorHomeCACLineFORD_MFG_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	09/01/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- FORD for Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where ClientID = 14
exec dbo.dms_BillingIncomingCallsMotorHomeCACLineFORD_MFG_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'

-- Queries to help in testing
select	*
from	dbo.vw_BillingPhoneCallMetricsIncomingCalls with (nolock)
where	ProgramID in (select ID from dbo.Program where ClientID = 14)
and		convert(date, startdatetimeADJ) >= '06/01/2013'
and		convert(date, startdatetimeADJ) <= '06/30/2013'

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
select * into #tmpViewData from dbo.vw_BillingPhoneCallMetricsIncomingCalls where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingPhoneCallMetricsIncomingCalls v '
select	@SQLString = @SQLString + 'join #tmpPrograms pr on pr.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + ' and client = ''FORD'' ' -- FORD Client
select	@SQLString = @SQLString + ' and subclient = ''Motor Home CAC'' ' -- Sub Client  Motor Home CAC only
select	@SQLString = @SQLString + ' and origcallednumber in (''2164'', ''2220'', ''2170'') ' -- Line #
select	@SQLString = @SQLString + ' and convert(date, v.startdatetimeADJ) >= ''' + @RangeBeginDate + ''' ' -- Within the Range given
select	@SQLString = @SQLString + ' and convert(date, v.startdatetimeADJ) <= ''' + @RangeEndDate + ''' ' -- Within the Range given


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
		EntityID, -- EntityID
		EntityKey, -- EntityKey
		startdatetime as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		cast(null as nvarchar(50)) as ServiceCode,
		cast(null as nvarchar(50)) as BillingCode
from	#tmpViewData
GO

GO
/****** Object:  StoredProcedure [dbo].[dms_BillingIncomingCallsRecallLineFORD_MFG_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingIncomingCallsRecallLineFORD_MFG_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingIncomingCallsRecallLineFORD_MFG_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingIncomingCallsRecallLineFORD_MFG_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingIncomingCallsRecallLineFORD_MFG_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	09/01/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- FORD for Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where ClientID = 14
exec dbo.dms_BillingIncomingCallsRecallLineFORD_MFG_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'

-- Queries to help in testing
select	*
from	dbo.vw_BillingPhoneCallMetricsIncomingCalls with (nolock)
where	ProgramID in (select ID from dbo.Program where ClientID = 14)
and		convert(date, startdatetimeADJ) >= '06/01/2013'
and		convert(date, startdatetimeADJ) <= '06/30/2013'

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
select * into #tmpViewData from dbo.vw_BillingPhoneCallMetricsIncomingCalls where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingPhoneCallMetricsIncomingCalls v '
select	@SQLString = @SQLString + 'join #tmpPrograms pr on pr.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + ' and client = ''FORD'' ' -- FORD Client
select	@SQLString = @SQLString + ' and subclient = ''Recall'' ' -- Sub Client Recall only
select	@SQLString = @SQLString + ' and origcallednumber in (''2164'', ''2220'', ''2170'') ' -- Line #
select	@SQLString = @SQLString + ' and convert(date, v.startdatetimeADJ) >= ''' + @RangeBeginDate + ''' ' -- Within the Range given
select	@SQLString = @SQLString + ' and convert(date, v.startdatetimeADJ) <= ''' + @RangeEndDate + ''' ' -- Within the Range given


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
		EntityID, -- EntityID
		EntityKey, -- EntityKey
		startdatetime as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		cast(null as nvarchar(50)) as ServiceCode,
		cast(null as nvarchar(50)) as BillingCode
from	#tmpViewData
GO

GO
/****** Object:  StoredProcedure [dbo].[dms_BillingIncomingCallsTransportLineFORDTRNS_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingIncomingCallsTransportLineFORDTRNS_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingIncomingCallsTransportLineFORDTRNS_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingIncomingCallsTransportLineFORDTRNS_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingIncomingCallsTransportLineFORDTRNS_Get
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
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'FORDTRNS'
exec dbo.dms_BillingIncomingCallsTransportLineFORDTRNS_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'

-- Queries to help in testing
select	*
from	dbo.vw_BillingPhoneCallMetricsIncomingCalls with (nolock)
where	ProgramID = (select ID from dbo.Program where Code = 'FORDTRNS')
and		convert(date, startdatetimeADJ) >= '06/01/2013'
and		convert(date, startdatetimeADJ) <= '06/30/2013'

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
select * into #tmpViewData from dbo.vw_BillingPhoneCallMetricsIncomingCalls where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingPhoneCallMetricsIncomingCalls v '
select	@SQLString = @SQLString + 'join #tmpPrograms pr on pr.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + 'and client = ''FORD'''
select	@SQLString = @SQLString + 'and origcallednumber = ''2165'''
select	@SQLString = @SQLString + 'and convert(date, v.startdatetimeADJ) >= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and convert(date, v.startdatetimeADJ) <= ''' + @RangeEndDate + '''' -- Within the Range given

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
		EntityID, -- EntityID
		EntityKey, -- EntityKey
		startdatetime as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		cast(null as nvarchar(50)) as ServiceCode,
		cast(null as nvarchar(50)) as BillingCode
from	#tmpViewData

GO
/****** Object:  StoredProcedure [dbo].[dms_BillingNewRegistrationsManuallyCreated_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingNewRegistrationsManuallyCreated_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingNewRegistrationsManuallyCreated_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingNewRegistrationsManuallyCreated_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingNewRegistrationsManuallyCreated_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- LamBo for Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOHPN'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingNewRegistrationsManuallyCreated_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'

-- Queries to help in testing
select	mbr.*
from	Member mbr
join	Program pr on pr.ID = mbr.ProgramID
where	pr.Code = 'LAMBOHPN'
order by
		mbr.ExpirationDate desc

--begin tran
--update	Member
--set		ExpirationDate = '06/10/2020'
--where id in( 1987537, 1987555, 1987562)
----commit tran


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
select *, cast(0 as int) as RowRank into #tmpViewData from dbo.vw_BillingMembers where 1=0

-- Build SQL String for Select
-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select * from '
select	@SQLString = @SQLString + '(select v.*, '
select	@SQLString = @SQLString + 'RANK() OVER (PARTITION BY MembershipNumber ORDER BY DMSMEmberCreateDate, DMSMemberCountsID desc) AS RowRank '
select	@SQLString = @SQLString + 'from dbo.vw_BillingMembers v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + 'and v.DMSMemberCreateDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DMSMemberCreateDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and IsMbrManuallyCreated = ''1'' ' -- Member Created By NOT System
select	@SQLString = @SQLString + ') as DTL '
select	@SQLString = @SQLString + 'where 1=1 '


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
select	distinct
		ProgramID,
		EntityID,
		EntityKey,
		DMSMemberCreateDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		cast(null as nvarchar(50)) as ServiceCode,
		cast(null as nvarchar(50)) as BillingCode
from	#tmpViewData




GO
/****** Object:  StoredProcedure [dbo].[dms_BillingNewRegistrationsSystemCreated_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingNewRegistrationsSystemCreated_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingNewRegistrationsSystemCreated_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingNewRegistrationsSystemCreated_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingNewRegistrationsSystemCreated_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- LamBo for Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOHPN'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingNewRegistrationsSystemCreated_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'

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
select *, cast(0 as int) as RowRank into #tmpViewData from dbo.vw_BillingMembers where 1=0

-- Build SQL String for Select
-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select * from '
select	@SQLString = @SQLString + '(select v.*, '
select	@SQLString = @SQLString + 'RANK() OVER (PARTITION BY MembershipNumber ORDER BY DMSMEmberCreateDate, DMSMemberCountsID desc) AS RowRank '
select	@SQLString = @SQLString + 'from dbo.vw_BillingMembers v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + 'and v.DMSMemberCreateDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DMSMemberCreateDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and IsMbrManuallyCreated = ''0'' ' -- Member Created By the System
select	@SQLString = @SQLString + ') as DTL '
select	@SQLString = @SQLString + 'where 1=1 '

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
select	distinct
		ProgramID,
		EntityID,
		EntityKey,
		DMSMemberCreateDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		cast(null as nvarchar(50)) as ServiceCode,
		cast(null as nvarchar(50)) as BillingCode
from	#tmpViewData
GO




/****** Object:  StoredProcedure [dbo].[dms_BillingNewRegistrations_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingNewRegistrations_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingNewRegistrations_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingNewRegistrations_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingNewRegistrations_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- For Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'TRLRCARE'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOHPN'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingNewRegistrations_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'

-- Queries to help in testing
select	mbr.*
from	Member mbr
join	Program pr on pr.ID = mbr.ProgramID
where	pr.Code = 'LAMBOHPN'
order by
		mbr.ExpirationDate desc

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
select *, cast(0 as int) as RowRank into #tmpViewData from dbo.vw_BillingMembers where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select * from '
select	@SQLString = @SQLString + '(select v.*, '
select	@SQLString = @SQLString + 'RANK() OVER (PARTITION BY MembershipNumber ORDER BY DMSMEmberCreateDate, DMSMemberCountsID desc) AS RowRank '
select	@SQLString = @SQLString + 'from dbo.vw_BillingMembers v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + 'and v.DMSMemberCreateDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DMSMemberCreateDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + ') as DTL ' -- Within the Range given
select	@SQLString = @SQLString + 'where 1=1 ' -- Within the Range given


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
-- Get results columns for queue
-- Include: BaseQuantity = 1
--			BaseAmount = null
--			BasePercentage = null	
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
select	distinct
		ProgramID,
		EntityID,
		EntityKey,
		DMSMemberCreateDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		cast(null as nvarchar(50)) as ServiceCode,
		cast(null as nvarchar(50)) as BillingCode
from	#tmpViewData




GO
/****** Object:  StoredProcedure [dbo].[dms_BillingNonDispatchEventsAllManuallyCreated_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingNonDispatchEventsAllManuallyCreated_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingNonDispatchEventsAllManuallyCreated_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingNonDispatchEventsAllManuallyCreated_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingNonDispatchEventsSystemCreated_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'TRLRCARE'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingNonDispatchEventsAllManuallyCreated_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'

-- Queries to help in testing
select	mbr.*
from	Member mbr
join	Program pr on pr.ID = mbr.ProgramID
where	pr.Code = 'LAMBOHPN'
order by
		mbr.ExpirationDate desc

--begin tran
--update	Member
--set		ExpirationDate = '06/10/2020'
--where id in( 1987537, 1987555, 1987562)
----commit tran


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
--select	@SQLString = @SQLString + 'and v.ServiceRequestDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DISPATCH = ''0''' -- No Dispatch
select	@SQLString = @SQLString + 'and v.DISPATCH = ''0''' -- No Dispatch
select	@SQLString = @SQLString + 'and v.IsMbrManuallyCreated = ''1''' -- Member NOT Created By System
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_ServiceRequest is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled


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
		EntityID_ServiceRequest as EntityID,
		EntityKey_ServiceRequest as EntityKey,
		ServiceRequestDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData




GO
/****** Object:  StoredProcedure [dbo].[dms_BillingNonDispatchEventsAllSystemCreated_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingNonDispatchEventsAllSystemCreated_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingNonDispatchEventsAllSystemCreated_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingNonDispatchEventsAllSystemCreated_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingNonDispatchEventsAllSystemCreated_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'TRLRCARE'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingNonDispatchEventsAllSystemCreated_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'

-- Queries to help in testing
select	mbr.*
from	Member mbr
join	Program pr on pr.ID = mbr.ProgramID
where	pr.Code = 'LAMBOHPN'
order by
		mbr.ExpirationDate desc

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
--select	@SQLString = @SQLString + 'and v.ServiceRequestDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DISPATCH = ''0''' -- No Dispatch
select	@SQLString = @SQLString + 'and v.IsMbrManuallyCreated = ''0''' -- Member Created By System
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_ServiceRequest is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled




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
		EntityID_ServiceRequest as EntityID,
		EntityKey_ServiceRequest as EntityKey,
		ServiceRequestDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData




GO
/****** Object:  StoredProcedure [dbo].[dms_BillingNonDispatchEventsAll_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingNonDispatchEventsAll_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingNonDispatchEventsAll_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingNonDispatchEventsAll_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingNonDispatchEventsAll_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'TRLRCARE'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingNonDispatchEventsAll_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'


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
--select	@SQLString = @SQLString + 'and v.ServiceRequestDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DISPATCH = ''0''' -- No Dispatch
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_ServiceRequest is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled


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
-- Get results columns for queue
-- Include: BaseQuantity = 1
--			BaseAmount = null
--			BasePercentage = null	
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


GO

GO
/****** Object:  StoredProcedure [dbo].[dms_BillingNonDispatchEventsCustomerAssistanceManuallyCreated_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingNonDispatchEventsCustomerAssistanceManuallyCreated_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingNonDispatchEventsCustomerAssistanceManuallyCreated_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingNonDispatchEventsCustomerAssistanceManuallyCreated_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingNonDispatchEventsCustomerAssistanceManuallyCreated_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'TRLRCARE'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingNonDispatchEventsCustomerAssistanceManuallyCreated_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'

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
--select	@SQLString = @SQLString + 'and v.ServiceRequestDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DISPATCH = ''0''' -- No Dispatch
select	@SQLString = @SQLString + 'and v.CUSTOMER_ASSISTANCE = ''1''' -- Customer Assistance
select	@SQLString = @SQLString + 'and v.IsMbrManuallyCreated = ''1''' -- Member not created by system
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_ServiceRequest is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled



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
		EntityID_ServiceRequest as EntityID,
		EntityKey_ServiceRequest as EntityKey,
		ServiceRequestDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData




GO
/****** Object:  StoredProcedure [dbo].[dms_BillingNonDispatchEventsCustomerAssistanceSystemCreated_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingNonDispatchEventsCustomerAssistanceSystemCreated_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingNonDispatchEventsCustomerAssistanceSystemCreated_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingNonDispatchEventsCustomerAssistanceSystemCreated_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingNonDispatchEventsCustomerAssistanceSystemCreated_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'TRLRCARE'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingNonDispatchEventsCustomerAssistanceSystemCreated_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'

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
--select	@SQLString = @SQLString + 'and v.ServiceRequestDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DISPATCH = ''0''' -- No Dispatch
select	@SQLString = @SQLString + 'and v.CUSTOMER_ASSISTANCE = ''1''' -- Customer Assistance
select	@SQLString = @SQLString + 'and v.IsMbrManuallyCreated = ''0''' -- Member created by system
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_ServiceRequest is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled



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
		EntityID_ServiceRequest as EntityID,
		EntityKey_ServiceRequest as EntityKey,
		ServiceRequestDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData
GO




/****** Object:  StoredProcedure [dbo].[dms_BillingNonDispatchEventsCustomerAssistance_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingNonDispatchEventsCustomerAssistance_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingNonDispatchEventsCustomerAssistance_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingNonDispatchEventsCustomerAssistance_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingNonDispatchEventsCustomerAssistance_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'TRLRCARE'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingNonDispatchEventsCustomerAssistance_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'

-- Queries to help in testing
select	mbr.*
from	Member mbr
join	Program pr on pr.ID = mbr.ProgramID
where	pr.Code = 'LAMBOHPN'
order by
		mbr.ExpirationDate desc

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
--select	@SQLString = @SQLString + 'and v.ServiceRequestDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DISPATCH = ''0''' -- No Dispatch
select	@SQLString = @SQLString + 'and v.CUSTOMER_ASSISTANCE = ''1''' -- Customer Assistance
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_ServiceRequest is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled



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
		EntityID_ServiceRequest as EntityID,
		EntityKey_ServiceRequest as EntityKey,
		ServiceRequestDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData




GO
/****** Object:  StoredProcedure [dbo].[dms_BillingNonDispatchEventsInfoManuallyCreated_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingNonDispatchEventsInfoManuallyCreated_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingNonDispatchEventsInfoManuallyCreated_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingNonDispatchEventsInfoManuallyCreated_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingNonDispatchEventsInfoManuallyCreated_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'TRLRCARE'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingNonDispatchEventsInfoManuallyCreated_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'


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
--select	@SQLString = @SQLString + 'and v.ServiceRequestDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DISPATCH = ''0''' -- No Dispatch
select	@SQLString = @SQLString + 'and v.INFO = ''1''' -- Info
select	@SQLString = @SQLString + 'and v.IsMbrManuallyCreated = ''1''' -- Mbr not created by system
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_ServiceRequest is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled



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
		EntityID_ServiceRequest as EntityID,
		EntityKey_ServiceRequest as EntityKey,
		ServiceRequestDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData




GO
/****** Object:  StoredProcedure [dbo].[dms_BillingNonDispatchEventsInfoSystemCreated_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingNonDispatchEventsInfoSystemCreated_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingNonDispatchEventsInfoSystemCreated_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingNonDispatchEventsInfoSystemCreated_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingNonDispatchEventsInfoSystemCreated_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'TRLRCARE'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingNonDispatchEventsInfoSystemCreated_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'


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
--select	@SQLString = @SQLString + 'and v.ServiceRequestDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DISPATCH = ''0''' -- No Dispatch
select	@SQLString = @SQLString + 'and v.INFO = ''1''' -- Info
select	@SQLString = @SQLString + 'and v.IsMbrManuallyCreated = ''0''' -- Mbr created by system
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_ServiceRequest is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled



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
		EntityID_ServiceRequest as EntityID,
		EntityKey_ServiceRequest as EntityKey,
		ServiceRequestDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData
GO




/****** Object:  StoredProcedure [dbo].[dms_BillingNonDispatchEventsInfo_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingNonDispatchEventsInfo_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingNonDispatchEventsInfo_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingNonDispatchEventsInfo_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingNonDispatchEventsInfo_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'TRLRCARE'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingNonDispatchEventsInfo_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'

-- Queries to help in testing
select	mbr.*
from	Member mbr
join	Program pr on pr.ID = mbr.ProgramID
where	pr.Code = 'LAMBOHPN'
order by
		mbr.ExpirationDate desc

--begin tran
--update	Member
--set		ExpirationDate = '06/10/2020'
--where id in( 1987537, 1987555, 1987562)
----commit tran


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
--select	@SQLString = @SQLString + 'and v.ServiceRequestDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DISPATCH = ''0''' -- No Dispatch
select	@SQLString = @SQLString + 'and v.INFO = ''1''' -- Info
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_ServiceRequest is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled



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
		EntityID_ServiceRequest as EntityID,
		EntityKey_ServiceRequest as EntityKey,
		ServiceRequestDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData


GO

GO
/****** Object:  StoredProcedure [dbo].[dms_BillingNonDispatchEventsOtherManuallyCreated_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingNonDispatchEventsOtherManuallyCreated_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingNonDispatchEventsOtherManuallyCreated_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingNonDispatchEventsOtherManuallyCreated_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingNonDispatchEventsOtherManuallyCreated_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'TRLRCARE'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingNonDispatchEventsOtherManuallyCreated_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'

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
--select	@SQLString = @SQLString + 'and v.ServiceRequestDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DISPATCH = ''0''' -- No Dispatch
select	@SQLString = @SQLString + 'and v.OTHER = ''1''' -- Other
select	@SQLString = @SQLString + 'and v.IsMbrManuallyCreated = ''1''' -- Member not Created By System
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_ServiceRequest is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled


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
-- Get results columns for queue
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




GO
/****** Object:  StoredProcedure [dbo].[dms_BillingNonDispatchEventsOtherSystemCreated_Get]    Script Date: 04/29/2014 02:13:21 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingNonDispatchEventsOtherSystemCreated_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingNonDispatchEventsOtherSystemCreated_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingNonDispatchEventsOtherSystemCreated_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingNonDispatchEventsOtherSystemCreated_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'TRLRCARE'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingNonDispatchEventsOtherSystemCreated_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'

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
--select	@SQLString = @SQLString + 'and v.ServiceRequestDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DISPATCH = ''0''' -- No Dispatch
select	@SQLString = @SQLString + 'and v.OTHER = ''1''' -- Other
select	@SQLString = @SQLString + 'and v.IsMbrManuallyCreated = ''0''' -- Member Created By System
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_ServiceRequest is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled


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
		EntityID_ServiceRequest as EntityID,
		EntityKey_ServiceRequest as EntityKey,
		ServiceRequestDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData




GO
/****** Object:  StoredProcedure [dbo].[dms_BillingNonDispatchEventsOther_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingNonDispatchEventsOther_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingNonDispatchEventsOther_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingNonDispatchEventsOther_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingNonDispatchEventsOther_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'TRLRCARE'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingNonDispatchEventsOther_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'

-- Queries to help in testing
select	mbr.*
from	Member mbr
join	Program pr on pr.ID = mbr.ProgramID
where	pr.Code = 'LAMBOHPN'
order by
		mbr.ExpirationDate desc

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
--select	@SQLString = @SQLString + 'and v.ServiceRequestDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DISPATCH = ''0''' -- No Dispatch
select	@SQLString = @SQLString + 'and v.OTHER = ''1''' -- Other
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_ServiceRequest is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled



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
		EntityID_ServiceRequest as EntityID,
		EntityKey_ServiceRequest as EntityKey,
		ServiceRequestDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData
GO




/****** Object:  StoredProcedure [dbo].[dms_BillingPurchaseOrdersIncurredWithCancels_Get]    Script Date: 04/29/2014 02:13:21 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingPurchaseOrdersIncurredWithCancels_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingPurchaseOrdersIncurredWithCancels_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingPurchaseOrdersIncurredWithCancels_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingPurchaseOrdersIncurredWithCancels_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	11/14/13	MJKrzysiak	Created
 **	
 **
 ** ^1	12/31/2013	MJKrzysiak	Added IsActive to criteria
 **
 **********************************************************************/

/**

declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from Program where Code = 'HPN2TOW'
exec dbo.dms_BillingPurchaseOrdersIncurredWithCancels_Get @ProgramIDs, '12/01/2013', '12/31/2013', '1=1'
--exec dbo.dms_BillingPurchaseOrdersIncurredWithCancels_Get @ProgramIDs, '01/01/2013', '01/31/2013', '1=1'


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
select	@SQLString = @SQLString + 'and v.PASS_THRU = ''1'' ' -- PASS THRU
--select	@SQLString = @SQLString + 'and v.PurchaseOrderDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.PurchaseOrderDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_PurchaseOrder is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled
select	@SQLString = @SQLString + 'and v.PurchaseOrderStatus in '
select	@SQLString = @SQLString + ' (''Issued'', ''Issued-Paid'', ''Cancelled'') ' -- Issued or cancelled
select	@SQLString = @SQLString + 'and v.PurchaseOrderIsActive = 1' -- Must be Active, not flagged as a delete ^1
 
 
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
		PurchaseOrderAmount as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData




GO
/****** Object:  StoredProcedure [dbo].[dms_BillingPurchaseOrdersIncurred_Get]    Script Date: 04/29/2014 02:13:21 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingPurchaseOrdersIncurred_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingPurchaseOrdersIncurred_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingPurchaseOrdersIncurred_Get]
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

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingServiceRequestsPurchaseOrders v '
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
		PurchaseOrderAmount as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData




GO

--/*
--/****** Object:  StoredProcedure [dbo].[dms_BillingVendorInvoicesReceivedwCCDelay1Month_Get]    Script Date: 04/29/2014 02:13:21 ******/
--IF EXISTS (SELECT * FROM dbo.sysobjects 
-- WHERE id = object_id(N'[dbo].[dms_BillingVendorInvoicesReceivedwCCDelay1Month_Get]')   		AND type in (N'P', N'PC')) 
-- BEGIN
-- DROP PROCEDURE [dbo].[dms_BillingVendorInvoicesReceivedwCCDelay1Month_Get] 
-- END 
-- GO  
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
--CREATE PROCEDURE [dbo].[dms_BillingVendorInvoicesReceivedwCCDelay1Month_Get]
--@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
--@pRangeBeginDate as datetime,
--@pRangeEndDate as datetime,
--@pEventFilter as nvarchar(2000)=null
--as
--/********************************************************************
-- **
-- **	dms_BillingVendorInvoicesReceivedwCCDelay1Month_Get
-- **
-- **	Date		Added By	Description
-- **	----------	----------	----------------------------------------
-- **	01/21/14	MJKrzysiak	Created
-- **	
-- **	04/27/14	MJKrzysiak	^1 Changed the BaseAmount being selected
-- **							from InvoiceAmount to PaymentAmount
-- **
-- **********************************************************************/

--/**

---- For Testing
--declare @ProgramIDs as BillingDefinitionProgramsTableType
--insert into @ProgramIDs(ProgramID) (select ID from dbo.Program where Code = 'TRLRCARE')
--exec dbo.dms_BillingVendorInvoicesReceivedwCCDelay1Month_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'


--**/

--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

---- Declare local variables
--declare	@Debug as int,
--		@RangeBeginDate as nvarchar(20),
--		@RangeEndDate as nvarchar(20),
--		@SQLString as nvarchar(max)


---- Initialize Local Variables
--select	@Debug = 0
--select	@SQLString = ''
--select	@RangeBeginDate = convert(nvarchar(20), @pRangeBeginDate, 101),
--		@RangeEndDate = convert(nvarchar(20), @pRangeEndDate, 101)


---- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
---- Get ProgramIDs from Programs Table variable
---- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--if object_id('tempdb..#tmpPrograms', 'U') is not null drop table #tmpPrograms
--create table #tmpPrograms
--(ProgramID	int)

--create unique clustered index inx_tmpPrograms1 on #tmpPrograms(ProgramID)
--insert into #tmpPrograms
--(ProgramID)
--select	ProgramID 
--from	@pProgramIDs


--if @Debug = 1
--begin

--	select	* from #tmpPrograms
	
--end


---- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
---- THIS IS THE SQL THAT DEFINES THE EVENT!
---- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
---- Build temp
--if object_id('tempdb..#tmpViewData', 'U') is not null drop table #tmpViewData
--select * into #tmpViewData from dbo.vw_BillingVendorInvoices where 1=0

---- Build SQL String for Select
--select	@SQLString = @SQLString + 'insert into #tmpViewData '
--select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingVendorInvoices v '
--select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
--select	@SQLString = @SQLString + 'where 1=1 '
--select	@SQLString = @SQLString + ' and v.ReceivedDate<= ''' + @RangeEndDate + ''' '
--select	@SQLString = @SQLString + ' and v.AccountingInvoiceBatchID is null ' -- Not Invoiced
--select	@SQLString = @SQLString + ' and v.VendorInvoiceStatusID in ' -- Ready for Payment
--select	@SQLString = @SQLString + ' (select ID from dbo.VendorInvoiceStatus '
--select	@SQLString = @SQLString + ' where name in (''Received'', ''Ready For Payment'', ''Paid'')) ' 
--select	@SQLString = @SQLString + ' and ''' + @RangeEndDate + ''' >= ' -- If CC then Delay
--select	@SQLString = @SQLString + ' case when v.PaymentCategoryName = ''CreditCard'' '
--select	@SQLString = @SQLString + ' then v.PaymentDateWith1MonthDelay '
--select	@SQLString = @SQLString + ' else v.PaymentDate '
--select	@SQLString = @SQLString + ' end '

 
---- Add additional Criteria
--if @pEventFilter is not null
--begin

--	select	@SQLString = @SQLString + 'and ' + @pEventFilter

--end


--if @Debug = 1
--begin

--	select	'Programs', * from @pProgramIDs
--	select	@pRangeBeginDate as pRangeBeginDate,
--			@pRangeEndDate as pRangeEndDate,
--			@RangeBeginDate as RangeBeginDate,
--			@RangeEndDate as RangeEndDate,
--			@pEventFilter as pEventFilter,
--			@SQLString as SQLString
--end


---- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
---- Execute SQL String to shove data into temp
---- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--exec(@SQLString)


---- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
---- Get results columns for detail
---- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--select	ProgramID,
--		EntityID,
--		EntityKey,
--		VendorInvoiceCreateDate as EntityDate,
--		cast(1 as int)as BaseQuantity,
----		InvoiceAmount as BaseAmount,
--		PaymentAmount as BaseAmount, -- ^1 
--		cast(null as float) as BasePercentage,
--		ServiceCode,
--		ServiceCode as BillingCode
--from	#tmpViewData




--GO

--/****** Object:  StoredProcedure [dbo].[dms_BillingVendorInvoicesReceived_Get]    Script Date: 04/29/2014 02:13:21 ******/
--IF EXISTS (SELECT * FROM dbo.sysobjects 
-- WHERE id = object_id(N'[dbo].[dms_BillingVendorInvoicesReceived_Get]')   		AND type in (N'P', N'PC')) 
-- BEGIN
-- DROP PROCEDURE [dbo].[dms_BillingVendorInvoicesReceived_Get] 
-- END 
-- GO  
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
--CREATE PROCEDURE [dbo].[dms_BillingVendorInvoicesReceived_Get]
--@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
--@pRangeBeginDate as datetime,
--@pRangeEndDate as datetime,
--@pEventFilter as nvarchar(2000)=null
--as
--/********************************************************************
-- **
-- **	dms_BillingVendorInvoicesReceived_Get
-- **
-- **	Date		Added By	Description
-- **	----------	----------	----------------------------------------
-- **	09/01/13	MJKrzysiak	Created
-- **	
-- **	04/27/14	MJKrzysiak	^1 Changed the BaseAmount being selected
-- **							from InvoiceAmount to PaymentAmount
-- **
-- **********************************************************************/

--/**

---- For Testing
--declare @ProgramIDs as BillingDefinitionProgramsTableType
--insert into @ProgramIDs(ProgramID) (select ID from dbo.Program where Code = 'TRLRCARE')
--exec dbo.dms_BillingVendorInvoicesReceived_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'


--**/

--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

---- Declare local variables
--declare	@Debug as int,
--		@RangeBeginDate as nvarchar(20),
--		@RangeEndDate as nvarchar(20),
--		@SQLString as nvarchar(max)


---- Initialize Local Variables
--select	@Debug = 0
--select	@SQLString = ''
--select	@RangeBeginDate = convert(nvarchar(20), @pRangeBeginDate, 101),
--		@RangeEndDate = convert(nvarchar(20), @pRangeEndDate, 101)


---- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
---- Get ProgramIDs from Programs Table variable
---- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--if object_id('tempdb..#tmpPrograms', 'U') is not null drop table #tmpPrograms
--create table #tmpPrograms
--(ProgramID	int)

--create unique clustered index inx_tmpPrograms1 on #tmpPrograms(ProgramID)
--insert into #tmpPrograms
--(ProgramID)
--select	ProgramID 
--from	@pProgramIDs


--if @Debug = 1
--begin

--	select	* from #tmpPrograms
	
--end


---- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
---- THIS IS THE SQL THAT DEFINES THE EVENT!
---- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
---- Build temp
--if object_id('tempdb..#tmpViewData', 'U') is not null drop table #tmpViewData
--select * into #tmpViewData from dbo.vw_BillingVendorInvoices where 1=0

---- Build SQL String for Select
--select	@SQLString = @SQLString + 'insert into #tmpViewData '
--select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingVendorInvoices v '
--select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
--select	@SQLString = @SQLString + 'where 1=1 '
----select	@SQLString = @SQLString + ' and v.ReceivedDate>= ''' + @RangeBeginDate + ''' '
--select	@SQLString = @SQLString + ' and v.ReceivedDate<= ''' + @RangeEndDate + ''' '
--select	@SQLString = @SQLString + ' and v.AccountingInvoiceBatchID is null ' -- Not Invoiced
--select	@SQLString = @SQLString + ' and v.VendorInvoiceStatusID in ' -- Ready for Payment
--select	@SQLString = @SQLString + ' (select ID from dbo.VendorInvoiceStatus '
--select	@SQLString = @SQLString + ' where name in (''Received'', ''Ready For Payment'', ''Paid'')) ' 
--select	@SQLString = @SQLString + ' and v.PaymentDate<= ''' + @RangeEndDate + ''' '


---- <<< NEED BILLLING STATUS TO CONTROL FLOW - Get all those where BillingStatus is not
---- select	@SQLString = @SQLString + 'and isnull(v.BillingStatus, '') = '''' <<< Turn this on when Data Available 

 
 
---- Add additional Criteria
--if @pEventFilter is not null
--begin

--	select	@SQLString = @SQLString + 'and ' + @pEventFilter

--end


--if @Debug = 1
--begin

--	select	'Programs', * from @pProgramIDs
--	select	@pRangeBeginDate as pRangeBeginDate,
--			@pRangeEndDate as pRangeEndDate,
--			@RangeBeginDate as RangeBeginDate,
--			@RangeEndDate as RangeEndDate,
--			@pEventFilter as pEventFilter,
--			@SQLString as SQLString
--end


---- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
---- Execute SQL String to shove data into temp
---- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--exec(@SQLString)


---- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
---- Get results columns for detail
---- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--select	ProgramID,
--		EntityID,
--		EntityKey,
--		VendorInvoiceCreateDate as EntityDate,
--		cast(1 as int)as BaseQuantity,
----		InvoiceAmount as BaseAmount,
--		PaymentAmount as BaseAmount, -- ^1 
--		cast(null as float) as BasePercentage,
--		ServiceCode,
--		ServiceCode as BillingCode
--from	#tmpViewData




--GO
--*/
