IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Dashboard_DispatchChart]')   		AND type in (N'P', N'PC')) 
BEGIN
 DROP PROCEDURE [dbo].[dms_Dashboard_DispatchChart] 
END 
GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[dms_Dashboard_DispatchChart]
AS
BEGIN
DECLARE @startDate AS DATE 
SET @startDate = DATEADD(m,-11,GETDATE())
DECLARE @EndDate AS DATE = DATEADD(d,1,GETDATE())


--====================================================================================================================
-- Service Request Count
--
--
-- 1. Setup Stored Procedure to drive chart.... convert to cross-tab query
-- 2. Setup chart on Dashboard for Dispatch
-- 3. Use line chart
-- 4. Title = Serivce Request Count
-- 5. Vertical Axis = service request counts:  0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000
-- 6. Horizontal Axis = NMC, Ford, Hagerty, Others
-- 7. Show Jan to Dec


-- Line Graph

-- Show monthly totals of call counts by clients

-- Set 

--82559
DECLARE @Result AS TABLE(
Client NVARCHAR(50),
Month1 INT,
Month2 INT,
Month3 INT,
Month4 INT,
Month5 INT,
Month6 INT,
Month7 INT,
Month8 INT,
Month9 INT,
Month10 INT,
Month11 INT,
Month12 INT
)

INSERT INTO @Result(Client,Month1,Month2,Month3,Month4,Month5,Month6,Month7,Month8,Month9,Month10,Month11,Month12)

SELECT 
	CASE  
		WHEN cl.Name = 'Coach-Net' THEN 'Coach-Net'
		WHEN cl.Name = 'National Motor Club' THEN 'NMC'
		WHEN cl.Name = 'Ford' Then 'Ford'
		WHEN cl.Name = 'Hagerty' Then 'Hagerty'
		ELSE 'Other'
	  END as Client
	--, datepart(mm,sr.CreateDate) AS 'Month'
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,@startDate) THEN count(sr.id)
	  END,0) AS Jan
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,1,@startDate))) THEN count(sr.id)
	  END,0) as Feb
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,2,@startDate))) THEN count(sr.id)
	  END,0) as Mar
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,3,@startDate))) THEN count(sr.id)
	  END,0) as Apr
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,4,@startDate))) THEN count(sr.id)
	  END,0) as May
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,5,@startDate))) THEN count(sr.id)
	  END,0) as Jun
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,6,@startDate))) THEN count(sr.id)
	  END,0) AS Jul
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,7,@startDate))) THEN count(sr.id)
	  END,0) as Aug
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,8,@startDate))) THEN count(sr.id)
	  END,0) as Sep
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,9,@startDate))) THEN count(sr.id)
	  END,0) as Oct
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,10,@startDate))) THEN count(sr.id)
	  END,0) as Nov
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,11,@startDate))) THEN count(sr.id)
	  END,0) as Dec
FROM ServiceRequest sr
JOIN ServiceRequestStatus srs ON srs.ID = sr.ServiceRequestStatusID
JOIN [Case] c ON c.ID = sr.CaseID
JOIN Program p on p.ID = c.ProgramID
JOIN Program pp on p.ParentProgramID IS NULL OR pp.ID = p.ParentProgramID
JOIN Client cl on cl.ID = p.ClientID
WHERE
	sr.CreateDate between @StartDate and @EndDate
	AND sr.ServiceRequestStatusID IN (SELECT ID FROM ServiceRequestStatus WHERE Name IN ('Complete','Cancelled'))
GROUP BY
		CASE
		WHEN cl.Name = 'Coach-Net' THEN 'Coach-Net'
		WHEN cl.Name = 'National Motor Club' THEN 'NMC'
		WHEN cl.Name = 'Ford' Then 'Ford'
		WHEN cl.Name = 'Hagerty' Then 'Hagerty'
		ELSE 'Other'
	  END
	  , datepart(mm,sr.createdate)
ORDER BY
	CASE
		WHEN cl.Name = 'Coach-Net' THEN 'Coach-Net'
		WHEN cl.Name = 'National Motor Club' THEN 'NMC'
		WHEN cl.Name = 'Ford' Then 'Ford'
		WHEN cl.Name = 'Hagerty' Then 'Hagerty'
		ELSE 'Other'
	END 
	, datepart(mm,sr.CreateDate)
	
SELECT Client,
	  SUM(Month1) AS 'Month1',
	  SUM(Month2) AS 'Month2',
	  SUM(Month3) AS 'Month3' ,
	  SUM(Month4) AS 'Month4' ,
	  SUM(Month5) AS 'Month5' ,
	  SUM(Month6) AS 'Month6' ,
	  SUM(Month7) AS 'Month7' ,
	  SUM(Month8) AS 'Month8' ,
	  SUM(Month9) AS 'Month9' ,
	  SUM(Month10) AS 'Month10' ,
	  SUM(Month11) AS 'Month11' ,
	  SUM(Month12) AS 'Month12' 
FROM @Result
GROUP BY Client
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
 WHERE id = object_id(N'[dbo].[dms_Program_Maintainence_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Maintainence_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Maintainence_List_Get]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
SortOperator="-1" 
ClientIDOperator="-1" 
ClientNameOperator="-1" 
ParentProgramIDOperator="-1" 
ParentNameOperator="-1" 
ProgramIDOperator="-1" 
ProgramCodeOperator="-1" 
ProgramNameOperator="-1" 
ProgramDescriptionOperator="-1" 
ProgramIsActiveOperator="-1" 
IsAuditedOperator="-1" 
IsClosedLoopAutomatedOperator="-1" 
IsGroupOperator="-1"
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
SortOperator INT NOT NULL,
SortValue int NULL,
ClientIDOperator INT NOT NULL,
ClientIDValue int NULL,
ClientNameOperator INT NOT NULL,
ClientNameValue nvarchar(50) NULL,
ParentProgramIDOperator INT NOT NULL,
ParentProgramIDValue int NULL,
ParentNameOperator INT NOT NULL,
ParentNameValue nvarchar(50) NULL,
ProgramIDOperator INT NOT NULL,
ProgramIDValue int NULL,
ProgramCodeOperator INT NOT NULL,
ProgramCodeValue nvarchar(50) NULL,
ProgramNameOperator INT NOT NULL,
ProgramNameValue nvarchar(50) NULL,
ProgramDescriptionOperator INT NOT NULL,
ProgramDescriptionValue nvarchar(50) NULL,
ProgramIsActiveOperator INT NOT NULL,
ProgramIsActiveValue bit NULL,
IsAuditedOperator INT NOT NULL,
IsAuditedValue bit NULL,
IsClosedLoopAutomatedOperator INT NOT NULL,
IsClosedLoopAutomatedValue bit NULL,
IsGroupOperator INT NOT NULL,
IsGroupValue bit NULL


)
DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Sort int  NULL ,
	ClientID int  NULL ,
	ClientName nvarchar(50)  NULL ,
	ParentProgramID int  NULL ,
	ParentName nvarchar(50)  NULL ,
	ProgramID int  NULL ,
	ProgramCode nvarchar(50)  NULL ,
	ProgramName nvarchar(50)  NULL ,
	ProgramDescription nvarchar(50)  NULL ,
	ProgramIsActive bit  NULL ,
	IsAudited bit  NULL ,
	IsClosedLoopAutomated bit  NULL ,
	IsGroup bit  NULL 
) 

