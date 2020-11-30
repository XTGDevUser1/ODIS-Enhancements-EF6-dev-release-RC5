IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_GOA_PO_Details]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_GOA_PO_Details] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_GOA_PO_Details] 1
 CREATE PROCEDURE [dbo].[dms_GOA_PO_Details]( 
  @OldPurchaseOrderID  INT = NULL
  ,@NewPurchaseOrderID INT = NULL
  ,@UserName NVARCHAR(50) 
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
 	
	INSERT INTO dbo.PurchaseOrderDetail(
		PurchaseOrderID,
		ProductID,
		ProductRateID,
		Sequence,
		UnitOfMeasure,
		ContractedRate,
		Rate,
		Quantity,
		ExtendedAmount,
		IsTaxable,
		IsMemberPay,
		CreateDate,
		CreateBy,
		ModifyDate,
		ModifyBy)
	SELECT DISTINCT
		   @NewPurchaseOrderID
		  ,POProduct.ProductID
		  --,GOARate.ProductRateID
		  ,(Select ID From RateType Where Name = 'GoneOnArrival') AS ProductRateID
		  ,1 AS Sequence
		  ,(Select UnitOfMeasure From RateType Where Name = 'GoneOnArrival') AS UnitOfMeasure
		  ,CASE WHEN VendorLocationRate.Price IS NOT NULL THEN VendorLocationRate.Price
				WHEN VendorDefaultRate.Price IS NOT NULL THEN VendorDefaultRate.Price
				ELSE 0 END AS ContractedRate
		  ,CASE WHEN VendorLocationRate.Price IS NOT NULL THEN VendorLocationRate.Price
				WHEN VendorDefaultRate.Price IS NOT NULL THEN VendorDefaultRate.Price
				ELSE 0 END AS Rate
		  ,1 AS Quantity
		  ,CASE WHEN VendorLocationRate.Price IS NOT NULL THEN VendorLocationRate.Price
				WHEN VendorDefaultRate.Price IS NOT NULL THEN VendorDefaultRate.Price
				ELSE 0 END AS ExtendedAmount
		  ,Cast(1 AS bit)  AS IsTaxable
		  ,Cast(0 AS bit)  AS IsMemberPay
		  ,GetDate()
		  ,@UserName
		  ,GetDate()
		  ,@UserName
	FROM (
		  SELECT 
				vl.VendorID
				,po.VendorLocationID
				,po.ID PurchaseOrderID
				,p.ID ProductID
		  FROM dbo.PurchaseOrder po
		  JOIN dbo.VendorLocation vl 
				ON vl.ID = po.VendorLocationID
		  JOIN dbo.PurchaseOrderDetail pod 
				ON po.ID = pod.PurchaseOrderID
		  JOIN dbo.Product p 
				ON pod.ProductID = p.ID
		  JOIN dbo.ProductSubType pst 
				ON pst.ID = p.ProductSubTypeID
		  WHERE pod.PurchaseOrderID = @OldPurchaseOrderID
		  -- CR : 1200 : Changes from Rusty.
		  AND pst.Name IN ('PrimaryService','SecondaryService')
		  GROUP BY 
				vl.VendorID
				,po.VendorLocationID
				,po.ID
				,p.ID
		  ) POProduct
	LEFT OUTER JOIN
		(
		SELECT *
		FROM dbo.fnGetCurrentProductRatesByVendorLocation() 
		WHERE RateName = 'GoneOnArrival'
		) VendorLocationRate ON VendorLocationRate.VendorLocationID = POProduct.VendorLocationID AND VendorLocationRate.ProductID = POProduct.ProductID
	LEFT OUTER JOIN
		(
		SELECT *
		FROM dbo.fnGetCurrentProductRatesByVendorLocation() 
		WHERE RateName = 'GoneOnArrival'
		AND VendorLocationID IS NULL
		) VendorDefaultRate ON VendorDefaultRate.VendorID = POProduct.VendorID AND VendorDefaultRate.ProductID = POProduct.ProductID

	 DECLARE @sumOfExtendedAmount as money
	 
	 SELECT @sumOfExtendedAmount=SUM(ExtendedAmount) from PurchaseOrderDetail where PurchaseOrderID=@NewPurchaseOrderID
	 UPDATE PurchaseOrder SET CoachNetServiceAmount=@sumOfExtendedAmount,TotalServiceAmount =@sumOfExtendedAmount,
	 PurchaseOrderAmount=@sumOfExtendedAmount where ID=@NewPurchaseOrderID AND ISGOA=1 
	 
 END
