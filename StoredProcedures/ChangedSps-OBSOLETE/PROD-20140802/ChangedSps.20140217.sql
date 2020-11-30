IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Details_For_Report_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Details_For_Report_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dbo].[dms_Vendor_Details_For_Report_Get] 190
 CREATE PROCEDURE [dbo].[dms_Vendor_Details_For_Report_Get](
 @vendorID INT
 )
 AS
 BEGIN
 
	DECLARE @vendorServicesPhoneNumber NVARCHAR(100) = NULL,
			@vendorServicesFaxNumber NVARCHAR(100) = NULL

	-- KB: TFS : 2433 - Fix the VendorServicesPhone and Fax numbers
	SET	@vendorServicesPhoneNumber	= (SELECT Value FROM ApplicationConfiguration WHERE Name = 'VendorServicesPhoneNumber')
	SET	@vendorServicesFaxNumber	= (SELECT Value FROM ApplicationConfiguration WHERE Name = 'VendorServicesFaxNumber')

	-- KB: Handle the case when there are multiple Office addresses and Business phone numbers.
	;WITH wBusinessAddresses
	AS
	(	
		SELECT	ROW_NUMBER() OVER (ORDER BY AE.ID DESC) AS RowNum,
				AE.*
		FROM	AddressEntity AE WITH (NOLOCK)
		WHERE	AE.RecordID = @vendorID AND AE.EntityID =
					  (SELECT     ID
						FROM          Entity
						WHERE      (Name = 'Vendor')) AND AE.AddressTypeID =
					  (SELECT     ID
						FROM          AddressType
						WHERE      (Name = 'Business'))
	),
	wOfficePhoneNumbers
	AS
	(
		SELECT	ROW_NUMBER() OVER (ORDER BY PE.ID DESC) AS RowNum,
				PE.*
		FROM	PhoneEntity PE WITH (NOLOCK)
		WHERE	PE.RecordID = @vendorID AND PE.EntityID =
					  (SELECT     ID
						FROM          Entity
						WHERE      (Name = 'Vendor')) AND PE.PhoneTypeID =
					  (SELECT     ID
						FROM          AddressType
						WHERE      (Name = 'Office'))
	)
		
	SELECT     
			V.VendorNumber, 
			V.Name, 
			V.ContactFirstName AS VendorFirstName, 
			V.ContactLastName AS VendorLastName, 
			V.Email as VendorEmail,
			VR.Name as VendorRegionName,
			VR.ContactFirstName AS RepFirstName, 
			VR.ContactLastName AS RepLastName, 
			VR.Email as RepEmail, 
			dbo.fnc_FormatPhoneNumber(PE.PhoneNumber, 0) AS VendorPhoneNumber,
			dbo.fnc_FormatPhoneNumber(VR.PhoneNumber, 0) AS RepPhoneNumber, 
			dbo.fnc_FormatPhoneNumber(@vendorServicesPhoneNumber, 0) AS VendorRegionOffice, 
			dbo.fnc_FormatPhoneNumber(@vendorServicesFaxNumber,0) as VendorRegionFax,
			AE.Line1, 
			AE.Line2, 
			AE.Line3, 
			AE.City, 
			AE.StateProvince, 
			AE.CountryCode, 
			AE.PostalCode
	FROM    Vendor AS V WITH (NOLOCK)
	LEFT OUTER JOIN	VendorRegion AS VR WITH (NOLOCK) ON V.VendorRegionID = VR.ID 
	LEFT OUTER JOIN wBusinessAddresses AE WITH (NOLOCK) ON AE.RecordID = V.ID AND AE.RowNum = 1
	LEFT OUTER JOIN wOfficePhoneNumbers PE WITH (NOLOCK) ON PE.RecordID = V.ID AND PE.RowNum = 1	
	WHERE     (V.ID = @vendorID)
 
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
 WHERE id = object_id(N'[dbo].[dms_Vendor_CCProcessingDetail_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_CCProcessingDetail_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Vendor_CCProcessingDetail_List_Get @TemporaryCreditCardId=1
 CREATE PROCEDURE [dbo].[dms_Vendor_CCProcessingDetail_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @TemporaryCreditCardId INT = NULL 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF;
 	SET NOCOUNT ON


 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	TransactionDate datetime  NULL ,
	TransactionBy nvarchar(100)  NULL ,
	TransactionType nvarchar(20)  NULL ,
	RequestedAmount money  NULL ,
	ApprovedAmount money  NULL ,
	ChargeAmount money  NULL ,
	ChargeDescription nvarchar(100)  NULL
	
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	TransactionDate datetime  NULL ,
	TransactionBy nvarchar(100)  NULL ,
	TransactionType nvarchar(20)  NULL ,
	RequestedAmount money  NULL ,
	ApprovedAmount money  NULL ,
	ChargeAmount money  NULL ,
	ChargeDescription nvarchar(100)  NULL
) 



--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT	TCCD.ID
		, CASE
			WHEN TCCD.TransactionType = 'Charge' THEN TCCD.ChargeDate
			ELSE TCCD.TransactionDate
		  END AS [Date]
		, TCCD.TransactionBy AS [User]
		, TCCD.TransactionType AS [Action]
		, TCCD.RequestedAmount AS [Requested]
		, TCCD.ApprovedAmount AS [Approved]
		, TCCD.ChargeAmount AS [Charge]
		, TCCD.ChargeDescription AS [ChargeDescription]
FROM	TemporaryCreditCardDetail TCCD
WHERE	TCCD.TemporaryCreditCardID = @TemporaryCreditCardId
ORDER BY TCCD.TransactionDate DESC,TCCD.TransactionSequence ASC


INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.TransactionDate,
	T.TransactionBy,
	T.TransactionType,
	T.RequestedAmount,
	T.ApprovedAmount,
	T.ChargeAmount,
	T.ChargeDescription
FROM #tmpFinalResults T


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
 WHERE id = object_id(N'[dbo].[dms_Vendor_CCProcessing_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_CCProcessing_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_Vendor_CCProcessing_List_Get] @whereClauseXML = '<ROW><Filter IDType="Vendor" IDValue="TX100532" NameValue="" NameOperator="" InvoiceStatuses="" POStatuses="" FromDate="" ToDate="" ExportType="" ToBePaidFromDate="" ToBePaidToDate=""/></ROW>'  
CREATE PROCEDURE [dbo].[dms_Vendor_CCProcessing_List_Get](     
   @whereClauseXML XML = NULL     
 , @startInd Int = 1     
 , @endInd BIGINT = 5000     
 , @pageSize int = 10000      
 , @sortColumn nvarchar(100)  = ''     
 , @sortOrder nvarchar(100) = 'ASC'     
      
 )     
 AS     
 BEGIN     
 
 SET FMTONLY OFF    
  SET NOCOUNT ON    
    
IF @whereClauseXML IS NULL     
BEGIN    
 SET @whereClauseXML = '<ROW><Filter     
NameOperator="-1"    
 ></Filter></ROW>'    
END    
    
    
CREATE TABLE #tmpForWhereClause    
(    
 IDType NVARCHAR(50) NULL,    
 IDValue NVARCHAR(100) NULL,    
 CCMatchStatuses NVARCHAR(MAX) NULL,    
 POPayStatuses NVARCHAR(MAX) NULL,    
 CCFromDate DATETIME NULL,    
 CCToDate DATETIME NULL,    
 POFromDate DATETIME NULL,    
 POToDate DATETIME NULL,
 PostingBatchID INT NULL
     
)    
    
 CREATE TABLE #FinalResults_Filtered(      
 ID int  NULL ,    
 CCRefPO nvarchar(50)  NULL ,    
 TempCC nvarchar(50) NULL,    
 CCIssueDate datetime  NULL ,    
 CCApprove money  NULL ,    
 CCCharge money  NULL ,    
 CCIssueStatus nvarchar(50)  NULL ,    
 CCMatchStatus nvarchar(50)  NULL ,    
 CCOrigPO nvarchar(50)  NULL ,    
 PONumber nvarchar(50)  NULL ,    
 PODate datetime  NULL ,    
 POPayStatus nvarchar(50)  NULL ,    
 POCC nvarchar(50)  NULL ,    
 POAmount money  NULL ,    
 InvoiceAmount money  NULL ,    
 Note nvarchar(1000)  NULL ,    
 ExceptionMessage nvarchar(200)  NULL ,    
 POId int  NULL  ,
 CreditCardIssueNumber nvarchar(50) NULL,
 PurchaseOrderStatus nvarchar(50)  NULL
)     
    
 CREATE TABLE #FinalResults_Sorted (     
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
 ID int  NULL ,    
 CCRefPO nvarchar(50)  NULL ,    
 TempCC nvarchar(50) NULL,    
 CCIssueDate datetime  NULL ,    
 CCApprove money  NULL ,    
 CCCharge money  NULL ,    
 CCIssueStatus nvarchar(50)  NULL ,    
 CCMatchStatus nvarchar(50)  NULL ,    
 CCOrigPO nvarchar(50)  NULL ,    
 PONumber nvarchar(50)  NULL ,    
 PODate datetime  NULL ,    
 POPayStatus nvarchar(50)  NULL ,    
 POCC nvarchar(50)  NULL ,    
 POAmount money  NULL ,    
 InvoiceAmount money  NULL ,    
 Note nvarchar(1000)  NULL ,    
 ExceptionMessage nvarchar(200)  NULL ,    
 POId int  NULL   ,
 CreditCardIssueNumber nvarchar(50) NULL,
 PurchaseOrderStatus nvarchar(50)  NULL
)     

DECLARE @matchedCount BIGINT      
DECLARE @exceptionCount BIGINT      
DECLARE @postedCount BIGINT    
DECLARE @cancelledCount BIGINT 
DECLARE @unmatchedCount BIGINT 
 
SET @matchedCount = 0      
SET @exceptionCount = 0      
SET @postedCount = 0
SET @cancelledCount = 0
SET @unmatchedCount = 0    
  
  
INSERT INTO #tmpForWhereClause    
SELECT      
 T.c.value('@IDType','NVARCHAR(50)') ,    
 T.c.value('@IDValue','NVARCHAR(100)'),     
 T.c.value('@CCMatchStatuses','nvarchar(MAX)') ,    
 T.c.value('@POPayStatuses','nvarchar(MAX)') , 
 T.c.value('@CCFromDate','datetime') ,    
 T.c.value('@CCToDate','datetime') ,    
 T.c.value('@POFromDate','datetime') ,
T.c.value('@POToDate','datetime') ,    
 T.c.value('@PostingBatchID','INT')     

FROM @whereClauseXML.nodes('/ROW/Filter') T(c)    
    
    
DECLARE @idType NVARCHAR(50) = NULL,    
  @idValue NVARCHAR(100) = NULL,    
  @CCMatchStatuses NVARCHAR(MAX) = NULL,    
  @POPayStatuses NVARCHAR(MAX) = NULL,    
  @CCFromDate DATETIME = NULL,    
  @CCToDate DATETIME = NULL, 
  @POFromDate DATETIME = NULL,    
  @POToDate DATETIME = NULL,
  @PostingBatchID INT = NULL   
      
SELECT @idType = IDType,    
  @idValue = IDValue,    
  @CCMatchStatuses = CCMatchStatuses,    
  @POPayStatuses = POPayStatuses,    
  @CCFromDate = CCFromDate,    
  @CCToDate = CASE WHEN CCToDate = '1900-01-01' THEN NULL ELSE CCToDate END,  
  @POFromDate = POFromDate,
  @POToDate = CASE WHEN POToDate = '1900-01-01' THEN NULL ELSE POToDate END,  
  @PostingBatchID = PostingBatchID 
FROM #tmpForWhereClause    

INSERT INTO #FinalResults_Filtered 
SELECT	TCC.ID,
		TCC.ReferencePurchaseOrderNumber
		, TCC.CreditCardNumber
		, TCC.IssueDate
		, TCC.ApprovedAmount
		, TCC.TotalChargedAmount
		, TCC.IssueStatus
		, TCCS.Name AS CCMatchStatus
		, TCC.OriginalReferencePurchaseOrderNumber
		, PO.PurchaseOrderNumber
		, PO.IssueDate
		, PSC.Name
		, PO.CompanyCreditCardNumber
		, PO.PurchaseOrderAmount
		, CASE
			WHEN TCCS.Name = 'Posted'  THEN ''--TCC.InvoiceAmount
			WHEN TCCS.Name = 'Matched' THEN TCC.TotalChargedAmount
			ELSE ''
		  END AS InvoiceAmount
		, TCC.Note
		,TCC.ExceptionMessage
		,PO.ID
		,TCC.CreditCardIssueNumber
		,POS.Name 
FROM	TemporaryCreditCard TCC
LEFT JOIN	TemporaryCreditCardStatus TCCS ON TCCS.ID = TCC.TemporaryCreditCardStatusID
LEFT JOIN	PurchaseOrder PO ON PO.PurchaseOrderNumber = TCC.ReferencePurchaseOrderNumber
LEFT JOIN   PurchaseOrderStatus POS ON POS.ID = PO.PurchaseOrderStatusID
LEFT JOIN	PurchaseOrderPayStatusCode PSC ON PSC.ID = PO.PayStatusCodeID
WHERE
 ( ISNULL(@idType,'') = ''    
   OR    
   (@idType = 'CCMatchPO' AND TCC.ReferencePurchaseOrderNumber = @idValue )    
   OR    
   (@idType = 'Last5ofTempCC' AND RIGHT(TCC.CreditCardNumber,5) = @idValue )    
    
  )    
 AND  (    
   ( ISNULL(@CCMatchStatuses,'') = '')    
   OR    
   ( TCC.TemporaryCreditCardStatusID IN (    
           SELECT item FROM fnSplitString(@CCMatchStatuses,',')    
   ))    
  )    
  AND  (    
   ( ISNULL(@POPayStatuses,'') = '')    
   OR    
   ( PO.PayStatusCodeID IN (    
           SELECT item FROM fnSplitString(@POPayStatuses,',')    
   ))    
  )     
  AND  (    
       
   ( @CCFromDate IS NULL OR (@CCFromDate IS NOT NULL AND TCC.IssueDate >= @CCFromDate))    
    AND    
   ( @CCToDate IS NULL OR (@CCToDate IS NOT NULL AND TCC.IssueDate < DATEADD(DD,1,@CCToDate)))    
  )
  AND  (    
       
   ( @POFromDate IS NULL OR (@POFromDate IS NOT NULL AND PO.IssueDate >= @POFromDate))    
    AND    
   ( @POToDate IS NULL OR (@POToDate IS NOT NULL AND PO.IssueDate < DATEADD(DD,1,@POToDate)))    
  )
  AND ( ISNULL(@PostingBatchID,0) = 0 OR TCC.PostingBatchID = @PostingBatchID )
  
INSERT INTO #FinalResults_Sorted    
SELECT     
 T.ID,    
 T.CCRefPO,    
 T.TempCC,    
 T.CCIssueDate,    
 T.CCApprove,    
 T.CCCharge,    
 T.CCIssueStatus,    
 T.CCMatchStatus,    
 T.CCOrigPO,    
 T.PONumber,    
 T.PODate,    
 T.POPayStatus,    
 T.POCC,    
 T.POAmount,    
 T.InvoiceAmount,    
 T.Note,    
 T.ExceptionMessage,    
 T.POId,
 T.CreditCardIssueNumber,
 T.PurchaseOrderStatus
FROM #FinalResults_Filtered T    


 ORDER BY     
  CASE WHEN @sortColumn = 'CCRefPO' AND @sortOrder = 'ASC'    
  THEN T.CCRefPO END ASC,     
  CASE WHEN @sortColumn = 'CCRefPO' AND @sortOrder = 'DESC'    
  THEN T.ID END DESC ,    
    
  CASE WHEN @sortColumn = 'TempCC' AND @sortOrder = 'ASC'    
  THEN T.TempCC END ASC,     
  CASE WHEN @sortColumn = 'TempCC' AND @sortOrder = 'DESC'    
  THEN T.TempCC END DESC ,    
     
 CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'ASC'    
  THEN T.CCIssueDate END ASC,     
  CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'DESC'    
  THEN T.CCIssueDate END DESC ,    
    
  CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'ASC'    
  THEN T.CCApprove END ASC,     
  CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'DESC'    
  THEN T.CCApprove END DESC ,    
    
  CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'ASC'    
  THEN T.CCCharge END ASC,     
  CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'DESC'    
  THEN T.CCCharge END DESC ,    
    
  CASE WHEN @sortColumn = 'CCIssueStatus' AND @sortOrder = 'ASC'    
  THEN T.CCIssueStatus END ASC,     
  CASE WHEN @sortColumn = 'CCIssueStatus' AND @sortOrder = 'DESC'    
  THEN T.CCIssueStatus END DESC ,    
    
  CASE WHEN @sortColumn = 'CCMatchStatus' AND @sortOrder = 'ASC'    
  THEN T.CCMatchStatus END ASC,     
  CASE WHEN @sortColumn = 'CCMatchStatus' AND @sortOrder = 'DESC'    
  THEN T.CCMatchStatus END DESC ,    
    
  CASE WHEN @sortColumn = 'CCOrigPO' AND @sortOrder = 'ASC'    
  THEN T.CCOrigPO END ASC,     
  CASE WHEN @sortColumn = 'CCOrigPO' AND @sortOrder = 'DESC'    
  THEN T.CCOrigPO END DESC ,    
    
  CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'    
  THEN T.PONumber END ASC,     
  CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'    
  THEN T.PONumber END DESC ,    
    
  CASE WHEN @sortColumn = 'PODate' AND @sortOrder = 'ASC'    
  THEN T.PODate END ASC,     
  CASE WHEN @sortColumn = 'PODate' AND @sortOrder = 'DESC'    
  THEN T.PODate END DESC ,    
    
  CASE WHEN @sortColumn = 'POPayStatus' AND @sortOrder = 'ASC'    
  THEN T.POPayStatus END ASC,     
  CASE WHEN @sortColumn = 'POPayStatus' AND @sortOrder = 'DESC'    
  THEN T.POPayStatus END DESC ,    
    
  CASE WHEN @sortColumn = 'POCC' AND @sortOrder = 'ASC'    
  THEN T.POCC END ASC,     
  CASE WHEN @sortColumn = 'POCC' AND @sortOrder = 'DESC'    
  THEN T.POCC END DESC ,    
    
  CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'ASC'    
  THEN T.POAmount END ASC,     
  CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'DESC'    
  THEN T.POAmount END DESC ,    
    
  CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'    
  THEN T.InvoiceAmount END ASC,     
  CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'    
  THEN T.InvoiceAmount END DESC ,    
    
  CASE WHEN @sortColumn = 'Note' AND @sortOrder = 'ASC'    
  THEN T.Note END ASC,     
  CASE WHEN @sortColumn = 'Note' AND @sortOrder = 'DESC'    
  THEN T.Note END DESC    ,    
    
  CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'ASC'    
  THEN T.CreditCardIssueNumber END ASC,     
  CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'DESC'    
  THEN T.CreditCardIssueNumber END DESC,
  
  CASE WHEN @sortColumn = 'PurchaseOrderStatus' AND @sortOrder = 'ASC'    
  THEN T.PurchaseOrderStatus END ASC,     
  CASE WHEN @sortColumn = 'PurchaseOrderStatus' AND @sortOrder = 'DESC'    
  THEN T.PurchaseOrderStatus END DESC
  
 --CreditCardIssueNumber
    
SELECT @matchedCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus = 'Matched'      
SELECT @exceptionCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus = 'Exception'      
SELECT @cancelledCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus= 'Cancelled'    
SELECT @postedCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus= 'Posted' 
SELECT @unmatchedCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus= 'Unmatched'    
   
    
DECLARE @count INT       
SET @count = 0       
SELECT @count = MAX(RowNum) FROM #FinalResults_Sorted    
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
    
SELECT   
   @count AS TotalRows  
 , *  
 , @matchedCount AS MatchedCount   
 , @exceptionCount AS ExceptionCount  
 , @postedCount AS PostedCount  
 , @cancelledCount AS CancellledCount
 , @unmatchedCount AS UnMatchedCount
 
