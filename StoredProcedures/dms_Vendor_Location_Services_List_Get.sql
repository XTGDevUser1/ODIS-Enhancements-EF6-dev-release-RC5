IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Location_Services_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Location_Services_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 --EXEC dms_Vendor_Location_Services_List_Get @VendorID=1, @VendorLocationID=1
CREATE PROCEDURE [dms_Vendor_Location_Services_List_Get](
	@VendorID INT = NULL
 ,	@VendorLocationID INT = NULL
 )
AS
BEGIN	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
DECLARE @FinalResults AS TABLE(
	SortOrder INT NULL,
	ServiceGroup NVARCHAR(255) NULL,
	ServiceName nvarchar(100)  NULL ,
	ProductID int  NULL ,
	VehicleCategorySequence int  NULL ,
	ProductCategory nvarchar(100)  NULL ,
	IsAvailByVendor bit default 0 ,
	IsAvailByVendorLocation bit default 0
) 

INSERT INTO @FinalResults (SortOrder, ServiceGroup,ServiceName,ProductID,VehicleCategorySequence,ProductCategory)
	SELECT 
			 CASE	WHEN vc.name is NULL THEN 2 
					ELSE 1 
			 END AS SortOrder
			,CASE	WHEN vc.name is NULL THEN 'Other' 
					ELSE vc.name 
			 END AS ServiceGroup
			,REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
			--,ISNULL(vc.Name,'') + CASE WHEN ISNULL(vc.Name,'') <> '' THEN ' - ' ELSE '' END  + REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory			
	FROM Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
	LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('PrimaryService', 'SecondaryService')
	--AND p.Name Not in ('Concierge', 'Information', 'Tech')
	--AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee')
	AND ISNULL(P.ShowOnVendorMaintenance,0) = 1

	UNION
	SELECT 
			3 AS SortOrder
			,'Additional' AS ServiceGroup
			,p.Name AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory
	FROM	Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
	LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('AdditionalService')
	--AND p.Name Not in ('Concierge', 'Information', 'Tech')
	--AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials')
	AND ISNULL(P.ShowOnVendorMaintenance,0) = 1
	
	UNION ALL
	
	SELECT 
			 4 AS SortOrder
			,'Repair' AS ServiceGroup
			, p.Name AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory
	FROM	Product p
	Join	ProductCategory pc on p.productCategoryid = pc.id
	Join	ProductType pt on p.ProductTypeID = pt.ID
	Join	ProductSubType pst on p.ProductSubTypeID = pst.id
	Left Outer Join VehicleCategory vc on p.VehicleCategoryID = vc.ID
	Left Outer Join VehicleType vt on p.VehicleTypeID = vt.ID
	Where	pt.Name = 'Attribute'
	and		pc.Name = 'Repair'
	and		pst.Name NOT IN ('Client')	
	AND ISNULL(P.ShowOnVendorMaintenance,0) = 1
	ORDER BY SortOrder, VehicleCategorySequence, ProductCategory
	
	UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
	LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
	WHERE VP.VendorID=@VendorID

	UPDATE @FinalResults SET IsAvailByVendorLocation = 1 FROM  @FinalResults T
	LEFT JOIN VendorLocationProduct VLP ON VLP.ProductID = T.ProductID
	WHERE VLP.VendorLocationID=@VendorLocationID

	SELECT *  FROM @FinalResults WHERE IsAvailByVendor=1 OR IsAvailByVendorLocation = 1
END
GO
