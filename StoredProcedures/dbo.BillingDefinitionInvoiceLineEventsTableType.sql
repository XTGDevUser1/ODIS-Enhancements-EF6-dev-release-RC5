/****** Object:  UserDefinedTableType [dbo].[BillingDefinitionInvoiceLineEventsTableType]    Script Date: 04/29/2014 02:13:26 ******/
DROP TYPE [dbo].[BillingDefinitionInvoiceLineEventsTableType]
GO
CREATE TYPE [dbo].[BillingDefinitionInvoiceLineEventsTableType] AS TABLE(
	[BillingDefinitionInvoiceID] [int] NULL,
	[BillingDefinitionInvoiceLineID] [int] NULL,
	[BillingDefinitionInvoiceLineEventID] [int] NULL
)
GO
