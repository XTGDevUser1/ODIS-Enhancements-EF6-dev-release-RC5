IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnServiceRequestEfforts]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnServiceRequestEfforts]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE function [dbo].[fnServiceRequestEfforts](@ServiceRequestID AS INT) RETURNS @AttempsResult TABLE(
								ID INT PRIMARY KEY NOT NULl IDENTITY(1,1),
							    RankID INT,
							    UserName NVARCHAR(50),
								EffortInSeconds NUMERIC(18,2),
								WaitingTimeInQueue NUMERIC(18,2))
BEGIN
DECLARE @Result AS TABLE(EventLogID INT,
						 EventID INT,
						 SessionID NVARCHAR(100),
						 PageSource NVARCHAR(MAX),
						 [Description] NVARCHAR(MAX),
						 CreateDate DATETIME,
						 CreateBy NVARCHAR(50))

DECLARE @FinalResult AS TABLE(ID INT PRIMARY KEY NOT NULl IDENTITY(1,1),
						 EventLogID INT,
						 EventID INT,
						 SessionID NVARCHAR(100),
						 PageSource NVARCHAR(MAX),
						 [Description] NVARCHAR(MAX),
						 CreateDate DATETIME,
						 CreateBy NVARCHAR(50),
						 Ranking INT NULL,
						 IsKeyRecord BIT NULL,
						 IsValidRecord BIT NULL,
						 TabTimeDifference NUMERIC(18,2) NULL)

-- Filters for Events and Keys to Create Group as Entry Point
DECLARE @Keys AS TABLE (EventID INT)
DECLARE @EventFilters AS TABLE (ID INT NOT NULL IDENTITY(1,1),EventID INT,IsKey BIT NOT NULL,IsEnter BIT NULL)

INSERT INTO @Keys VALUES((SELECT ID FROM Event WHERE Name  = 'StartServiceRequest'))
INSERT INTO @Keys VALUES((SELECT ID FROM Event WHERE Name  = 'OpenServiceRequest'))
INSERT INTO @Keys VALUES((SELECT ID FROM Event WHERE Name  = 'OpenActiveRequest'))

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'StartServiceRequest'),1,NULL)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'OpenServiceRequest'),1,NULL)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'OpenActiveRequest'),1,NULL)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterStartTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveStartTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterEmergencyTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveEmergencyTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterMemberTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveMemberTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterVehicleTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveVehicleTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterServiceTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveServiceTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterMapTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveMapTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterDispatchTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveDispatchTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterPOTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeavePOTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterPaymentTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeavePaymentTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterActivityTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveActivityTab'),0,0)

INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'EnterFinishTab'),0,1)
INSERT INTO @EventFilters VALUES((SELECT ID FROM Event WHERE Name  = 'LeaveFinishTab'),0,0)

-- INSERT LOGS FOR Service Request Considering RecordID for Entity SR
INSERT INTO @Result
SELECT EL.ID,
	   El.EventID,
	   EL.SessionID,
	   El.Source,
	   EL.Description,
	   EL.CreateDate,
	   EL.CreateBy	   
