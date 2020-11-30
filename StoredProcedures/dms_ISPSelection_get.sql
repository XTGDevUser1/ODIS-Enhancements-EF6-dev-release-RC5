IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ISPSelection_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ISPSelection_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO   
-- EXEC [dbo].[dms_ISPSelection_get]  1414,null,1,1,200,0.2,0.4,0.4,0,'Location',NULL
-- EXEC [dbo].[dms_ISPSelection_get]  44022,5,1,1,50,0.4,0.1,0.5,0,'Location'
/* Debug */
--DECLARE 
--    @ServiceRequestID int  = 44022 
--    ,@ActualServiceMiles decimal(10,2)  = 5 
--    ,@VehicleTypeID int  = 1 
--    ,@VehicleCategoryID int  = 1 
--    ,@SearchRadiusMiles int  = 50 
--    ,@AdminWeight decimal(5,2)  = .1 
--    ,@PerformWeight decimal(5,2) = .2  
--    ,@CostWeight decimal(5,2)  = .7 
--    ,@IncludeDoNotUse bit  = 0 
--    ,@SearchFrom nvarchar(50) = 'Location'
--    ,@productIDs NVARCHAR(MAX) = NULL 
      
-- EXEC [dbo].[dms_ISPSelection_get]  1414,null,1,1,200,0.2,0.4,0.4,0,'Location',NULL
-- EXEC [dbo].[dms_ISPSelection_get]  44022,5,1,1,50,0.4,0.1,0.5,0,'Location'
/* Debug */
--DECLARE 
--    @ServiceRequestID int  = 44022 
--    ,@ActualServiceMiles decimal(10,2)  = 5 
--    ,@VehicleTypeID int  = 1 
--    ,@VehicleCategoryID int  = 1 
--    ,@SearchRadiusMiles int  = 50 
--    ,@AdminWeight decimal(5,2)  = .1 
--    ,@PerformWeight decimal(5,2) = .2  
--    ,@CostWeight decimal(5,2)  = .7 
--    ,@IncludeDoNotUse bit  = 0 
--    ,@SearchFrom nvarchar(50) = 'Location'
--    ,@productIDs NVARCHAR(MAX) = NULL 
      
CREATE PROCEDURE [dbo].[dms_ISPSelection_get]  
      @ServiceRequestID int  = NULL 
      ,@ActualServiceMiles decimal(10,2)  = NULL 
      ,@VehicleTypeID int  = NULL 
      ,@VehicleCategoryID int  = NULL 
      ,@SearchRadiusMiles int  = NULL 
      ,@AdminWeight decimal(5,2)  = NULL 
      ,@PerformWeight decimal(5,2) = NULL  
      ,@CostWeight decimal(5,2)  = NULL 
      ,@IncludeDoNotUse bit  = NULL 
      ,@SearchFrom nvarchar(50) = NULL
      ,@productIDs NVARCHAR(MAX) = NULL -- comma separated list of product IDs.
AS  
BEGIN    
  
/* Variable Declarations */  
DECLARE       
      @ServiceLocationLatitude decimal(10,7)   
    ,@ServiceLocationLongitude decimal(10,7)    
    ,@ServiceLocationStateProvince nvarchar(2)  
    ,@ServiceLocationCountryCode nvarchar(10)   
    ,@ServiceLocationPostalCode nvarchar(20)
    ,@DestinationLocationLatitude decimal(10,7)    
    ,@DestinationLocationLongitude decimal(10,7)  
    ,@PrimaryProductID int   
    ,@SecondaryProductID int  
    ,@ProductCategoryID int  
    ,@SecondaryProductCategoryID int  
    ,@MembershipID int  
    ,@ProgramID INT  
    ,@pcAdminWeight decimal(5,2)  = NULL   
      ,@pcPerformWeight decimal(5,2) = NULL    
      ,@pcCostWeight decimal(5,2)  = NULL   
      ,@IsTireDelivery bit  
      ,@LogISPSelection bit  
      ,@LogISPSelectionFinal bit  
  
/* Set Logging On/Off */  
SET @LogISPSelection = 0  
SET @LogISPSelectionFinal = 1  
  
/* Hard-coded radius for Do-Not-Use vendor selection - Should be added to ApplicationConfiguration */  
DECLARE @DNUSearchRadiusMiles int    
SET @DNUSearchRadiusMiles = 50    
  
/* Get Current Time for log inserts */  
DECLARE @now DATETIME = GETDATE()  
  
  
/* Work table declarations *******************************************************/  
SET FMTONLY OFF  
DECLARE @ISPSelection TABLE (  
[VendorID] [int] NOT NULL,  
[VendorLocationID] [int] NOT NULL,  
[VendorLocationVirtualID] [int] NULL,  
[Latitude] [decimal](10, 7) NULL,  
[Longitude] [decimal](10, 7) NULL,  
[VendorName] [nvarchar](255) NULL,  
[VendorNumber] [nvarchar](50) NULL,  
[Source] [varchar](8) NOT NULL,  
[ContractStatus] [nvarchar](50) NOT NULL,  
[Address1] [nvarchar](100) NULL,  
[Address2] [nvarchar](100) NULL,  
[City] [nvarchar](100) NULL,  
[StateProvince] [nvarchar](10) NULL,  
[PostalCode] [nvarchar](20) NULL,  
[CountryCode] [nvarchar](2) NULL,  
[DispatchPhoneNumber] [nvarchar](50) NULL,  
[AlternateDispatchPhoneNumber] [nvarchar](50) NULL, -- TFS: 105
[FaxPhoneNumber] [nvarchar](50) NULL,   
[OfficePhoneNumber] [nvarchar](50) NULL,  
[CellPhoneNumber] [nvarchar](50) NULL, -- CR : 1226  
[AdministrativeRating] [int] NULL,  
[InsuranceStatus] [varchar](11) NOT NULL,  
[BusinessHours] [nvarchar](100) NOT NULL,  
[PaymentTypes] [nvarchar] (100) NULL,    
[Comment] [nvarchar](2000) NULL,  
[ProductID] [int] NOT NULL,  
[ProductName] [nvarchar](50) NULL,  
[ProductRating] [decimal](5, 2) NULL,  
[EnrouteMiles] [float] NULL,  
[EnrouteTimeMinutes] [int] NULL,  
[ServiceMiles] [decimal](10, 2) NULL,  
[ServiceTimeMinutes] [int] NULL,  
[ReturnMiles] [float] NULL,  
[ReturnTimeMinutes] [int] NULL,  
[EstimatedHours] [float] NULL,  
[BaseRate] [money] NULL,  
[HourlyRate] [money] NULL,  
[EnrouteRate] [money] NULL,  
[EnrouteFreeMiles] [int] NULL,  
[ServiceRate] [money] NULL,  
[ServiceFreeMiles] [int] NULL,  
[EstimatedPrice] [float] NULL,  
[WiseScore] [float] NULL,  
[CallStatus] [varchar](9) NOT NULL,  
[RejectReason] [nvarchar](255) NULL,  
[RejectComment] [nvarchar](max) NULL,  
[IsPossibleCallback] [bit] NOT NULL,
[IsPreferred] [int] NULL
)   
  
