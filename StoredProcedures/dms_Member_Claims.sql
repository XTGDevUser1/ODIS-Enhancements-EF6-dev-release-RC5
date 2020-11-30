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
  --EXEC dms_Member_Claims  @MemberShipID = 537
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Member_Claims]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_Claims] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Member_Claims]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @MemberID INT =  NULL
 , @MemberShipID INT =  NULL 
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
 	SET FMTONLY OFF

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
							ClaimIDOperator="-1" 
							ClaimTypeOperator="-1" 
							ClaimDateOperator="-1" 
							AmountRequestedOperator="-1" 
							PayeeeOperator="-1" 
							ClaimStatusOperator="-1" 
							CheckNumberOperator="-1" 
							PaymentDateOperator="-1" 
							PaymentAmountOperator="-1" 
							CheckClearedDateOperator="-1" 
							AmountApprovedOperator="-1"
							></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
ClaimIDOperator INT NOT NULL,
ClaimIDValue int NULL,
ClaimTypeOperator INT NOT NULL,
ClaimTypeValue nvarchar(100) NULL,
ClaimDateOperator INT NOT NULL,
ClaimDateValue datetime NULL,
AmountRequestedOperator INT NOT NULL,
AmountRequestedValue MONEY NULL,
PayeeeOperator INT NOT NULL,
PayeeeValue nvarchar(255) NULL,
ClaimStatusOperator INT NOT NULL,
ClaimStatusValue nvarchar(100) NULL,
CheckNumberOperator INT NOT NULL,
CheckNumberValue nvarchar(100) NULL,
PaymentDateOperator INT NOT NULL,
PaymentDateValue datetime NULL,
PaymentAmountOperator INT NOT NULL,
PaymentAmountValue MONEY NULL,
CheckClearedDateOperator INT NOT NULL,
CheckClearedDateValue datetime NULL,
AmountApprovedOperator INT NOT NULL,
AmountApprovedValue MONEY NULL
)

CREATE TABLE #FinalResultsFiltered( 	
	MemberID		 INT, 
	MemberShipID	 INT, 
	ClaimID			 INT  NULL ,
	ClaimType		 NVARCHAR(100)  NULL ,
	ClaimDate		 DATETIME  NULL ,
	AmountRequested  MONEY  NULL ,
	Payeee			 NVARCHAR(255)  NULL ,
	ClaimStatus		 NVARCHAR(100)  NULL ,
	CheckNumber		 NVARCHAR(100)  NULL ,
	PaymentDate		 DATETIME  NULL ,
	PaymentAmount	 MONEY  NULL,
	CheckClearedDate DATETIME NULL,
	AmountApproved	 MONEY NULL
) 

 CREATE TABLE #FinalResults( 
    [RowNum] [bigint] NOT NULL IDENTITY(1,1),
    MemberID		 INT, 
	MemberShipID	 INT, 
	ClaimID int  NULL ,
	ClaimType nvarchar(100)  NULL ,
	ClaimDate datetime  NULL ,
	AmountRequested MONEY  NULL ,
	Payeee nvarchar(255)  NULL ,
	ClaimStatus nvarchar(100)  NULL ,
	CheckNumber nvarchar(100)  NULL ,
	PaymentDate datetime  NULL ,
	PaymentAmount MONEY  NULL ,
	CheckClearedDate datetime  NULL ,
	AmountApproved	 MONEY NULL
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@ClaimIDOperator','INT'),-1),
	T.c.value('@ClaimIDValue','int') ,
	ISNULL(T.c.value('@ClaimTypeOperator','INT'),-1),
	T.c.value('@ClaimTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ClaimDateOperator','INT'),-1),
	T.c.value('@ClaimDateValue','datetime') ,
	ISNULL(T.c.value('@AmountRequestedOperator','INT'),-1),
	T.c.value('@AmountRequestedValue','MONEY') ,
	ISNULL(T.c.value('@PayeeeOperator','INT'),-1),
	T.c.value('@PayeeeValue','nvarchar(255)') ,
	ISNULL(T.c.value('@ClaimStatusOperator','INT'),-1),
	T.c.value('@ClaimStatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CheckNumberOperator','INT'),-1),
	T.c.value('@CheckNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PaymentDateOperator','INT'),-1),
	T.c.value('@PaymentDateValue','datetime') ,
	ISNULL(T.c.value('@PaymentAmountOperator','INT'),-1),
	T.c.value('@PaymentAmountValue','MONEY') ,
	ISNULL(T.c.value('@CheckClearedDateOperator','INT'),-1),
	T.c.value('@CheckClearedDateValue','datetime') ,
	ISNULL(T.c.value('@AmountApprovedOperator','INT'),-1),
	T.c.value('@AmountApprovedValue','MONEY')
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResultsFiltered
SELECT
		      C.MemberID
		    , MS.ID
			, C.ID AS ClaimID
			, CT.Name AS ClaimType
			, C.ClaimDate
			, C.AmountRequested
			, C.PaymentPayeeName
			, CS.Name AS ClaimStatus
			, C.CheckNumber
			, C.PaymentDate
			, C.PaymentAmount
			, C.CheckClearedDate
			, C.AmountApproved
