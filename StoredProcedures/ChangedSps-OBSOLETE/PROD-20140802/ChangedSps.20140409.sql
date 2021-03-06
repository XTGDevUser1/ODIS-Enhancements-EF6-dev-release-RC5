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
 WHERE id = object_id(N'[dbo].[dms_Claims_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Claims_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dbo].[dms_Claims_List_Get]@sortColumn='AmountApproved' ,@endInd=50,@pageSize=50,@whereClauseXML='<ROW><Filter ClaimAmountFrom="0"/></ROW>',@sortOrder='DESC'
 CREATE PROCEDURE [dbo].[dms_Claims_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF;
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDType=""
IDValue=""
NameType=""
NameOperator=""
NameValue=""
ClaimTypes=""
ClaimStatuses=""
ClaimCategories=""
ClientID=""
ProgramID=""
ExportBatchID=""
 ></Filter></ROW>'
END

--CREATE TABLE #tmpForWhereClause
DECLARE @tmpForWhereClause TABLE
(
IDType			NVARCHAR(50) NULL,
IDValue			NVARCHAR(100) NULL,
NameType		NVARCHAR(50) NULL,
NameOperator	NVARCHAR(50) NULL,
NameValue		NVARCHAR(MAX) NULL,
ClaimTypes		NVARCHAR(MAX) NULL,
ClaimStatuses	NVARCHAR(MAX) NULL,
ClaimCategories	NVARCHAR(MAX) NULL,
ClientID		INT NULL,
ProgramID		INT NULL,
Preset			INT NULL,
ClaimDateFrom	DATETIME NULL,
ClaimDateTo		DATETIME NULL,
ClaimAmountFrom	MONEY NULL,
ClaimAmountTo	MONEY NULL,
CheckNumber		NVARCHAR(50) NULL,
CheckDateFrom	DATETIME NULL,
CheckDateTo		DATETIME NULL,
ExportBatchID	INT NULL,
ACESSubmitFromDate DATETIME NULL,
ACESSubmitToDate DATETIME NULL,
ACESClearedFromDate DATETIME NULL,
ACESClearedToDate DATETIME NULL,
ACESStatus NVARCHAR(MAX) NULL,
ReceivedFromDate DATETIME NULL,
ReceivedToDate DATETIME NULL
)
 CREATE TABLE #FinalResultsFiltered( 	
	ClaimID			INT  NULL ,
	ClaimType		NVARCHAR(100)  NULL ,
	ClaimDate		DATETIME  NULL ,
	AmountRequested MONEY  NULL ,
	Payeee			NVARCHAR(100)  NULL ,
	ClaimStatus		NVARCHAR(100)  NULL ,
	NextAction		NVARCHAR(100)  NULL ,
	AssignedTo		NVARCHAR(100)  NULL ,
	NextActionScheduledDate DATETIME  NULL ,
	ACESSubmitDate	DATETIME  NULL ,
	CheckNumber		NVARCHAR(100)  NULL ,
	PaymentDate		DATETIME  NULL ,
	PaymentAmount	MONEY  NULL,
	CheckClearedDate DATETIME NULL,
	AuthorizationCount	BIGINT NULL,
	InProcessCount	BIGINT NULL,
	CancelledCount	BIGINT NULL,
	ApprovedCount	BIGINT NULL,
	DeniedCount	BIGINT NULL,
	ReadyForPaymentCount BIGINT NULL,
	PaidCount		BIGINT NULL,
	ExceptionCount		BIGINT NULL,
	ClaimExceptionDetails NVARCHAR(MAX) NULL,
	MembershipNumber NVARCHAR(100) NULL,
	ProgramName NVARCHAR(100) NULL,
	BatchID INT NULL,
	AmountApproved MONEY  NULL ,
	ACESStatus nvarchar(100) NULL ,
	ACESClearedDate DATETIME NULL,
	ACESFeeAmount MONEY NULL
) 

CREATE TABLE #FinalResultsSorted( 
	[RowNum]		[BIGINT]	NOT NULL IDENTITY(1,1),
	ClaimID			INT  NULL ,
	ClaimType		NVARCHAR(100)  NULL ,
	ClaimDate		DATETIME  NULL ,
	AmountRequested MONEY  NULL ,
	Payeee			NVARCHAR(100)  NULL ,
	ClaimStatus		NVARCHAR(100)  NULL ,
	NextAction		NVARCHAR(100)  NULL ,
	AssignedTo		NVARCHAR(100)  NULL ,
	NextActionScheduledDate DATETIME  NULL ,
	ACESSubmitDate	DATETIME  NULL ,
	CheckNumber		NVARCHAR(100)  NULL ,
	PaymentDate		DATETIME  NULL ,
	PaymentAmount	MONEY  NULL,
	CheckClearedDate DATETIME NULL,
	AuthorizationCount	BIGINT NULL,
	InProcessCount	BIGINT NULL,
	CancelledCount	BIGINT NULL,
	ApprovedCount	BIGINT NULL,
	DeniedCount	BIGINT NULL,
	ReadyForPaymentCount BIGINT NULL,
	PaidCount		BIGINT NULL,
	ExceptionCount		BIGINT NULL ,
	ClaimExceptionDetails NVARCHAR(MAX)NULL,
	MembershipNumber NVARCHAR(100) NULL,
	ProgramName NVARCHAR(100) NULL,
	BatchID INT NULL,
	AmountApproved MONEY  NULL,
	ACESStatus nvarchar(100) NULL ,
	ACESClearedDate DATETIME NULL ,
	ACESFeeAmount MONEY NULL
) 

INSERT INTO @tmpForWhereClause
SELECT  
	T.c.value('@IDType','NVARCHAR(50)'),
	T.c.value('@IDValue','NVARCHAR(100)'),
	T.c.value('@NameType','NVARCHAR(50)'),
	T.c.value('@NameOperator','NVARCHAR(50)'),
	T.c.value('@NameValue','NVARCHAR(MAX)'),
	T.c.value('@ClaimTypes','NVARCHAR(MAX)'),
	T.c.value('@ClaimStatuses','NVARCHAR(MAX)'),
	T.c.value('@ClaimCategories','NVARCHAR(MAX)'),
	T.c.value('@ClientID','INT'),
	T.c.value('@ProgramID','INT'),
	T.c.value('@Preset','INT'),
	T.c.value('@ClaimDateFrom','DATETIME'),
	T.c.value('@ClaimDateTo','DATETIME'),
	T.c.value('@ClaimAmountFrom','MONEY'),
	T.c.value('@ClaimAmountTo','MONEY'),
	T.c.value('@CheckNumber','NVARCHAR(50)'),
	T.c.value('@CheckDateFrom','DATETIME'),
	T.c.value('@CheckDateTo','DATETIME'),
	T.c.value('@ExportBatchID','INT'),
	T.c.value('@ACESSubmitFromDate','DATETIME'),
	T.c.value('@ACESSubmitToDate','DATETIME'),
	T.c.value('@ACESClearedFromDate','DATETIME'),
	T.c.value('@ACESClearedToDate','DATETIME'),
	T.c.value('@ACESStatus','NVARCHAR(MAX)'),
	T.c.value('@ReceivedFromDate','DATETIME'),
	T.c.value('@ReceivedToDate','DATETIME')
	
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @IDType			NVARCHAR(50)= NULL,
@IDValue			NVARCHAR(100)= NULL,
@NameType		NVARCHAR(50)= NULL,
@NameOperator	NVARCHAR(50)= NULL,
@NameValue		NVARCHAR(MAX)= NULL,
@ClaimTypes		NVARCHAR(MAX)= NULL,
@ClaimStatuses	NVARCHAR(MAX)= NULL,
@ClaimCategories	NVARCHAR(MAX)= NULL,
@ClientID		INT= NULL,
@ProgramID		INT= NULL,
@preset			INT=NULL,
@ClaimDateFrom	DATETIME= NULL,
@ClaimDateTo		DATETIME= NULL,
@ClaimAmountFrom	MONEY= NULL,
@ClaimAmountTo	MONEY= NULL,
@CheckNumber		NVARCHAR(50)= NULL,
@CheckDateFrom	DATETIME= NULL,
@CheckDateTo		DATETIME= NULL,
@ExportBatchID	INT= NULL,
@ACESSubmitFromDate DATETIME= NULL,
@ACESSubmitToDate DATETIME= NULL,
@ACESClearedFromDate DATETIME= NULL,
@ACESClearedToDate DATETIME= NULL,
@ACESStatus NVARCHAR(MAX) = NULL,
@ReceivedFromDate DATETIME= NULL,
@ReceivedToDate DATETIME= NULL

SELECT 
		@IDType					= IDType				
		,@IDValue				= IDValue				
		,@NameType				= NameType			
		,@NameOperator			= NameOperator		
		,@NameValue				= NameValue			
		,@ClaimTypes			= ClaimTypes			
		,@ClaimStatuses			= ClaimStatuses		
		,@ClaimCategories		= ClaimCategories		
		,@ClientID				= ClientID			
		,@ProgramID				= ProgramID			
		,@preset				= Preset				
		,@ClaimDateFrom			= ClaimDateFrom		
		,@ClaimDateTo			= ClaimDateTo			
		,@ClaimAmountFrom		= ClaimAmountFrom		
		,@ClaimAmountTo			= ClaimAmountTo		
		,@CheckNumber			= CheckNumber			
		,@CheckDateFrom			= CheckDateFrom		
		,@CheckDateTo			= CheckDateTo			
		,@ExportBatchID			= ExportBatchID		
		,@ACESSubmitFromDate	= ACESSubmitFromDate	
		,@ACESSubmitToDate		= ACESSubmitToDate
		,@ACESClearedFromDate	= ACESClearedFromDate
		,@ACESClearedToDate		= ACESClearedToDate
		,@ACESStatus			= ACESStatus
		,@ReceivedFromDate      = ReceivedFromDate
        ,@ReceivedToDate        = ReceivedToDate
