IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Info]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Info] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_Vendor_Info] 319
 CREATE PROCEDURE [dbo].[dms_Vendor_Info]( 
  @VendorLocationID INT = NULL
  ,@ServiceRequestID INT =NULL
) 
 AS 
 BEGIN   
    
      SET NOCOUNT ON  
  
      DECLARE @ProductID INT = NULL  
       
      SELECT @ProductID=PrimaryProductID   
      FROM ServiceRequest   
      WHERE ID=@ServiceRequestID  
       
      Select   DISTINCT
			v.ID  
            , v.Name as VendorName  
            , v.VendorNumber as VendorNumber  
			, CASE WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted' ELSE 'Not Contracted' END AS ContractStatus  
            , ae.Line1 as Address1  
            , ae.Line2 as Address2  
            , REPLACE(RTRIM(  
				COALESCE(ae.City, '') +  
				COALESCE(', ' + ae.StateProvince,'') +   
				COALESCE(' ' + LTRIM(ae.PostalCode), '') +   
				COALESCE(' ' + ae.CountryCode, '')   
				), ' ', ' ') as VendorCityStateZipCountry  
            , pe24.PhoneTypeID as DispatchPhoneType  
            , pe24.PhoneNumber as DispatchPhoneNumber  
            , peFax.PhoneTypeID as FaxPhoneType  
            , peFax.PhoneNumber as FaxPhoneNumber  
            , peOfc.PhoneTypeID as OfficePhoneType  
            , peOfc.PhoneNumber as OfficePhoneNumber  
            ,ISNULL(vl.DispatchEmail,v.Email) Email
            ,v.CreateBy   
            ,v.CreateDate  
            ,v.ModifyBy  
            ,v.ModifyDate  
            ,vs.Name AS VendorStatus  
            ,COALESCE(TaxEIN,TaxSSN,'') VendorTaxID  
            ,COALESCE(ct.SignedDate,'') ContractSignedDate
            ,COALESCE(ct.SignedBy, '') ContractSignedBy
      From VendorLocation vl  
      Join Vendor v on v.ID = vl.VendorID  
      JOIN VendorStatus vs ON v.VendorStatusID = vs.ID  
      Left Outer Join AddressEntity ae on ae.RecordID = vl.ID and ae.EntityID = (Select ID From Entity Where Name = 'VendorLocation')   
      Left Outer Join PhoneEntity pe24 on pe24.RecordID = vl.ID and pe24.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and pe24.PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')  
      Left Outer Join PhoneEntity peFax on peFax.RecordID = vl.ID and peFax.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and peFax.PhoneTypeID = (Select ID From PhoneType Where Name = 'Fax')  
      Left Outer Join PhoneEntity peOfc on peOfc.RecordID = vl.ID and peOfc.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and peOfc.PhoneTypeID = (Select ID From PhoneType Where Name = 'Office')  
      LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID
      LEFT OUTER JOIN dbo.fnc_GetVendorActiveContractRateSchedule() VendorContract ON v.ID = VendorContract.VendorID
      LEFT OUTER JOIN dbo.[Contract] ct ON ct.ID = VendorContract.ContractID
      Where vl.ID = @VendorLocationID  
  
END  
