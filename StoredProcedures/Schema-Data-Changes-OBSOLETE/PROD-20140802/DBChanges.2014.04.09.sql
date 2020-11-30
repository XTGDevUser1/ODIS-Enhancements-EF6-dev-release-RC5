ALTER TABLE Claim ADD ACESFeeAmount MONEY NULL
GO

ALTER view [dbo].[vw_BillingServiceRequestsPurchaseOrders]
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
		left outer join dbo.BillTo bt with (nolock) on bt.ID = po.DispatchFeeBillToID
		
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
