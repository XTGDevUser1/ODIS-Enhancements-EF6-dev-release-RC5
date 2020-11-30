
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Location_Product_Save_Cascade]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Location_Product_Save_Cascade] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Vendor_Location_Product_Save_Cascade @vendorLocationID=292, @productIDs='1,2,3',@createBy = 'system'
 CREATE PROCEDURE [dbo].[dms_Vendor_Location_Product_Save_Cascade] 
 (
	  @vendorLocationID INT = NULL 
	, @productIDs NVARCHAR(MAX) = NULL
	, @createBy NVARCHAR(50) = NULL
 )
 
AS
BEGIN 

	/* KB:	When a Product is unchecked via VendorLocation -> Services, Get active RateSchedules and delete the related CRSPs */

	DECLARE @now DATETIME = GETDATE()

	DECLARE @tblNewProductList TABLE	
	(
		ProductID INT NOT NULL,
		Rating Decimal NULL
	)
	
	-- Dump the products chosen by the user into the temp table.
	INSERT INTO @tblNewProductList(ProductID)
	SELECT item FROM [dbo].[fnSplitString](@productIDs,',')
	
	
	UPDATE
		@tblNewProductList
	SET
		Rating = VLP.Rating
	FROM
		@tblNewProductList TBPL
	INNER JOIN
		VendorLocationProduct VLP 
	ON 
		TBPL.ProductID = VLP.ProductID AND VLP.VendorLocationID = @vendorLocationID
    
	

	;WITH wProductsToBeDeleted
	AS
	(
		SELECT		VLP.ProductID
		FROM		VendorLocationProduct VLP
		LEFT OUTER JOIN @tblNewProductList T ON VLP.ProductID = T.ProductID
		WHERE		T.ProductID IS NULL
		AND			VLP.VendorLocationID = @vendorLocationID
	)	
	,wCRSPsToBeDeleted
	AS
	(
		SELECT	CRSP.ID
		FROM	ContractRateScheduleProduct CRSP,
				ContractRateSchedule CRS		
		WHERE	CRSP.ContractRateScheduleID = CRS.ID
		AND		CRS.ContractRateScheduleStatusID = (SELECT ID FROM ContractRateScheduleStatus WHERE Name = 'Active') 
		AND		CRS.IsActive = 1
		AND		CRSP.VendorLocationID = @vendorLocationID
		AND		CRSP.ProductID IN ( SELECT ProductID FROM wProductsToBeDeleted)
	)


	DELETE FROM ContractRateScheduleProduct WHERE ID IN (SELECT ID FROM wCRSPsToBeDeleted)
	
	-- Delete all and insert afresh
	DELETE FROM VendorLocationProduct WHERE VendorLocationID = @vendorLocationID
	INSERT INTO VendorLocationProduct (	 VendorLocationID
										,ProductID
										,Rating
										,IsActive
										,CreateBy
										,CreateDate
									)
	SELECT	 @vendorLocationID
			,ProductID
			,Rating
			,1
			,@createBy
			,@now
	FROM	@tblNewProductList
			 

END

GO