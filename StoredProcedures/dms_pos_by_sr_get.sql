/*
*	Name				: dms_pos_by_sr_get
*	Purpose				: To get full details of a given PO (number).
*	Execution sample	: EXEC [dbo].[dms_pos_by_sr_get] 1398
*/

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_pos_by_sr_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
	DROP PROCEDURE [dbo].[dms_pos_by_sr_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  
 
 CREATE PROCEDURE [dbo].[dms_pos_by_sr_get]( 
	@serviceRequestID INT
 ) 
 AS 
 BEGIN
 
	SELECT
			PO.ID AS [POID]
			, PO.PurchaseOrderNumber AS [PONumber]
			, PO.IssueDate AS [PODate]
			, POS.Name AS [POStatus]
			, PC.Name AS [POService]
			, PO.CreateBy AS [TakenBy]
			, V.VendorNumber AS [ISPNumber]
			, V.Name AS [ISPName]
			, PO.CancellationReasonID AS [CancelReasonID]
			, CASE
				WHEN PO.CancellationReasonID = (SELECT ID FROM PurchaseOrderCancellationReason WHERE Name = 'Other')
				THEN PO.CancellationReasonOther
				ELSE CR.Name
			  END AS [CancelReason]
			, PO.CancellationComment AS [CancellationComments]
			, PO.IsGOA AS [IsGOA]
			, CASE
				WHEN PO.GOAReasonID = (SELECT ID FROM PurchaseOrderGOAReason WHERE Name = 'Other')
				THEN PO.GOAReasonOther
				ELSE GR.Name
			  END AS [GOAReason]
			, PO.GOAComment AS [GOAComments]
	FROM		PurchaseOrder PO WITH (NOLOCK)
	LEFT JOIN	PurchaseOrderStatus POS WITH (NOLOCK) ON POS.ID = PO.PurchaseOrderStatusID
	LEFT JOIN	Product P WITH (NOLOCK) ON P.ID = PO.ProductID
	LEFT JOIN	ProductCategory PC WITH (NOLOCK) ON PC.ID = P.ProductCategoryID
	LEFT JOIN	VendorLocation VL WITH (NOLOCK) ON VL.ID = PO.VendorLocationID
	LEFT JOIN	Vendor V WITH (NOLOCK) ON V.ID = VL.VendorID
	LEFT JOIN	PurchaseOrderCancellationReason CR WITH (NOLOCK) ON CR.ID = PO.CancellationReasonID
	LEFT JOIN	PurchaseOrderGOAReason GR WITH (NOLOCK) ON GR.ID = PO.GOAReasonID
	WHERE		PO.ServiceRequestID = @ServiceRequestID
	AND			PO.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued','Issued-Paid','Cancelled'))
	ORDER BY
				PO.CreateDate DESC
				
	
 END
 GO
