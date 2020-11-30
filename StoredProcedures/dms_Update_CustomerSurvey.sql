/****** Object:  StoredProcedure [dbo].[dms_Update_CustomerSurvey]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Update_CustomerSurvey]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Update_CustomerSurvey] 
 END 
 GO  
/**
EXEC dms_Update_CustomerSurvey 28, 'ignored',NULL, 'phani test', NULL
EXEC dms_Update_CustomerSurvey 30, 'Compliment',NULL, 'phani test', NULL
EXEC dms_Update_CustomerSurvey 32, 'ComplaintNonDamage',NULL, 'phani test', NULL


--select * from batchetlserver.pinnacle_reporting.dbo.CustomerSurvey
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_Update_CustomerSurvey]
			(
				@surveyId INT = NULL,
				@userAction NVARCHAR(100) = NULL,
				@sessionId NVARCHAR(MAX) = NULL,
				@loggedInUser NVARCHAR(MAX) = NULL,
				@eventSouce NVARCHAR(MAX) = NULL
			)
AS
BEGIN
	--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT OFF
	SET XACT_ABORT ON   

	IF @userAction = 'ignored'
	BEGIN
		--UPDATE	[Dart].[Pinnacle_Reporting].Dbo.customersurvey
		UPDATE	SurveyResponse
				--vw_CustomerSurvey 
				--batchetlserver.pinnacle_reporting.dbo.CustomerSurvey 
				--[Dart].[Pinnacle_Reporting].Dbo.customersurvey
		SET		DecidedBy = @loggedInUser,
				DecidedDate = GETDATE(),
				CustomerFeedbackID = NULL,
				IsIgnore = 1
		WHERE ID = @surveyId
	END
	ELSE
	BEGIN

		DECLARE @pendingCustomerFeedbackStatusID INT = (SELECT ID FROM CustomerFeedbackStatus WITH (NOLOCK) where Name = 'Pending'),
				@surveyCustomerFeedbackSourceID INT = (SELECT ID FROM CustomerFeedbackSource WITH (NOLOCK) where Name = 'Survey'),
				@insertCustomerFeedbackEventID INT = (SELECT ID FROM [Event] WITH (NOLOCK) where Name ='InsertCustomerFeedback'),
				@customerFeedbackEntityID INT = (SELECT ID FROM Entity WITH (NOLOCK) where Name = 'CustomerFeedback')
		DECLARE	@surveyCustomerFeedbackSourcePriorityID INT = (SELECT CustomerFeedbackPriorityID from CustomerFeedbackSourcePriority WITH (NOLOCK) where CustomerFeedbackSourceID =  @surveyCustomerFeedbackSourceID)
		DECLARE @customerFeedbackTypeID INT = (SELECT ID FROM CustomerFeedbackType WITH (NOLOCK) where Name = @userAction)
		DECLARE @memberEntityID INT = (SELECT ID FROM Entity WITH (NOLOCK) WHERE Name = 'Member')
		DECLARE @homeAddressTypeID INT = (SELECT ID FROM AddressType WITH (NOLOCK) WHERE Name = 'Home')
		DECLARE @homePhoneTypeID INT = (SELECT ID FROM PhoneType WITH (NOLOCK) WHERE Name = 'Home')


		DECLARE @serviceRequestId INT = NULL
		DECLARE @purchaseOrderNumber NVARCHAR(100) = NULL
		DECLARE @memberId INT = NULL
		DECLARE @memberAddressCountryCode NVARCHAR(100) = NULL

		--SR: Getting Service Request AND Country Code By and Purchase Order Number
		IF EXISTS(SELECT * FROM vw_CustomerSurvey CS WITH (NOLOCK) WHERE CS.ID = @surveyId AND ServiceRequestID IS NULL)
		BEGIN
			IF EXISTS(SELECT * FROM vw_CustomerSurvey CS WITH (NOLOCK) WHERE CS.ID = @surveyId AND PurchaseOrderNumber IS NOT NULL)
			BEGIN
				SELECT @purchaseOrderNumber = PurchaseOrderNumber FROM vw_CustomerSurvey CS WHERE CS.ID = @surveyId
				SELECT	@serviceRequestId = PO.ServiceRequestID 
				FROM	PurchaseOrder PO WITH (NOLOCK)
				WHERE	PO.PurchaseOrderNumber = @purchaseOrderNumber
			END
			ELSE
			BEGIN
				SET @purchaseOrderNumber = NULL
				SET @serviceRequestId = NULL
			END
		END
		ELSE
		BEGIN
			SELECT  @serviceRequestId = ServiceRequestID FROM vw_CustomerSurvey CS WITH (NOLOCK) WHERE CS.ID = @surveyId
		END
		
		;WITH wMemberDetails
		AS
		(
			SELECT TOP	1
					AE.Line1,
					AE.Line2,
					AE.Line3,
					AE.StateProvince,
					AE.StateProvinceID,
					AE.CountryCode,
					AE.CountryID,
					AE.City,
					AE.PostalCode,
					PE.PhoneNumber,
					M.FirstName,
					M.LastName,
					MS.MembershipNumber,
					C.ContactEmail AS Email,
					C.ContactFirstName,
					C.ContactLastName
			FROM	ServiceRequest SR WITH (NOLOCK)
			JOIN	[Case] C WITH (NOLOCK) ON SR.CaseId = C.ID
			JOIN	[Member] M WITH (NOLOCK) ON C.MemberID = M.ID
			JOIN	[Membership] MS WITH (NOLOCK) ON M.MembershipID = MS.ID
			LEFT JOIN	AddressEntity AE WITH (NOLOCK) ON AE.EntityID = @memberEntityID AND AE.RecordID = M.ID AND AE.AddressTypeID = @homeAddressTypeID
			LEFT JOIN	PhoneEntity PE WITH (NOLOCK) ON PE.EntityID = @memberEntityID AND PE.RecordID = M.ID AND PE.PhoneTypeID = @homePhoneTypeID
			WHERE	SR.ID = @serviceRequestID
				
		)

		INSERT INTO CustomerFeedback(
			ServiceRequestID
			, AssignedToUserID
			, CustomerFeedbackStatusID
			, CustomerFeedbackPriorityID
			, CustomerFeedbackSourceID
			, [Description]
			, ReceiveDate
			, MemberFirstName
			, MemberLastName
			, CreateDate
			, CreateBy
			, MemberAddressLine1
			, MemberAddressLine2
			, MemberAddressLine3
			, MemberAddressCity
			, MemberAddressStateProvince
			, MemberAddressStateProvinceID
			, MemberAddressPostalCode
			, MemberAddressCountryCode
			, MemberAddressCountryID
			, MemberPhoneNumber
			, MemberEmail
			, PurchaseOrderNumber
			, MembershipNumber
		)
		SELECT	
			@serviceRequestId, -- ServiceRequestID
			NULL, -- AssignedToUserID
			@pendingCustomerFeedbackStatusID, -- CustomerFeedbackStatusID
			@surveyCustomerFeedbackSourcePriorityID, -- CustomerFeedbackPriorityID
			@surveyCustomerFeedbackSourceID, -- CustomerFeedbackSourceID
			CS.AdditionalComments,-- [Description]
			GETDATE(),-- ReceiveDate
			M.ContactFirstName,-- MemberFirstName
			M.ContactLastName,-- MemberLastName
			GETDATE(),-- CreateDate
			@loggedInUser,-- CreateBy			
			M.Line1,-- MemberAddressLine1
			M.Line2,-- MemberAddressLine2
			M.Line3,-- MemberAddressLine3
			M.City,-- MemberAddressCity
			M.StateProvince,-- MemberAddressStateProvince
			M.StateProvinceID,-- MemberAddressStateProvinceID
			M.PostalCode,-- MemberAddressPostalCode
			M.CountryCode,-- MemberAddressCountryCode
			M.CountryID,-- MemberAddressCountryID
			M.PhoneNumber,-- MemberPhoneNumber
			M.Email,
			@purchaseOrderNumber,-- PurchaseOrderNumber
			M.MembershipNumber-- MembershipNumber
		FROM vw_CustomerSurvey CS, 
			--batchetlserver.pinnacle_reporting.dbo.CustomerSurvey CS 
			--[Dart].[Pinnacle_Reporting].Dbo.customersurvey CS
		wMemberDetails M

		WHERE CS.ID = @surveyId

		DECLARE @newlyCreatedCustomerFeedbackID INT = SCOPE_IDENTITY()

		INSERT INTO CustomerFeedbackDetail(
			CustomerFeedbackID,
			CustomerFeedbackTypeID,
			CreateDate,
			CreateBy
		)
		SELECT	@newlyCreatedCustomerFeedbackID,
				@customerFeedbackTypeID,
				GETDATE(),
				@loggedInUser

		INSERT INTO EventLog(
			EventID,
			SessionID,
			[Source],
			[Description],
			[Data],
			[CreateDate],
			[CreateBy]
		)
		SELECT	@insertCustomerFeedbackEventID,
				@sessionId,
				@eventSouce,
				'Insert Customer Feedback from Survey',
				NULL,
				GETDATE(),
				@loggedInUser
		DECLARE @eventLogId INT = SCOPE_IDENTITY()
		
		INSERT INTO EventLogLink(
			EventLogID,
			RecordID,
			EntityID
		)
		SELECT	@eventLogId,
				@newlyCreatedCustomerFeedbackID,
				@customerFeedbackEntityID

		--UPDATE	[Dart].[Pinnacle_Reporting].Dbo.customersurvey
		UPDATE SurveyResponse
				--vw_CustomerSurvey 
				--batchetlserver.pinnacle_reporting.dbo.CustomerSurvey 
				--[Dart].[Pinnacle_Reporting].Dbo.customersurvey
		SET		DecidedBy = @loggedInUser,
				DecidedDate = GETDATE(),
				CustomerFeedbackID = @newlyCreatedCustomerFeedbackID,
				IsIgnore = NULL
		WHERE ID = @surveyId
	END

END
GO
