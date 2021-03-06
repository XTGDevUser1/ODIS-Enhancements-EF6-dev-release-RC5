IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Dashboard_DispatchChart]')   		AND type in (N'P', N'PC')) 
BEGIN
 DROP PROCEDURE [dbo].[dms_Dashboard_DispatchChart] 
END 
GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[dms_Dashboard_DispatchChart]
AS
BEGIN
DECLARE @startDate AS DATE 
SET @startDate = DATEADD(m,-11,GETDATE())
DECLARE @EndDate AS DATE = DATEADD(d,1,GETDATE())


--====================================================================================================================
-- Service Request Count
--
--
-- 1. Setup Stored Procedure to drive chart.... convert to cross-tab query
-- 2. Setup chart on Dashboard for Dispatch
-- 3. Use line chart
-- 4. Title = Serivce Request Count
-- 5. Vertical Axis = service request counts:  0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000
-- 6. Horizontal Axis = NMC, Ford, Hagerty, Others
-- 7. Show Jan to Dec


-- Line Graph

-- Show monthly totals of call counts by clients

-- Set 

--82559
DECLARE @Result AS TABLE(
Client NVARCHAR(50),
Month1 INT,
Month2 INT,
Month3 INT,
Month4 INT,
Month5 INT,
Month6 INT,
Month7 INT,
Month8 INT,
Month9 INT,
Month10 INT,
Month11 INT,
Month12 INT
)

INSERT INTO @Result(Client,Month1,Month2,Month3,Month4,Month5,Month6,Month7,Month8,Month9,Month10,Month11,Month12)

SELECT 
	CASE  
		WHEN cl.Name = 'Coach-Net' THEN 'Coach-Net'
		WHEN cl.Name = 'National Motor Club' THEN 'NMC'
		WHEN cl.Name = 'Ford' Then 'Ford'
		WHEN cl.Name = 'Hagerty' Then 'Hagerty'
		ELSE 'Other'
	  END as Client
	--, datepart(mm,sr.CreateDate) AS 'Month'
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,@startDate) THEN count(sr.id)
	  END,0) AS Jan
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,1,@startDate))) THEN count(sr.id)
	  END,0) as Feb
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,2,@startDate))) THEN count(sr.id)
	  END,0) as Mar
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,3,@startDate))) THEN count(sr.id)
	  END,0) as Apr
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,4,@startDate))) THEN count(sr.id)
	  END,0) as May
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,5,@startDate))) THEN count(sr.id)
	  END,0) as Jun
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,6,@startDate))) THEN count(sr.id)
	  END,0) AS Jul
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,7,@startDate))) THEN count(sr.id)
	  END,0) as Aug
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,8,@startDate))) THEN count(sr.id)
	  END,0) as Sep
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,9,@startDate))) THEN count(sr.id)
	  END,0) as Oct
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,10,@startDate))) THEN count(sr.id)
	  END,0) as Nov
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,11,@startDate))) THEN count(sr.id)
	  END,0) as Dec
FROM ServiceRequest sr
JOIN ServiceRequestStatus srs ON srs.ID = sr.ServiceRequestStatusID
JOIN [Case] c ON c.ID = sr.CaseID
JOIN Program p on p.ID = c.ProgramID
--JOIN Program pp on p.ParentProgramID IS NULL OR pp.ID = p.ParentProgramID
JOIN Client cl on cl.ID = p.ClientID
WHERE
	sr.CreateDate between @StartDate and @EndDate
	AND sr.ServiceRequestStatusID IN (SELECT ID FROM ServiceRequestStatus WHERE Name IN ('Complete','Cancelled'))
GROUP BY
		CASE
		WHEN cl.Name = 'Coach-Net' THEN 'Coach-Net'
		WHEN cl.Name = 'National Motor Club' THEN 'NMC'
		WHEN cl.Name = 'Ford' Then 'Ford'
		WHEN cl.Name = 'Hagerty' Then 'Hagerty'
		ELSE 'Other'
	  END
	  , datepart(mm,sr.createdate)
ORDER BY
	CASE
		WHEN cl.Name = 'Coach-Net' THEN 'Coach-Net'
		WHEN cl.Name = 'National Motor Club' THEN 'NMC'
		WHEN cl.Name = 'Ford' Then 'Ford'
		WHEN cl.Name = 'Hagerty' Then 'Hagerty'
		ELSE 'Other'
	END 
	, datepart(mm,sr.CreateDate)
	
SELECT Client,
	  SUM(Month1) AS 'Month1',
	  SUM(Month2) AS 'Month2',
	  SUM(Month3) AS 'Month3' ,
	  SUM(Month4) AS 'Month4' ,
	  SUM(Month5) AS 'Month5' ,
	  SUM(Month6) AS 'Month6' ,
	  SUM(Month7) AS 'Month7' ,
	  SUM(Month8) AS 'Month8' ,
	  SUM(Month9) AS 'Month9' ,
	  SUM(Month10) AS 'Month10' ,
	  SUM(Month11) AS 'Month11' ,
	  SUM(Month12) AS 'Month12' 
FROM @Result
GROUP BY Client
END

GO
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
[IsPossibleCallback] [bit] NOT NULL  
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
[IsInProductSearchRadius] [bit] NULL  
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
[IsProductMatch] [int] NOT NULL  
)   
  
-- Get service information from ServiceRequest  
SELECT         
      @ServiceLocationLatitude = SR.ServiceLocationLatitude,  
    @ServiceLocationLongitude = SR.ServiceLocationLongitude,  
    @ServiceLocationStateProvince = SR.ServiceLocationStateProvince,  
    @ServiceLocationCountryCode = SR.ServiceLocationCountryCode,  
    @DestinationLocationLatitude = SR.DestinationLatitude,  
    @DestinationLocationLongitude = SR.DestinationLongitude,  
    @PrimaryProductID = SR.PrimaryProductID,  
    @SecondaryProductID = SR.SecondaryProductID,  
    @ProductCategoryID = SR.ProductCategoryID,  
   @MembershipID = m.MembershipID,  
    @ProgramID = c.ProgramID  
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
            ,v.Name VendorName    
            ,v.VendorNumber    
            ,CASE WHEN v.VendorNumber IS NULL THEN 'Internet' ELSE '' END AS [Source]  
            -- Have to check the if the selected product is a contract rate since the vendor can be contracted but not have a rate set for the service (bad data)    
            ,CAST(CASE WHEN VendorLocationRates.Price IS NOT NULL OR DefaultVendorRates.Price IS NOT NULL THEN 'Contracted'     
            ELSE NULL    
            END AS nvarchar(50)) AS ContractStatus    
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
            ,CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Price    
                        WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Price    
                        ELSE MarketRates.Price     
            END AS RatePrice    
            ,CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Quantity    
                        WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Quantity    
                        ELSE MarketRates.Quantity     
            END AS RateQuantity    
            , rt.Name RateTypeName    
            , rt.UnitOfMeasure RateUnitOfMeasure    
            , rt.UnitOfMeasureSource RateUnitOfMeasureSource    
            ,CASE WHEN p.ID = ISNULL(@PrimaryProductID,0) THEN 1   
                        ELSE 0   
            END IsProductMatch    
