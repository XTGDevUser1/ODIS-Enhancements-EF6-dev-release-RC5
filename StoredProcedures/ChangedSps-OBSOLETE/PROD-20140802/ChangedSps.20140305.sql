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
 PostingBatchID INT NULL,
 ChargedDateFrom DATETIME NULL,
 ChargedDateTo   DATETIME NULL,
 ChargedAmountFrom NUMERIC(18,2) NULL,
 ChargedAmountTo NUMERIC(18,2) NULL, 
 ExceptionType NVARCHAR(MAX) NULL
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
 PurchaseOrderStatus nvarchar(50)  NULL,
 ReferenceVendorNumber nvarchar(50) NULL,
 VendorNumber nvarchar(50) NULL,
 LastChargedDate DATETIME NULL
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
 PurchaseOrderStatus nvarchar(50)  NULL,
 ReferenceVendorNumber nvarchar(50) NULL,
 VendorNumber nvarchar(50) NULL,
 LastChargedDate DATETIME NULL
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
 T.c.value('@PostingBatchID','INT'),
 T.c.value('@ChargedDateFrom','datetime') ,  
 T.c.value('@ChargedDateTo','datetime') ,  
 T.c.value('@ChargedAmountFrom','NUMERIC(18,2)') ,  
 T.c.value('@ChargedAmountTo','NUMERIC(18,2)') ,  
 T.c.value('@ExceptionType','NVARCHAR(MAX)')  
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)    
    
    
DECLARE @idType NVARCHAR(50) = NULL,    
  @idValue NVARCHAR(100) = NULL,    
  @CCMatchStatuses NVARCHAR(MAX) = NULL,    
  @POPayStatuses NVARCHAR(MAX) = NULL,    
  @CCFromDate DATETIME = NULL,    
  @CCToDate DATETIME = NULL, 
  @POFromDate DATETIME = NULL,    
  @POToDate DATETIME = NULL,
  @PostingBatchID INT = NULL,
  @ChargedDateFrom DATETIME = NULL,    
  @ChargedDateTo DATETIME = NULL,  
  @ChargedAmountFrom NUMERIC(18,2),  
  @ChargedAmountTo NUMERIC(18,2),
  @ExceptionType NVARCHAR(MAX) = NULL

  DECLARE @ExTypeList AS TABLE([ExceptionMessage] NVARCHAR(MAX) NULL)
      
SELECT @idType = IDType,    
  @idValue = IDValue,    
  @CCMatchStatuses = CCMatchStatuses,    
  @POPayStatuses = POPayStatuses,    
  @CCFromDate = CCFromDate,    
  @CCToDate = CASE WHEN CCToDate = '1900-01-01' THEN NULL ELSE CCToDate END,  
  @POFromDate = POFromDate,
  @POToDate = CASE WHEN POToDate = '1900-01-01' THEN NULL ELSE POToDate END,  
  @PostingBatchID = PostingBatchID,
  @ChargedDateFrom = ChargedDateFrom,
  @ChargedDateTo = CASE WHEN ChargedDateTo = '1900-01-01' THEN NULL ELSE ChargedDateTo END,   
  @ChargedAmountFrom = ChargedAmountFrom,
  @ChargedAmountTo = ChargedAmountTo,
  @ExceptionType = ExceptionType

FROM #tmpForWhereClause    

INSERT INTO @ExTypeList([ExceptionMessage]) SELECT item FROM dbo.fnSplitString(@ExceptionType,',')

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
		,TCC.ReferenceVendorNumber
		,V.VendorNumber
		,TCC.LastChargedDate 
