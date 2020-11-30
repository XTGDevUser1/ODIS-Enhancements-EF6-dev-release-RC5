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
 WHERE id = object_id(N'[dbo].[dms_Vendor_Invoices_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Invoices_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_Vendor_Invoices_List_Get] @whereClauseXML = '<ROW><Filter IDType="Vendor" IDValue="TX100532" NameValue="" NameOperator="" InvoiceStatuses="" POStatuses="" FromDate="" ToDate="" ExportType="" ToBePaidFromDate="" ToBePaidToDate=""/></ROW>'  
CREATE PROCEDURE [dbo].[dms_Vendor_Invoices_List_Get](     
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
 NameOperator INT NULL,    
 NameValue NVARCHAR(100) NULL,    
 InvoiceStatuses NVARCHAR(MAX) NULL,    
 POStatuses NVARCHAR(MAX) NULL,    
 PayStatusCodes NVARCHAR(MAX) NULL, 
 ExceptionTypes NVARCHAR(MAX) NULL, 
 FromDate DATETIME NULL,    
 ToDate DATETIME NULL,    
 ToBePaidFromDate DATETIME NULL,    
 ToBePaidToDate DATETIME NULL,
 ExportType INT NULL ,  
 filterValue nvarchar(100) NULL      
)    
    
 CREATE TABLE #FinalResults_Filtered(      
 ID int  NULL ,    
 VendorNumber nvarchar(100)  NULL ,    
 VendorName nvarchar(100) NULL,    
 PurchaseOrderNumber nvarchar(100)  NULL ,    
 POStatus nvarchar(100)  NULL ,    
 IssueDate datetime  NULL ,    
 PurchaseOrderAmount money  NULL ,    
 InvoiceNumber nvarchar(100)  NULL ,    
 ReceivedDate datetime  NULL ,    
 InvoiceDate datetime  NULL ,    
 InvoiceAmount money  NULL ,    
 InvoiceStatus nvarchar(100)  NULL ,    
 ToBePaidDate datetime  NULL ,    
 ExportDate datetime  NULL ,    
 PaymentDate datetime  NULL ,    
 PaymentAmount money  NULL ,    
 PaymentType nvarchar(100)  NULL ,    
 PaymentNumber nvarchar(100)  NULL ,    
 CheckClearedDate datetime  NULL ,    
 VendorID int NULL  ,  
 VendorInvoiceException nvarchar(max) NULL ,
RecieveMethod  nvarchar(225) NULL
)     
    
 CREATE TABLE #FinalResults_Sorted (     
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
 ID int  NULL ,    
 VendorNumber nvarchar(100)  NULL ,    
 VendorName nvarchar(100) NULL,    
 PurchaseOrderNumber nvarchar(100)  NULL ,    
 POStatus nvarchar(100)  NULL ,    
 IssueDate datetime  NULL ,    
 PurchaseOrderAmount money  NULL ,    
 InvoiceNumber nvarchar(100)  NULL ,    
 ReceivedDate datetime  NULL ,    
 InvoiceDate datetime  NULL ,    
 InvoiceAmount money  NULL ,    
 InvoiceStatus nvarchar(100)  NULL ,    
 ToBePaidDate datetime  NULL ,    
 ExportDate datetime  NULL ,    
 PaymentDate datetime  NULL ,    
 PaymentAmount money  NULL ,    
 PaymentType nvarchar(100)  NULL ,    
 PaymentNumber nvarchar(100)  NULL ,    
 CheckClearedDate datetime  NULL ,    
 VendorID int NULL ,  
 VendorInvoiceException nvarchar(max) NULL  ,
RecieveMethod  nvarchar(225) NULL
)     

DECLARE @receivedCount BIGINT      
DECLARE @readyForPaymentCount BIGINT      
DECLARE @exceptionCount BIGINT    
DECLARE @paidCount BIGINT    
DECLARE @cancelledCount BIGINT      
SET @receivedCount = 0      
SET @readyForPaymentCount = 0      
SET @exceptionCount = 0    
SET @paidCount = 0    
SET @cancelledCount = 0    
  
INSERT INTO #tmpForWhereClause    
SELECT      
 T.c.value('@IDType','NVARCHAR(50)') ,    
 T.c.value('@IDValue','NVARCHAR(100)'),     
 ISNULL(T.c.value('@NameOperator','INT'),-1),    
 T.c.value('@NameValue','nvarchar(100)') ,    
 T.c.value('@InvoiceStatuses','nvarchar(MAX)') ,    
 T.c.value('@POStatuses','nvarchar(MAX)') ,    
 T.c.value('@PayStatusCodes','nvarchar(MAX)') ,  
 T.c.value('@ExceptionTypes','nvarchar(MAX)') , 
 T.c.value('@FromDate','datetime') ,    
 T.c.value('@ToDate','datetime') ,
 T.c.value('@ToBePaidFromDate','datetime') ,    
 T.c.value('@ToBePaidToDate','datetime') ,    
 T.c.value('@ExportType','INT') ,  
 T.c.value('@filterValue','NVARCHAR(100)') 

