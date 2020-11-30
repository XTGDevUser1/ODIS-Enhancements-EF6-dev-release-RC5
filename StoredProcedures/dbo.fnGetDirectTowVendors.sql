
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

