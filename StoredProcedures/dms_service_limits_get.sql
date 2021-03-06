IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_service_limits_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_service_limits_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

-- EXEC [dbo].[dms_service_limits_get] @programID = 3,@vehicleCategoryID = 1

 CREATE PROCEDURE [dbo].[dms_service_limits_get]( 

   @programID INT = NULL,

   @vehicleCategoryID INT = NULL 

 ) 

 AS 

 BEGIN 
 SET FMTONLY OFF
 

 DECLARE @tmpPrograms TABLE

(

	LevelID INT IDENTITY(1,1),

	ProgramID INT

)



INSERT INTO @tmpPrograms

SELECT ProgramID FROM fnc_GetProgramsandParents (@programID)


;With PPAll
As
(
	SELECT	DISTINCT TP.LevelID, 
	pc.Name AS ProductCategoryName,
	ROW_NUMBER() OVER (PARTITION BY pc.Name ORDER BY TP.LevelID ASC) AS RowNum,
			pp.ServiceCoverageLimit,
			P.Name AS ProductName

	FROM	ProgramProduct pp WITH (NOLOCK)

	LEFT JOIN Program pr WITH (NOLOCK) on pr.ID = pp.ProgramID

	LEFT JOIN Product p WITH (NOLOCK) on p.ID = pp.ProductID 

	LEFT JOIN ProductCategory pc WITH (NOLOCK) on pc.ID = p.ProductCategoryID	

	JOIN @tmpPrograms TP ON pr.ID = TP.ProgramID

	AND	 (p.VehicleCategoryID IS NULL OR	p.VehicleCategoryID = @vehicleCategoryID)

	WHERE P.ProductSubTypeID = (select ID from ProductSubType where name = 'PrimaryService') -- CR: 1052

	AND		(PC.Name <> 'Lockout' OR (PC.Name = 'Lockout' AND P.Name = 'Basic Lockout')) -- If is locksmith, take the basic lockout and exclude the other.

	GROUP BY TP.LevelID,pc.Name, pp.ServiceCoverageLimit,P.Name

	)
SELECT ProductCategoryName,ServiceCoverageLimit FROM PPAll WHERE RowNum = 1


 END

 