FROM	@tmpForWhereClause

--SELECT @preset
IF (@preset IS NOT NULL)
BEGIN
	DECLARE @fromDate DATETIME
	SET @fromDate = DATEADD(DD, DATEDIFF(DD,0, DATEADD(DD,-1 * @preset,GETDATE())),0)
	UPDATE @tmpForWhereClause 
	SET		ClaimDateFrom  = @fromDate,
			ClaimDateTo = DATEADD(DD,1,GETDATE())
		

END



--SELECT * FROM @tmpForWhereClause

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResultsFiltered
SELECT
		C.ID AS ClaimID
		, CT.Name AS ClaimType
		, C.ClaimDate
		, C.AmountRequested
		, CASE
                        WHEN ISNULL(C.PayeeType,'') = 'Member' THEN 'M-' + C.ContactName
                        WHEN ISNULL(C.PayeeType,'') = 'Vendor' THEN 'V-' + C.ContactName
                        ELSE C.ContactName
          END AS Payeee
		, CS.Name AS ClaimStatus
		, NA.Name AS NextAction
		, U.FirstName + ' ' + U.LastName AS AssignedTo
		, C.NextActionScheduledDate
		, C.ACESSubmitDate
		, C.CheckNumber
		, C.PaymentDate
		, C.PaymentAmount
		, C.CheckClearedDate
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, CE.[Description]
		, MS.MembershipNumber
		, P.Name
		, B.ID AS BatchID
		, C.AmountApproved
		, ACS.Name AS ACESClaimStatus
		, C.ACESClearedDate
		, C.ACESFeeAmount 
FROM	Claim C
JOIN	ClaimType CT WITH(NOLOCK) ON CT.ID = C.ClaimTypeID
LEFT JOIN ClaimStatus CS WITH(NOLOCK) ON CS.ID = C.ClaimStatusID 
LEFT JOIN ClaimException CE WITH(NOLOCK) ON CE.ClaimID = C.ID
LEFT JOIN NextAction NA WITH(NOLOCK) ON NA.ID = C.NextActionID
LEFT JOIN [User] U WITH(NOLOCK) ON U.ID = C.NextActionAssignedToUserID
LEFT JOIN Vendor V WITH (NOLOCK) ON C.VendorID = V.ID
LEFT JOIN Member M WITH (NOLOCK) ON C.MemberID = M.ID
LEFT JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
LEFT JOIN PurchaseOrder PO WITH (NOLOCK) ON C.PurchaseOrderID = PO.ID
LEFT JOIN Program P WITH (NOLOCK) ON P.ID = C.ProgramID
LEFT JOIN Batch B WITH(NOLOCK) ON B.ID=C.ExportBatchID
LEFT JOIN ACESClaimStatus ACS WITH(NOLOCK) ON ACS.ID=C.ACESClaimStatusID
WHERE C.IsActive = 1
AND		(ISNULL(LEN(@IDType),0) = 0 OR (	( @IDType = 'Claim' AND @IDValue	= CONVERT(NVARCHAR(100),C.ID))
											OR
											( @IDType = 'Vendor' AND @IDValue = V.VendorNumber)
											OR
											( @IDType = 'Member' AND @IDValue = MS.MembershipNumber)
										) )
AND		(ISNULL(LEN(@NameType),0) = 0 OR (	
											(@NameType = 'Member' AND (
																			-- TODO: Review the conditions against M.LastName. we might have to use first and last names.
																			(@NameOperator = 'Is equal to' AND @NameValue = M.LastName)
																			OR
																			(@NameOperator = 'Begins with' AND M.LastName LIKE  @NameValue + '%')
																			OR
																			(@NameOperator = 'Ends with' AND M.LastName LIKE  '%' + @NameValue)
																			OR
																			(@NameOperator = 'Contains' AND M.LastName LIKE  '%' + @NameValue + '%')

																		) )
												OR
											(@NameType = 'Vendor' AND (
																			(@NameOperator = 'Is equal to' AND @NameValue = V.Name)
																			OR
																			(@NameOperator = 'Begins with' AND V.Name LIKE  @NameValue + '%')
																			OR
																			(@NameOperator = 'Ends with' AND V.Name LIKE  '%' + @NameValue)
																			OR
																			(@NameOperator = 'Contains' AND V.Name LIKE  '%' + @NameValue + '%')

																		) )

											) )
AND		(ISNULL(LEN(@ClaimTypes),0) = 0  OR (C.ClaimTypeID IN ( SELECT item FROM [dbo].[fnSplitString](@ClaimTypes,',')) ) )
AND		(ISNULL(LEN(@ClaimStatuses),0) = 0  OR (C.ClaimStatusID IN ( SELECT item FROM [dbo].[fnSplitString](@ClaimStatuses,',')) ) )
AND		(ISNULL(LEN(@ClaimCategories),0) = 0  OR (C.ClaimCategoryID IN ( SELECT item FROM [dbo].[fnSplitString](@ClaimCategories,',')) ) )
AND		(ISNULL(@ClientID,0) = 0 OR @ClientID = 0 OR (P.ClientID = @ClientID  ) )
AND		(ISNULL(@ProgramID,0) = 0 OR @ProgramID = 0 OR (C.ProgramID = @ProgramID  ) )
AND		(C.ClaimDate IS NULL 
		OR
		C.ClaimDate IS NOT NULL
		AND		(@ClaimDateFrom IS NULL  OR ( C.ClaimDate >= @ClaimDateFrom ) )
		AND		(@ClaimDateTo IS NULL  OR ( C.ClaimDate < DATEADD(DD,1,@ClaimDateTo) ) )
		)
AND		(@ClaimAmountFrom IS NULL OR (ISNULL(C.AmountRequested,0) >= @ClaimAmountFrom))
AND		(@ClaimAmountTo IS NULL OR (ISNULL(C.AmountRequested,0) <= @ClaimAmountTo))
AND		(ISNULL(LEN(@CheckNumber),0) = 0 OR C.CheckNumber = @CheckNumber)
AND		(ISNULL(@ExportBatchID,0) = 0 OR @ExportBatchID = 0 OR (B.ID = @ExportBatchID  ) )
AND		(@CheckDateFrom IS NULL OR (C.CheckClearedDate >= @CheckDateFrom))
AND		(@CheckDateTo IS NULL OR (C.CheckClearedDate < DATEADD(DD,1,@CheckDateTo)))
AND		(@ACESSubmitFromDate IS NULL OR (C.ACESSubmitDate >= @ACESSubmitFromDate))
AND		(@ACESSubmitToDate IS NULL OR (C.ACESSubmitDate < DATEADD(DD,1,@ACESSubmitToDate)))	
AND		(@ACESClearedFromDate IS NULL OR (C.ACESClearedDate >= @ACESClearedFromDate))
AND		(@ACESClearedToDate IS NULL OR (C.ACESClearedDate < DATEADD(DD,1,@ACESClearedToDate)))		
AND		(@ACESStatus IS NULL OR (C.ACESClaimStatusID IN (SELECT item FROM [dbo].[fnSplitString](@ACESStatus,','))))
AND		(@ReceivedFromDate IS NULL OR (C.ReceivedDate >= @ReceivedFromDate))
AND		(@ReceivedToDate IS NULL OR (C.ReceivedDate < DATEADD(DD,1,@ReceivedToDate)))	


--FILTERING has to be taken care here
INSERT INTO #FinalResultsSorted
SELECT 
	T.ClaimID,
	T.ClaimType,
	T.ClaimDate,
	T.AmountRequested,
	T.Payeee,
	T.ClaimStatus,
	T.NextAction,
	T.AssignedTo,
	T.NextActionScheduledDate,
	T.ACESSubmitDate,
	T.CheckNumber,
	T.PaymentDate,
	T.PaymentAmount,
	T.CheckClearedDate,
	T.AuthorizationCount,
	T.InProcessCount,
	T.CancelledCount,
	T.ApprovedCount,
	T.DeniedCount,
	T.ReadyForPaymentCount,
	T.PaidCount,
	T.ExceptionCount,
   [dbo].[fnConcatenate](T.ClaimExceptionDetails) AS ClaimExceptionDetails,
    T.MembershipNumber,
    T.ProgramName,
    T.BatchID,
    T.AmountApproved,
    T.ACESStatus,
    T.ACESClearedDate,
	T.ACESFeeAmount 
