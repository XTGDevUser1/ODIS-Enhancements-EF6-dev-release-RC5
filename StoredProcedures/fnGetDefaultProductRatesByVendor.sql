/****** Object:  UserDefinedFunction [dbo].[fnSplitString]    Script Date: 09/13/2010 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnGetDefaultProductRatesByVendor]') 
AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
 DROP FUNCTION [dbo].[fnGetDefaultProductRatesByVendor]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetDefaultProductRatesByVendor]    Script Date: 12/03/2012 11:43:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fnGetDefaultProductRatesByVendor] ()
RETURNS TABLE 
AS
RETURN 
(
	SELECT 
		v.ID VendorID, cpr.ProductID, cpr.RateTypeID, rt.Name RateName, cpr.Price AS RatePrice, cpr.Quantity AS RateQuantity
	FROM dbo.Vendor v
	JOIN dbo.VendorLocation vl 
		ON v.ID = vl.VendorID 
	JOIN dbo.[Contract] c On c.VendorID = vl.VendorID 
	JOIN dbo.ContractProductRate cpr On vl.ID = cpr.VendorLocationID AND cpr.ContractID = c.ID
	JOIN RateType rt on rt.ID = cpr.RateTypeID
	WHERE --v.ID = @VendorID AND cpr.ProductID = @ProductID AND cpr.RateTypeID = @RateTypeID AND
	c.IsActive = 'TRUE'
	AND vl.Sequence = 0
	AND vl.VendorLocationTypeID = (SELECT ID FROM VendorLocationType WHERE Name = 'Physical')
)
GO

