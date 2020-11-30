IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Recent_Call_Details_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
	DROP PROCEDURE [dbo].[dms_Recent_Call_Details_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 -- EXEC [dms_Recent_Call_Details_Get] @purchaseOrderID = 450216
 CREATE PROCEDURE [dbo].[dms_Recent_Call_Details_Get](   
	@purchaseOrderID INT
 )
 AS
 BEGIN

	DECLARE @serviceRequestID INT = NULL,
			@vendorLocationID INT = NULL
	SELECT	@serviceRequestID = ServiceRequestID, 
			@vendorLocationID = VendorLocationID
	FROM	PurchaseOrder PO WITH (NOLOCK)
	WHERE	ID = @purchaseOrderID
			
	SELECT	CL.TalkedTo,
			PT.Name AS PhoneType,
			CL.PhoneNumber
	FROM	ContactLog CL WITH (NOLOCK)
	JOIN	ContactLogLink CLLSR WITH (NOLOCK) ON CL.ID = CLLSR.ContactLogID 
												AND CLLSR.EntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
												AND CLLSR.RecordID = @serviceRequestID
	JOIN	ContactLogLink CLLVL WITH (NOLOCK) ON CL.ID = CLLVL.ContactLogID 
												AND CLLVL.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
												AND CLLVL.RecordID = @vendorLocationID
	JOIN	ContactLogAction CLA WITH (NOLOCK) ON CLA.ContactLogID = CL.ID 
	JOIN	ContactAction CA WITH (NOLOCK) ON CLA.ContactActionID = CA.ID
	LEFT JOIN PhoneType PT WITH (NOLOCK) ON CL.PhoneTypeID = PT.ID
	WHERE	CA.Name = 'Negotiate'
	ORDER BY CL.CreateDate DESC
END
GO

