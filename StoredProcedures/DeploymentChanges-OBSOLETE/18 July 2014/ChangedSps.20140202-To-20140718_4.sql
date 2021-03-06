IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_QuestionAnswer_ServiceRequest')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_QuestionAnswer_ServiceRequest] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

CREATE PROC [dbo].[dms_QuestionAnswer_ServiceRequest](@serviceRequest INT  = NULL)
AS
BEGIN
	SELECT	PCQ.QuestionText,
			SRD.Answer,
			CASE WHEN (ISNULL(sr.IsPossibleTow,0) = 0 AND sr.productcategoryid = pc.id) OR (ISNULL(sr.IsPossibleTow,0) = 1 AND sr.productcategoryid = pc.id)
				THEN 'Primary'
				WHEN ISNULL(sr.IsPossibleTow,0) = 1 AND sr.productcategoryid <> pc.id
				THEN
				'Secondary'
			END As Flag
	FROM	servicerequestdetail SRD
	JOIN	servicerequest SR ON SR.ID = SRD.serviceRequestID
	JOIN	ProductCategoryquestion PCQ ON SRD.ProductCategoryQuestionID = PCQ.ID
	JOIN	ProductCategory PC ON PCQ.ProductCategoryID = PC.ID
	WHERE	SRD.servicerequestid = @serviceRequest
	ORDER BY PCQ.ProductCategoryID DESC
END



										
GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_questionanswer_values_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_questionanswer_values_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_questionanswer_values_get] 3,1,1
 
CREATE PROCEDURE [dbo].[dms_questionanswer_values_get]( 
   @ProgramID int,
   --@ProductCategoryID int,
   @VehicleTypeID int,
   @VehicleCategoryID int
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

DECLARE @Questions TABLE 
(
  ProductCategoryID int,
  ProductCategoryName NVARCHAR(MAX),
  ProductCategoryQuestionID int, 
  QuestionText nvarchar(4000),
  ControlType nvarchar(50),
  DataType nvarchar(50),
  HelpText nvarchar(4000),
  IsRequired bit,
  SubQuestionID int,
  RelatedAnswer nvarchar(255),
  Sequence int
)
DECLARE @relevantProductCategories TABLE
(
	ProductCategoryID INT,
	Sequence INT NULL
)
	INSERT INTO @relevantProductCategories
	SELECT DISTINCT ProductCategoryID,
			PC.Sequence 
	FROM	ProgramProductCategory PC
	JOIN	[dbo].[fnc_getprogramsandparents](@ProgramID) FNCP ON PC.ProgramID = FNCP.ProgramID
	AND		(VehicleTypeID = @VehicleTypeID OR VehicleTypeID IS NULL)
	-- KB: Do not consider @vehicleCategoryID here.By design, we load all the questions for a given vehicle type and show/hide questions relevant to vehiclecategory. Therefore, questions / product categories should not get filtered out here.
	--AND		(VehicleCategoryID = @vehicleCategoryID OR VehicleCategoryID IS NULL)
	WHERE	PC.IsActive = 1
	ORDER BY PC.Sequence 


-- Add questions related to Tow if they are not already in the list.
IF ( (SELECT COUNT(*) FROM @relevantProductCategories WHERE ProductCategoryID = 7) = 0)
BEGIN
	INSERT INTO @relevantProductCategories
	SELECT	PC.ID,
			PC.Sequence
	FROM ProductCategory PC WHERE Name like 'Tow%' AND PC.IsActive = 1
END

INSERT INTO @Questions 
SELECT DISTINCT 
	PCQ.ProductCategoryID,
	PC.Name,
	PCQ.ID, 
  PCQ.QuestionText,
  CT.Name as ControlType,
  DT.Name as DataType,
  PCQ.HelpText, 
  PCQ.IsRequired,  
  PCL.ProductCategoryQuestionID as SubQuestionID, 
  PVAL.Value as RelatedAnswer,
  PCQ.Sequence 
  FROM [dbo].ProductCategoryQuestion PCQ
  JOIN ProductCategoryQuestionVehicleType PCV ON PCV.ProductCategoryQuestionID = PCQ.ID 
	AND (PCV.VehicleTypeID IS NULL OR PCV.VehicleTypeID = @VehicleTypeID) 
	-- KB: Do not consider @vehicleCategoryID here.By design, we load all the questions for a given vehicle type and show/hide questions relevant to vehiclecategory. Therefore, questions / product categories should not get filtered out here.
	--AND (PCV.VehicleCategoryID IS NULL OR PCV.VehicleCategoryID = @VehicleCategoryID)
	AND PCV.IsActive = 1   
  JOIN ProductCategory PC ON PCQ.ProductCategoryID = PC.ID
  LEFT JOIN ControlType CT ON CT.ID = PCQ.ControlTypeID
  LEFT JOIN DataType DT on DT.ID = PCQ.DataTypeID
  LEFT JOIN ProductCategoryQuestionLink PCL on PCL.ParentProductCategoryQuestionID = PCV.ProductCategoryQuestionID
  AND PCL.IsActive = 1
  LEFT JOIN ProductCategoryQuestionValue PVAL on PVAL.ID = PCL.ProductCategoryQuestionValueID
  AND PVAL.IsActive = 1 
  WHERE PCQ.ProductCategoryID IN (SELECT ProductCategoryID FROM @relevantProductCategories )
  AND PCQ.IsActive = 1
  
  UNION ALL
  
SELECT DISTINCT 
PCQ.ProductCategoryID,
PC.Name AS ProductCategoryName,
PCQ.ID, 

  PCQ.QuestionText,
  CT.Name as ControlType,
  DT.Name as DataType,
  PCQ.HelpText, 
  PCQ.IsRequired,  
  PCL.ProductCategoryQuestionID as SubQuestionID, 
  PVAL.Value as RelatedAnswer,
  PCQ.Sequence 
  FROM [dbo].ProductCategoryQuestion PCQ
  JOIN ProductCategoryQuestionProgram PCP ON PCP.ProductCategoryQuestionID = PCQ.ID 
	AND (PCP.VehicleTypeID IS NULL OR PCP.VehicleTypeID = @VehicleTypeID )
	-- KB: Do not consider @vehicleCategoryID here.By design, we load all the questions for a given vehicle type and show/hide questions relevant to vehiclecategory. Therefore, questions / product categories should not get filtered out here.
	--AND (PCP.VehicleCategoryID IS NULL OR PCP.VehicleCategoryID = @VehicleCategoryID)
	AND PCP.IsActive = 1 
	JOIN ProductCategory PC ON PCQ.ProductCategoryID = PC.ID
  JOIN fnc_GetProgramsandParents(@ProgramID) fncP on fncP.ProgramID = PCP.ProgramID 
  LEFT JOIN ControlType CT ON CT.ID = PCQ.ControlTypeID
  LEFT JOIN DataType DT on DT.ID = PCQ.DataTypeID
  LEFT JOIN ProductCategoryQuestionLink PCL on PCL.ParentProductCategoryQuestionID = PCP.ProductCategoryQuestionID
  AND PCL.IsActive = 1
  LEFT JOIN ProductCategoryQuestionValue PVAL on PVAL.ID = PCL.ProductCategoryQuestionValueID
  AND PVAL.IsActive = 1 
  WHERE PCQ.ProductCategoryID IN (SELECT ProductCategoryID FROM @relevantProductCategories )
  AND PCQ.IsActive = 1
  ORDER BY PCQ.Sequence 
  
--SELECT * FROM @Questions 

SELECT PCV.ProductCategoryQuestionID, PCV.Value, PCV.IsPossibleTow, PCV.Sequence FROM ProductCategoryQuestionValue PCV
JOIN @Questions Q ON Q.ProductCategoryQuestionID = PCV.ProductCategoryQuestionID 
WHERE PCV.IsActive = 1
AND  Q.ProductCategoryName NOT IN ('Repair','Billing')
GROUP BY PCV.ProductCategoryQuestionID, PCV.Value, PCV.IsPossibleTow,PCV.Sequence
ORDER BY PCV.ProductCategoryQuestionID,PCV.Sequence 

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
 WHERE id = object_id(N'[dbo].[dms_Securables_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Securables_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Securables_List]( 
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
SecurableIDOperator="-1" 
FriendlyNameOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
SecurableIDOperator INT NOT NULL,
SecurableIDValue int NULL,
FriendlyNameOperator INT NOT NULL,
FriendlyNameValue nvarchar(50) NULL
)
DECLARE @FinalResults TABLE( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	SecurableID int  NULL ,
	FriendlyName nvarchar(MAX)  NULL ,
	[Permissions] nvarchar(MAX)  NULL 
) 

DECLARE @QueryResults TABLE( 
	SecurableID int  NULL ,
	FriendlyName nvarchar(MAX)  NULL ,
	[Permissions] nvarchar(MAX)  NULL 
) 

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(SecurableIDOperator,-1),
	SecurableIDValue ,
	ISNULL(FriendlyNameOperator,-1),
	FriendlyNameValue 
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
SecurableIDOperator INT,
SecurableIDValue int 
,FriendlyNameOperator INT,
FriendlyNameValue nvarchar(50) 
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------

INSERT INTO @QueryResults
SELECT S.ID,
	   S.FriendlyName,
	  (SELECT Permission FROM dbo.fn_SecurablePermissions(S.ID))
FROM Securable S WITH(NOLOCK)

INSERT INTO @FinalResults
SELECT 
	T.SecurableID,
	T.FriendlyName,
	T.Permissions
FROM @QueryResults T,
@tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.SecurableIDOperator = -1 ) 
 OR 
	 ( TMP.SecurableIDOperator = 0 AND T.SecurableID IS NULL ) 
 OR 
	 ( TMP.SecurableIDOperator = 1 AND T.SecurableID IS NOT NULL ) 
 OR 
	 ( TMP.SecurableIDOperator = 2 AND T.SecurableID = TMP.SecurableIDValue ) 
 OR 
	 ( TMP.SecurableIDOperator = 3 AND T.SecurableID <> TMP.SecurableIDValue ) 
 OR 
	 ( TMP.SecurableIDOperator = 7 AND T.SecurableID > TMP.SecurableIDValue ) 
 OR 
	 ( TMP.SecurableIDOperator = 8 AND T.SecurableID >= TMP.SecurableIDValue ) 
 OR 
	 ( TMP.SecurableIDOperator = 9 AND T.SecurableID < TMP.SecurableIDValue ) 
 OR 
	 ( TMP.SecurableIDOperator = 10 AND T.SecurableID <= TMP.SecurableIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.FriendlyNameOperator = -1 ) 
 OR 
	 ( TMP.FriendlyNameOperator = 0 AND T.FriendlyName IS NULL ) 
 OR 
	 ( TMP.FriendlyNameOperator = 1 AND T.FriendlyName IS NOT NULL ) 
 OR 
	 ( TMP.FriendlyNameOperator = 2 AND T.FriendlyName = TMP.FriendlyNameValue ) 
 OR 
	 ( TMP.FriendlyNameOperator = 3 AND T.FriendlyName <> TMP.FriendlyNameValue ) 
 OR 
	 ( TMP.FriendlyNameOperator = 4 AND T.FriendlyName LIKE TMP.FriendlyNameValue + '%') 
 OR 
	 ( TMP.FriendlyNameOperator = 5 AND T.FriendlyName LIKE '%' + TMP.FriendlyNameValue ) 
 OR 
	 ( TMP.FriendlyNameOperator = 6 AND T.FriendlyName LIKE '%' + TMP.FriendlyNameValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'SecurableID' AND @sortOrder = 'ASC'
	 THEN T.SecurableID END ASC, 
	 CASE WHEN @sortColumn = 'SecurableID' AND @sortOrder = 'DESC'
	 THEN T.SecurableID END DESC ,

	 CASE WHEN @sortColumn = 'FriendlyName' AND @sortOrder = 'ASC'
	 THEN T.FriendlyName END ASC, 
	 CASE WHEN @sortColumn = 'FriendlyName' AND @sortOrder = 'DESC'
	 THEN T.FriendlyName END DESC ,

	 CASE WHEN @sortColumn = 'Permissions' AND @sortOrder = 'ASC'
	 THEN T.Permissions END ASC, 
	 CASE WHEN @sortColumn = 'Permissions' AND @sortOrder = 'DESC'
	 THEN T.Permissions END DESC 


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

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Securbale_Permissions]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Securbale_Permissions] 
END 
GO

CREATE PROC dms_Securbale_Permissions(@SecurableID INT = NULL)
AS
BEGIN
	SELECT	R.RoleName,
			R.RoleId,
			AT.Name AccessTypeName,
			ACL.AccessTypeID
	FROM  aspnet_Roles R
	LEFT JOIN AccessControlList ACL ON R.RoleId = ACL.RoleID AND ACL.SecurableID = ( SELECT ID FROM Securable S WHERE S.ID = @SecurableID)
	LEFT JOIN AccessType AT ON AT.ID = ACL.AccessTypeID
	JOIN aspnet_Applications A ON R.ApplicationId = A.ApplicationId
	WHERE A.ApplicationName = 'DMS'
END






GO

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

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ServiceRequestDetail_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ServiceRequestDetail_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  

