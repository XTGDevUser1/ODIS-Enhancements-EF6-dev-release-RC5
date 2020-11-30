IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_CustomerFeedbackDetail]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_CustomerFeedbackDetail] 
 END 
 GO  
CREATE VIEW [dbo].[vw_CustomerFeedbackDetail] AS
SELECT CFD.ID CustomerFeedbackDetailID
	,CF.ID CustomerFeedbackID
	,CFD.CustomerFeedbackTypeID CustomerFeedbackDetailTypeID
	,CFT.[Description] CustomerFeedbackDetailTypeDescription
	,CFD.CustomerFeedbackCategoryID CustomerFeedbackDetailCategoryID
	,CFC.[Description] CustomerFeedbackDetailCategoryDescription
	,CFD.CustomerFeedbackSubCategoryID CustomerFeedbackDetailSubCategoryID
	,CFSC.[Description] CustomerFeedbackDetailSubCategoryDescription
	,CFD.ResolutionDescription CustomerFeedbackDetailResolutionDescription
	,CFD.UserID CustomerFeedbackDetailUserID
	,U.FirstName + ' ' + U.LastName CustomerFeedbackDetailUser
	,CFD.IsInvalid CustomerFeedbackDetailIsInvalid
	,CFD.CustomerFeedbackInvalidReasonID CustomerFeedbackDetailInvalidReasonID
	,CFIR.[Description] CustomerFeedbackDetailInvalidReasonDescription
FROM CustomerFeedbackDetail CFD (NOLOCK)
	LEFT JOIN CustomerFeedback CF (NOLOCK) ON CF.ID = CFD.CustomerFeedbackID
	LEFT JOIN CustomerFeedbackType CFT (NOLOCK) ON CFT.ID = CFD.CustomerFeedbackTypeID
	LEFT JOIN CustomerFeedbackCategory CFC (NOLOCK) ON CFC.ID = CFD.CustomerFeedbackCategoryID
	LEFT JOIN CustomerFeedbackSubCategory CFSC (NOLOCK) ON CFSC.ID = CFD.CustomerFeedbackSubCategoryID
	LEFT JOIN [User] U (NOLOCK) ON U.ID = CFD.UserID
	LEFT JOIN CustomerFeedbackInvalidReason CFIR (NOLOCK) ON CFIR.ID = CFD.CustomerFeedbackInvalidReasonID
GO

