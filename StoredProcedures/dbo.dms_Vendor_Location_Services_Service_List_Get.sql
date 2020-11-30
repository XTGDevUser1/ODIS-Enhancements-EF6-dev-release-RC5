/****** Object:  StoredProcedure [dbo].[dms_Vendor_Location_Services_Service_List_Get]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Location_Services_Service_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Location_Services_Service_List_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC dms_Vendor_Location_Services_Service_List_Get @VendorID=1, @VendorLocationID=1
CREATE PROCEDURE [dbo].[dms_Vendor_Location_Services_Service_List_Get](
	@VendorID INT = NULL
 ,	@VendorLocationID INT = NULL
 )
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
DECLARE @FinalResults AS TABLE(
	ServiceName nvarchar(100)  NULL ,
	ProductID int  NULL ,
	VehicleCategorySequence int  NULL ,
	ProductCategory nvarchar(100)  NULL ,
	IsAvailByVendor bit default 0 ,
	IsAvailByVendorLocation bit default 0
) 

INSERT INTO @FinalResults (ServiceName,ProductID,VehicleCategorySequence,ProductCategory)
	SELECT p.Name AS ServiceName
		  ,p.ID AS ProductID
		  ,vc.Sequence VehicleCategorySequence
		  ,pc.Name ProductCategory
		FROM Product p
		Join ProductCategory pc on p.productCategoryid = pc.id
		Join ProductType pt on p.ProductTypeID = pt.ID
		Join ProductSubType pst on p.ProductSubTypeID = pst.id
		Left Outer Join VehicleCategory vc on p.VehicleCategoryID = vc.ID
		Left Outer Join VehicleType vt on p.VehicleTypeID = vt.ID
		Where pt.Name = 'Service'
		and pst.Name IN ('PrimaryService', 'SecondaryService')
		--and p.Name Not in ('Concierge', 'Information', 'Tech')
		--and p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee')
		AND ISNULL(P.ShowOnVendorMaintenance,0) = 1
		
	UNION
	SELECT p.Name AS ServiceName
		   ,p.ID AS ProductID
		   ,vc.Sequence VehicleCategorySequence
		   ,pc.Name ProductCategory
		FROM Product p
		Join ProductCategory pc on p.productCategoryid = pc.id
		Join ProductType pt on p.ProductTypeID = pt.ID
		Join ProductSubType pst on p.ProductSubTypeID = pst.id
		Left Outer Join VehicleCategory vc on p.VehicleCategoryID = vc.ID
		Left Outer Join VehicleType vt on p.VehicleTypeID = vt.ID
		Where pt.Name = 'Service'
		and pst.Name IN ('AdditionalService')
		--and p.Name Not in ('Concierge', 'Information', 'Tech')
		--and p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials')
		AND ISNULL(P.ShowOnVendorMaintenance,0) = 1
	ORDER BY ProductCategory,VehicleCategorySequence
	
	UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
WHERE VP.VendorID=@VendorID

UPDATE @FinalResults SET IsAvailByVendorLocation = 1 FROM  @FinalResults T
LEFT JOIN VendorLocationProduct VLP ON VLP.ProductID = T.ProductID
WHERE VLP.VendorLocationID=@VendorLocationID

Select *  from @FinalResults where IsAvailByVendor=1
END
GO
