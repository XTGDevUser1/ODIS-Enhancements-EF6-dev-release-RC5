----  Portlet Screen
CREATE TABLE [dbo].[PortletScreen](
	[ID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[Name] [nvarchar](255) NOT NULL,
	[Description] [nvarchar](255))

----  Portlet Section
CREATE TABLE [dbo].[PortletSection](
	[ID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[Name] [nvarchar](255) NOT NULL,
	[AllowDragDrop] [bit] NOT NULL)


CREATE TABLE [dbo].[PortletColumns](
	[ID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[ColumnSizeClass] [nvarchar](50) NULL,
	[PortletSectionID] [int] NULL REFERENCES PortletSection(ID),
	[DisplayOrder] [int] NULL)

---- Portlets
CREATE TABLE [dbo].[Portlet](
	[ID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[PortletScreenID] INT NOT NULL REFERENCES PortletScreen(ID),
	[SecurableID] [int] NULL References Securable(ID),
	[TargetAction] [nvarchar](100) NULL,
	[TargetController] [nvarchar](100) NULL,
	[TargetArea] [nvarchar](100) NULL,
	[ColumnPosition] [int] NULL,
	[RowPosition] [int] NULL,
	[Name] [nvarchar](200) NULL,
	[Description] [nvarchar](200) NULL,
	[IsShownOnSetting] [bit] NULL,
	[PortletSectionID] [int] NULL,
	[Image] [nvarchar](max) NULL)


CREATE TABLE [dbo].[UserPortlet](
	[ID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[AspNetUsersID] uniqueidentifier NULL REFERENCES aspnet_Users(UserId),
	[PortletID] [int] NULL REFERENCES Portlet(ID),
	[ColumnPosition] [int] NULL,
	[RowPosition] [int] NULL,
	[IsActive] [bit] NULL,
	[PortletSectionID] [int] NULL REFERENCES PortletSection(ID))


CREATE TABLE [dbo].[UserPortletDefaultByRole](
	[ID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[RoleID] uniqueidentifier NULL REFERENCES aspnet_Roles(RoleId),
	[PortletSectionID] [int] NULL REFERENCES PortletSection(ID),
	[PortletID] [int] NULL REFERENCES Portlet(ID),
	[ColumnPosition] [int] NULL,
	[RowPosition] [int] NULL)


--SELECT * FROM PortletScreen

INSERT INTO PortletScreen VALUES('Vendor','Vendor Dashboard')

-- SELECT * FROM PortletSection

INSERT INTO PortletSection VALUES('Top',1)
INSERT INTO PortletSection VALUES('Middle',1)
INSERT INTO PortletSection VALUES('Bottom',1)


