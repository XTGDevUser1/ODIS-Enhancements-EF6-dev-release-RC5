IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_DeleteServiceInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_DeleteServiceInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Program_Management_DeleteServiceInformation 34
 CREATE PROCEDURE [dbo].[dms_Program_Management_DeleteServiceInformation]( 
 @id INT 
 )
 AS
 BEGIN
	DELETE FROM ProgramProduct WHERE ID = @id
 END
 