IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveDataItemInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveDataItemInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveDataItemInformation]( 
   @id INT = NULL
 , @programID INT = NULL
 , @controlTypeID INT = NULL
 , @dataTypeID INT = NULL
 , @name NVARCHAR(100) = NULL
 , @screenName NVARCHAR(100) = NULL
 , @label NVARCHAR(100) = NULL
 , @maxLength INT = NULL
 , @sequence INT = NULL
 , @isRequired BIT = NULL
 , @isActive BIT = NULL
 , @currentUser NVARCHAR(100) = NULL 
 )
 AS
 BEGIN
 IF @id > 0 
	 BEGIN
		UPDATE ProgramDataItem 
		SET ControlTypeID = @controlTypeID,
			DataTypeID = @dataTypeID,
			Name = @name,
			ScreenName = @screenName,
			Label = @label,
			Sequence = @sequence,
			MaxLength = @maxLength,
			IsRequired = @isRequired,
			IsActive = @isActive,
			ModifyBy = @currentUser,
			ModifyDate = GETDATE()
		WHERE ID = @id
	 END
ELSE
	BEGIN
		INSERT INTO ProgramDataItem (
			ProgramID,
			ControlTypeID,
			DataTypeID,
			Name,
			ScreenName,
			Label,
			Sequence,
			MaxLength,
			IsRequired,
			IsActive,
			CreateBy,
			CreateDate		
		)
		VALUES(
			@programID,
			@controlTypeID,
			@dataTypeID,
			@name,
			@screenName,
			@label,
			@sequence,
			@maxLength,
			@isRequired,
			@isActive,
			@currentUser,
			GETDATE()
		)
	END
END