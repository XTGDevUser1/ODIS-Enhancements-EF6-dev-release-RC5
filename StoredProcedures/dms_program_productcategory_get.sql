IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_program_productcategory_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_program_productcategory_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_program_productcategory_get] 1,NULL,NULL
 
CREATE PROCEDURE [dbo].[dms_program_productcategory_get]( 
   @ProgramID int, 
   @vehicleTypeID INT = NULL,
   @vehicleCategoryID INT = NULL   
 ) 
 AS 
 BEGIN 
  
      SET NOCOUNT ON

      SELECT      PC.ID,
                  PC.Name,
                  PC.Sequence,
                  CASE WHEN EL.ID IS NULL 
                        THEN CAST(0 AS BIT)
                        ELSE CAST(1 AS BIT)
                  END AS [Enabled],
                  PC.IsVehicleRequired
      FROM  ProductCategory PC 
      LEFT JOIN
      (     SELECT DISTINCT ProductCategoryID AS ID 
            FROM  ProgramProductCategory PC
            JOIN      [dbo].[fnc_getprogramsandparents](@ProgramID) FNCP ON PC.ProgramID = FNCP.ProgramID
            AND         (VehicleTypeID = @vehicleTypeID OR VehicleTypeID IS NULL)
            AND         (VehicleCategoryID = @vehicleCategoryID OR VehicleCategoryID IS NULL)

      
      ) EL ON PC.ID = EL.ID
      WHERE PC.Name NOT IN ('Billing', 'Repair', 'MemberProduct', 'ISPSelection')
      ORDER BY PC.Sequence

END