DECLARE @FinalResults_Temp TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Sort int  NULL ,
	ClientID int  NULL ,
	ClientName nvarchar(50)  NULL ,
	ParentProgramID int  NULL ,
	ParentName nvarchar(50)  NULL ,
	ProgramID int  NULL ,
	ProgramCode nvarchar(50)  NULL ,
	ProgramName nvarchar(50)  NULL ,
	ProgramDescription nvarchar(50)  NULL ,
	ProgramIsActive bit  NULL ,
	IsAudited bit  NULL ,
	IsClosedLoopAutomated bit  NULL ,
	IsGroup bit  NULL 
) 

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(SortOperator,-1),
	SortValue ,
	ISNULL(ClientIDOperator,-1),
	ClientIDValue ,
	ISNULL( ClientNameOperator,-1),
	ClientNameValue ,
	ISNULL(ParentProgramIDOperator,-1),
	ParentProgramIDValue ,
	ISNULL(ParentNameOperator,-1),
	ParentNameValue ,
	ISNULL(ProgramIDOperator,-1),
	ProgramIDValue ,
	ISNULL(ProgramCodeOperator,-1),
	ProgramCodeValue ,
	ISNULL(ProgramNameOperator,-1),
	ProgramNameValue ,
	ISNULL(ProgramDescriptionOperator,-1),
	ProgramDescriptionValue ,
	ISNULL(ProgramIsActiveOperator,-1),
	ProgramIsActiveValue ,
	ISNULL(IsAuditedOperator,-1),
	IsAuditedValue ,
	ISNULL(IsClosedLoopAutomatedOperator,-1),
	IsClosedLoopAutomatedValue ,
	ISNULL(IsGroupOperator,-1),
	IsGroupValue
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
SortOperator INT,
SortValue int 
,ClientIDOperator INT,
ClientIDValue int 
,ClientNameOperator INT,
ClientNameValue nvarchar(50) 
,ParentProgramIDOperator INT,
ParentProgramIDValue int 
,ParentNameOperator INT,
ParentNameValue nvarchar(50) 
,ProgramIDOperator INT,
ProgramIDValue int 
,ProgramCodeOperator INT,
ProgramCodeValue nvarchar(50) 
,ProgramNameOperator INT,
ProgramNameValue nvarchar(50) 
,ProgramDescriptionOperator INT,
ProgramDescriptionValue nvarchar(50) 
,ProgramIsActiveOperator INT,
ProgramIsActiveValue bit 
,IsAuditedOperator INT,
IsAuditedValue bit 
,IsClosedLoopAutomatedOperator INT,
IsClosedLoopAutomatedValue bit 
,IsGroupOperator INT,
IsGroupValue bit 

 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults_Temp
SELECT
CASE
WHEN PP.ID IS NULL THEN P.ID
ELSE PP.ID
END AS Sort
, C.ID AS ClientID
, C.Name AS ClientName
, PP.ID AS ParentProgramID
, PP.Name AS ParentName
, P.ID AS ProgramID
, P.Code AS ProgramCode
, P.Name AS ProgramName
, P.Description AS ProgramDescription
, P.IsActive AS ProgramIsActive
, P.IsAudited AS IsAudited
, P.IsClosedLoopAutomated AS IsClosedLoopAutomated
, P.IsGroup AS IsGroup
--, *
FROM Program P (NOLOCK)
JOIN Client C (NOLOCK) ON C.ID = P.ClientID
LEFT JOIN Program PP (NOLOCK) ON PP.ID = P.ParentProgramID
WHERE C.Name <> 'ARS'
ORDER BY C.Name, Sort, PP.ID, P.ID


INSERT INTO @FinalResults
SELECT 
	T.Sort,
	T.ClientID,
	T.ClientName,
	T.ParentProgramID,
	T.ParentName,
	T.ProgramID,
	T.ProgramCode,
	T.ProgramName,
	T.ProgramDescription,
	T.ProgramIsActive,
	T.IsAudited,
	T.IsClosedLoopAutomated,
	T.IsGroup
