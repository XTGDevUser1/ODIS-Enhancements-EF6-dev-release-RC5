IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_activity_list_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_activity_list_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_vendor_activity_list_get @vendorID = 25,@whereClauseXML = '<ROW><Filter TypeOperator="11" TypeValue="Contact Log"></Filter></ROW>' 

 CREATE PROCEDURE [dbo].[dms_vendor_activity_list_get](  
  @vendorID INT = NULL -- TODO - Let's use this in the where clause.   
  ,@whereClauseXML NVARCHAR(4000) = NULL   
  ,@startInd Int = 1   
  ,@endInd BIGINT = 5000   
  ,@pageSize int = 10    
  ,@sortColumn nvarchar(100)  = ''   
  ,@sortOrder nvarchar(100) = 'ASC'   
    
 )   
 AS   
 BEGIN   
   
SET FMTONLY OFF  
SET NOCOUNT ON  

DECLARE @tmpFinalResults TABLE  
--CREATE TABLE #tmpFinalResults   
(   
 Type nvarchar(50)  NULL ,  
 Name nvarchar(50)  NULL ,  
 ID int  NULL ,  
 Description nvarchar(MAX)  NULL ,  
 TypeDescription nvarchar(MAX)  NULL ,  
 Company nvarchar(100)  NULL ,  
 TalkedTo nvarchar(100)  NULL ,  
 PhoneNumber nvarchar(100)  NULL ,  
 CreateBy nvarchar(50)  NULL ,  
 CreateDate datetime  NULL ,  
 RoleName nvarchar(100)  NULL ,  
 OrganizationName nvarchar(100)  NULL,  
 Comments nvarchar(max) NULL,  
 ContactReason nvarchar(max) NULL,  
 ContactAction nvarchar(max) NULL ,  
 ContactMethod nvarchar(max) NULL ,
 ContactMethodClassName NVARCHAR(255) NULL, 
 QuestionAnswer nvarchar(max) NULL  
)  

DECLARE @FinalResults TABLE  (
--CREATE TABLE #FinalResults (   
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 Type nvarchar(50)  NULL ,  
 Name nvarchar(50)  NULL ,  
 ID int  NULL ,  
 Description nvarchar(MAX)  NULL ,  
 TypeDescription nvarchar(MAX)  NULL ,  
 Company nvarchar(100)  NULL ,  
 TalkedTo nvarchar(100)  NULL ,  
 PhoneNumber nvarchar(100)  NULL ,  
 CreateBy nvarchar(50)  NULL ,  
 CreateDate datetime  NULL ,  
 RoleName nvarchar(100)  NULL ,  
 OrganizationName nvarchar(100)  NULL,  
 Comments nvarchar(max) NULL,  
 ContactReason nvarchar(max) NULL,  
 ContactAction nvarchar(max) NULL, 
 ContactMethod nvarchar(max) NULL , 
 ContactMethodClassName NVARCHAR(255) NULL, 
 QuestionAnswer nvarchar(max) NULL  
)   
  
DECLARE @InboundCallResult AS TABLE(ID INT)  
DECLARE @EmergencyAssistanceResult AS TABLE(ID INT)  
DECLARE @PurchaseOrderResult AS TABLE(ID INT)  
  
  
DECLARE @eventLogCount BIGINT  
DECLARE @contactLogCount BIGINT  
DECLARE @commentCount BIGINT  
SET @eventLogCount = 0  
SET @contactLogCount = 0  
SET @commentCount = 0  

  

DECLARE @PurchaseOrderEntityID INT  

DECLARE @VendorEntityID INT  
DECLARE @ContactLogEntityID INT  
  

SELECT @PurchaseOrderEntityID  = ID FROM dbo.Entity(NOLOCK) WHERE Name = 'PurchaseOrder'  
SELECT @VendorEntityID =ID from dbo.Entity(NOLOCK) WHERE Name = 'Vendor'  
SELECT @ContactLogEntityID = ID FROM dbo.Entity(NOLOCK) WHERE Name = 'ContactLog'  
  
  
DECLARE @idoc int  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter   
TypeOperator="-1"   
 ></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
