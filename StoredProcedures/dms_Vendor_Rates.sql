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
 WHERE id = object_id(N'[dbo].[dms_Vendor_Rates]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Rates] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Vendor_Rates @vendorlocationid=289
 CREATE PROCEDURE [dbo].[dms_Vendor_Rates]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 50  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @vendorlocationid INT =NULL
) 
 AS 
 BEGIN 
  
      SET NOCOUNT ON

DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
      SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
NameOperator="-1" 
BaseRateOperator="-1" 
EnrouteRateOperator="-1" 
EnrouteFreeMilesOperator="-1" 
ServiceRateOperator="-1" 
ServiceFreeMilesOperator="-1" 
HourlyRateOperator="-1" 
GoaRateOperator="-1"
></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
NameOperator INT NOT NULL,
NameValue nvarchar(50) NULL,
BaseRateOperator INT NOT NULL,
BaseRateValue nvarchar(50) NULL,
EnrouteRateOperator INT NOT NULL,
EnrouteRateValue nvarchar(50) NULL,
EnrouteFreeMilesOperator INT NOT NULL,
EnrouteFreeMilesValue nvarchar(50) NULL,
ServiceRateOperator INT NOT NULL,
ServiceRateValue nvarchar(50) NULL,
ServiceFreeMilesOperator INT NOT NULL,
ServiceFreeMilesValue nvarchar(50) NULL,
HourlyRateOperator INT NOT NULL,
HourlyRateValue decimal NULL,
GoaRateOperator INT NOT NULL,
GoaRateValue nvarchar(50) NULL
)
DECLARE @FinalResults TABLE ( 
      [RowNum] [bigint] NOT NULL IDENTITY(1,1),
      ProductID int NULL,
      Name nvarchar(50)  NULL ,
      BaseRate nvarchar(50)  NULL ,
      EnrouteRate nvarchar(50)  NULL ,
      EnrouteFreeMiles nvarchar(50)  NULL ,
      ServiceRate nvarchar(50)  NULL ,
      ServiceFreeMiles nvarchar(50)  NULL ,
      HourlyRate decimal  NULL ,
      GoaRate nvarchar(50) NULL
) 
DECLARE @FinalResults1 TABLE ( 
      [RowNum] [bigint] NOT NULL IDENTITY(1,1),
      ProductID int NULL,
      Name nvarchar(50)  NULL ,
      BaseRate nvarchar(50)  NULL ,
      EnrouteRate nvarchar(50)  NULL ,
      EnrouteFreeMiles nvarchar(50)  NULL ,
      ServiceRate nvarchar(50)  NULL ,
      ServiceFreeMiles nvarchar(50)  NULL ,
      HourlyRate decimal  NULL ,
      GoaRate nvarchar(50) NULL
) 
INSERT INTO @tmpForWhereClause
SELECT  
      ISNULL(NameOperator,-1),
      NameValue ,
      ISNULL(BaseRateOperator,-1),
      BaseRateValue ,
      ISNULL(EnrouteRateOperator,-1),
      EnrouteRateValue ,
      ISNULL(EnrouteFreeMilesOperator,-1),
      EnrouteFreeMilesValue ,
      ISNULL(ServiceRateOperator,-1),
      ServiceRateValue ,
      ISNULL(ServiceFreeMilesOperator,-1),
      ServiceFreeMilesValue ,
      ISNULL(HourlyRateOperator,-1),
      HourlyRateValue,
      ISNULL(GoaRateOperator,-1),
      GoaRateValue
FROM  OPENXML (@idoc,'/ROW/Filter',1) WITH (
NameOperator INT,
NameValue nvarchar(50) 
,BaseRateOperator INT,
BaseRateValue nvarchar(50) 
,EnrouteRateOperator INT,
EnrouteRateValue nvarchar(50) 
,EnrouteFreeMilesOperator INT,
EnrouteFreeMilesValue nvarchar(50) 
,ServiceRateOperator INT,
ServiceRateValue nvarchar(50) 
,ServiceFreeMilesOperator INT,
ServiceFreeMilesValue nvarchar(50) 
,HourlyRateOperator INT,
HourlyRateValue decimal
,GoaRateOperator INT,
GoaRateValue nvarchar(50)
) 

/* Get Status IDs */ 
DECLARE @ActiveContractStatusID int
      ,@ActiveContractRateScheduleStatusID int
Set @ActiveContractStatusID = (SELECT ID FROM ContractStatus WHERE Name = 'Active')
Set @ActiveContractRateScheduleStatusID = (SELECT ID FROM ContractRateScheduleStatus WHERE Name = 'Active')