FROM @whereClauseXML.nodes('/ROW/Filter') T(c)    
    
    
DECLARE @idType NVARCHAR(50) = NULL,    
  @idValue NVARCHAR(100) = NULL,    
  @nameOperator INT = NULL,    
  @nameValue NVARCHAR(100) = NULL,    
  @invoiceStatuses NVARCHAR(MAX) = NULL,    
  @payStatusCodes NVARCHAR(MAX) = NULL,
  @exceptionTypes NVARCHAR(MAX) = NULL,
  @poStatuses NVARCHAR(MAX) = NULL,    
  @fromDate DATETIME = NULL,    
  @toDate DATETIME = NULL, 
  @toBePaidFromDate DATETIME = NULL,    
  @toBePaidToDate DATETIME = NULL,
  @exportType INT = NULL  ,  
  @filterValue NVARCHAR(100) = NULL  
      
SELECT @idType = IDType,    
  @idValue = IDValue,    
  @nameOperator = NameOperator,    
  @nameValue = NameValue,    
  @invoiceStatuses = InvoiceStatuses,    
  @poStatuses = POStatuses,    
  @payStatusCodes = PayStatusCodes,
  @exceptionTypes = ExceptionTypes,
  @fromDate = FromDate,    
  @toDate = CASE WHEN ToDate = '1900-01-01' THEN NULL ELSE ToDate END,  
  @toBePaidFromDate = ToBePaidFromDate,
  @toBePaidToDate = CASE WHEN ToBePaidToDate = '1900-01-01' THEN NULL ELSE ToBePaidToDate END,  
  @exportType = ExportType ,   
  @filterValue=filterValue  
FROM #tmpForWhereClause    

INSERT INTO #FinalResults_Filtered    
SELECT VI.ID    
  , V.VendorNumber    
  , V.Name AS VendorName    
  , PO.PurchaseOrderNumber    
  , POS.Name AS POStatus    
  , PO.IssueDate    
  , PO.PurchaseOrderAmount    
  , VI.InvoiceNumber    
  , VI.ReceivedDate    
  , VI.InvoiceDate    
  , VI.InvoiceAmount    
  , VIS.Name AS InvoiceStatus    
  , VI.ToBePaidDate    
  , VI.ExportDate    
  , VI.PaymentDate    
  , VI.PaymentAmount    
  --, PT.Name AS PaymentType    
  , CASE    
   WHEN VIS.Name = 'Paid' THEN PT.NAME    
   WHEN ISNULL(VIS.Name,'') <> 'Paid' AND ISNULL(ACH.ID,'') <> '' AND ISNULL(V.IsLevyActive,'') <> 1 THEN 'ACH'    
   ELSE 'Check'    
    END AS PaymentType    
  , VI.PaymentNumber     
  , VI.CheckClearedDate    
  , V.ID AS VendorID    
  , NULL AS VendorInvoiceException
  --, VIE.[Description] AS VendorInvoiceException
  , CM.Name  
FROM VendorInvoice VI    
JOIN VendorInvoiceStatus VIS ON VIS.ID = VI.VendorInvoiceStatusID    
LEFT JOIN PaymentType PT ON PT.ID = VI.PaymentTypeID    
JOIN Vendor V ON V.ID = VI.VendorID    
JOIN PurchaseOrder PO ON PO.ID = VI.PurchaseOrderID    
JOIN PurchaseOrderStatus POS ON POS.ID = PO.PurchaseOrderStatusID    
LEFT JOIN VendorACH ACH ON ACH.VendorID = V.ID AND ACH.ACHStatusID = (SELECT ID FROM ACHStatus WHERE Name = 'Valid') AND ISNULL(ACH.IsActive,0) = 1
LEFT JOIN VendorInvoiceException VIE ON VIE.VendorInvoiceID = VI.ID  
LEFT JOIN Batch B ON VI.ExportBatchID = B.ID
LEFT JOIN ContactMethod CM ON CM.ID=VI.ReceiveContactMethodID
WHERE VI.IsActive = 1    
AND  ( ISNULL(@idType,'') = ''    
   OR    
   (@idType = 'Vendor' AND V.VendorNumber = @idValue )    
   OR    
   (@idType = 'PO' AND PO.PurchaseOrderNumber = @idValue )    
   OR    
   (@idType = 'Invoice' AND VI.InvoiceNumber = @idValue )    
  )    