FROM	TemporaryCreditCard TCC WITH(NOLOCK)
LEFT JOIN	TemporaryCreditCardStatus TCCS ON TCCS.ID = TCC.TemporaryCreditCardStatusID
LEFT JOIN	PurchaseOrder PO ON PO.PurchaseOrderNumber = TCC.ReferencePurchaseOrderNumber
LEFT JOIN	VendorLocation VL ON VL.ID = PO.VendorLocationID
LEFT JOIN   Vendor V ON V.ID = VL.VendorID
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
       
   ( @ChargedDateFrom IS NULL OR (@ChargedDateFrom IS NOT NULL AND TCC.LastChargedDate >= @ChargedDateFrom))    
    AND    
   ( @ChargedDateTo IS NULL OR (@ChargedDateTo IS NOT NULL AND TCC.LastChargedDate < DATEADD(DD,1,@ChargedDateTo)))    
  )
  AND  (    
       
   ( @ChargedAmountFrom IS NULL OR (@ChargedAmountFrom IS NOT NULL AND TCC.TotalChargedAmount >= @ChargedAmountFrom))    
    AND    
   ( @ChargedAmountTo IS NULL OR (@ChargedAmountTo IS NOT NULL AND TCC.TotalChargedAmount <= @ChargedAmountTo))    
  )
  AND  (    
       
   ( @POFromDate IS NULL OR (@POFromDate IS NOT NULL AND PO.IssueDate >= @POFromDate))    
    AND    
   ( @POToDate IS NULL OR (@POToDate IS NOT NULL AND PO.IssueDate < DATEADD(DD,1,@POToDate)))    
  )
  AND ( ISNULL(@PostingBatchID,0) = 0 OR TCC.PostingBatchID = @PostingBatchID )
 
  AND ((@ExceptionType IS NULL) OR (@ExceptionType IS NOT NULL AND TCC.ExceptionMessage IN (SELECT ExceptionMessage  FROM @ExTypeList)))
  
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
 T.PurchaseOrderStatus,
 T.ReferenceVendorNumber,
 T.VendorNumber,
 T.LastChargedDate
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
  THEN T.PurchaseOrderStatus END DESC,
  
  CASE WHEN @sortColumn = 'ReferenceVendorNumber' AND @sortOrder = 'ASC'    
  THEN T.ReferenceVendorNumber END ASC,     
  CASE WHEN @sortColumn = 'ReferenceVendorNumber' AND @sortOrder = 'DESC'    
  THEN T.ReferenceVendorNumber END DESC,
  
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'    
  THEN T.VendorNumber END ASC,     
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'    
  THEN T.VendorNumber END DESC,

  CASE WHEN @sortColumn = 'LastChargedDate' AND @sortOrder = 'ASC'    
  THEN T.LastChargedDate END ASC,     
  CASE WHEN @sortColumn = 'LastChargedDate' AND @sortOrder = 'DESC'    
  THEN T.LastChargedDate END DESC
  
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
                        --Cancelled 
                         WHEN po.IsActive = 1 
                                    AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Cancelled%') 
                                    AND vi.ID IS NULL 
                                    AND tc.IssueStatus = 'Cancel'
                                    AND ISNULL(tc.TotalChargedAmount,0) = 0 
                              THEN @CancelledTemporaryCreditCardStatusID
                        --Matched
                        WHEN po.IsActive = 1 
                                    AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
                                    AND vi.ID IS NULL 
                                    AND (ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount
                                          OR ISNULL(tc.IsExceptionOverride,0) = 1)
                              THEN @MatchedTemporaryCreditCardStatusID
                        --Exception
                        ELSE @ExceptionTemporaryCreditCardStatusID
                        END
            ,ModifyBy = @currentUser
            ,ModifyDate = @now
            ,ExceptionMessage = 
                  CASE 
                         --Cancelled 
                         WHEN po.IsActive = 1 
                                    AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Cancelled%') 
                                    AND vi.ID IS NULL 
                                    AND tc.IssueStatus = 'Cancel'
                                    AND ISNULL(tc.TotalChargedAmount,0) = 0 
                              THEN NULL
                        --Matched
                        WHEN po.IsActive = 1 
                                    AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
                                    AND vi.ID IS NULL 
                                    AND (ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount
                                          OR ISNULL(tc.IsExceptionOverride,0) = 1)
                              THEN NULL
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
			CASE WHEN tc.IssueStatus = 'Cancel' THEN @CancelledTemporaryCreditCardStatusID
				 ELSE @ExceptionTemporaryCreditCardStatusID
				 END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE WHEN tc.IssueStatus = 'Cancel' THEN NULL
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
		AND po.CreateDate >= DATEADD(dd,1,tc.IssueDate)
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
 WHERE id = object_id(N'[dbo].[dms_Temporary_CC_Card_Details_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Temporary_CC_Card_Details_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_Temporary_CC_Card_Details_Get 1
 CREATE PROCEDURE [dbo].[dms_Temporary_CC_Card_Details_Get] ( 
   @TempCCID Int = null 
 ) 
 AS 
 BEGIN 
  
SET NOCOUNT ON

SELECT	TCC.ID
		, TCC.CreditCardNumber AS TempCC
		, TCC.TotalChargedAmount AS CCCharge
		, TCC.IssueStatus AS IssueStatus
		, TCCS.Name AS MatchStatus
		, TCC.ExceptionMessage AS ExceptionMessage
		, TCC.OriginalReferencePurchaseOrderNumber AS CCOrigPO
		, TCC.ReferencePurchaseOrderNumber AS CCRefPO
		, TCC.Note
		,ISNULL(TCC.IsExceptionOverride,0) AS IsExceptionOverride
FROM	TemporaryCreditCard TCC
LEFT JOIN	TemporaryCreditCardStatus TCCS ON TCCS.ID = TCC.TemporaryCreditCardStatusID
WHERE	TCC.ID = @TempCCID


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
   ,PO.ContractStatus
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
LEFT JOIN CurrencyType CT ON CT.ID=PO.CurrencyTypeID  
WHERE  PO.PurchaseOrderNumber = @PONumber  
   AND PO.IsActive = 1  
  
END  

GO
