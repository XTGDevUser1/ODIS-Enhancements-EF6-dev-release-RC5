/****** Object:  UserDefinedFunction [dbo].[fnc_RemoveNonNumericCharacters]    Script Date: 04/29/2014 02:13:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_RemoveNonNumericCharacters]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_RemoveNonNumericCharacters]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [dbo].[fnc_RemoveNonNumericCharacters](@strText VARCHAR(1000))
RETURNS VARCHAR(1000)
AS
BEGIN
    WHILE PATINDEX('%[^0-9]%', @strText) > 0
    BEGIN
        SET @strText = STUFF(@strText, PATINDEX('%[^0-9]%', @strText), 1, '')
    END
    RETURN @strText
END
GO

GO

GO

GO

/****** Object:  UserDefinedFunction [dbo].[fnGetCoachNetDealerPartnerVendors]    Script Date: 08/26/2013 10:47:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnGetCoachNetDealerPartnerVendors]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnGetCoachNetDealerPartnerVendors]
GO



/****** Object:  UserDefinedFunction [dbo].[fnGetCoachNetDealerPartnerVendors]    Script Date: 08/26/2013 10:47:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
-- SELECT * FROM [dbo].[fnGetCoachNetDealerPartnerVendors] ()


CREATE FUNCTION [dbo].[fnGetCoachNetDealerPartnerVendors] ()
RETURNS TABLE 
AS
RETURN (

		SELECT DISTINCT VL.VendorID As VendorID						
		FROM	VendorLocation VL WITH (NOLOCK) 
		JOIN	VendorLocationProduct VLP WITH (NOLOCK) ON VLP.VendorLocationID = VL.ID
		JOIN	Product P WITH (NOLOCK) ON VLP.ProductID = P.ID
		WHERE	P.Name = 'CoachNet Dealer Partner'
		AND		ISNULL(VLP.IsActive,0) = 1		
)


GO

GO

GO
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
		,CASE WHEN MetroRate.RatePrice IS NOT NULL THEN MetroRate.RatePrice * 1.25
			WHEN StateRate.RatePrice IS NOT NULL THEN StateRate.RatePrice * 1.25
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
		Select mlpr2.ProductID, mlpr2.RateTypeID,mlpr2.Price RatePrice, mlpr2.Quantity RateQuantity
		From dbo.MarketLocation ml2
		--Added Join to eliminate issues with overlapping metro area radii
		JOIN (
			Select Min(mld.GeographyLocation.STDistance(@ServiceLocationGeography)) MinDistance
			From dbo.MarketLocation mld
			Where mld.MarketLocationTypeID = (Select ID From MarketLocationType Where Name = 'Metro')
				And mld.IsActive = 'TRUE'
				and mld.GeographyLocation.STDistance(@ServiceLocationGeography) <= mld.RadiusMiles * 1609.344
			) MetroDistance ON MetroDistance.MinDistance = ml2.GeographyLocation.STDistance(@ServiceLocationGeography)
		Left Outer Join dbo.MarketLocationProductRate mlpr2 On ml2.ID = mlpr2.MarketLocationID 

		--Select mlpr2.ProductID, mlpr2.RateTypeID, mlpr2.Price RatePrice, mlpr2.Quantity RateQuantity
		--From dbo.MarketLocation ml2
		--Left Outer Join dbo.MarketLocationProductRate mlpr2 On ml2.ID = mlpr2.MarketLocationID 
		----Left Outer Join dbo.RateType rt2 On cpr2.RateTypeID = rt2.ID
		--Where ml2.MarketLocationTypeID = (Select ID From MarketLocationType Where Name = 'Metro')
		--	And ml2.IsActive = 'TRUE'
		--	and ml2.GeographyLocation.STDistance(@ServiceLocationGeography) <= ml2.RadiusMiles * 1609.344
		
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

GO

GO

/****** Object:  UserDefinedFunction [dbo].[fnGetDirectTowVendors]    Script Date: 08/26/2013 10:47:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnGetDirectTowVendors]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnGetDirectTowVendors]
GO



/****** Object:  UserDefinedFunction [dbo].[fnGetDirectTowVendors]    Script Date: 08/26/2013 10:47:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
-- SELECT * FROM [dbo].[fnGetDirectTowVendors] ()


CREATE FUNCTION [dbo].[fnGetDirectTowVendors] ()
RETURNS TABLE 
AS
RETURN (

		SELECT DISTINCT VL.VendorID As VendorID						
		FROM	VendorLocation VL WITH (NOLOCK) 
		JOIN	VendorLocationProduct VLP WITH (NOLOCK) ON VLP.VendorLocationID = VL.ID
		JOIN	Product P WITH (NOLOCK) ON VLP.ProductID = P.ID
		WHERE	P.Name = 'Ford Direct Tow'
		AND		ISNULL(VLP.IsActive,0) = 1
		AND		VL.DealerNumber IS NOT NULL 
		AND		VL.PartsAndAccessoryCode IS NOT NULL
)


GO

GO

GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnIsUserConnected]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnIsUserConnected]
GO

CREATE FUNCTION dbo.fnIsUserConnected(@userName NVARCHAR(MAX)) RETURNS BIT
AS
BEGIN
	DECLARE @IsUserConnected BIT = 0

	IF((SELECT COUNT(NotificationID) FROM DesktopNotifications WHERE UserName = @userName AND IsConnected = 1) > 0)
	BEGIN
		SET @IsUserConnected = 1
	END

	RETURN @IsUserConnected
END


GO

GO

GO
/****** Object:  StoredProcedure [dbo].[GetHashCode]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[GetHashCode]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[GetHashCode] 
 END 
 GO  
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/*****************************************************************************/

