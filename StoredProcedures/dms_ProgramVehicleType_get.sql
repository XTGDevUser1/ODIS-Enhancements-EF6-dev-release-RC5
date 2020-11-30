/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ProgramVehicleType_get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_ProgramVehicleType_get]
GO
/****** Object:  StoredProcedure [dbo].[dms_ProgramVehicleType_get]    Script Date: 07/03/2012 17:56:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC  [dbo].[dms_ProgramVehicleType_get] 3
 CREATE PROCEDURE [dbo].[dms_ProgramVehicleType_get]( 
   @ProgramID INT = NULL
 ) 
 AS 
 BEGIN 
  
	SET NOCOUNT ON
	
SELECT DISTINCT * 
FROM  ProgramVehicleType 
WHERE ProgramID IN ( 
      SELECT ProgramID FROM [dbo].[fnc_GetProgramsandParents](@ProgramID) )

END

