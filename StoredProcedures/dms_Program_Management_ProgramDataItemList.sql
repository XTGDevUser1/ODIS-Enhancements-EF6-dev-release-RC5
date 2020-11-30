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
 WHERE id = object_id(N'[dbo].[dms_Program_Management_ProgramDataItemList]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_ProgramDataItemList] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_Program_Management_ProgramDataItemList] @programID=45
 -- EXEC [dms_Program_Management_ProgramDataItemList] @programID=45
 CREATE PROCEDURE [dbo].[dms_Program_Management_ProgramDataItemList]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID INT = NULL 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
ProgramNameOperator="-1" 
ProgramDataItemIDOperator="-1" 
ScreenNameOperator="-1" 
NameOperator="-1" 
LabelOperator="-1" 
IsActiveOperator="-1" 
ControlTypeOperator="-1" 
DataTypeOperator="-1" 
SequenceOperator="-1" 
IsRequiredOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
ProgramNameOperator INT NOT NULL,
ProgramNameValue nvarchar(100) NULL,
ProgramDataItemIDOperator INT NOT NULL,
ProgramDataItemIDValue int NULL,
ScreenNameOperator INT NOT NULL,
ScreenNameValue nvarchar(100) NULL,
NameOperator INT NOT NULL,
NameValue nvarchar(100) NULL,
LabelOperator INT NOT NULL,
LabelValue nvarchar(100) NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue bit NULL,
ControlTypeOperator INT NOT NULL,
ControlTypeValue nvarchar(100) NULL,
DataTypeOperator INT NOT NULL,
DataTypeValue nvarchar(100) NULL,
SequenceOperator INT NOT NULL,
SequenceValue int NULL,
IsRequiredOperator INT NOT NULL,
IsRequiredValue bit NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramID INT NOT NULL,
	ProgramName nvarchar(100)  NULL,
	ProgramDataItemID int  NULL ,
	ScreenName nvarchar(100)  NULL ,
	Name nvarchar(100)  NULL ,
	Label nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	ControlType nvarchar(100)  NULL ,
	DataType nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsRequired bit  NULL 
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramID INT NOT NULL,
	ProgramName nvarchar(100)  NULL,
	ProgramDataItemID int  NULL ,
	ScreenName nvarchar(100)  NULL ,
	Name nvarchar(100)  NULL ,
	Label nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	ControlType nvarchar(100)  NULL ,
	DataType nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsRequired bit  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@ProgramNameOperator','INT'),-1),
	T.c.value('@ProgramNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProgramDataItemIDOperator','INT'),-1),
	T.c.value('@ProgramDataItemIDValue','int') ,
	ISNULL(T.c.value('@ScreenNameOperator','INT'),-1),
	T.c.value('@ScreenNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@NameOperator','INT'),-1),
	T.c.value('@NameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@LabelOperator','INT'),-1),
	T.c.value('@LabelValue','nvarchar(100)') ,
	ISNULL(T.c.value('@IsActiveOperator','INT'),-1),
	T.c.value('@IsActiveValue','bit') ,
	ISNULL(T.c.value('@ControlTypeOperator','INT'),-1),
	T.c.value('@ControlTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DataTypeOperator','INT'),-1),
	T.c.value('@DataTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@SequenceOperator','INT'),-1),
	T.c.value('@SequenceValue','int') ,
	ISNULL(T.c.value('@IsRequiredOperator','INT'),-1),
	T.c.value('@IsRequiredValue','bit') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT  PP.ProgramID,
		P.Name,
		PDI.ID ProgramDataItemID,
		PDI.ScreenName,
		PDI.Name,
		PDI.Label,
		PDI.IsActive,--CASE ISNULL(PC.IsActive,0) WHEN 0 THEN 'No' ELSE 'Yes' END IsActiveText,
		CT.[Description] ControlType,
		DT.[Description] DataType,
		PDI.Sequence,
		PDI.IsRequired
