/****** Object:  UserDefinedFunction [dbo].[fnc_GetVendorActiveContractRateSchedule]    Script Date: 04/29/2014 02:13:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetVendorActiveContractRateSchedule]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_GetVendorActiveContractRateSchedule]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Select * From [dbo].[fnc_GetVendorContractStatus]() Where VendorID = 4360 
CREATE FUNCTION [dbo].[fnc_GetVendorActiveContractRateSchedule] ()
RETURNS @VendorContract TABLE
   (
    VendorID int,
    ContractID int,
    ContractRateScheduleID int
   )
AS
BEGIN
	-- BOTH Contract and related Contract Rate Schedule must be active and within the effective date range
	-- Need to guard against the possibility of multiple active contract/rate schedules for the same vendor
	;WITH wResults 
	AS 
	(
	SELECT 
		v.ID VendorID
		,c.ID ContractID
		,crs.ID ContractRateScheduleID
	FROM dbo.Vendor v
	JOIN dbo.[Contract] c On 
		c.VendorID = v.ID 
		AND c.IsActive = 1 --Not Deleted
		AND c.ContractStatusID = (SELECT ID FROM ContractStatus WHERE Name = 'Active')
		AND c.StartDate <= GETDATE() 
		AND (c.EndDate IS NULL OR c.EndDate >= GETDATE())
	JOIN dbo.[ContractRateSchedule] crs ON 
		crs.ContractID = c.ID AND 
		crs.ContractRateScheduleStatusID = (SELECT ID FROM ContractRateScheduleStatus WHERE Name = 'Active') AND
		crs.StartDate <= GETDATE() AND
		(crs.EndDate IS NULL OR crs.EndDate >= GETDATE())
	WHERE 
	v.IsActive = 1
	)
	
	INSERT INTO @VendorContract
	SELECT 
		r.VendorID
		,r.ContractID
		,r.ContractRateScheduleID
	FROM wResults r
	JOIN (
		SELECT VendorID, ContractID, MAX(ContractRateScheduleID) ContractRateScheduleID
		FROM wResults
		GROUP BY  VendorID, ContractID
		) r2 ON 
		r.VendorID = r2.VendorID 
		AND r.ContractID = r2.ContractID
		AND r.ContractRateScheduleID = r2.ContractRateScheduleID

	RETURN
END
GO
