ALTER TABLE [dbo].[BillingDefinitionInvoice]
ADD ScheduleDateTypeID INT NULL

ALTER TABLE [dbo].[BillingDefinitionInvoice]
ADD ScheduleRangeTypeID INT NULL


ALTER TABLE [dbo].[BillingDefinitionInvoice]  WITH CHECK ADD  CONSTRAINT [FK_BDI_ScheduleDateTypeID] FOREIGN KEY([ScheduleDateTypeID])
REFERENCES [dbo].[BillingScheduleDateType] ([ID])
GO

ALTER TABLE [dbo].[BillingDefinitionInvoice] CHECK CONSTRAINT [FK_BDI_ScheduleDateTypeID]
GO

ALTER TABLE [dbo].[BillingDefinitionInvoice]  WITH CHECK ADD  CONSTRAINT [FK_BDI_ScheduleRangeTypeID] FOREIGN KEY([ScheduleRangeTypeID])
REFERENCES [dbo].[BillingScheduleRangeType] ([ID])
GO


/****** Object:  UserDefinedFunction [dbo].[fnc_BillingVINModel]    Script Date: 10/23/2013 02:07:11 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_BillingVINModel]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_BillingVINModel]
GO


/****** Object:  UserDefinedFunction [dbo].[fnc_BillingVINModel]    Script Date: 10/23/2013 02:07:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- drop function dbo.fnc_BillingVINModel

-- select top 1000 dbo.fnc_BillingVINModel(VehicleVIN) as VINModel, *  from [case] where VehicleVin is not null

CREATE function [dbo].[fnc_BillingVINModel]
--ALTER function [dbo].[fnc_BillingVINModel]
(@pVIN as nvarchar(50)=null)
returns nvarchar(50)
as
begin

	declare @VINModel as nvarchar(50)

	select @VINModel = 

	case
		 when substring(@pVIN,2,1) <> 'F' then ''
		 when substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('e3','s3') then 'E-350'
		 when substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('e4','s4') then 'E-450'
		 when substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('f3','w3','x3') then 'F-350'
		 when substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('f4','w4','x4') then 'F-450'
		 when substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('f5','w5','x5') then 'F-550'
		 when substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('f6','w6','x6') then 'F-650'
		 when substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('f7','w7','x7') then 'F-750'
		 when substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('l4','l5') then 'LCF'
		 else 'Unidentified'
	end
	

return @VINModel

end



GO


/****** Object:  UserDefinedFunction [dbo].[fnc_BillingVINModelYear]    Script Date: 10/23/2013 02:07:02 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_BillingVINModelYear]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_BillingVINModelYear]
GO

/****** Object:  UserDefinedFunction [dbo].[fnc_BillingVINModelYear]    Script Date: 10/23/2013 02:07:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- drop function dbo.fnc_BillingVINModelYear

-- select top 1000 dbo.fnc_BillingVINModelYear(VehicleVIN) as VINModelYear, *  from [case] where VehicleVin is not null

CREATE function [dbo].[fnc_BillingVINModelYear]
--ALTER function [dbo].[fnc_BillingVINModelYear]
(@pVIN as nvarchar(50)=null)
returns nvarchar(4)
as
begin

	declare @VINModelYear as nvarchar(4)

	select @VINModelYear = 

	case 
		 when substring(@pVIN,10,1) = 'x' then '1999'
		 when substring(@pVIN,10,1) = 'y' then '2000'
		 when substring(@pVIN,10,1) = '1' then '2001'
		 when substring(@pVIN,10,1) = '2' then '2002'
		 when substring(@pVIN,10,1) = '3' then '2003'
		 when substring(@pVIN,10,1) = '4' then '2004'
		 when substring(@pVIN,10,1) = '5' then '2005'
		 when substring(@pVIN,10,1) = '6' then '2006'
		 when substring(@pVIN,10,1) = '7' then '2007'
		 when substring(@pVIN,10,1) = '8' then '2008'
		 when substring(@pVIN,10,1) = '9' then '2009'
		 when substring(@pVIN,10,1) = 'a' then '2010'
		 when substring(@pVIN,10,1) = 'b' then '2011'
		 when substring(@pVIN,10,1) = 'c' then '2012'
		 when substring(@pVIN,10,1) = 'd' then '2013'
		 when substring(@pVIN,10,1) = 'e' then '2014'
		 when substring(@pVIN,10,1) = 'f' then '2015'
		 when substring(@pVIN,10,1) = 'g' then '2016'
		 when substring(@pVIN,10,1) = 'h' then '2017'
		 when substring(@pVIN,10,1) = 'i' then '2018'
		 when substring(@pVIN,10,1) = 'j' then '2019'				 
	else '' 
	end	

return @VINModelYear

end

GO



/****** Object:  View [dbo].[vw_ServiceRequestComments]    Script Date: 10/23/2013 02:00:45 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_ServiceRequestComments]'))
DROP VIEW [dbo].[vw_ServiceRequestComments]
GO


/****** Object:  View [dbo].[vw_ServiceRequestComments]    Script Date: 10/23/2013 02:00:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/***

select	top 1000 * from vw_ServiceRequestComments
where	1=1


***/


CREATE view [dbo].[vw_ServiceRequestComments]
as

