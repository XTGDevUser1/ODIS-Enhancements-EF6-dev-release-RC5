USE [DMS]
GO
/****** Object:  StoredProcedure [dbo].[dms_service_request_export_prepare]    Script Date: 04/04/2013 09:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


		 
ALTER PROC [dbo].[dms_service_request_export_prepare]
AS
BEGIN

	DECLARE @AppConfig AS INT  

	SET @AppConfig = (Select ISNULL(AC.Value,330) From ApplicationConfiguration AC 
	JOIN ApplicationConfigurationType ACT on ACT.ID = AC.ApplicationConfigurationTypeID
	JOIN ApplicationConfigurationCategory ACC on ACC.ID = AC.ApplicationConfigurationCategoryID
	Where AC.Name='AgingReadyForExportMinutes'
	AND ACT.Name = 'WindowsService'
	AND ACC.Name = 'DispatchProcessingService') 

	UPDATE SR 
	SET 
		ReadyForExportDate = GETDATE(),
		ModifyDate = getdate(),
		ModifyBy = 'system'
	FROM ServiceRequest SR
	JOIN dbo.ServiceRequestStatus SRStatus
		ON SR.ServiceRequestStatusID = SRStatus.ID
	WHERE
	SRStatus.Name IN ('Cancelled', 'Complete')		
	AND SR.ReadyForExportDate IS NULL 
	AND SR.DataTransferDate IS NULL
	AND DATEADD(mi,@AppConfig,SR.CreateDate)<= GETDATE()	
	AND NOT EXISTS (
		SELECT *
		FROM PurchaseOrder PO
		JOIN PurchaseOrderStatus POStatus
			ON PO.PurchaseOrderStatusID = POStatus.ID
		WHERE PO.ServiceRequestID = SR.ID
		AND POStatus.Name IN ('Cancelled', 'Issued','Issued-Paid')
		)

		
	UPDATE PO   
	SET 
		ReadyForExportDate = GETDATE(),
		ModifyDate = getdate(),
		ModifyBy = 'system'
	FROM PurchaseOrder  PO
	JOIN PurchaseOrderStatus POStatus
		ON PO.PurchaseOrderStatusID = POStatus.ID
	WHERE 
	PO.ReadyForExportDate IS NULL
	AND PO.DataTransferDate IS NULL
	AND POStatus.Name IN ('Cancelled', 'Issued','Issued-Paid')
	AND DATEADD(mi,@AppConfig,PO.IssueDate)<= GETDATE()
	AND PO.IsActive = 1	  -- RH Added 3/16/2013 4:44 PM
	
	
	/* Force expiration of added (temp) members to 2 days (or less)  */
	/* Exception: ARS */
	--UPDATE M SET
	--	EffectiveDate = CAST(CONVERT(varchar, m.CreateDate,101) as datetime)
	--	,ExpirationDate = DATEADD(dd, 2, CAST(CONVERT(varchar, m.CreateDate,101) as datetime))
	--FROM member m 
	--JOIN program p on p.ID = m.ProgramID
	--JOIN client cl on cl.ID = p.ClientID
	--WHERE
	--m.ClientMemberKey IS NULL
	--AND p.Name <> 'Hagerty Employee'


	/* Prevent bad data entry for ARS effective and expiration dates */
	--UPDATE M SET
	--	EffectiveDate = CASE WHEN m.EffectiveDate < '1950-01-01' THEN CAST(CONVERT(varchar, m.CreateDate,101) as datetime) ELSE m.EffectiveDate END
	--	,ExpirationDate = CASE WHEN m.ExpirationDate > '2039-12-31' THEN DATEADD(yy, 5, CAST(CONVERT(varchar, m.CreateDate,101) as datetime)) ELSE m.ExpirationDate END
	--FROM member m 
	--JOIN program p on p.ID = m.ProgramID
	--JOIN client cl on cl.ID = p.ClientID
	--WHERE
	--m.ClientMemberKey IS NULL
	--AND cl.Name = 'ARS'
	--AND (m.EffectiveDate < '1950-01-01' OR m.ExpirationDate > '2039-12-31')

END
GO
