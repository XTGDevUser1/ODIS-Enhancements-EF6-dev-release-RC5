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
 WHERE id = object_id(N'[dbo].[dms_Duplicate_Vendors_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Duplicate_Vendors_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXCE dms_Duplicate_Vendors_Get @vendorID=338
 --EXEC [dbo].[dms_Duplicate_Vendors_Get] @vendorID=338  
 CREATE PROCEDURE [dbo].[dms_Duplicate_Vendors_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @vendorID INT = NULL 	
 
 ) 
 AS 
 BEGIN 
 DECLARE
	@ID INT = NULL
 , @Address1 NVARCHAR(100) = NULL
 , @City NVARCHAR(100) = NULL
 , @OfficePhone NVARCHAR(100) = NULL
 , @DispatchPhone NVARCHAR(100) = NULL
 , @FaxPhone NVARCHAR (100) = NULL  
 , @VendorName NVARCHAR(100) = NULL
	SET FMTONLY OFF;
 	SET NOCOUNT ON
 
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
VendorLocationIDOperator="-1" 
SequenceOperator="-1" 
NameOperator="-1" 
VendorStatusOperator="-1" 
ContractStautsOperator="-1" 
Address1Operator="-1" 
StateCountryCityZipOperator="-1" 
DisptchTypeOperator="-1" 
DispatchNumberOperator="-1" 
OfficeTypeOperator="-1" 
OfficeNumberOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
VendorLocationIDOperator INT NOT NULL,
VendorLocationIDValue int NULL,
SequenceOperator INT NOT NULL,
SequenceValue int NULL,
NameOperator INT NOT NULL,
NameValue nvarchar(100) NULL,
VendorStatusOperator INT NOT NULL,
VendorStatusValue nvarchar(100) NULL,
ContractStautsOperator INT NOT NULL,
ContractStautsValue nvarchar(100) NULL,
Address1Operator INT NOT NULL,
Address1Value nvarchar(100) NULL,
StateCountryCityZipOperator INT NOT NULL,
StateCountryCityZipValue nvarchar(100) NULL,
DisptchTypeOperator INT NOT NULL,
DisptchTypeValue int NULL,
DispatchNumberOperator INT NOT NULL,
DispatchNumberValue nvarchar(100) NULL,
OfficeTypeOperator INT NOT NULL,
OfficeTypeValue int NULL,
OfficeNumberOperator INT NOT NULL,
OfficeNumberValue nvarchar(100) NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	VendorLocationID int  NULL ,
	Sequence int  NULL ,
	VendorNumber nvarchar(100)  NULL ,
	Name nvarchar(255)  NULL ,
	VendorStatus nvarchar(100)  NULL ,
	ContractStauts nvarchar(100)  NULL ,
	Address1 nvarchar(100)  NULL ,
	StateCountryCityZip nvarchar(100)  NULL ,
	DisptchType int  NULL ,
	DispatchNumber nvarchar(100)  NULL ,
	OfficeType int  NULL ,
	OfficeNumber nvarchar(100)  NULL 
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	VendorLocationID int  NULL ,
	Sequence int  NULL ,
	VendorNumber nvarchar(100)  NULL ,
	Name nvarchar(255)  NULL ,
	VendorStatus nvarchar(100)  NULL ,
	ContractStauts nvarchar(100)  NULL ,
	Address1 nvarchar(100)  NULL ,
	StateCountryCityZip nvarchar(100)  NULL ,
	DisptchType int  NULL ,
	DispatchNumber nvarchar(100)  NULL ,
	OfficeType int  NULL ,
	OfficeNumber nvarchar(100)  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@VendorLocationIDOperator','INT'),-1),
	T.c.value('@VendorLocationIDValue','int') ,
	ISNULL(T.c.value('@SequenceOperator','INT'),-1),
	T.c.value('@SequenceValue','int') ,
	ISNULL(T.c.value('@NameOperator','INT'),-1),
	T.c.value('@NameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VendorStatusOperator','INT'),-1),
	T.c.value('@VendorStatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ContractStautsOperator','INT'),-1),
	T.c.value('@ContractStautsValue','nvarchar(100)') ,
	ISNULL(T.c.value('@Address1Operator','INT'),-1),
	T.c.value('@Address1Value','nvarchar(100)') ,
	ISNULL(T.c.value('@StateCountryCityZipOperator','INT'),-1),
	T.c.value('@StateCountryCityZipValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DisptchTypeOperator','INT'),-1),
	T.c.value('@DisptchTypeValue','int') ,
	ISNULL(T.c.value('@DispatchNumberOperator','INT'),-1),
	T.c.value('@DispatchNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@OfficeTypeOperator','INT'),-1),
	T.c.value('@OfficeTypeValue','int') ,
	ISNULL(T.c.value('@OfficeNumberOperator','INT'),-1),
	T.c.value('@OfficeNumberValue','nvarchar(100)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------


SELECT 
 @ID = v.ID,
 @Address1 = ae.Line1 ,
 @City = ae.City,
 @OfficePhone = peOfc.PhoneNumber,
 @DispatchPhone = pe24.PhoneNumber,
 @FaxPhone = peFax.PhoneNumber
 FROM VendorLocation vl    
INNER JOIN Vendor v on v.ID = vl.VendorID    
LEFT OUTER JOIN AddressEntity ae on ae.RecordID = vl.ID and ae.EntityID = (Select ID From Entity Where Name = 'VendorLocation')     
LEFT OUTER JOIN PhoneEntity pe24 on pe24.RecordID = vl.ID and pe24.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and pe24.PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')    
Left Outer Join PhoneEntity peFax on peFax.RecordID = vl.ID and peFax.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and peFax.PhoneTypeID = (Select ID From PhoneType Where Name = 'Fax')    
LEFT OUTER JOIN PhoneEntity peOfc on peOfc.RecordID = v.ID and peOfc.EntityID = (Select ID From Entity Where Name = 'Vendor') and peOfc.PhoneTypeID = (Select ID From PhoneType Where Name = 'Office')    
LEFT OUTER JOIN [Contract] c on c.VendorID = v.ID and c.IsActive = 1    
 Where v.ID=@vendorID
 
INSERT INTO #tmpFinalResults
SELECT DISTINCT     
  v.ID    
 ,vl.ID  AS VendorLocationID   
 ,vl.Sequence    
 ,v.VendorNumber     
 ,v.Name     
 ,CASE --WHEN v.IsDoNotUse = 1 THEN 'Do Not Use'    
  WHEN v.IsActive = 0 THEN 'Inactive'    
  ELSE 'Active'    
  END  AS VendorStatus
 ,CASE     
  WHEN c.ID IS NOT NULL THEN 'Contracted'     
  ELSE 'Not Contracted'    
  END  AS ContractStauts
 ,ae.Line1 as Address1    
 --,ae.Line2 as Address2    
 ,REPLACE(RTRIM(    
   COALESCE(ae.City, '') +    
   COALESCE(', ' + ae.StateProvince,'') +     
   COALESCE(' ' + LTRIM(ae.PostalCode), '') +     
   COALESCE(' ' + ae.CountryCode, '')     
   ), ' ', ' ')     AS StateCountryCityZip 
 , pe24.PhoneTypeID  AS DisptchType
 , pe24.PhoneNumber  AS DispatchNumber  
 , peOfc.PhoneTypeID  AS OfficeType   
 , peOfc.PhoneNumber  AS OfficeNumber
FROM VendorLocation vl    
INNER JOIN Vendor v on v.ID = vl.VendorID    
LEFT OUTER JOIN AddressEntity ae on ae.RecordID = vl.ID and ae.EntityID = (Select ID From Entity Where Name = 'VendorLocation')     
LEFT OUTER JOIN PhoneEntity pe24 on pe24.RecordID = vl.ID and pe24.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and pe24.PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')    
--Left Outer Join PhoneEntity peFax on peFax.RecordID = vl.ID and peFax.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and peFax.PhoneTypeID = (Select ID From PhoneType Where Name = 'Fax')    
LEFT OUTER JOIN PhoneEntity peOfc on peOfc.RecordID = v.ID and peOfc.EntityID = (Select ID From Entity Where Name = 'Vendor') and peOfc.PhoneTypeID = (Select ID From PhoneType Where Name = 'Office')    
LEFT OUTER JOIN [Contract] c on c.VendorID = v.ID and c.IsActive = 1    

WHERE     
(v.VendorNumber IS NULL OR v.VendorNumber NOT LIKE '9X%' ) --KB: VendorNumber will be NULL for newly added vendors and these are getting excluded from the possible duplicates  
AND  
-- TP: Matching either phone number across both phone types is valid for this search;   
--     grouped OR condition -- A match on either phone number is valid  
(ISNULL(pe24.PhoneNumber,'') IN (@DispatchPhone, @OfficePhone, @FaxPhone)  
 OR  
 ISNULL(peOfc.PhoneNumber,'') IN (@DispatchPhone, @OfficePhone, @FaxPhone)  
 OR
 (ae.Line1 LIKE '%' + @Address1 + '%')
 AND
 (ae.City LIKE '%' + @City  + '%') 
 AND 
 (v.Name LIKE @VendorName)
)  
AND v.ID <> @ID

INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.VendorLocationID,
	T.Sequence,
	T.VendorNumber,
	T.Name,
	T.VendorStatus,
	T.ContractStauts,
	T.Address1,
	T.StateCountryCityZip,
	T.DisptchType,
	T.DispatchNumber,
	T.OfficeType,
	T.OfficeNumber
FROM #tmpFinalResults T,
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
	 ( TMP.VendorLocationIDOperator = -1 ) 
 OR 
	 ( TMP.VendorLocationIDOperator = 0 AND T.VendorLocationID IS NULL ) 
 OR 
	 ( TMP.VendorLocationIDOperator = 1 AND T.VendorLocationID IS NOT NULL ) 
 OR 
	 ( TMP.VendorLocationIDOperator = 2 AND T.VendorLocationID = TMP.VendorLocationIDValue ) 
 OR 
	 ( TMP.VendorLocationIDOperator = 3 AND T.VendorLocationID <> TMP.VendorLocationIDValue ) 
 OR 
	 ( TMP.VendorLocationIDOperator = 7 AND T.VendorLocationID > TMP.VendorLocationIDValue ) 
 OR 
	 ( TMP.VendorLocationIDOperator = 8 AND T.VendorLocationID >= TMP.VendorLocationIDValue ) 
 OR 
	 ( TMP.VendorLocationIDOperator = 9 AND T.VendorLocationID < TMP.VendorLocationIDValue ) 
 OR 
	 ( TMP.VendorLocationIDOperator = 10 AND T.VendorLocationID <= TMP.VendorLocationIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.SequenceOperator = -1 ) 
 OR 
	 ( TMP.SequenceOperator = 0 AND T.Sequence IS NULL ) 
 OR 
	 ( TMP.SequenceOperator = 1 AND T.Sequence IS NOT NULL ) 
 OR 
	 ( TMP.SequenceOperator = 2 AND T.Sequence = TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 3 AND T.Sequence <> TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 7 AND T.Sequence > TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 8 AND T.Sequence >= TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 9 AND T.Sequence < TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 10 AND T.Sequence <= TMP.SequenceValue ) 

 ) 

 AND 

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
	 ( TMP.VendorStatusOperator = -1 ) 
 OR 
	 ( TMP.VendorStatusOperator = 0 AND T.VendorStatus IS NULL ) 
 OR 
	 ( TMP.VendorStatusOperator = 1 AND T.VendorStatus IS NOT NULL ) 
 OR 
	 ( TMP.VendorStatusOperator = 2 AND T.VendorStatus = TMP.VendorStatusValue ) 
 OR 
	 ( TMP.VendorStatusOperator = 3 AND T.VendorStatus <> TMP.VendorStatusValue ) 
 OR 
	 ( TMP.VendorStatusOperator = 4 AND T.VendorStatus LIKE TMP.VendorStatusValue + '%') 
 OR 
	 ( TMP.VendorStatusOperator = 5 AND T.VendorStatus LIKE '%' + TMP.VendorStatusValue ) 
 OR 
	 ( TMP.VendorStatusOperator = 6 AND T.VendorStatus LIKE '%' + TMP.VendorStatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ContractStautsOperator = -1 ) 
 OR 
	 ( TMP.ContractStautsOperator = 0 AND T.ContractStauts IS NULL ) 
 OR 
	 ( TMP.ContractStautsOperator = 1 AND T.ContractStauts IS NOT NULL ) 
 OR 
	 ( TMP.ContractStautsOperator = 2 AND T.ContractStauts = TMP.ContractStautsValue ) 
 OR 
	 ( TMP.ContractStautsOperator = 3 AND T.ContractStauts <> TMP.ContractStautsValue ) 
 OR 
	 ( TMP.ContractStautsOperator = 4 AND T.ContractStauts LIKE TMP.ContractStautsValue + '%') 
 OR 
	 ( TMP.ContractStautsOperator = 5 AND T.ContractStauts LIKE '%' + TMP.ContractStautsValue ) 
 OR 
	 ( TMP.ContractStautsOperator = 6 AND T.ContractStauts LIKE '%' + TMP.ContractStautsValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.Address1Operator = -1 ) 
 OR 
	 ( TMP.Address1Operator = 0 AND T.Address1 IS NULL ) 
 OR 
	 ( TMP.Address1Operator = 1 AND T.Address1 IS NOT NULL ) 
 OR 
	 ( TMP.Address1Operator = 2 AND T.Address1 = TMP.Address1Value ) 
 OR 
	 ( TMP.Address1Operator = 3 AND T.Address1 <> TMP.Address1Value ) 
 OR 
	 ( TMP.Address1Operator = 4 AND T.Address1 LIKE TMP.Address1Value + '%') 
 OR 
	 ( TMP.Address1Operator = 5 AND T.Address1 LIKE '%' + TMP.Address1Value ) 
 OR 
	 ( TMP.Address1Operator = 6 AND T.Address1 LIKE '%' + TMP.Address1Value + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.StateCountryCityZipOperator = -1 ) 
 OR 
	 ( TMP.StateCountryCityZipOperator = 0 AND T.StateCountryCityZip IS NULL ) 
 OR 
	 ( TMP.StateCountryCityZipOperator = 1 AND T.StateCountryCityZip IS NOT NULL ) 
 OR 
	 ( TMP.StateCountryCityZipOperator = 2 AND T.StateCountryCityZip = TMP.StateCountryCityZipValue ) 
 OR 
	 ( TMP.StateCountryCityZipOperator = 3 AND T.StateCountryCityZip <> TMP.StateCountryCityZipValue ) 
 OR 
	 ( TMP.StateCountryCityZipOperator = 4 AND T.StateCountryCityZip LIKE TMP.StateCountryCityZipValue + '%') 
 OR 
	 ( TMP.StateCountryCityZipOperator = 5 AND T.StateCountryCityZip LIKE '%' + TMP.StateCountryCityZipValue ) 
 OR 
	 ( TMP.StateCountryCityZipOperator = 6 AND T.StateCountryCityZip LIKE '%' + TMP.StateCountryCityZipValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DisptchTypeOperator = -1 ) 
 OR 
	 ( TMP.DisptchTypeOperator = 0 AND T.DisptchType IS NULL ) 
 OR 
	 ( TMP.DisptchTypeOperator = 1 AND T.DisptchType IS NOT NULL ) 
 OR 
	 ( TMP.DisptchTypeOperator = 2 AND T.DisptchType = TMP.DisptchTypeValue ) 
 OR 
	 ( TMP.DisptchTypeOperator = 3 AND T.DisptchType <> TMP.DisptchTypeValue ) 
 OR 
	 ( TMP.DisptchTypeOperator = 7 AND T.DisptchType > TMP.DisptchTypeValue ) 
 OR 
	 ( TMP.DisptchTypeOperator = 8 AND T.DisptchType >= TMP.DisptchTypeValue ) 
 OR 
	 ( TMP.DisptchTypeOperator = 9 AND T.DisptchType < TMP.DisptchTypeValue ) 
 OR 
	 ( TMP.DisptchTypeOperator = 10 AND T.DisptchType <= TMP.DisptchTypeValue ) 

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
	 ( TMP.OfficeTypeOperator = -1 ) 
 OR 
	 ( TMP.OfficeTypeOperator = 0 AND T.OfficeType IS NULL ) 
 OR 
	 ( TMP.OfficeTypeOperator = 1 AND T.OfficeType IS NOT NULL ) 
 OR 
	 ( TMP.OfficeTypeOperator = 2 AND T.OfficeType = TMP.OfficeTypeValue ) 
 OR 
	 ( TMP.OfficeTypeOperator = 3 AND T.OfficeType <> TMP.OfficeTypeValue ) 
 OR 
	 ( TMP.OfficeTypeOperator = 7 AND T.OfficeType > TMP.OfficeTypeValue ) 
 OR 
	 ( TMP.OfficeTypeOperator = 8 AND T.OfficeType >= TMP.OfficeTypeValue ) 
 OR 
	 ( TMP.OfficeTypeOperator = 9 AND T.OfficeType < TMP.OfficeTypeValue ) 
 OR 
	 ( TMP.OfficeTypeOperator = 10 AND T.OfficeType <= TMP.OfficeTypeValue ) 

 ) 

 AND 

 ( 
	 ( TMP.OfficeNumberOperator = -1 ) 
 OR 
	 ( TMP.OfficeNumberOperator = 0 AND T.OfficeNumber IS NULL ) 
 OR 
	 ( TMP.OfficeNumberOperator = 1 AND T.OfficeNumber IS NOT NULL ) 
 OR 
	 ( TMP.OfficeNumberOperator = 2 AND T.OfficeNumber = TMP.OfficeNumberValue ) 
 OR 
	 ( TMP.OfficeNumberOperator = 3 AND T.OfficeNumber <> TMP.OfficeNumberValue ) 
 OR 
	 ( TMP.OfficeNumberOperator = 4 AND T.OfficeNumber LIKE TMP.OfficeNumberValue + '%') 
 OR 
	 ( TMP.OfficeNumberOperator = 5 AND T.OfficeNumber LIKE '%' + TMP.OfficeNumberValue ) 
 OR 
	 ( TMP.OfficeNumberOperator = 6 AND T.OfficeNumber LIKE '%' + TMP.OfficeNumberValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'VendorLocationID' AND @sortOrder = 'ASC'
	 THEN T.VendorLocationID END ASC, 
	 CASE WHEN @sortColumn = 'VendorLocationID' AND @sortOrder = 'DESC'
	 THEN T.VendorLocationID END DESC ,

	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'
	 THEN T.Sequence END ASC, 
	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'
	 THEN T.Sequence END DESC ,

	 CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'
	 THEN T.VendorNumber END ASC, 
	 CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'
	 THEN T.VendorNumber END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'ASC'
	 THEN T.VendorStatus END ASC, 
	 CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'DESC'
	 THEN T.VendorStatus END DESC ,

	 CASE WHEN @sortColumn = 'ContractStauts' AND @sortOrder = 'ASC'
	 THEN T.ContractStauts END ASC, 
	 CASE WHEN @sortColumn = 'ContractStauts' AND @sortOrder = 'DESC'
	 THEN T.ContractStauts END DESC ,

	 CASE WHEN @sortColumn = 'Address1' AND @sortOrder = 'ASC'
	 THEN T.Address1 END ASC, 
	 CASE WHEN @sortColumn = 'Address1' AND @sortOrder = 'DESC'
	 THEN T.Address1 END DESC ,

	 CASE WHEN @sortColumn = 'StateCountryCityZip' AND @sortOrder = 'ASC'
	 THEN T.StateCountryCityZip END ASC, 
	 CASE WHEN @sortColumn = 'StateCountryCityZip' AND @sortOrder = 'DESC'
	 THEN T.StateCountryCityZip END DESC ,

	 CASE WHEN @sortColumn = 'DisptchType' AND @sortOrder = 'ASC'
	 THEN T.DisptchType END ASC, 
	 CASE WHEN @sortColumn = 'DisptchType' AND @sortOrder = 'DESC'
	 THEN T.DisptchType END DESC ,

	 CASE WHEN @sortColumn = 'DispatchNumber' AND @sortOrder = 'ASC'
	 THEN T.DispatchNumber END ASC, 
	 CASE WHEN @sortColumn = 'DispatchNumber' AND @sortOrder = 'DESC'
	 THEN T.DispatchNumber END DESC ,

	 CASE WHEN @sortColumn = 'OfficeType' AND @sortOrder = 'ASC'
	 THEN T.OfficeType END ASC, 
	 CASE WHEN @sortColumn = 'OfficeType' AND @sortOrder = 'DESC'
	 THEN T.OfficeType END DESC ,

	 CASE WHEN @sortColumn = 'OfficeNumber' AND @sortOrder = 'ASC'
	 THEN T.OfficeNumber END ASC, 
	 CASE WHEN @sortColumn = 'OfficeNumber' AND @sortOrder = 'DESC'
	 THEN T.OfficeNumber END DESC 


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
DROP TABLE #tmpFinalResults
END

GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_MemberManagement_Search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_MemberManagement_Search]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
CREATE PROCEDURE [dbo].[dms_MemberManagement_Search](   
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10   
 , @sortColumn nvarchar(100)  = 'MemberNumber'   
 , @sortOrder nvarchar(100) = 'ASC'   
 )   
 AS   
 BEGIN   
    
	SET NOCOUNT ON    
	SET FMTONLY OFF
	-- KB : Temporary resultsets. These resultsets are used to prepare mangeable resultsets.
	CREATE TABLE #FinalResultsFiltered(     

	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	Suffix nvarchar(50)  NULL ,    
	Prefix nvarchar(50)  NULL ,    
	City nvarchar(50)  NULL ,    
	StateProvince nvarchar(50)  NULL ,    
	PostalCode nvarchar(50)  NULL ,    
	HomePhoneNumber nvarchar(50)  NULL ,    
	WorkPhoneNumber nvarchar(50)  NULL ,    
	CellPhoneNumber nvarchar(50)  NULL ,    
	Program nvarchar(50)  NULL ,    
	POCount INT NULL,  
	ExpirationDate DATETIME NULL,   
	EffectiveDate DATETIME NULL,
	VIN nvarchar(50)  NULL ,    
	[StateProvinceID] INT  NULL,
	MiddleName   nvarchar(50)  NULL , 
	CountryCode nvarchar(2) NULL
	)    

	CREATE TABLE #FinalResultsFormatted(      
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL ,    
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,    
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL     
	)    

	CREATE TABLE #FinalResultsSorted(     
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL ,    
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,    
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL     
	)  
	
	CREATE TABLE #FinalResultsDistinct(     
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL ,    
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,    
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL     
	)  

	DECLARE @idoc int    
	IF @whereClauseXML IS NULL     
	BEGIN    
	SET @whereClauseXML = '<ROW>
	<Filter     
	MemberIDOperator="-1"     
	MemberNumberOperator="-1"  
	FirstNameOperator="-1"  
	LastNameOperator="-1"      
	CountryIDOperator="-1"      
	StateProvinceIDOperator="-1"
	CityOperator="-1"
	PostalCodeOperator="-1"
	PhoneNumberOperator="-1"
	VINOperator="-1"
	MemberStatusOperator="-1"
	ClientIDOperator="-1"
	ProgramIDOperator="-1">
	</Filter></ROW>'    
	END    
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML    

	DECLARE @tmpForWhereClause TABLE    
	(    
	MemberIDOperator INT NOT NULL,    
	MemberIDValue int NULL,    
	
	MemberNumberOperator INT NOT NULL,    
	MemberNumberValue nvarchar(50) NULL,    
	
	FirstNameOperator INT NOT NULL,
	FirstNameValue nvarchar(50) NULL,  
	
	LastNameOperator INT NOT NULL,
	LastNameValue nvarchar(50) NULL,  
	
	CountryIDOperator INT NOT NULL,
	CountryIDValue INT NULL, 
	
	StateProvinceIDOperator INT NOT NULL,
	StateProvinceIDValue INT NULL, 
	
	CityOperator INT NOT NULL,
	CityValue nvarchar(50) NULL, 
	
	PostalCodeOperator INT NOT NULL,
	PostalCodeValue nvarchar(50) NULL, 
	
	PhoneNumberOperator INT NOT NULL,
	PhoneNumberValue nvarchar(50) NULL, 
	
	VINOperator INT NOT NULL,
	VINValue nvarchar(50) NULL, 
	
	MemberStatusOperator INT NOT NULL,
	MemberStatusValue nvarchar(50) NULL, 
	
	ClientIDOperator INT NOT NULL,
	ClientIDValue INT NULL, 
	
	ProgramIDOperator INT NOT NULL,
	ProgramIDValue INT NULL
	)    

	-- Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'     

	INSERT INTO @tmpForWhereClause    
	SELECT      
			ISNULL(MemberIDOperator,-1),    
			MemberIDValue ,    
			
			ISNULL(MemberNumberOperator,-1),    
			MemberNumberValue ,    
			
			ISNULL(FirstNameOperator,-1),    
			FirstNameValue ,    
			
			ISNULL(LastNameOperator,-1),    
			LastNameValue,
			
			ISNULL(CountryIDOperator,-1),    
			CountryIDValue,
			
			ISNULL(StateProvinceIDOperator,-1),    
			StateProvinceIDValue,
			
			ISNULL(CityOperator,-1),    
			CityValue,
			
			ISNULL(PostalCodeOperator,-1),    
			PostalCodeValue,
			
			ISNULL(PhoneNumberOperator,-1),    
			PhoneNumberValue,
			
			ISNULL(VINOperator,-1),    
			VINValue,
			
			ISNULL(MemberStatusOperator,-1),    
			MemberStatusValue,
			
			ISNULL(ClientIDOperator,-1),    
			ClientIDValue,
			
			ISNULL(ProgramIDOperator,-1),    
			ProgramIDValue
			 
	FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (    
			MemberIDOperator INT,    
			MemberIDValue int,
			
			MemberNumberOperator INT,    
			MemberNumberValue nvarchar(50),
			
			FirstNameOperator INT,    
			FirstNameValue nvarchar(50),
			
			LastNameOperator INT,    
			LastNameValue nvarchar(50),
			
			CountryIDOperator INT,    
			CountryIDValue INT,
			
			StateProvinceIDOperator INT,    
			StateProvinceIDValue INT,
			
			CityOperator INT,    
			CityValue nvarchar(50),
			
			PostalCodeOperator INT,    
			PostalCodeValue nvarchar(50),
			
			PhoneNumberOperator INT,    
			PhoneNumberValue nvarchar(50),
			
			VINOperator INT,    
			VINValue nvarchar(50),
			
			MemberStatusOperator INT,    
			MemberStatusValue nvarchar(50),
			
			ClientIDOperator INT,    
			ClientIDValue INT,
			
			ProgramIDOperator INT,    
			ProgramIDValue INT			  
	)     
	
	--SELECT * FROM @tmpForWhereClause
	
	DECLARE @vinParam nvarchar(50)    
	SELECT @vinParam = VINValue FROM @tmpForWhereClause    

	DECLARE @memberEntityID INT  
	SELECT @memberEntityID = ID FROM Entity WHERE Name = 'Member'  
	--------------------- BEGIN -----------------------------    
	----   Create a temp variable or a CTE with the actual SQL search query ----------    
	----   and use that CTE in the place of <table> in the following SQL statements ---    
	--------------------- END -----------------------------    
	DECLARE @phoneNumber NVARCHAR(100)  
	SET @phoneNumber = (SELECT PhoneNumberValue FROM @tmpForWhereClause)  

	DECLARE @memberID INT
	DECLARE @memberNumber NVARCHAR(50)
	DECLARE @ProgramID INT = NULL
	DECLARE @ClientID INT = NULL
	DECLARE @firstName NVARCHAR(50)
	DECLARE @lastName NVARCHAR(50)
	DECLARE @stateID INT = NULL
	DECLARE @CountryID INT = NULL
	DECLARE @Zip NVARCHAR(50) = NULL
	DECLARE @City NVARCHAR(50) = NULL
	DECLARE @lastNameOperator INT = NULL
	DECLARE @firstNameOperator INT = NULL
	DECLARE @memberStatusValue NVARCHAR(200) = NULL

	--Sanghi Need to Add Client Join
	SELECT	@memberID = MemberIDValue,
			@memberNumber = MemberNumberValue,
			@ProgramID = CASE WHEN ProgramIDValue = '-1' THEN NULL ELSE ProgramIDValue END,
			@ClientID = ClientIDValue,
			@firstName = FirstNameValue,
			@lastName = LastNameValue,
			@stateID =    StateProvinceIDValue,
			@CountryID =  CountryIDValue,
			@Zip = PostalCodeValue,
			@City = CityValue,
			@lastNameOperator = LastNameOperator,
			@firstNameOperator = FirstNameOperator,
			@memberStatusValue = MemberStatusValue
	FROM	@tmpForWhereClause

		
	SET FMTONLY OFF;  
	  
	IF @phoneNumber IS NULL  
	BEGIN  

	-- If vehicle is given, then let's use Vehicle in the left join (as the first table) else don't even consider vehicle table.

		IF @vinParam IS NOT NULL
		
		
		
		BEGIN

			SELECT	* 
			INTO	#TmpVehicle1
			FROM	Vehicle V WITH (NOLOCK)
			WHERE	V.VIN LIKE '%' + @vinParam + '%'


			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber-- PH.PhoneNumber AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber -- PW.PhoneNumber AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber -- PC.PhoneNumber AS CellPhoneNumber  
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate   
					, m.EffectiveDate 
					, v.VIN  
					, A.[StateProvinceID]
					,M.MiddleName 
					,A.CountryCode
			FROM #TmpVehicle1 v
			LEFT JOIN Member M WITH (NOLOCK) ON  (v.MemberID IS NULL OR v.MemberID = m.ID) 
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID AND v.MembershipID = MS.ID
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN Program P WITH (NOLOCK) ON P.ID = M.ProgramID   
			JOIN Client C WITH (NOLOCK) ON P.ClientID = C.ID
			WHERE  M.IsPrimary =1
			AND	  ((@memberID IS NULL)  OR (@memberID = M.ID))
			AND   ((@memberNumber IS NULL) OR (MS.MembershipNumber LIKE  '%' + @memberNumber + '%'))  
			AND   ((@ClientID IS NULL) OR (C.ID = @ClientID)) 
			AND   ((@ProgramID IS NULL) OR (P.ID = @ProgramID)) 
			AND   ((@stateID IS NULL) OR (A.StateProvinceID = @stateID)) 
			AND   ((@CountryID IS NULL) OR (A.CountryID = @CountryID)) 
			AND   ((@Zip IS NULL) OR (A.PostalCode LIKE '%' + @Zip +'%')) 
			AND   ((@City IS NULL) OR (A.City LIKE @City +'%')) 
			AND   ((@lastName IS NULL) OR (@lastNameOperator = 2 AND M.LastName = @lastName ) 
									   OR (@lastNameOperator = 4 AND M.LastName LIKE @lastName + '%')
									   OR (@lastNameOperator = 6 AND M.LastName LIKE '%' + @lastName + '%')
			                           OR (@lastNameOperator = 5 AND M.LastName LIKE '%' + @lastName))	
			
			AND   ((@firstName IS NULL) OR (@firstNameOperator = 2 AND M.FirstName = @firstName)
										OR (@firstNameOperator = 4 AND M.FirstName LIKE @firstName + '%')
										OR (@firstNameOperator = 6 AND M.FirstName LIKE '%' + @firstName + '%') 
										OR (@firstNameOperator = 5 AND M.FirstName LIKE '%' + @firstName)) 
		
			AND M.IsActive=1		 
			DROP TABLE #TmpVehicle1

		END -- End of Vin param check
		ELSE
		BEGIN

			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber-- PH.PhoneNumber AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber -- PW.PhoneNumber AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber -- PC.PhoneNumber AS CellPhoneNumber  
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate   
					, m.EffectiveDate 
					, '' AS VIN  
					, A.[StateProvinceID]
					,M.MiddleName 
					,A.CountryCode
			FROM Member M WITH (NOLOCK)  
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID   
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  			
			JOIN Program P WITH (NOLOCK) ON P.ID = M.ProgramID    
			JOIN Client C WITH (NOLOCK) ON P.ClientID = C.ID
			WHERE  M.IsPrimary =1
			AND   ((@memberID IS NULL)  OR (@memberID = M.ID))
			AND   ((@memberNumber IS NULL) OR (MS.MembershipNumber LIKE  '%' + @memberNumber + '%'))  
			AND   ((@ClientID IS NULL) OR (C.ID = @ClientID)) 
			AND   ((@ProgramID IS NULL) OR (P.ID = @ProgramID)) 
			AND   ((@stateID IS NULL) OR (A.StateProvinceID = @stateID)) 
			AND   ((@CountryID IS NULL) OR (A.CountryID = @CountryID)) 
			AND   ((@Zip IS NULL) OR (A.PostalCode LIKE '%' + @Zip +'%')) 
			AND   ((@City IS NULL) OR (A.City LIKE @City +'%')) 
		
			AND   ((@lastName IS NULL) OR (@lastNameOperator = 2 AND M.LastName = @lastName ) 
									   OR (@lastNameOperator = 4 AND M.LastName LIKE @lastName + '%')
									   OR (@lastNameOperator = 6 AND M.LastName LIKE '%' + @lastName + '%')
			                           OR (@lastNameOperator = 5 AND M.LastName LIKE '%' + @lastName))	
			
			AND   ((@firstName IS NULL) OR (@firstNameOperator = 2 AND M.FirstName = @firstName)
										OR (@firstNameOperator = 4 AND M.FirstName LIKE @firstName + '%')
										OR (@firstNameOperator = 6 AND M.FirstName LIKE '%' + @firstName + '%') 
										OR (@firstNameOperator = 5 AND M.FirstName LIKE '%' + @firstName))
		    AND M.IsActive=1
		END		
		
	END  -- End of Phone number is null check.
	ELSE  
	BEGIN
	
		SELECT *  
		INTO #tmpPhone  
		FROM PhoneEntity PH WITH (NOLOCK)  
		WHERE PH.EntityID = @memberEntityID   
		AND  PH.PhoneNumber = @phoneNumber   

		-- Consider VIN param.
		IF @vinParam IS NOT NULL
		BEGIN
		
			SELECT	* 
			INTO	#TmpVehicle
			FROM	Vehicle V WITH (NOLOCK)
			WHERE	V.VIN LIKE '%' + @vinParam + '%' 

			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber  
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate 
					, m.EffectiveDate  
					, v.VIN  
					, A.[StateProvinceID] 
					, M.MiddleName 
					,A.CountryCode
			FROM #TmpVehicle v
			LEFT JOIN Member M WITH (NOLOCK) ON  (v.MemberID IS NULL OR v.MemberID = m.ID) 
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID AND v.MembershipID = MS.ID
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN Program P WITH (NOLOCK) ON P.ID = M.ProgramID   
			JOIN Client C WITH (NOLOCK) ON P.ClientID = C.ID
			JOIN @tmpForWhereClause TMP ON 1=1  
			WHERE M.IsPrimary =1
			AND   ((@memberID IS NULL)  OR (@memberID = M.ID))
			AND   ((@memberNumber IS NULL) OR (MS.MembershipNumber LIKE  '%' + @memberNumber + '%'))  
			AND   ((@ClientID IS NULL) OR (C.ID = @ClientID))
			AND   ((@ProgramID IS NULL) OR (P.ID = @ProgramID)) 
			AND   ((@stateID IS NULL) OR (A.StateProvinceID = @stateID)) 
			AND   ((@CountryID IS NULL) OR (A.CountryID = @CountryID)) 
			AND   ((@Zip IS NULL) OR (A.PostalCode LIKE '%' + @Zip +'%')) 
			AND   ((@City IS NULL) OR (A.City LIKE @City +'%')) 
			
			AND   ((@lastName IS NULL) OR (@lastNameOperator = 2 AND M.LastName = @lastName ) 
									   OR (@lastNameOperator = 4 AND M.LastName LIKE @lastName + '%')
									   OR (@lastNameOperator = 6 AND M.LastName LIKE '%' + @lastName + '%')
			                           OR (@lastNameOperator = 5 AND M.LastName LIKE '%' + @lastName))	
			
			AND   ((@firstName IS NULL) OR (@firstNameOperator = 2 AND M.FirstName = @firstName)
										OR (@firstNameOperator = 4 AND M.FirstName LIKE @firstName + '%')
										OR (@firstNameOperator = 6 AND M.FirstName LIKE '%' + @firstName + '%') 
										OR (@firstNameOperator = 5 AND M.FirstName LIKE '%' + @firstName))
            AND M.IsActive=1
            
			DROP TABLE #TmpVehicle
		END -- End of Vin param check
		ELSE
		BEGIN
			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber  
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate
					, m.EffectiveDate   
					, '' AS VIN  
					, A.[StateProvinceID] 
					, M.MiddleName
					,A.CountryCode 
			FROM	#tmpPhone PH
			JOIN	Member M WITH (NOLOCK)  ON PH.RecordID = M.ID
			JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID    

			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN Program P WITH (NOLOCK) ON P.ID = M.ProgramID    
			JOIN Client C WITH (NOLOCK) ON P.ClientID = C.ID
			JOIN @tmpForWhereClause TMP ON 1 = 1  
			WHERE M.IsPrimary =1
			AND   ((@memberID IS NULL)  OR (@memberID = M.ID))
			AND   ((@memberNumber IS NULL) OR (MS.MembershipNumber LIKE  '%' + @memberNumber + '%'))  
			AND   ((@ClientID IS NULL) OR (C.ID = @ClientID))
			AND   ((@ProgramID IS NULL) OR (P.ID = @ProgramID)) 
			AND   ((@stateID IS NULL) OR (A.StateProvinceID = @stateID)) 
			AND   ((@CountryID IS NULL) OR (A.CountryID = @CountryID)) 
			AND   ((@Zip IS NULL) OR (A.PostalCode LIKE '%' + @Zip +'%')) 
			AND   ((@City IS NULL) OR (A.City LIKE @City +'%')) 
			
			AND   ((@lastName IS NULL) OR (@lastNameOperator = 2 AND M.LastName = @lastName ) 
									   OR (@lastNameOperator = 4 AND M.LastName LIKE @lastName + '%')
									   OR (@lastNameOperator = 6 AND M.LastName LIKE '%' + @lastName + '%')
			                           OR (@lastNameOperator = 5 AND M.LastName LIKE '%' + @lastName))	
			
			AND   ((@firstName IS NULL) OR (@firstNameOperator = 2 AND M.FirstName = @firstName)
										OR (@firstNameOperator = 4 AND M.FirstName LIKE @firstName + '%')
										OR (@firstNameOperator = 6 AND M.FirstName LIKE '%' + @firstName + '%') 
										OR (@firstNameOperator = 5 AND M.FirstName LIKE '%' + @firstName))
			AND M.IsActive=1
		END
	END  -- End of phone number not null check

	-- DEBUG:   
	--SELECT COUNT(*) AS Filtered FROM #FinalResultsFiltered  

	-- Do all computations  
	INSERT INTO #FinalResultsFormatted  
	SELECT   F.MemberID  
	, F.MembershipID  
	, F.MemberNumber     
	--, REPLACE(RTRIM(COALESCE(F.LastName, '')   
	-- + COALESCE(' ' + F.Suffix, '')   
	-- + COALESCE(', ' + F.FirstName, '')), ' ', ' ')   
	-- + COALESCE(' ' + F.Prefix, '') AS Name  
	,REPLACE(RTRIM( 
	COALESCE(F.FirstName, '') + 
	COALESCE(' ' + left(F.MiddleName,1), '') + 
	COALESCE(' ' + F.LastName, '') +
	COALESCE(' ' + F.Suffix, '')
	), ' ', ' ') AS MemberName
	,(ISNULL(F.City,'') + ', ' + ISNULL(F.StateProvince,'') + ' ' + ISNULL(F.PostalCode,'') + ' ' + ISNULL(F.CountryCode,'')) AS [Address]     
	, COALESCE(F.HomePhoneNumber, F.WorkPhoneNumber, F.CellPhoneNumber, '') As PhoneNumber     
	, F.Program    
	,(SELECT COUNT(*) FROM [Case] WHERE MemberID = F.MemberID) AS POCount   
	-- Ignore time while comparing the dates here  
	--,CASE WHEN F.EffectiveDate <= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0) AND F.ExpirationDate >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)   
	--  THEN 'Active'   
	--  ELSE 'Inactive'   
	-- END 
	-- KB: Considering Effective and Expiration Dates to calculate member status
	,CASE WHEN ISNULL(F.EffectiveDate,@minDate) <= @now AND ISNULL(F.ExpirationDate,@minDate) >= @now
			THEN 'Active'
			ELSE 'Inactive'
	END AS MemberStatus
	, F.LastName  
	, F.FirstName  
	,CASE WHEN ISNULL(@vinParam,'') <> ''    
	THEN  F.VIN    
	ELSE  ''    
	END AS VIN     
	, F.StateProvinceID AS [State]  
	, F.PostalCode AS ZipCode  

	FROM #FinalResultsFiltered F  
	
	IF @phoneNumber IS NULL  
	BEGIN  

		INSERT INTO #FinalResultsSorted  
		SELECT  F.MemberID,  
		F.MembershipID,    
		F.MemberNumber,     
		F.Name,    
		F.[Address],    
		COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber,   
		F.Program,    
		F.POCount,    
		F.MemberStatus,    
		F.LastName,    
		F.FirstName ,    
		F.VIN ,    
		F.[State] ,    
		F.ZipCode   
		FROM  #FinalResultsFormatted F   
		LEFT JOIN PhoneEntity PH WITH (NOLOCK) ON PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PH.PhoneNumber)  
		LEFT JOIN PhoneEntity PW WITH (NOLOCK) ON PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PW.PhoneNumber)  
		LEFT JOIN PhoneEntity PC WITH (NOLOCK) ON PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PC.PhoneNumber) 

		ORDER BY     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'    
		THEN F.MembershipID END ASC,     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'    
		THEN F.MembershipID END DESC ,    

		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'    
		THEN F.MemberNumber END ASC,     
		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'    
		THEN F.MemberNumber END DESC ,    

		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'    
		THEN F.Name END ASC,     
		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'    
		THEN F.Name END DESC ,    

		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'    
		THEN F.Address END ASC,     
		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'    
		THEN F.Address END DESC ,    

		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC ,    

		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,    

		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'    
		THEN F.POCount END ASC,     
		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'    
		THEN F.POCount END DESC ,    

		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'ASC'    
		THEN F.MemberStatus END ASC,     
		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'DESC'    
		THEN F.MemberStatus END DESC    

	END  
	ELSE  

	BEGIN  
	-- DEBUG  :SELECT COUNT(*) FROM #tmpPhone  

		INSERT INTO #FinalResultsSorted  
		SELECT  F.MemberID,  
		 F.MembershipID,    
		 F.MemberNumber,     
		 F.Name,    
		 F.[Address],    
		 COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber,   
		 F.Program,    
		 F.POCount,    
		 F.MemberStatus,    
		 F.LastName,    
		 F.FirstName ,    
		F.VIN ,    
		F.[State] ,    
		F.ZipCode   
		FROM  #FinalResultsFormatted F   
		LEFT JOIN #tmpPhone PH WITH (NOLOCK) ON PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID 
		LEFT JOIN #tmpPhone PW WITH (NOLOCK) ON PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID 
		LEFT JOIN #tmpPhone PC WITH (NOLOCK) ON PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID 
		WHERE (PH.PhoneNumber = @phoneNumber OR PW.PhoneNumber = @phoneNumber OR PC.PhoneNumber=@phoneNumber)
		ORDER BY     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'    
		THEN F.MembershipID END ASC,     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'    
		THEN F.MembershipID END DESC ,    

		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'    
		THEN F.MemberNumber END ASC,     
		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'    
		THEN F.MemberNumber END DESC ,    

		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'    
		THEN F.Name END ASC,      
		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'    
		THEN F.Name END DESC ,    

		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'    
		THEN F.Address END ASC,     
		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'    
		THEN F.Address END DESC ,    

		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC ,    

		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,    

		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'    
		THEN F.POCount END ASC,     
		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'    
		THEN F.POCount END DESC ,    

		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'ASC'    
		THEN F.MemberStatus END ASC,     
		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'DESC'    
		THEN F.MemberStatus END DESC
		
		DROP TABLE #tmpPhone    
	END     
