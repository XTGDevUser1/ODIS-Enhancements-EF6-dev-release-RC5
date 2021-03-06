/****** Object:  Table [dbo].[DispatchGPSNetwork]    Script Date: 1/28/2016 11:35:12 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DispatchGPSNetwork](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NULL,
	[Description] [nvarchar](255) NULL,
	[Sequence] [int] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_DispatchGPSNetwork] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DispatchSoftwareProduct]    Script Date: 1/28/2016 11:35:12 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DispatchSoftwareProduct](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[VendorName] [nvarchar](100) NULL,
	[SoftwareName] [nvarchar](100) NULL,
	[Description] [nvarchar](255) NULL,
	[Sequence] [int] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_DispatchSoftwareProduct] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE Vendor 
ADD DispatchSoftwareProductID INT NULL

ALTER TABLE Vendor
ADD DispatchSoftwareProductOther nvarchar(255) NULL

ALTER TABLE Vendor
ADD DriverSoftwareProductID INT NULL

ALTER TABLE Vendor
ADD DispatchGPSNetworkID INT NULL

ALTER TABLE [dbo].[Vendor]  WITH CHECK ADD  CONSTRAINT [FK_Vendor_DispatchSoftwareProduct] FOREIGN KEY([DispatchSoftwareProductID])
REFERENCES [dbo].[DispatchSoftwareProduct] ([ID])
GO
ALTER TABLE [dbo].[Vendor] CHECK CONSTRAINT [FK_Vendor_DispatchSoftwareProduct]
GO

ALTER TABLE [dbo].[Vendor]  WITH CHECK ADD  CONSTRAINT [FK_Vendor_DriverSoftwareProduct] FOREIGN KEY([DriverSoftwareProductID])
REFERENCES [dbo].[DispatchSoftwareProduct] ([ID])
GO
ALTER TABLE [dbo].[Vendor] CHECK CONSTRAINT [FK_Vendor_DriverSoftwareProduct]
GO


ALTER TABLE [dbo].[Vendor]  WITH CHECK ADD  CONSTRAINT [FK_Vendor_DispatchGPSNetwork] FOREIGN KEY([DispatchGPSNetworkID])
REFERENCES [dbo].[DispatchGPSNetwork] ([ID])
GO
ALTER TABLE [dbo].[Vendor] CHECK CONSTRAINT [FK_Vendor_DispatchGPSNetwork]
GO


IF NOT EXISTS(SELECT * FROM [DispatchSoftwareProduct] where VendorName ='Beacon Software Company'AND SoftwareName ='Dispatch Anywhere')
BEGIN
	INSERT INTO [DispatchSoftwareProduct] VALUES(
		'Beacon Software Company',
		'Dispatch Anywhere',
		'Dispatch Anywhere',
		1,
		1
	)
END

IF NOT EXISTS(SELECT * FROM [DispatchSoftwareProduct] where VendorName ='Towbook' AND SoftwareName ='Towbook')
BEGIN
	INSERT INTO [DispatchSoftwareProduct] VALUES(
		'Towbook',
		'Towbook',
		'Towbook',
		2,
		1
	)
END

IF NOT EXISTS(SELECT * FROM [DispatchSoftwareProduct] where VendorName ='Ranger SST' AND SoftwareName = 'SmartDispatch')
BEGIN
	INSERT INTO [DispatchSoftwareProduct] VALUES(
		'Ranger SST',
		'SmartDispatch',
		'Smart Dispatch',
		3,
		1
	)
END

IF NOT EXISTS(SELECT * FROM [DispatchSoftwareProduct] where VendorName ='Other' AND SoftwareName = 'Other')
BEGIN
	INSERT INTO [DispatchSoftwareProduct] VALUES(
		'Other',
		'Other',
		'Other',
		4,
		0
	)
END

IF NOT EXISTS(SELECT * FROM [DispatchGPSNetwork] where Name='TomTom')
BEGIN
	INSERT INTO [DispatchGPSNetwork] VALUES
	(
		'TomTom',
		'TomTom',
		1,
		1
	)
END

IF NOT EXISTS(SELECT * FROM [DispatchGPSNetwork] where Name='Teletrac')
BEGIN
	INSERT INTO [DispatchGPSNetwork] VALUES
	(
		'Teletrac',
		'Teletrac',
		2,
		1
	)
END

IF NOT EXISTS(SELECT * FROM [DispatchGPSNetwork] where Name='US Fleet')
BEGIN
	INSERT INTO [DispatchGPSNetwork] VALUES
	(
		'US Fleet',
		'US Fleet',
		3,
		1
	)
END