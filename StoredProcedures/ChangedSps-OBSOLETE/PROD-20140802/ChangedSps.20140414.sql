
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
-- EXEC [dbo].[dms_GoToPODetails_row] 1414, 100,100,100,null,null,25   
--32.780122,-96.801412,'TX','US',32.864132,-96.942948,
 CREATE PROCEDURE [dbo].[dms_GoToPODetails_row](
-- @ServiceLocationLatitude decimal(10,7)
-- ,@ServiceLocationLongitude decimal(10,7)
--,@ServiceLocationStateProvince varchar(20)
--,@ServiceLocationCountryCode varchar(20)
--,@DestinationLocationLatitude  decimal(10,7)
--,@DestinationLocationLongitude  decimal(10,7)
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

	DECLARE @ServiceLocation as geography  

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
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and RateDetail.RateQuantity = 0 THEN @EnrouteMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity = 0 and ISNULL(@PrimaryCoverageLimitMileage,0) > 0 and @ServiceMiles > ISNULL(@PrimaryCoverageLimitMileage,0) THEN ISNULL(@PrimaryCoverageLimitMileage,0)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity = 0 THEN @ServiceMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and RateDetail.RateQuantity <> 0 THEN (CASE WHEN RateDetail.RateQuantity > @EnrouteMiles THEN @EnrouteMiles ELSE RateDetail.RateQuantity END)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity <> 0 THEN (CASE WHEN RateDetail.RateQuantity > @ServiceMiles THEN @ServiceMiles ELSE RateDetail.RateQuantity END)
		  ELSE 0 END Quantity
	,ROUND(CASE 
		  WHEN RateDetail.UnitOfMeasure = 'Each' THEN RateDetail.RatePrice 
	WHEN RateDetail.UnitOfMeasure = 'Hour' THEN RateDetail.RatePrice * @EstimatedHours
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and RateDetail.RateQuantity = 0 THEN RateDetail.RatePrice * @EnrouteMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity = 0 and ISNULL(@PrimaryCoverageLimitMileage,0) > 0 and @ServiceMiles > ISNULL(@PrimaryCoverageLimitMileage,0)  THEN RateDetail.RatePrice * ISNULL(@PrimaryCoverageLimitMileage,0)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity = 0 THEN RateDetail.RatePrice * @ServiceMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and RateDetail.RateQuantity <> 0 THEN RateDetail.RatePrice * (CASE WHEN RateDetail.RateQuantity > @EnrouteMiles THEN @EnrouteMiles ELSE RateDetail.RateQuantity END)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity <> 0 THEN RateDetail.RatePrice * (CASE WHEN RateDetail.RateQuantity > @ServiceMiles THEN @ServiceMiles ELSE RateDetail.RateQuantity END)
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
						  ELSE 0 END AS RatePrice
				,CASE WHEN VendorLocationRate.Price IS NOT NULL THEN VendorLocationRate.Quantity
						  WHEN VendorDefaultRate.Price IS NOT NULL THEN VendorDefaultRate.Quantity
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
		  WHERE p.id = @ProductID
				and prt.IsOptional = 0
		  ) RateDetail

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
	

END

GO
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
			WHERE id = object_id(N'[dbo].[dms_service_limits_get_for_PO_Update]')   		AND type in (N'P', N'PC')) 
BEGIN
	DROP PROCEDURE [dbo].[dms_service_limits_get_for_PO_Update] 
END 
GO
/****** Object:  StoredProcedure [dbo].[dms_service_limits_get_for_PO_Update]    Script Date: 03/31/2013 20:42:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [dbo].[dms_service_limits_get_for_PO_Update] @programID = 3,@vehicleCategoryID = 1, @purchaseOrderID = 276,@productID =141,@productRateID=1
 
 CREATE PROCEDURE [dbo].[dms_service_limits_get_for_PO_Update]( 
   @programID INT = NULL,
   @vehicleCategoryID INT = NULL,
   @purchaseOrderID INT = NULL, 
   @productID INT =NULL,
   @productRateID INT =NULL
 ) 
 AS 
 BEGIN 
 
 SET FMTONLY OFF
 Declare @update bit
 set @update=0;
 IF((select count(*) from RateType where Name in ('Base','Hourly') AND ID=@productRateID)>0 AND (select Count(*) from Product p
Inner join ProductSubType ps ON p.ProductSubTypeID=ps.ID
where ps.Name in('PrimaryService','SecondaryService')
AND p.ID=@productID)>0)
 BEGIN
 SET @update=1
 END
 SELECT @update as ProductChanged
 END
 

GO
