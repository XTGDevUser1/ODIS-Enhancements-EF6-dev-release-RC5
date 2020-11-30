if (select @@ServerName) in ('INFHYDCRM4D\SQLR2')
begin


-- BillingAdjustmentReason
-- truncate table BillingAdjustmentReason
insert into dbo.BillingAdjustmentReason (Name, [Description], Sequence, IsActive) values ('OVER_LIMIT', 'Over Limit', 1, 1)
insert into dbo.BillingAdjustmentReason (Name, [Description], Sequence, IsActive) values ('CLIENT_REQ', 'Client Requested', 1, 1)
insert into dbo.BillingAdjustmentReason (Name, [Description], Sequence, IsActive) values ('INTERNAL_REQ', 'Internal Requested', 1, 1)
insert into dbo.BillingAdjustmentReason (Name, [Description], Sequence, IsActive) values ('OTHER', 'Other', 1, 1)

-- BillingExcludeReason
-- truncate table BillingExcludeReason
insert into dbo.BillingExcludeReason (Name, [Description], Sequence, IsActive) values ('GOA', 'Gone on Arrival', 1, 1)
insert into dbo.BillingExcludeReason (Name, [Description], Sequence, IsActive) values ('OUT_OF_WARR', 'Out Of Warranty', 1, 1)
insert into dbo.BillingExcludeReason (Name, [Description], Sequence, IsActive) values ('OTHER', 'Other', 1, 1)

-- BillingInvoiceStatus
-- truncate table BillingInvoiceStatus
insert into dbo.BillingInvoiceStatus (Name, [Description], Sequence, IsActive) values ('PENDING', 'Pending', 1, 1)
insert into dbo.BillingInvoiceStatus (Name, [Description], Sequence, IsActive) values ('READY', 'Ready', 1, 1)
insert into dbo.BillingInvoiceStatus (Name, [Description], Sequence, IsActive) values ('INVOICED', 'Invoiced', 1, 1)
insert into dbo.BillingInvoiceStatus (Name, [Description], Sequence, IsActive) values ('POSTED', 'Posted', 1, 1)

-- BillingInvoiceLineStatus
-- truncate table BillingInvoiceLineStatus
insert into dbo.BillingInvoiceLineStatus (Name, [Description], Sequence, IsActive) values ('PENDING', 'Pending', 1, 1)
insert into dbo.BillingInvoiceLineStatus (Name, [Description], Sequence, IsActive) values ('READY', 'Ready', 1, 1)
insert into dbo.BillingInvoiceLineStatus (Name, [Description], Sequence, IsActive) values ('INVOICED', 'Invoiced', 1, 1)
insert into dbo.BillingInvoiceLineStatus (Name, [Description], Sequence, IsActive) values ('POSTED', 'Posted', 1, 1)

-- BillingInvoiceDetailStatus
-- truncate table BillingInvoiceDetailStatus
insert into dbo.BillingInvoiceDetailStatus (Name, [Description], Sequence, IsActive) values ('PENDING', 'Pending', 1, 1)
insert into dbo.BillingInvoiceDetailStatus (Name, [Description], Sequence, IsActive) values ('READY', 'Ready', 1, 1)
--insert into dbo.BillingInvoiceDetailStatus (Name, [Description], Sequence, IsActive) values ('INVOICED', 'Invoiced', 1, 1)
insert into dbo.BillingInvoiceDetailStatus (Name, [Description], Sequence, IsActive) values ('POSTED', 'Posted', 1, 1)
insert into dbo.BillingInvoiceDetailStatus (Name, [Description], Sequence, IsActive) values ('ONHOLD', 'On Hold', 1, 1)
insert into dbo.BillingInvoiceDetailStatus (Name, [Description], Sequence, IsActive) values ('EXCEPTION', 'Exception', 1, 1)
insert into dbo.BillingInvoiceDetailStatus (Name, [Description], Sequence, IsActive) values ('DELETED', 'Deleted', 1, 1)
insert into dbo.BillingInvoiceDetailStatus (Name, [Description], Sequence, IsActive) values ('EXCLUDED', 'Excluded', 1, 1)

-- BillingInvoiceDetailDisposition
-- truncate table BillingInvoiceDetailDisposition
insert into dbo.BillingInvoiceDetailDisposition (Name, [Description], Sequence, IsActive) values ('REFRESH', 'Refresh', 1, 1)
insert into dbo.BillingInvoiceDetailDisposition (Name, [Description], Sequence, IsActive) values ('LOCKED', 'Locked', 1, 1)

-- BillingInvoiceDetailExceptionType
-- truncate table BillingInvoiceDetailExceptionType
insert into dbo.BillingInvoiceDetailExceptionType (Name, [Description], Sequence, IsActive) values ('OVER_MILEAGE', 'Over Mileage', 1, 1)
insert into dbo.BillingInvoiceDetailExceptionType (Name, [Description], Sequence, IsActive) values ('OUT_OF_WARR', 'Out of Warranty', 1, 1)
insert into dbo.BillingInvoiceDetailExceptionType (Name, [Description], Sequence, IsActive) values ('OTHER', 'Other', 1, 1)

-- BillingInvoiceDetailExceptionStatus
-- truncate table BillingInvoiceDetailExceptionStatus
insert into dbo.BillingInvoiceDetailExceptionStatus (Name, [Description], Sequence, IsActive) values ('PENDING', 'Pending', 1, 1)
insert into dbo.BillingInvoiceDetailExceptionStatus (Name, [Description], Sequence, IsActive) values ('READY', 'Ready', 1, 1)

