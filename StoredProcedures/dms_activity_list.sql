/*******************
* Operator Enums 
*  Conditions Enum :
* -1 - No filter
*  0 - Null
*  1 - Not Null
*  2 - Equals
*  3 - NotEquals
*  ---- for strings ---
*  4 - StartsWith
*  5 - EndsWith
*  6 - Contains
*  ---- for int, decimal, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*  11 - IN a list	
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_activity_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_activity_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --[dms_activity_list] @serviceRequestID = 1606
-- EXEC [dbo].[dms_activity_list] @serviceRequestID = 1414,@whereClauseXML = '<ROW><Filter TypeOperator="11" TypeValue="Event Log,Contact Log"></Filter></ROW>'   
 CREATE PROCEDURE [dbo].[dms_activity_list](
	 @serviceRequestID INT = NULL -- TODO - Let's use this in the where clause. 
	 ,@whereClauseXML NVARCHAR(4000) = NULL 
	 ,@startInd Int = 1 
	 ,@endInd BIGINT = 5000 
	 ,@pageSize int = 10  
	 ,@sortColumn nvarchar(100)  = '' 
	 ,@sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
 
 -- KB : For Activity, since there is no option to change the page size at the UI, we are setting the pagesize to 50 here in the sp.
 -- Eventually, this value would come from the application
 SET @endInd = 50
 SET @pageSize = 50
 
 
SET FMTONLY OFF
SET NOCOUNT ON

--CREATE TABLE #tmpFinalResults 
DECLARE @tmpFinalResults TABLE
( 
 Type nvarchar(50)  NULL ,
 Name nvarchar(50)  NULL ,
 ID int  NULL ,
 Description nvarchar(MAX)  NULL ,
 TypeDescription nvarchar(MAX)  NULL ,
 Company nvarchar(MAX)  NULL ,
 TalkedTo nvarchar(100)  NULL ,
 PhoneNumber nvarchar(100)  NULL ,
 CreateBy nvarchar(50)  NULL ,
 CreateDate datetime  NULL ,
 RoleName nvarchar(100)  NULL ,
 OrganizationName nvarchar(100)  NULL,
 Comments nvarchar(max) NULL,
 ContactReason nvarchar(max) NULL,
 ContactAction nvarchar(max) NULL ,
 ContactMethod NVARCHAR(255) NULL,
 ContactMethodClassName NVARCHAR(255) NULL, 
 QuestionAnswer nvarchar(max) NULL,
 EventName NVARCHAR(255) NULL,
 Data NVARCHAR(MAX) NULL
)

DECLARE @tmpFinalResultsUpdated TABLE
( 
 Type nvarchar(50)  NULL ,
 Name nvarchar(50)  NULL ,
 ID int  NULL ,
 Description nvarchar(MAX)  NULL ,
 TypeDescription nvarchar(MAX)  NULL ,
 Company nvarchar(MAX)  NULL ,
 TalkedTo nvarchar(100)  NULL ,
 PhoneNumber nvarchar(100)  NULL ,
 CreateBy nvarchar(50)  NULL ,
 CreateDate datetime  NULL ,
 RoleName nvarchar(100)  NULL ,
 OrganizationName nvarchar(100)  NULL,
 Comments nvarchar(max) NULL,
 ContactReason nvarchar(max) NULL,
 ContactAction nvarchar(max) NULL ,
 ContactMethod NVARCHAR(255) NULL,
 ContactMethodClassName NVARCHAR(255) NULL, 
 QuestionAnswer nvarchar(max) NULL
)

--CREATE TABLE #FinalResults ( 
DECLARE @FinalResults TABLE (
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),
 Type nvarchar(50)  NULL ,
 Name nvarchar(50)  NULL ,
 ID int  NULL ,
 Description nvarchar(MAX)  NULL ,
 TypeDescription nvarchar(MAX)  NULL ,
 Company nvarchar(MAX)  NULL ,
 TalkedTo nvarchar(100)  NULL ,
 PhoneNumber nvarchar(100)  NULL ,
 CreateBy nvarchar(50)  NULL ,
 CreateDate datetime  NULL ,
 RoleName nvarchar(100)  NULL ,
 OrganizationName nvarchar(100)  NULL,
 Comments nvarchar(max) NULL,
 ContactReason nvarchar(max) NULL,
 ContactAction nvarchar(max) NULL,
 ContactMethod NVARCHAR(255) NULL,
 ContactMethodClassName NVARCHAR(255) NULL, 
 QuestionAnswer nvarchar(max) NULL
) 

DECLARE @InboundCallResult AS TABLE(ID INT)
DECLARE @EmergencyAssistanceResult AS TABLE(ID INT)
DECLARE @PurchaseOrderResult AS TABLE(ID INT)

DECLARE @idoc int

DECLARE @tmpForWhereClause TABLE
(
TypeOperator INT NOT NULL,
TypeValue nvarchar(50) NULL
)

DECLARE @eventLogCount BIGINT
DECLARE @contactLogCount BIGINT
DECLARE @commentCount BIGINT
SET @eventLogCount = 0
SET @contactLogCount = 0
SET @commentCount = 0
DECLARE @Case AS INT  
SET @Case = (Select CaseID From ServiceRequest Where ID = @ServiceRequestID)  

DECLARE @CancelPOEventID INT
DECLARE @PurchaseOrderEntityID INT
DECLARE @InboundCallEntityID INT
DECLARE @EmergencyAssistanceEntityID INT
DECLARE @CaseEntityID INT
DECLARE @ServiceRequestEntityID INT
DECLARE @ContactLogEntityID INT

SELECT @CancelPOEventID = ID FROM dbo.Event(NOLOCK) WHERE Name = 'CancelPO'
SELECT @PurchaseOrderEntityID  = ID FROM dbo.Entity(NOLOCK) WHERE Name = 'PurchaseOrder'
SELECT @InboundCallEntityID = ID from dbo.Entity(NOLOCK) WHERE Name = 'InboundCall'
SELECT @EmergencyAssistanceEntityID=ID from dbo.Entity(NOLOCK) WHERE Name = 'EmergencyAssistance'
SELECT @CaseEntityID=ID from dbo.Entity(NOLOCK) WHERE Name = 'Case'
SELECT @ServiceRequestEntityID =ID from dbo.Entity(NOLOCK) WHERE Name = 'ServiceRequest'
SELECT @ContactLogEntityID = ID FROM dbo.Entity(NOLOCK) WHERE Name = 'ContactLog'

INSERT INTO @InboundCallResult Select ID From InboundCall(NOLOCK) Where CaseID = @Case
INSERT INTO @EmergencyAssistanceResult Select ID From EmergencyAssistance(NOLOCK) Where CaseID = @Case
INSERT INTO @PurchaseOrderResult Select ID From PurchaseOrder(NOLOCK) Where ServiceRequestID = @ServiceRequestID

IF @whereClauseXML IS NULL 
BEGIN
 SET @whereClauseXML = '<ROW><Filter 
TypeOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML


INSERT INTO @tmpForWhereClause
SELECT  
 ISNULL(TypeOperator,-1),
 TypeValue 
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (
TypeOperator INT,
TypeValue nvarchar(50) 
 ) 
 
/* BEGIN --- Get Program Dynamic Values related to SR ContactLog */ 
/* --------- Only get values related to the current SR */
 ;with wprogramDynamicValues AS(
-- @InboundCall
SELECT PDI.Label + ' : ' + PDIVE.Value AS 'QuestionAnswer', PDIVE.RecordID AS 'ContactLogID'
FROM ContactLog(NOLOCK) cl
JOIN ContactLogLink(NOLOCK) cll on cl.id = cll.ContactLogID 
JOIN ProgramDataItemValueEntity(NOLOCK) PDIVE ON PDIVE.EntityID = @ContactLogEntityID AND PDIVE.RecordID = cl.ID
JOIN ProgramDataItem(NOLOCK) PDI ON PDI.ID = PDIVE.ProgramDataItemID
WHERE 
      (
         (CLL.EntityID = @InboundCallEntityID AND CLL.RecordID IN (SELECT ID From @InboundCallResult))      
      )
AND PDIVE.Value IS NOT NULL 
AND PDIVE.Value != ''

UNION ALL
-- @EmergencyAssistance
SELECT PDI.Label + ' : ' + PDIVE.Value AS 'QuestionAnswer', PDIVE.RecordID AS 'ContactLogID'
FROM ContactLog(NOLOCK) cl
JOIN ContactLogLink(NOLOCK) cll on cl.id = cll.ContactLogID 
JOIN ProgramDataItemValueEntity(NOLOCK) PDIVE ON PDIVE.EntityID = @ContactLogEntityID AND PDIVE.RecordID = cl.ID
JOIN ProgramDataItem(NOLOCK) PDI ON PDI.ID = PDIVE.ProgramDataItemID
WHERE 
      (         
       (CLL.EntityID = @EmergencyAssistanceEntityID AND CLL.RecordID IN (SELECT ID From @EmergencyAssistanceResult))      
      )
AND PDIVE.Value IS NOT NULL 
AND PDIVE.Value != ''

UNION ALL
-- @ CASE
SELECT PDI.Label + ' : ' + PDIVE.Value AS 'QuestionAnswer', PDIVE.RecordID AS 'ContactLogID'
FROM ContactLog(NOLOCK) cl
JOIN ContactLogLink(NOLOCK) cll on cl.id = cll.ContactLogID 
JOIN ProgramDataItemValueEntity(NOLOCK) PDIVE ON PDIVE.EntityID = @ContactLogEntityID AND PDIVE.RecordID = cl.ID
JOIN ProgramDataItem(NOLOCK) PDI ON PDI.ID = PDIVE.ProgramDataItemID
WHERE 
      (  
		(CLL.EntityID = @CaseEntityID AND CLL.RecordID = @Case)      
      )
AND PDIVE.Value IS NOT NULL 
AND PDIVE.Value != ''

UNION ALL
-- @ SR
SELECT PDI.Label + ' : ' + PDIVE.Value AS 'QuestionAnswer', PDIVE.RecordID AS 'ContactLogID'
FROM ContactLog(NOLOCK) cl
JOIN ContactLogLink(NOLOCK) cll on cl.id = cll.ContactLogID 
JOIN ProgramDataItemValueEntity(NOLOCK) PDIVE ON PDIVE.EntityID = @ContactLogEntityID AND PDIVE.RecordID = cl.ID
JOIN ProgramDataItem(NOLOCK) PDI ON PDI.ID = PDIVE.ProgramDataItemID
WHERE 
      (  
		(CLL.EntityID = @ServiceRequestEntityID AND CLL.RecordID = @ServiceRequestID)      
      )
AND PDIVE.Value IS NOT NULL 
AND PDIVE.Value != ''

UNION ALL
-- @ PO
SELECT PDI.Label + ' : ' + PDIVE.Value AS 'QuestionAnswer', PDIVE.RecordID AS 'ContactLogID'
FROM ContactLog(NOLOCK) cl
JOIN ContactLogLink(NOLOCK) cll on cl.id = cll.ContactLogID 
JOIN ProgramDataItemValueEntity(NOLOCK) PDIVE ON PDIVE.EntityID = @ContactLogEntityID AND PDIVE.RecordID = cl.ID
JOIN ProgramDataItem(NOLOCK) PDI ON PDI.ID = PDIVE.ProgramDataItemID
WHERE 
      (
		(CLL.EntityID = @PurchaseOrderEntityID AND CLL.RecordID IN (SELECT ID FROM @PurchaseOrderResult))
      )
AND PDIVE.Value IS NOT NULL 
AND PDIVE.Value != ''
)

