/****** Object:  Table [dbo].[ClientType]    Script Date: 12/15/2015 12:32:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ClientType](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Description] [nvarchar](255) NULL,
	[Sequence] [int] NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_ClientType] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [Client]
ADD ClientTypeID INT NULL 

ALTER TABLE [Client]
ADD Website nvarchar(max) NULL 

ALTER TABLE [Client]
ADD MainContactFirstName nvarchar(256) NULL 

ALTER TABLE [Client]
ADD MainContactLastName nvarchar(256) NULL 

ALTER TABLE [Client]
ADD MainContactPhone nvarchar(50) NULL 

ALTER TABLE [Client]
ADD MainContactEmail nvarchar(255) NULL 


ALTER TABLE [dbo].[Client]  WITH CHECK ADD  CONSTRAINT [FK_Client_ClientType] FOREIGN KEY([ClientTypeID])
REFERENCES [dbo].[ClientType] ([ID])
GO
ALTER TABLE [dbo].[Client] CHECK CONSTRAINT [FK_Client_ClientType]
GO

ALTER TABLE Document
ADD IsShownOnClientPortal BIT NULL

