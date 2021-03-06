/****** Object:  StoredProcedure [dbo].[dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	08/07/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- FORD for Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'FORD'
exec dbo.dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get @ProgramIDs, '09/01/2015', '09/30/2015', '1=1'

-- Queries to help in testing
select	*
from	[DatamartServer].cn_datamart.dbo.vwstellarcontactcalldetail with (nolock)
where	destinationdn like ('%8886546136')
and		convert(date, startdatetime) >= '10/01/2013'
and		convert(date, startdatetime) <= '10/31/2013'

select	*
from	dbo.vw_BillingPhoneSwitchCallDetail with (nolock)
where	destinationdn like ('%8886546136')
and		convert(date, startdatetime) >= '10/01/2013'
and		convert(date, startdatetime) <= '10/31/2013'

**/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Declare local variables
declare	@Debug as int,
		@RangeBeginDate as nvarchar(20),
		@RangeEndDate as nvarchar(20),
		@SQLString as nvarchar(max)


-- Initialize Local Variables
select	@Debug = 0
select	@SQLString = ''
select	@RangeBeginDate = convert(nvarchar(20), @pRangeBeginDate, 101),
		@RangeEndDate = convert(nvarchar(20), @pRangeEndDate, 101)


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Get ProgramIDs from Programs Table variable
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if object_id('tempdb..#tmpPrograms', 'U') is not null drop table #tmpPrograms
create table #tmpPrograms
(ProgramID	int)
create unique clustered index inx_tmpPrograms1 on #tmpPrograms(ProgramID)
insert into #tmpPrograms
(ProgramID)
select	ProgramID 
from	@pProgramIDs


if @Debug = 1
begin

	select	* from #tmpPrograms
	
end


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- THIS IS THE SQL THAT DEFINES THE EVENT!
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Build temp
if object_id('tempdb..#tmpViewData', 'U') is not null drop table #tmpViewData
select * into #tmpViewData from dbo.vw_BillingServiceRequestsPurchaseOrders where 1=0
--select * into #tmpViewData from dbo.vw_BillingPhoneSwitchCallDetail where 1=0


-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingServiceRequestsPurchaseOrders v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + 'and v.ServiceRequestDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DISPATCH = ''0''' -- No Dispatch
select	@SQLString = @SQLString + 'and v.IsTransferredCallToAgero = ''1''' -- Customer Assistance
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_ServiceRequest is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled

---- Build SQL String for Select
--select	@SQLString = @SQLString + 'insert into #tmpViewData '
--select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingPhoneSwitchCallDetail v '
--select	@SQLString = @SQLString + 'join #tmpPrograms pr on pr.ProgramID = v.ProgramID '
--select	@SQLString = @SQLString + 'where 1=1 '
--select	@SQLString = @SQLString + 'and convert(date, v.startdatetime) >= ''' + @RangeBeginDate + '''' -- Within the Range given
--select	@SQLString = @SQLString + 'and convert(date, v.startdatetime) <= ''' + @RangeEndDate + '''' -- Within the Range given
--select	@SQLString = @SQLString + 'and v.destinationdn like ''%8886546136''' -- System Created

-- Add additional Criteria
if @pEventFilter is not null
begin

	select	@SQLString = @SQLString + 'and ' + @pEventFilter

end


if @Debug = 1
begin

	select	'Programs', * from @pProgramIDs
	select	@pEventFilter as pEventFilter,
			@SQLString as SQLString
end


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Execute SQL String to shove data into temp
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exec(@SQLString)


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Get results columns for Detail
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
select	ProgramID,
		EntityID_ServiceRequest as EntityID,
		EntityKey_ServiceRequest as EntityKey,
		ServiceRequestDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData

--select	ProgramID,
--		EntityID, -- EntityID
--		EntityKey, -- EntityKey
--		startdatetime as EntityDate,
--		cast(1 as int)as BaseQuantity,
--		cast(null as float) as BaseAmount,
--		cast(null as float) as BasePercentage,
--		----		
--		cast(null as nvarchar(50)) as ServiceCode,
--		cast(null as nvarchar(50)) as BillingCode
--from	#tmpViewData

GO



GO
/****** Object:  StoredProcedure [dbo].[dms_Vendor_Location_Services_Service_List_Get]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Location_Services_Service_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Location_Services_Service_List_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC dms_Vendor_Location_Services_Service_List_Get @VendorID=1, @VendorLocationID=1
CREATE PROCEDURE [dbo].[dms_Vendor_Location_Services_Service_List_Get](
	@VendorID INT = NULL
 ,	@VendorLocationID INT = NULL
 )
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
DECLARE @FinalResults AS TABLE(
	ServiceName nvarchar(100)  NULL ,
	ProductID int  NULL ,
	VehicleCategorySequence int  NULL ,
	ProductCategory nvarchar(100)  NULL ,
	IsAvailByVendor bit default 0 ,
	IsAvailByVendorLocation bit default 0
) 

INSERT INTO @FinalResults (ServiceName,ProductID,VehicleCategorySequence,ProductCategory)
	SELECT p.Name AS ServiceName
		  ,p.ID AS ProductID
		  ,vc.Sequence VehicleCategorySequence
		  ,pc.Name ProductCategory
		FROM Product p
		Join ProductCategory pc on p.productCategoryid = pc.id
		Join ProductType pt on p.ProductTypeID = pt.ID
		Join ProductSubType pst on p.ProductSubTypeID = pst.id
		Left Outer Join VehicleCategory vc on p.VehicleCategoryID = vc.ID
		Left Outer Join VehicleType vt on p.VehicleTypeID = vt.ID
		Where pt.Name = 'Service'
		and pst.Name IN ('PrimaryService', 'SecondaryService')
		--and p.Name Not in ('Concierge', 'Information', 'Tech')
		--and p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee')
		AND ISNULL(P.ShowOnVendorMaintenance,0) = 1
		
	UNION
	SELECT p.Name AS ServiceName
		   ,p.ID AS ProductID
		   ,vc.Sequence VehicleCategorySequence
		   ,pc.Name ProductCategory
		FROM Product p
		Join ProductCategory pc on p.productCategoryid = pc.id
		Join ProductType pt on p.ProductTypeID = pt.ID
		Join ProductSubType pst on p.ProductSubTypeID = pst.id
		Left Outer Join VehicleCategory vc on p.VehicleCategoryID = vc.ID
		Left Outer Join VehicleType vt on p.VehicleTypeID = vt.ID
		Where pt.Name = 'Service'
		and pst.Name IN ('AdditionalService')
		--and p.Name Not in ('Concierge', 'Information', 'Tech')
		--and p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials')
		AND ISNULL(P.ShowOnVendorMaintenance,0) = 1
	ORDER BY ProductCategory,VehicleCategorySequence
	
	UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
WHERE VP.VendorID=@VendorID

UPDATE @FinalResults SET IsAvailByVendorLocation = 1 FROM  @FinalResults T
LEFT JOIN VendorLocationProduct VLP ON VLP.ProductID = T.ProductID
WHERE VLP.VendorLocationID=@VendorLocationID

Select *  from @FinalResults where IsAvailByVendor=1
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
 --[dms_activity_list] @serviceRequestID = 400319
-- EXEC [dbo].[dms_activity_list] @serviceRequestID = 1515,@whereClauseXML = '<ROW><Filter TypeOperator="11" TypeValue="Event Log,Contact Log"></Filter></ROW>'   
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
 QuestionAnswer nvarchar(max) NULL,
 EventName NVARCHAR(255) NULL
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
NULL AS [QuestionAnswer],
E.Name AS EventName
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
NULL AS [QuestionAnswer],
E.Name AS EventName
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
NULL AS [QuestionAnswer],
E.Name AS EventName
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
NULL AS [QuestionAnswer],
E.Name AS EventName
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
NULL AS [QuestionAnswer],
E.Name AS EventName
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
    CPDV.QuestionAnswer,
    NULL        
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
    CPDV.QuestionAnswer,
    NULL                     
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
    CPDV.QuestionAnswer,
    NULL                     
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
    CPDV.QuestionAnswer,
    NULL                     
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
    CPDV.QuestionAnswer,
    NULL                     
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
 NULL AS [QuestionAnswer],
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
 NULL AS [QuestionAnswer],
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
 NULL AS [QuestionAnswer],
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
 NULL AS [QuestionAnswer],
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
 NULL AS [QuestionAnswer],
 NULL        
 FROM Comment(NOLOCK) C
 JOIN Entity EN(NOLOCK) ON EN.ID = C.EntityID 
 LEFT JOIN CommentType(NOLOCK) CMT on CMT.ID = C.CommentTypeID   
 WHERE (C.EntityID = @PurchaseOrderEntityID AND C.RecordID IN (Select ID From @PurchaseOrderResult))
 ORDER BY CreateDate DESC
 
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
 
 ;WITH wELNextActionCleared
  AS
 (
	SELECT  ID,
			Type,
			EventName,
			Description,
			Comments
	FROM	@tmpFinalResults
	WHERE	ISNULL(EventName,'') = 'NextActionCleared'
 )
 --SELECT * FROM wELSaveOnFinish
 UPDATE @tmpFinalResults
 SET	Comments = CASE WHEN ISNULL(T.[Description],'') = '' THEN '' 
						ELSE [dbo].[fn_EventDetailForFinish_Get](T.[Description],'NextActionCleared') END,
		[Description] = 'Next Action Cleared'
 FROM	wELNextActionCleared W 
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
SELECT @count AS TotalRows, *, @eventLogCount as EventLogCount,@contactLogCount as ContactLogCount,@commentCount as commentCount FROM @FinalResults WHERE RowNum BETWEEN @startInd AND @endInd
--DROP TABLE #tmpFinalResults
--DROP TABLE #FinalResults
DROP TABLE #CustomProgramDynamicValues
END




GO



GO
/****** Object:  StoredProcedure [dbo].[dms_BillingAdditionalServicePassThru_Get]    Script Date: 09/28/2015 12:26:05 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_BillingAdditionalServicePassThru_Get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_BillingAdditionalServicePassThru_Get]
GO

/****** Object:  StoredProcedure [dbo].[dms_BillingAdditionalServicePassThru_Get]    Script Date: 09/28/2015 12:26:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[dms_BillingAdditionalServicePassThru_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'HPN2TOW'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.[dms_BillingAdditionalServicePassThru_Get] @ProgramIDs, '12/01/2013', '12/31/2013', 'ServiceCode='Customer Payout'

**/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Declare local variables
declare	@Debug as int,
		@RangeBeginDate as nvarchar(20),
		@RangeEndDate as nvarchar(20),
		@SQLString as nvarchar(max)


-- Initialize Local Variables
select	@Debug = 0
select	@SQLString = ''
select	@RangeBeginDate = convert(nvarchar(20), @pRangeBeginDate, 101),
		@RangeEndDate = convert(nvarchar(20), @pRangeEndDate, 101)


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Get ProgramIDs from Programs Table variable
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if object_id('tempdb..#tmpPrograms', 'U') is not null drop table #tmpPrograms
create table #tmpPrograms
(ProgramID	int)
create unique clustered index inx_tmpPrograms1 on #tmpPrograms(ProgramID)
insert into #tmpPrograms
(ProgramID)
select	ProgramID 
from	@pProgramIDs


if @Debug = 1
begin

	select	* from #tmpPrograms
	
end


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- THIS IS THE SQL THAT DEFINES THE EVENT!
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Build temp
if object_id('tempdb..#tmpViewData', 'U') is not null drop table #tmpViewData
select * into #tmpViewData from dbo.vw_BillingPurchaseOrderAdditionalService where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingPurchaseOrderAdditionalService v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + 'and v.PurchaseOrderDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID is null ' -- Not Invoiced ^1
select	@SQLString = @SQLString + 'and v.PurchaseOrderStatus in ' -- ^3
select	@SQLString = @SQLString + ' (''Issued'', ''Issued-Paid'') ' -- Issued ^3


-- Add additional Criteria
if @pEventFilter is not null
begin

	select	@SQLString = @SQLString + 'and ' + @pEventFilter

end


if @Debug = 1
begin

	select	'Programs', * from @pProgramIDs
	select	@pEventFilter as pEventFilter,
			@SQLString as SQLString
end


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Execute SQL String to shove data into temp
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exec(@SQLString)


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Get results columns for detail
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
select	ProgramID,
		EntityID_PurchaseOrder as EntityID,
		EntityKey_PurchaseOrder as EntityKey,
		PurchaseOrderDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(Amount as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		ServiceCode,
		ServiceCode as BillingCode
from	#tmpViewData



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
 WHERE id = object_id(N'[dbo].[dms_BillingDetailExceptions_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingDetailExceptions_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
CREATE PROCEDURE [dbo].[dms_BillingDetailExceptions_Get]  
@pUserName as nvarchar(50) = null,  
@pScheduleTypeID as int = null,  
@pScheduleDateTypeID as int,   
@pScheduleRangeTypeID as int,  
@pInvoicesXML as XML -- Eg: <Records><BillingDefinitionInvoiceID>1</BillingDefinitionInvoiceID><BillingDefinitionInvoiceID>2</BillingDefinitionInvoiceID></Records>

AS  
/********************************************************************  
 **  
 ** dms_BillingDetailExceptions_Get  
 **  
 ** Date  Added By Description  
 ** ---------- ---------- ----------------------------------------  
 ** 10/10/13 MJKrzysiak Created  
 **   
 ** 04/27/14 MJKrzysiak ^1 Changed validation to use VendorInvoice
 **						PaymentAmount instead of Amount on ESP over $200
 **  
 **********************************************************************/  
  
/**  
  
declare @Invoices as BillingDefinitionInvoiceTableType  
insert into @Invoices (BillingDefinitionInvoiceID)  
select distinct BillingDefinitionInvoiceID from dbo.BillingInvoiceDetail  
  
exec dbo.dms_BillingDetailExceptions_Get 'mjk_testing', 1, 1, 1, @Invoices  
  
/***  
--- Clear Exceptions  
if (select @@ServerName) = 'TRAVERSE\TEST'   
begin    
  truncate table BillingInvoiceDetailException   
  
 update BillingInvoiceDetail  
 set  InvoiceDetailDispositionID = (select ID from BillingInvoiceDetailDisposition where Name = 'REFRESH'),  
   InvoiceDetailStatusID = (select ID from BillingInvoiceDetailStatus where Name = 'READY')  
 where InvoiceDetailStatusID = (select ID from BillingInvoiceDetailStatus where Name = 'EXCEPTION')  
end  
***/  
  
**/  
  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
  
DECLARE @pInvoices as BillingDefinitionInvoiceTableType

INSERT INTO @pInvoices
SELECT  
		T.c.value('.','int')
FROM	@pInvoicesXML.nodes('/Records/BillingDefinitionInvoiceID') T(c)

-- Declare local variables  
declare @Debug as int,  
  @ProgramName as nvarchar(50),  
  @Now as datetime,  
  @ScheduleDateOPEN as date,  
  @ScheduleRangeEndOPEN as date,  
    
  @InvoiceCount as int,  
    
  @UserName as nvarchar(50),  
  
  @BillingCode_EntityID_SR as int,  
  @BillingCode_EntityID_PO as int,  
  @BillingCode_EntityID_VI as int,  
  @BillingCode_EntityID_CL as int,  
  
  @BillingCode_DetailStatus_PENDING as int,  
  @BillingCode_DetailStatus_READY as int,  
  @BillingCode_DetailStatus_ONHOLD as int,  
  @BillingCode_DetailStatus_EXCEPTION as int,  
  @BillingCode_DetailStatus_DELETED as int,  
    
  @BillingCode_DetailDisposition_LOCKED as int,  
  
  @BillingCode_DetailExceptionType_ZERO_DOLLAR_PO as int,  
  @BillingCode_DetailExceptionType_NO_MBRSHP_NUM as int,  
  @BillingCode_DetailExceptionType_NO_VIN as int,  
  @BillingCode_DetailExceptionType_NO_MILEAGE as int,  
  @BillingCode_DetailExceptionType_GOA_REDISPATCH as int,  
  @BillingCode_DetailExceptionType_GOA_ISP_CANC as int,  
  @BillingCode_DetailExceptionType_MILEAGE_OVER_60K as int,  
  @BillingCode_DetailExceptionType_AMT_OVER_$200 as int,  
  @BillingCode_DetailExceptionType_AMT_OVER_$100 as int,  
  @BillingCode_DetailExceptionType_AMT_OVER_$125 as int,  
  @BillingCode_DetailExceptionType_GOA as int,  
  @BillingCode_DetailExceptionType_PO_OVER_90_DAYS as int,  
  
  @BillingCode_DetailExceptionSeverity_WARNING as int,  
  @BillingCode_DetailExceptionSeverity_ERROR as int,  
    
  @BillingCode_DetailExceptionStatus_EXCEPTION as int,  
  @BillingCode_DetailExceptionStatus_RESOLVED as int  
    
  
-- Initialize Local Variables  
select @Debug = 0  
select @Now = getdate()  
select @ProgramName = object_name(@@procid)  
  
-- Capture Billing Codes to use  
set @BillingCode_EntityID_SR = (select ID from Entity where Name = 'ServiceRequest')  
set @BillingCode_EntityID_PO = (select ID from Entity where Name = 'PurchaseOrder')  
set @BillingCode_EntityID_VI = (select ID from Entity where Name = 'VendorInvoice')  
set @BillingCode_EntityID_CL = (select ID from Entity where Name = 'Claim')  
  
set @BillingCode_DetailStatus_READY = (select ID from dbo.BillingInvoiceDetailStatus where Name = 'READY')  
set @BillingCode_DetailStatus_PENDING = (select ID from dbo.BillingInvoiceDetailStatus where Name = 'PENDING')  
set @BillingCode_DetailStatus_ONHOLD = (select ID from dbo.BillingInvoiceDetailStatus where Name = 'ONHOLD')  
set @BillingCode_DetailStatus_EXCEPTION = (select ID from dbo.BillingInvoiceDetailStatus where Name = 'EXCEPTION')  
set @BillingCode_DetailStatus_DELETED = (select ID from dbo.BillingInvoiceDetailStatus where Name = 'DELETED')  
  
set @BillingCode_DetailDisposition_LOCKED = (select ID from dbo.BillingInvoiceDetailDisposition where Name = 'LOCKED')  
  
set @BillingCode_DetailExceptionType_ZERO_DOLLAR_PO = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'ZERO_DOLLAR_PO')  
set @BillingCode_DetailExceptionType_NO_MBRSHP_NUM = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'NO_MBRSHP_NUM')  
set @BillingCode_DetailExceptionType_NO_VIN = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'NO_VIN')  
set @BillingCode_DetailExceptionType_NO_MILEAGE = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'NO_MILEAGE')  
set @BillingCode_DetailExceptionType_GOA_REDISPATCH = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'GOA_REDISPATCH')  
set @BillingCode_DetailExceptionType_GOA_ISP_CANC = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'GOA_ISP_CANC')  
set @BillingCode_DetailExceptionType_MILEAGE_OVER_60K = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'MILEAGE_OVER_60K')  
set @BillingCode_DetailExceptionType_AMT_OVER_$200 = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'AMT_OVER_$200')  
set @BillingCode_DetailExceptionType_GOA = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'GOA')  
set @BillingCode_DetailExceptionType_PO_OVER_90_DAYS = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'PO_OVER_90_DAYS')  
set @BillingCode_DetailExceptionType_AMT_OVER_$100 = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'AMT_OVER_$100')  
set @BillingCode_DetailExceptionType_AMT_OVER_$125 = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'AMT_OVER_$125')  
  
set @BillingCode_DetailExceptionSeverity_WARNING = (select ID from dbo.BillingInvoiceDetailExceptionSeverity where Name = 'WARNING')  
set @BillingCode_DetailExceptionSeverity_ERROR = (select ID from dbo.BillingInvoiceDetailExceptionSeverity where Name = 'ERROR')  
  
set @BillingCode_DetailExceptionStatus_EXCEPTION = (select ID from dbo.BillingInvoiceDetailExceptionStatus where Name = 'EXCEPTION')  
set @BillingCode_DetailExceptionStatus_RESOLVED = (select ID from dbo.BillingInvoiceDetailExceptionStatus where Name = 'RESOLVED')  
  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
-- Capture the user name.  If null, then get from the  
-- ProgramName  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
if @pUserName is null  
begin  
  select @UserName = @ProgramName  
end  
else  
begin  
  select @UserName = @pUserName  
end  
  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
-- Capture the Open Schedule for the Schedule Type Passed in  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
if object_id('tempdb..#tmpOpenSchedule', 'U') is not null drop table #tmpOpenSchedule  
create table #tmpOpenSchedule  
(BillingScheduleID  int,  
 ScheduleTypeID   int,  
 ScheduleDateTypeID  int,  
 ScheduleRangeTypeID int)  
  
create index inx_tmpOpenSchedule1 on #tmpOpenSchedule (BillingScheduleID)  
create index inx_tmpOpenSchedule2 on #tmpOpenSchedule (ScheduleTypeID, ScheduleDateTypeID, ScheduleRangeTypeID)  
  
insert into #tmpOpenSchedule  
(BillingScheduleID,  
 ScheduleTypeID,  
 ScheduleDateTypeID,  
 ScheduleRangeTypeID)  
select top 1   
  bs.ID,  
  bs.ScheduleTypeID,  
  bs.ScheduleDateTypeID,  
  bs.ScheduleRangeTypeID 
 from dbo.BillingSchedule bs   
 join dbo.BillingScheduleType bst on bst.ID = bs.ScheduleTypeID  
 join dbo.BillingScheduleStatus bss on bss.ID = bs.ScheduleStatusID  
 where bss.Name IN ('OPEN','PENDING')  
 and bs.ScheduleTypeID = @pScheduleTypeID  
 and bs.ScheduleDateTypeID = @pScheduleDateTypeID  
 and bs.ScheduleRangeTypeID = @pScheduleRangeTypeID  
 order by  
  bs.ScheduleDate desc  
  
  
if @Debug = 1  
begin  
 select '#tmpOpenSchedule', * from #tmpOpenSchedule  
end  
  
  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
-- Capture Invoice Definition IDs from Invoices Table   
-- parameter...if null passed in to the Invoices parameter, then  
-- get all that are associated to "OPEN" schedule, of the given  
-- Schedule Type  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
if object_id('tempdb..#tmpInvoices', 'U') is not null drop table #tmpInvoices  
create table #tmpInvoices  
(RowID       int     identity,  
 BillingDefinitionInvoiceID  int)  
   
create index inx_tmpInvoices1 on #tmpInvoices(RowID)  
create index inx_tmpInvoices2 on #tmpInvoices (BillingDefinitionInvoiceID)  
  
select @InvoiceCount = isnull(count(*), 0) from @pInvoices  
if @InvoiceCount = 0 -- Get them all in open schedule  
begin  
  
 insert into #tmpInvoices  
 (BillingDefinitionInvoiceID)  
 select bdi.ID -- BillingDefinitionInvoiceID  
 from dbo.BillingDefinitionInvoice bdi with (nolock)  
 join #tmpOpenSchedule O on O.ScheduleTypeID = bdi.ScheduleTypeID -- Open Schedule  
    and O.ScheduleDateTypeID = bdi.ScheduleDateTypeID  
    and O.ScheduleRangeTypeID = bdi.ScheduleRangeTypeID  
 where 1=1  
 and  bdi.IsActive = 1 -- Invoice Def Must be Active  
  
end  
else  
begin  
 insert into #tmpInvoices  
 (BillingDefinitionInvoiceID)  
 select bdi.ID -- BillingDefinitionInvoiceID  
 from @pInvoices i  
 join dbo.BillingDefinitionInvoice bdi with (nolock) on bdi.ID = i.BillingDefinitionInvoiceID  
end  
  
if @Debug = 1  
begin  
 select '#tmpInvoices', * from #tmpInvoices  
end  
  
  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
-- Find Existing Exceptions that no longer meet Exception business rules  
-- Update these to READY  
-- Get into a temp so we can look in debug  
-- Process the Update  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
create table #tmpExistingExceptionsNoLonger  
(BillingInvoiceDetailID  int,  
 BillingInvoiceDetailExceptionID int)  
  
create index inx_tmpExistingExceptions1 on #tmpExistingExceptionsNoLonger (BillingInvoiceDetailID)  
  
insert into #tmpExistingExceptionsNoLonger  
(BillingInvoiceDetailID,  
 BillingInvoiceDetailExceptionID)  
select bid.ID,  
  bidx.ID  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
Join BillingDefinitionInvoiceLine bdil with (nolock) on bil.BillingDefinitionInvoiceLineID = bdil.ID
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
join Program pr with (nolock) on pr.ID = bid.ProgramID  
join BillingInvoiceDetailException bidx with (nolock) on bidx.BillingInvoiceDetailID = bid.ID  
left outer join vw_BillingServiceRequestsPurchaseOrders srv with (nolock) on srv.ServiceRequestID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'ServiceRequest')  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
left outer join vw_BillingVendorInvoices viv with (nolock) on viv.VendorInvoiceID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'VendorInvoice')  
left outer join vw_BillingClaims clv with (nolock) on clv.ClaimID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'Claim')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List      
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_SR, @BillingCode_EntityID_PO, @BillingCode_EntityID_VI, @BillingCode_EntityID_CL) -- Entities  
and  bid.InvoiceDetailStatusID = @BillingCode_DetailStatus_EXCEPTION -- Detail Status is Exception  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
and  bidx.InvoiceDetailExceptionStatusID = @BillingCode_DetailExceptionStatus_EXCEPTION -- Is Exception  
--- Exception Criteria  
---------------------------------------------------------------------------  
and  (  
  ---------------- Zero Dollar PO : ALL ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_ZERO_DOLLAR_PO -- Zero Dollar PO Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and pov.PurchaseOrderAmount <> 0.00) -- No longer Zero Dollar : PO Entity  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_ZERO_DOLLAR_PO -- Zero Dollar PO Exception : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and viv.PurchaseOrderAmount <> 0.00) -- No longer Zero Dollar : VI Entity  
   or  
  ---------------- No MembershipNumber : ALL but Atwood, PDG, PCG/TravelGuard, Coach-Net, Sea Tow, Select Hagerty Programs ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MBRSHP_NUM -- No MembershipNumber Exception : SR Entity  
   and srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR -- SR Entity  
   and cl.ID in (select ID from Client with (nolock) where Name not in 
		('Atwood', 'Professional Dispatch Group', 'Travel Guard', 'SeaTow','Coach-Net','Ford','Newell','Novum'))
   and bid.ProgramID Not IN (Select ID from Program Where Name IN 
		('Hagerty Special Programs','Hagerty - Member Assist','Hagerty - Secondary Tow','Hagerty - Non Standard'))
   and srv.MembershipNumber is not null) -- Now has MembershipNumber  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MBRSHP_NUM -- No MembershipNumber Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and cl.ID in (select ID from Client with (nolock) where Name not in 
		('Atwood', 'Professional Dispatch Group', 'Travel Guard', 'SeaTow','Coach-Net','Ford','Newell','Novum'))
   and bid.ProgramID Not IN (Select ID from Program Where Name IN 
		('Hagerty Special Programs','Hagerty - Member Assist','Hagerty - Secondary Tow','Hagerty - Non Standard'))
   and pov.MembershipNumber is not null) -- Now has MembershipNumber  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MBRSHP_NUM -- No MembershipNumber Exception : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and cl.ID in (select ID from Client with (nolock) where Name not in 
		('Atwood', 'Professional Dispatch Group', 'Travel Guard', 'SeaTow','Coach-Net','Ford','Newell','Novum'))
   and bid.ProgramID Not IN (Select ID from Program Where Name IN 
		('Hagerty Special Programs','Hagerty - Member Assist','Hagerty - Secondary Tow','Hagerty - Non Standard'))
   and viv.MembershipNumber is not null) -- Now has MembershipNumber  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MBRSHP_NUM -- No MembershipNumber Exception : CL Entity  
   and clv.EntityID = @BillingCode_EntityID_CL -- CL Entity  
   and cl.ID in (select ID from Client with (nolock) where Name not in 
		('Atwood', 'Professional Dispatch Group', 'Travel Guard', 'SeaTow','Coach-Net','Ford','Newell','Novum'))
   and bid.ProgramID Not IN (Select ID from Program Where Name IN 
		('Hagerty Special Programs','Hagerty - Member Assist','Hagerty - Secondary Tow','Hagerty - Non Standard'))
   and clv.MembershipNumber is not null) -- Now has MembershipNumber  
   or  
  ---------------- No VIN : FORD ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_VIN -- No VIN Exception : SR Entity  
   and srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR -- SR Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and srv.MemberID IS NOT NULL   ---- Exclude Non-Member calls
   --and bdil.[Description] <> 'Call Transfer - To Agero'
   and srv.VIN is not null) -- Now has VIN  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_VIN --  No VIN Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and pov.VIN is not null) -- Now has VIN  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_VIN --  No VIN Exception : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and viv.VIN is not null) -- Now has VIN  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_VIN --  No VIN Exception : CL Entity  
   and clv.EntityID = @BillingCode_EntityID_CL -- CL Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and clv.VIN is not null) -- Now has VIN  
   or  
  ---------------- No Mileage : FORD ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MILEAGE -- No Mileage Exception : SR Entity  
   and srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR -- SR Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and srv.MemberID IS NOT NULL   ---- Exclude Non-Member calls
   --and bdil.[Description] <> 'Call Transfer - To Agero'
   and isnull(srv.VehicleCurrentMileage, 0) > 0) -- Now has Mileage  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MILEAGE --  No Mileage Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and isnull(pov.VehicleCurrentMileage, 0) > 0) -- Now has Mileage  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MILEAGE --  No Mileage Exception : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and isnull(viv.VehicleCurrentMileage, 0) > 0) -- Now has Mileage  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MILEAGE --  No Mileage Exception : CL Entity  
   and clv.EntityID = @BillingCode_EntityID_CL -- CL Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and isnull(clv.VehicleCurrentMileage, 0) > 0) -- Now has Mileage  
  or  
  ---------------- Mileage Over 60K : FORD exclude ESP & Direct Tow ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_MILEAGE_OVER_60K -- Over 60K Exception : SR Entity  
   and srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR -- SR Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')
   and pr.ID not in (select ID from Program with (nolock) where Code in ('FORDESP_MFG', 'FORDTOW'))  
   and isnull(srv.VehicleCurrentMileage, 0) <= 60000) -- Now under 60K  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_MILEAGE_OVER_60K --  Over 60K Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')
   and pr.ID not in (select ID from Program with (nolock) where Code in ('FORDESP_MFG', 'FORDTOW')) 
   and isnull(pov.VehicleCurrentMileage, 0) <= 60000) -- Now under 60K  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_MILEAGE_OVER_60K --  Over 60K Exception : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')
   and pr.ID not in (select ID from Program with (nolock) where Code in ('FORDESP_MFG', 'FORDTOW'))  
   and isnull(viv.VehicleCurrentMileage, 0) <= 60000) -- Now under 60K  
  or  
  ---------------- Amount over $200 : FORDESP ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$200 --  Amount Over $200 Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and pr.ID in (select ID from Program with (nolock) where Code = 'FORDESP_MFG')     
   and isnull(pov.PurchaseOrderAmount, 0) <= 200) -- Now $200 or less
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$200 --  Amount Over $200 Exception : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and pr.ID in (select ID from Program with (nolock) where Code = 'FORDESP_MFG')     
--   and isnull(viv.PurchaseOrderAmount, 0) <= 200) -- Now $200 or less
   and isnull(viv.PaymentAmount, 0) <= 200) -- Now $200 or less  ^1 Changed to PaymentAmount
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$200 --  Amount Over $200 Excpetion : CL Entity  
   and clv.EntityID = @BillingCode_EntityID_CL -- CL Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and pr.ID in (select ID from Program with (nolock) where Code = 'FORDESP_MFG')     
   and isnull(clv.PaymentAmount, 0) <= 200) -- Now $200 or less  
  or  
  ---------------- Amount over $100 : NMC ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$100 --  Amount Over $100 Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'NMC')  
   and pr.ID in (select ID from Program with (nolock) where Name IN ('NMCA','Security Shield','Security Roadside','Small Group'))     
   and isnull(pov.PurchaseOrderAmount, 0) <= 100) -- Now $100 or less
   or
  ---------------- Amount over $125 : NMC ASSOC (SafeDriver) ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$125 --  Amount Over $125 Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   --and cl.ID in (select ID from Client with (nolock) where Name = 'NMC')  
   and pr.ID in (select ID from Program with (nolock) where Name IN ('Association'))     
   and isnull(pov.PurchaseOrderAmount, 0) <= 125) -- Now $125 or less
   or
  ---------------- GOA - : ALL ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_GOA_REDISPATCH -- GOA : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and pov.GOAReason is null) -- No longer GOA  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_GOA_REDISPATCH -- GOA : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and viv.ServiceCode is null) -- No longer GOA  
  ) 
  
  
if @Debug = 1  
begin  
 select '#tmpExistingExceptionsNoLonger', * from #tmpExistingExceptionsNoLonger  
end  
else  
begin  
  
 -- Update the Exception Status to READY  
 update BillingInvoiceDetailException  
 set  InvoiceDetailExceptionStatusID = @BillingCode_DetailExceptionStatus_RESOLVED,  
   ExceptionAuthorizationDate = @Now,  
   ModifyDate = @Now,  
   ModifyBy = @ProgramName  
 from BillingInvoiceDetailException bidx  
 join #tmpExistingExceptionsNoLonger tmp on tmp.BillingInvoiceDetailExceptionID = bidx.ID  
  
 -- Update the Detail Status to PENDING  
 update BillingInvoiceDetail  
 set  InvoiceDetailStatusID = @BillingCode_DetailStatus_PENDING,  
   ModifyDate = @Now,  
   ModifyBy = @ProgramName  
 from BillingInvoiceDetail bid  
 join #tmpExistingExceptionsNoLonger tmp on tmp.BillingInvoiceDetailID = bid.ID  
 where not exists  
 -- Do not update the detail on those that have another PENDING exception other than the type at hand  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID <> @BillingCode_DetailExceptionType_ZERO_DOLLAR_PO  
   and InvoiceDetailExceptionStatusID = @BillingCode_DetailExceptionStatus_EXCEPTION)  
  
end  
  
  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
-- Create Exceptions  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
create table #tmpExceptions  
(BillingInvoiceDetailID int,  
 InvoiceDetailExceptionTypeID int,  
 InvoiceDetailExceptionStatusID int,  
 InvoiceDetailExceptionSeverityID int,  
 InvoiceDetailExceptionComment nvarchar(max),  
 ExceptionAuthorization nvarchar(100),  
 ExceptionAuthorizationDate datetime,  
 Sequence int,  
 IsActive bit,  
 CreateDate datetime,  
 CreateBy nvarchar(50),  
 ModifyDate datetime,  
 ModifyBy nvarchar(50)  
 )  
  
create index inx_tmpExceptions1 on #tmpExceptions (BillingInvoiceDetailID)  
  
------------------------------------  
-- Zero Dollar PO : ALL  
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_ZERO_DOLLAR_PO, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
left outer join vw_BillingVendorInvoices viv with (nolock) on viv.VendorInvoiceID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'VendorInvoice')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_PO, @BillingCode_EntityID_VI) -- PO, VI Entities Only  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
-------- Exception Criteria  
and  (  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO  
    and pov.PurchaseOrderAmount = 0.00 -- Zero Dollar  
    and pov.IsMemberPay = 0) -- Is not Member Pay  
  or  
   (viv.EntityID = @BillingCode_EntityID_VI -- VI  
    and viv.PurchaseOrderAmount = 0.00 -- Zero Dollar  
    and viv.IsMemberPay = 0) -- Is not Member Pay  
   )    
and  not exists   
  -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_ZERO_DOLLAR_PO)  
  
  
------------------------------------  
-- No Membership Number : ALL but Atwood, PDG,Travel Guard, and others
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_NO_MBRSHP_NUM, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
left outer join vw_BillingServiceRequestsPurchaseOrders srv with (nolock) on srv.ServiceRequestID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'ServiceRequest')  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
left outer join vw_BillingVendorInvoices viv with (nolock) on viv.VendorInvoiceID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'VendorInvoice')  
left outer join vw_BillingClaims clv with (nolock) on clv.ClaimID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'Claim')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_SR, @BillingCode_EntityID_PO, @BillingCode_EntityID_VI, @BillingCode_EntityID_CL) -- Entities Only  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked
and		cl.ID in (select ID from Client with (nolock) where Name not in 
	('Atwood', 'Professional Dispatch Group', 'Travel Guard', 'SeaTow', 'Coach-Net','Ford','Newell','Novum'))
and bid.ProgramID Not IN (Select ID from Program Where Name IN 
	('Hagerty Special Programs','Hagerty - Member Assist','Hagerty - Secondary Tow','Hagerty - Non Standard'))
-------- Exception Criteria  
and  (  
   (srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR and srv.MembershipNumber is null)  
   or  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and pov.MembershipNumber is null)  
   or  
   (viv.EntityID = @BillingCode_EntityID_VI and viv.MembershipNumber is null)  
   or  
   (clv.EntityID = @BillingCode_EntityID_CL and clv.MembershipNumber is null)  
  )  
and  not exists   
  -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MBRSHP_NUM)  
  
  
------------------------------------  
-- No VIN : FORD  
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_NO_VIN, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
left outer join vw_BillingServiceRequestsPurchaseOrders srv with (nolock) on srv.ServiceRequestID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'ServiceRequest')  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
left outer join vw_BillingVendorInvoices viv with (nolock) on viv.VendorInvoiceID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'VendorInvoice')  
left outer join vw_BillingClaims clv with (nolock) on clv.ClaimID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'Claim')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_SR, @BillingCode_EntityID_PO, @BillingCode_EntityID_VI, @BillingCode_EntityID_CL) -- Entities  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
and  cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
and  srv.MemberID IS NOT NULL   ---- Exclude Non-Member calls
-------- Exception Criteria  
and  (  
   (srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR and srv.VIN is null)  
   or  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and pov.VIN is null)  
   or  
   (viv.EntityID = @BillingCode_EntityID_VI and viv.VIN is null)  
   or  
   (clv.EntityID = @BillingCode_EntityID_CL and clv.VIN is null)  
  )  
and  not exists   
  -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_VIN)  
  
  
------------------------------------  
-- No Mileage : FORD  
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_NO_MILEAGE, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
left outer join vw_BillingServiceRequestsPurchaseOrders srv with (nolock) on srv.ServiceRequestID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'ServiceRequest')  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
left outer join vw_BillingVendorInvoices viv with (nolock) on viv.VendorInvoiceID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'VendorInvoice')  
left outer join vw_BillingClaims clv with (nolock) on clv.ClaimID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'Claim')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_SR, @BillingCode_EntityID_PO, @BillingCode_EntityID_VI, @BillingCode_EntityID_CL) -- Entities  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
and  cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
and  srv.MemberID IS NOT NULL   ---- Exclude Non-Member calls
-------- Exception Criteria  
and  (  
   (srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR and isnull(srv.VehicleCurrentMileage, 0) <= 0)  
   or  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and isnull(pov.VehicleCurrentMileage, 0) <= 0)  
   or  
   (viv.EntityID = @BillingCode_EntityID_VI and isnull(viv.VehicleCurrentMileage, 0) <= 0)  
   or  
   (clv.EntityID = @BillingCode_EntityID_CL and isnull(clv.VehicleCurrentMileage, 0) <= 0)  
  )  
and  not exists   
  -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MILEAGE)  
  
  
------------------------------------  
-- Mileage Over 60K : FORD exclude ESP & Direct Tow
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_MILEAGE_OVER_60K, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
join Program pr with (nolock) on pr.ID = bid.ProgramID  
left outer join vw_BillingServiceRequestsPurchaseOrders srv with (nolock) on srv.ServiceRequestID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'ServiceRequest')  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
left outer join vw_BillingVendorInvoices viv with (nolock) on viv.VendorInvoiceID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'VendorInvoice')  
left outer join vw_BillingClaims clv with (nolock) on clv.ClaimID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'Claim')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_SR, @BillingCode_EntityID_PO, @BillingCode_EntityID_VI, @BillingCode_EntityID_CL) -- Entities  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
and  cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
and  pr.ID not in (select ID from Program with (nolock) where Code in ('FORDESP_MFG', 'FORDTOW'))
-------- Exception Criteria  
and  (  
   (srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR and isnull(srv.VehicleCurrentMileage, 0) > 60000)  
   or  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and isnull(pov.VehicleCurrentMileage, 0) > 60000)  
   or  
   (viv.EntityID = @BillingCode_EntityID_VI and isnull(viv.VehicleCurrentMileage, 0) > 60000)  
   or  
   (clv.EntityID = @BillingCode_EntityID_CL and isnull(clv.VehicleCurrentMileage, 0) > 60000)  
  )  
and  not exists   
  -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_MILEAGE_OVER_60K)  
  
  
------------------------------------  
-- Amount Over $200 : FORD ESP  
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_AMT_OVER_$200, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
join Program pr with (nolock) on pr.ID = bid.ProgramID  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
left outer join vw_BillingVendorInvoices viv with (nolock) on viv.VendorInvoiceID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'VendorInvoice')  
left outer join vw_BillingClaims clv with (nolock) on clv.ClaimID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'Claim')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_PO, @BillingCode_EntityID_VI, @BillingCode_EntityID_CL) -- Entities  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
and  cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
and  pr.ID in (select ID from Program with (nolock) where Code = 'FORDESP_MFG')
-------- Exception Criteria  
and  (  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and isnull(pov.PurchaseOrderAmount, 0) > 200)  
   or  
--   (viv.EntityID = @BillingCode_EntityID_VI and isnull(viv.PurchaseOrderAmount, 0) > 100)  
   (viv.EntityID = @BillingCode_EntityID_VI and isnull(viv.PaymentAmount, 0) > 200)  -- ^1 Changed to PaymentAmount
   or  
   (clv.EntityID = @BillingCode_EntityID_CL and isnull(clv.PaymentAmount, 0) > 200)  
  )  
and  not exists     -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$200)  
  
  
------------------------------------  
-- Amount Over $100 : NMC  
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_AMT_OVER_$100, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
join Program pr with (nolock) on pr.ID = bid.ProgramID  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_PO, @BillingCode_EntityID_VI, @BillingCode_EntityID_CL) -- Entities  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
and cl.ID in (select ID from Client with (nolock) where Name = 'NMC')  
and pr.ID in (select ID from Program with (nolock) where Name IN ('NMCA','Security Shield','Security Roadside','Small Group'))     
-------- Exception Criteria  
and  (  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and isnull(pov.PurchaseOrderAmount, 0) > 100)  
  )  
and  not exists     -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$100)  
  
  
  
------------------------------------  
-- Amount Over $125 : NMC Association (Safedriver)  
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_AMT_OVER_$125, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
join Program pr with (nolock) on pr.ID = bid.ProgramID  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_PO, @BillingCode_EntityID_VI, @BillingCode_EntityID_CL) -- Entities  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
--and cl.ID in (select ID from Client with (nolock) where Name = 'NMC')  
and pr.ID in (select ID from Program with (nolock) where Name IN ('Association'))     
-------- Exception Criteria  
and  (  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and isnull(pov.PurchaseOrderAmount, 0) > 125)  
  )  
and  not exists     -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$125)  
  
  
  
------------------------------------  
-- GOA : ALL  
-- Exclude Member Cancel GOAs for Internal Clients - CNET, PMC, NMC, Safe Driver, Atlantic Internet, Ford 
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_GOA, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
join Program pr with (nolock) on pr.ID = bid.ProgramID  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
left outer join vw_BillingVendorInvoices viv with (nolock) on viv.VendorInvoiceID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'VendorInvoice')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_PO, @BillingCode_EntityID_VI) -- Entities  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
-------- Exception Criteria  
and  (  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and pov.GOAReason is not null)  
   or  
   (viv.EntityID = @BillingCode_EntityID_VI and viv.GOAReason is not null)  
  )  
---- Exclude Member Cancel GOAs for Internal Clients - CNET, PMC, NMC, Safe Driver, Ford, Atlantic Internet  
and NOT (pr.ClientID IN (SELECT ID FROM Client WHERE Name in 
			('Coach-Net', 'National Motor Club', 'Pinnacle Motor Club', 'Safe Driver', 'Ford', 'Atlantic Internet')) 
		AND (ISNULL(pov.GOAReason,'') = 'Member Cancel' OR ISNULL(viv.GOAReason,'') = 'Member Cancel')
		)

---- Exclude those that already have an Exception of this type  
and  not exists   
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_GOA)  
  

------------------------------------  
-- ALL: POs older than 90 days  
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_PO_OVER_90_DAYS, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
join Program pr with (nolock) on pr.ID = bid.ProgramID  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
Join BillingSchedule bs on bs.ID = bid.BillingScheduleID
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_PO) -- Entities  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
-------- Exception Criteria  
and  bid.EntityDate < DATEADD(dd, -90, bs.ScheduleRangeBegin)

  
  
if @Debug = 1  
begin  
 select '#tmpExceptions', b.Name, *   
 from #tmpExceptions t  
 join BillingInvoiceDetailExceptionType b on b.ID = t.InvoiceDetailExceptionTypeID  
 order by b.Name  
end  
else  
begin  
  
 -- Create the Exception  
 insert into dbo.BillingInvoiceDetailException  
 (BillingInvoiceDetailID,  
  InvoiceDetailExceptionTypeID,  
  InvoiceDetailExceptionStatusID,  
  InvoiceDetailExceptionSeverityID,  
  InvoiceDetailExceptionComment,  
  ExceptionAuthorization,  
  ExceptionAuthorizationDate,  
  Sequence,  
  IsActive,  
  CreateDate,  
  CreateBy,  
  ModifyDate,  
  ModifyBy  
  )  
 select BillingInvoiceDetailID,  
   InvoiceDetailExceptionTypeID,  
   InvoiceDetailExceptionStatusID,  
   InvoiceDetailExceptionSeverityID,  
   InvoiceDetailExceptionComment,  
   ExceptionAuthorization,  
   ExceptionAuthorizationDate,  
   Sequence,  
   IsActive,  
   CreateDate,  
   CreateBy,  
   ModifyDate,  
   ModifyBy  
 from #tmpExceptions  
  
 -- Set the Detail Status to EXCEPTION  
 update BillingInvoiceDetail  
 set  InvoiceDetailStatusID = @BillingCode_DetailStatus_EXCEPTION,  
   ModifyDate = @Now,  
   ModifyBy = @ProgramName  
 from BillingInvoiceDetail bid  
 join #tmpExceptions tmp on tmp.BillingInvoiceDetailID = bid.ID  
  
end  
  



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
 WHERE id = object_id(N'[dbo].[dms_BillingManageInvoicesList]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingManageInvoicesList] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC dms_BillingManageInvoicesList @pMode= 'OPEN',@pageSize=12
  -- EXEC dms_BillingManageInvoicesList @pMode= 'Closed',@pageSize=12
 CREATE PROCEDURE [dbo].[dms_BillingManageInvoicesList](   
   @whereClauseXML XML = NULL 
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 1   
 , @sortColumn nvarchar(100)  = 'ID'   
 , @sortOrder nvarchar(100) = 'DESC'   
 , @pMode nvarchar(50)='OPEN'
 )   
 AS   
  BEGIN     
 SET FMTONLY OFF;    
  SET NOCOUNT ON    
 
 DECLARE @tmpForWhereClause TABLE
(
ScheduleDateFrom DATETIME NULL,
ScheduleDateTo DATETIME NULL,
ClientID INT NULL,
BillingDefinitionInvoiceID INT NULL,
LineStatuses NVARCHAR(MAX) NULL,
InvoiceStatuses NVARCHAR(MAX) NULL,
BillingDefinitionInvoiceLines NVARCHAR(MAX) NULL
)
 
  CREATE TABLE #tmpFinalResults(     
     [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
     ID INT NULL,    
       
     InvoiceDescription nvarchar(255) NULL,    
     BillingScheduleID int NULL,    
     BillingSchedule nvarchar(50) NULL,    
     BillingScheduleTypeID nvarchar(50) NULL,    
     BillingScheduleType nvarchar(50) NULL,    
     ScheduleDate DATETIME NULL,    
     ScheduleRangeBegin DATETIME NULL,    
     ScheduleRangeEnd DATETIME NULL,    
     InvoiceNumber nvarchar(7) NULL,    
     InvoiceDate DATETIME NULL,    
     InvoiceStatusID int NULL,    
     InvoiceStatus nvarchar(50) NULL,  
     TotalDetailCount int NULL,    
     TotalDetailAmount money NULL,    
     ReadyToBillCount int NULL,    
     ReadyToBillAmount money NULL,    
     PendingCount int NULL,    
     PendingAmount money NULL,         
     ExcludedCount int NULL,    
     ExceptionAmount money NULL,         
     ExceptionCount int NULL,    
     ExcludedAmount money NULL,         
     OnHoldCount int NULL,    
     OnHoldAmount money NULL,         
     PostedCount int NULL,    
     PostedAmount money NULL,    
     BillingDefinitionInvoiceID int NULL,    
     ClientID int NULL,    
     InvoiceName nvarchar(50) NULL,    
     PONumber nvarchar(100) NULL,    
     AccountingSystemCustomerNumber nvarchar(7) NULL,    
     ClientName nvarchar(50) NULL,  
     CanAddLines BIT NULL  ,  
     BilingScheduleStatus nvarchar(100) NULL ,  
     ScheduleDateTypeID  INT NULL,  
     ScheduleRangeTypeID INT NULL  ,
     AccountingSystemAddressCode NVARCHAR(100) NULL
  )    
      
  CREATE TABLE #FinalResults(     
     [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
     ID INT NULL,    
     InvoiceDescription nvarchar(255) NULL,    
     BillingScheduleID int NULL,    
     BillingSchedule nvarchar(50) NULL,    
     BillingScheduleTypeID nvarchar(50) NULL,    
     BillingScheduleType nvarchar(50) NULL,    
     ScheduleDate DATETIME NULL,    
     ScheduleRangeBegin DATETIME NULL,    
     ScheduleRangeEnd DATETIME NULL,    
     InvoiceNumber nvarchar(7) NULL,    
     InvoiceDate DATETIME NULL,    
     InvoiceStatusID int NULL,    
     InvoiceStatus nvarchar(50) NULL,  
     TotalDetailCount int NULL,    
     TotalDetailAmount money NULL,    
     ReadyToBillCount int NULL,    
     ReadyToBillAmount money NULL,    
     PendingCount int NULL,    
     PendingAmount money NULL,         
     ExcludedCount int NULL,    
     ExceptionAmount money NULL,         
     ExceptionCount int NULL,    
     ExcludedAmount money NULL,         
     OnHoldCount int NULL,    
     OnHoldAmount money NULL,         
     PostedCount int NULL,    
     PostedAmount money NULL,    
     BillingDefinitionInvoiceID int NULL,    
     ClientID int NULL,    
     InvoiceName nvarchar(50) NULL,    
     PONumber nvarchar(100) NULL,    
     AccountingSystemCustomerNumber nvarchar(7) NULL,    
     ClientName nvarchar(50) NULL,  
     CanAddLines BIT NULL   ,  
     BilingScheduleStatus nvarchar(100) NULL ,  
     ScheduleDateTypeID  INT NULL,  
     ScheduleRangeTypeID INT NULL  ,
     AccountingSystemAddressCode NVARCHAR(100) NULL
  )    

INSERT INTO @tmpForWhereClause
SELECT  
		T.c.value('@ScheduleDateFrom','datetime'),
		T.c.value('@ScheduleDateTo','datetime'),
		T.c.value('@ClientID','int') ,
		T.c.value('@BillingDefinitionInvoiceID','int') ,
		T.c.value('@LineStatuses','NVARCHAR(MAX)'),
		T.c.value('@InvoiceStatuses','NVARCHAR(MAX)'), 
		T.c.value('@BillingDefinitionInvoiceLines','NVARCHAR(MAX)') 
				
		
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @ScheduleDateFrom DATETIME ,
@ScheduleDateTo DATETIME ,
@ClientID INT ,
@BillingDefinitionInvoiceID INT ,
@LineStatuses NVARCHAR(MAX) ,
@InvoiceStatuses NVARCHAR(MAX),
@BillingDefinitionInvoiceLines NVARCHAR(MAX)

SELECT	@ScheduleDateFrom = T.ScheduleDateFrom ,
		@ScheduleDateTo = T.ScheduleDateTo,
		@ClientID = T.ClientID ,
		@BillingDefinitionInvoiceID = T.BillingDefinitionInvoiceID ,
		@LineStatuses = T.LineStatuses ,
		@InvoiceStatuses = T.InvoiceStatuses,
		@BillingDefinitionInvoiceLines = T.BillingDefinitionInvoiceLines
FROM	@tmpForWhereClause T

DECLARE @sql NVARCHAR(MAX) = ''

  --INSERT INTO #tmpFinalResults
  
  SET @sql = ' SELECT   DISTINCT' 
  SET @sql = @sql + ' BI.ID, ' 
  SET @sql = @sql + ' BI.[Description], '
  SET @sql = @sql + ' BI.BillingScheduleID, '
  SET @sql = @sql + ' BS.Name, '
  SET @sql = @sql + ' BS.ScheduleTypeID, '   
  SET @sql = @sql + ' BST.Name, '
  SET @sql = @sql + ' BI.ScheduleDate, '
  SET @sql = @sql + ' BI.ScheduleRangeBegin, '
  SET @sql = @sql + ' BI.ScheduleRangeEnd, '
  SET @sql = @sql + ' BI.InvoiceNumber, '
  SET @sql = @sql + ' BI.InvoiceDate, '
  SET @sql = @sql + ' BI.InvoiceStatusID, '
  SET @sql = @sql + ' BIS.Name, '  
  SET @sql = @sql + ' DTLData.TotalDetailCount, '
  SET @sql = @sql + ' DTLData.TotalDetailAmount, '
  SET @sql = @sql + ' DTLData.ReadyToBillCount, '
  SET @sql = @sql + ' DTLData.ReadyToBillAmount, '
  SET @sql = @sql + ' DTLData.PendingCount, '
  SET @sql = @sql + ' DTLData.PendingAmount, '
  SET @sql = @sql + ' DTLData.ExceptionCount, '
  SET @sql = @sql + ' DTLData.ExceptionAmount, '
  SET @sql = @sql + ' DTLData.ExcludedCount, '
  SET @sql = @sql + ' DTLData.ExcludedAmount, '
  SET @sql = @sql + ' DTLData.OnHoldCount, '
  SET @sql = @sql + ' DTLData.OnHoldAmount, '
  SET @sql = @sql + ' DTLData.PostedCount, '
  SET @sql = @sql + ' DTLData.PostedAmount, '
  SET @sql = @sql + ' BI.BillingDefinitionInvoiceID, '
  SET @sql = @sql + ' BI.ClientID, '
  SET @sql = @sql + ' BI.Name, '
  SET @sql = @sql + ' isnull(bi.POPrefix, '''') + isnull(bi.PONumber, '''') as PONumber, '
  SET @sql = @sql + ' BI.AccountingSystemCustomerNumber, '
  SET @sql = @sql + ' cl.Name , '
  SET @sql = @sql + ' bi.CanAddLines, '
  SET @sql = @sql + ' bss.Name AS BilingScheduleStatus , '
  SET @sql = @sql + ' bdi.ScheduleDateTypeID,  '
  SET @sql = @sql + ' bdi.ScheduleRangeTypeID  , '
  SET @sql = @sql + ' bi.AccountingSystemAddressCode '
   SET @sql = @sql + ' from BillingInvoice bi with (nolock) '
  SET @sql = @sql + ' left outer join BillingDefinitionInvoice bdi with(nolock) on bdi.ID=bi.BillingDefinitionInvoiceID  '
  SET @sql = @sql + ' left outer join BillingInvoiceLine bil with (nolock) on bil.BillingInvoiceID = bi.ID ' 
  SET @sql = @sql + ' left outer join BillingDefinitionInvoiceLine bdil with(nolock) on bdil.BillingDefinitionInvoiceID = bdi.ID ' 
  SET @sql = @sql + ' left outer join BillingSchedule bs with (nolock) on bs.ID = bi.BillingScheduleID '  
  SET @sql = @sql + ' left outer join Client cl with (nolock) on cl.ID = bi.ClientID '  
  SET @sql = @sql + ' left outer join Product pr with (nolock) on pr.ID = bil.ProductID ' 
  SET @sql = @sql + ' left outer join RateType rt with (nolock) on rt.ID = bil.RateTypeID  ' 
  SET @sql = @sql + ' left outer join BillingInvoiceStatus bis with (nolock) on bis.ID = bi.InvoiceStatusID ' 
  SET @sql = @sql + ' left outer join BillingInvoiceLineStatus bils with (nolock) on bils.ID = bil.InvoiceLineStatusID ' 
  SET @sql = @sql + ' left outer join BillingScheduleType bst with (nolock) on bst.ID = bs.ScheduleTypeID ' 
  SET @sql = @sql + ' left outer join dbo.BillingScheduleStatus bss with (nolock) on bss.ID = bs.ScheduleStatusID '
  SET @sql = @sql + ' left outer join ( '
  SET @sql = @sql + ' select RS.InvoiceID, '
  SET @sql = @sql + ' isnull(sum(case when RS.Name <> ''DELETED'' then ISNULL(RS.TotalCount,0) else 0 end), 0) as TotalDetailCount, '
  SET @sql = @sql + ' isnull(sum(case when RS.Name <> ''DELETED'' then RS.Amount else 0 end), 0) as TotalDetailAmount, '
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''READY'' then ISNULL(RS.TotalCount,0) else 0 end), 0) as ReadyToBillCount, '
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''READY'' then RS.Amount else 0.00 end), 0.00) as ReadyToBillAmount, '
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''PENDING'' then ISNULL(RS.TotalCount,0) else 0 end), 0) as PendingCount,'
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''PENDING'' then RS.Amount else 0.00 end), 0.00) as PendingAmount, '
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''EXCEPTION'' then ISNULL(RS.TotalCount,0) else 0 end), 0) as ExceptionCount, '
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''EXCEPTION'' then RS.Amount else 0.00 end), 0.00) as ExceptionAmount,  ' 
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''EXCLUDED'' then ISNULL(RS.TotalCount,0) else 0 end), 0) as ExcludedCount, '
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''EXCLUDED'' then RS.Amount else 0.00 end), 0.00) as ExcludedAmount, '	  
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''ONHOLD'' then ISNULL(RS.TotalCount,0) else 0 end), 0) as OnHoldCount, ' 
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''ONHOLD'' then RS.Amount else 0.00 end), 0.00) as OnHoldAmount,  '  
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''POSTED'' then ISNULL(RS.TotalCount,0) else 0 end), 0) as PostedCount,  '  
  SET @sql = @sql + ' isnull(sum(case when RS.Name = ''POSTED'' then RS.Amount else 0.00 end), 0.00) as PostedAmount '
  SET @sql = @sql + ' FROM ('
  SET @sql = @sql + ' select bi.ID as InvoiceID, '
  SET @sql = @sql + ' bids.Name AS Name, '
  SET @sql = @sql + ' COUNT(*) As TotalCount, '
  SET @sql = @sql + ' SUM(ISNULL(bid.AdjustmentAmount,0)) As Amount '
  SET @sql = @sql + ' from BillingInvoice bi with (nolock) '  
  SET @sql = @sql + ' left outer join BillingInvoiceLine bil with (nolock) on bil.BillingInvoiceID = bi.ID  '
  SET @sql = @sql + ' left outer join BillingInvoiceDetail bid with (nolock) on bid.BillingInvoiceLineID = bil.ID  '
  SET @sql = @sql + ' left outer join BillingInvoiceDetailStatus bids with (nolock) on bids.ID = bid.InvoiceDetailStatusID  '
  SET @sql = @sql + ' where isnull(bid.IsAdjusted,0)= 1 and bid.InvoiceDetailStatusID  is not null '
  SET @sql = @sql + ' group by  bi.ID,bids.Name,bid.IsAdjusted	 '
  SET @sql = @sql + ' UNION ALL '
  SET @sql = @sql + ' select	bi.ID as InvoiceID,  '
  SET @sql = @sql + ' bids.Name AS Name, '
  SET @sql = @sql + ' COUNT(*) As TotalCount, '		
  SET @sql = @sql + ' SUM(ISNULL(bid.EventAmount,0)) AS Amount	'
  SET @sql = @sql + ' from BillingInvoice bi with (nolock) '  
  SET @sql = @sql + ' left outer join BillingInvoiceLine bil with (nolock) on bil.BillingInvoiceID = bi.ID  '
  SET @sql = @sql + ' left outer join BillingInvoiceDetail bid with (nolock) on bid.BillingInvoiceLineID = bil.ID  '
  SET @sql = @sql + ' left outer join BillingInvoiceDetailStatus bids with (nolock) on bids.ID = bid.InvoiceDetailStatusID  '
  SET @sql = @sql + ' where isnull(bid.IsAdjusted,0)= 0 and bid.InvoiceDetailStatusID  is not null '
  SET @sql = @sql + ' group by  bi.ID,bids.Name,bid.IsAdjusted	 '
  SET @sql = @sql + ' )RS '
  SET @sql = @sql + ' GROUP BY RS.InvoiceID '
  SET @sql = @sql + ' ) as DTLData on DTLData.InvoiceID = bi.ID '
  SET @sql = @sql + ' where 1=1'
   
   IF @pMode IS NOT NULL
   SET @sql = @sql + ' AND (bss.Name = @pMode)'
   
   IF @ScheduleDateFrom IS NOT NULL
   SET @sql = @sql + ' AND	(bs.ScheduleDate >= @ScheduleDateFrom ) '
   
   IF @ScheduleDateTo IS NOT NULL
   SET @sql = @sql + ' AND	( bs.ScheduleDate < DATEADD(DD,1,@ScheduleDateTo) ) '
   
   IF @ClientID IS NOT NULL
   SET @sql = @sql + ' AND	( @ClientID = cl.ID) '
   
   IF @BillingDefinitionInvoiceID IS NOT NULL
   SET @sql = @sql + ' AND	( @BillingDefinitionInvoiceID = bdi.ID) '
   
   IF @InvoiceStatuses IS NOT NULL
   SET @sql = @sql + ' AND	( bis.ID IN (SELECT item FROM [dbo].[fnSplitString](@InvoiceStatuses,'','') )) '
   
   IF @BillingDefinitionInvoiceLines IS NOT NULL
   SET @sql = @sql + ' AND	( bdil.ID IN (SELECT item FROM [dbo].[fnSplitString](@BillingDefinitionInvoiceLines,'','') )) '	
   
   SET @sql = @sql + ' order by  BI.ID,  '
   SET @sql = @sql + ' BI.[Description], '
   SET @sql = @sql + ' BI.BillingScheduleID,  '
   SET @sql = @sql + ' BS.Name, '
   SET @sql = @sql + ' BS.ScheduleTypeID, '   
   SET @sql = @sql + ' BST.Name, '
   SET @sql = @sql + ' BI.ScheduleDate, ' 
   SET @sql = @sql + ' BI.ScheduleRangeBegin, '
   SET @sql = @sql + ' BI.ScheduleRangeEnd, '
   SET @sql = @sql + ' BI.InvoiceNumber, '
   SET @sql = @sql + ' BI.InvoiceDate, '
   SET @sql = @sql + ' BI.InvoiceStatusID, '
   SET @sql = @sql + ' BIS.Name, '
   SET @sql = @sql + ' DTLData.TotalDetailCount,  '
   SET @sql = @sql + ' DTLData.TotalDetailAmount, '
   SET @sql = @sql + ' DTLData.ReadyToBillCount, '
   SET @sql = @sql + ' DTLData.ReadyToBillAmount, '
   SET @sql = @sql + ' DTLData.PendingCount, '
   SET @sql = @sql + ' DTLData.PendingAmount, '
   SET @sql = @sql + ' DTLData.ExceptionCount,   '
   SET @sql = @sql + ' DTLData.ExceptionAmount,  '
   SET @sql = @sql + ' DTLData.ExcludedCount,  '
   SET @sql = @sql + ' DTLData.ExcludedAmount,  '
   SET @sql = @sql + ' DTLData.OnHoldCount,  '
   SET @sql = @sql + ' DTLData.OnHoldAmount,    '
   SET @sql = @sql + ' DTLData.PostedCount,  '
   SET @sql = @sql + ' DTLData.PostedAmount,  '
   SET @sql = @sql + ' BI.BillingDefinitionInvoiceID,    '
   SET @sql = @sql + ' BI.ClientID,    '
   SET @sql = @sql + ' BI.Name,    '
   SET @sql = @sql + ' isnull(bi.POPrefix, '''') + isnull(bi.PONumber, ''''),  '
   SET @sql = @sql + ' BI.AccountingSystemCustomerNumber,    '
   SET @sql = @sql + ' cl.Name ,  '
   SET @sql = @sql + ' bi.CanAddLines,  '
   SET @sql = @sql + ' bss.Name  ,  '
   SET @sql = @sql + ' bdi.ScheduleDateTypeID,  '
   SET @sql = @sql + ' bdi.ScheduleRangeTypeID  ,'
   SET @sql = @sql + ' bi.AccountingSystemAddressCode '
   SET @sql = @sql + ' OPTION (RECOMPILE) '
   
    INSERT INTO #tmpFinalResults
		EXEC sp_executesql @sql, N'@pMode NVARCHAR(50), @ScheduleDateFrom DATETIME, @ScheduleDateTo DATETIME, 
@ClientID INT, @BillingDefinitionInvoiceID INT, @InvoiceStatuses NVARCHAR(MAX), @BillingDefinitionInvoiceLines NVARCHAR(MAX)',
		@pMode, @ScheduleDateFrom, @ScheduleDateTo, @ClientID, @BillingDefinitionInvoiceID, @InvoiceStatuses, @BillingDefinitionInvoiceLines
    
  
    
      
  INSERT INTO #FinalResults    
SELECT     
 T.ID,    
 T.InvoiceDescription,    
 T.BillingScheduleID,    
 T.BillingSchedule,    
 T.BillingScheduleTypeID,    
 T.BillingScheduleType,    
 T.ScheduleDate,    
 T.ScheduleRangeBegin,    
 T.ScheduleRangeEnd,    
 T.InvoiceNumber,    
 T.InvoiceDate,    
 T.InvoiceStatusID,    
 T.InvoiceStatus,    
 ISNULL(T.TotalDetailCount,  0),  
 ISNULL(T.TotalDetailAmount, 0),   
 ISNULL(T.ReadyToBillCount,  0),  
 ISNULL(T.ReadyToBillAmount, 0),   
 ISNULL(T.PendingCount,    	 0),
 ISNULL(T.PendingAmount,     0),
 ISNULL(T.ExceptionCount,    0),
 ISNULL(T.ExceptionAmount,   0),
 ISNULL(T.ExcludedCount,     0),
 ISNULL(T.ExcludedAmount,    0),
 ISNULL(T.OnHoldCount,    	 0),
 ISNULL(T.OnHoldAmount,   	 0),
 ISNULL(T.PostedCount,    	 0),
 ISNULL(T.PostedAmount,    	 0),
 T.BillingDefinitionInvoiceID,    
 T.ClientID,    
 T.InvoiceName,    
 T.PONumber,    
 T.AccountingSystemCustomerNumber,    
 T.ClientName,  
 T.CanAddLines ,  
 T.BilingScheduleStatus ,  
 T.ScheduleDateTypeID,  
 T.ScheduleRangeTypeID  ,
 T.AccountingSystemAddressCode
 FROM #tmpFinalResults T    
    ORDER BY     
  CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'    
  THEN T.ID END ASC,     
  CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'    
  THEN T.ID END DESC    ,

	 CASE WHEN @sortColumn = 'InvoiceDescription' AND @sortOrder = 'ASC'
	 THEN T.InvoiceDescription END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDescription' AND @sortOrder = 'DESC'
	 THEN T.InvoiceDescription END DESC ,

	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'ASC'
	 THEN T.BillingScheduleID END ASC, 
	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'DESC'
	 THEN T.BillingScheduleID END DESC ,

	 CASE WHEN @sortColumn = 'BillingSchedule' AND @sortOrder = 'ASC'
	 THEN T.BillingSchedule END ASC, 
	 CASE WHEN @sortColumn = 'BillingSchedule' AND @sortOrder = 'DESC'
	 THEN T.BillingSchedule END DESC ,

	 CASE WHEN @sortColumn = 'BillingScheduleTypeID' AND @sortOrder = 'ASC'
	 THEN T.BillingScheduleTypeID END ASC, 
	 CASE WHEN @sortColumn = 'BillingScheduleTypeID' AND @sortOrder = 'DESC'
	 THEN T.BillingScheduleTypeID END DESC ,

	 CASE WHEN @sortColumn = 'BillingScheduleType' AND @sortOrder = 'ASC'
	 THEN T.BillingScheduleType END ASC, 
	 CASE WHEN @sortColumn = 'BillingScheduleType' AND @sortOrder = 'DESC'
	 THEN T.BillingScheduleType END DESC ,

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

	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN T.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN T.InvoiceNumber END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'ASC'
	 THEN T.InvoiceDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'DESC'
	 THEN T.InvoiceDate END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceStatusID' AND @sortOrder = 'ASC'
	 THEN T.InvoiceStatusID END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceStatusID' AND @sortOrder = 'DESC'
	 THEN T.InvoiceStatusID END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'ASC'
	 THEN T.InvoiceStatus END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'DESC'
	 THEN T.InvoiceStatus END DESC ,

	 CASE WHEN @sortColumn = 'TotalDetailCount' AND @sortOrder = 'ASC'
	 THEN T.TotalDetailCount END ASC, 
	 CASE WHEN @sortColumn = 'TotalDetailCount' AND @sortOrder = 'DESC'
	 THEN T.TotalDetailCount END DESC ,

	 CASE WHEN @sortColumn = 'TotalDetailAmount' AND @sortOrder = 'ASC'
	 THEN T.TotalDetailAmount END ASC, 
	 CASE WHEN @sortColumn = 'TotalDetailAmount' AND @sortOrder = 'DESC'
	 THEN T.TotalDetailAmount END DESC ,

	 CASE WHEN @sortColumn = 'ReadyToBillCount' AND @sortOrder = 'ASC'
	 THEN T.ReadyToBillCount END ASC, 
	 CASE WHEN @sortColumn = 'ReadyToBillCount' AND @sortOrder = 'DESC'
	 THEN T.ReadyToBillCount END DESC ,

	 CASE WHEN @sortColumn = 'ReadyToBillAmount' AND @sortOrder = 'ASC'
	 THEN T.ReadyToBillAmount END ASC, 
	 CASE WHEN @sortColumn = 'ReadyToBillAmount' AND @sortOrder = 'DESC'
	 THEN T.ReadyToBillAmount END DESC ,

	 CASE WHEN @sortColumn = 'PendingCount' AND @sortOrder = 'ASC'
	 THEN T.PendingCount END ASC, 
	 CASE WHEN @sortColumn = 'PendingCount' AND @sortOrder = 'DESC'
	 THEN T.PendingCount END DESC ,

	 CASE WHEN @sortColumn = 'PendingAmount' AND @sortOrder = 'ASC'
	 THEN T.PendingAmount END ASC, 
	 CASE WHEN @sortColumn = 'PendingAmount' AND @sortOrder = 'DESC'
	 THEN T.PendingAmount END DESC ,

	 CASE WHEN @sortColumn = 'ExcludedCount' AND @sortOrder = 'ASC'
	 THEN T.ExcludedCount END ASC, 
	 CASE WHEN @sortColumn = 'ExcludedCount' AND @sortOrder = 'DESC'
	 THEN T.ExcludedCount END DESC ,

	 CASE WHEN @sortColumn = 'ExceptionAmount' AND @sortOrder = 'ASC'
	 THEN T.ExceptionAmount END ASC, 
	 CASE WHEN @sortColumn = 'ExceptionAmount' AND @sortOrder = 'DESC'
	 THEN T.ExceptionAmount END DESC ,

	 CASE WHEN @sortColumn = 'ExceptionCount' AND @sortOrder = 'ASC'
	 THEN T.ExceptionCount END ASC, 
	 CASE WHEN @sortColumn = 'ExceptionCount' AND @sortOrder = 'DESC'
	 THEN T.ExceptionCount END DESC ,

	 CASE WHEN @sortColumn = 'ExcludedAmount' AND @sortOrder = 'ASC'
	 THEN T.ExcludedAmount END ASC, 
	 CASE WHEN @sortColumn = 'ExcludedAmount' AND @sortOrder = 'DESC'
	 THEN T.ExcludedAmount END DESC ,

	 CASE WHEN @sortColumn = 'OnHoldCount' AND @sortOrder = 'ASC'
	 THEN T.OnHoldCount END ASC, 
	 CASE WHEN @sortColumn = 'OnHoldCount' AND @sortOrder = 'DESC'
	 THEN T.OnHoldCount END DESC ,

	 CASE WHEN @sortColumn = 'OnHoldAmount' AND @sortOrder = 'ASC'
	 THEN T.OnHoldAmount END ASC, 
	 CASE WHEN @sortColumn = 'OnHoldAmount' AND @sortOrder = 'DESC'
	 THEN T.OnHoldAmount END DESC ,

	 CASE WHEN @sortColumn = 'PostedCount' AND @sortOrder = 'ASC'
	 THEN T.PostedCount END ASC, 
	 CASE WHEN @sortColumn = 'PostedCount' AND @sortOrder = 'DESC'
	 THEN T.PostedCount END DESC ,

	 CASE WHEN @sortColumn = 'PostedAmount' AND @sortOrder = 'ASC'
	 THEN T.PostedAmount END ASC, 
	 CASE WHEN @sortColumn = 'PostedAmount' AND @sortOrder = 'DESC'
	 THEN T.PostedAmount END DESC ,

	 CASE WHEN @sortColumn = 'BillingDefinitionInvoiceID' AND @sortOrder = 'ASC'
	 THEN T.BillingDefinitionInvoiceID END ASC, 
	 CASE WHEN @sortColumn = 'BillingDefinitionInvoiceID' AND @sortOrder = 'DESC'
	 THEN T.BillingDefinitionInvoiceID END DESC ,

	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'ASC'
	 THEN T.ClientID END ASC, 
	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'DESC'
	 THEN T.ClientID END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceName' AND @sortOrder = 'ASC'
	 THEN T.InvoiceName END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceName' AND @sortOrder = 'DESC'
	 THEN T.InvoiceName END DESC ,

	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'
	 THEN T.PONumber END ASC, 
	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'
	 THEN T.PONumber END DESC ,

	 CASE WHEN @sortColumn = 'AccountingSystemCustomerNumber' AND @sortOrder = 'ASC'
	 THEN T.AccountingSystemCustomerNumber END ASC, 
	 CASE WHEN @sortColumn = 'AccountingSystemCustomerNumber' AND @sortOrder = 'DESC'
	 THEN T.AccountingSystemCustomerNumber END DESC ,

	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'ASC'
	 THEN T.ClientName END ASC, 
	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'DESC'
	 THEN T.ClientName END DESC ,

	 CASE WHEN @sortColumn = 'CanAddLines' AND @sortOrder = 'ASC'
	 THEN T.CanAddLines END ASC, 
	 CASE WHEN @sortColumn = 'CanAddLines' AND @sortOrder = 'DESC'
	 THEN T.CanAddLines END DESC ,

	 CASE WHEN @sortColumn = 'BilingScheduleStatus' AND @sortOrder = 'ASC'
	 THEN T.BilingScheduleStatus END ASC, 
	 CASE WHEN @sortColumn = 'BilingScheduleStatus' AND @sortOrder = 'DESC'
	 THEN T.BilingScheduleStatus END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleDateTypeID' AND @sortOrder = 'ASC'
	 THEN T.ScheduleDateTypeID END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleDateTypeID' AND @sortOrder = 'DESC'
	 THEN T.ScheduleDateTypeID END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeTypeID' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeTypeID END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeTypeID' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeTypeID END DESC  ,

	 CASE WHEN @sortColumn = 'AccountingSystemAddressCode' AND @sortOrder = 'ASC'
	 THEN T.AccountingSystemAddressCode END ASC, 
	 CASE WHEN @sortColumn = 'AccountingSystemAddressCode' AND @sortOrder = 'DESC'
	 THEN T.AccountingSystemAddressCode END DESC  
      
      
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
     
 DROP TABLE #FinalResults    
 DROP TABLE #tmpFinalResults    
 END 
GO
/****** Object:  StoredProcedure [dbo].[dms_BillingServiceEventWithPO_Get]    Script Date: 09/28/2015 12:27:58 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_BillingServiceEventWithPO_Get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_BillingServiceEventWithPO_Get]
GO

/****** Object:  StoredProcedure [dbo].[dms_BillingServiceEventWithPO_Get]    Script Date: 09/28/2015 12:27:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[dms_BillingServiceEventWithPO_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'NEWELL'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.[dms_BillingServiceEvent_Get] @ProgramIDs, '9/01/2015', '9/30/2015', '1=1'

**/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Declare local variables
declare	@Debug as int,
		@RangeBeginDate as nvarchar(20),
		@RangeEndDate as nvarchar(20),
		@SQLString as nvarchar(max)


-- Initialize Local Variables
select	@Debug = 0
select	@SQLString = ''
select	@RangeBeginDate = convert(nvarchar(20), @pRangeBeginDate, 101),
		@RangeEndDate = convert(nvarchar(20), @pRangeEndDate, 101)


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Get ProgramIDs from Programs Table variable
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if object_id('tempdb..#tmpPrograms', 'U') is not null drop table #tmpPrograms
create table #tmpPrograms
(ProgramID	int)
create unique clustered index inx_tmpPrograms1 on #tmpPrograms(ProgramID)
insert into #tmpPrograms
(ProgramID)
select	ProgramID 
from	@pProgramIDs


if @Debug = 1
begin

	select	* from #tmpPrograms
	
end


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- THIS IS THE SQL THAT DEFINES THE EVENT!
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Build temp
if object_id('tempdb..#tmpViewData', 'U') is not null drop table #tmpViewData
select * into #tmpViewData from dbo.vw_BillingServiceRequestsPurchaseOrders where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingServiceRequestsPurchaseOrders v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given ^1
--select	@SQLString = @SQLString + 'and v.PurchaseOrderDate<= ''' + @RangeEndDate + '''' -- Within the Range given ^1
select	@SQLString = @SQLString + 'and v.IsDispatched = 1 ' 
select	@SQLString = @SQLString + 'and v.GOAReason IS NULL ' 
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_PurchaseOrder is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled
select	@SQLString = @SQLString + 'and v.PurchaseOrderIsActive = 1'


-- Add additional Criteria
if @pEventFilter is not null
begin

	select	@SQLString = @SQLString + 'and ' + @pEventFilter

end


if @Debug = 1
begin

	select	'Programs', * from @pProgramIDs
	select	@pEventFilter as pEventFilter,
			@SQLString as SQLString
end


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Execute SQL String to shove data into temp
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exec(@SQLString)


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Get results columns for detail
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
select	ProgramID,
		EntityID_ServiceRequest, 
		EntityKey_ServiceRequest,
		ServiceRequestDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		MAX(ServiceCode) ServiceCode,
		MAX(ServiceCode) as BillingCode
from	#tmpViewData
GROUP BY 
		ProgramID,
		EntityID_ServiceRequest, 
		EntityKey_ServiceRequest,
		ServiceRequestDate





GO



GO
/****** Object:  StoredProcedure [dbo].[dms_BillingServiceEventWithPO_MileageOverage_Get]    Script Date: 09/28/2015 12:27:20 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_BillingServiceEventWithPO_MileageOverage_Get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_BillingServiceEventWithPO_MileageOverage_Get]
GO

/****** Object:  StoredProcedure [dbo].[dms_BillingServiceEventWithPO_MileageOverage_Get]    Script Date: 09/28/2015 12:27:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[dms_BillingServiceEventWithPO_MileageOverage_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as

/**
-- Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'NEWELL'
exec dbo.[dms_BillingServiceEventWithPO_MileageOverage_Get] @ProgramIDs, '9/01/2015', '9/30/2015', '25'

**/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Declare local variables
declare	@Debug as int,
		@RangeBeginDate as nvarchar(20),
		@RangeEndDate as nvarchar(20),
		@SQLString as nvarchar(max)


-- Initialize Local Variables
select	@Debug = 0
select	@SQLString = ''
select	@RangeBeginDate = convert(nvarchar(20), @pRangeBeginDate, 101),
		@RangeEndDate = convert(nvarchar(20), @pRangeEndDate, 101)


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Get ProgramIDs from Programs Table variable
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if object_id('tempdb..#tmpPrograms', 'U') is not null drop table #tmpPrograms
create table #tmpPrograms
(ProgramID	int)
create unique clustered index inx_tmpPrograms1 on #tmpPrograms(ProgramID)
insert into #tmpPrograms
(ProgramID)
select	ProgramID 
from	@pProgramIDs


if @Debug = 1
begin

	select	* from #tmpPrograms
	
end


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- THIS IS THE SQL THAT DEFINES THE EVENT!
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Build temp
if object_id('tempdb..#tmpViewData', 'U') is not null drop table #tmpViewData
select * into #tmpViewData from dbo.vw_BillingServiceRequestsPurchaseOrders where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingServiceRequestsPurchaseOrders v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + 'and v.ServiceRequestDate<= ''' + @RangeEndDate + '''' -- Within the Range given ^1
--select	@SQLString = @SQLString + 'and v.PurchaseOrderDate<= ''' + @RangeEndDate + '''' -- Within the Range given ^1
select	@SQLString = @SQLString + 'and v.IsDispatched = 1 ' 
select	@SQLString = @SQLString + 'and v.GOAReason IS NULL ' 
select	@SQLString = @SQLString + 'and v.AccountingInvoiceBatchID_PurchaseOrder is null ' -- Not Invoiced
select	@SQLString = @SQLString + 'and v.ServiceRequestStatus in '
select	@SQLString = @SQLString + ' (''Complete'', ''Cancelled'') ' -- Complete or Cancelled
select	@SQLString = @SQLString + 'and v.PurchaseOrderIsActive = 1'


-- Add additional Criteria
-- Event Filter is Mileage Limie
if @pEventFilter is not null
begin

	select	@SQLString = @SQLString + 'and ServiceMiles > ' + @pEventFilter

end


if @Debug = 1
begin

	select	'Programs', * from @pProgramIDs
	select	@pEventFilter as pEventFilter,
			@SQLString as SQLString
end


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Execute SQL String to shove data into temp
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exec(@SQLString)


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Get results columns for detail
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
select	ProgramID,
		EntityID_ServiceRequest, 
		EntityKey_ServiceRequest,
		ServiceRequestDate as EntityDate,
		cast((MAX(ServiceMiles) - CONVERT(int, @pEventFilter)) as int) as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		MAX(ServiceCode) ServiceCode,
		MAX(ServiceCode) as BillingCode
from	#tmpViewData
GROUP BY 
		ProgramID,
		EntityID_ServiceRequest, 
		EntityKey_ServiceRequest,
		ServiceRequestDate





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
    , ISNULL(REPLACE(ae.Line2,CHAR(0),''),'') AS Member_AddressLine2
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
 WHERE id = object_id(N'[dbo].[dms_Claims_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Claims_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dbo].[dms_Claims_List_Get]@sortColumn='AmountApproved' ,@endInd=50,@pageSize=50,@whereClauseXML='<ROW><Filter ClaimAmountFrom="0"/></ROW>',@sortOrder='DESC'
 CREATE PROCEDURE [dbo].[dms_Claims_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF;
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDType=""
IDValue=""
NameType=""
NameOperator=""
NameValue=""
ClaimTypes=""
ClaimStatuses=""
ClaimCategories=""
ClientID=""
ProgramID=""
ExportBatchID=""
 ></Filter></ROW>'
END

--CREATE TABLE #tmpForWhereClause
DECLARE @tmpForWhereClause TABLE
(
IDType			NVARCHAR(50) NULL,
IDValue			NVARCHAR(100) NULL,
NameType		NVARCHAR(50) NULL,
NameOperator	NVARCHAR(50) NULL,
NameValue		NVARCHAR(MAX) NULL,
ClaimTypes		NVARCHAR(MAX) NULL,
ClaimStatuses	NVARCHAR(MAX) NULL,
ClaimCategories	NVARCHAR(MAX) NULL,
ClientID		INT NULL,
ProgramID		INT NULL,
Preset			INT NULL,
ClaimDateFrom	DATETIME NULL,
ClaimDateTo		DATETIME NULL,
ClaimAmountFrom	MONEY NULL,
ClaimAmountTo	MONEY NULL,
CheckNumber		NVARCHAR(50) NULL,
CheckDateFrom	DATETIME NULL,
CheckDateTo		DATETIME NULL,
ExportBatchID	INT NULL,
ACESSubmitFromDate DATETIME NULL,
ACESSubmitToDate DATETIME NULL,
ACESClearedFromDate DATETIME NULL,
ACESClearedToDate DATETIME NULL,
ACESStatus NVARCHAR(MAX) NULL,
ReceivedFromDate DATETIME NULL,
ReceivedToDate DATETIME NULL
)
 CREATE TABLE #FinalResultsFiltered( 	
	ClaimID			INT  NULL ,
	ClaimType		NVARCHAR(100)  NULL ,
	ClaimDate		DATETIME  NULL ,
	ReceivedDate	DATETIME  NULL ,
	AmountRequested MONEY  NULL ,
	Payeee			NVARCHAR(100)  NULL ,
	ClaimStatus		NVARCHAR(100)  NULL ,
	NextAction		NVARCHAR(100)  NULL ,
	AssignedTo		NVARCHAR(100)  NULL ,
	NextActionScheduledDate DATETIME  NULL ,
	ACESSubmitDate	DATETIME  NULL ,
	CheckNumber		NVARCHAR(100)  NULL ,
	PaymentDate		DATETIME  NULL ,
	PaymentAmount	MONEY  NULL,
	CheckClearedDate DATETIME NULL,
	AuthorizationCount	BIGINT NULL,
	InProcessCount	BIGINT NULL,
	CancelledCount	BIGINT NULL,
	ApprovedCount	BIGINT NULL,
	DeniedCount	BIGINT NULL,
	ReadyForPaymentCount BIGINT NULL,
	PaidCount		BIGINT NULL,
	ExceptionCount		BIGINT NULL,
	ClaimExceptionDetails NVARCHAR(MAX) NULL,
	MembershipNumber NVARCHAR(100) NULL,
	ProgramName NVARCHAR(100) NULL,
	BatchID INT NULL,
	AmountApproved MONEY  NULL ,
	ACESStatus nvarchar(100) NULL ,
	ACESClearedDate DATETIME NULL,
	ACESFeeAmount MONEY NULL
) 

CREATE TABLE #FinalResultsSorted( 
	[RowNum]		[BIGINT]	NOT NULL IDENTITY(1,1),
	ClaimID			INT  NULL ,
	ClaimType		NVARCHAR(100)  NULL ,
	ClaimDate		DATETIME  NULL ,
	ReceivedDate	DATETIME  NULL ,
	AmountRequested MONEY  NULL ,
	Payeee			NVARCHAR(100)  NULL ,
	ClaimStatus		NVARCHAR(100)  NULL ,
	NextAction		NVARCHAR(100)  NULL ,
	AssignedTo		NVARCHAR(100)  NULL ,
	NextActionScheduledDate DATETIME  NULL ,
	ACESSubmitDate	DATETIME  NULL ,
	CheckNumber		NVARCHAR(100)  NULL ,
	PaymentDate		DATETIME  NULL ,
	PaymentAmount	MONEY  NULL,
	CheckClearedDate DATETIME NULL,
	AuthorizationCount	BIGINT NULL,
	InProcessCount	BIGINT NULL,
	CancelledCount	BIGINT NULL,
	ApprovedCount	BIGINT NULL,
	DeniedCount	BIGINT NULL,
	ReadyForPaymentCount BIGINT NULL,
	PaidCount		BIGINT NULL,
	ExceptionCount		BIGINT NULL ,
	ClaimExceptionDetails NVARCHAR(MAX)NULL,
	MembershipNumber NVARCHAR(100) NULL,
	ProgramName NVARCHAR(100) NULL,
	BatchID INT NULL,
	AmountApproved MONEY  NULL,
	ACESStatus nvarchar(100) NULL ,
	ACESClearedDate DATETIME NULL ,
	ACESFeeAmount MONEY NULL
) 

INSERT INTO @tmpForWhereClause
SELECT  
	T.c.value('@IDType','NVARCHAR(50)'),
	T.c.value('@IDValue','NVARCHAR(100)'),
	T.c.value('@NameType','NVARCHAR(50)'),
	T.c.value('@NameOperator','NVARCHAR(50)'),
	T.c.value('@NameValue','NVARCHAR(MAX)'),
	T.c.value('@ClaimTypes','NVARCHAR(MAX)'),
	T.c.value('@ClaimStatuses','NVARCHAR(MAX)'),
	T.c.value('@ClaimCategories','NVARCHAR(MAX)'),
	T.c.value('@ClientID','INT'),
	T.c.value('@ProgramID','INT'),
	T.c.value('@Preset','INT'),
	T.c.value('@ClaimDateFrom','DATETIME'),
	T.c.value('@ClaimDateTo','DATETIME'),
	T.c.value('@ClaimAmountFrom','MONEY'),
	T.c.value('@ClaimAmountTo','MONEY'),
	T.c.value('@CheckNumber','NVARCHAR(50)'),
	T.c.value('@CheckDateFrom','DATETIME'),
	T.c.value('@CheckDateTo','DATETIME'),
	T.c.value('@ExportBatchID','INT'),
	T.c.value('@ACESSubmitFromDate','DATETIME'),
	T.c.value('@ACESSubmitToDate','DATETIME'),
	T.c.value('@ACESClearedFromDate','DATETIME'),
	T.c.value('@ACESClearedToDate','DATETIME'),
	T.c.value('@ACESStatus','NVARCHAR(MAX)'),
	T.c.value('@ReceivedFromDate','DATETIME'),
	T.c.value('@ReceivedToDate','DATETIME')
	
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @IDType			NVARCHAR(50)= NULL,
@IDValue			NVARCHAR(100)= NULL,
@NameType		NVARCHAR(50)= NULL,
@NameOperator	NVARCHAR(50)= NULL,
@NameValue		NVARCHAR(MAX)= NULL,
@ClaimTypes		NVARCHAR(MAX)= NULL,
@ClaimStatuses	NVARCHAR(MAX)= NULL,
@ClaimCategories	NVARCHAR(MAX)= NULL,
@ClientID		INT= NULL,
@ProgramID		INT= NULL,
@preset			INT=NULL,
@ClaimDateFrom	DATETIME= NULL,
@ClaimDateTo		DATETIME= NULL,
@ClaimAmountFrom	MONEY= NULL,
@ClaimAmountTo	MONEY= NULL,
@CheckNumber		NVARCHAR(50)= NULL,
@CheckDateFrom	DATETIME= NULL,
@CheckDateTo		DATETIME= NULL,
@ExportBatchID	INT= NULL,
@ACESSubmitFromDate DATETIME= NULL,
@ACESSubmitToDate DATETIME= NULL,
@ACESClearedFromDate DATETIME= NULL,
@ACESClearedToDate DATETIME= NULL,
@ACESStatus NVARCHAR(MAX) = NULL,
@ReceivedFromDate DATETIME= NULL,
@ReceivedToDate DATETIME= NULL

SELECT 
		@IDType					= IDType				
		,@IDValue				= IDValue				
		,@NameType				= NameType			
		,@NameOperator			= NameOperator		
		,@NameValue				= NameValue			
		,@ClaimTypes			= ClaimTypes			
		,@ClaimStatuses			= ClaimStatuses		
		,@ClaimCategories		= ClaimCategories		
		,@ClientID				= ClientID			
		,@ProgramID				= ProgramID			
		,@preset				= Preset				
		,@ClaimDateFrom			= ClaimDateFrom		
		,@ClaimDateTo			= ClaimDateTo			
		,@ClaimAmountFrom		= ClaimAmountFrom		
		,@ClaimAmountTo			= ClaimAmountTo		
		,@CheckNumber			= CheckNumber			
		,@CheckDateFrom			= CheckDateFrom		
		,@CheckDateTo			= CheckDateTo			
		,@ExportBatchID			= ExportBatchID		
		,@ACESSubmitFromDate	= ACESSubmitFromDate	
		,@ACESSubmitToDate		= ACESSubmitToDate
		,@ACESClearedFromDate	= ACESClearedFromDate
		,@ACESClearedToDate		= ACESClearedToDate
		,@ACESStatus			= ACESStatus
		,@ReceivedFromDate      = ReceivedFromDate
        ,@ReceivedToDate        = ReceivedToDate
FROM	@tmpForWhereClause

--SELECT @preset
IF (@preset IS NOT NULL)
BEGIN
	DECLARE @fromDate DATETIME
	SET @fromDate = DATEADD(DD, DATEDIFF(DD,0, DATEADD(DD,-1 * @preset,GETDATE())),0)
	UPDATE @tmpForWhereClause 
	SET		ClaimDateFrom  = @fromDate,
			ClaimDateTo = DATEADD(DD,1,GETDATE())
		

END



--SELECT * FROM @tmpForWhereClause

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResultsFiltered
SELECT
		C.ID AS ClaimID
		, CT.Name AS ClaimType
		, C.ClaimDate
		, C.ReceivedDate
		, C.AmountRequested
		, CASE
                        WHEN ISNULL(C.PayeeType,'') = 'Member' THEN 'M-' + C.ContactName
                        WHEN ISNULL(C.PayeeType,'') = 'Vendor' THEN 'V-' + C.ContactName
                        ELSE C.ContactName
          END AS Payeee
		, CS.Name AS ClaimStatus
		, NA.Name AS NextAction
		, U.FirstName + ' ' + U.LastName AS AssignedTo
		, C.NextActionScheduledDate
		, C.ACESSubmitDate
		, C.CheckNumber
		, C.PaymentDate
		, C.PaymentAmount
		, C.CheckClearedDate
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, CE.[Description]
		, UPPER(COALESCE(MS.MembershipNumber,MS.ClientReferenceNumber)) MembershipNumber
		, P.Name
		, B.ID AS BatchID
		, C.AmountApproved
		, ACS.Name AS ACESClaimStatus
		, C.ACESClearedDate
		, C.ACESFeeAmount 
FROM	Claim C
JOIN	ClaimType CT WITH(NOLOCK) ON CT.ID = C.ClaimTypeID
LEFT JOIN ClaimStatus CS WITH(NOLOCK) ON CS.ID = C.ClaimStatusID 
LEFT JOIN ClaimException CE WITH(NOLOCK) ON CE.ClaimID = C.ID
LEFT JOIN NextAction NA WITH(NOLOCK) ON NA.ID = C.NextActionID
LEFT JOIN [User] U WITH(NOLOCK) ON U.ID = C.NextActionAssignedToUserID
LEFT JOIN Vendor V WITH (NOLOCK) ON C.VendorID = V.ID
LEFT JOIN Member M WITH (NOLOCK) ON C.MemberID = M.ID
LEFT JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
LEFT JOIN PurchaseOrder PO WITH (NOLOCK) ON C.PurchaseOrderID = PO.ID
LEFT JOIN Program P WITH (NOLOCK) ON P.ID = C.ProgramID
LEFT JOIN Batch B WITH(NOLOCK) ON B.ID=C.ExportBatchID
LEFT JOIN ACESClaimStatus ACS WITH(NOLOCK) ON ACS.ID=C.ACESClaimStatusID
WHERE C.IsActive = 1
AND		(ISNULL(LEN(@IDType),0) = 0 OR (	( @IDType = 'Claim' AND @IDValue	= CONVERT(NVARCHAR(100),C.ID))
											OR
											( @IDType = 'Vendor' AND @IDValue = V.VendorNumber)
											OR
											( @IDType = 'Member' AND @IDValue = MS.MembershipNumber)
										) )
AND		(ISNULL(LEN(@NameType),0) = 0 OR (	
											(@NameType = 'Member' AND (
																			-- TODO: Review the conditions against M.LastName. we might have to use first and last names.
																			(@NameOperator = 'Is equal to' AND @NameValue = M.LastName)
																			OR
																			(@NameOperator = 'Begins with' AND M.LastName LIKE  @NameValue + '%')
																			OR
																			(@NameOperator = 'Ends with' AND M.LastName LIKE  '%' + @NameValue)
																			OR
																			(@NameOperator = 'Contains' AND M.LastName LIKE  '%' + @NameValue + '%')

																		) )
												OR
											(@NameType = 'Vendor' AND (
																			(@NameOperator = 'Is equal to' AND @NameValue = V.Name)
																			OR
																			(@NameOperator = 'Begins with' AND V.Name LIKE  @NameValue + '%')
																			OR
																			(@NameOperator = 'Ends with' AND V.Name LIKE  '%' + @NameValue)
																			OR
																			(@NameOperator = 'Contains' AND V.Name LIKE  '%' + @NameValue + '%')

																		) )

											) )
AND		(ISNULL(LEN(@ClaimTypes),0) = 0  OR (C.ClaimTypeID IN ( SELECT item FROM [dbo].[fnSplitString](@ClaimTypes,',')) ) )
AND		(ISNULL(LEN(@ClaimStatuses),0) = 0  OR (C.ClaimStatusID IN ( SELECT item FROM [dbo].[fnSplitString](@ClaimStatuses,',')) ) )
AND		(ISNULL(LEN(@ClaimCategories),0) = 0  OR (C.ClaimCategoryID IN ( SELECT item FROM [dbo].[fnSplitString](@ClaimCategories,',')) ) )
AND		(ISNULL(@ClientID,0) = 0 OR @ClientID = 0 OR (P.ClientID = @ClientID  ) )
AND		(ISNULL(@ProgramID,0) = 0 OR @ProgramID = 0 OR (C.ProgramID = @ProgramID  ) )
AND		(C.ClaimDate IS NULL 
		OR
		C.ClaimDate IS NOT NULL
		AND		(@ClaimDateFrom IS NULL  OR ( C.ClaimDate >= @ClaimDateFrom ) )
		AND		(@ClaimDateTo IS NULL  OR ( C.ClaimDate < DATEADD(DD,1,@ClaimDateTo) ) )
		)
AND		(@ClaimAmountFrom IS NULL OR (ISNULL(C.AmountRequested,0) >= @ClaimAmountFrom))
AND		(@ClaimAmountTo IS NULL OR (ISNULL(C.AmountRequested,0) <= @ClaimAmountTo))
AND		(ISNULL(LEN(@CheckNumber),0) = 0 OR C.CheckNumber = @CheckNumber)
AND		(ISNULL(@ExportBatchID,0) = 0 OR @ExportBatchID = 0 OR (B.ID = @ExportBatchID  ) )
AND		(@CheckDateFrom IS NULL OR (C.CheckClearedDate >= @CheckDateFrom))
AND		(@CheckDateTo IS NULL OR (C.CheckClearedDate < DATEADD(DD,1,@CheckDateTo)))
AND		(@ACESSubmitFromDate IS NULL OR (C.ACESSubmitDate >= @ACESSubmitFromDate))
AND		(@ACESSubmitToDate IS NULL OR (C.ACESSubmitDate < DATEADD(DD,1,@ACESSubmitToDate)))	
AND		(@ACESClearedFromDate IS NULL OR (C.ACESClearedDate >= @ACESClearedFromDate))
AND		(@ACESClearedToDate IS NULL OR (C.ACESClearedDate < DATEADD(DD,1,@ACESClearedToDate)))		
AND		(@ACESStatus IS NULL OR (C.ACESClaimStatusID IN (SELECT item FROM [dbo].[fnSplitString](@ACESStatus,','))))
AND		(@ReceivedFromDate IS NULL OR (C.ReceivedDate >= @ReceivedFromDate))
AND		(@ReceivedToDate IS NULL OR (C.ReceivedDate < DATEADD(DD,1,@ReceivedToDate)))	


--FILTERING has to be taken care here
INSERT INTO #FinalResultsSorted
SELECT 
	T.ClaimID,
	T.ClaimType,
	T.ClaimDate,
	T.ReceivedDate,
	T.AmountRequested,
	T.Payeee,
	T.ClaimStatus,
	T.NextAction,
	T.AssignedTo,
	T.NextActionScheduledDate,
	T.ACESSubmitDate,
	T.CheckNumber,
	T.PaymentDate,
	T.PaymentAmount,
	T.CheckClearedDate,
	T.AuthorizationCount,
	T.InProcessCount,
	T.CancelledCount,
	T.ApprovedCount,
	T.DeniedCount,
	T.ReadyForPaymentCount,
	T.PaidCount,
	T.ExceptionCount,
   [dbo].[fnConcatenate](T.ClaimExceptionDetails) AS ClaimExceptionDetails,
    T.MembershipNumber,
    T.ProgramName,
    T.BatchID,
    T.AmountApproved,
    T.ACESStatus,
    T.ACESClearedDate,
	T.ACESFeeAmount 
FROM #FinalResultsFiltered T
GROUP BY 
	T.ClaimID,
	T.ClaimType,
	T.ClaimDate,
	T.ReceivedDate,
	T.AmountRequested,
	T.Payeee,
	T.ClaimStatus,
	T.NextAction,
	T.AssignedTo,
	T.NextActionScheduledDate,
	T.ACESSubmitDate,
	T.CheckNumber,
	T.PaymentDate,
	T.PaymentAmount,
	T.CheckClearedDate,
	T.AuthorizationCount,
	T.InProcessCount,
	T.CancelledCount,
	T.ApprovedCount,
	T.DeniedCount,
	T.ReadyForPaymentCount,
	T.PaidCount,
	T.ExceptionCount,
	T.MembershipNumber,
	T.ProgramName,
	T.BatchID,
	T.AmountApproved,
	T.ACESStatus,
	T.ACESClearedDate,
	T.ACESFeeAmount 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ClaimID' AND @sortOrder = 'ASC'
	 THEN T.ClaimID END ASC, 
	 CASE WHEN @sortColumn = 'ClaimID' AND @sortOrder = 'DESC'
	 THEN T.ClaimID END DESC ,

	 CASE WHEN @sortColumn = 'ClaimType' AND @sortOrder = 'ASC'
	 THEN T.ClaimType END ASC, 
	 CASE WHEN @sortColumn = 'ClaimType' AND @sortOrder = 'DESC'
	 THEN T.ClaimType END DESC ,

	 CASE WHEN @sortColumn = 'ClaimDate' AND @sortOrder = 'ASC'
	 THEN T.ClaimDate END ASC, 
	 CASE WHEN @sortColumn = 'ClaimDate' AND @sortOrder = 'DESC'
	 THEN T.ClaimDate END DESC ,

	  CASE WHEN @sortColumn = 'ReceivedDate' AND @sortOrder = 'ASC'
	 THEN T.ReceivedDate END ASC, 
	 CASE WHEN @sortColumn = 'ReceivedDate' AND @sortOrder = 'DESC'
	 THEN T.ReceivedDate END DESC ,

	 CASE WHEN @sortColumn = 'AmountRequested' AND @sortOrder = 'ASC'
	 THEN T.AmountRequested END ASC, 
	 CASE WHEN @sortColumn = 'AmountRequested' AND @sortOrder = 'DESC'
	 THEN T.AmountRequested END DESC ,

	 CASE WHEN @sortColumn = 'Payeee' AND @sortOrder = 'ASC'
	 THEN T.Payeee END ASC, 
	 CASE WHEN @sortColumn = 'Payeee' AND @sortOrder = 'DESC'
	 THEN T.Payeee END DESC ,

	 CASE WHEN @sortColumn = 'ClaimStatus' AND @sortOrder = 'ASC'
	 THEN T.ClaimStatus END ASC, 
	 CASE WHEN @sortColumn = 'ClaimStatus' AND @sortOrder = 'DESC'
	 THEN T.ClaimStatus END DESC ,

	 CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'ASC'
	 THEN T.NextAction END ASC, 
	 CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'DESC'
	 THEN T.NextAction END DESC ,

	 CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'ASC'
	 THEN T.AssignedTo END ASC, 
	 CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'DESC'
	 THEN T.AssignedTo END DESC ,

	 CASE WHEN @sortColumn = 'NextActionScheduledDate' AND @sortOrder = 'ASC'
	 THEN T.NextActionScheduledDate END ASC, 
	 CASE WHEN @sortColumn = 'NextActionScheduledDate' AND @sortOrder = 'DESC'
	 THEN T.NextActionScheduledDate END DESC ,

	 CASE WHEN @sortColumn = 'ACESSubmitDate' AND @sortOrder = 'ASC'
	 THEN T.ACESSubmitDate END ASC, 
	 CASE WHEN @sortColumn = 'ACESSubmitDate' AND @sortOrder = 'DESC'
	 THEN T.ACESSubmitDate END DESC ,

	 CASE WHEN @sortColumn = 'CheckNumber' AND @sortOrder = 'ASC'
	 THEN T.CheckNumber END ASC, 
	 CASE WHEN @sortColumn = 'CheckNumber' AND @sortOrder = 'DESC'
	 THEN T.CheckNumber END DESC ,

	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'ASC'
	 THEN T.PaymentDate END ASC, 
	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'DESC'
	 THEN T.PaymentDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'
	 THEN T.PaymentAmount END ASC, 
	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'
	 THEN T.PaymentAmount END DESC, 
	 
	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'ASC'
	 THEN T.CheckClearedDate END ASC, 
	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'DESC'
	 THEN T.CheckClearedDate END DESC,
	 
	 CASE WHEN @sortColumn = 'BatchID' AND @sortOrder = 'ASC'
	 THEN T.BatchID END ASC, 
	 CASE WHEN @sortColumn = 'BatchID' AND @sortOrder = 'DESC'
	 THEN T.BatchID END DESC,

	 CASE WHEN @sortColumn = 'AmountApproved' AND @sortOrder = 'ASC'
	 THEN T.AmountApproved END ASC, 
	 CASE WHEN @sortColumn = 'AmountApproved' AND @sortOrder = 'DESC'
	 THEN T.AmountApproved END DESC,

	 CASE WHEN @sortColumn = 'ACESStatus' AND @sortOrder = 'ASC'
	 THEN T.ACESStatus END ASC, 
	 CASE WHEN @sortColumn = 'ACESStatus' AND @sortOrder = 'DESC'
	 THEN T.ACESStatus END DESC,

	 CASE WHEN @sortColumn = 'ACESClearedDate' AND @sortOrder = 'ASC'
	 THEN T.ACESClearedDate END ASC, 
	 CASE WHEN @sortColumn = 'ACESClearedDate' AND @sortOrder = 'DESC'
	 THEN T.ACESClearedDate END DESC,

	 CASE WHEN @sortColumn = 'ACESFeeAmount' AND @sortOrder = 'ASC'
	 THEN T.ACESFeeAmount END ASC, 
	 CASE WHEN @sortColumn = 'ACESFeeAmount' AND @sortOrder = 'DESC'
	 THEN T.ACESFeeAmount END DESC


DECLARE @authorizationIssuedCount  BIGINT = 0,
		@inProcessCount BIGINT = 0,
		@cancelledCount BIGINT = 0,
		@approvedCount  BIGINT = 0,
		@deniedCount  BIGINT = 0,
		@readyForPaymentCount BIGINT = 0,
		@PaidCount BIGINT = 0,
		@exceptionCount BIGINT = 0


SELECT @authorizationIssuedCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'AuthorizationIssued'
SELECT @inProcessCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'In-Process'
SELECT @cancelledCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Cancelled'
SELECT @approvedCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Approved'
SELECT @deniedCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Denied'
SELECT @readyForPaymentCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'ReadyForPayment'
SELECT @PaidCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Paid'
SELECT @exceptionCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Exception'

-- DEBUG : SELECT * FROM #FinalResultsSorted WHERE ClaimStatus  ='Approved'

UPDATE #FinalResultsSorted
SET AuthorizationCount = @authorizationIssuedCount,
	InProcessCount = @inProcessCount,
	CancelledCount = @cancelledCount,
   	ApprovedCount = @approvedCount,
    DeniedCount = @deniedCount,
    ReadyForPaymentCount = @readyForPaymentCount,
    PaidCount = @PaidCount,
    ExceptionCount = @exceptionCount

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

--DROP TABLE #tmpForWhereClause
DROP TABLE #FinalResultsFiltered
DROP TABLE #FinalResultsSorted

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
 WHERE id = object_id(N'[dbo].[dms_Client_Invoice_Event_Processing_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Client_Invoice_Event_Processing_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_Client_Invoice_Event_Processing_List_Get @billingInvoiceLineID =3
 CREATE PROCEDURE [dbo].[dms_Client_Invoice_Event_Processing_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 100  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @billingInvoiceLineID INT 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
BillingInvoiceDetailIDOperator="-1" 
BillingTypeOperator="-1" 
InvoiceDefinitionOperator="-1" 
LineSequenceOperator="-1" 
LineNameOperator="-1" 
ServiceCodeOperator="-1" 
BillingDetailNameOperator="-1" 
QuantityOperator="-1" 
DetailStatusOperator="-1" 
DetailDispositionOperator="-1" 
AdjustmentReasonOperator="-1" 
AdjustmentDateOperator="-1" 
AdjustedByOperator="-1" 
SourceRecordNumberOperator="-1" 
BillingInvoiceScheduleTypeIDOperator="-1" 
EventAmountOperator="-1" 
RateTypeNameOperator="-1" 
ExcludedReasonOperator="-1" 
ExcludeDateOperator="-1" 
ExcludedByOperator="-1" 
EntityOperator="-1" 
ClientOperator="-1" 
InternalCommentOperator="-1" 
PurchaseOrderOperator="-1"
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
BillingInvoiceDetailIDOperator INT NOT NULL,
BillingInvoiceDetailIDValue int NULL,
BillingTypeOperator INT NOT NULL,
BillingTypeValue nvarchar(100) NULL,
InvoiceDefinitionOperator INT NOT NULL,
InvoiceDefinitionValue nvarchar(100) NULL,
LineSequenceOperator INT NOT NULL,
LineSequenceValue int NULL,
LineNameOperator INT NOT NULL,
LineNameValue nvarchar(100) NULL,
ServiceCodeOperator INT NOT NULL,
ServiceCodeValue nvarchar(100) NULL,
BillingDetailNameOperator INT NOT NULL,
BillingDetailNameValue nvarchar(100) NULL,
QuantityOperator INT NOT NULL,
QuantityValue int NULL,
DetailStatusOperator INT NOT NULL,
DetailStatusValue nvarchar(100) NULL,
DetailDispositionOperator INT NOT NULL,
DetailDispositionValue nvarchar(100) NULL,
AdjustmentReasonOperator INT NOT NULL,
AdjustmentReasonValue nvarchar(100) NULL,
AdjustmentDateOperator INT NOT NULL,
AdjustmentDateValue datetime NULL,
AdjustedByOperator INT NOT NULL,
AdjustedByValue nvarchar(100) NULL,
SourceRecordNumberOperator INT NOT NULL,
SourceRecordNumberValue nvarchar(100) NULL,
BillingInvoiceScheduleTypeIDOperator INT NOT NULL,
BillingInvoiceScheduleTypeIDValue int NULL,
EventAmountOperator INT NOT NULL,
EventAmountValue money NULL,
RateTypeNameOperator INT NOT NULL,
RateTypeNameValue nvarchar(100) NULL,
ExcludedReasonOperator INT NOT NULL,
ExcludedReasonValue nvarchar(100) NULL,
ExcludeDateOperator INT NOT NULL,
ExcludeDateValue datetime NULL,
ExcludedByOperator INT NOT NULL,
ExcludedByValue nvarchar(100) NULL,
EntityOperator INT NOT NULL,
EntityValue nvarchar(100) NULL,
ClientOperator INT NOT NULL,
ClientValue nvarchar(100) NULL,
InternalCommentOperator INT NOT NULL,
InternalCommentValue nvarchar(max) NULL,
PurchaseOrderOperator INT NOT NULL,
PurchaseOrderValue nvarchar(100) NULL,
)

CREATE TABLE #FinalResults_filtered( 
	BillingInvoiceDetailID int  NULL ,
	BillingType nvarchar(100)  NULL ,
	InvoiceDefinition nvarchar(100)  NULL ,
	Client nvarchar(100)  NULL ,
	LineSequence int  NULL ,
	LineName nvarchar(100)  NULL ,
	ServiceCode nvarchar(100)  NULL ,
	BillingDetailName nvarchar(100)  NULL ,
	Quantity int  NULL ,
	DetailStatus nvarchar(100)  NULL ,
	DetailDisposition nvarchar(100)  NULL ,
	AdjustmentReason nvarchar(100)  NULL ,
	AdjustmentDate datetime  NULL ,
	AdjustedBy nvarchar(100)  NULL ,
	SourceRecordNumber nvarchar(100)  NULL ,
	BillingInvoiceScheduleTypeID int  NULL ,
	EventAmount money  NULL ,
	RateTypeName nvarchar(100)  NULL ,
	ExcludedReason nvarchar(100)  NULL ,
	ExcludeDate datetime  NULL ,
	ExcludedBy nvarchar(100) NULL,
	Entity NVARCHAR(50) NULL,
	IsAdjusted BIT NULL,
	IsExcluded BIT NULL  ,
	InternalComment nvarchar(max)  NULL ,
	PurchaseOrder nvarchar(100) NULL ,
	ExceptionMessage nvarchar(max)  NULL 
) 
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	BillingInvoiceDetailID int  NULL ,
	BillingType nvarchar(100)  NULL ,
	InvoiceDefinition nvarchar(100)  NULL ,
	Client nvarchar(100)  NULL ,
	LineSequence int  NULL ,
	LineName nvarchar(100)  NULL ,
	ServiceCode nvarchar(100)  NULL ,
	BillingDetailName nvarchar(100)  NULL ,
	Quantity int  NULL ,
	DetailStatus nvarchar(100)  NULL ,
	DetailDisposition nvarchar(100)  NULL ,
	AdjustmentReason nvarchar(100)  NULL ,
	AdjustmentDate datetime  NULL ,
	AdjustedBy nvarchar(100)  NULL ,
	SourceRecordNumber nvarchar(100)  NULL ,
	BillingInvoiceScheduleTypeID int  NULL ,
	EventAmount money  NULL ,
	RateTypeName nvarchar(100)  NULL ,
	ExcludedReason nvarchar(100)  NULL ,
	ExcludeDate datetime  NULL ,
	ExcludedBy nvarchar(100)  NULL ,
	Entity nvarchar(100)  NULL ,
	InternalComment nvarchar(max)  NULL ,
	PurchaseOrder nvarchar(100) NULL ,
	ExceptionMessage nvarchar(max)  NULL 
)  

CREATE TABLE #tmpFinalResults( 
	
	BillingInvoiceDetailID int  NULL ,
	BillingType nvarchar(100)  NULL ,
	InvoiceDefinition nvarchar(100)  NULL ,
	Client nvarchar(100)  NULL ,
	LineSequence int  NULL ,
	LineName nvarchar(100)  NULL ,
	ServiceCode nvarchar(100)  NULL ,
	BillingDetailName nvarchar(100)  NULL ,
	Quantity int  NULL ,
	DetailStatus nvarchar(100)  NULL ,
	DetailDisposition nvarchar(100)  NULL ,
	AdjustmentReason nvarchar(100)  NULL ,
	AdjustmentDate datetime  NULL ,
	AdjustedBy nvarchar(100)  NULL ,
	SourceRecordNumber nvarchar(100)  NULL ,
	BillingInvoiceScheduleTypeID int  NULL ,
	EventAmount money  NULL ,
	RateTypeName nvarchar(100)  NULL ,
	ExcludedReason nvarchar(100)  NULL ,
	ExcludeDate datetime  NULL ,
	ExcludedBy nvarchar(100) NULL,
	Entity NVARCHAR(50) NULL,
	IsAdjusted BIT NULL,
	IsExcluded BIT NULL  ,
	InternalComment nvarchar(max)  NULL ,
	PurchaseOrder nvarchar(100) NULL ,
	ExceptionMessage nvarchar(max)  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@BillingInvoiceDetailIDOperator','INT'),-1),
	T.c.value('@BillingInvoiceDetailIDValue','int') ,
	ISNULL(T.c.value('@BillingTypeOperator','INT'),-1),
	T.c.value('@BillingTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@InvoiceDefinitionOperator','INT'),-1),
	T.c.value('@InvoiceDefinitionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@LineSequenceOperator','INT'),-1),
	T.c.value('@LineSequenceValue','int') ,
	ISNULL(T.c.value('@LineNameOperator','INT'),-1),
	T.c.value('@LineNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ServiceCodeOperator','INT'),-1),
	T.c.value('@ServiceCodeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@BillingDetailNameOperator','INT'),-1),
	T.c.value('@BillingDetailNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@QuantityOperator','INT'),-1),
	T.c.value('@QuantityValue','int') ,
	ISNULL(T.c.value('@DetailStatusOperator','INT'),-1),
	T.c.value('@DetailStatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DetailDispositionOperator','INT'),-1),
	T.c.value('@DetailDispositionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@AdjustmentReasonOperator','INT'),-1),
	T.c.value('@AdjustmentReasonValue','nvarchar(100)') ,
	ISNULL(T.c.value('@AdjustmentDateOperator','INT'),-1),
	T.c.value('@AdjustmentDateValue','datetime') ,
	ISNULL(T.c.value('@AdjustedByOperator','INT'),-1),
	T.c.value('@AdjustedByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@SourceRecordNumberOperator','INT'),-1),
	T.c.value('@SourceRecordNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@BillingInvoiceScheduleTypeIDOperator','INT'),-1),
	T.c.value('@BillingInvoiceScheduleTypeIDValue','int') ,
	ISNULL(T.c.value('@EventAmountOperator','INT'),-1),
	T.c.value('@EventAmountValue','money') ,
	ISNULL(T.c.value('@RateTypeNameOperator','INT'),-1),
	T.c.value('@RateTypeNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ExcludedReasonOperator','INT'),-1),
	T.c.value('@ExcludedReasonValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ExcludeDateOperator','INT'),-1),
	T.c.value('@ExcludeDateValue','datetime') ,
	ISNULL(T.c.value('@ExcludedByOperator','INT'),-1),
	T.c.value('@ExcludedByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@EntityOperator','INT'),-1),
	T.c.value('@EntityValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ClientOperator','INT'),-1),
	T.c.value('@ClientValue','nvarchar(100)')  ,
	ISNULL(T.c.value('@InternalCommentOperator','INT'),-1),
	T.c.value('@InternalCommentValue','nvarchar(max)') ,
	ISNULL(T.c.value('@PurchaseOrderOperator','INT'),-1),
	T.c.value('@PurchaseOrderValue','nvarchar(100)')
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
select	bd.ID as BillingInvoiceDetailID,
		bt.Name as BillingType,
		bdi.[Name] as InvoiceDefinition,
		cl.Name as Client,
		bdil.Sequence as LineSequence,
		bdil.Name as LineName,
		bd.ServiceCode,
		bd.Name as BillingDetailName,
		bd.Quantity,
		bids.Name as DetailStatus,
		bidd.Name as DetailDisposition,
		bar.[Description] as AdjustmentReason,
		bd.AdjustmentDate,
		bd.AdjustedBy,
		bd.EntityKey AS SourceRecordNumber,
		--case 
		--when (select Name from Entity with (nolock) where ID = EntityID) = 'PurchaseOrder' then po.PurchaseOrderNumber
		--else EntityKey
		--end as SourceRecordNumber ,
		bt.ID as BillingInvoiceScheduleTypeID,
		bd.EventAmount,
		bd.RateTypeName,  
		ber.Description as ExcludedReason,
		bd.ExcludeDate,
		bd.ExcludedBy,
		(select Name from Entity with (nolock) where ID = EntityID) as Entity,
		bd.IsAdjusted,
		bd.IsExcluded,
		bd.InternalComment,
		Case bd.EntityID
			WHEN (select ID from Entity with (nolock) where Name = 'PurchaseOrder')
			THEN (SELECT TOP 1 PurchaseOrderNumber from PurchaseOrder where ID = bd.EntityKey)
			WHEN (Select ID from Entity with (nolock) where Name = 'VendorInvoice')
			THEN (SELECT PurchaseOrderNumber from PurchaseOrder where ID =(SELECT PurchaseOrderID FROM VendorInvoice where ID = bd.EntityKey))
			ELSE NULL
		END AS PurchaseOrderNumber,
		--[dbo].[fnConcatenate](bide.InvoiceDetailExceptionComment) AS ExceptionMessage
		'' AS ExceptionMessage
from BillingInvoiceDetail bd
left outer join BillingDefinitionInvoice bdi with (nolock) on bdi.ID = bd.BillingDefinitionInvoiceID
left outer join BillingDefinitionInvoiceLine bdil with (nolock) on bdil.ID = bd.BillingDefinitionInvoiceLineID
left outer join BillingDefinitionEvent bde with (nolock) on bde.ID = bd.BillingDefinitionEventID
left outer join Client cl with (nolock) on cl.ID = bdi.ClientID
left outer join BillingSchedule bs with (nolock) on bs.ID = bd.BillingScheduleID
left outer join BillingScheduleType bt with (nolock) on bt.ID = bs.ScheduleTypeID
left outer join BillingInvoiceDetailStatus bids with (nolock) on bids.ID = bd.InvoiceDetailStatusID
left outer join BillingInvoiceDetailDisposition bidd with (nolock) on bidd.ID = bd.InvoiceDetailDispositionID
left outer join BillingAdjustmentReason bar with (nolock) on bar.ID = bd.AdjustmentReasonID
left outer join BillingExcludeReason ber with (nolock) on ber.ID = bd.ExcludeReasonID
--left outer join BillingInvoiceDetailException bide with (nolock) on bide.BillingInvoiceDetailID = bd.ID
--left outer join PurchaseOrder po with (nolock) on po.ID = bd.EntityKey and EntityID = (select ID from Entity with (nolock) where Name = 'PurchaseOrder')
where bd.BillingInvoiceLineID=@billingInvoiceLineID
--AND bd.AccountingInvoiceBatchID is null
INSERT INTO #FinalResults_filtered
SELECT 
	T.BillingInvoiceDetailID,
	T.BillingType,
	T.InvoiceDefinition,
	T.Client,
	T.LineSequence,
	T.LineName,
	T.ServiceCode,
	T.BillingDetailName,
	T.Quantity,
	T.DetailStatus,
	T.DetailDisposition,
	T.AdjustmentReason ,
	T.AdjustmentDate ,
	T.AdjustedBy ,
	T.SourceRecordNumber,
	T.BillingInvoiceScheduleTypeID,
	T.EventAmount,
	T.RateTypeName,
	T.ExcludedReason ,
	T.ExcludeDate,
	T.ExcludedBy,
	T.Entity,
	T.IsAdjusted,
	T.IsExcluded,
	T.InternalComment,
	T.PurchaseOrder,
	[dbo].[fnConcatenate](bidet.[Description]) AS ExceptionMessage
FROM #tmpFinalResults T
left outer join BillingInvoiceDetailException bide with (nolock) on bide.BillingInvoiceDetailID = T.BillingInvoiceDetailID
left outer join BillingInvoiceDetailExceptionType bidet with(nolock) on bide.InvoiceDetailExceptionTypeID = bidet.ID 
GROUP BY 
	T.BillingInvoiceDetailID,
	T.BillingType,
	T.InvoiceDefinition,
	T.Client,
	T.LineSequence,
	T.LineName,
	T.ServiceCode,
	T.BillingDetailName,
	T.Quantity,
	T.DetailStatus,
	T.DetailDisposition,
	T.AdjustmentReason ,
	T.AdjustmentDate ,
	T.AdjustedBy ,
	T.SourceRecordNumber,
	T.BillingInvoiceScheduleTypeID,
	T.EventAmount,
	T.RateTypeName,
	T.ExcludedReason ,
	T.ExcludeDate,
	T.ExcludedBy,
	T.Entity,
	T.IsAdjusted,
	T.IsExcluded,
	T.InternalComment,
	T.PurchaseOrder
	
INSERT INTO #FinalResults
SELECT 
	T.BillingInvoiceDetailID,
	T.BillingType,
	T.InvoiceDefinition,
	T.Client,
	T.LineSequence,
	T.LineName,
	T.ServiceCode,
	T.BillingDetailName,
	T.Quantity,
	T.DetailStatus,
	T.DetailDisposition,
	CASE WHEN ISNULL(T.IsAdjusted,0) = 1 THEN T.AdjustmentReason ELSE NULL END AS AdjustmentReason,
	CASE WHEN ISNULL(T.IsAdjusted,0) = 1 THEN T.AdjustmentDate ELSE NULL END AS AdjustmentDate,
	CASE WHEN ISNULL(T.IsAdjusted,0) = 1 THEN T.AdjustedBy ELSE NULL END AS AdjustedBy,
	T.SourceRecordNumber,
	T.BillingInvoiceScheduleTypeID,
	T.EventAmount,
	T.RateTypeName,
	CASE WHEN ISNULL(T.IsExcluded,0) = 1 THEN T.ExcludedReason ELSE NULL END AS ExcludedReason,
	CASE WHEN ISNULL(T.IsExcluded,0) = 1 THEN T.ExcludeDate ELSE NULL END AS ExcludeDate,
	CASE WHEN ISNULL(T.IsExcluded,0) = 1 THEN T.ExcludedBy ELSE NULL END AS ExcludedBy,
	T.Entity,
	T.InternalComment,
	T.PurchaseOrder,
	T.ExceptionMessage
	
FROM #FinalResults_filtered T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.BillingInvoiceDetailIDOperator = -1 ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 0 AND T.BillingInvoiceDetailID IS NULL ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 1 AND T.BillingInvoiceDetailID IS NOT NULL ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 2 AND T.BillingInvoiceDetailID = TMP.BillingInvoiceDetailIDValue ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 3 AND T.BillingInvoiceDetailID <> TMP.BillingInvoiceDetailIDValue ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 7 AND T.BillingInvoiceDetailID > TMP.BillingInvoiceDetailIDValue ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 8 AND T.BillingInvoiceDetailID >= TMP.BillingInvoiceDetailIDValue ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 9 AND T.BillingInvoiceDetailID < TMP.BillingInvoiceDetailIDValue ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 10 AND T.BillingInvoiceDetailID <= TMP.BillingInvoiceDetailIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.BillingTypeOperator = -1 ) 
 OR 
	 ( TMP.BillingTypeOperator = 0 AND T.BillingType IS NULL ) 
 OR 
	 ( TMP.BillingTypeOperator = 1 AND T.BillingType IS NOT NULL ) 
 OR 
	 ( TMP.BillingTypeOperator = 2 AND T.BillingType = TMP.BillingTypeValue ) 
 OR 
	 ( TMP.BillingTypeOperator = 3 AND T.BillingType <> TMP.BillingTypeValue ) 
 OR 
	 ( TMP.BillingTypeOperator = 4 AND T.BillingType LIKE TMP.BillingTypeValue + '%') 
 OR 
	 ( TMP.BillingTypeOperator = 5 AND T.BillingType LIKE '%' + TMP.BillingTypeValue ) 
 OR 
	 ( TMP.BillingTypeOperator = 6 AND T.BillingType LIKE '%' + TMP.BillingTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.InvoiceDefinitionOperator = -1 ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 0 AND T.InvoiceDefinition IS NULL ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 1 AND T.InvoiceDefinition IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 2 AND T.InvoiceDefinition = TMP.InvoiceDefinitionValue ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 3 AND T.InvoiceDefinition <> TMP.InvoiceDefinitionValue ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 4 AND T.InvoiceDefinition LIKE TMP.InvoiceDefinitionValue + '%') 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 5 AND T.InvoiceDefinition LIKE '%' + TMP.InvoiceDefinitionValue ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 6 AND T.InvoiceDefinition LIKE '%' + TMP.InvoiceDefinitionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LineSequenceOperator = -1 ) 
 OR 
	 ( TMP.LineSequenceOperator = 0 AND T.LineSequence IS NULL ) 
 OR 
	 ( TMP.LineSequenceOperator = 1 AND T.LineSequence IS NOT NULL ) 
 OR 
	 ( TMP.LineSequenceOperator = 2 AND T.LineSequence = TMP.LineSequenceValue ) 
 OR 
	 ( TMP.LineSequenceOperator = 3 AND T.LineSequence <> TMP.LineSequenceValue ) 
 OR 
	 ( TMP.LineSequenceOperator = 7 AND T.LineSequence > TMP.LineSequenceValue ) 
 OR 
	 ( TMP.LineSequenceOperator = 8 AND T.LineSequence >= TMP.LineSequenceValue ) 
 OR 
	 ( TMP.LineSequenceOperator = 9 AND T.LineSequence < TMP.LineSequenceValue ) 
 OR 
	 ( TMP.LineSequenceOperator = 10 AND T.LineSequence <= TMP.LineSequenceValue ) 

 ) 

 AND 

 ( 
	 ( TMP.LineNameOperator = -1 ) 
 OR 
	 ( TMP.LineNameOperator = 0 AND T.LineName IS NULL ) 
 OR 
	 ( TMP.LineNameOperator = 1 AND T.LineName IS NOT NULL ) 
 OR 
	 ( TMP.LineNameOperator = 2 AND T.LineName = TMP.LineNameValue ) 
 OR 
	 ( TMP.LineNameOperator = 3 AND T.LineName <> TMP.LineNameValue ) 
 OR 
	 ( TMP.LineNameOperator = 4 AND T.LineName LIKE TMP.LineNameValue + '%') 
 OR 
	 ( TMP.LineNameOperator = 5 AND T.LineName LIKE '%' + TMP.LineNameValue ) 
 OR 
	 ( TMP.LineNameOperator = 6 AND T.LineName LIKE '%' + TMP.LineNameValue + '%' ) 
 ) 
 AND 

 ( 
	 ( TMP.InternalCommentOperator = -1 ) 
 OR 
	 ( TMP.InternalCommentOperator = 0 AND T.InternalComment IS NULL ) 
 OR 
	 ( TMP.InternalCommentOperator = 1 AND T.InternalComment IS NOT NULL ) 
 OR 
	 ( TMP.InternalCommentOperator = 2 AND T.InternalComment = TMP.InternalCommentValue ) 
 OR 
	 ( TMP.InternalCommentOperator = 3 AND T.InternalComment <> TMP.InternalCommentValue ) 
 OR 
	 ( TMP.InternalCommentOperator = 4 AND T.InternalComment LIKE TMP.InternalCommentValue + '%') 
 OR 
	 ( TMP.InternalCommentOperator = 5 AND T.InternalComment LIKE '%' + TMP.InternalCommentValue ) 
 OR 
	 ( TMP.InternalCommentOperator = 6 AND T.InternalComment LIKE '%' + TMP.InternalCommentValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ServiceCodeOperator = -1 ) 
 OR 
	 ( TMP.ServiceCodeOperator = 0 AND T.ServiceCode IS NULL ) 
 OR 
	 ( TMP.ServiceCodeOperator = 1 AND T.ServiceCode IS NOT NULL ) 
 OR 
	 ( TMP.ServiceCodeOperator = 2 AND T.ServiceCode = TMP.ServiceCodeValue ) 
 OR 
	 ( TMP.ServiceCodeOperator = 3 AND T.ServiceCode <> TMP.ServiceCodeValue ) 
 OR 
	 ( TMP.ServiceCodeOperator = 4 AND T.ServiceCode LIKE TMP.ServiceCodeValue + '%') 
 OR 
	 ( TMP.ServiceCodeOperator = 5 AND T.ServiceCode LIKE '%' + TMP.ServiceCodeValue ) 
 OR 
	 ( TMP.ServiceCodeOperator = 6 AND T.ServiceCode LIKE '%' + TMP.ServiceCodeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.BillingDetailNameOperator = -1 ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 0 AND T.BillingDetailName IS NULL ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 1 AND T.BillingDetailName IS NOT NULL ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 2 AND T.BillingDetailName = TMP.BillingDetailNameValue ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 3 AND T.BillingDetailName <> TMP.BillingDetailNameValue ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 4 AND T.BillingDetailName LIKE TMP.BillingDetailNameValue + '%') 
 OR 
	 ( TMP.BillingDetailNameOperator = 5 AND T.BillingDetailName LIKE '%' + TMP.BillingDetailNameValue ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 6 AND T.BillingDetailName LIKE '%' + TMP.BillingDetailNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.QuantityOperator = -1 ) 
 OR 
	 ( TMP.QuantityOperator = 0 AND T.Quantity IS NULL ) 
 OR 
	 ( TMP.QuantityOperator = 1 AND T.Quantity IS NOT NULL ) 
 OR 
	 ( TMP.QuantityOperator = 2 AND T.Quantity = TMP.QuantityValue ) 
 OR 
	 ( TMP.QuantityOperator = 3 AND T.Quantity <> TMP.QuantityValue ) 
 OR 
	 ( TMP.QuantityOperator = 7 AND T.Quantity > TMP.QuantityValue ) 
 OR 
	 ( TMP.QuantityOperator = 8 AND T.Quantity >= TMP.QuantityValue ) 
 OR 
	 ( TMP.QuantityOperator = 9 AND T.Quantity < TMP.QuantityValue ) 
 OR 
	 ( TMP.QuantityOperator = 10 AND T.Quantity <= TMP.QuantityValue ) 

 ) 

 AND 

 ( 
	 ( TMP.DetailStatusOperator = -1 ) 
 OR 
	 ( TMP.DetailStatusOperator = 0 AND T.DetailStatus IS NULL ) 
 OR 
	 ( TMP.DetailStatusOperator = 1 AND T.DetailStatus IS NOT NULL ) 
 OR 
	 ( TMP.DetailStatusOperator = 2 AND T.DetailStatus = TMP.DetailStatusValue ) 
 OR 
	 ( TMP.DetailStatusOperator = 3 AND T.DetailStatus <> TMP.DetailStatusValue ) 
 OR 
	 ( TMP.DetailStatusOperator = 4 AND T.DetailStatus LIKE TMP.DetailStatusValue + '%') 
 OR 
	 ( TMP.DetailStatusOperator = 5 AND T.DetailStatus LIKE '%' + TMP.DetailStatusValue ) 
 OR 
	 ( TMP.DetailStatusOperator = 6 AND T.DetailStatus LIKE '%' + TMP.DetailStatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DetailDispositionOperator = -1 ) 
 OR 
	 ( TMP.DetailDispositionOperator = 0 AND T.DetailDisposition IS NULL ) 
 OR 
	 ( TMP.DetailDispositionOperator = 1 AND T.DetailDisposition IS NOT NULL ) 
 OR 
	 ( TMP.DetailDispositionOperator = 2 AND T.DetailDisposition = TMP.DetailDispositionValue ) 
 OR 
	 ( TMP.DetailDispositionOperator = 3 AND T.DetailDisposition <> TMP.DetailDispositionValue ) 
 OR 
	 ( TMP.DetailDispositionOperator = 4 AND T.DetailDisposition LIKE TMP.DetailDispositionValue + '%') 
 OR 
	 ( TMP.DetailDispositionOperator = 5 AND T.DetailDisposition LIKE '%' + TMP.DetailDispositionValue ) 
 OR 
	 ( TMP.DetailDispositionOperator = 6 AND T.DetailDisposition LIKE '%' + TMP.DetailDispositionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.AdjustmentReasonOperator = -1 ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 0 AND T.AdjustmentReason IS NULL ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 1 AND T.AdjustmentReason IS NOT NULL ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 2 AND T.AdjustmentReason = TMP.AdjustmentReasonValue ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 3 AND T.AdjustmentReason <> TMP.AdjustmentReasonValue ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 4 AND T.AdjustmentReason LIKE TMP.AdjustmentReasonValue + '%') 
 OR 
	 ( TMP.AdjustmentReasonOperator = 5 AND T.AdjustmentReason LIKE '%' + TMP.AdjustmentReasonValue ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 6 AND T.AdjustmentReason LIKE '%' + TMP.AdjustmentReasonValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.AdjustmentDateOperator = -1 ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 0 AND T.AdjustmentDate IS NULL ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 1 AND T.AdjustmentDate IS NOT NULL ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 2 AND T.AdjustmentDate = TMP.AdjustmentDateValue ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 3 AND T.AdjustmentDate <> TMP.AdjustmentDateValue ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 7 AND T.AdjustmentDate > TMP.AdjustmentDateValue ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 8 AND T.AdjustmentDate >= TMP.AdjustmentDateValue ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 9 AND T.AdjustmentDate < TMP.AdjustmentDateValue ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 10 AND T.AdjustmentDate <= TMP.AdjustmentDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.AdjustedByOperator = -1 ) 
 OR 
	 ( TMP.AdjustedByOperator = 0 AND T.AdjustedBy IS NULL ) 
 OR 
	 ( TMP.AdjustedByOperator = 1 AND T.AdjustedBy IS NOT NULL ) 
 OR 
	 ( TMP.AdjustedByOperator = 2 AND T.AdjustedBy = TMP.AdjustedByValue ) 
 OR 
	 ( TMP.AdjustedByOperator = 3 AND T.AdjustedBy <> TMP.AdjustedByValue ) 
 OR 
	 ( TMP.AdjustedByOperator = 4 AND T.AdjustedBy LIKE TMP.AdjustedByValue + '%') 
 OR 
	 ( TMP.AdjustedByOperator = 5 AND T.AdjustedBy LIKE '%' + TMP.AdjustedByValue ) 
 OR 
	 ( TMP.AdjustedByOperator = 6 AND T.AdjustedBy LIKE '%' + TMP.AdjustedByValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.SourceRecordNumberOperator = -1 ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 0 AND T.SourceRecordNumber IS NULL ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 1 AND T.SourceRecordNumber IS NOT NULL ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 2 AND T.SourceRecordNumber = TMP.SourceRecordNumberValue ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 3 AND T.SourceRecordNumber <> TMP.SourceRecordNumberValue ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 4 AND T.SourceRecordNumber LIKE TMP.SourceRecordNumberValue + '%') 
 OR 
	 ( TMP.SourceRecordNumberOperator = 5 AND T.SourceRecordNumber LIKE '%' + TMP.SourceRecordNumberValue ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 6 AND T.SourceRecordNumber LIKE '%' + TMP.SourceRecordNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = -1 ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 0 AND T.BillingInvoiceScheduleTypeID IS NULL ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 1 AND T.BillingInvoiceScheduleTypeID IS NOT NULL ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 2 AND T.BillingInvoiceScheduleTypeID = TMP.BillingInvoiceScheduleTypeIDValue ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 3 AND T.BillingInvoiceScheduleTypeID <> TMP.BillingInvoiceScheduleTypeIDValue ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 7 AND T.BillingInvoiceScheduleTypeID > TMP.BillingInvoiceScheduleTypeIDValue ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 8 AND T.BillingInvoiceScheduleTypeID >= TMP.BillingInvoiceScheduleTypeIDValue ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 9 AND T.BillingInvoiceScheduleTypeID < TMP.BillingInvoiceScheduleTypeIDValue ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 10 AND T.BillingInvoiceScheduleTypeID <= TMP.BillingInvoiceScheduleTypeIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.EventAmountOperator = -1 ) 
 OR 
	 ( TMP.EventAmountOperator = 0 AND T.EventAmount IS NULL ) 
 OR 
	 ( TMP.EventAmountOperator = 1 AND T.EventAmount IS NOT NULL ) 
 OR 
	 ( TMP.EventAmountOperator = 2 AND T.EventAmount = TMP.EventAmountValue ) 
 OR 
	 ( TMP.EventAmountOperator = 3 AND T.EventAmount <> TMP.EventAmountValue ) 
 OR 
	 ( TMP.EventAmountOperator = 7 AND T.EventAmount > TMP.EventAmountValue ) 
 OR 
	 ( TMP.EventAmountOperator = 8 AND T.EventAmount >= TMP.EventAmountValue ) 
 OR 
	 ( TMP.EventAmountOperator = 9 AND T.EventAmount < TMP.EventAmountValue ) 
 OR 
	 ( TMP.EventAmountOperator = 10 AND T.EventAmount <= TMP.EventAmountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.RateTypeNameOperator = -1 ) 
 OR 
	 ( TMP.RateTypeNameOperator = 0 AND T.RateTypeName IS NULL ) 
 OR 
	 ( TMP.RateTypeNameOperator = 1 AND T.RateTypeName IS NOT NULL ) 
 OR 
	 ( TMP.RateTypeNameOperator = 2 AND T.RateTypeName = TMP.RateTypeNameValue ) 
 OR 
	 ( TMP.RateTypeNameOperator = 3 AND T.RateTypeName <> TMP.RateTypeNameValue ) 
 OR 
	 ( TMP.RateTypeNameOperator = 4 AND T.RateTypeName LIKE TMP.RateTypeNameValue + '%') 
 OR 
	 ( TMP.RateTypeNameOperator = 5 AND T.RateTypeName LIKE '%' + TMP.RateTypeNameValue ) 
 OR 
	 ( TMP.RateTypeNameOperator = 6 AND T.RateTypeName LIKE '%' + TMP.RateTypeNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ExcludedReasonOperator = -1 ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 0 AND T.ExcludedReason IS NULL ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 1 AND T.ExcludedReason IS NOT NULL ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 2 AND T.ExcludedReason = TMP.ExcludedReasonValue ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 3 AND T.ExcludedReason <> TMP.ExcludedReasonValue ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 4 AND T.ExcludedReason LIKE TMP.ExcludedReasonValue + '%') 
 OR 
	 ( TMP.ExcludedReasonOperator = 5 AND T.ExcludedReason LIKE '%' + TMP.ExcludedReasonValue ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 6 AND T.ExcludedReason LIKE '%' + TMP.ExcludedReasonValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ExcludeDateOperator = -1 ) 
 OR 
	 ( TMP.ExcludeDateOperator = 0 AND T.ExcludeDate IS NULL ) 
 OR 
	 ( TMP.ExcludeDateOperator = 1 AND T.ExcludeDate IS NOT NULL ) 
 OR 
	 ( TMP.ExcludeDateOperator = 2 AND T.ExcludeDate = TMP.ExcludeDateValue ) 
 OR 
	 ( TMP.ExcludeDateOperator = 3 AND T.ExcludeDate <> TMP.ExcludeDateValue ) 
 OR 
	 ( TMP.ExcludeDateOperator = 7 AND T.ExcludeDate > TMP.ExcludeDateValue ) 
 OR 
	 ( TMP.ExcludeDateOperator = 8 AND T.ExcludeDate >= TMP.ExcludeDateValue ) 
 OR 
	 ( TMP.ExcludeDateOperator = 9 AND T.ExcludeDate < TMP.ExcludeDateValue ) 
 OR 
	 ( TMP.ExcludeDateOperator = 10 AND T.ExcludeDate <= TMP.ExcludeDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ExcludedByOperator = -1 ) 
 OR 
	 ( TMP.ExcludedByOperator = 0 AND T.ExcludedBy IS NULL ) 
 OR 
	 ( TMP.ExcludedByOperator = 1 AND T.ExcludedBy IS NOT NULL ) 
 OR 
	 ( TMP.ExcludedByOperator = 2 AND T.ExcludedBy = TMP.ExcludedByValue ) 
 OR 
	 ( TMP.ExcludedByOperator = 3 AND T.ExcludedBy <> TMP.ExcludedByValue ) 
 OR 
	 ( TMP.ExcludedByOperator = 4 AND T.ExcludedBy LIKE TMP.ExcludedByValue + '%') 
 OR 
	 ( TMP.ExcludedByOperator = 5 AND T.ExcludedBy LIKE '%' + TMP.ExcludedByValue ) 
 OR 
	 ( TMP.ExcludedByOperator = 6 AND T.ExcludedBy LIKE '%' + TMP.ExcludedByValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.EntityOperator = -1 ) 
 OR 
	 ( TMP.EntityOperator = 0 AND T.Entity IS NULL ) 
 OR 
	 ( TMP.EntityOperator = 1 AND T.Entity IS NOT NULL ) 
 OR 
	 ( TMP.EntityOperator = 2 AND T.Entity = TMP.EntityValue ) 
 OR 
	 ( TMP.EntityOperator = 3 AND T.Entity <> TMP.EntityValue ) 
 OR 
	 ( TMP.EntityOperator = 4 AND T.Entity LIKE TMP.EntityValue + '%') 
 OR 
	 ( TMP.EntityOperator = 5 AND T.Entity LIKE '%' + TMP.EntityValue ) 
 OR 
	 ( TMP.EntityOperator = 6 AND T.Entity LIKE '%' + TMP.EntityValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ClientOperator = -1 ) 
 OR 
	 ( TMP.ClientOperator = 0 AND T.Client IS NULL ) 
 OR 
	 ( TMP.ClientOperator = 1 AND T.Client IS NOT NULL ) 
 OR 
	 ( TMP.ClientOperator = 2 AND T.Client = TMP.ClientValue ) 
 OR 
	 ( TMP.ClientOperator = 3 AND T.Client <> TMP.ClientValue ) 
 OR 
	 ( TMP.ClientOperator = 4 AND T.Client LIKE TMP.ClientValue + '%') 
 OR 
	 ( TMP.ClientOperator = 5 AND T.Client LIKE '%' + TMP.ClientValue ) 
 OR 
	 ( TMP.ClientOperator = 6 AND T.Client LIKE '%' + TMP.ClientValue + '%' ) 
 ) 
 
 AND 

 ( 
	 ( TMP.PurchaseOrderOperator = -1 ) 
 OR 
	 ( TMP.PurchaseOrderOperator = 0 AND T.PurchaseOrder IS NULL ) 
 OR 
	 ( TMP.PurchaseOrderOperator = 1 AND T.PurchaseOrder IS NOT NULL ) 
 OR 
	 ( TMP.PurchaseOrderOperator = 2 AND T.PurchaseOrder = TMP.PurchaseOrderValue ) 
 OR 
	 ( TMP.PurchaseOrderOperator = 3 AND T.PurchaseOrder <> TMP.PurchaseOrderValue ) 
 OR 
	 ( TMP.PurchaseOrderOperator = 4 AND T.PurchaseOrder LIKE TMP.PurchaseOrderValue + '%') 
 OR 
	 ( TMP.PurchaseOrderOperator = 5 AND T.PurchaseOrder LIKE '%' + TMP.PurchaseOrderValue ) 
 OR 
	 ( TMP.PurchaseOrderOperator = 6 AND T.PurchaseOrder LIKE '%' + TMP.PurchaseOrderValue + '%' ) 
 ) 


 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'BillingInvoiceDetailID' AND @sortOrder = 'ASC'
	 THEN T.BillingInvoiceDetailID END ASC, 
	 CASE WHEN @sortColumn = 'BillingInvoiceDetailID' AND @sortOrder = 'DESC'
	 THEN T.BillingInvoiceDetailID END DESC ,

	 CASE WHEN @sortColumn = 'BillingType' AND @sortOrder = 'ASC'
	 THEN T.BillingType END ASC, 
	 CASE WHEN @sortColumn = 'BillingType' AND @sortOrder = 'DESC'
	 THEN T.BillingType END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceDefinition' AND @sortOrder = 'ASC'
	 THEN T.InvoiceDefinition END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDefinition' AND @sortOrder = 'DESC'
	 THEN T.InvoiceDefinition END DESC ,

	 CASE WHEN @sortColumn = 'LineSequence' AND @sortOrder = 'ASC'
	 THEN T.LineSequence END ASC, 
	 CASE WHEN @sortColumn = 'LineSequence' AND @sortOrder = 'DESC'
	 THEN T.LineSequence END DESC ,

	 CASE WHEN @sortColumn = 'LineName' AND @sortOrder = 'ASC'
	 THEN T.LineName END ASC, 
	 CASE WHEN @sortColumn = 'LineName' AND @sortOrder = 'DESC'
	 THEN T.LineName END DESC ,

	 CASE WHEN @sortColumn = 'ServiceCode' AND @sortOrder = 'ASC'
	 THEN T.ServiceCode END ASC, 
	 CASE WHEN @sortColumn = 'ServiceCode' AND @sortOrder = 'DESC'
	 THEN T.ServiceCode END DESC ,

	 CASE WHEN @sortColumn = 'BillingDetailName' AND @sortOrder = 'ASC'
	 THEN T.BillingDetailName END ASC, 
	 CASE WHEN @sortColumn = 'BillingDetailName' AND @sortOrder = 'DESC'
	 THEN T.BillingDetailName END DESC ,

	 CASE WHEN @sortColumn = 'Quantity' AND @sortOrder = 'ASC'
	 THEN T.Quantity END ASC, 
	 CASE WHEN @sortColumn = 'Quantity' AND @sortOrder = 'DESC'
	 THEN T.Quantity END DESC ,

	 CASE WHEN @sortColumn = 'DetailStatus' AND @sortOrder = 'ASC'
	 THEN T.DetailStatus END ASC, 
	 CASE WHEN @sortColumn = 'DetailStatus' AND @sortOrder = 'DESC'
	 THEN T.DetailStatus END DESC ,

	 CASE WHEN @sortColumn = 'DetailDisposition' AND @sortOrder = 'ASC'
	 THEN T.DetailDisposition END ASC, 
	 CASE WHEN @sortColumn = 'DetailDisposition' AND @sortOrder = 'DESC'
	 THEN T.DetailDisposition END DESC ,

	 CASE WHEN @sortColumn = 'AdjustmentReason' AND @sortOrder = 'ASC'
	 THEN T.AdjustmentReason END ASC, 
	 CASE WHEN @sortColumn = 'AdjustmentReason' AND @sortOrder = 'DESC'
	 THEN T.AdjustmentReason END DESC ,

	 CASE WHEN @sortColumn = 'AdjustmentDate' AND @sortOrder = 'ASC'
	 THEN T.AdjustmentDate END ASC, 
	 CASE WHEN @sortColumn = 'AdjustmentDate' AND @sortOrder = 'DESC'
	 THEN T.AdjustmentDate END DESC ,

	 CASE WHEN @sortColumn = 'AdjustedBy' AND @sortOrder = 'ASC'
	 THEN T.AdjustedBy END ASC, 
	 CASE WHEN @sortColumn = 'AdjustedBy' AND @sortOrder = 'DESC'
	 THEN T.AdjustedBy END DESC ,

	 CASE WHEN @sortColumn = 'SourceRecordNumber' AND @sortOrder = 'ASC'
	 THEN T.SourceRecordNumber END ASC, 
	 CASE WHEN @sortColumn = 'SourceRecordNumber' AND @sortOrder = 'DESC'
	 THEN T.SourceRecordNumber END DESC ,

	 CASE WHEN @sortColumn = 'BillingInvoiceScheduleTypeID' AND @sortOrder = 'ASC'
	 THEN T.BillingInvoiceScheduleTypeID END ASC, 
	 CASE WHEN @sortColumn = 'BillingInvoiceScheduleTypeID' AND @sortOrder = 'DESC'
	 THEN T.BillingInvoiceScheduleTypeID END DESC ,

	 CASE WHEN @sortColumn = 'EventAmount' AND @sortOrder = 'ASC'
	 THEN T.EventAmount END ASC, 
	 CASE WHEN @sortColumn = 'EventAmount' AND @sortOrder = 'DESC'
	 THEN T.EventAmount END DESC ,

	 CASE WHEN @sortColumn = 'RateTypeName' AND @sortOrder = 'ASC'
	 THEN T.RateTypeName END ASC, 
	 CASE WHEN @sortColumn = 'RateTypeName' AND @sortOrder = 'DESC'
	 THEN T.RateTypeName END DESC ,

	 CASE WHEN @sortColumn = 'ExcludedReason' AND @sortOrder = 'ASC'
	 THEN T.ExcludedReason END ASC, 
	 CASE WHEN @sortColumn = 'ExcludedReason' AND @sortOrder = 'DESC'
	 THEN T.ExcludedReason END DESC ,

	 CASE WHEN @sortColumn = 'ExcludeDate' AND @sortOrder = 'ASC'
	 THEN T.ExcludeDate END ASC, 
	 CASE WHEN @sortColumn = 'ExcludeDate' AND @sortOrder = 'DESC'
	 THEN T.ExcludeDate END DESC ,

	 CASE WHEN @sortColumn = 'ExcludedBy' AND @sortOrder = 'ASC'
	 THEN T.ExcludedBy END ASC, 
	 CASE WHEN @sortColumn = 'ExcludedBy' AND @sortOrder = 'DESC'
	 THEN T.ExcludedBy END DESC ,

	 CASE WHEN @sortColumn = 'Entity' AND @sortOrder = 'ASC'
	 THEN T.Entity END ASC, 
	 CASE WHEN @sortColumn = 'Entity' AND @sortOrder = 'DESC'
	 THEN T.Entity END DESC ,

	 CASE WHEN @sortColumn = 'Client' AND @sortOrder = 'ASC'
	 THEN T.Client END ASC, 
	 CASE WHEN @sortColumn = 'Client' AND @sortOrder = 'DESC'
	 THEN T.Client END DESC ,

	 CASE WHEN @sortColumn = 'InternalComment' AND @sortOrder = 'ASC'
	 THEN T.InternalComment END ASC, 
	 CASE WHEN @sortColumn = 'InternalComment' AND @sortOrder = 'DESC'
	 THEN T.InternalComment END DESC 	 ,

	 CASE WHEN @sortColumn = 'PurchaseOrder' AND @sortOrder = 'ASC'
	 THEN T.PurchaseOrder END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrder' AND @sortOrder = 'DESC'
	 THEN T.PurchaseOrder END DESC 


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
DROP TABLE #FinalResults_filtered
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
 WHERE id = object_id(N'[dbo].[dms_closedloop_search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_closedloop_search] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dbo].[dms_closedloop_search]
 
 CREATE PROCEDURE [dbo].[dms_closedloop_search](   
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
ServiceRequestIDOperator="-1" 
MemberNumberOperator="-1" 
MemberNameOperator="-1" 
CallbackNumberOperator="-1" 
ServiceTypeOperator="-1" 
ElapsedTimeOperator="-1" 
LastNameOperator="-1" 
FirstNameOperator="-1"   

 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
ServiceRequestIDOperator INT NOT NULL,
ServiceRequestIDValue int NULL,
MemberNumberOperator INT NOT NULL,
MemberNumberValue nvarchar(50) NULL,
MemberNameOperator INT NOT NULL,
MemberNameValue nvarchar(200) NULL,
CallbackNumberOperator INT NOT NULL,
CallbackNumberValue nvarchar(50) NULL,
ServiceTypeOperator INT NOT NULL,
ServiceTypeValue nvarchar(50) NULL,
ElapsedTimeOperator INT NOT NULL,
ElapsedTimeValue nvarchar(50) NULL,
LastNameOperator INT NOT NULL,
LastNameValue nvarchar(50) NULL,
FirstNameOperator INT NOT NULL,  
FirstNameValue nvarchar(50) NULL  

)
DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ServiceRequestID int  NULL ,
	MemberNumber nvarchar(50)  NULL ,
	MemberName nvarchar(200)  NULL ,
	CallbackNumber nvarchar(50)  NULL ,
	ServiceType nvarchar(50)  NULL ,
	ElapsedTime nvarchar(50)  NULL ,
	LastName nvarchar(50)  NULL ,
	FirstName nvarchar(50)  NULL 
) 

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(ServiceRequestIDOperator,-1),
	ServiceRequestIDValue ,
	ISNULL(MemberNumberOperator,-1),
	MemberNumberValue ,
	ISNULL(MemberNameOperator,-1),
	MemberNameValue ,
	ISNULL(CallbackNumberOperator,-1),
	CallbackNumberValue ,
	ISNULL(ServiceTypeOperator,-1),
	ServiceTypeValue ,
	ISNULL(ElapsedTimeOperator,-1),
	ElapsedTimeValue ,
	ISNULL(LastNameOperator,-1),
	LastNameValue ,
	ISNULL(FirstNameOperator,-1),  
    FirstNameValue 
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
ServiceRequestIDOperator INT,
ServiceRequestIDValue int 
,MemberNumberOperator INT,
MemberNumberValue nvarchar(50) 
,MemberNameOperator INT,
MemberNameValue nvarchar(50) 
,CallbackNumberOperator INT,
CallbackNumberValue nvarchar(50) 
,ServiceTypeOperator INT,
ServiceTypeValue nvarchar(50) 
,ElapsedTimeOperator INT,
ElapsedTimeValue nvarchar(50) 
,LastNameOperator INT,
LastNameValue nvarchar(50) 
,FirstNameOperator INT,  
FirstNameValue nvarchar(50)   

 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults
SELECT 
	T.ServiceRequestID,
	T.MemberNumber,
	T.MemberName,
	T.CallbackNumber,
	T.ServiceType,
	T.ElapsedTime,
	T.LastName,
	T.FirstName
FROM (
		SELECT 
			  sr.ID as ServiceRequestID
			, ms.MembershipNumber as MemberNumber 
			,  REPLACE(RTRIM(COALESCE(m.FirstName, '') +COALESCE(' ' + left(m.MiddleName,1), '') + COALESCE(' ' + m.LastName, '') + COALESCE(' ' + m.Suffix, '')), ' ', ' ') as MemberName 
			, c.ContactPhoneNumber AS CallbackNumber
			, pc.Name as ServiceType
			, CONVERT(varchar(6), DATEDIFF(second,sr.CreateDate, getdate())/3600) + ':' + RIGHT('0' + CONVERT(varchar(2), (DATEDIFF(second, sr.CreateDate, getdate()) % 3600) / 60), 2) + ':' + RIGHT('0' + CONVERT(varchar(2), DATEDIFF(second, sr.CreateDate, getdate()) % 60), 2) as ElapsedTime  -- 7:32 PM  time the should have service...which time zone?
			,m.LastName
			,m.FirstName
		FROM ServiceRequest sr
		join ContactLogLink cll on cll.RecordID = sr.ID and cll.EntityID = (select ID from Entity where Name = 'ServiceRequest')
		join ContactLog cl on cl.ID = cll.ContactLogID
		join ContactLogAction cla on cla.ContactLogID = cl.ID 
		join ContactAction ca on ca.ID = cla.ContactActionID 
		join [Case] c on c.ID = sr.CaseID
		join Member m on m.ID = c.MemberID
		join Membership ms on ms.ID = m.MembershipID
		join ProductCategory pc on pc.ID = sr.ProductCategoryID
		WHERE
			cl.ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ClosedLoop')
			AND ca.ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ClosedLoop')
			--AND sr.ServiceRequestStatusID = (SELECT ID FROM ServiceRequestStatus WHERE Name = 'Dispatched')
			AND sr.ServiceRequestStatusID NOT IN (SELECT ID FROM ServiceRequestStatus WHERE Name in ('Complete','Cancelled'))  
			AND ca.Name = 'ServiceNotArrived'
			group by sr.ID, ms.MembershipNumber, m.Firstname, m.Middlename, m.LastName, m.Suffix, c.ContactPhoneNumber, pc.Name, sr.CreateDate

        
  	 ) T,
@tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.ServiceRequestIDOperator = -1 ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 0 AND T.ServiceRequestID IS NULL ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 1 AND T.ServiceRequestID IS NOT NULL ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 2 AND T.ServiceRequestID = TMP.ServiceRequestIDValue ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 3 AND T.ServiceRequestID <> TMP.ServiceRequestIDValue ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 7 AND T.ServiceRequestID > TMP.ServiceRequestIDValue ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 8 AND T.ServiceRequestID >= TMP.ServiceRequestIDValue ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 9 AND T.ServiceRequestID < TMP.ServiceRequestIDValue ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 10 AND T.ServiceRequestID <= TMP.ServiceRequestIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.MemberNumberOperator = -1 ) 
 OR 
	 ( TMP.MemberNumberOperator = 0 AND T.MemberNumber IS NULL ) 
 OR 
	 ( TMP.MemberNumberOperator = 1 AND T.MemberNumber IS NOT NULL ) 
 OR 
	 ( TMP.MemberNumberOperator = 2 AND T.MemberNumber = TMP.MemberNumberValue ) 
 OR 
	 ( TMP.MemberNumberOperator = 3 AND T.MemberNumber <> TMP.MemberNumberValue ) 
 OR 
	 ( TMP.MemberNumberOperator = 4 AND T.MemberNumber LIKE TMP.MemberNumberValue + '%') 
 OR 
	 ( TMP.MemberNumberOperator = 5 AND T.MemberNumber LIKE '%' + TMP.MemberNumberValue ) 
 OR 
	 ( TMP.MemberNumberOperator = 6 AND T.MemberNumber LIKE '%' + TMP.MemberNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.MemberNameOperator = -1 ) 
 OR 
	 ( TMP.MemberNameOperator = 0 AND T.MemberName IS NULL ) 
 OR 
	 ( TMP.MemberNameOperator = 1 AND T.MemberName IS NOT NULL ) 
 OR 
	 ( TMP.MemberNameOperator = 2 AND T.MemberName = TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 3 AND T.MemberName <> TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 4 AND T.MemberName LIKE TMP.MemberNameValue + '%') 
 OR 
	 ( TMP.MemberNameOperator = 5 AND T.MemberName LIKE '%' + TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 6 AND T.MemberName LIKE '%' + TMP.MemberNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CallbackNumberOperator = -1 ) 
 OR 
	 ( TMP.CallbackNumberOperator = 0 AND T.CallbackNumber IS NULL ) 
 OR 
	 ( TMP.CallbackNumberOperator = 1 AND T.CallbackNumber IS NOT NULL ) 
 OR 
	 ( TMP.CallbackNumberOperator = 2 AND T.CallbackNumber = TMP.CallbackNumberValue ) 
 OR 
	 ( TMP.CallbackNumberOperator = 3 AND T.CallbackNumber <> TMP.CallbackNumberValue ) 
 OR 
	 ( TMP.CallbackNumberOperator = 4 AND T.CallbackNumber LIKE TMP.CallbackNumberValue + '%') 
 OR 
	 ( TMP.CallbackNumberOperator = 5 AND T.CallbackNumber LIKE '%' + TMP.CallbackNumberValue ) 
 OR 
	 ( TMP.CallbackNumberOperator = 6 AND T.CallbackNumber LIKE '%' + TMP.CallbackNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ServiceTypeOperator = -1 ) 
 OR 
	 ( TMP.ServiceTypeOperator = 0 AND T.ServiceType IS NULL ) 
 OR 
	 ( TMP.ServiceTypeOperator = 1 AND T.ServiceType IS NOT NULL ) 
 OR 
	 ( TMP.ServiceTypeOperator = 2 AND T.ServiceType = TMP.ServiceTypeValue ) 
 OR 
	 ( TMP.ServiceTypeOperator = 3 AND T.ServiceType <> TMP.ServiceTypeValue ) 
 OR 
	 ( TMP.ServiceTypeOperator = 4 AND T.ServiceType LIKE TMP.ServiceTypeValue + '%') 
 OR 
	 ( TMP.ServiceTypeOperator = 5 AND T.ServiceType LIKE '%' + TMP.ServiceTypeValue ) 
 OR 
	 ( TMP.ServiceTypeOperator = 6 AND T.ServiceType LIKE '%' + TMP.ServiceTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ElapsedTimeOperator = -1 ) 
 OR 
	 ( TMP.ElapsedTimeOperator = 0 AND T.ElapsedTime IS NULL ) 
 OR 
	 ( TMP.ElapsedTimeOperator = 1 AND T.ElapsedTime IS NOT NULL ) 
 OR 
	 ( TMP.ElapsedTimeOperator = 2 AND T.ElapsedTime = TMP.ElapsedTimeValue ) 
 OR 
	 ( TMP.ElapsedTimeOperator = 3 AND T.ElapsedTime <> TMP.ElapsedTimeValue ) 
 OR 
	 ( TMP.ElapsedTimeOperator = 4 AND T.ElapsedTime LIKE TMP.ElapsedTimeValue + '%') 
 OR 
	 ( TMP.ElapsedTimeOperator = 5 AND T.ElapsedTime LIKE '%' + TMP.ElapsedTimeValue ) 
 OR 
	 ( TMP.ElapsedTimeOperator = 6 AND T.ElapsedTime LIKE '%' + TMP.ElapsedTimeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LastNameOperator = -1 ) 
 OR 
	 ( TMP.LastNameOperator = 0 AND T.LastName IS NULL ) 
 OR 
	 ( TMP.LastNameOperator = 1 AND T.LastName IS NOT NULL ) 
 OR 
	 ( TMP.LastNameOperator = 2 AND T.LastName = TMP.LastNameValue ) 
 OR 
	 ( TMP.LastNameOperator = 3 AND T.LastName <> TMP.LastNameValue ) 
 OR 
	 ( TMP.LastNameOperator = 4 AND T.LastName LIKE TMP.LastNameValue + '%') 
 OR 
	 ( TMP.LastNameOperator = 5 AND T.LastName LIKE '%' + TMP.LastNameValue ) 
 OR 
	 ( TMP.LastNameOperator = 6 AND T.LastName LIKE '%' + TMP.LastNameValue + '%' ) 
 ) 
 AND   
  
 (   
  ( TMP.FirstNameOperator = -1 )   
 OR   
  ( TMP.FirstNameOperator = 0 AND T.FirstName IS NULL )   
 OR   
  ( TMP.FirstNameOperator = 1 AND T.FirstName IS NOT NULL )   
 OR   
  ( TMP.FirstNameOperator = 2 AND T.FirstName = TMP.FirstNameValue )   
 OR   
  ( TMP.FirstNameOperator = 3 AND T.FirstName <> TMP.FirstNameValue )   
 OR   
  ( TMP.FirstNameOperator = 4 AND T.FirstName LIKE TMP.FirstNameValue + '%')   
 OR   
  ( TMP.FirstNameOperator = 5 AND T.FirstName LIKE '%' + TMP.FirstNameValue )   
 OR   
  ( TMP.FirstNameOperator = 6 AND T.FirstName LIKE '%' + TMP.FirstNameValue + '%' )   
 )   

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ServiceRequestID' AND @sortOrder = 'ASC'
	 THEN T.ServiceRequestID END ASC, 
	 CASE WHEN @sortColumn = 'ServiceRequestID' AND @sortOrder = 'DESC'
	 THEN T.ServiceRequestID END DESC ,

	 CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'
	 THEN T.MemberNumber END ASC, 
	 CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'
	 THEN T.MemberNumber END DESC ,

	 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'
	 THEN T.MemberName END ASC, 
	 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'
	 THEN T.MemberName END DESC ,

	 CASE WHEN @sortColumn = 'CallbackNumber' AND @sortOrder = 'ASC'
	 THEN T.CallbackNumber END ASC, 
	 CASE WHEN @sortColumn = 'CallbackNumber' AND @sortOrder = 'DESC'
	 THEN T.CallbackNumber END DESC ,

	 CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'ASC'
	 THEN T.ServiceType END ASC, 
	 CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'DESC'
	 THEN T.ServiceType END DESC ,

	 CASE WHEN @sortColumn = 'ElapsedTime' AND @sortOrder = 'ASC'
	 THEN T.ElapsedTime END ASC, 
	 CASE WHEN @sortColumn = 'ElapsedTime' AND @sortOrder = 'DESC'
	 THEN T.ElapsedTime END DESC 


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
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Document_List_Get]')	AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Document_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
 --EXEC [dms_Document_List_Get] '',1,50,50,'Category','ASC','Vendor',5744,'VendorPortal'
 --EXEC [dms_Document_List_Get] '',1,50,50,'Category','ASC','Vendor',382,''
 CREATE PROCEDURE [dbo].[dms_Document_List_Get](    
   @whereClauseXML NVARCHAR(4000) = NULL     
  ,@startInd Int = 1     
  ,@endInd BIGINT = 5000     
  ,@pageSize int = 10      
  ,@sortColumn nvarchar(100)  = ''     
  ,@sortOrder nvarchar(100) = 'ASC'     
  ,@entityName nvarchar(50)
  ,@recordId int 
  ,@sourceSystem NVARCHAR(100) = NULL   
 )     
 AS     
 BEGIN     
SET NOCOUNT ON      
SET FMTONLY OFF    
   

CREATE TABLE #FinalResults     
(    
 [RowNum] [bigint] NOT NULL IDENTITY(1,1), 
 Category NVARCHAR(50) NULL,
 DocumentName NVARCHAR(255) NULL,
 Comment NVARCHAR(255) NULL,
 AddedBy NVARCHAR(50) NULL,
 DateAdded DATETIME NULL,
 DocumentId INT NULL
)    

INSERT INTO #FinalResults
SELECT DC.Name,D.Name,D.Comment,D.CreateBy,D.CreateDate,D.ID
FROM [Document] (NOLOCK) D
INNER JOIN [DocumentCategory] DC ON D.DocumentCategoryID  = DC.ID
WHERE D.EntityID = (SELECT TOP 1 ID FROM Entity WHERE Name = @entityName) AND D.RecordID = @recordId
AND((@sourceSystem IS NULL) OR (@entityName = 'Vendor' AND D.IsShownOnVendorPortal=1) OR (@sourceSystem = 'VendorPortal' AND @entityName = 'Vendor' AND
D.CreateBy IN (SELECT U.UserName
FROM VendorUser VU
JOIN aspnet_Users U ON U.UserID = VU.aspnet_UserID
WHERE VU.VendorID = @recordId
) AND D.IsShownOnVendorPortal=1 AND D.ISActive = 1)
)


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
    
SELECT @count AS TotalRows,Category,DocumentName,Comment,AddedBy,DateAdded,DocumentId
FROM #FinalResults WHERE RowNum BETWEEN @startInd AND @endInd    
ORDER BY 
	 CASE WHEN @sortColumn = 'Category' AND @sortOrder = 'ASC'
	 THEN Category END ASC, 
	 CASE WHEN @sortColumn = 'Category' AND @sortOrder = 'DESC'
	 THEN Category END DESC ,
	 
	 CASE WHEN @sortColumn = 'DocumentName' AND @sortOrder = 'ASC'
	 THEN DocumentName END ASC, 
	 CASE WHEN @sortColumn = 'DocumentName' AND @sortOrder = 'DESC'
	 THEN DocumentName END DESC ,
	 
	 CASE WHEN @sortColumn = 'Comment' AND @sortOrder = 'ASC'
	 THEN Comment END ASC, 
	 CASE WHEN @sortColumn = 'Comment' AND @sortOrder = 'DESC'
	 THEN Comment END DESC ,
	 
	 CASE WHEN @sortColumn = 'DateAdded' AND @sortOrder = 'ASC'
	 THEN DateAdded END ASC, 
	 CASE WHEN @sortColumn = 'DateAdded' AND @sortOrder = 'DESC'
	 THEN DateAdded END DESC 

DROP TABLE #FinalResults 	 
END
GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Get_Member_Information]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Get_Member_Information]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- exec dms_Get_Member_Information 541
CREATE PROC [dbo].[dms_Get_Member_Information](@memberID INT = NULL)
AS
BEGIN
	-- KB: Get membership ID of the current member.
	DECLARE @membershipID INT
	SELECT @membershipID = MembershipID FROM Member WHERE ID = @memberID

	DECLARE @memberEntityID INT
	SELECT @memberEntityID = ID FROM Entity WHERE Name = 'Member'

	--KB: Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'

	SET FMTONLY OFF;
	
	;WITH wResults
	AS
	(
	SELECT DISTINCT MS.ID AS MembershipID,
	M.ClientMemberType,
	MS.MembershipNumber,
	CASE MS.IsActive WHEN 1 THEN 'Active' ELSE 'Inactive' END AS MembershipStatus, -- KB: I don't think we are using this.
	P.[Description] AS Program,
	P.ID AS ProgramID,
	AD.Line1 AS Line1,
	PH.PhoneNumber AS HomePhoneNumber, 
	PW.PhoneNumber AS WorkPhoneNumber, 
	PC.PhoneNumber AS CellPhoneNumber,
	ISNULL(AD.City,'') + ' ' + ISNULL(AD.StateProvince,'') + ' ' +  ISNULL(AD.PostalCode,'') AS CityStateZip,
	CN.Name AS 'CountryName',
	M.Email,
	M.ID AS MemberID,
	CASE M.IsPrimary WHEN 1 THEN '*' ELSE '' END AS MasterMember,
	--ISNULL(M.FirstName,'') + ' ' + ISNULL(M.LastName,'') + ' ' + ISNULL(M.Suffix,'') AS MemberName,
	REPLACE(RTRIM( 
	COALESCE(M.FirstName, '') + 
	COALESCE(' ' + left(M.MiddleName,1), '') + 
	COALESCE(' ' + M.LastName, '') +
	COALESCE(' ' + M.Suffix, '')
	), ' ', ' ') AS MemberName,	
	-- KB: Considering Effective and Expiration Dates to calculate member status
	CASE WHEN ISNULL(m.EffectiveDate,@minDate) <= @now AND ISNULL(m.ExpirationDate,@minDate) >= @now
				THEN 'Active'
				ELSE 'Inactive'
	END AS MemberStatus,
	M.ExpirationDate,
	M.EffectiveDate,
	C.ID AS ClientID,
	C.Name AS ClientName,
	MS.Note AS MembershipNote	,
	M.FirstName,
	M.MiddleName,
	M.LastName,
	M.Suffix,
	M.Prefix
	FROM Member M
	LEFT JOIN Membership MS ON MS.ID = M.MembershipID
	LEFT JOIN Program P ON M.ProgramID = P.ID
	LEFT JOIN Client C ON P.ClientID = C.ID
	LEFT JOIN PhoneEntity PH ON PH.RecordID = M.ID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID 
	LEFT JOIN PhoneEntity PW ON PW.RecordID = M.ID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID 
	LEFT JOIN PhoneEntity PC ON PC.RecordID = M.ID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID 
	LEFT JOIN AddressEntity AD ON AD.RecordID = M.ID AND AD.EntityID = @memberEntityID
	LEFT JOIN Country CN ON CN.ISOCode = AD.CountryCode
	WHERE MS.ID =  @membershipID -- KB: Performing the check against the right attribute.
	)
	SELECT * FROM wResults M ORDER BY MasterMember DESC,MemberName

END


GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_MemberManagement_Search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_MemberManagement_Search]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
CREATE PROCEDURE [dbo].[dms_MemberManagement_Search](   
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10   
 , @sortColumn nvarchar(100)  = 'MemberNumber'   
 , @sortOrder nvarchar(100) = 'ASC'   
 )   
 AS   
 BEGIN   
    
	SET NOCOUNT ON    
	SET FMTONLY OFF
	
	-- KB : Temporary resultsets. These resultsets are used to prepare mangeable resultsets.
	CREATE TABLE #FinalResultsFiltered(     
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	Suffix nvarchar(50)  NULL ,    
	Prefix nvarchar(50)  NULL ,    
	City nvarchar(50)  NULL ,    
	StateProvince nvarchar(50)  NULL ,    
	PostalCode nvarchar(50)  NULL ,    
	HomePhoneNumber nvarchar(50)  NULL ,    
	WorkPhoneNumber nvarchar(50)  NULL ,    
	CellPhoneNumber nvarchar(50)  NULL ,    
	Program nvarchar(50)  NULL ,    
	POCount INT NULL,  
	ExpirationDate DATETIME NULL,   
	EffectiveDate DATETIME NULL,
	VIN nvarchar(50)  NULL ,    
	[StateProvinceID] INT  NULL,
	MiddleName   nvarchar(50)  NULL , 
	CountryCode nvarchar(2) NULL
	)    

	CREATE TABLE #FinalResultsFormatted(      
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL ,    
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,    
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL     
	)    

	CREATE TABLE #FinalResultsSorted(     
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL ,    
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,    
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL     
	)  
	
	--CREATE TABLE #FinalResultsDistinct(     
	--[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	--MemberID int  NULL ,   
	--MembershipID INT NULL,   
	--MemberNumber nvarchar(50)  NULL ,    
	--Name nvarchar(200)  NULL ,    
	--[Address] nvarchar(max)  NULL ,    
	--PhoneNumber nvarchar(50)  NULL ,    
	--Program nvarchar(50)  NULL ,    
	--POCount int  NULL ,    
	--MemberStatus nvarchar(50)  NULL ,    
	--LastName nvarchar(50)  NULL ,    
	--FirstName nvarchar(50)  NULL ,    
	--VIN nvarchar(50)  NULL ,    
	--State nvarchar(50)  NULL ,    
	--ZipCode nvarchar(50)  NULL     
	--)  

	DECLARE @idoc int    
	IF @whereClauseXML IS NULL     
	BEGIN    
	SET @whereClauseXML = '<ROW>
	<Filter     
	MemberIDOperator="-1"     
	MemberNumberOperator="-1"  
	FirstNameOperator="-1"  
	LastNameOperator="-1"      
	CountryIDOperator="-1"      
	StateProvinceIDOperator="-1"
	CityOperator="-1"
	PostalCodeOperator="-1"
	PhoneNumberOperator="-1"
	VINOperator="-1"
	MemberStatusOperator="-1"
	ClientIDOperator="-1"
	ProgramIDOperator="-1">
	</Filter></ROW>'    
	END    
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML    

	DECLARE @tmpForWhereClause TABLE    
		(    
		MemberIDOperator INT NOT NULL,    
		MemberIDValue int NULL,    
		
		MemberNumberOperator INT NOT NULL,    
		MemberNumberValue nvarchar(50) NULL,    
		
		FirstNameOperator INT NOT NULL,
		FirstNameValue nvarchar(50) NULL,  
		
		LastNameOperator INT NOT NULL,
		LastNameValue nvarchar(50) NULL,  
		
		CountryIDOperator INT NOT NULL,
		CountryIDValue INT NULL, 
		
		StateProvinceIDOperator INT NOT NULL,
		StateProvinceIDValue INT NULL, 
		
		CityOperator INT NOT NULL,
		CityValue nvarchar(50) NULL, 
		
		PostalCodeOperator INT NOT NULL,
		PostalCodeValue nvarchar(50) NULL, 
		
		PhoneNumberOperator INT NOT NULL,
		PhoneNumberValue nvarchar(50) NULL, 
		
		VINOperator INT NOT NULL,
		VINValue nvarchar(50) NULL, 
		
		MemberStatusOperator INT NOT NULL,
		MemberStatusValue nvarchar(50) NULL, 
		
		ClientIDOperator INT NOT NULL,
		ClientIDValue INT NULL, 
		
		ProgramIDOperator INT NOT NULL,
		ProgramIDValue INT NULL
		)    

	-- Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'     

	INSERT INTO @tmpForWhereClause    
	SELECT      
		ISNULL(MemberIDOperator,-1),    
		MemberIDValue ,    

		ISNULL(MemberNumberOperator,-1),    
		MemberNumberValue ,    

		ISNULL(FirstNameOperator,-1),    
		FirstNameValue ,    

		ISNULL(LastNameOperator,-1),    
		LastNameValue,

		ISNULL(CountryIDOperator,-1),    
		CountryIDValue,

		ISNULL(StateProvinceIDOperator,-1),    
		StateProvinceIDValue,

		ISNULL(CityOperator,-1),    
		CityValue,

		ISNULL(PostalCodeOperator,-1),    
		PostalCodeValue,

		ISNULL(PhoneNumberOperator,-1),    
		PhoneNumberValue,

		ISNULL(VINOperator,-1),    
		VINValue,

		ISNULL(MemberStatusOperator,-1),    
		MemberStatusValue,

		ISNULL(ClientIDOperator,-1),    
		ClientIDValue,

		ISNULL(ProgramIDOperator,-1),    
		ProgramIDValue
			 
	FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (    
		MemberIDOperator INT,    
		MemberIDValue int,

		MemberNumberOperator INT,    
		MemberNumberValue nvarchar(50),

		FirstNameOperator INT,    
		FirstNameValue nvarchar(50),

		LastNameOperator INT,    
		LastNameValue nvarchar(50),

		CountryIDOperator INT,    
		CountryIDValue INT,

		StateProvinceIDOperator INT,    
		StateProvinceIDValue INT,

		CityOperator INT,    
		CityValue nvarchar(50),

		PostalCodeOperator INT,    
		PostalCodeValue nvarchar(50),

		PhoneNumberOperator INT,    
		PhoneNumberValue nvarchar(50),

		VINOperator INT,    
		VINValue nvarchar(50),

		MemberStatusOperator INT,    
		MemberStatusValue nvarchar(50),

		ClientIDOperator INT,    
		ClientIDValue INT,

		ProgramIDOperator INT,    
		ProgramIDValue INT			  
		)     
	
	--SELECT * FROM @tmpForWhereClause
	
	DECLARE @memberEntityID INT ,
		@HomeAddressTypeID INT
	SELECT @memberEntityID = ID FROM Entity WHERE Name = 'Member'  
	SELECT @HomeAddressTypeID = ID FROM AddressType WHERE Name = 'Home'
 
	DECLARE @memberID INT
	DECLARE @memberNumber NVARCHAR(50)
	DECLARE @ProgramID INT = NULL
	DECLARE @ClientID INT = NULL
	DECLARE @firstName NVARCHAR(50)
	DECLARE @lastName NVARCHAR(50)
	DECLARE @stateID INT = NULL
	DECLARE @CountryID INT = NULL
	DECLARE @Zip NVARCHAR(50) = NULL
	DECLARE @City NVARCHAR(50) = NULL
	DECLARE @lastNameOperator INT = NULL
	DECLARE @firstNameOperator INT = NULL
	DECLARE @memberStatusValue NVARCHAR(200) = NULL
 	DECLARE @vinParam nvarchar(50) = NULL   
	DECLARE @phoneNumber NVARCHAR(100) = NULL

	SELECT	@memberID = MemberIDValue,
			@memberNumber = MemberNumberValue,
			@ProgramID = CASE WHEN ProgramIDValue = '-1' THEN NULL ELSE ProgramIDValue END,
			@ClientID = ClientIDValue,
			@firstName = FirstNameValue,
			@lastName = LastNameValue,
			@stateID =    StateProvinceIDValue,
			@CountryID =  CountryIDValue,
			@Zip = PostalCodeValue,
			@City = CityValue,
			@lastNameOperator = LastNameOperator,
			@firstNameOperator = FirstNameOperator,
			@memberStatusValue = MemberStatusValue,
			@PhoneNumber = REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumberValue,'(',''),' ',''),'-',''),')',''),  --Remove formatting
			@VinParam = VinValue
	FROM	@tmpForWhereClause

		
	SET FMTONLY OFF;  
	
	Declare @sql nvarchar(max) = ''
	
	SET @sql =        'SELECT DISTINCT TOP 1000'
	SET @sql = @sql + '  M.id AS MemberID'  
	SET @sql = @sql + ' ,M.MembershipID'
	SET @sql = @sql + ' ,CASE WHEN MS.MembershipNumber IS NULL THEN ''Ref#: '' + MS.ClientReferenceNUmber ELSE MS.MembershipNumber END AS MemberNumber'
	SET @sql = @sql + ' ,M.FirstName'
	SET @sql = @sql + ' ,M.LastName'
	SET @sql = @sql + ' ,M.Suffix'
	SET @sql = @sql + ' ,M.Prefix'     
	SET @sql = @sql + ' ,A.City' 
	SET @sql = @sql + ' ,A.StateProvince' 
	SET @sql = @sql + ' ,A.PostalCode' 
	SET @sql = @sql + ' ,NULL' -- HomePhoneNumber 
	SET @sql = @sql + ' ,NULL' -- WorkPhoneNumber  
	SET @sql = @sql + ' ,NULL' -- CellPhoneNumber 
	SET @sql = @sql + ' ,P.[Description]' --  Program    
	SET @sql = @sql + ' ,0 ' -- AS POCount   
	SET @sql = @sql + ' ,m.ExpirationDate'  
	SET @sql = @sql + ' ,m.EffectiveDate'
	SET @sql = @sql + ' ,(SELECT TOP 1 V.VIN FROM Vehicle V WHERE V.MembershipID = MS.ID'
					+ CASE WHEN @vinParam IS NOT NULL THEN ' AND V.VIN = @vinParam)' ELSE ')' END
	SET @sql = @sql + ' ,A.[StateProvinceID]'
	SET @sql = @sql + ' ,M.MiddleName'
	SET @sql = @sql + ' ,A.CountryCode'
	SET @sql = @sql + ' FROM Member M WITH (NOLOCK)'
	SET @sql = @sql + ' JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID'
	SET @sql = @sql + ' JOIN Program P WITH (NOLOCK) ON P.ID = M.ProgramID'
	SET @sql = @sql + ' JOIN Client C WITH (NOLOCK) ON P.ClientID = C.ID'
	SET @sql = @sql + ' LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = ' + CONVERT(nvarchar(50), @memberEntityID) + ' and A.AddressTypeID = '  + CONVERT(nvarchar(50), @HomeAddressTypeID)		

	SET @sql = @sql + ' WHERE  M.IsPrimary =1'
	
	IF @memberNumber IS NOT NULL
	SET @sql = @sql + ' AND (MS.MembershipNumber LIKE char(37) + @memberNumber + char(37) OR MS.AltMembershipNumber LIKE  char(37) + @memberNumber + char(37))'  
	
	IF @vinParam IS NOT NULL 
	SET @sql = @sql + ' AND MS.ID IN (SELECT v1.MembershipID FROM Vehicle v1 WHERE v1.VIN = @vinParam)'
	
	IF @phoneNumber IS NOT NULL
	SET @sql = @sql + ' AND M.ID IN (SELECT PH.RecordID FROM PhoneEntity PH WITH (NOLOCK) WHERE PH.EntityID = ' + CONVERT(nvarchar(50), @memberEntityID) + ' AND PH.PhoneNumber LIKE char(37) + @phoneNumber + char(37))'

	IF @ClientID IS NOT NULL
	SET @sql = @sql + ' AND C.ID = @ClientID'  

	IF @ProgramID IS NOT NULL
	SET @sql = @sql + ' AND P.ID = @ProgramID' 
		
	IF @StateID IS NOT NULL
	SET @sql = @sql + ' AND A.StateProvinceID = @StateID'  
	
	IF @CountryID IS NOT NULL
	SET @sql = @sql + ' AND A.CountryID = @CountryID' 
	
	IF @Zip IS NOT NULL
	SET @sql = @sql + ' AND A.PostalCode LIKE char(37) + @Zip + char(37)' 
	
	IF @City IS NOT NULL
	SET @sql = @sql + ' AND A.PostalCode LIKE @City + char(37)' 
	
	IF @lastName IS NOT NULL AND @lastNameOperator = 2	
	SET @sql = @sql + ' AND M.LastName = @LastName'  
	
	IF @lastName IS NOT NULL AND @lastNameOperator IN (4,5,6)
	SET @sql = @sql + ' AND M.LastName Like ' 
					+ CASE WHEN @lastNameOperator IN (5,6) THEN 'char(37)+' ELSE '' END
					+ '@LastName' 
					+ CASE WHEN @lastNameOperator IN (4,6) THEN '+char(37)' ELSE '' END
					--+ ''''
					
	IF @firstName IS NOT NULL AND @firstNameOperator = 2	
	SET @sql = @sql + ' AND M.FirstName = @FirstName'  
	
	IF @firstName IS NOT NULL AND @firstNameOperator IN (4,5,6)
	SET @sql = @sql + ' AND M.FirstName Like ' 
					+ CASE WHEN @firstNameOperator IN (5,6) THEN 'char(37)+' ELSE '' END
					+ ' @FirstName ' 
					+ CASE WHEN @firstNameOperator IN (4,6) THEN '+char(37)' ELSE '' END
					--+ ''''
					
	IF @memberStatusValue IS NOT NULL AND EXISTS (SELECT item FROM fnSplitString(@memberStatusValue,',') WHERE item = 'Active') AND NOT EXISTS (SELECT item FROM fnSplitString(@memberStatusValue,',') WHERE item = 'Inactive') 
	SET @sql = @sql + ' AND M.EffectiveDate <= ''' + CONVERT(nvarchar(50),@now,101) + ''' AND ISNULL(M.ExpirationDate,''' + CONVERT(nvarchar(50),@now,101) + ''') >= ''' + CONVERT(nvarchar(50),@now,101) + '''' 
					
	IF @memberStatusValue IS NOT NULL AND EXISTS (SELECT item FROM fnSplitString(@memberStatusValue,',') WHERE item = 'Inactive') AND NOT EXISTS (SELECT item FROM fnSplitString(@memberStatusValue,',') WHERE item = 'Active') 
	SET @sql = @sql + ' AND (M.EffectiveDate IS NULL OR M.EffectiveDate > ''' + CONVERT(nvarchar(50),@now,101) + ''' OR ISNULL(M.ExpirationDate,''' + CONVERT(nvarchar(50),@now,101) + ''') < ''' + CONVERT(nvarchar(50),@now,101) + ''')' 

	SET @sql = @sql + '	AND M.IsActive=1'
	SET @sql = @sql + ' OPTION (RECOMPILE)'
		
	----DEBUG:   
	PRINT @Sql 
	
    INSERT INTO #FinalResultsFiltered 
	EXEC sp_executesql @sql, N'@memberNumber nvarchar(50), @ClientID INT, @ProgramID INT, @StateID INT, @CountryID INT, @Zip nvarchar(50), @City nvarchar(50), @LastName nvarchar(50), @FirstName nvarchar(50), @vinParam nvarchar(20), @PhoneNumber nvarchar(20)'
				, @memberNumber, @ClientID, @ProgramID, @StateID, @CountryID, @Zip, @City, @LastName, @FirstName, @vinParam, @PhoneNumber
	
	----DEBUG:   
    --Select * from #FinalResultsFiltered
    
	-- Do all computations  
	INSERT INTO #FinalResultsFormatted  
	SELECT   F.MemberID  
		, F.MembershipID  
		, F.MemberNumber     
		,REPLACE(RTRIM( 
			COALESCE(F.FirstName, '') + 
			COALESCE(' ' + left(F.MiddleName,1), '') + 
			COALESCE(' ' + F.LastName, '') +
			COALESCE(' ' + F.Suffix, '')
			), ' ', ' ') AS MemberName
		,(ISNULL(F.City,'') + ', ' + ISNULL(F.StateProvince,'') + ' ' + ISNULL(F.PostalCode,'') + ' ' + ISNULL(F.CountryCode,'')) AS [Address]     
		, COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber   
		, F.Program    
		,(SELECT COUNT(*) FROM [Case] WHERE MemberID = F.MemberID) AS POCount   
		-- Ignore time while comparing the dates here  
		--,CASE WHEN F.EffectiveDate <= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0) AND F.ExpirationDate >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)   
		--  THEN 'Active'   
		--  ELSE 'Inactive'   
		-- END 
		-- KB: Considering Effective and Expiration Dates to calculate member status
		,CASE WHEN ISNULL(F.EffectiveDate,@minDate) <= @now AND ISNULL(F.ExpirationDate,@minDate) >= @now
				THEN 'Active'
				ELSE 'Inactive'
		END AS MemberStatus
		, F.LastName  
		, F.FirstName  
		,CASE WHEN ISNULL(@vinParam,'') <> ''    
		THEN  F.VIN    
		ELSE  ''    
		END AS VIN     
		, F.StateProvinceID AS [State]  
		, F.PostalCode AS ZipCode  
	FROM #FinalResultsFiltered F  
	LEFT JOIN PhoneEntity PH WITH (NOLOCK) ON PH.EntityID = @memberEntityID AND PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND ( @phoneNumber IS NULL OR PH.PhoneNumber like CHAR(37) + @phoneNumber + CHAR(37))  
	LEFT JOIN PhoneEntity PW WITH (NOLOCK) ON PW.EntityID = @memberEntityID AND PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND ( @phoneNumber IS NULL OR PW.PhoneNumber like CHAR(37) + @phoneNumber + CHAR(37))  
	LEFT JOIN PhoneEntity PC WITH (NOLOCK) ON PC.EntityID = @memberEntityID AND PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND ( @phoneNumber IS NULL OR PC.PhoneNumber like CHAR(37) + @phoneNumber + CHAR(37)) 
	
	
	INSERT INTO #FinalResultsSorted  
	SELECT  F.MemberID,  
		F.MembershipID,    
		F.MemberNumber,     
		F.Name,    
		F.[Address],    
		F.PhoneNumber,
		F.Program,    
		F.POCount,    
		F.MemberStatus,    
		F.LastName,    
		F.FirstName ,    
		F.VIN ,    
		F.[State] ,    
		F.ZipCode   
	FROM  #FinalResultsFormatted F   
	---- Have to apply this filter here since it is derived in #FinalResultsFormatted query
	--WHERE ((@memberStatusValue IS NULL) OR ( F.MemberStatus IN (SELECT item FROM fnSplitString(@memberStatusValue,','))))

	ORDER BY     
	CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'    
	THEN F.MembershipID END ASC,     
	CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'    
	THEN F.MembershipID END DESC ,    

	CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'    
	THEN F.MemberNumber END ASC,     
	CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'    
	THEN F.MemberNumber END DESC ,    

	CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'    
	THEN F.Name END ASC,     
	CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'    
	THEN F.Name END DESC ,    

	CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'    
	THEN F.Address END ASC,     
	CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'    
	THEN F.Address END DESC ,    

	CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
	THEN F.PhoneNumber END ASC,     
	CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
	THEN F.PhoneNumber END DESC ,    

	CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
	THEN F.Program END ASC,     
	CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
	THEN F.Program END DESC ,    

	CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'    
	THEN F.POCount END ASC,     
	CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'    
	THEN F.POCount END DESC ,    

	CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'ASC'    
	THEN F.MemberStatus END ASC,     
	CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'DESC'    
	THEN F.MemberStatus END DESC    

	---- DEBUG:
	--SELECT * FROM #FinalResultsSorted

--	-- Let's delete duplicates from #FinalResultsSorted and then insert into Distinct.
	
--	;WITH wSorted 
--	AS
--	(
--		SELECT ROW_NUMBER() OVER (PARTITION BY 
--			F.MemberID,  
--			F.MembershipID,    
--			F.MemberNumber,     
--			F.Name,    
--			F.[Address],    
--			F.PhoneNumber,    
--			F.Program,    
--			F.POCount,    
--			F.MemberStatus,    
--			F.VIN ORDER BY F.RowNum) AS sRowNumber	
--		FROM #FinalResultsSorted F
--	)
	
--	DELETE FROM wSorted WHERE sRowNumber > 1
	
--	INSERT INTO #FinalResultsDistinct(
--			MemberID,  
--			MembershipID,    
--			MemberNumber,     
--			Name,    
--			[Address],    
--			PhoneNumber,    
--			Program,    
--			POCount,    
--			MemberStatus,    
--			VIN 
--	)   
--	SELECT	F.MemberID,  
--			F.MembershipID,    
--			F.MemberNumber,     
--			F.Name,    
--			F.[Address],    
--			F.PhoneNumber,    
--			F.Program,    
--			F.POCount,    
--			F.MemberStatus,    
--			F.VIN  	
--	FROM #FinalResultsSorted F
--	WHERE ((@memberStatusValue IS NULL) OR ( F.MemberStatus IN (SELECT item FROM fnSplitString(@memberStatusValue,','))))
--	ORDER BY 
--	CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
--		THEN F.PhoneNumber END ASC,     
--		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
--		THEN F.PhoneNumber END DESC,
--		F.RowNum  
		

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


	SELECT @count AS TotalRows, F.MemberID,  
		F.MembershipID,    
		F.MemberNumber,     
		F.Name,    
		F.[Address],    
		F.PhoneNumber,    
		F.Program,    
		F.POCount,    
		F.MemberStatus,    
		F.VIN    
	FROM #FinalResultsSorted F 
	WHERE RowNum BETWEEN @startInd AND @endInd    

	     
	DROP TABLE #FinalResultsFiltered  
	DROP TABLE #FinalResultsFormatted  
	DROP TABLE #FinalResultsSorted 
	--DROP TABLE #FinalResultsDistinct

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
 WHERE id = object_id(N'[dbo].[dms_MemberShip_Products_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_MemberShip_Products_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- [dms_MemberShip_Products_Get] @MembershipID = 868
 CREATE PROCEDURE [dbo].[dms_MemberShip_Products_Get]( 
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10    
 , @sortColumn nvarchar(100)  = ''   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @MembershipID INT = NULL  
 )   
 AS   
BEGIN   
    
  SET NOCOUNT ON  
  
DECLARE @idoc int  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter   
ProductOperator="-1"   
StartDateOperator="-1"   
EndDateOperator="-1"   
StatusOperator="-1"   
ProviderOperator="-1"   
 ></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
ProductOperator INT NOT NULL,  
ProductValue nvarchar(50) NULL,  
StartDateOperator INT NOT NULL,  
StartDateValue datetime NULL,  
EndDateOperator INT NOT NULL,  
EndDateValue datetime NULL,  
StatusOperator INT NOT NULL,  
StatusValue nvarchar(50) NULL,  
ProviderOperator INT NOT NULL,  
ProviderValue nvarchar(50) NULL,  
ContractNumberOperator INT NOT NULL,  
ContractNumberValue nvarchar(100) NULL,  
VINOperator INT NOT NULL,  
VINValue nvarchar(100) NULL  
  
)  
DECLARE @FinalResults TABLE (   
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 Product nvarchar(200)  NULL ,  
 StartDate datetime  NULL ,  
 EndDate datetime  NULL ,  
 Status nvarchar(100)  NULL ,  
 Provider nvarchar(100)  NULL ,  
 PhoneNumber nvarchar(100)  NULL,  
 ContractNumber nvarchar(100)  NULL,  
 VIN  nvarchar(100)  NULL  
)   
  
DECLARE @QueryResults TABLE (   
 Product nvarchar(200)  NULL ,  
 StartDate datetime  NULL ,  
 EndDate datetime  NULL ,  
 Status nvarchar(100)  NULL ,  
 Provider nvarchar(100)  NULL ,  
 PhoneNumber nvarchar(100)  NULL,  
 ContractNumber nvarchar(100)  NULL,  
 VIN  nvarchar(100)  NULL  
)   
  
INSERT INTO @tmpForWhereClause  
SELECT    
 ISNULL(ProductOperator,-1),  
 ProductValue ,  
 ISNULL(StartDateOperator,-1),  
 StartDateValue ,  
 ISNULL(EndDateOperator,-1),  
 EndDateValue ,  
 ISNULL(StatusOperator,-1),  
 StatusValue ,  
 ISNULL(ProviderOperator,-1),  
 ProviderValue,  
 ISNULL(ContractNumberOperator,-1),  
 ContractNumberValue ,  
 ISNULL(VINOperator,-1),  
 VINValue   
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
ProductOperator INT,  
ProductValue nvarchar(50)   
,StartDateOperator INT,  
StartDateValue datetime   
,EndDateOperator INT,  
EndDateValue datetime   
,StatusOperator INT,  
StatusValue nvarchar(50)   
,ProviderOperator INT,  
ProviderValue nvarchar(50),  
ContractNumberOperator INT,  
ContractNumberValue  nvarchar(100),  
VINOperator INT,  
VINValue nvarchar(100))   
  
--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
  
INSERT INTO @QueryResults  
SELECT   P.Description AS Product  
   , MP.StartDate AS StartDate  
   , MP.EndDate AS EndDate  
   , CASE WHEN MP.EndDate < GETDATE() THEN 'Inactive' ELSE 'Active' END AS Status  
   , PP.Description AS Provider  
   , PP.PhoneNumber AS PhoneNumber  
   , MP.ContractNumber  
   , MP.VIN  
 FROM  MemberProduct MP (NOLOCK)  
 JOIN  Membership MS (NOLOCK) ON MP.MembershipID = MS.ID   
 LEFT JOIN Product P (NOLOCK) ON P.ID = MP.ProductID  
 LEFT JOIN ProductProvider PP (NOLOCK) ON PP.ID = MP.ProductProviderID  
 WHERE  MP.MembershipID = @MembershipID  
 ORDER BY P.Description  
  
  
INSERT INTO @FinalResults  
SELECT   
 T.Product,  
 T.StartDate,  
 T.EndDate,  
 T.Status,  
 T.Provider,  
 T.PhoneNumber,  
 T.ContractNumber,  
 T.VIN  
FROM @QueryResults T,  
@tmpForWhereClause TMP   
WHERE (   
  
 (   
  ( TMP.ProductOperator = -1 )   
 OR   
  ( TMP.ProductOperator = 0 AND T.Product IS NULL )   
 OR   
  ( TMP.ProductOperator = 1 AND T.Product IS NOT NULL )   
 OR   
  ( TMP.ProductOperator = 2 AND T.Product = TMP.ProductValue )   
 OR   
  ( TMP.ProductOperator = 3 AND T.Product <> TMP.ProductValue )   
 OR   
  ( TMP.ProductOperator = 4 AND T.Product LIKE TMP.ProductValue + '%')   
 OR   
  ( TMP.ProductOperator = 5 AND T.Product LIKE '%' + TMP.ProductValue )   
 OR   
  ( TMP.ProductOperator = 6 AND T.Product LIKE '%' + TMP.ProductValue + '%' )   
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
  ( TMP.ProviderOperator = -1 )   
 OR   
  ( TMP.ProviderOperator = 0 AND T.Provider IS NULL )   
 OR   
  ( TMP.ProviderOperator = 1 AND T.Provider IS NOT NULL )   
 OR   
  ( TMP.ProviderOperator = 2 AND T.Provider = TMP.ProviderValue )   
 OR   
  ( TMP.ProviderOperator = 3 AND T.Provider <> TMP.ProviderValue )   
 OR   
  ( TMP.ProviderOperator = 4 AND T.Provider LIKE TMP.ProviderValue + '%')   
 OR   
  ( TMP.ProviderOperator = 5 AND T.Provider LIKE '%' + TMP.ProviderValue )   
 OR   
  ( TMP.ProviderOperator = 6 AND T.Provider LIKE '%' + TMP.ProviderValue + '%' )   
 )   
  AND   
  
 (   
  ( TMP.ContractNumberOperator = -1 )   
 OR   
  ( TMP.ContractNumberOperator = 0 AND T.ContractNumber IS NULL )   
 OR   
  ( TMP.ContractNumberOperator = 1 AND T.ContractNumber IS NOT NULL )   
 OR   
  ( TMP.ContractNumberOperator = 2 AND T.ContractNumber = TMP.ContractNumberValue )   
 OR   
  ( TMP.ContractNumberOperator = 3 AND T.ContractNumber <> TMP.ContractNumberValue )   
 OR   
  ( TMP.ContractNumberOperator = 4 AND T.ContractNumber LIKE TMP.ContractNumberValue + '%')   
 OR   
  ( TMP.ContractNumberOperator = 5 AND T.ContractNumber LIKE '%' + TMP.ContractNumberValue )   
 OR   
  ( TMP.ContractNumberOperator = 6 AND T.ContractNumber LIKE '%' + TMP.ContractNumberValue + '%' )   
 )   
 AND   
  
 (   
  ( TMP.VINOperator = -1 )   
 OR   
  ( TMP.VINOperator = 0 AND T.VIN IS NULL )   
 OR   
  ( TMP.VINOperator = 1 AND T.VIN IS NOT NULL )   
 OR   
  ( TMP.VINOperator = 2 AND T.VIN = TMP.VINValue )   
 OR   
  ( TMP.VINOperator = 3 AND T.VIN <> TMP.VINValue )   
 OR   
  ( TMP.VINOperator = 4 AND T.VIN LIKE TMP.VINValue + '%')   
 OR   
  ( TMP.VINOperator = 5 AND T.VIN LIKE '%' + TMP.VINValue )   
 OR   
  ( TMP.VINOperator = 6 AND T.VIN LIKE '%' + TMP.VINValue + '%' )   
 )   
  
 AND   
 1 = 1   
 )   
 ORDER BY   
  CASE WHEN @sortColumn = 'Product' AND @sortOrder = 'ASC'  
  THEN T.Product END ASC,   
  CASE WHEN @sortColumn = 'Product' AND @sortOrder = 'DESC'  
  THEN T.Product END DESC ,  
  
  CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'ASC'  
  THEN T.StartDate END ASC,   
  CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'DESC'  
  THEN T.StartDate END DESC ,  
  
  CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'ASC'  
  THEN T.EndDate END ASC,   
  CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'DESC'  
  THEN T.EndDate END DESC ,  
  
  CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'  
  THEN T.Status END ASC,   
  CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'  
  THEN T.Status END DESC ,  
  
  CASE WHEN @sortColumn = 'Provider' AND @sortOrder = 'ASC'  
  THEN T.Provider END ASC,   
  CASE WHEN @sortColumn = 'Provider' AND @sortOrder = 'DESC'  
  THEN T.Provider END DESC ,  
  
  CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'  
  THEN T.PhoneNumber END ASC,   
  CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'  
  THEN T.PhoneNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'ContractNumber' AND @sortOrder = 'ASC'  
  THEN T.ContractNumber END ASC,   
  CASE WHEN @sortColumn = 'ContractNumber' AND @sortOrder = 'DESC'  
  THEN T.ContractNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'VIN' AND @sortOrder = 'ASC'  
  THEN T.VIN END ASC,   
  CASE WHEN @sortColumn = 'VIN' AND @sortOrder = 'DESC'  
  THEN T.VIN END DESC   
  
  
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
/*
	NP 02/03: Whatever the changes made to this SP has to be made to dms_Merge_Members_Search also
*/

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Members_Search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Members_Search] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter FirstNameOperator="4" FirstNameValue="jeevan"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
--EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter PhoneNumberOperator="2" PhoneNumberValue="8173078882"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
--EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter MemberNumberOperator="2" MemberNumberValue="1F6ED09370"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
-- EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter VINOperator="4" VINValue="K1234422323N1233"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3

CREATE PROCEDURE [dbo].[dms_Members_Search](   
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10   
 , @sortColumn nvarchar(100)  = 'MemberNumber'   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @programID INT = NULL   
 )   
 AS   
 BEGIN   
    
	SET NOCOUNT ON    
	SET FMTONLY OFF;
	-- KB : Temporary resultsets. These resultsets are used to prepare mangeable resultsets.
	CREATE TABLE #FinalResultsFiltered(     

	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	Suffix nvarchar(50)  NULL ,    
	Prefix nvarchar(50)  NULL ,    
	City nvarchar(50)  NULL ,    
	StateProvince nvarchar(50)  NULL ,    
	PostalCode nvarchar(50)  NULL ,    
	HomePhoneNumber nvarchar(50)  NULL ,    
	WorkPhoneNumber nvarchar(50)  NULL ,    
	CellPhoneNumber nvarchar(50)  NULL ,  
	ProgramID INT NULL, -- KB: ADDED IDS  
	Program nvarchar(50)  NULL ,    
	POCount INT NULL,  
	ExpirationDate DATETIME NULL,   
	EffectiveDate DATETIME NULL,
	VIN nvarchar(50)  NULL ,    
	VehicleID INT NULL, -- KB: Added VehicleID
	[StateProvinceID] INT  NULL,
	MiddleName   nvarchar(50)  NULL , 
	ClientMemberType nvarchar(200)  NULL 
	)    

	CREATE TABLE #FinalResultsFormatted(      
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,  
	VehicleID INT NULL, -- KB: Added VehicleID  
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL,
	ClientMemberType nvarchar(200)  NULL
	)    

	CREATE TABLE #FinalResultsSorted(     
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL , 
	VehicleID INT NULL, -- KB: Added VehicleID   
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL,
	ClientMemberType nvarchar(200)  NULL 
	)  
	--CREATE TABLE #FinalResultsDistinct(     
	--[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	--MemberID int  NULL ,   
	--MembershipID INT NULL,   
	--MemberNumber nvarchar(50)  NULL ,    
	--Name nvarchar(200)  NULL ,    
	--[Address] nvarchar(max)  NULL ,    
	--PhoneNumber nvarchar(50)  NULL , 
	--ProgramID INT NULL, -- KB: ADDED IDS   
	--Program nvarchar(50)  NULL ,    
	--POCount int  NULL ,    
	--MemberStatus nvarchar(50)  NULL ,    
	--LastName nvarchar(50)  NULL ,    
	--FirstName nvarchar(50)  NULL ,    
	--VIN nvarchar(50)  NULL ,  
	--VehicleID INT NULL, -- KB: Added VehicleID  
	--State nvarchar(50)  NULL ,    
	--ZipCode nvarchar(50)  NULL,
	--ClientMemberType nvarchar(200)  NULL
	--)  

	CREATE TABLE #SearchPrograms (
	ProgramID int, 
	ProgramName nvarchar(200),
	ClientID int
	)
	
	INSERT INTO #SearchPrograms (ProgramID, ProgramName, ClientID)
	SELECT ProgramID, ProgramName, ClientID
	--FROM [dbo].[fnc_GetMemberSearchPrograms](9) --@programID)
	FROM [dbo].[fnc_GetMemberSearchPrograms] (@programID)
	
	CREATE CLUSTERED INDEX IDX_SearchPrograms ON #SearchPrograms(ProgramID)
	--Select * From #SearchPrograms
	--Drop table #SearchPrograms
	
	DECLARE @idoc int    
	IF @whereClauseXML IS NULL     
	BEGIN    
	SET @whereClauseXML = '<ROW><Filter     
	MemberIDOperator="-1"     
	MemberNumberOperator="-1"     
	PhoneNumberOperator="-1"     
	ProgramOperator="-1"     
	LastNameOperator="-1"     
	FirstNameOperator="-1"     
	VINOperator="-1"     
	StateOperator="-1"    
	ZipCodeOperator = "-1"   
	></Filter></ROW>'    
	END    
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML    

	DECLARE @tmpForWhereClause TABLE    
	(    
	MemberIDOperator INT NOT NULL,    
	MemberIDValue int NULL,    
	MemberNumberOperator INT NOT NULL,    
	MemberNumberValue nvarchar(50) NULL,    
	PhoneNumberOperator INT NOT NULL,    
	PhoneNumberValue nvarchar(50) NULL,    
	ProgramOperator INT NOT NULL,    
	ProgramValue nvarchar(50) NULL,    
	LastNameOperator INT NOT NULL,    
	LastNameValue nvarchar(50) NULL,    
	FirstNameOperator INT NOT NULL,    
	FirstNameValue nvarchar(50) NULL,    
	VINOperator INT NOT NULL,    
	VINValue nvarchar(50) NULL,    
	StateOperator INT NOT NULL,    
	StateValue nvarchar(50) NULL,  
	ZipCodeOperator INT NOT NULL,    
	ZipCodeValue   nvarchar(50) NULL  
	)    

	-- Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'     

	INSERT INTO @tmpForWhereClause    
	SELECT      
			ISNULL(MemberIDOperator,-1),    
			MemberIDValue ,    
			ISNULL(MemberNumberOperator,-1),    
			MemberNumberValue ,    
			ISNULL(PhoneNumberOperator,-1),    
			PhoneNumberValue ,    
			ISNULL(ProgramOperator,-1),    
			ProgramValue ,    
			ISNULL(LastNameOperator,-1),    
			LastNameValue ,    
			ISNULL(FirstNameOperator,-1),    
			FirstNameValue ,    
			ISNULL(VINOperator,-1),    
			VINValue ,    
			ISNULL(StateOperator,-1),    
			StateValue,    
			ISNULL(ZipCodeOperator,-1),    
			ZipCodeValue    
	FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (    
			MemberIDOperator INT,    
			MemberIDValue int     
			,MemberNumberOperator INT,    
			MemberNumberValue nvarchar(50)     
			,PhoneNumberOperator INT,    
			PhoneNumberValue nvarchar(50)     
			,ProgramOperator INT,    
			ProgramValue nvarchar(50)     
			,LastNameOperator INT,    
			LastNameValue nvarchar(50)     
			,FirstNameOperator INT,    
			FirstNameValue nvarchar(50)     
			,VINOperator INT,    
			VINValue nvarchar(50)     
			,StateOperator INT,    
			StateValue nvarchar(50)     
			,ZipCodeOperator INT,    
			ZipCodeValue nvarchar(50)   
	)     
	
	
	--DECLARE @vinParam nvarchar(50)    
	--SELECT @vinParam = VINValue FROM @tmpForWhereClause    

	DECLARE @memberEntityID INT  
	SELECT @memberEntityID = ID FROM Entity WHERE Name = 'Member'  
	--------------------- BEGIN -----------------------------    
	----   Create a temp variable or a CTE with the actual SQL search query ----------    
	----   and use that CTE in the place of <table> in the following SQL statements ---    
	--------------------- END -----------------------------    
	DECLARE @phoneNumber NVARCHAR(100)  
	SET @phoneNumber = (SELECT PhoneNumberValue FROM @tmpForWhereClause)  

	DECLARE @memberID INT
	DECLARE @memberNumber NVARCHAR(50)
	DECLARE @programCode NVARCHAR(50)
	DECLARE @firstName NVARCHAR(50)
	DECLARE @lastName NVARCHAR(50)
	DECLARE @state NVARCHAR(50)
	DECLARE @zip NVARCHAR(50)
	DECLARE @vinParam nvarchar(50) = NULL
	--DECLARE @phoneNumber NVARCHAR(100) = NULL

	SELECT	@memberID = MemberIDValue,
			@memberNumber = MemberNumberValue,
			@programCode = ProgramValue,
			@firstName = FirstNameValue,
			@lastName = LastNameValue,
			@state = StateValue,
			@zip = ZipCodeValue,
			--@PhoneNumber = REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumberValue,'(',''),' ',''),'-',''),')',''),  --Remove formatting
			@VinParam = VinValue		
	FROM	@tmpForWhereClause

	
	SET FMTONLY OFF;  
	  
	Declare @sql nvarchar(max) = ''
			
			SET @sql =        'SELECT DISTINCT TOP 1000'
			SET @sql = @sql + '  M.id AS MemberID'  
			SET @sql = @sql + ' ,M.MembershipID' 
			SET @sql = @sql + ' ,CASE WHEN MS.MembershipNumber IS NULL THEN ''Ref#: '' + MS.ClientReferenceNUmber ELSE MS.MembershipNumber END AS MemberNumber'
			SET @sql = @sql + ' ,M.FirstName'
			SET @sql = @sql + ' ,M.LastName'
			SET @sql = @sql + ' ,M.Suffix'
			SET @sql = @sql + ' ,M.Prefix'     
			SET @sql = @sql + ' ,A.City' 
			SET @sql = @sql + ' ,A.StateProvince' 
			SET @sql = @sql + ' ,A.PostalCode' 
			SET @sql = @sql + ' ,NULL AS HomePhoneNumber'-- PH.PhoneNumber AS HomePhoneNumber 
			SET @sql = @sql + ' ,NULL AS WorkPhoneNumber' -- PW.PhoneNumber AS WorkPhoneNumber
			SET @sql = @sql + ' ,NULL AS CellPhoneNumber' -- PC.PhoneNumber AS CellPhoneNumber
			SET @sql = @sql + ' ,P.ID As ProgramID' -- KB: ADDED IDS
			SET @sql = @sql + ' ,P.[Description] AS Program'
			SET @sql = @sql + ' ,0 AS POCount' -- Computed later  
			SET @sql = @sql + ' ,m.ExpirationDate'  
			SET @sql = @sql + ' ,m.EffectiveDate'			
			SET @sql = @sql + ' ,(SELECT TOP 1 V.VIN FROM Vehicle V WHERE V.MembershipID = MS.ID'
					+ CASE WHEN @vinParam IS NOT NULL THEN ' AND V.VIN = @vinParam)' ELSE ')' END	
			SET @sql = @sql + ' ,(SELECT TOP 1 V.ID FROM Vehicle V WHERE V.MembershipID = MS.ID'
					+ CASE WHEN @vinParam IS NOT NULL THEN ' AND V.VIN = @vinParam)' ELSE ')' END	
			SET @sql = @sql + ' ,A.[StateProvinceID]'
			SET @sql = @sql + ' ,M.MiddleName'
			SET @sql = @sql + ' ,M.ClientMemberType'
			SET @sql = @sql + ' FROM Member M WITH (NOLOCK)'
			SET @sql = @sql + ' JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID'
			SET @sql = @sql + ' LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID =  '+ CONVERT(nvarchar(50), @memberEntityID) 
			SET @sql = @sql + ' JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID '   
			SET @sql = @sql + ' JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID'
			SET @sql = @sql + ' WHERE  ( @memberID IS NULL  OR @memberID = M.ID )'	
			
			
			IF @memberNumber IS NOT NULL
			SET @sql = @sql + ' AND (MS.MembershipNumber LIKE @memberNumber + char(37) OR MS.AltMembershipNumber LIKE  @memberNumber + char(37))'			
			
					
			IF @vinParam IS NOT NULL 
			SET @sql = @sql + ' AND MS.ID IN (SELECT v1.MembershipID FROM Vehicle v1 WHERE v1.VIN = @vinParam)'
	
			IF @phoneNumber IS NOT NULL
			SET @sql = @sql + ' AND M.ID IN (SELECT PH.RecordID FROM PhoneEntity PH WITH (NOLOCK) WHERE PH.EntityID = ' +				CONVERT(nvarchar(50), @memberEntityID) + ' AND PH.PhoneNumber = @phoneNumber)'	
			 
			IF @Zip IS NOT NULL
			SET @sql = @sql + ' AND A.PostalCode LIKE char(37) + @Zip + char(37)' 
			
			IF @programCode IS NOT NULL
			SET @sql = @sql + ' AND P.Code = @ProgramCode'
			
			IF @lastName IS NOT NULL
			SET @sql = @sql + ' AND M.LastName LIKE @lastName + char(37)'	
			
			IF @firstName IS NOT NULL
			SET @sql = @sql + ' AND M.FirstName LIKE @firstName + char(37)'
			
			IF @state IS NOT NULL
			SET @sql = @sql + ' AND A.StateProvinceID = @state'			
			
			
			SET @sql = @sql + '	AND M.IsActive=1'
			SET @sql = @sql + ' OPTION (RECOMPILE)'
			
			INSERT INTO #FinalResultsFiltered
			EXEC sp_executesql @sql, N'@memberID INT,@memberNumber nvarchar(50), @vinParam nvarchar(50),@phoneNumber nvarchar(20), @Zip nvarchar(50), @ProgramCode INT,   @lastName nvarchar(50), @firstName nvarchar(50), @state INT'
				, @memberID, @memberNumber, @vinParam, @PhoneNumber, @Zip, @programCode, @lastName, @firstName, @state		
			  
	
		
	-- Do all computations  
	INSERT INTO #FinalResultsFormatted  
	SELECT   F.MemberID  
	, F.MembershipID  
	, F.MemberNumber     
	--, REPLACE(RTRIM(COALESCE(F.LastName, '')   
	-- + COALESCE(' ' + F.Suffix, '')   
	-- + COALESCE(', ' + F.FirstName, '')), ' ', ' ')   
	-- + COALESCE(' ' + F.Prefix, '') AS Name  
	,REPLACE(RTRIM( 
	COALESCE(F.FirstName, '') + 
	COALESCE(' ' + left(F.MiddleName,1), '') + 
	COALESCE(' ' + F.LastName, '') +
	COALESCE(' ' + F.Suffix, '')
	), ' ', ' ') AS MemberName
	,(ISNULL(F.City,'') + ',' + ISNULL(F.StateProvince,'') + ' ' + ISNULL(F.PostalCode,'')) AS [Address]     
	, COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber 
	, F.ProgramID -- KB: ADDED IDS    
	, F.Program    
	,(SELECT COUNT(*) FROM [Case] WHERE MemberID = F.MemberID) AS POCount   
	-- Ignore time while comparing the dates here  
	--,CASE WHEN F.EffectiveDate <= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0) AND F.ExpirationDate >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)   
	--  THEN 'Active'   
	--  ELSE 'Inactive'   
	-- END 
	-- KB: Considering Effective and Expiration Dates to calculate member status
	,CASE WHEN ISNULL(F.EffectiveDate,@minDate) <= @now AND ISNULL(F.ExpirationDate,@minDate) >= @now
			THEN 'Active'
			ELSE 'Inactive'
	END AS MemberStatus
	, F.LastName  
	, F.FirstName  
	, F.VIN 
	, F.VehicleID  
	, F.StateProvinceID AS [State]  
	, F.PostalCode AS ZipCode  
	, F.ClientMemberType
	FROM #FinalResultsFiltered F  
	LEFT JOIN PhoneEntity PH WITH (NOLOCK) ON PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR PH.PhoneNumber like CHAR(37) + @phoneNumber + CHAR(37))  
		LEFT JOIN PhoneEntity PW WITH (NOLOCK) ON PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR PW.PhoneNumber like CHAR(37) + @phoneNumber + CHAR(37))   
		LEFT JOIN PhoneEntity PC WITH (NOLOCK) ON PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR PC.PhoneNumber like CHAR(37) + @phoneNumber + CHAR(37))

	
		INSERT INTO #FinalResultsSorted  
		SELECT  F.MemberID,  
		F.MembershipID,    
		F.MemberNumber,     
		F.Name,    
		F.[Address],    
		F.PhoneNumber, 
		F.ProgramID, -- KB: ADDED IDS     
		F.Program,    
		F.POCount,    
		F.MemberStatus,    
		F.LastName,    
		F.FirstName ,    
		F.VIN ,
		F.VehicleID,    
		F.[State] ,    
		F.ZipCode ,
		F.ClientMemberType
		FROM  #FinalResultsFormatted F   
		
		ORDER BY     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'    
		THEN F.MembershipID END ASC,     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'    
		THEN F.MembershipID END DESC ,    

		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'    
		THEN F.MemberNumber END ASC,     
		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'    
		THEN F.MemberNumber END DESC ,    

		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'    
		THEN F.Name END ASC,     
		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'    
		THEN F.Name END DESC ,    

		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'    
		THEN F.Address END ASC,     
		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'    
		THEN F.Address END DESC ,    

		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC ,    

		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,    

		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'    
		THEN F.POCount END ASC,     
		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'    
		THEN F.POCount END DESC ,    

		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'ASC'    
		THEN F.MemberStatus END ASC,     
		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'DESC'    
		THEN F.MemberStatus END DESC    

		

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



	SELECT @count AS TotalRows, F.MemberID,  
		F.MembershipID,    
	   F.MemberNumber,     
	   F.Name,    
	   F.[Address],    
	   F.PhoneNumber,  
	   F.ProgramID, -- KB: ADDED IDS      
	   F.Program,    
	   F.POCount,    
	   F.MemberStatus,    
	   F.VIN,
	   F.VehicleID ,
	   F.ClientMemberType
	   FROM    
	   #FinalResultsSorted F WHERE RowNum BETWEEN @startInd AND @endInd    
	     
	DROP TABLE #FinalResultsFiltered  
	DROP TABLE #FinalResultsFormatted  
	DROP TABLE #FinalResultsSorted 
	--DROP TABLE #FinalResultsDistinct


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
 WHERE id = object_id(N'[dbo].[dms_Member_AssociateList]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_AssociateList] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Member_AssociateList] @whereClauseXML ='<ROW><Filter MembershipIDOperator="2" MembershipIDValue="1"></Filter></ROW>', @sortColumn = 'EffectiveData', @sortOrder = 'ASC'  
CREATE PROCEDURE [dbo].[dms_Member_AssociateList]( 
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

	CREATE TABLE #FinalResultsFiltered ( 	
		MembershipID int  NULL ,
		MembershipNumber nvarchar(50)  NULL ,
		MemberID nvarchar(50)  NULL ,
		IsPrimary INT  NULL ,
		FirstName nvarchar(50)  NULL ,
		MiddleName nvarchar(50)  NULL ,
		LastName nvarchar(50)  NULL ,
		Suffix nvarchar(50)  NULL ,
		EffectiveDate datetime  NULL ,
		ExpirationDate datetime  NULL	 
	) 

	CREATE TABLE #FinalResultsFormatted ( 	
		MembershipID int  NULL ,
		MembershipNumber nvarchar(50)  NULL ,
		MemberID nvarchar(50)  NULL ,
		PrimaryMember nvarchar(50)  NULL ,
		MemberName nvarchar(200)  NULL ,
		EffectiveDate datetime  NULL ,
		ExpirationDate datetime  NULL ,
		IsPrimary int  NULL ,
		LastName nvarchar(50)  NULL ,
		FirstName nvarchar(50)  NULL ,
		MemberStatus nvarchar(50)  NULL 
	) 

	CREATE TABLE #FinalResultsSorted( 	
		[RowNum] [bigint] NOT NULL IDENTITY(1,1),  
		MembershipID int  NULL ,
		MembershipNumber nvarchar(50)  NULL ,
		MemberID nvarchar(50)  NULL ,
		PrimaryMember nvarchar(50)  NULL ,
		MemberName nvarchar(200)  NULL ,
		EffectiveDate datetime  NULL ,
		ExpirationDate datetime  NULL ,
		IsPrimary int  NULL ,
		LastName nvarchar(50)  NULL ,
		FirstName nvarchar(50)  NULL ,
		MemberStatus nvarchar(50)  NULL 
	) 

	DECLARE @idoc int
	IF @whereClauseXML IS NULL 
	BEGIN
	SET @whereClauseXML = '<ROW><Filter 
		MembershipIDOperator="-1" 
		MembershipNumberOperator="-1" 
		MemberIDOperator="-1" 
		 ></Filter></ROW>'
	END
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

	DECLARE @tmpForWhereClause TABLE
	(
	MembershipIDOperator INT NOT NULL,
	MembershipIDValue int NULL,
	MembershipNumberOperator INT NOT NULL,
	MembershipNumberValue nvarchar(50) NULL,
	MemberIDOperator INT NOT NULL,
	MemberIDValue nvarchar(50) NULL
	)

	-- Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'

	INSERT INTO @tmpForWhereClause
	SELECT  
		ISNULL(MembershipIDOperator,-1),
		MembershipIDValue ,
		ISNULL(MembershipNumberOperator,-1),
		MembershipNumberValue ,
		ISNULL(MemberIDOperator,-1),
		MemberIDValue 
	FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
	MembershipIDOperator INT,
	MembershipIDValue int 
	,MembershipNumberOperator INT,
	MembershipNumberValue nvarchar(50) 
	,MemberIDOperator INT,
	MemberIDValue nvarchar(50) 
	 ) 

	DECLARE @MembershipID int,
		@MembershipNumber nvarchar(50),
		@MemberID int

	SELECT	@MembershipID = MembershipIDValue,
			@MembershipNumber = MembershipNumberValue,
			@MemberID = MemberIDValue
	FROM	@tmpForWhereClause


	INSERT INTO #FinalResultsFiltered
	SELECT	ms.ID AS MembershipID, 
			ms.MembershipNumber AS MembershipNumber, 
			m.ID as MemberID,
			m.IsPrimary,
			m.FirstName,
			m.MiddleName,
			m.LastName,
			m.Suffix,
			m.EffectiveDate,
			m.ExpirationDate
	FROM Membership ms
	JOIN Member m ON m.MembershipID = ms.ID
	JOIN Program p ON p.id = m.ProgramID
	WHERE
		( @MembershipID IS NOT NULL OR @MemberID IS NOT NULL OR @MembershipNumber IS NOT NULL)
		AND
		( @MembershipID IS NULL  OR @MembershipID = MS.ID )
		 AND
		( @MemberID IS NULL  OR @MemberID = M.ID )
		 AND
		( @MembershipNumber IS NULL  OR @MembershipNumber = MS.MembershipNumber )


	 INSERT INTO #FinalResultsFormatted
	 SELECT	 DISTINCT 
			F.MembershipID, 
			F.MembershipNumber, 
			F.MemberID,
		   CASE WHEN F.IsPrimary = 1 THEN '*' ELSE ''END AS PrimaryMember,
		   CASE WHEN F.IsPrimary = 1 THEN '*' ELSE '' END + 
				REPLACE(RTRIM(COALESCE(F.FirstName,'')+ 
				COALESCE(' '+left(F.MiddleName,1),'')+
				COALESCE(' '+ F.LastName,'')+
				COALESCE(' '+ F.Suffix,'')),'  ',' ')
			AS MemberName,
			F.EffectiveDate,
			F.ExpirationDate,
			F.IsPrimary,
			F.LastName,
			F.FirstName,
			-- KB: Considering Effective and Expiration Dates to calculate member status
			CASE WHEN ISNULL(F.EffectiveDate,@minDate) <= @now AND ISNULL(F.ExpirationDate,@minDate) >= @now
							THEN 'Active'
							ELSE 'Inactive'
			END AS MemberStatus
	FROM	#FinalResultsFiltered F


	INSERT INTO #FinalResultsSorted
	SELECT F.*
	FROM	#FinalResultsFormatted  F
	ORDER BY 
		 CASE WHEN @sortColumn = 'MembershipID' AND @sortOrder = 'ASC'
		 THEN F.MembershipID END ASC, 
		 CASE WHEN @sortColumn = 'MembershipID' AND @sortOrder = 'DESC'
		 THEN F.MembershipID END DESC ,

		 CASE WHEN @sortColumn = 'MembershipNumber' AND @sortOrder = 'ASC'
		 THEN F.MembershipNumber END ASC, 
		 CASE WHEN @sortColumn = 'MembershipNumber' AND @sortOrder = 'DESC'
		 THEN F.MembershipNumber END DESC ,

		 CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'
		 THEN F.MemberID END ASC, 
		 CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'
		 THEN F.MemberID END DESC ,

		 CASE WHEN @sortColumn = 'PrimaryMember' AND @sortOrder = 'ASC'
		 THEN F.PrimaryMember END ASC, 
		 CASE WHEN @sortColumn = 'PrimaryMember' AND @sortOrder = 'DESC'
		 THEN F.PrimaryMember END DESC ,

		 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'
		 THEN F.MemberName END ASC, 
		 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'
		 THEN F.MemberName END DESC ,

		 CASE WHEN @sortColumn = 'EffectiveDate' AND @sortOrder = 'ASC'
		 THEN F.EffectiveDate END ASC, 
		 CASE WHEN @sortColumn = 'EffectiveDate' AND @sortOrder = 'DESC'
		 THEN F.EffectiveDate END DESC ,

		 CASE WHEN @sortColumn = 'ExpirationDate' AND @sortOrder = 'ASC'
		 THEN F.ExpirationDate END ASC, 
		 CASE WHEN @sortColumn = 'ExpirationDate' AND @sortOrder = 'DESC'
		 THEN F.ExpirationDate END DESC ,

		 CASE WHEN @sortColumn = 'IsPrimary' AND @sortOrder = 'ASC'
		 THEN F.IsPrimary END ASC, 
		 CASE WHEN @sortColumn = 'IsPrimary' AND @sortOrder = 'DESC'
		 THEN F.IsPrimary END DESC ,

		 CASE WHEN @sortColumn = 'LastName' AND @sortOrder = 'ASC'
		 THEN F.LastName END ASC, 
		 CASE WHEN @sortColumn = 'LastName' AND @sortOrder = 'DESC'
		 THEN F.LastName END DESC ,

		 CASE WHEN @sortColumn = 'FirstName' AND @sortOrder = 'ASC'
		 THEN F.FirstName END ASC, 
		 CASE WHEN @sortColumn = 'FirstName' AND @sortOrder = 'DESC'
		 THEN F.FirstName END DESC 


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

	SELECT @count AS TotalRows, 
		  F.RowNum,
		  F.MembershipID,
		  F.MemberID,
		  F.PrimaryMember,
		  F.MemberName,
		  CONVERT(NVARCHAR(10), F.EffectiveDate,101)AS EffectiveDate,
		  CONVERT(NVARCHAR(10), F.ExpirationDate,101)AS ExpirationDate,
		  F.MemberStatus 
		  FROM #FinalResultsSorted F 
		  
	DROP TABLE #FinalResultsFiltered
	DROP TABLE #FinalResultsFormatted
	DROP TABLE #FinalResultsSorted

END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Member_Products_Using_Category]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_Products_Using_Category] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- dms_Member_Products_Using_Category 897, 3
CREATE PROC [dbo].[dms_Member_Products_Using_Category](
	@memberID INT = NULL,
	@productCategoryID INT = NULL,
	@VIN nvarchar(50) = NULL
)
AS
BEGIN
IF (@productCategoryID IS NULL AND @VIN IS NULL)
BEGIN
	SELECT DISTINCT	ISNULL(REPLACE(RTRIM(
		COALESCE(p.Description, '') +
		COALESCE(', ' + pp.Description, '') +  
		COALESCE(', ' + pp.PhoneNumber, '') 
		), '  ', ' ')
		,'') AS [AdditionalProduct]
	, pp.Script AS [HelpText]
	
	FROM	MemberProduct mp (NOLOCK)
	JOIN	Membership ms (NOLOCK) ON mp.MembershipID = ms.ID
	JOIN	Product p (NOLOCK) ON p.ID = mp.ProductID
	JOIN	ProductProvider pp (NOLOCK) ON pp.ID = mp.ProductProviderID
	WHERE	(mp.MemberID = @memberID)
	
	UNION ALL
	SELECT DISTINCT	ISNULL(REPLACE(RTRIM(
		COALESCE(p.Description, '') +
		COALESCE(', ' + pp.Description, '') +  
		COALESCE(', ' + pp.PhoneNumber, '') 
		), '  ', ' ')
		,'') AS [AdditionalProduct]
	, pp.Script AS [HelpText]
	
	FROM	MemberProduct mp (NOLOCK)
	JOIN	Membership ms (NOLOCK) ON mp.MembershipID = ms.ID
	JOIN	Product p (NOLOCK) ON p.ID = mp.ProductID
	JOIN	ProductProvider pp (NOLOCK) ON pp.ID = mp.ProductProviderID
	WHERE	(mp.MemberID IS NULL AND ms.ID = (SELECT MembershipID FROM Member WHERE ID = @MemberID))				
			
	ORDER BY [AdditionalProduct]
END
ELSE
BEGIN
	SELECT	DISTINCT ISNULL(REPLACE(RTRIM(
			COALESCE(p.Description, '') +
			--COALESCE(', ' + CONVERT(VARCHAR(10),mp.StartDate,101),'') + 
			--COALESCE(' - ' + CONVERT(VARCHAR(10),mp.EndDate,101), '') +
			COALESCE(', ' + pp.Description, '') +  
			COALESCE(', ' + pp.PhoneNumber, '') 
			), '  ', ' ')
			,'') AS [AdditionalProduct]
		, pp.Script AS [HelpText]
		
	FROM	MemberProduct mp (NOLOCK)
	JOIN	Membership ms (NOLOCK) ON mp.MembershipID = ms.ID
	JOIN	Product p (NOLOCK) ON p.ID = mp.ProductID
	JOIN	ProductProvider pp (NOLOCK) ON pp.ID = mp.ProductProviderID
	JOIN	MemberProductProductCategory mppc (NOLOCK) ON mppc.ProductID = p.ID AND mppc.ProductCategoryID = @productCategoryID 
	WHERE	(mp.MemberID = @memberID) AND (mp.VIN IS NULL OR mp.VIN = @VIN)
	
	UNION ALL
	SELECT	DISTINCT ISNULL(REPLACE(RTRIM(
			COALESCE(p.Description, '') +
			--COALESCE(', ' + CONVERT(VARCHAR(10),mp.StartDate,101),'') + 
			--COALESCE(' - ' + CONVERT(VARCHAR(10),mp.EndDate,101), '') +
			COALESCE(', ' + pp.Description, '') +  
			COALESCE(', ' + pp.PhoneNumber, '') 
			), '  ', ' ')
			,'') AS [AdditionalProduct]
		, pp.Script AS [HelpText]
		
	FROM	MemberProduct mp (NOLOCK)
	JOIN	Membership ms (NOLOCK) ON mp.MembershipID = ms.ID
	JOIN	Product p (NOLOCK) ON p.ID = mp.ProductID
	JOIN	ProductProvider pp (NOLOCK) ON pp.ID = mp.ProductProviderID
	JOIN	MemberProductProductCategory mppc (NOLOCK) ON mppc.ProductID = p.ID AND mppc.ProductCategoryID = @productCategoryID 
	WHERE	(mp.MemberID IS NULL AND ms.ID = (SELECT MembershipID FROM Member WHERE ID = @MemberID))
							AND (mp.VIN IS NULL OR mp.VIN = @VIN) 
	ORDER BY [AdditionalProduct]
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
 WHERE id = object_id(N'[dbo].[dms_Member_ServiceRequestHistory]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_ServiceRequestHistory] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
-- EXEC  [dbo].[dms_Member_ServiceRequestHistory] @whereClauseXML ='<ROW><Filter MembershipIDOperator="2" MembershipIDValue="1"></Filter></ROW>', @sortColumn = 'CreateDate', @sortOrder = 'ASC'
CREATE PROCEDURE [dbo].[dms_Member_ServiceRequestHistory]( 
	@whereClauseXML NVARCHAR(4000) = NULL
	, @startInd Int = 1 
	, @endInd BIGINT = 10 
	, @pageSize int = 10  
	, @sortColumn nvarchar(100)  = '' 
	, @sortOrder nvarchar(100) = 'ASC' 
	) 
 AS 
 BEGIN 
  
    SET FMTONLY OFF
 	SET NOCOUNT ON  
 	
	CREATE TABLE #FinalResultsFiltered (    
		 CaseNumber int  NULL ,  
		 ServiceRequestNumber int  NULL ,  
		 CreateDate datetime  NULL ,  
		 ServiceType nvarchar(50)  NULL ,  
		 [Status] nvarchar(50)  NULL ,  
		 FirstName nvarchar(50)  NULL ,  
		 MiddleName nvarchar(50)  NULL ,  
		 LastName nvarchar(50)  NULL ,  
		 Suffix nvarchar(50)  NULL ,  
		 VehicleYear nvarchar(4)  NULL ,  
		 VehicleMake nvarchar(50)  NULL ,  
		 VehicleMakeOther nvarchar(50)  NULL ,  
		 VehicleModel nvarchar(50)  NULL ,  
		 VehicleModelOther nvarchar(50)  NULL ,  
		 Vendor nvarchar(255)  NULL , 
		 MembershipID int  NULL , 
		 POCount int  NULL  ,
		 ContactPhoneNumber nvarchar(100) NULL 
		)

	CREATE TABLE #FinalResultsFormatted (   
		 CaseNumber int  NULL ,  
		 ServiceRequestNumber int  NULL ,  
		 CreateDate datetime  NULL ,  
		 ServiceType nvarchar(50)  NULL ,  
		 Status nvarchar(50)  NULL ,  
		 MemberName nvarchar(200)  NULL ,  
		 Vehicle nvarchar(200)  NULL ,  
		 Vendor nvarchar(255)  NULL ,  
		 POCount int  NULL ,  
		 MembershipID int  NULL   ,
		 ContactPhoneNumber nvarchar(100) NULL 
		)
	  
	CREATE TABLE #FinalResultsSorted (   
		 [RowNum] [bigint] NOT NULL IDENTITY(1,1),  
		 CaseNumber int  NULL ,  
		 ServiceRequestNumber int  NULL ,  
		 CreateDate datetime  NULL ,  
		 ServiceType nvarchar(50)  NULL ,  
		 Status nvarchar(50)  NULL ,  
		 MemberName nvarchar(200)  NULL ,  
		 Vehicle nvarchar(200)  NULL ,  
		 Vendor nvarchar(255)  NULL ,  
		 POCount int  NULL ,  
		 MembershipID int  NULL   ,
		 ContactPhoneNumber nvarchar(100) NULL 
		)

	DECLARE @idoc int  
	IF @whereClauseXML IS NULL   
	BEGIN  
	SET @whereClauseXML = '<ROW><Filter   
		CaseNumberOperator="-1"   
		ServiceRequestNumberOperator="-1"   
		CreateDateOperator="-1"   
		ServiceTypeOperator="-1"   
		StatusOperator="-1"   
		MemberNameOperator="-1"   
		VehicleOperator="-1"   
		VendorOperator="-1"   
		POCountOperator="-1"   
		MembershipIDOperator="-1"   
		ContactPhoneNumberOperator="-1"
		 ></Filter></ROW>' 
	END  
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
	  
	DECLARE @tmpForWhereClause TABLE  
		(  
		CaseNumberOperator INT NOT NULL,  
		CaseNumberValue int NULL,  
		ServiceRequestNumberOperator INT NOT NULL,  
		ServiceRequestNumberValue int NULL,  
		CreateDateOperator INT NOT NULL,  
		CreateDateValue datetime NULL,  
		ServiceTypeOperator INT NOT NULL,  
		ServiceTypeValue nvarchar(50) NULL,  
		StatusOperator INT NOT NULL,  
		StatusValue nvarchar(50) NULL,  
		MemberNameOperator INT NOT NULL,  
		MemberNameValue nvarchar(200) NULL,  
		VehicleOperator INT NOT NULL,  
		VehicleValue nvarchar(50) NULL,  
		VendorOperator INT NOT NULL,  
		VendorValue nvarchar(50) NULL,  
		POCountOperator INT NOT NULL,  
		POCountValue int NULL,  
		MembershipIDOperator INT NOT NULL,  
		MembershipIDValue int NULL ,
		ContactPhoneNumberOperator INT NOT NULL ,
		ContactPhoneNumberValue nvarchar(50) NULL 
		)  
  
	INSERT INTO @tmpForWhereClause  
	SELECT    
	 ISNULL(CaseNumberOperator,-1),  
	 CaseNumberValue ,  
	 ISNULL(ServiceRequestNumberOperator,-1),  
	 ServiceRequestNumberValue ,  
	 ISNULL(CreateDateOperator,-1),  
	 CreateDateValue ,  
	 ISNULL(ServiceTypeOperator,-1),  
	 ServiceTypeValue ,  
	 ISNULL(StatusOperator,-1),  
	 StatusValue ,  
	 ISNULL(MemberNameOperator,-1),  
	 MemberNameValue ,  
	 ISNULL(VehicleOperator,-1),  
	 VehicleValue ,  
	 ISNULL(VendorOperator,-1),  
	 VendorValue ,  
	 ISNULL(POCountOperator,-1),  
	 POCountValue ,  
	 ISNULL(MembershipIDOperator,-1),  
	 MembershipIDValue  , 
	 ISNULL(ContactPhoneNumberOperator,-1),  
	 ContactPhoneNumberValue   
	FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
	CaseNumberOperator INT,  
	CaseNumberValue int   
	,ServiceRequestNumberOperator INT,  
	ServiceRequestNumberValue int   
	,CreateDateOperator INT,  
	CreateDateValue datetime   
	,ServiceTypeOperator INT,  
	ServiceTypeValue nvarchar(50)   
	,StatusOperator INT,  
	StatusValue nvarchar(50)   
	,MemberNameOperator INT,  
	MemberNameValue nvarchar(50)   
	,VehicleOperator INT,  
	VehicleValue nvarchar(50)   
	,VendorOperator INT,  
	VendorValue nvarchar(50)   
	,POCountOperator INT,  
	POCountValue int   
	,MembershipIDOperator INT,  
	MembershipIDValue int   
	,ContactPhoneNumberOperator INT,  
	ContactPhoneNumberValue nvarchar(50)
	 )   
	 
	DECLARE @MembershipID int

	SELECT	@MembershipID = MembershipIDValue
	FROM	@tmpForWhereClause
 
  
	INSERT INTO #FinalResultsFiltered
	SELECT  
		c.ID AS CaseNumber,   
		sr.ID AS ServiceRequestNumber,  
		sr.CreateDate,   
		pc.Name AS ServiceType,   
		srs.Name AS 'Status',  
		M.FirstName,
		M.MiddleName,
		M.LastName,
		M.Suffix,				  
		C.VehicleYear,
		C.VehicleMake,
		C.VehicleMakeOther,
		C.VehicleModel,
		C.VehicleModelOther,				   
		ven.Name AS Vendor,  
		ms.ID AS MembershipID,  
		0 AS POCount	,
		C.ContactPhoneNumber	AS ContactPhoneNumber		  
	FROM ServiceRequest sr  WITH (NOLOCK)
	JOIN [Case] c WITH (NOLOCK) ON c.ID = sr.CaseID  
	JOIN Member m WITH (NOLOCK) ON m.ID = c.MemberId  
	JOIN Membership ms WITH (NOLOCK) ON ms.ID = m.MembershipID
	JOIN ServiceRequestStatus srs WITH (NOLOCK) ON srs.ID = sr.ServiceRequestStatusID  
	LEFT JOIN ProductCategory pc WITH (NOLOCK) ON pc.ID = sr.ProductCategoryID     
	LEFT JOIN (SELECT TOP 1 ServiceRequestID, VendorLocationID   ---- Someone should verify this SQL?????  
			   FROM PurchaseOrder WITH (NOLOCK) 
			   ORDER BY issuedate DESC  
			  )  LastPO ON LastPO.ServiceRequestID = sr.ID   
	LEFT JOIN VendorLocation vl WITH (NOLOCK) on vl.ID = LastPO.VendorLocationID  
	LEFT JOIN Vendor ven WITH (NOLOCK) on ven.ID = vl.VendorID  
	WHERE ms.ID = @MembershipID 
 
	INSERT INTO #FinalResultsFormatted
	SELECT DISTINCT F.CaseNumber,   
		F.ServiceRequestNumber,  
		F.CreateDate,   
		F.ServiceType,   
		F.[Status],  
		REPLACE(RTRIM(  
		COALESCE(F.FirstName,'')+  
		COALESCE(' '+left(F.MiddleName,1),'')+  
		COALESCE(' '+ F.LastName,'')+  
		COALESCE(' '+ F.Suffix,'')  
		),'  ',' ') AS MemberName,  
		REPLACE(RTRIM(  
		COALESCE(F.VehicleYear,'')+  
		COALESCE(' '+ CASE F.VehicleMake WHEN 'Other' THEN F.VehicleMakeOther ELSE F.VehicleMake END,'')+  
		COALESCE(' '+ CASE F.VehicleModel WHEN 'Other' THEN F.VehicleModelOther ELSE F.VehicleModel END,'')  
		),'  ',' ') AS Vehicle,  
		F.Vendor,  
		(select count(*) FROM PurchaseOrder po WITH (NOLOCK) WHERE po.ServiceRequestID = F.ServiceRequestNumber and po.IsActive<>0) AS POCount, 
		F.MembershipID,
		F.ContactPhoneNumber
	FROM	#FinalResultsFiltered F
 
	--DEBUG
	-- SELECT * FROM #FinalResultsFiltered

	INSERT INTO #FinalResultsSorted
	SELECT F.*
	FROM  #FinalResultsFormatted F
	ORDER BY   
		CASE WHEN @sortColumn = 'CaseNumber' AND @sortOrder = 'ASC'  
		THEN F.CaseNumber END ASC,   
		CASE WHEN @sortColumn = 'CaseNumber' AND @sortOrder = 'DESC'  
		THEN F.CaseNumber END DESC ,  

		CASE WHEN @sortColumn = 'ServiceRequestNumber' AND @sortOrder = 'ASC'  
		THEN F.ServiceRequestNumber END ASC,   
		CASE WHEN @sortColumn = 'ServiceRequestNumber' AND @sortOrder = 'DESC'  
		THEN F.ServiceRequestNumber END DESC ,  

		CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'  
		THEN F.CreateDate END ASC,   
		CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'  
		THEN F.CreateDate END DESC ,  

		CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'ASC'  
		THEN F.ServiceType END ASC,   
		CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'DESC'  
		THEN F.ServiceType END DESC ,  

		CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'  
		THEN F.Status END ASC,   
		CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'  
		THEN F.Status END DESC ,  

		CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'  
		THEN F.MemberName END ASC,   
		CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'  
		THEN F.MemberName END DESC ,  

		CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'ASC'  
		THEN F.Vehicle END ASC,   
		CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'DESC'  
		THEN F.Vehicle END DESC ,  

		CASE WHEN @sortColumn = 'Vendor' AND @sortOrder = 'ASC'  
		THEN F.Vendor END ASC,   
		CASE WHEN @sortColumn = 'Vendor' AND @sortOrder = 'DESC'  
		THEN F.Vendor END DESC ,  

		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'  
		THEN F.POCount END ASC,   
		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'  
		THEN F.POCount END DESC ,  

		CASE WHEN @sortColumn = 'MembershipID' AND @sortOrder = 'ASC'  
		THEN F.MembershipID END ASC,   
		CASE WHEN @sortColumn = 'MembershipID' AND @sortOrder = 'DESC'  
		THEN F.MembershipID END DESC ,  

		CASE WHEN @sortColumn = 'ContactPhoneNumber' AND @sortOrder = 'ASC'  
		THEN F.ContactPhoneNumber END ASC,   
		CASE WHEN @sortColumn = 'ContactPhoneNumber' AND @sortOrder = 'DESC'  
		THEN F.ContactPhoneNumber END DESC 

  
	DECLARE @count INT     
	SET @count = 0     
	SELECT @count = MAX(RowNum) FROM #FinalResultsSorted  
	IF (@endInd IS NOT NULL)
	BEGIN
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
	END
	  
	SELECT @count AS TotalRows,   
	   F.RowNum,  
	   F.CaseNumber,  
	   F.ServiceRequestNumber,  
	   CONVERT(VARCHAR(10), F.CreateDate, 101) AS 'Date',  
	   F.ServiceType,  
	   F.Status,  
	   F.MemberName,  
	   F.Vehicle,  
	   F.Vendor,  
	   F.POCount ,
	   F.ContactPhoneNumber
	   FROM #FinalResultsSorted F 
	WHERE 
			(@endInd IS NULL AND RowNum >= @startInd)
			OR
			(RowNum BETWEEN @startInd AND @endInd)
	   
	   
	DROP TABLE #FinalResultsFiltered
	DROP TABLE #FinalResultsFormatted
	DROP TABLE #FinalResultsSorted

END

GO
		
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Membsership_Information]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Membsership_Information] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 	
 -- EXEC [dbo].[dms_Membsership_Information] 1
 CREATE PROC [dbo].[dms_Membsership_Information](@memberID INT = NULL)
 AS
 BEGIN
	
	-- Dates used while calculating member status
DECLARE @now DATETIME, @minDate DATETIME
SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
SET @minDate = '1900-01-01'
	
	SELECT	m.ID AS MemberID,
		
		REPLACE(RTRIM( 
COALESCE(M.FirstName, '') + 
COALESCE(' ' + left(M.MiddleName,1), '') + 
COALESCE(' ' + M.LastName, '') +
COALESCE(' ' + M.Suffix, '')
), ' ', ' ') AS MemberName,
			
		-- KB: Considering Effective and Expiration Dates to calculate member status	
		CASE WHEN ISNULL(m.EffectiveDate,@minDate) <= @now AND ISNULL(m.ExpirationDate,@minDate) >= @now
				THEN 'Active'
				ELSE 'Inactive'
		END	AS MemberStatus,
		ms.MembershipNumber AS MemberNumber,
		c.Name AS Client,  
		--parent.Code AS Program,  
		p.[Description] as Program,
		(SELECT MAX(ServiceCoverageLimit)FROM ProgramProduct pp WHERE pp.ProgramID = p.ID) as Limit,		
		CONVERT(varchar(10),m.MemberSinceDate,101) AS MemberSince,
		CONVERT(VARCHAR(10),m.ExpirationDate,101)AS Expiration, 
		m.ExpirationDate AS ExpirationDate,
		m.EffectiveDate AS EffectiveDate,
		CONVERT(VARCHAR(10),m.EffectiveDate,101)AS Effective, 
		ms.ClientReferenceNumber as ClientRefNumber, 
		ms.CreateDate as Created, 
		ms.ModifyDate as LastUpdate,
		ms.Note as MembershipNote,
		M.FirstName,
		M.MiddleName,
		M.LastName,
		M.Prefix,
		M.Suffix
	FROM Member m 
	JOIN Membership ms ON ms.ID = m.MembershipID
	JOIN Program p ON p.id = m.ProgramID
	LEFT OUTER JOIN Program parent ON parent.ID = p.ParentProgramID
	JOIN Client c ON c.ID = p.ClientID
	WHERE m.ID = @MemberID

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
 WHERE id = object_id(N'[dbo].[dms_Merge_Members_Search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Merge_Members_Search]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Merge_Members_Search] @whereClauseXML=N'<ROW><Filter FirstNameOperator="4" FirstNameValue="jeevan"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=NULL
--EXEC [dbo].[dms_Merge_Members_Search] @whereClauseXML=N'<ROW><Filter PhoneNumberOperator="2" PhoneNumberValue="8173078882"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
--EXEC [dbo].[dms_Merge_Members_Search] @whereClauseXML=N'<ROW><Filter MemberNumberOperator="2" MemberNumberValue="123"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
-- EXEC [dbo].[dms_Merge_Members_Search] @whereClauseXML=N'<ROW><Filter VINOperator="4" VINValue="K1234422323N1233"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3

CREATE PROCEDURE [dbo].[dms_Merge_Members_Search](   
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10   
 , @sortColumn nvarchar(100)  = 'MemberNumber'   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @programID INT = NULL   
 )   
 AS   
 BEGIN   
    
	SET NOCOUNT ON    
SET FMTONLY OFF;
	-- KB : Temporary resultsets. These resultsets are used to prepare mangeable resultsets.
	CREATE TABLE #FinalResultsFiltered(     

	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	Suffix nvarchar(50)  NULL ,    
	Prefix nvarchar(50)  NULL ,    
	City nvarchar(50)  NULL ,    
	StateProvince nvarchar(50)  NULL ,    
	PostalCode nvarchar(50)  NULL ,    
	HomePhoneNumber nvarchar(50)  NULL ,    
	WorkPhoneNumber nvarchar(50)  NULL ,    
	CellPhoneNumber nvarchar(50)  NULL ,  
	ProgramID INT NULL, -- KB: ADDED IDS  
	Program nvarchar(50)  NULL ,    
	POCount INT NULL,  
	ExpirationDate DATETIME NULL,   
	EffectiveDate DATETIME NULL,
	VIN nvarchar(50)  NULL ,    
	VehicleID INT NULL, -- KB: Added VehicleID
	[StateProvinceID] INT  NULL,
	MiddleName   nvarchar(50)  NULL , 
	ClientMemberType nvarchar(200)  NULL 
	)    

	CREATE TABLE #FinalResultsFormatted(      
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,  
	VehicleID INT NULL, -- KB: Added VehicleID  
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL,
	ClientMemberType nvarchar(200)  NULL  
	)    

	CREATE TABLE #FinalResultsSorted(     
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL , 
	VehicleID INT NULL, -- KB: Added VehicleID   
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL,
	ClientMemberType nvarchar(200)  NULL   
	)  
	--CREATE TABLE #FinalResultsDistinct(     
	--[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	--MemberID int  NULL ,   
	--MembershipID INT NULL,   
	--MemberNumber nvarchar(50)  NULL ,    
	--Name nvarchar(200)  NULL ,    
	--[Address] nvarchar(max)  NULL ,    
	--PhoneNumber nvarchar(50)  NULL , 
	--ProgramID INT NULL, -- KB: ADDED IDS   
	--Program nvarchar(50)  NULL ,    
	--POCount int  NULL ,    
	--MemberStatus nvarchar(50)  NULL ,    
	--LastName nvarchar(50)  NULL ,    
	--FirstName nvarchar(50)  NULL ,    
	--VIN nvarchar(50)  NULL ,  
	--VehicleID INT NULL, -- KB: Added VehicleID  
	--State nvarchar(50)  NULL ,    
	--ZipCode nvarchar(50)  NULL,
	--ClientMemberType nvarchar(200)  NULL
	--)  

	CREATE TABLE #SearchPrograms (
	ProgramID int, 
	ProgramName nvarchar(200),
	ClientID int
	)
	
	IF @programID IS NOT NULL
	BEGIN
	
	INSERT INTO #SearchPrograms (ProgramID, ProgramName, ClientID)
	SELECT ProgramID, ProgramName, ClientID
	--FROM [dbo].[fnc_GetMemberSearchPrograms](9) --@programID)
	FROM [dbo].[fnc_GetMemberSearchPrograms] (@programID)
	
	END
	ELSE
	BEGIN
		INSERT INTO #SearchPrograms (ProgramID, ProgramName, ClientID)
	    SELECT ID,Name,ClientID FROM Program
	END
	
	CREATE CLUSTERED INDEX IDX_SearchPrograms ON #SearchPrograms(ProgramID)
	--Select * From #SearchPrograms
	--Drop table #SearchPrograms
	
	DECLARE @idoc int    
	IF @whereClauseXML IS NULL     
	BEGIN    
	SET @whereClauseXML = '<ROW><Filter     
	MemberIDOperator="-1"     
	MemberNumberOperator="-1"     
	PhoneNumberOperator="-1"     
	ProgramOperator="-1"     
	LastNameOperator="-1"     
	FirstNameOperator="-1"     
	VINOperator="-1"     
	StateOperator="-1"    
	ZipCodeOperator = "-1"   
	></Filter></ROW>'    
	END    
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML    

	DECLARE @tmpForWhereClause TABLE    
	(    
	MemberIDOperator INT NOT NULL,    
	MemberIDValue int NULL,    
	MemberNumberOperator INT NOT NULL,    
	MemberNumberValue nvarchar(50) NULL,    
	PhoneNumberOperator INT NOT NULL,    
	PhoneNumberValue nvarchar(50) NULL,    
	ProgramOperator INT NOT NULL,    
	ProgramValue nvarchar(50) NULL,    
	LastNameOperator INT NOT NULL,    
	LastNameValue nvarchar(50) NULL,    
	FirstNameOperator INT NOT NULL,    
	FirstNameValue nvarchar(50) NULL,    
	VINOperator INT NOT NULL,    
	VINValue nvarchar(50) NULL,    
	StateOperator INT NOT NULL,    
	StateValue nvarchar(50) NULL,  
	ZipCodeOperator INT NOT NULL,    
	ZipCodeValue   nvarchar(50) NULL	
	)    

	-- Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'     

	INSERT INTO @tmpForWhereClause    
	SELECT      
			ISNULL(MemberIDOperator,-1),    
			MemberIDValue ,    
			ISNULL(MemberNumberOperator,-1),    
			MemberNumberValue ,    
			ISNULL(PhoneNumberOperator,-1),    
			PhoneNumberValue ,    
			ISNULL(ProgramOperator,-1),    
			ProgramValue ,    
			ISNULL(LastNameOperator,-1),    
			LastNameValue ,    
			ISNULL(FirstNameOperator,-1),    
			FirstNameValue ,    
			ISNULL(VINOperator,-1),    
			VINValue ,    
			ISNULL(StateOperator,-1),    
			StateValue, 			  
			ISNULL(ZipCodeOperator,-1),    
			ZipCodeValue    
	FROM OPENXML (@idoc,'/ROW/Filter',1) 
	WITH (    
			MemberIDOperator INT,    
			MemberIDValue int     
			,MemberNumberOperator INT,    
			MemberNumberValue nvarchar(50)     
			,PhoneNumberOperator INT,    
			PhoneNumberValue nvarchar(50)     
			,ProgramOperator INT,    
			ProgramValue nvarchar(50)     
			,LastNameOperator INT,    
			LastNameValue nvarchar(50)     
			,FirstNameOperator INT,    
			FirstNameValue nvarchar(50)     
			,VINOperator INT,    
			VINValue nvarchar(50)     
			,StateOperator INT,    
			StateValue nvarchar(50)     
			,ZipCodeOperator INT,    
			ZipCodeValue nvarchar(50)   
	)     
	
	
	DECLARE @memberEntityID INT ,
		@HomeAddressTypeID INT
	SELECT @memberEntityID = ID FROM Entity WHERE Name = 'Member'  
	SELECT @HomeAddressTypeID = ID FROM AddressType WHERE Name = 'Home'

	DECLARE @memberID INT
	DECLARE @memberNumber NVARCHAR(50)
	DECLARE @programCode NVARCHAR(50)
	DECLARE @firstName NVARCHAR(50)
	DECLARE @lastName NVARCHAR(50)
	DECLARE @state NVARCHAR(50)
	DECLARE @zip NVARCHAR(50)
	DECLARE @vinParam nvarchar(50) = NULL   
	DECLARE @phoneNumber NVARCHAR(100) = NULL
	

	SELECT	@memberID = MemberIDValue,
			@memberNumber = MemberNumberValue,
			@programCode = ProgramValue,
			@firstName = FirstNameValue,
			@lastName = LastNameValue,
			@state = StateValue,
			@zip = ZipCodeValue	,
			@PhoneNumber = REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumberValue,'(',''),' ',''),'-',''),')',''),  --Remove formatting
			@VinParam = VinValue				
	FROM	@tmpForWhereClause

	
	SET FMTONLY OFF;  	  
			
			
			Declare @sql nvarchar(max) = ''
			
			SET @sql =        'SELECT DISTINCT TOP 1000'
			SET @sql = @sql + '  M.id AS MemberID'  
			SET @sql = @sql + ' ,M.MembershipID' 
			SET @sql = @sql + ' ,CASE WHEN MS.MembershipNumber IS NULL THEN ''Ref#: '' + MS.ClientReferenceNUmber ELSE MS.MembershipNumber END AS MemberNumber'
			SET @sql = @sql + ' ,M.FirstName'
			SET @sql = @sql + ' ,M.LastName'
			SET @sql = @sql + ' ,M.Suffix'
			SET @sql = @sql + ' ,M.Prefix'     
			SET @sql = @sql + ' ,A.City' 
			SET @sql = @sql + ' ,A.StateProvince' 
			SET @sql = @sql + ' ,A.PostalCode' 
			SET @sql = @sql + ' , NULL AS HomePhoneNumber'-- PH.PhoneNumber AS HomePhoneNumber 
			SET @sql = @sql + ' ,NULL AS WorkPhoneNumber' -- PW.PhoneNumber AS WorkPhoneNumber
			SET @sql = @sql + ' ,NULL AS CellPhoneNumber' -- PC.PhoneNumber AS CellPhoneNumber
			SET @sql = @sql + ' , P.ID As ProgramID' -- KB: ADDED IDS
			SET @sql = @sql + ' ,P.[Description] AS Program'
			SET @sql = @sql + ' ,0 AS POCount' -- Computed later  
			SET @sql = @sql + ' ,m.ExpirationDate'  
			SET @sql = @sql + ' ,m.EffectiveDate'			
			SET @sql = @sql + ' ,(SELECT TOP 1 V.VIN FROM Vehicle V WHERE V.MembershipID = MS.ID'
					+ CASE WHEN @vinParam IS NOT NULL THEN ' AND V.VIN = @vinParam)' ELSE ')' END	
			SET @sql = @sql + ' ,(SELECT TOP 1 V.ID FROM Vehicle V WHERE V.MembershipID = MS.ID'
					+ CASE WHEN @vinParam IS NOT NULL THEN ' AND V.VIN = @vinParam)' ELSE ')' END	
			SET @sql = @sql + ' ,A.[StateProvinceID]'
			SET @sql = @sql + ' ,M.MiddleName'
			SET @sql = @sql + ' ,M.ClientMemberType'	   
			SET @sql = @sql + ' FROM Member M WITH (NOLOCK)'
			SET @sql = @sql + ' JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID'
			SET @sql = @sql + ' LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID =  '+ CONVERT(nvarchar(50), @memberEntityID) 
			SET @sql = @sql + ' JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID '   
			SET @sql = @sql + ' JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID'			
			SET @sql = @sql + ' WHERE  ( @memberID IS NULL  OR @memberID = M.ID )'	
	
			IF @memberNumber IS NOT NULL
			SET @sql = @sql + ' AND (MS.MembershipNumber LIKE char(37) + @memberNumber + char(37) OR MS.AltMembershipNumber				LIKE  char(37) + @memberNumber + char(37))'

			IF @vinParam IS NOT NULL 
			SET @sql = @sql + ' AND MS.ID IN (SELECT v1.MembershipID FROM Vehicle v1 WHERE v1.VIN = @vinParam)'
	
			IF @phoneNumber IS NOT NULL
			SET @sql = @sql + ' AND M.ID IN (SELECT PH.RecordID FROM PhoneEntity PH WITH (NOLOCK) WHERE PH.EntityID = ' +				CONVERT(nvarchar(50), @memberEntityID) + ' AND PH.PhoneNumber LIKE char(37) + @phoneNumber + char(37))'	
			 
			IF @Zip IS NOT NULL
			SET @sql = @sql + ' AND A.PostalCode LIKE char(37) + @Zip + char(37)' 
			
			IF @programCode IS NOT NULL
			SET @sql = @sql + ' AND P.Code = @ProgramCode'
			
			IF @lastName IS NOT NULL
			SET @sql = @sql + ' AND M.LastName = @lastName'	
			
			IF @firstName IS NOT NULL
			SET @sql = @sql + ' AND M.FirstName LIKE @firstName + char(37)'
			
			IF @state IS NOT NULL
			SET @sql = @sql + ' AND A.StateProvinceID = @state'			
			
			
			SET @sql = @sql + '	AND M.IsActive=1'
			SET @sql = @sql + ' OPTION (RECOMPILE)'
			
			INSERT INTO #FinalResultsFiltered
			EXEC sp_executesql @sql, N'@memberID INT,@memberNumber nvarchar(50), @vinParam nvarchar(50),@phoneNumber nvarchar(20), @Zip nvarchar(50), @ProgramCode INT,   @lastName nvarchar(50), @firstName nvarchar(50), @state INT'
				, @memberID, @memberNumber, @vinParam, @PhoneNumber, @Zip, @programCode, @lastName, @firstName, @state
		
		
	 

	-- Do all computations  
	INSERT INTO #FinalResultsFormatted  
	SELECT   F.MemberID  
	, F.MembershipID  
	, F.MemberNumber     
	--, REPLACE(RTRIM(COALESCE(F.LastName, '')   
	-- + COALESCE(' ' + F.Suffix, '')   
	-- + COALESCE(', ' + F.FirstName, '')), ' ', ' ')   
	-- + COALESCE(' ' + F.Prefix, '') AS Name  
	,REPLACE(RTRIM( 
	COALESCE(F.FirstName, '') + 
	COALESCE(' ' + left(F.MiddleName,1), '') + 
	COALESCE(' ' + F.LastName, '') +
	COALESCE(' ' + F.Suffix, '')
	), ' ', ' ') AS MemberName
	,(ISNULL(F.City,'') + ',' + ISNULL(F.StateProvince,'') + ' ' + ISNULL(F.PostalCode,'')) AS [Address]     
	, COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber 
	, F.ProgramID -- KB: ADDED IDS    
	, F.Program    
	,(SELECT COUNT(*) FROM [Case] WHERE MemberID = F.MemberID) AS POCount   
	-- Ignore time while comparing the dates here  
	--,CASE WHEN F.EffectiveDate <= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0) AND F.ExpirationDate >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)   
	--  THEN 'Active'   
	--  ELSE 'Inactive'   
	-- END 
	-- KB: Considering Effective and Expiration Dates to calculate member status
	,CASE WHEN ISNULL(F.EffectiveDate,@minDate) <= @now AND ISNULL(F.ExpirationDate,@minDate) >= @now
			THEN 'Active'
			ELSE 'Inactive'
	END AS MemberStatus
	, F.LastName  
	, F.FirstName  
	, F.VIN 
	, F.VehicleID  
	, F.StateProvinceID AS [State]  
	, F.PostalCode AS ZipCode  
	, F.ClientMemberType
	FROM #FinalResultsFiltered F 
	 
	LEFT JOIN PhoneEntity PH WITH (NOLOCK) ON PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR PH.PhoneNumber like CHAR(37) + @phoneNumber + CHAR(37))
		LEFT JOIN PhoneEntity PW WITH (NOLOCK) ON PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR PW.PhoneNumber like CHAR(37) + @phoneNumber + CHAR(37))  
		LEFT JOIN PhoneEntity PC WITH (NOLOCK) ON PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR PC.PhoneNumber like CHAR(37) + @phoneNumber + CHAR(37))



		INSERT INTO #FinalResultsSorted  
		SELECT  F.MemberID,  
		F.MembershipID,    
		F.MemberNumber,     
		F.Name,    
		F.[Address],    
		F.PhoneNumber,  
		F.ProgramID, -- KB: ADDED IDS     
		F.Program,    
		F.POCount,    
		F.MemberStatus,    
		F.LastName,    
		F.FirstName ,    
		F.VIN ,
		F.VehicleID,    
		F.[State] ,    
		F.ZipCode ,
		F.ClientMemberType
		FROM  #FinalResultsFormatted F   
		
		ORDER BY     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'    
		THEN F.MembershipID END ASC,     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'    
		THEN F.MembershipID END DESC ,    

		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'    
		THEN F.MemberNumber END ASC,     
		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'    
		THEN F.MemberNumber END DESC ,    

		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'    
		THEN F.Name END ASC,     
		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'    
		THEN F.Name END DESC ,    

		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'    
		THEN F.Address END ASC,     
		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'    
		THEN F.Address END DESC ,    

		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC ,    

		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,    

		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'    
		THEN F.POCount END ASC,     
		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'    
		THEN F.POCount END DESC ,    

		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'ASC'    
		THEN F.MemberStatus END ASC,     
		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'DESC'    
		THEN F.MemberStatus END DESC    

	  
	
	

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

	
	
	SELECT @count AS TotalRows, F.MemberID,  
		F.MembershipID,    
	   F.MemberNumber,     
	   F.Name,    
	   F.[Address],    
	   F.PhoneNumber,  
	   F.ProgramID, -- KB: ADDED IDS      
	   F.Program,    
	   F.POCount,    
	   F.MemberStatus,    
	   F.VIN,
	   F.VehicleID ,
	   F.ClientMemberType
	   FROM    
	   #FinalResultsSorted F WHERE RowNum BETWEEN @startInd AND @endInd  
     
	DROP TABLE #FinalResultsFiltered  
	DROP TABLE #FinalResultsFormatted  
	DROP TABLE #FinalResultsSorted 
	



END

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
					AND DATEDIFF(mi,M.[DateTime],GETDATE()) <= 60 
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
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_NightlyMaintenance]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_NightlyMaintenance] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[dms_NightlyMaintenance] 
AS
BEGIN
	SET NOCOUNT ON;

	EXEC dbo.dms_Vendor_UpdateAdminisrativeRating
	EXEC dbo.dms_Vendor_UpdateProductRating
	EXEC dbo.dms_Claim_FordQFC_Create
	EXEC dbo.dms_ServiceRequestAgentTime_Update
	EXEC dbo.dms_TemporaryDataFixes
	EXEC dbo.dms_Billing_GenerateMissingInvoices

END

GO

 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_POCopyProduct_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_POCopyProduct_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_POCopyProduct_list] 1,1,1
 CREATE PROCEDURE [dbo].[dms_POCopyProduct_list]
 (
 @VehicleTypeID int=null,
 @VehicleCategoryID int=null,
 @ProgramID INT = NULL
 )
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

    select P.* 
	from Product P
	JOIN ProgramProduct PP ON PP.ProductID = P.ID
    where
		p.ProductTypeID = 1 and ISNULL(p.IsShowOnPO, 0) = 1
		and P.ProducTSubTypeID in (1,2)
		and (p.VehicleCategoryID = @VehicleCategoryID or p.VehicleCategoryID is null)
		and (p.VehicleTypeID = @VehicleTypeID or p.VehicleTypeID is null)
		AND PP.ProgramID = @ProgramID
		order by p.name
END

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

	, ISNULL(c.VehicleYear + ' ' + CASE WHEN c.VehicleMake = 'Other' THEN c.VehicleMakeOther ELSE c.VehicleMake END + ' ' + CASE WHEN c.VehicleModel = 'Other' THEN c.VehicleModelOther ELSE c.VehicleModel END,' ') AS MemberVehicleDesc -- coalesce 

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
	
	,ISNULL(po.AdditionalInstructions,'') AS AdditionalInstructions
	
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
IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_PO_MemberPayDispatchFee]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_PO_MemberPayDispatchFee] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 
--EXEC [dms_PO_MemberPayDispatchFee] 943, 100
CREATE PROCEDURE [dbo].[dms_PO_MemberPayDispatchFee]( 
  @poId INT = NULL 
, @purchaseOrderAmount money = 0
) 
AS 
BEGIN 
	DECLARE @internalDispatchFee money = 0, 
			@clientDispatchFee money = 0, 
			@creditCardProcessingFee money = 0, 
			@dispatchFee money = 0, 
			@StringDispatchFee nvarchar(100) = NULL

	DECLARE @serviceRequestID INT = (SELECT ServiceRequestID from PurchaseOrder where ID = @poID)

	DECLARE @programID INT = (
		SELECT C.ProgramID
		FROM [Case] C with (nolock)
		JOIN ServiceRequest SR with (nolock) ON C.ID = SR.CaseID
		JOIN PurchaseOrder PO with (Nolock) ON PO.ServiceRequestID = SR.ID
		where PO.ID = @poId
	)
	
	--DECLARE @programName NVARCHAR(100) = (SELECT Name FROM Program where ID = @programID)

	DECLARE @caseVehcileTypeID INT = (
		SELECT C.VehicleTypeID
		FROM [Case] C with (nolock)
		JOIN ServiceRequest SR with (nolock) ON C.ID = SR.CaseID
		JOIN PurchaseOrder PO with (Nolock) ON PO.ServiceRequestID = SR.ID
		where PO.ID = @poId
	)

	DECLARE @autoVehicleType INT = (SELECT ID FROM VehicleType WHERE Name = 'Auto')
	DECLARE @rvVehicleType INT = (SELECT ID FROM VehicleType WHERE Name = 'RV')
	DECLARE @rentalCoverProgramID INT = (SELECT ID FROM Program where Name = 'RentalCover.com')
	--DECLARE @rentalCoverProgramID INT = (SELECT ID FROM Program where Name = 'Platinum')

	--DECLARE @applicationConfigurationTypeID INT = (SELECT ID FROM ConfigurationType where Name='Application')
	--DECLARE @ruleConfigurationCategoryID INT = (SELECT ID FROM ConfigurationCategory where Name='Rule')
	
	DECLARE @issuedPurchaseOrderStatusID INT = (SELECT ID FROM PurchaseOrderStatus where Name='Issued')
	--Note: Checking to see if there are any issued POs other than the current one.
	DECLARE @issuePOCount INT = (SELECT Count(ID) FROM PurchaseOrder where PurchaseOrderStatusID = @issuedPurchaseOrderStatusID AND ServiceRequestID = @serviceRequestID AND ID <> @poId)
	DECLARE @ProgramConfigValues TABLE
	(
		Name NVARCHAR(100) NULL,
		Value NVARCHAR(255) NULL,
		ControlType NVARCHAR(255) NULL,
		DataType NVARCHAR(255) NULL,
		Sequence INT NULL
	)
	
	INSERT INTO @ProgramConfigValues 
	SELECT	PC.Name, 
			PC.Value, 
			CT.Name AS ControlType, 
			DT.Name AS DataType,  
			PC.Sequence AS Sequence
	FROM ProgramConfiguration PC
	JOIN [dbo].[fnc_GetProgramConfigurationForProgram](@programID,'Application') P ON P.ProgramConfigurationID = PC.ID
	LEFT JOIN ConfigurationCategory C ON PC.ConfigurationCategoryID = C.ID
	LEFT JOIN ControlType CT ON PC.ControlTypeID = CT.ID
	LEFT JOIN DataType DT ON PC.DataTypeID = DT.ID
	WHERE	(C.Name = 'Rule')
	ORDER BY Sequence, Name
	
	IF EXISTS(SELECT * FROM @ProgramConfigValues WHERE Name='MemberPayDispatchFee' AND DataType <> 'Query')
	BEGIN		
		SET @StringDispatchFee = (SELECT W.Value FROM @ProgramConfigValues W where W.Name='MemberPayDispatchFee' AND W.DataType <> 'Query')
	END
	ELSE
	BEGIN
		SET @StringDispatchFee = (SELECT TOP 1 Value FROM ApplicationConfiguration where Name= 'MemberPayDispatchFee')
	END
	
	IF @programID = @rentalCoverProgramID
	BEGIN
		IF @issuePOCount = 0
		BEGIN 
			IF @caseVehcileTypeID = @autoVehicleType
			BEGIN
				SET @internalDispatchFee = 17.79
			END
			ELSE IF @caseVehcileTypeID = @rvVehicleType
			BEGIN
				SET @internalDispatchFee = 30.20
			END
			
			SET @clientDispatchFee = ISNULL(@purchaseOrderAmount,0) * 3
			
			SET @creditCardProcessingFee = ((ISNULL(@purchaseOrderAmount,0) + @clientDispatchFee) * 3) /100
			
			SET @dispatchFee = @internalDispatchFee + @clientDispatchFee + @creditCardProcessingFee
			
			SET @StringDispatchFee = @dispatchFee
		END
	END

	SELECT @internalDispatchFee AS InternalDispatchFee, @clientDispatchFee AS ClientDispatchFee, @creditCardProcessingFee AS CreditCardProcessingFee, @dispatchFee AS DispatchFee, @StringDispatchFee AS StringDispatchFee

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
 WHERE id = object_id(N'[dbo].[dms_queue_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_queue_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_queue_list] @userID = '67E7D483-51E8-4D9C-97B6-D8ABB6D87B4B', @sortColumn='RequestNumber',@sortOrder = 'ASC',@whereClauseXML = '<ROW><Filter StatusOperator="11" StatusValue="Manager"></Filter></ROW>'
-- EXEC [dbo].[dms_queue_list] @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB', @sortColumn='RequestNumber',@sortOrder = 'ASC',@whereClauseXML = '<ROW><Filter StatusValue="Manager"></Filter></ROW>'
-- EXEC [dbo].[dms_queue_list] @userID = '67E7D483-51E8-4D9C-97B6-D8ABB6D87B4B', @sortColumn='RequestNumber',@sortOrder = 'ASC',@whereClauseXML = '<ROW><Filter PONumberOperator="2" PONumberValue="8012956"></Filter></ROW>'
-- EXEC [dbo].[dms_queue_list] @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB', @sortColumn='RequestNumber',@sortOrder = 'ASC',@whereClauseXML = '<ROW><Filter MemberOperator="2" MemberValue="Reddy" StatusValue="RVTech"></Filter></ROW>'
-- EXEC [dbo].[dms_queue_list] @userID = '67E7D483-51E8-4D9C-97B6-D8ABB6D87B4B', @sortColumn='RequestNumber',@sortOrder = 'ASC', @whereClauseXML = '<ROW><Filter RequestNumberOperator="4" RequestNumberValue="4"></Filter></ROW>'
-- EXEC [dbo].[dms_queue_list] @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB', @sortColumn='RequestNumber',@sortOrder = 'ASC',@whereClauseXML = '<ROW><Filter PONumberOperator="11" StatusValue="Cancelled"></Filter></ROW>'
-- EXEC [dbo].[dms_queue_list] @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB', @sortColumn='RequestNumber',@sortOrder = 'ASC',@whereClauseXML = '<ROW><Filter statusOperator="11" StatusValue="FHT" ></Filter></ROW>'
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
DECLARE @isFHT  BIT = 0

DECLARE @serviceRequestEntityID INT
DECLARE @fhtContactReasonID INT
DECLARE @dispatchStatusID INT

SET @serviceRequestEntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
SET @fhtContactReasonID = (SELECT ID FROM ContactReason WHERE Name = 'HumanTouch')
SET @dispatchStatusID = (SELECT ID FROM ServiceRequestStatus WHERE Name = 'Dispatched')

DECLARE @StartMins INT = 0 
SELECT @StartMins = -1 * CONVERT(INT, ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'FordHumanTouchStartMins' 

DECLARE @EndMins INT = 0 
SELECT @EndMins = -1 * CONVERT(INT, ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'FordHumanTouchEndMins' 

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
 FROM	@tmpForWhereClause
  
  
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

DECLARE @sql NVARCHAR(MAX) = ''
  
INSERT INTO @tmpStatusInput  
SELECT Item FROM [dbo].[fnSplitString](@StatusValue,',') 

--select * from @tmpStatusInput 


--INSERT INTO @tmpStatusInput  
--SELECT StatusName + '^' FROM @tmpStatusInput  

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
	SET @sql = @sql + ' 		DISTINCT   '
	SET @sql = @sql + ' 		SR.CaseID AS [Case],   '
	SET @sql = @sql + ' 		SR.ID AS [RequestNumber],   '
	SET @sql = @sql + ' 		CL.Name AS [Client],   '
	SET @sql = @sql + ' 		M.FirstName, '
	SET @sql = @sql + ' 		M.LastName, '
	SET @sql = @sql + ' 		M.MiddleName, '
	SET @sql = @sql + ' 		M.Suffix, '
	SET @sql = @sql + ' 		M.Prefix,      '
	-- KB: Retain original values here for sorting
	SET @sql = @sql + ' 		sr.CreateDate AS SubmittedOriginal, '
	-- KB: Retain original values here for sorting 
	SET @sql = @sql + ' 		SR.SecondaryProductID, '
	SET @sql = @sql + ' 		PC.Name AS [ServiceType],   '
	SET @sql = @sql + ' 		SRS.Name As [Status], '
	SET @sql = @sql + ' 		SR.IsRedispatched,     '
	SET @sql = @sql + ' 		C.AssignedToUserID, '
	SET @sql = @sql + ' 		SR.NextActionAssignedToUserID, '
	SET @sql = @sql + ' 		CLS.[Description] AS [ClosedLoop],      '
	SET @sql = @sql + ' 		0 AS [PONumber],   '
	SET @sql = @sql + ' 		'''' AS [ISPName],   '
	SET @sql = @sql + ' 		SR.CreateBy AS [CreateBy], '
	--RH: Temporary fix until we remove Ford Tech from Next Action
	SET @sql = @sql + ' 		CASE  '
	SET @sql = @sql + ' 		WHEN NA.Description = ''Ford Tech'' THEN ''RV Tech'' '
	SET @sql = @sql + ' 		ELSE COALESCE(NA.Description,'''')  '
	SET @sql = @sql + ' 		END AS [NextAction],   '
	/*1. SET @sql = @sql + ' NA.Description, '*/
	
	SET @sql = @sql + ' 		CASE  '
	SET @sql = @sql + ' 		WHEN SR.NextActionID = (SELECT ID FROM NextAction WHERE Name = ''FordTech'' AND IsActive = 1)  '
	SET @sql = @sql + ' 			THEN (SELECT ID FROM NextAction WHERE Name = ''RVTech'') '
	SET @sql = @sql + ' 		ELSE SR.NextActionID ' 
	SET @sql = @sql + ' 		END AS NextActionID,   '
	/*2. SET @sql = @sql + ' SR.NextActionID, '*/
	--RH: See above '
	SET @sql = @sql + ' 		SR.ClosedLoopStatusID as [ClosedLoopID],   '
	SET @sql = @sql + ' 		SR.ProductCategoryID as [ServiceTypeID],   '
	SET @sql = @sql + ' 		MS.MembershipNumber AS [MemberNumber],   '
	SET @sql = @sql + ' 		SR.ServiceRequestPriorityID AS [PriorityID],   '
	
	SET @sql = @sql + ' 		CASE  '
	SET @sql = @sql + ' 		WHEN SRP.Name IN (''Normal'',''Low'') THEN '''' '  -- Do not display Normal and Low text '
	SET @sql = @sql + ' 		ELSE SRP.Name  '
	SET @sql = @sql + ' 		END AS [Priority],    '
	/*3. SET @sql = @sql + ' SRP.Name, '*/
	SET @sql = @sql + ' 		sr.NextActionScheduledDate AS ''ScheduledOriginal'',' -- This field is used for Queue Color '
	IF (@isFHT = 0)
	BEGIN
		SET @sql = @sql +	' P.ProgramName, '
		SET @sql = @sql + 	' P.ProgramID, '
	END
	ELSE
	BEGIN
		SET @sql = @sql +  ' Prg.Name AS ProgramName, '
		SET @sql = @sql +  ' Prg.ID AS ProgramID, '
	END
	SET @sql = @sql + ' 		M.ID AS MemberID, '
	SET @sql = @sql + ' 		SR.StatusDateModified	,'		-- Added by Lakshmi	-Queue Color
	
	SET @sql = @sql + ' 		CASE  '
	SET @sql = @sql + ' 		WHEN sr.ServiceRequestPriorityID = (SELECT ID FROM ServiceRequestPriority WHERE Name = ''Critical'') THEN 1 '
	--RA 06/25/2014 - Added to push anything over 2 hrs to bottom of list
	SET @sql = @sql + ' 		WHEN sr.NextActionScheduledDate <= DATEADD(HH,@intPriorityHours,getdate()) THEN 2  '
	SET @sql = @sql + ' 		WHEN sr.NextActionScheduledDate IS NULL AND sr.ServiceRequestPriorityID = (SELECT ID FROM ServiceRequestPriority WHERE Name = ''High'') THEN 2 '
	SET @sql = @sql + ' 		ELSE 3 '
	SET @sql = @sql + ' 		END PrioritySort, '            -- Push critical and High to the top
	/*4. SET @sql = @sql + ' sr.ServiceRequestPriorityID, ' */ 
	
	SET @sql = @sql + ' 		SR.NextActionScheduledDate, '
	SET @sql = @sql + ' 		CASE '
	SET @sql = @sql + ' 		WHEN sr.NextActionScheduledDate <= DATEADD(HH,@intPriorityHours,getdate()) THEN sr.NextActionScheduledDate '
	SET @sql = @sql + ' 		ELSE ''1/1/2099'' '
	SET @sql = @sql + ' 		END ScheduleDateSort  '      -- Push items scheduled now to the top, then scheduled later, then null
	/*5. SET @sql = @sql + 	' sr.NextActionScheduledDate '*/
	SET @sql = @sql + ' FROM ServiceRequest SR WITH (NOLOCK) '
	SET @sql = @sql + ' JOIN [ServiceRequestStatus] SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID   '
	SET @sql = @sql + ' LEFT JOIN [ServiceRequestPriority] SRP WITH (NOLOCK) ON SR.ServiceRequestPriorityID = SRP.ID   '
	SET @sql = @sql + ' JOIN [Case] C WITH (NOLOCK) ON C.ID = SR.CaseID'
	SET @sql = @sql + ' JOIN [Member] M WITH (NOLOCK) ON C.MemberID = M.ID   '
	SET @sql = @sql + ' JOIN Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID   '
	SET @sql = @sql + ' LEFT JOIN [ProductCategory] PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID  	 '
	IF (@isFHT = 0)
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
		
		IF @RequestNumberValue IS NOT NULL
		BEGIN
			SET @sql = @sql + ' AND SR.ID = @RequestNumberValue'
		END
		ELSE
		BEGIN
			SET @sql = @sql + ' AND DATEDIFF(HH,SR.CreateDate,@now) <= @queueDisplayHours'
		END
	END
	ELSE
	BEGIN
		SET @sql = @sql + ' JOIN Program Prg on Prg.ID = C.ProgramID '	
		SET @sql = @sql + ' JOIN [Client] CL WITH (NOLOCK) ON Prg.ClientID = CL.ID '
		SET @sql = @sql + ' JOIN	PurchaseOrder PO on PO.ServiceRequestID = SR.ID 
								AND PO.PurchaseOrderStatusID IN 
								(SELECT ID FROM PurchaseOrderStatus WHERE Name IN (''Issued'', ''Issued-Paid'')) '
		SET @sql = @sql + ' LEFT JOIN [NextAction] NA WITH (NOLOCK) ON SR.NextActionID=NA.ID  '
		SET @sql = @sql + ' LEFT JOIN [VendorLocation] VL WITH (NOLOCK) ON PO.VendorLocationID = VL.ID  '
		SET @sql = @sql + ' LEFT JOIN [Vendor] V WITH (NOLOCK) ON VL.VendorID = V.ID   '
		SET @sql = @sql + ' LEFT OUTER JOIN ClosedLoopStatus CLS WITH (NOLOCK) on CLS.ID=SR.ClosedLoopStatusID '
		SET @sql = @sql + ' LEFT OUTER JOIN ( '
		SET @sql = @sql + ' SELECT	CLL.RecordID' 
		SET @sql = @sql + '	FROM	ContactLogLink cll  '
		SET @sql = @sql + ' JOIN	ContactLog cl ON cl.ID = cll.ContactLogID '
		SET @sql = @sql + '	JOIN	ContactLogReason clr ON clr.ContactLogID = cl.ID '
		SET @sql = @sql + '	WHERE	cll.EntityID = @serviceRequestEntityID '
		SET @sql = @sql + '	AND clr.ContactReasonID = @fhtContactReasonID '
		SET @sql = @sql + ' ) CLSR ON CLSR.RecordID = SR.ID '
		SET @sql = @sql + ' WHERE	CL.Name = ''Ford'' '
		SET @sql = @sql + ' AND		SR.ServiceRequestStatusID = @dispatchStatusID '
		SET @sql = @sql + ' AND		@now between dateadd(mi,@StartMins,po.ETADate) and dateadd(mi,@EndMins,po.ETADate)    '
		-- Filter out those SRs that has a contactlog record for HumanTouch.
		SET @sql = @sql + ' AND		CLSR.RecordID IS NULL '
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
		SET @sql = @sql + ' OR C.AssignedToUserID in (SELECT ID FROM #tmpUserDetails WHERE Name LIKE ''%Manager%'' ) 
		OR SRP.Name = ''Critical'' OR 
		NA.name IN (''Credit Card Needed'', ''Follow-Up'', ''Escalation'',''Manager Approval'')) '
		
	END
	IF (@countStatusInputManager > 0  AND @countStatusInputDispatcher >0)
	BEGIN
		SET @sql = @sql + ' OR '
	END
	
	IF EXISTS (SELECT StatusName FROM @tmpStatusInput WHERE StatusName LIKE '%Dispatcher%')
	BEGIN
		SET @sql = @sql + ' (C.AssignedToUserID in (SELECT ID FROM [USER] WHERE FirstName = ''Dispatcher'' AND LastName ='' User'' ) '
		SET @sql = @sql + ' OR C.AssignedToUserID in (SELECT ID FROM #tmpUserDetails WHERE Name LIKE ''%Dispatcher%'' ) 
		OR NA.name IN (''Dispatch'', ''ReDispatch'')) '
		
	END
	
	IF ((@countStatusInputManager > 0  OR @countStatusInputDispatcher >0) AND @countStatusInputRVTech > 0)
	BEGIN
		SET @sql = @sql + ' OR '
	END
	
	IF EXISTS (SELECT StatusName FROM @tmpStatusInput WHERE StatusName LIKE '%RVTech%')
	BEGIN
		SET @sql = @sql + ' (C.AssignedToUserID in (SELECT ID FROM [USER] WHERE FirstName = ''Tech'' AND LastName =''User'' )'
		SET @sql = @sql + ' OR C.AssignedToUserID in (SELECT ID FROM #tmpUserDetails WHERE Name LIKE ''%RVTech%'' )
		OR NA.name IN (''Tech Assist'', ''DispatchMobileMechanic'', ''FindServiceLocation'') )'
		
	END
	IF ((@countStatusInputManager > 0  OR @countStatusInputDispatcher >0 OR @countStatusInputRVTech > 0) AND @countStatusInputRepair > 0)
	BEGIN
		SET @sql = @sql + ' OR '
	END
	IF EXISTS (SELECT StatusName FROM @tmpStatusInput WHERE StatusName LIKE '%Repair%')
	BEGIN
		SET @sql = @sql + ' ((NA.name =  ''Repair Follow-up'' 
		AND SR.NextActionScheduledDate >= DATEADD(hh, -2, GetDate())))  '
		
	END
	IF (@countStatusInput > 0)
BEGIN
	SET @sql = @sql + ' ) '
END
	--IF EXISTS (SELECT StatusName FROM @tmpStatusInput WHERE StatusName LIKE '%Manager%' OR
	--														StatusName LIKE '%Dispatcher%' OR
	--														StatusName LIKE '%RVTech%'	)
	--BEGIN
	SET @sql = @sql + ' ORDER BY Priority, SR.NextActionScheduledDate, SR.CreateDate '
	--END
	
	SET @sql = @sql + ' OPTION (RECOMPILE)'
	

	IF (@isFHT = 0)
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
	@intPriorityHours, 	@serviceRequestEntityID, @fhtContactReasonID, @dispatchStatusID, @now, @StartMins, @EndMins
	END
END

print @sql
  
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
SET @sql = @sql + ' T.[ScheduledOriginal],		' --* This field is used for Queue Color
SET @sql = @sql + ' T.ProgramName, '
SET @sql = @sql + ' T.ProgramID, '
SET @sql = @sql + ' T.MemberID, '
SET @sql = @sql + ' T.StatusDateModified	'				--* Added by Lakshmi - Queue Color
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
--SET @sql = @sql + ' T.[Status] IN (	SELECT T.StatusName FROM @tmpStatusInput T )  '
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
ORDER BY T.PrioritySort,T.ScheduleDateSort, T.RequestNumber DESC

*/

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
		T.StatusDateModified				--Added by Lakshmi
FROM	#FinalResultsFormatted T
WHERE	( 
			( @MemberValue IS NULL OR  T.Member LIKE '%' + @MemberValue  + '%')
			AND
			( @AssignedToValue IS NULL OR T.AssignedTo LIKE '%' + @AssignedToValue + '%' )
			--AND
			--( @StatusValue IS NULL OR T.[Status] IN (       
			--								SELECT T.StatusName FROM @tmpStatusInput T    
			--								)  
			--							)
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
  F.StatusDateModified,				--Added by Lakshmi - Queue Color
  F.ScheduledOriginal				--Added by Lakshmi - Queue Color
  FROM #FinalResultsSorted F  
WHERE F.RowNum BETWEEN @startInd AND @endInd  
  
DROP TABLE #FinalResultsFiltered  
DROP TABLE #FinalResultsFormatted
DROP TABLE #FinalResultsSorted
--DROP TABLE #tmpStatusSummary 
DROP TABLE #tmpGetProgramsForUser 
  
  
END  
  




GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ServiceFacilitySelection_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
DROP PROCEDURE [dbo].[dms_ServiceFacilitySelection_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  
 -- EXEC [dms_ServiceFacilitySelection_get] 1, 32.780122,-96.801412,'General RV,Ford F350,Ford F450,Ford F550,Ford F650,Ford F750',300
CREATE PROCEDURE [dbo].[dms_ServiceFacilitySelection_get]  
 @programID INT	= NULL
 ,@ServiceLocationLatitude decimal(10,7)  = 0
 ,@ServiceLocationLongitude decimal(10,7)  = 0
 ,@ProductList nvarchar(4000) = NULL--comma delimited list of product names  
 ,@SearchRadiusMiles int  = NULL
AS  
BEGIN  

	--Declare
	--@programID INT =437,
	--@ServiceLocationLatitude decimal(10,7)=36.314529,
	--@ServiceLocationLongitude decimal(10,7)=-76.217567,
	--@ProductList nvarchar(4000)=N'Ford F350,Ford F450',
	--@SearchRadiusMiles int=300

	SET FMTONLY OFF;
	CREATE TABLE #tmpServiceFacilitySelection(
		[VendorID] [int] NOT NULL,
		[VendorName] [nvarchar](255) NULL,
		[VendorNumber] [nvarchar](50) NULL,
		[AdministrativeRating] [int] NULL,
		[VendorLocationID] [int] NOT NULL,
		[PhoneNumber] [nvarchar](50) NULL,
		[EnrouteMiles] [float] NULL,
		[Address1] [nvarchar](100) NULL,
		[Address2] [nvarchar](100) NULL,
		[City] [nvarchar](100) NULL,
		[PostalCode] [nvarchar](20) NULL,
		[StateProvince] [nvarchar](50) NULL,
		[Country] [nvarchar](2) NULL,
		[GeographyLocation] [geography] NULL,		
		[AllServices] [nvarchar](max) NULL,
		[Comments] [nvarchar](max) NULL,
		[FaxPhoneNumber] [nvarchar](50) NULL,
		[OfficePhoneNumber] [nvarchar](50) NULL,
		[CellPhoneNumber] [nvarchar](50) NULL,		
		[IsPreferred] BIT NULL,
		[Rating] DECIMAL(5,2) NULL
	) 


	IF @programID IS NULL
	BEGIN
		
		SELECT * FROM #tmpServiceFacilitySelection
		RETURN;
	END
	--Declare @ProductList as nvarchar(200)  
	--Declare @ServiceLocationLatitude as decimal(10,7)  
	--Declare @ServiceLocationLongitude as decimal(10,7)  
	--Declare @SearchRadiusMiles int  
	--Set @ServiceLocationLatitude = 32.780122   
	--Set @ServiceLocationLongitude = -96.801412  
	--Set @ProductList = 'Diesel, Airstream, Winnebago' --'Ford F350,Ford F450,Ford F550,Ford F650,Ford F750'  
	--Set @SearchRadiusMiles = 200  
   
	DECLARE @strProductList nvarchar(max)  
	SET @strProductList = REPLACE(@ProductList,',',''',''')  
	SET @strProductList = '''' + @strProductList + ''''  
	DECLARE @tblProductList TABLE (ProductID int)  
	DECLARE @sqlStmt nvarchar(max)  
	SET @sqlStmt = N'SELECT ID FROM dbo.Product WHERE Name IN (' + @strProductList + N')'  
   
	INSERT INTO @tblProductList (ProductID)  
	EXEC sp_executesql @sqlStmt  
   
	Declare @ServiceLocation as geography  
	Set @ServiceLocation = geography::Point(@ServiceLocationLatitude, @ServiceLocationLongitude, 4326)  
	DECLARE  @VendorEntityID int  
			,@VendorLocationEntityID int  
			,@ServiceRequestEntityID int  
			,@BusinessAddressTypeID int  
			,@DispatchPhoneTypeID int  
			,@FaxPhoneTypeID int
			,@OfficePhoneTypeID int  
			,@CellPhoneTypeID int 
			,@ContactCategoryID INT 
			,@ActiveVendorStatusID int
			,@ActiveVendorLocationStatusID int

	SET @VendorEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'Vendor')  
	SET @VendorLocationEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'VendorLocation')  
	SET @ServiceRequestEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'ServiceRequest')  
	SET @BusinessAddressTypeID = (SELECT ID FROM dbo.AddressType WHERE Name = 'Business')  

	SET @FaxPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Fax')  
	SET @OfficePhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Office')  
	SET @CellPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Cell')    
 
	SET @DispatchPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Dispatch')  
	SET @ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ServiceLocationSelection')  

	SET @ActiveVendorStatusID = (SELECT ID FROM dbo.VendorStatus WHERE Name = 'Active')    
	SET @ActiveVendorLocationStatusID = (SELECT ID FROM dbo.VendorLocationStatus WHERE Name = 'Active')    

	-- Determine the vendors/ vendorlocations for the search.
   
	Select   
			v.ID VendorID  
			--,v.Name + CASE WHEN v.DealerNumber IS NOT NULL THEN ' *** DLR#: ' + v.DealerNumber ELSE N'' END  VendorName  
			/*KB: There is no DealerNumber in Vendor table now. + CASE WHEN v.DealerNumber IS NOT NULL THEN ' *** Ford Direct Tow' ELSE N'' END */   
			--,v.Name + CASE WHEN @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Direct Tow') AND vlp.ID IS NOT NULL AND vl.DealerNumber IS NOT NULL AND vl.PartsAndAccessoryCode IS NOT NULL 
			--	THEN ' (DT)' ELSE '' END VendorName
			,v.Name + COALESCE(F.Indicators,'') AS VendorName
			,v.VendorNumber  
			,v.AdministrativeRating  
			,vl.ID VendorLocationID  
			--,vl.Sequence  
			,ph.PhoneNumber PhoneNumber  
			,ROUND(vl.GeographyLocation.STDistance(@ServiceLocation)/1609.344,1) EnrouteMiles  
			,addr.Line1 Address1  
			,addr.Line2 Address2  
			,addr.City  
			,addr.PostalCode  
			--,addr.StateProvince,  
			,SP.Name as StateProvince    
			,Cn.ISOCode as Country  
			,vl.GeographyLocation
			,vl.DispatchNote
	Into	#tmpVendors				
	From	dbo.VendorLocation vl   
	LEFT JOIN [dbo].[fnc_GetVendorIndicators]('VendorLocation') F ON vl.ID = F.RecordID
	Join	dbo.Vendor v  On vl.VendorID = v.ID  
	Join	dbo.[AddressEntity] addr On addr.EntityID = @VendorLocationEntityID and addr.RecordID = vl.ID and addr.AddressTypeID = @BusinessAddressTypeID  
	Join	dbo.Country Cn On addr.CountryID = Cn.ID    
	Join	dbo.StateProvince SP on addr.StateProvinceID = SP.ID    
	Left Outer Join dbo.[PhoneEntity] ph On ph.EntityID = @VendorLocationEntityID and ph.RecordID = vl.ID and ph.PhoneTypeID = @DispatchPhoneTypeID 
	Left Outer Join VendorLocationProduct vlp on vlp.VendorLocationID = vl.ID and vlp.ProductID = (Select ID from Product where Name = 'Ford Direct Tow') and vlp.IsActive = 1

	WHERE	v.IsActive = 1 
	AND		v.VendorStatusID = @ActiveVendorStatusID  
	and		vl.IsActive = 1 
	AND		vl.VendorLocationStatusID = @ActiveVendorLocationStatusID  
	and		vl.GeographyLocation.STDistance(@ServiceLocation) <= @SearchRadiusMiles * 1609.344  
	and		Exists (  
					Select	*  
					From	VendorLocation vl1 
					Join	VendorLocationProduct vlp on vlp.VendorLocationID = vl1.ID and vlp.IsActive = 1
					Join	VendorProduct vp on vp.VendorID = vl1.VendorID and vp.ProductID = vlp.ProductID and vp.IsActive = 1 
					Join	@tblProductList pl On vlp.ProductID = pl.ProductID  
					Where	vp.IsActive = 1 
					and		vlp.IsActive = 1
					and		vlp.VendorLocationID = vl.ID
				)  
	--NOT IN USE: Order by ROUND(vl.GeographyLocation.STDistance(@ServiceLocation)/1609.344,1)  
	AND addr.Line1 NOT LIKE '%PO BOX%'
	AND addr.line1 NOT LIKE '%POBOX%'
	AND addr.line1 NOT LIKE '%P.O. BOX%'
	AND addr.line1 NOT LIKE '%P.O.BOX%'
	AND addr.line1 NOT LIKE '%P.O BOX%'
	AND addr.line1 NOT LIKE '%P.OBOX%'
	AND addr.line1 NOT LIKE '%PO. BOX%'
	AND addr.line1 NOT LIKE '%PO.BOX%'
	AND addr.line1 NOT LIKE '%P O BOX%'
	AND addr.line1 NOT LIKE '%BOX %'
	AND addr.line1 NOT LIKE '% BOX%'
	AND addr.line1 NOT LIKE '% BOX %'
 
 
	INSERT INTO #tmpServiceFacilitySelection (
			[VendorID],
			[VendorName],
			[VendorNumber],
			[AdministrativeRating],
			[VendorLocationID],
			[PhoneNumber],
			[EnrouteMiles],
			[Address1],
			[Address2],
			[City],
			[PostalCode],
			[StateProvince],
			[Country],
			[GeographyLocation],												
			[AllServices],
			[Comments],
			[FaxPhoneNumber],
			[OfficePhoneNumber],
			[CellPhoneNumber],
			[IsPreferred],
			[Rating]
			)
	SELECT  W.VendorID  
			,W.VendorName
			,W.VendorNumber  
			,W.AdministrativeRating  
			,W.VendorLocationID  
			,W.PhoneNumber  
			,W.EnrouteMiles  
			,W.Address1  
			,W.Address2  
			,W.City  
			,W.PostalCode  
			,W.StateProvince    
			,W.Country
			,W.GeographyLocation
			,VP.AllServices
			,W.DispatchNote Comments
			,Faxph.PhoneNumber AS FaxPhoneNumber
			,Officeph.PhoneNumber AS OfficePhoneNumber
			,Cellph.PhoneNumber AS CellPhoneNumber
			,NULL
			,NULL 
   
	FROM	#tmpVendors W  
	LEFT JOIN   
	(  
		SELECT vl.VendorID,  
		vl.ID,   
		[dbo].[fnConcatenate](p.Name) AS AllServices  
		FROM VendorLocation vl  
		JOIN VendorLocationProduct vlp on vlp.VendorLocationID = vl.ID  
		JOIN Product p on p.ID = vlp.ProductID  
		WHERE vlp.IsActive = 1
		GROUP BY vl.VendorID,vl.ID  
		) VP ON W.VendorID = VP.VendorID AND W.VendorLocationID = VP.ID  
	---- Get last ContactLog result for the current sevice request for the ISP  
	--LEFT OUTER JOIN (    
	--	SELECT RecordID,  
	--	[dbo].[fnConcatenate](REPLACE([Description],',','~') +  
	--			+ ' <LF> ' + ISNULL(CreateBy,'') + ' | ' + COALESCE( CONVERT( VARCHAR(10), GETDATE(), 101) +  
	--	STUFF( RIGHT( CONVERT( VARCHAR(26), GETDATE(), 109 ), 15 ), 10, 4, ' ' ),'')) AS [Comments]            
	--	FROM Comment         
	--	WHERE EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')  
	--	AND  [Description] IS NOT NULL  
	--	GROUP BY RecordID   
	--	) CMT ON CMT.RecordID = W.VendorLocationID  

	-- Get all other phone numbers.
	LEFT OUTER JOIN  dbo.[PhoneEntity] Faxph   
						ON Faxph.EntityID = @VendorLocationEntityID AND Faxph.RecordID = W.VendorLocationID AND Faxph.PhoneTypeID = @FaxPhoneTypeID  
	-- CR : 1226 - Office phone number of the vendor and not vendor location.
	LEFT OUTER JOIN  dbo.[PhoneEntity] Officeph   
						ON Officeph.EntityID = @VendorEntityID AND Officeph.RecordID = W.VendorID AND Officeph.PhoneTypeID = @OfficePhoneTypeID

	LEFT OUTER JOIN  dbo.[PhoneEntity] Cellph   -- CR: 1226
						ON Cellph.EntityID = @VendorLocationEntityID AND Cellph.RecordID = W.VendorLocationID AND Cellph.PhoneTypeID = @CellPhoneTypeID  

	--ORDER BY ROUND(W.GeographyLocation.STDistance(@ServiceLocation)/1609.344,1)  

	-- Update the temp table with preferred and score if only the user is searching by RV House or Make attributes / product subtypes.
	DECLARE @isProgramConfiguredForPreferredProduct BIT = 0,
			@isAgentSearchingByRVOrMake BIT = 0,
			@serviceLocationPreferredProduct INT = NULL

	SELECT	@isProgramConfiguredForPreferredProduct = CAST(1 AS BIT),
			@serviceLocationPreferredProduct = CONVERT(INT,RS.Value)
	FROM	(
				SELECT	PC.Name,
						PC.Value
				FROM	[dbo].[fnc_GetProgramConfigurationForProgram](@ProgramID,'Application') P 
				JOIN	ProgramConfiguration pc ON p.ProgramConfigurationID = pc.id
			) RS
	WHERE	RS.Name = 'ServiceLocationPreferredProduct' 

	SELECT	@isAgentSearchingByRVOrMake = CAST(1 AS BIT)
	FROM	(
				SELECT	PST.Name
				FROM	[dbo].[fnSplitString](@ProductList,',') PL 
				JOIN	Product P ON P.Name = PL.item
				JOIN	ProductSubType PST ON P.ProductSubTypeID = PST.ID

			) RS
	WHERE	RS.Name IN ('RVHouse', 'Make')

	
	IF (@isProgramConfiguredForPreferredProduct = 1 AND @isAgentSearchingByRVOrMake = 1)
	BEGIN
		PRINT 'Considering ServiceLocationPreferredProduct'
		
		/* Get ISP Search Radius increment (bands) based on service and location (metro or rural) */  
		DECLARE @IsMetroLocation bit  
		DECLARE @ProductSearchRadiusMiles int  
		
		/* Determine if service location is within a Metro Market Location radius */  
		SET @IsMetroLocation = ISNULL(  
			  (SELECT TOP 1 1   
			  FROM MarketLocation ml  
			  WHERE ml.MarketLocationTypeID = (SELECT ID FROM MarketLocationType WHERE Name = 'Metro')  
			  And ml.IsActive = 'TRUE'  
			  and ml.GeographyLocation.STDistance(@ServiceLocation) <= ml.RadiusMiles * 1609.344)  
			  ,0)  
		  
		SELECT @ProductSearchRadiusMiles = CASE WHEN @IsMetroLocation = 1 THEN MetroRadius ELSE RuralRadius END   
		FROM ProductISPSelectionRadius r  
		WHERE ProductID = (SELECT ID FROM Product WHERE Name = 'CoachNet Dealer Partner')


		-- Update the preferred indicator and the rating.
		UPDATE	#tmpServiceFacilitySelection
		SET		IsPreferred = 1,
				Rating = VLP.Rating
		FROM	#tmpServiceFacilitySelection T
		JOIN	VendorLocationProduct VLP ON T.VendorLocationID = VLP.VendorLocationID 
		WHERE	VLP.ProductID =  @serviceLocationPreferredProduct

		UPDATE #tmpServiceFacilitySelection
		SET		IsPreferred = 0
		WHERE	IsPreferred IS NULL

		SELECT	TOP 50 * 
		FROM	#tmpServiceFacilitySelection T
		ORDER BY 
			CASE WHEN T.EnrouteMiles <= @ProductSearchRadiusMiles THEN T.IsPreferred ELSE 0 END DESC, 
			CASE WHEN T.EnrouteMiles <= @ProductSearchRadiusMiles THEN T.Rating ELSE NULL END DESC, 
			T.EnrouteMiles ASC

	END
	ELSE
	BEGIN
		
		PRINT 'Not Considering ServiceLocationPreferredProduct'

		SELECT	TOP 50 * 
		FROM	#tmpServiceFacilitySelection T
		ORDER BY  T.EnrouteMiles ASC		
	END
	

	DROP TABLE #tmpServiceFacilitySelection
	DROP TABLE #tmpVendors
END


GO
/****** Object:  StoredProcedure [dbo].[dms_ServiceRequestAgentTime_Update]    Script Date: 04/21/2015 14:13:56 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ServiceRequestAgentTime_Update]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_ServiceRequestAgentTime_Update]
GO

/****** Object:  StoredProcedure [dbo].[dms_ServiceRequestAgentTime_Update]    Script Date: 04/21/2015 14:13:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- EXEC [dbo].[dms_ServiceRequestAgentTime_Update]


CREATE PROCEDURE [dbo].[dms_ServiceRequestAgentTime_Update] (
	@StartDate datetime = NULL,
	@EndDate datetime = NULL
)
AS
BEGIN


	--DECLARE @StartDate Datetime = '1/16/2015'
	--DECLARE @EndDate Datetime = '1/17/2015'
	
	IF @StartDate IS NULL 
		SET @StartDate = Convert(datetime, Convert(varchar, DATEADD(dd,-30,GetDate()),101))
		
	IF @EndDate IS NULL
		SET @EndDate = Convert(datetime, Convert(varchar, DATEADD(dd,1,GetDate()),101))	
	
	DECLARE @srEntityID INT,
			@CaseEntityID INT,
			@VendorLocationEntityID INT,
			@SRCompleteID int,
			@SRCancelledID int,
			@EnterDispatchTabEventID int
	SELECT @srEntityID = ID FROM Entity WHERE Name = 'ServiceRequest'
	SELECT @CaseEntityID = ID FROM Entity WHERE Name = 'Case'
	SELECT @VendorLocationEntityID = ID FROM Entity WHERE Name = 'VendorLocation'
	SELECT @SRCompleteID = (SELECT ID FROM ServiceRequestStatus WHERE Name = 'Complete')
	SELECT @SRCancelledID = (SELECT ID FROM ServiceRequestStatus WHERE Name = 'Cancelled')
	SELECT @EnterDispatchTabEventID = (SELECT ID from [Event] where name = 'EnterDispatchTab')
	
	Declare @ContactCategoryID_VendorSelection int,
		@ContactActionID_Negotiate int,
		@ContactCategoryID_ServiceLocationSelection int
	Set @ContactCategoryID_VendorSelection = (Select ID From ContactCategory Where Name = 'VendorSelection')
	Set @ContactActionID_Negotiate = (Select ID From ContactAction Where Name = 'Negotiate')
	Set @ContactCategoryID_ServiceLocationSelection = (Select ID From ContactCategory Where Name = 'ServiceLocationSelection')

	DECLARE @TimeTypeFrontEnd int,
			@TimeTypeBackEnd int,
			@TimeTypeTech int
	SELECT @TimeTypeFrontEnd = (SELECT ID FROM TimeType WHERE NAME = 'FrontEnd')
	SELECT @TimeTypeBackEnd = (SELECT ID FROM TimeType WHERE NAME = 'BackEnd')
	SELECT @TimeTypeTech = (SELECT ID FROM TimeType WHERE NAME = 'Tech')

	DECLARE @TechLeadTimeLimitSeconds int
	SET @TechLeadTimeLimitSeconds = 43200  --(12 hrs in seconds)
	
		/* Tech Users list */
	DECLARE @TechUsers Table (Username nvarchar(50))
	INSERT INTO @TechUsers (Username) VALUES ('lwendt')
	INSERT INTO @TechUsers (Username) VALUES ('kcarichner')
	INSERT INTO @TechUsers (Username) VALUES ('kgold')
	INSERT INTO @TechUsers (Username) VALUES ('lpintado')
	INSERT INTO @TechUsers (Username) VALUES ('ilewis')
	INSERT INTO @TechUsers (Username) VALUES ('ecausley')
	INSERT INTO @TechUsers (Username) VALUES ('kgriffis')
	INSERT INTO @TechUsers (Username) VALUES ('pscammel')
	INSERT INTO @TechUsers (Username) VALUES ('jenglish')
	INSERT INTO @TechUsers (Username) VALUES ('pwilliams')
	INSERT INTO @TechUsers (Username) VALUES ('doliver')

	/*
	Select u.UserName
	From aspnet_Users u
	Join aspnet_Applications app on app.ApplicationId = u.ApplicationId
	Join aspnet_UsersInRoles uir on u.UserId = uir.UserId
	Join aspnet_Roles r on r.RoleId = uir.RoleId
	Where app.ApplicationName = 'DMS'
	and r.RoleName like '%tech%'
	*/


	IF OBJECT_ID('tempdb..#tmpClickToCallEvents') IS NOT NULL
		Drop table #tmpClickToCallEvents
	IF OBJECT_ID('tempdb..#tmpSREvents') IS NOT NULL
		Drop table #tmpSREvents
	IF OBJECT_ID('tempdb..#tmpSRTime') IS NOT NULL
		Drop table #tmpSRTime
	IF OBJECT_ID('tempdb..#tmpSRTimeDispatch') IS NOT NULL
		Drop table #tmpSRTimeDispatch
	IF OBJECT_ID('tempdb..#tmpSRTTech') IS NOT NULL
		Drop table #tmpSRTTech


	Select el.CreateDate, el.CreateBy
	Into #tmpClickToCallEvents
	From EventLog el (NOLOCK)
	Join [Event] e (NOLOCK) on e.ID = el.EventID
	where e.Name = 'ClickToCall'
	and el.CreateDate  BETWEEN @StartDate AND @EndDate

	Create Index IDX_tmpClickToCallEvents ON #tmpClickToCallEvents(CreateDate, CreateBy)

	---- Get all completed and cancelled service requests within the date range
	;WITH wSRs
	AS
	(
	SELECT     
		c.ID CaseID
		,c.ProgramID
		,sr.id ServiceRequestID
		,pc.name AS ProductCategoryName
	FROM  ServiceRequest sr (NOLOCK)
	JOIN  [Case] c (NOLOCK) ON c.ID = sr.CaseID
	JOIN  Program p (NOLOCK) ON p.ID = c.ProgramID
	JOIN  Client cl (NOLOCK) ON cl.ID = p.ClientID
	LEFT JOIN   ProductCategory pc (NOLOCK) ON pc.ID = sr.ProductCategoryID
	WHERE 
	(sr.ServiceRequestStatusID = @SRCompleteID OR sr.ServiceRequestStatusID = @SRCancelledID)
	AND sr.CreateDate BETWEEN @StartDate AND @EndDate 
	)


	---- SR Events - Attempting to get call center events only
	SELECT      W.CaseID
				,W.ProgramID
				,W.ServiceRequestID 
				,el.ID EventLogID
				,CAST(NULL as int) MatchEventLogID
				,Case WHEN el.CreateDate < '3/1/2015' AND e.Name IN ('LeaveFinishTab','SaveFinishTab') THEN 'Close'
					WHEN e.Name = 'SaveFinishTab' THEN 'Close'  
					Else 'Open' END ActionType
				--,Case WHEN e.Name = 'SaveFinishTab' THEN 'Close' Else 'Open' END ActionType
				,e.Name EventName
				,el.SessionID
				,el.CreateBy
				,el.CreateDate
				,0 IsInboundCall
				,0 IsBeginMatchedToEnd
				,CASE WHEN e.Name IN ('StartServiceRequest','OpenActiveRequest','CreateServiceRequestForInfoCall') THEN 1 ELSE 0 END IsCheckForInboundCall
				,CAST(NULL as int) InboundCallID
	INTO #tmpSREvents
	FROM  wSRs W (NOLOCK)
	JOIN  EventLogLink ell (NOLOCK) ON (ell.EntityID = @srEntityID AND ell.RecordID = W.ServiceRequestID) 
	JOIN  EventLog el (NOLOCK) ON (el.ID = ell.EventLogID) 
	JOIN [Event] e (NOLOCK) ON e.ID = el.EventID 
		AND  (e.Name IN (
			'StartServiceRequest','OpenServiceRequest','CreateServiceRequestForInfoCall' --,'ManagerOverrideOpenCase'
			,'OpenActiveRequest','OpenedLockedRequestBecauseNotOnline','SaveFinishTab')
			OR
			-- ODIS Release on 3/1 introduced SaveFinishTab which is more reliable
			(el.CreateDate < '3/1/2015' AND e.Name = 'LeaveFinishTab'))
		--,'OpenActiveRequest','OpenedLockedRequestBecauseNotOnline','LeaveFinishTab','SaveFinishTab')
	WHERE 
	(
	el.CreateBy IN (SELECT Username FROM @TechUsers)
	OR 
	NOT EXISTS (SELECT * FROM aspnet_Users au (NOLOCK)
	   JOIN aspnet_Applications a (NOLOCK) ON a.ApplicationId = au.ApplicationId AND a.ApplicationName = 'DMS'
	   JOIN aspnet_UsersInRoles uir (NOLOCK) ON uir.UserId = au.UserId
	   JOIN aspnet_Roles r (NOLOCK) ON r.RoleId = uir.RoleId
	   WHERE au.Username = el.CreateBy
	   AND r.RoleName IN (
			'VendorMgr'
			,'VendorRep'
			,'ClientRelationsMgr'
			,'ClientRelations'
			,'DispatchAdmin'
			,'ClaimsMgr'
			,'Claims'
			,'Accounting'
			,'InvoiceEntry'
			,'SysAdmin'
			,'AccountingMgr')
	  )
	)
	
	/*  TOOK OUT CASE EVENTS GOING FORWARD DUE TO CODE FIX
	---- Case Events - Attempting to get call center events only
	---- Most events are related to just the SR, but some are linked to Case
	UNION
	SELECT      W.CaseID
				,W.ProgramID
				,W.ServiceRequestID 
				,el.ID EventLogID
				,CAST(NULL as int) MatchEventLogID
				,Case WHEN e.Name IN ('LeaveFinishTab','SaveFinishTab') THEN 'Close' Else 'Open' END ActionType
				--,Case WHEN e.Name = 'SaveFinishTab' THEN 'Close' Else 'Open' END ActionType
				,e.Name EventName
				,el.SessionID
				,el.CreateBy
				,el.CreateDate
				,0 IsInboundCall
				,0 IsBeginMatchedToEnd
				,CASE WHEN e.Name IN ('StartServiceRequest','OpenActiveRequest') THEN 1 ELSE 0 END IsCheckForInboundCall
				,CAST(NULL as int) InboundCallID
	FROM  wSRs W (NOLOCK)
	JOIN  EventLogLink ell (NOLOCK) ON (ell.EntityID = @CaseEntityID AND ell.RecordID = W.CaseID)
	JOIN  EventLog el (NOLOCK) ON (el.ID = ell.EventLogID) 
	JOIN [Event] e (NOLOCK) ON e.ID = el.EventID 
		AND  (e.Name IN (
			'StartServiceRequest','OpenServiceRequest','CreateServiceRequestForInfoCall' --,'ManagerOverrideOpenCase'
			,'OpenActiveRequest','OpenedLockedRequestBecauseNotOnline','SaveFinishTab')
			OR
			-- ODIS Release on 3/1 introduced SaveFinishTab which is more reliable
			(el.CreateDate < '3/1/2015' AND e.Name = 'LeaveFinishTab'))
		--,'OpenActiveRequest','OpenedLockedRequestBecauseNotOnline','LeaveFinishTab','SaveFinishTab')
	WHERE 
	(
	el.CreateBy IN (SELECT Username FROM @TechUsers)
	OR 
	NOT EXISTS (SELECT * FROM aspnet_Users au (NOLOCK)
	   JOIN aspnet_Applications a (NOLOCK) ON a.ApplicationId = au.ApplicationId AND a.ApplicationName = 'DMS'
	   JOIN aspnet_UsersInRoles uir (NOLOCK) ON uir.UserId = au.UserId
	   JOIN aspnet_Roles r (NOLOCK) ON r.RoleId = uir.RoleId
	   WHERE au.Username = el.CreateBy
	   AND r.RoleName IN (
			'VendorMgr'
			,'VendorRep'
			,'ClientRelationsMgr'
			,'ClientRelations'
			,'DispatchAdmin'
			,'ClaimsMgr'
			,'Claims'
			,'Accounting'
			,'InvoiceEntry'
			,'SysAdmin'
			,'AccountingMgr')
	  )
	)
	*/
	
	ORDER BY ServiceRequestID, CreateDate

	CREATE NONCLUSTERED INDEX IDX_tmpSREvents ON #tmpSREvents (ServiceRequestID, ActionType, CreateDate)
	CREATE NONCLUSTERED INDEX IDX_tmpSREvents_EventLogID ON #tmpSREvents (EventLogID)


	---- Adjust the OPEN event to the related Inbound call 
	Update sre1 SET InboundCallID = InBoundCallMatch.InboundCallID
	From #tmpSREvents sre1
	Join (
		Select sre.EventLogID, MAX(ic.ID) InboundCallID
		FROM #tmpSREvents sre
		Join InboundCall ic (NOLOCK) on ic.CaseID = sre.CaseID and ic.CreateBy = sre.CreateBy and ic.CreateDate < sre.CreateDate and DATEDIFF(mi, ic.CreateDate, sre.CreateDate) < 20
		Where sre.IsCheckForInboundCall = 1
		Group By sre.EventLogID
		) InBoundCallMatch ON sre1.EventLogID = InBoundCallMatch.EventLogID

	Update sre SET CreateDate = ic.CreateDate, IsInboundCall = 1	
	From #tmpSREvents sre
	Join InboundCall ic on ic.ID = sre.InboundCallID


	---- Link Open to Close
	UPDATE sre1 
	SET MatchEventLogID = 
			(SELECT MIN(sre2.EventLogID) 
			FROM #tmpSREvents sre2 
			WHERE sre2.ServiceRequestID = sre1.ServiceRequestID 
			AND sre2.CreateBy = sre1.CreateBy
			AND sre2.EventLogID > sre1.EventLogID) 
	From #tmpSREvents sre1 
	WHERE sre1.ActionType = 'OPEN' 

	-- Set IsBeginMatchedToEnd if the identified event was a Close event
	-- Need to insure that the agent did not drop out without saving and then got back in
	UPDATE sre1
	SET IsBeginMatchedToEnd = 1
	From #tmpSREvents sre1 
	JOIN #tmpSREvents sre2 ON sre2.EventLogID = sre1.MatchEventLogID AND sre2.ActionType = 'CLOSE'
	WHERE sre1.ActionType = 'OPEN'
	AND sre1.MatchEventLogID IS NOT NULL

	-- If the matched event for the same person was not a close, then clear the match and let the next step simply pair the event with the next access (below)
	UPDATE sre1
	SET MatchEventLogID = NULL, IsBeginMatchedToEnd = 0
	From #tmpSREvents sre1 
	JOIN #tmpSREvents sre2 ON sre2.EventLogID = sre1.MatchEventLogID AND sre2.ActionType <> 'CLOSE'
	WHERE sre1.ActionType = 'OPEN'
	AND sre1.MatchEventLogID IS NOT NULL


	---- Flatten out events and add TimeType based on distinct user list
	SELECT 
		sre1.ProgramID
		,sre1.ServiceRequestID
		,sre1.EventLogID BeginEventLogID
		,sre1.CreateDate BeginDate
		,sre1.CreateBy BeginUser
		,sre2.EventLogID EndEventLogID
		,sre2.CreateDate EndDate
		,sre2.CreateBy EndUser
		,CASE WHEN sre2.CreateDate IS NOT NULL THEN DATEDIFF(ss, sre1.CreateDate, sre2.CreateDate) ELSE 0 END EventSeconds
		,NULL as TechLeadTimeSeconds
		,Case WHEN sre1.CreateBy IN (SELECT Username FROM @TechUsers) THEN @TimeTypeTech ELSE @TimeTypeBackEnd END TimeTypeID
		,sre1.IsInboundCall
		--,Case WHEN sre1.CreateBy IN (SELECT Username FROM @TechUsers) THEN 1 ELSE 0 END IsTech
		,sre1.IsBeginMatchedToEnd
		,NULL as IssuedPOCount
		,NULL as DispatchISPCallCount
		,NULL as ServiceFacilityCallCount
		,NULL as  ClickToCallCount
	Into #tmpSRTime
	From #tmpSREvents sre1
	Left Outer Join #tmpSREvents sre2 on sre1.MatchEventLogID = sre2.EventLogID
	Where sre1.ActionType = 'OPEN'
	
	CREATE NONCLUSTERED INDEX IDX_tmpSRTime_SRID ON #tmpSRTime (ServiceRequestID)

		
	--update all the first entries for each SR as FrontEnd time type
	--make sure that first entry is in the temp table, may not be if adding to prior days entries
	UPDATE SRT
	SET SRT.TimeTypeID = @TimeTypeFrontEnd
	FROM #tmpSRTime SRT
	JOIN ServiceRequest SR (nolock) on SR.ID = SRT.ServiceRequestID
	WHERE 
	SRT.BeginDate <= SR.CreateDate
	AND SRT.BeginEventLogID = (SELECT Top 1 (BeginEventlogID) FROM #tmpSRTime tSRT where tSRT.ServiceRequestID = SRT.ServiceRequestID Order by BeginDate, EndDate)

	
	--Search for first time entry for each SR.  Within that timeframe search for 'EnterDispatchTab' event
	--and create new record to split the time between FrontEnd and Dispatch. If 'EnterDispatchTab' event not
	--found then don't need to split
	SELECT SRT.ProgramID
	,SRT.ServiceRequestID
		,SRT.BeginEventLogID 
		,SRT.BeginDate 
		,SRT.BeginUser 
		,SRT.EndEventLogID
		,SRT.EndDate
		,SRT.EndUser
		,EL.ID DispatchEventLogID
		,EL.CreateDate DispatchDate
		,EL.CreateBy DispatchUser
		,SRT.EventSeconds
		,NULL as TechLeadTimeSeconds
		,SRT.TimeTypeID
		,SRT.IsInboundCall
		,SRT.IsBeginMatchedToEnd
		,NULL as IssuedPOCount
		,NULL as DispatchISPCallCount
		,NULL as ServiceFacilityCallCount
		,NULL as  ClickToCallCount
	INTO #tmpSRTimeDispatch 
	FROM #tmpSRTime SRT 
	JOIN EventLogLink ell (NOLOCK) ON (ell.EntityID = @srEntityID AND ell.RecordID = SRT.ServiceRequestID) 
	JOIN  EventLog el (NOLOCK) ON 
	(el.ID = ell.EventLogID AND el.CreateBy = SRT.BeginUser AND el.createdate between SRT.BeginDate and SRT.EndDate
	and el.createdate = (SELECT Min(CreateDate) from EventLog el2 (NOLOCK)
	JOIN EventLogLink ell2 (NOLOCK) on ell2.EntityID = @srEntityID AND ell2.RecordID = SRT.ServiceREquestID 
	WHERE el2.ID = ell2.EventLogID and el2.CreateBy = SRT.BeginUser AND el.createdate between SRT.BeginDate and SRT.EndDate
	AND el2.EventID = @EnterDispatchTabEventID))
	JOIN [Event] e (NOLOCK) ON E.ID = el.EventID and el.EventID = @EnterDispatchTabEventID
	WHERE SRT.TimeTypeID = @TimeTypeFrontEnd 
	AND SRT.EndEventLogID <> EL.ID
	
	--Update first record of SR to end when EnterDispatchTab Event occurred; recalc EventSeconds
	UPDATE SRT
	SET SRT.EndEventLogID = SRTD.DispatchEventLogID,
	SRT.EndUser = SRTD.DispatchUser,
	SRT.EndDate = SRTD.DispatchDate,
	SRT.EventSeconds = CASE WHEN SRTD.DispatchDate IS NOT NULL THEN DATEDIFF(ss, SRT.BeginDate, SRTD.DispatchDate) ELSE 0 END 
	FROM #tmpSRTime SRT
	JOIN #tmpSRTimeDispatch SRTD ON SRTD.ServiceRequestID = SRT.ServiceRequestID AND SRTD.BeginEventLogID = SRT.BeginEventLogID
	
	
    --Insert new record for each dispatch event found, set type to BackEnd, calc EventSeconds
    INSERT INTO #tmpSRTime
    SELECT 
		SRTD.ProgramID
		,SRTD.ServiceRequestID
		,SRTD.DispatchEventLogID BeginEventLogID
		,SRTD.DispatchDate BeginDate
		,SRTD.DispatchUser BeginUser
		,SRTD.EndEventLogID
		,SRTD.EndDate
		,SRTD.EndUser
		,CASE WHEN SRTD.EndDate IS NOT NULL THEN DATEDIFF(ss, SRTD.DispatchDate, SRTD.EndDate) ELSE 0 END EventSeconds
		,NULL as TechLeadTimeSeconds
		,@TimeTypeBackEnd TimeTypeID
		,SRTD.IsInboundCall
		,SRTD.IsBeginMatchedToEnd
		,NULL as IssuedPOCount
		,NULL as DispatchISPCallCount
		,NULL as ServiceFacilityCallCount
		,NULL as  ClickToCallCount
	From #tmpSRTimeDispatch SRTD
		
	
	--Find every timetype = 'Tech', find prior record and calc difference between prior event end time
	--and tech record begin time.  If greater than 12 hours then TechLeadTimeSeconds = 0.  If prior record 
	--timetype = 'Tech' then TechLeadTimeSeconds = 0, else calc TechLeadTimeSeconds
	SELECT 
		SRT.ServiceRequestID ServiceRequestID
		,SRT.BeginEventLogID BeginEventLogID
		,SRT.BeginDate BeginDate
		,SRT.BeginUser BeginUser
		,SRT.EndEventLogID EndEventLogID
		,SRT.EndDate EndDate
		,SRT.EndUser EndUser
		,(SELECT MAX(SRTemp.EndDate) FROM #tmpSRTime SRTemp WHERE
			SRTemp.ServiceRequestID = SRT.ServiceRequestID 
			AND SRTemp.EndDate is not null 
			AND SRTemp.EndDate <= SRT.BeginDate
			AND SRTemp.TimeTypeID <> @TimeTypeTech) as PriorEventEndDate
	INTO #tmpSRTTech
	FROM #tmpSRTime SRT
	WHERE SRT.TimeTypeID = @TimeTypeTech
	AND SRT.EndDate is not null
	AND SRT.TechLeadTimeSeconds is null
	AND (SELECT Top 1 TimeTypeID FROM #tmpSRTime SRTemp WHERE
			SRTemp.ServiceRequestID = SRT.ServiceRequestID 
			AND SRTemp.EndDate is not null 
			AND SRTemp.EndDate <= SRT.BeginDate
			ORDER BY SRTemp.EndDate DESC) <> @TimeTypeTech
	
	
	
	UPDATE SRT
	SET TechLeadTimeSeconds = CASE WHEN SRTTech.PriorEventEndDate is not null AND (DATEDIFF(ss, ISNULL(SRTTech.PriorEventEndDate,'1/1/1900'), SRTTech.BeginDate)) < @TechLeadTimeLimitSeconds 
								THEN DATEDIFF(ss, SRTTech.PriorEventEndDate, SRTTech.BeginDate) 
								ELSE 0 END
	FROM #tmpSRTime SRT
	JOIN #tmpSRTTech SRTTech on SRTTech.ServiceRequestID = SRT.ServiceRequestID and SRTTech.BeginEventLogID = SRT.BeginEventLogID
	
	
	
	--Update counts
	UPDATE SRT
	SET IssuedPOCount = (SELECT Count(*) 
			FROM PurchaseOrder PO (NOLOCK)
			WHERE PO.ServiceRequestID = SRT.ServiceRequestID 
			AND PO.IsActive = 1 
			AND PO.PurchaseOrderNumber IS NOT NULL 
			AND PO.CreateDate between SRT.BeginDate and SRT.EndDate
			) 
		, DispatchISPCallCount = (Select Count(*) 
			From (
				Select sr.ID ServiceRequestID, cll_ISP.RecordID, cl.CreateBy, MAX(cl.CreateDate) CreateDate
				From ServiceRequest SR (NOLOCK) 
				Join ContactLogLink cll (NOLOCK) on cll.EntityID = @srEntityID and cll.RecordID = sr.ID 
				Join ContactLog cl (NOLOCK) on cl.ID = cll.ContactLogID
				Left Outer Join ContactLogLink cll_ISP (NOLOCK) on cll_ISP.ContactLogID =cl.ID and cll_ISP.EntityID = @VendorLocationEntityID 
				Join ContactLogAction cla (NOLOCK) on cla.ContactLogID = cl.ID
				Join ContactAction ca (NOLOCK) on ca.ID = cla.ContactActionID
				Join ContactCategory cc (NOLOCK) on cc.ID = cl.ContactCategoryID
				Join ContactType ct (NOLOCK) on ct.ID = cl.ContactTypeID
				Where sr.ID = SRT.ServiceRequestID
				and cl.ContactCategoryID = @ContactCategoryID_VendorSelection
				and cla.ContactActionID <> @ContactActionID_Negotiate
				Group By sr.ID, cll_ISP.RecordID, cl.CreateBy
				--Order by sr.ID, cl.ID
				) X
			Where X.ServiceRequestID = SRT.ServiceRequestID AND
				X.CreateDate BETWEEN SRT.BeginDate and SRT.EndDate
			) 
		,ServiceFacilityCallCount = (Select Count(*) 
			From (
				Select sr.ID ServiceRequestID, cll_ISP.RecordID, cl.CreateBy, MAX(cl.CreateDate) CreateDate
				From ServiceRequest SR (NOLOCK) 
				Join ContactLogLink cll (NOLOCK) on cll.EntityID = @srEntityID and cll.RecordID = sr.ID 
				Join ContactLog cl	(NOLOCK) on cl.ID = cll.ContactLogID
				Left Outer Join ContactLogLink cll_ISP (NOLOCK) on cll_ISP.ContactLogID =cl.ID and cll_ISP.EntityID = @VendorLocationEntityID 
				Join ContactLogAction cla (NOLOCK) on cla.ContactLogID = cl.ID
				Join ContactAction ca (NOLOCK) on ca.ID = cla.ContactActionID
				Join ContactCategory cc (NOLOCK) on cc.ID = cl.ContactCategoryID
				Join ContactType ct (NOLOCK) on ct.ID = cl.ContactTypeID
				Where sr.ID = SRT.ServiceRequestID
				and cl.ContactCategoryID = @ContactCategoryID_ServiceLocationSelection
				and cll_ISP.RecordID IS NOT NULL
				Group By sr.ID, cll_ISP.RecordID, cl.CreateBy
				--Order by sr.ID, cl.ID
				) X
			Where X.ServiceRequestID = SRT.ServiceRequestID AND
				X.CreateDate BETWEEN SRT.BeginDate and SRT.EndDate
			)
		,ClicktoCallcount = ISNULL((Select Count(*) ClickToCallCount
			From #tmpClickToCallEvents ctc 
			Where ctc.CreateBy = SRT.BeginUser and ctc.CreateDate between SRT.BeginDate and SRT.EndDate
			),0) 
		FROM #tmpSRTime SRT
	
	
		
	INSERT INTO dbo.ServiceRequestAgentTime
		([ProgramID]
		,[ServiceRequestID]
		,[BeginEventLogID]
		,[BeginDate]
		,[BeginUser]
		,[EndEventLogID]
		,[EndDate]
		,[EndUser]
		,[EventSeconds]
		,[TechLeadTimeSeconds]
		,[TimeTypeID]
		,[IsInboundCall]
		,[IsBeginMatchedToEnd]
		,[IssuedPOCount]
		,[DispatchISPCallCount]
		,[ServiceFacilityCallCount]
		,[ClickToCallCount])
	Select 
		[ProgramID]
		,[ServiceRequestID]
		,[BeginEventLogID]
		,[BeginDate]
		,[BeginUser]
		,[EndEventLogID]
		,[EndDate]
		,[EndUser]
		,[EventSeconds]
		,[TechLeadTimeSeconds]
		,[TimeTypeID]
		,[IsInboundCall]
		,[IsBeginMatchedToEnd]
		,[IssuedPOCount]
		,[DispatchISPCallCount]
		,[ServiceFacilityCallCount]
		,[ClickToCallCount]
	From #tmpSRTime tmpSrt
	WHERE NOT EXISTS (
		SELECT *
		FROM ServiceRequestAgentTime srt
		WHERE srt.ServiceRequestID = tmpSrt.ServiceRequestID
		AND srt.BeginEventLogID = tmpSrt.BeginEventLogID
		)
	ORDER BY tmpSRT.BeginDate
		
	--Select 
		--[ProgramID] = tmpSRT.ProgramID
		--,[ServiceRequestID] = tmpSrt.ServiceRequestID,
	UPDATE srt SET
		[BeginEventLogID] = tmpSrt.BeginEventLogID
		,[BeginDate] = tmpSrt.BeginDate
		,[BeginUser] = tmpSrt.BeginUser
		,[EndEventLogID] = tmpSrt.EndEventLogID
		,[EndDate] = tmpSrt.EndDate
		,[EndUser] = tmpSrt.EndUser
		,[EventSeconds] = tmpSrt.EventSeconds
		,[IsInboundCall] = tmpSrt.IsInboundCall
		,[TechLeadTimeSeconds] = tmpSrt.TechLeadTimeSeconds
		,[TimeTypeID] = tmpSrt.TimeTypeID
		,[IsBeginMatchedToEnd] = tmpSrt.IsBeginMatchedToEnd
		,[IssuedPOCount] = tmpSrt.IssuedPOCount
		,[DispatchISPCallCount] = tmpSrt.DispatchISPCallCount
		,[ServiceFacilityCallCount] = tmpSrt.ServiceFacilityCallCount
		,[ClickToCallCount] = tmpSrt.ClickToCallCount
	FROM #tmpSRTime tmpSRT
	JOIN ServiceRequestAgentTime srt on srt.ServiceRequestID = tmpSrt.ServiceRequestID AND srt.BeginEventLogID = tmpSrt.BeginEventLogID
		and srt.AccountingInvoiceBatchID IS NULL

END

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
--EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = '<ROW><Filter IDType="Contact Phone Number" IDValue="2485250690"/></ROW>',@userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
-- EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = '<ROW><Filter IDType="Contact Phone Number" IDValue="8285635847" NameType="" NameValue="" LastName="" FilterType = "StartsWith" FromDate = "" ToDate = "" Preset ="" Clients ="1" Programs ="" ServiceRequestStatuses = "" ServiceTypes ="" IsGOA = "" IsRedispatched = "" IsPossibleTow ="" VehicleType ="1" VehicleYear ="2012" VehicleMake = "" VehicleModel = "" PaymentByCheque = "" PaymentByCard = "" MemberPaid ="" POStatuses =""/></ROW>', @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
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
	

	DECLARE @totalRows INT = 0,
		@IDType NVARCHAR(255) ,
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
		,@strPOStatuses NVARCHAR(MAX)
		,@strPrograms NVARCHAR(MAX)
		,@strServiceRequestStatuses NVARCHAR(MAX)
		,@strServiceTypes NVARCHAR(MAX)

	-- Extract some of the values into separate tables for ease of processing.
	SELECT	@strClients = Clients,
			@strPOStatuses = POStatuses,
			@strPrograms = Programs,
			@strServiceRequestStatuses = ServiceRequestStatuses,
			@strServiceTypes = ServiceTypes			
	FROM	@tmpWhereClause
	
	-- Clients
	DECLARE @tmpClients IntTableType
	INSERT INTO @tmpClients
	SELECT item FROM fnSplitString(@strClients,',')
	
	-- Programs
	DECLARE @tmpPrograms IntTableType
	INSERT INTO @tmpPrograms
	SELECT item FROM fnSplitString(@strPrograms,',')
	
	-- POStatuses
	DECLARE @tmpPOStatuses IntTableType
	INSERT INTO @tmpPOStatuses
	SELECT item FROM fnSplitString(@strPOStatuses,',')
	
	-- Service request statuses
	DECLARE @tmpServiceRequestStatuses IntTableType
	INSERT INTO @tmpServiceRequestStatuses
	SELECT item FROM fnSplitString(@strServiceRequestStatuses,',')
	
	-- Service types
	DECLARE @tmpServiceTypes IntTableType
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
	

	DECLARE @sql nvarchar(max) = ''
	
	SET @sql =        'SELECT'
	SET @sql = @sql + '  SR.ID AS RequestNumber'	
	SET @sql = @sql + ' ,SR.CaseID AS [Case]'	
	SET @sql = @sql + ' ,P.ProgramID'    
	SET @sql = @sql + ' ,P.ProgramName Program'   
	SET @sql = @sql + ' ,CL.id AS ClientID'  
	SET @sql = @sql + ' ,CL.Name Client'  
	SET @sql = @sql + ' ,M.FirstName'
	SET @sql = @sql + ' ,M.LastName'
	SET @sql = @sql + ' ,M.MiddleName'
	SET @sql = @sql + ' ,M.Suffix'
	SET @sql = @sql + ' ,M.Prefix'     
	SET @sql = @sql + ' ,CASE WHEN MS.MembershipNumber IS NULL THEN ''Ref#: '' + MS.ClientReferenceNUmber ELSE MS.MembershipNumber END AS MemberNumber'
	SET @sql = @sql + ' ,SR.CreateDate'	
	SET @sql = @sql + ' ,PO.CreateBy'	
	SET @sql = @sql + ' ,PO.ModifyBy'	
	SET @sql = @sql + ' ,SR.CreateBy'	
	SET @sql = @sql + ' ,SR.ModifyBy'	
	SET @sql = @sql + ' ,C.VehicleVIN AS VIN'	
	SET @sql = @sql + ' ,VT.ID AS VehicleTypeID'	
	SET @sql = @sql + ' ,VT.Name AS VehicleType'	
	SET @sql = @sql + ' ,PC.ID AS ServiceTypeID'	
	SET @sql = @sql + ' ,PC.Name AS ServiceType'	
	SET @sql = @sql + ' ,SRS.ID AS StatusID'	
	SET @sql = @sql + ' ,CASE ISNULL(SR.IsRedispatched,0) WHEN 1 THEN SRS.Name + CHAR(94) ELSE SRS.Name END AS [Status]'
	SET @sql = @sql + ' ,SR.ServiceRequestPriorityID AS [PriorityID]'
	SET @sql = @sql + ' ,SRP.Name AS [Priority]'
	SET @sql = @sql + ' ,V.Name AS [ISPName]'
	SET @sql = @sql + ' ,V.VendorNumber'
	SET @sql = @sql + ' ,PO.PurchaseOrderNumber AS [PONumber]'
	SET @sql = @sql + ' ,POS.ID AS PurchaseOrderStatusID'
	SET @sql = @sql + ' ,POS.Name AS PurchaseOrderStatus'
	SET @sql = @sql + ' ,PO.PurchaseOrderAmount'
	SET @sql = @sql + ' ,C.AssignedToUserID'
	SET @sql = @sql + ' ,SR.NextActionAssignedToUserID'		
	SET @sql = @sql + ' ,PO.IsGOA'
	SET @sql = @sql + ' ,SR.IsRedispatched'
	SET @sql = @sql + ' ,SR.IsPossibleTow'
	SET @sql = @sql + ' ,C.VehicleYear'
	SET @sql = @sql + ' ,C.VehicleMake'
	SET @sql = @sql + ' ,C.VehicleMakeOther'
	SET @sql = @sql + ' ,C.VehicleModel'
	SET @sql = @sql + ' ,C.VehicleModelOther'
	SET @sql = @sql + ' ,PO.IsPayByCompanyCreditCard'
	SET @sql = @sql + ' ,PO.CreateDate'		

	SET @sql = @sql + ' FROM ServiceRequest SR WITH (NOLOCK)'
	SET @sql = @sql + ' JOIN [Case] C WITH (NOLOCK) on C.ID = SR.CaseID'
	SET @sql = @sql + ' JOIN dbo.fnc_GetProgramsForUser(@userID) P ON C.ProgramID = P.ProgramID'
	SET @sql = @sql + ' JOIN Client CL WITH (NOLOCK) ON P.ClientID = CL.ID'
	SET @sql = @sql + ' LEFT OUTER JOIN Member M WITH (NOLOCK) ON C.MemberID = M.ID'
	SET @sql = @sql + ' JOIN ServiceRequestStatus SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID'
	SET @sql = @sql + ' LEFT OUTER JOIN ServiceRequestPriority SRP WITH (NOLOCK) ON SR.ServiceRequestPriorityID = SRP.ID '
	SET @sql = @sql + ' LEFT OUTER JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID'
	SET @sql = @sql + ' LEFT OUTER JOIN ProductCategory PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID'
	SET @sql = @sql + ' LEFT OUTER JOIN VehicleType VT WITH (NOLOCK) ON VT.ID = C.VehicleTypeID'
	SET @sql = @sql + ' LEFT OUTER JOIN PurchaseOrder PO WITH (NOLOCK) ON PO.ServiceRequestID = SR.ID AND PO.IsActive = 1'
					--+ CASE WHEN @IDType = 'Purchase Order' THEN ' AND ' + @IDValue ELSE '' END
	SET @sql = @sql + ' LEFT OUTER JOIN PurchaseOrderStatus POS WITH (NOLOCK) ON PO.PurchaseOrderStatusID = POS.ID'
	SET @sql = @sql + ' LEFT OUTER JOIN NextAction NA WITH (NOLOCK) ON SR.NextActionID=NA.ID'
	SET @sql = @sql + ' LEFT OUTER JOIN VendorLocation VL WITH (NOLOCK) ON PO.VendorLocationID = VL.ID'
	SET @sql = @sql + ' LEFT OUTER JOIN Vendor V WITH (NOLOCK) ON VL.VendorID = V.ID'
	
	SET @sql = @sql + ' WHERE  1=1'
	
	---- ID Value
	IF @IDType = 'Member' 
	SET @sql = @sql + ' AND (MS.MembershipNumber LIKE char(37) + @IDValue + char(37) OR MS.AltMembershipNumber LIKE  char(37) + @IDValue + char(37))'  
	
	IF @IDType = 'Service Request' 
	SET @sql = @sql + ' AND SR.ID = @IDValue'  

	IF @IDType = 'Purchase Order' 
	SET @sql = @sql + ' AND PO.PurchaseOrderNumber = @IDValue'  

	IF @IDType = 'ISP' 
	SET @sql = @sql + ' AND V.VendorNumber = @IDValue'  

	IF @IDType = 'VIN' 
	SET @sql = @sql + ' AND C.VehicleVIN = @IDValue'  

	
	--Name: ISP
	IF @NameType = 'ISP' AND @NameValue IS NOT NULL
		BEGIN
		IF @FilterType IN ('Starts With', 'Contains', 'Ends With') 
			SET @sql = @sql + ' AND V.Name LIKE'
							+ CASE WHEN @FilterType IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @NameValue'
							+ CASE WHEN @FilterType IN ('Starts With', 'Contains') THEN ' +CHAR(37)' ELSE '' END
		ELSE
			---- Is Equal To
			SET @sql = @sql + ' AND V.Name = @NameValue'  
		END

	
	----Name: Member
	IF @NameType = 'Member' AND (@NameValue IS NOT NULL OR @LastName IS NOT NULL)
		BEGIN
		IF @FilterType IN ('Starts With', 'Contains', 'Ends With') 
			BEGIN
			SET @sql = @sql + ' AND M.FirstName LIKE'
							+ CASE WHEN @FilterType IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @NameValue'
							+ CASE WHEN @FilterType IN ('Starts With', 'Contains') THEN ' +CHAR(37)' ELSE '' END
			SET @sql = @sql + ' AND M.LastName LIKE'
							+ CASE WHEN @FilterType IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @LastName'
							+ CASE WHEN @FilterType IN ('Starts With', 'Contains') THEN ' +CHAR(37)' ELSE '' END
			END	
		ELSE
			---- Is Equal To
			BEGIN
			IF @NameValue IS NOT NULL
				SET @sql = @sql + ' AND M.FirstName = @NameValue'  
			IF @LastName IS NOT NULL
				SET @sql = @sql + ' AND M.LastName = @LastName'	
			END
		END

		
	----Name: User
	IF @NameType = 'User' AND @NameValue IS NOT NULL
		BEGIN
		IF @FilterType IN ('Starts With', 'Contains', 'Ends With') 
			SET @sql = @sql + ' AND (SR.CreateBy LIKE'
							+ CASE WHEN @FilterType IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @NameValue'
							+ CASE WHEN @FilterType IN ('Starts With', 'Contains') THEN ' +CHAR(37)' ELSE '' END

							+ ' OR SR.ModifyBy LIKE'
							+ CASE WHEN @FilterType IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @NameValue'
							+ CASE WHEN @FilterType IN ('Starts With', 'Contains') THEN ' +CHAR(37)' ELSE '' END

							+ ' OR PO.ModifyBy LIKE'
							+ CASE WHEN @FilterType IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @NameValue'
							+ CASE WHEN @FilterType IN ('Starts With', 'Contains') THEN ' +CHAR(37)' ELSE '' END

							+ ' OR PO.ModifyBy LIKE'
							+ CASE WHEN @FilterType IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @NameValue'
							+ CASE WHEN @FilterType IN ('Starts With', 'Contains') THEN ' +CHAR(37)' ELSE '' END
							+ ' )'
		ELSE
			---- Is Equal To
			SET @sql = @sql + ' AND (SR.CreateBy = @NameValue'
							+ '   OR SR.ModifyBy = @NameValue'
							+ '   OR PO.CreateBy = @NameValue'
							+ '   OR PO.ModifyBy = @NameValue)'  
		END

		
	---- Date Range
	IF @Preset IS NOT NULL
	SET @sql = @sql + CASE @Preset WHEN 'Last 30 days' THEN ' AND DATEDIFF(M,SR.CreateDate,GETDATE()) <= 1'
								   WHEN 'Last 90 days' THEN ' AND DATEDIFF(M,SR.CreateDate,GETDATE()) <= 3'
								   ELSE ' AND DATEDIFF(WK,SR.CreateDate,GETDATE()) <= 1'
					  END
					  
	IF @Preset IS NULL AND @FromDate IS NOT NULL
	SET @sql = @sql + ' AND SR.CreateDate >= @FromDate'  

	IF @Preset IS NULL AND @ToDate IS NOT NULL
	SET @sql = @sql + ' AND SR.CreateDate <= @ToDate'	

	
	---- Clients
	IF ISNULL(@strClients,'') <> ''
	SET @sql = @sql + ' AND CL.ID IN (SELECT ID FROM @tmpClients)'


	---- Programs
	IF ISNULL(@strPrograms,'') <> ''
	SET @sql = @sql + ' AND P.ProgramID IN (SELECT ID FROM @tmpPrograms)'


	---- SR Statuses
	IF ISNULL(@strServiceRequestStatuses,'') <> ''
	SET @sql = @sql + ' AND SRS.ID IN (SELECT ID FROM @tmpServiceRequestStatuses)'


	---- Service types
	IF ISNULL(@strServiceTypes,'') <> ''
	SET @sql = @sql + ' AND PC.ID IN (SELECT ID FROM @tmpServiceTypes)'


	---- PurchaseOrder Statuses
	IF ISNULL(@strPOStatuses,'') <> ''
	SET @sql = @sql + ' AND PO.PurchaseOrderStatusID IN (SELECT ID FROM @tmpPOStatuses)'


	--- Special Flags
	IF @IsGOA IS NOT NULL
	SET @sql = @sql + ' AND PO.IsGOA = @IsGOA'

	IF @IsPossibleTow IS NOT NULL
	SET @sql = @sql + ' AND SR.IsPossibleTow = @IsPossibleTow'

	IF @IsRedispatched IS NOT NULL
	SET @sql = @sql + ' AND SR.IsRedispatched = @IsRedispatched'


	----Vehicle
	IF @VehicleType IS NOT NULL
	SET @sql = @sql + ' AND C.VehicleTypeID = @VehicleType'
	
	IF @VehicleYear IS NOT NULL
	SET @sql = @sql + ' AND C.VehicleYear = @VehicleYear'
	
	IF @VehicleMake IS NOT NULL
	SET @sql = @sql + ' AND (C.VehicleMake = @VehicleMake OR (@VehicleMake = ''Other'' AND C.VehicleMake = ''Other'' AND C.VehicleMakeOther = @VehicleMakeOther ))'
	
	IF @VehicleModel IS NOT NULL
	SET @sql = @sql + ' AND (C.VehicleModel = @VehicleModel OR (@VehicleModel = ''Other'' AND C.VehicleModel = ''Other'' AND C.VehicleModelOther = @VehicleModelOther ))'


	----Payment Types
	IF ISNULL(@PaymentByCheque,0) = 1 
	SET @sql = @sql + ' AND PO.IsPayByCompanyCreditCard = 0 AND PO.PurchaseOrderAmount > 0 '
	
	IF ISNULL(@PaymentByCard,0) = 1 
	SET @sql = @sql + ' AND PO.IsPayByCompanyCreditCard = 1 AND PO.PurchaseOrderAmount > 0 '

	IF ISNULL(@MemberPaid,0) = 1 
	SET @sql = @sql + ' AND PO.MemberServiceAmount = PO.PurchaseOrderAmount AND PO.PurchaseOrderAmount > 0 '


	SET @sql = @sql + ' OPTION (RECOMPILE)'
			
	---- DEBUG
	--SELECT @sql		
			

	INSERT INTO #Filtered
	EXEC sp_executesql @sql, 
		N'@UserID Uniqueidentifier, @IDType nvarchar(50), @IDValue nvarchar(50), 
		  @NameType nvarchar(50), @NameValue nvarchar(50), @LastName nvarchar(50), @FilterType nvarchar(50), 
		  @FromDate datetime, @ToDate datetime, @Preset nvarchar(50),
		  @IsGoa bit, @IsRedispatched BIT, @IsPossibleTow BIT, 
		  @VehicleType INT, @VehicleYear INT, 
		  @VehicleMake NVARCHAR(255), @VehicleMakeOther NVARCHAR(255), 
		  @VehicleModel NVARCHAR(255), @VehicleModelOther NVARCHAR(255), 
		  @PaymentByCheque BIT, @PaymentByCard BIT, @MemberPaid BIT, 
		  @tmpClients intTableType READONLY, @tmpPrograms intTableType READONLY, @tmpPOStatuses intTableType READONLY, 
		  @tmpServiceRequestStatuses intTableType READONLY, @tmpServiceTypes intTableType READONLY '
		, @UserID, @IDType, @IDValue, 
		  @NameType, @NameValue, @LastName, @FilterType, 
		  @FromDate, @ToDate, @Preset,
		  @IsGoa, @IsRedispatched, @IsPossibleTow, 
		  @VehicleType, @VehicleYear, 
		  @VehicleMake, @VehicleMakeOther, 
		  @VehicleModel, @VehicleModelOther, 
		  @PaymentByCheque, @PaymentByCard, @MemberPaid, 
		  @tmpClients, @tmpPrograms, @tmpPOStatuses, 
		  @tmpServiceRequestStatuses, @tmpServiceTypes	


	---- DEBUG:
	--SELECT 'Filtered', * FROM #Filtered
	
	---- Format the data [ Member name, vehiclemake, model, etc]

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
	
	DROP TABLE #Filtered
	DROP TABLE #Formatted
	DROP TABLE #Sorted

END


GO



GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_service_limits_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_service_limits_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

-- EXEC [dbo].[dms_service_limits_get] @programID = 3,@vehicleCategoryID = 1

 CREATE PROCEDURE [dbo].[dms_service_limits_get]( 

   @programID INT = NULL,

   @vehicleCategoryID INT = NULL 

 ) 

 AS 

 BEGIN 
 SET FMTONLY OFF
 

 DECLARE @tmpPrograms TABLE

(

	LevelID INT IDENTITY(1,1),

	ProgramID INT

)



INSERT INTO @tmpPrograms

SELECT ProgramID FROM fnc_GetProgramsandParents (@programID)


;With PPAll
As
(
	SELECT	DISTINCT TP.LevelID, 
	pc.Name AS ProductCategoryName,
	ROW_NUMBER() OVER (PARTITION BY pc.Name ORDER BY TP.LevelID ASC) AS RowNum,
			pp.ServiceCoverageLimit,
			P.Name AS ProductName

	FROM	ProgramProduct pp WITH (NOLOCK)

	LEFT JOIN Program pr WITH (NOLOCK) on pr.ID = pp.ProgramID

	LEFT JOIN Product p WITH (NOLOCK) on p.ID = pp.ProductID 

	LEFT JOIN ProductCategory pc WITH (NOLOCK) on pc.ID = p.ProductCategoryID	

	JOIN @tmpPrograms TP ON pr.ID = TP.ProgramID

	AND	 (p.VehicleCategoryID IS NULL OR	p.VehicleCategoryID = @vehicleCategoryID)

	WHERE P.ProductSubTypeID = (select ID from ProductSubType where name = 'PrimaryService') -- CR: 1052

	AND		(PC.Name <> 'Lockout' OR (PC.Name = 'Lockout' AND P.Name = 'Basic Lockout')) -- If is locksmith, take the basic lockout and exclude the other.

	GROUP BY TP.LevelID,pc.Name, pp.ServiceCoverageLimit,P.Name

	)
SELECT ProductCategoryName,ServiceCoverageLimit FROM PPAll WHERE RowNum = 1


 END

 


GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_SR_Has_AccountingInvoiceBatchID_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_SR_Has_AccountingInvoiceBatchID_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- [dms_SR_Has_AccountingInvoiceBatchID_Get] 1544
 CREATE PROCEDURE [dbo].[dms_SR_Has_AccountingInvoiceBatchID_Get]( 
   @serviceRequestId Int = 1   
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
DECLARE @hasAccountingInvoiceBatchID as BIT = 0

IF( (SELECT ISNULL(AccountingInvoiceBatchID,0) from ServiceRequest WITH (NOLOCK) where ID=@serviceRequestId) <> 0)
BEGIN
	SET @hasAccountingInvoiceBatchID = 1
END

IF (@hasAccountingInvoiceBatchID = 0)
BEGIN
	IF((SELECT MAX(ISNULL(PO.AccountingInvoiceBatchID,0)) FROM PurchaseOrder  PO WITH (NOLOCK)  where PO.ServiceRequestID = @serviceRequestId) <> 0)
	BEGIN
		SET @hasAccountingInvoiceBatchID = 1
	END
END

SELECT @hasAccountingInvoiceBatchID AS SRHasAccountingInvoiceBatchID
END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_VendorPortal_Services_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VendorPortal_Services_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 --EXEC dms_VendorPortal_Services_List 
CREATE PROCEDURE [dbo].[dms_VendorPortal_Services_List]
AS
BEGIN

	SELECT 
			 CASE	WHEN vc.name is NULL THEN 2 
					ELSE 1 
			 END AS SortOrder
			,CASE	WHEN vc.name is NULL THEN 'Other' 
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
	--AND p.Name Not in ('Concierge', 'Information', 'Tech')
	--AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee')
	 AND ISNULL(P.ShowOnVendorPortal,0) = 1

	UNION
	SELECT 
			3 AS SortOrder
			,'Additional' AS ServiceGroup
			,p.Name AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory
	FROM	Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
	LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('AdditionalService')
	--AND p.Name Not in ('Concierge', 'Information', 'Tech')
	--AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials')
	 AND ISNULL(P.ShowOnVendorPortal,0) = 1
	ORDER BY SortOrder, VehicleCategorySequence, ProductCategory


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
 WHERE id = object_id(N'[dbo].[dms_Vendor_Invoices_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Invoices_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_Vendor_Invoices_List_Get] @whereClauseXML = '<ROW><Filter IDType="Vendor" IDValue="TX100532" NameValue="" NameOperator="" InvoiceStatuses="" POStatuses="" FromDate="" ToDate="" ExportType="" ToBePaidFromDate="" ToBePaidToDate=""/></ROW>'  
CREATE PROCEDURE [dbo].[dms_Vendor_Invoices_List_Get](     
   @whereClauseXML XML = NULL     
 , @startInd Int = 1     
 , @endInd BIGINT = 5000     
 , @pageSize int = 10000      
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
NameOperator="-1"    
 ></Filter></ROW>'    
END    
    
    
CREATE TABLE #tmpForWhereClause    
(    
 IDType NVARCHAR(50) NULL,    
 IDValue NVARCHAR(100) NULL,    
 NameOperator INT NULL,    
 NameValue NVARCHAR(100) NULL,    
 InvoiceStatuses NVARCHAR(MAX) NULL,    
 POStatuses NVARCHAR(MAX) NULL,    
 PayStatusCodes NVARCHAR(MAX) NULL, 
 ExceptionTypes NVARCHAR(MAX) NULL, 
 FromDate DATETIME NULL,    
 ToDate DATETIME NULL,    
 ToBePaidFromDate DATETIME NULL,    
 ToBePaidToDate DATETIME NULL,
 ExportType INT NULL ,  
 filterValue nvarchar(100) NULL      
)    
    
 CREATE TABLE #FinalResults_Filtered(      
 ID int  NULL ,    
 VendorNumber nvarchar(100)  NULL ,    
 VendorName nvarchar(100) NULL,    
 PurchaseOrderNumber nvarchar(100)  NULL ,    
 POStatus nvarchar(100)  NULL ,    
 IssueDate datetime  NULL ,    
 PurchaseOrderAmount money  NULL ,    
 InvoiceNumber nvarchar(100)  NULL ,    
 ReceivedDate datetime  NULL ,    
 InvoiceDate datetime  NULL ,    
 InvoiceAmount money  NULL ,    
 InvoiceStatus nvarchar(100)  NULL ,    
 ToBePaidDate datetime  NULL ,    
 ExportDate datetime  NULL ,    
 PaymentDate datetime  NULL ,    
 PaymentAmount money  NULL ,    
 PaymentType nvarchar(100)  NULL ,    
 PaymentNumber nvarchar(100)  NULL ,    
 CheckClearedDate datetime  NULL ,    
 VendorID int NULL  ,  
 VendorInvoiceException nvarchar(max) NULL ,
RecieveMethod  nvarchar(225) NULL
)     
    
 CREATE TABLE #FinalResults_Sorted (     
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
 ID int  NULL ,    
 VendorNumber nvarchar(100)  NULL ,    
 VendorName nvarchar(100) NULL,    
 PurchaseOrderNumber nvarchar(100)  NULL ,    
 POStatus nvarchar(100)  NULL ,    
 IssueDate datetime  NULL ,    
 PurchaseOrderAmount money  NULL ,    
 InvoiceNumber nvarchar(100)  NULL ,    
 ReceivedDate datetime  NULL ,    
 InvoiceDate datetime  NULL ,    
 InvoiceAmount money  NULL ,    
 InvoiceStatus nvarchar(100)  NULL ,    
 ToBePaidDate datetime  NULL ,    
 ExportDate datetime  NULL ,    
 PaymentDate datetime  NULL ,    
 PaymentAmount money  NULL ,    
 PaymentType nvarchar(100)  NULL ,    
 PaymentNumber nvarchar(100)  NULL ,    
 CheckClearedDate datetime  NULL ,    
 VendorID int NULL ,  
 VendorInvoiceException nvarchar(max) NULL  ,
RecieveMethod  nvarchar(225) NULL
)     

DECLARE @receivedCount BIGINT      
DECLARE @readyForPaymentCount BIGINT      
DECLARE @exceptionCount BIGINT    
DECLARE @paidCount BIGINT    
DECLARE @cancelledCount BIGINT      
SET @receivedCount = 0      
SET @readyForPaymentCount = 0      
SET @exceptionCount = 0    
SET @paidCount = 0    
SET @cancelledCount = 0    
  
INSERT INTO #tmpForWhereClause    
SELECT      
 T.c.value('@IDType','NVARCHAR(50)') ,    
 T.c.value('@IDValue','NVARCHAR(100)'),     
 ISNULL(T.c.value('@NameOperator','INT'),-1),    
 T.c.value('@NameValue','nvarchar(100)') ,    
 T.c.value('@InvoiceStatuses','nvarchar(MAX)') ,    
 T.c.value('@POStatuses','nvarchar(MAX)') ,    
 T.c.value('@PayStatusCodes','nvarchar(MAX)') ,  
 T.c.value('@ExceptionTypes','nvarchar(MAX)') , 
 T.c.value('@FromDate','datetime') ,    
 T.c.value('@ToDate','datetime') ,
 T.c.value('@ToBePaidFromDate','datetime') ,    
 T.c.value('@ToBePaidToDate','datetime') ,    
 T.c.value('@ExportType','INT') ,  
 T.c.value('@filterValue','NVARCHAR(100)') 

FROM @whereClauseXML.nodes('/ROW/Filter') T(c)    
    
    
DECLARE @idType NVARCHAR(50) = NULL,    
  @idValue NVARCHAR(100) = NULL,    
  @nameOperator INT = NULL,    
  @nameValue NVARCHAR(100) = NULL,    
  @invoiceStatuses NVARCHAR(MAX) = NULL,    
  @payStatusCodes NVARCHAR(MAX) = NULL,
  @exceptionTypes NVARCHAR(MAX) = NULL,
  @poStatuses NVARCHAR(MAX) = NULL,    
  @fromDate DATETIME = NULL,    
  @toDate DATETIME = NULL, 
  @toBePaidFromDate DATETIME = NULL,    
  @toBePaidToDate DATETIME = NULL,
  @exportType INT = NULL  ,  
  @filterValue NVARCHAR(100) = NULL  
      
SELECT @idType = IDType,    
  @idValue = IDValue,    
  @nameOperator = NameOperator,    
  @nameValue = NameValue,    
  @invoiceStatuses = InvoiceStatuses,    
  @poStatuses = POStatuses,    
  @payStatusCodes = PayStatusCodes,
  @exceptionTypes = ExceptionTypes,
  @fromDate = FromDate,    
  @toDate = CASE WHEN ToDate = '1900-01-01' THEN NULL ELSE ToDate END,  
  @toBePaidFromDate = ToBePaidFromDate,
  @toBePaidToDate = CASE WHEN ToBePaidToDate = '1900-01-01' THEN NULL ELSE ToBePaidToDate END,  
  @exportType = ExportType ,   
  @filterValue=filterValue  
FROM #tmpForWhereClause    

INSERT INTO #FinalResults_Filtered    
SELECT VI.ID    
  , V.VendorNumber    
  , V.Name AS VendorName    
  , PO.PurchaseOrderNumber    
  , POS.Name AS POStatus    
  , PO.IssueDate    
  , PO.PurchaseOrderAmount    
  , VI.InvoiceNumber    
  , VI.ReceivedDate    
  , VI.InvoiceDate    
  , VI.InvoiceAmount    
  , VIS.Name AS InvoiceStatus    
  , VI.ToBePaidDate    
  , VI.ExportDate    
  , VI.PaymentDate    
  , VI.PaymentAmount    
  --, PT.Name AS PaymentType    
  , CASE    
   WHEN VIS.Name = 'Paid' THEN PT.NAME    
   WHEN ISNULL(VIS.Name,'') <> 'Paid' AND ISNULL(ACH.ID,'') <> '' AND ISNULL(V.IsLevyActive,'') <> 1 THEN 'ACH'    
   ELSE 'Check'    
    END AS PaymentType    
  , VI.PaymentNumber     
  , VI.CheckClearedDate    
  , V.ID AS VendorID    
  , NULL AS VendorInvoiceException
  --, VIE.[Description] AS VendorInvoiceException
  , CM.Name  
FROM VendorInvoice VI    
JOIN VendorInvoiceStatus VIS ON VIS.ID = VI.VendorInvoiceStatusID    
LEFT JOIN PaymentType PT ON PT.ID = VI.PaymentTypeID    
JOIN Vendor V ON V.ID = VI.VendorID    
JOIN PurchaseOrder PO ON PO.ID = VI.PurchaseOrderID    
JOIN PurchaseOrderStatus POS ON POS.ID = PO.PurchaseOrderStatusID    
LEFT JOIN VendorACH ACH ON ACH.VendorID = V.ID AND ACH.ACHStatusID = (SELECT ID FROM ACHStatus WHERE Name = 'Valid') AND ISNULL(ACH.IsActive,0) = 1
LEFT JOIN VendorInvoiceException VIE ON VIE.VendorInvoiceID = VI.ID  
LEFT JOIN Batch B ON VI.ExportBatchID = B.ID
LEFT JOIN ContactMethod CM ON CM.ID=VI.ReceiveContactMethodID
WHERE VI.IsActive = 1    
AND  ( ISNULL(@idType,'') = ''    
   OR    
   (@idType = 'Vendor' AND V.VendorNumber = @idValue )    
   OR    
   (@idType = 'PO' AND PO.PurchaseOrderNumber = @idValue )    
   OR    
   (@idType = 'Invoice' AND VI.InvoiceNumber = @idValue )    
  )    
AND  (    
   ( @nameOperator = -1 )     
    OR     
   ( @nameOperator = 0 AND ISNULL(@nameValue,'') = '' )     
    OR     
   ( @nameOperator = 1 AND @nameValue IS NOT NULL )     
    OR     
   ( @nameOperator = 2 AND V.Name = @nameValue )     
    OR     
   ( @nameOperator = 3 AND V.Name <> @nameValue )     
    OR     
   ( @nameOperator = 4 AND V.Name LIKE @nameValue + '%')     
    OR     
   ( @nameOperator = 5 AND V.Name LIKE '%' + @nameValue )     
    OR     
   ( @nameOperator = 6 AND V.Name LIKE '%' + @nameValue + '%')     
  )  
AND  (    
   ( ISNULL(@invoiceStatuses,'') = '')    
   OR    
   ( VI.VendorInvoiceStatusID IN (    
           SELECT item FROM fnSplitString(@invoiceStatuses,',')    
           ))    
  )    
AND  (    
   ( ISNULL(@poStatuses,'') = '')    
   OR    
   ( PO.PurchaseOrderStatusID IN (    
           SELECT item FROM fnSplitString(@poStatuses,',')    
           ))    
  )    
  AND  (    
   ( ISNULL(@payStatusCodes,'') = '')    
   OR    
   ( PO.PayStatusCodeID IN (    
           SELECT item FROM fnSplitString(@payStatusCodes,',')    
           ))    
  ) 
   AND  (    
   ( ISNULL(@exceptionTypes,'') = '')    
   OR    
   ( VIE.[Description] IN (    
           SELECT item FROM fnSplitString(@exceptionTypes,',')    
           ))    
  ) 
AND  (    
       
   ( @fromDate IS NULL OR (@fromDate IS NOT NULL AND VI.InvoiceDate >= @fromDate))    
    AND    
   ( @toDate IS NULL OR (@toDate IS NOT NULL AND VI.InvoiceDate < DATEADD(DD,1,@toDate)))    
  )
  AND  (    
       
   ( @toBePaidFromDate IS NULL OR (@toBePaidFromDate IS NOT NULL AND VI.ToBePaidDate >= @toBePaidFromDate))    
    AND    
   ( @toBePaidToDate IS NULL OR (@toBePaidToDate IS NOT NULL AND VI.ToBePaidDate < DATEADD(DD,1,@toBePaidToDate)))    
  )    
AND  (    
   ( @filterValue IS NULL OR @filterValue = '')    
   OR    
   ( VIS.Name IN (    
           SELECT item FROM fnSplitString(@filterValue,',')    
           ))    
  )   
 AND ( ISNULL(@exportType,0) = 0 OR B.ID = @exportType )
    
--------------------- BEGIN -----------------------------    
----   Create a temp variable or a CTE with the actual SQL search query ----------    
----   and use that CTE in the place of <table> in the following SQL statements ---    
--------------------- END -----------------------------    

;WITH wExceptions
AS
(
      SELECT      V.VendorInvoiceID,
                  [dbo].[fnConcatenate](V.Description) AS ExceptionMessages
      FROM  VendorInvoiceException V
      JOIN  #FinalResults_Filtered F ON V.VendorInvoiceID = F.ID
      GROUP BY V.VendorInvoiceID
                  
)
--SELECT * FROM wExceptions

INSERT INTO #FinalResults_Sorted    
SELECT     
 T.ID,    
 T.VendorNumber,    
 T.VendorName,    
 T.PurchaseOrderNumber,    
 T.POStatus,    
 T.IssueDate,    
 T.PurchaseOrderAmount,    
 T.InvoiceNumber,    
 T.ReceivedDate,    
 T.InvoiceDate,    
 T.InvoiceAmount,    
 T.InvoiceStatus,    
 T.ToBePaidDate,    
 T.ExportDate,    
 T.PaymentDate,    
 T.PaymentAmount,    
 T.PaymentType,    
 T.PaymentNumber,    
 T.CheckClearedDate,    
 T.VendorID ,  
 W.ExceptionMessages AS VendorInvoiceException,
T.RecieveMethod
FROM #FinalResults_Filtered T    
LEFT OUTER JOIN wExceptions W ON T.ID = W.VendorInvoiceID

 ORDER BY     
  CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'    
  THEN T.ID END ASC,     
  CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'    
  THEN T.ID END DESC ,    
    
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'    
  THEN T.VendorNumber END ASC,     
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'    
  THEN T.VendorNumber END DESC ,    
     
 CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'ASC'    
  THEN T.VendorName END ASC,     
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'DESC'    
  THEN T.VendorName END DESC ,    
    
  CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'ASC'    
  THEN T.PurchaseOrderNumber END ASC,     
  CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'DESC'    
  THEN T.PurchaseOrderNumber END DESC ,    
    
  CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'ASC'    
  THEN T.POStatus END ASC,     
  CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'DESC'    
  THEN T.POStatus END DESC ,    
    
  CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'ASC'    
  THEN T.IssueDate END ASC,     
  CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'DESC'    
  THEN T.IssueDate END DESC ,    
    
  CASE WHEN @sortColumn = 'PurchaseOrderAmount' AND @sortOrder = 'ASC'    
  THEN T.PurchaseOrderAmount END ASC,     
  CASE WHEN @sortColumn = 'PurchaseOrderAmount' AND @sortOrder = 'DESC'    
  THEN T.PurchaseOrderAmount END DESC ,    
    
  CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'    
  THEN T.InvoiceNumber END ASC,     
  CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'    
  THEN T.InvoiceNumber END DESC ,    
    
  CASE WHEN @sortColumn = 'ReceivedDate' AND @sortOrder = 'ASC'    
  THEN T.ReceivedDate END ASC,     
  CASE WHEN @sortColumn = 'ReceivedDate' AND @sortOrder = 'DESC'    
  THEN T.ReceivedDate END DESC ,    
    
  CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'ASC'    
  THEN T.InvoiceDate END ASC,     
  CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'DESC'    
  THEN T.InvoiceDate END DESC ,    
    
  CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'    
  THEN T.InvoiceAmount END ASC,     
  CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'    
  THEN T.InvoiceAmount END DESC ,    
    
  CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'ASC'    
  THEN T.InvoiceStatus END ASC,     
  CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'DESC'    
  THEN T.InvoiceStatus END DESC ,    
    
  CASE WHEN @sortColumn = 'ToBePaidDate' AND @sortOrder = 'ASC'    
  THEN T.ToBePaidDate END ASC,     
  CASE WHEN @sortColumn = 'ToBePaidDate' AND @sortOrder = 'DESC'    
  THEN T.ToBePaidDate END DESC ,    
    
  CASE WHEN @sortColumn = 'ExportDate' AND @sortOrder = 'ASC'    
  THEN T.ExportDate END ASC,     
  CASE WHEN @sortColumn = 'ExportDate' AND @sortOrder = 'DESC'    
  THEN T.ExportDate END DESC ,    
    
  CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'ASC'    
  THEN T.PaymentDate END ASC,     
  CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'DESC'    
  THEN T.PaymentDate END DESC ,    
    
  CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'    
  THEN T.PaymentAmount END ASC,     
  CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'    
  THEN T.PaymentAmount END DESC ,    
    
  CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'ASC'    
  THEN T.PaymentType END ASC,     
  CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'DESC'    
  THEN T.PaymentType END DESC ,    
    
  CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'ASC'    
  THEN T.PaymentNumber END ASC,     
  CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'DESC'    
  THEN T.PaymentNumber END DESC ,    
    
  CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'ASC'    
  THEN T.CheckClearedDate END ASC,     
  CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'DESC'    
  THEN T.CheckClearedDate END DESC ,    
      
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'ASC'    
  THEN T.ID END ASC,     
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'DESC'    
  THEN T.ID END DESC     ,    
      
  CASE WHEN @sortColumn = 'RecieveMethod' AND @sortOrder = 'ASC'    
  THEN T.RecieveMethod END ASC,     
  CASE WHEN @sortColumn = 'RecieveMethod' AND @sortOrder = 'DESC'    
  THEN T.RecieveMethod END DESC     
 
    
SELECT @receivedCount = COUNT(*) FROM #FinalResults_Sorted WHERE InvoiceStatus = 'Received'      
SELECT @readyForPaymentCount = COUNT(*) FROM #FinalResults_Sorted WHERE InvoiceStatus = 'ReadyForPayment'      
SELECT @exceptionCount = COUNT(*) FROM #FinalResults_Sorted WHERE InvoiceStatus= 'Exception'    
SELECT @paidCount = COUNT(*) FROM #FinalResults_Sorted WHERE InvoiceStatus= 'Paid'    
SELECT @cancelledCount = COUNT(*) FROM #FinalResults_Sorted WHERE InvoiceStatus= 'Cancelled'    
    
DECLARE @count INT       
SET @count = 0       
SELECT @count = MAX(RowNum) FROM #FinalResults_Sorted    
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
    
SELECT   
   @count AS TotalRows  
 , *  
 , @receivedCount AS RecivedCount   
 , @readyForPaymentCount AS ReadyForPaymentCount  
 , @exceptionCount AS ExceptionCount  
 , @paidCount AS PaidCount  
 , @cancelledCount AS CancelledCount  
FROM #FinalResults_Sorted WHERE RowNum BETWEEN @startInd AND @endInd    
    
DROP TABLE #tmpForWhereClause    
DROP TABLE #FinalResults_Filtered    
DROP TABLE #FinalResults_Sorted  

    
END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Location_Services_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Location_Services_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 --EXEC dms_Vendor_Location_Services_List_Get @VendorID=1, @VendorLocationID=1
CREATE PROCEDURE [dms_Vendor_Location_Services_List_Get](
	@VendorID INT = NULL
 ,	@VendorLocationID INT = NULL
 )
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
	IsAvailByVendor bit default 0 ,
	IsAvailByVendorLocation bit default 0
) 

INSERT INTO @FinalResults (SortOrder, ServiceGroup,ServiceName,ProductID,VehicleCategorySequence,ProductCategory)
	SELECT 
			 CASE	WHEN vc.name is NULL THEN 2 
					ELSE 1 
			 END AS SortOrder
			,CASE	WHEN vc.name is NULL THEN 'Other' 
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
	--AND p.Name Not in ('Concierge', 'Information', 'Tech')
	--AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee')
	AND ISNULL(P.ShowOnVendorMaintenance,0) = 1

	UNION
	SELECT 
			3 AS SortOrder
			,'Additional' AS ServiceGroup
			,p.Name AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory
	FROM	Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
	LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('AdditionalService')
	--AND p.Name Not in ('Concierge', 'Information', 'Tech')
	--AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials')
	AND ISNULL(P.ShowOnVendorMaintenance,0) = 1
	
	UNION ALL
	
	SELECT 
			 4 AS SortOrder
			,'Repair' AS ServiceGroup
			, p.Name AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory
	FROM	Product p
	Join	ProductCategory pc on p.productCategoryid = pc.id
	Join	ProductType pt on p.ProductTypeID = pt.ID
	Join	ProductSubType pst on p.ProductSubTypeID = pst.id
	Left Outer Join VehicleCategory vc on p.VehicleCategoryID = vc.ID
	Left Outer Join VehicleType vt on p.VehicleTypeID = vt.ID
	Where	pt.Name = 'Attribute'
	and		pc.Name = 'Repair'
	and		pst.Name NOT IN ('Client')	
	AND ISNULL(P.ShowOnVendorMaintenance,0) = 1
	ORDER BY SortOrder, VehicleCategorySequence, ProductCategory
	
	UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
	LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
	WHERE VP.VendorID=@VendorID

	UPDATE @FinalResults SET IsAvailByVendorLocation = 1 FROM  @FinalResults T
	LEFT JOIN VendorLocationProduct VLP ON VLP.ProductID = T.ProductID
	WHERE VLP.VendorLocationID=@VendorLocationID

	SELECT *  FROM @FinalResults WHERE IsAvailByVendor=1 OR IsAvailByVendorLocation = 1
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
-- EXEC   [dbo].[dms_Vendor_Portal_Invoice_List_Get] @vendorID = 66905, @whereClauseXML = '<ROW><Filter PurchaseOrderNumberValue="7770395"/></ROW>' 
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
	SubmitMethod nvarchar(100) NULL,
	DocumentID INT NULL,
	DocumentName nvarchar(255) NULL
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
	SubmitMethod nvarchar(100) NULL,
	DocumentID INT NULL,
	DocumentName nvarchar(255) NULL
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
		, D.ID AS DocumentID
		, D.Name AS DocumentName
FROM	PurchaseOrder PO
JOIN	PurchaseOrderStatus POS ON POS.ID = PO.PurchaseOrderStatusID
JOIN	Product P ON P.ID = PO.ProductID
JOIN	VendorLocation VL ON VL.ID = PO.VendorLocationID 
JOIN	Vendor V ON V.ID = VL.VendorID 
LEFT JOIN VendorInvoice VI ON VI.PurchaseOrderID = PO.ID 
LEFT JOIN VendorInvoiceStatus VIS ON VIS.ID = VI.VendorInvoiceStatusID
LEFT JOIN PaymentType PT ON PT.ID = VI.PaymentTypeID
LEFT JOIN ContactMethod CM ON CM.ID = VI.ReceiveContactMethodID
LEFT JOIN Document D ON D.RecordID = VI.ID AND D.EntityID = (Select ID from Entity where Name='VendorInvoice') AND D.ISActive = 1
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
	T.SubmitMethod,
	T.DocumentID,
	T.DocumentName
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
	 THEN T.SubmitMethod END DESC,
	 
	 CASE WHEN @sortColumn = 'DocumentID' AND @sortOrder = 'ASC'
	 THEN T.DocumentID END ASC, 
	 CASE WHEN @sortColumn = 'DocumentID' AND @sortOrder = 'DESC'
	 THEN T.DocumentID END DESC,
	 
	 CASE WHEN @sortColumn = 'DocumentName' AND @sortOrder = 'ASC'
	 THEN T.DocumentName END ASC, 
	 CASE WHEN @sortColumn = 'DocumentName' AND @sortOrder = 'DESC'
	 THEN T.DocumentName END DESC

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
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Portal_Location_Services_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Portal_Location_Services_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 --EXEC dms_Vendor_Portal_Location_Services_List_Get @VendorID=1, @VendorLocationID=1
CREATE PROCEDURE [dms_Vendor_Portal_Location_Services_List_Get](
	@VendorID INT = NULL
 ,	@VendorLocationID INT = NULL
 )
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
	IsAvailByVendor bit default 0 ,
	IsAvailByVendorLocation bit default 0
) 

INSERT INTO @FinalResults (SortOrder, ServiceGroup,ServiceName,ProductID,VehicleCategorySequence,ProductCategory)
	SELECT 
			 CASE	WHEN vc.name is NULL THEN 2 
					ELSE 1 
			 END AS SortOrder
			,CASE	WHEN vc.name is NULL THEN 'Other' 
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
	--AND p.Name Not in ('Concierge', 'Information', 'Tech')
	--AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee','Tow - LD - White Glove')
	AND ISNULL(P.ShowOnVendorPortal,0) = 1

	UNION
	SELECT 
			3 AS SortOrder
			,'Additional' AS ServiceGroup
			,p.Name AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory
	FROM	Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
	LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('AdditionalService')
	--AND p.Name Not in ('Concierge', 'Information', 'Tech')
	--AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials')
	AND ISNULL(P.ShowOnVendorPortal,0) = 1
	
	UNION ALL
	
	SELECT 
			 4 AS SortOrder
			,'Repair' AS ServiceGroup
			, p.Name AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory
	FROM	Product p
	Join	ProductCategory pc on p.productCategoryid = pc.id
	Join	ProductType pt on p.ProductTypeID = pt.ID
	Join	ProductSubType pst on p.ProductSubTypeID = pst.id
	Left Outer Join VehicleCategory vc on p.VehicleCategoryID = vc.ID
	Left Outer Join VehicleType vt on p.VehicleTypeID = vt.ID
	Where	pt.Name = 'Attribute'
	and		pc.Name = 'Repair'
	and		pst.Name NOT IN ('Client')	
	AND ISNULL(P.ShowOnVendorPortal,0) = 1
	ORDER BY SortOrder, VehicleCategorySequence, ProductCategory
	
	UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
	LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
	WHERE VP.VendorID=@VendorID

	UPDATE @FinalResults SET IsAvailByVendorLocation = 1 FROM  @FinalResults T
	LEFT JOIN VendorLocationProduct VLP ON VLP.ProductID = T.ProductID
	WHERE VLP.VendorLocationID=@VendorLocationID

	SELECT *  FROM @FinalResults WHERE IsAvailByVendor=1 OR IsAvailByVendorLocation = 1
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
      --AND p.Name Not in ('Concierge', 'Information', 'Tech')
      --AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee','Tow - LD - Lamborghini','Tow - LD - White Glove')
      AND ISNULL(P.ShowOnVendorPortal,0) = 1

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
      --AND p.Name Not in ('Concierge', 'Information', 'Tech')
      --AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials','Diagnostics','Storage Fee - Auto','Storage Fee - RV') 
	  AND ISNULL(P.ShowOnVendorPortal,0) = 1
      
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
      AND ISNULL(P.ShowOnVendorPortal,0) = 1
      --and pst.Name NOT IN ('Client')
      ORDER BY SortOrder, VehicleCategorySequence, ProductCategory
      

UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
WHERE VP.VendorID=@VendorID
      
SELECT * FROM @FinalResults

END
GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Services_List_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Services_List_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 --EXEC dms_Vendor_Services_List_Get @VendorID=1
CREATE PROCEDURE [dbo].[dms_Vendor_Services_List_Get] @VendorID INT
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
      --AND p.Name Not in ('Concierge', 'Information', 'Tech')
      --AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee')
      AND ISNULL(P.ShowOnVendorMaintenance,0) = 1

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
      --AND p.Name Not in ('Concierge', 'Information', 'Tech')
      --AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials') 
	  AND ISNULL(P.ShowOnVendorMaintenance,0) = 1
      
      UNION
      SELECT 
                  4 AS SortOrder
                  ,'ISP Selection' AS ServiceGroup
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
      WHERE pt.Name = 'Attribute'
      AND pst.Name = 'Ranking'
      AND pc.Name = 'ISPSelection'
      AND ISNULL(P.ShowOnVendorMaintenance,0) = 1
      
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
      AND ISNULL(P.ShowOnVendorMaintenance,0) = 1
      --and pst.Name NOT IN ('Client')
      ORDER BY SortOrder, VehicleCategorySequence, ProductCategory
      

UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
WHERE VP.VendorID=@VendorID
      
SELECT * FROM @FinalResults

END
GO

GO
 /****** Object:  UserDefinedFunction [dbo].[fnc_IsValidVINCheckDigit]    Script Date: 27/10/2015 20:28:06 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_IsValidVINCheckDigit]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_IsValidVINCheckDigit]
GO
/****** Object:  UserDefinedFunction [dbo].[fnc_IsValidVINCheckDigit]    Script Date: 12/10/2012 20:03:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- SELECT dbo.fnc_IsValidVINCheckDigit('3FRNF6HP8CV192324')  
  
CREATE FUNCTION [dbo].[fnc_IsValidVINCheckDigit]   
(  
 @VIN nvarchar(17)  
)  
RETURNS bit  
AS  
BEGIN  
 --SET NOCOUNT ON  
  
 --DECLARE @VIN nvarchar(17)  
 --SET @VIN = '3FRNF6HP8CV192324'  
   
 -- Fail any VIN that contains non-alphanumeric characters   
 IF PATINDEX('%[^a-zA-Z0-9]%' , @VIN) > 0 OR LEN(@VIN) <> 17  
  RETURN 0  
  
 DECLARE @VINSum int, @Position int, @PositionValue int, @VINCheckDigit int, @IsValid bit  
  
 DECLARE @VinAlphaNumber TABLE (VIN_Alpha char(1), VIN_AlphaNumber int)  
 DECLARE @VINPositionWeight TABLE (VINPosition int, PositionWeight int)  
  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('A',1)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('B',2)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('C',3)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('D',4)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('E',5)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('F',6)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('G',7)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('H',8)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('J',1)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('K',2)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('L',3)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('M',4)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('N',5)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('P',7)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('R',9)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('S',2)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('T',3)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('U',4)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('V',5)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('W',6)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('X',7)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('Y',8)  
 INSERT INTO @VinAlphaNumber (VIN_Alpha, VIN_AlphaNumber) VALUES ('Z',9)  
  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (1, 8)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (2, 7)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (3, 6)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (4, 5)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (5, 4)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (6, 3)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (7, 2)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (8, 10)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (10, 9)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (11, 8)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (12, 7)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (13, 6)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (14, 5)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (15, 4)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (16, 3)  
 INSERT INTO @VINPositionWeight (VINPosition, PositionWeight) VALUES (17, 2)  
  
 SET @Position = 1  
 SET @VINSum = 0  
  
 WHILE @Position <= 17  
 BEGIN  
    
  IF @Position <> 9  
  BEGIN  
   SET @PositionValue = CASE WHEN ISNUMERIC(SUBSTRING(@VIN, @Position, 1)) = 1 THEN CONVERT(int, SUBSTRING(@VIN, @Position, 1)) ELSE (SELECT VIN_AlphaNumber FROM @VinAlphaNumber WHERE VIN_Alpha = SUBSTRING(@VIN, @Position, 1)) END  
   SET @VinSum = @VINSum + ((SELECT PositionWeight FROM @VINPositionWeight WHERE VINPosition = @Position) * @PositionValue)  
  END  
    
  SET @Position = @Position + 1  
    
 END  
  
 SET @VINCheckDigit = @VINSum % 11  
   
 SET @IsValid = 0  
 IF SUBSTRING(@VIN, 9, 1) = CASE WHEN @VINCheckDigit = 10 THEN 'X' ELSE CONVERT(char(1),@VINCheckDigit) END    
  SET @IsValid = 1  
  
 RETURN @IsValid  
  
END
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnXMLEncode]') 
AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
 DROP FUNCTION [dbo].[fnXMLEncode]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--SELECT [dbo].[fnXMLEncode]('K & N')
 CREATE FUNCTION [dbo].[fnXMLEncode] 
 (
	@str NVARCHAR(MAX)
 )
 RETURNS NVARCHAR(MAX)
 AS
 BEGIN

	DECLARE @encodedString NVARCHAR(MAX) = ''

	IF LEN(LTRIM(RTRIM(@str))) = 0
		RETURN @encodedString 

	SET @encodedString =  (SELECT  @str FOR XML PATH(''))

	RETURN @encodedString

 END



GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_EventDetailForFinish_Get]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_EventDetailForFinish_Get]
	GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SELECT * FROM dbo.fn_EventDetailForFinish_Get(2,2)
CREATE function fn_EventDetailForFinish_Get(@eventDetail NVARCHAR(MAX), @eventName NVARCHAR(100)) RETURNS NVARCHAR(MAX)
AS
BEGIN
	--DECLARE @eventDetail XML = '<EventDetail><ServiceRequestID>400316</ServiceRequestID><ContactCategory>2</ContactCategory><ServiceRequestStatus>Complete</ServiceRequestStatus><NextAction>ManualClosedLoop</NextAction><ScheduledDate>2015-08-29</ScheduledDate><AssignedTo>1</AssignedTo><Priority>High</Priority><ClosedLoopStatus></ClosedLoopStatus><NextSend></NextSend><Comments>Comments by Phani for testing</Comments><CreateBy>afreestone</CreateBy><ModifyBy>sysadmin</ModifyBy></EventDetail>',

	DECLARE @eventDetailXML xml
	DECLARE	@result NVARCHAR(MAX) = NULL


	SELECT @eventDetailXML = 
	
	CASE WHEN CHARINDEX('</Comments>',@eventDetail) - CHARINDEX('<Comments>', @eventDetail)  - Len('</Comments>') <= 0
		THEN @eventDetail
		ELSE
	SUBSTRING(@eventDetail,0,CHARINDEX('<Comments>',@eventDetail) + LEN('<Comments>'))
								+
							[dbo].[fnXMLEncode](SUBSTRING(@eventDetail, CHARINDEX('<Comments>', @eventDetail) + 10
														, CHARINDEX('</Comments>',@eventDetail) - CHARINDEX('<Comments>', @eventDetail) - Len('</Comments>')))
								+
							SUBSTRING(@eventDetail,CHARINDEX('</Comments>',@eventDetail), LEN(@eventDetail) - CHARINDEX('</Comments>',@eventDetail)+1)
		END
	IF @eventName = 'SaveFinishTab'
	BEGIN
		DECLARE @nextAction NVARCHAR(255),
				@scheduledDate NVARCHAR(255),
				@assignedTo INT = NULL
				
		SET @nextAction = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/NextAction') T(c))
		SET @scheduledDate = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/ScheduledDate') T(c))
		SET @assignedTo = (SELECT  T.c.value('.','INT') FROM @eventDetailXML.nodes('/EventDetail/AssignedTo') T(c))
		SET @result = ISNULL(@nextAction,'') + '<br>'
		SET @result = @result + ISNULL(@scheduledDate,'') + '<br>'
		SET @result = @result + (SELECT Case WHEN ISNULL(@assignedTo,0) = 0 
																THEN '' 
																ELSE (SELECT U.FirstName + ' ' + U.LastName
																		FROM [User] U WITH (NOLOCK)
																		WHERE U.Id = @assignedTo)
																END) + '<br>' 	
	END
	ELSE IF @eventName = 'NextActionSet'
	BEGIN
		DECLARE @nextActionAssignedToUserNextActionSet NVARCHAR(510),
				@scheduledDateNextActionSet NVARCHAR(255),
				@serviceRequestIDNextActionSet NVARCHAR(100),
				@nextActionNextActionSet NVARCHAR(100)
				
		SET @nextActionAssignedToUserNextActionSet = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/NextActionAssignedToUser') T(c))
		SET @scheduledDateNextActionSet = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/ScheduledDate') T(c))
		--SET @serviceRequestIDNextActionSet = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/ServiceRequestID') T(c))
		SET @nextActionNextActionSet = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/NextAction') T(c))
		
		SET @result = ISNULL(@nextActionNextActionSet,'') + '<br>'
		--SET @result = @result + ISNULL(@serviceRequestIDNextActionSet,'') + '<br>'
		SET @result = @result + ISNULL(@scheduledDateNextActionSet,'') + '<br>'
		SET @result = @result + ISNULL(@nextActionAssignedToUserNextActionSet,'')+'<br>'
		
	END
	ELSE IF @eventName = 'NextActionCleared'
	BEGIN
		DECLARE @serviceRequestIDNextActionCleared NVARCHAR(100),
				@nextActionCleared NVARCHAR(100)

		--SET @serviceRequestIDNextActionCleared = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/ServiceRequestID') T(c))
		SET @nextActionCleared = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/ClearedNextAction') T(c))
		
		SET @result = ISNULL(@nextActionCleared,'') + '<br>'
		--SET @result = @result + ISNULL(@serviceRequestIDNextActionCleared,'') + '<br>'
	END
	

	RETURN @result

END
GO
ALTER TRIGGER ProgramDataItemValueEntity_Trigger_After_Insert ON [dbo].[ProgramDataItemValueEntity] 
FOR INSERT
AS
	
	DECLARE @EntityName NVARCHAR(200);
	DECLARE @ScreenName NVARCHAR(200);
	DECLARE @FieldName NVARCHAR(200);
	DECLARE @Message NVARCHAR(MAX);
	DECLARE @ProgramID INT;

	DECLARE @EntityID INT;
	DECLARE @RecordID INT;
	DECLARE @ProgramDataItemID INT;
	DECLARE @Value NVARCHAR(MAX)
	
	

	SELECT @EntityID		  = currentRecord.EntityID FROM inserted currentRecord;	
	SELECT @RecordID		  = currentRecord.RecordID FROM inserted currentRecord;	
	SELECT @ProgramDataItemID = currentRecord.ProgramDataItemID FROM inserted currentRecord;	
	SELECT @Value			  = currentRecord.Value FROM inserted currentRecord;


	SELECT @EntityName = E.Name FROM Entity E WHERE E.ID = @EntityID
	SELECT @ScreenName = PDI.ScreenName,
		   @FieldName  = PDI.Name,
		   @ProgramID = PDI.ProgramID	 
	FROM   ProgramDataItem PDI WHERE PDI.ID = @ProgramDataItemID


	SET	   @Message = 'Executing Trigger AFTER INSERT ON ProgramDataItemValueEntity - Entity ID : ' + CAST(@EntityID AS NVARCHAR(100)) +  ' Record ID : ' + CAST(@RecordID AS NVARCHAR(100)) + ' Program Data Item : ' + CAST(@ProgramDataItemID AS NVARCHAR(100));
	INSERT INTO [Log]([Date],[Thread],[Level],[Logger],[Message]) VALUES(GETDATE(),0,'INFO','Trigger',@Message)
		
   -- BEGIN ACTUAL LOGIC

    IF @EntityName = 'Member' AND @ScreenName = 'RegisterMember' AND @FieldName = 'ClientReferenceNumber'
	BEGIN
		 -- UPDATE Client Reference Number Always
		 UPDATE Membership SET ClientReferenceNumber = @Value WHERE ID = (SELECT MembershipID FROM Member WHERE ID = @RecordID)

		 -- UPDATE Membership Number Based on Configuration
		 DECLARE	    @dms_programconfiguration_for_program_get AS TABLE(Name NVARCHAR(MAX),
															   Value NVARCHAR(MAX),
															   ControlType NVARCHAR(MAX),
															   DataType NVARCHAR(MAX),
															   Sequence INT)
		INSERT INTO @dms_programconfiguration_for_program_get EXEC dms_programconfiguration_for_program_get @ProgramID,'Application', 'Rule' 

		IF EXISTS (SELECT * FROM @dms_programconfiguration_for_program_get WHERE Name = 'InsertMembershipNumber' AND LOWER(Value) = 'yes')
		BEGIN
			 IF(LEN(@Value) > 0)
			 BEGIN
				UPDATE Membership SET MembershipNumber = @Value WHERE ID = (SELECT MembershipID FROM Member WHERE ID = @RecordID)
			 END
		END
	
	END

	IF @EntityName = 'Case' AND @ScreenName = 'StartCall' AND (@FieldName = 'ClaimNumber' OR @FieldName = 'CaseNumber')
	BEGIN
		Update [Case] SET ReferenceNumber = @Value WHERE ID = @RecordID
	END
	

   -- END LOGIC
	INSERT INTO [Log]([Date],[Thread],[Level],[Logger],[Message]) VALUES(GETDATE(),0,'INFO','Trigger','Trigger Execution Completed')
	
GO


IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_PO_MemberPayDispatchFee]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_PO_MemberPayDispatchFee] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 
--EXEC [dms_PO_MemberPayDispatchFee] 943, 100
CREATE PROCEDURE [dbo].[dms_PO_MemberPayDispatchFee]( 
  @poId INT = NULL 
, @purchaseOrderAmount money = 0
) 
AS 
BEGIN 
	DECLARE @internalDispatchFee money = 0, 
			@clientDispatchFee money = 0, 
			@creditCardProcessingFee money = 0, 
			@dispatchFee money = 0, 
			@StringDispatchFee nvarchar(100) = NULL

	DECLARE @serviceRequestID INT = (SELECT ServiceRequestID from PurchaseOrder where ID = @poID)

	DECLARE @programID INT = (
		SELECT C.ProgramID
		FROM [Case] C with (nolock)
		JOIN ServiceRequest SR with (nolock) ON C.ID = SR.CaseID
		JOIN PurchaseOrder PO with (Nolock) ON PO.ServiceRequestID = SR.ID
		where PO.ID = @poId
	)
	
	--DECLARE @programName NVARCHAR(100) = (SELECT Name FROM Program where ID = @programID)

	DECLARE @caseVehcileTypeID INT = (
		SELECT C.VehicleTypeID
		FROM [Case] C with (nolock)
		JOIN ServiceRequest SR with (nolock) ON C.ID = SR.CaseID
		JOIN PurchaseOrder PO with (Nolock) ON PO.ServiceRequestID = SR.ID
		where PO.ID = @poId
	)

	DECLARE @autoVehicleType INT = (SELECT ID FROM VehicleType WHERE Name = 'Auto')
	DECLARE @rvVehicleType INT = (SELECT ID FROM VehicleType WHERE Name = 'RV')
	DECLARE @rentalCoverProgramID INT = (SELECT ID FROM Program where Name = 'RentalCover.com')
	--DECLARE @rentalCoverProgramID INT = (SELECT ID FROM Program where Name = 'Platinum')

	--DECLARE @applicationConfigurationTypeID INT = (SELECT ID FROM ConfigurationType where Name='Application')
	--DECLARE @ruleConfigurationCategoryID INT = (SELECT ID FROM ConfigurationCategory where Name='Rule')
	
	DECLARE @issuedPurchaseOrderStatusID INT = (SELECT ID FROM PurchaseOrderStatus where Name='Issued')
	--Note: Checking to see if there are any issued POs other than the current one.
	DECLARE @issuePOCount INT = (SELECT Count(ID) FROM PurchaseOrder where PurchaseOrderStatusID = @issuedPurchaseOrderStatusID AND ServiceRequestID = @serviceRequestID AND ID <> @poId)

	-- Check to see if we are dealing with the PO that was first issued.	
	IF @issuePOCount > 0
	BEGIN
		
		DECLARE @currentPONumber INT = 0
		SET @currentPONumber = (SELECT ISNULL(CONVERT(INT,PurchaseOrderNumber),0) FROM PurchaseOrder PO WITH (NOLOCK) WHERE ID = @poID)

		-- Making sure that we are returning back the values that we returned the first time during issue po.
		SELECT	@issuePOCount = COUNT(*)  
		FROM	PurchaseOrder PO WITH (NOLOCK) 
		WHERE	ServiceRequestID = @serviceRequestID
		AND		PurchaseOrderStatusID = @issuedPurchaseOrderStatusID
		AND		IsActive = 1
		AND		CONVERT(INT, PurchaseOrderNumber) < @currentPONumber
	
	END 

	DECLARE @ProgramConfigValues TABLE
	(
		Name NVARCHAR(100) NULL,
		Value NVARCHAR(255) NULL,
		ControlType NVARCHAR(255) NULL,
		DataType NVARCHAR(255) NULL,
		Sequence INT NULL
	)
	
	INSERT INTO @ProgramConfigValues 
	SELECT	PC.Name, 
			PC.Value, 
			CT.Name AS ControlType, 
			DT.Name AS DataType,  
			PC.Sequence AS Sequence
	FROM ProgramConfiguration PC
	JOIN [dbo].[fnc_GetProgramConfigurationForProgram](@programID,'Application') P ON P.ProgramConfigurationID = PC.ID
	LEFT JOIN ConfigurationCategory C ON PC.ConfigurationCategoryID = C.ID
	LEFT JOIN ControlType CT ON PC.ControlTypeID = CT.ID
	LEFT JOIN DataType DT ON PC.DataTypeID = DT.ID
	WHERE	(C.Name = 'Rule')
	ORDER BY Sequence, Name
	
	IF EXISTS(SELECT * FROM @ProgramConfigValues WHERE Name='MemberPayDispatchFee' AND DataType <> 'Query')
	BEGIN		
		SET @StringDispatchFee = (SELECT W.Value FROM @ProgramConfigValues W where W.Name='MemberPayDispatchFee' AND W.DataType <> 'Query')
	END
	ELSE
	BEGIN
		SET @StringDispatchFee = (SELECT TOP 1 Value FROM ApplicationConfiguration where Name= 'MemberPayDispatchFee')
	END
	
	IF @programID = @rentalCoverProgramID
	BEGIN
		IF @issuePOCount = 0
		BEGIN 
			IF @caseVehcileTypeID = @autoVehicleType
			BEGIN
				SET @internalDispatchFee = 17.79
			END
			ELSE IF @caseVehcileTypeID = @rvVehicleType
			BEGIN
				SET @internalDispatchFee = 30.20
			END
			
			SET @clientDispatchFee = ISNULL(@purchaseOrderAmount,0) * 3
			
			SET @creditCardProcessingFee = ((ISNULL(@purchaseOrderAmount,0) + @clientDispatchFee) * 3) /100
			
			SET @dispatchFee = @internalDispatchFee + @clientDispatchFee + @creditCardProcessingFee
			
			SET @StringDispatchFee = @dispatchFee
		END
	END

	SELECT @internalDispatchFee AS InternalDispatchFee, @clientDispatchFee AS ClientDispatchFee, @creditCardProcessingFee AS CreditCardProcessingFee, @dispatchFee AS DispatchFee, @StringDispatchFee AS StringDispatchFee

END
GO
