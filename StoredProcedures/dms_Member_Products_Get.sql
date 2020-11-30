
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
 WHERE id = object_id(N'[dbo].[dms_Member_Products_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_Products_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Member_Products_Get]( 
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10    
 , @sortColumn nvarchar(100)  = ''   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @MemberID INT = NULL  
 )   
 AS   
BEGIN   
    
  SET NOCOUNT ON  
  
DECLARE @idoc int  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter   
ProductOperator="-1"   
StartDateOperator="-1"   
EndDateOperator="-1"   
StatusOperator="-1"   
ProviderOperator="-1"   
 ></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
ProductOperator INT NOT NULL,  
ProductValue nvarchar(50) NULL,  
StartDateOperator INT NOT NULL,  
StartDateValue datetime NULL,  
EndDateOperator INT NOT NULL,  
EndDateValue datetime NULL,  
StatusOperator INT NOT NULL,  
StatusValue nvarchar(50) NULL,  
ProviderOperator INT NOT NULL,  
ProviderValue nvarchar(50) NULL,  
ContractNumberOperator INT NOT NULL,  
ContractNumberValue nvarchar(100) NULL,  
VINOperator INT NOT NULL,  
VINValue nvarchar(100) NULL  
  
)  
DECLARE @FinalResults TABLE (   
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 Product nvarchar(200)  NULL ,  
 StartDate datetime  NULL ,  
 EndDate datetime  NULL ,  
 Status nvarchar(100)  NULL ,  
 Provider nvarchar(100)  NULL ,  
 PhoneNumber nvarchar(100)  NULL,  
 ContractNumber nvarchar(100)  NULL,  
 VIN  nvarchar(100)  NULL  ,
 HelpText nvarchar(max) NULL
)   
  
DECLARE @QueryResults TABLE (   
 Product nvarchar(200)  NULL ,  
 StartDate datetime  NULL ,  
 EndDate datetime  NULL ,  
 Status nvarchar(100)  NULL ,  
 Provider nvarchar(100)  NULL ,  
 PhoneNumber nvarchar(100)  NULL,  
 ContractNumber nvarchar(100)  NULL,  
 VIN  nvarchar(100)  NULL  ,
 HelpText nvarchar(max) NULL
)   
  
INSERT INTO @tmpForWhereClause  
SELECT    
 ISNULL(ProductOperator,-1),  
 ProductValue ,  
 ISNULL(StartDateOperator,-1),  
 StartDateValue ,  
 ISNULL(EndDateOperator,-1),  
 EndDateValue ,  
 ISNULL(StatusOperator,-1),  
 StatusValue ,  
 ISNULL(ProviderOperator,-1),  
 ProviderValue,  
 ISNULL(ContractNumberOperator,-1),  
 ContractNumberValue ,  
 ISNULL(VINOperator,-1),  
 VINValue   
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
ProductOperator INT,  
ProductValue nvarchar(50)   
,StartDateOperator INT,  
StartDateValue datetime   
,EndDateOperator INT,  
EndDateValue datetime   
,StatusOperator INT,  
StatusValue nvarchar(50)   
,ProviderOperator INT,  
ProviderValue nvarchar(50),  
ContractNumberOperator INT,  
ContractNumberValue  nvarchar(100),  
VINOperator INT,  
VINValue nvarchar(100))   
  
--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
  
INSERT INTO @QueryResults  
SELECT   P.Description AS Product  
   , MP.StartDate AS StartDate  
   , MP.EndDate AS EndDate  
   , CASE WHEN MP.EndDate < GETDATE() THEN 'Inactive' ELSE 'Active' END AS Status  
   , PP.Description AS Provider  
   , PP.PhoneNumber AS PhoneNumber  
   , MP.ContractNumber  
   , MP.VIN  
   , PP.Script AS [HelpText]
 FROM  MemberProduct MP (NOLOCK)  
 JOIN  Membership MS (NOLOCK) ON MP.MembershipID = MS.ID   
 LEFT JOIN Product P (NOLOCK) ON P.ID = MP.ProductID  
 LEFT JOIN ProductProvider PP (NOLOCK) ON PP.ID = MP.ProductProviderID  
 WHERE  MP.MemberID = @MemberID  
    OR  
    (MP.MemberID IS NULL AND MS.ID = (SELECT MembershipID FROM Member WHERE ID = @MemberID))   
 ORDER BY P.Description  
  
  
INSERT INTO @FinalResults  
SELECT   
 T.Product,  
 T.StartDate,  
 T.EndDate,  
 T.Status,  
 T.Provider,  
 T.PhoneNumber,  
 T.ContractNumber,  
 T.VIN  ,
 T.HelpText
