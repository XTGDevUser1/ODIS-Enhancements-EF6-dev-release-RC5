IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ProgramManagement_VehicleTypes_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ProgramManagement_VehicleTypes_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_ProgramManagement_VehicleTypes_List_Get @programID = 72
 CREATE PROCEDURE [dbo].[dms_ProgramManagement_VehicleTypes_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID INT  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter
ProgramNameOperator = "-1" 
VehicleTypeOperator="-1" 
MaxAllowedOperator="-1" 
IsActiveOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
ProgramNameOperator INT NOT NULL,
ProgramNameValue nvarchar(50) NULL,
VehicleTypeOperator INT NOT NULL,
VehicleTypeValue NVARCHAR(50) NULL,
MaxAllowedOperator INT NOT NULL,
MaxAllowedValue int NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue bit NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramID INT NOT NULL,
	ProgramName nvarchar(50) NULL,
	ID int  NULL ,
	VehicleType NVARCHAR(50)  NULL ,
	MaxAllowed int  NULL ,
	IsActive bit  NULL 
) 
CREATE TABLE #tmp_FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramID INT NOT NULL,
	ProgramName nvarchar(50) NULL,
	ID int  NULL ,
	VehicleType NVARCHAR(50)  NULL ,
	MaxAllowed int  NULL ,
	IsActive bit  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@ProgramNameOperator','INT'),-1),
	T.c.value('@ProgramNameValue','nvarchar(50)') ,
	ISNULL(T.c.value('@VehicleTypeOperator','INT'),-1),
	T.c.value('@VehicleTypeValue','nvarchar(50)') ,
	ISNULL(T.c.value('@MaxAllowedOperator','INT'),-1),
	T.c.value('@MaxAllowedValue','int') ,
	ISNULL(T.c.value('@IsActiveOperator','INT'),-1),
	T.c.value('@IsActiveValue','bit') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

;WITH wProgramConfig 
		AS
		(	SELECT ROW_NUMBER() OVER ( PARTITION BY V.Name ORDER BY PP.Sequence) AS RowNum,
					PP.ProgramID,
					P.Name ProgramName,
					V.[Description] VehicleType,
					PV.MaxAllowed,
					PV.IsActive,
					PV.ID,
					PP.Sequence AS Sequence
			FROM fnc_GetProgramsandParents(@programID) PP
			JOIN ProgramVehicleType PV ON PV.ProgramID = PP.ProgramID 
			JOIN Program P ON PP.ProgramID = P.ID
			JOIN VehicleType V ON V.ID = PV.VehicleTypeID
			
		)
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmp_FinalResults
SELECT 
	W.ProgramID,
	W.ProgramName,
    W.ID,
    W.VehicleType,
	W.MaxAllowed,
	W.IsActive
FROM wProgramConfig W
	 WHERE	W.RowNum = 1
	 ORDER BY W.Sequence,W.ID
		 
INSERT INTO #FinalResults
SELECT 
	T.ProgramID,
	T.ProgramName,
	T.ID,
	T.VehicleType,
	T.MaxAllowed,
	T.IsActive
FROM #tmp_FinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.VehicleTypeOperator = -1 ) 
 OR 
	 ( TMP.VehicleTypeOperator = 0 AND T.VehicleType IS NULL ) 
 OR 
	 ( TMP.VehicleTypeOperator = 1 AND T.VehicleType IS NOT NULL ) 
 OR 
	 ( TMP.VehicleTypeOperator = 2 AND T.VehicleType = TMP.VehicleTypeValue ) 
 OR 
	 ( TMP.VehicleTypeOperator = 3 AND T.VehicleType <> TMP.VehicleTypeValue ) 
 OR 
	 ( TMP.VehicleTypeOperator = 4 AND T.VehicleType LIKE TMP.VehicleTypeValue + '%') 
 OR 
	 ( TMP.VehicleTypeOperator = 5 AND T.VehicleType LIKE '%' + TMP.VehicleTypeValue ) 
 OR 
	 ( TMP.VehicleTypeOperator = 6 AND T.VehicleType LIKE '%' + TMP.VehicleTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.MaxAllowedOperator = -1 ) 
 OR 
	 ( TMP.MaxAllowedOperator = 0 AND T.MaxAllowed IS NULL ) 
 OR 
	 ( TMP.MaxAllowedOperator = 1 AND T.MaxAllowed IS NOT NULL ) 
 OR 
	 ( TMP.MaxAllowedOperator = 2 AND T.MaxAllowed = TMP.MaxAllowedValue ) 
 OR 
	 ( TMP.MaxAllowedOperator = 3 AND T.MaxAllowed <> TMP.MaxAllowedValue ) 
 OR 
	 ( TMP.MaxAllowedOperator = 7 AND T.MaxAllowed > TMP.MaxAllowedValue ) 
 OR 
	 ( TMP.MaxAllowedOperator = 8 AND T.MaxAllowed >= TMP.MaxAllowedValue ) 
 OR 
	 ( TMP.MaxAllowedOperator = 9 AND T.MaxAllowed < TMP.MaxAllowedValue ) 
 OR 
	 ( TMP.MaxAllowedOperator = 10 AND T.MaxAllowed <= TMP.MaxAllowedValue ) 

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
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'ASC'
	 THEN T.VehicleType END ASC, 
	 CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'DESC'
	 THEN T.VehicleType END DESC ,

	 CASE WHEN @sortColumn = 'MaxAllowed' AND @sortOrder = 'ASC'
	 THEN T.MaxAllowed END ASC, 
	 CASE WHEN @sortColumn = 'MaxAllowed' AND @sortOrder = 'DESC'
	 THEN T.MaxAllowed END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC ,

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
DROP TABLE #tmp_FinalResults
END