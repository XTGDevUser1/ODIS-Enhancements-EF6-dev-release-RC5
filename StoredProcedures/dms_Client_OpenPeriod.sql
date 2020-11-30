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
 WHERE id = object_id(N'[dbo].[dms_Client_OpenPeriod]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Client_OpenPeriod] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Client_OpenPeriod]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
	SET FMTONLY OFF

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
BillingScheduleIDOperator="-1" 
ScheduleNameOperator="-1" 
ScheduleDateOperator="-1" 
ScheduleRangeBeginOperator="-1" 
ScheduleRangeEndOperator="-1" 
StatusOperator="-1" 
InvoicesToBeCreatedCountOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
BillingScheduleIDOperator INT NOT NULL,
BillingScheduleIDValue int NULL,
ScheduleNameOperator INT NOT NULL,
ScheduleNameValue nvarchar(100) NULL,
ScheduleDateOperator INT NOT NULL,
ScheduleDateValue datetime NULL,
ScheduleRangeBeginOperator INT NOT NULL,
ScheduleRangeBeginValue datetime NULL,
ScheduleRangeEndOperator INT NOT NULL,
ScheduleRangeEndValue datetime NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL,
InvoicesToBeCreatedCountOperator INT NOT NULL,
InvoicesToBeCreatedCountValue int NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	BillingScheduleID int  NULL ,
	ScheduleName nvarchar(50)  NULL ,
	ScheduleDate datetime  NULL ,
	ScheduleRangeBegin datetime  NULL ,
	ScheduleRangeEnd datetime  NULL ,
	Status nvarchar(50)  NULL ,
	InvoicesToBeCreatedCount int  NULL 
) 

DECLARE @QueryResult AS TABLE( 
	BillingScheduleID int  NULL ,
	ScheduleName nvarchar(50)  NULL ,
	ScheduleDate datetime  NULL ,
	ScheduleRangeBegin datetime  NULL ,
	ScheduleRangeEnd datetime  NULL ,
	Status nvarchar(50)  NULL ,
	InvoicesToBeCreatedCount int  NULL 
) 

INSERT INTO @QueryResult
SELECT	bs.ID as BillingScheduleID,
		bs.Name as ScheduleName,
		bs.ScheduleDate,
		bs.ScheduleRangeBegin,
		bs.ScheduleRangeEnd,
		bss.Name as [Status],
		tt.InvoicesToBeCreatedCount
FROM	BillingSchedule bs with (nolock)
left outer join	BillingScheduleType bst with (nolock) on bst.ID = bs.ScheduleTypeID
left outer join	BillingScheduleStatus bss with (nolock) on bss.ID = bs.ScheduleStatusID
left outer join	BillingScheduleRangeType bsrt with (nolock) on bsrt.ID = bs.ScheduleRangeTypeID
left outer join	BillingScheduleDateType bsdt with (nolock) on bsdt.ID = bs.ScheduleDateTypeID
left outer join
	(SELECT bs.ID AS BillingScheduleID, 
			count(*) InvoicesToBeCreatedCount
	from	BillingSchedule bs
	join	BillingDefinitionInvoice bdi on bdi.ScheduleTypeID = bs.ScheduleTypeID
	and		bdi.ScheduleDateTypeID = bs.ScheduleDateTypeID
	and		bdi.ScheduleRangeTypeID = bs.ScheduleRangeTypeID
	and		bdi.IsActive = 1
	group by
			bs.ID
	)tt on tt.BillingScheduleID = bs.ID
WHERE bss.Name = 'PENDING' 
	and bs.IsActive = 1

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@BillingScheduleIDOperator','INT'),-1),
	T.c.value('@BillingScheduleIDValue','int') ,
	ISNULL(T.c.value('@ScheduleNameOperator','INT'),-1),
	T.c.value('@ScheduleNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ScheduleDateOperator','INT'),-1),
	T.c.value('@ScheduleDateValue','datetime') ,
	ISNULL(T.c.value('@ScheduleRangeBeginOperator','INT'),-1),
	T.c.value('@ScheduleRangeBeginValue','datetime') ,
	ISNULL(T.c.value('@ScheduleRangeEndOperator','INT'),-1),
	T.c.value('@ScheduleRangeEndValue','datetime') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@InvoicesToBeCreatedCountOperator','INT'),-1),
	T.c.value('@InvoicesToBeCreatedCountValue','int') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.BillingScheduleID,
	T.ScheduleName,
	T.ScheduleDate,
	T.ScheduleRangeBegin,
	T.ScheduleRangeEnd,
	T.Status,
	T.InvoicesToBeCreatedCount
