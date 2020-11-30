IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_CCImport_UpdateTempCreditCardDetails]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_CCImport_UpdateTempCreditCardDetails]
GO

--EXEC dms_CCImport_UpdateTempCreditCardDetails
--EXEC dms_CCImport_UpdateTempCreditCardDetails
CREATE PROC [dbo].[dms_CCImport_UpdateTempCreditCardDetails]
AS
BEGIN

BEGIN TRY
 

CREATE TABLE #TempCardsNotPosted (     
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
 ID int  NULL)

DECLARE @postedStatus INT
DECLARE @startROWParent INT 
DECLARE @totalRowsParent INT,
		@creditcardNumber INT,
		@totalApprovedAmount money,
		@totalChargedAmount money,
		@maxLastChargeDate datetime

SET @postedStatus = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name='Posted')

INSERT INTO #TempCardsNotPosted
SELECT DISTINCT TCCD.TemporaryCreditCardID FROM
TemporaryCreditCardDetail TCCD
JOIN TemporaryCreditCard TCC ON TCC.ID = TCCD.TemporaryCreditCardID
WHERE TCC.TemporaryCreditCardStatusID NOT IN (SELECT ID FROM TemporaryCreditCardStatus WHERE Name IN ('Cancelled','Posted'))
--AND TCC.IssueDate > DATEADD(mm, -180, GETDATE())

SET @startROWParent =  (SELECT MIN([RowNum]) FROM #TempCardsNotPosted)
SET @totalRowsParent = (SELECT MAX([RowNum]) FROM #TempCardsNotPosted)

WHILE(@startROWParent <= @totalRowsParent)  
BEGIN

SET @creditcardNumber = (SELECT ID FROM #TempCardsNotPosted WHERE [RowNum] = @startROWParent)
SET @maxLastChargeDate = (SELECT MAX(ChargeDate) FROM TemporaryCreditCardDetail WHERE TemporaryCreditCardID =  @creditcardNumber)

UPDATE TemporaryCreditCard
SET LastChargedDate = @maxLastChargeDate
WHERE ID =  @creditcardNumber

IF((SELECT Count(*) FROM TemporaryCreditCardDetail 
   WHERE TransactionType='Cancel' AND TemporaryCreditCardID = @creditcardNumber) > 0)
 BEGIN
	UPDATE TemporaryCreditCard 
	SET IssueStatus = 'Cancel'
	WHERE ID = @creditcardNumber
 END
 
 SET @totalApprovedAmount = (SELECT TOP 1 ApprovedAmount FROM TemporaryCreditCardDetail
							 WHERE TemporaryCreditCardID = @creditcardNumber AND TransactionType='Approve'
							 AND TransactionSequence IS NOT NULL
							 ORDER BY TransactionSequence DESC)
SET @totalChargedAmount = (SELECT SUM(ChargeAmount) FROM TemporaryCreditCardDetail
						   WHERE TemporaryCreditCardID = @creditcardNumber AND TransactionType='Charge')

UPDATE TemporaryCreditCard
SET ApprovedAmount = @totalApprovedAmount,
	TotalChargedAmount = @totalChargedAmount
WHERE ID = @creditcardNumber
						 
SET @startROWParent = @startROWParent + 1

END

DROP TABLE #TempCardsNotPosted



END TRY
BEGIN CATCH
		
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
	
END CATCH

END
GO

