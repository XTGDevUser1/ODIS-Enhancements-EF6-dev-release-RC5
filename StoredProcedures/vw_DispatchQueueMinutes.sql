IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_DispatchQueueMinutes]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_DispatchQueueMinutes] 
 END 
 GO  
CREATE View [dbo].[vw_DispatchQueueMinutes]
AS
Select 
cl.Name Client
,p.Name Program
,sr.ID ServiceRequest 
,sr.CreateDate ServiceRequestCreateDate
,Dispatch.SubmitForDispatchDate
,Dispatch.FirstVendorSelectionDate
,ROUND(DATEDIFF(ss, Dispatch.SubmitForDispatchDate, Dispatch.FirstVendorSelectionDate) / 60.0, 2) QueueMinutes
,FirstPO.CreateDate FirstPOCreateDate
,PO.CreateBy FirstPOCreateBy
From [Case] c (NOLOCK)
Join Program p (NOLOCK) on c.ProgramID = p.ID
Join Client cl (NOLOCK) on cl.ID = p.ClientID
Join ServiceRequest sr on sr.CaseID = c.ID
Left Outer Join (
	Select sr.ID ServiceRequestID, MIN(po.ID) PurchaseOrderID, MIN(po.CreateDate) CreateDate 
	From ServiceRequest SR (NOLOCK)
	Join PurchaseOrder po (NOLOCK) on po.ServiceRequestID = SR.ID
	Group By sr.ID
	) FirstPO on FirstPO.ServiceRequestID = SR.ID
Left Outer Join (
	Select sr.ID ServiceRequestID, max(el.CreateDate) SubmitForDispatchDate, max(FirstVendorSelection.CreateDate) FirstVendorSelectionDate
	From ServiceRequest SR (NOLOCK)
	Join EventLogLink ell (NOLOCK) on ell.EntityID = 13 and ell.RecordID = SR.ID
	Join EventLog el (NOLOCK) on el.ID = ell.EventLogID
	Join [Event] e (NOLOCK) on e.ID = el.EventID and e.Name = 'SaveFinishTab'
	Left Outer Join (
		Select sr.ID ServiceRequestID, Min(cl.CreateDate) CreateDate
		From ServiceRequest sr (NOLOCK)
		Join ContactLogLink cll (NOLOCK) on cll.EntityID = 13 and cll.RecordID = sr.ID
		Join ContactLog cl (NOLOCK) on cl.ID = cll.ContactLogID
		Join ContactCategory cc (NOLOCK) on cc.ID = cl.ContactCategoryID and cc.Name = 'VendorSelection'
		Group By sr.ID
		) FirstVendorSelection on FirstVendorSelection.ServiceRequestID = sr.ID
	where FirstVendorSelection.CreateDate > el.CreateDate
	Group By sr.ID
	) Dispatch on Dispatch.ServiceRequestID = SR.ID
Left Outer Join PurchaseOrder PO on PO.ID = FirstPO.PurchaseOrderID
Where 1=1
and Dispatch.SubmitForDispatchDate is not null
and DATEDIFF(ss, Dispatch.SubmitForDispatchDate, Dispatch.FirstVendorSelectionDate) <= 7200
GO

