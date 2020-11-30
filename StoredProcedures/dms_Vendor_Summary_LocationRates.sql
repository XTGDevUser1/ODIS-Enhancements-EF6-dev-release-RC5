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
 WHERE id = object_id(N'[dbo].[dms_Vendor_Summary_LocationRates]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Summary_LocationRates] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Vendor_Summary_LocationRates]( 
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
LocationAddressOperator="-1" 
StatusOperator="-1" 
DispatchNumberOperator="-1" 
FaxNumberOperator="-1" 
CellNumberOperator="-1" 
IsDispatchNoteOperator="-1" 
DispatchNoteOperator="-1" 
LatitudeOperator="-1" 
LongitudeOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
LocationAddressOperator INT NOT NULL,
LocationAddressValue nvarchar(100) NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL,
DispatchNumberOperator INT NOT NULL,
DispatchNumberValue nvarchar(100) NULL,
FaxNumberOperator INT NOT NULL,
FaxNumberValue nvarchar(100) NULL,
CellNumberOperator INT NOT NULL,
CellNumberValue nvarchar(100) NULL,
IsDispatchNoteOperator INT NOT NULL,
IsDispatchNoteValue nvarchar(100) NULL,
DispatchNoteOperator INT NOT NULL,
DispatchNoteValue nvarchar(100) NULL,
LatitudeOperator INT NOT NULL,
LatitudeValue decimal NULL,
LongitudeOperator INT NOT NULL,
LongitudeValue decimal NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	VendorID int  NULL ,
	VendorLocationID int  NULL ,
	LocationAddress nvarchar(MAX)  NULL ,
	Status nvarchar(MAX)  NULL ,
	DispatchNumber nvarchar(100)  NULL ,
	FaxNumber nvarchar(100)  NULL ,
	CellNumber nvarchar(100)  NULL ,
	IsDispatchNote nvarchar(MAX)  NULL ,
	DispatchNote nvarchar(MAX)  NULL ,
	Latitude decimal(10,7)  NULL ,
	Longitude decimal(10,7)  NULL 
) 

DECLARE @Query AS TABLE( 
	VendorID int  NULL ,
	VendorLocationID int  NULL ,
	LocationAddress nvarchar(MAX)  NULL ,
	Status nvarchar(MAX)  NULL ,
	DispatchNumber nvarchar(100)  NULL ,
	FaxNumber nvarchar(100)  NULL ,
	CellNumber nvarchar(100)  NULL ,
	IsDispatchNote nvarchar(MAX)  NULL ,
	DispatchNote nvarchar(MAX)  NULL ,
	Latitude decimal(10,7)  NULL ,
	Longitude decimal(10,7)  NULL 
) 
INSERT INTO @Query
SELECT	VL.VendorID,
		VL.ID VendorLocationID,
		ISNULL(REPLACE(RTRIM(
		COALESCE(AE.Line1, '') + 
		COALESCE(' ' + AE.Line2, '') + 
		COALESCE(' ' + AE.Line3, '') + 
		COALESCE(', ' + AE.City, '') +
		COALESCE(RTRIM(', ' + AE.StateProvince), '') + 
		COALESCE(' ' + AE.PostalCode, '') +	
		COALESCE(' ' + AE.CountryCode, '') 
		), '  ', ' ')
		,'') AS LocationAddress
		, VLS.Description AS Status
		, PE.PhoneNumber AS DispatchNumber
		, PEF.PhoneNumber AS FaxNumber
		, PEC.PhoneNumber AS CellNumber
		, CASE
			WHEN ISNULL(VL.DispatchNote,'')='' THEN 'No'
			ELSE 'Yes'
		  END AS IsDispatchNote
		, VL.DispatchNote
		, VL.Latitude AS Latitude
		, VL.Longitude AS Longitude
FROM	VendorLocation VL
JOIN	VendorLocationStatus VLS ON VLS.ID = VL.VendorLocationStatusID
LEFT JOIN AddressEntity AE ON AE.RecordID = VL.ID AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') 
LEFT JOIN PhoneEntity PE ON PE.RecordID = VL.ID AND PE.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') 
		AND PE.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Dispatch') 
