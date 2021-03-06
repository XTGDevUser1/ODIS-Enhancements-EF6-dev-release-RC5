/****** Object:  StoredProcedure [dbo].[dms_Vendor_PO_Details_Get]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_PO_Details_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_PO_Details_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC dms_Vendor_PO_Details_Get @VendorID=1
 CREATE PROCEDURE [dbo].[dms_Vendor_PO_Details_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @VendorID INT 
 ) 
 AS 
 BEGIN 
  SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
PurchaseOrderNumberOperator="-1" 
IssueDateOperator="-1" 
AddressOperator="-1" 
MemberNameOperator="-1" 
CreateByOperator="-1" 
StatusOperator="-1" 
ServiceOperator="-1" 
PurchaseOrderAmountOperator="-1" 
PaidDateOperator="-1" 
MemberNumberOperator="-1" 
ServiceRequestIDOperator="-1"
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
PurchaseOrderNumberOperator INT NOT NULL,
PurchaseOrderNumberValue nvarchar(100) NULL,
IssueDateOperator INT NOT NULL,
IssueDateValue datetime NULL,
AddressOperator INT NOT NULL,
AddressValue nvarchar(100) NULL,
MemberNameOperator INT NOT NULL,
MemberNameValue nvarchar(100) NULL,
CreateByOperator INT NOT NULL,
CreateByValue nvarchar(100) NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL,
ServiceOperator INT NOT NULL,
ServiceValue nvarchar(100) NULL,
PurchaseOrderAmountOperator INT NOT NULL,
PurchaseOrderAmountValue nvarchar(100) NULL,
PaidDateOperator INT NOT NULL,
PaidDateValue datetime NULL,
MemberNumberOperator INT NOT NULL,
MemberNumberValue int NULL,
ServiceRequestIDOperator INT NOT NULL,
ServiceRequestIDValue int NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	PurchaseOrderNumber nvarchar(100)  NULL ,
	IssueDate datetime  NULL ,
	Address nvarchar(100)  NULL ,
	MemberName nvarchar(100)  NULL ,
	CreateBy nvarchar(100)  NULL ,
	Status nvarchar(100)  NULL ,
	Service nvarchar(100)  NULL ,
	PurchaseOrderAmount nvarchar(100)  NULL ,
	PaidDate datetime  NULL ,
	MemberNumber int  NULL ,
	ServiceRequestID int  NULL   
) 
CREATE TABLE #FinalResults1( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	PurchaseOrderNumber nvarchar(100)  NULL ,
	IssueDate datetime  NULL ,
	Address nvarchar(100)  NULL ,
	MemberName nvarchar(100)  NULL ,
	CreateBy nvarchar(100)  NULL ,
	Status nvarchar(100)  NULL ,
	Service nvarchar(100)  NULL ,
	PurchaseOrderAmount nvarchar(100)  NULL ,
	PaidDate datetime  NULL ,
	MemberNumber int  NULL ,
	ServiceRequestID int  NULL   
) 
INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@PurchaseOrderNumberOperator','INT'),-1),
	T.c.value('@PurchaseOrderNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@IssueDateOperator','INT'),-1),
	T.c.value('@IssueDateValue','datetime') ,
	ISNULL(T.c.value('@AddressOperator','INT'),-1),
	T.c.value('@AddressValue','nvarchar(100)') ,
	ISNULL(T.c.value('@MemberNameOperator','INT'),-1),
	T.c.value('@MemberNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CreateByOperator','INT'),-1),
	T.c.value('@CreateByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ServiceOperator','INT'),-1),
	T.c.value('@ServiceValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PurchaseOrderAmountOperator','INT'),-1),
	T.c.value('@PurchaseOrderAmountValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PaidDateOperator','INT'),-1),
	T.c.value('@PaidDateValue','datetime') ,
	ISNULL(T.c.value('@MemberNumberOperator','INT'),-1),
	T.c.value('@MemberNumberValue','int') ,
	ISNULL(T.c.value('@ServiceRequestIDOperator','INT'),-1),
	T.c.value('@ServiceRequestIDValue','int')  
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)
INSERT INTO #FinalResults1
SELECT PO.ID
	 , PO.PurchaseOrderNumber
	 , ISNULL(CONVERT(NVARCHAR(10),PO.IssueDate,101),'') AS IssueDate
	 , ISNULL(REPLACE(RTRIM(
		COALESCE(PO.BillingAddressLine1, '') + 
	 	COALESCE(PO.BillingAddressLine2, '') +     
		COALESCE(PO.BillingAddressLine3, '') +     
		COALESCE(', ' + PO.BillingAddressCity, '') +
		COALESCE(', ' + RTRIM(PO.BillingAddressStateProvince), '') +
		COALESCE(' ' + PO.BillingAddressPostalCode, '') +
		COALESCE(' ' + PO.BillingAddressCountryCode, '') 
		), '  ', ' ')
	  ,'') AS [Address]
	 , ISNULL(REPLACE(RTRIM(
		COALESCE(M.FirstName, '') +
		COALESCE(' ' + M.MiddleName, '') +
		COALESCE(' ' + M.LastName, '') +
		COALESCE(' ' + M.Suffix, '') 
	    ), '  ', ' ' )
	  ,'') AS [MemberName] 
	 , PO.CreateBy
	 , POS.Name AS [Status]
	 , P.Name AS [Service]
	 , PO.PurchaseOrderAmount
	 , '01/01/2000' AS PaidDate --- WHere do we get this?	 
	 , M.MembershipID AS MemberNumber
	 , SR.ID AS ServiceRequestID
FROM PurchaseOrder PO
LEFT OUTER JOIN	VendorLocation VL 
				ON VL.ID = PO.VendorLocationID
LEFT OUTER JOIN	Vendor V
				ON V.ID = VL.VendorID
LEFT OUTER JOIN	ServiceRequest SR
				ON SR.ID = PO.ServiceRequestID
LEFT OUTER JOIN	[Case] C 
				ON C.ID = SR.CaseID
LEFT OUTER JOIN	Member M
				ON M.ID = C.MemberID
LEFT OUTER JOIN	PurchaseOrderStatus POS
				ON POS.ID = PO.PurchaseOrderStatusID
LEFT OUTER JOIN	Product P            -- Really need to verify through PODetail
				ON P.ID = PO.ProductID
				
WHERE		PO.IsActive = 1
AND			V.ID = @VendorID
ORDER BY	PO.PurchaseOrderNumber DESC
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.PurchaseOrderNumber,
	T.IssueDate,
	T.Address,
	T.MemberName,
	T.CreateBy,
	T.Status,
	T.Service,
	T.PurchaseOrderAmount,
	T.PaidDate,
	T.MemberNumber,
	T.ServiceRequestID
FROM  #FinalResults1 T,
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
	 ( TMP.PurchaseOrderNumberOperator = -1 ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 0 AND T.PurchaseOrderNumber IS NULL ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 1 AND T.PurchaseOrderNumber IS NOT NULL ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 2 AND T.PurchaseOrderNumber = TMP.PurchaseOrderNumberValue ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 3 AND T.PurchaseOrderNumber <> TMP.PurchaseOrderNumberValue ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 4 AND T.PurchaseOrderNumber LIKE TMP.PurchaseOrderNumberValue + '%') 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 5 AND T.PurchaseOrderNumber LIKE '%' + TMP.PurchaseOrderNumberValue ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 6 AND T.PurchaseOrderNumber LIKE '%' + TMP.PurchaseOrderNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.IssueDateOperator = -1 ) 
 OR 
	 ( TMP.IssueDateOperator = 0 AND T.IssueDate IS NULL ) 
 OR 
	 ( TMP.IssueDateOperator = 1 AND T.IssueDate IS NOT NULL ) 
 OR 
	 ( TMP.IssueDateOperator = 2 AND T.IssueDate = TMP.IssueDateValue ) 
 OR 
	 ( TMP.IssueDateOperator = 3 AND T.IssueDate <> TMP.IssueDateValue ) 
 OR 
	 ( TMP.IssueDateOperator = 7 AND T.IssueDate > TMP.IssueDateValue ) 
 OR 
	 ( TMP.IssueDateOperator = 8 AND T.IssueDate >= TMP.IssueDateValue ) 
 OR 
	 ( TMP.IssueDateOperator = 9 AND T.IssueDate < TMP.IssueDateValue ) 
 OR 
	 ( TMP.IssueDateOperator = 10 AND T.IssueDate <= TMP.IssueDateValue ) 

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
	 ( TMP.CreateByOperator = -1 ) 
 OR 
	 ( TMP.CreateByOperator = 0 AND T.CreateBy IS NULL ) 
 OR 
	 ( TMP.CreateByOperator = 1 AND T.CreateBy IS NOT NULL ) 
 OR 
	 ( TMP.CreateByOperator = 2 AND T.CreateBy = TMP.CreateByValue ) 
 OR 
	 ( TMP.CreateByOperator = 3 AND T.CreateBy <> TMP.CreateByValue ) 
 OR 
	 ( TMP.CreateByOperator = 4 AND T.CreateBy LIKE TMP.CreateByValue + '%') 
 OR 
	 ( TMP.CreateByOperator = 5 AND T.CreateBy LIKE '%' + TMP.CreateByValue ) 
 OR 
	 ( TMP.CreateByOperator = 6 AND T.CreateBy LIKE '%' + TMP.CreateByValue + '%' ) 
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
	 ( TMP.ServiceOperator = -1 ) 
 OR 
	 ( TMP.ServiceOperator = 0 AND T.Service IS NULL ) 
 OR 
	 ( TMP.ServiceOperator = 1 AND T.Service IS NOT NULL ) 
 OR 
	 ( TMP.ServiceOperator = 2 AND T.Service = TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 3 AND T.Service <> TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 4 AND T.Service LIKE TMP.ServiceValue + '%') 
 OR 
	 ( TMP.ServiceOperator = 5 AND T.Service LIKE '%' + TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 6 AND T.Service LIKE '%' + TMP.ServiceValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PurchaseOrderAmountOperator = -1 ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 0 AND T.PurchaseOrderAmount IS NULL ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 1 AND T.PurchaseOrderAmount IS NOT NULL ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 2 AND T.PurchaseOrderAmount = TMP.PurchaseOrderAmountValue ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 3 AND T.PurchaseOrderAmount <> TMP.PurchaseOrderAmountValue ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 4 AND T.PurchaseOrderAmount LIKE TMP.PurchaseOrderAmountValue + '%') 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 5 AND T.PurchaseOrderAmount LIKE '%' + TMP.PurchaseOrderAmountValue ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 6 AND T.PurchaseOrderAmount LIKE '%' + TMP.PurchaseOrderAmountValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PaidDateOperator = -1 ) 
 OR 
	 ( TMP.PaidDateOperator = 0 AND T.PaidDate IS NULL ) 
 OR 
	 ( TMP.PaidDateOperator = 1 AND T.PaidDate IS NOT NULL ) 
 OR 
	 ( TMP.PaidDateOperator = 2 AND T.PaidDate = TMP.PaidDateValue ) 
 OR 
	 ( TMP.PaidDateOperator = 3 AND T.PaidDate <> TMP.PaidDateValue ) 
 OR 
	 ( TMP.PaidDateOperator = 7 AND T.PaidDate > TMP.PaidDateValue ) 
 OR 
	 ( TMP.PaidDateOperator = 8 AND T.PaidDate >= TMP.PaidDateValue ) 
 OR 
	 ( TMP.PaidDateOperator = 9 AND T.PaidDate < TMP.PaidDateValue ) 
 OR 
	 ( TMP.PaidDateOperator = 10 AND T.PaidDate <= TMP.PaidDateValue ) 

 ) 
 
 AND 

 ( 
	 ( TMP.MemberNumberOperator = -1 ) 
 OR 
	 ( TMP.MemberNumberOperator = 0 AND T.MemberNumber IS NULL ) 
 OR 
	 ( TMP.MemberNumberOperator = 1 AND T.MemberNumber IS NOT NULL ) 
 OR 
	 ( TMP.MemberNumberOperator = 2 AND T.MemberNumber = TMP.MemberNumberValue ) 
 OR 
	 ( TMP.MemberNumberOperator = 3 AND T.MemberNumber <> TMP.MemberNumberValue ) 
 OR 
	 ( TMP.MemberNumberOperator = 7 AND T.MemberNumber > TMP.MemberNumberValue ) 
 OR 
	 ( TMP.MemberNumberOperator = 8 AND T.MemberNumber >= TMP.MemberNumberValue ) 
 OR 
	 ( TMP.MemberNumberOperator = 9 AND T.MemberNumber < TMP.MemberNumberValue ) 
 OR 
	 ( TMP.MemberNumberOperator = 10 AND T.MemberNumber <= TMP.MemberNumberValue ) 

 ) 
 
 AND 

 ( 
	 ( TMP.ServiceRequestIDOperator = -1 ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 0 AND T.ServiceRequestID IS NULL ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 1 AND T.ServiceRequestID IS NOT NULL ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 2 AND T.ServiceRequestID = TMP.ServiceRequestIDValue ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 3 AND T.ServiceRequestID <> TMP.ServiceRequestIDValue ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 7 AND T.ServiceRequestID > TMP.ServiceRequestIDValue ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 8 AND T.ServiceRequestID >= TMP.ServiceRequestIDValue ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 9 AND T.ServiceRequestID < TMP.ServiceRequestIDValue ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 10 AND T.ServiceRequestID <= TMP.ServiceRequestIDValue ) 

 ) 
 
 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'ASC'
	 THEN T.PurchaseOrderNumber END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'DESC'
	 THEN T.PurchaseOrderNumber END DESC ,

	 CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'ASC'
	 THEN T.IssueDate END ASC, 
	 CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'DESC'
	 THEN T.IssueDate END DESC ,

	 CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'
	 THEN T.Address END ASC, 
	 CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'
	 THEN T.Address END DESC ,

	 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'
	 THEN T.MemberName END ASC, 
	 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'
	 THEN T.MemberName END DESC ,

	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
	 THEN T.CreateBy END ASC, 
	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
	 THEN T.CreateBy END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC ,

	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'ASC'
	 THEN T.Service END ASC, 
	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'DESC'
	 THEN T.Service END DESC ,

	 CASE WHEN @sortColumn = 'PurchaseOrderAmount' AND @sortOrder = 'ASC'
	 THEN T.PurchaseOrderAmount END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderAmount' AND @sortOrder = 'DESC'
	 THEN T.PurchaseOrderAmount END DESC ,

	 CASE WHEN @sortColumn = 'PaidDate' AND @sortOrder = 'ASC'
	 THEN T.PaidDate END ASC, 
	 CASE WHEN @sortColumn = 'PaidDate' AND @sortOrder = 'DESC'
	 THEN T.PaidDate END DESC ,
	 
	 CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'
	 THEN T.MemberNumber END ASC, 
	 CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'
	 THEN T.MemberNumber END DESC ,

	 CASE WHEN @sortColumn = 'ServiceRequestID' AND @sortOrder = 'ASC'
	 THEN T.ServiceRequestID END ASC, 
	 CASE WHEN @sortColumn = 'ServiceRequestID' AND @sortOrder = 'DESC'
	 THEN T.ServiceRequestID END DESC 



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
DROP TABLE #FinalResults1
END
GO
