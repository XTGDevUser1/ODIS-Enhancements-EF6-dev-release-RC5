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
 WHERE id = object_id(N'[dbo].dms_Membership_Members_List_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Membership_Members_List_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC dms_Membership_Members_List_Get @MembershipID=1
 CREATE PROCEDURE [dbo].dms_Membership_Members_List_Get( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @MembershipID INT = NULL 
 ) 
 AS 
 BEGIN 
  SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
MembershipNumberOperator="-1" 
LastNameOperator="-1" 
FirstNameOperator="-1" 
MiddlenameOperator="-1" 
StateProvinceOperator="-1" 
CityStateZipOperator="-1" 
PhoneNumberOperator="-1" 
EffectiveDateOperator="-1" 
ExpirationDateOperator="-1" 
RequestCountOperator="-1" 
StatusOperator="-1" 
 ></Filter></ROW>'
END


DECLARE @now DATETIME, @minDate DATETIME
	
SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
SET @minDate = '1900-01-01' 

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
MembershipNumberOperator INT NOT NULL,
MembershipNumberValue nvarchar(100) NULL,
LastNameOperator INT NOT NULL,
LastNameValue nvarchar(100) NULL,
FirstNameOperator INT NOT NULL,
FirstNameValue nvarchar(100) NULL,
MiddlenameOperator INT NOT NULL,
MiddlenameValue nvarchar(100) NULL,
StateProvinceOperator INT NOT NULL,
StateProvinceValue nvarchar(100) NULL,
CityStateZipOperator INT NOT NULL,
CityStateZipValue nvarchar(100) NULL,
PhoneNumberOperator INT NOT NULL,
PhoneNumberValue nvarchar(100) NULL,
EffectiveDateOperator INT NOT NULL,
EffectiveDateValue datetime NULL,
ExpirationDateOperator INT NOT NULL,
ExpirationDateValue datetime NULL,
RequestCountOperator INT NOT NULL,
RequestCountValue int NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL
)
 DECLARE @FinalResults AS TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	MembershipNumber nvarchar(100)  NULL ,
	LastName nvarchar(100)  NULL ,
	FirstName nvarchar(100)  NULL ,
	Middlename nvarchar(100)  NULL ,
	StateProvince nvarchar(100)  NULL ,
	CityStateZip nvarchar(100)  NULL ,
	PhoneNumber nvarchar(100)  NULL ,
	EffectiveDate datetime  NULL ,
	ExpirationDate datetime  NULL ,
	RequestCount int  NULL ,
	Status nvarchar(100)  NULL 
) 

DECLARE @FinalResults_TEMP AS TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	MembershipNumber nvarchar(100)  NULL ,
	LastName nvarchar(100)  NULL ,
	FirstName nvarchar(100)  NULL ,
	Middlename nvarchar(100)  NULL ,
	StateProvince nvarchar(100)  NULL ,
	CityStateZip nvarchar(100)  NULL ,
	PhoneNumber nvarchar(100)  NULL ,
	EffectiveDate datetime  NULL ,
	ExpirationDate datetime  NULL ,
	RequestCount int  NULL ,
	Status nvarchar(100)  NULL 
)

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@MembershipNumberOperator','INT'),-1),
	T.c.value('@MembershipNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@LastNameOperator','INT'),-1),
	T.c.value('@LastNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@FirstNameOperator','INT'),-1),
	T.c.value('@FirstNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@MiddlenameOperator','INT'),-1),
	T.c.value('@MiddlenameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@StateProvinceOperator','INT'),-1),
	T.c.value('@StateProvinceValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CityStateZipOperator','INT'),-1),
	T.c.value('@CityStateZipValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PhoneNumberOperator','INT'),-1),
	T.c.value('@PhoneNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@EffectiveDateOperator','INT'),-1),
	T.c.value('@EffectiveDateValue','datetime') ,
	ISNULL(T.c.value('@ExpirationDateOperator','INT'),-1),
	T.c.value('@ExpirationDateValue','datetime') ,
	ISNULL(T.c.value('@RequestCountOperator','INT'),-1),
	T.c.value('@RequestCountValue','int') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)


