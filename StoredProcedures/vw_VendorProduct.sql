IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_VendorProduct]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_VendorProduct] 
 END 
 GO  
CREATE View [dbo].[vw_VendorProduct]
As
Select v.ID VendorID, v.VendorNumber, vp.ProductID, p.Name ProductName, pt.Name ProductType
From Vendor v 
Join VendorProduct vp on vp.VendorID = v.ID
Join Product p on p.ID = vp.ProductID
Join ProductType pt on pt.ID = p.ProductTypeID 
Where v.IsActive = 1
GO

