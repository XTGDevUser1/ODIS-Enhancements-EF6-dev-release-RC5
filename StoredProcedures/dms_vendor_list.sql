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
 WHERE id = object_id(N'[dbo].[dms_vendor_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_vendor_list] @pageSize=5000, @whereClauseXML="<ROW><Filter VendorNameOperator='Begins With' VendorNameValue='Royal'/></ROW>"
 
 CREATE PROCEDURE [dbo].[dms_vendor_list](   
 @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = 'VendorName' 
 , @sortOrder nvarchar(100) = 'ASC'
 ) 

 AS 

 BEGIN   
 SET FMTONLY OFF  
  SET NOCOUNT ON  
  
CREATE TABLE #FinalResultsFiltered  
(  
 ContractStatus NVARCHAR(100) NULL,  
 VendorID INT NULL,  
 VendorNumber NVARCHAR(50) NULL,  
 VendorName NVARCHAR(255) NULL,  
 City NVARCHAR(100) NULL,  
 StateProvince NVARCHAR(10) NULL,  
 CountryCode NVARCHAR(2) NULL,  
 OfficePhone NVARCHAR(50) NULL,  
 AdminRating INT NULL,  
 InsuranceExpirationDate DATETIME NULL,  
 PaymentMethod NVARCHAR(50) NULL,  
 VendorStatus NVARCHAR(50) NULL,  
 VendorRegion NVARCHAR(50) NULL,  
 PostalCode NVARCHAR(20) NULL  ,
 POCount INT NULL
)  
  
CREATE TABLE #FinalResultsSorted  
(  
 RowNum BIGINT NOT NULL IDENTITY(1,1),  
 ContractStatus NVARCHAR(100) NULL,  
 VendorID INT NULL,  
 VendorNumber NVARCHAR(50) NULL,  
 VendorName NVARCHAR(255) NULL,  
 City NVARCHAR(100) NULL,  
 StateProvince NVARCHAR(10) NULL,  
 CountryCode NVARCHAR(2) NULL,  
 OfficePhone NVARCHAR(50) NULL,  
 AdminRating INT NULL,  
 InsuranceExpirationDate DATETIME NULL,  
 PaymentMethod NVARCHAR(50) NULL,  
 VendorStatus NVARCHAR(50) NULL,  
 VendorRegion NVARCHAR(50) NULL,  
 PostalCode NVARCHAR(20) NULL ,
 POCount INT NULL 
)  
  
CREATE TABLE #wVendorAddresses(
	[RowNum] [int] NOT NULL,
	[ID] [int] NOT NULL,
	[EntityID] [int] NULL,
	[RecordID] [int] NULL,
	[AddressTypeID] [int] NULL,
	[Line1] [nvarchar](100) NULL,
	[Line2] [nvarchar](100) NULL,
	[Line3] [nvarchar](100) NULL,
	[City] [nvarchar](100) NULL,
	[StateProvince] [nvarchar](10) NULL,
	[PostalCode] [nvarchar](20) NULL,
	[StateProvinceID] [int] NULL,
	[CountryID] [int] NULL,
	[CountryCode] [nvarchar](2) NULL,
	[CreateBatchID] [int] NULL,
	[CreateDate] [datetime] NULL,
	[CreateBy] [nvarchar](50) NULL,
	[ModifyBatchID] [int] NULL,
	[ModifyDate] [datetime] NULL,
	[ModifyBy] [nvarchar](50) NULL 
) 
CREATE TABLE #wVendorPhone(
	[RowNum] [int] NOT NULL,
	[ID] [int] NOT NULL,
	[EntityID] [int] NOT NULL,
	[RecordID] [int] NOT NULL,
	[PhoneTypeID] [int] NULL,
	[PhoneNumber] [nvarchar](50) NULL,
	[IndexPhoneNumber] [int] NULL,
	[Sequence] [int] NULL,
	[CreateBatchID] [int] NULL,
	[CreateDate] [datetime] NULL,
	[CreateBy] [nvarchar](50) NULL,
	[ModifyBatchID] [int] NULL,
	[ModifyDate] [datetime] NULL,
	[ModifyBy] [nvarchar](50) NULL
)


