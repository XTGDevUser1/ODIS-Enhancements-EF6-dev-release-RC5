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
 WHERE id = object_id(N'[dbo].[dms_po_search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_po_search] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_po_search] @UserID = '3C19F725-5D19-4701-AE53-F2C104648541',@whereClauseXML ='<ROW><Filter TimeOperator="2" TimeValue="1w"></Filter></ROW>'
 CREATE PROCEDURE [dbo].[dms_po_search](   
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10    
 , @sortColumn nvarchar(100)  = ''   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @UserID UNIQUEIDENTIFIER   
 )   
 AS   
 BEGIN   
    
  SET NOCOUNT ON  

CREATE TABLE #FinalResultsFiltered (    
 RequestID int  NULL ,  
 PONumber nvarchar(50)  NULL ,  
 [Date] datetime  NULL ,  
 LastName nvarchar(50)  NULL ,  
 FirstName nvarchar(50)  NULL ,  
 Suffix nvarchar(50)  NULL ,  
 MemberNumber nvarchar(50)  NULL ,  
 UserName nvarchar(50)  NULL ,  
 ServiceType nvarchar(50)  NULL ,  
 Amount decimal  NULL ,  
 DatePaid datetime  NULL ,  
 [Status] nvarchar(50)  NULL,  
 VendorNumber nvarchar(50)  NULL ,  
 City nvarchar(100) NULL,  
 StateProvince nvarchar(10) NULL,
 MiddleName nvarchar(1) NULL 
)
CREATE TABLE #FinalResultsFormatted (   
 
 RequestID int  NULL ,  
 PONumber nvarchar(50)  NULL ,  
 Date datetime  NULL ,  
 MemberName nvarchar(200)  NULL ,  
 MemberNumber nvarchar(50)  NULL ,  
 UserName nvarchar(50)  NULL ,  
 ServiceType nvarchar(50)  NULL ,  
 Amount decimal  NULL ,  
 DatePaid datetime  NULL ,  
 Status nvarchar(50)  NULL,  
 VendorNumber nvarchar(50)  NULL ,  
 City nvarchar(100) NULL,  
 StateProvince nvarchar(10) NULL  
)
CREATE TABLE #FinalResultsSorted (   
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 RequestID int  NULL ,  
 PONumber nvarchar(50)  NULL ,  
 Date datetime  NULL ,  
 MemberName nvarchar(200)  NULL ,  
 MemberNumber nvarchar(50)  NULL ,  
 UserName nvarchar(50)  NULL ,  
 ServiceType nvarchar(50)  NULL ,  
 Amount decimal  NULL ,  
 DatePaid datetime  NULL ,  
 Status nvarchar(50)  NULL,  
 VendorNumber nvarchar(50)  NULL ,  
 City nvarchar(100) NULL,  
 StateProvince nvarchar(10) NULL  
)   
DECLARE @idoc int  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter   
PONumberOperator="-1"   
TimeOperator="-1"   
UserNameOperator="-1"   
VendorNumberOperator="-1"  
 ></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
PONumberOperator INT NOT NULL,  
PONumberValue nvarchar(50) NULL,  
TimeOperator INT NOT NULL,  
TimeValue nvarchar(50),  
UserNameOperator INT NOT NULL,  
UserNameValue nvarchar(50) NULL,  
VendorNumberOperator INT NOT NULL,  
VendorNumberValue nvarchar(50) NULL  
)  
  
  
INSERT INTO @tmpForWhereClause  
SELECT    
 ISNULL(PONumberOperator,-1),  
 PONumberValue ,  
 ISNULL(TimeOperator,-1),  
 TimeValue ,   
 ISNULL(UserNameOperator,-1),  
 UserNameValue,  
 ISNULL(VendorNumberOperator,-1),  
 VendorNumberValue    
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
PONumberOperator INT,  
PONumberValue nvarchar(50)   
,TimeOperator INT,  
TimeValue nvarchar(50)   
,UserNameOperator INT,  
UserNameValue nvarchar(50),  
VendorNumberOperator INT,  
VendorNumberValue nvarchar(50)  
  
 )   
  
