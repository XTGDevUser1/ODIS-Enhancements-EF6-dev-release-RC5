--NP 02/17: Execute statement by statement.

ALTER TABLE UserPasswordHistory
ADD PasswordSalt nvarchar(128)

INSERT INTO UserPasswordHistory(aspnet_UserId,[Password],InitialUseDate,CreateBy,CreateDate,PasswordSalt) 
Select am.UserId,am.[Password],GETDATE(),'system',GETDATE(),am.PasswordSalt 
from aspnet_Membership am 
Join aspnet_Users au on au.UserID = am.UserID
Where Not Exists (
	Select *
	From UserPasswordHistory uph
	Where uph.aspnet_UserID = au.UserID)
