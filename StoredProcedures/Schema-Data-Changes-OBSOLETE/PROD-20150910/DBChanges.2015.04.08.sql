ALTER TABLE Product ADD ShowOnVendorPortal bit null
ALTER TABLE Product ADD ShowOnVendorMaintenance bit null


UPDATE Product Set ShowOnVendorMaintenance = 0, ShowOnVendorPortal = 0

--Select p.ID, p.Name, pt.Name ProductType, pst.Name ProductSubType
UPDATE p SET ShowOnVendorMaintenance = 1
	FROM Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('PrimaryService', 'SecondaryService', 'AdditionalService')
	AND p.Name not in ('Concierge', 'Information', 'Tech', 'Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials')
	
UPDATE p SET ShowOnVendorMaintenance = 1
	FROM Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	WHERE pt.Name = 'Attribute'
	and pc.Name in ('Repair','ISPSelection')	


--Select p.ID, p.Name, pt.Name ProductType, pst.Name ProductSubType
UPDATE p SET ShowOnVendorPortal = 1
	FROM Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('PrimaryService', 'SecondaryService', 'AdditionalService')
	AND p.Name not in ('Concierge', 'Information', 'Tech', 'Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials','Tow - LD - Lamborghini','Tow - LD - White Glove','Diagnostics','Storage Fee - Auto','Storage Fee - RV')

UPDATE p SET ShowOnVendorPortal = 1
	FROM Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	WHERE pt.Name = 'Attribute'
	and pc.Name in ('Repair')	
    and pst.Name NOT IN ('Client')