FROM @FinalResults_Temp T,
@tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.SortOperator = -1 ) 
 OR 
	 ( TMP.SortOperator = 0 AND T.Sort IS NULL ) 
 OR 
	 ( TMP.SortOperator = 1 AND T.Sort IS NOT NULL ) 
 OR 
	 ( TMP.SortOperator = 2 AND T.Sort = TMP.SortValue ) 
 OR 
	 ( TMP.SortOperator = 3 AND T.Sort <> TMP.SortValue ) 
 OR 
	 ( TMP.SortOperator = 7 AND T.Sort > TMP.SortValue ) 
 OR 
	 ( TMP.SortOperator = 8 AND T.Sort >= TMP.SortValue ) 
 OR 
	 ( TMP.SortOperator = 9 AND T.Sort < TMP.SortValue ) 
 OR 
	 ( TMP.SortOperator = 10 AND T.Sort <= TMP.SortValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ClientIDOperator = -1 ) 
 OR 
	 ( TMP.ClientIDOperator = 0 AND T.ClientID IS NULL ) 
 OR 
	 ( TMP.ClientIDOperator = 1 AND T.ClientID IS NOT NULL ) 
 OR 
	 ( TMP.ClientIDOperator = 2 AND T.ClientID = TMP.ClientIDValue ) 
 OR 
	 ( TMP.ClientIDOperator = 3 AND T.ClientID <> TMP.ClientIDValue ) 
 OR 
	 ( TMP.ClientIDOperator = 7 AND T.ClientID > TMP.ClientIDValue ) 
 OR 
	 ( TMP.ClientIDOperator = 8 AND T.ClientID >= TMP.ClientIDValue ) 
 OR 
	 ( TMP.ClientIDOperator = 9 AND T.ClientID < TMP.ClientIDValue ) 
 OR 
	 ( TMP.ClientIDOperator = 10 AND T.ClientID <= TMP.ClientIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ClientNameOperator = -1 ) 
 OR 
	 ( TMP.ClientNameOperator = 0 AND T.ClientName IS NULL ) 
 OR 
	 ( TMP.ClientNameOperator = 1 AND T.ClientName IS NOT NULL ) 
 OR 
	 ( TMP.ClientNameOperator = 2 AND T.ClientName = TMP.ClientNameValue ) 
 OR 
	 ( TMP.ClientNameOperator = 3 AND T.ClientName <> TMP.ClientNameValue ) 
 OR 
	 ( TMP.ClientNameOperator = 4 AND T.ClientName LIKE TMP.ClientNameValue + '%') 
 OR 
	 ( TMP.ClientNameOperator = 5 AND T.ClientName LIKE '%' + TMP. ClientNameValue ) 
 OR 
	 ( TMP.ClientNameOperator = 6 AND T.ClientName LIKE '%' + TMP. ClientNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ParentProgramIDOperator = -1 ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 0 AND T.ParentProgramID IS NULL ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 1 AND T.ParentProgramID IS NOT NULL ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 2 AND T.ParentProgramID = TMP.ParentProgramIDValue ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 3 AND T.ParentProgramID <> TMP.ParentProgramIDValue ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 7 AND T.ParentProgramID > TMP.ParentProgramIDValue ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 8 AND T.ParentProgramID >= TMP.ParentProgramIDValue ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 9 AND T.ParentProgramID < TMP.ParentProgramIDValue ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 10 AND T.ParentProgramID <= TMP.ParentProgramIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ParentNameOperator = -1 ) 
 OR 
	 ( TMP.ParentNameOperator = 0 AND T.ParentName IS NULL ) 
 OR 
	 ( TMP.ParentNameOperator = 1 AND T.ParentName IS NOT NULL ) 
 OR 
	 ( TMP.ParentNameOperator = 2 AND T.ParentName = TMP.ParentNameValue ) 
 OR 
	 ( TMP.ParentNameOperator = 3 AND T.ParentName <> TMP.ParentNameValue ) 
 OR 
	 ( TMP.ParentNameOperator = 4 AND T.ParentName LIKE TMP.ParentNameValue + '%') 
 OR 
	 ( TMP.ParentNameOperator = 5 AND T.ParentName LIKE '%' + TMP.ParentNameValue ) 
 OR 
	 ( TMP.ParentNameOperator = 6 AND T.ParentName LIKE '%' + TMP.ParentNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProgramIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramIDOperator = 0 AND T.ProgramID IS NULL ) 
 OR 
	 ( TMP.ProgramIDOperator = 1 AND T.ProgramID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramIDOperator = 2 AND T.ProgramID = TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 3 AND T.ProgramID <> TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 7 AND T.ProgramID > TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 8 AND T.ProgramID >= TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 9 AND T.ProgramID < TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 10 AND T.ProgramID <= TMP.ProgramIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ProgramCodeOperator = -1 ) 
 OR 
	 ( TMP.ProgramCodeOperator = 0 AND T.ProgramCode IS NULL ) 
 OR 
	 ( TMP.ProgramCodeOperator = 1 AND T.ProgramCode IS NOT NULL ) 
 OR 
	 ( TMP.ProgramCodeOperator = 2 AND T.ProgramCode = TMP.ProgramCodeValue ) 
 OR 
	 ( TMP.ProgramCodeOperator = 3 AND T.ProgramCode <> TMP.ProgramCodeValue ) 
 OR 
	 ( TMP.ProgramCodeOperator = 4 AND T.ProgramCode LIKE TMP.ProgramCodeValue + '%') 
 OR 
	 ( TMP.ProgramCodeOperator = 5 AND T.ProgramCode LIKE '%' + TMP.ProgramCodeValue ) 
 OR 
	 ( TMP.ProgramCodeOperator = 6 AND T.ProgramCode LIKE '%' + TMP.ProgramCodeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProgramNameOperator = -1 ) 
 OR 
	 ( TMP.ProgramNameOperator = 0 AND T.ProgramName IS NULL ) 
 OR 
	 ( TMP.ProgramNameOperator = 1 AND T.ProgramName IS NOT NULL ) 
 OR 
	 ( TMP.ProgramNameOperator = 2 AND T.ProgramName = TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 3 AND T.ProgramName <> TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 4 AND T.ProgramName LIKE TMP.ProgramNameValue + '%') 
 OR 
	 ( TMP.ProgramNameOperator = 5 AND T.ProgramName LIKE '%' + TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 6 AND T.ProgramName LIKE '%' + TMP.ProgramNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProgramDescriptionOperator = -1 ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 0 AND T.ProgramDescription IS NULL ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 1 AND T.ProgramDescription IS NOT NULL ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 2 AND T.ProgramDescription = TMP.ProgramDescriptionValue ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 3 AND T.ProgramDescription <> TMP.ProgramDescriptionValue ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 4 AND T.ProgramDescription LIKE TMP.ProgramDescriptionValue + '%') 
 OR 
	 ( TMP.ProgramDescriptionOperator = 5 AND T.ProgramDescription LIKE '%' + TMP.ProgramDescriptionValue ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 6 AND T.ProgramDescription LIKE '%' + TMP.ProgramDescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProgramIsActiveOperator = -1 ) 
 OR 
	 ( TMP.ProgramIsActiveOperator = 0 AND T.ProgramIsActive IS NULL ) 
 OR 
	 ( TMP.ProgramIsActiveOperator = 1 AND T.ProgramIsActive IS NOT NULL ) 
 OR 
	 ( TMP.ProgramIsActiveOperator = 2 AND T.ProgramIsActive = TMP.ProgramIsActiveValue ) 
 OR 
	 ( TMP.ProgramIsActiveOperator = 3 AND T.ProgramIsActive <> TMP.ProgramIsActiveValue ) 
 ) 

 AND 

 ( 
	 ( TMP.IsAuditedOperator = -1 ) 
 OR 
	 ( TMP.IsAuditedOperator = 0 AND T.IsAudited IS NULL ) 
 OR 
	 ( TMP.IsAuditedOperator = 1 AND T.IsAudited IS NOT NULL ) 
 OR 
	 ( TMP.IsAuditedOperator = 2 AND T.IsAudited = TMP.IsAuditedValue ) 
 OR 
	 ( TMP.IsAuditedOperator = 3 AND T.IsAudited <> TMP.IsAuditedValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsClosedLoopAutomatedOperator = -1 ) 
 OR 
	 ( TMP.IsClosedLoopAutomatedOperator = 0 AND T.IsClosedLoopAutomated IS NULL ) 
 OR 
	 ( TMP.IsClosedLoopAutomatedOperator = 1 AND T.IsClosedLoopAutomated IS NOT NULL ) 
 OR 
	 ( TMP.IsClosedLoopAutomatedOperator = 2 AND T.IsClosedLoopAutomated = TMP.IsClosedLoopAutomatedValue ) 
 OR 
	 ( TMP.IsClosedLoopAutomatedOperator = 3 AND T.IsClosedLoopAutomated <> TMP.IsClosedLoopAutomatedValue )

 ) 

 AND 

 ( 
	 ( TMP.IsGroupOperator = -1 ) 
 OR 
	 ( TMP.IsGroupOperator = 0 AND T.IsGroup IS NULL ) 
 OR 
	 ( TMP.IsGroupOperator = 1 AND T.IsGroup IS NOT NULL ) 
 OR 
	 ( TMP.IsGroupOperator = 2 AND T.IsGroup = TMP.IsGroupValue ) 
 OR 
	 ( TMP.IsGroupOperator = 3 AND T.IsGroup <> TMP.IsGroupValue )

 ) 
 
 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'Sort' AND @sortOrder = 'ASC'
	 THEN T.Sort END ASC, 
	 CASE WHEN @sortColumn = 'Sort' AND @sortOrder = 'DESC'
	 THEN T.Sort END DESC ,

	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'ASC'
	 THEN T.ClientID END ASC, 
	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'DESC'
	 THEN T.ClientID END DESC ,

	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'ASC'
	 THEN T.ClientName END ASC, 
	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'DESC'
	 THEN T.ClientName END DESC ,

	 CASE WHEN @sortColumn = 'ParentProgramID' AND @sortOrder = 'ASC'
	 THEN T.ParentProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ParentProgramID' AND @sortOrder = 'DESC'
	 THEN T.ParentProgramID END DESC ,

	 CASE WHEN @sortColumn = 'ParentName' AND @sortOrder = 'ASC'
	 THEN T.ParentName END ASC, 
	 CASE WHEN @sortColumn = 'ParentName' AND @sortOrder = 'DESC'
	 THEN T.ParentName END DESC ,

	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'ASC'
	 THEN T.ProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'DESC'
	 THEN T.ProgramID END DESC ,

	 CASE WHEN @sortColumn = 'ProgramCode' AND @sortOrder = 'ASC'
	 THEN T.ProgramCode END ASC, 
	 CASE WHEN @sortColumn = 'ProgramCode' AND @sortOrder = 'DESC'
	 THEN T.ProgramCode END DESC ,

	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'ASC'
	 THEN T.ProgramName END ASC, 
	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'DESC'
	 THEN T.ProgramName END DESC ,

	 CASE WHEN @sortColumn = 'ProgramDescription' AND @sortOrder = 'ASC'
	 THEN T.ProgramDescription END ASC, 
	 CASE WHEN @sortColumn = 'ProgramDescription' AND @sortOrder = 'DESC'
	 THEN T.ProgramDescription END DESC ,

	 CASE WHEN @sortColumn = 'ProgramIsActive' AND @sortOrder = 'ASC'
	 THEN T.ProgramIsActive END ASC, 
	 CASE WHEN @sortColumn = 'ProgramIsActive' AND @sortOrder = 'DESC'
	 THEN T.ProgramIsActive END DESC ,

	 CASE WHEN @sortColumn = 'IsAudited' AND @sortOrder = 'ASC'
	 THEN T.IsAudited END ASC, 
	 CASE WHEN @sortColumn = 'IsAudited' AND @sortOrder = 'DESC'
	 THEN T.IsAudited END DESC ,

	 CASE WHEN @sortColumn = 'IsClosedLoopAutomated' AND @sortOrder = 'ASC'
	 THEN T.IsClosedLoopAutomated END ASC, 
	 CASE WHEN @sortColumn = 'IsClosedLoopAutomated' AND @sortOrder = 'DESC'
	 THEN T.IsClosedLoopAutomated END DESC ,

	 CASE WHEN @sortColumn = 'IsGroup' AND @sortOrder = 'ASC'
	 THEN T.IsGroup END ASC, 
	 CASE WHEN @sortColumn = 'IsGroup' AND @sortOrder = 'DESC'
	 THEN T.IsGroup END DESC 


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
*  ---- for int, money, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_Services_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_Services_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_Program_Management_Services_List_Get] @ProgramID =3 ,@pageSize = 25
 CREATE PROCEDURE [dbo].[dms_Program_Management_Services_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @ProgramID INT = NULL 
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
 	SET FMTONLY OFF

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
ProgramProductIDOperator="-1" 
CategoryOperator="-1" 
ServiceOperator="-1" 
StartDateOperator="-1" 
EndDateOperator="-1" 
ServiceCoverageLimitOperator="-1" 
IsServiceCoverageBestValueOperator="-1" 
MaterialsCoverageLimitOperator="-1" 
IsMaterialsMemberPayOperator="-1" 
ServiceMileageLimitOperator="-1" 
IsServiceMileageUnlimitedOperator="-1" 
IsServiceMileageOverageAllowedOperator="-1" 
IsReimbersementOnlyOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
ProgramProductIDOperator INT NOT NULL,
ProgramProductIDValue int NULL,
CategoryOperator INT NOT NULL,
CategoryValue nvarchar(100) NULL,
ServiceOperator INT NOT NULL,
ServiceValue nvarchar(100) NULL,
StartDateOperator INT NOT NULL,
StartDateValue datetime NULL,
EndDateOperator INT NOT NULL,
EndDateValue datetime NULL,
ServiceCoverageLimitOperator INT NOT NULL,
ServiceCoverageLimitValue money NULL,
IsServiceCoverageBestValueOperator INT NOT NULL,
IsServiceCoverageBestValueValue bit NULL,
MaterialsCoverageLimitOperator INT NOT NULL,
MaterialsCoverageLimitValue money NULL,
IsMaterialsMemberPayOperator INT NOT NULL,
IsMaterialsMemberPayValue bit NULL,
ServiceMileageLimitOperator INT NOT NULL,
ServiceMileageLimitValue int NULL,
IsServiceMileageUnlimitedOperator INT NOT NULL,
IsServiceMileageUnlimitedValue bit NULL,
IsServiceMileageOverageAllowedOperator INT NOT NULL,
IsServiceMileageOverageAllowedValue bit NULL,
IsReimbersementOnlyOperator INT NOT NULL,
IsReimbersementOnlyValue bit NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramProductID int  NULL ,
	Category nvarchar(100)  NULL ,
	Service nvarchar(100)  NULL ,
	StartDate datetime  NULL ,
	EndDate datetime  NULL ,
	ServiceCoverageLimit money  NULL ,
	IsServiceCoverageBestValue bit  NULL ,
	MaterialsCoverageLimit money  NULL ,
	IsMaterialsMemberPay bit  NULL ,
	ServiceMileageLimit int  NULL ,
	IsServiceMileageUnlimited bit  NULL ,
	IsServiceMileageOverageAllowed bit  NULL ,
	IsReimbersementOnly bit  NULL 
) 

