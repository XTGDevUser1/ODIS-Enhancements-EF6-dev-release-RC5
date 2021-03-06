
/****** Object:  UserDefinedFunction [dbo].[fnc_GetVendorIndicators]    Script Date: 08/26/2013 10:47:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetVendorIndicators]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_GetVendorIndicators]
GO



/****** Object:  UserDefinedFunction [dbo].[fnc_GetVendorIndicators]    Script Date: 08/26/2013 10:47:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
-- SELECT * FROM [dbo].[fnc_GetVendorIndicators] ('Vendor')
-- SELECT * FROM [dbo].[fnc_GetVendorIndicators] ('VendorLocation')


CREATE FUNCTION [dbo].[fnc_GetVendorIndicators] (@entityName nvarchar(255))  
RETURNS @tblIndicators TABLE ( RecordID INT, Indicators NVARCHAR(MAX) )
AS  
BEGIN

	IF @entityName = 'Vendor'
	BEGIN

		INSERT INTO @tblIndicators (RecordID, Indicators) 
		SELECT	v.ID VendorID			  
				,CASE WHEN SUM(CASE WHEN vlp_P.ID IS NOT NULL  
									  THEN 1 ELSE 0 END) > 0 THEN ' (P)' ELSE '' END 
				+ CASE WHEN SUM(CASE WHEN vlp_DT.ID IS NOT NULL AND vl.DealerNumber IS NOT NULL AND vl.PartsAndAccessoryCode IS NOT NULL 
									  THEN 1 ELSE 0 END) > 0 THEN ' (DT)' ELSE '' END Indicators
		FROM	dbo.Vendor v WITH (NOLOCK)   
		JOIN	dbo.VendorLocation vl WITH (NOLOCK) ON vl.VendorID = v.ID AND vl.IsActive = 1 AND vl.VendorLocationStatusID = (SELECT ID FROM VendorLocationStatus WHERE Name = 'Active')
		LEFT OUTER JOIN VendorLocationProduct vlp_DT WITH (NOLOCK) ON vlp_DT.VendorLocationID = vl.ID AND vlp_DT.ProductID = (SELECT ID from Product where Name = 'Ford Direct Tow') AND vlp_DT.IsActive = 1
		LEFT OUTER JOIN VendorLocationProduct vlp_P WITH (NOLOCK) ON vlp_P.VendorLocationID = vl.ID AND vlp_P.ProductID = (SELECT ID from Product where Name = 'CoachNet Dealer Partner') AND vlp_P.IsActive = 1
		WHERE 
			  (vlp_DT.ID IS NOT NULL 
			  AND vl.DealerNumber IS NOT NULL 
			  AND vl.PartsAndAccessoryCode IS NOT NULL)
			  OR
			  (vlp_P.ID IS NOT NULL)
		GROUP BY v.VendorNumber, 
			  v.ID
			  ,v.Name
		
	END
	ELSE IF @entityName = 'VendorLocation'
	BEGIN

		INSERT INTO @tblIndicators (RecordID, Indicators) 
		SELECT	DISTINCT vl.ID VendorLocationID
				,CASE WHEN vlp_P.ID IS NOT NULL 
										THEN ' (P)' ELSE '' END 
				+ CASE WHEN vlp_DT.ID IS NOT NULL AND vl.DealerNumber IS NOT NULL AND vl.PartsAndAccessoryCode IS NOT NULL 
										THEN ' (DT)' ELSE '' END Indicators
		FROM	dbo.VendorLocation vl WITH (NOLOCK)
		LEFT OUTER JOIN VendorLocationProduct vlp_DT WITH (NOLOCK) on vlp_DT.VendorLocationID = vl.ID and vlp_DT.ProductID = (Select ID from Product where Name = 'Ford Direct Tow') and vlp_DT.IsActive = 1
		LEFT OUTER JOIN VendorLocationProduct vlp_P WITH (NOLOCK) on vlp_P.VendorLocationID = vl.ID and vlp_P.ProductID = (Select ID from Product where Name = 'CoachNet Dealer Partner') and vlp_P.IsActive = 1
		WHERE	vl.IsActive = 1 AND vl.VendorLocationStatusID = (SELECT ID FROM VendorLocationStatus WHERE Name = 'Active')
				AND
				(vlp_DT.ID IS NOT NULL 
				AND vl.DealerNumber IS NOT NULL 
				AND vl.PartsAndAccessoryCode IS NOT NULL)
				OR
				(vlp_P.ID IS NOT NULL)	

	END

	RETURN;

END
GO
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
   
	 ; WITH wVendors  
	 AS  
	 (   
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
				,Cn.ISOCode as Country,  
				vl.GeographyLocation
				
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
	 )  
   
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
	SELECT  W.*,  
			VP.AllServices,  
			CMT.Comments,
			Faxph.PhoneNumber AS FaxPhoneNumber,
			Officeph.PhoneNumber AS OfficePhoneNumber,
			Cellph.PhoneNumber AS CellPhoneNumber,
			NULL,
			NULL 
   
	FROM	wVendors W  
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
	-- Get last ContactLog result for the current sevice request for the ISP  
	LEFT OUTER JOIN (    
		SELECT RecordID,  
		[dbo].[fnConcatenate](REPLACE([Description],',','~') +  
				+ ' <LF> ' + ISNULL(CreateBy,'') + ' | ' + COALESCE( CONVERT( VARCHAR(10), GETDATE(), 101) +  
		STUFF( RIGHT( CONVERT( VARCHAR(26), GETDATE(), 109 ), 15 ), 10, 4, ' ' ),'')) AS [Comments]            
		FROM Comment         
		WHERE EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')  
		AND  [Description] IS NOT NULL  
		GROUP BY RecordID   
		) CMT ON CMT.RecordID = W.VendorLocationID  

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
END

GO

 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_indicators_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_indicators_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_vendor_indicators_get] 'VendorLocation',222
 
 CREATE PROCEDURE [dbo].[dms_vendor_indicators_get](
 @entityName NVARCHAR(255),
 @entityID INT
 )
 AS
 BEGIN

	DECLARE @indicators NVARCHAR(MAX) = NULL

	SELECT	@indicators = F.Indicators
	FROM	[dbo].[fnc_GetVendorIndicators](@entityName) F 
	WHERE	F.RecordID = @entityID
	

	SELECT ISNULL(@indicators,'') AS Indicators

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
 WHERE id = object_id(N'[dbo].[dms_vendor_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_vendor_list] @pageSize=5000 @whereClauseXML="<ROW>\r\n  <Filter VendorNumber=\'1,4\' />\r\n</ROW>"
 
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
@HasPO BIT   ,
@programID INT	= NULL
  
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
  --, V.Name AS VendorName  
 -- ,v.Name +	
	--CASE WHEN VPCNDP.VendorID IS NOT NULL THEN ' (P)' ELSE '' END  + 
	--CASE WHEN VPFDT.VendorID IS NOT NULL 
	--		THEN ' (DT)' 
	--ELSE '' END VendorName
  , v.Name + COALESCE(F.Indicators,'') AS VendorName
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
LEFT JOIN [dbo].[fnc_GetVendorIndicators]('Vendor') F ON V.ID = F.RecordID
--LEFT JOIN   VendorLocation VL ON V.ID = VL.VendorID
--Left Outer Join VendorProduct VPFDT ON VPFDT.VendorID = V.ID and VPFDT.ProductID = (Select ID from Product where Name = 'Ford Direct Tow') and VPFDT.IsActive = 1
--Left Outer Join VendorProduct VPCNDP on VPCNDP.VendorID = V.ID and VPCNDP.ProductID = (Select ID from Product where Name = 'CoachNet Dealer Partner') and VPCNDP.IsActive = 1
--LEFT JOIN   PurchaseOrder PO ON VL.ID = PO.VendorLocationID AND ISNULL(PO.IsActive,0) = 1
LEFT JOIN [dbo].[fnGetDirectTowVendors]() VPFDT ON VPFDT.VendorID = V.ID
LEFT JOIN [dbo].[fnGetCoachNetDealerPartnerVendors]() VPCNDP ON VPCNDP.VendorID = V.ID
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
 -- EXEC dms_VerifyProgramServiceBenefit 1, 3, 1, 1,3
CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit]
        @ProgramID INT
      , @ProductCategoryID INT
      , @VehicleCategoryID INT
      , @VehicleTypeID INT = NULL
      , @SecondaryCategoryID INT = NULL
      , @ServiceRequestID  INT = NULL
AS
BEGIN 
SET NOCOUNT ON  
SET FMTONLY OFF  
      --DECLARE @ProgramID INT
      --DECLARE @ProductCategoryID INT
      --DECLARE @VehicleCategoryID INT
      --DECLARE @VehicleTypeID INT
      --SET @ProgramID = 1
      --SET @ProductCategoryID = 1
      --SET @VehicleCategoryID = 2
      --SET @VehicleTypeID = 1

      SELECT pc.Name ProductCategoryName
            ,pc.ID ProductCategoryID
            ,ISNULL(vc.Name,'') VehicleCategoryName
            ,vc.ID VehicleCategoryID
            ,MAX(CAST(pp.IsServiceCoverageBestValue AS INT)) IsServiceCoverageBestValue
            ,MAX(pp.ServiceCoverageLimit) ServiceCoverageLimit
            ,MAX(pp.CurrencyTypeID) CurrencyTypeID
            ,MAX(pp.ServiceMileageLimit) ServiceMileageLimit
            ,MAX(pp.ServiceMileageLimitUOM) ServiceMileageLimitUOM
            ,MAX(CASE WHEN pp.ServiceCoverageLimit IS NULL THEN 0 
                          WHEN pp.ServiceCoverageLimit = 0 AND pp.IsReimbursementOnly = 1 THEN 1 
                          WHEN pp.IsServiceCoverageBestValue = 1 THEN 1
                          WHEN pp.ServiceCoverageLimit > 0 THEN 1
                          ELSE 0 END) IsServiceEligible
            ,pp.IsServiceGuaranteed 
            ,pp.ServiceCoverageDescription
            ,pp.IsReimbursementOnly
            ,1 AS IsPrimary
      FROM  ProductCategory pc (NOLOCK) 
      JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID 
                        AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')
                        AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')
      LEFT OUTER JOIN   VehicleCategory vc on vc.id = p.VehicleCategoryID
      LEFT OUTER JOIN   ProgramProduct pp on p.id = pp.productid
      WHERE pp.ProgramID = @ProgramID
      AND         pc.ID = @ProductCategoryID
      AND         (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)
      AND         (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)
      GROUP BY 
            pc.Name     
            ,pc.ID 
            ,vc.Name
            ,vc.ID
			,pp.IsServiceGuaranteed 
			,pp.ServiceCoverageDescription
			,pp.IsReimbursementOnly
	UNION
	
	SELECT pc.Name ProductCategoryName
            ,pc.ID ProductCategoryID
            ,ISNULL(vc.Name,'') VehicleCategoryName
            ,vc.ID VehicleCategoryID
            ,MAX(CAST(pp.IsServiceCoverageBestValue AS INT)) IsServiceCoverageBestValue
            ,MAX(pp.ServiceCoverageLimit) ServiceCoverageLimit
            ,MAX(pp.CurrencyTypeID) CurrencyTypeID
            ,MAX(pp.ServiceMileageLimit) ServiceMileageLimit
            ,MAX(pp.ServiceMileageLimitUOM) ServiceMileageLimitUOM
            ,MAX(CASE WHEN pp.ServiceCoverageLimit IS NULL THEN 0 
                          WHEN pp.ServiceCoverageLimit = 0 AND pp.IsReimbursementOnly = 1 THEN 1 
                          WHEN pp.IsServiceCoverageBestValue = 1 THEN 1
                          WHEN pp.ServiceCoverageLimit > 0 THEN 1
                          ELSE 0 END) IsServiceEligible
            ,pp.IsServiceGuaranteed 
            ,pp.ServiceCoverageDescription
            ,pp.IsReimbursementOnly
            ,0 AS IsPrimary
      FROM  ProductCategory pc (NOLOCK) 
      JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID 
                        AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')
                        AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'SecondaryService')
      LEFT OUTER JOIN   VehicleCategory vc on vc.id = p.VehicleCategoryID
      LEFT OUTER JOIN   ProgramProduct pp on p.id = pp.productid
      WHERE pp.ProgramID = @ProgramID
      AND         pc.ID = @SecondaryCategoryID
      AND         (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)
      AND         (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)
      GROUP BY 
            pc.Name     
            ,pc.ID 
            ,vc.Name
            ,vc.ID
			,pp.IsServiceGuaranteed 
			,pp.ServiceCoverageDescription
			,pp.IsReimbursementOnly
END

GO
