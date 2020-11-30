IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveProgramPhoneSystemConfigurationInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveProgramPhoneSystemConfigurationInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveProgramPhoneSystemConfigurationInformation]( 
   @id INT = NULL
 , @ivrScriptID INT = NULL
 , @skillSetID INT = NULL
 , @phoneCompanyID INT = NULL
 , @inboundNumber NVARCHAR(100) = NULL
 , @pilotNumber NVARCHAR(100) = NULL
 , @isshownOnScreen BIT = NULL
 , @isActive BIT = NULL
 , @programID INT = NULL
 , @modifiedBy NVARCHAR(100) = NULL
 )
 AS
 BEGIN
 
 IF @id>0
	BEGIN
		UPDATE PhoneSystemConfiguration
		SET IVRScriptID = @ivrScriptID ,
			SkillsetID = @skillSetID ,
			InboundPhoneCompanyID = @phoneCompanyID ,
			InboundNumber = @inboundNumber ,
			PilotNumber = @pilotNumber ,
			IsShownOnScreen = @isshownOnScreen ,
			IsActive = @isActive ,
			ModifyBy = @modifiedBy ,
			ModifyDate = GETDATE()
		WHERE ID = @id
	END
ELSE
	BEGIN
		INSERT INTO PhoneSystemConfiguration(
			ProgramID,
			IVRScriptID,
			SkillsetID,
			InboundPhoneCompanyID,
			InboundNumber,
			PilotNumber,
			IsShownOnScreen,
			IsActive,
			CreateBy,
			CreateDate
		)
		VALUES(
			@programID,
			@ivrScriptID,
			@skillSetID,
			@phoneCompanyID,
			@inboundNumber,
			@pilotNumber,
			@isshownOnScreen,
			@isActive,
			@modifiedBy,
			GETDATE()
		)
	END
 
 END