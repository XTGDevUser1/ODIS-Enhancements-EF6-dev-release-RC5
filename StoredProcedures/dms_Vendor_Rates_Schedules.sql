IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Vendor_Rates_Schedules]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Vendor_Rates_Schedules]
GO
 
CREATE PROCEDURE [dbo].[dms_Vendor_Rates_Schedules](   
   @whereClauseXML XML = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10    
 , @sortColumn nvarchar(100)  = ''   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @VendorID INT = NULL    
 )   
 AS   
 BEGIN   
SET FMTONLY OFF    
SET NOCOUNT ON  
  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter   
ContractIDOperator="-1"   
ContractRateScheduleIDOperator="-1"   
ContractRateScheduleStartDateOperator="-1"   
ContractRateScheduleEndDateOperator="-1"   
ContractRateScheduleStatusOperator="-1"   
ContractRateScheduleSignedDateOperator="-1"   
SignedByOperator="-1"   
SignedByTitleOperator="-1"   
ContractStartDateOperator="-1"   
 ></Filter></ROW>'  
END  
  
CREATE TABLE #tmpForWhereClause  
(  
ContractIDOperator INT NOT NULL,  
ContractIDValue int NULL,  
ContractRateScheduleIDOperator INT NOT NULL,  
ContractRateScheduleIDValue int NULL,  
ContractRateScheduleStartDateOperator INT NOT NULL,  
ContractRateScheduleStartDateValue datetime NULL,  
ContractRateScheduleEndDateOperator INT NOT NULL,  
ContractRateScheduleEndDateValue datetime NULL,  
ContractRateScheduleStatusOperator INT NOT NULL,  
ContractRateScheduleStatusValue nvarchar(100) NULL,  
ContractRateScheduleSignedDateOperator INT NOT NULL,  
ContractRateScheduleSignedDateValue datetime NULL,  
SignedByOperator INT NOT NULL,  
SignedByValue nvarchar(100) NULL,  
SignedByTitleOperator INT NOT NULL,  
SignedByTitleValue nvarchar(100) NULL,  
ContractStartDateOperator INT NOT NULL,  
ContractStartDateValue datetime NULL  
)  
 DECLARE @FinalResults AS  TABLE (   
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 ContractID int  NULL ,  
 ContractRateScheduleID int  NULL ,  
 ContractRateScheduleStartDate datetime  NULL ,  
 ContractRateScheduleEndDate datetime  NULL ,  
 ContractRateScheduleStatus nvarchar(100)  NULL ,  
 ContractRateScheduleSignedDate datetime  NULL ,  
 SignedBy nvarchar(100)  NULL ,  
 SignedByTitle nvarchar(100)  NULL ,  
 ContractStartDate datetime  NULL   
)   
  
DECLARE @FinalResults_Temp AS  TABLE (   
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 ContractID int  NULL ,  
 ContractRateScheduleID int  NULL ,  
 ContractRateScheduleStartDate datetime  NULL ,  
 ContractRateScheduleEndDate datetime  NULL ,  
 ContractRateScheduleStatus nvarchar(100)  NULL ,  
 ContractRateScheduleSignedDate datetime  NULL ,  
 SignedBy nvarchar(100)  NULL ,  
 SignedByTitle nvarchar(100)  NULL ,  
 ContractStartDate datetime  NULL   
)  
  
INSERT INTO #tmpForWhereClause  
SELECT    
 ISNULL(T.c.value('@ContractIDOperator','INT'),-1),  
 T.c.value('@ContractIDValue','int') ,  
 ISNULL(T.c.value('@ContractRateScheduleIDOperator','INT'),-1),  
 T.c.value('@ContractRateScheduleIDValue','int') ,  
 ISNULL(T.c.value('@ContractRateScheduleStartDateOperator','INT'),-1),  
 T.c.value('@ContractRateScheduleStartDateValue','datetime') ,  
 ISNULL(T.c.value('@ContractRateScheduleEndDateOperator','INT'),-1),  
 T.c.value('@ContractRateScheduleEndDateValue','datetime') ,  
 ISNULL(T.c.value('@ContractRateScheduleStatusOperator','INT'),-1),  
 T.c.value('@ContractRateScheduleStatusValue','nvarchar(100)') ,  
 ISNULL(T.c.value('@ContractRateScheduleSignedDateOperator','INT'),-1),  
 T.c.value('@ContractRateScheduleSignedDateValue','datetime') ,  
 ISNULL(T.c.value('@SignedByOperator','INT'),-1),  
 T.c.value('@SignedByValue','nvarchar(100)') ,  
 ISNULL(T.c.value('@SignedByTitleOperator','INT'),-1),  
 T.c.value('@SignedByTitleValue','nvarchar(100)') ,  
 ISNULL(T.c.value('@ContractStartDateOperator','INT'),-1),  
 T.c.value('@ContractStartDateValue','datetime')   
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)  
  
