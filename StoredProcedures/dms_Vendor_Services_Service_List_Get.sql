IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Vendor_Services_Service_List_Get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Vendor_Services_Service_List_Get]
GO

--EXEC dms_Vendor_Services_Service_List_Get @VendorID=1
CREATE PROCEDURE [dbo].[dms_Vendor_Services_Service_List_Get] @VendorID INT
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
	IsAvailByVendor bit default 0
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
		and p.Name Not in ('Concierge', 'Information', 'Tech')
		and p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee')
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
		and p.Name Not in ('Concierge', 'Information', 'Tech')
		and p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials')
	ORDER BY ProductCategory,VehicleCategorySequence
	
	UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
WHERE VP.VendorID=@VendorID

Select * from @FinalResults
END
GO