FROM @QueryResults T,  
@tmpForWhereClause TMP   
WHERE (   
  
 (   
  ( TMP.ProductOperator = -1 )   
 OR   
  ( TMP.ProductOperator = 0 AND T.Product IS NULL )   
 OR   
  ( TMP.ProductOperator = 1 AND T.Product IS NOT NULL )   
 OR   
  ( TMP.ProductOperator = 2 AND T.Product = TMP.ProductValue )   
 OR   
  ( TMP.ProductOperator = 3 AND T.Product <> TMP.ProductValue )   
 OR   
  ( TMP.ProductOperator = 4 AND T.Product LIKE TMP.ProductValue + '%')   
 OR   
  ( TMP.ProductOperator = 5 AND T.Product LIKE '%' + TMP.ProductValue )   
 OR   
  ( TMP.ProductOperator = 6 AND T.Product LIKE '%' + TMP.ProductValue + '%' )   
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
  ( TMP.ProviderOperator = -1 )   
 OR   
  ( TMP.ProviderOperator = 0 AND T.Provider IS NULL )   
 OR   
  ( TMP.ProviderOperator = 1 AND T.Provider IS NOT NULL )   
 OR   
  ( TMP.ProviderOperator = 2 AND T.Provider = TMP.ProviderValue )   
 OR   
  ( TMP.ProviderOperator = 3 AND T.Provider <> TMP.ProviderValue )   
 OR   
  ( TMP.ProviderOperator = 4 AND T.Provider LIKE TMP.ProviderValue + '%')   
 OR   
  ( TMP.ProviderOperator = 5 AND T.Provider LIKE '%' + TMP.ProviderValue )   
 OR   
  ( TMP.ProviderOperator = 6 AND T.Provider LIKE '%' + TMP.ProviderValue + '%' )   
 )   
  AND   
  
 (   
  ( TMP.ContractNumberOperator = -1 )   
 OR   
  ( TMP.ContractNumberOperator = 0 AND T.ContractNumber IS NULL )   
 OR   
  ( TMP.ContractNumberOperator = 1 AND T.ContractNumber IS NOT NULL )   
 OR   
  ( TMP.ContractNumberOperator = 2 AND T.ContractNumber = TMP.ContractNumberValue )   
 OR   
  ( TMP.ContractNumberOperator = 3 AND T.ContractNumber <> TMP.ContractNumberValue )   
 OR   
  ( TMP.ContractNumberOperator = 4 AND T.ContractNumber LIKE TMP.ContractNumberValue + '%')   
 OR   
  ( TMP.ContractNumberOperator = 5 AND T.ContractNumber LIKE '%' + TMP.ContractNumberValue )   
 OR   
  ( TMP.ContractNumberOperator = 6 AND T.ContractNumber LIKE '%' + TMP.ContractNumberValue + '%' )   
 )   
 AND   
  
 (   
  ( TMP.VINOperator = -1 )   
 OR   
  ( TMP.VINOperator = 0 AND T.VIN IS NULL )   
 OR   
  ( TMP.VINOperator = 1 AND T.VIN IS NOT NULL )   
 OR   
  ( TMP.VINOperator = 2 AND T.VIN = TMP.VINValue )   
 OR   
  ( TMP.VINOperator = 3 AND T.VIN <> TMP.VINValue )   
 OR   
  ( TMP.VINOperator = 4 AND T.VIN LIKE TMP.VINValue + '%')   
 OR   
  ( TMP.VINOperator = 5 AND T.VIN LIKE '%' + TMP.VINValue )   
 OR   
  ( TMP.VINOperator = 6 AND T.VIN LIKE '%' + TMP.VINValue + '%' )   
 )   
  
 AND   
 1 = 1   
 )   
 ORDER BY   
  CASE WHEN @sortColumn = 'Product' AND @sortOrder = 'ASC'  
  THEN T.Product END ASC,   
  CASE WHEN @sortColumn = 'Product' AND @sortOrder = 'DESC'  
  THEN T.Product END DESC ,  
  
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
  
  CASE WHEN @sortColumn = 'Provider' AND @sortOrder = 'ASC'  
  THEN T.Provider END ASC,   
  CASE WHEN @sortColumn = 'Provider' AND @sortOrder = 'DESC'  
  THEN T.Provider END DESC ,  
  
  CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'  
  THEN T.PhoneNumber END ASC,   
  CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'  
  THEN T.PhoneNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'ContractNumber' AND @sortOrder = 'ASC'  
  THEN T.ContractNumber END ASC,   
  CASE WHEN @sortColumn = 'ContractNumber' AND @sortOrder = 'DESC'  
  THEN T.ContractNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'VIN' AND @sortOrder = 'ASC'  
  THEN T.VIN END ASC,   
  CASE WHEN @sortColumn = 'VIN' AND @sortOrder = 'DESC'  
  THEN T.VIN END DESC   
  
  
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