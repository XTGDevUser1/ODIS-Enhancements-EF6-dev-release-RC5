 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_SR_Has_AccountingInvoiceBatchID_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_SR_Has_AccountingInvoiceBatchID_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- [dms_SR_Has_AccountingInvoiceBatchID_Get] 1544
 CREATE PROCEDURE [dbo].[dms_SR_Has_AccountingInvoiceBatchID_Get]( 
   @serviceRequestId Int = 1   
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
DECLARE @hasAccountingInvoiceBatchID as BIT = 0

IF( (SELECT ISNULL(AccountingInvoiceBatchID,0) from ServiceRequest WITH (NOLOCK) where ID=@serviceRequestId) <> 0)
BEGIN
	SET @hasAccountingInvoiceBatchID = 1
END

IF (@hasAccountingInvoiceBatchID = 0)
BEGIN
	IF((SELECT MAX(ISNULL(PO.AccountingInvoiceBatchID,0)) FROM PurchaseOrder  PO WITH (NOLOCK)  where PO.ServiceRequestID = @serviceRequestId) <> 0)
	BEGIN
		SET @hasAccountingInvoiceBatchID = 1
	END
END

SELECT @hasAccountingInvoiceBatchID AS SRHasAccountingInvoiceBatchID
END