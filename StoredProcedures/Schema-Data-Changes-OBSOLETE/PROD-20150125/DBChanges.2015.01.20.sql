--
-- Dispatch
-- ODIS
-- SCRIPT to load new entries into HagertyProgramMap table
--


IF NOT EXISTS(SELECT * FROM Program where Name='Hagerty Employee')
BEGIN
INSERT INTO Program(ParentProgramID,ClientID,Code,Name,[Description],IsActive) VALUES
(
	(SELECT ID FROM Program where Name='Hagerty' AND ParentProgramID = NULL ),
	(Select ID FROM Client where Name='Hagerty'),
	'HagertyEmployee',
	'Hagerty Employee',
	'Hagerty Employee',
	1
)
END

IF NOT EXISTS(SELECT * FROM Program where Name='Hagerty VIP')
BEGIN
INSERT INTO Program(ParentProgramID,ClientID,Code,Name,[Description],IsActive) VALUES
(
	(SELECT ID FROM Program where Name='Hagerty' AND ParentProgramID = NULL ),
	(Select ID FROM Client where Name='Hagerty'),
	'HagertyVIP',
	'Hagerty VIP',
	'Hagerty VIP',
	1
)
END

---- Insert new rows in Hagerty Mapping Table
IF NOT EXISTS (SELECT ID FROM HagertyProgramMap WHERE CustomerType='E' AND PlanType='Employee Plan')
BEGIN
	INSERT HagertyProgramMap (CustomerType, PlanType, ProgramID)
	VALUES ('E', 'Employee Plan', (SELECT ID FROM Program WHERE Name = 'Hagerty Employee') )
END

IF NOT EXISTS (SELECT ID FROM HagertyProgramMap WHERE CustomerType='H' AND PlanType='125 Mile')
BEGIN
	INSERT HagertyProgramMap (CustomerType, PlanType, ProgramID)
	VALUES ('H', '125 Mile', (SELECT ID FROM Program WHERE Name = 'Hagerty VIP') )
END


-- Verify data 
--select * from HagertyProgramMap order by customertype, ID