select	ServiceRequestID,
		ServiceRequestComments,
		ServiceRequestCommentsRaw,
		case
		 when isnull(PATINDEX ( '%<ClaimNum>%' ,  ServiceRequestComments), 0 ) <> 0
		 and isnull(PATINDEX ( '%</ClaimNum>%' ,  ServiceRequestComments), 0 ) <> 0
		then
			substring(
			 ServiceRequestComments, 
			 PATINDEX ( '%<ClaimNum>%' ,  ServiceRequestComments) + 10, 
			 (PATINDEX ( '%</ClaimNum>%' ,  ServiceRequestComments) - PATINDEX ( '%<ClaimNum>%' , ServiceRequestComments))-10
			)
		else null
		end as ServiceRequestCommentsClaimNum,
		case
		 when isnull(PATINDEX ( '%<PACode>%' ,  ServiceRequestComments), 0 ) <> 0
		 and isnull(PATINDEX ( '%</PACode>%' ,  ServiceRequestComments), 0 ) <> 0
		then
			substring(
			 ServiceRequestComments, 
			 PATINDEX ( '%<PACode>%' ,  ServiceRequestComments) + 8, 
			 (PATINDEX ( '%</PACode>%' ,  ServiceRequestComments) - PATINDEX ( '%<PACode>%' , ServiceRequestComments))-8
			)
		else null
		end as ServiceRequestCommentsPACode,
		case
		 when isnull(PATINDEX ( '%<DealerID>%' ,  ServiceRequestComments), 0 ) <> 0
		 and isnull(PATINDEX ( '%</DealerID>%' ,  ServiceRequestComments), 0 ) <> 0
		then
			substring(
			 ServiceRequestComments, 
			 PATINDEX ( '%<DealerID>%' ,  ServiceRequestComments) + 10, 
			 (PATINDEX ( '%</DealerID>%' ,  ServiceRequestComments) - PATINDEX ( '%<DealerID>%' , ServiceRequestComments))-10
			)
		else null
		end as ServiceRequestCommentsDealerID

from

	(select	ServiceRequestID,
			replace(replace(replace(replace(replace(replace(replace(replace(DTL.ServiceRequestComments, '</Comments></row><row><Comments>', ''), '<row>', ''),  '<Comments>', ''), '</row>', ''), '</Comments>', ''), '<row/>', ''), '&lt;', '<'), '&gt;', '>')
			as ServiceRequestComments,
			DTL.ServiceRequestComments as ServiceRequestCommentsRaw
	from	

		(select	C.RecordID as ServiceRequestID,
				C.EntityID,
				cast(
					(select	'~ ~ ~' + convert(nvarchar(20),CreateDate, 100) + ' : ' + [Description] as Comments
					 from	Comment cc
					 where	cc.EntityID = C.EntityID
					 and	cc.RecordID = C.RecordID
					 order by
							cc.CreateDate
					 FOR XML PATH)
					as nvarchar(max)) as ServiceRequestComments
		from	Comment C with (nolock)
		where	1=1
		and		C.EntityID in (select ID from Entity with (nolock) where Name = 'ServiceRequest')
		group by
				C.RecordID,
				C.EntityID) DTL) CMT


GO

/****** Object:  View [dbo].[vw_ServiceCode]    Script Date: 10/23/2013 02:03:13 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_ServiceCode]'))
DROP VIEW [dbo].[vw_ServiceCode]
GO


/****** Object:  View [dbo].[vw_ServiceCode]    Script Date: 10/23/2013 02:03:13 ******/
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
		 when ca.[Description] = 'Cancelled Service' and (p4.[Description] is not null or p1.[Description] is not null) then ca.[Description]
		 when srs.Name ='Cancelled' and (p4.[Description] is not null or p1.[Description] is not null) then 'Cancelled Service'
		 when p4.[Description] is not null and sr.DispatchTabStatus is not null then p4.[Description]
		 when p1.[Description] is not null and sr.DispatchTabStatus is not null and po.ID is not null then p1.[Description]
		 when pc.Name = 'Tech' and DIAG.PrimaryVehicleDiagnosticCodeID is not null then DIAG.PrimaryVehicleDiagnosticCodeName
		 when pc.[Description] is not null and pc.Name in ('Tech', 'Info', 'Concierge', 'Repair') then pc.[Description]

		 when ca.[Description] = 'Member will call back' and sr.DispatchTabStatus = 1 then 'Cancel -' + ca.[Description]
		 when sr.MapTabStatus = 1 and sr.DispatchTabStatus = 1 and sr.ServiceTabStatus in (3,4,5) then 'Canceled'
		 else ca.[Description]
		end 
		as nvarchar(255)
		)as ServiceCode		

from	dbo.ServiceRequest sr with(nolock)
left join dbo.ServiceRequestStatus srs with(nolock) on sr.ServiceRequestStatusID = srs.ID
left join dbo.ProductCategory pc with(nolock) on sr.ProductCategoryID = pc.ID
left join dbo.Product p1 with(nolock) on sr.PrimaryProductID = p1.ID
left join dbo.Product p2 with(nolock) on sr.SecondaryProductID = p2.ID
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
left join	(select distinct pod.PurchaseOrderID, pod.ProductID from dbo.PurchaseOrderDetail pod with (nolock)) b  
			on	b.PurchaseOrderID = po.ID  
				and --if the po detail records have the same product as the po record then use it to define the product for the call
				b.ProductID =	(Case when po.ProductID = (select distinct pod1.productid from dbo.PurchaseOrderDetail pod1 with (nolock) 
								where pod1.PurchaseOrderID = po.ID and pod1.ProductID = po.ProductID) then po.ProductID
					--if the productid from the Purchase order detail doesn't match the product id on the po record then use the max id from the purchase order detail
								else (select distinct max(pod2.productid) from dbo.PurchaseOrderDetail pod2 with (nolock) 
								where pod2.PurchaseOrderID = po.ID) end)
--Get the lable for the Product Name
left join dbo.Product p4 with (nolock) on p4.ID = b.ProductID
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




