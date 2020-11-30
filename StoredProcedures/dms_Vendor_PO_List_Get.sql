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
*  ---- for int, money, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_PO_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_PO_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
  -- EXEC [dms_Vendor_PO_List_Get] @VendorID =316
 CREATE PROCEDURE [dbo].[dms_Vendor_PO_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @VendorID INT = null
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
ServiceRequestIDOperator="-1" 
PurchaseOrderNumberOperator="-1" 
IssueDateOperator="-1" 
PurchaseOrderAmountOperator="-1" 
StatusOperator="-1" 
ServiceOperator="-1" 
CreateByOperator="-1" 
MemberNameOperator="-1" 
MemberNumberOperator="-1" 
AddressOperator="-1" 
InvoiceNumberOperator="-1" 
InvoiceDateOperator="-1" 
InvoiceAmountOperator="-1" 
InvoiceStatusOperator="-1" 
PaymentNumberOperator="-1" 
PaidDateOperator="-1" 
PaymentAmountOperator="-1" 
CheckClearedDateOperator="-1" 
InvoiceReceivedDateOperator="-1"
InvoiceReceiveMethodOperator="-1"
InvoiceToBePaidDateOperator="-1"
PaymentTypeOperator="-1"
PurchaseOrderPayStatusCodeDescOperator="-1"
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
ServiceRequestIDOperator INT NOT NULL,
ServiceRequestIDValue int NULL,
PurchaseOrderNumberOperator INT NOT NULL,
PurchaseOrderNumberValue nvarchar(100) NULL,
IssueDateOperator INT NOT NULL,
IssueDateValue datetime NULL,
PurchaseOrderAmountOperator INT NOT NULL,
PurchaseOrderAmountValue money NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL,
ServiceOperator INT NOT NULL,
ServiceValue nvarchar(100) NULL,
CreateByOperator INT NOT NULL,
CreateByValue nvarchar(100) NULL,
MemberNameOperator INT NOT NULL,
MemberNameValue nvarchar(100) NULL,
MemberNumberOperator INT NOT NULL,
MemberNumberValue int NULL,
AddressOperator INT NOT NULL,
AddressValue nvarchar(1000) NULL,
InvoiceNumberOperator INT NOT NULL,
InvoiceNumberValue nvarchar(100) NULL,
InvoiceDateOperator INT NOT NULL,
InvoiceDateValue datetime NULL,
InvoiceAmountOperator INT NOT NULL,
InvoiceAmountValue money NULL,
InvoiceStatusOperator INT NOT NULL,
InvoiceStatusValue nvarchar(100) NULL,
PaymentNumberOperator INT NOT NULL,
PaymentNumberValue nvarchar(100) NULL,
PaidDateOperator INT NOT NULL,
PaidDateValue datetime NULL,
PaymentAmountOperator INT NOT NULL,
PaymentAmountValue money NULL,
CheckClearedDateOperator INT NOT NULL,
CheckClearedDateValue datetime NULL,
InvoiceReceivedDateOperator INT NOT NULL,
InvoiceReceivedDateValue datetime NULL,
InvoiceReceiveMethodOperator INT NOT NULL,
InvoiceReceiveMethodValue nvarchar(100) NULL,
InvoiceToBePaidDateOperator INT NOT NULL,
InvoiceToBePaidDateValue datetime NULL,
PaymentTypeOperator INT NOT NULL,
PaymentTypeValue nvarchar(100) NULL,
PurchaseOrderPayStatusCodeDescOperator INT NOT NULL,
PurchaseOrderPayStatusCodeDescValue nvarchar(255) NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	ServiceRequestID int  NULL ,
	PurchaseOrderNumber nvarchar(100)  NULL ,
	IssueDate datetime  NULL ,
	PurchaseOrderAmount money  NULL ,
	Status nvarchar(100)  NULL ,
	Service nvarchar(100)  NULL ,
	CreateBy nvarchar(100)  NULL ,
	MemberName nvarchar(100)  NULL ,
	MemberNumber int  NULL ,
	Address nvarchar(1000)  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceDate datetime  NULL ,
	InvoiceAmount money  NULL ,
	InvoiceStatus nvarchar(100)  NULL ,
	PaymentNumber nvarchar(100)  NULL ,
	PaidDate datetime  NULL ,
	PaymentAmount money  NULL ,
	CheckClearedDate datetime  NULL ,
	InvoiceReceivedDate datetime NULL ,
	InvoiceReceiveMethod nvarchar(100) NULL ,
	InvoiceToBePaidDate datetime NULL ,
	PaymentType nvarchar(100) NULL ,
	PurchaseOrderID INT NULL,
	PurchaseOrderPayStatusCodeDesc nvarchar(255) NULL
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	ServiceRequestID int  NULL ,
	PurchaseOrderNumber nvarchar(100)  NULL ,
	IssueDate datetime  NULL ,
	PurchaseOrderAmount money  NULL ,
	Status nvarchar(100)  NULL ,
	Service nvarchar(100)  NULL ,
	CreateBy nvarchar(100)  NULL ,
	MemberName nvarchar(100)  NULL ,
	MemberNumber int  NULL ,
	Address nvarchar(1000)  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceDate datetime  NULL ,
	InvoiceAmount money  NULL ,
	InvoiceStatus nvarchar(100)  NULL ,
	PaymentNumber nvarchar(100)  NULL ,
	PaidDate datetime  NULL ,
	PaymentAmount money  NULL ,
	CheckClearedDate datetime  NULL ,
	InvoiceReceivedDate datetime NULL ,
	InvoiceReceiveMethod nvarchar(100) NULL ,
	InvoiceToBePaidDate datetime NULL ,
	PaymentType nvarchar(100) NULL ,
	PurchaseOrderID INT NULL,
	PurchaseOrderPayStatusCodeDesc nvarchar(255) NULL
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@ServiceRequestIDOperator','INT'),-1),
	T.c.value('@ServiceRequestIDValue','int') ,
	ISNULL(T.c.value('@PurchaseOrderNumberOperator','INT'),-1),
	T.c.value('@PurchaseOrderNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@IssueDateOperator','INT'),-1),
	T.c.value('@IssueDateValue','datetime') ,
	ISNULL(T.c.value('@PurchaseOrderAmountOperator','INT'),-1),
	T.c.value('@PurchaseOrderAmountValue','money') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ServiceOperator','INT'),-1),
	T.c.value('@ServiceValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CreateByOperator','INT'),-1),
	T.c.value('@CreateByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@MemberNameOperator','INT'),-1),
	T.c.value('@MemberNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@MemberNumberOperator','INT'),-1),
	T.c.value('@MemberNumberValue','int') ,
	ISNULL(T.c.value('@AddressOperator','INT'),-1),
	T.c.value('@AddressValue','nvarchar(1000)') ,
	ISNULL(T.c.value('@InvoiceNumberOperator','INT'),-1),
	T.c.value('@InvoiceNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@InvoiceDateOperator','INT'),-1),
	T.c.value('@InvoiceDateValue','datetime') ,
	ISNULL(T.c.value('@InvoiceAmountOperator','INT'),-1),
	T.c.value('@InvoiceAmountValue','money') ,
	ISNULL(T.c.value('@InvoiceStatusOperator','INT'),-1),
	T.c.value('@InvoiceStatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PaymentNumberOperator','INT'),-1),
	T.c.value('@PaymentNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PaidDateOperator','INT'),-1),
	T.c.value('@PaidDateValue','datetime') ,
	ISNULL(T.c.value('@PaymentAmountOperator','INT'),-1),
	T.c.value('@PaymentAmountValue','money') ,
	ISNULL(T.c.value('@CheckClearedDateOperator','INT'),-1),
	T.c.value('@CheckClearedDateValue','datetime') ,
	ISNULL(T.c.value('@InvoiceReceivedDateOperator','INT'),-1),
	T.c.value('@InvoiceReceivedDateValue','datetime') ,
	ISNULL(T.c.value('@InvoiceReceiveMethodOperator','INT'),-1),
	T.c.value('@InvoiceReceiveMethodValue','nvarchar(100)')  ,
	ISNULL(T.c.value('@InvoiceToBePaidDateOperator','INT'),-1),
	T.c.value('@InvoiceToBePaidDateValue','datetime') ,
	ISNULL(T.c.value('@PaymentTypeOperator','INT'),-1),
	T.c.value('@PaymentTypeValue','nvarchar(100)'),
	ISNULL(T.c.value('@PurchaseOrderPayStatusCodeDescOperator','INT'),-1),
	T.c.value('@PurchaseOrderPayStatusCodeDescValue','nvarchar(255)')
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT PO.ID
, SR.ID AS ServiceRequestID
, PO.PurchaseOrderNumber
, ISNULL(CONVERT(NVARCHAR(10),PO.IssueDate,101),'') AS IssueDate
, PO.PurchaseOrderAmount
, POS.Name AS [Status]
, P.Name AS [Service]
, PO.CreateBy 
, ISNULL(REPLACE(RTRIM(
COALESCE(M.FirstName, '') +
COALESCE(' ' + M.MiddleName, '') +
COALESCE(' ' + M.LastName, '') +
COALESCE(' ' + M.Suffix, '') 
), ' ', ' ' )
,'') AS [MemberName] 
, M.MembershipID AS MemberNumber
, ISNULL(REPLACE(RTRIM(
COALESCE(PO.BillingAddressLine1, '') + 
COALESCE(PO.BillingAddressLine2, '') + 
COALESCE(PO.BillingAddressLine3, '') + 
COALESCE(', ' + PO.BillingAddressCity, '') +
COALESCE(', ' + RTRIM(PO.BillingAddressStateProvince), '') +
COALESCE(' ' + PO.BillingAddressPostalCode, '') +
COALESCE(' ' + PO.BillingAddressCountryCode, '') 
), ' ', ' ')
,'') AS [Address]
, VI.InvoiceNumber
, VI.InvoiceDate
, VI.InvoiceAmount
, VIS.Name AS [InvoiceStatus]
, VI.PaymentNumber
, VI.PaymentDate AS [PaidDate]
, VI.PaymentAmount 
, VI.CheckClearedDate
, VI.ReceivedDate
, CM.Name
, VI.ToBePaidDate
, CASE 
WHEN VIS.Name = 'Paid' THEN PT.NAME 
WHEN ISNULL(VIS.Name,'') <> 'Paid' AND ISNULL(ACH.ID,'') <> '' AND ISNULL(V.IsLevyActive,'') <> 1 THEN 'ACH' 
ELSE 'Check' 
END AS PaymentType 
, PO.ID AS PurchaseOrderID
,POSC.Description
FROM PurchaseOrder PO
LEFT OUTER JOIN PurchaseOrderPayStatusCode POSC
	ON POSC.ID = PO.PayStatusCodeID
