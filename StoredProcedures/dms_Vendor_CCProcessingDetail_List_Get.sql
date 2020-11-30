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
 WHERE id = object_id(N'[dbo].[dms_Vendor_CCProcessingDetail_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_CCProcessingDetail_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Vendor_CCProcessingDetail_List_Get @TemporaryCreditCardId=1
 CREATE PROCEDURE [dbo].[dms_Vendor_CCProcessingDetail_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @TemporaryCreditCardId INT = NULL 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF;
 	SET NOCOUNT ON


 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	TransactionDate datetime  NULL ,
	TransactionSequence int NULL,
	TransactionBy nvarchar(100)  NULL ,
	TransactionType nvarchar(20)  NULL ,
	RequestedAmount money  NULL ,
	ApprovedAmount money  NULL ,
	ChargeAmount money  NULL ,
	ChargeDescription nvarchar(100)  NULL
	
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	TransactionDate datetime  NULL ,
	TransactionSequence int NULL,
	TransactionBy nvarchar(100)  NULL ,
	TransactionType nvarchar(20)  NULL ,
	RequestedAmount money  NULL ,
	ApprovedAmount money  NULL ,
	ChargeAmount money  NULL ,
	ChargeDescription nvarchar(100)  NULL
) 



--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT	TCCD.ID
		, CASE
			WHEN TCCD.TransactionType = 'Charge' THEN TCCD.ChargeDate
			ELSE TCCD.TransactionDate
		  END AS [Date]
		, TCCD.TransactionSequence AS [Sequence]
		, TCCD.TransactionBy AS [User]
		, TCCD.TransactionType AS [Action]
		, TCCD.RequestedAmount AS [Requested]
		, TCCD.ApprovedAmount AS [Approved]
		, TCCD.ChargeAmount AS [Charge]
		, TCCD.ChargeDescription AS [ChargeDescription]
FROM	TemporaryCreditCardDetail TCCD
WHERE	TCCD.TemporaryCreditCardID = @TemporaryCreditCardId
ORDER BY TCCD.TransactionDate ASC,TCCD.TransactionSequence ASC


INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.TransactionDate,
	T.TransactionSequence,
	T.TransactionBy,
	T.TransactionType,
	T.RequestedAmount,
	T.ApprovedAmount,
	T.ChargeAmount,
	T.ChargeDescription
FROM #tmpFinalResults T
ORDER BY T.TransactionDate, T.TransactionSequence


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

DROP TABLE #FinalResults
DROP TABLE #tmpFinalResults
END
