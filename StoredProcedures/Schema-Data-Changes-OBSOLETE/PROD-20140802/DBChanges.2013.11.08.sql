
IF NOT EXISTS ( SELECT * FROM [Event] where Name = 'OverrideServiceRating')
BEGIN
INSERT INTO [Event] values
(
(Select ID from EventType where Name='System'),
(Select ID from EventCategory where Name='Vendor'),
'OverrideServiceRating',
'Override vendor service rating',
0,1,'SYSTEM',null
)
END