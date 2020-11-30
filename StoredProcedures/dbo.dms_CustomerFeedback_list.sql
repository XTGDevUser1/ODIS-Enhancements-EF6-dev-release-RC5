

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
 WHERE id = object_id(N'[dbo].[dms_CustomerFeedback_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_CustomerFeedback_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_CustomerFeedback_list] 
 CREATE PROCEDURE [dbo].[dms_CustomerFeedback_list](        
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
  
CREATE TABLE #FinalResultsFiltered (    
	CustomerFeedbackID INT NULL,  
	[Status] NVARCHAR(100) NULL,  
	[Source] NVARCHAR(100) NULL,  
	[Priority] NVARCHAR(100) NULL,  
	[PrioritySequence] INT NULL,
	[CreatedBy] NVARCHAR(100) NULL,  
	AssignedToFirstName NVARCHAR(MAX) NULL,  
	AssignedToLastName NVARCHAR(MAX) NULL,  	
	MemberFirstName NVARCHAR(255) NULL,  
	MemberLastName NVARCHAR(255) NULL, 
	MemberID INT NULL,
	MemberNumber NVARCHAR(255) NULL,
	ClientID INT NULL,
	ClientName NVARCHAR(255) NULL,
	ProgramID INT NULL, 
	ProgramName NVARCHAR(255) NULL,
	PurchaseOrderNumber NVARCHAR(255) NULL,
	ServiceRequestID INT NULL,
	[Type] NVARCHAR(50) NULL,  
	[TypeSequence] INT NULL,  
	DateofService DATETIME NULL,
	NextAction  NVARCHAR(MAX) NULL,  
	NextActionAssignedToFirstName NVARCHAR(MAX) NULL,  
	NextActionAssignedToLastName NVARCHAR(MAX) NULL,  
	NextActionScheduledDate DATETIME NULL,
	DescriptionofConcern NVARCHAR(MAX) NULL,
	DueDate	DATETIME NULL,
	WorkedBy NVARCHAR(255) NULL 
)    
	
CREATE TABLE #FinalResultsFormatted (      
	CustomerFeedbackID INT NULL,  
	[Status] NVARCHAR(100) NULL,    
	[Source] NVARCHAR(50) NULL,  
	[Priority] NVARCHAR(255) NULL,  
	[PrioritySequence] INT NULL,
	[CreatedBy] NVARCHAR(100) NULL,  
	AssignedTo NVARCHAR(100) NULL,  	
	MemberFirstName NVARCHAR(100) NULL,  
	MemberLastName NVARCHAR(100) NULL,  
	MemberID INT NULL,
	MemberNumber NVARCHAR(255) NULL,
	ClientID INT NULL,
	ClientName NVARCHAR(255) NULL,
	ProgramID INT NULL, 
	ProgramName NVARCHAR(255) NULL,
	PurchaseOrderNumber NVARCHAR(255) NULL, 
	ServiceRequestID INT NULL,
	[Type] NVARCHAR(50) NULL,  
	DateofService DATETIME NULL,
	NextAction  NVARCHAR(50) NULL,  
	NextActionAssignedTo NVARCHAR(50) NULL,  
	NextActionScheduledDate DATETIME NULL,
	DescriptionofConcern NVARCHAR(max) NULL,
	DueDate	DATETIME NULL,
	WorkedBy NVARCHAR(255) NULL
)    
  
