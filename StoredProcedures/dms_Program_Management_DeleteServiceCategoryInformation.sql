IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_DeleteServiceCategoryInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_DeleteServiceCategoryInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Program_Management_DeleteServiceCategoryInformation 34
 CREATE PROCEDURE [dbo].[dms_Program_Management_DeleteServiceCategoryInformation]( 
 @id INT 
 )
 AS
 BEGIN
	DELETE FROM ProgramProductCategory WHERE ID = @id
 END
 