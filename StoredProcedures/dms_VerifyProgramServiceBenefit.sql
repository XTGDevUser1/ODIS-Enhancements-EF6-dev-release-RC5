/*******************
* Operator Enums 
*  Conditions Enum :
* -1 - No filter
*  0 - Null
*  1 - Not Null
*  2 - Equals
*  3 - NotEquals
*  ---- for strings ---
*  4 - StartsWith
*  5 - EndsWith
*  6 - Contains
*  ---- for int, decimal, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_VerifyProgramServiceBenefit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC dms_VerifyProgramServiceBenefit 1, 1, 1, 1, 1, NULL, NULL  
CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit]  
       @ProgramID INT   
      , @ProductCategoryID INT  
      , @VehicleCategoryID INT  
      , @VehicleTypeID INT  
      , @SecondaryCategoryID INT = NULL  
      , @ServiceRequestID  INT = NULL  
      , @ProductID INT = NULL  
      , @IsPrimaryOverride BIT = NULL
AS  
BEGIN   
  
	SET NOCOUNT ON    
	SET FMTONLY OFF    

	--KB: 
	SET @ProductID = NULL

	DECLARE @SecondaryProductID INT
		,@OverrideCoverageLimit money 

	/*** Determine Primary and Secondary Product IDs ***/  
	/* Ignore Vehicle related values for Product Categories not requiring a Vehicle */
	IF @ProductCategoryID IN (SELECT ID FROM ProductCategory WHERE IsVehicleRequired = 0)
	BEGIN
		SET @VehicleCategoryID = NULL
		SET @VehicleTypeID = NULL
	END

	/* Select Basic Lockout over Locksmith when a specific product is not provided */  
	IF @ProductID IS NULL AND @ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Lockout')  
	BEGIN  
	SET @ProductID = (SELECT ID FROM Product WHERE Name = 'Basic Lockout')  
	END  

	/* Select Tire Change over Tire Repair when a specific product is not provided */  
	IF @ProductID IS NULL AND @ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tire')  
	BEGIN  
	SET @ProductID = (SELECT ID FROM Product WHERE Name like 'Tire Change%' AND VehicleCategoryID = @VehicleCategoryID)  
	END  

	IF @ProductID IS NULL  
	SELECT @ProductID = p.ID   
	FROM  ProductCategory pc (NOLOCK)   
	JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID   
	  AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')  
	  AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')  
	WHERE  
	pc.ID = @ProductCategoryID   
	AND (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)  
	AND (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)  


	IF @SecondaryCategoryID IS NOT NULL  
	SELECT @SecondaryProductID = p.ID   
	FROM  ProductCategory pc (NOLOCK)   
	JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID   
	  AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')  
	  AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')  
	WHERE  
	pc.ID = @SecondaryCategoryID   
	AND (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)  
	AND (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)  


	-- Coverage Limit Override for Ford ESP vehicles E/F 650 and 750; Blue Bird Bus
	IF @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Extended Service Plan (RV & COMM)')
	BEGIN
	
	----Override for Ford Medium and Heavy Duty
	---- TP 10/1 - All Ford Comm now $200 - Logic no longer needed
	--IF EXISTS(
	--	SELECT * 
	--	FROM [Case] c
	--	JOIN ServiceRequest sr ON sr.CaseID = c.ID
	--	WHERE sr.ID = @ServiceRequestID
	--		AND (SUBSTRING(c.VehicleVIN, 6, 1) IN ('6','7')
	--			OR c.VehicleModel IN ('F-650', 'F-750', 'E-650', 'E-750'))
	--	)
	--	SET @OverrideCoverageLimit = 200.00
		
	-- Override for Ford Bluebird bus	
	IF EXISTS(
		SELECT * 
		FROM [Case] c
		JOIN ServiceRequest sr ON sr.CaseID = c.ID
		WHERE sr.ID = @ServiceRequestID
			AND c.VehicleMake = 'Blue bird'
		)
		SET @OverrideCoverageLimit = 400.00	
	END
   
   
	SELECT ISNULL(pc.Name,'') ProductCategoryName  
		,pc.ID ProductCategoryID  
		--,pc.Sequence  
		,ISNULL(vc.Name,'') VehicleCategoryName  
		,vc.ID VehicleCategoryID  
		,pp.ProductID  

		,CAST (pp.IsServiceCoverageBestValue AS BIT) AS IsServiceCoverageBestValue
		,CASE WHEN @OverrideCoverageLimit IS NOT NULL THEN @OverrideCoverageLimit ELSE pp.ServiceCoverageLimit END AS ServiceCoverageLimit
		,pp.CurrencyTypeID   
		,pp.ServiceMileageLimit   
		,pp.ServiceMileageLimitUOM   
		,1 AS IsServiceEligible
		--TP: Below logic is not needed; Only eligible services will be added to ProgramProduct 
		--,CASE WHEN pp.ServiceCoverageLimit IS NULL THEN 0   
		--              WHEN pp.IsServiceCoverageBestValue = 1 THEN 1  
		--              WHEN pp.ServiceCoverageLimit = 0 AND pp.IsReimbursementOnly = 1 THEN 1   
		--              WHEN pp.ServiceCoverageLimit = 0 AND ISNULL(pp.ServiceMileageLimit,0) > 0 THEN 1   
		--              WHEN pp.ServiceCoverageLimit = 0 AND pp.ProductID IN (SELECT p.ID FROM Product p WHERE p.ProductCategoryID IN (SELECT ID FROM ProductCategory WHERE Name IN ('Info', 'Tech', 'Concierge'))) THEN 1
		--              WHEN pp.ServiceCoverageLimit > 0 THEN 1  
		--              ELSE 0 END IsServiceEligible  
		,pp.IsServiceGuaranteed   
		,pp.ServiceCoverageDescription  
		,pp.IsReimbursementOnly  
		,CASE WHEN ISNULL(@IsPrimaryOverride,0) = 0 AND pc.ID = @SecondaryCategoryID THEN 0 ELSE 1 END AS IsPrimary  
	FROM ProgramProduct pp (NOLOCK)  
	JOIN Product p ON p.ID = pp.ProductID  
	LEFT OUTER JOIN ProductCategory pc (NOLOCK) ON pc.ID = p.ProductCategoryID  
	LEFT OUTER JOIN VehicleCategory vc (NOLOCK) ON vc.id = p.VehicleCategoryID  
	WHERE pp.ProgramID = @ProgramID  
	AND (pp.ProductID = @ProductID OR pp.ProductID = @SecondaryProductID)  
	ORDER BY   
	(CASE WHEN pc.ID = @SecondaryCategoryID THEN 0 ELSE 1 END) DESC  
	,pc.Sequence  
     
END  

