--
-- SCRIPT 
-- Creates ClientToCompanyMap table and all related items
-- Create Table
-- Insert new clients
-- Insert map records

---------------------------------------
-- Create table

GO

/****** Object:  Table [dbo].[ClientToCompanyMap]    Script Date: 01/26/2016 22:21:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ClientToCompanyMap](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ClientID] [int] NULL,
	[CompanyID] [int] NULL,
 CONSTRAINT [PK_ClientToCompanyMap] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[ClientToCompanyMap]  WITH CHECK ADD  CONSTRAINT [FK_ClientToCompanyMap_Client] FOREIGN KEY([ClientID])
REFERENCES [dbo].[Client] ([ID])
GO

ALTER TABLE [dbo].[ClientToCompanyMap] CHECK CONSTRAINT [FK_ClientToCompanyMap_Client]
GO



---------------------------------------------
-- Setup Clients

IF NOT EXISTS (SELECT * FROM Client WHERE Name = 'MyAutoLoan')
BEGIN
	INSERT Client (Name, Description, IsActive, CreateDate, CreateBy, ModifyDate, ModifyBy, AccountingSystemCustomerNumber, AccountingSystemAddressCode, PaymentBalance, AccountingSystemDivisionCode, ClientTypeID, Website, MainContactFirstName, MainContactLastName, MainContactPhone, MainContactEmail, ClientRepID, FTPFolder, Avatar)
	VALUES ('MyAutoLoan', NULL,	1, getdate(), 'System', NULL, NULL, 'MAL', NULL, NULL, 0, 2, 'myautoloan.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL)
END

IF NOT EXISTS (SELECT * FROM Client WHERE Name = 'YouDecide.com, Inc')
BEGIN
	INSERT Client (Name, Description, IsActive, CreateDate, CreateBy, ModifyDate, ModifyBy, AccountingSystemCustomerNumber, AccountingSystemAddressCode, PaymentBalance, AccountingSystemDivisionCode, ClientTypeID, Website, MainContactFirstName, MainContactLastName, MainContactPhone, MainContactEmail, ClientRepID, FTPFolder, Avatar)
	VALUES ('YouDecide.com, Inc', NULL,	1, getdate(), 'System', NULL, NULL, 'YDI', NULL, NULL, 0, 2, 'youdecide.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL)
END

IF NOT EXISTS (SELECT * FROM Client WHERE Name = 'Benefit Hub')
BEGIN
	INSERT Client (Name, Description, IsActive, CreateDate, CreateBy, ModifyDate, ModifyBy, AccountingSystemCustomerNumber, AccountingSystemAddressCode, PaymentBalance, AccountingSystemDivisionCode, ClientTypeID, Website, MainContactFirstName, MainContactLastName, MainContactPhone, MainContactEmail, ClientRepID, FTPFolder, Avatar)
	VALUES ('Benefit Hub', NULL,	1, getdate(), 'System', NULL, NULL, 'BHUB', NULL, NULL, 0, 2, 'benefithub.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL)
END

IF NOT EXISTS (SELECT * FROM Client WHERE Name = 'Walmart / Sam''s Club')
BEGIN
	INSERT Client (Name, Description, IsActive, CreateDate, CreateBy, ModifyDate, ModifyBy, AccountingSystemCustomerNumber, AccountingSystemAddressCode, PaymentBalance, AccountingSystemDivisionCode, ClientTypeID, Website, MainContactFirstName, MainContactLastName, MainContactPhone, MainContactEmail, ClientRepID, FTPFolder, Avatar)
	VALUES ('Walmart / Sam''s Club', NULL,	1, getdate(), 'System', NULL, NULL, 'WAL', NULL, NULL, 0, 2, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL)
END

IF NOT EXISTS (SELECT * FROM Client WHERE Name = 'PerkSpot')
BEGIN
	INSERT Client (Name, Description, IsActive, CreateDate, CreateBy, ModifyDate, ModifyBy, AccountingSystemCustomerNumber, AccountingSystemAddressCode, PaymentBalance, AccountingSystemDivisionCode, ClientTypeID, Website, MainContactFirstName, MainContactLastName, MainContactPhone, MainContactEmail, ClientRepID, FTPFolder, Avatar)
	VALUES ('PerkSpot', NULL,	1, getdate(), 'System', NULL, NULL, 'PRK', NULL, NULL, 0, 2, 'perkspot.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL)
END

IF NOT EXISTS (SELECT * FROM Client WHERE Name = 'Abenity')
BEGIN
	INSERT Client (Name, Description, IsActive, CreateDate, CreateBy, ModifyDate, ModifyBy, AccountingSystemCustomerNumber, AccountingSystemAddressCode, PaymentBalance, AccountingSystemDivisionCode, ClientTypeID, Website, MainContactFirstName, MainContactLastName, MainContactPhone, MainContactEmail, ClientRepID, FTPFolder, Avatar)
	VALUES ('Abenity', NULL,	1, getdate(), 'System', NULL, NULL, 'ABE', NULL, NULL, 0, 2, 'abenity.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL)
END

------------------------------
-- Setup ClientToCompanyMap

IF NOT EXISTS (SELECT * FROM ClientToCompanyMap WHERE ClientID = (SELECT ID FROM Client WHERE Name = 'MyAutoLoan') AND CompanyID = (SELECT ID FROM MTSServer.Aptify.dbo.Company WHERE Name = 'MyAutoLoan') )
BEGIN
	INSERT ClientToCompanyMap (ClientID, CompanyID)
	VALUES ((SELECT ID FROM Client WHERE Name = 'MyAutoLoan'),  (SELECT ID FROM MTSServer.Aptify.dbo.Company WHERE Name = 'MyAutoLoan'))
END

IF NOT EXISTS (SELECT * FROM ClientToCompanyMap WHERE ClientID = (SELECT ID FROM Client WHERE Name = 'YouDecide.com, Inc') AND CompanyID = (SELECT ID FROM MTSServer.Aptify.dbo.Company WHERE Name = 'YouDecide.com, Inc') )
BEGIN
	INSERT ClientToCompanyMap (ClientID, CompanyID)
	VALUES ((SELECT ID FROM Client WHERE Name = 'YouDecide.com, Inc'), (SELECT ID FROM MTSServer.Aptify.dbo.Company WHERE Name = 'YouDecide.com, Inc'))
END

IF NOT EXISTS (SELECT * FROM ClientToCompanyMap WHERE ClientID = (SELECT ID FROM Client WHERE Name = 'Benefit Hub') AND CompanyID = (SELECT ID FROM MTSServer.Aptify.dbo.Company WHERE Name = 'Benefit Hub') )
BEGIN
	INSERT ClientToCompanyMap (ClientID, CompanyID)
	VALUES ((SELECT ID FROM Client WHERE Name = 'Benefit Hub'), (SELECT ID FROM MTSServer.Aptify.dbo.Company WHERE Name = 'Benefit Hub'))
END

IF NOT EXISTS (SELECT * FROM ClientToCompanyMap WHERE ClientID = (SELECT ID FROM Client WHERE Name = 'Walmart / Sam''s Club') AND CompanyID = (SELECT ID FROM MTSServer.Aptify.dbo.Company WHERE Name = 'Walmart / Sam''s Club') )
BEGIN
	INSERT ClientToCompanyMap (ClientID, CompanyID)
	VALUES ((SELECT ID FROM Client WHERE Name = 'Walmart / Sam''s Club'), (SELECT ID FROM MTSServer.Aptify.dbo.Company WHERE Name = 'Walmart / Sam''s Club'))
END

IF NOT EXISTS (SELECT * FROM ClientToCompanyMap WHERE ClientID = (SELECT ID FROM Client WHERE Name = 'PerkSpot') AND CompanyID = (SELECT ID FROM MTSServer.Aptify.dbo.Company WHERE Name = 'PerkSpot') )
BEGIN
	INSERT ClientToCompanyMap (ClientID, CompanyID)
	VALUES ((SELECT ID FROM Client WHERE Name = 'PerkSpot'), (SELECT ID FROM MTSServer.Aptify.dbo.Company WHERE Name = 'PerkSpot'))
END

IF NOT EXISTS (SELECT * FROM ClientToCompanyMap WHERE ClientID = (SELECT ID FROM Client WHERE Name = 'Abenity') AND CompanyID = (SELECT ID FROM MTSServer.Aptify.dbo.Company WHERE Name = 'Abenity') )
BEGIN
	INSERT ClientToCompanyMap (ClientID, CompanyID)
	VALUES ((SELECT ID FROM Client WHERE Name = 'Abenity'), (SELECT ID FROM MTSServer.Aptify.dbo.Company WHERE Name = 'Abenity'))
END


DECLARE @requireVehicleVINPC NVARCHAR(100) = 'RequireVehicleVIN'
DECLARE @requireVehicleYearPC NVARCHAR(100) = 'RequireVehicleYear'
DECLARE @requireVehicleMakePC NVARCHAR(100) = 'RequireVehicleMake'
DECLARE @requireVehicleModelPC NVARCHAR(100) = 'RequireVehicleModel'
DECLARE @requireVehiclePC NVARCHAR(100) = 'RequireVehicle'

DECLARE @programID INT = (SELECT ID FROM Program where Name = 'NMC')

DECLARE @validationConfigurationCategory INT = (SELECT ID FROM ConfigurationCategory where Name='Validation')
DECLARE @registerMemberConfigurationType INT = (SELECT ID FROM ConfigurationType where Name = 'RegisterMember')
IF NOT EXISTS(SELECT * FROM ProgramConfiguration where Name=@requireVehiclePC AND ProgramID = @programID AND ConfigurationCategoryID = @validationConfigurationCategory AND ConfigurationTypeID = @registerMemberConfigurationType)
BEGIN
	INSERT INTO ProgramConfiguration VALUES
	(
		@programID,
		@registerMemberConfigurationType,
		@validationConfigurationCategory,
		NULL,
		NULL,
		@requireVehiclePC,
		'Yes',
		1,
		1,
		GETDATE(),
		'system',
		NULL,
		NULL
	)
END
IF NOT EXISTS(SELECT * FROM ProgramConfiguration where Name=@requireVehicleVINPC AND ProgramID = @programID AND ConfigurationCategoryID = @validationConfigurationCategory AND ConfigurationTypeID = @registerMemberConfigurationType)
BEGIN
	INSERT INTO ProgramConfiguration VALUES
	(
		@programID,
		@registerMemberConfigurationType,
		@validationConfigurationCategory,
		NULL,
		NULL,
		@requireVehicleVINPC,
		'Yes',
		1,
		1,
		GETDATE(),
		'system',
		NULL,
		NULL
	)
END
IF NOT EXISTS(SELECT * FROM ProgramConfiguration where Name=@requireVehicleYearPC AND ProgramID = @programID AND ConfigurationCategoryID = @validationConfigurationCategory AND ConfigurationTypeID = @registerMemberConfigurationType)
BEGIN
	INSERT INTO ProgramConfiguration VALUES
	(
		@programID,
		@registerMemberConfigurationType,
		@validationConfigurationCategory,
		NULL,
		NULL,
		@requireVehicleYearPC,
		'Yes',
		1,
		1,
		GETDATE(),
		'system',
		NULL,
		NULL
	)
END

IF NOT EXISTS(SELECT * FROM ProgramConfiguration where Name=@requireVehicleMakePC AND ProgramID = @programID AND ConfigurationCategoryID = @validationConfigurationCategory AND ConfigurationTypeID = @registerMemberConfigurationType)
BEGIN
	INSERT INTO ProgramConfiguration VALUES
	(
		@programID,
		@registerMemberConfigurationType,
		@validationConfigurationCategory,
		NULL,
		NULL,
		@requireVehicleMakePC,
		'Yes',
		1,
		1,
		GETDATE(),
		'system',
		NULL,
		NULL
	)
END

IF NOT EXISTS(SELECT * FROM ProgramConfiguration where Name=@requireVehicleModelPC AND ProgramID = @programID AND ConfigurationCategoryID = @validationConfigurationCategory AND ConfigurationTypeID = @registerMemberConfigurationType)
BEGIN
	INSERT INTO ProgramConfiguration VALUES
	(
		@programID,
		@registerMemberConfigurationType,
		@validationConfigurationCategory,
		NULL,
		NULL,
		@requireVehicleModelPC,
		'Yes',
		1,
		1,
		GETDATE(),
		'system',
		NULL,
		NULL
	)
END

SET @programID = (SELECT ID FROM Program where Name = 'Ford')
IF NOT EXISTS(SELECT * FROM ProgramConfiguration where Name=@requireVehiclePC AND ProgramID = @programID AND ConfigurationCategoryID = @validationConfigurationCategory AND ConfigurationTypeID = @registerMemberConfigurationType)
BEGIN
	INSERT INTO ProgramConfiguration VALUES
	(
		@programID,
		@registerMemberConfigurationType,
		@validationConfigurationCategory,
		NULL,
		NULL,
		@requireVehiclePC,
		'Yes',
		1,
		1,
		GETDATE(),
		'system',
		NULL,
		NULL
	)
END
IF NOT EXISTS(SELECT * FROM ProgramConfiguration where Name=@requireVehicleVINPC AND ProgramID = @programID AND ConfigurationCategoryID = @validationConfigurationCategory AND ConfigurationTypeID = @registerMemberConfigurationType)
BEGIN
	INSERT INTO ProgramConfiguration VALUES
	(
		@programID,
		@registerMemberConfigurationType,
		@validationConfigurationCategory,
		NULL,
		NULL,
		@requireVehicleVINPC,
		'Yes',
		1,
		1,
		GETDATE(),
		'system',
		NULL,
		NULL
	)
END
IF NOT EXISTS(SELECT * FROM ProgramConfiguration where Name=@requireVehicleYearPC AND ProgramID = @programID AND ConfigurationCategoryID = @validationConfigurationCategory AND ConfigurationTypeID = @registerMemberConfigurationType)
BEGIN
	INSERT INTO ProgramConfiguration VALUES
	(
		@programID,
		@registerMemberConfigurationType,
		@validationConfigurationCategory,
		NULL,
		NULL,
		@requireVehicleYearPC,
		'Yes',
		1,
		1,
		GETDATE(),
		'system',
		NULL,
		NULL
	)
END

IF NOT EXISTS(SELECT * FROM ProgramConfiguration where Name=@requireVehicleMakePC AND ProgramID = @programID AND ConfigurationCategoryID = @validationConfigurationCategory AND ConfigurationTypeID = @registerMemberConfigurationType)
BEGIN
	INSERT INTO ProgramConfiguration VALUES
	(
		@programID,
		@registerMemberConfigurationType,
		@validationConfigurationCategory,
		NULL,
		NULL,
		@requireVehicleMakePC,
		'Yes',
		1,
		1,
		GETDATE(),
		'system',
		NULL,
		NULL
	)
END

IF NOT EXISTS(SELECT * FROM ProgramConfiguration where Name=@requireVehicleModelPC AND ProgramID = @programID AND ConfigurationCategoryID = @validationConfigurationCategory AND ConfigurationTypeID = @registerMemberConfigurationType)
BEGIN
	INSERT INTO ProgramConfiguration VALUES
	(
		@programID,
		@registerMemberConfigurationType,
		@validationConfigurationCategory,
		NULL,
		NULL,
		@requireVehicleModelPC,
		'Yes',
		1,
		1,
		GETDATE(),
		'system',
		NULL,
		NULL
	)
END