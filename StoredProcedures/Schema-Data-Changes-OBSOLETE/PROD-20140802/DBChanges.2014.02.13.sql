--Temp cc buttons securables
--
-- Make buttons on Temp CC Processing page
--

DECLARE @RoleID UNIQUEIDENTIFIER
DECLARE @AccessTypeID INT
DECLARE @ButtonImportCCFile INT
DECLARE @ButtonTempCCMatch INT
DECLARE @ButtonTempCCPost INT

-- Temp CC Processing - Import CC File button
IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_IMPORT_CCFILE')
	INSERT INTO Securable (FriendlyName, ParentID, SecurityContext)
		VALUES ('BUTTON_IMPORT_CCFILE',NULL,NULL)
SET @ButtonImportCCFile = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'BUTTON_IMPORT_CCFILE')

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_TEMPCC_MATCH')
	INSERT INTO Securable (FriendlyName, ParentID, SecurityContext)
		VALUES ('BUTTON_TEMPCC_MATCH',NULL,NULL)
SET @ButtonTempCCMatch = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'BUTTON_TEMPCC_MATCH')

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_TEMPCC_POST')
	INSERT INTO Securable (FriendlyName, ParentID, SecurityContext)
		VALUES ('BUTTON_TEMPCC_POST',NULL,NULL)
SET @ButtonTempCCPost = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'BUTTON_TEMPCC_POST')

-- Setup Accounting AccessControlList
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Accounting')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ButtonImportCCFile AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ButtonImportCCFile,@RoleID,@AccessTypeID)
	END

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ButtonTempCCMatch AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ButtonTempCCMatch,@RoleID,@AccessTypeID)
	END

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ButtonTempCCPost AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ButtonTempCCPost,@RoleID,@AccessTypeID)
	END
	
-- Setup AccountingMgr AccessControlList
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='AccountingMgr')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ButtonImportCCFile AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ButtonImportCCFile,@RoleID,@AccessTypeID)
	END

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ButtonTempCCMatch AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ButtonTempCCMatch,@RoleID,@AccessTypeID)
	END

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ButtonTempCCPost AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ButtonTempCCPost,@RoleID,@AccessTypeID)
	END

-- Setup sysadmin AccessControlList
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='sysadmin')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ButtonImportCCFile AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ButtonImportCCFile,@RoleID,@AccessTypeID)
	END

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ButtonTempCCMatch AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ButtonTempCCMatch,@RoleID,@AccessTypeID)
	END

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ButtonTempCCPost AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ButtonTempCCPost,@RoleID,@AccessTypeID)
	END

GO



/****** Object:  Table [dbo].[UserPasswordHistory]    Script Date: 02/13/2014 14:32:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
IF NOT  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UserPasswordHistory]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[UserPasswordHistory](
	[ID] [int] IDENTITY(1,1)  NOT NULL,
	[aspnet_UserId] [uniqueidentifier] NULL,
	[Password] [nvarchar](50) NULL,
	[InitialUseDate] [datetime] NULL,
	[CreateDate] [datetime] NULL,
	[CreateBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_UserPasswordHistory] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[UserPasswordHistory]  WITH CHECK ADD  CONSTRAINT [FK_UserPasswordHistory_aspnet_Users] FOREIGN KEY([aspnet_UserId])
REFERENCES [dbo].[aspnet_Users] ([UserId])

ALTER TABLE [dbo].[UserPasswordHistory] CHECK CONSTRAINT [FK_UserPasswordHistory_aspnet_Users]

END
