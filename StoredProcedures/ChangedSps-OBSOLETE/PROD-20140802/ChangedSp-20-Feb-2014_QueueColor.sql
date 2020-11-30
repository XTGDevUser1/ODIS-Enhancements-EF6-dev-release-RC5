

---*********** Queue Color Enhancement DB Scripts *********----

-- MODIFY IN EXISTING STORED PROCEDURE "[dbo].[dms_queue_list]" ***---

-- ** MODIFICATION CAN BE FOUND IN BELOW STORED PROCEDURE BY COMMENTED LINE "Added by Lakshmi - Queue Color". ***---

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_queue_list]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_queue_list] 
 END 
 GO  

 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

 CREATE PROCEDURE [dbo].[dms_queue_list](   
   @userID UNIQUEIDENTIFIER = NULL  
 , @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 100    
 , @sortColumn nvarchar(100)  = ''   
 , @sortOrder nvarchar(100) = 'ASC'   
    
 )   
 AS   
 BEGIN   
    
SET NOCOUNT ON  
SET FMTONLY OFF  

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
StatusDateModified DATETIME NULL  -- Added by Lakshmi - Queue Color
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
-- KB: Added extra IDs
ProgramName NVARCHAR(50) NULL,
ProgramID INT NULL,
MemberID INT NULL,
StatusDateModified DATETIME NULL  -- Added by Lakshmi - Queue Color
)
  
DECLARE @openedCount BIGINT = 0  
DECLARE @submittedCount BIGINT = 0  
  
DECLARE @dispatchedCount BIGINT = 0  
--  
DECLARE @completecount BIGINT = 0  
DECLARE @cancelledcount BIGINT = 0  
  
--DECLARE @scheduledCount BIGINT = 0  
  
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
PriorityValue nvarchar(50) NULL  
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
PriorityValue  
  
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
PriorityValue nvarchar(50)  
)  

DECLARE @CaseValue int  
DECLARE @RequestNumberValue int
DECLARE @MemberValue nvarchar(200)
DECLARE @ServiceTypeValue nvarchar(50)  
DECLARE @PONumberValue nvarchar(50)  
DECLARE @ISPNameValue nvarchar(255)  
DECLARE @CreateByValue nvarchar(50)  
DECLARE @StatusValue nvarchar(50)
DECLARE @ClosedLoopValue nvarchar(50)
DECLARE @NextActionValue nvarchar(50)
DECLARE @AssignedToValue nvarchar(50)
DECLARE @MemberNumberValue nvarchar(50)
DECLARE @PriorityValue nvarchar(50)
DECLARE @isFHT  BIT = 0

DECLARE @serviceRequestEntityID INT
DECLARE @fhtContactReasonID INT
DECLARE @dispatchStatusID INT

SET @serviceRequestEntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
SET @fhtContactReasonID = (SELECT ID FROM ContactReason WHERE Name = 'HumanTouch')
SET @dispatchStatusID = (SELECT ID FROM ServiceRequestStatus WHERE Name = 'Dispatched')

