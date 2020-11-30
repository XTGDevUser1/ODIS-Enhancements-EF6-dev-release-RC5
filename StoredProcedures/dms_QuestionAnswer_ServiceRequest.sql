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
-- EXEC [dbo].[dms_QuestionAnswer_ServiceRequest] 1597,'Dispatch'
CREATE PROC [dbo].[dms_QuestionAnswer_ServiceRequest](@serviceRequest INT  = NULL, @sourceSystemName NVARCHAR(50) = 'Dispatch')
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
	JOIN	[dbo].ProductCategoryQuestionSourceSystem PCQS WITH (NOLOCK) ON PCQ.ID = PCQS.ProductCategoryQuestionID
	JOIN	[dbo].[SourceSystem] SS WITH (NOLOCK) ON SS.ID = PCQS.SourceSystemID
	WHERE	SRD.servicerequestid = @serviceRequest
	AND		SS.Name = @sourceSystemName
	ORDER BY PCQ.ProductCategoryID DESC
END



										