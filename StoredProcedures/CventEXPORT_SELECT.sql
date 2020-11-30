
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CventEXPORT_SELECT]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CventEXPORT_SELECT]
GO

-- dbo.CventEXPORT_SELECT 'NMC', '01/01/2016','03/09/2016'

-- dbo.CventEXPORT_SELECT 'CNET', '03/22/2016','03/22/2016'

-- dbo.CventEXPORT_SELECT 'FORD', '03/22/2016','03/22/2016'

-- dbo.CventEXPORT_SELECT 'NMC', '03/22/2016','03/22/2016'

--********************************************************************************************

-- dbo.CventEXPORT_SELECT 'PINNACLE', '03/22/2016','03/22/2016'

--dbo.CventEXPORT_SELECT 'NMC', '09/01/2013','09/01/2013'

--dbo.CventEXPORT_SELECT 'CNET', '09/01/2013','09/01/2013'

--dbo.CventEXPORT_SELECT 'FORD', '09/01/2013','09/01/2013'

--********************************************************************************************

CREATE procedure [dbo].[CventEXPORT_SELECT] (     
    @pOrgId varchar(10),
    @pBeginDate as date,
    @pEndDate as date
	)
AS
BEGIN

/***  Debug ***/
--DECLARE
--      @pOrgId varchar(10) = 'CNET',
--      @pBeginDate as date = '3/23/2016',
--      @pEndDate as date = '3/24/2016'
--if object_id('tempdb..#Results', 'U') is not null drop table #Results
--if object_id('tempdb..#Rank', 'U') is not null drop table #Rank


declare @Enddate date
declare @OrgId varchar(10)

set @Enddate = DATEADD(dd,1,@pEndDate)
set @OrgId = @pOrgId

