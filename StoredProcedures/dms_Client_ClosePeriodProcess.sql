IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Client_ClosePeriodProcess]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Client_ClosePeriodProcess] 
END 
GO
-- EXCE dms_Client_ClosePeriodProcess @billingSchedules = '1,2',@userName = 'demoUser',@sessionID = 'XX12',@pageReference = 'Test'
CREATE PROC [dbo].[dms_Client_ClosePeriodProcess](@billingSchedules NVARCHAR(MAX),@userName NVARCHAR(100),@sessionID NVARCHAR(MAX),@pageReference NVARCHAR(MAX))
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN
			
			DECLARE @BillingScheduleID AS TABLE(RecordID INT IDENTITY(1,1), BillingScheduleID INT)
			INSERT INTO @BillingScheduleID(BillingScheduleID) SELECT item FROM dbo.fnSplitString(@billingSchedules,',')
	
			DECLARE @scheduleID AS INT
			DECLARE @ProcessingCounter AS INT = 1
			DECLARE @TotalRows AS INT
			SELECT  @TotalRows = MAX(RecordID) FROM @BillingScheduleID
	
			DECLARE @entityID AS INT 
			DECLARE @eventID AS INT
			DECLARE	@eventDescription AS NVARCHAR(MAX)
			SELECT  @entityID = ID FROM Entity WHERE Name = 'BillingSchedule'
			SELECT  @eventID =  ID FROM Event WHERE Name = 'ClosePeriod'
			SELECT  @eventDescription =  Description FROM Event WHERE Name = 'ClosePeriod'
	

			DECLARE	@BillingScheduleStatusID_CLOSED AS INT
			SELECT	@BillingScheduleStatusID_CLOSED = ID FROM BillingScheduleStatus WHERE Name = 'CLOSED'
	
			WHILE @ProcessingCounter <= @TotalRows
			BEGIN
			SET @scheduleID = (SELECT BillingScheduleID FROM @BillingScheduleID WHERE RecordID = @ProcessingCounter)
			
			-- Set BillingSchedule to Closed
			UPDATE	dbo.BillingSchedule
			SET		ScheduleStatusID = @BillingScheduleStatusID_CLOSED
					, ModifyBy = @userName
					, ModifyDate = GETDATE()
					, IsActive = 0
			WHERE	ID = @scheduleID
			
			
			-- Open New Period
			DECLARE  @Now AS DATETIME
			DECLARE  @BillingScheduleStatusID_PENDING AS INT,
					 @BillingScheduleTypeID_MONTHLY AS INT,
					 @BillingScheduleTypeID_WEEKLY AS INT,
					 @BillingScheduleRangeTypeID_PREVIOUS_MO AS INT,
					 @BillingScheduleRangeTypeID_PREVIOUS_WK AS INT,
					 @BillingScheduleDateTypeID_FIRST_DAY_OF_MO AS INT,
					 @BillingScheduleDateTypeID_MONDAY AS INT

			SELECT   @Now = GETDATE()
			SELECT   @BillingScheduleStatusID_PENDING = ID FROM BillingScheduleStatus WHERE Name = 'PENDING'
			SELECT   @BillingScheduleTypeID_MONTHLY = ID FROM BillingScheduleType WHERE Name = 'MONTHLY'
			SELECT   @BillingScheduleTypeID_WEEKLY = ID FROM BillingScheduleType WHERE Name = 'WEEKLY'
			SELECT   @BillingScheduleRangeTypeID_PREVIOUS_MO = ID FROM BillingScheduleRangeType WHERE Name = 'PREVIOUS_MO'
			SELECT   @BillingScheduleRangeTypeID_PREVIOUS_WK = ID FROM BillingScheduleRangeType WHERE Name = 'PREVIOUS_WK'
			SELECT   @BillingScheduleDateTypeID_FIRST_DAY_OF_MO = ID FROM BillingScheduleDateType WHERE Name = 'FIRST_DAY_OF_MO'
			SELECT   @BillingScheduleDateTypeID_MONDAY = ID FROM BillingScheduleDateType WHERE Name = 'MONDAY'

			DECLARE  @Name as nvarchar(50),
					 @Description as nvarchar(50),
					 @ScheduleDateTypeID as int,
					 @ScheduleRangeTypeID as int,
					 @ScheduleDate_CURR as datetime,
					 @ScheduleRangeBegin_CURR as datetime,
					 @ScheduleRangeEnd_CURR as datetime,
					 @ScheduleTypeID as int,
					 @ScheduleStatusID as int,
					 @ScheduleDate_NEW as datetime,
					 @ScheduleRangeBegin_NEW as datetime,
					 @ScheduleRangeEnd_NEW as datetime

			SET     @ScheduleStatusID = @BillingScheduleStatusID_PENDING -- PENDING
 
			-- Inherit columns from record getting closed 
			SELECT   @Name = Name,
					 @Description  = [Description],
					 @ScheduleDateTypeID = ScheduleDateTypeID,
					 @ScheduleRangeTypeID = ScheduleRangeTypeID,
					 @ScheduleDate_CURR = ScheduleDate,
					 @ScheduleRangeBegin_CURR = ScheduleRangeBegin,
					 @ScheduleRangeEnd_CURR = ScheduleRangeEnd,
					 @ScheduleTypeID = ScheduleTypeID
			FROM     dbo.BillingSchedule
			WHERE    ID = @scheduleID

			-- Monthly / Previous Month / First Day Of Month 
			-------------------------------------------------
			IF       @ScheduleDateTypeID = @BillingScheduleTypeID_MONTHLY
			AND      @ScheduleRangeTypeID = @BillingScheduleRangeTypeID_PREVIOUS_MO
			AND      @ScheduleDateTypeID = @BillingScheduleDateTypeID_FIRST_DAY_OF_MO
			BEGIN
 
			   SELECT      @ScheduleDate_NEW = DATEADD(mm, 1, @ScheduleDate_CURR) -- Advance 1 month
			   SELECT      @ScheduleRangeBegin_NEW = @ScheduleDate_CURR -- Set to the Curr Sched date
			   SELECT      @ScheduleRangeEnd_NEW = DATEADD(dd, -1, @ScheduleDate_NEW) -- 1 day Less than New Scheduled date
 
			END
 
			-- Weekly / Previous Week / Monday
			-------------------------------------------------
			IF		 @ScheduleDateTypeID = @BillingScheduleTypeID_WEEKLY
			AND      @ScheduleRangeTypeID = @BillingScheduleRangeTypeID_PREVIOUS_WK
			AND      @ScheduleDateTypeID = @BillingScheduleDateTypeID_MONDAY
			BEGIN
 
			   SELECT      @ScheduleDate_NEW = dateadd(dd, 7, @ScheduleDate_CURR) -- Advance 7 days
			   SELECT      @ScheduleRangeBegin_NEW = @ScheduleDate_CURR -- Set to the Curr Sched date
			   SELECT      @ScheduleRangeEnd_NEW = dateadd(dd, -1, @ScheduleDate_NEW) -- 1 day Less than New Scheduled date
 
			END
 
			INSERT INTO dbo.BillingSchedule(Name,			  [Description],			ScheduleDateTypeID,				ScheduleRangeTypeID,
											ScheduleDate,     ScheduleRangeBegin,		ScheduleRangeEnd,				ScheduleTypeID,
											ScheduleStatusID, Sequence,					IsActive,						CreateDate,
											CreateBy,		  ModifyDate,				ModifyBy)
 
			SELECT							@Name, -- Name
											@Description, -- [Description]
										    @ScheduleDateTypeID, -- ScheduleDateTypeID
											@ScheduleRangeTypeID,-- ScheduleRangeTypeID
											@ScheduleDate_NEW, -- ScheduleDate
											@ScheduleRangeBegin_NEW, -- ScheduleRangeBegin
											@ScheduleRangeEnd_NEW, -- ScheduleRangeEnd
											@ScheduleTypeID, -- ScheduleTypeID
											@ScheduleStatusID, -- ScheduleStatusID
											0, -- Sequence
											1, -- IsActive
											@Now, -- CreateDate
											@userName, -- CreateBy
											null, -- ModifyDate
											null -- ModifyBy	

			-- Create Event Logs Reocords
			INSERT INTO EventLog([EventID],				[SessionID],				[Source],			[Description],
								 [Data],				[NotificationQueueDate],	[CreateBy],			[CreateDate]) 
			VALUES				(@eventID,				@sessionID,					@pageReference,		@eventDescription,
								 NULL,					NULL,						@userName,			GETDATE())
			-- CREATE Link Records
			INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) VALUES(SCOPE_IDENTITY(),@entityID,@scheduleID)
			
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

