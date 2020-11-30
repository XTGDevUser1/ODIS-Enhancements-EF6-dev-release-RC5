IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Service_Ratings_Product_Category_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Service_Ratings_Product_Category_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_Service_Ratings_Product_Category_List_Get] 190
 CREATE PROCEDURE [dbo].[dms_Service_Ratings_Product_Category_List_Get]( 
  @VendorID INT =NULL
 )
 AS 
 BEGIN 
 SELECT
	v.ID
	,pc.ID AS ProductCategoryID
    ,pc.Name ProductCategoryName
    ,ROUND(AVG(ISNULL(vlp.Rating,0)),0) AvgProductRating
FROM Vendor v
JOIN VendorLocation vl ON v.ID = vl.VendorID
JOIN VendorLocationProduct vlp ON vl.ID = vlp.VendorLocationID AND vlp.IsActive = 1
JOIN Product p ON p.ID = vlp.ProductID
JOIN ProductCategory pc ON pc.ID = p.ProductCategoryID
WHERE
            v.id = @VendorID
GROUP BY
            v.ID
            ,pc.ID
            ,pc.Name
 END