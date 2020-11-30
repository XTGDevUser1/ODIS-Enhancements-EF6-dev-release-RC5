
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Product_Save_Cascade]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Product_Save_Cascade] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Vendor_Product_Save_Cascade @vendorLocationID=289, @rateScheduleID=1
 CREATE PROCEDURE [dbo].[dms_Vendor_Product_Save_Cascade] 
 (
	  @vendorID INT = NULL 
	, @productIDs NVARCHAR(MAX) = NULL
	, @createBy NVARCHAR(50) = NULL
 )
 
AS
BEGIN 

/* KB:	When a Product is unchecked via Vendor -> Services, we need to identify the Contracts that are active or set for future.
*		Get their associated RateSchedules and delete the related CRSPs
*/

	DECLARE @now DATETIME = GETDATE()

	DECLARE @tblNewProductList TABLE	
	(
		ProductID INT NOT NULL
	)
	
	-- Dump the products chosen by the user into the temp table.
	INSERT INTO @tblNewProductList
	SELECT item FROM [dbo].[fnSplitString](@productIDs,',')
	
	;WITH wProductsToBeDeleted
	AS
	(
		SELECT		VP.ProductID
		FROM		VendorProduct VP
		LEFT OUTER JOIN @tblNewProductList T ON VP.ProductID = T.ProductID
		WHERE		T.ProductID IS NULL
		AND			VP.VendorID = @vendorID
	)
	, wCRSPsToBeDeleted
	AS
	(
		SELECT	CRSP.ID
		FROM	[Contract] C,
				ContractRateSchedule CRS,
				ContractRateScheduleProduct CRSP		
		WHERE	CRS.ContractID = C.ID
		AND		CRSP.ContractRateScheduleID = CRS.ID
		AND		VendorID = @vendorID
		AND		(DATEDIFF(dd,@now,C.StartDate) >= 0 
				OR
				C.EndDate IS NULL)
		AND		C.ContractStatusID = (SELECT ID FROM ContractStatus WHERE Name = 'Active')
		AND		C.IsActive = 1
		AND		CRS.ContractRateScheduleStatusID = (SELECT ID FROM ContractRateScheduleStatus WHERE Name = 'Active') 
		AND		CRS.IsActive = 1
		AND		CRSP.VendorLocationID IS NULL
		AND		CRSP.ProductID IN ( SELECT ProductID FROM wProductsToBeDeleted)
	)


	DELETE FROM ContractRateScheduleProduct WHERE ID IN (SELECT ID FROM wCRSPsToBeDeleted)
	
	
	DECLARE @vendorProductRatingDefault NVARCHAR(50) = NULL
	SELECT @vendorProductRatingDefault = Value FROM ApplicationConfiguration WHERE Name = 'VendorProductRatingDefault'
	
	
	-- Delete all and insert afresh
	DELETE FROM VendorProduct WHERE VendorID = @vendorID
	INSERT INTO VendorProduct		(	 VendorID
										,ProductID
										,IsActive
										,Rating
										,CreateBy
										,CreateDate
									)
	SELECT	 @vendorID
			,ProductID
			,1
			,CASE WHEN @vendorProductRatingDefault IS NULL THEN NULL ELSE CONVERT(decimal(18,4),@vendorProductRatingDefault) END
			,@createBy
			,@now
	FROM	@tblNewProductList

END

GO