DECLARE @ISPSelectionFinalResults TABLE (  
[VendorID] [int] NOT NULL,  
[VendorLocationID] [int] NOT NULL,  
[VendorLocationVirtualID] [int] NULL,  
[Latitude] [decimal](10, 7) NULL,  
[Longitude] [decimal](10, 7) NULL,  
[VendorName] [nvarchar](255) NULL,  
[VendorNumber] [nvarchar](50) NULL,  
[Source] [varchar](8) NOT NULL,  
[ContractStatus] [nvarchar](50) NOT NULL,  
[Address1] [nvarchar](100) NULL,  
[Address2] [nvarchar](100) NULL,  
[City] [nvarchar](100) NULL,  
[StateProvince] [nvarchar](10) NULL,  
[PostalCode] [nvarchar](20) NULL,  
[CountryCode] [nvarchar](2) NULL,  
[DispatchPhoneNumber] [nvarchar](50) NULL,  
[AlternateDispatchPhoneNumber] [nvarchar](50) NULL, -- TFS: 105
[FaxPhoneNumber] [nvarchar](50) NULL,   
[OfficePhoneNumber] [nvarchar](50) NULL,  
[CellPhoneNumber] [nvarchar](50) NULL, -- CR : 1226  
[AdministrativeRating] [int] NULL,  
[InsuranceStatus] [varchar](11) NOT NULL,  
[BusinessHours] [nvarchar](100) NOT NULL,  
[PaymentTypes] [nvarchar] (100) NULL,    
[Comment] [nvarchar](2000) NULL,  
[ProductID] [int] NOT NULL,  
[ProductName] [nvarchar](50) NULL,  
[ProductRating] [decimal](5, 2) NULL,  
[EnrouteMiles] [float] NULL,  
[EnrouteTimeMinutes] [int] NULL,  
[ServiceMiles] [decimal](10, 2) NULL,  
[ServiceTimeMinutes] [int] NULL,  
[ReturnMiles] [float] NULL,  
[ReturnTimeMinutes] [int] NULL,  
[EstimatedHours] [float] NULL,  
[BaseRate] [money] NULL,  
[HourlyRate] [money] NULL,  
[EnrouteRate] [money] NULL,  
[EnrouteFreeMiles] [int] NULL,  
[ServiceRate] [money] NULL,  
[ServiceFreeMiles] [int] NULL,  
[EstimatedPrice] [float] NULL,  
[WiseScore] [float] NULL,  
[CallStatus] [varchar](9) NOT NULL,  
[RejectReason] [nvarchar](255) NULL,  
[RejectComment] [nvarchar](max) NULL,  
[IsPossibleCallback] [bit] NOT NULL,  
[AllServices] [NVARCHAR](MAX) NULL,  
[ProductSearchRadiusMiles] [int] NULL,  
[IsInProductSearchRadius] [bit] NULL,
[IsPreferred] [int] NULL  
)  
  
CREATE TABLE #ISPDoNotUse (  
[VendorID] [int] NOT NULL,  
[VendorLocationID] [int] NOT NULL,  
[VendorLocationVirtualID] [int] NULL,  
[Latitude] [decimal](10, 7) NULL,  
[Longitude] [decimal](10, 7) NULL,  
[VendorName] [nvarchar](255) NULL,  
[VendorNumber] [nvarchar](50) NULL,  
[Source] [varchar](8) NOT NULL,  
[ContractStatus] [nvarchar](50) NULL,  
[Address1] [nvarchar](100) NULL,  
[Address2] [nvarchar](100) NULL,  
[City] [nvarchar](100) NULL,  
[StateProvince] [nvarchar](10) NULL,  
[PostalCode] [nvarchar](20) NULL,  
[CountryCode] [nvarchar](2) NULL,  
[DispatchPhoneNumber] [nvarchar](50) NULL,  
[AlternateDispatchPhoneNumber] [nvarchar](50) NULL, -- TFS: 105
[FaxPhoneNumber] [nvarchar](50) NULL,   
[OfficePhoneNumber] [nvarchar](50) NULL,  
[CellPhoneNumber] [nvarchar](50) NULL, -- CR: 1226  
[AdministrativeRating] [int] NULL,  
[InsuranceStatus] [varchar](11) NULL,  
[BusinessHours] [nvarchar](100) NULL,  
[PaymentTypes] [nvarchar] (100) NULL,    
[Comment] [nvarchar](2000) NULL,  
[ProductID] [int] NULL,  
[ProductName] [nvarchar](50) NULL,  
[ProductRating] [decimal](5, 2) NULL,  
[EnrouteMiles] [float] NULL,  
[EnrouteTimeMinutes] [int] NULL,  
[ServiceMiles] [decimal](10, 2) NULL,  
[ServiceTimeMinutes] [int] NULL,  
[ReturnMiles] [float] NULL,  
[ReturnTimeMinutes] [int] NULL,  
[EstimatedHours] [float] NULL,  
[BaseRate] [money] NULL,  
[HourlyRate] [money] NULL,  
[EnrouteRate] [money] NULL,  
[EnrouteFreeMiles] [int] NULL,  
[ServiceRate] [money] NULL,  
[ServiceFreeMiles] [int] NULL,  
[EstimatedPrice] [float] NULL,  
[WiseScore] [float] NULL,  
[CallStatus] [varchar](9) NULL,  
[RejectReason] [nvarchar](255) NULL,  
[RejectComment] [nvarchar](max) NULL,  
[IsPossibleCallback] [bit] NULL  
)   
  
CREATE TABLE #IspDetail (  
[VendorID] [int] NOT NULL,  
[VendorLocationID] [int] NOT NULL,  
[VendorLocationVirtualID] [int] NULL,  
[Latitude] [decimal](10, 7) NULL,  
[Longitude] [decimal](10, 7) NULL,  
[VendorName] [nvarchar](255) NULL,  
[VendorNumber] [nvarchar](50) NULL,  
[Source] [varchar](8) NOT NULL,  
[ContractStatus] [nvarchar](50) NULL,  
[DispatchPhoneNumber] [nvarchar](50) NULL,  
[AlternateDispatchPhoneNumber] [nvarchar](50) NULL, -- TFS: 105
[AdministrativeRating] [int] NULL,  
[InsuranceStatus] [varchar](11) NOT NULL,  
[IsOpen24Hours] [bit] NULL,  
[BusinessHours] [nvarchar](100) NULL,  
--[PaymentTypes] [nvarchar] (100) NULL,    
[Comment] [nvarchar](2000) NULL,  
[EnrouteMiles] [float] NULL,  
[ServiceMiles] [decimal](10, 2) NULL,  
[ReturnMiles] [float] NULL,  
[ProductID] [int] NOT NULL,  
[ProductName] [nvarchar](50) NULL,  
[ProductRating] [decimal](5, 2) NULL,  
[RateTypeID] [int] NULL,  
[RatePrice] [money] NULL,  
[RateQuantity] [int] NULL,  
[RateTypeName] [nvarchar](50) NULL,  
[RateUnitOfMeasure] [nvarchar](50) NULL,  
[RateUnitOfMeasureSource] [nvarchar](50) NULL,  
[IsProductMatch] [int] NOT NULL,
[IsPreferred] [int] NULL  
)   
  
-- Get service information from ServiceRequest  
SELECT         
      @ServiceLocationLatitude = SR.ServiceLocationLatitude,  
    @ServiceLocationLongitude = SR.ServiceLocationLongitude,  
    @ServiceLocationStateProvince = SR.ServiceLocationStateProvince,  
    @ServiceLocationCountryCode = SR.ServiceLocationCountryCode,  
    @ServiceLocationPostalCode = SR.ServiceLocationPostalCode,
    @DestinationLocationLatitude = SR.DestinationLatitude,  
    @DestinationLocationLongitude = SR.DestinationLongitude,  
    @PrimaryProductID = SR.PrimaryProductID,  
    @SecondaryProductID = SR.SecondaryProductID,  
    @ProductCategoryID = SR.ProductCategoryID,  
   @MembershipID = m.MembershipID,  
    @ProgramID = c.ProgramID,
    @VehicleCategoryID = COALESCE(@VehicleCategoryID, SR.VehicleCategoryID)
FROM  ServiceRequest SR  
JOIN [Case] c ON SR.CaseID = c.ID  
JOIN Member m ON c.MemberID = m.ID  
WHERE SR.ID = @ServiceRequestID  
  
SET @SecondaryProductCategoryID = (SELECT ProductCategoryID FROM Product WHERE ID = @SecondaryProductID)  
  
-- Additional condition needed to include tire stores if tire service and tire delivery selected  
SET @IsTireDelivery = ISNULL((SELECT 1 FROM ServiceRequestDetail WHERE @ProductCategoryID = 2 AND ServiceRequestID = @ServiceRequestID AND ProductCategoryQuestionID = 203 AND Answer = 'Tire Delivery'),0)  
  
-- Set program specific ISP scoring weights */  
DECLARE @ProgramConfig TABLE (  
      Name NVARCHAR(50) NULL,  
      Value NVARCHAR(255) NULL  
)  
  
