USE [DMS]
GO

/****** Object:  StoredProcedure [report].[PDGServiceEventDetail]    Script Date: 04/26/2016 07:05:05 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[report].[PDGServiceEventDetail]') AND type in (N'P', N'PC'))
DROP PROCEDURE [report].[PDGServiceEventDetail]
GO

USE [DMS]
GO

/****** Object:  StoredProcedure [report].[PDGServiceEventDetail]    Script Date: 04/26/2016 07:05:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- ==================================================================
-- Author:		Clay McNurlin
-- Create date: 8/14/2013
-- Description:	Generic Service Event Data
-- ==================================================================


-- exec [dbo].[ODISServiceReport] '03/17/2015',null, null,-1,null,0
-- exec [dbo].[ODISServiceReport_Test2] '04/18/2016',null, null,86,null,0 --510 8:02
-- exec [dbo].[ODISServiceReport] '06/28/2015',null, null,-1,null,1 

-- exec [dbo].[ODISServiceReport] '06/28/2015',null, null,-1,null,0
-- exec [dbo].[ODISServiceReport_Test] '06/28/2015',null, null,-1,null,0

CREATE PROCEDURE [report].[PDGServiceEventDetail]
	@pDate date = NULL,
	@pFromDate date = NULL,
	@pToDate date = NULL,
	@pParent varchar(max) = NULL,
	@pProgramID varchar(max) = NULL,
	@pShowComments int = 0
AS

/*
Drop Table #Results
Drop Table #ContactLogHistory
*/

--Declare  
--@pDate date = '10/16/15',
--@pFromDate date = '9/1/15',
--@pToDate date = '9/8/15',
--@pParent varchar(max) = '86',
--@pProgramID varchar(max) = null,
--@pShowComments int = 0


declare @Date date,
@FromDate date,
@ToDate date,
@Parent varchar(max),
@ProgramID varchar(max),
@ShowComments int


set @Date = @pDate
set @FromDate = @pFromDate
set @ToDate = @pToDate
set @Parent = @pParent
set @ProgramID = @pProgramID
set @ShowComments = @pShowComments

declare @parents table( s varchar(10))



set @Date = @pDate
set @FromDate = @pFromDate
set @ToDate = @pToDate
set @ProgramID = @pProgramID
set @ShowComments = @pShowComments

if @FromDate is null set @FromDate = @Date
if @ToDate is null set @ToDate = @date




if @pParent =-1
begin 			 
     			

    insert into @parents
    Select distinct
				    isnull(pgm3.id, isnull(pgm2.id, pgm1.id))	[ParentProgramID]
		    From dbo.Program pgm1 with(nolock)
				left join dbo.Program pgm2 with(nolock) on pgm1.ParentProgramID = pgm2.ID  and pgm2.isactive = 1
				left join dbo.Program pgm3 with(nolock) on pgm2.ParentProgramID = pgm3.ID and pgm3.isactive = 1
				left outer join dbo.client c with(nolock) on c.id = pgm1.ClientID
		    where pgm1.isactive = 1
		    and pgm1.id in (Select ProgramID 
					--into #Programs 
				From DatamartServer.Batch_Processing_ETL.dms.MapClientProgram with(nolock)
				Where 1=1 
					And RecordSource = 'CNET'
					And isnull(CompanyCode,'') NOT IN ('RVDAC'))
end
else 
begin
    insert into @parents
    select s from dbo.fnNMCSplit(',',@Parent)
end  


