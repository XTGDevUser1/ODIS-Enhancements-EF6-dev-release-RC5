IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_BillingInvoiceDetails]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_BillingInvoiceDetails] 
 END 
 GO 
CREATE VIEW [dbo].[vw_BillingInvoiceDetails]
AS

Select bi.Name InvoiceName
	,bi.[Description] InvoiceDescription
	,bi.ClientID
	,cl.Name Client
	,bid.ProgramID
	,pg.[Description] Program
	,bi.ID InvoiceID
	,bi.InvoiceDate
	,bi.InvoiceNumber
	,bi.InvoiceReferenceNumber
	--,bi.InvoiceTypeID
	--,bt.Name InvoiceType
	--,bi.PONumber
	--,bi.POPrefix
	--,bi.ScheduleDate
	,DATENAME(month, bi.ScheduleRangeBegin) InvoiceMonth
	,bi.ScheduleRangeBegin InvoiceRangeBegin
	,bi.ScheduleRangeEnd InvoiceRangeEnd
	,bil.[Description] InvoiceLineDescription
	,bil.LineCost InvoiceLineCost
	,bil.RateTypeID
	,rt.[Description] RateType
	,bil.ProductID
	,prod.[Description] Product
	,bid.[Description] ItemDescription
	,bid.ServiceCode
	--,bid.Name ItemName
	,bid.EntityID
	,e.Name Entity
	,bid.EntityKey EntityRecordID
	,bid.Quantity ItemQuantity
	,bid.EventAmount ItemAmount
	,bid.AccountingInvoiceBatchID
	--,bid.IsExcluded
	,CASE WHEN bcht.Name = 'ClientBillingUnbilled' THEN 0 ELSE 1 END IsBilled
	
	--,mbrCount.ID MemberCountID
	,Srt.ID ServiceRequestAgentTimeID
	
	,clm.ID ClaimID
	,COALESCE(po.ID, VendorInvoicePO.ID) PurchaseOrderID
	,COALESCE(po.PurchaseOrderNumber, VendorInvoicePO.PurchaseOrderNumber) PurchaseOrderNumber
	,vi.ID VendorInvoiceID
	,sr.ID ServiceRequestID
	,c.ID CaseID
	
	,mbr.ID MemberID
	,ms.ID MembershipID
	
	,COALESCE(be.[Description], bid.ExcludeReasonOther) ExcludeReason
	,ISNULL(bid.ExcludeComment,'') ExcludeComment
	,bid.ExcludedBy
	,ISNULL(bid.InternalComment,'') InternalComment

From BillingInvoice bi (NOLOCK)
--Join BillingInvoiceType bt (NOLOCK) on bt.ID = bi.InvoiceTypeID
Join Client cl (NOLOCK) on cl.ID = bi.ClientID
Join BillingSchedule bs (NOLOCK) on bs.ID = bi.BillingScheduleID
Join BillingInvoiceLine bil (NOLOCK) on bil.BillingInvoiceID = bi.ID
Join BillingInvoiceDetail bid (NOLOCK) on bid.BillingInvoiceLineID = bil.ID
Join Entity e (NOLOCK) on e.ID = bid.EntityID
Join Program pg (NOLOCK) on pg.ID = bid.ProgramID
Join Batch bch (NOLOCK) on bch.ID = bid.AccountingInvoiceBatchID
Join BatchType bcht (NOLOCK) on bcht.ID = bch.BatchTypeID
Left Outer Join Product prod (NOLOCK) on prod.ID = bil.ProductID
Left Outer Join RateType rt (NOLOCK) on rt.ID = bil.RateTypeID
Left Outer Join BillingExcludeReason be on be.ID = bid.ExcludeReasonID

---- Purchase Order Entity
LEFT OUTER JOIN PurchaseOrder PO (NOLOCK) on PO.ID = (CASE WHEN e.Name = 'PurchaseOrder' THEN bid.EntityKey ELSE NULL END)
---- Vendor Invoice Entity
LEFT OUTER JOIN VendorInvoice vi (NOLOCK) on vi.ID = (CASE WHEN e.Name = 'VendorInvoice' THEN bid.EntityKey ELSE NULL END)
LEFT OUTER JOIN PurchaseOrder VendorInvoicePO (NOLOCK) on VendorInvoicePO.ID = vi.PurchaseOrderID
---- Claim Entity
LEFT OUTER JOIN Claim clm (NOLOCK) on clm.ID = (CASE WHEN e.Name = 'Claim' THEN bid.EntityKey ELSE NULL END)
--LEFT OUTER JOIN ClaimType clType on clType.ID = clm.ClaimTypeID
--LEFT OUTER JOIN ProductCategory clProdCat on clProdCat.ID = clm.ServiceProductCategoryID
---- Member Entity (count)
---- Removed to eliminate dependency on DMS_Reporting 
--LEFT OUTER JOIN DMS_Reporting.MemberCounts.DMSMemberCounts mbrCount (NOLOCK) on mbrCount.ID = (CASE WHEN e.Name = 'MemberCounts' THEN bid.EntityKey ELSE NULL END)
---- Service Request Agent Time
LEFT OUTER JOIN ServiceRequestAgentTime srt (NOLOCK) on srt.ID = (CASE WHEN e.Name = 'ServiceRequestAgentTime' THEN bid.EntityKey ELSE NULL END)

---- Case / SR
LEFT OUTER JOIN ServiceRequest sr (NOLOCK) on sr.ID = COALESCE(po.ServiceRequestID, VendorInvoicePO.ServiceRequestID, srt.ServiceRequestID,(CASE WHEN e.Name = 'ServiceRequest' THEN bid.EntityKey ELSE NULL END))
LEFT OUTER JOIN [Case] c (NOLOCK) on c.ID = sr.CaseID

---- Membership / Member
LEFT OUTER JOIN Member mbr (NOLOCK) on mbr.ID = COALESCE(c.MemberID, clm.MemberID) --, mbrCount.MemberID)
LEFT OUTER JOIN Membership ms (NOLOCK) on ms.ID = mbr.MembershipID
GO

