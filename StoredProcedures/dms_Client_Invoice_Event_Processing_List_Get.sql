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
 WHERE id = object_id(N'[dbo].[dms_Client_Invoice_Event_Processing_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Client_Invoice_Event_Processing_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_Client_Invoice_Event_Processing_List_Get @billingInvoiceLineID =3
 -- EXEC dms_Client_Invoice_Event_Processing_List_Get_NEW @billingInvoiceLineID =48709
 CREATE PROCEDURE [dbo].[dms_Client_Invoice_Event_Processing_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 100  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @billingInvoiceLineID INT 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
BillingInvoiceDetailIDOperator="-1" 
BillingTypeOperator="-1" 
InvoiceDefinitionOperator="-1" 
LineSequenceOperator="-1" 
LineNameOperator="-1" 
ServiceCodeOperator="-1" 
BillingDetailNameOperator="-1" 
QuantityOperator="-1" 
DetailStatusOperator="-1" 
DetailDispositionOperator="-1" 
AdjustmentReasonOperator="-1" 
AdjustmentDateOperator="-1" 
AdjustedByOperator="-1" 
SourceRecordNumberOperator="-1" 
BillingInvoiceScheduleTypeIDOperator="-1" 
EventAmountOperator="-1" 
RateTypeNameOperator="-1" 
ExcludedReasonOperator="-1" 
ExcludeDateOperator="-1" 
ExcludedByOperator="-1" 
EntityOperator="-1" 
ClientOperator="-1" 
InternalCommentOperator="-1" 
PurchaseOrderOperator="-1"
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
BillingInvoiceDetailIDOperator INT NOT NULL,
BillingInvoiceDetailIDValue int NULL,
BillingTypeOperator INT NOT NULL,
BillingTypeValue nvarchar(100) NULL,
InvoiceDefinitionOperator INT NOT NULL,
InvoiceDefinitionValue nvarchar(100) NULL,
LineSequenceOperator INT NOT NULL,
LineSequenceValue int NULL,
LineNameOperator INT NOT NULL,
LineNameValue nvarchar(100) NULL,
ServiceCodeOperator INT NOT NULL,
ServiceCodeValue nvarchar(100) NULL,
BillingDetailNameOperator INT NOT NULL,
BillingDetailNameValue nvarchar(100) NULL,
QuantityOperator INT NOT NULL,
QuantityValue int NULL,
DetailStatusOperator INT NOT NULL,
DetailStatusValue nvarchar(100) NULL,
DetailDispositionOperator INT NOT NULL,
DetailDispositionValue nvarchar(100) NULL,
AdjustmentReasonOperator INT NOT NULL,
AdjustmentReasonValue nvarchar(100) NULL,
AdjustmentDateOperator INT NOT NULL,
AdjustmentDateValue datetime NULL,
AdjustedByOperator INT NOT NULL,
AdjustedByValue nvarchar(100) NULL,
SourceRecordNumberOperator INT NOT NULL,
SourceRecordNumberValue nvarchar(100) NULL,
BillingInvoiceScheduleTypeIDOperator INT NOT NULL,
BillingInvoiceScheduleTypeIDValue int NULL,
EventAmountOperator INT NOT NULL,
EventAmountValue money NULL,
RateTypeNameOperator INT NOT NULL,
RateTypeNameValue nvarchar(100) NULL,
ExcludedReasonOperator INT NOT NULL,
ExcludedReasonValue nvarchar(100) NULL,
ExcludeDateOperator INT NOT NULL,
ExcludeDateValue datetime NULL,
ExcludedByOperator INT NOT NULL,
ExcludedByValue nvarchar(100) NULL,
EntityOperator INT NOT NULL,
EntityValue nvarchar(100) NULL,
ClientOperator INT NOT NULL,
ClientValue nvarchar(100) NULL,
InternalCommentOperator INT NOT NULL,
InternalCommentValue nvarchar(max) NULL,
PurchaseOrderOperator INT NOT NULL,
PurchaseOrderValue nvarchar(100) NULL,
)

CREATE TABLE #FinalResults_filtered( 
	BillingInvoiceDetailID int  NULL ,
	BillingType nvarchar(100)  NULL ,
	InvoiceDefinition nvarchar(100)  NULL ,
	Client nvarchar(100)  NULL ,
	LineSequence int  NULL ,
	LineName nvarchar(100)  NULL ,
	ServiceCode nvarchar(100)  NULL ,
	BillingDetailName nvarchar(100)  NULL ,
	Quantity int  NULL ,
	DetailStatus nvarchar(100)  NULL ,
	DetailDisposition nvarchar(100)  NULL ,
	AdjustmentReason nvarchar(100)  NULL ,
	AdjustmentDate datetime  NULL ,
	AdjustedBy nvarchar(100)  NULL ,
	SourceRecordNumber nvarchar(100)  NULL ,
	BillingInvoiceScheduleTypeID int  NULL ,
	EventAmount money  NULL ,
	RateTypeName nvarchar(100)  NULL ,
	ExcludedReason nvarchar(100)  NULL ,
	ExcludeDate datetime  NULL ,
	ExcludedBy nvarchar(100) NULL,
	Entity NVARCHAR(50) NULL,
	IsAdjusted BIT NULL,
	IsExcluded BIT NULL  ,
	InternalComment nvarchar(max)  NULL ,
	PurchaseOrder nvarchar(100) NULL ,
	ExceptionMessage nvarchar(max)  NULL 
) 
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	BillingInvoiceDetailID int  NULL ,
	BillingType nvarchar(100)  NULL ,
	InvoiceDefinition nvarchar(100)  NULL ,
	Client nvarchar(100)  NULL ,
	LineSequence int  NULL ,
	LineName nvarchar(100)  NULL ,
	ServiceCode nvarchar(100)  NULL ,
	BillingDetailName nvarchar(100)  NULL ,
	Quantity int  NULL ,
	DetailStatus nvarchar(100)  NULL ,
	DetailDisposition nvarchar(100)  NULL ,
	AdjustmentReason nvarchar(100)  NULL ,
	AdjustmentDate datetime  NULL ,
	AdjustedBy nvarchar(100)  NULL ,
	SourceRecordNumber nvarchar(100)  NULL ,
	BillingInvoiceScheduleTypeID int  NULL ,
	EventAmount money  NULL ,
	RateTypeName nvarchar(100)  NULL ,
	ExcludedReason nvarchar(100)  NULL ,
	ExcludeDate datetime  NULL ,
	ExcludedBy nvarchar(100)  NULL ,
	Entity nvarchar(100)  NULL ,
	InternalComment nvarchar(max)  NULL ,
	PurchaseOrder nvarchar(100) NULL ,
	ExceptionMessage nvarchar(max)  NULL 
)  

