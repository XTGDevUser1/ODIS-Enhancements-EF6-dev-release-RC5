--DB Changes
ALTER TABLE VendorLocation
ADD DispatchEmail NVARCHAR(100) NULL

--PO Table changes

CREATE TABLE [dbo].[PurchaseOrderPayStatusCode](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Description] [nvarchar](255) NULL,
	[Sequence] [int] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_PurchaseOrderPayStatusCode] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


INSERT INTO [dbo].[PurchaseOrderPayStatusCode]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('OnHold'
           ,'OnHold'
           ,1
           ,1)
INSERT INTO [dbo].[PurchaseOrderPayStatusCode]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('PaidByCC'
           ,'Paid by company CC'
           ,2
           ,1)
INSERT INTO [dbo].[PurchaseOrderPayStatusCode]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('PaidByMember'
           ,'Paid by Member'
           ,3
           ,1)
INSERT INTO [dbo].[PurchaseOrderPayStatusCode]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('Aged'
           ,'Over 90 Days'
           ,4
           ,1)
INSERT INTO [dbo].[PurchaseOrderPayStatusCode]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('PayToVendor'
           ,'Pay to Vendor'
           ,5
           ,1)                                            
GO

ALTER Table [dbo].[PurchaseOrder] ADD PayStatusCodeID int null
GO 

ALTER TABLE [dbo].[PurchaseOrder]  WITH CHECK ADD  CONSTRAINT [FK_PurchaseOrder_PurchaseOrderPayStatusCode] FOREIGN KEY([PayStatusCodeID])
REFERENCES [dbo].[PurchaseOrderPayStatusCode] ([ID])
GO

ALTER TABLE [dbo].[PurchaseOrder] CHECK CONSTRAINT [FK_PurchaseOrder_PurchaseOrderPayStatusCode]
GO

ALTER TABLE [dbo].[PurchaseOrder]
DROP COLUMN IsNotInvoiceEligible
GO