FROM #FinalResults_Sorted WHERE RowNum BETWEEN @startInd AND @endInd    
    
DROP TABLE #tmpForWhereClause    
DROP TABLE #FinalResults_Filtered    
DROP TABLE #FinalResults_Sorted  

    
END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ClientPortal_member_registration]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ClientPortal_member_registration] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 
GO

/****** Object:  StoredProcedure [dbo].[dms_ClientPortal_member_registration]    Script Date: 07/23/2013 18:44:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--EXEC [dbo].[dms_ClientPortal_member_registration] 15287507, 2, 112233445566, 2, 'THISBE', 'J', 'BESTTEST', NULL, '8177779999', '8178889999', '123 MAIN STREET', NULL, NULL, 'FORT WORTH', 44, '77111', 1, 'THISBE.BESTTEST@GMAIL.COM', '2013-07-23', '2013-07-31', 'SYSTEM'

CREATE PROCEDURE [dbo].[dms_ClientPortal_member_registration](
	@memberID INT = NULL,
	@programID INT,
	@MembershipNumber NVARCHAR(25),
	@prefixID INT = NULL,
	@firstName NVARCHAR(50),
	@middleName NVARCHAR(50) = NULL,
	@lastName NVARCHAR(50),
	@suffixID INT = NULL,
	--@homePhoneTypeID INT,
	@homePhoneNumber NVARCHAR(50) = NULL,
	--@cellPhoneTypeID INT,
	@cellPhoneNumber NVARCHAR(50) = NULL,
	@addressLine1 NVARCHAR(100),
	@addressLine2 NVARCHAR(100) = NULL,
	@addressLine3 NVARCHAR(100) = NULL,
	--@addressTypeID INT,
	@city NVARCHAR(50),
	@stateID INT,
	@zipCode NVARCHAR(10)= NULL,
	@countryID INT,
	@email NVARCHAR(50) = NULL,
	@effectiveDate DATE,
	@expirationDate DATE,
	@userName NVARCHAR(50) = 'API'
	)
AS
BEGIN

	DECLARE @prefixName NVARCHAR(50)
	DECLARE @suffixName NVARCHAR(50)
	DECLARE @countryCode NVARCHAR(50)
	DECLARE @StateCode NVARCHAR(50)
	DECLARE @MemberEntityID INT
	DECLARE @MembershipEntityID INT
	DECLARE @HomeAddressTypeID INT
	DECLARE @HomePhoneTypeID INT
	DECLARE @CellPhoneTypeID INT
	DECLARE @MembershipID INT
	DECLARE @IsPrimary BIT = 0	
	DECLARE @IsNewMembership BIT = 0
	DECLARE @CurrentDate datetime
	DECLARE @sourceSystemID INT = NULL
	
	SET @prefixName			= (SELECT Name FROM Prefix WHERE ID = @prefixID)
	SET @suffixName			= (SELECT Name FROM  Suffix WHERE ID = @suffixID)
	SET @countryCode		= (SELECT ISOCode FROM Country WHERE ID = @countryID)
	SET @StateCode			= (SELECT Abbreviation FROM StateProvince WHERE ID = @stateID)
	SET @MemberEntityID		= (SELECT ID FROM Entity WHERE Name = 'Member')
	SET @membershipEntityID	= (SELECT ID FROM Entity WHERE Name = 'Membership')
	SET @HomeAddressTypeID  = (SELECT ID FROM AddressType WHERE Name = 'Home')
	SET @HomePhoneTypeID	= (SELECT ID FROM PhoneType WHERE Name = 'Home')
	SET @CellPhoneTypeID	= (SELECT ID FROM PhoneType WHERE Name = 'Cell')
	SET @CurrentDate		= GETDATE()
	SET @sourceSystemID		= (SELECT ID FROM SourceSystem WHERE Name = 'ClientPortal')
	
	
	--IF(@memberEntityID IS NULL)
	--RAISERROR('Unable to retrieve Entity Details for Member',16,1)
	
	--IF(@membershipEntityID IS NULL)
	--RAISERROR('Unable to retrieve Entity Details for Membership',16,1)
	
	BEGIN TRY
		BEGIN TRAN
		
			-- Get membership entity already if exists
			-- Allow program change if it is within the same client
  			SELECT TOP 1 @MembershipID = ms.id
  			FROM dbo.Membership ms
  			JOIN dbo.Member m on ms.ID = m.MembershipID
  			JOIN dbo.Program p on p.ID = m.ProgramID
  			WHERE ms.MembershipNumber = @MembershipNumber
  			AND p.ClientID = (SELECT ClientID FROM Program WHERE ID = @ProgramID)
  			AND (@memberID IS NULL OR m.ID = @MemberID)

			IF(@membershipID IS NULL) AND (@MemberID IS NOT NULL)
				RAISERROR('Unable to retrieve Membership Details for the supplied Member ID',16,1)

			-- Create new membership entity if not exists
			IF (@MembershipID IS NULL) 
			BEGIN
				-- TODO: Set ClientMembershipKey based on program rule
				INSERT INTO Membership(
					MembershipNumber,	SourceSystemID, -- KB: TFS: 2436 - Set SourceSystemID on Member and Membership.
					Email,				IsActive,			
					CreateDate,			CreateBy)
				VALUES (@MembershipNumber, @sourceSystemID,
					@email,				1,
					@CurrentDate,			@userName)
				
				-- Hold on to new Membership ID 
				SET @MembershipID = SCOPE_IDENTITY()

				-- If initial add of the membership then make this member the primary
				SET @IsPrimary = 1
				SET @IsNewMembership = 1
			END
			
			-- Determine if existing member is primary
			IF (@MemberID IS NOT NULL)
				SET @IsPrimary = ISNULL((SELECT IsPrimary FROM Member(NOLOCK) WHERE ID = @memberID),0)
				
			-- Insert or Update MemberShip Record if new membership or existing member is Primary
			IF (@MembershipID IS NOT NULL) AND @IsPrimary = 1 
			BEGIN
				
				DECLARE @MembershipAddressID INT
				DECLARE @MembershipHomePhoneID INT
			
				SET @MembershipAddressID	  = (SELECT ID FROM AddressEntity(NOLOCK) WHERE EntityID = @MembershipEntityID AND RecordID = @membershipID AND AddressTypeID = @HomeAddressTypeID)
				SET @MembershipHomePhoneID	  = (SELECT ID FROM PhoneEntity(NOLOCK) WHERE EntityID = @MembershipEntityID AND RecordID = @membershipID AND PhoneTypeID = @HomePhoneTypeID)

				-- Don't update membership if just added
				IF @IsNewMembership <> 1
					UPDATE Membership 
					SET 
						Email		= @email,
						ModifyBy	= @userName,
						ModifyDate	= @CurrentDate
					WHERE ID = @membershipID
					
				-- Create Membership Address Entity Record if not exists
				IF (@MembershipAddressID IS NULL)
					INSERT INTO AddressEntity(
							EntityID,				RecordID,		AddressTypeID,
							Line1,					Line2,			Line3,
							City,					StateProvince,	PostalCode,
							StateProvinceID,		CountryID,		CountryCode,
							CreateDate,				CreateBy)
					VALUES (					  
							@MembershipEntityID,	@MembershipID,	@HomeAddressTypeID,
							@addressLine1,			@addressLine2,	@addressLine3,
							@city,					@StateCode,		@zipCode,
							@stateID,				@countryID,		@countryCode,
							@CurrentDate,			@userName)
				
				-- Update Membership address
				IF (@MembershipAddressID IS NOT NULL)
					UPDATE AddressEntity 
					SET 
						AddressTypeID		= @HomeAddressTypeID,
						Line1				= @addressLine1,			
						Line2				= @addressLine2,			
						Line3				= @addressLine3,
						City				= @city,				
						StateProvince		= @StateCode,	
						PostalCode			= @zipCode,
						StateProvinceID		= @stateID,	
						CountryID			= @countryID,		
						CountryCode			= @countryCode,
						ModifyBy		    = @userName,			
						ModifyDate			= @CurrentDate
					WHERE 
						ID					= @MembershipAddressID

				-- Create Membership Home Phone Entity is not exists
				IF (@MembershipHomePhoneID IS NULL) AND (ISNULL(@HomePhoneNumber,'') <> '')
					INSERT INTO PhoneEntity  (
						EntityID,				RecordID,		PhoneTypeID,
						PhoneNumber,			CreateDate,		CreateBy)
					VALUES (
						@MembershipEntityID,	@MembershipID,	@homePhoneTypeID,
						@homePhoneNumber,		@CurrentDate,	@userName)		
						
				-- Update Existing Membership Home Phone Entity
				IF (@MembershipHomePhoneID IS NOT NULL)
					UPDATE PhoneEntity  
					SET
						PhoneNumber		= @homePhoneNumber,	
						ModifyDate		= @CurrentDate,
						ModifyBy		= @userName
					WHERE 
						ID				= @MembershipHomePhoneID
			END


			-- Insert member if not existing
			IF(@MemberID IS NULL)
			BEGIN
				-- Create Member Record
				INSERT INTO Member(
					MembershipID,	ProgramID,
					SourceSystemID,		
					Prefix,			FirstName,
					MiddleName,		LastName,
					Suffix,	    	Email,
					EffectiveDate,	ExpirationDate,
					IsPrimary,		IsActive,
					CreateDate,		CreateBy)
				VALUES(			   
					@MembershipID,	@programID,
					@sourceSystemID,
					@prefixName,	@firstName,
					@middleName,	@lastName,
					@suffixName,	@email,
					@effectiveDate,	@expirationDate,
					@IsPrimary,		1,				
					@CurrentDate,	@userName)
				
				
				-- Set member ID value
				SET @MemberID = SCOPE_IDENTITY()
				
			END
			ELSE IF (@memberID IS NOT NULL)
			BEGIN
				-- Update existing member record
				UPDATE Member SET
								   ProgramID	 = @programID,
								   Prefix		 = @prefixName,			
								   FirstName	 = @firstName,
								   MiddleName	 = @middleName,		
								   LastName		 = @lastName,
								   Suffix		 = @suffixName,	    	
								   Email		 = @email,
								   EffectiveDate = @effectiveDate,	
								   ExpirationDate= @expirationDate,
								   ModifyDate	 = @CurrentDate,		
								   ModifyBy      = @userName
							 WHERE ID = @memberID
			END
			
			
			-- Retrieve associated recordID
			DECLARE @MemberAddressID INT
			DECLARE @MemberHomePhoneID INT
			DECLARE @MemberCellPhoneID INT
			
			SET @MemberAddressID	  = (SELECT ID FROM AddressEntity(NOLOCK) WHERE EntityID = @MemberEntityID AND RecordID = @memberID AND AddressTypeID = @HomeAddressTypeID)
			SET @MemberHomePhoneID	  = (SELECT ID FROM PhoneEntity(NOLOCK) WHERE EntityID = @MemberEntityID AND RecordID = @memberID AND PhoneTypeID = @HomePhoneTypeID)
			SET @MemberCellPhoneID	  = (SELECT ID FROM PhoneEntity(NOLOCK) WHERE EntityID = @MemberEntityID AND RecordID = @memberID AND PhoneTypeID = @CellPhoneTypeID)

			-- Create Address Record
			IF (@MemberAddressID IS NULL)	
				INSERT INTO AddressEntity(
					EntityID,			RecordID,		AddressTypeID,
					Line1,				Line2,			Line3,
					City,				StateProvince,	PostalCode,
					StateProvinceID,	CountryID,		CountryCode,
					CreateBy,			CreateDate)
				VALUES(					  
					@MemberEntityID,	@MemberID,		@HomeAddressTypeID,
					@addressLine1,		@addressLine2,	@addressLine3,
					@city,				@StateCode,		@zipCode,
					@stateID,			@countryID,		@countryCode,
					@userName,			@CurrentDate)
			
			
			-- Update Address Entity
			IF (@MemberAddressID IS NOT NULL)	
			UPDATE	AddressEntity 
			SET 
				  AddressTypeID		= @HomeAddressTypeID,
				  Line1				= @addressLine1,			
				  Line2				= @addressLine2,			
				  Line3				= @addressLine3,
				  City				= @city,				
				  StateProvince		= @StateCode,	
				  PostalCode		= @zipCode,
				  StateProvinceID	= @stateID,	
				  CountryID			= @countryID,		
				  CountryCode		= @countryCode,
				  ModifyBy		    = @userName,			
				  ModifyDate		= @CurrentDate
			WHERE ID = @MemberAddressID
			
			-- Insert Home Phone entity if not exists
			IF (@MemberHomePhoneID IS NULL)	AND (ISNULL(@HomePhoneNumber,'') <> '')				
				INSERT INTO PhoneEntity  (
					EntityID,			RecordID,	  PhoneTypeID,
					PhoneNumber,	    CreateDate,   CreateBy)
				VALUES(					  
					@MemberEntityID,	@MemberID, @HomePhoneTypeID,
					@homePhoneNumber,	@CurrentDate, @userName)	
						
			-- Update Existing Member Home Phone Entity
			IF (@MemberHomePhoneID IS NOT NULL)					
				UPDATE PhoneEntity  
				SET
					  PhoneNumber	= @homePhoneNumber,	
					  ModifyDate	= @CurrentDate,
					  ModifyBy		= @userName
				WHERE ID = @MemberHomePhoneID
				
			-- Insert Member Cell Phone entity if not exists
			IF (@MemberCellPhoneID IS NULL)	AND (ISNULL(@CellPhoneNumber,'') <> '')				
				INSERT INTO PhoneEntity  (
					EntityID,			RecordID,	  PhoneTypeID,
					PhoneNumber,	    CreateDate,   CreateBy)
				VALUES(					  
					@MemberEntityID,	@MemberID, @CellPhoneTypeID,
					@CellPhoneNumber,	@CurrentDate, @userName)	
								
			-- Update Existing Member Cell Phone Entity
			IF (@MemberCellPhoneID IS NOT NULL)					
				UPDATE PhoneEntity  
				SET
					PhoneNumber = @cellPhoneNumber,	
					ModifyDate = @CurrentDate,
					ModifyBy = @userName
				WHERE ID = @MemberCellPhoneID				

		COMMIT TRAN
	END TRY
	
	
	BEGIN CATCH
		-- XACT_STATE =  0  means there is no transaction
		-- XACT_STATE =  1  means transaction is uncommittable
		-- XACT_STATE = -1  means it's active transaction and valid
		IF (XACT_STATE() = -1 OR XACT_STATE() = 1)
			BEGIN
				ROLLBACK TRANSACTION;
			END;
	
		DECLARE 
			@ErrorMessage    NVARCHAR(4000),
			@ErrorNumber     INT,
			@ErrorSeverity   INT,
			@ErrorState      INT,
			@ErrorLine       INT,
			@ErrorProcedure  NVARCHAR(200);

		-- Assign variables to error-handling functions that 
		-- capture information for RAISERROR.
		SELECT 
			@ErrorNumber = ERROR_NUMBER(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE(),
			@ErrorLine = ERROR_LINE(),
			@ErrorProcedure = ISNULL(ERROR_PROCEDURE(), '-');
		 RAISERROR 
			(
			@ErrorMessage, 
			@ErrorSeverity, 
			1,               
			@ErrorNumber,    -- parameter: original error number.
			@ErrorSeverity,  -- parameter: original error severity.
			@ErrorState,     -- parameter: original error state.
			@ErrorProcedure, -- parameter: original error procedure name.
			@ErrorLine       -- parameter: original error line number.
			);
	END CATCH
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
 WHERE id = object_id(N'[dbo].[dms_Client_OpenPeriod]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Client_OpenPeriod] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Client_OpenPeriod]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
	SET FMTONLY OFF

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
BillingScheduleIDOperator="-1" 
ScheduleNameOperator="-1" 
ScheduleDateOperator="-1" 
ScheduleRangeBeginOperator="-1" 
ScheduleRangeEndOperator="-1" 
StatusOperator="-1" 
InvoicesToBeCreatedCountOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
BillingScheduleIDOperator INT NOT NULL,
BillingScheduleIDValue int NULL,
ScheduleNameOperator INT NOT NULL,
ScheduleNameValue nvarchar(100) NULL,
ScheduleDateOperator INT NOT NULL,
ScheduleDateValue datetime NULL,
ScheduleRangeBeginOperator INT NOT NULL,
ScheduleRangeBeginValue datetime NULL,
ScheduleRangeEndOperator INT NOT NULL,
ScheduleRangeEndValue datetime NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL,
InvoicesToBeCreatedCountOperator INT NOT NULL,
InvoicesToBeCreatedCountValue int NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	BillingScheduleID int  NULL ,
	ScheduleName nvarchar(50)  NULL ,
	ScheduleDate datetime  NULL ,
	ScheduleRangeBegin datetime  NULL ,
	ScheduleRangeEnd datetime  NULL ,
	Status nvarchar(50)  NULL ,
	InvoicesToBeCreatedCount int  NULL 
) 

DECLARE @QueryResult AS TABLE( 
	BillingScheduleID int  NULL ,
	ScheduleName nvarchar(50)  NULL ,
	ScheduleDate datetime  NULL ,
	ScheduleRangeBegin datetime  NULL ,
	ScheduleRangeEnd datetime  NULL ,
	Status nvarchar(50)  NULL ,
	InvoicesToBeCreatedCount int  NULL 
) 

INSERT INTO @QueryResult
SELECT	bs.ID as BillingScheduleID,
		bs.Name as ScheduleName,
		bs.ScheduleDate,
		bs.ScheduleRangeBegin,
		bs.ScheduleRangeEnd,
		bss.Name as [Status],
		tt.InvoicesToBeCreatedCount
FROM	BillingSchedule bs with (nolock)
left outer join	BillingScheduleType bst with (nolock) on bst.ID = bs.ScheduleTypeID
left outer join	BillingScheduleStatus bss with (nolock) on bss.ID = bs.ScheduleStatusID
left outer join	BillingScheduleRangeType bsrt with (nolock) on bsrt.ID = bs.ScheduleRangeTypeID
left outer join	BillingScheduleDateType bsdt with (nolock) on bsdt.ID = bs.ScheduleDateTypeID
left outer join
	(SELECT bs.ID AS BillingScheduleID, 
			count(*) InvoicesToBeCreatedCount
	from	BillingSchedule bs
	join	BillingDefinitionInvoice bdi on bdi.ScheduleTypeID = bs.ScheduleTypeID
	and		bdi.ScheduleDateTypeID = bs.ScheduleDateTypeID
	and		bdi.ScheduleRangeTypeID = bs.ScheduleRangeTypeID
	and		bdi.IsActive = 1
	group by
			bs.ID
	)tt on tt.BillingScheduleID = bs.ID
WHERE bss.Name = 'PENDING' 
	and bs.IsActive = 1

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@BillingScheduleIDOperator','INT'),-1),
	T.c.value('@BillingScheduleIDValue','int') ,
	ISNULL(T.c.value('@ScheduleNameOperator','INT'),-1),
	T.c.value('@ScheduleNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ScheduleDateOperator','INT'),-1),
	T.c.value('@ScheduleDateValue','datetime') ,
	ISNULL(T.c.value('@ScheduleRangeBeginOperator','INT'),-1),
	T.c.value('@ScheduleRangeBeginValue','datetime') ,
	ISNULL(T.c.value('@ScheduleRangeEndOperator','INT'),-1),
	T.c.value('@ScheduleRangeEndValue','datetime') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@InvoicesToBeCreatedCountOperator','INT'),-1),
	T.c.value('@InvoicesToBeCreatedCountValue','int') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.BillingScheduleID,
	T.ScheduleName,
	T.ScheduleDate,
	T.ScheduleRangeBegin,
	T.ScheduleRangeEnd,
	T.Status,
	T.InvoicesToBeCreatedCount
FROM @QueryResult T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.BillingScheduleIDOperator = -1 ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 0 AND T.BillingScheduleID IS NULL ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 1 AND T.BillingScheduleID IS NOT NULL ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 2 AND T.BillingScheduleID = TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 3 AND T.BillingScheduleID <> TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 7 AND T.BillingScheduleID > TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 8 AND T.BillingScheduleID >= TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 9 AND T.BillingScheduleID < TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 10 AND T.BillingScheduleID <= TMP.BillingScheduleIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleNameOperator = -1 ) 
 OR 
	 ( TMP.ScheduleNameOperator = 0 AND T.ScheduleName IS NULL ) 
 OR 
	 ( TMP.ScheduleNameOperator = 1 AND T.ScheduleName IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleNameOperator = 2 AND T.ScheduleName = TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 3 AND T.ScheduleName <> TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 4 AND T.ScheduleName LIKE TMP.ScheduleNameValue + '%') 
 OR 
	 ( TMP.ScheduleNameOperator = 5 AND T.ScheduleName LIKE '%' + TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 6 AND T.ScheduleName LIKE '%' + TMP.ScheduleNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ScheduleDateOperator = -1 ) 
 OR 
	 ( TMP.ScheduleDateOperator = 0 AND T.ScheduleDate IS NULL ) 
 OR 
	 ( TMP.ScheduleDateOperator = 1 AND T.ScheduleDate IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleDateOperator = 2 AND T.ScheduleDate = TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 3 AND T.ScheduleDate <> TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 7 AND T.ScheduleDate > TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 8 AND T.ScheduleDate >= TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 9 AND T.ScheduleDate < TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 10 AND T.ScheduleDate <= TMP.ScheduleDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleRangeBeginOperator = -1 ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 0 AND T.ScheduleRangeBegin IS NULL ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 1 AND T.ScheduleRangeBegin IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 2 AND T.ScheduleRangeBegin = TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 3 AND T.ScheduleRangeBegin <> TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 7 AND T.ScheduleRangeBegin > TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 8 AND T.ScheduleRangeBegin >= TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 9 AND T.ScheduleRangeBegin < TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 10 AND T.ScheduleRangeBegin <= TMP.ScheduleRangeBeginValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleRangeEndOperator = -1 ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 0 AND T.ScheduleRangeEnd IS NULL ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 1 AND T.ScheduleRangeEnd IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 2 AND T.ScheduleRangeEnd = TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 3 AND T.ScheduleRangeEnd <> TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 7 AND T.ScheduleRangeEnd > TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 8 AND T.ScheduleRangeEnd >= TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 9 AND T.ScheduleRangeEnd < TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 10 AND T.ScheduleRangeEnd <= TMP.ScheduleRangeEndValue ) 

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
	 ( TMP.InvoicesToBeCreatedCountOperator = -1 ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 0 AND T.InvoicesToBeCreatedCount IS NULL ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 1 AND T.InvoicesToBeCreatedCount IS NOT NULL ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 2 AND T.InvoicesToBeCreatedCount = TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 3 AND T.InvoicesToBeCreatedCount <> TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 7 AND T.InvoicesToBeCreatedCount > TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 8 AND T.InvoicesToBeCreatedCount >= TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 9 AND T.InvoicesToBeCreatedCount < TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 10 AND T.InvoicesToBeCreatedCount <= TMP.InvoicesToBeCreatedCountValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'ASC'
	 THEN T.BillingScheduleID END ASC, 
	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'DESC'
	 THEN T.BillingScheduleID END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleName' AND @sortOrder = 'ASC'
	 THEN T.ScheduleName END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleName' AND @sortOrder = 'DESC'
	 THEN T.ScheduleName END DESC ,

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

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC ,

	 CASE WHEN @sortColumn = 'InvoicesToBeCreatedCount' AND @sortOrder = 'ASC'
	 THEN T.InvoicesToBeCreatedCount END ASC, 
	 CASE WHEN @sortColumn = 'InvoicesToBeCreatedCount' AND @sortOrder = 'DESC'
	 THEN T.InvoicesToBeCreatedCount END DESC 


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
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_tempcc_match_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_tempcc_match_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vendor_tempcc_match_update] @tempccIdXML = '<Tempcc><ID>1</ID><ID>2</ID><ID>3</ID><ID>4</ID></Tempcc>',@currentUser = 'demouser'
 CREATE PROCEDURE [dbo].[dms_vendor_tempcc_match_update](
	@tempccIdXML XML,
	@currentUser NVARCHAR(50)
 )
 AS
 BEGIN
 
    SET FMTONLY OFF
	SET NOCOUNT ON

	DECLARE @now DATETIME = GETDATE()
	DECLARE @MinCreateDate datetime

	DECLARE @Matched INT =0
		,@MatchedAmount money =0
		,@Unmatched int = 0
		,@UnmatchedAmount money = 0
		,@Posted INT=0
		,@PostedAmount money=0
		,@Cancelled INT=0
		,@CancelledAmount money=0
		,@Exception INT=0
		,@ExceptionAmount money=0
		,@MatchedIds nvarchar(max)=''

	DECLARE @MatchedTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Matched')
		,@UnMatchedTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'UnMatched')
		,@PostededTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Posted')
		,@CancelledTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Cancelled')
		,@ExceptionTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Exception')

	-- Build table of selected items
	CREATE TABLE #SelectedTemporaryCC 
	(	
		ID INT IDENTITY(1,1),
		TemporaryCreditCardID INT
	)

	INSERT INTO #SelectedTemporaryCC
	SELECT tcc.ID
	FROM TemporaryCreditCard tcc WITH (NOLOCK)
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @tempccIdXML.nodes('/Tempcc/ID') T(c)
			) T ON tcc.ID = T.ID

	CREATE CLUSTERED INDEX IDX_SelectedTemporaryCC ON #SelectedTemporaryCC(TemporaryCreditCardID)

		
	/**************************************************************************************************/
	-- Update (Reset) Selected items to Unmatched where status is not Posted
	UPDATE tc SET 
		TemporaryCreditCardStatusID = @UnmatchedTemporaryCreditCardStatusID
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = NULL
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	WHERE tcs.Name <> 'Posted'


	/**************************************************************************************************/
	--Update for Exact match on PO# and CC#
	--Conditions:
	--	PO# AND CC# match exactly
	--	PO Status is Issued or Issued Paid
	--	PO has not been deleted
	--	PO does not already have a related Vendor Invoice
	--	Temporary CC has not already been posted
	--Match Status
	--	Total CC charge amount LESS THAN or EQUAL to the PO amount
	--Exception Status
	--	Total CC charge amount GREATER THAN the PO amount
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE 
				 --Match
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND po.PayStatusCodeID = (Select ID FROM PurchaseOrderPayStatusCode WHERE Name = 'PaidByCC')
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > 0
						AND ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount 
					THEN @MatchedTemporaryCreditCardStatusID
				 --Cancelled	
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID = (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Cancelled') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) = 0
					THEN @CancelledTemporaryCreditCardStatusID
				 --Exception
				 ELSE @ExceptionTemporaryCreditCardStatusID
				 END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				 --Match
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > 0
						AND ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount 
					THEN NULL
				 --Cancelled	
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID = (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Cancelled') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) = 0
					THEN NULL
				 --Exception: Invalid purchase order payment status
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND po.PayStatusCodeID <> (Select ID FROM PurchaseOrderPayStatusCode WHERE Name = 'PaidByCC')
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > 0
						AND ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount 
					THEN 'Invalid purchase order payment status'
				 --Exception: Charge more than PO Amount
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) = 0
					THEN 'Matching credit card has not been charged'
				 --Exception: Charge more than PO Amount
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > po.PurchaseOrderAmount 
					THEN 'Charge amount exceeds PO amount'
				 -- Other Exceptions	
				 WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 ELSE NULL
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = RIGHT(tc.CreditCardNumber,5)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID
	WHERE 1=1
	AND tcs.Name = 'Unmatched'
		
		
	/**************************************************************************************************/
	-- Update For No matches on PO# or CC#
	-- Conditions:
	--	No potential PO matches exist
	--  No potential CC# matches exist
	-- Cancelled Status
	--	Temporary Credit Card Issue Status is Cancelled
	-- Exception Status
	--	Temporary Credit Card Issue Status is NOT Cancelled
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE WHEN tc.IssueStatus = 'Cancelled' THEN @CancelledTemporaryCreditCardStatusID
				 ELSE @ExceptionTemporaryCreditCardStatusID
				 END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE WHEN tc.IssueStatus = 'Cancelled' THEN NULL
				 ELSE 'No matching PO# or CC#'
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	WHERE  1=1
	AND tcs.Name = 'Unmatched'
	AND NOT EXISTS (
		SELECT *
		FROM PurchaseOrder po
		WHERE
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		)
	AND NOT EXISTS (
		SELECT *
		FROM PurchaseOrder po
		WHERE  
		po.PurchaseOrderNumber <> LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND po.CompanyCreditCardNumber IS NOT NULL
		AND RIGHT(RTRIM(po.CompanyCreditCardNumber),5) = RIGHT(tc.CreditCardNumber,5)
		)


	/**************************************************************************************************/
	--Update to Exception Status - PO matches and CC# does not match
	-- Conditions
	--	PO# matches exactly
	--	CC# does not match or is blank
	UPDATE tc SET
		TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 WHEN RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = '' THEN 'Matching PO does not have a credit card number'
				 ELSE 'CC# Mismatch'
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND	RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) <> RIGHT(tc.CreditCardNumber,5)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID
	where tcs.Name = 'Unmatched'


	/**************************************************************************************************/
	--Update to Exception Status - PO does not match and CC# matches
	-- Conditions
	--	PO# does not match
	--	CC# matches exactly
	UPDATE tc SET
		TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 ELSE 'PO# Mismatch'
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber <> LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND	RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = RIGHT(tc.CreditCardNumber,5)
		AND po.CreateDate <= DATEADD(dd,1,tc.IssueDate)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID
	where tcs.Name = 'Unmatched'


	/**************************************************************************************************/
	-- Prepare Results
	SELECT 
		@Matched = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @MatchedTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@MatchedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @MatchedTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Unmatched = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @UnMatchedTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@UnmatchedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @UnMatchedTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Posted = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @PostededTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@PostedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @PostededTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Cancelled = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @CancelledTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@CancelledAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @CancelledTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Exception = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@ExceptionAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID

	-- Build string of 'Matched' IDs
	SELECT @MatchedIds = @MatchedIds + CONVERT(varchar(20),tc.ID) + ',' 
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	WHERE tc.TemporaryCreditCardStatusID = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Matched')

	-- Remove ending comma from string or IDs
	IF LEN(@MatchedIds) > 1 
		SET @MatchedIds = LEFT(@MatchedIds, LEN(@MatchedIds) - 1)

	DROP TABLE #SelectedTemporaryCC
	
	SELECT @Matched 'MatchedCount',
		   @MatchedAmount 'MatchedAmount',
		   --@Unmatched 'UnmatchedCount',
		   --@UnmatchedAmount 'UnmatchedAmount',
		   @Posted 'PostedCount',
		   @PostedAmount 'PostedAmount',
		   @Cancelled 'CancelledCount',
		   @CancelledAmount 'CancelledAmount',
		   @Exception 'ExceptionCount',
		   @ExceptionAmount 'ExceptionAmount',
		   @MatchedIds 'MatchedIds'
