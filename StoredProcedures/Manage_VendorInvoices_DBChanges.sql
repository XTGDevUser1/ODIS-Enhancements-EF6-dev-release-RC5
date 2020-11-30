-- NP:8/20
CREATE TABLE [dbo].[VendorInvoiceStatus](
      [ID] [int] IDENTITY(1,1) NOT NULL,
      [Name] [nvarchar](50) NULL,
      [Description] [nvarchar](255) NULL,
      [Sequence] [int] NULL,
      [IsActive] [bit] NULL,
CONSTRAINT [PK_VendorInvoiceStatus] PRIMARY KEY CLUSTERED
(
      [ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
 
GO
 
SET IDENTITY_INSERT [dbo].[VendorInvoiceStatus] ON
INSERT [dbo].[VendorInvoiceStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (1, N'Received', N'Received', 1, 1)
INSERT [dbo].[VendorInvoiceStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (2, N'ReadyForPayment', N'Ready For Payment', 2, 1)
INSERT [dbo].[VendorInvoiceStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (3, N'Paid', N'Paid', 3, 1)
INSERT [dbo].[VendorInvoiceStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (4, N'Cancelled', N'Cancelled', 4, 1)
SET IDENTITY_INSERT [dbo].[VendorInvoiceStatus] OFF
GO
 
CREATE TABLE [dbo].[VendorInvoice](
      [ID] [int] IDENTITY(1,1) NOT NULL,
      [PurchaseOrderID] [int] NULL,
      [VendorID] [int] NULL,
      [VendorInvoiceStatusID] [int] NULL,
      [SourceSystemID] [int] NULL,
      [InvoiceNumber] [nvarchar](50) NULL,
      [ReceivedDate] [datetime] NULL,
      [ReceiveContactMethodID] [int] NULL,
      [InvoiceDate] [datetime] NULL,
      [InvoiceAmount] [money] NULL,
      [BillingBusinessName] [nvarchar](50) NULL,
      [BillingContactName] [nvarchar](50) NULL,
      [BillingAddressLine1] [nvarchar](100) NULL,
      [BillingAddressLine2] [nvarchar](100) NULL,
      [BillingAddressLine3] [nvarchar](100) NULL,
      [BillingAddressCity] [nvarchar](100) NULL,
      [BillingAddressStateProvince] [nvarchar](10) NULL,
      [BillingAddressPostalCode] [nvarchar](20) NULL,
      [BillingAddressCountryCode] [nvarchar](2) NULL,
      [ToBePaidDate] [datetime] NULL,
      [ExportDate] [datetime] NULL,
      [ExportBatchID] [int] NULL,
      [PaymentTypeID] [int] NULL,
      [PaymentDate] [datetime] NULL,
      [PaymentAmount] [money] NULL,
      [CheckNumber] [nvarchar](50) NULL,
      [CheckClearedDate] [datetime] NULL,
      [ActualETAMinutes] [int] NULL,
      [Last8OfVIN] [nvarchar](20) NULL,
      [VehicleMileage] [int] NULL,
      [IsActive] [bit] NULL,
      [CreateDate] [datetime] NULL,
      [CreateBy] [nvarchar](50) NULL,
      [ModifyDate] [datetime] NULL,
      [ModifyBy] [nvarchar](50) NULL,
CONSTRAINT [PK_VendorInvoice] PRIMARY KEY CLUSTERED
(
      [ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
 
GO
 
ALTER TABLE [dbo].[VendorInvoice]  WITH CHECK ADD  CONSTRAINT [FK_VendorInvoice_PurchaseOrder] FOREIGN KEY([PurchaseOrderID])
REFERENCES [dbo].[PurchaseOrder] ([ID])
GO
 
ALTER TABLE [dbo].[VendorInvoice] CHECK CONSTRAINT [FK_VendorInvoice_PurchaseOrder]
GO
 
ALTER TABLE [dbo].[VendorInvoice]  WITH CHECK ADD  CONSTRAINT [FK_VendorInvoice_SourceSystem] FOREIGN KEY([SourceSystemID])
REFERENCES [dbo].[SourceSystem] ([ID])
GO
 
ALTER TABLE [dbo].[VendorInvoice] CHECK CONSTRAINT [FK_VendorInvoice_SourceSystem]
GO
 
ALTER TABLE [dbo].[VendorInvoice]  WITH CHECK ADD  CONSTRAINT [FK_VendorInvoice_Vendor] FOREIGN KEY([VendorID])
REFERENCES [dbo].[Vendor] ([ID])
GO
 
ALTER TABLE [dbo].[VendorInvoice] CHECK CONSTRAINT [FK_VendorInvoice_Vendor]
GO
 
ALTER TABLE [dbo].[VendorInvoice]  WITH CHECK ADD  CONSTRAINT [FK_VendorInvoice_VendorInvoiceStatus] FOREIGN KEY([VendorInvoiceStatusID])
REFERENCES [dbo].[VendorInvoiceStatus] ([ID])
GO
 
ALTER TABLE [dbo].[VendorInvoice] CHECK CONSTRAINT [FK_VendorInvoice_VendorInvoiceStatus]
GO
 
 
 --NP 8/20 Vendor Invoice Packet
INSERT INTO [ContactCategory]
	([Name]
	,[Description]
	,[IsShownOnFinish]
	,[IsActive]
	,[Sequence])
	VALUES
('VendorInvoice', 'Vendor Invoice', 1, 1, NULL)
GO

INSERT INTO [ContactReason]
	([ContactCategoryID]
	,[Name]
	,[Description]
	,[IsActive]
	,[IsShownOnScreen]
	,[Sequence])
VALUES
(14, 'SubmitInvoice', 'Submit Invoice', 1, 1, NULL)
GO

INSERT INTO [ContactReason]
	([ContactCategoryID]
	,[Name]
	,[Description]
	,[IsActive]
	,[IsShownOnScreen]
	,[Sequence])
VALUES
(14, 'UpdateInvoice', 'Update Invoice', 1, 1, NULL)
GO

INSERT INTO [ContactAction]
	([ContactCategoryID]
	,[Name]
	,[Description]
	,[IsShownOnScreen]
	,[IsTalkedToRequired]
	,[IsActive]
	,[Sequence])
VALUES
(14, 'ReceivedInvoice', 'Received Vendor Invoice', 1, NULL, 1, NULL)
GO

INSERT INTO [ContactAction]
	([ContactCategoryID]
	,[Name]
	,[Description]
	,[IsShownOnScreen]
	,[IsTalkedToRequired]
	,[IsActive]
	,[Sequence])
VALUES
(14, 'UpdatedInvoice', 'Updated Vendor Invoice', 1, NULL, 1, NULL)
GO