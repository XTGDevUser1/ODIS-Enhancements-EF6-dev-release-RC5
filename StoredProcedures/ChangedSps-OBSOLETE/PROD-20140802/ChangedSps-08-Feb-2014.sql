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

/****** Object:  StoredProcedure [dbo].[dms_BillingGenerateBillingDetails]    Script Date: 10/23/2013 04:40:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_BillingGenerateBillingDetails]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_BillingGenerateBillingDetails]
GO

/****** Object:  StoredProcedure [dbo].[dms_BillingGenerateBillingDetails]    Script Date: 10/23/2013 04:40:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[dms_BillingGenerateBillingDetails]
@pUserName as nvarchar(50),
@pBillingEvents as BillingDefinitionInvoiceLineEventsTableType READONLY
AS
/********************************************************************
 **
 **	dms_BillingGenerateBillingDetails
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/16/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**


**/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Declare local variables
declare	@Debug as int,
		@ProgramName as nvarchar(50),
		@Now as datetime,
		@RowToProcess as int,
		@NumRowsToProcess as int,
		@BillingDefinitionInvoiceID as int,
		@BillingDefinitionInvoiceLineID as int,
		@BillingDefinitionEventID as int,
		@BillingScheduleID as int,
		@Name as nvarchar(50),
		@Description as nvarchar(255),
		@ProductID as int,
		@AccountingSystemItemCode as nvarchar(14),
		@AccountingSystemGLCode	as nvarchar(50),
		@RateTypeName as nvarchar(50),
		@Rate as money,
		@FixedQuantity as int,
		@EventFilter as nvarchar(2000),
		@DBObject as nvarchar(255),
		@DefaultInvoiceDetailStatusID		int,
		@IsAdjustable						bit,
		@IsExcludable						bit,
		@ScheduleDate as datetime,
		@ScheduleRangeBeginDate as datetime,
		@ScheduleRangeEndDate as datetime,
		@SQLString as nvarchar(max),
		@BillingEventPrograms as BillingDefinitionProgramsTableType,
		@ParmDefinition as nvarchar(2000),
		@ReviewRequired as bit,
		@AmountIsAdjustable as bit,
		@BillingCode_DetailDisposition_REFRESH as int,
		@BillingCode_DetailDisposition_LOCKED as int,
		@BillingCode_DetailStatus_DELETE as int,
		@BillingCode_DetailStatus_POSTED as int,
		@BillingDefinitionInvoiceLineSequence as int,
		@UserName as nvarchar(50),
		@IsAdjusted as bit,
		@IsExcluded as bit,
		@IsEditable as bit
		

-- Initialize Local Variables
select	@Debug = 0
select	@Now = getdate()
select	@ProgramName = object_name(@@procid)
select	@RowToProcess = 1
select	@NumRowsToProcess = 0
select	@SQLString = ' '
select	@ParmDefinition = ' '


-- Capture Billing Codes to use
select	@BillingCode_DetailDisposition_REFRESH = ID from dbo.BillingInvoiceDetailDisposition where Name = 'REFRESH'
select	@BillingCode_DetailDisposition_LOCKED = ID from dbo.BillingInvoiceDetailDisposition where Name = 'LOCKED'
select	@BillingCode_DetailStatus_DELETE = ID from dbo.BillingInvoiceDetailStatus where Name = 'DELETED'
select	@BillingCode_DetailStatus_POSTED = ID from dbo.BillingInvoiceDetailStatus where Name = 'POSTED'


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Capture the user name.  If null, then get from the
-- ProgramName
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
if @pUserName is null
begin
		select @UserName = @ProgramName
end
else
begin
		select @UserName = @pUserName