END

GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Client_OpenPeriodProcess]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Client_OpenPeriodProcess] 
END 
GO
-- EXCE dms_Client_OpenPeriodProcess @billingSchedules = '1,2',@userName = 'demoUser',@sessionID = 'XX12',@pageReference = 'Test'
CREATE PROC [dbo].[dms_Client_OpenPeriodProcess](@billingSchedules NVARCHAR(MAX),@userName NVARCHAR(100),@sessionID NVARCHAR(MAX),@pageReference NVARCHAR(MAX))
AS
BEGIN
		BEGIN TRY
		BEGIN TRAN
			DECLARE @BillingScheduleID AS TABLE(RecordID INT IDENTITY(1,1), BillingScheduleID INT)
			INSERT INTO @BillingScheduleID(BillingScheduleID) SELECT item FROM dbo.fnSplitString(@billingSchedules,',')
			DECLARE @scheduleID AS INT
			DECLARE @ProcessingCounter AS INT = 1
			DECLARE @TotalRows AS INT
			SELECT  @TotalRows = MAX(RecordID) FROM @BillingScheduleID
	
			DECLARE @entityID AS INT 
			DECLARE @eventID AS INT
			DECLARE	@eventDescription AS NVARCHAR(MAX)
			SELECT  @entityID = ID FROM Entity WHERE Name = 'BillingInvoice'
			SELECT  @eventID =  ID FROM Event WHERE Name = 'OpenPeriod'
			SELECT  @eventDescription =  Description FROM Event WHERE Name = 'OpenPeriod'

			WHILE @ProcessingCounter <= @TotalRows
			BEGIN
					SET @scheduleID = (SELECT BillingScheduleID FROM @BillingScheduleID WHERE RecordID = @ProcessingCounter)
			
					-- Write Process Logic for Schedule ID
					DECLARE @pScheduleTypeID AS INT,
					@pScheduledDateTypeID AS INT,
					@pScheduleRangeTypeID AS INT;

					DECLARE @pInvoiceXML AS NVARCHAR(MAX)
			
					SELECT  @pScheduleTypeID = ScheduleTypeID,
							@pScheduledDateTypeID = ScheduleDateTypeID,
							@pScheduleRangeTypeID = ScheduleRangeTypeID
					FROM    BillingSchedule
					WHERE   ID = @scheduleID

					--SELECT * FROM BillingSchedule
					SELECT	    @pInvoiceXML = [dbo].[fnConcatenate](ID)
					FROM        BillingDefinitionInvoice
					WHERE       IsActive = 1
					AND         ScheduleTypeID = @pScheduleTypeID
					AND         ScheduleDateTypeID = @pScheduledDateTypeID
					AND         ScheduleRangeTypeID = @pScheduleRangeTypeID
			
					SET @pInvoiceXML = '<Records><BillingDefinitionInvoiceID>' + REPLACE(@pInvoiceXML,',','</BillingDefinitionInvoiceID><BillingDefinitionInvoiceID>') + '</BillingDefinitionInvoiceID></Records>'

					EXEC dbo.dms_BillingGenerateInvoices 
					@pUserName  = @userName,
					@pScheduleTypeID = @pScheduleTypeID,
					@pScheduleDateTypeID = @pScheduledDateTypeID,
					@pScheduleRangeTypeID = @pScheduleRangeTypeID,
					@pInvoicesXML = @pInvoiceXML

					-- Create Event Logs Reocords
					INSERT INTO		EventLog([EventID],				[SessionID],				[Source],			[Description],
									[Data],				[NotificationQueueDate],	[CreateBy],			[CreateDate]) 
						VALUES		(@eventID,				@sessionID,					@pageReference,	   @eventDescription,
									NULL,					NULL,						@userName,			GETDATE())
			
					-- CREATE Link Records
					INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) VALUES(SCOPE_IDENTITY(),@entityID,@scheduleID)
			
					UPDATE	BillingSchedule
					SET		ScheduleStatusID = (SELECT ID From BillingScheduleStatus WHERE Name = 'OPEN')
					WHERE	ID = @scheduleID
			
					SET @ProcessingCounter = @ProcessingCounter + 1
			END
			
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		DECLARE @ErrorMessage    NVARCHAR(4000)			
		-- Assign variables to error-handling functions that 
		-- capture information for RAISERROR.
		SELECT  @ErrorMessage = ERROR_MESSAGE();
		RAISERROR(@ErrorMessage,16,1);
	END CATCH
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Location_Virtual_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
	DROP PROCEDURE [dbo].[dms_Vendor_Location_Virtual_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  
 --EXEC dms_Vendor_Location_Virtual_get 640
 CREATE PROCEDURE [dbo].[dms_Vendor_Location_Virtual_get]( 
	@vendorLocationID int = NULL
 ) 
 AS 
 BEGIN
	Select 
	VLV.LocationAddress,
	VLV.LocationCity,
	VLV.LocationStateProvince,
	VLV.LocationCountryCode,
	VLV.LocationPostalCode,
	VLV.Latitude,
	VLV.Longitude,
	CONVERT(NVARCHAR(MAX),VLV.GeographyLocation) AS GeographyLocation
FROM VendorLocationVirtual VLV 
LEFT JOIN VendorLocation VL ON VL.ID= VLV.VendorLocationID
where VendorLocationID = @vendorLocationID

 END
 GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_PO_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_PO_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_PO_Details_Get @PONumber=7770395
 CREATE PROCEDURE [dbo].dms_Vendor_Invoice_PO_Details_Get( 
	@PONumber nvarchar(50) =NULL
	)
AS
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 SET FMTONLY OFF  
  
SELECT  PO.ID  
   , CASE  
    WHEN ISNULL(PO.IsPayByCompanyCreditCard,'') = 1 THEN 'Paid with company credit card'  
    ELSE ''  
     END AS [AlertText]  
   , PO.PurchaseOrderNumber AS [PONumber]  
   , POS.Name AS [POStatus]  
   , PO.PurchaseOrderAmount AS [POAmount]  
   , PC.Name AS [Service]  
   , PO.IssueDate AS [IssueDate]  
   , PO.ETADate AS [ETADate]  
   , PO.VendorLocationID     
   --, CASE  
   --WHEN ISNULL(CRS.ID,'') = '' THEN 'Not Contracted'  
   --ELSE 'Contracted'  
   --END AS 'ContractStatus'  
   , CASE  
    WHEN ContractedVendors.ContractID IS NOT NULL AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'  
    ELSE 'Not Contracted'   
     END AS ContractStatus  
   , V.Name AS [VendorName]  
   , V.VendorNumber AS [VendorNumber]  
   , ISNULL(PO.BillingAddressLine1,'') AS [VendorLocationLine1]  
   , ISNULL(PO.BillingAddressLine2,'') AS [VendorLocationLine2]  
   , ISNULL(PO.BillingAddressLine3,'') AS [VendorLocationLine3]   
   , ISNULL(REPLACE(RTRIM(  
      COALESCE(PO.BillingAddressCity, '') +   
      COALESCE(', ' + RTRIM(PO.BillingAddressStateProvince), '') +       
      COALESCE(' ' + PO.BillingAddressPostalCode, '') +            
      COALESCE(' ' + PO.BillingAddressCountryCode, '')   
     ), '  ', ' ')  
     ,'') AS [VendorLocationCityStZip]  
   , PO.DispatchPhoneNumber AS [DispatchPhoneNumber]  
   , PO.FaxPhoneNumber AS [FaxPhoneNumber]  
   , 'TalkedTo' AS [TalkedTo] -- TODO: Linked to ContactLog and get Talked To  
   , CL.Name AS [Client]  
   , P.Name AS [Program]  
   , MS.MembershipNumber AS [MemberNumber]  
   , C.MemberStatus  
   , REPLACE(RTRIM(  
    COALESCE(CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+  
    COALESCE(' ' + LEFT(M.MiddleName,1),'')+  
    COALESCE(' ' + CASE WHEN M.LastName = '' THEN NULL ELSE M.LastName END,'')+    
    COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')  
    ),'','') AS [CustomerName]  
   , C.ContactPhoneNumber AS [CallbackNumber]   
   , C.ContactAltPhoneNumber AS [AlternateNumber]  
   --, PO.SubTotal AS [SubTotal]  calculated from PO Details GRID  
   , PO.TaxAmount AS [Tax]  
   , PO.TotalServiceAmount AS [ServiceTotal]  
   , PO.CoachNetServiceAmount AS [CoachNetPays]  
   , PO.MemberServiceAmount AS [MemberPays]  
   , VT.Name + ' - ' + VC.Name AS [VehicleType]  
   , REPLACE(RTRIM(  
    COALESCE(C.VehicleYear,'')+  
    COALESCE(' ' + CASE WHEN C.VehicleMake = 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END,'')+  
    COALESCE(' ' + CASE WHEN C.VehicleModel = 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END,'')  
    ), '','') AS [Vehicle]  
   , ISNULL(C.VehicleVIN,'') AS [VIN]  
   , ISNULL(C.VehicleColor,'') AS [Color]  
   , REPLACE(RTRIM(  
     COALESCE(C.VehicleLicenseState + ' - ','') +  
     COALESCE(C.VehicleLicenseNumber,'')   
    ),'','') AS [License]  
   , ISNULL(C.VehicleCurrentMileage,'') AS [Mileage]  
   , ISNULL(SR.ServiceLocationAddress,'') AS [Location]  
   , ISNULL(SR.ServiceLocationDescription,'') AS [LocationDescription]  
   , ISNULL(SR.DestinationAddress,'') AS [Destination]  
   , ISNULL(SR.DestinationDescription,'') AS [DestinationDescription]  
   , PO.CreateBy  
   , PO.CreateDate  
   , PO.ModifyBy  
   , PO.ModifyDate   
   , CT.Abbreviation AS [CurrencyType]   
   , PO.IsPayByCompanyCreditCard AS IsPayByCC  
   , PO.CompanyCreditCardNumber CompanyCC  
   ,PO.VendorTaxID  
   ,PO.Email  
   ,POPS.[Description] PurchaseOrderPayStatus  
FROM  PurchaseOrder PO   
JOIN  PurchaseOrderStatus POS WITH (NOLOCK)ON POS.ID = PO.PurchaseOrderStatusID  
LEFT JOIN PurchaseOrderPayStatusCode POPS WITH (NOLOCK) ON POPS.ID = PO.PayStatusCodeID  
JOIN  ServiceRequest SR WITH (NOLOCK) ON SR.ID = PO.ServiceRequestID  
LEFT JOIN ServiceRequestStatus SRS WITH (NOLOCK) ON SRS.ID = SR.ServiceRequestStatusID  
LEFT JOIN ProductCategory PCSR ON PCSR.ID = SR.ProductCategoryID  
JOIN  [Case] C WITH (NOLOCK) ON C.ID = SR.CaseID  
JOIN  Program P WITH (NOLOCK) ON P.ID = C.ProgramID  
JOIN  Client CL WITH (NOLOCK) ON CL.ID = P.ClientID  
JOIN  Member M WITH (NOLOCK) ON M.ID = C.MemberID  
JOIN  Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID  
JOIN  Product PR WITH (NOLOCK) ON PR.ID = PO.ProductID  
JOIN  ProductCategory PC WITH (NOLOCK) ON PC.ID = PR.ProductCategoryID  
LEFT JOIN VehicleType VT WITH(NOLOCK) ON VT.ID = C.VehicleTypeID  
LEFT JOIN VehicleCategory VC WITH(NOLOCK) ON VC.ID = C.VehicleCategoryID  
LEFT JOIN RVType RT WITH (NOLOCK) ON RT.ID = C.VehicleRVTypeID  
JOIN  VendorLocation VL WITH(NOLOCK) ON VL.ID = PO.VendorLocationID  
JOIN  Vendor V WITH(NOLOCK) ON V.ID = VL.VendorID  
--LEFT JOIN [Contract] CO ON CO.VendorID = V.ID  AND CO.IsActive = 1  
--LEFT JOIN ContractRateSchedule CRS ON CRS.ContractID = V.ID AND CO.IsActive = 1  
LEFT OUTER JOIN(  
    SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID  
    FROM dbo.fnGetContractedVendors() cv  
    ) ContractedVendors ON v.ID = ContractedVendors.VendorID   
LEFT JOIN CurrencyType CT ON CT.ID=PO.CurrencyTypeID  
WHERE  PO.PurchaseOrderNumber = @PONumber  
   AND PO.IsActive = 1  
  
END  
GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Info]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Info] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_Vendor_Info] 238
 CREATE PROCEDURE [dbo].[dms_Vendor_Info]( 
  @VendorLocationID INT = NULL
  ,@ServiceRequestID INT =NULL
) 
 AS 
 BEGIN   
    
      SET NOCOUNT ON  
  
     DECLARE @ProductID INT = NULL  
       
      SELECT @ProductID=PrimaryProductID   
      FROM ServiceRequest   
      WHERE ID=@ServiceRequestID  
       
      Select   
   v.ID  
            , v.Name as VendorName  
            , v.VendorNumber as VendorNumber  
            --, CASE   
            --WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NOT NULL THEN 'Contracted'  
            --WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NULL THEN 'Not Contracted'  
            --WHEN c.ID IS NOT NULL THEN 'Contracted'   
            --ELSE 'Not Contracted'  
            --END as ContractStatus  
   , CASE  
    WHEN ContractedVendors.ContractID IS NOT NULL   
     AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'  
    ELSE 'Not Contracted'   
     END AS ContractStatus  
            , ae.Line1 as Address1  
            , ae.Line2 as Address2  
            , REPLACE(RTRIM(  
            COALESCE(ae.City, '') +  
            COALESCE(', ' + ae.StateProvince,'') +   
            COALESCE(' ' + LTRIM(ae.PostalCode), '') +   
            COALESCE(' ' + ae.CountryCode, '')   
            ), ' ', ' ') as VendorCityStateZipCountry  
            , pe24.PhoneTypeID as DispatchPhoneType  
            , pe24.PhoneNumber as DispatchPhoneNumber  
            , peFax.PhoneTypeID as FaxPhoneType  
            , peFax.PhoneNumber as FaxPhoneNumber  
            , peOfc.PhoneTypeID as OfficePhoneType  
            , peOfc.PhoneNumber as OfficePhoneNumber  
            ,v.Email  
            ,v.CreateBy   
            ,v.CreateDate  
            ,v.ModifyBy  
            ,v.ModifyDate  
            ,vs.Name AS VendorStatus  
            ,COALESCE(TaxEIN,TaxSSN,'') VendorTaxID  
      From VendorLocation vl  
      Join Vendor v on v.ID = vl.VendorID  
      JOIN VendorStatus vs ON v.VendorStatusID = vs.ID  
      Left Outer Join AddressEntity ae on ae.RecordID = vl.ID and ae.EntityID = (Select ID From Entity Where Name = 'VendorLocation')   
      Left Outer Join PhoneEntity pe24 on pe24.RecordID = vl.ID and pe24.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and pe24.PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')  
      Left Outer Join PhoneEntity peFax on peFax.RecordID = vl.ID and peFax.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and peFax.PhoneTypeID = (Select ID From PhoneType Where Name = 'Fax')  
      Left Outer Join PhoneEntity peOfc on peOfc.RecordID = vl.ID and peOfc.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and peOfc.PhoneTypeID = (Select ID From PhoneType Where Name = 'Office')  
      Left Outer Join [Contract] c on c.VendorID = v.ID and c.IsActive = 1 and c.ContractStatusID = (Select ID From ContractStatus Where Name = 'Active')  
      --Left Outer Join (  
      --      SELECT DISTINCT vr.VendorID, vr.ProductID  
      --      FROM dbo.fnGetCurrentProductRatesByVendorLocation() vr   
      --      ) DefaultVendorRates ON v.ID = DefaultVendorRates.VendorID And @ProductID = DefaultVendorRates.ProductID  
      LEFT OUTER JOIN(  
   SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID  
   FROM dbo.fnGetContractedVendors() cv  
   ) ContractedVendors ON v.ID = ContractedVendors.VendorID   
      Where vl.ID = @VendorLocationID  
  