/****** Object:  StoredProcedure [dbo].[dms_ServiceRequestDetail_Get]    Script Date: 07/23/2013 18:35:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

  -- EXEC dms_ServiceRequestDetail_Get 240717
 CREATE PROCEDURE [dbo].[dms_ServiceRequestDetail_Get]( 
	@serviceRequestID INT
 ) 
 AS 
 BEGIN
 
/*
*	Name				: dms_ServiceRequestDetail_Get
*	Purpose				: To get full details of a given Service Request.
*	Execution sample	: EXEC [dbo].[dms_ServiceRequestDetail_Get] '28498' --'25592'  -- select * from servicerequest sr join purchaseorder po on po.servicerequestid = sr.id
*/

	
	DECLARE @minDate DATETIME = '1900-01-01'
	DECLARE @now DATETIME = GETDATE()
	
	SELECT
			CL.ID AS [ClientID]
			, CL.Name AS [ClientName]
			, P.ID AS [ProgramID]
			, P.Name AS [ProgramName]
			, SR.ID AS [SRNumber]
			, SR.CreateDate AS [SRDate]
			, SRS.Name AS [SRStatus]
			, PCSR.Name as [SRServiceTypeName]
			, PCSR.Description as [SRServiceTypeDescription]
			, M.ID AS [MemberID]
			, MS.MembershipNumber AS [MemberNumber]
			, M.Prefix AS [Prefix]
			, M.FirstName AS [FirstName]
			, M.MiddleName AS [MiddleName]
			, M.LastName AS [LastName]
			, M.Suffix AS [Suffix]
			, REPLACE(RTRIM(
			  COALESCE(M.LastName,'')+  
			  COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')+  
			  COALESCE(', '+ CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+
			  COALESCE(' ' + LEFT(M.MiddleName,1),'')
				),'','') AS [MemberName]
			, C.ContactPhoneNumber AS [CallbackNumber] 
			, C.ContactAltPhoneNumber AS [AlternateNumber]
			, C.VehicleVIN AS [VIN]
			, C.VehicleYear AS [Year]
			, CASE
				WHEN C.VehicleMake = 'Other'
				THEN C.VehicleMakeOther
				ELSE C.VehicleMake
			  END AS [Make]
			 , CASE
				WHEN C.VehicleModel = 'Other'
				THEN C.VehicleModelOther
				ELSE C.VehicleModel
			  END AS [Model]	
			, C.VehicleLicenseNumber AS [LicenseNumber]
			, C.VehicleLicenseState AS [LicenseState]
			, C.VehicleColor AS [Color]
			, C.VehicleDescription AS [VehicleDescription]
			, C.VehicleLength AS [Length]
			, C.VehicleHeight AS [Height]
			, VC.Name AS [VehicleCategory]
			, VT.Name AS [VehicleType]
			, RVT.Name AS [RVType]
			, C.VehicleTransmission AS [Transmission]
			, C.VehicleEngine AS [Engine]
			, C.VehicleGVWR AS [GVWR]
			, C.VehicleChassis AS [Chassis]
			, SR.ServiceLocationAddress AS [Location]
			, SR.ServiceLocationDescription AS [LocationDescription]
			, SR.DestinationAddress AS [Destination]
			, SR.DestinationDescription AS [DestinationDescription]
			, PO.ID AS [POID]
			, PO.PurchaseOrderNumber AS [PONumber]
			, PO.IssueDate AS [POIssueDate]
			, PO.ETADate AS [POETADate]
			, POS.Name AS [POStatus]
			, PC.Name AS [POService]
			, PO.TotalServiceAmount AS [POAmount]
			, PO.CancellationReasonID AS [POCancellationReasonID]
			, CASE 
				WHEN POCR.Name = 'Other'
				THEN PO.CancellationReasonOther
				ELSE POCR.[Description] 
			  END AS [POCancellationReasonName]
			, PO.CancellationComment AS [POCancellationComment]
			, PO.IsGOA AS [POIsGOA]
			, PO.GOAReasonID AS [POGOAReasonID]
			, CASE  
				WHEN POGR.Name = 'Other'
				THEN PO.GOAReasonOther
				ELSE POGR.[Description]
			  END AS [POGOAReasonName]
			, PO.GOAComment AS [POGOAComment]
			, PO.CreateBy AS [POTakenBy]
			, V.VendorNumber AS [VendorNumber]
			, V.Name AS [VendorName]
	FROM		ServiceRequest SR WITH (NOLOCK)
	LEFT JOIN	ServiceRequestStatus SRS WITH (NOLOCK) ON SRS.ID = SR.ServiceRequestStatusID
	LEFT JOIN	ProductCategory PCSR ON PCSR.ID = SR.ProductCategoryID
	LEFT JOIN	PurchaseOrder PO WITH (NOLOCK) ON PO.ServiceRequestID = SR.ID 
	LEFT JOIN	PurchaseOrderStatus POS WITH (NOLOCK) ON POS.ID = PO.PurchaseOrderStatusID
	LEFT JOIN	PurchaseOrderCancellationReason POCR WITH (NOLOCK) ON POCR.ID = PO.CancellationReasonID
	LEFT JOIN	PurchaseOrderGOAReason POGR WITH (NOLOCK) ON POGR.ID = PO.GOAReasonID
	LEFT JOIN	VendorLocation VL WITH (NOLOCK) ON VL.ID = PO.VendorLocationID
	LEFT JOIN	Vendor V WITH (NOLOCK) ON V.ID = VL.VendorID
	JOIN		[Case] C WITH (NOLOCK) ON C.ID = SR.CaseID
	LEFT JOIN	VehicleCategory VC WITH (NOLOCK) ON VC.ID = C.VehicleCategoryID
	LEFT JOIN	VehicleType VT WITH (NOLOCK) ON VT.ID = C.VehicleTypeID
	JOIN		Program P WITH (NOLOCK) ON P.ID = C.ProgramID
	JOIN		Client CL WITH (NOLOCK) ON CL.ID = P.ClientID
	LEFT JOIN	Member M WITH (NOLOCK) ON M.ID = C.MemberID
	LEFT JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
	LEFT JOIN	Product PR WITH (NOLOCK) ON PR.ID = PO.ProductID
	LEFT JOIN	ProductCategory PC WITH (NOLOCK) ON PC.ID = PR.ProductCategoryID
	LEFT JOIN	RVType RVT WITH (NOLOCK) ON RVT.ID = C.VehicleRVTypeID
	WHERE		SR.ID = @serviceRequestID
	AND			(
				(ISNULL(PO.ID,'')='') 
				OR  
				(PO.IsActive = 1 AND PO.PurchaseOrderStatusID <> (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending'))
				)
	ORDER BY 	SR.ID, PO.PurchaseOrderNumber
	
 END

GO

GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ServiceRequestList_ByClient_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ServiceRequestList_ByClient_Get] 
 END 
 GO  
/****** Object:  StoredProcedure [dbo].[dms_ServiceRequestList_ByClient_Get]    Script Date: 07/23/2013 18:34:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 
 -- EXEC dms_ServiceRequestList_ByClient_Get '32','1/1/2013', '7/31/2013'
 CREATE PROCEDURE [dbo].[dms_ServiceRequestList_ByClient_Get]( 
	@clientIDs NVARCHAR(MAX),
	@startDate DATETIME,
	@endDate DATETIME
 ) 
 AS 
 BEGIN
	DECLARE @tblClients TABLE (
	ClientID	INT
	)
	INSERT INTO @tblClients
	SELECT * FROM [dbo].[fnSplitString](@clientIDs,',')
	
	SELECT 
			CLT.ClientID AS [ClientID]
			, P.ID AS [ProgramID]
			, P.Name AS [ProgramName]
			, SR.ID AS [SRNumber]
			, SR.CreateDate AS [SRDate]
			, SRS.Name AS [SRStatus]
			, PC.Name AS [SRServiceTypeName]
			, PC.Description AS [SRServiceTypeDescription]
			, MS.MembershipNumber AS [MemberNumber]
			, M.Prefix AS [Prefix]
			, M.FirstName AS [FirstName]
			, M.MiddleName AS [MiddleName]
			, M.LastName AS [LastName]
			, M.Suffix AS [Suffix]
			, REPLACE(RTRIM(
			  COALESCE(M.LastName,'')+  
			  COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')+  
			  COALESCE(', '+ CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+
			  COALESCE(' ' + LEFT(M.MiddleName,1),'')
				),'','') AS [MemberName]
			, PO.ID AS [POID]
			, PO.PurchaseOrderNumber AS [PONumber]
			, PO.IssueDate AS [POIssueDate]
			, POS.Name AS [POStatus]
			, PO.CancellationReasonID AS [POCancellationReasonID]
			, POCR.Name AS [POCancellationReasonName]
			, PO.CancellationReasonOther AS [POCancellationReasonOther]
			, PO.CancellationComment AS [POCancellationComment]
			, PO.IsGOA AS [POIsGOA]
			, PO.GOAReasonID AS [POGOAReasonID]
			, POGR.Name AS [POGOAReasonName]
			, PO.GOAReasonOther AS [POGOAReasonOther]
			, PO.GOAComment AS [POGOAComment]
			, V.VendorNumber AS [ISPNumber]
			, V.Name AS [ISPName]
	FROM		ServiceRequest SR WITH (NOLOCK)
	LEFT JOIN	ServiceRequestStatus SRS WITH (NOLOCK) ON SRS.ID = SR.ServiceRequestStatusID
	LEFT JOIN	ProductCategory PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID
	LEFT JOIN	PurchaseOrder PO WITH (NOLOCK) ON PO.ServiceRequestID = SR.ID AND PO.IsActive = 1 AND PO.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued', 'Issued-Paid', 'Cancelled'))
	LEFT JOIN	PurchaseOrderStatus POS WITH (NOLOCK) ON POS.ID = PO.PurchaseOrderStatusID 
	LEFT JOIN	PurchaseOrderCancellationReason POCR WITH (NOLOCK) ON POCR.ID = PO.CancellationReasonID
	LEFT JOIN	PurchaseOrderGOAReason POGR WITH (NOLOCK) ON POGR.ID = PO.GOAReasonID
	LEFT JOIN	[Case] C WITH (NOLOCK) ON C.ID = SR.CaseID
	LEFT JOIN	Program P WITH (NOLOCK) ON P.ID = C.ProgramID
	LEFT JOIN	Member M WITH (NOLOCK) ON M.ID = C.MemberID
	LEFT JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
	LEFT JOIN	VendorLocation VL WITH (NOLOCK) ON VL.ID = PO.VendorLocationID
	LEFT JOIN	Vendor V WITH (NOLOCK) ON V.ID = VL.VendorID
	JOIN		@tblClients CLT ON CLT.ClientID	= P.ClientID
	WHERE		SRS.Name IN ('Complete','Cancelled')
	AND			((@startDate IS NULL AND @endDate IS NULL) OR (SR.CreateDate BETWEEN @StartDate AND @EndDate))
	AND			(
				(ISNULL(PO.ID,'')='') 
				OR  
				(PO.IsActive = 1 AND PO.PurchaseOrderStatusID <> (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending'))
				)	
	AND			SR.CreateBy <> 'Sysadmin'
	--AND			PO.IsActive = '1' 
	--AND			PO.PurchaseOrderStatusID <> (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending')
	ORDER BY
				SR.ID, 
				PO.PurchaseOrderNumber DESC
	
 END

GO

GO

/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_servicerequest_get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_servicerequest_get]
GO
/****** Object:  StoredProcedure [dbo].[dms_servicerequest_get]    Script Date: 07/03/2012 17:56:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC  [dbo].[dms_servicerequest_get] 1414
CREATE PROCEDURE [dbo].[dms_servicerequest_get](
   @serviceRequestID INT=NULL
)
AS
BEGIN
SET NOCOUNT ON

declare @MemberID INT=NULL
-- GET CASE ID
SET   @MemberID =(SELECT CaseID FROM [ServiceRequest](NOLOCK) WHERE ID = @serviceRequestID)
-- GET Member ID
SET @MemberID =(SELECT MemberID FROM [Case](NOLOCK) WHERE ID = @MemberID)

DECLARE @ProductID INT
SET @ProductID =NULL
SELECT  @ProductID = PrimaryProductID FROM ServiceRequest(NOLOCK) WHERE ID = @serviceRequestID

DECLARE @memberEntityID INT
DECLARE @vendorLocationEntityID INT
DECLARE @otherReasonID INT
DECLARE @dispatchPhoneTypeID INT

SET @memberEntityID = (SELECT ID FROM Entity(NOLOCK) WHERE Name ='Member')
SET @vendorLocationEntityID = (SELECT ID FROM Entity(NOLOCK) WHERE Name ='VendorLocation')
SET @otherReasonID = (Select ID From PurchaseOrderCancellationReason(NOLOCK) Where Name ='Other')
SET @dispatchPhoneTypeID = (SELECT ID FROM PhoneType(NOLOCK) WHERE Name ='Dispatch')

SELECT
		-- Service Request Data Section
		-- Column 1		
		SR.CaseID,
		C.IsDeliveryDriver,
		SR.ID AS [RequestNumber],
		SRS.Name AS [Status],
		SRP.Name AS [Priority],
		SR.CreateDate AS [CreateDate],
		SR.CreateBy AS [CreateBy],
		SR.ModifyDate AS [ModifyDate],
		SR.ModifyBy AS [ModifyBy],
		-- Column 2
		NA.Name AS [NextAction],
		SR.NextActionScheduledDate AS [NextActionScheduledDate],
		SASU.FirstName +' '+ SASU.LastName AS [NextActionAssignedTo],
		CLS.Name AS [ClosedLoop],
		SR.ClosedLoopNextSend AS [ClosedLoopNextSend],
		-- Column 3
		CASE WHEN SR.IsPossibleTow = 1 THEN PC.Name +'/Possible Tow'ELSE PC.Name +''END AS [ServiceCategory],
		CASE
			WHEN SRS.Name ='Dispatched'
				  THEN CONVERT(VARCHAR(6),DATEDIFF(SECOND,sr.CreateDate,GETDATE())/3600)+':'
						+RIGHT('0'+CONVERT(VARCHAR(2),(DATEDIFF(SECOND,sr.CreateDate,GETDATE())%3600)/60),2)
			ELSE''
		END AS [Elapsed],
		(SELECT MAX(IssueDate)FROM PurchaseOrder(NOLOCK) Where ServiceRequestID = @ServiceRequestID) AS [PoMaxIssueDate],
		(SELECT MAX(ETADate)FROM PurchaseOrder(NOLOCK) Where ServiceRequestID = @ServiceRequestID) AS [PoMaxETADate],
		SR.DataTransferDate AS [DataTransferDate],

		-- Member data  
		REPLACE(RTRIM(
		COALESCE(m.FirstName,'')+
		COALESCE(' '+left(m.MiddleName,1),'')+
		COALESCE(' '+ m.LastName,'')+
		COALESCE(' '+ m.Suffix,'')
		),'  ',' ')AS [Member],
		MS.MembershipNumber,
		C.MemberStatus,
		CL.Name AS [Client],
		P.Name AS [ProgramName],
		CONVERT(varchar(10),M.MemberSinceDate,101)AS [MemberSince],
		CONVERT(varchar(10),M.ExpirationDate,101)AS [ExpirationDate],
		MS.ClientReferenceNumber as [ClientReferenceNumber],
		ISNULL((SELECT NAME FROM PhoneType(NOLOCK) WHERE ID = c.ContactPhoneTypeID),'')AS [CallbackPhoneType],
		C.ContactPhoneNumber AS [CallbackNumber],
		ISNULL((SELECT NAME FROM PhoneType(NOLOCK) WHERE ID = c.ContactAltPhoneTypeID),'')AS [AlternatePhoneType],
		C.ContactAltPhoneNumber AS [AlternateNumber],
		ISNULL(MA.Line1,'')AS Line1,
		ISNULL(MA.Line2,'')AS Line2,
		ISNULL(MA.Line3,'')AS Line3,
		REPLACE(RTRIM(
			COALESCE(MA.City,'')+
			COALESCE(', '+RTRIM(MA.StateProvince),'')+
			COALESCE(' '+LTRIM(MA.PostalCode),'')+
			COALESCE(' '+ MA.CountryCode,'')
			),' ',' ')AS MemberCityStateZipCountry,

		-- Vehicle Section
		-- Vehcile 
		ISNULL(RTRIM(COALESCE(c.VehicleYear +' ','')+
		COALESCE(CASE c.VehicleMake WHEN'Other'THEN C.VehicleMakeOther ELSE C.VehicleMake END+' ','')+
		COALESCE(CASE C.VehicleModel WHEN'Other'THEN C.VehicleModelOther ELSE C.VehicleModel END,'')),' ')AS [YearMakeModel],
		VT.Name +' - '+ VC.Name AS [VehicleTypeAndCategory],
		C.VehicleColor AS [VehicleColor],
		C.VehicleVIN AS [VehicleVIN],
		COALESCE(C.VehicleLicenseState +'-','')+COALESCE(c.VehicleLicenseNumber,'')AS [License],
		C.VehicleDescription,
		-- For vehicle type = RV only  
		RVT.Name AS [RVType],
		C.VehicleChassis AS [VehicleChassis],
		C.VehicleEngine AS [VehicleEngine],
		C.VehicleTransmission AS [VehicleTransmission],
		-- Location  
		SR.ServiceLocationAddress +' '+ SR.ServiceLocationCountryCode AS [ServiceLocationAddress],
		SR.ServiceLocationDescription,
		-- Destination
		SR.DestinationAddress +' '+ SR.DestinationCountryCode AS [DestinationAddress],
		SR.DestinationDescription,

		-- Service Section 
		CASE
			WHEN SR.IsPossibleTow = 1 
			THEN PC.Name +'/Possible Tow'
			ELSE PC.Name
		END AS [ServiceCategorySection],
		SR.PrimaryCoverageLimit AS CoverageLimit,
		CASE
			WHEN C.IsSafe IN(NULL,1)
			THEN'Yes'
			ELSE'No'
		END AS [Safe],
		SR.PrimaryProductID,
		(SELECT Name FROM Product WHERE ID = SR.PrimaryProductID) AS PrimaryProductName,
		SR.PrimaryServiceEligiblityMessage,
		SR.SecondaryProductID,
		(SELECT Name FROM Product WHERE ID = SR.SecondaryProductID) AS SecondaryProductName,
		SR.SecondaryServiceEligiblityMessage,
		SR.IsPrimaryOverallCovered,
		SR.IsSecondaryOverallCovered,
		SR.IsPossibleTow,
		

		-- Service Q&A's


		---- Service Provider Section  
		--CASE 
		--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NOT NULL THEN 'Contracted'
		--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NULL THEN 'Not Contracted'
		--	WHEN c.ID IS NOT NULL THEN 'Contracted' 
		--	ELSE 'Not Contracted'
		--	END as ContractStatus,
		CASE
			WHEN ContractedVendors.ContractID IS NOT NULL 
				AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'
			ELSE 'Not Contracted' 
			END AS ContractStatus,
		V.Name AS [VendorName],
		V.ID AS [VendorID],
		V.VendorNumber AS [VendorNumber],
		(SELECT TOP 1 PE.PhoneNumber
			FROM PhoneEntity PE
			WHERE PE.RecordID = VL.ID
			AND PE.EntityID = @vendorLocationEntityID
			AND PE.PhoneTypeID = @dispatchPhoneTypeID
			ORDER BY PE.ID DESC
		) AS [VendorLocationPhoneNumber] ,
		VLA.Line1 AS [VendorLocationLine1],
		VLA.Line2 AS [VendorLocationLine2],
		VLA.Line3 AS [VendorLocationLine3],
		REPLACE(RTRIM(
			COALESCE(VLA.City,'')+
			COALESCE(', '+RTRIM(VLA.StateProvince),'')+
			COALESCE(' '+LTRIM(VLA.PostalCode),'')+
			COALESCE(' '+ VLA.CountryCode,'')
			),' ',' ')AS VendorCityStateZipCountry,
		-- PO data
		convert(int,PO.PurchaseOrderNumber) AS [PONumber],
		PO.LegacyReferenceNumber,
		--convert(int,PO.ID) AS [PONumber],
		POS.Name AS [POStatus],
		CASE
				WHEN PO.CancellationReasonID = @otherReasonID
				THEN PO.CancellationReasonOther 
				ELSE ISNULL(CR.Name,'')
		END AS [CancelReason],
		PO.PurchaseOrderAmount AS [POAmount],
		POPC.Name AS [ServiceType],
		PO.IssueDate AS [IssueDate],
		PO.ETADate AS [ETADate],
		PO.DataTransferDate AS [ExtractDate],

		-- Other
		CASE WHEN C.AssignedToUserID IS NOT NULL
			THEN'*'+ISNULL(ASU.FirstName,'')+' '+ISNULL(ASU.LastName,'')
			ELSE ISNULL(SASU.FirstName,'')+' '+ISNULL(SASU.LastName,'')
		END AS [AssignedTo],
		C.AssignedToUserID AS [AssignedToID],
      
      -- Vendor Invoice Details
		VI.InvoiceDate,
		CASE	WHEN PT.Name = 'ACH' 
		THEN 'ACH'
				WHEN PT.Name = 'Check'
		THEN VI.PaymentNumber
		ELSE ''
		END AS PaymentType,
		
		VI.PaymentAmount,
		VI.PaymentDate,
		VI.CheckClearedDate
FROM [ServiceRequest](NOLOCK) SR  
JOIN [Case](NOLOCK) C ON C.ID = SR.CaseID  
JOIN [ServiceRequestStatus](NOLOCK) SRS ON SR.ServiceRequestStatusID = SRS.ID  
LEFT JOIN [ServiceRequestPriority](NOLOCK) SRP ON SR.ServiceRequestPriorityID = SRP.ID   
LEFT JOIN [Program](NOLOCK) P ON C.ProgramID = P.ID   
LEFT JOIN [Client](NOLOCK) CL ON P.ClientID = CL.ID  
LEFT JOIN [Member](NOLOCK) M ON C.MemberID = M.ID  
LEFT JOIN [Membership](NOLOCK) MS ON M.MembershipID = MS.ID  
LEFT JOIN [AddressEntity](NOLOCK) MA ON M.ID = MA.RecordID  
            AND MA.EntityID = @memberEntityID
LEFT JOIN [Country](NOLOCK) MCNTRY ON MA.CountryCode = MCNTRY.ISOCode  
LEFT JOIN [Country](NOLOCK) LCNTRY ON SR.ServiceLocationCountryCode = LCNTRY.ISOCode  
LEFT JOIN [Country](NOLOCK) DCNTRY ON SR.DestinationCountryCode = DCNTRY.ISOCode  
LEFT JOIN [VehicleType](NOLOCK) VT ON C.VehicleTypeID = VT.ID  
LEFT JOIN [VehicleCategory](NOLOCK) VC ON C.VehicleCategoryID = VC.ID  
LEFT JOIN [RVType](NOLOCK) RVT ON C.VehicleRVTypeID = RVT.ID  
LEFT JOIN [ProductCategory](NOLOCK) PC ON PC.ID = SR.ProductCategoryID  
LEFT JOIN [User](NOLOCK) ASU ON C.AssignedToUserID = ASU.ID  
LEFT OUTER JOIN [User](NOLOCK) SASU ON SR.NextActionAssignedToUserID = SASU.ID  
LEFT JOIN [PurchaseOrder](NOLOCK) PO ON PO.ServiceRequestID = SR.ID  AND PO.IsActive = 1 
LEFT JOIN [PurchaseOrderStatus](NOLOCK) POS ON PO.PurchaseOrderStatusID = POS.ID
LEFT JOIN [PurchaseOrderCancellationReason](NOLOCK) CR ON PO.CancellationReasonID = CR.ID
LEFT JOIN [Product](NOLOCK) PR ON PO.ProductID = PR.ID
LEFT JOIN [ProductCategory](NOLOCK) POPC ON PR.ProductCategoryID = POPC.ID
LEFT JOIN [VendorLocation](NOLOCK) VL ON PO.VendorLocationID = VL.ID  
LEFT JOIN [AddressEntity](NOLOCK) VLA ON VL.ID = VLA.RecordID 
            AND VLA.EntityID =@vendorLocationEntityID
LEFT JOIN [Vendor](NOLOCK) V ON VL.VendorID = V.ID 
LEFT JOIN [Contract](NOLOCK) CON on CON.VendorID = V.ID and CON.IsActive = 1 and CON.ContractStatusID = (Select ID From ContractStatus Where Name = 'Active')
LEFT JOIN [ClosedLoopStatus](NOLOCK) CLS ON SR.ClosedLoopStatusID = CLS.ID 
LEFT JOIN [NextAction](NOLOCK) NA ON SR.NextActionID = NA.ID

--Join to get information needed to determine Vendor Contract status ********************
--LEFT OUTER JOIN (
--      SELECT DISTINCT vr.VendorID, vr.ProductID
--      FROM dbo.fnGetCurrentProductRatesByVendorLocation() vr 
--      ) DefaultVendorRates ON v.ID = DefaultVendorRates.VendorID And @ProductID = DefaultVendorRates.ProductID
LEFT OUTER JOIN(
	  SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID
	  FROM dbo.fnGetContractedVendors() cv
	  ) ContractedVendors ON v.ID = ContractedVendors.VendorID 
      
LEFT JOIN [VendorInvoice] VI WITH (NOLOCK) ON PO.ID = VI.PurchaseOrderID
LEFT JOIN [PaymentType] PT WITH (NOLOCK) ON VI.PaymentTypeID = PT.ID
WHERE SR.ID = @serviceRequestID

END
GO

GO
/* KB: This is procedure is not in use and the logic is moved to dms_Service_Save. The SP is retained in TFS for reference purposes only */
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_servicerequest_productids_set]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_servicerequest_productids_set] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
-- EXEC [dbo].[dms_servicerequest_productids_set] 2,5,1,1,0,3
CREATE PROCEDURE [dbo].[dms_servicerequest_productids_set]( 
	@serviceRequestID INT,
	@ProductCategoryID INT,
	@VehicleTypeID INT,
	@VehicleCategoryID INT,
	@IsPossibleTow BIT,
	@programID INT
)
AS
BEGIN

