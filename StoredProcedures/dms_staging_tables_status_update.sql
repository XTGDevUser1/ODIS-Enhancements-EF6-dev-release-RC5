IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_staging_tables_status_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_staging_tables_status_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

-- EXEC  [dbo].[dms_staging_tables_status_update] 'sysadmin'  
 
CREATE PROCEDURE [dbo].[dms_staging_tables_status_update](  
@etlExecutionLogID BIGINT
)
AS
BEGIN
	
	UPDATE [staging_MAS90].APCheckRequest
	SET		ProcessFlag = 1,
			Status = 'Y'
	WHERE	ETL_Load_ID = @etlExecutionLogID
	
	UPDATE [staging_MAS90].APVendorMaster
	SET		ProcessFlag = 1,
			Status = 'Y'
	WHERE	ETL_Load_ID = @etlExecutionLogID

END
