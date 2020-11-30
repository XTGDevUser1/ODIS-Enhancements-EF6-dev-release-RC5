ALTER TABLE VendorUser
ADD ReceiveNotification BIT NULL
GO

ALTER TABLE Feedback
ADD [VendorID] [int] NULL
GO

ALTER TABLE Feedback
ADD [PreferedContactMethodID] [int] NULL
GO

ALTER TABLE [dbo].[Feedback]  WITH CHECK ADD  CONSTRAINT [FK_Feedback_ContactMethod] FOREIGN KEY([PreferedContactMethodID])
REFERENCES [dbo].[ContactMethod] ([ID])
GO

ALTER TABLE [dbo].[Feedback] CHECK CONSTRAINT [FK_Feedback_ContactMethod]
GO

ALTER TABLE [dbo].[Feedback]  WITH CHECK ADD  CONSTRAINT [FK_Feedback_Vendor] FOREIGN KEY([VendorID])
REFERENCES [dbo].[Vendor] ([ID])
GO

ALTER TABLE [dbo].[Feedback] CHECK CONSTRAINT [FK_Feedback_Vendor]
GO



INSERT INTO [Entity]
([Name]
,[IsAudited])
VALUES
('Feedback',0)
INSERT INTO [Event]
([EventTypeID]
,[EventCategoryID]
,[Name]
,[Description]
,[IsShownOnScreen]
,[IsActive]
,[CreateBy]
,[CreateDate])
VALUES
(2, SELECT ID FROM EventCategory WHERE Name = 'VendorPortal', 'VendorPortalSubmitFeedback', 'Vendor Portal Submit Feedback', 1, 1, NULL, NULL)

GO

/* Vendor Regions */

SET IDENTITY_INSERT [dbo].[Entity] ON
INSERT INTO [dbo].[Entity] ([ID], [Name], [IsAudited]) VALUES (30, N'VendorRegion', 0)
SET IDENTITY_INSERT [dbo].[Entity] OFF

/****** Object:  Table [dbo].[VendorRegion]    Script Date: 09/09/2013 16:52:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VendorRegion](
      [ID] [int] IDENTITY(1,1) NOT NULL,
      [Name] [nvarchar](255) NULL,
      [ContactFirstName] [nvarchar](50) NULL,
      [ContactLastName] [nvarchar](50) NULL,
      [Email] [nvarchar](255) NULL,
CONSTRAINT [PK_VendorRegion] PRIMARY KEY CLUSTERED 
(
      [ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[VendorRegionStateProvince]    Script Date: 09/09/2013 16:52:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VendorRegionStateProvince](
      [ID] [int] IDENTITY(1,1) NOT NULL,
      [VendorRegionID] [int] NOT NULL,
      [StateProvinceID] [int] NOT NULL,
CONSTRAINT [PK_VendorRegionStateProvince] PRIMARY KEY CLUSTERED 
(
      [ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  ForeignKey [FK_VendorRegionStateProvince_StateProvince]    Script Date: 09/09/2013 16:52:06 ******/
ALTER TABLE [dbo].[VendorRegionStateProvince]  WITH CHECK ADD  CONSTRAINT [FK_VendorRegionStateProvince_StateProvince] FOREIGN KEY([StateProvinceID])
REFERENCES [dbo].[StateProvince] ([ID])
GO
ALTER TABLE [dbo].[VendorRegionStateProvince] CHECK CONSTRAINT [FK_VendorRegionStateProvince_StateProvince]
GO
/****** Object:  ForeignKey [FK_VendorRegionStateProvince_VendorRegion]    Script Date: 09/09/2013 16:52:06 ******/
ALTER TABLE [dbo].[VendorRegionStateProvince]  WITH CHECK ADD  CONSTRAINT [FK_VendorRegionStateProvince_VendorRegion] FOREIGN KEY([VendorRegionID])
REFERENCES [dbo].[VendorRegion] ([ID])
GO
ALTER TABLE [dbo].[VendorRegionStateProvince] CHECK CONSTRAINT [FK_VendorRegionStateProvince_VendorRegion]
GO



