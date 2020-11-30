IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Member_Product_Provider_List_Get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Member_Product_Provider_List_Get]
GO

-- EXEC [dms_Member_Product_Provider_List_Get] 898
 CREATE PROCEDURE [dbo].[dms_Member_Product_Provider_List_Get](
 @memberId INT = NULL)
 AS 
 BEGIN 	
	SELECT 
		PP.*
	FROM 
		ProductProvider PP
		LEFT JOIN MemberProduct MP WITH(NOLOCK) ON MP.ProductProviderID = PP.ID	
	WHERE MP.MemberID = @memberId	
	
 END
GO

