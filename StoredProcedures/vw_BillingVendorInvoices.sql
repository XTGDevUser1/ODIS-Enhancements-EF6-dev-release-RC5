/****** Object:  View [dbo].[vw_BillingVendorInvoices]    Script Date: 01/12/2017 03:36:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[vw_BillingVendorInvoices]  
as  
  
-- CHANGE LOG:  
--  
-- ^1 01/21/2014 - MJK - Added join to PaymentCatgory  
-- ^2 01/21/2014 - MJK - Added New field for PaymentDateWith1MonthDelay  
-- ^3 02/02/2014 - MJK - Added IsDeliveryDriver  
--   
 select vi.ID as VendorInvoiceID,  
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
--   vi.CheckNumber,  
   vi.CheckClearedDate,  
   vi.ActualETAMinutes,  
   vi.Last8OfVIN,  
   vi.VehicleMileage,  
   vi.AccountingInvoiceBatchID,  
   vi.IsActive,  
   vi.CreateDate as VendorInvoiceCreateDate,  
   vi.CreateBy as VendorInvoiceCreatedBy,  
     
   (select ID from dbo.Entity with (nolock) where Name = 'VendorInvoice') as EntityID,  
   vi.ID as  EntityKey,  
     
   pc.ID as PaymentCategoryID,  
   isnull(pc.Name, '~') as PaymentCategoryName,  
   dateadd(mm, 1, convert(date, vi.PaymentDate)) as PaymentDateWith1MonthDelay, -- ^2  
   vpo.IsDeliveryDriver,  
   vpo.AccountingInvoiceBatchID_PurchaseOrder
  
from dbo.VendorInvoice vi with (nolock)  
left outer join dbo.VendorInvoiceException vie with (nolock) on vie.VendorInvoiceID = vi.ID  
left outer join dbo.VendorInvoiceStatus vis with (nolock) on vis.ID = vi.VendorInvoiceStatusID  
left outer join dbo.Vendor ven with (nolock) on ven.ID = vi.VendorID  
left outer join dbo.PaymentType pt with (nolock) on pt.ID = vi.PaymentTypeID  
left outer join dbo.PaymentCategory pc with (nolock) on pc.ID = pt.PaymentCategoryID -- ^1  
  
left outer join vw_BillingServiceRequestsPurchaseOrders vpo on vpo.PurchaseOrderID = vi.PurchaseOrderID  
Where vi.IsActive = 1
and vi.ReceivedDate > DATEADD(mm, -9, GETDATE())
GO