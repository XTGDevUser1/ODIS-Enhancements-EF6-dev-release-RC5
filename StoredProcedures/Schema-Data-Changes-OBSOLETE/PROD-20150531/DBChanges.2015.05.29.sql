-- ProgramConfiguration
--DELETE FROM ProgramConfiguration WHERE Name = 'TrackRepairStatus'
IF NOT EXISTS(SELECT * FROM ProgramConfiguration WHERE Name = 'TrackRepairStatus')
BEGIN
	DECLARE @programID INT
	SELECT  @programID = ID FROM Program P WHERE P.Name = 'Ford Commercial Truck'
	DECLARE @configurationTypeID INT
	DECLARE @configurationCategoryID INT

	SELECT  @configurationTypeID     = ID FROM ConfigurationType CT WHERE CT.Name = 'Service' 
	SELECT  @configurationCategoryID = ID FROM ConfigurationCategory CC WHERE CC.Name = 'Rule' 

	INSERT INTO ProgramConfiguration(ProgramID,ConfigurationTypeID,ConfigurationCategoryID,Name,Value,IsActive,Sequence,CreateDate,CreateBy) 
	VALUES (@programID,@configurationTypeID,@configurationCategoryID,'TrackRepairStatus','Yes',1,1,GETDATE(),'System')
END

--  Contact Category
IF NOT EXISTS (SELECT * FROM [dbo].[ContactCategory] Where Name = 'ContactServiceLocation')
INSERT INTO [dbo].[ContactCategory]
			   ([Name]
			   ,[Description]
			   ,[IsShownOnFinish]
			   ,[IsActive]
			   ,[Sequence]
			   ,[IsShownOnActivity])
	VALUES
		(
		'ContactServiceLocation'
		,'Contact Service Location'
		,0
		,1
		,NULL
		,1
		)

--  Contact Reason
IF NOT EXISTS (SELECT * FROM [dbo].[ContactReason] Where Name = 'RepairFollowUp' and ContactCategoryID = (Select ID From ContactCategory Where Name = 'ContactServiceLocation'))
INSERT INTO [dbo].[ContactReason]
           ([ContactCategoryID]
           ,[Name]
           ,[Description]
           ,[IsActive]
           ,[IsShownOnScreen]
           ,[Sequence])
VALUES
           ((Select ID From ContactCategory Where Name = 'ContactServiceLocation')
           ,'RepairFollowUp'
           ,'Repair Follow Up'
           ,1
           ,1
           ,NULL)

--  Contact Actions
IF NOT EXISTS (SELECT * FROM [dbo].[ContactAction] Where Name = 'NoAnswer' and ContactCategoryID = (Select ID From ContactCategory Where Name = 'ContactServiceLocation'))
INSERT INTO [dbo].[ContactAction]
           ([ContactCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsTalkedToRequired]
           ,[IsActive]
           ,[Sequence]
           ,[VendorServiceRatingAdjustment])
VALUES
           ((Select ID From ContactCategory Where Name = 'ContactServiceLocation')
           ,'NoAnswer'
           ,'No Answer'
           ,1
           ,0
           ,1
           ,NULL
           ,NULL)

IF NOT EXISTS (SELECT * FROM [dbo].[ContactAction] Where Name = 'UpdatedRepairStatus' and ContactCategoryID = (Select ID From ContactCategory Where Name = 'ContactServiceLocation'))
INSERT INTO [dbo].[ContactAction]
           ([ContactCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsTalkedToRequired]
           ,[IsActive]
           ,[Sequence]
           ,[VendorServiceRatingAdjustment])
VALUES
           ((Select ID From ContactCategory Where Name = 'ContactServiceLocation')
           ,'UpdatedRepairStatus'
           ,'Updated Repair Status'
           ,1
           ,1
           ,1
           ,NULL
           ,NULL)