SELECT ContactLogID,
STUFF((SELECT ' ' + CAST(QuestionAnswer + '<br/>'AS NVARCHAR(MAX))
FROM wprogramDynamicValues T1
WHERE T1.ContactLogID = T2.ContactLogID
FOR  XML path('')),1,1,'' ) as [QuestionAnswer]
INTO #CustomProgramDynamicValues
FROM wprogramDynamicValues T2
GROUP BY ContactLogID
/* END --- Get Program Dynamic Values related to SR ContactLog */ 


 
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @tmpFinalResults 
-- Events
-- Inbound call
SELECT  'Event Log' AS Type,
EN.Name,
EL.ID, 
EL.Description, 
ET.Description as TypeDescription, 
Null as Company,
Null as Talkedto,
Null as Phonenumber,
EL.CreateBy, 
EL.CreateDate, 
--r.RoleName, 
NULL as RoleName,
--O.Name as OrganizationName,
NULL as OrganizationName,
NULL AS Comments,
NULL AS ContactReason,
NULL AS [ContactAction],
NULL AS [ContactMethod],
NULL AS [ContactMethodClassName],
NULL AS [QuestionAnswer],
E.Name AS EventName,
EL.Data
FROM EventLogLink ELL WITH (NOLOCK)
JOIN EventLog EL WITH (NOLOCK) ON ELL.EventLogID = EL.ID
JOIN [Event](NOLOCK) E on E.ID = EL.EventID
JOIN EventType(NOLOCK) ET on ET.ID = E.EventTypeID
JOIN Entity(NOLOCK) EN ON EN.ID = ELL.EntityID
WHERE	E.IsShownOnScreen = 1 AND E.IsActive = 1 
AND		ELL.RecordID IN (SELECT ID FROM @InboundCallResult) AND ELL.EntityID = @InboundCallEntityID