/****** Object:  View [dbo].[vw_BillingServiceRequestsPurchaseOrders]    Script Date: 10/23/2013 01:59:32 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_BillingServiceRequestsPurchaseOrders]'))
DROP VIEW [dbo].[vw_BillingServiceRequestsPurchaseOrders]
GO

/****** Object:  View [dbo].[vw_BillingServiceRequestsPurchaseOrders]    Script Date: 10/23/2013 01:59:32 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/***

select	* from vw_BillingServiceRequestsPurchaseOrders
where	1=1
and		ProgramCode = 'FORDCOMM_MFG'
and		ServiceRequestDate >= '06/01/2013'
and		ServiceRequestDate <= '06/30/2013'


select	* from vw_BillingServiceRequestsPurchaseOrders
where	1=1
and		ProgramCode = 'FORDTOW'
and		ServiceRequestDate >= '10/01/2013'
and		ServiceRequestDate <= '12/30/2013'
and		ServiceRequestID = 152527


***/


CREATE view [dbo].[vw_BillingServiceRequestsPurchaseOrders]
as
select	ServiceRequestID,
		ServiceRequestStatus,
		ServiceRequestDate,
		ServiceRequestDatetime,
		ClientID,
		ClientName,
		ProgramID,
		ProgramName,
		ProgramCode,
		MemberID,
		LastName,
		FirstName,
		MembershipNumber,
		MemberSinceDate,
		EffectiveDate,
		ExpirationDate,
		MemberCreateDate,
		MemberCreateDatetime,
		PurchaseOrderID,
		PurchaseOrderNumber,
		PurchaseOrderDate,
		PurchaseOrderDatetime,
		PurchaseOrderStatus,
		PurchaseOrderIsActive,
		ContactLastName,
		ContactFirstName,
		VIN,
		VehicleYear,
		VehicleMake,
		VehicleModel,
		VINModelYear,
		VINModel,
		VehicleCurrentMileage,
		VehicleMileageUOM,
		VehicleLicenseNumber,
		VehicleLicenseState,
		SRPrimaryProductCat,
		SRPrimaryProductID,
		SRPrimaryProductDescription,
		SRPrimaryProductCategoryDescription,
		SRSecondaryProductID,
		SRSecondProductDescription,
		SRSecondaryProductCategoryDescription,
		ServiceCode,
		POProductID,
		POProductDescription,
		POPProductCategoryDescription,
		PODetailProductID,
		PODetailProductDescription,
		PODetailProductCategoryDescription,
		ServiceLocationAddress,
		ServiceLocationCity,
		ServiceLocationStateProvince,
		DestinationDescription,
		DestinationCity,
		DestinationStateProvince,
		TotalServiceAmount,
		CoachNetServiceAmount,
		MemberServiceAmount,
		PurchaseOrderAmount,
		ServiceRequestCCPaymentsReceived,
		IsPaidByCompanyCC,
		BillingApprovalCode,
		IsCancelledSR,
		IsDispatchIntended,
		IsDispatched,
		IsCancelledPO,
		GOAReason,
		IsVendorPay,
		IsMemberPay,
		IsReDispatch,
		IsTechAssistance,
		IsDiagnostics,
		IsVerifyService,
		IsISPSelection,
		IsInfoContact,
		IsNoMemberOnService,
		IsMbrManuallyCreated,
		IsImpoundRelease,
		IsOutOfWarranty,
		
		IsDirectTowApprovedDestination,
		DispatchFee,
		DispatchFeeBillToName,
		VendorID,
		VendorNumber,
		VendorLocationID,
		DealerNumber,
		PACode,

		PrimaryVehicleDiagnosticCodeID,
		PrimaryVehicleDiagnosticCodeName,
		VehicleDiagnosticCodeCount,
		InboundContactsTOTAL,
		InboundContactsNEWCALL,
		InboundContactsCUSTOMER,
		InboundContactsVENDOR,
		InboundContactsCLOSEDLOOP,
		InboundContactsOTHER,
		OutboundContactsTOTAL,
		OutboundContactsNEWCALL,
		OutboundContactsCUSTOMER,
		OutboundContactsVENDOR,
		OutboundContactsCLOSEDLOOP,
		OutboundContactsOTHER,
		cast(case when IsDispatchIntended = 1 then 1 else 0 end as int) as DISPATCH,
		cast(case when IsDispatchIntended = 0 then 1 else 0 end as int) as NON_DISPATCH,
		cast(case 
				when IsDispatchIntended = 0 
				and (IsTechAssistance = 1
					 or IsDiagnostics = 1
					 or IsVerifyService = 1
					 or IsISPSelection = 1)
				then 1 else 0 
				end
			as int) as CUSTOMER_ASSISTANCE,
		cast(case 
				when IsDispatchIntended = 0 
				and IsTechAssistance = 0
				and	IsDiagnostics = 0
				and	IsVerifyService = 0
				and	IsISPSelection = 0
				and IsInfoContact = 1
				then 1 else 0 
				end
			as int) as INFO,
		cast(case 
				when IsDispatchIntended = 0 
				and IsTechAssistance = 0
				and	IsDiagnostics = 0
				and	IsVerifyService = 0
				and	IsISPSelection = 0
				and IsInfoContact = 0
				then 1 else 0 
				end
			as int) as OTHER,
		cast(case 
				when IsDispatched = 1
				and IsVendorPay = 1
				then 1 else 0
				end 
			as int) as PASS_THRU,

		AccountingInvoiceBatchID_ServiceRequest,
		AccountingInvoiceBatchID_PurchaseOrder,

		ServiceRequestComments,
		ServiceRequestCommentsClaimNum,
		ServiceRequestCommentsPACode,
		ServiceRequestCommentsDealerID,

		(select ID from dbo.Entity with (nolock) where Name = 'ServiceRequest') as EntityID_ServiceRequest,
		ServiceRequestID as  EntityKey_ServiceRequest,
		(select ID from dbo.Entity with (nolock) where Name = 'PurchaseOrder') as EntityID_PurchaseOrder,
		PurchaseOrderID as  EntityKey_PurchaseOrder