-- DEBUG:
--SELECT * FROM #FinalResultsSorted

	-- Let's delete duplicates from #FinalResultsSorted and then insert into Distinct.
	
	;WITH wSorted 
	AS
	(
		SELECT ROW_NUMBER() OVER (PARTITION BY 
			F.MemberID,  
			F.MembershipID,    
			F.MemberNumber,     
			F.Name,    
			F.[Address],    
			F.PhoneNumber,    
			F.Program,    
			F.POCount,    
			F.MemberStatus,    
			F.VIN ORDER BY F.RowNum) AS sRowNumber	
		FROM #FinalResultsSorted F
	)
	
	DELETE FROM wSorted WHERE sRowNumber > 1
	
	INSERT INTO #FinalResultsDistinct(
			MemberID,  
			MembershipID,    
			MemberNumber,     
			Name,    
			[Address],    
			PhoneNumber,    
			Program,    
			POCount,    
			MemberStatus,    
			VIN 
	)   
	SELECT	F.MemberID,  
			F.MembershipID,    
			F.MemberNumber,     
			F.Name,    
			F.[Address],    
			F.PhoneNumber,    
			F.Program,    
			F.POCount,    
			F.MemberStatus,    
			F.VIN  	
	FROM #FinalResultsSorted F
	WHERE ((@memberStatusValue IS NULL) OR ( F.MemberStatus IN (SELECT item FROM fnSplitString(@memberStatusValue,','))))
	ORDER BY 
	CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC,
		F.RowNum  
		

	DECLARE @count INT       
	SET @count = 0       
	SELECT @count = MAX(RowNum) FROM #FinalResultsDistinct   
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



	SELECT @count AS TotalRows, F.MemberID,  
		F.MembershipID,    
	   F.MemberNumber,     
	   F.Name,    
	   F.[Address],    
	   F.PhoneNumber,    
	   F.Program,    
	   F.POCount,    
	   F.MemberStatus,    
	   F.VIN    
	   FROM    
	   #FinalResultsDistinct F WHERE RowNum BETWEEN @startInd AND @endInd    
	     
	DROP TABLE #FinalResultsFiltered  
	DROP TABLE #FinalResultsFormatted  
	DROP TABLE #FinalResultsSorted 
	DROP TABLE #FinalResultsDistinct