/* Set up Vendor Regions */
SET IDENTITY_INSERT [dbo].[VendorRegion] ON
INSERT [dbo].[VendorRegion] ([ID], [Name], [ContactFirstName], [ContactLastName], [Email]) VALUES (1, N'Central Region Network', N'Jessica', N'Waldon', N'jwaldon@nmc.com')
INSERT [dbo].[VendorRegion] ([ID], [Name], [ContactFirstName], [ContactLastName], [Email]) VALUES (2, N'West Region Network', N'Candice', N'Anderson', N'canderson@nmc.com')
INSERT [dbo].[VendorRegion] ([ID], [Name], [ContactFirstName], [ContactLastName], [Email]) VALUES (3, N'Southeast Region Network', N'Tony', N'Van Deyl', N'tvandeyl@nmc.com')
INSERT [dbo].[VendorRegion] ([ID], [Name], [ContactFirstName], [ContactLastName], [Email]) VALUES (4, N'Northeast Region Network', N'Byron', N'Bailey', N'bbailey@nmc.com')
INSERT [dbo].[VendorRegion] ([ID], [Name], [ContactFirstName], [ContactLastName], [Email]) VALUES (5, N'Canada Network', N'Candice', N'Anderson', N'canderson@nmc.com')
INSERT [dbo].[VendorRegion] ([ID], [Name], [ContactFirstName], [ContactLastName], [Email]) VALUES (6, N'Puerto Rico Network', N'Tony', N'Van Deyl', N'tvandeyl@nmc.com')
SET IDENTITY_INSERT [dbo].[VendorRegion] OFF
GO

SET IDENTITY_INSERT [dbo].[VendorRegionStateProvince] ON
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (1, 1, 4)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (2, 1, 14)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (3, 1, 16)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (4, 1, 17)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (5, 1, 19)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (6, 1, 24)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (7, 1, 25)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (8, 1, 26)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (9, 1, 28)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (10, 1, 35)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (11, 1, 37)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (12, 1, 42)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (13, 1, 44)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (14, 1, 50)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (15, 2, 2)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (16, 2, 3)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (17, 2, 5)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (18, 2, 6)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (19, 2, 12)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (20, 2, 13)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (21, 2, 27)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (22, 2, 29)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (23, 2, 32)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (24, 2, 38)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (25, 2, 45)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (26, 2, 48)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (27, 2, 51)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (28, 3, 1)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (29, 3, 10)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (30, 3, 11)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (31, 3, 34)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (32, 3, 41)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (33, 3, 43)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (34, 4, 7)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (35, 4, 8)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (36, 4, 15)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (37, 4, 18)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (38, 4, 20)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (39, 4, 21)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (40, 4, 22)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (41, 4, 23)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (42, 4, 30)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (43, 4, 31)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (44, 4, 33)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (45, 4, 36)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (46, 4, 39)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (47, 4, 40)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (48, 4, 46)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (49, 4, 47)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (50, 4, 49)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (51, 5, 63)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (52, 5, 64)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (53, 5, 65)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (54, 5, 66)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (55, 5, 67)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (56, 5, 68)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (57, 5, 69)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (58, 5, 70)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (59, 5, 71)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (60, 5, 72)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (61, 5, 73)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (62, 5, 74)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (63, 5, 75)
INSERT [dbo].[VendorRegionStateProvince] ([ID], [VendorRegionID], [StateProvinceID]) VALUES (64, 6, 55)
SET IDENTITY_INSERT [dbo].[VendorRegionStateProvince] OFF
GO

