SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ClaimTypeCategory](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ClaimTypeID] [int] NOT NULL,
	[ClaimCategoryID] [int] NOT NULL,
 CONSTRAINT [PK_ClaimTypeCategroy] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[ClaimTypeCategory]  WITH CHECK ADD  CONSTRAINT [FK_ClaimTypeCategory_ClaimCategory] FOREIGN KEY([ClaimCategoryID])
REFERENCES [dbo].[ClaimCategory] ([ID])
GO

ALTER TABLE [dbo].[ClaimTypeCategory] CHECK CONSTRAINT [FK_ClaimTypeCategory_ClaimCategory]
GO

ALTER TABLE [dbo].[ClaimTypeCategory]  WITH CHECK ADD  CONSTRAINT [FK_ClaimTypeCategory_ClaimType] FOREIGN KEY([ClaimTypeID])
REFERENCES [dbo].[ClaimType] ([ID])
GO

ALTER TABLE [dbo].[ClaimTypeCategory] CHECK CONSTRAINT [FK_ClaimTypeCategory_ClaimType]
GO


IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Claim_ClaimCategory]') AND parent_object_id = OBJECT_ID(N'[dbo].[Claim]'))
ALTER TABLE [dbo].[Claim] DROP CONSTRAINT [FK_Claim_ClaimCategory]
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Claim_ClaimType]') AND parent_object_id = OBJECT_ID(N'[dbo].[Claim]'))
ALTER TABLE [dbo].[Claim] DROP CONSTRAINT [FK_Claim_ClaimType]
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_ClaimTypeCategory_ClaimCategory]') AND parent_object_id = OBJECT_ID(N'[dbo].[ClaimTypeCategory]'))
ALTER TABLE [dbo].[ClaimTypeCategory] DROP CONSTRAINT [FK_ClaimTypeCategory_ClaimCategory]
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_ClaimTypeCategory_ClaimType]') AND parent_object_id = OBJECT_ID(N'[dbo].[ClaimTypeCategory]'))
ALTER TABLE [dbo].[ClaimTypeCategory] DROP CONSTRAINT [FK_ClaimTypeCategory_ClaimType]
GO


TRUNCATE TABLE [ClaimTypeCategory]
TRUNCATE TABLE [ClaimCategory]
TRUNCATE TABLE [ClaimType]
GO

SET IDENTITY_INSERT [dbo].[ClaimType] ON
INSERT [dbo].[ClaimType] ([ID], [Name], [Description], [Sequence], [IsActive], [IsFordACES], [AccountingDivisionNumber]) VALUES (1, N'MotorhomeReimbursement', N'Motorhome Reimbursement', 1, 1, 1, NULL)
INSERT [dbo].[ClaimType] ([ID], [Name], [Description], [Sequence], [IsActive], [IsFordACES], [AccountingDivisionNumber]) VALUES (2, N'RoadsideReimbursement', N'Roadside Reimbursement', 2, 1, 0, NULL)
INSERT [dbo].[ClaimType] ([ID], [Name], [Description], [Sequence], [IsActive], [IsFordACES], [AccountingDivisionNumber]) VALUES (3, N'Damage', N'Damage Reimbursement', 3, 1, 0, NULL)
INSERT [dbo].[ClaimType] ([ID], [Name], [Description], [Sequence], [IsActive], [IsFordACES], [AccountingDivisionNumber]) VALUES (4, N'FordQFC', N'Ford QFC', 4, 1, 1, NULL)
SET IDENTITY_INSERT [dbo].[ClaimType] OFF

SET IDENTITY_INSERT [dbo].[ClaimCategory] ON
INSERT [dbo].[ClaimCategory] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (1, N'Warranty Repair', N'Warranty Repair', 1, 1)
INSERT [dbo].[ClaimCategory] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (2, N'DestinationAssistance', N'Destination Assistance', 2, 1)
INSERT [dbo].[ClaimCategory] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (3, N'TravelExpense', N'Travel Expense', 3, 1)
INSERT [dbo].[ClaimCategory] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (4, N'RoadsideService', N'Roadside Service', 8, 1)
INSERT [dbo].[ClaimCategory] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (5, N'CustomerServiceIssue', N'Customer Service Issue', 4, 1)
INSERT [dbo].[ClaimCategory] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (6, N'ISPIssue', N'ISP Issue', 5, 1)
INSERT [dbo].[ClaimCategory] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (7, N'OneTimeException', N'One-Time Member Exception', 6, 1)
INSERT [dbo].[ClaimCategory] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (8, N'VehicleDamage', N'Vehicle Damage', 7, 1)
INSERT [dbo].[ClaimCategory] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (9, N'RoadsideService', N'Roadside Service', 8, 1)
SET IDENTITY_INSERT [dbo].[ClaimCategory] OFF