FROM @QueryResult T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.BillingScheduleIDOperator = -1 ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 0 AND T.BillingScheduleID IS NULL ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 1 AND T.BillingScheduleID IS NOT NULL ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 2 AND T.BillingScheduleID = TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 3 AND T.BillingScheduleID <> TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 7 AND T.BillingScheduleID > TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 8 AND T.BillingScheduleID >= TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 9 AND T.BillingScheduleID < TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 10 AND T.BillingScheduleID <= TMP.BillingScheduleIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleNameOperator = -1 ) 
 OR 
	 ( TMP.ScheduleNameOperator = 0 AND T.ScheduleName IS NULL ) 
 OR 
	 ( TMP.ScheduleNameOperator = 1 AND T.ScheduleName IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleNameOperator = 2 AND T.ScheduleName = TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 3 AND T.ScheduleName <> TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 4 AND T.ScheduleName LIKE TMP.ScheduleNameValue + '%') 
 OR 
	 ( TMP.ScheduleNameOperator = 5 AND T.ScheduleName LIKE '%' + TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 6 AND T.ScheduleName LIKE '%' + TMP.ScheduleNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ScheduleDateOperator = -1 ) 
 OR 
	 ( TMP.ScheduleDateOperator = 0 AND T.ScheduleDate IS NULL ) 
 OR 
	 ( TMP.ScheduleDateOperator = 1 AND T.ScheduleDate IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleDateOperator = 2 AND T.ScheduleDate = TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 3 AND T.ScheduleDate <> TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 7 AND T.ScheduleDate > TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 8 AND T.ScheduleDate >= TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 9 AND T.ScheduleDate < TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 10 AND T.ScheduleDate <= TMP.ScheduleDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleRangeBeginOperator = -1 ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 0 AND T.ScheduleRangeBegin IS NULL ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 1 AND T.ScheduleRangeBegin IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 2 AND T.ScheduleRangeBegin = TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 3 AND T.ScheduleRangeBegin <> TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 7 AND T.ScheduleRangeBegin > TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 8 AND T.ScheduleRangeBegin >= TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 9 AND T.ScheduleRangeBegin < TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 10 AND T.ScheduleRangeBegin <= TMP.ScheduleRangeBeginValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleRangeEndOperator = -1 ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 0 AND T.ScheduleRangeEnd IS NULL ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 1 AND T.ScheduleRangeEnd IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 2 AND T.ScheduleRangeEnd = TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 3 AND T.ScheduleRangeEnd <> TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 7 AND T.ScheduleRangeEnd > TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 8 AND T.ScheduleRangeEnd >= TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 9 AND T.ScheduleRangeEnd < TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 10 AND T.ScheduleRangeEnd <= TMP.ScheduleRangeEndValue ) 

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
	 ( TMP.InvoicesToBeCreatedCountOperator = -1 ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 0 AND T.InvoicesToBeCreatedCount IS NULL ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 1 AND T.InvoicesToBeCreatedCount IS NOT NULL ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 2 AND T.InvoicesToBeCreatedCount = TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 3 AND T.InvoicesToBeCreatedCount <> TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 7 AND T.InvoicesToBeCreatedCount > TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 8 AND T.InvoicesToBeCreatedCount >= TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 9 AND T.InvoicesToBeCreatedCount < TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 10 AND T.InvoicesToBeCreatedCount <= TMP.InvoicesToBeCreatedCountValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'ASC'
	 THEN T.BillingScheduleID END ASC, 
	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'DESC'
	 THEN T.BillingScheduleID END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleName' AND @sortOrder = 'ASC'
	 THEN T.ScheduleName END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleName' AND @sortOrder = 'DESC'
	 THEN T.ScheduleName END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleDate' AND @sortOrder = 'ASC'
	 THEN T.ScheduleDate END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleDate' AND @sortOrder = 'DESC'
	 THEN T.ScheduleDate END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeBegin' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeBegin END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeBegin' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeBegin END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeEnd' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeEnd END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeEnd' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeEnd END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC ,

	 CASE WHEN @sortColumn = 'InvoicesToBeCreatedCount' AND @sortOrder = 'ASC'
	 THEN T.InvoicesToBeCreatedCount END ASC, 
	 CASE WHEN @sortColumn = 'InvoicesToBeCreatedCount' AND @sortOrder = 'DESC'
	 THEN T.InvoicesToBeCreatedCount END DESC 


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