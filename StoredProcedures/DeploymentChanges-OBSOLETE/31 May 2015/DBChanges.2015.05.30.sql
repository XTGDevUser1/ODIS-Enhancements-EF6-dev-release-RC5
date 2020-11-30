ALTER TABLE PurchaseOrder ADD IsPreferredVendor BIT NULL

Update Product Set Name = 'Preferred - LD Tow', [Description] = 'Preferred - LD Tow', VehicleCategoryID = NULL, Sequence = 1 Where Name = 'Preferred - LD'
Update Product Set Name = 'Preferred - MD Tow', [Description] = 'Preferred - MD Tow', VehicleCategoryID = NULL, Sequence = 3 Where Name = 'Preferred - MD'
Update Product Set Name = 'Preferred - HD Tow', [Description] = 'Preferred - HD Tow', VehicleCategoryID = NULL, Sequence = 5 Where Name = 'Preferred - HD'


INSERT INTO [dbo].[Product]
           ([ProductCategoryID]
           ,[ProductTypeID]
           ,[ProductSubTypeID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy]
           ,[IsShowOnPO]
           ,[AccountingSystemGLCode]
           ,[AccountingSystemItemCode])
     VALUES
           ((Select ID from ProductCategory Where Name = 'ISPSelection')
           ,(Select ID from ProductType Where Name = 'Attribute')
           ,(Select ID from ProductSubType Where Name = 'Ranking')
           ,NULL
           ,NULL
           ,'Preferred - LD Service Call' 
           ,'Preferred - LD Service Call'
           ,2
           ,1
           ,'5/29/2015'
           ,'system'
           ,NULL
           ,NULL
           ,0
           ,NULL
           ,NULL)


INSERT INTO [dbo].[Product]
           ([ProductCategoryID]
           ,[ProductTypeID]
           ,[ProductSubTypeID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy]
           ,[IsShowOnPO]
           ,[AccountingSystemGLCode]
           ,[AccountingSystemItemCode])
     VALUES
           ((Select ID from ProductCategory Where Name = 'ISPSelection')
           ,(Select ID from ProductType Where Name = 'Attribute')
           ,(Select ID from ProductSubType Where Name = 'Ranking')
           ,NULL
           ,NULL
           ,'Preferred - MD Service Call' 
           ,'Preferred - MD Service Call'
           ,4
           ,1
           ,'5/29/2015'
           ,'system'
           ,NULL
           ,NULL
           ,0
           ,NULL
           ,NULL)


INSERT INTO [dbo].[Product]
           ([ProductCategoryID]
           ,[ProductTypeID]
           ,[ProductSubTypeID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy]
           ,[IsShowOnPO]
           ,[AccountingSystemGLCode]
           ,[AccountingSystemItemCode])
     VALUES
           ((Select ID from ProductCategory Where Name = 'ISPSelection')
           ,(Select ID from ProductType Where Name = 'Attribute')
           ,(Select ID from ProductSubType Where Name = 'Ranking')
           ,NULL
           ,NULL
           ,'Preferred - HD Service Call' 
           ,'Preferred - HD Service Call'
           ,6
           ,1
           ,'5/29/2015'
           ,'system'
           ,NULL
           ,NULL
           ,0
           ,NULL
           ,NULL)

