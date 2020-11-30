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
-- EXEC [dms_vendor_list] @whereClauseXML="<ROW>\r\n  <Filter VendorNumber=\'1,4\' />\r\n</ROW>"
 
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
	PostalCode NVARCHAR(20) NULL
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
	PostalCode NVARCHAR(20) NULL
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
IsLevy BIT NULL
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
@IsLevy BIT 

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
    IsLevy
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
	VendorNameOperator NVARCHAR(50),
	VendorName NVARCHAR(MAX),
	VendorNumber NVARCHAR(50), 
	CountryID INT,
	StateProvinceID INT,
	City nvarchar(255), 
	VendorStatus NVARCHAR(100),
	VendorRegion NVARCHAR(100),
	PostalCode NVARCHAR(20),
	IsLevy BIT
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
		@IsLevy = IsLevy
FROM	@tmpForWhereClause

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
-- LOGIC : START

DECLARE @vendorEntityID INT, @businessAddressTypeID INT, @officePhoneTypeID INT
SELECT @vendorEntityID = ID FROM Entity WHERE Name = 'Vendor'
SELECT @businessAddressTypeID = ID FROM AddressType WHERE Name = 'Business'
SELECT @officePhoneTypeID = ID FROM PhoneType WHERE Name = 'Office'

;WITH wVendorAddresses
AS
(	
	SELECT ROW_NUMBER() OVER ( PARTITION BY RecordID, AddressTypeID ORDER BY ID ) AS RowNum,
			*
	FROM	AddressEntity 
	WHERE	EntityID = @vendorEntityID
	AND		AddressTypeID = @businessAddressTypeID
)
INSERT INTO #FinalResultsFiltered
SELECT	DISTINCT
		--CASE WHEN C.VendorID IS NOT NULL 
		--	 THEN 'Contracted' 
		--	 ELSE 'Not Contracted' 
		--	 END AS ContractStatus
		NULL As ContractStatus
		, V.ID AS VendorID
		, V.VendorNumber AS VendorNumber
		, V.Name AS VendorName
		, AE.City AS City
		, AE.StateProvince AS State
		, AE.CountryCode AS Country
		, PE.PhoneNumber AS OfficePhone
		, V.AdministrativeRating AS AdminRating
		, V.InsuranceExpirationDate AS InsuranceExpirationDate
		, VACH.BankABANumber AS PaymentMethod -- To be calculated in the next step.
		--,	 CASE
		--     WHEN ISNULL(VACH.BankABANumber,'') = '' THEN 'Check'
		--     ELSE 'DirectDeposit'
		--	 END AS PaymentMethod
		, VS.Name AS VendorStatus
		, VR.Name AS VendorRegion
		, AE.PostalCode
FROM	Vendor V WITH (NOLOCK)
LEFT JOIN	wVendorAddresses AE ON AE.RecordID = V.ID	AND AE.RowNum = 1
LEFT JOIN	PhoneEntity PE ON PE.RecordID = V.ID 
					AND PE.EntityID = @vendorEntityID
					AND PE.PhoneTypeID = @officePhoneTypeID
LEFT JOIN	VendorStatus VS ON VS.ID = V.VendorStatusID
LEFT JOIN	VendorACH VACH ON VACH.VendorID = V.ID
LEFT JOIN	VendorRegion VR ON VR.ID=V.VendorRegionID
--LEFT OUTER	JOIN (SELECT VendorID, MAX(CreateDate) AS [CreateDate] FROM [Contract] WHERE IsActive = 1 GROUP BY VendorID) C ON C.VendorID = V.ID

