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
			@agentUserID INT

	DECLARE @tmpCurrentUser TABLE
			(
				UserId UNIQUEIDENTIFIER NULL,
				UserName NVARCHAR(100) NULL
			)
	
	SELECT  @resendPONextActionID = ID FROM NextAction WITH (NOLOCK) WHERE Name = 'ResendPO'
	
	SELECT	@agentUserID = U.ID
	FROM	[User] U WITH (NOLOCK) 
	JOIN	aspnet_Users AU WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
	JOIN	aspnet_Applications A WITH (NOLOCK) ON A.ApplicationId = AU.ApplicationId
	WHERE	AU.UserName = 'Agent'
	AND		A.ApplicationName = 'DMS'

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
			
			IF ( (SELECT [dbo].[fnIsUserConnected](@CreateByUser) ) = 1)
			BEGIN
				
				INSERT INTO @tmpCurrentUser
				SELECT	AU.UserId,
						AU.UserName
				FROM	aspnet_Users AU WITH (NOLOCK) 
				JOIN	aspnet_Applications A WITH (NOLOCK) ON AU.ApplicationId = A.ApplicationId			
				WHERE	AU.UserName = @CreateByUser
				AND		A.ApplicationName = 'DMS'
				
			END
			ELSE
			BEGIN

				SELECT	@nextActionIDOnSR = SR.NextActionID,
						@nextActionAssignedToOnSR = SR.NextActionAssignedToUserID
				FROM	ServiceRequest SR WITH (NOLOCK) 
				WHERE ID = @ServiceRequest 

				IF @nextActionAssignedToOnSR IS NULL AND @nextActionIDOnSR IS NULL
				BEGIN
					
					UPDATE	ServiceRequest
					SET		NextActionID = @resendPONextActionID,
							NextActionAssignedToUserID = @agentUserID
					WHERE	ID = @ServiceRequest

				END
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
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Notification_History_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Notification_History_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Notification_History_Get] 'demouser'
CREATE PROCEDURE [dbo].[dms_Notification_History_Get](
@userName NVARCHAR(100)
)
AS
BEGIN

	DECLARE @notificationHistoryDisplayHours INT = 48 -- Default value is set to 48.

	SELECT @notificationHistoryDisplayHours = CONVERT(INT,Value) FROM ApplicationConfiguration WHERE Name = 'NotificationHistoryDisplayHours'
	

	SELECT	CL.*
	FROM	CommunicationLog CL WITH (NOLOCK)
	JOIN	ContactMethod CM WITH (NOLOCK) ON CL.ContactMethodID = CM.ID
	WHERE	CL.NotificationRecipient = @userName
	AND		CM.Name = 'DesktopNotification'
	AND		DATEDIFF(HH,CL.CreateDate,GETDATE()) <= @notificationHistoryDisplayHours
	AND		CL.Status = 'SUCCESS'
	ORDER BY CL.CreateDate DESC

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
 WHERE id = object_id(N'[dbo].[dms_Program_Management_ProgramDataItemList]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_ProgramDataItemList] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_Program_Management_ProgramDataItemList] @programID=45
 CREATE PROCEDURE [dbo].[dms_Program_Management_ProgramDataItemList]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID INT = NULL 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
ProgramDataItemIDOperator="-1" 
ScreenNameOperator="-1" 
NameOperator="-1" 
LabelOperator="-1" 
IsActiveOperator="-1" 
ControlTypeOperator="-1" 
DataTypeOperator="-1" 
SequenceOperator="-1" 
IsRequiredOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
ProgramDataItemIDOperator INT NOT NULL,
ProgramDataItemIDValue int NULL,
ScreenNameOperator INT NOT NULL,
ScreenNameValue nvarchar(100) NULL,
NameOperator INT NOT NULL,
NameValue nvarchar(100) NULL,
LabelOperator INT NOT NULL,
LabelValue nvarchar(100) NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue bit NULL,
ControlTypeOperator INT NOT NULL,
ControlTypeValue nvarchar(100) NULL,
DataTypeOperator INT NOT NULL,
DataTypeValue nvarchar(100) NULL,
SequenceOperator INT NOT NULL,
SequenceValue int NULL,
IsRequiredOperator INT NOT NULL,
IsRequiredValue bit NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramDataItemID int  NULL ,
	ScreenName nvarchar(100)  NULL ,
	Name nvarchar(100)  NULL ,
	Label nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	ControlType nvarchar(100)  NULL ,
	DataType nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsRequired bit  NULL 
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramDataItemID int  NULL ,
	ScreenName nvarchar(100)  NULL ,
	Name nvarchar(100)  NULL ,
	Label nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	ControlType nvarchar(100)  NULL ,
	DataType nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsRequired bit  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@ProgramDataItemIDOperator','INT'),-1),
	T.c.value('@ProgramDataItemIDValue','int') ,
	ISNULL(T.c.value('@ScreenNameOperator','INT'),-1),
	T.c.value('@ScreenNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@NameOperator','INT'),-1),
	T.c.value('@NameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@LabelOperator','INT'),-1),
	T.c.value('@LabelValue','nvarchar(100)') ,
	ISNULL(T.c.value('@IsActiveOperator','INT'),-1),
	T.c.value('@IsActiveValue','bit') ,
	ISNULL(T.c.value('@ControlTypeOperator','INT'),-1),
	T.c.value('@ControlTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DataTypeOperator','INT'),-1),
	T.c.value('@DataTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@SequenceOperator','INT'),-1),
	T.c.value('@SequenceValue','int') ,
	ISNULL(T.c.value('@IsRequiredOperator','INT'),-1),
	T.c.value('@IsRequiredValue','bit') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT --ROW_NUMBER() OVER ( PARTITION BY PDI.Name ORDER BY PP.Sequence) AS RowNum,
		PDI.ID ProgramDataItemID,
		PDI.ScreenName,
		PDI.Name,
		PDI.Label,
		PDI.IsActive,--CASE ISNULL(PC.IsActive,0) WHEN 0 THEN 'No' ELSE 'Yes' END IsActiveText,
		CT.[Description] ControlType,
		DT.[Description] DataType,
		PDI.Sequence,
		PDI.IsRequired
