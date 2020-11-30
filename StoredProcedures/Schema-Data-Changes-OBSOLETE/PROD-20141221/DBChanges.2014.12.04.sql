IF NOT EXISTS (SELECT * FROM Product WHERE Name = 'FinishProtect')
BEGIN
INSERT INTO [Product]([ProductCategoryID],
					  [ProductTypeID],
					  [ProductSubTypeID],
					  [VehicleTypeID],
					  [VehicleCategoryID],
					  [Name],
					  [Description],
					  [Sequence],
					  [IsActive],
					  [CreateDate],
					  [CreateBy],
					  [ModifyDate],
					  [ModifyBy],
					  [IsShowOnPO],
					  [AccountingSystemGLCode],
					  [AccountingSystemItemCode])

VALUES( (SELECT ID FROM ProductCategory WHERE Name = 'MemberProduct'), NULL, NULL, NULL, NULL, 'FinishProtect', 'Finish Protect', NULL, 1, getdate(), 
		'system', NULL, NULL, NULL, NULL, NULL)
END
GO


IF NOT EXISTS (SELECT * FROM MemberProductProductCategory WHERE ProductID = (SELECT ID FROM Product WHERE Name = 'RVProtect') AND ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tech') )
BEGIN
 INSERT MemberProductProductCategory (ProductID, ProductCategoryID, IsActive)
 VALUES ( (SELECT ID FROM Product WHERE Name = 'RVProtect'),(SELECT ID FROM ProductCategory WHERE Name = 'Tech'), 1)
END

IF NOT EXISTS (SELECT * FROM MemberProductProductCategory WHERE ProductID = (SELECT ID FROM Product WHERE Name = 'HarzardProtect') AND ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tow') )
BEGIN
 INSERT MemberProductProductCategory (ProductID, ProductCategoryID, IsActive)
 VALUES ( (SELECT ID FROM Product WHERE Name = 'HazardProtect'),(SELECT ID FROM ProductCategory WHERE Name = 'Tow'), 1)
END
