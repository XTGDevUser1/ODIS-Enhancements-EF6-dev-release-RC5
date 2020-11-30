
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
 WHERE id = object_id(N'[dbo].[dms_Members_By_VIN_MembershipNumber_Search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Members_By_VIN_MembershipNumber_Search]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Members_By_VIN_MembershipNumber_Search] @whereClauseXML=N'<ROW><Filter FirstNameOperator="4" FirstNameValue="jeevan"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
--EXEC [dbo].[dms_Members_By_VIN_MembershipNumber_Search] @whereClauseXML=N'<ROW><Filter PhoneNumberOperator="2" PhoneNumberValue="8173078882"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
--EXEC [dbo].[dms_Members_By_VIN_MembershipNumber_Search] @whereClauseXML=N'<ROW><Filter MemberNumberOperator="2" MemberNumberValue="1FAEA92016"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=165
-- EXEC [dbo].[dms_Members_By_VIN_MembershipNumber_Search] @whereClauseXML=N'<ROW><Filter VINOperator="4" VINValue="K1234422323N1233"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
-- EXEC [dbo].[dms_Members_By_VIN_MembershipNumber_Search] @whereClauseXML=N'<ROW><Filter MemberNumberOperator="4" MemberNumberValue="00000000"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3

CREATE PROCEDURE [dbo].[dms_Members_By_VIN_MembershipNumber_Search](   
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10   
 , @sortColumn nvarchar(100)  = 'MemberNumber'   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @programID INT = NULL   
 )   
 AS   
 BEGIN   
    
	SET NOCOUNT ON    
SET FMTONLY OFF;
	-- KB : Temporary resultsets. These resultsets are used to prepare mangeable resultsets.
	CREATE TABLE #FinalResultsFiltered(     

	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	Suffix nvarchar(50)  NULL ,    
	Prefix nvarchar(50)  NULL ,    
	City nvarchar(50)  NULL ,    
	StateProvince nvarchar(50)  NULL ,    
	PostalCode nvarchar(50)  NULL ,    
	HomePhoneNumber nvarchar(50)  NULL ,    
	WorkPhoneNumber nvarchar(50)  NULL ,    
	CellPhoneNumber nvarchar(50)  NULL ,  
	ProgramID INT NULL, -- KB: ADDED IDS  
	Program nvarchar(50)  NULL ,    
	POCount INT NULL,  
	ExpirationDate DATETIME NULL,   
	EffectiveDate DATETIME NULL,
	VIN nvarchar(50)  NULL ,    
	VehicleID INT NULL, -- KB: Added VehicleID
	[StateProvinceID] INT  NULL,
	MiddleName   nvarchar(50)  NULL , 
	)    

	CREATE TABLE #FinalResultsFormatted(      
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,  
	VehicleID INT NULL, -- KB: Added VehicleID  
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL     
	)    

	CREATE TABLE #FinalResultsSorted(     
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL , 
	VehicleID INT NULL, -- KB: Added VehicleID   
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL     
	)  
	CREATE TABLE #FinalResultsDistinct(     
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,  
	VehicleID INT NULL, -- KB: Added VehicleID  
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL     
	)  	
	--Select * From #SearchPrograms
	--Drop table #SearchPrograms
	
	DECLARE @idoc int    
	IF @whereClauseXML IS NULL     
	BEGIN    
	SET @whereClauseXML = '<ROW><Filter     
	MemberIDOperator="-1"     
	MemberNumberOperator="-1"     
	PhoneNumberOperator="-1"     
	ProgramOperator="-1"     
	LastNameOperator="-1"     
	FirstNameOperator="-1"     
	VINOperator="-1"     
	StateOperator="-1"    
	ZipCodeOperator = "-1"   
	></Filter></ROW>'    
	END    
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML    

	DECLARE @tmpForWhereClause TABLE    
	(    
	MemberIDOperator INT NOT NULL,    
	MemberIDValue int NULL,    
	MemberNumberOperator INT NOT NULL,    
	MemberNumberValue nvarchar(50) NULL,    
	PhoneNumberOperator INT NOT NULL,    
	PhoneNumberValue nvarchar(50) NULL,    
	ProgramOperator INT NOT NULL,    
	ProgramValue nvarchar(50) NULL,    
	LastNameOperator INT NOT NULL,    
	LastNameValue nvarchar(50) NULL,    
	FirstNameOperator INT NOT NULL,    
	FirstNameValue nvarchar(50) NULL,    
	VINOperator INT NOT NULL,    
	VINValue nvarchar(50) NULL,    
	StateOperator INT NOT NULL,    
	StateValue nvarchar(50) NULL,  
	ZipCodeOperator INT NOT NULL,    
	ZipCodeValue   nvarchar(50) NULL  
	)    

	-- Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'     

	INSERT INTO @tmpForWhereClause    
	SELECT      
			ISNULL(MemberIDOperator,-1),    
			MemberIDValue ,    
			ISNULL(MemberNumberOperator,-1),    
			MemberNumberValue ,    
			ISNULL(PhoneNumberOperator,-1),    
			PhoneNumberValue ,    
			ISNULL(ProgramOperator,-1),    
			ProgramValue ,    
			ISNULL(LastNameOperator,-1),    
			LastNameValue ,    
			ISNULL(FirstNameOperator,-1),    
			FirstNameValue ,    
			ISNULL(VINOperator,-1),    
			VINValue ,    
			ISNULL(StateOperator,-1),    
			StateValue,    
			ISNULL(ZipCodeOperator,-1),    
			ZipCodeValue    
	FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (    
			MemberIDOperator INT,    
			MemberIDValue int     
			,MemberNumberOperator INT,    
			MemberNumberValue nvarchar(50)     
			,PhoneNumberOperator INT,    
			PhoneNumberValue nvarchar(50)     
			,ProgramOperator INT,    
			ProgramValue nvarchar(50)     
			,LastNameOperator INT,    
			LastNameValue nvarchar(50)     
			,FirstNameOperator INT,    
			FirstNameValue nvarchar(50)     
			,VINOperator INT,    
			VINValue nvarchar(50)     
			,StateOperator INT,    
			StateValue nvarchar(50)     
			,ZipCodeOperator INT,    
			ZipCodeValue nvarchar(50)   
	)     
	
	
	DECLARE @vinParam nvarchar(50)    
	SELECT @vinParam = VINValue FROM @tmpForWhereClause    

	DECLARE @membershipEntityID INT  
	SELECT @membershipEntityID = ID FROM Entity WHERE Name = 'Membership'  
	
	DECLARE @homeAddressType INT 
	SELECT @homeAddressType = (SELECT ID FROM AddressType WHERE Name = 'Home')
	--------------------- BEGIN -----------------------------    
	----   Create a temp variable or a CTE with the actual SQL search query ----------    
	----   and use that CTE in the place of <table> in the following SQL statements ---    
	--------------------- END -----------------------------    
	DECLARE @phoneNumber NVARCHAR(100)  
	SET @phoneNumber = (SELECT PhoneNumberValue FROM @tmpForWhereClause)  

	DECLARE @memberID INT
	DECLARE @memberNumber NVARCHAR(50)
	DECLARE @programCode NVARCHAR(50)
	DECLARE @firstName NVARCHAR(50)
	DECLARE @lastName NVARCHAR(50)
	DECLARE @state NVARCHAR(50)
	DECLARE @zip NVARCHAR(50)

	SELECT	@memberID = MemberIDValue,
			@memberNumber = MemberNumberValue,
			@programCode = ProgramValue,
			@firstName = FirstNameValue,
			@lastName = LastNameValue,
			@state = StateValue,
			@zip = ZipCodeValue
	FROM	@tmpForWhereClause

	
	SET FMTONLY OFF;  
	  
	

	-- If vehicle is given, then let's use Vehicle in the left join (as the first table) else don't even consider vehicle table.

		IF @vinParam IS NOT NULL
		BEGIN

			SELECT	* 
			INTO	#TmpVehicle1
			FROM	Vehicle V WITH (NOLOCK)
			WHERE	V.VIN = @vinParam 


			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber-- PH.PhoneNumber AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber -- PW.PhoneNumber AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber -- PC.PhoneNumber AS CellPhoneNumber  
					, P.ID As ProgramID  -- KB: ADDED IDS
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate   
					, m.EffectiveDate 
					, v.VIN  
					, v.ID AS VehicleID
					, A.[StateProvinceID]
					,M.MiddleName 

			FROM #TmpVehicle1 v
			LEFT JOIN Member M WITH (NOLOCK) ON  (v.MemberID IS NULL OR v.MemberID = m.ID) 
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID AND v.MembershipID = MS.ID
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = MS.ID AND A.EntityID = @membershipEntityID  AND A.AddressTypeID = @homeAddressType
			JOIN [dbo].[fnc_GetChildPrograms] (@programID) FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID   
			
			WHERE   ( V.VIN = @vinParam ) -- LIKE '%' + @vinParam + '%')
					 
			AND		ISNULL(M.IsActive,0) = 1
					 
			DROP TABLE #TmpVehicle1

		END -- End of Vin param check
		ELSE
		BEGIN

			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber-- PH.PhoneNumber AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber -- PW.PhoneNumber AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber -- PC.PhoneNumber AS CellPhoneNumber
					, P.ID As ProgramID  -- KB: ADDED IDS  
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate   
					, m.EffectiveDate 
					, NULL AS VIN
					, NULL AS VehicleID
					, A.[StateProvinceID]
					,M.MiddleName 
			FROM Member M WITH (NOLOCK)  
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID   
			
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = MS.ID AND A.EntityID = @membershipEntityID AND A.AddressTypeID = @homeAddressType  
			JOIN [dbo].[fnc_GetChildPrograms] (@programID) FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID  
			WHERE   (MS.MembershipNumber = @memberNumber )--LIKE  '%' + @memberNumber + '%')					 
			AND		ISNULL(M.IsActive,0) = 1
			
			--DEBUG: SELECT * FROM #FinalResultsFiltered
			
			;WITH wMSVehicles
			AS
			(
				SELECT  ROW_NUMBER() OVER ( PARTITION BY V.MembershipID, V.ID ORDER BY V.ID DESC) AS RowNum,
						V.ID, V.VIN, V.MembershipID
				FROM	Vehicle V
				JOIN	#FinalResultsFiltered F ON V.MembershipID = F.MembershipID
				WHERE	V.VIN IS NOT NULL
				
			)
			
			UPDATE #FinalResultsFiltered
			SET		VIN = V.VIN,
					VehicleID = V.ID
			--SELECT  V.RowNum, F.MembershipID, V.MembershipID, V.ID
			FROM	#FinalResultsFiltered F 
			LEFT JOIN	wMSVehicles V ON F.MembershipID = V.MembershipID AND V.RowNum = 1
		
		END		
		
	
	
	-- DEBUG:   
	--SELECT COUNT(*) AS Filtered FROM #FinalResultsFiltered  

	-- Do all computations  
	INSERT INTO #FinalResultsFormatted  
	SELECT   F.MemberID  
	, F.MembershipID  
	, F.MemberNumber     
	
	,REPLACE(RTRIM( 
	COALESCE(F.FirstName, '') + 
	COALESCE(' ' + left(F.MiddleName,1), '') + 
	COALESCE(' ' + F.LastName, '') +
	COALESCE(' ' + F.Suffix, '')
	), ' ', ' ') AS MemberName
	,(ISNULL(F.City,'') + ',' + ISNULL(F.StateProvince,'') + ' ' + ISNULL(F.PostalCode,'')) AS [Address]     
	, COALESCE(F.HomePhoneNumber, F.WorkPhoneNumber, F.CellPhoneNumber, '') As PhoneNumber 
	, F.ProgramID -- KB: ADDED IDS    
	, F.Program    
	, 0 AS POCount --(SELECT COUNT(*) FROM [Case] WHERE MemberID = F.MemberID) AS POCount   
	
	-- KB: Considering Effective and Expiration Dates to calculate member status
	,CASE WHEN ISNULL(F.EffectiveDate,@minDate) <= @now AND ISNULL(F.ExpirationDate,@minDate) >= @now
			THEN 'Active'
			ELSE 'Inactive'
	END AS MemberStatus
	, F.LastName  
	, F.FirstName  
	, F.VIN
	, F.VehicleID  
	, F.StateProvinceID AS [State]  
	, F.PostalCode AS ZipCode
	FROM #FinalResultsFiltered F  

	

		INSERT INTO #FinalResultsSorted  
		SELECT  F.MemberID,  
		F.MembershipID,    
		F.MemberNumber,     
		F.Name,    
		F.[Address],    
		--COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber,  
		NULL AS PhoneNumber,
		F.ProgramID, -- KB: ADDED IDS     
		F.Program,    
		F.POCount,    
		F.MemberStatus,    
		F.LastName,    
		F.FirstName ,    
		F.VIN ,
		F.VehicleID,    
		F.[State] ,    
		F.ZipCode   
		FROM  #FinalResultsFormatted F   
		--LEFT JOIN PhoneEntity PH WITH (NOLOCK) ON PH.RecordID = F.MembershipID AND PH.PhoneTypeID = 1 AND PH.EntityID = @membershipEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PH.PhoneNumber)  
		--LEFT JOIN PhoneEntity PW WITH (NOLOCK) ON PW.RecordID = F.MembershipID AND PW.PhoneTypeID = 2 AND PW.EntityID = @membershipEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PW.PhoneNumber)  
		--LEFT JOIN PhoneEntity PC WITH (NOLOCK) ON PC.RecordID = F.MembershipID AND PC.PhoneTypeID = 3 AND PC.EntityID = @membershipEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PC.PhoneNumber) 

		ORDER BY  F.MemberNumber 
	
	 