--SET @ProductCategoryID = (Select ID From ProductCategory Where Name = 'Jump')
--SET @VehicleTypeID = (Select ID From VehicleType Where Name = 'Auto')
--SET @VehicleCategoryID = (Select ID From VehicleCategory Where Name = 'HeavyDuty')
--SET @IsPossibleTow = 'TRUE'
	DECLARE @tmpPrograms TABLE
	(
		LevelID INT IDENTITY(1,1),
		ProgramID INT
	)
	
	INSERT INTO @tmpPrograms
	SELECT ProgramID FROM fnc_GetProgramsandParents (@programID)

	--DEBUG: SELECT * FROM @tmpPrograms
	
	DECLARE @TowProductCategoryID int
	DECLARE @primaryProductID INT
	DECLARE @secondaryProductID INT
	DECLARE @isPrimaryServiceCovered BIT
	DECLARE @isSecondaryServiceCovered BIT

	SET @primaryProductID = NULL
	SET @secondaryProductID = NULL
	
	SET @TowProductCategoryID = (Select ID From ProductCategory Where Name = 'Tow')

	;WITH wPrimaryProducts
	AS
	(
	SELECT	ROW_NUMBER() OVER (PARTITION BY P.ID ORDER BY T.LevelID ASC) AS RowNum,
			T.ProgramID AS ProgramID,			
			p.ID AS ProductID,
			pp.ID AS ProgramProductID,
			pp.IsReimbursementOnly
	FROM	dbo.Product p
	JOIN	dbo.ProductType pt ON p.ProductTypeID = pt.ID
	JOIN	dbo.ProductSubType pst ON p.ProductSubTypeID = pst.ID
	JOIN	dbo.ProductCategory pc ON p.ProductCategoryID = pc.ID
	JOIN	dbo.ProgramProduct pp ON pp.ProductID = P.ID --AND pp.ProgramID = @programID
	JOIN	@tmpPrograms T ON pp.ProgramID = T.ProgramID
	WHERE	pt.Name = 'Service'
	AND		pst.Name = 'PrimaryService'
	AND		pc.ID = @ProductCategoryID
	AND		(p.VehicleTypeID = @VehicleTypeID OR p.VehicleTypeID IS NULL)
	AND (p.VehicleCategoryID = @VehicleCategoryID OR p.VehicleCategoryID IS NULL)
	)
	
	SELECT	@primaryProductID = ProductID,
			@isPrimaryServiceCovered = CASE WHEN ProgramProductID IS NULL OR ISNULL(IsReimbursementOnly, 0) = 1 
											THEN 0 
											ELSE 1 
										END		
	FROM wPrimaryProducts
	
	;WITH wSecondaryProducts
	AS
	(
	SELECT	ROW_NUMBER() OVER (PARTITION BY P.ID ORDER BY T.LevelID ASC) AS RowNum,
			T.ProgramID AS ProgramID,			
			p.ID AS ProductID,
			pp.ID AS ProgramProductID,
			pp.IsReimbursementOnly
	FROM	dbo.Product p
	JOIN	dbo.ProductType pt ON p.ProductTypeID = pt.ID
	JOIN	dbo.ProductSubType pst ON p.ProductSubTypeID = pst.ID
	JOIN	dbo.ProductCategory pc ON p.ProductCategoryID = pc.ID
	JOIN	dbo.ProgramProduct pp ON pp.ProductID = p.ID  -- AND pp.ProgramID = @programID
	JOIN	@tmpPrograms T ON pp.ProgramID = T.ProgramID
	WHERE	pt.Name = 'Service'
	AND		pst.Name = 'PrimaryService'
	AND		@IsPossibleTow = 'TRUE'
	AND		pc.ID = @TowProductCategoryID
	AND		(p.VehicleTypeID = @VehicleTypeID OR p.VehicleTypeID IS NULL)
	AND		(p.VehicleCategoryID = @VehicleCategoryID OR p.VehicleCategoryID IS NULL)	
	)
	
	SELECT	@secondaryProductID = ProductID,
			@isSecondaryServiceCovered = CASE WHEN ProgramProductID IS NULL OR ISNULL(IsReimbursementOnly, 0) = 1 
											THEN 0 
											ELSE 1 
										END		
	FROM wSecondaryProducts

	
	UPDATE	ServiceRequest
	SET		PrimaryProductID = @primaryProductID,
			SecondaryProductID = @secondaryProductID,
			IsPrimaryProductCovered = @isPrimaryServiceCovered,
			IsSecondaryProductCovered = @isSecondaryServiceCovered
	WHERE	ID = @serviceRequestID
	
	
END


GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ServiceRequest_Vendor_Details_From_Map_Update]')   		AND type in (N'P', N'PC')) 
 BEGIN
DROP PROCEDURE [dbo].[dms_ServiceRequest_Vendor_Details_From_Map_Update]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  
 -- EXEC [dms_ServiceRequest_Vendor_Details_From_Map_Update] 1414
CREATE PROCEDURE [dbo].[dms_ServiceRequest_Vendor_Details_From_Map_Update]  
 @serviceRequestID INT	= NULL 
AS  
BEGIN

	UPDATE	ServiceRequest
	SET		DealerIDNumber = VL.DealerNumber,
			PartsAndAccessoryCode = VL.PartsAndAccessoryCode,
			IsDirectTowDealer = CASE WHEN VLP.ID IS NULL THEN 0 ELSE 1 END
	FROM	ServiceRequest SR
	JOIN	VendorLocation VL ON SR.DestinationVendorLocationID = VL.ID
	LEFT JOIN	VendorLocationProduct VLP ON VLP.VendorLocationID = VL.ID AND VLP.ProductID = 
						(
							SELECT ID FROM Product WHERE Name = 'Ford Direct Tow' 
						)
	WHERE	SR.ID = @serviceRequestID
	


END
GO

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

GO
 
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Service_Save]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Service_Save]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 
CREATE PROC dms_Service_Save(@serviceRequestID INT
,@inputXML NVARCHAR(MAX)
,@userName NVARCHAR(50)
,@vehicleTypeID INT = NULL)  
AS  
BEGIN  
 DECLARE @idoc int  
 EXEC sp_xml_preparedocument @idoc OUTPUT, @inputXML  
   
 DECLARE @tmpForInput TABLE  
 (  
  ServiceRequestID INT NULL,  
  ProductCategoryQuestionID INT NOT NULL,  
  Answer NVARCHAR(MAX) NULL,  
  CreateDate DATETIME DEFAULT GETDATE(),  
  CreatedBy NVARCHAR(50) NULL,  
  ModifyDate DATETIME DEFAULT GETDATE(),  
  ModifiedBy NVARCHAR(50) NULL  
 )  
  
 INSERT INTO @tmpForInput( ProductCategoryQuestionID,  
  Answer  
    )  
 SELECT    
  ProductCategoryQuestionID,  
  Answer  
 FROM   
  OPENXML (@idoc,'/ROW/Data',1) WITH (  
   ProductCategoryQuestionID INT,  
   Answer NVARCHAR(MAX)  
  )   
   
 UPDATE @tmpForInput  
 SET  ServiceRequestID = @serviceRequestID,  
   CreatedBy    = @userName,  
   ModifiedBy    = @userName  
 
 
-- KB: Let's clear off existing values and add the new values.
 DELETE FROM ServiceRequestDetail WHERE ServiceRequestID = @serviceRequestID
   
 -- INSERT NEW Records  
 INSERT INTO  ServiceRequestDetail   
 SELECT  
  T.[ServiceRequestID],  
  T.[ProductCategoryQuestionID],  
  T.[Answer],  
  T.[CreateDate],  
  T.[CreatedBy],  
  T.[ModifyDate],  
  T.[ModifiedBy]  
 FROM @tmpForInput T   
 WHERE T.ProductCategoryQuestionID NOT IN (SELECT ProductCategoryQuestionID FROM ServiceRequestDetail WHERE ServiceRequestID = @serviceRequestID)    
  
 -- CR: 1097 : Set the product IDs based on the answers provided.
 DECLARE @vehicleCategoryID INT = NULL
 DECLARE @isPossibleTow BIT = 0
 DECLARE @productCategoryID INT = NULL
 DECLARE @programID INT = NULL
 DECLARE @pPrimaryProductID INT = NULL
 DECLARE @pSecondaryProductID INT = NULL
  
 DECLARE @primaryProductID INT = NULL
 DECLARE @secondaryProductID INT = NULL
 DECLARE @isPrimaryServiceCovered BIT = NULL
 DECLARE @isSecondaryServiceCovered BIT = NULL
 DECLARE @towProductCategoryID int = NULL
 SET @towProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tow')
 DECLARE @tmpPrograms TABLE
 (
 LevelID INT IDENTITY(1,1),
 ProgramID INT
 )
 SELECT @vehicleCategoryID = SR.VehicleCategoryID,
   @productCategoryID = SR.ProductCategoryID,
   @isPossibleTow = SR.IsPossibleTow,
   @programID = C.ProgramID
 FROM  ServiceRequest SR,
   [Case] C
 WHERE  SR.CaseID = C.ID
 AND  SR.ID = @serviceRequestID
  
 INSERT INTO @tmpPrograms
 SELECT ProgramID FROM fnc_GetProgramsandParents (@programID)
  /*
 *  Determine PrimaryProducID
 *  Get value from ServiceType dropdown
 *  Look at all the answers to those category questions and see if any have a ProductID defined.
 *  If a ProductCategoryQuestionValue.ProductID is defined for any of the answers given for this category then use that ProductID to set PrimaryProductID
 *  Right now there is only 1 question/answer that will have a product defined and that is Lockout / Do you need a locksmith? / Yes / ProductID=9
 *  If Tow is selected in the ServiceType dropdown then there might be a special type tow product defined on an answer under towing. This will go in PrimaryProductID because Tow is set as the primary service.
 */
 
 SELECT @pPrimaryProductID = W.ProductID
 FROM
 (SELECT TOP 1 PCQV.ProductID
 FROM  ProductCategoryQuestionValue PCQV
 JOIN  ServiceRequestDetail SRD ON PCQV.ProductCategoryQuestionID = SRD.ProductCategoryQuestionID AND SRD.Answer = PCQV.Value
 JOIN  ProductCategoryQuestion PCQ ON PCQV.ProductCategoryQuestionID = PCQ.ID
 WHERE  SRD.ServiceRequestID = @serviceRequestID
 AND   PCQ.ProductCategoryID = @productCategoryID
 AND   PCQV.ProductID IS NOT NULL) W
    /*Tim's SQL: Logic to select Basic Lockout over Locksmith within Lockout Product Category */
    
IF @pPrimaryProductID IS NULL AND @productCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Lockout')
BEGIN
 SET @pPrimaryProductID = (SELECT ID FROM Product WHERE Name = 'Basic Lockout')
END
/* Select Tire Change over Tire Repair when one of the tire services is not specifically selected */
IF @pPrimaryProductID IS NULL AND @productCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tire')
BEGIN
 SET @pPrimaryProductID = (SELECT ID FROM Product WHERE Name like 'Tire Change%' AND VehicleCategoryID = @VehicleCategoryID)
END
/*  
 *  Determine SecondaryProductID
 *  If IsPossibleTow = Yes then look for a secondary product id.
 *  It turns out that we can't just pass Tow-LD every time. We have to look at some answers to Tow questions to see if there is a special type of tow needed.
 *  Look through the Tow category answers to see if any have a ProductID defined, if they do then use that to set the SecondaryProductID sent to the stored proc.
 *  Right now there is only one question: Speical Tow that has answers that will have ProductID's defined. Flatbed Tow, Enclosed Hauler, etc.
 */
 
 IF @isPossibleTow = 1
 BEGIN
  SELECT @pSecondaryProductID = W.ProductID
  FROM
  (SELECT TOP 1 PCQV.ProductID
  FROM  ProductCategoryQuestionValue PCQV
  JOIN  ProductCategoryQuestion PCQ ON PCQ.ID = PCQV.ProductCategoryQuestionID
  JOIN  ServiceRequestDetail SRD ON PCQV.ProductCategoryQuestionID = SRD.ProductCategoryQuestionID AND SRD.Answer = PCQV.Value
  WHERE  SRD.ServiceRequestID = @serviceRequestID
  AND   PCQ.ProductCategoryID = @towProductCategoryID
  AND   PCQV.ProductID IS NOT NULL
  ) W
  
 END
 
 ;WITH wPrimaryProducts
 AS
 (
  SELECT ROW_NUMBER() OVER (PARTITION BY P.ID ORDER BY T.LevelID ASC) AS RowNum,
  T.ProgramID AS ProgramID, 
  p.ID AS ProductID,
  pp.ID AS ProgramProductID,
  pp.IsReimbursementOnly
  FROM dbo.Product p
  JOIN dbo.ProductType pt ON p.ProductTypeID = pt.ID
  JOIN dbo.ProductSubType pst ON p.ProductSubTypeID = pst.ID
  JOIN dbo.ProductCategory pc ON p.ProductCategoryID = pc.ID
  JOIN dbo.ProgramProduct pp ON pp.ProductID = P.ID --AND pp.ProgramID = @programID
  JOIN @tmpPrograms T ON pp.ProgramID = T.ProgramID
  WHERE 
  (p.ID = @pPrimaryProductID)
  OR
  (
   @pPrimaryProductID IS NULL
   AND pt.Name = 'Service'
   AND pst.Name = 'PrimaryService'
   AND pc.ID = @productCategoryID
   AND (p.VehicleTypeID = @vehicleTypeID OR p.VehicleTypeID IS NULL)
   AND (p.VehicleCategoryID = @vehicleCategoryID OR p.VehicleCategoryID IS NULL)
  )
 )
 SELECT @primaryProductID = ProductID,
 @isPrimaryServiceCovered = CASE WHEN ProgramProductID IS NULL OR ISNULL(IsReimbursementOnly, 0) = 1 
         THEN 0 
         ELSE 1 
        END 
 FROM wPrimaryProducts
 ;WITH wSecondaryProducts
 AS
 (
  SELECT ROW_NUMBER() OVER (PARTITION BY P.ID ORDER BY T.LevelID ASC) AS RowNum,
  T.ProgramID AS ProgramID, 
  p.ID AS ProductID,
  pp.ID AS ProgramProductID,
  pp.IsReimbursementOnly
  FROM dbo.Product p
  JOIN dbo.ProductType pt ON p.ProductTypeID = pt.ID
  JOIN dbo.ProductSubType pst ON p.ProductSubTypeID = pst.ID
  JOIN dbo.ProductCategory pc ON p.ProductCategoryID = pc.ID
  JOIN dbo.ProgramProduct pp ON pp.ProductID = p.ID -- AND pp.ProgramID = @programID
  JOIN @tmpPrograms T ON pp.ProgramID = T.ProgramID
  WHERE 
  (p.ID = @pSecondaryProductID)
  OR
  (
   @pSecondaryProductID IS NULL
   AND pt.Name = 'Service'
   AND pst.Name = 'PrimaryService'
   AND @isPossibleTow = 'TRUE'
   AND pc.ID = @towProductCategoryID
   AND (p.VehicleTypeID = @vehicleTypeID OR p.VehicleTypeID IS NULL)
   AND (p.VehicleCategoryID = @vehicleCategoryID OR p.VehicleCategoryID IS NULL) 
  )
 )
 SELECT @secondaryProductID = ProductID,
   @isSecondaryServiceCovered = CASE WHEN ProgramProductID IS NULL OR ISNULL(IsReimbursementOnly, 0) = 1 
            THEN 0 
            ELSE 1 
           END 
 FROM wSecondaryProducts
 UPDATE ServiceRequest
 SET 
  PrimaryProductID = @primaryProductID,
  SecondaryProductID = @secondaryProductID,
  IsPrimaryProductCovered = @isPrimaryServiceCovered,
  IsSecondaryProductCovered = @isSecondaryServiceCovered
 WHERE ID = @serviceRequestID

  
   
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
 WHERE id = object_id(N'[dbo].[dms_Temporary_CC_Batch_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Temporary_CC_Batch_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Temporary_CC_Batch_List]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = 'CreateDate' 
 , @sortOrder nvarchar(100) = 'DESC' 
  
 ) 
 AS 
 BEGIN 
      SET FMTONLY OFF;
     SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
      SET @whereClauseXML = '<ROW><Filter 

></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
BatchStatusID int NULL,
FromDate DATETIME NULL,
ToDate DATETIME NULL
)
CREATE TABLE #FinalResults( 
      [RowNum] [bigint] NOT NULL IDENTITY(1,1),
      ID int  NULL ,
      BatchType nvarchar(100)  NULL ,
      BatchStatusID int  NULL ,
      BatchStatus nvarchar(100)  NULL ,
      TotalCount int  NULL ,
      TotalAmount money  NULL ,    
      CreateDate datetime  NULL ,
      CreateBy nvarchar(100)  NULL ,
      ModifyDate datetime  NULL ,
      ModifyBy nvarchar(100)  NULL,
      CreditCardIssueNumber nvarchar(100) NULL
) 

CREATE TABLE #tmpFinalResults( 
      [RowNum] [bigint] NOT NULL IDENTITY(1,1),
      ID int  NULL ,
      BatchType nvarchar(100)  NULL ,
      BatchStatusID int  NULL ,
      BatchStatus nvarchar(100)  NULL ,
      TotalCount int  NULL ,
      TotalAmount money  NULL ,     
      CreateDate datetime  NULL ,
      CreateBy nvarchar(100)  NULL ,
      ModifyDate datetime  NULL ,
      ModifyBy nvarchar(100)  NULL,
      CreditCardIssueNumber nvarchar(100) NULL
) 

INSERT INTO #tmpForWhereClause
SELECT 
      T.c.value('@BatchStatusID','int') ,
      T.c.value('@FromDate','datetime') ,
      T.c.value('@ToDate','datetime') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @batchStatusID NVARCHAR(100) = NULL,
            @fromDate DATETIME = NULL,
            @toDate DATETIME = NULL
            
SELECT      @batchStatusID = BatchStatusID, 
            @fromDate = FromDate,
            @toDate = ToDate
FROM  #tmpForWhereClause
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------


INSERT INTO #tmpFinalResults
SELECT      B.ID
            , BT.[Description] AS BatchType
            , B.BatchStatusID
            , BS.Name AS BatchStatus
            , B.TotalCount AS TotalCount
            , B.TotalAmount AS TotalAmount
            , B.CreateDate
            , B.CreateBy
            , B.ModifyDate
            , B.ModifyBy 
            , TCC.CreditCardIssueNumber
FROM  Batch B
JOIN  BatchType BT ON BT.ID = B.BatchTypeID
JOIN  BatchStatus BS ON BS.ID = B.BatchStatusID
LEFT JOIN TemporaryCreditCard TCC ON TCC.PostingBatchID = B.ID
WHERE B.BatchTypeID = (SELECT ID FROM BatchType WHERE Name = 'TemporaryCCPost')
AND         (@batchStatusID IS NULL OR @batchStatusID = B.BatchStatusID)
AND         (@fromDate IS NULL OR B.CreateDate > @fromDate)
AND         (@toDate IS NULL OR B.CreateDate < @toDate)
GROUP BY    B.ID
            , BT.[Description] 
            , B.BatchStatusID
            , BS.Name  
            , B.TotalCount
            , B.TotalAmount         
            , B.CreateDate
            , B.CreateBy
            , B.ModifyDate
            , B.ModifyBy
            , TCC.CreditCardIssueNumber
ORDER BY B.CreateDate DESC



INSERT INTO #FinalResults
SELECT 
      T.ID,
      T.BatchType,
      T.BatchStatusID,
      T.BatchStatus,
      T.TotalCount,
      T.TotalAmount,    
      T.CreateDate,
      T.CreateBy,
      T.ModifyDate,
      T.ModifyBy,
      T.CreditCardIssueNumber
      
FROM #tmpFinalResults T

ORDER BY 
       CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
      THEN T.ID END ASC, 
       CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
      THEN T.ID END DESC ,

      CASE WHEN @sortColumn = 'BatchType' AND @sortOrder = 'ASC'
      THEN T.BatchType END ASC, 
       CASE WHEN @sortColumn = 'BatchType' AND @sortOrder = 'DESC'
      THEN T.BatchType END DESC ,

      CASE WHEN @sortColumn = 'BatchStatusID' AND @sortOrder = 'ASC'
      THEN T.BatchStatusID END ASC, 
       CASE WHEN @sortColumn = 'BatchStatusID' AND @sortOrder = 'DESC'
      THEN T.BatchStatusID END DESC ,

      CASE WHEN @sortColumn = 'BatchStatus' AND @sortOrder = 'ASC'
      THEN T.BatchStatus END ASC, 
       CASE WHEN @sortColumn = 'BatchStatus' AND @sortOrder = 'DESC'
      THEN T.BatchStatus END DESC ,

      CASE WHEN @sortColumn = 'TotalCount' AND @sortOrder = 'ASC'
      THEN T.TotalCount END ASC, 
       CASE WHEN @sortColumn = 'TotalCount' AND @sortOrder = 'DESC'
      THEN T.TotalCount END DESC ,

      CASE WHEN @sortColumn = 'TotalAmount' AND @sortOrder = 'ASC'
      THEN T.TotalAmount END ASC, 
       CASE WHEN @sortColumn = 'TotalAmount' AND @sortOrder = 'DESC'
      THEN T.TotalAmount END DESC ,     

      CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'
      THEN T.CreateDate END ASC, 
       CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'
      THEN T.CreateDate END DESC ,

      CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
      THEN T.CreateBy END ASC, 
       CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
      THEN T.CreateBy END DESC ,

      CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'ASC'
      THEN T.ModifyDate END ASC, 
       CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'DESC'
      THEN T.ModifyDate END DESC ,

      CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'ASC'
      THEN T.ModifyBy END ASC, 
       CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'DESC'
      THEN T.ModifyBy END DESC ,

      CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'ASC'
      THEN T.CreditCardIssueNumber END ASC, 
       CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'DESC'
      THEN T.CreditCardIssueNumber END DESC 


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
DROP TABLE #tmpFinalResults
END