DECLARE @idoc int  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
VendorNameOperator NVARCHAR(50) NULL,  
VendorName NVARCHAR(MAX) NULL,  
VendorNumber NVARCHAR(50) NULL,  
CountryID INT NULL,  
StateProvinceID INT NULL,  
City nvarchar(255) NULL,  
VendorStatus NVARCHAR(100) NULL,  
VendorRegion NVARCHAR(100) NULL,  
PostalCode NVARCHAR(20) NULL,  
IsLevy BIT NULL  ,
HasPO BIT NULL,
IsFordDirectTow BIT NULL,
IsCNETDirectPartner BIT NULL
)  
  
DECLARE @VendorNameOperator NVARCHAR(50) ,  
@VendorName NVARCHAR(MAX) ,  
@VendorNumber NVARCHAR(50) ,  
@CountryID INT ,  
@StateProvinceID INT ,  
@City nvarchar(255) ,  
@VendorStatus NVARCHAR(100) ,  
@VendorRegion NVARCHAR(100) ,  
@PostalCode NVARCHAR(20) ,  
@IsLevy BIT,
@HasPO BIT   ,
@programID INT	= NULL,
@IsFordDirectTow BIT,
@IsCNETDirectPartner BIT
  
INSERT INTO @tmpForWhereClause  
SELECT    
 VendorNameOperator,  
 VendorName ,  
 VendorNumber,  
 CountryID,  
 StateProvinceID,  
 City,  
 VendorStatus,  
 VendorRegion,  
    PostalCode,  
    IsLevy ,
	HasPo,
	IsFordDirectTow,
	IsCNETDirectPartner
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
 VendorNameOperator NVARCHAR(50),  
 VendorName NVARCHAR(MAX),  
 VendorNumber NVARCHAR(50),   
 CountryID INT,  
 StateProvinceID INT,  
 City nvarchar(255),   
 VendorStatus NVARCHAR(100),  
 VendorRegion NVARCHAR(100),  
 PostalCode NVARCHAR(20),  
 IsLevy BIT ,
 HasPo BIT,
 IsFordDirectTow BIT,
 IsCNETDirectPartner BIT
)   
  
SELECT    
  @VendorNameOperator = VendorNameOperator ,  
  @VendorName = VendorName ,  
  @VendorNumber = VendorNumber,  
  @CountryID = CountryID,  
  @StateProvinceID = StateProvinceID,  
  @City = City,  
  @VendorStatus = VendorStatus,  
  @VendorRegion = VendorRegion,  
  @PostalCode = PostalCode,  
  @IsLevy = IsLevy  ,
  @HasPO = HasPO,
  @IsFordDirectTow = IsFordDirectTow,
  @IsCNETDirectPartner = IsCNETDirectPartner
FROM @tmpForWhereClause  
  
--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
-- LOGIC : START  

--DECLARE @PoCount AS TABLE(VendorID INT NULL,PoCount INT NULL)
CREATE TABLE #PoCount 
(
	VendorID INT NULL,
	PoCount INT NULL
)
INSERT INTO #PoCount
SELECT V.ID,
	   COUNT(PO.ID) FROM PurchaseOrder PO 
	   LEFT JOIN VendorLocation VL ON PO.VendorLocationID = VL.ID
	   LEFT JOIN Vendor V ON VL.VendorID = V.ID
WHERE  PO.IsActive = 1
GROUP BY V.ID 
  
DECLARE @vendorEntityID INT, @businessAddressTypeID INT, @officePhoneTypeID INT  
SELECT @vendorEntityID = ID FROM Entity WHERE Name = 'Vendor'  
SELECT @businessAddressTypeID = ID FROM AddressType WHERE Name = 'Business'  
SELECT @officePhoneTypeID = ID FROM PhoneType WHERE Name = 'Office'    

