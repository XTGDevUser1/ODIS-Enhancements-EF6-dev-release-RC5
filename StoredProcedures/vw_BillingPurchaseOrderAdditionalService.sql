IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_BillingPurchaseOrderAdditionalService]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_BillingPurchaseOrderAdditionalService] 
 END 
 GO  
CREATE VIEW [dbo].[vw_BillingPurchaseOrderAdditionalService]
AS

Select 
	c.ProgramID
	,(Select ID From Entity Where Name = 'PurchaseOrder') as EntityID_PurchaseOrder
	,po.ID as EntityKey_PurchaseOrder
	,pos.Name PurchaseOrderStatus
	,po.AccountingInvoiceBatchID
	,po.IssueDate as PurchaseOrderDate
	,pod.ExtendedAmount as Amount
	,prod.Name as ServiceCode
from PurchaseOrder po
Join PurchaseOrderStatus pos on pos.ID = po.PurchaseOrderStatusID
Join ServiceRequest sr on sr.ID = po.ServiceRequestID
Join [Case] c on c.ID = sr.CaseID
Join PurchaseOrderDetail pod on pod.PurchaseOrderID = po.ID
Join Product prod on prod.ID = pod.ProductID 
Join ProductType pt on pt.ID = Prod.ProductTypeID and pt.Name = 'Service'
Join ProductSubType pst on pst.ID = Prod.ProductSubTypeID and pst.Name = 'AdditionalService'
Where 1=1
and po.IsActive = 1
--and pos.Name = 'Issued'
GO

