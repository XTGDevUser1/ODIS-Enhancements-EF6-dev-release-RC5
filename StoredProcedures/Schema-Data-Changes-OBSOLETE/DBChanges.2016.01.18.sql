ALTER TABLE Member
ADD MemberNumber NVARCHAR(50) NULL

ALTER TABLE Member
ADD SellerVendorID INT NULL

ALTER TABLE [dbo].[Member]  WITH CHECK ADD  CONSTRAINT [FK_Member_Vendor] FOREIGN KEY([SellerVendorID])
REFERENCES [dbo].[Vendor] ([ID])
GO
ALTER TABLE [dbo].[Member] CHECK CONSTRAINT [FK_Member_Vendor]
GO


ALTER TABLE Vendor
ADD ClientVendorKey NVARCHAR(50) NULL

ALTER TABLE Vendor
ADD ClientID INT NULL

ALTER TABLE [dbo].[Vendor]  WITH CHECK ADD  CONSTRAINT [FK_Vendor_Client] FOREIGN KEY([ClientID])
REFERENCES [dbo].[Client] ([ID])
GO
ALTER TABLE [dbo].[Vendor] CHECK CONSTRAINT [FK_Vendor_Client]
GO

DECLARE @expirationDateSecurableID INT,
		@editNameSecurableID INT,
		@editProgramSecurableID INT,
		@expirationDateSecurableName NVARCHAR(100) = 'BUTTON_MEMBER_EDIT_EXPIRATION',
		@editNameSecurableName NVARCHAR(100) = 'BUTTON_MEMBER_EDIT_NAME',
		@editProgramSecurableName NVARCHAR(100) = 'BUTTON_MEMBER_EDIT_PROGRAM'
SELECT @expirationDateSecurableID = ID FROM Securable where FriendlyName = @expirationDateSecurableName

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = @editNameSecurableName)
BEGIN
	INSERT INTO Securable
	SELECT @editNameSecurableName,NULL,NULL

	SELECT @editNameSecurableID = SCOPE_IDENTITY()

	INSERT INTO AccessControlList
	SELECT @editNameSecurableID, RoleID,AccessTypeID
	FROM	AccessControlList
	WHERE	SecurableID = @expirationDateSecurableID

END

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = @editProgramSecurableName)
BEGIN
	INSERT INTO Securable
	SELECT @editProgramSecurableName,NULL,NULL

	SELECT @editProgramSecurableID = SCOPE_IDENTITY()

	INSERT INTO AccessControlList
	SELECT @editProgramSecurableID, RoleID,AccessTypeID
	FROM	AccessControlList
	WHERE	SecurableID = @expirationDateSecurableID

END
GO