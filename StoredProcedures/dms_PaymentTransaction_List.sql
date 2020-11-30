IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_PaymentTransaction_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_PaymentTransaction_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

CREATE PROC dms_PaymentTransaction_List(@ServiceRequestID INT = NULL)
AS
BEGIN
SELECT
	ptx.ServiceRequestID
	, ptt.Description as TransType
	, pr.Description as Reason
	, ptx.Amount as Amount
	, pt.Description as Card
	, ptx.CCPartial as Number
	, ps.Description as Status
	, Case ps.Name WHEN 'Approved' THEN ptx.ResponseApproved 
				    WHEN 'Failed'   THEN ptx.ResponseError 
				    ELSE  COALESCE(ptx.CCAuthCode, ptx.ResponseError) 
	  END
	  AS AuthCodeError
	, ptx.CreateBy as [User]
	, ptx.CreateDate as [Date]
	, ptx.Comments as Comments
FROM PaymentTransaction ptx
JOIN PaymentTransactionType ptt on ptt.ID = ptx.PaymentTransactionTypeID
JOIN PaymentType pt ON pt.ID = ptx.PaymentTypeID
JOIN PaymentReason pr on pr.ID = ptx.PaymentReasonID
JOIN PaymentStatus ps on ps.ID = ptx.PaymentStatusID
WHERE
ptx.ServiceRequestID = @ServiceRequestID
ORDER BY ptx.CreateDate DESC
END