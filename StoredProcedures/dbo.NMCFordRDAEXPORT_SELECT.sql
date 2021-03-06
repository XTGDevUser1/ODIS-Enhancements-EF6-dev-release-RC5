/****** Object:  StoredProcedure [dbo].[NMCFordRDAEXPORT_SELECT]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[NMCFordRDAEXPORT_SELECT]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[NMCFordRDAEXPORT_SELECT] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--dbo.NMCFordRDAEXPORT_SELECT '09/1/13','09/9/13'
--dbo.NMCFordRDAEXPORT_SELECT '10/15/2013'

CREATE procedure [dbo].[NMCFordRDAEXPORT_SELECT]
(	
	@pBeginDate as date,
	@pEndDate as date
)
AS

--******************************************************************************************
--******************************************************************************************
--1/8/14 Removed blank spaces from around the VIN  Clay McNurlin
--		
--******************************************************************************************
--******************************************************************************************

declare @Enddate date
set @Enddate = DATEADD(dd,1,@pEndDate)

					
select 

		c.ContactLastName
		,c.ContactFirstName
		,substring(hpe.PhoneNumber,3,10) HomePhone
		,m.FirstName
		,m.LastName
		,ae.Line1
		,ae.Line2
		,ae.City
		,ae.StateProvince
		,ae.PostalCode
		,ltrim(rtrim(c.VehicleVIN)) VehicleVIN
		,c.VehicleYear
		,c.VehicleModel
		,c.VehicleMake
		,'' ManfactureCode
		,(Case	when sc.ServiceCode like '%tow%' then '56'
				when sc.ServiceCode like '%lock%' then '4'
				when sc.ServiceCode like '%mech%' then '7'
				when sc.ServiceCode like '%jump%' then '2'
				when sc.ServiceCode like '%Tire%' then '5'
				when sc.ServiceCode like '%Fluid%' then '1'
				when sc.ServiceCode like '%Winch%' then '9'
				end) ServiceCode
		,convert(varchar,sr.CreateDate,101) ContactDate
		,Convert(varchar(8),sr.CreateDate,114) ContactTime
		,convert(varchar,po.CreateDate,101)DispatchDate
		,convert(varchar(8),po.CreateDate,114) DispatchTime
		,v.VendorNumber POVEND
		,'' VendorName
		,'' VnAddLn1
		,'' VnAddLn2
		,'' vncity
		,vlae.StateProvince as VnStateProvince
		,'' vnzip
		,''	vnregn
		,''	blank1
		,right(replicate('0',2)+ rtrim(ltrim(str(datepart(hh,po.ETADATE)))),2) + right(replicate('0',2)+ rtrim(ltrim(str(datepart(MI,po.ETADATE)))),2) ETA_MIN
		,'' blank2
		,right(replicate('0',15)+ isnull(po.PurchaseOrderNumber,''),15) PurchaseOrderNumber
		,'' blank3
		,'' fromloc
		,(Case when isnull(sr.IsAccident,'') != '' then sr.IsAccident else 2 end) IsAccident
		,'' blank4
		,right(replicate('0',5)+ isnull(rvl.PartsAndAccessoryCode,''),5) PartsAndAccessoryCode
		,'' TowtoDLR2
		,'' Tows
		,'' Calls
		,'' locst
		,'' loczip
		,po.CreateBy
		,(case	when isnull(b.Description,'') = '' then '' else 'Y' end) POGLFLAG
		,right(replicate('0',10)+ convert(varchar,substring(isnull(hpe.PhoneNumber,''),3,10),10),10) HomePhone
		,right(replicate('0',10)+ convert(varchar,substring(isnull(c.ContactPhoneNumber,''),3,10),10),10) CallBackNumber
		,right(replicate('0',10)+ convert(varchar,substring(isnull(c.ContactAltPhoneNumber,''),3,10),10),10) AltCallBackNumber
		,right(replicate('0',10)+ convert(varchar,substring(isnull(cpe.PhoneNumber,''),3,10),10),10) CellPhone
		
from DMS.dbo.ServiceRequest sr with(nolock)
	left join dms.dbo.VendorLocation rvl with (nolock) on sr.DestinationVendorLocationID = rvl.id
	left join DMS.dbo.ServiceRequestStatus srs with(nolock) on sr.ServiceRequestStatusID = srs.ID 
	left join DMS.dbo.[Case] c with(nolock) on sr.CaseID = c.ID 
	left join DMS.dbo.Program pgm1 with(nolock) on c.ProgramID = pgm1.ID 
	left join DMS.dbo.PurchaseOrder po with(nolock) on sr.ID = po.ServiceRequestID and po.IsActive = 1
	left join dms.dbo.VendorLocation vl with (nolock) on po.VendorLocationID = vl.ID
	left join dms.dbo.Vendor v with (nolock) on vl.VendorID = v.ID
	left join DMS.dbo.Program pgm2 with(nolock) on pgm1.ParentProgramID = pgm2.ID 
	left join DMS.dbo.Program pgm3 with(nolock) on pgm2.ParentProgramID = pgm3.ID 
	left join dms.dbo.vw_ServiceCode sc with (nolock) on sc.ServiceRequestID = sr.ID and ISNULL(sc.PurchaseOrderID,0) = ISNULL(po.id,0)
	left join dms.dbo.Member m with (nolock) on c.MemberID = m.ID
	left join dms.dbo.PhoneEntity cpe with (nolock) on cpe.PhoneTypeID = 3 and cpe.EntityID = 5 and cpe.RecordID = c.MemberID
	left join dms.dbo.PhoneEntity hpe with (nolock) on hpe.PhoneTypeID = 1 and hpe.EntityID = 5 and hpe.RecordID = c.MemberID
	left join dms.dbo.AddressEntity ae with (nolock) on ae.AddressTypeID = 1 and ae.EntityID = 5 and ae.RecordID = c.MemberID
	left join dms.dbo.AddressEntity vlae with (nolock) on vlae.AddressTypeID = 2 and vlae.EntityID = 18 and vl.ID = vlae.RecordID
	left join
	(Select cll.recordid ServiceRequestID
		   ,ca.description
			from rogue.dms.dbo.ContactLogLink cll with (nolock) 
			left join rogue.dms.dbo.contactlog cl with (nolock) on cll.ContactLogID = cl.ID
			left join dms.dbo.ContactLogAction cla with (nolock)on cl.ID = cla.ContactLogID  
			left join dms.dbo.ContactAction ca with (nolock) on ca.ID = cla.ContactActionID 
			where cll.EntityID in (13,14) and cla.ContactActionID = 99
			 and cll.ID = (select MAX(cll2.ID) from rogue.dms.dbo.ContactLogLink cll2 with (nolock) 
										left join rogue.dms.dbo.contactlog cl2 with (nolock) on cll2.ContactLogID = cl2.ID
										left join dms.dbo.ContactLogAction cla2 with (nolock)on cl2.ID = cla2.ContactLogID
										where cll2.EntityID in (13,14) and cll2.RecordID = cll.recordid and cla2.ContactActionID = 99 )
			) b on b.ServiceRequestID=sr.id
	where	isnull(pgm3.id, isnull(pgm2.id, pgm1.id)) = 86								---Parent = Ford
			and pgm1.ID <> 343															---Dosne't include FORD Direct Tow
			and po.CreateDate between @pBeginDate and @Enddate --'10/1/13' and '10/9/13'
			and	po.id is not null														---Only Pull Valid events with a PO created 
																						---need to verify how rebursements will be docuemnted
			and (sc.ServiceCode like '%tow%' or sc.ServiceCode like '%lock%' or sc.ServiceCode like '%mech%'  	
				or sc.ServiceCode like '%jump%' or sc.ServiceCode like '%Tire%' or sc.ServiceCode like '%Fluid%'
				or sc.ServiceCode like '%Winch%' )
GO
