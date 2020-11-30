IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_RVMakeModel]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_RVMakeModel] 
 END 
 GO  
CREATE VIEW [dbo].[vw_RVMakeModel]
AS
Select Distinct Top 2000000
	rvm.Make
	,rvm.Model
	,rvt.Name [RVType]
	,vc.Name VehicleCategory
	,rvm.VehicleCategoryID
From RVMakeModel rvm
Join RVType rvt on rvt.ID = rvm.RVTypeID
Join VehicleCategory vc on vc.ID = rvm.VehicleCategoryID
Order By rvm.Make, rvm.Model, rvt.Name
GO

