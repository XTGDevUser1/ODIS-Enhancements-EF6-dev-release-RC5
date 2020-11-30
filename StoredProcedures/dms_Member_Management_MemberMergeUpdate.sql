IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Member_Management_MemberMergeUpdate]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_Management_MemberMergeUpdate] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
 --EXEC   [dms_Member_Management_MemberMergeUpdate] @sourceMemberId=1,@targetMemberId=2,@sessionId=NULL,@userId='system',@source='SQL'
 CREATE PROCEDURE [dbo].[dms_Member_Management_MemberMergeUpdate]
 (   
 @sourceMemberId int,
 @targetMemberId int,
 @sessionId nvarchar(88),
 @userId nvarchar(50),
 @source nvarchar(255)
 )
 AS
 BEGIN
 
 BEGIN TRY
 
	 BEGIN TRAN
	 
	 SET NOCOUNT ON    
	 DECLARE @currentDate DATETIME
	 SET @currentDate = GETDATE()
	 DECLARE @entityMember int
	 DECLARE @membersCount int
	 DECLARE @eventLogDescription nvarchar(2000)
	 DECLARE @eventLogId int
	 DECLARE @maxCount int
	 DECLARE @counter int
	 DECLARE @eventLogName nvarchar(200)
	 
	 SET @entityMember = (SELECT ID FROM Entity WHERE Name = 'Member')
	 
	 DECLARE @LogResults TABLE(   
	 ID int NOT NULL,
	 Name nvarchar(200) NULL,
	 Value nvarchar(200) NULL)
	 
	 SET @eventLogDescription = '<EventDetail>'
	 SET @eventLogDescription = @eventLogDescription + '<SOURCEMEMBERSHIP>' + (SELECT CAST(MembershipID AS VARCHAR(10)) FROM Member WHERE ID = @sourceMemberId) + '</SOURCEMEMBERSHIP>'
	 SET @eventLogDescription = @eventLogDescription + '<TARGETMEMBERSHIP>' + (SELECT CAST(MembershipID AS VARCHAR(10)) FROM Member WHERE ID = @targetMemberId) + '</TARGETMEMBERSHIP>'
	 SET @eventLogDescription = @eventLogDescription + '<SOURCEMEMBER>' + (SELECT CAST(@sourceMemberId AS VARCHAR(10))) + '</SOURCEMEMBER>'
	 SET @eventLogDescription = @eventLogDescription + '<TARGETMEMBER>' + (SELECT CAST(@targetMemberId AS VARCHAR(10))) + '</TARGETMEMBER>'
	 
	 --Log Case
	 INSERT INTO @LogResults
	 SELECT 
		 ROW_NUMBER() OVER (ORDER BY ID) AS columnOrder,
		 'CASE_' + CAST(ID AS VARCHAR(10)),
		 ID
		 FROM [Case]
		 WHERE MemberID = @sourceMemberId
	 
	 SET @maxCount = (SELECT Count(*) FROM @LogResults)
	 SET @counter = 1
	 
	 WHILE(@counter <= @maxCount)
	 BEGIN
	 
	 SET @eventLogDescription = @eventLogDescription + '<' + (SELECT Name FROM @LogResults WHERE ID = @counter) + '>'
													 +  (SELECT Value FROM @LogResults WHERE ID = @counter)
													 + '</' + (SELECT Name FROM @LogResults WHERE ID = @counter) + '>'
	 SET @counter = @counter + 1
	 
	 END
	 DELETE FROM @LogResults
	     
	 UPDATE [Case]
	 SET MemberID = @targetMemberId,
		 ModifyBy = @userId,
		 ModifyDate = @currentDate
	 WHERE MemberID = @sourceMemberId
	 
	 --Log EventLogLink
	 INSERT INTO @LogResults
	 SELECT 
		 ROW_NUMBER() OVER (ORDER BY ID) AS columnOrder,
		 'EVENTLOGLINK_' + CAST(ID AS VARCHAR(10)),
		 ID
		 FROM EventLogLink
		 WHERE RecordID = @sourceMemberId AND EntityID = @entityMember
	     
	 SET @maxCount = (SELECT Count(*) FROM @LogResults)
	 SET @counter = 1
	 
	 WHILE(@counter <= @maxCount)
	 BEGIN
	 
	 SET @eventLogDescription = @eventLogDescription + '<' + (SELECT Name FROM @LogResults WHERE ID = @counter) + '>'
													 +  (SELECT Value FROM @LogResults WHERE ID = @counter)
													 + '</' + (SELECT Name FROM @LogResults WHERE ID = @counter) + '>'
	 SET @counter = @counter + 1
	 
	 END
	 
	 DELETE FROM @LogResults    
	 
	 UPDATE EventLogLink
	 SET RecordID = @targetMemberId
	 WHERE RecordID = @sourceMemberId AND EntityID = @entityMember
	 
	 
	 
	  --Log ContactLogLink
	 INSERT INTO @LogResults
	 SELECT 
		 ROW_NUMBER() OVER (ORDER BY ID) AS columnOrder,
		 'CONTACTLOGLINK_' + CAST(ID AS VARCHAR(10)),
		 ID
		 FROM ContactLogLink
		 WHERE RecordID = @sourceMemberId AND EntityID = @entityMember
	     
	 SET @maxCount = (SELECT Count(*) FROM @LogResults)
	 SET @counter = 1   
	 
	 WHILE(@counter <= @maxCount)
	 BEGIN
	 
	 SET @eventLogDescription = @eventLogDescription + '<' + (SELECT Name FROM @LogResults WHERE ID = @counter) + '>'
													 +  (SELECT Value FROM @LogResults WHERE ID = @counter)
													 + '</' + (SELECT Name FROM @LogResults WHERE ID = @counter) + '>'
	 SET @counter = @counter + 1
	 
	 END
	 DELETE FROM @LogResults
	 
	 UPDATE ContactLogLink
	 SET RecordID = @targetMemberId
	 WHERE RecordID = @sourceMemberId AND EntityID = @entityMember
	 
	 
	 UPDATE Member
	 SET IsActive = 0,
		 ModifyBy = @userId,
		 ModifyDate = @currentDate
	 WHERE ID = @sourceMemberId
	 
	 SET @membersCount = (SELECT Count(*) FROM Member
	 WHERE MembershipID = (SELECT MembershipID FROM Member WHERE ID = @sourceMemberId)
	 AND ID != @sourceMemberId)
	 
	 IF(@membersCount = 0)
	 BEGIN
	 
		UPDATE Membership
		SET IsActive = 0,
			ModifyBy = @userId,
			ModifyDate = @currentDate
		WHERE ID = (SELECT MembershipID FROM Member WHERE ID = @sourceMemberId)
		
	 END
	 
	 SET @eventLogDescription = @eventLogDescription + '</EventDetail>'
	 
	 INSERT INTO EventLog(EventID,SessionID,[Source],[Description],CreateDate,CreateBy)
	 SELECT (SELECT ID FROM [Event] WHERE Name = 'MergeMember') EventID,
			 @sessionId,
			 @source,
			 @eventLogDescription,
			 @currentDate,
			 @userId
	 
	 SET @eventLogId = SCOPE_IDENTITY()
						
	 INSERT INTO EventLogLink(EventLogID,EntityID,RecordID)
	 SELECT @eventLogId,
			@entityMember,
			@sourceMemberId
			
	 INSERT INTO EventLogLink(EventLogID,EntityID,RecordID)
	 SELECT @eventLogId,
			@entityMember,
			@targetMemberId

	COMMIT TRAN
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
	
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
	
END CATCH
	
	


 
END