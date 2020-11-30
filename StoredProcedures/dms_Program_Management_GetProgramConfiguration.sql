IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_GetProgramConfiguration]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_GetProgramConfiguration] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_GetProgramConfiguration]( 
 @programConfigurationId INT
 )
 AS
 BEGIN
 SELECT 
	    ConfigurationTypeID,
	    ConfigurationCategoryID,
	    ControlTypeID,
	    DataTypeID,
	    Name,
	    Value,
	    IsActive,
	    Sequence,
	    CreateDate,
	    CreateBy,
	    ModifyDate,
	    ModifyBy
 FROM ProgramConfiguration
 WHERE ID=@programConfigurationId
 END