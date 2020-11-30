IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Vendor_Dasboard_ServiceRatings]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Vendor_Dasboard_ServiceRatings]
GO
CREATE PROCEDURE [dbo].[dms_Vendor_Dasboard_ServiceRatings](@VendorID INT = NULL)
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
GO

