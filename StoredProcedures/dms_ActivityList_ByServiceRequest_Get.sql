
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ActivityList_ByServiceRequest_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ActivityList_ByServiceRequest_Get] 
 END 
 GO  
/****** Object:  StoredProcedure [dbo].[dms_ActivityList_ByServiceRequest_Get]    Script Date: 07/23/2013 18:36:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 
 CREATE PROCEDURE [dbo].[dms_ActivityList_ByServiceRequest_Get]( 
	@serviceRequestID INT
 ) 
 AS 
 BEGIN
 
/*
*	Name				: dms_ActivityList_ByServiceRequest_Get
*	Purpose				: To get all the activities for a given Service Request -- Comments, Send PO's
*	Execution sample	: EXEC [dbo].[dms_ActivityList_ByServiceRequest_Get] '28498' --'25592'  -- select * from servicerequest sr join purchaseorder po on po.servicerequestid = sr.id
*/


-- Get Comments
	SELECT 
			C.Description
			, C.CreateBy
			, C.CreateDate
	FROM	Comment C
	JOIN	ServiceRequest SR on SR.ID = C.RecordID and C.EntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
	WHERE	C.EntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
	AND		C.RecordID = @serviceRequestID

	UNION

-- Get all Send PO's
	SELECT
			'Dispatch PO ' + cm.Name
			+ ' - ' +
			CASE 
				WHEN cm.Name = 'Fax' THEN cl.PhoneNumber 
				WHEN cm.Name = 'Email' THEN cl.Email 
				WHEN cm.Name = 'Verbally' THEN ''
				ELSE ''
			END  AS Description
			, CL.CreateBy
			, CL.CreateDate
	FROM		ServiceRequest SR 
	LEFT JOIN	PurchaseOrder PO ON PO.ServiceRequestID = SR.ID 
	JOIN		ContactLogLink CLL ON CLL.RecordID = PO.ID AND CLL.EntityID = (SELECT ID FROM Entity WHERE Name = 'PurchaseOrder')
	JOIN		ContactLog CL ON CL.ID = CLL.ContactLogID
	JOIN		ContactMethod CM ON CM.ID = CL.ContactMethodID
	JOIN		ContactLogAction CLA ON CLA.ContactLogID = CL.ID 
	JOIN		ContactAction CAC ON cac.ID = CLA.ContactActionID AND CAC.Name = 'Pending' AND CAC.ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ContactVendor')
	WHERE		SR.ID = @serviceRequestID
	AND			PO.IsActive = 1
	AND			PO.PurchaseOrderStatusID <> (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending')

	UNION

-- Get all PO Cancel Comments
	SELECT
			'Cancel Comment: ' + left(PO.CancellationComment,200) AS Description
			, EL.CreateBy
			, EL.CreateDate
	FROM		ServiceRequest SR
	LEFT JOIN	PurchaseOrder PO ON PO.ServiceRequestID = SR.ID 
	LEFT JOIN	EventLogLink ELL ON ELL.RecordID = PO.ID and ELL.EntityID = (SELECT ID FROM Entity WHERE Name = 'PurchaseOrder')
	LEFT JOIN	EventLog EL ON el.ID = ELL.EventLogID
	JOIN		Event E ON E.ID = EL.EventID AND E.Name = 'CancelPO'
	WHERE	sr.ID = @serviceRequestID
	AND		PO.IsActive = 1
	AND		PO.PurchaseOrderStatusID <> (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending')
	AND		isnull(po.CancellationComment, '') <> ''

	UNION

-- Get all PO GOA Comments
	SELECT
			'GOA Comment: ' + left(PO.GOAComment,200) AS Description
			, EL.CreateBy
			, EL.CreateDate
	FROM	ServiceRequest SR
	LEFT JOIN	PurchaseOrder PO ON PO.ServiceRequestID = SR.ID 
	LEFT JOIN	EventLogLink ELL ON ELL.RecordID = PO.ID AND ELL.EntityID = (SELECT ID FROM Entity WHERE Name = 'PurchaseOrder')
	LEFT JOIN	EventLog EL ON EL.ID = ELL.EventLogID
	JOIN		Event E ON E.ID = EL.EventID AND E.Name = 'Create GOA'
	WHERE	SR.ID = @serviceRequestID
	AND		PO.IsActive = 1
	AND		PO.PurchaseOrderStatusID <> (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending')
	AND		isnull(PO.GOAComment,'') <> ''

	ORDER BY CreateDate

END



GO


