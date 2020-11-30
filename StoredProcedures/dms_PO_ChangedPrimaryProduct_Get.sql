IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_PO_ChangedPrimaryProduct_Get]')	AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_PO_ChangedPrimaryProduct_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_PO_ChangedPrimaryProduct_Get] 637
-- EXEC [dbo].[dms_PO_ChangedPrimaryProduct_Get] 637
CREATE PROCEDURE [dbo].[dms_PO_ChangedPrimaryProduct_Get]
(
@purchaseOrderID int
)
AS  
BEGIN

SELECT PODtl.ProductID
FROM PurchaseOrder PO
JOIN PurchaseOrderDetail PODtl ON PO.ID = PODtl.PurchaseOrderID
JOIN (
SELECT POProduct.PurchaseOrderID, MIN(PODTLID) PODTLID
FROM
(
SELECT PurchaseOrderID, ProductID, MIN(PODtl.ID) PODTLID
FROM PurchaseOrderDetail PODtl
JOIN dbo.Product Prod 
ON Prod.ID = PODtl.ProductID
JOIN dbo.ProductCategory ProdCat 
ON ProdCat.ID = Prod.ProductCategoryID
WHERE Prod.ProductSubTypeID IN (1,2)
--AND PODtl.Rate <> 0.00
GROUP BY PurchaseOrderID, ProductID
) POProduct
GROUP BY POProduct.PurchaseOrderID
) FirstPOProductDetailID ON PODTL.PurchaseOrderID = FirstPOProductDetailID.PurchaseOrderID AND PODTL.ID = FirstPOProductDetailID.PODTLID
WHERE 1=1
AND PODtl.PurchaseOrderID = @purchaseOrderID
AND ISNULL(PODtl.ProductID,0) <> ISNULL(PO.ProductID,0)

END
GO

