IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Mobile_Configuration]') AND type in (N'P', N'PC'))

DROP PROCEDURE [dbo].[dms_Mobile_Configuration]
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
						JOIN Program P ON M.ProgramID=P.ID				--Lakshmi - ODIS NMC Mobile App call  Hagerty Confusion
						WHERE M.IsPrimary = 1 
						AND MS.MembershipNumber = 
						(SELECT MemberNumber FROM #Mobile_CallForService_Temp where membernumber IS NOT NULL AND memberNumber <> '') 
						AND P.ParentProgramID=@programID				--Lakshmi - ODIS NMC Mobile App call  Hagerty Confusion
  
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

