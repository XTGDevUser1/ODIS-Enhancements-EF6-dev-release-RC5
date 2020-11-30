/****** Object:  UserDefinedFunction [dbo].[fnSplitString]    Script Date: 09/13/2010 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnGetDefaultProductRatesByLocation]') 
AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
 DROP FUNCTION [dbo].[fnGetDefaultProductRatesByLocation]
GO

/****** Object:  UserDefinedFunction [dbo].[fnGetDefaultProductRatesByLocation]    Script Date: 12/03/2012 11:43:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Description:	Returns default product rates by location
-- =============================================
CREATE FUNCTION [dbo].[fnGetDefaultProductRatesByLocation] 
(
	@ServiceLocationGeography geography
	,@ServiceCountryCode nvarchar(50)
	,@ServiceStateProvince nvarchar(50)
	--,@ProductID int = NULL
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT prt.ProductID, prt.RateTypeID, rt.Name
		,CASE WHEN MetroRate.RatePrice IS NOT NULL THEN MetroRate.RatePrice
			WHEN StateRate.RatePrice IS NOT NULL THEN StateRate.RatePrice
			ELSE ISNULL(GlobalDefaultRate.RatePrice,0)
			END AS RatePrice
		,CASE WHEN MetroRate.RatePrice IS NOT NULL THEN ISNULL(MetroRate.RateQuantity,0)
			WHEN StateRate.RatePrice IS NOT NULL THEN ISNULL(StateRate.RateQuantity,0)
			ELSE ISNULL(GlobalDefaultRate.RateQuantity ,0)
			END AS RateQuantity
	FROM ProductRateType prt
	JOIN RateType rt on rt.ID = prt.RateTypeID
	Left Outer Join (
		Select cpr1.ProductID, cpr1.RateTypeID, cpr1.Price AS RatePrice, cpr1.Quantity AS RateQuantity
		From dbo.VendorLocation vl1
		Left Outer Join dbo.[Contract] c1 On c1.VendorID = vl1.VendorID and c1.IsActive = 'TRUE'
		Left Outer Join dbo.ContractProductRate cpr1 On vl1.ID = cpr1.VendorLocationID 
		--Left Outer Join dbo.RateType rt1 On cpr1.RateTypeID = rt1.ID
		Where vl1.VendorLocationTypeID = (Select ID From VendorLocationType Where Name = 'GlobalDefault')
		) GlobalDefaultRate
		ON GlobalDefaultRate.ProductID = prt.ProductID AND GlobalDefaultRate.RateTypeID = prt.RateTypeID
	Left Outer Join (
		Select cpr2.ProductID, cpr2.RateTypeID, cpr2.Price RatePrice, cpr2.Quantity RateQuantity
		From dbo.VendorLocation vl2
		--Join dbo.AddressEntity addr1 On addr1.EntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'VendorLocation') and addr1.RecordID = vl2.ID and addr1.AddressTypeID = (SELECT ID FROM dbo.AddressType WHERE Name = 'Business')
		Left Outer Join dbo.[Contract] c2 On c2.VendorID = vl2.VendorID and c2.IsActive = 'TRUE'
		Left Outer Join dbo.ContractProductRate cpr2 On vl2.ID = cpr2.VendorLocationID 
		--Left Outer Join dbo.RateType rt2 On cpr2.RateTypeID = rt2.ID
		Where vl2.VendorLocationTypeID = (Select ID From VendorLocationType Where Name = 'Metro')
			And vl2.IsActive = 'TRUE'
			and vl2.GeographyLocation.STDistance(@ServiceLocationGeography) <= vl2.RadiusMiles * 1609.344
		) MetroRate 
		ON MetroRate.ProductID = prt.ProductID AND MetroRate.RateTypeID = prt.RateTypeID
	Left Outer Join
		(
		Select cpr3.ProductID,cpr3.RateTypeID, cpr3.Price RatePrice, cpr3.Quantity RateQuantity
		From dbo.VendorLocation vl3
		--Join dbo.AddressEntity addr3 On addr3.EntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'VendorLocation') and addr3.RecordID = vl3.ID and addr3.AddressTypeID = (SELECT ID FROM dbo.AddressType WHERE Name = 'Business')
		Left Outer Join dbo.[Contract] c3 On c3.VendorID = vl3.VendorID and c3.IsActive = 'TRUE'
		Left Outer Join dbo.ContractProductRate cpr3 On vl3.ID = cpr3.VendorLocationID 
		--Left Outer Join dbo.RateType rt3 On cpr3.RateTypeID = rt3.ID
		Where vl3.VendorLocationTypeID = (Select ID From VendorLocationType Where Name = 'State')
		And vl3.IsActive = 'TRUE'
		And vl3.DefaultLocationName = (@ServiceCountryCode + N'_' + @ServiceStateProvince)
		) StateRate 
		ON StateRate.ProductID = prt.ProductID AND StateRate.RateTypeID = prt.RateTypeID
	WHERE 
	--prt.ProductID = @ProductID
	--AND 
	prt.IsOptional = 'FALSE'
	AND rt.Name NOT IN ('EnrouteFree','ServiceFree')
)

GO


