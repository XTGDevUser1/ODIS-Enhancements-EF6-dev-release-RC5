 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[MarketLocationRates]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[MarketLocationRates] 
 END 
 GO  
Create View [dbo].[MarketLocationRates]
as 
Select Top 9999999999 ml.Name Market, ml.Latitude, ml.Longitude, ml.RadiusMiles, pc.Name ServiceCategory, vc.Name VehicleCategory, p.Name [Service], rt.name RateType, mlp.Price, mlp.Quantity --, mlp.*
From MarketLocation ml
Join MarketLocationProductRate mlp on mlp.MarketLocationID = ml.id
Join Product p on p.ID = mlp.ProductID
Join ProductCategory pc on pc.ID = p.ProductCategoryID
Left Outer Join VehicleCategory vc on vc.ID = p.VehicleCategoryID
Join RateType rt on rt.ID = mlp.RateTypeID
Where ml.Name IN ('Dallas-Fort Worth', 'Houston', 'US_TX')
Order by ml.ID, mlp.ProductID, rt.name
GO

