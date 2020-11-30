
--
-- TRAINING setup accounts
--
-- Use this script to create training accounts after the training database has been refreshed from Production

-- Current Training Account Setup
--select * from aspnet_Users where username like 'train%' order by UserName
--select * from [User] where firstname like 'Train%' order by lastname
--select * from aspnet_membership m join aspnet_users u on m.userid = u.userid where u.username like 'Train%'
--select * from aspnet_UsersInRoles uir join aspnet_users u on uir.userid = u.userid join aspnet_Roles r on r.roleid = uir.roleid where u.username like 'Train%'

-- DELETE EXISTING TRAIN ACCOUNTS
--DELETE [User] WHERE firstName like 'Train%'
--DELETE aspnet_UsersInRoles WHERE UserID IN (SELECT UserID FROM aspnet_Users WHERE UserName like 'Train%')
--DELETE aspnet_Membership WHERE UserID IN (SELECT UserID FROM aspnet_Users WHERE UserName like 'Train%')
--DELETE aspnet_Users WHERE UserName Like 'Train%'

-- INSERT NEW TRAIN ACCOUNTS
DECLARE @ApplicationID UNIQUEIDENTIFIER
DECLARE @aspnet_RoleID UNIQUEIDENTIFIER
DECLARE @OrganizationID INT

SET @ApplicationID = (SELECT ApplicationID FROM aspnet_Applications WHERE ApplicationName = 'DMS')
SET @aspnet_RoleID = (SELECT RoleID FROM aspnet_Roles WHERE ApplicationID = @ApplicationID AND RoleName = 'Agent')
SET @OrganizationID = (SELECT ID FROM Organization WHERE Name = 'NMC')

DECLARE @ProcessingCounter AS INT = 1
DECLARE @NumberOfUsers INT
SET @NumberOfUsers = 25

WHILE @ProcessingCounter <= @NumberOfUsers
	BEGIN

		DECLARE @aspnet_UserID UNIQUEIDENTIFIER
		DECLARE @UserName NVARCHAR(256)	
		DECLARE @LoweredUserName NVARCHAR(50)
		DECLARE @Password NVARCHAR(128)
		DECLARE @PasswordSalt NVARCHAR(128)
		DECLARE @Email NVARCHAR(256)
		DECLARE @LoweredEmail NVARCHAR(256)
		DECLARE @FirstName NVARCHAR(50)
		DECLARE @LastName NVARCHAR(50)
		DECLARE @AgentNumber NVARCHAR(4)
		DECLARE @PhoneUserID NVARCHAR(50)
		DECLARE @PhonePassword NVARCHAR(50)
		
		SET @aspnet_UserID = newid()
		SET @UserName = ('Train' + convert(nvarchar(2),@ProcessingCounter))
		SET @LoweredUserName = ('train' + convert(nvarchar(2),@ProcessingCounter))
		SET @Password = N'4R3RgwiBrv5PkbhuqREbhPJbBeg=' ---- nmcps@800
		SET @PasswordSalt = 'vwFxs/N5KjgSH2UgNDMd+Q=='
		SET @Email = ('Train' + convert(nvarchar(2),@ProcessingCounter) + '@nmc.com')
		SET @LoweredEmail = ('train' + convert(nvarchar(2),@ProcessingCounter) + '@nmc.com') 
		SET @FirstName = 'Train'
		SET @LastName = convert(nvarchar(50),@ProcessingCounter)
		SET @AgentNumber = '1111'
		SET @PhoneUserID = ('train' + convert(nvarchar(2),@ProcessingCounter))
		SET @PhonePassword = '12345'
				
		-- Insert Account Records:
		
		-- Insert aspnet_Users
		IF NOT EXISTS(SELECT * FROM aspnet_Users WHERE Username = @UserName)
			BEGIN
				INSERT INTO aspnet_Users
					(UserID
					,ApplicationID
					,UserName
					,LoweredUserName
					,MobileAlias
					,IsAnonymous
					,LastActivityDate
					)
				VALUES
					(@aspnet_UserID
					,@ApplicationID
					,@UserName
					,@LoweredUserName
					,NULL
					,0
					,'1754-01-01 00:00:00.000'
					)
			END

		-- Insert aspnet_Membership
		IF NOT EXISTS(SELECT * FROM aspnet_Membership WHERE UserID = @aspnet_UserID)
			BEGIN
				INSERT INTO aspnet_Membership
					(UserID
					,ApplicationID
					,[Password]
					,PasswordFormat
					,PasswordSalt
					,MobilePIN
					,Email
					,LoweredEmail
					,PasswordQuestion
					,PasswordAnswer
					,IsApproved
					,IsLockedOut
					,CreateDate
					,LastLoginDate
					,LastPasswordChangedDate
					,LastLockoutDate
					,FailedPasswordAttemptCount
					,FailedPasswordAttemptWindowStart
					,FailedPasswordAnswerAttemptCount
					,FailedPasswordAnswerAttemptWindowStart
					,Comment
					)
				VALUES
					(@aspnet_UserID
					,@ApplicationID
					,@Password
					,1
					,@PasswordSalt
					,NULL
					,@Email 
					,@LoweredEmail 
					,NULL
					,NULL
					,1
					,0
					,getdate()
					,'1754-01-01 00:00:00.000'
					,getdate()
					,'1754-01-01 00:00:00.000'
					,0
					,'1754-01-01 00:00:00.000'
					,0
					,'1754-01-01 00:00:00.000'
					,NULL
					)
			END

		-- Insert aspnet_UsersInRoles
		IF NOT EXISTS(SELECT * FROM aspnet_UsersInRoles WHERE UserID = @aspnet_UserID)
			BEGIN
				INSERT INTO aspnet_UsersInRoles
					(UserID
					,RoleID
					)
				VALUES
					(@aspnet_UserID
					,@aspnet_RoleID
					)
			END

		-- Insert [User]
		IF NOT EXISTS(Select * from [User] where aspnet_UserID = @aspnet_UserID)
			BEGIN
				INSERT INTO [User]
					(OrganizationID
					,aspnet_UserID
					,FirstName
					,LastName
					,AgentNumber
					,PhoneUserID
					,PhonePassword
					,CreateDate
					,CreateBy
					,ModifyDate
					,ModifyBy
					)
				VALUES
					(@OrganizationID
					,@aspnet_UserID
					,@FirstName
					,@LastName 
					,@AgentNumber
					,@PhoneUserID 
					,@PhonePassword
					,getdate()
					,'System'
					,NULL
					,NULL
					)
			END
			
		SET @ProcessingCounter = @ProcessingCounter + 1
		
	END



-- Verify
SELECT * FROM [User] WHERE aspnet_UserID IN (SELECT UserID FROM aspnet_Users WHERE UserName like 'Train%')
SELECT * FROM aspnet_UsersInRoles WHERE UserID IN (SELECT UserID FROM aspnet_Users WHERE UserName like 'Train%')
SELECT * FROM aspnet_Membership WHERE UserID IN (SELECT UserID FROM aspnet_Users WHERE UserName like 'Train%')
SELECT * FROM aspnet_Users WHERE UserName Like 'Train%'
