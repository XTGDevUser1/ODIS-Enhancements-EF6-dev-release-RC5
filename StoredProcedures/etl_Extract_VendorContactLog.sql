IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[etl_Extract_VendorContactLog]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[etl_Extract_VendorContactLog]
GO

CREATE PROCEDURE [dbo].[etl_Extract_VendorContactLog] 
AS
BEGIN

    SELECT 
		SR.ID ServiceRequestID
		,ISNULL(PO.ID, 0) PurchaseOrderID
		,PO.PurchaseOrderNumber
		--,(Select name from PurchaseOrderStatus WHERE ID = PO.PurchaseOrderStatusID) PurchaseOrderStatus
		,v.VendorNumber
		--,v.Name VendorName
		--,vl.ID VendorLocationID
		,vl.Sequence
		,CL.ID ContactLogID
		--,cla.ID ContactLogActionID
		,ca.ID ContactActionID
		--,ca.Name ContactActionName
		,LEFT(cl.Comments,30) Comments
		,cla.CreateDate
		,cla.CreateBy
    FROM dbo.ContactLog cl  
    JOIN dbo.ContactLogReason clr ON cl.ID = clr.ContactLogID
    JOIN dbo.ContactReason cr ON clr.ContactReasonID = cr.ID
    JOIN dbo.ContactLogLink SRcll ON SRcll.ContactLogID = cl.ID  
    JOIN dbo.Entity e1 ON e1.ID = SRcll.EntityID AND e1.Name = 'ServiceRequest'  
    JOIN dbo.ServiceRequest sr ON sr.ID = SRcll.RecordID
    JOIN dbo.ContactLogLink ISPcll ON ISPcll.ContactLogID = cl.ID  
    JOIN dbo.Entity e2 ON e2.ID = ISPcll.EntityID AND e2.Name = 'VendorLocation'  
    JOIN dbo.VendorLocation vl ON vl.ID = ISPcll.RecordID
    JOIN dbo.Vendor v ON v.ID = vl.VendorID
    JOIN dbo.ContactLogAction cla ON cla.ContactLogID = CL.ID
    JOIN dbo.ContactAction ca ON ca.ID = cla.ContactActionID
    LEFT OUTER JOIN (
		SELECT ServiceRequestID, MIN(ID) PurchaseOrderID
		FROM PurchaseOrder 
		WHERE ISNULL(PurchaseOrderNumber, '') <> ''
		GROUP BY ServiceRequestID
		) FirstPO ON FirstPO.ServiceRequestID = SRcll.RecordID
	LEFT OUTER JOIN dbo.PurchaseOrder PO ON FirstPO.PurchaseOrderID = PO.ID
    WHERE  
    cr.Name = 'ISP Selection'  
    AND ca.Name NOT IN ('Negotiate', 'Call Not Made', 'Accepted')
    AND (SR.DataTransferDate IS NOT NULL OR PO.DataTransferDate IS NOT NULL)
    AND cl.DataTransferDate IS NULL
    AND PO.ID IS NOT NULL
    AND ISNULL(v.VendorNumber,'') <> ''
    AND ISNULL(v.VendorNumber,'') NOT LIKE '9X%'
    
   
	UNION
    SELECT 
		SR.ID ServiceRequestID
		,ISNULL(PO.ID, 0) PurchaseOrderID
		,ISNULL(PO.PurchaseOrderNumber,'') PurchaseOrderNumber
		--,(Select name from PurchaseOrderStatus WHERE ID = PO.PurchaseOrderStatusID) PurchaseOrderStatus
		,v.VendorNumber
		--,v.Name VendorName
		--,vl.ID VendorLocationID
		,vl.Sequence
		,CL.ID ContactLogID
		--,cla.ID ContactLogActionID
		,ca.ID ContactActionID
		--,ca.Name ContactActionName
		,LEFT(cl.Comments,30) Comments
		,cla.CreateDate
		,cla.CreateBy
    FROM dbo.ContactLog cl  
    JOIN dbo.ContactLogReason clr ON cl.ID = clr.ContactLogID
    JOIN dbo.ContactReason cr ON clr.ContactReasonID = cr.ID
    JOIN dbo.ContactLogLink SRcll ON SRcll.ContactLogID = cl.ID  
    JOIN dbo.Entity e1 ON e1.ID = SRcll.EntityID AND e1.Name = 'ServiceRequest'  
    JOIN dbo.ServiceRequest sr ON sr.ID = SRcll.RecordID
    JOIN dbo.ContactLogLink ISPcll ON ISPcll.ContactLogID = cl.ID  
    JOIN dbo.Entity e2 ON e2.ID = ISPcll.EntityID AND e2.Name = 'VendorLocation'  
    JOIN dbo.VendorLocation vl ON vl.ID = ISPcll.RecordID
    JOIN dbo.Vendor v ON v.ID = vl.VendorID
    JOIN dbo.ContactLogAction cla ON cla.ContactLogID = CL.ID
    JOIN dbo.ContactAction ca ON ca.ID = cla.ContactActionID
    --JOIN Batch_Processing_ETL.DMS.Map_CNET_VendorLogCode CNETCode ON CNETCode.ContactActionID = ca.ID
    LEFT OUTER JOIN (
		SELECT ServiceRequestID, VendorLocationID, MIN(ID) PurchaseOrderID
		FROM PurchaseOrder 
		WHERE ISNULL(PurchaseOrderNumber, '') <> ''
		GROUP BY ServiceRequestID, VendorLocationID
		) FirstPO ON FirstPO.ServiceRequestID = SRcll.RecordID AND FirstPO.VendorLocationID = vl.ID
	LEFT OUTER JOIN dbo.PurchaseOrder PO ON FirstPO.PurchaseOrderID = PO.ID
    WHERE  
    cr.Name = 'ISP Selection' 
    AND ca.Name = 'Accepted'
    AND (SR.DataTransferDate IS NOT NULL OR PO.DataTransferDate IS NOT NULL)
    AND cl.DataTransferDate IS NULL
    AND PO.ID IS NOT NULL
    AND ISNULL(v.VendorNumber,'') <> ''
    AND ISNULL(v.VendorNumber,'') NOT LIKE '9X%'
     
    ORDER BY ServiceRequestID, CreateDate

END
GO

