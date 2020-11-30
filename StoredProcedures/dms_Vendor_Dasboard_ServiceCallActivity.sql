IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Vendor_Dasboard_ServiceCallActivity]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Vendor_Dasboard_ServiceCallActivity]
GO

CREATE PROCEDURE [dbo].[dms_Vendor_Dasboard_ServiceCallActivity](@VendorID INT = NULL)
AS
BEGIN
	/* Month numbers for the last 6 months */
	DECLARE @Months TABLE (MonthNumber int)
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-1, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-2, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-3, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-4, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-5, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-6, getdate())))

	SELECT m.MonthNumber, ISNULL(va.TotalCalls,0) TotalCalls, ISNULL(va.AcceptedCalls,0) AcceptedCalls
	FROM @Months m
	LEFT OUTER JOIN (
		SELECT 
			MONTH(VendorContactLog.CreateDate) MonthNumber
			,COUNT(*) TotalCalls
			,SUM(CASE WHEN VendorContactLog.ContactAction = 'Accepted' THEN 1 ELSE 0 END) AcceptedCalls
		FROM [dbo].[fnc_GetVendorLocationProduct_ContactLog] () VendorContactLog
		WHERE VendorContactLog.VendorID = @VendorID
		GROUP BY MONTH(VendorContactLog.CreateDate)
		) va ON va.MonthNumber = m.MonthNumber
	ORDER BY m.MonthNumber
END
GO