from
		(select	sr.ID as ServiceRequestID,
				srs.Name as ServiceRequestStatus,
				convert(date, sr.CreateDate) as ServiceRequestDate,
				sr.CreateDate as ServiceRequestDatetime,
				cl.ID as ClientID,
				cl.Name as ClientName,
				(CASE WHEN ISNULL(ca.ProgramID,0) <> 0 THEN COALESCE(mbr.ProgramID, ca.ProgramID, 0) ELSE 0 END) as ProgramID,
				pro.Name as ProgramName,
				pro.Code as ProgramCode,
				mbr.ID as MemberID,
				mbr.LastName,
				mbr.FirstName,
				mbrs.MembershipNumber,
				mbr.MemberSinceDate,
				mbr.EffectiveDate,
				convert(date, mbr.CreateDate) as MemberCreateDate,
				mbr.CreateDate as MemberCreateDatetime,
				mbr.ExpirationDate,
				ca.ContactLastName,
				ca.ContactFirstName,

				ca.VehicleVIN as VIN,
				ca.VehicleYear,
				ca.VehicleMake,
				ca.VehicleModel,
				dbo.fnc_BillingVINModelYear(ca.VehicleVIN) as VINModelYear,
				dbo.fnc_BillingVINModel(ca.VehicleVIN) as VINModel,
				ca.VehicleCurrentMileage,
				ca.VehicleMileageUOM,
				ca.VehicleLicenseNumber,
				ca.VehicleLicenseState,
								
				-- SR Product Category
				srpc.Name as SRPrimaryProductCat,
				
				-- SR Primary Product
				srpr.ID as SRPrimaryProductID,
				srpr.[Description] as SRPrimaryProductDescription,
				srprpc.[Description] as SRPrimaryProductCategoryDescription,
				
				-- SR Secondary Product
				srpr2.ID as SRSecondaryProductID,
				srpr2.[Description] as SRSecondProductDescription,
				srprpc2.[Description] as SRSecondaryProductCategoryDescription,
				
				-- PO Product
				popr.ID as POProductID,
				popr.[Description] as POProductDescription,
				popc.[Description] as POPProductCategoryDescription,
				
				-- PO Detail Product
				p4.ID as PODetailProductID,
				p4.[Description] as PODetailProductDescription,
				p4pc.[Description] as PODetailProductCategoryDescription,
				
				scv.ServiceCode,
				
				sr.ServiceLocationAddress,
				sr.ServiceLocationCity,
				sr.ServiceLocationStateProvince,

				sr.DestinationDescription,
				sr.DestinationCity,
				sr.DestinationStateProvince,
								
				po.ID as PurchaseOrderID,
				po.PurchaseOrderNumber,
				convert(date, po.CreateDate) as PurchaseOrderDate,
				po.CreateDate as PurchaseOrderDatetime,
				pos.Name as PurchaseOrderStatus,
				po.IsActive as PurchaseOrderIsActive,
				po.TotalServiceAmount,
				po.CoachNetServiceAmount,
				po.MemberServiceAmount,
				po.PurchaseOrderAmount,
				CC.ServiceRequestCCPaymentsReceived,
				
				cast(
				 case
				 when po.IsPayByCompanyCreditCard = 1 and po.CompanyCreditCardNumber is not null then 1
				 else 0
				end 
				as int) as IsPaidByCompanyCC,
				
				cast(null as nvarchar(50)) as BillingApprovalCode,  -- NEED TO GET QFC BILLING CODE HERE

				cast(
				case
				 when srs.Name = 'Cancelled' then 1
				 else 0
				end as int) as IsCancelledSR,
				cast(
					case
					when	po.ID is null and COALESCE(popc.Name, srpc.Name) = 'Tech' then 0 -- 1. No PO and Tech then No DispatchIntended
					when	po.ID is not null then 1 -- 2. Has a PO, then DispatchIntended
					when	-- 3. When Member Data, Vehicle Data, Is of Dispatch Concern, and Location then DispatchIntended
							(mbrs.MembershipNumber is not null -- Member Data
							 and	(ca.VehicleYear is not null -- Vehicle Data
									 or ca.VehicleMake is not null
									 or ca.VehicleModel is not null)
							 and	COALESCE(popc.Name, srpc.Name) in ('Tow', 'Tire', 'Lockout', 'Fluid', 'Jump', 'Winch', 'Tech', 'Mobile', 'Repair') -- is of Dispatch Concern
							 and	sr.ServiceLocationAddress is not null
							 and	sr.ServiceLocationCity is not null
							 and	sr.ServiceLocationStateProvince is not null) then 1
					else 0
					end as int) as IsDispatchIntended,
					cast(
					case
					 when po.ID is not null then 1
					 else 0
					end as int)	as IsDispatched,
					cast(
					case
					 when pos.Name = 'Cancelled' then 1
					 else 0
					end as int)as IsCancelledPO,
					pocr.[Description] as CancelledPOReason,
					isnull(cast(po.IsGOA as int), 0) as IsGOA,
					goa.[Description] as GOAReason,
					case
					 when po.PurchaseOrderAmount > 0.00 then 1
					 else 0
					end as IsVendorPay,
					case
					-- when (po.MemberServiceAmount = po.TotalServiceAmount) and po.PurchaseOrderAmount = 0.00 then 1
					 when (po.MemberServiceAmount = po.TotalServiceAmount) and po.TotalServiceAmount <> 0.00 then 1
					 else 0
					end as IsMemberPay,
					cast(
					case
					 when isnull(CLOG.ReDispatchContact, 0) > 0 then 1
					 else 0
					end as int) as IsReDispatch,
					cast(
					case
					 when COALESCE(popc.Name, srpc.Name) = 'Tech' or IsWorkedByTech = 1 then 1
					 else 0
					end as int) as IsTechAssistance,
					cast(
					case
					 when isnull(DIAG.VehicleDiagnosticCodeCount, 0) > 0 then 1
					 else 0
					end as int) as IsDiagnostics,
					cast(
					case
					 when isnull(CLOG.VerifyServiceContact, 0) > 0 then 1
					 else 0
					end as int) as IsVerifyService,
					cast(
					case
					 when isnull(CLOG.ISPSelectionContact, 0) > 0 then 1
					 else 0
					end as int) as IsISPSelection,
					cast(
					case
					 when COALESCE(popc.Name, srpc.Name) like '%Info%' then 1 -- Info Product
					 when isnull(CLOG.InfoContact, 0) > 0 then 1 -- Coded with Info Contact
					 else 0
					end as int) as IsInfoContact,
					cast(
					case
					 when mbr.ID is null then 1
					 else 0
					end as int) as IsNoMemberOnService,
					cast(
					case
					 when mbr.CreateBy not in ('System', 'DISPATCHPOST') then 1
					 else 0
					end as int) as IsMbrManuallyCreated,
					cast(
					case
					 when IMP.PurchaseOrderID is not null then 1
					 else 0
					end as int) as IsImpoundRelease,
					cast(
					case
					 when isnull(CLOG.OutOfWarrantyContact, 0) > 0 then 1
					 else 0
					end as int) as IsOutOfWarranty,

					DT.IsDirectTowApprovedDestination,
					po.DispatchFee,
					bt.Name as DispatchFeeBillToName,
					
					-- Direct Tow
					DT.VendorID,
					DT.VendorNumber,
					DT.VendorLocationID,
					DT.DealerNumber,
					DT.PACode,
					
					-- Diagnostics
					DIAG.PrimaryVehicleDiagnosticCodeID,
					DIAG.PrimaryVehicleDiagnosticCodeName,
					isnull(DIAG.VehicleDiagnosticCodeCount, 0) as VehicleDiagnosticCodeCount,

					-- Contacts
					InboundContactsTOTAL,
					InboundContactsNEWCALL,
					InboundContactsCUSTOMER,
					InboundContactsVENDOR,
					InboundContactsCLOSEDLOOP,
					InboundContactsOTHER,
					OutboundContactsTOTAL,
					OutboundContactsNEWCALL,
					OutboundContactsCUSTOMER,
					OutboundContactsVENDOR,
					OutboundContactsCLOSEDLOOP,
					OutboundContactsOTHER,
					
					sr.AccountingInvoiceBatchID as AccountingInvoiceBatchID_ServiceRequest,
					po.AccountingInvoiceBatchID as AccountingInvoiceBatchID_PurchaseOrder,

					-- Comments
					CMT.ServiceRequestComments,
					CMT.ServiceRequestCommentsClaimNum,
					CMT.ServiceRequestCommentsPACode,
					CMT.ServiceRequestCommentsDealerID
		
		from	dbo.ServiceRequest sr with (nolock)
		left outer join dbo.ProductCategory srpc with (nolock) on srpc.ID = sr.ProductCategoryID
		left outer join dbo.ServiceRequestStatus srs with (nolock) on srs.ID = sr.ServiceRequestStatusID
		left outer join dbo.[Case] ca with (nolock) on ca.ID = sr.CaseID
		left outer join dbo.CaseStatus cas with (nolock) on cas.ID = ca.CaseStatusID
		left outer join PurchaseOrder po with (nolock) on sr.ID = po.ServiceRequestID
		left outer join dbo.ContactMethod cm with (nolock) on cm.ID = po.ContactMethodID
		left outer join dbo.PurchaseOrderType pot with (nolock) on pot.ID = po.PurchaseOrderTypeID
		left outer join dbo.PurchaseOrderStatus pos with (nolock) on pos.ID = po.PurchaseOrderStatusID
		left outer join dbo.PurchaseOrderCancellationReason pocr with (nolock) on pocr.ID = po.CancellationReasonID
		left outer join dbo.CurrencyType ct with (nolock) on ct.ID = po.CurrencyTypeID
		left outer join dbo.PaymentType pt with (nolock) on pt.ID = po.MemberPaymentTypeID
		left outer join dbo.PurchaseOrderGOAReason goa with (nolock) on goa.ID = po.GOAReasonID
		left outer join dbo.Product popr with (nolock) on popr.ID = po.ProductID
		left outer join dbo.ProductCategory popc with (nolock) on popc.ID = popr.ProductCategoryID

		left outer join dbo.Member mbr with (nolock) on mbr.ID = ca.MemberID
		left outer join dbo.Membership mbrs with (nolock) on mbrs.ID = mbr.MembershipID
		left outer join dbo.Program pro with (nolock) on pro.ID = (CASE WHEN ISNULL(ca.ProgramID,0) <> 0 THEN COALESCE(mbr.ProgramID, ca.ProgramID, 0) ELSE 0 END)
		left outer join dbo.Program pra with (nolock) on pra.ID = pro.ParentProgramID
		left outer join dbo.Client cl with (nolock) on cl.ID = pro.ClientID
		left outer join dbo.Product srpr with (nolock) on srpr.ID = sr.PrimaryProductID
		left outer join dbo.ProductCategory srprpc with (nolock) on srprpc.ID = srpr.ProductCategoryID
		left outer join dbo.Product srpr2 with (nolock) on srpr2.ID = sr.SecondaryProductID
		left outer join dbo.ProductCategory srprpc2 with (nolock) on srprpc2.ID = srpr2.ProductCategoryID
		left outer join dbo.BillTo bt with (nolock) on bt.ID = po.DipatchFeeBillToID
		
		-- To Get the Service Code
		left outer join vw_ServiceCode scv on scv.ServiceRequestID = sr.ID
				and isnull(scv.PurchaseOrderID, -999) = isnull(po.ID, -999)

		left outer join	
		
				(select distinct pod.PurchaseOrderID, pod.ProductID from dbo.PurchaseOrderDetail pod with (nolock)) b  
						on	b.PurchaseOrderID = po.ID  
							and --if the po detail records have the same product as the po record then use it to define the product for the call
							b.ProductID =	(Case when po.ProductID = (select distinct pod1.productid from dbo.PurchaseOrderDetail pod1 with (nolock) 
											where pod1.PurchaseOrderID = po.ID and pod1.ProductID = po.ProductID) then po.ProductID
								--if the productid from the Purchase order detail doesn't match the product id on the po record then use the max id from the purchase order detail
											else (select distinct max(pod2.productid) from dbo.PurchaseOrderDetail pod2 with (nolock) 
											where pod2.PurchaseOrderID = po.ID) end)
			--Get the lable for the Product Name
		left outer join dbo.Product p4 with (nolock) on p4.ID = b.ProductID	
		left outer join dbo.ProductCategory p4pc with (nolock) on p4pc.ID = p4.ProductCategoryID	


		left outer join -- Diagnostics

				(select	srvdc.ServiceRequestID,
						srvdc.VehicleDiagnosticCodeID as PrimaryVehicleDiagnosticCodeID,
						vdc.Name as PrimaryVehicleDiagnosticCodeName,
						(select count(*)
						 from	ServiceRequestVehicleDiagnosticCode dc1 with (nolock)
						 where	dc1.ServiceRequestID = srvdc.ServiceRequestID) as VehicleDiagnosticCodeCount
				 from	ServiceRequestVehicleDiagnosticCode srvdc with (nolock)
				 join	VehicleDiagnosticCode vdc with (nolock) on vdc.ID = srvdc.VehicleDiagnosticCodeID
				 where	srvdc.IsPrimary = 1) DIAG on DIAG.ServiceRequestID = SR.ID

		left outer join -- Contact Logs

				(select	sr2.ID as ServiceRequestID,
						-- Inbound
						count(distinct 
							  case when cl.Direction = 'Inbound' then cl.ID
							  else null
							  end) as InboundContactsTOTAL,
						count(distinct
							  case when cl.Direction = 'Inbound' and cc.Name = 'NewCall' then cl.ID
							  else null
							  end) as InboundContactsNEWCALL,
						count(distinct
							  case when cl.Direction = 'Inbound' and cc.Name in ('ContactCustomer', 'CustomerCallback') then cl.ID
							  else null
							  end) as InboundContactsCUSTOMER,
						count(distinct
							  case when cl.Direction = 'Inbound' and cc.Name in ('ContactVendor', 'VendorCallback', 'VendorSelection') then cl.ID
							  else null
							  end) as InboundContactsVENDOR,
						count(distinct
							  case when cl.Direction = 'Inbound' and cc.Name in ('ClosedLoop') then cl.ID
							  else null
							  end) as InboundContactsCLOSEDLOOP,
						count(distinct
							  case when cl.Direction = 'Inbound' and cc.Name not in 
							  ('NewCall', 'ContactCustomer', 'CustomerCallback', 'ContactVendor', 'VendorCallback', 'VendorSelection', 'ClosedLoop')
							  then cl.ID
							  else null
							  end) as InboundContactsOTHER,
						-- Outbound
						count(distinct 
							  case when cl.Direction = 'Outbound' then cl.ID
							  else null
							  end) as OutboundContactsTOTAL,
						count(distinct
							  case when cl.Direction = 'Outbound' and cc.Name = 'NewCall' then cl.ID
							  else null
							  end) as OutboundContactsNEWCALL,
						count(distinct
							  case when cl.Direction = 'Outbound' and cc.Name in ('ContactCustomer', 'CustomerCallback') then cl.ID
							  else null
							  end) as OutboundContactsCUSTOMER,
						count(distinct
							  case when cl.Direction = 'Outbound' and cc.Name in ('ContactVendor', 'VendorCallback', 'VendorSelection') then cl.ID
							  else null
							  end) as OutboundContactsVENDOR,
						count(distinct
							  case when cl.Direction = 'Outbound' and cc.Name in ('ClosedLoop') then cl.ID
							  else null
							  end) as OutboundContactsCLOSEDLOOP,
						count(distinct
							  case when cl.Direction = 'Outbound' and cc.Name not in 
							  ('NewCall', 'ContactCustomer', 'CustomerCallback', 'ContactVendor', 'VendorCallback', 'VendorSelection', 'ClosedLoop')
							  then cl.ID
							  else null
							  end) as OutboundContactsOTHER,
						count(distinct
							  case when ca.Name like '%Information%'
							  then cl.ID
							  else null
							  end) as InfoContact,
						count(distinct
							  case when cr.Name = 'Verify Service'
							  then cl.ID
							  else null
							  end) as VerifyServiceContact,
						count(distinct
							  case when cr.Name = 'ISP Selection'
							  then cl.ID
							  else null
							  end) as ISPSelectionContact,				  				  
						count(distinct
							  case when cr.Name = 'Re-dispatch'
							  then cl.ID
							  else null
							  end) as ReDispatchContact,
						count(distinct
							  case when ca.Name = 'OutOfWarranty'
							  then cl.ID
							  else null
							  end) as OutOfWarrantyContact
				from	contactlog cl with (nolock)
				join	contactloglink cll with (nolock) on cl.id = cll.contactlogid and cll.EntityID = (select ID from Entity where Name = 'ServiceRequest')
				join	servicerequest sr2 with (nolock) on sr2.id = cll.recordid
				join	contactcategory cc with (nolock) on cl.contactcategoryid = cc.id
				join	contactlogReason clr with (nolock) on cl.id = clr.contactlogid
				join	contactreason cr with (nolock) on clr.ContactReasonID = cr.ID
				join	contactlogaction cla with (nolock) on cl.id = cla.contactlogid
				join	contactaction ca with (nolock) on cla.ContactActionID = ca.ID
				group by
						sr2.ID) CLOG on CLOG.ServiceRequestID = SR.ID

		left outer join -- Impound Release Fees
					
					(select	distinct po.ID as PurchaseOrderID
					 from	dbo.PurchaseOrder po with (nolock)
					 join	dbo.PurchaseOrderDetail pod with (nolock) on pod.PurchaseOrderID = po.ID
					 join	dbo.Product pr with (nolock) on pr.ID = pod.ProductID
					 where	pr.Name = 'Impound Release Fee'
					) IMP on IMP.PurchaseOrderID = po.ID


		left outer join	-- Direct Tow Destination Attributes
		
					(select	v.ID as VendorID,
							v.VendorNumber,
							vl.ID as VendorLocationID,
							vl.DealerNumber,
							cast(null as nvarchar(50)) as PACode,
							cast(1 as int) as IsDirectTowApprovedDestination
					from	Vendor v with (nolock)
					left outer join	VendorLocation vl with (nolock) on vl.VendorID = v.ID
					left outer join	VendorLocationProduct vlp with (nolock) on vlp.VendorLocationID = vl.ID
					left outer join	Product pr with (nolock) on pr.ID = vlp.ProductID
					where	1=1
					and		pr.Name = 'Ford Direct Tow') DT on DT.VendorLocationID = sr.DestinationVendorLocationID
					
		left outer join -- Service Request CC Payments Received

					(select	sr.ID as ServiceRequestID,
							sum(pmt.Amount) ServiceRequestCCPaymentsReceived
					from	Payment pmt with (nolock)
					join	PaymentStatus ps on ps.ID = pmt.PaymentStatusID
							and ps.Name = 'Approved'
					join	PaymentType pt on pt.ID = pmt.PaymentTypeID
					join	PaymentCategory pc on pc.ID = pt.PaymentCategoryID
							and pc.Name = 'CreditCard'
					join	ServiceRequest sr on sr.ID = pmt.ServiceRequestID
					join	PaymentReason pr on pr.ID = pmt.PaymentReasonID
					group by
							sr.ID) CC on CC.ServiceRequestID = sr.ID
							
		Left outer join dbo.vw_ServiceRequestComments CMT on CMT.ServiceRequestID = sr.ID -- Service Request Comments


			) DTL
	where	1=1


