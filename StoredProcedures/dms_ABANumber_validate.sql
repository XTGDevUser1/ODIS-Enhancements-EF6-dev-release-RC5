IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ABANumber_validate]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ABANumber_validate] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_ABANumber_validate] @ABANumber = '238525069'
 CREATE PROCEDURE [dbo].[dms_ABANumber_validate](
 @ABANumber NVARCHAR(9)
 )
 AS
 BEGIN
 		
	SELECT ISNULL([dbo].[fnIsValidABANumber](@ABANumber),0) AS IsABANumberValid
 
 END