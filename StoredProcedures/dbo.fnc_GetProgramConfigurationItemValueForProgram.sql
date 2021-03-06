/****** Object:  UserDefinedFunction [dbo].[fnc_GetProgramsForUser]    Script Date: 09/03/2012 15:48:18 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetProgramConfigurationItemValueForProgram]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_GetProgramConfigurationItemValueForProgram]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fnc_GetProgramConfigurationItemValueForProgram] (
													@ProgramID int, 
													@ConfigurationType nvarchar(50), 
													@ConfigurationCategory NVARCHAR(50),
													@configName NVARCHAR(50))
RETURNS NVARCHAR(MAX)
AS
BEGIN

		DECLARE @programConfigValue NVARCHAR(MAX) = NULL		
		

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
			LEFT JOIN ConfigurationCategory CC ON PC.ConfigurationCategoryID = CC.ID
			WHERE	(@ConfigurationType IS NULL OR C.Name = @ConfigurationType)
			AND		(@ConfigurationCategory IS NULL OR CC.Name = @ConfigurationCategory)
		)

		SELECT @programConfigValue = W.Value  
		FROM	wProgramConfig W
		WHERE	W.RowNum = 1
		AND		W.Name = @configName
		ORDER BY Sequence
	
		

		RETURN @programConfigValue

END





