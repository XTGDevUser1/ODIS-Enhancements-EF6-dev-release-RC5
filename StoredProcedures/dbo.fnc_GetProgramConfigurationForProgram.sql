/****** Object:  UserDefinedFunction [dbo].[fnc_GetProgramsForUser]    Script Date: 09/03/2012 15:48:18 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetProgramConfigurationForProgram]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_GetProgramConfigurationForProgram]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fnc_GetProgramConfigurationForProgram] (@ProgramID int, @ConfigurationType nvarchar(50))
RETURNS @ProgramConfiguration TABLE
   (
    ProgramConfigurationID     int
   )
AS
BEGIN

/*KB: The following recursive query fails to get all the program configurations properly and therefore a simplified approach is implemented that gets correct values */			
		/*;WITH wProgramConfig
		AS
		(
			SELECT DISTINCT PC.ID,
			PC.ProgramID,
			P.ParentProgramID,
		    PC.Name,
		    0 as Iteration,
		    PC.Sequence 
			FROM ProgramConfiguration PC
			JOIN Program P on PC.ProgramID = P.ID
			JOIN ConfigurationCategory cc on cc.ID = PC.ConfigurationCategoryID 
			JOIN ConfigurationType ct on ct.ID = PC.ConfigurationTypeID 
			WHERE PC.ProgramID = (SELECT TOP 1 PC.ProgramID 
									FROM ProgramConfiguration PC
									JOIN fnc_GetProgramsandParents(@ProgramID) fnc ON fnc.ProgramID = pc.ProgramID
									ORDER BY fnc.Sequence) 
			AND ct.Name = @ConfigurationType  
			AND PC.IsActive = 1 AND P.IsActive = 1
			
			UNION ALL
			
			SELECT PC.ID,
			PC.ProgramID, 
			P.ParentProgramID,
			PC.Name,
			wP.Iteration + 1,
			PC.Sequence
			FROM ProgramConfiguration PC
			JOIN wProgramConfig wP ON PC.ProgramID = wP.ParentProgramID  
			JOIN Program P ON P.ID = PC.ProgramID 	
			JOIN ConfigurationCategory cc on cc.ID = PC.ConfigurationCategoryID 
			JOIN ConfigurationType ct on ct.ID = PC.ConfigurationTypeID 
			WHERE ct.Name = @ConfigurationType  
			AND PC.Name <> wP.Name --Do not get items already defined at previous level
			AND P.IsActive = 1 AND PC.IsActive = 1
		)*/
		
		

		;WITH wProgramConfig 
		AS
		(	SELECT ROW_NUMBER() OVER ( PARTITION BY PC.Name ORDER BY PP.Sequence) AS RowNum,
					PC.ID,
					PP.ProgramID,
					PP.Sequence,
					PC.Name,	
					PC.Value	
			FROM fnc_GetProgramsandParents(@ProgramID) PP
			JOIN ProgramConfiguration PC ON PP.ProgramID = PC.ProgramID AND PC.IsActive = 1
			JOIN ConfigurationType C ON PC.ConfigurationTypeID = C.ID 
			WHERE	C.Name = @ConfigurationType
		)

		INSERT @ProgramConfiguration 
		SELECT ID from wProgramConfig W
		WHERE	W.RowNum = 1
		ORDER BY Sequence
	
		

RETURN 

END





