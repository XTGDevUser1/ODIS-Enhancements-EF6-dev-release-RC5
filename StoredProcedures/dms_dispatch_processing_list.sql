IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_dispatch_processing_list]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_dispatch_processing_list]
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 
-- EXEC [dbo].[dms_dispatch_processing_list]		 
CREATE PROC [dbo].[dms_dispatch_processing_list]
AS
BEGIN
	
	CREATE TABLE #Results
	(
		ContactMethodID INT NOT NULL,
		ServiceRequestID INT NOT NULL,
		IsSMSAvailable BIT NULL,
		MemberID INT NOT NULL,
		ETADate DATETIME NULL,
		CaseID INT NOT NULL,
		ContactPhoneTypeID INT NULL,
		ContactPhoneNumber NVARCHAR(50) NULL,
		ProgramID INT NOT NULL,
		TollFreeNumber NVARCHAR(255) NULL,
		PurchaseOrderNumber NVARCHAR(255) NULL,
		IsClosedLoopAutomated BIT NULL,
		SourceSystemID INT NULL,
		SourceSystem NVARCHAR(50) NULL
	)
			 
	;with wResult AS(
	SELECT 
	CASE WHEN C.SourceSystemID = (SELECT ID FROM SourceSystem WHERE Name = 'MemberMobile') 
			THEN (SELECT ID From ContactMethod Where Name = 'MobileNotification')
		 WHEN ISNULL(C.IsSMSAvailable,0) = 1 
			THEN (SELECT ID From ContactMethod Where Name = 'Text')
		 ELSE
			(SELECT ID From ContactMethod Where Name = 'IVR')
    	 END AS 'ContactMethodID',
		
	SR.ID AS 'ServiceRequestID',
	ISNULL(C.IsSMSAvailable,0) AS 'IsSMSAvailable',
	ISNULL(PRG.IsClosedLoopAutomated,0) AS 'IsClosedLoopAutomated',
	C.MemberID,
	PO.ETADate,
	C.ID AS 'CaseID',
	C.ContactPhoneTypeID,
	C.ContactPhoneNumber,
	C.ProgramID,
	PO.PurchaseOrderNumber,
	(SELECT TOP 1 dbo.fnc_FormatPhoneNumber(DispatchPhoneNumber,0) FROM dbo.fnc_GetProgramDispatchNumber(C.ProgramID)) AS 'TollFreeNumber',
	ROW_NUMBER() OVER(PARTITION BY PO.ServiceRequestID ORDER BY PO.IssueDate ASC) AS 'SRank',
	C.SourceSystemID,
	SS.Name AS SourceSystem
	FROM 
	ServiceRequest SR with(nolock)
	LEFT JOIN PurchaseOrder PO with(nolock) ON SR.ID = PO.ServiceRequestID
	LEFT JOIN [Case] C with(nolock) ON C.ID = SR.CaseID
	LEFT JOIN Program PRG with(nolock) ON PRG.ID = C.ProgramID
	LEFT JOIN Product P with(nolock) ON P.ID = PO.ProductID
	LEFT JOIN SourceSystem SS with(nolock) ON SS.ID = C.SourceSystemID
	WHERE
	SR.ClosedLoopStatusID IS NULL 
	AND SR.ServiceRequestStatusID IN(SELECT ID From ServiceRequestStatus Where Name = 'Dispatched')
	AND (SR.NextActionID is null OR SR.NextActionID <> (SELECT ID FROM NextAction WHERE Name = 'ManualClosedLoop'))
	AND ISNULL(SR.IsRedispatched,0) = 0
	AND ISNULL(SR.ClosedLoopNextSend,PO.ETADate) <= GETDATE()
	AND PO.PurchaseOrderStatusID in (SELECT ID from PurchaseOrderStatus WHERE Name in ('Issued', 'Issued-Paid'))
	AND C.ContactPhoneNumber is not null 
	AND ISNULL(PRG.IsClosedLoopAutomated,0) = 1
	---- Removed per Asana task
	--AND P.ProductCategoryID <> (select ID from ProductCategory where name = 'Mobile')
	)
	
	INSERT INTO #Results(
		ContactMethodID,
		ServiceRequestID,
		IsSMSAvailable,
		MemberID,
		ETADate,
		CaseID,
		ContactPhoneTypeID,
		ContactPhoneNumber,
		ProgramID,
		TollFreeNumber,
		PurchaseOrderNumber,
		IsClosedLoopAutomated,
		SourceSystemID,
		SourceSystem
	)
	SELECT wResult.ContactMethodID,
		wResult.ServiceRequestID,
		wResult.IsSMSAvailable,
		wResult.MemberID,
		wResult.ETADate,
		wResult.CaseID,
		wResult.ContactPhoneTypeID,
		wResult.ContactPhoneNumber,
		wResult.ProgramID,
		wResult.TollFreeNumber,
		wResult.PurchaseOrderNumber,
		wResult.IsClosedLoopAutomated,
		wResult.SourceSystemID,
		wResult.SourceSystem
		FROM wResult 
		WHERE  SRank = 1

	-- Insert a duplicate record for Text notification for all those records whose contactmethod = 'MobileNotification'
	INSERT INTO #Results(
		ContactMethodID,
		ServiceRequestID,
		IsSMSAvailable,
		MemberID,
		ETADate,
		CaseID,
		ContactPhoneTypeID,
		ContactPhoneNumber,
		ProgramID,
		TollFreeNumber,
		PurchaseOrderNumber,
		IsClosedLoopAutomated,
		SourceSystemID,
		SourceSystem
	)

	SELECT	(SELECT ID FROM ContactMethod WHERE Name = 'Text'),
			wResult.ServiceRequestID,
			wResult.IsSMSAvailable,
			wResult.MemberID,
			wResult.ETADate,
			wResult.CaseID,
			wResult.ContactPhoneTypeID,
			wResult.ContactPhoneNumber,
			wResult.ProgramID,
			wResult.TollFreeNumber,
			wResult.PurchaseOrderNumber,
			wResult.IsClosedLoopAutomated,
			wResult.SourceSystemID,
			wResult.SourceSystem
	FROM	#Results wResult
	WHERE	wResult.ContactMethodID = (SELECT ID FROM ContactMethod WHERE Name = 'MobileNotification')

	SELECT	wResult.ContactMethodID,
			wResult.ServiceRequestID,
			wResult.IsSMSAvailable,
			wResult.MemberID,
			wResult.ETADate,
			wResult.CaseID,
			wResult.ContactPhoneTypeID,
			wResult.ContactPhoneNumber,
			wResult.ProgramID,
			wResult.TollFreeNumber,
			wResult.PurchaseOrderNumber,
			wResult.IsClosedLoopAutomated,
			wResult.SourceSystemID,
			wResult.SourceSystem
	FROM	#Results wResult

	DROP TABLE #Results
	
END
	 
		 
		 
		 
