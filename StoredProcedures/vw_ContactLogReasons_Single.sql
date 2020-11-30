IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_ContactLogReasons_Single]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_ContactLogReasons_Single] 
 END 
 GO  
CREATE VIEW [dbo].[vw_ContactLogReasons_Single]
AS
SELECT	CLR.ID ContactLogReasonID, 
		CLR.ContactLogID ContactLogID,
		CLR.ContactReasonID ContactReasonID,
		CR.Name ContactReasonName,
		CR.Description ContactReasonDescription, 
		CR.ContactCategoryID ContactCategoryID,
		CC.Name ContactCategoryName,
		CC.Description ContactCategoryDescription,
		CLR.CreateDate CreateDate,
		CLR.CreateBy CreateBy
FROM	ContactLogReason CLR (NOLOCK)
JOIN	(
		SELECT ContactLogID, MAX(ContactReasonID) ContactReasonID
		FROM ContactLogReason
		GROUP BY ContactLogID
		) Single_CLR ON Single_CLR.ContactLogID = CLR.ContactLogID AND Single_CLR.ContactReasonID = CLR.ContactReasonID
LEFT JOIN ContactReason CR (NOLOCK) ON CR.ID = CLR.ContactReasonID 
LEFT JOIN ContactCategory CC (NOLOCK) ON CC.ID = CR.ContactCategoryID
GO