CREATE TABLE #FinalResults_temp( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramProductID int  NULL ,
	Category nvarchar(100)  NULL ,
	Service nvarchar(100)  NULL ,
	StartDate datetime  NULL ,
	EndDate datetime  NULL ,
	ServiceCoverageLimit money  NULL ,
	IsServiceCoverageBestValue bit  NULL ,
	MaterialsCoverageLimit money  NULL ,
	IsMaterialsMemberPay bit  NULL ,
	ServiceMileageLimit int  NULL ,
	IsServiceMileageUnlimited bit  NULL ,
	IsServiceMileageOverageAllowed bit  NULL ,
	IsReimbersementOnly bit  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@ProgramProductIDOperator','INT'),-1),
	T.c.value('@ProgramProductIDValue','int') ,
	ISNULL(T.c.value('@CategoryOperator','INT'),-1),
	T.c.value('@CategoryValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ServiceOperator','INT'),-1),
	T.c.value('@ServiceValue','nvarchar(100)') ,
	ISNULL(T.c.value('@StartDateOperator','INT'),-1),
	T.c.value('@StartDateValue','datetime') ,
	ISNULL(T.c.value('@EndDateOperator','INT'),-1),
	T.c.value('@EndDateValue','datetime') ,
	ISNULL(T.c.value('@ServiceCoverageLimitOperator','INT'),-1),
	T.c.value('@ServiceCoverageLimitValue','money') ,
	ISNULL(T.c.value('@IsServiceCoverageBestValueOperator','INT'),-1),
	T.c.value('@IsServiceCoverageBestValueValue','bit') ,
	ISNULL(T.c.value('@MaterialsCoverageLimitOperator','INT'),-1),
	T.c.value('@MaterialsCoverageLimitValue','money') ,
	ISNULL(T.c.value('@IsMaterialsMemberPayOperator','INT'),-1),
	T.c.value('@IsMaterialsMemberPayValue','bit') ,
	ISNULL(T.c.value('@ServiceMileageLimitOperator','INT'),-1),
	T.c.value('@ServiceMileageLimitValue','int') ,
	ISNULL(T.c.value('@IsServiceMileageUnlimitedOperator','INT'),-1),
	T.c.value('@IsServiceMileageUnlimitedValue','bit') ,
	ISNULL(T.c.value('@IsServiceMileageOverageAllowedOperator','INT'),-1),
	T.c.value('@IsServiceMileageOverageAllowedValue','bit') ,
	ISNULL(T.c.value('@IsReimbersementOnlyOperator','INT'),-1),
	T.c.value('@IsReimbersementOnlyValue','bit') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults_temp