END

GO
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
 WHERE id = object_id(N'[dbo].dms_MemberShip_Mangement_SR_History_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_MemberShip_Mangement_SR_History_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_MemberShip_Mangement_SR_History_Get @MembershipID=1
 CREATE PROCEDURE [dbo].dms_MemberShip_Mangement_SR_History_Get( 
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
WHERE M.MembershipID = @MembershipID
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

GO
/*
	NP 02/03: Whatever the changes made to this SP has to be made to dms_Merge_Members_Search also
*/

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
 WHERE id = object_id(N'[dbo].[dms_Members_Search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Members_Search]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter FirstNameOperator="4" FirstNameValue="jeevan"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
--EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter PhoneNumberOperator="2" PhoneNumberValue="8173078882"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
--EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter MemberNumberOperator="2" MemberNumberValue="123"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
-- EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter VINOperator="4" VINValue="K1234422323N1233"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3

CREATE PROCEDURE [dbo].[dms_Members_Search](   
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10   
 , @sortColumn nvarchar(100)  = 'MemberNumber'   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @programID INT = NULL   
 )   
 AS   
 BEGIN   
    
	SET NOCOUNT ON    
	SET FMTONLY OFF;
	-- KB : Temporary resultsets. These resultsets are used to prepare mangeable resultsets.
	CREATE TABLE #FinalResultsFiltered(     

	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	Suffix nvarchar(50)  NULL ,    
	Prefix nvarchar(50)  NULL ,    
	City nvarchar(50)  NULL ,    
	StateProvince nvarchar(50)  NULL ,    
	PostalCode nvarchar(50)  NULL ,    
	HomePhoneNumber nvarchar(50)  NULL ,    
	WorkPhoneNumber nvarchar(50)  NULL ,    
	CellPhoneNumber nvarchar(50)  NULL ,  
	ProgramID INT NULL, -- KB: ADDED IDS  
	Program nvarchar(50)  NULL ,    
	POCount INT NULL,  
	ExpirationDate DATETIME NULL,   
	EffectiveDate DATETIME NULL,
	VIN nvarchar(50)  NULL ,    
	VehicleID INT NULL, -- KB: Added VehicleID
	[StateProvinceID] INT  NULL,
	MiddleName   nvarchar(50)  NULL , 
	ClientMemberType nvarchar(200)  NULL 
	)    

	CREATE TABLE #FinalResultsFormatted(      
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,  
	VehicleID INT NULL, -- KB: Added VehicleID  
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL,
	ClientMemberType nvarchar(200)  NULL
	)    

	CREATE TABLE #FinalResultsSorted(     
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL , 
	VehicleID INT NULL, -- KB: Added VehicleID   
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL,
	ClientMemberType nvarchar(200)  NULL 
	)  
	CREATE TABLE #FinalResultsDistinct(     
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,  
	VehicleID INT NULL, -- KB: Added VehicleID  
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL,
	ClientMemberType nvarchar(200)  NULL
	)  

	CREATE TABLE #SearchPrograms (
	ProgramID int, 
	ProgramName nvarchar(200),
	ClientID int
	)
	
	INSERT INTO #SearchPrograms (ProgramID, ProgramName, ClientID)
	SELECT ProgramID, ProgramName, ClientID
	--FROM [dbo].[fnc_GetMemberSearchPrograms](9) --@programID)
	FROM [dbo].[fnc_GetMemberSearchPrograms] (@programID)
	
	CREATE CLUSTERED INDEX IDX_SearchPrograms ON #SearchPrograms(ProgramID)
	--Select * From #SearchPrograms
	--Drop table #SearchPrograms
	
	DECLARE @idoc int    
	IF @whereClauseXML IS NULL     
	BEGIN    
	SET @whereClauseXML = '<ROW><Filter     
	MemberIDOperator="-1"     
	MemberNumberOperator="-1"     
	PhoneNumberOperator="-1"     
	ProgramOperator="-1"     
	LastNameOperator="-1"     
	FirstNameOperator="-1"     
	VINOperator="-1"     
	StateOperator="-1"    
	ZipCodeOperator = "-1"   
	></Filter></ROW>'    
	END    
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML    

	DECLARE @tmpForWhereClause TABLE    
	(    
	MemberIDOperator INT NOT NULL,    
	MemberIDValue int NULL,    
	MemberNumberOperator INT NOT NULL,    
	MemberNumberValue nvarchar(50) NULL,    
	PhoneNumberOperator INT NOT NULL,    
	PhoneNumberValue nvarchar(50) NULL,    
	ProgramOperator INT NOT NULL,    
	ProgramValue nvarchar(50) NULL,    
	LastNameOperator INT NOT NULL,    
	LastNameValue nvarchar(50) NULL,    
	FirstNameOperator INT NOT NULL,    
	FirstNameValue nvarchar(50) NULL,    
	VINOperator INT NOT NULL,    
	VINValue nvarchar(50) NULL,    
	StateOperator INT NOT NULL,    
	StateValue nvarchar(50) NULL,  
	ZipCodeOperator INT NOT NULL,    
	ZipCodeValue   nvarchar(50) NULL  
	)    

	-- Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'     

	INSERT INTO @tmpForWhereClause    
	SELECT      
			ISNULL(MemberIDOperator,-1),    
			MemberIDValue ,    
			ISNULL(MemberNumberOperator,-1),    
			MemberNumberValue ,    
			ISNULL(PhoneNumberOperator,-1),    
			PhoneNumberValue ,    
			ISNULL(ProgramOperator,-1),    
			ProgramValue ,    
			ISNULL(LastNameOperator,-1),    
			LastNameValue ,    
			ISNULL(FirstNameOperator,-1),    
			FirstNameValue ,    
			ISNULL(VINOperator,-1),    
			VINValue ,    
			ISNULL(StateOperator,-1),    
			StateValue,    
			ISNULL(ZipCodeOperator,-1),    
			ZipCodeValue    
	FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (    
			MemberIDOperator INT,    
			MemberIDValue int     
			,MemberNumberOperator INT,    
			MemberNumberValue nvarchar(50)     
			,PhoneNumberOperator INT,    
			PhoneNumberValue nvarchar(50)     
			,ProgramOperator INT,    
			ProgramValue nvarchar(50)     
			,LastNameOperator INT,    
			LastNameValue nvarchar(50)     
			,FirstNameOperator INT,    
			FirstNameValue nvarchar(50)     
			,VINOperator INT,    
			VINValue nvarchar(50)     
			,StateOperator INT,    
			StateValue nvarchar(50)     
			,ZipCodeOperator INT,    
			ZipCodeValue nvarchar(50)   
	)     
	
	
	DECLARE @vinParam nvarchar(50)    
	SELECT @vinParam = VINValue FROM @tmpForWhereClause    

	DECLARE @memberEntityID INT  
	SELECT @memberEntityID = ID FROM Entity WHERE Name = 'Member'  
	--------------------- BEGIN -----------------------------    
	----   Create a temp variable or a CTE with the actual SQL search query ----------    
	----   and use that CTE in the place of <table> in the following SQL statements ---    
	--------------------- END -----------------------------    
	DECLARE @phoneNumber NVARCHAR(100)  
	SET @phoneNumber = (SELECT PhoneNumberValue FROM @tmpForWhereClause)  

	DECLARE @memberID INT
	DECLARE @memberNumber NVARCHAR(50)
	DECLARE @programCode NVARCHAR(50)
	DECLARE @firstName NVARCHAR(50)
	DECLARE @lastName NVARCHAR(50)
	DECLARE @state NVARCHAR(50)
	DECLARE @zip NVARCHAR(50)

	SELECT	@memberID = MemberIDValue,
			@memberNumber = MemberNumberValue,
			@programCode = ProgramValue,
			@firstName = FirstNameValue,
			@lastName = LastNameValue,
			@state = StateValue,
			@zip = ZipCodeValue
	FROM	@tmpForWhereClause

	
	SET FMTONLY OFF;  
	  
	IF @phoneNumber IS NULL  
	BEGIN  

	-- If vehicle is given, then let's use Vehicle in the left join (as the first table) else don't even consider vehicle table.

		IF @vinParam IS NOT NULL
		BEGIN

			SELECT	* 
			INTO	#TmpVehicle1
			FROM	Vehicle V WITH (NOLOCK)
			WHERE	V.VIN LIKE '%' + @vinParam + '%'


			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber-- PH.PhoneNumber AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber -- PW.PhoneNumber AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber -- PC.PhoneNumber AS CellPhoneNumber  
					, P.ID As ProgramID  -- KB: ADDED IDS
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate   
					, m.EffectiveDate 
					, v.VIN  
					, v.ID AS VehicleID
					, A.[StateProvinceID]
					,M.MiddleName 
					,M.ClientMemberType
			FROM #TmpVehicle1 v
			LEFT JOIN Member M WITH (NOLOCK) ON  (v.MemberID IS NULL OR v.MemberID = m.ID) 
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID AND v.MembershipID = MS.ID
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID   
			
			WHERE   ( @memberID IS NULL  OR @memberID = M.ID )
					 AND
					 (@memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%'
					 OR MS.AltMembershipNumber LIKE  '%' + @memberNumber + '%')    -- Lakshmi - Old Membership Search
					 AND
					 ( @zip is NULL OR A.PostalCode LIKE @zip +'%' )
					 AND
					 ( @programCode IS NULL OR P.Code = @programCode)
					 AND
					 ( @lastName IS NULL OR M.LastName LIKE @lastName + '%')
					 AND
					 ( @firstName IS NULL OR M.FirstName LIKE @firstName + '%')
					 AND
					 ( @vinParam IS NULL OR V.VIN LIKE '%' + @vinParam + '%')
					 AND
					 ( @state IS NULL OR A.StateProvinceID = @state)
			AND		ISNULL(M.IsActive,0) = 1
					 
			DROP TABLE #TmpVehicle1

		END -- End of Vin param check
		ELSE
		BEGIN

			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber-- PH.PhoneNumber AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber -- PW.PhoneNumber AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber -- PC.PhoneNumber AS CellPhoneNumber
					, P.ID As ProgramID  -- KB: ADDED IDS  
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate   
					, m.EffectiveDate 
					, '' AS VIN
					, NULL AS VehicleID
					, A.[StateProvinceID]
					,M.MiddleName 
					,M.ClientMemberType
			FROM Member M WITH (NOLOCK)  
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID   

			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID    
			
			WHERE   ( @memberID IS NULL  OR @memberID = M.ID )
					 AND
					 (@memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%'
					 OR MS.AltMembershipNumber LIKE  '%' + @memberNumber + '%')			-- Lakshmi - Old Membership Search
					 AND
					 ( @zip is NULL OR A.PostalCode LIKE @zip +'%' )
					 AND
					 ( @programCode IS NULL OR P.Code = @programCode)
					 AND
					 ( @lastName IS NULL OR M.LastName LIKE @lastName + '%')
					 AND
					 ( @firstName IS NULL OR M.FirstName LIKE @firstName + '%')
					 --AND
					 --( @vinParam IS NULL OR V.VIN LIKE '%' + @vinParam + '%')
					 AND
					 ( @state IS NULL OR A.StateProvinceID = @state)
			AND		ISNULL(M.IsActive,0) = 1
		END		
		
	END  -- End of Phone number is null check.
	ELSE  
	BEGIN
	
		SELECT *  
		INTO #tmpPhone  
		FROM PhoneEntity PH WITH (NOLOCK)  
		WHERE PH.EntityID = @memberEntityID   
		AND  PH.PhoneNumber = @phoneNumber   

		-- Consider VIN param.
		IF @vinParam IS NOT NULL
		BEGIN
		
			SELECT	* 
			INTO	#TmpVehicle
			FROM	Vehicle V WITH (NOLOCK)
			WHERE	V.VIN LIKE '%' + @vinParam + '%' 

			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber 
					, P.ID As ProgramID  -- KB: ADDED IDS 
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate 
					, m.EffectiveDate  
					, v.VIN
					, v.ID AS VehicleID
					, A.[StateProvinceID] 
					, M.MiddleName 
					, M.ClientMemberType
			FROM #TmpVehicle v
			LEFT JOIN Member M WITH (NOLOCK) ON  (v.MemberID IS NULL OR v.MemberID = m.ID) 
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID AND v.MembershipID = MS.ID
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID    
			--LEFT OUTER join Vehicle v WITH (NOLOCK) ON 
			--						(
			--							(v.MemberID IS NULL OR v.MemberID = m.ID) AND
			--								v.MembershipID = MS.ID

			--							--	(@vinParam IS NULL AND M.ID IS NULL) 
			--							--	OR
			--							--(@vinParam IS NOT NULL 
			--							--	AND 
			--							--	(v.MemberID = m.ID 
			--							--		OR (v.MembershipID = MS.ID AND v.MemberID IS NULL) 
			--							--		--AND V.VIN = @vinParam
			--							--	) 
			--							--) 
			--						)
			JOIN @tmpForWhereClause TMP ON 1=1  
			   
			WHERE  ( (@memberID IS NULL OR @memberID = M.ID)
					 AND
					 ( @memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%'
					 OR MS.AltMembershipNumber LIKE  '%' + @memberNumber + '%')						-- Lakshmi - Old Membership Search
					 AND
					 ( @zip is NULL OR A.PostalCode LIKE @zip +'%' )
					 AND
					 ( @programCode IS NULL OR P.Code = @programCode)
					 AND
					 ( @lastName IS NULL OR M.LastName LIKE @lastName + '%')
					 AND
					 ( @firstName IS NULL OR M.FirstName LIKE @firstName + '%')
					 AND
					 ( @vinParam IS NULL OR V.VIN LIKE '%' + @vinParam + '%')
					 AND
					 ( @state IS NULL OR A.StateProvinceID = @state)
				  )
			AND		ISNULL(M.IsActive,0) = 1

			DROP TABLE #TmpVehicle
		END -- End of Vin param check
		ELSE
		BEGIN
			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber  
					, P.ID As ProgramID  -- KB: ADDED IDS
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate
					, m.EffectiveDate   
					, '' AS VIN
					, NULL AS VehicleID  
					, A.[StateProvinceID] 
					, M.MiddleName 
					, M.ClientMemberType
			FROM	#tmpPhone PH
			JOIN	Member M WITH (NOLOCK)  ON PH.RecordID = M.ID
			JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID    

			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID    
			--LEFT OUTER join Vehicle v WITH (NOLOCK) ON 
			--						(
			--							(v.MemberID IS NULL OR v.MemberID = m.ID) AND
			--								v.MembershipID = MS.ID

			--							--	(@vinParam IS NULL AND M.ID IS NULL) 
			--							--	OR
			--							--(@vinParam IS NOT NULL 
			--							--	AND 
			--							--	(v.MemberID = m.ID 
			--							--		OR (v.MembershipID = MS.ID AND v.MemberID IS NULL) 
			--							--		--AND V.VIN = @vinParam
			--							--	) 
			--							--) 
			--						)
			JOIN @tmpForWhereClause TMP ON 1=1  
			   
			WHERE  ( (@memberID IS NULL OR @memberID = M.ID)
					 AND
					 ( @memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%'
					 OR MS.AltMembershipNumber LIKE  '%' + @memberNumber + '%')					-- Lakshmi - Old Membership Search
					 AND
					 ( @zip is NULL OR A.PostalCode LIKE @zip +'%' )
					 AND
					 ( @programCode IS NULL OR P.Code = @programCode)
					 AND
					 ( @lastName IS NULL OR M.LastName LIKE @lastName + '%')
					 AND
					 ( @firstName IS NULL OR M.FirstName LIKE @firstName + '%')
					 --AND
					 --( @vinParam IS NULL OR V.VIN LIKE '%' + @vinParam + '%')
					 AND
					 ( @state IS NULL OR A.StateProvinceID = @state)
				  )
			AND		ISNULL(M.IsActive,0) = 1
		END
	END  -- End of phone number not null check

	-- DEBUG:   
	--SELECT COUNT(*) AS Filtered FROM #FinalResultsFiltered  

	-- Do all computations  
	INSERT INTO #FinalResultsFormatted  
	SELECT   F.MemberID  
	, F.MembershipID  
	, F.MemberNumber     
	--, REPLACE(RTRIM(COALESCE(F.LastName, '')   
	-- + COALESCE(' ' + F.Suffix, '')   
	-- + COALESCE(', ' + F.FirstName, '')), ' ', ' ')   
	-- + COALESCE(' ' + F.Prefix, '') AS Name  
	,REPLACE(RTRIM( 
	COALESCE(F.FirstName, '') + 
	COALESCE(' ' + left(F.MiddleName,1), '') + 
	COALESCE(' ' + F.LastName, '') +
	COALESCE(' ' + F.Suffix, '')
	), ' ', ' ') AS MemberName
	,(ISNULL(F.City,'') + ',' + ISNULL(F.StateProvince,'') + ' ' + ISNULL(F.PostalCode,'')) AS [Address]     
	, COALESCE(F.HomePhoneNumber, F.WorkPhoneNumber, F.CellPhoneNumber, '') As PhoneNumber 
	, F.ProgramID -- KB: ADDED IDS    
	, F.Program    
	,(SELECT COUNT(*) FROM [Case] WHERE MemberID = F.MemberID) AS POCount   
	-- Ignore time while comparing the dates here  
	--,CASE WHEN F.EffectiveDate <= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0) AND F.ExpirationDate >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)   
	--  THEN 'Active'   
	--  ELSE 'Inactive'   
	-- END 
	-- KB: Considering Effective and Expiration Dates to calculate member status
	,CASE WHEN ISNULL(F.EffectiveDate,@minDate) <= @now AND ISNULL(F.ExpirationDate,@minDate) >= @now
			THEN 'Active'
			ELSE 'Inactive'
	END AS MemberStatus
	, F.LastName  
	, F.FirstName  
	,CASE WHEN ISNULL(@vinParam,'') <> ''    
	THEN  F.VIN    
	ELSE  ''    
	END AS VIN   
	, F.VehicleID  
	, F.StateProvinceID AS [State]  
	, F.PostalCode AS ZipCode  
	, F.ClientMemberType
	FROM #FinalResultsFiltered F  

	IF @phoneNumber IS NULL  
	BEGIN  

		INSERT INTO #FinalResultsSorted  
		SELECT  F.MemberID,  
		F.MembershipID,    
		F.MemberNumber,     
		F.Name,    
		F.[Address],    
		COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber,  
		F.ProgramID, -- KB: ADDED IDS     
		F.Program,    
		F.POCount,    
		F.MemberStatus,    
		F.LastName,    
		F.FirstName ,    
		F.VIN ,
		F.VehicleID,    
		F.[State] ,    
		F.ZipCode ,
		F.ClientMemberType
		FROM  #FinalResultsFormatted F   
		LEFT JOIN PhoneEntity PH WITH (NOLOCK) ON PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PH.PhoneNumber)  
		LEFT JOIN PhoneEntity PW WITH (NOLOCK) ON PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PW.PhoneNumber)  
		LEFT JOIN PhoneEntity PC WITH (NOLOCK) ON PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PC.PhoneNumber) 

		ORDER BY     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'    
		THEN F.MembershipID END ASC,     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'    
		THEN F.MembershipID END DESC ,    

		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'    
		THEN F.MemberNumber END ASC,     
		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'    
		THEN F.MemberNumber END DESC ,    

		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'    
		THEN F.Name END ASC,     
		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'    
		THEN F.Name END DESC ,    

		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'    
		THEN F.Address END ASC,     
		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'    
		THEN F.Address END DESC ,    

		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC ,    

		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,    

		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'    
		THEN F.POCount END ASC,     
		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'    
		THEN F.POCount END DESC ,    

		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'ASC'    
		THEN F.MemberStatus END ASC,     
		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'DESC'    
		THEN F.MemberStatus END DESC    

	END  
	ELSE  

	BEGIN  
	-- DEBUG  :SELECT COUNT(*) FROM #tmpPhone  

		INSERT INTO #FinalResultsSorted  
		SELECT  F.MemberID,  
		 F.MembershipID,    
		 F.MemberNumber,     
		 F.Name,    
		 F.[Address],    
		 COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber, 
		 F.ProgramID, --KB: ADDED IDS      
		 F.Program,    
		 F.POCount,    
		 F.MemberStatus,    
		 F.LastName,    
		 F.FirstName ,    
		F.VIN , 
		F.VehicleID,   
		F.[State] ,    
		F.ZipCode ,
		F.ClientMemberType
		FROM  #FinalResultsFormatted F   
		LEFT JOIN #tmpPhone PH WITH (NOLOCK) ON PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID 
		LEFT JOIN #tmpPhone PW WITH (NOLOCK) ON PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID 
		LEFT JOIN #tmpPhone PC WITH (NOLOCK) ON PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID 
		WHERE (PH.PhoneNumber = @phoneNumber OR PW.PhoneNumber = @phoneNumber OR PC.PhoneNumber=@phoneNumber)
		ORDER BY     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'    
		THEN F.MembershipID END ASC,     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'    
		THEN F.MembershipID END DESC ,    

		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'    
		THEN F.MemberNumber END ASC,     
		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'    
		THEN F.MemberNumber END DESC ,    

		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'    
		THEN F.Name END ASC,      
		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'    
		THEN F.Name END DESC ,    

		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'    
		THEN F.Address END ASC,     
		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'    
		THEN F.Address END DESC ,    

		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC ,    

		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,    

		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'    
		THEN F.POCount END ASC,     
		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'    
		THEN F.POCount END DESC ,    

		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'ASC'    
		THEN F.MemberStatus END ASC,     
		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'DESC'    
		THEN F.MemberStatus END DESC
		
		DROP TABLE #tmpPhone    
	END     
