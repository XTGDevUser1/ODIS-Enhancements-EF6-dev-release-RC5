IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vwPreferredVendorByCategory]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vwPreferredVendorByCategory] 
 END 
 GO  
CREATE VIEW [dbo].[vwPreferredVendorByCategory]
AS
select v.ID VendorID, v.VendorNumber, p.ID ProductID, p.Name PreferredCategoryName, p.VehicleCategoryID
from vendor v
Join VendorProduct vp on vp.VendorID = v.ID
Join Product p on p.ID = vp.ProductID
Join ProductCategory pc on pc.ID = p.ProductCategoryID
Join ProductType pt on pt.ID = p.ProductTypeID
Join ProductSubType pst on pst.ID = p.ProductSubTypeID
Where pc.Name = 'ISPSelection'
and pt.Name = 'Attribute'
and pst.Name = 'Ranking'
GO

