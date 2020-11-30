--
-- SCRIPT for setting up Coach-Net Dealer Partner logic
--

IF NOT EXISTS (SELECT * FROM Product WHERE Name = 'CoachNet Dealer Partner')
	BEGIN
		INSERT [dbo].[Product]
			( [ProductCategoryID]
			, [ProductTypeID]
			, [ProductSubTypeID]
			, [VehicleTypeID]
			, [VehicleCategoryID]
			, [Name]
			, [Description]
			, [Sequence]
			, [IsActive]
			, [CreateDate]
			, [CreateBy]
			, [ModifyDate]
			, [ModifyBy]
			, [IsShowOnPO]
			, [AccountingSystemGLCode]
			, [AccountingSystemItemCode]
			)
		VALUES
			( 
			 (SELECT ID FROM ProductCategory WHERE Name = 'Repair')
			, (SELECT ID FROM ProductType WHERE Name = 'Attribute')
			, (SELECT ID FROM ProductSubType WHERE Name = 'Client')
			, NULL
			, NULL
			, 'CoachNet Dealer Partner'
			, 'CoachNet Dealer Partner'
			, 0
			, 1
			, getdate()
			, 'System'
			, NULL
			, NULL
			, 0
			, NULL
			, NULL
			)
	END
GO


-- Add program configuration item 
DECLARE @ProgramID INT
SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Coach-Net')

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'ServiceLocationPreferredProduct')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID
			, (SELECT ID FROM ConfigurationType WHERE Name = 'Application')
			, (SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation')
			, NULL
			, NULL
			, 'ServiceLocationPreferredProduct'
			, (SELECT ID FROM Product WHERE Name = 'CoachNet Dealer Partner')
			, 1
			, 1
			, getdate()
			, 'System'
			, NULL
			, NULL
			)
	END
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[zCoachNetDealerPartner_List]') AND type in (N'U'))
CREATE TABLE [dbo].[zCoachNetDealerPartner_List](
	[VendorID] [int] NULL,
	[VendorNumber] [nvarchar](50) NULL,
	[Name] [nvarchar](50) NULL,
	[City] [nvarchar](50) NULL,
	[State] [nvarchar](2) NULL
) ON [PRIMARY]

GO

--Service request locked comments
IF NOT EXISTS (SELECT * FROM Event WHERE Name = 'LockedRequestComment')
	BEGIN
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
           (
           (SELECT ID FROM EventType WHERE Name = 'User')
           , (SELECT ID FROM EventCategory WHERE Name = 'ServiceRequest')
           , 'LockedRequestComment'
           , 'Locked Request Comment'
           , 1
           , 1
           , 'System'
           , getdate())
	END
GO

-- Add CommentType for Locked Request comment
IF NOT EXISTS (SELECT * FROM CommentType WHERE Name = 'LockedRequest')
	BEGIN
		INSERT INTO [dbo].[CommentType]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
		VALUES
           (
            'LockedRequest'
           , 'Locked Request'
           , 1
           , 1)
	END
GO

	