-- DEBUG:
--SELECT * FROM #FinalResultsSorted

	-- Let's delete duplicates from #FinalResultsSorted and then insert into Distinct.
	
	;WITH wSorted 
	AS
	(
		SELECT ROW_NUMBER() OVER (PARTITION BY 
			F.MemberID,  
			F.MembershipID,    
			F.MemberNumber,     
			F.Name,    
			F.[Address],    
			F.PhoneNumber,    
			F.Program,    
			F.POCount,    
			F.MemberStatus,    
			F.VIN,
			F.VehicleID ORDER BY F.RowNum) AS sRowNumber,
			F.ClientMemberType
		FROM #FinalResultsSorted F
	)
	
	DELETE FROM wSorted WHERE sRowNumber > 1
	
	INSERT INTO #FinalResultsDistinct(
			MemberID,  
			MembershipID,    
			MemberNumber,     
			Name,    
			[Address],    
			PhoneNumber,  
			ProgramID, -- KB: ADDED IDS      
			Program,    
			POCount,    
			MemberStatus,    
			VIN,
			VehicleID,
		   ClientMemberType
	)   
	SELECT	F.MemberID,  
			F.MembershipID,    
			F.MemberNumber,     
			F.Name,    
			F.[Address],    
			F.PhoneNumber,
			F.ProgramID, -- KB: ADDED IDS        
			F.Program,    
			F.POCount,    
			F.MemberStatus,    
			F.VIN,
			F.VehicleID,
			F.ClientMemberType
			
	FROM #FinalResultsSorted F
	ORDER BY 
	CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC,
		F.RowNum  
		

	DECLARE @count INT       
	SET @count = 0       
	SELECT @count = MAX(RowNum) FROM #FinalResultsDistinct   
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

