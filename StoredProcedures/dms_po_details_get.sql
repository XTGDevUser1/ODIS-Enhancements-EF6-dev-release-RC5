/*
*	Name				: dms_po_details_get
*	Purpose				: To get full details of a given PO (number).
*	Execution sample	: EXEC [dbo].[dms_po_details_get] '7770444'
*/

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_po_details_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
	DROP PROCEDURE [dbo].[dms_po_details_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  
 
 CREATE PROCEDURE [dbo].[dms_po_details_get]( 
	@poNumber NVARCHAR(50)
 ) 
 AS 
 BEGIN
 
	--DECLARE @serviceRequestID INT
	--SELECT	@serviceRequestID = ServiceRequestID
	--FROM	PurchaseOrder PO WITH (NOLOCK) 
	--WHERE	PurchaseOrderNumber = @poNumber
	
	SELECT
			CL.Name AS [Client]
			, SR.ID AS [ServiceRequestID]
			, SRS.Name AS [SRStatus]
			, PCSR.Name as [SRService]
			, MS.MembershipNumber AS [CustomerNumber]
			, REPLACE(RTRIM(
			  COALESCE(M.LastName,'')+  
			  COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')+  
			  COALESCE(', '+ CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+
			  COALESCE(' ' + LEFT(M.MiddleName,1),'')
				),'','') AS [CustomerName]
			, PO.PurchaseOrderNumber AS [PONumber]
			, 'Invoice'
			, PO.CreateBy AS [TakenBy]
			, PC.Name AS [Service]
			, PO.ETADate AS [ETA]
			, 'Comments'  -- use another sp get pull in all comments
			, SR.ServiceLocationAddress AS [Location]
			, SR.ServiceLocationDescription AS [LocationDescription]
			, C.ContactPhoneNumber AS [CallbackNumber] 
			, C.ContactAltPhoneNumber AS [AlternateNumber]
			, SR.DestinationAddress AS [Destination]
			, SR.DestinationDescription AS [DestinationDescription]
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
			, C.VehicleLength AS [Length]
			, C.VehicleChassis AS [Chassis]
			, C.VehicleEngine AS [Engine]
			, RT.Name AS [Class]
			, C.VehicleVIN AS [VIN]
			, C.VehicleDescription AS [VehicleDescription]
	FROM		ServiceRequest SR WITH (NOLOCK)
	LEFT JOIN	ServiceRequestStatus SRS WITH (NOLOCK) ON SRS.ID = SR.ServiceRequestStatusID
	LEFT JOIN	ProductCategory PCSR ON PCSR.ID = SR.ProductCategoryID
	LEFT JOIN	PurchaseOrder PO WITH (NOLOCK) ON PO.ServiceRequestID = SR.ID AND PO.IsActive = 1
	JOIN		[Case] C WITH (NOLOCK) ON C.ID = SR.CaseID
	JOIN		Program P WITH (NOLOCK) ON P.ID = C.ProgramID
	JOIN		Client CL WITH (NOLOCK) ON CL.ID = P.ClientID
	JOIN		Member M WITH (NOLOCK) ON M.ID = C.MemberID
	JOIN		Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
	LEFT JOIN	Product PR WITH (NOLOCK) ON PR.ID = PO.ProductID
	LEFT JOIN	ProductCategory PC WITH (NOLOCK) ON PC.ID = PR.ProductCategoryID
	LEFT JOIN	RVType RT WITH (NOLOCK) ON RT.ID = C.VehicleRVTypeID
	WHERE		PO.PurchaseOrderNumber = @poNumber
	--AND SR.ID = @ServiceRequestID
				
	
 END