if @OrgId in ('CNET','NMC','PINNACLE')
BEGIN
	Select 
		isnull(c.ContactLastName,'') as ContactLastName
		,isnull(c.ContactFirstName,'') as ContactFirstName
		,substring(isnull(hpe.PhoneNumber,''),3,10) as PhoneNumber
		,isnull(m.FirstName,'') as FirstName
		,isnull(m.LastName,'') as LastName
		,isnull(ae.Line1,'') as AddressLine1
		,isnull(ae.Line2,'') as AddressLine2
		,isnull(ae.City,'') as City
		,isnull(ae.StateProvince,'') as StateProvince
		,isnull(ae.PostalCode,'') as PostalCode
		,ltrim(rtrim(isnull(c.VehicleVIN,''))) as VehicleVIN
		,isnull(c.VehicleYear,'') as VehicleYear
		,isnull(c.VehicleModel,'') as VehicleModel
		,isnull(c.VehicleMake,'') as VehicleMake
		,'' as ManufactureCode
		,ServiceCode.LegacyCode as ServiceCode
		,ServiceCode.[PO Description1] as ServiceCodeDescription
		,convert(varchar,sr.CreateDate,101) as ContactDate
		,Convert(varchar(8),sr.CreateDate,114) as ContactTime
		,convert(varchar,po.CreateDate,101) as DispatchDate
		,convert(varchar(8),po.CreateDate,114) as DispatchTime
		,isnull(v.VendorNumber,'') as OnSiteServiceProvider
		,isnull(vlae.StateProvince,'') as VendorStateProvince
		,Right(replicate('0',2)+ rtrim(ltrim(str(datepart(hh,po.ETADATE)))),2) + Right(replicate('0',2)+ rtrim(ltrim(str(datepart(MI,po.ETADATE)))),2) as ETA
		,isnull(po.PurchaseOrderNumber,'') as PurchaseOrderNumber
		,(Case When isnull(sr.IsAccident,'') != '' Then sr.IsAccident Else 2 End) as IsAccident
		,isnull(sr.PartsAndAccessoryCode,'') as RepairDealerID
		,coalesce(po.CreateBy, sr.createby) Agent
		,Right(replicate('0',10)+ convert(varchar,substring(isnull(hpe.PhoneNumber,''),3,10),10),10) as HomePhone
		,Right(replicate('0',10)+ convert(varchar,substring(isnull(c.ContactPhoneNumber,''),3,10),10),10) as CallBackNumber
		,Right(replicate('0',10)+ convert(varchar,substring(isnull(c.ContactAltPhoneNumber,''),3,10),10),10) as AltCallBackNumber
		,Right(replicate('0',10)+ convert(varchar,substring(isnull(cpe.PhoneNumber,''),3,10),10),10) as CellPhone
		,isnull(rtrim(ltrim(c.ContactEmail)),'') as ContactEmailAddress
		,Case When srpc.Name = 'Tech' OR sr.IsWorkedByTech = 1 Then 1 Else 0 End IsTechAssistance
		,m.ClientMemberKey
		,coalesce (ms.membershipnumber,ms.ClientReferenceNumber) MembershipNumber
		,ms.id ODISMbrshpID
		,sr.id ServiceRequestID
		,case   when isnull(po.PurchaseOrderNumber,0) = 0 then 'SR-' + ltrim(rtrim(STR(sr.ID)))
					else 'PO-' + ltrim(rtrim(STR(po.PurchaseOrderNumber))) end ReferenceNumber
		,case   when isnull(po.PurchaseOrderNumber,0) = 0 then sr.CreateDate
					else po.CreateDate end ReferenceDate
		,case when ServiceCode.LegacyCode in ('1','2','4','5','7','9','16','56','5D') then 1
					when srpc.Name = 'Tech' OR sr.IsWorkedByTech = 1 then 2
					else 3 end SelectionRank
		,po.id PuchaseOrderID
		,p.ID  ProgramID
		,p.[Description]
		
	into #Results
	From dbo.[Case] c
	Join dbo.ServiceRequest sr with (nolock) on c.id = sr.caseid
	Join dbo.Program p with (nolock) on p.ID = c.ProgramID
	Join dbo.ProgramConfiguration prgcfg on prgcfg.ProgramID = p.ID and prgcfg.Name = 'SurveyGroup' and prgcfg.Value = @OrgId
	left outer join dbo.ProductCategory srpc with (nolock) on srpc.ID = sr.ProductCategoryID  
	left outer join dbo.PurchaseOrder po with (nolock)on po.ServiceRequestID = sr.ID and po.isactive = 1 
	left outer join dbo.PurchaseOrderStatus pos (nolock) on pos.ID = po.PurchaseOrderStatusID
	left outer join dms_reporting.Report.ServiceRequestLegacyCodes ServiceCode with (nolock) on ServiceCode.ServiceRequestID = sr.ID And ISNULL(ServiceCode.ID,0) = ISNULL(po.id,0)
	Left outer Join dbo.VendorLocation vl with (nolock) on po.VendorLocationID = vl.ID and vl.isactive = 1
	Left outer Join dbo.Vendor v with (nolock) on vl.VendorID = v.ID and v.isactive = 1                                                                                                             
	left outer join dbo.Member m with (nolock) on c.MemberID = m.ID
	left outer join dbo.Membership ms with (nolock)on m.MembershipID = ms.ID
	Left outer Join dbo.PhoneEntity cpe with (nolock) on cpe.PhoneTypeID = 3 And cpe.EntityID = 5 And cpe.RecordID = c.MemberID
	Left outer Join dbo.PhoneEntity hpe with (nolock) on hpe.PhoneTypeID = 1 And hpe.EntityID = 5 And hpe.RecordID = c.MemberID
	Left outer Join dbo.AddressEntity ae with (nolock) on ae.AddressTypeID = 1 And ae.EntityID = 5 And ae.RecordID = c.MemberID
	Left outer Join dbo.AddressEntity vlae with (nolock) on vlae.AddressTypeID = 2 And vlae.EntityID = 18 And vl.ID = vlae.RecordID
	                  
	where  COALESCE(po.CreateDate,sr.CreateDate) >= @pBeginDate 
		and COALESCE(po.CreateDate,sr.CreateDate) < DATEADD(day,1,@pEndDate) 
		and ISNULL(po.IsGOA,0) <> 1
		and pos.Name = 'Issued'
		and srpc.Name <> 'Info' --Don't send INFO call records. --Per Stacey 06/17/2014
		and c.ReasonID IS NULL
		and c.ContactEmail IS NOT NULL

	----create a ranking order that will list the last service group by dispatch, then Tech, then information type calls without Tech
	            
	select      c.membershipnumber
			  ,c.ODISMbrshpID
			  ,c.SelectionRank
			  ,c.ReferenceDate
			  ,ROW_NUMBER() over( Partition by c.ODISMbrshpID order by c.MembershipNumber,c.ODISMbrshpID, c.SelectionRank,c.ReferenceDate desc) SelectionOrder
			  ,c.ServiceRequestID
			  ,c.PuchaseOrderID
	into #Rank
	from #Results c
	order by c.MembershipNumber,c.ODISMbrshpID, c.SelectionRank,c.ReferenceDate desc