END  

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_CCImport_UpdateTempCreditCardDetails]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_CCImport_UpdateTempCreditCardDetails]
GO

--EXEC dms_CCImport_UpdateTempCreditCardDetails
CREATE PROC [dbo].[dms_CCImport_UpdateTempCreditCardDetails]
AS
BEGIN

BEGIN TRY
 

CREATE TABLE #TempCardsNotPosted (     
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
 ID int  NULL)

DECLARE @postedStatus INT
DECLARE @startROWParent INT 
DECLARE @totalRowsParent INT,
		@creditcardNumber INT,
		@totalApprovedAmount money,
		@totalChargedAmount money

SET @postedStatus = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name='Posted')

INSERT INTO #TempCardsNotPosted
SELECT DISTINCT TCCD.TemporaryCreditCardID FROM
TemporaryCreditCardDetail TCCD
JOIN TemporaryCreditCard TCC ON TCC.ID = TCCD.TemporaryCreditCardID
WHERE TCC.TemporaryCreditCardStatusID != @postedStatus

SET @startROWParent =  (SELECT MIN([RowNum]) FROM #TempCardsNotPosted)
SET @totalRowsParent = (SELECT MAX([RowNum]) FROM #TempCardsNotPosted)

WHILE(@startROWParent <= @totalRowsParent)  
BEGIN

SET @creditcardNumber = (SELECT ID FROM #TempCardsNotPosted WHERE [RowNum] = @startROWParent)

IF((SELECT Count(*) FROM TemporaryCreditCardDetail 
   WHERE TransactionType='Cancel' AND TemporaryCreditCardID = @creditcardNumber) > 0)
 BEGIN
	UPDATE TemporaryCreditCard 
	SET IssueStatus = 'Cancel'
	WHERE ID = @creditcardNumber
 END
 
 SET @totalApprovedAmount = (SELECT TOP 1 ApprovedAmount FROM TemporaryCreditCardDetail
							 WHERE TemporaryCreditCardID = @creditcardNumber AND TransactionType='Approve'
							 AND TransactionSequence IS NOT NULL
							 ORDER BY TransactionSequence DESC)
SET @totalChargedAmount = (SELECT SUM(ChargeAmount) FROM TemporaryCreditCardDetail
						   WHERE TemporaryCreditCardID = @creditcardNumber AND TransactionType='Charge')

UPDATE TemporaryCreditCard
SET ApprovedAmount = @totalApprovedAmount,
	TotalChargedAmount = @totalChargedAmount
WHERE ID = @creditcardNumber
						 
SET @startROWParent = @startROWParent + 1

END

DROP TABLE #TempCardsNotPosted



END TRY
BEGIN CATCH
		
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
	
END CATCH

END

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Call_Summary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Call_Summary]
GO

--EXEC dms_Call_Summary @serviceRequestID = 1429  
CREATE PROC dms_Call_Summary(@serviceRequestID INT = NULL)  
AS  
BEGIN 
	DECLARE @Hold TABLE(ColumnName NVARCHAR(MAX),ColumnValue NVARCHAR(MAX),DataType NVARCHAR(MAX),Sequence INT,GroupName NVARCHAR(MAX),DefaultRows INT NULL)    
	DECLARE @DocHandle int    
	DECLARE @XmlDocument NVARCHAR(MAX)   
	DECLARE @ProductID INT
	SET @ProductID = NULL
	SELECT  @ProductID = PrimaryProductID FROM ServiceRequest WHERE ID = @serviceRequestID

-- Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'

	SET FMTONLY OFF    
-- Sanghi : ISNull is required because generating XML will ommit the columns.     
-- Two Blank Space is required.  
	DECLARE @tmpServiceLocationVendor TABLE
	(
		Line1 NVARCHAR(100) NULL,
		Line2 NVARCHAR(100) NULL,
		Line3 NVARCHAR(100) NULL,
		City NVARCHAR(100) NULL,
		StateProvince NVARCHAR(100) NULL,
		CountryCode NVARCHAR(100) NULL,
		PostalCode NVARCHAR(100) NULL,
		
		TalkedTo NVARCHAR(50) NULL,
		PhoneNumber NVARCHAR(100) NULL,
		VendorName NVARCHAR(100) NULL
	)
	INSERT INTO @tmpServiceLocationVendor	
	SELECT	TOP 1	AE.Line1, 
					AE.Line2, 
					AE.Line3, 
					AE.City, 
					AE.StateProvince, 
					AE.CountryCode, 
					AE.PostalCode,
					cl.TalkedTo,
					cl.PhoneNumber,
					V.Name As VendorName
		FROM	ContactLogLink cll
		JOIN	ContactLog cl on cl.ID = cll.ContactLogID
		JOIN	ContactLogLink cll2 on cll2.contactlogid = cl.id and cll2.entityid = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest') and cll2.RecordID = @serviceRequestID
		JOIN	VendorLocation VL ON cll.RecordID = VL.ID
		JOIN	Vendor V ON VL.VendorID = V.ID 	
		JOIN	AddressEntity AE ON AE.RecordID = VL.ID AND AE.EntityID = (SELECT ID FROM Entity WHERE name = 'VendorLocation')
		WHERE	cll.entityid = (SELECT ID FROM Entity WHERE name = 'VendorLocation')
		AND		cl.ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ServiceLocationSelection')
		ORDER BY cll.id DESC
	

  
	SET @XmlDocument = (SELECT DISTINCT    

-- PROGRAM SECTION
--	1 AS Program_DefaultNumberOfRows   
	cl.Name + ' - ' + p.name as Program_ClientProgramName    

-- MEMBER SECTION
--	, 5 AS Member_DefaultNumberOfRows
-- KB : 6/7 : TFS # 1339 : Presenting Case.Contactfirstname and Case.ContactLastName as member name and the values from member as company_name when the values differ.	
	, COALESCE(c.ContactFirstName,'') + COALESCE(' ' + c.ContactLastName,'') AS Member_Name
	, CASE
		WHEN	c.ContactFirstName <> m.Firstname
		AND		c.ContactLastName <> m.LastName
		THEN
				REPLACE(RTRIM(    
				COALESCE(m.FirstName, '') +    
				COALESCE(m.MiddleName, '') +   
				COALESCE(m.Suffix, '') + 
				COALESCE(' ' + m.LastName, '') 
				), '  ', ' ')
		ELSE
				NULL
		END as Member_CompanyName
    , ISNULL(ms.MembershipNumber,' ') AS Member_MembershipNumber
    -- Ignore time while comparing dates here
    -- KB: Considering Effective and Expiration Dates to calculate member status
	, CASE 
		WHEN	ISNULL(m.EffectiveDate,@minDate) <= @now AND ISNULL(m.ExpirationDate,@minDate) >= @now
		THEN	'Active'
		ELSE	'Inactive'
		END	AS Member_Status       
    , ISNULL((SELECT NAME FROM PhoneType WHERE ID = c.ContactPhoneTypeID),' ') as Member_CallbackPhoneTypeID    
    , ISNULL(c.ContactPhoneNumber,'') as Member_CallbackPhoneNumber    
    , ISNULL((SELECT NAME FROM PhoneType WHERE ID = c.ContactAltPhoneTypeID),' ') as Member_AltCallbackPhoneTypeID   
    , ISNULL(c.ContactAltPhoneNumber,'') as Member_AltCallbackPhoneNumber    
    , CONVERT(nvarchar(10),m.MemberSinceDate,101) as Member_MemberSinceDate
    , CONVERT(nvarchar(10),m.EffectiveDate,101) AS Member_EffectiveDate
    , CONVERT(nvarchar(10),m.ExpirationDate,101) AS Member_ExpirationDate
    , ISNULL(ae.Line1,'') AS Member_AddressLine1
    , ISNULL(ae.Line2,'') AS Member_AddressLine2
    , ISNULL(REPLACE(RTRIM(    
		COALESCE(ae.City, '') +
		COALESCE(', ' + ae.StateProvince, '') +
		COALESCE(' ' + ae.PostalCode, '') +
		COALESCE(' ' + ae.CountryCode, '') 
		), '  ', ' ')
		, ' ' ) AS Member_AddressCityStateZip
-- VEHICLE SECTION
--	, 3 AS Vehicle_DefalutNumberOfRows
	, ISNULL(RTRIM (
		COALESCE(c.VehicleYear + ' ', '') +    
		COALESCE(CASE c.VehicleMake WHEN 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END+ ' ', '') +    
		COALESCE(CASE C.VehicleModel WHEN 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END, '')
		), ' ') as Vehicle_YearMakeModel    
	, ISNULL(c.VehicleVIN,' ') as Vehicle_VIN    
	, ISNULL(RTRIM (
		COALESCE(c.VehicleColor + '  ' , '') +
		COALESCE(c.VehicleLicenseState + '-','') + 
		COALESCE(c.VehicleLicenseNumber, '')
		), ' ' ) AS Vehicle_Color_LicenseStateNumber
    ,ISNULL(
			COALESCE((SELECT Name FROM VehicleType WHERE ID = c.VehicleTypeID) + '-','') +
			COALESCE((SELECT Name FROM VehicleCategory WHERE ID = c.VehicleCategoryID),'') 
		,'') AS Vehicle_Type_Category
    ,ISNULL(C.[VehicleDescription],'') AS Vehicle_Description
    ,CASE WHEN C.[VehicleLength] IS NULL THEN '' ELSE CONVERT(NVARCHAR(50),C.[VehicleLength]) END AS Vehicle_Length  
-- SERVICE SECTION   
--	, 2 AS Service_DefaultNumberOfRows  
	, ISNULL(
		COALESCE(pc.Name, '') + 
		COALESCE('/' + CASE WHEN sr.IsPossibleTow = 1 THEN 'Possible Tow' END, '')
		,' ') as Service_ProductCategoryTow    
	, '$' + CONVERT(NVARCHAR(50),ISNULL(sr.CoverageLimit,0)) as Service_CoverageLimit  

-- LOCATION SECTION     
--	, 2 AS Location_DefaultNumberOfRows
	, ISNULL(sr.ServiceLocationAddress,' ') as Location_Address    
	, ISNULL(sr.ServiceLocationDescription,' ') as Location_Description  

-- DESTINATION SECTION     
--	, 2 AS Destination_DefaultNumberOfRows
	, ISNULL(sr.DestinationAddress,' ') as Destination_Address    
	, ISNULL(sr.DestinationDescription,' ') as Destination_Description 	
	, (SELECT VendorName FROM @tmpServiceLocationVendor ) AS Destination_VendorName
	, (SELECT PhoneNumber FROM @tmpServiceLocationVendor ) AS Destination_PhoneNumber
	, (SELECT TalkedTo FROM @tmpServiceLocationVendor ) AS Destination_TalkedTo
	, (SELECT ISNULL(Line1,'') FROM @tmpServiceLocationVendor ) AS Destination_AddressLine1
    , (SELECT ISNULL(Line2,'') FROM @tmpServiceLocationVendor) AS Destination_AddressLine2
    , (SELECT ISNULL(REPLACE(RTRIM(    
		COALESCE(City, '') +
		COALESCE(', ' + StateProvince, '') +
		COALESCE(' ' + PostalCode, '') +
		COALESCE(' ' + CountryCode, '') 
		), '  ', ' ')
		, ' ' ) FROM  @tmpServiceLocationVendor) AS Destination_AddressCityStateZip    
		
-- ISP SECTION
--	, 3 AS ISP_DefaultNumberOfRows
	--,CASE 
	--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NOT NULL THEN 'Contracted'
	--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NULL THEN 'Not Contracted'
	--	WHEN vc.ID IS NOT NULL THEN 'Contracted' 
	--	ELSE 'Not Contracted'
	--	END as ISP_Contracted
	, CASE
		WHEN ContractedVendors.ContractID IS NOT NULL 
			AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'
		ELSE 'Not Contracted' 
		END AS ISP_Contracted
	, ISNULL(v.Name,' ') as ISP_VendorName    
	, ISNULL(v.VendorNumber, ' ') AS ISP_VendorNumber
	--, ISNULL(peISP.PhoneNumber,' ') as ISP_DispatchPhoneNumber 
	, (SELECT TOP 1 PhoneNumber
		FROM PhoneEntity 
		WHERE RecordID = vl.ID
		AND EntityID = (Select ID From Entity Where Name = 'VendorLocation')
		AND PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')
		ORDER BY ID DESC
		) AS ISP_DispatchPhoneNumber
	, ISNULL(aeISP.Line1,'') AS ISP_AddressLine1
    , ISNULL(aeISP.Line2,'') AS ISP_AddressLine2
    , ISNULL(REPLACE(RTRIM(    
		COALESCE(aeISP.City, '') +
		COALESCE(', ' + aeISP.StateProvince, '') +
		COALESCE(' ' + aeISP.PostalCode, '') +
		COALESCE(' ' + aeISP.CountryCode, '') 
		), '  ', ' ')
		, ' ' ) AS ISP_AddressCityStateZip
	, COALESCE(ISNULL(po.PurchaseOrderNumber + '-', ' '),'') + ISNULL(pos.Name, ' ' ) AS ISP_PONumberStatus
--	, ISNULL(pos.Name, ' ' ) AS ISP_POStatus
	, COALESCE( '$' + CONVERT(NVARCHAR(10),po.PurchaseOrderAmount),'') 
		+ ' ' 
		+ ISNULL(CASE WHEN po.ID IS NOT NULL THEN PC.Name ELSE NULL END,'') AS ISP_POAmount_ProductCategory
	--, ISNULL(po.PurchaseOrderAmount, ' ' ) AS ISP_POAmount
	, 'Issued:' +
		REPLACE(CONVERT(VARCHAR(8), po.IssueDate, 10), '-', '/') + ' - ' +  
		SUBSTRING(CONVERT(VARCHAR(20), po.IssueDate, 9), 13, 8) + ' ' +  
		SUBSTRING(CONVERT(VARCHAR(30), po.IssueDate, 9), 25, 2) AS ISP_IssuedDate  
	, 'ETA:' +
		REPLACE(CONVERT(VARCHAR(8), po.ETADate, 10), '-', '/') + ' - ' +  
		SUBSTRING(CONVERT(VARCHAR(20), po.ETADate, 9), 13, 8) + ' ' +  
		SUBSTRING(CONVERT(VARCHAR(30), po.ETADate, 9), 25, 2) AS ISP_ETADate  

-- SERVICE REQUEST SECTION 
--	, 2 AS SR_DefaultNumberOfRows
	--Sanghi 03 - July - 2013 Updated Below Line.
	, CAST(CAST(ISNULL(sr.ID, ' ') AS NVARCHAR(MAX)) + ' - ' + ISNULL(srs.Name, ' ') AS NVARCHAR(MAX))  AS SR_Info 
	--, ISNULL(sr.ID,' ') as SR_ServiceRequestID      
	--,(ISNULL(srs.Name,'')) + CASE WHEN na.Name IS NULL THEN '' ELSE ' - ' + (ISNULL(na.Name,'')) END AS SR_ServiceRequestStatus
	--, ISNULL('Closed Loop: ' + cls.Name, ' ') as SR_ClosedLoopStatus
	, ISNULL(sr.CreateBy,' ') + ' ' + 
		    REPLACE(CONVERT(VARCHAR(8), sr.CreateDate, 10), '-', '/') + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(20), sr.CreateDate, 9), 13, 8) + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(30), sr.CreateDate, 9), 25, 2
			) AS SR_CreateInfo
	--, ISNULL(sr.CreateBy,' ')as SR_CreatedBy   
	--, REPLACE(CONVERT(VARCHAR(8), sr.CreateDate, 10), '-', '/') + ' - ' +  
	--	SUBSTRING(CONVERT(VARCHAR(20), sr.CreateDate, 9), 13, 8) + ' ' +  
	--	SUBSTRING(CONVERT(VARCHAR(30), sr.CreateDate, 9), 25, 2) AS SR_CreateDate
	--, ISNULL(NextAction.Name, ' ') + ISNULL(u.FirstName, ' ') + ' ' + ISNULL(u.LastName,' ') AS SR_NextActionInfo  
	, ISNULL(NextAction.Name + ' - ', ' ') + ISNULL(u.FirstName, ' ') + ' ' + ISNULL(u.LastName,' ') AS SR_NextActionName_AssignedTo
	, ISNULL( 	
			REPLACE(
			CONVERT(VARCHAR(8), sr.NextActionScheduledDate, 10), '-', '/') + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(20), sr.NextActionScheduledDate, 9), 13, 8) + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(30), sr.NextActionScheduledDate, 9), 25, 2
			) 
			, ' ') AS SR_NextActionScheduledDate
	--, ISNULL('AssignedTo: ' + u.FirstName, ' ') + ' ' + ISNULL(u.LastName,' ') AS SR_NextActionAssignedTo  

	FROM		ServiceRequest sr      
	JOIN		[Case] c on c.ID = sr.CaseID    
	LEFT JOIN	PhoneType ptContact on ptContact.ID = c.ContactPhoneTypeID    
	JOIN		Program p on p.ID = c.ProgramID    
	JOIN		Client cl on cl.ID = p.ClientID    
	JOIN		Member m on m.ID = c.MemberID    
	JOIN		Membership ms on ms.ID = m.MembershipID    
	LEFT JOIN	AddressEntity ae ON ae.EntityID = (select ID from Entity where Name = 'Membership')    
	AND			ae.RecordID = ms.ID    
	AND			ae.AddressTypeID = (select ID from AddressType where Name = 'Home')    
	LEFT JOIN	Country country on country.ID = ae.CountryID     
	LEFT JOIN	PhoneEntity peMbr ON peMbr.EntityID = (select ID from Entity where Name = 'Membership')     
	AND			peMbr.RecordID = ms.ID    
	AND			peMbr.PhoneTypeID = (select ID from PhoneType where Name = 'Home')    
	LEFT JOIN	PhoneType ptMbr on ptMbr.ID = peMbr.PhoneTypeID    
	LEFT JOIN	ProductCategory pc on pc.ID = sr.ProductCategoryID    
	LEFT JOIN	(  
				SELECT TOP 1 *  
				FROM PurchaseOrder wPO   
				WHERE wPO.ServiceRequestID = @serviceRequestID  
				AND wPO.IsActive = 1
				AND wPO.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending')
				ORDER BY wPO.IssueDate DESC  
				) po on po.ServiceRequestID = sr.ID  
	LEFT JOIN	PurchaseOrderStatus pos on pos.ID = po.PurchaseOrderStatusID  
	LEFT JOIN	VendorLocation vl on vl.ID = po.VendorLocationID    
	LEFT JOIN	Vendor v on v.ID = vl.VendorID 
	LEFT JOIN	[Contract] vc on vc.VendorID = v.ID and vc.IsActive = 1 and vc.ContractStatusID = (Select ID From ContractStatus Where Name = 'Active')
	LEFT OUTER JOIN (
				SELECT DISTINCT vr.VendorID, vr.ProductID
				FROM dbo.fnGetCurrentProductRatesByVendorLocation() vr 
				) DefaultVendorRates ON v.ID = DefaultVendorRates.VendorID And @ProductID = DefaultVendorRates.ProductID
	LEFT OUTER JOIN (
				SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID
				FROM dbo.fnGetContractedVendors() cv
				) ContractedVendors ON v.ID = ContractedVendors.VendorID
	--LEFT JOIN	PhoneEntity peISP on peISP.EntityID = (select ID from Entity where Name = 'VendorLocation')     
	--AND			peISP.RecordID = vl.ID    
	--AND			peISP.PhoneTypeID = (select ID from PhoneType where Name = 'Dispatch')  
	--LEFT JOIN	PhoneType ptISP on ptISP.ID = peISP.PhoneTypeID    
	--LEFT JOIN (
	--			SELECT TOP 1 ph.RecordID, ph.PhoneNumber
	--			FROM PhoneEntity ph 
	--			WHERE EntityID = (Select ID From Entity Where Name = 'VendorLocation')
	--			AND PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')
	--			ORDER BY ID 
	--		   )  peISP ON peISP.RecordID = vl.ID
	LEFT JOIN	AddressEntity aeISP ON aeISP.EntityID = (select ID from Entity where Name = 'VendorLocation')    
	AND			aeISP.RecordID = vl.ID    
	AND			aeISP.AddressTypeID = (select ID from AddressType where Name = 'Business')    
 -- CR # 524  
	LEFT JOIN	ServiceRequestStatus srs ON srs.ID=sr.ServiceRequestStatusID  
	LEFT JOIN	NextAction na ON na.ID=sr.NextActionID  
	LEFT JOIN	ClosedLoopStatus cls ON cls.ID=sr.ClosedLoopStatusID 
 -- End : CR # 524  
 	LEFT JOIN	VendorLocation VLD ON VLD.ID = sr.DestinationVendorLocationID
	LEFT JOIN	PhoneEntity peDestination ON peDestination.RecordID = VLD.ID AND peDestination.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')  
	LEFT JOIN	NextAction NextAction on NextAction.ID = sr.NextActionID
	LEFT JOIN	[User] u on u.ID = sr.NextActionAssignedToUserID

	WHERE		sr.ID = @ServiceRequestID    
	FOR XML PATH)    
    

