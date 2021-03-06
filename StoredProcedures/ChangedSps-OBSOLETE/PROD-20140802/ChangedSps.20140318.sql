IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_billing_invoices_tag]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_billing_invoices_tag] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_billing_invoices_tag] @invoicesOrClaimsXML = '<Invoices><ID>41</ID></Invoices>',@batchID = 999, @currentUser='kbanda'
 CREATE PROCEDURE [dbo].[dms_billing_invoices_tag](
	@invoicesXML XML,
	@billedBatchID BIGINT,
	@unBilledBatchID BIGINT,
	@currentUser NVARCHAR(50),
	@eventSource NVARCHAR(MAX),
	@eventName NVARCHAR(100) = 'PostInvoice',
	@eventDetails NVARCHAR(MAX),
	@entityName NVARCHAR(50) = 'BillingInvoice',
	@sessionID NVARCHAR(MAX) = NULL	
 )
 AS
 BEGIN
 
	DECLARE @now DATETIME = GETDATE()
	
	DECLARE @tblBillingInvoices TABLE
	(	
		ID INT IDENTITY(1,1),
		RecordID INT
	)
	
	INSERT INTO @tblBillingInvoices
	SELECT BI.ID
	FROM	BillingInvoice BI
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @invoicesXML.nodes('/Invoices/ID') T(c)
			) T ON BI.ID = T.ID
			
	DECLARE	@BillingInvoiceDetailStatus_POSTED as int,
			@BillingInvoiceDetailStatus_EXCLUDED as INT,
			@BillingInvoiceLineStatus_POSTED as int,
			@BillingInvoiceStatus_POSTED as int,
			@BillingInvoiceDisposition_LOCKED as int,
			@BillingInvoiceStatus_DELETED as int,
			
			@serviceRequestEntityID INT,
			@purchaseOrderEntityID INT,
			@claimEntityID INT,
			@vendorInvoiceEntityID INT,
			@billingInvoiceEntityID INT,
			@postInvoiceEventID INT	
	
	SELECT @BillingInvoiceDetailStatus_POSTED = (SELECT ID from BillingInvoiceDetailStatus where Name = 'POSTED')
	SELECT @BillingInvoiceLineStatus_POSTED = (SELECT ID from BillingInvoiceLineStatus where Name = 'POSTED')
	SELECT @BillingInvoiceStatus_POSTED = (SELECT ID from BillingInvoiceStatus where Name = 'POSTED')
	SELECT @BillingInvoiceDisposition_LOCKED = (SELECT ID from BillingInvoiceDetailDisposition where Name = 'LOCKED')
	SELECT @BillingInvoiceStatus_DELETED = (SELECT ID from BillingInvoiceStatus where Name = 'DELETED')

	SELECT @BillingInvoiceDetailStatus_EXCLUDED = (SELECT ID from BillingInvoiceDetailStatus where Name = 'EXCLUDED')
 
 
	SELECT @serviceRequestEntityID = ID FROM Entity WHERE Name = 'ServiceRequest'
	SELECT @purchaseOrderEntityID = ID FROM Entity WHERE Name = 'PurchaseOrder'
	SELECT @claimEntityID = ID FROM Entity WHERE Name = 'Claim'
	SELECT @vendorInvoiceEntityID = ID FROM Entity WHERE Name = 'VendorInvoice'
	SELECT @billingInvoiceEntityID = ID FROM Entity WHERE Name = 'BillingInvoice'
	
	SELECT @postInvoiceEventID = ID FROM [Event] WHERE Name = 'PostInvoice'
	
	DECLARE @index INT = 1, @maxRows INT = 0, @billingInvoiceID INT = 0
	
	SELECT @maxRows = MAX(ID) FROM @tblBillingInvoices
	
	--DEBUG: SELECT @index,@maxRows
	
	WHILE (@index <= @maxRows AND @maxRows > 0)
	BEGIN
		
		
		
		SELECT @billingInvoiceID = RecordID FROM @tblBillingInvoices WHERE ID = @index
		
		--DEBUG: SELECT 'Updating statuses' As StatusMessage,@billingInvoiceID AS InvoiceID
		
		-- Update Billing Invoice.
		UPDATE	BillingInvoice 
		SET		InvoiceStatusID = @BillingInvoiceStatus_POSTED,
				AccountingInvoiceBatchID = @billedBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		WHERE	ID = @billingInvoiceID		
		
		-- Update Billing InvoiceLines
		UPDATE	BillingInvoiceLine
		SET		InvoiceLineStatusID = @BillingInvoiceLineStatus_POSTED,
				ModifyBy = @currentUser,
				ModifyDate = @now
		WHERE	BillingInvoiceID = @billingInvoiceID
		
		-- Update BillingInvoiceDetail and related entities.
		UPDATE	BillingInvoiceDetail
		SET		AccountingInvoiceBatchID = CASE WHEN ISNULL(BID.IsExcluded,0) = 1
												THEN @unBilledBatchID
												ELSE @billedBatchID
											END,
				InvoiceDetailDispositionID = @BillingInvoiceDisposition_LOCKED,
				--TFS: 203 --InvoiceDetailStatusID = @BillingInvoiceDetailStatus_POSTED,
				InvoiceDetailStatusID = CASE WHEN ISNULL(BID.IsExcluded, 0) = 1
                                                            THEN @BillingInvoiceDetailStatus_EXCLUDED
                                                            ELSE @BillingInvoiceDetailStatus_POSTED
                                                END, 
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	BillingInvoiceDetail BID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID AND BID.InvoiceDetailStatusID <> @BillingInvoiceStatus_DELETED
		
		
		-- SRs
		UPDATE	ServiceRequest
		SET		AccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	ServiceRequest SR
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @serviceRequestEntityID AND BID.EntityKey = SR.ID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
				
		-- POs
		UPDATE	PurchaseOrder
		SET		AccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	PurchaseOrder PO
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @purchaseOrderEntityID AND BID.EntityKey = PO.ID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
		
		-- Claims PassThru
		UPDATE	Claim
		SET		PassthruAccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	Claim C
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @claimEntityID AND BID.EntityKey = C.ID
		JOIN	BillingDefinitionInvoiceLine BDIL ON BID.BillingDefinitionInvoiceLineID = BDIL.ID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
		AND		BDIL.Rate IS NULL
		
		-- Claims Fee
		UPDATE	Claim
		SET		FeeAccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	Claim C
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @claimEntityID AND BID.EntityKey = C.ID
		JOIN	BillingDefinitionInvoiceLine BDIL ON BID.BillingDefinitionInvoiceLineID = BDIL.ID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
		AND		BDIL.Rate IS NOT NULL
		
		-- VendorInvoice
		UPDATE	VendorInvoice
		SET		AccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	VendorInvoice VI
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @vendorInvoiceEntityID AND BID.EntityKey = VI.ID		
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
		
		
		INSERT INTO EventLog
		SELECT	@postInvoiceEventID,
				@sessionID,
				@eventSource,
				@eventDetails,
				NULL,
				NULL,
				GETDATE(),
				@currentUser
				
		INSERT INTO EventLogLink
		SELECT	SCOPE_IDENTITY(),
				@billingInvoiceEntityID,
				@billingInvoiceID			
	
		SET @index = @index + 1
		
		
	END
 
 
 END

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ManualNotification_Event_Log]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ManualNotification_Event_Log] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_ManualNotification_Event_Log] 'SSMS','SSMS','Manual notification','kbanda',1,'AE05306D-492D-4944-B8BA-8E90BE11F393,BEB5FA18-50CE-499D-BB62-FFB9585242AB'
CREATE PROCEDURE [dbo].[dms_ManualNotification_Event_Log](
	@eventSource NVARCHAR(255) = NULL,
	@sessionID NVARCHAR(255) = NULL,
	@message NVARCHAR(MAX) = NULL,
	@createBy NVARCHAR(50) = NULL,
	@recipientTypeID INT = NULL,
	@autoCloseDelay INT = 0,
	@toUserOrRoleIDs NVARCHAR(MAX) = NULL -- CSV of ASPNET_UserIds / RoleIds
)
AS
BEGIN
 
	DECLARE @tmpUsers TABLE
	(
		ID INT IDENTITY(1,1),
		UserID INT NULL,
		aspnet_UserID UNIQUEIDENTIFIER NULL
	)

	DECLARE @eventLogID INT,
			@idx INT = 1,
			@maxRows INT = 0,
			@userEntityID INT

	SET @userEntityID = (SELECT ID FROM Entity WHERE Name = 'User')

	SET @message =	REPLACE( REPLACE( REPLACE(REPLACE(@message,'&','&amp;'),'<','&lt;'), '>','&gt;'),'''','&quot;')

	IF ( @recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'User') )
	BEGIN
		
		INSERT INTO @tmpUsers (UserID, aspnet_UserID)
		SELECT	DISTINCT U.ID,
				AU.UserId
		FROM	[dbo].[fnSplitString](@toUserOrRoleIDs,',') T
		JOIN	aspnet_Users AU WITH (NOLOCK) ON T.item = AU.UserId
		JOIN	[User] U WITH (NOLOCK) ON  U.aspnet_UserID = AU.UserId
		

	END
	ELSE IF (@recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'Role'))
	BEGIN

		INSERT INTO @tmpUsers (UserID, aspnet_UserID)
		SELECT	DISTINCT U.ID,
				AU.UserId
		FROM	[dbo].[fnSplitString](@toUserOrRoleIDs,',') T
		JOIN	aspnet_UsersInRoles UIR WITH (NOLOCK) ON T.item = UIR.RoleId
		JOIN	aspnet_Users AU WITH (NOLOCK) ON UIR.UserId = AU.UserId
		JOIN	[User] U WITH (NOLOCK) ON  U.aspnet_UserID = AU.UserId

	END


	INSERT INTO EventLog (	EventID,
							SessionID,
							[Source],
							[Description],
							Data,
							NotificationQueueDate,
							CreateDate,
							CreateBy
						)
	SELECT	(SELECT ID FROM [Event] WHERE Name = 'ManualNotification'),
			@sessionID,
			@eventSource,
			(SELECT [Description] FROM [Event] WHERE Name = 'ManualNotification'),
			'<MessageData><SentFrom>' + @createBy + '</SentFrom><MessageText>' + @message + '</MessageText><AutoClose>' + CONVERT(NVARCHAR(100),@autoCloseDelay)  + '</AutoClose></MessageData>',
			NULL,
			GETDATE(),
			@createBy

	SET @eventLogID = SCOPE_IDENTITY()
	SELECT @maxRows = MAX(ID) FROM @tmpUsers

	-- Create EventLogLinks
	WHILE (@idx <= @maxRows)
	BEGIN

		INSERT INTO EventLogLink(	EntityID,
									EventLogID,
									RecordID
								)
		SELECT	@userEntityID,
				@eventLogID,
				T.UserID
		FROM	@tmpUsers T WHERE T.ID = @idx

		SET @idx = @idx + 1

	END

END

GO


GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Notification_History_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Notification_History_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Notification_History_Get] 'demouser'
CREATE PROCEDURE [dbo].[dms_Notification_History_Get](
@userName NVARCHAR(100)
)
AS
BEGIN

	SELECT	CL.*
	FROM	CommunicationLog CL WITH (NOLOCK)
	JOIN	ContactMethod CM WITH (NOLOCK) ON CL.ContactMethodID = CM.ID
	WHERE	CL.Email = @userName
	AND		CM.Name = 'DesktopNotification'
	AND		DATEDIFF(HH,CL.CreateDate,GETDATE()) <= 48
	AND		CL.Status = 'SUCCESS'
	ORDER BY CL.CreateDate DESC

END
GO
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveProgramPhoneSystemConfigurationInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveProgramPhoneSystemConfigurationInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveProgramPhoneSystemConfigurationInformation]( 
   @id INT = NULL
 , @ivrScriptID INT = NULL
 , @skillSetID INT = NULL
 , @phoneCompanyID INT = NULL
 , @inboundNumber NVARCHAR(100) = NULL
 , @pilotNumber NVARCHAR(100) = NULL
 , @isshownOnScreen BIT = NULL
 , @isActive BIT = NULL
 , @programID INT = NULL
 , @modifiedBy NVARCHAR(100) = NULL
 )
 AS
 BEGIN
 
 IF @id>0
	BEGIN
		UPDATE PhoneSystemConfiguration
		SET IVRScriptID = @ivrScriptID ,
			SkillsetID = @skillSetID ,
			InboundPhoneCompanyID = @phoneCompanyID ,
			InboundNumber = @inboundNumber ,
			PilotNumber = @pilotNumber ,
			IsShownOnScreen = @isshownOnScreen ,
			IsActive = @isActive ,
			ModifyBy = @modifiedBy ,
			ModifyDate = GETDATE()
		WHERE ID = @id
	END
ELSE
	BEGIN
		INSERT INTO PhoneSystemConfiguration(
			ProgramID,
			IVRScriptID,
			SkillsetID,
			InboundPhoneCompanyID,
			InboundNumber,
			PilotNumber,
			IsShownOnScreen,
			IsActive,
			CreateBy,
			CreateDate
		)
		VALUES(
			@programID,
			@ivrScriptID,
			@skillSetID,
			@phoneCompanyID,
			@inboundNumber,
			@pilotNumber,
			@isshownOnScreen,
			@isActive,
			@modifiedBy,
			GETDATE()
		)
	END
 
 END
GO
