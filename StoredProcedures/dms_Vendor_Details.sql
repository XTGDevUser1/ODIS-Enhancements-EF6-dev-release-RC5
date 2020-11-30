 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Details]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Details] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
--EXEC dms_Vendor_Details null,null,null,'Destination'
 CREATE PROCEDURE [dbo].[dms_Vendor_Details](     
 -- Add the parameters for the stored procedure here    
   @VendorSearchID int    
    , @VendorSearchLocationID int 
    , @ServiceRequestID int
    , @SearchFrom nvarchar(50) = NULL
        )    
AS    
BEGIN    

 SET NOCOUNT ON;    
 SET FMTONLY OFF;
  
DECLARE       
	@ServiceLocationLatitude decimal(10,7)   
    ,@ServiceLocationLongitude decimal(10,7)    
    ,@ServiceLocationStateProvince nvarchar(2)  
    ,@ServiceLocationCountryCode nvarchar(10)   
    ,@DestinationLocationLatitude decimal(10,7)    
    ,@DestinationLocationLongitude decimal(10,7)  
  
-- Get service information from ServiceRequest  
SELECT         
	@ServiceLocationLatitude = SR.ServiceLocationLatitude,  
    @ServiceLocationLongitude = SR.ServiceLocationLongitude,  
    @ServiceLocationStateProvince = SR.ServiceLocationStateProvince,  
    @ServiceLocationCountryCode = SR.ServiceLocationCountryCode,  
    @DestinationLocationLatitude = SR.DestinationLatitude,  
    @DestinationLocationLongitude = SR.DestinationLongitude
FROM  ServiceRequest SR   
WHERE SR.ID = @ServiceRequestID  

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
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    

   SELECT     
  v.ID AS VendorID    
 ,vl.ID AS VendorLocationID    
 ,vl.Sequence AS VendorSequence     
 ,v.VendorNumber     
 ,v.Name AS VendorName    
 ,ae.Line1 as VendorAddress1    
 ,ae.Line2 as VendorAddress2     
 , pe24.PhoneNumber AS VendorDispatchNumber    
 , peOfc.PhoneNumber AS VendorOfficeNumber    
 , peFax.PhoneNumber AS VendorFaxNumber    
 ,ae.PostalCode AS VendorPostalCode     
 ,ae.CountryID AS VendorCountry    
 ,ae.StateProvinceID AS VendorState    
 ,ae.City AS VendorCity    
 ,v.Email AS VendorEmail  
 -- If vendor location is empty, don't attempt to calculate the enroute miles.
 ,CASE	WHEN (vl.Latitude IS NULL OR vl.Longitude IS NULL) OR (vl.Latitude = 0 AND vl.Longitude = 0) THEN 0
		ELSE ISNULL(ROUND(vl.GeographyLocation.STDistance(
						CASE	WHEN ISNULL(@SearchFrom, '') = 'Destination' 
								THEN @DestinationLocation ELSE @ServiceLocation 
								END
						)/1609.344,1),0) 
		END AS  EnrouteMiles    
     
FROM VendorLocation vl    
INNER JOIN Vendor v on v.ID = vl.VendorID    
LEFT OUTER JOIN AddressEntity ae on ae.RecordID = vl.ID and ae.EntityID = (Select ID From Entity Where Name = 'VendorLocation')     
LEFT OUTER JOIN PhoneEntity pe24 on pe24.RecordID = vl.ID and pe24.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and pe24.PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')    
Left Outer Join PhoneEntity peFax on peFax.RecordID = vl.ID and peFax.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and peFax.PhoneTypeID = (Select ID From PhoneType Where Name = 'Fax')    
LEFT OUTER JOIN PhoneEntity peOfc on peOfc.RecordID = v.ID and peOfc.EntityID = (Select ID From Entity Where Name = 'Vendor') and peOfc.PhoneTypeID = (Select ID From PhoneType Where Name = 'Office')    
LEFT OUTER JOIN [Contract] c on c.VendorID = v.ID and c.IsActive = 1    
WHERE     
v.ID=@VendorSearchID AND vl.ID=@VendorSearchLocationID    
     
END    
  