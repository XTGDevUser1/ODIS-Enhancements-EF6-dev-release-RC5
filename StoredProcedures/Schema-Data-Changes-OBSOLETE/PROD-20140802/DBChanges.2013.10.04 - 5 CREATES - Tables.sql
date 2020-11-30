
-- ========================    DROPS  ==========================================================================================

--IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingBatchDetail]') AND type in (N'U'))
--DROP TABLE [dbo].[BillingBatchDetail]
--GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingDefinitionInvoiceLineEventProgram]') AND type in (N'U'))
DROP TABLE [dbo].[BillingDefinitionInvoiceLineEventProgram]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingDefinitionInvoiceLineEvent]') AND type in (N'U'))
DROP TABLE [dbo].[BillingDefinitionInvoiceLineEvent]
GO

--IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingBatch]') AND type in (N'U'))
--DROP TABLE [dbo].[BillingBatch]
--GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingInvoiceDetailException]') AND type in (N'U'))
DROP TABLE [dbo].BillingInvoiceDetailException
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingInvoiceDetail]') AND type in (N'U'))
DROP TABLE [dbo].[BillingInvoiceDetail]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingInvoiceLine]') AND type in (N'U'))
DROP TABLE [dbo].[BillingInvoiceLine]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingInvoice]') AND type in (N'U'))
DROP TABLE [dbo].[BillingInvoice]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingDefinitionEvent]') AND type in (N'U'))
DROP TABLE [dbo].[BillingDefinitionEvent]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingDefinitionInvoiceLine]') AND type in (N'U'))
DROP TABLE [dbo].[BillingDefinitionInvoiceLine]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingDefinitionInvoice]') AND type in (N'U'))
DROP TABLE [dbo].[BillingDefinitionInvoice]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingSchedule]') AND type in (N'U'))
DROP TABLE [dbo].[BillingSchedule]
GO

---------------------- LOOK UP TABLES -------------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingAdjustmentReason]') AND type in (N'U'))
DROP TABLE [dbo].[BillingAdjustmentReason]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingExcludeReason]') AND type in (N'U'))
DROP TABLE [dbo].[BillingExcludeReason]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingInvoiceStatus]') AND type in (N'U'))
DROP TABLE [dbo].[BillingInvoiceStatus]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingInvoiceLineStatus]') AND type in (N'U'))
DROP TABLE [dbo].[BillingInvoiceLineStatus]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingInvoiceDetailStatus]') AND type in (N'U'))
DROP TABLE [dbo].[BillingInvoiceDetailStatus]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingInvoiceDetailDisposition]') AND type in (N'U'))
DROP TABLE [dbo].[BillingInvoiceDetailDisposition]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingInvoiceDetailExceptionStatus]') AND type in (N'U'))
DROP TABLE [dbo].[BillingInvoiceDetailExceptionStatus]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingInvoiceDetailExceptionType]') AND type in (N'U'))
DROP TABLE [dbo].[BillingInvoiceDetailExceptionType]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingInvoiceDetailExceptionSeverity]') AND type in (N'U'))
DROP TABLE [dbo].[BillingInvoiceDetailExceptionSeverity]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingScheduleStatus]') AND type in (N'U'))
DROP TABLE [dbo].[BillingScheduleStatus]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingScheduleType]') AND type in (N'U'))
DROP TABLE [dbo].[BillingScheduleType]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingScheduleDateType]') AND type in (N'U'))
DROP TABLE [dbo].[BillingScheduleDateType]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingScheduleRangeType]') AND type in (N'U'))
DROP TABLE [dbo].[BillingScheduleRangeType]
GO

--IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingInvoiceTerms]') AND type in (N'U'))
--DROP TABLE [dbo].[BillingInvoiceTerms]
--GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingInvoiceType]') AND type in (N'U'))
DROP TABLE [dbo].[BillingInvoiceType]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingInvoiceTemplate]') AND type in (N'U'))
DROP TABLE [dbo].[BillingInvoiceTemplate]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingInvoiceLineEventGenWhen]') AND type in (N'U'))
DROP TABLE [dbo].BillingInvoiceLineEventGenWhen
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BillingEventSystemSource]') AND type in (N'U'))
DROP TABLE [dbo].BillingEventSystemSource
GO



-- ========================    CREATES  ==========================================================================================