SELECT 
  PP.ID AS ProgramProductID
, PC.Name AS Category
, PR.Name AS [Service]
, PP.StartDate
, PP.EndDate
, PP.ServiceCoverageLimit
, PP.IsServiceCoverageBestValue
, PP.MaterialsCoverageLimit
, PP.IsMaterialsMemberPay
, PP.ServiceMileageLimit
, PP.IsServiceMileageUnlimited
, PP.IsServiceMileageOverageAllowed
, PP.IsReimbersementOnly
FROM ProgramProduct PP
JOIN Program P (NOLOCK) ON P.ID = PP.ProgramID
JOIN Product PR (NOLOCK) ON PR.ID = PP.ProductID
JOIN ProductCategory PC (NOLOCK) ON PC.ID = PR.ProductCategoryID
WHERE PP.ProgramID = @ProgramID
ORDER BY PC.Sequence, PR.Name
INSERT INTO #FinalResults
SELECT 
	T.ProgramProductID,
	T.Category,
	T.Service,
	T.StartDate,
	T.EndDate,
	T.ServiceCoverageLimit,
	T.IsServiceCoverageBestValue,
	T.MaterialsCoverageLimit,
	T.IsMaterialsMemberPay,
	T.ServiceMileageLimit,
	T.IsServiceMileageUnlimited,
	T.IsServiceMileageOverageAllowed,
	T.IsReimbersementOnly
