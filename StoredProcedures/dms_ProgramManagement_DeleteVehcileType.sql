IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ProgramManagement_DeleteVehcileType]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_ProgramManagement_DeleteVehcileType]
GO


CREATE PROC dms_ProgramManagement_DeleteVehcileType(@programVehicleTypeId INT = NULL)  
AS  
BEGIN 

DELETE FROM ProgramVehicleType
WHERE ID=@programVehicleTypeId

END