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
  -- EXEC dms_BillingManageInvoicesList @pMode= 'OPEN'
 CREATE PROCEDURE [dbo].[dms_BillingManageInvoicesList](   
   @whereClauseXML XML = NULL 
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10    
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
     ScheduleDate VARCHAR(10) NULL,    
     ScheduleRangeBegin VARCHAR(10) NULL,    
     ScheduleRangeEnd VARCHAR(10) NULL,    
     InvoiceNumber nvarchar(7) NULL,    
     InvoiceDate VARCHAR(10) NULL,    
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
     ScheduleDate VARCHAR(10) NULL,    
     ScheduleRangeBegin VARCHAR(10) NULL,    
     ScheduleRangeEnd VARCHAR(10) NULL,    
     InvoiceNumber nvarchar(7) NULL,    
     InvoiceDate VARCHAR(10) NULL,    
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
    ISNULL(CONVERT(VARCHAR(10), BI.ScheduleDate, 1),''),    
    ISNULL(CONVERT(VARCHAR(10), BI.ScheduleRangeBegin, 1),''),    
    ISNULL(CONVERT(VARCHAR(10), BI.ScheduleRangeEnd, 1),''),    
    BI.InvoiceNumber,    
    ISNULL(CONVERT(VARCHAR(10), BI.InvoiceDate, 1),''),    
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
    ISNULL(CONVERT(VARCHAR(10), BI.ScheduleDate, 1),''),    
    ISNULL(CONVERT(VARCHAR(10), BI.ScheduleRangeBegin, 1),''),    
    ISNULL(CONVERT(VARCHAR(10), BI.ScheduleRangeEnd, 1),''),    
    BI.InvoiceNumber,    
    ISNULL(CONVERT(VARCHAR(10), BI.InvoiceDate, 1),''),    
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
  THEN T.ID END DESC     
      
      
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
 WHERE id = object_id(N'[dbo].[dms_Client_Batch_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Client_Batch_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Client_Batch_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = 'CreateDate' 
 , @sortOrder nvarchar(100) = 'DESC' 
  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF;
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 

 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
BatchStatusID int NULL,
FromDate DATETIME NULL,
ToDate DATETIME NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	BatchType nvarchar(100)  NULL ,
	BatchStatusID int  NULL ,
	BatchStatus nvarchar(100)  NULL ,
	TotalCount int  NULL ,
	TotalAmount money  NULL ,
	MasterETLLoadID int  NULL ,
	TransactionETLLoadID int  NULL ,
	CreateDate datetime  NULL ,
	CreateBy nvarchar(100)  NULL ,
	ModifyDate datetime  NULL ,
	ModifyBy nvarchar(100)  NULL ,
	LinesCount INT NULL
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	BatchType nvarchar(100)  NULL ,
	BatchStatusID int  NULL ,
	BatchStatus nvarchar(100)  NULL ,
	TotalCount int  NULL ,
	TotalAmount money  NULL ,
	MasterETLLoadID int  NULL ,
	TransactionETLLoadID int  NULL ,
	CreateDate datetime  NULL ,
	CreateBy nvarchar(100)  NULL ,
	ModifyDate datetime  NULL ,
	ModifyBy nvarchar(100)  NULL ,
	LinesCount INT NULL
) 

INSERT INTO #tmpForWhereClause
SELECT 
	T.c.value('@BatchStatusID','int') ,
	T.c.value('@FromDate','datetime') ,
	T.c.value('@ToDate','datetime') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @batchStatusID NVARCHAR(100) = NULL,
		@fromDate DATETIME = NULL,
		@toDate DATETIME = NULL
		
SELECT	@batchStatusID = BatchStatusID, 
		@fromDate = FromDate,
		@toDate = ToDate
FROM	#tmpForWhereClause

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------


INSERT INTO #tmpFinalResults
SELECT	B.ID
		, BT.[Description] AS BatchType
		, B.BatchStatusID
		, BS.Name AS BatchStatus
		, COUNT(DISTINCT BI.ID) AS TotalCount
		, SUM(ISNULL(BIL.LineAmount,0)) AS TotalAmount
		, B.MasterETLLoadID   
		, B.TransactionETLLoadID
		, B.CreateDate
		, B.CreateBy 
		, B.ModifyDate
		, B.ModifyBy
		, COUNT(BIL.ID) AS LinesCount
FROM	Batch B
JOIN	BatchType BT ON BT.ID = B.BatchTypeID
JOIN	BatchStatus BS ON BS.ID = B.BatchStatusID
--LEFT JOIN	VendorInvoice VI ON VI.ExportBatchID = B.ID
LEFT JOIN	BillingInvoice BI ON BI.AccountingInvoiceBatchID = B.ID
LEFT JOIN	BillingInvoiceLine BIL ON BIL.BillingInvoiceID = BI.ID
WHERE	BT.Name='ClientBillingExport'
AND		(@batchStatusID IS NULL OR @batchStatusID = B.BatchStatusID)
AND		(@fromDate IS NULL OR B.CreateDate > @fromDate)
AND		(@toDate IS NULL OR B.CreateDate < @toDate)

GROUP	BY	B.ID
		, BT.[Description] 
		, B.BatchStatusID
		, BS.Name
		, B.MasterETLLoadID
		, B.TransactionETLLoadID
		, B.CreateDate
		, B.CreateBy
		, B.ModifyDate
		, B.ModifyBy

ORDER BY B.CreateDate DESC


INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.BatchType,
	T.BatchStatusID,
	T.BatchStatus,
	T.TotalCount,
	T.TotalAmount,
	T.MasterETLLoadID,
	T.TransactionETLLoadID,
	T.CreateDate,
	T.CreateBy,
	T.ModifyDate,
	T.ModifyBy,
	t.LinesCount
FROM #tmpFinalResults T

 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'BatchType' AND @sortOrder = 'ASC'
	 THEN T.BatchType END ASC, 
	 CASE WHEN @sortColumn = 'BatchType' AND @sortOrder = 'DESC'
	 THEN T.BatchType END DESC ,

	 CASE WHEN @sortColumn = 'BatchStatusID' AND @sortOrder = 'ASC'
	 THEN T.BatchStatusID END ASC, 
	 CASE WHEN @sortColumn = 'BatchStatusID' AND @sortOrder = 'DESC'
	 THEN T.BatchStatusID END DESC ,

	 CASE WHEN @sortColumn = 'BatchStatus' AND @sortOrder = 'ASC'
	 THEN T.BatchStatus END ASC, 
	 CASE WHEN @sortColumn = 'BatchStatus' AND @sortOrder = 'DESC'
	 THEN T.BatchStatus END DESC ,

	 CASE WHEN @sortColumn = 'TotalCount' AND @sortOrder = 'ASC'
	 THEN T.TotalCount END ASC, 
	 CASE WHEN @sortColumn = 'TotalCount' AND @sortOrder = 'DESC'
	 THEN T.TotalCount END DESC ,

	 CASE WHEN @sortColumn = 'TotalAmount' AND @sortOrder = 'ASC'
	 THEN T.TotalAmount END ASC, 
	 CASE WHEN @sortColumn = 'TotalAmount' AND @sortOrder = 'DESC'
	 THEN T.TotalAmount END DESC ,

	 CASE WHEN @sortColumn = 'MasterETLLoadID' AND @sortOrder = 'ASC'
	 THEN T.MasterETLLoadID END ASC, 
	 CASE WHEN @sortColumn = 'MasterETLLoadID' AND @sortOrder = 'DESC'
	 THEN T.MasterETLLoadID END DESC ,

	 CASE WHEN @sortColumn = 'TransactionETLLoadID' AND @sortOrder = 'ASC'
	 THEN T.TransactionETLLoadID END ASC, 
	 CASE WHEN @sortColumn = 'TransactionETLLoadID' AND @sortOrder = 'DESC'
	 THEN T.TransactionETLLoadID END DESC ,

	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'
	 THEN T.CreateDate END ASC, 
	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'
	 THEN T.CreateDate END DESC ,

	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
	 THEN T.CreateBy END ASC, 
	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
	 THEN T.CreateBy END DESC ,

	 CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'ASC'
	 THEN T.ModifyDate END ASC, 
	 CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'DESC'
	 THEN T.ModifyDate END DESC ,

	 CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'ASC'
	 THEN T.ModifyBy END ASC, 
	 CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'DESC'
	 THEN T.ModifyBy END DESC ,

	 CASE WHEN @sortColumn = 'LinesCount' AND @sortOrder = 'ASC'
	 THEN T.LinesCount END ASC, 
	 CASE WHEN @sortColumn = 'LinesCount' AND @sortOrder = 'DESC'
	 THEN T.LinesCount END DESC


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
 WHERE id = object_id(N'[dbo].[dms_Member_ServiceRequestHistory]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_ServiceRequestHistory] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
-- EXEC  [dbo].[dms_Member_ServiceRequestHistory] @whereClauseXML ='<ROW><Filter MembershipIDOperator="2" MembershipIDValue="1"></Filter></ROW>', @sortColumn = 'CreateDate', @sortOrder = 'ASC'
 CREATE PROCEDURE [dbo].[dms_Member_ServiceRequestHistory]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 10 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 
 ) 
 AS 
 BEGIN 
  
    SET FMTONLY OFF
 	SET NOCOUNT ON  
 	
CREATE TABLE #FinalResultsFiltered (    
 CaseNumber int  NULL ,  
 ServiceRequestNumber int  NULL ,  
 CreateDate datetime  NULL ,  
 ServiceType nvarchar(50)  NULL ,  
 [Status] nvarchar(50)  NULL ,  
 FirstName nvarchar(50)  NULL ,  
 MiddleName nvarchar(50)  NULL ,  
 LastName nvarchar(50)  NULL ,  
 Suffix nvarchar(50)  NULL ,  
 VehicleYear nvarchar(4)  NULL ,  
 VehicleMake nvarchar(50)  NULL ,  
 VehicleMakeOther nvarchar(50)  NULL ,  
 VehicleModel nvarchar(50)  NULL ,  
 VehicleModelOther nvarchar(50)  NULL ,  
 Vendor nvarchar(255)  NULL , 
 MembershipID int  NULL , 
 POCount int  NULL  ,
 ContactPhoneNumber nvarchar(100) NULL 
)

CREATE TABLE #FinalResultsFormatted (   
 
 CaseNumber int  NULL ,  
 ServiceRequestNumber int  NULL ,  
 CreateDate datetime  NULL ,  
 ServiceType nvarchar(50)  NULL ,  
 Status nvarchar(50)  NULL ,  
 MemberName nvarchar(200)  NULL ,  
 Vehicle nvarchar(200)  NULL ,  
 Vendor nvarchar(255)  NULL ,  
 POCount int  NULL ,  
 MembershipID int  NULL   ,
 ContactPhoneNumber nvarchar(100) NULL 
)
  
CREATE TABLE #FinalResultsSorted (   
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 CaseNumber int  NULL ,  
 ServiceRequestNumber int  NULL ,  
 CreateDate datetime  NULL ,  
 ServiceType nvarchar(50)  NULL ,  
 Status nvarchar(50)  NULL ,  
 MemberName nvarchar(200)  NULL ,  
 Vehicle nvarchar(200)  NULL ,  
 Vendor nvarchar(255)  NULL ,  
 POCount int  NULL ,  
 MembershipID int  NULL   ,
 ContactPhoneNumber nvarchar(100) NULL 
)

DECLARE @idoc int  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter   
CaseNumberOperator="-1"   
ServiceRequestNumberOperator="-1"   
CreateDateOperator="-1"   
ServiceTypeOperator="-1"   
StatusOperator="-1"   
MemberNameOperator="-1"   
VehicleOperator="-1"   
VendorOperator="-1"   
POCountOperator="-1"   
MembershipIDOperator="-1"   
ContactPhoneNumberOperator="-1"
 ></Filter></ROW>' 
  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
CaseNumberOperator INT NOT NULL,  
CaseNumberValue int NULL,  
ServiceRequestNumberOperator INT NOT NULL,  
ServiceRequestNumberValue int NULL,  
CreateDateOperator INT NOT NULL,  
CreateDateValue datetime NULL,  
ServiceTypeOperator INT NOT NULL,  
ServiceTypeValue nvarchar(50) NULL,  
StatusOperator INT NOT NULL,  
StatusValue nvarchar(50) NULL,  
MemberNameOperator INT NOT NULL,  
MemberNameValue nvarchar(200) NULL,  
VehicleOperator INT NOT NULL,  
VehicleValue nvarchar(50) NULL,  
VendorOperator INT NOT NULL,  
VendorValue nvarchar(50) NULL,  
POCountOperator INT NOT NULL,  
POCountValue int NULL,  
MembershipIDOperator INT NOT NULL,  
MembershipIDValue int NULL ,
ContactPhoneNumberOperator INT NOT NULL ,
ContactPhoneNumberValue nvarchar(50) NULL 
)  
   -- ContactPhoneNumber nvarchar NULL 
  
INSERT INTO @tmpForWhereClause  
SELECT    
 ISNULL(CaseNumberOperator,-1),  
 CaseNumberValue ,  
 ISNULL(ServiceRequestNumberOperator,-1),  
 ServiceRequestNumberValue ,  
 ISNULL(CreateDateOperator,-1),  
 CreateDateValue ,  
 ISNULL(ServiceTypeOperator,-1),  
 ServiceTypeValue ,  
 ISNULL(StatusOperator,-1),  
 StatusValue ,  
 ISNULL(MemberNameOperator,-1),  
 MemberNameValue ,  
 ISNULL(VehicleOperator,-1),  
 VehicleValue ,  
 ISNULL(VendorOperator,-1),  
 VendorValue ,  
 ISNULL(POCountOperator,-1),  
 POCountValue ,  
 ISNULL(MembershipIDOperator,-1),  
 MembershipIDValue  , 
 ISNULL(ContactPhoneNumberOperator,-1),  
 ContactPhoneNumberValue   
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
CaseNumberOperator INT,  
CaseNumberValue int   
,ServiceRequestNumberOperator INT,  
ServiceRequestNumberValue int   
,CreateDateOperator INT,  
CreateDateValue datetime   
,ServiceTypeOperator INT,  
ServiceTypeValue nvarchar(50)   
,StatusOperator INT,  
StatusValue nvarchar(50)   
,MemberNameOperator INT,  
MemberNameValue nvarchar(50)   
,VehicleOperator INT,  
VehicleValue nvarchar(50)   
,VendorOperator INT,  
VendorValue nvarchar(50)   
,POCountOperator INT,  
POCountValue int   
,MembershipIDOperator INT,  
MembershipIDValue int   
,ContactPhoneNumberOperator INT,  
ContactPhoneNumberValue nvarchar(50)
 )   
  
--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
INSERT INTO #FinalResultsFiltered
SELECT   
 T.CaseNumber,  
 T.ServiceRequestNumber,  
 T.CreateDate,  
 T.ServiceType,  
 T.[Status],  
 T.FirstName,  
 T.MiddleName,
 T.LastName,
 T.Suffix,
 T.VehicleYear,
 T.VehicleMake,
 T.VehicleMakeOther,
 T.VehicleModel,
 T.VehicleModelOther, 
 T.Vendor,  
 T.MembershipID,  
 T.POCount,
 T.ContactPhoneNumber
   
FROM (  
        SELECT  
				  c.ID AS CaseNumber,   
				  sr.ID AS ServiceRequestNumber,  
				  sr.CreateDate,   
				  pc.Name AS ServiceType,   
				  srs.Name AS 'Status',  
				  M.FirstName,
				  M.MiddleName,
				  M.LastName,
				  M.Suffix,				  
				  C.VehicleYear,
				  C.VehicleMake,
				  C.VehicleMakeOther,
				  C.VehicleModel,
				  C.VehicleModelOther,				   
				  ven.Name AS Vendor,  
				  ms.ID AS MembershipID,  
				  0 AS POCount	,
				  --'' AS ContactPhoneNumber
				  C.ContactPhoneNumber	AS ContactPhoneNumber		  
    FROM ServiceRequest sr  WITH (NOLOCK)
	JOIN [Case] c WITH (NOLOCK) ON c.ID = sr.CaseID  
	JOIN Member m WITH (NOLOCK) ON m.ID = c.MemberId  
	JOIN Membership ms WITH (NOLOCK) ON ms.ID = m.MembershipID
	JOIN ServiceRequestStatus srs WITH (NOLOCK) ON srs.ID = sr.ServiceRequestStatusID  
	LEFT JOIN ProductCategory pc WITH (NOLOCK) ON pc.ID = sr.ProductCategoryID     
	LEFT JOIN (SELECT TOP 1 ServiceRequestID, VendorLocationID   ---- Someone should verify this SQL?????  
			   FROM PurchaseOrder WITH (NOLOCK) 
			   ORDER BY issuedate DESC  
			  )  LastPO ON LastPO.ServiceRequestID = sr.ID   
	LEFT JOIN VendorLocation vl WITH (NOLOCK) on vl.ID = LastPO.VendorLocationID  
	LEFT JOIN Vendor ven WITH (NOLOCK) on ven.ID = vl.VendorID  
  
     ) T,  
