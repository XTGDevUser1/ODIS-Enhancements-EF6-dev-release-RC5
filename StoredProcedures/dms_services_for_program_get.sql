 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_services_for_program_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_services_for_program_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 -- EXEC [dbo].[dms_services_for_program_get] 36,'Service'
 CREATE PROCEDURE [dbo].[dms_services_for_program_get]( 
   @programID INT,   
   @productCategory nvarchar(50)
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
	
	SELECT	FP.ProductCategory AS Name,
			MIN(PP.ServiceCoverageLimit) AS LowerLimit,
			MAX(PP.ServiceCoverageLimit) AS UpperLimit
	FROM	[dbo].[fnc_GetProgramProductForProgram](@programID,@productCategory) FP
	JOIN	ProgramProduct PP ON PP.ID = FP.ProgramProductID
	GROUP BY FP.ProductCategory
END