CREATE TABLE #FinalResultsSorted (    
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	CustomerFeedbackID INT NULL,  
	[Status] NVARCHAR(100) NULL,    
	[Source] NVARCHAR(50) NULL,  
	[Priority] NVARCHAR(255) NULL, 
	[PrioritySequence] INT NULL, 
	[CreatedBy] NVARCHAR(100) NULL,  
	AssignedTo NVARCHAR(100) NULL,  	
	MemberFirstName NVARCHAR(100) NULL,  
	MemberLastName NVARCHAR(100) NULL,  
	MemberID INT NULL,
	MemberNumber NVARCHAR(255) NULL,
	ClientID INT NULL,
	ClientName NVARCHAR(255) NULL,
	ProgramID INT NULL, 
	ProgramName NVARCHAR(255) NULL,
	PurchaseOrderNumber NVARCHAR(255) NULL, 
	ServiceRequestID INT NULL,
	[Type] NVARCHAR(50) NULL,  
	DateofService DATETIME NULL,
	NextAction  NVARCHAR(50) NULL,  
	NextActionAssignedTo NVARCHAR(50) NULL,  
	NextActionScheduledDate DATETIME NULL,
	DescriptionofConcern NVARCHAR(max) NULL,
	DueDate	DATETIME NULL,
	WorkedBy NVARCHAR(255) NULL	
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
	Statuses NVARCHAR(255) NULL,
	Sources NVARCHAR(255) NULL,
	FeedbackTypes NVARCHAR(255) NULL,
	Priorities NVARCHAR(255) NULL,
	Client INT NULL,
	Program INT NULL,
	ReceivedFromDate DATETIME NULL,
	ReceivedToDate DATETIME NULL,
	NextAction INT NULL
)    
	
	
INSERT INTO @tmpForWhereClause    
SELECT    
NumberType,   
NumberValue,
NameType,
NameTypeOperator,
NameValue,
Statuses,
Sources,
FeedbackTypes,
Priorities,
Client,
Program,
ReceivedFromDate,
ReceivedToDate,
NextAction
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (    
	NumberType NVARCHAR(100),
	NumberValue NVARCHAR(100),
	NameType NVARCHAR(100),
	NameTypeOperator NVARCHAR(100),
	NameValue NVARCHAR(max),
	Statuses NVARCHAR(255),
	Sources NVARCHAR(255),
	FeedbackTypes NVARCHAR(255),
	Priorities NVARCHAR(255),
	Client INT,
	Program INT,
	ReceivedFromDate DATETIME,
	ReceivedToDate DATETIME,
	NextAction INT
)    
  
--DEBUG:SELECT * FROM @tmpForWhereClause

DECLARE	@NumberType NVARCHAR(100),
		@NumberValue NVARCHAR(100),
		@NameType NVARCHAR(100),
		@NameTypeOperator NVARCHAR(100),
		@NameValue NVARCHAR(max),
		@Statuses NVARCHAR(255),
		@Sources NVARCHAR(255),
		@FeedbackTypes NVARCHAR(255),
		@Priorities NVARCHAR(255),
		@Client INT,
		@Program INT,
		@ReceivedFromDate DATETIME,
		@ReceivedToDate DATETIME,
		@NextAction INT,
		@FilterType VARCHAR(MAX)

SELECT  @NumberType = NumberType,
		@NumberValue = NumberValue,
		@NameType = NameType,
		@NameTypeOperator = NameTypeOperator,
		@NameValue = NameValue,
		@Statuses = Statuses,
		@Sources = Sources,
		@FeedbackTypes = FeedbackTypes ,
		@Priorities = T.Priorities,
		@Client = Client,
		@Program = Program,
		@ReceivedFromDate = ReceivedFromDate,
		@ReceivedToDate = ReceivedToDate,
		@NextAction = NextAction
FROM	@tmpForWhereClause T
	
-- Statuses
	DECLARE @tmpStatuses IntTableType
	INSERT INTO @tmpStatuses
	SELECT item FROM fnSplitString(@Statuses,',')
	
	-- Sources
	DECLARE @tmpSources IntTableType
	INSERT INTO @tmpSources
	SELECT item FROM fnSplitString(@Sources,',')
	
	-- Feedbacktypes
	DECLARE @tmpFeedbackTypes IntTableType
	INSERT INTO @tmpFeedbackTypes
	SELECT item FROM fnSplitString(@FeedbackTypes,',')

	-- Priorities
	DECLARE @tmpPriorities IntTableType
	INSERT INTO @tmpPriorities
	SELECT item FROM fnSplitString(@Priorities,',')
	
DECLARE @sql NVARCHAR(MAX) = ''  
  

