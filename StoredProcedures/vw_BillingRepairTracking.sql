USE [DMS]
GO

/****** Object:  View [dbo].[vw_BillingRepairTracking]    Script Date: 04/26/2016 06:53:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_BillingRepairTracking]
AS
	SELECT 
		sr.ID ServiceRequestID
		,c.ProgramID
		,c.VehicleVIN
		,dbo.fnc_BillingVINModel(c.VehicleVIN) as VINModel
		,MIN(sr.CreateDate) PurchaseOrderDate
		--,MIN(po.IssueDate) PurchaseOrderDate
		,sr.AccountingInvoiceBatchID
	From ProgramDataItemValueEntity pdive 
	Join ContactLog cl on pdive.EntityID = 22 and pdive.RecordID = cl.ID
	Join ContactLogLink cll on cll.ContactLogID = cl.ID and cll.EntityID = 13
	Join ServiceRequest sr on sr.ID = cll.RecordID
	Join [Case] c on c.ID = sr.ID
	Join ProgramDataItem pdi on 
		pdi.ID = pdive.ProgramDataItemID 
		and pdi.ScreenName = 'RepairContactLog'
		and pdi.Name = 'RepairStatus'
	--Join PurchaseOrder po on po.ServiceRequestID = sr.ID and po.IsActive = 1
	--Join PurchaseOrderStatus pos on pos.ID = po.PurchaseOrderStatusID and pos.Name in ('Issued')
	Group By sr.ID, c.ProgramID, c.VehicleVIN, sr.AccountingInvoiceBatchID

GO

