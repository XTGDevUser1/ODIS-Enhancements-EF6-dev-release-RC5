
INSERT INTO ClaimStatus([Name],[Description],[Sequence],[IsActive])VALUES('Exception', 'Exception', 0, 1)

--Claim Exception
CREATE TABLE [dbo].[ClaimException](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ClaimID] [int] NULL,
	[Description] [nvarchar](255) NULL,
	[CreateDate] [datetime] NULL,
	[CreateBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_ClaimException] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'TagClaimReadyForPayment')
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
           ((SELECT ID FROM EventType WHERE Name = 'User'), 
			(SELECT ID FROM EventCategory WHERE Name = 'Claim'), 
			'TagClaimReadyForPayment', 'Tag claims ready for payment', 1, 1, NULL, NULL)
END

--PHANI
ALTER TABLE ContactCategory
ADD IsShownOnActivity  bit null
GO

Update ContactCategory set IsShownOnActivity =1 where Name IN('VendorManagement','VendorInvoice','Claim','VendorPortal','ContactCustomer','ContactVendor','VendorCallback')

--Pavan for Feedback email vendor default value
IF NOT Exists(SELECT * FROM ApplicationConfiguration WHERE Name='VendorPortalDefaultFeedbackEmail')
BEGIN
INSERT INTO [ApplicationConfiguration]
([ApplicationConfigurationTypeID]
,[ApplicationConfigurationCategoryID]
,[ControlTypeID]
,[DataTypeID]
,[Name]
,[Value]
,[CreateDate]
,[CreateBy]
,[ModifyDate]
,[ModifyBy])
VALUES
(1, 11, NULL, NULL, 'VendorPortalDefaultFeedbackEmail', 'vendorsupport@nmc.com', NULL, NULL, NULL, NULL)
END


	