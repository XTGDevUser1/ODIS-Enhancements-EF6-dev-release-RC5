IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_OdisUserRoles]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_OdisUserRoles] 
 END 
 GO  
CREATE View [dbo].[vw_OdisUserRoles]
as
Select u.UserName, r.RoleName
From aspnet_Roles r 
Join aspnet_Applications app on r.ApplicationId = app.ApplicationId and app.ApplicationName = 'DMS'
Join aspnet_UsersInRoles uir on uir.RoleId = r.RoleId
Join aspnet_Users u on u.UserId = uir.UserID
GO