;WITH wProgramConfig   
AS  
(     SELECT ROW_NUMBER() OVER ( PARTITION BY PC.Name ORDER BY PP.Sequence) AS RowNum,  
                  PP.Sequence,  
                  PC.Name,      
                  PC.Value      
      FROM fnc_GetProgramsandParents(@ProgramID) PP  
      JOIN ProgramConfiguration PC ON PP.ProgramID = PC.ProgramID AND PC.IsActive = 1  
      WHERE PC.ConfigurationTypeID = 5   
      AND         PC.ConfigurationCategoryID = 3  
)  
  
INSERT INTO @ProgramConfig  
SELECT      W.Name,  
            W.Value  
FROM  wProgramConfig W  
WHERE W.RowNum = 1  
  
SET @pcAdminWeight = NULL  
SET @pcPerformWeight = NULL  
SET @pcCostWeight = NULL  
SELECT @pcAdminWeight = CONVERT(DECIMAL(5,2),Value) FROM @ProgramConfig WHERE Name = 'DefaultAdminWeighting'  
SELECT @pcPerformWeight = CONVERT(DECIMAL(5,2),Value) FROM @ProgramConfig WHERE Name = 'DefaultPerformanceWeighting'  
SELECT @pcCostWeight = CONVERT(DECIMAL(5,2),Value) FROM @ProgramConfig WHERE Name = 'DefaultCostWeighting'  
  
-- DEBUG : SELECT @pcAdminWeight AS AdminWeight, @pcCostWeight AS CostWeight, @pcPerformWeight AS PerfWeight  
-- If one the values is not defined, then use the values from ApplicationConfiguration.  
-- In other words, if all the three values are found, then override the ones from the app config.  
IF @pcAdminWeight IS NOT NULL AND @pcCostWeight IS NOT NULL AND @pcPerformWeight IS NOT NULL  
BEGIN  
      PRINT 'Using the values from ProgramConfig'  
        
      SET @AdminWeight = @pcAdminWeight  
      SET @CostWeight = @pcCostWeight  
      SET @PerformWeight = @pcPerformWeight  
END  
    
/* Get geography values for service location and towing destination */    
DECLARE @ServiceLocation as geography    
      ,@DestinationLocation as geography    
IF (@ServiceLocationLatitude IS NOT NULL AND @ServiceLocationLongitude IS NOT NULL)  
BEGIN  
    SET @ServiceLocation = geography::Point(@ServiceLocationLatitude, @ServiceLocationLongitude, 4326)    
END  
IF (@DestinationLocationLatitude IS NOT NULL AND @DestinationLocationLongitude IS NOT NULL)  
BEGIN  
    SET @DestinationLocation = geography::Point(@DestinationLocationLatitude, @DestinationLocationLongitude, 4326)    
END  
    
/* Set Service Miles based on service and destination locations - same for all vendors */    
DECLARE @ServiceMiles decimal(10,2)    
IF @ActualServiceMiles IS NOT NULL    
SET @ServiceMiles = @ActualServiceMiles    
ELSE    
SET @ServiceMiles = ROUND(@DestinationLocation.STDistance(@ServiceLocation)/1609.344,0)    
  
/* Get Market product rates according to market location */  
CREATE TABLE #MarketRates (  
[ProductID] [int] NULL,  
[RateTypeID] [int] NULL,  
[Name] [nvarchar](50) NULL,  
[Price] [money] NULL,  
[Quantity] [int] NULL  
)  
  
INSERT INTO #MarketRates  
SELECT ProductID, RateTypeID, Name, RatePrice, RateQuantity  
FROM dbo.fnGetDefaultProductRatesByMarketLocation(@ServiceLocation, @ServiceLocationCountryCode, @ServiceLocationStateProvince)  
  
CREATE CLUSTERED INDEX IDX_MarketRates ON #MarketRates(ProductID, RateTypeID)  
  
/* Get ISP Search Radius increment (bands) based on service and location (metro or rural) */  
DECLARE @IsMetroLocation bit  
DECLARE @ProductSearchRadiusMiles int  
  
/* Determine if service location is within a Metro Market Location radius */  
SET @IsMetroLocation = ISNULL(  
      (SELECT TOP 1 1   
      FROM MarketLocation ml  
      WHERE ml.MarketLocationTypeID = (SELECT ID FROM MarketLocationType WHERE Name = 'Metro')  
      And ml.IsActive = 'TRUE'  
      and ml.GeographyLocation.STDistance(@ServiceLocation) <= ml.RadiusMiles * 1609.344)  
      ,0)  
  
SELECT @ProductSearchRadiusMiles = CASE WHEN @IsMetroLocation = 1 THEN MetroRadius ELSE RuralRadius END   
FROM ProductISPSelectionRadius r  
WHERE ProductID = @PrimaryProductID   
  
IF @ProductSearchRadiusMiles IS NULL   
      SET @ProductSearchRadiusMiles = @SearchRadiusMiles  
  
  
/* Get reference type IDs */    
DECLARE     
            @VendorEntityID int    
            ,@VendorLocationEntityID int    
            ,@ServiceRequestEntityID int    
            ,@BusinessAddressTypeID int    
            ,@DispatchPhoneTypeID int  
			,@AltDispatchPhoneTypeID int 
            ,@FaxPhoneTypeID int  
            ,@OfficePhoneTypeID int    
            ,@CellPhoneTypeID int -- CR : 1226  
            ,@PrimaryServiceProductSubTypeID int    
            ,@ActiveVendorStatusID int  
            ,@DoNotUseVendorStatusID int  
            ,@ActiveVendorLocationStatusID int  
            ,@HeavyDutyVehicleCategoryID int
SET @VendorEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'Vendor')    
SET @VendorLocationEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'VendorLocation')    
SET @ServiceRequestEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'ServiceRequest')    
SET @BusinessAddressTypeID = (SELECT ID FROM dbo.AddressType WHERE Name = 'Business')    
SET @DispatchPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Dispatch') 
SET @AltDispatchPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'AlternateDispatch') -- TFS : 105   
SET @FaxPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Fax')    
SET @OfficePhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Office')    
SET @CellPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Cell')  -- CR: 1226  
SET @PrimaryServiceProductSubTypeID = (Select ID From dbo.ProductSubType Where Name = 'PrimaryService')    
SET @ActiveVendorStatusID = (SELECT ID FROM dbo.VendorStatus WHERE Name = 'Active')    
SET @DoNotUseVendorStatusID = (SELECT ID FROM dbo.VendorStatus WHERE Name = 'DoNotUse')    
SET @ActiveVendorLocationStatusID = (SELECT ID FROM dbo.VendorLocationStatus WHERE Name = 'Active')    
SET @HeavyDutyVehicleCategoryID = (SELECT ID FROM dbo.VehicleCategory WHERE Name = 'HeavyDuty') 
  
    
/* Get list of ALL vendors within the Search Radius of the service location */  
SELECT V.ID VendorID  
      ,vl.ID VendorLocationID  
      ,NULL AS VendorLocationVirtualID  
      ,vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) Distance  
      ,vl.GeographyLocation  
      ,vl.Latitude  
      ,vl.Longitude  
INTO #tmpVendorLocation  
FROM VendorLocation vl  
JOIN Vendor V ON vl.VendorID = V.ID  
WHERE V.IsActive = 1 AND V.VendorStatusID = @ActiveVendorStatusID  
AND vl.IsActive = 1 AND vl.VendorLocationStatusID = @ActiveVendorLocationStatusID  
AND vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) <= @SearchRadiusMiles * 1609.344    
--If using zip codes, only include if zip code is serviced by the vendor location
AND (
	ISNULL(vl.IsUsingZipCodes,0) = 0
	OR
	@ServiceLocationPostalCode IS NULL
	OR
	@ServiceLocationPostalCode = 'null' --Work around for ODIS bug, TFS #456
	OR
	@VehicleCategoryID = @HeavyDutyVehicleCategoryID --Do not use zip code restriction for Heavy Duty services
	OR
	EXISTS(SELECT * FROM VendorLocationPostalCode vlzip
			WHERE vlZip.VendorLocationID = vl.ID AND vlZip.PostalCode = @ServiceLocationPostalCode)
	)
  
