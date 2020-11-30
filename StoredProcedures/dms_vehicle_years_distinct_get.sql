 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vehicle_years_distinct_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vehicle_years_distinct_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- exec [dbo].[dms_vehicle_years_distinct_get]
CREATE PROC [dbo].[dms_vehicle_years_distinct_get]
AS
BEGIN
	
		SELECT DISTINCT [Year]
		FROM	VehicleMakeModel 
		WHERE [Year] IS NOT NULL
		ORDER BY [Year] DESC
	

END

