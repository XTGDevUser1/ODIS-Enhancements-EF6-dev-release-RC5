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
 WHERE id = object_id(N'[dbo].[dms_queue_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_queue_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_queue_list] @userID = '67E7D483-51E8-4D9C-97B6-D8ABB6D87B4B', @sortColumn='RequestNumber',@sortOrder = 'DESC',@whereClauseXML = '<ROW><Filter StatusOperator="11" StatusValue="Manager"></Filter></ROW>'
-- EXEC [dbo].[dms_queue_list] @userID = '67E7D483-51E8-4D9C-97B6-D8ABB6D87B4B', @sortColumn='RequestNumber',@sortOrder = 'ASC',@whereClauseXML = '<ROW><Filter StatusValue="Manager"></Filter></ROW>'
-- EXEC [dbo].[dms_queue_list] @userID = '67E7D483-51E8-4D9C-97B6-D8ABB6D87B4B', @sortColumn='RequestNumber',@sortOrder = 'ASC',@whereClauseXML = '<ROW><Filter PONumberOperator="2" PONumberValue="8012956"></Filter></ROW>'
-- EXEC [dbo].[dms_queue_list] @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB', @sortColumn='RequestNumber',@sortOrder = 'ASC',@whereClauseXML = '<ROW><Filter MemberOperator="2" MemberValue="Reddy" StatusValue="RVTech"></Filter></ROW>'
-- EXEC [dbo].[dms_queue_list] @userID = '67E7D483-51E8-4D9C-97B6-D8ABB6D87B4B', @sortColumn='RequestNumber',@sortOrder = 'ASC', @whereClauseXML = '<ROW><Filter RequestNumberOperator="4" RequestNumberValue="4"></Filter></ROW>'
-- EXEC [dbo].[dms_queue_list] @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB', @sortColumn='RequestNumber',@sortOrder = 'ASC',@whereClauseXML = '<ROW><Filter StatusOperator="11" StatusValue="Manager"></Filter></ROW>'
-- EXEC [dbo].[dms_queue_list] @userID = '67E7D483-51E8-4D9C-97B6-D8ABB6D87B4B', @sortColumn='RequestNumber',@sortOrder = 'ASC',@whereClauseXML = '<ROW><Filter statusOperator="11" StatusValue="CHT" ></Filter></ROW>'
 CREATE PROCEDURE [dbo].[dms_queue_list](     
   @userID UNIQUEIDENTIFIER = NULL    
 , @whereClauseXML NVARCHAR(4000) = NULL     
 , @startInd Int = 1     
 , @endInd BIGINT = 5000     
 , @pageSize int = 100      
 , @sortColumn nvarchar(100)  = 'RequestNumber'     
 , @sortOrder nvarchar(100) = 'ASC'     
      
 )     
 AS     
 BEGIN     
      
SET NOCOUNT ON    
SET FMTONLY OFF    
  
DECLARE @intPriorityHours int = 12  
  
CREATE TABLE #FinalResultsFiltered (    
[Case] int NULL ,    
RequestNumber int NULL ,    
Client nvarchar(100) NULL ,    
FirstName nvarchar(50)  NULL ,      
LastName nvarchar(50)  NULL ,   
MiddleName   nvarchar(50)  NULL ,     
Suffix nvarchar(50)  NULL ,      
Prefix nvarchar(50)  NULL ,    
SubmittedOriginal DATETIME,   
SecondaryProductID INT NULL,     
ServiceType nvarchar(100) NULL ,    
[Status] nvarchar(100) NULL ,    
IsRedispatched BIT NULL,  
AssignedToUserID INT NULL,  
NextActionAssignedToUserID INT NULL,  
ClosedLoop nvarchar(100) NULL ,    
PONumber nvarchar(50) NULL ,    
ISPName nvarchar(255) NULL ,    
CreateBy nvarchar(100) NULL ,    
NextAction nvarchar(MAX) NULL,    
NextActionID INT NULL,    
ClosedLoopID INT NULL,    
ServiceTypeID INT NULL,    
MemberNumber NVARCHAR(50) NULL,    
PriorityID INT NULL,    
[Priority] NVARCHAR(255) NULL,     
ScheduledOriginal DATETIME NULL,  
-- KB: Added extra IDs  
ProgramName NVARCHAR(50) NULL,  
ProgramID INT NULL,  
MemberID INT NULL,  
StatusDateModified DATETIME NULL,  -- Added by Lakshmi - Queue Color  
PrioritySort INT NULL,             -- Added by Phani - TFS 442  
NextActionScheduledDate DATETIME NULL,     -- Added by Phani - TFS 442  
ScheduleDateSort DATETIME NULL  
)    
    
CREATE TABLE #FinalResultsFormatted (      
[Case] int NULL ,    
RequestNumber int NULL ,    
Client nvarchar(100) NULL ,    
Member nvarchar(max) NULL ,    
Submitted nvarchar(100) NULL ,    
SubmittedOriginal DATETIME,    
Elapsed NVARCHAR(10),    
ElapsedOriginal bigint,    
ServiceType nvarchar(100) NULL ,    
[Status] nvarchar(100) NULL ,   
--AssignedToUserID INT NULL,   
AssignedTo nvarchar(100) NULL ,    
ClosedLoop nvarchar(100) NULL ,    
PONumber int NULL ,    
ISPName nvarchar(255) NULL ,    
CreateBy nvarchar(100) NULL ,    
NextAction nvarchar(MAX) NULL,    
MemberNumber NVARCHAR(50) NULL,    
[Priority] NVARCHAR(255) NULL,    
[Scheduled] nvarchar(100) NULL,    
ScheduledOriginal DATETIME  NULL,  
-- KB: Added extra IDs  
ProgramName NVARCHAR(50) NULL,  
ProgramID INT NULL,  
MemberID INT NULL,  
StatusDateModified DATETIME NULL  -- Added by Lakshmi - Queue Color  
)    
  
CREATE TABLE #FinalResultsSorted (    
[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
[Case] int NULL ,    
RequestNumber int NULL ,    
Client nvarchar(100) NULL ,    
Member nvarchar(max) NULL ,    
Submitted nvarchar(100) NULL ,    
SubmittedOriginal DATETIME,    
Elapsed NVARCHAR(10),    
ElapsedOriginal bigint,    
ServiceType nvarchar(100) NULL ,    
[Status] nvarchar(100) NULL ,   
--AssignedToUserID INT NULL,   
AssignedTo nvarchar(100) NULL ,    
ClosedLoop nvarchar(100) NULL ,    
PONumber int NULL ,    
ISPName nvarchar(255) NULL ,    
CreateBy nvarchar(100) NULL ,    
NextAction nvarchar(MAX) NULL,    
MemberNumber NVARCHAR(50) NULL,    
[Priority] NVARCHAR(255) NULL,    
[Scheduled] nvarchar(100) NULL,    
ScheduledOriginal DATETIME NULL,  
ProgramName NVARCHAR(50) NULL,  
ProgramID INT NULL,  
MemberID INT NULL,  
StatusDateModified DATETIME NULL  -- Added by Lakshmi - Queue Color  
)  
    
--DECLARE @managerCount BIGINT = 0    
--DECLARE @dispatcherCount BIGINT = 0  
--DECLARE @TechCount BIGINT = 0   
--DECLARE @repaircount BIGINT = 0    
   
DECLARE @queueDisplayHours INT    
DECLARE @now DATETIME    
    