-- Include search of related Vendor Location virtual mapping points   
INSERT INTO #tmpVendorLocation  
SELECT V.ID VendorID  
      ,vl.ID VendorLocationID  
      ,vlv.ID VendorLocationVirtualID  
      ,vlv.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) Distance  
      ,vlv.GeographyLocation  
      ,vlv.Latitude  
      ,vlv.Longitude  
FROM VendorLocation vl  
JOIN Vendor V ON vl.VendorID = V.ID  
JOIN VendorLocationVirtual vlv on vlv.VendorLocationID = vl.ID --AND vlv.IsActive = 1  
WHERE V.IsActive = 1 AND V.VendorStatusID = @ActiveVendorStatusID  
AND vl.IsActive = 1 AND vl.VendorLocationStatusID = @ActiveVendorLocationStatusID  
AND vlv.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) <= @SearchRadiusMiles * 1609.344    
--If using zip codes, only include if zip code is serviced by the vendor location
AND (
	ISNULL(vl.IsUsingZipCodes,0) = 0
	--OR --Check for at least one zip code if vendor location configured to use zip codes
	--(ISNULL(vl.IsUsingZipCodes,0) = 1 AND NOT EXISTS(SELECT * FROM VendorLocationPostalCode vlzip
	--		WHERE vlZip.VendorLocationID = vl.ID))
	OR
	EXISTS(SELECT * FROM VendorLocationPostalCode vlzip
			WHERE vlZip.VendorLocationID = vl.ID AND vlZip.PostalCode = @ServiceLocationPostalCode)
	)
  
/* Index physical locations */  
CREATE NONCLUSTERED INDEX [IDX_tmpVendors_VendorLocationID] ON #tmpVendorLocation  
([VendorLocationID] ASC)  
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]  
  
/* Reduce list to only the closest location if the vendor has multiple physical or virtual locations within the Search Radius */  
DELETE #tmpVendorLocation   
FROM #tmpVendorLocation vl1  
WHERE NOT EXISTS (  
      SELECT *  
      FROM #tmpVendorLocation vl2  
      JOIN (  
            SELECT VendorID, MIN(Distance) Distance  
            FROM #tmpVendorLocation   
            GROUP BY VendorID  
            ) ClosestLocation   
            ON ClosestLocation.VendorID = vl2.VendorID and ClosestLocation.Distance = vl2.Distance  
      WHERE vl1.VendorLocationID = vl2.VendorLocationID AND  
            vl1.Distance = vl2.Distance  
      )  

  
/* For the vendor locations within the Search Radius determine vendors that can provide the desired service */  
INSERT INTO #IspDetail   
SELECT     
            v.ID VendorID    
            ,vl.ID VendorLocationID   
            ,tvl.VendorLocationVirtualID   
            ,CASE WHEN tvl.VendorLocationVirtualID IS NOT NULL THEN tvl.Latitude ELSE vl.Latitude END Latitude    
            ,CASE WHEN tvl.VendorLocationVirtualID IS NOT NULL THEN tvl.Longitude ELSE vl.Longitude END Longitude    
            ,v.Name + CASE WHEN PreferredVendors.VendorID IS NOT NULL THEN ' (P)' ELSE '' END VendorName
            ,v.VendorNumber    
            ,CASE WHEN v.VendorNumber IS NULL THEN 'Internet' ELSE '' END AS [Source]  
			,CAST(CASE WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted'     
            ELSE NULL    
            END AS nvarchar(50)) AS ContractStatus 
            ---- Have to check the if the selected product is a contract rate since the vendor can be contracted but not have a rate set for the service (bad data)    
            --,CAST(CASE WHEN VendorLocationRates.Price IS NOT NULL OR DefaultVendorRates.Price IS NOT NULL THEN 'Contracted'     
            --ELSE NULL    
            --END AS nvarchar(50)) AS ContractStatus    
            --,ph.PhoneNumber DispatchPhoneNumber   
		   ,(SELECT Top 1 PhoneNumber  
			FROM dbo.[PhoneEntity]   
			WHERE RecordID = vl.ID   
			AND EntityID = @VendorLocationEntityID  
			AND PhoneTypeID = @DispatchPhoneTypeID  
			ORDER BY ID DESC   
			 ) AS DispatchPhoneNumber
			 ,(SELECT Top 1 PhoneNumber  
			FROM dbo.[PhoneEntity]   
			WHERE RecordID = vl.ID   
			AND EntityID = @VendorLocationEntityID  
			AND PhoneTypeID = @AltDispatchPhoneTypeID  
			ORDER BY ID DESC   
			 ) AS AlternateDispatchPhoneNumber  -- TFS : 105
            ,v.AdministrativeRating   
            -- Ignore time while comparing dates here  
            ,CASE WHEN v.InsuranceExpirationDate >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0) THEN 'Insured'   
            ELSE 'Not Insured' END InsuranceStatus    
            ,vl.[IsOpen24Hours]    
            ,vl.BusinessHours    
            ,vl.DispatchNote AS Comment    
            ,ROUND(tvl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END)/1609.344,1) EnrouteMiles    
            ,@ServiceMiles as ServiceMiles    
            ,ROUND(tvl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' OR @ProductCategoryID <> 1 THEN @ServiceLocation ELSE @DestinationLocation END)/1609.344,1) ReturnMiles    
            ,vlp.ProductID    
            ,p.Name ProductName    
            ,vlp.Rating ProductRating    
            ,prt.RateTypeID     
            ,COALESCE(VendorLocationRates.Price, DefaultVendorRates.Price, MarketRates.Price, 0) AS RatePrice  
            ,COALESCE(VendorLocationRates.Quantity, DefaultVendorRates.Quantity, MarketRates.Quantity, 0) AS RateQuantity  
            --,CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Price    
            --            WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Price    
            --            ELSE MarketRates.Price     
            --END AS RatePrice    
            --,CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Quantity    
            --            WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Quantity    
            --            ELSE MarketRates.Quantity     
            --END AS RateQuantity    
            , rt.Name RateTypeName    
            , rt.UnitOfMeasure RateUnitOfMeasure    
            , rt.UnitOfMeasureSource RateUnitOfMeasureSource    
            ,CASE WHEN p.ID = ISNULL(@PrimaryProductID,0) THEN 1   
                        ELSE 0   
            END IsProductMatch
            ,Case WHEN PreferredVendors.VendorID IS NOT NULL THEN 1 ELSE 0 END IsPreferred
FROM  #tmpVendorLocation tvl  
JOIN  dbo.VendorLocation vl on tvl.VendorLocationID = vl.ID   
JOIN  dbo.Vendor v  ON vl.VendorID = v.ID    
JOIN  dbo.VendorLocationProduct vlp ON vl.ID = vlp.VendorLocationID AND vlp.IsActive = 1  
JOIN  dbo.Product p ON p.ID = vlp.ProductID    
JOIN  dbo.ProductRateType prt ON prt.ProductID = p.ID AND   prt.IsOptional = 0   
JOIN  dbo.RateType rt ON prt.RateTypeID = rt.ID    
LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON
	v.ID = ContractedVendors.VendorID    
LEFT OUTER JOIN dbo.fnGetPreferredVendorsByProduct() PreferredVendors ON
	v.ID = PreferredVendors.VendorID AND p.ID = PreferredVendors.ProductID
LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() VendorLocationRates ON   
      v.ID = VendorLocationRates.VendorID AND   
      p.ID = VendorLocationRates.ProductID AND   
      prt.RateTypeID = VendorLocationRates.RateTypeID AND  
      VendorLocationRates.VendorLocationID = vl.ID   
LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() DefaultVendorRates ON   
      v.ID = DefaultVendorRates.VendorID AND   
      p.ID = DefaultVendorRates.ProductID AND   
      prt.RateTypeID = DefaultVendorRates.RateTypeID AND  
      DeFaultVendorRates.VendorLocationID IS NULL  
LEFT OUTER JOIN #MarketRates MarketRates ON p.ID = MarketRates.ProductID And MarketRates.RateTypeID = prt.RateTypeID 
	--TP: Added condition to prevent backfill of market rates for missing contracted vendor rates 
	AND NOT EXISTS (
		Select * 
		From [dbo].[fnGetCurrentProductRatesByVendorLocation]() r2 
		Where r2.VendorID = v.ID 
			and r2.ProductID = p.ID 
			and r2.RateName IN ('Base','Hourly')
			and r2.Price <> 0) 
    
WHERE   
(VendorLocationRates.RateTypeID IS NOT NULL OR DefaultVendorRates.Price IS NOT NULL OR MarketRates.Price IS NOT NULL)    
AND           
      (  
            (   vlp.ProductID = @PrimaryProductID  
                  AND  
                -- Additional condition to include tire stores if tire service and tire delivery selected  
                  (   
                    @IsTireDelivery = 0  
                    OR  
                    --If Tire delivery then Tire Repair must also have Tire Store Attributes  
                    (@IsTireDelivery = 1    
                              AND EXISTS (  
                              SELECT * FROM VendorLocationProduct vlp1   
                              JOIN Product p1 ON vlp1.ProductID = p1.ID and p1.ProductCategoryID = 2 and p1.ProductSubTypeID = 10  
                              WHERE vlp1.VendorLocationID = vl.ID)  
                    )   
                  )   
            --Additional condition for Mobile Mechanic service  
                  OR  
        (@ProductCategoryID = 8 AND vlp.ProductID IN (SELECT ID FROM Product WHERE ProductCategoryID = 8))  
  
            )  
      AND   
            -- Code to require towing service for possible tow  
            ( @SecondaryProductID IS NULL   
            OR EXISTS (SELECT * FROM VendorLocationProduct vlp2 WHERE vlp2.VendorLocationID = vl.ID and vlp2.ProductID = @SecondaryProductID)  
            )  
      )  
  
  
-- Remove duplicate results for vendorlocations that are caused by multiple product matches   
-- TP: 4/21 Removed previous record deletion logic that was no longer needed and added this logic to fix issue with mobile mechanic vendors appearing multiple times  
DELETE ISPDetail1  
FROM #IspDetail ISPDetail1   
WHERE NOT EXISTS (  
      SELECT *  
      FROM   
            (    
            Select VendorLocationID, Min(ProductID) MinProductID  
            FROM #IspDetail  
            Group by VendorLocationID   
            ) ISPDetail2   
      WHERE ISPDetail1.VendorLocationID = ISPDetail2.VendorLocationID   
            AND ISPDetail1.ProductID  = ISPDetail2.MinProductID  
      )   
  
    
 -- Select list of 'Do Not Use' vendors within the 'Do Not Use' search radius of the service location   
INSERT INTO #ISPDoNotUse   
SELECT      v.ID VendorID    
            ,vl.ID VendorLocationID   
            ,NULL   
            ,vl.Latitude    
            ,vl.Longitude    
            ,v.Name VendorName    
            ,v.VendorNumber    
            ,CASE WHEN v.VendorNumber IS NULL THEN 'Internet'   
                        ELSE 'Database'   
            END AS [Source]    
            ,'Not Contracted' AS ContractStatus    
            ,addr.Line1 Address1    
            ,addr.Line2 Address2    
            ,addr.City    
            ,addr.StateProvince    
            ,addr.PostalCode    
            ,addr.CountryCode    
            ,ph.PhoneNumber DispatchPhoneNumber 
			,aph.PhoneNumber AlternateDispatchPhoneNumber -- TFS : 105   
            ,'' AS FaxPhoneNumber    
            ,'' AS OfficePhoneNumber   
            ,'' AS CellPhoneNumber  -- CR : 1226  
            ,0 AS AdministrativeRating    
            ,'' AS InsuranceStatus    
            ,'' AS BusinessHours    
            ,'' AS PaymentTypes  
            ,'' AS Comment    
            ,0 AS ProductID    
            ,'' AS ProductName    
            ,NULL AS ProductRating    
            ,ROUND(vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END)/1609.344,1) EnrouteMiles    
            ,NULL AS EnrouteTimeMinutes  
            ,NULL AS ServiceMiles    
            ,NULL AS ServiceTimeMinutes  
            ,NULL AS ReturnMiles    
            ,NULL AS ReturnTimeMinutes  
            ,NULL AS EstimatedHours    
            ,NULL AS BaseRate  
            ,NULL AS HourlyRate  
            ,NULL AS EnrouteRate  
            ,NULL AS EnrouteFreeMiles  
            ,NULL AS ServiceRate  
            ,NULL AS ServiceFreeMiles  
            ,NULL AS EstimatedPrice    
            ,-99999 AS WiseScore    
            ,'DoNotUse' AS CallStatus    
            ,'' AS RejectReason    
            ,'' AS RejectComment    
            ,0 AS IsPossibleCallback    
