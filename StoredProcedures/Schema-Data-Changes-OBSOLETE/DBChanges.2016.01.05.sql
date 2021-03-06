/****** Object:  Table [dbo].[ClientRep]    Script Date: 1/5/2016 1:43:05 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ClientRep](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[FirstName] [nvarchar](100) NULL,
	[LastName] [nvarchar](100) NULL,
	[Title] [nvarchar](100) NULL,
	[Email] [nvarchar](255) NULL,
	[PhoneNumber] [nvarchar](100) NULL,
	[IsActive] [bit] NULL,
	[CreateDate] [datetime] NULL,
	[CreateBy] [nvarchar](100) NULL,
	[ModifyDate] [datetime] NULL,
	[ModifyBy] [nvarchar](100) NULL,
 CONSTRAINT [PK_ClientRep] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE Client ADD ClientRepID INT NULL

ALTER TABLE [dbo].[Client]  WITH CHECK ADD  CONSTRAINT [FK_Client_ClientRep] FOREIGN KEY([ClientRepID])
REFERENCES [dbo].[ClientRep] ([ID])
GO
ALTER TABLE [dbo].[Client] CHECK CONSTRAINT [FK_Client_ClientRep]
GO

