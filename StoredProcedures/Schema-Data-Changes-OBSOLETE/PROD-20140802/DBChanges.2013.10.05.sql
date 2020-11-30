ALTER TABLE Claim
ADD IsFirstOwner BIT NULL
GO


IF NOT EXISTS ( SELECT * FROM ConfigurationType WHERE Name = 'Claim')
BEGIN
INSERT INTO [ConfigurationType]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('Claim', 'Claim', 7, 1)
END

DECLARE @ProgramID INT 
SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford')
DECLARE @ConfigurationTypeID INT 
SET @ConfigurationTypeID = (SELECT ID FROM ConfigurationType WHERE Name = 'Claim')
DECLARE @ConfigurationCategoryID INT 
SET @ConfigurationCategoryID = (SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation')


INSERT INTO [ProgramConfiguration]
           ([ProgramID]
           ,[ConfigurationTypeID]
           ,[ConfigurationCategoryID]
           ,[ControlTypeID]
           ,[DataTypeID]
           ,[Name]
           ,[Value]
           ,[IsActive]
           ,[Sequence]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'IsWarrantyRequired', 'Yes', 1, NULL, NULL, NULL, NULL, NULL)
