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
 -- EXEC dms_Program_Management_ProgramConfigurationList @programID = 1,@pageSize=50
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_ProgramConfigurationList]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_ProgramConfigurationList] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_ProgramConfigurationList]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID INT = NULL
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
    SET FMTONLY OFF
    
DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
ProgramConfigurationIDOperator="-1" 
ConfigurationTypeOperator="-1" 
ConfigurationCategoryOperator="-1" 
NameOperator="-1" 
ValueOperator="-1" 
ControlTypeOperator="-1" 
DataTypeOperator="-1" 
IsActiveOperator="-1" 
SequenceOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

CREATE TABLE #tmpForWhereClause
(
ProgramNameOperator INT NOT NULL,
ProgramNameValue nvarchar(50) NULL,
ProgramConfigurationIDOperator INT NOT NULL,
ProgramConfigurationIDValue INT NULL,
ConfigurationTypeOperator INT NOT NULL,
ConfigurationTypeValue nvarchar(50) NULL,
ConfigurationCategoryOperator INT NOT NULL,
ConfigurationCategoryValue nvarchar(50) NULL,
NameOperator INT NOT NULL,
NameValue nvarchar(50) NULL,
ValueOperator INT NOT NULL,
ValueValue nvarchar(50) NULL,
ControlTypeOperator INT NOT NULL,
ControlTypeValue nvarchar(50) NULL,
DataTypeOperator INT NOT NULL,
DataTypeValue nvarchar(50) NULL,
SequenceOperator INT NOT NULL,
SequenceValue INT NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue nvarchar(50) NULL
)

CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramID INT NOT NULL,
	ProgramName nvarchar(50) NULL,
	ProgramConfigurationID int  NULL ,
	ConfigurationType nvarchar(50) NULL,
	ConfigurationCategory nvarchar(50) NULL,
	Name nvarchar(MAX)  NULL ,
	Value nvarchar(MAX)  NULL ,
	IsActive nvarchar(50)  NULL ,
	ControlType nvarchar(50) NULL,
	DataType nvarchar(50) NULL,
	Sequence INT NULL
) 
DECLARE @QueryResult AS TABLE( 
	ProgramID INT NOT NULL,
	ProgramName nvarchar(50) NULL,
	ProgramConfigurationID int  NULL ,
	ConfigurationType nvarchar(50) NULL,
	ConfigurationCategory nvarchar(50) NULL,
	Name nvarchar(MAX)  NULL ,
	Value nvarchar(MAX)  NULL ,
	IsActive nvarchar(50)  NULL ,
	ControlType nvarchar(50) NULL,
	DataType nvarchar(50) NULL,
	Sequence INT NULL
) 

;WITH wProgramConfig 
		AS
		(	SELECT ROW_NUMBER() OVER ( PARTITION BY PC.Name ORDER BY PP.Sequence) AS RowNum,
					PP.ProgramID,
					P.Name ProgramName,
					PC.ID ProgramConfigurationID,
					PC.Sequence,
					PC.Name,	
					PC.Value,
					CASE ISNULL(PC.IsActive,0) WHEN 0 THEN 'No' ELSE 'Yes' END IsActiveText,
					CT.Name ControlType,
					DT.Name DataType,
					C.Name ConfigurationType,
					CC.Name ConfigurationCategory,
					PP.Sequence FnSequence
			FROM fnc_GetProgramsandParents(@ProgramID) PP
			JOIN ProgramConfiguration PC ON PP.ProgramID = PC.ProgramID AND PC.IsActive = 1
			LEFT JOIN Program P ON PP.ProgramID = P.ID
			LEFT JOIN ConfigurationType C ON PC.ConfigurationTypeID = C.ID 
			LEFT JOIN ControlType CT ON CT.ID = PC.ControlTypeID
			LEFT JOIN DataType DT ON DT.ID = PC.DataTypeID
			LEFT JOIN ConfigurationCategory CC ON PC.ConfigurationCategoryID = CC.ID
			--WHERE	(@ConfigurationType IS NULL OR C.Name = @ConfigurationType)
			--AND		(@ConfigurationCategory IS NULL OR CC.Name = @ConfigurationCategory)
		)
INSERT INTO @QueryResult SELECT
								W.ProgramID,
								W.ProgramName,
							    W.ProgramConfigurationID,	
								W.ConfigurationType,
								W.ConfigurationCategory,
								W.Name,
								W.Value,
								W.IsActiveText,
								W.ControlType,
								W.DataType,
								W.Sequence
						FROM	wProgramConfig W
						 WHERE	W.RowNum = 1
					   ORDER BY W.FnSequence, W.ProgramConfigurationID


INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(ProgramNameOperator,-1),
	ProgramNameValue ,
	ISNULL(ProgramConfigurationIDOperator,-1),
	ProgramConfigurationIDValue ,
	ISNULL(ConfigurationTypeOperator,-1),
	ConfigurationTypeValue ,
	ISNULL(ConfigurationCategoryOperator,-1),
	ConfigurationCategoryValue ,
	ISNULL(NameOperator,-1),
	NameValue ,
	ISNULL(ValueOperator,-1),
	ValueValue,
	ISNULL(ControlTypeOperator,-1),
	ControlTypeValue , 
	ISNULL(DataTypeOperator,-1),
	DataTypeValue , 
	ISNULL(SequenceOperator,-1),
	SequenceValue,
	ISNULL(IsActiveOperator,-1),
	IsActiveValue
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
ProgramNameOperator INT,
ProgramNameValue nvarchar(50) ,
ProgramConfigurationIDOperator INT,
ProgramConfigurationIDValue int 
,ConfigurationTypeOperator INT,
ConfigurationTypeValue nvarchar(50) 
,ConfigurationCategoryOperator INT,
ConfigurationCategoryValue nvarchar(50) 
,NameOperator INT,
NameValue nvarchar(50) 
,ValueOperator INT,
ValueValue nvarchar(50) 
,ControlTypeOperator INT,
ControlTypeValue nvarchar(50) 
,DataTypeOperator INT,
DataTypeValue nvarchar(50)
,SequenceOperator INT,
SequenceValue nvarchar(50)
,IsActiveOperator INT,
IsActiveValue nvarchar(50)    
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.ProgramID,
	T.ProgramName,
	T.ProgramConfigurationID,
	T.ConfigurationType,
	T.ConfigurationCategory,
	T.Name,
	T.Value,
	T.IsActive,
	T.ControlType,
	T.DataType,
	T.Sequence
FROM @QueryResult T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.ProgramConfigurationIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 0 AND T.ProgramConfigurationID IS NULL ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 1 AND T.ProgramConfigurationID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 2 AND T.ProgramConfigurationID = TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 3 AND T.ProgramConfigurationID <> TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 7 AND T.ProgramConfigurationID > TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 8 AND T.ProgramConfigurationID >= TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 9 AND T.ProgramConfigurationID < TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 10 AND T.ProgramConfigurationID <= TMP.ProgramConfigurationIDValue ) 

 ) 
  AND 

 ( 
	 ( TMP.ConfigurationTypeOperator = -1 ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 0 AND T.ConfigurationType IS NULL ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 1 AND T.ConfigurationType IS NOT NULL ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 2 AND T.ConfigurationType = TMP.ConfigurationTypeValue ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 3 AND T.ConfigurationType <> TMP.ConfigurationTypeValue ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 4 AND T.ConfigurationType LIKE TMP.ConfigurationTypeValue + '%') 
 OR 
	 ( TMP.ConfigurationTypeOperator = 5 AND T.ConfigurationType LIKE '%' + TMP.ConfigurationTypeValue ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 6 AND T.ConfigurationType LIKE '%' + TMP.ConfigurationTypeValue + '%' ) 
 ) 
 AND 

 ( 
	 ( TMP.ConfigurationCategoryOperator = -1 ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 0 AND T.ConfigurationCategory IS NULL ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 1 AND T.ConfigurationCategory IS NOT NULL ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 2 AND T.ConfigurationCategory = TMP.ConfigurationCategoryValue ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 3 AND T.ConfigurationCategory <> TMP.ConfigurationCategoryValue ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 4 AND T.ConfigurationCategory LIKE TMP.ConfigurationCategoryValue + '%') 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 5 AND T.ConfigurationCategory LIKE '%' + TMP.ConfigurationCategoryValue ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 6 AND T.ConfigurationCategory LIKE '%' + TMP.ConfigurationCategoryValue + '%' ) 
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
	 ( TMP.IsActiveOperator = -1 ) 
 OR 
	 ( TMP.IsActiveOperator = 0 AND T.IsActive IS NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 1 AND T.IsActive IS NOT NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 2 AND T.IsActive = TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 3 AND T.IsActive <> TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 4 AND T.IsActive LIKE TMP.IsActiveValue + '%') 
 OR 
	 ( TMP.IsActiveOperator = 5 AND T.IsActive LIKE '%' + TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 6 AND T.IsActive LIKE '%' + TMP.IsActiveValue + '%' ) 
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
	 ( TMP.ValueOperator = -1 ) 
 OR 
	 ( TMP.ValueOperator = 0 AND T.Value IS NULL ) 
 OR 
	 ( TMP.ValueOperator = 1 AND T.Value IS NOT NULL ) 
 OR 
	 ( TMP.ValueOperator = 2 AND T.Value = TMP.ValueValue ) 
 OR 
	 ( TMP.ValueOperator = 3 AND T.Value <> TMP.ValueValue ) 
 OR 
	 ( TMP.ValueOperator = 4 AND T.Value LIKE TMP.ValueValue + '%') 
 OR 
	 ( TMP.ValueOperator = 5 AND T.Value LIKE '%' + TMP.ValueValue ) 
 OR 
	 ( TMP.ValueOperator = 6 AND T.Value LIKE '%' + TMP.ValueValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ProgramConfigurationID' AND @sortOrder = 'ASC'
	 THEN T.ProgramConfigurationID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramConfigurationID' AND @sortOrder = 'DESC'
	 THEN T.ProgramConfigurationID END DESC ,

	 CASE WHEN @sortColumn = 'ConfigurationType' AND @sortOrder = 'ASC'
	 THEN T.ConfigurationType END ASC, 
	 CASE WHEN @sortColumn = 'ConfigurationType' AND @sortOrder = 'DESC'
	 THEN T.ConfigurationType END DESC ,

     CASE WHEN @sortColumn = 'ConfigurationCategory' AND @sortOrder = 'ASC'
	 THEN T.ConfigurationCategory END ASC, 
	 CASE WHEN @sortColumn = 'ConfigurationCategory' AND @sortOrder = 'DESC'
	 THEN T.ConfigurationCategory END DESC ,
	 
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
	 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Value' AND @sortOrder = 'ASC'
	 THEN T.Value END ASC, 
	 CASE WHEN @sortColumn = 'Value' AND @sortOrder = 'DESC'
	 THEN T.Value END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC, 

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
END