@tmpForWhereClause TMP   
WHERE (   
 --(   
 -- ( TMP.CaseNumberOperator = -1 )   
 -- OR   
 -- ( TMP.CaseNumberOperator = 2 AND T.CaseNumber = TMP.CaseNumberValue )   
 --)     
 --AND   
 --(   
 -- ( TMP.ServiceRequestNumberOperator = -1 )    
 --OR   
 -- ( TMP.ServiceRequestNumberOperator = 2 AND T.ServiceRequestNumber = TMP.ServiceRequestNumberValue )  
 --)     
 --AND   
 --(   
 -- ( TMP.CreateDateOperator = -1 )   
 --OR   
 -- ( TMP.CreateDateOperator = 2 AND T.CreateDate = TMP.CreateDateValue )   
 --)     
 --AND   
 --(   
 -- ( TMP.ServiceTypeOperator = -1 )    
 --OR   
 -- ( TMP.ServiceTypeOperator = 2 AND T.ServiceType = TMP.ServiceTypeValue )    
 --)     
 --AND   
 --(   
 -- ( TMP.StatusOperator = -1 )    
 --OR   
 -- ( TMP.StatusOperator = 2 AND T.Status = TMP.StatusValue )    
 --)   
 --AND   
 --(   
 -- ( TMP.VendorOperator = -1 )   
 --OR   
 -- ( TMP.VendorOperator = 2 AND T.Vendor = TMP.VendorValue )    
 --) 
 --AND     
 (   
  ( TMP.MembershipIDOperator = -1 )    
 OR   
  ( TMP.MembershipIDOperator = 2 AND T.MembershipID = TMP.MembershipIDValue )  
 )    
 AND   
 1 = 1   
 )   
 
 
 INSERT INTO #FinalResultsFormatted
 SELECT DISTINCT F.CaseNumber,   
		F.ServiceRequestNumber,  
		F.CreateDate,   
		F.ServiceType,   
		F.[Status],  
		REPLACE(RTRIM(  
		COALESCE(F.FirstName,'')+  
		COALESCE(' '+left(F.MiddleName,1),'')+  
		COALESCE(' '+ F.LastName,'')+  
		COALESCE(' '+ F.Suffix,'')  
		),'  ',' ') AS MemberName,  
		REPLACE(RTRIM(  
		COALESCE(F.VehicleYear,'')+  
		COALESCE(' '+ CASE F.VehicleMake WHEN 'Other' THEN F.VehicleMakeOther ELSE F.VehicleMake END,'')+  
		COALESCE(' '+ CASE F.VehicleModel WHEN 'Other' THEN F.VehicleModelOther ELSE F.VehicleModel END,'')  
		),'  ',' ') AS Vehicle,  
		F.Vendor,  
		(select count(*) FROM PurchaseOrder po WITH (NOLOCK) WHERE po.ServiceRequestID = F.ServiceRequestNumber and po.IsActive<>0) AS POCount, 
		F.MembershipID,
		F.ContactPhoneNumber
 FROM	#FinalResultsFiltered F
 --DEBUG
-- SELECT * FROM #FinalResultsFiltered
 INSERT INTO #FinalResultsSorted
 SELECT F.*
 FROM  #FinalResultsFormatted F,
		@tmpForWhereClause TMP
 --WHERE 
 --(	
 --(   
 -- ( TMP.MemberNameOperator = -1 )   
 --OR   
 -- ( TMP.MemberNameOperator = 2 AND F.MemberName = TMP.MemberNameValue )   
 --)   
 --AND 
 --(   
 -- ( TMP.VehicleOperator = -1 )   
 --OR   
 -- ( TMP.VehicleOperator = 2 AND F.Vehicle = TMP.VehicleValue )   
 --)  
 --AND   
 --(   
 -- ( TMP.POCountOperator = -1 )    
 --OR   
 -- ( TMP.POCountOperator = 2 AND F.POCount = TMP.POCountValue )   
 --)   
	 
 --AND 
	--(1=1)
 --)
 ORDER BY   
  CASE WHEN @sortColumn = 'CaseNumber' AND @sortOrder = 'ASC'  
  THEN F.CaseNumber END ASC,   
  CASE WHEN @sortColumn = 'CaseNumber' AND @sortOrder = 'DESC'  
  THEN F.CaseNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'ServiceRequestNumber' AND @sortOrder = 'ASC'  
  THEN F.ServiceRequestNumber END ASC,   
  CASE WHEN @sortColumn = 'ServiceRequestNumber' AND @sortOrder = 'DESC'  
  THEN F.ServiceRequestNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'  
  THEN F.CreateDate END ASC,   
  CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'  
  THEN F.CreateDate END DESC ,  
  
  CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'ASC'  
  THEN F.ServiceType END ASC,   
  CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'DESC'  
  THEN F.ServiceType END DESC ,  
  
  CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'  
  THEN F.Status END ASC,   
  CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'  
  THEN F.Status END DESC ,  
  
  CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'  
  THEN F.MemberName END ASC,   
  CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'  
  THEN F.MemberName END DESC ,  
  
  CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'ASC'  
  THEN F.Vehicle END ASC,   
  CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'DESC'  
  THEN F.Vehicle END DESC ,  
  
  CASE WHEN @sortColumn = 'Vendor' AND @sortOrder = 'ASC'  
  THEN F.Vendor END ASC,   
  CASE WHEN @sortColumn = 'Vendor' AND @sortOrder = 'DESC'  
  THEN F.Vendor END DESC ,  
  
  CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'  
  THEN F.POCount END ASC,   
  CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'  
  THEN F.POCount END DESC ,  
  
  CASE WHEN @sortColumn = 'MembershipID' AND @sortOrder = 'ASC'  
  THEN F.MembershipID END ASC,   
  CASE WHEN @sortColumn = 'MembershipID' AND @sortOrder = 'DESC'  
  THEN F.MembershipID END DESC ,  
  
  CASE WHEN @sortColumn = 'ContactPhoneNumber' AND @sortOrder = 'ASC'  
  THEN F.ContactPhoneNumber END ASC,   
  CASE WHEN @sortColumn = 'ContactPhoneNumber' AND @sortOrder = 'DESC'  
  THEN F.ContactPhoneNumber END DESC 

  
DECLARE @count INT     
SET @count = 0     
SELECT @count = MAX(RowNum) FROM #FinalResultsSorted  
IF (@endInd IS NOT NULL)
BEGIN

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
END
  
SELECT @count AS TotalRows,   
   F.RowNum,  
   F.CaseNumber,  
   F.ServiceRequestNumber,  
   CONVERT(VARCHAR(10), F.CreateDate, 101) AS 'Date',  
   F.ServiceType,  
   F.Status,  
   F.MemberName,  
   F.Vehicle,  
   F.Vendor,  
   F.POCount ,
   F.ContactPhoneNumber
   FROM #FinalResultsSorted F 
WHERE 
		(@endInd IS NULL AND RowNum >= @startInd)
		OR
		(RowNum BETWEEN @startInd AND @endInd)
   
   
DROP TABLE #FinalResultsFiltered
DROP TABLE #FinalResultsFormatted
DROP TABLE #FinalResultsSorted

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
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL , 
	VehicleID INT NULL, -- KB: Added VehicleID   
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
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,  
	VehicleID INT NULL, -- KB: Added VehicleID  
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL     
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
		 F.ProgramID, --KB: ADDED IDS      
		 F.Program,    
		 F.POCount,    
		 F.MemberStatus,    
		 F.LastName,    
		 F.FirstName ,    
		F.VIN , 
		F.VehicleID,   
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
			F.VIN,
			F.VehicleID ORDER BY F.RowNum) AS sRowNumber	
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
			VehicleID 
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
			F.VehicleID
			
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
	   F.VehicleID   
	   FROM    
	   #FinalResultsDistinct F WHERE RowNum BETWEEN @startInd AND @endInd    
	     
	DROP TABLE #FinalResultsFiltered  
	DROP TABLE #FinalResultsFormatted  
	DROP TABLE #FinalResultsSorted 
	DROP TABLE #FinalResultsDistinct



END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Payment_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Payment_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC dms_Payment_List @ServiceRequestID = 1058
CREATE PROC dms_Payment_List(@ServiceRequestID INT = NULL)
AS
BEGIN
SELECT
	  p.ID as PaymentID
	, p.PaymentTypeID as PaymentTypeID
	, pt.Description as PaymentType
	, p.PaymentStatusID as PaymentStatusID
	, ps.Description as PaymentStatus
	, p.PaymentTransactionTypeID as PaymentTransactionTypeID
	, ptt.Description as TransactionType
	, p.PaymentReasonID as PaymentReasonID
	, CASE	WHEN pr.Name = 'Other' THEN  p.PaymentReasonOther
			ELSE pr.Description
		END PaymentReason
	, p.PaymentReasonOther as OtherReason
	, p.PaymentDate as PaymentDate
	, p.Amount as Amount
	, p.CurrencyTypeID as CurrencyTypeID
	, ct.Abbreviation as CurrencyType
	, p.CCAccountNumber as CardNumber
	, p.CCPartial as CCPartial
	, p.CCOrderID
	, p.CCTransactionReference
	, p.CCExpireDate as ExpirationDate
	,datepart(mm,p.CCExpireDate)as ExpirationMonth
	,datepart(yy,p.CCExpireDate)as ExpirationYear
	, p.CCNameOnCard as NameOnCard
	, PA.AuthorizationCode CCAuthCode
	, p.CCAuthType as CCAuthType
	, p.CCTransactionReference as CCTransRef
	, p.BillingLine1 as Address1
	, p.BillingLine2 as Address2
	, p.BillingCity as City
	, p.BillingStateProvince as StateProvince
	, p.BillingPostalCode as PostalCode
	, p.BillingCountryCode as CoutnryCode
	, p.BillingStateProvinceID as StateProvinceID
	, p.BillingCountryID as CountryID
	, p.Comments as Comments
	, p.CreateDate as CreateDate
	, p.CreateBy as Username			
FROM		Payment p
JOIN		PaymentType pt on pt.ID = p.PaymentTypeID
JOIN		PaymentStatus ps on ps.ID = p.PaymentStatusID
JOIN		PaymentTransactionType ptt on ptt.ID = p.PaymentTransactionTypeID
LEFT JOIN	PaymentReason pr on pr.ID = p.PaymentReasonID
JOIN		CurrencyType ct on ct.ID = p.CurrencyTypeID 
LEFT JOIN	PaymentAuthorization PA ON PA.PaymentID = P.ID
WHERE		p.ServiceRequestID = @ServiceRequestID 
ORDER BY	p.CreateDate DESC -- CR : 1296

END


GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_PO_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_PO_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
 --EXEC [dbo].[dms_PO_list] @serviceRequestID = 1414, @sortColumn='PurchaseOrderPayStatusCode', @sortOrder = 'ASC'
 CREATE PROCEDURE [dbo].[dms_PO_list]( 
  @serviceRequestID INT = NULL
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON
 	
 	CREATE TABLE #tmpPODetails 	
 	(
 		ID INT NULL,
 		PONumber NVARCHAR(50) NULL,
 		PODate DATETIME NULL,
 		VendorName NVARCHAR(255) NULL,
 		POTotal MONEY NULL,
 		[Service] NVARCHAR(200) NULL,
 		POStatus NVARCHAR(50) NULL,
 		CancelReason NVARCHAR(255) NULL,
 		DataTransferDate DATETIME NULL,
 		ModifyDate DATETIME NULL,
 		OriginalPONumber NVARCHAR(50) NULL 	,
 		
 		InvoiceNumber nvarchar(100)  NULL ,
		InvoiceDate datetime  NULL ,
		InvoiceAmount money  NULL ,
		InvoiceStatus nvarchar(100)  NULL ,
		PaymentNumber nvarchar(100)  NULL ,
		PaymentDate datetime  NULL ,
		PaymentAmount money  NULL ,
		CheckClearedDate datetime  NULL ,
		InvoiceReceivedDate datetime NULL ,
		InvoiceReceiveMethod nvarchar(100) NULL ,
		InvoiceToBePaidDate datetime NULL,
		PurchaseOrderPayStatusCode nvarchar(255) NULL 	
 	)
 	
 	SET FMTONLY OFF;
 	
	INSERT INTO #tmpPODetails
	SELECT	  po.ID as ID
			, po.PurchaseOrderNumber as PONumber
			, po.IssueDate as PODate
			, v.Name as VendorName
			, po.TotalServiceAmount as POTotal
			, pc.[Description] as [Service]
			, pos.Name as POStatus
			--, cr.[Description] as CancelReason
			, CASE	WHEN po.CancellationReasonOther <> '' THEN po.CancellationReasonOther  
					WHEN po.GOAReasonOther <> '' THEN po.GOAReasonOther   
					ELSE cr.[Description]  
				END as CancelReason
			, po.DataTransferDate
			, po.ModifyDate
			,poo.PurchaseOrderNumber as OriginalPONumber
			, VI.InvoiceNumber
			, VI.InvoiceDate
			, VI.InvoiceAmount
			, VIS.Name AS [InvoiceStatus]
			--, VI.PaymentNumber
			,CASE 
			WHEN VI.PaymentTypeID = (SELECT ID From PaymentType WHERE Name = 'ACH') 
			THEN 'ACH' 
			ELSE VI.PaymentNumber
			END AS PaymentNumber
			, VI.PaymentDate 
			, VI.PaymentAmount 
			, VI.CheckClearedDate
			, VI.ReceivedDate
			, CM.Name
			, VI.ToBePaidDate
			,pops.[Description]
	FROM	PurchaseOrder po WITH (NOLOCK)
	LEFT OUTER JOIN PurchaseOrder poo WITH (NOLOCK) on poo.ID=po.OriginalPurchaseOrderID
	JOIN VendorLocation vl WITH (NOLOCK) on vl.ID = po.VendorLocationID
	JOIN Vendor v WITH (NOLOCK) on v.ID = vl.VendorID
	--Join PurchaseOrderDetail pod on pod.PurchaseOrderID = po.ID 
	--and pod.Sequence = 1
	--LEFT OUTER Join Product p on p.ID = pod.ProductID 
	LEFT OUTER JOIN Product p WITH (NOLOCK) on p.ID = po.ProductID 
	LEFT OUTER JOIN ProductCategory pc WITH (NOLOCK) on pc.ID = p.ProductCategoryID
	JOIN PurchaseOrderStatus pos WITH (NOLOCK) on pos.ID = po.PurchaseOrderStatusID
	LEFT JOIN PurchaseOrderPayStatusCode pops WITH (NOLOCK) on pops.ID = po.PayStatusCodeID
	LEFT JOIN PurchaseOrderCancellationReason cr WITH (NOLOCK) on cr.ID = po.CancellationReasonID
	LEFT OUTER JOIN VendorInvoice VI ON VI.PurchaseOrderID = PO.ID 
	LEFT OUTER JOIN VendorInvoiceStatus VIS ON VIS.ID = VI.VendorInvoiceStatusID 	
	LEFT OUTER JOIN ContactMethod CM ON CM.ID=VI.ReceiveContactMethodID
	WHERE	po.ServiceRequestID = @serviceRequestID and (po.IsActive = 1 or po.IsActive IS NULL )

SELECT W.*
FROM #tmpPODetails W
 ORDER BY 
     CASE WHEN @sortColumn IS NULL
     THEN W.ID END DESC,
	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'
	 THEN W.PONumber END ASC, 
	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'
	 THEN W.PONumber END DESC ,

	 CASE WHEN @sortColumn = 'PODate' AND @sortOrder = 'ASC'
	 THEN W.PODate END ASC, 
	 CASE WHEN @sortColumn = 'PODate' AND @sortOrder = 'DESC'
	 THEN W.PODate END DESC ,

	 CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'ASC'
	 THEN W.VendorName  END ASC, 
	 CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'DESC'
	 THEN W.VendorName  END DESC ,

	 CASE WHEN @sortColumn = 'POTotal' AND @sortOrder = 'ASC'
	 THEN W.POTotal END ASC, 
	 CASE WHEN @sortColumn = 'POTotal' AND @sortOrder = 'DESC'
	 THEN W.POTotal END DESC ,

	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'ASC'
	 THEN W.[Service] END ASC, 
	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'DESC'
	 THEN W.[Service] END DESC ,

	 CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'ASC'
	 THEN W.POStatus END ASC, 
	 CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'DESC'
	 THEN W.POStatus END DESC ,

	 CASE WHEN @sortColumn = 'CancelReason' AND @sortOrder = 'ASC'
	 THEN W.CancelReason END ASC, 
	 CASE WHEN @sortColumn = 'CancelReason' AND @sortOrder = 'DESC'
	 THEN W.CancelReason END DESC ,
	 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN W.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN W.InvoiceNumber END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'ASC'
	 THEN W.InvoiceDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'DESC'
	 THEN W.InvoiceDate END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'
	 THEN W.InvoiceAmount END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'
	 THEN W.InvoiceAmount END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'ASC'
	 THEN W.InvoiceStatus END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'DESC'
	 THEN W.InvoiceStatus END DESC ,

	 CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'ASC'
	 THEN W.PaymentNumber END ASC, 
	 CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'DESC'
	 THEN W.PaymentNumber END DESC ,

	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'ASC'
	 THEN W.PaymentDate END ASC, 
	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'DESC'
	 THEN W.PaymentDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'
	 THEN W.PaymentAmount END ASC, 
	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'
	 THEN W.PaymentAmount END DESC ,

	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'ASC'
	 THEN W.CheckClearedDate END ASC, 
	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'DESC'
	 THEN W.CheckClearedDate END DESC  ,

	 CASE WHEN @sortColumn = 'InvoiceReceivedDate' AND @sortOrder = 'ASC'
	 THEN W.InvoiceReceivedDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceReceivedDate' AND @sortOrder = 'DESC'
	 THEN W.InvoiceReceivedDate END DESC,

	 CASE WHEN @sortColumn = 'InvoiceReceiveMethod' AND @sortOrder = 'ASC'
	 THEN W.InvoiceReceiveMethod END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceReceiveMethod' AND @sortOrder = 'DESC'
	 THEN W.InvoiceReceiveMethod END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceToBePaidDate' AND @sortOrder = 'ASC'
	 THEN W.InvoiceToBePaidDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceToBePaidDate' AND @sortOrder = 'DESC'
	 THEN W.InvoiceToBePaidDate END DESC, 
	 
	 CASE WHEN @sortColumn = 'PurchaseOrderPayStatusCode' AND @sortOrder = 'ASC'
	 THEN W.PurchaseOrderPayStatusCode END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderPayStatusCode' AND @sortOrder = 'DESC'
	 THEN W.PurchaseOrderPayStatusCode END DESC 
	 
	DROP TABLE #tmpPODetails	 

END 
	 
	
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_servicerequest_history_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_servicerequest_history_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = '<ROW><Filter IDType="ServiceRequest" IDValue="1234" NameType="" NameValue="" LastName="" FilterType = "StartsWith" FromDate = "" ToDate = "" Preset ="" Clients ="1" Programs ="" ServiceRequestStatuses = "" ServiceTypes ="" IsGOA = "" IsRedispatched = "" IsPossibleTow ="" VehicleType ="1" VehicleYear ="2012" VehicleMake = "" VehicleModel = "" PaymentByCheque = "" PaymentByCard = "" MemberPaid ="" POStatuses =""/></ROW>', @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
-- EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = NULL, @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
-- EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = '<ROW><Filter IDType="Service Request" IDValue="2"/></ROW>', @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'

CREATE PROCEDURE [dbo].[dms_servicerequest_history_list]( 
	@whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10   
 , @sortColumn nvarchar(100)  = 'RequestNumber'   
 , @sortOrder nvarchar(100) = 'ASC'
 , @userID UNIQUEIDENTIFIER = NULL
) 
AS
BEGIN
	
	SET FMTONLY OFF;
	-- Temporary tables to hold the results until the final resultset.
	CREATE TABLE #Raw	
	(
		RequestNumber INT NOT NULL,
		CaseID INT NOT NULL,
		ProgramID INT NULL,
		Program NVARCHAR(50) NULL,
		ClientID INT NULL,
		Client NVARCHAR(50) NULL,
		FirstName NVARCHAR(50)  NULL ,    
		LastName NVARCHAR(50)  NULL ,  
		MiddleName NVARCHAR(50)  NULL ,  
		Suffix NVARCHAR(50)  NULL ,    
		Prefix NVARCHAR(50)  NULL ,
		MemberNumber NVARCHAR(50) NULL, 
		CreateDate DATETIME NULL,
		POCreateBy NVARCHAR(50) NULL,
		POModifyBy NVARCHAR(50) NULL,
		SRCreateBy NVARCHAR(50) NULL,
		SRModifyBy NVARCHAR(50) NULL,
		VIN NVARCHAR(50) NULL,
		VehicleTypeID INT NULL,
		VehicleType NVARCHAR(50) NULL,
		ServiceTypeID INT NULL, 
		ServiceType nvarchar(100) NULL,		 
		StatusID INT NULL,
		[Status] NVARCHAR(100) NULL,
		PriorityID INT NULL,
		[Priority] NVARCHAR(100) NULL,
		ISPName NVARCHAR(255) NULL,
		VendorNumber NVARCHAR(50) NULL,
		PONumber NVARCHAR(50) NULL,
		PurchaseOrderStatusID INT NULL,
		PurchaseOrderStatus NVARCHAR(50) NULL, 
		PurchaseOrderAmount money NULL,
		AssignedToUserID INT NULL,
		NextActionAssignedToUserID INT NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow BIT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,
		VehicleMakeOther NVARCHAR(255) NULL,
		VehicleModel NVARCHAR(255) NULL,
		VehicleModelOther NVARCHAR(255) NULL,		
		PaymentByCard BIT NULL
	)
	
	CREATE TABLE #Filtered	
	(
		RequestNumber INT NOT NULL,
		CaseID INT NOT NULL,
		ProgramID INT NULL,
		Program NVARCHAR(50) NULL,
		ClientID INT NULL,
		Client NVARCHAR(50) NULL,
		FirstName NVARCHAR(50)  NULL ,    
		LastName NVARCHAR(50)  NULL ,  
		MiddleName NVARCHAR(50)  NULL ,  
		Suffix NVARCHAR(50)  NULL ,    
		Prefix NVARCHAR(50)  NULL , 
		MemberNumber NVARCHAR(50) NULL,
		CreateDate DATETIME NULL,
		POCreateBy NVARCHAR(50) NULL,
		POModifyBy NVARCHAR(50) NULL,
		SRCreateBy NVARCHAR(50) NULL,
		SRModifyBy NVARCHAR(50) NULL,
		VIN NVARCHAR(50) NULL,
		VehicleTypeID INT NULL,
		VehicleType NVARCHAR(50) NULL,
		ServiceTypeID INT NULL, 
		ServiceType nvarchar(100) NULL,		 
		StatusID INT NULL,
		[Status] NVARCHAR(100) NULL,
		PriorityID INT NULL,
		[Priority] NVARCHAR(100) NULL,
		ISPName NVARCHAR(255) NULL,
		VendorNumber NVARCHAR(50) NULL,
		PONumber NVARCHAR(50) NULL,
		PurchaseOrderStatusID INT NULL,
		PurchaseOrderStatus NVARCHAR(50) NULL, 
		PurchaseOrderAmount money NULL,
		AssignedToUserID INT NULL,
		NextActionAssignedToUserID INT NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow BIT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,
		VehicleMakeOther NVARCHAR(255) NULL,
		VehicleModel NVARCHAR(255) NULL,
		VehicleModelOther NVARCHAR(255) NULL,		
		PaymentByCard BIT NULL
	)
	
	CREATE TABLE #Formatted	
	(
		RequestNumber INT NOT NULL,
		CaseID INT NOT NULL,
		ProgramID INT NULL,
		Program NVARCHAR(50) NULL,
		ClientID INT NULL,
		Client NVARCHAR(50) NULL,
		MemberName NVARCHAR(255)  NULL ,
		MemberNumber NVARCHAR(50) NULL,    		
		CreateDate DATETIME NULL,
		POCreateBy NVARCHAR(50) NULL,
		POModifyBy NVARCHAR(50) NULL,
		SRCreateBy NVARCHAR(50) NULL,
		SRModifyBy NVARCHAR(50) NULL,
		VIN NVARCHAR(50) NULL,
		VehicleTypeID INT NULL,
		VehicleType NVARCHAR(50) NULL,
		ServiceTypeID INT NULL, 
		ServiceType nvarchar(100) NULL,		 
		StatusID INT NULL,
		[Status] NVARCHAR(100) NULL,
		PriorityID INT NULL,
		[Priority] NVARCHAR(100) NULL,
		ISPName NVARCHAR(255) NULL,
		VendorNumber NVARCHAR(50) NULL,
		PONumber NVARCHAR(50) NULL,
		PurchaseOrderStatusID INT NULL,
		PurchaseOrderStatus NVARCHAR(50) NULL, 
		PurchaseOrderAmount money NULL,
		AssignedToUserID INT NULL,
		NextActionAssignedToUserID INT NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow BIT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,		
		VehicleModel NVARCHAR(255) NULL,		
		PaymentByCard BIT NULL
	)
	
	CREATE TABLE #Sorted
	(
		RowNum INT NOT NULL IDENTITY(1,1),
		RequestNumber INT NOT NULL,
		CaseID INT NOT NULL,
		ProgramID INT NULL,
		Program NVARCHAR(50) NULL,
		ClientID INT NULL,
		Client NVARCHAR(50) NULL,
		MemberName NVARCHAR(255)  NULL , 
		MemberNumber NVARCHAR(50) NULL,   		
		CreateDate DATETIME NULL,
		POCreateBy NVARCHAR(50) NULL,
		POModifyBy NVARCHAR(50) NULL,
		SRCreateBy NVARCHAR(50) NULL,
		SRModifyBy NVARCHAR(50) NULL,
		VIN NVARCHAR(50) NULL,
		VehicleTypeID INT NULL,
		VehicleType NVARCHAR(50) NULL,
		ServiceTypeID INT NULL, 
		ServiceType nvarchar(100) NULL,		 
		StatusID INT NULL,
		[Status] NVARCHAR(100) NULL,
		PriorityID INT NULL,
		[Priority] NVARCHAR(100) NULL,
		ISPName NVARCHAR(255) NULL,
		VendorNumber NVARCHAR(50) NULL,
		PONumber NVARCHAR(50) NULL,
		PurchaseOrderStatusID INT NULL,
		PurchaseOrderStatus NVARCHAR(50) NULL, 
		PurchaseOrderAmount money NULL,
		AssignedToUserID INT NULL,
		NextActionAssignedToUserID INT NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow BIT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,
		VehicleModel NVARCHAR(255) NULL,
		PaymentByCard BIT NULL
	)
	
	CREATE TABLE #tmpVehicle
	(
		VIN NVARCHAR(50) NULL,
		MemberID INT NULL,
		MembershipID INT NULL
	)
	
	DECLARE @totalRows INT = 0

	DECLARE @tmpWhereClause TABLE
	(	
		IDType NVARCHAR(255) NULL,
		IDValue NVARCHAR(255) NULL,
		NameType NVARCHAR(255) NULL,
		NameValue NVARCHAR(255) NULL,
		LastName NVARCHAR(255) NULL, -- If name type = Member, then firstname goes into namevalue and last name goes into this field.
		FilterType NVARCHAR(100) NULL,
		FromDate DATETIME NULL,
		ToDate DATETIME NULL,
		Preset NVARCHAR(100) NULL,
		Clients NVARCHAR(MAX) NULL,
		Programs NVARCHAR(MAX) NULL,
		ServiceRequestStatuses NVARCHAR(MAX) NULL,
		ServiceTypes NVARCHAR(MAX) NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow  BIT NULL,		
		VehicleType INT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,
		VehicleMakeOther NVARCHAR(255) NULL,
		VehicleModel NVARCHAR(255) NULL,
		VehicleModelOther NVARCHAR(255) NULL,
		PaymentByCheque BIT NULL,
		PaymentByCard BIT NULL,
		MemberPaid BIT NULL,
		POStatuses NVARCHAR(MAX) NULL
	)
	
	DECLARE @IDType NVARCHAR(255) ,
			@IDValue NVARCHAR(255) ,
			@NameType NVARCHAR(255) ,
			@NameValue NVARCHAR(255) ,
			@LastName NVARCHAR(255) , 
			@FilterType NVARCHAR(100) ,
			@FromDate DATETIME ,
			@ToDate DATETIME ,
			@Preset NVARCHAR(100) ,
			@Clients NVARCHAR(MAX) ,
			@Programs NVARCHAR(MAX) ,
			@ServiceRequestStatuses NVARCHAR(MAX) ,
			@ServiceTypes NVARCHAR(MAX) ,
			@IsGOA BIT ,
			@IsRedispatched BIT ,
			@IsPossibleTow  BIT ,		
			@VehicleType INT ,
			@VehicleYear INT ,
			@VehicleMake NVARCHAR(255) ,
			@VehicleMakeOther NVARCHAR(255) ,
			@VehicleModel NVARCHAR(255) ,
			@VehicleModelOther NVARCHAR(255) ,
			@PaymentByCheque BIT ,
			@PaymentByCard BIT ,
			@MemberPaid BIT ,
			@POStatuses NVARCHAR(MAX) 
	
	DECLARE @idoc int
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML 
	
	INSERT INTO @tmpWhereClause  
	SELECT	IDType,
			IDValue,
			NameType,
			NameValue,
			LastName,
			FilterType,
			FromDate,
			ToDate,
			Preset,
			Clients,
			Programs,
			ServiceRequestStatuses,
			ServiceTypes,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleType,
			VehicleYear,
			VehicleMake,
			VehicleMakeOther,
			VehicleModel,
			VehicleModelOther,
			PaymentByCheque,
			PaymentByCard,
			MemberPaid,
			POStatuses
	FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH ( 
	
			IDType NVARCHAR(255) ,
			IDValue NVARCHAR(255) ,
			NameType NVARCHAR(255) ,
			NameValue NVARCHAR(255) ,
			LastName NVARCHAR(255) ,
			FilterType NVARCHAR(100) ,
			FromDate DATETIME ,
			ToDate DATETIME ,
			Preset NVARCHAR(100) ,
			Clients NVARCHAR(MAX) ,
			Programs NVARCHAR(MAX) ,
			ServiceRequestStatuses NVARCHAR(MAX) ,
			ServiceTypes NVARCHAR(MAX) ,
			IsGOA BIT,
			IsRedispatched BIT,
			IsPossibleTow BIT,			
			VehicleType INT ,
			VehicleYear INT ,
			VehicleMake NVARCHAR(255) ,
			VehicleMakeOther NVARCHAR(255) ,
			VehicleModel NVARCHAR(255) ,
			VehicleModelOther NVARCHAR(255) ,
			PaymentByCheque BIT ,
			PaymentByCard BIT ,
			MemberPaid BIT ,
			POStatuses NVARCHAR(MAX) 	
	)
	
	-- DEBUG:
	--SELECT * FROM @tmpWhereClause
	
	DECLARE @strClients NVARCHAR(MAX)
	DECLARE @tmpClients TABLE
	(
		ID INT NOT NULL
	)	
	DECLARE @strPrograms NVARCHAR(MAX)
	DECLARE @tmpPrograms TABLE
	(
		ID INT NOT NULL
	)
	DECLARE @strServiceRequestStatuses NVARCHAR(MAX)
	DECLARE @tmpServiceRequestStatuses TABLE
	(
		ID INT NOT NULL
	)
	
	DECLARE @strServiceTypes NVARCHAR(MAX)
	DECLARE @tmpServiceTypes TABLE
	(
		ID INT NOT NULL
	)
	DECLARE @strPOStatuses NVARCHAR(MAX)
	DECLARE @tmpPOStatuses TABLE
	(
		ID INT NOT NULL
	)
	
	-- Extract some of the values into separate tables for ease of processing.
	SELECT	@strClients = Clients,
			@strPOStatuses = POStatuses,
			@strPrograms = Programs,
			@strServiceRequestStatuses = ServiceRequestStatuses,
			@strServiceTypes = ServiceTypes			
	FROM	@tmpWhereClause
	
	-- Clients
	INSERT INTO @tmpClients
	SELECT item FROM fnSplitString(@strClients,',')
	
	-- Programs
	INSERT INTO @tmpPrograms
	SELECT item FROM fnSplitString(@strPrograms,',')
	
	-- POStatuses
	INSERT INTO @tmpPOStatuses
	SELECT item FROM fnSplitString(@strPOStatuses,',')
	
	-- Service request statuses
	INSERT INTO @tmpServiceRequestStatuses
	SELECT item FROM fnSplitString(@strServiceRequestStatuses,',')
	
	-- Service types
	INSERT INTO @tmpServiceTypes
	SELECT item FROM fnSplitString(@strServiceTypes,',')
	
	
	SELECT	@IDType = T.IDType,			
			@IDValue = T.IDValue,
			@NameType = T.NameType,
			@NameValue = T.NameValue,
			@LastName = T.LastName, 
			@FilterType = T.FilterType,
			@FromDate = T.FromDate,
			@ToDate = T.ToDate,
			@Preset = T.Preset,
			@IsGOA = T.IsGOA,
			@IsRedispatched = T.IsRedispatched,
			@IsPossibleTow  = T.IsPossibleTow,		
			@VehicleType = T.VehicleType,
			@VehicleYear = T.VehicleYear,
			@VehicleMake = T.VehicleMake,
			@VehicleMakeOther = T.VehicleMakeOther,
			@VehicleModel = T.VehicleModel,
			@VehicleModelOther = T.VehicleModelOther,
			@PaymentByCheque = T.PaymentByCheque,
			@PaymentByCard = T.PaymentByCard ,
			@MemberPaid = T.MemberPaid
	FROM	@tmpWhereClause T
	
	DECLARE @vinParam NVARCHAR(50) = NULL
	SELECT	@vinParam = IDValue 
	FROM	@tmpWhereClause
	WHERE	IDType = 'VIN'
	
	IF ISNULL(@vinParam,'') <> ''
	BEGIN
	
		INSERT INTO #tmpVehicle
		SELECT	V.VIN,
				V.MemberID,
				V.MembershipID
		FROM	Vehicle V WITH (NOLOCK)
		WHERE	V.VIN = @vinParam
		--V.VIN LIKE '%' + @vinParam + '%'
		
	END
	
	INSERT INTO #Filtered
	SELECT  
			--DISTINCT  
			SR.ID AS [RequestNumber],  
			SR.CaseID AS [Case],
			P.ProgramID,
			P.ProgramName AS [Program],
			CL.ID AS ClientID,
			CL.Name AS [Client], 			
			M.FirstName,
			M.LastName,
			M.MiddleName,
			M.Suffix,
			M.Prefix,   
			MS.MembershipNumber AS MemberNumber,  			
			SR.CreateDate,
			PO.CreateBy,
			PO.ModifyBy,
			SR.CreateBy,
			SR.ModifyBy,
			TV.VIN,
			VT.ID As VehicleTypeID,
			VT.Name AS VehicleType,						
			PC.ID AS [ServiceTypeID],
			PC.Name AS [ServiceType],			  
			SRS.ID AS [StatusID],
			CASE ISNULL(SR.IsRedispatched,0) WHEN 1 THEN SRS.Name + '^' ELSE SRS.Name END AS [Status],
			SR.ServiceRequestPriorityID AS [PriorityID],  
			SRP.Name AS [Priority],			
			V.Name AS [ISPName], 
			V.VendorNumber, 
			PO.PurchaseOrderNumber AS [PONumber], 
			POS.ID AS PurchaseOrderStatusID,
			POS.Name AS PurchaseOrderStatus,
			PO.PurchaseOrderAmount,			   
			C.AssignedToUserID,
			SR.NextActionAssignedToUserID,			
			PO.IsGOA,
			SR.IsRedispatched,
			SR.IsPossibleTow,
			C.VehicleYear,
			C.VehicleMake,
			C.VehicleMakeOther,
			C.VehicleModel,
			C.VehicleModelOther,
			PO.IsPayByCompanyCreditCard
			
	FROM	ServiceRequest SR WITH (NOLOCK)	
	--LEFT JOIN	@tmpWhereClause TMP ON 1=1	
	JOIN	[ServiceRequestStatus] SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID  
	LEFT JOIN	[ServiceRequestPriority] SRP WITH (NOLOCK) ON SR.ServiceRequestPriorityID = SRP.ID 
	JOIN	[Case] C WITH (NOLOCK) on C.ID = SR.CaseID
	JOIN	dbo.fnc_GetProgramsForUser(@userID) P ON C.ProgramID = P.ProgramID  
	
	JOIN	[Client] CL WITH (NOLOCK) ON P.ClientID = CL.ID
	JOIN	[Member] M WITH (NOLOCK) ON C.MemberID = M.ID  
	LEFT JOIN	Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID  
	LEFT JOIN [ProductCategory] PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID   
	LEFT JOIN [VehicleType] VT WITH (NOLOCK) ON VT.ID = C.VehicleTypeID
	LEFT JOIN (  
			SELECT ROW_NUMBER() OVER (PARTITION BY ServiceRequestID ORDER BY CreateDate DESC) AS RowNum,  
			ID,  
			PurchaseOrderNumber, 
			PurchaseOrderStatusID, 
			ServiceRequestID,  
			VendorLocationID,
			PurchaseOrderAmount,
			TPO.IsGOA,
			TPO.IsPayByCompanyCreditCard,
			TPO.CreateBy,
			TPO.ModifyBy			   
			FROM PurchaseOrder TPO WITH (NOLOCK)
			--LEFT JOIN	 @tmpWhereClause TMP   ON 1=1
			WHERE ( (@IDType IS NULL) OR (@IDType <> 'Purchase Order') OR (@IDType = 'Purchase Order' AND PurchaseOrderNumber = @IDValue))
	) PO ON SR.ID = PO.ServiceRequestID AND PO.RowNum = 1  
	
	LEFT JOIN	PurchaseOrderStatus POS WITH (NOLOCK) ON PO.PurchaseOrderStatusID = POS.ID
	LEFT JOIN	[NextAction] NA WITH (NOLOCK) ON SR.NextActionID=NA.ID 
	LEFT JOIN	[VendorLocation] VL WITH (NOLOCK) ON PO.VendorLocationID = VL.ID  
	LEFT JOIN	[Vendor] V WITH (NOLOCK) ON VL.VendorID = V.ID
	LEFT JOIN	#tmpVehicle TV ON (TV.MemberID IS NULL OR TV.MemberID = M.ID) 
	
	-- DEBUG:
	--SELECT * FROM @tmpWhereClause
	--SELECT * FROM #Raw
	
	-- Apply filter on the #Raw
	--INSERT INTO #Filtered 
	--		(
	--		RequestNumber,
	--		CaseID,
	--		ProgramID,
	--		Program,
	--		ClientID,
	--		Client,
	--		FirstName,
	--		LastName,
	--		MiddleName,
	--		Suffix,
	--		Prefix,
	--		MemberNumber,
	--		CreateDate,
	--		POCreateBy,
	--		POModifyBy,
	--		SRCreateBy,
	--		SRModifyBy,
	--		VIN,
	--		VehicleTypeID,
	--		VehicleType,
	--		ServiceTypeID,
	--		ServiceType,
	--		StatusID,
	--		[Status],
	--		PriorityID,
	--		[Priority],
	--		ISPName,
	--		VendorNumber,
	--		PONumber,
	--		PurchaseOrderStatusID,
	--		PurchaseOrderStatus,
	--		PurchaseOrderAmount,
	--		AssignedToUserID,
	--		NextActionAssignedToUserID,
	--		IsGOA,
	--		IsRedispatched,
	--		IsPossibleTow,
	--		VehicleYear,
	--		VehicleMake,
	--		VehicleMakeOther,
	--		VehicleModel,
	--		VehicleModelOther,
	--		PaymentByCard
	--		)
				
	--SELECT	RequestNumber,
	--		CaseID,
	--		ProgramID,
	--		Program,
	--		ClientID,
	--		Client,
	--		FirstName,
	--		R.LastName,
	--		MiddleName,
	--		Suffix,
	--		Prefix,
	--		MemberNumber,
	--		CreateDate,
	--		POCreateBy,
	--		POModifyBy,
	--		SRCreateBy,
	--		SRModifyBy,
	--		VIN,
	--		VehicleTypeID,
	--		R.VehicleType,
	--		ServiceTypeID, 
	--		ServiceType,		 
	--		StatusID,
	--		[Status],
	--		PriorityID,
	--		[Priority],
	--		ISPName,
	--		VendorNumber,
	--		PONumber,
	--		PurchaseOrderStatusID,
	--		PurchaseOrderStatus, 
	--		PurchaseOrderAmount,
	--		AssignedToUserID,
	--		NextActionAssignedToUserID,
	--		R.IsGOA,
	--		R.IsRedispatched,
	--		R.IsPossibleTow,
	--		R.VehicleYear,
	--		R.VehicleMake,
	--		R.VehicleMakeOther,
	--		R.VehicleModel,
	--		R.VehicleModelOther,
	--		R.PaymentByCard	
	--FROM	#Raw R
	--LEFT JOIN	@tmpWhereClause T ON 1=1
	WHERE	
	(
	
		-- IDs
		(
			(@IDType IS NULL)
			OR
			(@IDType = 'Purchase Order' AND PO.PurchaseOrderNumber = CONVERT(NVARCHAR(50),@IDValue))
			OR
			(@IDType = 'Service Request' AND @IDValue = CONVERT(NVARCHAR(50),SR.ID))
			OR
			(@IDType = 'ISP' AND V.VendorNumber =  CONVERT(NVARCHAR(50),@IDValue) )
			OR
			(@IDType = 'Member' AND MS.MembershipNumber = CONVERT(NVARCHAR(50),@IDValue))			 
			OR
			(@IDType = 'VIN' AND TV.VIN = CONVERT(NVARCHAR(50),@IDValue))
		)
	
		AND
		-- Names
		(
				(@FilterType IS NULL)
				OR
				(@FilterType = 'Is equal to' 
					AND (
							(@NameType = 'ISP' AND V.Name = @NameValue)
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName = @NameValue))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName = @LastName))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy = @NameValue 
																				OR 
																				SR.ModifyBy = @NameValue 
																				OR 
																				PO.CreateBy = @NameValue 
																				OR 
																				PO.ModifyBy = @NameValue 
																			)) )
											
											)
							)		
						)
				)
				OR
				(@FilterType = 'Starts with' 
					AND (
							(@NameType = 'ISP' AND V.Name LIKE  @NameValue + '%')
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName LIKE  @NameValue + '%'))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName LIKE  @LastName + '%'))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy LIKE  @NameValue + '%' 
																				OR 
																				SR.ModifyBy LIKE  @NameValue + '%'
																				OR 
																				PO.CreateBy LIKE  @NameValue + '%'
																				OR 
																				PO.ModifyBy LIKE  @NameValue + '%'
																			)) )
											
											)
							)		
						)
				)
				OR
				(@FilterType = 'Contains' 
					AND (
							(@NameType = 'ISP' AND V.Name LIKE  '%' + @NameValue + '%')
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName LIKE  '%' + @NameValue + '%'))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName LIKE  '%' + @LastName + '%'))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy LIKE  '%' + @NameValue + '%' 
																				OR 
																				SR.ModifyBy LIKE  '%' + @NameValue + '%' 
																				OR 
																				PO.CreateBy LIKE  '%' + @NameValue + '%' 
																				OR 
																				PO.ModifyBy LIKE  '%' + @NameValue + '%' 
																			)) )
											
											)
							)		
						)
				)
				OR
				(@FilterType = 'Ends with' 
					AND (
							(@NameType = 'ISP' AND V.Name LIKE  '%' + @NameValue)
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName LIKE  '%' + @NameValue))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName LIKE  '%' + @LastName))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy LIKE  '%' + @NameValue 
																				OR 
																				SR.ModifyBy LIKE  '%' + @NameValue 
																				OR 
																				PO.CreateBy LIKE  '%' + @NameValue 
																				OR 
																				PO.ModifyBy LIKE  '%' + @NameValue 
																			)) )
											
											)
							)		
						)
				)
			
		)
	
		AND
		-- Date Range
		(
				(@Preset IS NOT NULL AND	(
											(@Preset = 'Last 7 days' AND DATEDIFF(WK,SR.CreateDate,GETDATE()) <= 1)
											OR
											(@Preset = 'Last 30 days' AND DATEDIFF(M,SR.CreateDate,GETDATE()) <= 1)
											OR
											(@Preset = 'Last 90 days' AND DATEDIFF(M,SR.CreateDate,GETDATE()) <= 3)
											)
				)
				OR
				(
					(@Preset IS NULL AND	(	( @FromDate IS NULL OR (@FromDate IS NOT NULL AND SR.CreateDate >= @FromDate))
											AND
												( @ToDate IS NULL OR (@ToDate IS NOT NULL AND SR.CreateDate <= @ToDate))
											)
					)
				)
		)
		AND
		-- Clients
		(
				(	ISNULL(@strClients,'') = '' OR ( CL.ID IN (SELECT ID FROM @tmpClients) ))
		)
		AND
		-- Programs
		(
				(	ISNULL(@strPrograms,'') = '' OR ( P.ProgramID IN (SELECT ID FROM @tmpPrograms) ))
		)
		AND
		-- SR Statuses
		(
				(	ISNULL(@strServiceRequestStatuses,'') = '' OR ( SRS.ID IN (SELECT ID FROM @tmpServiceRequestStatuses) ))
		)
		AND
		-- Service types
		(
				(	ISNULL(@strServiceTypes,'') = '' OR ( PC.ID IN (SELECT ID FROM @tmpServiceTypes) ))
		)
		AND
		-- Special flags
		(
				( @IsGOA IS NULL OR (PO.IsGOA = @IsGOA))
				AND
				( @IsPossibleTow IS NULL OR (SR.IsPossibleTow = @IsPossibleTow))
				AND
				( @IsRedispatched IS NULL OR (SR.IsRedispatched = @IsRedispatched))
		)
		AND
		-- Vehicle
		(
				(@VehicleType IS NULL OR (C.VehicleTypeID = @VehicleType))
				AND
				(@VehicleYear IS NULL OR (C.VehicleYear = @VehicleYear))
				AND
				(@VehicleMake IS NULL OR ( (C.VehicleMake = @VehicleMake) OR (@VehicleMake = 'Other' AND C.VehicleMake = 'Other' AND C.VehicleMakeOther = @VehicleMakeOther ) ) )
				AND
				(@VehicleModel IS NULL OR ( (C.VehicleModel = @VehicleModel) OR (@VehicleModel = 'Other' AND C.VehicleModel = 'Other' AND C.VehicleModelOther = @VehicleModelOther) ) )
		)
		AND
		-- Payment Type
		(
				( @PaymentByCheque IS NULL OR ( @PaymentByCheque = 1 AND PO.IsPayByCompanyCreditCard = 0 AND PO.PurchaseOrderAmount > 0 ) )
				AND
				( @PaymentByCard IS NULL OR ( @PaymentByCard = 1 AND PO.IsPayByCompanyCreditCard = 1 AND PO.PurchaseOrderAmount > 0 ) )
				AND
				( @MemberPaid IS NULL OR ( @MemberPaid = 1 AND POS.Name = 'Issue-Paid' AND PO.PurchaseOrderAmount > 0 ))
		)
		AND
		-- PurchaseOrder status
		(
				(	ISNULL(@strPOStatuses,'') = '' OR ( PO.PurchaseOrderStatusID IN (SELECT ID FROM @tmpPOStatuses) ))
		)
	)
	
	-- DEBUG:
	--SELECT 'Filtered', * FROM #Filtered
	
	-- Format the data [ Member name, vehiclemake, model, etc]
	INSERT INTO #Formatted 
			(
			RequestNumber,
			CaseID,
			ProgramID,
			Program,
			ClientID,
			Client,
			MemberName,
			MemberNumber,
			CreateDate,
			POCreateBy,
			POModifyBy,
			SRCreateBy,
			SRModifyBy,
			VIN,
			VehicleTypeID,
			VehicleType,
			ServiceTypeID,
			ServiceType,
			StatusID,
			[Status],
			PriorityID,
			[Priority],
			ISPName,
			VendorNumber,
			PONumber,
			PurchaseOrderStatusID,
			PurchaseOrderStatus,
			PurchaseOrderAmount,
			AssignedToUserID,
			NextActionAssignedToUserID,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleYear,
			VehicleMake,			
			VehicleModel,			
			PaymentByCard
			)
				
	SELECT	RequestNumber,
			CaseID,
			ProgramID,
			Program,
			ClientID,
			Client,
			REPLACE(RTRIM( 
				COALESCE(FirstName, '') + 
				COALESCE(' ' + left(MiddleName,1), '') + 
				COALESCE(' ' + LastName, '') +
				COALESCE(' ' + Suffix, '')
				), ' ', ' ') AS MemberName, 
			MemberNumber,
			CreateDate,
			POCreateBy,
			POModifyBy,
			SRCreateBy,
			SRModifyBy,
			VIN,
			VehicleTypeID,
			VehicleType,
			ServiceTypeID,
			ServiceType,
			StatusID,
			[Status],
			PriorityID,
			[Priority],
			ISPName,
			VendorNumber,
			PONumber,
			PurchaseOrderStatusID,
			PurchaseOrderStatus,
			PurchaseOrderAmount,
			AssignedToUserID,
			NextActionAssignedToUserID,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleYear,
			CASE WHEN VehicleMake = 'Other' THEN VehicleMakeOther ELSE VehicleMake END AS VehicleMake,
			CASE WHEN VehicleModel = 'Other' THEN VehicleModelOther ELSE VehicleModel END AS VehicleModel,			
			PaymentByCard	
	FROM	#Filtered R
	
	
	
	-- Apply sorting
	INSERT INTO #Sorted 
			(
			RequestNumber,
			CaseID,
			ProgramID,
			Program,
			ClientID,
			Client,
			MemberName,
			MemberNumber,
			CreateDate,
			POCreateBy,
			POModifyBy,
			SRCreateBy,
			SRModifyBy,
			VIN,
			VehicleTypeID,
			VehicleType,
			ServiceTypeID,
			ServiceType,
			StatusID,
			[Status],
			PriorityID,
			[Priority],
			ISPName,
			VendorNumber,
			PONumber,
			PurchaseOrderStatusID,
			PurchaseOrderStatus,
			PurchaseOrderAmount,
			AssignedToUserID,
			NextActionAssignedToUserID,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleYear,
			VehicleMake,			
			VehicleModel,			
			PaymentByCard
			)
				
	SELECT	RequestNumber,
			CaseID,
			ProgramID,
			Program,
			ClientID,
			Client,
			MemberName, 
			MemberNumber,
			CreateDate,
			POCreateBy,
			POModifyBy,
			SRCreateBy,
			SRModifyBy,
			VIN,
			VehicleTypeID,
			VehicleType,
			ServiceTypeID,
			ServiceType,
			StatusID,
			[Status],
			PriorityID,
			[Priority],
			ISPName,
			VendorNumber,
			PONumber,
			PurchaseOrderStatusID,
			PurchaseOrderStatus,
			PurchaseOrderAmount,
			AssignedToUserID,
			NextActionAssignedToUserID,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleYear,
			VehicleMake,
			VehicleModel,			
			PaymentByCard	
	FROM	#Formatted F
	ORDER BY     
		CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'ASC'    
		THEN F.RequestNumber END ASC,     
		CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'DESC'    
		THEN F.RequestNumber END DESC ,
		
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,
		
		CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'    
		THEN F.CreateDate END ASC,     
		CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'    
		THEN F.CreateDate END DESC ,
		
		CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'    
		THEN F.MemberName END ASC,     
		CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'    
		THEN F.MemberName END DESC ,
		
		CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'ASC'    
		THEN F.VehicleType END ASC,     
		CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'DESC'    
		THEN F.VehicleType END DESC ,
		
		CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'ASC'    
		THEN F.ServiceType END ASC,     
		CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'DESC'    
		THEN F.ServiceType END DESC ,
		
		CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'    
		THEN F.[Status] END ASC,     
		CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'    
		THEN F.[Status] END DESC ,
		
		CASE WHEN @sortColumn = 'ISP' AND @sortOrder = 'ASC'    
		THEN F.[ISPName] END ASC,     
		CASE WHEN @sortColumn = 'ISP' AND @sortOrder = 'DESC'    
		THEN F.ISPName END DESC ,
		
		CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'    
		THEN F.PONumber END ASC,     
		CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'    
		THEN F.PONumber END DESC ,
		
		CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'ASC'    
		THEN F.PurchaseOrderStatus END ASC,     
		CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'DESC'    
		THEN F.PurchaseOrderStatus END DESC ,
		
		CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'ASC'    
		THEN F.PurchaseOrderAmount END ASC,     
		CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'DESC'    
		THEN F.PurchaseOrderAmount END DESC
		
	
	 
	SET @totalRows = 0  
	SELECT @totalRows = MAX(RowNum) FROM #Sorted  
	SET @endInd = @startInd + @pageSize - 1  
	IF @startInd > @totalRows  
	BEGIN  
	 DECLARE @numOfPages INT  
	 SET @numOfPages = @totalRows / @pageSize  
	IF @totalRows % @pageSize > 1  
	BEGIN  
	 SET @numOfPages = @numOfPages + 1  
	END  
	 SET @startInd = ((@numOfPages - 1) * @pageSize) + 1  
	 SET @endInd = @numOfPages * @pageSize  
	END  
	
	-- Take the required set (say 10 out of "n").	
	SELECT @totalRows AS TotalRows, * FROM #Sorted F WHERE F.RowNum BETWEEN @startInd AND @endInd
	
	DROP TABLE #Raw
	DROP TABLE #Filtered
	DROP TABLE #Formatted
	DROP TABLE #Sorted

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
*  ---- for int, money, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Location_PO_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Location_PO_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC [dms_Vendor_Location_PO_List_Get] @VendorLocationID =356
   -- EXEC [dms_Vendor_Location_PO_List_Get] @VendorLocationID =356  
 CREATE PROCEDURE [dbo].[dms_Vendor_Location_PO_List_Get](   
   @whereClauseXML XML = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10    
 , @sortColumn nvarchar(100)  = ''   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @VendorLocationID INT = null  
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
 CheckClearedDate datetime  NULL,  
 InvoiceReceivedDate datetime NULL ,  
 InvoiceReceiveMethod nvarchar(100) NULL ,  
 InvoiceToBePaidDate datetime NULL ,  
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
 InvoiceToBePaidDate datetime NULL,  
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
 T.c.value('@InvoiceReceiveMethodValue','datetime')  ,  
 ISNULL(T.c.value('@InvoiceToBePaidDateOperator','INT'),-1),  
 T.c.value('@InvoiceToBePaidDateValue','datetime'),  
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
ON VI.PurchaseOrderID = PO.ID  
LEFT OUTER JOIN VendorInvoiceStatus VIS  
ON VIS.ID = VI.VendorInvoiceStatusID  
LEFT OUTER JOIN ContactMethod CM  
ON CM.ID=VI.ReceiveContactMethodID  
WHERE PO.IsActive = 1  
AND VL.ID = @VendorLocationID  
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
  THEN T.InvoiceToBePaidDate END DESC,  
    
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
	ON ACH.VendorID = V.ID
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
	ON ACH.VendorID = V.ID
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

GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_servicerequest_history_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_servicerequest_history_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = '<ROW><Filter IDType="ServiceRequest" IDValue="1234" NameType="" NameValue="" LastName="" FilterType = "StartsWith" FromDate = "" ToDate = "" Preset ="" Clients ="1" Programs ="" ServiceRequestStatuses = "" ServiceTypes ="" IsGOA = "" IsRedispatched = "" IsPossibleTow ="" VehicleType ="1" VehicleYear ="2012" VehicleMake = "" VehicleModel = "" PaymentByCheque = "" PaymentByCard = "" MemberPaid ="" POStatuses =""/></ROW>', @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
-- EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = NULL, @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
-- EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = '<ROW><Filter IDType="Service Request" IDValue="2"/></ROW>', @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'

CREATE PROCEDURE [dbo].[dms_servicerequest_history_list]( 
	@whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10   
 , @sortColumn nvarchar(100)  = 'RequestNumber'   
 , @sortOrder nvarchar(100) = 'ASC'
 , @userID UNIQUEIDENTIFIER = NULL
) 
AS
BEGIN
	
	SET FMTONLY OFF;
	-- Temporary tables to hold the results until the final resultset.
	CREATE TABLE #Raw	
	(
		RequestNumber INT NOT NULL,
		CaseID INT NOT NULL,
		ProgramID INT NULL,
		Program NVARCHAR(50) NULL,
		ClientID INT NULL,
		Client NVARCHAR(50) NULL,
		FirstName NVARCHAR(50)  NULL ,    
		LastName NVARCHAR(50)  NULL ,  
		MiddleName NVARCHAR(50)  NULL ,  
		Suffix NVARCHAR(50)  NULL ,    
		Prefix NVARCHAR(50)  NULL ,
		MemberNumber NVARCHAR(50) NULL, 
		CreateDate DATETIME NULL,
		POCreateBy NVARCHAR(50) NULL,
		POModifyBy NVARCHAR(50) NULL,
		SRCreateBy NVARCHAR(50) NULL,
		SRModifyBy NVARCHAR(50) NULL,
		VIN NVARCHAR(50) NULL,
		VehicleTypeID INT NULL,
		VehicleType NVARCHAR(50) NULL,
		ServiceTypeID INT NULL, 
		ServiceType nvarchar(100) NULL,		 
		StatusID INT NULL,
		[Status] NVARCHAR(100) NULL,
		PriorityID INT NULL,
		[Priority] NVARCHAR(100) NULL,
		ISPName NVARCHAR(255) NULL,
		VendorNumber NVARCHAR(50) NULL,
		PONumber NVARCHAR(50) NULL,
		PurchaseOrderStatusID INT NULL,
		PurchaseOrderStatus NVARCHAR(50) NULL, 
		PurchaseOrderAmount money NULL,
		AssignedToUserID INT NULL,
		NextActionAssignedToUserID INT NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow BIT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,
		VehicleMakeOther NVARCHAR(255) NULL,
		VehicleModel NVARCHAR(255) NULL,
		VehicleModelOther NVARCHAR(255) NULL,		
		PaymentByCard BIT NULL
	)
	
	CREATE TABLE #Filtered	
	(
		RequestNumber INT NOT NULL,
		CaseID INT NOT NULL,
		ProgramID INT NULL,
		Program NVARCHAR(50) NULL,
		ClientID INT NULL,
		Client NVARCHAR(50) NULL,
		FirstName NVARCHAR(50)  NULL ,    
		LastName NVARCHAR(50)  NULL ,  
		MiddleName NVARCHAR(50)  NULL ,  
		Suffix NVARCHAR(50)  NULL ,    
		Prefix NVARCHAR(50)  NULL , 
		MemberNumber NVARCHAR(50) NULL,
		CreateDate DATETIME NULL,
		POCreateBy NVARCHAR(50) NULL,
		POModifyBy NVARCHAR(50) NULL,
		SRCreateBy NVARCHAR(50) NULL,
		SRModifyBy NVARCHAR(50) NULL,
		VIN NVARCHAR(50) NULL,
		VehicleTypeID INT NULL,
		VehicleType NVARCHAR(50) NULL,
		ServiceTypeID INT NULL, 
		ServiceType nvarchar(100) NULL,		 
		StatusID INT NULL,
		[Status] NVARCHAR(100) NULL,
		PriorityID INT NULL,
		[Priority] NVARCHAR(100) NULL,
		ISPName NVARCHAR(255) NULL,
		VendorNumber NVARCHAR(50) NULL,
		PONumber NVARCHAR(50) NULL,
		PurchaseOrderStatusID INT NULL,
		PurchaseOrderStatus NVARCHAR(50) NULL, 
		PurchaseOrderAmount money NULL,
		AssignedToUserID INT NULL,
		NextActionAssignedToUserID INT NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow BIT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,
		VehicleMakeOther NVARCHAR(255) NULL,
		VehicleModel NVARCHAR(255) NULL,
		VehicleModelOther NVARCHAR(255) NULL,		
		PaymentByCard BIT NULL
	)
	
	CREATE TABLE #Formatted	
	(
		RequestNumber INT NOT NULL,
		CaseID INT NOT NULL,
		ProgramID INT NULL,
		Program NVARCHAR(50) NULL,
		ClientID INT NULL,
		Client NVARCHAR(50) NULL,
		MemberName NVARCHAR(255)  NULL ,
		MemberNumber NVARCHAR(50) NULL,    		
		CreateDate DATETIME NULL,
		POCreateBy NVARCHAR(50) NULL,
		POModifyBy NVARCHAR(50) NULL,
		SRCreateBy NVARCHAR(50) NULL,
		SRModifyBy NVARCHAR(50) NULL,
		VIN NVARCHAR(50) NULL,
		VehicleTypeID INT NULL,
		VehicleType NVARCHAR(50) NULL,
		ServiceTypeID INT NULL, 
		ServiceType nvarchar(100) NULL,		 
		StatusID INT NULL,
		[Status] NVARCHAR(100) NULL,
		PriorityID INT NULL,
		[Priority] NVARCHAR(100) NULL,
		ISPName NVARCHAR(255) NULL,
		VendorNumber NVARCHAR(50) NULL,
		PONumber NVARCHAR(50) NULL,
		PurchaseOrderStatusID INT NULL,
		PurchaseOrderStatus NVARCHAR(50) NULL, 
		PurchaseOrderAmount money NULL,
		AssignedToUserID INT NULL,
		NextActionAssignedToUserID INT NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow BIT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,		
		VehicleModel NVARCHAR(255) NULL,		
		PaymentByCard BIT NULL
	)
	
	CREATE TABLE #Sorted
	(
		RowNum INT NOT NULL IDENTITY(1,1),
		RequestNumber INT NOT NULL,
		CaseID INT NOT NULL,
		ProgramID INT NULL,
		Program NVARCHAR(50) NULL,
		ClientID INT NULL,
		Client NVARCHAR(50) NULL,
		MemberName NVARCHAR(255)  NULL , 
		MemberNumber NVARCHAR(50) NULL,   		
		CreateDate DATETIME NULL,
		POCreateBy NVARCHAR(50) NULL,
		POModifyBy NVARCHAR(50) NULL,
		SRCreateBy NVARCHAR(50) NULL,
		SRModifyBy NVARCHAR(50) NULL,
		VIN NVARCHAR(50) NULL,
		VehicleTypeID INT NULL,
		VehicleType NVARCHAR(50) NULL,
		ServiceTypeID INT NULL, 
		ServiceType nvarchar(100) NULL,		 
		StatusID INT NULL,
		[Status] NVARCHAR(100) NULL,
		PriorityID INT NULL,
		[Priority] NVARCHAR(100) NULL,
		ISPName NVARCHAR(255) NULL,
		VendorNumber NVARCHAR(50) NULL,
		PONumber NVARCHAR(50) NULL,
		PurchaseOrderStatusID INT NULL,
		PurchaseOrderStatus NVARCHAR(50) NULL, 
		PurchaseOrderAmount money NULL,
		AssignedToUserID INT NULL,
		NextActionAssignedToUserID INT NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow BIT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,
		VehicleModel NVARCHAR(255) NULL,
		PaymentByCard BIT NULL
	)
	
	CREATE TABLE #tmpVehicle
	(
		VIN NVARCHAR(50) NULL,
		MemberID INT NULL,
		MembershipID INT NULL
	)
	
	DECLARE @totalRows INT = 0

	DECLARE @tmpWhereClause TABLE
	(	
		IDType NVARCHAR(255) NULL,
		IDValue NVARCHAR(255) NULL,
		NameType NVARCHAR(255) NULL,
		NameValue NVARCHAR(255) NULL,
		LastName NVARCHAR(255) NULL, -- If name type = Member, then firstname goes into namevalue and last name goes into this field.
		FilterType NVARCHAR(100) NULL,
		FromDate DATETIME NULL,
		ToDate DATETIME NULL,
		Preset NVARCHAR(100) NULL,
		Clients NVARCHAR(MAX) NULL,
		Programs NVARCHAR(MAX) NULL,
		ServiceRequestStatuses NVARCHAR(MAX) NULL,
		ServiceTypes NVARCHAR(MAX) NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow  BIT NULL,		
		VehicleType INT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,
		VehicleMakeOther NVARCHAR(255) NULL,
		VehicleModel NVARCHAR(255) NULL,
		VehicleModelOther NVARCHAR(255) NULL,
		PaymentByCheque BIT NULL,
		PaymentByCard BIT NULL,
		MemberPaid BIT NULL,
		POStatuses NVARCHAR(MAX) NULL
	)
	
	DECLARE @IDType NVARCHAR(255) ,
			@IDValue NVARCHAR(255) ,
			@NameType NVARCHAR(255) ,
			@NameValue NVARCHAR(255) ,
			@LastName NVARCHAR(255) , 
			@FilterType NVARCHAR(100) ,
			@FromDate DATETIME ,
			@ToDate DATETIME ,
			@Preset NVARCHAR(100) ,
			@Clients NVARCHAR(MAX) ,
			@Programs NVARCHAR(MAX) ,
			@ServiceRequestStatuses NVARCHAR(MAX) ,
			@ServiceTypes NVARCHAR(MAX) ,
			@IsGOA BIT ,
			@IsRedispatched BIT ,
			@IsPossibleTow  BIT ,		
			@VehicleType INT ,
			@VehicleYear INT ,
			@VehicleMake NVARCHAR(255) ,
			@VehicleMakeOther NVARCHAR(255) ,
			@VehicleModel NVARCHAR(255) ,
			@VehicleModelOther NVARCHAR(255) ,
			@PaymentByCheque BIT ,
			@PaymentByCard BIT ,
			@MemberPaid BIT ,
			@POStatuses NVARCHAR(MAX) 
	
	DECLARE @idoc int
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML 
	
	INSERT INTO @tmpWhereClause  
	SELECT	IDType,
			IDValue,
			NameType,
			NameValue,
			LastName,
			FilterType,
			FromDate,
			ToDate,
			Preset,
			Clients,
			Programs,
			ServiceRequestStatuses,
			ServiceTypes,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleType,
			VehicleYear,
			VehicleMake,
			VehicleMakeOther,
			VehicleModel,
			VehicleModelOther,
			PaymentByCheque,
			PaymentByCard,
			MemberPaid,
			POStatuses
	FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH ( 
	
			IDType NVARCHAR(255) ,
			IDValue NVARCHAR(255) ,
			NameType NVARCHAR(255) ,
			NameValue NVARCHAR(255) ,
			LastName NVARCHAR(255) ,
			FilterType NVARCHAR(100) ,
			FromDate DATETIME ,
			ToDate DATETIME ,
			Preset NVARCHAR(100) ,
			Clients NVARCHAR(MAX) ,
			Programs NVARCHAR(MAX) ,
			ServiceRequestStatuses NVARCHAR(MAX) ,
			ServiceTypes NVARCHAR(MAX) ,
			IsGOA BIT,
			IsRedispatched BIT,
			IsPossibleTow BIT,			
			VehicleType INT ,
			VehicleYear INT ,
			VehicleMake NVARCHAR(255) ,
			VehicleMakeOther NVARCHAR(255) ,
			VehicleModel NVARCHAR(255) ,
			VehicleModelOther NVARCHAR(255) ,
			PaymentByCheque BIT ,
			PaymentByCard BIT ,
			MemberPaid BIT ,
			POStatuses NVARCHAR(MAX) 	
	)
	
	-- DEBUG:
	--SELECT * FROM @tmpWhereClause
	
	DECLARE @strClients NVARCHAR(MAX)
	DECLARE @tmpClients TABLE
	(
		ID INT NOT NULL
	)	
	DECLARE @strPrograms NVARCHAR(MAX)
	DECLARE @tmpPrograms TABLE
	(
		ID INT NOT NULL
	)
	DECLARE @strServiceRequestStatuses NVARCHAR(MAX)
	DECLARE @tmpServiceRequestStatuses TABLE
	(
		ID INT NOT NULL
	)
	
	DECLARE @strServiceTypes NVARCHAR(MAX)
	DECLARE @tmpServiceTypes TABLE
	(
		ID INT NOT NULL
	)
	DECLARE @strPOStatuses NVARCHAR(MAX)
	DECLARE @tmpPOStatuses TABLE
	(
		ID INT NOT NULL
	)
	
	-- Extract some of the values into separate tables for ease of processing.
	SELECT	@strClients = Clients,
			@strPOStatuses = POStatuses,
			@strPrograms = Programs,
			@strServiceRequestStatuses = ServiceRequestStatuses,
			@strServiceTypes = ServiceTypes			
	FROM	@tmpWhereClause
	
	-- Clients
	INSERT INTO @tmpClients
	SELECT item FROM fnSplitString(@strClients,',')
	
	-- Programs
	INSERT INTO @tmpPrograms
	SELECT item FROM fnSplitString(@strPrograms,',')
	
	-- POStatuses
	INSERT INTO @tmpPOStatuses
	SELECT item FROM fnSplitString(@strPOStatuses,',')
	
	-- Service request statuses
	INSERT INTO @tmpServiceRequestStatuses
	SELECT item FROM fnSplitString(@strServiceRequestStatuses,',')
	
	-- Service types
	INSERT INTO @tmpServiceTypes
	SELECT item FROM fnSplitString(@strServiceTypes,',')
	
	
	SELECT	@IDType = T.IDType,			
			@IDValue = T.IDValue,
			@NameType = T.NameType,
			@NameValue = T.NameValue,
			@LastName = T.LastName, 
			@FilterType = T.FilterType,
			@FromDate = T.FromDate,
			@ToDate = T.ToDate,
			@Preset = T.Preset,
			@IsGOA = T.IsGOA,
			@IsRedispatched = T.IsRedispatched,
			@IsPossibleTow  = T.IsPossibleTow,		
			@VehicleType = T.VehicleType,
			@VehicleYear = T.VehicleYear,
			@VehicleMake = T.VehicleMake,
			@VehicleMakeOther = T.VehicleMakeOther,
			@VehicleModel = T.VehicleModel,
			@VehicleModelOther = T.VehicleModelOther,
			@PaymentByCheque = T.PaymentByCheque,
			@PaymentByCard = T.PaymentByCard ,
			@MemberPaid = T.MemberPaid
	FROM	@tmpWhereClause T
	
	DECLARE @vinParam NVARCHAR(50) = NULL
	SELECT	@vinParam = IDValue 
	FROM	@tmpWhereClause
	WHERE	IDType = 'VIN'
	
	IF ISNULL(@vinParam,'') <> ''
	BEGIN
	
		INSERT INTO #tmpVehicle
		SELECT	V.VIN,
				V.MemberID,
				V.MembershipID
		FROM	Vehicle V WITH (NOLOCK)
		WHERE	V.VIN = @vinParam
		--V.VIN LIKE '%' + @vinParam + '%'
		
	END
	
	INSERT INTO #Filtered
	SELECT  
			--DISTINCT  
			SR.ID AS [RequestNumber],  
			SR.CaseID AS [Case],
			P.ProgramID,
			P.ProgramName AS [Program],
			CL.ID AS ClientID,
			CL.Name AS [Client], 			
			M.FirstName,
			M.LastName,
			M.MiddleName,
			M.Suffix,
			M.Prefix,   
			MS.MembershipNumber AS MemberNumber,  			
			SR.CreateDate,
			PO.CreateBy,
			PO.ModifyBy,
			SR.CreateBy,
			SR.ModifyBy,
			TV.VIN,
			VT.ID As VehicleTypeID,
			VT.Name AS VehicleType,						
			PC.ID AS [ServiceTypeID],
			PC.Name AS [ServiceType],			  
			SRS.ID AS [StatusID],
			CASE ISNULL(SR.IsRedispatched,0) WHEN 1 THEN SRS.Name + '^' ELSE SRS.Name END AS [Status],
			SR.ServiceRequestPriorityID AS [PriorityID],  
			SRP.Name AS [Priority],			
			V.Name AS [ISPName], 
			V.VendorNumber, 
			PO.PurchaseOrderNumber AS [PONumber], 
			POS.ID AS PurchaseOrderStatusID,
			POS.Name AS PurchaseOrderStatus,
			PO.PurchaseOrderAmount,			   
			C.AssignedToUserID,
			SR.NextActionAssignedToUserID,			
			PO.IsGOA,
			SR.IsRedispatched,
			SR.IsPossibleTow,
			C.VehicleYear,
			C.VehicleMake,
			C.VehicleMakeOther,
			C.VehicleModel,
			C.VehicleModelOther,
			PO.IsPayByCompanyCreditCard
			
	FROM	ServiceRequest SR WITH (NOLOCK)	
	--LEFT JOIN	@tmpWhereClause TMP ON 1=1	
	JOIN	[ServiceRequestStatus] SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID  
	LEFT JOIN	[ServiceRequestPriority] SRP WITH (NOLOCK) ON SR.ServiceRequestPriorityID = SRP.ID 
	JOIN	[Case] C WITH (NOLOCK) on C.ID = SR.CaseID
	JOIN	dbo.fnc_GetProgramsForUser(@userID) P ON C.ProgramID = P.ProgramID  
	
	JOIN	[Client] CL WITH (NOLOCK) ON P.ClientID = CL.ID
	JOIN	[Member] M WITH (NOLOCK) ON C.MemberID = M.ID  
	LEFT JOIN	Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID  
	LEFT JOIN [ProductCategory] PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID   
	LEFT JOIN [VehicleType] VT WITH (NOLOCK) ON VT.ID = C.VehicleTypeID
	LEFT JOIN (  
			SELECT ROW_NUMBER() OVER (PARTITION BY ServiceRequestID ORDER BY CreateDate DESC) AS RowNum,  
			ID,  
			PurchaseOrderNumber, 
			PurchaseOrderStatusID, 
			ServiceRequestID,  
			VendorLocationID,
			PurchaseOrderAmount,
			TPO.IsGOA,
			TPO.IsPayByCompanyCreditCard,
			TPO.CreateBy,
			TPO.ModifyBy			   
			FROM PurchaseOrder TPO WITH (NOLOCK)
			--LEFT JOIN	 @tmpWhereClause TMP   ON 1=1
			WHERE ( (@IDType IS NULL) OR (@IDType <> 'Purchase Order') OR (@IDType = 'Purchase Order' AND PurchaseOrderNumber = @IDValue))
	) PO ON SR.ID = PO.ServiceRequestID AND PO.RowNum = 1  
	
	LEFT JOIN	PurchaseOrderStatus POS WITH (NOLOCK) ON PO.PurchaseOrderStatusID = POS.ID
	LEFT JOIN	[NextAction] NA WITH (NOLOCK) ON SR.NextActionID=NA.ID 
	LEFT JOIN	[VendorLocation] VL WITH (NOLOCK) ON PO.VendorLocationID = VL.ID  
	LEFT JOIN	[Vendor] V WITH (NOLOCK) ON VL.VendorID = V.ID
	LEFT JOIN	#tmpVehicle TV ON (TV.MemberID IS NULL OR TV.MemberID = M.ID) 
	
	-- DEBUG:
	--SELECT * FROM @tmpWhereClause
	--SELECT * FROM #Raw
	
	-- Apply filter on the #Raw
	--INSERT INTO #Filtered 
	--		(
	--		RequestNumber,
	--		CaseID,
	--		ProgramID,
	--		Program,
	--		ClientID,
	--		Client,
	--		FirstName,
	--		LastName,
	--		MiddleName,
	--		Suffix,
	--		Prefix,
	--		MemberNumber,
	--		CreateDate,
	--		POCreateBy,
	--		POModifyBy,
	--		SRCreateBy,
	--		SRModifyBy,
	--		VIN,
	--		VehicleTypeID,
	--		VehicleType,
	--		ServiceTypeID,
	--		ServiceType,
	--		StatusID,
	--		[Status],
	--		PriorityID,
	--		[Priority],
	--		ISPName,
	--		VendorNumber,
	--		PONumber,
	--		PurchaseOrderStatusID,
	--		PurchaseOrderStatus,
	--		PurchaseOrderAmount,
	--		AssignedToUserID,
	--		NextActionAssignedToUserID,
	--		IsGOA,
	--		IsRedispatched,
	--		IsPossibleTow,
	--		VehicleYear,
	--		VehicleMake,
	--		VehicleMakeOther,
	--		VehicleModel,
	--		VehicleModelOther,
	--		PaymentByCard
	--		)
				
	--SELECT	RequestNumber,
	--		CaseID,
	--		ProgramID,
	--		Program,
	--		ClientID,
	--		Client,
	--		FirstName,
	--		R.LastName,
	--		MiddleName,
	--		Suffix,
	--		Prefix,
	--		MemberNumber,
	--		CreateDate,
	--		POCreateBy,
	--		POModifyBy,
	--		SRCreateBy,
	--		SRModifyBy,
	--		VIN,
	--		VehicleTypeID,
	--		R.VehicleType,
	--		ServiceTypeID, 
	--		ServiceType,		 
	--		StatusID,
	--		[Status],
	--		PriorityID,
	--		[Priority],
	--		ISPName,
	--		VendorNumber,
	--		PONumber,
	--		PurchaseOrderStatusID,
	--		PurchaseOrderStatus, 
	--		PurchaseOrderAmount,
	--		AssignedToUserID,
	--		NextActionAssignedToUserID,
	--		R.IsGOA,
	--		R.IsRedispatched,
	--		R.IsPossibleTow,
	--		R.VehicleYear,
	--		R.VehicleMake,
	--		R.VehicleMakeOther,
	--		R.VehicleModel,
	--		R.VehicleModelOther,
	--		R.PaymentByCard	
	--FROM	#Raw R
	--LEFT JOIN	@tmpWhereClause T ON 1=1
	WHERE	
	(
	
		-- IDs
		(
			(@IDType IS NULL)
			OR
			(@IDType = 'Purchase Order' AND PO.PurchaseOrderNumber = CONVERT(NVARCHAR(50),@IDValue))
			OR
			(@IDType = 'Service Request' AND @IDValue = CONVERT(NVARCHAR(50),SR.ID))
			OR
			(@IDType = 'ISP' AND V.VendorNumber =  CONVERT(NVARCHAR(50),@IDValue) )
			OR
			(@IDType = 'Member' AND MS.MembershipNumber = CONVERT(NVARCHAR(50),@IDValue))			 
			OR
			(@IDType = 'VIN' AND TV.VIN = CONVERT(NVARCHAR(50),@IDValue))
		)
	
		AND
		-- Names
		(
				(@FilterType IS NULL)
				OR
				(@FilterType = 'Is equal to' 
					AND (
							(@NameType = 'ISP' AND V.Name = @NameValue)
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName = @NameValue))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName = @LastName))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy = @NameValue 
																				OR 
																				SR.ModifyBy = @NameValue 
																				OR 
																				PO.CreateBy = @NameValue 
																				OR 
																				PO.ModifyBy = @NameValue 
																			)) )
											
											)
							)		
						)
				)
				OR
				(@FilterType = 'Starts with' 
					AND (
							(@NameType = 'ISP' AND V.Name LIKE  @NameValue + '%')
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName LIKE  @NameValue + '%'))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName LIKE  @LastName + '%'))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy LIKE  @NameValue + '%' 
																				OR 
																				SR.ModifyBy LIKE  @NameValue + '%'
																				OR 
																				PO.CreateBy LIKE  @NameValue + '%'
																				OR 
																				PO.ModifyBy LIKE  @NameValue + '%'
																			)) )
											
											)
							)		
						)
				)
				OR
				(@FilterType = 'Contains' 
					AND (
							(@NameType = 'ISP' AND V.Name LIKE  '%' + @NameValue + '%')
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName LIKE  '%' + @NameValue + '%'))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName LIKE  '%' + @LastName + '%'))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy LIKE  '%' + @NameValue + '%' 
																				OR 
																				SR.ModifyBy LIKE  '%' + @NameValue + '%' 
																				OR 
																				PO.CreateBy LIKE  '%' + @NameValue + '%' 
																				OR 
																				PO.ModifyBy LIKE  '%' + @NameValue + '%' 
																			)) )
											
											)
							)		
						)
				)
				OR
				(@FilterType = 'Ends with' 
					AND (
							(@NameType = 'ISP' AND V.Name LIKE  '%' + @NameValue)
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName LIKE  '%' + @NameValue))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName LIKE  '%' + @LastName))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy LIKE  '%' + @NameValue 
																				OR 
																				SR.ModifyBy LIKE  '%' + @NameValue 
																				OR 
																				PO.CreateBy LIKE  '%' + @NameValue 
																				OR 
																				PO.ModifyBy LIKE  '%' + @NameValue 
																			)) )
											
											)
							)		
						)
				)
			
		)
	
		AND
		-- Date Range
		(
				(@Preset IS NOT NULL AND	(
											(@Preset = 'Last 7 days' AND DATEDIFF(WK,SR.CreateDate,GETDATE()) <= 1)
											OR
											(@Preset = 'Last 30 days' AND DATEDIFF(M,SR.CreateDate,GETDATE()) <= 1)
											OR
											(@Preset = 'Last 90 days' AND DATEDIFF(M,SR.CreateDate,GETDATE()) <= 3)
											)
				)
				OR
				(
					(@Preset IS NULL AND	(	( @FromDate IS NULL OR (@FromDate IS NOT NULL AND SR.CreateDate >= @FromDate))
											AND
												( @ToDate IS NULL OR (@ToDate IS NOT NULL AND SR.CreateDate <= @ToDate))
											)
					)
				)
		)
		AND
		-- Clients
		(
				(	ISNULL(@strClients,'') = '' OR ( CL.ID IN (SELECT ID FROM @tmpClients) ))
		)
		AND
		-- Programs
		(
				(	ISNULL(@strPrograms,'') = '' OR ( P.ProgramID IN (SELECT ID FROM @tmpPrograms) ))
		)
		AND
		-- SR Statuses
		(
				(	ISNULL(@strServiceRequestStatuses,'') = '' OR ( SRS.ID IN (SELECT ID FROM @tmpServiceRequestStatuses) ))
		)
		AND
		-- Service types
		(
				(	ISNULL(@strServiceTypes,'') = '' OR ( PC.ID IN (SELECT ID FROM @tmpServiceTypes) ))
		)
		AND
		-- Special flags
		(
				( @IsGOA IS NULL OR (PO.IsGOA = @IsGOA))
				AND
				( @IsPossibleTow IS NULL OR (SR.IsPossibleTow = @IsPossibleTow))
				AND
				( @IsRedispatched IS NULL OR (SR.IsRedispatched = @IsRedispatched))
		)
		AND
		-- Vehicle
		(
				(@VehicleType IS NULL OR (C.VehicleTypeID = @VehicleType))
				AND
				(@VehicleYear IS NULL OR (C.VehicleYear = @VehicleYear))
				AND
				(@VehicleMake IS NULL OR ( (C.VehicleMake = @VehicleMake) OR (@VehicleMake = 'Other' AND C.VehicleMake = 'Other' AND C.VehicleMakeOther = @VehicleMakeOther ) ) )
				AND
				(@VehicleModel IS NULL OR ( (C.VehicleModel = @VehicleModel) OR (@VehicleModel = 'Other' AND C.VehicleModel = 'Other' AND C.VehicleModelOther = @VehicleModelOther) ) )
		)
		AND
		-- Payment Type
		(
				( @PaymentByCheque IS NULL OR ( @PaymentByCheque = 1 AND PO.IsPayByCompanyCreditCard = 0 AND PO.PurchaseOrderAmount > 0 ) )
				AND
				( @PaymentByCard IS NULL OR ( @PaymentByCard = 1 AND PO.IsPayByCompanyCreditCard = 1 AND PO.PurchaseOrderAmount > 0 ) )
				AND
				( @MemberPaid IS NULL OR ( @MemberPaid = 1 AND POS.Name = 'Issue-Paid' AND PO.PurchaseOrderAmount > 0 ))
		)
		AND
		-- PurchaseOrder status
		(
				(	ISNULL(@strPOStatuses,'') = '' OR ( PO.PurchaseOrderStatusID IN (SELECT ID FROM @tmpPOStatuses) ))
		)
	)
	
	-- DEBUG:
	--SELECT 'Filtered', * FROM #Filtered
	
	-- Format the data [ Member name, vehiclemake, model, etc]
	INSERT INTO #Formatted 
			(
			RequestNumber,
			CaseID,
			ProgramID,
			Program,
			ClientID,
			Client,
			MemberName,
			MemberNumber,
			CreateDate,
			POCreateBy,
			POModifyBy,
			SRCreateBy,
			SRModifyBy,
			VIN,
			VehicleTypeID,
			VehicleType,
			ServiceTypeID,
			ServiceType,
			StatusID,
			[Status],
			PriorityID,
			[Priority],
			ISPName,
			VendorNumber,
			PONumber,
			PurchaseOrderStatusID,
			PurchaseOrderStatus,
			PurchaseOrderAmount,
			AssignedToUserID,
			NextActionAssignedToUserID,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleYear,
			VehicleMake,			
			VehicleModel,			
			PaymentByCard
			)
				
	SELECT	RequestNumber,
			CaseID,
			ProgramID,
			Program,
			ClientID,
			Client,
			REPLACE(RTRIM( 
				COALESCE(FirstName, '') + 
				COALESCE(' ' + left(MiddleName,1), '') + 
				COALESCE(' ' + LastName, '') +
				COALESCE(' ' + Suffix, '')
				), ' ', ' ') AS MemberName, 
			MemberNumber,
			CreateDate,
			POCreateBy,
			POModifyBy,
			SRCreateBy,
			SRModifyBy,
			VIN,
			VehicleTypeID,
			VehicleType,
			ServiceTypeID,
			ServiceType,
			StatusID,
			[Status],
			PriorityID,
			[Priority],
			ISPName,
			VendorNumber,
			PONumber,
			PurchaseOrderStatusID,
			PurchaseOrderStatus,
			PurchaseOrderAmount,
			AssignedToUserID,
			NextActionAssignedToUserID,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleYear,
			CASE WHEN VehicleMake = 'Other' THEN VehicleMakeOther ELSE VehicleMake END AS VehicleMake,
			CASE WHEN VehicleModel = 'Other' THEN VehicleModelOther ELSE VehicleModel END AS VehicleModel,			
			PaymentByCard	
	FROM	#Filtered R
	
	
	
	-- Apply sorting
	INSERT INTO #Sorted 
			(
			RequestNumber,
			CaseID,
			ProgramID,
			Program,
			ClientID,
			Client,
			MemberName,
			MemberNumber,
			CreateDate,
			POCreateBy,
			POModifyBy,
			SRCreateBy,
			SRModifyBy,
			VIN,
			VehicleTypeID,
			VehicleType,
			ServiceTypeID,
			ServiceType,
			StatusID,
			[Status],
			PriorityID,
			[Priority],
			ISPName,
			VendorNumber,
			PONumber,
			PurchaseOrderStatusID,
			PurchaseOrderStatus,
			PurchaseOrderAmount,
			AssignedToUserID,
			NextActionAssignedToUserID,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleYear,
			VehicleMake,			
			VehicleModel,			
			PaymentByCard
			)
				
	SELECT	RequestNumber,
			CaseID,
			ProgramID,
			Program,
			ClientID,
			Client,
			MemberName, 
			MemberNumber,
			CreateDate,
			POCreateBy,
			POModifyBy,
			SRCreateBy,
			SRModifyBy,
			VIN,
			VehicleTypeID,
			VehicleType,
			ServiceTypeID,
			ServiceType,
			StatusID,
			[Status],
			PriorityID,
			[Priority],
			ISPName,
			VendorNumber,
			PONumber,
			PurchaseOrderStatusID,
			PurchaseOrderStatus,
			PurchaseOrderAmount,
			AssignedToUserID,
			NextActionAssignedToUserID,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleYear,
			VehicleMake,
			VehicleModel,			
			PaymentByCard	
	FROM	#Formatted F
	ORDER BY     
		CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'ASC'    
		THEN F.RequestNumber END ASC,     
		CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'DESC'    
		THEN F.RequestNumber END DESC ,
		
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,
		
		CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'    
		THEN F.CreateDate END ASC,     
		CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'    
		THEN F.CreateDate END DESC ,
		
		CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'    
		THEN F.MemberName END ASC,     
		CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'    
		THEN F.MemberName END DESC ,
		
		CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'ASC'    
		THEN F.VehicleType END ASC,     
		CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'DESC'    
		THEN F.VehicleType END DESC ,
		
		CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'ASC'    
		THEN F.ServiceType END ASC,     
		CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'DESC'    
		THEN F.ServiceType END DESC ,
		
		CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'    
		THEN F.[Status] END ASC,     
		CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'    
		THEN F.[Status] END DESC ,
		
		CASE WHEN @sortColumn = 'ISP' AND @sortOrder = 'ASC'    
		THEN F.[ISPName] END ASC,     
		CASE WHEN @sortColumn = 'ISP' AND @sortOrder = 'DESC'    
		THEN F.ISPName END DESC ,
		
		CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'    
		THEN F.PONumber END ASC,     
		CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'    
		THEN F.PONumber END DESC ,
		
		CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'ASC'    
		THEN F.PurchaseOrderStatus END ASC,     
		CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'DESC'    
		THEN F.PurchaseOrderStatus END DESC ,
		
		CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'ASC'    
		THEN F.PurchaseOrderAmount END ASC,     
		CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'DESC'    
		THEN F.PurchaseOrderAmount END DESC
		
	
	 
	SET @totalRows = 0  
	SELECT @totalRows = MAX(RowNum) FROM #Sorted  
	SET @endInd = @startInd + @pageSize - 1  
	IF @startInd > @totalRows  
	BEGIN  
	 DECLARE @numOfPages INT  
	 SET @numOfPages = @totalRows / @pageSize  
	IF @totalRows % @pageSize > 1  
	BEGIN  
	 SET @numOfPages = @numOfPages + 1  
	END  
	 SET @startInd = ((@numOfPages - 1) * @pageSize) + 1  
	 SET @endInd = @numOfPages * @pageSize  
	END  
	
	-- Take the required set (say 10 out of "n").	
	SELECT @totalRows AS TotalRows, * FROM #Sorted F WHERE F.RowNum BETWEEN @startInd AND @endInd
	
	DROP TABLE #Raw
	DROP TABLE #Filtered
	DROP TABLE #Formatted
	DROP TABLE #Sorted