INSERT INTO @FinalResults_Temp  
SELECT C.ID AS ContractID  
 , CRS.ID AS ContractRateScheduleID  
 , CRS.StartDate AS ContractRateScheduleStartDate  
 , CRS.EndDate AS ContractRateScheduleEndDate  
 , CRSS.Name AS ContractRateScheduleStatus  
 , CRS.SignedDate AS ContractRateScheduleSignedDate  
 , CRS.SignedBy  
 , CRS.SignedByTitle  
 , C.StartDate AS ContractStartDate  
FROM ContractRateSchedule CRS  
JOIN Contract C ON C.ID = CRS.ContractID  
JOIN Vendor V ON V.ID = C.VendorID  
JOIN ContractRateScheduleStatus CRSS ON CRSS.ID = CRS.ContractRateScheduleStatusID  
WHERE CRS.IsActive = 1  
AND C.VendorID = @VendorID  
ORDER BY CRS.StartDate DESC  
--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
INSERT INTO @FinalResults  
SELECT   
 T.ContractID,  
 T.ContractRateScheduleID,  
 T.ContractRateScheduleStartDate,  
 T.ContractRateScheduleEndDate,  
 T.ContractRateScheduleStatus,  
 T.ContractRateScheduleSignedDate,  
 T.SignedBy,  
 T.SignedByTitle,  
 T.ContractStartDate  
