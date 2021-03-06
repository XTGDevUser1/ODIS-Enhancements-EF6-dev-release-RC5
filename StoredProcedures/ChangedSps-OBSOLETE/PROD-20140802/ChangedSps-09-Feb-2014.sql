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

UNION ALL

-- Emergency
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

UNION ALL
-- Service Request
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

UNION ALL
-- CASE
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

UNION ALL
-- PO
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

UNION ALL
-- Contact Logs
-- InboundCall, Emergency, SR, CASE and PO
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
 
 UNION ALL
 -- Case
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
 
 UNION ALL
 -- SR
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
 UNION ALL
 -- Emergency Assistance
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
 
 UNION ALL
 -- PO
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
 
 UNION ALL
 -- Comments
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
 WHERE id = object_id(N'[dbo].[dms_Client_ClosePeriod]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Client_ClosePeriod] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Client_ClosePeriod]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
BillingScheduleIDOperator="-1" 
ScheduleNameOperator="-1" 
ScheduleDateOperator="-1" 
ScheduleRangeBeginOperator="-1" 
ScheduleRangeEndOperator="-1" 
ScheduleTypeOperator="-1" 
ScheduleRangeTypeOperator="-1" 
ScheduleDateTypeOperator="-1" 
ScheduleStatusOperator="-1" 
TotalInvoiceCountOperator="-1" 
PostedInvoiceCountOperator="-1" 
CanBeClosedOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
BillingScheduleIDOperator INT NOT NULL,
BillingScheduleIDValue int NULL,
ScheduleNameOperator INT NOT NULL,
ScheduleNameValue nvarchar(100) NULL,
ScheduleDateOperator INT NOT NULL,
ScheduleDateValue datetime NULL,
ScheduleRangeBeginOperator INT NOT NULL,
ScheduleRangeBeginValue datetime NULL,
ScheduleRangeEndOperator INT NOT NULL,
ScheduleRangeEndValue datetime NULL,
ScheduleTypeOperator INT NOT NULL,
ScheduleTypeValue nvarchar(100) NULL,
ScheduleRangeTypeOperator INT NOT NULL,
ScheduleRangeTypeValue nvarchar(100) NULL,
ScheduleDateTypeOperator INT NOT NULL,
ScheduleDateTypeValue nvarchar(100) NULL,
ScheduleStatusOperator INT NOT NULL,
ScheduleStatusValue nvarchar(100) NULL,
TotalInvoiceCountOperator INT NOT NULL,
TotalInvoiceCountValue int NULL,
PostedInvoiceCountOperator INT NOT NULL,
PostedInvoiceCountValue int NULL,
CanBeClosedOperator INT NOT NULL,
CanBeClosedValue INT NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	BillingScheduleID int  NULL ,
	ScheduleName nvarchar(50)  NULL ,
	ScheduleDate datetime  NULL ,
	ScheduleRangeBegin datetime  NULL ,
	ScheduleRangeEnd datetime  NULL ,
	ScheduleType nvarchar(255)  NULL ,
	ScheduleRangeType nvarchar(255)  NULL ,
	ScheduleDateType nvarchar(255)  NULL ,
	ScheduleStatus nvarchar(255)  NULL ,
	TotalInvoiceCount int  NULL ,
	PostedInvoiceCount int  NULL ,
	CanBeClosed INT  NULL 
) 

DECLARE @QueryResult AS TABLE( 
	BillingScheduleID int  NULL ,
	ScheduleName nvarchar(50)  NULL ,
	ScheduleDate datetime  NULL ,
	ScheduleRangeBegin datetime  NULL ,
	ScheduleRangeEnd datetime  NULL ,
	ScheduleType nvarchar(255)  NULL ,
	ScheduleRangeType nvarchar(255)  NULL ,
	ScheduleDateType nvarchar(255)  NULL ,
	ScheduleStatus nvarchar(255)  NULL ,
	TotalInvoiceCount int  NULL ,
	PostedInvoiceCount int  NULL ,
	CanBeClosed INT  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@BillingScheduleIDOperator','INT'),-1),
	T.c.value('@BillingScheduleIDValue','int') ,
	ISNULL(T.c.value('@ScheduleNameOperator','INT'),-1),
	T.c.value('@ScheduleNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ScheduleDateOperator','INT'),-1),
	T.c.value('@ScheduleDateValue','datetime') ,
	ISNULL(T.c.value('@ScheduleRangeBeginOperator','INT'),-1),
	T.c.value('@ScheduleRangeBeginValue','datetime') ,
	ISNULL(T.c.value('@ScheduleRangeEndOperator','INT'),-1),
	T.c.value('@ScheduleRangeEndValue','datetime') ,
	ISNULL(T.c.value('@ScheduleTypeOperator','INT'),-1),
	T.c.value('@ScheduleTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ScheduleRangeTypeOperator','INT'),-1),
	T.c.value('@ScheduleRangeTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ScheduleDateTypeOperator','INT'),-1),
	T.c.value('@ScheduleDateTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ScheduleStatusOperator','INT'),-1),
	T.c.value('@ScheduleStatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@TotalInvoiceCountOperator','INT'),-1),
	T.c.value('@TotalInvoiceCountValue','int') ,
	ISNULL(T.c.value('@PostedInvoiceCountOperator','INT'),-1),
	T.c.value('@PostedInvoiceCountValue','int') ,
	ISNULL(T.c.value('@CanBeClosedOperator','INT'),-1),
	T.c.value('@CanBeClosedValue','INT') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @QueryResult
SELECT	bs.ID as BillingScheduleID,
		bs.Name as ScheduleName,
		bs.ScheduleDate,
		bs.ScheduleRangeBegin,
		bs.ScheduleRangeEnd,
		bst.[Description] as ScheduleType,
		bsrt.[Description] as ScheduleRangeType,
		bsdt.[Description] as ScheduleDateType,
		bss.[Description] as ScheduleStatus,
		tt.TotalInvoiceCount,
		pp.PostedInvoiceCount,
		case
		 when tt.TotalInvoiceCount = pp.PostedInvoiceCount then 1
		 else 0
		end as CanBeClosed
from	BillingSchedule bs with (nolock)
left outer join	BillingScheduleType bst with (nolock) on bst.ID = bs.ScheduleTypeID
left outer join	BillingScheduleStatus bss with (nolock) on bss.ID = bs.ScheduleStatusID
left outer join	BillingScheduleRangeType bsrt with (nolock) on bsrt.ID = bs.ScheduleRangeTypeID
left outer join	BillingScheduleDateType bsdt with (nolock) on bsdt.ID = bs.ScheduleDateTypeID
left outer join
	(select	BillingScheduleID,
			count(*) as TotalInvoiceCount
	 from	BillingInvoice bi with (nolock)
	 where	1=1
	 group by
			BillingScheduleID) tt on tt.BillingScheduleID = bs.ID
left outer join
	(select	BillingScheduleID,
			count(*) as PostedInvoiceCount
	 from	BillingInvoice bi with (nolock)
	 where	1=1
	 and	InvoiceStatusID = (select ID from BillingInvoiceStatus with (nolock) where Name = 'POSTED')
	 group by
			BillingScheduleID) pp on pp.BillingScheduleID = bs.ID
where	1=1
and		bss.Name = 'OPEN' -- Must be Open
and		bs.ScheduleDate < getdate() -- Must be after the schedule date

INSERT INTO #FinalResults
SELECT 
	T.BillingScheduleID,
	T.ScheduleName,
	T.ScheduleDate,
	T.ScheduleRangeBegin,
	T.ScheduleRangeEnd,
	T.ScheduleType,
	T.ScheduleRangeType,
	T.ScheduleDateType,
	T.ScheduleStatus,
	T.TotalInvoiceCount,
	T.PostedInvoiceCount,
	T.CanBeClosed