-- Emergency
INSERT INTO @tmpFinalResults 
SELECT  'Event Log' AS Type,
EN.Name,
EL.ID, 
EL.Description, 
ET.Description as TypeDescription, 
Null as Company,
Null as Talkedto,
Null as Phonenumber,
EL.CreateBy, 
EL.CreateDate, 
--r.RoleName, 
NULL as RoleName,
--O.Name as OrganizationName,
NULL as OrganizationName,
NULL AS Comments,
NULL AS ContactReason,
NULL AS [ContactAction],
NULL AS [ContactMethod],
NULL AS [ContactMethodClassName],
NULL AS [QuestionAnswer],
E.Name AS EventName,
EL.Data
FROM EventLogLink ELL WITH (NOLOCK)
JOIN EventLog EL WITH (NOLOCK) ON ELL.EventLogID = EL.ID
JOIN [Event](NOLOCK) E on E.ID = EL.EventID
JOIN EventType(NOLOCK) ET on ET.ID = E.EventTypeID
JOIN Entity(NOLOCK) EN ON EN.ID = ELL.EntityID
WHERE	E.IsShownOnScreen = 1 AND E.IsActive = 1 
AND		ELL.RecordID IN (SELECT ID FROM @EmergencyAssistanceResult) AND ELL.EntityID = @EmergencyAssistanceEntityID
AND NOT EXISTS (
	SELECT * FROM @tmpFinalResults tmp Where tmp.[Type] = 'Event Log' AND tmp.ID = EL.ID)

-- Service Request
INSERT INTO @tmpFinalResults 
SELECT  'Event Log' AS Type,
EN.Name,
EL.ID, 
EL.Description, 
ET.Description as TypeDescription, 
Null as Company,
Null as Talkedto,
Null as Phonenumber,
EL.CreateBy, 
EL.CreateDate, 
--r.RoleName, 
NULL as RoleName,
--O.Name as OrganizationName,
NULL as OrganizationName,
NULL AS Comments,
NULL AS ContactReason,
NULL AS [ContactAction],
NULL AS [ContactMethod],
NULL AS [ContactMethodClassName],
NULL AS [QuestionAnswer],
E.Name AS EventName,
EL.Data
FROM EventLogLink ELL WITH (NOLOCK)
JOIN EventLog EL WITH (NOLOCK) ON ELL.EventLogID = EL.ID
JOIN [Event](NOLOCK) E on E.ID = EL.EventID
JOIN EventType(NOLOCK) ET on ET.ID = E.EventTypeID
JOIN Entity(NOLOCK) EN ON EN.ID = ELL.EntityID
WHERE	E.IsShownOnScreen = 1 AND E.IsActive = 1 
AND		ELL.RecordID = @serviceRequestID AND ELL.EntityID = @serviceRequestEntityID
AND NOT EXISTS (
	SELECT * FROM @tmpFinalResults tmp Where tmp.[Type] = 'Event Log' AND tmp.ID = EL.ID)

-- CASE
INSERT INTO @tmpFinalResults 
SELECT  'Event Log' AS Type,
EN.Name,
EL.ID, 
EL.Description, 
ET.Description as TypeDescription, 
Null as Company,
Null as Talkedto,
Null as Phonenumber,
EL.CreateBy, 
EL.CreateDate, 
--r.RoleName, 
NULL as RoleName,
--O.Name as OrganizationName,
NULL as OrganizationName,
NULL AS Comments,
NULL AS ContactReason,
NULL AS [ContactAction],
NULL AS [ContactMethod],
NULL AS [ContactMethodClassName],
NULL AS [QuestionAnswer],
E.Name AS EventName,
EL.Data
FROM EventLogLink ELL WITH (NOLOCK)
JOIN EventLog EL WITH (NOLOCK) ON ELL.EventLogID = EL.ID
JOIN [Event](NOLOCK) E on E.ID = EL.EventID
JOIN EventType(NOLOCK) ET on ET.ID = E.EventTypeID
JOIN Entity(NOLOCK) EN ON EN.ID = ELL.EntityID
WHERE	E.IsShownOnScreen = 1 AND E.IsActive = 1 
AND		ELL.RecordID = @Case AND ELL.EntityID = @CaseEntityID
AND NOT EXISTS (
	SELECT * FROM @tmpFinalResults tmp Where tmp.[Type] = 'Event Log' AND tmp.ID = EL.ID)

