/****** Object:  View [dbo].[vw_ServiceRequests]    Script Date: 01/08/2015 11:32:25 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_ServiceRequests]'))
DROP VIEW [dbo].[vw_ServiceRequests]
GO
CREATE VIEW [dbo].[vw_ServiceRequests]
AS
SELECT SR.[ID] ServiceRequestID
	  ,CL.[ID] ClientID
	  ,CL.[Name] ClientName
	  ,P.[ID] ProgramID
	  ,P.[Name] ProgramName
      ,SR.[ServiceRequestStatusID]
      ,SRS.[Name] ServiceRequestStatusName
      ,SRS.[Description] ServiceRequestStatusDescription
      ,SR.[ProductCategoryID]
      ,PC.[Name] ProductCategoryName
      ,pc.[Description] ProductCategoryDescription
      ,SR.[PrimaryProductID]
      ,PP.[Name] PrimaryProductName
      ,PP.[Description] PrimaryProductDescription
      ,SR.[SecondaryProductID]
      ,SP.[Name] SecondaryProductName
      ,SP.[Description] SecondaryProductDescription
      ,SR.[CaseID]
      ,C.[MemberID]
      ,C.[VehicleID]
      ,C.[CaseStatusID]
      ,CS.[Name] CaseStatusName
      ,C.[AssignedToUserID] CaseAssignedToUserID
      ,CU.[FirstName] CaseAssignedToUserFirstName
      ,CU.[LastName] CaseAssignedToUserLastName
      ,C.[ReferenceNumber] CaseReferenceNumber
      ,C.[MemberNumber] CaseMemberNumber
      ,C.[MemberStatus] CaseMemberStatus
      ,C.[CallTypeID] CaseCallTypeID
      ,CAT.[Name] CallTypeName
      ,C.[Language]
      ,C.[VehicleVIN]
      ,C.[VehicleYear]
      ,C.[VehicleMake]
      ,C.[VehicleMakeOther]
      ,C.[VehicleModel]
      ,C.[VehicleModelOther]
      ,C.[VehicleLicenseNumber]
      ,C.[VehicleLicenseState]
      ,C.[VehicleDescription]
      ,C.[VehicleColor]
      ,C.[VehicleLength]
      ,C.[VehicleHeight]
      ,C.[VehicleSource]
      ,C.[VehicleCategoryID] CaseVehicleCategoryID
      ,CVC.[Name] CaseVehicleCategoryName
      ,CVC.[Description] CaseVehicleCategoryDescription
      ,C.[VehicleTypeID]
      ,VT.[Name] VehicleTypeName
      ,C.[VehicleRVTypeID]
      ,RVT.[Name] VehicleRVTypeName
      ,C.[TrailerTypeID]
      ,TVT.[Name] TrailerTypeName
      ,C.[TrailerTypeOther]
      ,C.[TrailerSerialNumber]
      ,C.[TrailerNumberofAxles]
      ,C.[TrailerHitchTypeID]
      ,C.[TrailerHitchTypeOther]
      ,C.[TrailerBallSize]
      ,C.[TrailerBallSizeOther]
      ,C.[VehicleTireSize]
      ,C.[VehicleTireBrand]
      ,C.[VehicleTireBrandOther]
      ,C.[VehicleTransmission]
      ,C.[VehicleEngine]
      ,C.[VehicleGVWR]
      ,C.[VehicleChassis]
      ,C.[VehiclePurchaseDate]
      ,C.[VehicleWarrantyStartDate]
      ,C.[VehicleStartMileage]
      ,C.[VehicleEndMileage]
      ,C.[VehicleCurrentMileage]
      ,C.[VehicleMileageUOM]
      ,C.[VehicleIsFirstOwner]
      ,C.[VehicleIsSportUtilityRV]
      ,C.[ContactLastName]
      ,C.[ContactFirstName]
      ,C.[InboundPhoneNumber]
      ,C.[ANIPhoneTypeID]
      ,C.[ANIPhoneNumber]
      ,C.[ContactPhoneTypeID]
      ,C.[ContactPhoneNumber]
      ,C.[ContactAltPhoneTypeID]
      ,C.[ContactAltPhoneNumber]
      ,C.[IsSMSAvailable]
      ,C.[IsSafe]
      ,C.[LegacySystemID]
      ,C.[LegacySystemIDSequence]
      ,C.[CreateDate] CaseCreateDate
      ,C.[CreateBy] CaseCreateBy
      ,C.[ModifyDate] CaseModifyDate
      ,C.[ModifyBy] CaseModifyBy
      ,C.[IsDeliveryDriver] CaseIsDeliveryDriver
      ,C.[VehicleLicenseCountryID]
      ,C.[ContactEmail]
      ,C.[ReasonID]
      ,C.[VehicleWarrantyPeriod]
      ,C.[VehicleWarrantyPeriodUOM]
      ,C.[VehicleWarrantyMileage]
      ,C.[IsVehicleEligible]
      ,C.[VehicleWarrantyEndDate]
      ,M.[FirstName] MemberFirstName
      ,M.[LastName] MemberLastName
      ,M.[ClaimSubmissionNumber] MemberClaimSubmissionNumber
      ,M.[EffectiveDate] MemberEffectiveDate
      ,M.[ExpirationDate] MemberExpirationDate
      ,M.[Email] MemberEmail
      ,SR.[NextActionID]
      ,NA.[Name] NextActionName
      ,NA.[Description] NextActionDescription
      ,SR.[NextActionAssignedToUserID]
      ,U.[AgentNumber] NextActionAssignedToUserAgentNumber
      ,U.[FirstName] NextActionAssignedToUserFirstName
      ,U.[LastName] NextActionAssignedToUserLastName
      ,SR.[VehicleCategoryID]
      ,VC.[Name] VehicleCategoryName
      ,VC.[Description] VehicleCategoryDescription
      ,SR.[ServiceRequestPriorityID]
      ,SRP.[Name] ServiceRequestPriorityName
      ,SRP.[Description] ServiceRequestPriorityDescription
      ,SR.[ClosedLoopStatusID]
      ,CLS.[Name] ClosedLoopStatusName
      ,CLS.[Description] ClosedLoopStatusDescription
      ,SR.[ClosedLoopNextSend]
      ,SR.[IsPrimaryProductCovered]
      ,SR.[IsSecondaryProductCovered]
      ,SR.[MemberPaymentTypeID]
      ,PT.[Name] MemberPaymentTypeName
      ,SR.[PassengersRidingWithServiceProvider]
      ,SR.[IsEmergency]
      ,SR.[IsAccident]
      ,SR.[IsPossibleTow]
      ,SR.[ServiceLocationAddress]
      ,SR.[ServiceLocationDescription]
      ,SR.[ServiceLocationCrossStreet1]
      ,SR.[ServiceLocationCrossStreet2]
      ,SR.[ServiceLocationCity]
      ,SR.[ServiceLocationStateProvince]
      ,SR.[ServiceLocationPostalCode]
      ,SR.[ServiceLocationCountryCode]
      ,SR.[ServiceLocationLatitude]
      ,SR.[ServiceLocationLongitude]
      ,SR.[DestinationAddress]
      ,SR.[DestinationDescription]
      ,SR.[DestinationCrossStreet1]
      ,SR.[DestinationCrossStreet2]
      ,SR.[DestinationCity]
      ,SR.[DestinationStateProvince]
      ,SR.[DestinationPostalCode]
      ,SR.[DestinationCountryCode]
      ,SR.[DestinationLatitude]
      ,SR.[DestinationLongitude]
      ,SR.[DestinationVendorLocationID]
      ,SR.[ServiceMiles]
      ,SR.[ServiceTimeInMinutes]
      ,SR.[DealerIDNumber]
      ,SR.[IsDirectTowDealer]
      ,SR.[CallFee]
      ,SR.[IsRedispatched]
      ,SR.[IsDispatchThresholdReached]
      ,SR.[IsWorkedByTech]
      ,SR.[NextActionScheduledDate]
      ,SR.[LegacyReferenceNumber]
      ,SR.[ReadyForExportDate]
      ,SR.[DataTransferDate]
      , CASE 
			WHEN ISNULL(SR.[StartTabStatus],0)=0 THEN 'Not Visited'
			WHEN ISNULL(SR.[StartTabStatus],0)=1 THEN 'Visited With No Erros'
			ELSE 'Visited With Errors'
		  END  AS StartTabStatus
	   , CASE 
			WHEN ISNULL(SR.[MemberTabStatus],0)=0 THEN 'Not Visited'
			WHEN ISNULL(SR.[MemberTabStatus],0)=1 THEN 'Visited With No Erros'
			ELSE 'Visited With Errors'
		  END  AS MemberTabStatus
       , CASE 
			WHEN ISNULL(SR.[VehicleTabStatus],0)=0 THEN 'Not Visited'
			WHEN ISNULL(SR.[VehicleTabStatus],0)=1 THEN 'Visited With No Erros'
			ELSE 'Visited With Errors'
		  END  AS VehicleTabStatus
       , CASE 
			WHEN ISNULL(SR.[ServiceTabStatus],0)=0 THEN 'Not Visited'
			WHEN ISNULL(SR.[ServiceTabStatus],0)=1 THEN 'Visited With No Erros'
			ELSE 'Visited With Errors'
		  END  AS ServiceTabStatus
      , CASE 
			WHEN ISNULL(SR.[MapTabStatus],0)=0 THEN 'Not Visited'
			WHEN ISNULL(SR.[MapTabStatus],0)=1 THEN 'Visited With No Erros'
			ELSE 'Visited With Errors'
		  END  AS MapTabStatus
       , CASE 
			WHEN ISNULL(SR.[DispatchTabStatus],0)=0 THEN 'Not Visited'
			WHEN ISNULL(SR.[DispatchTabStatus],0)=1 THEN 'Visited With No Erros'
			ELSE 'Visited With Errors'
		  END  AS DispatchTabStatus
      , CASE 
			WHEN ISNULL(SR.[POTabStatus],0)=0 THEN 'Not Visited'
			WHEN ISNULL(SR.[POTabStatus],0)=1 THEN 'Visited With No Erros'
			ELSE 'Visited With Errors'
		  END  AS POTabStatus
      , CASE 
			WHEN ISNULL(SR.[PaymentTabStatus],0)=0 THEN 'Not Visited'
			WHEN ISNULL(SR.[PaymentTabStatus],0)=1 THEN 'Visited With No Erros'
			ELSE 'Visited With Errors'
		  END  AS PaymentTabStatus
     , CASE 
			WHEN ISNULL(SR.[ActivityTabStatus],0)=0 THEN 'Not Visited'
			WHEN ISNULL(SR.[ActivityTabStatus],0)=1 THEN 'Visited With No Erros'
			ELSE 'Visited With Errors'
		  END  AS ActivityTabStatus
     , CASE 
			WHEN ISNULL(SR.[FinishTabStatus],0)=0 THEN 'Not Visited'
			WHEN ISNULL(SR.[FinishTabStatus],0)=1 THEN 'Visited With No Erros'
			ELSE 'Visited With Errors'
		  END  AS FinishTabStatus
      ,SR.[CreateDate]
      ,SR.[CreateBy]
      ,SR.[ModifyDate]
      ,SR.[ModifyBy]
      ,SR.[AccountingInvoiceBatchID]
      ,SR.[StatusDateModified]
      ,SR.[PartsAndAccessoryCode]
      ,SR.[CurrencyTypeID]
      ,CT.[Name] CurrencyTypeName
      ,CT.[Abbreviation] CurrencyTypeAbbreviation
      ,SR.[PrimaryCoverageLimit]
      ,SR.[SecondaryCoverageLimit]
      ,SR.[MileageUOM]
      ,SR.[PrimaryCoverageLimitMileage]
      ,SR.[SecondaryCoverageLimitMileage]
      ,SR.[IsServiceGuaranteed]
      ,SR.[IsReimbursementOnly]
      ,SR.[IsServiceCoverageBestValue]
      ,SR.[ProgramServiceEventLimitID]
      ,SR.[PrimaryServiceCoverageDescription]
      ,SR.[SecondaryServiceCoverageDescription]
      ,SR.[PrimaryServiceEligiblityMessage]
      ,SR.[SecondaryServiceEligiblityMessage]
      ,SR.[IsPrimaryOverallCovered]
      ,SR.[IsSecondaryOverallCovered]
      ,SR.[ProviderClaimNumber]
	  ,SR.[ExportBatchID]
	  ,C.[SourceSystemID]
	  ,SS.[Description] AS SourceSystemName
  FROM [ServiceRequest] SR (NOLOCK)
  LEFT JOIN [ServiceRequestStatus] SRS (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID
  LEFT JOIN [ProductCategory] PC (NOLOCK) ON SR.ProductCategoryID = PC.ID
  LEFT JOIN [Product] PP (NOLOCK) ON SR.PrimaryProductID = PP.ID
  LEFT JOIN [Product] SP (NOLOCK) ON SR.SecondaryProductID = SP.ID
  LEFT JOIN [Case] C (NOLOCK) ON SR.CaseID = C.ID
  LEFT JOIN [Member] M (NOLOCK) ON C.MemberID = M.ID
  LEFT JOIN [NextAction] NA (NOLOCK) ON Sr.NextActionID = NA.ID
  LEFT JOIN [User] U (NOLOCK) ON SR.NextActionAssignedToUserID = U.ID
  LEFT JOIN [VehicleCategory] VC (NOLOCK) ON SR.VehicleCategoryID = VC.ID
  LEFT JOIN [ServiceRequestPriority] SRP ON SR.ServiceRequestPriorityID = SRP.ID
  LEFT JOIN [ClosedLoopStatus] CLS ON SR.ClosedLoopStatusID = CLS.ID
  LEFT JOIN [CurrencyType] CT ON SR.CurrencyTypeID = CT.ID
  LEFT JOIN [PaymentType] PT ON SR.MemberPaymentTypeID = PT.ID
  LEFT JOIN [Program] P (NOLOCK) ON C.ProgramID = P.ID
  LEFT JOIN [Client] CL (NOLOCK) ON P.ClientID = CL.ID
  LEFT JOIN [CaseStatus] CS (NOLOCK) ON C.CaseStatusID = CS.ID
  LEFT JOIN [User] CU (NOLOCK) ON C.AssignedToUserID = CU.ID
  LEFT JOIN [CallType] CAT (NOLOCK) ON C.CallTypeID = CAT.ID
  LEFT JOIN [VehicleCategory] CVC (NOLOCK) ON C.VehicleCategoryID = CVC.ID
  LEFT JOIN [VehicleType] VT (NOLOCK) ON C.VehicleTypeID = VT.ID
  LEFT JOIN [RVType] RVT (NOLOCK) ON C.VehicleRVTypeID = RVT.ID
  LEFT JOIN [TrailerType] TVT (NOLOCK) ON C.TrailerTypeID = TVT.ID
  LEFT JOIN [SourceSystem] SS (NOLOCK) ON C.SourceSystemID = SS.ID
GO