-- Code Tables
--------------------------------------------------------------
create table dbo.BillingAdjustmentReason
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingAdjustmentReason
add constraint PK_BillingAdjustmentReason primary key (ID)
go
create unique index inx_BillingAdjustmentReason_uc on dbo.BillingAdjustmentReason (Name)
select	* from dbo.BillingAdjustmentReason

-----------------
create table dbo.BillingExcludeReason
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingExcludeReason
add constraint PK_BillingExcludeReason primary key (ID)
go
create unique index inx_BillingExcludeReason_uc on dbo.BillingExcludeReason (Name)
select	* from dbo.BillingExcludeReason

-----------------
create table dbo.BillingInvoiceStatus
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingInvoiceStatus
add constraint PK_BillingInvoiceStatus primary key (ID)
go
create unique index inx_BillingInvoiceStatus_uc on dbo.BillingInvoiceStatus (Name)
select	* from dbo.BillingInvoiceStatus

-----------------
create table dbo.BillingInvoiceLineStatus
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingInvoiceLineStatus
add constraint PK_BillingInvoiceLineStatus primary key (ID)
go
create unique index inx_BillingInvoiceLineStatus_uc on dbo.BillingInvoiceLineStatus (Name)
select	* from dbo.BillingInvoiceLineStatus

-----------------
create table dbo.BillingInvoiceDetailStatus
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingInvoiceDetailStatus
add constraint PK_BillingInvoiceDetailStatus primary key (ID)
go
create unique index inx_BillingInvoiceDetailStatus_uc on dbo.BillingInvoiceDetailStatus (Name)
select	* from dbo.BillingInvoiceDetailStatus

-----------------
create table dbo.BillingInvoiceDetailDisposition
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingInvoiceDetailDisposition
add constraint PK_BillingInvoiceDetailDisposition primary key (ID)
go
create unique index inx_BillingInvoiceDetailDisposition_uc on dbo.BillingInvoiceDetailDisposition (Name)
select	* from dbo.BillingInvoiceDetailDisposition

-----------------
create table dbo.BillingInvoiceDetailExceptionType
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingInvoiceDetailExceptionType
add constraint PK_BillingInvoiceDetailExceptionType primary key (ID)
go
create unique index inx_BillingInvoiceDetailExceptionType_uc on dbo.BillingInvoiceDetailExceptionType (Name)
select	* from dbo.BillingInvoiceDetailExceptionType

-----------------
create table dbo.BillingInvoiceDetailExceptionStatus
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingInvoiceDetailExceptionStatus
add constraint PK_BillingInvoiceDetailExceptionStatus primary key (ID)
go
create unique index inx_BillingInvoiceDetailExceptionStatus_uc on dbo.BillingInvoiceDetailExceptionStatus (Name)
select	* from dbo.BillingInvoiceDetailExceptionStatus

-----------------
create table dbo.BillingInvoiceDetailExceptionSeverity
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingInvoiceDetailExceptionSeverity
add constraint PK_BillingInvoiceDetailExceptionSeverity primary key (ID)
go
create unique index inx_BillingInvoiceDetailExceptionSeverity_uc on dbo.BillingInvoiceDetailExceptionSeverity (Name)
select	* from dbo.BillingInvoiceDetailExceptionSeverity

-----------------
create table dbo.BillingScheduleType
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingScheduleType
add constraint PK_BillingScheduleType primary key (ID)
go
create unique index inx_BillingScheduleType_uc on dbo.BillingScheduleType (Name)
select	* from dbo.BillingScheduleType

-----------------
create table dbo.BillingScheduleDateType
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingScheduleDateType
add constraint PK_BillingScheduleDateType primary key (ID)
go
create unique index inx_BillingScheduleDateType_uc on dbo.BillingScheduleDateType (Name)
select	* from dbo.BillingScheduleDateType

-----------------
create table dbo.BillingScheduleRangeType
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingScheduleRangeType
add constraint PK_BillingScheduleRangeType primary key (ID)
go
create unique index inx_BillingScheduleRangeType_uc on dbo.BillingScheduleRangeType (Name)
select	* from dbo.BillingScheduleRangeType

-----------------
create table dbo.BillingScheduleStatus
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingScheduleStatus
add constraint PK_BillingScheduleStatus primary key (ID)
go
create unique index inx_BillingScheduleStatus_uc on dbo.BillingScheduleStatus (Name)
select	* from dbo.BillingScheduleStatus