GO
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
 WHERE id = object_id(N'[dbo].[dms_Temporary_CC_Batch_Payment_Runs_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Temporary_CC_Batch_Payment_Runs_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC [dms_Temporary_CC_Batch_Payment_Runs_List_Get] @BatchID = 169 , @GLAccountName='6300-310-00'
 CREATE PROCEDURE [dbo].[dms_Temporary_CC_Batch_Payment_Runs_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @BatchID INT = NULL  
 , @GLAccountName nvarchar(11) = NULL
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
TemporaryCCIDOperator="-1" 
TemporaryCCNumberOperator="-1" 
CCIssueDateOperator="-1" 
CCIssueByOperator="-1" 
CCApproveOperator="-1" 
CCChargeOperator="-1" 
POIDOperator="-1" 
PONumberOperator="-1" 
POAmountOperator="-1" 
InvoiceIDOperator="-1" 
InvoiceNumberOperator="-1" 
InvoiceAmountOperator="-1" 
CreditCardIssueNumberOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
TemporaryCCIDOperator INT NOT NULL,
TemporaryCCIDValue int NULL,
TemporaryCCNumberOperator INT NOT NULL,
TemporaryCCNumberValue nvarchar(100) NULL,
CCIssueDateOperator INT NOT NULL,
CCIssueDateValue datetime NULL,
CCIssueByOperator INT NOT NULL,
CCIssueByValue nvarchar(100) NULL,
CCApproveOperator INT NOT NULL,
CCApproveValue money NULL,
CCChargeOperator INT NOT NULL,
CCChargeValue money NULL,
POIDOperator INT NOT NULL,
POIDValue int NULL,
PONumberOperator INT NOT NULL,
PONumberValue nvarchar(100) NULL,
POAmountOperator INT NOT NULL,
POAmountValue money NULL,
InvoiceIDOperator INT NOT NULL,
InvoiceIDValue int NULL,
InvoiceNumberOperator INT NOT NULL,
InvoiceNumberValue nvarchar(100) NULL,
InvoiceAmountOperator INT NOT NULL,
InvoiceAmountValue money NULL,
CreditCardIssueNumberOperator INT NOT NULL,
CreditCardIssueNumberValue nvarchar(100) NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	TemporaryCCID int  NULL ,
	TemporaryCCNumber nvarchar(100)  NULL ,
	CCIssueDate datetime  NULL ,
	CCIssueBy nvarchar(100)  NULL ,
	CCApprove money  NULL ,
	CCCharge money  NULL ,
	POID int  NULL ,
	PONumber nvarchar(100)  NULL ,
	POAmount money  NULL ,
	InvoiceID int  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceAmount money  NULL,
	CreditCardIssueNumber nvarchar(100)  NULL 
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	TemporaryCCID int  NULL ,
	TemporaryCCNumber nvarchar(100)  NULL ,
	CCIssueDate datetime  NULL ,
	CCIssueBy nvarchar(100)  NULL ,
	CCApprove money  NULL ,
	CCCharge money  NULL ,
	POID int  NULL ,
	PONumber nvarchar(100)  NULL ,
	POAmount money  NULL ,
	InvoiceID int  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceAmount money  NULL ,
	CreditCardIssueNumber nvarchar(100)  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@TemporaryCCIDOperator','INT'),-1),
	T.c.value('@TemporaryCCIDValue','int') ,
	ISNULL(T.c.value('@TemporaryCCNumberOperator','INT'),-1),
	T.c.value('@TemporaryCCNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CCIssueDateOperator','INT'),-1),
	T.c.value('@CCIssueDateValue','datetime') ,
	ISNULL(T.c.value('@CCIssueByOperator','INT'),-1),
	T.c.value('@CCIssueByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CCApproveOperator','INT'),-1),
	T.c.value('@CCApproveValue','money') ,
	ISNULL(T.c.value('@CCChargeOperator','INT'),-1),
	T.c.value('@CCChargeValue','money') ,
	ISNULL(T.c.value('@POIDOperator','INT'),-1),
	T.c.value('@POIDValue','int') ,
	ISNULL(T.c.value('@PONumberOperator','INT'),-1),
	T.c.value('@PONumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@POAmountOperator','INT'),-1),
	T.c.value('@POAmountValue','money') ,
	ISNULL(T.c.value('@InvoiceIDOperator','INT'),-1),
	T.c.value('@InvoiceIDValue','int') ,
	ISNULL(T.c.value('@InvoiceNumberOperator','INT'),-1),
	T.c.value('@InvoiceNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@InvoiceAmountOperator','INT'),-1),
	T.c.value('@InvoiceAmountValue','money') ,
	ISNULL(T.c.value('@CreditCardIssueNumberOperator','INT'),-1),
	T.c.value('@CreditCardIssueNumberValue','nvarchar(100)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT 
  TCC.ID AS TemporaryCCID
, TCC.CreditCardNumber AS TemporaryCCNumber
, TCC.IssueDate AS CCIssueDate
, TCC.IssueBy AS CCIssueBy
, TCC.ApprovedAmount AS CCApprove
, TCC.TotalChargedAmount AS CCCharge
, PO.ID AS POID
, PO.PurchaseOrderNumber AS PONumber
, PO.PurchaseOrderAmount AS POAmount 
, VI.ID AS InvoiceID
, VI.InvoiceNumber AS InvoiceNumber
, VI.InvoiceAmount AS InvoiceAmount
, TCC.CreditCardIssueNumber AS CreditCardIssueNumber
FROM	TemporaryCreditCard TCC
LEFT JOIN	PurchaseOrder PO ON PO.PurchaseOrderNumber = TCC.ReferencePurchaseOrderNumber
LEFT JOIN   VendorInvoice VI ON VI.PurchaseOrderID = PO.ID
WHERE TCC.PostingBatchID = @BatchID AND VI.GLExpenseAccount = @GLAccountName

INSERT INTO #FinalResults
SELECT 
	T.TemporaryCCID,
	T.TemporaryCCNumber,
	T.CCIssueDate,
	T.CCIssueBy,
	T.CCApprove,
	T.CCCharge,
	T.POID,
	T.PONumber,
	T.POAmount,
	T.InvoiceID,
	T.InvoiceNumber,
	T.InvoiceAmount,
	T.CreditCardIssueNumber
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.TemporaryCCIDOperator = -1 ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 0 AND T.TemporaryCCID IS NULL ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 1 AND T.TemporaryCCID IS NOT NULL ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 2 AND T.TemporaryCCID = TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 3 AND T.TemporaryCCID <> TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 7 AND T.TemporaryCCID > TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 8 AND T.TemporaryCCID >= TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 9 AND T.TemporaryCCID < TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 10 AND T.TemporaryCCID <= TMP.TemporaryCCIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.TemporaryCCNumberOperator = -1 ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 0 AND T.TemporaryCCNumber IS NULL ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 1 AND T.TemporaryCCNumber IS NOT NULL ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 2 AND T.TemporaryCCNumber = TMP.TemporaryCCNumberValue ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 3 AND T.TemporaryCCNumber <> TMP.TemporaryCCNumberValue ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 4 AND T.TemporaryCCNumber LIKE TMP.TemporaryCCNumberValue + '%') 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 5 AND T.TemporaryCCNumber LIKE '%' + TMP.TemporaryCCNumberValue ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 6 AND T.TemporaryCCNumber LIKE '%' + TMP.TemporaryCCNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CCIssueDateOperator = -1 ) 
 OR 
	 ( TMP.CCIssueDateOperator = 0 AND T.CCIssueDate IS NULL ) 
 OR 
	 ( TMP.CCIssueDateOperator = 1 AND T.CCIssueDate IS NOT NULL ) 
 OR 
	 ( TMP.CCIssueDateOperator = 2 AND T.CCIssueDate = TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 3 AND T.CCIssueDate <> TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 7 AND T.CCIssueDate > TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 8 AND T.CCIssueDate >= TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 9 AND T.CCIssueDate < TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 10 AND T.CCIssueDate <= TMP.CCIssueDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CCIssueByOperator = -1 ) 
 OR 
	 ( TMP.CCIssueByOperator = 0 AND T.CCIssueBy IS NULL ) 
 OR 
	 ( TMP.CCIssueByOperator = 1 AND T.CCIssueBy IS NOT NULL ) 
 OR 
	 ( TMP.CCIssueByOperator = 2 AND T.CCIssueBy = TMP.CCIssueByValue ) 
 OR 
	 ( TMP.CCIssueByOperator = 3 AND T.CCIssueBy <> TMP.CCIssueByValue ) 
 OR 
	 ( TMP.CCIssueByOperator = 4 AND T.CCIssueBy LIKE TMP.CCIssueByValue + '%') 
 OR 
	 ( TMP.CCIssueByOperator = 5 AND T.CCIssueBy LIKE '%' + TMP.CCIssueByValue ) 
 OR 
	 ( TMP.CCIssueByOperator = 6 AND T.CCIssueBy LIKE '%' + TMP.CCIssueByValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CCApproveOperator = -1 ) 
 OR 
	 ( TMP.CCApproveOperator = 0 AND T.CCApprove IS NULL ) 
 OR 
	 ( TMP.CCApproveOperator = 1 AND T.CCApprove IS NOT NULL ) 
 OR 
	 ( TMP.CCApproveOperator = 2 AND T.CCApprove = TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 3 AND T.CCApprove <> TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 7 AND T.CCApprove > TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 8 AND T.CCApprove >= TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 9 AND T.CCApprove < TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 10 AND T.CCApprove <= TMP.CCApproveValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CCChargeOperator = -1 ) 
 OR 
	 ( TMP.CCChargeOperator = 0 AND T.CCCharge IS NULL ) 
 OR 
	 ( TMP.CCChargeOperator = 1 AND T.CCCharge IS NOT NULL ) 
 OR 
	 ( TMP.CCChargeOperator = 2 AND T.CCCharge = TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 3 AND T.CCCharge <> TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 7 AND T.CCCharge > TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 8 AND T.CCCharge >= TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 9 AND T.CCCharge < TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 10 AND T.CCCharge <= TMP.CCChargeValue ) 

 ) 

 AND 

 ( 
	 ( TMP.POIDOperator = -1 ) 
 OR 
	 ( TMP.POIDOperator = 0 AND T.POID IS NULL ) 
 OR 
	 ( TMP.POIDOperator = 1 AND T.POID IS NOT NULL ) 
 OR 
	 ( TMP.POIDOperator = 2 AND T.POID = TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 3 AND T.POID <> TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 7 AND T.POID > TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 8 AND T.POID >= TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 9 AND T.POID < TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 10 AND T.POID <= TMP.POIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.PONumberOperator = -1 ) 
 OR 
	 ( TMP.PONumberOperator = 0 AND T.PONumber IS NULL ) 
 OR 
	 ( TMP.PONumberOperator = 1 AND T.PONumber IS NOT NULL ) 
 OR 
	 ( TMP.PONumberOperator = 2 AND T.PONumber = TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 3 AND T.PONumber <> TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 4 AND T.PONumber LIKE TMP.PONumberValue + '%') 
 OR 
	 ( TMP.PONumberOperator = 5 AND T.PONumber LIKE '%' + TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 6 AND T.PONumber LIKE '%' + TMP.PONumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.POAmountOperator = -1 ) 
 OR 
	 ( TMP.POAmountOperator = 0 AND T.POAmount IS NULL ) 
 OR 
	 ( TMP.POAmountOperator = 1 AND T.POAmount IS NOT NULL ) 
 OR 
	 ( TMP.POAmountOperator = 2 AND T.POAmount = TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 3 AND T.POAmount <> TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 7 AND T.POAmount > TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 8 AND T.POAmount >= TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 9 AND T.POAmount < TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 10 AND T.POAmount <= TMP.POAmountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.InvoiceIDOperator = -1 ) 
 OR 
	 ( TMP.InvoiceIDOperator = 0 AND T.InvoiceID IS NULL ) 
 OR 
	 ( TMP.InvoiceIDOperator = 1 AND T.InvoiceID IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceIDOperator = 2 AND T.InvoiceID = TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 3 AND T.InvoiceID <> TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 7 AND T.InvoiceID > TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 8 AND T.InvoiceID >= TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 9 AND T.InvoiceID < TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 10 AND T.InvoiceID <= TMP.InvoiceIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.InvoiceNumberOperator = -1 ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 0 AND T.InvoiceNumber IS NULL ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 1 AND T.InvoiceNumber IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 2 AND T.InvoiceNumber = TMP.InvoiceNumberValue ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 3 AND T.InvoiceNumber <> TMP.InvoiceNumberValue ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 4 AND T.InvoiceNumber LIKE TMP.InvoiceNumberValue + '%') 
 OR 
	 ( TMP.InvoiceNumberOperator = 5 AND T.InvoiceNumber LIKE '%' + TMP.InvoiceNumberValue ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 6 AND T.InvoiceNumber LIKE '%' + TMP.InvoiceNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.InvoiceAmountOperator = -1 ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 0 AND T.InvoiceAmount IS NULL ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 1 AND T.InvoiceAmount IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 2 AND T.InvoiceAmount = TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 3 AND T.InvoiceAmount <> TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 7 AND T.InvoiceAmount > TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 8 AND T.InvoiceAmount >= TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 9 AND T.InvoiceAmount < TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 10 AND T.InvoiceAmount <= TMP.InvoiceAmountValue ) 

 ) 



 AND 
 
 ( 
	 ( TMP.CreditCardIssueNumberOperator = -1 ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 0 AND T.CreditCardIssueNumber IS NULL ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 1 AND T.CreditCardIssueNumber IS NOT NULL ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 2 AND T.CreditCardIssueNumber = TMP.CreditCardIssueNumberValue ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 3 AND T.CreditCardIssueNumber <> TMP.CreditCardIssueNumberValue ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 4 AND T.CreditCardIssueNumber LIKE TMP.CreditCardIssueNumberValue + '%') 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 5 AND T.CreditCardIssueNumber LIKE '%' + TMP.CreditCardIssueNumberValue ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 6 AND T.CreditCardIssueNumber LIKE '%' + TMP.CreditCardIssueNumberValue + '%' ) 
 ) 

 AND 
 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'TemporaryCCID' AND @sortOrder = 'ASC'
	 THEN T.TemporaryCCID END ASC, 
	 CASE WHEN @sortColumn = 'TemporaryCCID' AND @sortOrder = 'DESC'
	 THEN T.TemporaryCCID END DESC ,

	 CASE WHEN @sortColumn = 'TemporaryCCNumber' AND @sortOrder = 'ASC'
	 THEN T.TemporaryCCNumber END ASC, 
	 CASE WHEN @sortColumn = 'TemporaryCCNumber' AND @sortOrder = 'DESC'
	 THEN T.TemporaryCCNumber END DESC ,

	 CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'ASC'
	 THEN T.CCIssueDate END ASC, 
	 CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'DESC'
	 THEN T.CCIssueDate END DESC ,

	 CASE WHEN @sortColumn = 'CCIssueBy' AND @sortOrder = 'ASC'
	 THEN T.CCIssueBy END ASC, 
	 CASE WHEN @sortColumn = 'CCIssueBy' AND @sortOrder = 'DESC'
	 THEN T.CCIssueBy END DESC ,

	 CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'ASC'
	 THEN T.CCApprove END ASC, 
	 CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'DESC'
	 THEN T.CCApprove END DESC ,

	 CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'ASC'
	 THEN T.CCCharge END ASC, 
	 CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'DESC'
	 THEN T.CCCharge END DESC ,

	 CASE WHEN @sortColumn = 'POID' AND @sortOrder = 'ASC'
	 THEN T.POID END ASC, 
	 CASE WHEN @sortColumn = 'POID' AND @sortOrder = 'DESC'
	 THEN T.POID END DESC ,

	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'
	 THEN T.PONumber END ASC, 
	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'
	 THEN T.PONumber END DESC ,

	 CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'ASC'
	 THEN T.POAmount END ASC, 
	 CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'DESC'
	 THEN T.POAmount END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceID' AND @sortOrder = 'ASC'
	 THEN T.InvoiceID END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceID' AND @sortOrder = 'DESC'
	 THEN T.InvoiceID END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN T.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN T.InvoiceNumber END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'
	 THEN T.InvoiceAmount END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'
	 THEN T.InvoiceAmount END DESC ,
	 
	 CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'ASC'
	 THEN T.CreditCardIssueNumber END ASC, 
	 CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'DESC'
	 THEN T.CreditCardIssueNumber END DESC 


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
DROP TABLE #tmpFinalResults
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
 WHERE id = object_id(N'[dbo].[dms_Temporary_CC_Card_Details_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Temporary_CC_Card_Details_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_Temporary_CC_Card_Details_Get 1
 CREATE PROCEDURE [dbo].[dms_Temporary_CC_Card_Details_Get] ( 
   @TempCCID Int = null 
 ) 
 AS 
 BEGIN 
  
SET NOCOUNT ON

SELECT	TCC.ID
		, TCC.CreditCardNumber AS TempCC
		, TCC.TotalChargedAmount AS CCCharge
		, TCC.IssueStatus AS IssueStatus
		, TCCS.Name AS MatchStatus
		, TCC.ExceptionMessage AS ExceptionMessage
		, TCC.OriginalReferencePurchaseOrderNumber AS CCOrigPO
		, TCC.ReferencePurchaseOrderNumber AS CCRefPO
		, TCC.Note
		,ISNULL(TCC.IsExceptionOverride,0) AS IsExceptionOverride
FROM	TemporaryCreditCard TCC
LEFT JOIN	TemporaryCreditCardStatus TCCS ON TCCS.ID = TCC.TemporaryCreditCardStatusID
WHERE	TCC.ID = @TempCCID


END
GO

GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Temporary_CC_Split]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Temporary_CC_Split]
GO

CREATE PROCEDURE [dbo].[dms_Temporary_CC_Split] 
	@SourceTemporaryCreditCardID int,
	@SplitTo_PurchaseOrderNumber nvarchar(50)
AS
BEGIN
	
	DECLARE	@NewTemporaryCreditCardID int,
		@NewTemporaryCreditCard_TotalChargedAmount money
		
	SELECT @NewTemporaryCreditCard_TotalChargedAmount = PurchaseOrderAmount
	FROM PurchaseOrder
	WHERE PurchaseOrderNumber = @SplitTo_PurchaseOrderNumber

	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO [DMS].[dbo].[TemporaryCreditCard]
				   ([CreditCardIssueNumber]
				   ,[CreditCardNumber]
				   ,[PurchaseOrderID]
				   ,[VendorInvoiceID]
				   ,[IssueDate]
				   ,[IssueBy]
				   ,[IssueStatus]
				   ,[ReferencePurchaseOrderNumber]
				   ,[OriginalReferencePurchaseOrderNumber]
				   ,[ReferenceVendorNumber]
				   ,[ApprovedAmount]
				   ,[TotalChargedAmount]
				   ,[TemporaryCreditCardStatusID]
				   ,[ExceptionMessage]
				   ,[Note]
				   ,[PostingBatchID]
				   ,[AccountingPeriodID]
				   ,[CreateDate]
				   ,[CreateBy]
				   ,[ModifyDate]
				   ,[ModifyBy])
		SELECT [CreditCardIssueNumber]
			  ,[CreditCardNumber]
			  ,[PurchaseOrderID]
			  ,[VendorInvoiceID]
			  ,[IssueDate]
			  ,[IssueBy]
			  ,[IssueStatus]
			  ,@SplitTo_PurchaseOrderNumber
			  ,[OriginalReferencePurchaseOrderNumber]
			  ,[ReferenceVendorNumber]
			  ,[ApprovedAmount]
			  ,@NewTemporaryCreditCard_TotalChargedAmount
			  ,[TemporaryCreditCardStatusID]
			  ,[ExceptionMessage]
			  ,[Note]
			  ,[PostingBatchID]
			  ,[AccountingPeriodID]
			  ,[CreateDate]
			  ,[CreateBy]
			  ,[ModifyDate]
			  ,[ModifyBy]
		FROM [DMS].[dbo].[TemporaryCreditCard]
		WHERE ID = @SourceTemporaryCreditCardID

		SET @NewTemporaryCreditCardID = SCOPE_IDENTITY()

		INSERT INTO [DMS].[dbo].[TemporaryCreditCardDetail]
				   ([TemporaryCreditCardID]
				   ,[TransactionSequence]
				   ,[TransactionDate]
				   ,[TransactionType]
				   ,[TransactionBy]
				   ,[RequestedAmount]
				   ,[ApprovedAmount]
				   ,[AvailableBalance]
				   ,[ChargeDate]
				   ,[ChargeAmount]
				   ,[ChargeDescription]
				   ,[CreateDate]
				   ,[CreateBy]
				   ,[ModifyDate]
				   ,[ModifyBy])
		SELECT @NewTemporaryCreditCardID
			  ,[TransactionSequence]
			  ,[TransactionDate]
			  ,[TransactionType]
			  ,[TransactionBy]
			  ,[RequestedAmount]
			  ,[ApprovedAmount]
			  ,[AvailableBalance]
			  ,[ChargeDate]
			  ,[ChargeAmount]
			  ,[ChargeDescription]
			  ,[CreateDate]
			  ,[CreateBy]
			  ,[ModifyDate]
			  ,[ModifyBy]
		FROM [DMS].[dbo].[TemporaryCreditCardDetail]
		WHERE TemporaryCreditCardID = @SourceTemporaryCreditCardID

		UPDATE TemporaryCreditCard SET TotalChargedAmount = (TotalChargedAmount - @NewTemporaryCreditCard_TotalChargedAmount)
		WHERE ID = @SourceTemporaryCreditCardID
		
		COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
	END CATCH
	
END

GO