INSERT INTO @FinalResults1
SELECT 
  p.ID ProductID,
  p.Name,
  SUM(CASE WHEN rt.Name = 'Base' THEN 
   (CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Price  
    WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Price  
    ELSE 0.00   
    END) 
   ELSE 0 END) AS BaseRate
  ,SUM(CASE WHEN rt.Name = 'Enroute' THEN 
   (CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Price  
    WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Price  
    ELSE 0.00   
    END) 
   ELSE 0 END) AS EnrouteRate
  ,SUM(CASE WHEN rt.Name = 'EnrouteFree' THEN 
   (CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Quantity  
    WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Quantity  
    ELSE 0.00   
    END) 
   ELSE 0 END) AS EnrouteFreeMiles
  ,SUM(CASE WHEN rt.Name = 'Service' THEN 
   (CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Price  
    WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Price  
    ELSE 0.00   
    END) 
   ELSE 0 END) AS ServiceRate
  ,SUM(CASE WHEN rt.Name = 'ServiceFree' THEN 
   (CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Quantity  
    WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Quantity  
    ELSE 0.00   
    END) 
   ELSE 0 END) AS ServiceFreeMiles
  ,SUM(CASE WHEN rt.Name = 'Hourly' THEN 
   (CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Price  
    WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Price  
    ELSE 0.00   
    END) 
   ELSE 0 END) AS HourlyRate
  ,SUM(CASE WHEN rt.Name = 'GoneOnArrival' THEN 
   (CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Price  
    WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Price  
    ELSE 0.00   
    END) 
   ELSE 0 END) AS GOARate
FROM dbo.VendorLocation vl   
JOIN dbo.Vendor v  ON vl.VendorID = v.ID  
JOIN dbo.VendorLocationProduct vlp ON vl.ID = vlp.VendorLocationID AND vlp.IsActive = 1
JOIN dbo.Product p ON p.ID = vlp.ProductID  
JOIN dbo.ProductRateType prt ON prt.ProductID = p.ID 
JOIN dbo.RateType rt ON prt.RateTypeID = rt.ID  
LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() VendorLocationRates ON 
      v.ID = VendorLocationRates.VendorID AND 
      p.ID = VendorLocationRates.ProductID AND 
      prt.RateTypeID = VendorLocationRates.RateTypeID AND
      VendorLocationRates.VendorLocationID = vl.ID
LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() DefaultVendorRates ON 
      v.ID = DefaultVendorRates.VendorID AND 
      p.ID = DefaultVendorRates.ProductID AND 
      prt.RateTypeID = DefaultVendorRates.RateTypeID AND
      DeFaultVendorRates.VendorLocationID IS NULL
WHERE vl.ID = @VendorLocationID
GROUP BY p.ID, p.Name
ORDER BY p.ID, p.Name


--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults
SELECT
      T.ProductID,
      T.Name,
      T.BaseRate,
      T.EnrouteRate,
      T.EnrouteFreeMiles,
      T.ServiceRate,
      T.ServiceFreeMiles,
      T.HourlyRate,
      T.GoaRate
