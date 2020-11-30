/*******************
* Operator Enums 
*  Conditions Enum :
* -1 - No filter
*  0 - Null
*  1 - Not Null
*  2 - Equals
*  3 - NotEquals
*  ---- for strings ---
*  4 - StartsWith
*  5 - EndsWith
*  6 - Contains
*  ---- for int, decimal, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Products_For_ProductCategory_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Products_For_ProductCategory_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_Products_For_ProductCategory_List_Get]
 CREATE PROCEDURE [dbo].[dms_Products_For_ProductCategory_List_Get]( 
   @productCategoryID INT = NULL 
 ) 
 AS 
 BEGIN 

SELECT 
	  p.ID
	, p.Name
	, p.IsActive
FROM Product p 
WHERE (p.ProductCategoryid = @ProductCategoryID OR @ProductCategoryID IS NULL)
AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')
AND p.ProductSubTypeID IN (SELECT ID FROM ProductSubType WHERE Name IN ('PrimaryService','SecondaryService'))
AND p.IsActive = 1 AND p.Name IS NOT NULL
 

 
 END