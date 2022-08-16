IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_CCImport_CreditCardChargedTransactions]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_CCImport_CreditCardChargedTransactions] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
 CREATE PROCEDURE [dbo].[dms_CCImport_CreditCardChargedTransactions] ( 
   @processGUID UNIQUEIDENTIFIER = NULL
 ) 
 
AS
BEGIN

	DECLARE @Results AS TABLE(TotalRecordCount INT,
							  TotalRecordsIgnored INT,
							  TotalCreditCardAdded INT,
							  TotalTransactionAdded INT,
							  TotalErrorRecords INT)
							  
	-- Helpers
	DECLARE @TotalRecordCount INT	= 0
	DECLARE @TotalRecordsIgnored INT = 0
	DECLARE @TotalCreditCardAdded INT = 0
	DECLARE @TotalTransactionAdded INT = 0
	DECLARE @TotalErrorRecords INT	= 0	 			  

	-- Step 1 : Insert Records INTO Temporary Credit Card
	DECLARE @startROWParent INT 
	DECLARE @totalRowsParent INT
	
	DECLARE @purchaseOrderNumber NVARCHAR(50) 
	DECLARE @creditCardNumber NVARCHAR(50)
	DECLARE @chargedDate DATE
	DECLARE @chargedAmount MONEY
	DECLARE @transactionDate DATE
	DECLARE @TemporaryCreditCardPostedStatusID int
	
	DECLARE @ParentRecordID INT = NULL
	DECLARE @ChildRecordID INT = NULL
	DECLARE @newRecordID INT
	
	SET @startROWParent =  (SELECT MIN(RecordID) FROM TemporaryCreditCard_Import_ChargedTransactions 
												 WHERE ProcessIdentifier = @processGUID)
	SET @totalRowsParent = (SELECT MAX(RecordID) FROM TemporaryCreditCard_Import_ChargedTransactions 
												 WHERE ProcessIdentifier = @processGUID)
	SET @TemporaryCreditCardPostedStatusID = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Posted')
	
	WHILE(@startROWParent <= @totalRowsParent)  
	BEGIN	
		
		SELECT @creditCardNumber    = FINVirtualCardNumber_C_CreditCardNumber,
			   @purchaseOrderNumber = FINCFFData02_C_OriginalReferencePurchaseOrderNumber,
			   @chargedDate			= FINPostingDate_ChargeDate,
			   @chargedAmount		= FINTransactionAmount_ChargeAmount,
			   @transactionDate		= FINTransactionDate_C_IssueDate_TransactionDate
		FROM TemporaryCreditCard_Import_ChargedTransactions
		WHERE RecordID = @startROWParent
		
		SET @ParentRecordID =   (SELECT tcc.ID
								 FROM TemporaryCreditCard tcc
								 --- Get Last Issue matching the last 6 digits of the CC
								 JOIN (
									SELECT right(CreditCardNumber, 6) Last6OfCC, MAX(IssueDate) MaxIssueDate
									FROM TemporaryCreditCard
									GROUP BY right(CreditCardNumber, 6)
									) LastIssueEntry ON LastIssueEntry.Last6OfCC = right(tcc.CreditCardNumber, 6) 
										AND LastIssueEntry.MaxIssueDate = tcc.IssueDate
								 WHERE right(tcc.CreditCardNumber, 6) = right(@creditCardNumber,6)
								 ---- Removed this condition since the PO number does not always make it into the Charge transaction
								 AND ltrim(rtrim(isnull(tcc.OriginalReferencePurchaseOrderNumber,''))) = ltrim(rtrim(isnull(@purchaseOrderNumber,'')))
								 AND Cast(Convert(varchar, tcc.IssueDate,101) as datetime) <= @chargedDate
								 ---- The last 6 digits of the CC can be same for different CCs, so don't look back too far for this matching Issue
								 --AND tcc.IssueDate >= DATEADD(dd, -60, GetDate())
								 AND tcc.TemporaryCreditCardStatusID <> @TemporaryCreditCardPostedStatusID  -- Don't post charges after Posted
								 )
			 
	    IF (@ParentRecordID IS NULL)
			  BEGIN
					UPDATE TemporaryCreditCard_Import_ChargedTransactions 
					SET ExceptionMessage = 'No matching TemporaryCreditCard for input charge transaction'
					WHERE RecordID = @startROWParent
			  END
		ELSE
			 BEGIN
					UPDATE TemporaryCreditCard_Import_ChargedTransactions 
					SET TemporaryCreditCardID = @ParentRecordID WHERE RecordID = @startROWParent
					
					SET    @ChildRecordID = (SELECT tccd.ID
						   FROM TemporaryCreditCard tcc
						   JOIN TemporaryCreditCardDetail tccd
						   ON tcc.ID = tccd.TemporaryCreditCardID
						   WHERE right(isnull(tcc.CreditCardNumber,''), 6) = 
						   right(isnull(@creditCardNumber,''), 6)
						   AND tccd.TransactionDate = @transactionDate
						   AND tccd.ChargeDate = @chargedDate
						   AND tccd.TransactionType = 'Charge'
						   AND ltrim(rtrim(isnull(tcc.OriginalReferencePurchaseOrderNumber,''))) 
						   = ltrim(rtrim(isnull(@purchaseOrderNumber,'')))
						   AND tccd.ChargeAmount = @chargedAmount)
					
					IF(@ChildRecordID IS NULL)
					BEGIN
						 INSERT INTO TemporaryCreditCardDetail(TemporaryCreditCardID,
															   TransactionSequence,
															   TransactionDate,
															   TransactionType,
															   TransactionBy,
															   RequestedAmount,
															   ApprovedAmount,
															   AvailableBalance,
															   ChargeDate,
															   ChargeAmount,
															   ChargeDescription,
															   CreateDate,
															   CreateBy,
															   ModifyDate,
															   ModifyBy)
						 SELECT @ParentRecordID,
								TransactionSequence,
								FINTransactionDate_C_IssueDate_TransactionDate,
								TransactionType,
								TransactionBy,
								RequestedAmount,
								ApprovedAmount,
								AvailableBalance,
								FINPostingDate_ChargeDate,
								FINTransactionAmount_ChargeAmount,
								FINTransactionDescription_ChargeDescription,
								CreateDate,
								CreatedBy,
								ModifyDate,
								ModifiedBy
						 FROM TemporaryCreditCard_Import_ChargedTransactions
						 WHERE RecordID = @startROWParent
						 
						 SET @newRecordID = SCOPE_IDENTITY()
						 
						 UPDATE TemporaryCreditCard_Import_ChargedTransactions
						 SET TemporaryCreditCardDetailsID = @newRecordID
						 WHERE RecordID = @startROWParent
					END

			 END
		SET @startROWParent = @startROWParent + 1
	END
	
	-- Step 3 Update Counts
	SET @TotalRecordCount = (SELECT COUNT(*) FROM TemporaryCreditCard_Import_ChargedTransactions WHERE 
							 ProcessIdentifier = @processGUID)
	
							  
	SET @TotalTransactionAdded = (SELECT COUNT(*) FROM TemporaryCreditCard_Import_ChargedTransactions
							     WHERE TemporaryCreditCardDetailsID IS NOT NULL AND ProcessIdentifier = @processGUID)
			
	SET @TotalErrorRecords = (SELECT COUNT(*) FROM TemporaryCreditCard_Import_ChargedTransactions
							     WHERE TemporaryCreditCardID IS NULL AND ProcessIdentifier = @processGUID)				     
							   
	
	-- Step 4 Insert Counts
	INSERT INTO @Results(TotalRecordCount,
						 TotalRecordsIgnored,
						 TotalCreditCardAdded,
						 TotalTransactionAdded,
						 TotalErrorRecords)
	VALUES(@TotalRecordCount,@TotalRecordsIgnored,@TotalCreditCardAdded,@TotalTransactionAdded,
	@TotalErrorRecords)
	
	-- Step 5 Show Results
	SELECT * FROM @Results
END
GO
