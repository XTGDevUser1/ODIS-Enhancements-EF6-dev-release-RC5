IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_VendorLocationProduct]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_VendorLocationProduct] 
 END 
 GO  
Create View [dbo].[vw_VendorLocationProduct]
As
Select v.ID VendorID, v.VendorNumber, vl.ID VendorLocationID, vp.ProductID, p.Name ProductName, pt.Name ProductType
From Vendor v 
Join VendorLocation vl on vl.VendorID = v.ID 
Join VendorLocationProduct vp on vp.VendorLocationID = vl.ID
Join Product p on p.ID = vp.ProductID
Join ProductType pt on pt.ID = p.ProductTypeID 
Where v.IsActive = 1
and vl.IsActive = 1
GO