FROM @QueryResult T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.BillingScheduleIDOperator = -1 ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 0 AND T.BillingScheduleID IS NULL ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 1 AND T.BillingScheduleID IS NOT NULL ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 2 AND T.BillingScheduleID = TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 3 AND T.BillingScheduleID <> TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 7 AND T.BillingScheduleID > TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 8 AND T.BillingScheduleID >= TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 9 AND T.BillingScheduleID < TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 10 AND T.BillingScheduleID <= TMP.BillingScheduleIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleNameOperator = -1 ) 
 OR 
	 ( TMP.ScheduleNameOperator = 0 AND T.ScheduleName IS NULL ) 
 OR 
	 ( TMP.ScheduleNameOperator = 1 AND T.ScheduleName IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleNameOperator = 2 AND T.ScheduleName = TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 3 AND T.ScheduleName <> TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 4 AND T.ScheduleName LIKE TMP.ScheduleNameValue + '%') 
 OR 
	 ( TMP.ScheduleNameOperator = 5 AND T.ScheduleName LIKE '%' + TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 6 AND T.ScheduleName LIKE '%' + TMP.ScheduleNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ScheduleDateOperator = -1 ) 
 OR 
	 ( TMP.ScheduleDateOperator = 0 AND T.ScheduleDate IS NULL ) 
 OR 
	 ( TMP.ScheduleDateOperator = 1 AND T.ScheduleDate IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleDateOperator = 2 AND T.ScheduleDate = TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 3 AND T.ScheduleDate <> TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 7 AND T.ScheduleDate > TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 8 AND T.ScheduleDate >= TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 9 AND T.ScheduleDate < TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 10 AND T.ScheduleDate <= TMP.ScheduleDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleRangeBeginOperator = -1 ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 0 AND T.ScheduleRangeBegin IS NULL ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 1 AND T.ScheduleRangeBegin IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 2 AND T.ScheduleRangeBegin = TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 3 AND T.ScheduleRangeBegin <> TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 7 AND T.ScheduleRangeBegin > TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 8 AND T.ScheduleRangeBegin >= TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 9 AND T.ScheduleRangeBegin < TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 10 AND T.ScheduleRangeBegin <= TMP.ScheduleRangeBeginValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleRangeEndOperator = -1 ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 0 AND T.ScheduleRangeEnd IS NULL ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 1 AND T.ScheduleRangeEnd IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 2 AND T.ScheduleRangeEnd = TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 3 AND T.ScheduleRangeEnd <> TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 7 AND T.ScheduleRangeEnd > TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 8 AND T.ScheduleRangeEnd >= TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 9 AND T.ScheduleRangeEnd < TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 10 AND T.ScheduleRangeEnd <= TMP.ScheduleRangeEndValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleTypeOperator = -1 ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 0 AND T.ScheduleType IS NULL ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 1 AND T.ScheduleType IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 2 AND T.ScheduleType = TMP.ScheduleTypeValue ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 3 AND T.ScheduleType <> TMP.ScheduleTypeValue ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 4 AND T.ScheduleType LIKE TMP.ScheduleTypeValue + '%') 
 OR 
	 ( TMP.ScheduleTypeOperator = 5 AND T.ScheduleType LIKE '%' + TMP.ScheduleTypeValue ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 6 AND T.ScheduleType LIKE '%' + TMP.ScheduleTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ScheduleRangeTypeOperator = -1 ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 0 AND T.ScheduleRangeType IS NULL ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 1 AND T.ScheduleRangeType IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 2 AND T.ScheduleRangeType = TMP.ScheduleRangeTypeValue ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 3 AND T.ScheduleRangeType <> TMP.ScheduleRangeTypeValue ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 4 AND T.ScheduleRangeType LIKE TMP.ScheduleRangeTypeValue + '%') 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 5 AND T.ScheduleRangeType LIKE '%' + TMP.ScheduleRangeTypeValue ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 6 AND T.ScheduleRangeType LIKE '%' + TMP.ScheduleRangeTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ScheduleDateTypeOperator = -1 ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 0 AND T.ScheduleDateType IS NULL ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 1 AND T.ScheduleDateType IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 2 AND T.ScheduleDateType = TMP.ScheduleDateTypeValue ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 3 AND T.ScheduleDateType <> TMP.ScheduleDateTypeValue ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 4 AND T.ScheduleDateType LIKE TMP.ScheduleDateTypeValue + '%') 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 5 AND T.ScheduleDateType LIKE '%' + TMP.ScheduleDateTypeValue ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 6 AND T.ScheduleDateType LIKE '%' + TMP.ScheduleDateTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ScheduleStatusOperator = -1 ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 0 AND T.ScheduleStatus IS NULL ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 1 AND T.ScheduleStatus IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 2 AND T.ScheduleStatus = TMP.ScheduleStatusValue ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 3 AND T.ScheduleStatus <> TMP.ScheduleStatusValue ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 4 AND T.ScheduleStatus LIKE TMP.ScheduleStatusValue + '%') 
 OR 
	 ( TMP.ScheduleStatusOperator = 5 AND T.ScheduleStatus LIKE '%' + TMP.ScheduleStatusValue ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 6 AND T.ScheduleStatus LIKE '%' + TMP.ScheduleStatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.TotalInvoiceCountOperator = -1 ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 0 AND T.TotalInvoiceCount IS NULL ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 1 AND T.TotalInvoiceCount IS NOT NULL ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 2 AND T.TotalInvoiceCount = TMP.TotalInvoiceCountValue ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 3 AND T.TotalInvoiceCount <> TMP.TotalInvoiceCountValue ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 7 AND T.TotalInvoiceCount > TMP.TotalInvoiceCountValue ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 8 AND T.TotalInvoiceCount >= TMP.TotalInvoiceCountValue ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 9 AND T.TotalInvoiceCount < TMP.TotalInvoiceCountValue ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 10 AND T.TotalInvoiceCount <= TMP.TotalInvoiceCountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.PostedInvoiceCountOperator = -1 ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 0 AND T.PostedInvoiceCount IS NULL ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 1 AND T.PostedInvoiceCount IS NOT NULL ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 2 AND T.PostedInvoiceCount = TMP.PostedInvoiceCountValue ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 3 AND T.PostedInvoiceCount <> TMP.PostedInvoiceCountValue ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 7 AND T.PostedInvoiceCount > TMP.PostedInvoiceCountValue ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 8 AND T.PostedInvoiceCount >= TMP.PostedInvoiceCountValue ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 9 AND T.PostedInvoiceCount < TMP.PostedInvoiceCountValue ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 10 AND T.PostedInvoiceCount <= TMP.PostedInvoiceCountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CanBeClosedOperator = -1 ) 
 OR 
	 ( TMP.CanBeClosedOperator = 0 AND T.CanBeClosed IS NULL ) 
 OR 
	 ( TMP.CanBeClosedOperator = 1 AND T.CanBeClosed IS NOT NULL ) 
 OR 
	 ( TMP.CanBeClosedOperator = 2 AND T.CanBeClosed = TMP.CanBeClosedValue ) 
 OR 
	 ( TMP.CanBeClosedOperator = 3 AND T.CanBeClosed <> TMP.CanBeClosedValue ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'ASC'
	 THEN T.BillingScheduleID END ASC, 
	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'DESC'
	 THEN T.BillingScheduleID END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleName' AND @sortOrder = 'ASC'
	 THEN T.ScheduleName END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleName' AND @sortOrder = 'DESC'
	 THEN T.ScheduleName END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleDate' AND @sortOrder = 'ASC'
	 THEN T.ScheduleDate END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleDate' AND @sortOrder = 'DESC'
	 THEN T.ScheduleDate END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeBegin' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeBegin END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeBegin' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeBegin END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeEnd' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeEnd END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeEnd' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeEnd END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleType' AND @sortOrder = 'ASC'
	 THEN T.ScheduleType END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleType' AND @sortOrder = 'DESC'
	 THEN T.ScheduleType END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeType' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeType END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeType' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeType END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleDateType' AND @sortOrder = 'ASC'
	 THEN T.ScheduleDateType END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleDateType' AND @sortOrder = 'DESC'
	 THEN T.ScheduleDateType END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleStatus' AND @sortOrder = 'ASC'
	 THEN T.ScheduleStatus END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleStatus' AND @sortOrder = 'DESC'
	 THEN T.ScheduleStatus END DESC ,

	 CASE WHEN @sortColumn = 'TotalInvoiceCount' AND @sortOrder = 'ASC'
	 THEN T.TotalInvoiceCount END ASC, 
	 CASE WHEN @sortColumn = 'TotalInvoiceCount' AND @sortOrder = 'DESC'
	 THEN T.TotalInvoiceCount END DESC ,

	 CASE WHEN @sortColumn = 'PostedInvoiceCount' AND @sortOrder = 'ASC'
	 THEN T.PostedInvoiceCount END ASC, 
	 CASE WHEN @sortColumn = 'PostedInvoiceCount' AND @sortOrder = 'DESC'
	 THEN T.PostedInvoiceCount END DESC ,

	 CASE WHEN @sortColumn = 'CanBeClosed' AND @sortOrder = 'ASC'
	 THEN T.CanBeClosed END ASC, 
	 CASE WHEN @sortColumn = 'CanBeClosed' AND @sortOrder = 'DESC'
	 THEN T.CanBeClosed END DESC 


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
END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Client_ClosePeriodProcess]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Client_ClosePeriodProcess] 
END 
GO
-- EXCE dms_Client_ClosePeriodProcess @billingSchedules = '1,2',@userName = 'demoUser',@sessionID = 'XX12',@pageReference = 'Test'
CREATE PROC [dbo].[dms_Client_ClosePeriodProcess](@billingSchedules NVARCHAR(MAX),@userName NVARCHAR(100),@sessionID NVARCHAR(MAX),@pageReference NVARCHAR(MAX))
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN
			
			DECLARE @BillingScheduleID AS TABLE(RecordID INT IDENTITY(1,1), BillingScheduleID INT)
			INSERT INTO @BillingScheduleID(BillingScheduleID) SELECT item FROM dbo.fnSplitString(@billingSchedules,',')
	
			DECLARE @scheduleID AS INT
			DECLARE @ProcessingCounter AS INT = 1
			DECLARE @TotalRows AS INT
			SELECT  @TotalRows = MAX(RecordID) FROM @BillingScheduleID
	
			DECLARE @entityID AS INT 
			DECLARE @eventID AS INT
			DECLARE	@eventDescription AS NVARCHAR(MAX)
			SELECT  @entityID = ID FROM Entity WHERE Name = 'BillingSchedule'
			SELECT  @eventID =  ID FROM Event WHERE Name = 'ClosePeriod'
			SELECT  @eventDescription =  Description FROM Event WHERE Name = 'ClosePeriod'
	

			DECLARE	@BillingScheduleStatusID_CLOSED AS INT
			SELECT	@BillingScheduleStatusID_CLOSED = ID FROM BillingScheduleStatus WHERE Name = 'CLOSED'
	
			WHILE @ProcessingCounter <= @TotalRows
			BEGIN
			SET @scheduleID = (SELECT BillingScheduleID FROM @BillingScheduleID WHERE RecordID = @ProcessingCounter)
			
			-- Set BillingSchedule to Closed
			UPDATE	dbo.BillingSchedule
			SET		ScheduleStatusID = @BillingScheduleStatusID_CLOSED
					, ModifyBy = @userName
					, ModifyDate = GETDATE()
					, IsActive = 0
			WHERE	ID = @scheduleID
			
			
			-- Open New Period
			DECLARE  @Now AS DATETIME
			DECLARE  @BillingScheduleStatusID_PENDING AS INT,
					 @BillingScheduleTypeID_MONTHLY AS INT,
					 @BillingScheduleTypeID_WEEKLY AS INT,
					 @BillingScheduleRangeTypeID_PREVIOUS_MO AS INT,
					 @BillingScheduleRangeTypeID_PREVIOUS_WK AS INT,
					 @BillingScheduleDateTypeID_FIRST_DAY_OF_MO AS INT,
					 @BillingScheduleDateTypeID_MONDAY AS INT

			SELECT   @Now = GETDATE()
			SELECT   @BillingScheduleStatusID_PENDING = ID FROM BillingScheduleStatus WHERE Name = 'PENDING'
			SELECT   @BillingScheduleTypeID_MONTHLY = ID FROM BillingScheduleType WHERE Name = 'MONTHLY'
			SELECT   @BillingScheduleTypeID_WEEKLY = ID FROM BillingScheduleType WHERE Name = 'WEEKLY'
			SELECT   @BillingScheduleRangeTypeID_PREVIOUS_MO = ID FROM BillingScheduleRangeType WHERE Name = 'PREVIOUS_MO'
			SELECT   @BillingScheduleRangeTypeID_PREVIOUS_WK = ID FROM BillingScheduleRangeType WHERE Name = 'PREVIOUS_WK'
			SELECT   @BillingScheduleDateTypeID_FIRST_DAY_OF_MO = ID FROM BillingScheduleDateType WHERE Name = 'FIRST_DAY_OF_MO'
			SELECT   @BillingScheduleDateTypeID_MONDAY = ID FROM BillingScheduleDateType WHERE Name = 'MONDAY'

			DECLARE  @Name as nvarchar(50),
					 @Description as nvarchar(50),
					 @ScheduleDateTypeID as int,
					 @ScheduleRangeTypeID as int,
					 @ScheduleDate_CURR as datetime,
					 @ScheduleRangeBegin_CURR as datetime,
					 @ScheduleRangeEnd_CURR as datetime,
					 @ScheduleTypeID as int,
					 @ScheduleStatusID as int,
					 @ScheduleDate_NEW as datetime,
					 @ScheduleRangeBegin_NEW as datetime,
					 @ScheduleRangeEnd_NEW as datetime

			SET     @ScheduleStatusID = @BillingScheduleStatusID_PENDING -- PENDING
 
			-- Inherit columns from record getting closed 
			SELECT   @Name = Name,
					 @Description  = [Description],
					 @ScheduleDateTypeID = ScheduleDateTypeID,
					 @ScheduleRangeTypeID = ScheduleRangeTypeID,
					 @ScheduleDate_CURR = ScheduleDate,
					 @ScheduleRangeBegin_CURR = ScheduleRangeBegin,
					 @ScheduleRangeEnd_CURR = ScheduleRangeEnd,
					 @ScheduleTypeID = ScheduleTypeID
			FROM     dbo.BillingSchedule
			WHERE    ID = @scheduleID

			-- Monthly / Previous Month / First Day Of Month 
			-------------------------------------------------
			IF       @ScheduleDateTypeID = @BillingScheduleTypeID_MONTHLY
			AND      @ScheduleRangeTypeID = @BillingScheduleRangeTypeID_PREVIOUS_MO
			AND      @ScheduleDateTypeID = @BillingScheduleDateTypeID_FIRST_DAY_OF_MO
			BEGIN
 
			   SELECT      @ScheduleDate_NEW = DATEADD(mm, 1, @ScheduleDate_CURR) -- Advance 1 month
			   SELECT      @ScheduleRangeBegin_NEW = @ScheduleDate_CURR -- Set to the Curr Sched date
			   SELECT      @ScheduleRangeEnd_NEW = DATEADD(dd, -1, @ScheduleDate_NEW) -- 1 day Less than New Scheduled date
 
			END
 
			-- Weekly / Previous Week / Monday
			-------------------------------------------------
			IF		 @ScheduleDateTypeID = @BillingScheduleTypeID_WEEKLY
			AND      @ScheduleRangeTypeID = @BillingScheduleRangeTypeID_PREVIOUS_WK
			AND      @ScheduleDateTypeID = @BillingScheduleDateTypeID_MONDAY
			BEGIN
 
			   SELECT      @ScheduleDate_NEW = dateadd(dd, 7, @ScheduleDate_CURR) -- Advance 7 days
			   SELECT      @ScheduleRangeBegin_NEW = @ScheduleDate_CURR -- Set to the Curr Sched date
			   SELECT      @ScheduleRangeEnd_NEW = dateadd(dd, -1, @ScheduleDate_NEW) -- 1 day Less than New Scheduled date
 
			END
 
			INSERT INTO dbo.BillingSchedule(Name,			  [Description],			ScheduleDateTypeID,				ScheduleRangeTypeID,
											ScheduleDate,     ScheduleRangeBegin,		ScheduleRangeEnd,				ScheduleTypeID,
											ScheduleStatusID, Sequence,					IsActive,						CreateDate,
											CreateBy,		  ModifyDate,				ModifyBy)
 
			SELECT							@Name, -- Name
											@Description, -- [Description]
										    @ScheduleDateTypeID, -- ScheduleDateTypeID
											@ScheduleRangeTypeID,-- ScheduleRangeTypeID
											@ScheduleDate_NEW, -- ScheduleDate
											@ScheduleRangeBegin_NEW, -- ScheduleRangeBegin
											@ScheduleRangeEnd_NEW, -- ScheduleRangeEnd
											@ScheduleTypeID, -- ScheduleTypeID
											@ScheduleStatusID, -- ScheduleStatusID
											0, -- Sequence
											1, -- IsActive
											@Now, -- CreateDate
											@userName, -- CreateBy
											null, -- ModifyDate
											null -- ModifyBy	

			-- Create Event Logs Reocords
			INSERT INTO EventLog([EventID],				[SessionID],				[Source],			[Description],
								 [Data],				[NotificationQueueDate],	[CreateBy],			[CreateDate]) 
			VALUES				(@eventID,				@sessionID,					@pageReference,		@eventDescription,
								 NULL,					NULL,						@userName,			GETDATE())
			-- CREATE Link Records
			INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) VALUES(SCOPE_IDENTITY(),@entityID,@scheduleID)
			
			SET @ProcessingCounter = @ProcessingCounter + 1
	END
		
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		DECLARE @ErrorMessage    NVARCHAR(4000)			
		-- Assign variables to error-handling functions that 
		-- capture information for RAISERROR.
		SELECT  @ErrorMessage = ERROR_MESSAGE();
		RAISERROR(@ErrorMessage,16,1);
	END CATCH
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
 WHERE id = object_id(N'[dbo].[dms_Client_OpenPeriod]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Client_OpenPeriod] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Client_OpenPeriod]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
	SET FMTONLY OFF

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
BillingScheduleIDOperator="-1" 
ScheduleNameOperator="-1" 
ScheduleDateOperator="-1" 
ScheduleRangeBeginOperator="-1" 
ScheduleRangeEndOperator="-1" 
StatusOperator="-1" 
InvoicesToBeCreatedCountOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
BillingScheduleIDOperator INT NOT NULL,
BillingScheduleIDValue int NULL,
ScheduleNameOperator INT NOT NULL,
ScheduleNameValue nvarchar(100) NULL,
ScheduleDateOperator INT NOT NULL,
ScheduleDateValue datetime NULL,
ScheduleRangeBeginOperator INT NOT NULL,
ScheduleRangeBeginValue datetime NULL,
ScheduleRangeEndOperator INT NOT NULL,
ScheduleRangeEndValue datetime NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL,
InvoicesToBeCreatedCountOperator INT NOT NULL,
InvoicesToBeCreatedCountValue int NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	BillingScheduleID int  NULL ,
	ScheduleName nvarchar(50)  NULL ,
	ScheduleDate datetime  NULL ,
	ScheduleRangeBegin datetime  NULL ,
	ScheduleRangeEnd datetime  NULL ,
	Status nvarchar(50)  NULL ,
	InvoicesToBeCreatedCount int  NULL 
) 

