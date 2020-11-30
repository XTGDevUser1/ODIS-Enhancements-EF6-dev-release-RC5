IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_product_options_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
DROP PROCEDURE [dbo].[dms_product_options_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_product_options_get]  8,1,1
CREATE PROCEDURE [dbo].[dms_product_options_get]    
 @productCategoryID INT = NULL,
 @vehicleTypeID INT = NULL,  
 @vehicleCategoryID INT = NULL
AS    
BEGIN 

	SELECT	P.* -- use p.ID for attribute list
	FROM	Product P
	WHERE	P.ProductCategoryID = @productCategoryID
	
	AND		(ISNULL(p.VehicleTypeID ,'')='' OR P.VehicleTypeID = @vehicleTypeID)
	AND		(ISNULL(p.VehicleCategoryID ,'')='' OR P.VehicleCategoryID = @vehicleCategoryID)
	AND		P.ProductTypeID = (select ID from ProductType where Name = 'Service')
	-- KB: Updates from Tim and Rusty
	AND		P.ProductSubTypeID IN (select ID from ProductSubType where Name IN ('PrimaryService', 'SecondaryService'))
	AND		P.ProductCategoryID IN (1,2,3,4,5,6,8)	
	-- KB: End of update
	ORDER BY P.Name

END
