IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Client_OpenPeriodToBeProcessRecords]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Client_OpenPeriodToBeProcessRecords] 
END 
GO

CREATE PROC [dbo].[dms_Client_OpenPeriodToBeProcessRecords](@billingSchedules NVARCHAR(MAX) = NULL)
AS
BEGIN
	
	DECLARE @BillingScheduleID AS TABLE(RecordID INT IDENTITY(1,1), BillingScheduleID INT)
	INSERT INTO @BillingScheduleID(BillingScheduleID) SELECT item FROM dbo.fnSplitString(@billingSchedules,',')
	
	SELECT BDI.ID BillingDefinitionInvoiceID,
		   BDI.Description AS BillingDefinitionInvoiceDescription,
		   BC.ID BillingSchedueID,
		   BC.ScheduleTypeID,
		   BC.ScheduleDateTypeID,
		   BC.ScheduleRangeTypeID
		   FROM BillingDefinitionInvoice BDI
		   LEFT JOIN BillingSchedule BC 
		   ON   BDI.ScheduleTypeID = BC.ScheduleTypeID
		   AND  BDI.ScheduleDateTypeID = BC.ScheduleDateTypeID
		   AND  BDI.ScheduleRangeTypeID = BC.ScheduleRangeTypeID
	WHERE  BC.IsActive = 1
	AND	   BC.ID IN (SELECT BillingScheduleID FROM @BillingScheduleID)
END