DECLARE @QueryResult AS TABLE( 
	BillingScheduleID int  NULL ,
	ScheduleName nvarchar(50)  NULL ,
	ScheduleDate datetime  NULL ,
	ScheduleRangeBegin datetime  NULL ,
	ScheduleRangeEnd datetime  NULL ,
	Status nvarchar(50)  NULL ,
	InvoicesToBeCreatedCount int  NULL 
) 

INSERT INTO @QueryResult
SELECT	bs.ID as BillingScheduleID,
		bs.Name as ScheduleName,
		bs.ScheduleDate,
		bs.ScheduleRangeBegin,
		bs.ScheduleRangeEnd,
		bss.Name as [Status],
		tt.InvoicesToBeCreatedCount
FROM	BillingSchedule bs with (nolock)
left outer join	BillingScheduleType bst with (nolock) on bst.ID = bs.ScheduleTypeID
left outer join	BillingScheduleStatus bss with (nolock) on bss.ID = bs.ScheduleStatusID
left outer join	BillingScheduleRangeType bsrt with (nolock) on bsrt.ID = bs.ScheduleRangeTypeID
left outer join	BillingScheduleDateType bsdt with (nolock) on bsdt.ID = bs.ScheduleDateTypeID
left outer join
	(SELECT bs.ID AS BillingScheduleID, 
			count(*) InvoicesToBeCreatedCount
	from	BillingSchedule bs
	join	BillingDefinitionInvoice bdi on bdi.ScheduleTypeID = bs.ScheduleTypeID
	and		bdi.ScheduleDateTypeID = bs.ScheduleDateTypeID
	and		bdi.ScheduleRangeTypeID = bs.ScheduleRangeTypeID
	and		bdi.IsActive = 1
	group by
			bs.ID
	)tt on tt.BillingScheduleID = bs.ID
