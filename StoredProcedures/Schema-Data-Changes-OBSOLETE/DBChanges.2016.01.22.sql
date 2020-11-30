ALTER TABLE UserPortletDefaultByRole 
ADD IsDisplayedByDefault BIT NULL



/****** Object:  Table [dbo].[PortletAccessList]    Script Date: 1/22/2016 11:50:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PortletAccessList](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[PortletID] [int] NULL,
	[ClientTypeID] [int] NULL,
	[ClientID] [int] NULL,
	[RoleID] [uniqueidentifier] NULL,
	[ClientUserID] [int] NULL,
 CONSTRAINT [PK_PortletAccessList] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[PortletAccessList]  WITH CHECK ADD  CONSTRAINT [FK_PortletAccessList_aspnet_Roles] FOREIGN KEY([RoleID])
REFERENCES [dbo].[aspnet_Roles] ([RoleId])
GO
ALTER TABLE [dbo].[PortletAccessList] CHECK CONSTRAINT [FK_PortletAccessList_aspnet_Roles]
GO
ALTER TABLE [dbo].[PortletAccessList]  WITH CHECK ADD  CONSTRAINT [FK_PortletAccessList_Client] FOREIGN KEY([ClientID])
REFERENCES [dbo].[Client] ([ID])
GO
ALTER TABLE [dbo].[PortletAccessList] CHECK CONSTRAINT [FK_PortletAccessList_Client]
GO
ALTER TABLE [dbo].[PortletAccessList]  WITH CHECK ADD  CONSTRAINT [FK_PortletAccessList_ClientType] FOREIGN KEY([ClientTypeID])
REFERENCES [dbo].[ClientType] ([ID])
GO
ALTER TABLE [dbo].[PortletAccessList] CHECK CONSTRAINT [FK_PortletAccessList_ClientType]
GO
ALTER TABLE [dbo].[PortletAccessList]  WITH CHECK ADD  CONSTRAINT [FK_PortletAccessList_ClientUser] FOREIGN KEY([ClientUserID])
REFERENCES [dbo].[ClientUser] ([ID])
GO
ALTER TABLE [dbo].[PortletAccessList] CHECK CONSTRAINT [FK_PortletAccessList_ClientUser]
GO
ALTER TABLE [dbo].[PortletAccessList]  WITH CHECK ADD  CONSTRAINT [FK_PortletAccessList_Portlet] FOREIGN KEY([PortletID])
REFERENCES [dbo].[Portlet] ([ID])
GO
ALTER TABLE [dbo].[PortletAccessList] CHECK CONSTRAINT [FK_PortletAccessList_Portlet]
GO



ALTER TABLE Membership
ALTER COLUMN MembershipNumber nvarchar(100) NULL

ALTER TABLE Member
ALTER COLUMN MemberNumber NVARCHAR(100) NULL
