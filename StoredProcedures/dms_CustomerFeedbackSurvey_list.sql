

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
 WHERE id = object_id(N'[dbo].[dms_CustomerFeedbackSurvey_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_CustomerFeedbackSurvey_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_CustomerFeedbackSurvey_list] 
/*
	EXEC [dbo].[dms_CustomerFeedbackSurvey_list]  @whereClauseXML = '<ROW><Filter FeedbackStatus="closed" /></ROW>',  @pageSize = 1000

*/
 CREATE PROCEDURE [dbo].[dms_CustomerFeedbackSurvey_list](        
   @whereClauseXML NVARCHAR(4000) = NULL     
 , @startInd Int = 1     
 , @endInd BIGINT = 5000     
 , @pageSize int = 100      
 , @sortColumn nvarchar(100)  = NULL     
 , @sortOrder nvarchar(100) = NULL           
 )     
 AS     
 BEGIN     
	  
	SET NOCOUNT ON    
	SET FMTONLY OFF   

	CREATE TABLE #FinalResults( 
		[RowNum] [bigint] NOT NULL IDENTITY(1,1),
		ID int  NULL ,
		DispatchDatetime datetime  NULL ,
		CustomerFeedbackID int  NULL ,
		IsIgnore bit  NULL ,
		OrgID nvarchar(100)  NULL ,
		ServiceRequestID int  NULL ,
		PurchaseOrderNumber nvarchar(100)  NULL ,
		FirstName nvarchar(100)  NULL ,
		LastName nvarchar(100)  NULL ,
		AdditionalComments nvarchar(MAX)  NULL ,
		ContactDate datetime  NULL 
	) 

	CREATE TABLE #tmpFinalResults( 
		[RowNum] [bigint] NOT NULL IDENTITY(1,1),
		ID int  NULL ,
		DispatchDatetime datetime  NULL ,
		CustomerFeedbackID int  NULL ,
		IsIgnore bit  NULL ,
		OrgID nvarchar(100)  NULL ,
		ServiceRequestID int  NULL ,
		PurchaseOrderNumber nvarchar(100)  NULL ,
		FirstName nvarchar(100)  NULL ,
		LastName nvarchar(100)  NULL ,
		AdditionalComments nvarchar(MAX)  NULL ,
		ContactDate datetime  NULL 
	) 


	DECLARE @idoc int    
  
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML    
	
	DECLARE @tmpForWhereClause TABLE    
	(  
		NumberType NVARCHAR(100) NULL,
		NumberValue NVARCHAR(100) NULL,
		NameType NVARCHAR(100) NULL,
		NameTypeOperator NVARCHAR(100) NULL,
		NameValue NVARCHAR(max) NULL,
		ContactFromDate DATETIME NULL,
		ContactToDate DATETIME NULL,
		FeedbackStatus NVARCHAR(255) NULL,
		DispatchFromDate DATETIME NULL,
		DispatchToDate DATETIME NULL
	)    

	INSERT INTO @tmpForWhereClause    
	SELECT    
	NumberType,   
	NumberValue,
	NameType,
	NameTypeOperator,
	NameValue,
	ContactFromDate,
	ContactToDate,
	FeedbackStatus,
	DispatchFromDate,
	DispatchToDate
	FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (    
		NumberType NVARCHAR(100),
		NumberValue NVARCHAR(100),
		NameType NVARCHAR(100),
		NameTypeOperator NVARCHAR(100),
		NameValue NVARCHAR(max),
		ContactFromDate DATETIME,
		ContactToDate DATETIME,
		FeedbackStatus NVARCHAR(100),
		DispatchFromDate DATETIME,
		DispatchToDate DATETIME
	)    
  

  
	DECLARE	@NumberType NVARCHAR(100),
			@NumberValue NVARCHAR(100),
			@NameType NVARCHAR(100),
			@NameTypeOperator NVARCHAR(100),
			@NameValue NVARCHAR(max),
			@ContactFromDate DATETIME,
			@ContactToDate DATETIME,
			@FeedbackStatus VARCHAR(100),
			@DispatchFromDate DATETIME,
			@DispatchToDate DATETIME

	SELECT  @NumberType = NumberType,
			@NumberValue = NumberValue,
			@NameType = NameType,
			@NameTypeOperator = NameTypeOperator,
			@NameValue = NameValue,
			@ContactFromDate =ContactFromDate,
			@ContactToDate = ContactToDate,
			@FeedbackStatus = FeedbackStatus,
			@DispatchFromDate = DispatchFromDate,
			@DispatchToDate  = DispatchToDate
	FROM	@tmpForWhereClause T


	DECLARE @sql NVARCHAR(MAX) = ''  

	SET @sql = @sql + ' SELECT '
	SET @sql = @sql + ' 	CS.ID,'
	SET @sql = @sql + ' 	CS.DispatchDatetime,'
	SET @sql = @sql + ' 	CS.CustomerFeedbackID,'
	SET @sql = @sql + ' 	CS.IsIgnore,'
	SET @sql = @sql + ' 	CS.SurveyType,'
	SET @sql = @sql + ' 	CS.ServiceRequestID,'
	SET @sql = @sql + ' 	CS.PurchaseOrderNumber,'
	SET @sql = @sql + ' 	CS.FirstName,'
	SET @sql = @sql + ' 	CS.LastName,'
	SET @sql = @sql + ' 	CS.AdditionalComments,'
	SET @sql = @sql + ' 	CS.ContactDateTime'
	SET @sql = @sql + ' FROM vw_CustomerSurvey CS'
	SET @sql = @sql + ' WHERE 1= 1'

	IF @NumberType IS NOT NULL
	BEGIN  
		IF @NumberType = 'PurchaseOrder'
		BEGIN
			SET @sql  = @sql + ' AND CS.PurchaseOrderNumber = @NumberValue '
		END
		ELSE IF @NumberType = 'Member'
		BEGIN
			SET @sql  = @sql + ' AND CS.MemberNumber = @NumberValue '
		END
		ELSE
		BEGIN
			SET @sql  = @sql + ' AND CS.ServiceRequestID = @NumberValue '
		END
	END  

  
	IF @NameType = 'Member First Name' AND @NameValue IS NOT NULL
	BEGIN
		IF @NameTypeOperator IN ('Begins With', 'Contains', 'Ends With') 
		BEGIN
			SET @sql = @sql + ' AND (CS.FirstName LIKE'
						+ CASE WHEN @NameTypeOperator IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
						+ ' @NameValue'
						+ CASE WHEN @NameTypeOperator IN ('Begins With', 'Contains') THEN ' +CHAR(37)' ELSE '' END
						--+' OR CS.LastName LIKE'
						--+ CASE WHEN @NameTypeOperator IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
						--+ ' @NameValue'
						--+ CASE WHEN @NameTypeOperator IN ('Starts With', 'Contains') THEN ' +CHAR(37)' ELSE '' END
						+')'
		END	
		ELSE
			---- Is Equal To
		BEGIN
				IF @NameValue IS NOT NULL
				SET @sql = @sql + ' AND (CS.FirstName = @NameValue) '  
		END
	END
	IF @NameType = 'Member Last Name' AND @NameValue IS NOT NULL
	BEGIN
		IF @NameTypeOperator IN ('Begins With', 'Contains', 'Ends With') 
		BEGIN
			SET @sql = @sql + ' AND (CS.LastName LIKE'
						+ CASE WHEN @NameTypeOperator IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
						+ ' @NameValue'
						+ CASE WHEN @NameTypeOperator IN ('Begins With', 'Contains') THEN ' +CHAR(37)' ELSE '' END
						--+' OR CS.LastName LIKE'
						--+ CASE WHEN @NameTypeOperator IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
						--+ ' @NameValue'
						--+ CASE WHEN @NameTypeOperator IN ('Starts With', 'Contains') THEN ' +CHAR(37)' ELSE '' END
						+')'
		END	
		ELSE
			---- Is Equal To
		BEGIN
				IF @NameValue IS NOT NULL
				SET @sql = @sql + ' AND (CS.LastName =@NameValue) '  
		END
	END
	 

	 
	IF @ContactFromDate IS NOT NULL 
	BEGIN
		SET @sql  = @sql + ' AND  CS.ContactDateTime >= @ContactFromDate'
	END
	
	IF @ContactToDate IS NOT NULL
	BEGIN
		SET @sql  = @sql + ' AND  CS.ContactDateTime <= @ContactToDate'
	END

	IF @DispatchFromDate IS NOT NULL 
	BEGIN
		SET @sql  = @sql + ' AND  CS.DispatchDatetime >= @DispatchFromDate'
	END
	
	IF @DispatchToDate IS NOT NULL
	BEGIN
		SET @sql  = @sql + ' AND  CS.DispatchDatetime <= @DispatchToDate'
	END

	IF @FeedbackStatus IS NOT NULL
	BEGIN
		IF @FeedbackStatus = 'open'
		BEGIN
			SET @sql = @sql + ' AND CS.CustomerFeedbackID IS NULL AND CS.IsIgnore IS NULL'
		END
		IF @FeedbackStatus = 'closed'
		BEGIN
			SET @sql = @sql + ' AND (CS.CustomerFeedbackID IS NOT NULL OR CS.IsIgnore IS NOT NULL)'
		END

		--IF @FeedbackStatus = 'All'
		--BEGIN
		--	--Get All the records
		--END

	END
	--ELSE
	--BEGIN
	--	SET @sql = @sql + ' AND CS.CustomerFeedbackID IS NULL AND CS.IsIgnore IS NULL'
	--END
	PRINT @sql
	INSERT INTO #tmpFinalResults
	EXEC sp_executesql @sql,N'@NumberValue NVARCHAR(100),
								@NameValue NVARCHAR(MAX),
								@ContactFromDate DATETIME,
								@ContactToDate DATETIME,
								@FeedbackStatus NVARCHAR(100),
								@DispatchFromDate DATETIME,
								@DispatchToDate DATETIME',
								@NumberValue,
								@NameValue,
								@ContactFromDate,
								@ContactToDate,
								@FeedbackStatus,
								@DispatchFromDate,
								@DispatchToDate

	INSERT INTO #FinalResults
	SELECT 
		T.ID,
		T.DispatchDatetime,
		T.CustomerFeedbackID,
		T.IsIgnore,
		T.OrgID,
		T.ServiceRequestID,
		T.PurchaseOrderNumber,
		T.FirstName,
		T.LastName,
		T.AdditionalComments,
		T.ContactDate
	FROM #tmpFinalResults T
	ORDER BY 
		 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
		 THEN T.ID END ASC, 
		 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
		 THEN T.ID END DESC ,

		 CASE WHEN @sortColumn = 'DispatchDatetime' AND @sortOrder = 'ASC'
		 THEN T.DispatchDatetime END ASC, 
		 CASE WHEN @sortColumn = 'DispatchDatetime' AND @sortOrder = 'DESC'
		 THEN T.DispatchDatetime END DESC ,

		 CASE WHEN @sortColumn = 'CustomerFeedbackID' AND @sortOrder = 'ASC'
		 THEN T.CustomerFeedbackID END ASC, 
		 CASE WHEN @sortColumn = 'CustomerFeedbackID' AND @sortOrder = 'DESC'
		 THEN T.CustomerFeedbackID END DESC ,

		 CASE WHEN @sortColumn = 'IsIgnore' AND @sortOrder = 'ASC'
		 THEN T.IsIgnore END ASC, 
		 CASE WHEN @sortColumn = 'IsIgnore' AND @sortOrder = 'DESC'
		 THEN T.IsIgnore END DESC ,

		 CASE WHEN @sortColumn = 'OrgID' AND @sortOrder = 'ASC'
		 THEN T.OrgID END ASC, 
		 CASE WHEN @sortColumn = 'OrgID' AND @sortOrder = 'DESC'
		 THEN T.OrgID END DESC ,

		 CASE WHEN @sortColumn = 'ServiceRequestID' AND @sortOrder = 'ASC'
		 THEN T.ServiceRequestID END ASC, 
		 CASE WHEN @sortColumn = 'ServiceRequestID' AND @sortOrder = 'DESC'
		 THEN T.ServiceRequestID END DESC ,

		 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'ASC'
		 THEN T.PurchaseOrderNumber END ASC, 
		 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'DESC'
		 THEN T.PurchaseOrderNumber END DESC ,

		 CASE WHEN @sortColumn = 'FirstName' AND @sortOrder = 'ASC'
		 THEN T.FirstName END ASC, 
		 CASE WHEN @sortColumn = 'FirstName' AND @sortOrder = 'DESC'
		 THEN T.FirstName END DESC ,

		 CASE WHEN @sortColumn = 'LastName' AND @sortOrder = 'ASC'
		 THEN T.LastName END ASC, 
		 CASE WHEN @sortColumn = 'LastName' AND @sortOrder = 'DESC'
		 THEN T.LastName END DESC ,

		 CASE WHEN @sortColumn = 'AdditionalComments' AND @sortOrder = 'ASC'
		 THEN T.AdditionalComments END ASC, 
		 CASE WHEN @sortColumn = 'AdditionalComments' AND @sortOrder = 'DESC'
		 THEN T.AdditionalComments END DESC ,

		 CASE WHEN @sortColumn = 'ContactDate' AND @sortOrder = 'ASC'
		 THEN T.ContactDate END ASC, 
		 CASE WHEN @sortColumn = 'ContactDate' AND @sortOrder = 'DESC'
		 THEN T.ContactDate END DESC 



		 DECLARE @openCount INT = 0,
			@closedCount INT = 0,
			@TotalCount INT=0
	
	SELECT @openCount = COUNT(*) FROM #tmpFinalResults WHERE CUSTOMERFEEDBACKID IS NULL AND ISIGNORE IS NULL
	SELECT @closedCount = COUNT(*) FROM #tmpFinalResults WHERE CUSTOMERFEEDBACKID IS NOT NULL OR ISIGNORE IS NOT NULL
	SELECT @TotalCount = COUNT(*) FROM #tmpFinalResults 

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

	SELECT @count AS TotalRows, *,@openCount AS OpenCount,@closedCount AS ClosedCount,@TotalCount AS TotalCount FROM #FinalResults WHERE RowNum BETWEEN @startInd AND @endInd

	DROP TABLE #FinalResults
	DROP TABLE #tmpFinalResults
END