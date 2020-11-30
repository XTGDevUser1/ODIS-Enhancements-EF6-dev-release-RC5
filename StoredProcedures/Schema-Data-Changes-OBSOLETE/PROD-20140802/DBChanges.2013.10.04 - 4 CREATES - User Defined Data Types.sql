
-- User Defined Data Types
----------------------------------------------------------------------------
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