LEFT OUTER JOIN VendorLocation VL 
	ON VL.ID = PO.VendorLocationID
LEFT OUTER JOIN Vendor V
	ON V.ID = VL.VendorID
LEFT OUTER JOIN ServiceRequest SR
	ON SR.ID = PO.ServiceRequestID
LEFT OUTER JOIN [Case] C 
	ON C.ID = SR.CaseID
LEFT OUTER JOIN Member M
	ON M.ID = C.MemberID
LEFT OUTER JOIN PurchaseOrderStatus POS
	ON POS.ID = PO.PurchaseOrderStatusID
LEFT OUTER JOIN Product P -- Really need to verify through PODetail
	ON P.ID = PO.ProductID
LEFT OUTER JOIN VendorInvoice VI
	ON VI.PurchaseOrderID = PO.ID AND VI.IsActive=1
LEFT OUTER JOIN VendorInvoiceStatus VIS
	ON VIS.ID = VI.VendorInvoiceStatusID 
LEFT OUTER JOIN ContactMethod CM
	ON CM.ID=VI.ReceiveContactMethodID
LEFT OUTER JOIN PaymentType PT 
	ON VI.PaymentTypeID=PT.ID
LEFT OUTER JOIN VendorACH ACH
	ON ACH.VendorID = V.ID AND ACH.IsActive = 1
