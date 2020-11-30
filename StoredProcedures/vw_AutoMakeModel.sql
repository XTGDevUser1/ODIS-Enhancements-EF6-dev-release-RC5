IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_AutoMakeModel]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_AutoMakeModel] 
 END 
 GO  
CREATE VIEW [dbo].[vw_AutoMakeModel]
AS
Select Distinct Top 2000000
	vm.Make
	,vm.Model
	,vc.Name VehicleCategory
	,vm.VehicleCategoryID
From VehicleMakeModel vm
Join VehicleCategory vc on vc.ID = vm.VehicleCategoryID
GO

