IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_CCImport_CreditCardIssueTransactions]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_CCImport_CreditCardIssueTransactions]
GO
CREATE PROC [dbo].dms_CCImport_CreditCardIssueTransactions(@processGUID UNIQUEIDENTIFIER = NULL)
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
	DECLARE @creditCardIssueNumber NVARCHAR(50) 
	DECLARE @creditCardNumber NVARCHAR(50)
	DECLARE @purchaseType NVARCHAR(50)
	DECLARE @transactionSequence INT
	DECLARE @tempLookUpID INT
	DECLARE @newRecordID INT
	
	SET @startROWParent =  (SELECT MIN(RecordID) FROM TemporaryCreditCard_Import 
												 WHERE ProcessIdentifier = @processGUID)
	SET @totalRowsParent = (SELECT MAX(RecordID) FROM TemporaryCreditCard_Import 
												 WHERE ProcessIdentifier = @processGUID)
	
	WHILE(@startROWParent <= @totalRowsParent)  
	BEGIN
		SELECT  @creditCardIssueNumber = IMP.PurchaseID_CreditCardIssueNumber,
				@creditCardNumber = IMP.CPN_PAN_CreditCardNumber,
				@purchaseType = IMP.PURCHASE_TYPE
		FROM TemporaryCreditCard_Import IMP
		WHERE RecordID = @startROWParent
		
		IF(@creditCardNumber IS NULL OR @creditCardNumber = '' OR @purchaseType != 'ISP Claims')
			BEGIN
				INSERT INTO [Log]([Date],[Thread],[Level],[Logger], [Message]) VALUES(GETDATE(),01,'INFO','dms_CCImport_CreditCardIssueTransactions','Business Rule Failed for more information Use Record ID ' + CONVERT(NVARCHAR(100),@startROWParent) + ' TemporaryCreditCard_Import')
			END
		ELSE
			BEGIN
				IF(NOT EXISTS(SELECT * FROM TemporaryCreditCard TCC WHERE 
																TCC.CreditCardIssueNumber = @creditCardIssueNumber AND 
																TCC.CreditCardNumber = @creditCardNumber))
				 BEGIN
				INSERT INTO TemporaryCreditCard(CreditCardIssueNumber,			
								CreditCardNumber,			
								PurchaseOrderID,									
								VendorInvoiceID,				
								IssueDate,					
								IssueBy,
								IssueStatus,					
								ReferencePurchaseOrderNumber,				 
								OriginalReferencePurchaseOrderNumber,					 
								ReferenceVendorNumber,
								ApprovedAmount,					
								TotalChargedAmount,
								TemporaryCreditCardStatusID,									
								ExceptionMessage,				
								Note,						
								CreateDate,
								CreateBy,						
								ModifyDate,					
								ModifyBy) 
					SELECT PurchaseID_CreditCardIssueNumber,
						   CPN_PAN_CreditCardNumber,
						   PurchaseOrderID,
						   VendorInvoiceID,
						   CREATE_DATE_IssueDate_TransactionDate,
						   USER_NAME_IssueBy_TransactionBy,
						   IssueStatus,
						   CDF_PO_ReferencePurchaseOrderNumber,
						   CDF_PO_OriginalReferencePurchaseOrderNumber,
						   CDF_ISP_Vendor_ReferenceVendorNumber,
						   ApprovedAmount,
						   TotalChargeAmount,
						   TemporaryCreditCardStatusID,
						   ExceptionMessage,
						   Note,
						   CreateDate,
						   CreateBy,
						   ModifyDate,
						   ModifyBy
					FROM TemporaryCreditCard_Import S1 WHERE S1.RecordID = @startROWParent
				
				SET @newRecordID = SCOPE_IDENTITY()	
			
				UPDATE TemporaryCreditCard_Import SET TemporaryCreditCardID = @newRecordID
				WHERE RecordID = @startROWParent
			END
			END
		
		SET @startROWParent = @startROWParent + 1
	END
	
	-- Step 2 : Insert Records Into Temporary Credit Card Details
	SET @startROWParent =  (SELECT MIN(RecordID) FROM TemporaryCreditCard_Import 
												 WHERE ProcessIdentifier = @processGUID)
	
	SET @totalRowsParent = (SELECT MAX(RecordID) FROM TemporaryCreditCard_Import 
												 WHERE ProcessIdentifier = @processGUID)
												 
	WHILE(@startROWParent <= @totalRowsParent)  
	BEGIN
		SELECT  @creditCardIssueNumber = IMP.PurchaseID_CreditCardIssueNumber,
				@creditCardNumber = IMP.CPN_PAN_CreditCardNumber,
				@transactionSequence = IMP.HISTORY_ID_TransactionSequence,
				@purchaseType = IMP.PURCHASE_TYPE
		FROM TemporaryCreditCard_Import IMP
		WHERE RecordID = @startROWParent
		
		IF(@creditCardNumber IS NOT NULL AND @creditCardNumber != '' AND @purchaseType = 'ISP Claims')
		BEGIN
			IF(NOT EXISTS(SELECT tcc.ID, tccd.ID
					FROM TemporaryCreditCard tcc
					JOIN TemporaryCreditCardDetail tccd
						ON tcc.ID = tccd.TemporaryCreditCardID
					WHERE tcc.CreditCardIssueNumber = @creditCardIssueNumber
					AND tcc.CreditCardNumber = @creditCardNumber
					AND tccd.TransactionSequence = @transactionSequence
					))
					
		BEGIN
		SET @tempLookUpID = (SELECT tcc.ID FROM TemporaryCreditCard tcc
							   WHERE tcc.CreditCardIssueNumber = @creditCardIssueNumber
							   AND tcc.CreditCardNumber = @creditCardNumber)
							   
		INSERT INTO TemporaryCreditCardDetail(  TemporaryCreditCardID,
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
		SELECT @tempLookUpID, 
			   HISTORY_ID_TransactionSequence,
			   CREATE_DATE_IssueDate_TransactionDate,
			   ACTION_TYPE_TransactionType,
			   USER_NAME_IssueBy_TransactionBy,
			   REQUESTED_AMOUNT_RequestedAmount,
			   APPROVED_AMOUNT_ApprovedAmount,
			   AVAILABLE_BALANCE_AvailableBalance,
			   ChargeDate,
			   ChargeAmount,
			   ChargeDescription,
			   CreateDate,
			   CreateBy,
			   ModifyDate,
			   ModifyBy
		FROM TemporaryCreditCard_Import WHERE RecordID = @startROWParent
		
		SET @newRecordID = SCOPE_IDENTITY()
		UPDATE TemporaryCreditCard_Import SET TemporaryCreditCardDetailsID = @newRecordID
		WHERE RecordID = @startROWParent  
		
		END
		END
		
		SET @startROWParent = @startROWParent + 1
	END
	
	-- Step 3 Update Counts
	SET @TotalRecordCount = (SELECT COUNT(*) FROM TemporaryCreditCard_Import WHERE 
							 ProcessIdentifier = @processGUID)
	
	SET @TotalRecordsIgnored = (SELECT COUNT(*) FROM TemporaryCreditCard_Import
							   WHERE TemporaryCreditCardDetailsID IS NULL AND ProcessIdentifier = @processGUID
							   AND TemporaryCreditCardID IS NULL
							   ) 
							  
	
	SET @TotalCreditCardAdded = (SELECT COUNT(*) FROM TemporaryCreditCard_Import
							     WHERE TemporaryCreditCardID IS NOT NULL AND ProcessIdentifier = @processGUID)
							     
	SET @TotalTransactionAdded = (SELECT COUNT(*) FROM TemporaryCreditCard_Import
							     WHERE TemporaryCreditCardDetailsID IS NOT NULL AND ProcessIdentifier = @processGUID)
							   
	
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
	   



