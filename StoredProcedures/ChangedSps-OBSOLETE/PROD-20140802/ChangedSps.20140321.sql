 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Get_Member_Information]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Get_Member_Information]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- exec dms_Get_Member_Information 541
CREATE PROC [dbo].[dms_Get_Member_Information](@memberID INT = NULL)
AS
BEGIN
	-- KB: Get membership ID of the current member.
	DECLARE @membershipID INT
	SELECT @membershipID = MembershipID FROM Member WHERE ID = @memberID

	DECLARE @memberEntityID INT
	SELECT @memberEntityID = ID FROM Entity WHERE Name = 'Member'

	--KB: Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'

	SET FMTONLY OFF;
	
	;WITH wResults
	AS
	(
	SELECT DISTINCT MS.ID AS MembershipID,
	MS.MembershipNumber,
	CASE MS.IsActive WHEN 1 THEN 'Active' ELSE 'Inactive' END AS MembershipStatus, -- KB: I don't think we are using this.
	P.[Description] AS Program,
	P.ID AS ProgramID,
	AD.Line1 AS Line1,
	PH.PhoneNumber AS HomePhoneNumber, 
	PW.PhoneNumber AS WorkPhoneNumber, 
	PC.PhoneNumber AS CellPhoneNumber,
	ISNULL(AD.City,'') + ' ' + ISNULL(AD.StateProvince,'') + ' ' +  ISNULL(AD.PostalCode,'') AS CityStateZip,
	CN.Name AS 'CountryName',
	M.Email,
	M.ID AS MemberID,
	CASE M.IsPrimary WHEN 1 THEN '*' ELSE '' END AS MasterMember,
	--ISNULL(M.FirstName,'') + ' ' + ISNULL(M.LastName,'') + ' ' + ISNULL(M.Suffix,'') AS MemberName,
	REPLACE(RTRIM( 
	COALESCE(M.FirstName, '') + 
	COALESCE(' ' + left(M.MiddleName,1), '') + 
	COALESCE(' ' + M.LastName, '') +
	COALESCE(' ' + M.Suffix, '')
	), ' ', ' ') AS MemberName,	
	-- KB: Considering Effective and Expiration Dates to calculate member status
	CASE WHEN ISNULL(m.EffectiveDate,@minDate) <= @now AND ISNULL(m.ExpirationDate,@minDate) >= @now
				THEN 'Active'
				ELSE 'Inactive'
	END AS MemberStatus,
	M.ExpirationDate,
	M.EffectiveDate,
	C.ID AS ClientID,
	C.Name AS ClientName,
	MS.Note AS MembershipNote	  
	FROM Member M
	LEFT JOIN Membership MS ON MS.ID = M.MembershipID
	LEFT JOIN Program P ON M.ProgramID = P.ID
	LEFT JOIN Client C ON P.ClientID = C.ID
	LEFT JOIN PhoneEntity PH ON PH.RecordID = M.ID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID 
	LEFT JOIN PhoneEntity PW ON PW.RecordID = M.ID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID 
	LEFT JOIN PhoneEntity PC ON PC.RecordID = M.ID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID 
	LEFT JOIN AddressEntity AD ON AD.RecordID = M.ID AND AD.EntityID = @memberEntityID
	LEFT JOIN Country CN ON CN.ISOCode = AD.CountryCode
	WHERE MS.ID =  @membershipID -- KB: Performing the check against the right attribute.
	)
	SELECT * FROM wResults M ORDER BY MasterMember DESC,MemberName

END


GO
		
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Membsership_Information]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Membsership_Information] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 	
 -- EXEC [dbo].[dms_Membsership_Information] 1
 CREATE PROC [dbo].[dms_Membsership_Information](@memberID INT = NULL)
 AS
 BEGIN
	
	-- Dates used while calculating member status
DECLARE @now DATETIME, @minDate DATETIME
SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
SET @minDate = '1900-01-01'
	
	SELECT	m.ID AS MemberID,
		
		REPLACE(RTRIM( 
COALESCE(M.FirstName, '') + 
COALESCE(' ' + left(M.MiddleName,1), '') + 
COALESCE(' ' + M.LastName, '') +
COALESCE(' ' + M.Suffix, '')
), ' ', ' ') AS MemberName,
			
		-- KB: Considering Effective and Expiration Dates to calculate member status	
		CASE WHEN ISNULL(m.EffectiveDate,@minDate) <= @now AND ISNULL(m.ExpirationDate,@minDate) >= @now
				THEN 'Active'
				ELSE 'Inactive'
		END	AS MemberStatus,
		ms.MembershipNumber AS MemberNumber,
		c.Name AS Client,  
		--parent.Code AS Program,  
		p.[Description] as Program,
		(SELECT MAX(ServiceCoverageLimit)FROM ProgramProduct pp WHERE pp.ProgramID = p.ID) as Limit,		
		CONVERT(varchar(10),m.MemberSinceDate,101) AS MemberSince,
		CONVERT(VARCHAR(10),m.ExpirationDate,101)AS Expiration, 
		m.ExpirationDate AS ExpirationDate,
		m.EffectiveDate AS EffectiveDate,
		CONVERT(VARCHAR(10),m.EffectiveDate,101)AS Effective, 
		ms.ClientReferenceNumber as ClientRefNumber, 
		ms.CreateDate as Created, 
		ms.ModifyDate as LastUpdate,
		ms.Note as MembershipNote
	FROM Member m 
	JOIN Membership ms ON ms.ID = m.MembershipID
	JOIN Program p ON p.id = m.ProgramID
	LEFT OUTER JOIN Program parent ON parent.ID = p.ParentProgramID
	JOIN Client c ON c.ID = p.ClientID
	WHERE m.ID = @MemberID

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
 WHERE id = object_id(N'[dbo].[dms_Program_Coverage_Information_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Coverage_Information_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_Program_Coverage_Information_List_Get @programID =1
 CREATE PROCEDURE [dbo].[dms_Program_Coverage_Information_List_Get]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID int = NULL 
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
NameOperator="-1" 
LimitOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
NameOperator INT NOT NULL,
NameValue nvarchar(50) NULL,
LimitOperator INT NOT NULL,
LimitValue money NULL
)
DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Name nvarchar(50)  NULL ,
	Limit money  NULL ,
	Vehicle nvarchar(50)  NULL 
) 

