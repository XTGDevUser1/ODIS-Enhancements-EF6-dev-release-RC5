
GO

/****** Object:  StoredProcedure [dbo].[dms_POList_ByServiceRequest_Get]    Script Date: 07/23/2013 18:32:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 
 CREATE PROCEDURE [dbo].[dms_POList_ByServiceRequest_Get]( 
	@serviceRequestID INT
 ) 
 AS 
 BEGIN
 
/*
*	Name				: dms_POList_ByServiceRequest_Get
*	Purpose				: To get full details of a given PO (number).
*	Execution sample	: EXEC [dbo].[dms_POList_ByServiceRequest_Get] 28498
*/

	
	SELECT
			PO.ID AS [POID]
			, PO.PurchaseOrderNumber AS [PONumber]
			, PO.IssueDate AS [PODate]
			, PO.ETADate AS [POETADate]
			, POS.Name AS [POStatus]
			, PC.Name AS [POService]
			, PO.TotalServiceAmount AS [POAmount]
			, PO.CancellationReasonID AS [CancelReasonID]
			, CASE
				WHEN PO.CancellationReasonID = (SELECT ID FROM PurchaseOrderCancellationReason WHERE Name = 'Other')
				THEN PO.CancellationReasonOther
				ELSE CR.Name
			  END AS [CancelReason]
			, PO.CancellationComment AS [CancellationComments]
			, PO.IsGOA AS [IsGOA]
			, PO.GOAReasonID
			, CASE
				WHEN PO.GOAReasonID = (SELECT ID FROM PurchaseOrderGOAReason WHERE Name = 'Other')
				THEN PO.GOAReasonOther
				ELSE GR.Name
			  END AS [GOAReason]
			, PO.GOAComment AS [GOAComments]
			, PO.CreateBy AS [TakenBy]
			, V.VendorNumber AS [ISPNumber]
			, V.Name AS [ISPName]
	FROM		PurchaseOrder PO WITH (NOLOCK)
	LEFT JOIN	PurchaseOrderStatus POS WITH (NOLOCK) ON POS.ID = PO.PurchaseOrderStatusID
	LEFT JOIN	Product P WITH (NOLOCK) ON P.ID = PO.ProductID
	LEFT JOIN	ProductCategory PC WITH (NOLOCK) ON PC.ID = P.ProductCategoryID
	LEFT JOIN	VendorLocation VL WITH (NOLOCK) ON VL.ID = PO.VendorLocationID
	LEFT JOIN	Vendor V WITH (NOLOCK) ON V.ID = VL.VendorID
	LEFT JOIN	PurchaseOrderCancellationReason CR WITH (NOLOCK) ON CR.ID = PO.CancellationReasonID
	LEFT JOIN	PurchaseOrderGOAReason GR WITH (NOLOCK) ON GR.ID = PO.GOAReasonID
	WHERE		PO.ServiceRequestID = @ServiceRequestID
	AND			PO.IsActive = 1
	AND			PO.PurchaseOrderStatusID <> (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending')
	ORDER BY
				PO.IssueDate DESC
				
	
 END

GO