END

GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_PO_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_PO_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
 --EXEC [dbo].[dms_PO_list] @serviceRequestID = 1414, @sortColumn='PurchaseOrderPayStatusCode', @sortOrder = 'ASC'
 CREATE PROCEDURE [dbo].[dms_PO_list]( 
  @serviceRequestID INT = NULL
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON
 	
 	CREATE TABLE #tmpPODetails 	
 	(
 		ID INT NULL,
 		PONumber NVARCHAR(50) NULL,
 		PODate DATETIME NULL,
 		VendorName NVARCHAR(255) NULL,
 		POTotal MONEY NULL,
 		[Service] NVARCHAR(200) NULL,
 		POStatus NVARCHAR(50) NULL,
 		CancelReason NVARCHAR(255) NULL,
 		DataTransferDate DATETIME NULL,
 		ModifyDate DATETIME NULL,
 		OriginalPONumber NVARCHAR(50) NULL 	,
 		
 		InvoiceNumber nvarchar(100)  NULL ,
		InvoiceDate datetime  NULL ,
		InvoiceAmount money  NULL ,
		InvoiceStatus nvarchar(100)  NULL ,
		PaymentNumber nvarchar(100)  NULL ,
		PaymentDate datetime  NULL ,
		PaymentAmount money  NULL ,
		CheckClearedDate datetime  NULL ,
		InvoiceReceivedDate datetime NULL ,
		InvoiceReceiveMethod nvarchar(100) NULL ,
		InvoiceToBePaidDate datetime NULL,
		PurchaseOrderPayStatusCode nvarchar(255) NULL 	
 	)
 	
 	SET FMTONLY OFF;
 	
	INSERT INTO #tmpPODetails
	SELECT	  po.ID as ID
			, po.PurchaseOrderNumber as PONumber
			, po.IssueDate as PODate
			, v.Name as VendorName
			, po.TotalServiceAmount as POTotal
			, pc.[Description] as [Service]
			, pos.Name as POStatus
			--, cr.[Description] as CancelReason
			, CASE	WHEN po.CancellationReasonOther <> '' THEN po.CancellationReasonOther  
					WHEN po.GOAReasonOther <> '' THEN po.GOAReasonOther   
					ELSE cr.[Description]  
				END as CancelReason
			, po.DataTransferDate
			, po.ModifyDate
			,poo.PurchaseOrderNumber as OriginalPONumber
			, VI.InvoiceNumber
			, VI.InvoiceDate
			, VI.InvoiceAmount
			, VIS.Name AS [InvoiceStatus]
			--, VI.PaymentNumber
			,CASE 
			WHEN VI.PaymentTypeID = (SELECT ID From PaymentType WHERE Name = 'ACH') 
			THEN 'ACH' 
			ELSE VI.PaymentNumber
			END AS PaymentNumber
			, VI.PaymentDate 
			, VI.PaymentAmount 
			, VI.CheckClearedDate
			, VI.ReceivedDate
			, CM.Name
			, VI.ToBePaidDate
			,pops.[Description]
	FROM	PurchaseOrder po WITH (NOLOCK)
	LEFT OUTER JOIN PurchaseOrder poo WITH (NOLOCK) on poo.ID=po.OriginalPurchaseOrderID
	JOIN VendorLocation vl WITH (NOLOCK) on vl.ID = po.VendorLocationID
	JOIN Vendor v WITH (NOLOCK) on v.ID = vl.VendorID
	--Join PurchaseOrderDetail pod on pod.PurchaseOrderID = po.ID 
	--and pod.Sequence = 1
	--LEFT OUTER Join Product p on p.ID = pod.ProductID 
	LEFT OUTER JOIN Product p WITH (NOLOCK) on p.ID = po.ProductID 
	LEFT OUTER JOIN ProductCategory pc WITH (NOLOCK) on pc.ID = p.ProductCategoryID
	JOIN PurchaseOrderStatus pos WITH (NOLOCK) on pos.ID = po.PurchaseOrderStatusID
	LEFT JOIN PurchaseOrderPayStatusCode pops WITH (NOLOCK) on pops.ID = po.PayStatusCodeID
	LEFT JOIN PurchaseOrderCancellationReason cr WITH (NOLOCK) on cr.ID = po.CancellationReasonID
	LEFT OUTER JOIN VendorInvoice VI ON VI.PurchaseOrderID = PO.ID 
	LEFT OUTER JOIN VendorInvoiceStatus VIS ON VIS.ID = VI.VendorInvoiceStatusID 	
	LEFT OUTER JOIN ContactMethod CM ON CM.ID=VI.ReceiveContactMethodID
	WHERE	po.ServiceRequestID = @serviceRequestID and (po.IsActive = 1 or po.IsActive IS NULL )

SELECT W.*
FROM #tmpPODetails W
 ORDER BY 
     CASE WHEN @sortColumn IS NULL
     THEN W.ID END DESC,
	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'
	 THEN W.PONumber END ASC, 
	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'
	 THEN W.PONumber END DESC ,

	 CASE WHEN @sortColumn = 'PODate' AND @sortOrder = 'ASC'
	 THEN W.PODate END ASC, 
	 CASE WHEN @sortColumn = 'PODate' AND @sortOrder = 'DESC'
	 THEN W.PODate END DESC ,

	 CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'ASC'
	 THEN W.VendorName  END ASC, 
	 CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'DESC'
	 THEN W.VendorName  END DESC ,

	 CASE WHEN @sortColumn = 'POTotal' AND @sortOrder = 'ASC'
	 THEN W.POTotal END ASC, 
	 CASE WHEN @sortColumn = 'POTotal' AND @sortOrder = 'DESC'
	 THEN W.POTotal END DESC ,

	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'ASC'
	 THEN W.[Service] END ASC, 
	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'DESC'
	 THEN W.[Service] END DESC ,

	 CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'ASC'
	 THEN W.POStatus END ASC, 
	 CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'DESC'
	 THEN W.POStatus END DESC ,

	 CASE WHEN @sortColumn = 'CancelReason' AND @sortOrder = 'ASC'
	 THEN W.CancelReason END ASC, 
	 CASE WHEN @sortColumn = 'CancelReason' AND @sortOrder = 'DESC'
	 THEN W.CancelReason END DESC ,
	 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN W.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN W.InvoiceNumber END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'ASC'
	 THEN W.InvoiceDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'DESC'
	 THEN W.InvoiceDate END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'
	 THEN W.InvoiceAmount END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'
	 THEN W.InvoiceAmount END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'ASC'
	 THEN W.InvoiceStatus END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'DESC'
	 THEN W.InvoiceStatus END DESC ,

	 CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'ASC'
	 THEN W.PaymentNumber END ASC, 
	 CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'DESC'
	 THEN W.PaymentNumber END DESC ,

	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'ASC'
	 THEN W.PaymentDate END ASC, 
	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'DESC'
	 THEN W.PaymentDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'
	 THEN W.PaymentAmount END ASC, 
	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'
	 THEN W.PaymentAmount END DESC ,

	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'ASC'
	 THEN W.CheckClearedDate END ASC, 
	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'DESC'
	 THEN W.CheckClearedDate END DESC  ,

	 CASE WHEN @sortColumn = 'InvoiceReceivedDate' AND @sortOrder = 'ASC'
	 THEN W.InvoiceReceivedDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceReceivedDate' AND @sortOrder = 'DESC'
	 THEN W.InvoiceReceivedDate END DESC,

	 CASE WHEN @sortColumn = 'InvoiceReceiveMethod' AND @sortOrder = 'ASC'
	 THEN W.InvoiceReceiveMethod END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceReceiveMethod' AND @sortOrder = 'DESC'
	 THEN W.InvoiceReceiveMethod END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceToBePaidDate' AND @sortOrder = 'ASC'
	 THEN W.InvoiceToBePaidDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceToBePaidDate' AND @sortOrder = 'DESC'
	 THEN W.InvoiceToBePaidDate END DESC, 
	 
	 CASE WHEN @sortColumn = 'PurchaseOrderPayStatusCode' AND @sortOrder = 'ASC'
	 THEN W.PurchaseOrderPayStatusCode END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderPayStatusCode' AND @sortOrder = 'DESC'
	 THEN W.PurchaseOrderPayStatusCode END DESC 
	 
	DROP TABLE #tmpPODetails	 

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
 WHERE id = object_id(N'[dbo].[dms_Member_ServiceRequestHistory]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_ServiceRequestHistory] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
-- EXEC  [dbo].[dms_Member_ServiceRequestHistory] @whereClauseXML ='<ROW><Filter MembershipIDOperator="2" MembershipIDValue="1"></Filter></ROW>', @sortColumn = 'CreateDate', @sortOrder = 'ASC'
 CREATE PROCEDURE [dbo].[dms_Member_ServiceRequestHistory]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 10 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 
 ) 
 AS 
 BEGIN 
  
    SET FMTONLY OFF
 	SET NOCOUNT ON  
 	
CREATE TABLE #FinalResultsFiltered (    
 CaseNumber int  NULL ,  
 ServiceRequestNumber int  NULL ,  
 CreateDate datetime  NULL ,  
 ServiceType nvarchar(50)  NULL ,  
 [Status] nvarchar(50)  NULL ,  
 FirstName nvarchar(50)  NULL ,  
 MiddleName nvarchar(50)  NULL ,  
 LastName nvarchar(50)  NULL ,  
 Suffix nvarchar(50)  NULL ,  
 VehicleYear nvarchar(4)  NULL ,  
 VehicleMake nvarchar(50)  NULL ,  
 VehicleMakeOther nvarchar(50)  NULL ,  
 VehicleModel nvarchar(50)  NULL ,  
 VehicleModelOther nvarchar(50)  NULL ,  
 Vendor nvarchar(255)  NULL , 
 MembershipID int  NULL , 
 POCount int  NULL  ,
 ContactPhoneNumber nvarchar(100) NULL 
)