WHERE PO.IsActive = 1 
--AND VI.IsActive = 1
AND V.ID = @VendorID
AND POS.Name <> 'Pending'
ORDER BY PO.PurchaseOrderNumber DESC


INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.ServiceRequestID,
	T.PurchaseOrderNumber,
	T.IssueDate,
	T.PurchaseOrderAmount,
	T.Status,
	T.Service,
	T.CreateBy,
	T.MemberName,
	T.MemberNumber,
	T.Address,
	T.InvoiceNumber,
	T.InvoiceDate,
	T.InvoiceAmount,
	T.InvoiceStatus,
	T.PaymentNumber,
	T.PaidDate,
	T.PaymentAmount,
	T.CheckClearedDate,	
	T.InvoiceReceivedDate,
	T.InvoiceReceiveMethod,
	T.InvoiceToBePaidDate,
	T.PaymentType,
	T.PurchaseOrderID,
	T.PurchaseOrderPayStatusCodeDesc
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
	 ( TMP.PurchaseOrderAmountOperator = 7 AND T.PurchaseOrderAmount > TMP.PurchaseOrderAmountValue ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 8 AND T.PurchaseOrderAmount >= TMP.PurchaseOrderAmountValue ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 9 AND T.PurchaseOrderAmount < TMP.PurchaseOrderAmountValue ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 10 AND T.PurchaseOrderAmount <= TMP.PurchaseOrderAmountValue ) 

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
	 ( TMP.InvoiceNumberOperator = -1 ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 0 AND T.InvoiceNumber IS NULL ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 1 AND T.InvoiceNumber IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 2 AND T.InvoiceNumber = TMP.InvoiceNumberValue ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 3 AND T.InvoiceNumber <> TMP.InvoiceNumberValue ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 4 AND T.InvoiceNumber LIKE TMP.InvoiceNumberValue + '%') 
 OR 
	 ( TMP.InvoiceNumberOperator = 5 AND T.InvoiceNumber LIKE '%' + TMP.InvoiceNumberValue ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 6 AND T.InvoiceNumber LIKE '%' + TMP.InvoiceNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.InvoiceDateOperator = -1 ) 
 OR 
	 ( TMP.InvoiceDateOperator = 0 AND T.InvoiceDate IS NULL ) 
 OR 
	 ( TMP.InvoiceDateOperator = 1 AND T.InvoiceDate IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceDateOperator = 2 AND T.InvoiceDate = TMP.InvoiceDateValue ) 
 OR 
	 ( TMP.InvoiceDateOperator = 3 AND T.InvoiceDate <> TMP.InvoiceDateValue ) 
 OR 
	 ( TMP.InvoiceDateOperator = 7 AND T.InvoiceDate > TMP.InvoiceDateValue ) 
 OR 
	 ( TMP.InvoiceDateOperator = 8 AND T.InvoiceDate >= TMP.InvoiceDateValue ) 
 OR 
	 ( TMP.InvoiceDateOperator = 9 AND T.InvoiceDate < TMP.InvoiceDateValue ) 
 OR 
	 ( TMP.InvoiceDateOperator = 10 AND T.InvoiceDate <= TMP.InvoiceDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.InvoiceAmountOperator = -1 ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 0 AND T.InvoiceAmount IS NULL ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 1 AND T.InvoiceAmount IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 2 AND T.InvoiceAmount = TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 3 AND T.InvoiceAmount <> TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 7 AND T.InvoiceAmount > TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 8 AND T.InvoiceAmount >= TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 9 AND T.InvoiceAmount < TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 10 AND T.InvoiceAmount <= TMP.InvoiceAmountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.InvoiceStatusOperator = -1 ) 
 OR 
	 ( TMP.InvoiceStatusOperator = 0 AND T.InvoiceStatus IS NULL ) 
 OR 
	 ( TMP.InvoiceStatusOperator = 1 AND T.InvoiceStatus IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceStatusOperator = 2 AND T.InvoiceStatus = TMP.InvoiceStatusValue ) 
 OR 
	 ( TMP.InvoiceStatusOperator = 3 AND T.InvoiceStatus <> TMP.InvoiceStatusValue ) 
 OR 
	 ( TMP.InvoiceStatusOperator = 4 AND T.InvoiceStatus LIKE TMP.InvoiceStatusValue + '%') 
 OR 
	 ( TMP.InvoiceStatusOperator = 5 AND T.InvoiceStatus LIKE '%' + TMP.InvoiceStatusValue ) 
 OR 
	 ( TMP.InvoiceStatusOperator = 6 AND T.InvoiceStatus LIKE '%' + TMP.InvoiceStatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PaymentNumberOperator = -1 ) 
 OR 
	 ( TMP.PaymentNumberOperator = 0 AND T.PaymentNumber IS NULL ) 
 OR 
	 ( TMP.PaymentNumberOperator = 1 AND T.PaymentNumber IS NOT NULL ) 
 OR 
	 ( TMP.PaymentNumberOperator = 2 AND T.PaymentNumber = TMP.PaymentNumberValue ) 
 OR 
	 ( TMP.PaymentNumberOperator = 3 AND T.PaymentNumber <> TMP.PaymentNumberValue ) 
 OR 
	 ( TMP.PaymentNumberOperator = 4 AND T.PaymentNumber LIKE TMP.PaymentNumberValue + '%') 
 OR 
	 ( TMP.PaymentNumberOperator = 5 AND T.PaymentNumber LIKE '%' + TMP.PaymentNumberValue ) 
 OR 
	 ( TMP.PaymentNumberOperator = 6 AND T.PaymentNumber LIKE '%' + TMP.PaymentNumberValue + '%' ) 
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
	 ( TMP.PaymentAmountOperator = -1 ) 
 OR 
	 ( TMP.PaymentAmountOperator = 0 AND T.PaymentAmount IS NULL ) 
 OR 
	 ( TMP.PaymentAmountOperator = 1 AND T.PaymentAmount IS NOT NULL ) 
 OR 
	 ( TMP.PaymentAmountOperator = 2 AND T.PaymentAmount = TMP.PaymentAmountValue ) 
 OR 
	 ( TMP.PaymentAmountOperator = 3 AND T.PaymentAmount <> TMP.PaymentAmountValue ) 
 OR 
	 ( TMP.PaymentAmountOperator = 7 AND T.PaymentAmount > TMP.PaymentAmountValue ) 
 OR 
	 ( TMP.PaymentAmountOperator = 8 AND T.PaymentAmount >= TMP.PaymentAmountValue ) 
 OR 
	 ( TMP.PaymentAmountOperator = 9 AND T.PaymentAmount < TMP.PaymentAmountValue ) 
 OR 
	 ( TMP.PaymentAmountOperator = 10 AND T.PaymentAmount <= TMP.PaymentAmountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CheckClearedDateOperator = -1 ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 0 AND T.CheckClearedDate IS NULL ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 1 AND T.CheckClearedDate IS NOT NULL ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 2 AND T.CheckClearedDate = TMP.CheckClearedDateValue ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 3 AND T.CheckClearedDate <> TMP.CheckClearedDateValue ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 7 AND T.CheckClearedDate > TMP.CheckClearedDateValue ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 8 AND T.CheckClearedDate >= TMP.CheckClearedDateValue ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 9 AND T.CheckClearedDate < TMP.CheckClearedDateValue ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 10 AND T.CheckClearedDate <= TMP.CheckClearedDateValue ) 

 ) 

