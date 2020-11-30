/****** Object:  View [dbo].[vw_ServiceCode]    Script Date: 01/12/2017 03:36:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/***

select	top 25000 *
from	vw_ServiceCode 
where	1=1
order by
		ServiceRequestID desc


***/

CREATE view [dbo].[vw_ServiceCode]
as


select	sr.ID as ServiceRequestID,
		po.ID as PurchaseOrderID,
		cast(
		case
		 when gor.[Description] is not null then 'GOA - ' + gor.[Description]
		 when cnr.[Description] is not  null then 'Cancel - ' + cnr.[Description]
		 when p4.[Description] is not null then p4.[Description]
		 when p1.[Description] is not null and po.ID is not null then p1.[Description]
		 when srs.Name ='Cancelled' and (p3.[Description] is not null or p1.[Description] is not null) then 'Cancelled Service'
		 when ca.[Description] = 'Cancelled Service' and (p4.[Description] is not null or p1.[Description] is not null) then ca.[Description]
		 when pc.Name = 'Tech' and DIAG.PrimaryVehicleDiagnosticCodeID is not null then 'Technician: ' + DIAG.PrimaryVehicleDiagnosticCodeName
		 when pc.[Description] is not null and pc.Name in ('Tech', 'Info', 'Concierge', 'Repair') then pc.[Description]
		 when ca.[Description] = 'Member will call back' then 'Cancel -' + ca.[Description]
		 when sr.MapTabStatus = 1 and sr.ServiceTabStatus in (3,4,5) then 'Cancelled'
		 else ca.[Description]
		end 
		as nvarchar(255)
		)as ServiceCode		

from	dbo.ServiceRequest sr with(nolock)
left join dbo.ServiceRequestStatus srs with(nolock) on sr.ServiceRequestStatusID = srs.ID
left join dbo.ProductCategory pc with(nolock) on sr.ProductCategoryID = pc.ID
left join dbo.Product p1 with(nolock) on sr.PrimaryProductID = p1.ID
--left join dbo.Product p2 with(nolock) on sr.SecondaryProductID = p2.ID
left join dbo.PurchaseOrder po with(nolock) on sr.ID  = po.ServiceRequestID  and po.IsActive = 1 
left join dbo.Product p3 with(nolock) on po.ProductID  = p3.ID
left join dbo.PurchaseOrderCancellationReason  cnr  with (nolock)on po.CancellationReasonID = cnr.id
left join dbo.PurchaseOrderGOAReason gor with (nolock) on gor.id= po.GOAReasonID
left join dbo.ContactLogLink cll with (nolock) on cll.EntityID  in (select ID from dbo.Entity with (nolock) where name in ('ServiceRequest','ServiceRequestDetail')) 
			and cll.RecordID  = sr.ID and cll.ID = (select MAX(id) from dbo.ContactLogLink clll with (nolock) where clll.EntityID in (13,14) and clll.RecordID = sr.ID)
left join dbo.contactlog cl with (nolock) on cll.ContactLogID = cl.ID
left join dbo.ContactCategory cc with (nolock) on cc.ID  = cl.ContactCategoryID
left join dbo.ContactLogAction cla with (nolock)on cl.ID = cla.ContactLogID and cla.ID  = (select MAX(claa.id) from dbo.ContactLogAction claa where cl.ID  = claa.ContactLogID  and claa.ContactActionID  is not null) 
left join dbo.ContactAction ca with (nolock) on ca.ID  = cla.ContactActionID 
left join	(select distinct pod.PurchaseOrderID, pod.ProductID from DMS.dbo.PurchaseOrderDetail pod with (nolock)) b  
			on	b.PurchaseOrderID = po.ID  
				and --if the po detail records have the same product as the po record then use it to define the product for the call
				b.ProductID =	(Case when po.ProductID = (select distinct pod1.productid from dms.dbo.PurchaseOrderDetail pod1 with (nolock) 
								where pod1.PurchaseOrderID = po.ID and pod1.ProductID = po.ProductID and pod1.ExtendedAmount > 0) then po.ProductID
					--if the productid from the Purchase order detail doesn't match the product id on the po record then use the max id from the purchase order detail
								else (select distinct max(pod2.productid) from dms.dbo.PurchaseOrderDetail pod2 with (nolock) 
								where pod2.PurchaseOrderID = po.ID) end)
----Get the lable for the Product Name
left join dms.dbo.Product p4 with (nolock) on p4.ID = b.ProductID
left outer  join -- Diagnostics
                  (select srvdc.ServiceRequestID,
                              srvdc.VehicleDiagnosticCodeID as PrimaryVehicleDiagnosticCodeID,
                              vdc.Name as PrimaryVehicleDiagnosticCodeName,
                             (select count(*)  from dbo.ServiceRequestVehicleDiagnosticCode dc1 with (nolock)
                                                      where dc1.ServiceRequestID = srvdc.ServiceRequestID) as VehicleDiagnosticCodeCount
                  from dbo.ServiceRequestVehicleDiagnosticCode srvdc with (nolock)
                        join dbo.VehicleDiagnosticCode vdc with (nolock) on vdc.ID  = srvdc.VehicleDiagnosticCodeID
                  where srvdc.IsPrimary = 1) DIAG  on DIAG.ServiceRequestID  = SR.ID
GO