end


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Capture the Columns from Billing Events Table parameter
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -(
if object_id('tempdb..#tmpBillingEvents', 'U') is not null drop table #tmpBillingEvents
create table #tmpBillingEvents
(BillingDefinitionInvoiceID int null,
 BillingDefinitionInvoiceLineID int null,
 BillingDefinitionInvoiceLineEventID int null
)

insert into #tmpBillingEvents
(BillingDefinitionInvoiceID,
 BillingDefinitionInvoiceLineID,
 BillingDefinitionInvoiceLineEventID)
select	BillingDefinitionInvoiceID,
		BillingDefinitionInvoiceLineID,
		BillingDefinitionInvoiceLineEventID
from	@pBillingEvents

if @Debug = 1
begin

select	@BillingCode_DetailStatus_DELETE as '@BillingCode_DetailStatus_DELETE',
		@BillingCode_DetailDisposition_REFRESH as '@BillingCode_DetailDisposition_REFRESH'

 select '#tmpBillingEvents', * from #tmpBillingEvents

end


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Capture the Open Schedule for the Definitions passed in 
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
if object_id('tempdb..#tmpDefOpenSchedules', 'U') is not null drop table #tmpDefOpenSchedules
create table #tmpDefOpenSchedules
(BillingDefinitionInvoiceID	int,
 BillingScheduleID			int,
 ScheduleTypeID				int,
 ScheduleDateTypeID			int,
 ScheduleRangeTypeID		int,
 ScheduleDate				datetime, 
 ScheduleRangeBegin			datetime,
 ScheduleRangeEnd			datetime,
 IsEditable					bit)

create index inx_tmpDefOpenSchedules1 on #tmpDefOpenSchedules (BillingDefinitionInvoiceID)

insert into #tmpDefOpenSchedules
(BillingDefinitionInvoiceID,
 BillingScheduleID,
 ScheduleTypeID,
 ScheduleDateTypeID,
 ScheduleRangeTypeID,
 ScheduleDate, 
 ScheduleRangeBegin,
 ScheduleRangeEnd,
 IsEditable)
select	bdi.ID, -- BillingDefinitionInvoiceID
		bs.ID, -- BillingScheduleID
		bs.ScheduleTypeID,
		bs.ScheduleDateTypeID,
		bs.ScheduleRangeTypeID,
		bs.ScheduleDate,
		bs.ScheduleRangeBegin,
		bs.ScheduleRangeEnd,
		bdile.IsEditable
from	dbo.BillingSchedule bs
join	dbo.BillingScheduleStatus bss on bss.ID = bs.ScheduleStatusID
join	dbo.BillingDefinitionInvoice bdi on bdi.ScheduleTypeID = bs.ScheduleTypeID
		and bdi.ScheduleDateTypeID = bs.ScheduleDateTypeID
		and bdi.ScheduleRangeTypeID = bs.ScheduleRangeTypeID
join
		(select	distinct BillingDefinitionInvoiceID
		 from	#tmpBillingEvents) D on D.BillingDefinitionInvoiceID = bdi.ID
left join	dbo.BillingDefinitionInvoiceLine bdil with (nolock) on bdil.BillingDefinitionInvoiceID = bdi.ID
		 
left join	dbo.BillingDefinitionInvoiceLineEvent bdile with (nolock) on 
		 bdile.BillingDefinitionInvoiceLineID = bdil.ID
		 
where	bss.Name = 'OPEN'


if @Debug = 1
begin
 select '#tmpDefOpenSchedules', * from #tmpDefOpenSchedules
end



-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Get Billing Invoice Meta data...this identifys the
-- breadth of how many invoice/line/details to create
-- This meta data temp table contains those elements
-- that will be taken from the definitions
-- and pushed over to the invoice detail table
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if object_id('tempdb..#tmpBillingInvoiceMeta', 'U') is not null drop table #tmpBillingInvoiceMeta
create table #tmpBillingInvoiceMeta
(RowID								int					identity,
 BillingDefinitionInvoiceID			int,
 BillingDefinitionInvoiceLineID		int,
 BillingDefinitionEventID			int,
 BillingScheduleID					int,
 Name								nvarchar(50),
 [Description]						nvarchar(255),
 ProductID							int,
 AccountingSystemItemCode			nvarchar(14),
 AccountingSystemGLCode				nvarchar(50),
 RateTypeName						nvarchar(50),
 Rate								money,
 FixedQuantity						int,
 EventFilter						nvarchar(2000),
 DBObject							nvarchar(255),
 DefaultInvoiceDetailStatusID		int,
 IsAdjustable						bit,
 IsExcludable						bit,
 ScheduleDate						datetime,
 ScheduleRangeBeginDate				datetime,
 ScheduleRangeEndDate				datetime,
 BillingDefinitionInvoiceLineSequence		int,
 IsEditable							bit
)

insert into #tmpBillingInvoiceMeta
(BillingDefinitionInvoiceID,
 BillingDefinitionInvoiceLineID,
 BillingDefinitionEventID,
 BillingScheduleID,
 Name,
 [Description],
 ProductID,
 AccountingSystemItemCode,
 AccountingSystemGLCode,
 RateTypeName,
 Rate,
 FixedQuantity,
 EventFilter,
 DBObject,
 DefaultInvoiceDetailStatusID,
 IsAdjustable,
 IsExcludable,
 ScheduleDate,
 ScheduleRangeBeginDate,
 ScheduleRangeEndDate,
 BillingDefinitionInvoiceLineSequence,
 IsEditable)
select	bdi.ID, -- BillingDefinitionInvoiceID
		bdil.ID, -- BillingDefinitionInvoiceLineID
		bde.ID, -- BillingDefinitionEventID
		O.BillingScheduleID, -- BillingScheduleID
		bdile.Name,
		bdile.[Description],
		bdil.ProductID,
		pr.AccountingSystemItemCode,
		pr.AccountingSystemGLCode,
		rt.Name, -- RateTypeName
		bdil.Rate,
		bdil.FixedQuantity,
		bdile.EventFilter,
		bde.DBObject,
		bdile.DefaultInvoiceDetailStatusID,
		bdile.IsAdjustable,
		bdile.IsExcludable,
		O.ScheduleDate, 
		O.ScheduleRangeBegin,
		O.ScheduleRangeEnd,
		bdil.Sequence, -- BillingDefinitionInvoiceLineSequence
		bdile.IsEditable
from	dbo.BillingDefinitionInvoice bdi
join	dbo.BillingDefinitionInvoiceLine bdil on bdil.BillingDefinitionInvoiceID = bdi.ID
join	dbo.BillingDefinitionInvoiceLineEvent bdile on bdile.BillingDefinitionInvoiceLineID = bdil.ID
join	dbo.BillingDefinitionEvent bde on bde.ID = bdile.BillingDefinitionEventID
join	dbo.RateType rt on rt.ID = bdil.RateTypeID
join	dbo.Product pr on pr.ID = bdil.ProductID
join	#tmpDefOpenSchedules O on O.BillingDefinitionInvoiceID = bdi.ID
		and O.ScheduleTypeID = bdi.ScheduleTypeID
		and	O.ScheduleDateTypeID = bdi.ScheduleDateTypeID
		and O.ScheduleRangeTypeID = bdi.ScheduleRangeTypeID
join	#tmpBillingEvents t on t.BillingDefinitionInvoiceID = bdi.ID -- Get the Programs to load
		and t.BillingDefinitionInvoiceLineID = bdil.ID
		and t.BillingDefinitionInvoiceLineEventID = bdile.ID
order by
		bdi.ID,
		bdil.Sequence


if @Debug = 1
begin
 select '#tmpBillingInvoiceMeta', * from #tmpBillingInvoiceMeta
end



-- Set the Number of Rows to Process
select	@NumRowsToProcess = count(*) from #tmpBillingInvoiceMeta

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Cycle thru the invoice Meta and 
-- Create Invoice Detail Data
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if object_id('tempdb..#tmpEventData', 'U') is not null drop table #tmpEventData
create table #tmpEventData
(ProgramID									int,
 EntityID									int,
 EntityKey									nvarchar(50),
 EntityDate									datetime,
 BaseQuantity								int,
 BaseAmount									money,
 BasePercentage								float,
 ---
 ServiceCode								nvarchar(50),
 BillingCode								nvarchar(50)
 )


if object_id('tempdb..#tmpInvoiceDetail', 'U') is not null drop table #tmpInvoiceDetail
create table #tmpInvoiceDetail
(RowID									int			identity,
 BillingDefinitionInvoiceID				int,
 BillingDefinitionInvoiceLineID			int,
 BillingDefinitionEventID				int,
 BillingScheduleID						int,
 ProgramID								int,
 EntityID								int,
 EntityKey								nvarchar(50),
 EntityDate								datetime,
 Name									nvarchar(50),
 [Description]							nvarchar(255),
 ---
 ServiceCode							nvarchar(50),
 BillingCode							nvarchar(50),
 ProductID								int,
 AccountingSystemItemCode				nvarchar(14),
 AccountingSystemGLCode					nvarchar(50),
 RateTypeName							nvarchar(50),
 Quantity								int,
 EventAmount							money,
 
 -- Status Cols
 InvoiceDetailStatusID					int, -- BillingInvoiceDetailStatus
 InvoiceDetailStatusAuthorization		nvarchar(100),
 InvoiceDetailStatusAuthorizationDate	datetime,

-- Disposition Cols
 InvoiceDetailDispositionID				nvarchar(50), -- BillingInvoiceDetailDisposition

 -- Adjustment Cols
 IsAdjustable							bit,
 AdjustmentReasonID						int, -- BillingAdjustmentReason
 AdjustmentReasonOther					nvarchar(50),
 AdjustmentComment						nvarchar(max),
 AdjustedBy								nvarchar(50),
 AdjustmentDate							datetime,
 AdjustmentAmount						money,
 AdjustmentAuthorization				nvarchar(100),
 AdjustmentAuthorizationDate			datetime,
 
 -- Exclude From Invoice Cols
 IsExcludable							bit,
 ExcludeReasonID						int, -- BillingExcludeReason
 ExcludeReasonOther						nvarchar(50),
 ExcludeComment							nvarchar(max),
 ExcludedBy								nvarchar(50),
 ExcludeDate							datetime,
 ExcludeAuthorization					nvarchar(100),
 ExcludeAuthorizationDate				datetime,


 BillingInvoiceLineID					int, -- brought over when invoice finalized
 
 Sequence								int,
 IsActive								bit,
 CreateDate								datetime,
 CreateBy								nvarchar(50),
 ModifyDate								datetime,
 ModifyBy								nvarchar(50),
 
 BaseQuantity							int,
 BaseAmount								money,
 BasePercentage							money,
 Rate									money,

 IsAdjusted								bit,
 IsExcluded								bit,
 IsEditable								bit
)


while @RowToProcess <= @NumRowsToProcess
begin

	print 'Start Cycle Here'
	print ' '

	-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	-- Capture Programs that are associated to
	-- the  Billing Event Line
	-- Put into a Table parameter...these will be passed to
	-- the Event DBObject
	-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	delete	@BillingEventPrograms
	insert into @BillingEventPrograms
	(ProgramID)
	select	bdilep.ProgramID
	from	#tmpBillingInvoiceMeta t
	join	BillingDefinitionInvoiceLineEvent bdile on bdile.BillingDefinitionInvoiceLineID = t.BillingDefinitionInvoiceLineID
	and		bdile.BillingDefinitionEventID = t.BillingDefinitionEventID
	join	BillingDefinitionInvoiceLineEventProgram bdilep on bdilep.BillingDefinitionInvoiceLineEventID = bdile.ID
	where	RowID = @RowToProcess

	-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	-- Get all other data elements from the meta data and
	-- save into local variables
	-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	select	@BillingDefinitionInvoiceID = BillingDefinitionInvoiceID,
			@BillingDefinitionInvoiceLineID = BillingDefinitionInvoiceLineID,
			@BillingDefinitionEventID = BillingDefinitionEventID,
			@BillingScheduleID = BillingScheduleID,
			@Name = Name,
			@Description = [Description],
			@ProductID = ProductID,
			@AccountingSystemItemCode = AccountingSystemItemCode,
			@AccountingSystemGLCode	= AccountingSystemGLCode,
			@RateTypeName = RateTypeName,
			@Rate = Rate,
			@FixedQuantity = FixedQuantity,
			@EventFilter = EventFilter,
			@DBObject = DBObject,
			@DefaultInvoiceDetailStatusID = DefaultInvoiceDetailStatusID,
			@IsAdjustable = IsAdjustable,
			@IsExcludable = IsExcludable,
			@ScheduleRangeBeginDate = ScheduleRangeBeginDate,
			@ScheduleRangeEndDate = ScheduleRangeEndDate,
			@BillingDefinitionInvoiceLineSequence = BillingDefinitionInvoiceLineSequence,
			@IsEditable = IsEditable
	from	#tmpBillingInvoiceMeta
	where	RowID = @RowToProcess


	if @Debug = 1
	begin
		select	'MetaData:',
				@BillingDefinitionInvoiceID as BillingDefinitionInvoiceID,
				@BillingDefinitionInvoiceLineID as BillingDefinitionInvoiceLineID,
				@BillingDefinitionEventID as BillingDefinitionEventID,
				@BillingScheduleID as BillingScheduleID,
				@Name as Name,
				@Description as [Description],
				@RateTypeName as RateTypeName,
				@Rate as Rate,
				@FixedQuantity as FixedQuantity,
				@ProductID as ProductID,
				@AccountingSystemItemCode as AccountingSystemItemCode,
				@AccountingSystemGLCode	as AccountingSystemGLCode,
				@EventFilter as EventFilter,
				@DBObject as DBObject,
				@DefaultInvoiceDetailStatusID as DefaultInvoiceDetailStatusID,
				@IsAdjustable as IsAdjustable,
				@IsExcludable as IsExcludable,
				@ScheduleDate as ScheduleDate,
				@ScheduleRangeBeginDate as ScheduleRangeBeginDate,
				@ScheduleRangeEndDate as ScheduleRangeEndDate,
				@BillingDefinitionInvoiceLineSequence as BillingDefinitionInvoiceLineSequence,
				@IsEditable as IsEditable

		select '@BillingEventPrograms', * from @BillingEventPrograms
		
	end


	-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	-- Execute the Event DBObject to get events
	-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	-- Create the SQL String that we will exec to get the detailed events
	select	@SQLString = @SQLString + N'insert into #tmpEventData '
	select	@SQLString = @SQLString + N'(ProgramID, '
	select	@SQLString = @SQLString + N'EntityID, '
	select	@SQLString = @SQLString + N'EntityKey, '
	select	@SQLString = @SQLString + N'EntityDate, '
	select	@SQLString = @SQLString + N'BaseQuantity, '
	select	@SQLString = @SQLString + N'BaseAmount, '
	select	@SQLString = @SQLString + N'BasePercentage, '
	select	@SQLString = @SQLString + N'ServiceCode, '
	select	@SQLString = @SQLString + N'BillingCode) '
	select	@SQLString = @SQLString + N'exec ' + @DBObject + ' @BillingEventPrograms, @ScheduleRangeBeginDate, @ScheduleRangeEndDate, @EventFilter'

	select @ParmDefinition = @ParmDefinition + N'@DBObject as nvarchar(255), '
	select @ParmDefinition = @ParmDefinition + N'@BillingEventPrograms as BillingDefinitionProgramsTableType READONLY, '
	select @ParmDefinition = @ParmDefinition + N'@ScheduleRangeBeginDate as datetime,   '
	select @ParmDefinition = @ParmDefinition + N'@ScheduleRangeEndDate as datetime,  '
	select @ParmDefinition = @ParmDefinition + N'@EventFilter as nvarchar(2000)'


	if @Debug = 1
	begin
		
		select	@SQLString as '@SQLString'

	end
	
	print @DBObject
	print ' '
	print 'String Build Execute Next statement'
	print ' '
	
	-- Get data
	exec sp_executesql @SQLString, @ParmDefinition, @DBObject, @BillingEventPrograms, @ScheduleRangeBeginDate, @ScheduleRangeEndDate, @EventFilter
	select	@SQLString = ' '
	select	@ParmDefinition = ' '
	
	print 'Execute just happened'
	print ' '
	

	if @Debug = 1
	begin
	
		select	'#tmpEventData', * from #tmpEventData

	end		

	-- Insert into temp formatted for the Detail Table
	insert into #tmpInvoiceDetail
	(BillingDefinitionInvoiceID,
	 BillingDefinitionInvoiceLineID,
	 BillingDefinitionEventID,
	 BillingScheduleID,
	 ProgramID,
	 EntityID,
	 EntityKey,
	 EntityDate,
	 Name,
	 [Description],
	 ---
	 ServiceCode,
	 BillingCode,
	 ProductID,
	 AccountingSystemItemCode,
	 AccountingSystemGLCode,
	 RateTypeName,
	 Quantity,
	 EventAmount,
	 InvoiceDetailStatusID,
	 InvoiceDetailStatusAuthorization,
	 InvoiceDetailStatusAuthorizationDate,
	 InvoiceDetailDispositionID,
	 IsAdjustable,
	 AdjustmentReasonID,
	 AdjustmentReasonOther,
	 AdjustmentComment,
	 AdjustedBy,
	 AdjustmentDate,
	 AdjustmentAmount,
	 AdjustmentAuthorization,
	 AdjustmentAuthorizationDate,
	 IsExcludable,
	 ExcludeReasonID,
	 ExcludeReasonOther,
	 ExcludeComment,
	 ExcludedBy,
	 ExcludeDate,
	 ExcludeAuthorization,
	 ExcludeAuthorizationDate,
	 BillingInvoiceLineID,
	 Sequence,
	 IsActive,
	 CreateDate,
	 CreateBy,
	 ModifyDate,
	 ModifyBy,
	 
	 BaseQuantity,
	 BaseAmount,
	 BasePercentage,
	 Rate,
	 IsAdjusted,
	 IsExcluded,
	 IsEditable)
	select	@BillingDefinitionInvoiceID, -- BillingDefinitionInvoiceID
			@BillingDefinitionInvoiceLineID, -- BillingDefinitionInvoiceLineID
			@BillingDefinitionEventID, -- BillingDefinitionEventID
			@BillingScheduleID, -- BillingScheduleID
			ProgramID, -- ProgramID
			EntityID, -- EntityID
			EntityKey, -- EntityKey
			EntityDate, -- EntityDate
			@Name, -- Name
			@Description, -- [Description] -- from the BillingEvent proc
			---
			ServiceCode,
			BillingCode,
			@ProductID,
			@AccountingSystemItemCode,
			@AccountingSystemGLCode,
			@RateTypeName,
			case
			 when @RateTypeName = 'AmountFixed' then @FixedQuantity
			 else BaseQuantity
			end, -- Quantity
			BaseAmount, -- EventAmount

			@DefaultInvoiceDetailStatusID, -- InvoiceDetailStatusID
			null,	-- InvoiceDetailStatusAuthorization
			null,	-- InvoiceDetailStatusAuthorizationDate
			@BillingCode_DetailDisposition_REFRESH, -- InvoiceDetailDispositionID : REFRESH << Default to REFRESH
			@IsAdjustable, -- IsAdjustable
			null, -- AdjustmentReasonID
			null, -- AdjustmentReasonOther
			null, -- AdjustmentComment
			null, -- AdjustedBy
			null, -- AdjustmentDate
			null, -- AdjustmentAmount
			null, -- AdjustmentAuthorization
			null, -- AdjustmentAuthorizationDate
			@IsExcludable, -- IsExcludable
			null, -- ExcludeReasonID
			null, -- ExcludeReasonOther
			null, -- ExcludeComment
			null, -- ExcludedBy
			null, -- ExcludeDate
			null, -- ExcludeAuthorization
			null, -- ExcludeAuthorizationDate

			null, -- BillingInvoiceLineID

			@BillingDefinitionInvoiceLineSequence, -- Sequence
			1, -- IsActive

			@Now, -- CreateDate
			@UserName, -- CreateBy
			null, -- ModifyDate
			null, -- ModifyBy
			case
			 when @RateTypeName = 'AmountFixed' then @FixedQuantity
			 else BaseQuantity
			end, -- BaseQuantity
			BaseAmount,
			BasePercentage,
			@Rate, -- Rate
			0, -- IsAdjusted,
			0, -- IsExcluded,
			@IsEditable -- IsEditable
			
	from	#tmpEventData

-- select 'TEST>>>', @FixedQuantity as FixedQuantity

	
	-- Price the records
	update	#tmpInvoiceDetail
	set		EventAmount = dbo.fnc_BillingCalcPriceUsingRateType
			(RateTypeName, 
			 BaseQuantity,
			 case
			  when RateTypeName = 'AmountPassThru' then BaseAmount
			  when RateTypeName = 'PercentageEach' then BaseAmount
			  when RateTypeName = 'AmountFixed' then Rate
			  else Rate
			 end,
			 case
			  when RateTypeName = 'PercentageEach' then Rate
			  else BasePercentage
			 end)


	-- Clear out table in prep for next cycle
	truncate table #tmpEventData
	--delete @BillingEventPrograms
	

	-- Increment counter
	select	@RowToProcess = @RowToProcess + 1
	
	print 'Increment here'
	print ' '

end

print 'Processing Deletes '
print ' '

-- select 'TEST>>>>', * from #tmpInvoiceDetail

-- First see if records no longer exist...capture these as DELETES
if object_id('tempdb..#tmpDeletes', 'U') is not null drop table #tmpDeletes
create table #tmpDeletes
(BillingDefinitionInvoiceID	int,
 BillingDefinitionInvoiceLineID int,
 BillingDefinitionEventID int,
 BillingScheduleID int,
 ProgramID int,
 EntityID int,
 EntityKey nvarchar(50),
 IsEditable bit)

insert into #tmpDeletes
(BillingDefinitionInvoiceID,
 BillingDefinitionInvoiceLineID,
 BillingDefinitionEventID,
 BillingScheduleID,
 ProgramID,
 EntityID,
 EntityKey,
 IsEditable)
select	BillingDefinitionInvoiceID,
		BillingDefinitionInvoiceLineID,
		BillingDefinitionEventID,
		BillingScheduleID,
		ProgramID,
		EntityID,
		EntityKey,
		IsEditable
from	dbo.BillingInvoiceDetail bid
where	exists -- Within the Invoice Definition and Schedule 
	(select 1
	 from	#tmpInvoiceDetail tmp
	 where	tmp.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID
	 and	tmp.BillingScheduleID = bid.BillingScheduleID)
and not exists -- But not found
	(select 1
	 from	#tmpInvoiceDetail tmp
	 where	tmp.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID
	 and	tmp.BillingDefinitionInvoiceLineID = bid.BillingDefinitionInvoiceLineID
	 and	tmp.BillingDefinitionEventID = bid.BillingDefinitionEventID
	 and	tmp.BillingScheduleID = bid.BillingScheduleID
	 and	tmp.ProgramID = bid.ProgramID
	 and	tmp.EntityID = bid.EntityID
	 and	tmp.EntityKey = bid.EntityKey)
and	InvoiceDetailDispositionID = @BillingCode_DetailDisposition_REFRESH -- is in REFRESH
and InvoiceDetailStatusID <> @BillingCode_DetailStatus_POSTED -- is Not POSTED


if isnull(@Debug, 1) <> 0
begin

	select '#tmpInvoiceDetail', * from #tmpInvoiceDetail
	select '#tmpDeletes', * from #tmpDeletes
	
end
else
begin

	-- Process Deletes by updating the Status to DELETED
	update	dbo.BillingInvoiceDetail
	set		InvoiceDetailStatusID = @BillingCode_DetailStatus_DELETE -- Change Status to Deleted
	from	dbo.BillingInvoiceDetail bid
	join	#tmpDeletes tmp on tmp.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID
	and		tmp.BillingDefinitionInvoiceLineID = bid.BillingDefinitionInvoiceLineID
	and		tmp.BillingDefinitionEventID = bid.BillingDefinitionEventID
	and		tmp.BillingScheduleID = bid.BillingScheduleID
	and		tmp.ProgramID = bid.ProgramID
	and		tmp.EntityID = bid.EntityID
	and		tmp.EntityKey = bid.EntityKey

print 'Deletes Completed'
print ' '

	-- Create Billing Invoice Detail Events
	-- MERGE...If new, then insert,  If not, then check the QueueDisposition:
	-- when 'Refresh' then update, if 'Lock' ignore 

MERGE	dbo.BillingInvoiceDetail as target
USING
		(	select	BillingDefinitionInvoiceID,
					BillingDefinitionInvoiceLineID,
					BillingDefinitionEventID,
					BillingScheduleID,
					ProgramID,
					EntityID,
					EntityKey,
					EntityDate,
					Name,
					[Description],
					---
					ServiceCode,
					BillingCode,
					ProductID,
					AccountingSystemItemCode,
					AccountingSystemGLCode,
					RateTypeName,
					Quantity,
					EventAmount,

					InvoiceDetailStatusID,
					InvoiceDetailStatusAuthorization,
					InvoiceDetailStatusAuthorizationDate,
					InvoiceDetailDispositionID,

					IsAdjustable,
					AdjustmentReasonID,
					AdjustmentReasonOther,
					AdjustmentComment,
					AdjustedBy,
					AdjustmentDate,
					AdjustmentAmount,
					AdjustmentAuthorization,
					AdjustmentAuthorizationDate,
					IsExcludable,
					ExcludeReasonID,
					ExcludeReasonOther,
					ExcludeComment,
					ExcludedBy,
					ExcludeDate,
					ExcludeAuthorization,
					ExcludeAuthorizationDate,

					BillingInvoiceLineID,
					 
					Sequence,
					IsActive,
					CreateDate,
					CreateBy,
					ModifyDate,
					ModifyBy,
					IsAdjusted,
					IsExcluded,
					IsEditable

	from	#tmpInvoiceDetail)
AS SOURCE
(BillingDefinitionInvoiceID,
 BillingDefinitionInvoiceLineID,
 BillingDefinitionEventID,
 BillingScheduleID,
 ProgramID,
 EntityID,
 EntityKey,
 EntityDate,
 Name,
 [Description],
 ---
 ServiceCode,
 BillingCode,
 ProductID,
 AccountingSystemItemCode,
 AccountingSystemGLCode,
 RateTypeName,
 Quantity,
 EventAmount,
 InvoiceDetailStatusID,
 InvoiceDetailStatusAuthorization,
 InvoiceDetailStatusAuthorizationDate,
 InvoiceDetailDispositionID,
 IsAdjustable,
 AdjustmentReasonID,
 AdjustmentReasonOther,
 AdjustmentComment,
 AdjustedBy,
 AdjustmentDate,
 AdjustmentAmount,
 AdjustmentAuthorization,
 AdjustmentAuthorizationDate,
 IsExcludable,
 ExcludeReasonID,
 ExcludeReasonOther,
 ExcludeComment,
 ExcludedBy,
 ExcludeDate,
 ExcludeAuthorization,
 ExcludeAuthorizationDate,
 BillingInvoiceLineID,
 Sequence,
 IsActive,
 CreateDate,
 CreateBy,
 ModifyDate,
 ModifyBy,
 IsAdjusted,
 IsExcluded,
 IsEditable
)

ON 
	(target.BillingDefinitionInvoiceID = source.BillingDefinitionInvoiceID
	and		target.BillingDefinitionInvoiceLineID = source.BillingDefinitionInvoiceLineID
	and		target.BillingDefinitionEventID = source.BillingDefinitionEventID
	and		target.BillingScheduleID = source.BillingScheduleID
	and		target.ProgramID = source.ProgramID
	and		target.EntityID = source.EntityID
	and		target.EntityKey = source.EntityKey
	and		target.ISEditable = source.IsEditable)

WHEN MATCHED and target.InvoiceDetailDispositionID = @BillingCode_DetailDisposition_REFRESH THEN 
UPDATE
SET		EntityDate = source.EntityDate,
		Name = source.Name,
		[Description] = source.[Description],
		---
		ServiceCode = source.ServiceCode,
		BillingCode = source.BillingCode,
		ProductID = source.ProductID,
		AccountingSystemItemCode = source.AccountingSystemItemCode,
		AccountingSystemGLCode = source.AccountingSystemGLCode,
		RateTypeName = source.RateTypeName,
		Quantity = source.Quantity,
		EventAmount = source.EventAmount,
		Sequence = source.Sequence,
		ModifyDate = @Now,
		ModifyBy = @UserName

WHEN NOT MATCHED THEN	
INSERT	(BillingDefinitionInvoiceID,
		 BillingDefinitionInvoiceLineID,
		 BillingDefinitionEventID,
		 BillingScheduleID,
		 ProgramID,
		 EntityID,
		 EntityKey,
		 EntityDate,
		 Name,
		 [Description],
		 ---
		 ServiceCode,
		 BillingCode,
		 ProductID,
		 AccountingSystemItemCode,
		 AccountingSystemGLCode,
		 RateTypeName,
		 Quantity,
		 EventAmount,
		 InvoiceDetailStatusID,
		 InvoiceDetailStatusAuthorization,
		 InvoiceDetailStatusAuthorizationDate,
		 InvoiceDetailDispositionID,
		 IsAdjustable,
		 AdjustmentReasonID,
		 AdjustmentReasonOther,
		 AdjustmentComment,
		 AdjustedBy,
		 AdjustmentDate,
		 AdjustmentAmount,
		 AdjustmentAuthorization,
		 AdjustmentAuthorizationDate,
		 IsExcludable,
		 ExcludeReasonID,
		 ExcludeReasonOther,
		 ExcludeComment,
		 ExcludedBy,
		 ExcludeDate,
		 ExcludeAuthorization,
		 ExcludeAuthorizationDate,
		 BillingInvoiceLineID,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy,
		 IsAdjusted,
		 IsExcluded,
		 IsEditable
)
VALUES (source.BillingDefinitionInvoiceID,
		source.BillingDefinitionInvoiceLineID,
		source.BillingDefinitionEventID,
		source.BillingScheduleID,
		source.ProgramID,
		source.EntityID,
		source.EntityKey,
		source.EntityDate,
		source.Name,
		source.[Description],
		---
		source.ServiceCode,
		source.BillingCode,
		source.ProductID,
		source.AccountingSystemItemCode,
		source.AccountingSystemGLCode,
		source.RateTypeName,
		source.Quantity,
		source.EventAmount,
		source.InvoiceDetailStatusID,
		source.InvoiceDetailStatusAuthorization,
		source.InvoiceDetailStatusAuthorizationDate,
		source.InvoiceDetailDispositionID,
		source.IsAdjustable,
		source.AdjustmentReasonID,
		source.AdjustmentReasonOther,
		source.AdjustmentComment,
		source.AdjustedBy,
		source.AdjustmentDate,
		source.AdjustmentAmount,
		source.AdjustmentAuthorization,
		source.AdjustmentAuthorizationDate,
		source.IsExcludable,
		source.ExcludeReasonID,
		source.ExcludeReasonOther,
		source.ExcludeComment,
		source.ExcludedBy,
		source.ExcludeDate,
		source.ExcludeAuthorization,
		source.ExcludeAuthorizationDate,
		source.BillingInvoiceLineID,
		source.Sequence,
		source.IsActive,
		source.CreateDate,
		source.CreateBy,
		source.ModifyDate,
		source.ModifyBy,
		source.IsAdjusted,
		source.IsExcluded,
		source.IsEditable
);

end






GO



GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ClientBillableEventProcessing_Details]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ClientBillableEventProcessing_Details] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
-- EXEC dms_ClientBillableEventProcessing_Details 1
CREATE PROC dms_ClientBillableEventProcessing_Details(@pBillingInvoiceDetail INT = NULL)
AS
BEGIN
SELECT	
		--Billable Event Section
		BID.ID as BillingInvoiceDetailID,
		BIDs.[ID] DetailsStatusID,
		BIDs.[Description] as DetailStatus,
		BIDd.ID as DispositionID,
		BIDd.[Description] as Disposition,
		BID.EntityKey,
		e.Name as EntityType,
		BID.EntityDate,
		BID.ServiceCode,
		BID.Quantity,
		BID.EventAmount,
		pro.Id as ProgramID,
		pro.Description as Program,
		'' MembershipNumber,
		'' MemberName,
		BID.InvoiceDetailStatusAuthorization + ' ' + BID.InvoiceDetailStatusAuthorizationDate as AuthorizedBy,
		
		--Invoice Information Section
		bis.[Description] as InvoiceStatus,
		bis.ID InvoiceStatusID,
		bis.Name InvoiceStatusName,
		bi.InvoiceNumber,
		bi.InvoiceDate,
		cl.Name as ClientName,
		bst.Name as BillingSchedule,
		bdi.Name as InvoiceName,
		bdil.Name as LineName,
		pr.Name as ProductName,
		bdile.Name as EventName,
		bdil.[Description] as EventDescription,
		BID.RateTypeName as Rate,
		pr.AccountingSystemGLCode as GLCode,	
		
		--Adjustment Section
		BID.IsAdjustable as Adjustable,
		BID.AdjustmentAmount,
		
		bar.ID AdjustmentReasonID,
		bar.[Description] as AdjustmentReason,
		BID.AdjustmentReasonOther,
		BID.AdjustmentComment,
		BID.AdjustedBy,
		BID.AdjustmentDate,
		
		-- Other Information
		BID.IsExcludable as Excludable,
		ber.ID as ExcludeReasonID, 
		ber.[Description] as ExcludeReason,
		BID.ExcludeReasonOther,
		BID.ExcludeComment,
		BID.ExcludedBy,
		BID.ExcludeDate,
		
		-- Audit Section
		BID.CreateBy,
		BID.CreateDate,
		BID.ModifyBy,
		BID.ModifyDate,
		
		--Newly Added
		BID.IsAdjusted,
		BID.IsExcluded,
		
		--TOP Headers
		bi.[Description] AS InvoiceDescription,
		bil.[Description] AS LineDescription,
		BID.IsEditable AS IsQuantityAndAmountEditable  

FROM	dbo.BillingInvoiceDetail BID with (nolock)
left join	dbo.BillingDefinitionInvoice bdi with (nolock) on bdi.ID = BID.BillingDefinitionInvoiceID
left join	dbo.BillingDefinitionInvoiceLine bdil with (nolock) on bdil.ID = BID.BillingDefinitionInvoiceLineID
left join	dbo.BillingDefinitionInvoiceLineEvent bdile with (nolock) on bdile.BillingDefinitionInvoiceLineID = bdil.ID
		and bdile.BillingDefinitionInvoiceLineID = BID.BillingDefinitionInvoiceLineID
		and bdile.BillingDefinitionEventID = BID.BillingDefinitionEventID
left join	dbo.BillingDefinitionEvent bde with (nolock) on bde.ID = BID.BillingDefinitionEventID
left join	dbo.BillingSchedule bs with (nolock) on bs.ID = BID.BillingScheduleID
left join	dbo.Product pr with (nolock) on pr.ID = BID.ProductID
left join	dbo.Program pro with (nolock) on pro.ID = BID.ProgramID
left join	dbo.Client cl with (nolock) on cl.ID = bdi.ClientID
left join	dbo.BillingScheduleStatus bss with (nolock) on bss.ID = bs.ScheduleStatusID
left join	dbo.BillingInvoiceDetailStatus BIDs with (nolock) on BIDs.ID = BID.InvoiceDetailStatusID
left join	dbo.BillingInvoiceDetailDisposition BIDd with (nolock) on BIDd.ID = BID.InvoiceDetailDispositionID
left join	dbo.BillingScheduleType bst with (nolock) on bst.ID = bs.ScheduleTypeID
left outer join dbo.Entity e with (nolock) on e.ID = BID.EntityID
left outer join	dbo.BillingAdjustmentReason bar on bar.ID = BID.AdjustmentReasonID
left outer join	dbo.BillingExcludeReason ber on ber.ID = BID.ExcludeReasonID
left outer join dbo.BillingInvoiceLine bil with (nolock) on bil.ID = BID.BillingInvoiceLineID
left outer join dbo.BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID
left outer join dbo.BillingInvoiceStatus bis with(nolock) on bis.ID = bi.InvoiceStatusID

WHERE	BID.ID = @pBillingInvoiceDetail

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
	
	DECLARE @BillingScheduleID AS TABLE(RecordID INT IDENTITY(1,1), BillingScheduleID INT)
	INSERT INTO @BillingScheduleID(BillingScheduleID) SELECT item FROM dbo.fnSplitString(@billingSchedules,',')
	DECLARE @scheduleID AS INT
	DECLARE @ProcessingCounter AS INT = 1
	DECLARE @TotalRows AS INT
	SELECT  @TotalRows = MAX(RecordID) FROM @BillingScheduleID
	
	DECLARE @entityID AS INT 
	DECLARE @eventID AS INT
	SELECT  @entityID = ID FROM Entity WHERE Name = 'BillingSchedule'
	SELECT  @eventID =  ID FROM Event WHERE Name = 'ClosePeriod'

	WHILE @ProcessingCounter <= @TotalRows
	BEGIN
			SET @scheduleID = (SELECT BillingScheduleID FROM @BillingScheduleID WHERE RecordID = @ProcessingCounter)
			
			-- Write Process Logic for Schedule ID

			-- Create Event Logs Reocords
			INSERT INTO EventLog([EventID],				[SessionID],				[Source],			[Description],
								 [Data],				[NotificationQueueDate],	[CreateBy],			[CreateDate]) 
			VALUES				(@eventID,				@sessionID,					@pageReference,		 @scheduleID,
								 NULL,					NULL,						@userName,			GETDATE())
			
			-- CREATE Link Records
			INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) VALUES(SCOPE_IDENTITY(),@entityID,@scheduleID)
			
			SET @ProcessingCounter = @ProcessingCounter + 1
	END
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
	ScheduleName nvarchar(100)  NULL ,
	ScheduleDate datetime  NULL ,
	ScheduleRangeBegin datetime  NULL ,
	ScheduleRangeEnd datetime  NULL ,
	Status nvarchar(100)  NULL ,
	InvoicesToBeCreatedCount int  NULL 
) 

