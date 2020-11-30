/*
*	Name				: dms_pos_by_client_mfg_list
*	Purpose				: To get a list of POs between a date range for a given client.
*	Execution sample	: EXEC [dbo].[dms_pos_by_client_mfg_list] '32,50','2013-05-01','2013-06-11'
*/

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_pos_by_client_mfg_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_pos_by_client_mfg_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  
 
 CREATE PROCEDURE [dbo].[dms_pos_by_client_mfg_list]( 
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
			MS.MembershipNumber AS CustomerID
			, REPLACE(RTRIM(
			  COALESCE(M.LastName,'')+  
			  COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')+  
			  COALESCE(', '+ CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+
			  COALESCE(' ' + LEFT(M.MiddleName,1),'')
				),'','') AS [CustomerName]
			, PO.PurchaseOrderNumber AS [PONumber]
			, V.Name as [ISP]
	FROM	PurchaseOrder PO WITH (NOLOCK)
	JOIN	ServiceRequest SR WITH (NOLOCK) ON SR.ID = PO.ServiceRequestID
	JOIN	[Case] C WITH (NOLOCK) ON C.ID = SR.CaseID
	JOIN	Program P WITH (NOLOCK) ON P.ID = C.ProgramID
	JOIN	Member M WITH (NOLOCK) ON M.ID = C.MemberID
	JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
	JOIN	VendorLocation VL WITH (NOLOCK) ON VL.ID = PO.VendorLocationID
	JOIN	Vendor V WITH (NOLOCK) ON V.ID = VL.VendorID
	JOIN	@tblClients CLT ON CLT.ClientID	= P.ClientID
	WHERE	PO.IsActive = 1
	AND		PO.PurchaseOrderStatusID IN (
					SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued', 'Issued-Paid', 'Cancelled')
					)
	AND		PO.CreateDate BETWEEN @StartDate and @EndDate
	ORDER BY	
			SR.CreateDate DESC 
	
 END
 GO