FROM #FinalResults_temp T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.ProgramProductIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 0 AND T.ProgramProductID IS NULL ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 1 AND T.ProgramProductID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 2 AND T.ProgramProductID = TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 3 AND T.ProgramProductID <> TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 7 AND T.ProgramProductID > TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 8 AND T.ProgramProductID >= TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 9 AND T.ProgramProductID < TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 10 AND T.ProgramProductID <= TMP.ProgramProductIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CategoryOperator = -1 ) 
 OR 
	 ( TMP.CategoryOperator = 0 AND T.Category IS NULL ) 
 OR 
	 ( TMP.CategoryOperator = 1 AND T.Category IS NOT NULL ) 
 OR 
	 ( TMP.CategoryOperator = 2 AND T.Category = TMP.CategoryValue ) 
 OR 
	 ( TMP.CategoryOperator = 3 AND T.Category <> TMP.CategoryValue ) 
 OR 
	 ( TMP.CategoryOperator = 4 AND T.Category LIKE TMP.CategoryValue + '%') 
 OR 
	 ( TMP.CategoryOperator = 5 AND T.Category LIKE '%' + TMP.CategoryValue ) 
 OR 
	 ( TMP.CategoryOperator = 6 AND T.Category LIKE '%' + TMP.CategoryValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ServiceOperator = -1 ) 
 OR 
	 ( TMP.ServiceOperator = 0 AND T.Service IS NULL ) 
 OR 
	 ( TMP.ServiceOperator = 1 AND T.Service IS NOT NULL ) 
 OR 
	 ( TMP.ServiceOperator = 2 AND T.Service = TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 3 AND T.Service <> TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 4 AND T.Service LIKE TMP.ServiceValue + '%') 
 OR 
	 ( TMP.ServiceOperator = 5 AND T.Service LIKE '%' + TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 6 AND T.Service LIKE '%' + TMP.ServiceValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.StartDateOperator = -1 ) 
 OR 
	 ( TMP.StartDateOperator = 0 AND T.StartDate IS NULL ) 
 OR 
	 ( TMP.StartDateOperator = 1 AND T.StartDate IS NOT NULL ) 
 OR 
	 ( TMP.StartDateOperator = 2 AND T.StartDate = TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 3 AND T.StartDate <> TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 7 AND T.StartDate > TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 8 AND T.StartDate >= TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 9 AND T.StartDate < TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 10 AND T.StartDate <= TMP.StartDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.EndDateOperator = -1 ) 
 OR 
	 ( TMP.EndDateOperator = 0 AND T.EndDate IS NULL ) 
 OR 
	 ( TMP.EndDateOperator = 1 AND T.EndDate IS NOT NULL ) 
 OR 
	 ( TMP.EndDateOperator = 2 AND T.EndDate = TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 3 AND T.EndDate <> TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 7 AND T.EndDate > TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 8 AND T.EndDate >= TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 9 AND T.EndDate < TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 10 AND T.EndDate <= TMP.EndDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ServiceCoverageLimitOperator = -1 ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 0 AND T.ServiceCoverageLimit IS NULL ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 1 AND T.ServiceCoverageLimit IS NOT NULL ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 2 AND T.ServiceCoverageLimit = TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 3 AND T.ServiceCoverageLimit <> TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 7 AND T.ServiceCoverageLimit > TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 8 AND T.ServiceCoverageLimit >= TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 9 AND T.ServiceCoverageLimit < TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 10 AND T.ServiceCoverageLimit <= TMP.ServiceCoverageLimitValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsServiceCoverageBestValueOperator = -1 ) 
 OR 
	 ( TMP.IsServiceCoverageBestValueOperator = 0 AND T.IsServiceCoverageBestValue IS NULL ) 
 OR 
	 ( TMP.IsServiceCoverageBestValueOperator = 1 AND T.IsServiceCoverageBestValue IS NOT NULL ) 
 OR 
	 ( TMP.IsServiceCoverageBestValueOperator = 2 AND T.IsServiceCoverageBestValue = TMP.IsServiceCoverageBestValueValue ) 
 OR 
	 ( TMP.IsServiceCoverageBestValueOperator = 3 AND T.IsServiceCoverageBestValue <> TMP.IsServiceCoverageBestValueValue ) 
 ) 

 AND 

 ( 
	 ( TMP.MaterialsCoverageLimitOperator = -1 ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 0 AND T.MaterialsCoverageLimit IS NULL ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 1 AND T.MaterialsCoverageLimit IS NOT NULL ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 2 AND T.MaterialsCoverageLimit = TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 3 AND T.MaterialsCoverageLimit <> TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 7 AND T.MaterialsCoverageLimit > TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 8 AND T.MaterialsCoverageLimit >= TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 9 AND T.MaterialsCoverageLimit < TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 10 AND T.MaterialsCoverageLimit <= TMP.MaterialsCoverageLimitValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsMaterialsMemberPayOperator = -1 ) 
 OR 
	 ( TMP.IsMaterialsMemberPayOperator = 0 AND T.IsMaterialsMemberPay IS NULL ) 
 OR 
	 ( TMP.IsMaterialsMemberPayOperator = 1 AND T.IsMaterialsMemberPay IS NOT NULL ) 
 OR 
	 ( TMP.IsMaterialsMemberPayOperator = 2 AND T.IsMaterialsMemberPay = TMP.IsMaterialsMemberPayValue ) 
 OR 
	 ( TMP.IsMaterialsMemberPayOperator = 3 AND T.IsMaterialsMemberPay <> TMP.IsMaterialsMemberPayValue ) 
 ) 

 AND 

 ( 
	 ( TMP.ServiceMileageLimitOperator = -1 ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 0 AND T.ServiceMileageLimit IS NULL ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 1 AND T.ServiceMileageLimit IS NOT NULL ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 2 AND T.ServiceMileageLimit = TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 3 AND T.ServiceMileageLimit <> TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 7 AND T.ServiceMileageLimit > TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 8 AND T.ServiceMileageLimit >= TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 9 AND T.ServiceMileageLimit < TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 10 AND T.ServiceMileageLimit <= TMP.ServiceMileageLimitValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsServiceMileageUnlimitedOperator = -1 ) 
 OR 
	 ( TMP.IsServiceMileageUnlimitedOperator = 0 AND T.IsServiceMileageUnlimited IS NULL ) 
 OR 
	 ( TMP.IsServiceMileageUnlimitedOperator = 1 AND T.IsServiceMileageUnlimited IS NOT NULL ) 
 OR 
	 ( TMP.IsServiceMileageUnlimitedOperator = 2 AND T.IsServiceMileageUnlimited = TMP.IsServiceMileageUnlimitedValue ) 
 OR 
	 ( TMP.IsServiceMileageUnlimitedOperator = 3 AND T.IsServiceMileageUnlimited <> TMP.IsServiceMileageUnlimitedValue ) 
 ) 

 AND 

 ( 
	 ( TMP.IsServiceMileageOverageAllowedOperator = -1 ) 
 OR 
	 ( TMP.IsServiceMileageOverageAllowedOperator = 0 AND T.IsServiceMileageOverageAllowed IS NULL ) 
 OR 
	 ( TMP.IsServiceMileageOverageAllowedOperator = 1 AND T.IsServiceMileageOverageAllowed IS NOT NULL ) 
 OR 
	 ( TMP.IsServiceMileageOverageAllowedOperator = 2 AND T.IsServiceMileageOverageAllowed = TMP.IsServiceMileageOverageAllowedValue ) 
 OR 
	 ( TMP.IsServiceMileageOverageAllowedOperator = 3 AND T.IsServiceMileageOverageAllowed <> TMP.IsServiceMileageOverageAllowedValue ) 
 ) 

 AND 

 ( 
	 ( TMP.IsReimbersementOnlyOperator = -1 ) 
 OR 
	 ( TMP.IsReimbersementOnlyOperator = 0 AND T.IsReimbersementOnly IS NULL ) 
 OR 
	 ( TMP.IsReimbersementOnlyOperator = 1 AND T.IsReimbersementOnly IS NOT NULL ) 
 OR 
	 ( TMP.IsReimbersementOnlyOperator = 2 AND T.IsReimbersementOnly = TMP.IsReimbersementOnlyValue ) 
 OR 
	 ( TMP.IsReimbersementOnlyOperator = 3 AND T.IsReimbersementOnly <> TMP.IsReimbersementOnlyValue ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ProgramProductID' AND @sortOrder = 'ASC'
	 THEN T.ProgramProductID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramProductID' AND @sortOrder = 'DESC'
	 THEN T.ProgramProductID END DESC ,

	 CASE WHEN @sortColumn = 'Category' AND @sortOrder = 'ASC'
	 THEN T.Category END ASC, 
	 CASE WHEN @sortColumn = 'Category' AND @sortOrder = 'DESC'
	 THEN T.Category END DESC ,

	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'ASC'
	 THEN T.Service END ASC, 
	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'DESC'
	 THEN T.Service END DESC ,

	 CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'ASC'
	 THEN T.StartDate END ASC, 
	 CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'DESC'
	 THEN T.StartDate END DESC ,

	 CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'ASC'
	 THEN T.EndDate END ASC, 
	 CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'DESC'
	 THEN T.EndDate END DESC ,

	 CASE WHEN @sortColumn = 'ServiceCoverageLimit' AND @sortOrder = 'ASC'
	 THEN T.ServiceCoverageLimit END ASC, 
	 CASE WHEN @sortColumn = 'ServiceCoverageLimit' AND @sortOrder = 'DESC'
	 THEN T.ServiceCoverageLimit END DESC ,

	 CASE WHEN @sortColumn = 'IsServiceCoverageBestValue' AND @sortOrder = 'ASC'
	 THEN T.IsServiceCoverageBestValue END ASC, 
	 CASE WHEN @sortColumn = 'IsServiceCoverageBestValue' AND @sortOrder = 'DESC'
	 THEN T.IsServiceCoverageBestValue END DESC ,

	 CASE WHEN @sortColumn = 'MaterialsCoverageLimit' AND @sortOrder = 'ASC'
	 THEN T.MaterialsCoverageLimit END ASC, 
	 CASE WHEN @sortColumn = 'MaterialsCoverageLimit' AND @sortOrder = 'DESC'
	 THEN T.MaterialsCoverageLimit END DESC ,

	 CASE WHEN @sortColumn = 'IsMaterialsMemberPay' AND @sortOrder = 'ASC'
	 THEN T.IsMaterialsMemberPay END ASC, 
	 CASE WHEN @sortColumn = 'IsMaterialsMemberPay' AND @sortOrder = 'DESC'
	 THEN T.IsMaterialsMemberPay END DESC ,

	 CASE WHEN @sortColumn = 'ServiceMileageLimit' AND @sortOrder = 'ASC'
	 THEN T.ServiceMileageLimit END ASC, 
	 CASE WHEN @sortColumn = 'ServiceMileageLimit' AND @sortOrder = 'DESC'
	 THEN T.ServiceMileageLimit END DESC ,

	 CASE WHEN @sortColumn = 'IsServiceMileageUnlimited' AND @sortOrder = 'ASC'
	 THEN T.IsServiceMileageUnlimited END ASC, 
	 CASE WHEN @sortColumn = 'IsServiceMileageUnlimited' AND @sortOrder = 'DESC'
	 THEN T.IsServiceMileageUnlimited END DESC ,

	 CASE WHEN @sortColumn = 'IsServiceMileageOverageAllowed' AND @sortOrder = 'ASC'
	 THEN T.IsServiceMileageOverageAllowed END ASC, 
	 CASE WHEN @sortColumn = 'IsServiceMileageOverageAllowed' AND @sortOrder = 'DESC'
	 THEN T.IsServiceMileageOverageAllowed END DESC ,

	 CASE WHEN @sortColumn = 'IsReimbersementOnly' AND @sortOrder = 'ASC'
	 THEN T.IsReimbersementOnly END ASC, 
	 CASE WHEN @sortColumn = 'IsReimbersementOnly' AND @sortOrder = 'DESC'
	 THEN T.IsReimbersementOnly END DESC 


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
DROP TABLE #FinalResults_temp
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
 -- EXEC dms_Program_Management_ProgramConfigurationList @programID = 1
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_ProgramConfigurationList]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_ProgramConfigurationList] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_ProgramConfigurationList]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID INT = NULL
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
ProgramConfigurationIDOperator="-1" 
ProgramIDOperator="-1" 
NameOperator="-1" 
ValueOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