CREATE TABLE #tmpFinalResults( 
	
	BillingInvoiceDetailID int  NULL ,
	BillingType nvarchar(100)  NULL ,
	InvoiceDefinition nvarchar(100)  NULL ,
	Client nvarchar(100)  NULL ,
	LineSequence int  NULL ,
	LineName nvarchar(100)  NULL ,
	ServiceCode nvarchar(100)  NULL ,
	BillingDetailName nvarchar(100)  NULL ,
	Quantity int  NULL ,
	DetailStatus nvarchar(100)  NULL ,
	DetailDisposition nvarchar(100)  NULL ,
	AdjustmentReason nvarchar(100)  NULL ,
	AdjustmentDate datetime  NULL ,
	AdjustedBy nvarchar(100)  NULL ,
	SourceRecordNumber nvarchar(100)  NULL ,
	BillingInvoiceScheduleTypeID int  NULL ,
	EventAmount money  NULL ,
	RateTypeName nvarchar(100)  NULL ,
	ExcludedReason nvarchar(100)  NULL ,
	ExcludeDate datetime  NULL ,
	ExcludedBy nvarchar(100) NULL,
	Entity NVARCHAR(50) NULL,
	IsAdjusted BIT NULL,
	IsExcluded BIT NULL  ,
	InternalComment nvarchar(max)  NULL ,
	PurchaseOrder nvarchar(100) NULL ,
	ExceptionMessage nvarchar(max)  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@BillingInvoiceDetailIDOperator','INT'),-1),
	T.c.value('@BillingInvoiceDetailIDValue','int') ,
	ISNULL(T.c.value('@BillingTypeOperator','INT'),-1),
	T.c.value('@BillingTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@InvoiceDefinitionOperator','INT'),-1),
	T.c.value('@InvoiceDefinitionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@LineSequenceOperator','INT'),-1),
	T.c.value('@LineSequenceValue','int') ,
	ISNULL(T.c.value('@LineNameOperator','INT'),-1),
	T.c.value('@LineNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ServiceCodeOperator','INT'),-1),
	T.c.value('@ServiceCodeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@BillingDetailNameOperator','INT'),-1),
	T.c.value('@BillingDetailNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@QuantityOperator','INT'),-1),
	T.c.value('@QuantityValue','int') ,
	ISNULL(T.c.value('@DetailStatusOperator','INT'),-1),
	T.c.value('@DetailStatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DetailDispositionOperator','INT'),-1),
	T.c.value('@DetailDispositionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@AdjustmentReasonOperator','INT'),-1),
	T.c.value('@AdjustmentReasonValue','nvarchar(100)') ,
	ISNULL(T.c.value('@AdjustmentDateOperator','INT'),-1),
	T.c.value('@AdjustmentDateValue','datetime') ,
	ISNULL(T.c.value('@AdjustedByOperator','INT'),-1),
	T.c.value('@AdjustedByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@SourceRecordNumberOperator','INT'),-1),
	T.c.value('@SourceRecordNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@BillingInvoiceScheduleTypeIDOperator','INT'),-1),
	T.c.value('@BillingInvoiceScheduleTypeIDValue','int') ,
	ISNULL(T.c.value('@EventAmountOperator','INT'),-1),
	T.c.value('@EventAmountValue','money') ,
	ISNULL(T.c.value('@RateTypeNameOperator','INT'),-1),
	T.c.value('@RateTypeNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ExcludedReasonOperator','INT'),-1),
	T.c.value('@ExcludedReasonValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ExcludeDateOperator','INT'),-1),
	T.c.value('@ExcludeDateValue','datetime') ,
	ISNULL(T.c.value('@ExcludedByOperator','INT'),-1),
	T.c.value('@ExcludedByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@EntityOperator','INT'),-1),
	T.c.value('@EntityValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ClientOperator','INT'),-1),
	T.c.value('@ClientValue','nvarchar(100)')  ,
	ISNULL(T.c.value('@InternalCommentOperator','INT'),-1),
	T.c.value('@InternalCommentValue','nvarchar(max)') ,
	ISNULL(T.c.value('@PurchaseOrderOperator','INT'),-1),
	T.c.value('@PurchaseOrderValue','nvarchar(100)')
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
select	bd.ID as BillingInvoiceDetailID,
		bt.Name as BillingType,
		bdi.[Name] as InvoiceDefinition,
		cl.Name as Client,
		bdil.Sequence as LineSequence,
		bdil.Name as LineName,
		bd.ServiceCode,
		bd.Name as BillingDetailName,
		bd.Quantity,
		bids.Name as DetailStatus,
		bidd.Name as DetailDisposition,
		bar.[Description] as AdjustmentReason,
		bd.AdjustmentDate,
		bd.AdjustedBy,
		bd.EntityKey AS SourceRecordNumber,
		--case 
		--when (select Name from Entity with (nolock) where ID = EntityID) = 'PurchaseOrder' then po.PurchaseOrderNumber
		--else EntityKey
		--end as SourceRecordNumber ,
		bt.ID as BillingInvoiceScheduleTypeID,
		bd.EventAmount,
		bd.RateTypeName,  
		ber.Description as ExcludedReason,
		bd.ExcludeDate,
		bd.ExcludedBy,
		(select Name from Entity with (nolock) where ID = EntityID) as Entity,
		bd.IsAdjusted,
		bd.IsExcluded,
		bd.InternalComment,
		Case bd.EntityID
			WHEN (select ID from Entity with (nolock) where Name = 'PurchaseOrder')
			THEN (SELECT TOP 1 PurchaseOrderNumber from PurchaseOrder where ID = bd.EntityKey)
			WHEN (Select ID from Entity with (nolock) where Name = 'VendorInvoice')
			THEN (SELECT PurchaseOrderNumber from PurchaseOrder where ID =(SELECT PurchaseOrderID FROM VendorInvoice where ID = bd.EntityKey))
			WHEN (select ID from Entity with (nolock) where Name = 'ServiceRequestAgentTime')
			THEN (SELECT TOP 1 ServiceRequestID from ServiceRequestAgentTime where ID = bd.EntityKey)
			ELSE NULL
		END AS PurchaseOrderNumber,
		--[dbo].[fnConcatenate](bide.InvoiceDetailExceptionComment) AS ExceptionMessage
		'' AS ExceptionMessage
