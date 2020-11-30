IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_DeleteDataItem]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_DeleteDataItem] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Program_Management_DeleteDataItem 19
 CREATE PROCEDURE [dbo].[dms_Program_Management_DeleteDataItem]( 
 @id INT 
 )
 AS
 BEGIN
	DELETE FROM ProgramDataItemValue WHERE ProgramDataItemID = @id
	DELETE FROM ProgramDataItemValueEntity WHERE ProgramDataItemID = @id
	DELETE FROM ProgramDataItem WHERE ID = @id
 END
 