select 
	sr.ID								[Service Request ID]
	,srs.Description					[Status]
	,pc.Description						[Product Category]
	,p1.Description						[Service Request Primary Product]
	,p2.Description						[Service Request Secondary Product]
	,na.Description						[Next Action]
	,vc.Description						[Vehicle Category]
	,cls.Description					[Closed Loop Status]
	,sr.PrimaryCoverageLimit					[Coverage Limit]
	,pt.Description						[Member Payment Type]
	,sr.IsRedispatched					[Is Redispatched]
	,sr.IsWorkedByTech					[Is Worked by Tech]
	,convert(date,sr.CreateDate,101)	[Created Date]
	,sr.CreateBy						[Created By]
	,u.FirstName + ' ' + u.LastName		[User Name]
	,pgm1.Description					[Program Description]
	,cpl.LocationAccuracy				[WALDO Location Accuracy]
	,po.PurchaseOrderAmount				[PO Amount]
	,po.MemberServiceAmount				[Mbr Amount]
	,po.TaxAmount						[PO Tax]
	,p3.Description						[PO Product]
	,case	when isnull(po.PurchaseOrderAmount,0) =0 and isnull (po.MemberServiceAmount,0)>0 and pos.id in (2,3) then 'Dispatched to vendor as member pay' 
			else pos.Description	end 	[PO Status]
	,po.ID                              [PO ID]
	,CASE WHEN ISNULL(po.PurchaseOrderNumber,'')='' THEN ''
		  ELSE po.PurchaseOrderNumber
     END AS             [Purchase Order Number]
        ,pgm1.ID						[Program ID]
	,isnull(pgm3.Description, isnull(pgm2.Description, pgm1.Description))	[Parent Program]
	,c.VehicleVIN						VIN
	,isnull(ms.ClientReferenceNumber,ms.[MembershipNumber])				[Membership Number]
	,mb.FirstName						[First Name]
	,mb.LastName						[Last Name]
	,c.VehicleMake						[Vehicle Make]
	,c.VehicleMakeOther					[Vehicle Make Other]
	,CASE WHEN ISNULL(c.VehicleModel,'')='' THEN 'Other'
		  ELSE c.VehicleModel
     END AS 						[Vehicle Model]
	,c.VehicleModelOther				 VehicleModelOther
	,c.VehicleYear						[Vehicle Year]
	,c.VehicleCurrentMileage			[Vehicle Current Mileage]
	,c.TrailerNumberofAxles
	
	,po.CreateDate						[PO Created Date]
	,cnr.[Description]					[Cancel Description]
	,gor.[Description]					[GOA Description]
	,po.IsGOA
	,(
		case
		 when gor.[Description] is not null then 'GOA - ' + gor.[Description]
		 when cnr.[Description] is not  null then 'Cancel - ' + cnr.[Description]
		 when p4.[Description] is not null then p4.[Description]
		 when p1.[Description] is not null and po.ID is not null then p1.[Description]
		 when srs.Name ='Cancelled' and (p3.[Description] is not null or p1.[Description] is not null) then 'Cancelled Service'
		 when ca.[Description] = 'Cancelled Service' and (p4.[Description] is not null or p1.[Description] is not null) then ca.[Description]
		 when pc.Name = 'Tech' and DIAG.PrimaryVehicleDiagnosticCodeID is not null then DIAG.PrimaryVehicleDiagnosticCodeName
		 when pc.[Description] is not null and pc.Name in ('Tech', 'Info', 'Concierge', 'Repair') then pc.[Description]
		 when ca.[Description] = 'Member will call back' then 'Cancel -' + ca.[Description]
		 when sr.MapTabStatus = 1 and sr.ServiceTabStatus in (3,4,5) then 'Cancelled'
		 else ca.[Description]
		end 
		)[PO Code]
	,po.ETADate
	,po.ETAMinutes
	,isnull(po.ETADate,po.CreateDate)  [Report Date]
	--,a.Case#
	,upper(ae.Line1) MbrAddLn1
	,upper(ae.Line2) MbrAddLn2
	,upper(ae.City)  MbrCity
	,upper(ae.StateProvince) MbrState
	,ae.PostalCode MbrPostalCode
	,upper(sr.ServiceLocationStateProvince) ServiceState
	,sr.ServiceMiles
	,DATEDIFF(MINUTE,sr.CreateDate,po.ETADate) CreateToETA
	,Case	when DATEDIFF(MINUTE,sr.CreateDate,po.ETADate) >=60 and str(DATEDIFF(MINUTE,sr.CreateDate,po.ETADate)-(cast((DATEDIFF(MINUTE,sr.CreateDate,po.ETADate)/60)as int))*60) <> 0 
					then ltrim(str(cast((DATEDIFF(MINUTE,sr.CreateDate,po.ETADate)/60)as int))) +' hr  '+ ltrim(str(DATEDIFF(MINUTE,sr.CreateDate,po.ETADate)-(cast((DATEDIFF(MINUTE,sr.CreateDate,po.ETADate)/60)as int))*60)) + ' min'
			when DATEDIFF(MINUTE,sr.CreateDate,po.ETADate) >=60 and str(DATEDIFF(MINUTE,sr.CreateDate,po.ETADate)-(cast((DATEDIFF(MINUTE,sr.CreateDate,po.ETADate)/60)as int))*60) = 0 
					then ltrim(str(cast((DATEDIFF(MINUTE,sr.CreateDate,po.ETADate)/60)as int))) +' hr'
			when DATEDIFF(MINUTE,sr.CreateDate,po.ETADate) < 60
					then ltrim(str(DATEDIFF(MINUTE,sr.CreateDate,po.ETADate))) + ' min' 
			end as Create_to_ETA_Hr_Min
	,ms.ClientReferenceNumber
	,c.ContactFirstName
	,c.ContactLastName
	,Case when mb.CreateBy = 'system' then 'System' when mb.Createby = 'DISPATCHPOST' then 'System' else 'Added' end Who_Created_Member
	,mb.CreateBy MemberCreateBy
	,c.VehicleLicenseNumber
	,cr.Description Member_Request
	,cla.ID action_id
	,ca.description Last_Action_Taken
	,sr.IsWorkedByTech
	,c.VehicleLicenseState
	,sr.CreateDate [Create Date Time]
	,(
		case
		 when gor.[Description] is not null then 'GOA - ' + gor.[Description]
		 when cnr.[Description] is not  null then 'Cancel - ' + cnr.[Description]
		 when p4.[Description] is not null then p4.[Description]
		 when p1.[Description] is not null and po.ID is not null then p1.[Description]
		 when srs.Name ='Cancelled' and (p3.[Description] is not null or p1.[Description] is not null) then 'Cancelled Service'
		 when ca.[Description] = 'Cancelled Service' and (p4.[Description] is not null or p1.[Description] is not null) then ca.[Description]
		 when pc.Name = 'Tech' and DIAG.PrimaryVehicleDiagnosticCodeID is not null then DIAG.PrimaryVehicleDiagnosticCodeName
		 when pc.[Description] is not null and pc.Name in ('Tech', 'Info', 'Concierge', 'Repair') then pc.[Description]
		 when ca.[Description] = 'Member will call back' then 'Cancel -' + ca.[Description]
		 when sr.MapTabStatus = 1 and sr.ServiceTabStatus in (3,4,5) then 'Cancelled'
		 else ca.[Description]
		end 
		)[Service Code]
	,mb.CreateDate Member_Create_Date
	,SUBSTRING(c.ContactPhoneNumber,3,3)+'-'+SUBSTRING(c.ContactPhoneNumber,6,3) + '-' + SUBSTRING(c.ContactPhoneNumber,9,4) ContactPhoneNumber
	,SUBSTRING(c.ContactAltPhoneNumber,3,3)+'-'+SUBSTRING(c.ContactAltPhoneNumber,6,3) + '-' + SUBSTRING(c.ContactAltPhoneNumber,9,4) ContactAltPhoneNumber
	,c.InboundPhoneNumber
	,case when CHARINDEX(',',sr.ServiceLocationAddress) > 1 then substring(sr.ServiceLocationAddress,1,(CHARINDEX(',',sr.ServiceLocationAddress)-1)) else substring(sr.ServiceLocationAddress,1,(CHARINDEX(',',sr.ServiceLocationAddress)))end ServiceLocationAddress
	,sr.ServiceLocationCity
	,sr.ServiceLocationStateProvince
	,sr.ServiceLocationPostalCode
	,sr.ServiceLocationDescription
	,case when CHARINDEX(',',sr.DestinationAddress) > 1 then substring(sr.DestinationAddress,1,(CHARINDEX(',',sr.DestinationAddress)-1)) else substring(sr.DestinationAddress,1,(CHARINDEX(',',sr.DestinationAddress)))end DestinationAddress
	,sr.DestinationCity
	,sr.DestinationStateProvince
	,sr.DestinationPostalCode
	,sr.DestinationDescription
	,case when LEN(pe.PhoneNumber) = 12 then  substring(pe.PhoneNumber,3,3) + '-' + substring(pe.PhoneNumber,6,3) + '-' + RIGHT(pe.PhoneNumber,4) else null end  DestinationPhoneNumber
	,sr.ServiceLocationCrossStreet1
	,sr.ServiceLocationCrossStreet2
	,sr.DestinationCrossStreet1
	,sr.DestinationCrossStreet2
	,c.IsDeliveryDriver
	,po.IsPayByCompanyCreditCard
	,vl.VendorID
	,v.VendorNumber
	,v.Name VendorName
     --,CAST(null as NVARCHAR(Max)) as TechComment
     --,CAST(null as datetime) TechCommentDate
     ,c.VehicleDescription
     ,diag.PrimaryVehicleDiagnosticCodeID DiagnosticCodeID
     ,diag.PrimaryVehicleDiagnosticCodeName DiagnosticCode   
 