AND 

 ( 
	 ( TMP.InvoiceReceivedDateOperator = -1 ) 
 OR 
	 ( TMP.InvoiceReceivedDateOperator = 0 AND T.InvoiceReceivedDate IS NULL ) 
 OR 
	 ( TMP.InvoiceReceivedDateOperator = 1 AND T.InvoiceReceivedDate IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceReceivedDateOperator = 2 AND T.InvoiceReceivedDate = TMP.InvoiceReceivedDateValue ) 
 OR 
	 ( TMP.InvoiceReceivedDateOperator = 3 AND T.InvoiceReceivedDate <> TMP.InvoiceReceivedDateValue ) 
 OR 
	 ( TMP.InvoiceReceivedDateOperator = 7 AND T.InvoiceReceivedDate > TMP.InvoiceReceivedDateValue ) 
 OR 
	 ( TMP.InvoiceReceivedDateOperator = 8 AND T.InvoiceReceivedDate >= TMP.InvoiceReceivedDateValue ) 
 OR 
	 ( TMP.InvoiceReceivedDateOperator = 9 AND T.InvoiceReceivedDate < TMP.InvoiceReceivedDateValue ) 
 OR 
	 ( TMP.InvoiceReceivedDateOperator = 10 AND T.InvoiceReceivedDate <= TMP.InvoiceReceivedDateValue ) 

 ) 

