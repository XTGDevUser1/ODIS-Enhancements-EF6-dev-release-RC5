/****** Object:  Table [dbo].[ClientUser]    Script Date: 12/16/2015 2:47:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ClientUser](
	[ID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[ClientID] [int] NULL,
	[aspnet_UserID] [uniqueidentifier] NOT NULL,
	[PostLoginPromptID] [int] NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[IsHelpOverlayEnabled] [bit] NULL,
	[ChangePassword] [bit] NULL,
	[ReceiveNotification] [bit] NULL,
	[CreateDate] [datetime] NULL,
	[CreateBy] [nvarchar](50) NULL,
	[ModifyDate] [datetime] NULL,
	[ModifyBy] [nvarchar](50) NULL,
	[PasswordResetToken] [nvarchar](50) NULL,
	[PasswordTokenGeneratedOn] [datetime] NULL,
	[PasswordTokenValidityInHours] [int] NULL,
 CONSTRAINT [PK_ClientUser] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[ClientUser] ADD  CONSTRAINT [DF_ClientUser_PostLoginPromptID]  DEFAULT ((1)) FOR [PostLoginPromptID]
GO
ALTER TABLE [dbo].[ClientUser]  WITH CHECK ADD  CONSTRAINT [FK_ClientUser_aspnet_Users] FOREIGN KEY([aspnet_UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO
ALTER TABLE [dbo].[ClientUser] CHECK CONSTRAINT [FK_ClientUser_aspnet_Users]
GO
ALTER TABLE [dbo].[ClientUser]  WITH CHECK ADD  CONSTRAINT [FK_ClientUser_PostLoginPrompt] FOREIGN KEY([PostLoginPromptID])
REFERENCES [dbo].[PostLoginPrompt] ([ID])
GO
ALTER TABLE [dbo].[ClientUser] CHECK CONSTRAINT [FK_ClientUser_PostLoginPrompt]
GO
ALTER TABLE [dbo].[ClientUser]  WITH CHECK ADD  CONSTRAINT [FK_ClientUser_Client] FOREIGN KEY([ClientID])
REFERENCES [dbo].[Client] ([ID])
GO
ALTER TABLE [dbo].[ClientUser] CHECK CONSTRAINT [FK_ClientUser_Client]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserInviteStatus](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Description] [nvarchar](50) NULL,
	[Sequence] [int] NULL,
	[IsActive] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Table [dbo].[UserInvite]    Script Date: 12/16/2015 3:08:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserInvite](
	[ID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[ClientID] [int] NULL,
	[ClientUserID] [int] NULL,
	[aspnet_UserID] [uniqueidentifier] NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[Email] [nvarchar](255) NULL,
	[aspnet_RoleID] [uniqueidentifier] NULL,
	[InviteStatusID] [int] NULL,
	[ResponseDate] [datetime] NULL,
	[CreateDate] [datetime] NULL,
	[CreateBy] [nvarchar](50) NULL,
	[ModifyDate] [datetime] NULL,
	[ModifyBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_UserInvite] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[UserInvite]  WITH CHECK ADD  CONSTRAINT [FK_UserInvite_aspnet_Roles] FOREIGN KEY([aspnet_RoleID])
REFERENCES [dbo].[aspnet_Roles] ([RoleId])
GO
ALTER TABLE [dbo].[UserInvite] CHECK CONSTRAINT [FK_UserInvite_aspnet_Roles]
GO
ALTER TABLE [dbo].[UserInvite]  WITH CHECK ADD  CONSTRAINT [FK_UserInvite_aspnet_Users] FOREIGN KEY([aspnet_UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO
ALTER TABLE [dbo].[UserInvite] CHECK CONSTRAINT [FK_UserInvite_aspnet_Users]
GO
ALTER TABLE [dbo].[UserInvite]  WITH CHECK ADD  CONSTRAINT [FK_UserInvite_Client] FOREIGN KEY([ClientID])
REFERENCES [dbo].[Client] ([ID])
GO
ALTER TABLE [dbo].[UserInvite] CHECK CONSTRAINT [FK_UserInvite_Client]
GO
ALTER TABLE [dbo].[UserInvite]  WITH CHECK ADD  CONSTRAINT [FK_UserInvite_ClientUser] FOREIGN KEY([ClientUserID])
REFERENCES [dbo].[ClientUser] ([ID])
GO
ALTER TABLE [dbo].[UserInvite] CHECK CONSTRAINT [FK_UserInvite_ClientUser]
GO
ALTER TABLE [dbo].[UserInvite]  WITH CHECK ADD  CONSTRAINT [FK_UserInvite_UserInviteStatus] FOREIGN KEY([InviteStatusID])
REFERENCES [dbo].[UserInviteStatus] ([ID])
GO
ALTER TABLE [dbo].[UserInvite] CHECK CONSTRAINT [FK_UserInvite_UserInviteStatus]
GO
