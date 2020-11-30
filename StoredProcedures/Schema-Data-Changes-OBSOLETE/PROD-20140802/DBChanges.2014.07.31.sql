--EXECUTE Line by Line
UPDATE ServiceRequest SET PrimaryCoverageLimit = CoverageLimit where PrimaryCoverageLimit IS NULL
UPDATE ServiceRequest SET CoverageLimit = null  WHERE PrimaryCoverageLimit IS NOT  NULL
UPDATE ServiceRequest SET PrimaryCoverageLimit = 0, IsServiceCoverageBestValue = 1 where PrimaryCoverageLimit IN (999,9999,9999.99)

IF EXISTS(SELECT * FROM sys.columns 
        WHERE [name] = N'CoverageLimit' AND [object_id] = OBJECT_ID(N'ServiceRequest'))
BEGIN
ALTER TABLE ServiceRequest DROP COLUMN CoverageLimit
END

DECLARE @roleID UNIQUEIDENTIFIER = (Select RoleId from aspnet_Roles where ApplicationId = (Select ApplicationId from aspnet_Applications where ApplicationName='DMS') AND RoleName='sysadmin')
INSERT INTO NextActionRole(NextActionID,RoleID) SELECT ID,@roleID FROM NextAction
--Select * from [User] where aspnet_UserID IN(Select UserId from aspnet_UsersInRoles where RoleId=@roleID)