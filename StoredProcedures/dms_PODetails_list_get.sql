IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_PODetails_list_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_PODetails_list_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_PODetails_list_get] 66
 CREATE PROCEDURE [dbo].[dms_PODetails_list_get]( 
  @purchaseOrderID INT = NULL

 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
 	SELECT POD.ID
,POD.PurchaseOrderID
,POD.ProductID
,POD.ProductRateID
,POD.Sequence
,POD.UnitOfMeasure
,POD.Rate
,POD.Quantity
,POD.ExtendedAmount
,POD.IsTaxable
,POD.IsMemberPay
,POD.CreateDate
,POD.CreateBy
,POD.ModifyDate
,POD.ModifyBy
 ,RT.[Description] AS RateTypeDescription
 , P.Name AS ProductName
 from dbo.PurchaseOrderDetail POD WITH (NOLOCK)
LEFT OUTER JOIN dbo.RateType RT WITH (NOLOCK) ON POD.ProductRateID=RT.ID
LEFT OUTER JOIN dbo.Product P WITH (NOLOCK) ON P.ID=POD.ProductID
WHERE POD.PurchaseOrderID=@purchaseOrderID
ORDER BY POD.Sequence
END 
	
	