-- Add Home Locksmith product category if not exists
IF NOT EXISTS (SELECT * FROM [dbo].[ProductCategory] WHERE Name = 'Home Locksmith')
BEGIN
	INSERT INTO [dbo].[ProductCategory]
			   ([Name]
			   ,[Description]
			   ,[Sequence]
			   ,[IsActive])
		 VALUES
			   ('Home Locksmith'
			   ,'Home Locksmith'
			   ,13
			   ,1)
END

-- Add Home Locksmith product if not exists
IF NOT EXISTS (SELECT * FROM [dbo].[Product] WHERE Name = 'Home Locksmith')
BEGIN
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
           ((SELECT ID FROM ProductCategory WHERE Name = 'Home Locksmith')
           ,(SELECT ID From ProductType Where Name = 'Service')
           ,(SELECT ID From ProductSubType Where Name = 'PrimaryService')
           ,NULL
           ,NULL
           ,'Home Locksmith'
           ,'Home Locksmith'
           ,15
           ,1
           ,GetDate()
           ,'System'
           ,NULL
           ,NULL
           ,1
           ,NULL
           ,NULL)
END

--Add Home Locksmith service to any vendor currently having (Auto) Locksmith
INSERT INTO [dbo].[VendorProduct]
           ([VendorID]
           ,[ProductID]
           ,[IsActive]
           ,[Rating]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
SELECT 
           vp.[VendorID]
           ,(SELECT ID FROM Product WHERE Name = 'Home Locksmith') ProductID
           ,vp.[IsActive]
           ,vp.[Rating]
           ,vp.[CreateDate]
           ,vp.[CreateBy]
           ,vp.[ModifyDate]
           ,vp.[ModifyBy]
FROM Vendor v
JOIN VendorProduct vp on v.id = vp.VendorID
WHERE 1=1
AND v.IsActive = 1
AND vp.ProductID = (SELECT TOP 1 ID FROM Product WHERE Name = 'Locksmith' ORDER BY 1 DESC)
AND vp.IsActive = 1
AND NOT EXISTS (
	SELECT *
	FROM VendorProduct vp1
	WHERE vp1.VendorID = vp.VendorID
	AND vp1.ProductID = (SELECT ID FROM Product WHERE Name = 'Home Locksmith'))
--AND v.ID = 93524

--Add Home Locksmith service to any vendor location currently having (Auto) Locksmith
INSERT INTO [dbo].[VendorLocationProduct]
           ([VendorLocationID]
           ,[ProductID]
           ,[IsActive]
           ,[Rating]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
SELECT	
           vlp.[VendorLocationID]
           ,(SELECT ID FROM Product WHERE Name = 'Home Locksmith') ProductID
           ,vlp.[IsActive]
           ,vlp.[Rating]
           ,vlp.[CreateDate]
           ,vlp.[CreateBy]
           ,vlp.[ModifyDate]
           ,vlp.[ModifyBy]
FROM Vendor v
JOIN VendorProduct vp on v.id = vp.VendorID
JOIN VendorLocation vl ON vl.VendorID = v.ID
JOIN VendorLocationProduct vlp on vlp.VendorLocationID = vl.ID
WHERE 1=1
AND v.IsActive = 1
AND vl.IsActive = 1
AND vp.ProductID = (SELECT TOP 1 ID FROM Product WHERE Name = 'Locksmith' ORDER BY 1 DESC)
AND vlp.ProductID = (SELECT TOP 1 ID FROM Product WHERE Name = 'Locksmith' ORDER BY 1 DESC)
AND NOT EXISTS (
	SELECT *
	FROM VendorLocationProduct vlp1
	WHERE vlp1.VendorLocationID = vlp.VendorLocationID
	AND vlp1.ProductID = (SELECT ID FROM Product WHERE Name = 'Home Locksmith'))
--AND vl.vendorID = 93524


--Set contract rates for Home Locksmith according to any contracted rates for (auto) locksmith
INSERT INTO [dbo].[ContractRateScheduleProduct]
           ([ContractRateScheduleID]
           ,[VendorLocationID]
           ,[ProductID]
           ,[RateTypeID]
           ,[Price]
           ,[Quantity]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
SELECT 
           crsp.[ContractRateScheduleID]
           ,crsp.[VendorLocationID]
           ,(SELECT ID FROM Product WHERE Name = 'Home Locksmith') ProductID
           ,crsp.[RateTypeID]
           ,crsp.[Price]
           ,crsp.[Quantity]
           ,crsp.[CreateDate]
           ,crsp.[CreateBy]
           ,crsp.[ModifyDate]
           ,crsp.[ModifyBy]
FROM dbo.Vendor v
JOIN dbo.[Contract] c On c.VendorID = v.ID 
JOIN dbo.[ContractRateSchedule] crs ON 
	crs.ContractID = c.ID AND 
	crs.ContractRateScheduleStatusID = (SELECT ID FROM ContractRateScheduleStatus WHERE Name = 'Active') AND
	crs.StartDate <= GETDATE() AND
	(crs.EndDate IS NULL OR crs.EndDate >= GETDATE())
JOIN dbo.[ContractRateScheduleProduct] crsp On crsp.ContractRateScheduleID = crs.ID 
JOIN RateType rt on rt.ID = crsp.RateTypeID
WHERE 1=1
AND v.IsActive = 1
AND c.IsActive = 1 
AND c.ContractStatusID = (SELECT ID FROM ContractStatus WHERE Name = 'Active')
AND c.StartDate <= GETDATE() 
AND (c.EndDate IS NULL OR c.EndDate >= GETDATE())
AND crsp.ProductID = (SELECT TOP 1 ID FROM Product WHERE Name = 'Locksmith' ORDER BY 1 DESC)
AND NOT EXISTS (
	SELECT *
	FROM dbo.[ContractRateScheduleProduct] crsp1
	WHERE crsp1.ContractRateScheduleID = crsp.ContractRateScheduleID
	AND crsp1.ProductID = (SELECT ID FROM Product WHERE Name = 'Home Locksmith'))
--AND v.ID = 93524



