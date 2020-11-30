ALTER TABLE Vendor
ADD IsVirtualLocationEnabled bit null
GO


INSERT INTO ProgramConfiguration
SELECT 1,7,4,NULL,NULL,'MotorhomeReimbursementClaim','Yes',1,NULL,GETDATE(),'system',NULL,NULL


INSERT INTO ProgramConfiguration
SELECT (SELECT ID FROM Program WHERE Name = 'Ford') ,7,4,NULL,NULL,'RoadsideReimbursementClaim','Yes',1,NULL,GETDATE(),'system',NULL,NULL