SET @now = GETDATE()   
    
SET @queueDisplayHours = 0    
SELECT @queueDisplayHours = CONVERT(INT,ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'QueueDisplayHours'    
    
DECLARE @idoc int    
IF @whereClauseXML IS NULL    
BEGIN    
SET @whereClauseXML = '<ROW><Filter    
CaseOperator="-1"    
RequestNumberOperator="-1"    
MemberOperator="-1"    
ServiceTypeOperator="-1"    
PONumberOperator="-1"    
ISPNameOperator="-1"    
CreateByOperator="-1"    
StatusOperator="-1"    
ClosedLoopOperator="-1"    
NextActionOperator="-1"    
AssignedToOperator="-1"  
ClientOperator="-1"     
></Filter></ROW>'    
END    
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML    
    
DECLARE @tmpForWhereClause TABLE    
(    
CaseOperator INT NOT NULL,    
CaseValue int NULL,    
RequestNumberOperator INT NOT NULL,    
RequestNumberValue int NULL,    
MemberOperator INT NOT NULL,    
MemberValue nvarchar(200) NULL,    
ServiceTypeOperator INT NOT NULL,    
ServiceTypeValue nvarchar(50) NULL,    
PONumberOperator INT NOT NULL,    
PONumberValue nvarchar(50) NULL,    
ISPNameOperator INT NOT NULL,    
ISPNameValue nvarchar(255) NULL,    
CreateByOperator INT NOT NULL,    
CreateByValue nvarchar(50) NULL,    
StatusOperator INT NOT NULL,    
StatusValue nvarchar(50) NULL,    
ClosedLoopOperator INT NOT NULL,    
ClosedLoopValue nvarchar(50) NULL,    
NextActionOperator INT NOT NULL,    
NextActionValue nvarchar(50) NULL,    
AssignedToOperator INT NOT NULL,    
AssignedToValue nvarchar(50) NULL,    
MemberNumberOperator INT NOT NULL,    
MemberNumberValue nvarchar(50) NULL,    
PriorityOperator INT NOT NULL,    
PriorityValue nvarchar(50) NULL,  
ClientOperator INT NOT NULL,    
ClientValue nvarchar(255) NULL    
)    
    
    
INSERT INTO @tmpForWhereClause    
SELECT    
ISNULL(CaseOperator,-1),    
CaseValue ,    
ISNULL(RequestNumberOperator,-1),    
RequestNumberValue ,    
ISNULL(MemberOperator,-1),    
MemberValue ,    
ISNULL(ServiceTypeOperator,-1),    
ServiceTypeValue ,    
ISNULL(PONumberOperator,-1),    
PONumberValue ,    
ISNULL(ISPNameOperator,-1),    
ISPNameValue ,    
ISNULL(CreateByOperator,-1),    
CreateByValue,    
ISNULL(StatusOperator,-1),    
StatusValue ,    
ISNULL(ClosedLoopOperator,-1),    
ClosedLoopValue,    
ISNULL(NextActionOperator,-1),    
NextActionValue,    
ISNULL(AssignedToOperator,-1),    
AssignedToValue,    
ISNULL(MemberNumberOperator,-1),    
MemberNumberValue,    
ISNULL(PriorityOperator,-1),    
PriorityValue,  
ISNULL(ClientOperator,-1),    
ClientValue     
    
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (    
CaseOperator INT,    
CaseValue int    
,RequestNumberOperator INT,    
RequestNumberValue int    
,MemberOperator INT,    
MemberValue nvarchar(200)    
,ServiceTypeOperator INT,    
ServiceTypeValue nvarchar(50)    
,PONumberOperator INT,    
PONumberValue nvarchar(50)    
,ISPNameOperator INT,    
ISPNameValue nvarchar(255)    
,CreateByOperator INT,    
CreateByValue nvarchar(50)    
,StatusOperator INT,    
StatusValue nvarchar(50),    
ClosedLoopOperator INT,    
ClosedLoopValue nvarchar(50),    
NextActionOperator INT,    
NextActionValue nvarchar(50),    
AssignedToOperator INT,    
AssignedToValue nvarchar(50),    
MemberNumberOperator INT,    
MemberNumberValue nvarchar(50),    
PriorityOperator INT,    
PriorityValue nvarchar(50),  
ClientOperator INT,    
ClientValue nvarchar(50)    
)    
  
DECLARE @CaseValue int    
DECLARE @RequestNumberValue int  
DECLARE @MemberValue nvarchar(200)  
DECLARE @ServiceTypeValue nvarchar(50)    
DECLARE @PONumberValue nvarchar(50)    
DECLARE @ISPNameValue nvarchar(255)    
DECLARE @CreateByValue nvarchar(50)  
--DECLARE @AssignedToUserIDValue INT    
DECLARE @StatusValue nvarchar(50)  
DECLARE @ClosedLoopValue nvarchar(50)  
DECLARE @NextActionValue nvarchar(50)  
DECLARE @AssignedToValue nvarchar(50)  
DECLARE @MemberNumberValue nvarchar(50)  
DECLARE @PriorityValue nvarchar(50)  
DECLARE @ClientValue nvarchar(50)  
DECLARE @isFHT  BIT = 0, @isCHT BIT = 0
  
DECLARE @serviceRequestEntityID INT  
DECLARE @fhtContactReasonID INT  
DECLARE @dispatchStatusID INT  
  
SET @serviceRequestEntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')  
SET @fhtContactReasonID = (SELECT ID FROM ContactReason WHERE Name = 'HumanTouch')  
SET @dispatchStatusID = (SELECT ID FROM ServiceRequestStatus WHERE Name = 'Dispatched')  
 
-- Human Touch
DECLARE @StartMins INT = 0   
DECLARE @EndMins INT = 0   
  

 SELECT @CaseValue = CaseValue,  
  @RequestNumberValue = RequestNumberValue,  
  @MemberValue = MemberValue,  
  @ServiceTypeValue = ServiceTypeValue,  
  @PONumberValue = PONumberValue,  
  @ISPNameValue = ISPNameValue,  
  @CreateByValue = CreateByValue,  
  @StatusValue = StatusValue,  
  @ClosedLoopValue = ClosedLoopValue,  
  @NextActionValue = NextActionValue,  
  @AssignedToValue = AssignedToValue,  
  @MemberNumberValue = MemberNumberValue,  
  @PriorityValue = PriorityValue,  
  @ClientValue = ClientValue  
 FROM @tmpForWhereClause  
    
    
DECLARE @tmpStatusInput TABLE    
(    
 StatusName NVARCHAR(100)    
)    
-- Ford Human Touch   
DECLARE @fhtCharIndex INT = -1  
SET @fhtCharIndex = CHARINDEX('FHT',@StatusValue,0)  
  
IF (@fhtCharIndex > 0)  
BEGIN  
 SET @StatusValue = REPLACE(@StatusValue,'FHT','')  
 SET @isFHT = 1  
 SELECT @StartMins = -1 * CONVERT(INT, ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'FordHumanTouchStartMins'
 SELECT @EndMins = -1 * CONVERT(INT, ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'FordHumanTouchEndMins'   

END  

-- CNET Human Touch
DECLARE @chtCharIndex INT = -1  
SET @chtCharIndex = CHARINDEX('CHT',@StatusValue,0)  
  
IF (@chtCharIndex > 0)  
BEGIN  
 SET @StatusValue = REPLACE(@StatusValue,'CHT','')  
 SET @isCHT = 1  
 -- CNET Human Touch 
 SELECT @StartMins = -1 * CONVERT(INT, ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'CNETHumanTouchStartMins'   
 SELECT @EndMins = -1 * CONVERT(INT, ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'CNETHumanTouchEndMins' 
END  

--DEBUG: PRINT @StartMins PRINT @EndMins
  
DECLARE @sql NVARCHAR(MAX) = ''  
    
INSERT INTO @tmpStatusInput    
SELECT Item FROM [dbo].[fnSplitString](@StatusValue,',')   
  
--select * from @tmpStatusInput   
  
  
--INSERT INTO @tmpStatusInput    
--SELECT StatusName + '^' FROM @tmpStatusInput    
  
IF (@isFHT = 1 OR @isCHT = 1)  
BEGIN   
 -- remove FHT from the StatusValue.   
 DECLARE @cnt INT = 0  
 SELECT @cnt = COUNT(*) FROM @tmpStatusInput   
 IF (@cnt = 0)  
 BEGIN  
  SET @StatusValue = NULL    
 END  
END  
  
    
-- For EF to generate proper classes    
IF @userID IS NULL    
BEGIN    
SELECT 0 AS TotalRows,    
F.[RowNum],    
F.[Case],    
F.RequestNumber,    
F.Client,    
F.Member,    
F.Submitted,    
    
F.Elapsed,    
    
F.ServiceType,    
F.[Status] ,   
--F.AssignedToUserID ,   
F.AssignedTo ,    
F.ClosedLoop ,    
F.PONumber ,    
    
F.ISPName ,    
F.CreateBy ,    
F.NextAction,    
F.MemberNumber,    
F.[Priority],   
F.ProgramName,   
F.ProgramID,  
F.MemberID,  
--@managerCount AS [ManagerCount],    
--@dispatcherCount AS [dispatcherCount],    
--@TechCount AS [TechCount],    
--@repaircount AS [repairCount],    
F.[Scheduled],  
F.ScheduledOriginal , -- Added by Lakshmi- Queue Color  
F.StatusDateModified  -- Added by Lakshmi  - Queue Color   
FROM #FinalResultsSorted F    
RETURN;    
END    
--------------------- BEGIN -----------------------------    
---- Create a temp variable or a CTE with the actual SQL search query ----------    
---- and use that CTE in the place of <table> in the following SQL statements ---    
--------------------- END -----------------------------    
-- LOGIC : BEGIN   
  
SELECT ProgramID, ClientID, ProgramName  
INTO #tmpGetProgramsForUser  
FROM dbo.fnc_GetProgramsForUser(@userID)  
  
SELECT DISTINCT U.id AS ID,R.RoleName AS NAME  
INTO #tmpUserDetails  
FROM [User] U  
JOIN aspnet_UsersInRoles UR  
ON U.aspnet_UserID = UR.UserId  
JOIN aspnet_Roles R  
ON R.RoleId = UR.RoleId  
WHERE R.RoleName in ('Manager','Dispatcher','RVTech','Repair')  
  
  
  
BEGIN  
 SET @sql = ' SELECT   '  
 SET @sql = @sql + '   DISTINCT   '  
 SET @sql = @sql + '   SR.CaseID AS [Case],   '  
 SET @sql = @sql + '   SR.ID AS [RequestNumber],   '  
 SET @sql = @sql + '   CL.Name AS [Client],   '  
 SET @sql = @sql + '   M.FirstName, '  
 SET @sql = @sql + '   M.LastName, '  
 SET @sql = @sql + '   M.MiddleName, '  
 SET @sql = @sql + '   M.Suffix, '  
 SET @sql = @sql + '   M.Prefix,      '  
 -- KB: Retain original values here for sorting  
 SET @sql = @sql + '   sr.CreateDate AS SubmittedOriginal, '  
 -- KB: Retain original values here for sorting   
 SET @sql = @sql + '   SR.SecondaryProductID, '  
 SET @sql = @sql + '   PC.Name AS [ServiceType],   '  
 SET @sql = @sql + '   SRS.Name As [Status], '  
 SET @sql = @sql + '   SR.IsRedispatched,     '  
 SET @sql = @sql + '   C.AssignedToUserID, '  
 SET @sql = @sql + '   SR.NextActionAssignedToUserID, '  
 SET @sql = @sql + '   CLS.[Description] AS [ClosedLoop],      '  
 SET @sql = @sql + '   0 AS [PONumber],   '  
 SET @sql = @sql + '   '''' AS [ISPName],   '  
 SET @sql = @sql + '   SR.CreateBy AS [CreateBy], '  
 --RH: Temporary fix until we remove Ford Tech from Next Action  
 SET @sql = @sql + '   CASE  '  
 SET @sql = @sql + '   WHEN NA.Description = ''Ford Tech'' THEN ''RV Tech'' '  
 SET @sql = @sql + '   ELSE COALESCE(NA.Description,'''')  '  
 SET @sql = @sql + '   END AS [NextAction],   '  
 /*1. SET @sql = @sql + ' NA.Description, '*/  
   
 SET @sql = @sql + '   CASE  '  
 SET @sql = @sql + '   WHEN SR.NextActionID = (SELECT ID FROM NextAction WHERE Name = ''FordTech'' AND IsActive = 1)  '  
 SET @sql = @sql + '    THEN (SELECT ID FROM NextAction WHERE Name = ''RVTech'') '  
 SET @sql = @sql + '   ELSE SR.NextActionID '   
 SET @sql = @sql + '   END AS NextActionID,   '  
 /*2. SET @sql = @sql + ' SR.NextActionID, '*/  
 --RH: See above '  
 SET @sql = @sql + '   SR.ClosedLoopStatusID as [ClosedLoopID],   '  
 SET @sql = @sql + '   SR.ProductCategoryID as [ServiceTypeID],   '  
 SET @sql = @sql + '   MS.MembershipNumber AS [MemberNumber],   '  
 SET @sql = @sql + '   SR.ServiceRequestPriorityID AS [PriorityID],   '  
   
 SET @sql = @sql + '   CASE  '  
 SET @sql = @sql + '   WHEN SRP.Name IN (''Normal'',''Low'') THEN '''' '  -- Do not display Normal and Low text '  
 SET @sql = @sql + '   ELSE SRP.Name  '  
 SET @sql = @sql + '   END AS [Priority],    '  
 /*3. SET @sql = @sql + ' SRP.Name, '*/  
 SET @sql = @sql + '   sr.NextActionScheduledDate AS ''ScheduledOriginal'',' -- This field is used for Queue Color '  

 IF (@isFHT = 0 AND @isCHT = 0)  
 BEGIN  
  SET @sql = @sql + ' P.ProgramName, '  
  SET @sql = @sql +  ' P.ProgramID, '  
 END  
 ELSE  
 BEGIN  
  SET @sql = @sql +  ' Prg.Name AS ProgramName, '  
  SET @sql = @sql +  ' Prg.ID AS ProgramID, '  
 END  
 SET @sql = @sql + '   M.ID AS MemberID, '  
 SET @sql = @sql + '   SR.StatusDateModified ,'  -- Added by Lakshmi -Queue Color  
   
 SET @sql = @sql + '   CASE  '  
 SET @sql = @sql + '   WHEN sr.ServiceRequestPriorityID = (SELECT ID FROM ServiceRequestPriority WHERE Name = ''Critical'') THEN 1 '  
 --RA 06/25/2014 - Added to push anything over 2 hrs to bottom of list  
 SET @sql = @sql + '   WHEN sr.NextActionScheduledDate <= DATEADD(HH,@intPriorityHours,getdate()) THEN 2  '  
 SET @sql = @sql + '   WHEN sr.NextActionScheduledDate IS NULL AND sr.ServiceRequestPriorityID = (SELECT ID FROM ServiceRequestPriority WHERE Name = ''High'') THEN 2 '  
 SET @sql = @sql + '   ELSE 3 '  
 SET @sql = @sql + '   END PrioritySort, '            -- Push critical and High to the top  
 /*4. SET @sql = @sql + ' sr.ServiceRequestPriorityID, ' */   
   
 SET @sql = @sql + '   SR.NextActionScheduledDate, '  
 SET @sql = @sql + '   CASE '  
 SET @sql = @sql + '   WHEN sr.NextActionScheduledDate <= DATEADD(HH,@intPriorityHours,getdate()) THEN sr.NextActionScheduledDate '  
 SET @sql = @sql + '   ELSE ''1/1/2099'' '  
 SET @sql = @sql + '   END ScheduleDateSort  '      -- Push items scheduled now to the top, then scheduled later, then null  
 /*5. SET @sql = @sql +  ' sr.NextActionScheduledDate '*/  
 SET @sql = @sql + ' FROM ServiceRequest SR WITH (NOLOCK) '  
 SET @sql = @sql + ' JOIN [ServiceRequestStatus] SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID   '  
 SET @sql = @sql + ' LEFT JOIN [ServiceRequestPriority] SRP WITH (NOLOCK) ON SR.ServiceRequestPriorityID = SRP.ID   '  
 SET @sql = @sql + ' JOIN [Case] C WITH (NOLOCK) ON C.ID = SR.CaseID'  
 SET @sql = @sql + ' LEFT JOIN [SourceSystem] SS WITH (NOLOCK) ON C.SourceSystemID = SS.ID'  
 SET @sql = @sql + ' JOIN [Member] M WITH (NOLOCK) ON C.MemberID = M.ID   '  
 SET @sql = @sql + ' JOIN Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID   '  
 SET @sql = @sql + ' LEFT JOIN [ProductCategory] PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID    '  
 IF (@isFHT = 0 AND @isCHT = 0)  
 BEGIN  
  SET @sql = @sql + ' JOIN #tmpGetProgramsForUser P ON C.ProgramID = P.ProgramID '  
  SET @sql = @sql + ' JOIN [Client] CL WITH (NOLOCK) ON P.ClientID = CL.ID '  
  SET @sql = @sql + ' LEFT JOIN [NextAction] NA WITH (NOLOCK) ON SR.NextActionID=NA.ID   '  
  SET @sql = @sql + ' LEFT JOIN (   '  
  SET @sql = @sql + ' SELECT ROW_NUMBER() OVER (PARTITION BY ELL.RecordID ORDER BY EL.CreateDate ASC) AS RowNum,   '  
  SET @sql = @sql + ' ELL.RecordID,   '  
  SET @sql = @sql + ' EL.EventID,   '  
  SET @sql = @sql + ' EL.CreateDate AS [Submitted]   '  
  SET @sql = @sql + ' FROM EventLog EL  WITH (NOLOCK)  '  
  SET @sql = @sql + ' JOIN EventLogLink ELL WITH (NOLOCK) ON EL.ID = ELL.EventLogID   '  
  SET @sql = @sql + ' JOIN [Event] E WITH (NOLOCK) ON EL.EventID = E.ID   '  
  SET @sql = @sql + ' JOIN [EventCategory] EC WITH (NOLOCK) ON E.EventCategoryID = EC.ID   '  
  SET @sql = @sql + ' WHERE ELL.EntityID = (SELECT ID FROM Entity WITH (NOLOCK) WHERE Name = ''ServiceRequest'')   '  
  SET @sql = @sql + ' AND E.Name = ''SubmittedForDispatch''   '  
  SET @sql = @sql + ' ) ELOG ON SR.ID = ELOG.RecordID AND ELOG.RowNum = 1   '  
  SET @sql = @sql + ' LEFT OUTER JOIN ClosedLoopStatus CLS WITH (NOLOCK) on CLS.ID=SR.ClosedLoopStatusID   '  
  SET @sql = @sql + ' WHERE 1=1'  
  SET @sql = @sql + ' AND ( (SS.Name = ''MemberMobile'' AND SRS.Name <> ''Entry'') OR (SS.Name <> ''MemberMobile'') ) '  
    
  IF @RequestNumberValue IS NOT NULL  
	  BEGIN  
	   SET @sql = @sql + ' AND SR.ID = @RequestNumberValue'  
	  END  
	  ELSE  
	  BEGIN  
	   SET @sql = @sql + ' AND (DATEDIFF(HH,SR.CreateDate,@now) <= @queueDisplayHours OR DATEDIFF(HH,SR.NextActionScheduledDate,@now) <= @queueDisplayHours)'  
	  END  
  END  
 ELSE  
 BEGIN  
  SET @sql = @sql + ' JOIN Program Prg on Prg.ID = C.ProgramID '   
  SET @sql = @sql + ' JOIN [Client] CL WITH (NOLOCK) ON Prg.ClientID = CL.ID '  
  SET @sql = @sql + ' JOIN PurchaseOrder PO on PO.ServiceRequestID = SR.ID   
        AND PO.PurchaseOrderStatusID IN   
        (SELECT ID FROM PurchaseOrderStatus WHERE Name IN (''Issued'', ''Issued-Paid'')) '  
  SET @sql = @sql + ' LEFT JOIN [NextAction] NA WITH (NOLOCK) ON SR.NextActionID=NA.ID  '  
  SET @sql = @sql + ' LEFT JOIN [VendorLocation] VL WITH (NOLOCK) ON PO.VendorLocationID = VL.ID  '  
  SET @sql = @sql + ' LEFT JOIN [Vendor] V WITH (NOLOCK) ON VL.VendorID = V.ID   '  
  SET @sql = @sql + ' LEFT OUTER JOIN ClosedLoopStatus CLS WITH (NOLOCK) on CLS.ID=SR.ClosedLoopStatusID '  
  SET @sql = @sql + ' LEFT OUTER JOIN ( '  
  SET @sql = @sql + ' SELECT CLL.RecordID'   
  SET @sql = @sql + ' FROM ContactLogLink cll  '  
  SET @sql = @sql + ' JOIN ContactLog cl ON cl.ID = cll.ContactLogID '  
  SET @sql = @sql + ' JOIN ContactLogReason clr ON clr.ContactLogID = cl.ID '  
  SET @sql = @sql + ' WHERE cll.EntityID = @serviceRequestEntityID '  
  SET @sql = @sql + ' AND clr.ContactReasonID = @fhtContactReasonID '  
  SET @sql = @sql + ' ) CLSR ON CLSR.RecordID = SR.ID '  
  IF @isFHT = 1
  BEGIN
	SET @sql = @sql + ' WHERE CL.Name = ''Ford'' '  
  END
  IF @isCHT = 1
  BEGIN
	SET @sql = @sql + ' WHERE CL.Name = ''Coach-Net'' '  

	-- TFS: 1252
	SET @sql = @sql + ' AND SR.PrimaryProductID IN ( '

	SET @sql = @sql + ' SELECT	P.ID  '
	SET @sql = @sql + ' FROM	Product P WITH (NOLOCK) '
	SET @sql = @sql + ' WHERE	(P.ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = ''Tow'') AND P.VehicleCategoryID = (SELECT ID FROM VehicleCategory WHERE Name = ''HeavyDuty'')) '
	SET @sql = @sql + ' OR		(P.ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = ''Tire'') AND P.VehicleCategoryID = (SELECT ID FROM VehicleCategory WHERE Name = ''HeavyDuty'')) '
	SET @sql = @sql + ' OR		(P.ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = ''Mobile'')) '

	SET @sql = @sql + ' ) '


  END
  SET @sql = @sql + ' AND  SR.ServiceRequestStatusID = @dispatchStatusID '  
  SET @sql = @sql + ' AND  @now between dateadd(mi,@StartMins,po.ETADate) and dateadd(mi,@EndMins,po.ETADate)    '  
  -- Filter out those SRs that has a contactlog record for HumanTouch.  
  SET @sql = @sql + ' AND  CLSR.RecordID IS NULL '  
 END  
-- IF   
DECLARE @countStatusInput INT = (SELECT COUNT(*) FROM @tmpStatusInput)    
DECLARE @countStatusInputManager INT = (SELECT COUNT(*) FROM @tmpStatusInput where StatusName = 'Manager')    
DECLARE @countStatusInputDispatcher INT = (SELECT COUNT(*) FROM @tmpStatusInput where StatusName = 'Dispatcher')    
DECLARE @countStatusInputRVTech INT = (SELECT COUNT(*) FROM @tmpStatusInput where StatusName = 'RVTech')    
DECLARE @countStatusInputRepair INT = (SELECT COUNT(*) FROM @tmpStatusInput where StatusName = 'Repair')    
IF (@countStatusInput > 0)  
BEGIN  
 SET @sql = @sql + ' AND ('  
END  
  
  
 IF EXISTS (SELECT StatusName FROM @tmpStatusInput WHERE StatusName LIKE '%Manager%')  
 BEGIN  
  SET @sql = @sql + ' (C.AssignedToUserID in (SELECT ID FROM [USER] WHERE FirstName = ''Manager'' AND LastName =''User'' )'  
  SET @sql = @sql + ' OR C.AssignedToUserID in (SELECT ID FROM #tmpUserDetails WHERE Name LIKE ''%Manager%'' ) '  
  SET @sql = @sql + ' OR SR.NextActionAssignedToUserID in (SELECT ID FROM [USER] WHERE FirstName = ''Manager'' AND LastName =''User'' )'  
  SET @sql = @sql + ' OR SR.NextActionAssignedToUserID in (SELECT ID FROM #tmpUserDetails WHERE Name LIKE ''%Manager%'' )   
  OR SRP.Name = ''Critical''   
  OR NA.name IN (''Credit Card Needed'', ''Follow-Up'', ''Escalation'',''Manager Approval'')) '  
    
 END  
 IF (@countStatusInputManager > 0  AND @countStatusInputDispatcher >0)  
 BEGIN  
  SET @sql = @sql + ' OR '  
 END  
   
 IF EXISTS (SELECT StatusName FROM @tmpStatusInput WHERE StatusName LIKE '%Dispatcher%')  
 BEGIN  
  SET @sql = @sql + ' ((C.AssignedToUserID in (SELECT ID FROM [USER] WHERE FirstName = ''Dispatch'' AND LastName =''User'' ) '  
  SET @sql = @sql + ' OR C.AssignedToUserID in (SELECT ID FROM #tmpUserDetails WHERE Name LIKE ''%Dispatch%'' ) '  
  SET @sql = @sql + ' OR SR.NextActionAssignedToUserID in (SELECT ID FROM [USER] WHERE FirstName = ''Dispatch'' AND LastName =''User'' ) '  
  SET @sql = @sql + ' OR SR.NextActionAssignedToUserID in (SELECT ID FROM #tmpUserDetails WHERE Name LIKE ''%Dispatcher%'' )   
					  OR NA.name IN (''Dispatch'', ''ReDispatch''))'  
  SET @sql = @sql + ' AND (sr.NextActionScheduledDate <= @now OR sr.NextActionScheduledDate IS NULL)'  
  SET @sql = @sql + ' AND srs.Name <> ''Entry'')'  
 END  
   
 IF ((@countStatusInputManager > 0  OR @countStatusInputDispatcher >0) AND @countStatusInputRVTech > 0)  
 BEGIN  
  SET @sql = @sql + ' OR '  
 END  
   
 IF EXISTS (SELECT StatusName FROM @tmpStatusInput WHERE StatusName LIKE '%RVTech%')  
 BEGIN  
  SET @sql = @sql + ' (C.AssignedToUserID in (SELECT ID FROM [USER] WHERE FirstName = ''Tech'' AND LastName =''User'' )'  
  SET @sql = @sql + ' OR C.AssignedToUserID in (SELECT ID FROM #tmpUserDetails WHERE Name LIKE ''%RVTech%'' )'  
  SET @sql = @sql + ' OR SR.NextActionAssignedToUserID in (SELECT ID FROM [USER] WHERE FirstName = ''Tech'' AND LastName =''User'' )'  
  SET @sql = @sql + ' OR SR.NextActionAssignedToUserID in (SELECT ID FROM #tmpUserDetails WHERE Name LIKE ''%RVTech%'' )  
  OR NA.name IN (''TechAssist'', ''DispatchMobileMechanic'', ''FindServiceLocation'') )'  
    
 END  
 IF ((@countStatusInputManager > 0  OR @countStatusInputDispatcher >0 OR @countStatusInputRVTech > 0) AND @countStatusInputRepair > 0)  
 BEGIN  
  SET @sql = @sql + ' OR '  
 END  
 IF EXISTS (SELECT StatusName FROM @tmpStatusInput WHERE StatusName LIKE '%Repair%')  
 BEGIN  
  SET @sql = @sql + ' ((NA.name =  ''RepairFollowUp''   
  AND SR.NextActionScheduledDate >= DATEADD(hh, -2, GetDate())))  '  
    
 END  
 IF (@countStatusInput > 0)  
BEGIN  
 SET @sql = @sql + ' ) '  
END  
 --IF EXISTS (SELECT StatusName FROM @tmpStatusInput WHERE StatusName LIKE '%Manager%' OR  
 --              StatusName LIKE '%Dispatcher%' OR  
 --              StatusName LIKE '%RVTech%' )  
 --BEGIN  
 SET @sql = @sql + ' ORDER BY Priority, SR.NextActionScheduledDate, SR.CreateDate '  
 --END  
   
 SET @sql = @sql + ' OPTION (RECOMPILE)'  
   
-- DEBUG: SELECT @sql
  
 IF (@isFHT = 0 AND @isCHT = 0)  
 BEGIN  
  INSERT INTO #FinalResultsFiltered  
  EXEC sp_executesql @sql, N'@intPriorityHours INT, @userID UNIQUEIDENTIFIER, @PONumberValue NVARCHAR(50), @RequestNumberValue INT, @now DATETIME, @queueDisplayHours INT',   
  @intPriorityHours,@userID,@PONumberValue,@RequestNumberValue, @now, @queueDisplayHours  
  
  
  --KB: IF user is searching by ponumber of isp, update filtered with those values.  
  IF (ISNULL(@PONumberValue,'') <> '' OR ISNULL ( @ISPNameValue,'') <> '')  
  BEGIN  
   ;WITH wPOISPValues AS  
   (  
    SELECT ROW_NUMBER() OVER (PARTITION BY PO.ServiceRequestID ORDER BY PO.CreateDate DESC) AS RowNum,      
       PO.ID,      
       PO.PurchaseOrderNumber,      
       PO.ServiceRequestID,      
       PO.VendorLocationID     
       FROM PurchaseOrder PO WITH (NOLOCK)       
       JOIN #FinalResultsFiltered F ON PO.ServiceRequestID = F.RequestNumber  
       WHERE PO.PurchaseOrderStatusID NOT IN   
         (SELECT ID FROM PurchaseOrderStatus WITH (NOLOCK) WHERE Name = 'Pending')   
   )  
    
   UPDATE #FinalResultsFiltered  
   SET PONumber = CONVERT(INT,W.PurchaseOrderNumber),  
    ISPName = V.Name   
   FROM #FinalResultsFiltered F  
   JOIN wPOISPValues W ON F.RequestNumber = W.ServiceRequestID AND W.RowNum = 1  
   JOIN VendorLocation VL WITH (NOLOCK) ON W.VendorLocationID = VL.ID  
   JOIN Vendor V WITH (NOLOCK) ON VL.VendorID = V.ID  
   
  END  
 END  
 ELSE  
 BEGIN  
 INSERT INTO #FinalResultsFiltered  
 EXEC sp_executesql @sql, N'@intPriorityHours INT, @serviceRequestEntityID INT, @fhtContactReasonID INT, @dispatchStatusID INT, @now DATETIME, @StartMins INT, @EndMins INT' ,  
 @intPriorityHours,  @serviceRequestEntityID, @fhtContactReasonID, @dispatchStatusID, @now, @StartMins, @EndMins  
 END  
END  
    
-- LOGIC : END     
  
SET @sql = ''  
SET @sql = ' SELECT   '  
SET @sql = @sql + ' T.[Case],   '  
SET @sql = @sql + ' T.RequestNumber,   '  
SET @sql = @sql + ' T.Client,   '  
--* CR : 1256 '  
SET @sql = @sql + ' REPLACE(RTRIM( '  
SET @sql = @sql + ' COALESCE(T.LastName,'''')+   '  
SET @sql = @sql + ' COALESCE('' '' + CASE WHEN T.Suffix = '''' THEN NULL ELSE T.Suffix END,'''')+   '  
SET @sql = @sql + ' COALESCE('', ''+ CASE WHEN T.FirstName = '''' THEN NULL ELSE T.FirstName END,'''' )+ '  
SET @sql = @sql + ' COALESCE('' '' + LEFT(T.MiddleName,1),'''') '  
SET @sql = @sql + ' ),'''','''') AS [Member], '  
SET @sql = @sql + ' CONVERT(VARCHAR(3),DATENAME(MONTH,T.SubmittedOriginal)) + SPACE(1)+    '  
SET @sql = @sql + ' +''''+CONVERT (VARCHAR(2),DATEPART(dd,T.SubmittedOriginal)) + SPACE(1) +    '  
SET @sql = @sql + ' +''''+REPLACE(REPLACE(RIGHT(''0''+LTRIM(RIGHT(CONVERT(VARCHAR,T.SubmittedOriginal,100),7)),7),''AM'',''AM''),''PM'',''PM'')as [Submitted],  '  
SET @sql = @sql + ' T.SubmittedOriginal,   '  
SET @sql = @sql + ' CONVERT(VARCHAR(6),DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())/3600)+ '':''   '  
SET @sql = @sql + ' + RIGHT(''0'' + CONVERT(VARCHAR(2),(DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())%3600)/60),2) AS [Elapsed],   '  
SET @sql = @sql + ' DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())/3600 + ((DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())%3600)/60) AS ElapsedOriginal,     '  
SET @sql = @sql + ' CASE   '  
SET @sql = @sql + ' WHEN T.SecondaryProductID IS NOT NULL   '  
SET @sql = @sql + ' THEN T.ServiceType + ''+''   '  
SET @sql = @sql + ' ELSE T.ServiceType  '  
SET @sql = @sql + ' END AS ServiceType, '  
SET @sql = @sql + ' CASE   '  
SET @sql = @sql + ' WHEN T.IsRedispatched =1 then T.[Status] + ''^''   '  
SET @sql = @sql + ' ELSE T.[Status]   '  
SET @sql = @sql + ' END AS [Status], '  
--SET @sql = @sql + ' T.AssignedToUserID,'  
SET @sql = @sql + ' CASE WHEN T.AssignedToUserID IS NOT NULL   '  
SET @sql = @sql + ' THEN ''*'' + ISNULL(ASU.FirstName,'''') + '' '' + ISNULL(ASU.LastName,'''')   '  
SET @sql = @sql + ' ELSE ISNULL(SASU.FirstName,'''') + '' '' + ISNULL(SASU.LastName,'''')   '  
SET @sql = @sql + ' END AS [AssignedTo],     '  
SET @sql = @sql + ' T.ClosedLoop,   '  
SET @sql = @sql + ' T.PONumber,   '  
SET @sql = @sql + ' T.ISPName,   '  
SET @sql = @sql + ' T.CreateBy,   '  
SET @sql = @sql + ' T.NextAction,   '  
SET @sql = @sql + ' T.MemberNumber,   '  
SET @sql = @sql + ' T.[Priority],   '  
SET @sql = @sql + ' CONVERT(VARCHAR(3),DATENAME(MONTH,T.ScheduledOriginal)) + SPACE(1)+    '  
SET @sql = @sql + ' +''''+CONVERT (VARCHAR(2),DATEPART(dd,T.ScheduledOriginal)) + SPACE(1) +    '  
SET @sql = @sql + ' +''''+REPLACE(REPLACE(RIGHT(''0''+LTRIM(RIGHT(CONVERT(VARCHAR,T.ScheduledOriginal,100),7)),7),''AM'',''AM''),''PM'',''PM'')as [Scheduled], '  
SET @sql = @sql + ' T.[ScheduledOriginal],  ' --* This field is used for Queue Color  
SET @sql = @sql + ' T.ProgramName, '  
SET @sql = @sql + ' T.ProgramID, '  
SET @sql = @sql + ' T.MemberID, '  
SET @sql = @sql + ' T.StatusDateModified '    --* Added by Lakshmi - Queue Color  
SET @sql = @sql + ' FROM #FinalResultsFiltered T '  
SET @sql = @sql + ' LEFT JOIN [User] ASU WITH (NOLOCK) ON T.AssignedToUserID = ASU.ID   '  
SET @sql = @sql + ' LEFT JOIN [User] SASU WITH (NOLOCK) ON T.NextActionAssignedToUserID = SASU.ID   '  
SET @sql = @sql + ' WHERE 1=1 '  
  
IF @CaseValue IS NOT NULL  
BEGIN  
SET @sql = @sql + ' AND @CaseValue = T.[Case] '  
END  
  
IF @RequestNumberValue IS NOT NULL  
BEGIN  
SET @sql = @sql + ' AND @RequestNumberValue = T.RequestNumber '  
END  
  
IF @ServiceTypeValue IS NOT NULL  
BEGIN  
SET @sql = @sql + ' AND @ServiceTypeValue = T.ServiceTypeID '  
END  
  
IF @ISPNameValue IS NOT NULL  
BEGIN  
SET @sql = @sql + ' AND  T.ISPName LIKE ''%'' + @ISPNameValue + ''%'' '  
END  
  
IF @CreateByValue IS NOT NULL  
BEGIN  
SET @sql = @sql + ' AND T.CreateBy LIKE ''%'' + @CreateByValue + ''%'' '  
END  
  
IF @ClosedLoopValue IS NOT NULL  
BEGIN  
SET @sql = @sql + ' AND T.ClosedLoopID = @ClosedLoopValue '  
END  
  
IF @NextActionValue IS NOT NULL  
BEGIN  
SET @sql = @sql + ' AND T.NextActionID = @NextActionValue '  
END  
  
IF @MemberNumberValue IS NOT NULL  
BEGIN  
SET @sql = @sql + ' AND @MemberNumberValue = T.MemberNumber '  
END  
  
IF @PriorityValue IS NOT NULL  
BEGIN  
SET @sql = @sql + ' AND @PriorityValue = T.PriorityID '  
END  
  
IF ISNULL(@ClientValue,'') <> ''  
BEGIN  
SET @sql = @sql + ' AND @ClientValue = T.Client '  
END  
  
IF @PONumberValue IS NOT NULL  
BEGIN  
SET @sql = @sql + ' AND @PONumberValue = T.PONumber  '  
END  
  
  
--IF @StatusValue IS NOT NULL  
--BEGIN  
--SET @sql = @sql + ' T.[Status] IN ( SELECT T.StatusName FROM @tmpStatusInput T )  '  
--END  
  
SET @sql = @sql + ' ORDER BY T.PrioritySort,T.ScheduleDateSort, T.RequestNumber DESC '    
SET @sql = @sql + ' OPTION (RECOMPILE)'  
    
INSERT INTO #FinalResultsFormatted    
EXEC sp_executesql @sql, N'@CaseValue INT, @RequestNumberValue INT,@ServiceTypeValue NVARCHAR(50), @ISPNameValue NVARCHAR(255), @CreateByValue NVARCHAR(50), @ClosedLoopValue NVARCHAR(50), @NextActionValue NVARCHAR(50), @MemberNumberValue NVARCHAR(50), @PriorityValue NVARCHAR(50),@ClientValue NVARCHAR(50), @PONumberValue NVARCHAR(50), @MemberValue NVARCHAR(200), @AssignedToValue NVARCHAR(50)',   
       @CaseValue,  
       @RequestNumberValue,  
       @ServiceTypeValue,  
       @ISPNameValue,  
       @CreateByValue,  
       @ClosedLoopValue,  
       @NextActionValue,  
       @MemberNumberValue,  
       @PriorityValue,  
       @ClientValue,  
       @PONumberValue,  
       @MemberValue,  
       @AssignedToValue  
        
         
--SELECT  'End Formatting', GETDATE()  
/*SELECT    
T.[Case],    
T.RequestNumber,    
T.Client,    
-- CR : 1256  
REPLACE(RTRIM(  
  COALESCE(T.LastName,'')+    
  COALESCE(' ' + CASE WHEN T.Suffix = '' THEN NULL ELSE T.Suffix END,'')+    
  COALESCE(', '+ CASE WHEN T.FirstName = '' THEN NULL ELSE T.FirstName END,'' )+  
  COALESCE(' ' + LEFT(T.MiddleName,1),'')  
  ),'','') AS [Member],  
--REPLACE(RTRIM(    
--  COALESCE(''+T.LastName,'')+    
--  COALESCE(''+ space(1)+ T.Suffix,'')+    
--  COALESCE(','+  space(1) + T.FirstName,'' )+    
--  COALESCE(''+ space(1) + left(T.MiddleName,1),'')    
--  ),'','') AS [Member],    
CONVERT(VARCHAR(3),DATENAME(MONTH,T.SubmittedOriginal)) + SPACE(1)+     
+''+CONVERT (VARCHAR(2),DATEPART(dd,T.SubmittedOriginal)) + SPACE(1) +     
+''+REPLACE(REPLACE(RIGHT('0'+LTRIM(RIGHT(CONVERT(VARCHAR,T.SubmittedOriginal,100),7)),7),'AM','AM'),'PM','PM')as [Submitted],   
T.SubmittedOriginal,    
CONVERT(VARCHAR(6),DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())/3600)+':'    
  +RIGHT('0'+CONVERT(VARCHAR(2),(DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())%3600)/60),2) AS [Elapsed],    
DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())/3600 + ((DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())%3600)/60) AS ElapsedOriginal,      
CASE    
 WHEN T.SecondaryProductID IS NOT NULL    
 THEN T.ServiceType + '+'    
 ELSE T.ServiceType   
END AS ServiceType,  
CASE    
 WHEN T.IsRedispatched =1 then T.[Status] + '^'    
 ELSE T.[Status]    
END AS [Status],  
CASE WHEN T.AssignedToUserID IS NOT NULL    
 THEN '*' + ISNULL(ASU.FirstName,'') + ' ' + ISNULL(ASU.LastName,'')    
 ELSE ISNULL(SASU.FirstName,'') + ' ' + ISNULL(SASU.LastName,'')    
END AS [AssignedTo],      
T.ClosedLoop,    
T.PONumber,    
T.ISPName,    
T.CreateBy,    
T.NextAction,    
T.MemberNumber,    
T.[Priority],    
CONVERT(VARCHAR(3),DATENAME(MONTH,T.ScheduledOriginal)) + SPACE(1)+     
  +''+CONVERT (VARCHAR(2),DATEPART(dd,T.ScheduledOriginal)) + SPACE(1) +     
  +''+REPLACE(REPLACE(RIGHT('0'+LTRIM(RIGHT(CONVERT(VARCHAR,T.ScheduledOriginal,100),7)),7),'AM','AM'),'PM','PM')as [Scheduled],  
T.[ScheduledOriginal],  -- This field is used for Queue Color  
T.ProgramName,  
T.ProgramID,  
T.MemberID,  
T.StatusDateModified     --Added by Lakshmi - Queue Color  
FROM #FinalResultsFiltered T  
LEFT JOIN [User] ASU WITH (NOLOCK) ON T.AssignedToUserID = ASU.ID    
LEFT JOIN [User] SASU WITH (NOLOCK) ON T.NextActionAssignedToUserID = SASU.ID    
WHERE (  
  ( @CaseValue IS NULL OR @CaseValue = T.[Case])  
  AND  
  ( @RequestNumberValue IS NULL OR @RequestNumberValue = T.RequestNumber)  
  AND  
  ( @ServiceTypeValue IS NULL OR @ServiceTypeValue = T.ServiceTypeID)  
  AND  
  ( @ISPNameValue IS NULL OR T.ISPName LIKE '%' + @ISPNameValue + '%')  
  AND  
  ( @CreateByValue IS NULL OR T.CreateBy LIKE '%' + @CreateByValue + '%')  
    
  AND  
  ( @ClosedLoopValue IS NULL OR T.ClosedLoopID = @ClosedLoopValue)  
  AND  
  ( @NextActionValue IS NULL OR T.NextActionID = @NextActionValue)  
  AND  
  ( @MemberNumberValue IS NULL OR @MemberNumberValue = T.MemberNumber)  
  AND   
  ( @PriorityValue IS NULL OR @PriorityValue = T.PriorityID)   
  AND   
  ( @PONumberValue IS NULL OR @PONumberValue = T.PONumber)    
 )  
ORDER BY T.PrioritySort,T.ScheduleDateSort, T.RequestNumber DESC  
  
*/  
  
INSERT INTO #FinalResultsSorted  
SELECT T.[Case],    
  T.RequestNumber,    
  T.Client,    
  T.Member,    
  T.Submitted,    
  T.SubmittedOriginal,    
  T.Elapsed,    
  T.ElapsedOriginal,    
  T.ServiceType,    
  T.[Status],    
  --T.AssignedToUserID,  
  T.AssignedTo,    
  T.ClosedLoop,    
  T.PONumber,    
  T.ISPName,    
  T.CreateBy,    
  T.NextAction,    
  T.MemberNumber,    
  T.[Priority],    
  T.[Scheduled],    
  T.ScheduledOriginal,  
  T.ProgramName,  
  T.ProgramID,  
  T.MemberID,  
  T.StatusDateModified    --Added by Lakshmi  
FROM #FinalResultsFormatted T  
WHERE (   
   ( @MemberValue IS NULL OR  T.Member LIKE '%' + @MemberValue  + '%')  
   AND  
   ( @AssignedToValue IS NULL OR T.AssignedTo LIKE '%' + @AssignedToValue + '%' )  
   --AND  
   --( @StatusValue IS NULL OR T.[Status] IN (         
   --        SELECT T.StatusName FROM @tmpStatusInput T      
   --        )    
   --       )  
  )  
  
ORDER BY    
CASE WHEN @sortColumn = 'Case' AND @sortOrder = 'ASC'    
THEN T.[Case] END ASC,    
CASE WHEN @sortColumn = 'Case' AND @sortOrder = 'DESC'    
THEN T.[Case] END DESC ,    
    
CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'ASC'    
THEN T.RequestNumber END ASC,    
CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'DESC'    
THEN T.RequestNumber END DESC ,    
    
CASE WHEN @sortColumn = 'Client' AND @sortOrder = 'ASC'    
THEN T.Client END ASC,    
CASE WHEN @sortColumn = 'Client' AND @sortOrder = 'DESC'    
THEN T.Client END DESC ,    
    
CASE WHEN @sortColumn = 'Member' AND @sortOrder = 'ASC'    
THEN T.Member END ASC,    
CASE WHEN @sortColumn = 'Member' AND @sortOrder = 'DESC'    
THEN T.Member END DESC ,    
    
CASE WHEN @sortColumn = 'Submitted' AND @sortOrder = 'ASC'    
THEN T.SubmittedOriginal END ASC,    
CASE WHEN @sortColumn = 'Submitted' AND @sortOrder = 'DESC'    
THEN T.SubmittedOriginal END DESC ,    
    
CASE WHEN @sortColumn = 'FormattedElapsedTime' AND @sortOrder = 'ASC'    
THEN T.ElapsedOriginal END ASC,    
CASE WHEN @sortColumn = 'FormattedElapsedTime' AND @sortOrder = 'DESC'    
THEN T.ElapsedOriginal END DESC ,    
    
CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'ASC'    
THEN T.ServiceType END ASC,    
CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'DESC'    
THEN T.ServiceType END DESC ,    
    
CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'    
THEN T.[Status] END ASC,    
CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'    
THEN T.[Status] END DESC ,   
  
   
CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'ASC'    
THEN T.AssignedTo END ASC,    
CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'DESC'    
THEN T.AssignedTo END DESC ,    
    
CASE WHEN @sortColumn = 'ClosedLoop' AND @sortOrder = 'ASC'    
THEN T.ClosedLoop END ASC,    
CASE WHEN @sortColumn = 'ClosedLoop' AND @sortOrder = 'DESC'    
THEN T.ClosedLoop END DESC ,    
    
CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'    
THEN T.PONumber END ASC,    
CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'    
THEN T.PONumber END DESC ,    
    
CASE WHEN @sortColumn = 'ISPName' AND @sortOrder = 'ASC'    
THEN T.ISPName END ASC,    
CASE WHEN @sortColumn = 'ISPName' AND @sortOrder = 'DESC'    
THEN T.ISPName END DESC ,    
    
CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'    
THEN T.CreateBy END ASC,    
CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'    
THEN T.CreateBy END DESC,    
    
CASE WHEN @sortColumn = 'Scheduled' AND @sortOrder = 'ASC'    
THEN T.ScheduledOriginal END ASC,    
CASE WHEN @sortColumn = 'Scheduled' AND @sortOrder = 'DESC'    
THEN T.ScheduledOriginal END DESC,    
  
CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'ASC'    
THEN T.NextAction END ASC,    
CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'DESC'    
THEN T.NextAction END DESC     
    
DECLARE @count INT    
SET @count = 0    
SELECT @count = MAX(RowNum) FROM #FinalResultsSorted    
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
  
--select * from #FinalResultsFiltered  
--select * from #FinalResultsSorted  
--select * from #FinalResultsFormatted  
  
--SELECT F.AssignedToUserID AS ID, U.Name, COUNT(*) AS [Total]  
--INTO #tmpStatusSummary    
--FROM #FinalResultsSorted F  
--JOIN #tmpUserDetails U  
--ON F.AssignedToUserID = U.ID  
--GROUP BY F.AssignedToUserID, U.Name  
  
  
--SELECT @managerCount = [Total] FROM #tmpStatusSummary WHERE Name = 'Manager'  
--SELECT @dispatcherCount = [Total] FROM #tmpStatusSummary WHERE Name = 'Dispatcher'  
--SELECT @TechCount = [Total] FROM #tmpStatusSummary WHERE Name = 'RVTech'    
--SELECT @repaircount = [Total] FROM #tmpStatusSummary WHERE Name = 'Repair'  
   
  
UPDATE #FinalResultsSorted SET Elapsed = NULL WHERE [Status] IN ('Complete','Complete^','Cancelled','Cancelled^')    
    
SELECT @count AS TotalRows,     
F.[RowNum],    
F.[Case],    
F.RequestNumber,    
F.Client,    
F.Member,    
F.Submitted,    
    
F.Elapsed,    
    
F.ServiceType,    
F.[Status] ,    
F.AssignedTo ,    
F.ClosedLoop ,    
F.PONumber ,    
    
F.ISPName ,    
F.CreateBy ,    
F.NextAction,    
F.MemberNumber,    
F.[Priority],    
    
  --ISNULL(@managerCount,0) AS [ManagerCount],    
  --ISNULL(@dispatcherCount,0) AS [DispatcherCount],    
  --ISNULL(@TechCount,0) AS [TechCount],    
  --ISNULL(@repaircount,0) AS [RepairCount],    
   
  F.[Scheduled],  
  F.ProgramName,  
  F.ProgramID,  
  F.MemberID,  
  F.StatusDateModified,    --Added by Lakshmi - Queue Color  
  F.ScheduledOriginal    --Added by Lakshmi - Queue Color  
  FROM #FinalResultsSorted F    
WHERE F.RowNum BETWEEN @startInd AND @endInd    
    
DROP TABLE #FinalResultsFiltered    
DROP TABLE #FinalResultsFormatted  
DROP TABLE #FinalResultsSorted  
--DROP TABLE #tmpStatusSummary   
DROP TABLE #tmpGetProgramsForUser   
    
    
END