GO

/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Users_List_For_Role_Get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Users_List_For_Role_Get]
GO
/****** Object:  StoredProcedure [dbo].[dms_Users_List_For_Role_Get]    Script Date: 07/03/2012 17:56:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC  [dbo].[dms_Users_List_For_Role_Get] '663F08B5-16BC-4552-A8B0-1FF5D436B045'

 CREATE PROCEDURE [dbo].[dms_Users_List_For_Role_Get](
 @roleID UNIQUEIDENTIFIER = NULL
 )
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

SELECT DISTINCT  u.* 
FROM [User] u
JOIN aspnet_UsersInRoles uir ON uir.UserID = u.aspnet_UserID
JOIN aspnet_Roles r ON r.RoleID = uir.RoleID
JOIN aspnet_Membership m ON u.aspnet_UserID = m.UserId
WHERE
	--r.RoleName IN ('Agent','RVTech','Manager','Dispatcher','FrontEnd')
	r.RoleId = @roleID
AND m.IsApproved = 1
ORDER BY  u.FirstName


END



GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Users_Or_Roles_For_Notification_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Users_Or_Roles_For_Notification_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dms_Users_Or_Roles_For_Notification_Get] 2
 CREATE PROCEDURE [dbo].[dms_Users_Or_Roles_For_Notification_Get](
 @recipientTypeID INT = NULL
 )
 AS
 BEGIN
 DECLARE @ApplicationID UNIQUEIDENTIFIER
 SET @ApplicationID = (SELECT ApplicationId FROM aspnet_Applications where ApplicationName='DMS')
 
	 IF ( @recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'User') )
	 BEGIN
	 
		;WITH wUsers
		AS
		(
			SELECT	U.UserId AS ID,
					U.UserName AS Name,
					[dbo].[fnIsUserConnected](U.UserName) AS IsConnected
			FROM aspnet_Users U WITH (NOLOCK)
			WHERE U.ApplicationId = @ApplicationID		
		)
		
		SELECT	W.ID,
				W.Name
		FROM	wUsers W 
		WHERE	W.IsConnected = 1
	 
	 END
	 ELSE IF (@recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'Role') )
	 BEGIN
		
		SELECT	R.RoleId AS ID,
				R.RoleName AS Name		
		FROM	aspnet_Roles R WITH (NOLOCK)
		WHERE	R.ApplicationId = @ApplicationID
		 
	 END
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
 WHERE id = object_id(N'[dbo].[dms_Vendor_CCProcessing_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_CCProcessing_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_Vendor_CCProcessing_List_Get] @whereClauseXML = '<ROW><Filter IDType="Vendor" IDValue="TX100532" NameValue="" NameOperator="" InvoiceStatuses="" POStatuses="" FromDate="" ToDate="" ExportType="" ToBePaidFromDate="" ToBePaidToDate=""/></ROW>'  
CREATE PROCEDURE [dbo].[dms_Vendor_CCProcessing_List_Get](     
   @whereClauseXML XML = NULL     
 , @startInd Int = 1     
 , @endInd BIGINT = 5000     
 , @pageSize int = 10000      
 , @sortColumn nvarchar(100)  = ''     
 , @sortOrder nvarchar(100) = 'ASC'     
      
 )     
 AS     
 BEGIN     
 
 SET FMTONLY OFF    
  SET NOCOUNT ON    
    
IF @whereClauseXML IS NULL     
BEGIN    
 SET @whereClauseXML = '<ROW><Filter     
NameOperator="-1"    
 ></Filter></ROW>'    
END    
    
    
CREATE TABLE #tmpForWhereClause    
(    
 IDType NVARCHAR(50) NULL,    
 IDValue NVARCHAR(100) NULL,    
 CCMatchStatuses NVARCHAR(MAX) NULL,    
 POPayStatuses NVARCHAR(MAX) NULL,    
 CCFromDate DATETIME NULL,    
 CCToDate DATETIME NULL,    
 POFromDate DATETIME NULL,    
 POToDate DATETIME NULL,
 PostingBatchID INT NULL,
 ChargedDateFrom DATETIME NULL,
 ChargedDateTo   DATETIME NULL,
 ChargedAmountFrom NUMERIC(18,2) NULL,
 ChargedAmountTo NUMERIC(18,2) NULL, 
 ExceptionType NVARCHAR(MAX) NULL
)    
    
 CREATE TABLE #FinalResults_Filtered(      
 ID int  NULL ,    
 CCRefPO nvarchar(50)  NULL ,    
 TempCC nvarchar(50) NULL,    
 CCIssueDate datetime  NULL ,    
 CCApprove money  NULL ,    
 CCCharge money  NULL ,    
 CCIssueStatus nvarchar(50)  NULL ,    
 CCMatchStatus nvarchar(50)  NULL ,    
 CCOrigPO nvarchar(50)  NULL ,    
 PONumber nvarchar(50)  NULL ,    
 PODate datetime  NULL ,    
 POPayStatus nvarchar(50)  NULL ,    
 POCC nvarchar(50)  NULL ,    
 POAmount money  NULL ,    
 InvoiceAmount money  NULL ,    
 Note nvarchar(1000)  NULL ,    
 ExceptionMessage nvarchar(200)  NULL ,    
 POId int  NULL  ,
 CreditCardIssueNumber nvarchar(50) NULL,
 PurchaseOrderStatus nvarchar(50)  NULL,
 ReferenceVendorNumber nvarchar(50) NULL,
 VendorNumber nvarchar(50) NULL,
 LastChargedDate DATETIME NULL
)     
    
 CREATE TABLE #FinalResults_Sorted (     
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
 ID int  NULL ,    
 CCRefPO nvarchar(50)  NULL ,    
 TempCC nvarchar(50) NULL,    
 CCIssueDate datetime  NULL ,    
 CCApprove money  NULL ,    
 CCCharge money  NULL ,    
 CCIssueStatus nvarchar(50)  NULL ,    
 CCMatchStatus nvarchar(50)  NULL ,    
 CCOrigPO nvarchar(50)  NULL ,    
 PONumber nvarchar(50)  NULL ,    
 PODate datetime  NULL ,    
 POPayStatus nvarchar(50)  NULL ,    
 POCC nvarchar(50)  NULL ,    
 POAmount money  NULL ,    
 InvoiceAmount money  NULL ,    
 Note nvarchar(1000)  NULL ,    
 ExceptionMessage nvarchar(200)  NULL ,    
 POId int  NULL   ,
 CreditCardIssueNumber nvarchar(50) NULL,
 PurchaseOrderStatus nvarchar(50)  NULL,
 ReferenceVendorNumber nvarchar(50) NULL,
 VendorNumber nvarchar(50) NULL,
 LastChargedDate DATETIME NULL
)     

DECLARE @matchedCount BIGINT      
DECLARE @exceptionCount BIGINT      
DECLARE @postedCount BIGINT    
DECLARE @cancelledCount BIGINT 
DECLARE @unmatchedCount BIGINT 
 
SET @matchedCount = 0      
SET @exceptionCount = 0      
SET @postedCount = 0
SET @cancelledCount = 0
SET @unmatchedCount = 0    
  
  
INSERT INTO #tmpForWhereClause    
SELECT      
 T.c.value('@IDType','NVARCHAR(50)') ,    
 T.c.value('@IDValue','NVARCHAR(100)'),     
 T.c.value('@CCMatchStatuses','nvarchar(MAX)') ,    
 T.c.value('@POPayStatuses','nvarchar(MAX)') , 
 T.c.value('@CCFromDate','datetime') ,    
 T.c.value('@CCToDate','datetime') ,    
 T.c.value('@POFromDate','datetime') ,
 T.c.value('@POToDate','datetime') ,    
 T.c.value('@PostingBatchID','INT'),
 T.c.value('@ChargedDateFrom','datetime') ,  
 T.c.value('@ChargedDateTo','datetime') ,  
 T.c.value('@ChargedAmountFrom','NUMERIC(18,2)') ,  
 T.c.value('@ChargedAmountTo','NUMERIC(18,2)') ,  
 T.c.value('@ExceptionType','NVARCHAR(MAX)')  
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)    
    
    
DECLARE @idType NVARCHAR(50) = NULL,    
  @idValue NVARCHAR(100) = NULL,    
  @CCMatchStatuses NVARCHAR(MAX) = NULL,    
  @POPayStatuses NVARCHAR(MAX) = NULL,    
  @CCFromDate DATETIME = NULL,    
  @CCToDate DATETIME = NULL, 
  @POFromDate DATETIME = NULL,    
  @POToDate DATETIME = NULL,
  @PostingBatchID INT = NULL,
  @ChargedDateFrom DATETIME = NULL,    
  @ChargedDateTo DATETIME = NULL,  
  @ChargedAmountFrom NUMERIC(18,2),  
  @ChargedAmountTo NUMERIC(18,2),
  @ExceptionType NVARCHAR(MAX) = NULL

  DECLARE @ExTypeList AS TABLE([ExceptionMessage] NVARCHAR(MAX) NULL)
      
SELECT @idType = IDType,    
  @idValue = IDValue,    
  @CCMatchStatuses = CCMatchStatuses,    
  @POPayStatuses = POPayStatuses,    
  @CCFromDate = CCFromDate,    
  @CCToDate = CASE WHEN CCToDate = '1900-01-01' THEN NULL ELSE CCToDate END,  
  @POFromDate = POFromDate,
  @POToDate = CASE WHEN POToDate = '1900-01-01' THEN NULL ELSE POToDate END,  
  @PostingBatchID = PostingBatchID,
  @ChargedDateFrom = ChargedDateFrom,
  @ChargedDateTo = CASE WHEN ChargedDateTo = '1900-01-01' THEN NULL ELSE ChargedDateTo END,   
  @ChargedAmountFrom = ChargedAmountFrom,
  @ChargedAmountTo = ChargedAmountTo,
  @ExceptionType = ExceptionType

FROM #tmpForWhereClause    

INSERT INTO @ExTypeList([ExceptionMessage]) SELECT item FROM dbo.fnSplitString(@ExceptionType,',')

INSERT INTO #FinalResults_Filtered 
SELECT	TCC.ID,
		TCC.ReferencePurchaseOrderNumber
		, TCC.CreditCardNumber
		, TCC.IssueDate
		, TCC.ApprovedAmount
		, TCC.TotalChargedAmount
		, TCC.IssueStatus
		, TCCS.Name AS CCMatchStatus
		, TCC.OriginalReferencePurchaseOrderNumber
		, PO.PurchaseOrderNumber
		, PO.IssueDate
		, PSC.Name
		, PO.CompanyCreditCardNumber
		, PO.PurchaseOrderAmount
		, CASE
			WHEN TCCS.Name = 'Posted'  THEN ''--TCC.InvoiceAmount
			WHEN TCCS.Name = 'Matched' THEN TCC.TotalChargedAmount
			ELSE ''
		  END AS InvoiceAmount
		, TCC.Note
		,TCC.ExceptionMessage
		,PO.ID
		,TCC.CreditCardIssueNumber
		,POS.Name 
		,TCC.ReferenceVendorNumber
		,V.VendorNumber
		,TCC.LastChargedDate 
FROM	TemporaryCreditCard TCC WITH(NOLOCK)
LEFT JOIN	TemporaryCreditCardStatus TCCS ON TCCS.ID = TCC.TemporaryCreditCardStatusID
LEFT JOIN	PurchaseOrder PO ON PO.PurchaseOrderNumber = TCC.ReferencePurchaseOrderNumber
LEFT JOIN	VendorLocation VL ON VL.ID = PO.VendorLocationID
LEFT JOIN   Vendor V ON V.ID = VL.VendorID
LEFT JOIN   PurchaseOrderStatus POS ON POS.ID = PO.PurchaseOrderStatusID
LEFT JOIN	PurchaseOrderPayStatusCode PSC ON PSC.ID = PO.PayStatusCodeID
WHERE
 ( ISNULL(@idType,'') = ''    
   OR    
   (@idType = 'CCMatchPO' AND TCC.ReferencePurchaseOrderNumber = @idValue )    
   OR    
   (@idType = 'Last5ofTempCC' AND RIGHT(TCC.CreditCardNumber,5) = @idValue )    
    
  )    
 AND  (    
   ( ISNULL(@CCMatchStatuses,'') = '')    
   OR    
   ( TCC.TemporaryCreditCardStatusID IN (    
           SELECT item FROM fnSplitString(@CCMatchStatuses,',')    
   ))    
  )    
  AND  (    
   ( ISNULL(@POPayStatuses,'') = '')    
   OR    
   ( PO.PayStatusCodeID IN (    
           SELECT item FROM fnSplitString(@POPayStatuses,',')    
   ))    
  )     
  AND  (    
       
   ( @CCFromDate IS NULL OR (@CCFromDate IS NOT NULL AND TCC.IssueDate >= @CCFromDate))    
    AND    
   ( @CCToDate IS NULL OR (@CCToDate IS NOT NULL AND TCC.IssueDate < DATEADD(DD,1,@CCToDate)))    
  )
  AND  (    
       
   ( @ChargedDateFrom IS NULL OR (@ChargedDateFrom IS NOT NULL AND TCC.LastChargedDate >= @ChargedDateFrom))    
    AND    
   ( @ChargedDateTo IS NULL OR (@ChargedDateTo IS NOT NULL AND TCC.LastChargedDate < DATEADD(DD,1,@ChargedDateTo)))    
  )
  AND  (    
       
   ( @ChargedAmountFrom IS NULL OR (@ChargedAmountFrom IS NOT NULL AND TCC.TotalChargedAmount >= @ChargedAmountFrom))    
    AND    
   ( @ChargedAmountTo IS NULL OR (@ChargedAmountTo IS NOT NULL AND TCC.TotalChargedAmount <= @ChargedAmountTo))    
  )
  AND  (    
       
   ( @POFromDate IS NULL OR (@POFromDate IS NOT NULL AND PO.IssueDate >= @POFromDate))    
    AND    
   ( @POToDate IS NULL OR (@POToDate IS NOT NULL AND PO.IssueDate < DATEADD(DD,1,@POToDate)))    
  )
  AND ( ISNULL(@PostingBatchID,0) = 0 OR TCC.PostingBatchID = @PostingBatchID )
 
  AND ((@ExceptionType IS NULL) OR (@ExceptionType IS NOT NULL AND TCC.ExceptionMessage IN (SELECT ExceptionMessage  FROM @ExTypeList)))
  
INSERT INTO #FinalResults_Sorted    
SELECT     
 T.ID,    
 T.CCRefPO,    
 T.TempCC,    
 T.CCIssueDate,    
 T.CCApprove,    
 T.CCCharge,    
 T.CCIssueStatus,    
 T.CCMatchStatus,    
 T.CCOrigPO,    
 T.PONumber,    
 T.PODate,    
 T.POPayStatus,    
 T.POCC,    
 T.POAmount,    
 T.InvoiceAmount,    
 T.Note,    
 T.ExceptionMessage,    
 T.POId,
 T.CreditCardIssueNumber,
 T.PurchaseOrderStatus,
 T.ReferenceVendorNumber,
 T.VendorNumber,
 T.LastChargedDate
FROM #FinalResults_Filtered T    


 ORDER BY     
  CASE WHEN @sortColumn = 'CCRefPO' AND @sortOrder = 'ASC'    
  THEN T.CCRefPO END ASC,     
  CASE WHEN @sortColumn = 'CCRefPO' AND @sortOrder = 'DESC'    
  THEN T.ID END DESC ,    
    
  CASE WHEN @sortColumn = 'TempCC' AND @sortOrder = 'ASC'    
  THEN T.TempCC END ASC,     
  CASE WHEN @sortColumn = 'TempCC' AND @sortOrder = 'DESC'    
  THEN T.TempCC END DESC ,    
     
 CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'ASC'    
  THEN T.CCIssueDate END ASC,     
  CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'DESC'    
  THEN T.CCIssueDate END DESC ,    
    
  CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'ASC'    
  THEN T.CCApprove END ASC,     
  CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'DESC'    
  THEN T.CCApprove END DESC ,    
    
  CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'ASC'    
  THEN T.CCCharge END ASC,     
  CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'DESC'    
  THEN T.CCCharge END DESC ,    
    
  CASE WHEN @sortColumn = 'CCIssueStatus' AND @sortOrder = 'ASC'    
  THEN T.CCIssueStatus END ASC,     
  CASE WHEN @sortColumn = 'CCIssueStatus' AND @sortOrder = 'DESC'    
  THEN T.CCIssueStatus END DESC ,    
    
  CASE WHEN @sortColumn = 'CCMatchStatus' AND @sortOrder = 'ASC'    
  THEN T.CCMatchStatus END ASC,     
  CASE WHEN @sortColumn = 'CCMatchStatus' AND @sortOrder = 'DESC'    
  THEN T.CCMatchStatus END DESC ,    
    
  CASE WHEN @sortColumn = 'CCOrigPO' AND @sortOrder = 'ASC'    
  THEN T.CCOrigPO END ASC,     
  CASE WHEN @sortColumn = 'CCOrigPO' AND @sortOrder = 'DESC'    
  THEN T.CCOrigPO END DESC ,    
    
  CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'    
  THEN T.PONumber END ASC,     
  CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'    
  THEN T.PONumber END DESC ,    
    
  CASE WHEN @sortColumn = 'PODate' AND @sortOrder = 'ASC'    
  THEN T.PODate END ASC,     
  CASE WHEN @sortColumn = 'PODate' AND @sortOrder = 'DESC'    
  THEN T.PODate END DESC ,    
    
  CASE WHEN @sortColumn = 'POPayStatus' AND @sortOrder = 'ASC'    
  THEN T.POPayStatus END ASC,     
  CASE WHEN @sortColumn = 'POPayStatus' AND @sortOrder = 'DESC'    
  THEN T.POPayStatus END DESC ,    
    
  CASE WHEN @sortColumn = 'POCC' AND @sortOrder = 'ASC'    
  THEN T.POCC END ASC,     
  CASE WHEN @sortColumn = 'POCC' AND @sortOrder = 'DESC'    
  THEN T.POCC END DESC ,    
    
  CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'ASC'    
  THEN T.POAmount END ASC,     
  CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'DESC'    
  THEN T.POAmount END DESC ,    
    
  CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'    
  THEN T.InvoiceAmount END ASC,     
  CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'    
  THEN T.InvoiceAmount END DESC ,    
    
  CASE WHEN @sortColumn = 'Note' AND @sortOrder = 'ASC'    
  THEN T.Note END ASC,     
  CASE WHEN @sortColumn = 'Note' AND @sortOrder = 'DESC'    
  THEN T.Note END DESC    ,    
    
  CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'ASC'    
  THEN T.CreditCardIssueNumber END ASC,     
  CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'DESC'    
  THEN T.CreditCardIssueNumber END DESC,
  
  CASE WHEN @sortColumn = 'PurchaseOrderStatus' AND @sortOrder = 'ASC'    
  THEN T.PurchaseOrderStatus END ASC,     
  CASE WHEN @sortColumn = 'PurchaseOrderStatus' AND @sortOrder = 'DESC'    
  THEN T.PurchaseOrderStatus END DESC,
  
  CASE WHEN @sortColumn = 'ReferenceVendorNumber' AND @sortOrder = 'ASC'    
  THEN T.ReferenceVendorNumber END ASC,     
  CASE WHEN @sortColumn = 'ReferenceVendorNumber' AND @sortOrder = 'DESC'    
  THEN T.ReferenceVendorNumber END DESC,
  
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'    
  THEN T.VendorNumber END ASC,     
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'    
  THEN T.VendorNumber END DESC,

  CASE WHEN @sortColumn = 'LastChargedDate' AND @sortOrder = 'ASC'    
  THEN T.LastChargedDate END ASC,     
  CASE WHEN @sortColumn = 'LastChargedDate' AND @sortOrder = 'DESC'    
  THEN T.LastChargedDate END DESC
  
 --CreditCardIssueNumber
    
SELECT @matchedCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus = 'Matched'      
SELECT @exceptionCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus = 'Exception'      
SELECT @cancelledCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus= 'Cancelled'    
SELECT @postedCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus= 'Posted' 
SELECT @unmatchedCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus= 'Unmatched'    
   
    
DECLARE @count INT       
SET @count = 0       
SELECT @count = MAX(RowNum) FROM #FinalResults_Sorted    
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
    
SELECT   
   @count AS TotalRows  
 , *  
 , @matchedCount AS MatchedCount   
 , @exceptionCount AS ExceptionCount  
 , @postedCount AS PostedCount  
 , @cancelledCount AS CancellledCount
 , @unmatchedCount AS UnMatchedCount
 
FROM #FinalResults_Sorted WHERE RowNum BETWEEN @startInd AND @endInd    
    
DROP TABLE #tmpForWhereClause    
DROP TABLE #FinalResults_Filtered    
DROP TABLE #FinalResults_Sorted  

    
END

GO

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

GO
  
  IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Info_Search]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Info_Search] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

  --EXEC dms_Vendor_Info_Search @DispatchPhoneNumber = '1 4695213697',@OfficePhoneNumber = '1 9254494909'  
 CREATE PROCEDURE [dbo].[dms_Vendor_Info_Search](   
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10    
 , @sortColumn nvarchar(100)  = ''   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @DispatchPhoneNumber nvarchar(50)=NULL 
 , @OfficePhoneNumber nvarchar(50)=NULL
 , @VendorSearchName nvarchar(50)=NULL  
-- , @FaxPhoneNumber nvarchar(50)  
  
--SET @DispatchPhoneNumber = '1 2146834715';  
--SET @OfficePhoneNumber = '1 5868722949'  
  
) AS   
 BEGIN   
    
  SET NOCOUNT ON  
  
DECLARE @idoc int  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter   
VendorIDOperator="-1"   
VendorLocationIDOperator="-1"   
SequenceOperator="-1"   
VendorNumberOperator="-1"   
VendorNameOperator="-1"   
VendorStatusOperator="-1"   
ContractStatusOperator="-1"   
Address1Operator="-1"   
VendorCityOperator="-1"   
DispatchPhoneTypeOperator="-1"   
DispatchPhoneNumberOperator="-1"   
OfficePhoneTypeOperator="-1"   
 ></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
VendorIDOperator INT NOT NULL,  
VendorIDValue int NULL,  
VendorLocationIDOperator INT NOT NULL,  
VendorLocationIDValue int NULL,  
SequenceOperator INT NOT NULL,  
SequenceValue int NULL,  
VendorNumberOperator INT NOT NULL,  
VendorNumberValue nvarchar(50) NULL,  
VendorNameOperator INT NOT NULL,  
VendorNameValue nvarchar(50) NULL,  
VendorStatusOperator INT NOT NULL,  
VendorStatusValue nvarchar(50) NULL,  
ContractStatusOperator INT NOT NULL,  
ContractStatusValue nvarchar(50) NULL,  
Address1Operator INT NOT NULL,  
Address1Value nvarchar(50) NULL,  
VendorCityOperator INT NOT NULL,  
VendorCityValue nvarchar(50) NULL,  
DispatchPhoneTypeOperator INT NOT NULL,  
DispatchPhoneTypeValue int NULL,  
DispatchPhoneNumberOperator INT NOT NULL,  
DispatchPhoneNumberValue nvarchar(50) NULL,  
OfficePhoneTypeOperator INT NOT NULL,  
OfficePhoneTypeValue int NULL  
)  
DECLARE @FinalResults TABLE (   
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 VendorID int  NULL ,  
 VendorLocationID int  NULL ,  
 Sequence int  NULL ,  
 VendorNumber nvarchar(50)  NULL ,  
 VendorName nvarchar(255)  NULL ,  
 VendorStatus nvarchar(50)  NULL ,  
 ContractStatus nvarchar(50)  NULL ,  
 Address1 nvarchar(255)  NULL ,  
 VendorCity nvarchar(255)  NULL ,  
 DispatchPhoneType int  NULL ,  
 DispatchPhoneNumber nvarchar(50)  NULL ,  
 OfficePhoneType int  NULL ,  
 OfficePhoneNumber nvarchar(50)  NULL   
)   
DECLARE @FinalResults1 TABLE (   
 --[RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 VendorID int  NULL ,  
 VendorLocationID int  NULL ,  
 Sequence int  NULL ,  
 VendorNumber nvarchar(50)  NULL ,  
 VendorName nvarchar(255)  NULL ,  
 VendorStatus nvarchar(50)  NULL ,  
 ContractStatus nvarchar(50)  NULL ,  
 Address1 nvarchar(255)  NULL ,  
 VendorCity nvarchar(255)  NULL ,  
 DispatchPhoneType int  NULL ,  
 DispatchPhoneNumber nvarchar(50)  NULL ,  
 OfficePhoneType int  NULL ,  
 OfficePhoneNumber nvarchar(50)  NULL   
)   
  
INSERT INTO @tmpForWhereClause  
SELECT    
 ISNULL(VendorIDOperator,-1),  
 VendorIDValue ,  
 ISNULL(VendorLocationIDOperator,-1),  
 VendorLocationIDValue ,  
 ISNULL(SequenceOperator,-1),  
 SequenceValue ,  
 ISNULL(VendorNumberOperator,-1),  
 VendorNumberValue ,  
 ISNULL(VendorNameOperator,-1),  
 VendorNameValue ,  
 ISNULL(VendorStatusOperator,-1),  
 VendorStatusValue ,  
 ISNULL(ContractStatusOperator,-1),  
 ContractStatusValue ,  
 ISNULL(Address1Operator,-1),  
 Address1Value ,  
 ISNULL(VendorCityOperator,-1),  
 VendorCityValue ,  
 ISNULL(DispatchPhoneTypeOperator,-1),  
 DispatchPhoneTypeValue ,  
 ISNULL(DispatchPhoneNumberOperator,-1),  
 DispatchPhoneNumberValue ,  
 ISNULL(OfficePhoneTypeOperator,-1),  
 OfficePhoneTypeValue   
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
VendorIDOperator INT,  
VendorIDValue int   
,VendorLocationIDOperator INT,  
VendorLocationIDValue int   
,SequenceOperator INT,  
SequenceValue int   
,VendorNumberOperator INT,  
VendorNumberValue nvarchar(50)   
,VendorNameOperator INT,  
VendorNameValue nvarchar(50)   
,VendorStatusOperator INT,  
VendorStatusValue nvarchar(50)   
,ContractStatusOperator INT,  
ContractStatusValue nvarchar(50)   
,Address1Operator INT,  
Address1Value nvarchar(50)   
,VendorCityOperator INT,  
VendorCityValue nvarchar(50)   
,DispatchPhoneTypeOperator INT,  
DispatchPhoneTypeValue int   
,DispatchPhoneNumberOperator INT,  
DispatchPhoneNumberValue nvarchar(50)   
,OfficePhoneTypeOperator INT,  
OfficePhoneTypeValue int   
 )   

DECLARE @VendorLocationEntityID int,
	@VendorEntityID int,
	@DispatchPhoneTypeID int,
	@OfficePhoneTypeID int
SET @VendorLocationEntityID = (Select ID From Entity Where Name = 'VendorLocation')
SET @VendorEntityID = (Select ID From Entity Where Name = 'Vendor')
SET @DispatchPhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')  
SET @OfficePhoneTypeID = (Select ID From PhoneType Where Name = 'Office')  

--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
  
INSERT INTO @FinalResults1  
  
SELECT   
  v.ID  
 ,vl.ID   
 ,vl.Sequence  
 ,v.VendorNumber   
 ,v.Name
 ,vs.Name AS VendorStatus
 ,CASE
  WHEN ContractedVendors.ContractID IS NOT NULL 
		AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'
   ELSE 'Not Contracted' 
   END
 ,ae.Line1 as Address1  
 --,ae.Line2 as Address2  
 ,REPLACE(RTRIM(  
   COALESCE(ae.City, '') +  
   COALESCE(', ' + ae.StateProvince,'') +   
   COALESCE(LTRIM(ae.PostalCode), '') +   
   COALESCE(' ' + ae.CountryCode, '')   
   ), ' ', ' ')   
 , pe24.PhoneTypeID   
 , pe24.PhoneNumber   
 , peOfc.PhoneTypeID   
 , peOfc.PhoneNumber   
FROM VendorLocation vl  
INNER JOIN Vendor v on v.ID = vl.VendorID  
JOIN VendorStatus vs on v.VendorStatusID  = vs.ID
LEFT OUTER JOIN(
	  SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID
	  FROM dbo.fnGetContractedVendors() cv
	  ) ContractedVendors ON v.ID = ContractedVendors.VendorID
LEFT OUTER JOIN AddressEntity ae on ae.RecordID = vl.ID and ae.EntityID = @VendorLocationEntityID    
LEFT OUTER JOIN PhoneEntity pe24 on pe24.RecordID = vl.ID and pe24.EntityID = @VendorLocationEntityID and pe24.PhoneTypeID = @DispatchPhoneTypeID   
LEFT OUTER JOIN PhoneEntity peOfc on peOfc.RecordID = v.ID and peOfc.EntityID = @VendorEntityID and peOfc.PhoneTypeID = @OfficePhoneTypeID 
LEFT OUTER JOIN [Contract] c on c.VendorID = v.ID and c.IsActive = 1 AND c.ContractStatusID = (SELECT ID FROM ContractStatus WHERE Name = 'Active')
WHERE  
v.IsActive = 1 
--AND (v.VendorNumber IS NULL OR v.VendorNumber NOT LIKE '9X%' ) --KB: VendorNumber will be NULL for newly added vendors and these are getting excluded from the possible duplicates
AND
-- TP: Matching either phone number across both phone types is valid for this search; 
--     grouped OR condition -- A match on either phone number is valid
(ISNULL(pe24.PhoneNumber,'') IN (@DispatchPhoneNumber, @OfficePhoneNumber)
 OR
 ISNULL(peOfc.PhoneNumber,'') IN (@DispatchPhoneNumber, @OfficePhoneNumber)
)

--AND (@DispatchPhoneNumber IS NULL) OR (pe24.PhoneNumber = @DispatchPhoneNumber)  
--OR (@OfficePhoneNumber IS NULL) OR (peOfc.PhoneNumber = @OfficePhoneNumber)  
--AND (@VendorSearchName IS NULL) OR (v.NAme LIKE '%'+@VendorSearchName+'%')  

INSERT INTO @FinalResults  
SELECT   
 T.VendorID,  
 T.VendorLocationID,  
 T.Sequence,  
 T.VendorNumber,  
 T.VendorName,  
 T.VendorStatus,  
 T.ContractStatus,  
 T.Address1,  
 T.VendorCity,  
 T.DispatchPhoneType,  
 T.DispatchPhoneNumber,  
 T.OfficePhoneType,  
 T.OfficePhoneNumber  
FROM @FinalResults1 T,  
@tmpForWhereClause TMP   
WHERE (   
  
 (   
  ( TMP.VendorIDOperator = -1 )   
 OR   
  ( TMP.VendorIDOperator = 0 AND T.VendorID IS NULL )   
 OR   
  ( TMP.VendorIDOperator = 1 AND T.VendorID IS NOT NULL )   
 OR   
  ( TMP.VendorIDOperator = 2 AND T.VendorID = TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 3 AND T.VendorID <> TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 7 AND T.VendorID > TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 8 AND T.VendorID >= TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 9 AND T.VendorID < TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 10 AND T.VendorID <= TMP.VendorIDValue )   
  
 )   
  
 AND   
  
 (   
  ( TMP.VendorLocationIDOperator = -1 )   
 OR   
  ( TMP.VendorLocationIDOperator = 0 AND T.VendorLocationID IS NULL )   
 OR   
  ( TMP.VendorLocationIDOperator = 1 AND T.VendorLocationID IS NOT NULL )   
 OR   
  ( TMP.VendorLocationIDOperator = 2 AND T.VendorLocationID = TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 3 AND T.VendorLocationID <> TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 7 AND T.VendorLocationID > TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 8 AND T.VendorLocationID >= TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 9 AND T.VendorLocationID < TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 10 AND T.VendorLocationID <= TMP.VendorLocationIDValue )   
  
 )   
  
 AND   
  
 (   
  ( TMP.SequenceOperator = -1 )   
 OR   
  ( TMP.SequenceOperator = 0 AND T.Sequence IS NULL )   
 OR   
  ( TMP.SequenceOperator = 1 AND T.Sequence IS NOT NULL )   
 OR   
  ( TMP.SequenceOperator = 2 AND T.Sequence = TMP.SequenceValue )   
 OR   
  ( TMP.SequenceOperator = 3 AND T.Sequence <> TMP.SequenceValue )   
 OR   
  ( TMP.SequenceOperator = 7 AND T.Sequence > TMP.SequenceValue )   
 OR   
  ( TMP.SequenceOperator = 8 AND T.Sequence >= TMP.SequenceValue )   
 OR   
  ( TMP.SequenceOperator = 9 AND T.Sequence < TMP.SequenceValue )   
 OR   
  ( TMP.SequenceOperator = 10 AND T.Sequence <= TMP.SequenceValue )   
  
 )   
  
 AND   
  
 (   
  ( TMP.VendorNumberOperator = -1 )   
 OR   
  ( TMP.VendorNumberOperator = 0 AND T.VendorNumber IS NULL )   
 OR   
  ( TMP.VendorNumberOperator = 1 AND T.VendorNumber IS NOT NULL )   
 OR   
  ( TMP.VendorNumberOperator = 2 AND T.VendorNumber = TMP.VendorNumberValue )   
 OR   
  ( TMP.VendorNumberOperator = 3 AND T.VendorNumber <> TMP.VendorNumberValue )   
 OR   
  ( TMP.VendorNumberOperator = 4 AND T.VendorNumber LIKE TMP.VendorNumberValue + '%')   
 OR   
  ( TMP.VendorNumberOperator = 5 AND T.VendorNumber LIKE '%' + TMP.VendorNumberValue )   
 OR   
  ( TMP.VendorNumberOperator = 6 AND T.VendorNumber LIKE '%' + TMP.VendorNumberValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.VendorNameOperator = -1 )   
 OR   
  ( TMP.VendorNameOperator = 0 AND T.VendorName IS NULL )   
 OR   
  ( TMP.VendorNameOperator = 1 AND T.VendorName IS NOT NULL )   
 OR   
  ( TMP.VendorNameOperator = 2 AND T.VendorName = TMP.VendorNameValue )   
 OR   
  ( TMP.VendorNameOperator = 3 AND T.VendorName <> TMP.VendorNameValue )   
 OR   
  ( TMP.VendorNameOperator = 4 AND T.VendorName LIKE TMP.VendorNameValue + '%')   
 OR   
  ( TMP.VendorNameOperator = 5 AND T.VendorName LIKE '%' + TMP.VendorNameValue )   
 OR   
  ( TMP.VendorNameOperator = 6 AND T.VendorName LIKE '%' + TMP.VendorNameValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.VendorStatusOperator = -1 )   
 OR   
  ( TMP.VendorStatusOperator = 0 AND T.VendorStatus IS NULL )   
 OR   
  ( TMP.VendorStatusOperator = 1 AND T.VendorStatus IS NOT NULL )   
 OR   
  ( TMP.VendorStatusOperator = 2 AND T.VendorStatus = TMP.VendorStatusValue )   
 OR   
  ( TMP.VendorStatusOperator = 3 AND T.VendorStatus <> TMP.VendorStatusValue )   
 OR   
  ( TMP.VendorStatusOperator = 4 AND T.VendorStatus LIKE TMP.VendorStatusValue + '%')   
 OR   
  ( TMP.VendorStatusOperator = 5 AND T.VendorStatus LIKE '%' + TMP.VendorStatusValue )   
 OR   
  ( TMP.VendorStatusOperator = 6 AND T.VendorStatus LIKE '%' + TMP.VendorStatusValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.ContractStatusOperator = -1 )   
 OR   
  ( TMP.ContractStatusOperator = 0 AND T.ContractStatus IS NULL )   
 OR   
  ( TMP.ContractStatusOperator = 1 AND T.ContractStatus IS NOT NULL )   
 OR   
  ( TMP.ContractStatusOperator = 2 AND T.ContractStatus = TMP.ContractStatusValue )   
 OR   
  ( TMP.ContractStatusOperator = 3 AND T.ContractStatus <> TMP.ContractStatusValue )   
 OR   
  ( TMP.ContractStatusOperator = 4 AND T.ContractStatus LIKE TMP.ContractStatusValue + '%')   
 OR   
  ( TMP.ContractStatusOperator = 5 AND T.ContractStatus LIKE '%' + TMP.ContractStatusValue )   
 OR   
  ( TMP.ContractStatusOperator = 6 AND T.ContractStatus LIKE '%' + TMP.ContractStatusValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.Address1Operator = -1 )   
 OR   
  ( TMP.Address1Operator = 0 AND T.Address1 IS NULL )   
 OR   
  ( TMP.Address1Operator = 1 AND T.Address1 IS NOT NULL )   
 OR   
  ( TMP.Address1Operator = 2 AND T.Address1 = TMP.Address1Value )   
 OR   
  ( TMP.Address1Operator = 3 AND T.Address1 <> TMP.Address1Value )   
 OR   
  ( TMP.Address1Operator = 4 AND T.Address1 LIKE TMP.Address1Value + '%')   
 OR   
  ( TMP.Address1Operator = 5 AND T.Address1 LIKE '%' + TMP.Address1Value )   
 OR   
  ( TMP.Address1Operator = 6 AND T.Address1 LIKE '%' + TMP.Address1Value + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.VendorCityOperator = -1 )   
 OR   
  ( TMP.VendorCityOperator = 0 AND T.VendorCity IS NULL )   
 OR   
  ( TMP.VendorCityOperator = 1 AND T.VendorCity IS NOT NULL )   
 OR   
  ( TMP.VendorCityOperator = 2 AND T.VendorCity = TMP.VendorCityValue )   
 OR   
  ( TMP.VendorCityOperator = 3 AND T.VendorCity <> TMP.VendorCityValue )   
 OR   
  ( TMP.VendorCityOperator = 4 AND T.VendorCity LIKE TMP.VendorCityValue + '%')   
 OR   
  ( TMP.VendorCityOperator = 5 AND T.VendorCity LIKE '%' + TMP.VendorCityValue )   
 OR   
  ( TMP.VendorCityOperator = 6 AND T.VendorCity LIKE '%' + TMP.VendorCityValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.DispatchPhoneTypeOperator = -1 )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 0 AND T.DispatchPhoneType IS NULL )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 1 AND T.DispatchPhoneType IS NOT NULL )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 2 AND T.DispatchPhoneType = TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 3 AND T.DispatchPhoneType <> TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 7 AND T.DispatchPhoneType > TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 8 AND T.DispatchPhoneType >= TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 9 AND T.DispatchPhoneType < TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 10 AND T.DispatchPhoneType <= TMP.DispatchPhoneTypeValue )   
  
 )   
  
 AND   
  
 (   
  ( TMP.DispatchPhoneNumberOperator = -1 )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 0 AND T.DispatchPhoneNumber IS NULL )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 1 AND T.DispatchPhoneNumber IS NOT NULL )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 2 AND T.DispatchPhoneNumber = TMP.DispatchPhoneNumberValue )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 3 AND T.DispatchPhoneNumber <> TMP.DispatchPhoneNumberValue )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 4 AND T.DispatchPhoneNumber LIKE TMP.DispatchPhoneNumberValue + '%')   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 5 AND T.DispatchPhoneNumber LIKE '%' + TMP.DispatchPhoneNumberValue )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 6 AND T.DispatchPhoneNumber LIKE '%' + TMP.DispatchPhoneNumberValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.OfficePhoneTypeOperator = -1 )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 0 AND T.OfficePhoneType IS NULL )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 1 AND T.OfficePhoneType IS NOT NULL )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 2 AND T.OfficePhoneType = TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 3 AND T.OfficePhoneType <> TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 7 AND T.OfficePhoneType > TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 8 AND T.OfficePhoneType >= TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 9 AND T.OfficePhoneType < TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 10 AND T.OfficePhoneType <= TMP.OfficePhoneTypeValue )   
  
 )   
  
 AND   
 1 = 1   
 )   
 ORDER BY   
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'ASC'  
  THEN T.VendorID END ASC,   
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'DESC'  
  THEN T.VendorID END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorLocationID' AND @sortOrder = 'ASC'  
  THEN T.VendorLocationID END ASC,   
  CASE WHEN @sortColumn = 'VendorLocationID' AND @sortOrder = 'DESC'  
  THEN T.VendorLocationID END DESC ,  
  
  CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'  
  THEN T.Sequence END ASC,   
  CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'  
  THEN T.Sequence END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'  
  THEN T.VendorNumber END ASC,   
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'  
  THEN T.VendorNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'ASC'  
  THEN T.VendorName END ASC,   
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'DESC'  
  THEN T.VendorName END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'ASC'  
  THEN T.VendorStatus END ASC,   
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'DESC'  
  THEN T.VendorStatus END DESC ,  
  
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'ASC'  
  THEN T.ContractStatus END ASC,   
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'DESC'  
  THEN T.ContractStatus END DESC ,  
  
  CASE WHEN @sortColumn = 'Address1' AND @sortOrder = 'ASC'  
  THEN T.Address1 END ASC,   
  CASE WHEN @sortColumn = 'Address1' AND @sortOrder = 'DESC'  
  THEN T.Address1 END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorCity' AND @sortOrder = 'ASC'  
  THEN T.VendorCity END ASC,   
  CASE WHEN @sortColumn = 'VendorCity' AND @sortOrder = 'DESC'  
  THEN T.VendorCity END DESC ,  
  
  CASE WHEN @sortColumn = 'DispatchPhoneType' AND @sortOrder = 'ASC'  
  THEN T.DispatchPhoneType END ASC,   
  CASE WHEN @sortColumn = 'DispatchPhoneType' AND @sortOrder = 'DESC'  
  THEN T.DispatchPhoneType END DESC ,  
  
  CASE WHEN @sortColumn = 'DispatchPhoneNumber' AND @sortOrder = 'ASC'  
  THEN T.DispatchPhoneNumber END ASC,   
  CASE WHEN @sortColumn = 'DispatchPhoneNumber' AND @sortOrder = 'DESC'  
  THEN T.DispatchPhoneNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'OfficePhoneType' AND @sortOrder = 'ASC'  
  THEN T.OfficePhoneType END ASC,   
  CASE WHEN @sortColumn = 'OfficePhoneType' AND @sortOrder = 'DESC'  
  THEN T.OfficePhoneType END DESC ,  
  
  CASE WHEN @sortColumn = 'OfficePhoneNumber' AND @sortOrder = 'ASC'  
  THEN T.OfficePhoneNumber END ASC,   
  CASE WHEN @sortColumn = 'OfficePhoneNumber' AND @sortOrder = 'DESC'  
  THEN T.OfficePhoneNumber END DESC   
  
  
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

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_PO_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_PO_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_PO_Details_Get @PONumber=7770395
 CREATE PROCEDURE [dbo].[dms_Vendor_Invoice_PO_Details_Get]( 
	@PONumber nvarchar(50) =NULL
	)
AS
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 SET FMTONLY OFF  
  
SELECT  PO.ID  
   , CASE  
    WHEN ISNULL(PO.IsPayByCompanyCreditCard,'') = 1 THEN 'Paid with company credit card'  
    ELSE ''  
     END AS [AlertText]  
   , PO.PurchaseOrderNumber AS [PONumber]  
   , POS.Name AS [POStatus]  
   , PO.PurchaseOrderAmount AS [POAmount]  
   , PC.Name AS [Service]  
   , PO.IssueDate AS [IssueDate]  
   , PO.ETADate AS [ETADate]  
   , PO.VendorLocationID     
   --, CASE  
   --WHEN ISNULL(CRS.ID,'') = '' THEN 'Not Contracted'  
   --ELSE 'Contracted'  
   --END AS 'ContractStatus'  
   , CASE  
    WHEN ContractedVendors.ContractID IS NOT NULL AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'  
    ELSE 'Not Contracted'   
     END AS ContractStatus  
   , V.Name AS [VendorName]  
   , V.VendorNumber AS [VendorNumber]  
   , ISNULL(PO.BillingAddressLine1,'') AS [VendorLocationLine1]  
   , ISNULL(PO.BillingAddressLine2,'') AS [VendorLocationLine2]  
   , ISNULL(PO.BillingAddressLine3,'') AS [VendorLocationLine3]   
   , ISNULL(REPLACE(RTRIM(  
      COALESCE(PO.BillingAddressCity, '') +   
      COALESCE(', ' + RTRIM(PO.BillingAddressStateProvince), '') +       
      COALESCE(' ' + PO.BillingAddressPostalCode, '') +            
      COALESCE(' ' + PO.BillingAddressCountryCode, '')   
     ), '  ', ' ')  
     ,'') AS [VendorLocationCityStZip]  
   , PO.DispatchPhoneNumber AS [DispatchPhoneNumber]  
   , PO.FaxPhoneNumber AS [FaxPhoneNumber]  
   , 'TalkedTo' AS [TalkedTo] -- TODO: Linked to ContactLog and get Talked To  
   , CL.Name AS [Client]  
   , P.Name AS [Program]  
   , MS.MembershipNumber AS [MemberNumber]  
   , C.MemberStatus  
   , REPLACE(RTRIM(  
    COALESCE(CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+  
    COALESCE(' ' + LEFT(M.MiddleName,1),'')+  
    COALESCE(' ' + CASE WHEN M.LastName = '' THEN NULL ELSE M.LastName END,'')+    
    COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')  
    ),'','') AS [CustomerName]  
   , C.ContactPhoneNumber AS [CallbackNumber]   
   , C.ContactAltPhoneNumber AS [AlternateNumber]  
   --, PO.SubTotal AS [SubTotal]  calculated from PO Details GRID  
   , PO.TaxAmount AS [Tax]  
   , PO.TotalServiceAmount AS [ServiceTotal]  
   , PO.CoachNetServiceAmount AS [CoachNetPays]  
   , PO.MemberServiceAmount AS [MemberPays]  
   , VT.Name + ' - ' + VC.Name AS [VehicleType]  
   , REPLACE(RTRIM(  
    COALESCE(C.VehicleYear,'')+  
    COALESCE(' ' + CASE WHEN C.VehicleMake = 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END,'')+  
    COALESCE(' ' + CASE WHEN C.VehicleModel = 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END,'')  
    ), '','') AS [Vehicle]  
   , ISNULL(C.VehicleVIN,'') AS [VIN]  
   , ISNULL(C.VehicleColor,'') AS [Color]  
   , REPLACE(RTRIM(  
     COALESCE(C.VehicleLicenseState + ' - ','') +  
     COALESCE(C.VehicleLicenseNumber,'')   
    ),'','') AS [License]  
   , ISNULL(C.VehicleCurrentMileage,'') AS [Mileage]  
   , ISNULL(SR.ServiceLocationAddress,'') AS [Location]  
   , ISNULL(SR.ServiceLocationDescription,'') AS [LocationDescription]  
   , ISNULL(SR.DestinationAddress,'') AS [Destination]  
   , ISNULL(SR.DestinationDescription,'') AS [DestinationDescription]  
   , PO.CreateBy  
   , PO.CreateDate  
   , PO.ModifyBy  
   , PO.ModifyDate   
   , CT.Abbreviation AS [CurrencyType]   
   , PO.IsPayByCompanyCreditCard AS IsPayByCC  
   , PO.CompanyCreditCardNumber CompanyCC  
   ,PO.VendorTaxID  
   ,PO.Email  
   ,POPS.[Description] PurchaseOrderPayStatus  
FROM  PurchaseOrder PO   
JOIN  PurchaseOrderStatus POS WITH (NOLOCK)ON POS.ID = PO.PurchaseOrderStatusID  
LEFT JOIN PurchaseOrderPayStatusCode POPS WITH (NOLOCK) ON POPS.ID = PO.PayStatusCodeID  
JOIN  ServiceRequest SR WITH (NOLOCK) ON SR.ID = PO.ServiceRequestID  
LEFT JOIN ServiceRequestStatus SRS WITH (NOLOCK) ON SRS.ID = SR.ServiceRequestStatusID  
LEFT JOIN ProductCategory PCSR ON PCSR.ID = SR.ProductCategoryID  
JOIN  [Case] C WITH (NOLOCK) ON C.ID = SR.CaseID  
JOIN  Program P WITH (NOLOCK) ON P.ID = C.ProgramID  
JOIN  Client CL WITH (NOLOCK) ON CL.ID = P.ClientID  
JOIN  Member M WITH (NOLOCK) ON M.ID = C.MemberID  
JOIN  Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID  
LEFT JOIN  Product PR WITH (NOLOCK) ON PR.ID = PO.ProductID  
LEFT JOIN  ProductCategory PC WITH (NOLOCK) ON PC.ID = PR.ProductCategoryID  
LEFT JOIN VehicleType VT WITH(NOLOCK) ON VT.ID = C.VehicleTypeID  
LEFT JOIN VehicleCategory VC WITH(NOLOCK) ON VC.ID = C.VehicleCategoryID  
LEFT JOIN RVType RT WITH (NOLOCK) ON RT.ID = C.VehicleRVTypeID  
JOIN  VendorLocation VL WITH(NOLOCK) ON VL.ID = PO.VendorLocationID  
JOIN  Vendor V WITH(NOLOCK) ON V.ID = VL.VendorID  
--LEFT JOIN [Contract] CO ON CO.VendorID = V.ID  AND CO.IsActive = 1  
--LEFT JOIN ContractRateSchedule CRS ON CRS.ContractID = V.ID AND CO.IsActive = 1  
LEFT OUTER JOIN(  
    SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID  
    FROM dbo.fnGetContractedVendors() cv  
    ) ContractedVendors ON v.ID = ContractedVendors.VendorID   
LEFT JOIN CurrencyType CT ON CT.ID=PO.CurrencyTypeID  
WHERE  PO.PurchaseOrderNumber = @PONumber  
   AND PO.IsActive = 1  
  
END  

GO

GO
-- Get VendorLocation data
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_Vendor_Location_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_Vendor_Location_Details_Get @VendorLocationID=356
 CREATE PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Details_Get( 
	@VendorLocationID INT =NULL
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET FMTONLY OFF
	
	SELECT VL.ID
	 ,CASE  
    WHEN ContractedVendors.ContractID IS NOT NULL   
     AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'  
    ELSE 'Not Contracted'
		END AS 'ContractStatus'
	, V.Name
	, V.VendorNumber
	, AE.Line1
	, AE.Line2
	, AE.Line3
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN 'No billing address on file'
		ELSE ISNULL(REPLACE(RTRIM(
			COALESCE(AE.City, '') +
			COALESCE(', ' + AE.StateProvince, '') +
			COALESCE(' ' + AE.PostalCode, '') +
			COALESCE(' ' + AE.CountryCode, '')
		), ' ', ' ')
	,'')
	END AS BillingCityStZip
	, PE24.PhoneNumber AS [24HRNumber]
	, PEFax.PhoneNumber AS FaxNumber
	, 'Talked To' AS TalkedTo
	
	FROM VendorLocation VL
	JOIN Vendor V ON V.ID = VL.VendorID
	  LEFT OUTER JOIN(  
   SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID  
   FROM dbo.fnGetContractedVendors() cv  
   ) ContractedVendors ON V.ID = ContractedVendors.VendorID   
	LEFT JOIN Contract C ON C.VendorID = V.ID
	AND C.IsActive = 1
	LEFT JOIN ContractRateSchedule CRS ON CRS.ContractID = V.ID
	AND C.IsActive = 1
	LEFT JOIN AddressEntity AE ON AE.RecordID = VL.ID
	AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
	AND AE.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Business')
	LEFT JOIN PhoneEntity PE24 ON PE24.RecordID = VL.ID
	AND PE24.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
	AND PE24.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Dispatch')
	LEFT JOIN PhoneEntity PEFax ON PEFax.RecordID = VL.ID
	AND PEFax.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
	AND PEFax.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Fax')
	WHERE VL.ID = @VendorLocationID
END
GO
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
HasPO BIT NULL,
IsFordDirectTow BIT NULL,
IsCNETDirectPartner BIT NULL
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
@programID INT	= NULL,
@IsFordDirectTow BIT,
@IsCNETDirectPartner BIT
  
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
	HasPo,
	IsFordDirectTow,
	IsCNETDirectPartner
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
 HasPo BIT,
 IsFordDirectTow BIT,
 IsCNETDirectPartner BIT
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
  @HasPO = HasPO,
  @IsFordDirectTow = IsFordDirectTow,
  @IsCNETDirectPartner = IsCNETDirectPartner
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
AND  (@IsFordDirectTow IS NULL OR (@IsFordDirectTow = 1 AND COALESCE(F.Indicators,'') LIKE '%(DT)%'))  
AND  (@IsCNETDirectPartner IS NULL OR (@IsCNETDirectPartner = 1 AND COALESCE(F.Indicators,'') LIKE '%(P)%'))  
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

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Location_Services_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Location_Services_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 --EXEC dms_Vendor_Location_Services_List_Get @VendorID=1, @VendorLocationID=1
CREATE PROCEDURE [dms_Vendor_Location_Services_List_Get](
	@VendorID INT = NULL
 ,	@VendorLocationID INT = NULL
 )
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
DECLARE @FinalResults AS TABLE(
	SortOrder INT NULL,
	ServiceGroup NVARCHAR(255) NULL,
	ServiceName nvarchar(100)  NULL ,
	ProductID int  NULL ,
	VehicleCategorySequence int  NULL ,
	ProductCategory nvarchar(100)  NULL ,
	IsAvailByVendor bit default 0 ,
	IsAvailByVendorLocation bit default 0
) 

INSERT INTO @FinalResults (SortOrder, ServiceGroup,ServiceName,ProductID,VehicleCategorySequence,ProductCategory)
	SELECT 
			 CASE	WHEN vc.name is NULL THEN 2 
					ELSE 1 
			 END AS SortOrder
			,CASE	WHEN vc.name is NULL THEN 'Other' 
					ELSE vc.name 
			 END AS ServiceGroup
			,REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
			--,ISNULL(vc.Name,'') + CASE WHEN ISNULL(vc.Name,'') <> '' THEN ' - ' ELSE '' END  + REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory			
	FROM Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
	LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('PrimaryService', 'SecondaryService')
	AND p.Name Not in ('Concierge', 'Information', 'Tech')
	AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee')

	UNION
	SELECT 
			3 AS SortOrder
			,'Additional' AS ServiceGroup
			,p.Name AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory
	FROM	Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
	LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('AdditionalService')
	AND p.Name Not in ('Concierge', 'Information', 'Tech')
	AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials')
	
	UNION ALL
	
	SELECT 
			 4 AS SortOrder
			,pst.Name AS ServiceGroup
			, p.Name AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory
	FROM	Product p
	Join	ProductCategory pc on p.productCategoryid = pc.id
	Join	ProductType pt on p.ProductTypeID = pt.ID
	Join	ProductSubType pst on p.ProductSubTypeID = pst.id
	Left Outer Join VehicleCategory vc on p.VehicleCategoryID = vc.ID
	Left Outer Join VehicleType vt on p.VehicleTypeID = vt.ID
	Where	pt.Name = 'Attribute'
	and		pc.Name = 'Repair'
	--and		pst.Name NOT IN ('Client')	
	ORDER BY SortOrder, VehicleCategorySequence, ProductCategory , ServiceGroup
	
	UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
	LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
	WHERE VP.VendorID=@VendorID

	UPDATE @FinalResults SET IsAvailByVendorLocation = 1 FROM  @FinalResults T
	LEFT JOIN VendorLocationProduct VLP ON VLP.ProductID = T.ProductID
	WHERE VLP.VendorLocationID=@VendorLocationID

	SELECT *  FROM @FinalResults WHERE IsAvailByVendor=1 OR IsAvailByVendorLocation = 1
END
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Services_List_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Services_List_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 --EXEC dms_Vendor_Services_List_Get @VendorID=1
CREATE PROCEDURE dms_Vendor_Services_List_Get @VendorID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
DECLARE @FinalResults AS TABLE(
	SortOrder INT NULL,
	ServiceGroup NVARCHAR(255) NULL,
	ServiceName nvarchar(100)  NULL ,
	ProductID int  NULL ,
	VehicleCategorySequence int  NULL ,
	ProductCategory nvarchar(100)  NULL ,
	IsAvailByVendor bit default 0
) 

INSERT INTO @FinalResults (SortOrder, ServiceGroup,ServiceName,ProductID,VehicleCategorySequence,ProductCategory)
	SELECT 
			 CASE	WHEN vc.name is NULL THEN 2 
					ELSE 1 
			 END AS SortOrder
			,CASE	WHEN vc.name is NULL THEN 'Other' 
					ELSE vc.name 
			 END AS ServiceGroup
			,REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
			--,ISNULL(vc.Name,'') + CASE WHEN ISNULL(vc.Name,'') <> '' THEN ' - ' ELSE '' END  + REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory			
	FROM Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
	LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('PrimaryService', 'SecondaryService')
	AND p.Name Not in ('Concierge', 'Information', 'Tech')
	AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee')

	UNION
	SELECT 
			3 AS SortOrder
			,'Additional' AS ServiceGroup
			,p.Name AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory
	FROM	Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
	LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('AdditionalService')
	AND p.Name Not in ('Concierge', 'Information', 'Tech')
	AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials')	
	
	UNION ALL
	
	SELECT 
			4 AS SortOrder
			,pst.Name AS ServiceGroup 
			,p.Name AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory
	FROM Product p
	Join ProductCategory pc on p.productCategoryid = pc.id
	Join ProductType pt on p.ProductTypeID = pt.ID
	Join ProductSubType pst on p.ProductSubTypeID = pst.id
	Left Outer Join VehicleCategory vc on p.VehicleCategoryID = vc.ID
	Left Outer Join VehicleType vt on p.VehicleTypeID = vt.ID
	Where pt.Name = 'Attribute'
	and pc.Name = 'Repair'
	--and pst.Name NOT IN ('Client')
	ORDER BY SortOrder, VehicleCategorySequence, ProductCategory
	

UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
WHERE VP.VendorID=@VendorID
	
SELECT * FROM @FinalResults

END
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_tempcc_match_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_tempcc_match_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vendor_tempcc_match_update] @tempccIdXML = '<Tempcc><ID>1</ID><ID>2</ID><ID>3</ID><ID>4</ID></Tempcc>',@currentUser = 'demouser'
 CREATE PROCEDURE [dbo].[dms_vendor_tempcc_match_update](
	@tempccIdXML XML,
	@currentUser NVARCHAR(50)
  )
 AS
 BEGIN
 
    SET FMTONLY OFF
	SET NOCOUNT ON

	DECLARE @now DATETIME = GETDATE()
	DECLARE @CCExpireDays int = 30
	DECLARE @MinCreateDate datetime

	DECLARE @Matched INT =0
		,@MatchedAmount money =0
		,@Unmatched int = 0
		,@UnmatchedAmount money = 0
		,@Posted INT=0
		,@PostedAmount money=0
		,@Cancelled INT=0
		,@CancelledAmount money=0
		,@Exception INT=0
		,@ExceptionAmount money=0
		,@MatchedIds nvarchar(max)=''

	DECLARE @MatchedTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Matched')
		,@UnMatchedTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'UnMatched')
		,@PostededTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Posted')
		,@CancelledTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Cancelled')
		,@ExceptionTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Exception')

	-- Build table of selected items
	CREATE TABLE #SelectedTemporaryCC 
	(	
		ID INT IDENTITY(1,1),
		TemporaryCreditCardID INT
	)

	INSERT INTO #SelectedTemporaryCC
	SELECT tcc.ID
	FROM TemporaryCreditCard tcc WITH (NOLOCK)
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @tempccIdXML.nodes('/Tempcc/ID') T(c)
			) T ON tcc.ID = T.ID

	CREATE CLUSTERED INDEX IDX_SelectedTemporaryCC ON #SelectedTemporaryCC(TemporaryCreditCardID)

		
	/**************************************************************************************************/
	-- Update (Reset) Selected items to Unmatched where status is not Posted
	UPDATE tc SET 
		TemporaryCreditCardStatusID = @UnmatchedTemporaryCreditCardStatusID
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = NULL
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	WHERE tcs.Name <> 'Posted'


	/**************************************************************************************************/
	--Update for Exact match on PO# and CC#
	--Conditions:
	--	PO# AND CC# match exactly
	--	PO Status is Issued or Issued Paid
	--	PO has not been deleted
	--	PO does not already have a related Vendor Invoice
	--	Temporary CC has not already been posted
	--Match Status
	--	Total CC charge amount LESS THAN or EQUAL to the PO amount
	--Exception Status
	--	Total CC charge amount GREATER THAN the PO amount
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE
				 --Cancelled 
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Cancelled', 'Issued', 'Issued-Paid')) 
						AND vi.ID IS NULL 
						AND (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
						AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN @CancelledTemporaryCreditCardStatusID
				 --Matched
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > 0
                        AND ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount
					THEN @MatchedTemporaryCreditCardStatusID
				 --Cancelled	
				 WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN @CancelledTemporaryCreditCardStatusID
				 --Exception
				 ELSE @ExceptionTemporaryCreditCardStatusID
				 END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				 --Cancelled 
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Cancelled', 'Issued', 'Issued-Paid')) 
						AND vi.ID IS NULL 
						AND (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
						AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN NULL
				 --Matched
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > 0
                        AND ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount
					THEN NULL
				 --Exception: PO has not been charged
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) = 0
					THEN 'Credit card has not been charged by the vendor'
				 --Exception: Charge more than PO Amount
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > po.PurchaseOrderAmount 
					THEN 'Charge amount exceeds PO amount'
				 --Cancelled	
				 WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN NULL
				 -- Other Exceptions	
				 WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 ELSE NULL
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = RIGHT(tc.CreditCardNumber,5)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID and vi.IsActive = 1
	WHERE 1=1
	AND tcs.Name = 'Unmatched'
		
		
		
	/**************************************************************************************************/
	-- Update For No matches on PO# or CC#
	-- Conditions:
	--	No potential PO matches exist
	--  No potential CC# matches exist
	-- Cancelled Status
	--	Temporary Credit Card Issue Status is Cancelled
	-- Exception Status
	--	Temporary Credit Card Issue Status is NOT Cancelled
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE 
				WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN @CancelledTemporaryCreditCardStatusID
				ELSE @ExceptionTemporaryCreditCardStatusID
				END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN NULL
				ELSE 'No matching PO# or CC#'
				END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	WHERE  1=1
	AND tcs.Name = 'Unmatched'
	AND NOT EXISTS (
		SELECT *
		FROM PurchaseOrder po
		WHERE
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		)
	AND NOT EXISTS (
		SELECT *
		FROM PurchaseOrder po
		WHERE  
		po.PurchaseOrderNumber <> LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND po.CompanyCreditCardNumber IS NOT NULL
		AND RIGHT(RTRIM(po.CompanyCreditCardNumber),5) = RIGHT(tc.CreditCardNumber,5)
		)


	/**************************************************************************************************/
	--Update to Exception Status - PO matches and CC# does not match
	-- Conditions
	--	PO# matches exactly
	--	CC# does not match or is blank
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE
				WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN @CancelledTemporaryCreditCardStatusID
				WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN @CancelledTemporaryCreditCardStatusID
				ELSE @ExceptionTemporaryCreditCardStatusID
				END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				 --Cancelled	
				 WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN NULL
				 WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN NULL
				 --Exceptions
				 WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 WHEN RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = '' THEN 'Matching PO does not have a credit card number'
				 ELSE 'CC# Mismatch'
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND	RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) <> RIGHT(tc.CreditCardNumber,5)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID and vi.IsActive = 1
	where tcs.Name = 'Unmatched'


	/**************************************************************************************************/
	--Update to Exception Status - PO does not match and CC# matches
	-- Conditions
	--	PO# does not match
	--	CC# matches exactly
	UPDATE tc SET
		TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 ELSE 'PO# Mismatch'
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber <> LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND	RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = RIGHT(tc.CreditCardNumber,5)
		AND po.CreateDate >= DATEADD(dd,1,tc.IssueDate)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID and vi.IsActive = 1
	where tcs.Name = 'Unmatched'


	/**************************************************************************************************/
	-- Prepare Results
	SELECT 
		@Matched = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @MatchedTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@MatchedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @MatchedTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Unmatched = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @UnMatchedTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@UnmatchedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @UnMatchedTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Posted = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @PostededTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@PostedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @PostededTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Cancelled = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @CancelledTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@CancelledAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @CancelledTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Exception = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@ExceptionAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID

	-- Build string of 'Matched' IDs
	SELECT @MatchedIds = @MatchedIds + CONVERT(varchar(20),tc.ID) + ',' 
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	WHERE tc.TemporaryCreditCardStatusID = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Matched')

	-- Remove ending comma from string or IDs
	IF LEN(@MatchedIds) > 1 
		SET @MatchedIds = LEFT(@MatchedIds, LEN(@MatchedIds) - 1)

	DROP TABLE #SelectedTemporaryCC
	
	SELECT @Matched 'MatchedCount',
		   @MatchedAmount 'MatchedAmount',
		   --@Unmatched 'UnmatchedCount',
		   --@UnmatchedAmount 'UnmatchedAmount',
		   @Posted 'PostedCount',
		   @PostedAmount 'PostedAmount',
		   @Cancelled 'CancelledCount',
		   @CancelledAmount 'CancelledAmount',
		   @Exception 'ExceptionCount',
		   @ExceptionAmount 'ExceptionAmount',
		   @MatchedIds 'MatchedIds'
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
 WHERE id = object_id(N'[dbo].[dms_VerifyProgramServiceBenefit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC dms_VerifyProgramServiceBenefit 1, 1, 1, 1, 1, NULL, NULL  
CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit]  
        @ProgramID INT   
      , @ProductCategoryID INT  
      , @VehicleCategoryID INT  
      , @VehicleTypeID INT  
      , @SecondaryCategoryID INT = NULL  
      , @ServiceRequestID  INT = NULL  
      , @ProductID INT = NULL  
