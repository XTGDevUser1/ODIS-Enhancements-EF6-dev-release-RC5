IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_QuestionAnswer_ServiceRequest')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_QuestionAnswer_ServiceRequest] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

CREATE PROC [dbo].[dms_QuestionAnswer_ServiceRequest](@serviceRequest INT  = NULL)
AS
BEGIN
	SELECT	PCQ.QuestionText,
			SRD.Answer,
			CASE WHEN (ISNULL(sr.IsPossibleTow,0) = 0 AND sr.productcategoryid = pc.id) OR (ISNULL(sr.IsPossibleTow,0) = 1 AND sr.productcategoryid = pc.id)
				THEN 'Primary'
				WHEN ISNULL(sr.IsPossibleTow,0) = 1 AND sr.productcategoryid <> pc.id
				THEN
				'Secondary'
			END As Flag
	FROM	servicerequestdetail SRD
	JOIN	servicerequest SR ON SR.ID = SRD.serviceRequestID
	JOIN	ProductCategoryquestion PCQ ON SRD.ProductCategoryQuestionID = PCQ.ID
	JOIN	ProductCategory PC ON PCQ.ProductCategoryID = PC.ID
	WHERE	SRD.servicerequestid = @serviceRequest
	ORDER BY PCQ.ProductCategoryID DESC
END



										
GO
