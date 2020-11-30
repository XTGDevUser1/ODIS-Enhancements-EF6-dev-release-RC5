CREATE VIEW [dbo].[vw_VendorApplications]
AS
SELECT VA.[ID] VendorApplicationID
      ,VA.[VendorID]
	  , V.[VendorNumber]
      ,VA.[Name]
      ,VA.[CorporationName]
      ,VA.[VendorApplicationReferralSourceID]
	  ,VARS.[Description] VendorApplicationReferralSourceDescription
      ,VA.[Website]
      ,VA.[Email]
      ,VA.[ContactFirstName]
      ,VA.[ContactLastName]
      ,VA.[IsOpen24Hours]
      ,VA.[BusinessHours]
      ,VA.[DepartmentOfTransportationNumber]
      ,VA.[MotorCarrierNumber]
      ,VA.[IsEmployeeBackgroundChecked]
      ,VA.[IsEmployeeDrugTested]
      ,VA.[IsDriverUniformed]
      ,VA.[IsEachServiceTruckMarked]
      ,VA.[IsElectronicDispatch]
      ,VA.[IsFaxDispatch]
      ,VA.[IsEmailDispatch]
      ,VA.[IsTextDispatch]
      ,VA.[MaxTowingGVWR]
      ,VA.[TaxClassification]
      ,VA.[TaxClassificationOther]
      ,VA.[InsuranceCarrierName]
      ,VA.[ApplicationSignedByName]
      ,VA.[ApplicationSignedByTitle]
      ,VA.[ApplicationComments]
      ,VA.[CreateDate]
      ,VA.[CreateBy]
      ,VA.[ModifyDate]
      ,VA.[ModifyBy]
      ,VA.[TaxEIN]
      ,VA.[TaxSSN]
      ,VA.[W9SignedBy]
      ,VA.[TotalServiceVehicleCount]
      ,VA.[IsKeyDropAvailable]
      ,VA.[IsOvernightStayAllowed]
      ,VA.[InsuranceCertificateFileName]
  FROM [dbo].[VendorApplication] VA WITH (NOLOCK)
  LEFT JOIN [dbo].[Vendor] V WITH (NOLOCK) ON VA.VendorID = V.ID
  LEFT JOIN [dbo].[VendorApplicationReferralSource] VARS ON VA.VendorApplicationReferralSourceID = VARS.ID