FROM #FinalResultsFiltered T
GROUP BY 
	T.ClaimID,
	T.ClaimType,
	T.ClaimDate,
	T.AmountRequested,
	T.Payeee,
	T.ClaimStatus,
	T.NextAction,
	T.AssignedTo,
	T.NextActionScheduledDate,
	T.ACESSubmitDate,
	T.CheckNumber,
	T.PaymentDate,
	T.PaymentAmount,
	T.CheckClearedDate,
	T.AuthorizationCount,
	T.InProcessCount,
	T.CancelledCount,
	T.ApprovedCount,
	T.DeniedCount,
	T.ReadyForPaymentCount,
	T.PaidCount,
	T.ExceptionCount,
	T.MembershipNumber,
	T.ProgramName,
	T.BatchID,
	T.AmountApproved,
	T.ACESStatus,
	T.ACESClearedDate,
	T.ACESFeeAmount 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ClaimID' AND @sortOrder = 'ASC'
	 THEN T.ClaimID END ASC, 
	 CASE WHEN @sortColumn = 'ClaimID' AND @sortOrder = 'DESC'
	 THEN T.ClaimID END DESC ,

	 CASE WHEN @sortColumn = 'ClaimType' AND @sortOrder = 'ASC'
	 THEN T.ClaimType END ASC, 
	 CASE WHEN @sortColumn = 'ClaimType' AND @sortOrder = 'DESC'
	 THEN T.ClaimType END DESC ,

	 CASE WHEN @sortColumn = 'ClaimDate' AND @sortOrder = 'ASC'
	 THEN T.ClaimDate END ASC, 
	 CASE WHEN @sortColumn = 'ClaimDate' AND @sortOrder = 'DESC'
	 THEN T.ClaimDate END DESC ,

	 CASE WHEN @sortColumn = 'AmountRequested' AND @sortOrder = 'ASC'
	 THEN T.AmountRequested END ASC, 
	 CASE WHEN @sortColumn = 'AmountRequested' AND @sortOrder = 'DESC'
	 THEN T.AmountRequested END DESC ,

	 CASE WHEN @sortColumn = 'Payeee' AND @sortOrder = 'ASC'
	 THEN T.Payeee END ASC, 
	 CASE WHEN @sortColumn = 'Payeee' AND @sortOrder = 'DESC'
	 THEN T.Payeee END DESC ,

	 CASE WHEN @sortColumn = 'ClaimStatus' AND @sortOrder = 'ASC'
	 THEN T.ClaimStatus END ASC, 
	 CASE WHEN @sortColumn = 'ClaimStatus' AND @sortOrder = 'DESC'
	 THEN T.ClaimStatus END DESC ,

	 CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'ASC'
	 THEN T.NextAction END ASC, 
	 CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'DESC'
	 THEN T.NextAction END DESC ,

	 CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'ASC'
	 THEN T.AssignedTo END ASC, 
	 CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'DESC'
	 THEN T.AssignedTo END DESC ,

	 CASE WHEN @sortColumn = 'NextActionScheduledDate' AND @sortOrder = 'ASC'
	 THEN T.NextActionScheduledDate END ASC, 
	 CASE WHEN @sortColumn = 'NextActionScheduledDate' AND @sortOrder = 'DESC'
	 THEN T.NextActionScheduledDate END DESC ,

	 CASE WHEN @sortColumn = 'ACESSubmitDate' AND @sortOrder = 'ASC'
	 THEN T.ACESSubmitDate END ASC, 
	 CASE WHEN @sortColumn = 'ACESSubmitDate' AND @sortOrder = 'DESC'
	 THEN T.ACESSubmitDate END DESC ,

	 CASE WHEN @sortColumn = 'CheckNumber' AND @sortOrder = 'ASC'
	 THEN T.CheckNumber END ASC, 
	 CASE WHEN @sortColumn = 'CheckNumber' AND @sortOrder = 'DESC'
	 THEN T.CheckNumber END DESC ,

	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'ASC'
	 THEN T.PaymentDate END ASC, 
	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'DESC'
	 THEN T.PaymentDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'
	 THEN T.PaymentAmount END ASC, 
	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'
	 THEN T.PaymentAmount END DESC, 
	 
	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'ASC'
	 THEN T.CheckClearedDate END ASC, 
	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'DESC'
	 THEN T.CheckClearedDate END DESC,
	 
	 CASE WHEN @sortColumn = 'BatchID' AND @sortOrder = 'ASC'
	 THEN T.BatchID END ASC, 
	 CASE WHEN @sortColumn = 'BatchID' AND @sortOrder = 'DESC'
	 THEN T.BatchID END DESC,

	 CASE WHEN @sortColumn = 'AmountApproved' AND @sortOrder = 'ASC'
	 THEN T.AmountApproved END ASC, 
	 CASE WHEN @sortColumn = 'AmountApproved' AND @sortOrder = 'DESC'
	 THEN T.AmountApproved END DESC,

	 CASE WHEN @sortColumn = 'ACESStatus' AND @sortOrder = 'ASC'
	 THEN T.ACESStatus END ASC, 
	 CASE WHEN @sortColumn = 'ACESStatus' AND @sortOrder = 'DESC'
	 THEN T.ACESStatus END DESC,

	 CASE WHEN @sortColumn = 'ACESClearedDate' AND @sortOrder = 'ASC'
	 THEN T.ACESClearedDate END ASC, 
	 CASE WHEN @sortColumn = 'ACESClearedDate' AND @sortOrder = 'DESC'
	 THEN T.ACESClearedDate END DESC,

	 CASE WHEN @sortColumn = 'ACESFeeAmount' AND @sortOrder = 'ASC'
	 THEN T.ACESFeeAmount END ASC, 
	 CASE WHEN @sortColumn = 'ACESFeeAmount' AND @sortOrder = 'DESC'
	 THEN T.ACESFeeAmount END DESC


DECLARE @authorizationIssuedCount  BIGINT = 0,
		@inProcessCount BIGINT = 0,
		@cancelledCount BIGINT = 0,
		@approvedCount  BIGINT = 0,
		@deniedCount  BIGINT = 0,
		@readyForPaymentCount BIGINT = 0,
		@PaidCount BIGINT = 0,
		@exceptionCount BIGINT = 0


SELECT @authorizationIssuedCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'AuthorizationIssued'
SELECT @inProcessCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'In-Process'
SELECT @cancelledCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Cancelled'
SELECT @approvedCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Approved'
SELECT @deniedCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Denied'
SELECT @readyForPaymentCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'ReadyForPayment'
SELECT @PaidCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Paid'
SELECT @exceptionCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Exception'

-- DEBUG : SELECT * FROM #FinalResultsSorted WHERE ClaimStatus  ='Approved'

UPDATE #FinalResultsSorted
SET AuthorizationCount = @authorizationIssuedCount,
	InProcessCount = @inProcessCount,
	CancelledCount = @cancelledCount,
   	ApprovedCount = @approvedCount,
    DeniedCount = @deniedCount,
    ReadyForPaymentCount = @readyForPaymentCount,
    PaidCount = @PaidCount,
    ExceptionCount = @exceptionCount

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

--DROP TABLE #tmpForWhereClause
DROP TABLE #FinalResultsFiltered
DROP TABLE #FinalResultsSorted

END

GO

 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_GoToPODetails_row]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_GoToPODetails_row] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_GoToPODetails_row] 1414, 100,100,100,null,null,25   
