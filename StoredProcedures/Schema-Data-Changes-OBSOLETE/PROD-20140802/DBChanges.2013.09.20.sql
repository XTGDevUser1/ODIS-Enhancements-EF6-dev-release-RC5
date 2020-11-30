--PHANI
/*Feedback*/
ALTER TABLE FEEDBACK
ADD [SourceSystemID] [int] NULL
GO

ALTER TABLE [dbo].[Feedback]  WITH CHECK ADD  CONSTRAINT [FK_Feedback_SourceSystem] FOREIGN KEY([SourceSystemID])
REFERENCES [dbo].[SourceSystem] ([ID])
GO

ALTER TABLE [dbo].[Feedback] CHECK CONSTRAINT [FK_Feedback_SourceSystem]
GO

/*FeedbackType*/
ALTER TABLE FEEDBACKTYPE
ADD IsShownOnVendorPortal bit null
GO

--Check whether present or not
INSERT INTO FeedbackType VALUES('ISPUpdates','ISPUpdates','rustyh@martexsoftware.com;rhancock817@gmail.com',5,1,0)

UPDATE FEEDBACKTYPE SET IsShownOnVendorPortal=1 where Name='Problem'
UPDATE FEEDBACKTYPE SET IsShownOnVendorPortal=1 where Name='Suggestion'
UPDATE FEEDBACKTYPE SET IsShownOnVendorPortal=1 where Name='Comment'
UPDATE FEEDBACKTYPE SET IsShownOnVendorPortal=1 where Name='Other'
UPDATE FEEDBACKTYPE SET IsShownOnVendorPortal=0 where Name='ISPUpdates'



--For Vendor Portal
INSERT INTO ApplicationConfiguration(ApplicationConfigurationTypeID,Name,Value) VALUES(1,'VendorPortalACHVoidedCheckPath','/VoidedCheck')
