/****** Object:  UserDefinedFunction [dbo].[fnc_GetOrganizationsForUser]    Script Date: 09/03/2012 15:48:18 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetChildPrograms]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_GetChildPrograms]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnc_GetChildPrograms] ( @programID INT )  
RETURNS @ProgramsForUser TABLE  
   (  
    ProgramID  int,  
    ProgramName  nvarchar(50),  
    ClientID  int  
   )  
AS 
BEGIN
;WITH wPrograms  
 AS  
 (  SELECT DISTINCT   
    P.ID,  
    P.Name ,  
    P.ClientID   
    FROM [Program] P   
    --JOIN [DataGroupProgram] DGP  ON DGP.ProgramID = P.ID  
    --JOIN [UserDataGroup] UDG  ON UDG.DataGroupID = DGP.DataGroupID  
    --JOIN    [User] U  ON U.ID = UDG.UserID   
    WHERE P.ID  = @programID  
    AND P.IsActive = 1  
     
    UNION ALL  
     
   SELECT P.ID ,  
       P.Name,   
       P.ClientID   
   FROM Program P  
   JOIN wPrograms wP ON P.ParentProgramID = wP.ID  
   WHERE P.IsActive = 1  
  )  
  INSERT @ProgramsForUser   
  -- KB: Exclude the current program from the list of children
  SELECT DISTINCT ID,Name,ClientID from wPrograms p ORDER BY Name  
  RETURN
 END
    