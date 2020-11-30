IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Member_Payment_Balance]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_Payment_Balance] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_Member_Payment_Balance] 2
 CREATE PROCEDURE [dbo].[dms_Member_Payment_Balance]( 
  @serviceRequestID  INT = NULL
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
 	Select sum(
	CASE WHEN pt.Name = 'Credit'
	THEN -1 * p.Amount
	ELSE p.Amount
	END
	) AS Amount
From Payment p
Join ServiceRequest sr on sr.ID = p.ServiceRequestID
Join PaymentTransactionType pt on pt.ID = p.PaymentTransactionTypeID
Where
	sr.ID = @serviceRequestID
	 END 
