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
  -- EXEC dms_BillingManageInvoicesList @pMode= 'Closed',@pageSize=12
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
     ScheduleRangeTypeID INT NULL  ,
     AccountingSystemAddressCode NVARCHAR(100) NULL
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
     ScheduleRangeTypeID INT NULL  ,
     AccountingSystemAddressCode NVARCHAR(100) NULL
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

DECLARE @sql NVARCHAR(MAX) = ''

  --INSERT INTO #tmpFinalResults
  
  SET @sql = ' SELECT   DISTINCT' 
  SET @sql = @sql + ' BI.ID, ' 
  SET @sql = @sql + ' BI.[Description], '
  SET @sql = @sql + ' BI.BillingScheduleID, '
  SET @sql = @sql + ' BS.Name, '
  SET @sql = @sql + ' BS.ScheduleTypeID, '   
  SET @sql = @sql + ' BST.Name, '
  SET @sql = @sql + ' BI.ScheduleDate, '
  SET @sql = @sql + ' BI.ScheduleRangeBegin, '
  SET @sql = @sql + ' BI.ScheduleRangeEnd, '
  SET @sql = @sql + ' BI.InvoiceNumber, '
  SET @sql = @sql + ' BI.InvoiceDate, '
  SET @sql = @sql + ' BI.InvoiceStatusID, '
  SET @sql = @sql + ' BIS.Name, '  
  SET @sql = @sql + ' DTLData.TotalDetailCount, '
  SET @sql = @sql + ' DTLData.TotalDetailAmount, '
  SET @sql = @sql + ' DTLData.ReadyToBillCount, '
  SET @sql = @sql + ' DTLData.ReadyToBillAmount, '
  SET @sql = @sql + ' DTLData.PendingCount, '
  SET @sql = @sql + ' DTLData.PendingAmount, '
  SET @sql = @sql + ' DTLData.ExceptionCount, '
  SET @sql = @sql + ' DTLData.ExceptionAmount, '
  SET @sql = @sql + ' DTLData.ExcludedCount, '
  SET @sql = @sql + ' DTLData.ExcludedAmount, '
  SET @sql = @sql + ' DTLData.OnHoldCount, '
  SET @sql = @sql + ' DTLData.OnHoldAmount, '
  SET @sql = @sql + ' DTLData.PostedCount, '
  SET @sql = @sql + ' DTLData.PostedAmount, '
  SET @sql = @sql + ' BI.BillingDefinitionInvoiceID, '
  SET @sql = @sql + ' BI.ClientID, '
  SET @sql = @sql + ' BI.Name, '
  SET @sql = @sql + ' isnull(bi.POPrefix, '''') + isnull(bi.PONumber, '''') as PONumber, '
  SET @sql = @sql + ' BI.AccountingSystemCustomerNumber, '
  SET @sql = @sql + ' cl.Name , '
  SET @sql = @sql + ' bi.CanAddLines, '
  SET @sql = @sql + ' bss.Name AS BilingScheduleStatus , '
  SET @sql = @sql + ' bdi.ScheduleDateTypeID,  '
  SET @sql = @sql + ' bdi.ScheduleRangeTypeID  , '
  SET @sql = @sql + ' bi.AccountingSystemAddressCode '
   SET @sql = @sql + ' from BillingInvoice bi with (nolock) '
  SET @sql = @sql + ' left outer join BillingDefinitionInvoice bdi with(nolock) on bdi.ID=bi.BillingDefinitionInvoiceID  '
  SET @sql = @sql + ' left outer join BillingInvoiceLine bil with (nolock) on bil.BillingInvoiceID = bi.ID ' 
  SET @sql = @sql + ' left outer join BillingDefinitionInvoiceLine bdil with(nolock) on bdil.BillingDefinitionInvoiceID = bdi.ID ' 
  SET @sql = @sql + ' left outer join BillingSchedule bs with (nolock) on bs.ID = bi.BillingScheduleID '  
  SET @sql = @sql + ' left outer join Client cl with (nolock) on cl.ID = bi.ClientID '  
  SET @sql = @sql + ' left outer join Product pr with (nolock) on pr.ID = bil.ProductID ' 
  SET @sql = @sql + ' left outer join RateType rt with (nolock) on rt.ID = bil.RateTypeID  ' 
  SET @sql = @sql + ' left outer join BillingInvoiceStatus bis with (nolock) on bis.ID = bi.InvoiceStatusID ' 
  SET @sql = @sql + ' left outer join BillingInvoiceLineStatus bils with (nolock) on bils.ID = bil.InvoiceLineStatusID ' 
  SET @sql = @sql + ' left outer join BillingScheduleType bst with (nolock) on bst.ID = bs.ScheduleTypeID ' 
  SET @sql = @sql + ' left outer join dbo.BillingScheduleStatus bss with (nolock) on bss.ID = bs.ScheduleStatusID '
  SET @sql = @sql + ' left outer join ( '
  SET @sql = @sql + ' select RS.InvoiceID, '
  SET @sql = @sql + ' isnull(sum(case when RS.Name <> ''DELETED'' then ISNULL(RS.TotalCount,0) else 0 end), 0) as TotalDetailCount, '
  SET @sql = @sql + ' isnull(sum(case when RS.Name <> ''DELETED'' then RS.Amount else 0 end), 0) as TotalDetailAmount, '
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''READY'' then ISNULL(RS.TotalCount,0) else 0 end), 0) as ReadyToBillCount, '
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''READY'' then RS.Amount else 0.00 end), 0.00) as ReadyToBillAmount, '
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''PENDING'' then ISNULL(RS.TotalCount,0) else 0 end), 0) as PendingCount,'
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''PENDING'' then RS.Amount else 0.00 end), 0.00) as PendingAmount, '
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''EXCEPTION'' then ISNULL(RS.TotalCount,0) else 0 end), 0) as ExceptionCount, '
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''EXCEPTION'' then RS.Amount else 0.00 end), 0.00) as ExceptionAmount,  ' 
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''EXCLUDED'' then ISNULL(RS.TotalCount,0) else 0 end), 0) as ExcludedCount, '
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''EXCLUDED'' then RS.Amount else 0.00 end), 0.00) as ExcludedAmount, '	  
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''ONHOLD'' then ISNULL(RS.TotalCount,0) else 0 end), 0) as OnHoldCount, ' 
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''ONHOLD'' then RS.Amount else 0.00 end), 0.00) as OnHoldAmount,  '  
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''POSTED'' then ISNULL(RS.TotalCount,0) else 0 end), 0) as PostedCount,  '  
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''POSTED'' then RS.Amount else 0.00 end), 0.00) as PostedAmount '
  SET @sql = @sql + ' FROM ('
  SET @sql = @sql + ' select bi.ID as InvoiceID, '
  SET @sql = @sql + ' bids.Name AS Name, '
  SET @sql = @sql + ' COUNT(*) As TotalCount, '
  SET @sql = @sql + ' SUM(ISNULL(bid.AdjustmentAmount,0)) As Amount '
  SET @sql = @sql + ' from BillingInvoice bi with (nolock) '  
  SET @sql = @sql + ' left outer join BillingInvoiceLine bil with (nolock) on bil.BillingInvoiceID = bi.ID  '
  SET @sql = @sql + ' left outer join BillingInvoiceDetail bid with (nolock) on bid.BillingInvoiceLineID = bil.ID  '
  SET @sql = @sql + ' left outer join BillingInvoiceDetailStatus bids with (nolock) on bids.ID = bid.InvoiceDetailStatusID  '
  SET @sql = @sql + ' where isnull(bid.IsAdjusted,0)= 1 and bid.InvoiceDetailStatusID  is not null and ISNULL(bid.IsExcluded,0) = 0 '
  SET @sql = @sql + ' group by  bi.ID,bids.Name,bid.IsAdjusted	 '
  SET @sql = @sql + ' UNION ALL '
  SET @sql = @sql + ' select	bi.ID as InvoiceID,  '
  SET @sql = @sql + ' bids.Name AS Name, '
  SET @sql = @sql + ' COUNT(*) As TotalCount, '		
  SET @sql = @sql + ' SUM(ISNULL(bid.EventAmount,0)) AS Amount	'
  SET @sql = @sql + ' from BillingInvoice bi with (nolock) '  
  SET @sql = @sql + ' left outer join BillingInvoiceLine bil with (nolock) on bil.BillingInvoiceID = bi.ID  '
  SET @sql = @sql + ' left outer join BillingInvoiceDetail bid with (nolock) on bid.BillingInvoiceLineID = bil.ID  '
  SET @sql = @sql + ' left outer join BillingInvoiceDetailStatus bids with (nolock) on bids.ID = bid.InvoiceDetailStatusID  '
  SET @sql = @sql + ' where isnull(bid.IsAdjusted,0)= 0 and bid.InvoiceDetailStatusID  is not null and ISNULL(bid.IsExcluded,0) = 0 '
  SET @sql = @sql + ' group by  bi.ID,bids.Name,bid.IsAdjusted	 '
  SET @sql = @sql + ' )RS '
  SET @sql = @sql + ' GROUP BY RS.InvoiceID '
  SET @sql = @sql + ' ) as DTLData on DTLData.InvoiceID = bi.ID '
  SET @sql = @sql + ' where 1=1'
   
   IF @pMode IS NOT NULL
   SET @sql = @sql + ' AND (bss.Name = @pMode)'
   
   IF @ScheduleDateFrom IS NOT NULL
   SET @sql = @sql + ' AND	(bs.ScheduleDate >= @ScheduleDateFrom ) '
   
   IF @ScheduleDateTo IS NOT NULL
   SET @sql = @sql + ' AND	( bs.ScheduleDate < DATEADD(DD,1,@ScheduleDateTo) ) '
   
   IF @ClientID IS NOT NULL
   SET @sql = @sql + ' AND	( @ClientID = cl.ID) '
   
   IF @BillingDefinitionInvoiceID IS NOT NULL
   SET @sql = @sql + ' AND	( @BillingDefinitionInvoiceID = bdi.ID) '
   
   IF @InvoiceStatuses IS NOT NULL
   SET @sql = @sql + ' AND	( bis.ID IN (SELECT item FROM [dbo].[fnSplitString](@InvoiceStatuses,'','') )) '
   
   IF @BillingDefinitionInvoiceLines IS NOT NULL
   SET @sql = @sql + ' AND	( bdil.ID IN (SELECT item FROM [dbo].[fnSplitString](@BillingDefinitionInvoiceLines,'','') )) '	
   
   SET @sql = @sql + ' order by  BI.ID,  '
   SET @sql = @sql + ' BI.[Description], '
   SET @sql = @sql + ' BI.BillingScheduleID,  '
   SET @sql = @sql + ' BS.Name, '
   SET @sql = @sql + ' BS.ScheduleTypeID, '   
   SET @sql = @sql + ' BST.Name, '
   SET @sql = @sql + ' BI.ScheduleDate, ' 
   SET @sql = @sql + ' BI.ScheduleRangeBegin, '
   SET @sql = @sql + ' BI.ScheduleRangeEnd, '
   SET @sql = @sql + ' BI.InvoiceNumber, '
   SET @sql = @sql + ' BI.InvoiceDate, '
   SET @sql = @sql + ' BI.InvoiceStatusID, '
   SET @sql = @sql + ' BIS.Name, '
   SET @sql = @sql + ' DTLData.TotalDetailCount,  '
   SET @sql = @sql + ' DTLData.TotalDetailAmount, '
   SET @sql = @sql + ' DTLData.ReadyToBillCount, '
   SET @sql = @sql + ' DTLData.ReadyToBillAmount, '
   SET @sql = @sql + ' DTLData.PendingCount, '
   SET @sql = @sql + ' DTLData.PendingAmount, '
   SET @sql = @sql + ' DTLData.ExceptionCount,   '
   SET @sql = @sql + ' DTLData.ExceptionAmount,  '
   SET @sql = @sql + ' DTLData.ExcludedCount,  '
   SET @sql = @sql + ' DTLData.ExcludedAmount,  '
   SET @sql = @sql + ' DTLData.OnHoldCount,  '
   SET @sql = @sql + ' DTLData.OnHoldAmount,    '
   SET @sql = @sql + ' DTLData.PostedCount,  '
   SET @sql = @sql + ' DTLData.PostedAmount,  '
   SET @sql = @sql + ' BI.BillingDefinitionInvoiceID,    '
   SET @sql = @sql + ' BI.ClientID,    '
   SET @sql = @sql + ' BI.Name,    '
   SET @sql = @sql + ' isnull(bi.POPrefix, '''') + isnull(bi.PONumber, ''''),  '
   SET @sql = @sql + ' BI.AccountingSystemCustomerNumber,    '
   SET @sql = @sql + ' cl.Name ,  '
   SET @sql = @sql + ' bi.CanAddLines,  '
   SET @sql = @sql + ' bss.Name  ,  '
   SET @sql = @sql + ' bdi.ScheduleDateTypeID,  '
   SET @sql = @sql + ' bdi.ScheduleRangeTypeID  ,'
   SET @sql = @sql + ' bi.AccountingSystemAddressCode '
   SET @sql = @sql + ' OPTION (RECOMPILE) '
   
   
    INSERT INTO #tmpFinalResults
		EXEC sp_executesql @sql, N'@pMode NVARCHAR(50), @ScheduleDateFrom DATETIME, @ScheduleDateTo DATETIME, 
