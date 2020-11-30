ALTER TABLE Product
ADD [AccountingSystemItemCode] nvarchar(14) NULL;
ALTER TABLE ContactLog
ADD [VendorServiceRatingAdjustment] decimal(5,2);


DECLARE @ContactCategoryID INT
SET @ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ContactVendor')
INSERT INTO [ContactReason]
([ContactCategoryID]
,[Name]
,[Description]
,[IsActive]
,[IsShownOnScreen]
,[Sequence])
VALUES
(@ContactCategoryID, 'NewVendor', 'NewVendor', 1, 0, NULL)
INSERT INTO [ContactAction]
([ContactCategoryID]
,[Name]
,[Description]
,[IsShownOnScreen]
,[IsTalkedToRequired]
,[IsActive]
,[Sequence])
VALUES
(@ContactCategoryID, 'SendWelcomeLetter', 'Send Welcome Letter', 1,1, 0, NULL)

IF NOT EXISTS(SELECT * FROM EventCategory WHERE Name = 'PurchaseOrder')
BEGIN
INSERT INTO [EventCategory]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('PurchaseOrder', 'Purchase Order', 16, 1)
END  

DECLARE @EventTypeID INT
SET @EventTypeID = (SELECT ID FROM EventType WHERE Name = 'User')
DECLARE @EventCategoryID INT
SET @EventCategoryID = (SELECT ID FROM EventCategory WHERE Name = 'PurchaseOrder')

IF NOT EXISTS(SELECT * FROM Event WHERE Name = 'Re-Issued temporary cc')
BEGIN
INSERT INTO [Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES
           (@EventTypeID, @EventCategoryID, 'Re-Issued temporary cc','Re-issued temporary credit card', 1, 1, NULL, NULL)
END    
