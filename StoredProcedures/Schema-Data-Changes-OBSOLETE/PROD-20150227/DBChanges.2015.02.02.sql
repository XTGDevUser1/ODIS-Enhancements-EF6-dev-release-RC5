
ALTER TABLE ServiceRequest
ADD ProviderID INT NULL

IF NOT EXISTS (SELECT ID FROM Event WHERE Name = 'EnteredProviderClaimNumber')
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
           ,(SELECT ID FROM EventCategory WHERE Name= 'ServiceRequest')
           ,'EnteredProviderClaimNumber'
           ,'Entered provider claim number'
           ,1
           ,1
           ,'system'
           ,getdate()
           )
END
GO



--
-- Dispatch
-- ODIS
-- Steup Preferred Provider Logic
--

------ Reference Queries
----SELECT * FROM Product order by id desc --WHERE ID = 232
----select * from ProductCategory
----select * from ProductType
----Select * from ProductSubType 

-----------------------------------------------------------------------------------
-- Script to setup Preferred ISP reference data

-- ProductCategory
IF NOT EXISTS (SELECT * FROM ProductCategory WHERE Name = 'ISPSelection')
BEGIN
	INSERT ProductCategory (Name, Description, Sequence, IsActive, IsVehicleRequired) 
	VALUES ('ISPSelection','ISP Selection',14, 1, NULL)
END

-- ProductSubType
IF NOT EXISTS (SELECT * FROM ProductSubType WHERE Name = 'Ranking')
BEGIN
	INSERT ProductSubType (ProductTypeID, Name, Description, Sequence, IsActive) 
	VALUES ((SELECT ID FROM ProductType WHERE Name = 'Attribute'),'Ranking','Ranking',11, 1)
END

-- Product 
IF NOT EXISTS (SELECT * FROM Product WHERE Name = 'Preferred - HD')
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
			 (SELECT ID FROM ProductCategory WHERE Name = 'ISPSelection')
			, (SELECT ID FROM ProductType WHERE Name = 'Attribute')
			, (SELECT ID FROM ProductSubType WHERE Name = 'Ranking')
			, NULL
			, (SELECT ID FROM VehicleCategory WHERE Name = 'HeavyDuty')
			, 'Preferred - HD'
			, 'Preferred ISP - HD'
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

-- Product 
IF NOT EXISTS (SELECT * FROM Product WHERE Name = 'Preferred - MD')
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
			 (SELECT ID FROM ProductCategory WHERE Name = 'ISPSelection')
			, (SELECT ID FROM ProductType WHERE Name = 'Attribute')
			, (SELECT ID FROM ProductSubType WHERE Name = 'Ranking')
			, NULL
			, (SELECT ID FROM VehicleCategory WHERE Name = 'MediumDuty')
			, 'Preferred - MD'
			, 'Preferred ISP - MD'
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

-- Product 
IF NOT EXISTS (SELECT * FROM Product WHERE Name = 'Preferred - LD')
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
			 (SELECT ID FROM ProductCategory WHERE Name = 'ISPSelection')
			, (SELECT ID FROM ProductType WHERE Name = 'Attribute')
			, (SELECT ID FROM ProductSubType WHERE Name = 'Ranking')
			, NULL
			, (SELECT ID FROM VehicleCategory WHERE Name = 'LightDuty')
			, 'Preferred - LD'
			, 'Preferred ISP - LD'
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