-- PO
INSERT INTO @tmpFinalResults 
SELECT  'Event Log' AS Type,
EN.Name,
EL.ID, 
EL.Description, 
ET.Description as TypeDescription, 
Null as Company,
Null as Talkedto,
Null as Phonenumber,
EL.CreateBy, 
EL.CreateDate, 
--r.RoleName, 
NULL as RoleName,
--O.Name as OrganizationName,
NULL as OrganizationName,
CASE WHEN EL.EventID = @CancelPOEventID THEN PO.CancellationComment ELSE NULL END AS Comments,
NULL AS ContactReason,
NULL AS [ContactAction],
NULL AS [ContactMethod],
NULL AS [ContactMethodClassName],
NULL AS [QuestionAnswer],
E.Name AS EventName,
EL.Data
FROM EventLogLink ELL WITH (NOLOCK)
JOIN EventLog EL WITH (NOLOCK) ON ELL.EventLogID = EL.ID
JOIN [Event](NOLOCK) E on E.ID = EL.EventID
JOIN EventType(NOLOCK) ET on ET.ID = E.EventTypeID
JOIN Entity(NOLOCK) EN ON EN.ID = ELL.EntityID
LEFT JOIN PurchaseOrder PO ON PO.ID = ELL.RecordID AND ELL.EntityID = @PurchaseOrderEntityID
WHERE	E.IsShownOnScreen = 1 AND E.IsActive = 1 
AND		ELL.RecordID IN (SELECT ID FROM @PurchaseOrderResult) AND ELL.EntityID = @PurchaseOrderEntityID
AND NOT EXISTS (
	SELECT * FROM @tmpFinalResults tmp Where tmp.[Type] = 'Event Log' AND tmp.ID = EL.ID)

-- Contact Logs
-- InboundCall, Emergency, SR, CASE and PO
INSERT INTO @tmpFinalResults 
SELECT  'Contact Log' as Type, 
 EN.Name, 
 CL.ID, 
 CL.Description, 
 CC.Description AS TypeDescription, 
 CL.Company AS Company, 
 CL.TalkedTo, 
 CL.PhoneNumber, 
 CL.CreateBy, 
 CL.CreateDate, 
--r.RoleName, 
 NULL as RoleName,
--O.Name as OrganizationName, 
 NULL as OrganizationName,
 CL.Comments,  
 CR.Description AS ContactReason,
 --CA.Description AS [ContactAction]
  ContactAction = substring((SELECT ( ', ' + CA2.Description )
                           FROM ContactAction CA2
                           JOIN ContactLogAction CLA2 ON CLA2.ContactActionID = CA2.ID
                           WHERE CLA2.ContactLogID = CL.ID
                           AND CA2.IsShownOnScreen = 1
                           AND CA2.IsActive = 1
                           ORDER BY 
                              CLA2.CreateDate                  
                           FOR XML PATH( '' )
                          ), 3, 1000 ),
	CM.Name AS ContactMethod,
	CM.ClassName AS ContactMethodClassName,
    CPDV.QuestionAnswer,
    NULL,
	CL.Data   
 FROM ContactLogLink (NOLOCK) CLL
 JOIN ContactLog(NOLOCK) CL ON CLL.ContactLogID = CL.ID
 JOIN Entity(NOLOCK) EN ON EN.ID = CLL.EntityID
 JOIN ContactType(NOLOCK) CT ON CT.ID = CL.ContactTypeID
 JOIN ContactCategory(NOLOCK) CC ON CC.ID = CL.ContactCategoryID
 JOIN ContactMethod(NOLOCK) CM ON CM.ID= CL.ContactMethodID 
 JOIN ContactLogReason(NOLOCK) CLR ON CLR.ContactLogID = CL.ID
 JOIN ContactReason(NOLOCK) CR ON CR.ID = CLR.ContactReasonID 
 LEFT JOIN #CustomProgramDynamicValues CPDV ON CPDV.ContactLogID = CL.ID 
 WHERE 
 (CLL.EntityID = @InboundCallEntityID AND CLL.RecordID IN (Select ID From @InboundCallResult))
AND NOT EXISTS (
	SELECT * FROM @tmpFinalResults tmp Where tmp.[Type] = 'Contact Log' AND tmp.ID = CL.ID)
 
-- Case
INSERT INTO @tmpFinalResults 
 SELECT  'Contact Log' as Type, 
 EN.Name, 
 CL.ID, 
 CL.Description, 
 CC.Description AS TypeDescription, 
 CL.Company AS Company, 
 CL.TalkedTo, 
 CL.PhoneNumber, 
 CL.CreateBy, 
 CL.CreateDate, 
--r.RoleName, 
 NULL as RoleName,
--O.Name as OrganizationName, 
 NULL as OrganizationName,
 CL.Comments,  
 CR.Description AS ContactReason,
 --CA.Description AS [ContactAction]
  ContactAction = substring((SELECT ( ', ' + CA2.Description )
                           FROM ContactAction CA2
                           JOIN ContactLogAction CLA2 ON CLA2.ContactActionID = CA2.ID
                           WHERE CLA2.ContactLogID = CL.ID
                           AND CA2.IsShownOnScreen = 1
                           AND CA2.IsActive = 1
                           ORDER BY 
                              CLA2.CreateDate                  
                           FOR XML PATH( '' )
                          ), 3, 1000 ),
    CM.Name AS ContactMethod,
	CM.ClassName AS ContactMethodClassName,
	CPDV.QuestionAnswer,
    NULL     ,
	CL.Data                
 FROM ContactLogLink (NOLOCK) CLL
 JOIN ContactLog(NOLOCK) CL ON CLL.ContactLogID = CL.ID
 JOIN Entity(NOLOCK) EN ON EN.ID = CLL.EntityID
 JOIN ContactType(NOLOCK) CT ON CT.ID = CL.ContactTypeID
 JOIN ContactCategory(NOLOCK) CC ON CC.ID = CL.ContactCategoryID
 JOIN ContactMethod(NOLOCK) CM ON CM.ID= CL.ContactMethodID 
 JOIN ContactLogReason(NOLOCK) CLR ON CLR.ContactLogID = CL.ID
 JOIN ContactReason(NOLOCK) CR ON CR.ID = CLR.ContactReasonID 
 LEFT JOIN #CustomProgramDynamicValues CPDV ON CPDV.ContactLogID = CL.ID 
 WHERE 
 (CLL.EntityID = @CaseEntityID AND CLL.RecordID =@Case)