AND  (    
   ( @nameOperator = -1 )     
    OR     
   ( @nameOperator = 0 AND ISNULL(@nameValue,'') = '' )     
    OR     
   ( @nameOperator = 1 AND @nameValue IS NOT NULL )     
    OR     
   ( @nameOperator = 2 AND V.Name = @nameValue )     
    OR     
   ( @nameOperator = 3 AND V.Name <> @nameValue )     
    OR     
   ( @nameOperator = 4 AND V.Name LIKE @nameValue + '%')     
    OR     
   ( @nameOperator = 5 AND V.Name LIKE '%' + @nameValue )     
    OR     
   ( @nameOperator = 6 AND V.Name LIKE '%' + @nameValue + '%')     
  )  
AND  (    
   ( ISNULL(@invoiceStatuses,'') = '')    
   OR    
   ( VI.VendorInvoiceStatusID IN (    
           SELECT item FROM fnSplitString(@invoiceStatuses,',')    
           ))    
  )    
AND  (    
   ( ISNULL(@poStatuses,'') = '')    
   OR    
   ( PO.PurchaseOrderStatusID IN (    
           SELECT item FROM fnSplitString(@poStatuses,',')    
           ))    
  )    
  AND  (    
   ( ISNULL(@payStatusCodes,'') = '')    
   OR    
   ( PO.PayStatusCodeID IN (    
           SELECT item FROM fnSplitString(@payStatusCodes,',')    
           ))    
  ) 
   AND  (    
   ( ISNULL(@exceptionTypes,'') = '')    
   OR    
   ( VIE.[Description] IN (    
           SELECT item FROM fnSplitString(@exceptionTypes,',')    
           ))    
  ) 
AND  (    
       
   ( @fromDate IS NULL OR (@fromDate IS NOT NULL AND VI.InvoiceDate >= @fromDate))    
    AND    
   ( @toDate IS NULL OR (@toDate IS NOT NULL AND VI.InvoiceDate < DATEADD(DD,1,@toDate)))    
  )
  AND  (    
       
   ( @toBePaidFromDate IS NULL OR (@toBePaidFromDate IS NOT NULL AND VI.ToBePaidDate >= @toBePaidFromDate))    
    AND    
   ( @toBePaidToDate IS NULL OR (@toBePaidToDate IS NOT NULL AND VI.ToBePaidDate < DATEADD(DD,1,@toBePaidToDate)))    
  )    
AND  (    
   ( @filterValue IS NULL OR @filterValue = '')    
   OR    
   ( VIS.Name IN (    
           SELECT item FROM fnSplitString(@filterValue,',')    
           ))    
  )   
 AND ( ISNULL(@exportType,0) = 0 OR B.ID = @exportType )
    
--------------------- BEGIN -----------------------------    
----   Create a temp variable or a CTE with the actual SQL search query ----------    
----   and use that CTE in the place of <table> in the following SQL statements ---    
--------------------- END -----------------------------    

;WITH wExceptions
AS
(
      SELECT      V.VendorInvoiceID,
                  [dbo].[fnConcatenate](V.Description) AS ExceptionMessages
      FROM  VendorInvoiceException V
      JOIN  #FinalResults_Filtered F ON V.VendorInvoiceID = F.ID
      GROUP BY V.VendorInvoiceID
                  
)
--SELECT * FROM wExceptions

INSERT INTO #FinalResults_Sorted    
SELECT     
 T.ID,    
 T.VendorNumber,    
 T.VendorName,    
 T.PurchaseOrderNumber,    
 T.POStatus,    
 T.IssueDate,    
 T.PurchaseOrderAmount,    
 T.InvoiceNumber,    
 T.ReceivedDate,    
 T.InvoiceDate,    
 T.InvoiceAmount,    
 T.InvoiceStatus,    
 T.ToBePaidDate,    
 T.ExportDate,    
 T.PaymentDate,    
 T.PaymentAmount,    
 T.PaymentType,    
 T.PaymentNumber,    
 T.CheckClearedDate,    
 T.VendorID ,  
 W.ExceptionMessages AS VendorInvoiceException,