FROM  dbo.VendorLocation vl     
JOIN  dbo.Vendor v ON vl.VendorID = v.ID     
JOIN  dbo.[AddressEntity] addr ON addr.EntityID = @VendorLocationEntityID AND addr.RecordID = vl.ID AND addr.AddressTypeID = @BusinessAddressTypeID    
-- TP - Eliminate join duplication due to multiple dispatch numbers  
JOIN (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @DispatchPhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) ph ON ph.RecordID = vl.ID  
 LEFT JOIN (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @AltDispatchPhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) aph ON aph.RecordID = vl.ID     
WHERE v.IsActive = 'TRUE'    
AND         v.VendorStatusID = @DoNotUseVendorStatusID  
AND         vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) <= @DNUSearchRadiusMiles * 1609.344    
AND         @IncludeDoNotUse = 'TRUE'    
ORDER BY vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END)    
  
-- DEBUG : SELECT * FROM #IspDetail  
  
-- Create ISP Selection data set from ISP Details, adding additional data items and related contact logs   
INSERT INTO @ISPSelection   
SELECT      ISP.VendorID    
            ,ISP.VendorLocationID    
            ,ISP.VendorLocationVirtualID  
            ,ISP.Latitude    
            ,ISP.Longitude    
            ,ISP.VendorName + CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN ' (virtual)' ELSE '' END AS VendorName  
            ,ISP.VendorNumber    
            ,ISP.[Source]    
            ,ISNULL(MAX(ISP.ContractStatus), 'Not Contracted') ContractStatus    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationAddress ELSE addr.Line1 END Address1    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN NULL ELSE addr.Line2 END Address2    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationCity ELSE addr.City END City    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationStateProvince ELSE addr.StateProvince END StateProvince    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationPostalCode ELSE addr.PostalCode END PostalCode    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationCountryCode ELSE addr.CountryCode END CountryCode    
            ,ISP.DispatchPhoneNumber
			,ISP.AlternateDispatchPhoneNumber -- TFS: 105   
            ,FaxPh.PhoneNumber FaxPhoneNumber  
            ,ph.PhoneNumber OfficePhoneNumber  
            ,cph.PhoneNumber CellPhoneNumber --  CR : 1226  
            ,ISP.AdministrativeRating    
            ,ISP.InsuranceStatus    
            ,CASE WHEN ISP.[IsOpen24Hours] = 1 THEN '24/7'   
            ELSE ISNULL(ISP.BusinessHours,'') END AS BusinessHours    
            ,PaymentTypes.List AS PaymentTypes  
            ,ISP.Comment    
            ,ISP.ProductID    
            ,ISP.ProductName    
            ,ISP.ProductRating    
            ,ISP.EnrouteMiles    
            ,(ISP.EnrouteMiles/40)*60 AS EnrouteTimeMinutes  
            ,ISP.ServiceMiles    
            ,(ISP.ServiceMiles/40)*60 AS ServiceTimeMinutes  
            ,ISP.ReturnMiles    
            ,(ISP.ReturnMiles/40)*60 AS ReturnTimeMinutes  
            ,MAX(1.5 + ROUND((ISP.EnrouteMiles + ISP.ServiceMiles + ISP.ReturnMiles)/40,2)) AS EstimatedHours    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Base' THEN ISP.RatePrice ELSE 0 END) AS BaseRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Hourly' THEN ISP.RatePrice ELSE 0 END) AS HourlyRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Enroute' THEN ISP.RatePrice ELSE 0 END) AS EnrouteRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'EnrouteFree' THEN ISP.RateQuantity ELSE 0 END) AS EnrouteFreeMiles    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Service' THEN ISP.RatePrice ELSE 0 END) AS ServiceRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'ServiceFree' THEN ISP.RateQuantity ELSE 0 END) AS ServiceFreeMiles    
            ,ROUND(SUM(CASE     
                                    WHEN ISP.RateUnitOfMeasure = 'Each' THEN ISP.RatePrice     
                                    WHEN ISP.RateUnitOfMeasure = 'Hour' THEN ISP.RatePrice * (1.5 + ROUND((ISNULL(ISP.EnrouteMiles,0.0) + ISNULL(ISP.ServiceMiles,0.0) + ISNULL(ISP.ReturnMiles,0.0))/40,2))    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity = 0 THEN ISP.RatePrice * ISP.EnrouteMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity = 0 THEN ISP.RatePrice * ISP.ServiceMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.EnrouteMiles THEN ISP.EnrouteMiles ELSE ISP.RateQuantity END)
    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.ServiceMiles THEN ISP.ServiceMiles ELSE ISP.RateQuantity END) 
   
                                    ELSE 0   
                              END),2) EstimatedPrice    
            ,ROUND((AdministrativeRating*@AdminWeight)+(ProductRating*@PerformWeight)-    
                        (SUM(CASE     
                                    WHEN ISP.RateUnitOfMeasure = 'Each' THEN ISP.RatePrice     
                                    WHEN ISP.RateUnitOfMeasure = 'Hour' THEN ISP.RatePrice * (1.5 + ROUND((ISNULL(ISP.EnrouteMiles,0.0) + ISNULL(ISP.ServiceMiles,0.0) + ISNULL(ISP.ReturnMiles,0.0))/40,2))    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity = 0 THEN ISP.RatePrice * ISP.EnrouteMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity = 0 THEN ISP.RatePrice * ISP.ServiceMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.EnrouteMiles THEN ISP.EnrouteMiles ELSE ISP.RateQuantity END) 
   
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.ServiceMiles THEN ISP.ServiceMiles ELSE ISP.RateQuantity END) 
   
                                    ELSE 0   
                              END) * @CostWeight),2) as WiseScore    
            ,CASE WHEN ContactLogAction.VendorLocationID IS NULL THEN 'NotCalled'    
                        WHEN ISNULL(ContactLogAction.Name,'') = '' THEN 'Called'    
                        WHEN ISNULL(ContactLogAction.Name,'') = 'Accepted' THEN 'Accepted'    
                        ELSE 'Rejected'   
            END AS CallStatus    
            ,ContactLogAction.[Description] RejectReason    
            ,ContactLogAction.[Comments] RejectComment    
            ,ISNULL(ContactLogAction.IsPossibleCallback,0) AS IsPossibleCallback    
            ,MAX(ISP.IsPreferred) IsPreferred