FROM  #tmpVendorLocation tvl  
JOIN  dbo.VendorLocation vl on tvl.VendorLocationID = vl.ID   
JOIN  dbo.Vendor v  ON vl.VendorID = v.ID    
-- TP - Eliminate join duplication due to multiple dispatch numbers  
--JOIN (  
-- SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
-- FROM dbo.[PhoneEntity]   
-- WHERE EntityID = @VendorLocationEntityID  
-- AND PhoneTypeID = @DispatchPhoneTypeID  
-- GROUP BY EntityID, RecordID  
-- ) ph ON ph.RecordID = vl.ID     
JOIN  dbo.VendorLocationProduct vlp ON vl.ID = vlp.VendorLocationID AND vlp.IsActive = 1  
JOIN  dbo.Product p ON p.ID = vlp.ProductID    
JOIN  dbo.ProductRateType prt ON prt.ProductID = p.ID AND   prt.IsOptional = 0   
JOIN  dbo.RateType rt ON prt.RateTypeID = rt.ID    
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
            ,SUM(1.5 + ROUND((ISP.EnrouteMiles + ISP.ServiceMiles + ISP.ReturnMiles)/40,2)) AS EstimatedHours    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Base' THEN ISP.RatePrice ELSE 0 END) AS BaseRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Hourly' THEN ISP.RatePrice ELSE 0 END) AS HourlyRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Enroute' THEN ISP.RatePrice ELSE 0 END) AS EnrouteRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'EnrouteFree' THEN ISP.RateQuantity ELSE 0 END) AS EnrouteFreeMiles    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Service' THEN ISP.RatePrice ELSE 0 END) AS ServiceRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'ServiceFree' THEN ISP.RateQuantity ELSE 0 END) AS ServiceFreeMiles    
            ,ROUND(SUM(CASE     
                                    WHEN ISP.RateUnitOfMeasure = 'Each' THEN ISP.RatePrice     
                                    WHEN ISP.RateUnitOfMeasure = 'Hour' THEN ISP.RatePrice * (1.5 + ROUND((ISP.EnrouteMiles + ISP.ServiceMiles + ISP.ReturnMiles)/40,2))    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity = 0 THEN ISP.RatePrice * ISP.EnrouteMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity = 0 THEN ISP.RatePrice * ISP.ServiceMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.EnrouteMiles THEN ISP.EnrouteMiles ELSE ISP.RateQuantity END)
    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.ServiceMiles THEN ISP.ServiceMiles ELSE ISP.RateQuantity END) 
   
                                    ELSE 0   
                              END),2) EstimatedPrice    
            ,ROUND((AdministrativeRating*@AdminWeight)+(ProductRating*@PerformWeight)-    
                        (SUM(CASE     
                                    WHEN ISP.RateUnitOfMeasure = 'Each' THEN ISP.RatePrice     
                                    WHEN ISP.RateUnitOfMeasure = 'Hour' THEN ISP.RatePrice * (1.5 + ROUND((ISP.EnrouteMiles + ISP.ServiceMiles + ISP.ReturnMiles)/40,2))    
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
  
ORDER BY WiseScore DESC, EstimatedPrice, EnrouteMiles, ProductRating DESC    
  
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
            ,ProductSearchRadiusMiles  
            ,IsInProductSearchRadius  
            ,@ServiceRequestID  
            ,@now  
            ,'ISPSELECTION_FINAL'    
FROM @ISPSelectionFinalResults ISP  
WHERE @LogISPSelectionFinal = 1  
ORDER BY      
      ISP.IsInProductSearchRadius DESC,  
      ISP.WiseScore DESC,   
      ISP.EstimatedPrice,   
      ISP.EnrouteMiles,   
      ISP.ProductRating DESC   
  
/* Return results */  
SELECT      ISP.*   
FROM  @ISPSelectionFinalResults ISP  
ORDER BY      
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
 WHERE id = object_id(N'[dbo].[dms_Program_Maintainence_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Maintainence_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Maintainence_List_Get]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
SortOperator="-1" 
ClientIDOperator="-1" 
ClientNameOperator="-1" 
ParentProgramIDOperator="-1" 
ParentNameOperator="-1" 
ProgramIDOperator="-1" 
ProgramCodeOperator="-1" 
ProgramNameOperator="-1" 
ProgramDescriptionOperator="-1" 
ProgramIsActiveOperator="-1" 
IsAuditedOperator="-1" 
IsClosedLoopAutomatedOperator="-1" 
IsGroupOperator="-1"
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
SortOperator INT NOT NULL,
SortValue int NULL,
ClientIDOperator INT NOT NULL,
ClientIDValue int NULL,
ClientNameOperator INT NOT NULL,
ClientNameValue nvarchar(50) NULL,
ParentProgramIDOperator INT NOT NULL,
ParentProgramIDValue int NULL,
ParentNameOperator INT NOT NULL,
ParentNameValue nvarchar(50) NULL,
ProgramIDOperator INT NOT NULL,
ProgramIDValue int NULL,
ProgramCodeOperator INT NOT NULL,
ProgramCodeValue nvarchar(50) NULL,
ProgramNameOperator INT NOT NULL,
ProgramNameValue nvarchar(50) NULL,
ProgramDescriptionOperator INT NOT NULL,
ProgramDescriptionValue nvarchar(50) NULL,
ProgramIsActiveOperator INT NOT NULL,
ProgramIsActiveValue bit NULL,
IsAuditedOperator INT NOT NULL,
IsAuditedValue bit NULL,
IsClosedLoopAutomatedOperator INT NOT NULL,
IsClosedLoopAutomatedValue bit NULL,
IsGroupOperator INT NOT NULL,
IsGroupValue bit NULL


)
DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Sort int  NULL ,
	ClientID int  NULL ,
	ClientName nvarchar(50)  NULL ,
	ParentProgramID int  NULL ,
	ParentName nvarchar(50)  NULL ,
	ProgramID int  NULL ,
	ProgramCode nvarchar(50)  NULL ,
	ProgramName nvarchar(50)  NULL ,
	ProgramDescription nvarchar(50)  NULL ,
	ProgramIsActive bit  NULL ,
	IsAudited bit  NULL ,
	IsClosedLoopAutomated bit  NULL ,
	IsGroup bit  NULL 
) 

DECLARE @FinalResults_Temp TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Sort int  NULL ,
	ClientID int  NULL ,
	ClientName nvarchar(50)  NULL ,
	ParentProgramID int  NULL ,
	ParentName nvarchar(50)  NULL ,
	ProgramID int  NULL ,
	ProgramCode nvarchar(50)  NULL ,
	ProgramName nvarchar(50)  NULL ,
	ProgramDescription nvarchar(50)  NULL ,
	ProgramIsActive bit  NULL ,
	IsAudited bit  NULL ,
	IsClosedLoopAutomated bit  NULL ,
	IsGroup bit  NULL 
) 

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(SortOperator,-1),
	SortValue ,
	ISNULL(ClientIDOperator,-1),
	ClientIDValue ,
	ISNULL( ClientNameOperator,-1),
	ClientNameValue ,
	ISNULL(ParentProgramIDOperator,-1),
	ParentProgramIDValue ,
	ISNULL(ParentNameOperator,-1),
	ParentNameValue ,
	ISNULL(ProgramIDOperator,-1),
	ProgramIDValue ,
	ISNULL(ProgramCodeOperator,-1),
	ProgramCodeValue ,
	ISNULL(ProgramNameOperator,-1),
	ProgramNameValue ,
	ISNULL(ProgramDescriptionOperator,-1),
	ProgramDescriptionValue ,
	ISNULL(ProgramIsActiveOperator,-1),
	ProgramIsActiveValue ,
	ISNULL(IsAuditedOperator,-1),
	IsAuditedValue ,
	ISNULL(IsClosedLoopAutomatedOperator,-1),
	IsClosedLoopAutomatedValue ,
	ISNULL(IsGroupOperator,-1),
	IsGroupValue
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
SortOperator INT,
SortValue int 
,ClientIDOperator INT,
ClientIDValue int 
,ClientNameOperator INT,
ClientNameValue nvarchar(50) 
,ParentProgramIDOperator INT,
ParentProgramIDValue int 
,ParentNameOperator INT,
ParentNameValue nvarchar(50) 
,ProgramIDOperator INT,
ProgramIDValue int 
,ProgramCodeOperator INT,
ProgramCodeValue nvarchar(50) 
,ProgramNameOperator INT,
ProgramNameValue nvarchar(50) 
,ProgramDescriptionOperator INT,
ProgramDescriptionValue nvarchar(50) 
,ProgramIsActiveOperator INT,
ProgramIsActiveValue bit 
,IsAuditedOperator INT,
IsAuditedValue bit 
,IsClosedLoopAutomatedOperator INT,
IsClosedLoopAutomatedValue bit 
,IsGroupOperator INT,
IsGroupValue bit 

 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults_Temp
SELECT
CASE
WHEN PP.ID IS NULL THEN P.ID
ELSE PP.ID
END AS Sort
, C.ID AS ClientID
, C.Name AS ClientName
, PP.ID AS ParentProgramID
, PP.Name AS ParentName
, P.ID AS ProgramID
, P.Code AS ProgramCode
, P.Name AS ProgramName
, P.Description AS ProgramDescription
, P.IsActive AS ProgramIsActive
, P.IsAudited AS IsAudited
, P.IsClosedLoopAutomated AS IsClosedLoopAutomated
, P.IsGroup AS IsGroup
--, *
FROM Program P (NOLOCK)
JOIN Client C (NOLOCK) ON C.ID = P.ClientID
LEFT JOIN Program PP (NOLOCK) ON PP.ID = P.ParentProgramID
WHERE C.Name <> 'ARS'
ORDER BY C.Name, Sort, PP.ID, P.ID


INSERT INTO @FinalResults
SELECT 
	T.Sort,
	T.ClientID,
	T.ClientName,
	T.ParentProgramID,
	T.ParentName,
	T.ProgramID,
	T.ProgramCode,
	T.ProgramName,
	T.ProgramDescription,
	T.ProgramIsActive,
	T.IsAudited,
	T.IsClosedLoopAutomated,
	T.IsGroup
FROM @FinalResults_Temp T,
@tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.SortOperator = -1 ) 
 OR 
	 ( TMP.SortOperator = 0 AND T.Sort IS NULL ) 
 OR 
	 ( TMP.SortOperator = 1 AND T.Sort IS NOT NULL ) 
 OR 
	 ( TMP.SortOperator = 2 AND T.Sort = TMP.SortValue ) 
 OR 
	 ( TMP.SortOperator = 3 AND T.Sort <> TMP.SortValue ) 
 OR 
	 ( TMP.SortOperator = 7 AND T.Sort > TMP.SortValue ) 
 OR 
	 ( TMP.SortOperator = 8 AND T.Sort >= TMP.SortValue ) 
 OR 
	 ( TMP.SortOperator = 9 AND T.Sort < TMP.SortValue ) 
 OR 
	 ( TMP.SortOperator = 10 AND T.Sort <= TMP.SortValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ClientIDOperator = -1 ) 
 OR 
	 ( TMP.ClientIDOperator = 0 AND T.ClientID IS NULL ) 
 OR 
	 ( TMP.ClientIDOperator = 1 AND T.ClientID IS NOT NULL ) 
 OR 
	 ( TMP.ClientIDOperator = 2 AND T.ClientID = TMP.ClientIDValue ) 
 OR 
	 ( TMP.ClientIDOperator = 3 AND T.ClientID <> TMP.ClientIDValue ) 
 OR 
	 ( TMP.ClientIDOperator = 7 AND T.ClientID > TMP.ClientIDValue ) 
 OR 
	 ( TMP.ClientIDOperator = 8 AND T.ClientID >= TMP.ClientIDValue ) 
 OR 
	 ( TMP.ClientIDOperator = 9 AND T.ClientID < TMP.ClientIDValue ) 
 OR 
	 ( TMP.ClientIDOperator = 10 AND T.ClientID <= TMP.ClientIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ClientNameOperator = -1 ) 
 OR 
	 ( TMP.ClientNameOperator = 0 AND T.ClientName IS NULL ) 
 OR 
	 ( TMP.ClientNameOperator = 1 AND T.ClientName IS NOT NULL ) 
 OR 
	 ( TMP.ClientNameOperator = 2 AND T.ClientName = TMP.ClientNameValue ) 
 OR 
	 ( TMP.ClientNameOperator = 3 AND T.ClientName <> TMP.ClientNameValue ) 
 OR 
	 ( TMP.ClientNameOperator = 4 AND T.ClientName LIKE TMP.ClientNameValue + '%') 
 OR 
	 ( TMP.ClientNameOperator = 5 AND T.ClientName LIKE '%' + TMP. ClientNameValue ) 
 OR 
	 ( TMP.ClientNameOperator = 6 AND T.ClientName LIKE '%' + TMP. ClientNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ParentProgramIDOperator = -1 ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 0 AND T.ParentProgramID IS NULL ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 1 AND T.ParentProgramID IS NOT NULL ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 2 AND T.ParentProgramID = TMP.ParentProgramIDValue ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 3 AND T.ParentProgramID <> TMP.ParentProgramIDValue ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 7 AND T.ParentProgramID > TMP.ParentProgramIDValue ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 8 AND T.ParentProgramID >= TMP.ParentProgramIDValue ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 9 AND T.ParentProgramID < TMP.ParentProgramIDValue ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 10 AND T.ParentProgramID <= TMP.ParentProgramIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ParentNameOperator = -1 ) 
 OR 
	 ( TMP.ParentNameOperator = 0 AND T.ParentName IS NULL ) 
 OR 
	 ( TMP.ParentNameOperator = 1 AND T.ParentName IS NOT NULL ) 
 OR 
	 ( TMP.ParentNameOperator = 2 AND T.ParentName = TMP.ParentNameValue ) 
 OR 
	 ( TMP.ParentNameOperator = 3 AND T.ParentName <> TMP.ParentNameValue ) 
 OR 
	 ( TMP.ParentNameOperator = 4 AND T.ParentName LIKE TMP.ParentNameValue + '%') 
 OR 
	 ( TMP.ParentNameOperator = 5 AND T.ParentName LIKE '%' + TMP.ParentNameValue ) 
 OR 
	 ( TMP.ParentNameOperator = 6 AND T.ParentName LIKE '%' + TMP.ParentNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProgramIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramIDOperator = 0 AND T.ProgramID IS NULL ) 
 OR 
	 ( TMP.ProgramIDOperator = 1 AND T.ProgramID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramIDOperator = 2 AND T.ProgramID = TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 3 AND T.ProgramID <> TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 7 AND T.ProgramID > TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 8 AND T.ProgramID >= TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 9 AND T.ProgramID < TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 10 AND T.ProgramID <= TMP.ProgramIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ProgramCodeOperator = -1 ) 
 OR 
	 ( TMP.ProgramCodeOperator = 0 AND T.ProgramCode IS NULL ) 
 OR 
	 ( TMP.ProgramCodeOperator = 1 AND T.ProgramCode IS NOT NULL ) 
 OR 
	 ( TMP.ProgramCodeOperator = 2 AND T.ProgramCode = TMP.ProgramCodeValue ) 
 OR 
	 ( TMP.ProgramCodeOperator = 3 AND T.ProgramCode <> TMP.ProgramCodeValue ) 
 OR 
	 ( TMP.ProgramCodeOperator = 4 AND T.ProgramCode LIKE TMP.ProgramCodeValue + '%') 
 OR 
	 ( TMP.ProgramCodeOperator = 5 AND T.ProgramCode LIKE '%' + TMP.ProgramCodeValue ) 
 OR 
	 ( TMP.ProgramCodeOperator = 6 AND T.ProgramCode LIKE '%' + TMP.ProgramCodeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProgramNameOperator = -1 ) 
 OR 
	 ( TMP.ProgramNameOperator = 0 AND T.ProgramName IS NULL ) 
 OR 
	 ( TMP.ProgramNameOperator = 1 AND T.ProgramName IS NOT NULL ) 
 OR 
	 ( TMP.ProgramNameOperator = 2 AND T.ProgramName = TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 3 AND T.ProgramName <> TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 4 AND T.ProgramName LIKE TMP.ProgramNameValue + '%') 
 OR 
	 ( TMP.ProgramNameOperator = 5 AND T.ProgramName LIKE '%' + TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 6 AND T.ProgramName LIKE '%' + TMP.ProgramNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProgramDescriptionOperator = -1 ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 0 AND T.ProgramDescription IS NULL ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 1 AND T.ProgramDescription IS NOT NULL ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 2 AND T.ProgramDescription = TMP.ProgramDescriptionValue ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 3 AND T.ProgramDescription <> TMP.ProgramDescriptionValue ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 4 AND T.ProgramDescription LIKE TMP.ProgramDescriptionValue + '%') 
 OR 
	 ( TMP.ProgramDescriptionOperator = 5 AND T.ProgramDescription LIKE '%' + TMP.ProgramDescriptionValue ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 6 AND T.ProgramDescription LIKE '%' + TMP.ProgramDescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProgramIsActiveOperator = -1 ) 
 OR 
	 ( TMP.ProgramIsActiveOperator = 0 AND T.ProgramIsActive IS NULL ) 
 OR 
	 ( TMP.ProgramIsActiveOperator = 1 AND T.ProgramIsActive IS NOT NULL ) 
 OR 
	 ( TMP.ProgramIsActiveOperator = 2 AND T.ProgramIsActive = TMP.ProgramIsActiveValue ) 
 OR 
	 ( TMP.ProgramIsActiveOperator = 3 AND T.ProgramIsActive <> TMP.ProgramIsActiveValue ) 
 ) 

 AND 

 ( 
	 ( TMP.IsAuditedOperator = -1 ) 
 OR 
	 ( TMP.IsAuditedOperator = 0 AND T.IsAudited IS NULL ) 
 OR 
	 ( TMP.IsAuditedOperator = 1 AND T.IsAudited IS NOT NULL ) 
 OR 
	 ( TMP.IsAuditedOperator = 2 AND T.IsAudited = TMP.IsAuditedValue ) 
 OR 
	 ( TMP.IsAuditedOperator = 3 AND T.IsAudited <> TMP.IsAuditedValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsClosedLoopAutomatedOperator = -1 ) 
 OR 
	 ( TMP.IsClosedLoopAutomatedOperator = 0 AND T.IsClosedLoopAutomated IS NULL ) 
 OR 
	 ( TMP.IsClosedLoopAutomatedOperator = 1 AND T.IsClosedLoopAutomated IS NOT NULL ) 
 OR 
	 ( TMP.IsClosedLoopAutomatedOperator = 2 AND T.IsClosedLoopAutomated = TMP.IsClosedLoopAutomatedValue ) 
 OR 
	 ( TMP.IsClosedLoopAutomatedOperator = 3 AND T.IsClosedLoopAutomated <> TMP.IsClosedLoopAutomatedValue )

 ) 

 AND 

 ( 
	 ( TMP.IsGroupOperator = -1 ) 
 OR 
	 ( TMP.IsGroupOperator = 0 AND T.IsGroup IS NULL ) 
 OR 
	 ( TMP.IsGroupOperator = 1 AND T.IsGroup IS NOT NULL ) 
 OR 
	 ( TMP.IsGroupOperator = 2 AND T.IsGroup = TMP.IsGroupValue ) 
 OR 
	 ( TMP.IsGroupOperator = 3 AND T.IsGroup <> TMP.IsGroupValue )

 ) 
 
 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'Sort' AND @sortOrder = 'ASC'
	 THEN T.Sort END ASC, 
	 CASE WHEN @sortColumn = 'Sort' AND @sortOrder = 'DESC'
	 THEN T.Sort END DESC ,

	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'ASC'
	 THEN T.ClientID END ASC, 
	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'DESC'
	 THEN T.ClientID END DESC ,

	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'ASC'
	 THEN T.ClientName END ASC, 
	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'DESC'
	 THEN T.ClientName END DESC ,

	 CASE WHEN @sortColumn = 'ParentProgramID' AND @sortOrder = 'ASC'
	 THEN T.ParentProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ParentProgramID' AND @sortOrder = 'DESC'
	 THEN T.ParentProgramID END DESC ,

	 CASE WHEN @sortColumn = 'ParentName' AND @sortOrder = 'ASC'
	 THEN T.ParentName END ASC, 
	 CASE WHEN @sortColumn = 'ParentName' AND @sortOrder = 'DESC'
	 THEN T.ParentName END DESC ,

	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'ASC'
	 THEN T.ProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'DESC'
	 THEN T.ProgramID END DESC ,

	 CASE WHEN @sortColumn = 'ProgramCode' AND @sortOrder = 'ASC'
	 THEN T.ProgramCode END ASC, 
	 CASE WHEN @sortColumn = 'ProgramCode' AND @sortOrder = 'DESC'
	 THEN T.ProgramCode END DESC ,

	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'ASC'
	 THEN T.ProgramName END ASC, 
	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'DESC'
	 THEN T.ProgramName END DESC ,

	 CASE WHEN @sortColumn = 'ProgramDescription' AND @sortOrder = 'ASC'
	 THEN T.ProgramDescription END ASC, 
	 CASE WHEN @sortColumn = 'ProgramDescription' AND @sortOrder = 'DESC'
	 THEN T.ProgramDescription END DESC ,

	 CASE WHEN @sortColumn = 'ProgramIsActive' AND @sortOrder = 'ASC'
	 THEN T.ProgramIsActive END ASC, 
	 CASE WHEN @sortColumn = 'ProgramIsActive' AND @sortOrder = 'DESC'
	 THEN T.ProgramIsActive END DESC ,

	 CASE WHEN @sortColumn = 'IsAudited' AND @sortOrder = 'ASC'
	 THEN T.IsAudited END ASC, 
	 CASE WHEN @sortColumn = 'IsAudited' AND @sortOrder = 'DESC'
	 THEN T.IsAudited END DESC ,

	 CASE WHEN @sortColumn = 'IsClosedLoopAutomated' AND @sortOrder = 'ASC'
	 THEN T.IsClosedLoopAutomated END ASC, 
	 CASE WHEN @sortColumn = 'IsClosedLoopAutomated' AND @sortOrder = 'DESC'
	 THEN T.IsClosedLoopAutomated END DESC ,

	 CASE WHEN @sortColumn = 'IsGroup' AND @sortOrder = 'ASC'
	 THEN T.IsGroup END ASC, 
	 CASE WHEN @sortColumn = 'IsGroup' AND @sortOrder = 'DESC'
	 THEN T.IsGroup END DESC 


DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM @FinalResults
SET @endInd = @startInd + @pageSize - 1
IF @startInd  > @count   
BEGIN   
	DECLARE @numOfPages INT    
	SET @numOfPages = @count / @pageSize   
	IF @count % @pageSize > 1   
	BEGIN   
		SET @numOfPages = @numOfPages + 1   
	END   
	SET @startInd = ((@numOfPages - 1) * @pageSize) + 1   
	SET @endInd = @numOfPages * @pageSize   
END

SELECT @count AS TotalRows, * FROM @FinalResults WHERE RowNum BETWEEN @startInd AND @endInd

END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Program_Management_Information]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Program_Management_Information] 
END 
GO
CREATE PROC dms_Program_Management_Information(@ProgramID INT = NULL)
AS
BEGIN
	SELECT   
			   P.ID ProgramID
			 , C.ID AS ClientID
			 , C.Name AS ClientName
			 , P.ParentProgramID AS ParentID
			 , PP.Name AS ParentName
			 , P.Name AS ProgramName
			 , P.Description AS ProgramDescription
			 , P.IsActive AS IsActive
			 , P.Code AS Code
			 , P.IsServiceGuaranteed
			 , P.CallFee
			 , P.DispatchFee
			 , P.IsAudited
			 , P.IsClosedLoopAutomated
			 , P.IsGroup
			 , '' AS PageMode
	FROM       Program P (NOLOCK)
	JOIN       Client C (NOLOCK) ON C.ID = P.ClientID
	LEFT JOIN  Program PP (NOLOCK) ON PP.ID = P.ParentProgramID
	WHERE      P.ID = @ProgramID
END


GO
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
 -- EXEC dms_Program_Management_ProgramConfigurationList @programID = 1
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_ProgramConfigurationList]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_ProgramConfigurationList] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_ProgramConfigurationList]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID INT = NULL
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
ProgramConfigurationIDOperator="-1" 
ProgramIDOperator="-1" 
NameOperator="-1" 
ValueOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

CREATE TABLE #tmpForWhereClause
(
ProgramConfigurationIDOperator INT NOT NULL,
ProgramConfigurationIDValue int NULL,
ProgramIDOperator INT NOT NULL,
ProgramIDValue int NULL,
NameOperator INT NOT NULL,
NameValue nvarchar(50) NULL,
ValueOperator INT NOT NULL,
ValueValue nvarchar(50) NULL
)

CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramConfigurationID int  NULL ,
	ProgramID int  NULL ,
	Name nvarchar(MAX)  NULL ,
	Value nvarchar(MAX)  NULL ,
	IsActive nvarchar(50)  NULL 
) 
DECLARE @QueryResult AS TABLE( 
	ProgramConfigurationID int  NULL ,
	ProgramID int  NULL ,
	Name nvarchar(MAX)  NULL ,
	Value nvarchar(MAX)  NULL ,
	IsActive nvarchar(50)  NULL 
) 

;WITH wProgramConfig 
		AS
		(	SELECT ROW_NUMBER() OVER ( PARTITION BY PC.Name ORDER BY PP.Sequence) AS RowNum,
					PC.ID ProgramConfigurationID,
					PP.ProgramID,
					PP.Sequence,
					PC.Name,	
					PC.Value,
					PC.IsActive,
					CASE ISNULL(PC.IsActive,0) WHEN 0 THEN 'No' ELSE 'Yes' END IsActiveText
			FROM fnc_GetProgramsandParents(@ProgramID) PP
			JOIN ProgramConfiguration PC ON PP.ProgramID = PC.ProgramID AND PC.IsActive = 1
			JOIN ConfigurationType C ON PC.ConfigurationTypeID = C.ID 
			LEFT JOIN ConfigurationCategory CC ON PC.ConfigurationCategoryID = CC.ID
			--WHERE	(@ConfigurationType IS NULL OR C.Name = @ConfigurationType)
			--AND		(@ConfigurationCategory IS NULL OR CC.Name = @ConfigurationCategory)
		)
INSERT INTO @QueryResult SELECT W.ProgramConfigurationID,	
								W.ProgramID,
								W.Name,
								W.Value,
								W.IsActiveText
						FROM	wProgramConfig W
						 WHERE	W.RowNum = 1
					   ORDER BY W.Sequence


INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(ProgramConfigurationIDOperator,-1),
	ProgramConfigurationIDValue ,
	ISNULL(ProgramIDOperator,-1),
	ProgramIDValue ,
	ISNULL(NameOperator,-1),
	NameValue ,
	ISNULL(ValueOperator,-1),
	ValueValue 
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
ProgramConfigurationIDOperator INT,
ProgramConfigurationIDValue int 
,ProgramIDOperator INT,
ProgramIDValue int 
,NameOperator INT,
NameValue nvarchar(50) 
,ValueOperator INT,
ValueValue nvarchar(50) 
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.ProgramConfigurationID,
	T.ProgramID,
	T.Name,
	T.Value,
	T.IsActive
FROM @QueryResult T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.ProgramConfigurationIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 0 AND T.ProgramConfigurationID IS NULL ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 1 AND T.ProgramConfigurationID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 2 AND T.ProgramConfigurationID = TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 3 AND T.ProgramConfigurationID <> TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 7 AND T.ProgramConfigurationID > TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 8 AND T.ProgramConfigurationID >= TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 9 AND T.ProgramConfigurationID < TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 10 AND T.ProgramConfigurationID <= TMP.ProgramConfigurationIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ProgramIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramIDOperator = 0 AND T.ProgramID IS NULL ) 
 OR 
	 ( TMP.ProgramIDOperator = 1 AND T.ProgramID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramIDOperator = 2 AND T.ProgramID = TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 3 AND T.ProgramID <> TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 7 AND T.ProgramID > TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 8 AND T.ProgramID >= TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 9 AND T.ProgramID < TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 10 AND T.ProgramID <= TMP.ProgramIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.NameOperator = -1 ) 
 OR 
	 ( TMP.NameOperator = 0 AND T.Name IS NULL ) 
 OR 
	 ( TMP.NameOperator = 1 AND T.Name IS NOT NULL ) 
 OR 
	 ( TMP.NameOperator = 2 AND T.Name = TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 3 AND T.Name <> TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 4 AND T.Name LIKE TMP.NameValue + '%') 
 OR 
	 ( TMP.NameOperator = 5 AND T.Name LIKE '%' + TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 6 AND T.Name LIKE '%' + TMP.NameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ValueOperator = -1 ) 
 OR 
	 ( TMP.ValueOperator = 0 AND T.Value IS NULL ) 
 OR 
	 ( TMP.ValueOperator = 1 AND T.Value IS NOT NULL ) 
 OR 
	 ( TMP.ValueOperator = 2 AND T.Value = TMP.ValueValue ) 
 OR 
	 ( TMP.ValueOperator = 3 AND T.Value <> TMP.ValueValue ) 
 OR 
	 ( TMP.ValueOperator = 4 AND T.Value LIKE TMP.ValueValue + '%') 
 OR 
	 ( TMP.ValueOperator = 5 AND T.Value LIKE '%' + TMP.ValueValue ) 
 OR 
	 ( TMP.ValueOperator = 6 AND T.Value LIKE '%' + TMP.ValueValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ProgramConfigurationID' AND @sortOrder = 'ASC'
	 THEN T.ProgramConfigurationID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramConfigurationID' AND @sortOrder = 'DESC'
	 THEN T.ProgramConfigurationID END DESC ,

	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'ASC'
	 THEN T.ProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'DESC'
	 THEN T.ProgramID END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Value' AND @sortOrder = 'ASC'
	 THEN T.Value END ASC, 
	 CASE WHEN @sortColumn = 'Value' AND @sortOrder = 'DESC'
	 THEN T.Value END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC 


DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM #FinalResults
SET @endInd = @startInd + @pageSize - 1
IF @startInd  > @count   
BEGIN   
	DECLARE @numOfPages INT    
	SET @numOfPages = @count / @pageSize   
	IF @count % @pageSize > 1   
	BEGIN   
		SET @numOfPages = @numOfPages + 1   
	END   
	SET @startInd = ((@numOfPages - 1) * @pageSize) + 1   
	SET @endInd = @numOfPages * @pageSize   
END

SELECT @count AS TotalRows, * FROM #FinalResults WHERE RowNum BETWEEN @startInd AND @endInd

DROP TABLE #tmpForWhereClause
DROP TABLE #FinalResults
END

GO
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
*  ---- for int, money, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_Services_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_Services_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_Program_Management_Services_List_Get] @ProgramID =3 ,@pageSize = 25
 CREATE PROCEDURE [dbo].[dms_Program_Management_Services_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @ProgramID INT = NULL 
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
 	SET FMTONLY OFF

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
ProgramProductIDOperator="-1" 
CategoryOperator="-1" 
ServiceOperator="-1" 
StartDateOperator="-1" 
EndDateOperator="-1" 
ServiceCoverageLimitOperator="-1" 
IsServiceCoverageBestValueOperator="-1" 
MaterialsCoverageLimitOperator="-1" 
IsMaterialsMemberPayOperator="-1" 
ServiceMileageLimitOperator="-1" 
IsServiceMileageUnlimitedOperator="-1" 
IsServiceMileageOverageAllowedOperator="-1" 
IsReimbersementOnlyOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
ProgramProductIDOperator INT NOT NULL,
ProgramProductIDValue int NULL,
CategoryOperator INT NOT NULL,
CategoryValue nvarchar(100) NULL,
ServiceOperator INT NOT NULL,
ServiceValue nvarchar(100) NULL,
StartDateOperator INT NOT NULL,
StartDateValue datetime NULL,
EndDateOperator INT NOT NULL,
EndDateValue datetime NULL,
ServiceCoverageLimitOperator INT NOT NULL,
ServiceCoverageLimitValue money NULL,
IsServiceCoverageBestValueOperator INT NOT NULL,
IsServiceCoverageBestValueValue bit NULL,
MaterialsCoverageLimitOperator INT NOT NULL,
MaterialsCoverageLimitValue money NULL,
IsMaterialsMemberPayOperator INT NOT NULL,
IsMaterialsMemberPayValue bit NULL,
ServiceMileageLimitOperator INT NOT NULL,
ServiceMileageLimitValue int NULL,
IsServiceMileageUnlimitedOperator INT NOT NULL,
IsServiceMileageUnlimitedValue bit NULL,
IsServiceMileageOverageAllowedOperator INT NOT NULL,
IsServiceMileageOverageAllowedValue bit NULL,
IsReimbersementOnlyOperator INT NOT NULL,
IsReimbersementOnlyValue bit NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramProductID int  NULL ,
	Category nvarchar(100)  NULL ,
	Service nvarchar(100)  NULL ,
	StartDate datetime  NULL ,
	EndDate datetime  NULL ,
	ServiceCoverageLimit money  NULL ,
	IsServiceCoverageBestValue bit  NULL ,
	MaterialsCoverageLimit money  NULL ,
	IsMaterialsMemberPay bit  NULL ,
	ServiceMileageLimit int  NULL ,
	IsServiceMileageUnlimited bit  NULL ,
	IsServiceMileageOverageAllowed bit  NULL ,
	IsReimbersementOnly bit  NULL 
) 

CREATE TABLE #FinalResults_temp( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramProductID int  NULL ,
	Category nvarchar(100)  NULL ,
	Service nvarchar(100)  NULL ,
	StartDate datetime  NULL ,
	EndDate datetime  NULL ,
	ServiceCoverageLimit money  NULL ,
	IsServiceCoverageBestValue bit  NULL ,
	MaterialsCoverageLimit money  NULL ,
	IsMaterialsMemberPay bit  NULL ,
	ServiceMileageLimit int  NULL ,
	IsServiceMileageUnlimited bit  NULL ,
	IsServiceMileageOverageAllowed bit  NULL ,
	IsReimbersementOnly bit  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@ProgramProductIDOperator','INT'),-1),
	T.c.value('@ProgramProductIDValue','int') ,
	ISNULL(T.c.value('@CategoryOperator','INT'),-1),
	T.c.value('@CategoryValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ServiceOperator','INT'),-1),
	T.c.value('@ServiceValue','nvarchar(100)') ,
	ISNULL(T.c.value('@StartDateOperator','INT'),-1),
	T.c.value('@StartDateValue','datetime') ,
	ISNULL(T.c.value('@EndDateOperator','INT'),-1),
	T.c.value('@EndDateValue','datetime') ,
	ISNULL(T.c.value('@ServiceCoverageLimitOperator','INT'),-1),
	T.c.value('@ServiceCoverageLimitValue','money') ,
	ISNULL(T.c.value('@IsServiceCoverageBestValueOperator','INT'),-1),
	T.c.value('@IsServiceCoverageBestValueValue','bit') ,
	ISNULL(T.c.value('@MaterialsCoverageLimitOperator','INT'),-1),
	T.c.value('@MaterialsCoverageLimitValue','money') ,
	ISNULL(T.c.value('@IsMaterialsMemberPayOperator','INT'),-1),
	T.c.value('@IsMaterialsMemberPayValue','bit') ,
	ISNULL(T.c.value('@ServiceMileageLimitOperator','INT'),-1),
	T.c.value('@ServiceMileageLimitValue','int') ,
	ISNULL(T.c.value('@IsServiceMileageUnlimitedOperator','INT'),-1),
	T.c.value('@IsServiceMileageUnlimitedValue','bit') ,
	ISNULL(T.c.value('@IsServiceMileageOverageAllowedOperator','INT'),-1),
	T.c.value('@IsServiceMileageOverageAllowedValue','bit') ,
	ISNULL(T.c.value('@IsReimbersementOnlyOperator','INT'),-1),
	T.c.value('@IsReimbersementOnlyValue','bit') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults_temp
