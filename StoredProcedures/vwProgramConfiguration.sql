IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vwProgramConfiguration]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vwProgramConfiguration] 
 END 
 GO  
CREATE VIEW [dbo].[vwProgramConfiguration]
AS
SELECT TOP 99999
	pc.ID
	, pc.ProgramID
	, p.Name AS ProgramName
	, pc.ConfigurationTypeID
	, ct.Name AS ConfigurationTypeName
	, pc.ConfigurationCategoryID
	, cc.Name AS ConfigurationCategoryName
	, pc.ControlTypeID
	, cnt.Name AS ControlTypeName
	, pc.DataTypeID
	, dt.Name AS DataTypeName
	, pc.Name
	, pc.Value
	, pc.IsActive
	, pc.Sequence
	, pc.CreateDate
	, pc.CreateBy
	, pc.ModifyDate
	, pc.ModifyBy
FROM ProgramConfiguration pc
JOIN Program p ON pc.ProgramID = p.ID
JOIN ConfigurationType ct ON pc.ConfigurationTypeID = ct.ID
JOIN ConfigurationCategory cc ON pc.ConfigurationCategoryID = cc.ID
LEFT JOIN ControlType cnt ON pc.ControlTypeID = cnt.ID
LEFT JOIN DataType dt ON pc.DataTypeID = dt.ID
ORDER BY p.Name, ct.Name, cc.Name
GO