FROM fnc_GetProgramsandParents(@ProgramID) PP
JOIN Program P ON PP.ProgramID = P.ID
JOIN ProgramDataItem PDI ON PP.ProgramID = PDI.ProgramID AND PDI.IsActive = 1	
LEFT JOIN ControlType CT ON CT.ID = PDI.ControlTypeID
LEFT JOIN DataType DT ON DT.ID = PDI.DataTypeID
ORDER BY PDI.ScreenName,PDI.Sequence
INSERT INTO #FinalResults
SELECT 
	T.ProgramID,
	T.ProgramName,
	T.ProgramDataItemID,
	T.ScreenName,
	T.Name,
	T.Label,
	T.IsActive,
	T.ControlType,
	T.DataType,
	T.Sequence,
	T.IsRequired
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.ProgramDataItemIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 0 AND T.ProgramDataItemID IS NULL ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 1 AND T.ProgramDataItemID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 2 AND T.ProgramDataItemID = TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 3 AND T.ProgramDataItemID <> TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 7 AND T.ProgramDataItemID > TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 8 AND T.ProgramDataItemID >= TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 9 AND T.ProgramDataItemID < TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 10 AND T.ProgramDataItemID <= TMP.ProgramDataItemIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScreenNameOperator = -1 ) 
 OR 
	 ( TMP.ScreenNameOperator = 0 AND T.ScreenName IS NULL ) 
 OR 
	 ( TMP.ScreenNameOperator = 1 AND T.ScreenName IS NOT NULL ) 
 OR 
	 ( TMP.ScreenNameOperator = 2 AND T.ScreenName = TMP.ScreenNameValue ) 
 OR 
	 ( TMP.ScreenNameOperator = 3 AND T.ScreenName <> TMP.ScreenNameValue ) 
 OR 
	 ( TMP.ScreenNameOperator = 4 AND T.ScreenName LIKE TMP.ScreenNameValue + '%') 
 OR 
	 ( TMP.ScreenNameOperator = 5 AND T.ScreenName LIKE '%' + TMP.ScreenNameValue ) 
 OR 
	 ( TMP.ScreenNameOperator = 6 AND T.ScreenName LIKE '%' + TMP.ScreenNameValue + '%' ) 
 ) 
 AND 

 ( 
	 ( TMP.ProgramNameOperator = -1 ) 
 OR 
	 ( TMP.ProgramNameOperator = 0 AND T.ProgramName IS NULL ) 
 OR 
	 ( TMP.ProgramNameOperator = 1 AND T.ProgramName IS NOT NULL ) 
 OR 
	 ( TMP.ProgramNameOperator = 2 AND T.ProgramName = TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 3 AND T.ProgramName <> TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 4 AND T.ProgramName LIKE TMP.ProgramNameValue + '%') 
 OR 
	 ( TMP.ProgramNameOperator = 5 AND T.ProgramName LIKE '%' + TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 6 AND T.ProgramName LIKE '%' + TMP.ProgramNameValue + '%' ) 
 ) 

 AND 

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
	 ( TMP.LabelOperator = -1 ) 
 OR 
	 ( TMP.LabelOperator = 0 AND T.Label IS NULL ) 
 OR 
	 ( TMP.LabelOperator = 1 AND T.Label IS NOT NULL ) 
 OR 
	 ( TMP.LabelOperator = 2 AND T.Label = TMP.LabelValue ) 
 OR 
	 ( TMP.LabelOperator = 3 AND T.Label <> TMP.LabelValue ) 
 OR 
	 ( TMP.LabelOperator = 4 AND T.Label LIKE TMP.LabelValue + '%') 
 OR 
	 ( TMP.LabelOperator = 5 AND T.Label LIKE '%' + TMP.LabelValue ) 
 OR 
	 ( TMP.LabelOperator = 6 AND T.Label LIKE '%' + TMP.LabelValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.IsActiveOperator = -1 ) 
 OR 
	 ( TMP.IsActiveOperator = 0 AND T.IsActive IS NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 1 AND T.IsActive IS NOT NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 2 AND T.IsActive = TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 3 AND T.IsActive <> TMP.IsActiveValue ) 
 ) 

 AND 

 ( 
	 ( TMP.ControlTypeOperator = -1 ) 
 OR 
	 ( TMP.ControlTypeOperator = 0 AND T.ControlType IS NULL ) 
 OR 
	 ( TMP.ControlTypeOperator = 1 AND T.ControlType IS NOT NULL ) 
 OR 
	 ( TMP.ControlTypeOperator = 2 AND T.ControlType = TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 3 AND T.ControlType <> TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 4 AND T.ControlType LIKE TMP.ControlTypeValue + '%') 
 OR 
	 ( TMP.ControlTypeOperator = 5 AND T.ControlType LIKE '%' + TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 6 AND T.ControlType LIKE '%' + TMP.ControlTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DataTypeOperator = -1 ) 
 OR 
	 ( TMP.DataTypeOperator = 0 AND T.DataType IS NULL ) 
 OR 
	 ( TMP.DataTypeOperator = 1 AND T.DataType IS NOT NULL ) 
 OR 
	 ( TMP.DataTypeOperator = 2 AND T.DataType = TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 3 AND T.DataType <> TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 4 AND T.DataType LIKE TMP.DataTypeValue + '%') 
 OR 
	 ( TMP.DataTypeOperator = 5 AND T.DataType LIKE '%' + TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 6 AND T.DataType LIKE '%' + TMP.DataTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.SequenceOperator = -1 ) 
 OR 
	 ( TMP.SequenceOperator = 0 AND T.Sequence IS NULL ) 
 OR 
	 ( TMP.SequenceOperator = 1 AND T.Sequence IS NOT NULL ) 
 OR 
	 ( TMP.SequenceOperator = 2 AND T.Sequence = TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 3 AND T.Sequence <> TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 7 AND T.Sequence > TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 8 AND T.Sequence >= TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 9 AND T.Sequence < TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 10 AND T.Sequence <= TMP.SequenceValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsRequiredOperator = -1 ) 
 OR 
	 ( TMP.IsRequiredOperator = 0 AND T.IsRequired IS NULL ) 
 OR 
	 ( TMP.IsRequiredOperator = 1 AND T.IsRequired IS NOT NULL ) 
 OR 
	 ( TMP.IsRequiredOperator = 2 AND T.IsRequired = TMP.IsRequiredValue ) 
 OR 
	 ( TMP.IsRequiredOperator = 3 AND T.IsRequired <> TMP.IsRequiredValue ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ProgramDataItemID' AND @sortOrder = 'ASC'
	 THEN T.ProgramDataItemID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramDataItemID' AND @sortOrder = 'DESC'
	 THEN T.ProgramDataItemID END DESC ,

	 CASE WHEN @sortColumn = 'ScreenName' AND @sortOrder = 'ASC'
	 THEN T.ScreenName END ASC, 
	 CASE WHEN @sortColumn = 'ScreenName' AND @sortOrder = 'DESC'
	 THEN T.ScreenName END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Label' AND @sortOrder = 'ASC'
	 THEN T.Label END ASC, 
	 CASE WHEN @sortColumn = 'Label' AND @sortOrder = 'DESC'
	 THEN T.Label END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC ,

	 CASE WHEN @sortColumn = 'ControlType' AND @sortOrder = 'ASC'
	 THEN T.ControlType END ASC, 
	 CASE WHEN @sortColumn = 'ControlType' AND @sortOrder = 'DESC'
	 THEN T.ControlType END DESC ,

	 CASE WHEN @sortColumn = 'DataType' AND @sortOrder = 'ASC'
	 THEN T.DataType END ASC, 
	 CASE WHEN @sortColumn = 'DataType' AND @sortOrder = 'DESC'
	 THEN T.DataType END DESC ,

	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'
	 THEN T.Sequence END ASC, 
	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'
	 THEN T.Sequence END DESC ,

	 CASE WHEN @sortColumn = 'IsRequired' AND @sortOrder = 'ASC'
	 THEN T.IsRequired END ASC, 
	 CASE WHEN @sortColumn = 'IsRequired' AND @sortOrder = 'DESC'
	 THEN T.IsRequired END DESC,

	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'ASC'
	 THEN T.ProgramName END ASC, 
	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'DESC'
	 THEN T.ProgramName END DESC 


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