LEFT JOIN PhoneEntity PEF ON PEF.RecordID = VL.ID AND PEF.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') 
		AND PEF.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Fax') 
LEFT JOIN PhoneEntity PEC ON PEC.RecordID = VL.ID AND PEC.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') 
		AND PEC.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Cell') 
WHERE	VL.VendorID = @VendorID

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@LocationAddressOperator','INT'),-1),
	T.c.value('@LocationAddressValue','nvarchar(100)') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DispatchNumberOperator','INT'),-1),
	T.c.value('@DispatchNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@FaxNumberOperator','INT'),-1),
	T.c.value('@FaxNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CellNumberOperator','INT'),-1),
	T.c.value('@CellNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@IsDispatchNoteOperator','INT'),-1),
	T.c.value('@IsDispatchNoteValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DispatchNoteOperator','INT'),-1),
	T.c.value('@DispatchNoteValue','nvarchar(100)') ,
	ISNULL(T.c.value('@LatitudeOperator','INT'),-1),
	T.c.value('@LatitudeValue','decimal') ,
	ISNULL(T.c.value('@LongitudeOperator','INT'),-1),
	T.c.value('@LongitudeValue','decimal') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.VendorID,
	T.VendorLocationID,
	T.LocationAddress,
	T.Status,
	T.DispatchNumber,
	T.FaxNumber,
	T.CellNumber,
	T.IsDispatchNote,
	T.DispatchNote,
	T.Latitude,
	T.Longitude
