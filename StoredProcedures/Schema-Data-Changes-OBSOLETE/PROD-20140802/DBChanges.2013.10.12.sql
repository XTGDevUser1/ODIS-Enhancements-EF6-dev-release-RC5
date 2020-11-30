ALTER TABLE Claim DROP COLUMN BillingCode
GO

ALTER TABLE ClaimCategory ADD BillingCode nvarchar(50) NULL
GO

IF NOT EXISTS(SELECT * FROM Securable WHERE FriendlyName = 'PO_BUTTON_REISSUECC')
BEGIN
INSERT INTO [dbo].[Securable]
           ([FriendlyName]
           ,[ParentID]
           ,[SecurityContext])
     VALUES
           ('PO_BUTTON_REISSUECC',
			 3,
			 NULL
           )
END           

DECLARE @RoleId uniqueidentifier
SET @RoleId = (select RoleId from aspnet_Roles where RoleName = 'SysAdmin' and ApplicationId = (SELECT TOP 1 ApplicationId from 
aspnet_Applications where ApplicationName = 'DMS'))
DECLARE @POSecurable int
SET @POSecurable = (SELECT ID FROM Securable WHERE FriendlyName = 'PO_BUTTON_REISSUECC')
DECLARE @ReadWriteAcessType int
SET @ReadWriteAcessType = (SELECT ID FROM AccessType WHERE Name = 'ReadWrite')

INSERT INTO [dbo].[AccessControlList]
           ([SecurableID]
           ,[RoleID]
           ,[AccessTypeID])
     VALUES
           (@POSecurable
           ,@RoleId
           ,@ReadWriteAcessType)
GO



ALTER TABLE PurchaseOrder ADD IsNotInvoiceEligible BIT NULL
GO


INSERT INTO ApplicationConfiguration 
SELECT 1,10,NULL,NULL,'VendorDocumentsUserName','inforica\devadmin',GETDATE(),'system',NULL, NULL
UNION ALL
SELECT 1,10,NULL,NULL,'VendorDocumentsPassword','Inf#su',GETDATE(),'system',NULL, NULL
UNION ALL
SELECT 1,10,NULL,NULL,'ExportFilesFolderUserName','inforica\devadmin',GETDATE(),'system',NULL, NULL
UNION ALL
SELECT 1,10,NULL,NULL,'ExportFilesFolderPassword','Inf#su',GETDATE(),'system',NULL, NULL
GO