IF @vinParam IS NULL
BEGIN
PRINT 'Gathering VIN Number'
	;WITH wForVIN
	AS(
	
		SELECT @count AS TotalRows, F.MemberID,  
		F.MembershipID,    
	   F.MemberNumber,     
	   F.Name,    
	   F.[Address],    
	   F.PhoneNumber,  
	   F.ProgramID, -- KB: ADDED IDS      
	   F.Program,    
	   F.POCount,    
	   F.MemberStatus,    
	   V.VIN,
	   F.VehicleID ,
	   F.ClientMemberType,
	   ROW_NUMBER() OVER (PARTITION BY F.MemberID, F.MembershipID ORDER BY V.CreateDate DESC) AS VRow,
	   V.CreateDate
	   FROM    #FinalResultsDistinct F
	   LEFT JOIN Vehicle V WITH (NOLOCK) ON (V.MemberID IS NULL OR V.MemberID = F.MemberID) AND V.MembershipID = F.MembershipID
	   WHERE RowNum BETWEEN @startInd AND @endInd 
	)
	
	SELECT @count AS TotalRows, F.MemberID,  
			F.MembershipID,    
			F.MemberNumber,     
			F.Name,    
			F.[Address],    
			F.PhoneNumber,  
			F.ProgramID, -- KB: ADDED IDS      
			F.Program,    
			F.POCount,    
			F.MemberStatus,    
			F.VIN,
			F.VehicleID ,
			F.ClientMemberType
	FROM	wForVIN F
	WHERE	F.VRow = 1
	