-- DEBUG:
--SELECT * FROM #FinalResultsSorted

	-- Let's delete duplicates from #FinalResultsSorted and then insert into Distinct.
	
	;WITH wSorted 
	AS
	(
		SELECT ROW_NUMBER() OVER (PARTITION BY 
			F.MemberID,  
			F.MembershipID,    
			F.MemberNumber,     
			F.Name,    
			F.[Address],    
			F.PhoneNumber,    
			F.Program,    
			F.POCount,    
			F.MemberStatus,    
			F.VIN,
			F.VehicleID ORDER BY F.RowNum) AS sRowNumber	
		FROM #FinalResultsSorted F
	)
	
	DELETE FROM wSorted WHERE sRowNumber > 1
	
	INSERT INTO #FinalResultsDistinct(
			MemberID,  
			MembershipID,    
			MemberNumber,     
			Name,    
			[Address],    
			PhoneNumber,  
			ProgramID, -- KB: ADDED IDS      
			Program,    
			POCount,    
			MemberStatus,    
			VIN,
			VehicleID 
	)   
	SELECT	F.MemberID,  
			F.MembershipID,    
			F.MemberNumber,     
			F.Name,    
			F.[Address],    
			F.PhoneNumber,
			F.ProgramID, -- KB: ADDED IDS        
			F.Program,    
			F.POCount,    
			F.MemberStatus,    
			F.VIN,
			F.VehicleID
			
	FROM #FinalResultsSorted F
	ORDER BY 
	F.RowNum  
		

	DECLARE @count INT       
	SET @count = 0       
	SELECT @count = MAX(RowNum) FROM #FinalResultsDistinct   
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



	SELECT @count AS TotalRows, F.MemberID,  
		F.MembershipID,    
	   F.MemberNumber,     
	   F.Name,    
	   F.[Address],    
	   F.PhoneNumber,  
	   F.ProgramID, -- KB: ADDED IDS      
	   F.Program,    
	   F.POCount,    
	   F.MemberStatus,    
	   F.VIN,
	   F.VehicleID   
	   FROM    
	   #FinalResultsDistinct F WHERE RowNum BETWEEN @startInd AND @endInd    
	     
	DROP TABLE #FinalResultsFiltered  
	DROP TABLE #FinalResultsFormatted  
	DROP TABLE #FinalResultsSorted 
	DROP TABLE #FinalResultsDistinct



END
