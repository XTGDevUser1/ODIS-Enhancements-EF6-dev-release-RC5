IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Client_OpenPeriodProcess]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Client_OpenPeriodProcess] 
END 
GO
CREATE PROC [dbo].[dms_Client_OpenPeriodProcess](@billingDefinitionInvoiceID INT,
												 @billingScheduleID INT,
												 @scheduleTypeID INT,
												 @scheduleDateTypeID INT,
												 @scheduleRangeTypeID INT,
												 @userName NVARCHAR(100),
												 @sessionID NVARCHAR(MAX),
												 @pageReference NVARCHAR(MAX))
AS
BEGIN
		BEGIN TRY
		BEGIN TRAN
			
			DECLARE @entityID AS INT 
			DECLARE @eventID AS INT
			DECLARE	@eventDescription AS NVARCHAR(MAX)
			SELECT  @entityID = ID FROM Entity WHERE Name = 'BillingInvoice'
			SELECT  @eventID =  ID FROM Event WHERE Name = 'OpenPeriod'
			SELECT  @eventDescription =  Description FROM Event WHERE Name = 'OpenPeriod'
			
			DECLARE @pInvoiceXML AS NVARCHAR(MAX)
			SET @pInvoiceXML = '<Records><BillingDefinitionInvoiceID>' + CONVERT(NVARCHAR(50),@billingDefinitionInvoiceID) + '</BillingDefinitionInvoiceID></Records>'
			
			EXEC dbo.dms_BillingGenerateInvoices 
				 @pUserName  = @userName,
				 @pScheduleTypeID = @scheduleTypeID,
				 @pScheduleDateTypeID = @scheduleDateTypeID,
				 @pScheduleRangeTypeID = @scheduleRangeTypeID,
				 @pInvoicesXML = @pInvoiceXML
		
			--TO DO :
			-- Create Event Logs Reocords
			--INSERT INTO		EventLog([EventID],				[SessionID],				[Source],			[Description],
			--						[Data],				[NotificationQueueDate],	[CreateBy],			[CreateDate]) 
			--			VALUES		(@eventID,				@sessionID,					@pageReference,	   @eventDescription,
			--						NULL,					NULL,						@userName,			GETDATE())
		   -- CREATE Link Records
			--INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) VALUES(SCOPE_IDENTITY(),@entityID,@billingScheduleID)
			
			UPDATE	BillingSchedule
			SET		ScheduleStatusID = (SELECT ID From BillingScheduleStatus WHERE Name = 'OPEN')
			WHERE	ID = @billingScheduleID
			AND	    ScheduleTypeID = @scheduleTypeID
			AND		ScheduleDateTypeID = @scheduleDateTypeID
			AND		ScheduleRangeTypeID = @scheduleRangeTypeID
			
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		DECLARE @ErrorMessage    NVARCHAR(4000)			
		-- Assign variables to error-handling functions that 
		-- capture information for RAISERROR.
		SELECT  @ErrorMessage = ERROR_MESSAGE();
		RAISERROR(@ErrorMessage,16,1);
	END CATCH
END

IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Client_OpenPeriodToBeProcessRecords]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Client_OpenPeriodToBeProcessRecords] 
END 
GO

CREATE PROC [dbo].[dms_Client_OpenPeriodToBeProcessRecords](@billingSchedules NVARCHAR(MAX) = NULL)
AS
BEGIN
	
	DECLARE @BillingScheduleID AS TABLE(RecordID INT IDENTITY(1,1), BillingScheduleID INT)
	INSERT INTO @BillingScheduleID(BillingScheduleID) SELECT item FROM dbo.fnSplitString(@billingSchedules,',')
	
	SELECT BDI.ID BillingDefinitionInvoiceID,
		   BDI.Description AS BillingDefinitionInvoiceDescription,
		   BC.ID BillingSchedueID,
		   BC.ScheduleTypeID,
		   BC.ScheduleDateTypeID,
		   BC.ScheduleRangeTypeID
		   FROM BillingDefinitionInvoice BDI
		   LEFT JOIN BillingSchedule BC 
		   ON   BDI.ScheduleTypeID = BC.ScheduleTypeID
		   AND  BDI.ScheduleDateTypeID = BC.ScheduleDateTypeID
		   AND  BDI.ScheduleRangeTypeID = BC.ScheduleRangeTypeID
	WHERE  BC.IsActive = 1
	AND	   BC.ID IN (SELECT BillingScheduleID FROM @BillingScheduleID)
END


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
	ACESClearedDate DATETIME NULL
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
	ACESClearedDate DATETIME NULL 
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
    T.ACESClearedDate
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
	T.ACESClearedDate
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
	 THEN T.ACESClearedDate END DESC


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





