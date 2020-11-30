USE [DMS]
GO

/****** Object:  View [dbo].[vw_PhoneSystemMap]    Script Date: 04/26/2016 06:54:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[vw_PhoneSystemMap]
AS	

SELECT 
	ps.ClientID
	,cl.Name ClientName
	,ps.ProgramID
	,prg.Name ProgramName
	,PilotNumber
	,ps.CustomVariable1
	,ps.CustomVariable5
	,ps.CustomVariable8
	,ps.CSQName
	,ps.PhoneSystemDescription
	,CASE WHEN ps.ClientID = 58 THEN 30 ELSE 20 END SLA_AnswerSeconds
From PhoneSystemMap ps
Left Outer Join Client cl on cl.ID = ps.ClientID
Left Outer Join Program prg on prg.ID = ps.ProgramID



GO

