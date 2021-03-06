/****** Object:  StoredProcedure [dbo].[dms_ServiceRequestList_BySalesChannel_Get]    Script Date: 04/29/2014 02:13:22 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ServiceRequestList_BySalesChannel_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ServiceRequestList_BySalesChannel_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC dms_ServiceRequestList_BySalesChannel_Get '4793','1/1/2013', '7/31/2013'
Create PROCEDURE [dbo].[dms_ServiceRequestList_BySalesChannel_Get]( 
	@SalesChannelIDs NVARCHAR(MAX),
	@startDate DATETIME,
	@endDate DATETIME
 ) 
AS 
 BEGIN
 
 
 --set @clientIDs = '4793,4448,4742,4425,4772,4748,4748,4748,4753,4757'
  
	DECLARE @tblClients TABLE (
	ClientID	nvarchar(50)
	)
	INSERT INTO @tblClients
	SELECT * FROM [dbo].[fnSplitString](@SalesChannelIDs,',')
	
	SELECT 
			CLT.ClientID AS [ClientID]
			, P.ID AS [ProgramID]
			, P.Name AS [ProgramName]
			, SR.ID AS [SRNumber]
			, SR.CreateDate AS [SRDate]
			, SRS.Name AS [SRStatus]
			, PC.Name AS [SRServiceTypeName]
			, PC.Description AS [SRServiceTypeDescription]
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
			, PO.ID AS [POID]
			, PO.PurchaseOrderNumber AS [PONumber]
			, PO.IssueDate AS [POIssueDate]
			, POS.Name AS [POStatus]
			, PO.CancellationReasonID AS [POCancellationReasonID]
			, POCR.Name AS [POCancellationReasonName]
			, PO.CancellationReasonOther AS [POCancellationReasonOther]
			, PO.CancellationComment AS [POCancellationComment]
			, PO.IsGOA AS [POIsGOA]
			, PO.GOAReasonID AS [POGOAReasonID]
			, POGR.Name AS [POGOAReasonName]
			, PO.GOAReasonOther AS [POGOAReasonOther]
			, PO.GOAComment AS [POGOAComment]
			, V.VendorNumber AS [ISPNumber]
			, V.Name AS [ISPName]
	FROM		ServiceRequest SR WITH (NOLOCK)
	LEFT JOIN	ServiceRequestStatus SRS WITH (NOLOCK) ON SRS.ID = SR.ServiceRequestStatusID
	LEFT JOIN	ProductCategory PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID
	LEFT JOIN	PurchaseOrder PO WITH (NOLOCK) ON PO.ServiceRequestID = SR.ID AND PO.IsActive = '1' AND PO.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued', 'Issued-Paid', 'Cancelled'))
	LEFT JOIN	PurchaseOrderStatus POS WITH (NOLOCK) ON POS.ID = PO.PurchaseOrderStatusID 
	LEFT JOIN	PurchaseOrderCancellationReason POCR WITH (NOLOCK) ON POCR.ID = PO.CancellationReasonID
	LEFT JOIN	PurchaseOrderGOAReason POGR WITH (NOLOCK) ON POGR.ID = PO.GOAReasonID
	LEFT JOIN	[Case] C WITH (NOLOCK) ON C.ID = SR.CaseID
	LEFT JOIN	Program P WITH (NOLOCK) ON P.ID = C.ProgramID
	LEFT JOIN	Member M WITH (NOLOCK) ON M.ID = C.MemberID
	LEFT JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
	LEFT JOIN	VendorLocation VL WITH (NOLOCK) ON VL.ID = PO.VendorLocationID
	LEFT JOIN	Vendor V WITH (NOLOCK) ON V.ID = VL.VendorID
	JOIN		@tblClients CLT ON CLT.ClientID	= M.AccountSource
	WHERE		SRS.Name IN ('Complete','Cancelled')
	AND			((@startDate IS NULL AND @endDate IS NULL) OR (SR.CreateDate BETWEEN @StartDate AND @EndDate))
	AND			PO.IsActive = '1' 
	AND			PO.PurchaseOrderStatusID <> (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending')
	ORDER BY
				SR.ID, 
				PO.PurchaseOrderNumber DESC
	
 END
GO
