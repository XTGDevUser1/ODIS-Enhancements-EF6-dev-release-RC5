IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ClientBillableEventProcessing_Details]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ClientBillableEventProcessing_Details] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
-- EXEC dms_ClientBillableEventProcessing_Details 1
CREATE PROC dms_ClientBillableEventProcessing_Details(@pBillingInvoiceDetail INT = NULL)
AS
BEGIN
SELECT	
		--Billable Event Section
		BID.ID as BillingInvoiceDetailID,
		BIDs.[ID] DetailsStatusID,
		BIDs.[Description] as DetailStatus,
		BIDd.ID as DispositionID,
		BIDd.[Description] as Disposition,
		BID.EntityKey,
		e.Name as EntityType,
		BID.EntityDate,
		BID.ServiceCode,
		BID.Quantity,
		BID.EventAmount,
		pro.Id as ProgramID,
		pro.Description as Program,
		'' MembershipNumber,
		'' MemberName,
		BID.InvoiceDetailStatusAuthorization + ' ' + BID.InvoiceDetailStatusAuthorizationDate as AuthorizedBy,
		
		--Invoice Information Section
		bis.[Description] as InvoiceStatus,
		bis.ID InvoiceStatusID,
		bis.Name InvoiceStatusName,
		bi.InvoiceNumber,
		bi.InvoiceDate,
		cl.Name as ClientName,
		bst.Name as BillingSchedule,
		bdi.Name as InvoiceName,
		bdil.Name as LineName,
		pr.Name as ProductName,
		bdile.Name as EventName,
		bdil.[Description] as EventDescription,
		BID.RateTypeName as Rate,
		pr.AccountingSystemGLCode as GLCode,	
		
		--Adjustment Section
		BID.IsAdjustable as Adjustable,
		BID.AdjustmentAmount,
		
		bar.ID AdjustmentReasonID,
		bar.[Description] as AdjustmentReason,
		BID.AdjustmentReasonOther,
		BID.AdjustmentComment,
		BID.AdjustedBy,
		BID.AdjustmentDate,
		
		-- Other Information
		BID.IsExcludable as Excludable,
		ber.ID as ExcludeReasonID, 
		ber.[Description] as ExcludeReason,
		BID.ExcludeReasonOther,
		BID.ExcludeComment,
		BID.ExcludedBy,
		BID.ExcludeDate,
		
		-- Audit Section
		BID.CreateBy,
		BID.CreateDate,
		BID.ModifyBy,
		BID.ModifyDate,
		
		--Newly Added
		BID.IsAdjusted,
		BID.IsExcluded,
		
		--TOP Headers
		bi.[Description] AS InvoiceDescription,
		bil.[Description] AS LineDescription,
		BID.IsEditable AS IsQuantityAndAmountEditable,

		-- TFS 612
		BID.InternalComment,
		BID.ClientNote

FROM	dbo.BillingInvoiceDetail BID with (nolock)
left join	dbo.BillingDefinitionInvoice bdi with (nolock) on bdi.ID = BID.BillingDefinitionInvoiceID
left join	dbo.BillingDefinitionInvoiceLine bdil with (nolock) on bdil.ID = BID.BillingDefinitionInvoiceLineID
left join	dbo.BillingDefinitionInvoiceLineEvent bdile with (nolock) on bdile.BillingDefinitionInvoiceLineID = bdil.ID
		and bdile.BillingDefinitionInvoiceLineID = BID.BillingDefinitionInvoiceLineID
		and bdile.BillingDefinitionEventID = BID.BillingDefinitionEventID
left join	dbo.BillingDefinitionEvent bde with (nolock) on bde.ID = BID.BillingDefinitionEventID
left join	dbo.BillingSchedule bs with (nolock) on bs.ID = BID.BillingScheduleID
left join	dbo.Product pr with (nolock) on pr.ID = BID.ProductID
left join	dbo.Program pro with (nolock) on pro.ID = BID.ProgramID
left join	dbo.Client cl with (nolock) on cl.ID = bdi.ClientID
left join	dbo.BillingScheduleStatus bss with (nolock) on bss.ID = bs.ScheduleStatusID
left join	dbo.BillingInvoiceDetailStatus BIDs with (nolock) on BIDs.ID = BID.InvoiceDetailStatusID
left join	dbo.BillingInvoiceDetailDisposition BIDd with (nolock) on BIDd.ID = BID.InvoiceDetailDispositionID
left join	dbo.BillingScheduleType bst with (nolock) on bst.ID = bs.ScheduleTypeID
left outer join dbo.Entity e with (nolock) on e.ID = BID.EntityID
left outer join	dbo.BillingAdjustmentReason bar on bar.ID = BID.AdjustmentReasonID
left outer join	dbo.BillingExcludeReason ber on ber.ID = BID.ExcludeReasonID
left outer join dbo.BillingInvoiceLine bil with (nolock) on bil.ID = BID.BillingInvoiceLineID
left outer join dbo.BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID
left outer join dbo.BillingInvoiceStatus bis with(nolock) on bis.ID = bi.InvoiceStatusID

WHERE	BID.ID = @pBillingInvoiceDetail

END
