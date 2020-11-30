/****** Object:  UserDefinedFunction [dbo].[fnGetDefaultProductRatesByMarketLocation]    Script Date: 07/30/2014 14:02:41 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnGetDefaultProductRatesByMarketLocation]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnGetDefaultProductRatesByMarketLocation]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Description:	Returns default product rates by location
-- =============================================
CREATE FUNCTION [dbo].[fnGetDefaultProductRatesByMarketLocation] 
(
	@ServiceLocationGeography geography
	,@ServiceCountryCode nvarchar(50)
	,@ServiceStateProvince nvarchar(50)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT prt.ProductID, prt.RateTypeID, rt.Name
		,CASE WHEN MetroRate.RatePrice IS NOT NULL THEN MetroRate.RatePrice * 1.10
			WHEN StateRate.RatePrice IS NOT NULL THEN StateRate.RatePrice * 1.10
			ELSE ISNULL(GlobalDefaultRate.RatePrice,0)
			END AS RatePrice
		,CASE WHEN MetroRate.RatePrice IS NOT NULL THEN ISNULL(MetroRate.RateQuantity,0)
			WHEN StateRate.RatePrice IS NOT NULL THEN ISNULL(StateRate.RateQuantity,0)
			ELSE ISNULL(GlobalDefaultRate.RateQuantity ,0)
			END AS RateQuantity
	FROM ProductRateType prt
	JOIN RateType rt on rt.ID = prt.RateTypeID
	Left Outer Join (
		Select mlpr1.ProductID, mlpr1.RateTypeID, mlpr1.Price AS RatePrice, mlpr1.Quantity AS RateQuantity
		From dbo.MarketLocation ml1
		Left Outer Join dbo.MarketLocationProductRate mlpr1 On ml1.ID = mlpr1.MarketLocationID 
		--Left Outer Join dbo.RateType rt1 On cpr1.RateTypeID = rt1.ID
		Where ml1.MarketLocationTypeID = (Select ID From MarketLocationType Where Name = 'GlobalDefault')
		) GlobalDefaultRate
		ON GlobalDefaultRate.ProductID = prt.ProductID AND GlobalDefaultRate.RateTypeID = prt.RateTypeID
	Left Outer Join (
		Select mlpr2.ProductID, mlpr2.RateTypeID, mlpr2.Price RatePrice, mlpr2.Quantity RateQuantity
		From dbo.MarketLocation ml2
		Left Outer Join dbo.MarketLocationProductRate mlpr2 On ml2.ID = mlpr2.MarketLocationID 
		--Left Outer Join dbo.RateType rt2 On cpr2.RateTypeID = rt2.ID
		Where ml2.MarketLocationTypeID = (Select ID From MarketLocationType Where Name = 'Metro')
			And ml2.IsActive = 'TRUE'
			and ml2.GeographyLocation.STDistance(@ServiceLocationGeography) <= ml2.RadiusMiles * 1609.344
		) MetroRate 
		ON MetroRate.ProductID = prt.ProductID AND MetroRate.RateTypeID = prt.RateTypeID
	Left Outer Join
		(
		Select mlpr3.ProductID,mlpr3.RateTypeID, mlpr3.Price RatePrice, mlpr3.Quantity RateQuantity
		From dbo.MarketLocation ml3
		Left Outer Join dbo.MarketLocationProductRate mlpr3 On ml3.ID = mlpr3.MarketLocationID 
		--Left Outer Join dbo.RateType rt3 On cpr3.RateTypeID = rt3.ID
		Where ml3.MarketLocationTypeID = (Select ID From MarketLocationType Where Name = 'State')
		And ml3.IsActive = 'TRUE'
		And ml3.Name = (@ServiceCountryCode + N'_' + @ServiceStateProvince)
		) StateRate 
		ON StateRate.ProductID = prt.ProductID AND StateRate.RateTypeID = prt.RateTypeID
	WHERE 
	prt.IsOptional = 'FALSE'
	AND rt.Name NOT IN ('EnrouteFree','ServiceFree')
)

GO