-----------------
/***
create table dbo.BillingInvoiceTerms
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingInvoiceTerms
add constraint PK_BillingInvoiceTerms primary key (ID)
go
create unique index inx_BillingTerms_uc on dbo.BillingInvoiceTerms (Name)
select	* from dbo.BillingInvoiceTerms
***/

-----------------
create table dbo.BillingInvoiceType
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingInvoiceType
add constraint PK_BillingInvoiceType primary key (ID)
go
create unique index inx_BillingInvoiceType_uc on dbo.BillingInvoiceType (Name)
select	* from dbo.BillingInvoiceType

-----------------
create table dbo.BillingInvoiceTemplate
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingInvoiceTemplate
add constraint PK_BillingInvoiceTemplate primary key (ID)
go
create unique index inx_BillingInvoiceTemplate_uc on dbo.BillingInvoiceTemplate (Name)
select	* from dbo.BillingInvoiceTemplate

-----------------
create table dbo.BillingInvoiceLineEventGenWhen
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingInvoiceLineEventGenWhen
add constraint PK_BillingInvoiceLineEventGenWhen primary key (ID)
go
create unique index inx_BillingInvoiceLineEventGenWhen_uc on dbo.BillingInvoiceLineEventGenWhen (Name)
select	* from dbo.BillingInvoiceLineEventGenWhen

-----------------
create table dbo.BillingEventSystemSource
(ID								int					identity,
 Name							nvarchar(50),
 [Description]					nvarchar(255),
 Sequence						int,
 IsActive						bit
)
go

-- PK
alter table dbo.BillingEventSystemSource
add constraint PK_BillingEventSystemSource primary key (ID)
go
create unique index inx_BillingEventSystemSource_uc on dbo.BillingEventSystemSource (Name)
select	* from dbo.BillingEventSystemSource

--------------------------------------------------------------------------------------------------------------------------------
--create table dbo.BillingBatch
--(ID								int					identity,
-- BatchID						int,
-- Name							nvarchar(50),
-- [Description]					nvarchar(255),
-- Sequence						int,
-- IsActive						bit,
-- InvoiceCount					int,
-- InvoiceAmountTotal				money,
-- CreateDate						datetime,
-- CreateBy						nvarchar(50),
-- ModifyDate						datetime,
-- ModifyBy						nvarchar(50)
--)
--go

---- PK
--alter table dbo.BillingBatch
--add constraint PK_BillingBatch primary key (ID)
--go
--select	* from dbo.BillingBatch


--------------------------------------------------------------------------------------------------------------------------------
-- drop table dbo.BillingSchedule
create table dbo.BillingSchedule
(ID							int					identity,
 Name						nvarchar(50),
 [Description]				nvarchar(255),
 ScheduleDateTypeID			int,
 ScheduleRangeTypeID		int,
 ScheduleDate				datetime,
 ScheduleRangeBegin			datetime,
 ScheduleRangeEnd			datetime,
 ScheduleTypeID				int,
 ScheduleStatusID			int,
 Sequence					int,
 IsActive					bit,
 CreateDate					datetime,
 CreateBy					nvarchar(50),
 ModifyDate					datetime,
 ModifyBy					nvarchar(50)
)
go

-- PK
alter table dbo.BillingSchedule
add constraint PK_BillingSchedule primary key (ID)
go

create unique index inx_BillingSchedule_uc on dbo.BillingSchedule (Name, ScheduleTypeID, ScheduleDate)
go

alter table dbo.BillingSchedule
add constraint FK_BS_ScheduleDateTypeID foreign key (ScheduleDateTypeID) references dbo.BillingScheduleDateType(ID)
go

alter table dbo.BillingSchedule
add constraint FK_BS_ScheduleRangeTypeID foreign key (ScheduleRangeTypeID) references dbo.BillingScheduleRangeType(ID)
go

alter table dbo.BillingSchedule
add constraint FK_BS_ScheduleTypeID foreign key (ScheduleTypeID) references dbo.BillingScheduleType(ID)
go

alter table dbo.BillingSchedule
add constraint FK_BS_ScheduleStatusID foreign key (ScheduleStatusID) references dbo.BillingScheduleStatus(ID)
go


select	* from dbo.BillingSchedule


