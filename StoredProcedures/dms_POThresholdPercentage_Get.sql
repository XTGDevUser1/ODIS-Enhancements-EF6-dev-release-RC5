
/****** Object:  StoredProcedure [dbo].[dms_POThresholdPercentage_Get]    Script Date: 06/09/2016 16:50:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_POThresholdPercentage_Get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_POThresholdPercentage_Get]
GO

/****** Object:  StoredProcedure [dbo].[dms_POThresholdPercentage_Get]    Script Date: 06/09/2016 16:50:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
/*
	EXEC [dms_POThresholdPercentage_Get] @VehicleCategoryID = 1, @ProductCategoryID = 2, @VendorID = 3
	EXEC [dms_POThresholdPercentage_Get] 1,0,615,null,2

*/
/*
	EXEC [dms_POThresholdPercentage_Get] @VehicleCategoryID = 1, @ProductCategoryID = 2, @VendorID = 3
	EXEC [dms_POThresholdPercentage_Get] 1,0,615,null,2

*/
CREATE PROCEDURE [dbo].[dms_POThresholdPercentage_Get] (
	@VehicleCategoryID int,
	@ProductCategoryID int,
	@VendorID int,
	@ClientID int = NULL,
	@ProgramID int = NULL
)
AS
BEGIN

	---- DEBUG
	--Declare @ClientID int = 1
	--	,@ProgramID int = 2
	--	,@VendorID int = 3
	--	,@VehicleCategoryID int = 1
	--	,@ProductCategoryID int = 2

	If EXISTS (Select * From dbo.fnGetContractedVendors() Where VendorID = @VendorID)
		Select 0.5 AS ThresholdPercentage
	Else
		Select Top 1 x.ThresholdPercentage AS ThresholdPercentage
		FROM (	
			Select ThresholdPercentage, 1 as RankSort 
			From PurchaseOrderThresholdPercentage tp
			Where tp.VehicleCategoryID = @VehicleCategoryID
			and tp.ProductCategoryID = @ProductCategoryID
			and tp.ClientID = @ClientID and tp.ProgramID = @ProgramID

			UNION 
			Select ThresholdPercentage, 2 as RankSort 
			From PurchaseOrderThresholdPercentage tp
			Where tp.VehicleCategoryID = @VehicleCategoryID
			and tp.ProductCategoryID = @ProductCategoryID
			and tp.ClientID = @ClientID and tp.ProgramID IS NULL

			UNION 
			Select ThresholdPercentage, 3 as RankSort 
			From PurchaseOrderThresholdPercentage tp
			Where tp.VehicleCategoryID = @VehicleCategoryID
			and tp.ProductCategoryID = @ProductCategoryID
			and tp.ClientID IS NULL and tp.ProgramID IS NULL
			) x
		ORDER BY RankSort

END
GO