AS  
BEGIN   
  
	SET NOCOUNT ON    
	SET FMTONLY OFF    

	--KB: 
	SET @ProductID = NULL

	DECLARE @SecondaryProductID INT
		,@OverrideCoverageLimit money 

	/*** Determine Primary and Secondary Product IDs ***/  
	/* Ignore Vehicle related values for Product Categories not requiring a Vehicle */
	IF @ProductCategoryID IN (SELECT ID FROM ProductCategory WHERE IsVehicleRequired = 0)
	BEGIN
		SET @VehicleCategoryID = NULL
		SET @VehicleTypeID = NULL
	END

	/* Select Basic Lockout over Locksmith when a specific product is not provided */  
	IF @ProductID IS NULL AND @ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Lockout')  
	BEGIN  
	SET @ProductID = (SELECT ID FROM Product WHERE Name = 'Basic Lockout')  
	END  

	/* Select Tire Change over Tire Repair when a specific product is not provided */  
	IF @ProductID IS NULL AND @ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tire')  
	BEGIN  
	SET @ProductID = (SELECT ID FROM Product WHERE Name like 'Tire Change%' AND VehicleCategoryID = @VehicleCategoryID)  
	END  

	IF @ProductID IS NULL  
	SELECT @ProductID = p.ID   
	FROM  ProductCategory pc (NOLOCK)   
	JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID   
	  AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')  
	  AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')  
	WHERE  
	pc.ID = @ProductCategoryID   
	AND (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)  
	AND (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)  


	IF @SecondaryCategoryID IS NOT NULL  
	SELECT @SecondaryProductID = p.ID   
	FROM  ProductCategory pc (NOLOCK)   
	JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID   
	  AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')  
	  AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')  
	WHERE  
	pc.ID = @SecondaryCategoryID   
	AND (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)  
	AND (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)  

	-- Coverage Limit Override for Ford ESP vehicles E/F 650 and 750
	IF @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Extended Service Plan (RV & COMM)')
	BEGIN
	IF EXISTS(
		SELECT * 
		FROM [Case] c
		JOIN ServiceRequest sr ON sr.CaseID = c.ID
		WHERE sr.ID = @ServiceRequestID
			AND (SUBSTRING(c.VehicleVIN, 6, 1) IN ('6','7')
				OR c.VehicleModel IN ('F-650', 'F-750'))
		)
		SET @OverrideCoverageLimit = 200.00
	END
   
	SELECT ISNULL(pc.Name,'') ProductCategoryName  
		,pc.ID ProductCategoryID  
		--,pc.Sequence  
		,ISNULL(vc.Name,'') VehicleCategoryName  
		,vc.ID VehicleCategoryID  
		,pp.ProductID  

		,CAST (pp.IsServiceCoverageBestValue AS BIT) AS IsServiceCoverageBestValue
		,CASE WHEN @OverrideCoverageLimit IS NOT NULL THEN @OverrideCoverageLimit ELSE pp.ServiceCoverageLimit END AS ServiceCoverageLimit
		,pp.CurrencyTypeID   
		,pp.ServiceMileageLimit   
		,pp.ServiceMileageLimitUOM   
		,1 AS IsServiceEligible
		--TP: Below logic is not needed; Only eligible services will be added to ProgramProduct 
		--,CASE WHEN pp.ServiceCoverageLimit IS NULL THEN 0   
		--              WHEN pp.IsServiceCoverageBestValue = 1 THEN 1  
		--              WHEN pp.ServiceCoverageLimit = 0 AND pp.IsReimbursementOnly = 1 THEN 1   
		--              WHEN pp.ServiceCoverageLimit = 0 AND ISNULL(pp.ServiceMileageLimit,0) > 0 THEN 1   
		--              WHEN pp.ServiceCoverageLimit = 0 AND pp.ProductID IN (SELECT p.ID FROM Product p WHERE p.ProductCategoryID IN (SELECT ID FROM ProductCategory WHERE Name IN ('Info', 'Tech', 'Concierge'))) THEN 1
		--              WHEN pp.ServiceCoverageLimit > 0 THEN 1  
		--              ELSE 0 END IsServiceEligible  
		,pp.IsServiceGuaranteed   
		,pp.ServiceCoverageDescription  
		,pp.IsReimbursementOnly  
		,CASE WHEN pc.ID = @SecondaryCategoryID THEN 0 ELSE 1 END AS IsPrimary  
	FROM ProgramProduct pp (NOLOCK)  
	JOIN Product p ON p.ID = pp.ProductID  
	LEFT OUTER JOIN ProductCategory pc (NOLOCK) ON pc.ID = p.ProductCategoryID  
	LEFT OUTER JOIN VehicleCategory vc (NOLOCK) ON vc.id = p.VehicleCategoryID  
	WHERE pp.ProgramID = @ProgramID  
	AND (pp.ProductID = @ProductID OR pp.ProductID = @SecondaryProductID)  
	ORDER BY   
	(CASE WHEN pc.ID = @SecondaryCategoryID THEN 0 ELSE 1 END) DESC  
	,pc.Sequence  
     
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
 WHERE id = object_id(N'[dbo].[dms_VerifyProgramServiceEventLimit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

 --EXEC dms_VerifyProgramServiceEventLimit 1, 3,1,null, null, null  
CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit]  
      @ServiceRequestID int
      ,@ProgramID int
      ,@ProductCategoryID int
      ,@ProductID int 
      ,@VehicleTypeID int
      ,@VehicleCategoryID int 
      ,@SecondaryCategoryID INT = NULL
