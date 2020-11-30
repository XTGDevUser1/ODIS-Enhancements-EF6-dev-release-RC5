/* KB: This is procedure is not in use and the logic is moved to dms_Service_Save. The SP is retained in TFS for reference purposes only */
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_servicerequest_productids_set]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_servicerequest_productids_set] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
-- EXEC [dbo].[dms_servicerequest_productids_set] 2,5,1,1,0,3
CREATE PROCEDURE [dbo].[dms_servicerequest_productids_set]( 
	@serviceRequestID INT,
	@ProductCategoryID INT,
	@VehicleTypeID INT,
	@VehicleCategoryID INT,
	@IsPossibleTow BIT,
	@programID INT
)
AS
BEGIN

--SET @ProductCategoryID = (Select ID From ProductCategory Where Name = 'Jump')
--SET @VehicleTypeID = (Select ID From VehicleType Where Name = 'Auto')
--SET @VehicleCategoryID = (Select ID From VehicleCategory Where Name = 'HeavyDuty')
--SET @IsPossibleTow = 'TRUE'
	DECLARE @tmpPrograms TABLE
	(
		LevelID INT IDENTITY(1,1),
		ProgramID INT
	)
	
	INSERT INTO @tmpPrograms
	SELECT ProgramID FROM fnc_GetProgramsandParents (@programID)

	--DEBUG: SELECT * FROM @tmpPrograms
	
	DECLARE @TowProductCategoryID int
	DECLARE @primaryProductID INT
	DECLARE @secondaryProductID INT
	DECLARE @isPrimaryServiceCovered BIT
	DECLARE @isSecondaryServiceCovered BIT

	SET @primaryProductID = NULL
	SET @secondaryProductID = NULL
	
	SET @TowProductCategoryID = (Select ID From ProductCategory Where Name = 'Tow')

	;WITH wPrimaryProducts
	AS
	(
	SELECT	ROW_NUMBER() OVER (PARTITION BY P.ID ORDER BY T.LevelID ASC) AS RowNum,
			T.ProgramID AS ProgramID,			
			p.ID AS ProductID,
			pp.ID AS ProgramProductID,
			pp.IsReimbursementOnly
	FROM	dbo.Product p
	JOIN	dbo.ProductType pt ON p.ProductTypeID = pt.ID
	JOIN	dbo.ProductSubType pst ON p.ProductSubTypeID = pst.ID
	JOIN	dbo.ProductCategory pc ON p.ProductCategoryID = pc.ID
	JOIN	dbo.ProgramProduct pp ON pp.ProductID = P.ID --AND pp.ProgramID = @programID
	JOIN	@tmpPrograms T ON pp.ProgramID = T.ProgramID
	WHERE	pt.Name = 'Service'
	AND		pst.Name = 'PrimaryService'
	AND		pc.ID = @ProductCategoryID
	AND		(p.VehicleTypeID = @VehicleTypeID OR p.VehicleTypeID IS NULL)
	AND (p.VehicleCategoryID = @VehicleCategoryID OR p.VehicleCategoryID IS NULL)
	)
	
	SELECT	@primaryProductID = ProductID,
			@isPrimaryServiceCovered = CASE WHEN ProgramProductID IS NULL OR ISNULL(IsReimbursementOnly, 0) = 1 
											THEN 0 
											ELSE 1 
										END		
	FROM wPrimaryProducts
	
	;WITH wSecondaryProducts
	AS
	(
	SELECT	ROW_NUMBER() OVER (PARTITION BY P.ID ORDER BY T.LevelID ASC) AS RowNum,
			T.ProgramID AS ProgramID,			
			p.ID AS ProductID,
			pp.ID AS ProgramProductID,
			pp.IsReimbursementOnly
	FROM	dbo.Product p
	JOIN	dbo.ProductType pt ON p.ProductTypeID = pt.ID
	JOIN	dbo.ProductSubType pst ON p.ProductSubTypeID = pst.ID
	JOIN	dbo.ProductCategory pc ON p.ProductCategoryID = pc.ID
	JOIN	dbo.ProgramProduct pp ON pp.ProductID = p.ID  -- AND pp.ProgramID = @programID
	JOIN	@tmpPrograms T ON pp.ProgramID = T.ProgramID
	WHERE	pt.Name = 'Service'
	AND		pst.Name = 'PrimaryService'
	AND		@IsPossibleTow = 'TRUE'
	AND		pc.ID = @TowProductCategoryID
	AND		(p.VehicleTypeID = @VehicleTypeID OR p.VehicleTypeID IS NULL)
	AND		(p.VehicleCategoryID = @VehicleCategoryID OR p.VehicleCategoryID IS NULL)	
	)
	
	SELECT	@secondaryProductID = ProductID,
			@isSecondaryServiceCovered = CASE WHEN ProgramProductID IS NULL OR ISNULL(IsReimbursementOnly, 0) = 1 
											THEN 0 
											ELSE 1 
										END		
	FROM wSecondaryProducts

	
	UPDATE	ServiceRequest
	SET		PrimaryProductID = @primaryProductID,
			SecondaryProductID = @secondaryProductID,
			IsPrimaryProductCovered = @isPrimaryServiceCovered,
			IsSecondaryProductCovered = @isSecondaryServiceCovered
	WHERE	ID = @serviceRequestID
	
	
END

