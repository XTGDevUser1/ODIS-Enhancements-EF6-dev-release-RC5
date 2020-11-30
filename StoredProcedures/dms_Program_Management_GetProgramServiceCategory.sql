IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_GetProgramServiceCategory]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_GetProgramServiceCategory] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Program_Management_GetProgramServiceCategory 100
 CREATE PROCEDURE [dbo].[dms_Program_Management_GetProgramServiceCategory]( 
 @programServiceCategoryId INT
 )
 AS
 BEGIN
 DECLARE @maxSequnceNumber INT =0
 DECLARE @bitIsActive BIT = 0
 SET @maxSequnceNumber = (SELECT MAX(Sequence) FROM ProgramProductCategory)
 IF EXISTS (SELECT * FROM ProgramProductCategory WHERE ID = @programServiceCategoryId)
 BEGIN
	 SELECT 
		PPC.ID,
		PPC.ProductCategoryID,
		PPC.ProgramID,
		PPC.VehicleCategoryID,
		PPC.VehicleTypeID,
		PPC.Sequence,
		PPC.IsActive,
		@maxSequnceNumber+1 AS MaxSequnceNumber
	
FROM ProgramProductCategory ppc
WHERE PPC.ID = @programServiceCategoryId
END
ELSE
BEGIN 
	SELECT
		0 AS ID,
		1 AS ProductCategoryID,
		0 AS ProgramID,
		null AS VehicleCategoryID,
		null AS VehicleTypeID,
		null AS Sequence,
		@bitIsActive AS IsActive,
		@maxSequnceNumber+1 AS MaxSequnceNumber
		
END
 END