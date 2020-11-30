IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_VendorManagement_VendorServiceRating_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VendorManagement_VendorServiceRating_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_VendorManagement_VendorServiceRating_Get] 382
CREATE PROCEDURE [dbo].[dms_VendorManagement_VendorServiceRating_Get](
  @vendorID int
)
AS  
BEGIN

SELECT      p.Name, CAST(ROUND(AVG(vlp.Rating),0) AS decimal(5,2)) Rating
FROM        Vendor v
JOIN        VendorProduct vp ON vp.VendorID = v.ID
JOIN        Product p ON p.ID = vp.ProductID
LEFT JOIN   VendorLocation vl ON vl.VendorID = v.ID
LEFT JOIN   VendorLocationProduct vlp ON vlp.VendorLocationID = vl.ID and vlp.ProductID = vp.ProductID
WHERE       v.ID = @VendorID
AND         p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service') 
AND         p.ProductSubTypeID IN (SELECT ID FROM ProductSubType WHERE Name IN ('PrimaryService','SecondaryService'))
AND         p.IsShowOnPO = 1
GROUP BY    p.ProductCategoryID, p.Name
ORDER BY    p.ProductCategoryID, p.Name


END





