-- 
-- Make "Post Selected" button securable
--

-- REMOVE OLD ENTRIES IN AccessControlList and Securable (RH: 1/20)
-- This is referring to the old left menu item: Billable Event Processing which has been removed
DELETE FROM AccessControlList WHERE SecurableID = (SELECT ID From Securable WHERE FriendlyName = 'MENU_LEFT_CLIENT_BILLING')
DELETE FROM Securable WHERE ID = (SELECT ID From Securable WHERE FriendlyName = 'MENU_LEFT_CLIENT_BILLING')

-- SETUP NEW ENTRIES FOR "Post Selected Invoices" BUTTON
DECLARE @parentID INT 
DECLARE @recordID INT 
DECLARE @InvoiceProcessingID INT
DECLARE @BillingHistoryID INT

DECLARE @accounting UNIQUEIDENTIFIER
DECLARE @accountingMGR  UNIQUEIDENTIFIER
DECLARE @sysadmin UNIQUEIDENTIFIER
 
SET @accounting = (select R.RoleId from aspnet_Roles R join
aspnet_Applications  A
ON R.ApplicationId = A.ApplicationId
WHERE A.ApplicationName = 'DMS'
AND R.RoleName ='Accounting')
 
SET @accountingMGR = (select R.RoleId from aspnet_Roles R join
aspnet_Applications  A
ON R.ApplicationId = A.ApplicationId
WHERE A.ApplicationName = 'DMS'
AND R.RoleName ='AccountingMgr')

SET @sysadmin = (select R.RoleId from aspnet_Roles R join
aspnet_Applications  A
ON R.ApplicationId = A.ApplicationId
WHERE A.ApplicationName = 'DMS'
AND R.RoleName ='sysadmin')


SET @parentID = (SELECT ID FROM Securable WHERE FriendlyName = 'MENU_TOP_CLIENT')
SET @recordID = (SELECT ID FROM Securable WHERE FriendlyName = 'BUTTON_POST_INVOICES')
SET @InvoiceProcessingID = (SELECT ID FROM Securable WHERE FriendlyName = 'MENU_LEFT_CLIENT_INVOICEPROCESSING') 
SET @BillingHistoryID = (SELECT ID FROM Securable WHERE FriendlyName = 'MENU_LEFT_BILLING_BILLINGHISTORY') 

IF EXISTS(SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_POST_INVOICES')
BEGIN
	DELETE FROM AccessControlList WHERE SecurableID = (SELECT ID From Securable WHERE FriendlyName = 'BUTTON_POST_INVOICES')
	DELETE FROM Securable WHERE FriendlyName = 'BUTTON_POST_INVOICES'
END

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_POST_INVOICES')
BEGIN
      INSERT INTO Securable Values('BUTTON_POST_INVOICES',NULL,NULL) 
      SET @recordID = SCOPE_IDENTITY()
END
 
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @recordID AND RoleID = @accounting)
BEGIN  
      INSERT INTO AccessControlList VALUES(@recordID,@accounting,3)
END

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @recordID AND RoleID = @accountingMgr)
BEGIN
      INSERT INTO AccessControlList VALUES(@recordID,@accountingMGR,3)
END

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @recordID AND RoleID = @sysadmin)
BEGIN
      INSERT INTO AccessControlList VALUES(@recordID,@sysadmin,3)
END

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @InvoiceProcessingID AND RoleID = @accounting)
BEGIN
	INSERT INTO AccessControlList VALUES(@InvoiceProcessingID,@accounting,3)
END

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @InvoiceProcessingID AND RoleID = @accountingMgr)
BEGIN
      INSERT INTO AccessControlList VALUES(@InvoiceProcessingID,@accountingMGR,3)
END

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @BillingHistoryID AND RoleID = @accounting)
BEGIN
	INSERT INTO AccessControlList VALUES(@BillingHistoryID,@accounting,3)
END

--PHANI
IF NOT EXISTS (SELECT * FROM CommentType WHERE Name = 'ServiceRequest')
BEGIN
INSERT INTO CommentType VALUES('ServiceRequest', 'Service Request',1,1)
END


--select * from securable where id in (26,28,29,30,49,50,52,53)
--select s.Friendlyname, r.rolename, * from AccessControlList acl join securable s on s.id = acl.securableid join aspnet_roles r on r.roleid = acl.roleid where securableid in (26,28,29,30,49,50,52,53) order by r.roleid, s.id
--select s.Friendlyname, r.rolename, * from AccessControlList acl join securable s on s.id = acl.securableid join aspnet_roles r on r.roleid = acl.roleid where r.roleid = 'FE2ECF25-EDE4-408D-9E37-9D2F278B7C68' order by r.roleid, s.id


