IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ContactLogLink_Update_For_PurchaseOrderIssuing]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ContactLogLink_Update_For_PurchaseOrderIssuing] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_ContactLogLink_Update_For_PurchaseOrderIssuing]( 
   @ServiceRequestID INT = NULL 
 , @POID Int = NULL
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
 	
	DECLARE @EID AS INT
	SET @EID = (SELECT ID FROM Entity WHERE Name  = 'PurchaseOrder')

	INSERT INTO ContactLogLink([ContactLogID],[EntityID],[RecordID]) 
	SELECT CL.ID,@EID,@POID
	FROM   ContactLog CL
          LEFT JOIN ContactMethod CM ON CL.ContactMethodID = CM.ID
          LEFT JOIN ContactType CT ON CL.ContactTypeID = CT.ID
          LEFT JOIN ContactCategory CC ON CL.ContactCategoryID = CC.ID
          LEFT JOIN ContactLogLink CLL ON CL.ID = CLL.ContactLogID
          INNER JOIN Entity E ON CLL.EntityID = E.ID
	WHERE  CT.Name  = 'Vendor'
	AND    CM.Name = 'Phone'
	AND    CC.Name = 'VendorSelection'
	AND       E.Name = 'ServiceRequest' 
	AND    CLL.RecordID = @ServiceRequestID
	AND NOT EXISTS(SELECT 1 FROM ContactLogLink CLL WHERE CLL.ContactLogID = CL.ID AND EntityID = @EID)



END