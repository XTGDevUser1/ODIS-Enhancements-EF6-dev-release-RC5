IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ServiceRequestList_ByMember_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ServiceRequestList_ByMember_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  


/****** Object:  StoredProcedure [dbo].[dms_ServiceRequestList_ByMember_Get]    Script Date: 07/23/2013 18:34:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 
 -- EXEC dms_ServiceRequestList_ByMember_Get 18, '15287495', NULL , NULL
 CREATE PROCEDURE [dbo].[dms_ServiceRequestList_ByMember_Get]( 
	@ClientID INT, 
	@MembershipNumber NVARCHAR(25), 
	@startDate DATETIME,
	@endDate DATETIME
 ) 
 AS 
 BEGIN
		
	SELECT 
			CL.ID AS [ClientID]
			, CL.Name AS [ClientName]
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
	LEFT JOIN	Client CL WITH (NOLOCK) ON CL.ID = P.ClientID
	LEFT JOIN	Member M WITH (NOLOCK) ON M.ID = C.MemberID
	LEFT JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
	LEFT JOIN	VendorLocation VL WITH (NOLOCK) ON VL.ID = PO.VendorLocationID
	LEFT JOIN	Vendor V WITH (NOLOCK) ON V.ID = VL.VendorID
	WHERE		P.ClientID = @clientID
	--AND			C.MemberID = @memberID
	AND			MS.MembershipNumber = @MembershipNumber
	AND			SRS.Name IN ('Complete','Cancelled')
	AND			((@startDate IS NULL AND @endDate IS NULL) OR (SR.CreateDate BETWEEN @StartDate AND @EndDate))
	AND			PO.IsActive = '1' 
	AND			PO.PurchaseOrderStatusID <> (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending')
	ORDER BY
				SR.ID, 
				PO.PurchaseOrderNumber DESC
	
 END

GO