FROM @FinalResults_Temp T,  
#tmpForWhereClause TMP   
WHERE (   
  
 (   
  ( TMP.ContractIDOperator = -1 )   
 OR   
  ( TMP.ContractIDOperator = 0 AND T.ContractID IS NULL )   
 OR   
  ( TMP.ContractIDOperator = 1 AND T.ContractID IS NOT NULL )   
 OR   
  ( TMP.ContractIDOperator = 2 AND T.ContractID = TMP.ContractIDValue )   
 OR   
  ( TMP.ContractIDOperator = 3 AND T.ContractID <> TMP.ContractIDValue )   
 OR   
  ( TMP.ContractIDOperator = 7 AND T.ContractID > TMP.ContractIDValue )   
 OR   
  ( TMP.ContractIDOperator = 8 AND T.ContractID >= TMP.ContractIDValue )   
 OR   
  ( TMP.ContractIDOperator = 9 AND T.ContractID < TMP.ContractIDValue )   
 OR   
  ( TMP.ContractIDOperator = 10 AND T.ContractID <= TMP.ContractIDValue )   
  
 )   
  
 AND   
  
 (   
  ( TMP.ContractRateScheduleIDOperator = -1 )   
 OR   
  ( TMP.ContractRateScheduleIDOperator = 0 AND T.ContractRateScheduleID IS NULL )   
 OR   
  ( TMP.ContractRateScheduleIDOperator = 1 AND T.ContractRateScheduleID IS NOT NULL )   
 OR   
  ( TMP.ContractRateScheduleIDOperator = 2 AND T.ContractRateScheduleID = TMP.ContractRateScheduleIDValue )   
 OR   
  ( TMP.ContractRateScheduleIDOperator = 3 AND T.ContractRateScheduleID <> TMP.ContractRateScheduleIDValue )   
 OR   
  ( TMP.ContractRateScheduleIDOperator = 7 AND T.ContractRateScheduleID > TMP.ContractRateScheduleIDValue )   
 OR   
  ( TMP.ContractRateScheduleIDOperator = 8 AND T.ContractRateScheduleID >= TMP.ContractRateScheduleIDValue )   
 OR   
  ( TMP.ContractRateScheduleIDOperator = 9 AND T.ContractRateScheduleID < TMP.ContractRateScheduleIDValue )   
 OR   
  ( TMP.ContractRateScheduleIDOperator = 10 AND T.ContractRateScheduleID <= TMP.ContractRateScheduleIDValue )   
  
 )   
  
 AND   
  
 (   
  ( TMP.ContractRateScheduleStartDateOperator = -1 )   
 OR   
  ( TMP.ContractRateScheduleStartDateOperator = 0 AND T.ContractRateScheduleStartDate IS NULL )   
 OR   
  ( TMP.ContractRateScheduleStartDateOperator = 1 AND T.ContractRateScheduleStartDate IS NOT NULL )   
 OR   
  ( TMP.ContractRateScheduleStartDateOperator = 2 AND T.ContractRateScheduleStartDate = TMP.ContractRateScheduleStartDateValue )   
 OR   
  ( TMP.ContractRateScheduleStartDateOperator = 3 AND T.ContractRateScheduleStartDate <> TMP.ContractRateScheduleStartDateValue )   
 OR   
  ( TMP.ContractRateScheduleStartDateOperator = 7 AND T.ContractRateScheduleStartDate > TMP.ContractRateScheduleStartDateValue )   
 OR   
  ( TMP.ContractRateScheduleStartDateOperator = 8 AND T.ContractRateScheduleStartDate >= TMP.ContractRateScheduleStartDateValue )   
 OR   
  ( TMP.ContractRateScheduleStartDateOperator = 9 AND T.ContractRateScheduleStartDate < TMP.ContractRateScheduleStartDateValue )   
 OR   
  ( TMP.ContractRateScheduleStartDateOperator = 10 AND T.ContractRateScheduleStartDate <= TMP.ContractRateScheduleStartDateValue )   
  
 )   
  
 AND   
  
 (   
  ( TMP.ContractRateScheduleEndDateOperator = -1 )   
 OR   
  ( TMP.ContractRateScheduleEndDateOperator = 0 AND T.ContractRateScheduleEndDate IS NULL )   
 OR   
  ( TMP.ContractRateScheduleEndDateOperator = 1 AND T.ContractRateScheduleEndDate IS NOT NULL )   
 OR   
  ( TMP.ContractRateScheduleEndDateOperator = 2 AND T.ContractRateScheduleEndDate = TMP.ContractRateScheduleEndDateValue )   
 OR   
  ( TMP.ContractRateScheduleEndDateOperator = 3 AND T.ContractRateScheduleEndDate <> TMP.ContractRateScheduleEndDateValue )   
 OR   
  ( TMP.ContractRateScheduleEndDateOperator = 7 AND T.ContractRateScheduleEndDate > TMP.ContractRateScheduleEndDateValue )   
 OR   
  ( TMP.ContractRateScheduleEndDateOperator = 8 AND T.ContractRateScheduleEndDate >= TMP.ContractRateScheduleEndDateValue )   
 OR   
  ( TMP.ContractRateScheduleEndDateOperator = 9 AND T.ContractRateScheduleEndDate < TMP.ContractRateScheduleEndDateValue )   
 OR   
  ( TMP.ContractRateScheduleEndDateOperator = 10 AND T.ContractRateScheduleEndDate <= TMP.ContractRateScheduleEndDateValue )   
  
 )   
  
 AND   
  
 (   
  ( TMP.ContractRateScheduleStatusOperator = -1 )   
 OR   
  ( TMP.ContractRateScheduleStatusOperator = 0 AND T.ContractRateScheduleStatus IS NULL )   
 OR   
  ( TMP.ContractRateScheduleStatusOperator = 1 AND T.ContractRateScheduleStatus IS NOT NULL )   
 OR   
  ( TMP.ContractRateScheduleStatusOperator = 2 AND T.ContractRateScheduleStatus = TMP.ContractRateScheduleStatusValue )   
 OR   
  ( TMP.ContractRateScheduleStatusOperator = 3 AND T.ContractRateScheduleStatus <> TMP.ContractRateScheduleStatusValue )   
 OR   
  ( TMP.ContractRateScheduleStatusOperator = 4 AND T.ContractRateScheduleStatus LIKE TMP.ContractRateScheduleStatusValue + '%')   
 OR   
  ( TMP.ContractRateScheduleStatusOperator = 5 AND T.ContractRateScheduleStatus LIKE '%' + TMP.ContractRateScheduleStatusValue )   
 OR   
  ( TMP.ContractRateScheduleStatusOperator = 6 AND T.ContractRateScheduleStatus LIKE '%' + TMP.ContractRateScheduleStatusValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.ContractRateScheduleSignedDateOperator = -1 )   
 OR   
  ( TMP.ContractRateScheduleSignedDateOperator = 0 AND T.ContractRateScheduleSignedDate IS NULL )   
 OR   
  ( TMP.ContractRateScheduleSignedDateOperator = 1 AND T.ContractRateScheduleSignedDate IS NOT NULL )   
 OR   
  ( TMP.ContractRateScheduleSignedDateOperator = 2 AND T.ContractRateScheduleSignedDate = TMP.ContractRateScheduleSignedDateValue )   
 OR   
  ( TMP.ContractRateScheduleSignedDateOperator = 3 AND T.ContractRateScheduleSignedDate <> TMP.ContractRateScheduleSignedDateValue )   
 OR   
  ( TMP.ContractRateScheduleSignedDateOperator = 7 AND T.ContractRateScheduleSignedDate > TMP.ContractRateScheduleSignedDateValue )   
 OR   
  ( TMP.ContractRateScheduleSignedDateOperator = 8 AND T.ContractRateScheduleSignedDate >= TMP.ContractRateScheduleSignedDateValue )   
 OR   
  ( TMP.ContractRateScheduleSignedDateOperator = 9 AND T.ContractRateScheduleSignedDate < TMP.ContractRateScheduleSignedDateValue )   
 OR   
  ( TMP.ContractRateScheduleSignedDateOperator = 10 AND T.ContractRateScheduleSignedDate <= TMP.ContractRateScheduleSignedDateValue )   
  
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
  ( TMP.ContractStartDateOperator = -1 )   
 OR   
  ( TMP.ContractStartDateOperator = 0 AND T.ContractStartDate IS NULL )   
 OR   
  ( TMP.ContractStartDateOperator = 1 AND T.ContractStartDate IS NOT NULL )   
 OR   
  ( TMP.ContractStartDateOperator = 2 AND T.ContractStartDate = TMP.ContractStartDateValue )   
 OR   
  ( TMP.ContractStartDateOperator = 3 AND T.ContractStartDate <> TMP.ContractStartDateValue )   
 OR   
  ( TMP.ContractStartDateOperator = 7 AND T.ContractStartDate > TMP.ContractStartDateValue )   
 OR   
  ( TMP.ContractStartDateOperator = 8 AND T.ContractStartDate >= TMP.ContractStartDateValue )   
 OR   
  ( TMP.ContractStartDateOperator = 9 AND T.ContractStartDate < TMP.ContractStartDateValue )   
 OR   
  ( TMP.ContractStartDateOperator = 10 AND T.ContractStartDate <= TMP.ContractStartDateValue )   
  
 )   
  
 AND   
 1 = 1   
 )   
 ORDER BY   
  CASE WHEN @sortColumn = 'ContractID' AND @sortOrder = 'ASC'  
  THEN T.ContractID END ASC,   
  CASE WHEN @sortColumn = 'ContractID' AND @sortOrder = 'DESC'  
  THEN T.ContractID END DESC ,  
  
  CASE WHEN @sortColumn = 'ContractRateScheduleID' AND @sortOrder = 'ASC'  
  THEN T.ContractRateScheduleID END ASC,   
  CASE WHEN @sortColumn = 'ContractRateScheduleID' AND @sortOrder = 'DESC'  
  THEN T.ContractRateScheduleID END DESC ,  
  
  CASE WHEN @sortColumn = 'ContractRateScheduleStartDate' AND @sortOrder = 'ASC'  
  THEN T.ContractRateScheduleStartDate END ASC,   
  CASE WHEN @sortColumn = 'ContractRateScheduleStartDate' AND @sortOrder = 'DESC'  
  THEN T.ContractRateScheduleStartDate END DESC ,  
  
  CASE WHEN @sortColumn = 'ContractRateScheduleEndDate' AND @sortOrder = 'ASC'  
  THEN T.ContractRateScheduleEndDate END ASC,   
  CASE WHEN @sortColumn = 'ContractRateScheduleEndDate' AND @sortOrder = 'DESC'  
  THEN T.ContractRateScheduleEndDate END DESC ,  
  
  CASE WHEN @sortColumn = 'ContractRateScheduleStatus' AND @sortOrder = 'ASC'  
  THEN T.ContractRateScheduleStatus END ASC,   
  CASE WHEN @sortColumn = 'ContractRateScheduleStatus' AND @sortOrder = 'DESC'  
  THEN T.ContractRateScheduleStatus END DESC ,  
  
  CASE WHEN @sortColumn = 'ContractRateScheduleSignedDate' AND @sortOrder = 'ASC'  
  THEN T.ContractRateScheduleSignedDate END ASC,   
  CASE WHEN @sortColumn = 'ContractRateScheduleSignedDate' AND @sortOrder = 'DESC'  
  THEN T.ContractRateScheduleSignedDate END DESC ,  
  
  CASE WHEN @sortColumn = 'SignedBy' AND @sortOrder = 'ASC'  
  THEN T.SignedBy END ASC,   
  CASE WHEN @sortColumn = 'SignedBy' AND @sortOrder = 'DESC'  
  THEN T.SignedBy END DESC ,  
  
  CASE WHEN @sortColumn = 'SignedByTitle' AND @sortOrder = 'ASC'  
  THEN T.SignedByTitle END ASC,   
  CASE WHEN @sortColumn = 'SignedByTitle' AND @sortOrder = 'DESC'  
  THEN T.SignedByTitle END DESC ,  
  
  CASE WHEN @sortColumn = 'ContractStartDate' AND @sortOrder = 'ASC'  
  THEN T.ContractStartDate END ASC,   
  CASE WHEN @sortColumn = 'ContractStartDate' AND @sortOrder = 'DESC'  
  THEN T.ContractStartDate END DESC   
  
  
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