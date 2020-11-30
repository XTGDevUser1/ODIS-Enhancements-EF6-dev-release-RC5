IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Phone_Number_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Phone_Number_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
 --EXEC [dms_Phone_Number_Get]  @VendorID=6,@EntityName='Vendor',@PhoneType ='Office'
 CREATE PROCEDURE [dbo].[dms_Phone_Number_Get]( 
   @VendorID INT = NULL
 , @EntityName nvarchar(50)=NULL
 , @PhoneType nvarchar(50)=NULL 
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
 	
 	SELECT		PE.PhoneNumber
FROM		Vendor V
LEFT JOIN	PhoneEntity PE WITH(NOLOCK) ON PE.RecordID = V.ID AND PE.EntityID = (SELECT ID FROM Entity WHERE Name = @EntityName)--'Vendor'
LEFT JOIN	PhoneType PT WITH(NOLOCK) ON PT.ID = PE.PhoneTypeID
WHERE		V.ID = @VendorID
AND			PE.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name =@PhoneType)
END