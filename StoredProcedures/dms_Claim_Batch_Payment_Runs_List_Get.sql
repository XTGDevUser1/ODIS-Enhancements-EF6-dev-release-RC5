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
 WHERE id = object_id(N'[dbo].[dms_Claim_Batch_Payment_Runs_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Claim_Batch_Payment_Runs_List_Get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_Claim_Batch_Payment_Runs_List_Get] @BatchID= 65
 CREATE PROCEDURE [dbo].[dms_Claim_Batch_Payment_Runs_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = 'CreateDate' 
 , @sortOrder nvarchar(100) = 'DESC' 
 , @BatchID INT =NULL 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
ClaimNumberOperator="-1" 
ClaimTypeOperator="-1" 
ClaimDateOperator="-1" 
PayeeTypeOperator="-1" 
ReferenceNumberOperator="-1" 
PayeeNameOperator="-1" 
PayMethodOperator="-1" 
PaymentDateOperator="-1" 
PaymentAmountOperator="-1" 
ProgramNameOperator="-1"
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
ClaimNumberOperator INT NOT NULL,
ClaimNumberValue int NULL,
ClaimTypeOperator INT NOT NULL,
ClaimTypeValue nvarchar(100) NULL,
ClaimDateOperator INT NOT NULL,
ClaimDateValue datetime NULL,
PayeeTypeOperator INT NOT NULL,
PayeeTypeValue nvarchar(100) NULL,
ReferenceNumberOperator INT NOT NULL,
ReferenceNumberValue nvarchar(100) NULL,
PayeeNameOperator INT NOT NULL,
PayeeNameValue nvarchar(260) NULL,
PayMethodOperator INT NOT NULL,
PayMethodValue nvarchar(100) NULL,
PaymentDateOperator INT NOT NULL,
PaymentDateValue datetime NULL,
PaymentAmountOperator INT NOT NULL,
PaymentAmountValue money NULL,
ProgramNameOperator INT NOT NULL,
ProgramNameValue nvarchar(100) NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ClaimNumber int  NULL ,
	ClaimType nvarchar(100)  NULL ,
	ClaimDate datetime  NULL ,
	PayeeType nvarchar(100)  NULL ,
	ReferenceNumber nvarchar(100)  NULL ,
	PayeeName nvarchar(260)  NULL ,
	PayMethod nvarchar(100)  NULL ,
	PaymentDate datetime  NULL ,
	PaymentAmount money  NULL ,
	CreateDate datetime null,
	ProgramName nvarchar(100) NULL
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ClaimNumber int  NULL ,
	ClaimType nvarchar(100)  NULL ,
	ClaimDate datetime  NULL ,
	PayeeType nvarchar(100)  NULL ,
	ReferenceNumber nvarchar(100)  NULL ,
	PayeeName nvarchar(260)  NULL ,
	PayMethod nvarchar(100)  NULL ,
	PaymentDate datetime  NULL ,
	PaymentAmount money  NULL ,
	CreateDate datetime NULL ,
	ProgramName nvarchar(100) NULL
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@ClaimNumberOperator','INT'),-1),
	T.c.value('@ClaimNumberValue','int') ,
	ISNULL(T.c.value('@ClaimTypeOperator','INT'),-1),
	T.c.value('@ClaimTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ClaimDateOperator','INT'),-1),
	T.c.value('@ClaimDateValue','datetime') ,
	ISNULL(T.c.value('@PayeeTypeOperator','INT'),-1),
	T.c.value('@PayeeTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ReferenceNumberOperator','INT'),-1),
	T.c.value('@ReferenceNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PayeeNameOperator','INT'),-1),
	T.c.value('@PayeeNameValue','nvarchar(260)') ,
	ISNULL(T.c.value('@PayMethodOperator','INT'),-1),
	T.c.value('@PayMethodValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PaymentDateOperator','INT'),-1),
	T.c.value('@PaymentDateValue','datetime') ,
	ISNULL(T.c.value('@PaymentAmountOperator','INT'),-1),
	T.c.value('@PaymentAmountValue','money') ,
	ISNULL(T.c.value('@ProgramNameOperator','INT'),-1),
	T.c.value('@ProgramNameValue','nvarchar(100)') 
	
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT	C.ID AS [ClaimNumber]
		, CT.Name AS [ClaimType]
		, C.ClaimDate
		, CASE
			WHEN ISNULL(C.VendorID,'')<>'' THEN 'Vendor'
			WHEN ISNULL(C.MemberID,'')<>'' THEN 'Member'
			ELSE 'Other'
		  END AS [PayeeType]
		, CASE 
			WHEN ISNULL(C.VendorID,'')<>'' THEN V.VendorNumber
			WHEN ISNULL(C.MemberID,'')<>'' THEN MS.MembershipNumber
			ELSE ''
		  END AS [ReferenceNumber]
		, C.ContactName AS [PayeeName]
		, PT.Name AS [PayMethod]
		, C.PaymentDate
		, C.PaymentAmount
		, B.CreateDate
		, P.Name AS ProgramName
