IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_client_update_billinginvoicedetail_disposition]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_client_update_billinginvoicedetail_disposition] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_client_update_billinginvoicedetail_disposition] @billingeventdetailIdXML = '<BillingInvoiceDetail><ID>1</ID><ID>2</ID></BillingInvoiceDetail>',@currentUser = 'demouser',@statusId=1,@eventId=70234
 CREATE PROCEDURE [dbo].[dms_client_update_billinginvoicedetail_disposition](
	@billingeventdetailIdXML XML,
	@currentUser NVARCHAR(50),
	@statusId int,
	@eventId int
	
 )
 AS
 BEGIN
 
    SET FMTONLY OFF
	SET NOCOUNT ON
	
	DECLARE @now DATETIME = GETDATE()
	
	
	DECLARE @entityId INT
	SET @entityId = (SELECT ID FROM Entity WHERE Name='BillingInvoiceDetail')
	
	CREATE TABLE #SelectedBillingInvoiceDetail
	(	
		ID INT IDENTITY(1,1),
		BillingInvoiceDetailId INT
	)
	
	INSERT INTO #SelectedBillingInvoiceDetail
	SELECT tcc.ID
	FROM BillingInvoiceDetail tcc WITH (NOLOCK)
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @billingeventdetailIdXML.nodes('/BillingInvoiceDetail/ID') T(c)
			) T ON tcc.ID = T.ID

	CREATE CLUSTERED INDEX IDX_SelectedBillingInvoiceDetail ON #SelectedBillingInvoiceDetail(BillingInvoiceDetailId)
	
	--Insert log records
	INSERT INTO EventLogLink
	SELECT @eventId,
	       @entityId,
	       BillingInvoiceDetailId
	FROM #SelectedBillingInvoiceDetail
	
	--Update BillingInvoiceDetail
	UPDATE BillingInvoiceDetail
	SET InvoiceDetailDispositionID = @statusId,
	    ModifyBy = @currentUser,
	    ModifyDate = @now
	WHERE ID IN(SELECT BillingInvoiceDetailId FROM #SelectedBillingInvoiceDetail)
	
	DROP TABLE #SelectedBillingInvoiceDetail
	
 END