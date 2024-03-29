
/****** Object:  Table [dbo].[ProgramServiceEventLimit]    Script Date: 03/28/2014 13:13:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProgramServiceEventLimit]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[ProgramServiceEventLimit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ProgramID] [int] NULL,
	[ProductCategoryID] [int] NULL,
	[ProductID] [int] NULL,
	[VehicleTypeID] [int] NULL,
	[VehicleCategoryID] [int] NULL,
	[Description] [nvarchar](255) NULL,
	[Limit] [int] NULL,
	[LimitDuration] [int] NULL,
	[LimitDurationUOM] [nvarchar](50) NULL,
	[IsActive] [bit] NOT NULL
) ON [PRIMARY]


SET IDENTITY_INSERT [dbo].[ProgramServiceEventLimit] ON
INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive]) VALUES (1, 3, 1, NULL, NULL, NULL, N'1 Tow (any vehicle class) every 12 months', 1, 12, N'Month', 1)
INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive]) VALUES (2, 3, 3, NULL, NULL, NULL, N'1 Lockout (Basic or Locksmith) every 12 months', 3, 1, N'Month', 1)
INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive]) VALUES (3, 3, NULL, NULL, NULL, NULL, N'10 Total service events every 12 months ', 10, 12, N'Month', 1)
INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive]) VALUES (5, 3, NULL, 6, NULL, NULL, N'1 LD Jump Start events every 12 months ', 1, 12, N'Month', 0)
SET IDENTITY_INSERT [dbo].[ProgramServiceEventLimit] OFF
END
GO


DECLARE @ProgramID INT = NULL

SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford QFC')

IF ( @ProgramID IS NOT NULL )
BEGIN
	
	IF NOT EXISTS (	SELECT * 
				FROM	ProgramConfiguration 
				WHERE	Name = 'VehicleLicenseStateRequired' 
				AND		ProgramID =  @ProgramID )
	BEGIN

		INSERT INTO ProgramConfiguration (	ProgramID,
											ConfigurationTypeID,
											ConfigurationCategoryID,
											Name,
											Value,
											IsActive,
											CreateDate,
											CreateBy )
		SELECT	@ProgramID,
				(SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle'),
				(SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'),
				'VehicleLicenseStateRequired',
				'Yes',
				1,
				GETDATE(),
				'system'

	END

	IF NOT EXISTS (	SELECT * 
				FROM	ProgramConfiguration 
				WHERE	Name = 'VehicleLicenseNumberRequired' 
				AND		ProgramID =  @ProgramID )
	BEGIN

		INSERT INTO ProgramConfiguration (	ProgramID,
											ConfigurationTypeID,
											ConfigurationCategoryID,
											Name,
											Value,
											IsActive,
											CreateDate,
											CreateBy )
		SELECT	@ProgramID,
				(SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle'),
				(SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'),
				'VehicleLicenseNumberRequired',
				'Yes',
				1,
				GETDATE(),
				'system'

	END

END