--[ProgramDataItemLink]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProgramDataItemLink]') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[ProgramDataItemLink](
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[ProgramDataItemID] [int] NOT NULL,
		[ParentProgramDataItemID] [int] NOT NULL,
		[ProgramDataItemValueID] [int] NULL,
		[Sequence] [int] NULL,
		[IsActive] [bit] NOT NULL,
	 CONSTRAINT [PK_ProgramDataItemLink] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK__ProgramDataItemLink_ParentProgramDataItem]') AND parent_object_id = OBJECT_ID(N'[dbo].[ProgramDataItemLink]'))
	ALTER TABLE [dbo].[ProgramDataItemLink]  WITH NOCHECK ADD  CONSTRAINT [FK__ProgramDataItemLink_ParentProgramDataItem] FOREIGN KEY([ParentProgramDataItemID])
	REFERENCES [dbo].[ProgramDataItem] ([ID])
	IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK__ProgramDataItemLink_ParentProgramDataItem]') AND parent_object_id = OBJECT_ID(N'[dbo].[ProgramDataItemLink]'))
	ALTER TABLE [dbo].[ProgramDataItemLink] NOCHECK CONSTRAINT [FK__ProgramDataItemLink_ParentProgramDataItem]

	IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK__ProgramDataItemLink_ProgramDataItem]') AND parent_object_id = OBJECT_ID(N'[dbo].[ProgramDataItemLink]'))
	ALTER TABLE [dbo].[ProgramDataItemLink]  WITH NOCHECK ADD  CONSTRAINT [FK__ProgramDataItemLink_ProgramDataItem] FOREIGN KEY([ProgramDataItemID])
	REFERENCES [dbo].[ProgramDataItem] ([ID])
	IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK__ProgramDataItemLink_ProgramDataItem]') AND parent_object_id = OBJECT_ID(N'[dbo].[ProgramDataItemLink]'))
	ALTER TABLE [dbo].[ProgramDataItemLink] NOCHECK CONSTRAINT [FK__ProgramDataItemLink_ProgramDataItem]

	IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK__ProgramDataItemLink_ProgramDataItemValue]') AND parent_object_id = OBJECT_ID(N'[dbo].[ProgramDataItemLink]'))
	ALTER TABLE [dbo].[ProgramDataItemLink]  WITH NOCHECK ADD  CONSTRAINT [FK__ProgramDataItemLink_ProgramDataItemValue] FOREIGN KEY([ProgramDataItemValueID])
	REFERENCES [dbo].[ProgramDataItemValue] ([ID])
	IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK__ProgramDataItemLink_ProgramDataItemValue]') AND parent_object_id = OBJECT_ID(N'[dbo].[ProgramDataItemLink]'))
	ALTER TABLE [dbo].[ProgramDataItemLink] NOCHECK CONSTRAINT [FK__ProgramDataItemLink_ProgramDataItemValue]
END

DECLARE @programDataItemProgramID AS INT
SET     @programDataItemProgramID = (SELECT ID FROM Program P WHERE P.Name = 'Ford Commercial Truck')

