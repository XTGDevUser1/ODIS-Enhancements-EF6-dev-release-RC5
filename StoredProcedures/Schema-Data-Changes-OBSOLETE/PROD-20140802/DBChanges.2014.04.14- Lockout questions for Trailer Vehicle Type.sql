
DECLARE @ProductCategoryQuestionID AS INT

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Is this a Class A RV or a travel trailer? '
                                    
                                  
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Is this a Class A RV or a travel trailer? ')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


---------------------------------------------------------------------------------



SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Is the vehicle running?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Is the vehicle running?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End

----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Where are the keys located?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Where are the keys located?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Trunk accessible from cabin?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Trunk accessible from cabin?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Is key a transponder key?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Is key a transponder key?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Do you have the key code?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Do you have the key code?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Reason key is not working?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Reason key is not working?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Power door locks?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Power door locks?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


----------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Side-Impact air bags?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Side-Impact air bags?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


----------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Do you need a locksmith?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Do you need a locksmith?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Provide Description'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT  TOP 1 [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Provide Description')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


