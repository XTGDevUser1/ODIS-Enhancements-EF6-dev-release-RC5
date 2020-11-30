
IF NOT EXISTS(SELECT * FROM SourceSystem where Name='WebService')
BEGIN
	INSERT INTO SourceSystem VALUES (
		'WebService',
		'Web Service',
		(SELECT MAX(Sequence) FROM SourceSystem) + 1,
		1
	)
END

IF NOT EXISTS(SELECT * FROM CallType where Name = 'WebService')
BEGIN
	INSERT INTO CallType VALUES (
		'WebService',
		'Web Service',
		(SELECT ID FROM ContactCategory where Name = 'NewCall'),
		(SELECT MAX(Sequence) FROM CallType) + 1,
		0
	)
END

