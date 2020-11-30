IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_NightlyMaintenance]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_NightlyMaintenance]
GO

CREATE PROCEDURE [dbo].[dms_NightlyMaintenance] 
AS
BEGIN
	SET NOCOUNT ON;

	EXEC dbo.dms_Vendor_UpdateAdminisrativeRating
	EXEC dbo.dms_Vendor_UpdateProductRating
	EXEC dbo.dms_Claim_FordQFC_Create
	EXEC dbo.dms_ServiceRequestAgentTime_TechLeadTime_Update 	
	--EXEC dbo.dms_ServiceRequestAgentTime_Update
	EXEC dbo.dms_TemporaryDataFixes
	--EXEC dbo.dms_Billing_GenerateMissingInvoices
	--EXEC dbo.dms_BillingRefreshAllInvoices

END
GO