GO


/****** Object:  View [dbo].[vw_BillingVendorInvoices]    Script Date: 10/23/2013 02:30:42 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_BillingVendorInvoices]'))
DROP VIEW [dbo].[vw_BillingVendorInvoices]
GO

/****** Object:  View [dbo].[vw_BillingVendorInvoices]    Script Date: 10/23/2013 02:30:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/***

select	* from vw_BillingVendorInvoices
where	1=1
and		ProgramCode = 'TRLRCARE'
and		ReceivedDate >= '06/01/2013'
and		ReceivedDate <= '06/30/2013'


***/


CREATE view [dbo].[vw_BillingVendorInvoices]
as
	select	vi.ID as VendorInvoiceID,
			vi.PurchaseOrderID,
			vpo.PurchaseOrderNumber,
			vpo.ServiceRequestID,
			vpo.ServiceRequestDate,
			vpo.ServiceRequestDatetime,
			vpo.ClientID,
			vpo.ClientName,
			vpo.ProgramID,
			vpo.ProgramName,
			vpo.ProgramCode,
			vpo.MemberID,
			vpo.MembershipNumber,
			vpo.LastName,
			vpo.FirstName,
			vpo.MemberSinceDate,
			vpo.EffectiveDate,
			vpo.ExpirationDate,
			vpo.MemberCreateDate,
			vpo.MemberCreateDatetime,
			vpo.ContactLastName,
			vpo.ContactFirstName,
			vpo.TotalServiceAmount,
			vpo.MemberServiceAmount,
			vpo.PurchaseOrderAmount,
			vpo.ServiceRequestCCPaymentsReceived,
			vpo.BillingApprovalCode,
			vpo.VIN,
			vpo.VehicleYear,
			vpo.VehicleMake,
			vpo.VehicleModel,
			vpo.VINModelYear,
			vpo.VINModel,
			vpo.VehicleCurrentMileage,
			vpo.VehicleMileageUOM,
			vpo.VehicleLicenseNumber,
			vpo.VehicleLicenseState,

			vpo.IsDirectTowApprovedDestination,
			vpo.DispatchFee,
			vpo.DispatchFeeBillToName,
			vpo.VendorNumber,
			vpo.VendorLocationID,
			vpo.DealerNumber,
			vpo.PACode,

			vpo.ServiceCode,
			vpo.isMemberPay,
			
			vpo.GOAReason,
			
			vi.VendorID,
			vi.VendorInvoiceStatusID,
			vi.SourceSystemID,
			vi.PaymentTypeID,
			vi.InvoiceNumber,
			convert(date, vi.ReceivedDate) as ReceivedDate,
			vi.ReceivedDate as ReceivedDatetime,
			vi.ReceiveContactMethodID,
			convert(date, vi.InvoiceDate) as InvoiceDate,
			vi.InvoiceDate as InvoiceDatetime,
			vi.InvoiceAmount,
			vi.BillingBusinessName,
			vi.BillingContactName,
			vi.BillingAddressLine1,
			vi.BillingAddressLine2,
			vi.BillingAddressLine3,
			vi.BillingAddressCity,
			vi.BillingAddressStateProvince,
			vi.BillingAddressPostalCode,
			vi.BillingAddressCountryCode,
			convert(date, vi.ToBePaidDate) as ToBePaidDate,
			vi.ToBePaidDate as ToBePaidDatetime,
			vi.ExportDate,
			vi.ExportBatchID,
			convert(date, vi.PaymentDate) as PaymentDate,
			vi.PaymentDate as PaymentDatetime,
			vi.PaymentAmount,