DECLARE @tmpForWhereClause TABLE  
(  
TypeOperator INT NOT NULL,  
TypeValue nvarchar(50) NULL  
)  
  
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
 (CLL.EntityID = @VendorEntityID AND CLL.RecordID = @VendorID)  
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
NULL as RoleName,
NULL as OrganizationName,  
NULL AS Comments,  
NULL AS ContactReason,  
NULL AS [ContactAction],  
NULL AS [ContactMethod],
NULL AS [ContactMethodClassName],
NULL AS [QuestionAnswer]  
FROM EventLog(NOLOCK) EL  
JOIN Event(NOLOCK) E on E.ID = EL.EventID  
JOIN EventType(NOLOCK) ET on ET.ID = E.EventTypeID  
JOIN EventCategory(NOLOCK) EC on EC.ID = E.EventCategoryID  
JOIN EventLogLink(NOLOCK) ELL on ELL.EventLogID = EL.ID  
JOIN Entity(NOLOCK) EN ON EN.ID = ELL.EntityID  
WHERE  
E.IsShownOnScreen = 1 AND E.IsActive = 1   
AND (  

(ELL.EntityID = @VendorEntityID AND ELL.RecordID = @VendorID)  

)  
   
UNION ALL  
-- CONTACT LOGS  
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
 NULL as RoleName,  
 NULL as OrganizationName,  
 CL.Comments,    
 CR.Description AS ContactReason, 
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
	CPDV.QuestionAnswer               
 FROM ContactLog(NOLOCK) CL  
 JOIN ContactLogLink(NOLOCK) CLL ON CLL.ContactLogID = CL.ID  
 JOIN Entity(NOLOCK) EN ON EN.ID = CLL.EntityID  
 JOIN ContactType(NOLOCK) CT ON CT.ID = CL.ContactTypeID   
 JOIN ContactMethod (NOLOCK) CM ON CM.ID = CL.ContactMethodID
 JOIN ContactLogReason(NOLOCK) CLR ON CLR.ContactLogID = CL.ID  
 JOIN ContactReason(NOLOCK) CR ON CR.ID = CLR.ContactReasonID   
 LEFT JOIN #CustomProgramDynamicValues CPDV ON CPDV.ContactLogID = CL.ID  
 WHERE    
 (CLL.EntityID = @VendorEntityID AND CLL.RecordID = @VendorID)  
 
  
UNION ALL  
 SELECT  'Comment' as Type,   
 EN.Name, C.ID,   
 C.Description,  
 CMT.Description as TypeDescription,  
 Null as Company,  
 Null as Talkedto,  
 Null as Phonenumber,  
 C.CreateBy,   
 C.CreateDate,  
 NULL as RoleName,  
 NULL as OrganizationName,  
 NULL AS Comments,  
 NULL AS ContactReason,  
 NULL AS [ContactAction],  
 NULL AS [ContactMethod],
 NULL AS [ContactMethodClassName],
 NULL AS [QuestionAnswer]  
 FROM Comment(NOLOCK) C  
 JOIN Entity EN(NOLOCK) ON EN.ID = C.EntityID   
 LEFT JOIN CommentType(NOLOCK) CMT on CMT.ID = C.CommentTypeID
 WHERE   
 (C.EntityID = @VendorEntityID AND C.RecordID = @VendorID)  
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
 T.ContactMethod,
 T.ContactMethodClassName,
 T.QuestionAnswer  
FROM @tmpFinalResults T  
,@tmpForWhereClause TMP   
WHERE (   
 (   
  ( TMP.TypeOperator = -1 )    OR   
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
 
 
SELECT @eventLogCount = COUNT(*) FROM @tmpFinalResults WHERE [Type] = 'Event Log'  
SELECT @contactLogCount = COUNT(*) FROM @tmpFinalResults WHERE [Type] = 'Contact Log'  
SELECT @commentCount = COUNT(*) FROM @tmpFinalResults WHERE [Type] = 'Comment'  
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
  
  