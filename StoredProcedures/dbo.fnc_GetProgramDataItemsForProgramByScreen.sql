/****** Object:  UserDefinedFunction [dbo].[fnc_GetProgramDataItemsForProgramByScreen]    Script Date: 04/29/2014 02:13:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetProgramDataItemsForProgramByScreen]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_GetProgramDataItemsForProgramByScreen]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnc_GetProgramDataItemsForProgramByScreen] (@ProgramID int, @ScreenName varchar(50))
RETURNS @ProgramDataItemsForProgramByScreen TABLE
   (
    ProgramDataItemID     int,
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
		INSERT @ProgramDataItemsForProgramByScreen 
		SELECT ID, Name FROM ProgramDataItem Where ProgramID = @pid
		AND Name not in (SELECT Distinct Name from @ProgramDataItemsForProgramByScreen)
		AND IsActive = 1
		ORDER BY Sequence 
	
END

 		

RETURN 

END
GO
