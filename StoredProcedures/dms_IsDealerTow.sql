
/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_IsDealerTow]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_IsDealerTow]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC  [dbo].[dms_IsDealerTow]

 CREATE PROCEDURE [dbo].[dms_IsDealerTow](
 @programID int
 )
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

SELECT pc.* FROM 
ProgramConfiguration pc
JOIN fnc_GetProgramConfigurationForProgram(@programID,'Service') fnc ON fnc.ProgramConfigurationID = pc.ID 
WHERE pc.Name = 'IsDealerTow'

END