--------------------------------------------------------------------------------------------------------------------------------
-- drop table dbo.BillingDefinitionInvoice
create table dbo.BillingDefinitionInvoice
(ID									int					identity,
 ClientID							int,
 ScheduleTypeID						int,
 Name								nvarchar(50),
 [Description]						nvarchar(255),
 --BillToCompany					nvarchar(100),
 --BillToAttention					nvarchar(100),
 --InvoiceTermsID					int,
 AccountingSystemCustomerNumber		nvarchar(7),
 AccountingSystemAddressCode		nvarchar(4),
 POPrefix							nvarchar(15),
 PONumber							nvarchar(100),
 InvoiceTypeID						int,								
 InvoiceTemplateID					int,
 DefaultInvoiceStatusID				int,
 CanAddLines						bit,
 Sequence							int,
 IsActive							bit,
 CreateDate							datetime,
 CreateBy							nvarchar(50),
 ModifyDate							datetime,
 ModifyBy							nvarchar(50)
)
go

-- PK
alter table dbo.BillingDefinitionInvoice
add constraint PK_BillingDefinitionInvoice primary key (ID)
go

-- FKs
alter table dbo.BillingDefinitionInvoice
add constraint FK_BDI_ClientID foreign key (ClientID) references dbo.Client(ID)
go

alter table dbo.BillingDefinitionInvoice
add constraint FK_BDI_ScheduleTypeID foreign key (ScheduleTypeID) references dbo.BillingScheduleType(ID)
go

alter table dbo.BillingDefinitionInvoice
add constraint FK_BDI_DefaultInvoiceStatusID foreign key (DefaultInvoiceStatusID) references dbo.BillingInvoiceStatus(ID)
go

alter table dbo.BillingDefinitionInvoice
add constraint FK_BDI_InvoiceTypeID foreign key (InvoiceTypeID) references dbo.BillingInvoiceType(ID)
go

alter table dbo.BillingDefinitionInvoice
add constraint FK_BDI_InvoiceTemplateID foreign key (InvoiceTemplateID) references dbo.BillingInvoiceTemplate(ID)
go

--alter table dbo.BillingDefinitionInvoice
--add constraint FK_BDI_InvoiceTermsID foreign key (InvoiceTermsID) references dbo.BillingInvoiceTerms(ID)
--go


select	* from dbo.BillingDefinitionInvoice


--------------------------------------------------------------------------------------------------------------------------------
create table dbo.BillingDefinitionInvoiceLine
(ID									int					identity,
 BillingDefinitionInvoiceID			int,
 ProductID							int,
 RateTypeID							int,
 Name								nvarchar(50),
 [Description]						nvarchar(255),
 Comment							nvarchar(30),
 Rate								money,
 FixedQuantity						int,
 DefaultInvoiceLineStatusID			int,
 Sequence							int,
 IsActive							bit,
 CreateDate							datetime,
 CreateBy							nvarchar(50),
 ModifyDate							datetime,
 ModifyBy							nvarchar(50)
)
go

-- PK
alter table dbo.BillingDefinitionInvoiceLine
add constraint PK_BillingDefinitionInvoiceLine primary key (ID)
go

-- FKs
alter table dbo.BillingDefinitionInvoiceLine
add constraint FK_BDIL_BillingDefinitionInvoiceID foreign key (BillingDefinitionInvoiceID) references dbo.BillingDefinitionInvoice(ID)
go

alter table dbo.BillingDefinitionInvoiceLine
add constraint FK_BDIL_ProductID foreign key (ProductID) references dbo.Product(ID)
go

alter table dbo.BillingDefinitionInvoiceLine
add constraint FK_BDIL_RateTypeID foreign key (RateTypeID) references dbo.RateType(ID)
go

alter table dbo.BillingDefinitionInvoiceLine
add constraint FK_BDIL_DefaultInvoiceLineStatusID foreign key (DefaultInvoiceLineStatusID) references dbo.BillingInvoiceLineStatus(ID)
go

select	* from dbo.BillingDefinitionInvoiceLine


--------------------------------------------------------------------------------------------------------------------------------
create table dbo.BillingDefinitionEvent
(ID						int					identity,
 EventSystemSourceID	int,
 --EntityID				int,
 Name					nvarchar(50),
 [Description]			nvarchar(255),
 DBObject				nvarchar(255),
 Sequence				int,
 IsActive				bit,
 CreateDate				datetime,
 CreateBy				nvarchar(50),
 ModifyDate				datetime,
 ModifyBy				nvarchar(50)
 )

go

