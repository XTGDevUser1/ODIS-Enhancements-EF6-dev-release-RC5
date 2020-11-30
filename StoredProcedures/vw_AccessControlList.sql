
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_AccessControlList]') ) 
 BEGIN
 DROP VIEW [dbo].[vw_AccessControlList] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
/****** Object:  View [dbo].[vw_AccessControlList]    Script Date: 11/09/2014 17:58:55 ******/
SET ANSI_NULLS ON
GO
/*
	Select * from vw_AccessControlList
*/
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[vw_AccessControlList]

AS

SELECT acl.ID [ID]
  , a.ApplicationName [ApplicationName]
  , acl.RoleID [RoleID]
  , r.RoleName [RoleName]
  , acl.SecurableID [SecurableID]
  , s.FriendlyName [FriendlyName]
  , acl.AccessTypeID [AccessTypeID]
  , at.Name [AccessType]
  , acl.ClientTypeID [ClientTypeID]
  , ct.Name [ClientType]
  , acl.ClientID [ClientID]
  , c.Name [ClientName]
  , acl.ClientUserID [ClientUserID]
  , cu.FirstName [ClientUserFirstName]
  , cu.LastName [ClientUserLastName]
  , u.Username [Username]
FROM AccessControlList acl
JOIN Securable s ON s.ID = acl.SecurableID
JOIN aspnet_Roles r ON r.RoleID = acl.RoleID
JOIN aspnet_Applications a ON a.ApplicationID = r.ApplicationID
JOIN AccessType at ON at.ID = acl.AccessTypeID
LEFT JOIN Client c ON c.ID = acl.ClientID
LEFT JOIN ClientType ct ON ct.ID = acl.ClientTypeID
LEFT JOIN ClientUser cu ON cu.ID = acl.ClientUserID
LEFT JOIN aspnet_Users u ON u.UserID = cu.aspnet_UseriD 
--ORDER BY a.ApplicationID, r.RoleName, s.FriendlyName
GO