WHERE bss.Name = 'PENDING' 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@BillingScheduleIDOperator','INT'),-1),
	T.c.value('@BillingScheduleIDValue','int') ,
	ISNULL(T.c.value('@ScheduleNameOperator','INT'),-1),
	T.c.value('@ScheduleNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ScheduleDateOperator','INT'),-1),
	T.c.value('@ScheduleDateValue','datetime') ,
	ISNULL(T.c.value('@ScheduleRangeBeginOperator','INT'),-1),
	T.c.value('@ScheduleRangeBeginValue','datetime') ,
	ISNULL(T.c.value('@ScheduleRangeEndOperator','INT'),-1),
	T.c.value('@ScheduleRangeEndValue','datetime') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@InvoicesToBeCreatedCountOperator','INT'),-1),
	T.c.value('@InvoicesToBeCreatedCountValue','int') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.BillingScheduleID,
	T.ScheduleName,
	T.ScheduleDate,
	T.ScheduleRangeBegin,
	T.ScheduleRangeEnd,
	T.Status,
	T.InvoicesToBeCreatedCount
FROM @QueryResult T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.BillingScheduleIDOperator = -1 ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 0 AND T.BillingScheduleID IS NULL ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 1 AND T.BillingScheduleID IS NOT NULL ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 2 AND T.BillingScheduleID = TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 3 AND T.BillingScheduleID <> TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 7 AND T.BillingScheduleID > TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 8 AND T.BillingScheduleID >= TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 9 AND T.BillingScheduleID < TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 10 AND T.BillingScheduleID <= TMP.BillingScheduleIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleNameOperator = -1 ) 
 OR 
	 ( TMP.ScheduleNameOperator = 0 AND T.ScheduleName IS NULL ) 
 OR 
	 ( TMP.ScheduleNameOperator = 1 AND T.ScheduleName IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleNameOperator = 2 AND T.ScheduleName = TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 3 AND T.ScheduleName <> TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 4 AND T.ScheduleName LIKE TMP.ScheduleNameValue + '%') 
 OR 
	 ( TMP.ScheduleNameOperator = 5 AND T.ScheduleName LIKE '%' + TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 6 AND T.ScheduleName LIKE '%' + TMP.ScheduleNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ScheduleDateOperator = -1 ) 
 OR 
	 ( TMP.ScheduleDateOperator = 0 AND T.ScheduleDate IS NULL ) 
 OR 
	 ( TMP.ScheduleDateOperator = 1 AND T.ScheduleDate IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleDateOperator = 2 AND T.ScheduleDate = TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 3 AND T.ScheduleDate <> TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 7 AND T.ScheduleDate > TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 8 AND T.ScheduleDate >= TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 9 AND T.ScheduleDate < TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 10 AND T.ScheduleDate <= TMP.ScheduleDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleRangeBeginOperator = -1 ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 0 AND T.ScheduleRangeBegin IS NULL ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 1 AND T.ScheduleRangeBegin IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 2 AND T.ScheduleRangeBegin = TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 3 AND T.ScheduleRangeBegin <> TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 7 AND T.ScheduleRangeBegin > TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 8 AND T.ScheduleRangeBegin >= TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 9 AND T.ScheduleRangeBegin < TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 10 AND T.ScheduleRangeBegin <= TMP.ScheduleRangeBeginValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleRangeEndOperator = -1 ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 0 AND T.ScheduleRangeEnd IS NULL ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 1 AND T.ScheduleRangeEnd IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 2 AND T.ScheduleRangeEnd = TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 3 AND T.ScheduleRangeEnd <> TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 7 AND T.ScheduleRangeEnd > TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 8 AND T.ScheduleRangeEnd >= TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 9 AND T.ScheduleRangeEnd < TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 10 AND T.ScheduleRangeEnd <= TMP.ScheduleRangeEndValue ) 

 ) 

 AND 

 ( 
	 ( TMP.StatusOperator = -1 ) 
 OR 
	 ( TMP.StatusOperator = 0 AND T.Status IS NULL ) 
 OR 
	 ( TMP.StatusOperator = 1 AND T.Status IS NOT NULL ) 
 OR 
	 ( TMP.StatusOperator = 2 AND T.Status = TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 3 AND T.Status <> TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 4 AND T.Status LIKE TMP.StatusValue + '%') 
 OR 
	 ( TMP.StatusOperator = 5 AND T.Status LIKE '%' + TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 6 AND T.Status LIKE '%' + TMP.StatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.InvoicesToBeCreatedCountOperator = -1 ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 0 AND T.InvoicesToBeCreatedCount IS NULL ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 1 AND T.InvoicesToBeCreatedCount IS NOT NULL ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 2 AND T.InvoicesToBeCreatedCount = TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 3 AND T.InvoicesToBeCreatedCount <> TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 7 AND T.InvoicesToBeCreatedCount > TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 8 AND T.InvoicesToBeCreatedCount >= TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 9 AND T.InvoicesToBeCreatedCount < TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 10 AND T.InvoicesToBeCreatedCount <= TMP.InvoicesToBeCreatedCountValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'ASC'
	 THEN T.BillingScheduleID END ASC, 
	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'DESC'
	 THEN T.BillingScheduleID END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleName' AND @sortOrder = 'ASC'
	 THEN T.ScheduleName END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleName' AND @sortOrder = 'DESC'
	 THEN T.ScheduleName END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleDate' AND @sortOrder = 'ASC'
	 THEN T.ScheduleDate END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleDate' AND @sortOrder = 'DESC'
	 THEN T.ScheduleDate END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeBegin' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeBegin END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeBegin' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeBegin END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeEnd' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeEnd END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeEnd' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeEnd END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC ,

	 CASE WHEN @sortColumn = 'InvoicesToBeCreatedCount' AND @sortOrder = 'ASC'
	 THEN T.InvoicesToBeCreatedCount END ASC, 
	 CASE WHEN @sortColumn = 'InvoicesToBeCreatedCount' AND @sortOrder = 'DESC'
	 THEN T.InvoicesToBeCreatedCount END DESC 


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
END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Client_OpenPeriodProcess]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Client_OpenPeriodProcess] 
END 
GO
-- EXCE dms_Client_OpenPeriodProcess @billingSchedules = '1,2',@userName = 'demoUser',@sessionID = 'XX12',@pageReference = 'Test'
CREATE PROC [dbo].[dms_Client_OpenPeriodProcess](@billingSchedules NVARCHAR(MAX),@userName NVARCHAR(100),@sessionID NVARCHAR(MAX),@pageReference NVARCHAR(MAX))
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN
			DECLARE @BillingScheduleID AS TABLE(RecordID INT IDENTITY(1,1), BillingScheduleID INT)
			INSERT INTO @BillingScheduleID(BillingScheduleID) SELECT item FROM dbo.fnSplitString(@billingSchedules,',')
			DECLARE @scheduleID AS INT
			DECLARE @ProcessingCounter AS INT = 1
			DECLARE @TotalRows AS INT
			SELECT  @TotalRows = MAX(RecordID) FROM @BillingScheduleID
	
			DECLARE @entityID AS INT 
			DECLARE @eventID AS INT
			DECLARE	@eventDescription AS NVARCHAR(MAX)
			SELECT  @entityID = ID FROM Entity WHERE Name = 'BillingInvoice'
			SELECT  @eventID =  ID FROM Event WHERE Name = 'OpenPeriod'
			SELECT  @eventDescription =  Description FROM Event WHERE Name = 'ClosePeriod'

			WHILE @ProcessingCounter <= @TotalRows
			BEGIN
					SET @scheduleID = (SELECT BillingScheduleID FROM @BillingScheduleID WHERE RecordID = @ProcessingCounter)
			
					-- Write Process Logic for Schedule ID
									DECLARE @pScheduleTypeID AS INT,
					@pScheduledDateTypeID AS INT,
					@pScheduleRangeTypeID AS INT;

					DECLARE @pInvoiceXML AS NVARCHAR(MAX)
			
													SELECT  @pScheduleTypeID = ScheduleTypeID,
					@pScheduledDateTypeID = ScheduleDateTypeID,
					@pScheduleRangeTypeID = ScheduleRangeTypeID
			FROM    BillingSchedule
			WHERE   ID = @scheduleID

					--SELECT * FROM BillingSchedule
															SELECT	    @pInvoiceXML = [dbo].[fnConcatenate](ID)
			FROM        BillingDefinitionInvoice
			WHERE       IsActive = 1
			AND         ScheduleTypeID = @pScheduleTypeID
			AND         ScheduleDateTypeID = @pScheduledDateTypeID
			AND         ScheduleRangeTypeID = @pScheduleRangeTypeID
			
					SET @pInvoiceXML = '<Records><BillingDefinitionInvoiceID>' + REPLACE(@pInvoiceXML,',','</BillingDefinitionInvoiceID><BillingDefinitionInvoiceID>') + '</BillingDefinitionInvoiceID></Records>'

															EXEC dbo.dms_BillingGenerateInvoices 
			@pUserName  = @userName,
			@pScheduleTypeID = @pScheduleTypeID,
			@pScheduleDateTypeID = @pScheduledDateTypeID,
			@pScheduleRangeTypeID = @pScheduleRangeTypeID,
			@pInvoicesXML = @pInvoiceXML

					-- Create Event Logs Reocords
											INSERT INTO EventLog([EventID],				[SessionID],				[Source],			[Description],
								 [Data],				[NotificationQueueDate],	[CreateBy],			[CreateDate]) 
			VALUES				(@eventID,				@sessionID,					@pageReference,	   @eventDescription,
								 NULL,					NULL,						@userName,			GETDATE())
			
					-- CREATE Link Records
					INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) VALUES(SCOPE_IDENTITY(),@entityID,@scheduleID)
			
					SET @ProcessingCounter = @ProcessingCounter + 1
			END
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		DECLARE @ErrorMessage    NVARCHAR(4000)			
		-- Assign variables to error-handling functions that 
		-- capture information for RAISERROR.
		SELECT  @ErrorMessage = ERROR_MESSAGE();
		RAISERROR(@ErrorMessage,16,1);
	END CATCH
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
 WHERE id = object_id(N'[dbo].[dms_Vendor_Summary_LocationRates]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Summary_LocationRates] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Vendor_Summary_LocationRates]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @VendorID INT = NULL
  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
LocationAddressOperator="-1" 
StatusOperator="-1" 
DispatchNumberOperator="-1" 
FaxNumberOperator="-1" 
CellNumberOperator="-1" 
IsDispatchNoteOperator="-1" 
DispatchNoteOperator="-1" 
LatitudeOperator="-1" 
LongitudeOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
LocationAddressOperator INT NOT NULL,
LocationAddressValue nvarchar(100) NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL,
DispatchNumberOperator INT NOT NULL,
DispatchNumberValue nvarchar(100) NULL,
FaxNumberOperator INT NOT NULL,
FaxNumberValue nvarchar(100) NULL,
CellNumberOperator INT NOT NULL,
CellNumberValue nvarchar(100) NULL,
IsDispatchNoteOperator INT NOT NULL,
IsDispatchNoteValue nvarchar(100) NULL,
DispatchNoteOperator INT NOT NULL,
DispatchNoteValue nvarchar(100) NULL,
LatitudeOperator INT NOT NULL,
LatitudeValue decimal NULL,
LongitudeOperator INT NOT NULL,
LongitudeValue decimal NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	VendorID int  NULL ,
	VendorLocationID int  NULL ,
	LocationAddress nvarchar(MAX)  NULL ,
	Status nvarchar(MAX)  NULL ,
	DispatchNumber nvarchar(100)  NULL ,
	FaxNumber nvarchar(100)  NULL ,
	CellNumber nvarchar(100)  NULL ,
	IsDispatchNote nvarchar(MAX)  NULL ,
	DispatchNote nvarchar(MAX)  NULL ,
	Latitude decimal(10,7)  NULL ,
	Longitude decimal(10,7)  NULL 
) 

