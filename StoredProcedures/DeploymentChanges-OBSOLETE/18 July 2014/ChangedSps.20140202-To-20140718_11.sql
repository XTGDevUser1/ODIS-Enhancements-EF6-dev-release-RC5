IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ManualNotification_Event_Log]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ManualNotification_Event_Log] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_ManualNotification_Event_Log] 'SSMS','SSMS','Manual notification','kbanda',1,'AE05306D-492D-4944-B8BA-8E90BE11F393,BEB5FA18-50CE-499D-BB62-FFB9585242AB'
CREATE PROCEDURE [dbo].[dms_ManualNotification_Event_Log](
	@eventSource NVARCHAR(255) = NULL,
	@sessionID NVARCHAR(255) = NULL,
	@message NVARCHAR(MAX) = NULL,
	@createBy NVARCHAR(50) = NULL,
	@recipientTypeID INT = NULL,
	@autoCloseDelay INT = 0,
	@toUserOrRoleIDs NVARCHAR(MAX) = NULL -- CSV of ASPNET_UserIds / RoleIds
)
AS
BEGIN
 
	DECLARE @tmpUsers TABLE
	(
		ID INT IDENTITY(1,1),
		UserID INT NULL,
		aspnet_UserID UNIQUEIDENTIFIER NULL
	)

	DECLARE @eventLogID INT,
			@idx INT = 1,
			@maxRows INT = 0,
			@userEntityID INT

	SET @userEntityID = (SELECT ID FROM Entity WHERE Name = 'User')

	SET @message =	REPLACE( REPLACE( REPLACE(REPLACE(@message,'&','&amp;'),'<','&lt;'), '>','&gt;'),'''','&quot;')

	IF ( @recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'User') )
	BEGIN
		
		INSERT INTO @tmpUsers (UserID, aspnet_UserID)
		SELECT	DISTINCT U.ID,
				AU.UserId
		FROM	[dbo].[fnSplitString](@toUserOrRoleIDs,',') T
		JOIN	aspnet_Users AU WITH (NOLOCK) ON T.item = AU.UserId
		JOIN	[User] U WITH (NOLOCK) ON  U.aspnet_UserID = AU.UserId
		

	END
	ELSE IF (@recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'Role'))
	BEGIN

		INSERT INTO @tmpUsers (UserID, aspnet_UserID)
		SELECT	DISTINCT U.ID,
				AU.UserId
		FROM	[dbo].[fnSplitString](@toUserOrRoleIDs,',') T
		JOIN	aspnet_UsersInRoles UIR WITH (NOLOCK) ON T.item = UIR.RoleId
		JOIN	aspnet_Users AU WITH (NOLOCK) ON UIR.UserId = AU.UserId
		JOIN	[User] U WITH (NOLOCK) ON  U.aspnet_UserID = AU.UserId

	END


	INSERT INTO EventLog (	EventID,
							SessionID,
							[Source],
							[Description],
							Data,
							NotificationQueueDate,
							CreateDate,
							CreateBy
						)
	SELECT	(SELECT ID FROM [Event] WHERE Name = 'ManualNotification'),
			@sessionID,
			@eventSource,
			(SELECT [Description] FROM [Event] WHERE Name = 'ManualNotification'),
			'<MessageData><SentFrom>' + ISNULL(@createBy,'') + '</SentFrom><MessageText>' + ISNULL(@message,'') + '</MessageText><AutoClose>' + CONVERT(NVARCHAR(100),ISNULL(@autoCloseDelay,0))  + '</AutoClose></MessageData>',
			NULL,
			GETDATE(),
			@createBy

	SET @eventLogID = SCOPE_IDENTITY()
	SELECT @maxRows = MAX(ID) FROM @tmpUsers

	-- Create EventLogLinks
	WHILE (@idx <= @maxRows)
	BEGIN

		INSERT INTO EventLogLink(	EntityID,
									EventLogID,
									RecordID
								)
		SELECT	@userEntityID,
				@eventLogID,
				T.UserID
		FROM	@tmpUsers T WHERE T.ID = @idx

		SET @idx = @idx + 1

	END

END


GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_map_callHistory]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_map_callHistory]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO

--EXEC dms_map_callHistory 1398
CREATE PROC [dbo].[dms_map_callHistory](@ServiceRequestID AS INT = NULL)  
AS  
BEGIN  
SET FMTONLY  OFF
-- FOR Program Dynamci Values 
-- Sanghi 02.15.2013
;with wprogramDynamicValues AS(
SELECT PDI.Label,
	   PDIVE.Value,
	   PDIVE.RecordID AS 'ContactLogID'
	   FROM ProgramDataItem PDI
JOIN ProgramDataItemValueEntity PDIVE 
ON PDI.ID = PDIVE.ProgramDataItemID
WHERE PDIVE.Value IS NOT NULL AND PDIVE.Value != ''
AND PDIVE.EntityID = (SELECT ID FROM Entity WHERE Name = 'ContactLog')
) SELECT ContactLogID,
	    STUFF((SELECT '|' + CAST(Label AS VARCHAR(MAX))
	    FROM wprogramDynamicValues T1
	    WHERE T1.ContactLogID = T2.ContactLogID
	    FOR  XML path('')),1,1,'' ) as [Question],
	    STUFF((SELECT '|' + CAST(Value AS VARCHAR(MAX))
	    FROM wprogramDynamicValues T1
	    WHERE T1.ContactLogID = T2.ContactLogID
	    FOR  XML path('')),1,1,'' ) as [Answer] 
	    INTO #CustomProgramDynamicValues
	    FROM wprogramDynamicValues T2
	    GROUP BY ContactLogID
	   
SELECT CC.Description AS ContactCategory  
, CL.Company AS CompanyName  
, CL.PhoneNumber AS PhoneNumber  
, CL.TalkedTo AS TalkedTo  
, CL.Comments AS Comments  
, CL.CreateDate AS CreateDate  
, CL.CreateBy AS CreateBy  
, CR.Name AS Reason  
, CA.Name ASAction
, CLL.RecordID AS ServiceRequestID
, VCLL.RecordID AS VendorLocationID
, CPDV.Question
, CPDV.Answer
FROM ContactLog CL  
JOIN ContactLogLink CLL ON CLL.ContactLogID = CL.ID
LEFT OUTER JOIN ContactLogLink VCLL ON VCLL.ContactLogID = CL.ID AND   VCLL.EntityID=((Select ID From Entity Where Name ='VendorLocation')  ) 
JOIN ContactCategory CC ON CC.ID = CL.ContactCategoryID  
JOIN ContactLogReason CLR ON CLR.ContactLogID = CL.ID  
JOIN ContactReason CR ON CR.ID = CLR.ContactReasonID  
JOIN ContactLogAction CLA on CLA.ContactLogID = CL.ID  
JOIN ContactAction CA on CA.ID = CLA.ContactActionID  
LEFT JOIN #CustomProgramDynamicValues CPDV ON CPDV.ContactLogID = CL.ID
WHERE  
CLL.RecordID = @ServiceRequestID AND CLL.EntityID =(Select ID From Entity Where Name ='ServiceRequest')  
AND CC.ID =(Select ID From ContactCategory Where Name ='ServiceLocationSelection')  
ORDER BY  
CL.CreateDate DESC  

DROP TABLE #CustomProgramDynamicValues
END


GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Mobile_Configuration]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Mobile_Configuration] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
CREATE PROC [dbo].[dms_Mobile_Configuration](@programID INT = NULL,  
          @configurationType nvarchar(50) = NULL,  
          @configurationCategory nvarchar(50) = NULL,  
          @callBackNumber nvarchar(50) = NULL,  
          @inBoundCallID INT = NULL,
		  @memberID INT = NULL,
		  @membershipID INT = NULL)  
AS  
BEGIN  
	SET FMTONLY OFF  
	-- Output Values   
	DECLARE @unformattedNumber nvarchar(50) = NULL  
	--DECLARE @memberID nvarchar(50) = NULL  
	--DECLARE @membershipID nvarchar(50) = NULL  
	DECLARE @isMobileEnabled BIT = NULL  
	DECLARE @searchCaseRecords BIT = 1
	DECLARE @appOrgName NVARCHAR(100) = NULL

	-- Temporary Holders  
	DECLARE       @ProgramInformation_Temp TABLE(  
	 Name  NVARCHAR(MAX),  
	 Value NVARCHAR(MAX),  
	 ControlType INT NULL,  
	 DataType NVARCHAR(MAX) NULL,  
	 Sequence INT NULL,
	 ProgramLevel INT NULL)  
	 
	 -- Lakshmi - Added on 7/24/14
	 DECLARE  @GetPrograms_Temp TABLE(  
	 ProgramID INT NULL )  
	 
	 
	 --End
  
	DECLARE @Mobile_CallForService_Temp TABLE(  
	[PKID] [int]  NULL,  
	[MemberNumber] [nvarchar](50) NULL,  
	[GUID] [nvarchar](50) NULL,  
	[FirstName] [nvarchar](50) NULL,  
	[LastName] [nvarchar](50) NULL,  
	[MemberDevicePhoneNumber] [nvarchar](20) NULL,  
	[locationLatitude] [nvarchar](10) NULL,  
	[locationLongtitude] [nvarchar](10) NULL,  
	[serviceType] [nvarchar](100) NULL,  
	[ErrorCode] [int] NULL,  
	[ErrorMessage] [nvarchar](200) NULL,  
	[DateTime] [datetime] NULL,  
	[IsMobileEnabled] BIT,  
	[MemberID] INT,  
	[MembershipID] INT)  
 

	IF ( @memberID IS NOT NULL)
	BEGIN
		
		UPDATE	InboundCall 
		SET		MemberID = @memberID   		
		WHERE	ID = @inBoundCallID 


		INSERT INTO @Mobile_CallForService_Temp
						([MemberID],[MembershipID],[IsMobileEnabled]) 
		VALUES(@memberID,@membershipID,@isMobileEnabled) 

	END
	ELSE
	BEGIN


		DECLARE @charIndex INT = 0  
		SELECT @charIndex = CHARINDEX('x',@callBackNumber,0)  

		IF @charIndex = 0  
		BEGIN  
			SET @charIndex = LEN(@callBackNumber)  
		END  
		ELSE  
		BEGIN  
			SET @charIndex = @charIndex -1  
		END  

	-- DEBUG:
	--PRINT @charIndex  

		SELECT @unformattedNumber = SUBSTRING(@callBackNumber,1,@charIndex)  
		SET @charIndex = 0  
		SELECT @charIndex = CHARINDEX(' ',@unformattedNumber,0)  
		--SELECT @callBackNumber  
		SELECT @unformattedNumber = LTRIM(RTRIM(SUBSTRING(@unformattedNumber, @charIndex + 1, LEN(@unformattedNumber) - @charIndex)))  

	--DEBUG:
	--SELECT @unformattedNumber As UnformattedNumber, @callBackNumber AS CallbackNumber

 
	-- Step 1 : Get the Program Information  
		;with wResultB AS  
		(    
			SELECT PC.Name,     
			PC.Value,     
			CT.Name AS ControlType,     
			DT.Name AS DataType,      
			PC.Sequence AS Sequence	,
			ROW_NUMBER() OVER ( PARTITION BY PC.Name ORDER BY PP.Sequence) AS [ProgramLevel]			    
			FROM ProgramConfiguration PC    
			 JOIN dbo.fnc_GetProgramsandParents(@programID)PP ON PP.ProgramID=PC.ProgramID    
			 JOIN [dbo].[fnc_GetProgramConfigurationForProgram](@programID,@configurationType) P ON P.ProgramConfigurationID = PC.ID    
			 LEFT JOIN ControlType CT ON PC.ControlTypeID = CT.ID    
			 LEFT JOIN DataType DT ON PC.DataTypeID = DT.ID    
		)  
		INSERT INTO @ProgramInformation_Temp SELECT * FROM wResultB  ORDER BY ProgramLevel, Sequence, Name   
	
		-- CR : 1225 - Start Tab - change process to lookup mobile phone number to incorporate appOrgName
		SELECT @appOrgName = Value FROM @ProgramInformation_Temp WHERE ProgramLevel = 1 AND Name = 'MobileAppOrg'
	
	--Lakshmi - Added on 7/24/2014
	
	 
	
	INSERT INTO @GetPrograms_Temp ([ProgramID]) 
	((SELECT ProgramID FROM fnc_GetChildPrograms(@programID)
	UNION
	SELECT ProgramID FROM MemberSearchProgramGrouping
	WHERE ProgramID in(SELECT ProgramID FROM fnc_GetChildPrograms(@programID))))
	
	
	--DEBUG:  
	-- SELECT @appOrgName
	--SELECT * FROM @ProgramInformation_Temp  
 
	--Step 2 :  
	-- Check Mobile is Enabled or NOT  
		IF EXISTS(SELECT * FROM @ProgramInformation_Temp WHERE Name = 'IsMobileEnabled' AND Value = 'yes')  
		BEGIN  
		--DEBUG:
		--PRINT 'Mobile config found'
			SET @isMobileEnabled = 1  
			SET @unformattedNumber  =  RTRIM(LTRIM(@unformattedNumber))  
			-- Get the Details FROM Mobile_CallForService  
			SELECT TOP 1 *  INTO #Mobile_CallForService_Temp  
				FROM Mobile_CallForService M  
				WHERE REPLACE(M.MemberDevicePhoneNumber,'-','') = @unformattedNumber  
				AND DATEDIFF(hh,M.[DateTime],GETDATE()) < 1  
				AND ISNULL(M.ErrorCode,0) = 0  
				AND appOrgName = @appOrgName -- CR : 1225 - Start Tab - change process to lookup mobile phone number to incorporate appOrgName
				ORDER BY M.[DateTime] DESC  

 
 
		IF((SELECT COUNT(*) FROM #Mobile_CallForService_Temp) >= 1)  
			BEGIN  
					--DEBUG:
					--PRINT 'Mobile record found'
				
					SET @searchCaseRecords = 0
				
					-- Try to find the member using the member number.
					
					INSERT INTO @Mobile_CallForService_Temp
								([MemberID],[MembershipID],[IsMobileEnabled]) 
					  
						SELECT DISTINCT M.ID, 
						M.MembershipID ,
						@isMobileEnabled
						FROM Membership MS 
						JOIN Member M ON MS.ID = M.MembershipID 
						JOIN Program P ON M.ProgramID=P.ID
						WHERE M.IsPrimary = 1 
						AND MS.MembershipNumber = 
						(SELECT MemberNumber FROM #Mobile_CallForService_Temp where membernumber IS NOT NULL AND memberNumber <> '') 
						AND M.ProgramID IN (SELECT * FROM @GetPrograms_Temp)
  
					
					
					IF((SELECT COUNT(*) FROM @Mobile_CallForService_Temp) = 1) 
			        BEGIN
			        
						UPDATE InboundCall SET MemberID = @memberID,
							 MobileID = (SELECT PKID FROM #Mobile_CallForService_Temp)  
							WHERE ID = @inBoundCallID 

					-- Create a case phone location record when there is lat/long information.
					IF EXISTS(	SELECT * FROM #Mobile_CallForService_Temp   
							WHERE ISNULL(locationLatitude,'') <> ''  
							AND ISNULL(locationLongtitude,'') <> ''  
						)  
					BEGIN
						INSERT INTO CasePhoneLocation(	CaseID,  
														PhoneNumber,  
														CivicLatitude,  
														CivicLongitude,  
														IsSMSAvailable,  
														LocationDate,  
														LocationAccuracy,  
														InboundCallID,  
														PhoneTypeID,  
														CreateDate)   
														VALUES(NULL,  
														@callBackNumber,  
														(SELECT  locationLatitude FROM #Mobile_CallForService_Temp),  
														(SELECT  locationLongtitude FROM #Mobile_CallForService_Temp),  
														1,  
														(SELECT  [DateTime] FROM #Mobile_CallForService_Temp),  
														'mobile',  
														@inBoundCallID,  
														(SELECT ID FROM PhoneType WHERE Name = 'Cell'),  
														GETDATE()  
														)  
					END
					END

					IF((SELECT COUNT(*) FROM @Mobile_CallForService_Temp) > 1)
					BEGIN
					        UPDATE InboundCall 
							SET  MobileID = (SELECT PKID FROM #Mobile_CallForService_Temp)  
							WHERE ID = @inBoundCallID  
					END
				
					IF @memberID IS NULL
					BEGIN
					-- Search in prior cases when you don't get a member using the membernumber from the mobile record.
						SET @searchCaseRecords = 1 
					END
				
					DROP TABLE #Mobile_CallForService_Temp
			
		   END  
	
		IF ( @searchCaseRecords = 1 )  
			BEGIN 
		
		
		    INSERT INTO @Mobile_CallForService_Temp
								([MemberID],[MembershipID],[IsMobileEnabled]) 
				SELECT  DISTINCT M.ID,   
								M.MembershipID,
								@isMobileEnabled
				FROM [Case] C  
				JOIN Member M ON C.MemberID = M.ID 
				JOIN Program P ON M.ProgramID=P.ID		--Lakshmi
				WHERE C.ContactPhoneNumber = @callBackNumber AND M.ProgramID IN (SELECT * FROM @GetPrograms_Temp)  
				ORDER BY ID DESC
					

			IF((SELECT COUNT(*) FROM @Mobile_CallForService_Temp)= 0 OR (SELECT COUNT(*) FROM @Mobile_CallForService_Temp) = 1) 
			BEGIN
						
				UPDATE InboundCall 
				SET MemberID = @memberID   		
				WHERE ID = @inBoundCallID  
			END
		END  
	    END
	           

	SELECT * FROM @Mobile_CallForService_Temp  
          
   
END     
END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Unprocessed_EventLogs_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Unprocessed_EventLogs_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Unprocessed_EventLogs_Get] 
CREATE PROCEDURE [dbo].[dms_Unprocessed_EventLogs_Get]
AS
BEGIN

	SELECT	EL.ID,
			EventID,
			SessionID,
			Source,
			EL.[Description],
			[Data],
			NotificationQueueDate,
			EL.CreateDate,
			EL.CreateBy,			
			EventTypeID,
			EventCategoryID,
			E.Name,
			E.[Description] AS EventDescription
	FROM	[EventLog] EL WITH (NOLOCK) 
	JOIN	[Event] E WITH (NOLOCK) ON EL.EventID = E.ID
	WHERE	NotificationQueueDate IS NULL
	ORDER BY CreateDate ASC
	

END
GO