SELECT 
  PP.ID AS ProgramProductID
, PC.Name AS Category
, PR.Name AS [Service]
, PP.StartDate
, PP.EndDate
, PP.ServiceCoverageLimit
, PP.IsServiceCoverageBestValue
, PP.MaterialsCoverageLimit
, PP.IsMaterialsMemberPay
, PP.ServiceMileageLimit
, PP.IsServiceMileageUnlimited
, PP.IsServiceMileageOverageAllowed
, PP.IsReimbersementOnly
FROM ProgramProduct PP
JOIN Program P (NOLOCK) ON P.ID = PP.ProgramID
JOIN Product PR (NOLOCK) ON PR.ID = PP.ProductID
JOIN ProductCategory PC (NOLOCK) ON PC.ID = PR.ProductCategoryID
WHERE PP.ProgramID = @ProgramID
ORDER BY PC.Sequence, PR.Name
INSERT INTO #FinalResults
SELECT 
	T.ProgramProductID,
	T.Category,
	T.Service,
	T.StartDate,
	T.EndDate,
	T.ServiceCoverageLimit,
	T.IsServiceCoverageBestValue,
	T.MaterialsCoverageLimit,
	T.IsMaterialsMemberPay,
	T.ServiceMileageLimit,
	T.IsServiceMileageUnlimited,
	T.IsServiceMileageOverageAllowed,
	T.IsReimbersementOnly
FROM #FinalResults_temp T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.ProgramProductIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 0 AND T.ProgramProductID IS NULL ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 1 AND T.ProgramProductID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 2 AND T.ProgramProductID = TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 3 AND T.ProgramProductID <> TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 7 AND T.ProgramProductID > TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 8 AND T.ProgramProductID >= TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 9 AND T.ProgramProductID < TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 10 AND T.ProgramProductID <= TMP.ProgramProductIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CategoryOperator = -1 ) 
 OR 
	 ( TMP.CategoryOperator = 0 AND T.Category IS NULL ) 
 OR 
	 ( TMP.CategoryOperator = 1 AND T.Category IS NOT NULL ) 
 OR 
	 ( TMP.CategoryOperator = 2 AND T.Category = TMP.CategoryValue ) 
 OR 
	 ( TMP.CategoryOperator = 3 AND T.Category <> TMP.CategoryValue ) 
 OR 
	 ( TMP.CategoryOperator = 4 AND T.Category LIKE TMP.CategoryValue + '%') 
 OR 
	 ( TMP.CategoryOperator = 5 AND T.Category LIKE '%' + TMP.CategoryValue ) 
 OR 
	 ( TMP.CategoryOperator = 6 AND T.Category LIKE '%' + TMP.CategoryValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ServiceOperator = -1 ) 
 OR 
	 ( TMP.ServiceOperator = 0 AND T.Service IS NULL ) 
 OR 
	 ( TMP.ServiceOperator = 1 AND T.Service IS NOT NULL ) 
 OR 
	 ( TMP.ServiceOperator = 2 AND T.Service = TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 3 AND T.Service <> TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 4 AND T.Service LIKE TMP.ServiceValue + '%') 
 OR 
	 ( TMP.ServiceOperator = 5 AND T.Service LIKE '%' + TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 6 AND T.Service LIKE '%' + TMP.ServiceValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.StartDateOperator = -1 ) 
 OR 
	 ( TMP.StartDateOperator = 0 AND T.StartDate IS NULL ) 
 OR 
	 ( TMP.StartDateOperator = 1 AND T.StartDate IS NOT NULL ) 
 OR 
	 ( TMP.StartDateOperator = 2 AND T.StartDate = TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 3 AND T.StartDate <> TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 7 AND T.StartDate > TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 8 AND T.StartDate >= TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 9 AND T.StartDate < TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 10 AND T.StartDate <= TMP.StartDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.EndDateOperator = -1 ) 
 OR 
	 ( TMP.EndDateOperator = 0 AND T.EndDate IS NULL ) 
 OR 
	 ( TMP.EndDateOperator = 1 AND T.EndDate IS NOT NULL ) 
 OR 
	 ( TMP.EndDateOperator = 2 AND T.EndDate = TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 3 AND T.EndDate <> TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 7 AND T.EndDate > TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 8 AND T.EndDate >= TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 9 AND T.EndDate < TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 10 AND T.EndDate <= TMP.EndDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ServiceCoverageLimitOperator = -1 ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 0 AND T.ServiceCoverageLimit IS NULL ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 1 AND T.ServiceCoverageLimit IS NOT NULL ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 2 AND T.ServiceCoverageLimit = TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 3 AND T.ServiceCoverageLimit <> TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 7 AND T.ServiceCoverageLimit > TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 8 AND T.ServiceCoverageLimit >= TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 9 AND T.ServiceCoverageLimit < TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 10 AND T.ServiceCoverageLimit <= TMP.ServiceCoverageLimitValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsServiceCoverageBestValueOperator = -1 ) 
 OR 
	 ( TMP.IsServiceCoverageBestValueOperator = 0 AND T.IsServiceCoverageBestValue IS NULL ) 
 OR 
	 ( TMP.IsServiceCoverageBestValueOperator = 1 AND T.IsServiceCoverageBestValue IS NOT NULL ) 
 OR 
	 ( TMP.IsServiceCoverageBestValueOperator = 2 AND T.IsServiceCoverageBestValue = TMP.IsServiceCoverageBestValueValue ) 
 OR 
	 ( TMP.IsServiceCoverageBestValueOperator = 3 AND T.IsServiceCoverageBestValue <> TMP.IsServiceCoverageBestValueValue ) 
 ) 

 AND 

 ( 
	 ( TMP.MaterialsCoverageLimitOperator = -1 ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 0 AND T.MaterialsCoverageLimit IS NULL ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 1 AND T.MaterialsCoverageLimit IS NOT NULL ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 2 AND T.MaterialsCoverageLimit = TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 3 AND T.MaterialsCoverageLimit <> TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 7 AND T.MaterialsCoverageLimit > TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 8 AND T.MaterialsCoverageLimit >= TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 9 AND T.MaterialsCoverageLimit < TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 10 AND T.MaterialsCoverageLimit <= TMP.MaterialsCoverageLimitValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsMaterialsMemberPayOperator = -1 ) 
 OR 
	 ( TMP.IsMaterialsMemberPayOperator = 0 AND T.IsMaterialsMemberPay IS NULL ) 
 OR 
	 ( TMP.IsMaterialsMemberPayOperator = 1 AND T.IsMaterialsMemberPay IS NOT NULL ) 
 OR 
	 ( TMP.IsMaterialsMemberPayOperator = 2 AND T.IsMaterialsMemberPay = TMP.IsMaterialsMemberPayValue ) 
 OR 
	 ( TMP.IsMaterialsMemberPayOperator = 3 AND T.IsMaterialsMemberPay <> TMP.IsMaterialsMemberPayValue ) 
 ) 

 AND 

 ( 
	 ( TMP.ServiceMileageLimitOperator = -1 ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 0 AND T.ServiceMileageLimit IS NULL ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 1 AND T.ServiceMileageLimit IS NOT NULL ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 2 AND T.ServiceMileageLimit = TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 3 AND T.ServiceMileageLimit <> TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 7 AND T.ServiceMileageLimit > TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 8 AND T.ServiceMileageLimit >= TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 9 AND T.ServiceMileageLimit < TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 10 AND T.ServiceMileageLimit <= TMP.ServiceMileageLimitValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsServiceMileageUnlimitedOperator = -1 ) 
 OR 
	 ( TMP.IsServiceMileageUnlimitedOperator = 0 AND T.IsServiceMileageUnlimited IS NULL ) 
 OR 
	 ( TMP.IsServiceMileageUnlimitedOperator = 1 AND T.IsServiceMileageUnlimited IS NOT NULL ) 
 OR 
	 ( TMP.IsServiceMileageUnlimitedOperator = 2 AND T.IsServiceMileageUnlimited = TMP.IsServiceMileageUnlimitedValue ) 
 OR 
	 ( TMP.IsServiceMileageUnlimitedOperator = 3 AND T.IsServiceMileageUnlimited <> TMP.IsServiceMileageUnlimitedValue ) 
 ) 

 AND 

 ( 
	 ( TMP.IsServiceMileageOverageAllowedOperator = -1 ) 
 OR 
	 ( TMP.IsServiceMileageOverageAllowedOperator = 0 AND T.IsServiceMileageOverageAllowed IS NULL ) 
 OR 
	 ( TMP.IsServiceMileageOverageAllowedOperator = 1 AND T.IsServiceMileageOverageAllowed IS NOT NULL ) 
 OR 
	 ( TMP.IsServiceMileageOverageAllowedOperator = 2 AND T.IsServiceMileageOverageAllowed = TMP.IsServiceMileageOverageAllowedValue ) 
 OR 
	 ( TMP.IsServiceMileageOverageAllowedOperator = 3 AND T.IsServiceMileageOverageAllowed <> TMP.IsServiceMileageOverageAllowedValue ) 
 ) 

 AND 

 ( 
	 ( TMP.IsReimbersementOnlyOperator = -1 ) 
 OR 
	 ( TMP.IsReimbersementOnlyOperator = 0 AND T.IsReimbersementOnly IS NULL ) 
 OR 
	 ( TMP.IsReimbersementOnlyOperator = 1 AND T.IsReimbersementOnly IS NOT NULL ) 
 OR 
	 ( TMP.IsReimbersementOnlyOperator = 2 AND T.IsReimbersementOnly = TMP.IsReimbersementOnlyValue ) 
 OR 
	 ( TMP.IsReimbersementOnlyOperator = 3 AND T.IsReimbersementOnly <> TMP.IsReimbersementOnlyValue ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ProgramProductID' AND @sortOrder = 'ASC'
	 THEN T.ProgramProductID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramProductID' AND @sortOrder = 'DESC'
	 THEN T.ProgramProductID END DESC ,

	 CASE WHEN @sortColumn = 'Category' AND @sortOrder = 'ASC'
	 THEN T.Category END ASC, 
	 CASE WHEN @sortColumn = 'Category' AND @sortOrder = 'DESC'
	 THEN T.Category END DESC ,

	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'ASC'
	 THEN T.Service END ASC, 
	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'DESC'
	 THEN T.Service END DESC ,

	 CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'ASC'
	 THEN T.StartDate END ASC, 
	 CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'DESC'
	 THEN T.StartDate END DESC ,

	 CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'ASC'
	 THEN T.EndDate END ASC, 
	 CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'DESC'
	 THEN T.EndDate END DESC ,

	 CASE WHEN @sortColumn = 'ServiceCoverageLimit' AND @sortOrder = 'ASC'
	 THEN T.ServiceCoverageLimit END ASC, 
	 CASE WHEN @sortColumn = 'ServiceCoverageLimit' AND @sortOrder = 'DESC'
	 THEN T.ServiceCoverageLimit END DESC ,

	 CASE WHEN @sortColumn = 'IsServiceCoverageBestValue' AND @sortOrder = 'ASC'
	 THEN T.IsServiceCoverageBestValue END ASC, 
	 CASE WHEN @sortColumn = 'IsServiceCoverageBestValue' AND @sortOrder = 'DESC'
	 THEN T.IsServiceCoverageBestValue END DESC ,

	 CASE WHEN @sortColumn = 'MaterialsCoverageLimit' AND @sortOrder = 'ASC'
	 THEN T.MaterialsCoverageLimit END ASC, 
	 CASE WHEN @sortColumn = 'MaterialsCoverageLimit' AND @sortOrder = 'DESC'
	 THEN T.MaterialsCoverageLimit END DESC ,

	 CASE WHEN @sortColumn = 'IsMaterialsMemberPay' AND @sortOrder = 'ASC'
	 THEN T.IsMaterialsMemberPay END ASC, 
	 CASE WHEN @sortColumn = 'IsMaterialsMemberPay' AND @sortOrder = 'DESC'
	 THEN T.IsMaterialsMemberPay END DESC ,

	 CASE WHEN @sortColumn = 'ServiceMileageLimit' AND @sortOrder = 'ASC'
	 THEN T.ServiceMileageLimit END ASC, 
	 CASE WHEN @sortColumn = 'ServiceMileageLimit' AND @sortOrder = 'DESC'
	 THEN T.ServiceMileageLimit END DESC ,

	 CASE WHEN @sortColumn = 'IsServiceMileageUnlimited' AND @sortOrder = 'ASC'
	 THEN T.IsServiceMileageUnlimited END ASC, 
	 CASE WHEN @sortColumn = 'IsServiceMileageUnlimited' AND @sortOrder = 'DESC'
	 THEN T.IsServiceMileageUnlimited END DESC ,

	 CASE WHEN @sortColumn = 'IsServiceMileageOverageAllowed' AND @sortOrder = 'ASC'
	 THEN T.IsServiceMileageOverageAllowed END ASC, 
	 CASE WHEN @sortColumn = 'IsServiceMileageOverageAllowed' AND @sortOrder = 'DESC'
	 THEN T.IsServiceMileageOverageAllowed END DESC ,

	 CASE WHEN @sortColumn = 'IsReimbersementOnly' AND @sortOrder = 'ASC'
	 THEN T.IsReimbersementOnly END ASC, 
	 CASE WHEN @sortColumn = 'IsReimbersementOnly' AND @sortOrder = 'DESC'
	 THEN T.IsReimbersementOnly END DESC 


DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM #FinalResults
SET @endInd = @startInd + @pageSize - 1
IF @startInd  > @count   
BEGIN   
	DECLARE @numOfPages INT    
	SET @numOfPages = @count / @pageSize   
	IF @count % @pageSize > 1   
	BEGIN   
		SET @numOfPages = @numOfPages + 1   
	END   
	SET @startInd = ((@numOfPages - 1) * @pageSize) + 1   
	SET @endInd = @numOfPages * @pageSize   
END

SELECT @count AS TotalRows, * FROM #FinalResults WHERE RowNum BETWEEN @startInd AND @endInd

DROP TABLE #tmpForWhereClause
DROP TABLE #FinalResults
DROP TABLE #FinalResults_temp
END

GO
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
 WHERE id = object_id(N'[dbo].[dms_queue_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_queue_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_queue_list] @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB', @sortColumn='RequestNumber',@sortOrder = 'ASC'
-- EXEC [dbo].[dms_queue_list] @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB', @sortColumn='RequestNumber',@sortOrder = 'ASC', @whereClauseXML = '<ROW><Filter RequestNumberOperator="4" RequestNumberValue="4"></Filter></ROW>'
-- EXEC [dbo].[dms_queue_list] @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB', @sortColumn='RequestNumber',@sortOrder = 'ASC',@whereClauseXML = '<ROW><Filter StatusOperator="11" StatusValue="Cancelled"></Filter></ROW>'
 CREATE PROCEDURE [dbo].[dms_queue_list](   
   @userID UNIQUEIDENTIFIER = NULL  
 , @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 100    
 , @sortColumn nvarchar(100)  = ''   
 , @sortOrder nvarchar(100) = 'ASC'   
    
 )   
 AS   
 BEGIN   
    
SET NOCOUNT ON  
SET FMTONLY OFF  

CREATE TABLE #FinalResultsFiltered (  
[Case] int NULL ,  
RequestNumber int NULL ,  
Client nvarchar(100) NULL ,  
FirstName nvarchar(50)  NULL ,    
LastName nvarchar(50)  NULL , 
MiddleName   nvarchar(50)  NULL ,   
Suffix nvarchar(50)  NULL ,    
Prefix nvarchar(50)  NULL ,  
SubmittedOriginal DATETIME, 
SecondaryProductID INT NULL,   
ServiceType nvarchar(100) NULL ,  
[Status] nvarchar(100) NULL ,  
IsRedispatched BIT NULL,
AssignedToUserID INT NULL,
NextActionAssignedToUserID INT NULL,
ClosedLoop nvarchar(100) NULL ,  
PONumber nvarchar(50) NULL ,  
ISPName nvarchar(255) NULL ,  
CreateBy nvarchar(100) NULL ,  
NextAction nvarchar(MAX) NULL,  
NextActionID INT NULL,  
ClosedLoopID INT NULL,  
ServiceTypeID INT NULL,  
MemberNumber NVARCHAR(50) NULL,  
PriorityID INT NULL,  
[Priority] NVARCHAR(255) NULL,   
ScheduledOriginal DATETIME NULL,
-- KB: Added extra IDs
ProgramName NVARCHAR(50) NULL,
ProgramID INT NULL,
MemberID INT NULL,
StatusDateModified DATETIME NULL  -- Added by Lakshmi - Queue Color
)  
  
CREATE TABLE #FinalResultsFormatted (    
[Case] int NULL ,  
RequestNumber int NULL ,  
Client nvarchar(100) NULL ,  
Member nvarchar(max) NULL ,  
Submitted nvarchar(100) NULL ,  
SubmittedOriginal DATETIME,  
Elapsed NVARCHAR(10),  
ElapsedOriginal bigint,  
ServiceType nvarchar(100) NULL ,  
[Status] nvarchar(100) NULL ,  
AssignedTo nvarchar(100) NULL ,  
ClosedLoop nvarchar(100) NULL ,  
PONumber int NULL ,  
ISPName nvarchar(255) NULL ,  
CreateBy nvarchar(100) NULL ,  
NextAction nvarchar(MAX) NULL,  
MemberNumber NVARCHAR(50) NULL,  
[Priority] NVARCHAR(255) NULL,  
[Scheduled] nvarchar(100) NULL,  
ScheduledOriginal DATETIME  NULL,
-- KB: Added extra IDs
ProgramName NVARCHAR(50) NULL,
ProgramID INT NULL,
MemberID INT NULL,
StatusDateModified DATETIME NULL  -- Added by Lakshmi - Queue Color
)  

CREATE TABLE #FinalResultsSorted (  
[RowNum] [bigint] NOT NULL IDENTITY(1,1),  
[Case] int NULL ,  
RequestNumber int NULL ,  
Client nvarchar(100) NULL ,  
Member nvarchar(max) NULL ,  
Submitted nvarchar(100) NULL ,  
SubmittedOriginal DATETIME,  
Elapsed NVARCHAR(10),  
ElapsedOriginal bigint,  
ServiceType nvarchar(100) NULL ,  
[Status] nvarchar(100) NULL ,  
AssignedTo nvarchar(100) NULL ,  
ClosedLoop nvarchar(100) NULL ,  
PONumber int NULL ,  
ISPName nvarchar(255) NULL ,  
CreateBy nvarchar(100) NULL ,  
NextAction nvarchar(MAX) NULL,  
MemberNumber NVARCHAR(50) NULL,  
[Priority] NVARCHAR(255) NULL,  
[Scheduled] nvarchar(100) NULL,  
ScheduledOriginal DATETIME NULL,
-- KB: Added extra IDs
ProgramName NVARCHAR(50) NULL,
ProgramID INT NULL,
MemberID INT NULL,
StatusDateModified DATETIME NULL  -- Added by Lakshmi - Queue Color
)
  
