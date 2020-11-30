 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ServiceFacilitySelection_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
DROP PROCEDURE [dbo].[dms_ServiceFacilitySelection_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  
 -- EXEC [dms_ServiceFacilitySelection_get] 1, 32.780122,-96.801412,'General RV,Ford F350,Ford F450,Ford F550,Ford F650,Ford F750',300
CREATE PROCEDURE [dbo].[dms_ServiceFacilitySelection_get]  
 @programID INT	= NULL
 ,@ServiceLocationLatitude decimal(10,7)  = 0
 ,@ServiceLocationLongitude decimal(10,7)  = 0
 ,@ProductList nvarchar(4000) = NULL--comma delimited list of product names  
 ,@SearchRadiusMiles int  = NULL
AS  
BEGIN  

	--Declare
	--@programID INT =437,
	--@ServiceLocationLatitude decimal(10,7)=36.314529,
	--@ServiceLocationLongitude decimal(10,7)=-76.217567,
	--@ProductList nvarchar(4000)=N'Ford F350,Ford F450',
	--@SearchRadiusMiles int=300

	SET FMTONLY OFF;
	CREATE TABLE #tmpServiceFacilitySelection(
		[VendorID] [int] NOT NULL,
		[VendorName] [nvarchar](255) NULL,
		[VendorNumber] [nvarchar](50) NULL,
		[AdministrativeRating] [int] NULL,
		[VendorLocationID] [int] NOT NULL,
		[PhoneNumber] [nvarchar](50) NULL,
		[EnrouteMiles] [float] NULL,
		[Address1] [nvarchar](100) NULL,
		[Address2] [nvarchar](100) NULL,
		[City] [nvarchar](100) NULL,
		[PostalCode] [nvarchar](20) NULL,
		[StateProvince] [nvarchar](50) NULL,
		[Country] [nvarchar](2) NULL,
		[GeographyLocation] [geography] NULL,		
		[AllServices] [nvarchar](max) NULL,
		[Comments] [nvarchar](max) NULL,
		[FaxPhoneNumber] [nvarchar](50) NULL,
		[OfficePhoneNumber] [nvarchar](50) NULL,
		[CellPhoneNumber] [nvarchar](50) NULL,		
		[IsPreferred] BIT NULL,
		[Rating] DECIMAL(5,2) NULL
	) 


	IF @programID IS NULL
	BEGIN
		
		SELECT * FROM #tmpServiceFacilitySelection
		RETURN;
	END
	--Declare @ProductList as nvarchar(200)  
	--Declare @ServiceLocationLatitude as decimal(10,7)  
	--Declare @ServiceLocationLongitude as decimal(10,7)  
	--Declare @SearchRadiusMiles int  
	--Set @ServiceLocationLatitude = 32.780122   
	--Set @ServiceLocationLongitude = -96.801412  
	--Set @ProductList = 'Diesel, Airstream, Winnebago' --'Ford F350,Ford F450,Ford F550,Ford F650,Ford F750'  
	--Set @SearchRadiusMiles = 200  
   
	DECLARE @strProductList nvarchar(max)  
	SET @strProductList = REPLACE(@ProductList,',',''',''')  
	SET @strProductList = '''' + @strProductList + ''''  
	DECLARE @tblProductList TABLE (ProductID int)  
	DECLARE @sqlStmt nvarchar(max)  
	SET @sqlStmt = N'SELECT ID FROM dbo.Product WHERE Name IN (' + @strProductList + N')'  
   
	INSERT INTO @tblProductList (ProductID)  
	EXEC sp_executesql @sqlStmt  
   
	Declare @ServiceLocation as geography  
	Set @ServiceLocation = geography::Point(@ServiceLocationLatitude, @ServiceLocationLongitude, 4326)  
	DECLARE  @VendorEntityID int  
			,@VendorLocationEntityID int  
			,@ServiceRequestEntityID int  
			,@BusinessAddressTypeID int  
			,@DispatchPhoneTypeID int  
			,@FaxPhoneTypeID int
			,@OfficePhoneTypeID int  
			,@CellPhoneTypeID int 
			,@ContactCategoryID INT 
			,@ActiveVendorStatusID int
			,@ActiveVendorLocationStatusID int

	SET @VendorEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'Vendor')  
	SET @VendorLocationEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'VendorLocation')  
	SET @ServiceRequestEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'ServiceRequest')  
	SET @BusinessAddressTypeID = (SELECT ID FROM dbo.AddressType WHERE Name = 'Business')  

	SET @FaxPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Fax')  
	SET @OfficePhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Office')  
	SET @CellPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Cell')    
 
	SET @DispatchPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Dispatch')  
	SET @ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ServiceLocationSelection')  

	SET @ActiveVendorStatusID = (SELECT ID FROM dbo.VendorStatus WHERE Name = 'Active')    
	SET @ActiveVendorLocationStatusID = (SELECT ID FROM dbo.VendorLocationStatus WHERE Name = 'Active')    

	-- Determine the vendors/ vendorlocations for the search.
   
	Select   
			v.ID VendorID  
			--,v.Name + CASE WHEN v.DealerNumber IS NOT NULL THEN ' *** DLR#: ' + v.DealerNumber ELSE N'' END  VendorName  
			/*KB: There is no DealerNumber in Vendor table now. + CASE WHEN v.DealerNumber IS NOT NULL THEN ' *** Ford Direct Tow' ELSE N'' END */   
			--,v.Name + CASE WHEN @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Direct Tow') AND vlp.ID IS NOT NULL AND vl.DealerNumber IS NOT NULL AND vl.PartsAndAccessoryCode IS NOT NULL 
			--	THEN ' (DT)' ELSE '' END VendorName
			,v.Name + COALESCE(F.Indicators,'') AS VendorName
			,v.VendorNumber  
			,v.AdministrativeRating  
			,vl.ID VendorLocationID  
			--,vl.Sequence  
			,ph.PhoneNumber PhoneNumber  
			,ROUND(vl.GeographyLocation.STDistance(@ServiceLocation)/1609.344,1) EnrouteMiles  
			,addr.Line1 Address1  
			,addr.Line2 Address2  
			,addr.City  
			,addr.PostalCode  
			--,addr.StateProvince,  
			,SP.Name as StateProvince    
			,Cn.ISOCode as Country  
			,vl.GeographyLocation
			,vl.DispatchNote
	Into	#tmpVendors				
	From	dbo.VendorLocation vl   
	LEFT JOIN [dbo].[fnc_GetVendorIndicators]('VendorLocation') F ON vl.ID = F.RecordID
	Join	dbo.Vendor v  On vl.VendorID = v.ID  
	Join	dbo.[AddressEntity] addr On addr.EntityID = @VendorLocationEntityID and addr.RecordID = vl.ID and addr.AddressTypeID = @BusinessAddressTypeID  
	Join	dbo.Country Cn On addr.CountryID = Cn.ID    
	Join	dbo.StateProvince SP on addr.StateProvinceID = SP.ID    
	Left Outer Join dbo.[PhoneEntity] ph On ph.EntityID = @VendorLocationEntityID and ph.RecordID = vl.ID and ph.PhoneTypeID = @DispatchPhoneTypeID 
	Left Outer Join VendorLocationProduct vlp on vlp.VendorLocationID = vl.ID and vlp.ProductID = (Select ID from Product where Name = 'Ford Direct Tow') and vlp.IsActive = 1

	WHERE	v.IsActive = 1 
	AND		v.VendorStatusID = @ActiveVendorStatusID  
	and		vl.IsActive = 1 
	AND		vl.VendorLocationStatusID = @ActiveVendorLocationStatusID  
	and		vl.GeographyLocation.STDistance(@ServiceLocation) <= @SearchRadiusMiles * 1609.344  
	and		Exists (  
					Select	*  
					From	VendorLocation vl1 
					Join	VendorLocationProduct vlp on vlp.VendorLocationID = vl1.ID and vlp.IsActive = 1
					Join	VendorProduct vp on vp.VendorID = vl1.VendorID and vp.ProductID = vlp.ProductID and vp.IsActive = 1 
					Join	@tblProductList pl On vlp.ProductID = pl.ProductID  
					Where	vp.IsActive = 1 
					and		vlp.IsActive = 1
					and		vlp.VendorLocationID = vl.ID
				)  
	--NOT IN USE: Order by ROUND(vl.GeographyLocation.STDistance(@ServiceLocation)/1609.344,1)  
	AND addr.Line1 NOT LIKE '%PO BOX%'
	AND addr.line1 NOT LIKE '%POBOX%'
	AND addr.line1 NOT LIKE '%P.O. BOX%'
	AND addr.line1 NOT LIKE '%P.O.BOX%'
	AND addr.line1 NOT LIKE '%P.O BOX%'
	AND addr.line1 NOT LIKE '%P.OBOX%'
	AND addr.line1 NOT LIKE '%PO. BOX%'
	AND addr.line1 NOT LIKE '%PO.BOX%'
	AND addr.line1 NOT LIKE '%P O BOX%'
	AND addr.line1 NOT LIKE '%BOX %'
	AND addr.line1 NOT LIKE '% BOX%'
	AND addr.line1 NOT LIKE '% BOX %'
 
 
	INSERT INTO #tmpServiceFacilitySelection (
			[VendorID],
			[VendorName],
			[VendorNumber],
			[AdministrativeRating],
			[VendorLocationID],
			[PhoneNumber],
			[EnrouteMiles],
			[Address1],
			[Address2],
			[City],
			[PostalCode],
			[StateProvince],
			[Country],
			[GeographyLocation],												
			[AllServices],
			[Comments],
			[FaxPhoneNumber],
			[OfficePhoneNumber],
			[CellPhoneNumber],
			[IsPreferred],
			[Rating]
			)
	SELECT  W.VendorID  
			,W.VendorName
			,W.VendorNumber  
			,W.AdministrativeRating  
			,W.VendorLocationID  
			,W.PhoneNumber  
			,W.EnrouteMiles  
			,W.Address1  
			,W.Address2  
			,W.City  
			,W.PostalCode  
			,W.StateProvince    
			,W.Country
			,W.GeographyLocation
			,VP.AllServices
			,W.DispatchNote Comments
			,Faxph.PhoneNumber AS FaxPhoneNumber
			,Officeph.PhoneNumber AS OfficePhoneNumber
			,Cellph.PhoneNumber AS CellPhoneNumber
			,NULL
			,NULL 
   
	FROM	#tmpVendors W  
	LEFT JOIN   
	(  
		SELECT vl.VendorID,  
		vl.ID,   
		[dbo].[fnConcatenate](p.Name) AS AllServices  
		FROM VendorLocation vl  
		JOIN VendorLocationProduct vlp on vlp.VendorLocationID = vl.ID  
		JOIN Product p on p.ID = vlp.ProductID  
		WHERE vlp.IsActive = 1
		GROUP BY vl.VendorID,vl.ID  
		) VP ON W.VendorID = VP.VendorID AND W.VendorLocationID = VP.ID  
	---- Get last ContactLog result for the current sevice request for the ISP  
	--LEFT OUTER JOIN (    
	--	SELECT RecordID,  
	--	[dbo].[fnConcatenate](REPLACE([Description],',','~') +  
	--			+ ' <LF> ' + ISNULL(CreateBy,'') + ' | ' + COALESCE( CONVERT( VARCHAR(10), GETDATE(), 101) +  
	--	STUFF( RIGHT( CONVERT( VARCHAR(26), GETDATE(), 109 ), 15 ), 10, 4, ' ' ),'')) AS [Comments]            
	--	FROM Comment         
	--	WHERE EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')  
	--	AND  [Description] IS NOT NULL  
	--	GROUP BY RecordID   
	--	) CMT ON CMT.RecordID = W.VendorLocationID  

	-- Get all other phone numbers.
	LEFT OUTER JOIN  dbo.[PhoneEntity] Faxph   
						ON Faxph.EntityID = @VendorLocationEntityID AND Faxph.RecordID = W.VendorLocationID AND Faxph.PhoneTypeID = @FaxPhoneTypeID  
	-- CR : 1226 - Office phone number of the vendor and not vendor location.
	LEFT OUTER JOIN  dbo.[PhoneEntity] Officeph   
						ON Officeph.EntityID = @VendorEntityID AND Officeph.RecordID = W.VendorID AND Officeph.PhoneTypeID = @OfficePhoneTypeID

	LEFT OUTER JOIN  dbo.[PhoneEntity] Cellph   -- CR: 1226
						ON Cellph.EntityID = @VendorLocationEntityID AND Cellph.RecordID = W.VendorLocationID AND Cellph.PhoneTypeID = @CellPhoneTypeID  

	--ORDER BY ROUND(W.GeographyLocation.STDistance(@ServiceLocation)/1609.344,1)  

	-- Update the temp table with preferred and score if only the user is searching by RV House or Make attributes / product subtypes.
	DECLARE @isProgramConfiguredForPreferredProduct BIT = 0,
			@isAgentSearchingByRVOrMake BIT = 0,
			@serviceLocationPreferredProduct INT = NULL

	SELECT	@isProgramConfiguredForPreferredProduct = CAST(1 AS BIT),
			@serviceLocationPreferredProduct = CONVERT(INT,RS.Value)
	FROM	(
				SELECT	PC.Name,
						PC.Value
				FROM	[dbo].[fnc_GetProgramConfigurationForProgram](@ProgramID,'Application') P 
				JOIN	ProgramConfiguration pc ON p.ProgramConfigurationID = pc.id
			) RS
	WHERE	RS.Name = 'ServiceLocationPreferredProduct' 

	SELECT	@isAgentSearchingByRVOrMake = CAST(1 AS BIT)
	FROM	(
				SELECT	PST.Name
				FROM	[dbo].[fnSplitString](@ProductList,',') PL 
				JOIN	Product P ON P.Name = PL.item
				JOIN	ProductSubType PST ON P.ProductSubTypeID = PST.ID

			) RS
	WHERE	RS.Name IN ('RVHouse', 'Make')

	
	IF (@isProgramConfiguredForPreferredProduct = 1 AND @isAgentSearchingByRVOrMake = 1)
	BEGIN
		PRINT 'Considering ServiceLocationPreferredProduct'
		
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
		WHERE ProductID = (SELECT ID FROM Product WHERE Name = 'CoachNet Dealer Partner')


		-- Update the preferred indicator and the rating.
		UPDATE	#tmpServiceFacilitySelection
		SET		IsPreferred = 1,
				Rating = VLP.Rating
		FROM	#tmpServiceFacilitySelection T
		JOIN	VendorLocationProduct VLP ON T.VendorLocationID = VLP.VendorLocationID 
		WHERE	VLP.ProductID =  @serviceLocationPreferredProduct

		UPDATE #tmpServiceFacilitySelection
		SET		IsPreferred = 0
		WHERE	IsPreferred IS NULL

		SELECT	TOP 50 * 
		FROM	#tmpServiceFacilitySelection T
		ORDER BY 
			CASE WHEN T.EnrouteMiles <= @ProductSearchRadiusMiles THEN T.IsPreferred ELSE 0 END DESC, 
			CASE WHEN T.EnrouteMiles <= @ProductSearchRadiusMiles THEN T.Rating ELSE NULL END DESC, 
			T.EnrouteMiles ASC

	END
	ELSE
	BEGIN
		
		PRINT 'Not Considering ServiceLocationPreferredProduct'

		SELECT	TOP 50 * 
		FROM	#tmpServiceFacilitySelection T
		ORDER BY  T.EnrouteMiles ASC		
	END
	

	DROP TABLE #tmpServiceFacilitySelection
	DROP TABLE #tmpVendors
END

