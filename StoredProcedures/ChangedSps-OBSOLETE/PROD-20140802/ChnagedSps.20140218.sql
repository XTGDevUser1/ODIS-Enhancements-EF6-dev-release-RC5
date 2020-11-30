IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_VendorWebAccount_Info]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VendorWebAccount_Info]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
CREATE PROC dms_VendorWebAccount_Info(@VendorID INT = NULL)
AS
BEGIN
	SELECT 
	  VU.VendorID
	, U.Username
	, VU.FirstName + ' ' + VU.LastName AS [FirstLastName]
	, M.Email
	, DATEADD(HH,-6,U.LastActivityDate) LastActivityDate
	, DATEADD(HH,-6,M.LastPasswordChangedDate) LastPasswordChangedDate
	, M.IsApproved
	, M.IsLockedOut
	, LC.Username AS LegacyUsername
	, LC.Password AS LegacyPassword
	, U.ApplicationId
	, U.UserId
	FROM VendorUser VU
	JOIN aspnet_Users U ON U.UserID = VU.aspnet_UserID
	JOIN aspnet_Membership M ON M.USerID = U.UserID
	LEFT JOIN VendorLegacyCredentials LC ON LC.VendorID = VU.VendorID
	WHERE VU.VendorID = @VendorID
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
		TemporaryCreditCardStatusID = 
			CASE
				 --Cancelled	
				 WHEN po.IsActive = 1 
						AND (po.PurchaseOrderStatusID = (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Cancelled') 
							OR tc.IssueStatus = 'Cancel')
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
				 WHEN po.IsActive = 1 
						AND (po.PurchaseOrderStatusID = (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Cancelled') 
							OR tc.IssueStatus = 'Cancel')
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) = 0
					THEN NULL
				 WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
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
	TransactionSequence int NULL,
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
	TransactionSequence int NULL,
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
		, TCCD.TransactionSequence AS [Sequence]
		, TCCD.TransactionBy AS [User]
		, TCCD.TransactionType AS [Action]
		, TCCD.RequestedAmount AS [Requested]
		, TCCD.ApprovedAmount AS [Approved]
		, TCCD.ChargeAmount AS [Charge]
		, TCCD.ChargeDescription AS [ChargeDescription]
FROM	TemporaryCreditCardDetail TCCD
WHERE	TCCD.TemporaryCreditCardID = @TemporaryCreditCardId
ORDER BY TCCD.TransactionDate ASC,TCCD.TransactionSequence ASC


INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.TransactionDate,
	T.TransactionSequence,
	T.TransactionBy,
	T.TransactionType,
	T.RequestedAmount,
	T.ApprovedAmount,
	T.ChargeAmount,
	T.ChargeDescription
FROM #tmpFinalResults T
ORDER BY T.TransactionDate, T.TransactionSequence


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
 WHERE id = object_id(N'[dbo].[dms_TempCC_GLAccountList_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_TempCC_GLAccountList_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dbo].[dms_TempCC_GLAccountList_get] @BatchID=169
 CREATE PROCEDURE [dbo].[dms_TempCC_GLAccountList_get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC'
 , @BatchID INT = NULL 
  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF;
 	SET NOCOUNT ON

Declare @DefaultGLAccount nvarchar(50)
	   , @ApplicationConfigurationType INT
SET @ApplicationConfigurationType = (Select ID from ApplicationConfigurationTYpe where name = 'VendorInvoice')
SET @DefaultGLAccount = (Select Value From ApplicationConfiguration where Name = 'ISPCheckGLExpenseAccount' And ApplicationConfigurationTypeID = @ApplicationConfigurationType)


 CREATE TABLE #FinalResultsFiltered( 	
	GLAccountName			NVARCHAR(11)  NULL ,
	GLAccountCount		INT  NULL ,
	PaymentAmount		money  NULL
) 

CREATE TABLE #FinalResultsSorted( 
	[RowNum]		[BIGINT]	NOT NULL IDENTITY(1,1),
	GLAccountName			NVARCHAR(11)  NULL ,
	GLAccountCount		INT  NULL ,
	PaymentAmount		money  NULL 
) 

--SELECT * FROM @tmpForWhereClause

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResultsFiltered
SELECT
VI.GLExpenseAccount [GLAccountName],
COUNT(TCC.ID) [GLAccountCount],
SUM(TCC.TotalChargedAmount) [PaymentAmount]
 from VendorInvoice VI
join TemporaryCreditCard TCC ON TCC.VendorInvoiceID = VI.ID
WHERE VI.ExportBatchID = @BatchID
group by vi.GLExpenseAccount
order by vi.GLExpenseAccount



--Select COALESCE(pc.Value, @DefaultGLAccount) [GL Account]
--, count(*) [Count]
--, SUM(vi.paymentamount) Amount
--, po.ID
--, TCC.ID
--From TemporaryCreditCard tcc
--Join PurchaseOrder po on po.id = tcc.PurchaseOrderID
--Join VendorInvoice vi on po.ID = vi.PurchaseOrderID
--Join ServiceRequest sr on sr.ID = po.ServiceRequestID
--Join [Case] c on c.ID = SR.CaseID
--Left Outer Join ProgramConfiguration pc on pc.ProgramID = c.ProgramID And pc.Name = 'ISPCheckGLExpenseAccount'
--Where tcc.PostingBatchID = @BatchID
--Group By
--COALESCE(pc.Value, @DefaultGLAccount),po.ID

INSERT INTO #FinalResultsSorted
SELECT 
	T.GLAccountName,
	T.GLAccountCount,
	T.PaymentAmount
FROM #FinalResultsFiltered T

 ORDER BY 
	 CASE WHEN @sortColumn = 'GLAccountName' AND @sortOrder = 'ASC'
	 THEN T.GLAccountName END ASC, 
	 CASE WHEN @sortColumn = 'GLAccountName' AND @sortOrder = 'DESC'
	 THEN T.GLAccountName END DESC ,

	 CASE WHEN @sortColumn = 'GLAccountCount' AND @sortOrder = 'ASC'
	 THEN T.GLAccountCount END ASC, 
	 CASE WHEN @sortColumn = 'GLAccountCount' AND @sortOrder = 'DESC'
	 THEN T.GLAccountCount END DESC ,

	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'
	 THEN T.PaymentAmount END ASC, 
	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'
	 THEN T.PaymentAmount END DESC 
	 
	 

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

SELECT @count AS TotalRows,@BatchID AS BatchId, * FROM #FinalResultsSorted WHERE RowNum BETWEEN @startInd AND @endInd

DROP TABLE #FinalResultsFiltered
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
 WHERE id = object_id(N'[dbo].[dms_Temporary_CC_Batch_Payment_Runs_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Temporary_CC_Batch_Payment_Runs_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC [dms_Temporary_CC_Batch_Payment_Runs_List_Get] @BatchID = 169 , @GLAccountName='6300-310-00'
 CREATE PROCEDURE [dbo].[dms_Temporary_CC_Batch_Payment_Runs_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @BatchID INT = NULL  
 , @GLAccountName nvarchar(11) = NULL
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
TemporaryCCIDOperator="-1" 
TemporaryCCNumberOperator="-1" 
CCIssueDateOperator="-1" 
CCIssueByOperator="-1" 
CCApproveOperator="-1" 
CCChargeOperator="-1" 
POIDOperator="-1" 
PONumberOperator="-1" 
POAmountOperator="-1" 
InvoiceIDOperator="-1" 
InvoiceNumberOperator="-1" 
InvoiceAmountOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
TemporaryCCIDOperator INT NOT NULL,
TemporaryCCIDValue int NULL,
TemporaryCCNumberOperator INT NOT NULL,
TemporaryCCNumberValue nvarchar(100) NULL,
CCIssueDateOperator INT NOT NULL,
CCIssueDateValue datetime NULL,
CCIssueByOperator INT NOT NULL,
CCIssueByValue nvarchar(100) NULL,
CCApproveOperator INT NOT NULL,
CCApproveValue money NULL,
CCChargeOperator INT NOT NULL,
CCChargeValue money NULL,
POIDOperator INT NOT NULL,
POIDValue int NULL,
PONumberOperator INT NOT NULL,
PONumberValue nvarchar(100) NULL,
POAmountOperator INT NOT NULL,
POAmountValue money NULL,
InvoiceIDOperator INT NOT NULL,
InvoiceIDValue int NULL,
InvoiceNumberOperator INT NOT NULL,
InvoiceNumberValue nvarchar(100) NULL,
InvoiceAmountOperator INT NOT NULL,
InvoiceAmountValue money NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	TemporaryCCID int  NULL ,
	TemporaryCCNumber nvarchar(100)  NULL ,
	CCIssueDate datetime  NULL ,
	CCIssueBy nvarchar(100)  NULL ,
	CCApprove money  NULL ,
	CCCharge money  NULL ,
	POID int  NULL ,
	PONumber nvarchar(100)  NULL ,
	POAmount money  NULL ,
	InvoiceID int  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceAmount money  NULL
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	TemporaryCCID int  NULL ,
	TemporaryCCNumber nvarchar(100)  NULL ,
	CCIssueDate datetime  NULL ,
	CCIssueBy nvarchar(100)  NULL ,
	CCApprove money  NULL ,
	CCCharge money  NULL ,
	POID int  NULL ,
	PONumber nvarchar(100)  NULL ,
	POAmount money  NULL ,
	InvoiceID int  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceAmount money  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@TemporaryCCIDOperator','INT'),-1),
	T.c.value('@TemporaryCCIDValue','int') ,
	ISNULL(T.c.value('@TemporaryCCNumberOperator','INT'),-1),
	T.c.value('@TemporaryCCNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CCIssueDateOperator','INT'),-1),
	T.c.value('@CCIssueDateValue','datetime') ,
	ISNULL(T.c.value('@CCIssueByOperator','INT'),-1),
	T.c.value('@CCIssueByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CCApproveOperator','INT'),-1),
	T.c.value('@CCApproveValue','money') ,
	ISNULL(T.c.value('@CCChargeOperator','INT'),-1),
	T.c.value('@CCChargeValue','money') ,
	ISNULL(T.c.value('@POIDOperator','INT'),-1),
	T.c.value('@POIDValue','int') ,
	ISNULL(T.c.value('@PONumberOperator','INT'),-1),
	T.c.value('@PONumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@POAmountOperator','INT'),-1),
	T.c.value('@POAmountValue','money') ,
	ISNULL(T.c.value('@InvoiceIDOperator','INT'),-1),
	T.c.value('@InvoiceIDValue','int') ,
	ISNULL(T.c.value('@InvoiceNumberOperator','INT'),-1),
	T.c.value('@InvoiceNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@InvoiceAmountOperator','INT'),-1),
	T.c.value('@InvoiceAmountValue','money') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT 
  TCC.ID AS TemporaryCCID
