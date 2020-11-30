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
*  ---- for int, money, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Coverage_Information_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Coverage_Information_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_Program_Coverage_Information_List_Get @programID =100
 CREATE PROCEDURE [dbo].[dms_Program_Coverage_Information_List_Get]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID int = NULL 
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
NameOperator="-1" 
LimitOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
NameOperator INT NOT NULL,
NameValue nvarchar(50) NULL,
LimitOperator INT NOT NULL,
LimitValue nvarchar(50) NULL
)
DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Name nvarchar(50)  NULL ,
	Limit nvarchar(50)  NULL ,
	Vehicle nvarchar(50)  NULL 
) 

DECLARE @tmpFinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Name nvarchar(50)  NULL ,
	Limit nvarchar(50)  NULL ,
	Vehicle nvarchar(50)  NULL 
) 

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(NameOperator,-1),
	NameValue ,
	ISNULL(LimitOperator,-1),
	LimitValue 
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
NameOperator INT,
NameValue nvarchar(50) 
,LimitOperator INT,
LimitValue money 
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @tmpFinalResults
SELECT	pc.Name
, max(CASE
WHEN pp.ServiceCoverageLimit > 0 THEN '$' + CONVERT(NVARCHAR(10),CONVERT(NUMERIC(10),pp.ServiceCoverageLimit))
WHEN pp.ServiceCoverageLimit = 0 AND pp.IsServiceCoverageBestValue = 1 THEN 'Best Value'
WHEN pp.ServiceCoverageLimit = 0 AND pp.IsServiceCoverageBestValue = 0 THEN '$0'
WHEN pp.ServiceCoverageLimit >= 0 AND pp.IsReimbursementOnly = 1 THEN '$' + CONVERT(NVARCHAR(10),CONVERT(NUMERIC(10),pp.ServiceCoverageLimit)) + '-' + 'Reimbursement'
WHEN pp.ServiceCoverageLimit = 0 AND pp.IsReimbursementOnly = 0 THEN 'Assit Only'
ELSE ''
END) +
coalesce(max(CASE WHEN convert(nvarchar(3),pp.ServiceMileageLimit) > 0 THEN ' - ' + convert(nvarchar(3),pp.ServiceMileageLimit) + ' miles' ELSE '' END), '')
AS Limit
, max(CASE WHEN RIGHT(p.Name,2) = 'LD' THEN 'LD' ELSE '' END) +
coalesce('-' + max(CASE WHEN RIGHT(p.Name,2) = 'MD' THEN 'MD' END),'') +
coalesce('-'+max(CASE WHEN RIGHT(p.Name,2) = 'HD' THEN 'HD' END),'') AS Vehicle
FROM	ProgramProduct pp
JOIN	Product p (NOLOCK) ON p.id = pp.ProductID
JOIN	ProductCategory pc (NOLOCK) ON pc.id = p.productcategoryid
WHERE	pc.Name NOT IN ('Info','Repair','Billing')
AND	 pp.ProgramID = @ProgramID
GROUP BY pc.Name, pc.sequence
ORDER BY pc.Sequence
INSERT INTO @FinalResults
SELECT 
	T.Name,
	T.Limit,
	T.Vehicle
FROM @tmpFinalResults T,
@tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.NameOperator = -1 ) 
 OR 
	 ( TMP.NameOperator = 0 AND T.Name IS NULL ) 
 OR 
	 ( TMP.NameOperator = 1 AND T.Name IS NOT NULL ) 
 OR 
	 ( TMP.NameOperator = 2 AND T.Name = TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 3 AND T.Name <> TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 4 AND T.Name LIKE TMP.NameValue + '%') 
 OR 
	 ( TMP.NameOperator = 5 AND T.Name LIKE '%' + TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 6 AND T.Name LIKE '%' + TMP.NameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LimitOperator = -1 ) 
 OR 
	 ( TMP.LimitOperator = 0 AND T.Limit IS NULL ) 
 OR 
	 ( TMP.LimitOperator = 1 AND T.Limit IS NOT NULL ) 
 OR 
	 ( TMP.LimitOperator = 2 AND T.Limit = TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 3 AND T.Limit <> TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 7 AND T.Limit > TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 8 AND T.Limit >= TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 9 AND T.Limit < TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 10 AND T.Limit <= TMP.LimitValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Limit' AND @sortOrder = 'ASC'
	 THEN T.Limit END ASC, 
	 CASE WHEN @sortColumn = 'Limit' AND @sortOrder = 'DESC'
	 THEN T.Limit END DESC ,

	 CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'ASC'
	 THEN T.Vehicle END ASC, 
	 CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'DESC'
	 THEN T.Vehicle END DESC 


DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM @FinalResults
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

SELECT @count AS TotalRows, * FROM @FinalResults WHERE RowNum BETWEEN @startInd AND @endInd

END
