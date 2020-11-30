IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_PO_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_PO_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_PO_Details_Get @PONumber=7770395
 CREATE PROCEDURE [dbo].[dms_Vendor_Invoice_PO_Details_Get]( 
	@PONumber nvarchar(50) =NULL
	)
AS
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 SET FMTONLY OFF  
  
SELECT  PO.ID  
   , CASE  
    WHEN ISNULL(PO.IsPayByCompanyCreditCard,'') = 1 THEN 'Paid with company credit card'  
    ELSE ''  
     END AS [AlertText]  
   , PO.PurchaseOrderNumber AS [PONumber]  
   , POS.Name AS [POStatus]  
   , PO.PurchaseOrderAmount AS [POAmount]  
   , PC.Name AS [Service]  
   , PO.IssueDate AS [IssueDate]  
   , PO.ETADate AS [ETADate]  
   , PO.VendorLocationID     
   --, CASE  
   --WHEN ISNULL(CRS.ID,'') = '' THEN 'Not Contracted'  
   --ELSE 'Contracted'  
   --END AS 'ContractStatus'  
   , CASE WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted' ELSE 'Not Contracted' END AS ContractStatus  
   , V.Name AS [VendorName]  
   , V.VendorNumber AS [VendorNumber]  
   , ISNULL(PO.BillingAddressLine1,'') AS [VendorLocationLine1]  
   , ISNULL(PO.BillingAddressLine2,'') AS [VendorLocationLine2]  
   , ISNULL(PO.BillingAddressLine3,'') AS [VendorLocationLine3]   
   , ISNULL(REPLACE(RTRIM(  
      COALESCE(PO.BillingAddressCity, '') +   
      COALESCE(', ' + RTRIM(PO.BillingAddressStateProvince), '') +       
      COALESCE(' ' + PO.BillingAddressPostalCode, '') +            
      COALESCE(' ' + PO.BillingAddressCountryCode, '')   
     ), '  ', ' ')  
     ,'') AS [VendorLocationCityStZip]  
   , PO.DispatchPhoneNumber AS [DispatchPhoneNumber]  
   , PO.FaxPhoneNumber AS [FaxPhoneNumber]  
   , 'TalkedTo' AS [TalkedTo] -- TODO: Linked to ContactLog and get Talked To  
   , CL.Name AS [Client]  
   , P.Name AS [Program]  
   , MS.MembershipNumber AS [MemberNumber]  
   , C.MemberStatus  
   , REPLACE(RTRIM(  
    COALESCE(CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+  
    COALESCE(' ' + LEFT(M.MiddleName,1),'')+  
    COALESCE(' ' + CASE WHEN M.LastName = '' THEN NULL ELSE M.LastName END,'')+    
    COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')  
    ),'','') AS [CustomerName]  
   , C.ContactPhoneNumber AS [CallbackNumber]   
   , C.ContactAltPhoneNumber AS [AlternateNumber]  
   --, PO.SubTotal AS [SubTotal]  calculated from PO Details GRID  
   , PO.TaxAmount AS [Tax]  
   , PO.TotalServiceAmount AS [ServiceTotal]  
   , PO.CoachNetServiceAmount AS [CoachNetPays]  
   , PO.MemberServiceAmount AS [MemberPays]  
   , VT.Name + ' - ' + VC.Name AS [VehicleType]  
   , REPLACE(RTRIM(  
    COALESCE(C.VehicleYear,'')+  
    COALESCE(' ' + CASE WHEN C.VehicleMake = 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END,'')+  
    COALESCE(' ' + CASE WHEN C.VehicleModel = 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END,'')  
    ), '','') AS [Vehicle]  
   , ISNULL(C.VehicleVIN,'') AS [VIN]  
   , ISNULL(C.VehicleColor,'') AS [Color]  
   , REPLACE(RTRIM(  
     COALESCE(C.VehicleLicenseState + ' - ','') +  
     COALESCE(C.VehicleLicenseNumber,'')   
    ),'','') AS [License]  
   , ISNULL(C.VehicleCurrentMileage,'') AS [Mileage]  
   , ISNULL(SR.ServiceLocationAddress,'') AS [Location]  
   , ISNULL(SR.ServiceLocationDescription,'') AS [LocationDescription]  
   , ISNULL(SR.DestinationAddress,'') AS [Destination]  
   , ISNULL(SR.DestinationDescription,'') AS [DestinationDescription]  
   , PO.CreateBy  
   , PO.CreateDate  
   , PO.ModifyBy  
   , PO.ModifyDate   
   , CT.Abbreviation AS [CurrencyType]   
   , PO.IsPayByCompanyCreditCard AS IsPayByCC  
   , PO.CompanyCreditCardNumber CompanyCC  
   ,PO.VendorTaxID  
   ,PO.Email  
   ,POPS.[Description] PurchaseOrderPayStatus  
FROM  PurchaseOrder PO   
JOIN  PurchaseOrderStatus POS WITH (NOLOCK)ON POS.ID = PO.PurchaseOrderStatusID  
LEFT JOIN PurchaseOrderPayStatusCode POPS WITH (NOLOCK) ON POPS.ID = PO.PayStatusCodeID  
JOIN  ServiceRequest SR WITH (NOLOCK) ON SR.ID = PO.ServiceRequestID  
LEFT JOIN ServiceRequestStatus SRS WITH (NOLOCK) ON SRS.ID = SR.ServiceRequestStatusID  
LEFT JOIN ProductCategory PCSR ON PCSR.ID = SR.ProductCategoryID  
JOIN  [Case] C WITH (NOLOCK) ON C.ID = SR.CaseID  
JOIN  Program P WITH (NOLOCK) ON P.ID = C.ProgramID  
JOIN  Client CL WITH (NOLOCK) ON CL.ID = P.ClientID  
JOIN  Member M WITH (NOLOCK) ON M.ID = C.MemberID  
JOIN  Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID  
LEFT JOIN  Product PR WITH (NOLOCK) ON PR.ID = PO.ProductID  
LEFT JOIN  ProductCategory PC WITH (NOLOCK) ON PC.ID = PR.ProductCategoryID  
LEFT JOIN VehicleType VT WITH(NOLOCK) ON VT.ID = C.VehicleTypeID  
LEFT JOIN VehicleCategory VC WITH(NOLOCK) ON VC.ID = C.VehicleCategoryID  
LEFT JOIN RVType RT WITH (NOLOCK) ON RT.ID = C.VehicleRVTypeID  
JOIN  VendorLocation VL WITH(NOLOCK) ON VL.ID = PO.VendorLocationID  
JOIN  Vendor V WITH(NOLOCK) ON V.ID = VL.VendorID  
--LEFT JOIN [Contract] CO ON CO.VendorID = V.ID  AND CO.IsActive = 1  
--LEFT JOIN ContractRateSchedule CRS ON CRS.ContractID = V.ID AND CO.IsActive = 1  
LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID   
LEFT JOIN CurrencyType CT ON CT.ID=PO.CurrencyTypeID  
WHERE  PO.PurchaseOrderNumber = @PONumber  
   AND PO.IsActive = 1  
  
END  