END
ELSE
BEGIN

	SELECT @count AS TotalRows, F.MemberID,  
		F.MembershipID,    
	   F.MemberNumber,     
	   F.Name,    
	   F.[Address],    
	   F.PhoneNumber,  
	   F.ProgramID, -- KB: ADDED IDS      
	   F.Program,    
	   F.POCount,    
	   F.MemberStatus,    
	   F.VIN,
	   F.VehicleID ,
	   F.ClientMemberType
	   FROM    
	   #FinalResultsDistinct F WHERE RowNum BETWEEN @startInd AND @endInd    
END	     
	DROP TABLE #FinalResultsFiltered  
	DROP TABLE #FinalResultsFormatted  
	DROP TABLE #FinalResultsSorted 
	DROP TABLE #FinalResultsDistinct


END

GO
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
 WHERE id = object_id(N'[dbo].[dms_Member_Mangement_SR_History_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_Mangement_SR_History_Get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_Member_Mangement_SR_History_Get @MemberID=3
 CREATE PROCEDURE [dbo].[dms_Member_Mangement_SR_History_Get]( 
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

GO

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
 WHERE id = object_id(N'[dbo].[dms_Merge_Members_Search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Merge_Members_Search]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Merge_Members_Search] @whereClauseXML=N'<ROW><Filter FirstNameOperator="4" FirstNameValue="jeevan"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=NULL
--EXEC [dbo].[dms_Merge_Members_Search] @whereClauseXML=N'<ROW><Filter PhoneNumberOperator="2" PhoneNumberValue="8173078882"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
--EXEC [dbo].[dms_Merge_Members_Search] @whereClauseXML=N'<ROW><Filter MemberNumberOperator="2" MemberNumberValue="123"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
-- EXEC [dbo].[dms_Merge_Members_Search] @whereClauseXML=N'<ROW><Filter VINOperator="4" VINValue="K1234422323N1233"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3

CREATE PROCEDURE [dbo].[dms_Merge_Members_Search](   
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10   
 , @sortColumn nvarchar(100)  = 'MemberNumber'   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @programID INT = NULL   
 )   
 AS   
 BEGIN   
    
	SET NOCOUNT ON    
SET FMTONLY OFF;
	-- KB : Temporary resultsets. These resultsets are used to prepare mangeable resultsets.
	CREATE TABLE #FinalResultsFiltered(     

	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	Suffix nvarchar(50)  NULL ,    
	Prefix nvarchar(50)  NULL ,    
	City nvarchar(50)  NULL ,    
	StateProvince nvarchar(50)  NULL ,    
	PostalCode nvarchar(50)  NULL ,    
	HomePhoneNumber nvarchar(50)  NULL ,    
	WorkPhoneNumber nvarchar(50)  NULL ,    
	CellPhoneNumber nvarchar(50)  NULL ,  
	ProgramID INT NULL, -- KB: ADDED IDS  
	Program nvarchar(50)  NULL ,    
	POCount INT NULL,  
	ExpirationDate DATETIME NULL,   
	EffectiveDate DATETIME NULL,
	VIN nvarchar(50)  NULL ,    
	VehicleID INT NULL, -- KB: Added VehicleID
	[StateProvinceID] INT  NULL,
	MiddleName   nvarchar(50)  NULL , 
	ClientMemberType nvarchar(200)  NULL 
	)    

	CREATE TABLE #FinalResultsFormatted(      
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,  
	VehicleID INT NULL, -- KB: Added VehicleID  
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL,
	ClientMemberType nvarchar(200)  NULL  
	)    

	CREATE TABLE #FinalResultsSorted(     
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL , 
	VehicleID INT NULL, -- KB: Added VehicleID   
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL,
	ClientMemberType nvarchar(200)  NULL   
	)  
	CREATE TABLE #FinalResultsDistinct(     
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,  
	VehicleID INT NULL, -- KB: Added VehicleID  
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL,
	ClientMemberType nvarchar(200)  NULL
	)  

	CREATE TABLE #SearchPrograms (
	ProgramID int, 
	ProgramName nvarchar(200),
	ClientID int
	)
	
	IF @programID IS NOT NULL
	BEGIN
	
	INSERT INTO #SearchPrograms (ProgramID, ProgramName, ClientID)
	SELECT ProgramID, ProgramName, ClientID
	--FROM [dbo].[fnc_GetMemberSearchPrograms](9) --@programID)
	FROM [dbo].[fnc_GetMemberSearchPrograms] (@programID)
	
	END
	ELSE
	BEGIN
		INSERT INTO #SearchPrograms (ProgramID, ProgramName, ClientID)
	    SELECT ID,Name,ClientID FROM Program
	END
	
	CREATE CLUSTERED INDEX IDX_SearchPrograms ON #SearchPrograms(ProgramID)
	--Select * From #SearchPrograms
	--Drop table #SearchPrograms
	
	DECLARE @idoc int    
	IF @whereClauseXML IS NULL     
	BEGIN    
	SET @whereClauseXML = '<ROW><Filter     
	MemberIDOperator="-1"     
	MemberNumberOperator="-1"     
	PhoneNumberOperator="-1"     
	ProgramOperator="-1"     
	LastNameOperator="-1"     
	FirstNameOperator="-1"     
	VINOperator="-1"     
	StateOperator="-1"    
	ZipCodeOperator = "-1"   
	></Filter></ROW>'    
	END    
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML    

	DECLARE @tmpForWhereClause TABLE    
	(    
	MemberIDOperator INT NOT NULL,    
	MemberIDValue int NULL,    
	MemberNumberOperator INT NOT NULL,    
	MemberNumberValue nvarchar(50) NULL,    
	PhoneNumberOperator INT NOT NULL,    
	PhoneNumberValue nvarchar(50) NULL,    
	ProgramOperator INT NOT NULL,    
	ProgramValue nvarchar(50) NULL,    
	LastNameOperator INT NOT NULL,    
	LastNameValue nvarchar(50) NULL,    
	FirstNameOperator INT NOT NULL,    
	FirstNameValue nvarchar(50) NULL,    
	VINOperator INT NOT NULL,    
	VINValue nvarchar(50) NULL,    
	StateOperator INT NOT NULL,    
	StateValue nvarchar(50) NULL,  
	ZipCodeOperator INT NOT NULL,    
	ZipCodeValue   nvarchar(50) NULL  
	)    

	-- Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'     

	INSERT INTO @tmpForWhereClause    
	SELECT      
			ISNULL(MemberIDOperator,-1),    
			MemberIDValue ,    
			ISNULL(MemberNumberOperator,-1),    
			MemberNumberValue ,    
			ISNULL(PhoneNumberOperator,-1),    
			PhoneNumberValue ,    
			ISNULL(ProgramOperator,-1),    
			ProgramValue ,    
			ISNULL(LastNameOperator,-1),    
			LastNameValue ,    
			ISNULL(FirstNameOperator,-1),    
			FirstNameValue ,    
			ISNULL(VINOperator,-1),    
			VINValue ,    
			ISNULL(StateOperator,-1),    
			StateValue,    
			ISNULL(ZipCodeOperator,-1),    
			ZipCodeValue    
	FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (    
			MemberIDOperator INT,    
			MemberIDValue int     
			,MemberNumberOperator INT,    
			MemberNumberValue nvarchar(50)     
			,PhoneNumberOperator INT,    
			PhoneNumberValue nvarchar(50)     
			,ProgramOperator INT,    
			ProgramValue nvarchar(50)     
			,LastNameOperator INT,    
			LastNameValue nvarchar(50)     
			,FirstNameOperator INT,    
			FirstNameValue nvarchar(50)     
			,VINOperator INT,    
			VINValue nvarchar(50)     
			,StateOperator INT,    
			StateValue nvarchar(50)     
			,ZipCodeOperator INT,    
			ZipCodeValue nvarchar(50)   
	)     
	
	
	DECLARE @vinParam nvarchar(50)    
	SELECT @vinParam = VINValue FROM @tmpForWhereClause    

	DECLARE @memberEntityID INT  
	SELECT @memberEntityID = ID FROM Entity WHERE Name = 'Member'  
	--------------------- BEGIN -----------------------------    
	----   Create a temp variable or a CTE with the actual SQL search query ----------    
	----   and use that CTE in the place of <table> in the following SQL statements ---    
	--------------------- END -----------------------------    
	DECLARE @phoneNumber NVARCHAR(100)  
	SET @phoneNumber = (SELECT PhoneNumberValue FROM @tmpForWhereClause)  

	DECLARE @memberID INT
	DECLARE @memberNumber NVARCHAR(50)
	DECLARE @programCode NVARCHAR(50)
	DECLARE @firstName NVARCHAR(50)
	DECLARE @lastName NVARCHAR(50)
	DECLARE @state NVARCHAR(50)
	DECLARE @zip NVARCHAR(50)

	SELECT	@memberID = MemberIDValue,
			@memberNumber = MemberNumberValue,
			@programCode = ProgramValue,
			@firstName = FirstNameValue,
			@lastName = LastNameValue,
			@state = StateValue,
			@zip = ZipCodeValue
	FROM	@tmpForWhereClause

	
	SET FMTONLY OFF;  
	  
	IF @phoneNumber IS NULL  
	BEGIN  

	-- If vehicle is given, then let's use Vehicle in the left join (as the first table) else don't even consider vehicle table.

		IF @vinParam IS NOT NULL
		BEGIN

			SELECT	* 
			INTO	#TmpVehicle1
			FROM	Vehicle V WITH (NOLOCK)
			WHERE	V.VIN LIKE '%' + @vinParam + '%'


			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber-- PH.PhoneNumber AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber -- PW.PhoneNumber AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber -- PC.PhoneNumber AS CellPhoneNumber  
					, P.ID As ProgramID  -- KB: ADDED IDS
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate   
					, m.EffectiveDate 
					, v.VIN  
					, v.ID AS VehicleID
					, A.[StateProvinceID]
					,M.MiddleName 
					,M.ClientMemberType
			FROM #TmpVehicle1 v
			LEFT JOIN Member M WITH (NOLOCK) ON  (v.MemberID IS NULL OR v.MemberID = m.ID) 
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID AND v.MembershipID = MS.ID
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID   
			
			WHERE   ( @memberID IS NULL  OR @memberID = M.ID )
					 AND
					 (@memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%')
					 AND
					 ( @zip is NULL OR A.PostalCode LIKE @zip +'%' )
					 AND
					 ( @programCode IS NULL OR P.Code = @programCode)
					 AND
					 ( @lastName IS NULL OR M.LastName LIKE @lastName + '%')
					 AND
					 ( @firstName IS NULL OR M.FirstName LIKE @firstName + '%')
					 AND
					 ( @vinParam IS NULL OR V.VIN LIKE '%' + @vinParam + '%')
					 AND
					 ( @state IS NULL OR A.StateProvinceID = @state)
			AND		ISNULL(M.IsActive,0) = 1
					 
			DROP TABLE #TmpVehicle1

		END -- End of Vin param check
		ELSE
		BEGIN

			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber-- PH.PhoneNumber AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber -- PW.PhoneNumber AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber -- PC.PhoneNumber AS CellPhoneNumber
					, P.ID As ProgramID  -- KB: ADDED IDS  
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate   
					, m.EffectiveDate 
					, '' AS VIN
					, NULL AS VehicleID
					, A.[StateProvinceID]
					,M.MiddleName 
					,M.ClientMemberType
			FROM Member M WITH (NOLOCK)  
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID   

			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID    
			
			WHERE   ( @memberID IS NULL  OR @memberID = M.ID )
					 AND
					 (@memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%')
					 AND
					 ( @zip is NULL OR A.PostalCode LIKE @zip +'%' )
					 AND
					 ( @programCode IS NULL OR P.Code = @programCode)
					 AND
					 ( @lastName IS NULL OR M.LastName LIKE @lastName + '%')
					 AND
					 ( @firstName IS NULL OR M.FirstName LIKE @firstName + '%')
					 --AND
					 --( @vinParam IS NULL OR V.VIN LIKE '%' + @vinParam + '%')
					 AND
					 ( @state IS NULL OR A.StateProvinceID = @state)
			AND		ISNULL(M.IsActive,0) = 1
		END		
		
	END  -- End of Phone number is null check.
	ELSE  
	BEGIN
	
		SELECT *  
		INTO #tmpPhone  
		FROM PhoneEntity PH WITH (NOLOCK)  
		WHERE PH.EntityID = @memberEntityID   
		AND  PH.PhoneNumber = @phoneNumber   

		-- Consider VIN param.
		IF @vinParam IS NOT NULL
		BEGIN
		
			SELECT	* 
			INTO	#TmpVehicle
			FROM	Vehicle V WITH (NOLOCK)
			WHERE	V.VIN LIKE '%' + @vinParam + '%' 

			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber 
					, P.ID As ProgramID  -- KB: ADDED IDS 
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate 
					, m.EffectiveDate  
					, v.VIN
					, v.ID AS VehicleID
					, A.[StateProvinceID] 
					, M.MiddleName 
					, M.ClientMemberType
			FROM #TmpVehicle v
			LEFT JOIN Member M WITH (NOLOCK) ON  (v.MemberID IS NULL OR v.MemberID = m.ID) 
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID AND v.MembershipID = MS.ID
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID    
			--LEFT OUTER join Vehicle v WITH (NOLOCK) ON 
			--						(
			--							(v.MemberID IS NULL OR v.MemberID = m.ID) AND
			--								v.MembershipID = MS.ID

			--							--	(@vinParam IS NULL AND M.ID IS NULL) 
			--							--	OR
			--							--(@vinParam IS NOT NULL 
			--							--	AND 
			--							--	(v.MemberID = m.ID 
			--							--		OR (v.MembershipID = MS.ID AND v.MemberID IS NULL) 
			--							--		--AND V.VIN = @vinParam
			--							--	) 
			--							--) 
			--						)
			JOIN @tmpForWhereClause TMP ON 1=1  
			   
			WHERE  ( (@memberID IS NULL OR @memberID = M.ID)
					 AND
					 ( @memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%')
					 AND
					 ( @zip is NULL OR A.PostalCode LIKE @zip +'%' )
					 AND
					 ( @programCode IS NULL OR P.Code = @programCode)
					 AND
					 ( @lastName IS NULL OR M.LastName LIKE @lastName + '%')
					 AND
					 ( @firstName IS NULL OR M.FirstName LIKE @firstName + '%')
					 AND
					 ( @vinParam IS NULL OR V.VIN LIKE '%' + @vinParam + '%')
					 AND
					 ( @state IS NULL OR A.StateProvinceID = @state)
				  )
			AND		ISNULL(M.IsActive,0) = 1

			DROP TABLE #TmpVehicle
		END -- End of Vin param check
		ELSE
		BEGIN
			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber  
					, P.ID As ProgramID  -- KB: ADDED IDS
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate
					, m.EffectiveDate   
					, '' AS VIN
					, NULL AS VehicleID  
					, A.[StateProvinceID] 
					, M.MiddleName 
					, M.ClientMemberType
			FROM	#tmpPhone PH
			JOIN	Member M WITH (NOLOCK)  ON PH.RecordID = M.ID
			JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID    

			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID    
			--LEFT OUTER join Vehicle v WITH (NOLOCK) ON 
			--						(
			--							(v.MemberID IS NULL OR v.MemberID = m.ID) AND
			--								v.MembershipID = MS.ID

			--							--	(@vinParam IS NULL AND M.ID IS NULL) 
			--							--	OR
			--							--(@vinParam IS NOT NULL 
			--							--	AND 
			--							--	(v.MemberID = m.ID 
			--							--		OR (v.MembershipID = MS.ID AND v.MemberID IS NULL) 
			--							--		--AND V.VIN = @vinParam
			--							--	) 
			--							--) 
			--						)
			JOIN @tmpForWhereClause TMP ON 1=1  
			   
			WHERE  ( (@memberID IS NULL OR @memberID = M.ID)
					 AND
					 ( @memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%')
					 AND
					 ( @zip is NULL OR A.PostalCode LIKE @zip +'%' )
					 AND
					 ( @programCode IS NULL OR P.Code = @programCode)
					 AND
					 ( @lastName IS NULL OR M.LastName LIKE @lastName + '%')
					 AND
					 ( @firstName IS NULL OR M.FirstName LIKE @firstName + '%')
					 --AND
					 --( @vinParam IS NULL OR V.VIN LIKE '%' + @vinParam + '%')
					 AND
					 ( @state IS NULL OR A.StateProvinceID = @state)
				  )
			AND		ISNULL(M.IsActive,0) = 1
		END
	END  -- End of phone number not null check

	-- DEBUG:   
	--SELECT COUNT(*) AS Filtered FROM #FinalResultsFiltered  

	-- Do all computations  
	INSERT INTO #FinalResultsFormatted  
	SELECT   F.MemberID  
	, F.MembershipID  
	, F.MemberNumber     
	--, REPLACE(RTRIM(COALESCE(F.LastName, '')   
	-- + COALESCE(' ' + F.Suffix, '')   
	-- + COALESCE(', ' + F.FirstName, '')), ' ', ' ')   
	-- + COALESCE(' ' + F.Prefix, '') AS Name  
	,REPLACE(RTRIM( 
	COALESCE(F.FirstName, '') + 
	COALESCE(' ' + left(F.MiddleName,1), '') + 
	COALESCE(' ' + F.LastName, '') +
	COALESCE(' ' + F.Suffix, '')
	), ' ', ' ') AS MemberName
	,(ISNULL(F.City,'') + ',' + ISNULL(F.StateProvince,'') + ' ' + ISNULL(F.PostalCode,'')) AS [Address]     
	, COALESCE(F.HomePhoneNumber, F.WorkPhoneNumber, F.CellPhoneNumber, '') As PhoneNumber 
	, F.ProgramID -- KB: ADDED IDS    
	, F.Program    
	,(SELECT COUNT(*) FROM [Case] WHERE MemberID = F.MemberID) AS POCount   
	-- Ignore time while comparing the dates here  
	--,CASE WHEN F.EffectiveDate <= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0) AND F.ExpirationDate >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)   
	--  THEN 'Active'   
	--  ELSE 'Inactive'   
	-- END 
	-- KB: Considering Effective and Expiration Dates to calculate member status
	,CASE WHEN ISNULL(F.EffectiveDate,@minDate) <= @now AND ISNULL(F.ExpirationDate,@minDate) >= @now
			THEN 'Active'
			ELSE 'Inactive'
	END AS MemberStatus
	, F.LastName  
	, F.FirstName  
	,CASE WHEN ISNULL(@vinParam,'') <> ''    
	THEN  F.VIN    
	ELSE  ''    
	END AS VIN   
	, F.VehicleID  
	, F.StateProvinceID AS [State]  
	, F.PostalCode AS ZipCode  
	, F.ClientMemberType
	FROM #FinalResultsFiltered F  

	IF @phoneNumber IS NULL  
	BEGIN  

		INSERT INTO #FinalResultsSorted  
		SELECT  F.MemberID,  
		F.MembershipID,    
		F.MemberNumber,     
		F.Name,    
		F.[Address],    
		COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber,  
		F.ProgramID, -- KB: ADDED IDS     
		F.Program,    
		F.POCount,    
		F.MemberStatus,    
		F.LastName,    
		F.FirstName ,    
		F.VIN ,
		F.VehicleID,    
		F.[State] ,    
		F.ZipCode ,
		F.ClientMemberType
		FROM  #FinalResultsFormatted F   
		LEFT JOIN PhoneEntity PH WITH (NOLOCK) ON PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PH.PhoneNumber)  
		LEFT JOIN PhoneEntity PW WITH (NOLOCK) ON PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PW.PhoneNumber)  
		LEFT JOIN PhoneEntity PC WITH (NOLOCK) ON PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PC.PhoneNumber) 

		ORDER BY     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'    
		THEN F.MembershipID END ASC,     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'    
		THEN F.MembershipID END DESC ,    

		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'    
		THEN F.MemberNumber END ASC,     
		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'    
		THEN F.MemberNumber END DESC ,    

		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'    
		THEN F.Name END ASC,     
		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'    
		THEN F.Name END DESC ,    

		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'    
		THEN F.Address END ASC,     
		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'    
		THEN F.Address END DESC ,    

		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC ,    

		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,    

		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'    
		THEN F.POCount END ASC,     
		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'    
		THEN F.POCount END DESC ,    

		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'ASC'    
		THEN F.MemberStatus END ASC,     
		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'DESC'    
		THEN F.MemberStatus END DESC    

	END  
	ELSE  

	BEGIN  
	-- DEBUG  :SELECT COUNT(*) FROM #tmpPhone  

		INSERT INTO #FinalResultsSorted  
		SELECT  F.MemberID,  
		 F.MembershipID,    
		 F.MemberNumber,     
		 F.Name,    
		 F.[Address],    
		 COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber, 
		 F.ProgramID, --KB: ADDED IDS      
		 F.Program,    
		 F.POCount,    
		 F.MemberStatus,    
		 F.LastName,    
		 F.FirstName ,    
		F.VIN , 
		F.VehicleID,   
		F.[State] ,    
		F.ZipCode ,
		F.ClientMemberType
		FROM  #FinalResultsFormatted F   
		LEFT JOIN #tmpPhone PH WITH (NOLOCK) ON PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID 
		LEFT JOIN #tmpPhone PW WITH (NOLOCK) ON PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID 
		LEFT JOIN #tmpPhone PC WITH (NOLOCK) ON PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID 
		WHERE (PH.PhoneNumber = @phoneNumber OR PW.PhoneNumber = @phoneNumber OR PC.PhoneNumber=@phoneNumber)
		ORDER BY     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'    
		THEN F.MembershipID END ASC,     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'    
		THEN F.MembershipID END DESC ,    

		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'    
		THEN F.MemberNumber END ASC,     
		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'    
		THEN F.MemberNumber END DESC ,    

		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'    
		THEN F.Name END ASC,      
		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'    
		THEN F.Name END DESC ,    

		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'    
		THEN F.Address END ASC,     
		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'    
		THEN F.Address END DESC ,    

		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC ,    

		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,    

		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'    
		THEN F.POCount END ASC,     
		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'    
		THEN F.POCount END DESC ,    

		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'ASC'    
		THEN F.MemberStatus END ASC,     
		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'DESC'    
		THEN F.MemberStatus END DESC
		
		DROP TABLE #tmpPhone    
	END     