--			vi.CheckNumber,
			vi.CheckClearedDate,
			vi.ActualETAMinutes,
			vi.Last8OfVIN,
			vi.VehicleMileage,
			vi.AccountingInvoiceBatchID,
			vi.IsActive,
			vi.CreateDate as VendorInvoiceCreateDate,
			vi.CreateBy as VendorInvoiceCreatedBy,
			
			(select ID from dbo.Entity with (nolock) where Name = 'VendorInvoice') as EntityID,
			vi.ID as  EntityKey

from	dbo.VendorInvoice vi with (nolock)
left outer join dbo.VendorInvoiceException vie with (nolock) on vie.VendorInvoiceID = vi.ID
left outer join dbo.VendorInvoiceStatus vis with (nolock) on vis.ID = vi.VendorInvoiceStatusID
left outer join dbo.Vendor ven with (nolock) on ven.ID = vi.VendorID
left outer join dbo.PaymentType pt with (nolock) on pt.ID = vi.PaymentTypeID

left outer join vw_BillingServiceRequestsPurchaseOrders vpo on vpo.PurchaseOrderID = vi.PurchaseOrderID

GO


/****** Object:  View [dbo].[vw_BillingClaims]    Script Date: 10/23/2013 02:32:18 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_BillingClaims]'))
DROP VIEW [dbo].[vw_BillingClaims]
GO

/****** Object:  View [dbo].[vw_BillingClaims]    Script Date: 10/23/2013 02:32:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/***

select	* from vw_BillingClaims
where	1=1
and		ProgramCode = 'FORDESP_MFG'
and		ReceivedDate >= '06/01/2013'
and		ReceivedDate <= '06/30/2013'


***/


