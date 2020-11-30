IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_VendorManagement_VendorLocationServiceRating_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VendorManagement_VendorLocationServiceRating_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_VendorManagement_VendorLocationServiceRating_Get] 452
CREATE PROCEDURE [dbo].[dms_VendorManagement_VendorLocationServiceRating_Get](
  @vendorLocationID int
)
AS  
BEGIN

SELECT      P.Name, VLP.Rating,VLP.ID
FROM        VendorLocationProduct VLP
LEFT JOIN   Product P ON P.ID = VLP.ProductID
WHERE       VLP.VendorLocationID = @vendorLocationID
AND         p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service') 
AND         p.ProductSubTypeID IN (SELECT ID FROM ProductSubType WHERE Name IN ('PrimaryService','SecondaryService'))
AND         p.IsShowOnPO = 1
ORDER BY    P.ProductCategoryID, P.Name

END