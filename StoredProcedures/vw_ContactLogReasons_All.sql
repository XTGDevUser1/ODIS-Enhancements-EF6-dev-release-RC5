IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_ContactLogReasons_All]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_ContactLogReasons_All] 
 END 
 GO  
CREATE VIEW [dbo].[vw_ContactLogReasons_All]
AS

SELECT	CLR.ID ContactLogReasonID, 
		CLR.ContactLogID ContactLogID,
		CLR.ContactReasonID ContactReasonID,
		ContactLogReasons.Reasons,
		CLR.CreateDate CreateDate,
		CLR.CreateBy CreateBy
FROM	ContactLogReason CLR (NOLOCK)
Join (
	select distinct clr.ContactLogID,
	  STUFF(
			 (SELECT ', ' + cr.Name
			  FROM ContactLogReason clr2
			  Join ContactReason cr on cr.ID = clr2.ContactReasonID
			  where clr.ContactLogID = clr2.ContactLogID
			  FOR XML PATH (''))
			  , 1, 1, '')  AS Reasons
	from ContactLogReason clr
	) ContactLogReasons ON ContactLogReasons.ContactLogID = CLR.ContactLogID
GO

