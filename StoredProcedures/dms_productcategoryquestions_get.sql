IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_productcategoryquestions_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_productcategoryquestions_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_productcategoryquestions_get] 458,1,1,NULL,'MemberMobile'
 
CREATE PROCEDURE [dbo].[dms_productcategoryquestions_get]( 
   @ProgramID int,   
   @VehicleTypeID int = NULL,
   @VehicleCategoryID int = NULL,
   @serviceRequestID INT = NULL,
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
  Sequence int,
  AnswerValue NVARCHAR(MAX) NULL, -- Answer provided for this question
  IsEnabled BIT,
  VehicleCategoryID INT NULL
)
DECLARE @relevantProductCategories TABLE
(
	ProductCategoryID INT,
	Sequence INT NULL
)

--DEBUG : FOR EF
IF(@ProgramID IS NULL)
BEGIN
	SELECT * FROM @Questions
	RETURN;
END
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

IF ( (SELECT COUNT(*) FROM @relevantProductCategories R,ProductCategory PC WHERE PC.ID = R.ProductCategoryID AND PC.Name like 'Tow%') = 0)
BEGIN
	INSERT INTO @relevantProductCategories
	SELECT	PC.ID,
			PC.Sequence
	FROM ProductCategory PC WHERE Name like 'Tow%' AND PC.IsActive = 1
END

IF ( (SELECT COUNT(*) FROM @relevantProductCategories R,ProductCategory PC WHERE PC.ID = R.ProductCategoryID AND PC.Name like 'Tow%') = 0)
BEGIN
	INSERT INTO @relevantProductCategories
	SELECT	PC.ID,
			PC.Sequence
	FROM ProductCategory PC  WHERE Name like 'Tow%'	AND PC.IsActive = 1
		  
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
  PCQ.Sequence,
  NULL,
  CASE WHEN (PCV.VehicleCategoryID IS NULL OR PCV.VehicleCategoryID = @VehicleCategoryID)
		THEN CAST (1 AS BIT)
		ELSE CAST (0 AS BIT)
  END AS IsEnabled,
  PCV.VehicleCategoryID
  FROM [dbo].ProductCategoryQuestion PCQ WITH (NOLOCK)
  JOIN [dbo].ProductCategoryQuestionSourceSystem PCQS WITH (NOLOCK) ON PCQ.ID = PCQS.ProductCategoryQuestionID
  JOIN	[dbo].[SourceSystem] SS WITH (NOLOCK) ON SS.ID = PCQS.SourceSystemID
  /*** KB: The following join was original code from Martex
  JOIN ProductCategoryQuestionVehicleType PCV ON PCV.ProductCategoryQuestionID = PCQ.ID 
  **/
  -- KB: Changed inner join to Left join.
  --RA: Changed to check IS NULL for VehicleType and added VehicleCategory back in
  JOIN ProductCategoryQuestionVehicleType PCV WITH (NOLOCK) ON PCV.ProductCategoryQuestionID = PCQ.ID 
	AND (PCV.VehicleTypeID IS NULL OR PCV.VehicleTypeID = @VehicleTypeID) 
	-- KB: Do not consider @vehicleCategoryID here.By design, we load all the questions for a given vehicle type and show/hide questions relevant to vehiclecategory. Therefore, questions / product categories should not get filtered out here.
	--AND (PCV.VehicleCategoryID IS NULL OR PCV.VehicleCategoryID = @VehicleCategoryID)
	AND PCV.IsActive = 1 
  JOIN ProductCategory PC WITH (NOLOCK) ON PCQ.ProductCategoryID = PC.ID
  LEFT JOIN ControlType CT WITH (NOLOCK) ON CT.ID = PCQ.ControlTypeID
  LEFT JOIN DataType DT WITH (NOLOCK) on DT.ID = PCQ.DataTypeID
  LEFT JOIN ProductCategoryQuestionLink PCL WITH (NOLOCK) on PCL.ParentProductCategoryQuestionID = PCV.ProductCategoryQuestionID
  AND PCL.IsActive = 1
  LEFT JOIN ProductCategoryQuestionValue PVAL WITH (NOLOCK) on PVAL.ID = PCL.ProductCategoryQuestionValueID
  AND PVAL.IsActive = 1 
  WHERE PCQ.ProductCategoryID IN (SELECT ProductCategoryID FROM @relevantProductCategories )
  AND	PCQ.IsActive = 1
  AND	SS.Name = @sourceSystemName
  
  UNION ALL
  
