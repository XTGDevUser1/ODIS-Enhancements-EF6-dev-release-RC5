/****** Object:  UserDefinedFunction [dbo].[fnc_GetProgramsForUser]    Script Date: 09/03/2012 15:48:18 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetProgramsForUser]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_GetProgramsForUser]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- SELECT * FROM [dbo].[fnc_GetProgramsForUser] (1)
CREATE FUNCTION [dbo].[fnc_GetProgramsForUser] ( @UserID UNIQUEIDENTIFIER )
RETURNS @ProgramsForUser TABLE
   (
    ProgramID		int,
    ProgramName		nvarchar(50),
    ClientID		int
   )
AS
BEGIN
 

IF EXISTS ( SELECT	* 
			FROM	UserDataGroup UDG
			JOIN [User] U ON U.ID = UDG.UserID 
			WHERE	U.aspnet_UserID  = @userID
		   )
 BEGIN
 --If data groups exist for user, then get programs included in those data groups and then get their children recursively 
		;WITH wPrograms
		AS
		(
		
			SELECT DISTINCT 
				P.ID,
 				P.Name ,
 				P.ClientID 
 			FROM	[Program] P 
			JOIN	[DataGroupProgram] DGP  ON DGP.ProgramID = P.ID
			JOIN	[UserDataGroup] UDG  ON UDG.DataGroupID = DGP.DataGroupID
			JOIN    [User] U  ON U.ID = UDG.UserID 
			WHERE	U.aspnet_UserID  = @UserID 
			AND P.IsActive = 1
			
			UNION ALL
			
			SELECT P.ID ,
				   P.Name, 
				   P.ClientID 
			FROM	Program P
			JOIN wPrograms wP ON P.ParentProgramID = wP.ID
			WHERE	P.IsActive = 1
		)
		
		INSERT @ProgramsForUser 
		SELECT DISTINCT ID,Name,ClientID from wPrograms p ORDER BY Name
 END	
ELSE

    --Otherwise, get all the clients for this user and then for each client get all the programs recursively
 
	BEGIN


		;WITH wPrograms
		AS
		(

			SELECT DISTINCT 
				P.ID,
				P.Name,
				P.ClientID 
			FROM fnc_GetOrganizationsForUser(@UserID) O 
			JOIN OrganizationClient OC ON OC.OrganizationID  = O.OrganizationID 
			JOIN  Client C ON OC.ClientID = C.ID 
			JOIN Program P ON P.ClientID = C.ID
			WHERE C.IsActive = 1 			
			AND P.IsActive = 1
						
			UNION ALL
			
			SELECT P.ID, 
				   P.Name,
				   P.ClientID
			FROM	Program P
			JOIN wPrograms wP ON P.ParentProgramID = wP.ID
			WHERE	P.IsActive = 1
		)

		INSERT @ProgramsForUser 
		SELECT DISTINCT ID,Name,ClientID from wPrograms p ORDER BY Name 
 END
RETURN 

END