FROM EventLog EL
LEFT JOIN EventLogLink ELL ON EL.ID = ELL.EventLogID
WHERE ELL.EntityID =  (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
AND ELL.RecordID = @ServiceRequestID
AND EL.EventID IN (SELECT EventID FROM @EventFilters)

-- --INSERT LOGS FOR Case Considering RecordID for Entity Case
--INSERT INTO @Result
--SELECT EL.ID,
--	   El.EventID,
--	   EL.SessionID,
--	   El.Source,
--	   EL.Description,
--	   EL.CreateDate,
--	   EL.CreateBy	   
--FROM EventLog EL
--LEFT JOIN EventLogLink ELL ON EL.ID = ELL.EventLogID
--WHERE ELL.EntityID = (SELECT ID FROM Entity WHERE Name = 'Case')
--AND ELL.RecordID = (SELECT CaseID FROM ServiceRequest WHERE ID = @ServiceRequestID)
--AND EL.EventID IN (SELECT EventID FROM @EventFilters)

--- Filters Record Based On Create Date
INSERT INTO @FinalResult(EventLogID,EventID,SessionID,PageSource,[Description],CreateDate,CreateBy)
SELECT * FROM @Result ORDER BY EventLogID ASC

-- Insert Total As Dummy Later Will Update
INSERT INTO @AttempsResult VALUES(0,'Total',0,0)

----------logic #2
declare @counter int = 1
declare @val int = 1
declare @otherval int = 1
declare @eventID INT

-- Ranking Logic to Create Groups Known As Rank
WHILE @counter <= (SELECT COUNT(*) FROM @FinalResult)
BEGIN
	SELECT @eventID = EventID 
	FROM @FinalResult
	WHERE ID = @counter

	IF @eventID in (SELECT EventID FROM @Keys)
	BEGIN
		UPDATE @FinalResult SET Ranking = @val,IsKeyRecord = 1 WHERE ID = @counter
		SET @otherval = @val
		SET @val=@val+1
	END
	
	ELSE
	 BEGIN
	 UPDATE @FinalResult SET Ranking = @otherval,IsKeyRecord = 0 WHERE ID = @counter
	END
SET @counter = @counter + 1
END

-- Ranking Logic to update Valid Ranks
DECLARE @validRecordRank INT = 1
WHILE @validRecordRank <= (SELECT MAX(Ranking) FROM @FinalResult)
BEGIN
	 IF (SELECT COUNT(*) FROM @FinalResult WHERE Ranking  =  @validRecordRank) > 1
	 BEGIN
		UPDATE @FinalResult SET IsValidRecord = 1 WHERE Ranking  =  @validRecordRank
	 END
	 ELSE
	 BEGIN
		UPDATE @FinalResult SET IsValidRecord = 0 WHERE Ranking  =  @validRecordRank
	 END
	 SET @validRecordRank= @validRecordRank + 1
END


DECLARE @rankForTabTime AS INT
SET     @rankForTabTime = 1
WHILE   @rankForTabTime <= (SELECT Max(Ranking) FROM @FinalResult)
BEGIN
	 
	INSERT INTO @AttempsResult(RankID,UserName,EffortInSeconds) SELECT Ranking,CreateBy,0 FROM @FinalResult WHERE Ranking = @rankForTabTime AND IsKeyRecord = 1

    DECLARE @startID INT
	DECLARE @endID INT
	SET @startID = (SELECT TOP(1) ID FROM @FinalResult WHERE Ranking = @rankForTabTime AND IsKeyRecord = 0)
	SET @endID = (SELECT TOP(1) ID FROM @FinalResult WHERE Ranking = @rankForTabTime AND IsKeyRecord = 0 ORDER BY ID DESC)
	
	WHILE @startID <= @endID
	BEGIN
		DECLARE @curEventID INT
		SET @curEventID = (SELECT EventID FROM @FinalResult WHERE ID = @startID)
		DECLARE @eventFilterID int
		SET @eventFilterID = (SELECT ID FROM @EventFilters WHERE EventID = @curEventID AND IsEnter = 1 AND IsKey = 0)
		IF @eventFilterID IS NOT NULL
			BEGIN
				DECLARE @eventIDFromFilter int
				SET @eventIDFromFilter = (SELECT EventID FROM @EventFilters WHERE ID= @eventFilterID + 1)
				IF EXISTS (SELECT * FROM @FinalResult WHERE ID=@startID + 1 AND EventID = @eventIDFromFilter)
				BEGIN
					DECLARE @dateDIFF NUMERIC(18,2)
					SET @dateDIFF = ABS(DATEDIFF(SS,(SELECT CreateDate FROM @FinalResult WHERE ID=@startID + 1),
												(SELECT CreateDate FROM @FinalResult WHERE ID=@startID)))
					UPDATE @FinalResult
					SET TabTimeDifference = @dateDIFF
					WHERE ID = @startID
				END
			END
		
		SET @startID =  @startID + 1
	END

	UPDATE @FinalResult SET TabTimeDifference = (SELECT SUM(ABS(ISNULL(TabTimeDifference,0))) 
												 FROM @FinalResult WHERE Ranking = @rankForTabTime)
	WHERE  Ranking = @rankForTabTime AND IsKeyRecord = 1

	UPDATE @AttempsResult SET EffortInSeconds = (SELECT TabTimeDifference FROM @FinalResult WHERE Ranking = @rankForTabTime AND IsKeyRecord = 1) 
	WHERE  RankID = @rankForTabTime
	
	SET @rankForTabTime = @rankForTabTime + 1
END
UPDATE @AttempsResult SET EffortInSeconds = (SELECT SUM(EffortInSeconds) FROM @AttempsResult WHERE RankID != 0) WHERE RankID = 0

--DEBUGING PURPOSE
--SELECT * FROM @FinalResult

IF EXISTS (SELECT Ranking FROM @FinalResult WHERE Ranking > 1)
BEGIN
	DECLARE @firstRankKeyRecordCreateDate DATETIME
	SET     @firstRankKeyRecordCreateDate = (SELECT TOP 1 CreateDate FROM @FinalResult WHERE Ranking = 1 ORDER BY EventLogID DESC)
	
	DECLARE @SecondRankKeyRecordCreateDate DATETIME
	SET     @SecondRankKeyRecordCreateDate = (SELECT TOP 1 CreateDate FROM @FinalResult WHERE Ranking = 2 ORDER BY EventLogID ASC)

	UPDATE @AttempsResult SET WaitingTimeInQueue = ABS(DATEDIFF(SS,@SecondRankKeyRecordCreateDate,@firstRankKeyRecordCreateDate))
	WHERE ID = 3

	DECLARE @waitStartCounter AS INT
    SET @waitStartCounter = 4

	DECLARE @maxStartCounter AS INT
	SET @maxStartCounter = (SELECT MAX(ID) FROM @AttempsResult)

	WHILE @waitStartCounter <= @maxStartCounter
	BEGIN
		UPDATE @AttempsResult SET 
		WaitingTimeInQueue = ABS(DATEDIFF(SS,(SELECT TOP 1 CreateDate FROM @FinalResult WHERE Ranking = 
																 (SELECT RankID FROM @AttempsResult WHERE ID = @waitStartCounter) 
																  ORDER BY EventLogID ASC),(SELECT TOP 1 CreateDate FROM @FinalResult WHERE Ranking = 
																 (SELECT RankID FROM @AttempsResult WHERE ID = @waitStartCounter - 1) ORDER BY EventLogID DESC)))
		WHERE ID = @waitStartCounter
		SET @waitStartCounter = @waitStartCounter + 1
	END
END

UPDATE @AttempsResult SET WaitingTimeInQueue = ISNULL((SELECT SUM(WaitingTimeInQueue) FROM @AttempsResult A WHERE ID > 1),0) WHERE ID = 1
RETURN
END
