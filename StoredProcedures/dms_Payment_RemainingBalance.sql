IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Payment_RemainingBalance]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Payment_RemainingBalance] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

CREATE PROC dms_Payment_RemainingBalance(@paymentID INT = NULL)
AS
BEGIN

DECLARE @RemainingBalance TABLE(RemainingBalance money,CCOrderID NVARCHAR(100),ResponseTdate NVARCHAR(100))
DECLARE @SRID INT
DECLARE @CCOrderID NVARCHAR(100)
DECLARE @ResponseTdate NVARCHAR(100)
DECLARE @AmountAlreadyCredited money
DECLARE @OriginalTransactionAmount money

SELECT @SRID = ServiceRequestID FROM Payment WHERE ID = @paymentID
SELECT @CCOrderID = CCOrderID FROM Payment WHERE ID = @paymentID
SELECT @ResponseTdate = ResponseTdate FROM PaymentTransaction WHERE PaymentID = @paymentID

SELECT @OriginalTransactionAmount = 
									Amount from PaymentTransaction 
									where ServiceRequestID = @SRID 
									AND CCOrderID = @CCOrderID
									AND PaymentStatusID =(Select ID FROM PaymentStatus WHERE Name ='Approved')
						            AND PaymentTransactionTypeID in(SELECT ID FROM PaymentTransactionType WHERE Name ='Sale')

select @AmountAlreadyCredited =	SUM(Amount)from PaymentTransaction 
								where ServiceRequestID = @SRID 
								AND CCOrderID =@CCOrderID
								AND PaymentStatusID =(Select ID FROM PaymentStatus WHERE Name ='Approved')
								AND PaymentTransactionTypeID in(SELECT ID FROM PaymentTransactionType WHERE Name in('Credit','Void'))

INSERT INTO @RemainingBalance VALUES(ISNULL(@OriginalTransactionAmount -ISNULL(@AmountAlreadyCredited, 0),0),@CCOrderID,@ResponseTdate)

SELECT * FROM @RemainingBalance

END