@ClientID INT, @BillingDefinitionInvoiceID INT, @InvoiceStatuses NVARCHAR(MAX), @BillingDefinitionInvoiceLines NVARCHAR(MAX)',
		@pMode, @ScheduleDateFrom, @ScheduleDateTo, @ClientID, @BillingDefinitionInvoiceID, @InvoiceStatuses, @BillingDefinitionInvoiceLines
    
  
    
      
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
 ISNULL(T.TotalDetailCount,  0),  
 ISNULL(T.TotalDetailAmount, 0),   
 ISNULL(T.ReadyToBillCount,  0),  
 ISNULL(T.ReadyToBillAmount, 0),   
 ISNULL(T.PendingCount,    	 0),
 ISNULL(T.PendingAmount,     0),
 ISNULL(T.ExceptionCount,    0),
 ISNULL(T.ExceptionAmount,   0),
 ISNULL(T.ExcludedCount,     0),
 ISNULL(T.ExcludedAmount,    0),
 ISNULL(T.OnHoldCount,    	 0),
 ISNULL(T.OnHoldAmount,   	 0),
 ISNULL(T.PostedCount,    	 0),
 ISNULL(T.PostedAmount,    	 0),
 T.BillingDefinitionInvoiceID,    
 T.ClientID,    
 T.InvoiceName,    
 T.PONumber,    
 T.AccountingSystemCustomerNumber,    
 T.ClientName,  
 T.CanAddLines ,  
 T.BilingScheduleStatus ,  
 T.ScheduleDateTypeID,  
 T.ScheduleRangeTypeID  ,
 T.AccountingSystemAddressCode
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
	 THEN T.ScheduleRangeTypeID END DESC  ,

	 CASE WHEN @sortColumn = 'AccountingSystemAddressCode' AND @sortOrder = 'ASC'
	 THEN T.AccountingSystemAddressCode END ASC, 
	 CASE WHEN @sortColumn = 'AccountingSystemAddressCode' AND @sortOrder = 'DESC'
	 THEN T.AccountingSystemAddressCode END DESC  
      
      
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