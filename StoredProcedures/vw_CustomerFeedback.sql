IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_CustomerFeedback]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_CustomerFeedback] 
 END 
 GO  
CREATE VIEW [dbo].[vw_CustomerFeedback] 
AS

SELECT CF.ID CustomerFeedbackID
	,CF.ServiceRequestID ServiceRequestID
	,U.FirstName + ' ' + U.LastName CustomerFeedbackAssignedToUser
	,CFS.Description CustomerFeedbackStatus
	,CFP.Description CustomerFeedbackPriority
	,CFSR.Description CustomerFeedbackSource
	,NA.Description CustomerFeedbackNextAction
	,U2.FirstName + ' ' + U2.LastName CustomerFeedbackNextActionAssignedToUser
	,CF.NextActionScheduleDate CustomerFeedbackNextActionScheduleDate
	,CF.Description CustomerFeedbackDescription
	,CF.ReceiveDate CustomerFeedbackReceiveDate
	,CF.MemberFirstName CustomerFeedbackMemberFirstName
	,CF.MemberLastName CustomerFeedbackMemberLastName
	,CF.CallRecordingNumber CustomerFeedbackCallRecordingNumber 
	,CF.CreateDate CustomerFeedbackCreateDate
	,CF.CreateBy CustomerFeedbackCreateBy
	,CF.ModifyDate CustomerFeedbackModifyDate
	,CF.ModifyBy CustomerFeedbackModifyBy
	,CF.MemberAddressLine1 CustomerFeedbackMemberAddressLine1
	,CF.MemberAddressLine2 CustomerFeedbackMemberAddressLine2
	,CF.MemberAddressLine3 CustomerFeedbackMemberAddressLine3
	,CF.MemberAddressCity CustomerFeedbackMemberAddressCity
	,CF.MemberAddressStateProvince CustomerFeedbackMemberAddressStateProvince
	,CF.MemberAddressPostalCode CustomerFeedbackMemberAddressPostalCode
	,CF.MemberAddressCountryCode CustomerFeedbackMemberAddressCountryCode
	,CF.MemberPhoneNumber CustomerFeedbackMemberPhoneNumber
	,CF.MemberEmail CustomerFeedbackMemberEmail
	,CF.MembershipNumber CustomerFeedbackMembershipNumber
	,CF.PurchaseOrderNumber CustomerFeedbackPurchaseOrderNumber
	,CF.DueDate CustomerFeedbackDueDate
	,U3.FirstName + ' ' + U3.LastName CustomerFeedbackWorkedByUser
	,CF.StartDate CustomerFeedbackStartDate
	,CF.ResearchComplete CustomerFeedbackResearchCompleteDate
	,CF.ClosedDate CustomerFeedbackClosedDate
	,CFD.CustomerFeedbackDetailID
	,CFD.CustomerFeedbackDetailTypeID
	,CFD.CustomerFeedbackDetailTypeDescription
	,CFD.CustomerFeedbackDetailCategoryID
	,CFD.CustomerFeedbackDetailCategoryDescription
	,CFD.CustomerFeedbackDetailSubCategoryID
	,CFD.CustomerFeedbackDetailSubCategoryDescription
	,CFD.CustomerFeedbackDetailResolutionDescription
	,CFD.CustomerFeedbackDetailUserID
	,CFD.CustomerFeedbackDetailUser
	,CFD.CustomerFeedbackDetailIsInvalid
	,CFD.CustomerFeedbackDetailInvalidReasonID
	,CFD.CustomerFeedbackDetailInvalidReasonDescription
FROM CustomerFeedback CF (NOLOCK)
	JOIN vw_CustomerFeedbackDetail CFD (NOLOCK) ON CFD.CustomerFeedbackID = CF.ID
	JOIN (
		SELECT CustomerFeedBackID, MIN(ID) ID
		FROM CustomerFeedbackDetail (NOLOCK)
		GROUP BY CustomerFeedbackID
		) First_CFD ON First_CFD.ID = CFD.CustomerFeedbackDetailID
	LEFT JOIN [User] U (NOLOCK) ON U.ID = CF.AssignedToUserID
	LEFT JOIN CustomerFeedbackStatus CFS  (NOLOCK) ON CFS.ID = CF.CustomerFeedbackStatusID
	LEFT JOIN CustomerFeedbackPriority CFP (NOLOCK) ON CFP.ID = CF.CustomerFeedbackPriorityID
	LEFT JOIN CustomerFeedbackSource CFSR (NOLOCK) ON CFSR.ID = CF.CustomerFeedbackSourceID
	LEFT JOIN NextAction NA (NOLOCK) ON NA.ID = CF.NextActionID
	LEFT JOIN [User] U2 (NOLOCK) ON U2.ID = CF.NextActionAssignedToUserID
	LEFT JOIN [User] U3 (NOLOCK) ON U3.ID = CF.WorkedByUserID
GO

