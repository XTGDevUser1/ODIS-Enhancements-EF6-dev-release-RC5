ALTER TABLE Claim
DROP COLUMN AccountingInvoiceBatchID
GO
ALTER TABLE Claim
ADD PassthruAccountingInvoiceBatchID INT NULL
GO
ALTER TABLE Claim
ADD FeeAccountingInvoiceBatchID INT NULL
GO
ALTER TABLE Claim
ADD VehicleID INT NULL
GO

ALTER TABLE Claim
ADD VehicleOwnerName NVARCHAR(255) NULL
GO

CREATE NONCLUSTERED INDEX [IDX_Vendor_VendorStatus]
    ON [dbo].[Vendor]([VendorStatusID],[IsActive])
    INCLUDE([ID]) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ONLINE = OFF, MAXDOP = 0)
    ON [PRIMARY];
GO

CREATE NONCLUSTERED INDEX [IDX_Vendor_VendorStatus]
    ON [dbo].[VendorLocation]([VendorLocationStatusID],[IsActive])
    INCLUDE([ID]) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ONLINE = OFF, MAXDOP = 0)
    ON [PRIMARY];
GO

--Securables for client management scripts
INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
     VALUES ('MENU_LEFT_CLIENT_INVOICEPROCESSING',26,NULL)
INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
     VALUES ('MENU_LEFT_CLIENT_INVOICEBATCHES',26,NULL)
INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
     VALUES ('MENU_LEFT_BILLING_BILLINGHISTORY',26,NULL)

DECLARE @RoleId uniqueidentifier
DECLARE @SecurableInvoiceProcessing int
DECLARE @SecurableInvoiceBatches int
DECLARE @SecurableBillingHistory int

SET @RoleId = (SELECT TOP 1 RoleId FROM aspnet_Roles WHERE RoleName = 'SysAdmin' and ApplicationId = (SELECT TOP 1 ApplicationId FROM aspnet_Applications WHERE ApplicationName = 'DMS'))
SET @SecurableInvoiceProcessing = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'MENU_LEFT_CLIENT_INVOICEPROCESSING')
SET @SecurableInvoiceBatches = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'MENU_LEFT_CLIENT_INVOICEBATCHES')
SET @SecurableBillingHistory = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'MENU_LEFT_BILLING_BILLINGHISTORY')

INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES (@SecurableInvoiceProcessing, @RoleId, 3)
INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES (@SecurableInvoiceBatches, @RoleId, 3)
INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES (@SecurableBillingHistory, @RoleId, 3)