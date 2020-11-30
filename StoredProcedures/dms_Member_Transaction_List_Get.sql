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
 WHERE id = object_id(N'[dbo].[dms_Member_Transaction_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_Transaction_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dms_Member_Transaction_List_Get]  @MemberID=4
 CREATE PROCEDURE [dbo].[dms_Member_Transaction_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @MemberID INT = NULL    
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF;
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
TypeOperator="-1" 
NumberOperator="-1" 
DateOperator="-1" 
StatusOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
TypeOperator INT NOT NULL,
TypeValue nvarchar(100) NULL,
NumberOperator INT NOT NULL,
NumberValue int NULL,
DateOperator INT NOT NULL,
DateValue datetime NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Type nvarchar(100)  NULL ,
	Number int  NULL ,
	Date datetime  NULL ,
	Status nvarchar(100)  NULL 
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Type nvarchar(100)  NULL ,
	Number int  NULL ,
	Date datetime  NULL ,
	Status nvarchar(100)  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@TypeOperator','INT'),-1),
	T.c.value('@TypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@NumberOperator','INT'),-1),
	T.c.value('@NumberValue','int') ,
	ISNULL(T.c.value('@DateOperator','INT'),-1),
	T.c.value('@DateValue','datetime') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT	'InboundCall' AS Type
		, IC.ID AS Number
		, IC.CreateDate AS Date
		, '' AS Status
FROM	InboundCall IC
WHERE	IC.MemberID = @MemberID

UNION

SELECT	'EmergencyAssistance'
		, EA.ID 
		, EA.CreateDate
		, '' AS Status
FROM	[Case] C
JOIN	EmergencyAssistance EA ON EA.CaseID = C.ID
WHERE	C.MemberID = @MemberID

UNION

SELECT	'ServiceRequest'
		, SR.ID
		, SR.CreateDate
		, SRS.Name AS Status
FROM	ServiceRequest SR
JOIN	ServiceRequestStatus SRS ON SRS.ID = SR.ServiceRequestStatusID
JOIN	[CASE] C ON C.ID = SR.CaseID
WHERE	C.MemberID = @MemberID

UNION

SELECT	'Vehicle'
		, V.ID
		, V.CreateDate
		, '' 
FROM	Vehicle V
WHERE	V.MemberID = @MemberID

INSERT INTO #FinalResults
SELECT 
	T.Type,
	T.Number,
	T.Date,
	T.Status
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.TypeOperator = -1 ) 
 OR 
	 ( TMP.TypeOperator = 0 AND T.Type IS NULL ) 
 OR 
	 ( TMP.TypeOperator = 1 AND T.Type IS NOT NULL ) 
 OR 
	 ( TMP.TypeOperator = 2 AND T.Type = TMP.TypeValue ) 
 OR 
	 ( TMP.TypeOperator = 3 AND T.Type <> TMP.TypeValue ) 
 OR 
	 ( TMP.TypeOperator = 4 AND T.Type LIKE TMP.TypeValue + '%') 
 OR 
	 ( TMP.TypeOperator = 5 AND T.Type LIKE '%' + TMP.TypeValue ) 
 OR 
	 ( TMP.TypeOperator = 6 AND T.Type LIKE '%' + TMP.TypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.NumberOperator = -1 ) 
 OR 
	 ( TMP.NumberOperator = 0 AND T.Number IS NULL ) 
 OR 
	 ( TMP.NumberOperator = 1 AND T.Number IS NOT NULL ) 
 OR 
	 ( TMP.NumberOperator = 2 AND T.Number = TMP.NumberValue ) 
 OR 
	 ( TMP.NumberOperator = 3 AND T.Number <> TMP.NumberValue ) 
 OR 
	 ( TMP.NumberOperator = 7 AND T.Number > TMP.NumberValue ) 
 OR 
	 ( TMP.NumberOperator = 8 AND T.Number >= TMP.NumberValue ) 
 OR 
	 ( TMP.NumberOperator = 9 AND T.Number < TMP.NumberValue ) 
 OR 
	 ( TMP.NumberOperator = 10 AND T.Number <= TMP.NumberValue ) 

 ) 

 AND 

 ( 
	 ( TMP.DateOperator = -1 ) 
 OR 
	 ( TMP.DateOperator = 0 AND T.Date IS NULL ) 
 OR 
	 ( TMP.DateOperator = 1 AND T.Date IS NOT NULL ) 
 OR 
	 ( TMP.DateOperator = 2 AND T.Date = TMP.DateValue ) 
 OR 
	 ( TMP.DateOperator = 3 AND T.Date <> TMP.DateValue ) 
 OR 
	 ( TMP.DateOperator = 7 AND T.Date > TMP.DateValue ) 
 OR 
	 ( TMP.DateOperator = 8 AND T.Date >= TMP.DateValue ) 
 OR 
	 ( TMP.DateOperator = 9 AND T.Date < TMP.DateValue ) 
 OR 
	 ( TMP.DateOperator = 10 AND T.Date <= TMP.DateValue ) 

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
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'Type' AND @sortOrder = 'ASC'
	 THEN T.Type END ASC, 
	 CASE WHEN @sortColumn = 'Type' AND @sortOrder = 'DESC'
	 THEN T.Type END DESC ,

	 CASE WHEN @sortColumn = 'Number' AND @sortOrder = 'ASC'
	 THEN T.Number END ASC, 
	 CASE WHEN @sortColumn = 'Number' AND @sortOrder = 'DESC'
	 THEN T.Number END DESC ,

	 CASE WHEN @sortColumn = 'Date' AND @sortOrder = 'ASC'
	 THEN T.Date END ASC, 
	 CASE WHEN @sortColumn = 'Date' AND @sortOrder = 'DESC'
	 THEN T.Date END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC 


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
