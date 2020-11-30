/*******************
* Operator Enums 
*  Conditions Enum :
* -1 - No filter
*  0 - Null
*  1 - Not Null
*  2 - Equals
*  3 - NotEquals
*  ---- for strings ---
*  4 - StartsWith
*  5 - EndsWith
*  6 - Contains
*  ---- for int, decimal, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_customer_feedback_header_by_sr_po_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_customer_feedback_header_by_sr_po_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC  [dbo].[dms_customer_feedback_header_by_sr_po_get] @numberType='ServiceRequest', @numberValue='664805'
-- EXEC  [dbo].[dms_customer_feedback_header_by_sr_po_get] @numberType='PurchaseOrder', @numberValue='7770594'
CREATE PROCEDURE [dbo].[dms_customer_feedback_header_by_sr_po_get](
   @numberType NVARCHAR(100) = 'ServiceRequest', -- Possible values: ServiceRequest / PurchaseOrder
   @numberValue NVARCHAR(100) = NULL
)
AS
BEGIN
	DECLARE @results TABLE
	(
		ServiceRequestID INT NULL,
		PurchaseOrderNumber NVARCHAR(100) NULL,
		SubmittedDate DATETIME NULL,
		ClientName NVARCHAR(100) NULL,
		ProgramName NVARCHAR(100) NULL,
		MemberID INT NULL,
		MembershipID INT NULL,
		MembershipNumber NVARCHAR(100) NULL,
		MemberName NVARCHAR(MAX) NULL
	)
	-- Having if--else for better performance over using an OR or a CASE statement
	IF @numberType = 'ServiceRequest'
	BEGIN
		INSERT INTO @results
		SELECT	VW.ServiceRequestID,
				NULL AS PurchaseOrderNumber,
				VW.CreateDate AS SubmittedDate,
				VW.ClientName,
				VW.ProgramName,
				M.ID AS MemberID,
				MS.ID AS MembershipID,
				MS.MembershipNumber,
				COALESCE(VW.MemberFirstName,'')+		
				COALESCE(' '+ VW.MemberLastName,'') AS [MemberName]
		FROM	[dbo].[vw_ServiceRequests] VW
		JOIN	Member M WITH (NOLOCK) ON VW.MemberID = M.ID
		JOIN	Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID
		WHERE	VW.ServiceRequestID = @numberValue
	END
	ELSE IF (@numberType = 'PurchaseOrder')
	BEGIN
		INSERT INTO @results
		SELECT	VW.ServiceRequestID,
				VW.PurchaseOrderNumber,
				SR.CreateDate AS SubmittedDate,
				VW.ClientName,
				VW.ProgramName,
				M.ID AS MemberID,
				MS.ID AS MembershipID,
				MS.MembershipNumber,
				COALESCE(SR.MemberFirstName,'')+		
				COALESCE(' '+ SR.MemberLastName,'') AS [MemberName]
		FROM	[dbo].[vw_PurchaseOrders] VW
		JOIN	[dbo].[vw_ServiceRequests] SR ON VW.ServiceRequestID = SR.ServiceRequestID
		JOIN	Member M WITH (NOLOCK) ON SR.MemberID = M.ID
		JOIN	Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID
		WHERE	VW.PurchaseOrderNumber = @numberValue
	END

	SELECT	R.ServiceRequestID,
			R.PurchaseOrderNumber,
			R.SubmittedDate,
			R.ClientName,
			R.ProgramName,
			R.MembershipNumber,
			R.MemberName,
			R.MemberID,
			R.MembershipID
	FROM	@results R



END