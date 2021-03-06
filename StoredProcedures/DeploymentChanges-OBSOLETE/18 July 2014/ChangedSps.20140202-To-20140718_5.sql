IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ManualNotification_Event_Log]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ManualNotification_Event_Log] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_ManualNotification_Event_Log] 'SSMS','SSMS','Manual notification','kbanda',1,'AE05306D-492D-4944-B8BA-8E90BE11F393,BEB5FA18-50CE-499D-BB62-FFB9585242AB'
CREATE PROCEDURE [dbo].[dms_ManualNotification_Event_Log](
	@eventSource NVARCHAR(255) = NULL,
	@sessionID NVARCHAR(255) = NULL,
	@message NVARCHAR(MAX) = NULL,
	@createBy NVARCHAR(50) = NULL,
	@recipientTypeID INT = NULL,
	@autoCloseDelay INT = 0,
	@toUserOrRoleIDs NVARCHAR(MAX) = NULL -- CSV of ASPNET_UserIds / RoleIds
)
AS
BEGIN
 
	DECLARE @tmpUsers TABLE
	(
		ID INT IDENTITY(1,1),
		UserID INT NULL,
		aspnet_UserID UNIQUEIDENTIFIER NULL
	)

	DECLARE @eventLogID INT,
			@idx INT = 1,
			@maxRows INT = 0,
			@userEntityID INT

	SET @userEntityID = (SELECT ID FROM Entity WHERE Name = 'User')

	SET @message =	REPLACE( REPLACE( REPLACE(REPLACE(@message,'&','&amp;'),'<','&lt;'), '>','&gt;'),'''','&quot;')

	IF ( @recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'User') )
	BEGIN
		
		INSERT INTO @tmpUsers (UserID, aspnet_UserID)
		SELECT	DISTINCT U.ID,
				AU.UserId
		FROM	[dbo].[fnSplitString](@toUserOrRoleIDs,',') T
		JOIN	aspnet_Users AU WITH (NOLOCK) ON T.item = AU.UserId
		JOIN	[User] U WITH (NOLOCK) ON  U.aspnet_UserID = AU.UserId
		

	END
	ELSE IF (@recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'Role'))
	BEGIN

		INSERT INTO @tmpUsers (UserID, aspnet_UserID)
		SELECT	DISTINCT U.ID,
				AU.UserId
		FROM	[dbo].[fnSplitString](@toUserOrRoleIDs,',') T
		JOIN	aspnet_UsersInRoles UIR WITH (NOLOCK) ON T.item = UIR.RoleId
		JOIN	aspnet_Users AU WITH (NOLOCK) ON UIR.UserId = AU.UserId
		JOIN	[User] U WITH (NOLOCK) ON  U.aspnet_UserID = AU.UserId

	END


	INSERT INTO EventLog (	EventID,
							SessionID,
							[Source],
							[Description],
							Data,
							NotificationQueueDate,
							CreateDate,
							CreateBy
						)
	SELECT	(SELECT ID FROM [Event] WHERE Name = 'ManualNotification'),
			@sessionID,
			@eventSource,
			(SELECT [Description] FROM [Event] WHERE Name = 'ManualNotification'),
			'<MessageData><SentFrom>' + ISNULL(@createBy,'') + '</SentFrom><MessageText>' + ISNULL(@message,'') + '</MessageText><AutoClose>' + CONVERT(NVARCHAR(100),ISNULL(@autoCloseDelay,0))  + '</AutoClose></MessageData>',
			NULL,
			GETDATE(),
			@createBy

	SET @eventLogID = SCOPE_IDENTITY()
	SELECT @maxRows = MAX(ID) FROM @tmpUsers

	-- Create EventLogLinks
	WHILE (@idx <= @maxRows)
	BEGIN

		INSERT INTO EventLogLink(	EntityID,
									EventLogID,
									RecordID
								)
		SELECT	@userEntityID,
				@eventLogID,
				T.UserID
		FROM	@tmpUsers T WHERE T.ID = @idx

		SET @idx = @idx + 1

	END

END
GO


GO
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

GO

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

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_NightlyMaintenance]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_NightlyMaintenance] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[dms_NightlyMaintenance] 
AS
BEGIN
	SET NOCOUNT ON;

	EXEC dbo.dms_Vendor_UpdateAdminisrativeRating
	EXEC dbo.dms_Vendor_UpdateProductRating
	EXEC dbo.dms_Claim_FordQFC_Create
END

GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Notification_History_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Notification_History_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Notification_History_Get] 'demouser'
CREATE PROCEDURE [dbo].[dms_Notification_History_Get](
@userName NVARCHAR(100)
)
AS
BEGIN

	DECLARE @notificationHistoryDisplayHours INT = 48 -- Default value is set to 48.

	SELECT @notificationHistoryDisplayHours = CONVERT(INT,Value) FROM ApplicationConfiguration WHERE Name = 'NotificationHistoryDisplayHours'
	

	SELECT	CL.*
	FROM	CommunicationLog CL WITH (NOLOCK)
	JOIN	ContactMethod CM WITH (NOLOCK) ON CL.ContactMethodID = CM.ID
	WHERE	CL.NotificationRecipient = @userName
	AND		CM.Name = 'DesktopNotification'
	AND		DATEDIFF(HH,CL.CreateDate,GETDATE()) <= @notificationHistoryDisplayHours
	AND		CL.Status = 'SUCCESS'
	ORDER BY CL.CreateDate DESC

END
GO
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_productcategoryquestions_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_productcategoryquestions_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_productcategoryquestions_get] 3,1,1,NULL
 
CREATE PROCEDURE [dbo].[dms_productcategoryquestions_get]( 
   @ProgramID int,   
   @VehicleTypeID int = NULL,
   @VehicleCategoryID int = NULL,
   @serviceRequestID INT = NULL
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
  Sequence int,
  AnswerValue NVARCHAR(MAX) NULL, -- Answer provided for this question
  IsEnabled BIT,
  VehicleCategoryID INT NULL
)
DECLARE @relevantProductCategories TABLE
(
	ProductCategoryID INT,
	Sequence INT NULL
)

--DEBUG : FOR EF
IF(@ProgramID IS NULL)
BEGIN
	SELECT * FROM @Questions
	RETURN;
END
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

IF ( (SELECT COUNT(*) FROM @relevantProductCategories R,ProductCategory PC WHERE PC.ID = R.ProductCategoryID AND PC.Name like 'Tow%') = 0)
BEGIN
	INSERT INTO @relevantProductCategories
	SELECT	PC.ID,
			PC.Sequence
	FROM ProductCategory PC WHERE Name like 'Tow%' AND PC.IsActive = 1
END

IF ( (SELECT COUNT(*) FROM @relevantProductCategories R,ProductCategory PC WHERE PC.ID = R.ProductCategoryID AND PC.Name like 'Tow%') = 0)
BEGIN
	INSERT INTO @relevantProductCategories
	SELECT	PC.ID,
			PC.Sequence
	FROM ProductCategory PC  WHERE Name like 'Tow%'	AND PC.IsActive = 1
		  
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
  PCQ.Sequence,
  NULL,
  CASE WHEN (PCV.VehicleCategoryID IS NULL OR PCV.VehicleCategoryID = @VehicleCategoryID)
		THEN CAST (1 AS BIT)
		ELSE CAST (0 AS BIT)
  END AS IsEnabled,
  PCV.VehicleCategoryID
  FROM [dbo].ProductCategoryQuestion PCQ
  /*** KB: The following join was original code from Martex
  JOIN ProductCategoryQuestionVehicleType PCV ON PCV.ProductCategoryQuestionID = PCQ.ID 
  **/
  -- KB: Changed inner join to Left join.
  --RA: Changed to check IS NULL for VehicleType and added VehicleCategory back in
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
  PCQ.Sequence,
  NULL,
  CASE WHEN (PCP.VehicleCategoryID IS NULL OR PCP.VehicleCategoryID = @VehicleCategoryID)
		THEN CAST (1 AS BIT)
		ELSE CAST (0 AS BIT)
  END AS IsEnabled,
  PCP.VehicleCategoryID 
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

	IF @serviceRequestID IS NULL
	BEGIN  
		SELECT * FROM @Questions
		WHERE  ProductCategoryName NOT IN ('Repair','Billing')
		ORDER BY ProductCategoryID,ProductCategoryQuestionID, Sequence
	END
	ELSE
	BEGIN
		SELECT	
				Q.ProductCategoryID,
				Q.ProductCategoryName,
				Q.ProductCategoryQuestionID, 
				Q.QuestionText,
				Q.ControlType,
				Q.DataType,
				Q.HelpText,
				Q.IsRequired,
				Q.SubQuestionID,
				Q.RelatedAnswer,
				Q.Sequence,
				SR.Answer AS AnswerValue,
				Q.IsEnabled,
				Q.VehicleCategoryID
		FROM @Questions Q 
		LEFT JOIN ServiceRequestDetail SR ON Q.ProductCategoryQuestionID = SR.ProductCategoryQuestionID 
						AND SR.ServiceRequestID = @serviceRequestID
		WHERE  ProductCategoryName NOT IN ('Repair','Billing')
		ORDER BY ProductCategoryID,ProductCategoryQuestionID, Q.Sequence
				
	
	END
	


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
 WHERE id = object_id(N'[dbo].[dms_Products_For_ProductCategory_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Products_For_ProductCategory_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_Products_For_ProductCategory_List_Get]
 CREATE PROCEDURE [dbo].[dms_Products_For_ProductCategory_List_Get]( 
   @productCategoryID INT = NULL 
 ) 
 AS 
 BEGIN 

SELECT 
	  p.ID
	, p.Name
	, p.IsActive
FROM Product p 
WHERE (p.ProductCategoryid = @ProductCategoryID OR @ProductCategoryID IS NULL)
AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')
AND p.ProductSubTypeID IN (SELECT ID FROM ProductSubType WHERE Name IN ('PrimaryService','SecondaryService'))
AND p.IsActive = 1 AND p.Name IS NOT NULL
 

 
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
 -- EXEC dms_Program_Coverage_Information_List_Get @programID =100
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
LimitValue nvarchar(50) NULL
)
DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Name nvarchar(50)  NULL ,
	Limit nvarchar(50)  NULL ,
	Vehicle nvarchar(50)  NULL 
) 

DECLARE @tmpFinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Name nvarchar(50)  NULL ,
	Limit nvarchar(50)  NULL ,
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
, max(CASE
WHEN pp.ServiceCoverageLimit > 0 THEN '$' + CONVERT(NVARCHAR(10),CONVERT(NUMERIC(10),pp.ServiceCoverageLimit))
WHEN pp.ServiceCoverageLimit = 0 AND pp.IsServiceCoverageBestValue = 1 THEN 'Best Value'
WHEN pp.ServiceCoverageLimit = 0 AND pp.IsServiceCoverageBestValue = 0 THEN '$0'
WHEN pp.ServiceCoverageLimit >= 0 AND pp.IsReimbursementOnly = 1 THEN '$' + CONVERT(NVARCHAR(10),CONVERT(NUMERIC(10),pp.ServiceCoverageLimit)) + '-' + 'Reimbursement'
WHEN pp.ServiceCoverageLimit = 0 AND pp.IsReimbursementOnly = 0 THEN 'Assit Only'
ELSE ''
END) +
coalesce(max(CASE WHEN convert(nvarchar(3),pp.ServiceMileageLimit) > 0 THEN ' - ' + convert(nvarchar(3),pp.ServiceMileageLimit) + ' miles' ELSE '' END), '')
AS Limit
, max(CASE WHEN RIGHT(p.Name,2) = 'LD' THEN 'LD' ELSE '' END) +
coalesce('-' + max(CASE WHEN RIGHT(p.Name,2) = 'MD' THEN 'MD' END),'') +
coalesce('-'+max(CASE WHEN RIGHT(p.Name,2) = 'HD' THEN 'HD' END),'') AS Vehicle
FROM	ProgramProduct pp
JOIN	Product p (NOLOCK) ON p.id = pp.ProductID
JOIN	ProductCategory pc (NOLOCK) ON pc.id = p.productcategoryid
WHERE	pc.Name NOT IN ('Info','Repair','Billing')
AND	 pp.ProgramID = @ProgramID
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

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_DeleteDataItem]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_DeleteDataItem] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Program_Management_DeleteDataItem 19
 CREATE PROCEDURE [dbo].[dms_Program_Management_DeleteDataItem]( 
 @id INT 
 )
 AS
 BEGIN
	DELETE FROM ProgramDataItemValue WHERE ProgramDataItemID = @id
	DELETE FROM ProgramDataItemValueEntity WHERE ProgramDataItemID = @id
	DELETE FROM ProgramDataItem WHERE ID = @id
 END
 
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_DeleteProgramServiceEventLimit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_DeleteProgramServiceEventLimit] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Program_Management_DeleteDataItem 19
 CREATE PROCEDURE [dbo].[dms_Program_Management_DeleteProgramServiceEventLimit]( 
 @id INT 
 )
 AS
 BEGIN
	DELETE FROM ProgramServiceEventLimit WHERE ID = @id
 END
 
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_DeleteServiceCategoryInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_DeleteServiceCategoryInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Program_Management_DeleteServiceCategoryInformation 34
 CREATE PROCEDURE [dbo].[dms_Program_Management_DeleteServiceCategoryInformation]( 
 @id INT 
 )
 AS
 BEGIN
	DELETE FROM ProgramProductCategory WHERE ID = @id
 END
 
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_DeleteServiceInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_DeleteServiceInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Program_Management_DeleteServiceInformation 34
 CREATE PROCEDURE [dbo].[dms_Program_Management_DeleteServiceInformation]( 
 @id INT 
 )
 AS
 BEGIN
	DELETE FROM ProgramProduct WHERE ID = @id
 END
 
GO

GO

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

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_GetProgramConfiguration]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_GetProgramConfiguration] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_GetProgramConfiguration]( 
 @programConfigurationId INT
 )
 AS
 BEGIN
 SELECT 
	    ConfigurationTypeID,
	    ConfigurationCategoryID,
	    ControlTypeID,
	    DataTypeID,
	    Name,
	    Value,
	    IsActive,
	    Sequence,
	    CreateDate,
	    CreateBy,
	    ModifyDate,
	    ModifyBy
 FROM ProgramConfiguration
 WHERE ID=@programConfigurationId
 END
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_GetProgramServiceCategory]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_GetProgramServiceCategory] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Program_Management_GetProgramServiceCategory 100
 CREATE PROCEDURE [dbo].[dms_Program_Management_GetProgramServiceCategory]( 
 @programServiceCategoryId INT
 )
 AS
 BEGIN
 DECLARE @maxSequnceNumber INT =0
 DECLARE @bitIsActive BIT = 0
 SET @maxSequnceNumber = (SELECT MAX(Sequence) FROM ProgramProductCategory)
 IF EXISTS (SELECT * FROM ProgramProductCategory WHERE ID = @programServiceCategoryId)
 BEGIN
	 SELECT 
		PPC.ID,
		PPC.ProductCategoryID,
		PPC.ProgramID,
		PPC.VehicleCategoryID,
		PPC.VehicleTypeID,
		PPC.Sequence,
		PPC.IsActive,
		@maxSequnceNumber+1 AS MaxSequnceNumber
	
FROM ProgramProductCategory ppc
WHERE PPC.ID = @programServiceCategoryId
END
ELSE
BEGIN 
	SELECT
		0 AS ID,
		1 AS ProductCategoryID,
		0 AS ProgramID,
		null AS VehicleCategoryID,
		null AS VehicleTypeID,
		null AS Sequence,
		@bitIsActive AS IsActive,
		@maxSequnceNumber+1 AS MaxSequnceNumber
		
END
 END
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_GetProgramVehicleTypeDetails]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_GetProgramVehicleTypeDetails] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_GetProgramVehicleTypeDetails]( 
 @programVehicleTypeId INT
 )
 AS
 BEGIN
	SET FMTONLY OFF
 	SET NOCOUNT ON
 	
   SELECT ID,
          VehicleTypeID,
          MaxAllowed,
          IsActive
   FROM ProgramVehicleType
   WHERE ID=@programVehicleTypeId
 END
GO

GO

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
			 , P.IsWebRegistrationEnabled
			 , P.CreateBy
			 , P.CreateDate
			 , P.ModifyBy
			 , P.ModifyDate
			 , '' AS PageMode
	FROM       Program P (NOLOCK)
	JOIN       Client C (NOLOCK) ON C.ID = P.ClientID
	LEFT JOIN  Program PP (NOLOCK) ON PP.ID = P.ParentProgramID
	WHERE      P.ID = @ProgramID
END


GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Program_Management_List_Get @whereClauseXML='<ROW><Filter ClientID="1" ProgramID="5" Name="tes" NameOperator="Conains"></Filter></ROW>'
 CREATE PROCEDURE [dbo].[dms_Program_Management_List_Get]( 
   @whereClauseXML XML = NULL 
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
Number=""
Name=""
NameOperator=""
ClientID=""
ProgramID=""
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
Number NVARCHAR(50) NULL,
Name NVARCHAR(50) NULL,
NameOperator NVARCHAR(50) NULL,
ClientID int NULL,
ProgramID INT NULL
)

INSERT INTO @tmpForWhereClause
SELECT  
	T.c.value('@Number','NVARCHAR(50)'),
	T.c.value('@Name','NVARCHAR(100)'),
	T.c.value('@NameOperator','NVARCHAR(50)'),
	T.c.value('@ClientID','INT'),
	T.c.value('@ProgramID','INT')
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @Number			NVARCHAR(50)= NULL,
@Name			NVARCHAR(100)= NULL,
@NameOperator	NVARCHAR(50)= NULL,
@ClientID		INT= NULL,
@ProgramID		INT= NULL

SELECT 
		@Number					= Number				
		,@NameOperator			= NameOperator				
		,@ClientID				= ClientID			
		,@ProgramID			    = ProgramID
		,@Name		            = Name
			
FROM @tmpForWhereClause

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

PRINT @NameOperator
PRINT 'nAME:'+@Name
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
FROM @FinalResults_Temp T
WHERE 
(ISNULL(LEN(@Number),0) = 0 OR (@Number = CONVERT(NVARCHAR(100),T.ProgramID)  ))
AND (ISNULL(@ClientID,0) = 0 OR @ClientID = 0 OR (T.ClientID = @ClientID  ))
AND (ISNULL(@ProgramID,0) = 0 OR @ProgramID = T.ProgramID OR (T.ParentProgramID = @ProgramID  ))
AND	(ISNULL(LEN(@Name),0) = 0 OR  (
									(@NameOperator = 'Is equal to' AND @Name = T.ProgramName)
									OR
									(@NameOperator = 'Begins with' AND T.ProgramName LIKE  @Name + '%')
									OR
									(@NameOperator = 'Ends with' AND T.ProgramName LIKE  '%' + @Name)
									OR
									(@NameOperator = 'Contains' AND T.ProgramName LIKE  '%' + @Name + '%')
								))
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
 -- EXEC dms_Program_Management_ProgramConfigurationList @programID = 1,@pageSize=50
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
    SET FMTONLY OFF
    
DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
ProgramConfigurationIDOperator="-1" 
ConfigurationTypeOperator="-1" 
ConfigurationCategoryOperator="-1" 
NameOperator="-1" 
ValueOperator="-1" 
ControlTypeOperator="-1" 
DataTypeOperator="-1" 
IsActiveOperator="-1" 
SequenceOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

CREATE TABLE #tmpForWhereClause
(
ProgramNameOperator INT NOT NULL,
ProgramNameValue nvarchar(50) NULL,
ProgramConfigurationIDOperator INT NOT NULL,
ProgramConfigurationIDValue INT NULL,
ConfigurationTypeOperator INT NOT NULL,
ConfigurationTypeValue nvarchar(50) NULL,
ConfigurationCategoryOperator INT NOT NULL,
ConfigurationCategoryValue nvarchar(50) NULL,
NameOperator INT NOT NULL,
NameValue nvarchar(50) NULL,
ValueOperator INT NOT NULL,
ValueValue nvarchar(50) NULL,
ControlTypeOperator INT NOT NULL,
ControlTypeValue nvarchar(50) NULL,
DataTypeOperator INT NOT NULL,
DataTypeValue nvarchar(50) NULL,
SequenceOperator INT NOT NULL,
SequenceValue INT NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue nvarchar(50) NULL
)

CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramID INT NOT NULL,
	ProgramName nvarchar(50) NULL,
	ProgramConfigurationID int  NULL ,
	ConfigurationType nvarchar(50) NULL,
	ConfigurationCategory nvarchar(50) NULL,
	Name nvarchar(MAX)  NULL ,
	Value nvarchar(MAX)  NULL ,
	IsActive nvarchar(50)  NULL ,
	ControlType nvarchar(50) NULL,
	DataType nvarchar(50) NULL,
	Sequence INT NULL
) 
DECLARE @QueryResult AS TABLE( 
	ProgramID INT NOT NULL,
	ProgramName nvarchar(50) NULL,
	ProgramConfigurationID int  NULL ,
	ConfigurationType nvarchar(50) NULL,
	ConfigurationCategory nvarchar(50) NULL,
	Name nvarchar(MAX)  NULL ,
	Value nvarchar(MAX)  NULL ,
	IsActive nvarchar(50)  NULL ,
	ControlType nvarchar(50) NULL,
	DataType nvarchar(50) NULL,
	Sequence INT NULL
) 

;WITH wProgramConfig 
		AS
		(	SELECT ROW_NUMBER() OVER ( PARTITION BY PC.Name ORDER BY PP.Sequence) AS RowNum,
					PP.ProgramID,
					P.Name ProgramName,
					PC.ID ProgramConfigurationID,
					PC.Sequence,
					PC.Name,	
					PC.Value,
					CASE ISNULL(PC.IsActive,0) WHEN 0 THEN 'No' ELSE 'Yes' END IsActiveText,
					CT.Name ControlType,
					DT.Name DataType,
					C.Name ConfigurationType,
					CC.Name ConfigurationCategory,
					PP.Sequence FnSequence
			FROM fnc_GetProgramsandParents(@ProgramID) PP
			JOIN ProgramConfiguration PC ON PP.ProgramID = PC.ProgramID AND PC.IsActive = 1
			LEFT JOIN Program P ON PP.ProgramID = P.ID
			LEFT JOIN ConfigurationType C ON PC.ConfigurationTypeID = C.ID 
			LEFT JOIN ControlType CT ON CT.ID = PC.ControlTypeID
			LEFT JOIN DataType DT ON DT.ID = PC.DataTypeID
			LEFT JOIN ConfigurationCategory CC ON PC.ConfigurationCategoryID = CC.ID
			--WHERE	(@ConfigurationType IS NULL OR C.Name = @ConfigurationType)
			--AND		(@ConfigurationCategory IS NULL OR CC.Name = @ConfigurationCategory)
		)
INSERT INTO @QueryResult SELECT
								W.ProgramID,
								W.ProgramName,
							    W.ProgramConfigurationID,	
								W.ConfigurationType,
								W.ConfigurationCategory,
								W.Name,
								W.Value,
								W.IsActiveText,
								W.ControlType,
								W.DataType,
								W.Sequence
						FROM	wProgramConfig W
						 WHERE	W.RowNum = 1
					   ORDER BY W.FnSequence, W.ProgramConfigurationID


INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(ProgramNameOperator,-1),
	ProgramNameValue ,
	ISNULL(ProgramConfigurationIDOperator,-1),
	ProgramConfigurationIDValue ,
	ISNULL(ConfigurationTypeOperator,-1),
	ConfigurationTypeValue ,
	ISNULL(ConfigurationCategoryOperator,-1),
	ConfigurationCategoryValue ,
	ISNULL(NameOperator,-1),
	NameValue ,
	ISNULL(ValueOperator,-1),
	ValueValue,
	ISNULL(ControlTypeOperator,-1),
	ControlTypeValue , 
	ISNULL(DataTypeOperator,-1),
	DataTypeValue , 
	ISNULL(SequenceOperator,-1),
	SequenceValue,
	ISNULL(IsActiveOperator,-1),
	IsActiveValue
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
ProgramNameOperator INT,
ProgramNameValue nvarchar(50) ,
ProgramConfigurationIDOperator INT,
ProgramConfigurationIDValue int 
,ConfigurationTypeOperator INT,
ConfigurationTypeValue nvarchar(50) 
,ConfigurationCategoryOperator INT,
ConfigurationCategoryValue nvarchar(50) 
,NameOperator INT,
NameValue nvarchar(50) 
,ValueOperator INT,
ValueValue nvarchar(50) 
,ControlTypeOperator INT,
ControlTypeValue nvarchar(50) 
,DataTypeOperator INT,
DataTypeValue nvarchar(50)
,SequenceOperator INT,
SequenceValue nvarchar(50)
,IsActiveOperator INT,
IsActiveValue nvarchar(50)    
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.ProgramID,
	T.ProgramName,
	T.ProgramConfigurationID,
	T.ConfigurationType,
	T.ConfigurationCategory,
	T.Name,
	T.Value,
	T.IsActive,
	T.ControlType,
	T.DataType,
	T.Sequence
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
	 ( TMP.ConfigurationTypeOperator = -1 ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 0 AND T.ConfigurationType IS NULL ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 1 AND T.ConfigurationType IS NOT NULL ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 2 AND T.ConfigurationType = TMP.ConfigurationTypeValue ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 3 AND T.ConfigurationType <> TMP.ConfigurationTypeValue ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 4 AND T.ConfigurationType LIKE TMP.ConfigurationTypeValue + '%') 
 OR 
	 ( TMP.ConfigurationTypeOperator = 5 AND T.ConfigurationType LIKE '%' + TMP.ConfigurationTypeValue ) 
 OR 
	 ( TMP.ConfigurationTypeOperator = 6 AND T.ConfigurationType LIKE '%' + TMP.ConfigurationTypeValue + '%' ) 
 ) 
 AND 

 ( 
	 ( TMP.ConfigurationCategoryOperator = -1 ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 0 AND T.ConfigurationCategory IS NULL ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 1 AND T.ConfigurationCategory IS NOT NULL ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 2 AND T.ConfigurationCategory = TMP.ConfigurationCategoryValue ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 3 AND T.ConfigurationCategory <> TMP.ConfigurationCategoryValue ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 4 AND T.ConfigurationCategory LIKE TMP.ConfigurationCategoryValue + '%') 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 5 AND T.ConfigurationCategory LIKE '%' + TMP.ConfigurationCategoryValue ) 
 OR 
	 ( TMP.ConfigurationCategoryOperator = 6 AND T.ConfigurationCategory LIKE '%' + TMP.ConfigurationCategoryValue + '%' ) 
 ) 
 AND 

 ( 
	 ( TMP.ControlTypeOperator = -1 ) 
 OR 
	 ( TMP.ControlTypeOperator = 0 AND T.ControlType IS NULL ) 
 OR 
	 ( TMP.ControlTypeOperator = 1 AND T.ControlType IS NOT NULL ) 
 OR 
	 ( TMP.ControlTypeOperator = 2 AND T.ControlType = TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 3 AND T.ControlType <> TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 4 AND T.ControlType LIKE TMP.ControlTypeValue + '%') 
 OR 
	 ( TMP.ControlTypeOperator = 5 AND T.ControlType LIKE '%' + TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 6 AND T.ControlType LIKE '%' + TMP.ControlTypeValue + '%' ) 
 ) 
 AND 

 ( 
	 ( TMP.DataTypeOperator = -1 ) 
 OR 
	 ( TMP.DataTypeOperator = 0 AND T.DataType IS NULL ) 
 OR 
	 ( TMP.DataTypeOperator = 1 AND T.DataType IS NOT NULL ) 
 OR 
	 ( TMP.DataTypeOperator = 2 AND T.DataType = TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 3 AND T.DataType <> TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 4 AND T.DataType LIKE TMP.DataTypeValue + '%') 
 OR 
	 ( TMP.DataTypeOperator = 5 AND T.DataType LIKE '%' + TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 6 AND T.DataType LIKE '%' + TMP.DataTypeValue + '%' ) 
 ) 
 AND 

 ( 
	 ( TMP.IsActiveOperator = -1 ) 
 OR 
	 ( TMP.IsActiveOperator = 0 AND T.IsActive IS NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 1 AND T.IsActive IS NOT NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 2 AND T.IsActive = TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 3 AND T.IsActive <> TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 4 AND T.IsActive LIKE TMP.IsActiveValue + '%') 
 OR 
	 ( TMP.IsActiveOperator = 5 AND T.IsActive LIKE '%' + TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 6 AND T.IsActive LIKE '%' + TMP.IsActiveValue + '%' ) 
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

	 CASE WHEN @sortColumn = 'ConfigurationType' AND @sortOrder = 'ASC'
	 THEN T.ConfigurationType END ASC, 
	 CASE WHEN @sortColumn = 'ConfigurationType' AND @sortOrder = 'DESC'
	 THEN T.ConfigurationType END DESC ,

     CASE WHEN @sortColumn = 'ConfigurationCategory' AND @sortOrder = 'ASC'
	 THEN T.ConfigurationCategory END ASC, 
	 CASE WHEN @sortColumn = 'ConfigurationCategory' AND @sortOrder = 'DESC'
	 THEN T.ConfigurationCategory END DESC ,
	 
	 CASE WHEN @sortColumn = 'ControlType' AND @sortOrder = 'ASC'
	 THEN T.ControlType END ASC, 
	 CASE WHEN @sortColumn = 'ControlType' AND @sortOrder = 'DESC'
	 THEN T.ControlType END DESC ,
	 
	 CASE WHEN @sortColumn = 'DataType' AND @sortOrder = 'ASC'
	 THEN T.DataType END ASC, 
	 CASE WHEN @sortColumn = 'DataType' AND @sortOrder = 'DESC'
	 THEN T.DataType END DESC ,
	 
	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'
	 THEN T.Sequence END ASC, 
	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'
	 THEN T.Sequence END DESC ,
	 
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
	 THEN T.IsActive END DESC, 

	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'ASC'
	 THEN T.ProgramName END ASC, 
	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'DESC'
	 THEN T.ProgramName END DESC 


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
 WHERE id = object_id(N'[dbo].[dms_Program_Management_ProgramDataItemList]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_ProgramDataItemList] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_Program_Management_ProgramDataItemList] @programID=45
 CREATE PROCEDURE [dbo].[dms_Program_Management_ProgramDataItemList]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID INT = NULL 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
ProgramNameOperator="-1" 
ProgramDataItemIDOperator="-1" 
ScreenNameOperator="-1" 
NameOperator="-1" 
LabelOperator="-1" 
IsActiveOperator="-1" 
ControlTypeOperator="-1" 
DataTypeOperator="-1" 
SequenceOperator="-1" 
IsRequiredOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
ProgramNameOperator INT NOT NULL,
ProgramNameValue nvarchar(100) NULL,
ProgramDataItemIDOperator INT NOT NULL,
ProgramDataItemIDValue int NULL,
ScreenNameOperator INT NOT NULL,
ScreenNameValue nvarchar(100) NULL,
NameOperator INT NOT NULL,
NameValue nvarchar(100) NULL,
LabelOperator INT NOT NULL,
LabelValue nvarchar(100) NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue bit NULL,
ControlTypeOperator INT NOT NULL,
ControlTypeValue nvarchar(100) NULL,
DataTypeOperator INT NOT NULL,
DataTypeValue nvarchar(100) NULL,
SequenceOperator INT NOT NULL,
SequenceValue int NULL,
IsRequiredOperator INT NOT NULL,
IsRequiredValue bit NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramID INT NOT NULL,
	ProgramName nvarchar(100)  NULL,
	ProgramDataItemID int  NULL ,
	ScreenName nvarchar(100)  NULL ,
	Name nvarchar(100)  NULL ,
	Label nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	ControlType nvarchar(100)  NULL ,
	DataType nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsRequired bit  NULL 
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramID INT NOT NULL,
	ProgramName nvarchar(100)  NULL,
	ProgramDataItemID int  NULL ,
	ScreenName nvarchar(100)  NULL ,
	Name nvarchar(100)  NULL ,
	Label nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	ControlType nvarchar(100)  NULL ,
	DataType nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsRequired bit  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@ProgramNameOperator','INT'),-1),
	T.c.value('@ProgramNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProgramDataItemIDOperator','INT'),-1),
	T.c.value('@ProgramDataItemIDValue','int') ,
	ISNULL(T.c.value('@ScreenNameOperator','INT'),-1),
	T.c.value('@ScreenNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@NameOperator','INT'),-1),
	T.c.value('@NameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@LabelOperator','INT'),-1),
	T.c.value('@LabelValue','nvarchar(100)') ,
	ISNULL(T.c.value('@IsActiveOperator','INT'),-1),
	T.c.value('@IsActiveValue','bit') ,
	ISNULL(T.c.value('@ControlTypeOperator','INT'),-1),
	T.c.value('@ControlTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DataTypeOperator','INT'),-1),
	T.c.value('@DataTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@SequenceOperator','INT'),-1),
	T.c.value('@SequenceValue','int') ,
	ISNULL(T.c.value('@IsRequiredOperator','INT'),-1),
	T.c.value('@IsRequiredValue','bit') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT  PP.ProgramID,
		P.Name,
		PDI.ID ProgramDataItemID,
		PDI.ScreenName,
		PDI.Name,
		PDI.Label,
		PDI.IsActive,--CASE ISNULL(PC.IsActive,0) WHEN 0 THEN 'No' ELSE 'Yes' END IsActiveText,
		CT.[Description] ControlType,
		DT.[Description] DataType,
		PDI.Sequence,
		PDI.IsRequired
FROM fnc_GetProgramsandParents(@ProgramID) PP
JOIN Program P ON PP.ProgramID = P.ID
JOIN ProgramDataItem PDI ON PP.ProgramID = PDI.ProgramID AND PDI.IsActive = 1	
LEFT JOIN ControlType CT ON CT.ID = PDI.ControlTypeID
LEFT JOIN DataType DT ON DT.ID = PDI.DataTypeID
ORDER BY PDI.ScreenName,PDI.Sequence
INSERT INTO #FinalResults
SELECT 
	T.ProgramID,
	T.ProgramName,
	T.ProgramDataItemID,
	T.ScreenName,
	T.Name,
	T.Label,
	T.IsActive,
	T.ControlType,
	T.DataType,
	T.Sequence,
	T.IsRequired
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.ProgramDataItemIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 0 AND T.ProgramDataItemID IS NULL ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 1 AND T.ProgramDataItemID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 2 AND T.ProgramDataItemID = TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 3 AND T.ProgramDataItemID <> TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 7 AND T.ProgramDataItemID > TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 8 AND T.ProgramDataItemID >= TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 9 AND T.ProgramDataItemID < TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 10 AND T.ProgramDataItemID <= TMP.ProgramDataItemIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScreenNameOperator = -1 ) 
 OR 
	 ( TMP.ScreenNameOperator = 0 AND T.ScreenName IS NULL ) 
 OR 
	 ( TMP.ScreenNameOperator = 1 AND T.ScreenName IS NOT NULL ) 
 OR 
	 ( TMP.ScreenNameOperator = 2 AND T.ScreenName = TMP.ScreenNameValue ) 
 OR 
	 ( TMP.ScreenNameOperator = 3 AND T.ScreenName <> TMP.ScreenNameValue ) 
 OR 
	 ( TMP.ScreenNameOperator = 4 AND T.ScreenName LIKE TMP.ScreenNameValue + '%') 
 OR 
	 ( TMP.ScreenNameOperator = 5 AND T.ScreenName LIKE '%' + TMP.ScreenNameValue ) 
 OR 
	 ( TMP.ScreenNameOperator = 6 AND T.ScreenName LIKE '%' + TMP.ScreenNameValue + '%' ) 
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
	 ( TMP.LabelOperator = -1 ) 
 OR 
	 ( TMP.LabelOperator = 0 AND T.Label IS NULL ) 
 OR 
	 ( TMP.LabelOperator = 1 AND T.Label IS NOT NULL ) 
 OR 
	 ( TMP.LabelOperator = 2 AND T.Label = TMP.LabelValue ) 
 OR 
	 ( TMP.LabelOperator = 3 AND T.Label <> TMP.LabelValue ) 
 OR 
	 ( TMP.LabelOperator = 4 AND T.Label LIKE TMP.LabelValue + '%') 
 OR 
	 ( TMP.LabelOperator = 5 AND T.Label LIKE '%' + TMP.LabelValue ) 
 OR 
	 ( TMP.LabelOperator = 6 AND T.Label LIKE '%' + TMP.LabelValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.IsActiveOperator = -1 ) 
 OR 
	 ( TMP.IsActiveOperator = 0 AND T.IsActive IS NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 1 AND T.IsActive IS NOT NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 2 AND T.IsActive = TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 3 AND T.IsActive <> TMP.IsActiveValue ) 
 ) 

 AND 

 ( 
	 ( TMP.ControlTypeOperator = -1 ) 
 OR 
	 ( TMP.ControlTypeOperator = 0 AND T.ControlType IS NULL ) 
 OR 
	 ( TMP.ControlTypeOperator = 1 AND T.ControlType IS NOT NULL ) 
 OR 
	 ( TMP.ControlTypeOperator = 2 AND T.ControlType = TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 3 AND T.ControlType <> TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 4 AND T.ControlType LIKE TMP.ControlTypeValue + '%') 
 OR 
	 ( TMP.ControlTypeOperator = 5 AND T.ControlType LIKE '%' + TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 6 AND T.ControlType LIKE '%' + TMP.ControlTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DataTypeOperator = -1 ) 
 OR 
	 ( TMP.DataTypeOperator = 0 AND T.DataType IS NULL ) 
 OR 
	 ( TMP.DataTypeOperator = 1 AND T.DataType IS NOT NULL ) 
 OR 
	 ( TMP.DataTypeOperator = 2 AND T.DataType = TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 3 AND T.DataType <> TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 4 AND T.DataType LIKE TMP.DataTypeValue + '%') 
 OR 
	 ( TMP.DataTypeOperator = 5 AND T.DataType LIKE '%' + TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 6 AND T.DataType LIKE '%' + TMP.DataTypeValue + '%' ) 
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
	 ( TMP.IsRequiredOperator = -1 ) 
 OR 
	 ( TMP.IsRequiredOperator = 0 AND T.IsRequired IS NULL ) 
 OR 
	 ( TMP.IsRequiredOperator = 1 AND T.IsRequired IS NOT NULL ) 
 OR 
	 ( TMP.IsRequiredOperator = 2 AND T.IsRequired = TMP.IsRequiredValue ) 
 OR 
	 ( TMP.IsRequiredOperator = 3 AND T.IsRequired <> TMP.IsRequiredValue ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ProgramDataItemID' AND @sortOrder = 'ASC'
	 THEN T.ProgramDataItemID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramDataItemID' AND @sortOrder = 'DESC'
	 THEN T.ProgramDataItemID END DESC ,

	 CASE WHEN @sortColumn = 'ScreenName' AND @sortOrder = 'ASC'
	 THEN T.ScreenName END ASC, 
	 CASE WHEN @sortColumn = 'ScreenName' AND @sortOrder = 'DESC'
	 THEN T.ScreenName END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Label' AND @sortOrder = 'ASC'
	 THEN T.Label END ASC, 
	 CASE WHEN @sortColumn = 'Label' AND @sortOrder = 'DESC'
	 THEN T.Label END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC ,

	 CASE WHEN @sortColumn = 'ControlType' AND @sortOrder = 'ASC'
	 THEN T.ControlType END ASC, 
	 CASE WHEN @sortColumn = 'ControlType' AND @sortOrder = 'DESC'
	 THEN T.ControlType END DESC ,

	 CASE WHEN @sortColumn = 'DataType' AND @sortOrder = 'ASC'
	 THEN T.DataType END ASC, 
	 CASE WHEN @sortColumn = 'DataType' AND @sortOrder = 'DESC'
	 THEN T.DataType END DESC ,

	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'
	 THEN T.Sequence END ASC, 
	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'
	 THEN T.Sequence END DESC ,

	 CASE WHEN @sortColumn = 'IsRequired' AND @sortOrder = 'ASC'
	 THEN T.IsRequired END ASC, 
	 CASE WHEN @sortColumn = 'IsRequired' AND @sortOrder = 'DESC'
	 THEN T.IsRequired END DESC,

	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'ASC'
	 THEN T.ProgramName END ASC, 
	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'DESC'
	 THEN T.ProgramName END DESC 


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
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveDataItemInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveDataItemInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveDataItemInformation]( 
   @id INT = NULL
 , @programID INT = NULL
 , @controlTypeID INT = NULL
 , @dataTypeID INT = NULL
 , @name NVARCHAR(100) = NULL
 , @screenName NVARCHAR(100) = NULL
 , @label NVARCHAR(100) = NULL
 , @maxLength INT = NULL
 , @sequence INT = NULL
 , @isRequired BIT = NULL
 , @isActive BIT = NULL
 , @currentUser NVARCHAR(100) = NULL 
 )
 AS
 BEGIN
 IF @id > 0 
	 BEGIN
		UPDATE ProgramDataItem 
		SET ControlTypeID = @controlTypeID,
			DataTypeID = @dataTypeID,
			Name = @name,
			ScreenName = @screenName,
			Label = @label,
			Sequence = @sequence,
			MaxLength = @maxLength,
			IsRequired = @isRequired,
			IsActive = @isActive,
			ModifyBy = @currentUser,
			ModifyDate = GETDATE()
		WHERE ID = @id
	 END
ELSE
	BEGIN
		INSERT INTO ProgramDataItem (
			ProgramID,
			ControlTypeID,
			DataTypeID,
			Name,
			ScreenName,
			Label,
			Sequence,
			MaxLength,
			IsRequired,
			IsActive,
			CreateBy,
			CreateDate		
		)
		VALUES(
			@programID,
			@controlTypeID,
			@dataTypeID,
			@name,
			@screenName,
			@label,
			@sequence,
			@maxLength,
			@isRequired,
			@isActive,
			@currentUser,
			GETDATE()
		)
	END
END
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveProgramConfiguration]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveProgramConfiguration] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveProgramConfiguration]( 
 @programConfigurationId INT,
 @configurationTypeID INT=NULL,
 @configurationCategoryID INT=NULL,
 @controlTypeID INT=NULL,
 @dataTypeID INT=NULL,
 @name nvarchar(50)=NULL,
 @value nvarchar(4000)=NULL,
 @sequence INT=NULL,
 @user nvarchar(50)=NULL,
 @modifiedOn datetime=NULL,
 @isAdd bit,
 @programID int
 )
 AS
 BEGIN
 
 IF @isAdd=1 
 BEGIN
 
	INSERT INTO ProgramConfiguration(ProgramID,ConfigurationTypeID,ConfigurationCategoryID,ControlTypeID,DataTypeID,Name,Value,IsActive,Sequence,CreateDate,CreateBy)
	VALUES(@programID,@configurationTypeID,@configurationCategoryID,@controlTypeID,@dataTypeID,@name,@value,1,@sequence,@modifiedOn,@user)
	
 END
 ELSE BEGIN
 
	UPDATE ProgramConfiguration
	SET ConfigurationTypeID=@configurationTypeID,
		ConfigurationCategoryID=@configurationCategoryID,
		ControlTypeID=@controlTypeID,
		DataTypeID=@dataTypeID,
		Name=@name,
		Value=@value,
		Sequence=@sequence,
		ModifyBy=@user,
		ModifyDate=@modifiedOn
	WHERE ID=@programConfigurationId
 END
 
 END
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveProgramInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveProgramInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveProgramInformation]( 
 @programID int,
 @parentProgramID int = NULL,
 @programName nvarchar(50) = NULL,
 @programDescription nvarchar(255) = NULL,
 @programCode nvarchar(20) = NULL,
 @isActive bit = NULL,
 @isAudited bit = NULL,
 @isGroup bit = NULL,
 @isServiceGuaranteed bit = NULL,
 @isWebRegistrationEnabled bit = NULL,
 @modifiedBy nvarchar(50)  = NULL
 )
 AS
 BEGIN
	UPDATE Program
	SET ParentProgramID = @parentProgramID,
		Name = @programName,
		[Description] = @programDescription,
		Code = @programCode,
		IsActive = @isActive,
		IsAudited = @isAudited,
		IsGroup = @isGroup,
		IsServiceGuaranteed = @isServiceGuaranteed,
		IsWebRegistrationEnabled = @isWebRegistrationEnabled,
		ModifyBy = @modifiedBy,
		ModifyDate = GETDATE()
	WHERE ID=@programID
	
 END
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveProgramPhoneSystemConfigurationInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveProgramPhoneSystemConfigurationInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveProgramPhoneSystemConfigurationInformation]( 
   @id INT = NULL
 , @ivrScriptID INT = NULL
 , @skillSetID INT = NULL
 , @phoneCompanyID INT = NULL
 , @inboundNumber NVARCHAR(100) = NULL
 , @pilotNumber NVARCHAR(100) = NULL
 , @isshownOnScreen BIT = NULL
 , @isActive BIT = NULL
 , @programID INT = NULL
 , @modifiedBy NVARCHAR(100) = NULL
 )
 AS
 BEGIN
 
 IF @id>0
	BEGIN
		UPDATE PhoneSystemConfiguration
		SET IVRScriptID = @ivrScriptID ,
			SkillsetID = @skillSetID ,
			InboundPhoneCompanyID = @phoneCompanyID ,
			InboundNumber = @inboundNumber ,
			PilotNumber = @pilotNumber ,
			IsShownOnScreen = @isshownOnScreen ,
			IsActive = @isActive ,
			ModifyBy = @modifiedBy ,
			ModifyDate = GETDATE()
		WHERE ID = @id
	END
ELSE
	BEGIN
		INSERT INTO PhoneSystemConfiguration(
			ProgramID,
			IVRScriptID,
			SkillsetID,
			InboundPhoneCompanyID,
			InboundNumber,
			PilotNumber,
			IsShownOnScreen,
			IsActive,
			CreateBy,
			CreateDate
		)
		VALUES(
			@programID,
			@ivrScriptID,
			@skillSetID,
			@phoneCompanyID,
			@inboundNumber,
			@pilotNumber,
			@isshownOnScreen,
			@isActive,
			@modifiedBy,
			GETDATE()
		)
	END
 
 END
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveServiceEventLimitInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveServiceEventLimitInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveServiceEventLimitInformation]( 
   @id INT = NULL
 , @programID INT = NULL
 , @productCategoryID INT = NULL
 , @productID INT = NULL
 , @vehicleTypeID INT = NULL
 , @vehicleCategoryID INT = NULL
 , @description NVARCHAR(MAX) = NULL
 , @limit INT = NULL
 , @limitDuration INT = NULL
 , @limitDurationUOM NVARCHAR(100) = NULL
 , @storedProcedureName NVARCHAR(100) = NULL
 , @currentUser NVARCHAR(100) = NULL 
 , @isActive BIT = NULL
 )
 AS
 BEGIN
 IF @id > 0 
	 BEGIN
		UPDATE ProgramServiceEventLimit 
		SET ProductCategoryID = @productCategoryID,
			ProductID = @productID,
			VehicleTypeID = @vehicleTypeID,
			VehicleCategoryID = @vehicleCategoryID,
			Description = @description,
			Limit = @limit,
			LimitDuration = @limitDuration,
			LimitDurationUOM=@limitDurationUOM,
			IsActive = @isActive,
			StoredProcedureName= @storedProcedureName
		WHERE ID = @id
	 END
ELSE
	BEGIN
		INSERT INTO ProgramServiceEventLimit (
			ProgramID,
			ProductCategoryID,
			ProductID,
			VehicleTypeID,
			VehicleCategoryID,
			Description,
			Limit,
			LimitDuration,
			LimitDurationUOM,
			StoredProcedureName,
			IsActive,
			CreateBy,
			CreateDate		
		)
		VALUES(
			@programID,
			@productCategoryID,
			@productID,
			@vehicleTypeID,
			@vehicleCategoryID,
			@description,
			@limit,
			@limitDuration,
			@limitDurationUOM,
			@storedProcedureName,
			@isActive,
			@currentUser,
			GETDATE()
		)
	END
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
