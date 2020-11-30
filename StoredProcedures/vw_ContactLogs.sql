
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_ContactLogs]')) 
 BEGIN
 DROP VIEW [dbo].[vw_ContactLogs] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
/****** Object:  View [dbo].[vw_ContactLogs]    Script Date: 11/09/2014 17:58:55 ******/
SET ANSI_NULLS ON
GO
/*
	Select * from [vw_ContactLogs]
*/
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[vw_ContactLogs]

AS

SELECT DISTINCT

	   CL.ID ContactLogID,

	   CL.ContactCategoryID,

	   CC.Description ContactCategoryDescription,

	   CL.ContactTypeID,

	   CT.Description ContactTypeDescription,

	   CL.ContactMethodID,

	   CM.Description ContactMethodDescription,

	   CL.ContactSourceID,

	   CS.Description ContactSourceDescription,

	   CL.Company,

	   CL.TalkedTo,

	   CL.PhoneTypeID,

	   PT.Description PhoneTypeDescription,

	   CL.PhoneNumber,

	   CL.Email,

	   CL.Direction,

	   CL.Description,

	   CL.Data,

	   CL.Comments,

	   CL.AgentRating,

	   Cl.IsPossibleCallback,

	   CL.DataTransferDate,

	   CL.CreateDate,

	   CL.CreateBy,

	   datepart(hh,CL.CreateDate) HourOfDay,

	   DATENAME(dw,CL.CreateDate) [DayOfWeek],

	   --CL.ModifyDate,

	   --CL.ModifyBy,

	   CL.VendorServiceRatingAdjustment,

	   --COALESCE(SR_cll.RecordID, (SELECT ServiceRequestID FROM PurchaseOrder WHERE ID = PO_cll.RecordID)) ServiceRequestID,
	   SR.ID ServiceRequestID,
	   
	   PO.ID PurchaseOrderID, 

	   VL.ID VendorLocationID,

	   VI.ID VendorInvoiceID,

	   MBR.ID MemberID,

	   EA_cll.RecordID EmergencyAssistanceID,

	   PMT_cll.RecordID PaymentID,

	   FB_cll.RecordID FeedbackID

FROM   ContactLog CL (NOLOCK)

LEFT JOIN ContactCategory CC (NOLOCK) ON CL.ContactCategoryID = CC.ID

LEFT JOIN ContactType CT (NOLOCK) ON CL.ContactTypeID = CT.ID

LEFT JOIN ContactMethod CM (NOLOCK) ON CL.ContactMethodID = CM.ID

LEFT JOIN ContactSource CS (NOLOCK) ON CL.ContactSourceID = CS.ID

LEFT JOIN PhoneType PT (NOLOCK) ON CL.PhoneTypeID = PT.ID

LEFT OUTER JOIN ContactLogLink SR_cll (NOLOCK) ON SR_cll.ContactLogID = CL.ID AND SR_cll.EntityID = 13 --(SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
LEFT OUTER JOIN ServiceRequest SR (NOLOCK) ON SR.ID = SR_cll.RecordID

LEFT OUTER JOIN ContactLogLink PO_cll (NOLOCK) ON PO_cll.ContactLogID = CL.ID AND PO_cll.EntityID = 11 --(SELECT ID FROM Entity WHERE Name = 'PurchaseOrder')
LEFT OUTER JOIN PurchaseOrder PO (NOLOCK) ON PO.ID = PO_cll.RecordID

LEFT OUTER JOIN ContactLogLink VL_cll (NOLOCK) ON VL_cll.ContactLogID = CL.ID AND VL_cll.EntityID = 18 --(SELECT ID FROM Entity WHERE Name = 'VendorLocation')
LEFT OUTER JOIN VendorLocation VL (NOLOCK) ON VL.ID = VL_cll.RecordID

LEFT OUTER JOIN ContactLogLink VI_cll (NOLOCK) ON VI_cll.ContactLogID = CL.ID AND VI_cll.EntityID = 28 --(SELECT ID FROM Entity WHERE Name = 'VendorInvoice')
LEFT OUTER JOIN VendorInvoice VI (NOLOCK) ON VI.ID = VI_cll.RecordID

LEFT OUTER JOIN ContactLogLink MBR_cll (NOLOCK) ON MBR_cll.ContactLogID = CL.ID AND MBR_cll.EntityID = 5 --(SELECT ID FROM Entity WHERE Name = 'Member')
LEFT OUTER JOIN Member MBR (NOLOCK) ON MBR.ID = MBR_cll.RecordID

LEFT OUTER JOIN ContactLogLink EA_cll (NOLOCK) ON EA_cll.ContactLogID = CL.ID AND EA_cll.EntityID = 20 --(SELECT ID FROM Entity WHERE Name = 'EmergencyAssistance')

LEFT OUTER JOIN ContactLogLink PMT_cll (NOLOCK) ON PMT_cll.ContactLogID = CL.ID AND PMT_cll.EntityID = 8 --(SELECT ID FROM Entity WHERE Name = 'Payment')

LEFT OUTER JOIN ContactLogLink FB_cll (NOLOCK) ON FB_cll.ContactLogID = CL.ID AND FB_cll.EntityID = 31 --(SELECT ID FROM Entity WHERE Name = 'Feedback')
GO