EXEC sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument    
SELECT * INTO #Temp FROM OPENXML (@DocHandle, '/row',2)       
INSERT INTO @Hold    
SELECT T1.localName ,T2.text,'String',ROW_NUMBER() OVER(ORDER BY T1.ID),'',NULL FROM #Temp T1     
INNER JOIN #Temp T2 ON T1.id = T2.parentid    
WHERE T1.id > 0    
    
    
DROP TABLE #Temp    
    -- Group Values Based on Sequence Number    
 UPDATE @Hold SET GroupName = 'Member', DefaultRows = 5 WHERE CHARINDEX('Member_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Vehicle', DefaultRows = 3 WHERE CHARINDEX('Vehicle_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Service' ,DefaultRows = 2 WHERE CHARINDEX('Service_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Location', DefaultRows = 2 WHERE CHARINDEX('Location_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Destination', DefaultRows = 2 WHERE CHARINDEX('Destination_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'ISP', DefaultRows = 10 WHERE CHARINDEX('ISP_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Program', DefaultRows = 1 WHERE CHARINDEX('Program_',ColumnName) > 0   
 UPDATE  @Hold SET GroupName = 'Service Request', DefaultRows = 2 WHERE CHARINDEX('SR_',ColumnName) > 0   
     
 --CR # 524   
      
-- UPDATE @Hold SET GroupName ='Service Request' where ColumnName in ('ServiceRequestID','ServiceRequestStatus','NextAction',  
--'ClosedLoopStatus',  
--'CreateDate','CreatedBy','SR_NextAction','SR_NextActionAssignedTo')  
 -- End : CR # 524  
   
 UPDATE @Hold SET DataType = 'Phone' WHERE CHARINDEX('PhoneNumber',ColumnName) > 0    
 UPDATE @Hold SET DataType = 'LabelTheme' WHERE CHARINDEX('Member_Status',ColumnName) > 0    

 DELETE FROM @Hold WHERE ColumnValue IS NULL

 DECLARE @DefaultRows INT
 SET  @DefaultRows = (SELECT Sequence FROM @Hold WHERE ColumnName = 'Member_AltCallbackPhoneNumber')
 IF @DefaultRows IS NOT NULL
 BEGIN
 SET @DefaultRows = (SELECT COUNT(*) FROM @Hold WHERE ColumnName LIKE 'Member_%' AND Sequence <= @DefaultRows)
 -- Re Setting values 
 UPDATE @Hold SET DefaultRows = @DefaultRows WHERE GroupName = 'Member' 
 END
 -- Update Label fields
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Member Since: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Member_MemberSinceDate')
 WHERE ColumnName = 'Member_MemberSinceDate'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Effective: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Member_EffectiveDate')
 WHERE ColumnName = 'Member_EffectiveDate'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Expiration: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Member_ExpirationDate')
 WHERE ColumnName = 'Member_ExpirationDate'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'PO: ' + ColumnValue FROM @Hold WHERE ColumnName = 'ISP_PONumberStatus')
 WHERE ColumnName = 'ISP_PONumberStatus'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Length: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Vehicle_Length')
 WHERE ColumnName = 'Vehicle_Length'
 
 
 SELECT * FROM @Hold WHERE ColumnValue IS NOT NULL ORDER BY Sequence ASC 
 
	
END

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnGetContractedVendors]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnGetContractedVendors]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO 
-- Select * From [dbo].[fnGetContractedVendors]() Where VendorID = 4360   
CREATE FUNCTION [dbo].[fnGetContractedVendors] ()  
RETURNS TABLE   
AS  
RETURN   
(  
 -- Contract must me active and within date range  
 -- Related Contract Rate Schedule must be active and within date range  
 SELECT   
  v.ID VendorID, v.VendorNumber, MAX(c.ID) ContractID, MAX(crs.ID) ContractRateScheduleID  
 FROM dbo.Vendor v  
 JOIN dbo.[Contract] c On c.VendorID = v.ID   
 JOIN dbo.[ContractRateSchedule] crs ON   
  crs.ContractID = c.ID AND   
  crs.ContractRateScheduleStatusID = (SELECT ID FROM ContractRateScheduleStatus WHERE Name = 'Active') AND  
  crs.StartDate <= GETDATE() AND  
  (crs.EndDate IS NULL OR crs.EndDate >= GETDATE())  
 JOIN dbo.[ContractRateScheduleProduct] crsp On crsp.ContractRateScheduleID = crs.ID   
 WHERE   
 v.IsActive = 1 --Vendor Not Deleted  
 AND v.VendorStatusID = (SELECT ID FROM VendorStatus WHERE Name = 'Active')  
 AND c.IsActive = 1 --Contract Not Deleted  
 AND c.ContractStatusID = (SELECT ID FROM ContractStatus WHERE Name = 'Active')  
 AND c.StartDate <= GETDATE()   
 AND (c.EndDate IS NULL OR c.EndDate >= GETDATE())  
 GROUP BY v.ID, v.VendorNumber  
)  

GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ISPSelection_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ISPSelection_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO   
-- EXEC [dbo].[dms_ISPSelection_get]  848,null,1,1,200,0.2,0.4,0.4,0,'Location',true,true
-- EXEC [dbo].[dms_ISPSelection_get]  44022,5,1,1,50,0.4,0.1,0.5,0,'Location'
/* Debug */
--DECLARE 
--    @ServiceRequestID int  = 44022 
--    ,@ActualServiceMiles decimal(10,2)  = 5 
--    ,@VehicleTypeID int  = 1 
--    ,@VehicleCategoryID int  = 1 
--    ,@SearchRadiusMiles int  = 50 
--    ,@AdminWeight decimal(5,2)  = .1 
--    ,@PerformWeight decimal(5,2) = .2  
--    ,@CostWeight decimal(5,2)  = .7 
--    ,@IncludeDoNotUse bit  = 0 
--    ,@SearchFrom nvarchar(50) = 'Location'
--    ,@productIDs NVARCHAR(MAX) = NULL 
      
CREATE PROCEDURE [dbo].[dms_ISPSelection_get]  
      @ServiceRequestID int  = NULL 
      ,@ActualServiceMiles decimal(10,2)  = NULL 
      ,@VehicleTypeID int  = NULL 
      ,@VehicleCategoryID int  = NULL 
      ,@SearchRadiusMiles int  = NULL 
      ,@AdminWeight decimal(5,2)  = NULL 
      ,@PerformWeight decimal(5,2) = NULL  
      ,@CostWeight decimal(5,2)  = NULL 
      ,@IncludeDoNotUse bit  = NULL 
      ,@SearchFrom nvarchar(50) = NULL
      ,@productIDs NVARCHAR(MAX) = NULL -- comma separated list of product IDs.
AS  
BEGIN    
  
/* Variable Declarations */  
DECLARE       
      @ServiceLocationLatitude decimal(10,7)   
    ,@ServiceLocationLongitude decimal(10,7)    
    ,@ServiceLocationStateProvince nvarchar(2)  
    ,@ServiceLocationCountryCode nvarchar(10)   
    ,@DestinationLocationLatitude decimal(10,7)    
    ,@DestinationLocationLongitude decimal(10,7)  
    ,@PrimaryProductID int   
    ,@SecondaryProductID int  
    ,@ProductCategoryID int  
    ,@SecondaryProductCategoryID int  
    ,@MembershipID int  
    ,@ProgramID INT  
    ,@pcAdminWeight decimal(5,2)  = NULL   
      ,@pcPerformWeight decimal(5,2) = NULL    
      ,@pcCostWeight decimal(5,2)  = NULL   
      ,@IsTireDelivery bit  
      ,@LogISPSelection bit  
      ,@LogISPSelectionFinal bit  
  
/* Set Logging On/Off */  
SET @LogISPSelection = 0  
SET @LogISPSelectionFinal = 1  
  
/* Hard-coded radius for Do-Not-Use vendor selection - Should be added to ApplicationConfiguration */  
DECLARE @DNUSearchRadiusMiles int    
SET @DNUSearchRadiusMiles = 50    
  
/* Get Current Time for log inserts */  
DECLARE @now DATETIME = GETDATE()  
  
  
/* Work table declarations *******************************************************/  
SET FMTONLY OFF  
DECLARE @ISPSelection TABLE (  
[VendorID] [int] NOT NULL,  
[VendorLocationID] [int] NOT NULL,  
[VendorLocationVirtualID] [int] NULL,  
[Latitude] [decimal](10, 7) NULL,  
[Longitude] [decimal](10, 7) NULL,  
[VendorName] [nvarchar](255) NULL,  
[VendorNumber] [nvarchar](50) NULL,  
[Source] [varchar](8) NOT NULL,  
[ContractStatus] [nvarchar](50) NOT NULL,  
[Address1] [nvarchar](100) NULL,  
[Address2] [nvarchar](100) NULL,  
[City] [nvarchar](100) NULL,  
[StateProvince] [nvarchar](10) NULL,  
[PostalCode] [nvarchar](20) NULL,  
[CountryCode] [nvarchar](2) NULL,  
[DispatchPhoneNumber] [nvarchar](50) NULL,  
[FaxPhoneNumber] [nvarchar](50) NULL,   
[OfficePhoneNumber] [nvarchar](50) NULL,  
[CellPhoneNumber] [nvarchar](50) NULL, -- CR : 1226  
[AdministrativeRating] [int] NULL,  
[InsuranceStatus] [varchar](11) NOT NULL,  
[BusinessHours] [nvarchar](100) NOT NULL,  
[PaymentTypes] [nvarchar] (100) NULL,    
[Comment] [nvarchar](2000) NULL,  
[ProductID] [int] NOT NULL,  
[ProductName] [nvarchar](50) NULL,  
[ProductRating] [decimal](5, 2) NULL,  
[EnrouteMiles] [float] NULL,  
[EnrouteTimeMinutes] [int] NULL,  
[ServiceMiles] [decimal](10, 2) NULL,  
[ServiceTimeMinutes] [int] NULL,  
[ReturnMiles] [float] NULL,  
[ReturnTimeMinutes] [int] NULL,  
[EstimatedHours] [float] NULL,  
[BaseRate] [money] NULL,  
[HourlyRate] [money] NULL,  
[EnrouteRate] [money] NULL,  
[EnrouteFreeMiles] [int] NULL,  
[ServiceRate] [money] NULL,  
[ServiceFreeMiles] [int] NULL,  
[EstimatedPrice] [float] NULL,  
[WiseScore] [float] NULL,  
[CallStatus] [varchar](9) NOT NULL,  
[RejectReason] [nvarchar](255) NULL,  
[RejectComment] [nvarchar](max) NULL,  
[IsPossibleCallback] [bit] NOT NULL  
)   
  
DECLARE @ISPSelectionFinalResults TABLE (  
[VendorID] [int] NOT NULL,  
[VendorLocationID] [int] NOT NULL,  
[VendorLocationVirtualID] [int] NULL,  
[Latitude] [decimal](10, 7) NULL,  
[Longitude] [decimal](10, 7) NULL,  
[VendorName] [nvarchar](255) NULL,  
[VendorNumber] [nvarchar](50) NULL,  
[Source] [varchar](8) NOT NULL,  
[ContractStatus] [nvarchar](50) NOT NULL,  
[Address1] [nvarchar](100) NULL,  
[Address2] [nvarchar](100) NULL,  
[City] [nvarchar](100) NULL,  
[StateProvince] [nvarchar](10) NULL,  
[PostalCode] [nvarchar](20) NULL,  
[CountryCode] [nvarchar](2) NULL,  
[DispatchPhoneNumber] [nvarchar](50) NULL,  
[FaxPhoneNumber] [nvarchar](50) NULL,   
[OfficePhoneNumber] [nvarchar](50) NULL,  
[CellPhoneNumber] [nvarchar](50) NULL, -- CR : 1226  
[AdministrativeRating] [int] NULL,  
[InsuranceStatus] [varchar](11) NOT NULL,  
[BusinessHours] [nvarchar](100) NOT NULL,  
[PaymentTypes] [nvarchar] (100) NULL,    
[Comment] [nvarchar](2000) NULL,  
[ProductID] [int] NOT NULL,  
[ProductName] [nvarchar](50) NULL,  
[ProductRating] [decimal](5, 2) NULL,  
[EnrouteMiles] [float] NULL,  
[EnrouteTimeMinutes] [int] NULL,  
[ServiceMiles] [decimal](10, 2) NULL,  
[ServiceTimeMinutes] [int] NULL,  
[ReturnMiles] [float] NULL,  
[ReturnTimeMinutes] [int] NULL,  
[EstimatedHours] [float] NULL,  
[BaseRate] [money] NULL,  
[HourlyRate] [money] NULL,  
[EnrouteRate] [money] NULL,  
[EnrouteFreeMiles] [int] NULL,  
[ServiceRate] [money] NULL,  
[ServiceFreeMiles] [int] NULL,  
[EstimatedPrice] [float] NULL,  
[WiseScore] [float] NULL,  
[CallStatus] [varchar](9) NOT NULL,  
[RejectReason] [nvarchar](255) NULL,  
[RejectComment] [nvarchar](max) NULL,  
[IsPossibleCallback] [bit] NOT NULL,  
[AllServices] [NVARCHAR](MAX) NULL,  
[ProductSearchRadiusMiles] [int] NULL,  
[IsInProductSearchRadius] [bit] NULL  
)  
  
CREATE TABLE #ISPDoNotUse (  
[VendorID] [int] NOT NULL,  
[VendorLocationID] [int] NOT NULL,  
[VendorLocationVirtualID] [int] NULL,  
[Latitude] [decimal](10, 7) NULL,  
[Longitude] [decimal](10, 7) NULL,  
[VendorName] [nvarchar](255) NULL,  
[VendorNumber] [nvarchar](50) NULL,  
[Source] [varchar](8) NOT NULL,  
[ContractStatus] [nvarchar](50) NULL,  
[Address1] [nvarchar](100) NULL,  
[Address2] [nvarchar](100) NULL,  
[City] [nvarchar](100) NULL,  
[StateProvince] [nvarchar](10) NULL,  
[PostalCode] [nvarchar](20) NULL,  
[CountryCode] [nvarchar](2) NULL,  
[DispatchPhoneNumber] [nvarchar](50) NULL,  
[FaxPhoneNumber] [nvarchar](50) NULL,   
[OfficePhoneNumber] [nvarchar](50) NULL,  
[CellPhoneNumber] [nvarchar](50) NULL, -- CR: 1226  
[AdministrativeRating] [int] NULL,  
[InsuranceStatus] [varchar](11) NULL,  
[BusinessHours] [nvarchar](100) NULL,  
[PaymentTypes] [nvarchar] (100) NULL,    
[Comment] [nvarchar](2000) NULL,  
[ProductID] [int] NULL,  
[ProductName] [nvarchar](50) NULL,  
[ProductRating] [decimal](5, 2) NULL,  
[EnrouteMiles] [float] NULL,  
[EnrouteTimeMinutes] [int] NULL,  
[ServiceMiles] [decimal](10, 2) NULL,  
[ServiceTimeMinutes] [int] NULL,  
[ReturnMiles] [float] NULL,  
[ReturnTimeMinutes] [int] NULL,  
[EstimatedHours] [float] NULL,  
[BaseRate] [money] NULL,  
[HourlyRate] [money] NULL,  
[EnrouteRate] [money] NULL,  
[EnrouteFreeMiles] [int] NULL,  
[ServiceRate] [money] NULL,  
[ServiceFreeMiles] [int] NULL,  
[EstimatedPrice] [float] NULL,  
[WiseScore] [float] NULL,  
[CallStatus] [varchar](9) NULL,  
[RejectReason] [nvarchar](255) NULL,  
[RejectComment] [nvarchar](max) NULL,  
[IsPossibleCallback] [bit] NULL  
)   
  
CREATE TABLE #IspDetail (  
[VendorID] [int] NOT NULL,  
[VendorLocationID] [int] NOT NULL,  
[VendorLocationVirtualID] [int] NULL,  
[Latitude] [decimal](10, 7) NULL,  
[Longitude] [decimal](10, 7) NULL,  
[VendorName] [nvarchar](255) NULL,  
[VendorNumber] [nvarchar](50) NULL,  
[Source] [varchar](8) NOT NULL,  
[ContractStatus] [nvarchar](50) NULL,  
[DispatchPhoneNumber] [nvarchar](50) NULL,  
[AdministrativeRating] [int] NULL,  
[InsuranceStatus] [varchar](11) NOT NULL,  
[IsOpen24Hours] [bit] NULL,  
[BusinessHours] [nvarchar](100) NULL,  
--[PaymentTypes] [nvarchar] (100) NULL,    
[Comment] [nvarchar](2000) NULL,  
[EnrouteMiles] [float] NULL,  
[ServiceMiles] [decimal](10, 2) NULL,  
[ReturnMiles] [float] NULL,  
[ProductID] [int] NOT NULL,  
[ProductName] [nvarchar](50) NULL,  
[ProductRating] [decimal](5, 2) NULL,  
[RateTypeID] [int] NULL,  
[RatePrice] [money] NULL,  
[RateQuantity] [int] NULL,  
[RateTypeName] [nvarchar](50) NULL,  
[RateUnitOfMeasure] [nvarchar](50) NULL,  
[RateUnitOfMeasureSource] [nvarchar](50) NULL,  
[IsProductMatch] [int] NOT NULL  
)   
  