WHERE	V.IsActive = 1  -- Not deleted		
AND		(@VendorNumber IS NULL OR @VendorNumber = V.VendorNumber)
AND		(@CountryID IS NULL OR @CountryID = AE.CountryID)
AND		(@StateProvinceID IS NULL OR @StateProvinceID = AE.StateProvinceID)
AND		(@City IS NULL OR @City = AE.City)
AND		(@PostalCode IS NULL OR @PostalCode = AE.PostalCode)
AND		(@IsLevy IS NULL OR @IsLevy = ISNULL(V.IsLevyActive,0))
AND		(@VendorStatus IS NULL OR VS.ID IN (SELECT Item FROM [dbo].[fnSplitString](@VendorStatus,',') ) )
AND		(@VendorRegion IS NULL OR VR.ID IN (SELECT Item FROM [dbo].[fnSplitString](@VendorRegion,',') ) )
AND		(  
			(@VendorNameOperator IS NULL )
			OR
			(@VendorNameOperator = 'Begins with' AND V.Name LIKE  @VendorName + '%')
			OR
			(@VendorNameOperator = 'Is equal to' AND V.Name =  @VendorName )
			OR
			(@VendorNameOperator = 'Ends with' AND V.Name LIKE  '%' + @VendorName)
			OR
			(@VendorNameOperator = 'Contains' AND V.Name LIKE  '%' + @VendorName + '%')
		)
	
 UPDATE #FinalResultsFiltered
 SET	ContractStatus = CASE WHEN C.VendorID IS NOT NULL 
						 THEN 'Contracted' 
						 ELSE 'Not Contracted' 
						 END,
		PaymentMethod =	 CASE
						 WHEN ISNULL(F.PaymentMethod,'') = '' THEN 'Check'
						 ELSE 'DirectDeposit'
						 END
 FROM #FinalResultsFiltered F
 LEFT OUTER	JOIN (SELECT VendorID, MAX(CreateDate) AS [CreateDate] FROM [Contract] WHERE IsActive = 1 GROUP BY VendorID) C ON C.VendorID = F.VendorID
 
 INSERT INTO #FinalResultsSorted
 SELECT	  ContractStatus
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
 FROM	#FinalResultsFiltered T	
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
	 THEN T.PostalCode END DESC 
	

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
 WHERE id = object_id(N'[dbo].[dms_BillingManageInvoicesList]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingManageInvoicesList] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC dms_BillingManageInvoicesList @pMode= 'OPEN',@pageSize=12
 CREATE PROCEDURE [dbo].[dms_BillingManageInvoicesList](   
   @whereClauseXML XML = NULL 
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 1   
 , @sortColumn nvarchar(100)  = 'ID'   
 , @sortOrder nvarchar(100) = 'DESC'   
 , @pMode nvarchar(50)='OPEN'
 )   
 AS   
 BEGIN     
 SET FMTONLY OFF;    
  SET NOCOUNT ON    
 
 DECLARE @tmpForWhereClause TABLE
(
ScheduleDateFrom DATETIME NULL,
ScheduleDateTo DATETIME NULL,
ClientID INT NULL,
BillingDefinitionInvoiceID INT NULL,
LineStatuses NVARCHAR(MAX) NULL,
InvoiceStatuses NVARCHAR(MAX) NULL,
BillingDefinitionInvoiceLines NVARCHAR(MAX) NULL
)
 
  CREATE TABLE #tmpFinalResults(     
     [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
     ID INT NULL,    
       
     InvoiceDescription nvarchar(255) NULL,    
     BillingScheduleID int NULL,    
     BillingSchedule nvarchar(50) NULL,    
     BillingScheduleTypeID nvarchar(50) NULL,    
     BillingScheduleType nvarchar(50) NULL,    
     ScheduleDate DATETIME NULL,    
     ScheduleRangeBegin DATETIME NULL,    
     ScheduleRangeEnd DATETIME NULL,    
     InvoiceNumber nvarchar(7) NULL,    
     InvoiceDate DATETIME NULL,    
     InvoiceStatusID int NULL,    
     InvoiceStatus nvarchar(50) NULL,  
     TotalDetailCount int NULL,    
     TotalDetailAmount money NULL,    
     ReadyToBillCount int NULL,    
     ReadyToBillAmount money NULL,    
     PendingCount int NULL,    
     PendingAmount money NULL,         
     ExcludedCount int NULL,    
     ExceptionAmount money NULL,         
     ExceptionCount int NULL,    
     ExcludedAmount money NULL,         
     OnHoldCount int NULL,    
     OnHoldAmount money NULL,         
     PostedCount int NULL,    
     PostedAmount money NULL,    
     BillingDefinitionInvoiceID int NULL,    
     ClientID int NULL,    
     InvoiceName nvarchar(50) NULL,    
     PONumber nvarchar(100) NULL,    
     AccountingSystemCustomerNumber nvarchar(7) NULL,    
     ClientName nvarchar(50) NULL,  
     CanAddLines BIT NULL  ,  
     BilingScheduleStatus nvarchar(100) NULL ,  
     ScheduleDateTypeID  INT NULL,  
     ScheduleRangeTypeID INT NULL  
  )    
      
  CREATE TABLE #FinalResults(     
     [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
     ID INT NULL,    
     InvoiceDescription nvarchar(255) NULL,    
     BillingScheduleID int NULL,    
     BillingSchedule nvarchar(50) NULL,    
     BillingScheduleTypeID nvarchar(50) NULL,    
     BillingScheduleType nvarchar(50) NULL,    
     ScheduleDate DATETIME NULL,    
     ScheduleRangeBegin DATETIME NULL,    
     ScheduleRangeEnd DATETIME NULL,    
     InvoiceNumber nvarchar(7) NULL,    
     InvoiceDate DATETIME NULL,    
     InvoiceStatusID int NULL,    
     InvoiceStatus nvarchar(50) NULL,  
     TotalDetailCount int NULL,    
     TotalDetailAmount money NULL,    
     ReadyToBillCount int NULL,    
     ReadyToBillAmount money NULL,    
     PendingCount int NULL,    
     PendingAmount money NULL,         
     ExcludedCount int NULL,    
     ExceptionAmount money NULL,         
     ExceptionCount int NULL,    
     ExcludedAmount money NULL,         
     OnHoldCount int NULL,    
     OnHoldAmount money NULL,         
     PostedCount int NULL,    
     PostedAmount money NULL,    
     BillingDefinitionInvoiceID int NULL,    
     ClientID int NULL,    
     InvoiceName nvarchar(50) NULL,    
     PONumber nvarchar(100) NULL,    
     AccountingSystemCustomerNumber nvarchar(7) NULL,    
     ClientName nvarchar(50) NULL,  
     CanAddLines BIT NULL   ,  
     BilingScheduleStatus nvarchar(100) NULL ,  
     ScheduleDateTypeID  INT NULL,  
     ScheduleRangeTypeID INT NULL  
  )    

INSERT INTO @tmpForWhereClause
SELECT  
		T.c.value('@ScheduleDateFrom','datetime'),
		T.c.value('@ScheduleDateTo','datetime'),
		T.c.value('@ClientID','int') ,
		T.c.value('@BillingDefinitionInvoiceID','int') ,
		T.c.value('@LineStatuses','NVARCHAR(MAX)'),
		T.c.value('@InvoiceStatuses','NVARCHAR(MAX)'), 
		T.c.value('@BillingDefinitionInvoiceLines','NVARCHAR(MAX)') 
				
		
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @ScheduleDateFrom DATETIME ,
@ScheduleDateTo DATETIME ,
@ClientID INT ,
@BillingDefinitionInvoiceID INT ,
@LineStatuses NVARCHAR(MAX) ,
@InvoiceStatuses NVARCHAR(MAX),
@BillingDefinitionInvoiceLines NVARCHAR(MAX)

SELECT	@ScheduleDateFrom = T.ScheduleDateFrom ,
		@ScheduleDateTo = T.ScheduleDateTo,
		@ClientID = T.ClientID ,
		@BillingDefinitionInvoiceID = T.BillingDefinitionInvoiceID ,
		@LineStatuses = T.LineStatuses ,
		@InvoiceStatuses = T.InvoiceStatuses,
		@BillingDefinitionInvoiceLines = T.BillingDefinitionInvoiceLines
FROM	@tmpForWhereClause T

  INSERT INTO #tmpFinalResults    
  SELECT  DISTINCT   
 BI.ID,    
 BI.[Description],    
 BI.BillingScheduleID,    
    BS.Name,    
    BS.ScheduleTypeID,    
    BST.Name,    
    BI.ScheduleDate,--ISNULL(CONVERT(VARCHAR(10), BI.ScheduleDate, 1),''),    
    BI.ScheduleRangeBegin,--ISNULL(CONVERT(VARCHAR(10), BI.ScheduleRangeBegin, 1),''),    
    BI.ScheduleRangeEnd,--ISNULL(CONVERT(VARCHAR(10), BI.ScheduleRangeEnd, 1),''),    
    BI.InvoiceNumber,    
    BI.InvoiceDate,--ISNULL(CONVERT(VARCHAR(10), BI.InvoiceDate, 1),''),    
    BI.InvoiceStatusID,    
    BIS.Name,    
    DTLData.TotalDetailCount,  
 DTLData.TotalDetailAmount,    
 DTLData.ReadyToBillCount,  
 DTLData.ReadyToBillAmount,  
 DTLData.PendingCount,  
 DTLData.PendingAmount,  
 DTLData.ExceptionCount,  
 DTLData.ExceptionAmount,  
 DTLData.ExcludedCount,  
 DTLData.ExcludedAmount,  
 DTLData.OnHoldCount,  
 DTLData.OnHoldAmount,    
 DTLData.PostedCount,  
 DTLData.PostedAmount,  
    BI.BillingDefinitionInvoiceID,    
    BI.ClientID,    
    BI.Name,    
    isnull(bi.POPrefix, '') + isnull(bi.PONumber, '') as PONumber,  
    BI.AccountingSystemCustomerNumber,    
    cl.Name ,  
    bi.CanAddLines,  
    bss.Name AS BilingScheduleStatus ,  
    bdi.ScheduleDateTypeID,  
    bdi.ScheduleRangeTypeID  
  from BillingInvoice bi with (nolock)  
left outer join BillingDefinitionInvoice bdi with(nolock) on bdi.ID=bi.BillingDefinitionInvoiceID  
left outer join BillingInvoiceLine bil with (nolock) on bil.BillingInvoiceID = bi.ID 
left outer join BillingDefinitionInvoiceLine bdil with(nolock) on bdil.BillingDefinitionInvoiceID = bdi.ID 
left outer join BillingSchedule bs with (nolock) on bs.ID = bi.BillingScheduleID  
left outer join Client cl with (nolock) on cl.ID = bi.ClientID  
left outer join Product pr with (nolock) on pr.ID = bil.ProductID  
left outer join RateType rt with (nolock) on rt.ID = bil.RateTypeID  
left outer join BillingInvoiceStatus bis with (nolock) on bis.ID = bi.InvoiceStatusID  
left outer join BillingInvoiceLineStatus bils with (nolock) on bils.ID = bil.InvoiceLineStatusID  
left outer join BillingScheduleType bst with (nolock) on bst.ID = bs.ScheduleTypeID  
left outer join dbo.BillingScheduleStatus bss with (nolock) on bss.ID = bs.ScheduleStatusID  
 --and  bss.Name = @pMode  
left outer join (select bi.ID as InvoiceID,  
    --bil.ID as InvoiceLineID,  
    -- Total  
    isnull(sum(case  
      when bids.Name <> 'DELETED' then 1  
      else 0  
     end), 0) as TotalDetailCount,  
    isnull(sum(case  
      when bids.Name <> 'DELETED' then -- COALESCE(bid.AdjustmentAmount, bid.EventAmount)
			CASE WHEN ISNULL(bid.IsAdjusted,0) = 1 THEN bid.AdjustmentAmount ELSE bid.EventAmount END
      else 0  
     end), 0) as TotalDetailAmount,  
    -- READY  
    isnull(sum(case  
      when bids.Name = 'READY' then 1  
      else 0  
     end), 0) as ReadyToBillCount,  
    isnull(sum(case  
      when bids.Name = 'READY' then -- COALESCE(bid.AdjustmentAmount, bid.EventAmount)  
			CASE WHEN ISNULL(bid.IsAdjusted,0) = 1 THEN bid.AdjustmentAmount ELSE bid.EventAmount END
      else 0.00  
     end), 0.00) as ReadyToBillAmount,  
    -- PENDING  
    isnull(sum(case  
      when bids.Name = 'PENDING' then 1  
      else 0  
     end), 0) as PendingCount,  
    isnull(sum(case  
      when bids.Name = 'PENDING' then -- COALESCE(bid.AdjustmentAmount, bid.EventAmount)  
			CASE WHEN ISNULL(bid.IsAdjusted,0) = 1 THEN bid.AdjustmentAmount ELSE bid.EventAmount END
      else 0.00  
     end), 0.00) as PendingAmount,  
    -- EXCEPTION  
    isnull(sum(case  
      when bids.Name = 'EXCEPTION' then 1  
      else 0  
     end), 0) as ExceptionCount,  
    isnull(sum(case  
      when bids.Name = 'EXCEPTION' then -- COALESCE(bid.AdjustmentAmount, bid.EventAmount)  
			CASE WHEN ISNULL(bid.IsAdjusted,0) = 1 THEN bid.AdjustmentAmount ELSE bid.EventAmount END
      else 0.00  
     end), 0.00) as ExceptionAmount,  
    -- EXCLUDED  
    isnull(sum(case  
      when bids.Name = 'EXCLUDED' then 1  
      else 0  
     end), 0) as ExcludedCount,  
    isnull(sum(case  
      when bids.Name = 'EXCLUDED' then -- COALESCE(bid.AdjustmentAmount, bid.EventAmount)  
			CASE WHEN ISNULL(bid.IsAdjusted,0) = 1 THEN bid.AdjustmentAmount ELSE bid.EventAmount END
      else 0.00  
     end), 0.00) as ExcludedAmount,  
    -- ONHOLD  
    isnull(sum(case  
      when bids.Name = 'ONHOLD' then 1  
      else 0  
     end), 0) as OnHoldCount,  
    isnull(sum(case  
      when bids.Name = 'ONHOLD' then -- COALESCE(bid.AdjustmentAmount, bid.EventAmount)  
			CASE WHEN ISNULL(bid.IsAdjusted,0) = 1 THEN bid.AdjustmentAmount ELSE bid.EventAmount END
      else 0.00  
     end), 0.00) as OnHoldAmount,  
    -- POSTED  
    isnull(sum(case  
      when bids.Name = 'POSTED' then 1  
      else 0  
     end), 0) as PostedCount,  
    isnull(sum(case  
      when bids.Name = 'POSTED' then -- COALESCE(bid.AdjustmentAmount, bid.EventAmount)  
			CASE WHEN ISNULL(bid.IsAdjusted,0) = 1 THEN bid.AdjustmentAmount ELSE bid.EventAmount END
      else 0.00  
     end), 0.00) as PostedAmount  
  from BillingInvoice bi with (nolock)  
  left outer join BillingInvoiceLine bil with (nolock) on bil.BillingInvoiceID = bi.ID  
  left outer join BillingInvoiceDetail bid with (nolock) on bid.BillingInvoiceLineID = bil.ID  
  left outer join BillingInvoiceDetailStatus bids with (nolock) on bids.ID = bid.InvoiceDetailStatusID  
 
   group by  
    bi.ID  
    --bil.ID  
   ) as DTLData on DTLData.InvoiceID = bi.ID  
      --and DTLData.InvoiceLineID = bil.ID  
where (@pMode IS NULL OR bss.Name = @pMode)
AND	(@ScheduleDateFrom IS NULL OR bs.ScheduleDate >= @ScheduleDateFrom )
AND	(@ScheduleDateTo IS NULL OR bs.ScheduleDate < DATEADD(DD,1,@ScheduleDateTo) )
AND	(@ClientID IS NULL OR @ClientID = cl.ID)
AND	(@BillingDefinitionInvoiceID IS NULL OR @BillingDefinitionInvoiceID = bdi.ID)
--AND	(@LineStatuses IS NULL )--OR bids.ID IN (SELECT item FROM fnSplitString(@LineStatuses,',') ))
AND	(@InvoiceStatuses IS NULL OR bis.ID IN (SELECT item FROM fnSplitString(@InvoiceStatuses,',') ))
AND	(@BillingDefinitionInvoiceLines IS NULL OR bdil.ID IN (SELECT item FROM fnSplitString(@BillingDefinitionInvoiceLines,',') ))
order by  
  BI.ID,    
 BI.[Description],    
 BI.BillingScheduleID,    
    BS.Name,    
    BS.ScheduleTypeID,    
    BST.Name,    
    BI.ScheduleDate,--ISNULL(CONVERT(VARCHAR(10), BI.ScheduleDate, 1),''),    
    BI.ScheduleRangeBegin,--ISNULL(CONVERT(VARCHAR(10), BI.ScheduleRangeBegin, 1),''),    
    BI.ScheduleRangeEnd,--ISNULL(CONVERT(VARCHAR(10), BI.ScheduleRangeEnd, 1),''),    
    BI.InvoiceNumber,    
    BI.InvoiceDate,--ISNULL(CONVERT(VARCHAR(10), BI.InvoiceDate, 1),''),    
    BI.InvoiceStatusID,    
    BIS.Name,    
    DTLData.TotalDetailCount,  
 DTLData.TotalDetailAmount,    
 DTLData.ReadyToBillCount,  
 DTLData.ReadyToBillAmount,  
 DTLData.PendingCount,  
 DTLData.PendingAmount,  
 DTLData.ExceptionCount,  
 DTLData.ExceptionAmount,  
 DTLData.ExcludedCount,  
 DTLData.ExcludedAmount,  
 DTLData.OnHoldCount,  
 DTLData.OnHoldAmount,    
 DTLData.PostedCount,  
 DTLData.PostedAmount,  
    BI.BillingDefinitionInvoiceID,    
    BI.ClientID,    
    BI.Name,    
    isnull(bi.POPrefix, '') + isnull(bi.PONumber, ''),  
    BI.AccountingSystemCustomerNumber,    
    cl.Name ,  
    bi.CanAddLines,  
    bss.Name  ,  
    bdi.ScheduleDateTypeID,  
    bdi.ScheduleRangeTypeID  
  
      
  INSERT INTO #FinalResults    
