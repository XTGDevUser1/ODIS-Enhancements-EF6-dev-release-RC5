IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Securbale_Permissions]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Securbale_Permissions] 
END 
GO

CREATE PROC dms_Securbale_Permissions(@SecurableID INT = NULL)
AS
BEGIN
	SELECT	R.RoleName,
			R.RoleId,
			AT.Name AccessTypeName,
			ACL.AccessTypeID
	FROM  aspnet_Roles R
	LEFT JOIN AccessControlList ACL ON R.RoleId = ACL.RoleID AND ACL.SecurableID = ( SELECT ID FROM Securable S WHERE S.ID = @SecurableID)
	LEFT JOIN AccessType AT ON AT.ID = ACL.AccessTypeID
	JOIN aspnet_Applications A ON R.ApplicationId = A.ApplicationId
	WHERE A.ApplicationName = 'DMS'
END