SET IDENTITY_INSERT [dbo].[ClaimTypeCategory] ON
INSERT [dbo].[ClaimTypeCategory] ([ID], [ClaimTypeID], [ClaimCategoryID]) VALUES (1, 1, 1)
INSERT [dbo].[ClaimTypeCategory] ([ID], [ClaimTypeID], [ClaimCategoryID]) VALUES (2, 1, 2)
INSERT [dbo].[ClaimTypeCategory] ([ID], [ClaimTypeID], [ClaimCategoryID]) VALUES (3, 1, 3)
INSERT [dbo].[ClaimTypeCategory] ([ID], [ClaimTypeID], [ClaimCategoryID]) VALUES (4, 2, 4)
INSERT [dbo].[ClaimTypeCategory] ([ID], [ClaimTypeID], [ClaimCategoryID]) VALUES (5, 2, 2)
INSERT [dbo].[ClaimTypeCategory] ([ID], [ClaimTypeID], [ClaimCategoryID]) VALUES (6, 2, 3)
INSERT [dbo].[ClaimTypeCategory] ([ID], [ClaimTypeID], [ClaimCategoryID]) VALUES (7, 2, 5)
INSERT [dbo].[ClaimTypeCategory] ([ID], [ClaimTypeID], [ClaimCategoryID]) VALUES (8, 2, 6)
INSERT [dbo].[ClaimTypeCategory] ([ID], [ClaimTypeID], [ClaimCategoryID]) VALUES (9, 2, 7)
INSERT [dbo].[ClaimTypeCategory] ([ID], [ClaimTypeID], [ClaimCategoryID]) VALUES (10, 3, 8)
INSERT [dbo].[ClaimTypeCategory] ([ID], [ClaimTypeID], [ClaimCategoryID]) VALUES (11, 4, 4)
SET IDENTITY_INSERT [dbo].[ClaimTypeCategory] OFF
GO

ALTER TABLE [dbo].[Claim]  WITH NOCHECK ADD  CONSTRAINT [FK_Claim_ClaimCategory] FOREIGN KEY([ClaimCategoryID])
REFERENCES [dbo].[ClaimCategory] ([ID])
GO

ALTER TABLE [dbo].[Claim] CHECK CONSTRAINT [FK_Claim_ClaimCategory]
GO

ALTER TABLE [dbo].[Claim]  WITH NOCHECK ADD  CONSTRAINT [FK_Claim_ClaimType] FOREIGN KEY([ClaimTypeID])
REFERENCES [dbo].[ClaimType] ([ID])
GO

ALTER TABLE [dbo].[Claim] CHECK CONSTRAINT [FK_Claim_ClaimType]
GO

ALTER TABLE [dbo].[ClaimTypeCategory]  WITH CHECK ADD  CONSTRAINT [FK_ClaimTypeCategory_ClaimCategory] FOREIGN KEY([ClaimCategoryID])
REFERENCES [dbo].[ClaimCategory] ([ID])
GO

ALTER TABLE [dbo].[ClaimTypeCategory] CHECK CONSTRAINT [FK_ClaimTypeCategory_ClaimCategory]
GO

ALTER TABLE [dbo].[ClaimTypeCategory]  WITH CHECK ADD  CONSTRAINT [FK_ClaimTypeCategory_ClaimType] FOREIGN KEY([ClaimTypeID])
REFERENCES [dbo].[ClaimType] ([ID])
GO

ALTER TABLE [dbo].[ClaimTypeCategory] CHECK CONSTRAINT [FK_ClaimTypeCategory_ClaimType]
GO
