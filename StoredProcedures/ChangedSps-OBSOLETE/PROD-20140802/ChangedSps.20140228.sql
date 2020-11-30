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
 WHERE id = object_id(N'[dbo].[dms_StartCall_MemberSelections]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_StartCall_MemberSelections] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_StartCall_MemberSelections]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @memberIDCommaSeprated nvarchar(MAX) = NULL
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
MemberIDOperator="-1" 
MembershipIDOperator="-1" 
MembershipNumberOperator="-1" 
MemberNameOperator="-1" 
AddressOperator="-1" 
PhoneNumberOperator="-1" 
ProgramIDOperator="-1" 
ProgramOperator="-1" 
VINOperator="-1" 
MemberStatusOperator="-1" 
POCountOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
MemberIDOperator INT NOT NULL,
MemberIDValue int NULL,
MembershipIDOperator INT NOT NULL,
MembershipIDValue int NULL,
MembershipNumberOperator INT NOT NULL,
MembershipNumberValue nvarchar(100) NULL,
MemberNameOperator INT NOT NULL,
MemberNameValue nvarchar(100) NULL,
AddressOperator INT NOT NULL,
AddressValue nvarchar(100) NULL,
PhoneNumberOperator INT NOT NULL,
PhoneNumberValue nvarchar(100) NULL,
ProgramIDOperator INT NOT NULL,
ProgramIDValue int NULL,
ProgramOperator INT NOT NULL,
ProgramValue nvarchar(100) NULL,
VINOperator INT NOT NULL,
VINValue nvarchar(100) NULL,
MemberStatusOperator INT NOT NULL,
MemberStatusValue nvarchar(100) NULL,
POCountOperator INT NOT NULL,
POCountValue int NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
		MemberID int  NULL ,
		MembershipID int  NULL ,
		MembershipNumber nvarchar(200)  NULL ,
		MemberName NVARCHAR(MAX)  NULL ,
		Address NVARCHAR(MAX)  NULL ,
		PhoneNumber NVARCHAR(MAX)  NULL ,
		ProgramID INT NULL ,
		Program nvarchar(200) NULL,
		VIN nvarchar(200) NULL,
		MemberStatus nvarchar(200) NULL,
		POCount INT NULL
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@MemberIDOperator','INT'),-1),
	T.c.value('@MemberIDValue','int') ,
	ISNULL(T.c.value('@MembershipIDOperator','INT'),-1),
	T.c.value('@MembershipIDValue','int') ,
	ISNULL(T.c.value('@MembershipNumberOperator','INT'),-1),
	T.c.value('@MembershipNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@MemberNameOperator','INT'),-1),
	T.c.value('@MemberNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@AddressOperator','INT'),-1),
	T.c.value('@AddressValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PhoneNumberOperator','INT'),-1),
	T.c.value('@PhoneNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProgramIDOperator','INT'),-1),
	T.c.value('@ProgramIDValue','int') ,
	ISNULL(T.c.value('@ProgramOperator','INT'),-1),
	T.c.value('@ProgramValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VINOperator','INT'),-1),
	T.c.value('@VINValue','nvarchar(100)') ,
	ISNULL(T.c.value('@MemberStatusOperator','INT'),-1),
	T.c.value('@MemberStatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@POCountOperator','INT'),-1),
	T.c.value('@POCountValue','int') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
 DECLARE @QueryResult AS TABLE( 
		MemberID int  NULL ,
		MembershipID int  NULL ,
		MembershipNumber nvarchar(200)  NULL ,
		MemberName NVARCHAR(MAX)  NULL ,
		Address NVARCHAR(MAX)  NULL ,
		PhoneNumber NVARCHAR(MAX)  NULL ,
		ProgramID INT NULL ,
		Program nvarchar(200) NULL,
		VIN nvarchar(200) NULL,
		MemberStatus nvarchar(200) NULL,
		POCount INT NULL		
)


-- Dates used while calculating member status
DECLARE @now DATETIME, @minDate DATETIME
SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
SET @minDate = '1900-01-01'     

DECLARE @MemberIDValues AS TABLE(MemberID INT NULL)
INSERT INTO @MemberIDValues SELECT item from dbo.fnSplitString(@memberIDCommaSeprated,',')

DECLARE @memberEntityID INT  
SELECT  @memberEntityID = ID FROM Entity WHERE Name = 'Member' 

SELECT * INTO #tmpPhone  
		 FROM PhoneEntity PH WITH (NOLOCK)  
		 WHERE PH.EntityID = @memberEntityID   
		 AND  PH.RecordID IN (SELECT MemberID FROM @MemberIDValues)