into #Results	
from dbo.ServiceRequest sr with(nolock)
	left outer join dbo.ServiceRequestStatus srs with(nolock) on sr.ServiceRequestStatusID = srs.ID 
	left outer join dbo.ProductCategory pc with(nolock) on sr.ProductCategoryID = pc.ID 
	left outer join dbo.Product p1 with(nolock) on sr.PrimaryProductID = p1.ID 
	left outer join dbo.Product p2 with(nolock) on sr.SecondaryProductID = p2.ID 
	left outer join dbo.NextAction na with(nolock) on sr.NextActionID = na.ID 
	left outer join dbo.VehicleCategory vc with(nolock) on sr.VehicleCategoryID = vc.ID 
	left outer join dbo.ClosedLoopStatus cls with(nolock) on sr.ClosedLoopStatusID = cls.ID 
	left outer join dbo.PaymentType pt with(nolock) on MemberPaymentTypeID = pt.ID 
	left outer join dbo.[User] u with(nolock) on sr.CreateBy = u.PhoneUserID 
	left outer join dbo.[Case] c with(nolock) on sr.CaseID = c.ID 
	left outer join dbo.Program pgm1 with(nolock) on c.ProgramID = pgm1.ID 
	left outer join dbo.CasePhoneLocation cpl with(nolock) on cpl.CaseID = c.ID 
	left outer join dbo.PurchaseOrder po with(nolock) on sr.ID = po.ServiceRequestID and po.IsActive = 1
	left outer join dbo.Product p3 with(nolock) on po.ProductID = p3.ID 
	left outer join dbo.PurchaseOrderStatus pos with(nolock) on po.PurchaseOrderStatusID = pos.ID 
	left outer join dbo.Program pgm2 with(nolock) on pgm1.ParentProgramID = pgm2.ID 
	left outer join dbo.Program pgm3 with(nolock) on pgm2.ParentProgramID = pgm3.ID 
	left outer join dbo.Member mb with (nolock) on c.MemberID = mb.ID
	left outer join dbo.AddressEntity ae with (nolock) on mb.id = ae.recordid and ae.EntityID = 5
	left outer join dbo.Membership ms with (nolock)on mb.MembershipID = ms.ID
	left outer join dbo.PurchaseOrderCancellationReason  cnr  with (nolock)on po.CancellationReasonID = cnr.id
	left outer join dbo.PurchaseOrderGOAReason gor with (nolock) on gor.id= po.GOAReasonID
	left outer join dbo.ContactLogLink cll with (nolock) on cll.EntityID in (13,14) and cll.RecordID = sr.ID and cll.ID = (select MAX(id) from dbo.ContactLogLink clll with (nolock) where clll.EntityID in (13,14) and clll.RecordID = sr.ID)
	left outer join dbo.contactlog cl with (nolock) on cll.ContactLogID = cl.ID
	left outer join dbo.ContactCategory cc with (nolock) on cc.ID = cl.ContactCategoryID
	left outer join dbo.ContactLogAction cla with (nolock)on cl.ID = cla.ContactLogID and cla.ID = (select MAX(claa.id) from dbo.ContactLogAction claa where cl.ID = claa.ContactLogID and claa.ContactActionID is not null) 
	left outer join dbo.ContactAction ca with (nolock) on ca.ID = cla.ContactActionID 
	left outer join dbo.ContactLogReason clr with (nolock) on cl.ID = clr.ContactLogID and clr.ID = (select MIN (clr.ID) from dbo.ContactLogReason clr with (nolock) where cl.ID = clr.ContactLogID)
	left outer join dbo.ContactReason cr with (nolock) on clr.ContactReasonID = cr.ID
	left outer join dbo.VendorLocation vl with (nolock) on po.VendorLocationID = vl.ID
	left outer join dbo.Vendor v with (nolock) on vl.VendorID = v.ID
	left outer join dbo.PhoneEntity pe With(Nolock) on v.ID = pe.RecordID
	   and pe.EntityID = 17 --Vendor
	   and pe.PhoneTypeID =6 --Office
     left outer join [DMS].[dbo].[Entity] e With(Nolock) on e.ID = pe.EntityID
	left outer join	(select distinct pod.PurchaseOrderID, pod.ProductID from dbo.PurchaseOrderDetail pod with (nolock)) b  
				on	b.PurchaseOrderID = po.ID  
					and --if the po detail records have the same product as the po record then use it to define the product for the call
					b.ProductID =	(Case when po.ProductID = (select distinct pod1.productid from dbo.PurchaseOrderDetail pod1 with (nolock) 
									where pod1.PurchaseOrderID = po.ID and pod1.ProductID = po.ProductID) then po.ProductID
						--if the productid from the Purchase order detail doesn't match the product id on the po record then use the max id from the purchase order detail
									else (select distinct max(pod2.productid) from dbo.PurchaseOrderDetail pod2 with (nolock) 
									where pod2.PurchaseOrderID = po.ID) end)
	--Get the lable for the Product Name
	left outer join dbo.Product p4 with (nolock) on p4.ID = b.ProductID	
	
	
	left outer join -- Diagnostics
				(select srvdc.ServiceRequestID,
						srvdc.VehicleDiagnosticCodeID as PrimaryVehicleDiagnosticCodeID,
						vdc.Name as PrimaryVehicleDiagnosticCodeName,
				 		(select count(*) from dbo.ServiceRequestVehicleDiagnosticCode dc1 with (nolock)
										 where dc1.ServiceRequestID = srvdc.ServiceRequestID) as VehicleDiagnosticCodeCount
				 from dbo.ServiceRequestVehicleDiagnosticCode srvdc with (nolock)
					join dbo.VehicleDiagnosticCode vdc with (nolock) on vdc.ID = srvdc.VehicleDiagnosticCodeID
				 where srvdc.IsPrimary = 1) DIAG on DIAG.ServiceRequestID = SR.ID
	--left outer join cte_TechComment com on com.RecordID = sr.id
	---Find Case Number select * from dbo.comment

