IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Access_Control_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Access_Control_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 	
 -- EXEC [dbo].[dms_Access_Control_List_Get] 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
 -- '02C162F8-C8BD-481B-A4E5-6D958141E8E1'
 CREATE PROC [dbo].[dms_Access_Control_List_Get](@userID UNIQUEIDENTIFIER = NULL)
 AS
 BEGIN
 
	-- 1. Get all the roles of the logged in user
	-- 2. Get a list of securables that the user is allowed to access
	-- 3. Filter the securables by applying the following precedence - ReadWrite > ReadOnly > Denied.
	DECLARE @tblACL TABLE
	(
		FriendlyName NVARCHAR(255),
		SecurityContext NVARCHAR(255),
		AccessTypeID INT		
	)
	
	;WITH wRolesOfUser
	AS
	(
		SELECT	R.RoleId
		FROM	aspnet_UsersInRoles UIR
		JOIN	aspnet_Users U ON UIR.UserId = U.UserId
		JOIN	aspnet_Roles R ON UIR.RoleId = R.RoleId
		WHERE	U.UserId = @userID
	)
	
	INSERT INTO @tblACL
	SELECT	S.FriendlyName,
			S.SecurityContext,
			ACL.AccessTypeID
	FROM	AccessControlList ACL
	JOIN	Securable S ON ACL.SecurableID = S.ID
	JOIN	wRolesOfUser W ON ACL.RoleID = W.RoleId
	
	
	;WITH wACL
	AS
	(
		SELECT ROW_NUMBER() OVER ( PARTITION BY T.FriendlyName ORDER BY T.AccessTypeID DESC) AS RowNum,
			   T.FriendlyName,
			   T.SecurityContext,
			   T.AccessTypeID	
		FROM	@tblACL T	
	)
	
	DELETE FROM wACL WHERE RowNum > 1
	
	SELECT	T.FriendlyName,
			T.SecurityContext,
			T.AccessTypeID
	FROM	@tblACL T
	
 
 END