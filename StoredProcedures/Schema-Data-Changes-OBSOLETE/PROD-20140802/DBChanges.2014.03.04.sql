
ALTER TABLE VendorInvoice
ALTER COLUMN BillingContactName  nvarchar(100)
GO

ALTER TABLE VendorInvoice ALTER COLUMN BillingBusinessName NVARCHAR(255)
GO
--BUG 167
ALTER TABLE TemporaryCreditCard ADD LastChargedDate DATETIME NULL
GO
--Bug 169
ALTER TABLE TemporaryCreditCard 
ADD IsExceptionOverride bit 
GO
--Bug 161
UPDATE PurchaseOrder
SET ContractStatus = 
'Not Contracted'
WHERE ContractStatus = 'NotContracted'
GO
--CR --165
ALTER TABLE TemporaryCreditCard_Import ALTER COLUMN CPN_PAN_CreditCardNumber NVARCHAR(50) NULL
GO
ALTER TABLE TemporaryCreditCard_Import ADD PURCHASE_TYPE NVARCHAR(100) NULL
GO

-- CR --163

/****** Object:  Table [dbo].[ServiceRequestException]    Script Date: 3/4/2014 6:10:57 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ServiceRequestException](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ServiceRequestID] [int] NOT NULL,
	[RequestArea] [nvarchar](50) NULL,
	[ExceptionMessage] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_ServiceRequestException] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

ALTER TABLE [dbo].[ServiceRequestException]  WITH CHECK ADD  CONSTRAINT [FK_ServiceRequestException_ServiceRequest] FOREIGN KEY([ServiceRequestID])
REFERENCES [dbo].[ServiceRequest] ([ID])
GO

ALTER TABLE [dbo].[ServiceRequestException] CHECK CONSTRAINT [FK_ServiceRequestException_ServiceRequest]
GO


--PHANI
DECLARE @sysAdminRoleID UNIQUEIDENTIFIER
SET		@sysAdminRoleID = (SELECT RoleID FROM aspnet_Roles WHERE LoweredRoleName = 'sysadmin' AND ApplicationId = (SELECT ApplicationId FROM aspnet_Applications WHERE LoweredApplicationName = 'VendorPortal'))

IF NOT EXISTS (SELECT * FROM Securable where FriendlyName = 'MENU_LEFT_ISP_IMPERSONATE')
BEGIN
INSERT INTO Securable(FriendlyName,ParentID) VALUES('MENU_LEFT_ISP_IMPERSONATE',(Select ID from Securable where FriendlyName='MENU_TOP_ADMIN'))
INSERT INTO AccessControlList(SecurableID,RoleID,AccessTypeID) VALUES(SCOPE_IDENTITY(),@sysAdminRoleID,(SELECT ID FROM AccessType WHERE Name = 'ReadWrite')) 
END