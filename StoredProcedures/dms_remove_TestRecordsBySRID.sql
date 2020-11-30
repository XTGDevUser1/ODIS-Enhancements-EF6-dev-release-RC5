IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_remove_TestRecordsBySRID]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_remove_TestRecordsBySRID] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_remove_TestRecordsBySRID] 899
 CREATE PROCEDURE [dbo].[dms_remove_TestRecordsBySRID]( 
  @serviceRequestID INT = NULL
 ) 
 AS 
 BEGIN 
 SET NOCOUNT ON
 
  delete dbo.PurchaseOrderDetail where PurchaseOrderID in (select ID from PurchaseOrder where ServiceRequestID=@serviceRequestID);
  delete dbo.Comment where EntityID=11 and RecordID in(select ID from PurchaseOrder where ServiceRequestID=@serviceRequestID)
  delete dbo.PurchaseOrder where ServiceRequestID=@serviceRequestID;
  delete dbo.Comment where EntityID=20 and RecordID in(Select ID FROM dbo.EmergencyAssistance where CaseID in 
  (select CaseID from ServiceRequest where ID=@serviceRequestID))
   delete dbo.InboundCall where CaseID in (select CaseID from ServiceRequest where ID=@serviceRequestID)
  delete from EmergencyAssistance where ID in (SELECT  ea.ID FROM EmergencyAssistance ea
 Inner join InboundCall ic on ic.ID = ea.InboundCallID
 Inner join ServiceRequest s on s.CaseID=ic.CaseID
 WHERE s.ID=@serviceRequestID)
 
  delete dbo.CasePhoneLocation where CaseID in (select CaseID from ServiceRequest where ID=@serviceRequestID)
  delete dbo.[Case] where ID =(select CaseID from ServiceRequest where ID=@serviceRequestID)
  delete dbo.ServiceRequestDetail where ServiceRequestID=@serviceRequestID
  delete dbo.ServiceRequestVehicleDiagnosticCode where ServiceRequestID=@serviceRequestID
  delete dbo.ServiceRequest WHERE ID =@serviceRequestID
  
--  SELECT * FROM dbo.CommunicationLog
--SELECT * FROM dbo.CommunicationQueue
--SELECT * FROM dbo.ContactLogLink
--SELECT * FROM dbo.EventLogLink


 END 
	 
	