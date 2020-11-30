IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_BillingAgentTime]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_BillingAgentTime] 
 END 
 GO 
--Views
CREATE view [dbo].[vw_BillingAgentTime]  

as  

  

 select srat.ProgramID  

   ,srat.ServiceRequestID

   ,srat.UserName

   ,srat.BeginDate CreateDate

   ,srat.EventSeconds

   --,srat.EventSeconds/60.0

   --,CEILING(srat.EventSeconds/60.0) EventMinutes

   ,CONVERT(int,ROUND(srat.EventSeconds/60.0,0)) EventMinutes

   ,srat.IsInboundCall

   ,tt.Name TimeType

   ,srat.IsBeginMatchedToEnd

   ,srat.IssuedPOCount

   ,srat.DispatchISPCallCount

   ,srat.ServiceFacilityCallCount

   ,srat.AccountingInvoiceBatchID

        

   ,(select ID from dbo.Entity with (nolock) where Name = 'ServiceRequestAgentTime') as EntityID  

   ,CONVERT(int,srat.ID) as  EntityKey  

  

from ServiceRequestAgentTime srat with (nolock)  

Join TimeType tt on tt.ID = srat.TimeTypeID

Where srat.IsBeginMatchedToEnd = 1
GO

