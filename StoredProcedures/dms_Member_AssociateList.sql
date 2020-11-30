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
 WHERE id = object_id(N'[dbo].[dms_Member_AssociateList]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_AssociateList] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Member_AssociateList] @whereClauseXML ='<ROW><Filter MembershipIDOperator="2" MembershipIDValue="1"></Filter></ROW>', @sortColumn = 'EffectiveData', @sortOrder = 'ASC'  
CREATE PROCEDURE [dbo].[dms_Member_AssociateList]( 
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

	CREATE TABLE #FinalResultsFiltered ( 	
		MembershipID int  NULL ,
		MembershipNumber nvarchar(50)  NULL ,
		MemberID nvarchar(50)  NULL ,
		IsPrimary INT  NULL ,
		FirstName nvarchar(50)  NULL ,
		MiddleName nvarchar(50)  NULL ,
		LastName nvarchar(50)  NULL ,
		Suffix nvarchar(50)  NULL ,
		EffectiveDate datetime  NULL ,
		ExpirationDate datetime  NULL	 
	) 

	CREATE TABLE #FinalResultsFormatted ( 	
		MembershipID int  NULL ,
		MembershipNumber nvarchar(50)  NULL ,
		MemberID nvarchar(50)  NULL ,
		PrimaryMember nvarchar(50)  NULL ,
		MemberName nvarchar(200)  NULL ,
		EffectiveDate datetime  NULL ,
		ExpirationDate datetime  NULL ,
		IsPrimary int  NULL ,
		LastName nvarchar(50)  NULL ,
		FirstName nvarchar(50)  NULL ,
		MemberStatus nvarchar(50)  NULL 
	) 

	CREATE TABLE #FinalResultsSorted( 	
		[RowNum] [bigint] NOT NULL IDENTITY(1,1),  
		MembershipID int  NULL ,
		MembershipNumber nvarchar(50)  NULL ,
		MemberID nvarchar(50)  NULL ,
		PrimaryMember nvarchar(50)  NULL ,
		MemberName nvarchar(200)  NULL ,
		EffectiveDate datetime  NULL ,
		ExpirationDate datetime  NULL ,
		IsPrimary int  NULL ,
		LastName nvarchar(50)  NULL ,
		FirstName nvarchar(50)  NULL ,
		MemberStatus nvarchar(50)  NULL 
	) 

	DECLARE @idoc int
	IF @whereClauseXML IS NULL 
	BEGIN
	SET @whereClauseXML = '<ROW><Filter 
		MembershipIDOperator="-1" 
		MembershipNumberOperator="-1" 
		MemberIDOperator="-1" 
		 ></Filter></ROW>'
	END
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

	DECLARE @tmpForWhereClause TABLE
	(
	MembershipIDOperator INT NOT NULL,
	MembershipIDValue int NULL,
	MembershipNumberOperator INT NOT NULL,
	MembershipNumberValue nvarchar(50) NULL,
	MemberIDOperator INT NOT NULL,
	MemberIDValue nvarchar(50) NULL
	)

	-- Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'

	INSERT INTO @tmpForWhereClause
	SELECT  
		ISNULL(MembershipIDOperator,-1),
		MembershipIDValue ,
		ISNULL(MembershipNumberOperator,-1),
		MembershipNumberValue ,
		ISNULL(MemberIDOperator,-1),
		MemberIDValue 
	FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
	MembershipIDOperator INT,
	MembershipIDValue int 
	,MembershipNumberOperator INT,
	MembershipNumberValue nvarchar(50) 
	,MemberIDOperator INT,
	MemberIDValue nvarchar(50) 
	 ) 

	DECLARE @MembershipID int,
		@MembershipNumber nvarchar(50),
		@MemberID int

	SELECT	@MembershipID = MembershipIDValue,
			@MembershipNumber = MembershipNumberValue,
			@MemberID = MemberIDValue
	FROM	@tmpForWhereClause


	INSERT INTO #FinalResultsFiltered
	SELECT	ms.ID AS MembershipID, 
			ms.MembershipNumber AS MembershipNumber, 
			m.ID as MemberID,
			m.IsPrimary,
			m.FirstName,
			m.MiddleName,
			m.LastName,
			m.Suffix,
			m.EffectiveDate,
			m.ExpirationDate
	FROM Membership ms
	JOIN Member m ON m.MembershipID = ms.ID
	JOIN Program p ON p.id = m.ProgramID
	WHERE
		( @MembershipID IS NOT NULL OR @MemberID IS NOT NULL OR @MembershipNumber IS NOT NULL)
		AND
		( @MembershipID IS NULL  OR @MembershipID = MS.ID )
		 AND
		( @MemberID IS NULL  OR @MemberID = M.ID )
		 AND
		( @MembershipNumber IS NULL  OR @MembershipNumber = MS.MembershipNumber )


	 INSERT INTO #FinalResultsFormatted
	 SELECT	 DISTINCT 
			F.MembershipID, 
			F.MembershipNumber, 
			F.MemberID,
		   CASE WHEN F.IsPrimary = 1 THEN '*' ELSE ''END AS PrimaryMember,
		   CASE WHEN F.IsPrimary = 1 THEN '*' ELSE '' END + 
				REPLACE(RTRIM(COALESCE(F.FirstName,'')+ 
				COALESCE(' '+left(F.MiddleName,1),'')+
				COALESCE(' '+ F.LastName,'')+
				COALESCE(' '+ F.Suffix,'')),'  ',' ')
			AS MemberName,
			F.EffectiveDate,
			F.ExpirationDate,
			F.IsPrimary,
			F.LastName,
			F.FirstName,
			-- KB: Considering Effective and Expiration Dates to calculate member status
			CASE WHEN ISNULL(F.EffectiveDate,@minDate) <= @now AND ISNULL(F.ExpirationDate,@minDate) >= @now
							THEN 'Active'
							ELSE 'Inactive'
			END AS MemberStatus
	FROM	#FinalResultsFiltered F


	INSERT INTO #FinalResultsSorted
	SELECT F.*
	FROM	#FinalResultsFormatted  F
	ORDER BY 
		 CASE WHEN @sortColumn = 'MembershipID' AND @sortOrder = 'ASC'
		 THEN F.MembershipID END ASC, 
		 CASE WHEN @sortColumn = 'MembershipID' AND @sortOrder = 'DESC'
		 THEN F.MembershipID END DESC ,

		 CASE WHEN @sortColumn = 'MembershipNumber' AND @sortOrder = 'ASC'
		 THEN F.MembershipNumber END ASC, 
		 CASE WHEN @sortColumn = 'MembershipNumber' AND @sortOrder = 'DESC'
		 THEN F.MembershipNumber END DESC ,

		 CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'
		 THEN F.MemberID END ASC, 
		 CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'
		 THEN F.MemberID END DESC ,

		 CASE WHEN @sortColumn = 'PrimaryMember' AND @sortOrder = 'ASC'
		 THEN F.PrimaryMember END ASC, 
		 CASE WHEN @sortColumn = 'PrimaryMember' AND @sortOrder = 'DESC'
		 THEN F.PrimaryMember END DESC ,

		 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'
		 THEN F.MemberName END ASC, 
		 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'
		 THEN F.MemberName END DESC ,

		 CASE WHEN @sortColumn = 'EffectiveDate' AND @sortOrder = 'ASC'
		 THEN F.EffectiveDate END ASC, 
		 CASE WHEN @sortColumn = 'EffectiveDate' AND @sortOrder = 'DESC'
		 THEN F.EffectiveDate END DESC ,

		 CASE WHEN @sortColumn = 'ExpirationDate' AND @sortOrder = 'ASC'
		 THEN F.ExpirationDate END ASC, 
		 CASE WHEN @sortColumn = 'ExpirationDate' AND @sortOrder = 'DESC'
		 THEN F.ExpirationDate END DESC ,

		 CASE WHEN @sortColumn = 'IsPrimary' AND @sortOrder = 'ASC'
		 THEN F.IsPrimary END ASC, 
		 CASE WHEN @sortColumn = 'IsPrimary' AND @sortOrder = 'DESC'
		 THEN F.IsPrimary END DESC ,

		 CASE WHEN @sortColumn = 'LastName' AND @sortOrder = 'ASC'
		 THEN F.LastName END ASC, 
		 CASE WHEN @sortColumn = 'LastName' AND @sortOrder = 'DESC'
		 THEN F.LastName END DESC ,

		 CASE WHEN @sortColumn = 'FirstName' AND @sortOrder = 'ASC'
		 THEN F.FirstName END ASC, 
		 CASE WHEN @sortColumn = 'FirstName' AND @sortOrder = 'DESC'
		 THEN F.FirstName END DESC 


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

	SELECT @count AS TotalRows, 
		  F.RowNum,
		  F.MembershipID,
		  F.MemberID,
		  F.PrimaryMember,
		  F.MemberName,
		  CONVERT(NVARCHAR(10), F.EffectiveDate,101)AS EffectiveDate,
		  CONVERT(NVARCHAR(10), F.ExpirationDate,101)AS ExpirationDate,
		  F.MemberStatus 
		  FROM #FinalResultsSorted F 
		  
	DROP TABLE #FinalResultsFiltered
	DROP TABLE #FinalResultsFormatted
	DROP TABLE #FinalResultsSorted

END