DECLARE @StartMins INT = 0 
SELECT @StartMins = -1 * CONVERT(INT,ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'FordHumanTouchStartMins' 

DECLARE @EndMins INT = 0 
SELECT @EndMins = -1 * CONVERT(INT,ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'FordHumanTouchEndMins' 

-- DEBUG:
--SELECT @StartMins, @EndMins

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
		@PriorityValue = PriorityValue
 FROM	@tmpForWhereClause
  
-- Extract the status values.  
  
DECLARE @tmpStatusInput TABLE  
(  
 StatusName NVARCHAR(100)  
)  
 
DECLARE @fhtCharIndex INT = -1
SET @fhtCharIndex = CHARINDEX('FHT',@StatusValue,0)

IF (@fhtCharIndex > 0)
BEGIN
	SET @StatusValue = REPLACE(@StatusValue,'FHT','')
	SET @isFHT = 1
END


  
INSERT INTO @tmpStatusInput  
SELECT Item FROM [dbo].[fnSplitString](@StatusValue,',')  
  
  
-- Include StatusNames with '^' suffix.  
INSERT INTO @tmpStatusInput  
SELECT StatusName + '^' FROM @tmpStatusInput  

-- CR : 1244 - FHT
IF (@isFHT = 1)
BEGIN	
	-- remove FHT from the StatusValue.	
	DECLARE @cnt INT = 0
	SELECT @cnt = COUNT(*) FROM @tmpStatusInput	
	IF (@cnt = 0)
	BEGIN
		SET @StatusValue = NULL		
	END
END

  
--DEBUG: SELECT * FROM @tmpStatusInput  
  
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
@openedCount AS [OpenedCount],  
@submittedCount AS [SubmittedCount],  
@cancelledcount AS [CancelledCount],  
@dispatchedCount AS [DispatchedCount],  
@completecount AS [CompleteCount],  
F.[Scheduled],
F.ScheduledOriginal ,	-- Added by Lakshmi- Queue Color
F.StatusDateModified  -- Added by Lakshmi  - Queue Color 
FROM #FinalResultsSorted F  
RETURN;  
END  
--------------------- BEGIN -----------------------------  
---- Create a temp variable or a CTE with the actual SQL search query ----------  
---- and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
-- LOGIC : BEGIN 

IF ( @isFHT = 0 )
BEGIN 
	
	INSERT INTO #FinalResultsFiltered
	SELECT  
			  DISTINCT  
			  SR.CaseID AS [Case],  
			  SR.ID AS [RequestNumber],  
			  CL.Name AS [Client],  
			  M.FirstName,
			  M.LastName,
			  M.MiddleName,
			  M.Suffix,
			  M.Prefix,     
			-- KB: Retain original values here for sorting  
			  sr.CreateDate AS SubmittedOriginal,
			-- KB: Retain original values here for sorting   
			  SR.SecondaryProductID,
			  PC.Name AS [ServiceType],  
			  SRS.Name As [Status],
			  SR.IsRedispatched,    
			  C.AssignedToUserID,
			  SR.NextActionAssignedToUserID,
			  CLS.[Description] AS [ClosedLoop],     
			  CONVERT(int,PO.PurchaseOrderNumber) AS [PONumber],  
			  V.Name AS [ISPName],  
			  SR.CreateBy AS [CreateBy],  
			  COALESCE(NA.Description,'') AS [NextAction],  
			  SR.NextActionID,  
			  SR.ClosedLoopStatusID as [ClosedLoopID],  
			  SR.ProductCategoryID as [ServiceTypeID],  
			  MS.MembershipNumber AS [MemberNumber],  
			  SR.ServiceRequestPriorityID AS [PriorityID],  
			  SRP.Name AS [Priority],   
			  sr.NextActionScheduledDate AS 'ScheduledOriginal', -- This field is used for Queue Color
			  P.ProgramName,
			  P.ProgramID,
			  M.ID AS MemberID,
			  SR.StatusDateModified			-- Added by Lakshmi	-Queue Color
	FROM [Case] C WITH (NOLOCK)
	JOIN [ServiceRequest] SR WITH (NOLOCK) ON C.ID = SR.CaseID  
	JOIN [ServiceRequestStatus] SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID  
	LEFT JOIN [ServiceRequestPriority] SRP WITH (NOLOCK) ON SR.ServiceRequestPriorityID = SRP.ID  
	JOIN dbo.fnc_GetProgramsForUser(@userID) P ON C.ProgramID = P.ProgramID  
	JOIN [Client] CL WITH (NOLOCK) ON P.ClientID = CL.ID  
	JOIN [Member] M WITH (NOLOCK) ON C.MemberID = M.ID  
	JOIN Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID  
	LEFT JOIN [ProductCategory] PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID  	
	LEFT JOIN (  
	SELECT ROW_NUMBER() OVER (PARTITION BY ServiceRequestID ORDER BY CreateDate DESC) AS RowNum,  
	ID,  
	PurchaseOrderNumber,  
	ServiceRequestID,  
	VendorLocationID   
	FROM PurchaseOrder WITH (NOLOCK)   
	WHERE --IsActive = 1 AND  
	PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WITH (NOLOCK) WHERE Name in ('Pending'))   
	AND (@PONumberValue IS NULL OR @PONumberValue = PurchaseOrderNumber)  
	) PO ON SR.ID = PO.ServiceRequestID AND PO.RowNum = 1  
	LEFT JOIN [NextAction] NA WITH (NOLOCK) ON SR.NextActionID=NA.ID  
	LEFT JOIN [VendorLocation] VL WITH (NOLOCK) ON PO.VendorLocationID = VL.ID  
	LEFT JOIN [Vendor] V WITH (NOLOCK) ON VL.VendorID = V.ID  
	LEFT JOIN (  
	SELECT ROW_NUMBER() OVER (PARTITION BY ELL.RecordID ORDER BY EL.CreateDate ASC) AS RowNum,  
	ELL.RecordID,  
	EL.EventID,  
	EL.CreateDate AS [Submitted]  
	FROM EventLog EL  WITH (NOLOCK) 
	JOIN EventLogLink ELL WITH (NOLOCK) ON EL.ID = ELL.EventLogID  
	JOIN [Event] E WITH (NOLOCK) ON EL.EventID = E.ID  
	JOIN [EventCategory] EC WITH (NOLOCK) ON E.EventCategoryID = EC.ID  
	WHERE ELL.EntityID = (SELECT ID FROM Entity WITH (NOLOCK) WHERE Name = 'ServiceRequest')  
	AND E.Name = 'SubmittedForDispatch'  
	) ELOG ON SR.ID = ELOG.RecordID AND ELOG.RowNum = 1  
	LEFT OUTER JOIN ClosedLoopStatus CLS WITH (NOLOCK) on CLS.ID=SR.ClosedLoopStatusID  

	WHERE	(@RequestNumberValue IS NOT NULL AND SR.ID = @RequestNumberValue)
	OR		(@RequestNumberValue IS NULL AND DATEDIFF(HH,SR.CreateDate,@now) <= @queueDisplayHours )--and SR.IsRedispatched is null  
END
ELSE
BEGIN
	
	INSERT INTO #FinalResultsFiltered	
	SELECT  
			DISTINCT  
			SR.CaseID AS [Case],  
			SR.ID AS [RequestNumber],  
			CL.Name AS [Client],  
			M.FirstName,
			M.LastName,
			M.MiddleName,
			M.Suffix,
			M.Prefix,     
			-- KB: Retain original values here for sorting  
			sr.CreateDate AS SubmittedOriginal,
			-- KB: Retain original values here for sorting   
			SR.SecondaryProductID,
			PC.Name AS [ServiceType],  
			SRS.Name As [Status],
			SR.IsRedispatched,    
			C.AssignedToUserID,
			SR.NextActionAssignedToUserID,
			CLS.[Description] AS [ClosedLoop],     
			CONVERT(int,PO.PurchaseOrderNumber) AS [PONumber],  
			V.Name AS [ISPName],  
			SR.CreateBy AS [CreateBy],  
			COALESCE(NA.Description,'') AS [NextAction],  
			SR.NextActionID,  
			SR.ClosedLoopStatusID as [ClosedLoopID],  
			SR.ProductCategoryID as [ServiceTypeID],  
			MS.MembershipNumber AS [MemberNumber],  
			SR.ServiceRequestPriorityID AS [PriorityID],  
			SRP.Name AS [Priority],   
			SR.NextActionScheduledDate AS 'ScheduledOriginal',		-- This field is used for Queue Color
			P.Name AS ProgramName,
			P.ID AS ProgramID,
			M.ID AS MemberID,
			SR.StatusDateModified			-- Added by Lakshmi	-Queue Color	
	FROM	ServiceRequest SR	
	JOIN	[ServiceRequestStatus] SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID  
	LEFT JOIN	[ServiceRequestPriority] SRP WITH (NOLOCK) ON SR.ServiceRequestPriorityID = SRP.ID 
	JOIN	[Case] C on C.ID = SR.CaseID
	JOIN	Program P on P.ID = C.ProgramID
	JOIN	[Client] CL WITH (NOLOCK) ON P.ClientID = CL.ID
	JOIN	[Member] M WITH (NOLOCK) ON C.MemberID = M.ID  
	JOIN	Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID  
	LEFT JOIN [ProductCategory] PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID    
	JOIN	PurchaseOrder PO on PO.ServiceRequestID = SR.ID 
							AND PO.PurchaseOrderStatusID IN 
							(SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued', 'Issued-Paid'))
	LEFT JOIN [NextAction] NA WITH (NOLOCK) ON SR.NextActionID=NA.ID 
	LEFT JOIN [VendorLocation] VL WITH (NOLOCK) ON PO.VendorLocationID = VL.ID  
	LEFT JOIN [Vendor] V WITH (NOLOCK) ON VL.VendorID = V.ID  
	LEFT OUTER JOIN ClosedLoopStatus CLS WITH (NOLOCK) on CLS.ID=SR.ClosedLoopStatusID 
	LEFT OUTER JOIN (
		SELECT	CLL.RecordID 
				FROM	ContactLogLink cll 
				JOIN	ContactLog cl ON cl.ID = cll.ContactLogID
				JOIN	ContactLogReason clr ON clr.ContactLogID = cl.ID
				WHERE	cll.EntityID = @serviceRequestEntityID
				AND clr.ContactReasonID = @fhtContactReasonID
	) CLSR ON CLSR.RecordID = SR.ID
	WHERE	CL.Name = 'Ford'
	AND		SR.ServiceRequestStatusID = @dispatchStatusID
	AND		@now between dateadd(mi,@StartMins,po.ETADate) and dateadd(mi,@EndMins,po.ETADate)   
	-- Filter out those SRs that has a contactlog record for HumanTouch.
	AND		CLSR.RecordID IS NULL
	
END

  
-- LOGIC : END  
  

  
  
INSERT INTO #FinalResultsFormatted  
SELECT  
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
T.[ScheduledOriginal],		-- This field is used for Queue Color
T.ProgramName,
T.ProgramID,
T.MemberID,
T.StatusDateModified					--Added by Lakshmi - Queue Color
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




INSERT INTO #FinalResultsSorted
SELECT	T.[Case],  
		T.RequestNumber,  
		T.Client,  
		T.Member,  
		T.Submitted,  
		T.SubmittedOriginal,  
		T.Elapsed,  
		T.ElapsedOriginal,  
		T.ServiceType,  
		T.[Status],  
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
		T.StatusDateModified				--Added by Lakshmi
FROM	#FinalResultsFormatted T
WHERE	( 
			( @MemberValue IS NULL OR  T.Member LIKE '%' + @MemberValue  + '%')
			AND
			( @AssignedToValue IS NULL OR T.AssignedTo LIKE '%' + @AssignedToValue + '%' )
			AND
			( @StatusValue IS NULL OR T.[Status] IN (       
											SELECT T.StatusName FROM @tmpStatusInput T    
											)  
										)
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
  
SELECT [Status],  
  COUNT(*) AS [Total]  
INTO #tmpStatusSummary  
FROM #FinalResultsFiltered  
WHERE [Status] IN ('Entry','Submitted','Submitted^','Dispatched','Dispatched^','Complete','Complete^','Cancelled','Cancelled^')  
GROUP BY [Status]  
--DEBUG: SELECT * FROM #tmpStatusSummary   
  
SELECT @openedCount = [Total] FROM #tmpStatusSummary WHERE [Status] = 'Entry'  
SELECT @submittedCount = SUM([Total]) FROM #tmpStatusSummary WHERE [Status] IN ('Submitted','Submitted^')  
SELECT @dispatchedCount = SUM([Total]) FROM #tmpStatusSummary WHERE [Status] in ('Dispatched', 'Dispatched^')  
SELECT @completecount = SUM([Total]) FROM #tmpStatusSummary WHERE [Status] in ('Complete', 'Complete^')  
SELECT @cancelledcount = SUM([Total]) FROM #tmpStatusSummary WHERE [Status] in ('Cancelled', 'Cancelled^')  
  
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
  
  ISNULL(@openedCount,0) AS [OpenedCount],  
  ISNULL(@submittedCount,0) AS [SubmittedCount],  
  ISNULL(@dispatchedCount,0) AS [DispatchedCount],  
  ISNULL(@completecount,0) AS [CompleteCount],  
  ISNULL(@cancelledcount,0) AS [CancelledCount],  
  F.[Scheduled],
  F.ProgramName,
  F.ProgramID,
  F.MemberID,
  F.StatusDateModified,				--Added by Lakshmi - Queue Color
  F.ScheduledOriginal				--Added by Lakshmi - Queue Color
  
FROM #FinalResultsSorted F  
WHERE F.RowNum BETWEEN @startInd AND @endInd  
  
DROP TABLE #FinalResultsFiltered  
DROP TABLE #FinalResultsFormatted
DROP TABLE #FinalResultsSorted
DROP TABLE #tmpStatusSummary  
  
  
END  
  

