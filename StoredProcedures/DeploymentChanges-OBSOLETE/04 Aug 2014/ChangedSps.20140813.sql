
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
	

END
GO
GO
--USE [DMS]
GO
/****** Object:  StoredProcedure [dbo].[dms_service_request_export_prepare]    Script Date: 04/04/2013 09:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


		 
ALTER PROC [dbo].[dms_service_request_export_prepare]
AS
BEGIN

	DECLARE @AppConfig AS INT  

	SET @AppConfig = (Select ISNULL(AC.Value,330) From ApplicationConfiguration AC 
	JOIN ApplicationConfigurationType ACT on ACT.ID = AC.ApplicationConfigurationTypeID
	JOIN ApplicationConfigurationCategory ACC on ACC.ID = AC.ApplicationConfigurationCategoryID
	Where AC.Name='AgingReadyForExportMinutes'
	AND ACT.Name = 'WindowsService'
	AND ACC.Name = 'DispatchProcessingService') 

	UPDATE SR 
	SET 
		ReadyForExportDate = GETDATE(),
		ModifyDate = getdate(),
		ModifyBy = 'system'
	FROM ServiceRequest SR
	JOIN dbo.ServiceRequestStatus SRStatus
		ON SR.ServiceRequestStatusID = SRStatus.ID
	WHERE
	SRStatus.Name IN ('Cancelled', 'Complete')		
	AND SR.ReadyForExportDate IS NULL 
	AND SR.DataTransferDate IS NULL
	AND DATEADD(mi,@AppConfig,SR.CreateDate)<= GETDATE()	
	AND NOT EXISTS (
		SELECT *
		FROM PurchaseOrder PO
		JOIN PurchaseOrderStatus POStatus
			ON PO.PurchaseOrderStatusID = POStatus.ID
		WHERE PO.ServiceRequestID = SR.ID
		AND POStatus.Name IN ('Cancelled', 'Issued','Issued-Paid')
		)

		
	UPDATE PO   
	SET 
		ReadyForExportDate = GETDATE(),
		ModifyDate = getdate(),
		ModifyBy = 'system'
	FROM PurchaseOrder  PO
	JOIN PurchaseOrderStatus POStatus
		ON PO.PurchaseOrderStatusID = POStatus.ID
	WHERE 
	PO.ReadyForExportDate IS NULL
	AND PO.DataTransferDate IS NULL
	AND POStatus.Name IN ('Cancelled', 'Issued','Issued-Paid')
	AND DATEADD(mi,@AppConfig,PO.IssueDate)<= GETDATE()
	AND PO.IsActive = 1	  -- RH Added 3/16/2013 4:44 PM
	
	
	/* Force expiration of added (temp) members to 2 days (or less)  */
	/* Exception: ARS */
	--UPDATE M SET
	--	EffectiveDate = CAST(CONVERT(varchar, m.CreateDate,101) as datetime)
	--	,ExpirationDate = DATEADD(dd, 2, CAST(CONVERT(varchar, m.CreateDate,101) as datetime))
	--FROM member m 
	--JOIN program p on p.ID = m.ProgramID
	--JOIN client cl on cl.ID = p.ClientID
	--WHERE
	--m.ClientMemberKey IS NULL
	--AND p.Name <> 'Hagerty Employee'


	/* Prevent bad data entry for ARS effective and expiration dates */
	--UPDATE M SET
	--	EffectiveDate = CASE WHEN m.EffectiveDate < '1950-01-01' THEN CAST(CONVERT(varchar, m.CreateDate,101) as datetime) ELSE m.EffectiveDate END
	--	,ExpirationDate = CASE WHEN m.ExpirationDate > '2039-12-31' THEN DATEADD(yy, 5, CAST(CONVERT(varchar, m.CreateDate,101) as datetime)) ELSE m.ExpirationDate END
	--FROM member m 
	--JOIN program p on p.ID = m.ProgramID
	--JOIN client cl on cl.ID = p.ClientID
	--WHERE
	--m.ClientMemberKey IS NULL
	--AND cl.Name = 'ARS'
	--AND (m.EffectiveDate < '1950-01-01' OR m.ExpirationDate > '2039-12-31')

END
GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_UpdateAdminisrativeRating]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_UpdateAdminisrativeRating] 
 END 
 GO  
 SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_Vendor_UpdateAdminisrativeRating] 
AS
BEGIN

      Update v1 Set 
      --select v1.id, (Select name from VendorStatus where id = v1.VendorStatusID), v1.vendornumber, v1.AdministrativeRating,
            AdministrativeRating = v2.AdministrativeRating,
            AdministrativeRatingModifyDate = GETDATE()
      From vendor v1
      JOIN (
            SELECT v.ID, v.VendorNumber
                  ,CASE WHEN ContractVendor.VendorID IS NOT NULL THEN 60 ELSE 20 END +
                   CASE WHEN v.InsuranceExpirationDate >= getdate() THEN 10 ELSE 0 END +
                   CASE WHEN ach.ID IS NOT NULL THEN 10 ELSE 0 END +
                   CASE WHEN [24Hours].VendorID IS NOT NULL THEN 10 ELSE 0 END +
                   CASE WHEN (v.TaxSSN IS NOT NULL AND LEN(v.TaxSSN) = 9) OR v.TaxEIN IS NOT NULL THEN 10 ELSE 0 END AS AdministrativeRating
            FROM dbo.Vendor v
            LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractVendor On ContractVendor.VendorID = v.ID
            LEFT OUTER JOIN VendorACH ach ON ach.VendorID = v.ID AND ach.IsActive = 1 AND ach.ACHStatusID = (SELECT ID FROM ACHStatus WHERE Name = 'Valid')
            LEFT OUTER JOIN (
                  Select VendorID
                  From VendorLocation 
                  Where IsOpen24Hours = 'TRUE'
                  Group By VendorID
                  ) [24Hours] On [24Hours].VendorID = v.ID
            ) v2 on v2.ID = v1.ID
      where ISNULL(v1.AdministrativeRating, 0) <> v2.AdministrativeRating
      and v1.VendorStatusID = (SELECT ID FROM VendorStatus WHERE Name = 'Active')
END

GO
