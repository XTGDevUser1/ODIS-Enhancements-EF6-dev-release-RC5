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
 WHERE id = object_id(N'[dbo].[dms_Client_ClosePeriod]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Client_ClosePeriod] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Client_ClosePeriod]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
BillingScheduleIDOperator="-1" 
ScheduleNameOperator="-1" 
ScheduleDateOperator="-1" 
ScheduleRangeBeginOperator="-1" 
ScheduleRangeEndOperator="-1" 
ScheduleTypeOperator="-1" 
ScheduleRangeTypeOperator="-1" 
ScheduleDateTypeOperator="-1" 
ScheduleStatusOperator="-1" 
TotalInvoiceCountOperator="-1" 
PostedInvoiceCountOperator="-1" 
CanBeClosedOperator="-1" 
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
ScheduleTypeOperator INT NOT NULL,
ScheduleTypeValue nvarchar(100) NULL,
ScheduleRangeTypeOperator INT NOT NULL,
ScheduleRangeTypeValue nvarchar(100) NULL,
ScheduleDateTypeOperator INT NOT NULL,
ScheduleDateTypeValue nvarchar(100) NULL,
ScheduleStatusOperator INT NOT NULL,
ScheduleStatusValue nvarchar(100) NULL,
TotalInvoiceCountOperator INT NOT NULL,
TotalInvoiceCountValue int NULL,
PostedInvoiceCountOperator INT NOT NULL,
PostedInvoiceCountValue int NULL,
CanBeClosedOperator INT NOT NULL,
CanBeClosedValue INT NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	BillingScheduleID int  NULL ,
	ScheduleName nvarchar(50)  NULL ,
	ScheduleDate datetime  NULL ,
	ScheduleRangeBegin datetime  NULL ,
	ScheduleRangeEnd datetime  NULL ,
	ScheduleType nvarchar(255)  NULL ,
	ScheduleRangeType nvarchar(255)  NULL ,
	ScheduleDateType nvarchar(255)  NULL ,
	ScheduleStatus nvarchar(255)  NULL ,
	TotalInvoiceCount int  NULL ,
	PostedInvoiceCount int  NULL ,
	CanBeClosed INT  NULL 
) 

DECLARE @QueryResult AS TABLE( 
	BillingScheduleID int  NULL ,
	ScheduleName nvarchar(50)  NULL ,
	ScheduleDate datetime  NULL ,
	ScheduleRangeBegin datetime  NULL ,
	ScheduleRangeEnd datetime  NULL ,
	ScheduleType nvarchar(255)  NULL ,
	ScheduleRangeType nvarchar(255)  NULL ,
	ScheduleDateType nvarchar(255)  NULL ,
	ScheduleStatus nvarchar(255)  NULL ,
	TotalInvoiceCount int  NULL ,
	PostedInvoiceCount int  NULL ,
	CanBeClosed INT  NULL 
) 

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
	ISNULL(T.c.value('@ScheduleTypeOperator','INT'),-1),
	T.c.value('@ScheduleTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ScheduleRangeTypeOperator','INT'),-1),
	T.c.value('@ScheduleRangeTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ScheduleDateTypeOperator','INT'),-1),
	T.c.value('@ScheduleDateTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ScheduleStatusOperator','INT'),-1),
	T.c.value('@ScheduleStatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@TotalInvoiceCountOperator','INT'),-1),
	T.c.value('@TotalInvoiceCountValue','int') ,
	ISNULL(T.c.value('@PostedInvoiceCountOperator','INT'),-1),
	T.c.value('@PostedInvoiceCountValue','int') ,
	ISNULL(T.c.value('@CanBeClosedOperator','INT'),-1),
	T.c.value('@CanBeClosedValue','INT') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @QueryResult
SELECT	bs.ID as BillingScheduleID,
		bs.Name as ScheduleName,
		bs.ScheduleDate,
		bs.ScheduleRangeBegin,
		bs.ScheduleRangeEnd,
		bst.[Description] as ScheduleType,
		bsrt.[Description] as ScheduleRangeType,
		bsdt.[Description] as ScheduleDateType,
		bss.[Description] as ScheduleStatus,
		tt.TotalInvoiceCount,
		pp.PostedInvoiceCount,
		case
		 when tt.TotalInvoiceCount = pp.PostedInvoiceCount then 1
		 else 0
		end as CanBeClosed
