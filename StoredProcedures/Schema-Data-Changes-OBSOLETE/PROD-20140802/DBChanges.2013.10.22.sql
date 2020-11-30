DECLARE @EventType INT = (SELECT ID FROM EventType WHERE Name =  'User')
DECLARE @EventCategory INT = (SELECT ID FROM EventCategory WHERE Name =  'Billing')
IF NOT EXISTS ( SELECT * FROM [Event] WHERE Name = 'UpdateBillingInvoiceDetail')
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
           (@EventType,@EventCategory, 'UpdateBillingInvoiceDetail', 'Update BillingInvoiceDetail', 1, 1, NULL, NULL)
END
IF NOT EXISTS ( SELECT * FROM [Event] WHERE Name = 'AddInvoiceLine')
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
           (@EventType,@EventCategory, 'AddInvoiceLine', 'Add Invoice Line', 1, 1, NULL, NULL)
           
END
IF NOT EXISTS ( SELECT * FROM [Event] WHERE Name = 'DeleteInvoiceLine')
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
           (@EventType,@EventCategory, 'DeleteInvoiceLine', 'Delete Invoice Line', 1, 1, NULL, NULL)
END
IF NOT EXISTS ( SELECT * FROM [Event] WHERE Name = 'RefreshInvoiceDetails')
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
           (@EventType,@EventCategory,'RefreshInvoiceDetails', 'Refresh Invoice Details', 1, 1, NULL, NULL)
END
IF NOT EXISTS ( SELECT * FROM [Event] WHERE Name = 'PostInvoice')
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
           (@EventType,@EventCategory,'PostInvoice', 'Post Invoice', 1, 1, NULL, NULL)
END
IF NOT EXISTS ( SELECT * FROM [Event] WHERE Name = 'RefreshAllInvoiceDetails')
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
           (@EventType,@EventCategory,'RefreshAllInvoiceDetails', 'Refresh All Invoice Details', 1, 1, NULL, NULL)
END

IF NOT EXISTS ( SELECT * FROM [Event] WHERE Name = 'PostAllInvoices')
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
           (@EventType,@EventCategory,'PostAllInvoices', 'Post All Invoices', 1, 1, NULL, NULL)
END           
GO

     
     

