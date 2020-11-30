IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_Ford_UHaulServiceEvents_old]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_Ford_UHaulServiceEvents_old] 
 END 
 GO  
CREATE VIEW [dbo].[vw_Ford_UHaulServiceEvents_old]
AS
SELECT	sr.ID ServiceRequestID
		, po.PurchaseOrderNumber
		, vi.ID VendorInvoiceID
		, UPPER(m.FirstName) FirstName
		, UPPER(m.LastName) LastName
		, COALESCE(po.IssueDate, sr.CreateDate) EventDate
		, COALESCE(pc.Name, sr_pc.Name) AS ServiceType
--		, srs.Name AS ServiceStatus
		, UPPER(c.VehicleVIN) VehicleVIN
		, c.VehicleYear
		, Case When ISNULL(c.VehicleMakeOther,'')<> '' THEN c.VehicleMakeOther ELSE c.VehicleMake END AS Make
		, Case When ISNULL(c.VehicleModelOther,'')<> '' THEN c.VehicleModelOther ELSE c.VehicleModel END AS Model
		, COALESCE(vi.PaymentAmount,po.PurchaseOrderAmount) TotalPOAmount
		--, po.PurchaseOrderAmount TotalPOAmount
		,Case When sr.AccountingInvoiceBatchID IS NOT NULL THEN 1 ELSE 0 END IsServiceRequestBilled
		,Case When po.AccountingInvoiceBatchID IS NOT NULL THEN 1 ELSE 0 END IsPurchaseOrderBilled
		,Case When vi.AccountingInvoiceBatchID IS NOT NULL THEN 1 ELSE 0 END IsVendorInvoiceBilled
FROM	[Case] c (nolock)
JOIN	Member m (nolock) ON m.ID = c.MemberID
JOIN	ServiceRequest sr (nolock) ON c.ID = sr.CaseID
JOIN	ServiceRequestStatus srs (nolock) on srs.ID = sr.ServiceRequestStatusID
JOIN	ProductCategory SR_pc on SR_pc.ID = sr.ProductCategoryID
LEFT JOIN	PurchaseOrder po (nolock) ON po.ServiceRequestID = sr.ID and po.IsActive = 1 AND po.PurchaseOrderStatusID = 2 --and ISNULL(po.IsGOA,0) = 0
LEFT JOIN	VendorInvoice vi (nolock) ON vi.PurchaseOrderID = po.ID --AND vi.AccountingInvoiceBatchID IS NOT NULL
LEFT JOIN	Product prod (nolock) ON prod.ID = po.ProductID
LEFT JOIN	ProductCategory pc (nolock) ON pc.id = prod.ProductCategoryID  
WHERE	((m.FirstName like '%U-Haul%' OR m.FirstName like '%U Haul%' OR (m.FirstName LIKE 'UHAUL' AND m.LastName <> 'Mike'))
		OR (m.LastName like '%U-Haul%' OR m.LastName LIKE '%U Haul%' OR (m.LastName LIKE 'UHAUL' AND m.FirstName NOT IN ('Carole','Lisa','Marion'))) )
	--AND COALESCE(po.IssueDate,sr.CreateDate) BETWEEN @StartDate AND dateadd(d,1,@EndDate)
	AND COALESCE(po.IssueDate,sr.CreateDate) >= '1/1/2015'
	AND srs.Name IN ('Complete', 'Cancelled')
GO