DECLARE @Query AS TABLE( 
	VendorID int  NULL ,
	VendorLocationID int  NULL ,
	LocationAddress nvarchar(MAX)  NULL ,
	Status nvarchar(MAX)  NULL ,
	DispatchNumber nvarchar(100)  NULL ,
	FaxNumber nvarchar(100)  NULL ,
	CellNumber nvarchar(100)  NULL ,
	IsDispatchNote nvarchar(MAX)  NULL ,
	DispatchNote nvarchar(MAX)  NULL ,
	Latitude decimal(10,7)  NULL ,
	Longitude decimal(10,7)  NULL 
) 
INSERT INTO @Query
SELECT	VL.VendorID,
		VL.ID VendorLocationID,
		ISNULL(REPLACE(RTRIM(
		COALESCE(AE.Line1, '') + 
		COALESCE(' ' + AE.Line2, '') + 
		COALESCE(' ' + AE.Line3, '') + 
		COALESCE(', ' + AE.City, '') +
		COALESCE(RTRIM(', ' + AE.StateProvince), '') + 
		COALESCE(' ' + AE.PostalCode, '') +	
		COALESCE(' ' + AE.CountryCode, '') 
		), '  ', ' ')
		,'') AS LocationAddress
		, VLS.Description AS Status
		, PE.PhoneNumber AS DispatchNumber
		, PEF.PhoneNumber AS FaxNumber
		, PEC.PhoneNumber AS CellNumber
		, CASE
			WHEN ISNULL(VL.DispatchNote,'')='' THEN 'No'
			ELSE 'Yes'
		  END AS IsDispatchNote
		, VL.DispatchNote
		, VL.Latitude AS Latitude
		, VL.Longitude AS Longitude
