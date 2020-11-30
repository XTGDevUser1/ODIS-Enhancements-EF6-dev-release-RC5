/* dms_programs_for_call_list */
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_programs_for_call_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_programs_for_call_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_programs_for_call_list] @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
  CREATE PROCEDURE [dbo].[dms_programs_for_call_list](   
   @userID UNIQUEIDENTIFIER = NULL  
 )   
 AS   
 BEGIN   
 --Get Programs for user by data group and then traverse up the parent hierarchy until you get the programs associated with an 800 number  
    
  SET NOCOUNT ON  
   
 ;WITH wProgram  
  AS  
  (  
   SELECT PLIST.ProgramID AS Id,   
     PLIST.ProgramName AS Name  
   FROM [dbo].[fnc_GetProgramsForUser](@UserID) PLIST  
   JOIN [dbo].[Program] P ON PLIST.ProgramID = P.ID
   JOIN PhoneSystemConfiguration PSC WITH (NOLOCK) ON PSC.ProgramId = PLIST.ProgramId  
   WHERE ISNULL(PSC.InboundNumber, '') <> ''  
   AND PSC.IsActive = 1
   AND PSC.IsShownOnScreen = 1 
   -- CR : 1093
   --AND ISNULL(P.IsGroup,0) = 1
       
   UNION ALL  
     
   SELECT P.Id,   
     P.Name   
   FROM Program P   
   JOIN wProgram wP ON P.ParentProgramID = wP.ID    
   JOIN PhoneSystemConfiguration PSC WITH (NOLOCK) ON PSC.ProgramId = P.Id  
   WHERE ISNULL(PSC.InboundNumber, '') <> ''   
   AND P.IsActive = 1  
   AND PSC.IsActive = 1
   AND PSC.IsShownOnScreen = 1
   -- CR : 1093
   --AND ISNULL(P.IsGroup,0) = 1
     
  )  
  
    
  SELECT DISTINCT ID, Name from wProgram  
  ORDER BY Name  
   
END  
  