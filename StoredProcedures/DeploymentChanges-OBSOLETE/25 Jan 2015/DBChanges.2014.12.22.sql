IF NOT EXISTS(SELECT * FROM Entity where Name='CoachingConcern')
BEGIN
	INSERT INTO Entity(Name,IsAudited)
	VALUES (
				'CoachingConcern',
				0
			)

END

IF NOT EXISTS(Select * from DocumentCategory where Name='CoachingConcern')
BEGIN
	INSERT INTO DocumentCategory(Name,[Description],Sequence,IsActive)
	VALUES (
				'CoachingConcern',
				'Coaching Concern',
				7,
				1
			)
END