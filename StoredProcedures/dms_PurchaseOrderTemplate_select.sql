
/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_PurchaseOrderTemplate_select]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_PurchaseOrderTemplate_select]
GO
/****** Object:  StoredProcedure [dbo].[dms_users_list]    Script Date: 07/03/2012 17:56:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [dms_PurchaseOrderTemplate_select] 108,1
CREATE PROCEDURE [dbo].[dms_PurchaseOrderTemplate_select]   
   @PurchaseOrderID int,  
   @ContactLogID int  
 AS   
 BEGIN   
    
 SET NOCOUNT ON  
  
DECLARE @TalkedTo nvarchar(50)  
DECLARE @FaxNo nvarchar(50)  
DECLARE @VendorCallback nvarchar(50)
DECLARE @VendorBilling nvarchar(50)
  
SELECT @TalkedTo = CL.TalkedTo,   
@FaxNo = REPLACE(CL.PhoneNumber, ' ','')   
FROM ContactLog CL  
WHERE CL.ID = @ContactLogID  
  
 
SELECT   
@TalkedTo as POTo,  
V.Name as VendorName,  
V.VendorNumber,  
@FaxNo as FaxPhoneNumber,  
ACFrom.Value as POFrom,  
ACVendorCallbackPhone.Value as VendorCallback,
ACBilling.Value as VendorBilling,
PO.IssueDate,  
--CONVERT(VARCHAR(8), PO.IssueDate, 108) + '-' + CONVERT(VARCHAR(10), PO.IssueDate, 101) as IssueDate,
PO.PurchaseOrderNumber,  
PO.CreateBy as OpenedBy,  
COALESCE(PC.Name, PC2.Name) as ServiceName,  
PO.EtaMinutes,  
CASE WHEN Isnull(C.IsSafe,1) = 1 THEN 'Y'  
ELSE 'N'  
END AS Safe,  
CASE WHEN Isnull(PO.IsMemberAmountCollectedByVendor,0) = 1 THEN 'Y'  
ELSE 'N'  
END AS MemberPay,  
REPLACE(RTRIM(COALESCE(M.FirstName, '') +     
          COALESCE(' ' + LEFT(M.MiddleName,1), '') +    
          COALESCE(' ' + M.LastName, '')), '  ', ' ')     
          as MemberName,     
MS.MembershipNumber,  
dbo.fnc_FormatPhoneNumber(C.ContactPhoneNumber,0) as ContactPhoneNumber,  
dbo.fnc_FormatPhoneNumber(C.ContactAltPhoneNumber,0) as ContactAltPhoneNumber,  
SR.ServiceLocationDescription,  
SR.ServiceLocationAddress,  
SR.ServiceLocationCrossStreet1 + COALESCE(' & ' + SR.ServicelocationCrossStreet2, '') as ServiceLocationCrossStreet,  
SR.ServiceLocationCity + ', ' + SR.ServiceLocationStateProvince as CityState,  
SR.ServiceLocationPostalCode as Zip,  
SR.DestinationDescription,  
SR.DestinationAddress,  
SR.DestinationCrossStreet1 + COALESCE(' & ' + SR.DestinationCrossStreet2, '') as DestinationCrossStreet,  
SR.DestinationCity + ', ' + SR.ServiceLocationStateProvince as DestinationCityState,  
SR.DestinationPostalCode as DestinationZip,  
C.VehicleYear,   
--C.VehicleMake,  
--C.VehicleModel,  
CASE c.VehicleMake WHEN 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END AS VehicleMake,
CASE C.VehicleModel WHEN 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END AS VehicleModel,
C.VehicleDescription,  
C.VehicleColor,  
C.VehicleLicenseState + COALESCE('/' + C.VehicleLicenseNumber,'') as License,  
C.VehicleVIN,  
C.VehicleChassis,  
C.VehicleLength,  
C.VehicleEngine,  
REPLACE(RVT.Name,'Class','') as Class  
FROM PurchaseOrder PO  
JOIN ServiceRequest SR ON PO.ServiceRequestID = SR.ID  
JOIN [Case] C ON C.ID = SR.CaseID   
JOIN VendorLocation VL on VL.ID = PO.VendorLocationID   
JOIN Vendor V on V.ID = VL.VendorID   
JOIN ApplicationConfiguration ACFrom ON ACFrom.Name = 'POFaxFrom'  
JOIN ApplicationConfiguration ACVendorCallbackPhone ON ACVendorCallbackPhone.Name = 'VendorCallback'  
JOIN ApplicationConfiguration ACBilling ON ACBilling.Name = 'VendorBilling'  
LEFT JOIN Product P ON P.ID = PO.ProductID
LEFT JOIN ProductCategory PC ON PC.ID = P.ProductCategoryID
JOIN ProductCategory PC2 ON PC2.ID = SR.ProductCategoryID
JOIN Member M on M.ID = C.MemberID   
JOIN Membership MS ON MS.ID = M.MembershipID   
LEFT JOIN RVType RVT ON RVT.ID = C.VehicleRVTypeID   
WHERE PO.ID = @PurchaseOrderID   
  
END

