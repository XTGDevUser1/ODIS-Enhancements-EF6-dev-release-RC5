

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Dashboard_ServiceCallActivity]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Dashboard_ServiceCallActivity]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
CREATE PROC dms_Vendor_Dashboard_ServiceCallActivity(@VendorID INT = NULL)
AS
BEGIN
	/* Month numbers for the last 12 months */
	DECLARE @Months TABLE (MonthNumber int)
	
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-11, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-10, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-9, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-8, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-7, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-6, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-5, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-4, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-3, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-2, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-1, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-0, getdate())))

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
	--ORDER BY m.MonthNumber
END
