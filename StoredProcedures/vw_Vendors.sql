 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_Vendors]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_Vendors] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
/****** Object:  View [dbo].[vw_Vendors]    Script Date: 11/09/2014 17:58:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[vw_Vendors]

AS

SELECT	v.ID
		, v.Name AS VendorName
		, v.CorporationName
		, v.VendorStatusID
		, vs.Name AS VendorStatus
		, v.VendorRegionID
		, vr.Name AS VendorRegion
		, vr.ContactFirstName + ' ' + vr.ContactLastName AS VendorRegionContact 
		, v.SourceSystemID
		, ss.Name AS SourceSystem
		, cl.Name as ClientName
		, v.ClientVendorKey 
		, v.VendorNumber
		, v.ContactFirstName
		, v.ContactLastName
		, v.AdministrativeRating
		, v.AdministrativeRatingModifyDate
		, v.Website
		, v.Email
		, ae.Line1 AS BusinessLine1
		, ae.Line2 AS BusinessLine2
		, ae.City AS BusinessCity
		, ae.StateProvinceID AS BusinessStateProvinceID
		, ae.StateProvince AS BusinessStateProvince
		, ae.PostalCode AS BusinessPostalCode
		, ae.CountryID AS BusinessCountryID
		, ae.CountryCode AS BusinessCountryCode
		, aeBill.Line1 AS BillingLine1
		, aeBill.Line2 AS BillingLine2
		, aeBill.City AS BillingCity
		, aeBill.StateProvinceID AS BillingStateProvinceID
		, aeBill.StateProvince AS BillingStateProvince
		, aeBill.PostalCode AS BillingPostalCode
		, aeBill.CountryID AS BillingCountryID
		, aeBill.CountryCode AS BillingCountryCode
		,(SELECT TOP 1 PhoneNumber
			FROM PhoneEntity (NOLOCK) 
			WHERE EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor') 
			AND PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Office')
			AND RecordID = v.ID
			) OfficePhone
		, v.TaxClassification
		, v.TaxClassificationOther
		, v.TaxEIN
		, v.TaxSSN
		, v.W9SignedBy
		, v.IsW9OnFile
		, v.InsuranceCarrierName
		, v.InsurancePolicyNumber
		, v.InsuranceExpirationDate
		, v.IsInsuranceCertificateOnFile
		, v.IsInsuranceAdditional
		, v.IsEmployeeBackgroundChecked
		, v.IsEmployeeBackgroundCheckedComment
		, v.IsEmployeeDrugTested
		, v.IsEmployeeDrugTestedComment
		, v.IsDriverUniformed
		, v.IsDriverUniformedComment
		, v.IsEachServiceTruckMarked
		, v.IsEachServiceTruckMarkedComment
		, v.DepartmentOfTransportationNumber
		, v.MotorCarrierNumber
		, v.IsLevyActive
		, v.LevyRecipientName
		, v.IsPaymentOnHold
		, v.IsVirtualLocationEnabled
		, v.IsActive
		, CASE 
			WHEN ISNULL(ach.ID,'') = '' THEN 'No'
			ELSE 'Yes'
		  END  AS ACH
		, achs.Name AS ACHStatus
		, CASE 
			WHEN ISNULL(ach.ID,'') = '' THEN NULL
			ELSE ss.Name 
		  END AS ACHSourceSystem
		, ach.ReceiptContactMethodID 
		, cmACH.Name AS ACHReceiptContactMethod
		, Case 
			WHEN ISNULL(va.ID,'') = '' THEN 'No'
			ELSE 'Yes'
		  END AS VendorApplication
		, va.CreateDate AS VendorApplicationCreateDate
		, Case 
			WHEN EXISTS(SELECT * FROM VendorUser Where VendorID = v.ID) THEN 'Yes'
			ELSE 'No'
		  END AS WebAccount
		, Case WHEN cs.Name = 'Active' THEN 'Contracted' ELSE 'Not Contracted' END ContractStatus
		, c.StartDate AS ContractStartDate
		, c.EndDate AS ContractEndDate
		, vta.FileName AS SPAVersion
		, crs.StartDate AS RateScheduleStartDate
		, crs.EndDate AS RateScheduleEndDate
		, d.VendorName as DispatchSoftwareVendorName
		, d.SoftwareName as DispatchSoftwareProductName
		, v.DispatchSoftwareProductOther 
		, dr.VendorName as DriverSoftwareVendorName
		, dr.SoftwareName as DriverSoftwareProductName
		, v.DriverSoftwareProductOther 
		, v.CreateDate
		, v.CreateBy
		, v.ModifyDate
		, v.ModifyBy    
FROM	Vendor v (NOLOCK)
LEFT JOIN	VendorStatus vs (NOLOCK) ON vs.ID = v.VendorStatusID
LEFT JOIN	VendorRegion vr (NOLOCK) ON vr.ID = v.VendorRegionID
LEFT JOIN	SourceSystem ss (NOLOCK) ON ss.ID = v.SourceSystemID  
LEFT JOIN	AddressEntity ae (NOLOCK) ON ae.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor') AND ae.RecordID = v.ID  AND ae.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Business')
LEFT JOIN	AddressEntity aeBill (NOLOCK) ON aeBill.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor') AND aeBill.RecordID = v.ID  AND aeBill.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Billing')
LEFT JOIN	VendorACH ach (NOLOCK) ON ach.VendorID = v.ID AND ach.IsActive = 1
LEFT JOIN	ACHStatus achs (NOLOCK) ON achs.ID = ach.ACHStatusID 
LEFT JOIN	SourceSystem ssACH (NOLOCK) ON ssACH.ID = ach.SourceSystemID
LEFT JOIN	ContactMethod cmACH (NOLOCK) ON cmACH.ID = ach.ReceiptContactMethodID
LEFT JOIN	VendorApplication va (NOLOCK) ON va.VendorID = v.ID 
LEFT JOIN	dbo.fnc_GetVendorActiveContractRateSchedule() VendorContract ON VendorContract.VendorID = v.ID
LEFT JOIN	[Contract] c (NOLOCK) ON c.ID = VendorContract.ContractID
LEFT JOIN	ContractStatus cs (NOLOCK) ON cs.ID = c.ContractStatusID
LEFT JOIN	ContractRateSchedule crs (NOLOCK) ON crs.ID = VendorContract.ContractRateScheduleID
LEFT JOIN	VendorTermsAgreement vta (NOLOCK) ON vta.ID = c.VendorTermsAgreementID
LEFT JOIN	Client cl (NOLOCK) on cl.ID = v.ClientID 
LEFT JOIN	DispatchSoftwareProduct d (NOLOCK) on d.ID = v.DispatchSoftwareProductID 
LEFT JOIN	DispatchSoftwareProduct dr (NOLOCK) on dr.ID = v.DriverSoftwareProductID 
WHERE	v.IsActive = 1
GO