, TCC.CreditCardNumber AS TemporaryCCNumber
, TCC.IssueDate AS CCIssueDate
, TCC.IssueBy AS CCIssueBy
, TCC.ApprovedAmount AS CCApprove
, TCC.TotalChargedAmount AS CCCharge
, PO.ID AS POID
, PO.PurchaseOrderNumber AS PONumber
, PO.PurchaseOrderAmount AS POAmount 
, VI.ID AS InvoiceID
, VI.InvoiceNumber AS InvoiceNumber
, VI.InvoiceAmount AS InvoiceAmount
FROM	TemporaryCreditCard TCC
LEFT JOIN	PurchaseOrder PO ON PO.PurchaseOrderNumber = TCC.ReferencePurchaseOrderNumber
LEFT JOIN   VendorInvoice VI ON VI.PurchaseOrderID = PO.ID
WHERE TCC.PostingBatchID = @BatchID AND VI.GLExpenseAccount = @GLAccountName

INSERT INTO #FinalResults
SELECT 
	T.TemporaryCCID,
	T.TemporaryCCNumber,
	T.CCIssueDate,
	T.CCIssueBy,
	T.CCApprove,
	T.CCCharge,
	T.POID,
	T.PONumber,
	T.POAmount,
	T.InvoiceID,
	T.InvoiceNumber,
	T.InvoiceAmount
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.TemporaryCCIDOperator = -1 ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 0 AND T.TemporaryCCID IS NULL ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 1 AND T.TemporaryCCID IS NOT NULL ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 2 AND T.TemporaryCCID = TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 3 AND T.TemporaryCCID <> TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 7 AND T.TemporaryCCID > TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 8 AND T.TemporaryCCID >= TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 9 AND T.TemporaryCCID < TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 10 AND T.TemporaryCCID <= TMP.TemporaryCCIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.TemporaryCCNumberOperator = -1 ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 0 AND T.TemporaryCCNumber IS NULL ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 1 AND T.TemporaryCCNumber IS NOT NULL ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 2 AND T.TemporaryCCNumber = TMP.TemporaryCCNumberValue ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 3 AND T.TemporaryCCNumber <> TMP.TemporaryCCNumberValue ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 4 AND T.TemporaryCCNumber LIKE TMP.TemporaryCCNumberValue + '%') 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 5 AND T.TemporaryCCNumber LIKE '%' + TMP.TemporaryCCNumberValue ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 6 AND T.TemporaryCCNumber LIKE '%' + TMP.TemporaryCCNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CCIssueDateOperator = -1 ) 
 OR 
	 ( TMP.CCIssueDateOperator = 0 AND T.CCIssueDate IS NULL ) 
 OR 
	 ( TMP.CCIssueDateOperator = 1 AND T.CCIssueDate IS NOT NULL ) 
 OR 
	 ( TMP.CCIssueDateOperator = 2 AND T.CCIssueDate = TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 3 AND T.CCIssueDate <> TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 7 AND T.CCIssueDate > TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 8 AND T.CCIssueDate >= TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 9 AND T.CCIssueDate < TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 10 AND T.CCIssueDate <= TMP.CCIssueDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CCIssueByOperator = -1 ) 
 OR 
	 ( TMP.CCIssueByOperator = 0 AND T.CCIssueBy IS NULL ) 
 OR 
	 ( TMP.CCIssueByOperator = 1 AND T.CCIssueBy IS NOT NULL ) 
 OR 
	 ( TMP.CCIssueByOperator = 2 AND T.CCIssueBy = TMP.CCIssueByValue ) 
 OR 
	 ( TMP.CCIssueByOperator = 3 AND T.CCIssueBy <> TMP.CCIssueByValue ) 
 OR 
	 ( TMP.CCIssueByOperator = 4 AND T.CCIssueBy LIKE TMP.CCIssueByValue + '%') 
 OR 
	 ( TMP.CCIssueByOperator = 5 AND T.CCIssueBy LIKE '%' + TMP.CCIssueByValue ) 
 OR 
	 ( TMP.CCIssueByOperator = 6 AND T.CCIssueBy LIKE '%' + TMP.CCIssueByValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CCApproveOperator = -1 ) 
 OR 
	 ( TMP.CCApproveOperator = 0 AND T.CCApprove IS NULL ) 
 OR 
	 ( TMP.CCApproveOperator = 1 AND T.CCApprove IS NOT NULL ) 
 OR 
	 ( TMP.CCApproveOperator = 2 AND T.CCApprove = TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 3 AND T.CCApprove <> TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 7 AND T.CCApprove > TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 8 AND T.CCApprove >= TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 9 AND T.CCApprove < TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 10 AND T.CCApprove <= TMP.CCApproveValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CCChargeOperator = -1 ) 
 OR 
	 ( TMP.CCChargeOperator = 0 AND T.CCCharge IS NULL ) 
 OR 
	 ( TMP.CCChargeOperator = 1 AND T.CCCharge IS NOT NULL ) 
 OR 
	 ( TMP.CCChargeOperator = 2 AND T.CCCharge = TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 3 AND T.CCCharge <> TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 7 AND T.CCCharge > TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 8 AND T.CCCharge >= TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 9 AND T.CCCharge < TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 10 AND T.CCCharge <= TMP.CCChargeValue ) 

 ) 

 AND 

 ( 
	 ( TMP.POIDOperator = -1 ) 
 OR 
	 ( TMP.POIDOperator = 0 AND T.POID IS NULL ) 
 OR 
	 ( TMP.POIDOperator = 1 AND T.POID IS NOT NULL ) 
 OR 
	 ( TMP.POIDOperator = 2 AND T.POID = TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 3 AND T.POID <> TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 7 AND T.POID > TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 8 AND T.POID >= TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 9 AND T.POID < TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 10 AND T.POID <= TMP.POIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.PONumberOperator = -1 ) 
 OR 
	 ( TMP.PONumberOperator = 0 AND T.PONumber IS NULL ) 
 OR 
	 ( TMP.PONumberOperator = 1 AND T.PONumber IS NOT NULL ) 
 OR 
	 ( TMP.PONumberOperator = 2 AND T.PONumber = TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 3 AND T.PONumber <> TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 4 AND T.PONumber LIKE TMP.PONumberValue + '%') 
 OR 
	 ( TMP.PONumberOperator = 5 AND T.PONumber LIKE '%' + TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 6 AND T.PONumber LIKE '%' + TMP.PONumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.POAmountOperator = -1 ) 
 OR 
	 ( TMP.POAmountOperator = 0 AND T.POAmount IS NULL ) 
 OR 
	 ( TMP.POAmountOperator = 1 AND T.POAmount IS NOT NULL ) 
 OR 
	 ( TMP.POAmountOperator = 2 AND T.POAmount = TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 3 AND T.POAmount <> TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 7 AND T.POAmount > TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 8 AND T.POAmount >= TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 9 AND T.POAmount < TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 10 AND T.POAmount <= TMP.POAmountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.InvoiceIDOperator = -1 ) 
 OR 
	 ( TMP.InvoiceIDOperator = 0 AND T.InvoiceID IS NULL ) 
 OR 
	 ( TMP.InvoiceIDOperator = 1 AND T.InvoiceID IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceIDOperator = 2 AND T.InvoiceID = TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 3 AND T.InvoiceID <> TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 7 AND T.InvoiceID > TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 8 AND T.InvoiceID >= TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 9 AND T.InvoiceID < TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 10 AND T.InvoiceID <= TMP.InvoiceIDValue ) 

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
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'TemporaryCCID' AND @sortOrder = 'ASC'
	 THEN T.TemporaryCCID END ASC, 
	 CASE WHEN @sortColumn = 'TemporaryCCID' AND @sortOrder = 'DESC'
	 THEN T.TemporaryCCID END DESC ,

	 CASE WHEN @sortColumn = 'TemporaryCCNumber' AND @sortOrder = 'ASC'
	 THEN T.TemporaryCCNumber END ASC, 
	 CASE WHEN @sortColumn = 'TemporaryCCNumber' AND @sortOrder = 'DESC'
	 THEN T.TemporaryCCNumber END DESC ,

	 CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'ASC'
	 THEN T.CCIssueDate END ASC, 
	 CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'DESC'
	 THEN T.CCIssueDate END DESC ,

	 CASE WHEN @sortColumn = 'CCIssueBy' AND @sortOrder = 'ASC'
	 THEN T.CCIssueBy END ASC, 
	 CASE WHEN @sortColumn = 'CCIssueBy' AND @sortOrder = 'DESC'
	 THEN T.CCIssueBy END DESC ,

	 CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'ASC'
	 THEN T.CCApprove END ASC, 
	 CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'DESC'
	 THEN T.CCApprove END DESC ,

	 CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'ASC'
	 THEN T.CCCharge END ASC, 
	 CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'DESC'
	 THEN T.CCCharge END DESC ,

	 CASE WHEN @sortColumn = 'POID' AND @sortOrder = 'ASC'
	 THEN T.POID END ASC, 
	 CASE WHEN @sortColumn = 'POID' AND @sortOrder = 'DESC'
	 THEN T.POID END DESC ,

	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'
	 THEN T.PONumber END ASC, 
	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'
	 THEN T.PONumber END DESC ,

	 CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'ASC'
	 THEN T.POAmount END ASC, 
	 CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'DESC'
	 THEN T.POAmount END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceID' AND @sortOrder = 'ASC'
	 THEN T.InvoiceID END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceID' AND @sortOrder = 'DESC'
	 THEN T.InvoiceID END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN T.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN T.InvoiceNumber END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'
	 THEN T.InvoiceAmount END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'
	 THEN T.InvoiceAmount END DESC 


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
 WHERE id = object_id(N'[dbo].[dms_vendor_invoice_batch_details_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_invoice_batch_details_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vendor_invoice_batch_details_update] @invoicesXML = '<Invoices><ID>17</ID><ID>35</ID><ID>3</ID><ID>4</ID></Invoices>',@batchID = 999, @currentUser='kbanda',@eventSource='SQL', @eventDetails='TEST'
 CREATE PROCEDURE [dbo].[dms_vendor_invoice_batch_details_update](
	@invoicesXML XML,
	@batchID BIGINT,
	@currentUser NVARCHAR(50),
	@eventSource NVARCHAR(MAX),
	@eventName NVARCHAR(100) = 'PayInvoices',
	@eventDetails NVARCHAR(MAX),
	@entityName NVARCHAR(50) = 'VendorInvoice',
	@sessionID NVARCHAR(MAX) = NULL
 )
 AS
 BEGIN
 
	DECLARE @now DATETIME = GETDATE()
	
	DECLARE @invoicesFromDB TABLE
	(	
		ID INT IDENTITY(1,1),
		InvoiceID INT
	)
	
	INSERT INTO @invoicesFromDB
	SELECT VI.ID
	FROM	VendorInvoice VI
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @invoicesXML.nodes('/Invoices/ID') T(c)
			) T ON VI.ID = T.ID
	
	DECLARE @paidStatusID INT, 
			@payInvoicesEventID INT, 
			@vendorInvoiceEntityID INT,
			@checkPaymentTypeID INT,
			@ACHPaymentTypeID INT,
			@ACHValidStatusID INT
			
	SELECT @paidStatusID = ID FROM VendorInvoiceStatus WHERE Name = 'Paid'
	SELECT @payInvoicesEventID = ID FROM Event WHERE Name = @eventName
	SELECT @vendorInvoiceEntityID = ID FROM Entity WHERE Name = @entityName
	SELECT @checkPaymentTypeID = ID FROM PaymentType WHERE Name = 'Check'
	SELECT @ACHPaymentTypeID = ID FROM PaymentType WHERE Name = 'ACH'
	SELECT @ACHValidStatusID = ID FROM ACHStatus WHERE Name = 'Valid'
	
	UPDATE	VendorInvoice
	SET		ExportBatchID = @batchID,
			ExportDate = @now,
			ModifyBy = @currentUser,
			ModifyDate = @now,
			VendorInvoiceStatusID = @paidStatusID,
			PaymentDate = @now,
			--PaymentAmount = CASE WHEN VI.PaymentAmount IS NULL THEN VI.InvoiceAmount ELSE VI.PaymentAmount END,
			PaymentTypeID = Case WHEN ACH.ACHStatusID = @ACHValidStatusID
									THEN @ACHPaymentTypeID
									ELSE @checkPaymentTypeID
							END
	FROM	VendorInvoice VI
	JOIN	@invoicesFromDB I ON VI.ID = I.InvoiceID
	LEFT JOIN VendorACH ACH ON VI.VendorID = ACH.VendorID AND ISNULL(ACH.IsActive,0) = 1
	

	-- KB : Update GLExpenseAccount Details on VendorInvoices.
	DECLARE @glAccountFromAppConfig NVARCHAR(255)

	SET @glAccountFromAppConfig = (SELECT Value FROM ApplicationConfiguration WHERE Name = 'ISPCheckGLExpenseAccount')

	;WITH wVendorInvoiceGLExpenseAccount
	AS
	(
		SELECT	VI.ID AS VendorInvoiceID,
				PO.PurchaseOrderNumber,		
				@glAccountFromAppConfig AS AppConfigValue,
				C.ProgramID,
				C.IsDeliveryDriver,
				[dbo].[fnc_GetProgramConfigurationItemValueForProgram](C.ProgramID,
																	'Application',
																	NULL, 
																	CASE	WHEN ISNULL(C.IsDeliveryDriver,0) = 1 
																			THEN 'DeliveryDriverISPGLCheckExpenseAccount'
																			ELSE 'ISPCheckGLExpenseAccount' 
																			END) AS ProgramConfigItemValue
		FROM	VendorInvoice VI
		JOIN	@invoicesFromDB I ON VI.ID = I.InvoiceID
		JOIN	PurchaseOrder PO ON VI.PurchaseOrderID = PO.ID
		JOIN	ServiceRequest SR ON PO.ServiceRequestID = SR.ID
		JOIN	[Case] C ON SR.CaseID = C.ID
	)
	
	UPDATE	VendorInvoice
	SET		GLExpenseAccount = COALESCE(W.ProgramConfigItemValue,AppConfigValue)
	FROM	VendorInvoice VI
	JOIN	wVendorInvoiceGLExpenseAccount W ON VI.ID = W.VendorInvoiceID

	-- Event Logs.
	DECLARE @maxRows INT, @index INT = 1
	SELECT @maxRows = COUNT(*) FROM @invoicesFromDB
	
	WHILE ( @index <= @maxRows)
	BEGIN
		
		INSERT INTO EventLog
		SELECT	@payInvoicesEventID,
				@sessionID,
				@eventSource,
				@eventDetails,
				NULL,
				NULL,
				GETDATE(),
				@currentUser
				
		INSERT INTO EventLogLink
		SELECT	SCOPE_IDENTITY(),
				@vendorInvoiceEntityID,
				(SELECT InvoiceID FROM @invoicesFromDB WHERE ID = @index)			
	
		SET @index = @index + 1
	END
 
 END
 
 GO
 
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_TempCC_VendorInvoice_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_TempCC_VendorInvoice_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_TempCC_VendorInvoice_update] 169
 CREATE PROCEDURE [dbo].[dms_TempCC_VendorInvoice_update](
 @BatchId int
 )
 AS 
 BEGIN
 
    DECLARE @invoicesFromDB TABLE
	(	
		ID INT IDENTITY(1,1),
		InvoiceID INT
	)
	
	INSERT INTO @invoicesFromDB
	SELECT VI.ID
	FROM	VendorInvoice VI
	WHERE VI.ExportBatchID = @BatchId
	
    DECLARE @glAccountFromAppConfig NVARCHAR(255)

	SET @glAccountFromAppConfig = (SELECT Value FROM ApplicationConfiguration WHERE Name = 'ISPCheckGLExpenseAccount')

	;WITH wVendorInvoiceGLExpenseAccount
	AS
	(
		SELECT	VI.ID AS VendorInvoiceID,
				PO.PurchaseOrderNumber,		
				@glAccountFromAppConfig AS AppConfigValue,
				C.ProgramID,
				C.IsDeliveryDriver,
				[dbo].[fnc_GetProgramConfigurationItemValueForProgram](C.ProgramID,
																	'Application',
																	NULL, 
																	CASE	WHEN ISNULL(C.IsDeliveryDriver,0) = 1 
																			THEN 'DeliveryDriverISPGLCheckExpenseAccount'
																			ELSE 'ISPCheckGLExpenseAccount' 
																			END) AS ProgramConfigItemValue
		FROM	VendorInvoice VI
		JOIN	@invoicesFromDB I ON VI.ID = I.InvoiceID
		JOIN	PurchaseOrder PO ON VI.PurchaseOrderID = PO.ID
		JOIN	ServiceRequest SR ON PO.ServiceRequestID = SR.ID
		JOIN	[Case] C ON SR.CaseID = C.ID
	)
	
	UPDATE	VendorInvoice
	SET		GLExpenseAccount = COALESCE(W.ProgramConfigItemValue,AppConfigValue)
	FROM	VendorInvoice VI
	JOIN	wVendorInvoiceGLExpenseAccount W ON VI.ID = W.VendorInvoiceID
	
	
 END
 
 GO
 
 /****** Object:  UserDefinedFunction [dbo].[fnc_GetProgramsForUser]    Script Date: 09/03/2012 15:48:18 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetProgramConfigurationItemValueForProgram]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_GetProgramConfigurationItemValueForProgram]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fnc_GetProgramConfigurationItemValueForProgram] (
													@ProgramID int, 
													@ConfigurationType nvarchar(50), 
													@ConfigurationCategory NVARCHAR(50),
													@configName NVARCHAR(50))
RETURNS NVARCHAR(MAX)
AS
BEGIN

		DECLARE @programConfigValue NVARCHAR(MAX) = NULL		
		

		;WITH wProgramConfig 
		AS
		(	SELECT ROW_NUMBER() OVER ( PARTITION BY PC.Name ORDER BY PP.Sequence) AS RowNum,
					PC.ID,
					PP.ProgramID,
					PP.Sequence,
					PC.Name,	
					PC.Value	
			FROM fnc_GetProgramsandParents(@ProgramID) PP
			JOIN ProgramConfiguration PC ON PP.ProgramID = PC.ProgramID AND PC.IsActive = 1
			JOIN ConfigurationType C ON PC.ConfigurationTypeID = C.ID 
			LEFT JOIN ConfigurationCategory CC ON PC.ConfigurationCategoryID = CC.ID
			WHERE	(@ConfigurationType IS NULL OR C.Name = @ConfigurationType)
			AND		(@ConfigurationCategory IS NULL OR CC.Name = @ConfigurationCategory)
		)

		SELECT @programConfigValue = W.Value  
		FROM	wProgramConfig W
		WHERE	W.RowNum = 1
		AND		W.Name = @configName
		ORDER BY Sequence
	
		

		RETURN @programConfigValue

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
 PurchaseOrderStatus nvarchar(50)  NULL,
 ReferenceVendorNumber nvarchar(50) NULL,
 VendorNumber nvarchar(50) NULL
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
 VendorNumber nvarchar(50) NULL
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
		,TCC.ReferenceVendorNumber
		,V.VendorNumber
FROM	TemporaryCreditCard TCC
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
 T.PurchaseOrderStatus,
 T.ReferenceVendorNumber,
 T.VendorNumber
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
  THEN T.VendorNumber END DESC
  
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