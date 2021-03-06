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
		[MembershipID] INT)  
 

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
						AND (ISNULL(@ProgramID,0) = 0 OR M.ProgramID IN (SELECT * FROM @GetPrograms_Temp))
	  
							
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
									([MemberID],[MembershipID],[IsMobileEnabled]) 
					SELECT  DISTINCT M.ID,   
									M.MembershipID,
									@isMobileEnabled
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
 WHERE id = object_id(N'[dbo].[dms_Temporary_CC_Batch_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Temporary_CC_Batch_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Temporary_CC_Batch_List]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = 'CreateDate' 
 , @sortOrder nvarchar(100) = 'DESC' 
  
 ) 
 AS 
 BEGIN 
      SET FMTONLY OFF;
     SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
      SET @whereClauseXML = '<ROW><Filter 

></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
BatchStatusID int NULL,
FromDate DATETIME NULL,
ToDate DATETIME NULL
)
CREATE TABLE #FinalResults( 
      [RowNum] [bigint] NOT NULL IDENTITY(1,1),
      ID int  NULL ,
      BatchType nvarchar(100)  NULL ,
      BatchStatusID int  NULL ,
      BatchStatus nvarchar(100)  NULL ,
      TotalCount int  NULL ,
      TotalAmount money  NULL ,    
      CreateDate datetime  NULL ,
      CreateBy nvarchar(100)  NULL ,
      ModifyDate datetime  NULL ,
      ModifyBy nvarchar(100)  NULL--,
      --CreditCardIssueNumber nvarchar(100) NULL
) 

CREATE TABLE #tmpFinalResults( 
      [RowNum] [bigint] NOT NULL IDENTITY(1,1),
      ID int  NULL ,
      BatchType nvarchar(100)  NULL ,
      BatchStatusID int  NULL ,
      BatchStatus nvarchar(100)  NULL ,
      TotalCount int  NULL ,
      TotalAmount money  NULL ,     
      CreateDate datetime  NULL ,
      CreateBy nvarchar(100)  NULL ,
      ModifyDate datetime  NULL ,
      ModifyBy nvarchar(100)  NULL--,
      --CreditCardIssueNumber nvarchar(100) NULL
) 

INSERT INTO #tmpForWhereClause
SELECT 
      T.c.value('@BatchStatusID','int') ,
      T.c.value('@FromDate','datetime') ,
      T.c.value('@ToDate','datetime') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @batchStatusID NVARCHAR(100) = NULL,
            @fromDate DATETIME = NULL,
            @toDate DATETIME = NULL
            
SELECT      @batchStatusID = BatchStatusID, 
            @fromDate = FromDate,
            @toDate = ToDate
FROM  #tmpForWhereClause
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------


INSERT INTO #tmpFinalResults
SELECT      B.ID
            , BT.[Description] AS BatchType
            , B.BatchStatusID
            , BS.Name AS BatchStatus
            , B.TotalCount AS TotalCount
            , B.TotalAmount AS TotalAmount
            , B.CreateDate
            , B.CreateBy
            , B.ModifyDate
            , B.ModifyBy 
            --, TCC.CreditCardIssueNumber
FROM  Batch B
JOIN  BatchType BT ON BT.ID = B.BatchTypeID
JOIN  BatchStatus BS ON BS.ID = B.BatchStatusID
LEFT JOIN TemporaryCreditCard TCC ON TCC.PostingBatchID = B.ID
WHERE B.BatchTypeID = (SELECT ID FROM BatchType WHERE Name = 'TemporaryCCPost')
AND         (@batchStatusID IS NULL OR @batchStatusID = B.BatchStatusID)
AND         (@fromDate IS NULL OR B.CreateDate > @fromDate)
AND         (@toDate IS NULL OR B.CreateDate < @toDate)
GROUP BY    B.ID
            , BT.[Description] 
            , B.BatchStatusID
            , BS.Name  
            , B.TotalCount
            , B.TotalAmount         
            , B.CreateDate
            , B.CreateBy
            , B.ModifyDate
            , B.ModifyBy
            --, TCC.CreditCardIssueNumber
ORDER BY B.CreateDate DESC



