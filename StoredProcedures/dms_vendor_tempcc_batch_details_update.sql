IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_tempcc_batch_details_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_tempcc_batch_details_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vendor_tempcc_batch_details_update] @invoicesXML = '<Tempcc><ID>1</ID><ID>2</ID><ID>3</ID><ID>4</ID></Tempcc>',@batchID = 999, @currentUser='kbanda'
 CREATE PROCEDURE [dbo].[dms_vendor_tempcc_batch_details_update](
	@invoicesXML XML,
	@batchID BIGINT,
	@currentUser NVARCHAR(50),
	@eventSource NVARCHAR(MAX),
	@eventName NVARCHAR(100) = 'PostTempCC',
	@eventDetails NVARCHAR(MAX),
	@entityName NVARCHAR(50) = 'VendorInvoice',
	@sessionID NVARCHAR(MAX) = NULL
 )
 AS
 BEGIN
 
	DECLARE @now DATETIME = GETDATE()
	
	DECLARE @invoicesFromDB TABLE
	(	
		ID INT IDENTITY(1,1),
		InvoiceID INT
	)
	
	INSERT INTO @invoicesFromDB
	SELECT VI.ID
	FROM	TemporaryCreditCard VI
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @invoicesXML.nodes('/Tempcc/ID') T(c)
			) T ON VI.ID = T.ID
	
	DECLARE @tempccEventID INT, 
			@vendorInvoiceEntityID INT,
			@totalAmount money,
			@batchStatusId INT
			
	SELECT @tempccEventID = ID FROM Event WHERE Name = @eventName
	SELECT @vendorInvoiceEntityID = ID FROM Entity WHERE Name = @entityName
	
	
	
	-- Event Logs.
	DECLARE @maxRows INT, @index INT = 1
	SELECT @maxRows = COUNT(*) FROM @invoicesFromDB
	
	WHILE ( @index <= @maxRows)
	BEGIN
		
		INSERT INTO EventLog
		SELECT	@tempccEventID,
				@sessionID,
				@eventSource,
				@eventDetails,
				NULL,
				NULL,
				GETDATE(),
				@currentUser
				
		INSERT INTO EventLogLink
		SELECT	SCOPE_IDENTITY(),
				@vendorInvoiceEntityID,
				(SELECT InvoiceID FROM @invoicesFromDB WHERE ID = @index)			
	
		SET @index = @index + 1
	END
    
    SELECT @batchStatusId = ID FROM BatchStatus WHERE Name = 'Success'
    
    SELECT	@totalAmount = SUM(ISNULL(C.TotalChargedAmount,0))
		FROM	TemporaryCreditCard C
		JOIN	@invoicesFromDB I ON C.ID = I.InvoiceID
		
    UPDATE	Batch
	SET	BatchStatusID = @batchStatusID,				
	ModifyBy = @currentUser,
	ModifyDate = @now,
	TotalCount = (SELECT Count(*) FROM @invoicesFromDB),
	TotalAmount = @totalAmount
	WHERE	ID = @batchID
	
    
    
	
	SELECT @totalAmount AS TotalAmount
	
 END