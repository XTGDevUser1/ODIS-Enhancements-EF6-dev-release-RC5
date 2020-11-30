IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_map_callHistory]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_map_callHistory]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO

--EXEC dms_map_callHistory 310804
CREATE PROC [dbo].[dms_map_callHistory](@ServiceRequestID AS INT = NULL)  
AS  
BEGIN  
SET FMTONLY  OFF
-- FOR Program Dynamci Values 
-- Sanghi 02.15.2013
;with wprogramDynamicValues AS(
SELECT PDI.Label,
	   PDIVE.Value,
	   PDIVE.RecordID AS 'ContactLogID'
	   FROM ProgramDataItem PDI
JOIN ProgramDataItemValueEntity PDIVE 
ON PDI.ID = PDIVE.ProgramDataItemID
WHERE PDIVE.Value IS NOT NULL AND PDIVE.Value != ''
AND PDIVE.EntityID = (SELECT ID FROM Entity WHERE Name = 'ContactLog')
) SELECT ContactLogID,
	    STUFF((SELECT '|' + CAST(Label AS VARCHAR(MAX))
	    FROM wprogramDynamicValues T1
	    WHERE T1.ContactLogID = T2.ContactLogID
	    FOR  XML path('')),1,1,'' ) as [Question],
	    STUFF((SELECT '|' + CAST(Value AS VARCHAR(MAX))
	    FROM wprogramDynamicValues T1
	    WHERE T1.ContactLogID = T2.ContactLogID
	    FOR  XML path('')),1,1,'' ) as [Answer] 
	    INTO #CustomProgramDynamicValues
	    FROM wprogramDynamicValues T2
	    GROUP BY ContactLogID
	   
SELECT CC.Description AS ContactCategory  
, CL.Company AS CompanyName  
, CL.PhoneNumber AS PhoneNumber  
, CL.TalkedTo AS TalkedTo  
, CL.Comments AS Comments  
, CL.CreateDate AS CreateDate  
, CL.CreateBy AS CreateBy  
, CR.Name AS Reason  
--, CA.Name ASAction -- TFS: 396
, CA.[Description] AS ASAction -- TFS: 396
, CLL.RecordID AS ServiceRequestID
, VCLL.RecordID AS VendorLocationID
, CPDV.Question
, CPDV.Answer
FROM ContactLog CL WITH (NOLOCK)
JOIN ContactLogLink CLL WITH (NOLOCK) ON CLL.ContactLogID = CL.ID
LEFT OUTER JOIN ContactLogLink VCLL WITH (NOLOCK) ON VCLL.ContactLogID = CL.ID AND   VCLL.EntityID=((Select ID From Entity Where Name ='VendorLocation')  ) 
JOIN ContactCategory CC WITH (NOLOCK) ON CC.ID = CL.ContactCategoryID  
JOIN ContactLogReason CLR WITH (NOLOCK) ON CLR.ContactLogID = CL.ID  
JOIN ContactReason CR WITH (NOLOCK) ON CR.ID = CLR.ContactReasonID  
JOIN ContactLogAction CLA WITH (NOLOCK) on CLA.ContactLogID = CL.ID  
JOIN ContactAction CA WITH (NOLOCK) on CA.ID = CLA.ContactActionID  
LEFT JOIN #CustomProgramDynamicValues CPDV ON CPDV.ContactLogID = CL.ID
WHERE  
CLL.RecordID = @ServiceRequestID AND CLL.EntityID =(Select ID From Entity Where Name ='ServiceRequest')  
AND CC.ID =(Select ID From ContactCategory Where Name ='ServiceLocationSelection')  
ORDER BY  
CL.CreateDate DESC  

DROP TABLE #CustomProgramDynamicValues
END