End

--Select * From #Rank
--Select * From #Results
	
---Limit results by the ranking ordera and get the e-mail and mail flags from the person table in MTS


if @OrgId = 'CNET' 
Begin

	Select     top 40 percent
		c.ContactLastName
		,c.ContactFirstName
		,c.PhoneNumber
		,c.FirstName
		,c.LastName
		,c.AddressLine1
		,c.AddressLine2
		,c.City
		,c.StateProvince
		,c.PostalCode
		,c.VehicleVIN
		,c.VehicleYear
		,c.VehicleModel
		,c.VehicleMake
		,c.ServiceCode
		,c.ServiceCodeDescription
		,c.IsTechAssistance as IsTechFlag
		,c.ContactDate
		,c.ContactTime
		,c.DispatchDate
		,c.DispatchTime
		,c.OnSiteServiceProvider
		,c.VendorStateProvince
		,c.ETA
		,c.ReferenceNumber as PurchaseOrderNumber
		,c.RepairDealerID
		,c.Agent
		,c.CallBackNumber
		,c.AltCallBackNumber
		,c.CellPhone
		,c.ContactEmailAddress
		,c.MembershipNumber as MemberNumber
		--,per.MailExclude
		--,per.emailexclude
		,0 as MailExclude
		,0 as EmailExclude
	from #Results c
	join #Rank cr on cr.SelectionOrder = 1 
		and cr.ServiceRequestID = c.ServiceRequestID 
		and isnull(cr.PuchaseOrderID,0) = isnull(c.PuchaseOrderID,0)    
	--left JOIN DatamartServer.[Batch_Processing_ETL].[DMS].[MAP_ClientMemberKey] cmk with (nolock) on cmk.ClientMemberKey = c.ClientMemberKey
	--left join MTSServer.aptify.dbo.person per with (nolock) on cmk.MemberNumber = per.NMCMemberNumber
	--where ISNULL (per.emailexclude,0) =0 ---Keep only records we can email.  Stacey requested we include members that we can't join to properly.
	order by right(convert(varchar,c.ServiceRequestID),1)

end

if @OrgId = 'NMC'
begin 
	Select     
		c.ContactLastName
		,c.ContactFirstName
		,c.PhoneNumber
		,c.FirstName
		,c.LastName
		,c.AddressLine1
		,c.AddressLine2
		,c.City
		,c.StateProvince
		,c.PostalCode
		,c.VehicleVIN
		,c.VehicleYear
		,c.VehicleModel
		,c.VehicleMake
		,c.ServiceCode
		,c.ServiceCodeDescription
		,c.IsTechAssistance as IsTechFlag
		,c.ContactDate
		,c.ContactTime
		,c.DispatchDate
		,c.DispatchTime
		,c.OnSiteServiceProvider
		,c.VendorStateProvince
		,c.ETA
		,c.ReferenceNumber as PurchaseOrderNumber
		,c.RepairDealerID
		,c.Agent
		,c.CallBackNumber
		,c.AltCallBackNumber
		,c.CellPhone
		,c.ContactEmailAddress
		,c.MembershipNumber as MemberNumber
		--,per.MailExclude
		--,per.emailexclude
		,0 as MailExclude
		,0 as EmailExclude
	from #Results c
	join #Rank cr on cr.SelectionOrder = 1 
		and cr.ServiceRequestID = c.ServiceRequestID 
		and isnull(cr.PuchaseOrderID,0) = isnull(c.PuchaseOrderID,0)    
	--left JOIN DatamartServer.[Batch_Processing_ETL].[DMS].[MAP_ClientMemberKey] cmk with (nolock) on cmk.ClientMemberKey = c.ClientMemberKey
	--left join MTSServer.aptify.dbo.person per with (nolock) on cmk.MemberNumber = per.NMCMemberNumber
	--where ISNULL (per.emailexclude,0) =0 ---Keep only records we can email.  Stacey requested we include members that we can't join to properly.
end
      
