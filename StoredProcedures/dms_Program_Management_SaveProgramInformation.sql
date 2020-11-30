IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveProgramInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveProgramInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveProgramInformation]( 
 @programID int,
 @parentProgramID int = NULL,
 @programName nvarchar(50) = NULL,
 @programDescription nvarchar(255) = NULL,
 @programCode nvarchar(20) = NULL,
 @isActive bit = NULL,
 @isAudited bit = NULL,
 @isGroup bit = NULL,
 @isServiceGuaranteed bit = NULL,
 @isWebRegistrationEnabled bit = NULL,
 @modifiedBy nvarchar(50)  = NULL
 )
 AS
 BEGIN
	UPDATE Program
	SET ParentProgramID = @parentProgramID,
		Name = @programName,
		[Description] = @programDescription,
		Code = @programCode,
		IsActive = @isActive,
		IsAudited = @isAudited,
		IsGroup = @isGroup,
		IsServiceGuaranteed = @isServiceGuaranteed,
		IsWebRegistrationEnabled = @isWebRegistrationEnabled,
		ModifyBy = @modifiedBy,
		ModifyDate = GETDATE()
	WHERE ID=@programID
	
 END