AND 

 ( 
	 ( TMP.InvoiceReceiveMethodOperator = -1 ) 
 OR 
	 ( TMP.InvoiceReceiveMethodOperator = 0 AND T.InvoiceReceiveMethod IS NULL ) 
 OR 
	 ( TMP.InvoiceReceiveMethodOperator = 1 AND T.InvoiceReceiveMethod IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceReceiveMethodOperator = 2 AND T.InvoiceReceiveMethod = TMP.InvoiceReceiveMethodValue ) 
 OR 
	 ( TMP.InvoiceReceiveMethodOperator = 3 AND T.InvoiceReceiveMethod <> TMP.InvoiceReceiveMethodValue ) 
 OR 
	 ( TMP.InvoiceReceiveMethodOperator = 4 AND T.InvoiceReceiveMethod LIKE TMP.InvoiceReceiveMethodValue + '%') 
 OR 
	 ( TMP.InvoiceReceiveMethodOperator = 5 AND T.InvoiceReceiveMethod LIKE '%' + TMP.InvoiceReceiveMethodValue ) 
 OR 
	 ( TMP.InvoiceReceiveMethodOperator = 6 AND T.InvoiceReceiveMethod LIKE '%' + TMP.InvoiceReceiveMethodValue + '%' ) 
 ) 