FROM  #IspDetail ISP    
LEFT OUTER JOIN  dbo.[VendorLocationVirtual] vlv ON vlv.ID = ISP.VendorLocationVirtualID  
LEFT OUTER JOIN  dbo.[AddressEntity] addr ON addr.EntityID = @VendorLocationEntityID AND addr.RecordID = ISP.VendorLocationID AND addr.AddressTypeID = @BusinessAddressTypeID    
-- TP - Eliminate join duplication due to multiple Fax numbers  
LEFT OUTER JOIN  (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @FaxPhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) Faxph ON Faxph.RecordID = ISP.VendorLocationID     
-- TP - Eliminate join duplication due to multiple Office numbers  
LEFT OUTER JOIN  (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @OfficePhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) ph ON ph.RecordID = ISP.VendorLocationID     
-- TP - Eliminate join duplication due to multiple Cell numbers  
LEFT OUTER JOIN  (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @CellPhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) cph ON cph.RecordID = ISP.VendorLocationID     
-- Get last ContactLog result for the current sevice request for the ISP  
LEFT OUTER JOIN (    
                              SELECT      LastISPContactLog.VendorLocationID    
                                          ,LastContactLogAction.Name    
                                          ,LastContactLogAction.[Description]    
                                          ,cl.Comments    
                                          ,ISNULL(cl.IsPossibleCallback,0) IsPossibleCallback    
                              FROM  dbo.ContactLog cl    
                              JOIN (  
                                          SELECT      ISPcll.RecordID VendorLocationID, MAX(cl.ID) ID   
                                          FROM  dbo.ContactLog cl    
                                          JOIN  dbo.ContactLogLink SRcll ON SRcll.ContactLogID = cl.ID AND SRcll.EntityID = @ServiceRequestEntityID AND SRcll.RecordID = @ServiceRequestID     
                                          JOIN dbo.ContactLogLink ISPcll ON ISPcll.ContactLogID = cl.ID AND ISPcll.EntityID = @VendorLocationEntityID    
                                          JOIN dbo.ContactLogReason clr ON clr.ContactLogID = cl.ID    
                                          JOIN dbo.ContactReason cr ON cr.ID = clr.ContactReasonID    
                                          WHERE cr.Name = 'ISP selection'    
                                          GROUP BY ISPcll.RecordID  
                                    ) LastISPContactLog ON LastISPContactLog.ID = cl.ID  
                              LEFT OUTER JOIN (    
                                          SELECT      cla.ContactLogID  
                                                      ,ca.Name  
                                                      ,ca.[Description]  
                                                      ,cla.Comments    
                                          FROM  dbo.ContactLogAction cla    
                                          JOIN  dbo.ContactAction ca ON ca.ID = cla.ContactActionID    
                                          JOIN  (    
                                                            SELECT      cla1.ContactLogID, MAX(cla1.ID) ID    
                                                            FROM      dbo.ContactLogAction cla1    
                                                            GROUP BY cla1.ContactLogID    
                                                      ) MaxContactLogAction ON MaxContactLogAction.ContactLogID = cla.ContactLogID AND MaxContactLogAction.ID = cla.ID    
                                    ) LastContactLogAction ON LastContactLogAction.ContactLogID = cl.ID   
                        ) ContactLogAction ON ContactLogAction.VendorLocationID = ISP.VendorLocationID    
-- Get Payment Types accepted by this vendor                        
LEFT OUTER JOIN (    
      SELECT  
         pt1.VendorLocationID,  
         List = stuff((SELECT ( ', ' + [Description] )  
                    FROM (Select vlpt.VendorLocationID, pt.Name, pt.Sequence, pt.[Description]   
                              From VendorLocationPaymentType vlpt  
                              Join PaymentType pt on vlpt.PaymentTypeID = pt.ID  
                              ) pt2  
                    WHERE pt1.VendorLocationID = pt2.VendorLocationID  
                    ORDER BY VendorLocationID, pt2.Sequence  
                        FOR XML PATH( '' )  
                  ), 1, 1, '' )  
                  FROM   
                        (Select vlpt.VendorLocationID, pt.Name  
                        From VendorLocationPaymentType vlpt  
                        Join #IspDetail ISP on ISP.VendorLocationID = vlpt.VendorLocationID  
                        Join PaymentType pt on vlpt.PaymentTypeID = pt.ID  
                        ) pt1  
      GROUP BY pt1.VendorLocationID  
      ) PaymentTypes ON PaymentTypes.VendorLocationID = ISP.VendorLocationID  