from	BillingSchedule bs with (nolock)
left outer join	BillingScheduleType bst with (nolock) on bst.ID = bs.ScheduleTypeID
left outer join	BillingScheduleStatus bss with (nolock) on bss.ID = bs.ScheduleStatusID
left outer join	BillingScheduleRangeType bsrt with (nolock) on bsrt.ID = bs.ScheduleRangeTypeID
left outer join	BillingScheduleDateType bsdt with (nolock) on bsdt.ID = bs.ScheduleDateTypeID
left outer join
	(select	BillingScheduleID,
			count(*) as TotalInvoiceCount
	 from	BillingInvoice bi with (nolock)
	 where	1=1
	 group by
			BillingScheduleID) tt on tt.BillingScheduleID = bs.ID
left outer join
	(select	BillingScheduleID,
			count(*) as PostedInvoiceCount
	 from	BillingInvoice bi with (nolock)
	 where	1=1
	 and	InvoiceStatusID = (select ID from BillingInvoiceStatus with (nolock) where Name = 'POSTED')
	 group by
			BillingScheduleID) pp on pp.BillingScheduleID = bs.ID
where	1=1
and		bss.Name = 'OPEN' -- Must be Open
and		bs.ScheduleDate < getdate() -- Must be after the schedule date

INSERT INTO #FinalResults
SELECT 
	T.BillingScheduleID,
	T.ScheduleName,
	T.ScheduleDate,
	T.ScheduleRangeBegin,
	T.ScheduleRangeEnd,
	T.ScheduleType,
	T.ScheduleRangeType,
	T.ScheduleDateType,
	T.ScheduleStatus,
	T.TotalInvoiceCount,
	T.PostedInvoiceCount,
	T.CanBeClosed
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
	 ( TMP.ScheduleTypeOperator = -1 ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 0 AND T.ScheduleType IS NULL ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 1 AND T.ScheduleType IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 2 AND T.ScheduleType = TMP.ScheduleTypeValue ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 3 AND T.ScheduleType <> TMP.ScheduleTypeValue ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 4 AND T.ScheduleType LIKE TMP.ScheduleTypeValue + '%') 
 OR 
	 ( TMP.ScheduleTypeOperator = 5 AND T.ScheduleType LIKE '%' + TMP.ScheduleTypeValue ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 6 AND T.ScheduleType LIKE '%' + TMP.ScheduleTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ScheduleRangeTypeOperator = -1 ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 0 AND T.ScheduleRangeType IS NULL ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 1 AND T.ScheduleRangeType IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 2 AND T.ScheduleRangeType = TMP.ScheduleRangeTypeValue ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 3 AND T.ScheduleRangeType <> TMP.ScheduleRangeTypeValue ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 4 AND T.ScheduleRangeType LIKE TMP.ScheduleRangeTypeValue + '%') 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 5 AND T.ScheduleRangeType LIKE '%' + TMP.ScheduleRangeTypeValue ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 6 AND T.ScheduleRangeType LIKE '%' + TMP.ScheduleRangeTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ScheduleDateTypeOperator = -1 ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 0 AND T.ScheduleDateType IS NULL ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 1 AND T.ScheduleDateType IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 2 AND T.ScheduleDateType = TMP.ScheduleDateTypeValue ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 3 AND T.ScheduleDateType <> TMP.ScheduleDateTypeValue ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 4 AND T.ScheduleDateType LIKE TMP.ScheduleDateTypeValue + '%') 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 5 AND T.ScheduleDateType LIKE '%' + TMP.ScheduleDateTypeValue ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 6 AND T.ScheduleDateType LIKE '%' + TMP.ScheduleDateTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ScheduleStatusOperator = -1 ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 0 AND T.ScheduleStatus IS NULL ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 1 AND T.ScheduleStatus IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 2 AND T.ScheduleStatus = TMP.ScheduleStatusValue ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 3 AND T.ScheduleStatus <> TMP.ScheduleStatusValue ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 4 AND T.ScheduleStatus LIKE TMP.ScheduleStatusValue + '%') 
 OR 
	 ( TMP.ScheduleStatusOperator = 5 AND T.ScheduleStatus LIKE '%' + TMP.ScheduleStatusValue ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 6 AND T.ScheduleStatus LIKE '%' + TMP.ScheduleStatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.TotalInvoiceCountOperator = -1 ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 0 AND T.TotalInvoiceCount IS NULL ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 1 AND T.TotalInvoiceCount IS NOT NULL ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 2 AND T.TotalInvoiceCount = TMP.TotalInvoiceCountValue ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 3 AND T.TotalInvoiceCount <> TMP.TotalInvoiceCountValue ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 7 AND T.TotalInvoiceCount > TMP.TotalInvoiceCountValue ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 8 AND T.TotalInvoiceCount >= TMP.TotalInvoiceCountValue ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 9 AND T.TotalInvoiceCount < TMP.TotalInvoiceCountValue ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 10 AND T.TotalInvoiceCount <= TMP.TotalInvoiceCountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.PostedInvoiceCountOperator = -1 ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 0 AND T.PostedInvoiceCount IS NULL ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 1 AND T.PostedInvoiceCount IS NOT NULL ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 2 AND T.PostedInvoiceCount = TMP.PostedInvoiceCountValue ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 3 AND T.PostedInvoiceCount <> TMP.PostedInvoiceCountValue ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 7 AND T.PostedInvoiceCount > TMP.PostedInvoiceCountValue ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 8 AND T.PostedInvoiceCount >= TMP.PostedInvoiceCountValue ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 9 AND T.PostedInvoiceCount < TMP.PostedInvoiceCountValue ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 10 AND T.PostedInvoiceCount <= TMP.PostedInvoiceCountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CanBeClosedOperator = -1 ) 
 OR 
	 ( TMP.CanBeClosedOperator = 0 AND T.CanBeClosed IS NULL ) 
 OR 
	 ( TMP.CanBeClosedOperator = 1 AND T.CanBeClosed IS NOT NULL ) 
 OR 
	 ( TMP.CanBeClosedOperator = 2 AND T.CanBeClosed = TMP.CanBeClosedValue ) 
 OR 
	 ( TMP.CanBeClosedOperator = 3 AND T.CanBeClosed <> TMP.CanBeClosedValue ) 
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

	 CASE WHEN @sortColumn = 'ScheduleType' AND @sortOrder = 'ASC'
	 THEN T.ScheduleType END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleType' AND @sortOrder = 'DESC'
	 THEN T.ScheduleType END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeType' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeType END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeType' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeType END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleDateType' AND @sortOrder = 'ASC'
	 THEN T.ScheduleDateType END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleDateType' AND @sortOrder = 'DESC'
	 THEN T.ScheduleDateType END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleStatus' AND @sortOrder = 'ASC'
	 THEN T.ScheduleStatus END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleStatus' AND @sortOrder = 'DESC'
	 THEN T.ScheduleStatus END DESC ,

	 CASE WHEN @sortColumn = 'TotalInvoiceCount' AND @sortOrder = 'ASC'
	 THEN T.TotalInvoiceCount END ASC, 
	 CASE WHEN @sortColumn = 'TotalInvoiceCount' AND @sortOrder = 'DESC'
	 THEN T.TotalInvoiceCount END DESC ,

	 CASE WHEN @sortColumn = 'PostedInvoiceCount' AND @sortOrder = 'ASC'
	 THEN T.PostedInvoiceCount END ASC, 
	 CASE WHEN @sortColumn = 'PostedInvoiceCount' AND @sortOrder = 'DESC'
	 THEN T.PostedInvoiceCount END DESC ,

	 CASE WHEN @sortColumn = 'CanBeClosed' AND @sortOrder = 'ASC'
	 THEN T.CanBeClosed END ASC, 
	 CASE WHEN @sortColumn = 'CanBeClosed' AND @sortOrder = 'DESC'
	 THEN T.CanBeClosed END DESC 


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
