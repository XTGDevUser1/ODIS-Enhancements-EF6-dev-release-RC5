/*
*	Name				: dms_registered_owners_by_client_list
*	Purpose				: To get list of registered owners  based on client/MFG. The sp allows to filter the results by membernumber, first name and last name too.
*	Execution sample	: EXEC [dbo].[dms_registered_owners_by_client_list] '32,12',NULL,NULL,NULL
*/

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_registered_owners_by_client_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
	DROP PROCEDURE [dbo].[dms_registered_owners_by_client_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  
 
 CREATE PROCEDURE [dbo].[dms_registered_owners_by_client_list]( 
	@clientIDs			NVARCHAR(MAX),
	@startDate			DATETIME,
	@endDate			DATETIME,
	@MemberNumber		NVARCHAR(50) = NULL,
	@LastName			NVARCHAR(50) = NULL,
	@FirstName			NVARCHAR(50) = NULL
 ) 
 AS 
 BEGIN

	DECLARE @minDate DATETIME = '1900-01-01'
	DECLARE @now DATETIME = GETDATE()

	DECLARE @tblClients TABLE (
	ClientID	INT
	)
	INSERT INTO @tblClients
	SELECT * FROM [dbo].[fnSplitString](@clientIDs,',')
	
	SELECT
			CL.ID AS [ClientID]
			, CL.Name AS [ClientName]
			, M.ID AS [MemberID]
			, MS.MembershipNumber AS [CustomerID]
			, REPLACE(RTRIM(
			  COALESCE(M.LastName,'')+  
			  COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')+  
			  COALESCE(', '+ CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+
			  COALESCE(' ' + LEFT(M.MiddleName,1),'')
				),'','') AS [CustomerName]
			, M.Email AS [Email]
			, CONVERT(VARCHAR(10),M.MemberSinceDate,101) AS [MemberSinceDate]
			, CONVERT(VARCHAR(10),M.EffectiveDate,101) AS [EffectiveDate]
			, CONVERT(VARCHAR(10),M.ExpirationDate,101) AS [ExpirationDate]
			, M.ClientMemberKey AS [ClientMemberKey]
			, M.IsPrimary AS [IsPrimary]
			, CASE	WHEN ISNULL(M.EffectiveDate,@minDate) <= @now AND ISNULL(M.ExpirationDate,@minDate) >= @now
					THEN 'Active'
					ELSE 'Inactive'
				END AS [CustomerStatus]
			, (SELECT COUNT(*) 
				FROM PurchaseOrder PO1
				JOIN ServiceRequest SR1 ON SR1.ID = PO1.ServiceRequestID
				JOIN [Case] C1 ON C1.ID = SR1.CaseID
				JOIN Member M1 ON M1.ID = C1.MemberID
				WHERE M1.ID = M.ID
				) AS [POCount] 
			, CASE
				WHEN ISNULL(V.ID, '') <> '' 
				THEN 'Yes'
				ELSE 'No'
			  END AS [VehiclesIndicator]
			, P.Name AS [Program] 
	FROM	Client CL WITH (NOLOCK)
	JOIN	Program P WITH (NOLOCK) ON P.ClientID = CL.ID
	JOIN	Member M WITH (NOLOCK) ON M.ProgramID = P.ID
	JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
	JOIN	Vehicle V WITH (NOLOCK) ON V.MembershipID = MS.ID
	JOIN	@tblClients CLT ON CLT.ClientID	= CL.ID
	WHERE	M.CreateDate BETWEEN @startDate AND @endDate
	AND		( @MemberNumber IS NULL OR MS.MembershipNumber = @MemberNumber)
	AND		( @LastName IS NULL OR M.LastName LIKE @LastName + '%' )
	AND		( @FirstName IS NULL OR M.FirstName LIKE @FirstName + '%' ) 
	ORDER BY
			REPLACE(RTRIM(
			  COALESCE(M.LastName,'')+  
			  COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')+  
			  COALESCE(', '+ CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+
			  COALESCE(' ' + LEFT(M.MiddleName,1),'')
				),'','')
				
	
 END
 GO
