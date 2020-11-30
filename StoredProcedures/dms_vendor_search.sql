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
 WHERE id = object_id(N'[dbo].[dms_vendor_search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_search] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vendor_search] @searchText = 'TX'
 CREATE PROCEDURE [dbo].[dms_vendor_search]( 
   @searchText	NVARCHAR(100) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 100 
 , @pageSize int = 100
 , @sortColumn nvarchar(100)  = 'VendorName' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
  
SET NOCOUNT ON

SET FMTONLY OFF

CREATE TABLE #FinalResults (
[RowNum] [bigint] NOT NULL IDENTITY(1,1),
VendorID INT NULL,
VendorNumber nvarchar(100) NULL ,
VendorName nvarchar(255) NULL ,
City nvarchar(100) NULL ,
StateProvince nvarchar(100) NULL,
VendorUser nvarchar(100) NULL
)

--------------------- BEGIN -----------------------------
---- Create a temp variable or a CTE with the actual SQL search query ----------
---- and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
-- LOGIC : BEGIN
DECLARE @vendorEntityID INT
DECLARE @vendorLocationEntityID INT
DECLARE @BusinessAddressTypeID INT

SELECT @vendorEntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
SELECT @vendorLocationEntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
SELECT @BusinessAddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Business')

INSERT INTO #FinalResults
SELECT	DISTINCT 
				V.ID,
				V.VendorNumber,
				V.Name AS VendorName,
				VA.City,
				VA.StateProvince,
				Case when VU.ID IS NULL
				THen ' '
				ELSE 'Yes'
				END
				 AS VendorUser
FROM	Vendor V WITH (NOLOCK)
LEFT JOIN VendorUser VU WITH (NOLOCK) ON V.ID = VU.VendorID
LEFT JOIN	AddressEntity VA WITH (NOLOCK) ON VA.RecordID = V.ID AND VA.EntityID = @vendorEntityID AND VA.AddressTypeID = @BusinessAddressTypeID
WHERE	V.IsActive=1 AND 
		(V.Name like '%' + @searchText + '%'
		OR
		V.VendorNumber like '%' + @searchText + '%'
		OR
		VA.City like '%' + @searchText + '%'
		OR
		VA.StateProvince like '%' + @searchText + '%'	)	
			
ORDER BY V.Name ASC


DECLARE @count INT
SET @count = 0
SELECT @count = MAX(RowNum) FROM #FinalResults
SET @endInd = @startInd + @pageSize - 1
IF @startInd > @count
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



SELECT	@count AS TotalRows, F.*

FROM	#FinalResults F
WHERE	F.RowNum BETWEEN @startInd AND @endInd

DROP TABLE #FinalResults



END
