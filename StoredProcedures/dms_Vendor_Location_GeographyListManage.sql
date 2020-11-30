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
 WHERE id = object_id(N'[dbo].[dms_Vendor_Location_GeographyListManage]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Location_GeographyListManage] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Vendor_Location_GeographyListManage]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

CREATE TABLE #tmpForWhereClause
(
	VendorLocationIDValue NVARCHAR(MAX) NULL,
)
CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	VendorLocationID int  NULL ,
	Latitude decimal(10,7)  NULL ,
	Longitude decimal(10,7)  NULL ,
	GeographyLocation nvarchar(MAX)  NULL ,
	ModifyDate datetime  NULL ,
	ModifyBy nvarchar(100)  NULL 
) 

DECLARE @QueryResult AS TABLE( 
	VendorLocationID int  NULL ,
	Latitude decimal(10,7)  NULL ,
	Longitude decimal(10,7)  NULL ,
	GeographyLocation nvarchar(MAX)  NULL ,
	ModifyDate datetime  NULL ,
	ModifyBy nvarchar(100)  NULL 
) 

DECLARE @QueryVendorLocationID AS TABLE( 
	VendorLocationID int  NULL
) 

INSERT INTO #tmpForWhereClause
SELECT  
	T.c.value('@VendorLocationIDValue','NVARCHAR(MAX)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)


INSERT INTO @QueryVendorLocationID(VendorLocationID) SELECT item from dbo.fnSplitString((SELECT TOP 1 VendorLocationIDValue FROM #tmpForWhereClause),',')


INSERT INTO @QueryResult
SELECT 
		VL.ID VendorLocationID,
		VL.Latitude,
		VL.Longitude,
		CONVERT(NVARCHAR(MAX),VL.GeographyLocation) AS GeographyLocation,
		VL.ModifyDate,
		VL.ModifyBy
FROM    VendorLocation VL
WHERE VL.ID IN (SELECT QVL.VendorLocationID FROM @QueryVendorLocationID QVL)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.VendorLocationID,
	T.Latitude,
	T.Longitude,
	T.GeographyLocation,
	T.ModifyDate,
	T.ModifyBy
FROM @QueryResult T
 ORDER BY 
	 CASE WHEN @sortColumn = 'VendorLocationID' AND @sortOrder = 'ASC'
	 THEN T.VendorLocationID END ASC, 
	 CASE WHEN @sortColumn = 'VendorLocationID' AND @sortOrder = 'DESC'
	 THEN T.VendorLocationID END DESC ,

	 CASE WHEN @sortColumn = 'Latitude' AND @sortOrder = 'ASC'
	 THEN T.Latitude END ASC, 
	 CASE WHEN @sortColumn = 'Latitude' AND @sortOrder = 'DESC'
	 THEN T.Latitude END DESC ,

	 CASE WHEN @sortColumn = 'Longitude' AND @sortOrder = 'ASC'
	 THEN T.Longitude END ASC, 
	 CASE WHEN @sortColumn = 'Longitude' AND @sortOrder = 'DESC'
	 THEN T.Longitude END DESC ,

	 CASE WHEN @sortColumn = 'GeographyLocation' AND @sortOrder = 'ASC'
	 THEN T.GeographyLocation END ASC, 
	 CASE WHEN @sortColumn = 'GeographyLocation' AND @sortOrder = 'DESC'
	 THEN T.GeographyLocation END DESC ,

	 CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'ASC'
	 THEN T.ModifyDate END ASC, 
	 CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'DESC'
	 THEN T.ModifyDate END DESC ,

	 CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'ASC'
	 THEN T.ModifyBy END ASC, 
	 CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'DESC'
	 THEN T.ModifyBy END DESC 


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