FROM		Claim C
JOIN		ClaimType CT WITH(NOLOCK) ON CT.ID = C.ClaimTypeID
JOIN		ClaimStatus CS WITH(NOLOCK) ON CS.ID = C.ClaimStatusID
LEFT JOIN	Member M WITH (NOLOCK) ON C.MemberID = M.ID
LEFT JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
WHERE		C.IsActive = 1
AND		   ((@MemberID IS NULL) OR (@MemberID IS NOT NULL AND C.MemberID = @MemberID))
AND		   ((@MemberShipID IS NULL) OR (@MemberShipID IS NOT NULL AND MS.ID = @MemberShipID))

INSERT INTO #FinalResults
SELECT 
	T.MemberID,
	T.MemberShipID,
	T.ClaimID,
	T.ClaimType,
	T.ClaimDate,
	T.AmountRequested,
	T.Payeee,
	T.ClaimStatus,
	T.CheckNumber,
	T.PaymentDate,
	T.PaymentAmount,
	T.CheckClearedDate,
	T.AmountApproved
FROM #FinalResultsFiltered T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.ClaimIDOperator = -1 ) 
 OR 
	 ( TMP.ClaimIDOperator = 0 AND T.ClaimID IS NULL ) 
 OR 
	 ( TMP.ClaimIDOperator = 1 AND T.ClaimID IS NOT NULL ) 
 OR 
	 ( TMP.ClaimIDOperator = 2 AND T.ClaimID = TMP.ClaimIDValue ) 
 OR 
	 ( TMP.ClaimIDOperator = 3 AND T.ClaimID <> TMP.ClaimIDValue ) 
 OR 
	 ( TMP.ClaimIDOperator = 7 AND T.ClaimID > TMP.ClaimIDValue ) 
 OR 
	 ( TMP.ClaimIDOperator = 8 AND T.ClaimID >= TMP.ClaimIDValue ) 
 OR 
	 ( TMP.ClaimIDOperator = 9 AND T.ClaimID < TMP.ClaimIDValue ) 
 OR 
	 ( TMP.ClaimIDOperator = 10 AND T.ClaimID <= TMP.ClaimIDValue ) 

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
	 ( TMP.AmountRequestedOperator = -1 ) 
 OR 
	 ( TMP.AmountRequestedOperator = 0 AND T.AmountRequested IS NULL ) 
 OR 
	 ( TMP.AmountRequestedOperator = 1 AND T.AmountRequested IS NOT NULL ) 
 OR 
	 ( TMP.AmountRequestedOperator = 2 AND T.AmountRequested = TMP.AmountRequestedValue ) 
 OR 
	 ( TMP.AmountRequestedOperator = 3 AND T.AmountRequested <> TMP.AmountRequestedValue ) 
 OR 
	 ( TMP.AmountRequestedOperator = 7 AND T.AmountRequested > TMP.AmountRequestedValue ) 
 OR 
	 ( TMP.AmountRequestedOperator = 8 AND T.AmountRequested >= TMP.AmountRequestedValue ) 
 OR 
	 ( TMP.AmountRequestedOperator = 9 AND T.AmountRequested < TMP.AmountRequestedValue ) 
 OR 
	 ( TMP.AmountRequestedOperator = 10 AND T.AmountRequested <= TMP.AmountRequestedValue ) 

 ) 

 AND 

 ( 
	 ( TMP.PayeeeOperator = -1 ) 
 OR 
	 ( TMP.PayeeeOperator = 0 AND T.Payeee IS NULL ) 
 OR 
	 ( TMP.PayeeeOperator = 1 AND T.Payeee IS NOT NULL ) 
 OR 
	 ( TMP.PayeeeOperator = 2 AND T.Payeee = TMP.PayeeeValue ) 
 OR 
	 ( TMP.PayeeeOperator = 3 AND T.Payeee <> TMP.PayeeeValue ) 
 OR 
	 ( TMP.PayeeeOperator = 4 AND T.Payeee LIKE TMP.PayeeeValue + '%') 
 OR 
	 ( TMP.PayeeeOperator = 5 AND T.Payeee LIKE '%' + TMP.PayeeeValue ) 
 OR 
	 ( TMP.PayeeeOperator = 6 AND T.Payeee LIKE '%' + TMP.PayeeeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ClaimStatusOperator = -1 ) 
 OR 
	 ( TMP.ClaimStatusOperator = 0 AND T.ClaimStatus IS NULL ) 
 OR 
	 ( TMP.ClaimStatusOperator = 1 AND T.ClaimStatus IS NOT NULL ) 
 OR 
	 ( TMP.ClaimStatusOperator = 2 AND T.ClaimStatus = TMP.ClaimStatusValue ) 
 OR 
	 ( TMP.ClaimStatusOperator = 3 AND T.ClaimStatus <> TMP.ClaimStatusValue ) 
 OR 
	 ( TMP.ClaimStatusOperator = 4 AND T.ClaimStatus LIKE TMP.ClaimStatusValue + '%') 
 OR 
	 ( TMP.ClaimStatusOperator = 5 AND T.ClaimStatus LIKE '%' + TMP.ClaimStatusValue ) 
 OR 
	 ( TMP.ClaimStatusOperator = 6 AND T.ClaimStatus LIKE '%' + TMP.ClaimStatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CheckNumberOperator = -1 ) 
 OR 
	 ( TMP.CheckNumberOperator = 0 AND T.CheckNumber IS NULL ) 
 OR 
	 ( TMP.CheckNumberOperator = 1 AND T.CheckNumber IS NOT NULL ) 
 OR 
	 ( TMP.CheckNumberOperator = 2 AND T.CheckNumber = TMP.CheckNumberValue ) 
 OR 
	 ( TMP.CheckNumberOperator = 3 AND T.CheckNumber <> TMP.CheckNumberValue ) 
 OR 
	 ( TMP.CheckNumberOperator = 4 AND T.CheckNumber LIKE TMP.CheckNumberValue + '%') 
 OR 
	 ( TMP.CheckNumberOperator = 5 AND T.CheckNumber LIKE '%' + TMP.CheckNumberValue ) 
 OR 
	 ( TMP.CheckNumberOperator = 6 AND T.CheckNumber LIKE '%' + TMP.CheckNumberValue + '%' ) 
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
	 ( TMP.CheckClearedDateOperator = -1 ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 0 AND T.CheckClearedDate IS NULL ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 1 AND T.CheckClearedDate IS NOT NULL ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 2 AND T.CheckClearedDate = TMP.CheckClearedDateValue ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 3 AND T.CheckClearedDate <> TMP.CheckClearedDateValue ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 7 AND T.CheckClearedDate > TMP.CheckClearedDateValue ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 8 AND T.CheckClearedDate >= TMP.CheckClearedDateValue ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 9 AND T.CheckClearedDate < TMP.CheckClearedDateValue ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 10 AND T.CheckClearedDate <= TMP.CheckClearedDateValue ) 

 ) 