--32.780122,-96.801412,'TX','US',32.864132,-96.942948,
 CREATE PROCEDURE [dbo].[dms_GoToPODetails_row](
-- @ServiceLocationLatitude decimal(10,7)
-- ,@ServiceLocationLongitude decimal(10,7)
--,@ServiceLocationStateProvince varchar(20)
--,@ServiceLocationCountryCode varchar(20)
--,@DestinationLocationLatitude  decimal(10,7)
--,@DestinationLocationLongitude  decimal(10,7)
@ServiceRequestID int 
	,@EnrouteMiles decimal(18,4) 
	,@ReturnMiles  decimal(18,4) 
	,@EstimatedHours decimal(18,4) 
	,@ProductID int 
	,@VendorLocationID int 
	,@VendorID int = NULL
) 
AS 
BEGIN

	SET FMTONLY OFF;
 	SET NOCOUNT ON;
 	
	DECLARE @ServiceLocationLatitude decimal(10,7)
		,@ServiceLocationLongitude decimal(10,7)
		,@ServiceLocationStateProvince varchar(20)
		,@ServiceLocationCountryCode varchar(20)
		,@DestinationLocationLatitude  decimal(10,7)
		,@DestinationLocationLongitude  decimal(10,7)
		,@ServiceMiles decimal(10,2)
		,@PrimaryCoverageLimitMileage int

	DECLARE @ServiceLocation as geography  

	SELECT 
		@ServiceLocationLatitude =ServiceLocationLatitude
		,@ServiceLocationLongitude=ServiceLocationLongitude
		,@ServiceLocationStateProvince=ServiceLocationStateProvince
		,@ServiceLocationCountryCode=ServiceLocationCountryCode
		,@DestinationLocationLatitude=DestinationLatitude
		,@DestinationLocationLongitude=DestinationLongitude
		,@ServiceMiles= ISNULL(ServiceMiles,0)
		,@PrimaryCoverageLimitMileage = ISNULL(PrimaryCoverageLimitMileage,0)
		FROM ServiceRequest Where 
		ID=@ServiceRequestID

	-- KB: Take the product from service request, if the param is null.
	IF (@ProductID IS NULL)
	BEGIN
	SELECT @ProductID = PrimaryProductID FROM ServiceRequest Where ID=@ServiceRequestID 
	END
	--PR: Take the VendorID From VendorLocation
	IF(@VendorID IS NULL)
	BEGIN
	SELECT @VendorID= VendorID from VendorLocation where ID=@VendorLocationID
	END

	SET @ServiceLocation = geography::Point(ISNULL(@ServiceLocationLatitude,0), ISNULL(@ServiceLocationLongitude,0), 4326)  
      
	SELECT 
		  @VendorLocationID AS VendorLocationID
		  ,RateDetail.ProductID
		  ,RateDetail.ProductName
		  ,RateDetail.RateTypeID
		  ,RateTypeName
		  ,RateDetail.Sequence
		  ,RateDetail.ContractedRate
		  ,RateDetail.RatePrice
		  ,RateDetail.RateQuantity
		  ,RateDetail.UnitOfMeasure
		  ,RateDetail.UnitOfMeasureSource
		  ,CASE 
				WHEN RateDetail.UnitOfMeasure = 'Each' THEN 1 
				WHEN RateDetail.UnitOfMeasure = 'Hour' THEN @EstimatedHours
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and RateDetail.RateQuantity = 0 THEN @EnrouteMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity = 0 and @PrimaryCoverageLimitMileage > 0 THEN @PrimaryCoverageLimitMileage
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity = 0 THEN @ServiceMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and RateDetail.RateQuantity <> 0 THEN (CASE WHEN RateDetail.RateQuantity > @EnrouteMiles THEN @EnrouteMiles ELSE RateDetail.RateQuantity END)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity <> 0 THEN (CASE WHEN RateDetail.RateQuantity > @ServiceMiles THEN @ServiceMiles ELSE RateDetail.RateQuantity END)
		  ELSE 0 END Quantity
	,ROUND(CASE 
		  WHEN RateDetail.UnitOfMeasure = 'Each' THEN RateDetail.RatePrice 
	WHEN RateDetail.UnitOfMeasure = 'Hour' THEN RateDetail.RatePrice * @EstimatedHours
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and RateDetail.RateQuantity = 0 THEN RateDetail.RatePrice * @EnrouteMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity = 0 and @PrimaryCoverageLimitMileage > 0 THEN RateDetail.RatePrice * @PrimaryCoverageLimitMileage
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity = 0 THEN RateDetail.RatePrice * @ServiceMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and RateDetail.RateQuantity <> 0 THEN RateDetail.RatePrice * (CASE WHEN RateDetail.RateQuantity > @EnrouteMiles THEN @EnrouteMiles ELSE RateDetail.RateQuantity END)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity <> 0 THEN RateDetail.RatePrice * (CASE WHEN RateDetail.RateQuantity > @ServiceMiles THEN @ServiceMiles ELSE RateDetail.RateQuantity END)
		  ELSE 0 END,2) ExtendedAmount
	,0 IsMemberPay
	INTO #PODetail
	FROM
		  (
		  Select 
				p.ID ProductID
				,p.Name ProductName
				,prt.RateTypeID 
				,rt.Name RateTypeName
				,prt.Sequence
				,CASE WHEN VendorLocationRate.Price IS NOT NULL THEN VendorLocationRate.Price
						  WHEN VendorDefaultRate.Price IS NOT NULL THEN VendorDefaultRate.Price
						  ELSE 0 END AS ContractedRate
				,CASE WHEN VendorLocationRate.Price IS NOT NULL THEN VendorLocationRate.Price
						  WHEN VendorDefaultRate.Price IS NOT NULL THEN VendorDefaultRate.Price
						  ELSE 0 END AS RatePrice
				,CASE WHEN VendorLocationRate.Price IS NOT NULL THEN VendorLocationRate.Quantity
						  WHEN VendorDefaultRate.Price IS NOT NULL THEN VendorDefaultRate.Quantity
						  ELSE 0 END AS RateQuantity
				,rt.UnitOfMeasure 
				,rt.UnitOfMeasureSource 
		  From dbo.Product p 
		  Join dbo.ProductRateType prt 
				On prt.ProductID = p.ID
		  Left Outer Join dbo.RateType rt 
				On prt.RateTypeID = rt.ID
		  LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() VendorLocationRate 
				ON VendorLocationRate.VendorID = @VendorID AND 
				p.ID = VendorLocationRate.ProductID AND 
				prt.RateTypeID = VendorLocationRate.RateTypeID AND
				VendorLocationRate.VendorLocationID = @VendorLocationID 
		  LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() VendorDefaultRate
				ON VendorDefaultRate.VendorID = @VendorID AND 
				p.ID = VendorDefaultRate.ProductID AND 
				prt.RateTypeID = VendorDefaultRate.RateTypeID AND
				VendorDefaultRate.VendorLocationID IS NULL
		  WHERE p.id = @ProductID
				and prt.IsOptional = 0
		  ) RateDetail

	--TP: Added logic to inject additional Member Pay line item for over program towing limit
	IF @PrimaryCoverageLimitMileage > 0 AND @ServiceMiles > @PrimaryCoverageLimitMileage
		INSERT INTO #PODetail
		SELECT VendorLocationID
			,ProductID
			,ProductName
			,RateTypeID
			,RateTypeName
			,Sequence
			,ContractedRate
			,RatePrice
			,RateQuantity
			,UnitOfMeasure
			,UnitOfMeasureSource
			,(@ServiceMiles - @PrimaryCoverageLimitMileage) Quantity
			,(@ServiceMiles - @PrimaryCoverageLimitMileage) * RatePrice ExtendedAmount
			,IsMemberPay = 1
		FROM #PODetail 
		WHERE RateTypeName = 'Service'
		ORDER BY Sequence

	SELECT 
		VendorLocationID
		,ProductID
		,ProductName
		,RateTypeID
		,RateTypeName
		,Sequence
		,ContractedRate
		,RatePrice
		,RateQuantity
		,UnitOfMeasure
		,UnitOfMeasureSource
		,Quantity
		,ExtendedAmount
		,IsMemberPay 
	FROM #PODetail
	ORDER BY Sequence

	DROP TABLE #PODetail
	

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
*  ---- for int, decimal, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Products_For_ProductCategory_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Products_For_ProductCategory_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_Products_For_ProductCategory_List_Get]
 CREATE PROCEDURE [dbo].[dms_Products_For_ProductCategory_List_Get]( 
   @productCategoryID INT = NULL 
 ) 
 AS 
 BEGIN 

SELECT 
	  p.ID
	, p.Name
	, p.IsActive
FROM Product p 
WHERE (p.ProductCategoryid = @ProductCategoryID OR @ProductCategoryID IS NULL)
AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')
AND p.ProductSubTypeID IN (SELECT ID FROM ProductSubType WHERE Name IN ('PrimaryService','SecondaryService'))
AND p.IsActive = 1 AND p.Name IS NOT NULL
 

 
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
 WHERE id = object_id(N'[dbo].[dms_ProgramManagement_ProgramServiceEventLimit_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ProgramManagement_ProgramServiceEventLimit_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_ProgramManagement_ProgramServiceEventLimit_List_Get
 CREATE PROCEDURE [dbo].[dms_ProgramManagement_ProgramServiceEventLimit_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID INT = NULL 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
ProgramOperator="-1" 
ProductCategoryOperator="-1" 
ProductOperator="-1" 
VehicleTypeOperator="-1" 
VehicleCategoryOperator="-1" 
PSELDescriptionOperator="-1" 
LimitOperator="-1" 
LimitDurationOperator="-1" 
LimitDurationUOMOperator="-1" 
StoredProcedureNameOperator="-1" 
IsActiveOperator="-1" 
CreateByOperator="-1" 
CreateDateOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
ProgramOperator INT NOT NULL,
ProgramValue nvarchar(100) NULL,
ProductCategoryOperator INT NOT NULL,
ProductCategoryValue nvarchar(100) NULL,
ProductOperator INT NOT NULL,
ProductValue nvarchar(100) NULL,
VehicleTypeOperator INT NOT NULL,
VehicleTypeValue nvarchar(100) NULL,
VehicleCategoryOperator INT NOT NULL,
VehicleCategoryValue nvarchar(100) NULL,
PSELDescriptionOperator INT NOT NULL,
PSELDescriptionValue nvarchar(255) NULL,
LimitOperator INT NOT NULL,
LimitValue int NULL,
LimitDurationOperator INT NOT NULL,
LimitDurationValue int NULL,
LimitDurationUOMOperator INT NOT NULL,
LimitDurationUOMValue nvarchar(100) NULL,
StoredProcedureNameOperator INT NOT NULL,
StoredProcedureNameValue nvarchar(100) NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue bit NULL,
CreateByOperator INT NOT NULL,
CreateByValue nvarchar(100) NULL,
CreateDateOperator INT NOT NULL,
CreateDateValue datetime NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	Program nvarchar(100)  NULL ,
	ProductCategory nvarchar(100)  NULL ,
	Product nvarchar(100)  NULL ,
	VehicleType nvarchar(100)  NULL ,
	VehicleCategory nvarchar(100)  NULL ,
	PSELDescription nvarchar(255)  NULL ,
	Limit int  NULL ,
	LimitDuration int  NULL ,
	LimitDurationUOM nvarchar(100)  NULL ,
	StoredProcedureName nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	CreateBy nvarchar(100)  NULL ,
	CreateDate datetime  NULL 
) 

 CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	Program nvarchar(100)  NULL ,
	ProductCategory nvarchar(100)  NULL ,
	Product nvarchar(100)  NULL ,
	VehicleType nvarchar(100)  NULL ,
	VehicleCategory nvarchar(100)  NULL ,
	PSELDescription nvarchar(255)  NULL ,
	Limit int  NULL ,
	LimitDuration int  NULL ,
	LimitDurationUOM nvarchar(100)  NULL ,
	StoredProcedureName nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	CreateBy nvarchar(100)  NULL ,
	CreateDate datetime  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@ProgramOperator','INT'),-1),
	T.c.value('@ProgramValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProductCategoryOperator','INT'),-1),
	T.c.value('@ProductCategoryValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProductOperator','INT'),-1),
	T.c.value('@ProductValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleTypeOperator','INT'),-1),
	T.c.value('@VehicleTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleCategoryOperator','INT'),-1),
	T.c.value('@VehicleCategoryValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PSELDescriptionOperator','INT'),-1),
	T.c.value('@PSELDescriptionValue','nvarchar(255)') ,
	ISNULL(T.c.value('@LimitOperator','INT'),-1),
	T.c.value('@LimitValue','int') ,
	ISNULL(T.c.value('@LimitDurationOperator','INT'),-1),
	T.c.value('@LimitDurationValue','int') ,
	ISNULL(T.c.value('@LimitDurationUOMOperator','INT'),-1),
	T.c.value('@LimitDurationUOMValue','nvarchar(100)') ,
	ISNULL(T.c.value('@StoredProcedureNameOperator','INT'),-1),
	T.c.value('@StoredProcedureNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@IsActiveOperator','INT'),-1),
	T.c.value('@IsActiveValue','bit') ,
	ISNULL(T.c.value('@CreateByOperator','INT'),-1),
	T.c.value('@CreateByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CreateDateOperator','INT'),-1),
	T.c.value('@CreateDateValue','datetime') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
