

/****** Object:  UserDefinedFunction [dbo].[fnc_GetProgramDispatchNumber]    Script Date: 01/02/2013 13:57:34 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetProgramDispatchNumber]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_GetProgramDispatchNumber]
GO



/****** Object:  UserDefinedFunction [dbo].[fnc_GetProgramDispatchNumber]    Script Date: 01/02/2013 13:57:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- SELECT * FROM [dbo].[fnc_GetProgramDispatchNumber] (NULL)  
CREATE FUNCTION [dbo].[fnc_GetProgramDispatchNumber] (@ProgramID int)  
RETURNS @ProgramDispatchNumber TABLE  
   (  
    ProgramID  int,  
    ProgramName  nvarchar(50),  
    ClientID  int,
    DispatchPhoneNumber nvarchar(50)  
   )  
AS 
BEGIN

;WITH wPrograms  
 AS  
 (  SELECT DISTINCT   
    P.ID,  
    P.Name ,  
    P.ClientID,
    PH.InboundNumber,
    1 as i
    FROM [Program] P   
    JOIN [dbo].[PhoneSystemConfiguration] PH ON PH.ProgramID = P.ID
    WHERE P.IsActive = 1  
    --AND P.ID = @ProgramID 
     
    UNION ALL  
     
   SELECT P.ID ,  
       P.Name,   
       P.ClientID,
       wP.InboundNumber,
       wp.i + 1 as i
   FROM Program P  
   JOIN wPrograms wP ON P.ParentProgramID = wP.ID  
   WHERE P.IsActive = 1  
  )  
  
  INSERT INTO @ProgramDispatchNumber
  SELECT ID,Name,ClientID,InboundNumber 
  FROM wPrograms p 
  WHERE (p.ID = @ProgramID OR @ProgramID IS NULL) 
  AND i = 1
  
  RETURN
  
 END
    