-- Get service information from ServiceRequest  
SELECT         
      @ServiceLocationLatitude = SR.ServiceLocationLatitude,  
    @ServiceLocationLongitude = SR.ServiceLocationLongitude,  
    @ServiceLocationStateProvince = SR.ServiceLocationStateProvince,  
    @ServiceLocationCountryCode = SR.ServiceLocationCountryCode,  
    @DestinationLocationLatitude = SR.DestinationLatitude,  
    @DestinationLocationLongitude = SR.DestinationLongitude,  
    @PrimaryProductID = SR.PrimaryProductID,  
    @SecondaryProductID = SR.SecondaryProductID,  
    @ProductCategoryID = SR.ProductCategoryID,  
   @MembershipID = m.MembershipID,  
    @ProgramID = c.ProgramID  
FROM  ServiceRequest SR  
JOIN [Case] c ON SR.CaseID = c.ID  
JOIN Member m ON c.MemberID = m.ID  
WHERE SR.ID = @ServiceRequestID  
  
SET @SecondaryProductCategoryID = (SELECT ProductCategoryID FROM Product WHERE ID = @SecondaryProductID)  
  
-- Additional condition needed to include tire stores if tire service and tire delivery selected  
SET @IsTireDelivery = ISNULL((SELECT 1 FROM ServiceRequestDetail WHERE @ProductCategoryID = 2 AND ServiceRequestID = @ServiceRequestID AND ProductCategoryQuestionID = 203 AND Answer = 'Tire Delivery'),0)  
  
-- Set program specific ISP scoring weights */  
DECLARE @ProgramConfig TABLE (  
      Name NVARCHAR(50) NULL,  
      Value NVARCHAR(255) NULL  
)  
  
;WITH wProgramConfig   
AS  
(     SELECT ROW_NUMBER() OVER ( PARTITION BY PC.Name ORDER BY PP.Sequence) AS RowNum,  
                  PP.Sequence,  
                  PC.Name,      
                  PC.Value      
      FROM fnc_GetProgramsandParents(@ProgramID) PP  
      JOIN ProgramConfiguration PC ON PP.ProgramID = PC.ProgramID AND PC.IsActive = 1  
      WHERE PC.ConfigurationTypeID = 5   
      AND         PC.ConfigurationCategoryID = 3  
)  
  
INSERT INTO @ProgramConfig  
SELECT      W.Name,  
            W.Value  
FROM  wProgramConfig W  
WHERE W.RowNum = 1  
  
SET @pcAdminWeight = NULL  
SET @pcPerformWeight = NULL  
SET @pcCostWeight = NULL  
SELECT @pcAdminWeight = CONVERT(DECIMAL(5,2),Value) FROM @ProgramConfig WHERE Name = 'DefaultAdminWeighting'  
SELECT @pcPerformWeight = CONVERT(DECIMAL(5,2),Value) FROM @ProgramConfig WHERE Name = 'DefaultPerformanceWeighting'  
SELECT @pcCostWeight = CONVERT(DECIMAL(5,2),Value) FROM @ProgramConfig WHERE Name = 'DefaultCostWeighting'  
  
-- DEBUG : SELECT @pcAdminWeight AS AdminWeight, @pcCostWeight AS CostWeight, @pcPerformWeight AS PerfWeight  
-- If one the values is not defined, then use the values from ApplicationConfiguration.  
-- In other words, if all the three values are found, then override the ones from the app config.  
IF @pcAdminWeight IS NOT NULL AND @pcCostWeight IS NOT NULL AND @pcPerformWeight IS NOT NULL  
BEGIN  
      PRINT 'Using the values from ProgramConfig'  
        
      SET @AdminWeight = @pcAdminWeight  
      SET @CostWeight = @pcCostWeight  
      SET @PerformWeight = @pcPerformWeight  
END  
    
/* Get geography values for service location and towing destination */    
DECLARE @ServiceLocation as geography    
      ,@DestinationLocation as geography    
IF (@ServiceLocationLatitude IS NOT NULL AND @ServiceLocationLongitude IS NOT NULL)  
BEGIN  
    SET @ServiceLocation = geography::Point(@ServiceLocationLatitude, @ServiceLocationLongitude, 4326)    
END  
IF (@DestinationLocationLatitude IS NOT NULL AND @DestinationLocationLongitude IS NOT NULL)  
BEGIN  
    SET @DestinationLocation = geography::Point(@DestinationLocationLatitude, @DestinationLocationLongitude, 4326)    
END  
    
/* Set Service Miles based on service and destination locations - same for all vendors */    
DECLARE @ServiceMiles decimal(10,2)    
IF @ActualServiceMiles IS NOT NULL    
SET @ServiceMiles = @ActualServiceMiles    
ELSE    
SET @ServiceMiles = ROUND(@DestinationLocation.STDistance(@ServiceLocation)/1609.344,0)    
  
/* Get Market product rates according to market location */  
CREATE TABLE #MarketRates (  
[ProductID] [int] NULL,  
[RateTypeID] [int] NULL,  
[Name] [nvarchar](50) NULL,  
[Price] [money] NULL,  
[Quantity] [int] NULL  
)  
  
INSERT INTO #MarketRates  
SELECT ProductID, RateTypeID, Name, RatePrice, RateQuantity  
FROM dbo.fnGetDefaultProductRatesByMarketLocation(@ServiceLocation, @ServiceLocationCountryCode, @ServiceLocationStateProvince)  
  
CREATE CLUSTERED INDEX IDX_MarketRates ON #MarketRates(ProductID, RateTypeID)  
  
/* Get ISP Search Radius increment (bands) based on service and location (metro or rural) */  
DECLARE @IsMetroLocation bit  
DECLARE @ProductSearchRadiusMiles int  
  
/* Determine if service location is within a Metro Market Location radius */  
SET @IsMetroLocation = ISNULL(  
      (SELECT TOP 1 1   
      FROM MarketLocation ml  
      WHERE ml.MarketLocationTypeID = (SELECT ID FROM MarketLocationType WHERE Name = 'Metro')  
      And ml.IsActive = 'TRUE'  
      and ml.GeographyLocation.STDistance(@ServiceLocation) <= ml.RadiusMiles * 1609.344)  
      ,0)  
  
SELECT @ProductSearchRadiusMiles = CASE WHEN @IsMetroLocation = 1 THEN MetroRadius ELSE RuralRadius END   
FROM ProductISPSelectionRadius r  
WHERE ProductID = @PrimaryProductID   
  
IF @ProductSearchRadiusMiles IS NULL   
      SET @ProductSearchRadiusMiles = @SearchRadiusMiles  
  
  
/* Get reference type IDs */    
DECLARE     
            @VendorEntityID int    
            ,@VendorLocationEntityID int    
            ,@ServiceRequestEntityID int    
            ,@BusinessAddressTypeID int    
            ,@DispatchPhoneTypeID int    
            ,@FaxPhoneTypeID int  
            ,@OfficePhoneTypeID int    
            ,@CellPhoneTypeID int -- CR : 1226  
            ,@PrimaryServiceProductSubTypeID int    
            ,@ActiveVendorStatusID int  
            ,@DoNotUseVendorStatusID int  
            ,@ActiveVendorLocationStatusID int  
SET @VendorEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'Vendor')    
SET @VendorLocationEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'VendorLocation')    
SET @ServiceRequestEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'ServiceRequest')    
SET @BusinessAddressTypeID = (SELECT ID FROM dbo.AddressType WHERE Name = 'Business')    
SET @DispatchPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Dispatch')    
SET @FaxPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Fax')    
SET @OfficePhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Office')    
SET @CellPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Cell')  -- CR: 1226  
SET @PrimaryServiceProductSubTypeID = (Select ID From dbo.ProductSubType Where Name = 'PrimaryService')    
SET @ActiveVendorStatusID = (SELECT ID FROM dbo.VendorStatus WHERE Name = 'Active')    
SET @DoNotUseVendorStatusID = (SELECT ID FROM dbo.VendorStatus WHERE Name = 'DoNotUse')    
SET @ActiveVendorLocationStatusID = (SELECT ID FROM dbo.VendorLocationStatus WHERE Name = 'Active')    
  
    
/* Get list of ALL vendors within the Search Radius of the service location */  
SELECT V.ID VendorID  
      ,vl.ID VendorLocationID  
      ,NULL AS VendorLocationVirtualID  
      ,vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) Distance  
      ,vl.GeographyLocation  
      ,vl.Latitude  
      ,vl.Longitude  
INTO #tmpVendorLocation  
FROM VendorLocation vl  
JOIN Vendor V ON vl.VendorID = V.ID  
WHERE V.IsActive = 1 AND V.VendorStatusID = @ActiveVendorStatusID  
AND vl.IsActive = 1 AND vl.VendorLocationStatusID = @ActiveVendorLocationStatusID  
AND vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) <= @SearchRadiusMiles * 1609.344    
  
-- Include search of related Vendor Location virtual mapping points   
INSERT INTO #tmpVendorLocation  
SELECT V.ID VendorID  
      ,vl.ID VendorLocationID  
      ,vlv.ID VendorLocationVirtualID  
      ,vlv.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) Distance  
      ,vlv.GeographyLocation  
      ,vlv.Latitude  
      ,vlv.Longitude  
FROM VendorLocation vl  
JOIN Vendor V ON vl.VendorID = V.ID  
JOIN VendorLocationVirtual vlv on vlv.VendorLocationID = vl.ID --AND vlv.IsActive = 1  
WHERE V.IsActive = 1 AND V.VendorStatusID = @ActiveVendorStatusID  
AND vl.IsActive = 1 AND vl.VendorLocationStatusID = @ActiveVendorLocationStatusID  
AND vlv.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) <= @SearchRadiusMiles * 1609.344    
  
/* Index physical locations */  
CREATE NONCLUSTERED INDEX [IDX_tmpVendors_VendorLocationID] ON #tmpVendorLocation  
([VendorLocationID] ASC)  
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]  
  
/* Reduce list to only the closest location if the vendor has multiple physical or virtual locations within the Search Radius */  
DELETE #tmpVendorLocation   
FROM #tmpVendorLocation vl1  
WHERE NOT EXISTS (  
      SELECT *  
      FROM #tmpVendorLocation vl2  
      JOIN (  
            SELECT VendorID, MIN(Distance) Distance  
            FROM #tmpVendorLocation   
            GROUP BY VendorID  
            ) ClosestLocation   
            ON ClosestLocation.VendorID = vl2.VendorID and ClosestLocation.Distance = vl2.Distance  
      WHERE vl1.VendorLocationID = vl2.VendorLocationID AND  
            vl1.Distance = vl2.Distance  
      )  
  
