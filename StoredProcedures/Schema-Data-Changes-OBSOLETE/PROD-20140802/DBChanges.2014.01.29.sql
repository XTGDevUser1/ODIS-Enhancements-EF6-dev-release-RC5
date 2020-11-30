CREATE TABLE [dbo].[TemporaryCreditCard_Import](
	[RecordID] [bigint] IDENTITY(1,1) NOT NULL,
	[ProcessIdentifier] [uniqueidentifier] NOT NULL,
	[PurchaseID_CreditCardIssueNumber] [nvarchar](50) NOT NULL,
	[CPN_PAN_CreditCardNumber] [nvarchar](50) NOT NULL,
	[PurchaseOrderID] [int] NULL,
	[VendorInvoiceID] [int] NULL,
	[CREATE_DATE_IssueDate_TransactionDate] [datetime] NOT NULL,
	[USER_NAME_IssueBy_TransactionBy] [nvarchar](100) NOT NULL,
	[IssueStatus] [nvarchar](50) NOT NULL,
	[CDF_PO_ReferencePurchaseOrderNumber] [nvarchar](50) NOT NULL,
	[CDF_PO_OriginalReferencePurchaseOrderNumber] [nvarchar](50) NOT NULL,
	[CDF_ISP_Vendor_ReferenceVendorNumber] [nvarchar](50) NOT NULL,
	[ApprovedAmount] [money] NOT NULL,
	[TotalChargeAmount] [money] NOT NULL,
	[TemporaryCreditCardStatusID] [int] NOT NULL,
	[ExceptionMessage] [nvarchar](200) NULL,
	[Note] [nvarchar](1000) NULL,
	[CreateDate] [datetime] NOT NULL,
	[CreateBy] [nvarchar](50) NOT NULL,
	[ModifyDate] [datetime] NULL,
	[ModifyBy] [nvarchar](50) NULL,
	[HISTORY_ID_TransactionSequence] [int] NOT NULL,
	[ACTION_TYPE_TransactionType] [nvarchar](20) NOT NULL,
	[REQUESTED_AMOUNT_RequestedAmount] [money] NOT NULL,
	[APPROVED_AMOUNT_ApprovedAmount] [money] NOT NULL,
	[AVAILABLE_BALANCE_AvailableBalance] [money] NOT NULL,
	[ChargeDate] [datetime] NULL,
	[ChargeAmount] [money] NULL,
	[ChargeDescription] [nvarchar](100) NULL,
	[TemporaryCreditCardID] [int] NULL,
	[TemporaryCreditCardDetailsID] [int] NULL,
 CONSTRAINT [PK_TemporaryCreditCard_Import] PRIMARY KEY CLUSTERED 
(
	[RecordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

CREATE TABLE [dbo].[TemporaryCreditCard_Import_ChargedTransactions](
	[RecordID] [bigint] IDENTITY(1,1) NOT NULL,
	[ProcessIdentifier] [uniqueidentifier] NULL,
	[TemporaryCreditCardID] [int] NULL,
	[TemporaryCreditCardDetailsID] [int] NULL,
	[FINVirtualCardNumber_C_CreditCardNumber] [nvarchar](50) NULL,
	[FINCFFData02_C_OriginalReferencePurchaseOrderNumber] [nvarchar](50) NULL,
	[TransactionSequence] [int] NULL,
	[FINTransactionDate_C_IssueDate_TransactionDate] [date] NOT NULL,
	[TransactionType] [nvarchar](50) NOT NULL,
	[TransactionBy] [nvarchar](50) NULL,
	[RequestedAmount] [money] NULL,
	[ApprovedAmount] [money] NULL,
	[AvailableBalance] [money] NULL,
	[FINPostingDate_ChargeDate] [date] NOT NULL,
	[FINTransactionAmount_ChargeAmount] [money] NOT NULL,
	[FINTransactionDescription_ChargeDescription] [nvarchar](max) NULL,
	[CreateDate] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](50) NOT NULL,
	[ModifyDate] [datetime] NULL,
	[ModifiedBy] [nvarchar](50) NULL,
	[ExceptionMessage] [nvarchar](max) NULL,
 CONSTRAINT [PK_TemporaryCreditCard_Import_ChargedTransactions] PRIMARY KEY CLUSTERED 
(
	[RecordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  ForeignKey [FK_VendorInvoice_PaymentType]    Script Date: 01/29/2014 13:15:08 ******/
ALTER TABLE [dbo].[VendorInvoice]  WITH NOCHECK ADD  CONSTRAINT [FK_VendorInvoice_PaymentType] FOREIGN KEY([PaymentTypeID])
REFERENCES [dbo].[PaymentType] ([ID])
GO
ALTER TABLE [dbo].[VendorInvoice] CHECK CONSTRAINT [FK_VendorInvoice_PaymentType]
GO
