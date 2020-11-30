

/****** Object:  UserDefinedFunction [dbo].[fnGetCurrentProductRatesByVendorLocation]    Script Date: 08/26/2013 10:58:16 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnGetCurrentProductRatesByVendorLocation]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnGetCurrentProductRatesByVendorLocation]
GO



/****** Object:  UserDefinedFunction [dbo].[fnGetCurrentProductRatesByVendorLocation]    Script Date: 08/26/2013 10:58:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Select * From [dbo].[fnGetCurrentProductRatesByVendorLocation]() Where VendorID = 4360 and VendorLocationID is null
-- Select * From [dbo].[fnGetCurrentProductRatesByVendorLocation]() Where VendorID = 4360 and VendorLocationID = 91927
CREATE FUNCTION [dbo].[fnGetCurrentProductRatesByVendorLocation]()
RETURNS TABLE 
AS
RETURN 
(
      -- Contract must me active and within date range
      -- Related Contract Rate Schedule must be active and within date range
      SELECT 
            v.ID VendorID, c.ID ContractID, crs.ID ContractRateScheduleID, crsp.ProductID, crsp.VendorLocationID, crsp.RateTypeID, rt.Name RateName, crsp.Price, crsp.Quantity
      FROM dbo.Vendor v
      JOIN dbo.[Contract] c On c.VendorID = v.ID 
      JOIN dbo.[ContractRateSchedule] crs ON 
            crs.ContractID = c.ID AND 
            crs.ContractRateScheduleStatusID = (SELECT ID FROM ContractRateScheduleStatus WHERE Name = 'Active') AND
            crs.StartDate <= GETDATE() AND
            (crs.EndDate IS NULL OR crs.EndDate >= GETDATE())
      JOIN dbo.[ContractRateScheduleProduct] crsp On crsp.ContractRateScheduleID = crs.ID 
      JOIN RateType rt on rt.ID = crsp.RateTypeID
      WHERE 
      c.IsActive = 'TRUE' --Not Deleted
      AND c.ContractStatusID = (SELECT ID FROM ContractStatus WHERE Name = 'Active')
      AND c.StartDate <= GETDATE() 
      AND (c.EndDate IS NULL OR c.EndDate >= GETDATE())
      --AND crsp.VendorLocationID IS NULL
)


GO