Select 
	  PSEL.ID
	, P.[Description] AS Program
	, PC.[Description] AS ProductCategory
	, PD.Name AS Product
	, VT.Name AS VehicleType
	, VC.Name AS VehicleCategory
	, PSEL.Description AS PSELDescription
	, PSEL.Limit AS Limit
	, PSEL.LimitDuration
	, PSEL.LimitDurationUOM
	, PSEL.StoredProcedureName
	, PSEL.IsActive
	, PSEL.CreateBy
	, PSEL.CreateDate
FROM ProgramServiceEventLimit PSEL
LEFT JOIN Program P (NOLOCK) ON PSEL.ProgramID = P.ID
LEFT JOIN ProductCategory PC (NOLOCK) ON PSEL.ProductCategoryID = PC.ID
LEFT JOIN Product PD (NOLOCK) ON PSEL.ProductID = PD.ID
LEFT JOIN VehicleType VT (NOLOCK) ON PSEL.VehicleTypeID = VT.ID
LEFT JOIN VehicleCategory VC (NOLOCK) ON PSEL.VehicleCategoryID = VC.ID
WHERE P.ID = @programID


INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.Program,
	T.ProductCategory,
	T.Product,
	T.VehicleType,
	T.VehicleCategory,
	T.PSELDescription,
	T.Limit,
	T.LimitDuration,
	T.LimitDurationUOM,
	T.StoredProcedureName,
	T.IsActive,
	T.CreateBy,
	T.CreateDate
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
	 ( TMP.ProgramOperator = -1 ) 
 OR 
	 ( TMP.ProgramOperator = 0 AND T.Program IS NULL ) 
 OR 
	 ( TMP.ProgramOperator = 1 AND T.Program IS NOT NULL ) 
 OR 
	 ( TMP.ProgramOperator = 2 AND T.Program = TMP.ProgramValue ) 
 OR 
	 ( TMP.ProgramOperator = 3 AND T.Program <> TMP.ProgramValue ) 
 OR 
	 ( TMP.ProgramOperator = 4 AND T.Program LIKE TMP.ProgramValue + '%') 
 OR 
	 ( TMP.ProgramOperator = 5 AND T.Program LIKE '%' + TMP.ProgramValue ) 
 OR 
	 ( TMP.ProgramOperator = 6 AND T.Program LIKE '%' + TMP.ProgramValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProductCategoryOperator = -1 ) 
 OR 
	 ( TMP.ProductCategoryOperator = 0 AND T.ProductCategory IS NULL ) 
 OR 
	 ( TMP.ProductCategoryOperator = 1 AND T.ProductCategory IS NOT NULL ) 
 OR 
	 ( TMP.ProductCategoryOperator = 2 AND T.ProductCategory = TMP.ProductCategoryValue ) 
 OR 
	 ( TMP.ProductCategoryOperator = 3 AND T.ProductCategory <> TMP.ProductCategoryValue ) 
 OR 
	 ( TMP.ProductCategoryOperator = 4 AND T.ProductCategory LIKE TMP.ProductCategoryValue + '%') 
 OR 
	 ( TMP.ProductCategoryOperator = 5 AND T.ProductCategory LIKE '%' + TMP.ProductCategoryValue ) 
 OR 
	 ( TMP.ProductCategoryOperator = 6 AND T.ProductCategory LIKE '%' + TMP.ProductCategoryValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProductOperator = -1 ) 
 OR 
	 ( TMP.ProductOperator = 0 AND T.Product IS NULL ) 
 OR 
	 ( TMP.ProductOperator = 1 AND T.Product IS NOT NULL ) 
 OR 
	 ( TMP.ProductOperator = 2 AND T.Product = TMP.ProductValue ) 
 OR 
	 ( TMP.ProductOperator = 3 AND T.Product <> TMP.ProductValue ) 
 OR 
	 ( TMP.ProductOperator = 4 AND T.Product LIKE TMP.ProductValue + '%') 
 OR 
	 ( TMP.ProductOperator = 5 AND T.Product LIKE '%' + TMP.ProductValue ) 
 OR 
	 ( TMP.ProductOperator = 6 AND T.Product LIKE '%' + TMP.ProductValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VehicleTypeOperator = -1 ) 
 OR 
	 ( TMP.VehicleTypeOperator = 0 AND T.VehicleType IS NULL ) 
 OR 
	 ( TMP.VehicleTypeOperator = 1 AND T.VehicleType IS NOT NULL ) 
 OR 
	 ( TMP.VehicleTypeOperator = 2 AND T.VehicleType = TMP.VehicleTypeValue ) 
 OR 
	 ( TMP.VehicleTypeOperator = 3 AND T.VehicleType <> TMP.VehicleTypeValue ) 
 OR 
	 ( TMP.VehicleTypeOperator = 4 AND T.VehicleType LIKE TMP.VehicleTypeValue + '%') 
 OR 
	 ( TMP.VehicleTypeOperator = 5 AND T.VehicleType LIKE '%' + TMP.VehicleTypeValue ) 
 OR 
	 ( TMP.VehicleTypeOperator = 6 AND T.VehicleType LIKE '%' + TMP.VehicleTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VehicleCategoryOperator = -1 ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 0 AND T.VehicleCategory IS NULL ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 1 AND T.VehicleCategory IS NOT NULL ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 2 AND T.VehicleCategory = TMP.VehicleCategoryValue ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 3 AND T.VehicleCategory <> TMP.VehicleCategoryValue ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 4 AND T.VehicleCategory LIKE TMP.VehicleCategoryValue + '%') 
 OR 
	 ( TMP.VehicleCategoryOperator = 5 AND T.VehicleCategory LIKE '%' + TMP.VehicleCategoryValue ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 6 AND T.VehicleCategory LIKE '%' + TMP.VehicleCategoryValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PSELDescriptionOperator = -1 ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 0 AND T.PSELDescription IS NULL ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 1 AND T.PSELDescription IS NOT NULL ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 2 AND T.PSELDescription = TMP.PSELDescriptionValue ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 3 AND T.PSELDescription <> TMP.PSELDescriptionValue ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 4 AND T.PSELDescription LIKE TMP.PSELDescriptionValue + '%') 
 OR 
	 ( TMP.PSELDescriptionOperator = 5 AND T.PSELDescription LIKE '%' + TMP.PSELDescriptionValue ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 6 AND T.PSELDescription LIKE '%' + TMP.PSELDescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LimitOperator = -1 ) 
 OR 
	 ( TMP.LimitOperator = 0 AND T.Limit IS NULL ) 
 OR 
	 ( TMP.LimitOperator = 1 AND T.Limit IS NOT NULL ) 
 OR 
	 ( TMP.LimitOperator = 2 AND T.Limit = TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 3 AND T.Limit <> TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 7 AND T.Limit > TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 8 AND T.Limit >= TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 9 AND T.Limit < TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 10 AND T.Limit <= TMP.LimitValue ) 

 ) 

 AND 

 ( 
	 ( TMP.LimitDurationOperator = -1 ) 
 OR 
	 ( TMP.LimitDurationOperator = 0 AND T.LimitDuration IS NULL ) 
 OR 
	 ( TMP.LimitDurationOperator = 1 AND T.LimitDuration IS NOT NULL ) 
 OR 
	 ( TMP.LimitDurationOperator = 2 AND T.LimitDuration = TMP.LimitDurationValue ) 
 OR 
	 ( TMP.LimitDurationOperator = 3 AND T.LimitDuration <> TMP.LimitDurationValue ) 
 OR 
	 ( TMP.LimitDurationOperator = 7 AND T.LimitDuration > TMP.LimitDurationValue ) 
 OR 
	 ( TMP.LimitDurationOperator = 8 AND T.LimitDuration >= TMP.LimitDurationValue ) 
 OR 
	 ( TMP.LimitDurationOperator = 9 AND T.LimitDuration < TMP.LimitDurationValue ) 
 OR 
	 ( TMP.LimitDurationOperator = 10 AND T.LimitDuration <= TMP.LimitDurationValue ) 

 ) 

 AND 

 ( 
	 ( TMP.LimitDurationUOMOperator = -1 ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 0 AND T.LimitDurationUOM IS NULL ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 1 AND T.LimitDurationUOM IS NOT NULL ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 2 AND T.LimitDurationUOM = TMP.LimitDurationUOMValue ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 3 AND T.LimitDurationUOM <> TMP.LimitDurationUOMValue ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 4 AND T.LimitDurationUOM LIKE TMP.LimitDurationUOMValue + '%') 
 OR 
	 ( TMP.LimitDurationUOMOperator = 5 AND T.LimitDurationUOM LIKE '%' + TMP.LimitDurationUOMValue ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 6 AND T.LimitDurationUOM LIKE '%' + TMP.LimitDurationUOMValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.StoredProcedureNameOperator = -1 ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 0 AND T.StoredProcedureName IS NULL ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 1 AND T.StoredProcedureName IS NOT NULL ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 2 AND T.StoredProcedureName = TMP.StoredProcedureNameValue ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 3 AND T.StoredProcedureName <> TMP.StoredProcedureNameValue ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 4 AND T.StoredProcedureName LIKE TMP.StoredProcedureNameValue + '%') 
 OR 
	 ( TMP.StoredProcedureNameOperator = 5 AND T.StoredProcedureName LIKE '%' + TMP.StoredProcedureNameValue ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 6 AND T.StoredProcedureName LIKE '%' + TMP.StoredProcedureNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.IsActiveOperator = -1 ) 
 OR 
	 ( TMP.IsActiveOperator = 0 AND T.IsActive IS NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 1 AND T.IsActive IS NOT NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 2 AND T.IsActive = TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 3 AND T.IsActive <> TMP.IsActiveValue ) 
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
	 ( TMP.CreateDateOperator = -1 ) 
 OR 
	 ( TMP.CreateDateOperator = 0 AND T.CreateDate IS NULL ) 
 OR 
	 ( TMP.CreateDateOperator = 1 AND T.CreateDate IS NOT NULL ) 
 OR 
	 ( TMP.CreateDateOperator = 2 AND T.CreateDate = TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 3 AND T.CreateDate <> TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 7 AND T.CreateDate > TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 8 AND T.CreateDate >= TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 9 AND T.CreateDate < TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 10 AND T.CreateDate <= TMP.CreateDateValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'
	 THEN T.Program END ASC, 
	 CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'
	 THEN T.Program END DESC ,

	 CASE WHEN @sortColumn = 'ProductCategory' AND @sortOrder = 'ASC'
	 THEN T.ProductCategory END ASC, 
	 CASE WHEN @sortColumn = 'ProductCategory' AND @sortOrder = 'DESC'
	 THEN T.ProductCategory END DESC ,

	 CASE WHEN @sortColumn = 'Product' AND @sortOrder = 'ASC'
	 THEN T.Product END ASC, 
	 CASE WHEN @sortColumn = 'Product' AND @sortOrder = 'DESC'
	 THEN T.Product END DESC ,

	 CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'ASC'
	 THEN T.VehicleType END ASC, 
	 CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'DESC'
	 THEN T.VehicleType END DESC ,

	 CASE WHEN @sortColumn = 'VehicleCategory' AND @sortOrder = 'ASC'
	 THEN T.VehicleCategory END ASC, 
	 CASE WHEN @sortColumn = 'VehicleCategory' AND @sortOrder = 'DESC'
	 THEN T.VehicleCategory END DESC ,

	 CASE WHEN @sortColumn = 'PSELDescription' AND @sortOrder = 'ASC'
	 THEN T.PSELDescription END ASC, 
	 CASE WHEN @sortColumn = 'PSELDescription' AND @sortOrder = 'DESC'
	 THEN T.PSELDescription END DESC ,

	 CASE WHEN @sortColumn = 'Limit' AND @sortOrder = 'ASC'
	 THEN T.Limit END ASC, 
	 CASE WHEN @sortColumn = 'Limit' AND @sortOrder = 'DESC'
	 THEN T.Limit END DESC ,

	 CASE WHEN @sortColumn = 'LimitDuration' AND @sortOrder = 'ASC'
	 THEN T.LimitDuration END ASC, 
	 CASE WHEN @sortColumn = 'LimitDuration' AND @sortOrder = 'DESC'
	 THEN T.LimitDuration END DESC ,

	 CASE WHEN @sortColumn = 'LimitDurationUOM' AND @sortOrder = 'ASC'
	 THEN T.LimitDurationUOM END ASC, 
	 CASE WHEN @sortColumn = 'LimitDurationUOM' AND @sortOrder = 'DESC'
	 THEN T.LimitDurationUOM END DESC ,

	 CASE WHEN @sortColumn = 'StoredProcedureName' AND @sortOrder = 'ASC'
	 THEN T.StoredProcedureName END ASC, 
	 CASE WHEN @sortColumn = 'StoredProcedureName' AND @sortOrder = 'DESC'
	 THEN T.StoredProcedureName END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC ,

	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
	 THEN T.CreateBy END ASC, 
	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
	 THEN T.CreateBy END DESC ,

	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'
	 THEN T.CreateDate END ASC, 
	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'
	 THEN T.CreateDate END DESC 


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
 WHERE id = object_id(N'[dbo].[dms_VerifyProgramServiceBenefit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC dms_VerifyProgramServiceBenefit 1, 1, 1, 1, 1, NULL, NULL  
CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit]  
        @ProgramID INT   
      , @ProductCategoryID INT  
      , @VehicleCategoryID INT  
      , @VehicleTypeID INT  
      , @SecondaryCategoryID INT = NULL  
      , @ServiceRequestID  INT = NULL  
      , @ProductID INT = NULL  
AS  
BEGIN   
  
	SET NOCOUNT ON    
	SET FMTONLY OFF    

	--KB: 
	SET @ProductID = NULL

	DECLARE @SecondaryProductID INT
		,@OverrideCoverageLimit money 

	/*** Determine Primary and Secondary Product IDs ***/  
	/* Ignore Vehicle related values for Product Categories not requiring a Vehicle */
	IF @ProductCategoryID IN (SELECT ID FROM ProductCategory WHERE IsVehicleRequired = 0)
	BEGIN
		SET @VehicleCategoryID = NULL
		SET @VehicleTypeID = NULL
	END

	/* Select Basic Lockout over Locksmith when a specific product is not provided */  
	IF @ProductID IS NULL AND @ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Lockout')  
	BEGIN  
	SET @ProductID = (SELECT ID FROM Product WHERE Name = 'Basic Lockout')  
	END  

	/* Select Tire Change over Tire Repair when a specific product is not provided */  
	IF @ProductID IS NULL AND @ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tire')  
	BEGIN  
	SET @ProductID = (SELECT ID FROM Product WHERE Name like 'Tire Change%' AND VehicleCategoryID = @VehicleCategoryID)  
	END  

	IF @ProductID IS NULL  
	SELECT @ProductID = p.ID   
	FROM  ProductCategory pc (NOLOCK)   
	JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID   
	  AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')  
	  AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')  
	WHERE  
	pc.ID = @ProductCategoryID   
	AND (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)  
	AND (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)  


	IF @SecondaryCategoryID IS NOT NULL  
	SELECT @SecondaryProductID = p.ID   
	FROM  ProductCategory pc (NOLOCK)   
	JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID   
	  AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')  
	  AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')  
	WHERE  
	pc.ID = @SecondaryCategoryID   
	AND (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)  
	AND (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)  

	-- Coverage Limit Override for Ford ESP vehicles E/F 650 and 750
	IF @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Extended Service Plan (RV & COMM)')
	BEGIN
	IF EXISTS(
		SELECT * 
		FROM [Case] c
		JOIN ServiceRequest sr ON sr.CaseID = c.ID
		WHERE sr.ID = @ServiceRequestID
			AND (SUBSTRING(c.VehicleVIN, 6, 1) IN ('6','7')
				OR c.VehicleModel IN ('F-650', 'F-750'))
		)
		SET @OverrideCoverageLimit = 200.00
	END
   
	SELECT ISNULL(pc.Name,'') ProductCategoryName  
		,pc.ID ProductCategoryID  
		--,pc.Sequence  
		,ISNULL(vc.Name,'') VehicleCategoryName  
		,vc.ID VehicleCategoryID  
		,pp.ProductID  

		,CAST (pp.IsServiceCoverageBestValue AS BIT) AS IsServiceCoverageBestValue
		,CASE WHEN @OverrideCoverageLimit IS NOT NULL THEN @OverrideCoverageLimit ELSE pp.ServiceCoverageLimit END AS ServiceCoverageLimit
		,pp.CurrencyTypeID   
		,pp.ServiceMileageLimit   
		,pp.ServiceMileageLimitUOM   
		,1 AS IsServiceEligible
		--TP: Below logic is not needed; Only eligible services will be added to ProgramProduct 
		--,CASE WHEN pp.ServiceCoverageLimit IS NULL THEN 0   
		--              WHEN pp.IsServiceCoverageBestValue = 1 THEN 1  
		--              WHEN pp.ServiceCoverageLimit = 0 AND pp.IsReimbursementOnly = 1 THEN 1   
		--              WHEN pp.ServiceCoverageLimit = 0 AND ISNULL(pp.ServiceMileageLimit,0) > 0 THEN 1   
		--              WHEN pp.ServiceCoverageLimit = 0 AND pp.ProductID IN (SELECT p.ID FROM Product p WHERE p.ProductCategoryID IN (SELECT ID FROM ProductCategory WHERE Name IN ('Info', 'Tech', 'Concierge'))) THEN 1
		--              WHEN pp.ServiceCoverageLimit > 0 THEN 1  
		--              ELSE 0 END IsServiceEligible  
		,pp.IsServiceGuaranteed   
		,pp.ServiceCoverageDescription  
		,pp.IsReimbursementOnly  
		,CASE WHEN pc.ID = @SecondaryCategoryID THEN 0 ELSE 1 END AS IsPrimary  
	FROM ProgramProduct pp (NOLOCK)  
	JOIN Product p ON p.ID = pp.ProductID  
	LEFT OUTER JOIN ProductCategory pc (NOLOCK) ON pc.ID = p.ProductCategoryID  
	LEFT OUTER JOIN VehicleCategory vc (NOLOCK) ON vc.id = p.VehicleCategoryID  
	WHERE pp.ProgramID = @ProgramID  
	AND (pp.ProductID = @ProductID OR pp.ProductID = @SecondaryProductID)  
	ORDER BY   
	(CASE WHEN pc.ID = @SecondaryCategoryID THEN 0 ELSE 1 END) DESC  
	,pc.Sequence  
     
END  

GO


IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Claim_ApplyCashClaims_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Claim_ApplyCashClaims_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Claim_ApplyCashClaims_Get] 
CREATE PROCEDURE [dbo].[dms_Claim_ApplyCashClaims_Get]
AS  
BEGIN

-- Claim List
SELECT		CT.Name AS Type
			, C.ID AS ClaimNumber
			, C.ReceivedDate  
			, C.AmountRequested
			, CASE
                        WHEN ISNULL(C.PayeeType,'') = 'Member' THEN 'M-' + C.ContactName
                        WHEN ISNULL(C.PayeeType,'') = 'Vendor' THEN 'V-' + C.ContactName
                        ELSE C.ContactName
              END AS Payee
			, CS.Name AS Status
			, C.AmountApproved AS ApprovedAmount
			, C.ACESReferenceNumber
			, C.ACESSubmitDate
			, C.ACESOutcome
			, C.ACESAmount
			, CASE
				WHEN P.Name = 'Ford QFC' THEN 1
				ELSE 0
			  END AS QFCFlag
			,'' Applied 
			,CAST( 0 as bit) Selected
			, C.ACESFeeAmount
FROM		Claim C
JOIN		ClaimType CT ON CT.ID = C.ClaimTypeID
LEFT JOIN   ACESClaimStatus ACS ON ACS.ID = C.ACESClaimStatusID
JOIN		ClaimStatus CS ON CS.ID = C.ClaimStatusID
LEFT JOIN	Member M WITH(NOLOCK) ON M.ID = C.MemberID
LEFT JOIN	Program P WITH(NOLOCK) ON P.ID = M.ProgramID
LEFT JOIN	Vendor V WITH(NOLOCK) ON V.ID = C.VendorID
WHERE		CT.IsFordACES = 1
AND			CS.Name = 'Approved'
AND			ACS.Name = 'Approved'
AND			C.IsActive = 1
AND			ISNULL(C.ACESClearedDate,'') = ''
ORDER BY	QFCFlag DESC, C.ReceivedDate ASC

END

GO


/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_servicerequest_get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_servicerequest_get]
GO
/****** Object:  StoredProcedure [dbo].[dms_servicerequest_get]    Script Date: 07/03/2012 17:56:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC  [dbo].[dms_servicerequest_get] 1414
CREATE PROCEDURE [dbo].[dms_servicerequest_get](
   @serviceRequestID INT=NULL
)
AS
BEGIN
SET NOCOUNT ON

declare @MemberID INT=NULL
-- GET CASE ID
SET   @MemberID =(SELECT CaseID FROM [ServiceRequest](NOLOCK) WHERE ID = @serviceRequestID)
-- GET Member ID
SET @MemberID =(SELECT MemberID FROM [Case](NOLOCK) WHERE ID = @MemberID)

DECLARE @ProductID INT
SET @ProductID =NULL
SELECT  @ProductID = PrimaryProductID FROM ServiceRequest(NOLOCK) WHERE ID = @serviceRequestID

DECLARE @memberEntityID INT
DECLARE @vendorLocationEntityID INT
DECLARE @otherReasonID INT
DECLARE @dispatchPhoneTypeID INT

SET @memberEntityID = (SELECT ID FROM Entity(NOLOCK) WHERE Name ='Member')
SET @vendorLocationEntityID = (SELECT ID FROM Entity(NOLOCK) WHERE Name ='VendorLocation')
SET @otherReasonID = (Select ID From PurchaseOrderCancellationReason(NOLOCK) Where Name ='Other')
SET @dispatchPhoneTypeID = (SELECT ID FROM PhoneType(NOLOCK) WHERE Name ='Dispatch')

SELECT
		-- Service Request Data Section
		-- Column 1		
		SR.CaseID,
		C.IsDeliveryDriver,
		SR.ID AS [RequestNumber],
		SRS.Name AS [Status],
		SRP.Name AS [Priority],
		SR.CreateDate AS [CreateDate],
		SR.CreateBy AS [CreateBy],
		SR.ModifyDate AS [ModifyDate],
		SR.ModifyBy AS [ModifyBy],
		-- Column 2
		NA.Name AS [NextAction],
		SR.NextActionScheduledDate AS [NextActionScheduledDate],
		SASU.FirstName +' '+ SASU.LastName AS [NextActionAssignedTo],
		CLS.Name AS [ClosedLoop],
		SR.ClosedLoopNextSend AS [ClosedLoopNextSend],
		-- Column 3
		CASE WHEN SR.IsPossibleTow = 1 THEN PC.Name +'/Possible Tow'ELSE PC.Name +''END AS [ServiceCategory],
		CASE
			WHEN SRS.Name ='Dispatched'
				  THEN CONVERT(VARCHAR(6),DATEDIFF(SECOND,sr.CreateDate,GETDATE())/3600)+':'
						+RIGHT('0'+CONVERT(VARCHAR(2),(DATEDIFF(SECOND,sr.CreateDate,GETDATE())%3600)/60),2)
			ELSE''
		END AS [Elapsed],
		(SELECT MAX(IssueDate)FROM PurchaseOrder(NOLOCK) Where ServiceRequestID = @ServiceRequestID) AS [PoMaxIssueDate],
		(SELECT MAX(ETADate)FROM PurchaseOrder(NOLOCK) Where ServiceRequestID = @ServiceRequestID) AS [PoMaxETADate],
		SR.DataTransferDate AS [DataTransferDate],

		-- Member data  
		REPLACE(RTRIM(
		COALESCE(m.FirstName,'')+
		COALESCE(' '+left(m.MiddleName,1),'')+
		COALESCE(' '+ m.LastName,'')+
		COALESCE(' '+ m.Suffix,'')
		),'  ',' ')AS [Member],
		MS.MembershipNumber,
		C.MemberStatus,
		CL.Name AS [Client],
		P.Name AS [ProgramName],
		CONVERT(varchar(10),M.MemberSinceDate,101)AS [MemberSince],
		CONVERT(varchar(10),M.ExpirationDate,101)AS [ExpirationDate],
		MS.ClientReferenceNumber as [ClientReferenceNumber],
		ISNULL((SELECT NAME FROM PhoneType(NOLOCK) WHERE ID = c.ContactPhoneTypeID),'')AS [CallbackPhoneType],
		C.ContactPhoneNumber AS [CallbackNumber],
		ISNULL((SELECT NAME FROM PhoneType(NOLOCK) WHERE ID = c.ContactAltPhoneTypeID),'')AS [AlternatePhoneType],
		C.ContactAltPhoneNumber AS [AlternateNumber],
		ISNULL(MA.Line1,'')AS Line1,
		ISNULL(MA.Line2,'')AS Line2,
		ISNULL(MA.Line3,'')AS Line3,
		REPLACE(RTRIM(
			COALESCE(MA.City,'')+
			COALESCE(', '+RTRIM(MA.StateProvince),'')+
			COALESCE(' '+LTRIM(MA.PostalCode),'')+
			COALESCE(' '+ MA.CountryCode,'')
			),' ',' ')AS MemberCityStateZipCountry,

		-- Vehicle Section
		-- Vehcile 
		ISNULL(RTRIM(COALESCE(c.VehicleYear +' ','')+
		COALESCE(CASE c.VehicleMake WHEN'Other'THEN C.VehicleMakeOther ELSE C.VehicleMake END+' ','')+
		COALESCE(CASE C.VehicleModel WHEN'Other'THEN C.VehicleModelOther ELSE C.VehicleModel END,'')),' ')AS [YearMakeModel],
		VT.Name +' - '+ VC.Name AS [VehicleTypeAndCategory],
		C.VehicleColor AS [VehicleColor],
		C.VehicleVIN AS [VehicleVIN],
		COALESCE(C.VehicleLicenseState +'-','')+COALESCE(c.VehicleLicenseNumber,'')AS [License],
		C.VehicleDescription,
		-- For vehicle type = RV only  
		RVT.Name AS [RVType],
		C.VehicleChassis AS [VehicleChassis],
		C.VehicleEngine AS [VehicleEngine],
		C.VehicleTransmission AS [VehicleTransmission],
		-- Location  
		SR.ServiceLocationAddress +' '+ SR.ServiceLocationCountryCode AS [ServiceLocationAddress],
		SR.ServiceLocationDescription,
		-- Destination
		SR.DestinationAddress +' '+ SR.DestinationCountryCode AS [DestinationAddress],
		SR.DestinationDescription,

		-- Service Section 
		CASE
			WHEN SR.IsPossibleTow = 1 
			THEN PC.Name +'/Possible Tow'
			ELSE PC.Name
		END AS [ServiceCategorySection],
		SR.PrimaryCoverageLimit AS CoverageLimit,
		CASE
			WHEN C.IsSafe IN(NULL,1)
			THEN'Yes'
			ELSE'No'
		END AS [Safe],
		SR.PrimaryProductID,
		(SELECT Name FROM Product WHERE ID = SR.PrimaryProductID) AS PrimaryProductName,
		SR.PrimaryServiceEligiblityMessage,
		SR.SecondaryProductID,
		(SELECT Name FROM Product WHERE ID = SR.SecondaryProductID) AS SecondaryProductName,
		SR.SecondaryServiceEligiblityMessage,
		SR.IsPrimaryOverallCovered,
		SR.IsSecondaryOverallCovered,
		SR.IsPossibleTow,
		

		-- Service Q&A's


		---- Service Provider Section  
		--CASE 
		--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NOT NULL THEN 'Contracted'
		--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NULL THEN 'Not Contracted'
		--	WHEN c.ID IS NOT NULL THEN 'Contracted' 
		--	ELSE 'Not Contracted'
		--	END as ContractStatus,
		CASE
			WHEN ContractedVendors.ContractID IS NOT NULL 
				AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'
			ELSE 'Not Contracted' 
			END AS ContractStatus,
		V.Name AS [VendorName],
		V.ID AS [VendorID],
		V.VendorNumber AS [VendorNumber],
		(SELECT TOP 1 PE.PhoneNumber
			FROM PhoneEntity PE
			WHERE PE.RecordID = VL.ID
			AND PE.EntityID = @vendorLocationEntityID
			AND PE.PhoneTypeID = @dispatchPhoneTypeID
			ORDER BY PE.ID DESC
		) AS [VendorLocationPhoneNumber] ,
		VLA.Line1 AS [VendorLocationLine1],
		VLA.Line2 AS [VendorLocationLine2],
		VLA.Line3 AS [VendorLocationLine3],
		REPLACE(RTRIM(
			COALESCE(VLA.City,'')+
			COALESCE(', '+RTRIM(VLA.StateProvince),'')+
			COALESCE(' '+LTRIM(VLA.PostalCode),'')+
			COALESCE(' '+ VLA.CountryCode,'')
			),' ',' ')AS VendorCityStateZipCountry,
		-- PO data
		convert(int,PO.PurchaseOrderNumber) AS [PONumber],
		PO.LegacyReferenceNumber,
		--convert(int,PO.ID) AS [PONumber],
		POS.Name AS [POStatus],
		CASE
				WHEN PO.CancellationReasonID = @otherReasonID
				THEN PO.CancellationReasonOther 
				ELSE ISNULL(CR.Name,'')
		END AS [CancelReason],
		PO.PurchaseOrderAmount AS [POAmount],
		POPC.Name AS [ServiceType],
		PO.IssueDate AS [IssueDate],
		PO.ETADate AS [ETADate],
		PO.DataTransferDate AS [ExtractDate],

		-- Other
		CASE WHEN C.AssignedToUserID IS NOT NULL
			THEN'*'+ISNULL(ASU.FirstName,'')+' '+ISNULL(ASU.LastName,'')
			ELSE ISNULL(SASU.FirstName,'')+' '+ISNULL(SASU.LastName,'')
		END AS [AssignedTo],
		C.AssignedToUserID AS [AssignedToID],
      
      -- Vendor Invoice Details
		VI.InvoiceDate,
		CASE	WHEN PT.Name = 'ACH' 
		THEN 'ACH'
				WHEN PT.Name = 'Check'
		THEN VI.PaymentNumber
		ELSE ''
		END AS PaymentType,
		
		VI.PaymentAmount,
		VI.PaymentDate,
		VI.CheckClearedDate
FROM [ServiceRequest](NOLOCK) SR  
JOIN [Case](NOLOCK) C ON C.ID = SR.CaseID  
JOIN [ServiceRequestStatus](NOLOCK) SRS ON SR.ServiceRequestStatusID = SRS.ID  
LEFT JOIN [ServiceRequestPriority](NOLOCK) SRP ON SR.ServiceRequestPriorityID = SRP.ID   
LEFT JOIN [Program](NOLOCK) P ON C.ProgramID = P.ID   
LEFT JOIN [Client](NOLOCK) CL ON P.ClientID = CL.ID  
LEFT JOIN [Member](NOLOCK) M ON C.MemberID = M.ID  
LEFT JOIN [Membership](NOLOCK) MS ON M.MembershipID = MS.ID  
LEFT JOIN [AddressEntity](NOLOCK) MA ON M.ID = MA.RecordID  
            AND MA.EntityID = @memberEntityID
LEFT JOIN [Country](NOLOCK) MCNTRY ON MA.CountryCode = MCNTRY.ISOCode  
LEFT JOIN [Country](NOLOCK) LCNTRY ON SR.ServiceLocationCountryCode = LCNTRY.ISOCode  
LEFT JOIN [Country](NOLOCK) DCNTRY ON SR.DestinationCountryCode = DCNTRY.ISOCode  
LEFT JOIN [VehicleType](NOLOCK) VT ON C.VehicleTypeID = VT.ID  
LEFT JOIN [VehicleCategory](NOLOCK) VC ON C.VehicleCategoryID = VC.ID  
LEFT JOIN [RVType](NOLOCK) RVT ON C.VehicleRVTypeID = RVT.ID  
LEFT JOIN [ProductCategory](NOLOCK) PC ON PC.ID = SR.ProductCategoryID  
LEFT JOIN [User](NOLOCK) ASU ON C.AssignedToUserID = ASU.ID  
LEFT OUTER JOIN [User](NOLOCK) SASU ON SR.NextActionAssignedToUserID = SASU.ID  
LEFT JOIN [PurchaseOrder](NOLOCK) PO ON PO.ServiceRequestID = SR.ID  AND PO.IsActive = 1 
LEFT JOIN [PurchaseOrderStatus](NOLOCK) POS ON PO.PurchaseOrderStatusID = POS.ID
LEFT JOIN [PurchaseOrderCancellationReason](NOLOCK) CR ON PO.CancellationReasonID = CR.ID
LEFT JOIN [Product](NOLOCK) PR ON PO.ProductID = PR.ID
LEFT JOIN [ProductCategory](NOLOCK) POPC ON PR.ProductCategoryID = POPC.ID
LEFT JOIN [VendorLocation](NOLOCK) VL ON PO.VendorLocationID = VL.ID  
LEFT JOIN [AddressEntity](NOLOCK) VLA ON VL.ID = VLA.RecordID 
            AND VLA.EntityID =@vendorLocationEntityID
LEFT JOIN [Vendor](NOLOCK) V ON VL.VendorID = V.ID 
LEFT JOIN [Contract](NOLOCK) CON on CON.VendorID = V.ID and CON.IsActive = 1 and CON.ContractStatusID = (Select ID From ContractStatus Where Name = 'Active')
LEFT JOIN [ClosedLoopStatus](NOLOCK) CLS ON SR.ClosedLoopStatusID = CLS.ID 
LEFT JOIN [NextAction](NOLOCK) NA ON SR.NextActionID = NA.ID

--Join to get information needed to determine Vendor Contract status ********************
--LEFT OUTER JOIN (
--      SELECT DISTINCT vr.VendorID, vr.ProductID
--      FROM dbo.fnGetCurrentProductRatesByVendorLocation() vr 
--      ) DefaultVendorRates ON v.ID = DefaultVendorRates.VendorID And @ProductID = DefaultVendorRates.ProductID
LEFT OUTER JOIN(
	  SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID
	  FROM dbo.fnGetContractedVendors() cv
	  ) ContractedVendors ON v.ID = ContractedVendors.VendorID 
      
LEFT JOIN [VendorInvoice] VI WITH (NOLOCK) ON PO.ID = VI.PurchaseOrderID
LEFT JOIN [PaymentType] PT WITH (NOLOCK) ON VI.PaymentTypeID = PT.ID
WHERE SR.ID = @serviceRequestID

END

GO