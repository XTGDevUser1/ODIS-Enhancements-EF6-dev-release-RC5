IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_ContactLogActions]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_ContactLogActions] 
 END 
 GO  
CREATE VIEW [dbo].[vw_ContactLogActions]
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
LEFT JOIN ContactAction CA (NOLOCK) ON CA.ID = CLA.ContactActionID 
LEFT JOIN ContactCategory CC (NOLOCK) ON CC.ID = CA.ContactCategoryID
GO