-- PK
alter table dbo.BillingDefinitionEvent
add constraint PK_BillingDefinitionEvent primary key (ID)
go

--alter table dbo.BillingDefinitionEvent -- <<<< NOT Always enforced- could be external source
--add constraint FK_BDE_EntityID foreign key (EntityID) REFERENCES dbo.Entity(ID)
--go

alter table dbo.BillingDefinitionEvent
add constraint FK_BDE_EventSystemSourceID foreign key (EventSystemSourceID) references dbo.BillingEventSystemSource(ID)
go

select	* from dbo.BillingDefinitionEvent


--------------------------------------------------------------------------------------------------------------------------------
create table dbo.BillingDefinitionInvoiceLineEvent
(ID									int			identity,
 BillingDefinitionInvoiceLineID		int,
 BillingDefinitionEventID			int,
 Name								nvarchar(50),
 [Description]						nvarchar(255),
 EventFilter						nvarchar(2000),
 IsAdjustable						bit,
 IsExcludable						bit,
 DefaultInvoiceDetailStatusID		int,
 EventGenWhenID						int,
 Sequence							int,
 IsActive							bit,
 CreateDate							datetime,
 CreateBy							nvarchar(50),
 ModifyDate							datetime,
 ModifyBy							nvarchar(50)
)
go

-- PK
alter table dbo.BillingDefinitionInvoiceLineEvent
add constraint PK_BillingDefinitionInvoiceLineEvent primary key (ID)
go

-- FKs
alter table dbo.BillingDefinitionInvoiceLineEvent
add constraint FK_BDILE_BillingDefinitionInvoiceLineID foreign key (BillingDefinitionInvoiceLineID) references dbo.BillingDefinitionInvoiceLine(ID)
go

alter table dbo.BillingDefinitionInvoiceLineEvent
add constraint FK_BDILE_BillingDefinitionEventID foreign key (BillingDefinitionEventID) references dbo.BillingDefinitionEvent(ID)
go

alter table dbo.BillingDefinitionInvoiceLineEvent
add constraint FK_BDILE_DefaultInvoiceDetailStatusID foreign key (DefaultInvoiceDetailStatusID) references dbo.BillingInvoiceDetailStatus(ID)
go

select	* from dbo.BillingDefinitionInvoiceLineEvent


--------------------------------------------------------------------------------------------------------------------------------
create table dbo.BillingDefinitionInvoiceLineEventProgram
(ID										int			identity,
 BillingDefinitionInvoiceLineEventID	int,
 ProgramID								int,
 Sequence								int,
 IsActive								bit,
 CreateDate								datetime,
 CreateBy								nvarchar(50),
 ModifyDate								datetime,
 ModifyBy								nvarchar(50)
)
go

-- PK
alter table dbo.BillingDefinitionInvoiceLineEventProgram
add constraint PK_BillingDefinitionInvoiceLineEventProgram primary key (ID)
go

-- FKs
alter table dbo.BillingDefinitionInvoiceLineEventProgram
add constraint FK_BDILEP_BillingDefinitionInvoiceLineEventID foreign key (BillingDefinitionInvoiceLineEventID) REFERENCES dbo.BillingDefinitionInvoiceLineEvent(ID)
go

alter table dbo.BillingDefinitionInvoiceLineEventProgram
add constraint FK_BDILEP_ProgramID foreign key (ProgramID) REFERENCES dbo.Program(ID)
go

select	* from dbo.BillingDefinitionInvoiceLineEventProgram


--------------------------------------------------------------------------------------------------------------------------------
create table dbo.BillingInvoice
(ID									int					identity,
 ClientID							int,
 BillingScheduleID					int,
 Name								nvarchar(50),
 [Description]						nvarchar(255),
 AccountingSystemCustomerNumber		nvarchar(7),
 AccountingSystemAddressCode		nvarchar(4),
 POPrefix							nvarchar(15),
 PONumber							nvarchar(100),
 InvoiceTypeID						int, --
 InvoiceTemplateID					int, --
 InvoiceDate						datetime,
 ScheduleDate						datetime,
 ScheduleRangeTypeID				int, -- 
 ScheduleRangeBegin					datetime,
 ScheduleRangeEnd					datetime,
 InvoiceStatusID					int,
 InvoiceReferenceNumber				nvarchar(50),
 InvoiceNumber						nvarchar(7),
 CanAddLines						bit,
 BillingDefinitionInvoiceID			int,
 AccountingInvoiceBatchID			int,
 Sequence							int,
 IsActive							bit,
 CreateDate							datetime,
 CreateBy							nvarchar(50),
 ModifyDate							datetime,
 ModifyBy							nvarchar(50)
)
go