DECLARE @openedCount BIGINT = 0  
DECLARE @submittedCount BIGINT = 0  
  
DECLARE @dispatchedCount BIGINT = 0  
--  
DECLARE @completecount BIGINT = 0  
DECLARE @cancelledcount BIGINT = 0  
  
--DECLARE @scheduledCount BIGINT = 0  
  
DECLARE @queueDisplayHours INT  
DECLARE @now DATETIME  
  
SET @now = GETDATE()  
  
SET @queueDisplayHours = 0  
SELECT @queueDisplayHours = CONVERT(INT,ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'QueueDisplayHours'  
  
DECLARE @idoc int  
IF @whereClauseXML IS NULL  
BEGIN  
SET @whereClauseXML = '<ROW><Filter  
CaseOperator="-1"  
RequestNumberOperator="-1"  
MemberOperator="-1"  
ServiceTypeOperator="-1"  
PONumberOperator="-1"  
ISPNameOperator="-1"  
CreateByOperator="-1"  
StatusOperator="-1"  
ClosedLoopOperator="-1"  
NextActionOperator="-1"  
AssignedToOperator="-1"  
></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
CaseOperator INT NOT NULL,  
CaseValue int NULL,  
RequestNumberOperator INT NOT NULL,  
RequestNumberValue int NULL,  
MemberOperator INT NOT NULL,  
MemberValue nvarchar(200) NULL,  
ServiceTypeOperator INT NOT NULL,  
ServiceTypeValue nvarchar(50) NULL,  
PONumberOperator INT NOT NULL,  
PONumberValue nvarchar(50) NULL,  
ISPNameOperator INT NOT NULL,  
ISPNameValue nvarchar(255) NULL,  
CreateByOperator INT NOT NULL,  
CreateByValue nvarchar(50) NULL,  
StatusOperator INT NOT NULL,  
StatusValue nvarchar(50) NULL,  
ClosedLoopOperator INT NOT NULL,  
ClosedLoopValue nvarchar(50) NULL,  
NextActionOperator INT NOT NULL,  
NextActionValue nvarchar(50) NULL,  
AssignedToOperator INT NOT NULL,  
AssignedToValue nvarchar(50) NULL,  
MemberNumberOperator INT NOT NULL,  
MemberNumberValue nvarchar(50) NULL,  
PriorityOperator INT NOT NULL,  
PriorityValue nvarchar(50) NULL  
)  
  
  
INSERT INTO @tmpForWhereClause  
SELECT  
ISNULL(CaseOperator,-1),  
CaseValue ,  
ISNULL(RequestNumberOperator,-1),  
RequestNumberValue ,  
ISNULL(MemberOperator,-1),  
MemberValue ,  
ISNULL(ServiceTypeOperator,-1),  
ServiceTypeValue ,  
ISNULL(PONumberOperator,-1),  
PONumberValue ,  
ISNULL(ISPNameOperator,-1),  
ISPNameValue ,  
ISNULL(CreateByOperator,-1),  
CreateByValue,  
ISNULL(StatusOperator,-1),  
StatusValue ,  
ISNULL(ClosedLoopOperator,-1),  
ClosedLoopValue,  
ISNULL(NextActionOperator,-1),  
NextActionValue,  
ISNULL(AssignedToOperator,-1),  
AssignedToValue,  
ISNULL(MemberNumberOperator,-1),  
MemberNumberValue,  
ISNULL(PriorityOperator,-1),  
PriorityValue  
  
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
CaseOperator INT,  
CaseValue int  
,RequestNumberOperator INT,  
RequestNumberValue int  
,MemberOperator INT,  
MemberValue nvarchar(200)  
,ServiceTypeOperator INT,  
ServiceTypeValue nvarchar(50)  
,PONumberOperator INT,  
PONumberValue nvarchar(50)  
,ISPNameOperator INT,  
ISPNameValue nvarchar(255)  
,CreateByOperator INT,  
CreateByValue nvarchar(50)  
,StatusOperator INT,  
StatusValue nvarchar(50),  
ClosedLoopOperator INT,  
ClosedLoopValue nvarchar(50),  
NextActionOperator INT,  
NextActionValue nvarchar(50),  
AssignedToOperator INT,  
AssignedToValue nvarchar(50),  
MemberNumberOperator INT,  
MemberNumberValue nvarchar(50),  
PriorityOperator INT,  
PriorityValue nvarchar(50)  
)  

DECLARE @CaseValue int  
DECLARE @RequestNumberValue int
DECLARE @MemberValue nvarchar(200)
DECLARE @ServiceTypeValue nvarchar(50)  
DECLARE @PONumberValue nvarchar(50)  
DECLARE @ISPNameValue nvarchar(255)  
DECLARE @CreateByValue nvarchar(50)  
DECLARE @StatusValue nvarchar(50)
DECLARE @ClosedLoopValue nvarchar(50)
DECLARE @NextActionValue nvarchar(50)
DECLARE @AssignedToValue nvarchar(50)
DECLARE @MemberNumberValue nvarchar(50)
DECLARE @PriorityValue nvarchar(50)
DECLARE @isFHT  BIT = 0

DECLARE @serviceRequestEntityID INT
DECLARE @fhtContactReasonID INT
DECLARE @dispatchStatusID INT

SET @serviceRequestEntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
SET @fhtContactReasonID = (SELECT ID FROM ContactReason WHERE Name = 'HumanTouch')
SET @dispatchStatusID = (SELECT ID FROM ServiceRequestStatus WHERE Name = 'Dispatched')

