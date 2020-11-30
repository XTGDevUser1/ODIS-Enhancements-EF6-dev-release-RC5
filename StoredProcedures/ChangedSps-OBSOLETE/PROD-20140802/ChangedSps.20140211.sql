IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Dashboard_DispatchChart]')   		AND type in (N'P', N'PC')) 
BEGIN
 DROP PROCEDURE [dbo].[dms_Dashboard_DispatchChart] 
END 
GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[dms_Dashboard_DispatchChart]
AS
BEGIN
DECLARE @startDate AS DATE = GETDATE() - 365
DECLARE @EndDate AS DATE = GETDATE() 

--====================================================================================================================
-- Service Request Count
--
--
-- 1. Setup Stored Procedure to drive chart.... convert to cross-tab query
-- 2. Setup chart on Dashboard for Dispatch
-- 3. Use line chart
-- 4. Title = Serivce Request Count
-- 5. Vertical Axis = service request counts:  0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000
-- 6. Horizontal Axis = NMC, Ford, Hagerty, Others
-- 7. Show Jan to Dec


-- Line Graph

-- Show monthly totals of call counts by clients

-- Set 

--82559
DECLARE @Result AS TABLE(
Client NVARCHAR(50),
Jan INT,
Feb INT,
Mar INT,
Apr INT,
May INT,
Jun INT,
Jul INT,
Aug INT,
Sep INT,
Oct INT,
Nov INT,
Dec INT
)

INSERT INTO @Result(Client,Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec)

SELECT 
	CASE  
		WHEN cl.Name = 'National Motor Club' AND pp.Name = 'Coach-Net' THEN 'Coach-Net'
		WHEN cl.Name = 'National Motor Club' AND pp.Name <> 'Coach-Net' THEN 'NMC'
		WHEN cl.Name = 'Ford' Then 'Ford'
		WHEN cl.Name = 'Hagerty' Then 'Hagerty'
		ELSE 'Other'
	  END as Client
	--, datepart(mm,sr.CreateDate) AS 'Month'
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = 1 THEN count(sr.id)
	  END,0) AS Jan
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = 2 THEN count(sr.id)
	  END,0) as Feb
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = 3 THEN count(sr.id)
	  END,0) as Mar
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = 4 THEN count(sr.id)
	  END,0) as Apr
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = 5 THEN count(sr.id)
	  END,0) as May
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = 6 THEN count(sr.id)
	  END,0) as Jun
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = 7 THEN count(sr.id)
	  END,0) AS Jul
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = 8 THEN count(sr.id)
	  END,0) as Aug
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = 9 THEN count(sr.id)
	  END,0) as Sep
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = 10 THEN count(sr.id)
	  END,0) as Oct
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = 11 THEN count(sr.id)
	  END,0) as Nov
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = 12 THEN count(sr.id)
	  END,0) as Dec
FROM ServiceRequest sr
JOIN ServiceRequestStatus srs ON srs.ID = sr.ServiceRequestStatusID
JOIN [Case] c ON c.ID = sr.CaseID
JOIN Program p on p.ID = c.ProgramID
JOIN Program pp on pp.ID = p.ParentProgramID
JOIN Client cl on cl.ID = p.ClientID
WHERE
	sr.CreateDate between @StartDate and @EndDate
	AND sr.ServiceRequestStatusID IN (SELECT ID FROM ServiceRequestStatus WHERE Name IN ('Complete','Cancelled'))
GROUP BY
		CASE
		WHEN cl.Name = 'National Motor Club' AND pp.Name = 'Coach-Net' THEN 'Coach-Net'
		WHEN cl.Name = 'National Motor Club' AND pp.Name <> 'Coach-Net' THEN 'NMC'
		WHEN cl.Name = 'Ford' Then 'Ford'
		WHEN cl.Name = 'Hagerty' Then 'Hagerty'
		ELSE 'Other'
	  END
	  , datepart(mm,sr.createdate)
ORDER BY
	CASE
		WHEN cl.Name = 'National Motor Club' AND pp.Name = 'Coach-Net' THEN 'Coach-Net'
		WHEN cl.Name = 'National Motor Club' AND pp.Name <> 'Coach-Net' THEN 'NMC'
		WHEN cl.Name = 'Ford' Then 'Ford'
		WHEN cl.Name = 'Hagerty' Then 'Hagerty'
		ELSE 'Other'
	END 
	, datepart(mm,sr.CreateDate)
	