AND 

 ( 
	 ( TMP.InvoiceToBePaidDateOperator = -1 ) 
 OR 
	 ( TMP.InvoiceToBePaidDateOperator = 0 AND T.InvoiceToBePaidDate IS NULL ) 
 OR 
	 ( TMP.InvoiceToBePaidDateOperator = 1 AND T.InvoiceToBePaidDate IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceToBePaidDateOperator = 2 AND T.InvoiceToBePaidDate = TMP.InvoiceToBePaidDateValue ) 
 OR 
	 ( TMP.InvoiceToBePaidDateOperator = 3 AND T.InvoiceToBePaidDate <> TMP.InvoiceToBePaidDateValue ) 
 OR 
	 ( TMP.InvoiceToBePaidDateOperator = 7 AND T.InvoiceToBePaidDate > TMP.InvoiceToBePaidDateValue ) 
 OR 
	 ( TMP.InvoiceToBePaidDateOperator = 8 AND T.InvoiceToBePaidDate >= TMP.InvoiceToBePaidDateValue ) 
 OR 
	 ( TMP.InvoiceToBePaidDateOperator = 9 AND T.InvoiceToBePaidDate < TMP.InvoiceToBePaidDateValue ) 
 OR 
	 ( TMP.InvoiceToBePaidDateOperator = 10 AND T.InvoiceToBePaidDate <= TMP.InvoiceToBePaidDateValue ) 

 ) 