CREATE TABLE #tmpForWhereClause
(
ProgramConfigurationIDOperator INT NOT NULL,
ProgramConfigurationIDValue int NULL,
ProgramIDOperator INT NOT NULL,
ProgramIDValue int NULL,
NameOperator INT NOT NULL,
NameValue nvarchar(50) NULL,
ValueOperator INT NOT NULL,
ValueValue nvarchar(50) NULL
)

CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramConfigurationID int  NULL ,
	ProgramID int  NULL ,
	Name nvarchar(MAX)  NULL ,
	Value nvarchar(MAX)  NULL ,
	IsActive nvarchar(50)  NULL 
) 
DECLARE @QueryResult AS TABLE( 
	ProgramConfigurationID int  NULL ,
	ProgramID int  NULL ,
	Name nvarchar(MAX)  NULL ,
	Value nvarchar(MAX)  NULL ,
	IsActive nvarchar(50)  NULL 
) 

;WITH wProgramConfig 
		AS
		(	SELECT ROW_NUMBER() OVER ( PARTITION BY PC.Name ORDER BY PP.Sequence) AS RowNum,
					PC.ID ProgramConfigurationID,
					PP.ProgramID,
					PP.Sequence,
					PC.Name,	
					PC.Value,
					PC.IsActive,
					CASE ISNULL(PC.IsActive,0) WHEN 0 THEN 'No' ELSE 'Yes' END IsActiveText
			FROM fnc_GetProgramsandParents(@ProgramID) PP
			JOIN ProgramConfiguration PC ON PP.ProgramID = PC.ProgramID AND PC.IsActive = 1
			JOIN ConfigurationType C ON PC.ConfigurationTypeID = C.ID 
			LEFT JOIN ConfigurationCategory CC ON PC.ConfigurationCategoryID = CC.ID
			--WHERE	(@ConfigurationType IS NULL OR C.Name = @ConfigurationType)
			--AND		(@ConfigurationCategory IS NULL OR CC.Name = @ConfigurationCategory)
		)