GROUP BY    
                  ISP.VendorID    
                  ,ISP.VendorLocationID    
                  ,ISP.VendorLocationVirtualID  
                  ,ISP.Latitude    
                  ,ISP.Longitude    
                  ,ISP.VendorName    
                  ,ISP.VendorNumber    
                  ,ISP.[Source]    
                  ,addr.Line1     
                  ,addr.Line2     
                  ,addr.City    
                  ,addr.StateProvince    
                  ,addr.PostalCode    
                  ,addr.CountryCode    
                  ,vlv.LocationAddress  
                  ,vlv.LocationCity    
                  ,vlv.LocationStateProvince    
                  ,vlv.LocationPostalCode    
                  ,vlv.LocationCountryCode    
                  ,ISP.DispatchPhoneNumber 
				  ,ISP.AlternateDispatchPhoneNumber   -- TFS: 105
                  ,Faxph.PhoneNumber  
                  ,ph.PhoneNumber   
                  ,cph.PhoneNumber   
                  ,ISP.AdministrativeRating    
                  ,ISP.InsuranceStatus    
                  ,ISP.[IsOpen24Hours]    
                  ,ISP.BusinessHours    
                  ,ISP.Comment    
                  ,ISP.ProductID    
                  ,ISP.ProductName    
                  ,ISP.ProductRating    
                  ,ISP.EnrouteMiles    
                  ,ISP.ServiceMiles    
                  ,ISP.ReturnMiles    
                  ,ISP.IsProductMatch    
                  ,ContactLogAction.VendorLocationID    
                  ,ContactLogAction.[Description]     
                  ,ContactLogAction.Comments     
                  ,ISNULL(ContactLogAction.Name ,'')  
                  ,ContactLogAction.IsPossibleCallback    
                  ,PaymentTypes.List  
ORDER BY   
                  WiseScore DESC  
                  ,EstimatedPrice  
                  ,EnrouteMiles  
                  ,ProductRating DESC    
   
 -- Log ISP SELECTION Results (first resultset).  
INSERT INTO ISPSelectionLog  
            ([VendorID]  
           ,[VendorLocationID]  
           ,[VendorLocationVirtualID]  
           ,[SelectionOrder]  
           ,[ServiceRadiusMiles]  
           ,[Latitude]  
           ,[Longitude]  
           ,[VendorName]  
           ,[VendorNumber]  
           ,[Source]  
           ,[ContractStatus]  
           ,[Address1]  
           ,[Address2]  
           ,[City]  
           ,[StateProvince]  
           ,[PostalCode]  
           ,[CountryCode]  
           ,[DispatchPhoneNumber]
		   ,[AlternateDispatchPhoneNumber] -- TFS: 105  
           ,[FaxPhoneNumber]  
           ,[OfficePhoneNumber]  
           ,[CellPhoneNumber]  
           ,[AdministrativeRating]  
           ,[InsuranceStatus]  
           ,[BusinessHours]  
           ,[PaymentTypes]  
           ,[Comment]  
           ,[ProductID]  
           ,[ProductName]  
           ,[ProductRating]  
           ,[EnrouteMiles]  
           ,[EnrouteTimeMinutes]  
           ,[ServiceMiles]  
           ,[ServiceTimeMinutes]  
           ,[ReturnMiles]  
           ,[ReturnTimeMinutes]  
           ,[EstimatedHours]  
           ,[BaseRate]  
           ,[HourlyRate]  
           ,[EnrouteRate]  
           ,[EnrouteFreeMiles]  
           ,[ServiceRate]  
           ,[ServiceFreeMiles]  
           ,[EstimatedPrice]  
           ,[WiseScore]  
           ,[CallStatus]  
           ,[RejectReason]  
           ,[RejectComment]  
           ,[IsPossibleCallback]  
           ,[ProductSearchRadiusMiles]  
           ,[IsInProductSearchRadius]  
           ,[ServiceRequestID]  
           ,[LogTime]  
           ,[Resultset])  
SELECT   
            VendorID    
            ,VendorLocationID    
            ,VendorLocationVirtualID  
            ,row_number() OVER(ORDER BY WiseScore DESC  
                  ,EstimatedPrice  
                  ,EnrouteMiles  
                  ,ProductRating DESC) AS SelectionOrder  
            ,@ProductSearchRadiusMiles  
            ,Latitude    
            ,Longitude    
            ,VendorName    
            ,VendorNumber    
            ,[Source]    
            ,ContractStatus    
            ,Address1    
            ,Address2    
            ,City    
            ,StateProvince    
            ,PostalCode    
            ,CountryCode    
            ,DispatchPhoneNumber   
			,AlternateDispatchPhoneNumber -- TFS: 105 
            ,FaxPhoneNumber  
            ,OfficePhoneNumber    
            ,CellPhoneNumber  
            ,AdministrativeRating    
            ,InsuranceStatus    
            ,BusinessHours    
            ,PaymentTypes  
            ,Comment    
            ,ProductID    
            ,ProductName    
            ,ProductRating    
            ,EnrouteMiles    
            ,EnrouteTimeMinutes  
            ,ServiceMiles  
            ,ServiceTimeMinutes  
            ,ReturnMiles    
            ,ReturnTimeMinutes  
            ,EstimatedHours    
            ,BaseRate  
            ,HourlyRate  
            ,EnrouteRate  
            ,EnrouteFreeMiles  
            ,ServiceRate  
            ,ServiceFreeMiles  
            ,EstimatedPrice    
            ,WiseScore    
            ,CallStatus    
			,RejectReason    
            ,RejectComment    
            ,IsPossibleCallback  
            ,@ProductSearchRadiusMiles AS ProductSearchRadiusMiles  
            ,NULL AS IsInProductSearchRadius  
            ,@ServiceRequestID  
            ,@now  
            ,'ISPSELECTION'    
 FROM @ISPSelection   
 WHERE @LogISPSelection = 1  
  
   
-- Combine ISP Selection and ISP Do Not use results     
-- Collect products in a separate query   
INSERT INTO @ISPSelectionFinalResults    
SELECT      TOP 50    
            I.VendorID    
            ,I.VendorLocationID    
            ,VendorLocationVirtualID  
            ,Latitude    
            ,Longitude    
            ,VendorName    
            ,VendorNumber    
            ,[Source]    
            ,ContractStatus    
            ,Address1    
            ,Address2    
            ,City    
            ,StateProvince    
            ,PostalCode    
            ,CountryCode    
            ,DispatchPhoneNumber  
			,AlternateDispatchPhoneNumber -- TFS: 105  
            ,FaxPhoneNumber  
            ,OfficePhoneNumber    
            ,CellPhoneNumber  
            ,AdministrativeRating    
            ,InsuranceStatus    
            ,BusinessHours    
            ,PaymentTypes  
            ,Comment    
            ,ProductID    
            ,ProductName    
            ,ProductRating    
            ,EnrouteMiles    
            ,EnrouteTimeMinutes  
            ,ServiceMiles  
            ,ServiceTimeMinutes  
            ,ReturnMiles    
            ,ReturnTimeMinutes  
            ,EstimatedHours    
            ,BaseRate  
            ,HourlyRate  
            ,EnrouteRate  
            ,EnrouteFreeMiles  
            ,ServiceRate  
            ,ServiceFreeMiles  
            ,EstimatedPrice    
            ,WiseScore    
            ,CallStatus    
            ,RejectReason    
            ,RejectComment    
            ,IsPossibleCallback  
            ,'' AS [AllServices]  
            ,@ProductSearchRadiusMiles AS ProductSearchRadiusMiles  
            ,CASE WHEN (I.EnrouteMiles <= @ProductSearchRadiusMiles) OR Top3Contracted.VendorLocationID IS NOT NULL THEN 1 ELSE 0 END AS IsInProductSearchRadius   
            ,IsPreferred
FROM  @ISPSelection I  
-- Identify top 3 contracted vendors  
LEFT OUTER JOIN (  
      SELECT TOP 3 VendorLocationID  
      FROM @ISPSelection  
      WHERE ContractStatus = 'Contracted'  
      ORDER BY EnrouteMiles ASC, WiseScore DESC  
      ) Top3Contracted ON Top3Contracted.VendorLocationID = I.VendorLocationID  
-- Apply product availability filtering (@ProductIDs list)  
WHERE EXISTS      (  
                              SELECT      *  
                              FROM  VendorLocation vl  
                              JOIN  VendorLocationProduct vlp   
                              ON          vlp.VendorLocationID = vl.ID  
                              JOIN  Product p on p.ID = vlp.ProductID   
                              WHERE vl.ID = I.VendorLocationID  
                              AND         (     ISNULL(@productIDs,'') = ''   
                                                OR    
                                                p.ID IN (SELECT item from [dbo].[fnSplitString](@productIDs,','))  
                                          )  
                        )  
  
ORDER BY IsPreferred DESC, WiseScore DESC, EstimatedPrice, EnrouteMiles, ProductRating DESC    
  
