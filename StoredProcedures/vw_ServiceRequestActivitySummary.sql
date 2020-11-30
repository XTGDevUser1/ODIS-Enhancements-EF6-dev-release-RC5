IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_ServiceRequestActivitySummary]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_ServiceRequestActivitySummary] 
 END 
 GO  
CREATE VIEW [dbo].[vw_ServiceRequestActivitySummary]
AS
Select 
	cl.ID ClientID
	,cl.Name Client
	,p.ID ProgramID
	,p.Name Program
	,sr.ID ServiceRequestID
	,CASE WHEN c.MemberID IS NULL THEN 'Non-Member'
		  WHEN c.MemberID IS NOT NULL AND POSummary.ServiceRequestID IS NULL		
			AND (prod.ID IS NULL OR prod.Name = 'Information') THEN 'Information'
		  WHEN c.MemberID IS NOT NULL AND POSummary.ServiceRequestID IS NULL		
			AND prod.Name = 'Tech' THEN 'TechAssist'
		  WHEN c.MemberID IS NOT NULL AND POSummary.ServiceRequestID IS NULL		
			AND prod.Name = 'Concierge' THEN 'Concierge'
		  WHEN c.MemberID IS NOT NULL AND POSummary.ServiceRequestID IS NULL		
			AND (prod.ID IS NOT NULL AND prod.Name NOT IN ('Information', 'Tech', 'Concierge')) THEN 'CancelledService'
		  WHEN POSummary.CancelledPOCount > 0 AND POSummary.IssuedPOCount = 0 THEN 'CancelledDispatch'
		  WHEN POSummary.IssuedPOCount > 0 AND POSummary.TowPOCount > 0 THEN 'Tow'
		  WHEN POSummary.IssuedPOCount > 0 AND POSummary.WinchPOCount > 0 THEN 'Winch'
		  WHEN POSummary.IssuedPOCount > 0 AND POSummary.FluidDeliveryPOCount > 0 THEN 'FluidDelivery'
		  WHEN POSummary.IssuedPOCount > 0 AND POSummary.LockoutPOCount > 0 THEN 'Lockout'
		  WHEN POSummary.IssuedPOCount > 0 AND POSummary.JumpStartPOCount > 0 THEN 'JumpStart'
		  WHEN POSummary.IssuedPOCount > 0 AND POSummary.MobileMechanicPOCount > 0 THEN 'MobileMechanic'
		  WHEN POSummary.IssuedPOCount > 0 AND POSummary.TireServicePOCount > 0 THEN 'Tire'
		  ELSE 'Dispatched' END ServiceRequestDisposition
	
	,ISNULL(POSummary.IssuedPOCount,0) IssuedPOCount
	,ISNULL(POSummary.FluidDeliveryPOCount,0) FluidDeliveryPOCount
	,ISNULL(POSummary.LockoutPOCount,0) LockoutPOCount
	,ISNULL(POSummary.JumpStartPOCount,0) JumpStartPOCount
	,ISNULL(POSummary.MobileMechanicPOCount,0) MobileMechanicPOCount
	,ISNULL(POSummary.TireServicePOCount,0) TireServicePOCount
	,ISNULL(POSummary.TowPOCount,0) TowPOCount
	,ISNULL(POSummary.WinchPOCount,0) WinchPOCount

	,ISNULL(POSummary.IssuedPOAmount,0) IssuedPOAmount
	,ISNULL(POSummary.FluidDeliveryPOAmount,0) FluidDeliveryPOAmount
	,ISNULL(POSummary.LockoutPOAmount,0) LockoutPOAmount
	,ISNULL(POSummary.JumpStartPOAmount,0) JumpStartPOAmount
	,ISNULL(POSummary.MobileMechanicPOAmount,0) MobileMechanicPOAmount
	,ISNULL(POSummary.TireServicePOAmount,0) TireServicePOAmount
	,ISNULL(POSummary.TowPOAmount,0) TowPOAmount
	,ISNULL(POSummary.WinchPOAmount,0) WinchPOAmount

	,COALESCE(POSummary.VehicleCategory, sr_vc.Name, case_vc.Name) VehicleCategory
