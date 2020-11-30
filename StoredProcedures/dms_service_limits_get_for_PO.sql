IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_service_limits_get_for_PO]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_service_limits_get_for_PO] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_service_limits_get_for_PO] @programID = 5,@vehicleCategoryID = 1, @purchaseOrderID = 656
 create PROCEDURE [dbo].[dms_service_limits_get_for_PO]( 
   @programID INT = NULL,
   @vehicleCategoryID INT = NULL,
   @purchaseOrderID INT = NULL 
 ) 
 AS 
 BEGIN 
 
 SET FMTONLY OFF

DECLARE @tmpPrograms TABLE
(
      LevelID INT IDENTITY(1,1),
      ProgramID INT
)

DECLARE @coverageLimit money
SET @coverageLimit = 0.00

DECLARE @ProductID int

SET @ProductID = (
SELECT top 1 pod.ProductID
FROM PurchaseOrderDetail pod
JOIN Product p ON pod.ProductID = p.ID
JOIN ProductSubType ps ON p.ProductSubTypeID = ps.ID AND ps.Name IN ('PrimaryService','SecondaryService')
WHERE pod.PurchaseOrderID = @PurchaseOrderID
)

IF @ProductID IS NULL
      SET @ProductID = (SELECT ProductID FROM PurchaseOrder WHERE ID = @PurchaseOrderID)


--select top 1 @coverageLimit=ISNULL(p.CoverageLimit,0.00) from PurchaseOrder p
--Inner join  PurchaseOrder sp ON p.ServicerequestID=sp.ServicerequestID
--where sp.ID=@purchaseOrderID

--IF(@coverageLimit=0.00)
--BEGIN

INSERT INTO @tmpPrograms
SELECT ProgramID FROM fnc_GetProgramsandParents (@programID)

SELECT TP.LevelID, pp.ProductID, MAX(pc.Name) AS ProductCategoryName, pp.ServiceCoverageLimit
INTO #tmpPPAll
FROM ProgramProduct pp WITH (NOLOCK)
LEFT JOIN Program pr WITH (NOLOCK) on pr.ID = pp.ProgramID
LEFT JOIN Product p WITH (NOLOCK) on p.ID = pp.ProductID
LEFT JOIN ProductCategory pc WITH (NOLOCK) on pc.ID = p.ProductCategoryID 
JOIN @tmpPrograms TP ON pr.ID = TP.ProgramID 
AND (p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @vehicleCategoryID)
WHERE P.ProductSubTypeID IN (select ID from ProductSubType where name IN ('PrimaryService','SecondaryService')) 
GROUP BY TP.LevelID, pp.ProductID, pp.ServiceCoverageLimit

;WITH wProgramProductsOrdered
AS
( 
SELECT ROW_NUMBER() OVER (PARTITION BY W.ProductID ORDER BY W.LevelID ASC) AS RowNum,
W.ProductID,
W.ProductCategoryName,
W.ServiceCoverageLimit
FROM #tmpPPAll W
)

/*** END --- Code from SP dms_service_limits_get ***/

/* Get List of PrimaryService products from the PO Details */

/* Use max service limit for primary products on the purchase order */

SELECT @coverageLimit = ISNULL(ServiceCoverageLimit,0.00)
FROM wProgramProductsOrdered
WHERE ProductID = @ProductID
-- IN (SELECT pod.ProductID
--FROM PurchaseOrderDetail pod
--JOIN Product p ON pod.ProductID = p.ID
--JOIN ProductSubType ps ON p.ProductSubTypeID = ps.ID AND ps.Name IN ('PrimaryService','SecondaryService')
--WHERE pod.PurchaseOrderID = @PurchaseOrderID
----GROUP BY pod.ProductID
AND RowNum = 1
--)

DROP TABLE #tmpPPALL

--END

--IF(@coverageLimit > 0)
--BEGIN
--select @coverageLimit=@coverageLimit-ISNULL(SUM(CoachNetServiceAmount),0) from PurchaseOrder P  
--Inner Join PurchaseOrderStatus ps ON ps.ID=P.PurchaseOrderStatusID
--where P.ServiceRequestID =(SELECT SP.ServiceRequestID FROM PurchaseOrder SP where SP.ID=@PurchaseOrderID)
--AND (PS.Name='Issued' OR PS.Name='Issued-Paid')

--SELECT ISNULL(@coverageLimit,0) AS CoverageLimit
--END
--ELSE
--BEGIN
--SET @coverageLimit=0.00
--SELECT @coverageLimit AS CoverageLimit
SELECT ISNULL(@coverageLimit,0) AS CoverageLimit
--END


END

 
GO