--
-- Setup ProgramConfiguration for Register Member 
--

DECLARE @ProgramID INT
DECLARE @ConfigurationTypeID INT
DECLARE @ConfigurationCategoryID INT 

SET @ConfigurationTypeID = (SELECT ID FROM ConfigurationType WHERE Name= 'RegisterMember')
SET @ConfigurationCategoryID = (SELECT ID FROM ConfigurationCategory WHERE Name= 'Validation')

DECLARE db_cursor CURSOR FOR  
      select p.ID ProgramID
      --c.id, c.name as Client, pp.id, pp.name as Parent, p.id, p.name as Program
      from program p
      join client c on c.id = p.clientid
      left join program pp on pp.id = p.parentprogramid
      where c.name <> 'ARS'
      and p.isactive = 1
      and isnull(pp.id, '') = ''
      and Not Exists (
            Select *
            From ProgramConfiguration pc
            Where pc.ProgramID = p.ID 
            and pc.ConfigurationTypeID = @ConfigurationTypeID 
            and pc.ConfigurationCategoryID = @ConfigurationCategoryID
            )           
      order by c.name, pp.name, p.name

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @ProgramID   

WHILE @@FETCH_STATUS = 0   
BEGIN   

      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireProgram', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequirePrefix', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireFirstName', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireMiddleName', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireLastName', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireSuffix', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequirePhone', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireAddress1', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireAddress2', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireAddress3', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireCity', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireCountry', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireState', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireZip', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireEmail', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireEffectiveDate', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireExpirationDate', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'DaysAddedToEffectiveDate', 2, 1, 1, getdate(), 'System', NULL, NULL)

    FETCH NEXT FROM db_cursor INTO @ProgramID   
END   

CLOSE db_cursor   
DEALLOCATE db_cursor

GO

-- PDG - Professional Dispatch Group
DECLARE @ProgramID INT
DECLARE @ConfigurationTypeID INT
DECLARE @ConfigurationCategoryID INT 

SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'PDG - Professional Dispatch Group') 
SET @ConfigurationTypeID = (SELECT ID FROM ConfigurationType WHERE Name= 'RegisterMember')
SET @ConfigurationCategoryID = (SELECT ID FROM ConfigurationCategory WHERE Name= 'Validation')

      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireProgram', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequirePrefix', 'No', 1, 1, getdate(), 'System', NULL, NULL)            
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireFirstName', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireMiddleName', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireLastName', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireSuffix', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequirePhone', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireAddress1', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireAddress2', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireAddress3', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireCity', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireCountry', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireState', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireZip', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireEmail', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireEffectiveDate', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireExpirationDate', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'DaysAddedToEffectiveDate', 2, 1, 1, getdate(), 'System', NULL, NULL)

GO

-- PDG - Professional Dispatch Group  
DECLARE @ProgramID INT
DECLARE @ConfigurationTypeID INT
DECLARE @ConfigurationCategoryID INT 

SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'PCG - Travel Guard') 
SET @ConfigurationTypeID = (SELECT ID FROM ConfigurationType WHERE Name= 'RegisterMember')
SET @ConfigurationCategoryID = (SELECT ID FROM ConfigurationCategory WHERE Name= 'Validation')

      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireProgram', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequirePrefix', 'No', 1, 1, getdate(), 'System', NULL, NULL)            
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireFirstName', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireMiddleName', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireLastName', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireSuffix', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequirePhone', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireAddress1', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireAddress2', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireAddress3', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireCity', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireCountry', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireState', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireZip', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireEmail', 'No', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireEffectiveDate', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireExpirationDate', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'DaysAddedToEffectiveDate', 2, 1, 1, getdate(), 'System', NULL, NULL)

GO
