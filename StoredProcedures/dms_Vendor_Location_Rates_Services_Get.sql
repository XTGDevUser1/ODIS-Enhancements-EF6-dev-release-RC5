
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Location_Rates_Services_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Location_Rates_Services_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Vendor_Location_Rates_Services_Get @vendorLocationID=289, @rateScheduleID=1
 CREATE PROCEDURE [dbo].dms_Vendor_Location_Rates_Services_Get 
 (
	  @vendorLocationID INT=NULL 
	, @rateScheduleID INT = NULL
 )
 --DECLARE @vendorLocationID INT = 289
AS
BEGIN 

;WITH wVendorLocationDefaults
AS
(

SELECT 
  p.ID AS ProductID ,   
  p.Name,  
  SUM(CASE WHEN rt.Name = 'Base' THEN   
   (CASE WHEN cpr.Price IS NOT NULL THEN cpr.Price    
    WHEN DefaultVendorRates.RatePrice IS NOT NULL THEN DefaultVendorRates.RatePrice    
    ELSE 0.00     
    END)   
   ELSE 0 END) AS BaseRate  
  ,SUM(CASE WHEN rt.Name = 'Enroute' THEN   
   (CASE WHEN cpr.Price IS NOT NULL THEN cpr.Price    
    WHEN DefaultVendorRates.RatePrice IS NOT NULL THEN DefaultVendorRates.RatePrice    
    ELSE 0.00     
    END)   
   ELSE 0 END) AS EnrouteRate  
  ,SUM(CASE WHEN rt.Name = 'EnrouteFree' THEN   
   (CASE WHEN cpr.Price IS NOT NULL THEN cpr.Quantity    
    WHEN DefaultVendorRates.RatePrice IS NOT NULL THEN DefaultVendorRates.RateQuantity    
    ELSE 0.00     
    END)   
   ELSE 0 END) AS EnrouteFreeMiles  
  ,SUM(CASE WHEN rt.Name = 'Service' THEN   
   (CASE WHEN cpr.Price IS NOT NULL THEN cpr.Price    
    WHEN DefaultVendorRates.RatePrice IS NOT NULL THEN DefaultVendorRates.RatePrice    
    ELSE 0.00     
    END)   
   ELSE 0 END) AS ServiceRate  
  ,SUM(CASE WHEN rt.Name = 'ServiceFree' THEN   
   (CASE WHEN cpr.Price IS NOT NULL THEN cpr.Quantity    
    WHEN DefaultVendorRates.RatePrice IS NOT NULL THEN DefaultVendorRates.RateQuantity    
    ELSE 0.00     
    END)   
   ELSE 0 END) AS ServiceFreeMiles  
  ,SUM(CASE WHEN rt.Name = 'Hourly' THEN   
   (CASE WHEN cpr.Price IS NOT NULL THEN cpr.Price    
    WHEN DefaultVendorRates.RatePrice IS NOT NULL THEN DefaultVendorRates.RatePrice    
    ELSE 0.00     
    END)   
   ELSE 0 END) AS HourlyRate  
   ,ISNULL(GOARate.price,0) AS GoaRate  
   ,0 AS ContractRateScheduleID  
FROM dbo.VendorLocation vl     
JOIN dbo.Vendor v  ON vl.VendorID = v.ID    
JOIN dbo.VendorLocationProduct vlp ON vl.ID = vlp.VendorLocationID AND vlp.IsActive = 1  
JOIN dbo.Product p ON p.ID = vlp.ProductID    
JOIN dbo.ProductRateType prt ON prt.ProductID = p.ID AND prt.IsOptional = 0   
LEFT OUTER JOIN dbo.[Contract] c ON v.ID = c.VendorID and c.IsActive = 'TRUE'    
LEFT OUTER JOIN dbo.ContractProductRate cpr ON vl.ID = cpr.VendorLocationID and cpr.ProductID = vlp.ProductID and cpr.RateTypeID = prt.RateTypeID and c.ID = cpr.ContractID   
LEFT OUTER JOIN dbo.RateType rt ON prt.RateTypeID = rt.ID    
LEFT OUTER JOIN dbo.fnGetDefaultProductRatesByVendor() DefaultVendorRates ON v.ID = DefaultVendorRates.VendorID And p.ID = DefaultVendorRates.ProductID And prt.RateTypeID = DefaultVendorRates.RateTypeID    
LEFT OUTER JOIN (  
      SELECT cpr.VendorLocationID, cpr.ProductID, rt.ID AS ProductRateID, rt.UnitOfMeasure, cpr.Price  
      FROM dbo.ContractProductRate cpr   
      JOIN dbo.[Contract] c ON cpr.ContractID = c.ID AND c.IsActive = 1  
      JOIN dbo.RateType rt ON cpr.RateTypeID = rt.ID AND rt.Name = 'GoneOnArrival'  
      ) GOARate   
      ON GOARate.VendorLocationID = vl.ID AND GOARate.ProductID = vlp.ProductID 
WHERE vl.ID = @vendorLocationID  
GROUP BY p.Name,GOARate.Price ,p.ID
--ORDER BY p.Name
),

