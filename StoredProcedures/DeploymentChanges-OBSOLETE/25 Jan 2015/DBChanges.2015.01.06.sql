DROP TABLE MemberProduct

CREATE TABLE [dbo].[MemberProduct](
	[ID] [bigint] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[MembershipID] INT NOT NULL References MemberShip(ID),
	[MemberID] [int] NULL REFERENCES Member(ID),
	[ProductID] [int] NOT NULL REFERENCES Product(ID),
	[ProductProviderID] [int] NULL REFERENCES ProductProvider(ID),
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[ContractNumber] nvarchar(50) NULL,
	[VIN] nvarchar(50) NULL,
	CreateDate	DATETIME NULL,
	CreateBy	NVARCHAR(50) NULL,
	ModifyDate	DATETIME NULL,
	ModifyBy	NVARCHAR(50) NULL)


	
