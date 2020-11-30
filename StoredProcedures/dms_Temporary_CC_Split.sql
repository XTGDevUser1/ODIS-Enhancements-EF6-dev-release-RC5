IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Temporary_CC_Split]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Temporary_CC_Split]
GO

-- Select * from TemporaryCreditCard where OriginalReferencePurchaseOrderNumber = '7959125'
-- EXEC [dms_Temporary_CC_Split] 22626, '7959245'
CREATE PROCEDURE [dbo].[dms_Temporary_CC_Split] 
	@SourceTemporaryCreditCardID int,
	@SplitTo_PurchaseOrderNumber nvarchar(50)
AS
BEGIN
	
	DECLARE	@NewTemporaryCreditCardID int,
		@NewTemporaryCreditCard_TotalChargedAmount money
		
	SELECT @NewTemporaryCreditCard_TotalChargedAmount = PurchaseOrderAmount
	FROM PurchaseOrder
	WHERE PurchaseOrderNumber = @SplitTo_PurchaseOrderNumber

	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO [DMS].[dbo].[TemporaryCreditCard]
				   ([CreditCardIssueNumber]
				   ,[CreditCardNumber]
				   ,[PurchaseOrderID]
				   ,[VendorInvoiceID]
				   ,[IssueDate]
				   ,[IssueBy]
				   ,[IssueStatus]
				   ,[ReferencePurchaseOrderNumber]
				   ,[OriginalReferencePurchaseOrderNumber]
				   ,[ReferenceVendorNumber]
				   ,[ApprovedAmount]
				   ,[TotalChargedAmount]
				   ,[TemporaryCreditCardStatusID]
				   ,[ExceptionMessage]
				   ,[Note]
				   ,[PostingBatchID]
				   ,[AccountingPeriodID]
				   ,[CreateDate]
				   ,[CreateBy]
				   ,[ModifyDate]
				   ,[ModifyBy])
		SELECT [CreditCardIssueNumber]
			  ,[CreditCardNumber]
			  ,[PurchaseOrderID]
			  ,[VendorInvoiceID]
			  ,[IssueDate]
			  ,[IssueBy]
			  ,[IssueStatus]
			  ,@SplitTo_PurchaseOrderNumber
			  ,[OriginalReferencePurchaseOrderNumber]
			  ,[ReferenceVendorNumber]
			  ,[ApprovedAmount]
			  ,@NewTemporaryCreditCard_TotalChargedAmount
			  ,[TemporaryCreditCardStatusID]
			  ,[ExceptionMessage]
			  ,[Note]
			  ,[PostingBatchID]
			  ,[AccountingPeriodID]
			  ,[CreateDate]
			  ,[CreateBy]
			  ,[ModifyDate]
			  ,[ModifyBy]
		FROM [DMS].[dbo].[TemporaryCreditCard]
		WHERE ID = @SourceTemporaryCreditCardID

		SET @NewTemporaryCreditCardID = SCOPE_IDENTITY()

		INSERT INTO [DMS].[dbo].[TemporaryCreditCardDetail]
				   ([TemporaryCreditCardID]
				   ,[TransactionSequence]
				   ,[TransactionDate]
				   ,[TransactionType]
				   ,[TransactionBy]
				   ,[RequestedAmount]
				   ,[ApprovedAmount]
				   ,[AvailableBalance]
				   ,[ChargeDate]
				   ,[ChargeAmount]
				   ,[ChargeDescription]
				   ,[CreateDate]
				   ,[CreateBy]
				   ,[ModifyDate]
				   ,[ModifyBy])
		SELECT @NewTemporaryCreditCardID
			  ,[TransactionSequence]
			  ,[TransactionDate]
			  ,[TransactionType]
			  ,[TransactionBy]
			  ,[RequestedAmount]
			  ,[ApprovedAmount]
			  ,[AvailableBalance]
			  ,[ChargeDate]
			  ,CASE WHEN TransactionType = 'Charge' Then @NewTemporaryCreditCard_TotalChargedAmount Else [ChargeAmount] End
			  ,[ChargeDescription]
			  ,[CreateDate]
			  ,[CreateBy]
			  ,[ModifyDate]
			  ,[ModifyBy]
		FROM [DMS].[dbo].[TemporaryCreditCardDetail]
		WHERE TemporaryCreditCardID = @SourceTemporaryCreditCardID

		UPDATE TemporaryCreditCard SET TotalChargedAmount = (TotalChargedAmount - @NewTemporaryCreditCard_TotalChargedAmount)
		WHERE ID = @SourceTemporaryCreditCardID
		
		Update tcd Set ChargeAmount = tcc.TotalChargedAmount
		From TemporaryCreditCard tcc
		Join TemporaryCreditCardDetail tcd on tcd.TemporaryCreditCardID = tcc.ID and tcd.TransactionType = 'Charge'
		Where tcc.ID = @SourceTemporaryCreditCardID
		
		UPDATE PurchaseOrder Set IsPayByCompanyCreditCard = 1, 
			CompanyCreditCardNumber = 
				(SELECT CompanyCreditCardNumber From PurchaseOrder 
				 WHERE PurchaseOrderNumber = 
					(Select ReferencePurchaseOrderNumber FROM TemporaryCreditCard WHERE ID = @SourceTemporaryCreditCardID)
				) 
		WHERE PurchaseOrderNumber = @SplitTo_PurchaseOrderNumber
		
		COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
	END CATCH
	
END
GO

