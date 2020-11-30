IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Payment_SendReceipt_History]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Payment_SendReceipt_History] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

CREATE PROC dms_Payment_SendReceipt_History(@paymentID INT = NULL)
AS
BEGIN
Select cm.Name as ContactMethod
, CASE
When cm.Name = 'Text' then cl.PhoneNumber
When cm.Name = 'Email' then cl.Email
END as SentTo 

, ca.Name as ContactAction
, cl.CreateDate as DateSent
, cl.CreateBy as Username	
From ContactLog cl
Join ContactLogLink cll on cll.ContactLogID = cl.ID
Join ContactLogAction cla on cla.ContactLogID = cl.ID 
Join ContactAction ca on ca.ID = cla.ContactActionID 
Join ContactMethod cm on cm.ID = cl.ContactMethodID
and ca.Name ='Sent Payment Receipt'and ca.ContactCategoryID =(Select ID From ContactCategory Where Name ='ContactCustomer')
Where
	cll.EntityID = (Select ID From Entity Where Name = 'Payment')
AND	cll.RecordID = @paymentID
ORDER BY cl.CreateDate DESC 
END