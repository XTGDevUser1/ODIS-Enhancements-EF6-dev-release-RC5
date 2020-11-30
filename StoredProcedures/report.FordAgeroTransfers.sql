USE [DMS]
GO

/****** Object:  StoredProcedure [report].[FordAgeroTransfers]    Script Date: 10/27/2015 13:20:44 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[report].[FordAgeroTransfers]') AND type in (N'P', N'PC'))
DROP PROCEDURE [report].[FordAgeroTransfers]
GO

USE [DMS]
GO

/****** Object:  StoredProcedure [report].[FordAgeroTransfers]    Script Date: 10/27/2015 13:20:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--EXEC [report].[FordAgeroTransfers] '9/22/2015', '10/1/2015'

CREATE PROCEDURE [report].[FordAgeroTransfers] (
	@BeginDate date,
	@EndDate date
)
AS

Select 
	cla.ServiceRequestID ServiceRequest
	 , COALESCE(VINCapture.CreateDate, cla.CreateDate) CreateDate
	 , COALESCE(VINCapture.CreateBy, cla.CreateBy) CreateBy
	 , UPPER(VINCapture.VIN) VIN
	 , CASE WHEN VINCapture.VIN = '11111111111111111' THEN 0 ELSE DMS.dbo.fnc_IsValidVINCheckDigit(VINCapture.VIN) END IsValidVIN
from DMS.dbo.vw_ContactLogActions_All cla
join DMS.dbo.ServiceRequest SR (NOLOCK) on SR.ID = cla.ServiceRequestID
join DMS.dbo.ServiceRequestStatus srs on srs.ID = SR.ServiceRequestStatusID
join DMS.dbo.[Case] c on c.ID = SR.CaseID
Left Outer Join (
	Select pdive1.RecordID CaseID, pdive1. CreateDate, pdive1.CreateBy, pdive1.Value VIN
	FROM DMS.dbo.ProgramDataItemValueEntity pdive1 (NOLOCK)
	JOIN (
		SELECT EntityID, RecordID CaseID, MIN(ID) ProgramDataItemValueEntityID
		FROM DMS.dbo.ProgramDataItemValueEntity
		WHERE ProgramDataItemID = 278
		AND EntityID = 2
		GROUP BY EntityID, RecordID 
		) FirstPdive on FirstPdive.ProgramDataItemValueEntityID = pdive1.ID
	)VINCapture on VINCapture.CaseID = SR.CaseID 

where cla.Actions like '%Transferred Call to Agero%'
and SR.CreateDate >= @BeginDate 
and SR.CreateDate < dateadd(dd,1,@EndDate)
--and srs.Name in ('Complete', 'Cancelled')
Order by sr.CreateDate

GO


