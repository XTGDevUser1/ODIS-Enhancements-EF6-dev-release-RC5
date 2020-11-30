
DECLARE @vendorRepRoleID UNIQUEIDENTIFIER
SET		@vendorRepRoleID = (SELECT RoleID FROM aspnet_Roles WHERE LoweredRoleName = 'vendorrep' AND ApplicationId = (SELECT ApplicationId FROM aspnet_Applications WHERE LoweredApplicationName = 'dms'))


DECLARE @sysAdminRoleID UNIQUEIDENTIFIER
SET		@sysAdminRoleID = (SELECT RoleID FROM aspnet_Roles WHERE LoweredRoleName = 'sysadmin' AND ApplicationId = (SELECT ApplicationId FROM aspnet_Applications WHERE LoweredApplicationName = 'dms'))

DECLARE @securableID INT

DECLARE @accessTypeID INT 
SET @accessTypeID = (SELECT ID FROM AccessType WHERE Name = 'ReadWrite')

IF EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_VENDOR_ACTIVITY_ADD_COMMENT')
BEGIN
	SET @securableID = (SELECT ID FROM Securable WHERE FriendlyName = 'BUTTON_VENDOR_ACTIVITY_ADD_COMMENT')
	IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @securableID AND RoleID=@sysAdminRoleID AND AccessTypeID = @accessTypeID)
	BEGIN
	--SELECT * FROM AccessControlList WHERE SecurableID = @securableID AND RoleID=@sysAdminRoleID AND AccessTypeID = @accessTypeID
		INSERT INTO AccessControlList(SecurableID,RoleID,AccessTypeID) VALUES(@securableID,@sysAdminRoleID,@accessTypeID) 
	END
END

IF  EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_VENDOR_ACTIVITY_ADD_CONTACT')
BEGIN 
	SET @securableID = (SELECT ID FROM Securable WHERE FriendlyName = 'BUTTON_VENDOR_ACTIVITY_ADD_CONTACT')
	IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @securableID AND RoleID=@sysAdminRoleID AND AccessTypeID = @accessTypeID)
	BEGIN
		--SELECT * FROM AccessControlList WHERE SecurableID = @securableID AND RoleID=@sysAdminRoleID AND AccessTypeID = @accessTypeID
		INSERT INTO AccessControlList(SecurableID,RoleID,AccessTypeID) VALUES(@securableID,@sysAdminRoleID,@accessTypeID) 
	END
END



-- SET UP A NEW PHONETYPE VALUE - AlternateDispatch.

--
-- Setup AlternateDispatch phone type
--

DECLARE @EntityVL INT
DECLARE @EntityV INT
DECLARE @PhoneTypeAltDisp INT
DECLARE @PhoneTypeDispatch INT

SET @EntityVL = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
SET @EntityV = (SELECT ID FROM Entity WHERE Name = 'Vendor')
SET @PhoneTypeDispatch = (SELECT ID FROM PHoneType WHERE Name = 'Dispatch')

-- Create new phone type Alternate Dispatch
IF NOT EXISTS (SELECT * FROM PhoneType WHERE Name = 'AlternateDispatch') 
	BEGIN
		INSERT INTO PhoneType (Name, Description, IsActive, Sequence)
			VALUES ('AlternateDispatch', 'AltDispatch', 1, 10)
	END

SET @PhoneTypeAltDisp = (SELECT ID FROM PhoneType WHERE Name = 'AlternateDispatch')

-- Create link from new phonetype AltDispatch to VendorLocation
IF NOT EXISTS (SELECT * FROM PhoneTypeEntity WHERE EntityID = @EntityVL AND PhoneTypeID = @PhoneTypeAltDisp)
	BEGIN
		INSERT INTO PhoneTypeEntity (EntityID, PhoneTypeID, IsShownOnScreen, Sequence)
			VALUES (@EntityVL, @PhoneTypeAltDisp, 1, 6)
	END

-- Remove
IF EXISTS (SELECT * FROM PhoneTypeEntity WHERE EntityID = @EntityV AND PhoneTypeID = @PhoneTypeDispatch)
	BEGIN
		DELETE FROM PhoneTypeEntity WHERE EntityID = @EntityV AND PhoneTypeID = @PhoneTypeDispatch
	END


	GO

-- CHANGE ISPSelectionLog table

ALTER TABLE ISPSelectionLog
ADD [AlternateDispatchPhoneNumber] [nvarchar](50) NULL -- TFS: 105

GO

-- UPDATE Second dispatch number of VendorLocation to be Alternate DispatchNumber

DECLARE @altDispatchPhoneTypeID INT = NULL
SET @altDispatchPhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'AlternateDispatch')


;WITH wDispatchPhoneNumbers
AS
(
SELECT	ROW_NUMBER() OVER ( PARTITION BY PE.RecordID ORDER BY PE.RecordID ASC) AS RowNumber,
		PE.*
FROM	PhoneEntity PE
WHERE	PE.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
AND		PE.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Dispatch')
)

UPDATE wDispatchPhoneNumbers
SET		PhoneTypeID = @altDispatchPhoneTypeID
WHERE	RowNumber = 2

GO