INSERT INTO @QueryResult SELECT W.ProgramConfigurationID,	
								W.ProgramID,
								W.Name,
								W.Value,
								W.IsActiveText
						FROM	wProgramConfig W
						 WHERE	W.RowNum = 1
					   ORDER BY W.Sequence


INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(ProgramConfigurationIDOperator,-1),
	ProgramConfigurationIDValue ,
	ISNULL(ProgramIDOperator,-1),
	ProgramIDValue ,
	ISNULL(NameOperator,-1),
	NameValue ,
	ISNULL(ValueOperator,-1),
	ValueValue 
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
ProgramConfigurationIDOperator INT,
ProgramConfigurationIDValue int 
,ProgramIDOperator INT,
ProgramIDValue int 
,NameOperator INT,
NameValue nvarchar(50) 
,ValueOperator INT,
ValueValue nvarchar(50) 
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.ProgramConfigurationID,
	T.ProgramID,
	T.Name,
	T.Value,
	T.IsActive
FROM @QueryResult T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.ProgramConfigurationIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 0 AND T.ProgramConfigurationID IS NULL ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 1 AND T.ProgramConfigurationID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 2 AND T.ProgramConfigurationID = TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 3 AND T.ProgramConfigurationID <> TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 7 AND T.ProgramConfigurationID > TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 8 AND T.ProgramConfigurationID >= TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 9 AND T.ProgramConfigurationID < TMP.ProgramConfigurationIDValue ) 
 OR 
	 ( TMP.ProgramConfigurationIDOperator = 10 AND T.ProgramConfigurationID <= TMP.ProgramConfigurationIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ProgramIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramIDOperator = 0 AND T.ProgramID IS NULL ) 
 OR 
	 ( TMP.ProgramIDOperator = 1 AND T.ProgramID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramIDOperator = 2 AND T.ProgramID = TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 3 AND T.ProgramID <> TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 7 AND T.ProgramID > TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 8 AND T.ProgramID >= TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 9 AND T.ProgramID < TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 10 AND T.ProgramID <= TMP.ProgramIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.NameOperator = -1 ) 
 OR 
	 ( TMP.NameOperator = 0 AND T.Name IS NULL ) 
 OR 
	 ( TMP.NameOperator = 1 AND T.Name IS NOT NULL ) 
 OR 
	 ( TMP.NameOperator = 2 AND T.Name = TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 3 AND T.Name <> TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 4 AND T.Name LIKE TMP.NameValue + '%') 
 OR 
	 ( TMP.NameOperator = 5 AND T.Name LIKE '%' + TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 6 AND T.Name LIKE '%' + TMP.NameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ValueOperator = -1 ) 
 OR 
	 ( TMP.ValueOperator = 0 AND T.Value IS NULL ) 
 OR 
	 ( TMP.ValueOperator = 1 AND T.Value IS NOT NULL ) 
 OR 
	 ( TMP.ValueOperator = 2 AND T.Value = TMP.ValueValue ) 
 OR 
	 ( TMP.ValueOperator = 3 AND T.Value <> TMP.ValueValue ) 
 OR 
	 ( TMP.ValueOperator = 4 AND T.Value LIKE TMP.ValueValue + '%') 
 OR 
	 ( TMP.ValueOperator = 5 AND T.Value LIKE '%' + TMP.ValueValue ) 
 OR 
	 ( TMP.ValueOperator = 6 AND T.Value LIKE '%' + TMP.ValueValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ProgramConfigurationID' AND @sortOrder = 'ASC'
	 THEN T.ProgramConfigurationID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramConfigurationID' AND @sortOrder = 'DESC'
	 THEN T.ProgramConfigurationID END DESC ,

	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'ASC'
	 THEN T.ProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'DESC'
	 THEN T.ProgramID END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Value' AND @sortOrder = 'ASC'
	 THEN T.Value END ASC, 
	 CASE WHEN @sortColumn = 'Value' AND @sortOrder = 'DESC'
	 THEN T.Value END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC 


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
WHERE id = object_id(N'[dbo].[dms_Program_Management_Information]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Program_Management_Information] 
END 
GO
CREATE PROC dms_Program_Management_Information(@ProgramID INT = NULL)
AS
BEGIN
	SELECT   
			   P.ID
			 , C.ID AS ClientID
			 , C.Name AS ClientName
			 , P.ParentProgramID AS ParentID
			 , PP.Name AS ParentName
			 , P.Name AS ProgramName
			 , P.Description AS ProgramDescription
			 , P.IsActive AS IsActive
			 , P.Code AS Code
			 , P.IsServiceGuaranteed
			 , P.CallFee
			 , P.DispatchFee
			 , P.IsAudited
			 , P.IsClosedLoopAutomated
			 , P.IsGroup
			 , '' AS PageMode
	FROM       Program P (NOLOCK)
	JOIN       Client C (NOLOCK) ON C.ID = P.ClientID
	LEFT JOIN  Program PP (NOLOCK) ON PP.ID = P.ParentProgramID
	WHERE      P.ID = @ProgramID
END


GO