from BillingInvoiceDetail bd
left outer join BillingDefinitionInvoice bdi with (nolock) on bdi.ID = bd.BillingDefinitionInvoiceID
left outer join BillingDefinitionInvoiceLine bdil with (nolock) on bdil.ID = bd.BillingDefinitionInvoiceLineID
left outer join BillingDefinitionEvent bde with (nolock) on bde.ID = bd.BillingDefinitionEventID
left outer join Client cl with (nolock) on cl.ID = bdi.ClientID
left outer join BillingSchedule bs with (nolock) on bs.ID = bd.BillingScheduleID
left outer join BillingScheduleType bt with (nolock) on bt.ID = bs.ScheduleTypeID
left outer join BillingInvoiceDetailStatus bids with (nolock) on bids.ID = bd.InvoiceDetailStatusID
left outer join BillingInvoiceDetailDisposition bidd with (nolock) on bidd.ID = bd.InvoiceDetailDispositionID
left outer join BillingAdjustmentReason bar with (nolock) on bar.ID = bd.AdjustmentReasonID
left outer join BillingExcludeReason ber with (nolock) on ber.ID = bd.ExcludeReasonID
--left outer join BillingInvoiceDetailException bide with (nolock) on bide.BillingInvoiceDetailID = bd.ID
--left outer join PurchaseOrder po with (nolock) on po.ID = bd.EntityKey and EntityID = (select ID from Entity with (nolock) where Name = 'PurchaseOrder')
where bd.BillingInvoiceLineID=@billingInvoiceLineID
--AND bd.AccountingInvoiceBatchID is null
INSERT INTO #FinalResults_filtered
SELECT 
	T.BillingInvoiceDetailID,
	T.BillingType,
	T.InvoiceDefinition,
	T.Client,
	T.LineSequence,
	T.LineName,
	T.ServiceCode,
	T.BillingDetailName,
	T.Quantity,
	T.DetailStatus,
	T.DetailDisposition,
	T.AdjustmentReason ,
	T.AdjustmentDate ,
	T.AdjustedBy ,
	T.SourceRecordNumber,
	T.BillingInvoiceScheduleTypeID,
	T.EventAmount,
	T.RateTypeName,
	T.ExcludedReason ,
	T.ExcludeDate,
	T.ExcludedBy,
	T.Entity,
	T.IsAdjusted,
	T.IsExcluded,
	T.InternalComment,
	T.PurchaseOrder,
	[dbo].[fnConcatenate](bidet.[Description]) AS ExceptionMessage
FROM #tmpFinalResults T
left outer join BillingInvoiceDetailException bide with (nolock) on bide.BillingInvoiceDetailID = T.BillingInvoiceDetailID
left outer join BillingInvoiceDetailExceptionType bidet with(nolock) on bide.InvoiceDetailExceptionTypeID = bidet.ID 
GROUP BY 
	T.BillingInvoiceDetailID,
	T.BillingType,
	T.InvoiceDefinition,
	T.Client,
	T.LineSequence,
	T.LineName,
	T.ServiceCode,
	T.BillingDetailName,
	T.Quantity,
	T.DetailStatus,
	T.DetailDisposition,
	T.AdjustmentReason ,
	T.AdjustmentDate ,
	T.AdjustedBy ,
	T.SourceRecordNumber,
	T.BillingInvoiceScheduleTypeID,
	T.EventAmount,
	T.RateTypeName,
	T.ExcludedReason ,
	T.ExcludeDate,
	T.ExcludedBy,
	T.Entity,
	T.IsAdjusted,
	T.IsExcluded,
	T.InternalComment,
	T.PurchaseOrder
	
INSERT INTO #FinalResults
SELECT 
	T.BillingInvoiceDetailID,
	T.BillingType,
	T.InvoiceDefinition,
	T.Client,
	T.LineSequence,
	T.LineName,
	T.ServiceCode,
	T.BillingDetailName,
	T.Quantity,
	T.DetailStatus,
	T.DetailDisposition,
	CASE WHEN ISNULL(T.IsAdjusted,0) = 1 THEN T.AdjustmentReason ELSE NULL END AS AdjustmentReason,
	CASE WHEN ISNULL(T.IsAdjusted,0) = 1 THEN T.AdjustmentDate ELSE NULL END AS AdjustmentDate,
	CASE WHEN ISNULL(T.IsAdjusted,0) = 1 THEN T.AdjustedBy ELSE NULL END AS AdjustedBy,
	T.SourceRecordNumber,
	T.BillingInvoiceScheduleTypeID,
	T.EventAmount,
	T.RateTypeName,
	CASE WHEN ISNULL(T.IsExcluded,0) = 1 THEN T.ExcludedReason ELSE NULL END AS ExcludedReason,
	CASE WHEN ISNULL(T.IsExcluded,0) = 1 THEN T.ExcludeDate ELSE NULL END AS ExcludeDate,
	CASE WHEN ISNULL(T.IsExcluded,0) = 1 THEN T.ExcludedBy ELSE NULL END AS ExcludedBy,
	T.Entity,
	T.InternalComment,
	T.PurchaseOrder,
	T.ExceptionMessage
	