-- CRSP

wData
AS
(

SELECT	CRSP.ProductID,
		P.Name AS ProductName,		
		CRSP.Price,
		CRSP.Quantity,
		RT.Name AS RateType,
		CRSP.ContractRateScheduleID
FROM	ContractRateScheduleProduct CRSP
JOIN	Product P ON CRSP.ProductID = P.ID
LEFT JOIN RateType RT ON CRSP.RateTypeID = RT.ID
WHERE	CRSP.ContractRateScheduleID = @rateScheduleID
),
wVendorLocationRates
AS
(
SELECT	ProductID,
		ProductName AS Name, 
		[Base] As [BaseRate], 
		[Enroute] AS [EnrouteRate], 
		[EnrouteFree] AS [EnrouteFreeMiles], 
		[Service] AS [ServiceRate],
		[ServiceFree] AS [ServiceFreeMiles],
		[Hourly] AS [HourlyRate],
		[GoneOnArrival] AS [GoaRate],
		[ContractRateScheduleID] AS ContractRateScheduleID
FROM 

(
	SELECT ProductID, ProductName,RateType, ISNULL(Price,Quantity) As Rate,ContractRateScheduleID FROM wData
) RS
PIVOT
 ( SUM(Rate) FOR RateType IN ( [Base], [Enroute], [EnrouteFree], [GoneOnArrival], [Hourly], [Service], [ServiceFree]))  AS pvt

)

SELECT	ISNULL(VLO.ProductID,VLD.ProductID) AS ProductID,
		ISNULL(VLO.Name,VLD.Name) AS Name,
		ISNULL(VLO.BaseRate,VLD.BaseRate) AS BaseRate,
		ISNULL(VLO.EnrouteRate,VLD.EnrouteRate) AS EnrouteRate,
		ISNULL(VLO.EnrouteFreeMiles,VLD.EnrouteFreeMiles) AS EnrouteFreeMiles,
		ISNULL(VLO.ServiceRate, VLD.ServiceRate) AS ServiceRate,
		ISNULL(VLO.ServiceFreeMiles, VLD.ServiceFreeMiles) AS ServiceFreeMiles,
		ISNULL(VLO.HourlyRate, VLD.HourlyRate) AS HourlyRate,
		ISNULL(VLO.GoaRate, VLD.GoaRate) AS GoaRate,
		ISNULL(VLO.ContractRateScheduleID,VLD.ContractRateScheduleID) AS ContractRateScheduleID
FROM	wVendorLocationDefaults VLD
FULL OUTER JOIN wVendorLocationRates VLO ON VLD.ProductID = VLO.ProductID
ORDER BY VLD.Name 

END
