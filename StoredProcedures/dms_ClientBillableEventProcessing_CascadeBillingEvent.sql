IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ClientBillableEventProcessing_CascadeBillingEvent]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ClientBillableEventProcessing_CascadeBillingEvent] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

CREATE PROC dms_ClientBillableEventProcessing_CascadeBillingEvent(@lineID NVARCHAR(100) = NULL)
AS
BEGIN
	SELECT		BDE.ID,
				BDE.Description,
				BDE.Name
	FROM		BillingDefinitionInvoiceLineEvent bdile
	JOIN   BillingDefinitionEvent BDE ON bdile.BillingDefinitionEventID = BDE.ID
	AND         bdile.IsActive = 1
	AND			bdile.BillingDefinitionInvoiceLineID IN (SELECT item FROM dbo.fnSplitString(@lineID,','))
	ORDER BY    bdile.Sequence
END




