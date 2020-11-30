IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_ContactLogReasons]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_ContactLogReasons] 
 END 
 GO  
CREATE VIEW [dbo].[vw_ContactLogReasons]
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
LEFT JOIN ContactReason CR (NOLOCK) ON CR.ID = CLR.ContactReasonID 
LEFT JOIN ContactCategory CC (NOLOCK) ON CC.ID = CR.ContactCategoryID
GO