-----Use Split to filter by parent and program
	join (select s from dbo.fnNMCSplit(',',@programID)) fpgm on pgm1.ID = isnull(fpgm.s,pgm1.id)
	join @parents fpar on isnull(pgm3.id, isnull(pgm2.id, pgm1.id)) = isnull(fpar.s,isnull(pgm3.id, isnull(pgm2.id, pgm1.id)))
	
	

	where	
			(@FromDate <= sr.CreateDate and DATEADD(day,1,@ToDate)> sr.CreateDate 
			or @FromDate <= isnull(po.ETADate,sr.CreateDate) and DATEADD(day,1,@ToDate)> isnull(po.ETADate,sr.CreateDate))
			--and ca.description  like '%tow%'
			--and isnull(pgm3.id, isnull(pgm2.id, pgm1.id)) = isnull(@Parent,isnull(pgm3.id, isnull(pgm2.id, pgm1.id)))
			--and pgm1.ID = (ISNULL(@programID,pgm1.id))





CREATE TABLE #ContactLogHistory(
    
     [RecordID] int,
     [CreateDate] Datetime NULL,
	[Comments] [nvarchar](max) NULL
	
)






if @ShowComments in( 1,3)
begin 
		  
    select distinct [Service Request ID] SRID into #SR from #Results
    
    insert into #ContactLogHistory
    SELECT	
		  sr.SRID
		 ,  cl.CreateDate
		 , cl.Comments	

    FROM	dbo.ContactLog cl (NOLOCK)
    JOIN	dbo.ContactCategory cc (NOLOCK) ON cc.ID = cl.ContactCategoryID
    JOIN	dbo.ContactLogLink cll (NOLOCK) ON cll.ContactLogID = cl.ID 
    join #SR sr on cll.RecordID = sr.SRID
    LEFT JOIN	dbo.ContactLogReason clr (NOLOCK) ON clr.ContactLogID = cl.ID 
    LEFT JOIN	dbo.ContactReason cr (NOLOCK) ON cr.ID = clr.ContactReasonID
    LEFT JOIN	dbo.ContactLogAction cla (NOLOCK) ON cla.ContactLogID = cl.ID 
    LEFT JOIN	dbo.ContactAction ca (NOLOCK) ON ca.ID = cla.ContactActionID
    --LEFT JOIN	#CustomProgramDynamicValues CPDV ON CPDV.ContactLogID = CL.ID
    WHERE	--cll.RecordID = @ServiceRequestID AND 
    cll.EntityID = (SELECT ID FROM dbo.Entity with(nolock) WHERE Name = 'ServiceRequest')
    AND		cc.Name IN ('ServiceLocationSelection','ContactServiceLocation')