-- BillingInvoiceDetailExceptionSeverity
-- truncate table BillingInvoiceDetailExceptionSeverity
insert into dbo.BillingInvoiceDetailExceptionSeverity (Name, [Description], Sequence, IsActive) values ('INFO', 'Information', 1, 1)
insert into dbo.BillingInvoiceDetailExceptionSeverity (Name, [Description], Sequence, IsActive) values ('WARNING', 'Warning', 1, 1)
insert into dbo.BillingInvoiceDetailExceptionSeverity (Name, [Description], Sequence, IsActive) values ('ERROR', 'Error', 1, 1)

-- BillingScheduleStatus
-- truncate table BillingScheduleStatus
insert into dbo.BillingScheduleStatus (Name, [Description], Sequence, IsActive) values ('OPEN', 'Open', 1, 1)
insert into dbo.BillingScheduleStatus (Name, [Description], Sequence, IsActive) values ('CLOSED', 'Closed', 1, 1)

-- BillingScheduleType
-- truncate table BillingScheduleType
insert into dbo.BillingScheduleType (Name, [Description], Sequence, IsActive) values ('MONTHLY', 'Monthly', 1, 1)
insert into dbo.BillingScheduleType (Name, [Description], Sequence, IsActive) values ('WEEKLY', 'Weekly', 1, 1)

-- BillingScheduleDateType
-- truncate table BillingScheduleDateType
insert into dbo.BillingScheduleDateType (Name, [Description], Sequence, IsActive) values ('FIRST_DAY_OF_MO', 'First Day Of Month', 1, 1)
insert into dbo.BillingScheduleDateType (Name, [Description], Sequence, IsActive) values ('MONDAY', 'Monday', 1, 1)

-- BillingScheduleDateRangeType
-- truncate table BillingScheduleRangeType
insert into dbo.BillingScheduleRangeType (Name, [Description], Sequence, IsActive) values ('PREVIOUS_MO', 'Previous Month', 1, 1)
insert into dbo.BillingScheduleRangeType (Name, [Description], Sequence, IsActive) values ('PREVIOUS_WK', 'Previous Week', 1, 1)

/**
-- BillingInvoiceTerms
-- truncate table dbo.BillingInvoiceTerms
insert into dbo.BillingInvoiceTerms (Name, [Description], Sequence, IsActive) values ('NET30', 'Net 30', 1, 1)
insert into dbo.BillingInvoiceTerms (Name, [Description], Sequence, IsActive) values ('NET60', 'Net 60', 1, 1)
**/

-- BillingInvoiceType
-- truncate table dbo.BillingInvoiceType
insert into dbo.BillingInvoiceType (Name, [Description], Sequence, IsActive) values ('STANDARD', 'Standard', 1, 1)
insert into dbo.BillingInvoiceType (Name, [Description], Sequence, IsActive) values ('DEL_DRVR', 'Delivery Driver', 1, 1)

-- BillingInvoiceTemplate
-- truncate table dbo.BillingInvoiceTemplate
insert into dbo.BillingInvoiceTemplate (Name, [Description], Sequence, IsActive) values ('STANDARD', 'Standard', 1, 1)

-- BillingInvoiceLineEventGenWhen
-- truncate table dbo.BillingInvoiceLineEventGenWhen
insert into dbo.BillingInvoiceLineEventGenWhen (Name, [Description], Sequence, IsActive) values ('ALWAYS', 'Always', 1, 1)
insert into dbo.BillingInvoiceLineEventGenWhen (Name, [Description], Sequence, IsActive) values ('SCHED_END', 'Schedule End', 1, 1)
insert into dbo.BillingInvoiceLineEventGenWhen (Name, [Description], Sequence, IsActive) values ('SCHED_END_JAN', 'Schedule End - Jan', 1, 1)

-- BillingEventSystemSource
-- truncate table dbo.BillingEventSystemSource
insert into dbo.BillingEventSystemSource (Name, [Description], Sequence, IsActive) values ('ODIS', 'ODIS Dispatch System', 1, 1)
insert into dbo.BillingEventSystemSource (Name, [Description], Sequence, IsActive) values ('DATAMART', 'Data Mart System', 1, 1)
insert into dbo.BillingEventSystemSource (Name, [Description], Sequence, IsActive) values ('MANUAL', 'Manual', 1, 1)



select 'BillingAdjustmentReason', * from dbo.BillingAdjustmentReason
select 'BillingExcludeReason',* from dbo.BillingExcludeReason
select 'BillingInvoiceStatus',* from dbo.BillingInvoiceStatus
select 'BillingInvoiceLineStatus',* from dbo.BillingInvoiceLineStatus
select 'BillingInvoiceDetailStatus',* from dbo.BillingInvoiceDetailStatus
select 'BillingInvoiceDetailDisposition',* from dbo.BillingInvoiceDetailDisposition
select 'BillingInvoiceDetailExceptionStatus',* from dbo.BillingInvoiceDetailExceptionStatus
select 'BillingInvoiceDetailExceptionSeverity',* from dbo.BillingInvoiceDetailExceptionSeverity
select 'BillingScheduleStatus',* from dbo.BillingScheduleStatus
select 'BillingScheduleType',* from dbo.BillingScheduleType
select 'BillingScheduleDateType', * from dbo.BillingScheduleDateType
select 'BillingScheduleRangeType', * from dbo.BillingScheduleRangeType
--select 'BillingInvoiceTerms',* from dbo.BillingInvoiceTerms
select 'BillingInvoiceType',* from dbo.BillingInvoiceType
select 'BillingInvoiceTemplate',* from dbo.BillingInvoiceTemplate
select 'BillingInvoiceLineEventGenWhen',* from dbo.BillingInvoiceLineEventGenWhen
select 'BillingEventSystemSource',* from dbo.BillingEventSystemSource


print 'Insert into Billing Code Tables Completed'


end


