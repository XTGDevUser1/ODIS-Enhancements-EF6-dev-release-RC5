/*
	NP 02/03: Whatever the changes made to this SP has to be made to dms_Merge_Members_Search also
*/

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Members_Search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Members_Search] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter FirstNameOperator="4" FirstNameValue="jeevan"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
--EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter PhoneNumberOperator="2" PhoneNumberValue="8173078882"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
--EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter MemberNumberOperator="2" MemberNumberValue="1F6ED09370"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
-- EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter VINOperator="4" VINValue="K1234422323N1233"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3

CREATE PROCEDURE [dbo].[dms_Members_Search](   
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
	ClientMemberType nvarchar(200)  NULL 
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
	ZipCode nvarchar(50)  NULL,
	ClientMemberType nvarchar(200)  NULL
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
	ZipCode nvarchar(50)  NULL,
	ClientMemberType nvarchar(200)  NULL 
	)  
	--CREATE TABLE #FinalResultsDistinct(     
	--[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	--MemberID int  NULL ,   
	--MembershipID INT NULL,   
	--MemberNumber nvarchar(50)  NULL ,    
	--Name nvarchar(200)  NULL ,    
	--[Address] nvarchar(max)  NULL ,    
	--PhoneNumber nvarchar(50)  NULL , 
	--ProgramID INT NULL, -- KB: ADDED IDS   
	--Program nvarchar(50)  NULL ,    
	--POCount int  NULL ,    
	--MemberStatus nvarchar(50)  NULL ,    
	--LastName nvarchar(50)  NULL ,    
	--FirstName nvarchar(50)  NULL ,    
	--VIN nvarchar(50)  NULL ,  
	--VehicleID INT NULL, -- KB: Added VehicleID  
	--State nvarchar(50)  NULL ,    
	--ZipCode nvarchar(50)  NULL,
	--ClientMemberType nvarchar(200)  NULL
	--)  

	CREATE TABLE #SearchPrograms (
	ProgramID int, 
	ProgramName nvarchar(200),
	ClientID int
	)
	
	INSERT INTO #SearchPrograms (ProgramID, ProgramName, ClientID)
	SELECT ProgramID, ProgramName, ClientID
	--FROM [dbo].[fnc_GetMemberSearchPrograms](9) --@programID)
	FROM [dbo].[fnc_GetMemberSearchPrograms] (@programID)
	
	CREATE CLUSTERED INDEX IDX_SearchPrograms ON #SearchPrograms(ProgramID)
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
	
	
	--DECLARE @vinParam nvarchar(50)    
	--SELECT @vinParam = VINValue FROM @tmpForWhereClause    

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
	DECLARE @programCode NVARCHAR(50)
	DECLARE @firstName NVARCHAR(50)
	DECLARE @lastName NVARCHAR(50)
	DECLARE @state NVARCHAR(50)
	DECLARE @zip NVARCHAR(50)
	DECLARE @vinParam nvarchar(50) = NULL
	--DECLARE @phoneNumber NVARCHAR(100) = NULL

	SELECT	@memberID = MemberIDValue,
			@memberNumber = MemberNumberValue,
			@programCode = ProgramValue,
			@firstName = FirstNameValue,
			@lastName = LastNameValue,
			@state = StateValue,
			@zip = ZipCodeValue,
			--@PhoneNumber = REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumberValue,'(',''),' ',''),'-',''),')',''),  --Remove formatting
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
			SET @sql = @sql + ' ,NULL AS HomePhoneNumber'-- PH.PhoneNumber AS HomePhoneNumber 
			SET @sql = @sql + ' ,NULL AS WorkPhoneNumber' -- PW.PhoneNumber AS WorkPhoneNumber
			SET @sql = @sql + ' ,NULL AS CellPhoneNumber' -- PC.PhoneNumber AS CellPhoneNumber
			SET @sql = @sql + ' ,P.ID As ProgramID' -- KB: ADDED IDS
			SET @sql = @sql + ' ,P.[Description] AS Program'
			SET @sql = @sql + ' ,0 AS POCount' -- Computed later  
			SET @sql = @sql + ' ,m.ExpirationDate'  
			SET @sql = @sql + ' ,m.EffectiveDate'			
			SET @sql = @sql + ' ,(SELECT TOP 1 V.VIN FROM Vehicle V WHERE V.MembershipID = MS.ID'
					+ CASE WHEN @vinParam IS NOT NULL THEN ' AND V.VIN = @vinParam)' ELSE ')' END	
			SET @sql = @sql + ' ,(SELECT TOP 1 V.ID FROM Vehicle V WHERE V.MembershipID = MS.ID'
					+ CASE WHEN @vinParam IS NOT NULL THEN ' AND V.VIN = @vinParam)' ELSE ')' END	
			SET @sql = @sql + ' ,A.[StateProvinceID]'
			SET @sql = @sql + ' ,M.MiddleName'
			SET @sql = @sql + ' ,M.ClientMemberType'
			SET @sql = @sql + ' FROM Member M WITH (NOLOCK)'
			SET @sql = @sql + ' JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID'
			SET @sql = @sql + ' LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID =  '+ CONVERT(nvarchar(50), @memberEntityID) 
			SET @sql = @sql + ' JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID '   
			SET @sql = @sql + ' JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID'
			SET @sql = @sql + ' WHERE  ( @memberID IS NULL  OR @memberID = M.ID )'	
			
			
			IF @memberNumber IS NOT NULL
			SET @sql = @sql + ' AND (MS.MembershipNumber LIKE @memberNumber + char(37) OR MS.AltMembershipNumber LIKE  @memberNumber + char(37))'			
			
					
			IF @vinParam IS NOT NULL 
			SET @sql = @sql + ' AND MS.ID IN (SELECT v1.MembershipID FROM Vehicle v1 WHERE v1.VIN = @vinParam)'
	
			IF @phoneNumber IS NOT NULL
			SET @sql = @sql + ' AND M.ID IN (SELECT PH.RecordID FROM PhoneEntity PH WITH (NOLOCK) WHERE PH.EntityID = ' +				CONVERT(nvarchar(50), @memberEntityID) + ' AND PH.PhoneNumber = @phoneNumber)'	
			 
			IF @Zip IS NOT NULL
			SET @sql = @sql + ' AND A.PostalCode LIKE char(37) + @Zip + char(37)' 
			
			IF @programCode IS NOT NULL
			SET @sql = @sql + ' AND P.Code = @ProgramCode'
			
			IF @lastName IS NOT NULL
			SET @sql = @sql + ' AND M.LastName LIKE @lastName + char(37)'	
			
			IF @firstName IS NOT NULL
			SET @sql = @sql + ' AND M.FirstName LIKE @firstName + char(37)'
			
			IF @state IS NOT NULL
			SET @sql = @sql + ' AND A.StateProvinceID = @state'			
			
			
			SET @sql = @sql + '	AND M.IsActive=1'
			SET @sql = @sql + ' OPTION (RECOMPILE)'
			
			INSERT INTO #FinalResultsFiltered
			EXEC sp_executesql @sql, N'@memberID INT,@memberNumber nvarchar(50), @vinParam nvarchar(50),@phoneNumber nvarchar(20), @Zip nvarchar(50), @ProgramCode nvarchar(50),   @lastName nvarchar(50), @firstName nvarchar(50), @state INT'
				, @memberID, @memberNumber, @vinParam, @PhoneNumber, @Zip, @programCode, @lastName, @firstName, @state		
			  
	
		
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
	,(ISNULL(F.City,'') + ',' + ISNULL(F.StateProvince,'') + ' ' + ISNULL(F.PostalCode,'')) AS [Address]     
	, COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber 
	, F.ProgramID -- KB: ADDED IDS    
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
	, F.VIN 
	, F.VehicleID  
	, F.StateProvinceID AS [State]  
	, F.PostalCode AS ZipCode  
	, F.ClientMemberType
	FROM #FinalResultsFiltered F  
	LEFT JOIN PhoneEntity PH WITH (NOLOCK) ON PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR PH.PhoneNumber like CHAR(37) + @phoneNumber + CHAR(37))  
		LEFT JOIN PhoneEntity PW WITH (NOLOCK) ON PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR PW.PhoneNumber like CHAR(37) + @phoneNumber + CHAR(37))   
		LEFT JOIN PhoneEntity PC WITH (NOLOCK) ON PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR PC.PhoneNumber like CHAR(37) + @phoneNumber + CHAR(37))

	
		INSERT INTO #FinalResultsSorted  
		SELECT  F.MemberID,  
		F.MembershipID,    
		F.MemberNumber,     
		F.Name,    
		F.[Address],    
		F.PhoneNumber, 
		F.ProgramID, -- KB: ADDED IDS     
		F.Program,    
		F.POCount,    
		F.MemberStatus,    
		F.LastName,    
		F.FirstName ,    
		F.VIN ,
		F.VehicleID,    
		F.[State] ,    
		F.ZipCode ,
		F.ClientMemberType
		FROM  #FinalResultsFormatted F   
		
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
	   F.ProgramID, -- KB: ADDED IDS      
	   F.Program,    
	   F.POCount,    
	   F.MemberStatus,    
	   F.VIN,
	   F.VehicleID ,
	   F.ClientMemberType
	   FROM    
	   #FinalResultsSorted F WHERE RowNum BETWEEN @startInd AND @endInd    
	     
	DROP TABLE #FinalResultsFiltered  
	DROP TABLE #FinalResultsFormatted  
	DROP TABLE #FinalResultsSorted 
	--DROP TABLE #FinalResultsDistinct


END
GO

