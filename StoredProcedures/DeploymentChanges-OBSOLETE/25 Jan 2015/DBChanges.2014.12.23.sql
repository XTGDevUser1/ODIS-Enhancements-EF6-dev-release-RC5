ALTER TABLE Member ADD ClientMemberType NVARCHAR(50) NULL


IF NOT EXISTS (SELECT * FROM ProductProvider WHERE Name = 'Warrantech')
BEGIN
	INSERT ProductProvider (Name, Description, PhoneNumber, Website, Script, IsActive)
	VALUES ('Warrantech', 'Warrantech', '877-264-9683', 'www.warrantech.com', 'This member is covered by a service contract and the repair work may be covered, please call for approval prior to any work being performed. You should contact Warrantech at 800-111-1111.', 1)
END
ELSE
BEGIN
	UPDATE ProductProvider SET PhoneNumber='877-264-9683' WHERE Name = 'Warrantech'
END

IF NOT EXISTS (SELECT * FROM ProductProvider WHERE Name = 'SouthwestRe')
BEGIN
	INSERT ProductProvider (Name, Description, PhoneNumber, Website, Script, IsActive)
	VALUES ('SouthwestRe', 'SouthwestRe', '866-444-1601', 'www.southwestre.com', 'This member is covered by a service contract and the repair work may be covered, please call for approval prior to any work being performed. You should contact SouthwestRe at 800-222-2222.', 1)
END
ELSE
BEGIN
	UPDATE ProductProvider SET PhoneNumber='866-444-1601' WHERE Name = 'SouthwestRe'
END

IF NOT EXISTS (SELECT * FROM ProductProvider WHERE Name = 'Coach-Net')
BEGIN
	INSERT ProductProvider (Name, Description, PhoneNumber, Website, Script, IsActive)
	VALUES ('Coach-Net', 'Coach-Net', '888-675-6573', 'www.coach-net.com', '', 1)
END
ELSE
BEGIN
	UPDATE ProductProvider SET PhoneNumber='888-675-6573' WHERE Name = 'Coach-Net'
END