FROM #FinalResults_filtered T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.BillingInvoiceDetailIDOperator = -1 ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 0 AND T.BillingInvoiceDetailID IS NULL ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 1 AND T.BillingInvoiceDetailID IS NOT NULL ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 2 AND T.BillingInvoiceDetailID = TMP.BillingInvoiceDetailIDValue ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 3 AND T.BillingInvoiceDetailID <> TMP.BillingInvoiceDetailIDValue ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 7 AND T.BillingInvoiceDetailID > TMP.BillingInvoiceDetailIDValue ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 8 AND T.BillingInvoiceDetailID >= TMP.BillingInvoiceDetailIDValue ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 9 AND T.BillingInvoiceDetailID < TMP.BillingInvoiceDetailIDValue ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 10 AND T.BillingInvoiceDetailID <= TMP.BillingInvoiceDetailIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.BillingTypeOperator = -1 ) 
 OR 
	 ( TMP.BillingTypeOperator = 0 AND T.BillingType IS NULL ) 
 OR 
	 ( TMP.BillingTypeOperator = 1 AND T.BillingType IS NOT NULL ) 
 OR 
	 ( TMP.BillingTypeOperator = 2 AND T.BillingType = TMP.BillingTypeValue ) 
 OR 
	 ( TMP.BillingTypeOperator = 3 AND T.BillingType <> TMP.BillingTypeValue ) 
 OR 
	 ( TMP.BillingTypeOperator = 4 AND T.BillingType LIKE TMP.BillingTypeValue + '%') 
 OR 
	 ( TMP.BillingTypeOperator = 5 AND T.BillingType LIKE '%' + TMP.BillingTypeValue ) 
 OR 
	 ( TMP.BillingTypeOperator = 6 AND T.BillingType LIKE '%' + TMP.BillingTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.InvoiceDefinitionOperator = -1 ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 0 AND T.InvoiceDefinition IS NULL ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 1 AND T.InvoiceDefinition IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 2 AND T.InvoiceDefinition = TMP.InvoiceDefinitionValue ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 3 AND T.InvoiceDefinition <> TMP.InvoiceDefinitionValue ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 4 AND T.InvoiceDefinition LIKE TMP.InvoiceDefinitionValue + '%') 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 5 AND T.InvoiceDefinition LIKE '%' + TMP.InvoiceDefinitionValue ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 6 AND T.InvoiceDefinition LIKE '%' + TMP.InvoiceDefinitionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LineSequenceOperator = -1 ) 
 OR 
	 ( TMP.LineSequenceOperator = 0 AND T.LineSequence IS NULL ) 
 OR 
	 ( TMP.LineSequenceOperator = 1 AND T.LineSequence IS NOT NULL ) 
 OR 
	 ( TMP.LineSequenceOperator = 2 AND T.LineSequence = TMP.LineSequenceValue ) 
 OR 
	 ( TMP.LineSequenceOperator = 3 AND T.LineSequence <> TMP.LineSequenceValue ) 
 OR 
	 ( TMP.LineSequenceOperator = 7 AND T.LineSequence > TMP.LineSequenceValue ) 
 OR 
	 ( TMP.LineSequenceOperator = 8 AND T.LineSequence >= TMP.LineSequenceValue ) 
 OR 
	 ( TMP.LineSequenceOperator = 9 AND T.LineSequence < TMP.LineSequenceValue ) 
 OR 
	 ( TMP.LineSequenceOperator = 10 AND T.LineSequence <= TMP.LineSequenceValue ) 

 ) 

 AND 

 ( 
	 ( TMP.LineNameOperator = -1 ) 
 OR 
	 ( TMP.LineNameOperator = 0 AND T.LineName IS NULL ) 
 OR 
	 ( TMP.LineNameOperator = 1 AND T.LineName IS NOT NULL ) 
 OR 
	 ( TMP.LineNameOperator = 2 AND T.LineName = TMP.LineNameValue ) 
 OR 
	 ( TMP.LineNameOperator = 3 AND T.LineName <> TMP.LineNameValue ) 
 OR 
	 ( TMP.LineNameOperator = 4 AND T.LineName LIKE TMP.LineNameValue + '%') 
 OR 
	 ( TMP.LineNameOperator = 5 AND T.LineName LIKE '%' + TMP.LineNameValue ) 
 OR 
	 ( TMP.LineNameOperator = 6 AND T.LineName LIKE '%' + TMP.LineNameValue + '%' ) 
 ) 
 AND 

 ( 
	 ( TMP.InternalCommentOperator = -1 ) 
 OR 
	 ( TMP.InternalCommentOperator = 0 AND T.InternalComment IS NULL ) 
 OR 
	 ( TMP.InternalCommentOperator = 1 AND T.InternalComment IS NOT NULL ) 
 OR 
	 ( TMP.InternalCommentOperator = 2 AND T.InternalComment = TMP.InternalCommentValue ) 
 OR 
	 ( TMP.InternalCommentOperator = 3 AND T.InternalComment <> TMP.InternalCommentValue ) 
 OR 
	 ( TMP.InternalCommentOperator = 4 AND T.InternalComment LIKE TMP.InternalCommentValue + '%') 
 OR 
	 ( TMP.InternalCommentOperator = 5 AND T.InternalComment LIKE '%' + TMP.InternalCommentValue ) 
 OR 
	 ( TMP.InternalCommentOperator = 6 AND T.InternalComment LIKE '%' + TMP.InternalCommentValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ServiceCodeOperator = -1 ) 
 OR 
	 ( TMP.ServiceCodeOperator = 0 AND T.ServiceCode IS NULL ) 
 OR 
	 ( TMP.ServiceCodeOperator = 1 AND T.ServiceCode IS NOT NULL ) 
 OR 
	 ( TMP.ServiceCodeOperator = 2 AND T.ServiceCode = TMP.ServiceCodeValue ) 
 OR 
	 ( TMP.ServiceCodeOperator = 3 AND T.ServiceCode <> TMP.ServiceCodeValue ) 
 OR 
	 ( TMP.ServiceCodeOperator = 4 AND T.ServiceCode LIKE TMP.ServiceCodeValue + '%') 
 OR 
	 ( TMP.ServiceCodeOperator = 5 AND T.ServiceCode LIKE '%' + TMP.ServiceCodeValue ) 
 OR 
	 ( TMP.ServiceCodeOperator = 6 AND T.ServiceCode LIKE '%' + TMP.ServiceCodeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.BillingDetailNameOperator = -1 ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 0 AND T.BillingDetailName IS NULL ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 1 AND T.BillingDetailName IS NOT NULL ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 2 AND T.BillingDetailName = TMP.BillingDetailNameValue ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 3 AND T.BillingDetailName <> TMP.BillingDetailNameValue ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 4 AND T.BillingDetailName LIKE TMP.BillingDetailNameValue + '%') 
 OR 
	 ( TMP.BillingDetailNameOperator = 5 AND T.BillingDetailName LIKE '%' + TMP.BillingDetailNameValue ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 6 AND T.BillingDetailName LIKE '%' + TMP.BillingDetailNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.QuantityOperator = -1 ) 
 OR 
	 ( TMP.QuantityOperator = 0 AND T.Quantity IS NULL ) 
 OR 
	 ( TMP.QuantityOperator = 1 AND T.Quantity IS NOT NULL ) 
 OR 
	 ( TMP.QuantityOperator = 2 AND T.Quantity = TMP.QuantityValue ) 
 OR 
	 ( TMP.QuantityOperator = 3 AND T.Quantity <> TMP.QuantityValue ) 
 OR 
	 ( TMP.QuantityOperator = 7 AND T.Quantity > TMP.QuantityValue ) 
 OR 
	 ( TMP.QuantityOperator = 8 AND T.Quantity >= TMP.QuantityValue ) 
 OR 
	 ( TMP.QuantityOperator = 9 AND T.Quantity < TMP.QuantityValue ) 
 OR 
	 ( TMP.QuantityOperator = 10 AND T.Quantity <= TMP.QuantityValue ) 

 ) 

 AND 

 ( 
	 ( TMP.DetailStatusOperator = -1 ) 
 OR 
	 ( TMP.DetailStatusOperator = 0 AND T.DetailStatus IS NULL ) 
 OR 
	 ( TMP.DetailStatusOperator = 1 AND T.DetailStatus IS NOT NULL ) 
 OR 
	 ( TMP.DetailStatusOperator = 2 AND T.DetailStatus = TMP.DetailStatusValue ) 
 OR 
	 ( TMP.DetailStatusOperator = 3 AND T.DetailStatus <> TMP.DetailStatusValue ) 
 OR 
	 ( TMP.DetailStatusOperator = 4 AND T.DetailStatus LIKE TMP.DetailStatusValue + '%') 
 OR 
	 ( TMP.DetailStatusOperator = 5 AND T.DetailStatus LIKE '%' + TMP.DetailStatusValue ) 
 OR 
	 ( TMP.DetailStatusOperator = 6 AND T.DetailStatus LIKE '%' + TMP.DetailStatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DetailDispositionOperator = -1 ) 
 OR 
	 ( TMP.DetailDispositionOperator = 0 AND T.DetailDisposition IS NULL ) 
 OR 
	 ( TMP.DetailDispositionOperator = 1 AND T.DetailDisposition IS NOT NULL ) 
 OR 
	 ( TMP.DetailDispositionOperator = 2 AND T.DetailDisposition = TMP.DetailDispositionValue ) 
 OR 
	 ( TMP.DetailDispositionOperator = 3 AND T.DetailDisposition <> TMP.DetailDispositionValue ) 
 OR 
	 ( TMP.DetailDispositionOperator = 4 AND T.DetailDisposition LIKE TMP.DetailDispositionValue + '%') 
 OR 
	 ( TMP.DetailDispositionOperator = 5 AND T.DetailDisposition LIKE '%' + TMP.DetailDispositionValue ) 
 OR 
	 ( TMP.DetailDispositionOperator = 6 AND T.DetailDisposition LIKE '%' + TMP.DetailDispositionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.AdjustmentReasonOperator = -1 ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 0 AND T.AdjustmentReason IS NULL ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 1 AND T.AdjustmentReason IS NOT NULL ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 2 AND T.AdjustmentReason = TMP.AdjustmentReasonValue ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 3 AND T.AdjustmentReason <> TMP.AdjustmentReasonValue ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 4 AND T.AdjustmentReason LIKE TMP.AdjustmentReasonValue + '%') 
 OR 
	 ( TMP.AdjustmentReasonOperator = 5 AND T.AdjustmentReason LIKE '%' + TMP.AdjustmentReasonValue ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 6 AND T.AdjustmentReason LIKE '%' + TMP.AdjustmentReasonValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.AdjustmentDateOperator = -1 ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 0 AND T.AdjustmentDate IS NULL ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 1 AND T.AdjustmentDate IS NOT NULL ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 2 AND T.AdjustmentDate = TMP.AdjustmentDateValue ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 3 AND T.AdjustmentDate <> TMP.AdjustmentDateValue ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 7 AND T.AdjustmentDate > TMP.AdjustmentDateValue ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 8 AND T.AdjustmentDate >= TMP.AdjustmentDateValue ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 9 AND T.AdjustmentDate < TMP.AdjustmentDateValue ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 10 AND T.AdjustmentDate <= TMP.AdjustmentDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.AdjustedByOperator = -1 ) 
 OR 
	 ( TMP.AdjustedByOperator = 0 AND T.AdjustedBy IS NULL ) 
 OR 
	 ( TMP.AdjustedByOperator = 1 AND T.AdjustedBy IS NOT NULL ) 
 OR 
	 ( TMP.AdjustedByOperator = 2 AND T.AdjustedBy = TMP.AdjustedByValue ) 
 OR 
	 ( TMP.AdjustedByOperator = 3 AND T.AdjustedBy <> TMP.AdjustedByValue ) 
 OR 
	 ( TMP.AdjustedByOperator = 4 AND T.AdjustedBy LIKE TMP.AdjustedByValue + '%') 
 OR 
	 ( TMP.AdjustedByOperator = 5 AND T.AdjustedBy LIKE '%' + TMP.AdjustedByValue ) 
 OR 
	 ( TMP.AdjustedByOperator = 6 AND T.AdjustedBy LIKE '%' + TMP.AdjustedByValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.SourceRecordNumberOperator = -1 ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 0 AND T.SourceRecordNumber IS NULL ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 1 AND T.SourceRecordNumber IS NOT NULL ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 2 AND T.SourceRecordNumber = TMP.SourceRecordNumberValue ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 3 AND T.SourceRecordNumber <> TMP.SourceRecordNumberValue ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 4 AND T.SourceRecordNumber LIKE TMP.SourceRecordNumberValue + '%') 
 OR 
	 ( TMP.SourceRecordNumberOperator = 5 AND T.SourceRecordNumber LIKE '%' + TMP.SourceRecordNumberValue ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 6 AND T.SourceRecordNumber LIKE '%' + TMP.SourceRecordNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = -1 ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 0 AND T.BillingInvoiceScheduleTypeID IS NULL ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 1 AND T.BillingInvoiceScheduleTypeID IS NOT NULL ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 2 AND T.BillingInvoiceScheduleTypeID = TMP.BillingInvoiceScheduleTypeIDValue ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 3 AND T.BillingInvoiceScheduleTypeID <> TMP.BillingInvoiceScheduleTypeIDValue ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 7 AND T.BillingInvoiceScheduleTypeID > TMP.BillingInvoiceScheduleTypeIDValue ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 8 AND T.BillingInvoiceScheduleTypeID >= TMP.BillingInvoiceScheduleTypeIDValue ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 9 AND T.BillingInvoiceScheduleTypeID < TMP.BillingInvoiceScheduleTypeIDValue ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 10 AND T.BillingInvoiceScheduleTypeID <= TMP.BillingInvoiceScheduleTypeIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.EventAmountOperator = -1 ) 
 OR 
	 ( TMP.EventAmountOperator = 0 AND T.EventAmount IS NULL ) 
 OR 
	 ( TMP.EventAmountOperator = 1 AND T.EventAmount IS NOT NULL ) 
 OR 
	 ( TMP.EventAmountOperator = 2 AND T.EventAmount = TMP.EventAmountValue ) 
 OR 
	 ( TMP.EventAmountOperator = 3 AND T.EventAmount <> TMP.EventAmountValue ) 
 OR 
	 ( TMP.EventAmountOperator = 7 AND T.EventAmount > TMP.EventAmountValue ) 
 OR 
	 ( TMP.EventAmountOperator = 8 AND T.EventAmount >= TMP.EventAmountValue ) 
 OR 
	 ( TMP.EventAmountOperator = 9 AND T.EventAmount < TMP.EventAmountValue ) 
 OR 
	 ( TMP.EventAmountOperator = 10 AND T.EventAmount <= TMP.EventAmountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.RateTypeNameOperator = -1 ) 
 OR 
	 ( TMP.RateTypeNameOperator = 0 AND T.RateTypeName IS NULL ) 
 OR 
	 ( TMP.RateTypeNameOperator = 1 AND T.RateTypeName IS NOT NULL ) 
 OR 
	 ( TMP.RateTypeNameOperator = 2 AND T.RateTypeName = TMP.RateTypeNameValue ) 
 OR 
	 ( TMP.RateTypeNameOperator = 3 AND T.RateTypeName <> TMP.RateTypeNameValue ) 
 OR 
	 ( TMP.RateTypeNameOperator = 4 AND T.RateTypeName LIKE TMP.RateTypeNameValue + '%') 
 OR 
	 ( TMP.RateTypeNameOperator = 5 AND T.RateTypeName LIKE '%' + TMP.RateTypeNameValue ) 
 OR 
	 ( TMP.RateTypeNameOperator = 6 AND T.RateTypeName LIKE '%' + TMP.RateTypeNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ExcludedReasonOperator = -1 ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 0 AND T.ExcludedReason IS NULL ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 1 AND T.ExcludedReason IS NOT NULL ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 2 AND T.ExcludedReason = TMP.ExcludedReasonValue ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 3 AND T.ExcludedReason <> TMP.ExcludedReasonValue ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 4 AND T.ExcludedReason LIKE TMP.ExcludedReasonValue + '%') 
 OR 
	 ( TMP.ExcludedReasonOperator = 5 AND T.ExcludedReason LIKE '%' + TMP.ExcludedReasonValue ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 6 AND T.ExcludedReason LIKE '%' + TMP.ExcludedReasonValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ExcludeDateOperator = -1 ) 
 OR 
	 ( TMP.ExcludeDateOperator = 0 AND T.ExcludeDate IS NULL ) 
 OR 
	 ( TMP.ExcludeDateOperator = 1 AND T.ExcludeDate IS NOT NULL ) 
 OR 
	 ( TMP.ExcludeDateOperator = 2 AND T.ExcludeDate = TMP.ExcludeDateValue ) 
 OR 
	 ( TMP.ExcludeDateOperator = 3 AND T.ExcludeDate <> TMP.ExcludeDateValue ) 
 OR 
	 ( TMP.ExcludeDateOperator = 7 AND T.ExcludeDate > TMP.ExcludeDateValue ) 
 OR 
	 ( TMP.ExcludeDateOperator = 8 AND T.ExcludeDate >= TMP.ExcludeDateValue ) 
 OR 
	 ( TMP.ExcludeDateOperator = 9 AND T.ExcludeDate < TMP.ExcludeDateValue ) 
 OR 
	 ( TMP.ExcludeDateOperator = 10 AND T.ExcludeDate <= TMP.ExcludeDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ExcludedByOperator = -1 ) 
 OR 
	 ( TMP.ExcludedByOperator = 0 AND T.ExcludedBy IS NULL ) 
 OR 
	 ( TMP.ExcludedByOperator = 1 AND T.ExcludedBy IS NOT NULL ) 
 OR 
	 ( TMP.ExcludedByOperator = 2 AND T.ExcludedBy = TMP.ExcludedByValue ) 
 OR 
	 ( TMP.ExcludedByOperator = 3 AND T.ExcludedBy <> TMP.ExcludedByValue ) 
 OR 
	 ( TMP.ExcludedByOperator = 4 AND T.ExcludedBy LIKE TMP.ExcludedByValue + '%') 
 OR 
	 ( TMP.ExcludedByOperator = 5 AND T.ExcludedBy LIKE '%' + TMP.ExcludedByValue ) 
 OR 
	 ( TMP.ExcludedByOperator = 6 AND T.ExcludedBy LIKE '%' + TMP.ExcludedByValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.EntityOperator = -1 ) 
 OR 
	 ( TMP.EntityOperator = 0 AND T.Entity IS NULL ) 
 OR 
	 ( TMP.EntityOperator = 1 AND T.Entity IS NOT NULL ) 
 OR 
	 ( TMP.EntityOperator = 2 AND T.Entity = TMP.EntityValue ) 
 OR 
	 ( TMP.EntityOperator = 3 AND T.Entity <> TMP.EntityValue ) 
 OR 
	 ( TMP.EntityOperator = 4 AND T.Entity LIKE TMP.EntityValue + '%') 
 OR 
	 ( TMP.EntityOperator = 5 AND T.Entity LIKE '%' + TMP.EntityValue ) 
 OR 
	 ( TMP.EntityOperator = 6 AND T.Entity LIKE '%' + TMP.EntityValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ClientOperator = -1 ) 
 OR 
	 ( TMP.ClientOperator = 0 AND T.Client IS NULL ) 
 OR 
	 ( TMP.ClientOperator = 1 AND T.Client IS NOT NULL ) 
 OR 
	 ( TMP.ClientOperator = 2 AND T.Client = TMP.ClientValue ) 
 OR 
	 ( TMP.ClientOperator = 3 AND T.Client <> TMP.ClientValue ) 
 OR 
	 ( TMP.ClientOperator = 4 AND T.Client LIKE TMP.ClientValue + '%') 
 OR 
	 ( TMP.ClientOperator = 5 AND T.Client LIKE '%' + TMP.ClientValue ) 
 OR 
	 ( TMP.ClientOperator = 6 AND T.Client LIKE '%' + TMP.ClientValue + '%' ) 
 ) 
 
 AND 

 ( 
	 ( TMP.PurchaseOrderOperator = -1 ) 
 OR 
	 ( TMP.PurchaseOrderOperator = 0 AND T.PurchaseOrder IS NULL ) 
 OR 
	 ( TMP.PurchaseOrderOperator = 1 AND T.PurchaseOrder IS NOT NULL ) 
 OR 
	 ( TMP.PurchaseOrderOperator = 2 AND T.PurchaseOrder = TMP.PurchaseOrderValue ) 
 OR 
	 ( TMP.PurchaseOrderOperator = 3 AND T.PurchaseOrder <> TMP.PurchaseOrderValue ) 
 OR 
	 ( TMP.PurchaseOrderOperator = 4 AND T.PurchaseOrder LIKE TMP.PurchaseOrderValue + '%') 
 OR 
	 ( TMP.PurchaseOrderOperator = 5 AND T.PurchaseOrder LIKE '%' + TMP.PurchaseOrderValue ) 
 OR 
	 ( TMP.PurchaseOrderOperator = 6 AND T.PurchaseOrder LIKE '%' + TMP.PurchaseOrderValue + '%' ) 
 ) 


 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'BillingInvoiceDetailID' AND @sortOrder = 'ASC'
	 THEN T.BillingInvoiceDetailID END ASC, 
	 CASE WHEN @sortColumn = 'BillingInvoiceDetailID' AND @sortOrder = 'DESC'
	 THEN T.BillingInvoiceDetailID END DESC ,

	 CASE WHEN @sortColumn = 'BillingType' AND @sortOrder = 'ASC'
	 THEN T.BillingType END ASC, 
	 CASE WHEN @sortColumn = 'BillingType' AND @sortOrder = 'DESC'
	 THEN T.BillingType END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceDefinition' AND @sortOrder = 'ASC'
	 THEN T.InvoiceDefinition END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDefinition' AND @sortOrder = 'DESC'
	 THEN T.InvoiceDefinition END DESC ,

	 CASE WHEN @sortColumn = 'LineSequence' AND @sortOrder = 'ASC'
	 THEN T.LineSequence END ASC, 
	 CASE WHEN @sortColumn = 'LineSequence' AND @sortOrder = 'DESC'
	 THEN T.LineSequence END DESC ,

	 CASE WHEN @sortColumn = 'LineName' AND @sortOrder = 'ASC'
	 THEN T.LineName END ASC, 
	 CASE WHEN @sortColumn = 'LineName' AND @sortOrder = 'DESC'
	 THEN T.LineName END DESC ,

	 CASE WHEN @sortColumn = 'ServiceCode' AND @sortOrder = 'ASC'
	 THEN T.ServiceCode END ASC, 
	 CASE WHEN @sortColumn = 'ServiceCode' AND @sortOrder = 'DESC'
	 THEN T.ServiceCode END DESC ,

	 CASE WHEN @sortColumn = 'BillingDetailName' AND @sortOrder = 'ASC'
	 THEN T.BillingDetailName END ASC, 
	 CASE WHEN @sortColumn = 'BillingDetailName' AND @sortOrder = 'DESC'
	 THEN T.BillingDetailName END DESC ,

	 CASE WHEN @sortColumn = 'Quantity' AND @sortOrder = 'ASC'
	 THEN T.Quantity END ASC, 
	 CASE WHEN @sortColumn = 'Quantity' AND @sortOrder = 'DESC'
	 THEN T.Quantity END DESC ,

	 CASE WHEN @sortColumn = 'DetailStatus' AND @sortOrder = 'ASC'
	 THEN T.DetailStatus END ASC, 
	 CASE WHEN @sortColumn = 'DetailStatus' AND @sortOrder = 'DESC'
	 THEN T.DetailStatus END DESC ,

	 CASE WHEN @sortColumn = 'DetailDisposition' AND @sortOrder = 'ASC'
	 THEN T.DetailDisposition END ASC, 
	 CASE WHEN @sortColumn = 'DetailDisposition' AND @sortOrder = 'DESC'
	 THEN T.DetailDisposition END DESC ,

	 CASE WHEN @sortColumn = 'AdjustmentReason' AND @sortOrder = 'ASC'
	 THEN T.AdjustmentReason END ASC, 
	 CASE WHEN @sortColumn = 'AdjustmentReason' AND @sortOrder = 'DESC'
	 THEN T.AdjustmentReason END DESC ,

	 CASE WHEN @sortColumn = 'AdjustmentDate' AND @sortOrder = 'ASC'
	 THEN T.AdjustmentDate END ASC, 
	 CASE WHEN @sortColumn = 'AdjustmentDate' AND @sortOrder = 'DESC'
	 THEN T.AdjustmentDate END DESC ,

	 CASE WHEN @sortColumn = 'AdjustedBy' AND @sortOrder = 'ASC'
	 THEN T.AdjustedBy END ASC, 
	 CASE WHEN @sortColumn = 'AdjustedBy' AND @sortOrder = 'DESC'
	 THEN T.AdjustedBy END DESC ,

	 CASE WHEN @sortColumn = 'SourceRecordNumber' AND @sortOrder = 'ASC'
	 THEN T.SourceRecordNumber END ASC, 
	 CASE WHEN @sortColumn = 'SourceRecordNumber' AND @sortOrder = 'DESC'
	 THEN T.SourceRecordNumber END DESC ,

	 CASE WHEN @sortColumn = 'BillingInvoiceScheduleTypeID' AND @sortOrder = 'ASC'
	 THEN T.BillingInvoiceScheduleTypeID END ASC, 
	 CASE WHEN @sortColumn = 'BillingInvoiceScheduleTypeID' AND @sortOrder = 'DESC'
	 THEN T.BillingInvoiceScheduleTypeID END DESC ,

	 CASE WHEN @sortColumn = 'EventAmount' AND @sortOrder = 'ASC'
	 THEN T.EventAmount END ASC, 
	 CASE WHEN @sortColumn = 'EventAmount' AND @sortOrder = 'DESC'
	 THEN T.EventAmount END DESC ,

	 CASE WHEN @sortColumn = 'RateTypeName' AND @sortOrder = 'ASC'
	 THEN T.RateTypeName END ASC, 
	 CASE WHEN @sortColumn = 'RateTypeName' AND @sortOrder = 'DESC'
	 THEN T.RateTypeName END DESC ,

	 CASE WHEN @sortColumn = 'ExcludedReason' AND @sortOrder = 'ASC'
	 THEN T.ExcludedReason END ASC, 
	 CASE WHEN @sortColumn = 'ExcludedReason' AND @sortOrder = 'DESC'
	 THEN T.ExcludedReason END DESC ,

	 CASE WHEN @sortColumn = 'ExcludeDate' AND @sortOrder = 'ASC'
	 THEN T.ExcludeDate END ASC, 
	 CASE WHEN @sortColumn = 'ExcludeDate' AND @sortOrder = 'DESC'
	 THEN T.ExcludeDate END DESC ,

	 CASE WHEN @sortColumn = 'ExcludedBy' AND @sortOrder = 'ASC'
	 THEN T.ExcludedBy END ASC, 
	 CASE WHEN @sortColumn = 'ExcludedBy' AND @sortOrder = 'DESC'
	 THEN T.ExcludedBy END DESC ,

	 CASE WHEN @sortColumn = 'Entity' AND @sortOrder = 'ASC'
	 THEN T.Entity END ASC, 
	 CASE WHEN @sortColumn = 'Entity' AND @sortOrder = 'DESC'
	 THEN T.Entity END DESC ,

	 CASE WHEN @sortColumn = 'Client' AND @sortOrder = 'ASC'
	 THEN T.Client END ASC, 
	 CASE WHEN @sortColumn = 'Client' AND @sortOrder = 'DESC'
	 THEN T.Client END DESC ,

	 CASE WHEN @sortColumn = 'InternalComment' AND @sortOrder = 'ASC'
	 THEN T.InternalComment END ASC, 
	 CASE WHEN @sortColumn = 'InternalComment' AND @sortOrder = 'DESC'
	 THEN T.InternalComment END DESC 	 ,

	 CASE WHEN @sortColumn = 'PurchaseOrder' AND @sortOrder = 'ASC'
	 THEN T.PurchaseOrder END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrder' AND @sortOrder = 'DESC'
	 THEN T.PurchaseOrder END DESC 


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
DROP TABLE #FinalResults_filtered
END
GO

