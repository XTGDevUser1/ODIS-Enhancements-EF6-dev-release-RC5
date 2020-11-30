IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vwServiceRequestInBoundCallCount]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vwServiceRequestInBoundCallCount] 
 END 
 GO  
CREATE VIEW [dbo].[vwServiceRequestInBoundCallCount]
as
Select sr.ID ServiceRequestID
	,c.ID CaseID
	,COUNT(*) InboundCallCount
	,SUM(CASE WHEN ct.Name = 'NewCall' THEN 1 ELSE 0 END) NewCallCount
	,SUM(CASE WHEN ct.Name = 'CustomerCallback' THEN 1 ELSE 0 END) CustomerCallbackCount
	,SUM(CASE WHEN ct.Name = 'VendorCallback' THEN 1 ELSE 0 END) VendorCallbackCount
	,SUM(CASE WHEN ct.Name = 'ClosedLoop' THEN 1 ELSE 0 END) ClosedLoopCallCount
From InboundCall ic
Join CallType ct on ct.ID = ic.CallTypeID
Join [Case] c on c.ID = ic.CaseID
Join ServiceRequest sr on sr.CaseID = c.ID
Group By sr.ID, c.ID
GO