CREATE PROCEDURE [dbo].[GetHashCode]
    @input tAppName,
    @hash int OUTPUT
AS
    /* 
       This sproc is based on this C# hash function:

        int GetHashCode(string s)
        {
            int     hash = 5381;
            int     len = s.Length;

            for (int i = 0; i < len; i++) {
                int     c = Convert.ToInt32(s[i]);
                hash = ((hash << 5) + hash) ^ c;
            }

            return hash;
        }

        However, SQL 7 doesn't provide a 32-bit integer
        type that allows rollover of bits, we have to
        divide our 32bit integer into the upper and lower
        16 bits to do our calculation.
    */
       
    DECLARE @hi_16bit   int
    DECLARE @lo_16bit   int
    DECLARE @hi_t       int
    DECLARE @lo_t       int
    DECLARE @len        int
    DECLARE @i          int
    DECLARE @c          int
    DECLARE @carry      int

    SET @hi_16bit = 0
    SET @lo_16bit = 5381
    
    SET @len = DATALENGTH(@input)
    SET @i = 1
    
    WHILE (@i <= @len)
    BEGIN
        SET @c = ASCII(SUBSTRING(@input, @i, 1))

        /* Formula:                        
           hash = ((hash << 5) + hash) ^ c */

        /* hash << 5 */
        SET @hi_t = @hi_16bit * 32 /* high 16bits << 5 */
        SET @hi_t = @hi_t & 0xFFFF /* zero out overflow */
        
        SET @lo_t = @lo_16bit * 32 /* low 16bits << 5 */
        
        SET @carry = @lo_16bit & 0x1F0000 /* move low 16bits carryover to hi 16bits */
        SET @carry = @carry / 0x10000 /* >> 16 */
        SET @hi_t = @hi_t + @carry
        SET @hi_t = @hi_t & 0xFFFF /* zero out overflow */

        /* + hash */
        SET @lo_16bit = @lo_16bit + @lo_t
        SET @hi_16bit = @hi_16bit + @hi_t + (@lo_16bit / 0x10000)
        /* delay clearing the overflow */

        /* ^c */
        SET @lo_16bit = @lo_16bit ^ @c

        /* Now clear the overflow bits */	
        SET @hi_16bit = @hi_16bit & 0xFFFF
        SET @lo_16bit = @lo_16bit & 0xFFFF

        SET @i = @i + 1
    END

    /* Do a sign extension of the hi-16bit if needed */
    IF (@hi_16bit & 0x8000 <> 0)
        SET @hi_16bit = 0xFFFF0000 | @hi_16bit

    /* Merge hi and lo 16bit back together */
    SET @hi_16bit = @hi_16bit * 0x10000 /* << 16 */
    SET @hash = @hi_16bit | @lo_16bit

    RETURN 0
GO

GO

GO

GO
/****** Object:  StoredProcedure [dbo].[Get_FordESP_FeeSupp_Select]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Get_FordESP_FeeSupp_Select]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Get_FordESP_FeeSupp_Select] 
 END 
 GO  
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--******************************************************************************************
--******************************************************************************************
--
--		exec [dbo].[Get_FordESP_FeeSupp_Select] 
--******************************************************************************************
--******************************************************************************************

CREATE Procedure [dbo].[Get_FordESP_FeeSupp_Select]
	
AS

	Select right(replicate('0',9)+convert(varchar,convert(int,bdil.Rate * 100000)),9)+'F' rate
		From dbo.BillingDefinitionInvoice bdi with(nolock)
		join dbo.BillingDefinitionInvoiceline bdil with(nolock) on bdi.Id = bdil.BillingDefinitionInvoiceID
	Where bdi.Name = 'Ford - ESP - Monthly Invoice'
		  and bdil.Sequence = 1
GO

GO

GO

GO