-- DEBUG:
--SELECT * FROM #FinalResultsSorted

	-- Let's delete duplicates from #FinalResultsSorted and then insert into Distinct.
	
	;WITH wSorted 
	AS
	(
		SELECT ROW_NUMBER() OVER (PARTITION BY 
			F.MemberID,  
			F.MembershipID,    
			F.MemberNumber,     
			F.Name,    
			F.[Address],    
			F.PhoneNumber,    
			F.Program,    
			F.POCount,    
			F.MemberStatus,    
			F.VIN,
			F.VehicleID ORDER BY F.RowNum) AS sRowNumber,
			F.ClientMemberType
		FROM #FinalResultsSorted F
	)
	
	DELETE FROM wSorted WHERE sRowNumber > 1
	
	INSERT INTO #FinalResultsDistinct(
			MemberID,  
			MembershipID,    
			MemberNumber,     
			Name,    
			[Address],    
			PhoneNumber,  
			ProgramID, -- KB: ADDED IDS      
			Program,    
			POCount,    
			MemberStatus,    
			VIN,
			VehicleID,
		   ClientMemberType
	)   
	SELECT	F.MemberID,  
			F.MembershipID,    
			F.MemberNumber,     
			F.Name,    
			F.[Address],    
			F.PhoneNumber,
			F.ProgramID, -- KB: ADDED IDS        
			F.Program,    
			F.POCount,    
			F.MemberStatus,    
			F.VIN,
			F.VehicleID,
			F.ClientMemberType
			
	FROM #FinalResultsSorted F
	ORDER BY 
	CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC,
		F.RowNum  
		

	DECLARE @count INT       
	SET @count = 0       
	SELECT @count = MAX(RowNum) FROM #FinalResultsDistinct   
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


	IF @vinParam IS NULL
BEGIN
PRINT 'Gathering VIN Number'
	;WITH wForVIN
	AS(
	
		SELECT @count AS TotalRows, F.MemberID,  
		F.MembershipID,    
	   F.MemberNumber,     
	   F.Name,    
	   F.[Address],    
	   F.PhoneNumber,  
	   F.ProgramID, -- KB: ADDED IDS      
	   F.Program,    
	   F.POCount,    
	   F.MemberStatus,    
	   V.VIN,
	   F.VehicleID ,
	   F.ClientMemberType,
	   ROW_NUMBER() OVER (PARTITION BY F.MemberID, F.MembershipID ORDER BY V.CreateDate DESC) AS VRow,
	   V.CreateDate
	   FROM    #FinalResultsDistinct F
	   LEFT JOIN Vehicle V WITH (NOLOCK) ON (V.MemberID IS NULL OR V.MemberID = F.MemberID) AND V.MembershipID = F.MembershipID
	   WHERE RowNum BETWEEN @startInd AND @endInd 
	)
	
	SELECT @count AS TotalRows, F.MemberID,  
			F.MembershipID,    
			F.MemberNumber,     
			F.Name,    
			F.[Address],    
			F.PhoneNumber,  
			F.ProgramID, -- KB: ADDED IDS      
			F.Program,    
			F.POCount,    
			F.MemberStatus,    
			F.VIN,
			F.VehicleID ,
			F.ClientMemberType
	FROM	wForVIN F
	WHERE	F.VRow = 1
	
