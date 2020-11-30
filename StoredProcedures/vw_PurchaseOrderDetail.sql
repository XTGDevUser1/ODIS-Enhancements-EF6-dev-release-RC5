IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_PurchaseOrderDetail]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_PurchaseOrderDetail] 
 END 
 GO  
CREATE VIEW [dbo].[vw_PurchaseOrderDetail] 
AS
SELECT 
	pod.PurchaseOrderID
	,po.PurchaseOrderNumber
	,prod.ID ProductID
	,prod.Name ProductName
	,rt.Name RateType
	,pod.UnitOfMeasure
	,pod.ContractedRate
	,pod.Rate
	,pod.Quantity
	,pod.ExtendedAmount
	,pod.IsTaxable
	,pod.IsMemberPay 
FROM PurchaseOrder po
Join PurchaseOrderDetail pod on pod.PurchaseOrderID = po.ID
Join Product prod on prod.ID = pod.ProductID
Join RateType rt on rt.ID = pod.ProductRateID
WHERE pod.ExtendedAmount <> 0
GO