INSERT INTO #FinalResults
SELECT 
      T.ID,
      T.BatchType,
      T.BatchStatusID,
      T.BatchStatus,
      T.TotalCount,
      T.TotalAmount,    
      T.CreateDate,
      T.CreateBy,
      T.ModifyDate,
      T.ModifyBy--,
      --T.CreditCardIssueNumber
      
FROM #tmpFinalResults T

ORDER BY 
       CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
      THEN T.ID END ASC, 
       CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
      THEN T.ID END DESC ,

      CASE WHEN @sortColumn = 'BatchType' AND @sortOrder = 'ASC'
      THEN T.BatchType END ASC, 
       CASE WHEN @sortColumn = 'BatchType' AND @sortOrder = 'DESC'
      THEN T.BatchType END DESC ,

      CASE WHEN @sortColumn = 'BatchStatusID' AND @sortOrder = 'ASC'
      THEN T.BatchStatusID END ASC, 
       CASE WHEN @sortColumn = 'BatchStatusID' AND @sortOrder = 'DESC'
      THEN T.BatchStatusID END DESC ,

      CASE WHEN @sortColumn = 'BatchStatus' AND @sortOrder = 'ASC'
      THEN T.BatchStatus END ASC, 
       CASE WHEN @sortColumn = 'BatchStatus' AND @sortOrder = 'DESC'
      THEN T.BatchStatus END DESC ,

      CASE WHEN @sortColumn = 'TotalCount' AND @sortOrder = 'ASC'
      THEN T.TotalCount END ASC, 
       CASE WHEN @sortColumn = 'TotalCount' AND @sortOrder = 'DESC'
      THEN T.TotalCount END DESC ,

      CASE WHEN @sortColumn = 'TotalAmount' AND @sortOrder = 'ASC'
      THEN T.TotalAmount END ASC, 
       CASE WHEN @sortColumn = 'TotalAmount' AND @sortOrder = 'DESC'
      THEN T.TotalAmount END DESC ,     

      CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'
      THEN T.CreateDate END ASC, 
       CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'
      THEN T.CreateDate END DESC ,

      CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
      THEN T.CreateBy END ASC, 
       CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
      THEN T.CreateBy END DESC ,

      CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'ASC'
      THEN T.ModifyDate END ASC, 
       CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'DESC'
      THEN T.ModifyDate END DESC ,

      CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'ASC'
      THEN T.ModifyBy END ASC, 
       CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'DESC'
      THEN T.ModifyBy END DESC --,

      --CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'ASC'
      --THEN T.CreditCardIssueNumber END ASC, 
      -- CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'DESC'
      --THEN T.CreditCardIssueNumber END DESC 


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
 WHERE id = object_id(N'[dbo].[dms_VerifyProgramServiceBenefit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC dms_VerifyProgramServiceBenefit 1, 1, 1, 1, 1, NULL, NULL  
CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit]  
       @ProgramID INT   
      , @ProductCategoryID INT  
      , @VehicleCategoryID INT  
      , @VehicleTypeID INT  
      , @SecondaryCategoryID INT = NULL  
      , @ServiceRequestID  INT = NULL  
      , @ProductID INT = NULL  
      , @IsPrimaryOverride BIT = NULL
