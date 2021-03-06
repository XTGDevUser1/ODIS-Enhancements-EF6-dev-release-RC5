
/****** Object:  UserDefinedFunction [dbo].[fnc_GetProgramProductForProgram]    Script Date: 11/02/2012 13:08:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [dbo].[fnc_GetProgramProductForProgram] (@ProgramID int, @ProductType nvarchar(50))
RETURNS @ProgramProduct TABLE
   (
    ProgramProductID     int,
    ProductCategory		 varchar(50)
   )
AS
BEGIN

			
		;WITH wProgramProduct
		AS
		(
			SELECT pp.ID , 
			pc.Description as ProductCategory,
			pr.ID as ProgramID,
			pr.ParentProgramID 
			FROM ProgramProduct pp
			JOIN Program pr ON pr.ID = pp.ProgramID 
			JOIN Product p on pp.productid = p.id
			JOIN productcategory pc on pc.id = p.productcategoryid
			JOIN ProductType pt on pt.ID = p.ProductTypeID 
			WHERE ProgramID = (SELECT TOP 1 PP.ProgramID 
									FROM ProgramProduct
									JOIN fnc_GetProgramsandParents(@ProgramID) fnc ON fnc.ProgramID = PP.ProgramID
									ORDER BY fnc.Sequence)
			AND pt.Name = @ProductType
			AND P.IsActive = 1 
			
			
			UNION ALL
			
			SELECT pp.ID , 
			pc.Description as ProductCategory ,
			pr.ID as ProgramID,
			pr.ParentProgramID 
			FROM ProgramProduct pp
			JOIN wProgramProduct wP on pp.ProgramID = wP.ParentProgramID
			JOIN Program pr ON pr.ID = pp.ProgramID 
			JOIN Product p on pp.productid = p.id
			JOIN productcategory pc on pc.id = p.productcategoryid
			JOIN ProductType pt on pt.ID = p.ProductTypeID 
			WHERE pt.Name = @ProductType
			AND pc.Description <> wp.ProductCategory --Do not get items already defined at previous level
			AND p.IsActive = 1 
			
		)

		INSERT @ProgramProduct 
		SELECT DISTINCT ID, ProductCategory  from wProgramProduct  
		ORDER BY ProductCategory 
	
		

RETURN 

END