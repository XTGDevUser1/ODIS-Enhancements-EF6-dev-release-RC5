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
 /*
 *	-- KB : Added two parameters - memberID and membershipID.
 *	The stored procedure will be called in two cases:
 *	1. Lookup a mobile  / prior Case record using the callback number
 *	2. The stored procedure might return multiple member records when there are multiple matching Case records.
 *	3. The application allows user to pick one member from a prior case record and this sp would then be invoked just to update the related inbound call record.
 */
CREATE PROC dms_Mobile_Configuration(@programID INT = NULL,  
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
				
					SELECT  @memberID = RR.ID,  
					@membershipID = RR.MembershipID   
					FROM  
					(  
						SELECT TOP 1 M.ID,  
							   M.MembershipID   
							   FROM Membership MS  
							JOIN Member M ON MS.ID = M.MembershipID  
							WHERE M.IsPrimary = 1  
							   AND MS.MembershipNumber =   
						   (SELECT  MemberNumber FROM #Mobile_CallForService_Temp where membernumber IS NOT NULL AND memberNumber <> '')  
					)RR  

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

					IF @memberID IS NOT NULL
					BEGIN
						UPDATE InboundCall SET MemberID = @memberID,   
							 MobileID = (SELECT PKID FROM #Mobile_CallForService_Temp)  
						WHERE ID = @inBoundCallID  
					END
						INSERT INTO @Mobile_CallForService_Temp  
						([PKID],  
						[MemberNumber],  
						[GUID],  
						[FirstName],  
						[LastName],  
						[MemberDevicePhoneNumber],  
						[locationLatitude],  
						[locationLongtitude],  
						[serviceType],  
						[ErrorCode],  
						[ErrorMessage],  
						[DateTime],
						MemberID,
						MembershipID,
						IsMobileEnabled  
						)   
						SELECT	[PKID],  
								[MemberNumber],  
								[GUID],  
								[FirstName],  
								[LastName],  
								[MemberDevicePhoneNumber],  
								[locationLatitude],  
								[locationLongtitude],  
								[serviceType],  
								[ErrorCode],  
								[ErrorMessage],  
								[DateTime],
								@memberID,
								@membershipID,
								@isMobileEnabled
						FROM #Mobile_CallForService_Temp  
				
					IF @memberID IS NULL
					BEGIN
					-- Search in prior cases when you don't get a member using the membernumber from the mobile record.
						SET @searchCaseRecords = 1 
					END
				
				
					DROP TABLE #Mobile_CallForService_Temp
			
		END  
	
		END
	
		IF ( @searchCaseRecords = 1 )  
		BEGIN 
		
			DECLARE @memberRecordCount AS INT 
			SET @memberRecordCount = ISNULL((SELECT COUNT(M.ID)  
										 FROM [Case] C  
										 JOIN Member M ON C.MemberID = M.ID  
										 WHERE C.ContactPhoneNumber = @callBackNumber),0)
		

			IF(@memberRecordCount = 0 OR @memberRecordCount = 1) 
			BEGIN
						--DEBUG:
			--PRINT 'Mobile record not found'
			-- GET THE MEMBER DETAILS BY USING CALL BACK NUMBER  
				SELECT @memberID     = R.ID,  
				@membershipID = R.MembershipID   
				FROM  
				(  
				SELECT TOP 1 M.ID,   
				M.MembershipID  
				FROM [Case] C  
				JOIN Member M ON C.MemberID = M.ID  
				WHERE C.ContactPhoneNumber = @callBackNumber  
				ORDER BY ID DESC
				) R  
			
		
				UPDATE InboundCall 
				SET MemberID = @memberID   		
				WHERE ID = @inBoundCallID  
		
				IF ( (SELECT COUNT(*) FROM @Mobile_CallForService_Temp) > 0)
				BEGIN
					-- We already found location details in the above call, and we found member from prior cases.
					UPDATE @Mobile_CallForService_Temp 
					SET		MemberID = @memberID,
							MembershipID = @membershipID		
			
				END
				ELSE
				BEGIN		
				
					INSERT INTO @Mobile_CallForService_Temp
							([MemberID],[MembershipID],[IsMobileEnabled]) 
					VALUES(@memberID,@membershipID,@isMobileEnabled) 	
				END
			END
			ELSE
			BEGIN
				INSERT INTO @Mobile_CallForService_Temp
								([MemberID],[MembershipID],[IsMobileEnabled]) 
				SELECT    DISTINCT M.ID,   
								M.MembershipID,
								@isMobileEnabled
				FROM [Case] C  
				JOIN Member M ON C.MemberID = M.ID  
				WHERE C.ContactPhoneNumber = @callBackNumber  
				ORDER BY ID DESC
			END
		END  
	END
	           

	SELECT * FROM @Mobile_CallForService_Temp  
          
   
END     

GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Client_OpenPeriodProcess_EventLogs]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Client_OpenPeriodProcess_EventLogs] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 
CREATE PROC dms_Client_OpenPeriodProcess_EventLogs(@userName NVARCHAR(100),
												   @sessionID NVARCHAR(MAX),
												   @pageReference NVARCHAR(MAX),
												   @billingScheduleIDList NVARCHAR(MAX),
												   @billingDefinitionInvoiceIDList NVARCHAR(MAX))
AS
BEGIN
		DECLARE @BillingScheduleList AS TABLE(Serial INT IDENTITY(1,1), BillingScheduleID INT NULL)
		DECLARE @BillingDefinitionList AS TABLE(Serial INT IDENTITY(1,1),BillingDefinitionInvoiceID INT NULL)

		INSERT INTO @BillingScheduleList(BillingScheduleID)			   SELECT DISTINCT item from dbo.fnSplitString(@billingScheduleIDList,',')
		INSERT INTO @BillingDefinitionList(BillingDefinitionInvoiceID) SELECT item from dbo.fnSplitString(@billingDefinitionInvoiceIDList,',')

		DECLARE @scheduleID AS INT
		DECLARE @billingDefinitionID AS INT
	    DECLARE @TotalRows AS INT
		DECLARE @ProcessingCounter AS INT = 1
		SELECT  @TotalRows = MAX(Serial) FROM @BillingScheduleList
		DECLARE @entityID AS INT 
		DECLARE @eventID AS INT
		SELECT  @entityID = ID FROM Entity WHERE Name = 'BillingSchedule'
		SELECT  @eventID =  ID FROM Event WHERE Name = 'OpenPeriod'
		
		-- Create Event Logs for Billing Schedule ID List
		WHILE @ProcessingCounter <= @TotalRows
		BEGIN
			SET @scheduleID = (SELECT BillingScheduleID FROM @BillingScheduleList WHERE Serial = @ProcessingCounter)
			-- Create Event Logs Reocords
			INSERT INTO EventLog([EventID],				[SessionID],				[Source],			[Description],
								 [Data],				[NotificationQueueDate],	[CreateBy],			[CreateDate]) 
			VALUES				(@eventID,				@sessionID,					@pageReference,		 @scheduleID,
								 NULL,					NULL,						@userName,			GETDATE())
			
			-- CREATE Link Records
			INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) VALUES(SCOPE_IDENTITY(),@entityID,@scheduleID)
			SET @ProcessingCounter = @ProcessingCounter + 1
		END

		-- Reset Variables
		SET @ProcessingCounter = 1
		SET @TotalRows = (SELECT MAX(Serial) FROM @BillingDefinitionList)
		
		
		-- Create Event Logs for Billing Definition Invoice ID List
		WHILE @ProcessingCounter <= @TotalRows
		BEGIN
			SET @billingDefinitionID = (SELECT BillingDefinitionInvoiceID FROM @BillingDefinitionList WHERE Serial = @ProcessingCounter)
			-- Pending Logic
		END
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
 WHERE id = object_id(N'[dbo].[dms_StartCall_MemberSelections]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_StartCall_MemberSelections] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_StartCall_MemberSelections]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @memberIDCommaSeprated nvarchar(MAX) = NULL
 , @memberShipIDCommaSeprated nvarchar(MAX) = NULL
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
	SET FMTONLY OFF

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
MemberIDOperator="-1" 
FirstNameOperator="-1" 
LastNameOperator="-1" 
SuffixOperator="-1" 
PrefixOperator="-1" 
MembershipIDOperator="-1" 
MembershipNumberOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
MemberIDOperator INT NOT NULL,
MemberIDValue int NULL,
FirstNameOperator INT NOT NULL,
FirstNameValue nvarchar(100) NULL,
LastNameOperator INT NOT NULL,
LastNameValue nvarchar(100) NULL,
SuffixOperator INT NOT NULL,
SuffixValue nvarchar(100) NULL,
PrefixOperator INT NOT NULL,
PrefixValue nvarchar(100) NULL,
MembershipIDOperator INT NOT NULL,
MembershipIDValue int NULL,
MembershipNumberOperator INT NOT NULL,
MembershipNumberValue nvarchar(100) NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	MemberID int  NULL ,
	FirstName nvarchar(100)  NULL ,
	LastName nvarchar(100)  NULL ,
	Suffix nvarchar(100)  NULL ,
	Prefix nvarchar(100)  NULL ,
	MembershipID int  NULL ,
	MembershipNumber nvarchar(100)  NULL 
) 