End


;with cte_TechComment as (select RecordID, Description ,CreateDate from [DMS].[dbo].[Comment] where  @ShowComments in( 1,2)
    and EntityID = 13 --DDragoo - 06/30/2015 - I added this because it was pulling comments for all entities and joing therm to the service request even though the comment was not on the service request
    union all 
    select RecordID, Comments Description ,CreateDate from #ContactLogHistory )
select 
	[Service Request ID]
	,[Status]
	,[Product Category]
	,[Service Request Primary Product]
	,[Service Request Secondary Product]
	,[Next Action]
	,[Vehicle Category]
	,[Closed Loop Status]
	,[Coverage Limit]
	,[Member Payment Type]
	,[Is Redispatched]
	,[Is Worked by Tech]
	,[Created Date]
	,[Created By]
	,[User Name]
	,[Program Description]
	,[WALDO Location Accuracy]
	,[PO Amount]
	,[Mbr Amount]
	,[PO Tax]
	,[PO Product]
	,[PO Status]
	,[PO ID]
	,[Purchase Order Number]
     ,[Program ID]
	,[Parent Program]
	,VIN
	,[Membership Number]
	,[First Name]
	,[Last Name]
	,[Vehicle Make]
	,[Vehicle Make Other]
	,[Vehicle Model]
	,VehicleModelOther
	,[Vehicle Year]
	,[Vehicle Current Mileage]
	,TrailerNumberofAxles	
	,[PO Created Date]
	,[Cancel Description]
	,[GOA Description]
	,IsGOA
	,[PO Code]
	,ETADate
	,ETAMinutes
	,[Report Date]
	,MbrAddLn1
	,MbrAddLn2
	,MbrCity
	,MbrState
	,MbrPostalCode
	,ServiceState
	,ServiceMiles
	,CreateToETA
	,Create_to_ETA_Hr_Min
	,ClientReferenceNumber
	,ContactFirstName
	,ContactLastName
	,Who_Created_Member
	,MemberCreateBy
	,VehicleLicenseNumber
	,Member_Request
	,action_id
	,Last_Action_Taken
	,IsWorkedByTech
	,VehicleLicenseState
	,[Create Date Time]
	,[Service Code]
	,Member_Create_Date
	,ContactPhoneNumber
	,ContactAltPhoneNumber
	,InboundPhoneNumber
	,ServiceLocationAddress
	,ServiceLocationCity
	,ServiceLocationStateProvince
	,ServiceLocationPostalCode
	,ServiceLocationDescription
	,DestinationAddress
	,DestinationCity
	,DestinationStateProvince
	,DestinationPostalCode
	,DestinationDescription
	,DestinationPhoneNumber
	,ServiceLocationCrossStreet1
	,ServiceLocationCrossStreet2
	,DestinationCrossStreet1
	,DestinationCrossStreet2
	,IsDeliveryDriver
	,IsPayByCompanyCreditCard
	,VendorID
	,VendorNumber
	,VendorName
     ,com.Description TechComment
     ,com.CreateDate TechCommentDate
     ,VehicleDescription
     ,DiagnosticCodeID
     ,DiagnosticCode 
from #results
left outer join cte_TechComment com on com.RecordID = [Service Request ID]			
--order by VehicleModel, [Service Request ID]	, PurchaseOrderNumber


GO