-- PK
alter table dbo.BillingInvoice
add constraint PK_BillingInvoice primary key (ID)
go

-- FKs
alter table dbo.BillingInvoice
add constraint FK_BI_BillingDefinitionInvoiceID foreign key (BillingDefinitionInvoiceID) references dbo.BillingDefinitionInvoice(ID)

alter table dbo.BillingInvoice
add constraint FK_BI_ClientID foreign key (ClientID) references dbo.Client(ID)

alter table dbo.BillingInvoice
add constraint FK_BI_BillingScheduleID foreign key (BillingScheduleID) references dbo.BillingSchedule(ID)

alter table dbo.BillingInvoice
add constraint FK_BI_InvoiceTypeID foreign key (InvoiceTypeID) references dbo.BillingInvoiceType(ID)

alter table dbo.BillingInvoice
add constraint FK_BI_InvoiceTemplateID foreign key (InvoiceTemplateID) references dbo.BillingInvoiceTemplate(ID)

alter table dbo.BillingInvoice
add constraint FK_BI_ScheduleRangeTypeID foreign key (ScheduleRangeTypeID) references dbo.BillingScheduleRangeType(ID)

alter table dbo.BillingInvoice
add constraint FK_BI_InvoiceStatusID foreign key (InvoiceStatusID) references dbo.BillingInvoiceStatus(ID)
go

select	* from dbo.BillingInvoice


--------------------------------------------------------------------------------------------------------------------------------
create table dbo.BillingInvoiceLine
(ID									int					identity,
 BillingInvoiceID					int,
 ProductID							int,
 RateTypeID							int,
 Name								nvarchar(50),
 [Description]						nvarchar(255),
 Comment							nvarchar(30),
 AccountingSystemGLCode				nvarchar(50),
 LineQuantity						int,
 LineCost							money,
 LineAmount							money,
 InvoiceLineStatusID				int,
 BillingDefinitionInvoiceLineID		int,
 AccountingSystemItemCode			nvarchar(14),
 Sequence							int,
 IsActive							bit,
 CreateDate							datetime,
 CreateBy							nvarchar(50),
 ModifyDate							datetime,
 ModifyBy							nvarchar(50)
)
go

-- PK
alter table dbo.BillingInvoiceLine
add constraint PK_BillingInvoiceLine primary key (ID)
go

-- FKs
alter table dbo.BillingInvoiceLine
add constraint FK_BIL_BillingInvoiceID foreign key (BillingInvoiceID) references dbo.BillingInvoice(ID)
go

alter table dbo.BillingInvoiceLine
add constraint FK_BIL_BillingDefinitionInvoiceLineID foreign key (BillingDefinitionInvoiceLineID) references dbo.BillingDefinitionInvoiceLine(ID)
go

alter table dbo.BillingInvoiceLine
add constraint FK_BIL_ProductID foreign key (ProductID) references dbo.Product(ID)
go

alter table dbo.BillingInvoiceLine
add constraint FK_BIL_RateTypeID foreign key (RateTypeID) references dbo.RateType(ID)
go

alter table dbo.BillingInvoiceLine
add constraint FK_BIL_InvoiceLineStatusID foreign key (InvoiceLineStatusID) references dbo.BillingInvoiceLineStatus(ID)
go

select	* from dbo.BillingInvoiceLine


