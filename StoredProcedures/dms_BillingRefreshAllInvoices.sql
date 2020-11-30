/****** Object:  StoredProcedure [dbo].[dms_BillingRefreshAllInvoices]    Script Date: 07/13/2016 09:50:33 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_BillingRefreshAllInvoices]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_BillingRefreshAllInvoices]
GO

/****** Object:  StoredProcedure [dbo].[dms_BillingRefreshAllInvoices]    Script Date: 07/13/2016 09:50:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[dms_BillingRefreshAllInvoices]
AS
BEGIN

	Declare @BillingDefinitionInvoiceID int
		,@ScheduleTypeID int
		,@ScheduleDateTypeID int
		,@ScheduleRangeTypeID int
		,@InvoicesXML xml

	DECLARE db_cursor CURSOR FOR  
		Select Distinct 
			bdi.ID
			,bdi.ScheduleTypeID
			,bdi.ScheduleDateTypeID
			,bdi.ScheduleRangeTypeID
		From BillingDefinitionInvoice bdi
		Where bdi.IsActive = 1
		---- Refresh only invoices that have not been posted
		and Not Exists (
			Select bi.BillingDefinitionInvoiceID
			From BillingSchedule bs
			Join BillingScheduleStatus bss on bss.ID = bs.ScheduleStatusID and bss.Name = 'Open'
			Join BillingInvoice bi on bi.BillingScheduleID = bs.ID 
			Join BillingInvoiceStatus bis on bis.ID = bi.InvoiceStatusID and bis.Name = 'Posted'
			Where bs.IsActive = 1
			and bi.BillingDefinitionInvoiceID = bdi.ID
			)


	OPEN db_cursor   
	FETCH NEXT FROM db_cursor INTO 
		@BillingDefinitionInvoiceID   
		,@ScheduleTypeID 
		,@ScheduleDateTypeID 
		,@ScheduleRangeTypeID 

	WHILE @@FETCH_STATUS = 0   
	BEGIN   

		Set @InvoicesXML = CONVERT(xml, '<Records><BillingDefinitionInvoiceID>' + CONVERT(nvarchar(20),@BillingDefinitionInvoiceID) + '</BillingDefinitionInvoiceID></Records>')

		EXECUTE dms_BillingGenerateInvoices
		   'sysadmin'
		  ,1
		  ,@ScheduleTypeID
		  ,@ScheduleDateTypeID
		  ,@ScheduleRangeTypeID
		  ,@InvoicesXML

		FETCH NEXT FROM db_cursor INTO 
			@BillingDefinitionInvoiceID   
			,@ScheduleTypeID 
			,@ScheduleDateTypeID 
			,@ScheduleRangeTypeID 
	END   

	CLOSE db_cursor   
	DEALLOCATE db_cursor

END


GO


