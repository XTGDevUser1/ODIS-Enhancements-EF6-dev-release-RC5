IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetMemberSearchPrograms]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fnc_GetMemberSearchPrograms]
	GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fnc_GetMemberSearchPrograms] ( @programID INT )  
RETURNS @SearchPrograms TABLE  
   (  
    ProgramID  int,  
    ProgramName  nvarchar(50),  
    ClientID  int  
   )  
AS 
BEGIN

	--DECLARE @ProgramID int
	--SET @ProgramID = 9

	DECLARE @Programs TABLE (ProgramID int, ProgramName nvarchar(100), ClientID int)

	INSERT INTO @Programs
	SELECT ProgramID, ProgramName, ClientID 
	FROM [dbo].[fnc_GetChildPrograms] (@programID)

	INSERT INTO @SearchPrograms
	SELECT DISTINCT p1.ProgramID, p1.ProgramName, p1.ClientID 
	FROM @Programs p1
	JOIN Program p on p.ID = p1.ProgramID AND p.IsGroup = 0
	UNION
	SELECT p.ID ProgramID, p.Name ProgramName, p.ClientID 
	FROM MemberSearchProgramGrouping pg 
	JOIN Program p on p.ID = pg.ProgramID AND p.IsGroup = 0
	WHERE pg.[Grouping] IN (
		SELECT DISTINCT pg1.[Grouping]
		FROM MemberSearchProgramGrouping pg1
		JOIN @Programs p1 ON pg1.ProgramID = p1.ProgramID)	
	ORDER BY ProgramID

	RETURN
END