CREATE view [dbo].[vw_BillingClaims]
as


select	cla.ID as ClaimID,
		clt.ID as ClaimTypeID,
		clt.Name as ClaimTypeName,
		cc.Name as ClaimCategoryName,
		cs.ID as ClaimStatusID,
		cs.Name as ClaimStatus,
		pro.ID as ProgramID,
		pro.Code as ProgramCode,
		pro.Name as ProgramName,
		pra.ID as ParentProgramID,
		pra.Name as ParentProgramName,
		cl.ID as ClientID,
		cl.Name as ClientName,
		mbr.ID as MemberID,
		mbrs.MembershipNumber,
		mbr.LastName,
		mbr.FirstName,
		mbr.MemberSinceDate,
		mbr.EffectiveDate,
		mbr.ExpirationDate,
		convert(date, mbr.CreateDate) as MemberCreateDate,
		mbr.CreateDate as MemberCreateDatetime,
		v.ID as VendorID,
		v.VendorNumber,
		v.Name as VendorName,
		cla.VehicleVIN as VIN,
		dbo.fnc_BillingVINModel(cla.VehicleVIN) as VINModel,
		dbo.fnc_BillingVINModelYear(cla.VehicleVIN) as VINModelYear,
		cla.VehicleYear,
		cla.VehicleMake,
		cla.VehicleModel,
		cla.CurrentMiles as VehicleCurrentMileage,
		ca.VehicleMileageUOM,
		ca.VehicleLicenseNumber,
		ca.VehicleLicenseState,
		cla.ClaimDate,
		cla.ReceivedDate,
		cla.ClaimDescription,
		cla.ContactName,
		cla.ServiceLocation,
		cla.DestinationLocation,
		cla.AmountRequested,
		cla.AmountApproved,
		crr.Name as ClaimRejectReason,
		cla.ACESReferenceNumber,
		cla.ACESSubmitDate,
		cla.ACESOutcome,
		cla.ACESClearedDate,
		cla.ACESAmount,
		cla.PaymentDate,
		cla.PaymentAmount,
		cla.CheckNumber,
		cla.CheckClearedDate,
		cla.CreateDate as ClaimCreateDate,
		po.ID as PurchaseOrderID,
		po.PurchaseOrderNumber,
		po.PurchaseOrderAmount,
		cla.PassThruAccountingInvoiceBatchID,
		cla.FeeAccountingInvoiceBatchID,
		(select ID from dbo.Entity with (nolock) where Name = 'Claim') as EntityID,
		cla.ID as EntityKey