if @OrgId = 'PINNACLE'
begin 
	Select     
		c.ContactLastName
		,c.ContactFirstName
		,c.PhoneNumber
		,c.FirstName
		,c.LastName
		,c.AddressLine1
		,c.AddressLine2
		,c.City
		,c.StateProvince
		,c.PostalCode
		,c.VehicleVIN
		,c.VehicleYear
		,c.VehicleModel
		,c.VehicleMake
		,c.ServiceCode
		,c.ServiceCodeDescription
		,c.IsTechAssistance as IsTechFlag
		,c.ContactDate
		,c.ContactTime
		,c.DispatchDate
		,c.DispatchTime
		,c.OnSiteServiceProvider
		,c.VendorStateProvince
		,c.ETA
		,c.ReferenceNumber as PurchaseOrderNumber
		,c.RepairDealerID
		,c.Agent
		,c.CallBackNumber
		,c.AltCallBackNumber
		,c.CellPhone
		,c.ContactEmailAddress
		,c.MembershipNumber as MemberNumber
		,0 as MailExclude
		,0 as emailexclude
		,c.[Description] as ServiceRequestOrg
				
	from #Results c
	join #Rank cr on cr.SelectionOrder = 1 
		and cr.ServiceRequestID = c.ServiceRequestID 
		and isnull(cr.PuchaseOrderID,0) = isnull(c.PuchaseOrderID,0)
end

