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
 WHERE id = object_id(N'[dbo].[dms_Vendor_Locations]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Locations] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dms_Vendor_Locations] @VendorID=1
 CREATE PROCEDURE [dbo].[dms_Vendor_Locations]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @VendorID INT = NULL
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
VendorLocationOperator="-1"
LocationAddressOperator="-1" 
StateProvinceOperator="-1" 
CountryCodeOperator="-1" 
LatitudeOperator="-1" 
LongitudeOperator="-1" 
ServiceIndicatorOperator="-1" 
PostalCodeOperator="-1"
PartsAndAccessoryCodeOperator="-1"
DispatchNoteOperator="-1"
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
VendorLocationOperator INT NOT NULL,
VendorLocationValue INT NULL,
LocationAddressOperator INT NOT NULL,
LocationAddressValue nvarchar(50) NULL,
StateProvinceOperator INT NOT NULL,
StateProvinceValue nvarchar(50) NULL,
CountryCodeOperator INT NOT NULL,
CountryCodeValue nvarchar(50) NULL,
LatitudeOperator INT NOT NULL,
LatitudeValue decimal (18,4) NULL,
LongitudeOperator INT NOT NULL,
LongitudeValue decimal (18,4) NULL,
ServiceIndicatorOperator INT NOT NULL,
ServiceIndicatorValue nvarchar(50) NULL ,
PostalCodeOperator INT NOT NULL,
PostalCodeValue nvarchar(50) NULL,
PartsAndAccessoryCodeOperator INT NOT NULL,
PartsAndAccessoryCodeValue nvarchar(50) NULL,
DispatchNoteOperator INT NOT NULL,
DispatchNoteValue nvarchar(2000) NULL
)
DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	VendorLocation INT NULL,
	LocationAddress nvarchar(MAX)  NULL ,
	StateProvince nvarchar(50)  NULL ,
	CountryCode nvarchar(50)  NULL ,
	Latitude decimal (18,4)  NULL ,
	Longitude decimal (18,4)  NULL ,
	ServiceIndicator nvarchar(50)  NULL ,
	VendorStatus nvarchar(50)  NULL ,
	PostalCode nvarchar(50) NULL,
	PartsAndAccessoryCode nvarchar(50) NULL,
	DispatchNote nvarchar(2000) NULL,
	IsActive bit NULL
) 
DECLARE @FinalResultsTemp TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	VendorLocation INT NULL,
	LocationAddress nvarchar(MAX)  NULL ,
	StateProvince nvarchar(50)  NULL ,
	CountryCode nvarchar(50)  NULL ,
	Latitude decimal (18,4)  NULL ,
	Longitude decimal (18,4)  NULL ,
	ServiceIndicator nvarchar(50)  NULL ,
	VendorStatus nvarchar(50)  NULL ,
	PostalCode nvarchar(50) NULL,
	PartsAndAccessoryCode nvarchar(50) NULL,
	DispatchNote nvarchar(2000) NULL,
	IsActive bit NULL
) 
INSERT INTO @tmpForWhereClause
SELECT 
 
	ISNULL(VendorLocationOperator,-1),
	VendorLocationValue,
	ISNULL(LocationAddressOperator,-1),
	LocationAddressValue ,
	ISNULL(StateProvinceOperator,-1),
	StateProvinceValue ,
	ISNULL(CountryCodeOperator,-1),
	CountryCodeValue ,
	ISNULL(LatitudeOperator,-1),
	LatitudeValue ,
	ISNULL(LongitudeOperator,-1),
	LongitudeValue ,
	ISNULL(ServiceIndicatorOperator,-1),
	ServiceIndicatorValue ,
	ISNULL(PostalCodeOperator,-1),
	PostalCodeValue,
	ISNULL(PartsAndAccessoryCodeOperator,-1),
	PartsAndAccessoryCodeValue,
	ISNULL(DispatchNoteOperator,-1),
	DispatchNoteValue
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
VendorLocationOperator INT,
VendorLocationValue INT
,LocationAddressOperator INT,
LocationAddressValue nvarchar(50) 
,StateProvinceOperator INT,
StateProvinceValue nvarchar(50) 
,CountryCodeOperator INT,
CountryCodeValue nvarchar(50) 
,LatitudeOperator INT,
LatitudeValue decimal (18,4) 
,LongitudeOperator INT,
LongitudeValue decimal (18,4) 
,ServiceIndicatorOperator INT,
ServiceIndicatorValue nvarchar(50) 
,PostalCodeOperator INT,
PostalCodeValue nvarchar(50)
,PartsAndAccessoryCodeOperator INT,
PartsAndAccessoryCodeValue nvarchar(50)
,DispatchNoteOperator INT,
DispatchNoteValue nvarchar(2000) 
 ) 
