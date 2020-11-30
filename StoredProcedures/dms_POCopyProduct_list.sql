
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_POCopyProduct_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_POCopyProduct_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_POCopyProduct_list] 1,1,1
 CREATE PROCEDURE [dbo].[dms_POCopyProduct_list]
 (
 @VehicleTypeID int=null,
 @VehicleCategoryID int=null,
 @ProgramID INT = NULL
 )
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

    select P.* 
	from Product P
	JOIN ProgramProduct PP ON PP.ProductID = P.ID
    where
		p.ProductTypeID = 1 and ISNULL(p.IsShowOnPO, 0) = 1
		and P.ProducTSubTypeID in (1,2)
		and (p.VehicleCategoryID = @VehicleCategoryID or p.VehicleCategoryID is null)
		and (p.VehicleTypeID = @VehicleTypeID or p.VehicleTypeID is null)
		AND PP.ProgramID = @ProgramID
		order by p.name
END