INSERT INTO @FinalResults_TEMP
SELECT M.ID
	, MS.MembershipNumber
	, REPLACE(RTRIM(
		COALESCE((CASE WHEN M.IsPrimary = 1 THEN '*' + M.LastName ELSE M.LastName END),'')+
		COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')
	  ),'','') AS LastName
	, M.FirstName
	, M.Middlename
	, AE.StateProvince
	, REPLACE(RTRIM(
		COALESCE(AE.Line1,'')+
		COALESCE(' ' + AE.Line2,'')+
		COALESCE(', ' + City,'')+
		COALESCE(', ' + RTRIM(StateProvince),'')+
		COALESCE(' ' + PostalCode,'')+
		COALESCE(' ' + CountryCode,'')
	  ),'','') AS CityStateZip
	, PE.PhoneNumber
	, CONVERT(NVARCHAR(10),M.EffectiveDate,101) AS EffectiveDate
	, CONVERT(NVARCHAR(10),M.ExpirationDate,101) AS ExpirationDate
	, (SELECT COUNT(*)
		FROM ServiceRequest SR
		JOIN [Case] C ON C.ID = SR.CaseID
		WHERE C.MemberID = M.ID
		GROUP BY C.MemberID
	  ) AS RequestCount
	, CASE	WHEN ISNULL(M.EffectiveDate,@minDate) <= @now AND ISNULL(M.ExpirationDate,@minDate) >= @now
					THEN 'Active'
					ELSE 'Inactive'
			END AS Status
      FROM Member M
LEFT JOIN Membership MS ON MS.ID = M.MembershipID
LEFT JOIN AddressEntity AE ON AE.RecordID = M.ID AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Member') AND AE.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Home')
LEFT JOIN PhoneEntity PE ON PE.RecordID = M.ID AND PE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Member') AND PE.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Home')
WHERE M.IsActive = 1
AND M.MembershipID = @MembershipID
ORDER BY M.IsPrimary DESC, M.LastName, M.FirstName, M.MiddleName
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults
SELECT 
	T.ID,
	T.MembershipNumber,
	T.LastName,
	T.FirstName,
	T.Middlename,
	T.StateProvince,
	T.CityStateZip,
	T.PhoneNumber,
	T.EffectiveDate,
	T.ExpirationDate,
	T.RequestCount,
	T.Status