AS  
BEGIN   
  
	SET NOCOUNT ON    
	SET FMTONLY OFF    

	--KB: 
	SET @ProductID = NULL

	DECLARE @SecondaryProductID INT
		,@OverrideCoverageLimit money 

	/*** Determine Primary and Secondary Product IDs ***/  
	/* Ignore Vehicle related values for Product Categories not requiring a Vehicle */
	IF @ProductCategoryID IN (SELECT ID FROM ProductCategory WHERE IsVehicleRequired = 0)
	BEGIN
		SET @VehicleCategoryID = NULL
		SET @VehicleTypeID = NULL
	END

	/* Select Basic Lockout over Locksmith when a specific product is not provided */  
	IF @ProductID IS NULL AND @ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Lockout')  
	BEGIN  
	SET @ProductID = (SELECT ID FROM Product WHERE Name = 'Basic Lockout')  
	END  

	/* Select Tire Change over Tire Repair when a specific product is not provided */  
	IF @ProductID IS NULL AND @ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tire')  
	BEGIN  
	SET @ProductID = (SELECT ID FROM Product WHERE Name like 'Tire Change%' AND VehicleCategoryID = @VehicleCategoryID)  
	END  

	IF @ProductID IS NULL  
	SELECT @ProductID = p.ID   
	FROM  ProductCategory pc (NOLOCK)   
	JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID   
	  AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')  
	  AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')  
	WHERE  
	pc.ID = @ProductCategoryID   
	AND (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)  
	AND (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)  


	IF @SecondaryCategoryID IS NOT NULL  
	SELECT @SecondaryProductID = p.ID   
	FROM  ProductCategory pc (NOLOCK)   
	JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID   
	  AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')  
	  AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')  
	WHERE  
	pc.ID = @SecondaryCategoryID   
	AND (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)  
	AND (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)  

	-- Coverage Limit Override for Ford ESP vehicles E/F 650 and 750
	IF @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Extended Service Plan (RV & COMM)')
	BEGIN
	IF EXISTS(
		SELECT * 
		FROM [Case] c
		JOIN ServiceRequest sr ON sr.CaseID = c.ID
		WHERE sr.ID = @ServiceRequestID
			AND (SUBSTRING(c.VehicleVIN, 6, 1) IN ('6','7')
				OR c.VehicleModel IN ('F-650', 'F-750', 'E-650', 'E-750'))
		)
		SET @OverrideCoverageLimit = 200.00
	END
   
	SELECT ISNULL(pc.Name,'') ProductCategoryName  
		,pc.ID ProductCategoryID  
		--,pc.Sequence  
		,ISNULL(vc.Name,'') VehicleCategoryName  
		,vc.ID VehicleCategoryID  
		,pp.ProductID  

		,CAST (pp.IsServiceCoverageBestValue AS BIT) AS IsServiceCoverageBestValue
		,CASE WHEN @OverrideCoverageLimit IS NOT NULL THEN @OverrideCoverageLimit ELSE pp.ServiceCoverageLimit END AS ServiceCoverageLimit
		,pp.CurrencyTypeID   
		,pp.ServiceMileageLimit   
		,pp.ServiceMileageLimitUOM   
		,1 AS IsServiceEligible
		--TP: Below logic is not needed; Only eligible services will be added to ProgramProduct 
		--,CASE WHEN pp.ServiceCoverageLimit IS NULL THEN 0   
		--              WHEN pp.IsServiceCoverageBestValue = 1 THEN 1  
		--              WHEN pp.ServiceCoverageLimit = 0 AND pp.IsReimbursementOnly = 1 THEN 1   
		--              WHEN pp.ServiceCoverageLimit = 0 AND ISNULL(pp.ServiceMileageLimit,0) > 0 THEN 1   
		--              WHEN pp.ServiceCoverageLimit = 0 AND pp.ProductID IN (SELECT p.ID FROM Product p WHERE p.ProductCategoryID IN (SELECT ID FROM ProductCategory WHERE Name IN ('Info', 'Tech', 'Concierge'))) THEN 1
		--              WHEN pp.ServiceCoverageLimit > 0 THEN 1  
		--              ELSE 0 END IsServiceEligible  
		,pp.IsServiceGuaranteed   
		,pp.ServiceCoverageDescription  
		,pp.IsReimbursementOnly  
		,CASE WHEN ISNULL(@IsPrimaryOverride,0) = 0 AND pc.ID = @SecondaryCategoryID THEN 0 ELSE 1 END AS IsPrimary  
	FROM ProgramProduct pp (NOLOCK)  
	JOIN Product p ON p.ID = pp.ProductID  
	LEFT OUTER JOIN ProductCategory pc (NOLOCK) ON pc.ID = p.ProductCategoryID  
	LEFT OUTER JOIN VehicleCategory vc (NOLOCK) ON vc.id = p.VehicleCategoryID  
	WHERE pp.ProgramID = @ProgramID  
	AND (pp.ProductID = @ProductID OR pp.ProductID = @SecondaryProductID)  
	ORDER BY   
	(CASE WHEN pc.ID = @SecondaryCategoryID THEN 0 ELSE 1 END) DESC  
	,pc.Sequence  
     
END  

GO
