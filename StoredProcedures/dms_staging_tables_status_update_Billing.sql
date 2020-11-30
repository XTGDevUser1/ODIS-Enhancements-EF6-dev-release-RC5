
/****** Object:  StoredProcedure [dbo].[dms_staging_tables_status_update_Billing]    Script Date: 10/31/2013 16:38:24 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_staging_tables_status_update_Billing]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_staging_tables_status_update_Billing]
GO



/****** Object:  StoredProcedure [dbo].[dms_staging_tables_status_update_Billing]    Script Date: 10/31/2013 16:38:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- EXEC  [dbo].[dms_staging_tables_status_update_Billing] 'sysadmin'  
 
CREATE PROCEDURE [dbo].[dms_staging_tables_status_update_Billing](  
@etlExecutionLogID BIGINT
)
AS
BEGIN
	
	UPDATE [staging_MAS90].[InvoiceRequest]
	SET		ProcessFlag = 1,
			Status = 'Y'
	WHERE	ETL_Load_ID = @etlExecutionLogID
	
END

GO


