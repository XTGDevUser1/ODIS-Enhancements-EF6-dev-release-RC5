IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_EventSubscriptions]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_EventSubscriptions] 
 END 
 GO  
CREATE VIEW [dbo].[vw_EventSubscriptions]
AS
Select 
	es.ID EventSubscriptionID
	,es.EventID
	,es.IsActive
	,e.Name EventName
	,LinkList.EntityLinks
	,RecipientList.Recipients
	,es.CreateDate
	,es.CreateBy
From EventSubscription es
Join [Event] e on e.ID = es.EventID

Left Join (
	select distinct t1.EventSubscriptionID,
	  STUFF(
			 (SELECT ', ' + e.Name + ': '  +  Convert(nvarchar(50), t2.RecordID)
			  FROM EventSubscriptionLink t2
			  Join Entity e on e.ID = t2.EntityID
			  where t1.EventSubscriptionID = t2.EventSubscriptionID
			  Order By e.Name
			  FOR XML PATH (''))
			  , 1, 1, '')  AS EntityLinks
	from EventSubscriptionLink t1
	) LinkList ON LinkList.EventSubscriptionID = es.ID

Left Join (
	select distinct t1.EventSubscriptionID,
	  STUFF(
			 (SELECT ', ' + 
			  COALESCE( e.Name + ': '  +  Convert(nvarchar(50), p.RecordID), t2.Recipient)
			  FROM EventSubscriptionRecipient t2
			  Left Join Person p on p.ID = t2.PersonID
			  Left Join Entity e on e.ID = p.EntityID
			  where t1.EventSubscriptionID = t2.EventSubscriptionID
			  Order By e.Name
			  FOR XML PATH (''))
			  , 1, 1, '')  AS Recipients
	from EventSubscriptionRecipient t1
	) RecipientList ON RecipientList.EventSubscriptionID = es.ID
GO

