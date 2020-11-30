
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Dashboard_ServiceRatings]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Dashboard_ServiceRatings]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

CREATE PROC dms_Vendor_Dashboard_ServiceRatings(@VendorID INT = NULL)
AS
BEGIN

SELECT 
	 v.ID
	--,pc.Name ProductCategoryName
	,ROUND(AVG(vlp.Rating),0) AvgProductRating
FROM Vendor v
JOIN VendorLocation vl ON v.ID = vl.VendorID
JOIN VendorLocationProduct vlp ON vl.ID = vlp.VendorLocationID AND vlp.IsActive = 1
JOIN Product p ON p.ID = vlp.ProductID
JOIN ProductCategory pc ON pc.ID = p.ProductCategoryID
WHERE
	v.id = @VendorID
GROUP BY
	v.VendorNumber
	,v.ID
	--,pc.Name
END