/****** Object:  StoredProcedure [dbo].[dms_POComments]    Script Date: 04/29/2014 02:13:21 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_POComments]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_POComments] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[dms_POComments](@i5PurchaseOrderID INT, @serviceRequestID INT)
AS  
BEGIN  
	--DECLARE @i5purchaseorderID as INT
	--DECLARE @servicerequestID as INT

-- Get Comments
SELECT c.Description, c.CreateBy, c.CreateDate
FROM  Comment c
JOIN ServiceRequest sr on sr.ID = c.RecordID and c.EntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
WHERE
	c.EntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
	and c.RecordID = @serviceRequestID

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
	, cl.CreateBy
	, cl.CreateDate
FROM PurchaseOrder po 
JOIN ContactLogLink cll ON cll.RecordID = po.ID AND cll.EntityID = (SELECT ID FROM Entity WHERE name = 'PurchaseOrder')
JOIN ContactLog cl ON cl.ID = cll.ContactLogID
JOIN ContactMethod cm ON cm.ID = cl.ContactMethodID
JOIN ContactLogAction cla ON cla.ContactLogID = cl.ID 
JOIN ContactAction cac ON cac.ID = cla.ContactActionID AND cac.Name = 'Pending' AND cac.ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ContactVendor')
WHERE
	po.LegacyReferenceNumber = @i5purchaseorderID
	AND po.IsActive = 1

UNION

-- Get all PO Cancel Comments
SELECT
	'Cancel Comment: ' + po.CancellationComment AS Description
	, el.CreateBy
	, el.CreateDate
FROM PurchaseOrder po
JOIN EventLogLink ell ON ell.RecordID = po.ID and ell.EntityID = (SELECT ID FROM Entity WHERE name = 'PurchaseOrder')
JOIN EventLog el ON el.ID = ell.EventLogID
JOIN Event e on e.ID = el.EventID AND e.Name = 'CancelPO'
WHERE
	po.LegacyReferenceNumber = @i5purchaseorderID 
	AND isnull(po.CancellationComment, '') <> ''
	AND po.IsActive = 1


UNION

-- Get all PO GOA Comments
SELECT
	'GOA Comment: ' + po.GOAComment AS Description
	, po.CreateBy
	, po.CreateDate
FROM PurchaseOrder po
WHERE
	po.LegacyReferenceNumber = @i5PurchaseOrderID
	AND po.IsActive = 1
	AND isnull(po.GOAComment,'') <> ''
	AND po.IsGOA = 1

ORDER BY CreateDate

END
GO
