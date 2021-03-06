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
 --[dms_activity_list] @serviceRequestID = 1000
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
SELECT PDI.Label + ' : ' + PDIVE.Value AS 'QuestionAnswer', PDIVE.RecordID AS 'ContactLogID'
FROM ContactLog(NOLOCK) cl
JOIN ContactLogLink(NOLOCK) cll on cl.id = cll.ContactLogID 
JOIN ProgramDataItemValueEntity(NOLOCK) PDIVE ON PDIVE.EntityID = @ContactLogEntityID AND PDIVE.RecordID = cl.ID
JOIN ProgramDataItem(NOLOCK) PDI ON PDI.ID = PDIVE.ProgramDataItemID
WHERE 
	(
	   (CLL.EntityID = @InboundCallEntityID AND CLL.RecordID IN (SELECT ID From @InboundCallResult))
	OR (CLL.EntityID = @EmergencyAssistanceEntityID AND CLL.RecordID IN (SELECT ID From @EmergencyAssistanceResult))
	OR (CLL.EntityID = @CaseEntityID AND CLL.RecordID = @Case)
	OR (CLL.EntityID = @ServiceRequestEntityID AND CLL.RecordID = @ServiceRequestID)
	OR (CLL.EntityID = @PurchaseOrderEntityID AND CLL.RecordID IN (SELECT ID FROM @PurchaseOrderResult))
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
NULL AS [QuestionAnswer]
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
NULL AS [QuestionAnswer]
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
NULL AS [QuestionAnswer]
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
NULL AS [QuestionAnswer]
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
NULL AS [QuestionAnswer]
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
 CT.Description AS TypeDescription, 
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
    CPDV.QuestionAnswer             
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
 CT.Description AS TypeDescription, 
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
    CPDV.QuestionAnswer             
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
 CT.Description AS TypeDescription, 
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
    CPDV.QuestionAnswer             
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
 CT.Description AS TypeDescription, 
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
    CPDV.QuestionAnswer             
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
 CT.Description AS TypeDescription, 
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
    CPDV.QuestionAnswer             
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
 NULL AS [QuestionAnswer]
 FROM Comment(NOLOCK) C
 JOIN Entity EN(NOLOCK) ON EN.ID = C.EntityID 
 LEFT JOIN CommentType(NOLOCK) CMT on CMT.ID = C.CommentTypeID   
 WHERE 
 (C.EntityID = @InboundCallEntityID AND C.RecordID IN (Select ID From @InboundCallResult))
 OR (C.EntityID = @EmergencyAssistanceEntityID AND C.RecordID IN (Select ID From @EmergencyAssistanceResult))
 OR (C.EntityID = @CaseEntityID AND C.RecordID = @Case)
 OR (C.EntityID = @ServiceRequestEntityID AND C.RecordID = @ServiceRequestID)
 OR (C.EntityID = @PurchaseOrderEntityID AND C.RecordID IN (Select ID From @PurchaseOrderResult))
 ORDER BY CreateDate DESC

UPDATE Temp
SET Temp.RoleName = R.RoleName,
Temp.OrganizationName = o.Name
FROM @tmpFinalResults Temp
LEFT OUTER JOIN aspnet_Users(NOLOCK) au on au.UserName = Temp.CreateBy
LEFT OUTER JOIN [User](NOLOCK) u on u.aspnet_UserID = au.UserID
LEFT OUTER JOIN aspnet_Roles(NOLOCK) R ON R.RoleID = (SELECT TOP 1 RoleID FROM aspnet_UsersInRoles(NOLOCK) UIR WHERE UIR.UserID = AU.userID)
LEFT OUTER JOIN Organization(NOLOCK) o on o.ID = u.OrganizationID


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
 T.QuestionAnswer
FROM @tmpFinalResults T
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
SELECT @count AS TotalRows, *, @eventLogCount as EventLogCount,@contactLogCount as ContactLogCount,@commentCount as commentCount FROM @FinalResults WHERE RowNum BETWEEN @startInd AND @endInd
--DROP TABLE #tmpFinalResults
--DROP TABLE #FinalResults
DROP TABLE #CustomProgramDynamicValues
END




GO



GO

GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Call_Summary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Call_Summary]
GO

--EXEC dms_Call_Summary @serviceRequestID = 1398
CREATE PROC dms_Call_Summary(@serviceRequestID INT = NULL)  
AS  
BEGIN 

DECLARE @MemberProductProvide AS TABLE(ID INT NOT NULL IDENTITY(1,1),
									   ProvideDetails NVARCHAR(MAX))

DECLARE @memberID AS INT
SET     @memberID = (SELECT MemberID FROM [Case] WHERE ID = (SELECT CaseID FROM ServiceRequest WHERE ID = @serviceRequestID))

INSERT INTO @MemberProductProvide
SELECT PP.Description + ' ' +
	   PP.PhoneNumber
FROM   MemberProduct MP
LEFT JOIN ProductProvider PP ON MP.ProductProviderID = PP.ID
WHERE MP.MemberID = @memberID 
AND   MP.EndDate > GETDATE()

--TFS : 555
DECLARE @RelatedCoverageDetails AS TABLE(ClaimNumber NVARCHAR(MAX),ProductProviderName NVARCHAR(MAX),ProductProviderPhoneNumber NVARCHAR(MAX))
IF EXISTS (SELECT * FROM ServiceRequest WHERE  ID = @serviceRequestID AND ProviderClaimNumber IS NOT NULL)
BEGIN
	INSERT INTO @RelatedCoverageDetails
	SELECT SR.ProviderClaimNumber,
		   PP.Name,
		   PP.PhoneNumber
	FROM  ServiceRequest SR
	LEFT JOIN ProductProvider PP ON SR.ProviderID = PP.ID
	WHERE SR.ID = @serviceRequestID
END


DECLARE @programID AS INT
SET     @programID = (SELECT ProgramID FROM [Case] WHERE ID = (SELECT CaseID FROM ServiceRequest WHERE ID = @serviceRequestID))

DECLARE @ProgramConfigurationDetails AS TABLE(
	Name NVARCHAR(100) NULL,
	Value NVARCHAR(100) NULL,
	ControlType NVARCHAR(100) NULL,
	DataType NVARCHAR(100) NULL,
	Sequence INT NULL)

INSERT INTO @ProgramConfigurationDetails
EXEC [dms_programconfiguration_for_program_get]
   @programID = @programID,
   @configurationType = 'Service',
   @configurationCategory  ='Validation'


DECLARE @Hold TABLE(ColumnName NVARCHAR(MAX),ColumnValue NVARCHAR(MAX),DataType NVARCHAR(MAX),Sequence INT,GroupName NVARCHAR(MAX),DefaultRows INT NULL) 
DECLARE @ProgramDataItemValues TABLE(Name NVARCHAR(MAX),Value NVARCHAR(MAX),ScreenName NVARCHAR(MAX))       

;WITH wProgDataItemValues
AS
(
SELECT ROW_NUMBER() OVER ( PARTITION BY EntityID, RecordID, ProgramDataItemID ORDER BY CreateDate DESC) AS RowNum,
              *
FROM   ProgramDataItemValueEntity 
WHERE  RecordId = (SELECT CaseID FROM ServiceRequest WHERE ID=@serviceRequestID)
)

INSERT INTO @ProgramDataItemValues
SELECT 
        PDI.Name,
        W.Value,
        PDI.ScreenName
FROM   ProgramDataItem PDI
JOIN   wProgDataItemValues W ON PDI.ID = W.ProgramDataItemID
WHERE  W.RowNum = 1



	DECLARE @DocHandle int    
	DECLARE @XmlDocument NVARCHAR(MAX)   
	DECLARE @ProductID INT
	SET @ProductID = NULL
	SELECT  @ProductID = PrimaryProductID FROM ServiceRequest WHERE ID = @serviceRequestID

-- Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'

	SET FMTONLY OFF    
-- Sanghi : ISNull is required because generating XML will ommit the columns.     
-- Two Blank Space is required.  
	DECLARE @tmpServiceLocationVendor TABLE
	(
		Line1 NVARCHAR(100) NULL,
		Line2 NVARCHAR(100) NULL,
		Line3 NVARCHAR(100) NULL,
		City NVARCHAR(100) NULL,
		StateProvince NVARCHAR(100) NULL,
		CountryCode NVARCHAR(100) NULL,
		PostalCode NVARCHAR(100) NULL,
		
		TalkedTo NVARCHAR(50) NULL,
		PhoneNumber NVARCHAR(100) NULL,
		VendorName NVARCHAR(100) NULL
	)
	INSERT INTO @tmpServiceLocationVendor	
	SELECT	TOP 1	AE.Line1, 
					AE.Line2, 
					AE.Line3, 
					AE.City, 
					AE.StateProvince, 
					AE.CountryCode, 
					AE.PostalCode,
					cl.TalkedTo,
					cl.PhoneNumber,
					V.Name As VendorName
		FROM	ContactLogLink cll
		JOIN	ContactLog cl on cl.ID = cll.ContactLogID
		JOIN	ContactLogLink cll2 on cll2.contactlogid = cl.id and cll2.entityid = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest') and cll2.RecordID = @serviceRequestID
		JOIN	VendorLocation VL ON cll.RecordID = VL.ID
		JOIN	Vendor V ON VL.VendorID = V.ID 	
		JOIN	AddressEntity AE ON AE.RecordID = VL.ID AND AE.EntityID = (SELECT ID FROM Entity WHERE name = 'VendorLocation')
		WHERE	cll.entityid = (SELECT ID FROM Entity WHERE name = 'VendorLocation')
		AND		cl.ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ServiceLocationSelection')
		ORDER BY cll.id DESC
	

  
	SET @XmlDocument = (SELECT TOP 1    

-- PROGRAM SECTION
--	1 AS Program_DefaultNumberOfRows   
	cl.Name + ' - ' + p.name as Program_ClientProgramName    
    ,(SELECT 'Case Number:'+Value FROM @ProgramDataItemValues WHERE ScreenName='StartCall' AND Name='CaseNumber') AS Program_CaseNumber
    ,(SELECT 'Agent Name:'+Value FROM @ProgramDataItemValues WHERE ScreenName='StartCall' AND Name='AgentName') AS Program_AgentName
    ,(SELECT 'Claim Number:'+ Value FROM @ProgramDataItemValues WHERE ScreenName='StartCall' AND Name='ClaimNumber') AS Program_ClaimNumber
-- MEMBER SECTION
--	, 5 AS Member_DefaultNumberOfRows
-- KB : 6/7 : TFS # 1339 : Presenting Case.Contactfirstname and Case.ContactLastName as member name and the values from member as company_name when the values differ.	
   -- Ignore time while comparing dates here
    -- KB: Considering Effective and Expiration Dates to calculate member status
	, CASE 
		WHEN	ISNULL(m.EffectiveDate,@minDate) <= @now AND ISNULL(m.ExpirationDate,@minDate) >= @now
		THEN	'Active'
		ELSE	'Inactive'
		END	AS Member_Status 
	, m.ClientMemberType AS Member_ClientMemberType   
	, COALESCE(c.ContactFirstName,'') + COALESCE(' ' + c.ContactLastName,'') AS Member_Name
	, CASE
		WHEN	c.ContactFirstName <> m.Firstname
		AND		c.ContactLastName <> m.LastName
		THEN
				REPLACE(RTRIM(    
				COALESCE(m.FirstName, '') +    
				COALESCE(m.MiddleName, '') +   
				COALESCE(m.Suffix, '') + 
				COALESCE(' ' + m.LastName, '') 
				), '  ', ' ')
		ELSE
				NULL
		END as Member_CompanyName
    , ISNULL(ms.MembershipNumber,' ') AS Member_MembershipNumber
    , ISNULL((SELECT NAME FROM PhoneType WHERE ID = c.ContactPhoneTypeID),' ') as Member_CallbackPhoneTypeID    
    , ISNULL(c.ContactPhoneNumber,'') as Member_CallbackPhoneNumber    
    , ISNULL((SELECT NAME FROM PhoneType WHERE ID = c.ContactAltPhoneTypeID),' ') as Member_AltCallbackPhoneTypeID   
    , ISNULL(c.ContactAltPhoneNumber,'') as Member_AltCallbackPhoneNumber    
    , CONVERT(nvarchar(10),m.MemberSinceDate,101) as Member_MemberSinceDate
    , CONVERT(nvarchar(10),m.EffectiveDate,101) AS Member_EffectiveDate
    , CONVERT(nvarchar(10),m.ExpirationDate,101) AS Member_ExpirationDate
    , ISNULL(ae.Line1,'') AS Member_AddressLine1
    , ISNULL(ae.Line2,'') AS Member_AddressLine2
    , ISNULL(REPLACE(RTRIM(    
		COALESCE(ae.City, '') +
		COALESCE(', ' + ae.StateProvince, '') +
		COALESCE(' ' + ae.PostalCode, '') +
		COALESCE(' ' + ae.CountryCode, '') 
		), '  ', ' ')
		, ' ' ) AS Member_AddressCityStateZip
	,'Client Ref #:' + ms.ClientReferenceNumber AS Member_ReceiptNumber
-- VEHICLE SECTION
--	, 3 AS Vehicle_DefalutNumberOfRows
	,CASE	WHEN C.IsVehicleEligible IS NULL THEN '' 
			WHEN C.IsVehicleEligible = 1 THEN 'In Warranty'
			ELSE 'Out of Warranty' END AS Vehicle_IsEligible
	, ISNULL(RTRIM (
		COALESCE(c.VehicleYear + ' ', '') +    
		COALESCE(CASE c.VehicleMake WHEN 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END+ ' ', '') +    
		COALESCE(CASE C.VehicleModel WHEN 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END, '')
		), ' ') as Vehicle_YearMakeModel    
	, ISNULL(c.VehicleVIN,' ') as Vehicle_VIN    
	, ISNULL(RTRIM (
		COALESCE(c.VehicleColor + '  ' , '') +
		COALESCE(c.VehicleLicenseState + '-','') + 
		COALESCE(c.VehicleLicenseNumber, '')
		), ' ' ) AS Vehicle_Color_LicenseStateNumber
    ,ISNULL(
			COALESCE((SELECT Name FROM VehicleType WHERE ID = c.VehicleTypeID) + '-','') +
			COALESCE((SELECT Name FROM VehicleCategory WHERE ID = c.VehicleCategoryID),'') 
		,'') AS Vehicle_Type_Category
    ,ISNULL(C.[VehicleDescription],'') AS Vehicle_Description
    ,CASE WHEN C.[VehicleLength] IS NULL THEN '' ELSE CONVERT(NVARCHAR(50),C.[VehicleLength]) END AS Vehicle_Length
-- SERVICE SECTION   
--	, 2 AS Service_DefaultNumberOfRows  
	
	, CASE WHEN sr.IsPrimaryOverallCovered  = 1 THEN 'Covered' ELSE 'Not Covered' END AS Service_IsPrimaryOverallCovered
	, pc.Name as Service_ProductCategoryTow
	, sr.PrimaryServiceEligiblityMessage as Service_PrimaryServiceEligiblityMessage

	, CASE WHEN sr.IsSecondaryOverallCovered  = 1 THEN 'Covered' ELSE 'Not Covered' END AS Service_IsSecondaryOverallCovered
	, CASE WHEN sr.IsPossibleTow = 1 THEN 'Possible Tow' ELSE '' END AS Service_IsPossibleTow
	, sr.SecondaryServiceEligiblityMessage as Service_SecondaryServiceEligiblityMessage

	--, '$' + CONVERT(NVARCHAR(50),ISNULL(sr.PrimaryCoverageLimit,0)) as Service_CoverageLimit  

-- LOCATION SECTION     
--	, 2 AS Location_DefaultNumberOfRows
	, ISNULL(sr.ServiceLocationAddress,' ') as Location_Address    
	, ISNULL(sr.ServiceLocationDescription,' ') as Location_Description  

-- DESTINATION SECTION     
--	, 2 AS Destination_DefaultNumberOfRows
	, ISNULL(sr.DestinationAddress,' ') as Destination_Address    
	, ISNULL(sr.DestinationDescription,' ') as Destination_Description 	
	, (SELECT VendorName FROM @tmpServiceLocationVendor ) AS Destination_VendorName
	, (SELECT PhoneNumber FROM @tmpServiceLocationVendor ) AS Destination_PhoneNumber
	, (SELECT TalkedTo FROM @tmpServiceLocationVendor ) AS Destination_TalkedTo
	, (SELECT ISNULL(Line1,'') FROM @tmpServiceLocationVendor ) AS Destination_AddressLine1
    , (SELECT ISNULL(Line2,'') FROM @tmpServiceLocationVendor) AS Destination_AddressLine2
    , (SELECT ISNULL(REPLACE(RTRIM(    
		COALESCE(City, '') +
		COALESCE(', ' + StateProvince, '') +
		COALESCE(' ' + PostalCode, '') +
		COALESCE(' ' + CountryCode, '') 
		), '  ', ' ')
		, ' ' ) FROM  @tmpServiceLocationVendor) AS Destination_AddressCityStateZip    
		
-- ISP SECTION
--	, 3 AS ISP_DefaultNumberOfRows
	--,CASE 
	--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NOT NULL THEN 'Contracted'
	--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NULL THEN 'Not Contracted'
	--	WHEN vc.ID IS NOT NULL THEN 'Contracted' 
	--	ELSE 'Not Contracted'
	--	END as ISP_Contracted
	, CASE WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted' ELSE 'Not Contracted' END AS ISP_Contracted
	, ISNULL(v.Name,' ') as ISP_VendorName    
	, ISNULL(v.VendorNumber, ' ') AS ISP_VendorNumber
	--, ISNULL(peISP.PhoneNumber,' ') as ISP_DispatchPhoneNumber 
	, (SELECT TOP 1 PhoneNumber
		FROM PhoneEntity 
		WHERE RecordID = vl.ID
		AND EntityID = (Select ID From Entity Where Name = 'VendorLocation')
		AND PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')
		ORDER BY ID DESC
		) AS ISP_DispatchPhoneNumber
	, ISNULL(aeISP.Line1,'') AS ISP_AddressLine1
    , ISNULL(aeISP.Line2,'') AS ISP_AddressLine2
    , ISNULL(REPLACE(RTRIM(    
		COALESCE(aeISP.City, '') +
		COALESCE(', ' + aeISP.StateProvince, '') +
		COALESCE(' ' + aeISP.PostalCode, '') +
		COALESCE(' ' + aeISP.CountryCode, '') 
		), '  ', ' ')
		, ' ' ) AS ISP_AddressCityStateZip
	, COALESCE(ISNULL(po.PurchaseOrderNumber + '-', ' '),'') + ISNULL(pos.Name, ' ' ) AS ISP_PONumberStatus
--	, ISNULL(pos.Name, ' ' ) AS ISP_POStatus
	, COALESCE( '$' + CONVERT(NVARCHAR(10),po.PurchaseOrderAmount),'') 
		+ ' ' 
		+ ISNULL(CASE WHEN po.ID IS NOT NULL THEN PC.Name ELSE NULL END,'') AS ISP_POAmount_ProductCategory
	--, ISNULL(po.PurchaseOrderAmount, ' ' ) AS ISP_POAmount
	, 'Issued:' +
		REPLACE(CONVERT(VARCHAR(8), po.IssueDate, 10), '-', '/') + ' - ' +  
		SUBSTRING(CONVERT(VARCHAR(20), po.IssueDate, 9), 13, 8) + ' ' +  
		SUBSTRING(CONVERT(VARCHAR(30), po.IssueDate, 9), 25, 2) AS ISP_IssuedDate  
	, 'ETA:' +
		REPLACE(CONVERT(VARCHAR(8), po.ETADate, 10), '-', '/') + ' - ' +  
		SUBSTRING(CONVERT(VARCHAR(20), po.ETADate, 9), 13, 8) + ' ' +  
		SUBSTRING(CONVERT(VARCHAR(30), po.ETADate, 9), 25, 2) AS ISP_ETADate  

-- SERVICE REQUEST SECTION 
--	, 2 AS SR_DefaultNumberOfRows
	--Sanghi 03 - July - 2013 Updated Below Line.
	, CAST(CAST(ISNULL(sr.ID, ' ') AS NVARCHAR(MAX)) + ' - ' + ISNULL(srs.Name, ' ') AS NVARCHAR(MAX))  AS SR_Info 
	--, ISNULL(sr.ID,' ') as SR_ServiceRequestID      
	--,(ISNULL(srs.Name,'')) + CASE WHEN na.Name IS NULL THEN '' ELSE ' - ' + (ISNULL(na.Name,'')) END AS SR_ServiceRequestStatus
	--, ISNULL('Closed Loop: ' + cls.Name, ' ') as SR_ClosedLoopStatus
	, ISNULL(sr.CreateBy,' ') + ' ' + 
		    REPLACE(CONVERT(VARCHAR(8), sr.CreateDate, 10), '-', '/') + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(20), sr.CreateDate, 9), 13, 8) + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(30), sr.CreateDate, 9), 25, 2
			) AS SR_CreateInfo
	--, ISNULL(sr.CreateBy,' ')as SR_CreatedBy   
	--, REPLACE(CONVERT(VARCHAR(8), sr.CreateDate, 10), '-', '/') + ' - ' +  
	--	SUBSTRING(CONVERT(VARCHAR(20), sr.CreateDate, 9), 13, 8) + ' ' +  
	--	SUBSTRING(CONVERT(VARCHAR(30), sr.CreateDate, 9), 25, 2) AS SR_CreateDate
	--, ISNULL(NextAction.Name, ' ') + ISNULL(u.FirstName, ' ') + ' ' + ISNULL(u.LastName,' ') AS SR_NextActionInfo  
	, ISNULL(NextAction.Name + ' - ', ' ') + ISNULL(u.FirstName, ' ') + ' ' + ISNULL(u.LastName,' ') AS SR_NextActionName_AssignedTo
	, ISNULL( 	
			REPLACE(
			CONVERT(VARCHAR(8), sr.NextActionScheduledDate, 10), '-', '/') + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(20), sr.NextActionScheduledDate, 9), 13, 8) + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(30), sr.NextActionScheduledDate, 9), 25, 2
			) 
			, ' ') AS SR_NextActionScheduledDate
	--, ISNULL('AssignedTo: ' + u.FirstName, ' ') + ' ' + ISNULL(u.LastName,' ') AS SR_NextActionAssignedTo  

	FROM		ServiceRequest sr      
	JOIN		[Case] c on c.ID = sr.CaseID    
	LEFT JOIN	PhoneType ptContact on ptContact.ID = c.ContactPhoneTypeID    
	JOIN		Program p on p.ID = c.ProgramID    
	JOIN		Client cl on cl.ID = p.ClientID    
	JOIN		Member m on m.ID = c.MemberID    
	JOIN		Membership ms on ms.ID = m.MembershipID    
	LEFT JOIN	AddressEntity ae ON ae.EntityID = (select ID from Entity where Name = 'Membership')    
	AND			ae.RecordID = ms.ID    
	AND			ae.AddressTypeID = (select ID from AddressType where Name = 'Home')    
	LEFT JOIN	Country country on country.ID = ae.CountryID     
	LEFT JOIN	PhoneEntity peMbr ON peMbr.EntityID = (select ID from Entity where Name = 'Membership')     
	AND			peMbr.RecordID = ms.ID    
	AND			peMbr.PhoneTypeID = (select ID from PhoneType where Name = 'Home')    
	LEFT JOIN	PhoneType ptMbr on ptMbr.ID = peMbr.PhoneTypeID    
	LEFT JOIN	ProductCategory pc on pc.ID = sr.ProductCategoryID    
	LEFT JOIN	(  
				SELECT TOP 1 *  
				FROM PurchaseOrder wPO   
				WHERE wPO.ServiceRequestID = @serviceRequestID  
				AND wPO.IsActive = 1
				AND wPO.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending')
				ORDER BY wPO.IssueDate DESC  
				) po on po.ServiceRequestID = sr.ID  
	LEFT JOIN	PurchaseOrderStatus pos on pos.ID = po.PurchaseOrderStatusID  
	LEFT JOIN	VendorLocation vl on vl.ID = po.VendorLocationID    
	LEFT JOIN	Vendor v on v.ID = vl.VendorID 
	--LEFT JOIN	[Contract] vc on vc.VendorID = v.ID and vc.IsActive = 1 and vc.ContractStatusID = (Select ID From ContractStatus Where Name = 'Active')
	--LEFT OUTER JOIN (
	--			SELECT DISTINCT vr.VendorID, vr.ProductID
	--			FROM dbo.fnGetCurrentProductRatesByVendorLocation() vr 
	--			) DefaultVendorRates ON v.ID = DefaultVendorRates.VendorID And @ProductID = DefaultVendorRates.ProductID
	LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID

	--LEFT JOIN	PhoneEntity peISP on peISP.EntityID = (select ID from Entity where Name = 'VendorLocation')     
	--AND			peISP.RecordID = vl.ID    
	--AND			peISP.PhoneTypeID = (select ID from PhoneType where Name = 'Dispatch')  
	--LEFT JOIN	PhoneType ptISP on ptISP.ID = peISP.PhoneTypeID    
	--LEFT JOIN (
	--			SELECT TOP 1 ph.RecordID, ph.PhoneNumber
	--			FROM PhoneEntity ph 
	--			WHERE EntityID = (Select ID From Entity Where Name = 'VendorLocation')
	--			AND PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')
	--			ORDER BY ID 
	--		   )  peISP ON peISP.RecordID = vl.ID
	LEFT JOIN	AddressEntity aeISP ON aeISP.EntityID = (select ID from Entity where Name = 'VendorLocation')    
	AND			aeISP.RecordID = vl.ID    
	AND			aeISP.AddressTypeID = (select ID from AddressType where Name = 'Business')    
 -- CR # 524  
	LEFT JOIN	ServiceRequestStatus srs ON srs.ID=sr.ServiceRequestStatusID  
	LEFT JOIN	NextAction na ON na.ID=sr.NextActionID  
	LEFT JOIN	ClosedLoopStatus cls ON cls.ID=sr.ClosedLoopStatusID 
 -- End : CR # 524  
 	LEFT JOIN	VendorLocation VLD ON VLD.ID = sr.DestinationVendorLocationID
	LEFT JOIN	PhoneEntity peDestination ON peDestination.RecordID = VLD.ID AND peDestination.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')  
	LEFT JOIN	NextAction NextAction on NextAction.ID = sr.NextActionID
	LEFT JOIN	[User] u on u.ID = sr.NextActionAssignedToUserID

	WHERE		sr.ID = @ServiceRequestID    
	FOR XML PATH)    
    