INSERT INTO @FinalResultsTemp

SELECT	VL.ID AS VendorLocation
		, ISNULL(REPLACE(RTRIM(
			--COALESCE(AE.Line1, ', ') + 
			--COALESCE(AE.Line2, ', ') +     
			--COALESCE(AE.Line3, ', ') +     
			--COALESCE(AE.City, '') 
			--), '  ', ' ')
			--,'') AS LocationAddress
			COALESCE(AE.Line1, '') + 
			COALESCE(' ' + AE.Line2, '') + 
			COALESCE(' ' + AE.Line3, '') + 
			COALESCE(', ' + AE.City, '') 
			), ' ', ' ')
		,'') AS LocationAddress
		, AE.StateProvince
		, AE.CountryCode
		, VL.Latitude
		, VL.Longitude
		, CASE WHEN ISNULL(VLP.ProductCount,0) > 0 THEN 'Yes' ELSE ' ' END AS ServiceIndicator
		, VLS.Description AS VendorStatus
		, AE.PostalCode
		, VL.PartsAndAccessoryCode
		, VL.DispatchNote
		,VL.IsActive
FROM		VendorLocation VL
JOIN		AddressEntity AE 
		ON AE.RecordID = VL.ID 
		AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
LEFT OUTER JOIN (
		SELECT VendorLocationID, COUNT(*) ProductCount
		FROM VendorLocationProduct 
		GROUP BY VendorLocationID
		) VLP ON VLP.VendorLocationID = VL.ID 
LEFT JOIN		VendorLocationStatus VLS
		ON VLS.ID = VL.VendorLocationStatusID
WHERE		VL.VendorID = @VendorID
AND		ISNULL(VL.IsActive,0) = 1
ORDER BY	VL.ID
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults
SELECT 
	T.VendorLocation, 
	T.LocationAddress,
	T.StateProvince,
	T.CountryCode,
	T.Latitude,
	T.Longitude,
	T.ServiceIndicator,
	T.VendorStatus,
	T.PostalCode,
	T.PartsAndAccessoryCode,
	T.DispatchNote,
	T.IsActive