AND NOT EXISTS (
	SELECT * FROM @tmpFinalResults tmp Where tmp.[Type] = 'Contact Log' AND tmp.ID = CL.ID)
 
-- SR
INSERT INTO @tmpFinalResults 
 SELECT  'Contact Log' as Type, 
 EN.Name, 
 CL.ID, 
 CL.Description, 
 CC.Description AS TypeDescription, 
 CL.Company AS Company, 
 CL.TalkedTo, 
 CL.PhoneNumber, 
 CL.CreateBy, 
 CL.CreateDate, 
--r.RoleName, 
 NULL as RoleName,
--O.Name as OrganizationName, 
 NULL as OrganizationName,
 CL.Comments,  
 CR.Description AS ContactReason,
 --CA.Description AS [ContactAction]
  ContactAction = substring((SELECT ( ', ' + CA2.Description )
                           FROM ContactAction CA2
                           JOIN ContactLogAction CLA2 ON CLA2.ContactActionID = CA2.ID
                           WHERE CLA2.ContactLogID = CL.ID
                           AND CA2.IsShownOnScreen = 1
                           AND CA2.IsActive = 1
                           ORDER BY 
                              CLA2.CreateDate                  
                           FOR XML PATH( '' )
                          ), 3, 1000 ),
    CM.Name AS ContactMethod,
	CM.ClassName AS ContactMethodClassName,
	CPDV.QuestionAnswer,
    NULL,
	CL.Data                     
 FROM ContactLogLink (NOLOCK) CLL
 JOIN ContactLog(NOLOCK) CL ON CLL.ContactLogID = CL.ID
 JOIN Entity(NOLOCK) EN ON EN.ID = CLL.EntityID
 JOIN ContactType(NOLOCK) CT ON CT.ID = CL.ContactTypeID
 JOIN ContactCategory(NOLOCK) CC ON CC.ID = CL.ContactCategoryID
 JOIN ContactMethod(NOLOCK) CM ON CM.ID= CL.ContactMethodID 
 JOIN ContactLogReason(NOLOCK) CLR ON CLR.ContactLogID = CL.ID
 JOIN ContactReason(NOLOCK) CR ON CR.ID = CLR.ContactReasonID 
 LEFT JOIN #CustomProgramDynamicValues CPDV ON CPDV.ContactLogID = CL.ID 
 WHERE 
 (CLL.EntityID = @ServiceRequestEntityID AND CLL.RecordID = @serviceRequestID)
AND NOT EXISTS (
	SELECT * FROM @tmpFinalResults tmp Where tmp.[Type] = 'Contact Log' AND tmp.ID = CL.ID)
 
 -- Emergency Assistance
INSERT INTO @tmpFinalResults 
 SELECT  'Contact Log' as Type, 
 EN.Name, 
 CL.ID, 
 CL.Description, 
 CC.Description AS TypeDescription, 
 CL.Company AS Company, 
 CL.TalkedTo, 
 CL.PhoneNumber, 
 CL.CreateBy, 
 CL.CreateDate, 
--r.RoleName, 
 NULL as RoleName,
--O.Name as OrganizationName, 
 NULL as OrganizationName,
 CL.Comments,  
 CR.Description AS ContactReason,
 --CA.Description AS [ContactAction]
  ContactAction = substring((SELECT ( ', ' + CA2.Description )
                           FROM ContactAction CA2
                           JOIN ContactLogAction CLA2 ON CLA2.ContactActionID = CA2.ID
                           WHERE CLA2.ContactLogID = CL.ID
                           AND CA2.IsShownOnScreen = 1
                           AND CA2.IsActive = 1
                           ORDER BY 
                              CLA2.CreateDate                  
                           FOR XML PATH( '' )
                          ), 3, 1000 ),
    CM.Name AS ContactMethod,
	CM.ClassName AS ContactMethodClassName,
	CPDV.QuestionAnswer,
    NULL,
	CL.Data                     
 FROM ContactLogLink (NOLOCK) CLL
 JOIN ContactLog(NOLOCK) CL ON CLL.ContactLogID = CL.ID
 JOIN Entity(NOLOCK) EN ON EN.ID = CLL.EntityID
 JOIN ContactType(NOLOCK) CT ON CT.ID = CL.ContactTypeID
 JOIN ContactCategory(NOLOCK) CC ON CC.ID = CL.ContactCategoryID
 JOIN ContactMethod(NOLOCK) CM ON CM.ID= CL.ContactMethodID 
 JOIN ContactLogReason(NOLOCK) CLR ON CLR.ContactLogID = CL.ID
 JOIN ContactReason(NOLOCK) CR ON CR.ID = CLR.ContactReasonID 
 LEFT JOIN #CustomProgramDynamicValues CPDV ON CPDV.ContactLogID = CL.ID 
 WHERE 
 (CLL.EntityID = @EmergencyAssistanceEntityID AND CLL.RecordID IN (Select ID From @EmergencyAssistanceResult))
AND NOT EXISTS (
	SELECT * FROM @tmpFinalResults tmp Where tmp.[Type] = 'Contact Log' AND tmp.ID = CL.ID)
 
 -- PO
