IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_VendorContactLog]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_VendorContactLog] 
 END 
 GO  
CREATE VIEW [dbo].[vw_VendorContactLog]
AS
SELECT 
	cl.ContactLogID
	,cl.VendorLocationID
	,vl.VendorID
	,vl.VendorNumber
	,vl.VendorName
	,vl.Latitude VendorLocationLatitude
	,vl.Longitude VendorLocationLongitude
	,cl.CreateDate VendorContactDate
	,cl.ServiceRequestID ServiceRequest
	,po.PurchaseOrderNumber
	,po.IssueDate POIssueDate
	,po.ServiceLocationAddress
	,po.ServiceLocationCity
	,po.ServiceLocationCountryCode
	,po.ServiceLocationPostalCode
	,po.ServiceLocationLatitude
	,po.ServiceLocationLongitude
	,po.ProductDescription
	,po.VehicleCategoryDescription
	,po.PurchaseOrderStatusName
	,po.PurchaseOrderCancellationReason
	,Case WHEN po.VendorLocationID = cl.VendorLocationID THEN 1 ELSE 0 END IsAccepted
	,cla.ContactActionDescription
	,cl.VendorServiceRatingAdjustment
	,vl.IsUsingZipCodes
FROM vw_ContactLogs cl
Join vw_ContactLogActions cla on cla.ContactLogID = cl.ContactLogID
Join (Select ContactLogID, MAX(ContactLogActionID) ContactLogActionID
	From vw_ContactLogActions 
	Group By ContactLogID
	) LastAction on LastAction.ContactLogID = cla.ContactLogID and LastAction.ContactLogActionID = cla.ContactLogActionID 
Join vw_VendorLocations vl on vl.VendorLocationID = cl.VendorLocationID
Left Join vw_PurchaseOrders po on po.PurchaseOrderID = cl.PurchaseOrderID
where cl.ContactCategoryDescription = 'Vendor Selection'
GO

