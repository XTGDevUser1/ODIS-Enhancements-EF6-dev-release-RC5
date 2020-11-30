IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spNMCReportRentalCoverCommission]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[spNMCReportRentalCoverCommission]
GO

CREATE PROCEDURE [dbo].[spNMCReportRentalCoverCommission]
@pMonthEndDate as date
as

DECLARE @MonthEndDate as date 

SET @MonthEndDate = @pMonthEndDate

SELECT	sr.ID AS ServiceRequestID, CONVERT(date, sr.CreateDate) AS ServiceDate
		, m.FirstName + ' ' + m.LastName AS Person
		, vt.Name AS VehicleType
		, c.VehicleYear + ' ' + c.VehicleMake + ' ' + c.VehicleModel AS Vehicle
		, sr.ServiceLocationAddress, po.PurchaseOrderNumber
		, po.PurchaseOrderAmount AS POAmount
		--, po.PurchaseOrderAmount * 3 AS Commission
		, CASE
			WHEN po.IssueDate < '4/12/2016 16:00' THEN po.PurchaseOrderAmount * 3
			ELSE 0
		  END AS Commission
		--, ROUND((po.PurchaseOrderAmount + (po.PurchaseOrderAmount * 3)) * .03, 2) AS CCFee
		, CASE
			WHEN po.IssueDate < '4/12/2016 16:00' THEN ROUND((po.PurchaseOrderAmount + (po.PurchaseOrderAmount * 3)) * .03, 2)
			ELSE ROUND(po.PurchaseOrderAmount * .03, 2)
		  END AS CCFee
		, CASE
			WHEN vt.Name = 'RV' THEN 30.20
			ELSE 17.79
		  END AS DispatchFee	
FROM	PurchaseOrder po
JOIN	ServiceRequest sr ON sr.ID = po.ServiceRequestID
JOIN	[Case] c ON c.ID = sr.CaseID
JOIN	Member m ON m.ID = c.MemberID
JOIN	Program p ON p.ID = c.ProgramID
JOIN	Client cl ON cl.ID = p.ClientID
JOIN	VehicleType vt ON vt.ID = c.VehicleTypeID
WHERE	po.IsActive=1
AND		po.PurchaseOrderStatusID = (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Issued')
AND		cl.Name = 'RentalCover.com'
AND		po.IssueDate BETWEEN '' AND @MonthEndDate
ORDER BY sr.ID
GO

