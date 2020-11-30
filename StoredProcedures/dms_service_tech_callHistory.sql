IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_service_tech_callHistory]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_service_tech_callHistory]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO

--EXEC [dms_service_tech_callHistory] 400305
--EXEC [dms_service_tech_callHistory] 400305
CREATE PROC [dbo].[dms_service_tech_callHistory](@ServiceRequestID AS INT = NULL)  
AS  
BEGIN  
SET FMTONLY  OFF

;with wprogramDynamicValues AS(
SELECT PDI.Label,
	   PDIVE.Value,
	   PDIVE.RecordID AS 'ContactLogID'
	   FROM ProgramDataItem PDI WITH (NOLOCK)
JOIN ProgramDataItemValueEntity PDIVE WITH (NOLOCK) ON PDI.ID = PDIVE.ProgramDataItemID
JOIN	ContactLog CL WITH (NOLOCK) ON CL.ID = PDIVE.RecordID
JOIN	ContactLogLink  CLL WITH (NOLOCK) ON CLL.ContactLogID = CL.ID

WHERE PDIVE.Value IS NOT NULL AND PDIVE.Value != ''
AND PDIVE.EntityID = (SELECT ID FROM Entity WHERE Name = 'ContactLog')
AND cll.RecordID = @ServiceRequestID AND cll.EntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
) 
SELECT ContactLogID,
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

SELECT	CC.[Description] AS ContactCategory  
		, CL.Company AS CompanyName  
		, CL.PhoneNumber AS PhoneNumber  
		, CL.TalkedTo AS TalkedTo
		,  cl.CreateDate
		, cl.CreateBy
		, cr.Name AS ContactReason
		, ca.Name AS ContactAction
		, ISNULL(CPDV.Question,'') AS Question
		, ISNULL(CPDV.Answer,'') AS Answer
		, cl.Comments		
FROM	ContactLog cl (NOLOCK)
JOIN	ContactCategory cc (NOLOCK) ON cc.ID = cl.ContactCategoryID
JOIN	ContactLogLink cll (NOLOCK) ON cll.ContactLogID = cl.ID 
LEFT JOIN	ContactLogReason clr (NOLOCK) ON clr.ContactLogID = cl.ID 
LEFT JOIN	ContactReason cr (NOLOCK) ON cr.ID = clr.ContactReasonID
LEFT JOIN	ContactLogAction cla (NOLOCK) ON cla.ContactLogID = cl.ID 
LEFT JOIN	ContactAction ca (NOLOCK) ON ca.ID = cla.ContactActionID
LEFT JOIN	#CustomProgramDynamicValues CPDV ON CPDV.ContactLogID = CL.ID
WHERE	cll.RecordID = @ServiceRequestID AND cll.EntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
AND		cc.Name IN ('ServiceLocationSelection','ContactServiceLocation')
ORDER BY cl.CreateDate DESC

DROP TABLE #CustomProgramDynamicValues
END
GO

