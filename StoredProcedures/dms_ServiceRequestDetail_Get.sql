IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ServiceRequestDetail_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ServiceRequestDetail_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  

/****** Object:  StoredProcedure [dbo].[dms_ServiceRequestDetail_Get]    Script Date: 07/23/2013 18:35:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 -- EXEC dms_ServiceRequestDetail_Get 1575
 CREATE PROCEDURE [dbo].[dms_ServiceRequestDetail_Get]( 
	@serviceRequestID INT
 ) 
 AS 
  BEGIN
 
/*
*	Name				: dms_ServiceRequestDetail_Get
*	Purpose				: To get full details of a given Service Request.
*	Execution sample	: EXEC [dbo].[dms_ServiceRequestDetail_Get] '28498' --'25592'  -- select * from servicerequest sr join purchaseorder po on po.servicerequestid = sr.id
*/

	
	DECLARE @minDate DATETIME = '1900-01-01'
	DECLARE @now DATETIME = GETDATE()
	
	SELECT
			CL.ID AS [ClientID]
			, CL.Name AS [ClientName]
			, P.ID AS [ProgramID]
			, P.Name AS [ProgramName]
			, SR.ID AS [SRNumber]
			, SR.CreateDate AS [SRDate]
			, SRS.Name AS [SRStatus]
			, PCSR.Name as [SRServiceTypeName]
			, PCSR.Description as [SRServiceTypeDescription]
			, M.ID AS [MemberID]
			, MS.MembershipNumber AS [MemberNumber]
			, M.Prefix AS [Prefix]
			, M.FirstName AS [FirstName]
			, M.MiddleName AS [MiddleName]
			, M.LastName AS [LastName]
			, M.Suffix AS [Suffix]
			, REPLACE(RTRIM(
			  COALESCE(M.LastName,'')+  
			  COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')+  
			  COALESCE(', '+ CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+
			  COALESCE(' ' + LEFT(M.MiddleName,1),'')
				),'','') AS [MemberName]
			, C.ContactPhoneNumber AS [CallbackNumber] 
			, C.ContactAltPhoneNumber AS [AlternateNumber]
			, C.VehicleVIN AS [VIN]
			, C.VehicleYear AS [Year]
			, CASE
				WHEN C.VehicleMake = 'Other'
				THEN C.VehicleMakeOther
				ELSE C.VehicleMake
			  END AS [Make]
			 , CASE
				WHEN C.VehicleModel = 'Other'
				THEN C.VehicleModelOther
				ELSE C.VehicleModel
			  END AS [Model]	
			, C.VehicleLicenseNumber AS [LicenseNumber]
			, C.VehicleLicenseState AS [LicenseState]
			, C.VehicleColor AS [Color]
			, C.VehicleDescription AS [VehicleDescription]
			, C.VehicleLength AS [Length]
			, C.VehicleHeight AS [Height]
			, VC.Name AS [VehicleCategory]
			, VT.Name AS [VehicleType]
			, RVT.Name AS [RVType]
			, C.VehicleTransmission AS [Transmission]
			, C.VehicleEngine AS [Engine]
			, C.VehicleGVWR AS [GVWR]
			, C.VehicleChassis AS [Chassis]
			, SR.ServiceLocationAddress AS [Location]
			, SR.ServiceLocationDescription AS [LocationDescription]
			, SR.DestinationAddress AS [Destination]
			, SR.DestinationDescription AS [DestinationDescription]
			, PO.ID AS [POID]
			, PO.PurchaseOrderNumber AS [PONumber]
			, PO.IssueDate AS [POIssueDate]
			, PO.ETADate AS [POETADate]
			, POS.Name AS [POStatus]
			, PC.Name AS [POService]
			, PO.TotalServiceAmount AS [POAmount]
			, PO.CancellationReasonID AS [POCancellationReasonID]
			, CASE 
				WHEN POCR.Name = 'Other'
				THEN PO.CancellationReasonOther
				ELSE POCR.[Description] 
			  END AS [POCancellationReasonName]
			, PO.CancellationComment AS [POCancellationComment]
			, PO.IsGOA AS [POIsGOA]
			, PO.GOAReasonID AS [POGOAReasonID]
			, CASE  
				WHEN POGR.Name = 'Other'
				THEN PO.GOAReasonOther
				ELSE POGR.[Description]
			  END AS [POGOAReasonName]
			, PO.GOAComment AS [POGOAComment]
			, PO.CreateBy AS [POTakenBy]
			, V.VendorNumber AS [VendorNumber]
			, V.Name AS [VendorName]
	FROM		ServiceRequest SR WITH (NOLOCK)
	LEFT JOIN	ServiceRequestStatus SRS WITH (NOLOCK) ON SRS.ID = SR.ServiceRequestStatusID
	LEFT JOIN	ProductCategory PCSR ON PCSR.ID = SR.ProductCategoryID
	LEFT JOIN	PurchaseOrder PO WITH (NOLOCK) ON PO.ServiceRequestID = SR.ID 
	LEFT JOIN	PurchaseOrderStatus POS WITH (NOLOCK) ON POS.ID = PO.PurchaseOrderStatusID
	LEFT JOIN	PurchaseOrderCancellationReason POCR WITH (NOLOCK) ON POCR.ID = PO.CancellationReasonID
	LEFT JOIN	PurchaseOrderGOAReason POGR WITH (NOLOCK) ON POGR.ID = PO.GOAReasonID
	LEFT JOIN	VendorLocation VL WITH (NOLOCK) ON VL.ID = PO.VendorLocationID
	LEFT JOIN	Vendor V WITH (NOLOCK) ON V.ID = VL.VendorID
	JOIN		[Case] C WITH (NOLOCK) ON C.ID = SR.CaseID
	LEFT JOIN	VehicleCategory VC WITH (NOLOCK) ON VC.ID = C.VehicleCategoryID
	LEFT JOIN	VehicleType VT WITH (NOLOCK) ON VT.ID = C.VehicleTypeID
	JOIN		Program P WITH (NOLOCK) ON P.ID = C.ProgramID
	JOIN		Client CL WITH (NOLOCK) ON CL.ID = P.ClientID
	LEFT JOIN	Member M WITH (NOLOCK) ON M.ID = C.MemberID
	LEFT JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
	LEFT JOIN	Product PR WITH (NOLOCK) ON PR.ID = PO.ProductID
	LEFT JOIN	ProductCategory PC WITH (NOLOCK) ON PC.ID = PR.ProductCategoryID
	LEFT JOIN	RVType RVT WITH (NOLOCK) ON RVT.ID = C.VehicleRVTypeID
	WHERE		SR.ID = @serviceRequestID
	AND			(
				(ISNULL(PO.ID,'')='') 
				OR  
				(PO.IsActive = 1 AND PO.PurchaseOrderStatusID <> (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending'))
				)
	ORDER BY 	SR.ID, PO.PurchaseOrderNumber
	
 END
 GO