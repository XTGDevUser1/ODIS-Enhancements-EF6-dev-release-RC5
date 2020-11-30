IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_claim_batch_details_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_claim_batch_details_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_claim_batch_details_update] @claimsXML = '<Claims><ID>1</ID><ID>2</ID><ID>3</ID><ID>4</ID></Claims>',@batchID = 999, @currentUser='kbanda', @eventSource='/TEST', @eventDetails='Test'
 CREATE PROCEDURE [dbo].[dms_claim_batch_details_update](
	@claimsXML XML,
	@batchID BIGINT,
	@currentUser NVARCHAR(50),
	@eventSource NVARCHAR(MAX),
	@eventName NVARCHAR(100) = 'PayClaim',
	@eventDetails NVARCHAR(MAX),
	@entityName NVARCHAR(50) = 'Claim',
	@sessionID NVARCHAR(MAX) = NULL
 )
 AS
 BEGIN
 
	DECLARE @now DATETIME = GETDATE()
	
	DECLARE @claimsFromDB TABLE
	(	
		ID INT IDENTITY(1,1),
		ClaimID INT
	)
	
	INSERT INTO @claimsFromDB
	SELECT C.ID
	FROM	Claim C
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @claimsXML.nodes('/Claims/ID') T(c)
			) T ON C.ID = T.ID
	JOIN	ClaimType CT ON C.ClaimTypeID = CT.ID
	WHERE	CT.Name <> 'FordQFC'
	
	DECLARE @paidStatusID INT, 
			@payClaimsEventID INT, 
			@claimEntityID INT,
			@paymentTypeID INT
	SELECT @paidStatusID = ID FROM ClaimStatus WHERE Name = 'Paid'
	SELECT @payClaimsEventID = ID FROM Event WHERE Name = @eventName
	SELECT @claimEntityID = ID FROM Entity WHERE Name = @entityName
	SELECT @paymentTypeID = ID FROM PaymentType WHERE Name = 'Check'
	
	UPDATE	Claim
	SET		ExportBatchID = @batchID,
			ExportDate = @now,
			ModifyBy = @currentUser,
			ModifyDate = @now,
			ClaimStatusID = @paidStatusID,
			PaymentDate = @now,
			PaymentAmount = C.AmountApproved,
			PaymentTypeID = @paymentTypeID			
	FROM	Claim C
	JOIN	@claimsFromDB I ON C.ID = I.ClaimID
	
	
	-- Event Logs.
	DECLARE @maxRows INT, @index INT = 1
	SELECT @maxRows = COUNT(*) FROM @claimsFromDB
	
	WHILE ( @index <= @maxRows)
	BEGIN
		
		INSERT INTO EventLog
		SELECT	@payClaimsEventID,
				@sessionID,
				@eventSource,
				@eventDetails,
				NULL,
				NULL,
				GETDATE(),
				@currentUser
				
		INSERT INTO EventLogLink
		SELECT	SCOPE_IDENTITY(),
				@claimEntityID,
				(SELECT ClaimID FROM @claimsFromDB WHERE ID = @index)			
	
		SET @index = @index + 1
	END
 
 END