FROM @Query T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.LocationAddressOperator = -1 ) 
 OR 
	 ( TMP.LocationAddressOperator = 0 AND T.LocationAddress IS NULL ) 
 OR 
	 ( TMP.LocationAddressOperator = 1 AND T.LocationAddress IS NOT NULL ) 
 OR 
	 ( TMP.LocationAddressOperator = 2 AND T.LocationAddress = TMP.LocationAddressValue ) 
 OR 
	 ( TMP.LocationAddressOperator = 3 AND T.LocationAddress <> TMP.LocationAddressValue ) 
 OR 
	 ( TMP.LocationAddressOperator = 4 AND T.LocationAddress LIKE TMP.LocationAddressValue + '%') 
 OR 
	 ( TMP.LocationAddressOperator = 5 AND T.LocationAddress LIKE '%' + TMP.LocationAddressValue ) 
 OR 
	 ( TMP.LocationAddressOperator = 6 AND T.LocationAddress LIKE '%' + TMP.LocationAddressValue + '%' ) 
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
	 ( TMP.DispatchNumberOperator = -1 ) 
 OR 
	 ( TMP.DispatchNumberOperator = 0 AND T.DispatchNumber IS NULL ) 
 OR 
	 ( TMP.DispatchNumberOperator = 1 AND T.DispatchNumber IS NOT NULL ) 
 OR 
	 ( TMP.DispatchNumberOperator = 2 AND T.DispatchNumber = TMP.DispatchNumberValue ) 
 OR 
	 ( TMP.DispatchNumberOperator = 3 AND T.DispatchNumber <> TMP.DispatchNumberValue ) 
 OR 
	 ( TMP.DispatchNumberOperator = 4 AND T.DispatchNumber LIKE TMP.DispatchNumberValue + '%') 
 OR 
	 ( TMP.DispatchNumberOperator = 5 AND T.DispatchNumber LIKE '%' + TMP.DispatchNumberValue ) 
 OR 
	 ( TMP.DispatchNumberOperator = 6 AND T.DispatchNumber LIKE '%' + TMP.DispatchNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.FaxNumberOperator = -1 ) 
 OR 
	 ( TMP.FaxNumberOperator = 0 AND T.FaxNumber IS NULL ) 
 OR 
	 ( TMP.FaxNumberOperator = 1 AND T.FaxNumber IS NOT NULL ) 
 OR 
	 ( TMP.FaxNumberOperator = 2 AND T.FaxNumber = TMP.FaxNumberValue ) 
 OR 
	 ( TMP.FaxNumberOperator = 3 AND T.FaxNumber <> TMP.FaxNumberValue ) 
 OR 
	 ( TMP.FaxNumberOperator = 4 AND T.FaxNumber LIKE TMP.FaxNumberValue + '%') 
 OR 
	 ( TMP.FaxNumberOperator = 5 AND T.FaxNumber LIKE '%' + TMP.FaxNumberValue ) 
 OR 
	 ( TMP.FaxNumberOperator = 6 AND T.FaxNumber LIKE '%' + TMP.FaxNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CellNumberOperator = -1 ) 
 OR 
	 ( TMP.CellNumberOperator = 0 AND T.CellNumber IS NULL ) 
 OR 
	 ( TMP.CellNumberOperator = 1 AND T.CellNumber IS NOT NULL ) 
 OR 
	 ( TMP.CellNumberOperator = 2 AND T.CellNumber = TMP.CellNumberValue ) 
 OR 
	 ( TMP.CellNumberOperator = 3 AND T.CellNumber <> TMP.CellNumberValue ) 
 OR 
	 ( TMP.CellNumberOperator = 4 AND T.CellNumber LIKE TMP.CellNumberValue + '%') 
 OR 
	 ( TMP.CellNumberOperator = 5 AND T.CellNumber LIKE '%' + TMP.CellNumberValue ) 
 OR 
	 ( TMP.CellNumberOperator = 6 AND T.CellNumber LIKE '%' + TMP.CellNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.IsDispatchNoteOperator = -1 ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 0 AND T.IsDispatchNote IS NULL ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 1 AND T.IsDispatchNote IS NOT NULL ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 2 AND T.IsDispatchNote = TMP.IsDispatchNoteValue ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 3 AND T.IsDispatchNote <> TMP.IsDispatchNoteValue ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 4 AND T.IsDispatchNote LIKE TMP.IsDispatchNoteValue + '%') 
 OR 
	 ( TMP.IsDispatchNoteOperator = 5 AND T.IsDispatchNote LIKE '%' + TMP.IsDispatchNoteValue ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 6 AND T.IsDispatchNote LIKE '%' + TMP.IsDispatchNoteValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DispatchNoteOperator = -1 ) 
 OR 
	 ( TMP.DispatchNoteOperator = 0 AND T.DispatchNote IS NULL ) 
 OR 
	 ( TMP.DispatchNoteOperator = 1 AND T.DispatchNote IS NOT NULL ) 
 OR 
	 ( TMP.DispatchNoteOperator = 2 AND T.DispatchNote = TMP.DispatchNoteValue ) 
 OR 
	 ( TMP.DispatchNoteOperator = 3 AND T.DispatchNote <> TMP.DispatchNoteValue ) 
 OR 
	 ( TMP.DispatchNoteOperator = 4 AND T.DispatchNote LIKE TMP.DispatchNoteValue + '%') 
 OR 
	 ( TMP.DispatchNoteOperator = 5 AND T.DispatchNote LIKE '%' + TMP.DispatchNoteValue ) 
 OR 
	 ( TMP.DispatchNoteOperator = 6 AND T.DispatchNote LIKE '%' + TMP.DispatchNoteValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LatitudeOperator = -1 ) 
 OR 
	 ( TMP.LatitudeOperator = 0 AND T.Latitude IS NULL ) 
 OR 
	 ( TMP.LatitudeOperator = 1 AND T.Latitude IS NOT NULL ) 
 OR 
	 ( TMP.LatitudeOperator = 2 AND T.Latitude = TMP.LatitudeValue ) 
 OR 
	 ( TMP.LatitudeOperator = 3 AND T.Latitude <> TMP.LatitudeValue ) 
 OR 
	 ( TMP.LatitudeOperator = 7 AND T.Latitude > TMP.LatitudeValue ) 
 OR 
	 ( TMP.LatitudeOperator = 8 AND T.Latitude >= TMP.LatitudeValue ) 
 OR 
	 ( TMP.LatitudeOperator = 9 AND T.Latitude < TMP.LatitudeValue ) 
 OR 
	 ( TMP.LatitudeOperator = 10 AND T.Latitude <= TMP.LatitudeValue ) 

 ) 

 AND 

 ( 
	 ( TMP.LongitudeOperator = -1 ) 
 OR 
	 ( TMP.LongitudeOperator = 0 AND T.Longitude IS NULL ) 
 OR 
	 ( TMP.LongitudeOperator = 1 AND T.Longitude IS NOT NULL ) 
 OR 
	 ( TMP.LongitudeOperator = 2 AND T.Longitude = TMP.LongitudeValue ) 
 OR 
	 ( TMP.LongitudeOperator = 3 AND T.Longitude <> TMP.LongitudeValue ) 
 OR 
	 ( TMP.LongitudeOperator = 7 AND T.Longitude > TMP.LongitudeValue ) 
 OR 
	 ( TMP.LongitudeOperator = 8 AND T.Longitude >= TMP.LongitudeValue ) 
 OR 
	 ( TMP.LongitudeOperator = 9 AND T.Longitude < TMP.LongitudeValue ) 
 OR 
	 ( TMP.LongitudeOperator = 10 AND T.Longitude <= TMP.LongitudeValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'LocationAddress' AND @sortOrder = 'ASC'
	 THEN T.LocationAddress END ASC, 
	 CASE WHEN @sortColumn = 'LocationAddress' AND @sortOrder = 'DESC'
	 THEN T.LocationAddress END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC ,

	 CASE WHEN @sortColumn = 'DispatchNumber' AND @sortOrder = 'ASC'
	 THEN T.DispatchNumber END ASC, 
	 CASE WHEN @sortColumn = 'DispatchNumber' AND @sortOrder = 'DESC'
	 THEN T.DispatchNumber END DESC ,

	 CASE WHEN @sortColumn = 'FaxNumber' AND @sortOrder = 'ASC'
	 THEN T.FaxNumber END ASC, 
	 CASE WHEN @sortColumn = 'FaxNumber' AND @sortOrder = 'DESC'
	 THEN T.FaxNumber END DESC ,

	 CASE WHEN @sortColumn = 'CellNumber' AND @sortOrder = 'ASC'
	 THEN T.CellNumber END ASC, 
	 CASE WHEN @sortColumn = 'CellNumber' AND @sortOrder = 'DESC'
	 THEN T.CellNumber END DESC ,

	 CASE WHEN @sortColumn = 'IsDispatchNote' AND @sortOrder = 'ASC'
	 THEN T.IsDispatchNote END ASC, 
	 CASE WHEN @sortColumn = 'IsDispatchNote' AND @sortOrder = 'DESC'
	 THEN T.IsDispatchNote END DESC ,

	 CASE WHEN @sortColumn = 'DispatchNote' AND @sortOrder = 'ASC'
	 THEN T.DispatchNote END ASC, 
	 CASE WHEN @sortColumn = 'DispatchNote' AND @sortOrder = 'DESC'
	 THEN T.DispatchNote END DESC ,

	 CASE WHEN @sortColumn = 'LatitudeText' AND @sortOrder = 'ASC'
	 THEN T.Latitude END ASC, 
	 CASE WHEN @sortColumn = 'LatitudeText' AND @sortOrder = 'DESC'
	 THEN T.Latitude END DESC ,

	 CASE WHEN @sortColumn = 'LongitudeText' AND @sortOrder = 'ASC'
	 THEN T.Longitude END ASC, 
	 CASE WHEN @sortColumn = 'LongitudeText' AND @sortOrder = 'DESC'
	 THEN T.Longitude END DESC 


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

SELECT @count AS TotalRows,
	   FR.[RowNum],
	   FR.VendorID,
	   FR.VendorLocationID,
	   FR.LocationAddress,
	   FR.[Status],
	   FR.DispatchNumber,
	   FR.FaxNumber,
	   FR.CellNumber,
	   FR.IsDispatchNote,
 	   FR.DispatchNote,
	   FR.Latitude,
	   FR.Longitude,
	   CONVERT(NVARCHAR(MAX),FR.Latitude) LatitudeText,
	   CONVERT(NVARCHAR(MAX),FR.Longitude) LongitudeText
FROM #FinalResults FR 
WHERE FR.RowNum BETWEEN @startInd AND @endInd

DROP TABLE #tmpForWhereClause
DROP TABLE #FinalResults
END