from	dbo.Claim cla
left outer join dbo.ClaimType clt with (nolock) on clt.ID = cla.ClaimTypeID
left outer join dbo.ClaimCategory cc with (nolock) on cc.ID = cla.ClaimCategoryID
left outer join dbo.ClaimStatus cs with (nolock) on cs.ID = cla.ClaimStatusID
left outer join dbo.ClaimRejectReason crr with (nolock) on crr.ID = cla.ClaimRejectReasonID
left outer join dbo.Member mbr with (nolock) on mbr.ID = cla.MemberID
left outer join dbo.Membership mbrs with (nolock) on mbrs.ID = mbr.MembershipID
left outer join dbo.Program pro with (nolock) on pro.ID = cla.ProgramID
left outer join dbo.Program pra with (nolock) on pra.ID = pro.ParentProgramID
left outer join dbo.Client cl with (nolock) on cl.ID = pro.ClientID
left outer join dbo.Vendor v with (nolock) on v.ID = cla.VendorID
left outer join dbo.PurchaseOrder po with (nolock) on po.ID = cla.PurchaseOrderID
left outer join dbo.ServiceRequest sr with (nolock) on sr.ID = po.ServiceRequestID
left outer join dbo.[Case] ca with (nolock) on ca.ID = sr.CaseID



GO