/* For the vendor locations within the Search Radius determine vendors that can provide the desired service */  
INSERT INTO #IspDetail   
SELECT     
            v.ID VendorID    
            ,vl.ID VendorLocationID   
            ,tvl.VendorLocationVirtualID   
            ,CASE WHEN tvl.VendorLocationVirtualID IS NOT NULL THEN tvl.Latitude ELSE vl.Latitude END Latitude    
            ,CASE WHEN tvl.VendorLocationVirtualID IS NOT NULL THEN tvl.Longitude ELSE vl.Longitude END Longitude    
            ,v.Name VendorName    
            ,v.VendorNumber    
            ,CASE WHEN v.VendorNumber IS NULL THEN 'Internet' ELSE '' END AS [Source]  
            -- Have to check the if the selected product is a contract rate since the vendor can be contracted but not have a rate set for the service (bad data)    
            ,CAST(CASE WHEN VendorLocationRates.Price IS NOT NULL OR DefaultVendorRates.Price IS NOT NULL THEN 'Contracted'     
            ELSE NULL    
            END AS nvarchar(50)) AS ContractStatus    
            --,ph.PhoneNumber DispatchPhoneNumber   
   ,(SELECT Top 1 PhoneNumber  
    FROM dbo.[PhoneEntity]   
    WHERE RecordID = vl.ID   
    AND EntityID = @VendorLocationEntityID  
    AND PhoneTypeID = @DispatchPhoneTypeID  
    ORDER BY ID DESC   
     ) AS DispatchPhoneNumber  
            ,v.AdministrativeRating   
            -- Ignore time while comparing dates here  
            ,CASE WHEN v.InsuranceExpirationDate >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0) THEN 'Insured'   
            ELSE 'Not Insured' END InsuranceStatus    
            ,vl.[IsOpen24Hours]    
            ,vl.BusinessHours    
            ,vl.DispatchNote AS Comment    
            ,ROUND(tvl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END)/1609.344,1) EnrouteMiles    
            ,@ServiceMiles as ServiceMiles    
            ,ROUND(tvl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' OR @ProductCategoryID <> 1 THEN @ServiceLocation ELSE @DestinationLocation END)/1609.344,1) ReturnMiles    
            ,vlp.ProductID    
            ,p.Name ProductName    
            ,vlp.Rating ProductRating    
            ,prt.RateTypeID     
            ,CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Price    
                        WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Price    
                        ELSE MarketRates.Price     
            END AS RatePrice    
            ,CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Quantity    
                        WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Quantity    
                        ELSE MarketRates.Quantity     
            END AS RateQuantity    
            , rt.Name RateTypeName    
            , rt.UnitOfMeasure RateUnitOfMeasure    
            , rt.UnitOfMeasureSource RateUnitOfMeasureSource    
            ,CASE WHEN p.ID = ISNULL(@PrimaryProductID,0) THEN 1   
                        ELSE 0   
            END IsProductMatch    
FROM  #tmpVendorLocation tvl  
JOIN  dbo.VendorLocation vl on tvl.VendorLocationID = vl.ID   
JOIN  dbo.Vendor v  ON vl.VendorID = v.ID    
-- TP - Eliminate join duplication due to multiple dispatch numbers  
--JOIN (  
-- SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
-- FROM dbo.[PhoneEntity]   
-- WHERE EntityID = @VendorLocationEntityID  
-- AND PhoneTypeID = @DispatchPhoneTypeID  
-- GROUP BY EntityID, RecordID  
-- ) ph ON ph.RecordID = vl.ID     
JOIN  dbo.VendorLocationProduct vlp ON vl.ID = vlp.VendorLocationID AND vlp.IsActive = 1  
JOIN  dbo.Product p ON p.ID = vlp.ProductID    
JOIN  dbo.ProductRateType prt ON prt.ProductID = p.ID AND   prt.IsOptional = 0   
JOIN  dbo.RateType rt ON prt.RateTypeID = rt.ID    
LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() VendorLocationRates ON   
      v.ID = VendorLocationRates.VendorID AND   
      p.ID = VendorLocationRates.ProductID AND   
      prt.RateTypeID = VendorLocationRates.RateTypeID AND  
      VendorLocationRates.VendorLocationID = vl.ID   
LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() DefaultVendorRates ON   
      v.ID = DefaultVendorRates.VendorID AND   
      p.ID = DefaultVendorRates.ProductID AND   
      prt.RateTypeID = DefaultVendorRates.RateTypeID AND  
      DeFaultVendorRates.VendorLocationID IS NULL  
LEFT OUTER JOIN #MarketRates MarketRates ON p.ID = MarketRates.ProductID And MarketRates.RateTypeID = prt.RateTypeID   
    
WHERE   
(VendorLocationRates.RateTypeID IS NOT NULL OR DefaultVendorRates.Price IS NOT NULL OR MarketRates.Price IS NOT NULL)    
AND           
      (  
            (   vlp.ProductID = @PrimaryProductID  
                  AND  
                -- Additional condition to include tire stores if tire service and tire delivery selected  
                  (   
                    @IsTireDelivery = 0  
                    OR  
                    --If Tire delivery then Tire Repair must also have Tire Store Attributes  
                    (@IsTireDelivery = 1    
                              AND EXISTS (  
                              SELECT * FROM VendorLocationProduct vlp1   
                              JOIN Product p1 ON vlp1.ProductID = p1.ID and p1.ProductCategoryID = 2 and p1.ProductSubTypeID = 10  
                              WHERE vlp1.VendorLocationID = vl.ID)  
                    )   
                  )   
            --Additional condition for Mobile Mechanic service  
                  OR  
        (@ProductCategoryID = 8 AND vlp.ProductID IN (SELECT ID FROM Product WHERE ProductCategoryID = 8))  
  
            )  
      AND   
            -- Code to require towing service for possible tow  
            ( @SecondaryProductID IS NULL   
            OR EXISTS (SELECT * FROM VendorLocationProduct vlp2 WHERE vlp2.VendorLocationID = vl.ID and vlp2.ProductID = @SecondaryProductID)  
            )  
      )  
  
  
-- Remove duplicate results for vendorlocations that are caused by multiple product matches   
-- TP: 4/21 Removed previous record deletion logic that was no longer needed and added this logic to fix issue with mobile mechanic vendors appearing multiple times  
DELETE ISPDetail1  
FROM #IspDetail ISPDetail1   
WHERE NOT EXISTS (  
      SELECT *  
      FROM   
            (    
            Select VendorLocationID, Min(ProductID) MinProductID  
            FROM #IspDetail  
            Group by VendorLocationID   
            ) ISPDetail2   
      WHERE ISPDetail1.VendorLocationID = ISPDetail2.VendorLocationID   
            AND ISPDetail1.ProductID  = ISPDetail2.MinProductID  
      )   
  
    
 -- Select list of 'Do Not Use' vendors within the 'Do Not Use' search radius of the service location   
INSERT INTO #ISPDoNotUse   
SELECT      v.ID VendorID    
            ,vl.ID VendorLocationID   
            ,NULL   
            ,vl.Latitude    
            ,vl.Longitude    
            ,v.Name VendorName    
            ,v.VendorNumber    
            ,CASE WHEN v.VendorNumber IS NULL THEN 'Internet'   
                        ELSE 'Database'   
            END AS [Source]    
            ,'Not Contracted' AS ContractStatus    
            ,addr.Line1 Address1    
            ,addr.Line2 Address2    
            ,addr.City    
            ,addr.StateProvince    
            ,addr.PostalCode    
            ,addr.CountryCode    
            ,ph.PhoneNumber DispatchPhoneNumber    
            ,'' AS FaxPhoneNumber    
            ,'' AS OfficePhoneNumber   
            ,'' AS CellPhoneNumber  -- CR : 1226  
            ,0 AS AdministrativeRating    
            ,'' AS InsuranceStatus    
            ,'' AS BusinessHours    
            ,'' AS PaymentTypes  
            ,'' AS Comment    
            ,0 AS ProductID    
            ,'' AS ProductName    
            ,NULL AS ProductRating    
            ,ROUND(vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END)/1609.344,1) EnrouteMiles    
            ,NULL AS EnrouteTimeMinutes  
            ,NULL AS ServiceMiles    
            ,NULL AS ServiceTimeMinutes  
            ,NULL AS ReturnMiles    
            ,NULL AS ReturnTimeMinutes  
            ,NULL AS EstimatedHours    
            ,NULL AS BaseRate  
            ,NULL AS HourlyRate  
            ,NULL AS EnrouteRate  
            ,NULL AS EnrouteFreeMiles  
            ,NULL AS ServiceRate  
            ,NULL AS ServiceFreeMiles  
            ,NULL AS EstimatedPrice    
            ,-99999 AS WiseScore    
            ,'DoNotUse' AS CallStatus    
            ,'' AS RejectReason    
            ,'' AS RejectComment    
            ,0 AS IsPossibleCallback    
FROM  dbo.VendorLocation vl     
JOIN  dbo.Vendor v ON vl.VendorID = v.ID     
JOIN  dbo.[AddressEntity] addr ON addr.EntityID = @VendorLocationEntityID AND addr.RecordID = vl.ID AND addr.AddressTypeID = @BusinessAddressTypeID    
-- TP - Eliminate join duplication due to multiple dispatch numbers  
JOIN (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @DispatchPhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) ph ON ph.RecordID = vl.ID     
WHERE v.IsActive = 'TRUE'    
AND         v.VendorStatusID = @DoNotUseVendorStatusID  
AND         vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) <= @DNUSearchRadiusMiles * 1609.344    
AND         @IncludeDoNotUse = 'TRUE'    
ORDER BY vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END)    
  
-- DEBUG : SELECT * FROM #IspDetail  
  
-- Create ISP Selection data set from ISP Details, adding additional data items and related contact logs   
INSERT INTO @ISPSelection   
SELECT      ISP.VendorID    
            ,ISP.VendorLocationID    
            ,ISP.VendorLocationVirtualID  
            ,ISP.Latitude    
            ,ISP.Longitude    
            ,ISP.VendorName + CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN ' (virtual)' ELSE '' END AS VendorName  
            ,ISP.VendorNumber    
            ,ISP.[Source]    
            ,ISNULL(MAX(ISP.ContractStatus), 'Not Contracted') ContractStatus    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationAddress ELSE addr.Line1 END Address1    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN NULL ELSE addr.Line2 END Address2    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationCity ELSE addr.City END City    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationStateProvince ELSE addr.StateProvince END StateProvince    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationPostalCode ELSE addr.PostalCode END PostalCode    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationCountryCode ELSE addr.CountryCode END CountryCode    
            ,ISP.DispatchPhoneNumber    
            ,FaxPh.PhoneNumber FaxPhoneNumber  
            ,ph.PhoneNumber OfficePhoneNumber  
            ,cph.PhoneNumber CellPhoneNumber --  CR : 1226  
            ,ISP.AdministrativeRating    
            ,ISP.InsuranceStatus    
            ,CASE WHEN ISP.[IsOpen24Hours] = 1 THEN '24/7'   
            ELSE ISNULL(ISP.BusinessHours,'') END AS BusinessHours    
            ,PaymentTypes.List AS PaymentTypes  
            ,ISP.Comment    
            ,ISP.ProductID    
            ,ISP.ProductName    
            ,ISP.ProductRating    
            ,ISP.EnrouteMiles    
            ,(ISP.EnrouteMiles/40)*60 AS EnrouteTimeMinutes  
            ,ISP.ServiceMiles    
            ,(ISP.ServiceMiles/40)*60 AS ServiceTimeMinutes  
            ,ISP.ReturnMiles    
            ,(ISP.ReturnMiles/40)*60 AS ReturnTimeMinutes  
            ,SUM(1.5 + ROUND((ISP.EnrouteMiles + ISP.ServiceMiles + ISP.ReturnMiles)/40,2)) AS EstimatedHours    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Base' THEN ISP.RatePrice ELSE 0 END) AS BaseRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Hourly' THEN ISP.RatePrice ELSE 0 END) AS HourlyRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Enroute' THEN ISP.RatePrice ELSE 0 END) AS EnrouteRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'EnrouteFree' THEN ISP.RateQuantity ELSE 0 END) AS EnrouteFreeMiles    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Service' THEN ISP.RatePrice ELSE 0 END) AS ServiceRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'ServiceFree' THEN ISP.RateQuantity ELSE 0 END) AS ServiceFreeMiles    
            ,ROUND(SUM(CASE     
                                    WHEN ISP.RateUnitOfMeasure = 'Each' THEN ISP.RatePrice     
                                    WHEN ISP.RateUnitOfMeasure = 'Hour' THEN ISP.RatePrice * (1.5 + ROUND((ISP.EnrouteMiles + ISP.ServiceMiles + ISP.ReturnMiles)/40,2))    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity = 0 THEN ISP.RatePrice * ISP.EnrouteMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity = 0 THEN ISP.RatePrice * ISP.ServiceMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.EnrouteMiles THEN ISP.EnrouteMiles ELSE ISP.RateQuantity END)
    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.ServiceMiles THEN ISP.ServiceMiles ELSE ISP.RateQuantity END) 
   
                                    ELSE 0   
                              END),2) EstimatedPrice    
            ,ROUND((AdministrativeRating*@AdminWeight)+(ProductRating*@PerformWeight)-    
                        (SUM(CASE     
                                    WHEN ISP.RateUnitOfMeasure = 'Each' THEN ISP.RatePrice     
                                    WHEN ISP.RateUnitOfMeasure = 'Hour' THEN ISP.RatePrice * (1.5 + ROUND((ISP.EnrouteMiles + ISP.ServiceMiles + ISP.ReturnMiles)/40,2))    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity = 0 THEN ISP.RatePrice * ISP.EnrouteMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity = 0 THEN ISP.RatePrice * ISP.ServiceMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.EnrouteMiles THEN ISP.EnrouteMiles ELSE ISP.RateQuantity END) 
   
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.ServiceMiles THEN ISP.ServiceMiles ELSE ISP.RateQuantity END) 
   
                                    ELSE 0   
                              END) * @CostWeight),2) as WiseScore    
            ,CASE WHEN ContactLogAction.VendorLocationID IS NULL THEN 'NotCalled'    
                        WHEN ISNULL(ContactLogAction.Name,'') = '' THEN 'Called'    
                        WHEN ISNULL(ContactLogAction.Name,'') = 'Accepted' THEN 'Accepted'    
                        ELSE 'Rejected'   
            END AS CallStatus    
            ,ContactLogAction.[Description] RejectReason    
            ,ContactLogAction.[Comments] RejectComment    
            ,ISNULL(ContactLogAction.IsPossibleCallback,0) AS IsPossibleCallback    
FROM  #IspDetail ISP    
LEFT OUTER JOIN  dbo.[VendorLocationVirtual] vlv ON vlv.ID = ISP.VendorLocationVirtualID  
LEFT OUTER JOIN  dbo.[AddressEntity] addr ON addr.EntityID = @VendorLocationEntityID AND addr.RecordID = ISP.VendorLocationID AND addr.AddressTypeID = @BusinessAddressTypeID    
-- TP - Eliminate join duplication due to multiple Fax numbers  
LEFT OUTER JOIN  (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @FaxPhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) Faxph ON Faxph.RecordID = ISP.VendorLocationID     
-- TP - Eliminate join duplication due to multiple Office numbers  
LEFT OUTER JOIN  (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @OfficePhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) ph ON ph.RecordID = ISP.VendorLocationID     
-- TP - Eliminate join duplication due to multiple Cell numbers  
LEFT OUTER JOIN  (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @CellPhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) cph ON cph.RecordID = ISP.VendorLocationID     
-- Get last ContactLog result for the current sevice request for the ISP  
LEFT OUTER JOIN (    
                              SELECT      LastISPContactLog.VendorLocationID    
                                          ,LastContactLogAction.Name    
                                          ,LastContactLogAction.[Description]    
                                          ,cl.Comments    
                                          ,ISNULL(cl.IsPossibleCallback,0) IsPossibleCallback    
                              FROM  dbo.ContactLog cl    
                              JOIN (  
                                          SELECT      ISPcll.RecordID VendorLocationID, MAX(cl.ID) ID   
                                          FROM  dbo.ContactLog cl    
                                          JOIN  dbo.ContactLogLink SRcll ON SRcll.ContactLogID = cl.ID AND SRcll.EntityID = @ServiceRequestEntityID AND SRcll.RecordID = @ServiceRequestID     
                                          JOIN dbo.ContactLogLink ISPcll ON ISPcll.ContactLogID = cl.ID AND ISPcll.EntityID = @VendorLocationEntityID    
                                          JOIN dbo.ContactLogReason clr ON clr.ContactLogID = cl.ID    
                                          JOIN dbo.ContactReason cr ON cr.ID = clr.ContactReasonID    
                                          WHERE cr.Name = 'ISP selection'    
                                          GROUP BY ISPcll.RecordID  
                                    ) LastISPContactLog ON LastISPContactLog.ID = cl.ID  
                              LEFT OUTER JOIN (    
                                          SELECT      cla.ContactLogID  
                                                      ,ca.Name  
                                                      ,ca.[Description]  
                                                      ,cla.Comments    
                                          FROM  dbo.ContactLogAction cla    
                                          JOIN  dbo.ContactAction ca ON ca.ID = cla.ContactActionID    
                                          JOIN  (    
                                                            SELECT      cla1.ContactLogID, MAX(cla1.ID) ID    
                                                            FROM      dbo.ContactLogAction cla1    
                                                            GROUP BY cla1.ContactLogID    
                                                      ) MaxContactLogAction ON MaxContactLogAction.ContactLogID = cla.ContactLogID AND MaxContactLogAction.ID = cla.ID    
                                    ) LastContactLogAction ON LastContactLogAction.ContactLogID = cl.ID   
                        ) ContactLogAction ON ContactLogAction.VendorLocationID = ISP.VendorLocationID    
-- Get Payment Types accepted by this vendor                        
LEFT OUTER JOIN (    
      SELECT  
         pt1.VendorLocationID,  
         List = stuff((SELECT ( ', ' + [Description] )  
                    FROM (Select vlpt.VendorLocationID, pt.Name, pt.Sequence, pt.[Description]   
                              From VendorLocationPaymentType vlpt  
                              Join PaymentType pt on vlpt.PaymentTypeID = pt.ID  
                              ) pt2  
                    WHERE pt1.VendorLocationID = pt2.VendorLocationID  
                    ORDER BY VendorLocationID, pt2.Sequence  
                        FOR XML PATH( '' )  
                  ), 1, 1, '' )  
                  FROM   
                        (Select vlpt.VendorLocationID, pt.Name  
                        From VendorLocationPaymentType vlpt  
                        Join #IspDetail ISP on ISP.VendorLocationID = vlpt.VendorLocationID  
                        Join PaymentType pt on vlpt.PaymentTypeID = pt.ID  
                        ) pt1  
      GROUP BY pt1.VendorLocationID  
      ) PaymentTypes ON PaymentTypes.VendorLocationID = ISP.VendorLocationID  
GROUP BY    
                  ISP.VendorID    
                  ,ISP.VendorLocationID    
                  ,ISP.VendorLocationVirtualID  
                  ,ISP.Latitude    
                  ,ISP.Longitude    
                  ,ISP.VendorName    
                  ,ISP.VendorNumber    
                  ,ISP.[Source]    
                  ,addr.Line1     
                  ,addr.Line2     
                  ,addr.City    
                  ,addr.StateProvince    
                  ,addr.PostalCode    
                  ,addr.CountryCode    
                  ,vlv.LocationAddress  
                  ,vlv.LocationCity    
                  ,vlv.LocationStateProvince    
                  ,vlv.LocationPostalCode    
                  ,vlv.LocationCountryCode    
                  ,ISP.DispatchPhoneNumber    
                  ,Faxph.PhoneNumber  
                  ,ph.PhoneNumber   
                  ,cph.PhoneNumber   
                  ,ISP.AdministrativeRating    
                  ,ISP.InsuranceStatus    
                  ,ISP.[IsOpen24Hours]    
                  ,ISP.BusinessHours    
                  ,ISP.Comment    
                  ,ISP.ProductID    
                  ,ISP.ProductName    
                  ,ISP.ProductRating    
                  ,ISP.EnrouteMiles    
                  ,ISP.ServiceMiles    
                  ,ISP.ReturnMiles    
                  ,ISP.IsProductMatch    
                  ,ContactLogAction.VendorLocationID    
                  ,ContactLogAction.[Description]     
                  ,ContactLogAction.Comments     
                  ,ISNULL(ContactLogAction.Name ,'')  
                  ,ContactLogAction.IsPossibleCallback    
                  ,PaymentTypes.List  
ORDER BY   
                  WiseScore DESC  
                  ,EstimatedPrice  
                  ,EnrouteMiles  
                  ,ProductRating DESC    
   
 -- Log ISP SELECTION Results (first resultset).  
INSERT INTO ISPSelectionLog  
            ([VendorID]  
           ,[VendorLocationID]  
           ,[VendorLocationVirtualID]  
           ,[SelectionOrder]  
           ,[ServiceRadiusMiles]  
           ,[Latitude]  
           ,[Longitude]  
           ,[VendorName]  
           ,[VendorNumber]  
           ,[Source]  
           ,[ContractStatus]  
           ,[Address1]  
           ,[Address2]  
           ,[City]  
           ,[StateProvince]  
           ,[PostalCode]  
           ,[CountryCode]  
           ,[DispatchPhoneNumber]  
           ,[FaxPhoneNumber]  
           ,[OfficePhoneNumber]  
           ,[CellPhoneNumber]  
           ,[AdministrativeRating]  
           ,[InsuranceStatus]  
           ,[BusinessHours]  
           ,[PaymentTypes]  
           ,[Comment]  
           ,[ProductID]  
           ,[ProductName]  
           ,[ProductRating]  
           ,[EnrouteMiles]  
           ,[EnrouteTimeMinutes]  
           ,[ServiceMiles]  
           ,[ServiceTimeMinutes]  
           ,[ReturnMiles]  
           ,[ReturnTimeMinutes]  
           ,[EstimatedHours]  
           ,[BaseRate]  
           ,[HourlyRate]  
           ,[EnrouteRate]  
           ,[EnrouteFreeMiles]  
           ,[ServiceRate]  
           ,[ServiceFreeMiles]  
           ,[EstimatedPrice]  
           ,[WiseScore]  
           ,[CallStatus]  
           ,[RejectReason]  
           ,[RejectComment]  
           ,[IsPossibleCallback]  
           ,[ProductSearchRadiusMiles]  
           ,[IsInProductSearchRadius]  
           ,[ServiceRequestID]  
           ,[LogTime]  
           ,[Resultset])  
SELECT   
            VendorID    
            ,VendorLocationID    
            ,VendorLocationVirtualID  
            ,row_number() OVER(ORDER BY WiseScore DESC  
                  ,EstimatedPrice  
                  ,EnrouteMiles  
                  ,ProductRating DESC) AS SelectionOrder  
            ,@ProductSearchRadiusMiles  
            ,Latitude    
            ,Longitude    
            ,VendorName    
            ,VendorNumber    
            ,[Source]    
            ,ContractStatus    
            ,Address1    
            ,Address2    
            ,City    
            ,StateProvince    
            ,PostalCode    
            ,CountryCode    
            ,DispatchPhoneNumber    
            ,FaxPhoneNumber  
            ,OfficePhoneNumber    
            ,CellPhoneNumber  
            ,AdministrativeRating    
            ,InsuranceStatus    
            ,BusinessHours    
            ,PaymentTypes  
            ,Comment    
            ,ProductID    
            ,ProductName    
            ,ProductRating    
            ,EnrouteMiles    
            ,EnrouteTimeMinutes  
            ,ServiceTimeMinutes  
            ,ReturnMiles    
            ,ReturnTimeMinutes  
            ,EstimatedHours    
            ,BaseRate  
            ,HourlyRate  
            ,EnrouteRate  
            ,EnrouteFreeMiles  
            ,ServiceRate  
            ,ServiceMiles  
            ,ServiceFreeMiles  
            ,EstimatedPrice    
            ,WiseScore    
            ,CallStatus    
  ,RejectReason    
            ,RejectComment    
            ,IsPossibleCallback  
            ,@ProductSearchRadiusMiles AS ProductSearchRadiusMiles  
            ,NULL AS IsInProductSearchRadius  
            ,@ServiceRequestID  
            ,@now  
            ,'ISPSELECTION'    
 FROM @ISPSelection   
 WHERE @LogISPSelection = 1  
  
   