-------------------------------------------------------------------------------------------------------------------------------
-- drop table dbo.BillingInvoiceDetail
create table dbo.BillingInvoiceDetail
(ID										int					identity,
 BillingDefinitionInvoiceID				int,
 BillingDefinitionInvoiceLineID			int,
 BillingDefinitionEventID				int,
 BillingScheduleID						int,
 ProgramID								int,
 EntityID								int,
 EntityKey								nvarchar(50),
 EntityDate								datetime,
 Name									nvarchar(50),
 [Description]							nvarchar(255),
 ---
 ServiceCode							nvarchar(50),
 BillingCode							nvarchar(50),
 ProductID								int,
 AccountingSystemItemCode				nvarchar(14),
 AccountingSystemGLCode					nvarchar(50),
 RateTypeName							nvarchar(50),
 Quantity								int,
 EventAmount							money,
 -- Status Cols
 InvoiceDetailStatusID					int, -- BillingInvoiceDetailStatus
 InvoiceDetailStatusAuthorization		nvarchar(100),
 InvoiceDetailStatusAuthorizationDate	datetime,

-- Disposition Cols
 InvoiceDetailDispositionID				int, -- BillingInvoiceDetailDisposition

 -- Adjustment Cols
 IsAdjustable							bit,
 AdjustmentReasonID						int, -- BillingAdjustmentReason
 AdjustmentReasonOther					nvarchar(50),
 AdjustmentComment						nvarchar(max),
 AdjustedBy								nvarchar(50),
 AdjustmentDate							datetime,
 AdjustmentAmount						money,
 AdjustmentAuthorization				nvarchar(100),
 AdjustmentAuthorizationDate			datetime,
 
 -- Exclude From Invoice Cols
 IsExcludable							bit,
 ExcludeReasonID						int, -- BillingExcludeReason
 ExcludeReasonOther						nvarchar(50),
 ExcludeComment							nvarchar(max),
 ExcludedBy								nvarchar(50),
 ExcludeDate							datetime,
 ExcludeAuthorization					nvarchar(100),
 ExcludeAuthorizationDate				datetime,


 BillingInvoiceLineID					int, -- brought over when invoice finalized
 
 AccountingInvoiceBatchID				int, -- brought over when invoiced
 
 Sequence								int,
 IsActive								bit,
 CreateDate								datetime,
 CreateBy								nvarchar(50),
 ModifyDate								datetime,
 ModifyBy								nvarchar(50)
)
go

-- PK
alter table dbo.BillingInvoiceDetail
add constraint PK_BillingInvoiceDetail primary key (ID)
go

-- FKs
alter table dbo.BillingInvoiceDetail
add constraint FK_BID_BillingDefinitionInvoiceID foreign key (BillingDefinitionInvoiceID) references dbo.BillingDefinitionInvoice(ID)
go

alter table dbo.BillingInvoiceDetail
add constraint FK_BID_BillingDefinitionInvoiceLineID foreign key (BillingDefinitionInvoiceLineID) references dbo.BillingDefinitionInvoiceLine(ID)
go

alter table dbo.BillingInvoiceDetail
add constraint FK_BID_BillingScheduleID foreign key (BillingScheduleID) references dbo.BillingSchedule(ID)
go

alter table dbo.BillingInvoiceDetail
add constraint FK_BID_BillingDefinitionEventID foreign key (BillingDefinitionEventID) references dbo.BillingDefinitionEvent(ID)
go

alter table dbo.BillingInvoiceDetail
add constraint FK_BID_ProgramID foreign key (ProgramID) references dbo.Program(ID)
go

alter table dbo.BillingInvoiceDetail
add constraint FK_BID_InvoiceDetailStatusID foreign key (InvoiceDetailStatusID) references dbo.BillingInvoiceDetailStatus(ID)
go

alter table dbo.BillingInvoiceDetail
add constraint FK_BID_InvoiceDetailDispositionID foreign key (InvoiceDetailDispositionID) references dbo.BillingInvoiceDetailDisposition(ID)
go

alter table dbo.BillingInvoiceDetail
add constraint FK_BID_AdjustmentReasonID foreign key (AdjustmentReasonID) references dbo.BillingAdjustmentReason(ID)
go

alter table dbo.BillingInvoiceDetail
add constraint FK_BID_ExcludeReasonID foreign key (ExcludeReasonID) references dbo.BillingExcludeReason(ID)
go


-- THIS DOES NOT ALWAYS EXIST, so CANT ENFORCE - May be from source outside ODIS
--alter table dbo.BillingInvoiceDetail
--add constraint FK_BID_EntityID foreign key (EntityID) references dbo.Entity(ID)
--go

select	* from dbo.BillingInvoiceDetail


-------------------------------------------------------------------------------------------------------------------------------
create table dbo.BillingInvoiceDetailException
(ID										int					identity,
 BillingInvoiceDetailID					int,
 InvoiceDetailExceptionTypeID			int, -- BillingInvoiceDetailExceptionType
 InvoiceDetailExceptionStatusID			int, -- BillingInvoiceDetailExceptionStatus
 InvoiceDetailExceptionSeverityID		int, -- BillingInvoiceDetailExceptionSeverity
 InvoiceDetailExceptionComment			nvarchar(max),
 ExceptionAuthorization					nvarchar(100),
 ExceptionAuthorizationDate				datetime,
 Sequence								int,
 IsActive								bit,
 CreateDate								datetime,
 CreateBy								nvarchar(50),
 ModifyDate								datetime,
 ModifyBy								nvarchar(50)
)
go

