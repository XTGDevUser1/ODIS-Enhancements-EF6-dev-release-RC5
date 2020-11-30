IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ReQueueFaxFailures]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_ReQueueFaxFailures]
GO

USE [DMS]
GO

/****** Object:  StoredProcedure [dbo].[dms_ReQueueFaxFailures]    Script Date: 10/15/2014 16:51:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[dms_ReQueueFaxFailures]
	@StartDate datetime
AS
BEGIN

	--DECLARE @StartDate datetime
	--SET @StartDate = '10/13/2014 09:00'

	INSERT INTO [DMS].[dbo].[CommunicationQueue]
	           ([ContactLogID]
	           ,[ContactMethodID]
	           ,[TemplateID]
	           ,[MessageData]
	           ,[Subject]
	           ,[MessageText]
	           ,[Attempts]
	           ,[ScheduledDate]
	           ,[CreateDate]
	           ,[CreateBy]
	           ,EventLogID
	           ,NotificationRecipient)
	SELECT [ContactLogID]
		  ,[ContactMethodID]
		  ,[TemplateID]
		  ,[Subject]
		  ,[Subject]
		  ,[MessageText]
		  ,0
		  ,getdate()
		  ,[CreateDate]
		  ,[CreateBy]
		  ,[EventLogID]
		  ,[NotificationRecipient]
	FROM [DMS].[dbo].[CommunicationLog]
	where createdate > @StartDate 
	and ContactMethodID = (SELECT ID FROM ContactMethod WHERE Name = 'Fax')
	and status = 'FAILURE' 
	and Comments like '%Unknown error%'
	order by CreateDate desc

END



GO