FROM	Batch B
JOIN	Claim C WITH(NOLOCK) ON C.ExportBatchID = B.ID
JOIN	ClaimType CT WITH(NOLOCK) ON CT.ID = C.ClaimTypeID
LEFT JOIN PaymentType PT WITH(NOLOCK) ON PT.ID = C.PaymentTypeID
LEFT JOIN Vendor V WITH(NOLOCK) ON V.ID = C.VendorID
LEFT JOIN Member M WITH(NOLOCK) ON M.ID = C.MemberID
LEFT JOIN Membership MS WITH(NOLOCK) ON MS.ID = M.MembershipID
LEFT JOIN Program P WITH(NOLOCK) ON P.ID=C.ProgramID
WHERE B.ID=@BatchID

INSERT INTO #FinalResults
SELECT 
	T.ClaimNumber,
	T.ClaimType,
	T.ClaimDate,
	T.PayeeType,
	T.ReferenceNumber,
	T.PayeeName,
	T.PayMethod,
	T.PaymentDate,
	T.PaymentAmount,
	T.CreateDate,
	T.ProgramName
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.ClaimNumberOperator = -1 ) 
 OR 
	 ( TMP.ClaimNumberOperator = 0 AND T.ClaimNumber IS NULL ) 
 OR 
	 ( TMP.ClaimNumberOperator = 1 AND T.ClaimNumber IS NOT NULL ) 
 OR 
	 ( TMP.ClaimNumberOperator = 2 AND T.ClaimNumber = TMP.ClaimNumberValue ) 
 OR 
	 ( TMP.ClaimNumberOperator = 3 AND T.ClaimNumber <> TMP.ClaimNumberValue ) 
 OR 
	 ( TMP.ClaimNumberOperator = 7 AND T.ClaimNumber > TMP.ClaimNumberValue ) 
 OR 
	 ( TMP.ClaimNumberOperator = 8 AND T.ClaimNumber >= TMP.ClaimNumberValue ) 
 OR 
	 ( TMP.ClaimNumberOperator = 9 AND T.ClaimNumber < TMP.ClaimNumberValue ) 
 OR 
	 ( TMP.ClaimNumberOperator = 10 AND T.ClaimNumber <= TMP.ClaimNumberValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ClaimTypeOperator = -1 ) 
 OR 
	 ( TMP.ClaimTypeOperator = 0 AND T.ClaimType IS NULL ) 
 OR 
	 ( TMP.ClaimTypeOperator = 1 AND T.ClaimType IS NOT NULL ) 
 OR 
	 ( TMP.ClaimTypeOperator = 2 AND T.ClaimType = TMP.ClaimTypeValue ) 
 OR 
	 ( TMP.ClaimTypeOperator = 3 AND T.ClaimType <> TMP.ClaimTypeValue ) 
 OR 
	 ( TMP.ClaimTypeOperator = 4 AND T.ClaimType LIKE TMP.ClaimTypeValue + '%') 
 OR 
	 ( TMP.ClaimTypeOperator = 5 AND T.ClaimType LIKE '%' + TMP.ClaimTypeValue ) 
 OR 
	 ( TMP.ClaimTypeOperator = 6 AND T.ClaimType LIKE '%' + TMP.ClaimTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ClaimDateOperator = -1 ) 
 OR 
	 ( TMP.ClaimDateOperator = 0 AND T.ClaimDate IS NULL ) 
 OR 
	 ( TMP.ClaimDateOperator = 1 AND T.ClaimDate IS NOT NULL ) 
 OR 
	 ( TMP.ClaimDateOperator = 2 AND T.ClaimDate = TMP.ClaimDateValue ) 
 OR 
	 ( TMP.ClaimDateOperator = 3 AND T.ClaimDate <> TMP.ClaimDateValue ) 
 OR 
	 ( TMP.ClaimDateOperator = 7 AND T.ClaimDate > TMP.ClaimDateValue ) 
 OR 
	 ( TMP.ClaimDateOperator = 8 AND T.ClaimDate >= TMP.ClaimDateValue ) 
 OR 
	 ( TMP.ClaimDateOperator = 9 AND T.ClaimDate < TMP.ClaimDateValue ) 
 OR 
	 ( TMP.ClaimDateOperator = 10 AND T.ClaimDate <= TMP.ClaimDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.PayeeTypeOperator = -1 ) 
 OR 
	 ( TMP.PayeeTypeOperator = 0 AND T.PayeeType IS NULL ) 
 OR 
	 ( TMP.PayeeTypeOperator = 1 AND T.PayeeType IS NOT NULL ) 
 OR 
	 ( TMP.PayeeTypeOperator = 2 AND T.PayeeType = TMP.PayeeTypeValue ) 
 OR 
	 ( TMP.PayeeTypeOperator = 3 AND T.PayeeType <> TMP.PayeeTypeValue ) 
 OR 
	 ( TMP.PayeeTypeOperator = 4 AND T.PayeeType LIKE TMP.PayeeTypeValue + '%') 
 OR 
	 ( TMP.PayeeTypeOperator = 5 AND T.PayeeType LIKE '%' + TMP.PayeeTypeValue ) 
 OR 
	 ( TMP.PayeeTypeOperator = 6 AND T.PayeeType LIKE '%' + TMP.PayeeTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ReferenceNumberOperator = -1 ) 
 OR 
	 ( TMP.ReferenceNumberOperator = 0 AND T.ReferenceNumber IS NULL ) 
 OR 
	 ( TMP.ReferenceNumberOperator = 1 AND T.ReferenceNumber IS NOT NULL ) 
 OR 
	 ( TMP.ReferenceNumberOperator = 2 AND T.ReferenceNumber = TMP.ReferenceNumberValue ) 
 OR 
	 ( TMP.ReferenceNumberOperator = 3 AND T.ReferenceNumber <> TMP.ReferenceNumberValue ) 
 OR 
	 ( TMP.ReferenceNumberOperator = 4 AND T.ReferenceNumber LIKE TMP.ReferenceNumberValue + '%') 
 OR 
	 ( TMP.ReferenceNumberOperator = 5 AND T.ReferenceNumber LIKE '%' + TMP.ReferenceNumberValue ) 
 OR 
	 ( TMP.ReferenceNumberOperator = 6 AND T.ReferenceNumber LIKE '%' + TMP.ReferenceNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PayeeNameOperator = -1 ) 
 OR 
	 ( TMP.PayeeNameOperator = 0 AND T.PayeeName IS NULL ) 
 OR 
	 ( TMP.PayeeNameOperator = 1 AND T.PayeeName IS NOT NULL ) 
 OR 
	 ( TMP.PayeeNameOperator = 2 AND T.PayeeName = TMP.PayeeNameValue ) 
 OR 
	 ( TMP.PayeeNameOperator = 3 AND T.PayeeName <> TMP.PayeeNameValue ) 
 OR 
	 ( TMP.PayeeNameOperator = 4 AND T.PayeeName LIKE TMP.PayeeNameValue + '%') 
 OR 
	 ( TMP.PayeeNameOperator = 5 AND T.PayeeName LIKE '%' + TMP.PayeeNameValue ) 
 OR 
	 ( TMP.PayeeNameOperator = 6 AND T.PayeeName LIKE '%' + TMP.PayeeNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PayMethodOperator = -1 ) 
 OR 
	 ( TMP.PayMethodOperator = 0 AND T.PayMethod IS NULL ) 
 OR 
	 ( TMP.PayMethodOperator = 1 AND T.PayMethod IS NOT NULL ) 
 OR 
	 ( TMP.PayMethodOperator = 2 AND T.PayMethod = TMP.PayMethodValue ) 
 OR 
	 ( TMP.PayMethodOperator = 3 AND T.PayMethod <> TMP.PayMethodValue ) 
 OR 
	 ( TMP.PayMethodOperator = 4 AND T.PayMethod LIKE TMP.PayMethodValue + '%') 
 OR 
	 ( TMP.PayMethodOperator = 5 AND T.PayMethod LIKE '%' + TMP.PayMethodValue ) 
 OR 
	 ( TMP.PayMethodOperator = 6 AND T.PayMethod LIKE '%' + TMP.PayMethodValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PaymentDateOperator = -1 ) 
 OR 
	 ( TMP.PaymentDateOperator = 0 AND T.PaymentDate IS NULL ) 
 OR 
	 ( TMP.PaymentDateOperator = 1 AND T.PaymentDate IS NOT NULL ) 
 OR 
	 ( TMP.PaymentDateOperator = 2 AND T.PaymentDate = TMP.PaymentDateValue ) 
 OR 
	 ( TMP.PaymentDateOperator = 3 AND T.PaymentDate <> TMP.PaymentDateValue ) 
 OR 
	 ( TMP.PaymentDateOperator = 7 AND T.PaymentDate > TMP.PaymentDateValue ) 
 OR 
	 ( TMP.PaymentDateOperator = 8 AND T.PaymentDate >= TMP.PaymentDateValue ) 
 OR 
	 ( TMP.PaymentDateOperator = 9 AND T.PaymentDate < TMP.PaymentDateValue ) 
 OR 
	 ( TMP.PaymentDateOperator = 10 AND T.PaymentDate <= TMP.PaymentDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.PaymentAmountOperator = -1 ) 
 OR 
	 ( TMP.PaymentAmountOperator = 0 AND T.PaymentAmount IS NULL ) 
 OR 
	 ( TMP.PaymentAmountOperator = 1 AND T.PaymentAmount IS NOT NULL ) 
 OR 
	 ( TMP.PaymentAmountOperator = 2 AND T.PaymentAmount = TMP.PaymentAmountValue ) 
 OR 
	 ( TMP.PaymentAmountOperator = 3 AND T.PaymentAmount <> TMP.PaymentAmountValue ) 
 OR 
	 ( TMP.PaymentAmountOperator = 7 AND T.PaymentAmount > TMP.PaymentAmountValue ) 
 OR 
	 ( TMP.PaymentAmountOperator = 8 AND T.PaymentAmount >= TMP.PaymentAmountValue ) 
 OR 
	 ( TMP.PaymentAmountOperator = 9 AND T.PaymentAmount < TMP.PaymentAmountValue ) 
 OR 
	 ( TMP.PaymentAmountOperator = 10 AND T.PaymentAmount <= TMP.PaymentAmountValue ) 

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
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ClaimNumber' AND @sortOrder = 'ASC'
	 THEN T.ClaimNumber END ASC, 
	 CASE WHEN @sortColumn = 'ClaimNumber' AND @sortOrder = 'DESC'
	 THEN T.ClaimNumber END DESC ,

	 CASE WHEN @sortColumn = 'ClaimType' AND @sortOrder = 'ASC'
	 THEN T.ClaimType END ASC, 
	 CASE WHEN @sortColumn = 'ClaimType' AND @sortOrder = 'DESC'
	 THEN T.ClaimType END DESC ,

	 CASE WHEN @sortColumn = 'ClaimDate' AND @sortOrder = 'ASC'
	 THEN T.ClaimDate END ASC, 
	 CASE WHEN @sortColumn = 'ClaimDate' AND @sortOrder = 'DESC'
	 THEN T.ClaimDate END DESC ,

	 CASE WHEN @sortColumn = 'PayeeType' AND @sortOrder = 'ASC'
	 THEN T.PayeeType END ASC, 
	 CASE WHEN @sortColumn = 'PayeeType' AND @sortOrder = 'DESC'
	 THEN T.PayeeType END DESC ,

	 CASE WHEN @sortColumn = 'ReferenceNumber' AND @sortOrder = 'ASC'
	 THEN T.ReferenceNumber END ASC, 
	 CASE WHEN @sortColumn = 'ReferenceNumber' AND @sortOrder = 'DESC'
	 THEN T.ReferenceNumber END DESC ,

	 CASE WHEN @sortColumn = 'PayeeName' AND @sortOrder = 'ASC'
	 THEN T.PayeeName END ASC, 
	 CASE WHEN @sortColumn = 'PayeeName' AND @sortOrder = 'DESC'
	 THEN T.PayeeName END DESC ,

	 CASE WHEN @sortColumn = 'PayMethod' AND @sortOrder = 'ASC'
	 THEN T.PayMethod END ASC, 
	 CASE WHEN @sortColumn = 'PayMethod' AND @sortOrder = 'DESC'
	 THEN T.PayMethod END DESC ,

	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'ASC'
	 THEN T.PaymentDate END ASC, 
	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'DESC'
	 THEN T.PaymentDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'
	 THEN T.PaymentAmount END ASC, 
	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'
	 THEN T.PaymentAmount END DESC ,

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