/* Add 'Do Not Use' vendors to the results (if selected above) */  
INSERT INTO @ISPSelectionFinalResults  
SELECT      TOP 100    
            I.VendorID    
            ,VendorLocationID    
            ,VendorLocationVirtualID  
            ,Latitude    
            ,Longitude    
            ,VendorName    
            ,VendorNumber    
            ,[Source]    
            ,ContractStatus    
            ,Address1    
            ,Address2    
            ,City    
            ,StateProvince    
            ,PostalCode    
            ,CountryCode    
            ,DispatchPhoneNumber  
			,AlternateDispatchPhoneNumber -- TFS: 105  
            ,FaxPhoneNumber  
            ,OfficePhoneNumber    
            ,CellPhoneNumber  
            ,AdministrativeRating    
            ,InsuranceStatus    
            ,BusinessHours    
            ,PaymentTypes  
            ,Comment    
            ,ProductID    
            ,ProductName    
            ,ProductRating    
            ,EnrouteMiles    
            ,EnrouteTimeMinutes  
            ,ServiceTimeMinutes  
            ,ReturnMiles    
            ,ReturnTimeMinutes  
            ,EstimatedHours    
            ,BaseRate  
            ,HourlyRate  
            ,EnrouteRate  
            ,EnrouteFreeMiles  
            ,ServiceRate  
            ,ServiceMiles  
            ,ServiceFreeMiles  
            ,EstimatedPrice    
            ,WiseScore    
            ,CallStatus    
            ,RejectReason    
            ,RejectComment    
            ,IsPossibleCallback  
            , '' AS [AllServices]   
            ,@ProductSearchRadiusMiles AS ProductSearchRadiusMiles  
            ,0 AS IsInProductSearchRadius  
            ,0 AS IsPreferred
FROM  #ISPDoNotUse I  
ORDER BY WiseScore DESC, EstimatedPrice, EnrouteMiles, ProductRating DESC    
   
-- Get all the products for the vendors collected in the above query.  
;WITH wVLP  
AS  
(  
      SELECT      vl.VendorID,  
                  vl.ID,   
                  [dbo].[fnConcatenate](p.Name) AS AllServices  
      FROM  VendorLocation vl  
      JOIN  VendorLocationProduct vlp on vlp.VendorLocationID = vl.ID  
      JOIN  Product p on p.ID = vlp.ProductID  
      JOIN  @ISPSelectionFinalResults ISP ON vl.ID = ISP.VendorLocationID AND vl.VendorID = ISP.VendorID  
      WHERE vlp.IsActive = 1  
      GROUP BY vl.VendorID,vl.ID  
)  
  
 -- Include 'All Services' provided by the selected ISPs in the results  
UPDATE      @ISPSelectionFinalResults  
SET         AllServices = W.AllServices  
FROM  wVLP W,  
            @ISPSelectionFinalResults ISP  
WHERE W.VendorID = ISP.VendorID  
AND         W.ID = VendorLocationID  
  
-- Remove Black Listed vendors from the result for this member  
DELETE FROM @ISPSelectionFinalResults  
WHERE VendorID IN (  
                                    SELECT VendorID  
                                    FROM MembershipBlackListVendor  
                                    WHERE MembershipID = @MembershipID  
                              )  
  
/* Insert reults into ISP Selection log */  
INSERT INTO ISPSelectionLog  
            ([VendorID]  
           ,[VendorLocationID]  
           ,[VendorLocationVirtualID]  
           ,[SelectionOrder]  
           ,[ServiceRadiusMiles]  
           ,[Latitude]  
           ,[Longitude]  
           ,[VendorName]  
           ,[VendorNumber]  
           ,[Source]  
           ,[ContractStatus]  
           ,[Address1]  
           ,[Address2]  
           ,[City]  
           ,[StateProvince]  
           ,[PostalCode]  
           ,[CountryCode]  
           ,[DispatchPhoneNumber]
		   ,[AlternateDispatchPhoneNumber] -- TFS: 105  
           ,[FaxPhoneNumber]  
           ,[OfficePhoneNumber]  
           ,[CellPhoneNumber]  
           ,[AdministrativeRating]  
           ,[InsuranceStatus]  
           ,[BusinessHours]  
           ,[PaymentTypes]  
           ,[Comment]  
           ,[ProductID]  
           ,[ProductName]  
           ,[ProductRating]  
           ,[EnrouteMiles]  
           ,[EnrouteTimeMinutes]  
           ,[ServiceMiles]  
           ,[ServiceTimeMinutes]  
           ,[ReturnMiles]  
           ,[ReturnTimeMinutes]  
           ,[EstimatedHours]  
           ,[BaseRate]  
           ,[HourlyRate]  
           ,[EnrouteRate]  
           ,[EnrouteFreeMiles]  
           ,[ServiceRate]  
           ,[ServiceFreeMiles]  
           ,[EstimatedPrice]  
           ,[WiseScore]  
           ,[CallStatus]  
           ,[RejectReason]  
           ,[RejectComment]  
           ,[IsPossibleCallback]  
           ,[ProductSearchRadiusMiles]  
           ,[IsInProductSearchRadius]  
           ,[ServiceRequestID]  
           ,[LogTime]  
           ,[Resultset])  
SELECT ISP.VendorID    
            ,ISP.VendorLocationID   
            ,ISP.VendorLocationVirtualID   
            ,row_number() OVER(ORDER BY   
                  ISP.IsInProductSearchRadius DESC,  
                  ISP.WiseScore DESC,   
    ISP.EstimatedPrice,   
                  ISP.EnrouteMiles,   
                  ISP.ProductRating DESC) AS SelectionOrder  
            ,@ProductSearchRadiusMiles  
            ,Latitude    
            ,Longitude    
            ,VendorName    
            ,VendorNumber    
            ,[Source]    
            ,ContractStatus    
            ,Address1    
            ,Address2    
            ,City    
            ,StateProvince    
            ,PostalCode    
            ,CountryCode    
            ,DispatchPhoneNumber
			,AlternateDispatchPhoneNumber -- TFS: 105    
            ,FaxPhoneNumber  
            ,OfficePhoneNumber    
            ,CellPhoneNumber  
            ,AdministrativeRating    
            ,InsuranceStatus    
            ,BusinessHours    
            ,PaymentTypes  
            ,Comment    
            ,ProductID    
            ,ProductName    
            ,ProductRating    
            ,EnrouteMiles    
            ,EnrouteTimeMinutes  
            ,ServiceMiles  
            ,ServiceTimeMinutes  
            ,ReturnMiles    
            ,ReturnTimeMinutes  
            ,EstimatedHours    
            ,BaseRate  
            ,HourlyRate  
            ,EnrouteRate  
            ,EnrouteFreeMiles  
            ,ServiceRate  
            ,ServiceFreeMiles  
            ,EstimatedPrice    
            ,WiseScore    
            ,CallStatus    
            ,RejectReason    
            ,RejectComment    
            ,IsPossibleCallback  
            ,ProductSearchRadiusMiles  
            ,IsInProductSearchRadius  
            ,@ServiceRequestID  
            ,@now  
            ,'ISPSELECTION_FINAL'    
FROM @ISPSelectionFinalResults ISP  
WHERE @LogISPSelectionFinal = 1  
ORDER BY   
	  ISP.IsPreferred DESC,   
      ISP.IsInProductSearchRadius DESC,  
      ISP.WiseScore DESC,   
      ISP.EstimatedPrice,   
      ISP.EnrouteMiles,   
      ISP.ProductRating DESC   
  
/* Return results */  
SELECT      ISP.*   
FROM  @ISPSelectionFinalResults ISP  
ORDER BY      
	  ISP.IsPreferred DESC,
      ISP.IsInProductSearchRadius DESC,  
      ISP.WiseScore DESC,   
      ISP.EstimatedPrice,   
      ISP.EnrouteMiles,   
      ISP.ProductRating DESC   
  
DROP TABLE #IspDoNotUse  
DROP TABLE #IspDetail  
DROP TABLE #tmpVendorLocation  
DROP TABLE #MarketRates  
  
END
GO