if @OrgId = 'FORD'
BEGIN
    Select distinct
          
		isnull(c.ContactLastName,'') as ContactLastName
		,isnull(c.ContactFirstName,'') as ContactFirstName
		,substring(isnull(hpe.PhoneNumber,''),3,10) as PhoneNumber
		,isnull(m.FirstName,'') as FirstName
		,isnull(m.LastName,'') as LastName
		,isnull(ae.Line1,'') as AddressLine1
		,isnull(ae.Line2,'') as AddressLine2
		,isnull(ae.City,'') as City
		,isnull(ae.StateProvince,'') as StateProvince
		,isnull(ae.PostalCode,'') as PostalCode
		,ltrim(rtrim(isnull(c.VehicleVIN,''))) as VehicleVIN
		,isnull(c.VehicleYear,'') as VehicleYear
		,isnull(c.VehicleModel,'') as VehicleModel
		,isnull(c.VehicleMake,'') as VehicleMake
		,ServiceCode.LegacyCode as ServiceCode
		,ServiceCode.[PO Description1] as ServiceCodeDescription
		,case when srpc.Name = 'Tech' OR sr.IsWorkedByTech = 1 then 'Y' else 'N' end IsTechFlag
		,convert(varchar,sr.CreateDate,101) as ContactDate
		,Convert(varchar(8),sr.CreateDate,114) as ContactTime
		,convert(varchar,po.CreateDate,101) as DispatchDate
		,convert(varchar(8),po.CreateDate,114) as DispatchTime
		,isnull(v.VendorNumber,'') as OnsiteServiceProvider
		,isnull(vlae.StateProvince,'') as VendorStateProvince
		,Right(replicate('0',2)+ rtrim(ltrim(str(datepart(hh,po.ETADATE)))),2) + Right(replicate('0',2)+ rtrim(ltrim(str(datepart(MI,po.ETADATE)))),2) as ETA
		,case   when isnull(po.PurchaseOrderNumber,0) = 0 then 'SR-' + ltrim(rtrim(STR(sr.ID)))
                            else 'PO-' + ltrim(rtrim(STR(po.PurchaseOrderNumber))) end PurchaseOrderNumber
		--,isnull(po.PurchaseOrderNumber,'') as PurchaseOrderNumber
		,isnull(rvl.PartsAndAccessoryCode,'') as RepairDealerID
		,po.CreateBy as Agent
		,Right(replicate('0',10)+ convert(varchar,substring(isnull(c.ContactPhoneNumber,''),3,10),10),10) as CallBackNumber
		,Right(replicate('0',10)+ convert(varchar,substring(isnull(c.ContactAltPhoneNumber,''),3,10),10),10) as AltCallBackNumber
		,Right(replicate('0',10)+ convert(varchar,substring(isnull(cpe.PhoneNumber,''),3,10),10),10) as CellPhone
		,isnull(rtrim(ltrim(c.ContactEmail)),'') as ContactEmailAddress
		,isnull(rtrim(ltrim(c.MemberNumber)),'') as MemberNumber
		,0 as MailExclude
		,0 as EmailExclude
		
	into #ford	
	From dbo.[Case] c
	Join dbo.ServiceRequest sr with (nolock) on c.id = sr.caseid
	Join dbo.Program p with (nolock) on p.ID = c.ProgramID
	Join dbo.ProgramConfiguration prgcfg on prgcfg.ProgramID = p.ID and prgcfg.Name = 'SurveyGroup' and prgcfg.Value = @OrgId
	left outer join dbo.ProductCategory srpc with (nolock) on srpc.ID = sr.ProductCategoryID  
	Left Join dbo.VendorLocation rvl with (nolock) on sr.DestinationVendorLocationID = rvl.id
	Left Join dbo.ServiceRequestStatus srs with(nolock) on sr.ServiceRequestStatusID = srs.ID 
	Left Join dbo.PurchaseOrder po with(nolock) on sr.ID = po.ServiceRequestID And po.IsActive = 1
	left join dbo.PurchaseOrderStatus pos (nolock) on pos.ID = po.PurchaseOrderStatusID
	left join dms_reporting.Report.ServiceRequestLegacyCodes ServiceCode with (nolock) on ServiceCode.ServiceRequestID = sr.ID And ISNULL(ServiceCode.ID,0) = ISNULL(po.id,0)
	Left Join dbo.VendorLocation vl with (nolock) on po.VendorLocationID = vl.ID
	Left Join dbo.Vendor v with (nolock) on vl.VendorID = v.ID
	Left Join dbo.vw_ServiceCode sc with (nolock) on sc.ServiceRequestID = sr.ID And ISNULL(sc.PurchaseOrderID,0) = ISNULL(po.id,0)
	Left Join dbo.Member m with (nolock) on c.MemberID = m.ID
	Left Join dbo.PhoneEntity cpe with (nolock) on cpe.PhoneTypeID = 3 And cpe.EntityID = 5 And cpe.RecordID = c.MemberID
	Left Join dbo.PhoneEntity hpe with (nolock) on hpe.PhoneTypeID = 1 And hpe.EntityID = 5 And hpe.RecordID = c.MemberID
	Left Join dbo.AddressEntity ae with (nolock) on ae.AddressTypeID = 1 And ae.EntityID = 5 And ae.RecordID = c.MemberID
	Left Join dbo.AddressEntity vlae with (nolock) on vlae.AddressTypeID = 2 And vlae.EntityID = 18 And vl.ID = vlae.RecordID
	Left Join
		(Select cll.recordid ServiceRequestID
		   ,ca.description
			  From dbo.ContactLogLink cll with (nolock) 
			  Left Join dbo.contactlog cl with (nolock) on cll.ContactLogID = cl.ID
			  Left Join dbo.ContactLogAction cla with (nolock)on cl.ID = cla.ContactLogID  
			  Left Join dbo.ContactAction ca with (nolock) on ca.ID = cla.ContactActionID 
			  Where cll.EntityID in (13,14) And cla.ContactActionID = 99
			  And cll.ID = (Select MAX(cll2.ID) From dbo.ContactLogLink cll2 with (nolock) 
														Left Join dbo.contactlog cl2 with (nolock) on cll2.ContactLogID = cl2.ID
														Left Join dbo.ContactLogAction cla2 with (nolock)on cl2.ID = cla2.ContactLogID
														Where cll2.EntityID in (13,14) And cll2.RecordID = cll.recordid And cla2.ContactActionID = 99 )
		) b on b.ServiceRequestID=sr.id
	where  COALESCE(po.CreateDate,sr.CreateDate) >= @pBeginDate 
	and COALESCE(po.CreateDate,sr.CreateDate) < DATEADD(day,1,@pEndDate) 
	and ISNULL(po.IsGOA,0) <> 1
	and pos.Name = 'Issued'
	And po.id is not null                                    ---Only Pull Valid events with a PO created 
															   ---need to verify how rebursements will be docuemnted
	--And (sc.ServiceCode like '%tow%' or sc.ServiceCode like '%lock%' or sc.ServiceCode like '%mech%'  
	--	or sc.ServiceCode like '%jump%' or sc.ServiceCode like '%Tire%' or sc.ServiceCode like '%Fluid%'
	--	or sc.ServiceCode like '%Winch%' )
	and c.ReasonID IS NULL
	and c.ContactEmail IS NOT NULL
	                              
	  
	select * from #ford f
	where PurchaseOrderNumber = 
		(select substring(max(case when PurchaseOrderNumber like '%po%' then '1' else '0' end + PurchaseOrderNumber),2,50) 
		 from #ford fs 
		 where f.VehicleVIN = fs.VehicleVIN 
		 and f.ContactDate = fs.ContactDate)
END               

END
GO

