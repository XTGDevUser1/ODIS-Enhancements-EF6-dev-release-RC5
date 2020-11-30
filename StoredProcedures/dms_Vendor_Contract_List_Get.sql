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
 WHERE id = object_id(N'[dbo].dms_Vendor_Contract_List_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Contract_List_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_Vendor_Contract_List_Get @VendorID=1
 CREATE PROCEDURE [dbo].dms_Vendor_Contract_List_Get( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @VendorID INT 
 ) 
 AS 
 BEGIN 
    SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
StartDateOperator="-1" 
EndDateOperator="-1" 
StatusOperator="-1" 
SignedDateOperator="-1" 
SignedByOperator="-1" 
SignedByTitleOperator="-1" 
AgreementVersionOperator="-1" 
SourceSystemOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
StartDateOperator INT NOT NULL,
StartDateValue datetime NULL,
EndDateOperator INT NOT NULL,
EndDateValue datetime NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL,
SignedDateOperator INT NOT NULL,
SignedDateValue datetime NULL,
SignedByOperator INT NOT NULL,
SignedByValue nvarchar(100) NULL,
SignedByTitleOperator INT NOT NULL,
SignedByTitleValue nvarchar(100) NULL,
AgreementVersionOperator INT NOT NULL,
AgreementVersionValue datetime NULL,
SourceSystemOperator INT NOT NULL,
SourceSystemValue nvarchar(100) NULL
)
 DECLARE @FinalResults AS  TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	StartDate datetime  NULL ,
	EndDate datetime  NULL ,
	Status nvarchar(100)  NULL ,
	SignedDate datetime  NULL ,
	SignedBy nvarchar(100)  NULL ,
	SignedByTitle nvarchar(100)  NULL ,
	AgreementVersion datetime  NULL ,
	SourceSystem nvarchar(100)  NULL 
) 

 DECLARE @FinalResults1 AS  TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	StartDate datetime  NULL ,
	EndDate datetime  NULL ,
	Status nvarchar(100)  NULL ,
	SignedDate datetime  NULL ,
	SignedBy nvarchar(100)  NULL ,
	SignedByTitle nvarchar(100)  NULL ,
	AgreementVersion datetime  NULL ,
	SourceSystem nvarchar(100)  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@StartDateOperator','INT'),-1),
	T.c.value('@StartDateValue','datetime') ,
	ISNULL(T.c.value('@EndDateOperator','INT'),-1),
	T.c.value('@EndDateValue','datetime') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@SignedDateOperator','INT'),-1),
	T.c.value('@SignedDateValue','datetime') ,
	ISNULL(T.c.value('@SignedByOperator','INT'),-1),
	T.c.value('@SignedByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@SignedByTitleOperator','INT'),-1),
	T.c.value('@SignedByTitleValue','nvarchar(100)') ,
	ISNULL(T.c.value('@AgreementVersionOperator','INT'),-1),
	T.c.value('@AgreementVersionValue','datetime') ,
	ISNULL(T.c.value('@SourceSystemOperator','INT'),-1),
	T.c.value('@SourceSystemValue','nvarchar(100)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

INSERT INTO @FinalResults1
SELECT C.ID
	, C.StartDate
	, C.EndDate
	, CS.Name AS Status
	, C.SignedDate
	, C.SignedBy
	, C.SignedByTitle
	--, C.Notes (from application)
	, TA.EffectiveDate AS AgreementVersion
	, SS.Name AS SourceSystem
FROM Contract C
JOIN ContractStatus CS ON CS.ID = C.ContractStatusID
JOIN VendorTermsAgreement TA ON TA.ID = C.VendorTermsAgreementID
JOIN SourceSystem SS ON SS.ID = C.SourceSystemID
WHERE C.IsActive = 1
AND C.VendorID = @VendorID
ORDER BY C.StartDate DESC
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults
SELECT 
	T.ID,
	T.StartDate,
	T.EndDate,
	T.Status,
	T.SignedDate,
	T.SignedBy,
	T.SignedByTitle,
	T.AgreementVersion,
	T.SourceSystem
FROM @FinalResults1 T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.IDOperator = -1 ) 
 OR 
	 ( TMP.IDOperator = 0 AND T.ID IS NULL ) 
 OR 
	 ( TMP.IDOperator = 1 AND T.ID IS NOT NULL ) 
 OR 
	 ( TMP.IDOperator = 2 AND T.ID = TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 3 AND T.ID <> TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 7 AND T.ID > TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 8 AND T.ID >= TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 9 AND T.ID < TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 10 AND T.ID <= TMP.IDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.StartDateOperator = -1 ) 
 OR 
	 ( TMP.StartDateOperator = 0 AND T.StartDate IS NULL ) 
 OR 
	 ( TMP.StartDateOperator = 1 AND T.StartDate IS NOT NULL ) 
 OR 
	 ( TMP.StartDateOperator = 2 AND T.StartDate = TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 3 AND T.StartDate <> TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 7 AND T.StartDate > TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 8 AND T.StartDate >= TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 9 AND T.StartDate < TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 10 AND T.StartDate <= TMP.StartDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.EndDateOperator = -1 ) 
 OR 
	 ( TMP.EndDateOperator = 0 AND T.EndDate IS NULL ) 
 OR 
	 ( TMP.EndDateOperator = 1 AND T.EndDate IS NOT NULL ) 
 OR 
	 ( TMP.EndDateOperator = 2 AND T.EndDate = TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 3 AND T.EndDate <> TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 7 AND T.EndDate > TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 8 AND T.EndDate >= TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 9 AND T.EndDate < TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 10 AND T.EndDate <= TMP.EndDateValue ) 

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
	 ( TMP.SignedDateOperator = -1 ) 
 OR 
	 ( TMP.SignedDateOperator = 0 AND T.SignedDate IS NULL ) 
 OR 
	 ( TMP.SignedDateOperator = 1 AND T.SignedDate IS NOT NULL ) 
 OR 
	 ( TMP.SignedDateOperator = 2 AND T.SignedDate = TMP.SignedDateValue ) 
 OR 
	 ( TMP.SignedDateOperator = 3 AND T.SignedDate <> TMP.SignedDateValue ) 
 OR 
	 ( TMP.SignedDateOperator = 7 AND T.SignedDate > TMP.SignedDateValue ) 
 OR 
	 ( TMP.SignedDateOperator = 8 AND T.SignedDate >= TMP.SignedDateValue ) 
 OR 
	 ( TMP.SignedDateOperator = 9 AND T.SignedDate < TMP.SignedDateValue ) 
 OR 
	 ( TMP.SignedDateOperator = 10 AND T.SignedDate <= TMP.SignedDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.SignedByOperator = -1 ) 
 OR 
	 ( TMP.SignedByOperator = 0 AND T.SignedBy IS NULL ) 
 OR 
	 ( TMP.SignedByOperator = 1 AND T.SignedBy IS NOT NULL ) 
 OR 
	 ( TMP.SignedByOperator = 2 AND T.SignedBy = TMP.SignedByValue ) 
 OR 
	 ( TMP.SignedByOperator = 3 AND T.SignedBy <> TMP.SignedByValue ) 
 OR 
	 ( TMP.SignedByOperator = 4 AND T.SignedBy LIKE TMP.SignedByValue + '%') 
 OR 
	 ( TMP.SignedByOperator = 5 AND T.SignedBy LIKE '%' + TMP.SignedByValue ) 
 OR 
	 ( TMP.SignedByOperator = 6 AND T.SignedBy LIKE '%' + TMP.SignedByValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.SignedByTitleOperator = -1 ) 
 OR 
	 ( TMP.SignedByTitleOperator = 0 AND T.SignedByTitle IS NULL ) 
 OR 
	 ( TMP.SignedByTitleOperator = 1 AND T.SignedByTitle IS NOT NULL ) 
 OR 
	 ( TMP.SignedByTitleOperator = 2 AND T.SignedByTitle = TMP.SignedByTitleValue ) 
 OR 
	 ( TMP.SignedByTitleOperator = 3 AND T.SignedByTitle <> TMP.SignedByTitleValue ) 
 OR 
	 ( TMP.SignedByTitleOperator = 4 AND T.SignedByTitle LIKE TMP.SignedByTitleValue + '%') 
 OR 
	 ( TMP.SignedByTitleOperator = 5 AND T.SignedByTitle LIKE '%' + TMP.SignedByTitleValue ) 
 OR 
	 ( TMP.SignedByTitleOperator = 6 AND T.SignedByTitle LIKE '%' + TMP.SignedByTitleValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.AgreementVersionOperator = -1 ) 
 OR 
	 ( TMP.AgreementVersionOperator = 0 AND T.AgreementVersion IS NULL ) 
 OR 
	 ( TMP.AgreementVersionOperator = 1 AND T.AgreementVersion IS NOT NULL ) 
 OR 
	 ( TMP.AgreementVersionOperator = 2 AND T.AgreementVersion = TMP.AgreementVersionValue ) 
 OR 
	 ( TMP.AgreementVersionOperator = 3 AND T.AgreementVersion <> TMP.AgreementVersionValue ) 
 OR 
	 ( TMP.AgreementVersionOperator = 7 AND T.AgreementVersion > TMP.AgreementVersionValue ) 
 OR 
	 ( TMP.AgreementVersionOperator = 8 AND T.AgreementVersion >= TMP.AgreementVersionValue ) 
 OR 
	 ( TMP.AgreementVersionOperator = 9 AND T.AgreementVersion < TMP.AgreementVersionValue ) 
 OR 
	 ( TMP.AgreementVersionOperator = 10 AND T.AgreementVersion <= TMP.AgreementVersionValue ) 

 ) 

 AND 

 ( 
	 ( TMP.SourceSystemOperator = -1 ) 
 OR 
	 ( TMP.SourceSystemOperator = 0 AND T.SourceSystem IS NULL ) 
 OR 
	 ( TMP.SourceSystemOperator = 1 AND T.SourceSystem IS NOT NULL ) 
 OR 
	 ( TMP.SourceSystemOperator = 2 AND T.SourceSystem = TMP.SourceSystemValue ) 
 OR 
	 ( TMP.SourceSystemOperator = 3 AND T.SourceSystem <> TMP.SourceSystemValue ) 
 OR 
	 ( TMP.SourceSystemOperator = 4 AND T.SourceSystem LIKE TMP.SourceSystemValue + '%') 
 OR 
	 ( TMP.SourceSystemOperator = 5 AND T.SourceSystem LIKE '%' + TMP.SourceSystemValue ) 
 OR 
	 ( TMP.SourceSystemOperator = 6 AND T.SourceSystem LIKE '%' + TMP.SourceSystemValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'ASC'
	 THEN T.StartDate END ASC, 
	 CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'DESC'
	 THEN T.StartDate END DESC ,

	 CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'ASC'
	 THEN T.EndDate END ASC, 
	 CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'DESC'
	 THEN T.EndDate END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC ,

	 CASE WHEN @sortColumn = 'SignedDate' AND @sortOrder = 'ASC'
	 THEN T.SignedDate END ASC, 
	 CASE WHEN @sortColumn = 'SignedDate' AND @sortOrder = 'DESC'
	 THEN T.SignedDate END DESC ,

	 CASE WHEN @sortColumn = 'SignedBy' AND @sortOrder = 'ASC'
	 THEN T.SignedBy END ASC, 
	 CASE WHEN @sortColumn = 'SignedBy' AND @sortOrder = 'DESC'
	 THEN T.SignedBy END DESC ,

	 CASE WHEN @sortColumn = 'SignedByTitle' AND @sortOrder = 'ASC'
	 THEN T.SignedByTitle END ASC, 
	 CASE WHEN @sortColumn = 'SignedByTitle' AND @sortOrder = 'DESC'
	 THEN T.SignedByTitle END DESC ,

	 CASE WHEN @sortColumn = 'AgreementVersion' AND @sortOrder = 'ASC'
	 THEN T.AgreementVersion END ASC, 
	 CASE WHEN @sortColumn = 'AgreementVersion' AND @sortOrder = 'DESC'
	 THEN T.AgreementVersion END DESC ,

	 CASE WHEN @sortColumn = 'SourceSystem' AND @sortOrder = 'ASC'
	 THEN T.SourceSystem END ASC, 
	 CASE WHEN @sortColumn = 'SourceSystem' AND @sortOrder = 'DESC'
	 THEN T.SourceSystem END DESC 


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

DROP TABLE #tmpForWhereClause

END
