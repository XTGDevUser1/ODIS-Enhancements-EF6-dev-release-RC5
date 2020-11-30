DECLARE @ContactCategoryID INT

SET @ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ContactVendor')

IF NOT EXISTS ( SELECT * FROM ContactAction WHERE Name = 'SendRateSchedule' )
BEGIN
INSERT INTO [ContactAction]
           ([ContactCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsTalkedToRequired]
           ,[IsActive]
           ,[Sequence])
     VALUES
           (@ContactCategoryID, 'SendRateSchedule', 'Send Rate Schedule', 1, 0, 1,NULL)
           
END


Update Securable set FriendlyName ='MENU_LEFT_ISP_SERVICERATINGS' where FriendlyName='MENU_LEFT_ISP_CONTACTHISTORY'