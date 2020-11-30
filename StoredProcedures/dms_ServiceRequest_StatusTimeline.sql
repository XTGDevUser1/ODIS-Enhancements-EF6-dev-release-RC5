IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ServiceRequest_StatusTimeline]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ServiceRequest_StatusTimeline]
 END 
 GO
 -- exec [dbo].[dms_ServiceRequest_StatusTimeline] 1575
CREATE PROCEDURE [dbo].[dms_ServiceRequest_StatusTimeline]
      @ServiceRequestID int
AS
BEGIN

	--declare @ServiceRequestID int = 664428
	
	DECLARE @ServiceRequestEntityID int = (Select ID From Entity Where Name = 'ServiceRequest')
	DECLARE @PurchaseOrderEntityID int = (Select ID From Entity Where Name = 'PurchaseOrder')
	DECLARE @MobileServiceRequestCommentTypeID int = (Select ID From CommentType Where Name = 'MobileServiceRequest')

	--SELECT 'Request Submitted' AS [Status]
	--	,sr.CreateDate AS StatusDate
	--	,'We will soon begin processing your request.' StatusMessage
	--FROM [Case] c
	--JOIN ServiceRequest sr on sr.CaseID = c.ID
	--JOIN Product prod on prod.ID = sr.PrimaryProductID
	--JOIN ProductCategory pc on pc.ID = prod.ProductCategoryID
	--WHERE sr.ID = @ServiceRequestID


	--UNION
	
	SELECT 'Request Submitted' AS [Status]
		,el.CreateDate AS StatusDate
		,'We will soon begin processing your request for ' + pc.[Description] + CASE WHEN CHARINDEX('service',pc.[Description]) > 0 THEN '' ELSE ' service' END + '.' 
		 + CASE WHEN ISNULL(cm.[Description],'') <> '' THEN '<br><b>Customer Note:</b> ' + cm.[Description] ELSE '' END
		 AS StatusMessage
	FROM ServiceRequest sr
	Join ProductCategory pc on pc.ID = sr.ProductCategoryID
	Join [Case] c on c.ID = sr.CaseID
	Join EventLogLink SR_ell on SR_ell.EntityID = @ServiceRequestEntityID and SR_ell.RecordID = sr.ID
	Join EventLog el on SR_ell.EventLogID = el.ID 
	Join [Event] e on e.ID = el.EventID
	Left Join SourceSystem ss on ss.ID = c.SourceSystemID
	Left Join Comment cm on cm.EntityID = @ServiceRequestEntityID and cm.RecordID = sr.ID and cm.CommentTypeID = @MobileServiceRequestCommentTypeID
	WHERE sr.ID = @ServiceRequestID
	And e.Name = 'SubmittedForDispatch'


	UNION
	SELECT 'Dispatch In-Process' AS [Status]
		,el.CreateDate AS StatusDate
		,'We are searching for a service provider in your area.' StatusMessage
	FROM ServiceRequest sr
	Join [Case] c on c.ID = sr.CaseID
	Join SourceSystem ss on ss.ID = c.SourceSystemID
	Join EventLogLink SR_ell on SR_ell.EntityID = @ServiceRequestEntityID and SR_ell.RecordID = sr.ID
	Join EventLog el on SR_ell.EventLogID = el.ID 
	Join [Event] e on e.ID = el.EventID
	WHERE sr.ID = @ServiceRequestID
	And e.Name = 'DispatchInProcess'
	--And ss.Name = 'MemberMobile'  ---- Only show for mobile 


	UNION
	SELECT 'Service Dispatched' AS [Status]
		,PO.IssueDate AS StatusDate
		,v.Name + ' has been dispatched to your location for ' 
				+ pc.[Description] + CASE WHEN CHARINDEX('service',pc.[Description]) > 0 THEN '' ELSE ' service' END 
				+ '. ETA is ' + CONVERT(nvarchar(50), po.ETAMinutes) +' minutes. '  StatusMessage
	FROM ServiceRequest sr
	Join EventLogLink SR_ell on SR_ell.EntityID = @ServiceRequestEntityID and SR_ell.RecordID = sr.ID
	Join EventLog el on SR_ell.EventLogID = el.ID 
	Join [Event] e on e.ID = el.EventID
	Join EventLogLink PO_ell on PO_ell.EventLogID = el.ID and PO_ell.EntityID = @PurchaseOrderEntityID 
	JOIN PurchaseOrder po on PO.ID = PO_ell.RecordID AND po.IsActive = 1  
	JOIN VendorLocation vl on vl.ID = po.VendorLocationID 
	JOIN Vendor v on v.ID = vl.VendorID
	JOIN Product prod on prod.ID = po.ProductID
	JOIN ProductCategory pc on pc.ID = prod.ProductCategoryID
	WHERE sr.ID = @ServiceRequestID
	And e.Name = 'Dispatched'


	UNION
	SELECT 'Request Cancelled' AS [Status]
		,el.CreateDate AS StatusDate
		,'Your requested service has been cancelled.' StatusMessage
	FROM ServiceRequest sr
	Join [Case] c on c.ID = sr.CaseID
	Join SourceSystem ss on ss.ID = c.SourceSystemID
	Join EventLogLink SR_ell on SR_ell.EntityID = @ServiceRequestEntityID and SR_ell.RecordID = sr.ID
	Join EventLog el on SR_ell.EventLogID = el.ID 
	Join [Event] e on e.ID = el.EventID
	WHERE sr.ID = @ServiceRequestID
	And e.Name = 'ServiceCancelled'


	UNION
	SELECT 'Request Complete' AS [Status]
		,el.CreateDate AS StatusDate
		,'Your requested service has been completed.' StatusMessage
	FROM ServiceRequest sr
	Join [Case] c on c.ID = sr.CaseID
	Join SourceSystem ss on ss.ID = c.SourceSystemID
	Join EventLogLink SR_ell on SR_ell.EntityID = @ServiceRequestEntityID and SR_ell.RecordID = sr.ID
	Join EventLog el on SR_ell.EventLogID = el.ID 
	Join [Event] e on e.ID = el.EventID
	WHERE sr.ID = @ServiceRequestID
	And e.Name = 'ServiceCompleted'

	ORDER BY StatusDate

END
