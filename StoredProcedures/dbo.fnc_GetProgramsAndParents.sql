
/****** Object:  UserDefinedFunction [dbo].[fnc_GetProgramsandParents]    Script Date: 11/02/2012 12:19:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fnc_GetProgramsandParents] ( @ProgramID int )
RETURNS @ProgramsandParents TABLE
   (
    ProgramID     int,
    Sequence	  int
   )
AS
BEGIN


		;WITH wPrograms
		AS
		(
			SELECT DISTINCT P.ID AS [ProgramID],		   
				   P.ParentProgramID,
				   0 as Iteration
			FROM Program P
			WHERE P.ID = @ProgramID 
			AND P.IsActive = 1
			
			UNION ALL
			
			SELECT P.ID AS [ProgramID],		   
				   P.ParentProgramID, 
				   wP.Iteration + 1 as Iteration
			FROM	Program P
			JOIN wPrograms wP ON P.ID = wP.ParentProgramID
			WHERE	P.IsActive = 1
		)

		INSERT @ProgramsandParents  
		SELECT DISTINCT ProgramID, ROW_NUMBER() OVER(ORDER BY Iteration) from wPrograms p
		

RETURN 

END