DECLARE @QueryResult AS TABLE( 
	BillingScheduleID int  NULL ,
	ScheduleName nvarchar(100)  NULL ,
	ScheduleDate datetime  NULL ,
	ScheduleRangeBegin datetime  NULL ,
	ScheduleRangeEnd datetime  NULL ,
	Status nvarchar(100)  NULL ,
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
	
	DECLARE @BillingScheduleID AS TABLE(RecordID INT IDENTITY(1,1), BillingScheduleID INT)
	INSERT INTO @BillingScheduleID(BillingScheduleID) SELECT item FROM dbo.fnSplitString(@billingSchedules,',')
	DECLARE @scheduleID AS INT
	DECLARE @ProcessingCounter AS INT = 1
	DECLARE @TotalRows AS INT
	SELECT  @TotalRows = MAX(RecordID) FROM @BillingScheduleID
	
	DECLARE @entityID AS INT 
	DECLARE @eventID AS INT
	SELECT  @entityID = ID FROM Entity WHERE Name = 'BillingInvoice'
	SELECT  @eventID =  ID FROM Event WHERE Name = 'OpenPeriod'

	WHILE @ProcessingCounter <= @TotalRows
	BEGIN
			SET @scheduleID = (SELECT BillingScheduleID FROM @BillingScheduleID WHERE RecordID = @ProcessingCounter)
			
			-- Write Process Logic for Schedule ID

			-- Create Event Logs Reocords
			INSERT INTO EventLog([EventID],				[SessionID],				[Source],			[Description],
								 [Data],				[NotificationQueueDate],	[CreateBy],			[CreateDate]) 
			VALUES				(@eventID,				@sessionID,					@pageReference,		 @scheduleID,
								 NULL,					NULL,						@userName,			GETDATE())
			
			-- CREATE Link Records
			INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) VALUES(SCOPE_IDENTITY(),@entityID,@scheduleID)
			
			SET @ProcessingCounter = @ProcessingCounter + 1
	END
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
	
	
	
	DECLARE @Matched INT =0,
		@MatchedAmount money =0,
		@Posted INT=0,
		@PostedAmount money=0,
		@Cancelled INT=0,
		@CancelledAmount money=0,
		@Exception INT=0,
		@ExceptionAmount money=0,
		@MatchedIds nvarchar(max)=''
		
	DECLARE @invoicesFromDB TABLE
	(	
		ID INT IDENTITY(1,1),
		InvoiceID INT
	)
	
	INSERT INTO @invoicesFromDB
	SELECT VI.ID
	FROM	TemporaryCreditCard  VI WITH (NOLOCK)
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @tempccIdXML.nodes('/Tempcc/ID') T(c)
			) T ON VI.ID = T.ID
	
	DECLARE @maxRows INT, @index INT = 1,@tempCCId INT = 0,
			@exceptionMessage NVARCHAR(500) = '',@tempccNumber NVARCHAR(50)=NULL,@totalChargedAmount money=0,
			@referencePONumber NVARCHAR(50)='',@ccMatchCount INT =0,@poMatchCount INT = 0
			
	SELECT @maxRows = COUNT(*) FROM @invoicesFromDB
	
	WHILE ( @index <= @maxRows)
	BEGIN
		SET @exceptionMessage = ''
		SET @tempCCId = (SELECT InvoiceID FROM @invoicesFromDB WHERE ID=@index)
		SET @tempccNumber = (SELECT RIGHT((ltrim(rtrim(isnull(CreditCardNumber,'')))),5) FROM TemporaryCreditCard WITH (NOLOCK) WHERE ID = @tempCCId)
		SET @totalChargedAmount = (SELECT ISNULL(TotalChargedAmount,0) FROM TemporaryCreditCard WITH (NOLOCK) WHERE ID = @tempCCId)
		SET @referencePONumber = (SELECT ReferencePurchaseOrderNumber FROM TemporaryCreditCard WITH (NOLOCK) WHERE ID = @tempCCId)
		
		--Process posted status.Ignore processing other blocks
		IF((SELECT Count(TC.ID) FROM TemporaryCreditCard TC
		   JOIN TemporaryCreditCardStatus TCS ON TCS.ID = TC.TemporaryCreditCardStatusID
		   WHERE TC.ID = @tempCCId AND (TCS.Name = 'Posted' OR TC.PostingBatchID is not null) ) > 0)
		BEGIN
			SET @Posted = @Posted + 1
			SET @PostedAmount = @PostedAmount + @totalChargedAmount
		END
		--Process cancelled status
		ELSE IF((SELECT Count(ID) FROM TemporaryCreditCard WITH (NOLOCK) WHERE ID = @tempCCId AND IssueStatus='Cancel') > 0)
		BEGIN
			IF((SELECT Count(TC.ID) FROM TemporaryCreditCard TC WITH (NOLOCK)
			   JOIN PurchaseOrder PO WITH (NOLOCK) ON PO.PurchaseOrderNumber = TC.ReferencePurchaseOrderNumber
			   WHERE TC.ID = @tempCCId) = 0)
			BEGIN
			
				UPDATE TemporaryCreditCard
				SET TemporaryCreditCardStatusID = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name='Cancelled'),
					ModifyBy = @currentUser,
					ModifyDate = @now,
					ExceptionMessage = NULL
				WHERE ID = @tempCCId
				
				SET @Cancelled = @Cancelled + 1
				SET @CancelledAmount = @CancelledAmount + @totalChargedAmount
				
			END
			
		END
		--Process exact match
		ELSE IF((SELECT Count(*) FROM
				(
				SELECT TOP 1 PO.PurchaseOrderAmount,
					   RIGHT((ltrim(rtrim(isnull(PO.CompanyCreditCardNumber,'')))),5) POCCNumber
				FROM PurchaseOrder PO WITH (NOLOCK)
			    WHERE PO.PurchaseOrderNumber = @referencePONumber
				)TP WHERE TP.PurchaseOrderAmount >= @totalChargedAmount AND @tempccNumber != '' AND TP.POCCNumber = @tempccNumber)
				> 0)
		BEGIN
			    UPDATE TemporaryCreditCard
				SET TemporaryCreditCardStatusID = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name='Matched'),
				    ModifyBy = @currentUser,
					ModifyDate = @now,
					ExceptionMessage = NULL
				WHERE ID = @tempCCId
				
				
		END
		--Process exceptions
		ELSE
		BEGIN
			--Check cancelled po exist
			IF((SELECT Count(TC.ID) FROM TemporaryCreditCard TC WITH (NOLOCK)
			   JOIN PurchaseOrder PO ON PO.PurchaseOrderNumber = TC.ReferencePurchaseOrderNumber
			   WHERE TC.ID = @tempCCId AND TC.IssueStatus = 'Cancel') > 0)
			BEGIN
				SET @exceptionMessage = @exceptionMessage + 'PO matches cancelled CC' + ','
				
			END
			
			--Check charge amount greater than po amount
			IF((SELECT Count(TC.ID) FROM TemporaryCreditCard TC WITH (NOLOCK)
			   JOIN PurchaseOrder PO WITH (NOLOCK) ON PO.PurchaseOrderNumber = TC.ReferencePurchaseOrderNumber
			   WHERE TC.ID = @tempCCId AND PO.PurchaseOrderAmount < @totalChargedAmount) > 0)
			BEGIN
				SET @exceptionMessage = @exceptionMessage + 'Charge amount exceeds PO amount' + ','
				
			END
			
			--Check pomismatch
			SET @ccMatchCount = (SELECT Count(PO.ID)
								 FROM PurchaseOrder PO WITH (NOLOCK)
								 WHERE RIGHT((ltrim(rtrim(isnull(PO.CompanyCreditCardNumber,'')))),5) = @tempccNumber)
			
			IF(@ccMatchCount > 0)
			BEGIN
				IF((SELECT Count(*) FROM
									(
									 SELECT PO.PurchaseOrderNumber
									 FROM PurchaseOrder PO WITH (NOLOCK)
									 WHERE RIGHT((ltrim(rtrim(isnull(PO.CompanyCreditCardNumber,'')))),5) = @tempccNumber
									)TP WHERE TP.PurchaseOrderNumber = @referencePONumber) = 0)
				
				BEGIN
					SET @exceptionMessage = @exceptionMessage + 'PO# Mismatch' + ','
					
				END
				
			END	
			
			--Check cc mismatch				
			SET @poMatchCount = (SELECT COUNT(PO.ID)
								FROM PurchaseOrder PO WITH (NOLOCK)
								WHERE PO.PurchaseOrderNumber = @referencePONumber)	
			
			IF(@poMatchCount > 0)
			BEGIN
				IF((SELECT Count(*) FROM
									(
									SELECT PO.PurchaseOrderAmount,
										   RIGHT((ltrim(rtrim(isnull(PO.CompanyCreditCardNumber,'')))),5) POCCNumber
									FROM PurchaseOrder PO WITH (NOLOCK)
									WHERE PO.PurchaseOrderNumber = @referencePONumber
									)TP WHERE @tempccNumber != '' AND TP.POCCNumber = @tempccNumber) = 0)
				BEGIN
					SET @exceptionMessage = @exceptionMessage + 'CC# Mismatch' + ','
					
				END
			END
			
			--Check if both po and cc does not match
			IF(@ccMatchCount = 0 AND @poMatchCount = 0)
			BEGIN
				SET @exceptionMessage = @exceptionMessage + 'No matching PO# or CC#' + ','
			END
			
			--Update exception and amount
			IF(@exceptionMessage != '')
			BEGIN
				IF((charindex(',', reverse(@exceptionMessage))) = 1)
				BEGIN
					SET @exceptionMessage = SUBSTRING(@exceptionMessage,1,LEN(@exceptionMessage)-1)
				END
				
				UPDATE TemporaryCreditCard
				SET TemporaryCreditCardStatusID = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name='Exception'),
				    ExceptionMessage = @exceptionMessage,
				    ModifyBy = @currentUser,
					ModifyDate = @now
				WHERE ID = @tempCCId
				
				SET @Exception = @Exception + 1
				SET @ExceptionAmount = @ExceptionAmount + @totalChargedAmount
			END
		END
		
		IF((SELECT Count(ID) FROM TemporaryCreditCard
			WHERE TemporaryCreditCardStatusID=(SELECT ID FROM TemporaryCreditCardStatus WHERE Name='Matched') AND ID=@tempCCId)
			>0)
		BEGIN
			SET @Matched = @Matched + 1
			SET @MatchedAmount = @MatchedAmount + @totalChargedAmount
				
			SET @MatchedIds = @MatchedIds + CONVERT(nvarchar(20),@tempCCId) + ','
		END
		
	    SET @index = @index + 1
	END
	
	IF((charindex(',', reverse(@MatchedIds))) = 1)
	BEGIN
		SET @MatchedIds = SUBSTRING(@MatchedIds,1,LEN(@MatchedIds)-1)
	END
	
	SELECT @Matched 'MatchedCount',
		   @MatchedAmount 'MatchedAmount',
		   @Posted 'PostedCount',
		   @PostedAmount 'PostedAmount',
		   @Cancelled 'CancelledCount',
		   @CancelledAmount 'CancelledAmount',
		   @Exception 'ExceptionCount',
		   @ExceptionAmount 'ExceptionAmount',
		   @MatchedIds 'MatchedIds'
END
GO
