/****** Object:  UserDefinedFunction [dbo].[fnc_GetProgramConfigurationForProgramAndParents]    Script Date: 04/29/2014 02:13:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetProgramConfigurationForProgramAndParents]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_GetProgramConfigurationForProgramAndParents]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnc_GetProgramConfigurationForProgramAndParents] (@ProgramID int)
RETURNS @ProgramConfiguration TABLE
   (
    ProgramConfigurationID     int,
    Name nvarchar(50)
   )
AS
BEGIN

DECLARE @pid int;

DECLARE program_cursor CURSOR FOR SELECT ProgramID FROM fnc_GetProgramsandParents(@ProgramID)
OPEN program_cursor

FETCH NEXT FROM program_cursor INTO @pid; 

WHILE @@FETCH_STATUS = 0

BEGIN
		INSERT @ProgramConfiguration
		SELECT ID, Name FROM ProgramConfiguration Where ProgramID = @pid
		AND Name not in (SELECT Distinct Name from @ProgramConfiguration)
		AND IsActive = 1
		ORDER BY Sequence 
	
END

 		

RETURN 

END
GO
