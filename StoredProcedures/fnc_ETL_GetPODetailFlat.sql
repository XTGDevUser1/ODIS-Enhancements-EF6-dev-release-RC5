USE [DMS]
GO
/****** Object:  UserDefinedFunction [dbo].[fnc_ETL_GetPODetailFlat]    Script Date: 04/08/2013 14:57:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Description:	Returns default product rates by location
-- =============================================
ALTER FUNCTION [dbo].[fnc_ETL_GetPODetailFlat] 
(
	@IncludeAllTransactions bit = 0
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT 
		PO.ID PurchaseOrderID
		,PO.OriginalPurchaseOrderID
		--,(SELECT Name FROM dbo.PurchaseOrderStatus WHERE ID = PO.PurchaseOrderStatusID)
		--,Prod.Name
		--,PO.TaxAmount
		--,PO.TotalServiceAmount
		--,PO.MemberServiceAmount
		--,PO.CoachNetServiceAmount
		--,PO.IsMemberAmountCollectedByVendor
		--,PO.MemberAmountDueToCoachNet
		--,PO.PurchaseOrderAmount

		,MIN(CASE WHEN Prod.ProductSubTypeID IN (1,2) OR rt.Name = 'GoneOnArrival' OR prod.Name = 'Impound Release Fee' THEN PODtl.ProductID ELSE 999 END) AS ProductID
		,SUM(CASE WHEN ProdCat.Name = 'Tow' and Prod.ProductSubTypeID IN (1,2) and rt.Name = 'Base' and ISNULL(PODtl.IsMemberPay,0) = 0 THEN PODtl.Rate ELSE 0 END) AS TowAmount --POHOOK
		,SUM(CASE WHEN ProdCat.Name = 'Tow' and Prod.ProductSubTypeID IN (1,2) and rt.Name = 'Service' and ISNULL(PODtl.IsMemberPay,0) = 0 THEN PODtl.Rate ELSE 0 END) AS TowPerMile --POHOOKPER
		,SUM(CASE WHEN ProdCat.Name = 'Tow' and Prod.ProductSubTypeID IN (1,2) and rt.Name = 'Service' and ISNULL(PODtl.IsMemberPay,0) = 0 THEN PODtl.Quantity ELSE 0 END) AS TowMiles --POHOOKMILE
		,SUM(CASE WHEN ProdCat.Name = 'Tow' and Prod.ProductSubTypeID IN (1,2) and rt.Name = 'ServiceFree' and ISNULL(PODtl.IsMemberPay,0) = 0 THEN PODtl.Quantity ELSE 0 END) AS TowFreeMiles --POFREEH

		,SUM(CASE WHEN ProdCat.Name <> 'Tow' and rt.Name = 'Base' and ISNULL(PODtl.IsMemberPay,0) = 0 THEN PODtl.Rate ELSE 0 END) AS NoTowAmount --POSERV

		,SUM(CASE WHEN ProdCat.Name = 'Tow' and Prod.ProductSubTypeID IN (1,2) and rt.Name = 'Base' and ISNULL(PODtl.IsMemberPay,0) = 1 THEN PODtl.Rate ELSE 0 END) AS MemberPayTowAmount --POMBRP
		,SUM(CASE WHEN ProdCat.Name = 'Tow' and Prod.ProductSubTypeID IN (1,2) and rt.Name = 'Service' and ISNULL(PODtl.IsMemberPay,0) = 1 THEN PODtl.Rate ELSE 0 END) AS MemberPayTowPerMile --POMBRPPER
		,SUM(CASE WHEN ProdCat.Name = 'Tow' and Prod.ProductSubTypeID IN (1,2) and rt.Name = 'Service' and ISNULL(PODtl.IsMemberPay,0) = 1 THEN PODtl.Quantity ELSE 0 END) AS MemberPayTowMiles --POMBRPMILE

		,SUM(CASE WHEN ProdCat.Name <> 'Tow' and rt.Name = 'Base' and ISNULL(PODtl.IsMemberPay,0) = 1 THEN PODtl.Rate ELSE 0 END) AS MemberPayNoTowAmount --POSUPPL1

		,SUM(CASE WHEN rt.Name = 'Enroute' THEN PODtl.Rate ELSE 0 END) AS EnroutePerMile  --POENRPER
		,SUM(CASE WHEN rt.Name = 'Enroute' THEN PODtl.Quantity ELSE 0 END) AS EnrouteMiles  --POENRMILE
		,SUM(CASE WHEN rt.Name = 'EnrouteFree' THEN PODtl.Quantity ELSE 0 END) AS EnrouteFreeMiles --POFREEE

		,SUM(CASE WHEN rt.Name = 'Return' THEN PODtl.Rate ELSE 0 END) AS ReturnPerMile --POPPPER
		,SUM(CASE WHEN rt.Name = 'Return' THEN PODtl.Quantity ELSE 0 END) AS ReturnMiles --POPPPER

		,SUM(CASE WHEN rt.Name = 'Hourly' THEN PODtl.Rate ELSE 0 END) AS HourlyRate --POHOUR
		,SUM(CASE WHEN rt.Name = 'Hourly' THEN PODtl.Quantity ELSE 0 END) AS HourlyHours --POHOUR#

		,SUM(CASE WHEN rt.Name = 'GoneOnArrival' THEN PODtl.Rate ELSE 0 END) AS GoneOnArrivalAmount --POGOA
		,SUM(CASE WHEN PODtl.ProductID = 151 THEN PODtl.Rate ELSE 0 END) AS TowDolliesAmount --POMBRPMILE
		,SUM(CASE WHEN PODtl.ProductID = 152 THEN PODtl.Rate ELSE 0 END) AS TowDropDriveLineAmount --POMBRPMILE

	FROM dbo.PurchaseOrder PO 
	JOIN dbo.ServiceRequest SR 
		ON PO.ServiceRequestID = SR.ID
	JOIN dbo.PurchaseOrderDetail PODtl 
		ON PODtl.PurchaseOrderID = PO.ID
	JOIN dbo.RateType rt 
		ON rt.ID = PODtl.ProductRateID
	JOIN dbo.Product Prod 
		ON Prod.ID = PODtl.ProductID
	JOIN dbo.ProductCategory ProdCat 
		ON ProdCat.ID = Prod.ProductCategoryID
	WHERE PO.DataTransferDate IS NULL OR @IncludeAllTransactions = 1 
	GROUP BY
		SR.ID
		,PO.ID
		,PO.OriginalPurchaseOrderID
		,PO.PurchaseOrderStatusID
		,PO.TaxAmount
		,PO.TotalServiceAmount
		,PO.MemberServiceAmount
		,PO.CoachNetServiceAmount
		,PO.IsMemberAmountCollectedByVendor
		,PO.MemberAmountDueToCoachNet
		,PO.PurchaseOrderAmount
	--ORDER BY PO.ID --desc
)


