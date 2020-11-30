USE [DMS]
GO

/****** Object:  StoredProcedure [report].[BillingClientInvoiceDetail_HagertySecondaryTow]    Script Date: 04/18/2016 11:15:12 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[report].[BillingClientInvoiceDetail_HagertySecondaryTow]') AND type in (N'P', N'PC'))
DROP PROCEDURE [report].[BillingClientInvoiceDetail_HagertySecondaryTow]
GO

USE [DMS]
GO

/****** Object:  StoredProcedure [report].[BillingClientInvoiceDetail_HagertySecondaryTow]    Script Date: 04/18/2016 11:15:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [report].[BillingClientInvoiceDetail_HagertySecondaryTow] (
	@InvoiceDate date
)
AS
BEGIN

	---- DEBUG
	--Declare @InvoiceDate date
	--SET @InvoiceDate = '8/1/2015'
	
	Declare @InvoiceName nvarchar(100)
	SET @InvoiceName = 'Hagerty - HPN2TOW - Markel'
	
	SELECT 
		InvoiceTotal.ClientName
		,InvoiceTotal.InvoiceID
		,InvoiceTotal.InvoiceName
		,c.ID
		,sr.ID ServiceRequest
		,CONVERT(nvarchar(50),sr.CreateDate,101) ItemDate
		,dbo.fnc_ProperCase(CASE WHEN c.ContactLastName IS NOT NULL THEN c.ContactFirstName ELSE mbr.FirstName END) FirstName
		,dbo.fnc_ProperCase(CASE WHEN c.ContactLastName IS NOT NULL THEN c.ContactLastName ELSE mbr.LastName END) LastName
		,dbo.fnc_ProperCase(
			RTRIM(CASE WHEN c.ContactLastName IS NOT NULL THEN ISNULL(c.ContactFirstName + ' ', '') + c.ContactLastName
					   WHEN mbr.LastName IS NOT NULL THEN ISNULL(mbr.FirstName + ' ', '') + mbr.LastName
					   ELSE '' End)) CustomerName
		,InvoiceTotal.ClientClaimNumber
		,InvoiceTotal.Amount
		,'' + RTRIM(CASE WHEN c.VehicleID IS NOT NULL THEN ISNULL(c.VehicleYear,'') END) +	
			RTRIM(CASE WHEN c.VehicleID IS NOT NULL THEN ' ' + CASE WHEN c.VehicleMake = 'Other' THEN ISNULL(c.VehicleMakeOther,'Unknown') ELSE ISNULL(c.VehicleMake,'') END END) + 
			RTRIM(CASE WHEN c.VehicleID IS NOT NULL THEN ' ' + CASE WHEN c.VehicleModel = 'Other' THEN ISNULL(c.VehicleModelOther,'') ELSE ISNULL(c.VehicleModel,'') END END
			) VehicleDescription	
		,CASE WHEN prod.Name IS NOT NULL THEN prod.Name + 
				(CASE WHEN COALESCE(sr.ServiceLocationCity, sr.ServiceLocationStateProvince, sr.ServiceLocationPostalCode) IS NOT NULL THEN '; ' ELSE '' END) +
				(CASE WHEN sr.ServiceLocationCity IS NOT NULL THEN sr.ServiceLocationCity ELSE '' END) +
				(CASE WHEN sr.ServiceLocationStateProvince IS NOT NULL THEN ', ' + sr.ServiceLocationStateProvince ELSE '' END) +
				(CASE WHEN sr.ServiceLocationPostalCode IS NOT NULL THEN ', ' + sr.ServiceLocationPostalCode ELSE '' END) 
			  ELSE 'N/A'
			  END ServiceDescription
			  
	FROM (
		SELECT 
			client.Name ClientName
			,bi.[Description] InvoiceName
			,bi.ID InvoiceID
			,c.ID CaseID
			,UPPER(c.ReferenceNumber) ClientClaimNumber 
			,ROUND(SUM(CASE WHEN bid.IsExcluded = 1 THEN 0.00
				  WHEN bid.IsAdjusted = 1 THEN bid.AdjustmentAmount
				  ELSE bid.EventAmount
				  END),2) Amount
		FROM BillingSchedule bs (nolock) 
		JOIN BillingInvoice bi with (nolock) on bi.BillingScheduleID = bs.ID
		JOIN Client client with (nolock) on client.ID = bi.ClientID
		JOIN BillingInvoiceLine bil with (nolock) on bi.ID = bil.BillingInvoiceID
		JOIN BillingInvoiceDetail bid with (nolock) on bil.ID = bid.BillingInvoiceLineID
		JOIN BillingInvoiceDetailStatus bids with (nolock) on bids.ID = bid.InvoiceDetailStatusID

		---- Purchase Order Entity
		LEFT OUTER JOIN PurchaseOrder PO on PO.ID = bid.EntityKey
		---- Case / SR
		LEFT OUTER JOIN ServiceRequest sr on sr.ID = po.ServiceRequestID
		LEFT OUTER JOIN [Case] c on c.ID = sr.CaseID

		Where bs.ScheduleRangeBegin = @InvoiceDate
		AND bi.Name = @InvoiceName
		AND	bids.Name not in ('DELETED')				---- EXCLUDE detail items with 'Deleted' status
		AND bid.ExcludeReasonID IS NULL					---- EXCLUDE detail items with 'Exclude' reason
		
		GROUP BY
			client.Name
			,bi.[Description] 
			,bi.ID 
			,c.ID 
			,c.ReferenceNumber 
		) InvoiceTotal
		---- Case / SR
	LEFT OUTER JOIN [Case] c on c.ID = InvoiceTotal.CaseID
	LEFT OUTER JOIN ServiceRequest sr on sr.CaseID = c.ID
	LEFT OUTER JOIN Product prod on prod.ID = SR.PrimaryProductID
	LEFT OUTER JOIN Member mbr on mbr.ID = c.MemberID
	ORDER BY CONVERT(nvarchar(50),sr.CreateDate,101), InvoiceTotal.ClientClaimNumber
END

GO