CREATE TABLE #FinalResultsFormatted (   
 
 CaseNumber int  NULL ,  
 ServiceRequestNumber int  NULL ,  
 CreateDate datetime  NULL ,  
 ServiceType nvarchar(50)  NULL ,  
 Status nvarchar(50)  NULL ,  
 MemberName nvarchar(200)  NULL ,  
 Vehicle nvarchar(200)  NULL ,  
 Vendor nvarchar(255)  NULL ,  
 POCount int  NULL ,  
 MembershipID int  NULL   ,
 ContactPhoneNumber nvarchar(100) NULL 
)
  
CREATE TABLE #FinalResultsSorted (   
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 CaseNumber int  NULL ,  
 ServiceRequestNumber int  NULL ,  
 CreateDate datetime  NULL ,  
 ServiceType nvarchar(50)  NULL ,  
 Status nvarchar(50)  NULL ,  
 MemberName nvarchar(200)  NULL ,  
 Vehicle nvarchar(200)  NULL ,  
 Vendor nvarchar(255)  NULL ,  
 POCount int  NULL ,  
 MembershipID int  NULL   ,
 ContactPhoneNumber nvarchar(100) NULL 
)

DECLARE @idoc int  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter   
CaseNumberOperator="-1"   
ServiceRequestNumberOperator="-1"   
CreateDateOperator="-1"   
ServiceTypeOperator="-1"   
StatusOperator="-1"   
MemberNameOperator="-1"   
VehicleOperator="-1"   
VendorOperator="-1"   
POCountOperator="-1"   
MembershipIDOperator="-1"   
ContactPhoneNumberOperator="-1"
 ></Filter></ROW>' 
  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
