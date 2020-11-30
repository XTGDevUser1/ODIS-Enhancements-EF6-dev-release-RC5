-- Sanghi Removes these Columns From Vendor and Added to VendorACH
ALTER TABLE Vendor
DROP COLUMN IsACHActive

ALTER TABLE Vendor
DROP COLUMN ACHSignedByName

ALTER TABLE Vendor
DROP COLUMN ACHSignedByTitle

ALTER TABLE Vendor
DROP COLUMN ACHSignedByDate

-- ADD NEW COLUMNS TO VENDOR ACH
ALTER TABLE VendorACH
ADD IsACHActive BIT NULL

ALTER TABLE VendorACH
ADD ACHSignedByName NVARCHAR(50) NULL

ALTER TABLE VendorACH
ADD ACHSignedByTitle NVARCHAR(50) NULL

ALTER TABLE VendorACH
ADD ACHSignedByDate DATETIME NULL

--Document Module related scripts
CREATE TABLE [dbo].[DocumentCategory](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Description] [nvarchar](255) NULL,
	[Sequence] INT NULL,
	[IsActive] bit NULL,
 CONSTRAINT [PK_DocumentCategory] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

CREATE TABLE [dbo].[DocumentType](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Description] [nvarchar](255) NULL,
	[Extension] [nvarchar](50) NULL,
	[Sequence] INT NULL,
	[IsActive] bit NULL,
 CONSTRAINT [PK_DocumentType] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

CREATE TABLE [dbo].[Document](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[EntityID] [int] NULL,
	[RecordID] [int] NULL,
	[DocumentCategoryID] [int] NULL,
	[DocumentTypeID] [int] NULL,
	[Name] [nvarchar](255) NULL,
	[DocumentFile] varbinary(max) NULL,
	[Comment] [nvarchar](255) NULL,
	[CreateDate] [datetime] NULL,
	[CreateBy] [nvarchar](50) NULL,
CONSTRAINT [PK_Document] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[Document]  WITH CHECK ADD  CONSTRAINT [FK_Document_Entity] FOREIGN KEY([EntityID])
REFERENCES [dbo].[Entity] ([ID])
GO

ALTER TABLE [dbo].[Document] CHECK CONSTRAINT [FK_Document_Entity]
GO

--Inser data Document category
IF NOT EXISTS(SELECT * FROM DocumentCategory WHERE Name = 'Application')
BEGIN
INSERT INTO [DocumentCategory]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('Application', 'Application', 1, 1)

END

IF NOT EXISTS(SELECT * FROM DocumentCategory WHERE Name = 'Contract')
BEGIN
INSERT INTO [DocumentCategory]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('Contract', 'Contract', 3, 1)
END

IF NOT EXISTS(SELECT * FROM DocumentCategory WHERE Name = 'VendorInvoice')
BEGIN
INSERT INTO [DocumentCategory]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('VendorInvoice', 'Vendor Invoice', 4, 1)
END

IF NOT EXISTS(SELECT * FROM DocumentCategory WHERE Name = 'Claim')
BEGIN
INSERT INTO [DocumentCategory]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('Claim', 'Claim', 2, 1)
END

--Insert into DocumentType
IF NOT EXISTS(SELECT * FROM DocumentType WHERE Name = 'Excel')
BEGIN
INSERT INTO [DocumentType]
           ([Name]
           ,[Description]
           ,[Extension]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('Excel', 'Excel', '.xlsx', 0, 1)
END

IF NOT EXISTS(SELECT * FROM DocumentType WHERE Name = 'Word')
BEGIN
INSERT INTO [DocumentType]
           ([Name]
           ,[Description]
           ,[Extension]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('Word', 'Word', '.docx', 0, 1)
END

IF NOT EXISTS(SELECT * FROM DocumentType WHERE Name = 'PDF')
BEGIN
INSERT INTO [DocumentType]
           ([Name]
           ,[Description]
           ,[Extension]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('PDF', 'PDF', '.pdf', 0, 1)
END

--Event table record inserts
DECLARE @EventCategoryID INT = (SELECT ID FROM EventCategory WHERE Name = 'Vendor')

IF NOT EXISTS(SELECT * FROM Event WHERE Name = 'UploadDocument')
BEGIN
INSERT INTO [Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES
           (2, @EventCategoryID, 'UploadDocument', 'Upload document', 0, 1, NULL, NULL)

END

IF NOT EXISTS(SELECT * FROM Event WHERE Name = 'DeleteDocument')
BEGIN
INSERT INTO [Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES
           (2, @EventCategoryID, 'DeleteDocument', 'Delete document', 0, 1, NULL, NULL)

END


INSERT INTO [Event] VALUES (2,(Select ID From EventCategory where Name='Membership'),'OpenedMembershipNote','Opened Membership Note',1,1,'System',CURRENT_TIMESTAMP)