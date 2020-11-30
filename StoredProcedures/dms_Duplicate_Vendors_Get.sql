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