INSERT INTO @tmpFinalResults 
 SELECT  'Contact Log' as Type, 
 EN.Name, 
 CL.ID, 
 CL.Description, 
 CC.Description AS TypeDescription, 
 CL.Company AS Company, 
 CL.TalkedTo, 
 CL.PhoneNumber, 
 CL.CreateBy, 
 CL.CreateDate, 
--r.RoleName, 
 NULL as RoleName,
--O.Name as OrganizationName, 
 NULL as OrganizationName,
 CL.Comments,  
 CR.Description AS ContactReason,
 --CA.Description AS [ContactAction]
  ContactAction = substring((SELECT ( ', ' + CA2.Description )
                           FROM ContactAction CA2
                           JOIN ContactLogAction CLA2 ON CLA2.ContactActionID = CA2.ID
                           WHERE CLA2.ContactLogID = CL.ID
                           AND CA2.IsShownOnScreen = 1
                           AND CA2.IsActive = 1
                           ORDER BY 
                              CLA2.CreateDate                  
                           FOR XML PATH( '' )
                          ), 3, 1000 ),
    CM.Name AS ContactMethod,
	CM.ClassName AS ContactMethodClassName,
	CPDV.QuestionAnswer,
    NULL,
	CL.Data                     
 FROM ContactLogLink (NOLOCK) CLL
 JOIN ContactLog(NOLOCK) CL ON CLL.ContactLogID = CL.ID
 JOIN Entity(NOLOCK) EN ON EN.ID = CLL.EntityID
 JOIN ContactType(NOLOCK) CT ON CT.ID = CL.ContactTypeID
 JOIN ContactCategory(NOLOCK) CC ON CC.ID = CL.ContactCategoryID
 JOIN ContactMethod(NOLOCK) CM ON CM.ID= CL.ContactMethodID 
 JOIN ContactLogReason(NOLOCK) CLR ON CLR.ContactLogID = CL.ID
 JOIN ContactReason(NOLOCK) CR ON CR.ID = CLR.ContactReasonID 
 LEFT JOIN #CustomProgramDynamicValues CPDV ON CPDV.ContactLogID = CL.ID 
 WHERE 
 (CLL.EntityID = @PurchaseOrderEntityID AND CLL.RecordID IN (Select ID From @PurchaseOrderResult))
AND NOT EXISTS (
	SELECT * FROM @tmpFinalResults tmp Where tmp.[Type] = 'Contact Log' AND tmp.ID = CL.ID)
 
 -- Comments
 -- Inbound call
INSERT INTO @tmpFinalResults 
 SELECT  'Comment' as Type, 
 EN.Name, C.ID, 
 C.Description,
 CMT.Description as TypeDescription,
 Null as Company,
 Null as Talkedto,
 Null as Phonenumber,
 C.CreateBy, 
 C.CreateDate, 
--r.RoleName, 
 NULL as RoleName,
--O.Name as OrganizationName,
 NULL as OrganizationName,
 NULL AS Comments,
 NULL AS ContactReason,
 NULL AS [ContactAction],
 NULL AS [ContactMethod],
 NULL AS [ContactMethodClassName],
 NULL AS [QuestionAnswer],
 NULL,
 NULL        
 FROM Comment(NOLOCK) C
 JOIN Entity EN(NOLOCK) ON EN.ID = C.EntityID 
 LEFT JOIN CommentType(NOLOCK) CMT on CMT.ID = C.CommentTypeID   
 WHERE 
 (C.EntityID = @InboundCallEntityID AND C.RecordID IN (Select ID From @InboundCallResult))
 ORDER BY CreateDate DESC

-- Emergency Assistance
INSERT INTO @tmpFinalResults 
 SELECT  'Comment' as Type, 
 EN.Name, C.ID, 
 C.Description,
 CMT.Description as TypeDescription,
 Null as Company,
 Null as Talkedto,
 Null as Phonenumber,
 C.CreateBy, 
 C.CreateDate, 
--r.RoleName, 
 NULL as RoleName,
--O.Name as OrganizationName,
 NULL as OrganizationName,
 NULL AS Comments,
 NULL AS ContactReason,
 NULL AS [ContactAction],
 NULL AS [ContactMethod],
 NULL AS [ContactMethodClassName],
 NULL AS [QuestionAnswer],
 NULL,
 NULL        
 FROM Comment(NOLOCK) C
 JOIN Entity EN(NOLOCK) ON EN.ID = C.EntityID 
 LEFT JOIN CommentType(NOLOCK) CMT on CMT.ID = C.CommentTypeID   
 WHERE  
 (C.EntityID = @EmergencyAssistanceEntityID AND C.RecordID IN (Select ID From @EmergencyAssistanceResult)) 
 ORDER BY CreateDate DESC

 -- Case
INSERT INTO @tmpFinalResults 
 SELECT  'Comment' as Type, 
 EN.Name, C.ID, 
 C.Description,
 CMT.Description as TypeDescription,
 Null as Company,
 Null as Talkedto,
 Null as Phonenumber,
 C.CreateBy, 
 C.CreateDate, 
--r.RoleName, 
 NULL as RoleName,
--O.Name as OrganizationName,
 NULL as OrganizationName,
 NULL AS Comments,
 NULL AS ContactReason,
 NULL AS [ContactAction],
 NULL AS [ContactMethod],
 NULL AS [ContactMethodClassName],
 NULL AS [QuestionAnswer],
 NULL,
 NULL        
 FROM Comment(NOLOCK) C
 JOIN Entity EN(NOLOCK) ON EN.ID = C.EntityID 
 LEFT JOIN CommentType(NOLOCK) CMT on CMT.ID = C.CommentTypeID   
 WHERE 
	(C.EntityID = @CaseEntityID AND C.RecordID = @Case) 
 ORDER BY CreateDate DESC

 -- Service Request
INSERT INTO @tmpFinalResults 
 SELECT  'Comment' as Type, 
 EN.Name, C.ID, 
 C.Description,
 CMT.Description as TypeDescription,
 Null as Company,
 Null as Talkedto,
 Null as Phonenumber,
 C.CreateBy, 
 C.CreateDate, 