AS
BEGIN

	----Debug
	--DECLARE 
	--      @ServiceRequestID int = 7779982
	--      ,@ProgramID int = 3
	--      ,@ProductCategoryID int = 1
	--      ,@ProductID int = NULL
	--      ,@VehicleTypeID int = 1
	--      ,@VehicleCategoryID int = 1
	--      ,@SecondaryCategoryID INT = 1

	SET NOCOUNT ON  
	SET FMTONLY OFF  

	DECLARE @MemberID INT
		,@ProgramServiceEventLimitID int
		,@ProgramServiceEventLimitStoredProcedureName nvarchar(255)
		,@ProgramServiceEventLimitDescription nvarchar(255)
		,@MemberExpirationDate datetime
		,@MemberRenewalDate datetime

	SELECT @MemberID = m.ID
	  ,@MemberExpirationDate = m.ExpirationDate
	  ,@ProgramID = CASE WHEN @ProgramID IS NULL THEN m.ProgramID ELSE  @ProgramID END
	FROM ServiceRequest SR 
	JOIN [Case] c on c.id = SR.CaseID
	JOIN Member m on m.ID = c.MemberID
	WHERE SR.ID = @ServiceRequestID
	
	-- Determine last annual renewal date 
	SET @MemberRenewalDate = DATEADD(yy, (ROUND(DATEDIFF(dd, getdate(), @MemberExpirationDate)/365.00,0,1) + 1)*-1, @MemberExpirationDate)
	  
	If @ProductID IS NOT NULL
		SELECT @ProductCategoryID = ProductCategoryID
			  ,@VehicleCategoryID = VehicleCategoryID
			  ,@VehicleTypeID = VehicleTypeID
		FROM Product 
		WHERE ID = @ProductID

	-- Check for a custom stored procedure that verifies the event limits for this program
	SELECT TOP 1 
		@ProgramServiceEventLimitID = ID
		,@ProgramServiceEventLimitStoredProcedureName = StoredProcedureName
		,@ProgramServiceEventLimitDescription = [Description]
	FROM ProgramServiceEventLimit
	WHERE ProgramID = @ProgramID
	AND StoredProcedureName IS NOT NULL
	AND IsActive = 1
	
	
	IF @ProgramServiceEventLimitStoredProcedureName IS NOT NULL
		-- Custome stored procedure used to verify the event limits for the program
		BEGIN
		
		DECLARE @LimitEligibilityResults TABLE (
			ID int
			,ProgramID int
			,[Description] nvarchar(255)
			,Limit int
			,EventCount int
			,IsPrimary int
			,IsEligible int)
		
		INSERT INTO @LimitEligibilityResults	
		EXECUTE @ProgramServiceEventLimitStoredProcedureName 
		   @ServiceRequestID
		  ,@ProgramID
		  ,@ProductCategoryID
		  ,@ProductID
		  ,@VehicleTypeID
		  ,@VehicleCategoryID
		  ,@SecondaryCategoryID

		SELECT 
			@ProgramServiceEventLimitID ID
			,@ProgramID ProgramID
			,@ProgramServiceEventLimitDescription [Description]
			,Limit
			,EventCount
			,IsPrimary
			,IsEligible
		FROM @LimitEligibilityResults
			
		END
	
	ELSE
		-- Event limits are configured for specific program products
		BEGIN
		Select 
				ServiceRequestEvent.ProgramServiceEventLimitID
				,ServiceRequestEvent.ProgramEventLimitDescription
				,ServiceRequestEvent.ProgramEventLimit
				,ServiceRequestEvent.ProgramID
				,ServiceRequestEvent.MemberID
				,ServiceRequestEvent.ProductCategoryID
				,ServiceRequestEvent.ProductID
				,MIN(MinEventDate) MinEventDate
				,count(*) EventCount
			Into #tmpProgramEventCount
			From (
				Select 
					  ppl.ID ProgramServiceEventLimitID
					  ,ppl.[Description] ProgramEventLimitDescription
					  ,ppl.Limit ProgramEventLimit
					  ,c.ProgramID 
					  ,c.MemberID
					  ,sr.ID ServiceRequestID
					  ,ppl.ProductCategoryID
					  ,ppl.ProductID
					  ,pc.Name ProductCategoryName
					  ,MIN(po.IssueDate) MinEventDate 
				From [Case] c
				Join ServiceRequest sr on c.ID = sr.CaseID
				Join PurchaseOrder po on sr.ID = po.ServiceRequestID and po.PurchaseOrderStatusID in (Select ID from PurchaseOrderStatus Where Name IN ('Issued', 'Issued-Paid'))
				Join Product p on po.ProductID = p.ID
				Join ProductCategory pc on pc.id = p.ProductCategoryID
				Join ProgramServiceEventLimit ppl on ppl.ProgramID = c.ProgramID 
					  and (ppl.ProductCategoryID IS NULL OR ppl.ProductCategoryID = pc.ID)
					  and (ppl.ProductID IS NULL OR ppl.ProductID = p.ID)
					  and ppl.IsActive = 1
					  and po.IssueDate > 
							CASE WHEN ppl.IsLimitDurationSinceMemberRenewal = 1
									AND @MemberRenewalDate > (
										CASE WHEN ppl.LimitDurationUOM = 'Day' THEN DATEADD(dd,-ppl.LimitDuration, getdate())
											 WHEN ppl.LimitDurationUOM = 'Month' THEN DATEADD(mm,-ppl.LimitDuration, getdate())
											 WHEN ppl.LimitDurationUOM = 'Year' THEN DATEADD(yy,-ppl.LimitDuration, getdate())
											 ELSE NULL
											 END
										) THEN @MemberRenewalDate
  								 WHEN ppl.LimitDurationUOM = 'Day' THEN DATEADD(dd,-ppl.LimitDuration, getdate())
								 WHEN ppl.LimitDurationUOM = 'Month' THEN DATEADD(mm,-ppl.LimitDuration, getdate())
								 WHEN ppl.LimitDurationUOM = 'Year' THEN DATEADD(yy,-ppl.LimitDuration, getdate())
								 ELSE NULL
							END 
				Where 
					  c.MemberID = @MemberID
					  and c.ProgramID = @ProgramID
					  and po.IssueDate IS NOT NULL
					  and sr.ID <> @ServiceRequestID
				Group By 
					  ppl.ID
					  ,ppl.[Description]
					  ,ppl.Limit
					  ,c.programid
					  ,c.MemberID
					  ,sr.ID
					  ,ppl.ProductCategoryID
					  ,ppl.ProductID
					  ,pc.Name
				) ServiceRequestEvent
			Group By 
				ServiceRequestEvent.ProgramServiceEventLimitID
				,ServiceRequestEvent.ProgramEventLimit
				,ServiceRequestEvent.ProgramEventLimitDescription
				,ServiceRequestEvent.ProgramID
				,ServiceRequestEvent.MemberID
				,ServiceRequestEvent.ProductCategoryID
				,ServiceRequestEvent.ProductID


			Select 
				psel.ID --ProgramServiceEventLimitID
				,psel.ProgramID
				,psel.[Description]
				,psel.Limit
				,ISNULL(pec.EventCount, 0) EventCount
				,CASE WHEN psel.ProductCategoryID = @SecondaryCategoryID AND @ProductCategoryID <> @SecondaryCategoryID THEN 0 ELSE 1 END IsPrimary
				,CASE WHEN ISNULL(pec.EventCount, 0) < psel.Limit THEN 1 ELSE 0 END IsEligible
			From ProgramServiceEventLimit psel
			Left Outer Join #tmpProgramEventCount pec on pec.ProgramServiceEventLimitID = psel.ID
			Where psel.IsActive = 1
			AND psel.ProgramID = @ProgramID
			AND   (
					  (@ProductID IS NOT NULL 
							AND psel.ProductID = @ProductID)
					  OR
					  (@ProductID IS NULL 
							AND (psel.ProductCategoryID = @ProductCategoryID OR psel.ProductCategoryID IS NULL) 
							AND (@VehicleCategoryID IS NULL OR psel.VehicleCategoryID IS NULL OR psel.VehicleCategoryID = @VehicleCategoryID)
							AND (@VehicleTypeID IS NULL OR psel.VehicleTypeID IS NULL OR psel.VehicleTypeID = @VehicleTypeID)
					  )
					  OR
					  (psel.ProductCategoryID = @SecondaryCategoryID AND @ProductCategoryID <> @SecondaryCategoryID
							AND (@VehicleCategoryID IS NULL OR psel.VehicleCategoryID IS NULL OR psel.VehicleCategoryID = @VehicleCategoryID)
							AND (@VehicleTypeID IS NULL OR psel.VehicleTypeID IS NULL OR psel.VehicleTypeID = @VehicleTypeID)
					  ))
			ORDER BY 
				(CASE WHEN ISNULL(pec.EventCount, 0) < psel.Limit THEN 1 ELSE 0 END) ASC
				,(CASE WHEN psel.ProductCategoryID = @SecondaryCategoryID THEN 0 ELSE 1 END) DESC
				,psel.ProductID DESC

			Drop table #tmpProgramEventCount
		END

