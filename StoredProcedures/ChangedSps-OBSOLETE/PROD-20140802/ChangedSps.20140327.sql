 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_MemberManagement_Search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_MemberManagement_Search]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
CREATE PROCEDURE [dbo].[dms_MemberManagement_Search](   
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10   
 , @sortColumn nvarchar(100)  = 'MemberNumber'   
 , @sortOrder nvarchar(100) = 'ASC'   
 )   
 AS   
 BEGIN   
    
	SET NOCOUNT ON    
	SET FMTONLY OFF
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
	Program nvarchar(50)  NULL ,    
	POCount INT NULL,  
	ExpirationDate DATETIME NULL,   
	EffectiveDate DATETIME NULL,
	VIN nvarchar(50)  NULL ,    
	[StateProvinceID] INT  NULL,
	MiddleName   nvarchar(50)  NULL , 
	CountryCode nvarchar(2) NULL
	)    

	CREATE TABLE #FinalResultsFormatted(      
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL ,    
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,    
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
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,    
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
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,    
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL     
	)  

	DECLARE @idoc int    
	IF @whereClauseXML IS NULL     
	BEGIN    
	SET @whereClauseXML = '<ROW>
	<Filter     
	MemberIDOperator="-1"     
	MemberNumberOperator="-1"  
	FirstNameOperator="-1"  
	LastNameOperator="-1"      
	CountryIDOperator="-1"      
	StateProvinceIDOperator="-1"
	CityOperator="-1"
	PostalCodeOperator="-1"
	PhoneNumberOperator="-1"
	VINOperator="-1"
	MemberStatusOperator="-1"
	ClientIDOperator="-1"
	ProgramIDOperator="-1">
	</Filter></ROW>'    
	END    
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML    

	DECLARE @tmpForWhereClause TABLE    
	(    
	MemberIDOperator INT NOT NULL,    
	MemberIDValue int NULL,    
	
	MemberNumberOperator INT NOT NULL,    
	MemberNumberValue nvarchar(50) NULL,    
	
	FirstNameOperator INT NOT NULL,
	FirstNameValue nvarchar(50) NULL,  
	
	LastNameOperator INT NOT NULL,
	LastNameValue nvarchar(50) NULL,  
	
	CountryIDOperator INT NOT NULL,
	CountryIDValue INT NULL, 
	
	StateProvinceIDOperator INT NOT NULL,
	StateProvinceIDValue INT NULL, 
	
	CityOperator INT NOT NULL,
	CityValue nvarchar(50) NULL, 
	
	PostalCodeOperator INT NOT NULL,
	PostalCodeValue nvarchar(50) NULL, 
	
	PhoneNumberOperator INT NOT NULL,
	PhoneNumberValue nvarchar(50) NULL, 
	
	VINOperator INT NOT NULL,
	VINValue nvarchar(50) NULL, 
	
	MemberStatusOperator INT NOT NULL,
	MemberStatusValue nvarchar(50) NULL, 
	
	ClientIDOperator INT NOT NULL,
	ClientIDValue INT NULL, 
	
	ProgramIDOperator INT NOT NULL,
	ProgramIDValue INT NULL
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
			
			ISNULL(FirstNameOperator,-1),    
			FirstNameValue ,    
			
			ISNULL(LastNameOperator,-1),    
			LastNameValue,
			
			ISNULL(CountryIDOperator,-1),    
			CountryIDValue,
			
			ISNULL(StateProvinceIDOperator,-1),    
			StateProvinceIDValue,
			
			ISNULL(CityOperator,-1),    
			CityValue,
			
			ISNULL(PostalCodeOperator,-1),    
			PostalCodeValue,
			
			ISNULL(PhoneNumberOperator,-1),    
			PhoneNumberValue,
			
			ISNULL(VINOperator,-1),    
			VINValue,
			
			ISNULL(MemberStatusOperator,-1),    
			MemberStatusValue,
			
			ISNULL(ClientIDOperator,-1),    
			ClientIDValue,
			
			ISNULL(ProgramIDOperator,-1),    
			ProgramIDValue
			 
	FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (    
			MemberIDOperator INT,    
			MemberIDValue int,
			
			MemberNumberOperator INT,    
			MemberNumberValue nvarchar(50),
			
			FirstNameOperator INT,    
			FirstNameValue nvarchar(50),
			
			LastNameOperator INT,    
			LastNameValue nvarchar(50),
			
			CountryIDOperator INT,    
			CountryIDValue INT,
			
			StateProvinceIDOperator INT,    
			StateProvinceIDValue INT,
			
			CityOperator INT,    
			CityValue nvarchar(50),
			
			PostalCodeOperator INT,    
			PostalCodeValue nvarchar(50),
			
			PhoneNumberOperator INT,    
			PhoneNumberValue nvarchar(50),
			
			VINOperator INT,    
			VINValue nvarchar(50),
			
			MemberStatusOperator INT,    
			MemberStatusValue nvarchar(50),
			
			ClientIDOperator INT,    
			ClientIDValue INT,
			
			ProgramIDOperator INT,    
			ProgramIDValue INT			  
	)     
	
	--SELECT * FROM @tmpForWhereClause
	
	DECLARE @vinParam nvarchar(50)    
	SELECT @vinParam = VINValue FROM @tmpForWhereClause    

	DECLARE @memberEntityID INT  
	SELECT @memberEntityID = ID FROM Entity WHERE Name = 'Member'  
	--------------------- BEGIN -----------------------------    
	----   Create a temp variable or a CTE with the actual SQL search query ----------    
	----   and use that CTE in the place of <table> in the following SQL statements ---    
	--------------------- END -----------------------------    
	DECLARE @phoneNumber NVARCHAR(100)  
	SET @phoneNumber = (SELECT PhoneNumberValue FROM @tmpForWhereClause)  

	DECLARE @memberID INT
	DECLARE @memberNumber NVARCHAR(50)
	DECLARE @ProgramID INT = NULL
	DECLARE @ClientID INT = NULL
	DECLARE @firstName NVARCHAR(50)
	DECLARE @lastName NVARCHAR(50)
	DECLARE @stateID INT = NULL
	DECLARE @CountryID INT = NULL
	DECLARE @Zip NVARCHAR(50) = NULL
	DECLARE @City NVARCHAR(50) = NULL
	DECLARE @lastNameOperator INT = NULL
	DECLARE @firstNameOperator INT = NULL
	DECLARE @memberStatusValue NVARCHAR(200) = NULL

	--Sanghi Need to Add Client Join
	SELECT	@memberID = MemberIDValue,
			@memberNumber = MemberNumberValue,
			@ProgramID = ProgramIDValue,
			@ClientID = ClientIDValue,
			@firstName = FirstNameValue,
			@lastName = LastNameValue,
			@stateID =    StateProvinceIDValue,
			@CountryID =  CountryIDValue,
			@Zip = PostalCodeValue,
			@City = CityValue,
			@lastNameOperator = LastNameOperator,
			@firstNameOperator = FirstNameOperator,
			@memberStatusValue = MemberStatusValue
	FROM	@tmpForWhereClause

		
	SET FMTONLY OFF;  
	  
	IF @phoneNumber IS NULL  
	BEGIN  

	-- If vehicle is given, then let's use Vehicle in the left join (as the first table) else don't even consider vehicle table.

		IF @vinParam IS NOT NULL
		
		
		
		BEGIN

			SELECT	* 
			INTO	#TmpVehicle1
			FROM	Vehicle V WITH (NOLOCK)
			WHERE	V.VIN LIKE '%' + @vinParam + '%'


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
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate   
					, m.EffectiveDate 
					, v.VIN  
					, A.[StateProvinceID]
					,M.MiddleName 
					,A.CountryCode
			FROM #TmpVehicle1 v
			LEFT JOIN Member M WITH (NOLOCK) ON  (v.MemberID IS NULL OR v.MemberID = m.ID) 
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID AND v.MembershipID = MS.ID
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN Program P WITH (NOLOCK) ON P.ID = M.ProgramID   
			WHERE  M.IsPrimary =1
			AND	  ((@memberID IS NULL)  OR (@memberID = M.ID))
			AND   ((@memberNumber IS NULL) OR (MS.MembershipNumber LIKE  '%' + @memberNumber + '%'))  
			AND   ((@ProgramID IS NULL) OR (P.ID = @ProgramID)) 
			AND   ((@stateID IS NULL) OR (A.StateProvinceID = @stateID)) 
			AND   ((@CountryID IS NULL) OR (A.CountryID = @CountryID)) 
			AND   ((@Zip IS NULL) OR (A.PostalCode LIKE '%' + @Zip +'%')) 
			AND   ((@City IS NULL) OR (A.City LIKE @City +'%')) 
			AND   ((@lastName IS NULL) OR (@lastNameOperator = 2 AND M.LastName = @lastName ) 
									   OR (@lastNameOperator = 4 AND M.LastName LIKE @lastName + '%')
									   OR (@lastNameOperator = 6 AND M.LastName LIKE '%' + @lastName + '%')
			                           OR (@lastNameOperator = 5 AND M.LastName LIKE '%' + @lastName))	
			
			AND   ((@firstName IS NULL) OR (@firstNameOperator = 2 AND M.FirstName = @firstName)
										OR (@firstNameOperator = 4 AND M.FirstName LIKE @firstName + '%')
										OR (@firstNameOperator = 6 AND M.FirstName LIKE '%' + @firstName + '%') 
										OR (@firstNameOperator = 5 AND M.FirstName LIKE '%' + @firstName)) 
		
			AND M.IsActive=1		 
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
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate   
					, m.EffectiveDate 
					, '' AS VIN  
					, A.[StateProvinceID]
					,M.MiddleName 
					,A.CountryCode
			FROM Member M WITH (NOLOCK)  
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID   
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN Program P WITH (NOLOCK) ON P.ID = M.ProgramID    
			WHERE  M.IsPrimary =1
			AND   ((@memberID IS NULL)  OR (@memberID = M.ID))
			AND   ((@memberNumber IS NULL) OR (MS.MembershipNumber LIKE  '%' + @memberNumber + '%'))  
			AND   ((@ProgramID IS NULL) OR (P.ID = @ProgramID)) 
			AND   ((@stateID IS NULL) OR (A.StateProvinceID = @stateID)) 
			AND   ((@CountryID IS NULL) OR (A.CountryID = @CountryID)) 
			AND   ((@Zip IS NULL) OR (A.PostalCode LIKE '%' + @Zip +'%')) 
			AND   ((@City IS NULL) OR (A.City LIKE @City +'%')) 
		
			AND   ((@lastName IS NULL) OR (@lastNameOperator = 2 AND M.LastName = @lastName ) 
									   OR (@lastNameOperator = 4 AND M.LastName LIKE @lastName + '%')
									   OR (@lastNameOperator = 6 AND M.LastName LIKE '%' + @lastName + '%')
			                           OR (@lastNameOperator = 5 AND M.LastName LIKE '%' + @lastName))	
			
			AND   ((@firstName IS NULL) OR (@firstNameOperator = 2 AND M.FirstName = @firstName)
										OR (@firstNameOperator = 4 AND M.FirstName LIKE @firstName + '%')
										OR (@firstNameOperator = 6 AND M.FirstName LIKE '%' + @firstName + '%') 
										OR (@firstNameOperator = 5 AND M.FirstName LIKE '%' + @firstName))
		    AND M.IsActive=1
		END		
		
	END  -- End of Phone number is null check.
	ELSE  
	BEGIN
	
		SELECT *  
		INTO #tmpPhone  
		FROM PhoneEntity PH WITH (NOLOCK)  
		WHERE PH.EntityID = @memberEntityID   
		AND  PH.PhoneNumber = @phoneNumber   

		-- Consider VIN param.
		IF @vinParam IS NOT NULL
		BEGIN
		
			SELECT	* 
			INTO	#TmpVehicle
			FROM	Vehicle V WITH (NOLOCK)
			WHERE	V.VIN LIKE '%' + @vinParam + '%' 

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
					, NULL AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber  
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate 
					, m.EffectiveDate  
					, v.VIN  
					, A.[StateProvinceID] 
					, M.MiddleName 
					,A.CountryCode
			FROM #TmpVehicle v
			LEFT JOIN Member M WITH (NOLOCK) ON  (v.MemberID IS NULL OR v.MemberID = m.ID) 
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID AND v.MembershipID = MS.ID
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN Program P WITH (NOLOCK) ON P.ID = M.ProgramID   
			JOIN @tmpForWhereClause TMP ON 1=1  
			WHERE M.IsPrimary =1
			AND   ((@memberID IS NULL)  OR (@memberID = M.ID))
			AND   ((@memberNumber IS NULL) OR (MS.MembershipNumber LIKE  '%' + @memberNumber + '%'))  
			AND   ((@ProgramID IS NULL) OR (P.ID = @ProgramID)) 
			AND   ((@stateID IS NULL) OR (A.StateProvinceID = @stateID)) 
			AND   ((@CountryID IS NULL) OR (A.CountryID = @CountryID)) 
			AND   ((@Zip IS NULL) OR (A.PostalCode LIKE '%' + @Zip +'%')) 
			AND   ((@City IS NULL) OR (A.City LIKE @City +'%')) 
			
			AND   ((@lastName IS NULL) OR (@lastNameOperator = 2 AND M.LastName = @lastName ) 
									   OR (@lastNameOperator = 4 AND M.LastName LIKE @lastName + '%')
									   OR (@lastNameOperator = 6 AND M.LastName LIKE '%' + @lastName + '%')
			                           OR (@lastNameOperator = 5 AND M.LastName LIKE '%' + @lastName))	
			
			AND   ((@firstName IS NULL) OR (@firstNameOperator = 2 AND M.FirstName = @firstName)
										OR (@firstNameOperator = 4 AND M.FirstName LIKE @firstName + '%')
										OR (@firstNameOperator = 6 AND M.FirstName LIKE '%' + @firstName + '%') 
										OR (@firstNameOperator = 5 AND M.FirstName LIKE '%' + @firstName))
            AND M.IsActive=1
            
			DROP TABLE #TmpVehicle
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
					, NULL AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber  
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate
					, m.EffectiveDate   
					, '' AS VIN  
					, A.[StateProvinceID] 
					, M.MiddleName
					,A.CountryCode 
			FROM	#tmpPhone PH
			JOIN	Member M WITH (NOLOCK)  ON PH.RecordID = M.ID
			JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID    

			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN Program P WITH (NOLOCK) ON P.ID = M.ProgramID    
			JOIN @tmpForWhereClause TMP ON 1 = 1  
			WHERE M.IsPrimary =1
			AND   ((@memberID IS NULL)  OR (@memberID = M.ID))
			AND   ((@memberNumber IS NULL) OR (MS.MembershipNumber LIKE  '%' + @memberNumber + '%'))  
			AND   ((@ProgramID IS NULL) OR (P.ID = @ProgramID)) 
			AND   ((@stateID IS NULL) OR (A.StateProvinceID = @stateID)) 
			AND   ((@CountryID IS NULL) OR (A.CountryID = @CountryID)) 
			AND   ((@Zip IS NULL) OR (A.PostalCode LIKE '%' + @Zip +'%')) 
			AND   ((@City IS NULL) OR (A.City LIKE @City +'%')) 
			
			AND   ((@lastName IS NULL) OR (@lastNameOperator = 2 AND M.LastName = @lastName ) 
									   OR (@lastNameOperator = 4 AND M.LastName LIKE @lastName + '%')
									   OR (@lastNameOperator = 6 AND M.LastName LIKE '%' + @lastName + '%')
			                           OR (@lastNameOperator = 5 AND M.LastName LIKE '%' + @lastName))	
			
			AND   ((@firstName IS NULL) OR (@firstNameOperator = 2 AND M.FirstName = @firstName)
										OR (@firstNameOperator = 4 AND M.FirstName LIKE @firstName + '%')
										OR (@firstNameOperator = 6 AND M.FirstName LIKE '%' + @firstName + '%') 
										OR (@firstNameOperator = 5 AND M.FirstName LIKE '%' + @firstName))
			AND M.IsActive=1
		END
	END  -- End of phone number not null check

	-- DEBUG:   
	--SELECT COUNT(*) AS Filtered FROM #FinalResultsFiltered  

	-- Do all computations  
	INSERT INTO #FinalResultsFormatted  
	SELECT   F.MemberID  
	, F.MembershipID  
	, F.MemberNumber     
	--, REPLACE(RTRIM(COALESCE(F.LastName, '')   
	-- + COALESCE(' ' + F.Suffix, '')   
	-- + COALESCE(', ' + F.FirstName, '')), ' ', ' ')   
	-- + COALESCE(' ' + F.Prefix, '') AS Name  
	,REPLACE(RTRIM( 
	COALESCE(F.FirstName, '') + 
	COALESCE(' ' + left(F.MiddleName,1), '') + 
	COALESCE(' ' + F.LastName, '') +
	COALESCE(' ' + F.Suffix, '')
	), ' ', ' ') AS MemberName
	,(ISNULL(F.City,'') + ', ' + ISNULL(F.StateProvince,'') + ' ' + ISNULL(F.PostalCode,'') + ' ' + ISNULL(F.CountryCode,'')) AS [Address]     
	, COALESCE(F.HomePhoneNumber, F.WorkPhoneNumber, F.CellPhoneNumber, '') As PhoneNumber     
	, F.Program    
	,(SELECT COUNT(*) FROM [Case] WHERE MemberID = F.MemberID) AS POCount   
	-- Ignore time while comparing the dates here  
	--,CASE WHEN F.EffectiveDate <= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0) AND F.ExpirationDate >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)   
	--  THEN 'Active'   
	--  ELSE 'Inactive'   
	-- END 
	-- KB: Considering Effective and Expiration Dates to calculate member status
	,CASE WHEN ISNULL(F.EffectiveDate,@minDate) <= @now AND ISNULL(F.ExpirationDate,@minDate) >= @now
			THEN 'Active'
			ELSE 'Inactive'
	END AS MemberStatus
	, F.LastName  
	, F.FirstName  
	,CASE WHEN ISNULL(@vinParam,'') <> ''    
	THEN  F.VIN    
	ELSE  ''    
	END AS VIN     
	, F.StateProvinceID AS [State]  
	, F.PostalCode AS ZipCode  

	FROM #FinalResultsFiltered F  
	
	IF @phoneNumber IS NULL  
	BEGIN  

		INSERT INTO #FinalResultsSorted  
		SELECT  F.MemberID,  
		F.MembershipID,    
		F.MemberNumber,     
		F.Name,    
		F.[Address],    
		COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber,   
		F.Program,    
		F.POCount,    
		F.MemberStatus,    
		F.LastName,    
		F.FirstName ,    
		F.VIN ,    
		F.[State] ,    
		F.ZipCode   
		FROM  #FinalResultsFormatted F   
		LEFT JOIN PhoneEntity PH WITH (NOLOCK) ON PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PH.PhoneNumber)  
		LEFT JOIN PhoneEntity PW WITH (NOLOCK) ON PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PW.PhoneNumber)  
		LEFT JOIN PhoneEntity PC WITH (NOLOCK) ON PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PC.PhoneNumber) 

		ORDER BY     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'    
		THEN F.MembershipID END ASC,     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'    
		THEN F.MembershipID END DESC ,    

		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'    
		THEN F.MemberNumber END ASC,     
		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'    
		THEN F.MemberNumber END DESC ,    

		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'    
		THEN F.Name END ASC,     
		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'    
		THEN F.Name END DESC ,    

		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'    
		THEN F.Address END ASC,     
		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'    
		THEN F.Address END DESC ,    

		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC ,    

		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,    

		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'    
		THEN F.POCount END ASC,     
		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'    
		THEN F.POCount END DESC ,    

		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'ASC'    
		THEN F.MemberStatus END ASC,     
		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'DESC'    
		THEN F.MemberStatus END DESC    

	END  
	ELSE  

	BEGIN  
	-- DEBUG  :SELECT COUNT(*) FROM #tmpPhone  

		INSERT INTO #FinalResultsSorted  
		SELECT  F.MemberID,  
		 F.MembershipID,    
		 F.MemberNumber,     
		 F.Name,    
		 F.[Address],    
		 COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber,   
		 F.Program,    
		 F.POCount,    
		 F.MemberStatus,    
		 F.LastName,    
		 F.FirstName ,    
		F.VIN ,    
		F.[State] ,    
		F.ZipCode   
		FROM  #FinalResultsFormatted F   
		LEFT JOIN #tmpPhone PH WITH (NOLOCK) ON PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID 
		LEFT JOIN #tmpPhone PW WITH (NOLOCK) ON PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID 
		LEFT JOIN #tmpPhone PC WITH (NOLOCK) ON PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID 
		WHERE (PH.PhoneNumber = @phoneNumber OR PW.PhoneNumber = @phoneNumber OR PC.PhoneNumber=@phoneNumber)
		ORDER BY     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'    
		THEN F.MembershipID END ASC,     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'    
		THEN F.MembershipID END DESC ,    

		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'    
		THEN F.MemberNumber END ASC,     
		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'    
		THEN F.MemberNumber END DESC ,    

		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'    
		THEN F.Name END ASC,      
		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'    
		THEN F.Name END DESC ,    

		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'    
		THEN F.Address END ASC,     
		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'    
		THEN F.Address END DESC ,    

		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC ,    

		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,    

		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'    
		THEN F.POCount END ASC,     
		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'    
		THEN F.POCount END DESC ,    

		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'ASC'    
		THEN F.MemberStatus END ASC,     
		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'DESC'    
		THEN F.MemberStatus END DESC
		
		DROP TABLE #tmpPhone    
	END     
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
			F.VIN ORDER BY F.RowNum) AS sRowNumber	
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
			Program,    
			POCount,    
			MemberStatus,    
			VIN 
	)   
	SELECT	F.MemberID,  
			F.MembershipID,    
			F.MemberNumber,     
			F.Name,    
			F.[Address],    
			F.PhoneNumber,    
			F.Program,    
			F.POCount,    
			F.MemberStatus,    
			F.VIN  	
	FROM #FinalResultsSorted F
	WHERE ((@memberStatusValue IS NULL) OR ( F.MemberStatus IN (SELECT item FROM fnSplitString(@memberStatusValue,','))))
	ORDER BY 
	CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC,
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
	   F.Program,    
	   F.POCount,    
	   F.MemberStatus,    
	   F.VIN    
	   FROM    
	   #FinalResultsDistinct F WHERE RowNum BETWEEN @startInd AND @endInd    
	     
	DROP TABLE #FinalResultsFiltered  
	DROP TABLE #FinalResultsFormatted  
	DROP TABLE #FinalResultsSorted 
	DROP TABLE #FinalResultsDistinct



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
				,v.Name + CASE WHEN @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Direct Tow') AND vlp.ID IS NOT NULL AND vl.DealerNumber IS NOT NULL AND vl.PartsAndAccessoryCode IS NOT NULL 
					THEN ' (DT)' ELSE '' END VendorName
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
  ,v.Name +	
	CASE WHEN VPCNDP.ID IS NOT NULL THEN ' (P)' ELSE '' END  + 
	CASE WHEN VPFDT.ID IS NOT NULL AND vl.DealerNumber IS NOT NULL AND vl.PartsAndAccessoryCode IS NOT NULL 
			THEN ' (DT)' 
	ELSE '' END VendorName
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
LEFT JOIN   VendorLocation VL ON V.ID = VL.VendorID
Left Outer Join VendorProduct VPFDT ON VPFDT.VendorID = V.ID and VPFDT.ProductID = (Select ID from Product where Name = 'Ford Direct Tow') and VPFDT.IsActive = 1
Left Outer Join VendorProduct VPCNDP on VPCNDP.VendorID = V.ID and VPCNDP.ProductID = (Select ID from Product where Name = 'CoachNet Dealer Partner') and VPCNDP.IsActive = 1
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