FROM	VendorLocation VL
JOIN	VendorLocationStatus VLS ON VLS.ID = VL.VendorLocationStatusID
LEFT JOIN AddressEntity AE ON AE.RecordID = VL.ID AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') 
LEFT JOIN PhoneEntity PE ON PE.RecordID = VL.ID AND PE.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') 
		AND PE.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Dispatch') 
LEFT JOIN PhoneEntity PEF ON PEF.RecordID = VL.ID AND PEF.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') 
		AND PEF.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Fax') 
LEFT JOIN PhoneEntity PEC ON PEC.RecordID = VL.ID AND PEC.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') 
		AND PEC.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Cell') 
WHERE	VL.VendorID = @VendorID

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@LocationAddressOperator','INT'),-1),
	T.c.value('@LocationAddressValue','nvarchar(100)') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DispatchNumberOperator','INT'),-1),
	T.c.value('@DispatchNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@FaxNumberOperator','INT'),-1),
	T.c.value('@FaxNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CellNumberOperator','INT'),-1),
	T.c.value('@CellNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@IsDispatchNoteOperator','INT'),-1),
	T.c.value('@IsDispatchNoteValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DispatchNoteOperator','INT'),-1),
	T.c.value('@DispatchNoteValue','nvarchar(100)') ,
	ISNULL(T.c.value('@LatitudeOperator','INT'),-1),
	T.c.value('@LatitudeValue','decimal') ,
	ISNULL(T.c.value('@LongitudeOperator','INT'),-1),
	T.c.value('@LongitudeValue','decimal') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.VendorID,
	T.VendorLocationID,
	T.LocationAddress,
	T.Status,
	T.DispatchNumber,
	T.FaxNumber,
	T.CellNumber,
	T.IsDispatchNote,
	T.DispatchNote,
	T.Latitude,
	T.Longitude