--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
 INSERT INTO #FinalResultsFiltered  
 SELECT SR.ID AS RequestID  
   , PO.PurchaseOrderNumber AS PONumber  
   , PO.IssueDate AS [Date]  
   --,REPLACE(RTRIM(  
   --           COALESCE(M.LastName, '') +   
   --           COALESCE(' ' + M.Suffix, '') +   
   --           COALESCE(', ' + M.FirstName, '')  
   --           ), '  ', ' ') AS MemberName  
   , M.LastName
   , M.FirstName
   , M.Suffix
   , MS.MembershipNumber AS MemberNumber  
   , AU.UserName AS UserName  
   , PC.Name AS ServiceType  
   , PO.PurchaseOrderAmount AS Amount     
   , GETDATE() AS DatePaid -- TODO : Fix this field.  
   , POS.Name AS [Status]  
   , V.VendorNumber as VendorNumber     
   ,ae.City  
   ,ae.StateProvince
   ,LEFT(M.MiddleName ,1) AS MiddleName
 FROM ServiceRequest SR WITH (NOLOCK)  
 JOIN PurchaseOrder PO WITH (NOLOCK) ON PO.ServiceRequestID = sr.ID  
 JOIN [aspnet_Users] AU WITH (NOLOCK) ON AU.UserName = PO.CreateBy   
 JOIN [Case] C WITH (NOLOCK) ON C.ID = SR.CaseID  
 JOIN Member M WITH (NOLOCK) ON M.ID = C.MemberID  
 JOIN [dbo].[fnc_GetProgramsForUser](@UserID) MP ON M.ProgramID = MP.ProgramID  
 JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID  
 JOIN ProductCategory PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID  
 JOIN PurchaseOrderStatus POS WITH (NOLOCK) ON POS.ID = PO.PurchaseOrderStatusID  
 JOIN VendorLocation VL WITH (NOLOCK) ON VL.ID = PO.VendorLocationID  
 JOIN Vendor V WITH (NOLOCK) ON V.ID = VL.VendorID  
 JOIN AddressEntity ae on ae.RecordID = VL.ID and ae.EntityID = (Select ID From Entity Where Name = 'VendorLocation')    
 JOIN @tmpForWhereClause TMP ON 1=1
 
 WHERE (   
   (   
		( TMP.PONumberOperator = -1 )     
		OR   
		( TMP.PONumberOperator = 6 AND PO.PurchaseOrderNumber LIKE '%' + TMP.PONumberValue + '%' )   
	)     
	AND   
	(   
		( TMP.TimeOperator = -1 )    
		OR   
		( TMP.TimeOperator = 2 AND TMP.TimeValue = '1w' AND  DATEDIFF(WK,PO.IssueDate,GETDATE()) <= 1)  -- 1 week  
		OR   
		( TMP.TimeOperator = 2 AND TMP.TimeValue = '1m' AND  DATEDIFF(m,PO.IssueDate,GETDATE()) <= 1)  -- 1 month  
		OR   
		( TMP.TimeOperator = 2 AND TMP.TimeValue = '3m' AND  DATEDIFF(m,PO.IssueDate,GETDATE()) <= 3) -- 3 months  
		OR   
		( TMP.TimeOperator = 2 AND TMP.TimeValue = '3m+' AND  DATEDIFF(m,PO.IssueDate,GETDATE()) > 3) -- over 3 months  
	)   
	AND     
	(   
		( TMP.UserNameOperator = -1 )      
		OR   
		( TMP.UserNameOperator = 2 AND AU.UserName = TMP.UserNameValue )    
	)   
	AND   
	(   
		( TMP.VendorNumberOperator = -1 )    
		OR   
		( TMP.VendorNumberOperator = 6 AND V.VendorNumber LIKE '%' + TMP.VendorNumberValue + '%' )   
	)  
	AND   
	1 = 1   
)  
 
 
INSERT INTO #FinalResultsFormatted  
SELECT   DISTINCT
 T.RequestID,  
 T.PONumber,  
 T.[Date],  
 --REPLACE(RTRIM(  
 --             COALESCE(T.LastName, '') +   
 --             COALESCE(' ' + T.Suffix, '') +   
 --             COALESCE(', ' + T.FirstName, '')  
 --             ), '  ', ' ') AS MemberName ,  
 REPLACE(RTRIM( 
COALESCE(T.FirstName, '') + 
COALESCE(' ' + left(MiddleName,1), '') + 
COALESCE(' ' + T.LastName, '') +
COALESCE(' ' + T.Suffix, '')
), ' ', ' ') AS MemberName, 

 T.MemberNumber,  
 T.UserName,  
 T.ServiceType,  
 T.Amount,  
 T.DatePaid,  
 T.Status,  
 T.VendorNumber,  
 T.City,  
 T.StateProvince  
FROM #FinalResultsFiltered T

INSERT INTO #FinalResultsSorted
SELECT	T.*
FROM	#FinalResultsFormatted T 
 ORDER BY   
  CASE WHEN @sortColumn = 'RequestID' AND @sortOrder = 'ASC'  
  THEN T.RequestID END ASC,   
  CASE WHEN @sortColumn = 'RequestID' AND @sortOrder = 'DESC'  
  THEN T.RequestID END DESC ,  
  
  CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'  
  THEN T.PONumber END ASC,   
  CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'  
  THEN T.PONumber END DESC ,  
  
  CASE WHEN @sortColumn = 'Date' AND @sortOrder = 'ASC'  
  THEN T.Date END ASC,   
  CASE WHEN @sortColumn = 'Date' AND @sortOrder = 'DESC'  
  THEN T.Date END DESC ,  
  
  CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'  
  THEN T.MemberName END ASC,   
  CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'  
  THEN T.MemberName END DESC ,  
  
  CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'  
  THEN T.MemberNumber END ASC,   
  CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'  
  THEN T.MemberNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'UserName' AND @sortOrder = 'ASC'  
  THEN T.UserName END ASC,   
  CASE WHEN @sortColumn = 'UserName' AND @sortOrder = 'DESC'  
  THEN T.UserName END DESC ,  
  
  CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'ASC'  
  THEN T.ServiceType END ASC,   
  CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'DESC'  
  THEN T.ServiceType END DESC ,  
  
  CASE WHEN @sortColumn = 'Amount' AND @sortOrder = 'ASC'  
  THEN T.Amount END ASC,   
  CASE WHEN @sortColumn = 'Amount' AND @sortOrder = 'DESC'  
  THEN T.Amount END DESC ,  
  
  CASE WHEN @sortColumn = 'DatePaid' AND @sortOrder = 'ASC'  
  THEN T.DatePaid END ASC,   
  CASE WHEN @sortColumn = 'DatePaid' AND @sortOrder = 'DESC'  
  THEN T.DatePaid END DESC ,  
  
  CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'  
  THEN T.Status END ASC,   
  CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'  
  THEN T.Status END DESC   
  
  
DECLARE @count INT     
SET @count = 0     
SELECT @count = MAX(RowNum) FROM #FinalResultsSorted  
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
  
SELECT @count AS TotalRows, * FROM #FinalResultsSorted WHERE RowNum BETWEEN @startInd AND @endInd  

DROP TABLE #FinalResultsFiltered  
DROP TABLE #FinalResultsFormatted  
DROP TABLE #FinalResultsSorted  
  
END  
GO