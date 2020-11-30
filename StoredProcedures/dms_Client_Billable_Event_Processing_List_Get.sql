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
 WHERE id = object_id(N'[dbo].[dms_Client_Billable_Event_Processing_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Client_Billable_Event_Processing_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
  -- EXEC [dms_Client_Billable_Event_Processing_List_Get]
 CREATE PROCEDURE [dbo].[dms_Client_Billable_Event_Processing_List_Get](   
   @whereClauseXML XML = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10    
 , @sortColumn nvarchar(100)  = ''   
 , @sortOrder nvarchar(100) = 'ASC'   
  ,@pMode nvarchar(50)=NULL  
 )   
 AS   
 BEGIN   
 SET FMTONLY OFF  
  SET NOCOUNT ON  
  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter   
BillingInvoiceScheduleTypeIDOperator="-1"   
 ></Filter></ROW>'  
END  
  
--CREATE TABLE #tmpForWhereClause  
DECLARE @tmpForWhereClause TABLE  
(  
BillingScheduleTypeID INT NULL,  
ClientID INT NULL,  
ProgramID INT NULL,  
BillingDefinitionInvoiceID INT NULL,  
BillingEvent INT NULL,  
DetailStatuses NVARCHAR(MAX) NULL,  
DispositionStatuses NVARCHAR(MAX) NULL,  
BillingDefinitionInvoiceLines NVARCHAR(MAX) NULL  
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
 Entity nvarchar(100)  NULL,  
 InvoiceNumber nvarchar(7) NULL,  
 BillingInvoiceStatus  nvarchar(50) NULL  
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
 ExcludedBy nvarchar(100)  NULL ,  
 Entity nvarchar(100)  NULL,  
 InvoiceNumber nvarchar(7) NULL,  
 BillingInvoiceStatus  nvarchar(50) NULL   
)   
INSERT INTO @tmpForWhereClause  
SELECT    
  T.c.value('@BillingScheduleTypeID','int'),  
  T.c.value('@ClientID','int') ,  
  T.c.value('@ProgramID','int') ,  
  T.c.value('@BillingDefinitionInvoiceID','int') ,  
  T.c.value('@BillingEvent','int') ,  
  T.c.value('@DetailStatuses','NVARCHAR(MAX)'),  
  T.c.value('@DispositionStatuses','NVARCHAR(MAX)'),   
  T.c.value('@BillingDefinitionInvoiceLines','NVARCHAR(MAX)')   
      
    
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)  
  
DECLARE @BillingScheduleTypeID INT ,  
@ClientID INT ,  
@ProgramID INT ,  
@BillingDefinitionInvoiceID INT ,  
@BillingEvent INT ,  
@DetailStatuses NVARCHAR(MAX) ,  
@DispositionStatuses NVARCHAR(MAX),  
@BillingDefinitionInvoiceLines NVARCHAR(MAX)  
  
SELECT @BillingScheduleTypeID = T.BillingScheduleTypeID ,  
  @ClientID = T.ClientID ,  
  @ProgramID = T.ProgramID ,  
  @BillingDefinitionInvoiceID = T.BillingDefinitionInvoiceID ,  
  @BillingEvent = T.BillingEvent,  
  @DetailStatuses = T.DetailStatuses ,  
  @DispositionStatuses = T.DispositionStatuses,  
  @BillingDefinitionInvoiceLines = T.BillingDefinitionInvoiceLines  
FROM @tmpForWhereClause T  
  
--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
INSERT INTO #tmpFinalResults  
select bd.ID as BillingInvoiceDetailID,  
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
  bar.Name as AdjustmentReason,  
  bd.AdjustmentDate,  
  bd.AdjustedBy,  
  bd.EntityKey As SourceRecordNumber,  
  --case   
  --when (select Name from Entity with (nolock) where ID = EntityID) = 'PurchaseOrder' then po.PurchaseOrderNumber  
  --else EntityKey  
  --end as SourceRecordNumber ,  
  bt.ID as BillingInvoiceScheduleTypeID,  
  bd.EventAmount,  
  bd.RateTypeName,    
  ber.Name as ExcludedReason,  
  bd.ExcludeDate,  
  bd.ExcludedBy,  
  (select Name from Entity with (nolock) where ID = EntityID) as Entity,  
  bi.InvoiceNumber,  
  bis.Name  
from BillingInvoiceDetail bd  
left outer join BillingInvoiceLine bil with (nolock) on bil.ID = bd.BillingInvoiceLineID  
left outer join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
left outer join BillingInvoiceStatus bis with (nolock) on bis.ID = bi.InvoiceStatusID  
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
--left outer join PurchaseOrder po with (nolock) on po.ID = bd.EntityKey and EntityID = (select ID from Entity with (nolock) where Name = 'PurchaseOrder')  
where bd.AccountingInvoiceBatchID is null  
AND (@pMode IS NULL OR bids.Name = @pMode)  
AND (@BillingScheduleTypeID IS NULL OR @BillingScheduleTypeID = bs.ScheduleTypeID)  
AND (@ClientID IS NULL OR @ClientID = cl.ID)  
AND (@ProgramID IS NULL OR @ProgramID = bd.ProgramID)  
AND (@BillingDefinitionInvoiceID IS NULL OR @BillingDefinitionInvoiceID = bdi.ID)  
AND (@BillingEvent IS NULL OR @BillingEvent = bde.ID)  
AND (@DetailStatuses IS NULL OR bids.ID IN (SELECT item FROM fnSplitString(@DetailStatuses,',') ))  
AND (@DispositionStatuses IS NULL OR bidd.ID IN (SELECT item FROM fnSplitString(@DispositionStatuses,',') ))  
AND (@BillingDefinitionInvoiceLines IS NULL OR bdil.ID IN (SELECT item FROM fnSplitString(@BillingDefinitionInvoiceLines,',') ))  
--order by  
--  bdi.ID,  
--  bdil.Sequence,  
--  bd.ID  
    
    
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
 T.AdjustmentReason,  
 T.AdjustmentDate,  
 T.AdjustedBy,  
 T.SourceRecordNumber,  
 T.BillingInvoiceScheduleTypeID,  
 T.EventAmount,  
 T.RateTypeName,  
 T.ExcludedReason,  
 T.ExcludeDate,  
 T.ExcludedBy,  
 T.Entity,  
 T.InvoiceNumber,  
T.BillingInvoiceStatus  
FROM #tmpFinalResults T  
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
  
  CASE WHEN @sortColumn = 'Client' AND @sortOrder = 'ASC'  
  THEN T.Client END ASC,   
  CASE WHEN @sortColumn = 'Client' AND @sortOrder = 'DESC'  
  THEN T.Client END DESC ,  
  
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
  THEN T.Entity END DESC   
  
  
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
