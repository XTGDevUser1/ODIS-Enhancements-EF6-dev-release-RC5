IF EXISTS (SELECT * FROM dbo.sysobjects 
	WHERE id = object_id(N'[dbo].[dms_service_eligibility_messages_get]')  AND type in (N'P', N'PC')) 
 BEGIN
	DROP PROCEDURE [dbo].[dms_service_eligibility_messages_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dbo].[dms_service_eligibility_messages_get] 7, 'MemberMobile' 
CREATE PROCEDURE [dbo].[dms_service_eligibility_messages_get]
(
	@programID INT,
	@sourceSystem NVARCHAR(MAX) = 'Dispatch'
)
AS
BEGIN

	--DECLARE @programID INT = 3,
	--		@sourceSystem NVARCHAR(MAX) = 'MemberMobile'
	DECLARE @sourceSystemID INT = (SELECT ID FROM SourceSystem WHERE Name = @sourceSystem)
	DECLARE @sourceSystemPriority INT
	DECLARE @defaultProgramIDForNull INT = 99999

	DECLARE @sourceSystemFallbackSequence TABLE
	(
		[Sequence] INT IDENTITY(1,1),
		SourceSystemID INT
	)

	DECLARE @relevantPrograms TABLE
	(
		ProgramID INT,
		[Sequence] INT
	)
	-- Grab all the parent programs + give a value to a null program for use in comparison against DSE messages set up with ProgramID = NULL
	INSERT INTO @relevantPrograms
	SELECT	PP.ProgramID,
			PP.[Sequence]
	FROM	[dbo].[fnc_GetProgramsandParents](@programID) PP
	UNION ALL
	-- insert the default Program (Used to compare DSEs with ProgramID = NULL)
	SELECT	@defaultProgramIDForNull,
			@defaultProgramIDForNull

	-- Define the fallback sequence
	INSERT INTO @sourceSystemFallbackSequence
	SELECT ID FROM SourceSystem WHERE Name = 'Dispatch'
	UNION ALL
	SELECT ID FROM SourceSystem WHERE Name = 'MemberMobile'

	SET @sourceSystemPriority = (SELECT [Sequence] FROM @sourceSystemFallbackSequence WHERE SourceSystemID = @sourceSystemID)

	-- Get all the messages defined for the program and it's parents (including the ones set up with program id = null) and the given source system.
	;WITH wDSEMessages
	AS
	(
		SELECT	SE.Name, 
				SE.[Message],
				SS.Name AS SourceSystemName,
				PP.[Sequence] AS ProgramLevel,
				PP.ProgramID,
				SSS.[Sequence] AS SourceSystemSequence,
				ROW_NUMBER() OVER (PARTITION BY SE.Name ORDER BY SSS.[Sequence] DESC,PP.[Sequence] ASC) AS RowNumber
		FROM	ServiceEligibilityMessage SE WITH (NOLOCK)
		JOIN	@relevantPrograms PP ON PP.ProgramID = ISNULL(SE.ProgramID,@defaultProgramIDForNull)
		JOIN	SourceSystem SS WITH (NOLOCK) ON SS.ID = SE.SourceSystemID
		JOIN	@sourceSystemFallbackSequence SSS ON SS.ID = SSS.SourceSystemID
		WHERE	SSS.[Sequence] <= @sourceSystemPriority
		AND		ISNULL(SE.IsActive,0) = 1
	)

	SELECT * FROM wDSEMessages WHERE RowNumber = 1 ORDER BY Name

END