END

GO

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_SecurablePermissions]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_SecurablePermissions]
	GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE function fn_SecurablePermissions(@SecurableID INT) RETURNS @Permission TABLE(SecurableID INT,Permission NVARCHAR(MAX))
AS
BEGIN
	DECLARE @ResultTemp AS TABLE(SecurableID INT, 
								 SecurableName NVARCHAR(MAX), 
								 AccessTypeID INT,
								 AccessTypeName NVARCHAR(MAX),
								 RoleID UNIQUEIDENTIFIER,
								 RoleName NVARCHAR(MAX))

	INSERT INTO @ResultTemp
	SELECT		ACL.SecurableID,
				S.FriendlyName,
				ACL.AccessTypeID,
				AT.Name,
				ACL.RoleID,
				AR.RoleName
	FROM		AccessControlList ACL
	LEFT JOIN Securable S ON ACL.SecurableID = S.ID
	LEFT JOIN AccessType AT ON AT.ID = ACL.AccessTypeID
	LEFT JOIN aspnet_Roles AR ON ACL.RoleID = AR.RoleId
	LEFT JOIN aspnet_Applications AP ON AR.ApplicationId = AP.ApplicationId
	WHERE AP.ApplicationName = 'DMS'
	AND  ACL.SecurableID = @SecurableID

	;WITH wTemp AS(
					SELECT SecurableID,
						   SecurableName,
						   AccessTypeID,
						   AccessTypeName,
						   AccessTypeName  + ' : ' +
						   STUFF((SELECT	 '| '  + RoleName 
											  FROM @ResultTemp B
											  WHERE B.AccessTypeID = A.AccessTypeID 
											  ORDER BY RoleName
											  FOR XML PATH('')), 1, 2, '') As AllPermissions
					FROM @ResultTemp A
					GROUP BY 
					SecurableID,
					SecurableName,
					AccessTypeID,
					AccessTypeName
	)
	INSERT INTO @Permission
	SELECT  	W.SecurableID,
			    STUFF((SELECT	 ', '  +	  AllPermissions 
											  FROM wTemp B
											  ORDER BY B.AccessTypeName
											  FOR XML PATH('')), 1, 2, '')
	FROM	    wTemp W
	GROUP BY W.SecurableID
	RETURN
END



GO

GO
