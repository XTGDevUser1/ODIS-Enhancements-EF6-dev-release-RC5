IF EXISTS (SELECT * FROM dbo.sysobjects 
			WHERE id = object_id(N'[dbo].[dms_NextNumber_get]')   		AND type in (N'P', N'PC')) 
BEGIN
	DROP PROCEDURE [dbo].[dms_NextNumber_get] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 
-- EXEC dms_NextNumber_get 'VendorNumber'
CREATE PROCEDURE [dbo].[dms_NextNumber_get] ( @Name nvarchar(50) ) 
AS BEGIN  
DECLARE @NextNumber int  
BEGIN TRANSACTION NextNumber  
	SELECT  @NextNumber = Value  FROM NextNumber WHERE  Name = @Name    
	UPDATE NextNumber SET  Value = Value + 1 WHERE  Name = @Name    
COMMIT TRANSACTION NextNumber  
SELECT @NextNumber  

END