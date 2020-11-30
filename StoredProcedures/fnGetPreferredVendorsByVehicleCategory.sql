IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnGetPreferredVendorsByVehicleCategory]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnGetPreferredVendorsByVehicleCategory]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Select * From [dbo].[fnGetContractedVendors]() Where VendorID = 4360   
CREATE FUNCTION [dbo].[fnGetPreferredVendorsByVehicleCategory] ()  
RETURNS TABLE   
AS  
RETURN   
(  
	select v.ID VendorID, p.VehicleCategoryID 
	from vendor v
	Join VendorProduct vp on vp.VendorID = v.ID
	Join Product p on p.ID = vp.ProductID
	Join ProductCategory pc on pc.ID = p.ProductCategoryID
	Join ProductType pt on pt.ID = p.ProductTypeID
	Join ProductSubType pst on pst.ID = p.ProductSubTypeID
	Where pc.Name = 'ISPSelection'
	and pt.Name = 'Attribute'
	and pst.Name = 'Ranking'
)  


GO


