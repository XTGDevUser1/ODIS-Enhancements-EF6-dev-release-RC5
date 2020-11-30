IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vwContactCategoryAction]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vwContactCategoryAction] 
 END 
 GO  
CREATE VIEW [dbo].[vwContactCategoryAction]
AS
SELECT     TOP (99999) ContactAction.ID, ContactCategory.Name AS ContactCategory, ContactAction.Name AS ContactAction, ContactAction.Description, 
                      ContactAction.IsShownOnScreen, ContactAction.IsActive, ContactAction.Sequence
FROM         dbo.ContactAction INNER JOIN
                      dbo.ContactCategory ON ContactAction.ContactCategoryID = ContactCategory.ID
ORDER BY ContactCategory, ContactAction.Sequence
GO