--r.RoleName, 
 NULL as RoleName,
--O.Name as OrganizationName,
 NULL as OrganizationName,
 NULL AS Comments,
 NULL AS ContactReason,
 NULL AS [ContactAction],
 NULL AS [ContactMethod],
 NULL AS [ContactMethodClassName],
 NULL AS [QuestionAnswer],
 NULL,
 NULL        
 FROM Comment(NOLOCK) C
 JOIN Entity EN(NOLOCK) ON EN.ID = C.EntityID 
 LEFT JOIN CommentType(NOLOCK) CMT on CMT.ID = C.CommentTypeID   
 WHERE 
	(C.EntityID = @ServiceRequestEntityID AND C.RecordID = @ServiceRequestID)
 ORDER BY CreateDate DESC

 -- PO
INSERT INTO @tmpFinalResults 
 SELECT  'Comment' as Type, 
 EN.Name, C.ID, 
 C.Description,
 CMT.Description as TypeDescription,
 Null as Company,
 Null as Talkedto,
 Null as Phonenumber,
 C.CreateBy, 
 C.CreateDate, 
--r.RoleName, 
 NULL as RoleName,
--O.Name as OrganizationName,
 NULL as OrganizationName,
 NULL AS Comments,
 NULL AS ContactReason,
 NULL AS [ContactAction],
 NULL AS [ContactMethod],
 NULL AS [ContactMethodClassName],
 NULL AS [QuestionAnswer],
 NULL,
 NULL        
 FROM Comment(NOLOCK) C
 JOIN Entity EN(NOLOCK) ON EN.ID = C.EntityID 
 LEFT JOIN CommentType(NOLOCK) CMT on CMT.ID = C.CommentTypeID   
 WHERE (C.EntityID = @PurchaseOrderEntityID AND C.RecordID IN (Select ID From @PurchaseOrderResult))
 ORDER BY CreateDate DESC
 --SELECT * FROM @tmpFinalResults
 -- KB TFS:653
 ;WITH wELSaveOnFinish
 AS
 (
	SELECT  ID,
			Type,
			EventName,
			Description,
			Comments
	FROM	@tmpFinalResults
	WHERE	ISNULL(EventName,'') = 'SaveFinishTab'
 )
 --SELECT * FROM wELSaveOnFinish
 UPDATE @tmpFinalResults
 SET	Comments = CASE WHEN ISNULL(T.[Description],'') = '' THEN '' 
						ELSE [dbo].[fn_EventDetailForFinish_Get](T.[Description],'SaveFinishTab') END,
		[Description] = 'Saving Finish Tab Details'
 FROM	wELSaveOnFinish W 
 JOIN	@tmpFinalResults T ON W.ID = T.ID AND W.Type = T.Type
 
 
 ;WITH wELNextActionSet
  AS
 (
	SELECT  ID,
			Type,
			EventName,
			Description,
			Comments
	FROM	@tmpFinalResults
	WHERE	ISNULL(EventName,'') = 'NextActionSet'
 )
 --SELECT * FROM wELSaveOnFinish
 UPDATE @tmpFinalResults
 SET	Comments = CASE WHEN ISNULL(T.[Description],'') = '' THEN '' 
						ELSE [dbo].[fn_EventDetailForFinish_Get](T.[Description],'NextActionSet') END,
		[Description] = 'Next Action Set'
 FROM	wELNextActionSet W 
 JOIN	@tmpFinalResults T ON W.ID = T.ID AND W.Type = T.Type

 ;WITH wELNextActionStarted
  AS
 (
	SELECT  ID,
			Type,
			EventName,
			Description,
			Comments
	FROM	@tmpFinalResults
	WHERE	ISNULL(EventName,'') = 'NextActionStarted'
 )
 UPDATE @tmpFinalResults
 SET	Comments = CASE WHEN ISNULL(T.[Description],'') = '' THEN '' 
						ELSE [dbo].[fn_EventDetailForFinish_Get](T.[Description],'NextActionStarted') END,
		[Description] = 'Next Action Started'
 FROM	wELNextActionStarted W 
 JOIN	@tmpFinalResults T ON W.ID = T.ID AND W.Type = T.Type
 
 ;WITH wELNextActionCleared
  AS
 (
	SELECT  ID,
			Type,
			EventName,
			Description,
			Comments
	FROM	@tmpFinalResults
	WHERE	ISNULL(EventName,'') = 'NextActionCleared')

 --SELECT * FROM wELSaveOnFinish
 UPDATE @tmpFinalResults
 SET	Comments = CASE WHEN ISNULL(T.[Description],'') = '' THEN '' 
						ELSE [dbo].[fn_EventDetailForFinish_Get](T.[Description],'NextActionCleared') END,
		[Description] = 'Next Action Cleared'
 FROM	wELNextActionCleared W 
 JOIN	@tmpFinalResults T ON W.ID = T.ID AND W.Type = T.Type

 
  ;WITH wELCaptureEstimate
  AS
 (
	SELECT  ID,
			Type,
			EventName,
			Description,
			Comments
	FROM	@tmpFinalResults
	WHERE	ISNULL(EventName,'') = 'CaptureEstimate'
 )
  UPDATE @tmpFinalResults
 SET	Comments = CASE WHEN ISNULL(T.[Description],'') = '' THEN '' 
						ELSE [dbo].[fn_EventDetailForFinish_Get](T.[Description],'CaptureEstimate') END,
		[Description] = 'Capture Estimate'
 FROM	wELCaptureEstimate W 
 JOIN	@tmpFinalResults T ON W.ID = T.ID AND W.Type = T.Type

   ;WITH wELPOThresholdApprove
  AS
 (
	SELECT  ID,
			Type,
			EventName,
			Description,
			Comments
	FROM	@tmpFinalResults
	WHERE	ISNULL(EventName,'') = 'POThresholdApproved'
 )
  UPDATE @tmpFinalResults
 SET	Comments = CASE WHEN ISNULL(T.[Description],'') = '' THEN '' 
						ELSE [dbo].[fn_EventDetailForFinish_Get](T.[Data],'POThresholdApproved') END,
		[Description] = 'PO Over Threshold Manager Approval'
 FROM	wELPOThresholdApprove W 
 JOIN	@tmpFinalResults T ON W.ID = T.ID AND W.Type = T.Type


   ;WITH wELPOThresholdReject
  AS
 (
	SELECT  ID,
			Type,
			EventName,
			Description,
			Comments
	FROM	@tmpFinalResults
	WHERE	ISNULL(EventName,'') = 'POThresholdRejected'
 )
  UPDATE @tmpFinalResults
 SET	Comments = CASE WHEN ISNULL(T.[Description],'') = '' THEN '' 
						ELSE [dbo].[fn_EventDetailForFinish_Get](T.[Data],'POThresholdApproved') END,
		[Description] = 'PO Over Threshold Manager Approval'
 FROM	wELPOThresholdReject W 
 JOIN	@tmpFinalResults T ON W.ID = T.ID AND W.Type = T.Type



