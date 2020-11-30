SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MemberProgramChangeMapping]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[MemberProgramChangeMapping](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[FromProgramID] [int] NOT NULL,
	[ToProgramID] [int] NOT NULL,
	[CreateDate] [datetime] NULL,
	[CreateBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_MemberProgramChangeMapping] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MemberProgramChangeMapping_Program]') AND parent_object_id = OBJECT_ID(N'[dbo].[MemberProgramChangeMapping]'))
ALTER TABLE [dbo].[MemberProgramChangeMapping]  WITH CHECK ADD  CONSTRAINT [FK_MemberProgramChangeMapping_Program] FOREIGN KEY([FromProgramID])
REFERENCES [dbo].[Program] ([ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MemberProgramChangeMapping_Program]') AND parent_object_id = OBJECT_ID(N'[dbo].[MemberProgramChangeMapping]'))
ALTER TABLE [dbo].[MemberProgramChangeMapping] CHECK CONSTRAINT [FK_MemberProgramChangeMapping_Program]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MemberProgramChangeMapping_Program1]') AND parent_object_id = OBJECT_ID(N'[dbo].[MemberProgramChangeMapping]'))
ALTER TABLE [dbo].[MemberProgramChangeMapping]  WITH CHECK ADD  CONSTRAINT [FK_MemberProgramChangeMapping_Program1] FOREIGN KEY([ToProgramID])
REFERENCES [dbo].[Program] ([ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MemberProgramChangeMapping_Program1]') AND parent_object_id = OBJECT_ID(N'[dbo].[MemberProgramChangeMapping]'))
ALTER TABLE [dbo].[MemberProgramChangeMapping] CHECK CONSTRAINT [FK_MemberProgramChangeMapping_Program1]
GO


IF NOT EXISTS (SELECT * FROM ProgramConfiguration where Name='AllowMemberNameChange' AND  ProgramID = (SELECT ID FROM Program where Name='NMC') AND ConfigurationTypeID=(SELECT ID FROM ConfigurationType where Name = 'Application') AND ConfigurationCategoryID =(SELECT ID FROM ConfigurationCategory where Name = 'Rule') )
BEGIN
	INSERT INTO ProgramConfiguration VALUES(
		(SELECT ID FROM Program where Name='NMC'),
		(SELECT ID FROM ConfigurationType where Name = 'Application'),
		(SELECT ID FROM ConfigurationCategory where Name = 'Rule'),
		NULL,
		NULL,
		'AllowMemberNameChange',
		'Yes',
		1,
		1,
		GETDATE(),
		'sysadmin',
		NULL,
		NULL
	)
END
IF NOT EXISTS (SELECT * FROM ProgramConfiguration where Name='AllowMemberNameChange' AND ProgramID = (SELECT ID FROM Program where Name='FORD') AND ConfigurationTypeID=(SELECT ID FROM ConfigurationType where Name = 'Application') AND ConfigurationCategoryID =(SELECT ID FROM ConfigurationCategory where Name = 'Rule') )
BEGIN
	INSERT INTO ProgramConfiguration VALUES(
		(SELECT ID FROM Program where Name='FORD'),
		(SELECT ID FROM ConfigurationType where Name = 'Application'),
		(SELECT ID FROM ConfigurationCategory where Name = 'Rule'),
		NULL,
		NULL,
		'AllowMemberNameChange',
		'Yes',
		1,
		1,
		GETDATE(),
		'sysadmin',
		NULL,
		NULL
	)
END

IF NOT EXISTS (SELECT * FROM [Event] where Name = 'ChangeMemberName')
BEGIN
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'ChangeMemberName',
		'Change Member Name',
		1,
		1,
		'system',
		GETDATE()
	)
END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration where Name='AllowMemberProgramChange' AND  ProgramID = (SELECT ID FROM Program where Name='NMC') AND ConfigurationTypeID=(SELECT ID FROM ConfigurationType where Name = 'Application') AND ConfigurationCategoryID =(SELECT ID FROM ConfigurationCategory where Name = 'Rule') )
BEGIN
	INSERT INTO ProgramConfiguration VALUES(
		(SELECT ID FROM Program where Name='NMC'),
		(SELECT ID FROM ConfigurationType where Name = 'Application'),
		(SELECT ID FROM ConfigurationCategory where Name = 'Rule'),
		NULL,
		NULL,
		'AllowMemberProgramChange',
		'Yes',
		1,
		1,
		GETDATE(),
		'sysadmin',
		NULL,
		NULL
	)
END
IF NOT EXISTS (SELECT * FROM ProgramConfiguration where Name='AllowMemberProgramChange' AND ProgramID = (SELECT ID FROM Program where Name='FORD') AND ConfigurationTypeID=(SELECT ID FROM ConfigurationType where Name = 'Application') AND ConfigurationCategoryID =(SELECT ID FROM ConfigurationCategory where Name = 'Rule') )
BEGIN
	INSERT INTO ProgramConfiguration VALUES(
		(SELECT ID FROM Program where Name='FORD'),
		(SELECT ID FROM ConfigurationType where Name = 'Application'),
		(SELECT ID FROM ConfigurationCategory where Name = 'Rule'),
		NULL,
		NULL,
		'AllowMemberProgramChange',
		'Yes',
		1,
		1,
		GETDATE(),
		'sysadmin',
		NULL,
		NULL
	)
END

IF NOT EXISTS (SELECT * FROM [Event] where Name = 'ChangeMemberProgram')
BEGIN
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'ChangeMemberProgram',
		'Change Member Program',
		1,
		1,
		'system',
		GETDATE()
	)
END