FROM @FinalResults1 T,
@tmpForWhereClause TMP 
WHERE ( 

( 
       
       ( TMP.NameOperator = -1 ) 
 OR 
       ( TMP.NameOperator = 0 AND T.Name IS NULL ) 
 OR 
       ( TMP.NameOperator = 1 AND T.Name IS NOT NULL ) 
 OR 
       ( TMP.NameOperator = 2 AND T.Name = TMP.NameValue ) 
 OR 
       ( TMP.NameOperator = 3 AND T.Name <> TMP.NameValue ) 
 OR 
       ( TMP.NameOperator = 4 AND T.Name LIKE TMP.NameValue + '%') 
 OR 
       ( TMP.NameOperator = 5 AND T.Name LIKE '%' + TMP.NameValue ) 
 OR 
       ( TMP.NameOperator = 6 AND T.Name LIKE '%' + TMP.NameValue + '%' ) 
 ) 

AND 

( 
       ( TMP.BaseRateOperator = -1 ) 
 OR 
       ( TMP.BaseRateOperator = 0 AND T.BaseRate IS NULL ) 
 OR 
       ( TMP.BaseRateOperator = 1 AND T.BaseRate IS NOT NULL ) 
 OR 
       ( TMP.BaseRateOperator = 2 AND T.BaseRate = TMP.BaseRateValue ) 
 OR 
       ( TMP.BaseRateOperator = 3 AND T.BaseRate <> TMP.BaseRateValue ) 
 OR 
       ( TMP.BaseRateOperator = 4 AND T.BaseRate LIKE TMP.BaseRateValue + '%') 
 OR 
       ( TMP.BaseRateOperator = 5 AND T.BaseRate LIKE '%' + TMP.BaseRateValue ) 
 OR 
       ( TMP.BaseRateOperator = 6 AND T.BaseRate LIKE '%' + TMP.BaseRateValue + '%' ) 
 ) 

AND 

( 
       ( TMP.EnrouteRateOperator = -1 ) 
 OR 
       ( TMP.EnrouteRateOperator = 0 AND T.EnrouteRate IS NULL ) 
 OR 
       ( TMP.EnrouteRateOperator = 1 AND T.EnrouteRate IS NOT NULL ) 
 OR 
       ( TMP.EnrouteRateOperator = 2 AND T.EnrouteRate = TMP.EnrouteRateValue ) 
 OR 
       ( TMP.EnrouteRateOperator = 3 AND T.EnrouteRate <> TMP.EnrouteRateValue ) 
 OR 
       ( TMP.EnrouteRateOperator = 4 AND T.EnrouteRate LIKE TMP.EnrouteRateValue + '%') 
 OR 
       ( TMP.EnrouteRateOperator = 5 AND T.EnrouteRate LIKE '%' + TMP.EnrouteRateValue ) 
 OR 
       ( TMP.EnrouteRateOperator = 6 AND T.EnrouteRate LIKE '%' + TMP.EnrouteRateValue + '%' ) 
 ) 

AND 

( 
       ( TMP.EnrouteFreeMilesOperator = -1 ) 
 OR 
       ( TMP.EnrouteFreeMilesOperator = 0 AND T.EnrouteFreeMiles IS NULL ) 
 OR 
       ( TMP.EnrouteFreeMilesOperator = 1 AND T.EnrouteFreeMiles IS NOT NULL ) 
 OR 
       ( TMP.EnrouteFreeMilesOperator = 2 AND T.EnrouteFreeMiles = TMP.EnrouteFreeMilesValue ) 
 OR 
       ( TMP.EnrouteFreeMilesOperator = 3 AND T.EnrouteFreeMiles <> TMP.EnrouteFreeMilesValue ) 
 OR 
       ( TMP.EnrouteFreeMilesOperator = 4 AND T.EnrouteFreeMiles LIKE TMP.EnrouteFreeMilesValue + '%') 
 OR 
       ( TMP.EnrouteFreeMilesOperator = 5 AND T.EnrouteFreeMiles LIKE '%' + TMP.EnrouteFreeMilesValue ) 
 OR 
       ( TMP.EnrouteFreeMilesOperator = 6 AND T.EnrouteFreeMiles LIKE '%' + TMP.EnrouteFreeMilesValue + '%' ) 
 ) 

AND 

( 
       ( TMP.ServiceRateOperator = -1 ) 
 OR 
       ( TMP.ServiceRateOperator = 0 AND T.ServiceRate IS NULL ) 
 OR 
       ( TMP.ServiceRateOperator = 1 AND T.ServiceRate IS NOT NULL ) 
 OR 
       ( TMP.ServiceRateOperator = 2 AND T.ServiceRate = TMP.ServiceRateValue ) 
 OR 
       ( TMP.ServiceRateOperator = 3 AND T.ServiceRate <> TMP.ServiceRateValue ) 
 OR 
       ( TMP.ServiceRateOperator = 4 AND T.ServiceRate LIKE TMP.ServiceRateValue + '%') 
 OR 
       ( TMP.ServiceRateOperator = 5 AND T.ServiceRate LIKE '%' + TMP.ServiceRateValue ) 
 OR 
       ( TMP.ServiceRateOperator = 6 AND T.ServiceRate LIKE '%' + TMP.ServiceRateValue + '%' ) 
 ) 

AND 

( 
       ( TMP.ServiceFreeMilesOperator = -1 ) 
 OR 
       ( TMP.ServiceFreeMilesOperator = 0 AND T.ServiceFreeMiles IS NULL ) 
 OR 
       ( TMP.ServiceFreeMilesOperator = 1 AND T.ServiceFreeMiles IS NOT NULL ) 
 OR 
       ( TMP.ServiceFreeMilesOperator = 2 AND T.ServiceFreeMiles = TMP.ServiceFreeMilesValue ) 
 OR 
       ( TMP.ServiceFreeMilesOperator = 3 AND T.ServiceFreeMiles <> TMP.ServiceFreeMilesValue ) 
 OR 
       ( TMP.ServiceFreeMilesOperator = 4 AND T.ServiceFreeMiles LIKE TMP.ServiceFreeMilesValue + '%') 
 OR 
       ( TMP.ServiceFreeMilesOperator = 5 AND T.ServiceFreeMiles LIKE '%' + TMP.ServiceFreeMilesValue ) 
 OR 
       ( TMP.ServiceFreeMilesOperator = 6 AND T.ServiceFreeMiles LIKE '%' + TMP.ServiceFreeMilesValue + '%' ) 
 ) 

AND 

( 
       ( TMP.HourlyRateOperator = -1 ) 
 OR 
       ( TMP.HourlyRateOperator = 0 AND T.HourlyRate IS NULL ) 
 OR 
       ( TMP.HourlyRateOperator = 1 AND T.HourlyRate IS NOT NULL ) 
 OR 
       ( TMP.HourlyRateOperator = 2 AND T.HourlyRate = TMP.HourlyRateValue ) 
 OR 
       ( TMP.HourlyRateOperator = 3 AND T.HourlyRate <> TMP.HourlyRateValue ) 
 OR 
       ( TMP.HourlyRateOperator = 7 AND T.HourlyRate > TMP.HourlyRateValue ) 
 OR 
       ( TMP.HourlyRateOperator = 8 AND T.HourlyRate >= TMP.HourlyRateValue ) 
 OR 
       ( TMP.HourlyRateOperator = 9 AND T.HourlyRate < TMP.HourlyRateValue ) 
 OR 
       ( TMP.HourlyRateOperator = 10 AND T.HourlyRate <= TMP.HourlyRateValue ) 

) 
 
AND 

( 
       ( TMP.GoaRateOperator = -1 ) 
 OR 
       ( TMP.GoaRateOperator = 0 AND T.GoaRate IS NULL ) 
 OR 
       ( TMP.GoaRateOperator = 1 AND T.GoaRate IS NOT NULL ) 
 OR 
       ( TMP.GoaRateOperator = 2 AND T.GoaRate = TMP.GoaRateValue ) 
 OR 
       ( TMP.GoaRateOperator = 3 AND T.GoaRate <> TMP.GoaRateValue ) 
 OR 
       ( TMP.GoaRateOperator = 4 AND T.GoaRate LIKE TMP.GoaRateValue + '%') 
 OR 
       ( TMP.GoaRateOperator = 5 AND T.GoaRate LIKE '%' + TMP.GoaRateValue ) 
 OR 
       ( TMP.GoaRateOperator = 6 AND T.GoaRate LIKE '%' + TMP.GoaRateValue + '%' ) 
 ) 
 AND 
 1 = 1 
 ) 
 ORDER BY 
       
       CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
      THEN T.Name END ASC, 
       CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
      THEN T.Name END DESC ,

      CASE WHEN @sortColumn = 'BaseRate' AND @sortOrder = 'ASC'
      THEN T.BaseRate END ASC, 
       CASE WHEN @sortColumn = 'BaseRate' AND @sortOrder = 'DESC'
      THEN T.BaseRate END DESC ,

      CASE WHEN @sortColumn = 'EnrouteRate' AND @sortOrder = 'ASC'
      THEN T.EnrouteRate END ASC, 
       CASE WHEN @sortColumn = 'EnrouteRate' AND @sortOrder = 'DESC'
      THEN T.EnrouteRate END DESC ,

      CASE WHEN @sortColumn = 'EnrouteFreeMiles' AND @sortOrder = 'ASC'
      THEN T.EnrouteFreeMiles END ASC, 
       CASE WHEN @sortColumn = 'EnrouteFreeMiles' AND @sortOrder = 'DESC'
      THEN T.EnrouteFreeMiles END DESC ,

      CASE WHEN @sortColumn = 'ServiceRate' AND @sortOrder = 'ASC'
      THEN T.ServiceRate END ASC, 
       CASE WHEN @sortColumn = 'ServiceRate' AND @sortOrder = 'DESC'
      THEN T.ServiceRate END DESC ,

      CASE WHEN @sortColumn = 'ServiceFreeMiles' AND @sortOrder = 'ASC'
      THEN T.ServiceFreeMiles END ASC, 
       CASE WHEN @sortColumn = 'ServiceFreeMiles' AND @sortOrder = 'DESC'
      THEN T.ServiceFreeMiles END DESC ,

      CASE WHEN @sortColumn = 'HourlyRate' AND @sortOrder = 'ASC'
      THEN T.HourlyRate END ASC, 
       CASE WHEN @sortColumn = 'HourlyRate' AND @sortOrder = 'DESC'
      THEN T.HourlyRate END DESC ,
      
       CASE WHEN @sortColumn = 'GoaRate' AND @sortOrder = 'ASC'
      THEN T.GoaRate END ASC, 
       CASE WHEN @sortColumn = 'GoaRate' AND @sortOrder = 'DESC'
      THEN T.GoaRate END DESC 

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