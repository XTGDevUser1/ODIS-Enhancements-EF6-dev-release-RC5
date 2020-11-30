
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_MemberList_ByClient_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_MemberList_ByClient_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  

 -- EXEC [dbo].[dms_MemberList_ByClient_Get] '32,12','4/15/2012','6/30/2013'
 CREATE PROCEDURE [dbo].[dms_MemberList_ByClient_Get]( 
	@clientIDs			NVARCHAR(MAX),
	@startDate			DATETIME, 
	@endDate			DATETIME,
	@MembershipNumber	NVARCHAR(25) = NULL,
	@LastName			NVARCHAR(50) = NULL,
	@FirstName			NVARCHAR(50) = NULL
 ) 
 AS 
 BEGIN
	DECLARE @tblClients TABLE (
		ClientID	INT
	)
	INSERT INTO @tblClients
	SELECT * FROM [dbo].[fnSplitString](@clientIDs,',')

/************ For Testing***********************
DECLARE	@clientID INT = 4
DECLARE	@startDate DATETIME = '4/15/2013'
DECLARE @endDate DATETIME = '6/30/2013'
DECLARE @MembershipNumber NVARCHAR(25) = NULL
DECLARE @LastName NVARCHAR(50) = NULL
DECLARE @FirstName NVARCHAR(50) = NULL
************************************************/
 
	CREATE TABLE #tmpResultsFiltered
	(
		ClientID INT,
		ClientName NVARCHAR(50) NULL,
		ClientStatus BIT NULL,
		ProgramID INT NULL,
		ProgramName NVARCHAR(50) NULL,
		ProgramStatus INT NULL,
		MemberID INT NULL,
		MembershipNumber NVARCHAR(25) NULL,
		Prefix NVARCHAR(10) NULL,
		FirstName NVARCHAR(50) NULL,
		MiddleName NVARCHAR(50) NULL,
		LastName NVARCHAR(50) NULL,		
		Suffix NVARCHAR(10) NULL,
		Email NVARCHAR(255) NULL,
		MemberSinceDate DATETIME NULL,
		EffectiveDate DATETIME NULL,
		ExpirationDate DATETIME NULL,
		ClientMemberKey NVARCHAR(50) NULL,
		IsPrimary BIT NULL,		
		POCount INT NULL,
		VehiclesIndicator INT NULL,
		ReferenceProgram NVARCHAR(50) NULL,
		MembershipDurationYears INT NULL
	)
	
	CREATE TABLE #tmpResultsFormatted
	(
		ClientID INT,
		ClientName NVARCHAR(50) NULL,
		ClientStatus BIT NULL,
		ProgramID INT NULL,
		ProgramName NVARCHAR(50) NULL,
		ProgramStatus INT NULL,
		MemberID INT NULL,
		MembershipNumber NVARCHAR(25) NULL,
		MemberName NVARCHAR(255) NULL,
		Email NVARCHAR(255) NULL,
		MemberSinceDate DATETIME NULL,
		EffectiveDate DATETIME NULL,
		ExpirationDate DATETIME NULL,
		ClientMemberKey NVARCHAR(50) NULL,
		IsPrimary BIT NULL,
		MemberStatus NVARCHAR(50) NULL,
		POCount INT NULL,
		VehiclesIndicator NVARCHAR(25) NULL,
		ReferenceProgram NVARCHAR(50) NULL,
		MembershipDurationYears INT NULL
	)
	
	DECLARE @minDate DATETIME = '1900-01-01'
	DECLARE @now DATETIME = GETDATE()
	
	INSERT INTO #tmpResultsFiltered
	SELECT
			CL.ID AS [ClientID]
			, CL.Name AS [ClientName]
			, CL.IsActive AS [ClientStatus]
			, P.ID AS [ProgramID]
			, P.Name AS [ProgramName]
			, P.IsActive AS [ProgramStatus]
			, M.ID AS [MemberID]
			, MS.MembershipNumber AS [MemberNumber]
			, M.Prefix
			, M.FirstName
			, M.MiddleName
			, M.LastName
			, M.Suffix
			, M.Email AS [Email]
			, M.MemberSinceDate
			, M.EffectiveDate
			, M.ExpirationDate
			, M.ClientMemberKey AS [ClientMemberKey]
			, M.IsPrimary AS [IsPrimary]			
			, 0 AS [POCount] 
			, NULL AS [VehiclesIndicator]
			, M.ReferenceProgram AS [ReferenceProgram]
			, DATEDIFF(yy,M.MemberSinceDate, getdate())
	FROM	Client CL WITH (NOLOCK)
	JOIN	Program P WITH (NOLOCK) ON P.ClientID = CL.ID AND P.IsActive = 1
	JOIN	Member M WITH (NOLOCK) ON M.ProgramID = P.ID
	JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
	JOIN	@tblClients CLT ON CLT.ClientID	= CL.ID
	--WHERE	CL.ID = @ClientID
	WHERE	((@startDate IS NULL AND @endDate IS NULL) OR (M.CreateDate BETWEEN @startDate AND @endDate))
	AND		( @MembershipNumber IS NULL OR MS.MembershipNumber = @MembershipNumber)
	AND		( @LastName IS NULL OR M.LastName LIKE @LastName + '%' )
	AND		( @FirstName IS NULL OR M.FirstName LIKE @FirstName + '%' ) 
	
	
	
	INSERT INTO #tmpResultsFormatted
	SELECT	  T.ClientID
			, T.ClientName
			, T.ClientStatus
			, T.ProgramID
			, T.ProgramName
			, T.ProgramStatus
			, T.MemberID
			, T.MembershipNumber
			, REPLACE(RTRIM(
			  COALESCE(T.LastName,'')+  
			  COALESCE(' ' + CASE WHEN T.Suffix = '' THEN NULL ELSE T.Suffix END,'')+  
			  COALESCE(', '+ CASE WHEN T.FirstName = '' THEN NULL ELSE T.FirstName END,'' )+
			  COALESCE(' ' + LEFT(T.MiddleName,1),'')
				),'','') AS [MemberName]
			, T.Email
			, T.MemberSinceDate
			, T.EffectiveDate
			, T.ExpirationDate
			, T.ClientMemberKey
			, T.IsPrimary
			, CASE	WHEN ISNULL(T.EffectiveDate,@minDate) <= @now AND ISNULL(T.ExpirationDate,@minDate) >= @now
					THEN 'Active'
					ELSE 'Inactive'
			END AS MemberStatus
			, (SELECT COUNT(*) 
				FROM PurchaseOrder PO1
				JOIN ServiceRequest SR1 ON SR1.ID = PO1.ServiceRequestID
				JOIN [Case] C1 ON C1.ID = SR1.CaseID
				JOIN Member M1 ON M1.ID = C1.MemberID
				WHERE M1.ID = T.MemberID
				AND	PO1.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued','Issued-Paid','Cancelled'))
				) 
			, CASE 
				WHEN (SELECT COUNT(*)
				FROM Vehicle V
				JOIN Membership MS ON MS.ID = V.MembershipID
				WHERE MS.MembershipNumber = T.MembershipNumber
				) > 0 THEN 'Yes'
				ELSE 'No'
			  END  
			, T.ReferenceProgram  
			, T.MembershipDurationYears
	FROM	#tmpResultsFiltered T
	
	SELECT T.ClientID
			, T.ClientName
			, T.ClientStatus
			, T.ProgramID
			, T.ProgramName
			, T.ProgramStatus
			, T.MemberID
			, T.MembershipNumber
			, T.[MemberName]
			, T.Email
			, T.MemberSinceDate
			, T.EffectiveDate
			, T.ExpirationDate
			, T.ClientMemberKey
			, T.IsPrimary
			, T.[MemberStatus]
			, T.[POCount]
			, T.VehiclesIndicator
			, T.ReferenceProgram as [ProgramReferenceField]
			, T.MembershipDurationYears
	FROM	#tmpResultsFormatted T
	ORDER BY T.MemberName
	
	DROP TABLE #tmpResultsFiltered
	DROP TABLE #tmpResultsFormatted
				
	
 END
 
GO