SELECT Client,
	  SUM(Jan) AS 'Jan',
	  SUM(Feb) AS 'Feb',
	  SUM(Mar) AS 'Mar' ,
	  SUM(Apr) AS 'Apr' ,
	  SUM(May) AS 'May' ,
	  SUM(Jun) AS 'Jun' ,
	  SUM(Jul) AS 'Jul' ,
	  SUM(Aug) AS 'Aug' ,
	  SUM(Sep) AS 'Sep' ,
	  SUM(Oct) AS 'Oct' ,
	  SUM(Nov) AS 'Nov' ,
	  SUM(Dec) AS 'Dec' 
FROM @Result
GROUP BY Client
END

GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Client_OpenPeriodProcess]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Client_OpenPeriodProcess] 
END 
GO
-- EXCE dms_Client_OpenPeriodProcess @billingSchedules = '1,2',@userName = 'demoUser',@sessionID = 'XX12',@pageReference = 'Test'
CREATE PROC [dbo].[dms_Client_OpenPeriodProcess](@billingSchedules NVARCHAR(MAX),@userName NVARCHAR(100),@sessionID NVARCHAR(MAX),@pageReference NVARCHAR(MAX))
AS
BEGIN
		BEGIN TRY
		BEGIN TRAN
			
			DECLARE @BillingScheduleID AS TABLE(RecordID INT IDENTITY(1,1), BillingScheduleID INT)
			DECLARE @BillingInvoiceID AS TABLE(RecordID INT IDENTITY(1,1), BillingInvoiceID INT)
		
			INSERT INTO @BillingScheduleID(BillingScheduleID) SELECT item FROM dbo.fnSplitString(@billingSchedules,',')
			DECLARE @eventLogID AS INT
			DECLARE @scheduleID AS INT
			DECLARE @ProcessingCounter AS INT = 1
			DECLARE @TotalRows AS INT
			SELECT  @TotalRows = MAX(RecordID) FROM @BillingScheduleID
	
			DECLARE @entityID AS INT 
			DECLARE @eventID AS INT
			DECLARE	@eventDescription AS NVARCHAR(MAX)
			SELECT  @entityID = ID FROM Entity WHERE Name = 'BillingInvoice'
			SELECT  @eventID =  ID FROM Event WHERE Name = 'OpenPeriod'
			SELECT  @eventDescription =  Description FROM Event WHERE Name = 'OpenPeriod'

			-- Create Master Event Log 
				INSERT INTO EventLog([EventID],				[SessionID],				[Source],			[Description],
									 [Data],				[NotificationQueueDate],	[CreateBy],			[CreateDate]) 
				VALUES				(@eventID,				@sessionID,					@pageReference,	   @eventDescription,
									NULL,					NULL,						@userName,			GETDATE())
				SET @eventLogID  =  SCOPE_IDENTITY()

			WHILE @ProcessingCounter <= @TotalRows
			BEGIN
				
				DECLARE @BillingDefinitionInvoiceID AS TABLE(BillingDefinitionInvoiceID INT NOT NULL)
				
				SET @scheduleID = (SELECT BillingScheduleID FROM @BillingScheduleID WHERE RecordID = @ProcessingCounter)
				-- Write Process Logic for Schedule ID
				DECLARE @pScheduleTypeID AS INT,
						@pScheduledDateTypeID AS INT,
						@pScheduleRangeTypeID AS INT;
				DECLARE @pInvoiceXML AS NVARCHAR(MAX)
			
				SELECT  @pScheduleTypeID = ScheduleTypeID,
						@pScheduledDateTypeID = ScheduleDateTypeID,
						@pScheduleRangeTypeID = ScheduleRangeTypeID
				FROM    BillingSchedule
				WHERE   ID = @scheduleID

				--SELECT * FROM BillingSchedule
				INSERT INTO @BillingDefinitionInvoiceID 
				SELECT		ID
				FROM        BillingDefinitionInvoice
				WHERE       IsActive = 1
				AND         ScheduleTypeID = @pScheduleTypeID
				AND         ScheduleDateTypeID = @pScheduledDateTypeID
				AND         ScheduleRangeTypeID = @pScheduleRangeTypeID

				SELECT	    @pInvoiceXML = [dbo].[fnConcatenate](ID)
				FROM        BillingDefinitionInvoice
				WHERE       IsActive = 1
				AND         ScheduleTypeID = @pScheduleTypeID
				AND         ScheduleDateTypeID = @pScheduledDateTypeID
				AND         ScheduleRangeTypeID = @pScheduleRangeTypeID
			
				SET @pInvoiceXML = '<Records><BillingDefinitionInvoiceID>' + REPLACE(@pInvoiceXML,',','</BillingDefinitionInvoiceID><BillingDefinitionInvoiceID>') + '</BillingDefinitionInvoiceID></Records>'

				EXEC dbo.dms_BillingGenerateInvoices 
					@pUserName  = @userName,
					@pScheduleTypeID = @pScheduleTypeID,
					@pScheduleDateTypeID = @pScheduledDateTypeID,
					@pScheduleRangeTypeID = @pScheduleRangeTypeID,
					@pInvoicesXML = @pInvoiceXML

				-- Create Event Logs Reocords
				INSERT INTO EventLog([EventID],				[SessionID],				[Source],			[Description],
									 [Data],				[NotificationQueueDate],	[CreateBy],			[CreateDate]) 
				VALUES				(@eventID,				@sessionID,					@pageReference,	   @eventDescription,
									NULL,					NULL,						@userName,			GETDATE())
			
				-- CREATE Link Records
				INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) VALUES(SCOPE_IDENTITY(),@entityID,@scheduleID)

				INSERT INTO @BillingInvoiceID(BillingInvoiceID) SELECT ID FROM BillingInvoice WHERE BillingDefinitionInvoiceID IN (SELECT BillingDefinitionInvoiceID FROM @BillingDefinitionInvoiceID)
				
				SET @ProcessingCounter = @ProcessingCounter + 1
			END

			SET   @ProcessingCounter = 1
			SET   @TotalRows = (SELECT MAX(RecordID) FROM @BillingInvoiceID)

			WHILE @ProcessingCounter <= @TotalRows
			BEGIN
				INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) VALUES(@eventLogID,@entityID,(SELECT BillingInvoiceID FROM @BillingInvoiceID WHERE RecordID = @ProcessingCounter))
				SET @ProcessingCounter = @ProcessingCounter + 1
			END


		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		DECLARE @ErrorMessage    NVARCHAR(4000)			
		-- Assign variables to error-handling functions that 
		-- capture information for RAISERROR.
		SELECT  @ErrorMessage = ERROR_MESSAGE();
		RAISERROR(@ErrorMessage,16,1);
	END CATCH
