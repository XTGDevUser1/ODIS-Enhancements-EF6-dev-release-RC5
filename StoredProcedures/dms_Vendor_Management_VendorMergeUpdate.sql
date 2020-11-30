IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Management_VendorMergeUpdate]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Management_VendorMergeUpdate] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
 --EXEC   [dms_Vendor_Management_VendorMergeUpdate] 
 CREATE PROCEDURE [dbo].[dms_Vendor_Management_VendorMergeUpdate]
 (   
 @sourceVendorId int,
 @targetVendorId int,
 @sourceVendorLocationId int,
 @targetVendorLocationId int,
 @sessionId nvarchar(88),
 @userId nvarchar(50),
 @source nvarchar(255)
 )
 AS
 BEGIN
 
 BEGIN TRY
 
	 BEGIN TRAN
	 
	 SET NOCOUNT ON    
	 DECLARE @currentDate DATETIME
	 SET @currentDate = GETDATE()
	 DECLARE @eventLogDescription nvarchar(2000)
	 DECLARE @eventLogId int
	 DECLARE @maxCount int
	 DECLARE @counter int
	  
	 
	 
	 CREATE TABLE #LogResults(   
	 ID int NOT NULL IDENTITY(1,1),
	 Name nvarchar(200) NULL,
	 Value nvarchar(max) NULL)
	 
	 SET @eventLogDescription = '<EventDetail>'
	 SET @eventLogDescription = @eventLogDescription + '<SourceVendor>' + CAST(@sourceVendorId AS VARCHAR(10)) + '</SourceVendor>'
	 SET @eventLogDescription = @eventLogDescription + '<TargetVendor>' + CAST(@targetVendorId AS VARCHAR(10)) + '</TargetVendor>'
	 SET @eventLogDescription = @eventLogDescription + '<SourceVendorLocation>' + CAST(@sourceVendorLocationId AS VARCHAR(10)) + '</SourceVendorLocation>'
	 SET @eventLogDescription = @eventLogDescription + '<TargetVendorLocation>' + CAST(@targetVendorLocationId AS VARCHAR(10)) + '</TargetVendorLocation>'
	 
	 --Log PO
	 INSERT INTO #LogResults
	 SELECT 'PO',
	 '<SourcePO><' + CAST(ID AS VARCHAR(10)) + '></SourcePO><TargetPO><' + CAST(ID AS VARCHAR(10)) + '></TargetPO>'
	 FROM PurchaseOrder
	WHERE VendorLocationID = @sourceVendorLocationId

	 --Update PO
	 UPDATE PurchaseOrder
	 SET VendorLocationID = @targetVendorLocationId,
		 ModifyBy = @userId,
		 ModifyDate = @currentDate
	WHERE VendorLocationID = @sourceVendorLocationId
	 
	 --Update EventLogLink
	 UPDATE EventLogLink
	 SET RecordID = @targetVendorLocationId
	 WHERE RecordID = @sourceVendorLocationId AND EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
	 
	 --Update ContactLogLink
	 UPDATE ContactLogLink
	 SET RecordID = @targetVendorLocationId
	 WHERE RecordID = @sourceVendorLocationId AND EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
	 
	 --Log VendorInvoice
	 INSERT INTO #LogResults
	 SELECT 'VendorInvoice',
	 '<SourceInvoice><' + CAST(ID AS VARCHAR(10)) + '></SourceInvoice><TargetInvoice><' + CAST(ID AS VARCHAR(10)) + '></TargetInvoice>'
	 FROM VendorInvoice
	WHERE VendorID = @sourceVendorId

	--Update VendorInvoice
	UPDATE VendorInvoice
	SET VendorID = @targetVendorId,
		ModifyBy = @userId,
		ModifyDate = @currentDate
	WHERE VendorID = @sourceVendorId

	--Update EventLogLink
	 UPDATE EventLogLink
	 SET RecordID = @targetVendorId
	 WHERE RecordID = @sourceVendorId AND EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
	 
	 --Update ContactLogLink
	 UPDATE ContactLogLink
	 SET RecordID = @targetVendorId
	 WHERE RecordID = @sourceVendorId AND EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')

	--Delete source Vendor
	UPDATE VendorLocation
	SET IsActive = 0,
		ModifyBy = @userId,
		ModifyDate = @currentDate
	WHERE ID = @sourceVendorLocationId

	IF((SELECT Count(*) FROM VendorLocation WHERE VendorID = @sourceVendorId AND IsActive = 1 AND ID <> @sourceVendorLocationId) = 0)
	BEGIN

		UPDATE Vendor
		SET IsActive = 0,
			ModifyBy = @userId,
			ModifyDate = @currentDate
		WHERE ID = @sourceVendorId
		
	END

	--Updating Log for VendorInvoice and PO
	 SET @maxCount = (SELECT Count(*) FROM #LogResults)
	 SET @counter = 1
	 
	 WHILE(@counter <= @maxCount)
	 BEGIN
	 
	 SET @eventLogDescription = @eventLogDescription + (SELECT Value FROM #LogResults WHERE ID = @counter)
	 SET @counter = @counter + 1
	 
	 END	
	  
	 
	 SET @eventLogDescription = @eventLogDescription + '</EventDetail>'
	 
	 INSERT INTO EventLog(EventID,SessionID,[Source],[Description],CreateDate,CreateBy)
	 SELECT (SELECT ID FROM [Event] WHERE Name = 'MergeVendor') EventID,
			 @sessionId,
			 @source,
			 @eventLogDescription,
			 @currentDate,
			 @userId
	 
	 SET @eventLogId = SCOPE_IDENTITY()
						
	 INSERT INTO EventLogLink(EventLogID,EntityID,RecordID)
	 SELECT @eventLogId,
			(SELECT ID FROM Entity WHERE Name = 'Vendor'),
			@sourceVendorId
			
	 INSERT INTO EventLogLink(EventLogID,EntityID,RecordID)
	 SELECT @eventLogId,
			(SELECT ID FROM Entity WHERE Name = 'Vendor'),
			@targetVendorId
			
	DROP TABLE #LogResults
	
 COMMIT TRAN
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
	
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