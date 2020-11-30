
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_GoToPODetails_row]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_GoToPODetails_row] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_GoToPODetails_row] 323184, 3,3,2,139,122825,NULL   
--32.780122,-96.801412,'TX','US',32.864132,-96.942948,
 CREATE PROCEDURE [dbo].[dms_GoToPODetails_row](
	@ServiceRequestID int 
	,@EnrouteMiles decimal(18,4) 
	,@ReturnMiles  decimal(18,4) 
	,@EstimatedHours decimal(18,4) 
	,@ProductID int 
	,@VendorLocationID int 
	,@VendorID int = NULL
) 
AS 
BEGIN

	SET FMTONLY OFF;
 	SET NOCOUNT ON;
 	
	DECLARE @ServiceLocationLatitude decimal(10,7)
		,@ServiceLocationLongitude decimal(10,7)
		,@ServiceLocationStateProvince varchar(20)
		,@ServiceLocationCountryCode varchar(20)
		,@DestinationLocationLatitude  decimal(10,7)
		,@DestinationLocationLongitude  decimal(10,7)
		,@ServiceMiles decimal(10,2)
		,@PrimaryCoverageLimitMileage int
		,@EnrouteFreeRateTypeID int
		,@ServiceFreeRateTypeID int
		,@ServiceLocation as geography  

	SET @EnrouteFreeRateTypeID = (SELECT ID FROM RateType WHERE Name = 'EnrouteFree')
	SET @ServiceFreeRateTypeID = (SELECT ID FROM RateType WHERE Name = 'ServiceFree')

	SELECT 
		@ServiceLocationLatitude =ServiceLocationLatitude
		,@ServiceLocationLongitude=ServiceLocationLongitude
		,@ServiceLocationStateProvince=ServiceLocationStateProvince
		,@ServiceLocationCountryCode=ServiceLocationCountryCode
		,@DestinationLocationLatitude=DestinationLatitude
		,@DestinationLocationLongitude=DestinationLongitude
		,@ServiceMiles= ISNULL(ServiceMiles,0)
		,@PrimaryCoverageLimitMileage = ISNULL(PrimaryCoverageLimitMileage,0)
		FROM ServiceRequest Where 
		ID=@ServiceRequestID

	-- KB: Take the product from service request, if the param is null.
	IF (@ProductID IS NULL)
	BEGIN
	SELECT @ProductID = PrimaryProductID FROM ServiceRequest Where ID=@ServiceRequestID 
	END
	--PR: Take the VendorID From VendorLocation
	IF(@VendorID IS NULL)
	BEGIN
	SELECT @VendorID= VendorID from VendorLocation where ID=@VendorLocationID
	END

	SET @ServiceLocation = geography::Point(ISNULL(@ServiceLocationLatitude,0), ISNULL(@ServiceLocationLongitude,0), 4326)  
 
	/* Get Market product rates according to market location */  
	CREATE TABLE #MarketRates (  
	[ProductID] [int] NULL,  
	[RateTypeID] [int] NULL,  
	[Name] [nvarchar](50) NULL,  
	[Price] [money] NULL,  
	[Quantity] [int] NULL  
	)  
	  
	INSERT INTO #MarketRates  
	SELECT ProductID, RateTypeID, Name, RatePrice, CASE WHEN Name = 'Base' Then 1 Else RateQuantity End RateQuantity  
	FROM dbo.fnGetDefaultProductRatesByMarketLocation(@ServiceLocation, @ServiceLocationCountryCode, @ServiceLocationStateProvince)  
	  
	CREATE CLUSTERED INDEX IDX_MarketRates ON #MarketRates(ProductID, RateTypeID)  
      
    --Select * From #MarketRates  
      
	SELECT 
		  @VendorLocationID AS VendorLocationID
		  ,RateDetail.ProductID
		  ,RateDetail.ProductName
		  ,RateDetail.RateTypeID
		  ,RateTypeName
		  ,RateDetail.Sequence
		  ,RateDetail.ContractedRate
		  ,RateDetail.RatePrice
		  ,RateDetail.RateQuantity
		  ,RateDetail.UnitOfMeasure
		  ,RateDetail.UnitOfMeasureSource
		  ,CASE 
				WHEN RateDetail.UnitOfMeasure = 'Each' THEN 1 
				WHEN RateDetail.UnitOfMeasure = 'Hour' THEN @EstimatedHours
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and ISNULL(RateDetail.RateQuantity,0) = 0 THEN @EnrouteMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and ISNULL(RateDetail.RateQuantity,0) = 0 and ISNULL(@PrimaryCoverageLimitMileage,0) > 0 and @ServiceMiles > ISNULL(@PrimaryCoverageLimitMileage,0) THEN ISNULL(@PrimaryCoverageLimitMileage,0)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and ISNULL(RateDetail.RateQuantity,0) = 0 THEN @ServiceMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and ISNULL(RateDetail.RateQuantity,0) <> 0 THEN (CASE WHEN RateDetail.RateQuantity > @EnrouteMiles THEN @EnrouteMiles ELSE RateDetail.RateQuantity END)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and ISNULL(RateDetail.RateQuantity,0) <> 0 THEN (CASE WHEN RateDetail.RateQuantity > @ServiceMiles THEN @ServiceMiles ELSE RateDetail.RateQuantity END)
		  ELSE 0 END Quantity
	,ROUND(CASE 
		  WHEN RateDetail.UnitOfMeasure = 'Each' THEN RateDetail.RatePrice 
	WHEN RateDetail.UnitOfMeasure = 'Hour' THEN RateDetail.RatePrice * @EstimatedHours
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and ISNULL(RateDetail.RateQuantity,0) = 0 THEN RateDetail.RatePrice * @EnrouteMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and ISNULL(RateDetail.RateQuantity,0) = 0 and ISNULL(@PrimaryCoverageLimitMileage,0) > 0 and @ServiceMiles > ISNULL(@PrimaryCoverageLimitMileage,0)  THEN RateDetail.RatePrice * ISNULL(@PrimaryCoverageLimitMileage,0)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and ISNULL(RateDetail.RateQuantity,0) = 0 THEN RateDetail.RatePrice * @ServiceMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and ISNULL(RateDetail.RateQuantity,0) <> 0 THEN RateDetail.RatePrice * (CASE WHEN RateDetail.RateQuantity > @EnrouteMiles THEN @EnrouteMiles ELSE RateDetail.RateQuantity END)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and ISNULL(RateDetail.RateQuantity,0) <> 0 THEN RateDetail.RatePrice * (CASE WHEN RateDetail.RateQuantity > @ServiceMiles THEN @ServiceMiles ELSE RateDetail.RateQuantity END)
		  ELSE 0 END,2) ExtendedAmount
	,0 IsMemberPay
	INTO #PODetail
	FROM
		(
		Select 
			p.ID ProductID
			,p.Name ProductName
			,prt.RateTypeID 
			,rt.Name RateTypeName
			,prt.Sequence
			,CASE WHEN VendorLocationRate.Price IS NOT NULL THEN VendorLocationRate.Price
					  WHEN VendorDefaultRate.Price IS NOT NULL THEN VendorDefaultRate.Price
					  ELSE 0 END AS ContractedRate
			,CASE WHEN VendorLocationRate.Price IS NOT NULL THEN VendorLocationRate.Price
					  WHEN VendorDefaultRate.Price IS NOT NULL THEN VendorDefaultRate.Price
					  WHEN MarketRates.Price IS NOT NULL THEN MarketRates.Price
					  ELSE 0 END AS RatePrice
			,CASE WHEN VendorLocationRate.Price IS NOT NULL THEN VendorLocationRate.Quantity
					  WHEN VendorDefaultRate.Price IS NOT NULL THEN VendorDefaultRate.Quantity
					  WHEN MarketRates.Price IS NOT NULL THEN MarketRates.Quantity
					  ELSE 0 END AS RateQuantity
			,rt.UnitOfMeasure 
			,rt.UnitOfMeasureSource 
		From dbo.Product p 
		Join dbo.ProductRateType prt 
			On prt.ProductID = p.ID
		Left Outer Join dbo.RateType rt 
			On prt.RateTypeID = rt.ID
		LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() VendorLocationRate 
			ON VendorLocationRate.VendorID = @VendorID AND 
			p.ID = VendorLocationRate.ProductID AND 
			prt.RateTypeID = VendorLocationRate.RateTypeID AND
			VendorLocationRate.VendorLocationID = @VendorLocationID 
		LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() VendorDefaultRate
			ON VendorDefaultRate.VendorID = @VendorID AND 
			p.ID = VendorDefaultRate.ProductID AND 
			prt.RateTypeID = VendorDefaultRate.RateTypeID AND
			VendorDefaultRate.VendorLocationID IS NULL
		LEFT OUTER JOIN #MarketRates MarketRates ON p.ID = MarketRates.ProductID And MarketRates.RateTypeID = prt.RateTypeID 
			--TP: Added condition to prevent backfill of market rates for missing contracted vendor rates 
			AND NOT EXISTS (
				Select * 
				From [dbo].[fnGetCurrentProductRatesByVendorLocation]() r2 
				Where r2.VendorID = @VendorID 
					and r2.ProductID = p.ID 
					and r2.RateName IN ('Base','Hourly')
					and r2.Price <> 0) 
		  WHERE p.id = @ProductID
				and prt.IsOptional = 0
		  ) RateDetail
	--TP: Add logic to eliminate Free Mile rates without mile quantity; Causing all miles to be free
	WHERE (RateDetail.RateTypeID <> @EnrouteFreeRateTypeID OR ISNULL(RateDetail.RateQuantity,0) <> 0)
	AND (RateDetail.RateTypeID <> @ServiceFreeRateTypeID OR ISNULL(RateDetail.RateQuantity,0) <> 0)

	--TP: Added logic to inject additional Member Pay line item for over program towing limit
	IF @PrimaryCoverageLimitMileage > 0 AND @ServiceMiles > @PrimaryCoverageLimitMileage
		INSERT INTO #PODetail
		SELECT VendorLocationID
			,ProductID
			,ProductName
			,RateTypeID
			,RateTypeName
			,Sequence
			,ContractedRate
			,RatePrice
			,RateQuantity
			,UnitOfMeasure
			,UnitOfMeasureSource
			,(@ServiceMiles - @PrimaryCoverageLimitMileage) Quantity
			,(@ServiceMiles - @PrimaryCoverageLimitMileage) * RatePrice ExtendedAmount
			,IsMemberPay = 1
		FROM #PODetail 
		WHERE RateTypeName = 'Service'
		ORDER BY Sequence

	SELECT 
		VendorLocationID
		,ProductID
		,ProductName
		,RateTypeID
		,RateTypeName
		,Sequence
		,ContractedRate
		,RatePrice
		,RateQuantity
		,UnitOfMeasure
		,UnitOfMeasureSource
		,Quantity
		,ExtendedAmount
		,IsMemberPay 
	FROM #PODetail
	ORDER BY Sequence

	DROP TABLE #PODetail
	DROP TABLE #MarketRates
	

END