FROM fnc_GetProgramsandParents(@ProgramID) PP
JOIN ProgramDataItem PDI ON PP.ProgramID = PDI.ProgramID AND PDI.IsActive = 1	
LEFT JOIN ControlType CT ON CT.ID = PDI.ControlTypeID
LEFT JOIN DataType DT ON DT.ID = PDI.DataTypeID
WHERE PDI.ProgramID=@programID		
INSERT INTO #FinalResults
SELECT 
	T.ProgramDataItemID,
	T.ScreenName,
	T.Name,
	T.Label,
	T.IsActive,
	T.ControlType,
	T.DataType,
	T.Sequence,
	T.IsRequired
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.ProgramDataItemIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 0 AND T.ProgramDataItemID IS NULL ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 1 AND T.ProgramDataItemID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 2 AND T.ProgramDataItemID = TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 3 AND T.ProgramDataItemID <> TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 7 AND T.ProgramDataItemID > TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 8 AND T.ProgramDataItemID >= TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 9 AND T.ProgramDataItemID < TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 10 AND T.ProgramDataItemID <= TMP.ProgramDataItemIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScreenNameOperator = -1 ) 
 OR 
	 ( TMP.ScreenNameOperator = 0 AND T.ScreenName IS NULL ) 
 OR 
	 ( TMP.ScreenNameOperator = 1 AND T.ScreenName IS NOT NULL ) 
 OR 
	 ( TMP.ScreenNameOperator = 2 AND T.ScreenName = TMP.ScreenNameValue ) 
 OR 
	 ( TMP.ScreenNameOperator = 3 AND T.ScreenName <> TMP.ScreenNameValue ) 
 OR 
	 ( TMP.ScreenNameOperator = 4 AND T.ScreenName LIKE TMP.ScreenNameValue + '%') 
 OR 
	 ( TMP.ScreenNameOperator = 5 AND T.ScreenName LIKE '%' + TMP.ScreenNameValue ) 
 OR 
	 ( TMP.ScreenNameOperator = 6 AND T.ScreenName LIKE '%' + TMP.ScreenNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.NameOperator = -1 ) 
 OR 
	 ( TMP.NameOperator = 0 AND T.Name IS NULL ) 
 OR 
	 ( TMP.NameOperator = 1 AND T.Name IS NOT NULL ) 
 OR 
	 ( TMP.NameOperator = 2 AND T.Name = TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 3 AND T.Name <> TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 4 AND T.Name LIKE TMP.NameValue + '%') 
 OR 
	 ( TMP.NameOperator = 5 AND T.Name LIKE '%' + TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 6 AND T.Name LIKE '%' + TMP.NameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LabelOperator = -1 ) 
 OR 
	 ( TMP.LabelOperator = 0 AND T.Label IS NULL ) 
 OR 
	 ( TMP.LabelOperator = 1 AND T.Label IS NOT NULL ) 
 OR 
	 ( TMP.LabelOperator = 2 AND T.Label = TMP.LabelValue ) 
 OR 
	 ( TMP.LabelOperator = 3 AND T.Label <> TMP.LabelValue ) 
 OR 
	 ( TMP.LabelOperator = 4 AND T.Label LIKE TMP.LabelValue + '%') 
 OR 
	 ( TMP.LabelOperator = 5 AND T.Label LIKE '%' + TMP.LabelValue ) 
 OR 
	 ( TMP.LabelOperator = 6 AND T.Label LIKE '%' + TMP.LabelValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.IsActiveOperator = -1 ) 
 OR 
	 ( TMP.IsActiveOperator = 0 AND T.IsActive IS NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 1 AND T.IsActive IS NOT NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 2 AND T.IsActive = TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 3 AND T.IsActive <> TMP.IsActiveValue ) 
 ) 

 AND 

 ( 
	 ( TMP.ControlTypeOperator = -1 ) 
 OR 
	 ( TMP.ControlTypeOperator = 0 AND T.ControlType IS NULL ) 
 OR 
	 ( TMP.ControlTypeOperator = 1 AND T.ControlType IS NOT NULL ) 
 OR 
	 ( TMP.ControlTypeOperator = 2 AND T.ControlType = TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 3 AND T.ControlType <> TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 4 AND T.ControlType LIKE TMP.ControlTypeValue + '%') 
 OR 
	 ( TMP.ControlTypeOperator = 5 AND T.ControlType LIKE '%' + TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 6 AND T.ControlType LIKE '%' + TMP.ControlTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DataTypeOperator = -1 ) 
 OR 
	 ( TMP.DataTypeOperator = 0 AND T.DataType IS NULL ) 
 OR 
	 ( TMP.DataTypeOperator = 1 AND T.DataType IS NOT NULL ) 
 OR 
	 ( TMP.DataTypeOperator = 2 AND T.DataType = TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 3 AND T.DataType <> TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 4 AND T.DataType LIKE TMP.DataTypeValue + '%') 
 OR 
	 ( TMP.DataTypeOperator = 5 AND T.DataType LIKE '%' + TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 6 AND T.DataType LIKE '%' + TMP.DataTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.SequenceOperator = -1 ) 
 OR 
	 ( TMP.SequenceOperator = 0 AND T.Sequence IS NULL ) 
 OR 
	 ( TMP.SequenceOperator = 1 AND T.Sequence IS NOT NULL ) 
 OR 
	 ( TMP.SequenceOperator = 2 AND T.Sequence = TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 3 AND T.Sequence <> TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 7 AND T.Sequence > TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 8 AND T.Sequence >= TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 9 AND T.Sequence < TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 10 AND T.Sequence <= TMP.SequenceValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsRequiredOperator = -1 ) 
 OR 
	 ( TMP.IsRequiredOperator = 0 AND T.IsRequired IS NULL ) 
 OR 
	 ( TMP.IsRequiredOperator = 1 AND T.IsRequired IS NOT NULL ) 
 OR 
	 ( TMP.IsRequiredOperator = 2 AND T.IsRequired = TMP.IsRequiredValue ) 
 OR 
	 ( TMP.IsRequiredOperator = 3 AND T.IsRequired <> TMP.IsRequiredValue ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ProgramDataItemID' AND @sortOrder = 'ASC'
	 THEN T.ProgramDataItemID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramDataItemID' AND @sortOrder = 'DESC'
	 THEN T.ProgramDataItemID END DESC ,

	 CASE WHEN @sortColumn = 'ScreenName' AND @sortOrder = 'ASC'
	 THEN T.ScreenName END ASC, 
	 CASE WHEN @sortColumn = 'ScreenName' AND @sortOrder = 'DESC'
	 THEN T.ScreenName END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Label' AND @sortOrder = 'ASC'
	 THEN T.Label END ASC, 
	 CASE WHEN @sortColumn = 'Label' AND @sortOrder = 'DESC'
	 THEN T.Label END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC ,

	 CASE WHEN @sortColumn = 'ControlType' AND @sortOrder = 'ASC'
	 THEN T.ControlType END ASC, 
	 CASE WHEN @sortColumn = 'ControlType' AND @sortOrder = 'DESC'
	 THEN T.ControlType END DESC ,

	 CASE WHEN @sortColumn = 'DataType' AND @sortOrder = 'ASC'
	 THEN T.DataType END ASC, 
	 CASE WHEN @sortColumn = 'DataType' AND @sortOrder = 'DESC'
	 THEN T.DataType END DESC ,

	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'
	 THEN T.Sequence END ASC, 
	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'
	 THEN T.Sequence END DESC ,

	 CASE WHEN @sortColumn = 'IsRequired' AND @sortOrder = 'ASC'
	 THEN T.IsRequired END ASC, 
	 CASE WHEN @sortColumn = 'IsRequired' AND @sortOrder = 'DESC'
	 THEN T.IsRequired END DESC 


DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM #FinalResults
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

SELECT @count AS TotalRows, * FROM #FinalResults WHERE RowNum BETWEEN @startInd AND @endInd

DROP TABLE #tmpForWhereClause
DROP TABLE #FinalResults
DROP TABLE #tmpFinalResults
END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveDataItemInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveDataItemInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveDataItemInformation]( 
   @id INT = NULL
 , @programID INT = NULL
 , @controlTypeID INT = NULL
 , @dataTypeID INT = NULL
 , @name NVARCHAR(100) = NULL
 , @screenName NVARCHAR(100) = NULL
 , @label NVARCHAR(100) = NULL
 , @maxLength INT = NULL
 , @sequence INT = NULL
 , @isRequired BIT = NULL
 , @isActive BIT = NULL
 , @currentUser NVARCHAR(100) = NULL 
 )
 AS
 BEGIN
 IF @id > 0 
	 BEGIN
		UPDATE ProgramDataItem 
		SET ControlTypeID = @controlTypeID,
			DataTypeID = @dataTypeID,
			Name = @name,
			ScreenName = @screenName,
			Label = @label,
			Sequence = @sequence,
			MaxLength = @maxLength,
			IsRequired = @isRequired,
			IsActive = @isActive,
			ModifyBy = @currentUser,
			ModifyDate = GETDATE()
		WHERE ID = @id
	 END
ELSE
	BEGIN
		INSERT INTO ProgramDataItem (
			ProgramID,
			ControlTypeID,
			DataTypeID,
			Name,
			ScreenName,
			Label,
			Sequence,
			MaxLength,
			IsRequired,
			IsActive,
			CreateBy,
			CreateDate		
		)
		VALUES(
			@programID,
			@controlTypeID,
			@dataTypeID,
			@name,
			@screenName,
			@label,
			@sequence,
			@maxLength,
			@isRequired,
			@isActive,
			@currentUser,
			GETDATE()
		)
	END
END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Services_List_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Services_List_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 --EXEC dms_Vendor_Services_List_Get @VendorID=1
CREATE PROCEDURE dms_Vendor_Services_List_Get @VendorID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
DECLARE @FinalResults AS TABLE(
	SortOrder INT NULL,
	ServiceGroup NVARCHAR(255) NULL,
	ServiceName nvarchar(100)  NULL ,
	ProductID int  NULL ,
	VehicleCategorySequence int  NULL ,
	ProductCategory nvarchar(100)  NULL ,
	IsAvailByVendor bit default 0
) 

INSERT INTO @FinalResults (SortOrder, ServiceGroup,ServiceName,ProductID,VehicleCategorySequence,ProductCategory)
	SELECT 
			 CASE	WHEN vc.name is NULL THEN 2 
					ELSE 1 
			 END AS SortOrder
			,CASE	WHEN vc.name is NULL THEN 'Other' 
					ELSE vc.name 
			 END AS ServiceGroup
			,REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
			--,ISNULL(vc.Name,'') + CASE WHEN ISNULL(vc.Name,'') <> '' THEN ' - ' ELSE '' END  + REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory			
	FROM Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
	LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('PrimaryService', 'SecondaryService')
	AND p.Name Not in ('Concierge', 'Information', 'Tech')
	AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee')

	UNION
	SELECT 
			3 AS SortOrder
			,'Additional' AS ServiceGroup
			,p.Name AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory
	FROM	Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
	LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('AdditionalService')
	AND p.Name Not in ('Concierge', 'Information', 'Tech')
	AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials')	
	
	UNION ALL
	
	SELECT 
			4 AS SortOrder
			,pst.Name AS ServiceGroup 
			,p.Name AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory
	FROM Product p
	Join ProductCategory pc on p.productCategoryid = pc.id
	Join ProductType pt on p.ProductTypeID = pt.ID
	Join ProductSubType pst on p.ProductSubTypeID = pst.id
	Left Outer Join VehicleCategory vc on p.VehicleCategoryID = vc.ID
	Left Outer Join VehicleType vt on p.VehicleTypeID = vt.ID
	Where pt.Name = 'Attribute'
	and pc.Name = 'Repair'
	--and pst.Name NOT IN ('Client')
	ORDER BY SortOrder, VehicleCategorySequence, ProductCategory
	

UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
WHERE VP.VendorID=@VendorID
	
SELECT * FROM @FinalResults

END
GO

GO
