IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_OdisUsers]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_OdisUsers] 
 END 
 GO  
CREATE View [dbo].[vw_OdisUsers]
as
Select org.[Description] Organization
,u.UserName
,OdisUser.FirstName
,OdisUser.LastName
,OdisUser.PhoneUserID
,ms.Email
,Case When ms.IsApproved = 1 Then 'Yes' Else 'No'End IsActive
,Case When ms.IsLockedOut = 1 Then 'Yes' Else 'No'End IsLockedOut
,ms.CreateDate
,ms.LastLoginDate
,ms.LastPasswordChangedDate
From [User] OdisUser
Join Organization org on org.ID = OdisUser.OrganizationID
Join aspnet_Users u on u.UserId = OdisUser.aspnet_UserID
Join aspnet_Applications app on u.ApplicationId = app.ApplicationId and app.ApplicationName = 'DMS'
Join aspnet_Membership ms on ms.UserId = u.UserId
GO

