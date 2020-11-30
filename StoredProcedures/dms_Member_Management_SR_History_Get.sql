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
 WHERE id = object_id(N'[dbo].[dms_Member_Management_SR_History_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_Management_SR_History_Get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_Member_Mangement_SR_History_Get @MemberID=3
 CREATE PROCEDURE [dbo].[dms_Member_Management_SR_History_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @MemberID INT = NULL 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
RequestNumberOperator="-1" 
RequestDateOperator="-1" 
MemberNameOperator="-1" 
ServiceTypeOperator="-1" 
StatusOperator="-1" 
VehicleOperator="-1" 
POCountOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
RequestNumberOperator INT NOT NULL,
RequestNumberValue int NULL,
RequestDateOperator INT NOT NULL,
RequestDateValue datetime NULL,
MemberNameOperator INT NOT NULL,
MemberNameValue nvarchar(100) NULL,
ServiceTypeOperator INT NOT NULL,
ServiceTypeValue nvarchar(100) NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL,
VehicleOperator INT NOT NULL,
VehicleValue nvarchar(100) NULL,
POCountOperator INT NOT NULL,
POCountValue int NULL
)
 DECLARE @FinalResults AS TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	RequestNumber int  NULL ,
	RequestDate datetime  NULL ,
	MemberName nvarchar(100)  NULL ,
	ServiceType nvarchar(100)  NULL ,
	Status nvarchar(100)  NULL ,
	Vehicle nvarchar(100)  NULL ,
	POCount int  NULL 
) 
DECLARE @FinalResults_Temp AS TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	RequestNumber int  NULL ,
	RequestDate datetime  NULL ,
	MemberName nvarchar(100)  NULL ,
	ServiceType nvarchar(100)  NULL ,
	Status nvarchar(100)  NULL ,
	Vehicle nvarchar(100)  NULL ,
	POCount int  NULL 
)

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@RequestNumberOperator','INT'),-1),
	T.c.value('@RequestNumberValue','int') ,
	ISNULL(T.c.value('@RequestDateOperator','INT'),-1),
	T.c.value('@RequestDateValue','datetime') ,
	ISNULL(T.c.value('@MemberNameOperator','INT'),-1),
	T.c.value('@MemberNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ServiceTypeOperator','INT'),-1),
	T.c.value('@ServiceTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleOperator','INT'),-1),
	T.c.value('@VehicleValue','nvarchar(100)') ,
	ISNULL(T.c.value('@POCountOperator','INT'),-1),
	T.c.value('@POCountValue','int') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

INSERT INTO @FinalResults_Temp

SELECT SR.ID AS RequestNumber
	, CONVERT(VARCHAR(10),SR.CreateDate,101) AS RequestDate
	, REPLACE(RTRIM(
		COALESCE(M.Firstname, '')+
		COALESCE(' ' + M.MiddleName, '')+
		COALESCE(' ' + M.LastName, '')+
		COALESCE(' ' + M.Suffix, '')
	  ),'','') AS MemberName
	, PC.Name AS ServiceType
	, SRS.Name AS Status
	, REPLACE(RTRIM(
		COALESCE(C.VehicleYear, '')+
		COALESCE(' ' + CASE WHEN C.VehicleMake = 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END, '')+
		COALESCE(' ' + CASE WHEN C.VehicleModel = 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END, '')
	  ),'','') AS Vehicle
	, (SELECT COUNT(*) FROM PurchaseOrder WHERE IsActive = 1 AND ServiceRequestID = SR.ID) AS POCount
FROM ServiceRequest SR
JOIN [Case] C ON C.ID = SR.CaseID
JOIN Member M ON M.ID = C.MemberID
LEFT JOIN Product P ON P.ID = SR.PrimaryProductID
LEFT JOIN ProductCategory PC ON PC.ID = P.ProductCategoryID
JOIN ServiceRequestStatus SRS ON SRS.ID = SR.ServiceRequestStatusID
WHERE M.ID = @MemberID
ORDER BY SR.ID DESC
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults
SELECT 
	T.RequestNumber,
	T.RequestDate,
	T.MemberName,
	T.ServiceType,
	T.Status,
	T.Vehicle,
	T.POCount