DECLARE @StartMins INT = 0 
SELECT @StartMins = -1 * CONVERT(INT,ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'FordHumanTouchStartMins' 

DECLARE @EndMins INT = 0 
SELECT @EndMins = -1 * CONVERT(INT,ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'FordHumanTouchEndMins' 

-- DEBUG:
--SELECT @StartMins, @EndMins

 SELECT @CaseValue = CaseValue,
		@RequestNumberValue = RequestNumberValue,
		@MemberValue = MemberValue,
		@ServiceTypeValue = ServiceTypeValue,
		@PONumberValue = PONumberValue,
		@ISPNameValue = ISPNameValue,
		@CreateByValue = CreateByValue,
		@StatusValue = StatusValue,
		@ClosedLoopValue = ClosedLoopValue,
		@NextActionValue = NextActionValue,
		@AssignedToValue = AssignedToValue,
		@MemberNumberValue = MemberNumberValue,
		@PriorityValue = PriorityValue
 FROM	@tmpForWhereClause
  
-- Extract the status values.  
  
DECLARE @tmpStatusInput TABLE  
(  
 StatusName NVARCHAR(100)  
)  
 
DECLARE @fhtCharIndex INT = -1
SET @fhtCharIndex = CHARINDEX('FHT',@StatusValue,0)

IF (@fhtCharIndex > 0)
BEGIN
	SET @StatusValue = REPLACE(@StatusValue,'FHT','')
	SET @isFHT = 1
END


  
INSERT INTO @tmpStatusInput  
SELECT Item FROM [dbo].[fnSplitString](@StatusValue,',')  
  
  
-- Include StatusNames with '^' suffix.  
INSERT INTO @tmpStatusInput  
SELECT StatusName + '^' FROM @tmpStatusInput  

-- CR : 1244 - FHT
IF (@isFHT = 1)
BEGIN	
	-- remove FHT from the StatusValue.	
	DECLARE @cnt INT = 0
	SELECT @cnt = COUNT(*) FROM @tmpStatusInput	
	IF (@cnt = 0)
	BEGIN
		SET @StatusValue = NULL		
	END
END

  
--DEBUG: SELECT * FROM @tmpStatusInput  
  
-- For EF to generate proper classes  
IF @userID IS NULL  
BEGIN  
SELECT 0 AS TotalRows,  
F.[RowNum],  
F.[Case],  
F.RequestNumber,  
F.Client,  
F.Member,  
F.Submitted,  
  
F.Elapsed,  
  
F.ServiceType,  
F.[Status] ,  
F.AssignedTo ,  
F.ClosedLoop ,  
F.PONumber ,  
  
F.ISPName ,  
F.CreateBy ,  
F.NextAction,  
F.MemberNumber,  
F.[Priority], 
F.ProgramName, 
F.ProgramID,
F.MemberID,
@openedCount AS [OpenedCount],  
@submittedCount AS [SubmittedCount],  
@cancelledcount AS [CancelledCount],  
@dispatchedCount AS [DispatchedCount],  
@completecount AS [CompleteCount],  
F.[Scheduled],
F.ScheduledOriginal ,	-- Added by Lakshmi- Queue Color
F.StatusDateModified  -- Added by Lakshmi  - Queue Color 
FROM #FinalResultsSorted F  
RETURN;  
END  
--------------------- BEGIN -----------------------------  
---- Create a temp variable or a CTE with the actual SQL search query ----------  
---- and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
-- LOGIC : BEGIN 

IF ( @isFHT = 0 )
BEGIN 
	
	INSERT INTO #FinalResultsFiltered
	SELECT  
			  DISTINCT  
			  SR.CaseID AS [Case],  
			  SR.ID AS [RequestNumber],  
			  CL.Name AS [Client],  
			  M.FirstName,
			  M.LastName,
			  M.MiddleName,
			  M.Suffix,
			  M.Prefix,     
			-- KB: Retain original values here for sorting  
			  sr.CreateDate AS SubmittedOriginal,
			-- KB: Retain original values here for sorting   
			  SR.SecondaryProductID,
			  PC.Name AS [ServiceType],  
			  SRS.Name As [Status],
			  SR.IsRedispatched,    
			  C.AssignedToUserID,
			  SR.NextActionAssignedToUserID,
			  CLS.[Description] AS [ClosedLoop],     
			  CONVERT(int,PO.PurchaseOrderNumber) AS [PONumber],  
			  V.Name AS [ISPName],  
			  SR.CreateBy AS [CreateBy],  
			  COALESCE(NA.Description,'') AS [NextAction],  
			  SR.NextActionID,  
			  SR.ClosedLoopStatusID as [ClosedLoopID],  
			  SR.ProductCategoryID as [ServiceTypeID],  
			  MS.MembershipNumber AS [MemberNumber],  
			  SR.ServiceRequestPriorityID AS [PriorityID],  
			  SRP.Name AS [Priority],   
			  sr.NextActionScheduledDate AS 'ScheduledOriginal', -- This field is used for Queue Color
			  P.ProgramName,
			  P.ProgramID,
			  M.ID AS MemberID,
			  SR.StatusDateModified			-- Added by Lakshmi	-Queue Color
	FROM [Case] C WITH (NOLOCK)
	JOIN [ServiceRequest] SR WITH (NOLOCK) ON C.ID = SR.CaseID  
	JOIN [ServiceRequestStatus] SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID  
	LEFT JOIN [ServiceRequestPriority] SRP WITH (NOLOCK) ON SR.ServiceRequestPriorityID = SRP.ID  
	JOIN dbo.fnc_GetProgramsForUser(@userID) P ON C.ProgramID = P.ProgramID  
	JOIN [Client] CL WITH (NOLOCK) ON P.ClientID = CL.ID  
	JOIN [Member] M WITH (NOLOCK) ON C.MemberID = M.ID  
	JOIN Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID  
	LEFT JOIN [ProductCategory] PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID  	
	LEFT JOIN (  
	SELECT ROW_NUMBER() OVER (PARTITION BY ServiceRequestID ORDER BY CreateDate DESC) AS RowNum,  
	ID,  
	PurchaseOrderNumber,  
	ServiceRequestID,  
	VendorLocationID   
	FROM PurchaseOrder WITH (NOLOCK)   
	WHERE --IsActive = 1 AND  
	PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WITH (NOLOCK) WHERE Name in ('Pending'))   
	AND (@PONumberValue IS NULL OR @PONumberValue = PurchaseOrderNumber)  
	) PO ON SR.ID = PO.ServiceRequestID AND PO.RowNum = 1  
	LEFT JOIN [NextAction] NA WITH (NOLOCK) ON SR.NextActionID=NA.ID  
	LEFT JOIN [VendorLocation] VL WITH (NOLOCK) ON PO.VendorLocationID = VL.ID  
	LEFT JOIN [Vendor] V WITH (NOLOCK) ON VL.VendorID = V.ID  
	LEFT JOIN (  
	SELECT ROW_NUMBER() OVER (PARTITION BY ELL.RecordID ORDER BY EL.CreateDate ASC) AS RowNum,  
	ELL.RecordID,  
	EL.EventID,  
	EL.CreateDate AS [Submitted]  
	FROM EventLog EL  WITH (NOLOCK) 
	JOIN EventLogLink ELL WITH (NOLOCK) ON EL.ID = ELL.EventLogID  
	JOIN [Event] E WITH (NOLOCK) ON EL.EventID = E.ID  
	JOIN [EventCategory] EC WITH (NOLOCK) ON E.EventCategoryID = EC.ID  
	WHERE ELL.EntityID = (SELECT ID FROM Entity WITH (NOLOCK) WHERE Name = 'ServiceRequest')  
	AND E.Name = 'SubmittedForDispatch'  
	) ELOG ON SR.ID = ELOG.RecordID AND ELOG.RowNum = 1  
	LEFT OUTER JOIN ClosedLoopStatus CLS WITH (NOLOCK) on CLS.ID=SR.ClosedLoopStatusID  

	WHERE	(@RequestNumberValue IS NOT NULL AND SR.ID = @RequestNumberValue)
	OR		(@RequestNumberValue IS NULL AND DATEDIFF(HH,SR.CreateDate,@now) <= @queueDisplayHours )--and SR.IsRedispatched is null  
END
ELSE
BEGIN
	
	INSERT INTO #FinalResultsFiltered	
	SELECT  
			DISTINCT  
			SR.CaseID AS [Case],  
			SR.ID AS [RequestNumber],  
			CL.Name AS [Client],  
			M.FirstName,
			M.LastName,
			M.MiddleName,
			M.Suffix,
			M.Prefix,     
			-- KB: Retain original values here for sorting  
			sr.CreateDate AS SubmittedOriginal,
			-- KB: Retain original values here for sorting   
			SR.SecondaryProductID,
			PC.Name AS [ServiceType],  
			SRS.Name As [Status],
			SR.IsRedispatched,    
			C.AssignedToUserID,
			SR.NextActionAssignedToUserID,
			CLS.[Description] AS [ClosedLoop],     
			CONVERT(int,PO.PurchaseOrderNumber) AS [PONumber],  
			V.Name AS [ISPName],  
			SR.CreateBy AS [CreateBy],  
			COALESCE(NA.Description,'') AS [NextAction],  
			SR.NextActionID,  
			SR.ClosedLoopStatusID as [ClosedLoopID],  
			SR.ProductCategoryID as [ServiceTypeID],  
			MS.MembershipNumber AS [MemberNumber],  
			SR.ServiceRequestPriorityID AS [PriorityID],  
			SRP.Name AS [Priority],   
			SR.NextActionScheduledDate AS 'ScheduledOriginal',		-- This field is used for Queue Color
			P.Name AS ProgramName,
			P.ID AS ProgramID,
			M.ID AS MemberID,
			SR.StatusDateModified			-- Added by Lakshmi	-Queue Color	
	FROM	ServiceRequest SR	
	JOIN	[ServiceRequestStatus] SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID  
	LEFT JOIN	[ServiceRequestPriority] SRP WITH (NOLOCK) ON SR.ServiceRequestPriorityID = SRP.ID 
	JOIN	[Case] C on C.ID = SR.CaseID
	JOIN	Program P on P.ID = C.ProgramID
	JOIN	[Client] CL WITH (NOLOCK) ON P.ClientID = CL.ID
	JOIN	[Member] M WITH (NOLOCK) ON C.MemberID = M.ID  
	JOIN	Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID  
	LEFT JOIN [ProductCategory] PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID    
	JOIN	PurchaseOrder PO on PO.ServiceRequestID = SR.ID 
							AND PO.PurchaseOrderStatusID IN 
							(SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued', 'Issued-Paid'))
	LEFT JOIN [NextAction] NA WITH (NOLOCK) ON SR.NextActionID=NA.ID 
	LEFT JOIN [VendorLocation] VL WITH (NOLOCK) ON PO.VendorLocationID = VL.ID  
	LEFT JOIN [Vendor] V WITH (NOLOCK) ON VL.VendorID = V.ID  
	LEFT OUTER JOIN ClosedLoopStatus CLS WITH (NOLOCK) on CLS.ID=SR.ClosedLoopStatusID 
	LEFT OUTER JOIN (
		SELECT	CLL.RecordID 
				FROM	ContactLogLink cll 
				JOIN	ContactLog cl ON cl.ID = cll.ContactLogID
				JOIN	ContactLogReason clr ON clr.ContactLogID = cl.ID
				WHERE	cll.EntityID = @serviceRequestEntityID
				AND clr.ContactReasonID = @fhtContactReasonID
	) CLSR ON CLSR.RecordID = SR.ID
	WHERE	CL.Name = 'Ford'
	AND		SR.ServiceRequestStatusID = @dispatchStatusID
	AND		@now between dateadd(mi,@StartMins,po.ETADate) and dateadd(mi,@EndMins,po.ETADate)   
	-- Filter out those SRs that has a contactlog record for HumanTouch.
	AND		CLSR.RecordID IS NULL
	
END

  
-- LOGIC : END  
  

  
  
INSERT INTO #FinalResultsFormatted  
SELECT  
T.[Case],  
T.RequestNumber,  
T.Client,  
-- CR : 1256
REPLACE(RTRIM(
  COALESCE(T.LastName,'')+  
  COALESCE(' ' + CASE WHEN T.Suffix = '' THEN NULL ELSE T.Suffix END,'')+  
  COALESCE(', '+ CASE WHEN T.FirstName = '' THEN NULL ELSE T.FirstName END,'' )+
  COALESCE(' ' + LEFT(T.MiddleName,1),'')
  ),'','') AS [Member],
--REPLACE(RTRIM(  
--  COALESCE(''+T.LastName,'')+  
--  COALESCE(''+ space(1)+ T.Suffix,'')+  
--  COALESCE(','+  space(1) + T.FirstName,'' )+  
--  COALESCE(''+ space(1) + left(T.MiddleName,1),'')  
--  ),'','') AS [Member],  
CONVERT(VARCHAR(3),DATENAME(MONTH,T.SubmittedOriginal)) + SPACE(1)+   
+''+CONVERT (VARCHAR(2),DATEPART(dd,T.SubmittedOriginal)) + SPACE(1) +   
+''+REPLACE(REPLACE(RIGHT('0'+LTRIM(RIGHT(CONVERT(VARCHAR,T.SubmittedOriginal,100),7)),7),'AM','AM'),'PM','PM')as [Submitted], 
T.SubmittedOriginal,  
CONVERT(VARCHAR(6),DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())/3600)+':'  
  +RIGHT('0'+CONVERT(VARCHAR(2),(DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())%3600)/60),2) AS [Elapsed],  
DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())/3600 + ((DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())%3600)/60) AS ElapsedOriginal,    
CASE  
	WHEN T.SecondaryProductID IS NOT NULL  
	THEN T.ServiceType + '+'  
	ELSE T.ServiceType 
END AS ServiceType,
CASE  
	WHEN T.IsRedispatched =1 then T.[Status] + '^'  
	ELSE T.[Status]  
END AS [Status],
CASE WHEN T.AssignedToUserID IS NOT NULL  
	THEN '*' + ISNULL(ASU.FirstName,'') + ' ' + ISNULL(ASU.LastName,'')  
	ELSE ISNULL(SASU.FirstName,'') + ' ' + ISNULL(SASU.LastName,'')  
END AS [AssignedTo],    
T.ClosedLoop,  
T.PONumber,  
T.ISPName,  
T.CreateBy,  
T.NextAction,  
T.MemberNumber,  
T.[Priority],  
CONVERT(VARCHAR(3),DATENAME(MONTH,T.ScheduledOriginal)) + SPACE(1)+   
  +''+CONVERT (VARCHAR(2),DATEPART(dd,T.ScheduledOriginal)) + SPACE(1) +   
  +''+REPLACE(REPLACE(RIGHT('0'+LTRIM(RIGHT(CONVERT(VARCHAR,T.ScheduledOriginal,100),7)),7),'AM','AM'),'PM','PM')as [Scheduled],
T.[ScheduledOriginal],		-- This field is used for Queue Color
T.ProgramName,
T.ProgramID,
T.MemberID,
T.StatusDateModified					--Added by Lakshmi - Queue Color
FROM #FinalResultsFiltered T
LEFT JOIN [User] ASU WITH (NOLOCK) ON T.AssignedToUserID = ASU.ID  
LEFT JOIN [User] SASU WITH (NOLOCK) ON T.NextActionAssignedToUserID = SASU.ID  
WHERE (
		( @CaseValue IS NULL OR @CaseValue = T.[Case])
		AND
		( @RequestNumberValue IS NULL OR @RequestNumberValue = T.RequestNumber)
		AND
		( @ServiceTypeValue IS NULL OR @ServiceTypeValue = T.ServiceTypeID)
		AND
		( @ISPNameValue IS NULL OR T.ISPName LIKE '%' + @ISPNameValue + '%')
		AND
		( @CreateByValue IS NULL OR T.CreateBy LIKE '%' + @CreateByValue + '%')
		
		AND
		( @ClosedLoopValue IS NULL OR T.ClosedLoopID = @ClosedLoopValue)
		AND
		( @NextActionValue IS NULL OR T.NextActionID = @NextActionValue)
		AND
		( @MemberNumberValue IS NULL OR @MemberNumberValue = T.MemberNumber)
		AND 
		( @PriorityValue IS NULL OR @PriorityValue = T.PriorityID)	
		AND 
		( @PONumberValue IS NULL OR @PONumberValue = T.PONumber)		
	)




INSERT INTO #FinalResultsSorted
SELECT	T.[Case],  
		T.RequestNumber,  
		T.Client,  
		T.Member,  
		T.Submitted,  
		T.SubmittedOriginal,  
		T.Elapsed,  
		T.ElapsedOriginal,  
		T.ServiceType,  
		T.[Status],  
		T.AssignedTo,  
		T.ClosedLoop,  
		T.PONumber,  
		T.ISPName,  
		T.CreateBy,  
		T.NextAction,  
		T.MemberNumber,  
		T.[Priority],  
		T.[Scheduled],  
		T.ScheduledOriginal,
		T.ProgramName,
		T.ProgramID,
		T.MemberID,
		T.StatusDateModified				--Added by Lakshmi
