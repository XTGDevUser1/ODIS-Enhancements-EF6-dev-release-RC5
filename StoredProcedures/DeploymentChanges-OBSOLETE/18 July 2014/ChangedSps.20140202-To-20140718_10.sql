IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_CCImport_UpdateTempCreditCardDetails]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_CCImport_UpdateTempCreditCardDetails]
GO

--EXEC dms_CCImport_UpdateTempCreditCardDetails
CREATE PROC [dbo].[dms_CCImport_UpdateTempCreditCardDetails]
AS
BEGIN

BEGIN TRY
 

CREATE TABLE #TempCardsNotPosted (     
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
 ID int  NULL)

DECLARE @postedStatus INT
DECLARE @startROWParent INT 
DECLARE @totalRowsParent INT,
		@creditcardNumber INT,
		@totalApprovedAmount money,
		@totalChargedAmount money,
		@maxLastChargeDate datetime

SET @postedStatus = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name='Posted')

INSERT INTO #TempCardsNotPosted
SELECT DISTINCT TCCD.TemporaryCreditCardID FROM
TemporaryCreditCardDetail TCCD
JOIN TemporaryCreditCard TCC ON TCC.ID = TCCD.TemporaryCreditCardID
WHERE TCC.TemporaryCreditCardStatusID NOT IN (SELECT ID FROM TemporaryCreditCardStatus WHERE Name IN ('Cancelled','Posted'))
AND TCC.IssueDate > DATEADD(mm, -3, GETDATE())

