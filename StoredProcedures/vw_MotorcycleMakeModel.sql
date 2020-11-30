IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_MotorcycleMakeModel]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_MotorcycleMakeModel] 
 END 
 GO  
CREATE VIEW [dbo].[vw_MotorcycleMakeModel]
AS
Select Distinct Top 2000000 
	mm.Make
	,mm.Model
	,mt.Name MotorcycleType
	,vc.Name VehicleCategory
from MotorcycleMakeModel mm
Join MotorcycleType mt on mm.MotorCycleTypeID = mt.ID
Join VehicleCategory vc on vc.ID = mm.VehicleCategoryID
Order By mm.Make
	,mm.Model
	,mt.Name
GO