-- KB: The following statements are causing performance issues.
/*INSERT INTO #wVendorAddresses
SELECT	ROW_NUMBER() OVER ( PARTITION BY RecordID, AddressTypeID ORDER BY ID ) AS RowNum,  
		*  
FROM	AddressEntity   
WHERE	EntityID = @vendorEntityID  
AND		AddressTypeID = @businessAddressTypeID  

INSERT INTO #wVendorPhone
SELECT ROW_NUMBER() OVER ( PARTITION BY RecordID, PhoneTypeID ORDER BY ID DESC ) AS RowNum,
			*
FROM	PhoneEntity 
WHERE	EntityID = @vendorEntityID
AND		PhoneTypeID = @officePhoneTypeID
*/

DECLARE @sql NVARCHAR(MAX) = ''

SET @sql = @sql + '  SELECT DISTINCT    '
SET @sql = @sql + '   CASE WHEN ContractedVendors.VendorID IS NOT NULL THEN ''Contracted'' ELSE ''Not Contracted'' END AS ContractStatus  '
SET @sql = @sql + '   , V.ID AS VendorID  '
SET @sql = @sql + '   , V.VendorNumber AS VendorNumber    '
SET @sql = @sql + '   , v.Name + COALESCE(F.Indicators,'''') AS VendorName '
SET @sql = @sql + '   , AE.City AS City  '
SET @sql = @sql + '   , AE.StateProvince AS State  '
SET @sql = @sql + '   , AE.CountryCode AS Country  '
SET @sql = @sql + '   , PE.PhoneNumber AS OfficePhone  '
SET @sql = @sql + '   , V.AdministrativeRating AS AdminRating ' 
SET @sql = @sql + '   , V.InsuranceExpirationDate AS InsuranceExpirationDate  '
SET @sql = @sql + '   , VACH.BankABANumber AS PaymentMethod '-- To be calculated in the next step.  
SET @sql = @sql + '   , VS.Name AS VendorStatus  '
SET @sql = @sql + '   , VR.Name AS VendorRegion  '
SET @sql = @sql + '   , AE.PostalCode  '
SET @sql = @sql + '   , ISNULL((SELECT PoCount FROM #PoCount POD WHERE POD.VendorID = V.ID),0) AS POCount'
SET @sql = @sql + ' FROM Vendor V WITH (NOLOCK)  '
SET @sql = @sql + ' LEFT JOIN [dbo].[fnc_GetVendorIndicators](''Vendor'') F ON V.ID = F.RecordID'
SET @sql = @sql + ' LEFT JOIN [dbo].[fnGetDirectTowVendors]() VPFDT ON VPFDT.VendorID = V.ID'
SET @sql = @sql + ' LEFT JOIN [dbo].[fnGetCoachNetDealerPartnerVendors]() VPCNDP ON VPCNDP.VendorID = V.ID'
SET @sql = @sql + ' LEFT JOIN AddressEntity AE ON AE.RecordID = V.ID AND AE.EntityID = @vendorEntityID AND AE.AddressTypeID = @businessAddressTypeID ' 
SET @sql = @sql + ' LEFT JOIN PhoneEntity PE ON PE.RecordID = V.ID AND PE.EntityID = @vendorEntityID AND PE.PhoneTypeID = @officePhoneTypeID ' 
SET @sql = @sql + ' LEFT JOIN VendorStatus VS ON VS.ID = V.VendorStatusID  '
SET @sql = @sql + ' LEFT JOIN VendorACH VACH ON VACH.VendorID = V.ID  '
SET @sql = @sql + ' LEFT JOIN VendorRegion VR ON VR.ID=V.VendorRegionID  '
SET @sql = @sql + ' LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID ' 
SET @sql = @sql + ' WHERE V.IsActive = 1 ' -- Not deleted  

IF @VendorNumber IS NOT NULL
BEGIN
	SET @sql = @sql + ' AND  @VendorNumber = V.VendorNumber '
END
  
IF @CountryID IS NOT NULL
BEGIN
	SET @sql = @sql + ' AND  @CountryID = AE.CountryID '
END

IF @StateProvinceID IS NOT NULL
BEGIN
	SET @sql = @sql + ' AND  @StateProvinceID = AE.StateProvinceID '
END

IF @City IS NOT NULL
BEGIN
	SET @sql = @sql + ' AND  @City = AE.City '  
END

IF @PostalCode IS NOT NULL
BEGIN
	SET @sql = @sql + ' AND  @PostalCode = AE.PostalCode '
END

IF @IsLevy IS NOT NULL
BEGIN
	SET @sql = @sql + ' AND  @IsLevy = ISNULL(V.IsLevyActive,0) '
END

IF @IsFordDirectTow IS NOT NULL
BEGIN
	SET @sql = @sql + ' AND  (@IsFordDirectTow = 1 AND COALESCE(F.Indicators,'') LIKE ''%(DT)%'') '  
END

IF @IsCNETDirectPartner IS NOT NULL
BEGIN
	SET @sql = @sql + ' AND  ((@IsCNETDirectPartner = 1 AND COALESCE(F.Indicators,'') LIKE ''%(P)%''))  '
END
IF @VendorStatus IS NOT NULL
BEGIN
	SET @sql = @sql + ' AND  (VS.ID IN (SELECT Item FROM [dbo].[fnSplitString](@VendorStatus,'','') ) )  '
END

IF @VendorRegion IS NOT NULL
BEGIN
	SET @sql = @sql + ' AND  ( VR.ID IN (SELECT Item FROM [dbo].[fnSplitString](@VendorRegion,'','') ) )  '
END

IF @VendorNameOperator IS NOT NULL
BEGIN
	SET @sql = @sql + ' AND  (    '
	IF @VendorNameOperator = 'Begins with'
	BEGIN
		SET @sql = @sql + '    (V.Name LIKE  @VendorName + ''%'') '  
	END
	IF @VendorNameOperator = 'Is equal to'
	BEGIN
		SET @sql = @sql + '    (V.Name =  @VendorName )  '
	END
	IF @VendorNameOperator = 'Ends with' 
	BEGIN 
		SET @sql = @sql + '    (V.Name LIKE  ''%'' + @VendorName)  '
	END

	IF @VendorNameOperator = 'Contains'
	BEGIN
		SET @sql = @sql + '    (V.Name LIKE  ''%'' + @VendorName + ''%'') '  
	END
	SET @sql = @sql + '   )  '
END

--SELECT @sql

INSERT INTO #FinalResultsFiltered  
EXEC sp_executesql @sql, N'@vendorEntityID INT, @businessAddressTypeID INT, @officePhoneTypeID INT, @VendorNumber NVARCHAR(50), @CountryID INT, @StateProvinceID INT, @City NVARCHAR(255), @PostalCode NVARCHAR(50),@IsLevy BIT, @IsFordDirectTow BIT, @IsCNETDirectPartner BIT, @VendorStatus NVARCHAR(50), @VendorRegion NVARCHAR(100), @VendorName NVARCHAR(MAX)', @vendorEntityID,@businessAddressTypeID, @officePhoneTypeID, @VendorNumber, @CountryID, @StateProvinceID, @City, @PostalCode, @IsLevy, @IsFordDirectTow, @IsCNETDirectPartner, @VendorStatus, @VendorRegion,@VendorName
 
 ;WITH wDistinctVendors
 AS
 (
	SELECT ROW_NUMBER() OVER (PARTITION BY VendorID ORDER BY VendorID) As RowNum,
			*
	FROM	#FinalResultsFiltered
 )
 
 INSERT INTO #FinalResultsSorted  
 SELECT   ContractStatus  
  , VendorID  
  , VendorNumber  
  , VendorName  
  , City  
  , StateProvince  
  , CountryCode  
  , OfficePhone  
  , AdminRating  
  , InsuranceExpirationDate  
  , PaymentMethod  
  , VendorStatus  
  , VendorRegion  
  , PostalCode  
  , POCount
 FROM wDistinctVendors T   
 WHERE	 T.RowNum = 1 AND (@HasPO IS NULL OR @HasPO = 0 OR T.POCount > 0)
 ORDER BY   
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'ASC'  
  THEN T.ContractStatus END ASC,   
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'DESC'  
  THEN T.ContractStatus END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'ASC'  
  THEN T.VendorID END ASC,   
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'DESC'  
  THEN T.VendorID END DESC ,  
    
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'  
  THEN T.VendorNumber END ASC,   
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'  
  THEN T.VendorNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'ASC'  
  THEN T.VendorName END ASC,   
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'DESC'  
  THEN T.VendorName END DESC ,  
  
  CASE WHEN @sortColumn = 'City' AND @sortOrder = 'ASC'  
  THEN T.City END ASC,   
  CASE WHEN @sortColumn = 'City' AND @sortOrder = 'DESC'  
  THEN T.City END DESC ,  
    
  CASE WHEN @sortColumn = 'StateProvince' AND @sortOrder = 'ASC'  
  THEN T.StateProvince END ASC,   
  CASE WHEN @sortColumn = 'StateProvince' AND @sortOrder = 'DESC'  
  THEN T.StateProvince END DESC ,  
  
  CASE WHEN @sortColumn = 'CountryCode' AND @sortOrder = 'ASC'  
  THEN T.CountryCode END ASC,   
  CASE WHEN @sortColumn = 'CountryCode' AND @sortOrder = 'DESC'  
  THEN T.CountryCode END DESC ,  
    
  CASE WHEN @sortColumn = 'OfficePhone' AND @sortOrder = 'ASC'  
  THEN T.OfficePhone END ASC,   
  CASE WHEN @sortColumn = 'OfficePhone' AND @sortOrder = 'DESC'  
  THEN T.OfficePhone END DESC ,  
    
  CASE WHEN @sortColumn = 'AdminRating' AND @sortOrder = 'ASC'  
  THEN T.AdminRating END ASC,   
  CASE WHEN @sortColumn = 'AdminRating' AND @sortOrder = 'DESC'  
  THEN T.AdminRating END DESC ,  
    
  CASE WHEN @sortColumn = 'InsuranceExpirationDate' AND @sortOrder = 'ASC'  
  THEN T.InsuranceExpirationDate END ASC,   
  CASE WHEN @sortColumn = 'InsuranceExpirationDate' AND @sortOrder = 'DESC'  
  THEN T.InsuranceExpirationDate END DESC ,  
    
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'ASC'  
  THEN T.VendorStatus END ASC,   
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'DESC'  
  THEN T.VendorStatus END DESC ,  
    
  CASE WHEN @sortColumn = 'VendorRegion' AND @sortOrder = 'ASC'  
  THEN T.VendorRegion END ASC,   
  CASE WHEN @sortColumn = 'VendorRegion' AND @sortOrder = 'DESC'  
  THEN T.VendorRegion END DESC ,  
  --VendorRegion  
  CASE WHEN @sortColumn = 'PaymentMethod' AND @sortOrder = 'ASC'  
  THEN T.PaymentMethod END ASC,   
  CASE WHEN @sortColumn = 'PaymentMethod' AND @sortOrder = 'DESC'  
  THEN T.PaymentMethod END DESC ,  
     
  CASE WHEN @sortColumn = 'PostalCode' AND @sortOrder = 'ASC'  
  THEN T.PostalCode END ASC,   
  CASE WHEN @sortColumn = 'PostalCode' AND @sortOrder = 'DESC'  
  THEN T.PostalCode END DESC   ,
  
  CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'
	THEN T.POCount END ASC, 
	CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'
	 THEN T.POCount END DESC 

   
  
DECLARE @count INT     
SET @count = 0     
SELECT @count = MAX(RowNum) FROM #FinalResultsSorted  
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
  
SELECT @count AS TotalRows, * FROM #FinalResultsSorted WHERE RowNum BETWEEN @startInd AND @endInd  

DROP TABLE #PoCount
DROP TABLE #wVendorAddresses
DROP TABLE #wVendorPhone

END  