-- Vendor Region Phone Numbers
INSERT INTO [DMS_TEST].[dbo].[PhoneEntity]
           ([EntityID],[RecordID],[PhoneTypeID],[PhoneNumber],[IndexPhoneNumber],[Sequence],[CreateBatchID],[CreateDate],[CreateBy])
     VALUES
           ((SELECT ID FROM Entity WHERE Name = 'VendorRegion'),1,(SELECT ID FROM PhoneType WHERE Name = 'Office'),'1 4695245314',NULL,0,NULL,GETDATE(),'System')

INSERT INTO [DMS_TEST].[dbo].[PhoneEntity]
           ([EntityID],[RecordID],[PhoneTypeID],[PhoneNumber],[IndexPhoneNumber],[Sequence],[CreateBatchID],[CreateDate],[CreateBy])
     VALUES
           ((SELECT ID FROM Entity WHERE Name = 'VendorRegion'),2,(SELECT ID FROM PhoneType WHERE Name = 'Office'),'1 4695245315',NULL,0,NULL,GETDATE(),'System')

INSERT INTO [DMS_TEST].[dbo].[PhoneEntity]
           ([EntityID],[RecordID],[PhoneTypeID],[PhoneNumber],[IndexPhoneNumber],[Sequence],[CreateBatchID],[CreateDate],[CreateBy])
     VALUES
           ((SELECT ID FROM Entity WHERE Name = 'VendorRegion'),3,(SELECT ID FROM PhoneType WHERE Name = 'Office'),'1 4695245316',NULL,0,NULL,GETDATE(),'System')

INSERT INTO [DMS_TEST].[dbo].[PhoneEntity]
           ([EntityID],[RecordID],[PhoneTypeID],[PhoneNumber],[IndexPhoneNumber],[Sequence],[CreateBatchID],[CreateDate],[CreateBy])
     VALUES
           ((SELECT ID FROM Entity WHERE Name = 'VendorRegion'),4,(SELECT ID FROM PhoneType WHERE Name = 'Office'),'1 4695245317',NULL,0,NULL,GETDATE(),'System')

INSERT INTO [DMS_TEST].[dbo].[PhoneEntity]
           ([EntityID],[RecordID],[PhoneTypeID],[PhoneNumber],[IndexPhoneNumber],[Sequence],[CreateBatchID],[CreateDate],[CreateBy])
     VALUES
           ((SELECT ID FROM Entity WHERE Name = 'VendorRegion'),5,(SELECT ID FROM PhoneType WHERE Name = 'Office'),'1 4695245315',NULL,0,NULL,GETDATE(),'System')

INSERT INTO [DMS_TEST].[dbo].[PhoneEntity]
           ([EntityID],[RecordID],[PhoneTypeID],[PhoneNumber],[IndexPhoneNumber],[Sequence],[CreateBatchID],[CreateDate],[CreateBy])
     VALUES
           ((SELECT ID FROM Entity WHERE Name = 'VendorRegion'),6,(SELECT ID FROM PhoneType WHERE Name = 'Office'),'1 4695245316',NULL,0,NULL,GETDATE(),'System')
GO


/* Client Billing related changes */
ALTER TABLE [dbo].[Client]
    ADD [AccountingSystemCustomerNumber] nvarchar(7) NULL,
            [AccountingSystemAddressCode] nvarchar(4) NULL;
GO
 
ALTER TABLE [dbo].[Product]
    ADD [AccountingSystemGLCode] nvarchar(50) NULL;
GO
 
ALTER TABLE [dbo].[ServiceRequest]
    ADD [AccountingInvoiceBatchID] nvarchar(50) NULL;
GO
 
ALTER TABLE [dbo].[PurchaseOrder]
    ADD [AccountingInvoiceBatchID] nvarchar(50) NULL;
GO
 
ALTER TABLE [dbo].[Claim]
    ADD [AccountingInvoiceBatchID] nvarchar(50) NULL;
GO
 
ALTER TABLE [dbo].[VendorInvoice]
    ADD [AccountingInvoiceBatchID] nvarchar(50) NULL;
GO
