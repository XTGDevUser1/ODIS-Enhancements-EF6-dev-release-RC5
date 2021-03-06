
/****** Object:  UserDefinedFunction [dbo].[fnc_GetProgramDataItemsForProgram]    Script Date: 11/02/2012 13:23:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fnc_GetProgramDataItemsForProgram] (@ProgramID int, @ScreenName nvarchar(50))
RETURNS @ProgramDataItemsForProgramByScreen TABLE
   (
    ProgramDataItemID     int
   )
AS
BEGIN
  	--Get all program data items starting at child level and working up the parent hierarchy
 
		--;WITH wProgramDataItems
		--AS
		--(
		--	SELECT DISTINCT PDI.ID AS [ProgramDataItemID],
		--    PDI.ProgramID,
		--    PDI.Name,
		--    P.ParentProgramID,
		--	0 as Iteration,
		--    PDI.Sequence 
		--	FROM ProgramDataItem PDI
		--	JOIN Program P ON P.ID = PDI.ProgramID 
		--	WHERE ProgramID = 
		--	(SELECT TOP 1 PDI.ProgramID 
		--							FROM ProgramDataItem PDI
		--							JOIN fnc_GetProgramsandParents(@ProgramID) fnc ON fnc.ProgramID = PDI.ProgramID
		--							ORDER BY fnc.Sequence)
		--	AND ScreenName = @ScreenName 
		--	AND PDI.IsActive = 1
			
		--	UNION ALL
			
		--	SELECT PDI.ID as [ProgramDataItemID],
		--	PDI.ProgramID,
		--	PDI.Name,
		--	P.ParentProgramID,
		--	wP.Iteration + 1,
		--	PDI.Sequence
		--	FROM ProgramDataItem PDI
		--	JOIN wProgramDataItems wP ON PDI.ProgramID = wP.ParentProgramID  
		--	JOIN Program P ON P.ID = PDI.ProgramID 	
		--	WHERE PDI.ScreenName = @ScreenName AND P.IsActive = 1 AND PDI.IsActive = 1
		--	AND PDI.Name <> wP.Name --Do not get items already defined at previous level
		--)

		;WITH wProgramDataItems
		AS
		(	SELECT ROW_NUMBER() OVER ( PARTITION BY PDI.Name ORDER BY PP.Sequence) AS RowNum,
					PDI.ID AS [ProgramDataItemID],
		    PDI.ProgramID,
		    PDI.Name,		    			
		    PP.Sequence 	
			FROM fnc_GetProgramsandParents(@ProgramID) PP
			JOIN ProgramDataItem PDI WITH (NOLOCK) ON PP.ProgramID = PDI.ProgramID
			WHERE	PDI.ScreenName = @screenName 
			AND PDI.IsActive = 1			
		)

		INSERT @ProgramDataItemsForProgramByScreen 
		SELECT ProgramDataItemID from wProgramDataItems p
		ORDER BY Sequence 

RETURN 

END