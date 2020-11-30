IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Contract_Status_Get]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Contract_Status_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_Vendor_Contract_Status_Get] 337
 CREATE PROCEDURE [dbo].[dms_Vendor_Contract_Status_Get]( 
  @VendorID INT = NULL
) 
 AS 
 BEGIN       
      SET NOCOUNT ON  

SELECT    
    CASE WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted' ELSE 'Not Contracted' END AS ContractStatus  
     From Vendor v 
    LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID
    Where v.ID = @VendorID  
  
END  