FROM @FinalResultsTemp T,
@tmpForWhereClause TMP 
WHERE ( 
( 
	 ( TMP.VendorLocationOperator = -1 ) 
 OR 
	 ( TMP.VendorLocationOperator = 0 AND T.VendorLocation IS NULL ) 
 OR 
	 ( TMP.VendorLocationOperator = 1 AND T.VendorLocation IS NOT NULL ) 
 OR 
	 ( TMP.VendorLocationOperator = 2 AND T.VendorLocation = TMP.VendorLocationValue ) 
 OR 
	 ( TMP.VendorLocationOperator = 3 AND T.VendorLocation <> TMP.VendorLocationValue ) 
 OR 
	 ( TMP.VendorLocationOperator = 7 AND T.VendorLocation > TMP.VendorLocationValue ) 
 OR 
	 ( TMP.VendorLocationOperator = 8 AND T.VendorLocation >= TMP.VendorLocationValue ) 
 OR 
	 ( TMP.VendorLocationOperator = 9 AND T.VendorLocation < TMP.VendorLocationValue ) 
 OR 
	 ( TMP.VendorLocationOperator = 10 AND T.VendorLocation <= TMP.VendorLocationValue ) 

 ) 
 AND
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
	 ( TMP.StateProvinceOperator = -1 ) 
 OR 
	 ( TMP.StateProvinceOperator = 0 AND T.StateProvince IS NULL ) 
 OR 
	 ( TMP.StateProvinceOperator = 1 AND T.StateProvince IS NOT NULL ) 
 OR 
	 ( TMP.StateProvinceOperator = 2 AND T.StateProvince = TMP.StateProvinceValue ) 
 OR 
	 ( TMP.StateProvinceOperator = 3 AND T.StateProvince <> TMP.StateProvinceValue ) 
 OR 
	 ( TMP.StateProvinceOperator = 4 AND T.StateProvince LIKE TMP.StateProvinceValue + '%') 
 OR 
	 ( TMP.StateProvinceOperator = 5 AND T.StateProvince LIKE '%' + TMP.StateProvinceValue ) 
 OR 
	 ( TMP.StateProvinceOperator = 6 AND T.StateProvince LIKE '%' + TMP.StateProvinceValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CountryCodeOperator = -1 ) 
 OR 
	 ( TMP.CountryCodeOperator = 0 AND T.CountryCode IS NULL ) 
 OR 
	 ( TMP.CountryCodeOperator = 1 AND T.CountryCode IS NOT NULL ) 
 OR 
	 ( TMP.CountryCodeOperator = 2 AND T.CountryCode = TMP.CountryCodeValue ) 
 OR 
	 ( TMP.CountryCodeOperator = 3 AND T.CountryCode <> TMP.CountryCodeValue ) 
 OR 
	 ( TMP.CountryCodeOperator = 4 AND T.CountryCode LIKE TMP.CountryCodeValue + '%') 
 OR 
	 ( TMP.CountryCodeOperator = 5 AND T.CountryCode LIKE '%' + TMP.CountryCodeValue ) 
 OR 
	 ( TMP.CountryCodeOperator = 6 AND T.CountryCode LIKE '%' + TMP.CountryCodeValue + '%' ) 
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

 ( 
	 ( TMP.ServiceIndicatorOperator = -1 ) 
 OR 
	 ( TMP.ServiceIndicatorOperator = 0 AND T.ServiceIndicator IS NULL ) 
 OR 
	 ( TMP.ServiceIndicatorOperator = 1 AND T.ServiceIndicator IS NOT NULL ) 
 OR 
	 ( TMP.ServiceIndicatorOperator = 2 AND T.ServiceIndicator = TMP.ServiceIndicatorValue ) 
 OR 
	 ( TMP.ServiceIndicatorOperator = 3 AND T.ServiceIndicator <> TMP.ServiceIndicatorValue ) 
 OR 
	 ( TMP.ServiceIndicatorOperator = 4 AND T.ServiceIndicator LIKE TMP.ServiceIndicatorValue + '%') 
 OR 
	 ( TMP.ServiceIndicatorOperator = 5 AND T.ServiceIndicator LIKE '%' + TMP.ServiceIndicatorValue ) 
 OR 
	 ( TMP.ServiceIndicatorOperator = 6 AND T.ServiceIndicator LIKE '%' + TMP.ServiceIndicatorValue + '%' ) 
 ) 

AND 

 ( 
	 ( TMP.PostalCodeOperator = -1 ) 
 OR 
	 ( TMP.PostalCodeOperator = 0 AND T.PostalCode IS NULL ) 
 OR 
	 ( TMP.PostalCodeOperator = 1 AND T.PostalCode IS NOT NULL ) 
 OR 
	 ( TMP.PostalCodeOperator = 2 AND T.PostalCode = TMP.PostalCodeValue ) 
 OR 
	 ( TMP.PostalCodeOperator = 3 AND T.PostalCode <> TMP.PostalCodeValue ) 
 OR 
	 ( TMP.PostalCodeOperator = 4 AND T.PostalCode LIKE TMP.PostalCodeValue + '%') 
 OR 
	 ( TMP.PostalCodeOperator = 5 AND T.PostalCode LIKE '%' + TMP.PostalCodeValue ) 
 OR 
	 ( TMP.PostalCodeOperator = 6 AND T.PostalCode LIKE '%' + TMP.PostalCodeValue + '%' ) 
 ) 
 
 AND 

 ( 
	 ( TMP.PartsAndAccessoryCodeOperator = -1 ) 
 OR 
	 ( TMP.PartsAndAccessoryCodeOperator = 0 AND T.PartsAndAccessoryCode IS NULL ) 
 OR 
	 ( TMP.PartsAndAccessoryCodeOperator = 1 AND T.PartsAndAccessoryCode IS NOT NULL ) 
 OR 
	 ( TMP.PartsAndAccessoryCodeOperator = 2 AND T.PartsAndAccessoryCode = TMP.PartsAndAccessoryCodeValue ) 
 OR 
	 ( TMP.PartsAndAccessoryCodeOperator = 3 AND T.PartsAndAccessoryCode <> TMP.PartsAndAccessoryCodeValue ) 
 OR 
	 ( TMP.PartsAndAccessoryCodeOperator = 4 AND T.PartsAndAccessoryCode LIKE TMP.PartsAndAccessoryCodeValue + '%') 
 OR 
	 ( TMP.PartsAndAccessoryCodeOperator = 5 AND T.PartsAndAccessoryCode LIKE '%' + TMP.PartsAndAccessoryCodeValue ) 
 OR 
	 ( TMP.PartsAndAccessoryCodeOperator = 6 AND T.PartsAndAccessoryCode LIKE '%' + TMP.PartsAndAccessoryCodeValue + '%' ) 
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
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'VendorLocation' AND @sortOrder = 'ASC'
	 THEN T.VendorLocation END ASC, 
	 CASE WHEN @sortColumn = 'VendorLocation' AND @sortOrder = 'DESC'
	 THEN T.VendorLocation END DESC ,
	 
	 CASE WHEN @sortColumn = 'LocationAddress' AND @sortOrder = 'ASC'
	 THEN T.LocationAddress END ASC, 
	 CASE WHEN @sortColumn = 'LocationAddress' AND @sortOrder = 'DESC'
	 THEN T.LocationAddress END DESC ,

	 CASE WHEN @sortColumn = 'StateProvince' AND @sortOrder = 'ASC'
	 THEN T.StateProvince END ASC, 
	 CASE WHEN @sortColumn = 'StateProvince' AND @sortOrder = 'DESC'
	 THEN T.StateProvince END DESC ,

	 CASE WHEN @sortColumn = 'CountryCode' AND @sortOrder = 'ASC'
	 THEN T.CountryCode END ASC, 
	 CASE WHEN @sortColumn = 'CountryCode' AND @sortOrder = 'DESC'
	 THEN T.CountryCode END DESC ,

	 CASE WHEN @sortColumn = 'Latitude' AND @sortOrder = 'ASC'
	 THEN T.Latitude END ASC, 
	 CASE WHEN @sortColumn = 'Latitude' AND @sortOrder = 'DESC'
	 THEN T.Latitude END DESC ,

	 CASE WHEN @sortColumn = 'Longitude' AND @sortOrder = 'ASC'
	 THEN T.Longitude END ASC, 
	 CASE WHEN @sortColumn = 'Longitude' AND @sortOrder = 'DESC'
	 THEN T.Longitude END DESC ,

	 CASE WHEN @sortColumn = 'ServiceIndicator' AND @sortOrder = 'ASC'
	 THEN T.ServiceIndicator END ASC, 
	 CASE WHEN @sortColumn = 'ServiceIndicator' AND @sortOrder = 'DESC'
	 THEN T.ServiceIndicator END DESC ,

	 CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'ASC'
	 THEN T.VendorStatus END ASC, 
	 CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'DESC'
	 THEN T.VendorStatus END DESC ,
	 
	 CASE WHEN @sortColumn = 'PostalCode' AND @sortOrder = 'ASC'
	 THEN T.PostalCode END ASC, 
	 CASE WHEN @sortColumn = 'PostalCode' AND @sortOrder = 'DESC'
	 THEN T.PostalCode END DESC ,
	 
	 CASE WHEN @sortColumn = 'PartsAndAccessoryCode' AND @sortOrder = 'ASC'
	 THEN T.PartsAndAccessoryCode END ASC, 
	 CASE WHEN @sortColumn = 'PartsAndAccessoryCode' AND @sortOrder = 'DESC'
	 THEN T.PartsAndAccessoryCode END DESC ,
	 
	 CASE WHEN @sortColumn = 'DispatchNote' AND @sortOrder = 'ASC'
	 THEN T.DispatchNote END ASC, 
	 CASE WHEN @sortColumn = 'DispatchNote' AND @sortOrder = 'DESC'
	 THEN T.DispatchNote END DESC 


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