IF NOT EXISTS (SELECT * FROM [ProgramDataItem] Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus')
INSERT INTO [dbo].[ProgramDataItem]
           ([ProgramID]
           ,[ControlTypeID]
           ,[DataTypeID]
           ,[ScreenName]
           ,[Name]
           ,[Label]
           ,[MaxLength]
           ,[Sequence]
           ,[IsRequired]
           ,[IsActive]
           ,[CreateDate]
           ,[CreateBy])
VALUES
           ( @programDataItemProgramID
           ,(Select ID From ControlType Where Name = 'Dropdown')
           ,(Select ID From DataType Where Name = 'Text')
           ,'RepairContactLog'
           ,'RepairStatus'
           ,'Repair Status'
           ,50
           ,1
           ,1
           ,1
           ,'5/27/2015'
           ,'system'
			)

IF NOT EXISTS (SELECT * FROM ProgramDataItemValue Where ProgramDataItemID = (Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus') 
	AND Value = 'Pending diagnosis')
INSERT INTO [dbo].[ProgramDataItemValue]
           ([ProgramDataItemID]
           ,[Value]
           ,[Description]
           ,[Sequence]
           ,[CreateDate]
           ,[CreateBy])
VALUES
           ((Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus')
           ,'Pending diagnosis'
           ,'Pending diagnosis'
           ,1
           ,'5/27/2015'
           ,'system'
			)


IF NOT EXISTS (SELECT * FROM ProgramDataItemValue Where ProgramDataItemID = 
(Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus') 
	AND Value = 'Waiting on parts')
INSERT INTO [dbo].[ProgramDataItemValue]
           ([ProgramDataItemID]
           ,[Value]
           ,[Description]
           ,[Sequence]
           ,[CreateDate]
           ,[CreateBy])
VALUES
           ((Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus')
           ,'Waiting on parts'
           ,'Waiting on parts'
           ,2
           ,'5/27/2015'
           ,'system'
			)

IF NOT EXISTS (SELECT * FROM ProgramDataItemValue Where ProgramDataItemID = (Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus') 
	AND Value = 'Pending repair')
INSERT INTO [dbo].[ProgramDataItemValue]
           ([ProgramDataItemID]
           ,[Value]
           ,[Description]
           ,[Sequence]
           ,[CreateDate]
           ,[CreateBy])
VALUES
           ((Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus')
           ,'Pending repair'
           ,'Pending repair'
           ,3
           ,'5/27/2015'
           ,'system'
			)


IF NOT EXISTS (SELECT * FROM ProgramDataItemValue Where ProgramDataItemID = (Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus') 
	AND Value = 'Performing on cost cap analysis')
INSERT INTO [dbo].[ProgramDataItemValue]
           ([ProgramDataItemID]
           ,[Value]
           ,[Description]
           ,[Sequence]
           ,[CreateDate]
           ,[CreateBy])
VALUES
           ((Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus')
           ,'Performing on cost cap analysis'
           ,'Performing on cost cap analysis'
           ,4
           ,'5/27/2015'
           ,'system'
			)

IF NOT EXISTS (SELECT * FROM ProgramDataItemValue Where ProgramDataItemID = (Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus') 
	AND Value = 'Contacted Tech Hot Line')
INSERT INTO [dbo].[ProgramDataItemValue]
           ([ProgramDataItemID]
           ,[Value]
           ,[Description]
           ,[Sequence]
           ,[CreateDate]
           ,[CreateBy])
VALUES
           ((Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus')
           ,'Contacted Tech Hot Line'
           ,'Contacted Tech Hot Line'
           ,5
           ,'5/27/2015'
           ,'system'
			)


IF NOT EXISTS (SELECT * FROM ProgramDataItemValue Where ProgramDataItemID = (Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus') 
	AND Value = 'Repair completed')
INSERT INTO [dbo].[ProgramDataItemValue]
           ([ProgramDataItemID]
           ,[Value]
           ,[Description]
           ,[Sequence]
           ,[CreateDate]
           ,[CreateBy])
VALUES
           ((Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus')
           ,'Repair completed'
           ,'Repair completed'
           ,6
           ,'5/27/2015'
           ,'system'
			)


IF NOT EXISTS (SELECT * FROM [ProgramDataItem] Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'PartsExpedite')
INSERT INTO [dbo].[ProgramDataItem]
           ([ProgramID]
           ,[ControlTypeID]
           ,[DataTypeID]
           ,[ScreenName]
           ,[Name]
           ,[Label]
           ,[MaxLength]
           ,[Sequence]
           ,[IsRequired]
           ,[IsActive]
           ,[CreateDate]
           ,[CreateBy])
VALUES
           (@programDataItemProgramID
           ,(Select ID From ControlType Where Name = 'Dropdown')
           ,(Select ID From DataType Where Name = 'Text')
           ,'RepairContactLog'
           ,'PartsExpedite'
           ,'Submitted parts expedite form?'
           ,10
           ,1
           ,1
           ,1
           ,'5/27/2015'
           ,'system'
			)


IF NOT EXISTS (SELECT * FROM [ProgramDataItem] Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'PartsOnBackorder')
INSERT INTO [dbo].[ProgramDataItem]
           ([ProgramID]
           ,[ControlTypeID]
           ,[DataTypeID]
           ,[ScreenName]
           ,[Name]
           ,[Label]
           ,[MaxLength]
           ,[Sequence]
           ,[IsRequired]
           ,[IsActive]
           ,[CreateDate]
           ,[CreateBy])
VALUES
           (@programDataItemProgramID
           ,(Select ID From ControlType Where Name = 'Dropdown')
           ,(Select ID From DataType Where Name = 'Text')
           ,'RepairContactLog'
           ,'PartsOnBackorder'
           ,'Parts on backorder?'
           ,10
           ,2
           ,1
           ,1
           ,'5/27/2015'
           ,'system'
			)

IF NOT EXISTS (SELECT * FROM [ProgramDataItem] Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'PartsOrdered')
INSERT INTO [dbo].[ProgramDataItem]
           ([ProgramID]
           ,[ControlTypeID]
           ,[DataTypeID]
           ,[ScreenName]
           ,[Name]
           ,[Label]
           ,[MaxLength]
           ,[Sequence]
           ,[IsRequired]
           ,[IsActive]
           ,[CreateDate]
           ,[CreateBy])
VALUES
           (@programDataItemProgramID
           ,(Select ID From ControlType Where Name = 'Combobox')
           ,(Select ID From DataType Where Name = 'Text')
           ,'RepairContactLog'
           ,'PartsOrdered'
           ,'Parts Ordered'
           ,100
           ,3
           ,1
           ,1
           ,'5/27/2015'
           ,'system'
			)

IF NOT EXISTS (SELECT * FROM [ProgramDataItem] Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'TechHotlineReferenceNumber')
INSERT INTO [dbo].[ProgramDataItem]
           ([ProgramID]
           ,[ControlTypeID]
           ,[DataTypeID]
           ,[ScreenName]
           ,[Name]
           ,[Label]
           ,[MaxLength]
           ,[Sequence]
           ,[IsRequired]
           ,[IsActive]
           ,[CreateDate]
           ,[CreateBy])
VALUES
           (@programDataItemProgramID
           ,(Select ID From ControlType Where Name = 'Textbox')
           ,(Select ID From DataType Where Name = 'Text')
           ,'RepairContactLog'
           ,'TechHotlineReferenceNumber'
           ,'Tech Hotline Reference Number'
           ,50
           ,1
           ,1
           ,1
           ,'5/27/2015'
           ,'system'
			)


IF NOT EXISTS (SELECT * FROM [ProgramDataItemLink] Where ProgramDataItemID = (Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'PartsExpedite'))
INSERT INTO [dbo].[ProgramDataItemLink]
           ([ProgramDataItemID]
           ,[ParentProgramDataItemID]
           ,[ProgramDataItemValueID]
           ,[Sequence]
           ,[IsActive])
VALUES
           ((Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'PartsExpedite')
           ,(Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus')
           ,(SELECT ID FROM ProgramDataItemValue Where ProgramDataItemID = 
				(Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus') AND Value = 'Waiting on parts')
           ,1
           ,1)

IF NOT EXISTS (SELECT * FROM [ProgramDataItemLink] Where ProgramDataItemID = (Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'PartsOnBackorder'))
INSERT INTO [dbo].[ProgramDataItemLink]
           ([ProgramDataItemID]
           ,[ParentProgramDataItemID]
           ,[ProgramDataItemValueID]
           ,[Sequence]
           ,[IsActive])
VALUES
           ((Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'PartsOnBackorder')
           ,(Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus')
           ,(SELECT ID FROM ProgramDataItemValue Where ProgramDataItemID = 
				(Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus') AND Value = 'Waiting on parts')
           ,1
           ,1)


IF NOT EXISTS (SELECT * FROM [ProgramDataItemLink] Where ProgramDataItemID = (Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'PartsOrdered'))
INSERT INTO [dbo].[ProgramDataItemLink]
           ([ProgramDataItemID]
           ,[ParentProgramDataItemID]
           ,[ProgramDataItemValueID]
           ,[Sequence]
           ,[IsActive])
VALUES
           ((Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'PartsOrdered')
           ,(Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus')
           ,(SELECT ID FROM ProgramDataItemValue Where ProgramDataItemID = 
				(Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus') AND Value = 'Waiting on parts')
           ,1
           ,1)


IF NOT EXISTS (SELECT * FROM [ProgramDataItemLink] Where ProgramDataItemID = (Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'TechHotlineReferenceNumber'))
INSERT INTO [dbo].[ProgramDataItemLink]
           ([ProgramDataItemID]
           ,[ParentProgramDataItemID]
           ,[ProgramDataItemValueID]
           ,[Sequence]
           ,[IsActive])
VALUES
           ((Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'TechHotlineReferenceNumber')
           ,(Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus')
           ,(SELECT ID FROM ProgramDataItemValue Where ProgramDataItemID = 
				(Select ID From ProgramDataItem Where ProgramID = @programDataItemProgramID AND ScreenName = 'RepairContactLog' AND Name = 'RepairStatus') AND Value = 'Contacted Tech Hot Line')
           ,1
           ,1)


IF NOT EXISTS (SELECT * FROM ContactSource WHERE Name = 'VendorData' AND ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ContactServiceLocation'))
BEGIN
	INSERT INTO ContactSource VALUES ((SELECT ID FROM ContactCategory WHERE Name = 'ContactServiceLocation'),'VendorData','Vendr Data',1,1)
END





/*

Select * from ContactCategory where Name = 'ContactServiceLocation'
Select * From ContactReason where ContactCategoryID = (Select ID from ContactCategory where Name = 'ContactServiceLocation')
Select * From ContactAction where ContactCategoryID = (Select ID from ContactCategory where Name = 'ContactServiceLocation')

Select * from ProgramDataItem where programID = 
 and screenname = 'RepairContactLog'
Select * from ProgramDataItemValue Where ProgramDataItemID = (Select ID from ProgramDataItem where programID = 165 and screenname = 'RepairContactLog' and Name = 'RepairStatus')
 
select ppdi.Name Parent, pdiv.Value ParentValue, pdi.Name ProgramDataItem 
from [dbo].[ProgramDataItemLink] pdil
Join ProgramDataItem pdi on pdil.ProgramDataItemID = pdi.ID
Join ProgramDataItem ppdi on pdil.ParentProgramDataItemID = ppdi.ID
Join ProgramDataItemValue pdiv on pdiv.ID = pdil.ProgramDataItemValueID

*/

