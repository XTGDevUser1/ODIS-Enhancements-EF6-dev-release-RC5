/*
*	Name				: dms_client_authenticate
*	Execution sample	: EXEC [dbo].[dms_client_authenticate] 'democlientsuper', 'demopass'
*/

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_client_authenticate]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_client_authenticate] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  
 
CREATE PROCEDURE [dbo].[dms_client_authenticate]
(
	@userName NVARCHAR(256),
	@password NVARCHAR(128)
)
AS
BEGIN
	
	DECLARE @applicationID UNIQUEIDENTIFIER = NULL
	DECLARE @userID UNIQUEIDENTIFIER = NULL
	
	DECLARE @userDetails TABLE
	(
		aspnet_UserID	UNIQUEIDENTIFIER,
		UserID			INT,
		FirstName	NVARCHAR(50) NULL,
		LastName	NVARCHAR(50) NULL,
		LastActivityDate DATETIME NULL,
		Email		NVARCHAR(256) NULL
	)
	
	DECLARE @finalResults TABLE
	(		
		[Status]	BIT,
		FirstName	NVARCHAR(50) NULL,
		LastName	NVARCHAR(50) NULL,
		ClientID	INT NULL,
		ClientName	NVARCHAR(50) NULL,
		LastActivityDate DATETIME NULL,
		Email		NVARCHAR(256) NULL
	)
	
	SELECT @applicationID = ApplicationId
	FROM	aspnet_Applications WITH (NOLOCK)
	WHERE	ApplicationName = 'ClientPortal'
	
	
	--DEBUG: SELECT @applicationID
	
	DECLARE @dbUserName NVARCHAR(256) = NULL
	DECLARE @dbPassword NVARCHAR(128) = NULL
	
	INSERT INTO @userDetails
	SELECT	AU.UserId,
			U.ID,
			U.FirstName,
			U.LastName,
			AU.LastActivityDate,
			AM.Email
	FROM	aspnet_Users AU WITH (NOLOCK)
	JOIN	aspnet_Membership AM WITH (NOLOCK) ON AU.UserId = AM.UserId AND AU.ApplicationId = AM.ApplicationId
	JOIN	[User] U WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
	WHERE	AU.ApplicationId = @applicationID
	AND		AU.UserName	= @userName
	AND		AM.[Password] = @password
	AND		AM.IsApproved = 1
	AND		AM.IsLockedOut = 0
	
	
	
	SELECT @userID = aspnet_UserID FROM @userDetails
	
	IF @userID IS NOT NULL -- User is authenticated
	BEGIN
		-- check to see if the user is a super user
		DECLARE @isSuperUser INT = 0
		SELECT  @isSuperUser = COUNT(*) 
		FROM	aspnet_UsersInRoles UIR
		JOIN	aspnet_Roles R ON UIR.RoleId = R.RoleId
		WHERE	R.RoleName = 'SuperUser'
		AND		UIR.UserId = @userID
		--Debug: Select @isSuperUser
		IF @isSuperUser > 0
		BEGIN
			
			SELECT	U.FirstName,
					U.LastName,
					C.ID AS ClientID,
					C.Name AS ClientName,
					U.LastActivityDate,
					U.Email
			FROM	@userDetails U,
					Client C
			WHERE	ISNULL(C.IsActive,0) = 1			
		
		END
		ELSe
		BEGIN
		
			SELECT	
					UD.FirstName,
					UD.LastName,
					C.ID AS ClientID,
					C.Name AS ClientName,
					UD.LastActivityDate,
					UD.Email
			FROM	@userDetails UD --WITH (NOLOCK)	
			JOIN	[User] U WITH (NOLOCK) ON U.ID = UD.UserID
			JOIN	OrganizationClient OC WITH (NOLOCK) ON U.OrganizationID = OC.OrganizationID
			JOIN	Client C WITH (NOLOCK) ON OC.ClientID = C.ID
			AND		ISNULL(C.IsActive,0) = 1
	
		END
		
	
	END
	ELSE
	BEGIN
		-- Return just the schema (@finalResults will be empty here)
		SELECT	FirstName,
				LastName,
				ClientID,
				ClientName,
				LastActivityDate,
				Email 
		FROM	@finalResults
	END

END
