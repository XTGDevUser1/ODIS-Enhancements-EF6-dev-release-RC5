/* Member - Db changes */

ALTER TABLE Membership
ADD Note NVARCHAR(2000) NULL
GO

ALTER TABLE Membership
ADD SourceSystemID INT NULL
GO


ALTER TABLE [dbo].[Membership]  WITH CHECK ADD  CONSTRAINT [FK__Membership__SourceSystem] FOREIGN KEY([SourceSystemID])
REFERENCES [dbo].[SourceSystem] ([ID])
GO

ALTER TABLE [dbo].[Membership] CHECK CONSTRAINT [FK__Membership__SourceSystem]
GO

ALTER TABLE Member
ADD ProgramReference NVARCHAR(50) NULL
GO

ALTER TABLE Member
ADD SourceSystemID INT NULL
GO

ALTER TABLE Member
DROP COLUMN MemberNumber
GO

ALTER TABLE [dbo].[Member]  WITH CHECK ADD  CONSTRAINT [FK__Member__SourceSystem] FOREIGN KEY([SourceSystemID])
REFERENCES [dbo].[SourceSystem] ([ID])
GO

ALTER TABLE [dbo].[Member] CHECK CONSTRAINT [FK__Member__SourceSystem]
GO


ALTER TABLE MembershipBlackListVendor
ADD 
IsActive bit null,
CreateDate datetime null,
CreateBy nvarchar(50)null,
ModifyDate datetime null,
ModifyBy nvarchar(50)null

GO

INSERT INTO [dbo].[EventCategory]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('Maintenance', 'Maintenance', NULL, 1)
GO


INSERT INTO [dbo].[Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES
           (2, 10, 'AddMembership', 'Add Membership', 0, 1, 'system', '8/11/2013')
GO

INSERT INTO [dbo].[Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES
           (2, 10, 'UpdateMembership', 'Update Membership', 0, 1, 'system', '8/11/2013')
GO
INSERT INTO [dbo].[Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
			,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES
           (2, 10, 'AddVehicle', 'Add Vehicle', 0, 1, 'system', '8/11/2013')
GO

INSERT INTO [dbo].[Event]
				([EventTypeID]
				,[EventCategoryID]
				,[Name]
				,[Description]
				,[IsShownOnScreen]
				,[IsActive]
				,[CreateBy]
				,[CreateDate])
VALUES
(2, 10, 'AddMember', 'Add Member', 0, 1, 'system', '8/11/2013')
GO