FROM	#FinalResultsFormatted T
WHERE	( 
			( @MemberValue IS NULL OR  T.Member LIKE '%' + @MemberValue  + '%')
			AND
			( @AssignedToValue IS NULL OR T.AssignedTo LIKE '%' + @AssignedToValue + '%' )
			AND
			( @StatusValue IS NULL OR T.[Status] IN (       
											SELECT T.StatusName FROM @tmpStatusInput T    
											)  
										)
		)

ORDER BY  
CASE WHEN @sortColumn = 'Case' AND @sortOrder = 'ASC'  
THEN T.[Case] END ASC,  
CASE WHEN @sortColumn = 'Case' AND @sortOrder = 'DESC'  
THEN T.[Case] END DESC ,  
  
CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'ASC'  
THEN T.RequestNumber END ASC,  
CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'DESC'  
THEN T.RequestNumber END DESC ,  
  
CASE WHEN @sortColumn = 'Client' AND @sortOrder = 'ASC'  
THEN T.Client END ASC,  
CASE WHEN @sortColumn = 'Client' AND @sortOrder = 'DESC'  
THEN T.Client END DESC ,  
  
CASE WHEN @sortColumn = 'Member' AND @sortOrder = 'ASC'  
THEN T.Member END ASC,  
CASE WHEN @sortColumn = 'Member' AND @sortOrder = 'DESC'  
THEN T.Member END DESC ,  
  
CASE WHEN @sortColumn = 'Submitted' AND @sortOrder = 'ASC'  
THEN T.SubmittedOriginal END ASC,  
CASE WHEN @sortColumn = 'Submitted' AND @sortOrder = 'DESC'  
THEN T.SubmittedOriginal END DESC ,  
  
CASE WHEN @sortColumn = 'FormattedElapsedTime' AND @sortOrder = 'ASC'  
THEN T.ElapsedOriginal END ASC,  
CASE WHEN @sortColumn = 'FormattedElapsedTime' AND @sortOrder = 'DESC'  
THEN T.ElapsedOriginal END DESC ,  
  
CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'ASC'  
THEN T.ServiceType END ASC,  
CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'DESC'  
THEN T.ServiceType END DESC ,  
  
CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'  
THEN T.[Status] END ASC,  
CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'  
THEN T.[Status] END DESC ,  
  
CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'ASC'  
THEN T.AssignedTo END ASC,  
CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'DESC'  
THEN T.AssignedTo END DESC ,  
  
CASE WHEN @sortColumn = 'ClosedLoop' AND @sortOrder = 'ASC'  
THEN T.ClosedLoop END ASC,  
CASE WHEN @sortColumn = 'ClosedLoop' AND @sortOrder = 'DESC'  
THEN T.ClosedLoop END DESC ,  
  
CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'  
THEN T.PONumber END ASC,  
CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'  
THEN T.PONumber END DESC ,  
  
CASE WHEN @sortColumn = 'ISPName' AND @sortOrder = 'ASC'  
THEN T.ISPName END ASC,  
CASE WHEN @sortColumn = 'ISPName' AND @sortOrder = 'DESC'  
THEN T.ISPName END DESC ,  
  
CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'  
THEN T.CreateBy END ASC,  
CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'  
THEN T.CreateBy END DESC,  
  
CASE WHEN @sortColumn = 'Scheduled' AND @sortOrder = 'ASC'  
THEN T.ScheduledOriginal END ASC,  
CASE WHEN @sortColumn = 'Scheduled' AND @sortOrder = 'DESC'  
THEN T.ScheduledOriginal END DESC,  

CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'ASC'  
THEN T.NextAction END ASC,  
CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'DESC'  
THEN T.NextAction END DESC   
  
DECLARE @count INT  
SET @count = 0  
SELECT @count = MAX(RowNum) FROM #FinalResultsSorted  
SET @endInd = @startInd + @pageSize - 1  
IF @startInd > @count  
BEGIN  
 DECLARE @numOfPages INT  
 SET @numOfPages = @count / @pageSize  
IF @count % @pageSize > 1  
BEGIN  
 SET @numOfPages = @numOfPages + 1  
END  
 SET @startInd = ((@numOfPages - 1) * @pageSize) + 1  
 SET @endInd = @numOfPages * @pageSize  
END  
  
SELECT [Status],  
  COUNT(*) AS [Total]  
INTO #tmpStatusSummary  
FROM #FinalResultsFiltered  
WHERE [Status] IN ('Entry','Submitted','Submitted^','Dispatched','Dispatched^','Complete','Complete^','Cancelled','Cancelled^')  
GROUP BY [Status]  
--DEBUG: SELECT * FROM #tmpStatusSummary   
  
SELECT @openedCount = [Total] FROM #tmpStatusSummary WHERE [Status] = 'Entry'  
SELECT @submittedCount = SUM([Total]) FROM #tmpStatusSummary WHERE [Status] IN ('Submitted','Submitted^')  
SELECT @dispatchedCount = SUM([Total]) FROM #tmpStatusSummary WHERE [Status] in ('Dispatched', 'Dispatched^')  
SELECT @completecount = SUM([Total]) FROM #tmpStatusSummary WHERE [Status] in ('Complete', 'Complete^')  
SELECT @cancelledcount = SUM([Total]) FROM #tmpStatusSummary WHERE [Status] in ('Cancelled', 'Cancelled^')  
  
UPDATE #FinalResultsSorted SET Elapsed = NULL WHERE [Status] IN ('Complete','Complete^','Cancelled','Cancelled^')  
  
SELECT @count AS TotalRows,   
F.[RowNum],  
F.[Case],  
F.RequestNumber,  
F.Client,  
F.Member,  
F.Submitted,  
  
F.Elapsed,  
  
F.ServiceType,  
F.[Status] ,  
F.AssignedTo ,  
F.ClosedLoop ,  
F.PONumber ,  
  
F.ISPName ,  
F.CreateBy ,  
F.NextAction,  
F.MemberNumber,  
F.[Priority],  
  
  ISNULL(@openedCount,0) AS [OpenedCount],  
  ISNULL(@submittedCount,0) AS [SubmittedCount],  
  ISNULL(@dispatchedCount,0) AS [DispatchedCount],  
  ISNULL(@completecount,0) AS [CompleteCount],  
  ISNULL(@cancelledcount,0) AS [CancelledCount],  
  F.[Scheduled],
  F.ProgramName,
  F.ProgramID,
  F.MemberID,
  F.StatusDateModified,				--Added by Lakshmi - Queue Color
  F.ScheduledOriginal				--Added by Lakshmi - Queue Color
  
FROM #FinalResultsSorted F  
WHERE F.RowNum BETWEEN @startInd AND @endInd  
  
DROP TABLE #FinalResultsFiltered  
DROP TABLE #FinalResultsFormatted
DROP TABLE #FinalResultsSorted
DROP TABLE #tmpStatusSummary  
  
  
END  
  


GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Details_For_Report_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Details_For_Report_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dbo].[dms_Vendor_Details_For_Report_Get] 190
 CREATE PROCEDURE [dbo].[dms_Vendor_Details_For_Report_Get](
 @vendorID INT
 )
 AS
 BEGIN
 
	DECLARE @vendorServicesPhoneNumber NVARCHAR(100) = NULL,
			@vendorServicesFaxNumber NVARCHAR(100) = NULL

	-- KB: TFS : 2433 - Fix the VendorServicesPhone and Fax numbers
	SET	@vendorServicesPhoneNumber	= (SELECT Value FROM ApplicationConfiguration WHERE Name = 'VendorServicesPhoneNumber')
	SET	@vendorServicesFaxNumber	= (SELECT Value FROM ApplicationConfiguration WHERE Name = 'VendorServicesFaxNumber')

	-- KB: Handle the case when there are multiple Office addresses and Business phone numbers.
	;WITH wBusinessAddresses
	AS
	(	
		SELECT	ROW_NUMBER() OVER (ORDER BY AE.ID DESC) AS RowNum,
				AE.*
		FROM	AddressEntity AE WITH (NOLOCK)
		WHERE	AE.RecordID = @vendorID AND AE.EntityID =
					  (SELECT     ID
						FROM          Entity
						WHERE      (Name = 'Vendor')) AND AE.AddressTypeID =
					  (SELECT     ID
						FROM          AddressType
						WHERE      (Name = 'Business'))
	),
	wOfficePhoneNumbers
	AS
	(
		SELECT	ROW_NUMBER() OVER (ORDER BY PE.ID DESC) AS RowNum,
				PE.*
		FROM	PhoneEntity PE WITH (NOLOCK)
		WHERE	PE.RecordID = @vendorID AND PE.EntityID =
					  (SELECT     ID
						FROM          Entity
						WHERE      (Name = 'Vendor')) AND PE.PhoneTypeID =
					  (SELECT     ID
						FROM          PhoneType
						WHERE      (Name = 'Office'))
	)
		
	SELECT     
			V.VendorNumber, 
			V.Name, 
			V.ContactFirstName AS VendorFirstName, 
			V.ContactLastName AS VendorLastName, 
			V.Email as VendorEmail,
			VR.Name as VendorRegionName,
			VR.ContactFirstName AS RepFirstName, 
			VR.ContactLastName AS RepLastName, 
			VR.Email as RepEmail, 
			dbo.fnc_FormatPhoneNumber(PE.PhoneNumber, 0) AS VendorPhoneNumber,
			dbo.fnc_FormatPhoneNumber(VR.PhoneNumber, 0) AS RepPhoneNumber, 
			dbo.fnc_FormatPhoneNumber(@vendorServicesPhoneNumber, 0) AS VendorRegionOffice, 
			dbo.fnc_FormatPhoneNumber(@vendorServicesFaxNumber,0) as VendorRegionFax,
			AE.Line1, 
			AE.Line2, 
			AE.Line3, 
			AE.City, 
			AE.StateProvince, 
			AE.CountryCode, 
			AE.PostalCode
	FROM    Vendor AS V WITH (NOLOCK)
	LEFT OUTER JOIN	VendorRegion AS VR WITH (NOLOCK) ON V.VendorRegionID = VR.ID 
	LEFT OUTER JOIN wBusinessAddresses AE WITH (NOLOCK) ON AE.RecordID = V.ID AND AE.RowNum = 1
	LEFT OUTER JOIN wOfficePhoneNumbers PE WITH (NOLOCK) ON PE.RecordID = V.ID AND PE.RowNum = 1	
	WHERE     (V.ID = @vendorID)
 
 END
 GO
GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_Details_Get @VendorInvoiceID=14329
 CREATE PROCEDURE [dbo].dms_Vendor_Invoice_Details_Get( 
	@VendorInvoiceID INT =NULL
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET FMTONLY OFF
    SELECT VI.ID
	, VI.VendorInvoiceStatusID
	, VIS.Name AS VendorInvoiceStatus
	, PO.PurchaseOrderNumber
	, V.VendorNumber
	, VI.InvoiceNumber
	, VI.InvoiceAmount
	, VI.InvoiceDate
	, VI.ReceivedDate
	, VI.ReceiveContactMethodID
	, VI.ActualETAMinutes
	, VI.Last8OfVIN
	, VI.VehicleMileage
	, VI.ToBePaidDate
	, VI.ExportDate
	, VI.ExportBatchID
	, VI.BillingBusinessName
	, VI.BillingContactName
	, VI.BillingAddressLine1
	, VI.BillingAddressLine2
	, VI.BillingAddressLine3
	, VI.BillingAddressCity
	, VI.BillingAddressStateProvince
	, VI.BillingAddressPostalCode
	, VI.BillingAddressCountryCode
	, PT.Name AS PaymentType
	, VI.PaymentDate AS PaymentDate
	, VI.PaymentAmount
	, VI.PaymentNumber
	, VI.CheckClearedDate AS CheckClearedDate
	, SS.Name AS SourceSystem
	, VI.CreateBy
	, VI.CreateDate
	, VI.ModifyBy
	, VI.ModifyDate
	, VI.VendorInvoicePaymentDifferenceReasonCodeID
	, V.ID AS VendorID
	, VI.GLExpenseAccount AS GLExpenseAccount
FROM VendorInvoice VI
JOIN VendorInvoiceStatus VIS ON VIS.ID = VI.VendorInvoiceStatusID
LEFT JOIN PaymentType PT ON PT.ID = VI.PaymentTypeID
JOIN Vendor V ON V.ID = VI.VendorID
JOIN PurchaseOrder PO ON PO.ID = VI.PurchaseOrderID
JOIN PurchaseOrderStatus POS ON POS.ID = PO.PurchaseOrderStatusID
LEFT JOIN SourceSystem SS ON SS.ID = VI.SourceSystemID
WHERE VI.ID = @VendorInvoiceID
END
GO

GO
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
 WHERE id = object_id(N'[dbo].[dms_vendor_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_vendor_list] @whereClauseXML="<ROW>\r\n  <Filter VendorNumber=\'1,4\' />\r\n</ROW>"
 
 CREATE PROCEDURE [dbo].[dms_vendor_list](
   
 @whereClauseXML NVARCHAR(4000) = NULL 

 , @startInd Int = 1 

 , @endInd BIGINT = 5000 

 , @pageSize int = 10  

 , @sortColumn nvarchar(100)  = 'VendorName' 

 , @sortOrder nvarchar(100) = 'ASC' 

  

 ) 

 AS 

 BEGIN   
 SET FMTONLY OFF  
  SET NOCOUNT ON  
  
CREATE TABLE #FinalResultsFiltered  
(  
 ContractStatus NVARCHAR(100) NULL,  
 VendorID INT NULL,  
 VendorNumber NVARCHAR(50) NULL,  
 VendorName NVARCHAR(255) NULL,  
 City NVARCHAR(100) NULL,  
 StateProvince NVARCHAR(10) NULL,  
 CountryCode NVARCHAR(2) NULL,  
 OfficePhone NVARCHAR(50) NULL,  
 AdminRating INT NULL,  
 InsuranceExpirationDate DATETIME NULL,  
 PaymentMethod NVARCHAR(50) NULL,  
 VendorStatus NVARCHAR(50) NULL,  
 VendorRegion NVARCHAR(50) NULL,  
 PostalCode NVARCHAR(20) NULL  ,
 POCount INT NULL
)  
  
CREATE TABLE #FinalResultsSorted  
(  
 RowNum BIGINT NOT NULL IDENTITY(1,1),  
 ContractStatus NVARCHAR(100) NULL,  
 VendorID INT NULL,  
 VendorNumber NVARCHAR(50) NULL,  
 VendorName NVARCHAR(255) NULL,  
 City NVARCHAR(100) NULL,  
 StateProvince NVARCHAR(10) NULL,  
 CountryCode NVARCHAR(2) NULL,  
 OfficePhone NVARCHAR(50) NULL,  
 AdminRating INT NULL,  
 InsuranceExpirationDate DATETIME NULL,  
 PaymentMethod NVARCHAR(50) NULL,  
 VendorStatus NVARCHAR(50) NULL,  
 VendorRegion NVARCHAR(50) NULL,  
 PostalCode NVARCHAR(20) NULL ,
 POCount INT NULL 
)  
  
DECLARE @idoc int  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
VendorNameOperator NVARCHAR(50) NULL,  
VendorName NVARCHAR(MAX) NULL,  
VendorNumber NVARCHAR(50) NULL,  
CountryID INT NULL,  
StateProvinceID INT NULL,  
City nvarchar(255) NULL,  
VendorStatus NVARCHAR(100) NULL,  
VendorRegion NVARCHAR(100) NULL,  
PostalCode NVARCHAR(20) NULL,  
IsLevy BIT NULL  ,
HasPO BIT NULL
)  
  
DECLARE @VendorNameOperator NVARCHAR(50) ,  
@VendorName NVARCHAR(MAX) ,  
@VendorNumber NVARCHAR(50) ,  
@CountryID INT ,  
@StateProvinceID INT ,  
@City nvarchar(255) ,  
@VendorStatus NVARCHAR(100) ,  
@VendorRegion NVARCHAR(100) ,  
@PostalCode NVARCHAR(20) ,  
@IsLevy BIT,
@HasPO BIT   
  
INSERT INTO @tmpForWhereClause  
SELECT    
 VendorNameOperator,  
 VendorName ,  
 VendorNumber,  
 CountryID,  
 StateProvinceID,  
 City,  
 VendorStatus,  
 VendorRegion,  
    PostalCode,  
    IsLevy ,
	HasPo
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
 VendorNameOperator NVARCHAR(50),  
 VendorName NVARCHAR(MAX),  
 VendorNumber NVARCHAR(50),   
 CountryID INT,  
 StateProvinceID INT,  
 City nvarchar(255),   
 VendorStatus NVARCHAR(100),  
 VendorRegion NVARCHAR(100),  
 PostalCode NVARCHAR(20),  
 IsLevy BIT ,
 HasPo BIT
)   
  