CaseNumberOperator INT NOT NULL,  
CaseNumberValue int NULL,  
ServiceRequestNumberOperator INT NOT NULL,  
ServiceRequestNumberValue int NULL,  
CreateDateOperator INT NOT NULL,  
CreateDateValue datetime NULL,  
ServiceTypeOperator INT NOT NULL,  
ServiceTypeValue nvarchar(50) NULL,  
StatusOperator INT NOT NULL,  
StatusValue nvarchar(50) NULL,  
MemberNameOperator INT NOT NULL,  
MemberNameValue nvarchar(200) NULL,  
VehicleOperator INT NOT NULL,  
VehicleValue nvarchar(50) NULL,  
VendorOperator INT NOT NULL,  
VendorValue nvarchar(50) NULL,  
POCountOperator INT NOT NULL,  
POCountValue int NULL,  
MembershipIDOperator INT NOT NULL,  
MembershipIDValue int NULL ,
ContactPhoneNumberOperator INT NOT NULL ,
ContactPhoneNumberValue nvarchar(50) NULL 
)  
   -- ContactPhoneNumber nvarchar NULL 
  
INSERT INTO @tmpForWhereClause  
SELECT    
 ISNULL(CaseNumberOperator,-1),  
 CaseNumberValue ,  
 ISNULL(ServiceRequestNumberOperator,-1),  
 ServiceRequestNumberValue ,  
 ISNULL(CreateDateOperator,-1),  
 CreateDateValue ,  
 ISNULL(ServiceTypeOperator,-1),  
 ServiceTypeValue ,  
 ISNULL(StatusOperator,-1),  
 StatusValue ,  
 ISNULL(MemberNameOperator,-1),  
 MemberNameValue ,  
 ISNULL(VehicleOperator,-1),  
 VehicleValue ,  
 ISNULL(VendorOperator,-1),  
 VendorValue ,  
 ISNULL(POCountOperator,-1),  
 POCountValue ,  
 ISNULL(MembershipIDOperator,-1),  
 MembershipIDValue  , 
 ISNULL(ContactPhoneNumberOperator,-1),  
 ContactPhoneNumberValue   
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
CaseNumberOperator INT,  
CaseNumberValue int   
,ServiceRequestNumberOperator INT,  
ServiceRequestNumberValue int   
,CreateDateOperator INT,  
CreateDateValue datetime   
,ServiceTypeOperator INT,  
ServiceTypeValue nvarchar(50)   
,StatusOperator INT,  
StatusValue nvarchar(50)   
,MemberNameOperator INT,  
MemberNameValue nvarchar(50)   
,VehicleOperator INT,  
VehicleValue nvarchar(50)   
,VendorOperator INT,  
VendorValue nvarchar(50)   
,POCountOperator INT,  
POCountValue int   
,MembershipIDOperator INT,  
MembershipIDValue int   
,ContactPhoneNumberOperator INT,  
ContactPhoneNumberValue nvarchar(50)
 )   
  