SELECT DISTINCT 
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
  PCQ.Sequence,
  NULL,
  CASE WHEN (PCP.VehicleCategoryID IS NULL OR PCP.VehicleCategoryID = @VehicleCategoryID)
		THEN CAST (1 AS BIT)
		ELSE CAST (0 AS BIT)
  END AS IsEnabled,
  PCP.VehicleCategoryID 
  FROM [dbo].ProductCategoryQuestion PCQ WITH (NOLOCK)
  JOIN [dbo].ProductCategoryQuestionSourceSystem PCQS WITH (NOLOCK) ON PCQ.ID = PCQS.ProductCategoryQuestionID
  JOIN	[dbo].[SourceSystem] SS WITH (NOLOCK) ON SS.ID = PCQS.SourceSystemID
  JOIN ProductCategoryQuestionProgram PCP WITH (NOLOCK) ON PCP.ProductCategoryQuestionID = PCQ.ID 
	AND (PCP.VehicleTypeID IS NULL OR PCP.VehicleTypeID = @VehicleTypeID )
	-- KB: Do not consider @vehicleCategoryID here.By design, we load all the questions for a given vehicle type and show/hide questions relevant to vehiclecategory. Therefore, questions / product categories should not get filtered out here.
	--AND (PCP.VehicleCategoryID IS NULL OR PCP.VehicleCategoryID = @VehicleCategoryID)
	AND PCP.IsActive = 1 
	JOIN ProductCategory PC WITH (NOLOCK) ON PCQ.ProductCategoryID = PC.ID
  JOIN fnc_GetProgramsandParents(@ProgramID) fncP on fncP.ProgramID = PCP.ProgramID 
  LEFT JOIN ControlType CT WITH (NOLOCK) ON CT.ID = PCQ.ControlTypeID
  LEFT JOIN DataType DT WITH (NOLOCK) on DT.ID = PCQ.DataTypeID
  LEFT JOIN ProductCategoryQuestionLink PCL WITH (NOLOCK) on PCL.ParentProductCategoryQuestionID = PCP.ProductCategoryQuestionID
  AND PCL.IsActive = 1
  LEFT JOIN ProductCategoryQuestionValue PVAL WITH (NOLOCK) on PVAL.ID = PCL.ProductCategoryQuestionValueID
  AND PVAL.IsActive = 1 
  WHERE PCQ.ProductCategoryID IN (SELECT ProductCategoryID FROM @relevantProductCategories )
  AND	PCQ.IsActive = 1
  AND	SS.Name = @sourceSystemName
  ORDER BY PCQ.Sequence 

	IF @serviceRequestID IS NULL
	BEGIN  
		SELECT * FROM @Questions
		WHERE  ProductCategoryName NOT IN ('Repair','Billing')
		ORDER BY ProductCategoryID,ProductCategoryQuestionID, Sequence
	END
	ELSE
	BEGIN
		SELECT	
				Q.ProductCategoryID,
				Q.ProductCategoryName,
				Q.ProductCategoryQuestionID, 
				Q.QuestionText,
				Q.ControlType,
				Q.DataType,
				Q.HelpText,
				Q.IsRequired,
				Q.SubQuestionID,
				Q.RelatedAnswer,
				Q.Sequence,
				SR.Answer AS AnswerValue,
				Q.IsEnabled,
				Q.VehicleCategoryID
		FROM @Questions Q 
		LEFT JOIN ServiceRequestDetail SR ON Q.ProductCategoryQuestionID = SR.ProductCategoryQuestionID 
						AND SR.ServiceRequestID = @serviceRequestID
		WHERE  ProductCategoryName NOT IN ('Repair','Billing')
		ORDER BY ProductCategoryID,ProductCategoryQuestionID, Q.Sequence
				
	
	END
	


END