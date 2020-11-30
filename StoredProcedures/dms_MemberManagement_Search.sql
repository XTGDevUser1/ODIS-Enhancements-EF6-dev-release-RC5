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
	
	--CREATE TABLE #FinalResultsDistinct(     
	--[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	--MemberID int  NULL ,   
	--MembershipID INT NULL,   
	--MemberNumber nvarchar(50)  NULL ,    
	--Name nvarchar(200)  NULL ,    
	--[Address] nvarchar(max)  NULL ,    
	--PhoneNumber nvarchar(50)  NULL ,    
	--Program nvarchar(50)  NULL ,    
	--POCount int  NULL ,    
	--MemberStatus nvarchar(50)  NULL ,    
	--LastName nvarchar(50)  NULL ,    
	--FirstName nvarchar(50)  NULL ,    
	--VIN nvarchar(50)  NULL ,    
	--State nvarchar(50)  NULL ,    
	--ZipCode nvarchar(50)  NULL     
	--)  

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
	
	DECLARE @memberEntityID INT ,
		@HomeAddressTypeID INT
	SELECT @memberEntityID = ID FROM Entity WHERE Name = 'Member'  
	SELECT @HomeAddressTypeID = ID FROM AddressType WHERE Name = 'Home'
 
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
 	DECLARE @vinParam nvarchar(50) = NULL   
	DECLARE @phoneNumber NVARCHAR(100) = NULL

	SELECT	@memberID = MemberIDValue,
			@memberNumber = MemberNumberValue,
			@ProgramID = CASE WHEN ProgramIDValue = '-1' THEN NULL ELSE ProgramIDValue END,
			@ClientID = ClientIDValue,
			@firstName = FirstNameValue,
			@lastName = LastNameValue,
			@stateID =    StateProvinceIDValue,
			@CountryID =  CountryIDValue,
			@Zip = PostalCodeValue,
			@City = CityValue,
			@lastNameOperator = LastNameOperator,
			@firstNameOperator = FirstNameOperator,
			@memberStatusValue = MemberStatusValue,
			@PhoneNumber = REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumberValue,'(',''),' ',''),'-',''),')',''),  --Remove formatting
			@VinParam = VinValue
	FROM	@tmpForWhereClause

		
	SET FMTONLY OFF;  
	
	Declare @sql nvarchar(max) = ''
	
	SET @sql =        'SELECT DISTINCT TOP 1000'
	SET @sql = @sql + '  M.id AS MemberID'  
	SET @sql = @sql + ' ,M.MembershipID'
	SET @sql = @sql + ' ,CASE WHEN MS.MembershipNumber IS NULL THEN ''Ref#: '' + MS.ClientReferenceNUmber ELSE MS.MembershipNumber END AS MemberNumber'
	SET @sql = @sql + ' ,M.FirstName'
	SET @sql = @sql + ' ,M.LastName'
	SET @sql = @sql + ' ,M.Suffix'
	SET @sql = @sql + ' ,M.Prefix'     
	SET @sql = @sql + ' ,A.City' 
	SET @sql = @sql + ' ,A.StateProvince' 
	SET @sql = @sql + ' ,A.PostalCode' 
	SET @sql = @sql + ' ,NULL' -- HomePhoneNumber 
	SET @sql = @sql + ' ,NULL' -- WorkPhoneNumber  
	SET @sql = @sql + ' ,NULL' -- CellPhoneNumber 
	SET @sql = @sql + ' ,P.[Description]' --  Program    
	SET @sql = @sql + ' ,0 ' -- AS POCount   
	SET @sql = @sql + ' ,m.ExpirationDate'  
	SET @sql = @sql + ' ,m.EffectiveDate'
	SET @sql = @sql + ' ,(SELECT TOP 1 V.VIN FROM Vehicle V WHERE V.MembershipID = MS.ID'
					+ CASE WHEN @vinParam IS NOT NULL THEN ' AND V.VIN = @vinParam)' ELSE ')' END
	SET @sql = @sql + ' ,A.[StateProvinceID]'
	SET @sql = @sql + ' ,M.MiddleName'
	SET @sql = @sql + ' ,A.CountryCode'
	SET @sql = @sql + ' FROM Member M WITH (NOLOCK)'
	SET @sql = @sql + ' JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID'
	SET @sql = @sql + ' JOIN Program P WITH (NOLOCK) ON P.ID = M.ProgramID'
	SET @sql = @sql + ' JOIN Client C WITH (NOLOCK) ON P.ClientID = C.ID'
	SET @sql = @sql + ' LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = ' + CONVERT(nvarchar(50), @memberEntityID) + ' and A.AddressTypeID = '  + CONVERT(nvarchar(50), @HomeAddressTypeID)		

	SET @sql = @sql + ' WHERE  M.IsPrimary =1'
	
	IF @memberNumber IS NOT NULL
	SET @sql = @sql + ' AND (MS.MembershipNumber LIKE char(37) + @memberNumber + char(37) OR MS.AltMembershipNumber LIKE  char(37) + @memberNumber + char(37))'  
	
	IF @vinParam IS NOT NULL 
	SET @sql = @sql + ' AND MS.ID IN (SELECT v1.MembershipID FROM Vehicle v1 WHERE v1.VIN = @vinParam)'
	
	IF @phoneNumber IS NOT NULL
	SET @sql = @sql + ' AND M.ID IN (SELECT PH.RecordID FROM PhoneEntity PH WITH (NOLOCK) WHERE PH.EntityID = ' + CONVERT(nvarchar(50), @memberEntityID) + ' AND PH.PhoneNumber LIKE char(37) + @phoneNumber + char(37))'

	IF @ClientID IS NOT NULL
	SET @sql = @sql + ' AND C.ID = @ClientID'  

	IF @ProgramID IS NOT NULL
	SET @sql = @sql + ' AND P.ID = @ProgramID' 
		
	IF @StateID IS NOT NULL
	SET @sql = @sql + ' AND A.StateProvinceID = @StateID'  
	
	IF @CountryID IS NOT NULL
	SET @sql = @sql + ' AND A.CountryID = @CountryID' 
	
	IF @Zip IS NOT NULL
	SET @sql = @sql + ' AND A.PostalCode LIKE char(37) + @Zip + char(37)' 
	
	IF @City IS NOT NULL
	SET @sql = @sql + ' AND A.PostalCode LIKE @City + char(37)' 
	
	IF @lastName IS NOT NULL AND @lastNameOperator = 2	
	SET @sql = @sql + ' AND M.LastName = @LastName'  
	
	IF @lastName IS NOT NULL AND @lastNameOperator IN (4,5,6)
	SET @sql = @sql + ' AND M.LastName Like ' 
					+ CASE WHEN @lastNameOperator IN (5,6) THEN 'char(37)+' ELSE '' END
					+ '@LastName' 
					+ CASE WHEN @lastNameOperator IN (4,6) THEN '+char(37)' ELSE '' END
					--+ ''''
					
	IF @firstName IS NOT NULL AND @firstNameOperator = 2	
	SET @sql = @sql + ' AND M.FirstName = @FirstName'  
	
	IF @firstName IS NOT NULL AND @firstNameOperator IN (4,5,6)
	SET @sql = @sql + ' AND M.FirstName Like ' 
					+ CASE WHEN @firstNameOperator IN (5,6) THEN 'char(37)+' ELSE '' END
					+ ' @FirstName ' 
					+ CASE WHEN @firstNameOperator IN (4,6) THEN '+char(37)' ELSE '' END
					--+ ''''
					
	IF @memberStatusValue IS NOT NULL AND EXISTS (SELECT item FROM fnSplitString(@memberStatusValue,',') WHERE item = 'Active') AND NOT EXISTS (SELECT item FROM fnSplitString(@memberStatusValue,',') WHERE item = 'Inactive') 
	SET @sql = @sql + ' AND M.EffectiveDate <= ''' + CONVERT(nvarchar(50),@now,101) + ''' AND ISNULL(M.ExpirationDate,''' + CONVERT(nvarchar(50),@now,101) + ''') >= ''' + CONVERT(nvarchar(50),@now,101) + '''' 
					
	IF @memberStatusValue IS NOT NULL AND EXISTS (SELECT item FROM fnSplitString(@memberStatusValue,',') WHERE item = 'Inactive') AND NOT EXISTS (SELECT item FROM fnSplitString(@memberStatusValue,',') WHERE item = 'Active') 
	SET @sql = @sql + ' AND (M.EffectiveDate IS NULL OR M.EffectiveDate > ''' + CONVERT(nvarchar(50),@now,101) + ''' OR ISNULL(M.ExpirationDate,''' + CONVERT(nvarchar(50),@now,101) + ''') < ''' + CONVERT(nvarchar(50),@now,101) + ''')' 

	SET @sql = @sql + '	AND M.IsActive=1'
	SET @sql = @sql + ' OPTION (RECOMPILE)'
		
	----DEBUG:   
	PRINT @Sql 
	
    INSERT INTO #FinalResultsFiltered 
	EXEC sp_executesql @sql, N'@memberNumber nvarchar(50), @ClientID INT, @ProgramID INT, @StateID INT, @CountryID INT, @Zip nvarchar(50), @City nvarchar(50), @LastName nvarchar(50), @FirstName nvarchar(50), @vinParam nvarchar(20), @PhoneNumber nvarchar(20)'
				, @memberNumber, @ClientID, @ProgramID, @StateID, @CountryID, @Zip, @City, @LastName, @FirstName, @vinParam, @PhoneNumber
	
	----DEBUG:   
    --Select * from #FinalResultsFiltered
    
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
		,(ISNULL(F.City,'') + ', ' + ISNULL(F.StateProvince,'') + ' ' + ISNULL(F.PostalCode,'') + ' ' + ISNULL(F.CountryCode,'')) AS [Address]     
		, COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber   
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
	LEFT JOIN PhoneEntity PH WITH (NOLOCK) ON PH.EntityID = @memberEntityID AND PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND ( @phoneNumber IS NULL OR PH.PhoneNumber like CHAR(37) + @phoneNumber + CHAR(37))  
	LEFT JOIN PhoneEntity PW WITH (NOLOCK) ON PW.EntityID = @memberEntityID AND PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND ( @phoneNumber IS NULL OR PW.PhoneNumber like CHAR(37) + @phoneNumber + CHAR(37))  
	LEFT JOIN PhoneEntity PC WITH (NOLOCK) ON PC.EntityID = @memberEntityID AND PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND ( @phoneNumber IS NULL OR PC.PhoneNumber like CHAR(37) + @phoneNumber + CHAR(37)) 
	
	
	INSERT INTO #FinalResultsSorted  
	SELECT  F.MemberID,  
		F.MembershipID,    
		F.MemberNumber,     
		F.Name,    
		F.[Address],    
		F.PhoneNumber,
		F.Program,    
		F.POCount,    
		F.MemberStatus,    
		F.LastName,    
		F.FirstName ,    
		F.VIN ,    
		F.[State] ,    
		F.ZipCode   
	FROM  #FinalResultsFormatted F   
	---- Have to apply this filter here since it is derived in #FinalResultsFormatted query
	--WHERE ((@memberStatusValue IS NULL) OR ( F.MemberStatus IN (SELECT item FROM fnSplitString(@memberStatusValue,','))))

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

	---- DEBUG:
	--SELECT * FROM #FinalResultsSorted

--	-- Let's delete duplicates from #FinalResultsSorted and then insert into Distinct.
	
--	;WITH wSorted 
--	AS
--	(
--		SELECT ROW_NUMBER() OVER (PARTITION BY 
--			F.MemberID,  
--			F.MembershipID,    
--			F.MemberNumber,     
--			F.Name,    
--			F.[Address],    
--			F.PhoneNumber,    
--			F.Program,    
--			F.POCount,    
--			F.MemberStatus,    
--			F.VIN ORDER BY F.RowNum) AS sRowNumber	
--		FROM #FinalResultsSorted F
--	)
	
--	DELETE FROM wSorted WHERE sRowNumber > 1
	
--	INSERT INTO #FinalResultsDistinct(
--			MemberID,  
--			MembershipID,    
--			MemberNumber,     
--			Name,    
--			[Address],    
--			PhoneNumber,    
--			Program,    
--			POCount,    
--			MemberStatus,    
--			VIN 
--	)   
--	SELECT	F.MemberID,  
--			F.MembershipID,    
--			F.MemberNumber,     
--			F.Name,    
--			F.[Address],    
--			F.PhoneNumber,    
--			F.Program,    
--			F.POCount,    
--			F.MemberStatus,    
--			F.VIN  	
--	FROM #FinalResultsSorted F
--	WHERE ((@memberStatusValue IS NULL) OR ( F.MemberStatus IN (SELECT item FROM fnSplitString(@memberStatusValue,','))))
--	ORDER BY 
--	CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
--		THEN F.PhoneNumber END ASC,     
--		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
--		THEN F.PhoneNumber END DESC,
--		F.RowNum  
		

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
	FROM #FinalResultsSorted F 
	WHERE RowNum BETWEEN @startInd AND @endInd    

	     
	DROP TABLE #FinalResultsFiltered  
	DROP TABLE #FinalResultsFormatted  
	DROP TABLE #FinalResultsSorted 
	--DROP TABLE #FinalResultsDistinct

END
