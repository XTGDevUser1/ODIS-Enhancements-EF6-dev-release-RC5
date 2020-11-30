			 IF EXISTS (SELECT * FROM dbo.sysobjects 
			 WHERE id = object_id(N'[dbo].[dms_service_request_closedloop_status_update]')   		AND type in (N'P', N'PC')) 
			 BEGIN
			 DROP PROCEDURE [dbo].[dms_service_request_closedloop_status_update]
			 END 
			 GO  
			 SET ANSI_NULLS ON 
			 GO 
			 SET QUOTED_IDENTIFIER ON 
			 GO 
			
			CREATE PROC [dbo].[dms_service_request_closedloop_status_update]
			AS
			BEGIN
			
			DECLARE @AppConfig AS INT  
	   
		   SET @AppConfig = (Select ISNULL(AC.Value,60) From ApplicationConfiguration AC 
		   JOIN ApplicationConfigurationType ACT on ACT.ID = AC.ApplicationConfigurationTypeID
		   JOIN ApplicationConfigurationCategory ACC on ACC.ID = AC.ApplicationConfigurationCategoryID
		   Where AC.Name='AgingClosedLoopMinutes'
		   AND ACT.Name = 'WindowsService'
		   AND ACC.Name = 'DispatchProcessingService')
		   
			;with wResult AS
			(
			SELECT 
			SR.ID AS 'ServiceRequestID', 
			PO.ID AS 'PurchaseOrderID',
			SR.ClosedLoopStatusID,
			SR.ServiceRequestStatusID,
			DATEADD(mi,@AppConfig,po.ETADate) AS ETADateAdded60, 
			PO.ETADate
		    FROM ServiceRequest SR
		    Join PurchaseOrder PO on PO.ServiceRequestID = SR.ID
		    Join PurchaseOrderStatus POS on PO.PurchaseOrderStatusID = POS.ID
			JOIN(
				SELECT SR.ID ServiceRequestID,MAX(PO.ETADate) ETADate
				FROM ServiceRequest SR
				Join PurchaseOrder PO on PO.ServiceRequestID = SR.ID
				GROUP BY SR.ID
				) LastPo on LastPO.ServiceRequestID = sr.ID AND LastPO.ETADate = po.ETADate
			where pos.Name Not In('Pending') AND PO.IsActive = 1
			AND (
			( 
			sr.ServiceRequestStatusID in 
			(select ID from ServiceRequestStatus where Name in ('Dispatched','Complete'))
			AND sr.ClosedLoopStatusID IN
			(select ID from ClosedLoopStatus where Name in('Sent','ServiceNotArrived','Unknown','Pending','NoAnswer'))
			)
			OR
			( 
			sr.ServiceRequestStatusID in 
			(select ID from ServiceRequestStatus where Name in ('Dispatched'))
			AND (sr.ClosedLoopStatusID IN
			(select ID from ClosedLoopStatus where Name in('ServiceArrived'))
			OR sr.ClosedLoopStatusID is null)
			)
			)
			AND dateadd(mi,@AppConfig,LastPO.ETADate)<=getdate()
			)
			UPDATE wResult 
			SET wResult.ClosedLoopStatusID = (SELECT ID From ClosedLoopStatus Where Name = 'ServiceArrived'),
				wResult.ServiceRequestStatusID = (SELECT ID From ServiceRequestStatus Where Name = 'Complete')
			
			END
