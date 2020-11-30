--
-- ODIS
-- Member Products Logic
--


-------------------------------------------------------------------------------------------
-- New tables

-- MemberProduct

SELECT * FROM ProductCategory
SELECT * FROM Product

-- Insert new ProductCategory
IF NOT EXISTS (SELECT * FROM ProductCategory WHERE Name = 'MemberProduct')
BEGIN
	INSERT ProductCategory (Name, Description, Sequence, IsActive, IsVehicleRequired)
	VALUES ('MemberProduct','Member Product',1,1,0)
END

---- Insert new ProductType
--IF NOT EXISTS (SELECT * FROM ProductType WHERE Name = 'MemberProduct')
--BEGIN
--	INSERT ProductType (Name, Description, Sequence, IsActive)
--	VALUES ('MemberProduct','Member Product',3,1)
--END

-- Insert Products
IF NOT EXISTS (SELECT * FROM Product WHERE Name = 'RVProtect')
INSERT INTO [Product]
           ([ProductCategoryID],[ProductTypeID],[ProductSubTypeID],[VehicleTypeID],[VehicleCategoryID],[Name],[Description],[Sequence],[IsActive],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy],[IsShowOnPO],[AccountingSystemGLCode],[AccountingSystemItemCode])
     VALUES
           ( (SELECT ID FROM ProductCategory WHERE Name = 'MemberProduct')
           , NULL, NULL, NULL, NULL, 'RVProtect', 'RV Protect', NULL, 1, getdate(), 'system', NULL, NULL, NULL, NULL, NULL)
GO

IF NOT EXISTS (SELECT * FROM Product WHERE Name = 'CPO')
INSERT INTO [Product]
           ([ProductCategoryID],[ProductTypeID],[ProductSubTypeID],[VehicleTypeID],[VehicleCategoryID],[Name],[Description],[Sequence],[IsActive],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy],[IsShowOnPO],[AccountingSystemGLCode],[AccountingSystemItemCode])
     VALUES
           ( (SELECT ID FROM ProductCategory WHERE Name = 'MemberProduct')
           , NULL, NULL, NULL, NULL, 'CPO', 'CPO', NULL, 1, getdate(), 'system', NULL, NULL, NULL, NULL, NULL)
GO



IF NOT EXISTS (SELECT * FROM Product WHERE Name = 'HazardProtect')
INSERT INTO [Product]
           ([ProductCategoryID],[ProductTypeID],[ProductSubTypeID],[VehicleTypeID],[VehicleCategoryID],[Name],[Description],[Sequence],[IsActive],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy],[IsShowOnPO],[AccountingSystemGLCode],[AccountingSystemItemCode])
     VALUES
           ( (SELECT ID FROM ProductCategory WHERE Name = 'MemberProduct')
           , NULL, NULL, NULL, NULL, 'HazardProtect', 'Hazard Protect', NULL, 1, getdate(), 'system', NULL, NULL, NULL, NULL, NULL)
GO


---------------------------------------------------
-- Relate additional products to Service Type --- we only want to show additional products for certain service types
-- Need a table that ties Products to 1 to many ProductCategories
select * from MemberProductProductCategory
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MemberProductProductCategory](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[ProductID] [int] NOT NULL,
	[ProductCategoryID] [int] NOT NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_MemberProductProductCategory] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