T.RecieveMethod
FROM #FinalResults_Filtered T    
LEFT OUTER JOIN wExceptions W ON T.ID = W.VendorInvoiceID

 ORDER BY     
  CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'    
  THEN T.ID END ASC,     
  CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'    
  THEN T.ID END DESC ,    
    
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'    
  THEN T.VendorNumber END ASC,     
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'    
  THEN T.VendorNumber END DESC ,    
     
 CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'ASC'    
  THEN T.VendorName END ASC,     
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'DESC'    
  THEN T.VendorName END DESC ,    
    
  CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'ASC'    
  THEN T.PurchaseOrderNumber END ASC,     
  CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'DESC'    
  THEN T.PurchaseOrderNumber END DESC ,    
    
  CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'ASC'    
  THEN T.POStatus END ASC,     
  CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'DESC'    
  THEN T.POStatus END DESC ,    
    
  CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'ASC'    
  THEN T.IssueDate END ASC,     
  CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'DESC'    
  THEN T.IssueDate END DESC ,    
    
  CASE WHEN @sortColumn = 'PurchaseOrderAmount' AND @sortOrder = 'ASC'    
  THEN T.PurchaseOrderAmount END ASC,     
  CASE WHEN @sortColumn = 'PurchaseOrderAmount' AND @sortOrder = 'DESC'    
  THEN T.PurchaseOrderAmount END DESC ,    
    
  CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'    
  THEN T.InvoiceNumber END ASC,     
  CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'    
  THEN T.InvoiceNumber END DESC ,    
    
  CASE WHEN @sortColumn = 'ReceivedDate' AND @sortOrder = 'ASC'    
  THEN T.ReceivedDate END ASC,     
  CASE WHEN @sortColumn = 'ReceivedDate' AND @sortOrder = 'DESC'    
  THEN T.ReceivedDate END DESC ,    
    
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
    
  CASE WHEN @sortColumn = 'ToBePaidDate' AND @sortOrder = 'ASC'    
  THEN T.ToBePaidDate END ASC,     
  CASE WHEN @sortColumn = 'ToBePaidDate' AND @sortOrder = 'DESC'    
  THEN T.ToBePaidDate END DESC ,    
    
  CASE WHEN @sortColumn = 'ExportDate' AND @sortOrder = 'ASC'    
  THEN T.ExportDate END ASC,     
  CASE WHEN @sortColumn = 'ExportDate' AND @sortOrder = 'DESC'    
  THEN T.ExportDate END DESC ,    
    
  CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'ASC'    
  THEN T.PaymentDate END ASC,     
  CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'DESC'    
  THEN T.PaymentDate END DESC ,    
    
  CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'    
  THEN T.PaymentAmount END ASC,     
  CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'    
  THEN T.PaymentAmount END DESC ,    
    
  CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'ASC'    
  THEN T.PaymentType END ASC,     
  CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'DESC'    
  THEN T.PaymentType END DESC ,    
    
  CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'ASC'    
  THEN T.PaymentNumber END ASC,     
  CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'DESC'    
  THEN T.PaymentNumber END DESC ,    
    
  CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'ASC'    
  THEN T.CheckClearedDate END ASC,     
  CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'DESC'    
  THEN T.CheckClearedDate END DESC ,    
      
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'ASC'    
  THEN T.ID END ASC,     
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'DESC'    
  THEN T.ID END DESC     ,    
      
  CASE WHEN @sortColumn = 'RecieveMethod' AND @sortOrder = 'ASC'    
  THEN T.RecieveMethod END ASC,     
  CASE WHEN @sortColumn = 'RecieveMethod' AND @sortOrder = 'DESC'    
  THEN T.RecieveMethod END DESC     
 
    
SELECT @receivedCount = COUNT(*) FROM #FinalResults_Sorted WHERE InvoiceStatus = 'Received'      
SELECT @readyForPaymentCount = COUNT(*) FROM #FinalResults_Sorted WHERE InvoiceStatus = 'ReadyForPayment'      
SELECT @exceptionCount = COUNT(*) FROM #FinalResults_Sorted WHERE InvoiceStatus= 'Exception'    
SELECT @paidCount = COUNT(*) FROM #FinalResults_Sorted WHERE InvoiceStatus= 'Paid'    
SELECT @cancelledCount = COUNT(*) FROM #FinalResults_Sorted WHERE InvoiceStatus= 'Cancelled'    
    
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
 , @receivedCount AS RecivedCount   
 , @readyForPaymentCount AS ReadyForPaymentCount  
 , @exceptionCount AS ExceptionCount  
 , @paidCount AS PaidCount  
 , @cancelledCount AS CancelledCount  
FROM #FinalResults_Sorted WHERE RowNum BETWEEN @startInd AND @endInd    
    
DROP TABLE #tmpForWhereClause    
DROP TABLE #FinalResults_Filtered    
DROP TABLE #FinalResults_Sorted  

    
END
