CREATE VIEW [dbo].[vw_PuchaseOrders]
AS


SELECT PO.[ID] PurchaseOrderID
	,CL.ID ClientID
	,CL.Name ClientName
	,PGM.ID ProgramID
	,PGM.Name ProgramName
	,PO.[ServiceRequestID]
	,PO.[OriginalPurchaseOrderID]
	,PO.[ContactMethodID]
	,CM.[Name] ContactMethodName
	,PO.[PurchaseOrderTypeID]
	,POT.[Name] PurchaseOrderTypeName
	,POT.[Description] PurchaseOrderTypeDescription
	,PO.[ProductID]
	,P.[Name] ProductName
	,P.[Description] ProductDescription
	,PC.Name ProductCategoryName
	,PC.[Description] ProductCategoryDescription
	,PO.[PurchaseOrderNumber]
	,PO.[PurchaseOrderStatusID]
	,POS.[Name] PurchaseOrderStatusName
	,POS.[Description] PurchaseOrderStatusDescription
	,PO.[CancellationReasonID]
	,COALESCE(POCR.[Description], PO.[CancellationReasonOther]) PurchaseOrderCancellationReason
	,PO.[CancellationComment]
	,PO.[VehicleCategoryID]
	,VC.[Name] VehicleCategoryName
	,VC.[Description] VehicleCategoryDescription
	,V.[VendorNumber]
	,V.[Name] VendorName
	,ISPCalls.[Count] ServiceRequestISPCallCount
	,PO.[VendorLocationID]
	,VL.[Email] VendorLocationEmail
	,VL.[BusinessHours] VendorLocationBusinessHours
	,VL.[DispatchEmail] VendorLocationDispatchEmail
	,VL.[DealerNumber] VendorLocationDealerNumber
	,VL.[DispatchNote] VendorLocationDispatchNote
	,VL.[GeographyLocation] VendorLocationGeographyLocation
	,VL.[IsOpen24Hours] VendorLocationIsOpen24Hours
	,VL.[PartsAndAccessoryCode] VendorLocationPartsAndAccessoryCode
	,PO.[BillingAddressTypeID]
	,BAT.[Name] BillingAddressTypeName
	,PO.[BillingAddressLine1]
	,PO.[BillingAddressLine2]
	,PO.[BillingAddressLine3]
	,PO.[BillingAddressCity]
	,PO.[BillingAddressStateProvince]
	,PO.[BillingAddressPostalCode]
	,PO.[BillingAddressCountryCode]
	,PO.[DispatchPhoneNumber]
	,PO.[DispatchPhoneTypeID]
	,PO.[FaxPhoneTypeID]
	,PO.[FaxPhoneNumber]
	,PO.[Email]
	,PO.[DealerIDNumber]
	,PO.[EnrouteMiles]
	,PO.[EnrouteFreeMiles]
	,PO.[EnrouteTimeMinutes]
	,PO.[ServiceMiles]
	,PO.[ServiceFreeMiles]
	,PO.[ServiceTimeMinutes]
	,PO.[ReturnMiles]
	,PO.[ReturnTimeMinutes]
	,PO.[IsServiceCovered]
	,PO.[ServiceLocationDescription]
	,PO.[ServiceLocationAddress]
	,PO.[ServiceLocationCity]
	,PO.[ServiceLocationStateProvince]
	,PO.[ServiceLocationPostalCode]
	,PO.[ServiceLocationCountryCode]
	,COALESCE(Dest_V.Name, PO.[DestinationDescription]) DestinationDescription
	,PO.[DestinationAddress]
	,PO.[DestinationCity]
	,PO.[DestinationStateProvince]
	,PO.[DestinationPostalCode]
	,PO.[DestinationCountryCode]
	,PO.[DestinationVendorLocationID]
	,(CASE WHEN PO.DestinationVendorLocationID IS NOT NULL THEN 1 ELSE 0 END) IsDestinationServiceFacility
	,PO.[CurrencyTypeID]
	,CT.[Name] CurrencyTypeName
	,CT.[Abbreviation] CurrencyTypeAbbreviation
	,PO.[TaxAmount]
	,PO.[TotalServiceAmount]
	,PO.[MemberServiceAmount]
	,PO.[MemberPaymentTypeID]
	,PO.[CoachNetServiceAmount]
	,PO.[IsMemberAmountCollectedByVendor]
	,PO.[DispatchFee]
	,PO.[DispatchFeeBillToID]
	,PO.[MemberAmountDueToCoachNet]
	,PO.[PurchaseOrderAmount]
	,PO.[IsPayByCompanyCreditCard]
	,PO.[CompanyCreditCardNumber]
	,PO.[IssueDate]
	,PO.[IsVendorAdvised]
	,PO.[ETAMinutes]
	,PO.[ETADate]
	,PO.[AdditionalInstructions]
	,PO.[LegacyReferenceNumber]
	,PO.[ReadyForExportDate]
	,PO.[DataTransferDate]
	,PO.[IsActive]
	,PO.[IsGOA]
	,PO.[CreateDate]
	,PO.[CreateBy]
	,PO.[ModifyDate]
	,PO.[ModifyBy]
	,PO.[CoverageLimit]
	,PO.[GOAReasonID]
	,PO.[GOAReasonOther]
	,PO.[GOAComment]
	,PO.[GOAAuthorization]
	,PO.[GOAAuthorizationDate]
	,PO.[VendorLocationVirtualID]
	,PO.[AccountingInvoiceBatchID]
	,PO.[ContractStatus]
	,PO.[AdminstrativeRating]
	,PO.[ServiceRating]
	,PO.[SelectionOrder]
	,PO.[PayStatusCodeID]
	,PO.[VendorTaxID]
	,PO.[CoverageLimitMileage]
	,PO.[MileageUOM]
	,PO.[IsServiceCoverageBestValue]
	,PO.[ServiceEligibilityMessage]
	,PO.[IsServiceCoveredOverridden]
	,PO.[IsPreferredVendor]
	,VT.Name VehicleType
	,RVT.Name VehicleRVType
	,C.[VehicleVIN]
	,C.[VehicleYear]
	,C.[VehicleMake]
	,C.[VehicleModel]
	,C.[VehicleChassis]
	,ISPCalls.[Count] VendorCallCount
	,ServiceCharges.BaseAmount
	,ServiceCharges.EnrouteAmount
	,ServiceCharges.EnrouteFreeAmount
	,ServiceCharges.GOAAmount
	,ServiceCharges.HourlyAmount
	,ServiceCharges.ServiceAmount
	,ServiceCharges.ServiceFreeAmount
	,ServiceCharges.ReturnServiceAmount
	,ServiceCharges.TotalEnrouteMiles 
	,ServiceCharges.TotalServiceHours 
	,ServiceCharges.TotalServiceMiles 
	,CASE WHEN ISNULL(ServiceCharges.TotalServiceMiles,0) > 0 THEN CAST(((ISNULL(ServiceCharges.ServiceAmount,0) + ISNULL(ServiceCharges.ServiceFreeAmount,0))/ServiceCharges.TotalServiceMiles ) as Money) ELSE NULL END as CostPerTowMile
	,CASE WHEN ISNULL(ServiceCharges.TotalServiceHours,0) > 0 THEN CAST(((ISNULL(ServiceCharges.ServiceAmount,0) + ISNULL(ServiceCharges.ServiceFreeAmount,0))/ServiceCharges.TotalServiceHours ) as Money) ELSE NULL END as CostPerHour
	,CASE WHEN ISNULL(ServiceCharges.TotalEnrouteMiles,0) > 0 THEN CAST(((ISNULL(ServiceCharges.EnrouteAmount,0) + ISNULL(ServiceCharges.EnrouteFreeAmount,0))/ServiceCharges.TotalEnrouteMiles )as Money) ELSE NULL END as CostPerEnrouteMile
	,ISNULL(OtherCharges.CustomerPayoutAmount,0.0) CustomerPayoutAmount
	,ISNULL(OtherCharges.MiscChargesAmount,0.0) MiscChargesAmount
	,POThresholdApproval.POThresholdApprovalResponse
	,POThresholdApproval.POThresholdComment
  FROM [dbo].[PurchaseOrder] PO (NOLOCK)
  JOIN [ServiceRequest] SR (NOLOCK) ON PO.ServiceRequestID = SR.ID
  JOIN [Case] C (NOLOCK) ON SR.CaseID = C.ID
  JOIN [Program] PGM (NOLOCK) ON C.ProgramID = PGM.ID
  JOIN [Client] CL (NOLOCK) ON PGM.ClientID = CL.ID
  LEFT JOIN (
		SELECT pod.PurchaseOrderID
			,SUM(CASE WHEN rt.Name = 'Base' THEN pod.ExtendedAmount ELSE 0.00 END) BaseAmount
			,SUM(CASE WHEN rt.Name = 'Enroute' THEN pod.ExtendedAmount ELSE 0.00 END) EnrouteAmount
			,SUM(CASE WHEN rt.Name = 'EnrouteFree' THEN pod.ExtendedAmount ELSE 0.00 END) EnrouteFreeAmount
			,SUM(CASE WHEN rt.Name = 'GoneOnArrival' THEN pod.ExtendedAmount ELSE 0.00 END) GOAAmount
			,SUM(CASE WHEN rt.Name = 'Hourly' THEN pod.ExtendedAmount ELSE 0.00 END) HourlyAmount
			,SUM(CASE WHEN rt.Name = 'Service' THEN pod.ExtendedAmount ELSE 0.00 END) ServiceAmount
			,SUM(CASE WHEN rt.Name = 'ServiceFree' THEN pod.ExtendedAmount ELSE 0.00 END) ServiceFreeAmount
			,SUM(CASE WHEN rt.Name = 'Return' THEN pod.ExtendedAmount ELSE 0.00 END) ReturnServiceAmount
			,SUM(CASE WHEN rt.Name = 'Enroute' AND rt.UnitofMeasure = 'Mile' THEN pod.Quantity WHEN rt.Name = 'EnrouteFree' AND rt.UnitofMeasure = 'Mile' THEN -1 * pod.Quantity END) TotalEnrouteMiles
			,SUM(CASE WHEN rt.Name = 'Service' AND rt.UnitofMeasure = 'Mile' THEN pod.Quantity WHEN rt.Name = 'ServiceFree' AND rt.UnitofMeasure = 'Mile' THEN -1 * pod.Quantity END) TotalServiceMiles
			,SUM(CASE WHEN rt.Name = 'Service' AND rt.UnitofMeasure <> 'Mile' THEN pod.Quantity WHEN rt.Name = 'ServiceFree' AND rt.UnitofMeasure <> 'Mile' THEN -1 * pod.Quantity END) TotalServiceHours
		FROM PurchaseOrder po (NOLOCK)
		JOIN PurchaseOrderDetail pod (NOLOCK) on po.ID = pod.PurchaseOrderID and pod.ProductID = po.ProductID 
		JOIN RateType rt (NOLOCK) on rt.ID = pod.ProductRateID
		GROUP BY PurchaseOrderID
		) ServiceCharges ON ServiceCharges.PurchaseOrderID = PO.ID
  LEFT JOIN (
		SELECT pod.PurchaseOrderID
			,SUM(CASE WHEN prod.Name = 'Customer Payout' THEN pod.ExtendedAmount ELSE 0.0 END) CustomerPayoutAmount
			,SUM(CASE WHEN prod.Name <> 'Customer Payout' THEN pod.ExtendedAmount ELSE 0.0 END) MiscChargesAmount
		FROM PurchaseOrder po (NOLOCK)
		JOIN PurchaseOrderDetail pod (NOLOCK) on po.ID = pod.PurchaseOrderID and pod.ProductID <> po.ProductID 
		JOIN Product prod (NOLOCK) on Prod.ID = pod.ProductID
		GROUP BY PurchaseOrderID
		) OtherCharges ON OtherCharges.PurchaseOrderID = PO.ID
  LEFT JOIN (
	SELECT cl.ServiceRequestID, COUNT(*) Count
	FROM vw_ContactLogs cl
	WHERE cl.ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'VendorSelection')
	GROUP BY cl.ServiceRequestID
	) ISPCalls ON ISPCalls.ServiceRequestID = SR.ID
  LEFT JOIN [PurchaseOrder] PPO (NOLOCK) ON PO.OriginalPurchaseOrderID = PPO.ID
  LEFT JOIN [ContactMethod] CM (NOLOCK) ON PO.ContactMethodID = CM.ID
  LEFT JOIN [PurchaseOrderType] POT (NOLOCK) ON PO.PurchaseOrderTypeID = POT.ID
  LEFT JOIN [Product] P (NOLOCK) ON PO.ProductID = P.ID
  LEFT JOIN [ProductCategory] PC (NOLOCK) ON PC.ID = P.ProductCategoryID
  LEFT JOIN [PurchaseOrderStatus] POS (NOLOCK) ON PO.PurchaseOrderStatusID = POS.ID
  LEFT JOIN [PurchaseOrderCancellationReason] POCR (NOLOCK) ON PO.CancellationReasonID = POCR.ID
  LEFT JOIN [VehicleCategory] VC (NOLOCK) ON PO.VehicleCategoryID = VC.ID
  LEFT JOIN [VehicleType] VT (NOLOCK) ON C.VehicleTypeID = VT.ID
  LEFT JOIN [RVType] RVT (NOLOCK) ON C.VehicleRVTypeID = RVT.ID
  LEFT JOIN [VendorLocation] VL (NOLOCK) ON PO.VendorLocationID = VL.ID
  LEFT JOIN [Vendor] V (NOLOCK) ON V.ID = VL.VendorID
  LEFT JOIN [VendorLocation] Dest_VL (NOLOCK) ON PO.DestinationVendorLocationID = Dest_VL.ID
  LEFT JOIN [Vendor] Dest_V (NOLOCK) ON Dest_V.ID = Dest_VL.VendorID
  LEFT JOIN [AddressType] BAT (NOLOCK) ON PO.BillingAddressTypeID = BAT.ID
  LEFT JOIN [CurrencyType] CT (NOLOCK) ON PO.CurrencyTypeID = CT.ID
  LEFT JOIN dbo.fnc_POThresholdApproval() POThresholdApproval ON POThresholdApproval.PurchaseOrderID = PO.ID
  WHERE PO.IsActive = 1
GO

