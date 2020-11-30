/****** Object:  StoredProcedure [dbo].[dms_Process_Vendor_Insurance_Expiration]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Process_Vendor_Insurance_Expiration]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Process_Vendor_Insurance_Expiration] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC [dms_Process_Vendor_Insurance_Expiration]
 CREATE PROCEDURE [dbo].[dms_Process_Vendor_Insurance_Expiration]
 AS 
 BEGIN 
 
    DECLARE @VendorsInsuranceExpired AS TABLE( 
	ID int NOT NULL IDENTITY(1,1),
	VendorID INT NOT NULL)
	
    DECLARE @VendorsInsuranceExpiring AS TABLE( 
	ID int NOT NULL IDENTITY(1,1),
	VendorID INT NOT NULL)
	

	INSERT INTO @VendorsInsuranceExpired
	SELECT	ID 
	FROM	Vendor WITH (NOLOCK) 
	WHERE	InsuranceExpirationDate IS NOT NULL 
	AND		DATEDIFF(DD,InsuranceExpirationDate,GETDATE()) = 1
	AND		ISNULL(IsActive,0) = 1
	

	--INSERT INTO @VendorsInsuranceExpiring
	--SELECT	ID 
	--FROM	Vendor WITH (NOLOCK)  
	--WHERE	InsuranceExpirationDate IS NOT NULL 
	--AND		DATEDIFF (hh, GETDATE(),InsuranceExpirationDate) BETWEEN 0 AND 72
	--AND		ISNULL(IsActive,0) = 1
	
	--SELECT * FROM @VendorsInsuranceExpired
	--SELECT * FROM @VendorsInsuranceExpiring
	
	
	DECLARE  @counter AS INT
	DECLARE  @maxItem AS INT
	DECLARE @vendorID AS INT
	
	SET @counter = 1

	SET @maxItem = (SELECT MAX(ID) FROM @VendorsInsuranceExpired)
	

		DECLARE @insuranceExpireDate DATETIME =NULL
		DECLARE @vendorName NVARCHAR(100) = NULL
		DECLARE @vendorNumber NVARCHAR(100) = NULL
		DECLARE @vendorEmail NVARCHAR(100) = NULL
		DECLARE @contactFirstName NVARCHAR(100) =NULL
		DECLARE @contactLastName NVARCHAR(100) = NULL
		DECLARE @regionName NVARCHAR(100) = NULL
		DECLARE @Email NVARCHAR(100) =NULL
		DECLARE @PhoneNumber NVARCHAR(100) =NULL
		DECLARE @vendorfax NVARCHAR(100) = NULL
		DECLARE @vendorRegionID INT = NULL
		DECLARE @vendorEntityID INT = NULL
		DECLARE @vendorRegionEntityID INT = NULL
		DECLARE @officePhoneTypeID INT = NULL
		DECLARE @faxPhoneTypeID INT = NULL
		
		DECLARE @officePhone NVARCHAR(100) = NULL
		DECLARE @faxPhone NVARCHAR(100) = NULL

		DECLARE @vendorServicesPhoneNumber NVARCHAR(100) = NULL,
				@vendorServicesFaxNumber NVARCHAR(100) = NULL,
				@contactLogID INT = NULL,
				@contactCategoryID INT = NULL,
				@contactTypeID INT = NULL,
				@emailContactMethodID INT = NULL,
				@faxContactMethodID INT = NULL,
				@contactSourceID INT = NULL,
				@contactReasonID INT = NULL,
				@contactActionID INT = NULL,
				@vendorInsuranceExpired_EmailTemplateID INT = NULL,
				@vendorInsuranceExpired_FaxTemplateID INT = NULL,
				@vendorInsuranceExpiring_EmailTemplateID INT = NULL,
				@vendorInsuranceExpiring_FaxTemplateID INT = NULL,
				@eventLogID BIGINT = NULL

		SET @contactCategoryID = (SELECT ID FROM ContactCategory WITH (NOLOCK) WHERE Name = 'ContactVendor')
		SET @contactTypeID = (SELECT ID FROM ContactType WITH (NOLOCK) WHERE Name = 'system')
		SET @contactCategoryID = (SELECT ID FROM ContactCategory WITH (NOLOCK) WHERE Name = 'ContactVendor')
		SET @emailContactMethodID = (SELECT ID FROM ContactMethod WITH (NOLOCK) WHERE Name = 'Email')
		SET @faxContactMethodID = (SELECT ID FROM ContactMethod WITH (NOLOCK) WHERE Name = 'Fax')
		SET @contactSourceID = (SELECT ID FROM ContactSource WITH (NOLOCK) WHERE Name = 'VendorData' AND ContactCategoryID = @contactCategoryID)
		SET @contactReasonID = (SELECT ID FROM ContactReason WITH (NOLOCK) WHERE Name = 'VendorInsurance' AND ContactCategoryID = @contactCategoryID)
		SET @contactActionID = (SELECT ID FROM ContactAction WITH (NOLOCK) WHERE Name = 'SendInsuranceExpirationNotice' AND ContactCategoryID = @contactCategoryID)

		SET @vendorInsuranceExpired_EmailTemplateID = (SELECT ID FROM Template WITH (NOLOCK) WHERE Name = 'Vendor_InsuranceExpiredEmail')
		SET @vendorInsuranceExpired_FaxTemplateID = (SELECT ID FROM Template WITH (NOLOCK) WHERE Name = 'Vendor_InsuranceExpiredFax')
		SET @vendorInsuranceExpiring_EmailTemplateID = (SELECT ID FROM Template WITH (NOLOCK) WHERE Name = 'Vendor_InsuranceExpiringEmail')
		SET @vendorInsuranceExpiring_FaxTemplateID = (SELECT ID FROM Template WITH (NOLOCK) WHERE Name = 'Vendor_InsuranceExpiringFax')
		
	
		SET	@vendorServicesPhoneNumber	= (SELECT Value FROM ApplicationConfiguration WHERE Name = 'VendorServicesPhoneNumber')
		SET	@vendorServicesFaxNumber	= (SELECT Value FROM ApplicationConfiguration WHERE Name = 'VendorServicesFaxNumber')
		SET @vendorEntityID = (SELECT ID FROM Entity where Name='Vendor')
		SELECT @faxPhoneTypeID = ID FROM PhoneType WHERE Name = 'Fax'
		
		DECLARE @messageData NVARCHAR(MAX) = NULL

	WHILE @counter <= @maxItem
	BEGIN

		-- Reset variables
		SET @insuranceExpireDate =NULL
		SET @vendorName  = NULL
		SET @vendorNumber  = NULL
		SET @vendorEmail = NULL
		SET @contactFirstName  =NULL
		SET @contactLastName  = NULL
		SET @regionName = NULL
		SET @Email =NULL
		SET @PhoneNumber =NULL
		SET @vendorRegionID = NULL
		SET @vendorRegionEntityID = NULL		
		
		SET @officePhone = NULL
		SET @faxPhone = NULL
		SET @vendorfax = NULL
		SET @contactLogID = NULL
		SET @eventLogID = NULL


		SET @vendorID = (SELECT VendorID FROM @VendorsInsuranceExpired WHERE ID = @counter)		

		PRINT '1: Processing InsuranceExpired for vendor - ' + CONVERT(NVARCHAR(100),@vendorID)

		SET @counter =  @counter + 1
		
		--SELECT  
		--		@vendorNumber = V.VendorNumber, 
		--		@insuranceExpireDate = V.InsuranceExpirationDate,
		--		@vendorName =  V.Name, 	
		--		@vendorEmail = LTRIM(RTRIM(COALESCE(V.Email,''))),			
		--		@regionName = VR.Name,
		--		@contactFirstName = VR.ContactFirstName, 
		--		@contactLastName =  VR.ContactLastName, 
		--		@Email = VR.Email, 				
		--		@PhoneNumber = dbo.fnc_FormatPhoneNumber(VR.PhoneNumber, 0) , 
		--		@officePhone = dbo.fnc_FormatPhoneNumber(@vendorServicesPhoneNumber, 0) , 
		--		@faxPhone = dbo.fnc_FormatPhoneNumber(@vendorServicesFaxNumber,0)			
		--FROM    Vendor AS V WITH (NOLOCK)
		--LEFT OUTER JOIN	VendorRegion AS VR WITH (NOLOCK) ON V.VendorRegionID = VR.ID
		--WHERE     (V.ID = @vendorID)
		
		SELECT  
				@vendorNumber = V.VendorNumber, 
				@insuranceExpireDate = V.InsuranceExpirationDate,
				@vendorName =  V.Name, 	
				@vendorEmail = LTRIM(RTRIM(COALESCE(V.Email,''))),			
				@regionName = '',				--VR.Name,
				@contactFirstName = 'Larry',	--VR.ContactFirstName, 
				@contactLastName =  'Turner',	--VR.ContactLastName, 
				@Email = 'insurance@nmc.com',	--VR.Email, 				
				@PhoneNumber = '469-524-5313',	--dbo.fnc_FormatPhoneNumber(VR.PhoneNumber, 0) , 
				@officePhone = '800-285-4977',	--dbo.fnc_FormatPhoneNumber(@vendorServicesPhoneNumber, 0) , 
				@faxPhone = '800-331-1145'		--dbo.fnc_FormatPhoneNumber(@vendorServicesFaxNumber,0)			
		FROM    Vendor AS V WITH (NOLOCK)
		LEFT OUTER JOIN	VendorRegion AS VR WITH (NOLOCK) ON V.VendorRegionID = VR.ID
		WHERE     (V.ID = @vendorID)
		
		SELECT @vendorfax = RS.PhoneNumber
		FROM
		(
		SELECT TOP 1 PhoneNumber
		FROM	Vendor V WITH (NOLOCK)
		LEFT JOIN PhoneEntity PE WITH (NOLOCK) ON PE.RecordID = V.ID AND PE.EntityID = @vendorEntityID AND PE.PhoneTypeID = @faxPhoneTypeID
		WHERE	V.ID = @vendorID
		) RS 
		
		--DEBUG: SELECT @vendorfax, @vendorID

		SET @messageData =  '<MessageData>'
		SET @messageData = @messageData + '<VendorName>'+ [dbo].[fnXMLEncode](ISNULL(@vendorName,''))+'</VendorName>'
		SET @messageData = @messageData + '<InsuranceExpireDate>'+ CONVERT(NVARCHAR(10),@insuranceExpireDate,101)+'</InsuranceExpireDate>'
		SET @messageData = @messageData + '<VendorNumber>'+ISNULL(@vendorNumber,'')+'</VendorNumber>'
		SET @messageData = @messageData + '<ContactFirstName>'+ [dbo].[fnXMLEncode](ISNULL(@contactFirstName,''))+'</ContactFirstName>'
		SET @messageData = @messageData + '<ContactLastName>'+ [dbo].[fnXMLEncode](ISNULL(@contactLastName,''))+'</ContactLastName>'
		SET @messageData = @messageData + '<RegionName>'+ [dbo].[fnXMLEncode](ISNULL(@regionName,''))+'</RegionName>'
		SET @messageData = @messageData + '<Email>'+ISNULL(@Email,'')+'</Email>'
		SET @messageData = @messageData + '<PhoneNumber>'+ISNULL(@PhoneNumber,'')+'</PhoneNumber>'
		SET @messageData = @messageData + '<Office>'+ISNULL(@officePhone,'')+'</Office>'
		SET @messageData = @messageData + '<fax>'+ISNULL(@faxPhone,'')+'</fax>'
		SET @messageData = @messageData + '<date>'+CONVERT(NVARCHAR(10),GETDATE(),101)+'</date>'
		SET @messageData = @messageData + '<vendorfax>' + ISNULL(dbo.fnc_FormatPhoneNumber(@vendorfax,0),'') + '</vendorfax>'
		SET @messageData = @messageData + '<vendorphone>' + 'TBD' + '</vendorphone>'
		SET @messageData =  @messageData + '</MessageData>'
		
		PRINT '1: ' + @messageData 
		
		-- 1. Create EventLog saying that an attempt was made to notify the vendor
		INSERT INTO EventLog (EventID,
						[Description],
						[Data],
						NotificationQueueDate,
						[Source],
						CreateDate,
						CreateBy)
			VALUES(
			(SELECT ID FROM [Event] WHERE Name='InsuranceExpired'),
			(SELECT [Description] FROM [Event] WHERE Name='InsuranceExpired'),
			@messageData,
			GETDATE(),
			'Vendor Insurance Expiry - Batch job',
			GETDATE(),
			'system'
			)
		SET @eventLogID = SCOPE_IDENTITY()
		INSERT INTO EventLogLink(EventLogID,EntityID,RecordID)
		VALUES(
			@eventLogID,
			@vendorEntityID,
			@vendorID
		)

		-- Check to see if a contactlog record was created in the past 12 hrs and skip the following statements if one exists.
		IF ( (SELECT [dbo].[fnCheckVendorInsuranceExpiryContactLog](@vendorID)) = 1)
		BEGIN
			-- 2. Create ContactLog
			INSERT INTO ContactLog (
									ContactCategoryID
									,ContactTypeID
									,ContactMethodID
									,ContactSourceID
									,Company									
									,PhoneTypeID
									,PhoneNumber
									,Email
									,Direction
									,Description																		
									,CreateDate
									,CreateBy									
									)
			SELECT	@contactCategoryID,
					@contactTypeID,
					CASE WHEN @vendorEmail = '' THEN @emailContactMethodID ELSE @faxContactMethodID END,
					@contactSourceID,
					@vendorName,
					CASE WHEN @vendorEmail = '' THEN @faxPhoneTypeID ELSE NULL END,
					CASE WHEN @vendorEmail = '' THEN @vendorfax ELSE NULL END,
					CASE WHEN @vendorEmail = '' THEN NULL ELSE @vendorEmail END,
					'Outbound',
					'Insurance Expiration Notice',
					GETDATE(),
					'system'

			SET @contactLogID = SCOPE_IDENTITY()

			--2.1 ContactLogLink
			INSERT INTO ContactLogLink (
											ContactLogID,
											EntityID,
											RecordID
										)

			SELECT	@contactLogID,
					@vendorEntityID,
					@vendorID
			--2.2 ContactLogAction

			INSERT INTO ContactLogAction (
											ContactLogID,
											ContactActionID,
											CreateBy,
											CreateDate									
											)
			SELECT	@contactLogID,
					@contactActionID,
					'system',
					GETDATE()

			--2.3 ContactLogReason

			INSERT INTO ContactLogReason (
											ContactLogID,
											ContactReasonID,
											CreateBy,
											CreateDate
											)
			SELECT	@contactLogID,
					@contactReasonID,
					'system',
					GETDATE()
			
			-- 3. Create CommunicationQueue record
			INSERT INTO CommunicationQueue (
											ContactLogID
											,ContactMethodID
											,TemplateID
											,MessageData
											,Subject
											,MessageText
											,Attempts
											,ScheduledDate
											,CreateDate
											,CreateBy
											,NotificationRecipient
											,EventLogID
											)
			SELECT	@contactLogID,
					CASE WHEN @vendorEmail <> '' THEN @emailContactMethodID ELSE @faxContactMethodID END,
					CASE WHEN @vendorEmail <> '' THEN @vendorInsuranceExpired_EmailTemplateID ELSE @vendorInsuranceExpired_FaxTemplateID END,
					@messageData,
					NULL,
					NULL,
					NULL,
					NULL,
					GETDATE(),
					'system',
					CASE WHEN @vendorEmail <> '' THEN @vendorEmail ELSE @vendorfax END,
					@eventLogID
		END

	END
	
	SET @counter = 1
	SET @maxItem = (SELECT MAX(ID) FROM @VendorsInsuranceExpiring)
	
	WHILE @counter <= @maxItem
	BEGIN

		-- Reset variables
		SET @insuranceExpireDate =NULL
		SET @vendorName  = NULL
		SET @vendorNumber  = NULL
		SET @vendorEmail = NULL
		SET @contactFirstName  =NULL
		SET @contactLastName  = NULL
		SET @regionName = NULL
		SET @Email =NULL
		SET @PhoneNumber =NULL
		SET @vendorRegionID = NULL
		SET @vendorRegionEntityID = NULL		
		
		SET @officePhone = NULL
		SET @faxPhone = NULL
		SET @vendorfax = NULL
		SET @contactLogID = NULL
		SET @eventLogID = NULL


		SET @vendorID = (SELECT VendorID FROM @VendorsInsuranceExpiring WHERE ID = @counter)		

		PRINT '1: Processing InsuranceExpiring for vendor - ' + CONVERT(NVARCHAR(100),@vendorID)

		SET @counter =  @counter + 1
		
		--SELECT  
		--		@vendorNumber = V.VendorNumber, 
		--		@insuranceExpireDate = V.InsuranceExpirationDate,
		--		@vendorName =  V.Name, 	
		--		@vendorEmail = LTRIM(RTRIM(COALESCE(V.Email,''))),			
		--		@regionName = VR.Name,
		--		@contactFirstName = VR.ContactFirstName, 
		--		@contactLastName =  VR.ContactLastName, 
		--		@Email = VR.Email, 				
		--		@PhoneNumber = dbo.fnc_FormatPhoneNumber(VR.PhoneNumber, 0) , 
		--		@officePhone = dbo.fnc_FormatPhoneNumber(@vendorServicesPhoneNumber, 0) , 
		--		@faxPhone = dbo.fnc_FormatPhoneNumber(@vendorServicesFaxNumber,0)			
		--FROM    Vendor AS V WITH (NOLOCK)
		--LEFT OUTER JOIN	VendorRegion AS VR WITH (NOLOCK) ON V.VendorRegionID = VR.ID
		--WHERE     (V.ID = @vendorID)
		
				SELECT  
				@vendorNumber = V.VendorNumber, 
				@insuranceExpireDate = V.InsuranceExpirationDate,
				@vendorName =  V.Name, 	
				@vendorEmail = LTRIM(RTRIM(COALESCE(V.Email,''))),			
				@regionName = '',				--VR.Name,
				@contactFirstName = 'Larry',	--VR.ContactFirstName, 
				@contactLastName =  'Turner',	--VR.ContactLastName, 
				@Email = 'insurance@nmc.com',	--VR.Email, 				
				@PhoneNumber = '469-524-5313',	--dbo.fnc_FormatPhoneNumber(VR.PhoneNumber, 0) , 
				@officePhone = '800-285-4977',	--dbo.fnc_FormatPhoneNumber(@vendorServicesPhoneNumber, 0) , 
				@faxPhone = '800-331-1145'		--dbo.fnc_FormatPhoneNumber(@vendorServicesFaxNumber,0)			
		FROM    Vendor AS V WITH (NOLOCK)
		LEFT OUTER JOIN	VendorRegion AS VR WITH (NOLOCK) ON V.VendorRegionID = VR.ID
		WHERE     (V.ID = @vendorID)
			
		
		SELECT @vendorfax = RS.PhoneNumber
		FROM
		(
		SELECT TOP 1 PhoneNumber
		FROM	Vendor V WITH (NOLOCK)
		LEFT JOIN PhoneEntity PE WITH (NOLOCK) ON PE.RecordID = V.ID AND PE.EntityID = @vendorEntityID AND PE.PhoneTypeID = @faxPhoneTypeID
		WHERE	V.ID = @vendorID
		) RS 
		
		--DEBUG: SELECT @vendorfax, @vendorID

		SET @messageData =  '<MessageData>'
		SET @messageData = @messageData + '<VendorName>'+[dbo].[fnXMLEncode](ISNULL(@vendorName,''))+'</VendorName>'
		SET @messageData = @messageData + '<InsuranceExpireDate>'+ CONVERT(NVARCHAR(10),@insuranceExpireDate,101)+'</InsuranceExpireDate>'
		SET @messageData = @messageData + '<VendorNumber>'+ISNULL(@vendorNumber,'')+'</VendorNumber>'
		SET @messageData = @messageData + '<ContactFirstName>'+[dbo].[fnXMLEncode](ISNULL(@contactFirstName,''))+'</ContactFirstName>'
		SET @messageData = @messageData + '<ContactLastName>'+[dbo].[fnXMLEncode](ISNULL(@contactLastName,''))+'</ContactLastName>'
		SET @messageData = @messageData + '<RegionName>'+ [dbo].[fnXMLEncode](ISNULL(@regionName,''))+'</RegionName>'
		SET @messageData = @messageData + '<Email>'+ISNULL(@Email,'')+'</Email>'
		SET @messageData = @messageData + '<PhoneNumber>'+ISNULL(@PhoneNumber,'')+'</PhoneNumber>'
		SET @messageData = @messageData + '<Office>'+ISNULL(@officePhone,'')+'</Office>'
		SET @messageData = @messageData + '<fax>'+ISNULL(@faxPhone,'')+'</fax>'
		SET @messageData = @messageData + '<date>'+CONVERT(NVARCHAR(10),GETDATE(),101)+'</date>'
		SET @messageData = @messageData + '<vendorfax>' + ISNULL(dbo.fnc_FormatPhoneNumber(@vendorfax,0),'') + '</vendorfax>'
		SET @messageData = @messageData + '<vendorphone>' + 'TBD' + '</vendorphone>'
		SET @messageData =  @messageData + '</MessageData>'
		
		PRINT '2: ' + @messageData 
		
		-- 1. Create EventLog saying that an attempt was made to notify the vendor
		INSERT INTO EventLog (EventID,
						[Description],
						[Data],
						NotificationQueueDate,
						[Source],
						CreateDate,
						CreateBy)
			VALUES(
			(SELECT ID FROM [Event] WHERE Name='InsuranceExpiring'),
			(SELECT [Description] FROM [Event] WHERE Name='InsuranceExpiring'),
			@messageData,
			GETDATE(),
			'Vendor Insurance Expiry - Batch job',
			GETDATE(),
			'system'
			)
		SET @eventLogID = SCOPE_IDENTITY()
		INSERT INTO EventLogLink(EventLogID,EntityID,RecordID)
		VALUES(
			@eventLogID,
			@vendorEntityID,
			@vendorID
		)

		-- Check to see if a contactlog record was created in the past 12 hrs and skip the following statements if one exists.
		IF ( (SELECT [dbo].[fnCheckVendorInsuranceExpiryContactLog](@vendorID)) = 1)
		BEGIN
			-- 2. Create ContactLog
			INSERT INTO ContactLog (
									ContactCategoryID
									,ContactTypeID
									,ContactMethodID
									,ContactSourceID
									,Company									
									,PhoneTypeID
									,PhoneNumber
									,Email
									,Direction
									,Description																		
									,CreateDate
									,CreateBy									
									)
			SELECT	@contactCategoryID,
					@contactTypeID,
					CASE WHEN @vendorEmail = '' THEN @emailContactMethodID ELSE @faxContactMethodID END,
					@contactSourceID,
					@vendorName,
					CASE WHEN @vendorEmail = '' THEN @faxPhoneTypeID ELSE NULL END,
					CASE WHEN @vendorEmail = '' THEN @vendorfax ELSE NULL END,
					CASE WHEN @vendorEmail = '' THEN NULL ELSE @vendorEmail END,
					'Outbound',
					'Insurance Expiration Notice',
					GETDATE(),
					'system'

			SET @contactLogID = SCOPE_IDENTITY()

			--2.1 ContactLogLink
			INSERT INTO ContactLogLink (
											ContactLogID,
											EntityID,
											RecordID
										)

			SELECT	@contactLogID,
					@vendorEntityID,
					@vendorID
			--2.2 ContactLogAction

			INSERT INTO ContactLogAction (
											ContactLogID,
											ContactActionID,
											CreateBy,
											CreateDate									
											)
			SELECT	@contactLogID,
					@contactActionID,
					'system',
					GETDATE()

			--2.3 ContactLogReason

			INSERT INTO ContactLogReason (
											ContactLogID,
											ContactReasonID,
											CreateBy,
											CreateDate
											)
			SELECT	@contactLogID,
					@contactReasonID,
					'system',
					GETDATE()
			
			-- 3. Create CommunicationQueue record
			INSERT INTO CommunicationQueue (
											ContactLogID
											,ContactMethodID
											,TemplateID
											,MessageData
											,Subject
											,MessageText
											,Attempts
											,ScheduledDate
											,CreateDate
											,CreateBy
											,NotificationRecipient
											,EventLogID
											)
			SELECT	@contactLogID,
					CASE WHEN @vendorEmail <> '' THEN @emailContactMethodID ELSE @faxContactMethodID END,
					CASE WHEN @vendorEmail <> '' THEN @vendorInsuranceExpiring_EmailTemplateID ELSE @vendorInsuranceExpiring_FaxTemplateID END,
					@messageData,
					NULL,
					NULL,
					NULL,
					NULL,
					GETDATE(),
					'system',
					CASE WHEN @vendorEmail <> '' THEN @vendorEmail ELSE @vendorfax END,
					@eventLogID
		END

	END
	
	-- KB: Enable the following after addressing the postlogin prompt
		
	/* 
	UPDATE
		VendorUser
	SET
		PostLoginPromptID = (SELECT ID  FROM PostLoginPrompt where Name ='InsuranceExpiring')
	FROM
		@VendorsInsuranceExpired VIE 
	INNER JOIN
		VendorUser VU
	ON 
		VU.VendorID = VIE.VendorID
    
    
	UPDATE
		VendorUser
	SET
		PostLoginPromptID = (SELECT ID  FROM PostLoginPrompt where Name ='InsuranceExpiring')
	FROM
		VendorUser VU
	INNER JOIN
		@VendorsInsuranceExpiring VIE 
	ON 
		VU.VendorID = VIE.VendorID
	*/

END
