

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
		cc.BillingCode,
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