FROM @FinalResults_Temp T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.RequestNumberOperator = -1 ) 
 OR 
	 ( TMP.RequestNumberOperator = 0 AND T.RequestNumber IS NULL ) 
 OR 
	 ( TMP.RequestNumberOperator = 1 AND T.RequestNumber IS NOT NULL ) 
 OR 
	 ( TMP.RequestNumberOperator = 2 AND T.RequestNumber = TMP.RequestNumberValue ) 
 OR 
	 ( TMP.RequestNumberOperator = 3 AND T.RequestNumber <> TMP.RequestNumberValue ) 
 OR 
	 ( TMP.RequestNumberOperator = 7 AND T.RequestNumber > TMP.RequestNumberValue ) 
 OR 
	 ( TMP.RequestNumberOperator = 8 AND T.RequestNumber >= TMP.RequestNumberValue ) 
 OR 
	 ( TMP.RequestNumberOperator = 9 AND T.RequestNumber < TMP.RequestNumberValue ) 
 OR 
	 ( TMP.RequestNumberOperator = 10 AND T.RequestNumber <= TMP.RequestNumberValue ) 

 ) 

 AND 

 ( 
	 ( TMP.RequestDateOperator = -1 ) 
 OR 
	 ( TMP.RequestDateOperator = 0 AND T.RequestDate IS NULL ) 
 OR 
	 ( TMP.RequestDateOperator = 1 AND T.RequestDate IS NOT NULL ) 
 OR 
	 ( TMP.RequestDateOperator = 2 AND T.RequestDate = TMP.RequestDateValue ) 
 OR 
	 ( TMP.RequestDateOperator = 3 AND T.RequestDate <> TMP.RequestDateValue ) 
 OR 
	 ( TMP.RequestDateOperator = 7 AND T.RequestDate > TMP.RequestDateValue ) 
 OR 
	 ( TMP.RequestDateOperator = 8 AND T.RequestDate >= TMP.RequestDateValue ) 
 OR 
	 ( TMP.RequestDateOperator = 9 AND T.RequestDate < TMP.RequestDateValue ) 
 OR 
	 ( TMP.RequestDateOperator = 10 AND T.RequestDate <= TMP.RequestDateValue ) 

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
	 ( TMP.ServiceTypeOperator = -1 ) 
 OR 
	 ( TMP.ServiceTypeOperator = 0 AND T.ServiceType IS NULL ) 
 OR 
	 ( TMP.ServiceTypeOperator = 1 AND T.ServiceType IS NOT NULL ) 
 OR 
	 ( TMP.ServiceTypeOperator = 2 AND T.ServiceType = TMP.ServiceTypeValue ) 
 OR 
	 ( TMP.ServiceTypeOperator = 3 AND T.ServiceType <> TMP.ServiceTypeValue ) 
 OR 
	 ( TMP.ServiceTypeOperator = 4 AND T.ServiceType LIKE TMP.ServiceTypeValue + '%') 
 OR 
	 ( TMP.ServiceTypeOperator = 5 AND T.ServiceType LIKE '%' + TMP.ServiceTypeValue ) 
 OR 
	 ( TMP.ServiceTypeOperator = 6 AND T.ServiceType LIKE '%' + TMP.ServiceTypeValue + '%' ) 
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
	 ( TMP.VehicleOperator = -1 ) 
 OR 
	 ( TMP.VehicleOperator = 0 AND T.Vehicle IS NULL ) 
 OR 
	 ( TMP.VehicleOperator = 1 AND T.Vehicle IS NOT NULL ) 
 OR 
	 ( TMP.VehicleOperator = 2 AND T.Vehicle = TMP.VehicleValue ) 
 OR 
	 ( TMP.VehicleOperator = 3 AND T.Vehicle <> TMP.VehicleValue ) 
 OR 
	 ( TMP.VehicleOperator = 4 AND T.Vehicle LIKE TMP.VehicleValue + '%') 
 OR 
	 ( TMP.VehicleOperator = 5 AND T.Vehicle LIKE '%' + TMP.VehicleValue ) 
 OR 
	 ( TMP.VehicleOperator = 6 AND T.Vehicle LIKE '%' + TMP.VehicleValue + '%' ) 
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
	 CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'ASC'
	 THEN T.RequestNumber END ASC, 
	 CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'DESC'
	 THEN T.RequestNumber END DESC ,

	 CASE WHEN @sortColumn = 'RequestDate' AND @sortOrder = 'ASC'
	 THEN T.RequestDate END ASC, 
	 CASE WHEN @sortColumn = 'RequestDate' AND @sortOrder = 'DESC'
	 THEN T.RequestDate END DESC ,

	 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'
	 THEN T.MemberName END ASC, 
	 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'
	 THEN T.MemberName END DESC ,

	 CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'ASC'
	 THEN T.ServiceType END ASC, 
	 CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'DESC'
	 THEN T.ServiceType END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC ,

	 CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'ASC'
	 THEN T.Vehicle END ASC, 
	 CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'DESC'
	 THEN T.Vehicle END DESC ,

	 CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'
	 THEN T.POCount END ASC, 
	 CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'
	 THEN T.POCount END DESC 


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
