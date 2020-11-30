IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Rate_Schedules_For_Report_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Rate_Schedules_For_Report_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_Rate_Schedules_For_Report_Get] 2195
 --EXEC [dbo].[dms_Rate_Schedules_For_Report_Get] 2195
 CREATE PROCEDURE [dbo].[dms_Rate_Schedules_For_Report_Get](
 @rateScheduleID INT
 )
 AS
 BEGIN
 
	SELECT 
                  @RateScheduleID AS RateScheduleID
                  ,p.ID AS ProductID
                  ,CASE 
                        WHEN p.Name = 'Mobile Mechanic' THEN 'Auto'
                        WHEN p.Name = 'Locksmith' THEN p.Name + ' *** Certified Only ***'
                        WHEN CHARINDEX(' - LD', p.Name) > 0 THEN REPLACE(p.Name, ' - LD', '')
                        WHEN CHARINDEX(' - MD', p.Name) > 0 THEN REPLACE(p.Name, ' - MD', '')
                        WHEN CHARINDEX(' - HD', p.Name) > 0 THEN REPLACE(p.Name, ' - HD', '')
                        WHEN CHARINDEX('Mobile Mechanic - ', p.Name) > 0 THEN REPLACE(p.Name, 'Mobile Mechanic - ', '')
                        ELSE p.Name 
                        END AS ProductName
                  ,CASE COALESCE(vc.Name, pc.Name)
                        WHEN 'LightDuty' THEN 1
                        WHEN 'MediumDuty' THEN 2
                        WHEN 'HeavyDuty' THEN 3
                        WHEN 'Lockout' THEN 4
                        WHEN 'Home Locksmith' THEN 4
                        WHEN 'Mobile' THEN 5
                        ELSE 99
                        END AS ProductGroup
                  ,vc.Name VehicleCategory
                  ,pc.Name ProductCategory
                  ,pc.Sequence ProductCategorySequence
                  ,MAX(CASE WHEN rt.Name IN ('Base', 'Hourly') AND ISNULL(VendorDefaultRates.Price,0.00) <> 0.00 THEN 1 ELSE 0 END) AS ProductIndicator
                  ,SUM(CASE WHEN rt.Name = 'Base' THEN 
                        (CASE WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Price  
                        ELSE 0.00   
                        END) 
                        ELSE 0 END) AS BaseRate
                  ,SUM(CASE WHEN rt.Name = 'Enroute' THEN 
                        (CASE WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Price  
                        ELSE 0.00   
                        END) 
                        ELSE 0 END) AS EnrouteRate
                  ,SUM(CASE WHEN rt.Name = 'EnrouteFree' THEN 
                        (CASE WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Quantity  
                        ELSE 0.00   
                        END) 
                        ELSE 0 END) AS EnrouteFreeMiles
                  ,SUM(CASE WHEN rt.Name = 'Service' THEN 
                        (CASE WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Price  
                        ELSE 0.00   
                        END) 
                        ELSE 0 END) AS ServiceRate
                  ,SUM(CASE WHEN rt.Name = 'ServiceFree' THEN 
                        (CASE WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Quantity  
                        ELSE 0.00   
                        END) 
                        ELSE 0 END) AS ServiceFreeMiles
                  ,SUM(CASE WHEN rt.Name = 'Hourly' THEN 
                        (CASE WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Price  
                        ELSE 0.00   
                        END) 
                        ELSE 0 END) AS HourlyRate
                  ,SUM(CASE WHEN rt.Name = 'GoneOnArrival' THEN 
                        (CASE WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Price  
                        ELSE 0.00   
                        END) 
                        ELSE 0 END) AS GOARate
      FROM dbo.Product p 
      JOIN dbo.ProductRateType prt ON prt.ProductID = p.ID --AND prt.RateTypeID = VendorDefaultRates.RateTypeID
      JOIN dbo.RateType rt ON prt.RateTypeID = rt.ID 
      JOIN dbo.ProductCategory pc ON p.ProductCategoryID = pc.ID
      LEFT OUTER JOIN dbo.VehicleCategory vc ON p.VehicleCategoryID = vc.ID
      LEFT OUTER JOIN dbo.fnGetAllProductRatesByVendorLocation() VendorDefaultRates  
            ON VendorDefaultRates.ContractRateScheduleID = @rateScheduleID 
            AND p.ID = VendorDefaultRates.ProductID  
            AND rt.ID = VendorDefaultRates.RateTypeID
      WHERE 
            p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')
            AND (
				 (p.ProductSubTypeID IN (SELECT ID FROM ProductSubType WHERE Name IN ('PrimaryService','SecondaryService')))
				 OR 
				 (p.ProductSubTypeID IN (SELECT ID FROM ProductSubType WHERE Name = 'AdditionalService')
				  AND p.Name IN ('Tow - Drop Drive Line','Tow - Dollies'))
				)
			AND p.Name NOT IN ('Tow - LD - White Glove')
            AND p.IsShowOnPO = 1 
      GROUP BY 
            p.ID   
            ,p.Name
            ,vc.Name 
            --,vc.Sequence 
            ,pc.Name 
            ,pc.Sequence 
      ORDER BY 
        CASE COALESCE(vc.Name, pc.Name)
            WHEN 'LightDuty' THEN 1
            WHEN 'MediumDuty' THEN 2
            WHEN 'HeavyDuty' THEN 3
            WHEN 'Lockout' THEN 4
            WHEN 'Home Locksmith' THEN 4
            WHEN 'Mobile' THEN 5
            ELSE 99
            END
            ,pc.Sequence
            ,p.Name


 END
GO

