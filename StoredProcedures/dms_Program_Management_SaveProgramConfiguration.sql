IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveProgramConfiguration]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveProgramConfiguration] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveProgramConfiguration]( 
 @programConfigurationId INT,
 @configurationTypeID INT=NULL,
 @configurationCategoryID INT=NULL,
 @controlTypeID INT=NULL,
 @dataTypeID INT=NULL,
 @name nvarchar(50)=NULL,
 @value nvarchar(4000)=NULL,
 @sequence INT=NULL,
 @user nvarchar(50)=NULL,
 @modifiedOn datetime=NULL,
 @isAdd bit,
 @programID int
 )
 AS
 BEGIN
 
 IF @isAdd=1 
 BEGIN
 
	INSERT INTO ProgramConfiguration(ProgramID,ConfigurationTypeID,ConfigurationCategoryID,ControlTypeID,DataTypeID,Name,Value,IsActive,Sequence,CreateDate,CreateBy)
	VALUES(@programID,@configurationTypeID,@configurationCategoryID,@controlTypeID,@dataTypeID,@name,@value,1,@sequence,@modifiedOn,@user)
	
 END
 ELSE BEGIN
 
	UPDATE ProgramConfiguration
	SET ConfigurationTypeID=@configurationTypeID,
		ConfigurationCategoryID=@configurationCategoryID,
		ControlTypeID=@controlTypeID,
		DataTypeID=@dataTypeID,
		Name=@name,
		Value=@value,
		Sequence=@sequence,
		ModifyBy=@user,
		ModifyDate=@modifiedOn
	WHERE ID=@programConfigurationId
 END
 
 END