FROM @FinalResults_TEMP T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.IDOperator = -1 ) 
 OR 
	 ( TMP.IDOperator = 0 AND T.ID IS NULL ) 
 OR 
	 ( TMP.IDOperator = 1 AND T.ID IS NOT NULL ) 
 OR 
	 ( TMP.IDOperator = 2 AND T.ID = TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 3 AND T.ID <> TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 7 AND T.ID > TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 8 AND T.ID >= TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 9 AND T.ID < TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 10 AND T.ID <= TMP.IDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.MembershipNumberOperator = -1 ) 
 OR 
	 ( TMP.MembershipNumberOperator = 0 AND T.MembershipNumber IS NULL ) 
 OR 
	 ( TMP.MembershipNumberOperator = 1 AND T.MembershipNumber IS NOT NULL ) 
 OR 
	 ( TMP.MembershipNumberOperator = 2 AND T.MembershipNumber = TMP.MembershipNumberValue ) 
 OR 
	 ( TMP.MembershipNumberOperator = 3 AND T.MembershipNumber <> TMP.MembershipNumberValue ) 
 OR 
	 ( TMP.MembershipNumberOperator = 4 AND T.MembershipNumber LIKE TMP.MembershipNumberValue + '%') 
 OR 
	 ( TMP.MembershipNumberOperator = 5 AND T.MembershipNumber LIKE '%' + TMP.MembershipNumberValue ) 
 OR 
	 ( TMP.MembershipNumberOperator = 6 AND T.MembershipNumber LIKE '%' + TMP.MembershipNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LastNameOperator = -1 ) 
 OR 
	 ( TMP.LastNameOperator = 0 AND T.LastName IS NULL ) 
 OR 
	 ( TMP.LastNameOperator = 1 AND T.LastName IS NOT NULL ) 
 OR 
	 ( TMP.LastNameOperator = 2 AND T.LastName = TMP.LastNameValue ) 
 OR 
	 ( TMP.LastNameOperator = 3 AND T.LastName <> TMP.LastNameValue ) 
 OR 
	 ( TMP.LastNameOperator = 4 AND T.LastName LIKE TMP.LastNameValue + '%') 
 OR 
	 ( TMP.LastNameOperator = 5 AND T.LastName LIKE '%' + TMP.LastNameValue ) 
 OR 
	 ( TMP.LastNameOperator = 6 AND T.LastName LIKE '%' + TMP.LastNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.FirstNameOperator = -1 ) 
 OR 
	 ( TMP.FirstNameOperator = 0 AND T.FirstName IS NULL ) 
 OR 
	 ( TMP.FirstNameOperator = 1 AND T.FirstName IS NOT NULL ) 
 OR 
	 ( TMP.FirstNameOperator = 2 AND T.FirstName = TMP.FirstNameValue ) 
 OR 
	 ( TMP.FirstNameOperator = 3 AND T.FirstName <> TMP.FirstNameValue ) 
 OR 
	 ( TMP.FirstNameOperator = 4 AND T.FirstName LIKE TMP.FirstNameValue + '%') 
 OR 
	 ( TMP.FirstNameOperator = 5 AND T.FirstName LIKE '%' + TMP.FirstNameValue ) 
 OR 
	 ( TMP.FirstNameOperator = 6 AND T.FirstName LIKE '%' + TMP.FirstNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.MiddlenameOperator = -1 ) 
 OR 
	 ( TMP.MiddlenameOperator = 0 AND T.Middlename IS NULL ) 
 OR 
	 ( TMP.MiddlenameOperator = 1 AND T.Middlename IS NOT NULL ) 
 OR 
	 ( TMP.MiddlenameOperator = 2 AND T.Middlename = TMP.MiddlenameValue ) 
 OR 
	 ( TMP.MiddlenameOperator = 3 AND T.Middlename <> TMP.MiddlenameValue ) 
 OR 
	 ( TMP.MiddlenameOperator = 4 AND T.Middlename LIKE TMP.MiddlenameValue + '%') 
 OR 
	 ( TMP.MiddlenameOperator = 5 AND T.Middlename LIKE '%' + TMP.MiddlenameValue ) 
 OR 
	 ( TMP.MiddlenameOperator = 6 AND T.Middlename LIKE '%' + TMP.MiddlenameValue + '%' ) 
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
	 ( TMP.CityStateZipOperator = -1 ) 
 OR 
	 ( TMP.CityStateZipOperator = 0 AND T.CityStateZip IS NULL ) 
 OR 
	 ( TMP.CityStateZipOperator = 1 AND T.CityStateZip IS NOT NULL ) 
 OR 
	 ( TMP.CityStateZipOperator = 2 AND T.CityStateZip = TMP.CityStateZipValue ) 
 OR 
	 ( TMP.CityStateZipOperator = 3 AND T.CityStateZip <> TMP.CityStateZipValue ) 
 OR 
	 ( TMP.CityStateZipOperator = 4 AND T.CityStateZip LIKE TMP.CityStateZipValue + '%') 
 OR 
	 ( TMP.CityStateZipOperator = 5 AND T.CityStateZip LIKE '%' + TMP.CityStateZipValue ) 
 OR 
	 ( TMP.CityStateZipOperator = 6 AND T.CityStateZip LIKE '%' + TMP.CityStateZipValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PhoneNumberOperator = -1 ) 
 OR 
	 ( TMP.PhoneNumberOperator = 0 AND T.PhoneNumber IS NULL ) 
 OR 
	 ( TMP.PhoneNumberOperator = 1 AND T.PhoneNumber IS NOT NULL ) 
 OR 
	 ( TMP.PhoneNumberOperator = 2 AND T.PhoneNumber = TMP.PhoneNumberValue ) 
 OR 
	 ( TMP.PhoneNumberOperator = 3 AND T.PhoneNumber <> TMP.PhoneNumberValue ) 
 OR 
	 ( TMP.PhoneNumberOperator = 4 AND T.PhoneNumber LIKE TMP.PhoneNumberValue + '%') 
 OR 
	 ( TMP.PhoneNumberOperator = 5 AND T.PhoneNumber LIKE '%' + TMP.PhoneNumberValue ) 
 OR 
	 ( TMP.PhoneNumberOperator = 6 AND T.PhoneNumber LIKE '%' + TMP.PhoneNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.EffectiveDateOperator = -1 ) 
 OR 
	 ( TMP.EffectiveDateOperator = 0 AND T.EffectiveDate IS NULL ) 
 OR 
	 ( TMP.EffectiveDateOperator = 1 AND T.EffectiveDate IS NOT NULL ) 
 OR 
	 ( TMP.EffectiveDateOperator = 2 AND T.EffectiveDate = TMP.EffectiveDateValue ) 
 OR 
	 ( TMP.EffectiveDateOperator = 3 AND T.EffectiveDate <> TMP.EffectiveDateValue ) 
 OR 
	 ( TMP.EffectiveDateOperator = 7 AND T.EffectiveDate > TMP.EffectiveDateValue ) 
 OR 
	 ( TMP.EffectiveDateOperator = 8 AND T.EffectiveDate >= TMP.EffectiveDateValue ) 
 OR 
	 ( TMP.EffectiveDateOperator = 9 AND T.EffectiveDate < TMP.EffectiveDateValue ) 
 OR 
	 ( TMP.EffectiveDateOperator = 10 AND T.EffectiveDate <= TMP.EffectiveDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ExpirationDateOperator = -1 ) 
 OR 
	 ( TMP.ExpirationDateOperator = 0 AND T.ExpirationDate IS NULL ) 
 OR 
	 ( TMP.ExpirationDateOperator = 1 AND T.ExpirationDate IS NOT NULL ) 
 OR 
	 ( TMP.ExpirationDateOperator = 2 AND T.ExpirationDate = TMP.ExpirationDateValue ) 
 OR 
	 ( TMP.ExpirationDateOperator = 3 AND T.ExpirationDate <> TMP.ExpirationDateValue ) 
 OR 
	 ( TMP.ExpirationDateOperator = 7 AND T.ExpirationDate > TMP.ExpirationDateValue ) 
 OR 
	 ( TMP.ExpirationDateOperator = 8 AND T.ExpirationDate >= TMP.ExpirationDateValue ) 
 OR 
	 ( TMP.ExpirationDateOperator = 9 AND T.ExpirationDate < TMP.ExpirationDateValue ) 
 OR 
	 ( TMP.ExpirationDateOperator = 10 AND T.ExpirationDate <= TMP.ExpirationDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.RequestCountOperator = -1 ) 
 OR 
	 ( TMP.RequestCountOperator = 0 AND T.RequestCount IS NULL ) 
 OR 
	 ( TMP.RequestCountOperator = 1 AND T.RequestCount IS NOT NULL ) 
 OR 
	 ( TMP.RequestCountOperator = 2 AND T.RequestCount = TMP.RequestCountValue ) 
 OR 
	 ( TMP.RequestCountOperator = 3 AND T.RequestCount <> TMP.RequestCountValue ) 
 OR 
	 ( TMP.RequestCountOperator = 7 AND T.RequestCount > TMP.RequestCountValue ) 
 OR 
	 ( TMP.RequestCountOperator = 8 AND T.RequestCount >= TMP.RequestCountValue ) 
 OR 
	 ( TMP.RequestCountOperator = 9 AND T.RequestCount < TMP.RequestCountValue ) 
 OR 
	 ( TMP.RequestCountOperator = 10 AND T.RequestCount <= TMP.RequestCountValue ) 

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
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'MembershipNumber' AND @sortOrder = 'ASC'
	 THEN T.MembershipNumber END ASC, 
	 CASE WHEN @sortColumn = 'MembershipNumber' AND @sortOrder = 'DESC'
	 THEN T.MembershipNumber END DESC ,

	 CASE WHEN @sortColumn = 'LastName' AND @sortOrder = 'ASC'
	 THEN T.LastName END ASC, 
	 CASE WHEN @sortColumn = 'LastName' AND @sortOrder = 'DESC'
	 THEN T.LastName END DESC ,

	 CASE WHEN @sortColumn = 'FirstName' AND @sortOrder = 'ASC'
	 THEN T.FirstName END ASC, 
	 CASE WHEN @sortColumn = 'FirstName' AND @sortOrder = 'DESC'
	 THEN T.FirstName END DESC ,

	 CASE WHEN @sortColumn = 'Middlename' AND @sortOrder = 'ASC'
	 THEN T.Middlename END ASC, 
	 CASE WHEN @sortColumn = 'Middlename' AND @sortOrder = 'DESC'
	 THEN T.Middlename END DESC ,

	 CASE WHEN @sortColumn = 'StateProvince' AND @sortOrder = 'ASC'
	 THEN T.StateProvince END ASC, 
	 CASE WHEN @sortColumn = 'StateProvince' AND @sortOrder = 'DESC'
	 THEN T.StateProvince END DESC ,

	 CASE WHEN @sortColumn = 'CityStateZip' AND @sortOrder = 'ASC'
	 THEN T.CityStateZip END ASC, 
	 CASE WHEN @sortColumn = 'CityStateZip' AND @sortOrder = 'DESC'
	 THEN T.CityStateZip END DESC ,

	 CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'
	 THEN T.PhoneNumber END ASC, 
	 CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'
	 THEN T.PhoneNumber END DESC ,

	 CASE WHEN @sortColumn = 'EffectiveDate' AND @sortOrder = 'ASC'
	 THEN T.EffectiveDate END ASC, 
	 CASE WHEN @sortColumn = 'EffectiveDate' AND @sortOrder = 'DESC'
	 THEN T.EffectiveDate END DESC ,

	 CASE WHEN @sortColumn = 'ExpirationDate' AND @sortOrder = 'ASC'
	 THEN T.ExpirationDate END ASC, 
	 CASE WHEN @sortColumn = 'ExpirationDate' AND @sortOrder = 'DESC'
	 THEN T.ExpirationDate END DESC ,

	 CASE WHEN @sortColumn = 'RequestCount' AND @sortOrder = 'ASC'
	 THEN T.RequestCount END ASC, 
	 CASE WHEN @sortColumn = 'RequestCount' AND @sortOrder = 'DESC'
	 THEN T.RequestCount END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC 


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
