USE [DMS]
GO
/****** Object:  StoredProcedure [dbo].[etl_Extract_Transaction]    Script Date: 04/08/2013 14:51:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[etl_Extract_Transaction] 
AS
BEGIN

	SELECT  
		SR.ID AS [ServiceRequestID]
		,PO.ID AS [PurchaseOrderID]
		,PO.PurchaseOrderNumber
		,Program.ClientID 
		,CASE WHEN ISNULL([Case].ProgramID,0) <> 0 THEN COALESCE([Member].ProgramID, [Case].ProgramID, 0) ELSE 0 END AS ProgramID
		,PODtl.ProductID
		,Membership.ClientMembershipKey
		,Member.ClientMemberKey
		,Member.ID MemberID
		,COALESCE(Membership.MembershipNumber, Membership.ClientReferenceNumber) MembershipNumber
		,SR.CreateDate AS ServiceRequestCreateDateTime
		,SR.[ServiceLocationAddress]
		,SR.[ServiceLocationDescription]
		,SR.[ServiceLocationCrossStreet1]
		,SR.[ServiceLocationCrossStreet2]
		,SR.[DestinationAddress]
		,SR.[DestinationDescription]
		,[Case].[VehicleDescription]
		,[Case].[VehicleMake]
		,[Case].[VehicleVIN]
		,[Case].[VehicleModel]
		,[Case].[VehiclePurchaseDate]
		,[Case].[VehicleWarrantyStartDate]
		,[Case].[VehicleStartMileage]
		,[Case].[VehicleEndMileage]
		,[Case].[VehicleCurrentMileage]
		,[Case].[VehicleMileageUOM]
		,[Case].[VehicleIsFirstOwner]
		,v.VendorNumber
		,PO.DispatchPhoneNumber
		,PO.PurchaseOrderAmount
		,[Case].[VehicleLicenseState]
		,[Case].[VehicleLicenseNumber]
		,PO.ETADate AS ETADateTime
		,SR.[ServiceLocationCity]
		,SR.[ServiceLocationStateProvince]
		,SR.[ServiceLocationPostalCode]
		,PODtl.PurchaseOrderID AS DetailPurchaseOrderID
		,PODtl.GoneOnArrivalAmount
		,SR.IsRedispatched
		,PO.ID
		,PO.PurchaseOrderStatusID
		,PO.CancellationReasonID PurchaseOrderCancellationReasonID
		,SR.ServiceRequestStatusID
		,PO.IsPayByCompanyCreditCard
		,PO.CompanyCreditCardNumber
		,[Case].IsSafe
		,[Case].ContactAltPhoneNumber
		,[Case].[VehicleYear]
		,[Case].[VehicleLength]
		,[Case].[VehicleEngine]
		,[Case].[VehicleChassis]
		,[Case].[VehicleRVTypeID]
		,[Case].[ContactLastName]
		,[Case].[ContactFirstName]
		,SR.[IsWorkedByTech]
		,[Case].[VehicleCategoryID]
		,[Case].[VehicleTypeID]
		,SR.[IsAccident]
		,PODtl.TowAmount --[POHOOK]
		,PODtl.TowPerMile --[POHOOKPER]
		,PODtl.TowMiles --[POHOOKMILE]
		,PODtl.MemberPayTowAmount --[POMBRP]
		,PODtl.MemberPayTowPerMile --[POMBRPPER]
		,PODtl.MemberPayTowMiles --[POMBRPMILE]
		,PODtl.EnrouteMiles --[POENRMILE]
		,PODtl.EnroutePerMile --[POENRPER]
		,PODtl.HourlyRate --[POHOUR]
		,PODtl.HourlyHours --[POHOUR#]
		,PODtl.TowFreeMiles --[POFREEH]
		,PODtl.EnrouteFreeMiles --[POFREEE]
		,PODtl.ReturnPerMile --[POPPPER]
		,PODtl.ReturnMiles --[POPPMILE]
		,PODtl.NoTowAmount --[POSERV]
		,PODtl.TowDropDriveLineAmount --[PODROP]
		,PODtl.TowDolliesAmount --[PODOLLY]
		,PODtl.MemberPayNoTowAmount --[POSUPPL1]
		,PO.[TaxAmount]
		,PO.[MemberServiceAmount]
		,SR.CoverageLimit
		,SR.[DestinationCity]
		,SR.[DestinationStateProvince]
		,SR.[DestinationPostalCode]
		,SR.[ServiceLocationLongitude]
		,SR.[ServiceLocationLatitude]
		,SR.[DestinationLongitude]
		,SR.[DestinationLatitude]
		,SR.[ServiceMiles]
		,[Case].[VehicleTransmission]
		,[Case].[VehicleGVWR]
		,SR.[PassengersRidingWithServiceProvider]
		,[Case].[VehicleTireSize]
		,[Case].[VehicleHeight]
		,[Case].[VehicleColor]
		,SR.[IsDirectTowDealer]
		--,SR.[DealerIDNumber]
		,(SELECT V1.DealerNumber 
			FROM Vendor V1 
			JOIN VendorLocation VL1 ON V1.ID = VL1.VendorID
			WHERE VL1.ID = SR.DestinationVendorLocationID) AS [DealerIDNumber]
		
		/* Only need Member Data for Temp Members */
		,Member.FirstName AS [MemberFirstName]
		,Member.LastName AS [MemberLastName]
		,MemberAddr.Line1 AS [MemberAddressLine1]
		,MemberAddr.Line2 AS [MemberAddressLine2]
		,MemberAddr.City AS [MemberCity]
		,MemberAddr.StateProvince AS [MemberStateProvince]
		,MemberAddr.CountryID
		,MemberAddr.PostalCode
		,[Case].ContactPhoneNumber
		,Member.Email
		,Member.EffectiveDate
		,Member.ExpirationDate
		
		/* Only need Vendor Information for Temp Vendors */
		,v.Name AS [VendorName]
		,PO.BillingAddressLine1 AS [VendorAddress]
		,PO.BillingAddressCity AS [VendorCity]
		,PO.BillingAddressStateProvince AS VendorStateProvince
		,PO.BillingAddressCountryCode AS VendorCountryCode
		,PO.BillingAddressPostalCode AS VendorPostalCode
		,PO.FaxPhoneNumber AS [VendorFaxPhoneNumber]
		,PO.DispatchPhoneNumber AS [VendorDispatchPhoneNumber]
		,PO.Email AS [VendorEmail]
		
		,CASE WHEN srvdc.VehicleDiagnosticCodeType = 'Standard' THEN vdc.FordStandardCode
		      WHEN srvdc.VehicleDiagnosticCodeType = 'Ford Warranty' THEN vdc.FordWarrantyCode
			  WHEN srvdc.VehicleDiagnosticCodeType = 'Ford After Warranty' THEN vdc.FordAfterWarrantyCode
			  ELSE vdc.LegacyCode END VehicleDiagnosticCode
		,(SELECT PurchaseOrderNumber FROM PurchaseOrder WHERE ID = PO.OriginalPurchaseOrderID) AS OriginalPurchaseOrderNumber
		,(SELECT CancellationReasonID FROM PurchaseOrder WHERE ID = PO.OriginalPurchaseOrderID) AS OriginalPurchaseOrderCancellationReasonID
		,PO.GOAReasonID 
		
		,CASE WHEN EXISTS (
			SELECT * FROM [dbo].[fnc_ETL_ServiceRequestContactAction] () ca 
			WHERE ca.servicerequestid = sr.ID 
				--and ca.ContactCategoryName = 'NewCall' 
				and ca.ContactActionName = 'Transferred Call to Agero') THEN 1 ELSE 0 END AS IsTransferToAgero
		,CASE WHEN SR.DestinationVendorLocationID IS NOT NULL THEN 1 ELSE 0 END AS IsVerifyServiceLocation
		,CASE WHEN EXISTS (
			SELECT * FROM [dbo].[fnc_ETL_ServiceRequestContactAction] () ca 
			WHERE ca.servicerequestid = sr.ID 
				and Program.ClientID = 14 
				and ca.ContactActionName = 'TextFordSurvey') THEN 1 ELSE 0 END AS IsTextFordSurvey
		,CASE WHEN EXISTS (
			SELECT * FROM [dbo].[fnc_ETL_ServiceRequestContactAction] () ca 
			WHERE ca.servicerequestid = sr.ID 
				and Program.ClientID = 14 
				and ca.ContactActionName = 'OutOfWarranty') THEN 1 ELSE 0 END AS IsOutOfWarranty
		,ISNULL([Case].IsDeliveryDriver,0) AS IsDeliveryDriver
	
	FROM 
		(
		/* Get list of Service Requests ready for data transfer */
		SELECT SR.ID ServiceRequestID, 0 AS PurchaseOrderID
		FROM dbo.ServiceRequest SR
		--JOIN dbo.ServiceRequestStatus SRStatus
		--	ON SR.ServiceRequestStatusID = SRStatus.ID
		WHERE 
		SR.ReadyForExportDate IS NOT NULL
		AND SR.DataTransferDate IS NULL
		AND SR.CreateDate > DATEADD(mm, -1, GETDATE())
		--AND SRStatus.Name IN ('Cancelled', 'Complete')
		AND NOT EXISTS (
			SELECT *
			FROM dbo.PurchaseOrder PO
			WHERE PO.ServiceRequestID = SR.ID
			AND PO.DataTransferDate IS NOT NULL)

		/* Get list of Purchase Orders ready for data transfer */
		UNION
		SELECT SR.ID ServiceRequestID, PO.ID AS PurchaseOrderID
		FROM dbo.PurchaseOrder PO
		JOIN dbo.ServiceRequest SR
			ON PO.ServiceRequestID = SR.ID
		--JOIN dbo.PurchaseOrderStatus POStatus
		--	ON PO.PurchaseOrderStatusID = POStatus.ID
		WHERE 
		PO.ReadyForExportDate IS NOT NULL
		AND PO.DataTransferDate IS NULL
		--AND POStatus.Name IN ('Cancelled', 'Issued','Issued-Paid')
		) Trans
	JOIN dbo.ServiceRequest SR
		ON SR.ID = Trans.ServiceRequestID
	JOIN dbo.[Case] [Case]
		ON [Case].ID = SR.CaseID
	LEFT OUTER JOIN dbo.Member Member
		ON Member.ID = [Case].MemberID
	LEFT OUTER JOIN dbo.Program Program
		ON Program.ID = COALESCE([Member].ProgramID, [Case].ProgramID, 0)
	LEFT JOIN dbo.Membership Membership
		ON Membership.ID = Member.MembershipID
	LEFT OUTER JOIN dbo.PurchaseOrder PO
		ON Trans.ServiceRequestID = PO.ServiceRequestID AND Trans.PurchaseOrderID = PO.ID
	LEFT OUTER JOIN dbo.fnc_ETL_GetPODetailFlat(NULL) PODtl
		ON PODtl.PurchaseOrderID = PO.ID
	LEFT OUTER JOIN dbo.VendorLocation vl
		ON vl.ID = PO.VendorLocationID
	LEFT OUTER JOIN dbo.Vendor v
		ON v.ID = vl.VendorID
	LEFT OUTER JOIN dbo.AddressEntity MemberAddr 
		ON MemberAddr.EntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'Member')
		AND MemberAddr.RecordID = Member.ID
		AND MemberAddr.AddressTypeID = (SELECT ID FROM dbo.AddressType WHERE Name = 'Home')
		AND Membership.ClientMembershipKey IS NULL
	LEFT OUTER JOIN dbo.ServiceRequestVehicleDiagnosticCode srvdc
		ON srvdc.ServiceRequestID = SR.ID AND srvdc.IsPrimary = 1
    LEFT OUTER JOIN dbo.VehicleDiagnosticCode vdc 
		ON srvdc.VehicleDiagnosticCodeID = vdc.ID
	WHERE (ISNULL(Membership.ClientMembershipKey, N'') <> N'' 
	OR ISNULL([Case].ContactLastName, N'') <> N'')
	OR [Program].ClientID = 4 -- ARS: Include transactions without a related member
	ORDER BY SR.ID
	
END