from [Case] c
Join ServiceRequest sr on sr.CaseID = c.ID
Join ServiceRequestStatus srs on srs.ID = sr.ServiceRequestStatusID 
Left Outer Join Product prod on prod.ID = sr.PrimaryProductID
Left Outer Join VehicleCategory sr_vc on sr_vc.ID = sr.VehicleCategoryID
Left Outer Join VehicleCategory case_vc on case_vc.ID = c.VehicleCategoryID
Left Outer Join Program p on p.ID = c.ProgramID
Left Outer Join MemberSearchProgramGrouping msg on msg.ProgramID = p.ID and msg.[Grouping] = 1 
Left Outer Join Client cl on cl.ID = (CASE WHEN msg.ID IS NOT NULL THEN (SELECT ID FROM Client WHERE Name = 'Coach-Net') ELSE p.ClientID END)
Left Outer Join (
	Select 
		sr.ID ServiceRequestID
		,SUM(CASE WHEN pos.Name = 'Cancelled' Then 1 Else 0 END) CancelledPOCount
		,SUM(CASE WHEN pos.Name = 'Cancelled' Then po.PurchaseOrderAmount Else 0 END) CancelledPOAmount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA = 1 Then 1 Else 0 End) GOAPOCount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA = 1 Then po.PurchaseOrderAmount Else 0 End) GOAPOAmount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA <> 1 Then 1 Else 0 End) IssuedPOCount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA <> 1 Then po.PurchaseOrderAmount Else 0 End) IssuedPOAmount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA <> 1 and pc.Name = 'Fluid' Then 1 Else 0 End) FluidDeliveryPOCount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA <> 1 and pc.Name = 'Fluid' Then po.PurchaseOrderAmount Else 0 End) FluidDeliveryPOAmount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA <> 1 and pc.Name IN ('Home Locksmith','Lockout') Then 1 Else 0 End) LockoutPOCount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA <> 1 and pc.Name IN ('Home Locksmith','Lockout') Then po.PurchaseOrderAmount Else 0 End) LockoutPOAmount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA <> 1 and pc.Name = 'Jump' Then 1 Else 0 End) JumpStartPOCount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA <> 1 and pc.Name = 'Jump' Then po.PurchaseOrderAmount Else 0 End) JumpStartPOAmount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA <> 1 and pc.Name = 'Mobile' Then 1 Else 0 End) MobileMechanicPOCount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA <> 1 and pc.Name = 'Mobile' Then po.PurchaseOrderAmount Else 0 End) MobileMechanicPOAmount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA <> 1 and pc.Name = 'Tire' Then 1 Else 0 End) TireServicePOCount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA <> 1 and pc.Name = 'Tire' Then po.PurchaseOrderAmount Else 0 End) TireServicePOAmount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA <> 1 and pc.Name = 'Tow' Then 1 Else 0 End) TowPOCount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA <> 1 and pc.Name = 'Tow' Then po.PurchaseOrderAmount Else 0 End) TowPOAmount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA <> 1 and pc.Name = 'Winch' Then 1 Else 0 End) WinchPOCount
		,SUM(CASE WHEN pos.Name <> 'Cancelled' and po.IsGOA <> 1 and pc.Name = 'Winch' Then po.PurchaseOrderAmount Else 0 End) WinchPOAmount
		,MAX(CASE WHEN COALESCE(po_vc.Name, sr_vc.Name) = 'HeavyDuty' THEN 'Heavy Duty'
				  WHEN COALESCE(po_vc.Name, sr_vc.Name) = 'MediumDuty' THEN 'Medium Duty'
				  WHEN COALESCE(po_vc.Name, sr_vc.Name) = 'LightDuty' THEN 'Light Duty'
				  ELSE '' END) VehicleCategory
	From ServiceRequest sr
	Join PurchaseOrder po on po.ServiceRequestID = sr.ID
	Join Product prod on prod.ID = po.ProductID
	Join ProductCategory pc on pc.ID = prod.ProductCategoryID
	Join PurchaseOrderStatus pos on po.PurchaseOrderStatusID = pos.ID
	Left Outer Join VehicleCategory po_vc on po_vc.ID = prod.VehicleCategoryID
	Left Outer Join VehicleCategory sr_vc on sr_vc.ID = sr.VehicleCategoryID
	Where po.IsActive = 1
	and pos.Name <> 'Pending'
	Group By sr.ID
	) POSummary on POSummary.ServiceRequestID = sr.ID
Where 1=1
and c.ProgramID IS NOT NULL
and srs.Name in ('Complete','Cancelled')
--and c.CreateDate > '10/1/2015'


--ORDER BY 
--	cl.Name 
--	,p.Name 
--	,sr.ID
GO