EXEC sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument    
SELECT * INTO #Temp FROM OPENXML (@DocHandle, '/row',2)      
INSERT INTO @Hold    
SELECT T1.localName ,T2.text,'String',ROW_NUMBER() OVER(ORDER BY T1.ID),'',NULL FROM #Temp T1     
INNER JOIN #Temp T2 ON T1.id = T2.parentid    
WHERE T1.id > 0    
    
    
DROP TABLE #Temp   

 -- Group Values Based on Sequence Number    
 UPDATE @Hold SET GroupName = 'Member', DefaultRows = 6 WHERE CHARINDEX('Member_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Vehicle', DefaultRows = 3 WHERE CHARINDEX('Vehicle_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Service' ,DefaultRows = 6 WHERE CHARINDEX('Service_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Location', DefaultRows = 2 WHERE CHARINDEX('Location_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Destination', DefaultRows = 2 WHERE CHARINDEX('Destination_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'ISP', DefaultRows = 10 WHERE CHARINDEX('ISP_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Program', DefaultRows = 1 WHERE CHARINDEX('Program_',ColumnName) > 0   
 UPDATE  @Hold SET GroupName = 'Service Request', DefaultRows = 2 WHERE CHARINDEX('SR_',ColumnName) > 0   

 --CR # 524   
      
-- UPDATE @Hold SET GroupName ='Service Request' where ColumnName in ('ServiceRequestID','ServiceRequestStatus','NextAction',  
--'ClosedLoopStatus',  
--'CreateDate','CreatedBy','SR_NextAction','SR_NextActionAssignedTo')  
 -- End : CR # 524  
   
 UPDATE @Hold SET DataType = 'Phone' WHERE CHARINDEX('PhoneNumber',ColumnName) > 0    
 UPDATE @Hold SET DataType = 'LabelThemeInline' WHERE CHARINDEX('Member_Status',ColumnName) > 0 
 UPDATE @Hold SET DataType = 'LabelThemeInline' WHERE CHARINDEX('Member_ClientMemberType',ColumnName) > 0 
 UPDATE @Hold SET DataType = 'LabelTheme' WHERE CHARINDEX('Vehicle_IsEligible',ColumnName) > 0
 UPDATE @Hold SET DataType = 'LabelThemeInline' WHERE CHARINDEX('Service_IsPrimaryOverallCovered',ColumnName) > 0
 UPDATE @Hold SET DataType = 'LabelThemeInline' WHERE CHARINDEX('Service_IsSecondaryOverallCovered',ColumnName) > 0   

 IF NOT EXISTS (SELECT * FROM @Hold WHERE ColumnName  = 'Service_IsPossibleTow' AND ColumnValue IS NOT NULL AND  ColumnValue != '')
 BEGIN
	DELETE FROM @Hold WHERE ColumnName  = 'Service_IsSecondaryOverallCovered'
	DELETE FROM @Hold WHERE ColumnName  = 'Service_SecondaryServiceEligiblityMessage'
 END

 IF NOT EXISTS (SELECT * FROM @Hold WHERE ColumnName  = 'Service_ProductCategoryTow' AND ColumnValue IS NOT NULL AND  ColumnValue != '')
 BEGIN
	DELETE FROM @Hold WHERE ColumnName  = 'Service_IsPrimaryOverallCovered'
 END

 DELETE FROM @Hold WHERE ColumnValue IS NULL

 DECLARE @DefaultRows INT
 SET  @DefaultRows = (SELECT Sequence FROM @Hold WHERE ColumnName = 'Member_AltCallbackPhoneNumber')
 IF @DefaultRows IS NOT NULL
 BEGIN
 SET @DefaultRows = (SELECT COUNT(*) FROM @Hold WHERE ColumnName LIKE 'Member_%' AND Sequence <= @DefaultRows)
 -- Re Setting values 
 UPDATE @Hold SET DefaultRows = @DefaultRows WHERE GroupName = 'Member' 
 END

 -- Sanghi - 01-04-2014 CR : 248 Increase Number of Columns to be Displayed When Warranty is Applicable.
 -- Validate Vehicle_IsEligible COLUMN 
 IF EXISTS (SELECT * FROM @Hold WHERE ColumnName = 'Vehicle_IsEligible')
 BEGIN
	UPDATE @Hold SET DefaultRows = 4 WHERE GroupName = 'Vehicle' 
 END


 -- Update Label fields
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Member Since: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Member_MemberSinceDate')
 WHERE ColumnName = 'Member_MemberSinceDate'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Effective: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Member_EffectiveDate')
 WHERE ColumnName = 'Member_EffectiveDate'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Expiration: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Member_ExpirationDate')
 WHERE ColumnName = 'Member_ExpirationDate'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'PO: ' + ColumnValue FROM @Hold WHERE ColumnName = 'ISP_PONumberStatus')
 WHERE ColumnName = 'ISP_PONumberStatus'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Length: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Vehicle_Length')
 WHERE ColumnName = 'Vehicle_Length'


IF NOT EXISTS (SELECT * FROM @ProgramConfigurationDetails WHERE Name = 'MemberEligibilityApplies' AND Value = 'Yes')
BEGIN
	DELETE FROM @Hold WHERE ColumnName = 'Member_Status'
END

IF NOT EXISTS(SELECT  * FROM @Hold WHERE ColumnName = 'Member_ClientMemberType') 
BEGIN
	UPDATE @Hold SET DataType = 'LabelTheme' WHERE ColumnName = 'Member_Status'
END


IF EXISTS (SELECT * FROM @RelatedCoverageDetails)
BEGIN
	DECLARE @maxSequence AS INT
	SET     @maxSequence = (SELECT MAX([Sequence]) FROM @Hold WHERE GroupName = 'Service Request')
	INSERT INTO @Hold SELECT 'RelatedCoverageDetailsProviderName', ProductProviderName,'String',@maxSequence + 1,'Related Coverage',3 FROM @RelatedCoverageDetails
	INSERT INTO @Hold SELECT 'RelatedCoverageDetailsProviderPhone', ProductProviderPhoneNumber,'String',@maxSequence + 2,'Related Coverage',3 FROM @RelatedCoverageDetails
	INSERT INTO @Hold SELECT 'RelatedCoverageDetailsClaimNumber', ClaimNumber,'String',@maxSequence + 3,'Related Coverage',3 FROM @RelatedCoverageDetails
END
 
 SELECT * FROM @Hold WHERE ColumnValue IS NOT NULL ORDER BY Sequence ASC 
 
END
GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Claim_FordQFC_Create]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Claim_FordQFC_Create] 
 END 
 GO  
 SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_Claim_FordQFC_Create]
AS
BEGIN

      INSERT INTO [dbo].[Claim]
                     ([ClaimTypeID]
                     ,[ClaimCategoryID]
                     ,[ClaimStatusID]
                     ,[ProgramID]
                     ,[MemberID]
                     ,[VendorID]
                     ,[PurchaseOrderID]
                     ,[ClaimDate]
                     ,[ReceivedDate]
                     ,[ReceiveContactMethodID]
                     ,[ClaimDescription]
                     ,[ContactName]
                     ,[ContactPhoneNumber]
                     ,[ContactEmailAddress]
                     ,[PayeeType]
                     ,[PaymentAddressLine1]
                     ,[PaymentAddressLine2]
                     ,[PaymentAddressLine3]
                     ,[PaymentAddressCity]
                     ,[PaymentAddressStateProvince]
                     ,[PaymentAddressStateProvinceID]
                     ,[PaymentAddressPostalCode]
                     ,[PaymentAddressCountryCode]
                     ,[PaymentAddressCountryID]
                     ,[ServiceProductCategoryID]
                     ,[ServiceLocation]
                     ,[DestinationLocation]
                     ,[ServiceFacilityName]
                     ,[ServiceFacilityPACode]
                     ,[ServiceMiles]
                     ,[IsServiceReceiptOnFile]
                     ,[VehicleTypeID]
                     ,[VehicleCategoryID]
                     ,[RVTypeID]
                     ,[VehicleVIN]
                     ,[VehicleYear]
                     ,[VehicleMake]
                     ,[VehicleMakeOther]
                     ,[VehicleModel]
                     ,[VehicleModelOther]
                     ,[VehicleChassis]
                     ,[VehicleEngine]
                     ,[VehicleTransmission]
                     ,[WarrantyStartDate]
                     ,[WarrantyYears]
                     ,[WarrantyMiles]
                     ,[CurrentMiles]
                     ,[NextActionID]
                     ,[NextActionAssignedToUserID]
                     ,[NextActionScheduledDate]
                     ,[AmountRequested]
                     ,[AmountApproved]
                     ,[ClaimDecisionDate]
                     ,[ClaimDecisionBy]
                     ,[ClaimRejectReasonID]
                     ,[ClaimRejectReasonOther]
                     ,[GWOApprovalCode]
                     ,[CUDLCaseNumber]
                     ,[ACESReferenceNumber]
                     ,[ACESSubmitDate]
                     ,[ACESOutcome]
                     ,[ACESClearedDate]
                     ,[ClientPaymentID]
                     ,[ACESAmount]
                     ,[ExportDate]
                     ,[ExportBatchID]
                     ,[PaymentTypeID]
                     ,[PaymentDate]
                     ,[PaymentAmount]
                     ,[PaymentPayeeName]
                     ,[CheckNumber]
                     ,[CheckClearedDate]
                     ,[PassthruAccountingInvoiceBatchID]
                     ,[FeeAccountingInvoiceBatchID]
                     ,[SourceSystemID]
                     ,[IsActive]
                     ,[CreateDate]
                     ,[CreateBy]
					 ,[ACESClaimStatusID])

      SELECT  
            (SELECT ID FROM ClaimType WHERE Name = 'FordQFC') ClaimTypeID
            ,(SELECT ID FROM ClaimCategory WHERE Name = 'RoadsideService') ClaimCategoryID
            ,(SELECT ID FROM ClaimStatus WHERE Name = 'Approved') ClaimStatusID
            ,p.ID AS ProgramID
            ,m.ID AS MemberID
            ,vl.VendorID
            ,po.ID AS PurchaseOrderID
            ,PO.CreateDate AS ClaimDate
            ,PO.CreateDate AS ReceivedDate
            ,(SELECT ID FROM ContactMethod WHERE Name = 'Phone') AS ReceiveContactMethod
            ,(
				'Ford QFC' + ' - ' + (SELECT Name FROM Product WHERE ID = PO.ProductID) +
				'; Agent: ' + c.CreateBy +
				'; Contact: ' + LEFT(dbo.fnc_ProperCase(CASE WHEN ISNULL(c.ContactFirstName,'') <> '' THEN c.ContactFirstName ELSE '' END +
					CASE WHEN ISNULL(c.ContactLastName,'') <> '' THEN CASE WHEN ISNULL(c.ContactFirstName,'') <> '' THEN ' ' ELSE '' END + c.ContactLastName ELSE '' END),50) +
				'; Vehicle License: ' + CASE WHEN c.VehicleLicenseState IS NOT NULL THEN UPPER(c.VehicleLicenseState) + '-' ELSE '' END +
					UPPER(ISNULL(c.VehicleLicenseNumber,'')) +
				CASE WHEN (SELECT pc.Name FROM Product p JOIN ProductCategory pc on pc.ID = p.ProductCategoryID WHERE p.ID = PO.ProductID) = 'Tow' 
						THEN '; Reason: ' + 
							CASE WHEN  
								  ISNULL((SELECT srd.Answer 
									FROM ServiceRequest sr 
									LEFT OUTER JOIN ServiceRequestDetail srd ON srd.ServiceRequestID = sr.ID AND 
										srd.ProductCategoryQuestionID = 1 
									WHERE sr.ID = PO.ServiceRequestID),'') <> ''
								THEN
								  ISNULL((SELECT CASE WHEN srd.Answer = 'Other' THEN '' ELSE srd.Answer END 
									FROM ServiceRequest sr 
									LEFT OUTER JOIN ServiceRequestDetail srd ON srd.ServiceRequestID = sr.ID AND 
										srd.ProductCategoryQuestionID = 1 -- Reason for Tow response
									WHERE sr.ID = PO.ServiceRequestID),'') 
									+ ' ' +
								  ISNULL((SELECT srd.Answer 
									FROM ServiceRequest sr 
									LEFT OUTER JOIN ServiceRequestDetail srd ON srd.ServiceRequestID = sr.ID AND 
										srd.ProductCategoryQuestionID = 2 ---- Response to Other reason 
									WHERE sr.ID = PO.ServiceRequestID),'') 
								ELSE 'No Reason Provided' 
								END
						ELSE '' 
						END 
				) AS ClaimDescription
            ,LEFT(dbo.fnc_ProperCase(CASE WHEN ISNULL(c.ContactFirstName,'') <> '' THEN c.ContactFirstName ELSE '' END +
            CASE WHEN ISNULL(c.ContactLastName,'') <> '' THEN CASE WHEN ISNULL(c.ContactFirstName,'') <> '' THEN ' ' ELSE '' END + c.ContactLastName ELSE '' END),50) AS ContactName
            ,c.ContactPhoneNumber
            ,m.Email AS ContactEmailAddress
            ,NULL AS PayeeType
            ,NULL AS PaymentAddressLine1
            ,NULL AS PaymentAddressLine2
            ,NULL AS PaymentAddressLine3
            ,NULL AS PaymentAddressCity
            ,NULL AS PaymentAddressStateProvince
            ,NULL AS PaymentAddressStateProvinceID
            ,NULL AS PaymentAddressPostalCode
            ,NULL AS PaymentAddressCountryCode
            ,NULL AS PaymentAddressCountryID
            ,(SELECT ProductCategoryID From Product WHERE ID = PO.ProductID) AS ServiceProductCategoryID
            ,dbo.fnc_ProperCase(SR.ServiceLocationAddress) AS ServiceLocation
            ,dbo.fnc_ProperCase(SR.DestinationAddress) AS DestinationLocation
            ,(SELECT v.Name 
                        FROM Vendor v 
                        JOIN VendorLocation vl on vl.vendorid = v.id 
                        WHERE vl.ID = SR.DestinationVendorLocationID) 
                  AS ServiceFacilityName
            ,(SELECT vl.PartsAndAccessoryCode 
                        FROM Vendor v 
                        JOIN VendorLocation vl on vl.vendorid = v.id 
                        WHERE vl.ID = SR.DestinationVendorLocationID) 
                  AS ServiceFacilityPACode
            ,SR.ServiceMiles AS ServiceMiles
            ,NULL AS IsServiceReceiptOnFile
            ,c.VehicleTypeID
            ,c.VehicleCategoryID
            ,c.VehicleRVTypeID AS RVTypeID
            ,UPPER(c.VehicleVIN) AS VehicleVIN
            ,c.VehicleYear
            ,c.VehicleMake
            ,c.VehicleMakeOther
            ,c.VehicleModel
            ,c.VehicleModelOther
            ,c.VehicleChassis
            ,c.VehicleEngine
            ,c.VehicleTransmission
            ,c.VehicleWarrantyStartDate AS WarrantyStartDate
            ,NULL AS WarrantyYears
            ,NULL AS WarrantyMiles
            ,c.VehicleCurrentMileage AS CurrentMiles
            ,NULL AS NextActionID
            ,NULL AS NextActionAssignedToUserID
            ,NULL AS NextActionScheduledDate
            ,VI.InvoiceAmount AS AmountRequested
            ,VI.PaymentAmount AS AmountApproved
            ,GETDATE() AS ClaimDecisionDate
            ,'system' AS ClaimDecisionBy
            ,NULL AS ClaimRejectReasonID
            ,NULL AS ClaimRejectReasonOther
            ,NULL AS GWOApprovalCode
            ,NULL AS CUDLCaseNumber
            ,NULL AS ACESReferenceNumber

            --,ACESSubmitDate = CASE WHEN PO.CreateDate > '2013-07-31' OR VI.ID IS NULL THEN NULL ELSE VI.CreateDate END
            --,ACESOutcome = CASE WHEN PO.CreateDate > '2013-07-31' OR VI.ID IS NULL THEN NULL ELSE 'Approved' END 
            --,ACESClearedDate = CASE WHEN PO.CreateDate > '2013-07-31' OR VI.ID IS NULL THEN NULL ELSE DATEADD(mm,0,DATEADD(mm, DATEDIFF(m,0,VI.CreateDate)+1,0)) END
            --,ACESAmount = CASE WHEN PO.CreateDate > '2013-07-31' OR VI.ID IS NULL THEN NULL ELSE PO.CoachNetServiceAmount END

            ,NULL AS ACESSubmitDate
            ,NULL AS ACESOutcome
            ,NULL AS ACESClearedDate
            ,NULL AS ClientPaymentID
            ,NULL AS ACESAmount
            ,NULL AS ExportDate
            ,NULL AS ExportBatchID
            ,NULL AS PaymentTypeID
            ,NULL AS PaymentDate
            ,NULL AS PaymentAmount
            ,NULL AS PaymentPayeeName
            ,NULL AS CheckNumber
            ,NULL AS CheckClearedDate
            ,NULL AS PassthruAccountingInvoiceBatchID
            ,NULL AS FeeAccountingInvoiceBatchID
            ,(SELECT ID FROM SourceSystem WHERE Name = 'Dispatch') AS SourceSystemID
            ,1 AS IsActive
            ,GETDATE() AS CreateDate
            ,'System' AS CreateBy
            ,(SELECT ID FROM ACESClaimStatus WHERE Name = 'Pending')
      FROM PurchaseOrder PO
      JOIN VendorInvoice VI ON VI.PurchaseOrderID = PO.ID
      JOIN ServiceRequest SR ON PO.ServiceRequestID = SR.ID
      JOIN [Case] c ON SR.CaseID = c.ID
      JOIN Member m ON c.MemberID = m.ID
      JOIN Program p ON m.ProgramID = p.ID
      JOIN VendorLocation vl ON po.VendorLocationID = vl.ID
      WHERE p.Name = 'Ford QFC'
      AND PO.IsActive = 1
      AND CoachNetServiceAmount > 0
      AND PO.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued', 'Issued-Paid'))
      AND NOT EXISTS (
            SELECT *
            FROM Claim 
            WHERE Claim.PurchaseOrderID = PO.ID
            AND Claim.ClaimTypeID = (SELECT ID FROM ClaimType WHERE Name = 'FordQFC'))

END


GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Member_Payment_Balance]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_Payment_Balance] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_Member_Payment_Balance] 2
 CREATE PROCEDURE [dbo].[dms_Member_Payment_Balance]( 
  @serviceRequestID  INT = NULL
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
 	Select sum(
	CASE WHEN pt.Name = 'Credit'
	THEN -1 * p.Amount
	ELSE p.Amount
	END
	) AS Amount
From Payment p
Join ServiceRequest sr on sr.ID = p.ServiceRequestID
Join PaymentTransactionType pt on pt.ID = p.PaymentTransactionTypeID
Where
	sr.ID = @serviceRequestID
	 END 

GO

GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Mobile_Configuration]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Mobile_Configuration] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 /*
 *	-- KB : Added two parameters - memberID and membershipID.
 *	The stored procedure will be called in two cases:
 *	1. Lookup a mobile  / prior Case record using the callback number
 *	2. The stored procedure might return multiple member records when there are multiple matching Case records.
 *	3. The application allows user to pick one member from a prior case record and this sp would then be invoked just to update the related inbound call record.
 */
CREATE PROC dms_Mobile_Configuration(@programID INT = NULL,  
          @configurationType nvarchar(50) = NULL,  
          @configurationCategory nvarchar(50) = NULL,  
          @callBackNumber nvarchar(50) = NULL,  
          @inBoundCallID INT = NULL,
		  @memberID INT = NULL,
		  @membershipID INT = NULL)  