AND 

 ( 
	 ( TMP.AmountApprovedOperator = -1 ) 
 OR 
	 ( TMP.AmountApprovedOperator = 0 AND T.AmountApproved IS NULL ) 
 OR 
	 ( TMP.AmountApprovedOperator = 1 AND T.AmountApproved IS NOT NULL ) 
 OR 
	 ( TMP.AmountApprovedOperator = 2 AND T.AmountApproved = TMP.AmountApprovedValue ) 
 OR 
	 ( TMP.AmountApprovedOperator = 3 AND T.AmountApproved <> TMP.AmountApprovedValue ) 
 OR 
	 ( TMP.AmountApprovedOperator = 7 AND T.AmountApproved > TMP.AmountApprovedValue ) 
 OR 
	 ( TMP.AmountApprovedOperator = 8 AND T.AmountApproved >= TMP.AmountApprovedValue ) 
 OR 
	 ( TMP.AmountApprovedOperator = 9 AND T.AmountApproved < TMP.AmountApprovedValue ) 
 OR 
	 ( TMP.AmountApprovedOperator = 10 AND T.AmountApproved <= TMP.AmountApprovedValue ) 

 ) 


 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ClaimID' AND @sortOrder = 'ASC'
	 THEN T.ClaimID END ASC, 
	 CASE WHEN @sortColumn = 'ClaimID' AND @sortOrder = 'DESC'
	 THEN T.ClaimID END DESC ,

	 CASE WHEN @sortColumn = 'ClaimType' AND @sortOrder = 'ASC'
	 THEN T.ClaimType END ASC, 
	 CASE WHEN @sortColumn = 'ClaimType' AND @sortOrder = 'DESC'
	 THEN T.ClaimType END DESC ,

	 CASE WHEN @sortColumn = 'ClaimDate' AND @sortOrder = 'ASC'
	 THEN T.ClaimDate END ASC, 
	 CASE WHEN @sortColumn = 'ClaimDate' AND @sortOrder = 'DESC'
	 THEN T.ClaimDate END DESC ,

	 CASE WHEN @sortColumn = 'AmountRequested' AND @sortOrder = 'ASC'
	 THEN T.AmountRequested END ASC, 
	 CASE WHEN @sortColumn = 'AmountRequested' AND @sortOrder = 'DESC'
	 THEN T.AmountRequested END DESC ,

	 CASE WHEN @sortColumn = 'Payeee' AND @sortOrder = 'ASC'
	 THEN T.Payeee END ASC, 
	 CASE WHEN @sortColumn = 'Payeee' AND @sortOrder = 'DESC'
	 THEN T.Payeee END DESC ,

	 CASE WHEN @sortColumn = 'ClaimStatus' AND @sortOrder = 'ASC'
	 THEN T.ClaimStatus END ASC, 
	 CASE WHEN @sortColumn = 'ClaimStatus' AND @sortOrder = 'DESC'
	 THEN T.ClaimStatus END DESC ,

	 CASE WHEN @sortColumn = 'CheckNumber' AND @sortOrder = 'ASC'
	 THEN T.CheckNumber END ASC, 
	 CASE WHEN @sortColumn = 'CheckNumber' AND @sortOrder = 'DESC'
	 THEN T.CheckNumber END DESC ,

	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'ASC'
	 THEN T.PaymentDate END ASC, 
	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'DESC'
	 THEN T.PaymentDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'
	 THEN T.PaymentAmount END ASC, 
	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'
	 THEN T.PaymentAmount END DESC ,

	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'ASC'
	 THEN T.CheckClearedDate END ASC, 
	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'DESC'
	 THEN T.CheckClearedDate END DESC ,

	 CASE WHEN @sortColumn = 'AmountApproved' AND @sortOrder = 'ASC'
	 THEN T.AmountApproved END ASC, 
	 CASE WHEN @sortColumn = 'AmountApproved' AND @sortOrder = 'DESC'
	 THEN T.AmountApproved END DESC


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
