USE [DMS]
GO

/****** Object:  StoredProcedure [report].[InboundCallsWithoutServiceRequest_CountsByAgent]    Script Date: 10/27/2015 13:23:07 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[report].[InboundCallsWithoutServiceRequest_CountsByAgent]') AND type in (N'P', N'PC'))
DROP PROCEDURE [report].[InboundCallsWithoutServiceRequest_CountsByAgent]
GO

USE [DMS]
GO

/****** Object:  StoredProcedure [report].[InboundCallsWithoutServiceRequest_CountsByAgent]    Script Date: 10/27/2015 13:23:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--EXEC report.InboundCallsWithoutServiceRequest_CountsByAgent '10/1/2015', '10/31/2015'

CREATE PROCEDURE [report].[InboundCallsWithoutServiceRequest_CountsByAgent] (
	@BeginDate date,
	@EndDate date
)
AS

Select 
	ic.CreateBy UserName
	,CASE WHEN COALESCE(u.FirstName,'') <> '' THEN u.FirstName + ' ' ELSE '' END + COALESCE(u.LastName, '') Name
	,Count(*) [Count]
From DMS.dbo.InboundCall ic (NOLOCK)
Join DMS.dbo.aspnet_Users aspUsers (NOLOCK) ON aspUsers.UserName = ic.CreateBy
Join DMS.dbo.[User] u (NOLOCK) on aspUsers.UserId = u.aspnet_UserID
Where 1=1
and ic.CaseID IS NULL
and ic.CreateDate >= @BeginDate
and ic.CreateDate <= @EndDate
and NOT EXISTS 
(SELECT * FROM DMS.dbo.aspnet_Users au (NOLOCK)
   JOIN DMS.dbo.aspnet_Applications a (NOLOCK) ON a.ApplicationId = au.ApplicationId AND a.ApplicationName = 'DMS'
   JOIN DMS.dbo.aspnet_UsersInRoles uir (NOLOCK) ON uir.UserId = au.UserId
   JOIN DMS.dbo.aspnet_Roles r (NOLOCK) ON r.RoleId = uir.RoleId
   WHERE 1=1
   AND au.Username = ic.CreateBy
   AND r.RoleName IN (
		'VendorMgr'
		,'VendorRep'
		,'ClientRelationsMgr'
		,'ClientRelations'
		,'DispatchAdmin'
		,'ClaimsMgr'
		,'Claims'
		,'Accounting'
		,'InvoiceEntry'
		,'SysAdmin'
		,'AccountingMgr'
  )
)
GROUP BY ic.CreateBy, u.FirstName, u.LastName
ORDER BY COUNT(*) DESC, ic.CreateBy, u.FirstName, u.LastName

GO


