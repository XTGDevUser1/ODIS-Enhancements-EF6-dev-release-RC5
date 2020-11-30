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
	--Declare
	--@programID INT = 286,  
	--@configurationType nvarchar(50) = 5,  
	--@configurationCategory nvarchar(50) = 3,  
	--@callBackNumber nvarchar(50) = '1 9858791084',  
	--@inBoundCallID INT = 509092,
	--@memberID INT = NULL, --16432463,
	--@membershipID INT = NULL --14802600  
		  
	SET FMTONLY OFF  
	-- Output Values   
	DECLARE @unformattedNumber nvarchar(50) = NULL  
	DECLARE @isMobileEnabled BIT = NULL  
	DECLARE @searchCaseRecords BIT = 1
	DECLARE @appOrgName NVARCHAR(100) = NULL
	
	DECLARE @memberProgramID INT = NULL
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
		[MembershipID] INT  ,
		[MemberProgramID] INT)
 

	IF ( @memberID IS NOT NULL)
		BEGIN
			
			UPDATE	InboundCall 
			SET		MemberID = @memberID   		
			WHERE	ID = @inBoundCallID 

			INSERT INTO @Mobile_CallForService_Temp
				([MemberID],[MembershipID],[IsMobileEnabled]) 
			VALUES
				(@memberID,@membershipID,@isMobileEnabled) 

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
		--SELECT @callBackNumber
		
			SELECT @unformattedNumber = SUBSTRING(@callBackNumber,1,@charIndex)  
			SET @charIndex = 0  
			SELECT @charIndex = CHARINDEX(' ',@unformattedNumber,0)  
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
					AND DATEDIFF(mi,M.[DateTime],GETDATE()) <= 60 
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
					@membershipID = RR.MembershipID ,
					@memberProgramID = RR.ProgramID
					FROM  
					(  
						SELECT TOP 1 M.ID,  
							   M.MembershipID,
							   M.ProgramID   
							   FROM Membership MS 
						JOIN Member M ON MS.ID = M.MembershipID 
						JOIN Program P ON M.ProgramID=P.ID
						WHERE M.IsPrimary = 1 
						AND MS.MembershipNumber = 
						(SELECT MemberNumber FROM #Mobile_CallForService_Temp where membernumber IS NOT NULL AND memberNumber <> '') 
						AND (ISNULL(@ProgramID,0) = 0 OR M.ProgramID IN (SELECT * FROM @GetPrograms_Temp))  
					)RR  
					
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
						IsMobileEnabled  ,
						MemberProgramID
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
								@isMobileEnabled,
								@memberProgramID
						FROM #Mobile_CallForService_Temp
	  
							
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
						--PRINT 'Update Inbound Call'
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
				
			END
		
			IF ( @searchCaseRecords = 1 )  
			BEGIN 
				--PRINT 'Search Case Records'
		
				INSERT INTO @Mobile_CallForService_Temp
									([MemberID],[MembershipID],[IsMobileEnabled], [MemberProgramID]) 
					SELECT  DISTINCT M.ID,   
									M.MembershipID,
									@isMobileEnabled,
									C.ProgramID
					FROM [Case] C  
					JOIN Member M ON C.MemberID = M.ID 
					JOIN Program P ON M.ProgramID=P.ID		--Lakshmi
					WHERE C.ContactPhoneNumber = @callBackNumber 
					AND (ISNULL(@ProgramID,0) = 0 OR M.ProgramID IN (SELECT * FROM @GetPrograms_Temp))
					ORDER BY ID DESC
					
				IF((SELECT COUNT(*) FROM @Mobile_CallForService_Temp)= 0 OR (SELECT COUNT(*) FROM @Mobile_CallForService_Temp) = 1) 
				BEGIN
					--PRINT 'Update Inbound Call'
					UPDATE InboundCall 
					SET MemberID = @memberID   		
					WHERE ID = @inBoundCallID  
				END
			END  

		-- If one of the matching member IDs has an open SR then only return the associated Member, otherwise return all matching Members
		IF EXISTS (
			SELECT temp.*
			FROM @Mobile_CallForService_Temp temp
			JOIN [Case] c ON temp.MemberID = c.MemberID
			JOIN ServiceRequest sr ON c.ID = sr.CaseID
			WHERE sr.ServiceRequestStatusID IN (SELECT ID FROM ServiceRequestStatus WHERE Name IN ('Entry','Submitted','Dispatched'))
			)
			SELECT temp.*
			FROM @Mobile_CallForService_Temp temp
			JOIN [Case] c ON temp.MemberID = c.MemberID
			JOIN ServiceRequest sr ON c.ID = sr.CaseID
			WHERE sr.ServiceRequestStatusID IN (SELECT ID FROM ServiceRequestStatus WHERE Name IN ('Entry','Submitted','Dispatched'))
		ELSE
			SELECT * FROM @Mobile_CallForService_Temp     
	END     

END
