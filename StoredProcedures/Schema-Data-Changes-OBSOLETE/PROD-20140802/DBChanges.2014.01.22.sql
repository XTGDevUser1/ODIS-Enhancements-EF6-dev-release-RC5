-- NP 01/22 : Excute statement by statement.

--Database scripts for Temporary Credit Card
/****** Object:  Table [dbo].[TemporaryCreditCardStatus]    Script Date: 01/21/2014 17:46:28 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TemporaryCreditCardStatus]') AND type in (N'U'))
DROP TABLE [dbo].[TemporaryCreditCardStatus]


GO

/****** Object:  Table [dbo].[TemporaryCreditCardStatus]    Script Date: 01/21/2014 17:48:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TemporaryCreditCardStatus](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Description] [nvarchar](255) NULL,
	[Sequence] [int] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_TemporaryCreditCardStatus] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

-- Load table
IF NOT EXISTS (SELECT * FROM TemporaryCreditCardStatus WHERE Name = 'Unmatched')
BEGIN
      INSERT INTO TemporaryCreditCardStatus VALUES('Unmatched','Unmatched',1,1)
END

IF NOT EXISTS (SELECT * FROM TemporaryCreditCardStatus WHERE Name = 'Exception')
BEGIN
      INSERT INTO TemporaryCreditCardStatus VALUES('Exception','Exception',2,1)
END

IF NOT EXISTS (SELECT * FROM TemporaryCreditCardStatus WHERE Name = 'Matched')
BEGIN
      INSERT INTO TemporaryCreditCardStatus VALUES('Matched','Matched',3,1)
END

IF NOT EXISTS (SELECT * FROM TemporaryCreditCardStatus WHERE Name = 'Posted')
BEGIN
      INSERT INTO TemporaryCreditCardStatus VALUES('Posted','Posted',4,1)
END

IF NOT EXISTS (SELECT * FROM TemporaryCreditCardStatus WHERE Name = 'Cancelled')
BEGIN
      INSERT INTO TemporaryCreditCardStatus VALUES('Cancelled','Cancelled',5,1)
END

GO

--Temporary credit card table
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK__TemporaryCreditCard_TemporaryCreditCardStatus]') AND parent_object_id = OBJECT_ID(N'[dbo].[TemporaryCreditCard]'))
ALTER TABLE [dbo].[TemporaryCreditCard] DROP CONSTRAINT [FK__TemporaryCreditCard_TemporaryCreditCardStatus]
GO

GO

/****** Object:  Table [dbo].[TemporaryCreditCard]    Script Date: 01/21/2014 20:51:40 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TemporaryCreditCard]') AND type in (N'U'))
DROP TABLE [dbo].[TemporaryCreditCard]
GO


GO

/****** Object:  Table [dbo].[TemporaryCreditCard]    Script Date: 01/21/2014 20:51:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TemporaryCreditCard](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CreditCardIssueNumber] [nvarchar](50) NULL,
	[CreditCardNumber] [nvarchar](50) NULL,
	[PurchaseOrderID] [int] NULL,
	[VendorInvoiceID] [int] NULL,
	[IssueDate] [datetime] NULL,
	[IssueBy] [nvarchar](100) NULL,
	[IssueStatus] [nvarchar](50) NULL,
	[MatchPurchaseOrderNumber] [nvarchar](50) NULL,
	[ReferencePurchaseOrderNumber] [nvarchar](50) NULL,
	[ReferenceVendorNumber] [nvarchar](50) NULL,
	[ApprovedAmount] [money] NULL,
	[TotalChargedAmount] [money] NULL,
	[TemporaryCreditCardStatusID] [int] NULL,
	[ExceptionMessage] [nvarchar](200) NULL,
	[Note] [nvarchar](1000) NULL,
	[PostingBatchID] [int] NULL,
	[AccountingPeriodID] [int] NULL,
	[CreateDate] [datetime] NULL,
	[CreateBy] [nvarchar](50) NULL,
	[ModifyDate] [datetime] NULL,
	[ModifyBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_TemporaryCreditCard] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[TemporaryCreditCard]  WITH NOCHECK ADD  CONSTRAINT [FK__TemporaryCreditCard_TemporaryCreditCardStatus] FOREIGN KEY([TemporaryCreditCardStatusID])
REFERENCES [dbo].[TemporaryCreditCardStatus] ([ID])
GO

ALTER TABLE [dbo].[TemporaryCreditCard] NOCHECK CONSTRAINT [FK__TemporaryCreditCard_TemporaryCreditCardStatus]
GO

--Temporary Credit Card detail
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TemporaryCreditCardDetail]') AND type in (N'U'))
DROP TABLE [dbo].[TemporaryCreditCardDetail]
GO


GO

/****** Object:  Table [dbo].[TemporaryCreditCardDetail]    Script Date: 01/21/2014 20:52:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TemporaryCreditCardDetail](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TemporaryCreditCardID] [int] NOT NULL,
	[TransactionSequence] [int] NULL,
	[TransactionDate] [datetime] NULL,
	[TransactionType] [nvarchar](20) NULL,
	[TransactionBy] [nvarchar](100) NULL,
	[RequestedAmount] [money] NULL,
	[ApprovedAmount] [money] NULL,
	[AvailableBalance] [money] NULL,
	[ChargeDate] [datetime] NULL,
	[ChargeAmount] [money] NULL,
	[ChargeDescription] [nvarchar](100) NULL,
	[CreateDate] [datetime] NULL,
	[CreateBy] [nvarchar](50) NULL,
	[ModifyDate] [datetime] NULL,
	[ModifyBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_TemporaryCreditCardDetail] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

--Batch type for temporary credit card
IF NOT EXISTS (SELECT * FROM BatchType WHERE Name = 'TemporaryCCPost')
BEGIN  
      INSERT INTO BatchType VALUES('TemporaryCCPost','Temporary CC Post',5,1,NULL)
END

-- NP 01/22 : Excute statement by statement.
IF NOT EXISTS (Select * from Securable where FriendlyName='MENU_LEFT_TEMPORARY_CC_PROCESSING')
BEGIN
INSERT INTO Securable VALUES('MENU_LEFT_TEMPORARY_CC_PROCESSING',(Select ID from Securable where FriendlyName='MENU_TOP_VENDOR'),NULL)
END
IF NOT EXISTS (Select * from Securable where FriendlyName='MENU_LEFT_TEMPORARY_CC_HISTORY')
BEGIN
INSERT INTO Securable VALUES('MENU_LEFT_TEMPORARY_CC_HISTORY',(Select ID from Securable where FriendlyName='MENU_TOP_VENDOR'),NULL)
END

INSERT INTO AccessControlList VALUES(
	(Select ID from Securable where FriendlyName='MENU_LEFT_TEMPORARY_CC_PROCESSING'),
	(Select RoleId from aspnet_Roles where RoleName='SysAdmin' AND ApplicationId=(Select ApplicationId from aspnet_Applications where ApplicationName='DMS')),
	(Select ID from AccessType where Name='ReadWrite')
	)
INSERT INTO AccessControlList VALUES(
	(Select ID from Securable where FriendlyName='MENU_LEFT_TEMPORARY_CC_HISTORY'),
	(Select RoleId from aspnet_Roles where RoleName='SysAdmin' AND ApplicationId=(Select ApplicationId from aspnet_Applications where ApplicationName='DMS')),
	(Select ID from AccessType where Name='ReadWrite')
	)
INSERT INTO AccessControlList VALUES(
	(Select ID from Securable where FriendlyName='MENU_LEFT_TEMPORARY_CC_PROCESSING'),
	(Select RoleId from aspnet_Roles where RoleName='VendorRep'),
	(Select ID from AccessType where Name='ReadWrite')
	)
INSERT INTO AccessControlList VALUES(
	(Select ID from Securable where FriendlyName='MENU_LEFT_TEMPORARY_CC_HISTORY'),
	(Select RoleId from aspnet_Roles where RoleName='VendorRep'),
	(Select ID from AccessType where Name='ReadWrite')
	)