SET @startROWParent =  (SELECT MIN([RowNum]) FROM #TempCardsNotPosted)
SET @totalRowsParent = (SELECT MAX([RowNum]) FROM #TempCardsNotPosted)

WHILE(@startROWParent <= @totalRowsParent)  
BEGIN

SET @creditcardNumber = (SELECT ID FROM #TempCardsNotPosted WHERE [RowNum] = @startROWParent)
SET @maxLastChargeDate = (SELECT MAX(ChargeDate) FROM TemporaryCreditCardDetail WHERE TemporaryCreditCardID =  @creditcardNumber)

UPDATE TemporaryCreditCard
SET LastChargedDate = @maxLastChargeDate
WHERE ID =  @creditcardNumber

IF((SELECT Count(*) FROM TemporaryCreditCardDetail 
   WHERE TransactionType='Cancel' AND TemporaryCreditCardID = @creditcardNumber) > 0)
 BEGIN
	UPDATE TemporaryCreditCard 
	SET IssueStatus = 'Cancel'
	WHERE ID = @creditcardNumber
 END
 
 SET @totalApprovedAmount = (SELECT TOP 1 ApprovedAmount FROM TemporaryCreditCardDetail
							 WHERE TemporaryCreditCardID = @creditcardNumber AND TransactionType='Approve'
							 AND TransactionSequence IS NOT NULL
							 ORDER BY TransactionSequence DESC)
SET @totalChargedAmount = (SELECT SUM(ChargeAmount) FROM TemporaryCreditCardDetail
						   WHERE TemporaryCreditCardID = @creditcardNumber AND TransactionType='Charge')

UPDATE TemporaryCreditCard
SET ApprovedAmount = @totalApprovedAmount,
	TotalChargedAmount = @totalChargedAmount
WHERE ID = @creditcardNumber
						 
SET @startROWParent = @startROWParent + 1

END

DROP TABLE #TempCardsNotPosted



END TRY
BEGIN CATCH
		
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
GO


IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Communication_Fax_Update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Communication_Fax_Update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dbo].[dms_Communication_Fax_Update] 'kbanda'
 CREATE PROCEDURE [dbo].[dms_Communication_Fax_Update](@userName NVARCHAR(50) = NULL)
 AS
 BEGIN
 
DECLARE @tmpRecordstoUpdate TABLE
(
CommunicationLogID INT NOT NULL,
ContactLogID INT NOT NULL,
[Status] nvarchar(255) NULL,
FaxResult nvarchar(2000) NULL,
FaxInfo nvarchar(2000)NULL,
sRank INT NOT NULL,
CommunicationLogCreateBy NVARCHAR(100) NULL
)
 
	
    -- To Update the Records in Batch
	--WITH wResult AS(
	INSERT INTO @tmpRecordstoUpdate
	SELECT	CL.ID,
			CL.ContactLogID,
			CL.[Status],
			FR.[result] AS FaxResult,
			FR.[info] AS FaxInfo,
			ROW_NUMBER() OVER(PARTITION BY FR.Billing_Code ORDER BY FR.[Date] DESC) AS 'SRank',
			CL.CreateBy
			FROM CommunicationLog CL
			 INNER JOIN FaxResult FR ON
			 FR.[date] > DATEADD(dd, -14, getdate()) AND
			 FR.[billing_code] <> '' AND 
			 FR.[billing_code] = CL.ID
			 WHERE ContactMethodID = (SELECT ID FROM ContactMethod WHERE Name = 'Fax')
			 AND [Status] = 'PENDING'

	UPDATE CommunicationLog 
	SET [Status] = T.FaxResult,
		Comments = T.FaxInfo,
		ModifyDate = getdate(),
		ModifyBy = @username 
	FROM CommunicationLog 
	JOIN @tmpRecordstoUpdate T on T.CommunicationLogID = CommunicationLog.ID
	WHERE T.sRank = 1
				 
	--UPDATE wResult SET wResult.[Status] = wResult.FaxResult,
	--				   wResult.Comments = wResult.[FaxInfo],
	--				   wResult.ModifyDate = getdate(),
	--				   wResult.ModifyBy = @userName 
	--				   WHERE SRank = 1
					   
	-- Create New Records in Batch if Contact Log ID is not NULL				   
	--;WITH wResultInsert AS(
	--SELECT CL.*,FR.[result] AS FaxResult,FR.[info] AS FaxInfo FROM CommunicationLog CL
	--		 INNER JOIN FaxResult FR ON
	--		 FR.[billing_code] = CL.ID
	--		 WHERE ContactMethodID = (SELECT ID FROM ContactMethod WHERE Name = 'Fax')
	--		 AND
	--		 [Status] IN ('SUCCESS','FAILURE')
	--		 AND ContactLogID IS NOT NULL)
	INSERT INTO ContactLogAction(ContactActionID,ContactLogID,Comments,CreateDate,CreateBy)
		   SELECT DISTINCT
		     Case FaxResult 
				WHEN 'SUCCESS' THEN (SELECT ID FROM ContactAction WHERE Name = 'Sent')
				ELSE (SELECT ID FROM ContactAction WHERE Name = 'SendFailure')
			END as ContactActionID,
		   [ContactLogID],FaxInfo,GETDATE(),@userName
		   FROM @tmpRecordstoUpdate
		   WHERE sRank = 1

	-- KB: Notifications
	-- For every communicationlog record whose status was set to FAIL, create eventlog records with event
	DECLARE @eventIDForSendPOFaxFailed INT,
			@eventDescriptionForSendPOFaxFailed NVARCHAR(255),
			@poEntityID INT,
			@contactLogActionEntityID INT,
			@idx INT = 1,
			@maxRows INT,
			@eventLogID INT,
			@sendFailureContactActionID INT

	SELECT	@eventIDForSendPOFaxFailed = ID, @eventDescriptionForSendPOFaxFailed = [Description] FROM [Event] WITH (NOLOCK) WHERE Name = 'SendPOFaxFailed'
	SELECT	@poEntityID = ID FROM Entity WHERE Name = 'PurchaseOrder'
	SELECT	@contactLogActionEntityID = ID FROM Entity WHERE Name = 'ContactLogAction'
	SELECT	@sendFailureContactActionID = ID FROM ContactAction WHERE Name = 'SendFailure'

	CREATE TABLE #tmpCommunicationLogFaxFailed
	(
		RowNum INT IDENTITY(1,1) NOT NULL,
		CommunicationLogID INT NOT NULL,
		ContactLogID INT NOT NULL,
		PurchaseOrderID INT NULL,
		PurchaseOrderNumber NVARCHAR(50) NULL,
		ServiceRequestNumber INT NULL,
		FailureReason NVARCHAR(MAX) NULL,
		CommunicationLogCreateBy NVARCHAR(100) NULL
	)

	INSERT INTO #tmpCommunicationLogFaxFailed 
	SELECT	T.CommunicationLogID,
			T.ContactLogID,
			CLL.RecordID,
			PO.PurchaseOrderNumber,
			PO.ServiceRequestID,
			T.FaxInfo,
			T.CommunicationLogCreateBy
	FROM	@tmpRecordstoUpdate T
	LEFT JOIN	ContactLogLink CLL ON T.ContactLogID = CLL.ContactLogID AND CLL.EntityID = @poEntityID
	LEFT JOIN	PurchaseOrder PO ON PO.ID = CLL.RecordID
	WHERE	T.FaxResult = 'FAILURE'
	AND		T.sRank = 1

	SELECT @maxRows = MAX(RowNum) FROM #tmpCommunicationLogFaxFailed


	--DEBUG: SELECT * FROM #tmpCommunicationLogFaxFailed

	DECLARE @purchaseOrderID INT,
			@serviceRequestID INT,
			@purchaseOrderNumber NVARCHAR(50),
			@contactLogID INT,
			@failureReason NVARCHAR(MAX),
			@commLogCreateBy NVARCHAR(100)

	WHILE ( @idx <= @maxRows )
	BEGIN
		
		SELECT	@contactLogID		= T.ContactLogID,
				@failureReason		= T.FailureReason,
				@purchaseOrderID	= T.PurchaseOrderID,
				@purchaseOrderNumber = T.PurchaseOrderNumber,
				@serviceRequestID	= T.ServiceRequestNumber,
				@commLogCreateBy	= T.CommunicationLogCreateBy
		FROM	#tmpCommunicationLogFaxFailed T WHERE T.RowNum = @idx

		-- For each communication log record related to fax failure, log an event and create link records - one per 
		INSERT INTO EventLog (	EventID,
								Source,
								Description,
								Data,
								NotificationQueueDate,
								CreateDate,
								CreateBy)
		SELECT	@eventIDForSendPOFaxFailed,
				'Communication Service',
				@eventDescriptionForSendPOFaxFailed,
				'<MessageData><PONumber>' + @purchaseOrderNumber + 
							'</PONumber><ServiceRequest>' + CONVERT(NVARCHAR(50),@serviceRequestID) + 
							'</ServiceRequest><FaxFailureReason>' + @failureReason + 
							'</FaxFailureReason><CreateByUser>' +  @commLogCreateBy +
							'</CreateByUser></MessageData>',
				NULL,
				GETDATE(),
				'system'
		

		SET @eventLogID = SCOPE_IDENTITY()

		--DEBUG: SELECT @eventLogID AS EventLogID

		INSERT INTO EventLogLink ( EventLogID, EntityID, RecordID)
		SELECT	@eventLogID,
				@poEntityID,
				@purchaseOrderID

		;WITH wContactLogActions
		AS
		(
			SELECT	ROW_NUMBER() OVER ( PARTITION BY CLA.ContactActionID ORDER BY CLA.CreateDate DESC) As RowNum,
					CLA.ID As ContactLogActionID,
					CLA.ContactLogID
			FROM	ContactLogAction CLA 			
			WHERE	CLA.ContactLogID = @contactLogID
			AND		CLA.ContactActionID = @sendFailureContactActionID
		)

		INSERT INTO EventLogLink ( EventLogID, EntityID, RecordID)
		SELECT	@eventLogID,
				@contactLogActionEntityID,
				W.ContactLogActionID
		FROM	wContactLogActions W 
		WHERE	W.RowNum = 1


		SET @idx = @idx + 1
	END



	DROP TABLE #tmpCommunicationLogFaxFailed
END



GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_CurrentUser_For_Event_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_CurrentUser_For_Event_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_CurrentUser_For_Event_Get] 'kbanda'
CREATE PROCEDURE [dbo].[dms_CurrentUser_For_Event_Get](
	@eventLogID INT,
	@eventSubscriptionID INT
)
AS
BEGIN
 
	/*
		Assumption : This stored procedure would be executed for DesktopNotifications.
		Logic : 
		If the event is SendPOFaxFailure - Determine the current user as follows:
			1.	Parse EL.Data and pull out <ServiceRequest><SR.ID>  </ServiceRequest>
			2.	Join to Case from that SR.ID and get Case.AssignedToUserID
			3.	Insert one CommunicatinQueue record
			4.	If this value is blank try next one
			iv.	If no current user assigned
			1.	Parse EL.Data and pull out <CreateByUser><username></CreateByUser>
			2.	Check to see if that <username> is online
			3.	If online then Insert one CommunicatinQueue record for that user
			v.	If still no user found or online, then check the Service Request and if the NextAction fields are blank.  If blank then:
			1.	Update the associated ServiceRequest next action fields.  These will be displayed on the Queue prompting someone to take action and re-send the PO
			a.	Set ServiceRequest.NextActionID = Re-send PO
			b.	Set ServiceRequest.NextActionAssignedToUserID = ‘Agent User’

		If the event is ManualNotification, determine the curren user(s) as follows: 
			1. Get the associated EventLogLinkRecords.
			2. For each of the link records:
				2.1 If the related entity on the link record is a user and the user is online, add the user details to the list.
				
		If the event is not SendPOFaxFailure - CurrentUser = ServiceRequest.Case.AssignedToUserID.
	*/

	DECLARE @eventName NVARCHAR(255),
			@eventData XML,
			@PONumber NVARCHAR(100),
			@ServiceRequest INT,
			@FaxFailureReason NVARCHAR(MAX),
			@CreateByUser NVARCHAR(50),

			@assignedToUserIDOnCase INT,
			@nextActionIDOnSR INT,
			@nextActionAssignedToOnSR INT,
			@resendPONextActionID INT,
			@agentUserID INT,
			@nextActionPriorityID INT = NULL,
			@defaultScheduleDateInterval INT = NULL,
			@defaultScheduleDateIntervalUOM NVARCHAR(50) = NULL

	DECLARE @tmpCurrentUser TABLE
			(
				UserId UNIQUEIDENTIFIER NULL,
				UserName NVARCHAR(100) NULL
			)
	
	SELECT  @resendPONextActionID = ID FROM NextAction WITH (NOLOCK) WHERE Name = 'ResendPO'
	SELECT	@nextActionPriorityID = DefaultPriorityID FROM NextAction WITH (NOLOCK) WHERE Name = 'ResendPO'

	IF (@nextActionPriorityID IS NULL)
	BEGIN
		SELECT @nextActionPriorityID = (SELECT ID FROM ServiceRequestPriority WITH (NOLOCK) WHERE Name = 'Normal')
	END


	SELECT	@defaultScheduleDateInterval	= ISNULL(DefaultScheduleDateInterval,0),
			@defaultScheduleDateIntervalUOM = DefaultScheduleDateIntervalUOM
	FROM	NextAction WITH (NOLOCK)
	WHERE	ID = @resendPONextActionID


	--SELECT	@agentUserID = U.ID
	--FROM	[User] U WITH (NOLOCK) 
	--JOIN	aspnet_Users AU WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
	--JOIN	aspnet_Applications A WITH (NOLOCK) ON A.ApplicationId = AU.ApplicationId
	--WHERE	AU.UserName = 'Agent'
	--AND		A.ApplicationName = 'DMS'

	SELECT	@eventData = EL.Data
	FROM	EventLog EL WITH (NOLOCK)
	JOIN	Event E WITH (NOLOCK) ON EL.EventID = E.ID
	WHERE	EL.ID = @eventLogID

	SELECT	@eventName = E.Name
	FROM	EventSubscription ES WITH (NOLOCK) 
	JOIN	Event E WITH (NOLOCK) ON ES.EventID = E.ID
	WHERE	ES.ID = @eventSubscriptionID
	

	SELECT	@PONumber = (SELECT  T.c.value('.','NVARCHAR(100)') FROM @eventData.nodes('/MessageData/PONumber') T(c)),
			@ServiceRequest = (SELECT  T.c.value('.','INT') FROM @eventData.nodes('/MessageData/ServiceRequest') T(c)),
			@FaxFailureReason = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventData.nodes('/MessageData/FaxFailureReason') T(c)),
			@CreateByUser = (SELECT  T.c.value('.','NVARCHAR(50)') FROM @eventData.nodes('/MessageData/CreateByUser') T(c))
		
	SELECT	@assignedToUserIDOnCase = C.AssignedToUserID
		FROM	[Case] C WITH (NOLOCK)
		JOIN	[ServiceRequest] SR WITH (NOLOCK) ON SR.CaseID = C.ID
		WHERE	SR.ID = @ServiceRequest

	IF (@eventName = 'SendPOFaxFailed')
	BEGIN	
				
		IF (@assignedToUserIDOnCase IS NOT NULL)
		BEGIN
			PRINT 'AssignedToUserID On Case is not null'
			-- Return the user details.
			INSERT INTO @tmpCurrentUser ( UserId, UserName)
			SELECT	AU.UserId,
					AU.UserName
			FROM	aspnet_Users AU WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
			WHERE	U.ID = @assignedToUserIDOnCase

		END
		ELSE 
		BEGIN
			-- TFS: 390
			--IF ( (SELECT [dbo].[fnIsUserConnected](@CreateByUser) ) = 1)
			--BEGIN
				
			--	INSERT INTO @tmpCurrentUser
			--	SELECT	AU.UserId,
			--			AU.UserName
			--	FROM	aspnet_Users AU WITH (NOLOCK) 
			--	JOIN	aspnet_Applications A WITH (NOLOCK) ON AU.ApplicationId = A.ApplicationId			
			--	WHERE	AU.UserName = @CreateByUser
			--	AND		A.ApplicationName = 'DMS'
				
			--END
			--ELSE
			--BEGIN
			PRINT 'AssignedToUserID On Case is null'
				SELECT	@nextActionIDOnSR = SR.NextActionID,
						@nextActionAssignedToOnSR = SR.NextActionAssignedToUserID
				FROM	ServiceRequest SR WITH (NOLOCK) 
				WHERE ID = @ServiceRequest 

				--IF @nextActionAssignedToOnSR IS NULL AND @nextActionIDOnSR IS NULL
				BEGIN
					PRINT 'Setting service request attributes'
					UPDATE	ServiceRequest
					SET		NextActionID = @resendPONextActionID,
							--TFS : 390
							NextActionAssignedToUserID = (SELECT DefaultAssignedToUserID FROM NextAction 
															WHERE ID = @resendPONextActionID 
														 ),
							ServiceRequestPriorityID = @nextActionPriorityID,
							NextActionScheduledDate =  CASE WHEN @defaultScheduleDateIntervalUOM = 'days'
																THEN DATEADD(dd,@defaultScheduleDateInterval,GETDATE())
															WHEN @defaultScheduleDateIntervalUOM = 'hours'
																THEN DATEADD(hh,@defaultScheduleDateInterval,GETDATE())
															WHEN @defaultScheduleDateIntervalUOM = 'minutes'
																THEN DATEADD(mi,@defaultScheduleDateInterval,GETDATE())
															WHEN @defaultScheduleDateIntervalUOM = 'seconds'
																THEN DATEADD(ss,@defaultScheduleDateInterval,GETDATE())
															ELSE NULL
															END
														
					WHERE	ID = @ServiceRequest

					INSERT INTO @tmpCurrentUser
					SELECT	AU.UserId,
							AU.UserName
					FROM	aspnet_Users AU WITH (NOLOCK) 
					JOIN	aspnet_Applications A WITH (NOLOCK) ON AU.ApplicationId = A.ApplicationId
					JOIN	aspnet_UsersInRoles UR WITH (NOLOCK) ON UR.UserId = AU.UserId
					JOIN	aspnet_Roles R WITH (NOLOCK) ON UR.RoleId = R.RoleId AND R.ApplicationId = A.ApplicationId
					WHERE	A.ApplicationName = 'DMS'
					AND		R.RoleName = 'Manager'
			
				END				
		END	
	END
	
	ELSE IF (@eventName = 'ManualNotification' OR @eventName = 'LockedRequestComment')
	BEGIN
		
		DECLARE @userEntityID INT

		SET @userEntityID = (SELECT ID FROM Entity WHERE Name = 'User')
		;WITH wUsersFromEventLogLinks
		AS
		(
			SELECT	AU.UserId,
					AU.UserName,
					[dbo].[fnIsUserConnected](AU.UserName) IsConnected				
			FROM	EventLogLink ELL WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON ELL.RecordID = U.ID AND ELL.EntityID = @userEntityID
			JOIN	aspnet_Users AU WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
			WHERE	ELL.EventLogID = @eventLogID
		)

		INSERT INTO @tmpCurrentUser (UserId, UserName)
		SELECT	W.UserId, W.UserName
		FROM	wUsersFromEventLogLinks W
		WHERE	ISNULL(W.IsConnected,0) = 1


	END	
	ELSE
	BEGIN
		
		IF (@assignedToUserIDOnCase IS NOT NULL)
		BEGIN

			INSERT INTO @tmpCurrentUser ( UserId, UserName)
			SELECT	AU.UserId,
					AU.Username
			FROM	aspnet_Users AU WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON AU.UserId = U.aspnet_UserID
			JOIN	[aspnet_Applications] A WITH (NOLOCK) ON A.ApplicationId = AU.ApplicationId
			WHERE	A.ApplicationName = 'DMS'
			AND		U.ID = @assignedToUserIDOnCase

		END
			
	END	


	SELECT UserId, Username from @tmpCurrentUser

END

GO


GO
/*******************
* Operator Enums 
*  Conditions Enum :
* -1 - No filter
*  0 - Null
*  1 - Not Null
*  2 - Equals
*  3 - NotEquals
*  ---- for strings ---
*  4 - StartsWith
*  5 - EndsWith
*  6 - Contains
*  ---- for int, decimal, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_MemberShip_Management_SR_History_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_MemberShip_Management_SR_History_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_MemberShip_Management_SR_History_Get @MembershipID=1
 CREATE PROCEDURE [dbo].dms_MemberShip_Management_SR_History_Get( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @MembershipID INT = NULL 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
RequestNumberOperator="-1" 
RequestDateOperator="-1" 
MemberNameOperator="-1" 
ServiceTypeOperator="-1" 
StatusOperator="-1" 
VehicleOperator="-1" 
POCountOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
RequestNumberOperator INT NOT NULL,
RequestNumberValue int NULL,
RequestDateOperator INT NOT NULL,
RequestDateValue datetime NULL,
MemberNameOperator INT NOT NULL,
MemberNameValue nvarchar(100) NULL,
ServiceTypeOperator INT NOT NULL,
ServiceTypeValue nvarchar(100) NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL,
VehicleOperator INT NOT NULL,
VehicleValue nvarchar(100) NULL,
POCountOperator INT NOT NULL,
POCountValue int NULL
)
 DECLARE @FinalResults AS TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	RequestNumber int  NULL ,
	RequestDate datetime  NULL ,
	MemberName nvarchar(100)  NULL ,
	ServiceType nvarchar(100)  NULL ,
	Status nvarchar(100)  NULL ,
	Vehicle nvarchar(100)  NULL ,
	POCount int  NULL 
) 
DECLARE @FinalResults_Temp AS TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	RequestNumber int  NULL ,
	RequestDate datetime  NULL ,
	MemberName nvarchar(100)  NULL ,
	ServiceType nvarchar(100)  NULL ,
	Status nvarchar(100)  NULL ,
	Vehicle nvarchar(100)  NULL ,
	POCount int  NULL 
)

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@RequestNumberOperator','INT'),-1),
	T.c.value('@RequestNumberValue','int') ,
	ISNULL(T.c.value('@RequestDateOperator','INT'),-1),
	T.c.value('@RequestDateValue','datetime') ,
	ISNULL(T.c.value('@MemberNameOperator','INT'),-1),
	T.c.value('@MemberNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ServiceTypeOperator','INT'),-1),
	T.c.value('@ServiceTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleOperator','INT'),-1),
	T.c.value('@VehicleValue','nvarchar(100)') ,
	ISNULL(T.c.value('@POCountOperator','INT'),-1),
	T.c.value('@POCountValue','int') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

INSERT INTO @FinalResults_Temp

SELECT SR.ID AS RequestNumber
	, CONVERT(VARCHAR(10),SR.CreateDate,101) AS RequestDate
	, REPLACE(RTRIM(
		COALESCE(M.Firstname, '')+
		COALESCE(' ' + M.MiddleName, '')+
		COALESCE(' ' + M.LastName, '')+
		COALESCE(' ' + M.Suffix, '')
	  ),'','') AS MemberName
	, PC.Name AS ServiceType
	, SRS.Name AS Status
	, REPLACE(RTRIM(
		COALESCE(C.VehicleYear, '')+
		COALESCE(' ' + CASE WHEN C.VehicleMake = 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END, '')+
		COALESCE(' ' + CASE WHEN C.VehicleModel = 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END, '')
	  ),'','') AS Vehicle
	, (SELECT COUNT(*) FROM PurchaseOrder WHERE IsActive = 1 AND ServiceRequestID = SR.ID) AS POCount
FROM ServiceRequest SR
JOIN [Case] C ON C.ID = SR.CaseID
JOIN Member M ON M.ID = C.MemberID
LEFT JOIN Product P ON P.ID = SR.PrimaryProductID
LEFT JOIN ProductCategory PC ON PC.ID = P.ProductCategoryID
JOIN ServiceRequestStatus SRS ON SRS.ID = SR.ServiceRequestStatusID
WHERE M.MembershipID = @MembershipID
ORDER BY SR.ID DESC
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults
SELECT 
	T.RequestNumber,
	T.RequestDate,
	T.MemberName,
	T.ServiceType,
	T.Status,
	T.Vehicle,
	T.POCount
FROM @FinalResults_Temp T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.RequestNumberOperator = -1 ) 
 OR 
	 ( TMP.RequestNumberOperator = 0 AND T.RequestNumber IS NULL ) 
 OR 
	 ( TMP.RequestNumberOperator = 1 AND T.RequestNumber IS NOT NULL ) 
 OR 
	 ( TMP.RequestNumberOperator = 2 AND T.RequestNumber = TMP.RequestNumberValue ) 
 OR 
	 ( TMP.RequestNumberOperator = 3 AND T.RequestNumber <> TMP.RequestNumberValue ) 
 OR 
	 ( TMP.RequestNumberOperator = 7 AND T.RequestNumber > TMP.RequestNumberValue ) 
 OR 
	 ( TMP.RequestNumberOperator = 8 AND T.RequestNumber >= TMP.RequestNumberValue ) 
 OR 
	 ( TMP.RequestNumberOperator = 9 AND T.RequestNumber < TMP.RequestNumberValue ) 
 OR 
	 ( TMP.RequestNumberOperator = 10 AND T.RequestNumber <= TMP.RequestNumberValue ) 

 ) 

 AND 

 ( 
	 ( TMP.RequestDateOperator = -1 ) 
 OR 
	 ( TMP.RequestDateOperator = 0 AND T.RequestDate IS NULL ) 
 OR 
	 ( TMP.RequestDateOperator = 1 AND T.RequestDate IS NOT NULL ) 
 OR 
	 ( TMP.RequestDateOperator = 2 AND T.RequestDate = TMP.RequestDateValue ) 
 OR 
	 ( TMP.RequestDateOperator = 3 AND T.RequestDate <> TMP.RequestDateValue ) 
 OR 
	 ( TMP.RequestDateOperator = 7 AND T.RequestDate > TMP.RequestDateValue ) 
 OR 
	 ( TMP.RequestDateOperator = 8 AND T.RequestDate >= TMP.RequestDateValue ) 
 OR 
	 ( TMP.RequestDateOperator = 9 AND T.RequestDate < TMP.RequestDateValue ) 
 OR 
	 ( TMP.RequestDateOperator = 10 AND T.RequestDate <= TMP.RequestDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.MemberNameOperator = -1 ) 
 OR 
	 ( TMP.MemberNameOperator = 0 AND T.MemberName IS NULL ) 
 OR 
	 ( TMP.MemberNameOperator = 1 AND T.MemberName IS NOT NULL ) 
 OR 
	 ( TMP.MemberNameOperator = 2 AND T.MemberName = TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 3 AND T.MemberName <> TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 4 AND T.MemberName LIKE TMP.MemberNameValue + '%') 
 OR 
	 ( TMP.MemberNameOperator = 5 AND T.MemberName LIKE '%' + TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 6 AND T.MemberName LIKE '%' + TMP.MemberNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ServiceTypeOperator = -1 ) 
 OR 
	 ( TMP.ServiceTypeOperator = 0 AND T.ServiceType IS NULL ) 
 OR 
	 ( TMP.ServiceTypeOperator = 1 AND T.ServiceType IS NOT NULL ) 
 OR 
	 ( TMP.ServiceTypeOperator = 2 AND T.ServiceType = TMP.ServiceTypeValue ) 
 OR 
	 ( TMP.ServiceTypeOperator = 3 AND T.ServiceType <> TMP.ServiceTypeValue ) 
 OR 
	 ( TMP.ServiceTypeOperator = 4 AND T.ServiceType LIKE TMP.ServiceTypeValue + '%') 
 OR 
	 ( TMP.ServiceTypeOperator = 5 AND T.ServiceType LIKE '%' + TMP.ServiceTypeValue ) 
 OR 
	 ( TMP.ServiceTypeOperator = 6 AND T.ServiceType LIKE '%' + TMP.ServiceTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.StatusOperator = -1 ) 
 OR 
	 ( TMP.StatusOperator = 0 AND T.Status IS NULL ) 
 OR 
	 ( TMP.StatusOperator = 1 AND T.Status IS NOT NULL ) 
 OR 
	 ( TMP.StatusOperator = 2 AND T.Status = TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 3 AND T.Status <> TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 4 AND T.Status LIKE TMP.StatusValue + '%') 
 OR 
	 ( TMP.StatusOperator = 5 AND T.Status LIKE '%' + TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 6 AND T.Status LIKE '%' + TMP.StatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VehicleOperator = -1 ) 
 OR 
	 ( TMP.VehicleOperator = 0 AND T.Vehicle IS NULL ) 
 OR 
	 ( TMP.VehicleOperator = 1 AND T.Vehicle IS NOT NULL ) 
 OR 
	 ( TMP.VehicleOperator = 2 AND T.Vehicle = TMP.VehicleValue ) 
 OR 
	 ( TMP.VehicleOperator = 3 AND T.Vehicle <> TMP.VehicleValue ) 
 OR 
	 ( TMP.VehicleOperator = 4 AND T.Vehicle LIKE TMP.VehicleValue + '%') 
 OR 
	 ( TMP.VehicleOperator = 5 AND T.Vehicle LIKE '%' + TMP.VehicleValue ) 
 OR 
	 ( TMP.VehicleOperator = 6 AND T.Vehicle LIKE '%' + TMP.VehicleValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.POCountOperator = -1 ) 
 OR 
	 ( TMP.POCountOperator = 0 AND T.POCount IS NULL ) 
 OR 
	 ( TMP.POCountOperator = 1 AND T.POCount IS NOT NULL ) 
 OR 
	 ( TMP.POCountOperator = 2 AND T.POCount = TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 3 AND T.POCount <> TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 7 AND T.POCount > TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 8 AND T.POCount >= TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 9 AND T.POCount < TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 10 AND T.POCount <= TMP.POCountValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'ASC'
	 THEN T.RequestNumber END ASC, 
	 CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'DESC'
	 THEN T.RequestNumber END DESC ,

	 CASE WHEN @sortColumn = 'RequestDate' AND @sortOrder = 'ASC'
	 THEN T.RequestDate END ASC, 
	 CASE WHEN @sortColumn = 'RequestDate' AND @sortOrder = 'DESC'
	 THEN T.RequestDate END DESC ,

	 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'
	 THEN T.MemberName END ASC, 
	 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'
	 THEN T.MemberName END DESC ,

	 CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'ASC'
	 THEN T.ServiceType END ASC, 
	 CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'DESC'
	 THEN T.ServiceType END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC ,

	 CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'ASC'
	 THEN T.Vehicle END ASC, 
	 CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'DESC'
	 THEN T.Vehicle END DESC ,

	 CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'
	 THEN T.POCount END ASC, 
	 CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'
	 THEN T.POCount END DESC 


DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM @FinalResults
SET @endInd = @startInd + @pageSize - 1
IF @startInd  > @count   
BEGIN   
	DECLARE @numOfPages INT    
	SET @numOfPages = @count / @pageSize   
	IF @count % @pageSize > 1   
	BEGIN   
		SET @numOfPages = @numOfPages + 1   
	END   
	SET @startInd = ((@numOfPages - 1) * @pageSize) + 1   
	SET @endInd = @numOfPages * @pageSize   
END

SELECT @count AS TotalRows, * FROM @FinalResults WHERE RowNum BETWEEN @startInd AND @endInd

DROP TABLE #tmpForWhereClause
END

GO
/*******************
* Operator Enums 
*  Conditions Enum :
* -1 - No filter
*  0 - Null
*  1 - Not Null
*  2 - Equals
*  3 - NotEquals
*  ---- for strings ---
*  4 - StartsWith
*  5 - EndsWith
*  6 - Contains
*  ---- for int, decimal, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Member_Management_SR_History_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_Management_SR_History_Get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_Member_Mangement_SR_History_Get @MemberID=3
 CREATE PROCEDURE [dbo].[dms_Member_Management_SR_History_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @MemberID INT = NULL 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
RequestNumberOperator="-1" 
RequestDateOperator="-1" 
MemberNameOperator="-1" 
ServiceTypeOperator="-1" 
StatusOperator="-1" 
VehicleOperator="-1" 
POCountOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
RequestNumberOperator INT NOT NULL,
RequestNumberValue int NULL,
RequestDateOperator INT NOT NULL,
RequestDateValue datetime NULL,
MemberNameOperator INT NOT NULL,
MemberNameValue nvarchar(100) NULL,
ServiceTypeOperator INT NOT NULL,
ServiceTypeValue nvarchar(100) NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL,
VehicleOperator INT NOT NULL,
VehicleValue nvarchar(100) NULL,
POCountOperator INT NOT NULL,
POCountValue int NULL
)
 DECLARE @FinalResults AS TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	RequestNumber int  NULL ,
	RequestDate datetime  NULL ,
	MemberName nvarchar(100)  NULL ,
	ServiceType nvarchar(100)  NULL ,
	Status nvarchar(100)  NULL ,
	Vehicle nvarchar(100)  NULL ,
	POCount int  NULL 
) 
DECLARE @FinalResults_Temp AS TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	RequestNumber int  NULL ,
	RequestDate datetime  NULL ,
	MemberName nvarchar(100)  NULL ,
	ServiceType nvarchar(100)  NULL ,
	Status nvarchar(100)  NULL ,
	Vehicle nvarchar(100)  NULL ,
	POCount int  NULL 
)

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@RequestNumberOperator','INT'),-1),
	T.c.value('@RequestNumberValue','int') ,
	ISNULL(T.c.value('@RequestDateOperator','INT'),-1),
	T.c.value('@RequestDateValue','datetime') ,
	ISNULL(T.c.value('@MemberNameOperator','INT'),-1),
	T.c.value('@MemberNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ServiceTypeOperator','INT'),-1),
	T.c.value('@ServiceTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleOperator','INT'),-1),
	T.c.value('@VehicleValue','nvarchar(100)') ,
	ISNULL(T.c.value('@POCountOperator','INT'),-1),
	T.c.value('@POCountValue','int') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

INSERT INTO @FinalResults_Temp

SELECT SR.ID AS RequestNumber
	, CONVERT(VARCHAR(10),SR.CreateDate,101) AS RequestDate
	, REPLACE(RTRIM(
		COALESCE(M.Firstname, '')+
		COALESCE(' ' + M.MiddleName, '')+
		COALESCE(' ' + M.LastName, '')+
		COALESCE(' ' + M.Suffix, '')
	  ),'','') AS MemberName
	, PC.Name AS ServiceType
	, SRS.Name AS Status
	, REPLACE(RTRIM(
		COALESCE(C.VehicleYear, '')+
		COALESCE(' ' + CASE WHEN C.VehicleMake = 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END, '')+
		COALESCE(' ' + CASE WHEN C.VehicleModel = 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END, '')
	  ),'','') AS Vehicle
	, (SELECT COUNT(*) FROM PurchaseOrder WHERE IsActive = 1 AND ServiceRequestID = SR.ID) AS POCount
FROM ServiceRequest SR
JOIN [Case] C ON C.ID = SR.CaseID
JOIN Member M ON M.ID = C.MemberID
LEFT JOIN Product P ON P.ID = SR.PrimaryProductID
LEFT JOIN ProductCategory PC ON PC.ID = P.ProductCategoryID
JOIN ServiceRequestStatus SRS ON SRS.ID = SR.ServiceRequestStatusID
WHERE M.ID = @MemberID
ORDER BY SR.ID DESC
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults
SELECT 
	T.RequestNumber,
	T.RequestDate,
	T.MemberName,
	T.ServiceType,
	T.Status,
	T.Vehicle,
	T.POCount
FROM @FinalResults_Temp T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.RequestNumberOperator = -1 ) 
 OR 
	 ( TMP.RequestNumberOperator = 0 AND T.RequestNumber IS NULL ) 
 OR 
	 ( TMP.RequestNumberOperator = 1 AND T.RequestNumber IS NOT NULL ) 
 OR 
	 ( TMP.RequestNumberOperator = 2 AND T.RequestNumber = TMP.RequestNumberValue ) 
 OR 
	 ( TMP.RequestNumberOperator = 3 AND T.RequestNumber <> TMP.RequestNumberValue ) 
 OR 
	 ( TMP.RequestNumberOperator = 7 AND T.RequestNumber > TMP.RequestNumberValue ) 
 OR 
	 ( TMP.RequestNumberOperator = 8 AND T.RequestNumber >= TMP.RequestNumberValue ) 
 OR 
	 ( TMP.RequestNumberOperator = 9 AND T.RequestNumber < TMP.RequestNumberValue ) 
 OR 
	 ( TMP.RequestNumberOperator = 10 AND T.RequestNumber <= TMP.RequestNumberValue ) 

 ) 

 AND 

 ( 
	 ( TMP.RequestDateOperator = -1 ) 
 OR 
	 ( TMP.RequestDateOperator = 0 AND T.RequestDate IS NULL ) 
 OR 
	 ( TMP.RequestDateOperator = 1 AND T.RequestDate IS NOT NULL ) 
 OR 
	 ( TMP.RequestDateOperator = 2 AND T.RequestDate = TMP.RequestDateValue ) 
 OR 
	 ( TMP.RequestDateOperator = 3 AND T.RequestDate <> TMP.RequestDateValue ) 
 OR 
	 ( TMP.RequestDateOperator = 7 AND T.RequestDate > TMP.RequestDateValue ) 
 OR 
	 ( TMP.RequestDateOperator = 8 AND T.RequestDate >= TMP.RequestDateValue ) 
 OR 
	 ( TMP.RequestDateOperator = 9 AND T.RequestDate < TMP.RequestDateValue ) 
 OR 
	 ( TMP.RequestDateOperator = 10 AND T.RequestDate <= TMP.RequestDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.MemberNameOperator = -1 ) 
 OR 
	 ( TMP.MemberNameOperator = 0 AND T.MemberName IS NULL ) 
 OR 
	 ( TMP.MemberNameOperator = 1 AND T.MemberName IS NOT NULL ) 
 OR 
	 ( TMP.MemberNameOperator = 2 AND T.MemberName = TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 3 AND T.MemberName <> TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 4 AND T.MemberName LIKE TMP.MemberNameValue + '%') 
 OR 
	 ( TMP.MemberNameOperator = 5 AND T.MemberName LIKE '%' + TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 6 AND T.MemberName LIKE '%' + TMP.MemberNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ServiceTypeOperator = -1 ) 
 OR 
	 ( TMP.ServiceTypeOperator = 0 AND T.ServiceType IS NULL ) 
 OR 
	 ( TMP.ServiceTypeOperator = 1 AND T.ServiceType IS NOT NULL ) 
 OR 
	 ( TMP.ServiceTypeOperator = 2 AND T.ServiceType = TMP.ServiceTypeValue ) 
 OR 
	 ( TMP.ServiceTypeOperator = 3 AND T.ServiceType <> TMP.ServiceTypeValue ) 
 OR 
	 ( TMP.ServiceTypeOperator = 4 AND T.ServiceType LIKE TMP.ServiceTypeValue + '%') 
 OR 
	 ( TMP.ServiceTypeOperator = 5 AND T.ServiceType LIKE '%' + TMP.ServiceTypeValue ) 
 OR 
	 ( TMP.ServiceTypeOperator = 6 AND T.ServiceType LIKE '%' + TMP.ServiceTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.StatusOperator = -1 ) 
 OR 
	 ( TMP.StatusOperator = 0 AND T.Status IS NULL ) 
 OR 
	 ( TMP.StatusOperator = 1 AND T.Status IS NOT NULL ) 
 OR 
	 ( TMP.StatusOperator = 2 AND T.Status = TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 3 AND T.Status <> TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 4 AND T.Status LIKE TMP.StatusValue + '%') 
 OR 
	 ( TMP.StatusOperator = 5 AND T.Status LIKE '%' + TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 6 AND T.Status LIKE '%' + TMP.StatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VehicleOperator = -1 ) 
 OR 
	 ( TMP.VehicleOperator = 0 AND T.Vehicle IS NULL ) 
 OR 
	 ( TMP.VehicleOperator = 1 AND T.Vehicle IS NOT NULL ) 
 OR 
	 ( TMP.VehicleOperator = 2 AND T.Vehicle = TMP.VehicleValue ) 
 OR 
	 ( TMP.VehicleOperator = 3 AND T.Vehicle <> TMP.VehicleValue ) 
 OR 
	 ( TMP.VehicleOperator = 4 AND T.Vehicle LIKE TMP.VehicleValue + '%') 
 OR 
	 ( TMP.VehicleOperator = 5 AND T.Vehicle LIKE '%' + TMP.VehicleValue ) 
 OR 
	 ( TMP.VehicleOperator = 6 AND T.Vehicle LIKE '%' + TMP.VehicleValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.POCountOperator = -1 ) 
 OR 
	 ( TMP.POCountOperator = 0 AND T.POCount IS NULL ) 
 OR 
	 ( TMP.POCountOperator = 1 AND T.POCount IS NOT NULL ) 
 OR 
	 ( TMP.POCountOperator = 2 AND T.POCount = TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 3 AND T.POCount <> TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 7 AND T.POCount > TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 8 AND T.POCount >= TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 9 AND T.POCount < TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 10 AND T.POCount <= TMP.POCountValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'ASC'
	 THEN T.RequestNumber END ASC, 
	 CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'DESC'
	 THEN T.RequestNumber END DESC ,

	 CASE WHEN @sortColumn = 'RequestDate' AND @sortOrder = 'ASC'
	 THEN T.RequestDate END ASC, 
	 CASE WHEN @sortColumn = 'RequestDate' AND @sortOrder = 'DESC'
	 THEN T.RequestDate END DESC ,

	 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'
	 THEN T.MemberName END ASC, 
	 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'
	 THEN T.MemberName END DESC ,

	 CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'ASC'
	 THEN T.ServiceType END ASC, 
	 CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'DESC'
	 THEN T.ServiceType END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC ,

	 CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'ASC'
	 THEN T.Vehicle END ASC, 
	 CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'DESC'
	 THEN T.Vehicle END DESC ,

	 CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'
	 THEN T.POCount END ASC, 
	 CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'
	 THEN T.POCount END DESC 


DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM @FinalResults
SET @endInd = @startInd + @pageSize - 1
IF @startInd  > @count   
BEGIN   
	DECLARE @numOfPages INT    
	SET @numOfPages = @count / @pageSize   
	IF @count % @pageSize > 1   
	BEGIN   
		SET @numOfPages = @numOfPages + 1   
	END   
	SET @startInd = ((@numOfPages - 1) * @pageSize) + 1   
	SET @endInd = @numOfPages * @pageSize   
END

SELECT @count AS TotalRows, * FROM @FinalResults WHERE RowNum BETWEEN @startInd AND @endInd

DROP TABLE #tmpForWhereClause
END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Users_Or_Roles_For_Notification_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Users_Or_Roles_For_Notification_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dms_Users_Or_Roles_For_Notification_Get] 2
 CREATE PROCEDURE [dbo].[dms_Users_Or_Roles_For_Notification_Get](
 @recipientTypeID INT = NULL
 )
 AS
 BEGIN
 DECLARE @ApplicationID UNIQUEIDENTIFIER
 DECLARE @RolesInAddNotificationList NVARCHAR(100)
 DECLARE @Role NVARCHAR(100)
 SET @RolesInAddNotificationList =(SELECT Value FROM ApplicationConfiguration WHERE Name = 'RolesInAddNotificationList')
 SET @ApplicationID = (SELECT ApplicationId FROM aspnet_Applications where ApplicationName='DMS')
 
	 IF ( @recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'User') )
	 BEGIN
	 
		;WITH wUsers
		AS
		(
			SELECT	U.UserId AS ID,
					U.UserName AS Name,
					[dbo].[fnIsUserConnected](U.UserName) AS IsConnected
			FROM aspnet_Users U WITH (NOLOCK)
			WHERE U.ApplicationId = @ApplicationID		
		)
		
		SELECT	W.ID,
				W.Name
		FROM	wUsers W 
		WHERE	W.IsConnected = 1
	 
	 END
	 ELSE IF (@recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'Role') )
	 BEGIN
		
		if LEN(@RolesInAddNotificationList) > 0 SET @RolesInAddNotificationList = @RolesInAddNotificationList + ',' 
		CREATE TABLE #tempResults(role VARCHAR(100))

		WHILE LEN(@RolesInAddNotificationList) > 0 
		BEGIN
		   SELECT @Role = LTRIM(SUBSTRING(@RolesInAddNotificationList, 1, CHARINDEX(',', @RolesInAddNotificationList) - 1))
		   INSERT INTO #tempResults (role) VALUES (@Role)
		   SELECT @RolesInAddNotificationList = SUBSTRING(@RolesInAddNotificationList, CHARINDEX(',', @RolesInAddNotificationList) + 1, LEN(@RolesInAddNotificationList))
		END
		
		SELECT	R.RoleId AS ID,
						R.RoleName AS Name		
				FROM	aspnet_Roles R WITH (NOLOCK)
				WHERE	R.ApplicationId = @ApplicationID
				AND     R.RoleName IN (select role from #tempResults)
		DROP TABLE #tempResults
		 
	 END
 END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_tempcc_match_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_tempcc_match_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vendor_tempcc_match_update] @tempccIdXML = '<Tempcc><ID>1</ID><ID>2</ID><ID>3</ID><ID>4</ID></Tempcc>',@currentUser = 'demouser'
 CREATE PROCEDURE [dbo].[dms_vendor_tempcc_match_update](
	@tempccIdXML XML,
	@currentUser NVARCHAR(50)
  )
 AS
 BEGIN
 
    SET FMTONLY OFF
	SET NOCOUNT ON

	DECLARE @now DATETIME = GETDATE()
	DECLARE @CCExpireDays int = 30
	DECLARE @MinCreateDate datetime

	DECLARE @Matched INT =0
		,@MatchedAmount money =0
		,@Unmatched int = 0
		,@UnmatchedAmount money = 0
		,@Posted INT=0
		,@PostedAmount money=0
		,@Cancelled INT=0
		,@CancelledAmount money=0
		,@Exception INT=0
		,@ExceptionAmount money=0
		,@MatchedIds nvarchar(max)=''

	DECLARE @MatchedTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Matched')
		,@UnMatchedTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'UnMatched')
		,@PostededTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Posted')
		,@CancelledTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Cancelled')
		,@ExceptionTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Exception')

	-- Build table of selected items
	CREATE TABLE #SelectedTemporaryCC 
	(	
		ID INT IDENTITY(1,1),
		TemporaryCreditCardID INT
	)

	INSERT INTO #SelectedTemporaryCC
	SELECT tcc.ID
	FROM TemporaryCreditCard tcc WITH (NOLOCK)
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @tempccIdXML.nodes('/Tempcc/ID') T(c)
			) T ON tcc.ID = T.ID

	CREATE CLUSTERED INDEX IDX_SelectedTemporaryCC ON #SelectedTemporaryCC(TemporaryCreditCardID)

		
	/**************************************************************************************************/
	-- Update (Reset) Selected items to Unmatched where status is not Posted
	UPDATE tc SET 
		TemporaryCreditCardStatusID = @UnmatchedTemporaryCreditCardStatusID
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = NULL
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	WHERE tcs.Name <> 'Posted'


	/**************************************************************************************************/
	--Update for Exact match on PO# and CC#
	--Conditions:
	--	PO# AND CC# match exactly
	--	PO Status is Issued or Issued Paid
	--	PO has not been deleted
	--	PO does not already have a related Vendor Invoice
	--	Temporary CC has not already been posted
	--Match Status
	--	Total CC charge amount LESS THAN or EQUAL to the PO amount
	--Exception Status
	--	Total CC charge amount GREATER THAN the PO amount
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE
				 --Cancelled 
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Cancelled', 'Issued', 'Issued-Paid')) 
						AND vi.ID IS NULL 
						AND (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
						AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN @CancelledTemporaryCreditCardStatusID
				 --Matched
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > 0
                        AND (ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount
                              OR ISNULL(tc.IsExceptionOverride,0) = 1)
					THEN @MatchedTemporaryCreditCardStatusID
				 --Cancelled	
				 WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN @CancelledTemporaryCreditCardStatusID
				 --Exception
				 ELSE @ExceptionTemporaryCreditCardStatusID
				 END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				 --Cancelled 
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Cancelled', 'Issued', 'Issued-Paid')) 
						AND vi.ID IS NULL 
						AND (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
						AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN NULL
				 --Matched
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > 0
                        AND (ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount
                              OR ISNULL(tc.IsExceptionOverride,0) = 1)
					THEN NULL
				 --Exception: PO has not been charged
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) = 0
					THEN 'Credit card has not been charged by the vendor'
				 --Exception: Charge more than PO Amount
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > po.PurchaseOrderAmount 
					THEN 'Charge amount exceeds PO amount'
				 --Cancelled	
				 WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN NULL
				 -- Other Exceptions	
				 WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 ELSE NULL
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = RIGHT(tc.CreditCardNumber,5)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID and vi.IsActive = 1
	WHERE 1=1
	AND tcs.Name = 'Unmatched'
		
		
		
	/**************************************************************************************************/
	-- Update For No matches on PO# or CC#
	-- Conditions:
	--	No potential PO matches exist
	--  No potential CC# matches exist
	-- Cancelled Status
	--	Temporary Credit Card Issue Status is Cancelled
	-- Exception Status
	--	Temporary Credit Card Issue Status is NOT Cancelled
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE 
				WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN @CancelledTemporaryCreditCardStatusID
				ELSE @ExceptionTemporaryCreditCardStatusID
				END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN NULL
				ELSE 'No matching PO# or CC#'
				END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	WHERE  1=1
	AND tcs.Name = 'Unmatched'
	AND NOT EXISTS (
		SELECT *
		FROM PurchaseOrder po
		WHERE
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		)
	AND NOT EXISTS (
		SELECT *
		FROM PurchaseOrder po
		WHERE  
		po.PurchaseOrderNumber <> LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND po.CompanyCreditCardNumber IS NOT NULL
		AND RIGHT(RTRIM(po.CompanyCreditCardNumber),5) = RIGHT(tc.CreditCardNumber,5)
		)


	/**************************************************************************************************/
	--Update to Exception Status - PO matches and CC# does not match
	-- Conditions
	--	PO# matches exactly
	--	CC# does not match or is blank
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE
				WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN @CancelledTemporaryCreditCardStatusID
				WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN @CancelledTemporaryCreditCardStatusID
				ELSE @ExceptionTemporaryCreditCardStatusID
				END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				 --Cancelled	
				 WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN NULL
				 WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN NULL
				 --Exceptions
				 WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 WHEN RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = '' THEN 'Matching PO does not have a credit card number'
				 ELSE 'CC# Mismatch'
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND	RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) <> RIGHT(tc.CreditCardNumber,5)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID and vi.IsActive = 1
	where tcs.Name = 'Unmatched'


	/**************************************************************************************************/
	--Update to Exception Status - PO does not match and CC# matches
	-- Conditions
	--	PO# does not match
	--	CC# matches exactly
	UPDATE tc SET
		TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 ELSE 'PO# Mismatch'
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber <> LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND	RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = RIGHT(tc.CreditCardNumber,5)
		AND po.CreateDate >= DATEADD(dd,1,tc.IssueDate)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID and vi.IsActive = 1
	where tcs.Name = 'Unmatched'


	/**************************************************************************************************/
	-- Prepare Results
	SELECT 
		@Matched = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @MatchedTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@MatchedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @MatchedTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Unmatched = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @UnMatchedTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@UnmatchedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @UnMatchedTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Posted = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @PostededTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@PostedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @PostededTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Cancelled = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @CancelledTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@CancelledAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @CancelledTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Exception = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@ExceptionAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID

	-- Build string of 'Matched' IDs
	SELECT @MatchedIds = @MatchedIds + CONVERT(varchar(20),tc.ID) + ',' 
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	WHERE tc.TemporaryCreditCardStatusID = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Matched')

	-- Remove ending comma from string or IDs
	IF LEN(@MatchedIds) > 1 
		SET @MatchedIds = LEFT(@MatchedIds, LEN(@MatchedIds) - 1)

	DROP TABLE #SelectedTemporaryCC
	
	SELECT @Matched 'MatchedCount',
		   @MatchedAmount 'MatchedAmount',
		   --@Unmatched 'UnmatchedCount',
		   --@UnmatchedAmount 'UnmatchedAmount',
		   @Posted 'PostedCount',
		   @PostedAmount 'PostedAmount',
		   @Cancelled 'CancelledCount',
		   @CancelledAmount 'CancelledAmount',
		   @Exception 'ExceptionCount',
		   @ExceptionAmount 'ExceptionAmount',
		   @MatchedIds 'MatchedIds'
END


GO