IF NOT EXISTS (SELECT * FROM MemberProductProductCategory WHERE ProductID = (SELECT ID FROM Product WHERE Name = 'RVProtect') AND ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tow') )
BEGIN
	INSERT MemberProductProductCategory (ProductID, ProductCategoryID, IsActive)
	VALUES ( (SELECT ID FROM Product WHERE Name = 'RVProtect'),(SELECT ID FROM ProductCategory WHERE Name = 'Tow'), 1)
END

IF NOT EXISTS (SELECT * FROM MemberProductProductCategory WHERE ProductID = (SELECT ID FROM Product WHERE Name = 'RVProtect') AND ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Mobile') )
BEGIN
	INSERT MemberProductProductCategory (ProductID, ProductCategoryID, IsActive)
	VALUES ( (SELECT ID FROM Product WHERE Name = 'RVProtect'),(SELECT ID FROM ProductCategory WHERE Name = 'Mobile'), 1)
END

IF NOT EXISTS (SELECT * FROM MemberProductProductCategory WHERE ProductID = (SELECT ID FROM Product WHERE Name = 'CPO') AND ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tow') )
BEGIN
	INSERT MemberProductProductCategory (ProductID, ProductCategoryID, IsActive)
	VALUES ( (SELECT ID FROM Product WHERE Name = 'CPO'),(SELECT ID FROM ProductCategory WHERE Name = 'Tow'), 1)
END

IF NOT EXISTS (SELECT * FROM MemberProductProductCategory WHERE ProductID = (SELECT ID FROM Product WHERE Name = 'CPO') AND ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Mobile') )
BEGIN
	INSERT MemberProductProductCategory (ProductID, ProductCategoryID, IsActive)
	VALUES ( (SELECT ID FROM Product WHERE Name = 'CPO'),(SELECT ID FROM ProductCategory WHERE Name = 'Mobile'), 1)
END

IF NOT EXISTS (SELECT * FROM MemberProductProductCategory WHERE ProductID = (SELECT ID FROM Product WHERE Name = 'HarzardProtect') AND ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tire') )
BEGIN
	INSERT MemberProductProductCategory (ProductID, ProductCategoryID, IsActive)
	VALUES ( (SELECT ID FROM Product WHERE Name = 'HazardProtect'),(SELECT ID FROM ProductCategory WHERE Name = 'Tire'), 1)
END


---------------------------------------------------
-- Create Product Provider table
/****** Object:  Table [dbo].[ProductProvider]    Script Date: 11/30/2014 16:50:58 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductProvider]') AND type in (N'U'))
DROP TABLE [dbo].[ProductProvider]
GO



/****** Object:  Table [dbo].[ProductProvider]    Script Date: 11/30/2014 16:51:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ProductProvider](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Description] [nvarchar](200) NULL,
	[PhoneNumber] [nvarchar](50) NULL,
	[Website] [nvarchar](200) NULL,
	[Script] [nvarchar] (1000) NULL, 
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_ProductProvider] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

-- Insert Records
IF NOT EXISTS (SELECT * FROM ProductProvider WHERE Name = 'Warrantech')
BEGIN
	INSERT ProductProvider (Name, Description, PhoneNumber, Website, Script, IsActive)
	VALUES ('Warrantech', 'Warrantech', '800-111-1111', 'www.warrantech.com', 'This member is covered by a service contract and the repair work may be covered, please call for approval prior to any work being performed. You should contact Warrantech at 800-111-1111.', 1)
END

IF NOT EXISTS (SELECT * FROM ProductProvider WHERE Name = 'SouthwestRe')
BEGIN
	INSERT ProductProvider (Name, Description, PhoneNumber, Website, Script, IsActive)
	VALUES ('SouthwestRe', 'SouthwestRe', '800-222-2222', 'www.southwestre.com', 'This member is covered by a service contract and the repair work may be covered, please call for approval prior to any work being performed. You should contact SouthwestRe at 800-222-2222.', 1)
END

IF NOT EXISTS (SELECT * FROM ProductProvider WHERE Name = 'Coach-Net')
BEGIN
	INSERT ProductProvider (Name, Description, PhoneNumber, Website, Script, IsActive)
	VALUES ('Coach-Net', 'Coach-Net', '800-333-3333', 'www.coach-net.com', '', 1)
END


---------------------------------------------------
-- Create MemberProduct Table
CREATE TABLE [dbo].[MemberProduct](
	[ID] [bigint] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[MemberID] [int] NOT NULL REFERENCES Member(ID),
	[ProductID] [int] NOT NULL REFERENCES Product(ID),
	[ProductProviderID] [int] NULL REFERENCES ProductProvider(ID),
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[ContractNumber] nvarchar(50) NULL,
	[VIN] nvarchar(50) NULL
)

GO

---**** Make MemberID Foreign Key
---**** Make ProductID Foreign Key
---**** Make ProductProviderID Foreign Key
--select * from Member where FirstName = 'tom' and LastName = 'Burt'
--select * from Membership where MembershipNumber = '4480784'
--select * from Product order by ID desc
--select * from ProductProvider 


IF NOT EXISTS (SELECT * FROM MemberProduct WHERE MemberID = 15612687 AND ProductID = (SELECT ID FROM Product WHERE Name = 'RVProtect'))
BEGIN
	INSERT MemberProduct (MemberID, ProductID, ProductProviderID, StartDate, EndDate)
	VALUES (15612687, (SELECT ID FROM Product WHERE Name = 'RVProtect'), 1, '08/21/2013', '08/20/2016')
END

IF NOT EXISTS (SELECT * FROM MemberProduct WHERE MemberID = 15612687 AND ProductID = (SELECT ID FROM Product WHERE Name = 'HazardProtect'))
BEGIN
	INSERT MemberProduct (MemberID, ProductID, ProductProviderID, StartDate, EndDate)
	VALUES (15612687, (SELECT ID FROM Product WHERE Name = 'HazardProtect'), 3, '08/21/2013', '08/20/2016')
END