--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
INSERT INTO #FinalResultsFiltered
SELECT   
 T.CaseNumber,  
 T.ServiceRequestNumber,  
 T.CreateDate,  
 T.ServiceType,  
 T.[Status],  
 T.FirstName,  
 T.MiddleName,
 T.LastName,
 T.Suffix,
 T.VehicleYear,
 T.VehicleMake,
 T.VehicleMakeOther,
 T.VehicleModel,
 T.VehicleModelOther, 
 T.Vendor,  
 T.MembershipID,  
 T.POCount,
 T.ContactPhoneNumber
   
FROM (  
        SELECT  
				  c.ID AS CaseNumber,   
				  sr.ID AS ServiceRequestNumber,  
				  sr.CreateDate,   
				  pc.Name AS ServiceType,   
				  srs.Name AS 'Status',  
				  M.FirstName,
				  M.MiddleName,
				  M.LastName,
				  M.Suffix,				  
				  C.VehicleYear,
				  C.VehicleMake,
				  C.VehicleMakeOther,
				  C.VehicleModel,
				  C.VehicleModelOther,				   
				  ven.Name AS Vendor,  
				  ms.ID AS MembershipID,  
				  0 AS POCount	,
				  --'' AS ContactPhoneNumber
				  C.ContactPhoneNumber	AS ContactPhoneNumber		  
    FROM ServiceRequest sr  WITH (NOLOCK)
	JOIN [Case] c WITH (NOLOCK) ON c.ID = sr.CaseID  
	JOIN Member m WITH (NOLOCK) ON m.ID = c.MemberId  
	JOIN Membership ms WITH (NOLOCK) ON ms.ID = m.MembershipID
	JOIN ServiceRequestStatus srs WITH (NOLOCK) ON srs.ID = sr.ServiceRequestStatusID  
	LEFT JOIN ProductCategory pc WITH (NOLOCK) ON pc.ID = sr.ProductCategoryID     
	LEFT JOIN (SELECT TOP 1 ServiceRequestID, VendorLocationID   ---- Someone should verify this SQL?????  
			   FROM PurchaseOrder WITH (NOLOCK) 
			   ORDER BY issuedate DESC  
			  )  LastPO ON LastPO.ServiceRequestID = sr.ID   
	LEFT JOIN VendorLocation vl WITH (NOLOCK) on vl.ID = LastPO.VendorLocationID  
	LEFT JOIN Vendor ven WITH (NOLOCK) on ven.ID = vl.VendorID  
  
     ) T,  
