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
 WHERE id = object_id(N'[dbo].[dms_Vendor_Portal_Service_Contact_Actions_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Portal_Service_Contact_Actions_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC [dms_Vendor_Portal_Service_Contact_Actions_List_Get] @VendorID = 190,@ProductID =147
 CREATE PROCEDURE [dbo].[dms_Vendor_Portal_Service_Contact_Actions_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @VendorID INT = NULL
 , @ProductID INT =NULL
 ) 
 AS 
 BEGIN 
  
 SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
DateOperator="-1" 
ServiceOperator="-1" 
ReasonOperator="-1" 
TalkedToOperator="-1" 
PONumberOperator="-1" 
CreateDateOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
DateOperator INT NOT NULL,
DateValue datetime NULL,
ServiceOperator INT NOT NULL,
ServiceValue nvarchar(100) NULL,
ReasonOperator INT NOT NULL,
ReasonValue nvarchar(100) NULL,
TalkedToOperator INT NOT NULL,
TalkedToValue nvarchar(100) NULL,
PONumberOperator INT NOT NULL,
PONumberValue nvarchar(100) NULL,
CreateDateOperator INT NOT NULL,
CreateDateValue datetime NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Date datetime  NULL ,
	Service nvarchar(100)  NULL ,
	Reason nvarchar(100)  NULL ,
	TalkedTo nvarchar(100)  NULL ,
	PONumber nvarchar(100)  NULL ,
	CreateDate datetime  NULL 
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Date datetime  NULL ,
	Service nvarchar(100)  NULL ,
	Reason nvarchar(100)  NULL ,
	TalkedTo nvarchar(100)  NULL ,
	PONumber nvarchar(100)  NULL ,
	CreateDate datetime  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@DateOperator','INT'),-1),
	T.c.value('@DateValue','datetime') ,
	ISNULL(T.c.value('@ServiceOperator','INT'),-1),
	T.c.value('@ServiceValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ReasonOperator','INT'),-1),
	T.c.value('@ReasonValue','nvarchar(100)') ,
	ISNULL(T.c.value('@TalkedToOperator','INT'),-1),
	T.c.value('@TalkedToValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PONumberOperator','INT'),-1),
	T.c.value('@PONumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CreateDateOperator','INT'),-1),
	T.c.value('@CreateDateValue','datetime') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT DISTINCT CONVERT(VARCHAR(10),CL.CreateDate,101) AS [Date]
		, 'Service' AS [Service]
		, CA.Name AS [Reason]
		, CL.TalkedTo AS [TalkedTo]  -- apply mixed case
		, VendorContactLog.PurchaseOrderNumber AS PONumber
		, CL.CreateDate
FROM	ContactLog CL
JOIN	ContactCategory CC ON CC.ID = CL.ContactCategoryID
JOIN	ContactLogLink CLL ON CLL.ContactLogID = CL.ID
LEFT JOIN ContactLogAction CLA ON CLA.ContactLogID = CL.ID
JOIN	ContactAction CA ON CA.ID = CLA.ContactActionID
JOIN	VendorLocation VL ON VL.ID = CLL.RecordID
JOIN	Vendor V ON V.ID = VL.VendorID
JOIN	VendorLocationProduct vlp ON vl.ID = vlp.VendorLocationID AND vlp.IsActive = 1
LEFT OUTER JOIN dbo.fnc_GetVendorLocationProduct_ContactLog() VendorContactLog ON VendorContactLog.VendorLocationID = vl.ID AND VendorContactLog.ProductID = vlp.ProductID AND VendorContactLog.ContactLogID = CL.ID

WHERE	V.ID = @VendorID AND vlp.ProductID = @ProductID
AND		CLL.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
AND		CC.ID = (SELECT ID FROM ContactCategory WHERE Name = 'VendorSelection')
ORDER BY CL.CreateDate DESC

