IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_questionanswer_values_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_questionanswer_values_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_questionanswer_values_get] 3,1,1,'Dispatch'
 
CREATE PROCEDURE [dbo].[dms_questionanswer_values_get]( 
   @ProgramID int,
   --@ProductCategoryID int,
   @VehicleTypeID int,
   @VehicleCategoryID int,
   @sourceSystemName NVARCHAR(100) = 'Dispatch'
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

DECLARE @Questions TABLE 
(
  ProductCategoryID int,
  ProductCategoryName NVARCHAR(MAX),
  ProductCategoryQuestionID int, 
  QuestionText nvarchar(4000),
  ControlType nvarchar(50),
  DataType nvarchar(50),
  HelpText nvarchar(4000),
  IsRequired bit,
  SubQuestionID int,
  RelatedAnswer nvarchar(255),
  Sequence int
)
DECLARE @relevantProductCategories TABLE
(
	ProductCategoryID INT,
	Sequence INT NULL
)
	INSERT INTO @relevantProductCategories
	SELECT DISTINCT ProductCategoryID,
			PC.Sequence 
	FROM	ProgramProductCategory PC
	JOIN	[dbo].[fnc_getprogramsandparents](@ProgramID) FNCP ON PC.ProgramID = FNCP.ProgramID
	AND		(VehicleTypeID = @VehicleTypeID OR VehicleTypeID IS NULL)
	-- KB: Do not consider @vehicleCategoryID here.By design, we load all the questions for a given vehicle type and show/hide questions relevant to vehiclecategory. Therefore, questions / product categories should not get filtered out here.
	--AND		(VehicleCategoryID = @vehicleCategoryID OR VehicleCategoryID IS NULL)
	WHERE	PC.IsActive = 1
	ORDER BY PC.Sequence 


-- Add questions related to Tow if they are not already in the list.
IF ( (SELECT COUNT(*) FROM @relevantProductCategories WHERE ProductCategoryID = 7) = 0)
BEGIN
	INSERT INTO @relevantProductCategories
	SELECT	PC.ID,
			PC.Sequence
	FROM ProductCategory PC WHERE Name like 'Tow%' AND PC.IsActive = 1
END

	INSERT INTO @Questions 
	SELECT DISTINCT 
			PCQ.ProductCategoryID,
			PC.Name,
			PCQ.ID, 
			PCQ.QuestionText,
			CT.Name as ControlType,
			DT.Name as DataType,
			PCQ.HelpText, 
			PCQ.IsRequired,  
			PCL.ProductCategoryQuestionID as SubQuestionID, 
			PVAL.Value as RelatedAnswer,
			PCQ.Sequence 
	FROM	[dbo].ProductCategoryQuestion PCQ WITH (NOLOCK)
	JOIN [dbo].ProductCategoryQuestionSourceSystem PCQS WITH (NOLOCK) ON PCQ.ID = PCQS.ProductCategoryQuestionID
	JOIN	[dbo].[SourceSystem] SS WITH (NOLOCK) ON SS.ID = PCQS.SourceSystemID
	JOIN	ProductCategoryQuestionVehicleType PCV WITH (NOLOCK) ON PCV.ProductCategoryQuestionID = PCQ.ID 
												AND (PCV.VehicleTypeID IS NULL OR PCV.VehicleTypeID = @VehicleTypeID) 
	-- KB: Do not consider @vehicleCategoryID here.By design, we load all the questions for a given vehicle type and show/hide questions relevant to vehiclecategory. Therefore, questions / product categories should not get filtered out here.
	--AND (PCV.VehicleCategoryID IS NULL OR PCV.VehicleCategoryID = @VehicleCategoryID)
												AND PCV.IsActive = 1   
	JOIN	ProductCategory PC WITH (NOLOCK) ON PCQ.ProductCategoryID = PC.ID
	LEFT JOIN ControlType CT WITH (NOLOCK) ON CT.ID = PCQ.ControlTypeID
	LEFT JOIN DataType DT WITH (NOLOCK) on DT.ID = PCQ.DataTypeID
	LEFT JOIN ProductCategoryQuestionLink PCL WITH (NOLOCK) on PCL.ParentProductCategoryQuestionID = PCV.ProductCategoryQuestionID
												AND PCL.IsActive = 1
	LEFT JOIN ProductCategoryQuestionValue PVAL WITH (NOLOCK) on PVAL.ID = PCL.ProductCategoryQuestionValueID
	AND		PVAL.IsActive = 1 
	WHERE	PCQ.ProductCategoryID IN (SELECT ProductCategoryID FROM @relevantProductCategories )
	AND		PCQ.IsActive = 1
	AND	SS.Name = @sourceSystemName

	UNION ALL
  
	SELECT	DISTINCT 
			PCQ.ProductCategoryID,
			PC.Name AS ProductCategoryName,
			PCQ.ID, 

			PCQ.QuestionText,
			CT.Name as ControlType,
			DT.Name as DataType,
			PCQ.HelpText, 
			PCQ.IsRequired,  
			PCL.ProductCategoryQuestionID as SubQuestionID, 
			PVAL.Value as RelatedAnswer,
			PCQ.Sequence 
	FROM	[dbo].ProductCategoryQuestion PCQ WITH (NOLOCK)
	JOIN	[dbo].ProductCategoryQuestionSourceSystem PCQS WITH (NOLOCK) ON PCQ.ID = PCQS.ProductCategoryQuestionID
	JOIN	[dbo].[SourceSystem] SS WITH (NOLOCK) ON SS.ID = PCQS.SourceSystemID
	JOIN	ProductCategoryQuestionProgram PCP WITH (NOLOCK) ON PCP.ProductCategoryQuestionID = PCQ.ID 
													AND (PCP.VehicleTypeID IS NULL OR PCP.VehicleTypeID = @VehicleTypeID )
	-- KB: Do not consider @vehicleCategoryID here.By design, we load all the questions for a given vehicle type and show/hide questions relevant to vehiclecategory. Therefore, questions / product categories should not get filtered out here.
	--AND (PCP.VehicleCategoryID IS NULL OR PCP.VehicleCategoryID = @VehicleCategoryID)
													AND PCP.IsActive = 1 
	JOIN	ProductCategory PC WITH (NOLOCK) ON PCQ.ProductCategoryID = PC.ID
	JOIN	fnc_GetProgramsandParents(@ProgramID) fncP on fncP.ProgramID = PCP.ProgramID 
	LEFT JOIN ControlType CT WITH (NOLOCK) ON CT.ID = PCQ.ControlTypeID
	LEFT JOIN DataType DT WITH (NOLOCK) on DT.ID = PCQ.DataTypeID
	LEFT JOIN ProductCategoryQuestionLink PCL WITH (NOLOCK) on PCL.ParentProductCategoryQuestionID = PCP.ProductCategoryQuestionID
													AND PCL.IsActive = 1
	LEFT JOIN ProductCategoryQuestionValue PVAL WITH (NOLOCK) on PVAL.ID = PCL.ProductCategoryQuestionValueID
													AND PVAL.IsActive = 1 
	WHERE	PCQ.ProductCategoryID IN (SELECT ProductCategoryID FROM @relevantProductCategories )
	AND		PCQ.IsActive = 1
	AND		SS.Name = @sourceSystemName
	ORDER BY PCQ.Sequence 
  
	--SELECT * FROM @Questions 

	SELECT PCV.ProductCategoryQuestionID, PCV.Value, PCV.IsPossibleTow, PCV.Sequence FROM ProductCategoryQuestionValue PCV
	JOIN @Questions Q ON Q.ProductCategoryQuestionID = PCV.ProductCategoryQuestionID 
	WHERE PCV.IsActive = 1
	AND  Q.ProductCategoryName NOT IN ('Repair','Billing')
	GROUP BY PCV.ProductCategoryQuestionID, PCV.Value, PCV.IsPossibleTow,PCV.Sequence
	ORDER BY PCV.ProductCategoryQuestionID,PCV.Sequence 

END