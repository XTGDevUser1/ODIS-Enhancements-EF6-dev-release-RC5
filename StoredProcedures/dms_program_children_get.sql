IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_program_children_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_program_children_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
-- EXEC [dbo].[dms_program_children_get] 3

CREATE PROC [dbo].[dms_program_children_get](
@programID INT
)
AS
BEGIN
	SELECT FP.ProgramID,
		   P.Name AS ProgramName,
		   FP.ClientID	
	FROM [dbo].[fnc_GetChildPrograms](@programID) FP
	JOIN Program P ON FP.ProgramID = P.ID
	WHERE ISNULL(P.IsGroup,0) = 0 -- CR: 1049 : Exclude "Group" programs
END
GO
