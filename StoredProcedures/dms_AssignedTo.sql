
/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_AssignedTo]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_AssignedTo]
GO
/****** Object:  StoredProcedure [dbo].[dms_users_list]    Script Date: 07/03/2012 17:56:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC  [dbo].[dms_AssignedTo]

 CREATE PROCEDURE [dbo].[dms_AssignedTo]
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

SELECT DISTINCT u.* 
FROM [User] u
JOIN aspnet_UsersInRoles uir ON uir.UserID = u.aspnet_UserID
JOIN aspnet_Roles r ON r.RoleID = uir.RoleID
JOIN aspnet_Membership m ON u.aspnet_UserID = m.UserId
WHERE
	r.RoleName IN ('Agent','RVTech','Manager','Dispatcher','FrontEnd')
AND m.IsApproved = 1
ORDER BY  u.FirstName


END


