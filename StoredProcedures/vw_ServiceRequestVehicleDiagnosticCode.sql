IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_ServiceRequestVehicleDiagnosticCode]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_ServiceRequestVehicleDiagnosticCode] 
 END 
 GO  
CREATE VIEW [dbo].[vw_ServiceRequestVehicleDiagnosticCode]
AS
SELECT sr.[ID]
      ,[ServiceRequestID]
	  ,[VehicleDiagnosticCodeID]
	  ,vd.[Name] AS VehicleDiagnosticCodeName
	  ,[VehicleDiagnosticCodeType]
	  ,vdc.[ID] AS VehicleDiagnosticCategroyID
	  ,vdc.[Name] AS VehicleDiagnosticCategoryName
	  ,[IsPrimary]
	  ,vd.[FordStandardCode]
	  ,vd.[FordWarrantyCode]
	  ,vd.[FordAfterWarrantyCode]
	  ,vd.[FordClaimCode]
	  ,[CreateDate]
	  ,[CreateBy]
  FROM [dbo].[ServiceRequestVehicleDiagnosticCode] sr
  JOIN VehicleDiagnosticCode vd ON vd.ID = sr.VehicleDiagnosticCodeID
  JOIN VehicleDiagnosticCategory vdc ON vdc.ID = vd.VehicleDiagnosticCategoryID
GO

