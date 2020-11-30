IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Send_History_List]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Send_History_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_Send_History_List] 2
 CREATE PROCEDURE [dbo].[dms_Send_History_List]( 
  @PurchaseOrderId  INT = NULL
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
-- 	Select ca.Name as ContactMethod, cl.CreateDate as DateSent
--	From ContactLog cl
--	Join ContactLogLink cll on cll.ContactLogID = cl.ID
--	Join ContactLogAction cla on cla.ContactLogID = cl.ID 
--	Join ContactAction ca on ca.ID =  cla.ContactActionID 
--	and ca.Name in ('Pending','Sent','SendFailure') 
--	--and ca.ContactCategoryID = (Select ID From ContactCategory Where Name = 'ContactVendor')
--Where
--	cll.EntityID = (Select ID From Entity Where Name = 'PurchaseOrder')
--	AND
--	 cll.RecordID = @purchaseOrderId
Select cm.Name as ContactMethod
, CASE
When cm.Name = 'Fax' then cl.PhoneNumber + ' (' + cl.TalkedTo + ')'
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
and ca.Name in ('Pending','Sent','SendFailure') 
Where
cll.EntityID = (Select ID From Entity Where Name = 'PurchaseOrder')
AND
cll.RecordID = @PurchaseOrderID 
	 END 
