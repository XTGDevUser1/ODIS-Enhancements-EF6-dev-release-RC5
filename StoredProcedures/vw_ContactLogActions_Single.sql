IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_ContactLogActions_Single]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_ContactLogActions_Single] 
 END 
 GO  
CREATE VIEW [dbo].[vw_ContactLogActions_Single]
AS
SELECT	CLA.ID ContactLogActionID, 
		CLA.ContactLogID ContactLogID,
		CLA.ContactActionID ContactActionID,
		CA.Description ContactActionDescription, 
		CA.ContactCategoryID ContactCategoryID,
		CC.Description ContactCategoryDescription,
		CLA.Comments Comments, 
		CLA.CreateDate CreateDate,
		CLA.CreateBy CreateBy
FROM	ContactLogAction CLA (NOLOCK)
JOIN	(
		SELECT ContactLogID, MAX(ContactActionID) ContactActionID
		FROM ContactLogAction
		GROUP BY ContactLogID
		) Single_CLA ON Single_CLA.ContactLogID = CLA.ContactLogID AND Single_CLA.ContactActionID = CLA.ContactActionID
LEFT JOIN ContactAction CA (NOLOCK) ON CA.ID = CLA.ContactActionID 
LEFT JOIN ContactCategory CC (NOLOCK) ON CC.ID = CA.ContactCategoryID
GO