@tmpForWhereClause TMP   
WHERE (   
 --(   
 -- ( TMP.CaseNumberOperator = -1 )   
 -- OR   
 -- ( TMP.CaseNumberOperator = 2 AND T.CaseNumber = TMP.CaseNumberValue )   
 --)     
 --AND   
 --(   
 -- ( TMP.ServiceRequestNumberOperator = -1 )    
 --OR   
 -- ( TMP.ServiceRequestNumberOperator = 2 AND T.ServiceRequestNumber = TMP.ServiceRequestNumberValue )  
 --)     
 --AND   
 --(   
 -- ( TMP.CreateDateOperator = -1 )   
 --OR   
 -- ( TMP.CreateDateOperator = 2 AND T.CreateDate = TMP.CreateDateValue )   
 --)     
 --AND   
 --(   
 -- ( TMP.ServiceTypeOperator = -1 )    
 --OR   
 -- ( TMP.ServiceTypeOperator = 2 AND T.ServiceType = TMP.ServiceTypeValue )    
 --)     
 --AND   
 --(   
 -- ( TMP.StatusOperator = -1 )    
 --OR   
 -- ( TMP.StatusOperator = 2 AND T.Status = TMP.StatusValue )    
 --)   
 --AND   
 --(   
 -- ( TMP.VendorOperator = -1 )   
 --OR   
 -- ( TMP.VendorOperator = 2 AND T.Vendor = TMP.VendorValue )    
 --) 
 --AND     
 (   
  ( TMP.MembershipIDOperator = -1 )    
 OR   
  ( TMP.MembershipIDOperator = 2 AND T.MembershipID = TMP.MembershipIDValue )  
 )    
 AND   
 1 = 1   
 )   
 
 
 INSERT INTO #FinalResultsFormatted
 SELECT DISTINCT F.CaseNumber,   
		F.ServiceRequestNumber,  
		F.CreateDate,   
		F.ServiceType,   
		F.[Status],  
		REPLACE(RTRIM(  
		COALESCE(F.FirstName,'')+  
		COALESCE(' '+left(F.MiddleName,1),'')+  
		COALESCE(' '+ F.LastName,'')+  
		COALESCE(' '+ F.Suffix,'')  
		),'  ',' ') AS MemberName,  
		REPLACE(RTRIM(  
		COALESCE(F.VehicleYear,'')+  
		COALESCE(' '+ CASE F.VehicleMake WHEN 'Other' THEN F.VehicleMakeOther ELSE F.VehicleMake END,'')+  
		COALESCE(' '+ CASE F.VehicleModel WHEN 'Other' THEN F.VehicleModelOther ELSE F.VehicleModel END,'')  
		),'  ',' ') AS Vehicle,  
		F.Vendor,  
		(select count(*) FROM PurchaseOrder po WITH (NOLOCK) WHERE po.ServiceRequestID = F.ServiceRequestNumber and po.IsActive<>0) AS POCount, 
		F.MembershipID,
		F.ContactPhoneNumber
 FROM	#FinalResultsFiltered F
 --DEBUG
-- SELECT * FROM #FinalResultsFiltered
 INSERT INTO #FinalResultsSorted
 SELECT F.*
 FROM  #FinalResultsFormatted F,
		@tmpForWhereClause TMP
 --WHERE 
 --(	
 --(   
 -- ( TMP.MemberNameOperator = -1 )   
 --OR   
 -- ( TMP.MemberNameOperator = 2 AND F.MemberName = TMP.MemberNameValue )   
 --)   
 --AND 
 --(   
 -- ( TMP.VehicleOperator = -1 )   
 --OR   
 -- ( TMP.VehicleOperator = 2 AND F.Vehicle = TMP.VehicleValue )   
 --)  
 --AND   
 --(   
 -- ( TMP.POCountOperator = -1 )    
 --OR   
 -- ( TMP.POCountOperator = 2 AND F.POCount = TMP.POCountValue )   
 --)   
	 
 --AND 
	--(1=1)
 --)
 ORDER BY   
  CASE WHEN @sortColumn = 'CaseNumber' AND @sortOrder = 'ASC'  
  THEN F.CaseNumber END ASC,   
  CASE WHEN @sortColumn = 'CaseNumber' AND @sortOrder = 'DESC'  
  THEN F.CaseNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'ServiceRequestNumber' AND @sortOrder = 'ASC'  
  THEN F.ServiceRequestNumber END ASC,   
  CASE WHEN @sortColumn = 'ServiceRequestNumber' AND @sortOrder = 'DESC'  
  THEN F.ServiceRequestNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'  
  THEN F.CreateDate END ASC,   
  CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'  
  THEN F.CreateDate END DESC ,  
  
  CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'ASC'  
  THEN F.ServiceType END ASC,   
  CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'DESC'  
  THEN F.ServiceType END DESC ,  
  
  CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'  
  THEN F.Status END ASC,   
  CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'  
  THEN F.Status END DESC ,  
  
  CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'  
  THEN F.MemberName END ASC,   
  CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'  
  THEN F.MemberName END DESC ,  
  
  CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'ASC'  
  THEN F.Vehicle END ASC,   
  CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'DESC'  
  THEN F.Vehicle END DESC ,  
  
  CASE WHEN @sortColumn = 'Vendor' AND @sortOrder = 'ASC'  
  THEN F.Vendor END ASC,   
  CASE WHEN @sortColumn = 'Vendor' AND @sortOrder = 'DESC'  
  THEN F.Vendor END DESC ,  
  
  CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'  
  THEN F.POCount END ASC,   
  CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'  
  THEN F.POCount END DESC ,  
  
  CASE WHEN @sortColumn = 'MembershipID' AND @sortOrder = 'ASC'  
  THEN F.MembershipID END ASC,   
  CASE WHEN @sortColumn = 'MembershipID' AND @sortOrder = 'DESC'  
  THEN F.MembershipID END DESC ,  
  
  CASE WHEN @sortColumn = 'ContactPhoneNumber' AND @sortOrder = 'ASC'  
  THEN F.ContactPhoneNumber END ASC,   
  CASE WHEN @sortColumn = 'ContactPhoneNumber' AND @sortOrder = 'DESC'  
  THEN F.ContactPhoneNumber END DESC 

  
DECLARE @count INT     
SET @count = 0     
SELECT @count = MAX(RowNum) FROM #FinalResultsSorted  
IF (@endInd IS NOT NULL)
BEGIN

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
END
  
SELECT @count AS TotalRows,   
   F.RowNum,  
   F.CaseNumber,  
   F.ServiceRequestNumber,  
   CONVERT(VARCHAR(10), F.CreateDate, 101) AS 'Date',  
   F.ServiceType,  
   F.Status,  
   F.MemberName,  
   F.Vehicle,  
   F.Vendor,  
   F.POCount ,
   F.ContactPhoneNumber
   FROM #FinalResultsSorted F 
WHERE 
		(@endInd IS NULL AND RowNum >= @startInd)
		OR
		(RowNum BETWEEN @startInd AND @endInd)
   
   
DROP TABLE #FinalResultsFiltered
DROP TABLE #FinalResultsFormatted
DROP TABLE #FinalResultsSorted

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
 WHERE id = object_id(N'[dbo].[dms_Client_Batch_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Client_Batch_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Client_Batch_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = 'CreateDate' 
 , @sortOrder nvarchar(100) = 'DESC' 
  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF;
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 

 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
BatchStatusID int NULL,
FromDate DATETIME NULL,
ToDate DATETIME NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	BatchType nvarchar(100)  NULL ,
	BatchStatusID int  NULL ,
	BatchStatus nvarchar(100)  NULL ,
	TotalCount int  NULL ,
	TotalAmount money  NULL ,
	MasterETLLoadID int  NULL ,
	TransactionETLLoadID int  NULL ,
	CreateDate datetime  NULL ,
	CreateBy nvarchar(100)  NULL ,
	ModifyDate datetime  NULL ,
	ModifyBy nvarchar(100)  NULL ,
	LinesCount INT NULL
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	BatchType nvarchar(100)  NULL ,
	BatchStatusID int  NULL ,
	BatchStatus nvarchar(100)  NULL ,
	TotalCount int  NULL ,
	TotalAmount money  NULL ,
	MasterETLLoadID int  NULL ,
	TransactionETLLoadID int  NULL ,
	CreateDate datetime  NULL ,
	CreateBy nvarchar(100)  NULL ,
	ModifyDate datetime  NULL ,
	ModifyBy nvarchar(100)  NULL ,
	LinesCount INT NULL
) 

INSERT INTO #tmpForWhereClause
SELECT 
	T.c.value('@BatchStatusID','int') ,
	T.c.value('@FromDate','datetime') ,
	T.c.value('@ToDate','datetime') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @batchStatusID NVARCHAR(100) = NULL,
		@fromDate DATETIME = NULL,
		@toDate DATETIME = NULL
		
SELECT	@batchStatusID = BatchStatusID, 
		@fromDate = FromDate,
		@toDate = ToDate
FROM	#tmpForWhereClause

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------


INSERT INTO #tmpFinalResults
SELECT	B.ID
		, BT.[Description] AS BatchType
		, B.BatchStatusID
		, BS.Name AS BatchStatus
		, COUNT(DISTINCT BI.ID) AS TotalCount
		, SUM(ISNULL(BIL.LineAmount,0)) AS TotalAmount
		, B.MasterETLLoadID   
		, B.TransactionETLLoadID
		, B.CreateDate
		, B.CreateBy 
		, B.ModifyDate
		, B.ModifyBy
		, COUNT(BIL.ID) AS LinesCount
FROM	Batch B
JOIN	BatchType BT ON BT.ID = B.BatchTypeID
JOIN	BatchStatus BS ON BS.ID = B.BatchStatusID
--LEFT JOIN	VendorInvoice VI ON VI.ExportBatchID = B.ID
LEFT JOIN	BillingInvoice BI ON BI.AccountingInvoiceBatchID = B.ID
LEFT JOIN	BillingInvoiceLine BIL ON BIL.BillingInvoiceID = BI.ID
WHERE	BT.Name='ClientBillingExport'
AND		(@batchStatusID IS NULL OR @batchStatusID = B.BatchStatusID)
AND		(@fromDate IS NULL OR B.CreateDate > @fromDate)
AND		(@toDate IS NULL OR B.CreateDate < @toDate)

GROUP	BY	B.ID
		, BT.[Description] 
		, B.BatchStatusID
		, BS.Name
		, B.MasterETLLoadID
		, B.TransactionETLLoadID
		, B.CreateDate
		, B.CreateBy
		, B.ModifyDate
		, B.ModifyBy

ORDER BY B.CreateDate DESC


INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.BatchType,
	T.BatchStatusID,
	T.BatchStatus,
	T.TotalCount,
	T.TotalAmount,
	T.MasterETLLoadID,
	T.TransactionETLLoadID,
	T.CreateDate,
	T.CreateBy,
	T.ModifyDate,
	T.ModifyBy,
	t.LinesCount
FROM #tmpFinalResults T

 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'BatchType' AND @sortOrder = 'ASC'
	 THEN T.BatchType END ASC, 
	 CASE WHEN @sortColumn = 'BatchType' AND @sortOrder = 'DESC'
	 THEN T.BatchType END DESC ,

	 CASE WHEN @sortColumn = 'BatchStatusID' AND @sortOrder = 'ASC'
	 THEN T.BatchStatusID END ASC, 
	 CASE WHEN @sortColumn = 'BatchStatusID' AND @sortOrder = 'DESC'
	 THEN T.BatchStatusID END DESC ,

	 CASE WHEN @sortColumn = 'BatchStatus' AND @sortOrder = 'ASC'
	 THEN T.BatchStatus END ASC, 
	 CASE WHEN @sortColumn = 'BatchStatus' AND @sortOrder = 'DESC'
	 THEN T.BatchStatus END DESC ,

	 CASE WHEN @sortColumn = 'TotalCount' AND @sortOrder = 'ASC'
	 THEN T.TotalCount END ASC, 
	 CASE WHEN @sortColumn = 'TotalCount' AND @sortOrder = 'DESC'
	 THEN T.TotalCount END DESC ,

	 CASE WHEN @sortColumn = 'TotalAmount' AND @sortOrder = 'ASC'
	 THEN T.TotalAmount END ASC, 
	 CASE WHEN @sortColumn = 'TotalAmount' AND @sortOrder = 'DESC'
	 THEN T.TotalAmount END DESC ,

	 CASE WHEN @sortColumn = 'MasterETLLoadID' AND @sortOrder = 'ASC'
	 THEN T.MasterETLLoadID END ASC, 
	 CASE WHEN @sortColumn = 'MasterETLLoadID' AND @sortOrder = 'DESC'
	 THEN T.MasterETLLoadID END DESC ,

	 CASE WHEN @sortColumn = 'TransactionETLLoadID' AND @sortOrder = 'ASC'
	 THEN T.TransactionETLLoadID END ASC, 
	 CASE WHEN @sortColumn = 'TransactionETLLoadID' AND @sortOrder = 'DESC'
	 THEN T.TransactionETLLoadID END DESC ,

	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'
	 THEN T.CreateDate END ASC, 
	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'
	 THEN T.CreateDate END DESC ,

	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
	 THEN T.CreateBy END ASC, 
	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
	 THEN T.CreateBy END DESC ,

	 CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'ASC'
	 THEN T.ModifyDate END ASC, 
	 CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'DESC'
	 THEN T.ModifyDate END DESC ,

	 CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'ASC'
	 THEN T.ModifyBy END ASC, 
	 CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'DESC'
	 THEN T.ModifyBy END DESC ,

	 CASE WHEN @sortColumn = 'LinesCount' AND @sortOrder = 'ASC'
	 THEN T.LinesCount END ASC, 
	 CASE WHEN @sortColumn = 'LinesCount' AND @sortOrder = 'DESC'
	 THEN T.LinesCount END DESC


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