-- Combine ISP Selection and ISP Do Not use results     
-- Collect products in a separate query   
INSERT INTO @ISPSelectionFinalResults    
SELECT      TOP 50    
            I.VendorID    
            ,I.VendorLocationID    
            ,VendorLocationVirtualID  
            ,Latitude    
            ,Longitude    
            ,VendorName    
            ,VendorNumber    
            ,[Source]    
            ,ContractStatus    
            ,Address1    
            ,Address2    
            ,City    
            ,StateProvince    
            ,PostalCode    
            ,CountryCode    
            ,DispatchPhoneNumber    
            ,FaxPhoneNumber  
            ,OfficePhoneNumber    
            ,CellPhoneNumber  
            ,AdministrativeRating    
            ,InsuranceStatus    
            ,BusinessHours    
            ,PaymentTypes  
            ,Comment    
            ,ProductID    
            ,ProductName    
            ,ProductRating    
            ,EnrouteMiles    
            ,EnrouteTimeMinutes  
            ,ServiceMiles  
            ,ServiceTimeMinutes  
            ,ReturnMiles    
            ,ReturnTimeMinutes  
            ,EstimatedHours    
            ,BaseRate  
            ,HourlyRate  
            ,EnrouteRate  
            ,EnrouteFreeMiles  
            ,ServiceRate  
            ,ServiceFreeMiles  
            ,EstimatedPrice    
            ,WiseScore    
            ,CallStatus    
            ,RejectReason    
            ,RejectComment    
            ,IsPossibleCallback  
            ,'' AS [AllServices]  
            ,@ProductSearchRadiusMiles AS ProductSearchRadiusMiles  
            ,CASE WHEN (I.EnrouteMiles <= @ProductSearchRadiusMiles) OR Top3Contracted.VendorLocationID IS NOT NULL THEN 1 ELSE 0 END AS IsInProductSearchRadius   
FROM  @ISPSelection I  
-- Identify top 3 contracted vendors  
LEFT OUTER JOIN (  
      SELECT TOP 3 VendorLocationID  
      FROM @ISPSelection  
      WHERE ContractStatus = 'Contracted'  
      ORDER BY EnrouteMiles ASC, WiseScore DESC  
      ) Top3Contracted ON Top3Contracted.VendorLocationID = I.VendorLocationID  
-- Apply product availability filtering (@ProductIDs list)  
WHERE EXISTS      (  
                              SELECT      *  
                              FROM  VendorLocation vl  
                              JOIN  VendorLocationProduct vlp   
                              ON          vlp.VendorLocationID = vl.ID  
                              JOIN  Product p on p.ID = vlp.ProductID   
                              WHERE vl.ID = I.VendorLocationID  
                              AND         (     ISNULL(@productIDs,'') = ''   
                                                OR    
                                                p.ID IN (SELECT item from [dbo].[fnSplitString](@productIDs,','))  
                                          )  
                        )  
  
ORDER BY WiseScore DESC, EstimatedPrice, EnrouteMiles, ProductRating DESC    
  
/* Add 'Do Not Use' vendors to the results (if selected above) */  
INSERT INTO @ISPSelectionFinalResults  
SELECT      TOP 100    
            I.VendorID    
            ,VendorLocationID    
            ,VendorLocationVirtualID  
            ,Latitude    
            ,Longitude    
            ,VendorName    
            ,VendorNumber    
            ,[Source]    
            ,ContractStatus    
            ,Address1    
            ,Address2    
            ,City    
            ,StateProvince    
            ,PostalCode    
            ,CountryCode    
            ,DispatchPhoneNumber    
            ,FaxPhoneNumber  
            ,OfficePhoneNumber    
            ,CellPhoneNumber  
            ,AdministrativeRating    
            ,InsuranceStatus    
            ,BusinessHours    
            ,PaymentTypes  
            ,Comment    
            ,ProductID    
            ,ProductName    
            ,ProductRating    
            ,EnrouteMiles    
            ,EnrouteTimeMinutes  
            ,ServiceTimeMinutes  
            ,ReturnMiles    
            ,ReturnTimeMinutes  
            ,EstimatedHours    
            ,BaseRate  
            ,HourlyRate  
            ,EnrouteRate  
            ,EnrouteFreeMiles  
            ,ServiceRate  
            ,ServiceMiles  
            ,ServiceFreeMiles  
            ,EstimatedPrice    
            ,WiseScore    
            ,CallStatus    
            ,RejectReason    
            ,RejectComment    
            ,IsPossibleCallback  
            , '' AS [AllServices]   
            ,@ProductSearchRadiusMiles AS ProductSearchRadiusMiles  
            ,0 AS IsInProductSearchRadius  
FROM  #ISPDoNotUse I  
ORDER BY WiseScore DESC, EstimatedPrice, EnrouteMiles, ProductRating DESC    
   
-- Get all the products for the vendors collected in the above query.  
;WITH wVLP  
AS  
(  
      SELECT      vl.VendorID,  
                  vl.ID,   
                  [dbo].[fnConcatenate](p.Name) AS AllServices  
      FROM  VendorLocation vl  
      JOIN  VendorLocationProduct vlp on vlp.VendorLocationID = vl.ID  
      JOIN  Product p on p.ID = vlp.ProductID  
      JOIN  @ISPSelectionFinalResults ISP ON vl.ID = ISP.VendorLocationID AND vl.VendorID = ISP.VendorID  
      WHERE vlp.IsActive = 1  
      GROUP BY vl.VendorID,vl.ID  
)  
  
 -- Include 'All Services' provided by the selected ISPs in the results  
UPDATE      @ISPSelectionFinalResults  
SET         AllServices = W.AllServices  
FROM  wVLP W,  
            @ISPSelectionFinalResults ISP  
WHERE W.VendorID = ISP.VendorID  
AND         W.ID = VendorLocationID  
  
-- Remove Black Listed vendors from the result for this member  
DELETE FROM @ISPSelectionFinalResults  
WHERE VendorID IN (  
                                    SELECT VendorID  
                                    FROM MembershipBlackListVendor  
                                    WHERE MembershipID = @MembershipID  
                              )  
  
/* Insert reults into ISP Selection log */  
INSERT INTO ISPSelectionLog  
            ([VendorID]  
           ,[VendorLocationID]  
           ,[VendorLocationVirtualID]  
           ,[SelectionOrder]  
           ,[ServiceRadiusMiles]  
           ,[Latitude]  
           ,[Longitude]  
           ,[VendorName]  
           ,[VendorNumber]  
           ,[Source]  
           ,[ContractStatus]  
           ,[Address1]  
           ,[Address2]  
           ,[City]  
           ,[StateProvince]  
           ,[PostalCode]  
           ,[CountryCode]  
           ,[DispatchPhoneNumber]  
           ,[FaxPhoneNumber]  
           ,[OfficePhoneNumber]  
           ,[CellPhoneNumber]  
           ,[AdministrativeRating]  
           ,[InsuranceStatus]  
           ,[BusinessHours]  
           ,[PaymentTypes]  
           ,[Comment]  
           ,[ProductID]  
           ,[ProductName]  
           ,[ProductRating]  
           ,[EnrouteMiles]  
           ,[EnrouteTimeMinutes]  
           ,[ServiceMiles]  
           ,[ServiceTimeMinutes]  
           ,[ReturnMiles]  
           ,[ReturnTimeMinutes]  
           ,[EstimatedHours]  
           ,[BaseRate]  
           ,[HourlyRate]  
           ,[EnrouteRate]  
           ,[EnrouteFreeMiles]  
           ,[ServiceRate]  
           ,[ServiceFreeMiles]  
           ,[EstimatedPrice]  
           ,[WiseScore]  
           ,[CallStatus]  
           ,[RejectReason]  
           ,[RejectComment]  
           ,[IsPossibleCallback]  
           ,[ProductSearchRadiusMiles]  
           ,[IsInProductSearchRadius]  
           ,[ServiceRequestID]  
           ,[LogTime]  
           ,[Resultset])  
SELECT ISP.VendorID    
            ,ISP.VendorLocationID   
            ,ISP.VendorLocationVirtualID   
            ,row_number() OVER(ORDER BY   
                  ISP.IsInProductSearchRadius DESC,  
                  ISP.WiseScore DESC,   
    ISP.EstimatedPrice,   
                  ISP.EnrouteMiles,   
                  ISP.ProductRating DESC) AS SelectionOrder  
            ,@ProductSearchRadiusMiles  
            ,Latitude    
            ,Longitude    
            ,VendorName    
            ,VendorNumber    
            ,[Source]    
            ,ContractStatus    
            ,Address1    
            ,Address2    
            ,City    
            ,StateProvince    
            ,PostalCode    
            ,CountryCode    
            ,DispatchPhoneNumber    
            ,FaxPhoneNumber  
            ,OfficePhoneNumber    
            ,CellPhoneNumber  
            ,AdministrativeRating    
            ,InsuranceStatus    
            ,BusinessHours    
            ,PaymentTypes  
            ,Comment    
            ,ProductID    
            ,ProductName    
            ,ProductRating    
            ,EnrouteMiles    
            ,EnrouteTimeMinutes  
            ,ServiceTimeMinutes  
            ,ReturnMiles    
            ,ReturnTimeMinutes  
            ,EstimatedHours    
            ,BaseRate  
            ,HourlyRate  
            ,EnrouteRate  
            ,EnrouteFreeMiles  
            ,ServiceRate  
            ,ServiceMiles  
            ,ServiceFreeMiles  
            ,EstimatedPrice    
            ,WiseScore    
            ,CallStatus    
            ,RejectReason    
            ,RejectComment    
            ,IsPossibleCallback  
            ,ProductSearchRadiusMiles  
            ,IsInProductSearchRadius  
            ,@ServiceRequestID  
            ,@now  
            ,'ISPSELECTION_FINAL'    
FROM @ISPSelectionFinalResults ISP  
WHERE @LogISPSelectionFinal = 1  
ORDER BY      
      ISP.IsInProductSearchRadius DESC,  
      ISP.WiseScore DESC,   
      ISP.EstimatedPrice,   
      ISP.EnrouteMiles,   
      ISP.ProductRating DESC   
  
/* Return results */  
SELECT      ISP.*   
FROM  @ISPSelectionFinalResults ISP  
ORDER BY      
      ISP.IsInProductSearchRadius DESC,  
      ISP.WiseScore DESC,   
      ISP.EstimatedPrice,   
      ISP.EnrouteMiles,   
      ISP.ProductRating DESC   
  
DROP TABLE #IspDoNotUse  
DROP TABLE #IspDetail  
DROP TABLE #tmpVendorLocation  
DROP TABLE #MarketRates  
  
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
HasPO BIT NULL
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
@HasPO BIT   
  
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
	HasPo
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
 HasPO BIT
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
  @HasPO = HasPO
FROM @tmpForWhereClause  
  
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
 FROM AddressEntity   
 WHERE EntityID = @vendorEntityID  
 AND  AddressTypeID = @businessAddressTypeID  
)  
INSERT INTO #FinalResultsFiltered  
SELECT DISTINCT  
  --CASE WHEN C.VendorID IS NOT NULL   
  --  THEN 'Contracted'   
  --  ELSE 'Not Contracted'   
  --  END AS ContractStatus  
  --NULL As ContractStatus  
  CASE  
   WHEN ContractedVendors.ContractID IS NOT NULL   
    AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'  
   ELSE 'Not Contracted'   
  END AS ContractStatus  
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
  , VS.Name AS VendorStatus  
  , VR.Name AS VendorRegion  
  , AE.PostalCode  
  , ISNULL(COUNT(PO.ID),0) AS POCount
FROM Vendor V WITH (NOLOCK)  
LEFT JOIN   VendorLocation VL ON V.ID = VL.VendorID
LEFT JOIN   PurchaseOrder PO ON VL.ID = PO.VendorLocationID AND ISNULL(PO.IsActive,0) = 1
LEFT JOIN wVendorAddresses AE ON AE.RecordID = V.ID AND AE.RowNum = 1  
LEFT JOIN PhoneEntity PE ON PE.RecordID = V.ID   
     AND PE.EntityID = @vendorEntityID  
     AND PE.PhoneTypeID = @officePhoneTypeID  
LEFT JOIN VendorStatus VS ON VS.ID = V.VendorStatusID  
LEFT JOIN VendorACH VACH ON VACH.VendorID = V.ID  
LEFT JOIN VendorRegion VR ON VR.ID=V.VendorRegionID  
LEFT OUTER JOIN(  
   SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID  
   FROM dbo.fnGetContractedVendors() cv  
   ) ContractedVendors ON v.ID = ContractedVendors.VendorID   
--LEFT OUTER JOIN (SELECT VendorID, MAX(CreateDate) AS [CreateDate] FROM [Contract] WHERE IsActive = 1 GROUP BY VendorID) C ON C.VendorID = V.ID  
  
WHERE V.IsActive = 1  -- Not deleted    
AND  (@VendorNumber IS NULL OR @VendorNumber = V.VendorNumber)  
AND  (@CountryID IS NULL OR @CountryID = AE.CountryID)  
AND  (@StateProvinceID IS NULL OR @StateProvinceID = AE.StateProvinceID)  
AND  (@City IS NULL OR @City = AE.City)  
AND  (@PostalCode IS NULL OR @PostalCode = AE.PostalCode)  
AND  (@IsLevy IS NULL OR @IsLevy = ISNULL(V.IsLevyActive,0))  
AND  (@VendorStatus IS NULL OR VS.ID IN (SELECT Item FROM [dbo].[fnSplitString](@VendorStatus,',') ) )  
AND  (@VendorRegion IS NULL OR VR.ID IN (SELECT Item FROM [dbo].[fnSplitString](@VendorRegion,',') ) )  
AND  (    
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
 GROUP BY 

		ContractStatus,
		V.ID,
		V.VendorNumber,
		V.Name,
		AE.City,
		AE.StateProvince,
		AE.CountryCode,
		PE.PhoneNumber,
		V.AdministrativeRating,
		V.InsuranceExpirationDate,
		VACH.BankABANumber,
		VS.Name,
		VR.Name,
		AE.PostalCode,
		ContractedVendors.ContractRateScheduleID,
		ContractedVendors.ContractID
 --UPDATE #FinalResultsFiltered  
 --SET ContractStatus = CASE WHEN C.VendorID IS NOT NULL   
 --      THEN 'Contracted'   
 --      ELSE 'Not Contracted'   
 --      END,  
 -- PaymentMethod =  CASE  
 --      WHEN ISNULL(F.PaymentMethod,'') = '' THEN 'Check'  
 --      ELSE 'DirectDeposit'  
 --      END  
 --FROM #FinalResultsFiltered F  
 --LEFT OUTER JOIN (SELECT VendorID, MAX(CreateDate) AS [CreateDate] FROM [Contract] WHERE IsActive = 1 GROUP BY VendorID) C ON C.VendorID = F.VendorID  
   
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
 FROM #FinalResultsFiltered T   
 WHERE	(@HasPO IS NULL OR @HasPO = 0 OR T.POCount > 0)
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
  
END  

GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Contract_Status_Get]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Contract_Status_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_Vendor_Contract_Status_Get] 337
 CREATE PROCEDURE [dbo].[dms_Vendor_Contract_Status_Get]( 
  @VendorID INT = NULL
) 
 AS 
 BEGIN       
      SET NOCOUNT ON  

SELECT    
    CASE  
    WHEN ContractedVendors.ContractID IS NOT NULL   
		AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'  
    ELSE 'Not Contracted'   
		END AS ContractStatus  
    From Vendor v 
      LEFT OUTER JOIN(  
   SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID  
   FROM dbo.fnGetContractedVendors() cv  
   ) ContractedVendors ON v.ID = ContractedVendors.VendorID   
      Where v.ID = @VendorID  
  
END  

GO


IF  EXISTS 
(SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].dms_vendor_Location_Address_Get') 
AND type IN (N'P', N'PC'))
DROP PROCEDURE [dbo].dms_vendor_Location_Address_Get
GO
--EXEC dms_vendor_Location_Address_Get @VendorLocationID=158
CREATE PROCEDURE dms_vendor_Location_Address_Get
	@VendorLocationID INT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
DECLARE @FaxPhoneTypeID INT,
        @DispatchPhoneTypeID INT,
        @OfficePhoneTypeID INT,
        @VendorLocationEntityTypeID INT

SET @FaxPhoneTypeID = (SELECT TOP 1 ID FROM PhoneType WHERE Name='Fax')   
SET @DispatchPhoneTypeID = (SELECT TOP 1 ID FROM PhoneType WHERE Name='Dispatch')
SET @OfficePhoneTypeID = (SELECT TOP 1 ID FROM PhoneType WHERE Name='Office')   
SET @VendorLocationEntityTypeID = (SELECT TOP 1 ID FROM Entity WHERE Name='VendorLocation')
  	
SELECT VL.ID AS VendorLocation  
  , ISNULL(REPLACE(RTRIM(  
   COALESCE(AE.Line1, '')  
   ), '  ', ' ')  
   ,'') AS LocationAddress1  
   , ISNULL(REPLACE(RTRIM(  
   COALESCE(AE.Line2, '') 
   ), '  ', ' ')  
   ,'') AS LocationAddress2 
   , ISNULL(REPLACE(RTRIM(      
   COALESCE(AE.Line3, '')  
   ), '  ', ' ')  
   ,'') AS LocationAddress3
   , ISNULL(REPLACE(RTRIM(       
   COALESCE(AE.City, '')   
   ), '  ', ' ')  
   ,'') AS LocationCity
  , AE.StateProvinceID  AS LocationState
  , AE.CountryID AS LocationCountry
  , AE.PostalCode AS LocationPostalCode
  , PEF.PhoneNumber AS LocationFaxNumber
  , PED.PhoneNumber AS LocationDispatchNumber
  , PEO.PhoneNumber AS LocationOfficeNumber
  --, VL.DefaultLocationName AS LocationName
FROM  VendorLocation VL  
JOIN  AddressEntity AE   
  ON AE.RecordID = VL.ID   
  AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')  
 
	LEFT JOIN PhoneEntity PEF ON PEF.RecordID = VL.ID AND PEF.PhoneTypeID = @FaxPhoneTypeID AND PEF.EntityID = @VendorLocationEntityTypeID 
	LEFT JOIN PhoneEntity PED ON PED.RecordID = VL.ID AND PED.PhoneTypeID = @DispatchPhoneTypeID AND PED.EntityID = @VendorLocationEntityTypeID 
	LEFT JOIN PhoneEntity PEO ON PEO.RecordID = VL.ID AND PEO.PhoneTypeID = @OfficePhoneTypeID AND PEO.EntityID = @VendorLocationEntityTypeID 
LEFT OUTER JOIN (  
  SELECT VendorLocationID, COUNT(*) ProductCount  
  FROM VendorLocationProduct   
  GROUP BY VendorLocationID  
  ) VLP ON VLP.VendorLocationID = VL.ID   
LEFT JOIN  VendorLocationStatus VLS  
  ON VLS.ID = VL.VendorLocationStatusID 
WHERE  VL.ID=@VendorLocationID 
END
GO