END

GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_DashboardServiceRequestCount]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_DashboardServiceRequestCount] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
CREATE PROC dms_DashboardServiceRequestCount
AS
BEGIN
DECLARE @StartDate DATE = GETDATE() - 365
DECLARE @EndDate DATE = GETDATE()

DECLARE @result TABLE(
	StatusID INT,
	Sequence INT,
	Name NVARCHAR(50) ,
	SRCount INT,
	StartDate DATE,
	EndDate DATE
)

INSERT INTO @result(StatusID,Sequence,Name,SRCount,StartDate,EndDate)
SELECT SRS.ID,
		CASE
		WHEN SRS.Name = 'Entry' THEN 1
		WHEN SRS.Name = 'Submitted' THEN 2
		WHEN SRS.Name = 'Dispatched' THEN 3
		WHEN SRS.Name = 'Cancelled' THEN 4
		WHEN SRS.Name = 'Completed' THEN 5
		ELSE 5
	END as Sequence,
	SRS.Name,
	0,
	@StartDate,@EndDate FROM ServiceRequestStatus SRS

;with wResult AS(
	SELECT 
	SRS.ID AS 'SRStatusID',
	COUNT(*) AS 'SRCount'
	FROM ServiceRequest SR
	JOIN ServiceRequestStatus SRS ON SR.ServiceRequestStatusID = SRS.ID
	WHERE SR.CreateDate BETWEEN @StartDate AND @EndDate
	GROUP BY SRS.ID
)

UPDATE	@result 
SET		SRCount = WR.SRCount 
FROM	@result R
JOIN	wResult WR ON R.StatusID = WR.	SRStatusID

SELECT * FROM @result ORDER BY Sequence

END
GO