SELECT     
 T.ID,    
 T.InvoiceDescription,    
 T.BillingScheduleID,    
 T.BillingSchedule,    
 T.BillingScheduleTypeID,    
 T.BillingScheduleType,    
 T.ScheduleDate,    
 T.ScheduleRangeBegin,    
 T.ScheduleRangeEnd,    
 T.InvoiceNumber,    
 T.InvoiceDate,    
 T.InvoiceStatusID,    
 T.InvoiceStatus,    
 T.TotalDetailCount,    
 T.TotalDetailAmount,    
 T.ReadyToBillCount,    
 T.ReadyToBillAmount,    
 T.PendingCount,    
 T.PendingAmount,     
 T.ExceptionCount,    
 T.ExceptionAmount,   
 T.ExcludedCount,    
 T.ExcludedAmount,   
 T.OnHoldCount,    
 T.OnHoldAmount,   
 T.PostedCount,    
 T.PostedAmount,    
 T.BillingDefinitionInvoiceID,    
 T.ClientID,    
 T.InvoiceName,    
 T.PONumber,    
 T.AccountingSystemCustomerNumber,    
 T.ClientName,  
 T.CanAddLines ,  
 T.BilingScheduleStatus ,  
T.ScheduleDateTypeID,  
T.ScheduleRangeTypeID  
 FROM #tmpFinalResults T    
    ORDER BY     
  CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'    
  THEN T.ID END ASC,     
  CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'    
  THEN T.ID END DESC    ,

	 CASE WHEN @sortColumn = 'InvoiceDescription' AND @sortOrder = 'ASC'
	 THEN T.InvoiceDescription END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDescription' AND @sortOrder = 'DESC'
	 THEN T.InvoiceDescription END DESC ,

	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'ASC'
	 THEN T.BillingScheduleID END ASC, 
	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'DESC'
	 THEN T.BillingScheduleID END DESC ,

	 CASE WHEN @sortColumn = 'BillingSchedule' AND @sortOrder = 'ASC'
	 THEN T.BillingSchedule END ASC, 
	 CASE WHEN @sortColumn = 'BillingSchedule' AND @sortOrder = 'DESC'
	 THEN T.BillingSchedule END DESC ,

	 CASE WHEN @sortColumn = 'BillingScheduleTypeID' AND @sortOrder = 'ASC'
	 THEN T.BillingScheduleTypeID END ASC, 
	 CASE WHEN @sortColumn = 'BillingScheduleTypeID' AND @sortOrder = 'DESC'
	 THEN T.BillingScheduleTypeID END DESC ,

	 CASE WHEN @sortColumn = 'BillingScheduleType' AND @sortOrder = 'ASC'
	 THEN T.BillingScheduleType END ASC, 
	 CASE WHEN @sortColumn = 'BillingScheduleType' AND @sortOrder = 'DESC'
	 THEN T.BillingScheduleType END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleDate' AND @sortOrder = 'ASC'
	 THEN T.ScheduleDate END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleDate' AND @sortOrder = 'DESC'
	 THEN T.ScheduleDate END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeBegin' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeBegin END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeBegin' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeBegin END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeEnd' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeEnd END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeEnd' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeEnd END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN T.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN T.InvoiceNumber END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'ASC'
	 THEN T.InvoiceDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'DESC'
	 THEN T.InvoiceDate END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceStatusID' AND @sortOrder = 'ASC'
	 THEN T.InvoiceStatusID END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceStatusID' AND @sortOrder = 'DESC'
	 THEN T.InvoiceStatusID END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'ASC'
	 THEN T.InvoiceStatus END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'DESC'
	 THEN T.InvoiceStatus END DESC ,

	 CASE WHEN @sortColumn = 'TotalDetailCount' AND @sortOrder = 'ASC'
	 THEN T.TotalDetailCount END ASC, 
	 CASE WHEN @sortColumn = 'TotalDetailCount' AND @sortOrder = 'DESC'
	 THEN T.TotalDetailCount END DESC ,

	 CASE WHEN @sortColumn = 'TotalDetailAmount' AND @sortOrder = 'ASC'
	 THEN T.TotalDetailAmount END ASC, 
	 CASE WHEN @sortColumn = 'TotalDetailAmount' AND @sortOrder = 'DESC'
	 THEN T.TotalDetailAmount END DESC ,

	 CASE WHEN @sortColumn = 'ReadyToBillCount' AND @sortOrder = 'ASC'
	 THEN T.ReadyToBillCount END ASC, 
	 CASE WHEN @sortColumn = 'ReadyToBillCount' AND @sortOrder = 'DESC'
	 THEN T.ReadyToBillCount END DESC ,

	 CASE WHEN @sortColumn = 'ReadyToBillAmount' AND @sortOrder = 'ASC'
	 THEN T.ReadyToBillAmount END ASC, 
	 CASE WHEN @sortColumn = 'ReadyToBillAmount' AND @sortOrder = 'DESC'
	 THEN T.ReadyToBillAmount END DESC ,

	 CASE WHEN @sortColumn = 'PendingCount' AND @sortOrder = 'ASC'
	 THEN T.PendingCount END ASC, 
	 CASE WHEN @sortColumn = 'PendingCount' AND @sortOrder = 'DESC'
	 THEN T.PendingCount END DESC ,

	 CASE WHEN @sortColumn = 'PendingAmount' AND @sortOrder = 'ASC'
	 THEN T.PendingAmount END ASC, 
	 CASE WHEN @sortColumn = 'PendingAmount' AND @sortOrder = 'DESC'
	 THEN T.PendingAmount END DESC ,

	 CASE WHEN @sortColumn = 'ExcludedCount' AND @sortOrder = 'ASC'
	 THEN T.ExcludedCount END ASC, 
	 CASE WHEN @sortColumn = 'ExcludedCount' AND @sortOrder = 'DESC'
	 THEN T.ExcludedCount END DESC ,

	 CASE WHEN @sortColumn = 'ExceptionAmount' AND @sortOrder = 'ASC'
	 THEN T.ExceptionAmount END ASC, 
	 CASE WHEN @sortColumn = 'ExceptionAmount' AND @sortOrder = 'DESC'
	 THEN T.ExceptionAmount END DESC ,

	 CASE WHEN @sortColumn = 'ExceptionCount' AND @sortOrder = 'ASC'
	 THEN T.ExceptionCount END ASC, 
	 CASE WHEN @sortColumn = 'ExceptionCount' AND @sortOrder = 'DESC'
	 THEN T.ExceptionCount END DESC ,

	 CASE WHEN @sortColumn = 'ExcludedAmount' AND @sortOrder = 'ASC'
	 THEN T.ExcludedAmount END ASC, 
	 CASE WHEN @sortColumn = 'ExcludedAmount' AND @sortOrder = 'DESC'
	 THEN T.ExcludedAmount END DESC ,

	 CASE WHEN @sortColumn = 'OnHoldCount' AND @sortOrder = 'ASC'
	 THEN T.OnHoldCount END ASC, 
	 CASE WHEN @sortColumn = 'OnHoldCount' AND @sortOrder = 'DESC'
	 THEN T.OnHoldCount END DESC ,

	 CASE WHEN @sortColumn = 'OnHoldAmount' AND @sortOrder = 'ASC'
	 THEN T.OnHoldAmount END ASC, 
	 CASE WHEN @sortColumn = 'OnHoldAmount' AND @sortOrder = 'DESC'
	 THEN T.OnHoldAmount END DESC ,

	 CASE WHEN @sortColumn = 'PostedCount' AND @sortOrder = 'ASC'
	 THEN T.PostedCount END ASC, 
	 CASE WHEN @sortColumn = 'PostedCount' AND @sortOrder = 'DESC'
	 THEN T.PostedCount END DESC ,

	 CASE WHEN @sortColumn = 'PostedAmount' AND @sortOrder = 'ASC'
	 THEN T.PostedAmount END ASC, 
	 CASE WHEN @sortColumn = 'PostedAmount' AND @sortOrder = 'DESC'
	 THEN T.PostedAmount END DESC ,

	 CASE WHEN @sortColumn = 'BillingDefinitionInvoiceID' AND @sortOrder = 'ASC'
	 THEN T.BillingDefinitionInvoiceID END ASC, 
	 CASE WHEN @sortColumn = 'BillingDefinitionInvoiceID' AND @sortOrder = 'DESC'
	 THEN T.BillingDefinitionInvoiceID END DESC ,

	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'ASC'
	 THEN T.ClientID END ASC, 
	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'DESC'
	 THEN T.ClientID END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceName' AND @sortOrder = 'ASC'
	 THEN T.InvoiceName END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceName' AND @sortOrder = 'DESC'
	 THEN T.InvoiceName END DESC ,

	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'
	 THEN T.PONumber END ASC, 
	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'
	 THEN T.PONumber END DESC ,

	 CASE WHEN @sortColumn = 'AccountingSystemCustomerNumber' AND @sortOrder = 'ASC'
	 THEN T.AccountingSystemCustomerNumber END ASC, 
	 CASE WHEN @sortColumn = 'AccountingSystemCustomerNumber' AND @sortOrder = 'DESC'
	 THEN T.AccountingSystemCustomerNumber END DESC ,

	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'ASC'
	 THEN T.ClientName END ASC, 
	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'DESC'
	 THEN T.ClientName END DESC ,

	 CASE WHEN @sortColumn = 'CanAddLines' AND @sortOrder = 'ASC'
	 THEN T.CanAddLines END ASC, 
	 CASE WHEN @sortColumn = 'CanAddLines' AND @sortOrder = 'DESC'
	 THEN T.CanAddLines END DESC ,

	 CASE WHEN @sortColumn = 'BilingScheduleStatus' AND @sortOrder = 'ASC'
	 THEN T.BilingScheduleStatus END ASC, 
	 CASE WHEN @sortColumn = 'BilingScheduleStatus' AND @sortOrder = 'DESC'
	 THEN T.BilingScheduleStatus END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleDateTypeID' AND @sortOrder = 'ASC'
	 THEN T.ScheduleDateTypeID END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleDateTypeID' AND @sortOrder = 'DESC'
	 THEN T.ScheduleDateTypeID END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeTypeID' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeTypeID END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeTypeID' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeTypeID END DESC  
      
      
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
     
 DROP TABLE #FinalResults    
 DROP TABLE #tmpFinalResults    
 END 