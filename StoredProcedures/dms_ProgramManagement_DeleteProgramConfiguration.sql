IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ProgramManagement_DeleteProgramConfiguration]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_ProgramManagement_DeleteProgramConfiguration]
GO


CREATE PROC dms_ProgramManagement_DeleteProgramConfiguration(@programConfigurationId INT = NULL)  
AS  
BEGIN 

DELETE FROM ProgramConfiguration
WHERE ID=@programConfigurationId

END