INSERT INTO @QueryResult
SELECT DISTINCT    	  M.ID AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber
					,REPLACE(RTRIM( COALESCE(M.FirstName, '') + 
									COALESCE(' ' + left(M.MiddleName,1), '') + 
									COALESCE(' ' + M.LastName, '') +
									COALESCE(' ' + M.Suffix, '')), ' ', ' ') 
									AS MemberName
					,(ISNULL(A.City,'') + ',' + ISNULL(A.StateProvince,'') + ' ' + ISNULL(A.PostalCode,'')) AS [Address]  
					, COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber 
					, P.ID As ProgramID  -- KB: ADDED IDS
					, P.[Description] AS Program    
					, '' AS VIN
					, CASE WHEN ISNULL(M.EffectiveDate,@minDate) <= @now AND ISNULL(M.ExpirationDate,@minDate) >= @now
					  THEN 'Active' ELSE 'Inactive' END AS MemberStatus
					,(SELECT COUNT(*) FROM [Case] WITH (NOLOCK) WHERE MemberID = M.ID) AS POCount
			FROM Member M
			LEFT JOIN Membership MS WITH (NOLOCK) ON  M.MembershipID = MS.ID
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID AND A.RecordID IN (SELECT MemberID FROM @MemberIDValues) 
			LEFT JOIN #tmpPhone PH WITH (NOLOCK) ON PH.RecordID = M.ID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID 
			LEFT JOIN #tmpPhone PW WITH (NOLOCK) ON PW.RecordID = M.ID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID 
			LEFT JOIN #tmpPhone PC WITH (NOLOCK) ON PC.RecordID = M.ID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID 
			JOIN Program P WITH (NOLOCK) ON P.ID = M.ProgramID
			WHERE M.ID IN (SELECT MemberID FROM @MemberIDValues)

DROP TABLE #tmpPhone


INSERT INTO #FinalResults
SELECT 
	T.MemberID,
	T.MembershipID,
	T.MembershipNumber,
	T.MemberName,
	T.Address,
	T.PhoneNumber,
	T.ProgramID,
	T.Program,
	T.VIN,
	T.MemberStatus,
	T.POCount
