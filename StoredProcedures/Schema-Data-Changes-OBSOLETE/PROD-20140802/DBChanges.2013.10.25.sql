
ALTER TABLE MEMBER
ADD AccountSource nvarchar(50) NULL

IF NOT EXISTS ( SELECT * FROM [Event] WHERE Name = 'UpdateInformation')
BEGIN
INSERT INTO Event values(
(Select ID from EventType where Name='User'),
(Select ID from EventCategory where Name='VendorPortal'),
'UpdateInformation','Update User Information',1,1,'system',GETDATE())
END

IF NOT EXISTS ( SELECT * FROM [Event] WHERE Name = 'UpdatePassword')
BEGIN
INSERT INTO Event values((Select ID from EventType where Name='User'),
(Select ID from EventCategory where Name='VendorPortal'),'UpdatePassword','Update Password',1,1,'system',GETDATE())
END
