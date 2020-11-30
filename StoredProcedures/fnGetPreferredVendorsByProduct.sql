-- Select * From [dbo].[fnGetPreferredVendorsByProduct]() Where VendorID = 4360   
CREATE FUNCTION [dbo].[fnGetPreferredVendorsByProduct] ()  
RETURNS TABLE   
AS  
RETURN   
(  
	Select v.ID VendorID, Preferred.ProductID, Preferred.PreferredCategory  
	From vendor v
	Join VendorProduct vp on vp.VendorID = v.ID
	Join Product p on p.ID = vp.ProductID
	Join ProductCategory pc on pc.ID = p.ProductCategoryID
	Join ProductType pt on pt.ID = p.ProductTypeID
	Join ProductSubType pst on pst.ID = p.ProductSubTypeID
	Join (
		Select p.ID ProductID
			--, pc.Name, p.Name,
			,Case 
				 When pc.Name In ('Tow','Winch') And vc.Name = 'HeavyDuty'  Then 'Preferred - HD Tow'
				 When pc.Name In ('Tow','Winch') And vc.Name = 'MediumDuty' Then 'Preferred - MD Tow'
				 When pc.Name In ('Tow','Winch') And vc.Name = 'LightDuty'  Then 'Preferred - LD Tow'
				 When vc.Name = 'HeavyDuty'  Then 'Preferred - HD Service Call'
				 When vc.Name = 'MediumDuty' Then 'Preferred - MD Service Call'
				 Else 'Preferred - LD Service Call'
				 End PreferredCategory
			--,p.Name, pst.Name, pc.Name, vc.Name, p.*
		From Product p
		Join ProductCategory pc on pc.ID = p.ProductCategoryID
		Join ProductType pt on pt.ID = p.ProductTypeID
		Join ProductSubType pst on pst.ID = p.ProductSubTypeID
		Left Outer Join VehicleCategory vc on vc.ID = p.VehicleCategoryID
		Where pst.Name IN ('PrimaryService','SecondaryService')
		and pc.Name not in ('Mobile','Home Locksmith')
		and p.IsShowOnPO = 1
		) Preferred on Preferred.PreferredCategory = p.Name
	Where pc.Name = 'ISPSelection'
	and pt.Name = 'Attribute'
	and pst.Name = 'Ranking'
)  