SET @sql = @sql + ' SELECT	CF.ID As CustomerFeedbackID, '
SET @sql = @sql + ' 		CFS.Description AS [Status], '
SET @sql = @sql + ' 		CFSO.Description AS [Source], '
SET @sql = @sql + ' 		CFP.Description As [Priority], '
SET @sql = @sql + ' 		CFP.Sequence As [PrioritySequence], '
SET @sql = @sql + ' 		CF.CreateBy, '
SET @sql = @sql + ' 		AU.FirstName As AssignedToFirstName, '
SET @sql = @sql + ' 		AU.LastName AS AssignedToLastName, '
SET @sql = @sql + ' 		CF.MemberFirstName, '
SET @sql = @sql + ' 		CF.MemberLastName, '
SET @sql = @sql + ' 		C.MemberID, '
SET @sql = @sql + ' 		CF.MembershipNumber, '
SET @sql = @sql + ' 		P.ClientID AS ClientID, '
SET @sql = @sql + ' 		CL.Name AS ClientName, '
SET @sql = @sql + ' 		P.ID AS ProgramID, '
SET @sql = @sql + ' 		P.Name AS ProgramName, '
SET @sql = @sql + ' 		COALESCE(CF.PurchaseOrderNumber, PO.PurchaseOrderNumber) AS PurchaseOrderNumber, '
SET @sql = @sql + ' 		CF.ServiceRequestID, '
SET @sql = @sql + ' 		CFT.Description AS [Type], '
SET @sql = @sql + ' 		ISNULL(CFT.Sequence,0) AS [TypeSequence], '
SET @sql = @sql + ' 		SR.CreateDate AS [DateOfService], '
SET @sql = @sql + ' 		NA.Description AS [NextAction], '
SET @sql = @sql + ' 		NAAU.FirstName As NextActionAssignedToFirstName, '
SET @sql = @sql + ' 		NAAU.LastName As NextActionAssignedToLastName, '
SET @sql = @sql + ' 		CF.NextActionScheduleDate As [NextActionScheduledDate], '
SET @sql = @sql + ' 		CF.Description As DescriptionOfConcern, '
SET @sql = @sql + ' 		CF.DueDate As DueDate, '
SET @sql = @sql + ' 		WB.FirstName + '' '' + WB.LastName As WorkedBy'
SET @sql = @sql + ' FROM		CustomerFeedback CF  '
SET @sql = @sql + ' LEFT JOIN	CustomerFeedbackPriority CFP ON CF.CustomerFeedbackPriorityID = CFP.ID '
SET @sql = @sql + ' Left Join	CustomerFeedbackStatus CFS ON CF.CustomerFeedbackStatusID=CFS.ID '
SET @sql = @sql + ' LEFT JOIN	CustomerFeedbackSource CFSO ON CF.CustomerFeedbackSourceID=CFSO.ID '
SET @sql = @sql + ' LEFT JOIN	CustomerFeedbackDETAIL CFD ON CF.ID=CFD.CustomerFeedbackID '
SET @sql = @sql + ' LEFT JOIN	CustomerFeedbackType CFT ON CFD.CustomerFeedbackTypeID=CFT.ID '
SET @sql = @sql + ' LEFT JOIN	PurchaseOrder PO ON CF.ServiceRequestID = PO.ServiceRequestID AND PO.PurchaseOrderStatusID <> (SELECT ID FROM PurchaseOrderStatus WHERE Name=''Pending'')'
SET @sql = @sql + ' LEFT JOIN	[User] AU ON CF.AssignedToUserID = AU.ID '
SET @sql = @sql + ' LEFT JOIN	[User] WB ON CF.WorkedByUserID = WB.ID '
SET @sql = @sql + ' LEFT JOIN	NextAction NA ON CF.NextActionID = NA.ID '
SET @sql = @sql + ' LEFT JOIN	[User] NAAU ON CF.NextActionAssignedToUserID = NAAU.ID '
SET @sql = @sql + ' LEFT JOIN	[ServiceRequest] SR ON CF.ServiceRequestID = SR.ID '
SET @sql = @sql + ' LEFT JOIN	[Case] C ON SR.CaseID = C.ID '
SET @sql = @sql + ' LEFT JOIN	[Program] P ON C.ProgramID = P.ID '
SET @sql = @sql + ' LEFT JOIN	[Client] CL ON P.ClientID = CL.ID '
SET @sql = @sql + ' WHERE	1=1 ' 
	
  IF @NumberType IS NOT NULL
	BEGIN  
	   IF @NumberType = 'PurchaseOrder'
	   BEGIN
			SET @sql  = @sql + ' AND PO.PurchaseOrderNumber = @NumberValue '
	   END
	   ELSE IF @NumberType = 'ServiceRequest'
	   BEGIN
			SET @sql  = @sql + ' AND CF.ServiceRequestID = @NumberValue '
	   END
	   ELSE IF @NumberType = 'Feedback'
	   BEGIN
			SET @sql  = @sql + ' AND CF.ID = @NumberValue '
	   END
	   ELSE 
	   BEGIN
			SET @sql  = @sql + ' AND CF.MembershipNumber = @NumberValue '
	   END
	END  
  

  IF @NameType = 'Created By' AND @NameValue IS NOT NULL
		BEGIN
			IF @NameTypeOperator IN ('Begins With', 'Contains', 'Ends With') 
				SET @sql = @sql + ' AND CF.CreateBy LIKE'
								+ CASE WHEN @NameTypeOperator IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
								+ ' @NameValue'
								+ CASE WHEN @NameTypeOperator IN ('Begins With', 'Contains') THEN ' +CHAR(37)' ELSE '' END
			ELSE
				---- Is Equal To
				SET @sql = @sql + ' AND CF.CreateBy = @NameValue'  
		END

  IF @NameType = 'Member' AND @NameValue IS NOT NULL
		BEGIN
			IF @NameTypeOperator IN ('Begins With', 'Contains', 'Ends With') 
			BEGIN
				SET @sql = @sql + ' AND (CF.MemberFirstName LIKE'
							+ CASE WHEN @NameTypeOperator IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @NameValue'
							+ CASE WHEN @NameTypeOperator IN ('Begins With', 'Contains') THEN ' +CHAR(37)' ELSE '' END
							+' OR CF.MemberLastName LIKE'
							+ CASE WHEN @NameTypeOperator IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @NameValue'
							+ CASE WHEN @NameTypeOperator IN ('Begins With', 'Contains') THEN ' +CHAR(37)' ELSE '' END
							+')'
			END	
			ELSE
				---- Is Equal To
			BEGIN
					IF @NameValue IS NOT NULL
					SET @sql = @sql + ' AND (CF.MemberFirstName = @NameValue OR CF.MemberLastName =@NameValue) '  
			END
		END

		 IF @NameType = 'Assigned To' AND @NameValue IS NOT NULL
		BEGIN
			IF @NameTypeOperator IN ('Begins With', 'Contains', 'Ends With') 
			BEGIN
				SET @sql = @sql + ' AND (AU.FirstName LIKE'
							+ CASE WHEN @NameTypeOperator IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @NameValue'
							+ CASE WHEN @NameTypeOperator IN ('Begins With', 'Contains') THEN ' +CHAR(37)' ELSE '' END
							+' OR AU.LastName LIKE'
							+ CASE WHEN @NameTypeOperator IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @NameValue'
							+ CASE WHEN @NameTypeOperator IN ('Begins With', 'Contains') THEN ' +CHAR(37)' ELSE '' END
							+')'
			END	
			ELSE
				---- Is Equal To
			BEGIN
					IF @NameValue IS NOT NULL
					SET @sql = @sql + ' AND (AU.FirstName = @NameValue OR AU.LastName =@NameValue) '  
			END
		END

	-- STATUSES
	IF ISNULL(@Statuses,'') <> ''
	BEGIN
		SET @sql = @sql + ' AND CFS.ID IN (SELECT ID FROM @tmpStatuses)'
	END

	IF ISNULL(@Sources,'') <> ''
	BEGIN
		SET @sql = @sql + ' AND CFSO.ID IN (SELECT ID FROM @tmpSources)'
	END


	IF ISNULL(@FeedbackTypes,'') <> ''
	BEGIN
		SET @sql = @sql + ' AND CFT.ID IN (SELECT ID FROM @tmpFeedbackTypes)'
	END

	IF ISNULL(@Priorities,'') <> ''
	BEGIN
		SET @sql = @sql + ' AND CFP.ID IN (SELECT ID FROM @tmpPriorities)'
	END

	IF @ReceivedFromDate IS NOT NULL 
		BEGIN
		 SET @sql  = @sql + ' AND  CF.ReceiveDate >= @ReceivedFromDate'
		END
	
	IF @ReceivedToDate IS NOT NULL
	BEGIN
	  SET @sql  = @sql + ' AND  CF.ReceiveDate <= @ReceivedToDate'
	END

	IF ISNULL(@NextAction,'')<>''
	BEGIN
	 SET @sql  = @sql + ' AND  NA.ID = @NextAction'
	END

	IF ISNULL(@Client,'')<>''
	BEGIN
	 SET @sql  = @sql + ' AND  CL.ID = @Client'
	END

	IF ISNULL(@Program,'')<>''
	BEGIN
	 SET @sql  = @sql + ' AND  P.ID = @Program'
	END

	-- DEBUG: 	SELECT @sql
	
	-- Filter the records
	INSERT INTO #FinalResultsFiltered
	EXEC sp_executesql @sql,N'@NumberValue NVARCHAR(100),
								@NameValue NVARCHAR(MAX),
								@tmpStatuses intTableType READONLY,
								@tmpSources intTableType READONLY,
								@tmpFeedbackTypes intTableType READONLY,
								@tmpPriorities intTableType READONLY,
								@ReceivedFromDate DATETIME,
								@ReceivedToDate DATETIME,
								@NextAction NVARCHAR(100),
								@Client INT,
								@Program INT',
								@NumberValue,
								@NameValue,
								@tmpStatuses,
								@tmpSources,
								@tmpFeedbackTypes,
								@tmpPriorities,
								@ReceivedFromDate,
								@ReceivedToDate,
								@NextAction,
								@Client,
								@Program


	;WITH wFormattedAfterClearingDuplicates
	AS(
		SELECT ROW_NUMBER() OVER (PARTITION BY CustomerFeedbackID ORDER BY PurchaseOrderNumber) AS RowNum,
		CustomerFeedbackID,  
		[Status],  
		[Source],  
		[Priority], 
		[PrioritySequence], 
		[CreatedBy],  
		COALESCE(AssignedToFirstName,'') + COALESCE(' ' + AssignedToLastName,'') AS AssignedTo,
		MemberFirstName,  
		MemberLastName,  
		MemberID,
		MemberNumber,
		ClientID,
		ClientName,
		ProgramID,
		ProgramName,
		PurchaseOrderNumber,
		ServiceRequestID,
		[Type],  
		[TypeSequence],
		DateOfService,
		NextAction,  
		COALESCE(NextActionAssignedToFirstName,'') + COALESCE(' ' + NextActionAssignedToLastName,'') AS NextActionAssignedTo,  	
		NextActionScheduledDate,	 
		DescriptionofConcern,
		ISNULL(DueDate,'9999-9-9') AS DueDate, /* Force null values to be future dates */
		WorkedBy
		FROM #FinalResultsFiltered
	)
	
	INSERT INTO #FinalResultsFormatted
	SELECT	CustomerFeedbackID,  
			[Status],  
			[Source],  
			[Priority], 
			[PrioritySequence],  
			[CreatedBy],  
			AssignedTo,
			MemberFirstName,  
			MemberLastName,  
			MemberID,
			MemberNumber,
			ClientID,
			ClientName,
			ProgramID,
			ProgramName,
			PurchaseOrderNumber,
			ServiceRequestID,
			[Type],  
			DateOfService,
			NextAction,  
			NextActionAssignedTo, 
			NextActionScheduledDate, 		 
			DescriptionofConcern,
			DueDate,
			WorkedBy
	FROM	wFormattedAfterClearingDuplicates
	WHERE	RowNum = 1
	ORDER BY [PrioritySequence] DESC, DueDate ASC, TypeSequence ASC

	DECLARE @openCount INT = 0,
			@closedCount INT = 0,
			@researchCompletedCount INT = 0,
			@inProgressCount INT = 0,
			@pendingCount INT = 0

	SELECT @openCount = COUNT(*) FROM #FinalResultsFormatted WHERE [Status] = 'Open'
	SELECT @closedCount = COUNT(*) FROM #FinalResultsFormatted WHERE [Status] = 'Closed'
	SELECT @researchCompletedCount = COUNT(*) FROM #FinalResultsFormatted WHERE [Status] = 'Research Completed'
	SELECT @inProgressCount = COUNT(*) FROM #FinalResultsFormatted WHERE [Status] = 'In Progress'
	SELECT @pendingCount = COUNT(*) FROM #FinalResultsFormatted WHERE [Status] = 'Pending'

	INSERT INTO #FinalResultsSorted
	SELECT	CustomerFeedbackID,  
			[Status],  
			[Source],  
			[Priority], 
			[PrioritySequence],  
			[CreatedBy],  
			AssignedTo,
			MemberFirstName,  
			MemberLastName,  
			MemberID,
			MemberNumber,
			ClientID,
			ClientName,
			ProgramID,
			ProgramName,
			PurchaseOrderNumber,
			ServiceRequestID,
			[Type],  
			DateOfService,
			NextAction,  
			CASE WHEN LEN(LTRIM(RTRIM(ISNULL(AssignedTo,'')))) = 0 THEN NextActionAssignedTo ELSE '*' + AssignedTo END, -- TFS 1670
			NextActionScheduledDate,  		 
			DescriptionofConcern,
			DueDate,
			WorkedBy
	FROM	#FinalResultsFormatted F
	ORDER BY 
		CASE WHEN @sortColumn = 'CustomerFeedbackID' AND @sortOrder = 'ASC'    
		THEN F.CustomerFeedbackID END,
		CASE WHEN @sortColumn = 'CustomerFeedbackID' AND @sortOrder = 'DESC'    
		THEN F.CustomerFeedbackID END DESC,
	    
		CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'    
		THEN F.[Status] END,
		CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'    
		THEN F.[Status] END DESC,

		CASE WHEN @sortColumn = 'Source' AND @sortOrder = 'ASC'    
		THEN F.[Source] END,
		CASE WHEN @sortColumn = 'Source' AND @sortOrder = 'DESC'    
		THEN F.[Source] END DESC,

		CASE WHEN @sortColumn = 'Priority' AND @sortOrder = 'ASC'    
		THEN F.[PrioritySequence] END,
		CASE WHEN @sortColumn = 'Priority' AND @sortOrder = 'DESC'    
		THEN F.[PrioritySequence] END DESC,

		CASE WHEN @sortColumn = 'CreatedBy' AND @sortOrder = 'ASC'    
		THEN F.CreatedBy END,
		CASE WHEN @sortColumn = 'CreatedBy' AND @sortOrder = 'DESC'    
		THEN F.CreatedBy END DESC,

		CASE WHEN @sortColumn = 'MemberFirstName' AND @sortOrder = 'ASC'    
		THEN F.MemberFirstName END,
		CASE WHEN @sortColumn = 'MemberFirstName' AND @sortOrder = 'DESC'    
		THEN F.MemberFirstName END DESC,

		CASE WHEN @sortColumn = 'MemberLastName' AND @sortOrder = 'ASC'    
		THEN F.MemberLastName END,
		CASE WHEN @sortColumn = 'MemberLastName' AND @sortOrder = 'DESC'    
		THEN F.MemberLastName END DESC,

		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'    
		THEN F.MemberNumber END,
		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'    
		THEN F.MemberNumber END DESC,

		CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'ASC'    
		THEN F.PurchaseOrderNumber END,
		CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'DESC'    
		THEN F.PurchaseOrderNumber END DESC,

		CASE WHEN @sortColumn = 'ServiceRequestID' AND @sortOrder = 'ASC'    
		THEN F.ServiceRequestID END,
		CASE WHEN @sortColumn = 'ServiceRequestID' AND @sortOrder = 'DESC'    
		THEN F.ServiceRequestID END DESC,

		CASE WHEN @sortColumn = 'Type' AND @sortOrder = 'ASC'    
		THEN F.Type END,
		CASE WHEN @sortColumn = 'Type' AND @sortOrder = 'DESC'    
		THEN F.Type END DESC,

		CASE WHEN @sortColumn = 'DateofService' AND @sortOrder = 'ASC'    
		THEN F.DateofService END,
		CASE WHEN @sortColumn = 'DateofService' AND @sortOrder = 'DESC'    
		THEN F.DateofService END DESC,

		CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'ASC'    
		THEN F.NextAction END,
		CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'DESC'    
		THEN F.NextAction END DESC,

		CASE WHEN @sortColumn = 'NextActionAssignedTo' AND @sortOrder = 'ASC'    
		THEN F.NextActionAssignedTo END,
		CASE WHEN @sortColumn = 'NextActionAssignedTo' AND @sortOrder = 'DESC'    
		THEN F.NextActionAssignedTo END DESC,

		CASE WHEN @sortColumn = 'NextActionScheduledDate' AND @sortOrder = 'ASC'    
		THEN F.NextActionScheduledDate END,
		CASE WHEN @sortColumn = 'NextActionScheduledDate' AND @sortOrder = 'DESC'    
		THEN F.NextActionScheduledDate END DESC,

		CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'ASC'    
		THEN F.AssignedTo END,
		CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'DESC'    
		THEN F.AssignedTo END DESC,

		CASE WHEN @sortColumn = 'DescriptionofConcern' AND @sortOrder = 'ASC'    
		THEN F.DescriptionofConcern END,
		CASE WHEN @sortColumn = 'DescriptionofConcern' AND @sortOrder = 'DESC'    
		THEN F.DescriptionofConcern END DESC,

		CASE WHEN @sortColumn = 'DueDate' AND @sortOrder = 'ASC'    
		THEN F.DueDate END,
		CASE WHEN @sortColumn = 'DueDate' AND @sortOrder = 'DESC'    
		THEN F.DueDate END DESC,

		CASE WHEN @sortColumn = 'WorkedBy' AND @sortOrder = 'ASC'    
		THEN F.WorkedBy END,
		CASE WHEN @sortColumn = 'WorkedBy' AND @sortOrder = 'DESC'    
		THEN F.WorkedBy END DESC

	DECLARE @count INT       
	SET @count = 0       
	SELECT @count = MAX(RowNum) FROM #FinalResultsSorted    
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
	
	-- Take the required set (say 10 out of "n").	
	SELECT	@count AS TotalRows, 
			[RowNum],
			CustomerFeedbackID,
			[Status],
			[Source],
			[Priority],
			[PrioritySequence],
			[CreatedBy],
			AssignedTo,
			MemberFirstName,
			MemberLastName,
			MemberID,
			MemberNumber,
			ClientID,
			ClientName,
			ProgramID,
			ProgramName,
			PurchaseOrderNumber,
			ServiceRequestID,
			[Type],
			DateofService ,
			NextAction,
			NextActionAssignedTo,
			NextActionScheduledDate ,
			DescriptionofConcern,
			CASE WHEN DueDate = '9999-9-9' THEN NULL ELSE DueDate END AS DueDate,
			WorkedBy, 
			@closedCount AS ClosedCount, 
			@openCount AS OpenCount, 
			@inProgressCount AS InprogressCount, 
			@researchCompletedCount AS ResearchCompletedCount,
			@pendingCount AS PendingCount 
	FROM	#FinalResultsSorted F 
	WHERE	F.RowNum BETWEEN @startInd AND @endInd
	
	DROP TABLE #FinalResultsFiltered
	DROP TABLE #FinalResultsFormatted
	DROP TABLE #FinalResultsSorted
END
