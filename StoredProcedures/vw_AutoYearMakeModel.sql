IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_AutoYearMakeModel]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_AutoYearMakeModel] 
 END 
 GO 
CREATE VIEW [dbo].[vw_AutoYearMakeModel]
AS
Select Distinct Top 2000000
	vm.[Year]
	,vm.Make
	,vm.Model
	,vc.Name VehicleCategory
	,vm.VehicleCategoryID
From VehicleMakeModel vm
Join VehicleCategory vc on vc.ID = vm.VehicleCategoryID
GO