UPDATE Temp
SET Temp.RoleName = R.RoleName,
Temp.OrganizationName = o.Name
FROM @tmpFinalResults Temp
LEFT OUTER JOIN aspnet_Users(NOLOCK) au on au.UserName = Temp.CreateBy
LEFT OUTER JOIN [User](NOLOCK) u on u.aspnet_UserID = au.UserID
LEFT OUTER JOIN aspnet_Roles(NOLOCK) R ON R.RoleID = (SELECT TOP 1 RoleID FROM aspnet_UsersInRoles(NOLOCK) UIR WHERE UIR.UserID = AU.userID)
LEFT OUTER JOIN Organization(NOLOCK) o on o.ID = u.OrganizationID

INSERT INTO @tmpFinalResultsUpdated
SELECT DISTINCT
 T.[Type],
 T.Name,
 T.ID,
 T.Description,
 T.TypeDescription,
 T.Company,
 T.TalkedTo,
 T.PhoneNumber,
 T.CreateBy,
 T.CreateDate,
 T.RoleName,
 T.OrganizationName,
 T.Comments,
 [dbo].[fnConcatenate](T.ContactReason) AS ContactReason,
 T.ContactAction,
 T.ContactMethod,
 T.ContactMethodClassName,
 T.QuestionAnswer
FROM @tmpFinalResults T
GROUP BY 
T.[Type],
 T.Name,
 T.ID,
 T.Description,
 T.TypeDescription,
 T.Company,
 T.TalkedTo,
 T.PhoneNumber,
 T.CreateBy,
 T.CreateDate,
 T.RoleName,
 T.OrganizationName,
 T.Comments,
 T.ContactAction,
 T.ContactMethod,
 T.ContactMethodClassName,
 T.QuestionAnswer


INSERT INTO @FinalResults
SELECT  DISTINCT
 T.[Type],
 T.Name,
 T.ID,
 T.Description,
 T.TypeDescription,
 T.Company,
 T.TalkedTo,
 T.PhoneNumber,
 T.CreateBy,
 T.CreateDate,
 T.RoleName,
 T.OrganizationName,
 T.Comments,
 T.ContactReason,
 T.ContactAction,
 T.ContactMethod,
 T.ContactMethodClassName,
 T.QuestionAnswer
FROM @tmpFinalResultsUpdated T
,@tmpForWhereClause TMP 
WHERE ( 
 ( 
  ( TMP.TypeOperator = -1 ) 
 OR 
  ( TMP.TypeOperator = 0 AND T.Type IS NULL ) 
 OR 
  ( TMP.TypeOperator = 1 AND T.Type IS NOT NULL ) 
 OR 
  ( TMP.TypeOperator = 2 AND T.Type = TMP.TypeValue ) 
 OR 
  ( TMP.TypeOperator = 3 AND T.Type <> TMP.TypeValue ) 
 OR 
  ( TMP.TypeOperator = 4 AND T.Type LIKE TMP.TypeValue + '%') 
 OR 
  ( TMP.TypeOperator = 5 AND T.Type LIKE '%' + TMP.TypeValue ) 
 OR 
  ( TMP.TypeOperator = 6 AND T.Type LIKE '%' + TMP.TypeValue + '%' ) 
 OR 
  ( TMP.TypeOperator = 11 AND T.Type IN (
            SELECT Item FROM [dbo].[fnSplitString](TMP.TypeValue,',')
           ) )
 ) 
 AND 
 1 = 1 
 ) 
 ORDER BY CreateDate DESC
 
 
 --SELECT * FROM @FinalResults
 
SELECT @eventLogCount = COUNT(*) FROM @FinalResults WHERE [Type] = 'Event Log'
SELECT @contactLogCount = COUNT(*) FROM @FinalResults WHERE [Type] = 'Contact Log'
SELECT @commentCount = COUNT(*) FROM @FinalResults WHERE [Type] = 'Comment'
DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM @FinalResults
SET @endInd = @startInd + @pageSize - 1
IF @startInd  > @count   
BEGIN   
 DECLARE @numOfPages INT    
 SET @numOfPages = @count / @pageSize   
 IF @count % @pageSize > 1   
 BEGIN   
  SET @numOfPages = @numOfPages + 1   
 END   
 SET @startInd = ((@numOfPages - 1) * @pageSize) + 1   
 SET @endInd = @numOfPages * @pageSize   
END
SELECT @count AS TotalRows, *, @eventLogCount as EventLogCount,@contactLogCount as ContactLogCount,@commentCount as commentCount FROM @FinalResults WHERE RowNum BETWEEN @startInd AND @endInd Order By RowNum
--DROP TABLE #tmpFinalResults
--DROP TABLE #FinalResults
DROP TABLE #CustomProgramDynamicValues
END




GO


