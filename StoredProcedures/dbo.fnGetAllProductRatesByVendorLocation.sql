
/****** Object:  UserDefinedFunction [dbo].[fnGetAllProductRatesByVendorLocation]    Script Date: 08/26/2013 10:47:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnGetAllProductRatesByVendorLocation]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnGetAllProductRatesByVendorLocation]
GO



/****** Object:  UserDefinedFunction [dbo].[fnGetAllProductRatesByVendorLocation]    Script Date: 08/26/2013 10:47:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[fnGetAllProductRatesByVendorLocation] ()
RETURNS TABLE 
AS
RETURN 
(
      -- Contract must me active and within date range
      -- Related Contract Rate Schedule must be active and within date range
      SELECT 
            v.ID VendorID
            ,c.ID ContractID
            ,(SELECT Name FROM ContractStatus WHERE ID = c.ContractStatusID) ContractStatus
            ,c.StartDate ContractStartDate
            ,c.EndDate ContractEndDate
            ,crs.ID ContractRateScheduleID
            ,(SELECT Name FROM ContractRateScheduleStatus WHERE ID = crs.ContractRateScheduleStatusID) ContractRateScheduleStatus
            ,crs.StartDate ContractRateScheduleStartDate
            ,crs.EndDate ContractRateScheduleEndDate
            ,crsp.ProductID
            ,crsp.VendorLocationID
            ,crsp.RateTypeID
            ,rt.Name RateName
            ,crsp.Price
            ,crsp.Quantity
      FROM dbo.Vendor v
      JOIN dbo.[Contract] c On c.VendorID = v.ID AND c.IsActive = 1
      JOIN dbo.[ContractRateSchedule] crs ON crs.ContractID = c.ID AND crs.IsActive = 1
      JOIN dbo.[ContractRateScheduleProduct] crsp On crsp.ContractRateScheduleID = crs.ID 
      JOIN RateType rt on rt.ID = crsp.RateTypeID
)

GO