AS  
BEGIN  
	--Declare
	--@programID INT = 286,  
	--@configurationType nvarchar(50) = 5,  
	--@configurationCategory nvarchar(50) = 3,  
	--@callBackNumber nvarchar(50) = '1 9858791084',  
	--@inBoundCallID INT = 509092,
	--@memberID INT = NULL, --16432463,
	--@membershipID INT = NULL --14802600  
		  
	SET FMTONLY OFF  
	-- Output Values   
	DECLARE @unformattedNumber nvarchar(50) = NULL  
	DECLARE @isMobileEnabled BIT = NULL  
	DECLARE @searchCaseRecords BIT = 1
	DECLARE @appOrgName NVARCHAR(100) = NULL
	
	DECLARE @memberProgramID INT = NULL
	-- Temporary Holders  
	DECLARE       @ProgramInformation_Temp TABLE(  
		Name  NVARCHAR(MAX),  
		Value NVARCHAR(MAX),  
		ControlType INT NULL,  
		DataType NVARCHAR(MAX) NULL,  
		Sequence INT NULL,
		ProgramLevel INT NULL)  
	 
	 -- Lakshmi - Added on 7/24/14
	 DECLARE  @GetPrograms_Temp TABLE(  
		ProgramID INT NULL )  
	 
	DECLARE @Mobile_CallForService_Temp TABLE(  
		[PKID] [int]  NULL,  
		[MemberNumber] [nvarchar](50) NULL,  
		[GUID] [nvarchar](50) NULL,  
		[FirstName] [nvarchar](50) NULL,  
		[LastName] [nvarchar](50) NULL,  
		[MemberDevicePhoneNumber] [nvarchar](20) NULL,  
		[locationLatitude] [nvarchar](10) NULL,  
		[locationLongtitude] [nvarchar](10) NULL,  
		[serviceType] [nvarchar](100) NULL,  
		[ErrorCode] [int] NULL,  
		[ErrorMessage] [nvarchar](200) NULL,  
		[DateTime] [datetime] NULL,  
		[IsMobileEnabled] BIT,  
		[MemberID] INT,  
		[MembershipID] INT  ,
		[MemberProgramID] INT)
 

	IF ( @memberID IS NOT NULL)
		BEGIN
			
			UPDATE	InboundCall 
			SET		MemberID = @memberID   		
			WHERE	ID = @inBoundCallID 

			INSERT INTO @Mobile_CallForService_Temp
				([MemberID],[MembershipID],[IsMobileEnabled]) 
			VALUES
				(@memberID,@membershipID,@isMobileEnabled) 

		END
	ELSE
		BEGIN


			DECLARE @charIndex INT = 0  
			SELECT @charIndex = CHARINDEX('x',@callBackNumber,0)  

			IF @charIndex = 0  
				BEGIN  
					SET @charIndex = LEN(@callBackNumber)  
				END  
			ELSE  
				BEGIN  
					SET @charIndex = @charIndex -1  
				END  

		-- DEBUG:
		--PRINT @charIndex  
		--SELECT @callBackNumber
		
			SELECT @unformattedNumber = SUBSTRING(@callBackNumber,1,@charIndex)  
			SET @charIndex = 0  
			SELECT @charIndex = CHARINDEX(' ',@unformattedNumber,0)  
			SELECT @unformattedNumber = LTRIM(RTRIM(SUBSTRING(@unformattedNumber, @charIndex + 1, LEN(@unformattedNumber) - @charIndex)))  

		--DEBUG:
		--SELECT @unformattedNumber As UnformattedNumber, @callBackNumber AS CallbackNumber

	 
		-- Step 1 : Get the Program Information  
			;with wResultB AS  
			(    
				SELECT PC.Name,     
				PC.Value,     
				CT.Name AS ControlType,     
				DT.Name AS DataType,      
				PC.Sequence AS Sequence	,
				ROW_NUMBER() OVER ( PARTITION BY PC.Name ORDER BY PP.Sequence) AS [ProgramLevel]			    
				FROM ProgramConfiguration PC    
				 JOIN dbo.fnc_GetProgramsandParents(@programID)PP ON PP.ProgramID=PC.ProgramID    
				 JOIN [dbo].[fnc_GetProgramConfigurationForProgram](@programID,@configurationType) P ON P.ProgramConfigurationID = PC.ID    
				 LEFT JOIN ControlType CT ON PC.ControlTypeID = CT.ID    
				 LEFT JOIN DataType DT ON PC.DataTypeID = DT.ID    
			)  
			INSERT INTO @ProgramInformation_Temp SELECT * FROM wResultB  ORDER BY ProgramLevel, Sequence, Name   
		
			-- CR : 1225 - Start Tab - change process to lookup mobile phone number to incorporate appOrgName
			SELECT @appOrgName = Value FROM @ProgramInformation_Temp WHERE ProgramLevel = 1 AND Name = 'MobileAppOrg'
		
			--Lakshmi - Added on 7/24/2014
			INSERT INTO @GetPrograms_Temp ([ProgramID]) 
			((SELECT ProgramID FROM fnc_GetChildPrograms(@programID)
			UNION
			SELECT ProgramID FROM MemberSearchProgramGrouping
			WHERE ProgramID in(SELECT ProgramID FROM fnc_GetChildPrograms(@programID))))
		
			--DEBUG:  
			-- SELECT @appOrgName
			--SELECT * FROM @ProgramInformation_Temp  
	 
			--Step 2 :  
			-- Check Mobile is Enabled or NOT  
			IF EXISTS(SELECT * FROM @ProgramInformation_Temp WHERE Name = 'IsMobileEnabled' AND Value = 'yes')  
			BEGIN  
			--DEBUG:
			--PRINT 'Mobile config found'
				SET @isMobileEnabled = 1  
				SET @unformattedNumber  =  RTRIM(LTRIM(@unformattedNumber))  
				-- Get the Details FROM Mobile_CallForService  
				SELECT TOP 1 *  INTO #Mobile_CallForService_Temp  
					FROM Mobile_CallForService M  
					WHERE REPLACE(M.MemberDevicePhoneNumber,'-','') = @unformattedNumber  
					AND DATEDIFF(hh,M.[DateTime],GETDATE()) < 1  
					AND ISNULL(M.ErrorCode,0) = 0  
					AND appOrgName = @appOrgName -- CR : 1225 - Start Tab - change process to lookup mobile phone number to incorporate appOrgName
					ORDER BY M.[DateTime] DESC  

				IF((SELECT COUNT(*) FROM #Mobile_CallForService_Temp) >= 1)  
				BEGIN  
					--DEBUG:
					--PRINT 'Mobile record found'
				
					SET @searchCaseRecords = 0
				
					-- Try to find the member using the member number.
					
					SELECT  @memberID = RR.ID,  
					@membershipID = RR.MembershipID ,
					@memberProgramID = RR.ProgramID
					FROM  
					(  
						SELECT TOP 1 M.ID,  
							   M.MembershipID,
							   M.ProgramID   
							   FROM Membership MS 
						JOIN Member M ON MS.ID = M.MembershipID 
						JOIN Program P ON M.ProgramID=P.ID
						WHERE M.IsPrimary = 1 
						AND MS.MembershipNumber = 
						(SELECT MemberNumber FROM #Mobile_CallForService_Temp where membernumber IS NOT NULL AND memberNumber <> '') 
						AND (ISNULL(@ProgramID,0) = 0 OR M.ProgramID IN (SELECT * FROM @GetPrograms_Temp))  
					)RR  
					
					INSERT INTO @Mobile_CallForService_Temp
								([PKID],  
						[MemberNumber],  
						[GUID],  
						[FirstName],  
						[LastName],  
						[MemberDevicePhoneNumber],  
						[locationLatitude],  
						[locationLongtitude],  
						[serviceType],  
						[ErrorCode],  
						[ErrorMessage],  
						[DateTime],
						MemberID,
						MembershipID,
						IsMobileEnabled  ,
						MemberProgramID
						)   
						SELECT	[PKID],  
								[MemberNumber],  
								[GUID],  
								[FirstName],  
								[LastName],  
								[MemberDevicePhoneNumber],  
								[locationLatitude],  
								[locationLongtitude],  
								[serviceType],  
								[ErrorCode],  
								[ErrorMessage],  
								[DateTime],
								@memberID,
								@membershipID,
								@isMobileEnabled,
								@memberProgramID
						FROM #Mobile_CallForService_Temp
	  
							
					IF((SELECT COUNT(*) FROM @Mobile_CallForService_Temp) = 1) 
					BEGIN
			        
						UPDATE InboundCall SET MemberID = @memberID,
							 MobileID = (SELECT PKID FROM #Mobile_CallForService_Temp)  
							WHERE ID = @inBoundCallID 

						-- Create a case phone location record when there is lat/long information.
						IF EXISTS(	SELECT * FROM #Mobile_CallForService_Temp   
								WHERE ISNULL(locationLatitude,'') <> ''  
								AND ISNULL(locationLongtitude,'') <> ''  
							)  
						BEGIN
							INSERT INTO CasePhoneLocation(	CaseID,  
														PhoneNumber,  
														CivicLatitude,  
														CivicLongitude,  
														IsSMSAvailable,  
														LocationDate,  
														LocationAccuracy,  
														InboundCallID,  
														PhoneTypeID,  
														CreateDate)   
														VALUES(NULL,  
														@callBackNumber,  
														(SELECT  locationLatitude FROM #Mobile_CallForService_Temp),  
														(SELECT  locationLongtitude FROM #Mobile_CallForService_Temp),  
														1,  
														(SELECT  [DateTime] FROM #Mobile_CallForService_Temp),  
														'mobile',  
														@inBoundCallID,  
														(SELECT ID FROM PhoneType WHERE Name = 'Cell'),  
														GETDATE()  
														)  
						END
					END

					IF((SELECT COUNT(*) FROM @Mobile_CallForService_Temp) > 1)
					BEGIN
						--PRINT 'Update Inbound Call'
						UPDATE InboundCall 
						SET  MobileID = (SELECT PKID FROM #Mobile_CallForService_Temp)  
						WHERE ID = @inBoundCallID  
					END
				
					IF @memberID IS NULL
					BEGIN
						-- Search in prior cases when you don't get a member using the membernumber from the mobile record.
						SET @searchCaseRecords = 1 
					END
				
					DROP TABLE #Mobile_CallForService_Temp
			
				END  
				
			END
		
			IF ( @searchCaseRecords = 1 )  
			BEGIN 
				--PRINT 'Search Case Records'
		
				INSERT INTO @Mobile_CallForService_Temp
									([MemberID],[MembershipID],[IsMobileEnabled], [MemberProgramID]) 
					SELECT  DISTINCT M.ID,   
									M.MembershipID,
									@isMobileEnabled,
									C.ProgramID
					FROM [Case] C  
					JOIN Member M ON C.MemberID = M.ID 
					JOIN Program P ON M.ProgramID=P.ID		--Lakshmi
					WHERE C.ContactPhoneNumber = @callBackNumber 
					AND (ISNULL(@ProgramID,0) = 0 OR M.ProgramID IN (SELECT * FROM @GetPrograms_Temp))
					ORDER BY ID DESC
					
				IF((SELECT COUNT(*) FROM @Mobile_CallForService_Temp)= 0 OR (SELECT COUNT(*) FROM @Mobile_CallForService_Temp) = 1) 
				BEGIN
					--PRINT 'Update Inbound Call'
					UPDATE InboundCall 
					SET MemberID = @memberID   		
					WHERE ID = @inBoundCallID  
				END
			END  

		-- If one of the matching member IDs has an open SR then only return the associated Member, otherwise return all matching Members
		IF EXISTS (
			SELECT temp.*
			FROM @Mobile_CallForService_Temp temp
			JOIN [Case] c ON temp.MemberID = c.MemberID
			JOIN ServiceRequest sr ON c.ID = sr.CaseID
			WHERE sr.ServiceRequestStatusID IN (SELECT ID FROM ServiceRequestStatus WHERE Name IN ('Entry','Submitted','Dispatched'))
			)
			SELECT temp.*
			FROM @Mobile_CallForService_Temp temp
			JOIN [Case] c ON temp.MemberID = c.MemberID
			JOIN ServiceRequest sr ON c.ID = sr.CaseID
			WHERE sr.ServiceRequestStatusID IN (SELECT ID FROM ServiceRequestStatus WHERE Name IN ('Entry','Submitted','Dispatched'))
		ELSE
			SELECT * FROM @Mobile_CallForService_Temp     
	END     

END

GO

GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_PO_Issue_Hagerty_EventMail_Tag_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_PO_Issue_Hagerty_EventMail_Tag_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC [dms_PO_Issue_Hagerty_EventMail_Tag_Get] 310520
 CREATE PROCEDURE [dbo].[dms_PO_Issue_Hagerty_EventMail_Tag_Get]( 
  @POID Int = NULL  
 ) 
 AS 
 BEGIN 

	DECLARE @Result TABLE(ColumnName NVARCHAR(MAX),
						  ColumnValue NVARCHAR(MAX)) 

	DECLARE @XmlString AS XML

	SET @XmlString = (
	SELECT m.ID AS MemberId
	
	, ISNULL(ms.MembershipNumber,'') AS MemberNumber
	
	, ISNULL(m.FirstName,'') + ' ' + ISNULL(m.LastName,'') AS MemberName

	, c.VehicleYear + ' ' + CASE WHEN c.VehicleMake = 'Other' THEN c.VehicleMakeOther ELSE c.VehicleMake END + ' ' + CASE WHEN c.VehicleModel = 'Other' THEN c.VehicleModelOther ELSE c.VehicleModel END AS MemberVehicleDesc -- coalesce 

	, ISNULL(c.ContactPhoneNumber,' ') AS MemberCallback 

	, sr.ID AS SRNumber

	, CONVERT (VARCHAR(20),sr.CreateDate,100) + ' CST' AS SRCallDateTime 

	, ISNULL(pc.Name,'  ') AS SRType

	, ISNULL(sr.ServiceLocationAddress,' ') AS SRLocation

	, ISNULL(sr.DestinationAddress,' ') AS SRDestination

	, ISNULL(po.PurchaseOrderNumber,' ') AS PONumber

	, CONVERT(VARCHAR(20),po.IssueDate,100) + ' CST' AS POIssueDateTime

	, ISNULL(v.Name,' ') AS POVendor

	, CONVERT(VARCHAR(20),ISNULL(po.ETAMinutes,' ')) + ' minutes' AS SRETA
	
	, ISNULL(m.ClientMemberType, ' ') AS ClientMemberType
	 
	, ISNULL(cl.Name,' ') AS Client
	
	, '888-310-8020' AS DispatchPhone
	
	, ISNULL(p.Name,' ')  AS ProgramName
	
	,ISNULL(p.Code,' ') AS ProgramCode
	
	FROM PurchaseOrder po (NOLOCK)

	JOIN ServiceRequest sr (NOLOCK) ON sr.ID = po.ServiceRequestID

	LEFT JOIN ProductCategory pc (NOLOCK) ON pc.ID = sr.ProductCategoryID

	JOIN [Case] c (NOLOCK) ON c.ID = sr.CaseID

	JOIN Member m (NOLOCK) ON m.ID = c.MemberID

	JOIN Membership ms (NOLOCK) ON ms.ID = m.MembershipID

	JOIN VendorLocation vl (NOLOCK) ON vl.ID = po.VendorLocationID

	JOIN Vendor v (NOLOCK) ON v.ID = vl.VendorID
	
	JOIN Program p (NOLOCK) ON c.ProgramID = p.ID
	
	JOIN Client cl (NOLOCK) ON cl.ID = p.ClientID
	WHERE po.ID = @POID FOR XML AUTO)

	INSERT INTO @Result(ColumnName,ColumnValue)
    SELECT CAST(x.v.query('local-name(.)') AS NVARCHAR(MAX)) As AttributeName,
			    x.v.value('.','NVARCHAR(MAX)') AttributeValue
    FROM @XmlString.nodes('//@*') x(v)
    ORDER BY AttributeName

	SELECT * FROM @Result

END
GO

GO

/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_PurchaseOrderTemplate_select]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_PurchaseOrderTemplate_select]
GO
/****** Object:  StoredProcedure [dbo].[dms_users_list]    Script Date: 07/03/2012 17:56:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [dms_PurchaseOrderTemplate_select] 108,1
CREATE PROCEDURE [dbo].[dms_PurchaseOrderTemplate_select]   
   @PurchaseOrderID int,  
   @ContactLogID int  
 AS   
 BEGIN   
    
 SET NOCOUNT ON  
  
DECLARE @TalkedTo nvarchar(50)  
DECLARE @FaxNo nvarchar(50)  
DECLARE @VendorCallback nvarchar(50)
DECLARE @VendorBilling nvarchar(50)
  
SELECT @TalkedTo = CL.TalkedTo,   
@FaxNo = REPLACE(CL.PhoneNumber, ' ','')   
FROM ContactLog CL  
WHERE CL.ID = @ContactLogID  
  
 
SELECT   
@TalkedTo as POTo,  
V.Name as VendorName,  
V.VendorNumber,  
@FaxNo as FaxPhoneNumber,  
ACFrom.Value as POFrom,  
ACVendorCallbackPhone.Value as VendorCallback,
ACBilling.Value as VendorBilling,
PO.IssueDate,  
--CONVERT(VARCHAR(8), PO.IssueDate, 108) + '-' + CONVERT(VARCHAR(10), PO.IssueDate, 101) as IssueDate,
PO.PurchaseOrderNumber,  
PO.CreateBy as OpenedBy,  
COALESCE(PC.Name, PC2.Name) as ServiceName,  
PO.EtaMinutes,  
CASE WHEN Isnull(C.IsSafe,1) = 1 THEN 'Y'  
ELSE 'N'  
END AS Safe,  
CASE WHEN Isnull(PO.IsMemberAmountCollectedByVendor,0) = 1 THEN 'Y'  
ELSE 'N'  
END AS MemberPay,  
REPLACE(RTRIM(COALESCE(M.FirstName, '') +     
          COALESCE(' ' + LEFT(M.MiddleName,1), '') +    
          COALESCE(' ' + M.LastName, '')), '  ', ' ')     
          as MemberName,     
MS.MembershipNumber,  
dbo.fnc_FormatPhoneNumber(C.ContactPhoneNumber,0) as ContactPhoneNumber,  
dbo.fnc_FormatPhoneNumber(C.ContactAltPhoneNumber,0) as ContactAltPhoneNumber,  
SR.ServiceLocationDescription,  
SR.ServiceLocationAddress,  
SR.ServiceLocationCrossStreet1 + COALESCE(' & ' + SR.ServicelocationCrossStreet2, '') as ServiceLocationCrossStreet,  
SR.ServiceLocationCity + ', ' + SR.ServiceLocationStateProvince as CityState,  
SR.ServiceLocationPostalCode as Zip,  
SR.DestinationDescription,  
SR.DestinationAddress,  
SR.DestinationCrossStreet1 + COALESCE(' & ' + SR.DestinationCrossStreet2, '') as DestinationCrossStreet,  
SR.DestinationCity + ', ' + SR.ServiceLocationStateProvince as DestinationCityState,  
SR.DestinationPostalCode as DestinationZip,  
C.VehicleYear,   
--C.VehicleMake,  
--C.VehicleModel,  
CASE c.VehicleMake WHEN 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END AS VehicleMake,
CASE C.VehicleModel WHEN 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END AS VehicleModel,
C.VehicleDescription,  
C.VehicleColor,  
C.VehicleLicenseState + COALESCE('/' + C.VehicleLicenseNumber,'') as License,  
C.VehicleVIN,  
C.VehicleChassis,  
C.VehicleLength,  
C.VehicleEngine,  
REPLACE(RVT.Name,'Class','') as Class  
FROM PurchaseOrder PO  
JOIN ServiceRequest SR ON PO.ServiceRequestID = SR.ID  
JOIN [Case] C ON C.ID = SR.CaseID   
JOIN VendorLocation VL on VL.ID = PO.VendorLocationID   
JOIN Vendor V on V.ID = VL.VendorID   
JOIN ApplicationConfiguration ACFrom ON ACFrom.Name = 'POFaxFrom'  
JOIN ApplicationConfiguration ACVendorCallbackPhone ON ACVendorCallbackPhone.Name = 'VendorCallback'  
JOIN ApplicationConfiguration ACBilling ON ACBilling.Name = 'VendorBilling'  
LEFT JOIN Product P ON P.ID = PO.ProductID
LEFT JOIN ProductCategory PC ON PC.ID = P.ProductCategoryID
JOIN ProductCategory PC2 ON PC2.ID = SR.ProductCategoryID
JOIN Member M on M.ID = C.MemberID   
JOIN Membership MS ON MS.ID = M.MembershipID   
LEFT JOIN RVType RVT ON RVT.ID = C.VehicleRVTypeID   
WHERE PO.ID = @PurchaseOrderID   
  
END


GO

GO

/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_servicerequest_get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_servicerequest_get]
GO
/****** Object:  StoredProcedure [dbo].[dms_servicerequest_get]    Script Date: 07/03/2012 17:56:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC  [dbo].[dms_servicerequest_get] 1467
CREATE PROCEDURE [dbo].[dms_servicerequest_get](
   @serviceRequestID INT=NULL
)
AS
BEGIN
SET NOCOUNT ON

declare @MemberID INT=NULL
-- GET CASE ID
SET   @MemberID =(SELECT CaseID FROM [ServiceRequest](NOLOCK) WHERE ID = @serviceRequestID)
-- GET Member ID
SET @MemberID =(SELECT MemberID FROM [Case](NOLOCK) WHERE ID = @MemberID)

DECLARE @ProductID INT
SET @ProductID =NULL
SELECT  @ProductID = PrimaryProductID FROM ServiceRequest(NOLOCK) WHERE ID = @serviceRequestID

DECLARE @memberEntityID INT
DECLARE @vendorLocationEntityID INT
DECLARE @otherReasonID INT
DECLARE @dispatchPhoneTypeID INT

SET @memberEntityID = (SELECT ID FROM Entity(NOLOCK) WHERE Name ='Member')
SET @vendorLocationEntityID = (SELECT ID FROM Entity(NOLOCK) WHERE Name ='VendorLocation')
SET @otherReasonID = (Select ID From PurchaseOrderCancellationReason(NOLOCK) Where Name ='Other')
SET @dispatchPhoneTypeID = (SELECT ID FROM PhoneType(NOLOCK) WHERE Name ='Dispatch')

SELECT DISTINCT
		-- Service Request Data Section
		-- Column 1		
		SR.CaseID,
		C.IsDeliveryDriver,
		SR.ID AS [RequestNumber],
		SRS.Name AS [Status],
		SRP.Name AS [Priority],
		SR.CreateDate AS [CreateDate],
		SR.CreateBy AS [CreateBy],
		SR.ModifyDate AS [ModifyDate],
		SR.ModifyBy AS [ModifyBy],
		-- Column 2
		NA.Name AS [NextAction],
		SR.NextActionScheduledDate AS [NextActionScheduledDate],
		SASU.FirstName +' '+ SASU.LastName AS [NextActionAssignedTo],
		CLS.Name AS [ClosedLoop],
		SR.ClosedLoopNextSend AS [ClosedLoopNextSend],
		-- Column 3
		CASE WHEN SR.IsPossibleTow = 1 THEN PC.Name +'/Possible Tow'ELSE PC.Name +''END AS [ServiceCategory],
		CASE
			WHEN SRS.Name ='Dispatched'
				  THEN CONVERT(VARCHAR(6),DATEDIFF(SECOND,sr.CreateDate,GETDATE())/3600)+':'
						+RIGHT('0'+CONVERT(VARCHAR(2),(DATEDIFF(SECOND,sr.CreateDate,GETDATE())%3600)/60),2)
			ELSE''
		END AS [Elapsed],
		(SELECT MAX(IssueDate)FROM PurchaseOrder(NOLOCK) Where ServiceRequestID = @ServiceRequestID) AS [PoMaxIssueDate],
		(SELECT MAX(ETADate)FROM PurchaseOrder(NOLOCK) Where ServiceRequestID = @ServiceRequestID) AS [PoMaxETADate],
		SR.DataTransferDate AS [DataTransferDate],

		-- Member data  
		M.ClientMemberType,
		REPLACE(RTRIM(
		COALESCE(m.FirstName,'')+
		COALESCE(' '+left(m.MiddleName,1),'')+
		COALESCE(' '+ m.LastName,'')+
		COALESCE(' '+ m.Suffix,'')
		),'  ',' ')AS [Member],
		MS.MembershipNumber,
		C.MemberStatus,
		CL.Name AS [Client],
		P.ID AS ProgramID,
		P.Name AS [ProgramName],
		CONVERT(varchar(10),M.MemberSinceDate,101)AS [MemberSince],
		CONVERT(varchar(10),M.ExpirationDate,101)AS [ExpirationDate],
		MS.ClientReferenceNumber as [ClientReferenceNumber],
		ISNULL((SELECT NAME FROM PhoneType(NOLOCK) WHERE ID = c.ContactPhoneTypeID),'')AS [CallbackPhoneType],
		C.ContactPhoneNumber AS [CallbackNumber],
		ISNULL((SELECT NAME FROM PhoneType(NOLOCK) WHERE ID = c.ContactAltPhoneTypeID),'')AS [AlternatePhoneType],
		C.ContactAltPhoneNumber AS [AlternateNumber],
		ISNULL(MA.Line1,'')AS Line1,
		ISNULL(MA.Line2,'')AS Line2,
		ISNULL(MA.Line3,'')AS Line3,
		REPLACE(RTRIM(
			COALESCE(MA.City,'')+
			COALESCE(', '+RTRIM(MA.StateProvince),'')+
			COALESCE(' '+LTRIM(MA.PostalCode),'')+
			COALESCE(' '+ MA.CountryCode,'')
			),' ',' ')AS MemberCityStateZipCountry,

		-- Vehicle Section
		-- Vehcile 
		ISNULL(RTRIM(COALESCE(c.VehicleYear +' ','')+
		COALESCE(CASE c.VehicleMake WHEN'Other'THEN C.VehicleMakeOther ELSE C.VehicleMake END+' ','')+
		COALESCE(CASE C.VehicleModel WHEN'Other'THEN C.VehicleModelOther ELSE C.VehicleModel END,'')),' ')AS [YearMakeModel],
		VT.Name +' - '+ VC.Name AS [VehicleTypeAndCategory],
		C.VehicleColor AS [VehicleColor],
		C.VehicleVIN AS [VehicleVIN],
		COALESCE(C.VehicleLicenseState +'-','')+COALESCE(c.VehicleLicenseNumber,'')AS [License],
		C.VehicleDescription,
		-- For vehicle type = RV only  
		RVT.Name AS [RVType],
		C.VehicleChassis AS [VehicleChassis],
		C.VehicleEngine AS [VehicleEngine],
		C.VehicleTransmission AS [VehicleTransmission],
		C.VehicleCurrentMileage AS [Mileage],
		-- Location  
		SR.ServiceLocationAddress +' '+ SR.ServiceLocationCountryCode AS [ServiceLocationAddress],
		SR.ServiceLocationDescription,
		-- Destination
		SR.DestinationAddress +' '+ SR.DestinationCountryCode AS [DestinationAddress],
		SR.DestinationDescription,

		-- Service Section 
		CASE
			WHEN SR.IsPossibleTow = 1 
			THEN PC.Name +'/Possible Tow'
			ELSE PC.Name
		END AS [ServiceCategorySection],
		SR.PrimaryCoverageLimit As CoverageLimit,
		CASE
			WHEN C.IsSafe IN(NULL,1)
			THEN'Yes'
			ELSE'No'
		END AS [Safe],
		SR.PrimaryProductID,
		(SELECT Name FROM Product WHERE ID = SR.PrimaryProductID) AS PrimaryProductName,
		SR.PrimaryServiceEligiblityMessage,
		SR.SecondaryProductID,
		(SELECT Name FROM Product WHERE ID = SR.SecondaryProductID) AS SecondaryProductName,
		SR.SecondaryServiceEligiblityMessage,
		SR.IsPrimaryOverallCovered,
		SR.IsSecondaryOverallCovered,
		SR.IsPossibleTow,
		

		-- Service Q&A's


		---- Service Provider Section  
		--CASE 
		--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NOT NULL THEN 'Contracted'
		--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NULL THEN 'Not Contracted'
		--	WHEN c.ID IS NOT NULL THEN 'Contracted' 
		--	ELSE 'Not Contracted'
		--	END as ContractStatus,
		CASE WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted' ELSE 'Not Contracted' END AS ContractStatus,
		V.Name AS [VendorName],
		V.ID AS [VendorID],
		V.VendorNumber AS [VendorNumber],
		(SELECT TOP 1 PE.PhoneNumber
			FROM PhoneEntity PE
			WHERE PE.RecordID = VL.ID
			AND PE.EntityID = @vendorLocationEntityID
			AND PE.PhoneTypeID = @dispatchPhoneTypeID
			ORDER BY PE.ID DESC
		) AS [VendorLocationPhoneNumber] ,
		VLA.Line1 AS [VendorLocationLine1],
		VLA.Line2 AS [VendorLocationLine2],
		VLA.Line3 AS [VendorLocationLine3],
		REPLACE(RTRIM(
			COALESCE(VLA.City,'')+
			COALESCE(', '+RTRIM(VLA.StateProvince),'')+
			COALESCE(' '+LTRIM(VLA.PostalCode),'')+
			COALESCE(' '+ VLA.CountryCode,'')
			),' ',' ')AS VendorCityStateZipCountry,
		-- PO data
		convert(int,PO.PurchaseOrderNumber) AS [PONumber],
		PO.LegacyReferenceNumber,
		--convert(int,PO.ID) AS [PONumber],
		POS.Name AS [POStatus],
		CASE
				WHEN PO.CancellationReasonID = @otherReasonID
				THEN PO.CancellationReasonOther 
				ELSE ISNULL(CR.Name,'')
		END AS [CancelReason],
		PO.PurchaseOrderAmount AS [POAmount],
		POPC.Name AS [ServiceType],
		PO.IssueDate AS [IssueDate],
		PO.ETADate AS [ETADate],
		PO.DataTransferDate AS [ExtractDate],

		-- Other
		CASE WHEN C.AssignedToUserID IS NOT NULL
			THEN'*'+ISNULL(ASU.FirstName,'')+' '+ISNULL(ASU.LastName,'')
			ELSE ISNULL(SASU.FirstName,'')+' '+ISNULL(SASU.LastName,'')
		END AS [AssignedTo],
		C.AssignedToUserID AS [AssignedToID],
      
      -- Vendor Invoice Details
		VI.InvoiceDate,
		CASE	WHEN PT.Name = 'ACH' 
		THEN 'ACH'
				WHEN PT.Name = 'Check'
		THEN VI.PaymentNumber
		ELSE ''
		END AS PaymentType,
		
		VI.PaymentAmount,
		VI.PaymentDate,
		VI.CheckClearedDate,
		PP.Name AS ProductProvider,
		PP.PhoneNumber AS ProductProviderNumber,
		SR.ProviderClaimNumber

FROM [ServiceRequest](NOLOCK) SR  
JOIN [Case](NOLOCK) C ON C.ID = SR.CaseID  
JOIN [ServiceRequestStatus](NOLOCK) SRS ON SR.ServiceRequestStatusID = SRS.ID  
LEFT JOIN [ServiceRequestPriority](NOLOCK) SRP ON SR.ServiceRequestPriorityID = SRP.ID   
LEFT JOIN [Program](NOLOCK) P ON C.ProgramID = P.ID   
LEFT JOIN [Client](NOLOCK) CL ON P.ClientID = CL.ID  
LEFT JOIN [Member](NOLOCK) M ON C.MemberID = M.ID  
LEFT JOIN [Membership](NOLOCK) MS ON M.MembershipID = MS.ID  
LEFT JOIN [AddressEntity](NOLOCK) MA ON M.ID = MA.RecordID  
            AND MA.EntityID = @memberEntityID
LEFT JOIN [Country](NOLOCK) MCNTRY ON MA.CountryCode = MCNTRY.ISOCode  
LEFT JOIN [Country](NOLOCK) LCNTRY ON SR.ServiceLocationCountryCode = LCNTRY.ISOCode  
LEFT JOIN [Country](NOLOCK) DCNTRY ON SR.DestinationCountryCode = DCNTRY.ISOCode  
LEFT JOIN [VehicleType](NOLOCK) VT ON C.VehicleTypeID = VT.ID  
LEFT JOIN [VehicleCategory](NOLOCK) VC ON C.VehicleCategoryID = VC.ID  
LEFT JOIN [RVType](NOLOCK) RVT ON C.VehicleRVTypeID = RVT.ID  
LEFT JOIN [ProductCategory](NOLOCK) PC ON PC.ID = SR.ProductCategoryID  
LEFT JOIN [User](NOLOCK) ASU ON C.AssignedToUserID = ASU.ID  
LEFT OUTER JOIN [User](NOLOCK) SASU ON SR.NextActionAssignedToUserID = SASU.ID  
LEFT JOIN [PurchaseOrder](NOLOCK) PO ON PO.ServiceRequestID = SR.ID  AND PO.IsActive = 1 
LEFT JOIN [PurchaseOrderStatus](NOLOCK) POS ON PO.PurchaseOrderStatusID = POS.ID
LEFT JOIN [PurchaseOrderCancellationReason](NOLOCK) CR ON PO.CancellationReasonID = CR.ID
LEFT JOIN [Product](NOLOCK) PR ON PO.ProductID = PR.ID
LEFT JOIN [ProductCategory](NOLOCK) POPC ON PR.ProductCategoryID = POPC.ID
LEFT JOIN [VendorLocation](NOLOCK) VL ON PO.VendorLocationID = VL.ID  
LEFT JOIN [AddressEntity](NOLOCK) VLA ON VL.ID = VLA.RecordID 
            AND VLA.EntityID =@vendorLocationEntityID
LEFT JOIN [Vendor](NOLOCK) V ON VL.VendorID = V.ID 
--LEFT JOIN [Contract](NOLOCK) CON on CON.VendorID = V.ID and CON.IsActive = 1 and CON.ContractStatusID = (Select ID From ContractStatus Where Name = 'Active')
LEFT JOIN [ClosedLoopStatus](NOLOCK) CLS ON SR.ClosedLoopStatusID = CLS.ID 
LEFT JOIN [NextAction](NOLOCK) NA ON SR.NextActionID = NA.ID

--Join to get information needed to determine Vendor Contract status ********************
--LEFT OUTER JOIN (
--      SELECT DISTINCT vr.VendorID, vr.ProductID
--      FROM dbo.fnGetCurrentProductRatesByVendorLocation() vr 
--      ) DefaultVendorRates ON v.ID = DefaultVendorRates.VendorID And @ProductID = DefaultVendorRates.ProductID
LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID
LEFT JOIN [VendorInvoice] VI WITH (NOLOCK) ON PO.ID = VI.PurchaseOrderID
LEFT JOIN [PaymentType] PT WITH (NOLOCK) ON VI.PaymentTypeID = PT.ID
--LEFT Join [MemberProduct]  MP (NOLOCK) ON (
--	MP.MemberID = C.MemberID      
--				OR
--	(MP.MemberID IS NULL AND MP.MembershipID = (SELECT MembershipID FROM Member WHERE ID = C.MemberID))
--	AND 
--	(MP.VIN IS NULL OR MP.VIN = C.VehicleVIN)
--)
LEFT JOIN [ProductProvider] PP (NOLOCK) ON PP.ID = SR.ProviderID
WHERE SR.ID = @serviceRequestID


END

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_servicerequest_history_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_servicerequest_history_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = '<ROW><Filter IDType="Service Request" IDValue="1234" NameType="" NameValue="" LastName="" FilterType = "StartsWith" FromDate = "" ToDate = "" Preset ="" Clients ="1" Programs ="" ServiceRequestStatuses = "" ServiceTypes ="" IsGOA = "" IsRedispatched = "" IsPossibleTow ="" VehicleType ="1" VehicleYear ="2012" VehicleMake = "" VehicleModel = "" PaymentByCheque = "" PaymentByCard = "" MemberPaid ="" POStatuses =""/></ROW>', @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
-- EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = NULL, @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
-- EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = '<ROW><Filter IDType="Service Request" IDValue="2"/></ROW>', @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'

CREATE PROCEDURE [dbo].[dms_servicerequest_history_list]( 
	@whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10   
 , @sortColumn nvarchar(100)  = 'RequestNumber'   
 , @sortOrder nvarchar(100) = 'ASC'
 , @userID UNIQUEIDENTIFIER = NULL
) 
AS
BEGIN
	
	SET FMTONLY OFF;
	-- Temporary tables to hold the results until the final resultset.
	CREATE TABLE #Raw	
	(
		RequestNumber INT NOT NULL,
		CaseID INT NOT NULL,
		ProgramID INT NULL,
		Program NVARCHAR(50) NULL,
		ClientID INT NULL,
		Client NVARCHAR(50) NULL,
		FirstName NVARCHAR(50)  NULL ,    
		LastName NVARCHAR(50)  NULL ,  
		MiddleName NVARCHAR(50)  NULL ,  
		Suffix NVARCHAR(50)  NULL ,    
		Prefix NVARCHAR(50)  NULL ,
		MemberNumber NVARCHAR(50) NULL, 
		CreateDate DATETIME NULL,
		POCreateBy NVARCHAR(50) NULL,
		POModifyBy NVARCHAR(50) NULL,
		SRCreateBy NVARCHAR(50) NULL,
		SRModifyBy NVARCHAR(50) NULL,
		VIN NVARCHAR(50) NULL,
		VehicleTypeID INT NULL,
		VehicleType NVARCHAR(50) NULL,
		ServiceTypeID INT NULL, 
		ServiceType nvarchar(100) NULL,		 
		StatusID INT NULL,
		[Status] NVARCHAR(100) NULL,
		PriorityID INT NULL,
		[Priority] NVARCHAR(100) NULL,
		ISPName NVARCHAR(255) NULL,
		VendorNumber NVARCHAR(50) NULL,
		PONumber NVARCHAR(50) NULL,
		PurchaseOrderStatusID INT NULL,
		PurchaseOrderStatus NVARCHAR(50) NULL, 
		PurchaseOrderAmount money NULL,
		AssignedToUserID INT NULL,
		NextActionAssignedToUserID INT NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow BIT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,
		VehicleMakeOther NVARCHAR(255) NULL,
		VehicleModel NVARCHAR(255) NULL,
		VehicleModelOther NVARCHAR(255) NULL,		
		PaymentByCard BIT NULL,
		POCreateDate DATETIME NULL
	)
	
	CREATE TABLE #Filtered	
	(
		RequestNumber INT NOT NULL,
		CaseID INT NOT NULL,
		ProgramID INT NULL,
		Program NVARCHAR(50) NULL,
		ClientID INT NULL,
		Client NVARCHAR(50) NULL,
		FirstName NVARCHAR(50)  NULL ,    
		LastName NVARCHAR(50)  NULL ,  
		MiddleName NVARCHAR(50)  NULL ,  
		Suffix NVARCHAR(50)  NULL ,    
		Prefix NVARCHAR(50)  NULL , 
		MemberNumber NVARCHAR(50) NULL,
		CreateDate DATETIME NULL,
		POCreateBy NVARCHAR(50) NULL,
		POModifyBy NVARCHAR(50) NULL,
		SRCreateBy NVARCHAR(50) NULL,
		SRModifyBy NVARCHAR(50) NULL,
		VIN NVARCHAR(50) NULL,
		VehicleTypeID INT NULL,
		VehicleType NVARCHAR(50) NULL,
		ServiceTypeID INT NULL, 
		ServiceType nvarchar(100) NULL,		 
		StatusID INT NULL,
		[Status] NVARCHAR(100) NULL,
		PriorityID INT NULL,
		[Priority] NVARCHAR(100) NULL,
		ISPName NVARCHAR(255) NULL,
		VendorNumber NVARCHAR(50) NULL,
		PONumber NVARCHAR(50) NULL,
		PurchaseOrderStatusID INT NULL,
		PurchaseOrderStatus NVARCHAR(50) NULL, 
		PurchaseOrderAmount money NULL,
		AssignedToUserID INT NULL,
		NextActionAssignedToUserID INT NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow BIT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,
		VehicleMakeOther NVARCHAR(255) NULL,
		VehicleModel NVARCHAR(255) NULL,
		VehicleModelOther NVARCHAR(255) NULL,		
		PaymentByCard BIT NULL,
		POCreateDate DATETIME NULL
	)
	
	CREATE TABLE #Formatted	
	(
		RequestNumber INT NOT NULL,
		CaseID INT NOT NULL,
		ProgramID INT NULL,
		Program NVARCHAR(50) NULL,
		ClientID INT NULL,
		Client NVARCHAR(50) NULL,
		MemberName NVARCHAR(255)  NULL ,
		MemberNumber NVARCHAR(50) NULL,    		
		CreateDate DATETIME NULL,
		POCreateBy NVARCHAR(50) NULL,
		POModifyBy NVARCHAR(50) NULL,
		SRCreateBy NVARCHAR(50) NULL,
		SRModifyBy NVARCHAR(50) NULL,
		VIN NVARCHAR(50) NULL,
		VehicleTypeID INT NULL,
		VehicleType NVARCHAR(50) NULL,
		ServiceTypeID INT NULL, 
		ServiceType nvarchar(100) NULL,		 
		StatusID INT NULL,
		[Status] NVARCHAR(100) NULL,
		PriorityID INT NULL,
		[Priority] NVARCHAR(100) NULL,
		ISPName NVARCHAR(255) NULL,
		VendorNumber NVARCHAR(50) NULL,
		PONumber NVARCHAR(50) NULL,
		PurchaseOrderStatusID INT NULL,
		PurchaseOrderStatus NVARCHAR(50) NULL, 
		PurchaseOrderAmount money NULL,
		AssignedToUserID INT NULL,
		NextActionAssignedToUserID INT NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow BIT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,		
		VehicleModel NVARCHAR(255) NULL,		
		PaymentByCard BIT NULL
	)
	
	CREATE TABLE #Sorted
	(
		RowNum INT NOT NULL IDENTITY(1,1),
		RequestNumber INT NOT NULL,
		CaseID INT NOT NULL,
		ProgramID INT NULL,
		Program NVARCHAR(50) NULL,
		ClientID INT NULL,
		Client NVARCHAR(50) NULL,
		MemberName NVARCHAR(255)  NULL , 
		MemberNumber NVARCHAR(50) NULL,   		
		CreateDate DATETIME NULL,
		POCreateBy NVARCHAR(50) NULL,
		POModifyBy NVARCHAR(50) NULL,
		SRCreateBy NVARCHAR(50) NULL,
		SRModifyBy NVARCHAR(50) NULL,
		VIN NVARCHAR(50) NULL,
		VehicleTypeID INT NULL,
		VehicleType NVARCHAR(50) NULL,
		ServiceTypeID INT NULL, 
		ServiceType nvarchar(100) NULL,		 
		StatusID INT NULL,
		[Status] NVARCHAR(100) NULL,
		PriorityID INT NULL,
		[Priority] NVARCHAR(100) NULL,
		ISPName NVARCHAR(255) NULL,
		VendorNumber NVARCHAR(50) NULL,
		PONumber NVARCHAR(50) NULL,
		PurchaseOrderStatusID INT NULL,
		PurchaseOrderStatus NVARCHAR(50) NULL, 
		PurchaseOrderAmount money NULL,
		AssignedToUserID INT NULL,
		NextActionAssignedToUserID INT NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow BIT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,
		VehicleModel NVARCHAR(255) NULL,
		PaymentByCard BIT NULL
	)
	
	CREATE TABLE #tmpVehicle
	(
		VIN NVARCHAR(50) NULL,
		MemberID INT NULL,
		MembershipID INT NULL
	)
	
	DECLARE @totalRows INT = 0

	DECLARE @tmpWhereClause TABLE
	(	
		IDType NVARCHAR(255) NULL UNIQUE NonClustered,
		IDValue NVARCHAR(255) NULL,
		NameType NVARCHAR(255) NULL,
		NameValue NVARCHAR(255) NULL,
		LastName NVARCHAR(255) NULL, -- If name type = Member, then firstname goes into namevalue and last name goes into this field.
		FilterType NVARCHAR(100) NULL,
		FromDate DATETIME NULL,
		ToDate DATETIME NULL,
		Preset NVARCHAR(100) NULL,
		Clients NVARCHAR(MAX) NULL,
		Programs NVARCHAR(MAX) NULL,
		ServiceRequestStatuses NVARCHAR(MAX) NULL,
		ServiceTypes NVARCHAR(MAX) NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow  BIT NULL,		
		VehicleType INT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,
		VehicleMakeOther NVARCHAR(255) NULL,
		VehicleModel NVARCHAR(255) NULL,
		VehicleModelOther NVARCHAR(255) NULL,
		PaymentByCheque BIT NULL,
		PaymentByCard BIT NULL,
		MemberPaid BIT NULL,
		POStatuses NVARCHAR(MAX) NULL
	)
	
	DECLARE @IDType NVARCHAR(255) ,
			@IDValue NVARCHAR(255) ,
			@NameType NVARCHAR(255) ,
			@NameValue NVARCHAR(255) ,
			@LastName NVARCHAR(255) , 
			@FilterType NVARCHAR(100) ,
			@FromDate DATETIME ,
			@ToDate DATETIME ,
			@Preset NVARCHAR(100) ,
			@Clients NVARCHAR(MAX) ,
			@Programs NVARCHAR(MAX) ,
			@ServiceRequestStatuses NVARCHAR(MAX) ,
			@ServiceTypes NVARCHAR(MAX) ,
			@IsGOA BIT ,
			@IsRedispatched BIT ,
			@IsPossibleTow  BIT ,		
			@VehicleType INT ,
			@VehicleYear INT ,
			@VehicleMake NVARCHAR(255) ,
			@VehicleMakeOther NVARCHAR(255) ,
			@VehicleModel NVARCHAR(255) ,
			@VehicleModelOther NVARCHAR(255) ,
			@PaymentByCheque BIT ,
			@PaymentByCard BIT ,
			@MemberPaid BIT ,
			@POStatuses NVARCHAR(MAX) 
	
	DECLARE @idoc int
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML 
	
	INSERT INTO @tmpWhereClause  
	SELECT	IDType,
			IDValue,
			NameType,
			NameValue,
			LastName,
			FilterType,
			FromDate,
			ToDate,
			Preset,
			Clients,
			Programs,
			ServiceRequestStatuses,
			ServiceTypes,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleType,
			VehicleYear,
			VehicleMake,
			VehicleMakeOther,
			VehicleModel,
			VehicleModelOther,
			PaymentByCheque,
			PaymentByCard,
			MemberPaid,
			POStatuses
	FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH ( 
	
			IDType NVARCHAR(255) ,
			IDValue NVARCHAR(255) ,
			NameType NVARCHAR(255) ,
			NameValue NVARCHAR(255) ,
			LastName NVARCHAR(255) ,
			FilterType NVARCHAR(100) ,
			FromDate DATETIME ,
			ToDate DATETIME ,
			Preset NVARCHAR(100) ,
			Clients NVARCHAR(MAX) ,
			Programs NVARCHAR(MAX) ,
			ServiceRequestStatuses NVARCHAR(MAX) ,
			ServiceTypes NVARCHAR(MAX) ,
			IsGOA BIT,
			IsRedispatched BIT,
			IsPossibleTow BIT,			
			VehicleType INT ,
			VehicleYear INT ,
			VehicleMake NVARCHAR(255) ,
			VehicleMakeOther NVARCHAR(255) ,
			VehicleModel NVARCHAR(255) ,
			VehicleModelOther NVARCHAR(255) ,
			PaymentByCheque BIT ,
			PaymentByCard BIT ,
			MemberPaid BIT ,
			POStatuses NVARCHAR(MAX) 	
	)
	
	-- DEBUG:
	--SELECT * FROM @tmpWhereClause
	

	DECLARE @strClients NVARCHAR(MAX)
	DECLARE @tmpClients TABLE
	(
		ID INT NOT NULL
	)	
	DECLARE @strPrograms NVARCHAR(MAX)
	DECLARE @tmpPrograms TABLE
	(
		ID INT NOT NULL
	)
	DECLARE @strServiceRequestStatuses NVARCHAR(MAX)
	DECLARE @tmpServiceRequestStatuses TABLE
	(
		ID INT NOT NULL
	)
	
	DECLARE @strServiceTypes NVARCHAR(MAX)
	DECLARE @tmpServiceTypes TABLE
	(
		ID INT NOT NULL
	)
	DECLARE @strPOStatuses NVARCHAR(MAX)
	DECLARE @tmpPOStatuses TABLE
	(
		ID INT NOT NULL
	)
	
	-- Extract some of the values into separate tables for ease of processing.
	SELECT	@strClients = Clients,
			@strPOStatuses = POStatuses,
			@strPrograms = Programs,
			@strServiceRequestStatuses = ServiceRequestStatuses,
			@strServiceTypes = ServiceTypes			
	FROM	@tmpWhereClause
	
	-- Clients
	INSERT INTO @tmpClients
	SELECT item FROM fnSplitString(@strClients,',')
	
	-- Programs
	INSERT INTO @tmpPrograms
	SELECT item FROM fnSplitString(@strPrograms,',')
	
	-- POStatuses
	INSERT INTO @tmpPOStatuses
	SELECT item FROM fnSplitString(@strPOStatuses,',')
	
	-- Service request statuses
	INSERT INTO @tmpServiceRequestStatuses
	SELECT item FROM fnSplitString(@strServiceRequestStatuses,',')
	
	-- Service types
	INSERT INTO @tmpServiceTypes
	SELECT item FROM fnSplitString(@strServiceTypes,',')
	
	
	SELECT	@IDType = T.IDType,			
			@IDValue = T.IDValue,
			@NameType = T.NameType,
			@NameValue = T.NameValue,
			@LastName = T.LastName, 
			@FilterType = T.FilterType,
			@FromDate = T.FromDate,
			@ToDate = T.ToDate,
			@Preset = T.Preset,
			@IsGOA = T.IsGOA,
			@IsRedispatched = T.IsRedispatched,
			@IsPossibleTow  = T.IsPossibleTow,		
			@VehicleType = T.VehicleType,
			@VehicleYear = T.VehicleYear,
			@VehicleMake = T.VehicleMake,
			@VehicleMakeOther = T.VehicleMakeOther,
			@VehicleModel = T.VehicleModel,
			@VehicleModelOther = T.VehicleModelOther,
			@PaymentByCheque = T.PaymentByCheque,
			@PaymentByCard = T.PaymentByCard ,
			@MemberPaid = T.MemberPaid
	FROM	@tmpWhereClause T
	
	DECLARE @vinParam NVARCHAR(50) = NULL
	IF @IDType = 'VIN'
	BEGIN
		SELECT	@vinParam = IDValue 
		FROM	@tmpWhereClause
		WHERE	IDType = 'VIN'
	END
	--IF ISNULL(@vinParam,'') <> ''
	--BEGIN
	
	--	INSERT INTO #tmpVehicle
	--	SELECT	V.VIN,
	--			V.MemberID,
	--			V.MembershipID
	--	FROM	Vehicle V WITH (NOLOCK)
	--	WHERE	V.VIN = @vinParam
	--	--V.VIN LIKE '%' + @vinParam + '%'
		
	--END
	
	Declare @PurchaseOrder NVARCHAR(50) = CONVERT(NVARCHAR(50),@IDValue)
	Declare @iServiceRequestID INT = 0
	IF (@IDType = 'Service Request')
	BEGIN
		SET @iServiceRequestID = CONVERT(INT, @IDValue)
	END

	Declare @ISP nvarchar(50) = CONVERT(NVARCHAR(50),@IDValue)
	Declare @Member nvarchar(50) = CONVERT(NVARCHAR(50),@IDValue)
	Declare @VIN nvarchar(50) = CONVERT(NVARCHAR(50),@IDValue)
	
			
	INSERT INTO #Filtered
	SELECT  
			--DISTINCT  
			SR.ID AS [RequestNumber],  
			SR.CaseID AS [Case],
			P.ProgramID,
			P.ProgramName AS [Program],
			CL.ID AS ClientID,
			CL.Name AS [Client], 			
			M.FirstName,
			M.LastName,
			M.MiddleName,
			M.Suffix,
			M.Prefix,   
			MS.MembershipNumber AS MemberNumber,  			
			SR.CreateDate,
			PO.CreateBy,
			PO.ModifyBy,
			SR.CreateBy,
			SR.ModifyBy,
			--TV.VIN,
			C.VehicleVIN AS VIN, -- KB: VIN Issue
			VT.ID As VehicleTypeID,
			VT.Name AS VehicleType,						
			PC.ID AS [ServiceTypeID],
			PC.Name AS [ServiceType],			  
			SRS.ID AS [StatusID],
			CASE ISNULL(SR.IsRedispatched,0) WHEN 1 THEN SRS.Name + '^' ELSE SRS.Name END AS [Status],
			SR.ServiceRequestPriorityID AS [PriorityID],  
			SRP.Name AS [Priority],			
			V.Name AS [ISPName], 
			V.VendorNumber, 
			PO.PurchaseOrderNumber AS [PONumber], 
			POS.ID AS PurchaseOrderStatusID,
			POS.Name AS PurchaseOrderStatus,
			PO.PurchaseOrderAmount,			   
			C.AssignedToUserID,
			SR.NextActionAssignedToUserID,			
			PO.IsGOA,
			SR.IsRedispatched,
			SR.IsPossibleTow,
			C.VehicleYear,
			C.VehicleMake,
			C.VehicleMakeOther,
			C.VehicleModel,
			C.VehicleModelOther,
			PO.IsPayByCompanyCreditCard,
			PO.CreateDate		
	FROM	ServiceRequest SR WITH (NOLOCK)	
	--LEFT JOIN	@tmpWhereClause TMP ON 1=1	
	JOIN	[ServiceRequestStatus] SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID  
	LEFT JOIN	[ServiceRequestPriority] SRP WITH (NOLOCK) ON SR.ServiceRequestPriorityID = SRP.ID 
	JOIN	[Case] C WITH (NOLOCK) on C.ID = SR.CaseID
	JOIN	dbo.fnc_GetProgramsForUser(@userID) P ON C.ProgramID = P.ProgramID  
	
	JOIN	[Client] CL WITH (NOLOCK) ON P.ClientID = CL.ID
	LEFT JOIN	[Member] M WITH (NOLOCK) ON C.MemberID = M.ID   -- RH 2/10/2014 Insisted on by the users
	LEFT JOIN	Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID  
	LEFT JOIN [ProductCategory] PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID   
	LEFT JOIN [VehicleType] VT WITH (NOLOCK) ON VT.ID = C.VehicleTypeID
	LEFT JOIN (  
			SELECT  
			ID,  
			PurchaseOrderNumber, 
			PurchaseOrderStatusID, 
			ServiceRequestID,  
			VendorLocationID,
			PurchaseOrderAmount,
			TPO.IsGOA,
			TPO.IsPayByCompanyCreditCard,
			TPO.CreateBy,
			TPO.ModifyBy,
			TPO.CreateDate			   
			FROM PurchaseOrder TPO WITH (NOLOCK)
			--LEFT JOIN	 @tmpWhereClause TMP   ON 1=1
			WHERE ( (@IDType IS NULL) OR (@IDType <> 'Purchase Order') OR (@IDType = 'Purchase Order' AND PurchaseOrderNumber = @IDValue))
	) PO ON SR.ID = PO.ServiceRequestID
	
	LEFT JOIN	PurchaseOrderStatus POS WITH (NOLOCK) ON PO.PurchaseOrderStatusID = POS.ID
	LEFT JOIN	[NextAction] NA WITH (NOLOCK) ON SR.NextActionID=NA.ID 
	LEFT JOIN	[VendorLocation] VL WITH (NOLOCK) ON PO.VendorLocationID = VL.ID  
	LEFT JOIN	[Vendor] V WITH (NOLOCK) ON VL.VendorID = V.ID
	--LEFT JOIN	#tmpVehicle TV ON (TV.MemberID IS NULL OR TV.MemberID = M.ID) 
	
	-- DEBUG:
	--SELECT * FROM @tmpWhereClause
	--SELECT * FROM #Raw
	
	-- Apply filter on the #Raw
	--INSERT INTO #Filtered 
	--		(
	--		RequestNumber,
	--		CaseID,
	--		ProgramID,
	--		Program,
	--		ClientID,
	--		Client,
	--		FirstName,
	--		LastName,
	--		MiddleName,
	--		Suffix,
	--		Prefix,
	--		MemberNumber,
	--		CreateDate,
	--		POCreateBy,
	--		POModifyBy,
	--		SRCreateBy,
	--		SRModifyBy,
	--		VIN,
	--		VehicleTypeID,
	--		VehicleType,
	--		ServiceTypeID,
	--		ServiceType,
	--		StatusID,
	--		[Status],
	--		PriorityID,
	--		[Priority],
	--		ISPName,
	--		VendorNumber,
	--		PONumber,
	--		PurchaseOrderStatusID,
	--		PurchaseOrderStatus,
	--		PurchaseOrderAmount,
	--		AssignedToUserID,
	--		NextActionAssignedToUserID,
	--		IsGOA,
	--		IsRedispatched,
	--		IsPossibleTow,
	--		VehicleYear,
	--		VehicleMake,
	--		VehicleMakeOther,
	--		VehicleModel,
	--		VehicleModelOther,
	--		PaymentByCard
	--		)
				
	--SELECT	RequestNumber,
	--		CaseID,
	--		ProgramID,
	--		Program,
	--		ClientID,
	--		Client,
	--		FirstName,
	--		R.LastName,
	--		MiddleName,
	--		Suffix,
	--		Prefix,
	--		MemberNumber,
	--		CreateDate,
	--		POCreateBy,
	--		POModifyBy,
	--		SRCreateBy,
	--		SRModifyBy,
	--		VIN,
	--		VehicleTypeID,
	--		R.VehicleType,
	--		ServiceTypeID, 
	--		ServiceType,		 
	--		StatusID,
	--		[Status],
	--		PriorityID,
	--		[Priority],
	--		ISPName,
	--		VendorNumber,
	--		PONumber,
	--		PurchaseOrderStatusID,
	--		PurchaseOrderStatus, 
	--		PurchaseOrderAmount,
	--		AssignedToUserID,
	--		NextActionAssignedToUserID,
	--		R.IsGOA,
	--		R.IsRedispatched,
	--		R.IsPossibleTow,
	--		R.VehicleYear,
	--		R.VehicleMake,
	--		R.VehicleMakeOther,
	--		R.VehicleModel,
	--		R.VehicleModelOther,
	--		R.PaymentByCard	
	--FROM	#Raw R
	--LEFT JOIN	@tmpWhereClause T ON 1=1

	WHERE	
			(
	
		-- IDs
		(
			(@IDType IS NULL)
			OR
			(@IDType = 'Purchase Order' AND PO.PurchaseOrderNumber = @PurchaseOrder )
			OR			
			(@IDType = 'Service Request' AND @iServiceRequestID = SR.ID )
			OR
			(@IDType = 'ISP' AND V.VendorNumber =  @ISP )
			OR
			(@IDType = 'Member' AND MS.MembershipNumber = @Member )			 
			OR
			(@IDType = 'VIN' AND C.VehicleVIN = @VIN )
		)

		---- IDs
		--(
		--	(@IDType IS NULL)
		--	OR
		--	(@IDType = 'Purchase Order' AND PO.PurchaseOrderNumber = CONVERT(NVARCHAR(50),@IDValue))
		--	OR
		--	(@IDType = 'Service Request' AND @IDValue = CONVERT(NVARCHAR(50),SR.ID))
		--	OR
		--	(@IDType = 'ISP' AND V.VendorNumber =  CONVERT(NVARCHAR(50),@IDValue) )
		--	OR
		--	(@IDType = 'Member' AND MS.MembershipNumber = CONVERT(NVARCHAR(50),@IDValue))			 
		--	OR
		--	(@IDType = 'VIN' AND C.VehicleVIN = CONVERT(NVARCHAR(50),@IDValue))
		--)
	
		AND
		-- Names
		(
				(@FilterType IS NULL)
				OR
				(@FilterType = 'Is equal to' 
					AND (
							(@NameType = 'ISP' AND V.Name = @NameValue)
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName = @NameValue))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName = @LastName))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy = @NameValue 
																				OR 
																				SR.ModifyBy = @NameValue 
																				OR 
																				PO.CreateBy = @NameValue 
																				OR 
																				PO.ModifyBy = @NameValue 
																			)) )
											
											)
							)		
						)
				)
				OR
				(@FilterType = 'Starts with' 
					AND (
							(@NameType = 'ISP' AND V.Name LIKE  @NameValue + '%')
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName LIKE  @NameValue + '%'))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName LIKE  @LastName + '%'))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy LIKE  @NameValue + '%' 
																				OR 
																				SR.ModifyBy LIKE  @NameValue + '%'
																				OR 
																				PO.CreateBy LIKE  @NameValue + '%'
																				OR 
																				PO.ModifyBy LIKE  @NameValue + '%'
																			)) )
											
											)
							)		
						)
				)
				OR
				(@FilterType = 'Contains' 
					AND (
							(@NameType = 'ISP' AND V.Name LIKE  '%' + @NameValue + '%')
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName LIKE  '%' + @NameValue + '%'))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName LIKE  '%' + @LastName + '%'))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy LIKE  '%' + @NameValue + '%' 
																				OR 
																				SR.ModifyBy LIKE  '%' + @NameValue + '%' 
																				OR 
																				PO.CreateBy LIKE  '%' + @NameValue + '%' 
																				OR 
																				PO.ModifyBy LIKE  '%' + @NameValue + '%' 
																			)) )
											
											)
							)		
						)
				)
				OR
				(@FilterType = 'Ends with' 
					AND (
							(@NameType = 'ISP' AND V.Name LIKE  '%' + @NameValue)
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName LIKE  '%' + @NameValue))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName LIKE  '%' + @LastName))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy LIKE  '%' + @NameValue 
																				OR 
																				SR.ModifyBy LIKE  '%' + @NameValue 
																				OR 
																				PO.CreateBy LIKE  '%' + @NameValue 
																				OR 
																				PO.ModifyBy LIKE  '%' + @NameValue 
																			)) )
											
											)
							)		
						)
				)
			
		)
	
		AND
		-- Date Range
		(
				(@Preset IS NOT NULL AND	(
											(@Preset = 'Last 7 days' AND DATEDIFF(WK,SR.CreateDate,GETDATE()) <= 1)
											OR
											(@Preset = 'Last 30 days' AND DATEDIFF(M,SR.CreateDate,GETDATE()) <= 1)
											OR
											(@Preset = 'Last 90 days' AND DATEDIFF(M,SR.CreateDate,GETDATE()) <= 3)
											)
				)
				OR
				(
					(@Preset IS NULL AND	(	( @FromDate IS NULL OR (@FromDate IS NOT NULL AND SR.CreateDate >= @FromDate))
											AND
												( @ToDate IS NULL OR (@ToDate IS NOT NULL AND SR.CreateDate <= @ToDate))
											)
					)
				)
		)
		AND
		-- Clients
		(
				(	ISNULL(@strClients,'') = '' OR ( CL.ID IN (SELECT ID FROM @tmpClients) ))
		)
		AND
		-- Programs
		(
				(	ISNULL(@strPrograms,'') = '' OR ( P.ProgramID IN (SELECT ID FROM @tmpPrograms) ))
		)
		AND
		-- SR Statuses
		(
				(	ISNULL(@strServiceRequestStatuses,'') = '' OR ( SRS.ID IN (SELECT ID FROM @tmpServiceRequestStatuses) ))
		)
		AND
		-- Service types
		(
				(	ISNULL(@strServiceTypes,'') = '' OR ( PC.ID IN (SELECT ID FROM @tmpServiceTypes) ))
		)
		AND
		-- Special flags
		(
				( @IsGOA IS NULL OR (PO.IsGOA = @IsGOA))
				AND
				( @IsPossibleTow IS NULL OR (SR.IsPossibleTow = @IsPossibleTow))
				AND
				( @IsRedispatched IS NULL OR (SR.IsRedispatched = @IsRedispatched))
		)
		AND
		-- Vehicle
		(
				(@VehicleType IS NULL OR (C.VehicleTypeID = @VehicleType))
				AND
				(@VehicleYear IS NULL OR (C.VehicleYear = @VehicleYear))
				AND
				(@VehicleMake IS NULL OR ( (C.VehicleMake = @VehicleMake) OR (@VehicleMake = 'Other' AND C.VehicleMake = 'Other' AND C.VehicleMakeOther = @VehicleMakeOther ) ) )
				AND
				(@VehicleModel IS NULL OR ( (C.VehicleModel = @VehicleModel) OR (@VehicleModel = 'Other' AND C.VehicleModel = 'Other' AND C.VehicleModelOther = @VehicleModelOther) ) )
		)
		AND
		-- Payment Type
		(
				( @PaymentByCheque IS NULL OR ( @PaymentByCheque = 1 AND PO.IsPayByCompanyCreditCard = 0 AND PO.PurchaseOrderAmount > 0 ) )
				AND
				( @PaymentByCard IS NULL OR ( @PaymentByCard = 1 AND PO.IsPayByCompanyCreditCard = 1 AND PO.PurchaseOrderAmount > 0 ) )
				AND
				( @MemberPaid IS NULL OR ( @MemberPaid = 1 AND POS.Name = 'Issue-Paid' AND PO.PurchaseOrderAmount > 0 ))
		)
		AND
		-- PurchaseOrder status
		(
				(	ISNULL(@strPOStatuses,'') = '' OR ( PO.PurchaseOrderStatusID IN (SELECT ID FROM @tmpPOStatuses) ))
		)
	)
	
	-- DEBUG:
	--SELECT 'Filtered', * FROM #Filtered
	
	-- Format the data [ Member name, vehiclemake, model, etc]

	;with CTEFormatted AS(
	SELECT	ROW_NUMBER() OVER (PARTITION BY RequestNumber ORDER BY POCreateDate DESC) AS RowNum, 
			RequestNumber,
			CaseID,
			ProgramID,
			Program,
			ClientID,
			Client,
			REPLACE(RTRIM( 
				COALESCE(FirstName, '') + 
				COALESCE(' ' + left(MiddleName,1), '') + 
				COALESCE(' ' + LastName, '') +
				COALESCE(' ' + Suffix, '')
				), ' ', ' ') AS MemberName, 
			MemberNumber,
			CreateDate,
			POCreateBy,
			POModifyBy,
			SRCreateBy,
			SRModifyBy,
			VIN,
			VehicleTypeID,
			VehicleType,
			ServiceTypeID,
			ServiceType,
			StatusID,
			[Status],
			PriorityID,
			[Priority],
			ISPName,
			VendorNumber,
			PONumber,
			PurchaseOrderStatusID,
			PurchaseOrderStatus,
			PurchaseOrderAmount,
			AssignedToUserID,
			NextActionAssignedToUserID,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleYear,
			CASE WHEN VehicleMake = 'Other' THEN VehicleMakeOther ELSE VehicleMake END AS VehicleMake,
			CASE WHEN VehicleModel = 'Other' THEN VehicleModelOther ELSE VehicleModel END AS VehicleModel,			
			PaymentByCard,
			POCreateDate
			FROM	#Filtered R
	)
	INSERT INTO #Formatted(
			RequestNumber,
			CaseID,
			ProgramID,
			Program,
			ClientID,
			Client,
			MemberName,
			MemberNumber,
			CreateDate,
			POCreateBy,
			POModifyBy,
			SRCreateBy,
			SRModifyBy,
			VIN,
			VehicleTypeID,
			VehicleType,
			ServiceTypeID,
			ServiceType,
			StatusID,
			[Status],
			PriorityID,
			[Priority],
			ISPName,
			VendorNumber,
			PONumber,
			PurchaseOrderStatusID,
			PurchaseOrderStatus,
			PurchaseOrderAmount,
			AssignedToUserID,
			NextActionAssignedToUserID,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleYear,
			VehicleMake,			
			VehicleModel,			
			PaymentByCard)
				
	SELECT	RequestNumber,
			CaseID,
			ProgramID,
			Program,
			ClientID,
			Client,
			MemberName,
			MemberNumber,
			CreateDate,
			POCreateBy,
			POModifyBy,
			SRCreateBy,
			SRModifyBy,
			VIN,
			VehicleTypeID,
			VehicleType,
			ServiceTypeID,
			ServiceType,
			StatusID,
			[Status],
			PriorityID,
			[Priority],
			ISPName,
			VendorNumber,
			PONumber,
			PurchaseOrderStatusID,
			PurchaseOrderStatus,
			PurchaseOrderAmount,
			AssignedToUserID,
			NextActionAssignedToUserID,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleYear,
			VehicleMake,			
			VehicleModel,			
			PaymentByCard
	FROM	CTEFormatted 
	WHERE   RowNum = 1
	
	
	-- Apply sorting
	INSERT INTO #Sorted 
			(
			RequestNumber,
			CaseID,
			ProgramID,
			Program,
			ClientID,
			Client,
			MemberName,
			MemberNumber,
			CreateDate,
			POCreateBy,
			POModifyBy,
			SRCreateBy,
			SRModifyBy,
			VIN,
			VehicleTypeID,
			VehicleType,
			ServiceTypeID,
			ServiceType,
			StatusID,
			[Status],
			PriorityID,
			[Priority],
			ISPName,
			VendorNumber,
			PONumber,
			PurchaseOrderStatusID,
			PurchaseOrderStatus,
			PurchaseOrderAmount,
			AssignedToUserID,
			NextActionAssignedToUserID,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleYear,
			VehicleMake,			
			VehicleModel,			
			PaymentByCard
			)
				
	SELECT	RequestNumber,
			CaseID,
			ProgramID,
			Program,
			ClientID,
			Client,
			MemberName, 
			MemberNumber,
			CreateDate,
			POCreateBy,
			POModifyBy,
			SRCreateBy,
			SRModifyBy,
			VIN,
			VehicleTypeID,
			VehicleType,
			ServiceTypeID,
			ServiceType,
			StatusID,
			[Status],
			PriorityID,
			[Priority],
			ISPName,
			VendorNumber,
			PONumber,
			PurchaseOrderStatusID,
			PurchaseOrderStatus,
			PurchaseOrderAmount,
			AssignedToUserID,
			NextActionAssignedToUserID,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleYear,
			VehicleMake,
			VehicleModel,			
			PaymentByCard
	FROM	#Formatted F
	ORDER BY     
		CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'ASC'    
		THEN F.RequestNumber END ASC,     
		CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'DESC'    
		THEN F.RequestNumber END DESC ,
		
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,
		
		CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'    
		THEN F.CreateDate END ASC,     
		CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'    
		THEN F.CreateDate END DESC ,
		
		CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'    
		THEN F.MemberName END ASC,     
		CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'    
		THEN F.MemberName END DESC ,
		
		CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'ASC'    
		THEN F.VehicleType END ASC,     
		CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'DESC'    
		THEN F.VehicleType END DESC ,
		
		CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'ASC'    
		THEN F.ServiceType END ASC,     
		CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'DESC'    
		THEN F.ServiceType END DESC ,
		
		CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'    
		THEN F.[Status] END ASC,     
		CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'    
		THEN F.[Status] END DESC ,
		
		CASE WHEN @sortColumn = 'ISP' AND @sortOrder = 'ASC'    
		THEN F.[ISPName] END ASC,     
		CASE WHEN @sortColumn = 'ISP' AND @sortOrder = 'DESC'    
		THEN F.ISPName END DESC ,
		
		CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'    
		THEN F.PONumber END ASC,     
		CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'    
		THEN F.PONumber END DESC ,
		
		CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'ASC'    
		THEN F.PurchaseOrderStatus END ASC,     
		CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'DESC'    
		THEN F.PurchaseOrderStatus END DESC ,
		
		CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'ASC'    
		THEN F.PurchaseOrderAmount END ASC,     
		CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'DESC'    
		THEN F.PurchaseOrderAmount END DESC
		
	
	 
	SET @totalRows = 0  
	SELECT @totalRows = MAX(RowNum) FROM #Sorted  
	SET @endInd = @startInd + @pageSize - 1  
	IF @startInd > @totalRows  
	BEGIN  
	 DECLARE @numOfPages INT  
	 SET @numOfPages = @totalRows / @pageSize  
	IF @totalRows % @pageSize > 1  
	BEGIN  
	 SET @numOfPages = @numOfPages + 1  
	END  
	 SET @startInd = ((@numOfPages - 1) * @pageSize) + 1  
	 SET @endInd = @numOfPages * @pageSize  
	END  
	
	-- Take the required set (say 10 out of "n").	
	SELECT @totalRows AS TotalRows, * FROM #Sorted F WHERE F.RowNum BETWEEN @startInd AND @endInd
	
	DROP TABLE #Raw
	DROP TABLE #Filtered
	DROP TABLE #Formatted
	DROP TABLE #Sorted

END

GO



GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Contract_Status_Get]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Contract_Status_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_Vendor_Contract_Status_Get] 337
 CREATE PROCEDURE [dbo].[dms_Vendor_Contract_Status_Get]( 
  @VendorID INT = NULL
) 
 AS 
 BEGIN       
      SET NOCOUNT ON  

SELECT    
    CASE WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted' ELSE 'Not Contracted' END AS ContractStatus  
     From Vendor v 
    LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID
    Where v.ID = @VendorID  
  
END  
GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Info]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Info] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_Vendor_Info] 319
 CREATE PROCEDURE [dbo].[dms_Vendor_Info]( 
  @VendorLocationID INT = NULL
  ,@ServiceRequestID INT =NULL
) 
 AS 
 BEGIN   
    
      SET NOCOUNT ON  
  
     DECLARE @ProductID INT = NULL  
       
      SELECT @ProductID=PrimaryProductID   
      FROM ServiceRequest   
      WHERE ID=@ServiceRequestID  
       
      Select   DISTINCT
   v.ID  
            , v.Name as VendorName  
            , v.VendorNumber as VendorNumber  
            --, CASE   
            --WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NOT NULL THEN 'Contracted'  
            --WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NULL THEN 'Not Contracted'  
            --WHEN c.ID IS NOT NULL THEN 'Contracted'   
            --ELSE 'Not Contracted'  
            --END as ContractStatus  
   , CASE WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted' ELSE 'Not Contracted' END AS ContractStatus  
            , ae.Line1 as Address1  
            , ae.Line2 as Address2  
            , REPLACE(RTRIM(  
            COALESCE(ae.City, '') +  
            COALESCE(', ' + ae.StateProvince,'') +   
            COALESCE(' ' + LTRIM(ae.PostalCode), '') +   
            COALESCE(' ' + ae.CountryCode, '')   
            ), ' ', ' ') as VendorCityStateZipCountry  
            , pe24.PhoneTypeID as DispatchPhoneType  
            , pe24.PhoneNumber as DispatchPhoneNumber  
            , peFax.PhoneTypeID as FaxPhoneType  
            , peFax.PhoneNumber as FaxPhoneNumber  
            , peOfc.PhoneTypeID as OfficePhoneType  
            , peOfc.PhoneNumber as OfficePhoneNumber  
            ,ISNULL(vl.DispatchEmail,v.Email) Email--,v.Email  
            ,v.CreateBy   
            ,v.CreateDate  
            ,v.ModifyBy  
            ,v.ModifyDate  
            ,vs.Name AS VendorStatus  
            ,COALESCE(TaxEIN,TaxSSN,'') VendorTaxID  
      From VendorLocation vl  
      Join Vendor v on v.ID = vl.VendorID  
      JOIN VendorStatus vs ON v.VendorStatusID = vs.ID  
      Left Outer Join AddressEntity ae on ae.RecordID = vl.ID and ae.EntityID = (Select ID From Entity Where Name = 'VendorLocation')   
      Left Outer Join PhoneEntity pe24 on pe24.RecordID = vl.ID and pe24.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and pe24.PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')  
      Left Outer Join PhoneEntity peFax on peFax.RecordID = vl.ID and peFax.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and peFax.PhoneTypeID = (Select ID From PhoneType Where Name = 'Fax')  
      Left Outer Join PhoneEntity peOfc on peOfc.RecordID = vl.ID and peOfc.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and peOfc.PhoneTypeID = (Select ID From PhoneType Where Name = 'Office')  
      --Left Outer Join [Contract] c on c.VendorID = v.ID and c.IsActive = 1 and c.ContractStatusID = (Select ID From ContractStatus Where Name = 'Active')  
      --Left Outer Join (  
      --      SELECT DISTINCT vr.VendorID, vr.ProductID  
      --      FROM dbo.fnGetCurrentProductRatesByVendorLocation() vr   
      --      ) DefaultVendorRates ON v.ID = DefaultVendorRates.VendorID And @ProductID = DefaultVendorRates.ProductID  
      LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID
      Where vl.ID = @VendorLocationID  
  
END  
GO

GO
  
  IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Info_Search]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Info_Search] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

  --EXEC dms_Vendor_Info_Search @DispatchPhoneNumber = '1 4695213697',@OfficePhoneNumber = '1 9254494909'  
 CREATE PROCEDURE [dbo].[dms_Vendor_Info_Search](   
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10    
 , @sortColumn nvarchar(100)  = ''   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @DispatchPhoneNumber nvarchar(50)=NULL 
 , @OfficePhoneNumber nvarchar(50)=NULL
 , @VendorSearchName nvarchar(50)=NULL  
-- , @FaxPhoneNumber nvarchar(50)  
  
--SET @DispatchPhoneNumber = '1 2146834715';  
--SET @OfficePhoneNumber = '1 5868722949'  
  
) AS   
 BEGIN   
    
  SET NOCOUNT ON  
  
DECLARE @idoc int  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter   
VendorIDOperator="-1"   
VendorLocationIDOperator="-1"   
SequenceOperator="-1"   
VendorNumberOperator="-1"   
VendorNameOperator="-1"   
VendorStatusOperator="-1"   
ContractStatusOperator="-1"   
Address1Operator="-1"   
VendorCityOperator="-1"   
DispatchPhoneTypeOperator="-1"   
DispatchPhoneNumberOperator="-1"   
OfficePhoneTypeOperator="-1"   
 ></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
VendorIDOperator INT NOT NULL,  
VendorIDValue int NULL,  
VendorLocationIDOperator INT NOT NULL,  
VendorLocationIDValue int NULL,  
SequenceOperator INT NOT NULL,  
SequenceValue int NULL,  
VendorNumberOperator INT NOT NULL,  
VendorNumberValue nvarchar(50) NULL,  
VendorNameOperator INT NOT NULL,  
VendorNameValue nvarchar(50) NULL,  
VendorStatusOperator INT NOT NULL,  
VendorStatusValue nvarchar(50) NULL,  
ContractStatusOperator INT NOT NULL,  
ContractStatusValue nvarchar(50) NULL,  
Address1Operator INT NOT NULL,  
Address1Value nvarchar(50) NULL,  
VendorCityOperator INT NOT NULL,  
VendorCityValue nvarchar(50) NULL,  
DispatchPhoneTypeOperator INT NOT NULL,  
DispatchPhoneTypeValue int NULL,  
DispatchPhoneNumberOperator INT NOT NULL,  
DispatchPhoneNumberValue nvarchar(50) NULL,  
OfficePhoneTypeOperator INT NOT NULL,  
OfficePhoneTypeValue int NULL  
)  
DECLARE @FinalResults TABLE (   
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 VendorID int  NULL ,  
 VendorLocationID int  NULL ,  
 Sequence int  NULL ,  
 VendorNumber nvarchar(50)  NULL ,  
 VendorName nvarchar(255)  NULL ,  
 VendorStatus nvarchar(50)  NULL ,  
 ContractStatus nvarchar(50)  NULL ,  
 Address1 nvarchar(255)  NULL ,  
 VendorCity nvarchar(255)  NULL ,  
 DispatchPhoneType int  NULL ,  
 DispatchPhoneNumber nvarchar(50)  NULL ,  
 OfficePhoneType int  NULL ,  
 OfficePhoneNumber nvarchar(50)  NULL   
)   
DECLARE @FinalResults1 TABLE (   
 --[RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 VendorID int  NULL ,  
 VendorLocationID int  NULL ,  
 Sequence int  NULL ,  
 VendorNumber nvarchar(50)  NULL ,  
 VendorName nvarchar(255)  NULL ,  
 VendorStatus nvarchar(50)  NULL ,  
 ContractStatus nvarchar(50)  NULL ,  
 Address1 nvarchar(255)  NULL ,  
 VendorCity nvarchar(255)  NULL ,  
 DispatchPhoneType int  NULL ,  
 DispatchPhoneNumber nvarchar(50)  NULL ,  
 OfficePhoneType int  NULL ,  
 OfficePhoneNumber nvarchar(50)  NULL   
)   
  
INSERT INTO @tmpForWhereClause  
SELECT    
 ISNULL(VendorIDOperator,-1),  
 VendorIDValue ,  
 ISNULL(VendorLocationIDOperator,-1),  
 VendorLocationIDValue ,  
 ISNULL(SequenceOperator,-1),  
 SequenceValue ,  
 ISNULL(VendorNumberOperator,-1),  
 VendorNumberValue ,  
 ISNULL(VendorNameOperator,-1),  
 VendorNameValue ,  
 ISNULL(VendorStatusOperator,-1),  
 VendorStatusValue ,  
 ISNULL(ContractStatusOperator,-1),  
 ContractStatusValue ,  
 ISNULL(Address1Operator,-1),  
 Address1Value ,  
 ISNULL(VendorCityOperator,-1),  
 VendorCityValue ,  
 ISNULL(DispatchPhoneTypeOperator,-1),  
 DispatchPhoneTypeValue ,  
 ISNULL(DispatchPhoneNumberOperator,-1),  
 DispatchPhoneNumberValue ,  
 ISNULL(OfficePhoneTypeOperator,-1),  
 OfficePhoneTypeValue   
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
VendorIDOperator INT,  
VendorIDValue int   
,VendorLocationIDOperator INT,  
VendorLocationIDValue int   
,SequenceOperator INT,  
SequenceValue int   
,VendorNumberOperator INT,  
VendorNumberValue nvarchar(50)   
,VendorNameOperator INT,  
VendorNameValue nvarchar(50)   
,VendorStatusOperator INT,  
VendorStatusValue nvarchar(50)   
,ContractStatusOperator INT,  
ContractStatusValue nvarchar(50)   
,Address1Operator INT,  
Address1Value nvarchar(50)   
,VendorCityOperator INT,  
VendorCityValue nvarchar(50)   
,DispatchPhoneTypeOperator INT,  
DispatchPhoneTypeValue int   
,DispatchPhoneNumberOperator INT,  
DispatchPhoneNumberValue nvarchar(50)   
,OfficePhoneTypeOperator INT,  
OfficePhoneTypeValue int   
 )   

DECLARE @VendorLocationEntityID int,
	@VendorEntityID int,
	@DispatchPhoneTypeID int,
	@OfficePhoneTypeID int
SET @VendorLocationEntityID = (Select ID From Entity Where Name = 'VendorLocation')
SET @VendorEntityID = (Select ID From Entity Where Name = 'Vendor')
SET @DispatchPhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')  
SET @OfficePhoneTypeID = (Select ID From PhoneType Where Name = 'Office')  

--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
  
INSERT INTO @FinalResults1  
  
SELECT   
  v.ID  
 ,vl.ID   
 ,vl.Sequence  
 ,v.VendorNumber   
 ,v.Name
 ,vs.Name AS VendorStatus
 ,CASE WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted' ELSE 'Not Contracted' END
 ,ae.Line1 as Address1  
 --,ae.Line2 as Address2  
 ,REPLACE(RTRIM(  
   COALESCE(ae.City, '') +  
   COALESCE(', ' + ae.StateProvince,'') +   
   COALESCE(LTRIM(ae.PostalCode), '') +   
   COALESCE(' ' + ae.CountryCode, '')   
   ), ' ', ' ')   
 , pe24.PhoneTypeID   
 , pe24.PhoneNumber   
 , peOfc.PhoneTypeID   
 , peOfc.PhoneNumber   
FROM VendorLocation vl  
INNER JOIN Vendor v on v.ID = vl.VendorID  
JOIN VendorStatus vs on v.VendorStatusID  = vs.ID
LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID
LEFT OUTER JOIN AddressEntity ae on ae.RecordID = vl.ID and ae.EntityID = @VendorLocationEntityID    
LEFT OUTER JOIN PhoneEntity pe24 on pe24.RecordID = vl.ID and pe24.EntityID = @VendorLocationEntityID and pe24.PhoneTypeID = @DispatchPhoneTypeID   
LEFT OUTER JOIN PhoneEntity peOfc on peOfc.RecordID = v.ID and peOfc.EntityID = @VendorEntityID and peOfc.PhoneTypeID = @OfficePhoneTypeID 
--LEFT OUTER JOIN [Contract] c on c.VendorID = v.ID and c.IsActive = 1 AND c.ContractStatusID = (SELECT ID FROM ContractStatus WHERE Name = 'Active')
WHERE  
v.IsActive = 1 
--AND (v.VendorNumber IS NULL OR v.VendorNumber NOT LIKE '9X%' ) --KB: VendorNumber will be NULL for newly added vendors and these are getting excluded from the possible duplicates
AND
-- TP: Matching either phone number across both phone types is valid for this search; 
--     grouped OR condition -- A match on either phone number is valid
(ISNULL(pe24.PhoneNumber,'') IN (@DispatchPhoneNumber, @OfficePhoneNumber)
 OR
 ISNULL(peOfc.PhoneNumber,'') IN (@DispatchPhoneNumber, @OfficePhoneNumber)
)

--AND (@DispatchPhoneNumber IS NULL) OR (pe24.PhoneNumber = @DispatchPhoneNumber)  
--OR (@OfficePhoneNumber IS NULL) OR (peOfc.PhoneNumber = @OfficePhoneNumber)  
--AND (@VendorSearchName IS NULL) OR (v.NAme LIKE '%'+@VendorSearchName+'%')  

INSERT INTO @FinalResults  
SELECT   
 T.VendorID,  
 T.VendorLocationID,  
 T.Sequence,  
 T.VendorNumber,  
 T.VendorName,  
 T.VendorStatus,  
 T.ContractStatus,  
 T.Address1,  
 T.VendorCity,  
 T.DispatchPhoneType,  
 T.DispatchPhoneNumber,  
 T.OfficePhoneType,  
 T.OfficePhoneNumber  
FROM @FinalResults1 T,  
@tmpForWhereClause TMP   
WHERE (   
  
 (   
  ( TMP.VendorIDOperator = -1 )   
 OR   
  ( TMP.VendorIDOperator = 0 AND T.VendorID IS NULL )   
 OR   
  ( TMP.VendorIDOperator = 1 AND T.VendorID IS NOT NULL )   
 OR   
  ( TMP.VendorIDOperator = 2 AND T.VendorID = TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 3 AND T.VendorID <> TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 7 AND T.VendorID > TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 8 AND T.VendorID >= TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 9 AND T.VendorID < TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 10 AND T.VendorID <= TMP.VendorIDValue )   
  
 )   
  
 AND   
  
 (   
  ( TMP.VendorLocationIDOperator = -1 )   
 OR   
  ( TMP.VendorLocationIDOperator = 0 AND T.VendorLocationID IS NULL )   
 OR   
  ( TMP.VendorLocationIDOperator = 1 AND T.VendorLocationID IS NOT NULL )   
 OR   
  ( TMP.VendorLocationIDOperator = 2 AND T.VendorLocationID = TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 3 AND T.VendorLocationID <> TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 7 AND T.VendorLocationID > TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 8 AND T.VendorLocationID >= TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 9 AND T.VendorLocationID < TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 10 AND T.VendorLocationID <= TMP.VendorLocationIDValue )   
  
 )   
  
 AND   
  
 (   
  ( TMP.SequenceOperator = -1 )   
 OR   
  ( TMP.SequenceOperator = 0 AND T.Sequence IS NULL )   
 OR   
  ( TMP.SequenceOperator = 1 AND T.Sequence IS NOT NULL )   
 OR   
  ( TMP.SequenceOperator = 2 AND T.Sequence = TMP.SequenceValue )   
 OR   
  ( TMP.SequenceOperator = 3 AND T.Sequence <> TMP.SequenceValue )   
 OR   
  ( TMP.SequenceOperator = 7 AND T.Sequence > TMP.SequenceValue )   
 OR   
  ( TMP.SequenceOperator = 8 AND T.Sequence >= TMP.SequenceValue )   
 OR   
  ( TMP.SequenceOperator = 9 AND T.Sequence < TMP.SequenceValue )   
 OR   
  ( TMP.SequenceOperator = 10 AND T.Sequence <= TMP.SequenceValue )   
  
 )   
  
 AND   
  
 (   
  ( TMP.VendorNumberOperator = -1 )   
 OR   
  ( TMP.VendorNumberOperator = 0 AND T.VendorNumber IS NULL )   
 OR   
  ( TMP.VendorNumberOperator = 1 AND T.VendorNumber IS NOT NULL )   
 OR   
  ( TMP.VendorNumberOperator = 2 AND T.VendorNumber = TMP.VendorNumberValue )   
 OR   
  ( TMP.VendorNumberOperator = 3 AND T.VendorNumber <> TMP.VendorNumberValue )   
 OR   
  ( TMP.VendorNumberOperator = 4 AND T.VendorNumber LIKE TMP.VendorNumberValue + '%')   
 OR   
  ( TMP.VendorNumberOperator = 5 AND T.VendorNumber LIKE '%' + TMP.VendorNumberValue )   
 OR   
  ( TMP.VendorNumberOperator = 6 AND T.VendorNumber LIKE '%' + TMP.VendorNumberValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.VendorNameOperator = -1 )   
 OR   
  ( TMP.VendorNameOperator = 0 AND T.VendorName IS NULL )   
 OR   
  ( TMP.VendorNameOperator = 1 AND T.VendorName IS NOT NULL )   
 OR   
  ( TMP.VendorNameOperator = 2 AND T.VendorName = TMP.VendorNameValue )   
 OR   
  ( TMP.VendorNameOperator = 3 AND T.VendorName <> TMP.VendorNameValue )   
 OR   
  ( TMP.VendorNameOperator = 4 AND T.VendorName LIKE TMP.VendorNameValue + '%')   
 OR   
  ( TMP.VendorNameOperator = 5 AND T.VendorName LIKE '%' + TMP.VendorNameValue )   
 OR   
  ( TMP.VendorNameOperator = 6 AND T.VendorName LIKE '%' + TMP.VendorNameValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.VendorStatusOperator = -1 )   
 OR   
  ( TMP.VendorStatusOperator = 0 AND T.VendorStatus IS NULL )   
 OR   
  ( TMP.VendorStatusOperator = 1 AND T.VendorStatus IS NOT NULL )   
 OR   
  ( TMP.VendorStatusOperator = 2 AND T.VendorStatus = TMP.VendorStatusValue )   
 OR   
  ( TMP.VendorStatusOperator = 3 AND T.VendorStatus <> TMP.VendorStatusValue )   
 OR   
  ( TMP.VendorStatusOperator = 4 AND T.VendorStatus LIKE TMP.VendorStatusValue + '%')   
 OR   
  ( TMP.VendorStatusOperator = 5 AND T.VendorStatus LIKE '%' + TMP.VendorStatusValue )   
 OR   
  ( TMP.VendorStatusOperator = 6 AND T.VendorStatus LIKE '%' + TMP.VendorStatusValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.ContractStatusOperator = -1 )   
 OR   
  ( TMP.ContractStatusOperator = 0 AND T.ContractStatus IS NULL )   
 OR   
  ( TMP.ContractStatusOperator = 1 AND T.ContractStatus IS NOT NULL )   
 OR   
  ( TMP.ContractStatusOperator = 2 AND T.ContractStatus = TMP.ContractStatusValue )   
 OR   
  ( TMP.ContractStatusOperator = 3 AND T.ContractStatus <> TMP.ContractStatusValue )   
 OR   
  ( TMP.ContractStatusOperator = 4 AND T.ContractStatus LIKE TMP.ContractStatusValue + '%')   
 OR   
  ( TMP.ContractStatusOperator = 5 AND T.ContractStatus LIKE '%' + TMP.ContractStatusValue )   
 OR   
  ( TMP.ContractStatusOperator = 6 AND T.ContractStatus LIKE '%' + TMP.ContractStatusValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.Address1Operator = -1 )   
 OR   
  ( TMP.Address1Operator = 0 AND T.Address1 IS NULL )   
 OR   
  ( TMP.Address1Operator = 1 AND T.Address1 IS NOT NULL )   
 OR   
  ( TMP.Address1Operator = 2 AND T.Address1 = TMP.Address1Value )   
 OR   
  ( TMP.Address1Operator = 3 AND T.Address1 <> TMP.Address1Value )   
 OR   
  ( TMP.Address1Operator = 4 AND T.Address1 LIKE TMP.Address1Value + '%')   
 OR   
  ( TMP.Address1Operator = 5 AND T.Address1 LIKE '%' + TMP.Address1Value )   
 OR   
  ( TMP.Address1Operator = 6 AND T.Address1 LIKE '%' + TMP.Address1Value + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.VendorCityOperator = -1 )   
 OR   
  ( TMP.VendorCityOperator = 0 AND T.VendorCity IS NULL )   
 OR   
  ( TMP.VendorCityOperator = 1 AND T.VendorCity IS NOT NULL )   
 OR   
  ( TMP.VendorCityOperator = 2 AND T.VendorCity = TMP.VendorCityValue )   
 OR   
  ( TMP.VendorCityOperator = 3 AND T.VendorCity <> TMP.VendorCityValue )   
 OR   
  ( TMP.VendorCityOperator = 4 AND T.VendorCity LIKE TMP.VendorCityValue + '%')   
 OR   
  ( TMP.VendorCityOperator = 5 AND T.VendorCity LIKE '%' + TMP.VendorCityValue )   
 OR   
  ( TMP.VendorCityOperator = 6 AND T.VendorCity LIKE '%' + TMP.VendorCityValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.DispatchPhoneTypeOperator = -1 )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 0 AND T.DispatchPhoneType IS NULL )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 1 AND T.DispatchPhoneType IS NOT NULL )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 2 AND T.DispatchPhoneType = TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 3 AND T.DispatchPhoneType <> TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 7 AND T.DispatchPhoneType > TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 8 AND T.DispatchPhoneType >= TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 9 AND T.DispatchPhoneType < TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 10 AND T.DispatchPhoneType <= TMP.DispatchPhoneTypeValue )   
  
 )   
  
 AND   
  
 (   
  ( TMP.DispatchPhoneNumberOperator = -1 )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 0 AND T.DispatchPhoneNumber IS NULL )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 1 AND T.DispatchPhoneNumber IS NOT NULL )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 2 AND T.DispatchPhoneNumber = TMP.DispatchPhoneNumberValue )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 3 AND T.DispatchPhoneNumber <> TMP.DispatchPhoneNumberValue )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 4 AND T.DispatchPhoneNumber LIKE TMP.DispatchPhoneNumberValue + '%')   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 5 AND T.DispatchPhoneNumber LIKE '%' + TMP.DispatchPhoneNumberValue )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 6 AND T.DispatchPhoneNumber LIKE '%' + TMP.DispatchPhoneNumberValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.OfficePhoneTypeOperator = -1 )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 0 AND T.OfficePhoneType IS NULL )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 1 AND T.OfficePhoneType IS NOT NULL )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 2 AND T.OfficePhoneType = TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 3 AND T.OfficePhoneType <> TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 7 AND T.OfficePhoneType > TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 8 AND T.OfficePhoneType >= TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 9 AND T.OfficePhoneType < TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 10 AND T.OfficePhoneType <= TMP.OfficePhoneTypeValue )   
  
 )   
  
 AND   
 1 = 1   
 )   
 ORDER BY   
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'ASC'  
  THEN T.VendorID END ASC,   
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'DESC'  
  THEN T.VendorID END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorLocationID' AND @sortOrder = 'ASC'  
  THEN T.VendorLocationID END ASC,   
  CASE WHEN @sortColumn = 'VendorLocationID' AND @sortOrder = 'DESC'  
  THEN T.VendorLocationID END DESC ,  
  
  CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'  
  THEN T.Sequence END ASC,   
  CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'  
  THEN T.Sequence END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'  
  THEN T.VendorNumber END ASC,   
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'  
  THEN T.VendorNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'ASC'  
  THEN T.VendorName END ASC,   
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'DESC'  
  THEN T.VendorName END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'ASC'  
  THEN T.VendorStatus END ASC,   
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'DESC'  
  THEN T.VendorStatus END DESC ,  
  
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'ASC'  
  THEN T.ContractStatus END ASC,   
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'DESC'  
  THEN T.ContractStatus END DESC ,  
  
  CASE WHEN @sortColumn = 'Address1' AND @sortOrder = 'ASC'  
  THEN T.Address1 END ASC,   
  CASE WHEN @sortColumn = 'Address1' AND @sortOrder = 'DESC'  
  THEN T.Address1 END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorCity' AND @sortOrder = 'ASC'  
  THEN T.VendorCity END ASC,   
  CASE WHEN @sortColumn = 'VendorCity' AND @sortOrder = 'DESC'  
  THEN T.VendorCity END DESC ,  
  
  CASE WHEN @sortColumn = 'DispatchPhoneType' AND @sortOrder = 'ASC'  
  THEN T.DispatchPhoneType END ASC,   
  CASE WHEN @sortColumn = 'DispatchPhoneType' AND @sortOrder = 'DESC'  
  THEN T.DispatchPhoneType END DESC ,  
  
  CASE WHEN @sortColumn = 'DispatchPhoneNumber' AND @sortOrder = 'ASC'  
  THEN T.DispatchPhoneNumber END ASC,   
  CASE WHEN @sortColumn = 'DispatchPhoneNumber' AND @sortOrder = 'DESC'  
  THEN T.DispatchPhoneNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'OfficePhoneType' AND @sortOrder = 'ASC'  
  THEN T.OfficePhoneType END ASC,   
  CASE WHEN @sortColumn = 'OfficePhoneType' AND @sortOrder = 'DESC'  
  THEN T.OfficePhoneType END DESC ,  
  
  CASE WHEN @sortColumn = 'OfficePhoneNumber' AND @sortOrder = 'ASC'  
  THEN T.OfficePhoneNumber END ASC,   
  CASE WHEN @sortColumn = 'OfficePhoneNumber' AND @sortOrder = 'DESC'  
  THEN T.OfficePhoneNumber END DESC   
  
  
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
  
SELECT @count AS TotalRows, * FROM @FinalResults WHERE RowNum BETWEEN @startInd AND @endInd  
  
END  

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_PO_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_PO_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_PO_Details_Get @PONumber=7770395
 CREATE PROCEDURE [dbo].[dms_Vendor_Invoice_PO_Details_Get]( 
	@PONumber nvarchar(50) =NULL
	)
AS
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 SET FMTONLY OFF  
  
SELECT  PO.ID  
   , CASE  
    WHEN ISNULL(PO.IsPayByCompanyCreditCard,'') = 1 THEN 'Paid with company credit card'  
    ELSE ''  
     END AS [AlertText]  
   , PO.PurchaseOrderNumber AS [PONumber]  
   , POS.Name AS [POStatus]  
   , PO.PurchaseOrderAmount AS [POAmount]  
   , PC.Name AS [Service]  
   , PO.IssueDate AS [IssueDate]  
   , PO.ETADate AS [ETADate]  
   , PO.VendorLocationID     
   --, CASE  
   --WHEN ISNULL(CRS.ID,'') = '' THEN 'Not Contracted'  
   --ELSE 'Contracted'  
   --END AS 'ContractStatus'  
   , CASE WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted' ELSE 'Not Contracted' END AS ContractStatus  
   , V.Name AS [VendorName]  
   , V.VendorNumber AS [VendorNumber]  
   , ISNULL(PO.BillingAddressLine1,'') AS [VendorLocationLine1]  
   , ISNULL(PO.BillingAddressLine2,'') AS [VendorLocationLine2]  
   , ISNULL(PO.BillingAddressLine3,'') AS [VendorLocationLine3]   
   , ISNULL(REPLACE(RTRIM(  
      COALESCE(PO.BillingAddressCity, '') +   
      COALESCE(', ' + RTRIM(PO.BillingAddressStateProvince), '') +       
      COALESCE(' ' + PO.BillingAddressPostalCode, '') +            
      COALESCE(' ' + PO.BillingAddressCountryCode, '')   
     ), '  ', ' ')  
     ,'') AS [VendorLocationCityStZip]  
   , PO.DispatchPhoneNumber AS [DispatchPhoneNumber]  
   , PO.FaxPhoneNumber AS [FaxPhoneNumber]  
   , 'TalkedTo' AS [TalkedTo] -- TODO: Linked to ContactLog and get Talked To  
   , CL.Name AS [Client]  
   , P.Name AS [Program]  
   , MS.MembershipNumber AS [MemberNumber]  
   , C.MemberStatus  
   , REPLACE(RTRIM(  
    COALESCE(CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+  
    COALESCE(' ' + LEFT(M.MiddleName,1),'')+  
    COALESCE(' ' + CASE WHEN M.LastName = '' THEN NULL ELSE M.LastName END,'')+    
    COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')  
    ),'','') AS [CustomerName]  
   , C.ContactPhoneNumber AS [CallbackNumber]   
   , C.ContactAltPhoneNumber AS [AlternateNumber]  
   --, PO.SubTotal AS [SubTotal]  calculated from PO Details GRID  
   , PO.TaxAmount AS [Tax]  
   , PO.TotalServiceAmount AS [ServiceTotal]  
   , PO.CoachNetServiceAmount AS [CoachNetPays]  
   , PO.MemberServiceAmount AS [MemberPays]  
   , VT.Name + ' - ' + VC.Name AS [VehicleType]  
   , REPLACE(RTRIM(  
    COALESCE(C.VehicleYear,'')+  
    COALESCE(' ' + CASE WHEN C.VehicleMake = 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END,'')+  
    COALESCE(' ' + CASE WHEN C.VehicleModel = 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END,'')  
    ), '','') AS [Vehicle]  
   , ISNULL(C.VehicleVIN,'') AS [VIN]  
   , ISNULL(C.VehicleColor,'') AS [Color]  
   , REPLACE(RTRIM(  
     COALESCE(C.VehicleLicenseState + ' - ','') +  
     COALESCE(C.VehicleLicenseNumber,'')   
    ),'','') AS [License]  
   , ISNULL(C.VehicleCurrentMileage,'') AS [Mileage]  
   , ISNULL(SR.ServiceLocationAddress,'') AS [Location]  
   , ISNULL(SR.ServiceLocationDescription,'') AS [LocationDescription]  
   , ISNULL(SR.DestinationAddress,'') AS [Destination]  
   , ISNULL(SR.DestinationDescription,'') AS [DestinationDescription]  
   , PO.CreateBy  
   , PO.CreateDate  
   , PO.ModifyBy  
   , PO.ModifyDate   
   , CT.Abbreviation AS [CurrencyType]   
   , PO.IsPayByCompanyCreditCard AS IsPayByCC  
   , PO.CompanyCreditCardNumber CompanyCC  
   ,PO.VendorTaxID  
   ,PO.Email  
   ,POPS.[Description] PurchaseOrderPayStatus  
FROM  PurchaseOrder PO   
JOIN  PurchaseOrderStatus POS WITH (NOLOCK)ON POS.ID = PO.PurchaseOrderStatusID  
LEFT JOIN PurchaseOrderPayStatusCode POPS WITH (NOLOCK) ON POPS.ID = PO.PayStatusCodeID  
JOIN  ServiceRequest SR WITH (NOLOCK) ON SR.ID = PO.ServiceRequestID  
LEFT JOIN ServiceRequestStatus SRS WITH (NOLOCK) ON SRS.ID = SR.ServiceRequestStatusID  
LEFT JOIN ProductCategory PCSR ON PCSR.ID = SR.ProductCategoryID  
JOIN  [Case] C WITH (NOLOCK) ON C.ID = SR.CaseID  
JOIN  Program P WITH (NOLOCK) ON P.ID = C.ProgramID  
JOIN  Client CL WITH (NOLOCK) ON CL.ID = P.ClientID  
JOIN  Member M WITH (NOLOCK) ON M.ID = C.MemberID  
JOIN  Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID  
LEFT JOIN  Product PR WITH (NOLOCK) ON PR.ID = PO.ProductID  
LEFT JOIN  ProductCategory PC WITH (NOLOCK) ON PC.ID = PR.ProductCategoryID  
LEFT JOIN VehicleType VT WITH(NOLOCK) ON VT.ID = C.VehicleTypeID  
LEFT JOIN VehicleCategory VC WITH(NOLOCK) ON VC.ID = C.VehicleCategoryID  
LEFT JOIN RVType RT WITH (NOLOCK) ON RT.ID = C.VehicleRVTypeID  
JOIN  VendorLocation VL WITH(NOLOCK) ON VL.ID = PO.VendorLocationID  
JOIN  Vendor V WITH(NOLOCK) ON V.ID = VL.VendorID  
--LEFT JOIN [Contract] CO ON CO.VendorID = V.ID  AND CO.IsActive = 1  
--LEFT JOIN ContractRateSchedule CRS ON CRS.ContractID = V.ID AND CO.IsActive = 1  
LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID   
LEFT JOIN CurrencyType CT ON CT.ID=PO.CurrencyTypeID  
WHERE  PO.PurchaseOrderNumber = @PONumber  
   AND PO.IsActive = 1  
  
END  

GO

GO
-- Get Vendor Billing with logic added to check for Alternate
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get @VendorLocationID=356, @POID=619
 CREATE PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get( 
	@VendorLocationID INT =NULL
	, @POID INT = NULL
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET FMTONLY OFF
SELECT V.ID
	--, CASE
	--	WHEN ISNULL(CRS.ID,'') = '' THEN 'Not Contracted'
	--	ELSE 'Contracted'
	--	END AS 'ContractStatus'
	, CASE
		WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted'
		ELSE 'Not Contracted' 
		END AS ContractStatus
	, V.Name
	, V.VendorNumber
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN ''
		WHEN ISNULL(VI.ID, '') <> '' THEN VI.BillingAddressLine1
		ELSE AE.Line1
		END AS Line1
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN ''
		WHEN ISNULL(VI.ID, '') <> '' THEN VI.BillingAddressLine2
		ELSE AE.Line2
	END AS Line2
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN ''
		WHEN ISNULL(VI.ID, '') <> '' THEN VI.BillingAddressLine3
		ELSE AE.Line3
	END AS Line3
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN 'No billing address on file'
		WHEN ISNULL(VI.ID,'') <> '' THEN
		ISNULL(REPLACE(RTRIM(
			COALESCE(VI.BillingAddressCity, '') +
			COALESCE(', ' + VI.BillingAddressStateProvince, '') +
			COALESCE(' ' + VI.BillingAddressPostalCode, '') +
			COALESCE(' ' + VI.BillingAddressCountryCode, '')
		), ' ', ' ')
	,'')
	ELSE ISNULL(REPLACE(RTRIM(
			COALESCE(AE.City, '') +
			COALESCE(', ' + AE.StateProvince, '') +
			COALESCE(' ' + AE.PostalCode, '') +
			COALESCE(' ' + AE.CountryCode, '')
		), ' ', ' ')
	,'')
	END AS BillingCityStZip
	, ISNULL(REPLACE(RTRIM(
		COALESCE(V.TaxSSN,'')+
		COALESCE(V.TaxEIN,'')
		), ' ', ' ')
	,'') AS TaxID
	, PE.PhoneNumber
	, V.Email
	, (V.ContactFirstName + ' ' + V.ContactLastName) AS ContactName
	, VI.ID AS VendorInvoiceID
FROM		Vendor V
JOIN		VendorLocation VL ON VL.VendorID = V.ID
LEFT JOIN	Contract C ON C.VendorID = V.ID
			AND C.IsActive = 1
LEFT JOIN ContractRateSchedule CRS ON CRS.ContractID = V.ID
			AND C.IsActive = 1
LEFT JOIN	AddressEntity AE ON AE.RecordID = V.ID
			AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
			AND	AE.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Billing')
LEFT JOIN	PhoneEntity PE ON PE.RecordID = V.ID
			AND	PE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
			AND PE.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Office')
LEFT JOIN	VendorInvoice VI ON VI.PurchaseOrderID = @POID
LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID
WHERE VL.ID = @VendorLocationID
END
GO
GO

GO
-- Get VendorLocation data
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_Vendor_Location_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_Vendor_Location_Details_Get @VendorLocationID=356
 CREATE PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Details_Get( 
	@VendorLocationID INT =NULL
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET FMTONLY OFF
	
	SELECT VL.ID
	 ,CASE WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted' ELSE 'Not Contracted' END AS 'ContractStatus'
	, V.Name
	, V.VendorNumber
	, AE.Line1
	, AE.Line2
	, AE.Line3
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN 'No billing address on file'
		ELSE ISNULL(REPLACE(RTRIM(
			COALESCE(AE.City, '') +
			COALESCE(', ' + AE.StateProvince, '') +
			COALESCE(' ' + AE.PostalCode, '') +
			COALESCE(' ' + AE.CountryCode, '')
		), ' ', ' ')
	,'')
	END AS BillingCityStZip
	, PE24.PhoneNumber AS [24HRNumber]
	, PEFax.PhoneNumber AS FaxNumber
	, 'Talked To' AS TalkedTo
	
	FROM VendorLocation VL
	JOIN Vendor V ON V.ID = VL.VendorID
	LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID
	LEFT JOIN Contract C ON C.VendorID = V.ID
	AND C.IsActive = 1
	LEFT JOIN ContractRateSchedule CRS ON CRS.ContractID = V.ID
	AND C.IsActive = 1
	LEFT JOIN AddressEntity AE ON AE.RecordID = VL.ID
	AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
	AND AE.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Business')
	LEFT JOIN PhoneEntity PE24 ON PE24.RecordID = VL.ID
	AND PE24.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
	AND PE24.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Dispatch')
	LEFT JOIN PhoneEntity PEFax ON PEFax.RecordID = VL.ID
	AND PEFax.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
	AND PEFax.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Fax')
	WHERE VL.ID = @VendorLocationID
END
GO
GO

GO
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
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_vendor_list] @pageSize=5000 @whereClauseXML="<ROW>\r\n  <Filter VendorNumber=\'1,4\' />\r\n</ROW>"
 
 CREATE PROCEDURE [dbo].[dms_vendor_list](
   
 @whereClauseXML NVARCHAR(4000) = NULL 

 , @startInd Int = 1 

 , @endInd BIGINT = 5000 

 , @pageSize int = 10  

 , @sortColumn nvarchar(100)  = 'VendorName' 

 , @sortOrder nvarchar(100) = 'ASC' 

  

 ) 

 AS 

 BEGIN   
 SET FMTONLY OFF  
  SET NOCOUNT ON  
  
CREATE TABLE #FinalResultsFiltered  
(  
 ContractStatus NVARCHAR(100) NULL,  
 VendorID INT NULL,  
 VendorNumber NVARCHAR(50) NULL,  
 VendorName NVARCHAR(255) NULL,  
 City NVARCHAR(100) NULL,  
 StateProvince NVARCHAR(10) NULL,  
 CountryCode NVARCHAR(2) NULL,  
 OfficePhone NVARCHAR(50) NULL,  
 AdminRating INT NULL,  
 InsuranceExpirationDate DATETIME NULL,  
 PaymentMethod NVARCHAR(50) NULL,  
 VendorStatus NVARCHAR(50) NULL,  
 VendorRegion NVARCHAR(50) NULL,  
 PostalCode NVARCHAR(20) NULL  ,
 POCount INT NULL
)  
  
CREATE TABLE #FinalResultsSorted  
(  
 RowNum BIGINT NOT NULL IDENTITY(1,1),  
 ContractStatus NVARCHAR(100) NULL,  
 VendorID INT NULL,  
 VendorNumber NVARCHAR(50) NULL,  
 VendorName NVARCHAR(255) NULL,  
 City NVARCHAR(100) NULL,  
 StateProvince NVARCHAR(10) NULL,  
 CountryCode NVARCHAR(2) NULL,  
 OfficePhone NVARCHAR(50) NULL,  
 AdminRating INT NULL,  
 InsuranceExpirationDate DATETIME NULL,  
 PaymentMethod NVARCHAR(50) NULL,  
 VendorStatus NVARCHAR(50) NULL,  
 VendorRegion NVARCHAR(50) NULL,  
 PostalCode NVARCHAR(20) NULL ,
 POCount INT NULL 
)  
  
DECLARE @idoc int  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
VendorNameOperator NVARCHAR(50) NULL,  
VendorName NVARCHAR(MAX) NULL,  
VendorNumber NVARCHAR(50) NULL,  
CountryID INT NULL,  
StateProvinceID INT NULL,  
City nvarchar(255) NULL,  
VendorStatus NVARCHAR(100) NULL,  
VendorRegion NVARCHAR(100) NULL,  
PostalCode NVARCHAR(20) NULL,  
IsLevy BIT NULL  ,
HasPO BIT NULL,
IsFordDirectTow BIT NULL,
IsCNETDirectPartner BIT NULL
)  
  
DECLARE @VendorNameOperator NVARCHAR(50) ,  
@VendorName NVARCHAR(MAX) ,  
@VendorNumber NVARCHAR(50) ,  
@CountryID INT ,  
@StateProvinceID INT ,  
@City nvarchar(255) ,  
@VendorStatus NVARCHAR(100) ,  
@VendorRegion NVARCHAR(100) ,  
@PostalCode NVARCHAR(20) ,  
@IsLevy BIT,
@HasPO BIT   ,
@programID INT	= NULL,
@IsFordDirectTow BIT,
@IsCNETDirectPartner BIT
  
INSERT INTO @tmpForWhereClause  
SELECT    
 VendorNameOperator,  
 VendorName ,  
 VendorNumber,  
 CountryID,  
 StateProvinceID,  
 City,  
 VendorStatus,  
 VendorRegion,  
    PostalCode,  
    IsLevy ,
	HasPo,
	IsFordDirectTow,
	IsCNETDirectPartner
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
 VendorNameOperator NVARCHAR(50),  
 VendorName NVARCHAR(MAX),  
 VendorNumber NVARCHAR(50),   
 CountryID INT,  
 StateProvinceID INT,  
 City nvarchar(255),   
 VendorStatus NVARCHAR(100),  
 VendorRegion NVARCHAR(100),  
 PostalCode NVARCHAR(20),  
 IsLevy BIT ,
 HasPo BIT,
 IsFordDirectTow BIT,
 IsCNETDirectPartner BIT
)   
  
SELECT    
  @VendorNameOperator = VendorNameOperator ,  
  @VendorName = VendorName ,  
  @VendorNumber = VendorNumber,  
  @CountryID = CountryID,  
  @StateProvinceID = StateProvinceID,  
  @City = City,  
  @VendorStatus = VendorStatus,  
  @VendorRegion = VendorRegion,  
  @PostalCode = PostalCode,  
  @IsLevy = IsLevy  ,
  @HasPO = HasPO,
  @IsFordDirectTow = IsFordDirectTow,
  @IsCNETDirectPartner = IsCNETDirectPartner
FROM @tmpForWhereClause  
  
--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
-- LOGIC : START  

DECLARE @PoCount AS TABLE(VendorID INT NULL,PoCount INT NULL)
INSERT INTO @PoCount
SELECT V.ID,
	   COUNT(PO.ID) FROM PurchaseOrder PO 
	   LEFT JOIN VendorLocation VL ON PO.VendorLocationID = VL.ID
	   LEFT JOIN Vendor V ON VL.VendorID = V.ID
WHERE  PO.IsActive = 1
GROUP BY V.ID 
  
DECLARE @vendorEntityID INT, @businessAddressTypeID INT, @officePhoneTypeID INT  
SELECT @vendorEntityID = ID FROM Entity WHERE Name = 'Vendor'  
SELECT @businessAddressTypeID = ID FROM AddressType WHERE Name = 'Business'  
SELECT @officePhoneTypeID = ID FROM PhoneType WHERE Name = 'Office'  
  
;WITH wVendorAddresses  
AS  
(   
 SELECT ROW_NUMBER() OVER ( PARTITION BY RecordID, AddressTypeID ORDER BY ID ) AS RowNum,  
   *  
 FROM AddressEntity   
 WHERE EntityID = @vendorEntityID  
 AND  AddressTypeID = @businessAddressTypeID  
),
wVendorPhone
AS

(

	SELECT ROW_NUMBER() OVER ( PARTITION BY RecordID, PhoneTypeID ORDER BY ID DESC ) AS RowNum,

			*

	FROM	PhoneEntity 

	WHERE	EntityID = @vendorEntityID

	AND		PhoneTypeID = @officePhoneTypeID

)

INSERT INTO #FinalResultsFiltered  
SELECT DISTINCT  
  --CASE WHEN C.VendorID IS NOT NULL   
  --  THEN 'Contracted'   
  --  ELSE 'Not Contracted'   
  --  END AS ContractStatus  
  --NULL As ContractStatus  
  CASE WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted' ELSE 'Not Contracted' END AS ContractStatus  
  , V.ID AS VendorID  
  , V.VendorNumber AS VendorNumber  
  --, V.Name AS VendorName  
 -- ,v.Name +	
	--CASE WHEN VPCNDP.VendorID IS NOT NULL THEN ' (P)' ELSE '' END  + 
	--CASE WHEN VPFDT.VendorID IS NOT NULL 
	--		THEN ' (DT)' 
	--ELSE '' END VendorName
  , v.Name + COALESCE(F.Indicators,'') AS VendorName
  , AE.City AS City  
  , AE.StateProvince AS State  
  , AE.CountryCode AS Country  
  , PE.PhoneNumber AS OfficePhone  
  , V.AdministrativeRating AS AdminRating  
  , V.InsuranceExpirationDate AS InsuranceExpirationDate  
  , VACH.BankABANumber AS PaymentMethod -- To be calculated in the next step.  
  , VS.Name AS VendorStatus  
  , VR.Name AS VendorRegion  
  , AE.PostalCode  
  , ISNULL((SELECT PoCount FROM @PoCount POD WHERE POD.VendorID = V.ID),0) AS POCount
FROM Vendor V WITH (NOLOCK)  
LEFT JOIN [dbo].[fnc_GetVendorIndicators]('Vendor') F ON V.ID = F.RecordID
--LEFT JOIN   VendorLocation VL ON V.ID = VL.VendorID
--Left Outer Join VendorProduct VPFDT ON VPFDT.VendorID = V.ID and VPFDT.ProductID = (Select ID from Product where Name = 'Ford Direct Tow') and VPFDT.IsActive = 1
--Left Outer Join VendorProduct VPCNDP on VPCNDP.VendorID = V.ID and VPCNDP.ProductID = (Select ID from Product where Name = 'CoachNet Dealer Partner') and VPCNDP.IsActive = 1
--LEFT JOIN   PurchaseOrder PO ON VL.ID = PO.VendorLocationID AND ISNULL(PO.IsActive,0) = 1
LEFT JOIN [dbo].[fnGetDirectTowVendors]() VPFDT ON VPFDT.VendorID = V.ID
LEFT JOIN [dbo].[fnGetCoachNetDealerPartnerVendors]() VPCNDP ON VPCNDP.VendorID = V.ID
LEFT JOIN wVendorAddresses AE ON AE.RecordID = V.ID AND AE.RowNum = 1  
LEFT JOIN	wVendorPhone PE ON PE.RecordID = V.ID AND PE.RowNum = 1  
LEFT JOIN VendorStatus VS ON VS.ID = V.VendorStatusID  
LEFT JOIN VendorACH VACH ON VACH.VendorID = V.ID  
LEFT JOIN VendorRegion VR ON VR.ID=V.VendorRegionID  
LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID  
--LEFT OUTER JOIN (SELECT VendorID, MAX(CreateDate) AS [CreateDate] FROM [Contract] WHERE IsActive = 1 GROUP BY VendorID) C ON C.VendorID = V.ID  =
WHERE V.IsActive = 1  -- Not deleted    
AND  (@VendorNumber IS NULL OR @VendorNumber = V.VendorNumber)  
AND  (@CountryID IS NULL OR @CountryID = AE.CountryID)  
AND  (@StateProvinceID IS NULL OR @StateProvinceID = AE.StateProvinceID)  
AND  (@City IS NULL OR @City = AE.City)  
AND  (@PostalCode IS NULL OR @PostalCode = AE.PostalCode)  
AND  (@IsLevy IS NULL OR @IsLevy = ISNULL(V.IsLevyActive,0))  
AND  (@IsFordDirectTow IS NULL OR (@IsFordDirectTow = 1 AND COALESCE(F.Indicators,'') LIKE '%(DT)%'))  
AND  (@IsCNETDirectPartner IS NULL OR (@IsCNETDirectPartner = 1 AND COALESCE(F.Indicators,'') LIKE '%(P)%'))  
AND  (@VendorStatus IS NULL OR VS.ID IN (SELECT Item FROM [dbo].[fnSplitString](@VendorStatus,',') ) )  
AND  (@VendorRegion IS NULL OR VR.ID IN (SELECT Item FROM [dbo].[fnSplitString](@VendorRegion,',') ) )  
AND  (    
   (@VendorNameOperator IS NULL )  
   OR  
   (@VendorNameOperator = 'Begins with' AND V.Name LIKE  @VendorName + '%')  
   OR  
   (@VendorNameOperator = 'Is equal to' AND V.Name =  @VendorName )  
   OR  
   (@VendorNameOperator = 'Ends with' AND V.Name LIKE  '%' + @VendorName)  
   OR  
   (@VendorNameOperator = 'Contains' AND V.Name LIKE  '%' + @VendorName + '%')  
  )  
 --GROUP BY 

	--	ContractStatus,
	--	V.ID,
	--	V.VendorNumber,
	--	V.Name,
	--	AE.City,
	--	AE.StateProvince,
	--	AE.CountryCode,
	--	PE.PhoneNumber,
	--	V.AdministrativeRating,
	--	V.InsuranceExpirationDate,
	--	VACH.BankABANumber,
	--	VS.Name,
	--	VR.Name,
	--	AE.PostalCode,
	--	ContractedVendors.ContractRateScheduleID,
	--	ContractedVendors.ContractID
 --UPDATE #FinalResultsFiltered  
 --SET ContractStatus = CASE WHEN C.VendorID IS NOT NULL   
 --      THEN 'Contracted'   
 --      ELSE 'Not Contracted'   
 --      END,  
 -- PaymentMethod =  CASE  
 --      WHEN ISNULL(F.PaymentMethod,'') = '' THEN 'Check'  
 --      ELSE 'DirectDeposit'  
 --      END  
 --FROM #FinalResultsFiltered F  
 --LEFT OUTER JOIN (SELECT VendorID, MAX(CreateDate) AS [CreateDate] FROM [Contract] WHERE IsActive = 1 GROUP BY VendorID) C ON C.VendorID = F.VendorID  
   
 INSERT INTO #FinalResultsSorted  
 SELECT   ContractStatus  
  , VendorID  
  , VendorNumber  
  , VendorName  
  , City  
  , StateProvince  
  , CountryCode  
  , OfficePhone  
  , AdminRating  
  , InsuranceExpirationDate  
  , PaymentMethod  
  , VendorStatus  
  , VendorRegion  
  , PostalCode  
  , POCount
 FROM #FinalResultsFiltered T   
 WHERE	(@HasPO IS NULL OR @HasPO = 0 OR T.POCount > 0)
 ORDER BY   
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'ASC'  
  THEN T.ContractStatus END ASC,   
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'DESC'  
  THEN T.ContractStatus END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'ASC'  
  THEN T.VendorID END ASC,   
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'DESC'  
  THEN T.VendorID END DESC ,  
    
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'  
  THEN T.VendorNumber END ASC,   
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'  
  THEN T.VendorNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'ASC'  
  THEN T.VendorName END ASC,   
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'DESC'  
  THEN T.VendorName END DESC ,  
  
  CASE WHEN @sortColumn = 'City' AND @sortOrder = 'ASC'  
  THEN T.City END ASC,   
  CASE WHEN @sortColumn = 'City' AND @sortOrder = 'DESC'  
  THEN T.City END DESC ,  
    
  CASE WHEN @sortColumn = 'StateProvince' AND @sortOrder = 'ASC'  
  THEN T.StateProvince END ASC,   
  CASE WHEN @sortColumn = 'StateProvince' AND @sortOrder = 'DESC'  
  THEN T.StateProvince END DESC ,  
  
  CASE WHEN @sortColumn = 'CountryCode' AND @sortOrder = 'ASC'  
  THEN T.CountryCode END ASC,   
  CASE WHEN @sortColumn = 'CountryCode' AND @sortOrder = 'DESC'  
  THEN T.CountryCode END DESC ,  
    
  CASE WHEN @sortColumn = 'OfficePhone' AND @sortOrder = 'ASC'  
  THEN T.OfficePhone END ASC,   
  CASE WHEN @sortColumn = 'OfficePhone' AND @sortOrder = 'DESC'  
  THEN T.OfficePhone END DESC ,  
    
  CASE WHEN @sortColumn = 'AdminRating' AND @sortOrder = 'ASC'  
  THEN T.AdminRating END ASC,   
  CASE WHEN @sortColumn = 'AdminRating' AND @sortOrder = 'DESC'  
  THEN T.AdminRating END DESC ,  
    
  CASE WHEN @sortColumn = 'InsuranceExpirationDate' AND @sortOrder = 'ASC'  
  THEN T.InsuranceExpirationDate END ASC,   
  CASE WHEN @sortColumn = 'InsuranceExpirationDate' AND @sortOrder = 'DESC'  
  THEN T.InsuranceExpirationDate END DESC ,  
    
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'ASC'  
  THEN T.VendorStatus END ASC,   
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'DESC'  
  THEN T.VendorStatus END DESC ,  
    
  CASE WHEN @sortColumn = 'VendorRegion' AND @sortOrder = 'ASC'  
  THEN T.VendorRegion END ASC,   
  CASE WHEN @sortColumn = 'VendorRegion' AND @sortOrder = 'DESC'  
  THEN T.VendorRegion END DESC ,  
  --VendorRegion  
  CASE WHEN @sortColumn = 'PaymentMethod' AND @sortOrder = 'ASC'  
  THEN T.PaymentMethod END ASC,   
  CASE WHEN @sortColumn = 'PaymentMethod' AND @sortOrder = 'DESC'  
  THEN T.PaymentMethod END DESC ,  
     
  CASE WHEN @sortColumn = 'PostalCode' AND @sortOrder = 'ASC'  
  THEN T.PostalCode END ASC,   
  CASE WHEN @sortColumn = 'PostalCode' AND @sortOrder = 'DESC'  
  THEN T.PostalCode END DESC   ,
  
  CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'
	THEN T.POCount END ASC, 
	CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'
	 THEN T.POCount END DESC 

   
  
DECLARE @count INT     
SET @count = 0     
SELECT @count = MAX(RowNum) FROM #FinalResultsSorted  
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
  
SELECT @count AS TotalRows, * FROM #FinalResultsSorted WHERE RowNum BETWEEN @startInd AND @endInd  
  
END  
GO

GO
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
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Portal_Invoice_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Portal_Invoice_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC   [dbo].[dms_Vendor_Portal_Invoice_List_Get] @vendorID = 190, @whereClauseXML = '<ROW><Filter PurchaseOrderNumberValue="7770395"/></ROW>' 
 CREATE PROCEDURE [dbo].[dms_Vendor_Portal_Invoice_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = 'IssueDate' 
 , @sortOrder nvarchar(100) = 'DESC'
 , @VendorID INT = NULL 
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 

 ></Filter></ROW>'
END

SET FMTONLY OFF;

CREATE TABLE #tmpForWhereClause
(

PurchaseOrderNumberValue nvarchar(100) NULL,
FromDate DATETIME NULL,
ToDate DATETIME NULL
)

CREATE TABLE #tmpFinalResults( 	
	ID int  NULL ,
	PurchaseOrderNumber nvarchar(100)  NULL ,
	IssueDate datetime  NULL ,
	Service nvarchar(100)  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceAmount money NULL,
	InvoiceDate datetime  NULL ,
	ToBePaidDate datetime  NULL ,
	PaymentType nvarchar(100)  NULL ,
	ReceivedDate datetime NULL,
	SubmitMethod nvarchar(100) NULL
) 

 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	PurchaseOrderNumber nvarchar(100)  NULL ,
	IssueDate datetime  NULL ,
	Service nvarchar(100)  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceAmount money NULL,
	InvoiceDate datetime  NULL ,
	ToBePaidDate datetime  NULL ,
	PaymentType nvarchar(100)  NULL ,
	ReceivedDate datetime NULL,
	SubmitMethod nvarchar(100) NULL
) 

INSERT INTO #tmpForWhereClause
SELECT  
	
	T.c.value('@PurchaseOrderNumberValue','nvarchar(100)'),
	T.c.value('@FromDate','datetime') ,
	T.c.value('@ToDate','datetime') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @poNumber NVARCHAR(100) = NULL,
		@fromDate DATETIME = NULL,
		@toDate DATETIME = NULL
		
SELECT	@poNumber = PurchaseOrderNumberValue, 
		@fromDate = FromDate,
		@toDate = ToDate
FROM	#tmpForWhereClause


IF @toDate IS NOT NULL
BEGIN
	SET @toDate = DATEADD(DD,1,@toDate)
END

IF @fromDate IS NULL AND @toDate IS NULL
BEGIN
	--SET @fromDate = DATEADD(DD,-30,GETDATE())
	SET @toDate = DATEADD(DD,1,GETDATE())
END


--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------


INSERT INTO #tmpFinalResults
SELECT	VI.ID
		, PO.PurchaseOrderNumber
		, PO.IssueDate
		, P.Name AS Service
		, VI.InvoiceNumber
		, VI.InvoiceAmount
		, VI.InvoiceDate		
		, VI.PaymentDate
		, PT.Name AS PaymentType
		, VI.ReceivedDate 
		, CM.Name AS SubmitMethod
FROM	PurchaseOrder PO
JOIN	PurchaseOrderStatus POS ON POS.ID = PO.PurchaseOrderStatusID
JOIN	Product P ON P.ID = PO.ProductID
JOIN	VendorLocation VL ON VL.ID = PO.VendorLocationID 
JOIN	Vendor V ON V.ID = VL.VendorID 
LEFT JOIN VendorInvoice VI ON VI.PurchaseOrderID = PO.ID 
LEFT JOIN VendorInvoiceStatus VIS ON VIS.ID = VI.VendorInvoiceStatusID
LEFT JOIN PaymentType PT ON PT.ID = VI.PaymentTypeID
LEFT JOIN ContactMethod CM ON CM.ID = VI.ReceiveContactMethodID
WHERE	VI.VendorID = @VendorID
AND		(@poNumber IS NULL OR @poNumber = PO.PurchaseOrderNumber)
AND		(@fromDate IS NULL OR PO.IssueDate >= @fromDate)
AND		(@toDate IS NULL OR PO.IssueDate <= @toDate)
AND		DATEDIFF(dd,PO.IssueDate,getdate())<=89 

INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.PurchaseOrderNumber,
	T.IssueDate,
	T.[Service],
	T.InvoiceNumber,
	T.InvoiceAmount,
	T.InvoiceDate,
	T.ToBePaidDate,
	T.PaymentType,
	T.ReceivedDate,
	T.SubmitMethod
FROM #tmpFinalResults T

 ORDER BY 
	 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'ASC'
	 THEN T.PurchaseOrderNumber END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'DESC'
	 THEN T.PurchaseOrderNumber END DESC ,

	 CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'ASC'
	 THEN T.IssueDate END ASC, 
	 CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'DESC'
	 THEN T.IssueDate END DESC ,

	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'ASC'
	 THEN T.Service END ASC, 
	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'DESC'
	 THEN T.Service END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN T.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN T.InvoiceNumber END DESC ,
	 
	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'
	 THEN T.InvoiceAmount END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'
	 THEN T.InvoiceAmount END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'ASC'
	 THEN T.InvoiceDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'DESC'
	 THEN T.InvoiceDate END DESC ,

	 CASE WHEN @sortColumn = 'ToBePaidDate' AND @sortOrder = 'ASC'
	 THEN T.ToBePaidDate END ASC, 
	 CASE WHEN @sortColumn = 'ToBePaidDate' AND @sortOrder = 'DESC'
	 THEN T.ToBePaidDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'ASC'
	 THEN T.PaymentType END ASC, 
	 CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'DESC'
	 THEN T.PaymentType END DESC ,
	 
	 CASE WHEN @sortColumn = 'SubmitMethod' AND @sortOrder = 'ASC'
	 THEN T.SubmitMethod END ASC, 
	 CASE WHEN @sortColumn = 'SubmitMethod' AND @sortOrder = 'DESC'
	 THEN T.SubmitMethod END DESC

DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM #FinalResults
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

SELECT @count AS TotalRows, * FROM #FinalResults WHERE RowNum BETWEEN @startInd AND @endInd

DROP TABLE #tmpForWhereClause
DROP TABLE #FinalResults
DROP TABLE #tmpFinalResults
END

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Portal_Services_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Portal_Services_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 --EXEC dms_Vendor_Services_List_Get @VendorID=1
CREATE PROCEDURE [dbo].[dms_Vendor_Portal_Services_List_Get] @VendorID INT
AS
BEGIN
      -- SET NOCOUNT ON added to prevent extra result sets from
      -- interfering with SELECT statements.
      SET NOCOUNT ON;
DECLARE @FinalResults AS TABLE(
      SortOrder INT NULL,
      ServiceGroup NVARCHAR(255) NULL,
      ServiceName nvarchar(100)  NULL ,
      ProductID int  NULL ,
      VehicleCategorySequence int  NULL ,
      ProductCategory nvarchar(100)  NULL ,
      IsAvailByVendor bit default 0
) 

INSERT INTO @FinalResults (SortOrder, ServiceGroup,ServiceName,ProductID,VehicleCategorySequence,ProductCategory)
      SELECT 
                   CASE WHEN vc.name is NULL THEN 2 
                              ELSE 1 
                   END AS SortOrder
                  ,CASE WHEN vc.name is NULL THEN 'Other' 
                              ELSE vc.name 
                   END AS ServiceGroup
                  ,REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
                  --,ISNULL(vc.Name,'') + CASE WHEN ISNULL(vc.Name,'') <> '' THEN ' - ' ELSE '' END  + REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
                  ,p.ID AS ProductID
                  ,vc.Sequence VehicleCategorySequence
                  ,pc.Name ProductCategory                  
      FROM Product p
      JOIN ProductCategory pc on p.productCategoryid = pc.id
      JOIN ProductType pt on p.ProductTypeID = pt.ID
      JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
      LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
      LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
      WHERE pt.Name = 'Service'
      AND pst.Name IN ('PrimaryService', 'SecondaryService')
      AND p.Name Not in ('Concierge', 'Information', 'Tech')
      AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee')

      UNION
      SELECT 
                  3 AS SortOrder
                  ,'Additional' AS ServiceGroup
                  ,p.Name AS ServiceName
                  ,p.ID AS ProductID
                  ,vc.Sequence VehicleCategorySequence
                  ,pc.Name ProductCategory
      FROM  Product p
      JOIN ProductCategory pc on p.productCategoryid = pc.id
      JOIN ProductType pt on p.ProductTypeID = pt.ID
      JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
      LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
      LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
      WHERE pt.Name = 'Service'
      AND pst.Name IN ('AdditionalService')
      AND p.Name Not in ('Concierge', 'Information', 'Tech')
      AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials') 
      
      --UNION
      --SELECT 
      --            4 AS SortOrder
      --            ,'ISP Selection' AS ServiceGroup
      --            ,p.Name AS ServiceName
      --            ,p.ID AS ProductID
      --            ,vc.Sequence VehicleCategorySequence
      --            ,pc.Name ProductCategory
      --FROM  Product p
      --JOIN ProductCategory pc on p.productCategoryid = pc.id
      --JOIN ProductType pt on p.ProductTypeID = pt.ID
      --JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
      --LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
      --LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
      --WHERE pt.Name = 'Attribute'
      --AND pst.Name = 'Ranking'
      --AND pc.Name = 'ISPSelection'
      
      UNION ALL
      
      SELECT 
                  5 AS SortOrder
                  ,pst.Name AS ServiceGroup 
                  ,p.Name AS ServiceName
                  ,p.ID AS ProductID
                  ,vc.Sequence VehicleCategorySequence
                  ,pc.Name ProductCategory
      FROM Product p
      Join ProductCategory pc on p.productCategoryid = pc.id
      Join ProductType pt on p.ProductTypeID = pt.ID
      Join ProductSubType pst on p.ProductSubTypeID = pst.id
      Left Outer Join VehicleCategory vc on p.VehicleCategoryID = vc.ID
      Left Outer Join VehicleType vt on p.VehicleTypeID = vt.ID
      Where pt.Name = 'Attribute'
      and pc.Name = 'Repair'
      --and pst.Name NOT IN ('Client')
      ORDER BY SortOrder, VehicleCategorySequence, ProductCategory
      

UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
WHERE VP.VendorID=@VendorID
      
SELECT * FROM @FinalResults

END
GO

GO

GO
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
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_search] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vendor_search] @searchText = 'TX'
 CREATE PROCEDURE [dbo].[dms_vendor_search]( 
   @searchText	NVARCHAR(100) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 100 
 , @pageSize int = 100
 , @sortColumn nvarchar(100)  = 'VendorName' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
  
SET NOCOUNT ON

SET FMTONLY OFF

CREATE TABLE #FinalResults (
[RowNum] [bigint] NOT NULL IDENTITY(1,1),
VendorID INT NULL,
VendorNumber nvarchar(100) NULL ,
VendorName nvarchar(255) NULL ,
City nvarchar(100) NULL ,
StateProvince nvarchar(100) NULL,
VendorUser nvarchar(100) NULL
)

--------------------- BEGIN -----------------------------
---- Create a temp variable or a CTE with the actual SQL search query ----------
---- and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
-- LOGIC : BEGIN
DECLARE @vendorEntityID INT
DECLARE @vendorLocationEntityID INT
DECLARE @BusinessAddressTypeID INT

SELECT @vendorEntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
SELECT @vendorLocationEntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
SELECT @BusinessAddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Business')

INSERT INTO #FinalResults
SELECT	DISTINCT 
				V.ID,
				V.VendorNumber,
				V.Name AS VendorName,
				VA.City,
				VA.StateProvince,
				Case when VU.ID IS NULL
				THen ' '
				ELSE 'Yes'
				END
				 AS VendorUser
FROM	Vendor V WITH (NOLOCK)
LEFT JOIN VendorUser VU WITH (NOLOCK) ON V.ID = VU.VendorID
LEFT JOIN	AddressEntity VA WITH (NOLOCK) ON VA.RecordID = V.ID AND VA.EntityID = @vendorEntityID AND VA.AddressTypeID = @BusinessAddressTypeID
WHERE	V.IsActive=1 AND 
		(V.Name like '%' + @searchText + '%'
		OR
		V.VendorNumber like '%' + @searchText + '%'
		OR
		VA.City like '%' + @searchText + '%'
		OR
		VA.StateProvince like '%' + @searchText + '%'	)	
			
ORDER BY V.Name ASC


DECLARE @count INT
SET @count = 0
SELECT @count = MAX(RowNum) FROM #FinalResults
SET @endInd = @startInd + @pageSize - 1
IF @startInd > @count
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



SELECT	@count AS TotalRows, F.*

FROM	#FinalResults F
WHERE	F.RowNum BETWEEN @startInd AND @endInd

DROP TABLE #FinalResults



END

GO

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
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Portal_Invoice_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Portal_Invoice_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC   [dbo].[dms_Vendor_Portal_Invoice_List_Get] @vendorID = 190, @whereClauseXML = '<ROW><Filter PurchaseOrderNumberValue="7770395"/></ROW>' 
 CREATE PROCEDURE [dbo].[dms_Vendor_Portal_Invoice_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = 'IssueDate' 
 , @sortOrder nvarchar(100) = 'DESC'
 , @VendorID INT = NULL 
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 

 ></Filter></ROW>'
END

SET FMTONLY OFF;

CREATE TABLE #tmpForWhereClause
(

PurchaseOrderNumberValue nvarchar(100) NULL,
FromDate DATETIME NULL,
ToDate DATETIME NULL
)

CREATE TABLE #tmpFinalResults( 	
	ID int  NULL ,
	PurchaseOrderNumber nvarchar(100)  NULL ,
	IssueDate datetime  NULL ,
	Service nvarchar(100)  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceAmount money NULL,
	InvoiceDate datetime  NULL ,
	ToBePaidDate datetime  NULL ,
	PaymentType nvarchar(100)  NULL ,
	ReceivedDate datetime NULL,
	SubmitMethod nvarchar(100) NULL
) 

 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	PurchaseOrderNumber nvarchar(100)  NULL ,
	IssueDate datetime  NULL ,
	Service nvarchar(100)  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceAmount money NULL,
	InvoiceDate datetime  NULL ,
	ToBePaidDate datetime  NULL ,
	PaymentType nvarchar(100)  NULL ,
	ReceivedDate datetime NULL,
	SubmitMethod nvarchar(100) NULL
) 

INSERT INTO #tmpForWhereClause
SELECT  
	
	T.c.value('@PurchaseOrderNumberValue','nvarchar(100)'),
	T.c.value('@FromDate','datetime') ,
	T.c.value('@ToDate','datetime') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @poNumber NVARCHAR(100) = NULL,
		@fromDate DATETIME = NULL,
		@toDate DATETIME = NULL
		
SELECT	@poNumber = PurchaseOrderNumberValue, 
		@fromDate = FromDate,
		@toDate = ToDate
FROM	#tmpForWhereClause


IF @toDate IS NOT NULL
BEGIN
	SET @toDate = DATEADD(DD,1,@toDate)
END

IF @fromDate IS NULL AND @toDate IS NULL
BEGIN
	--SET @fromDate = DATEADD(DD,-30,GETDATE())
	SET @toDate = DATEADD(DD,1,GETDATE())
END


--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------


INSERT INTO #tmpFinalResults
SELECT	VI.ID
		, PO.PurchaseOrderNumber
		, PO.IssueDate
		, P.Name AS Service
		, VI.InvoiceNumber
		, VI.InvoiceAmount
		, VI.InvoiceDate		
		, VI.PaymentDate
		, PT.Name AS PaymentType
		, VI.ReceivedDate 
		, CM.Name AS SubmitMethod
FROM	PurchaseOrder PO
JOIN	PurchaseOrderStatus POS ON POS.ID = PO.PurchaseOrderStatusID
JOIN	Product P ON P.ID = PO.ProductID
JOIN	VendorLocation VL ON VL.ID = PO.VendorLocationID 
JOIN	Vendor V ON V.ID = VL.VendorID 
LEFT JOIN VendorInvoice VI ON VI.PurchaseOrderID = PO.ID 
LEFT JOIN VendorInvoiceStatus VIS ON VIS.ID = VI.VendorInvoiceStatusID
LEFT JOIN PaymentType PT ON PT.ID = VI.PaymentTypeID
LEFT JOIN ContactMethod CM ON CM.ID = VI.ReceiveContactMethodID
WHERE	VI.VendorID = @VendorID
AND		(@poNumber IS NULL OR @poNumber = PO.PurchaseOrderNumber)
AND		(@fromDate IS NULL OR PO.IssueDate >= @fromDate)
AND		(@toDate IS NULL OR PO.IssueDate <= @toDate)
AND		(VI.ID IS NOT NULL OR DATEDIFF(dd,PO.IssueDate,getdate())<=89) 


INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.PurchaseOrderNumber,
	T.IssueDate,
	T.[Service],
	T.InvoiceNumber,
	T.InvoiceAmount,
	T.InvoiceDate,
	T.ToBePaidDate,
	T.PaymentType,
	T.ReceivedDate,
	T.SubmitMethod
FROM #tmpFinalResults T

 ORDER BY 
	 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'ASC'
	 THEN T.PurchaseOrderNumber END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'DESC'
	 THEN T.PurchaseOrderNumber END DESC ,

	 CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'ASC'
	 THEN T.IssueDate END ASC, 
	 CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'DESC'
	 THEN T.IssueDate END DESC ,

	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'ASC'
	 THEN T.Service END ASC, 
	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'DESC'
	 THEN T.Service END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN T.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN T.InvoiceNumber END DESC ,
	 
	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'
	 THEN T.InvoiceAmount END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'
	 THEN T.InvoiceAmount END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'ASC'
	 THEN T.InvoiceDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'DESC'
	 THEN T.InvoiceDate END DESC ,

	 CASE WHEN @sortColumn = 'ToBePaidDate' AND @sortOrder = 'ASC'
	 THEN T.ToBePaidDate END ASC, 
	 CASE WHEN @sortColumn = 'ToBePaidDate' AND @sortOrder = 'DESC'
	 THEN T.ToBePaidDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'ASC'
	 THEN T.PaymentType END ASC, 
	 CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'DESC'
	 THEN T.PaymentType END DESC ,
	 
	 CASE WHEN @sortColumn = 'SubmitMethod' AND @sortOrder = 'ASC'
	 THEN T.SubmitMethod END ASC, 
	 CASE WHEN @sortColumn = 'SubmitMethod' AND @sortOrder = 'DESC'
	 THEN T.SubmitMethod END DESC

DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM #FinalResults
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

SELECT @count AS TotalRows, * FROM #FinalResults WHERE RowNum BETWEEN @startInd AND @endInd

DROP TABLE #tmpForWhereClause
DROP TABLE #FinalResults
DROP TABLE #tmpFinalResults
END


GO