AND 

 ( 
	 ( TMP.PaymentTypeOperator = -1 ) 
 OR 
	 ( TMP.PaymentTypeOperator = 0 AND T.PaymentType IS NULL ) 
 OR 
	 ( TMP.PaymentTypeOperator = 1 AND T.PaymentType IS NOT NULL ) 
 OR 
	 ( TMP.PaymentTypeOperator = 2 AND T.PaymentType = TMP.PaymentTypeValue ) 
 OR 
	 ( TMP.PaymentTypeOperator = 3 AND T.PaymentType <> TMP.PaymentTypeValue ) 
 OR 
	 ( TMP.PaymentTypeOperator = 4 AND T.PaymentType LIKE TMP.PaymentTypeValue + '%') 
 OR 
	 ( TMP.PaymentTypeOperator = 5 AND T.PaymentType LIKE '%' + TMP.PaymentTypeValue ) 
 OR 
	 ( TMP.PaymentTypeOperator = 6 AND T.PaymentType LIKE '%' + TMP.PaymentTypeValue + '%' ) 
 ) 
 AND 

 ( 
	 ( TMP.PurchaseOrderPayStatusCodeDescOperator = -1 ) 
 OR 
	 ( TMP.PurchaseOrderPayStatusCodeDescOperator = 0 AND T.PurchaseOrderPayStatusCodeDesc IS NULL ) 
 OR 
	 ( TMP.PurchaseOrderPayStatusCodeDescOperator = 1 AND T.PurchaseOrderPayStatusCodeDesc IS NOT NULL ) 
 OR 
	 ( TMP.PurchaseOrderPayStatusCodeDescOperator = 2 AND T.PurchaseOrderPayStatusCodeDesc = TMP.PurchaseOrderPayStatusCodeDescValue ) 
 OR 
	 ( TMP.PurchaseOrderPayStatusCodeDescOperator = 3 AND T.PurchaseOrderPayStatusCodeDesc <> TMP.PurchaseOrderPayStatusCodeDescValue ) 
 OR 
	 ( TMP.PurchaseOrderPayStatusCodeDescOperator = 4 AND T.PurchaseOrderPayStatusCodeDesc LIKE TMP.PurchaseOrderPayStatusCodeDescValue + '%') 
 OR 
	 ( TMP.PurchaseOrderPayStatusCodeDescOperator = 5 AND T.PurchaseOrderPayStatusCodeDesc LIKE '%' + TMP.PurchaseOrderPayStatusCodeDescValue ) 
 OR 
	 ( TMP.PurchaseOrderPayStatusCodeDescOperator = 6 AND T.PurchaseOrderPayStatusCodeDesc LIKE '%' + TMP.PurchaseOrderPayStatusCodeDescValue + '%' ) 
 )
 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'ServiceRequestID' AND @sortOrder = 'ASC'
	 THEN T.ServiceRequestID END ASC, 
	 CASE WHEN @sortColumn = 'ServiceRequestID' AND @sortOrder = 'DESC'
	 THEN T.ServiceRequestID END DESC ,

	 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'ASC'
	 THEN T.PurchaseOrderNumber END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'DESC'
	 THEN T.PurchaseOrderNumber END DESC ,

	 CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'ASC'
	 THEN T.IssueDate END ASC, 
	 CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'DESC'
	 THEN T.IssueDate END DESC ,

	 CASE WHEN @sortColumn = 'PurchaseOrderAmount' AND @sortOrder = 'ASC'
	 THEN T.PurchaseOrderAmount END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderAmount' AND @sortOrder = 'DESC'
	 THEN T.PurchaseOrderAmount END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC ,

	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'ASC'
	 THEN T.Service END ASC, 
	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'DESC'
	 THEN T.Service END DESC ,

	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
	 THEN T.CreateBy END ASC, 
	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
	 THEN T.CreateBy END DESC ,

	 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'
	 THEN T.MemberName END ASC, 
	 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'
	 THEN T.MemberName END DESC ,

	 CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'
	 THEN T.MemberNumber END ASC, 
	 CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'
	 THEN T.MemberNumber END DESC ,

	 CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'
	 THEN T.Address END ASC, 
	 CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'
	 THEN T.Address END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN T.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN T.InvoiceNumber END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'ASC'
	 THEN T.InvoiceDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'DESC'
	 THEN T.InvoiceDate END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'
	 THEN T.InvoiceAmount END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'
	 THEN T.InvoiceAmount END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'ASC'
	 THEN T.InvoiceStatus END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'DESC'
	 THEN T.InvoiceStatus END DESC ,

	 CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'ASC'
	 THEN T.PaymentNumber END ASC, 
	 CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'DESC'
	 THEN T.PaymentNumber END DESC ,

	 CASE WHEN @sortColumn = 'PaidDate' AND @sortOrder = 'ASC'
	 THEN T.PaidDate END ASC, 
	 CASE WHEN @sortColumn = 'PaidDate' AND @sortOrder = 'DESC'
	 THEN T.PaidDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'
	 THEN T.PaymentAmount END ASC, 
	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'
	 THEN T.PaymentAmount END DESC ,

	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'ASC'
	 THEN T.CheckClearedDate END ASC, 
	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'DESC'
	 THEN T.CheckClearedDate END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceReceivedDate' AND @sortOrder = 'ASC'
	 THEN T.InvoiceReceivedDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceReceivedDate' AND @sortOrder = 'DESC'
	 THEN T.InvoiceReceivedDate END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceReceiveMethod' AND @sortOrder = 'ASC'
	 THEN T.InvoiceReceiveMethod END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceReceiveMethod' AND @sortOrder = 'DESC'
	 THEN T.InvoiceReceiveMethod END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceToBePaidDate' AND @sortOrder = 'ASC'
	 THEN T.InvoiceToBePaidDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceToBePaidDate' AND @sortOrder = 'DESC'
	 THEN T.InvoiceToBePaidDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'ASC'
	 THEN T.PaymentType END ASC, 
	 CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'DESC'
	 THEN T.PaymentType END DESC,
	 
	 CASE WHEN @sortColumn = 'PurchaseOrderPayStatusCodeDesc' AND @sortOrder = 'ASC'
	 THEN T.PurchaseOrderPayStatusCodeDesc END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderPayStatusCodeDesc' AND @sortOrder = 'DESC'
	 THEN T.PurchaseOrderPayStatusCodeDesc END DESC


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