DECLARE @QueryResult AS TABLE( 
	MemberID int  NULL ,
	FirstName nvarchar(100)  NULL ,
	LastName nvarchar(100)  NULL ,
	Suffix nvarchar(100)  NULL ,
	Prefix nvarchar(100)  NULL ,
	MembershipID int  NULL ,
	MembershipNumber nvarchar(100)  NULL 
) 

DECLARE @MemberIDValues AS TABLE(MemberID INT NULL)
DECLARE @MemberShipIDValues AS TABLE(MemberShipID INT NULL)

INSERT INTO @MemberIDValues     SELECT item from dbo.fnSplitString(@memberIDCommaSeprated,',')
INSERT INTO @MemberShipIDValues SELECT item from dbo.fnSplitString(@memberShipIDCommaSeprated,',')


INSERT INTO @QueryResult
SELECT 	M.ID MemberID,   
		M.FirstName,  
		M.LastName,
		M.Suffix,  
		M.Prefix,      
		MM.ID MembershipID,
		MM.MembershipNumber  
		FROM Member M 
		LEFT JOIN Membership MM ON M.MembershipID = MM.ID
WHERE M.ID  IN (SELECT MemberID		FROM @MemberIDValues)
AND   MM.ID IN (SELECT MemberShipID FROM @MemberShipIDValues)
ORDER BY M.ID DESC


INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@MemberIDOperator','INT'),-1),
	T.c.value('@MemberIDValue','int') ,
	ISNULL(T.c.value('@FirstNameOperator','INT'),-1),
	T.c.value('@FirstNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@LastNameOperator','INT'),-1),
	T.c.value('@LastNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@SuffixOperator','INT'),-1),
	T.c.value('@SuffixValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PrefixOperator','INT'),-1),
	T.c.value('@PrefixValue','nvarchar(100)') ,
	ISNULL(T.c.value('@MembershipIDOperator','INT'),-1),
	T.c.value('@MembershipIDValue','int') ,
	ISNULL(T.c.value('@MembershipNumberOperator','INT'),-1),
	T.c.value('@MembershipNumberValue','nvarchar(100)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.MemberID,
	T.FirstName,
	T.LastName,
	T.Suffix,
	T.Prefix,
	T.MembershipID,
	T.MembershipNumber
FROM @QueryResult T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.MemberIDOperator = -1 ) 
 OR 
	 ( TMP.MemberIDOperator = 0 AND T.MemberID IS NULL ) 
 OR 
	 ( TMP.MemberIDOperator = 1 AND T.MemberID IS NOT NULL ) 
 OR 
	 ( TMP.MemberIDOperator = 2 AND T.MemberID = TMP.MemberIDValue ) 
 OR 
	 ( TMP.MemberIDOperator = 3 AND T.MemberID <> TMP.MemberIDValue ) 
 OR 
	 ( TMP.MemberIDOperator = 7 AND T.MemberID > TMP.MemberIDValue ) 
 OR 
	 ( TMP.MemberIDOperator = 8 AND T.MemberID >= TMP.MemberIDValue ) 
 OR 
	 ( TMP.MemberIDOperator = 9 AND T.MemberID < TMP.MemberIDValue ) 
 OR 
	 ( TMP.MemberIDOperator = 10 AND T.MemberID <= TMP.MemberIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.FirstNameOperator = -1 ) 
 OR 
	 ( TMP.FirstNameOperator = 0 AND T.FirstName IS NULL ) 
 OR 
	 ( TMP.FirstNameOperator = 1 AND T.FirstName IS NOT NULL ) 
 OR 
	 ( TMP.FirstNameOperator = 2 AND T.FirstName = TMP.FirstNameValue ) 
 OR 
	 ( TMP.FirstNameOperator = 3 AND T.FirstName <> TMP.FirstNameValue ) 
 OR 
	 ( TMP.FirstNameOperator = 4 AND T.FirstName LIKE TMP.FirstNameValue + '%') 
 OR 
	 ( TMP.FirstNameOperator = 5 AND T.FirstName LIKE '%' + TMP.FirstNameValue ) 
 OR 
	 ( TMP.FirstNameOperator = 6 AND T.FirstName LIKE '%' + TMP.FirstNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LastNameOperator = -1 ) 
 OR 
	 ( TMP.LastNameOperator = 0 AND T.LastName IS NULL ) 
 OR 
	 ( TMP.LastNameOperator = 1 AND T.LastName IS NOT NULL ) 
 OR 
	 ( TMP.LastNameOperator = 2 AND T.LastName = TMP.LastNameValue ) 
 OR 
	 ( TMP.LastNameOperator = 3 AND T.LastName <> TMP.LastNameValue ) 
 OR 
	 ( TMP.LastNameOperator = 4 AND T.LastName LIKE TMP.LastNameValue + '%') 
 OR 
	 ( TMP.LastNameOperator = 5 AND T.LastName LIKE '%' + TMP.LastNameValue ) 
 OR 
	 ( TMP.LastNameOperator = 6 AND T.LastName LIKE '%' + TMP.LastNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.SuffixOperator = -1 ) 
 OR 
	 ( TMP.SuffixOperator = 0 AND T.Suffix IS NULL ) 
 OR 
	 ( TMP.SuffixOperator = 1 AND T.Suffix IS NOT NULL ) 
 OR 
	 ( TMP.SuffixOperator = 2 AND T.Suffix = TMP.SuffixValue ) 
 OR 
	 ( TMP.SuffixOperator = 3 AND T.Suffix <> TMP.SuffixValue ) 
 OR 
	 ( TMP.SuffixOperator = 4 AND T.Suffix LIKE TMP.SuffixValue + '%') 
 OR 
	 ( TMP.SuffixOperator = 5 AND T.Suffix LIKE '%' + TMP.SuffixValue ) 
 OR 
	 ( TMP.SuffixOperator = 6 AND T.Suffix LIKE '%' + TMP.SuffixValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PrefixOperator = -1 ) 
 OR 
	 ( TMP.PrefixOperator = 0 AND T.Prefix IS NULL ) 
 OR 
	 ( TMP.PrefixOperator = 1 AND T.Prefix IS NOT NULL ) 
 OR 
	 ( TMP.PrefixOperator = 2 AND T.Prefix = TMP.PrefixValue ) 
 OR 
	 ( TMP.PrefixOperator = 3 AND T.Prefix <> TMP.PrefixValue ) 
 OR 
	 ( TMP.PrefixOperator = 4 AND T.Prefix LIKE TMP.PrefixValue + '%') 
 OR 
	 ( TMP.PrefixOperator = 5 AND T.Prefix LIKE '%' + TMP.PrefixValue ) 
 OR 
	 ( TMP.PrefixOperator = 6 AND T.Prefix LIKE '%' + TMP.PrefixValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.MembershipIDOperator = -1 ) 
 OR 
	 ( TMP.MembershipIDOperator = 0 AND T.MembershipID IS NULL ) 
 OR 
	 ( TMP.MembershipIDOperator = 1 AND T.MembershipID IS NOT NULL ) 
 OR 
	 ( TMP.MembershipIDOperator = 2 AND T.MembershipID = TMP.MembershipIDValue ) 
 OR 
	 ( TMP.MembershipIDOperator = 3 AND T.MembershipID <> TMP.MembershipIDValue ) 
 OR 
	 ( TMP.MembershipIDOperator = 7 AND T.MembershipID > TMP.MembershipIDValue ) 
 OR 
	 ( TMP.MembershipIDOperator = 8 AND T.MembershipID >= TMP.MembershipIDValue ) 
 OR 
	 ( TMP.MembershipIDOperator = 9 AND T.MembershipID < TMP.MembershipIDValue ) 
 OR 
	 ( TMP.MembershipIDOperator = 10 AND T.MembershipID <= TMP.MembershipIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.MembershipNumberOperator = -1 ) 
 OR 
	 ( TMP.MembershipNumberOperator = 0 AND T.MembershipNumber IS NULL ) 
 OR 
	 ( TMP.MembershipNumberOperator = 1 AND T.MembershipNumber IS NOT NULL ) 
 OR 
	 ( TMP.MembershipNumberOperator = 2 AND T.MembershipNumber = TMP.MembershipNumberValue ) 
 OR 
	 ( TMP.MembershipNumberOperator = 3 AND T.MembershipNumber <> TMP.MembershipNumberValue ) 
 OR 
	 ( TMP.MembershipNumberOperator = 4 AND T.MembershipNumber LIKE TMP.MembershipNumberValue + '%') 
 OR 
	 ( TMP.MembershipNumberOperator = 5 AND T.MembershipNumber LIKE '%' + TMP.MembershipNumberValue ) 
 OR 
	 ( TMP.MembershipNumberOperator = 6 AND T.MembershipNumber LIKE '%' + TMP.MembershipNumberValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'
	 THEN T.MemberID END ASC, 
	 CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'
	 THEN T.MemberID END DESC ,

	 CASE WHEN @sortColumn = 'FirstName' AND @sortOrder = 'ASC'
	 THEN T.FirstName END ASC, 
	 CASE WHEN @sortColumn = 'FirstName' AND @sortOrder = 'DESC'
	 THEN T.FirstName END DESC ,

	 CASE WHEN @sortColumn = 'LastName' AND @sortOrder = 'ASC'
	 THEN T.LastName END ASC, 
	 CASE WHEN @sortColumn = 'LastName' AND @sortOrder = 'DESC'
	 THEN T.LastName END DESC ,

	 CASE WHEN @sortColumn = 'Suffix' AND @sortOrder = 'ASC'
	 THEN T.Suffix END ASC, 
	 CASE WHEN @sortColumn = 'Suffix' AND @sortOrder = 'DESC'
	 THEN T.Suffix END DESC ,

	 CASE WHEN @sortColumn = 'Prefix' AND @sortOrder = 'ASC'
	 THEN T.Prefix END ASC, 
	 CASE WHEN @sortColumn = 'Prefix' AND @sortOrder = 'DESC'
	 THEN T.Prefix END DESC ,

	 CASE WHEN @sortColumn = 'MembershipID' AND @sortOrder = 'ASC'
	 THEN T.MembershipID END ASC, 
	 CASE WHEN @sortColumn = 'MembershipID' AND @sortOrder = 'DESC'
	 THEN T.MembershipID END DESC ,

	 CASE WHEN @sortColumn = 'MembershipNumber' AND @sortOrder = 'ASC'
	 THEN T.MembershipNumber END ASC, 
	 CASE WHEN @sortColumn = 'MembershipNumber' AND @sortOrder = 'DESC'
	 THEN T.MembershipNumber END DESC 


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
END

GO

  
