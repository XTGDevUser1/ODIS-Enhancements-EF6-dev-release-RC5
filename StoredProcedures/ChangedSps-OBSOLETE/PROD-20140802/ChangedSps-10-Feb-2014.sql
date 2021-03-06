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
