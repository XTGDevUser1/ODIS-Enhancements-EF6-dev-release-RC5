IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_membermanagement_matched_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_membermanagement_matched_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_membermanagement_matched_get] @whereClauseXML=NULL,@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@memberID=811

CREATE PROCEDURE [dbo].[dms_membermanagement_matched_get](   
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10   
 , @sortColumn nvarchar(100)  = 'MemberNumber'   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @memberID INT = NULL   
 )   
 AS   
 BEGIN   
    
	SET NOCOUNT ON  
SET FMTONLY OFF;
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
	IsActive BIT NULL,
	CountryCode nvarchar(2) NULL 
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
	VehicleID INT NULL, -- KB: Added VehicleID     
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
	
	

DECLARE @currentMSClientReferenceNumber NVARCHAR(50) = NULL
DECLARE @memberEntityID INT  

DECLARE @now DATETIME, @minDate DATETIME
	
SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
SET @minDate = '1900-01-01'   
	
SELECT @memberEntityID = ID FROM Entity WHERE Name = 'Member'  

DECLARE @line1 NVARCHAR(50) = NULL,
		@city NVARCHAR(50) = NULL
		
		
SELECT	@line1 = LEFT(AE.Line1,7),
		@city = AE.City
FROM	AddressEntity AE 
WHERE	AE.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Home')
AND		AE.RecordID = @memberID
AND		AE.EntityID = @memberEntityID


SELECT	@currentMSClientReferenceNumber = ClientReferenceNumber
FROM	Membership 
WHERE	ID = (SELECT MembershipID FROM Member WHERE ID = @memberID)

SELECT	*  
INTO	#tmpPhone  
FROM	PhoneEntity PH WITH (NOLOCK)  
WHERE	PH.EntityID = @memberEntityID 
AND		PH.RecordID <> @memberID
AND  PH.PhoneNumber IN (
		SELECT PhoneNumber 
		FROM PhoneEntity MPE 
		WHERE	MPE.EntityID = @memberEntityID
		AND		MPE.RecordID = @memberID
	)
--DEBUG: SELECT * FROM #tmpPhone

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
					, P.ID AS ProgramID 
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate   
					, m.EffectiveDate 
					, '' AS VIN
					, NULL AS VehicleID
					, A.[StateProvinceID]
					,M.MiddleName
					,M.IsActive 
					,A.CountryCode
			FROM Member M WITH (NOLOCK)  
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID  
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID
			LEFT JOIN #tmpPhone PH WITH (NOLOCK) ON PH.RecordID = M.ID
			JOIN Program P WITH (NOLOCK) ON P.ID = M.ProgramID   
			WHERE (
				PH.RecordID IS NOT NULL
				OR	
				MS.ClientReferenceNumber = @currentMSClientReferenceNumber
				OR
				(	LEFT(A.Line1,7) = @line1
					AND
					A.City = @city
				)
			)
			AND	M.ID <> @memberID
				
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
		, COALESCE(F.HomePhoneNumber, F.WorkPhoneNumber, F.CellPhoneNumber, '') As PhoneNumber 
		, F.ProgramID    
		, F.Program    
		,(SELECT COUNT(*) FROM [Case] WHERE MemberID = F.MemberID) AS POCount   

		-- KB: Considering Effective and Expiration Dates to calculate member status
		, CASE  
			WHEN F.IsActive = 0 THEN 'Deleted'  
			WHEN ISNULL(F.EffectiveDate,@minDate) <= @now AND ISNULL(F.ExpirationDate,@minDate) >= @now
					THEN 'Active'
					ELSE 'Inactive' END AS MemberStatus
		, F.LastName  
		, F.FirstName  
		, '' AS VIN 
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
		COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber,
		F.ProgramID,   
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
		LEFT JOIN PhoneEntity PH WITH (NOLOCK) ON PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID 
		LEFT JOIN PhoneEntity PW WITH (NOLOCK) ON PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID 
		LEFT JOIN PhoneEntity PC WITH (NOLOCK) ON PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID 

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
			ProgramID,    
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
			F.ProgramID,  
			F.Program,    
			F.POCount,    
			F.MemberStatus,    
			F.VIN,
			F.VehicleID
	FROM #FinalResultsSorted F
	ORDER BY F.RowNum  
	
	
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
	   F.ProgramID,    
	   F.Program,    
	   F.POCount,    
	   F.MemberStatus,    
	   F.VIN,
	   F.VehicleID,    
	   MS.ClientReferenceNumber
	   FROM    
	   #FinalResultsDistinct F 
	   JOIN Membership MS ON F.MembershipID = MS.ID
	   WHERE RowNum BETWEEN @startInd AND @endInd    
	     
	DROP TABLE #FinalResultsFiltered  
	DROP TABLE #FinalResultsFormatted  
	DROP TABLE #FinalResultsSorted 
	DROP TABLE #FinalResultsDistinct
	DROP TABLE #tmpPhone


END

GO