END
ELSE
BEGIN
	SELECT @count AS TotalRows, F.MemberID,  
		F.MembershipID,    
	   F.MemberNumber,     
	   F.Name,    
	   F.[Address],    
	   F.PhoneNumber,  
	   F.ProgramID, -- KB: ADDED IDS      
	   F.Program,    
	   F.POCount,    
	   F.MemberStatus,    
	   F.VIN,
	   F.VehicleID ,
	   F.ClientMemberType
	   FROM    
	   #FinalResultsDistinct F WHERE RowNum BETWEEN @startInd AND @endInd    
END     
	DROP TABLE #FinalResultsFiltered  
	DROP TABLE #FinalResultsFormatted  
	DROP TABLE #FinalResultsSorted 
	DROP TABLE #FinalResultsDistinct



END

GO
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
 -- EXEC [dbo].[dms_StartCall_MemberSelections] @memberIDCommaSeprated = '741,742,843,505'
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
  SET NOCOUNT OFF
  SET FMTONLY OFF

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

DECLARE @tmpForWhereClause AS TABLE
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

DECLARE @FinalResults AS TABLE( 
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
		POCount INT NULL,
		ClientMemberType nvarchar(200) NULL
) 

INSERT INTO @tmpForWhereClause
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
		POCount INT NULL,
		ClientMemberType nvarchar(200) NULL
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
					,M.ClientMemberType
			FROM Member M
			LEFT JOIN Membership MS WITH (NOLOCK) ON  M.MembershipID = MS.ID
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID AND A.RecordID IN (SELECT MemberID FROM @MemberIDValues) 
			LEFT JOIN #tmpPhone PH WITH (NOLOCK) ON PH.RecordID = M.ID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID 
			LEFT JOIN #tmpPhone PW WITH (NOLOCK) ON PW.RecordID = M.ID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID 
			LEFT JOIN #tmpPhone PC WITH (NOLOCK) ON PC.RecordID = M.ID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID 
			JOIN Program P WITH (NOLOCK) ON P.ID = M.ProgramID
			WHERE M.ID IN (SELECT MemberID FROM @MemberIDValues)

DROP TABLE #tmpPhone

PRINT 'Gathering VIN Number'
	;WITH wForVIN
	AS(
	
		SELECT T.MemberID,
		T.MembershipID,
		T.MembershipNumber,
		T.MemberName,
		T.Address,
		T.PhoneNumber,
		T.ProgramID,
		T.Program,
		V.VIN,
		T.MemberStatus,
		T.POCount,
		T.ClientMemberType,
	   ROW_NUMBER() OVER (PARTITION BY T.MemberID, T.MembershipID ORDER BY V.CreateDate DESC) AS VRow,
	   V.CreateDate
	   FROM    @QueryResult T
	   LEFT JOIN Vehicle V WITH (NOLOCK) ON (V.MemberID IS NULL OR V.MemberID = T.MemberID) AND V.MembershipID = T.MembershipID	   
	)

INSERT INTO @FinalResults
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
	T.POCount,
	T.ClientMemberType
FROM wForVIN T,
@tmpForWhereClause TMP 
WHERE T.VRow = 1
AND
( 

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

GO
/****** Object:  StoredProcedure [dbo].[dms_VendorLocation_PaymentTypes]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_VendorLocation_PaymentTypes]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_VendorLocation_PaymentTypes]
GO

-- EXEC dms_VendorLocation_PaymentTypes 316, 'VendorLocation'
CREATE PROC [dbo].[dms_VendorLocation_PaymentTypes](
@vendorLocationID INT = NULL,
@EntityName nvarchar(50)=''
)  
AS
BEGIN
DECLARE @result AS TABLE(
[ProductID] INT NOT NULL,
[Description] NVARCHAR(50),
[IsSelected] BIT DEFAULT 0
)

INSERT INTO @result
SELECT PT.ID,
         PT.Description,
         CASE WHEN VLPT.ID IS NULL THEN 0 ELSE 1 END IsSelected
FROM PaymentType PT
JOIN PaymentTypeEntity pte ON pte.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') 
      AND pte.PaymentTypeID = pt.ID
LEFT JOIN VendorLocationPaymentType VLPT ON VLPT.PaymentTypeID = PT.ID 
AND VLPT.IsActive = 1 
AND	ISNULL(PTE.IsShownOnScreen,0) = 1
AND VLPT.VendorLocationID = @vendorLocationID

WHERE 
            PT.IsActive = 1
ORDER BY 
            PT.Sequence
            
SELECT * FROM @result
END



GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Portal_Location_Services_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Portal_Location_Services_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 --EXEC dms_Vendor_Portal_Location_Services_List_Get @VendorID=1, @VendorLocationID=1
CREATE PROCEDURE [dms_Vendor_Portal_Location_Services_List_Get](
	@VendorID INT = NULL
 ,	@VendorLocationID INT = NULL
 )
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
DECLARE @FinalResults AS TABLE(
	SortOrder INT NULL,
	ServiceGroup NVARCHAR(255) NULL,
	ServiceName nvarchar(100)  NULL ,
	ProductID int  NULL ,
	VehicleCategorySequence int  NULL ,
	ProductCategory nvarchar(100)  NULL ,
	IsAvailByVendor bit default 0 ,
	IsAvailByVendorLocation bit default 0
) 

INSERT INTO @FinalResults (SortOrder, ServiceGroup,ServiceName,ProductID,VehicleCategorySequence,ProductCategory)
	SELECT 
			 CASE	WHEN vc.name is NULL THEN 2 
					ELSE 1 
			 END AS SortOrder
			,CASE	WHEN vc.name is NULL THEN 'Other' 
					ELSE vc.name 
			 END AS ServiceGroup
			,REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
			--,ISNULL(vc.Name,'') + CASE WHEN ISNULL(vc.Name,'') <> '' THEN ' - ' ELSE '' END  + REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory			
	FROM Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
	LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('PrimaryService', 'SecondaryService')
	AND p.Name Not in ('Concierge', 'Information', 'Tech')
	AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee')

	UNION
	SELECT 
			3 AS SortOrder
			,'Additional' AS ServiceGroup
			,p.Name AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory
	FROM	Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
	LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('AdditionalService')
	AND p.Name Not in ('Concierge', 'Information', 'Tech')
	AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials')
	
	UNION ALL
	
	SELECT 
			 4 AS SortOrder
			,'Repair' AS ServiceGroup
			, p.Name AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory
	FROM	Product p
	Join	ProductCategory pc on p.productCategoryid = pc.id
	Join	ProductType pt on p.ProductTypeID = pt.ID
	Join	ProductSubType pst on p.ProductSubTypeID = pst.id
	Left Outer Join VehicleCategory vc on p.VehicleCategoryID = vc.ID
	Left Outer Join VehicleType vt on p.VehicleTypeID = vt.ID
	Where	pt.Name = 'Attribute'
	and		pc.Name = 'Repair'
	and		pst.Name NOT IN ('Client')	
	ORDER BY SortOrder, VehicleCategorySequence, ProductCategory
	
	UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
	LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
	WHERE VP.VendorID=@VendorID

	UPDATE @FinalResults SET IsAvailByVendorLocation = 1 FROM  @FinalResults T
	LEFT JOIN VendorLocationProduct VLP ON VLP.ProductID = T.ProductID
	WHERE VLP.VendorLocationID=@VendorLocationID

	SELECT *  FROM @FinalResults WHERE IsAvailByVendor=1 OR IsAvailByVendorLocation = 1
END
GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Portal_Services_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Portal_Services_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 --EXEC dms_Vendor_Services_List_Get @VendorID=1
CREATE PROCEDURE [dbo].[dms_Vendor_Portal_Services_List_Get] @VendorID INT
AS
BEGIN
      -- SET NOCOUNT ON added to prevent extra result sets from
      -- interfering with SELECT statements.
      SET NOCOUNT ON;
DECLARE @FinalResults AS TABLE(
      SortOrder INT NULL,
      ServiceGroup NVARCHAR(255) NULL,
      ServiceName nvarchar(100)  NULL ,
      ProductID int  NULL ,
      VehicleCategorySequence int  NULL ,
      ProductCategory nvarchar(100)  NULL ,
      IsAvailByVendor bit default 0
) 

INSERT INTO @FinalResults (SortOrder, ServiceGroup,ServiceName,ProductID,VehicleCategorySequence,ProductCategory)
      SELECT 
                   CASE WHEN vc.name is NULL THEN 2 
                              ELSE 1 
                   END AS SortOrder
                  ,CASE WHEN vc.name is NULL THEN 'Other' 
                              ELSE vc.name 
                   END AS ServiceGroup
                  ,REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
                  --,ISNULL(vc.Name,'') + CASE WHEN ISNULL(vc.Name,'') <> '' THEN ' - ' ELSE '' END  + REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
                  ,p.ID AS ProductID
                  ,vc.Sequence VehicleCategorySequence
                  ,pc.Name ProductCategory                  
      FROM Product p
      JOIN ProductCategory pc on p.productCategoryid = pc.id
      JOIN ProductType pt on p.ProductTypeID = pt.ID
      JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
      LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
      LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
      WHERE pt.Name = 'Service'
      AND pst.Name IN ('PrimaryService', 'SecondaryService')
      AND p.Name Not in ('Concierge', 'Information', 'Tech')
      AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee','Tow - LD - Lamborghini','Tow - LD - White Glove')

      UNION
      SELECT 
                  3 AS SortOrder
                  ,'Additional' AS ServiceGroup
                  ,p.Name AS ServiceName
                  ,p.ID AS ProductID
                  ,vc.Sequence VehicleCategorySequence
                  ,pc.Name ProductCategory
      FROM  Product p
      JOIN ProductCategory pc on p.productCategoryid = pc.id
      JOIN ProductType pt on p.ProductTypeID = pt.ID
      JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
      LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
      LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
      WHERE pt.Name = 'Service'
      AND pst.Name IN ('AdditionalService')
      AND p.Name Not in ('Concierge', 'Information', 'Tech')
      AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials','Diagnostics','Storage Fee - Auto','Storage Fee - RV') 
      
      --UNION
      --SELECT 
      --            4 AS SortOrder
      --            ,'ISP Selection' AS ServiceGroup
      --            ,p.Name AS ServiceName
      --            ,p.ID AS ProductID
      --            ,vc.Sequence VehicleCategorySequence
      --            ,pc.Name ProductCategory
      --FROM  Product p
      --JOIN ProductCategory pc on p.productCategoryid = pc.id
      --JOIN ProductType pt on p.ProductTypeID = pt.ID
      --JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
      --LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
      --LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
      --WHERE pt.Name = 'Attribute'
      --AND pst.Name = 'Ranking'
      --AND pc.Name = 'ISPSelection'
      
      UNION ALL
      
      SELECT 
                  5 AS SortOrder
                  ,pst.Name AS ServiceGroup 
                  ,p.Name AS ServiceName
                  ,p.ID AS ProductID
                  ,vc.Sequence VehicleCategorySequence
                  ,pc.Name ProductCategory
      FROM Product p
      Join ProductCategory pc on p.productCategoryid = pc.id
      Join ProductType pt on p.ProductTypeID = pt.ID
      Join ProductSubType pst on p.ProductSubTypeID = pst.id
      Left Outer Join VehicleCategory vc on p.VehicleCategoryID = vc.ID
      Left Outer Join VehicleType vt on p.VehicleTypeID = vt.ID
      Where pt.Name = 'Attribute'
      and pc.Name = 'Repair'
      --and pst.Name NOT IN ('Client')
      ORDER BY SortOrder, VehicleCategorySequence, ProductCategory
      

UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
WHERE VP.VendorID=@VendorID
      
SELECT * FROM @FinalResults

END
GO

GO
-- Select * From [dbo].[fnGetPreferredVendorsByProduct]() Where VendorID = 4360   
CREATE FUNCTION [dbo].[fnGetPreferredVendorsByProduct] ()  
RETURNS TABLE   
AS  
RETURN   
(  
	Select v.ID VendorID, Preferred.ProductID, Preferred.PreferredCategory  
	From vendor v
	Join VendorProduct vp on vp.VendorID = v.ID
	Join Product p on p.ID = vp.ProductID
	Join ProductCategory pc on pc.ID = p.ProductCategoryID
	Join ProductType pt on pt.ID = p.ProductTypeID
	Join ProductSubType pst on pst.ID = p.ProductSubTypeID
	Join (
		Select p.ID ProductID
			--, pc.Name, p.Name,
			,Case 
				 When pc.Name In ('Tow','Winch') And vc.Name = 'HeavyDuty'  Then 'Preferred - HD Tow'
				 When pc.Name In ('Tow','Winch') And vc.Name = 'MediumDuty' Then 'Preferred - MD Tow'
				 When pc.Name In ('Tow','Winch') And vc.Name = 'LightDuty'  Then 'Preferred - LD Tow'
				 When vc.Name = 'HeavyDuty'  Then 'Preferred - HD Service Call'
				 When vc.Name = 'MediumDuty' Then 'Preferred - MD Service Call'
				 Else 'Preferred - LD Service Call'
				 End PreferredCategory
			--,p.Name, pst.Name, pc.Name, vc.Name, p.*
		From Product p
		Join ProductCategory pc on pc.ID = p.ProductCategoryID
		Join ProductType pt on pt.ID = p.ProductTypeID
		Join ProductSubType pst on pst.ID = p.ProductSubTypeID
		Left Outer Join VehicleCategory vc on vc.ID = p.VehicleCategoryID
		Where pst.Name IN ('PrimaryService','SecondaryService')
		and pc.Name not in ('Mobile','Home Locksmith')
		and p.IsShowOnPO = 1
		) Preferred on Preferred.PreferredCategory = p.Name
	Where pc.Name = 'ISPSelection'
	and pt.Name = 'Attribute'
	and pst.Name = 'Ranking'
)  





GO