INSERT INTO #FinalResults
SELECT 
	T.Date,
	T.Service,
	T.Reason,
	T.TalkedTo,
	T.PONumber,
	T.CreateDate
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

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
	 ( TMP.ServiceOperator = -1 ) 
 OR 
	 ( TMP.ServiceOperator = 0 AND T.Service IS NULL ) 
 OR 
	 ( TMP.ServiceOperator = 1 AND T.Service IS NOT NULL ) 
 OR 
	 ( TMP.ServiceOperator = 2 AND T.Service = TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 3 AND T.Service <> TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 4 AND T.Service LIKE TMP.ServiceValue + '%') 
 OR 
	 ( TMP.ServiceOperator = 5 AND T.Service LIKE '%' + TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 6 AND T.Service LIKE '%' + TMP.ServiceValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ReasonOperator = -1 ) 
 OR 
	 ( TMP.ReasonOperator = 0 AND T.Reason IS NULL ) 
 OR 
	 ( TMP.ReasonOperator = 1 AND T.Reason IS NOT NULL ) 
 OR 
	 ( TMP.ReasonOperator = 2 AND T.Reason = TMP.ReasonValue ) 
 OR 
	 ( TMP.ReasonOperator = 3 AND T.Reason <> TMP.ReasonValue ) 
 OR 
	 ( TMP.ReasonOperator = 4 AND T.Reason LIKE TMP.ReasonValue + '%') 
 OR 
	 ( TMP.ReasonOperator = 5 AND T.Reason LIKE '%' + TMP.ReasonValue ) 
 OR 
	 ( TMP.ReasonOperator = 6 AND T.Reason LIKE '%' + TMP.ReasonValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.TalkedToOperator = -1 ) 
 OR 
	 ( TMP.TalkedToOperator = 0 AND T.TalkedTo IS NULL ) 
 OR 
	 ( TMP.TalkedToOperator = 1 AND T.TalkedTo IS NOT NULL ) 
 OR 
	 ( TMP.TalkedToOperator = 2 AND T.TalkedTo = TMP.TalkedToValue ) 
 OR 
	 ( TMP.TalkedToOperator = 3 AND T.TalkedTo <> TMP.TalkedToValue ) 
 OR 
	 ( TMP.TalkedToOperator = 4 AND T.TalkedTo LIKE TMP.TalkedToValue + '%') 
 OR 
	 ( TMP.TalkedToOperator = 5 AND T.TalkedTo LIKE '%' + TMP.TalkedToValue ) 
 OR 
	 ( TMP.TalkedToOperator = 6 AND T.TalkedTo LIKE '%' + TMP.TalkedToValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PONumberOperator = -1 ) 
 OR 
	 ( TMP.PONumberOperator = 0 AND T.PONumber IS NULL ) 
 OR 
	 ( TMP.PONumberOperator = 1 AND T.PONumber IS NOT NULL ) 
 OR 
	 ( TMP.PONumberOperator = 2 AND T.PONumber = TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 3 AND T.PONumber <> TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 4 AND T.PONumber LIKE TMP.PONumberValue + '%') 
 OR 
	 ( TMP.PONumberOperator = 5 AND T.PONumber LIKE '%' + TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 6 AND T.PONumber LIKE '%' + TMP.PONumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CreateDateOperator = -1 ) 
 OR 
	 ( TMP.CreateDateOperator = 0 AND T.CreateDate IS NULL ) 
 OR 
	 ( TMP.CreateDateOperator = 1 AND T.CreateDate IS NOT NULL ) 
 OR 
	 ( TMP.CreateDateOperator = 2 AND T.CreateDate = TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 3 AND T.CreateDate <> TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 7 AND T.CreateDate > TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 8 AND T.CreateDate >= TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 9 AND T.CreateDate < TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 10 AND T.CreateDate <= TMP.CreateDateValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'Date' AND @sortOrder = 'ASC'
	 THEN T.Date END ASC, 
	 CASE WHEN @sortColumn = 'Date' AND @sortOrder = 'DESC'
	 THEN T.Date END DESC ,

	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'ASC'
	 THEN T.Service END ASC, 
	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'DESC'
	 THEN T.Service END DESC ,

	 CASE WHEN @sortColumn = 'Reason' AND @sortOrder = 'ASC'
	 THEN T.Reason END ASC, 
	 CASE WHEN @sortColumn = 'Reason' AND @sortOrder = 'DESC'
	 THEN T.Reason END DESC ,

	 CASE WHEN @sortColumn = 'TalkedTo' AND @sortOrder = 'ASC'
	 THEN T.TalkedTo END ASC, 
	 CASE WHEN @sortColumn = 'TalkedTo' AND @sortOrder = 'DESC'
	 THEN T.TalkedTo END DESC ,

	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'
	 THEN T.PONumber END ASC, 
	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'
	 THEN T.PONumber END DESC ,

	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'
	 THEN T.CreateDate END ASC, 
	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'
	 THEN T.CreateDate END DESC 


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
