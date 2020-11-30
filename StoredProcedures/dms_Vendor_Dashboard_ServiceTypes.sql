IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Dashboard_ServiceTypes]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Dashboard_ServiceTypes]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 


CREATE PROC dms_Vendor_Dashboard_ServiceTypes(@VendorID INT = NULL)
AS
BEGIN
	SELECT 
	v.ID VendorID
	,pc.Name ProductCategoryName
	,pc.Sequence
	,count(*) ServiceCount
	--,Total.POCount TotalCount
	,ROUND(CAST(count(*) as float) / Total.POCount,2)*100 ServicePercentage
	FROM PurchaseOrder po
	JOIN VendorLocation vl ON po.VendorLocationID = vl.ID
	JOIN Vendor v ON v.ID = vl.VendorID
	JOIN Product p on p.ID = po.ProductID
	JOIN ProductCategory pc on pc.ID = p.ProductCategoryID
	JOIN (
	SELECT v.ID VendorID, count(*) POCount
	FROM PurchaseOrder po
	JOIN VendorLocation vl ON po.VendorLocationID = vl.ID
	JOIN Vendor v ON v.ID = vl.VendorID
	WHERE po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued', 'Issued-Paid'))
	GROUP BY v.ID
	) Total ON Total.VendorID = v.ID
	WHERE po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued', 'Issued-Paid'))
	AND v.ID = @VendorID
	GROUP BY v.ID, pc.ID, pc.Name, pc.Sequence, Total.POCount
END
