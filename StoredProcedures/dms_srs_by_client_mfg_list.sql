/*
*	Name				: dms_srs_by_client_mfg_list
*	Purpose				: To get a list of SRs between a date range for a given client.
*	Execution sample	: EXEC [dbo].[dms_srs_by_client_mfg_list] '32,38','2013-05-01','2013-06-11'
*/

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_srs_by_client_mfg_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_srs_by_client_mfg_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  
 
 CREATE PROCEDURE [dbo].[dms_srs_by_client_mfg_list]( 
	@clientIDs NVARCHAR(MAX),
	@startDate DATETIME,
	@endDate DATETIME
 ) 
 AS 
 BEGIN
	DECLARE @tblClients TABLE (
	ClientID	INT
	)
	INSERT INTO @tblClients
	SELECT * FROM [dbo].[fnSplitString](@clientIDs,',')
	
	SELECT 
			CLT.ClientID AS [ClientID]
			, P.Name AS [Program]
			, SR.ID AS [SRNumber]
			--, CONVERT(VARCHAR(10),SR.CreateDate,101) AS SRDate
			, SR.CreateDate AS [SRDate]
			, SRS.Name AS [SRStatus]
			, PC.Name AS [SRServiceType]
			, MS.MembershipNumber AS [CustomerID]
			, REPLACE(RTRIM(
			  COALESCE(M.LastName,'')+  
			  COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')+  
			  COALESCE(', '+ CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+
			  COALESCE(' ' + LEFT(M.MiddleName,1),'')
				),'','') AS [CustomerName]
			, PO.PurchaseOrderNumber AS [PONumber]
			, V.VendorNumber AS [ISPNumber]
			, V.Name AS [ISPName]
	FROM		ServiceRequest SR WITH (NOLOCK)
	LEFT JOIN	ServiceRequestStatus SRS WITH (NOLOCK) ON SRS.ID = SR.ServiceRequestStatusID
	LEFT JOIN	ProductCategory PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID
	LEFT JOIN	PurchaseOrder PO WITH (NOLOCK) ON PO.ServiceRequestID = SR.ID AND PO.IsActive = '1' AND PO.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued', 'Issued-Paid', 'Cancelled'))
	LEFT JOIN	[Case] C WITH (NOLOCK) ON C.ID = SR.CaseID
	LEFT JOIN	Program P WITH (NOLOCK) ON P.ID = C.ProgramID
	LEFT JOIN	Member M WITH (NOLOCK) ON M.ID = C.MemberID
	LEFT JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
	LEFT JOIN	VendorLocation VL WITH (NOLOCK) ON VL.ID = PO.VendorLocationID
	LEFT JOIN	Vendor V WITH (NOLOCK) ON V.ID = VL.VendorID
	JOIN		@tblClients CLT ON CLT.ClientID	= P.ClientID
	WHERE		SRS.Name IN ('Complete','Cancelled')
	AND			SR.CreateDate BETWEEN @StartDate AND @EndDate
	ORDER BY
				SR.ID, 
				PO.PurchaseOrderNumber DESC
	
 END
 GO
