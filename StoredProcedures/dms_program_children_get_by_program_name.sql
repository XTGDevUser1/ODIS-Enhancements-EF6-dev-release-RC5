IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_program_children_get_by_program_name]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_program_children_get_by_program_name] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
-- EXEC [dbo].[dms_program_children_get_by_program_name] 'Hagerty'

CREATE PROC [dbo].[dms_program_children_get_by_program_name](
@programName NVARCHAR(255)
)
AS
BEGIN

	DECLARE @programID INT = NULL
	
	SELECT	@programID = ID
	FROM	Program P WITH (NOLOCK)
	WHERE	P.Name = @programName
	AND		P.ParentProgramID IS NULL
	
	SELECT FP.ProgramID,
		   P.Name AS ProgramName,
		   FP.ClientID	
	FROM [dbo].[fnc_GetChildPrograms](@programID) FP
	JOIN Program P ON FP.ProgramID = P.ID
	WHERE ISNULL(P.IsGroup,0) = 0 -- CR: 1049 : Exclude "Group" programs
END
GO