FROM @Query T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.LocationAddressOperator = -1 ) 
 OR 
	 ( TMP.LocationAddressOperator = 0 AND T.LocationAddress IS NULL ) 
 OR 
	 ( TMP.LocationAddressOperator = 1 AND T.LocationAddress IS NOT NULL ) 
 OR 
	 ( TMP.LocationAddressOperator = 2 AND T.LocationAddress = TMP.LocationAddressValue ) 
 OR 
	 ( TMP.LocationAddressOperator = 3 AND T.LocationAddress <> TMP.LocationAddressValue ) 
 OR 
	 ( TMP.LocationAddressOperator = 4 AND T.LocationAddress LIKE TMP.LocationAddressValue + '%') 
 OR 
	 ( TMP.LocationAddressOperator = 5 AND T.LocationAddress LIKE '%' + TMP.LocationAddressValue ) 
 OR 
	 ( TMP.LocationAddressOperator = 6 AND T.LocationAddress LIKE '%' + TMP.LocationAddressValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.StatusOperator = -1 ) 
 OR 
	 ( TMP.StatusOperator = 0 AND T.Status IS NULL ) 
 OR 
	 ( TMP.StatusOperator = 1 AND T.Status IS NOT NULL ) 
 OR 
	 ( TMP.StatusOperator = 2 AND T.Status = TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 3 AND T.Status <> TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 4 AND T.Status LIKE TMP.StatusValue + '%') 
 OR 
	 ( TMP.StatusOperator = 5 AND T.Status LIKE '%' + TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 6 AND T.Status LIKE '%' + TMP.StatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DispatchNumberOperator = -1 ) 
 OR 
	 ( TMP.DispatchNumberOperator = 0 AND T.DispatchNumber IS NULL ) 
 OR 
	 ( TMP.DispatchNumberOperator = 1 AND T.DispatchNumber IS NOT NULL ) 
 OR 
	 ( TMP.DispatchNumberOperator = 2 AND T.DispatchNumber = TMP.DispatchNumberValue ) 
 OR 
	 ( TMP.DispatchNumberOperator = 3 AND T.DispatchNumber <> TMP.DispatchNumberValue ) 
 OR 
	 ( TMP.DispatchNumberOperator = 4 AND T.DispatchNumber LIKE TMP.DispatchNumberValue + '%') 
 OR 
	 ( TMP.DispatchNumberOperator = 5 AND T.DispatchNumber LIKE '%' + TMP.DispatchNumberValue ) 
 OR 
	 ( TMP.DispatchNumberOperator = 6 AND T.DispatchNumber LIKE '%' + TMP.DispatchNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.FaxNumberOperator = -1 ) 
 OR 
	 ( TMP.FaxNumberOperator = 0 AND T.FaxNumber IS NULL ) 
 OR 
	 ( TMP.FaxNumberOperator = 1 AND T.FaxNumber IS NOT NULL ) 
 OR 
	 ( TMP.FaxNumberOperator = 2 AND T.FaxNumber = TMP.FaxNumberValue ) 
 OR 
	 ( TMP.FaxNumberOperator = 3 AND T.FaxNumber <> TMP.FaxNumberValue ) 
 OR 
	 ( TMP.FaxNumberOperator = 4 AND T.FaxNumber LIKE TMP.FaxNumberValue + '%') 
 OR 
	 ( TMP.FaxNumberOperator = 5 AND T.FaxNumber LIKE '%' + TMP.FaxNumberValue ) 
 OR 
	 ( TMP.FaxNumberOperator = 6 AND T.FaxNumber LIKE '%' + TMP.FaxNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CellNumberOperator = -1 ) 
 OR 
	 ( TMP.CellNumberOperator = 0 AND T.CellNumber IS NULL ) 
 OR 
	 ( TMP.CellNumberOperator = 1 AND T.CellNumber IS NOT NULL ) 
 OR 
	 ( TMP.CellNumberOperator = 2 AND T.CellNumber = TMP.CellNumberValue ) 
 OR 
	 ( TMP.CellNumberOperator = 3 AND T.CellNumber <> TMP.CellNumberValue ) 
 OR 
	 ( TMP.CellNumberOperator = 4 AND T.CellNumber LIKE TMP.CellNumberValue + '%') 
 OR 
	 ( TMP.CellNumberOperator = 5 AND T.CellNumber LIKE '%' + TMP.CellNumberValue ) 
 OR 
	 ( TMP.CellNumberOperator = 6 AND T.CellNumber LIKE '%' + TMP.CellNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.IsDispatchNoteOperator = -1 ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 0 AND T.IsDispatchNote IS NULL ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 1 AND T.IsDispatchNote IS NOT NULL ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 2 AND T.IsDispatchNote = TMP.IsDispatchNoteValue ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 3 AND T.IsDispatchNote <> TMP.IsDispatchNoteValue ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 4 AND T.IsDispatchNote LIKE TMP.IsDispatchNoteValue + '%') 
 OR 
	 ( TMP.IsDispatchNoteOperator = 5 AND T.IsDispatchNote LIKE '%' + TMP.IsDispatchNoteValue ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 6 AND T.IsDispatchNote LIKE '%' + TMP.IsDispatchNoteValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DispatchNoteOperator = -1 ) 
 OR 
	 ( TMP.DispatchNoteOperator = 0 AND T.DispatchNote IS NULL ) 
 OR 
	 ( TMP.DispatchNoteOperator = 1 AND T.DispatchNote IS NOT NULL ) 
 OR 
	 ( TMP.DispatchNoteOperator = 2 AND T.DispatchNote = TMP.DispatchNoteValue ) 
 OR 
	 ( TMP.DispatchNoteOperator = 3 AND T.DispatchNote <> TMP.DispatchNoteValue ) 
 OR 
	 ( TMP.DispatchNoteOperator = 4 AND T.DispatchNote LIKE TMP.DispatchNoteValue + '%') 
 OR 
	 ( TMP.DispatchNoteOperator = 5 AND T.DispatchNote LIKE '%' + TMP.DispatchNoteValue ) 
 OR 
	 ( TMP.DispatchNoteOperator = 6 AND T.DispatchNote LIKE '%' + TMP.DispatchNoteValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LatitudeOperator = -1 ) 
 OR 
	 ( TMP.LatitudeOperator = 0 AND T.Latitude IS NULL ) 
 OR 
	 ( TMP.LatitudeOperator = 1 AND T.Latitude IS NOT NULL ) 
 OR 
	 ( TMP.LatitudeOperator = 2 AND T.Latitude = TMP.LatitudeValue ) 
 OR 
	 ( TMP.LatitudeOperator = 3 AND T.Latitude <> TMP.LatitudeValue ) 
 OR 
	 ( TMP.LatitudeOperator = 7 AND T.Latitude > TMP.LatitudeValue ) 
 OR 
	 ( TMP.LatitudeOperator = 8 AND T.Latitude >= TMP.LatitudeValue ) 
 OR 
	 ( TMP.LatitudeOperator = 9 AND T.Latitude < TMP.LatitudeValue ) 
 OR 
	 ( TMP.LatitudeOperator = 10 AND T.Latitude <= TMP.LatitudeValue ) 

 ) 

 AND 

 ( 
	 ( TMP.LongitudeOperator = -1 ) 
 OR 
	 ( TMP.LongitudeOperator = 0 AND T.Longitude IS NULL ) 
 OR 
	 ( TMP.LongitudeOperator = 1 AND T.Longitude IS NOT NULL ) 
 OR 
	 ( TMP.LongitudeOperator = 2 AND T.Longitude = TMP.LongitudeValue ) 
 OR 
	 ( TMP.LongitudeOperator = 3 AND T.Longitude <> TMP.LongitudeValue ) 
 OR 
	 ( TMP.LongitudeOperator = 7 AND T.Longitude > TMP.LongitudeValue ) 
 OR 
	 ( TMP.LongitudeOperator = 8 AND T.Longitude >= TMP.LongitudeValue ) 
 OR 
	 ( TMP.LongitudeOperator = 9 AND T.Longitude < TMP.LongitudeValue ) 
 OR 
	 ( TMP.LongitudeOperator = 10 AND T.Longitude <= TMP.LongitudeValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'LocationAddress' AND @sortOrder = 'ASC'
	 THEN T.LocationAddress END ASC, 
	 CASE WHEN @sortColumn = 'LocationAddress' AND @sortOrder = 'DESC'
	 THEN T.LocationAddress END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC ,

	 CASE WHEN @sortColumn = 'DispatchNumber' AND @sortOrder = 'ASC'
	 THEN T.DispatchNumber END ASC, 
	 CASE WHEN @sortColumn = 'DispatchNumber' AND @sortOrder = 'DESC'
	 THEN T.DispatchNumber END DESC ,

	 CASE WHEN @sortColumn = 'FaxNumber' AND @sortOrder = 'ASC'
	 THEN T.FaxNumber END ASC, 
	 CASE WHEN @sortColumn = 'FaxNumber' AND @sortOrder = 'DESC'
	 THEN T.FaxNumber END DESC ,

	 CASE WHEN @sortColumn = 'CellNumber' AND @sortOrder = 'ASC'
	 THEN T.CellNumber END ASC, 
	 CASE WHEN @sortColumn = 'CellNumber' AND @sortOrder = 'DESC'
	 THEN T.CellNumber END DESC ,

	 CASE WHEN @sortColumn = 'IsDispatchNote' AND @sortOrder = 'ASC'
	 THEN T.IsDispatchNote END ASC, 
	 CASE WHEN @sortColumn = 'IsDispatchNote' AND @sortOrder = 'DESC'
	 THEN T.IsDispatchNote END DESC ,

	 CASE WHEN @sortColumn = 'DispatchNote' AND @sortOrder = 'ASC'
	 THEN T.DispatchNote END ASC, 
	 CASE WHEN @sortColumn = 'DispatchNote' AND @sortOrder = 'DESC'
	 THEN T.DispatchNote END DESC ,

	 CASE WHEN @sortColumn = 'LatitudeText' AND @sortOrder = 'ASC'
	 THEN T.Latitude END ASC, 
	 CASE WHEN @sortColumn = 'LatitudeText' AND @sortOrder = 'DESC'
	 THEN T.Latitude END DESC ,

	 CASE WHEN @sortColumn = 'LongitudeText' AND @sortOrder = 'ASC'
	 THEN T.Longitude END ASC, 
	 CASE WHEN @sortColumn = 'LongitudeText' AND @sortOrder = 'DESC'
	 THEN T.Longitude END DESC 


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

SELECT @count AS TotalRows,
	   FR.[RowNum],
	   FR.VendorID,
	   FR.VendorLocationID,
	   FR.LocationAddress,
	   FR.[Status],
	   FR.DispatchNumber,
	   FR.FaxNumber,
	   FR.CellNumber,
	   FR.IsDispatchNote,
 	   FR.DispatchNote,
	   FR.Latitude,
	   FR.Longitude,
	   CONVERT(NVARCHAR(MAX),FR.Latitude) LatitudeText,
	   CONVERT(NVARCHAR(MAX),FR.Longitude) LongitudeText
FROM #FinalResults FR 
WHERE FR.RowNum BETWEEN @startInd AND @endInd

DROP TABLE #tmpForWhereClause
DROP TABLE #FinalResults
END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_tempcc_match_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_tempcc_match_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vendor_tempcc_match_update] @tempccIdXML = '<Tempcc><ID>1</ID><ID>2</ID><ID>3</ID><ID>4</ID></Tempcc>',@currentUser = 'demouser'
 CREATE PROCEDURE [dbo].[dms_vendor_tempcc_match_update](
	@tempccIdXML XML,
	@currentUser NVARCHAR(50)
 )
 AS
 BEGIN
 
    SET FMTONLY OFF
	SET NOCOUNT ON

	DECLARE @now DATETIME = GETDATE()
	DECLARE @MinCreateDate datetime

	DECLARE @Matched INT =0
		,@MatchedAmount money =0
		,@Unmatched int = 0
		,@UnmatchedAmount money = 0
		,@Posted INT=0
		,@PostedAmount money=0
		,@Cancelled INT=0
		,@CancelledAmount money=0
		,@Exception INT=0
		,@ExceptionAmount money=0
		,@MatchedIds nvarchar(max)=''

	DECLARE @MatchedTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Matched')
		,@UnMatchedTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'UnMatched')
		,@PostededTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Posted')
		,@CancelledTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Cancelled')
		,@ExceptionTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Exception')

	-- Build table of selected items
	CREATE TABLE #SelectedTemporaryCC 
	(	
		ID INT IDENTITY(1,1),
		TemporaryCreditCardID INT
	)

	INSERT INTO #SelectedTemporaryCC
	SELECT tcc.ID
	FROM TemporaryCreditCard tcc WITH (NOLOCK)
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @tempccIdXML.nodes('/Tempcc/ID') T(c)
			) T ON tcc.ID = T.ID

	CREATE CLUSTERED INDEX IDX_SelectedTemporaryCC ON #SelectedTemporaryCC(TemporaryCreditCardID)

		
	/**************************************************************************************************/
	-- Update (Reset) Selected items to Unmatched where status is not Posted
	UPDATE tc SET 
		TemporaryCreditCardStatusID = @UnmatchedTemporaryCreditCardStatusID
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = NULL
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	WHERE tcs.Name <> 'Posted'


	/**************************************************************************************************/
	--Update for Exact match on PO# and CC#
	--Conditions:
	--	PO# AND CC# match exactly
	--	PO Status is Issued or Issued Paid
	--	PO has not been deleted
	--	PO does not already have a related Vendor Invoice
	--	Temporary CC has not already been posted
	--Match Status
	--	Total CC charge amount LESS THAN or EQUAL to the PO amount
	--Exception Status
	--	Total CC charge amount GREATER THAN the PO amount
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount 
					THEN @MatchedTemporaryCreditCardStatusID
				 ELSE @ExceptionTemporaryCreditCardStatusID
				 END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				 --Match
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount 
					THEN NULL
				 --Exception: Charge more than PO Amount
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > po.PurchaseOrderAmount 
					THEN 'Charge amount exceeds PO amount'
				 -- Other Exceptions	
				 WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 ELSE NULL
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = RIGHT(tc.CreditCardNumber,5)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID
	WHERE 1=1
	AND tcs.Name = 'Unmatched'
		
		
	/**************************************************************************************************/
	-- Update For No matches on PO# or CC#
	-- Conditions:
	--	No potential PO matches exist
	--  No potential CC# matches exist
	-- Cancelled Status
	--	Temporary Credit Card Issue Status is Cancelled
	-- Exception Status
	--	Temporary Credit Card Issue Status is NOT Cancelled
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE WHEN tc.IssueStatus = 'Cancelled' THEN @CancelledTemporaryCreditCardStatusID
				 ELSE @ExceptionTemporaryCreditCardStatusID
				 END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE WHEN tc.IssueStatus = 'Cancelled' THEN NULL
				 ELSE 'No matching PO# or CC#'
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	WHERE  1=1
	AND tcs.Name = 'Unmatched'
	AND NOT EXISTS (
		SELECT *
		FROM PurchaseOrder po
		WHERE
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		)
	AND NOT EXISTS (
		SELECT *
		FROM PurchaseOrder po
		WHERE  
		po.PurchaseOrderNumber <> LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND po.CompanyCreditCardNumber IS NOT NULL
		AND RIGHT(RTRIM(po.CompanyCreditCardNumber),5) = RIGHT(tc.CreditCardNumber,5)
		)


	/**************************************************************************************************/
	--Update to Exception Status - PO matches and CC# does not match
	-- Conditions
	--	PO# matches exactly
	--	CC# does not match or is blank
	UPDATE tc SET
		TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 WHEN RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = '' THEN 'Matching PO does not have a credit card number'
				 ELSE 'CC# Mismatch'
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND	RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) <> RIGHT(tc.CreditCardNumber,5)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID
	where tcs.Name = 'Unmatched'


	/**************************************************************************************************/
	--Update to Exception Status - PO does not match and CC# matches
	-- Conditions
	--	PO# does not match
	--	CC# matches exactly
	UPDATE tc SET
		TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 ELSE 'PO# Mismatch'
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber <> LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND	RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = RIGHT(tc.CreditCardNumber,5)
		AND po.CreateDate >= DATEADD(dd,1,tc.IssueDate)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID
	where tcs.Name = 'Unmatched'


	/**************************************************************************************************/
	-- Prepare Results
	SELECT 
		@Matched = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @MatchedTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@MatchedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @MatchedTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Unmatched = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @UnMatchedTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@UnmatchedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @UnMatchedTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Posted = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @PostededTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@PostedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @PostededTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Cancelled = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @CancelledTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@CancelledAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @CancelledTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Exception = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@ExceptionAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID

	-- Build string of 'Matched' IDs
	SELECT @MatchedIds = @MatchedIds + CONVERT(varchar(20),tc.ID) + ',' 
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	WHERE tc.TemporaryCreditCardStatusID = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Matched')

	-- Remove ending comma from string or IDs
	IF LEN(@MatchedIds) > 1 
		SET @MatchedIds = LEFT(@MatchedIds, LEN(@MatchedIds) - 1)

	DROP TABLE #SelectedTemporaryCC
	
	SELECT @Matched 'MatchedCount',
		   @MatchedAmount 'MatchedAmount',
		   --@Unmatched 'UnmatchedCount',
		   --@UnmatchedAmount 'UnmatchedAmount',
		   @Posted 'PostedCount',
		   @PostedAmount 'PostedAmount',
		   @Cancelled 'CancelledCount',
		   @CancelledAmount 'CancelledAmount',
		   @Exception 'ExceptionCount',
		   @ExceptionAmount 'ExceptionAmount',
		   @MatchedIds 'MatchedIds'
END

GO