DECLARE @tmpFinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Name nvarchar(50)  NULL ,
	Limit money  NULL ,
	Vehicle nvarchar(50)  NULL 
) 

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(NameOperator,-1),
	NameValue ,
	ISNULL(LimitOperator,-1),
	LimitValue 
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
NameOperator INT,
NameValue nvarchar(50) 
,LimitOperator INT,
LimitValue money 
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @tmpFinalResults
SELECT	pc.Name
		, max(pp.servicecoveragelimit) AS Limit
		, max(CASE WHEN RIGHT(p.Name,2) = 'LD' THEN 'LD' ELSE '' END) +
		  coalesce('/' + max(CASE WHEN RIGHT(p.Name,2) = 'MD' THEN 'MD' END),'') +
		  coalesce('/'+max(CASE WHEN RIGHT(p.Name,2) = 'HD' THEN 'HD' END),'') AS Vehicle
FROM	ProgramProduct pp
JOIN	Product p (NOLOCK) on p.id = pp.ProductID
JOIN	ProductCategory pc (NOLOCK) on pc.id = p.productcategoryid
WHERE	pp.ProgramID = @ProgramID
AND		pc.Name <> 'Info'
GROUP BY pc.Name, pc.sequence
ORDER BY pc.Sequence

INSERT INTO @FinalResults
SELECT 
	T.Name,
	T.Limit,
	T.Vehicle
FROM @tmpFinalResults T,
@tmpForWhereClause TMP 
WHERE ( 

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
	 ( TMP.LimitOperator = -1 ) 
 OR 
	 ( TMP.LimitOperator = 0 AND T.Limit IS NULL ) 
 OR 
	 ( TMP.LimitOperator = 1 AND T.Limit IS NOT NULL ) 
 OR 
	 ( TMP.LimitOperator = 2 AND T.Limit = TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 3 AND T.Limit <> TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 7 AND T.Limit > TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 8 AND T.Limit >= TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 9 AND T.Limit < TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 10 AND T.Limit <= TMP.LimitValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Limit' AND @sortOrder = 'ASC'
	 THEN T.Limit END ASC, 
	 CASE WHEN @sortColumn = 'Limit' AND @sortOrder = 'DESC'
	 THEN T.Limit END DESC ,

	 CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'ASC'
	 THEN T.Vehicle END ASC, 
	 CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'DESC'
	 THEN T.Vehicle END DESC 


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
 WHERE id = object_id(N'[dbo].[dms_Program_Management_GetdistinctVehicleTypes]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_GetdistinctVehicleTypes] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
  --EXEC dms_Program_Management_GetdistinctVehicleTypes 4,8
 CREATE PROCEDURE [dbo].[dms_Program_Management_GetdistinctVehicleTypes]( 
   @programId INT=NULL,
   @programVehicleTypeId INT=NULL
  
 ) 
 AS 
 BEGIN 
 
	SET FMTONLY OFF;
 	SET NOCOUNT ON
 	
 	DECLARE @tmpVehicleType TABLE
	(
	ID INT NULL,
	Descipriton nvarchar(255) null,
	Name nvarchar(50) null
	)
	
	IF @programVehicleTypeId IS NULL
	BEGIN
		INSERT INTO @tmpVehicleType
		SELECT ID,[Description],Name 
		FROM VehicleType
		WHERE ID not in(SELECT DISTINCT VehicleTypeID from ProgramVehicleType WHERE ProgramID=@programId)
	END
	ELSE BEGIN
		INSERT INTO @tmpVehicleType
		
		SELECT ID,[Description],Name 
		FROM VehicleType
		WHERE ID not in(SELECT DISTINCT VehicleTypeID from ProgramVehicleType WHERE ProgramID=@programId)
		
		UNION 
		
		SELECT ID,[Description],Name FROM VehicleType
		WHERE ID=(SELECT VehicleTypeID FROM ProgramVehicleType where ID=@programVehicleTypeId)
	END
	
	SELECT * FROM @tmpVehicleType
	
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
				,v.Name /*KB: There is no DealerNumber in Vendor table now. + CASE WHEN v.DealerNumber IS NOT NULL THEN ' *** Ford Direct Tow' ELSE N'' END */ VendorName  
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
		Join	dbo.Vendor v  On vl.VendorID = v.ID  
		Join	dbo.[AddressEntity] addr On addr.EntityID = @VendorLocationEntityID and addr.RecordID = vl.ID and addr.AddressTypeID = @BusinessAddressTypeID  
		Join	dbo.Country Cn On addr.CountryID = Cn.ID    
		Join	dbo.StateProvince SP on addr.StateProvinceID = SP.ID    
		Left Outer Join dbo.[PhoneEntity] ph On ph.EntityID = @VendorLocationEntityID and ph.RecordID = vl.ID and ph.PhoneTypeID = @DispatchPhoneTypeID 
  
 
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
				FROM	[dbo].[fnc_GetProgramConfigurationForProgram](1,'ProgramInfo') P 
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
		ORDER BY T.IsPreferred DESC, T.Rating DESC, T.EnrouteMiles ASC

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
