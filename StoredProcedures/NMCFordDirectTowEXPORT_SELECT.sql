IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NMCFordDirectTowEXPORT_SELECT]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[NMCFordDirectTowEXPORT_SELECT]
GO

--dbo.NMCFordDirectTowEXPORT_SELECT '11/01/2013'

CREATE procedure [dbo].[NMCFordDirectTowEXPORT_SELECT]
(	
	@pProcessDate as date
)
AS

--******************************************************************************************
--******************************************************************************************
--
--	1/8/14 Removed the blanks spaces from around the VIN Clay McNurlin	
--******************************************************************************************
--******************************************************************************************


select 
            convert(varchar(10),dateadd(day,-1,convert(date,str(DATEPART(month,getdate()))+'/1/'+str(DATEPART(Year,getdate()))))) as MonthEndDate
            ,po.PurchaseOrderNumber as PONumber
            ,UPPER(ltrim(rtrim(c.VehicleVIN))) as VIN
            ,c.VehicleCurrentMileage as VehicleMileage
            ,c.VehicleYear as VehicleYear
            ,c.VehicleMake as VehicleMake
            ,Upper(SUBSTRING(ltrim(rtrim(c.VehicleVIN)),5,3)) as VehicleModel
            ,mb.LastName as OwnLastName
            ,ae.PostalCode as OwnerPostalCode
            ,vl.PartsAndAccessoryCode as PACode
            ,v.Name as DealerName
            ,sr.DestinationCity as DealerCity
            ,sr.DestinationStateProvince as DealerState
            ,'0030.00' as ServiceFee
            ,convert(varchar(10),isnull(po.ETADate,po.CreateDate),101) as ETADate
            ,pgm1.code as Assoc
            ,vl.DealerNumber as DealerID
            ,slc.LegacyCode as POCode
            
     
from DMS.dbo.ServiceRequest sr with(nolock)
      left join DMS.dbo.ServiceRequestStatus srs with(nolock) on sr.ServiceRequestStatusID = srs.ID 
      left join DMS.dbo.[Case] c with(nolock) on sr.CaseID = c.ID 
      left join DMS.dbo.Program pgm1 with(nolock) on c.ProgramID = pgm1.ID 
      left join DMS.dbo.PurchaseOrder po with(nolock) on sr.ID = po.ServiceRequestID and po.IsActive = 1
      left join DMS.dbo.PurchaseOrderStatus pos with(nolock) on po.PurchaseOrderStatusID = pos.ID 
      left join DMS.dbo.PurchaseOrderCancellationReason  cnr  with (nolock)on po.CancellationReasonID = cnr.id
      left join dms.dbo.PurchaseOrderGOAReason gor with (nolock) on gor.id= po.GOAReasonID
      left join dms.dbo.VendorLocation vl with (nolock) on sr.DestinationVendorLocationID = vl.ID
      left join dms.dbo.Vendor v with (nolock) on vl.VendorID = v.ID
      left join dms.dbo.Member mb with (nolock) on c.MemberID = mb.ID
      left join dms.dbo.AddressEntity ae with (nolock) on mb.id = ae.recordid and ae.EntityID = 5
      left join DMS.dbo.Membership ms with (nolock)on mb.MembershipID = ms.ID
      left join DMS_Reporting.Report.ServiceRequestLegacyCodes slc with (nolock) on slc.ID = po.ID 

	join 
			(
			
			Select	bid.EntityKey POID---- This is the POID
			from	DMS.dbo.BillingInvoiceDetail bid with (nolock)
			join	DMS.dbo.BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID
			join	DMS.dbo.BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID


			where	bid.BillingDefinitionInvoiceID = 39 --Direct Tow only
					and bid.IsExcluded = 0 --Remove excluded events
					and bi.InvoiceStatusID = 3 -- Billing has been posted
					and bi.ScheduleDate  = @pProcessDate --insert first day of following month
			) a on a.POID = po.ID
	

	where	 vl.PartsAndAccessoryCode is not null
			and slc.LegacyCode in ('56', '256')
GO

