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
 WHERE id = object_id(N'[dbo].[dms_Securables_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Securables_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Securables_List]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
SecurableIDOperator="-1" 
FriendlyNameOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
SecurableIDOperator INT NOT NULL,
SecurableIDValue int NULL,
FriendlyNameOperator INT NOT NULL,
FriendlyNameValue nvarchar(50) NULL
)
DECLARE @FinalResults TABLE( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	SecurableID int  NULL ,
	FriendlyName nvarchar(MAX)  NULL ,
	[Permissions] nvarchar(MAX)  NULL 
) 

DECLARE @QueryResults TABLE( 
	SecurableID int  NULL ,
	FriendlyName nvarchar(MAX)  NULL ,
	[Permissions] nvarchar(MAX)  NULL 
) 

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(SecurableIDOperator,-1),
	SecurableIDValue ,
	ISNULL(FriendlyNameOperator,-1),
	FriendlyNameValue 
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
SecurableIDOperator INT,
SecurableIDValue int 
,FriendlyNameOperator INT,
FriendlyNameValue nvarchar(50) 
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------

INSERT INTO @QueryResults
SELECT S.ID,
	   S.FriendlyName,
	  (SELECT Permission FROM dbo.fn_SecurablePermissions(S.ID))
FROM Securable S WITH(NOLOCK)

INSERT INTO @FinalResults
SELECT 
	T.SecurableID,
	T.FriendlyName,
	T.Permissions
FROM @QueryResults T,
@tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.SecurableIDOperator = -1 ) 
 OR 
	 ( TMP.SecurableIDOperator = 0 AND T.SecurableID IS NULL ) 
 OR 
	 ( TMP.SecurableIDOperator = 1 AND T.SecurableID IS NOT NULL ) 
 OR 
	 ( TMP.SecurableIDOperator = 2 AND T.SecurableID = TMP.SecurableIDValue ) 
 OR 
	 ( TMP.SecurableIDOperator = 3 AND T.SecurableID <> TMP.SecurableIDValue ) 
 OR 
	 ( TMP.SecurableIDOperator = 7 AND T.SecurableID > TMP.SecurableIDValue ) 
 OR 
	 ( TMP.SecurableIDOperator = 8 AND T.SecurableID >= TMP.SecurableIDValue ) 
 OR 
	 ( TMP.SecurableIDOperator = 9 AND T.SecurableID < TMP.SecurableIDValue ) 
 OR 
	 ( TMP.SecurableIDOperator = 10 AND T.SecurableID <= TMP.SecurableIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.FriendlyNameOperator = -1 ) 
 OR 
	 ( TMP.FriendlyNameOperator = 0 AND T.FriendlyName IS NULL ) 
 OR 
	 ( TMP.FriendlyNameOperator = 1 AND T.FriendlyName IS NOT NULL ) 
 OR 
	 ( TMP.FriendlyNameOperator = 2 AND T.FriendlyName = TMP.FriendlyNameValue ) 
 OR 
	 ( TMP.FriendlyNameOperator = 3 AND T.FriendlyName <> TMP.FriendlyNameValue ) 
 OR 
	 ( TMP.FriendlyNameOperator = 4 AND T.FriendlyName LIKE TMP.FriendlyNameValue + '%') 
 OR 
	 ( TMP.FriendlyNameOperator = 5 AND T.FriendlyName LIKE '%' + TMP.FriendlyNameValue ) 
 OR 
	 ( TMP.FriendlyNameOperator = 6 AND T.FriendlyName LIKE '%' + TMP.FriendlyNameValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'SecurableID' AND @sortOrder = 'ASC'
	 THEN T.SecurableID END ASC, 
	 CASE WHEN @sortColumn = 'SecurableID' AND @sortOrder = 'DESC'
	 THEN T.SecurableID END DESC ,

	 CASE WHEN @sortColumn = 'FriendlyName' AND @sortOrder = 'ASC'
	 THEN T.FriendlyName END ASC, 
	 CASE WHEN @sortColumn = 'FriendlyName' AND @sortOrder = 'DESC'
	 THEN T.FriendlyName END DESC ,

	 CASE WHEN @sortColumn = 'Permissions' AND @sortOrder = 'ASC'
	 THEN T.Permissions END ASC, 
	 CASE WHEN @sortColumn = 'Permissions' AND @sortOrder = 'DESC'
	 THEN T.Permissions END DESC 


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