FROM @QueryResult T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.MemberIDOperator = -1 ) 
 OR 
	 ( TMP.MemberIDOperator = 0 AND T.MemberID IS NULL ) 
 OR 
	 ( TMP.MemberIDOperator = 1 AND T.MemberID IS NOT NULL ) 
 OR 
	 ( TMP.MemberIDOperator = 2 AND T.MemberID = TMP.MemberIDValue ) 
 OR 
	 ( TMP.MemberIDOperator = 3 AND T.MemberID <> TMP.MemberIDValue ) 
 OR 
	 ( TMP.MemberIDOperator = 7 AND T.MemberID > TMP.MemberIDValue ) 
 OR 
	 ( TMP.MemberIDOperator = 8 AND T.MemberID >= TMP.MemberIDValue ) 
 OR 
	 ( TMP.MemberIDOperator = 9 AND T.MemberID < TMP.MemberIDValue ) 
 OR 
	 ( TMP.MemberIDOperator = 10 AND T.MemberID <= TMP.MemberIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.MembershipIDOperator = -1 ) 
 OR 
	 ( TMP.MembershipIDOperator = 0 AND T.MembershipID IS NULL ) 
 OR 
	 ( TMP.MembershipIDOperator = 1 AND T.MembershipID IS NOT NULL ) 
 OR 
	 ( TMP.MembershipIDOperator = 2 AND T.MembershipID = TMP.MembershipIDValue ) 
 OR 
	 ( TMP.MembershipIDOperator = 3 AND T.MembershipID <> TMP.MembershipIDValue ) 
 OR 
	 ( TMP.MembershipIDOperator = 7 AND T.MembershipID > TMP.MembershipIDValue ) 
 OR 
	 ( TMP.MembershipIDOperator = 8 AND T.MembershipID >= TMP.MembershipIDValue ) 
 OR 
	 ( TMP.MembershipIDOperator = 9 AND T.MembershipID < TMP.MembershipIDValue ) 
 OR 
	 ( TMP.MembershipIDOperator = 10 AND T.MembershipID <= TMP.MembershipIDValue ) 

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
	 ( TMP.MemberNameOperator = -1 ) 
 OR 
	 ( TMP.MemberNameOperator = 0 AND T.MemberName IS NULL ) 
 OR 
	 ( TMP.MemberNameOperator = 1 AND T.MemberName IS NOT NULL ) 
 OR 
	 ( TMP.MemberNameOperator = 2 AND T.MemberName = TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 3 AND T.MemberName <> TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 4 AND T.MemberName LIKE TMP.MemberNameValue + '%') 
 OR 
	 ( TMP.MemberNameOperator = 5 AND T.MemberName LIKE '%' + TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 6 AND T.MemberName LIKE '%' + TMP.MemberNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.AddressOperator = -1 ) 
 OR 
	 ( TMP.AddressOperator = 0 AND T.Address IS NULL ) 
 OR 
	 ( TMP.AddressOperator = 1 AND T.Address IS NOT NULL ) 
 OR 
	 ( TMP.AddressOperator = 2 AND T.Address = TMP.AddressValue ) 
 OR 
	 ( TMP.AddressOperator = 3 AND T.Address <> TMP.AddressValue ) 
 OR 
	 ( TMP.AddressOperator = 4 AND T.Address LIKE TMP.AddressValue + '%') 
 OR 
	 ( TMP.AddressOperator = 5 AND T.Address LIKE '%' + TMP.AddressValue ) 
 OR 
	 ( TMP.AddressOperator = 6 AND T.Address LIKE '%' + TMP.AddressValue + '%' ) 
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
	 ( TMP.ProgramIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramIDOperator = 0 AND T.ProgramID IS NULL ) 
 OR 
	 ( TMP.ProgramIDOperator = 1 AND T.ProgramID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramIDOperator = 2 AND T.ProgramID = TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 3 AND T.ProgramID <> TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 7 AND T.ProgramID > TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 8 AND T.ProgramID >= TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 9 AND T.ProgramID < TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 10 AND T.ProgramID <= TMP.ProgramIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ProgramOperator = -1 ) 
 OR 
	 ( TMP.ProgramOperator = 0 AND T.Program IS NULL ) 
 OR 
	 ( TMP.ProgramOperator = 1 AND T.Program IS NOT NULL ) 
 OR 
	 ( TMP.ProgramOperator = 2 AND T.Program = TMP.ProgramValue ) 
 OR 
	 ( TMP.ProgramOperator = 3 AND T.Program <> TMP.ProgramValue ) 
 OR 
	 ( TMP.ProgramOperator = 4 AND T.Program LIKE TMP.ProgramValue + '%') 
 OR 
	 ( TMP.ProgramOperator = 5 AND T.Program LIKE '%' + TMP.ProgramValue ) 
 OR 
	 ( TMP.ProgramOperator = 6 AND T.Program LIKE '%' + TMP.ProgramValue + '%' ) 
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

 ( 
	 ( TMP.MemberStatusOperator = -1 ) 
 OR 
	 ( TMP.MemberStatusOperator = 0 AND T.MemberStatus IS NULL ) 
 OR 
	 ( TMP.MemberStatusOperator = 1 AND T.MemberStatus IS NOT NULL ) 
 OR 
	 ( TMP.MemberStatusOperator = 2 AND T.MemberStatus = TMP.MemberStatusValue ) 
 OR 
	 ( TMP.MemberStatusOperator = 3 AND T.MemberStatus <> TMP.MemberStatusValue ) 
 OR 
	 ( TMP.MemberStatusOperator = 4 AND T.MemberStatus LIKE TMP.MemberStatusValue + '%') 
 OR 
	 ( TMP.MemberStatusOperator = 5 AND T.MemberStatus LIKE '%' + TMP.MemberStatusValue ) 
 OR 
	 ( TMP.MemberStatusOperator = 6 AND T.MemberStatus LIKE '%' + TMP.MemberStatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.POCountOperator = -1 ) 
 OR 
	 ( TMP.POCountOperator = 0 AND T.POCount IS NULL ) 
 OR 
	 ( TMP.POCountOperator = 1 AND T.POCount IS NOT NULL ) 
 OR 
	 ( TMP.POCountOperator = 2 AND T.POCount = TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 3 AND T.POCount <> TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 7 AND T.POCount > TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 8 AND T.POCount >= TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 9 AND T.POCount < TMP.POCountValue ) 
 OR 
	 ( TMP.POCountOperator = 10 AND T.POCount <= TMP.POCountValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'
	 THEN T.MemberID END ASC, 
	 CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'
	 THEN T.MemberID END DESC ,

	 CASE WHEN @sortColumn = 'MembershipID' AND @sortOrder = 'ASC'
	 THEN T.MembershipID END ASC, 
	 CASE WHEN @sortColumn = 'MembershipID' AND @sortOrder = 'DESC'
	 THEN T.MembershipID END DESC ,

	 CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'
	 THEN T.MembershipNumber END ASC, 
	 CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'
	 THEN T.MembershipNumber END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.MemberName END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.MemberName END DESC ,

	 CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'
	 THEN T.Address END ASC, 
	 CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'
	 THEN T.Address END DESC ,

	 CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'
	 THEN T.PhoneNumber END ASC, 
	 CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'
	 THEN T.PhoneNumber END DESC ,

	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'ASC'
	 THEN T.ProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'DESC'
	 THEN T.ProgramID END DESC ,

	 CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'
	 THEN T.Program END ASC, 
	 CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'
	 THEN T.Program END DESC ,

	 CASE WHEN @sortColumn = 'VIN' AND @sortOrder = 'ASC'
	 THEN T.VIN END ASC, 
	 CASE WHEN @sortColumn = 'VIN' AND @sortOrder = 'DESC'
	 THEN T.VIN END DESC ,

	 CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'ASC'
	 THEN T.MemberStatus END ASC, 
	 CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'DESC'
	 THEN T.MemberStatus END DESC ,

	 CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'
	 THEN T.POCount END ASC, 
	 CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'
	 THEN T.POCount END DESC 


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
