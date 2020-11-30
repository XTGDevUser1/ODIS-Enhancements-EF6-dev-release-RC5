IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_ProgramTowCoverage]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_ProgramTowCoverage] 
 END 
 GO  
CREATE View [dbo].[vw_ProgramTowCoverage]
AS
Select p.ClientID
	,cl.Name Client
	,p.ID ProgramID
	,p.ParentProgramID
	,ppg.[Description] ParentProgram
	,p.[Description] Program
	,p.Code, p.IsGroup
	,ph.InboundNumber
	,ph.IsShownOnScreen
	,ph.IsActive
	,pp.ServiceCoverageLimit
	,pp.IsServiceCoverageBestValue
	,ISNULL(ProgramLimits.List, 'Unlimited') Limit
From Program p
Join Client cl on cl.ID = p.ClientID
Join PhoneSystemConfiguration ph on ph.ProgramID = p.ID and ph.IsActive = 1
Join ProgramProduct pp on pp.ProgramID = p.ID
Join Product prod on prod.ID = pp.ProductID and prod.ID = 141
Left Outer Join Program ppg on ppg.ID = p.ParentProgramID
Left Outer Join 
	(
	select distinct t1.ProgramID,
	  STUFF(
			 (SELECT ', ' + t2.[Description]
			  FROM ProgramServiceEventLimit t2
			  Join Program p on p.ID = t2.ProgramID
			  where t1.ProgramID = t2.ProgramID
			  FOR XML PATH (''))
			  , 1, 1, '')  AS List
	from ProgramServiceEventLimit t1
	Where t1.IsActive = 1
	) ProgramLimits ON ProgramLimits.ProgramID = p.ID
Where p.IsActive = 1
--and ph.IsShownOnScreen = 1
--Order by cl.Name, p.Name
GO

