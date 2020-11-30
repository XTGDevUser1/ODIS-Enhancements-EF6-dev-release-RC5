IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_call_history_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_call_history_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vendor_call_history_get] 852,357
 
CREATE PROCEDURE [dbo].[dms_vendor_call_history_get]( 				
		@ServiceRequestID int
		,@VendorLocationID int
)
AS 
BEGIN
	DECLARE @serviceRequestEntityID INT
	DECLARE @vendorLocationEntityID INT
	SET @serviceRequestEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'ServiceRequest')
	SET @vendorLocationEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'VendorLocation')
	
	
	
		SELECT DISTINCT
			ISPcll.RecordID VendorLocationID
			, SRcll.RecordID AS ServiceRequestID
			,v.Name VendorName
			,cl.PhoneNumber
			,cl.PhoneTypeID
			,cl.TalkedTo			
			,cl.CreateDate
			,cl.CreateBy
			,cact.[Description]
			,cl.Comments
			,ISNULL(cl.IsPossibleCallback,0) IsPossibleCallback
			, cr.Name
		FROM dbo.VendorLocation vl
		JOIN dbo.Vendor v ON v.ID = vl.VendorID
		JOIN dbo.ContactLogLink ISPcll ON ISPcll.EntityID = @vendorLocationEntityID AND ISPcll.RecordID = vl.ID
		JOIN dbo.ContactLogLink SRcll ON SRcll.ContactLogID = ISPcll.ContactLogID AND SRcll.EntityID = @serviceRequestEntityID AND SRcll.RecordID = @ServiceRequestID 
		JOIN dbo.ContactLog cl ON cl.ID = ISPcll.ContactLogID
		JOIN dbo.ContactLogReason clr ON clr.ContactLogID = cl.ID
		JOIN dbo.ContactReason cr ON cr.ID = clr.ContactReasonID
		JOIN dbo.ContactLogAction cla ON cla.ContactLogID = cl.ID
		JOIN dbo.ContactAction cact ON cact.ID = cla.ContactActionID
		WHERE vl.ID = @VendorLocationID
		AND cr.Name = 'ISP selection' --KB Took the values from ContactReason table
		ORDER BY CL.CreateDate DESC
END

GO