-- PK
alter table dbo.BillingInvoiceDetailException
add constraint PK_BillingInvoiceDetailException primary key (ID)
go

-- FKs
alter table dbo.BillingInvoiceDetailException
add constraint FK_BIDE_BillingInvoiceDetailID foreign key (BillingInvoiceDetailID) references dbo.BillingInvoiceDetail(ID)
go

alter table dbo.BillingInvoiceDetailException
add constraint FK_BIDE_InvoiceDetailExceptionTypeID foreign key (InvoiceDetailExceptionTypeID) references dbo.BillingInvoiceDetailExceptionType(ID)
go

alter table dbo.BillingInvoiceDetailException
add constraint FK_BIDE_InvoiceDetailExceptionStatusID foreign key (InvoiceDetailExceptionStatusID) references dbo.BillingInvoiceDetailExceptionStatus(ID)
go

alter table dbo.BillingInvoiceDetailException
add constraint FK_BIDE_InvoiceDetailExceptionSeverityID foreign key (InvoiceDetailExceptionSeverityID) references dbo.BillingInvoiceDetailExceptionSeverity(ID)
go

select	* from dbo.BillingInvoiceDetailException



--------------------------------------------------------------------------------------------------------------------------------
--create table dbo.BillingBatchDetail
--(ID								int					identity,
-- BillingBatchID					int,
-- BillingInvoiceID				int,
-- Name							nvarchar(50),
-- [Description]					nvarchar(255),
-- ClientID						int,					
-- ProgramID						int,
-- InvoiceReferenceNumber			nvarchar(50),	
-- InvoiceNumber					nvarchar(50),
-- GLCode							nvarchar(50),
-- Amount							money,
-- Sequence						int,
-- IsActive						bit,
-- CreateDate						datetime,
-- CreateBy						nvarchar(50),
-- ModifyDate						datetime,
-- ModifyBy						nvarchar(50)
--)
--go

---- PK
--alter table dbo.BillingBatchDetail
--add constraint PK_BillingBatchDetail primary key (ID)
--go

---- FKs
--alter table dbo.BillingBatchDetail
--add constraint FK_BBD_BillingBatchID foreign key (BillingBatchID) REFERENCES dbo.BillingBatch(ID)
--go

--alter table dbo.BillingBatchDetail
--add constraint FK_BBD_BillingInvoiceID foreign key (BillingInvoiceID) REFERENCES dbo.BillingInvoice(ID)
--go

--alter table dbo.BillingBatchDetail
--add constraint FK_BBD_ClientID foreign key (ClientID) REFERENCES dbo.Client(ID)
--go

--alter table dbo.BillingBatchDetail
--add constraint FK_BBD_ProgramID foreign key (ProgramID) REFERENCES dbo.Program(ID)
--go

--select	* from dbo.BillingBatchDetail




-- TYPES ------------------------------------------------------------------------------------------------------------------------------

/***
IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'BillingDefinitionInvoiceLineEventsTableType' AND ss.name = N'dbo')
DROP TYPE [dbo].[BillingDefinitionInvoiceLineEventsTableType]
GO

create type BillingDefinitionInvoiceLineEventsTableType as table
(
 BillingDefinitionInvoiceID int null,
 BillingDefinitionInvoiceLineID int null,
 BillingDefinitionInvoiceLineEventID int null
)


IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'BillingDefinitionProgramsTableType' AND ss.name = N'dbo')
DROP TYPE [dbo].BillingDefinitionProgramsTableType
GO

create type BillingDefinitionProgramsTableType as table
(
 ProgramID int
)


IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'BillingDefinitionInvoiceTableType' AND ss.name = N'dbo')
DROP TYPE [dbo].[BillingDefinitionInvoiceTableType]
GO

create type BillingDefinitionInvoiceTableType as table
(
 BillingDefinitionInvoiceID int null
)


IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'BillingInvoiceTableType' AND ss.name = N'dbo')
DROP TYPE [dbo].[BillingInvoiceTableType]
GO

create type BillingInvoiceTableType as table
(
 BillingInvoiceID int null
)


***/

