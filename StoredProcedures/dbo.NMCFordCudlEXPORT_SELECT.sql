/****** Object:  StoredProcedure [dbo].[NMCFordCudlEXPORT_SELECT]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[NMCFordCudlEXPORT_SELECT]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[NMCFordCudlEXPORT_SELECT] 
 END 
 GO  
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--dbo.NMCFordCudlEXPORT_SELECT '09/20/2013'  --20141014
--dbo.NMCFordCudlEXPORT_SELECT '10/14/2014'

CREATE procedure [dbo].[NMCFordCudlEXPORT_SELECT]
(	
	@pProcessDate as date
)
AS


--******************************************************************************************
--******************************************************************************************
--
--		
--******************************************************************************************
--******************************************************************************************

--declare
--@date date = getdate()


						
			Select	
			1 pkid,	
			'000000000000' +
			RIGHT(REPLICATE(' ',17)+convert(varchar,upper(c.VehicleVIN)),17) +
			Case when pgm1.ID = 266 then '1416' else '1415' end +
			RIGHT(REPLICATE(' ',6)+convert(varchar,''),6) +
			RIGHT(REPLICATE('0',6)+convert(varchar,c.VehicleCurrentMileage),6) +
		    
			Case when sc.ServiceCode like '%tow%' then 'CCM002'
						when sc.ServiceCode like '%lock%' or sc.PurchaseOrderID like '%mech%' then 'CCM003' 
						when sc.ServiceCode like '%jump%' then 'CCM004'
						when sc.ServiceCode like '%Tire%' then 'CCM005'
						when sc.ServiceCode like '%Fluid%' then 'CCM006'
						when sc.ServiceCode like '%Winch%' then 'CCM007'
						else sc.ServiceCode
						end +
			 c.VehicleMileageUOM  + ': ' + cast(c.VehicleCurrentMileage as nvarchar(11)) + '; '+ sc.ServiceCode   as DataRow

		   into #results   
	
		from DMS.dbo.ServiceRequest sr with(nolock)
			  left join DMS.dbo.ServiceRequestStatus srs with(nolock) on sr.ServiceRequestStatusID = srs.ID 
			  left join DMS.dbo.[Case] c with(nolock) on sr.CaseID = c.ID 
			  left join DMS.dbo.Program pgm1 with(nolock) on c.ProgramID = pgm1.ID 
			  left join DMS.dbo.PurchaseOrder po with(nolock) on sr.ID = po.ServiceRequestID and po.IsActive = 1
			  left join DMS.dbo.Program pgm2 with(nolock) on pgm1.ParentProgramID = pgm2.ID 
			  left join DMS.dbo.Program pgm3 with(nolock) on pgm2.ParentProgramID = pgm3.ID 
			  left join DMS.dbo.vw_ServiceCode sc with (nolock) on sc.ServiceRequestID = sr.ID and ISNULL(sc.PurchaseOrderID,0) = ISNULL(po.id,0)
		where isnull(pgm3.id, isnull(pgm2.id, pgm1.id)) = 86						---Parent = Ford
				  and pgm1.ID <>343                                             ---Dosne't include FORD Direct Tow
				  and po.CreateDate between DATEADD(dd,-1,convert(date,@pProcessDate,112)) and convert(date,@pProcessDate,112)
				  and   po.id is not null                                       ---Only Pull Valid events with a PO created 
																				---need to verify how rebursements will be docuemnted
				  and (sc.ServiceCode like '%tow%' or sc.ServiceCode like '%lock%' or sc.ServiceCode like '%mech%'        
						or sc.ServiceCode like '%jump%' or sc.ServiceCode like '%Tire%' or sc.ServiceCode like '%Fluid%'
						or sc.ServiceCode like '%Winch%')
		
	Union all
	

		SELECT
				2, 
				'000000000000' +
				RIGHT(REPLICATE(' ',17)+convert(varchar,upper(c.VehicleVIN)),17) +
				Case when p1.ID = 266 then '1416' else '1415' end +
				RIGHT(REPLICATE(' ',12)+convert(varchar,c.CurrentMiles),12) +
			    'CCM002' + ---Was advised by Kristen Ellingson all claims were coded tow Not captured in Claims Process
			    'Miles' + ': ' + cast(c.CurrentMiles as nvarchar(11)) + '; '+ 
						(case	when SUBSTRING(c.VehicleVIN,6,1) in ('3','4','5')then 'Tow - MD'
								when SUBSTRING(c.VehicleVIN,6,1) in ('6','7')then  'Tow - HD' else 'TOW - LD' end )--as data

			
		  FROM [DMS].[dbo].[Claim] c with (nolock)
		  left join dms.dbo.ClaimType ct with (nolock) on c.ClaimTypeID = ct.ID 
		  left join dms.dbo.ClaimCategory cc with (nolock) on cc.ID = c.ClaimCategoryID
		  left join dms.dbo.ClaimStatus cs with (nolock) on cs.ID = c.ClaimStatusID
		  left join dms.dbo.Program p1 with (nolock) on c.ProgramID = p1.ID
		  left join DMS.dbo.Program p2 with (nolock) on p1.ParentProgramID = p2.ID 
		  left join DMS.dbo.Program p3 with (nolock) on p2.ParentProgramID = p3.ID 
		  left join dms.dbo.ContactMethod cm with (nolock) on c.ReceiveContactMethodID = cm.ID
		  left join dms.dbo.ProductCategory pc with (nolock) on pc.ID = c.ServiceProductCategoryID
		  
		  
		  where isnull(p3.id, isnull(p2.id, p1.id)) = 86
				and c.CreateDate between DATEADD(dd,-1,convert(date,@pProcessDate,112)) and convert(date,@pProcessDate,112)
				and c.CurrentMiles is not null	

						
						

select DataRow
from (
	select 0 as PKID,
		'HDRFORD_CUDL '+convert(varchar,dateadd(dd,-1,convert(date,@pProcessDate)),112)+
		'005000' as DataRow
			
	union all

		Select *
		from #results
			

	union all
	
		SELECT 3,'TRL' + RIGHT(REPLICATE('0',9)+convert(varchar,(select count(*) from #results)),9) + RIGHT(REPLICATE('0',9)+convert(varchar,(select count(*) from #results)),9)

	)a

order by PKID
GO

