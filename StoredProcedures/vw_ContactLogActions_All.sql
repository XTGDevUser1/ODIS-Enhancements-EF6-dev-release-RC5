IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_ContactLogActions_All]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_ContactLogActions_All] 
 END 
 GO  
CREATE VIEW [dbo].[vw_ContactLogActions_All]
AS
SELECT	CLL.RecordID ServiceRequestID,
		CL.ID ContactLogID,
		ContactLogActions.Actions,
		CL.CreateDate CreateDate,
		CL.CreateBy CreateBy
FROM	ContactLog CL (NOLOCK)
Join	ContactLogLink CLL on CLL.ContactLogID = CL.ID And CLL.EntityID = (Select ID From Entity Where Name = 'ServiceRequest') 
Join (
	select distinct cla.ContactLogID,
	  STUFF(
			 (SELECT ', ' + ca.[Description]
			  FROM ContactLogAction cla2
			  Join ContactAction ca on ca.ID = cla2.ContactActionID
			  where cla.ContactLogID = cla2.ContactLogID
			  FOR XML PATH (''))
			  , 1, 1, '')  AS Actions
	from ContactLogAction cla
	) ContactLogActions ON ContactLogActions.ContactLogID = CL.ID
GO

