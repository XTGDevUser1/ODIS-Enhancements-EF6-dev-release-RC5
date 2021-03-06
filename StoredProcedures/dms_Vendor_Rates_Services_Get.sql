GO
/****** Object:  StoredProcedure [dbo].[dms_Vendor_Rates_Services_Get]    Script Date: 08/29/2013 00:50:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--EXEC dms_Vendor_Rates_Services_Get @rateScheduleID=6778, @VendorLocationID = 91927
CREATE PROCEDURE [dbo].[dms_Vendor_Rates_Services_Get] 
 (
	@RateScheduleID INT = NULL
	,@VendorLocationID INT = NULL 
 ) 
AS
BEGIN 

	SELECT 
	  VendorDefaultRates.ContractRateScheduleID
	  ,VendorDefaultRates.ProductID
	  ,p.Name
	  ,SUM(CASE WHEN rt.Name = 'Base' THEN 
	   (CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Price  
		WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Price  
		ELSE 0.00   
		END) 
	   ELSE 0 END) AS BaseRate
	  ,SUM(CASE WHEN rt.Name = 'Enroute' THEN 
	   (CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Price  
		WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Price  
		ELSE 0.00   
		END) 
	   ELSE 0 END) AS EnrouteRate
	  ,SUM(CASE WHEN rt.Name = 'EnrouteFree' THEN 
	   (CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Quantity  
		WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Quantity  
		ELSE 0.00   
		END) 
	   ELSE 0 END) AS EnrouteFreeMiles
	  ,SUM(CASE WHEN rt.Name = 'Service' THEN 
	   (CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Price  
		WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Price  
		ELSE 0.00   
		END) 
	   ELSE 0 END) AS ServiceRate
	  ,SUM(CASE WHEN rt.Name = 'ServiceFree' THEN 
	   (CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Quantity  
		WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Quantity  
		ELSE 0.00   
		END) 
	   ELSE 0 END) AS ServiceFreeMiles
	  ,SUM(CASE WHEN rt.Name = 'Hourly' THEN 
	   (CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Price  
		WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Price  
		ELSE 0.00   
		END) 
	   ELSE 0 END) AS HourlyRate
	  ,SUM(CASE WHEN rt.Name = 'GoneOnArrival' THEN 
	   (CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Price  
		WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Price  
		ELSE 0.00   
		END) 
	   ELSE 0 END) AS GOARate
	 
	FROM dbo.fnGetAllProductRatesByVendorLocation() VendorDefaultRates  
	JOIN dbo.Product p ON p.ID = VendorDefaultRates.ProductID  
	JOIN dbo.VendorProduct vp ON vp.VendorID = VendorDefaultRates.VendorID and vp.ProductID = VendorDefaultRates.ProductID and vp.IsActive = 1
	JOIN dbo.ProductRateType prt ON prt.ProductID = VendorDefaultRates.ProductID AND prt.RateTypeID = VendorDefaultRates.RateTypeID
	JOIN dbo.RateType rt ON prt.RateTypeID = rt.ID  
	LEFT OUTER JOIN dbo.fnGetAllProductRatesByVendorLocation() VendorLocationRates  
		ON VendorLocationRates.ContractRateScheduleID = VendorDefaultRates.ContractRateScheduleID AND
			VendorLocationRates.ProductID = VendorDefaultRates.ProductID AND
			VendorLocationRates.RateTypeID = VendorDefaultRates.RateTypeID AND
			VendorLocationRates.VendorLocationID = @VendorLocationID
	WHERE
		VendorDefaultRates.ContractRateScheduleID = @RateScheduleID AND
		VendorDefaultRates.VendorLocationID IS NULL AND
		(@VendorLocationID IS NULL
		 OR
		 EXISTS (
			SELECT * 
			FROM VendorLocationProduct vlp 
			WHERE vlp.VendorLocationID = @VendorLocationID
			AND vlp.ProductID = vp.ProductID
			AND vlp.IsActive = 1
			)
		)
	GROUP BY 
		VendorDefaultRates.ContractRateScheduleID
		,VendorDefaultRates.ProductID
		,p.Name
	ORDER BY 
		p.Name

END
GO