SELECT    
  @VendorNameOperator = VendorNameOperator ,  
  @VendorName = VendorName ,  
  @VendorNumber = VendorNumber,  
  @CountryID = CountryID,  
  @StateProvinceID = StateProvinceID,  
  @City = City,  
  @VendorStatus = VendorStatus,  
  @VendorRegion = VendorRegion,  
  @PostalCode = PostalCode,  
  @IsLevy = IsLevy  ,
  @HasPO = HasPO
FROM @tmpForWhereClause  
  
--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
-- LOGIC : START  

DECLARE @PoCount AS TABLE(VendorID INT NULL,PoCount INT NULL)
INSERT INTO @PoCount
SELECT V.ID,
	   COUNT(PO.ID) FROM PurchaseOrder PO 
	   LEFT JOIN VendorLocation VL ON PO.VendorLocationID = VL.ID
	   LEFT JOIN Vendor V ON VL.VendorID = V.ID
WHERE  PO.IsActive = 1
GROUP BY V.ID 
  
DECLARE @vendorEntityID INT, @businessAddressTypeID INT, @officePhoneTypeID INT  
SELECT @vendorEntityID = ID FROM Entity WHERE Name = 'Vendor'  
SELECT @businessAddressTypeID = ID FROM AddressType WHERE Name = 'Business'  
SELECT @officePhoneTypeID = ID FROM PhoneType WHERE Name = 'Office'  
  
;WITH wVendorAddresses  
AS  
(   
 SELECT ROW_NUMBER() OVER ( PARTITION BY RecordID, AddressTypeID ORDER BY ID ) AS RowNum,  
   *  
 FROM AddressEntity   
 WHERE EntityID = @vendorEntityID  
 AND  AddressTypeID = @businessAddressTypeID  
),
wVendorPhone
AS

(

	SELECT ROW_NUMBER() OVER ( PARTITION BY RecordID, PhoneTypeID ORDER BY ID DESC ) AS RowNum,

			*

	FROM	PhoneEntity 

	WHERE	EntityID = @vendorEntityID

	AND		PhoneTypeID = @officePhoneTypeID

)

INSERT INTO #FinalResultsFiltered  
SELECT DISTINCT  
  --CASE WHEN C.VendorID IS NOT NULL   
  --  THEN 'Contracted'   
  --  ELSE 'Not Contracted'   
  --  END AS ContractStatus  
  --NULL As ContractStatus  
  CASE  
   WHEN ContractedVendors.ContractID IS NOT NULL   
    AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'  
   ELSE 'Not Contracted'   
  END AS ContractStatus  
  , V.ID AS VendorID  
  , V.VendorNumber AS VendorNumber  
  , V.Name AS VendorName  
  , AE.City AS City  
  , AE.StateProvince AS State  
  , AE.CountryCode AS Country  
  , PE.PhoneNumber AS OfficePhone  
  , V.AdministrativeRating AS AdminRating  
  , V.InsuranceExpirationDate AS InsuranceExpirationDate  
  , VACH.BankABANumber AS PaymentMethod -- To be calculated in the next step.  
  , VS.Name AS VendorStatus  
  , VR.Name AS VendorRegion  
  , AE.PostalCode  
  , ISNULL((SELECT PoCount FROM @PoCount POD WHERE POD.VendorID = V.ID),0) AS POCount
FROM Vendor V WITH (NOLOCK)  
--LEFT JOIN   VendorLocation VL ON V.ID = VL.VendorID
--LEFT JOIN   PurchaseOrder PO ON VL.ID = PO.VendorLocationID AND ISNULL(PO.IsActive,0) = 1
LEFT JOIN wVendorAddresses AE ON AE.RecordID = V.ID AND AE.RowNum = 1  
LEFT JOIN	wVendorPhone PE ON PE.RecordID = V.ID AND PE.RowNum = 1  
LEFT JOIN VendorStatus VS ON VS.ID = V.VendorStatusID  
LEFT JOIN VendorACH VACH ON VACH.VendorID = V.ID  
LEFT JOIN VendorRegion VR ON VR.ID=V.VendorRegionID  
LEFT OUTER JOIN(  
   SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID  
   FROM dbo.fnGetContractedVendors() cv  
   ) ContractedVendors ON v.ID = ContractedVendors.VendorID   
--LEFT OUTER JOIN (SELECT VendorID, MAX(CreateDate) AS [CreateDate] FROM [Contract] WHERE IsActive = 1 GROUP BY VendorID) C ON C.VendorID = V.ID  =
WHERE V.IsActive = 1  -- Not deleted    
AND  (@VendorNumber IS NULL OR @VendorNumber = V.VendorNumber)  
AND  (@CountryID IS NULL OR @CountryID = AE.CountryID)  
AND  (@StateProvinceID IS NULL OR @StateProvinceID = AE.StateProvinceID)  
AND  (@City IS NULL OR @City = AE.City)  
AND  (@PostalCode IS NULL OR @PostalCode = AE.PostalCode)  
AND  (@IsLevy IS NULL OR @IsLevy = ISNULL(V.IsLevyActive,0))  
AND  (@VendorStatus IS NULL OR VS.ID IN (SELECT Item FROM [dbo].[fnSplitString](@VendorStatus,',') ) )  
AND  (@VendorRegion IS NULL OR VR.ID IN (SELECT Item FROM [dbo].[fnSplitString](@VendorRegion,',') ) )  
AND  (    
   (@VendorNameOperator IS NULL )  
   OR  
   (@VendorNameOperator = 'Begins with' AND V.Name LIKE  @VendorName + '%')  
   OR  
   (@VendorNameOperator = 'Is equal to' AND V.Name =  @VendorName )  
   OR  
   (@VendorNameOperator = 'Ends with' AND V.Name LIKE  '%' + @VendorName)  
   OR  
   (@VendorNameOperator = 'Contains' AND V.Name LIKE  '%' + @VendorName + '%')  
  )  
 --GROUP BY 

	--	ContractStatus,
	--	V.ID,
	--	V.VendorNumber,
	--	V.Name,
	--	AE.City,
	--	AE.StateProvince,
	--	AE.CountryCode,
	--	PE.PhoneNumber,
	--	V.AdministrativeRating,
	--	V.InsuranceExpirationDate,
	--	VACH.BankABANumber,
	--	VS.Name,
	--	VR.Name,
	--	AE.PostalCode,
	--	ContractedVendors.ContractRateScheduleID,
	--	ContractedVendors.ContractID
 --UPDATE #FinalResultsFiltered  
 --SET ContractStatus = CASE WHEN C.VendorID IS NOT NULL   
 --      THEN 'Contracted'   
 --      ELSE 'Not Contracted'   
 --      END,  
 -- PaymentMethod =  CASE  
 --      WHEN ISNULL(F.PaymentMethod,'') = '' THEN 'Check'  
 --      ELSE 'DirectDeposit'  
 --      END  
 --FROM #FinalResultsFiltered F  
 --LEFT OUTER JOIN (SELECT VendorID, MAX(CreateDate) AS [CreateDate] FROM [Contract] WHERE IsActive = 1 GROUP BY VendorID) C ON C.VendorID = F.VendorID  
   
 INSERT INTO #FinalResultsSorted  
 SELECT   ContractStatus  
  , VendorID  
  , VendorNumber  
  , VendorName  
  , City  
  , StateProvince  
  , CountryCode  
  , OfficePhone  
  , AdminRating  
  , InsuranceExpirationDate  
  , PaymentMethod  
  , VendorStatus  
  , VendorRegion  
  , PostalCode  
  , POCount
 FROM #FinalResultsFiltered T   
 WHERE	(@HasPO IS NULL OR @HasPO = 0 OR T.POCount > 0)
 ORDER BY   
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'ASC'  
  THEN T.ContractStatus END ASC,   
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'DESC'  
  THEN T.ContractStatus END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'ASC'  
  THEN T.VendorID END ASC,   
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'DESC'  
  THEN T.VendorID END DESC ,  
    
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'  
  THEN T.VendorNumber END ASC,   
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'  
  THEN T.VendorNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'ASC'  
  THEN T.VendorName END ASC,   
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'DESC'  
  THEN T.VendorName END DESC ,  
  
  CASE WHEN @sortColumn = 'City' AND @sortOrder = 'ASC'  
  THEN T.City END ASC,   
  CASE WHEN @sortColumn = 'City' AND @sortOrder = 'DESC'  
  THEN T.City END DESC ,  
    
  CASE WHEN @sortColumn = 'StateProvince' AND @sortOrder = 'ASC'  
  THEN T.StateProvince END ASC,   
  CASE WHEN @sortColumn = 'StateProvince' AND @sortOrder = 'DESC'  
  THEN T.StateProvince END DESC ,  
  
  CASE WHEN @sortColumn = 'CountryCode' AND @sortOrder = 'ASC'  
  THEN T.CountryCode END ASC,   
  CASE WHEN @sortColumn = 'CountryCode' AND @sortOrder = 'DESC'  
  THEN T.CountryCode END DESC ,  
    
  CASE WHEN @sortColumn = 'OfficePhone' AND @sortOrder = 'ASC'  
  THEN T.OfficePhone END ASC,   
  CASE WHEN @sortColumn = 'OfficePhone' AND @sortOrder = 'DESC'  
  THEN T.OfficePhone END DESC ,  
    
  CASE WHEN @sortColumn = 'AdminRating' AND @sortOrder = 'ASC'  
  THEN T.AdminRating END ASC,   
  CASE WHEN @sortColumn = 'AdminRating' AND @sortOrder = 'DESC'  
  THEN T.AdminRating END DESC ,  
    
  CASE WHEN @sortColumn = 'InsuranceExpirationDate' AND @sortOrder = 'ASC'  
  THEN T.InsuranceExpirationDate END ASC,   
  CASE WHEN @sortColumn = 'InsuranceExpirationDate' AND @sortOrder = 'DESC'  
  THEN T.InsuranceExpirationDate END DESC ,  
    
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'ASC'  
  THEN T.VendorStatus END ASC,   
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'DESC'  
  THEN T.VendorStatus END DESC ,  
    
  CASE WHEN @sortColumn = 'VendorRegion' AND @sortOrder = 'ASC'  
  THEN T.VendorRegion END ASC,   
  CASE WHEN @sortColumn = 'VendorRegion' AND @sortOrder = 'DESC'  
  THEN T.VendorRegion END DESC ,  
  --VendorRegion  
  CASE WHEN @sortColumn = 'PaymentMethod' AND @sortOrder = 'ASC'  
  THEN T.PaymentMethod END ASC,   
  CASE WHEN @sortColumn = 'PaymentMethod' AND @sortOrder = 'DESC'  
  THEN T.PaymentMethod END DESC ,  
     
  CASE WHEN @sortColumn = 'PostalCode' AND @sortOrder = 'ASC'  
  THEN T.PostalCode END ASC,   
  CASE WHEN @sortColumn = 'PostalCode' AND @sortOrder = 'DESC'  
  THEN T.PostalCode END DESC   ,
  
  CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'
	THEN T.POCount END ASC, 
	CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'
	 THEN T.POCount END DESC 

   
  
DECLARE @count INT     
SET @count = 0     
SELECT @count = MAX(RowNum) FROM #FinalResultsSorted  
SET @endInd = @startInd + @pageSize - 1  
IF @startInd  > @count     
BEGIN     
 DECLARE @numOfPages INT      
 SET @numOfPages = @count / @pageSize     
 IF @count % @pageSize > 1     
 BEGIN     
  SET @numOfPages = @numOfPages + 1     
 END     
 SET @startInd = ((@numOfPages - 1) * @pageSize) + 1     
 SET @endInd = @numOfPages * @pageSize     
END  
  
SELECT @count AS TotalRows, * FROM #FinalResultsSorted WHERE RowNum BETWEEN @startInd AND @endInd  
  
END  
GO
