/***********************************************************************************************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
PRINT N'Create MarketLocationType';
GO

CREATE TABLE [dbo].[MarketLocationType](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Description] [nvarchar](255) NULL,
	[Sequence] [int] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_MarketLocationType] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

SET IDENTITY_INSERT [dbo].[MarketLocationType] ON
INSERT [dbo].[MarketLocationType] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (1, N'Metro', N'Metro Location Pricing', 1, 1)
INSERT [dbo].[MarketLocationType] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (2, N'State', N'State Pricing ', 2, 1)
INSERT [dbo].[MarketLocationType] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (3, N'GlobalDefault', N'Global Default Pricing', 3, 1)
SET IDENTITY_INSERT [dbo].[MarketLocationType] OFF
GO


PRINT N'Create MarketLocation';
GO

CREATE TABLE [dbo].[MarketLocation](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[MarketLocationTypeID] [int] NULL,
	[Name] [nvarchar](50) NULL,
	[Latitude] [decimal](10, 7) NULL,
	[Longitude] [decimal](10, 7) NULL,
	[GeographyLocation] [geography] NULL,
	[RadiusMiles] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[OldVendorLocationID] [int] NULL,
	[CreateDate] [datetime] NULL,
	[CreateBy] [nvarchar](50) NULL,
	[ModifyDate] [datetime] NULL,
	[ModifyBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_MarketLocation] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE SPATIAL INDEX [IDX_MarketLocation_GeographyLocation] ON [dbo].[MarketLocation] 
(
	[GeographyLocation]
)USING  GEOGRAPHY_GRID 
WITH (
GRIDS =(LEVEL_1 = MEDIUM,LEVEL_2 = MEDIUM,LEVEL_3 = MEDIUM,LEVEL_4 = MEDIUM), 
CELLS_PER_OBJECT = 16, PAD_INDEX  = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


PRINT N'Create MarketLocationProductRate';
GO

CREATE TABLE [dbo].[MarketLocationProductRate](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[MarketLocationID] [int] NOT NULL,
	[ProductID] [int] NOT NULL,
	[RateTypeID] [int] NOT NULL,
	[Price] [money] NULL,
	[Quantity] [int] NULL,
	[CreateDate] [datetime] NULL,
	[CreateBy] [nvarchar](50) NULL,
	[ModifyDate] [datetime] NULL,
	[ModifyBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_MarketLocationProductRate] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO



/***********************************************************************************************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
PRINT N'Converting Data - MarketLocation';
GO

INSERT INTO [dbo].[MarketLocation]
           ([MarketLocationTypeID]
           ,[Name]
           ,[Latitude]
           ,[Longitude]
           ,[GeographyLocation]
           ,[RadiusMiles]
           ,[IsActive]
           ,[OldVendorLocationID]
           ,[CreateDate]
           ,[CreateBy])
Select	CASE WHEN VendorLocationTypeID = 3 THEN 1
			 WHEN VendorLocationTypeID = 4 THEN 2
			 ELSE 3 END
	,CASE WHEN VendorLocationTypeID = 5 THEN 'Global Default' ELSE DefaultLocationName END
	,Latitude
	,Longitude
	,GeographyLocation
	,RadiusMiles
	,1
	,ID
	,getdate()
	,'system'
from vendorlocation 
where vendorlocationtypeid in (3,4,5)
GO


INSERT INTO [dbo].[MarketLocationProductRate]
           ([MarketLocationID]
           ,[ProductID]
           ,[RateTypeID]
           ,[Price]
           ,[Quantity]
           ,[CreateDate]
           ,[CreateBy])
Select 
	ml.ID
	,cpr.ProductID
	,cpr.RateTypeID
	,cpr.Price
	,cpr.Quantity
	,cpr.CreateDate
	,cpr.CreateBy
from Marketlocation ml
join contractproductrate cpr on cpr.VendorLocationID = ml.OldVendorLocationID
GO

PRINT N'Remove MarketLocations from VendorLocation and ContractProductRate';
GO

Delete From ContractProductRate
Where VendorLocationID IN (
	Select OldVendorLocationID
	From MarketLocation
	)
GO

Delete vi
From VendorInvoice vi
Join PurchaseOrder po on po.ID = vi.PurchaseOrderID
Where po.VendorLocationID In(
	Select OldVendorLocationID
	From MarketLocation
	)
GO

Delete pod
From PurchaseOrderDetail pod
Join PurchaseOrder po on po.ID = Pod.PurchaseOrderID
Where po.VendorLocationID In(
	Select OldVendorLocationID
	From MarketLocation
	)
GO

Delete From PurchaseOrder 
Where VendorLocationID In(
	Select OldVendorLocationID
	From MarketLocation
	)
GO

Delete From VendorLocation
Where ID IN (
	Select OldVendorLocationID
	From MarketLocation
	)
GO

ALTER TABLE MarketLocation
DROP COLUMN OldVendorLocationID
GO

/* --- END --- Create/Populate MarketLocation schema and dependencies ***************************************************************/



/* Should be using AddressTypeEntity instead of this column */
ALTER TABLE AddressType
DROP COLUMN IsShownOnVendor
GO

ALTER TABLE ContractRateScheduleProduct 
ALTER COLUMN VendorLocationID [int] NULL
GO

ALTER TABLE VendorLocation
DROP COLUMN RadiusMiles
GO

ALTER TABLE VendorLocation
DROP COLUMN DefaultLocationName
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK__VendorLoc__Vendo__55DFB4D9]') AND parent_object_id = OBJECT_ID(N'[dbo].[VendorLocation]'))
ALTER TABLE [dbo].[VendorLocation] DROP CONSTRAINT [FK__VendorLoc__Vendo__55DFB4D9]
GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[VendorLocation]') AND name = N'IDX_VendorLocationTypeID')
DROP INDEX [IDX_VendorLocationTypeID] ON [dbo].[VendorLocation] WITH ( ONLINE = OFF )
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_VendorLocation_ParentVendorLocation]') AND parent_object_id = OBJECT_ID(N'[dbo].[VendorLocation]'))
ALTER TABLE [dbo].[VendorLocation] DROP CONSTRAINT [FK_VendorLocation_ParentVendorLocation]
GO

ALTER TABLE VendorLocation
DROP COLUMN ParentVendorLocationID
GO

ALTER TABLE VendorLocation
DROP COLUMN VendorLocationTypeID
GO

DROP TABLE VendorLocationType
GO 

DROP TABLE [dbo].[VendorLocationStatus]
GO

CREATE TABLE [dbo].[VendorLocationStatus](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Description] [nvarchar](255) NULL,
	[Sequence] [int] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_VendorLocationStatus] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET IDENTITY_INSERT [dbo].[VendorLocationStatus] ON
INSERT [dbo].[VendorLocationStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (1, N'Pending', N'Pending', 1, 1)
INSERT [dbo].[VendorLocationStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (2, N'Active', N'Active', 2, 1)
INSERT [dbo].[VendorLocationStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (3, N'Inactive', N'Inactive', 3, 1)
SET IDENTITY_INSERT [dbo].[VendorLocationStatus] OFF
GO

UPDATE VendorLocation SET VendorLocationStatusID = 2 WHERE IsActive = 1
GO

UPDATE VendorLocation SET VendorLocationStatusID = 3 WHERE IsActive = 0
GO


ALTER TABLE Vendor
DROP COLUMN CreateBatchID
GO

ALTER TABLE Vendor
DROP COLUMN ModifyBatchID
GO

ALTER TABLE Vendor
DROP COLUMN ContactName
GO

ALTER TABLE Vendor
DROP COLUMN PrimaryContactFirstName
GO

ALTER TABLE Vendor
DROP COLUMN PrimaryContactLastName
GO

ALTER TABLE Vendor
DROP COLUMN ApplicationSignedByName
GO

ALTER TABLE Vendor
DROP COLUMN ApplicationSignedByTitle
GO

ALTER TABLE Vendor
DROP COLUMN ApplicationComments
GO

ALTER TABLE Vendor
DROP COLUMN ApplicationDate
GO

ALTER TABLE Vendor
ADD IsLevyActive [bit] NULL,
	LevyRecipientName [nvarchar](50) NULL

TRUNCATE TABLE [dbo].[VendorStatus]
GO
SET IDENTITY_INSERT [dbo].[VendorStatus] ON
INSERT [dbo].[VendorStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (1, N'Pending', N'Pending', 1, 1)
INSERT [dbo].[VendorStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (2, N'Active', N'Active', 2, 1)
INSERT [dbo].[VendorStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (3, N'Inactive', N'Inactive', 3, 1)
INSERT [dbo].[VendorStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (4, N'OnHold', N'On Hold', 4, 1)
INSERT [dbo].[VendorStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (5, N'Temporary', N'Temporary', 5, 1)
INSERT [dbo].[VendorStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (6, N'DoNotUse', N'Do Not Use', 6, 1)
SET IDENTITY_INSERT [dbo].[VendorStatus] OFF
GO

UPDATE Vendor SET VendorStatusID = 2 WHERE ISNULL(IsActive,0) = 1 AND ISNULL(IsDoNotUse,0) = 0
GO
UPDATE Vendor SET VendorStatusID = 3 WHERE ISNULL(IsActive,0) = 0 AND ISNULL(IsDoNotUse,0) = 0
GO
UPDATE Vendor SET VendorStatusID = 6 WHERE ISNULL(IsDoNotUse,0) = 1
GO
UPDATE Vendor SET VendorStatusID = 5 WHERE ISNULL(IsTemporary,0) = 1
GO


ALTER TABLE Vendor
DROP COLUMN IsDoNotUse
GO

ALTER TABLE Vendor
DROP COLUMN IsTemporary
GO

ALTER TABLE ISPSelectionLog
ADD VendorLocationVirtualID [int] NULL,
	PaymentTypes [nvarchar](100) NULL,
	ProductSearchRadiusMiles [int] NULL,
	IsInProductSearchRadius [bit] NULL
GO

ALTER TABLE ISPSelectionLog
DROP COLUMN [IsCashOnly]
GO

ALTER TABLE ISPSelectionLog
DROP COLUMN [IsPersonalCheckAccepted]
GO

ALTER TABLE PurchaseOrder
ADD VendorLocationVirtualID [INT] NULL
GO


/* Replace ProgramName with ProgramReference */
ALTER TABLE [dbo].[Member]
	DROP COLUMN ProgramName
GO
ALTER TABLE [dbo].[Member]
    ADD [ProgramReference] NVARCHAR (50) NULL
GO

ALTER TABLE Vehicle
ALTER COLUMN Height [nvarchar](50) NULL
GO

ALTER TABLE [Case]
ALTER COLUMN VehicleHeight [nvarchar](50) NULL
GO

ALTER TABLE Mobile_logAccess
ADD memberDeviceGUID [nvarchar](255) NULL,
	appOrgName [nvarchar](5) NULL
GO

ALTER TABLE Mobile_Registration
ADD memberDeviceGUID [nvarchar](255) NULL,
	appOrgName [nvarchar](5) NULL
GO

CREATE TABLE [dbo].[PaymentTypeEntity] (
    [ID]              INT IDENTITY (1, 1) NOT NULL,
    [EntityID]        INT NOT NULL,
    [PaymentTypeID]   INT NOT NULL,
    [IsShownOnScreen] BIT NOT NULL,
    [Sequence]        INT NULL
);
GO
ALTER TABLE [dbo].[PaymentTypeEntity]
    ADD CONSTRAINT [PK_PaymentTypeEntity] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);
GO

SET IDENTITY_INSERT [dbo].[PaymentTypeEntity] ON
INSERT [dbo].[PaymentTypeEntity] ([ID], [EntityID], [PaymentTypeID], [IsShownOnScreen], [Sequence]) VALUES (1, 17, 1, 1, 1)
INSERT [dbo].[PaymentTypeEntity] ([ID], [EntityID], [PaymentTypeID], [IsShownOnScreen], [Sequence]) VALUES (2, 17, 2, 1, 2)
INSERT [dbo].[PaymentTypeEntity] ([ID], [EntityID], [PaymentTypeID], [IsShownOnScreen], [Sequence]) VALUES (3, 17, 3, 1, 3)
INSERT [dbo].[PaymentTypeEntity] ([ID], [EntityID], [PaymentTypeID], [IsShownOnScreen], [Sequence]) VALUES (4, 17, 4, 1, 4)
INSERT [dbo].[PaymentTypeEntity] ([ID], [EntityID], [PaymentTypeID], [IsShownOnScreen], [Sequence]) VALUES (5, 17, 5, 1, 5)
INSERT [dbo].[PaymentTypeEntity] ([ID], [EntityID], [PaymentTypeID], [IsShownOnScreen], [Sequence]) VALUES (6, 17, 6, 1, 6)
INSERT [dbo].[PaymentTypeEntity] ([ID], [EntityID], [PaymentTypeID], [IsShownOnScreen], [Sequence]) VALUES (7, 17, 7, 0, 7)
INSERT [dbo].[PaymentTypeEntity] ([ID], [EntityID], [PaymentTypeID], [IsShownOnScreen], [Sequence]) VALUES (8, 17, 8, 0, 8)
INSERT [dbo].[PaymentTypeEntity] ([ID], [EntityID], [PaymentTypeID], [IsShownOnScreen], [Sequence]) VALUES (9, 28, 2, 1, 2)
INSERT [dbo].[PaymentTypeEntity] ([ID], [EntityID], [PaymentTypeID], [IsShownOnScreen], [Sequence]) VALUES (10, 28, 7, 1, 7)
INSERT [dbo].[PaymentTypeEntity] ([ID], [EntityID], [PaymentTypeID], [IsShownOnScreen], [Sequence]) VALUES (11, 28, 9, 1, 9)
SET IDENTITY_INSERT [dbo].[PaymentTypeEntity] OFF
GO

DROP TABLE VendorPayment
GO


/* Sync ContractStatus IDs */
TRUNCATE TABLE [dbo].[ContractStatus] 
GO
SET IDENTITY_INSERT [dbo].[ContractStatus] ON
INSERT [dbo].[ContractStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (1, N'Pending', N'Pending', 1, 1)
INSERT [dbo].[ContractStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (2, N'Active', N'Active', 2, 1)
INSERT [dbo].[ContractStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (3, N'Inactive', N'Inactive', 3, 1)
SET IDENTITY_INSERT [dbo].[ContractStatus] OFF
GO

UPDATE [Contract] SET ContractStatusID = 4 WHERE ContractStatusID = 2
GO

UPDATE [Contract] SET ContractStatusID = 2 WHERE ContractStatusID = 1
GO

UPDATE [Contract] SET ContractStatusID = 3 WHERE ContractStatusID = 5
GO

UPDATE [Contract] SET ContractStatusID = 1 WHERE ContractStatusID = 4
GO

/* Sync ContractRateScheduleStatus IDs */
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_ContractRateSchedule_ContractRateScheduleStatus]') AND parent_object_id = OBJECT_ID(N'[dbo].[ContractRateSchedule]'))
ALTER TABLE [dbo].[ContractRateSchedule] DROP CONSTRAINT [FK_ContractRateSchedule_ContractRateScheduleStatus]
GO

TRUNCATE TABLE [dbo].[ContractRateScheduleStatus]
GO
SET IDENTITY_INSERT [dbo].[ContractRateScheduleStatus] ON
INSERT [dbo].[ContractRateScheduleStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (1, N'Pending', N'Pending', 1, 1)
INSERT [dbo].[ContractRateScheduleStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (2, N'Active', N'Active', 2, 1)
INSERT [dbo].[ContractRateScheduleStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (3, N'Inactive', N'Inactive', 3, 1)
SET IDENTITY_INSERT [dbo].[ContractRateScheduleStatus] OFF
GO

UPDATE [ContractRateSchedule] SET ContractRateScheduleStatusID = 4 WHERE ContractRateScheduleStatusID = 2
GO

UPDATE [ContractRateSchedule] SET ContractRateScheduleStatusID = 2 WHERE ContractRateScheduleStatusID = 1
GO

UPDATE [ContractRateSchedule] SET ContractRateScheduleStatusID = 3 WHERE ContractRateScheduleStatusID = 5
GO

UPDATE [ContractRateSchedule] SET ContractRateScheduleStatusID = 1 WHERE ContractRateScheduleStatusID = 4
GO


ALTER TABLE [dbo].[ContractRateSchedule]  WITH CHECK ADD  CONSTRAINT [FK_ContractRateSchedule_ContractRateScheduleStatus] FOREIGN KEY([ContractRateScheduleStatusID])
REFERENCES [dbo].[ContractRateScheduleStatus] ([ID])
GO

ALTER TABLE [dbo].[ContractRateSchedule] CHECK CONSTRAINT [FK_ContractRateSchedule_ContractRateScheduleStatus]
GO

DROP TABLE [dbo].[VendorPaymentType]
GO

CREATE TABLE [dbo].[VendorPaymentType](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[VendorID] [int] NULL,
	[PaymentTypeID] [int] NULL,
	[IsActive] [bit] NULL,
	[CreateDate] [datetime] NULL,
	[CreateBy] [nvarchar](50) NULL,
	[ModifyDate] [datetime] NULL,
	[ModifyBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_VendorPaymentType] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[VendorPaymentType]  WITH CHECK ADD  CONSTRAINT [FK_VendorPaymentType_PaymentType] FOREIGN KEY([PaymentTypeID])
REFERENCES [dbo].[PaymentType] ([ID])
GO

ALTER TABLE [dbo].[VendorPaymentType] CHECK CONSTRAINT [FK_VendorPaymentType_PaymentType]
GO

ALTER TABLE [dbo].[VendorPaymentType]  WITH CHECK ADD  CONSTRAINT [FK_VendorPaymentType_Vendor] FOREIGN KEY([VendorID])
REFERENCES [dbo].[Vendor] ([ID])
GO

ALTER TABLE [dbo].[VendorPaymentType] CHECK CONSTRAINT [FK_VendorPaymentType_Vendor]
GO







/* Stored Procedure Changes */

DROP FUNCTION [dbo].[fnGetDefaultProductRatesByLocation];
GO

DROP FUNCTION [dbo].[fnGetDefaultProductRatesByVendor];
GO

CREATE FUNCTION [dbo].[fnGetAllProductRatesByVendorLocation] ()
RETURNS TABLE 
AS
RETURN 
(
	-- Contract must me active and within date range
	-- Related Contract Rate Schedule must be active and within date range
	SELECT 
		v.ID VendorID
		,c.ID ContractID
		,(SELECT Name FROM ContractStatus WHERE ID = c.ContractStatusID) ContractStatus
		,c.StartDate ContractStartDate
		,c.EndDate ContractEndDate
		,crs.ID ContractRateScheduleID
		,(SELECT Name FROM ContractRateScheduleStatus WHERE ID = crs.ContractRateScheduleStatusID) ContractRateScheduleStatus
		,crs.StartDate ContractRateScheduleStartDate
		,crs.EndDate ContractRateScheduleEndDate
		,crsp.ProductID
		,crsp.VendorLocationID
		,crsp.RateTypeID
		,rt.Name RateName
		,crsp.Price
		,crsp.Quantity
	FROM dbo.Vendor v
	JOIN dbo.[Contract] c On c.VendorID = v.ID 
	JOIN dbo.[ContractRateSchedule] crs ON crs.ContractID = c.ID 
	JOIN dbo.[ContractRateScheduleProduct] crsp On crsp.ContractRateScheduleID = crs.ID 
	JOIN RateType rt on rt.ID = crsp.RateTypeID
	WHERE 
	c.IsActive = 'TRUE' --Not Deleted
)
GO


-- =============================================
-- Description:	Returns default product rates by location
-- =============================================
CREATE FUNCTION [dbo].[fnGetDefaultProductRatesByMarketLocation] 
(
	@ServiceLocationGeography geography
	,@ServiceCountryCode nvarchar(50)
	,@ServiceStateProvince nvarchar(50)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT prt.ProductID, prt.RateTypeID, rt.Name
		,CASE WHEN MetroRate.RatePrice IS NOT NULL THEN MetroRate.RatePrice * 1.25
			WHEN StateRate.RatePrice IS NOT NULL THEN StateRate.RatePrice * 1.25
			ELSE ISNULL(GlobalDefaultRate.RatePrice,0)
			END AS RatePrice
		,CASE WHEN MetroRate.RatePrice IS NOT NULL THEN ISNULL(MetroRate.RateQuantity,0)
			WHEN StateRate.RatePrice IS NOT NULL THEN ISNULL(StateRate.RateQuantity,0)
			ELSE ISNULL(GlobalDefaultRate.RateQuantity ,0)
			END AS RateQuantity
	FROM ProductRateType prt
	JOIN RateType rt on rt.ID = prt.RateTypeID
	Left Outer Join (
		Select mlpr1.ProductID, mlpr1.RateTypeID, mlpr1.Price AS RatePrice, mlpr1.Quantity AS RateQuantity
		From dbo.MarketLocation ml1
		Left Outer Join dbo.MarketLocationProductRate mlpr1 On ml1.ID = mlpr1.MarketLocationID 
		--Left Outer Join dbo.RateType rt1 On cpr1.RateTypeID = rt1.ID
		Where ml1.MarketLocationTypeID = (Select ID From MarketLocationType Where Name = 'GlobalDefault')
		) GlobalDefaultRate
		ON GlobalDefaultRate.ProductID = prt.ProductID AND GlobalDefaultRate.RateTypeID = prt.RateTypeID
	Left Outer Join (
		Select mlpr2.ProductID, mlpr2.RateTypeID, mlpr2.Price RatePrice, mlpr2.Quantity RateQuantity
		From dbo.MarketLocation ml2
		Left Outer Join dbo.MarketLocationProductRate mlpr2 On ml2.ID = mlpr2.MarketLocationID 
		--Left Outer Join dbo.RateType rt2 On cpr2.RateTypeID = rt2.ID
		Where ml2.MarketLocationTypeID = (Select ID From MarketLocationType Where Name = 'Metro')
			And ml2.IsActive = 'TRUE'
			and ml2.GeographyLocation.STDistance(@ServiceLocationGeography) <= ml2.RadiusMiles * 1609.344
		) MetroRate 
		ON MetroRate.ProductID = prt.ProductID AND MetroRate.RateTypeID = prt.RateTypeID
	Left Outer Join
		(
		Select mlpr3.ProductID,mlpr3.RateTypeID, mlpr3.Price RatePrice, mlpr3.Quantity RateQuantity
		From dbo.MarketLocation ml3
		Left Outer Join dbo.MarketLocationProductRate mlpr3 On ml3.ID = mlpr3.MarketLocationID 
		--Left Outer Join dbo.RateType rt3 On cpr3.RateTypeID = rt3.ID
		Where ml3.MarketLocationTypeID = (Select ID From MarketLocationType Where Name = 'State')
		And ml3.IsActive = 'TRUE'
		And ml3.Name = (@ServiceCountryCode + N'_' + @ServiceStateProvince)
		) StateRate 
		ON StateRate.ProductID = prt.ProductID AND StateRate.RateTypeID = prt.RateTypeID
	WHERE 
	prt.IsOptional = 'FALSE'
	AND rt.Name NOT IN ('EnrouteFree','ServiceFree')
)
GO


 --[dms_activity_list] @serviceRequestID = 83358
-- EXEC [dbo].[dms_activity_list_debug] @serviceRequestID = 83329,@whereClauseXML = '<ROW><Filter TypeOperator="11" TypeValue="Event Log,Contact Log"></Filter></ROW>'   
 ALTER PROCEDURE [dbo].[dms_activity_list](
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

CREATE TABLE #tmpFinalResults 
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
 QuestionAnswer nvarchar(max) NULL
)

CREATE TABLE #FinalResults ( 
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
INSERT INTO #tmpFinalResults 
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
--r.RoleName, 
NULL as RoleName,
--O.Name as OrganizationName,
NULL as OrganizationName,
CASE WHEN EL.EventID = @CancelPOEventID THEN PO.CancellationComment ELSE NULL END AS Comments,
NULL AS ContactReason,
NULL AS [ContactAction],
NULL AS [QuestionAnswer]
FROM EventLog(NOLOCK) EL
JOIN Event(NOLOCK) E on E.ID = EL.EventID
JOIN EventType(NOLOCK) ET on ET.ID = E.EventTypeID
JOIN EventCategory(NOLOCK) EC on EC.ID = E.EventCategoryID
JOIN EventLogLink(NOLOCK) ELL on ELL.EventLogID = EL.ID
JOIN Entity(NOLOCK) EN ON EN.ID = ELL.EntityID
--LEFT OUTER JOIN aspnet_Users(NOLOCK) AU ON AU.UserName = EL.CreateBy
--LEFT OUTER JOIN [User](NOLOCK) U ON U.aspnet_UserID = AU.UserID
--LEFT OUTER JOIN aspnet_Roles(NOLOCK) R ON R.RoleID = (SELECT TOP 1 RoleID FROM aspnet_UsersInRoles UIR WHERE UIR.UserID = AU.userID)
--LEFT OUTER JOIN Organization(NOLOCK) O ON O.ID = U.OrganizationID
LEFT JOIN PurchaseOrder(NOLOCK) PO ON PO.ID = ELL.RecordID AND ELL.EntityID = @PurchaseOrderEntityID
WHERE
E.IsShownOnScreen = 1 AND E.IsActive = 1 
AND (
(ELL.EntityID = @InboundCallEntityID AND ELL.RecordID IN (Select ID From @InboundCallResult))
OR (ELL.EntityID = @EmergencyAssistanceEntityID AND ELL.RecordID IN (Select ID From @EmergencyAssistanceResult))
OR (ELL.EntityID = @CaseEntityID AND ELL.RecordID = @Case)
OR (ELL.EntityID = @ServiceRequestEntityID AND ELL.RecordID = @ServiceRequestID)
OR (ELL.EntityID = @PurchaseOrderEntityID AND ELL.RecordID IN (Select ID From @PurchaseOrderResult))
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
 FROM ContactLog(NOLOCK) CL
 JOIN ContactLogLink(NOLOCK) CLL ON CLL.ContactLogID = CL.ID
 JOIN Entity(NOLOCK) EN ON EN.ID = CLL.EntityID
 JOIN ContactType(NOLOCK) CT ON CT.ID = CL.ContactTypeID
 JOIN ContactCategory(NOLOCK) CC ON CC.ID = CL.ContactCategoryID
 JOIN ContactMethod(NOLOCK) CM ON CM.ID= CL.ContactMethodID 
 JOIN ContactLogReason(NOLOCK) CLR ON CLR.ContactLogID = CL.ID
 JOIN ContactReason(NOLOCK) CR ON CR.ID = CLR.ContactReasonID
 --LEFT JOIN ContactSource CS ON CS.ID= CL.ContactSourceID 
 LEFT JOIN #CustomProgramDynamicValues CPDV ON CPDV.ContactLogID = CL.ID
 -- adding left joins to deal with createby = 'system'
 --LEFT OUTER JOIN aspnet_Users(NOLOCK) au on au.UserName = CL.CreateBy
 --LEFT OUTER JOIN [User](NOLOCK) u on u.aspnet_UserID = au.UserID
 --LEFT OUTER JOIN aspnet_Roles(NOLOCK) R ON R.RoleID = (SELECT TOP 1 RoleID FROM aspnet_UsersInRoles UIR WHERE UIR.UserID = AU.userID)
 --LEFT OUTER JOIN Organization(NOLOCK) o on o.ID = u.OrganizationID
 WHERE 
 (CLL.EntityID = @InboundCallEntityID AND CLL.RecordID IN (Select ID From @InboundCallResult))
 OR (CLL.EntityID = @EmergencyAssistanceEntityID AND CLL.RecordID IN (Select ID From @EmergencyAssistanceResult))
 OR (CLL.EntityID = @CaseEntityID AND CLL.RecordID = @Case)
 OR (CLL.EntityID = @ServiceRequestEntityID AND CLL.RecordID = @ServiceRequestID)
 OR (CLL.EntityID = @PurchaseOrderEntityID AND CLL.RecordID IN (Select ID From @PurchaseOrderResult))

UNION ALL
-- COMMENTS
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
 --LEFT OUTER JOIN aspnet_Users(NOLOCK) au on au.UserName = C.CreateBy
 --LEFT OUTER JOIN [User](NOLOCK) u on u.aspnet_UserID = au.UserID
 --LEFT OUTER JOIN aspnet_Roles(NOLOCK) R ON R.RoleID = (SELECT TOP 1 RoleID FROM aspnet_UsersInRoles(NOLOCK) UIR WHERE UIR.UserID = AU.userID)
 --LEFT OUTER JOIN Organization(NOLOCK) o on o.ID = u.OrganizationID
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
FROM #tmpFinalResults Temp
LEFT OUTER JOIN aspnet_Users(NOLOCK) au on au.UserName = Temp.CreateBy
LEFT OUTER JOIN [User](NOLOCK) u on u.aspnet_UserID = au.UserID
LEFT OUTER JOIN aspnet_Roles(NOLOCK) R ON R.RoleID = (SELECT TOP 1 RoleID FROM aspnet_UsersInRoles(NOLOCK) UIR WHERE UIR.UserID = AU.userID)
LEFT OUTER JOIN Organization(NOLOCK) o on o.ID = u.OrganizationID


INSERT INTO #FinalResults
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
FROM #tmpFinalResults T
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
 
 
 
 
SELECT @eventLogCount = COUNT(*) FROM #FinalResults WHERE [Type] = 'Event Log'
SELECT @contactLogCount = COUNT(*) FROM #FinalResults WHERE [Type] = 'Contact Log'
SELECT @commentCount = COUNT(*) FROM #FinalResults WHERE [Type] = 'Comment'
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
SELECT @count AS TotalRows, *, @eventLogCount as EventLogCount,@contactLogCount as ContactLogCount,@commentCount as commentCount FROM #FinalResults WHERE RowNum BETWEEN @startInd AND @endInd
DROP TABLE #tmpFinalResults
DROP TABLE #FinalResults
DROP TABLE #CustomProgramDynamicValues
END
GO

 -- EXEC [dbo].[dms_ISPSelection_get]  44022,5,1,1,50,0.4,0.1,0.5,0,'Location'
/* Debug */
--DECLARE 
--	@ServiceRequestID int  = 44022 
--	,@ActualServiceMiles decimal(10,2)  = 5 
--	,@VehicleTypeID int  = 1 
--	,@VehicleCategoryID int  = 1 
--	,@SearchRadiusMiles int  = 50 
--	,@AdminWeight decimal(5,2)  = .1 
--	,@PerformWeight decimal(5,2) = .2  
--	,@CostWeight decimal(5,2)  = .7 
--	,@IncludeDoNotUse bit  = 0 
--	,@SearchFrom nvarchar(50) = 'Location'
--	,@productIDs NVARCHAR(MAX) = NULL 
	
ALTER PROCEDURE [dbo].[dms_ISPSelection_get]  
	@ServiceRequestID int  = NULL 
	,@ActualServiceMiles decimal(10,2)  = NULL 
	,@VehicleTypeID int  = NULL 
	,@VehicleCategoryID int  = NULL 
	,@SearchRadiusMiles int  = NULL 
	,@AdminWeight decimal(5,2)  = NULL 
	,@PerformWeight decimal(5,2) = NULL  
	,@CostWeight decimal(5,2)  = NULL 
	,@IncludeDoNotUse bit  = NULL 
	,@SearchFrom nvarchar(50) = NULL
	,@productIDs NVARCHAR(MAX) = NULL -- comma separated list of product IDs.
AS  
BEGIN  

/* Variable Declarations */
DECLARE     
	@ServiceLocationLatitude decimal(10,7) 
    ,@ServiceLocationLongitude decimal(10,7)  
    ,@ServiceLocationStateProvince nvarchar(2)
    ,@ServiceLocationCountryCode nvarchar(10) 
    ,@DestinationLocationLatitude decimal(10,7)  
    ,@DestinationLocationLongitude decimal(10,7)
    ,@PrimaryProductID int 
    ,@SecondaryProductID int
    ,@ProductCategoryID int
    ,@SecondaryProductCategoryID int
    ,@MembershipID int
    ,@ProgramID INT
    ,@pcAdminWeight decimal(5,2)  = NULL 
	,@pcPerformWeight decimal(5,2) = NULL  
	,@pcCostWeight decimal(5,2)  = NULL 
	,@IsTireDelivery bit
	,@LogISPSelection bit
	,@LogISPSelectionFinal bit

/* Set Logging On/Off */
SET @LogISPSelection = 0
SET @LogISPSelectionFinal = 1

/* Hard-coded radius for Do-Not-Use vendor selection - Should be added to ApplicationConfiguration */
DECLARE @DNUSearchRadiusMiles int  
SET @DNUSearchRadiusMiles = 50  

/* Get Current Time for log inserts */
DECLARE @now DATETIME = GETDATE()


/* Work table declarations *******************************************************/
SET FMTONLY OFF
DECLARE @ISPSelection TABLE (
[VendorID] [int] NOT NULL,
[VendorLocationID] [int] NOT NULL,
[VendorLocationVirtualID] [int] NULL,
[Latitude] [decimal](10, 7) NULL,
[Longitude] [decimal](10, 7) NULL,
[VendorName] [nvarchar](255) NULL,
[VendorNumber] [nvarchar](50) NULL,
[Source] [varchar](8) NOT NULL,
[ContractStatus] [nvarchar](50) NOT NULL,
[Address1] [nvarchar](100) NULL,
[Address2] [nvarchar](100) NULL,
[City] [nvarchar](100) NULL,
[StateProvince] [nvarchar](10) NULL,
[PostalCode] [nvarchar](20) NULL,
[CountryCode] [nvarchar](2) NULL,
[DispatchPhoneNumber] [nvarchar](50) NULL,
[FaxPhoneNumber] [nvarchar](50) NULL, 
[OfficePhoneNumber] [nvarchar](50) NULL,
[CellPhoneNumber] [nvarchar](50) NULL, -- CR : 1226
[AdministrativeRating] [int] NULL,
[InsuranceStatus] [varchar](11) NOT NULL,
[BusinessHours] [nvarchar](100) NOT NULL,
[PaymentTypes] [nvarchar] (100) NULL,  
[Comment] [nvarchar](2000) NULL,
[ProductID] [int] NOT NULL,
[ProductName] [nvarchar](50) NULL,
[ProductRating] [decimal](5, 2) NULL,
[EnrouteMiles] [float] NULL,
[EnrouteTimeMinutes] [int] NULL,
[ServiceMiles] [decimal](10, 2) NULL,
[ServiceTimeMinutes] [int] NULL,
[ReturnMiles] [float] NULL,
[ReturnTimeMinutes] [int] NULL,
[EstimatedHours] [float] NULL,
[BaseRate] [money] NULL,
[HourlyRate] [money] NULL,
[EnrouteRate] [money] NULL,
[EnrouteFreeMiles] [int] NULL,
[ServiceRate] [money] NULL,
[ServiceFreeMiles] [int] NULL,
[EstimatedPrice] [float] NULL,
[WiseScore] [float] NULL,
[CallStatus] [varchar](9) NOT NULL,
[RejectReason] [nvarchar](255) NULL,
[RejectComment] [nvarchar](max) NULL,
[IsPossibleCallback] [bit] NOT NULL
) 

DECLARE @ISPSelectionFinalResults TABLE (
[VendorID] [int] NOT NULL,
[VendorLocationID] [int] NOT NULL,
[VendorLocationVirtualID] [int] NULL,
[Latitude] [decimal](10, 7) NULL,
[Longitude] [decimal](10, 7) NULL,
[VendorName] [nvarchar](255) NULL,
[VendorNumber] [nvarchar](50) NULL,
[Source] [varchar](8) NOT NULL,
[ContractStatus] [nvarchar](50) NOT NULL,
[Address1] [nvarchar](100) NULL,
[Address2] [nvarchar](100) NULL,
[City] [nvarchar](100) NULL,
[StateProvince] [nvarchar](10) NULL,
[PostalCode] [nvarchar](20) NULL,
[CountryCode] [nvarchar](2) NULL,
[DispatchPhoneNumber] [nvarchar](50) NULL,
[FaxPhoneNumber] [nvarchar](50) NULL, 
[OfficePhoneNumber] [nvarchar](50) NULL,
[CellPhoneNumber] [nvarchar](50) NULL, -- CR : 1226
[AdministrativeRating] [int] NULL,
[InsuranceStatus] [varchar](11) NOT NULL,
[BusinessHours] [nvarchar](100) NOT NULL,
[PaymentTypes] [nvarchar] (100) NULL,  
[Comment] [nvarchar](2000) NULL,
[ProductID] [int] NOT NULL,
[ProductName] [nvarchar](50) NULL,
[ProductRating] [decimal](5, 2) NULL,
[EnrouteMiles] [float] NULL,
[EnrouteTimeMinutes] [int] NULL,
[ServiceMiles] [decimal](10, 2) NULL,
[ServiceTimeMinutes] [int] NULL,
[ReturnMiles] [float] NULL,
[ReturnTimeMinutes] [int] NULL,
[EstimatedHours] [float] NULL,
[BaseRate] [money] NULL,
[HourlyRate] [money] NULL,
[EnrouteRate] [money] NULL,
[EnrouteFreeMiles] [int] NULL,
[ServiceRate] [money] NULL,
[ServiceFreeMiles] [int] NULL,
[EstimatedPrice] [float] NULL,
[WiseScore] [float] NULL,
[CallStatus] [varchar](9) NOT NULL,
[RejectReason] [nvarchar](255) NULL,
[RejectComment] [nvarchar](max) NULL,
[IsPossibleCallback] [bit] NOT NULL,
[AllServices] [NVARCHAR](MAX) NULL,
[ProductSearchRadiusMiles] [int] NULL,
[IsInProductSearchRadius] [bit] NULL
)

CREATE TABLE #ISPDoNotUse (
[VendorID] [int] NOT NULL,
[VendorLocationID] [int] NOT NULL,
[VendorLocationVirtualID] [int] NULL,
[Latitude] [decimal](10, 7) NULL,
[Longitude] [decimal](10, 7) NULL,
[VendorName] [nvarchar](255) NULL,
[VendorNumber] [nvarchar](50) NULL,
[Source] [varchar](8) NOT NULL,
[ContractStatus] [nvarchar](50) NULL,
[Address1] [nvarchar](100) NULL,
[Address2] [nvarchar](100) NULL,
[City] [nvarchar](100) NULL,
[StateProvince] [nvarchar](10) NULL,
[PostalCode] [nvarchar](20) NULL,
[CountryCode] [nvarchar](2) NULL,
[DispatchPhoneNumber] [nvarchar](50) NULL,
[FaxPhoneNumber] [nvarchar](50) NULL, 
[OfficePhoneNumber] [nvarchar](50) NULL,
[CellPhoneNumber] [nvarchar](50) NULL, -- CR: 1226
[AdministrativeRating] [int] NULL,
[InsuranceStatus] [varchar](11) NULL,
[BusinessHours] [nvarchar](100) NULL,
[PaymentTypes] [nvarchar] (100) NULL,  
[Comment] [nvarchar](2000) NULL,
[ProductID] [int] NULL,
[ProductName] [nvarchar](50) NULL,
[ProductRating] [decimal](5, 2) NULL,
[EnrouteMiles] [float] NULL,
[EnrouteTimeMinutes] [int] NULL,
[ServiceMiles] [decimal](10, 2) NULL,
[ServiceTimeMinutes] [int] NULL,
[ReturnMiles] [float] NULL,
[ReturnTimeMinutes] [int] NULL,
[EstimatedHours] [float] NULL,
[BaseRate] [money] NULL,
[HourlyRate] [money] NULL,
[EnrouteRate] [money] NULL,
[EnrouteFreeMiles] [int] NULL,
[ServiceRate] [money] NULL,
[ServiceFreeMiles] [int] NULL,
[EstimatedPrice] [float] NULL,
[WiseScore] [float] NULL,
[CallStatus] [varchar](9) NULL,
[RejectReason] [nvarchar](255) NULL,
[RejectComment] [nvarchar](max) NULL,
[IsPossibleCallback] [bit] NULL
) 

CREATE TABLE #IspDetail (
[VendorID] [int] NOT NULL,
[VendorLocationID] [int] NOT NULL,
[VendorLocationVirtualID] [int] NULL,
[Latitude] [decimal](10, 7) NULL,
[Longitude] [decimal](10, 7) NULL,
[VendorName] [nvarchar](255) NULL,
[VendorNumber] [nvarchar](50) NULL,
[Source] [varchar](8) NOT NULL,
[ContractStatus] [nvarchar](50) NULL,
[DispatchPhoneNumber] [nvarchar](50) NULL,
[AdministrativeRating] [int] NULL,
[InsuranceStatus] [varchar](11) NOT NULL,
[IsOpen24Hours] [bit] NULL,
[BusinessHours] [nvarchar](100) NULL,
--[PaymentTypes] [nvarchar] (100) NULL,  
[Comment] [nvarchar](2000) NULL,
[EnrouteMiles] [float] NULL,
[ServiceMiles] [decimal](10, 2) NULL,
[ReturnMiles] [float] NULL,
[ProductID] [int] NOT NULL,
[ProductName] [nvarchar](50) NULL,
[ProductRating] [decimal](5, 2) NULL,
[RateTypeID] [int] NULL,
[RatePrice] [money] NULL,
[RateQuantity] [int] NULL,
[RateTypeName] [nvarchar](50) NULL,
[RateUnitOfMeasure] [nvarchar](50) NULL,
[RateUnitOfMeasureSource] [nvarchar](50) NULL,
[IsProductMatch] [int] NOT NULL
) 

-- Get service information from ServiceRequest
SELECT       
	@ServiceLocationLatitude = SR.ServiceLocationLatitude,
    @ServiceLocationLongitude = SR.ServiceLocationLongitude,
    @ServiceLocationStateProvince = SR.ServiceLocationStateProvince,
    @ServiceLocationCountryCode = SR.ServiceLocationCountryCode,
    @DestinationLocationLatitude = SR.DestinationLatitude,
    @DestinationLocationLongitude = SR.DestinationLongitude,
    @PrimaryProductID = SR.PrimaryProductID,
    @SecondaryProductID = SR.SecondaryProductID,
    @ProductCategoryID = SR.ProductCategoryID,
    @MembershipID = m.MembershipID,
    @ProgramID = c.ProgramID
FROM  ServiceRequest SR
JOIN [Case] c ON SR.CaseID = c.ID
JOIN Member m ON c.MemberID = m.ID
WHERE SR.ID = @ServiceRequestID

SET @SecondaryProductCategoryID = (SELECT ProductCategoryID FROM Product WHERE ID = @SecondaryProductID)

-- Additional condition needed to include tire stores if tire service and tire delivery selected
SET @IsTireDelivery = ISNULL((SELECT 1 FROM ServiceRequestDetail WHERE @ProductCategoryID = 2 AND ServiceRequestID = @ServiceRequestID AND ProductCategoryQuestionID = 203 AND Answer = 'Tire Delivery'),0)

-- Set program specific ISP scoring weights */
DECLARE @ProgramConfig TABLE (
	Name NVARCHAR(50) NULL,
	Value NVARCHAR(255) NULL
)

;WITH wProgramConfig 
AS
(	SELECT ROW_NUMBER() OVER ( PARTITION BY PC.Name ORDER BY PP.Sequence) AS RowNum,
			PP.Sequence,
			PC.Name,	
			PC.Value	
	FROM fnc_GetProgramsandParents(@ProgramID) PP
	JOIN ProgramConfiguration PC ON PP.ProgramID = PC.ProgramID AND PC.IsActive = 1
	WHERE	PC.ConfigurationTypeID = 5 
	AND		PC.ConfigurationCategoryID = 3
)

INSERT INTO @ProgramConfig
SELECT	W.Name,
		W.Value
FROM	wProgramConfig W
WHERE	W.RowNum = 1

SET @pcAdminWeight = NULL
SET @pcPerformWeight = NULL
SET @pcCostWeight = NULL
SELECT @pcAdminWeight = CONVERT(DECIMAL(5,2),Value) FROM @ProgramConfig WHERE Name = 'DefaultAdminWeighting'
SELECT @pcPerformWeight = CONVERT(DECIMAL(5,2),Value) FROM @ProgramConfig WHERE Name = 'DefaultPerformanceWeighting'
SELECT @pcCostWeight = CONVERT(DECIMAL(5,2),Value) FROM @ProgramConfig WHERE Name = 'DefaultCostWeighting'

-- DEBUG : SELECT @pcAdminWeight AS AdminWeight, @pcCostWeight AS CostWeight, @pcPerformWeight AS PerfWeight
-- If one the values is not defined, then use the values from ApplicationConfiguration.
-- In other words, if all the three values are found, then override the ones from the app config.
IF @pcAdminWeight IS NOT NULL AND @pcCostWeight IS NOT NULL AND @pcPerformWeight IS NOT NULL
BEGIN
	PRINT 'Using the values from ProgramConfig'
	
	SET @AdminWeight = @pcAdminWeight
	SET @CostWeight = @pcCostWeight
	SET @PerformWeight = @pcPerformWeight
END
  
/* Get geography values for service location and towing destination */  
DECLARE @ServiceLocation as geography  
	,@DestinationLocation as geography  
IF (@ServiceLocationLatitude IS NOT NULL AND @ServiceLocationLongitude IS NOT NULL)
BEGIN
    SET @ServiceLocation = geography::Point(@ServiceLocationLatitude, @ServiceLocationLongitude, 4326)  
END
IF (@DestinationLocationLatitude IS NOT NULL AND @DestinationLocationLongitude IS NOT NULL)
BEGIN
    SET @DestinationLocation = geography::Point(@DestinationLocationLatitude, @DestinationLocationLongitude, 4326)  
END
  
/* Set Service Miles based on service and destination locations - same for all vendors */  
DECLARE @ServiceMiles decimal(10,2)  
IF @ActualServiceMiles IS NOT NULL  
SET @ServiceMiles = @ActualServiceMiles  
ELSE  
SET @ServiceMiles = ROUND(@DestinationLocation.STDistance(@ServiceLocation)/1609.344,0)  

/* Get Market product rates according to market location */
CREATE TABLE #MarketRates (
[ProductID] [int] NULL,
[RateTypeID] [int] NULL,
[Name] [nvarchar](50) NULL,
[Price] [money] NULL,
[Quantity] [int] NULL
)

INSERT INTO #MarketRates
SELECT ProductID, RateTypeID, Name, RatePrice, RateQuantity
FROM dbo.fnGetDefaultProductRatesByMarketLocation(@ServiceLocation, @ServiceLocationCountryCode, @ServiceLocationStateProvince)

CREATE CLUSTERED INDEX IDX_MarketRates ON #MarketRates(ProductID, RateTypeID)

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
WHERE ProductID = @PrimaryProductID 

IF @ProductSearchRadiusMiles IS NULL 
	SET @ProductSearchRadiusMiles = @SearchRadiusMiles


/* Get reference type IDs */  
DECLARE   
		@VendorEntityID int  
		,@VendorLocationEntityID int  
		,@ServiceRequestEntityID int  
		,@BusinessAddressTypeID int  
		,@DispatchPhoneTypeID int  
		,@FaxPhoneTypeID int
		,@OfficePhoneTypeID int  
		,@CellPhoneTypeID int -- CR : 1226
		,@PrimaryServiceProductSubTypeID int  
		,@ActiveVendorStatusID int
		,@DoNotUseVendorStatusID int
		,@ActiveVendorLocationStatusID int
SET @VendorEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'Vendor')  
SET @VendorLocationEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'VendorLocation')  
SET @ServiceRequestEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'ServiceRequest')  
SET @BusinessAddressTypeID = (SELECT ID FROM dbo.AddressType WHERE Name = 'Business')  
SET @DispatchPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Dispatch')  
SET @FaxPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Fax')  
SET @OfficePhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Office')  
SET @CellPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Cell')  -- CR: 1226
SET @PrimaryServiceProductSubTypeID = (Select ID From dbo.ProductSubType Where Name = 'PrimaryService')  
SET @ActiveVendorStatusID = (SELECT ID FROM dbo.VendorStatus WHERE Name = 'Active')  
SET @DoNotUseVendorStatusID = (SELECT ID FROM dbo.VendorStatus WHERE Name = 'DoNotUse')  
SET @ActiveVendorLocationStatusID = (SELECT ID FROM dbo.VendorLocationStatus WHERE Name = 'Active')  

  
/* Get list of ALL vendors within the Search Radius of the service location */
SELECT V.ID VendorID
	,vl.ID VendorLocationID
	,NULL AS VendorLocationVirtualID
	,vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) Distance
	,vl.GeographyLocation
INTO #tmpVendorLocation
FROM VendorLocation vl
JOIN Vendor V ON vl.VendorID = V.ID
WHERE V.IsActive = 1 AND V.VendorStatusID = @ActiveVendorStatusID
AND vl.IsActive = 1 AND vl.VendorLocationStatusID = @ActiveVendorLocationStatusID
AND vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) <= @SearchRadiusMiles * 1609.344  

-- Include search of related Vendor Location virtual mapping points 
INSERT INTO #tmpVendorLocation
SELECT V.ID VendorID
	,vl.ID VendorLocationID
	,vlv.ID VendorLocationVirtualID
	,vlv.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) Distance
	,vlv.GeographyLocation
FROM VendorLocation vl
JOIN Vendor V ON vl.VendorID = V.ID
JOIN VendorLocationVirtual vlv on vlv.VendorLocationID = vl.ID AND vlv.IsActive = 1
WHERE V.IsActive = 1 AND V.VendorStatusID = @ActiveVendorStatusID
AND vl.IsActive = 1 AND vl.VendorLocationStatusID = @ActiveVendorLocationStatusID
AND vlv.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) <= @SearchRadiusMiles * 1609.344  

/* Index physical locations */
CREATE NONCLUSTERED INDEX [IDX_tmpVendors_VendorLocationID] ON #tmpVendorLocation
([VendorLocationID] ASC)
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

/* Reduce list to only the closest location if the vendor has multiple physical or virtual locations within the Search Radius */
DELETE #tmpVendorLocation 
FROM #tmpVendorLocation vl1
WHERE NOT EXISTS (
	SELECT *
	FROM #tmpVendorLocation vl2
	JOIN (
		SELECT VendorID, MIN(Distance) Distance
		FROM #tmpVendorLocation 
		GROUP BY VendorID
		) ClosestLocation 
		ON ClosestLocation.VendorID = vl2.VendorID and ClosestLocation.Distance = vl2.Distance
	WHERE vl1.VendorLocationID = vl2.VendorLocationID AND
		vl1.Distance = vl2.Distance
	)

/* For the vendor locations within the Search Radius determine vendors that can provide the desired service */
INSERT INTO #IspDetail 
SELECT   
		v.ID VendorID  
		,vl.ID VendorLocationID 
		,tvl.VendorLocationVirtualID 
		,vl.Latitude  
		,vl.Longitude  
		,v.Name VendorName  
		,v.VendorNumber  
		,CASE WHEN v.VendorNumber IS NULL THEN 'Internet' ELSE '' END AS [Source]
		-- Have to check the if the selected product is a contract rate since the vendor can be contracted but not have a rate set for the service (bad data)  
		,CAST(CASE WHEN VendorLocationRates.Price IS NOT NULL OR DefaultVendorRates.Price IS NOT NULL THEN 'Contracted'   
		ELSE NULL  
		END AS nvarchar(50)) AS ContractStatus  
		,ph.PhoneNumber DispatchPhoneNumber  
		,v.AdministrativeRating 
		-- Ignore time while comparing dates here
		,CASE WHEN v.InsuranceExpirationDate >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0) THEN 'Insured' 
		ELSE 'Not Insured' END InsuranceStatus  
		,vl.[IsOpen24Hours]  
		,vl.BusinessHours  
		,vl.DispatchNote AS Comment  
		,ROUND(tvl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END)/1609.344,1) EnrouteMiles  
		,@ServiceMiles as ServiceMiles  
		,ROUND(tvl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' OR @ProductCategoryID <> 1 THEN @ServiceLocation ELSE @DestinationLocation END)/1609.344,1) ReturnMiles  
		,vlp.ProductID  
		,p.Name ProductName  
		,vlp.Rating ProductRating  
		,prt.RateTypeID   
		,CASE	WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Price  
				WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Price  
				ELSE MarketRates.Price   
		END AS RatePrice  
		,CASE	WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Quantity  
				WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Quantity  
				ELSE MarketRates.Quantity   
		END AS RateQuantity  
		, rt.Name RateTypeName  
		, rt.UnitOfMeasure RateUnitOfMeasure  
		, rt.UnitOfMeasureSource RateUnitOfMeasureSource  
		,CASE	WHEN p.ID = ISNULL(@PrimaryProductID,0) THEN 1 
				ELSE 0 
		END IsProductMatch  
FROM	#tmpVendorLocation tvl
JOIN	dbo.VendorLocation vl on tvl.VendorLocationID = vl.ID 
JOIN	dbo.Vendor v  ON vl.VendorID = v.ID  
JOIN	dbo.[AddressEntity] addr ON addr.EntityID = @VendorLocationEntityID and addr.RecordID = vl.ID and addr.AddressTypeID = @BusinessAddressTypeID  
JOIN	dbo.[PhoneEntity] ph ON ph.EntityID = @VendorLocationEntityID and ph.RecordID = vl.ID and ph.PhoneTypeID = @DispatchPhoneTypeID  
JOIN	dbo.VendorLocationProduct vlp ON vl.ID = vlp.VendorLocationID AND vlp.IsActive = 1
JOIN	dbo.Product p ON p.ID = vlp.ProductID  
JOIN	dbo.ProductRateType prt ON prt.ProductID = p.ID AND	prt.IsOptional = 0 
JOIN	dbo.RateType rt ON prt.RateTypeID = rt.ID  
LEFT OUTER JOIN [Contract] c ON c.VendorID = v.ID
LEFT OUTER JOIN [ContractRateSchedule] crs ON crs.ContractID = c.ID
LEFT OUTER JOIN dbo.fnGetAllProductRatesByVendorLocation() VendorLocationRates ON 
	v.ID = VendorLocationRates.VendorID AND 
	p.ID = VendorLocationRates.ProductID AND 
	prt.RateTypeID = VendorLocationRates.RateTypeID AND
	crs.ID = VendorLocationRates.ContractRateScheduleID AND
	VendorLocationRates.VendorLocationID = vl.ID 
LEFT OUTER JOIN dbo.fnGetAllProductRatesByVendorLocation() DefaultVendorRates ON 
	v.ID = DefaultVendorRates.VendorID AND 
	p.ID = DefaultVendorRates.ProductID AND 
	prt.RateTypeID = DefaultVendorRates.RateTypeID AND
	crs.ID = DefaultVendorRates.ContractRateScheduleID AND
	DeFaultVendorRates.VendorLocationID IS NULL
LEFT OUTER JOIN #MarketRates MarketRates ON p.ID = MarketRates.ProductID And MarketRates.RateTypeID = prt.RateTypeID 
  
WHERE	
(VendorLocationRates.RateTypeID IS NOT NULL OR DefaultVendorRates.Price IS NOT NULL OR MarketRates.Price IS NOT NULL)  
AND		
	(
		(   vlp.ProductID = @PrimaryProductID
			AND
		    -- Additional condition to include tire stores if tire service and tire delivery selected
			( 
			  @IsTireDelivery = 0
			  OR
			  --If Tire delivery then Tire Repair must also have Tire Store Attributes
			  (@IsTireDelivery = 1  
					AND EXISTS (
					SELECT * FROM VendorLocationProduct vlp1 
					JOIN Product p1 ON vlp1.ProductID = p1.ID and p1.ProductCategoryID = 2 and p1.ProductSubTypeID = 10
					WHERE vlp1.VendorLocationID = vl.ID)
			  ) 
			) 
		--Additional condition for Mobile Mechanic service
			OR
        (@ProductCategoryID = 8 AND vlp.ProductID IN (SELECT ID FROM Product WHERE ProductCategoryID = 8))

		)
	AND 
		-- Code to require towing service for possible tow
		( @SecondaryProductID IS NULL 
		OR EXISTS (SELECT * FROM VendorLocationProduct vlp2 WHERE vlp2.VendorLocationID = vl.ID and vlp2.ProductID = @SecondaryProductID)
		)
	)

 
-- Remove duplicate results for vendorlocations that are caused by multiple product matches 
-- TP: 4/21 Removed previous record deletion logic that was no longer needed and added this logic to fix issue with mobile mechanic vendors appearing multiple times
DELETE ISPDetail1
FROM #IspDetail ISPDetail1 
WHERE NOT EXISTS (
	SELECT *
	FROM 
		(  
		Select VendorLocationID, Min(ProductID) MinProductID
		FROM #IspDetail
		Group by VendorLocationID 
		) ISPDetail2 
	WHERE ISPDetail1.VendorLocationID = ISPDetail2.VendorLocationID 
		AND ISPDetail1.ProductID  = ISPDetail2.MinProductID
	) 

  
 -- Select list of 'Do Not Use' vendors within the 'Do Not Use' search radius of the service location 
INSERT INTO #ISPDoNotUse 
SELECT	v.ID VendorID  
		,vl.ID VendorLocationID 
		,NULL 
		,vl.Latitude  
		,vl.Longitude  
		,v.Name VendorName  
		,v.VendorNumber  
		,CASE	WHEN v.VendorNumber IS NULL THEN 'Internet' 
				ELSE 'Database' 
		END AS [Source]  
		,'Not Contracted' AS ContractStatus  
		,addr.Line1 Address1  
		,addr.Line2 Address2  
		,addr.City  
		,addr.StateProvince  
		,addr.PostalCode  
		,addr.CountryCode  
		,ph.PhoneNumber DispatchPhoneNumber  
		,'' AS FaxPhoneNumber  
		,'' AS OfficePhoneNumber 
		,'' AS CellPhoneNumber  -- CR : 1226
		,0 AS AdministrativeRating  
		,'' AS InsuranceStatus  
		,'' AS BusinessHours  
		,'' AS PaymentTypes
		,'' AS Comment  
		,0 AS ProductID  
		,'' AS ProductName  
		,NULL AS ProductRating  
		,ROUND(vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END)/1609.344,1) EnrouteMiles  
		,NULL AS EnrouteTimeMinutes
		,NULL AS ServiceMiles  
		,NULL AS ServiceTimeMinutes
		,NULL AS ReturnMiles  
		,NULL AS ReturnTimeMinutes
		,NULL AS EstimatedHours  
		,NULL AS BaseRate
		,NULL AS HourlyRate
		,NULL AS EnrouteRate
		,NULL AS EnrouteFreeMiles
		,NULL AS ServiceRate
		,NULL AS ServiceFreeMiles
		,NULL AS EstimatedPrice  
		,-99999 AS WiseScore  
		,'DoNotUse' AS CallStatus  
		,'' AS RejectReason  
		,'' AS RejectComment  
		,0 AS IsPossibleCallback  
FROM	dbo.VendorLocation vl   
JOIN	dbo.Vendor v ON vl.VendorID = v.ID   
JOIN	dbo.[AddressEntity] addr ON addr.EntityID = @VendorLocationEntityID AND addr.RecordID = vl.ID AND addr.AddressTypeID = @BusinessAddressTypeID  
JOIN	dbo.[PhoneEntity] ph ON ph.EntityID = @VendorLocationEntityID AND ph.RecordID = vl.ID AND ph.PhoneTypeID = @DispatchPhoneTypeID  
WHERE	v.IsActive = 'TRUE'  
AND		v.VendorStatusID = @DoNotUseVendorStatusID
AND		vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) <= @DNUSearchRadiusMiles * 1609.344  
AND		@IncludeDoNotUse = 'TRUE'  
ORDER BY vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END)  

-- DEBUG : SELECT * FROM #IspDetail

-- Create ISP Selection data set from ISP Details, adding additional data items and related contact logs 
INSERT INTO @ISPSelection 
SELECT	ISP.VendorID  
		,ISP.VendorLocationID  
		,ISP.VendorLocationVirtualID
		,ISP.Latitude  
		,ISP.Longitude  
		,ISP.VendorName  
		,ISP.VendorNumber  
		,ISP.[Source]  
		,ISNULL(MAX(ISP.ContractStatus), 'Not Contracted') ContractStatus  
		,addr.Line1 Address1  
		,addr.Line2 Address2  
		,addr.City  
		,addr.StateProvince  
		,addr.PostalCode  
		,addr.CountryCode  
		,ISP.DispatchPhoneNumber  
		,FaxPh.PhoneNumber FaxPhoneNumber
		,ph.PhoneNumber OfficePhoneNumber
		,cph.PhoneNumber CellPhoneNumber --  CR : 1226
		,ISP.AdministrativeRating  
		,ISP.InsuranceStatus  
		,CASE WHEN ISP.[IsOpen24Hours] = 1 THEN '24/7' 
		ELSE ISNULL(ISP.BusinessHours,'') END AS BusinessHours  
		,PaymentTypes.List AS PaymentTypes
		,ISP.Comment  
		,ISP.ProductID  
		,ISP.ProductName  
		,ISP.ProductRating  
		,ISP.EnrouteMiles  
		,(ISP.EnrouteMiles/40)*60 AS EnrouteTimeMinutes
		,ISP.ServiceMiles  
		,(ISP.ServiceMiles/40)*60 AS ServiceTimeMinutes
		,ISP.ReturnMiles  
		,(ISP.ReturnMiles/40)*60 AS ReturnTimeMinutes
		,SUM(1.5 + ROUND((ISP.EnrouteMiles + ISP.ServiceMiles + ISP.ReturnMiles)/40,2)) AS EstimatedHours  
		,SUM(CASE WHEN ISP.RateTypeName = 'Base' THEN ISP.RatePrice ELSE 0 END) AS BaseRate  
		,SUM(CASE WHEN ISP.RateTypeName = 'Hourly' THEN ISP.RatePrice ELSE 0 END) AS HourlyRate  
		,SUM(CASE WHEN ISP.RateTypeName = 'Enroute' THEN ISP.RatePrice ELSE 0 END) AS EnrouteRate  
		,SUM(CASE WHEN ISP.RateTypeName = 'EnrouteFree' THEN ISP.RateQuantity ELSE 0 END) AS EnrouteFreeMiles  
		,SUM(CASE WHEN ISP.RateTypeName = 'Service' THEN ISP.RatePrice ELSE 0 END) AS ServiceRate  
		,SUM(CASE WHEN ISP.RateTypeName = 'ServiceFree' THEN ISP.RateQuantity ELSE 0 END) AS ServiceFreeMiles  
		,ROUND(SUM(CASE   
						WHEN ISP.RateUnitOfMeasure = 'Each' THEN ISP.RatePrice   
						WHEN ISP.RateUnitOfMeasure = 'Hour' THEN ISP.RatePrice * (1.5 + ROUND((ISP.EnrouteMiles + ISP.ServiceMiles + ISP.ReturnMiles)/40,2))  
						WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity = 0 THEN ISP.RatePrice * ISP.EnrouteMiles  
						WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity = 0 THEN ISP.RatePrice * ISP.ServiceMiles  
						WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.EnrouteMiles THEN ISP.EnrouteMiles ELSE ISP.RateQuantity END)  
						WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.ServiceMiles THEN ISP.ServiceMiles ELSE ISP.RateQuantity END)  
						ELSE 0 
					END),2) EstimatedPrice  
		,ROUND((AdministrativeRating*@AdminWeight)+(ProductRating*@PerformWeight)-  
				(SUM(CASE   
						WHEN ISP.RateUnitOfMeasure = 'Each' THEN ISP.RatePrice   
						WHEN ISP.RateUnitOfMeasure = 'Hour' THEN ISP.RatePrice * (1.5 + ROUND((ISP.EnrouteMiles + ISP.ServiceMiles + ISP.ReturnMiles)/40,2))  
						WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity = 0 THEN ISP.RatePrice * ISP.EnrouteMiles  
						WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity = 0 THEN ISP.RatePrice * ISP.ServiceMiles  
						WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.EnrouteMiles THEN ISP.EnrouteMiles ELSE ISP.RateQuantity END)  
						WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.ServiceMiles THEN ISP.ServiceMiles ELSE ISP.RateQuantity END)  
						ELSE 0 
					END) * @CostWeight),2) as WiseScore  
		,CASE	WHEN ContactLogAction.VendorLocationID IS NULL THEN 'NotCalled'  
				WHEN ISNULL(ContactLogAction.Name,'') = '' THEN 'Called'  
				WHEN ISNULL(ContactLogAction.Name,'') = 'Accepted' THEN 'Accepted'  
				ELSE 'Rejected' 
		END AS CallStatus  
		,ContactLogAction.[Description] RejectReason  
		,ContactLogAction.[Comments] RejectComment  
		,ISNULL(ContactLogAction.IsPossibleCallback,0) AS IsPossibleCallback  
FROM	#IspDetail ISP  
LEFT JOIN	dbo.[AddressEntity] addr ON addr.EntityID = @VendorLocationEntityID AND addr.RecordID = ISP.VendorLocationID AND addr.AddressTypeID = @BusinessAddressTypeID  
LEFT OUTER JOIN  dbo.[PhoneEntity] Faxph ON Faxph.EntityID = @VendorLocationEntityID AND Faxph.RecordID = ISP.VendorLocationID AND Faxph.PhoneTypeID = @FaxPhoneTypeID  
LEFT OUTER JOIN  dbo.[PhoneEntity] ph ON ph.EntityID = @VendorEntityID AND ph.RecordID = ISP.VendorID AND ph.PhoneTypeID = @OfficePhoneTypeID  
LEFT OUTER JOIN  dbo.[PhoneEntity] cph ON cph.EntityID = @VendorLocationEntityID AND cph.RecordID = ISP.VendorLocationID AND cph.PhoneTypeID = @CellPhoneTypeID  
-- Get last ContactLog result for the current sevice request for the ISP
LEFT OUTER JOIN (  
					SELECT	LastISPContactLog.VendorLocationID  
							,LastContactLogAction.Name  
							,LastContactLogAction.[Description]  
							,cl.Comments  
							,ISNULL(cl.IsPossibleCallback,0) IsPossibleCallback  
					FROM	dbo.ContactLog cl  
					JOIN (
							SELECT	ISPcll.RecordID VendorLocationID, MAX(cl.ID) ID 
							FROM	dbo.ContactLog cl  
							JOIN	dbo.ContactLogLink SRcll ON SRcll.ContactLogID = cl.ID AND SRcll.EntityID = @ServiceRequestEntityID AND SRcll.RecordID = @ServiceRequestID   
							JOIN dbo.ContactLogLink ISPcll ON ISPcll.ContactLogID = cl.ID AND ISPcll.EntityID = @VendorLocationEntityID  
							JOIN dbo.ContactLogReason clr ON clr.ContactLogID = cl.ID  
							JOIN dbo.ContactReason cr ON cr.ID = clr.ContactReasonID  
							WHERE cr.Name = 'ISP selection'  
							GROUP BY ISPcll.RecordID
						) LastISPContactLog ON LastISPContactLog.ID = cl.ID
					LEFT OUTER JOIN (  
							SELECT	cla.ContactLogID
									,ca.Name
									,ca.[Description]
									,cla.Comments  
							FROM	dbo.ContactLogAction cla  
							JOIN	dbo.ContactAction ca ON ca.ID = cla.ContactActionID  
							JOIN	(  
										SELECT	cla1.ContactLogID, MAX(cla1.ID) ID  
										FROM	dbo.ContactLogAction cla1  
										GROUP BY cla1.ContactLogID  
									) MaxContactLogAction ON MaxContactLogAction.ContactLogID = cla.ContactLogID AND MaxContactLogAction.ID = cla.ID  
						) LastContactLogAction ON LastContactLogAction.ContactLogID = cl.ID 
				) ContactLogAction ON ContactLogAction.VendorLocationID = ISP.VendorLocationID  
-- Get Payment Types accepted by this vendor				
LEFT OUTER JOIN (  
	SELECT
	   pt1.VendorLocationID,
	   List = stuff((SELECT ( ', ' + [Description] )
			  FROM (Select vlpt.VendorLocationID, pt.Name, pt.Sequence, pt.[Description] 
					From VendorLocationPaymentType vlpt
					Join PaymentType pt on vlpt.PaymentTypeID = pt.ID
					) pt2
			  WHERE pt1.VendorLocationID = pt2.VendorLocationID
			  ORDER BY VendorLocationID, pt2.Sequence
				FOR XML PATH( '' )
			), 1, 1, '' )
			FROM 
				(Select vlpt.VendorLocationID, pt.Name
				From VendorLocationPaymentType vlpt
				Join #IspDetail ISP on ISP.VendorLocationID = vlpt.VendorLocationID
				Join PaymentType pt on vlpt.PaymentTypeID = pt.ID
				) pt1
	GROUP BY pt1.VendorLocationID
	) PaymentTypes ON PaymentTypes.VendorLocationID = ISP.VendorLocationID
GROUP BY  
			ISP.VendorID  
			,ISP.VendorLocationID  
			,ISP.VendorLocationVirtualID
			,ISP.Latitude  
			,ISP.Longitude  
			,ISP.VendorName  
			,ISP.VendorNumber  
			,ISP.[Source]  
			,addr.Line1   
			,addr.Line2   
			,addr.City  
			,addr.StateProvince  
			,addr.PostalCode  
			,addr.CountryCode  
			,ISP.DispatchPhoneNumber  
			,Faxph.PhoneNumber
			,ph.PhoneNumber 
			,cph.PhoneNumber 
			,ISP.AdministrativeRating  
			,ISP.InsuranceStatus  
			,ISP.[IsOpen24Hours]  
			,ISP.BusinessHours  
			,ISP.Comment  
			,ISP.ProductID  
			,ISP.ProductName  
			,ISP.ProductRating  
			,ISP.EnrouteMiles  
			,ISP.ServiceMiles  
			,ISP.ReturnMiles  
			,ISP.IsProductMatch  
			,ContactLogAction.VendorLocationID  
			,ContactLogAction.[Description]   
			,ContactLogAction.Comments   
			,ISNULL(ContactLogAction.Name ,'')
			,ContactLogAction.IsPossibleCallback  
			,PaymentTypes.List
ORDER BY 
			WiseScore DESC
			,EstimatedPrice
			,EnrouteMiles
			,ProductRating DESC  
 
 -- Log ISP SELECTION Results (first resultset).
 INSERT INTO ISPSelectionLog
            ([VendorID]
           ,[VendorLocationID]
           ,[VendorLocationVirtualID]
           ,[SelectionOrder]
           ,[ServiceRadiusMiles]
           ,[Latitude]
           ,[Longitude]
           ,[VendorName]
           ,[VendorNumber]
           ,[Source]
           ,[ContractStatus]
           ,[Address1]
           ,[Address2]
           ,[City]
           ,[StateProvince]
           ,[PostalCode]
           ,[CountryCode]
           ,[DispatchPhoneNumber]
           ,[FaxPhoneNumber]
           ,[OfficePhoneNumber]
           ,[CellPhoneNumber]
           ,[AdministrativeRating]
           ,[InsuranceStatus]
           ,[BusinessHours]
           ,[PaymentTypes]
           ,[Comment]
           ,[ProductID]
           ,[ProductName]
           ,[ProductRating]
           ,[EnrouteMiles]
           ,[EnrouteTimeMinutes]
           ,[ServiceMiles]
           ,[ServiceTimeMinutes]
           ,[ReturnMiles]
           ,[ReturnTimeMinutes]
           ,[EstimatedHours]
           ,[BaseRate]
           ,[HourlyRate]
           ,[EnrouteRate]
           ,[EnrouteFreeMiles]
           ,[ServiceRate]
           ,[ServiceFreeMiles]
           ,[EstimatedPrice]
           ,[WiseScore]
           ,[CallStatus]
           ,[RejectReason]
           ,[RejectComment]
           ,[IsPossibleCallback]
           ,[ProductSearchRadiusMiles]
           ,[IsInProductSearchRadius]
           ,[ServiceRequestID]
           ,[LogTime]
           ,[Resultset])
 SELECT 
		VendorID  
		,VendorLocationID  
		,VendorLocationVirtualID
		,row_number() OVER(ORDER BY WiseScore DESC
			,EstimatedPrice
			,EnrouteMiles
			,ProductRating DESC) AS SelectionOrder
		,@ProductSearchRadiusMiles
		,Latitude  
		,Longitude  
		,VendorName  
		,VendorNumber  
		,[Source]  
		,ContractStatus  
		,Address1  
		,Address2  
		,City  
		,StateProvince  
		,PostalCode  
		,CountryCode  
		,DispatchPhoneNumber  
		,FaxPhoneNumber
		,OfficePhoneNumber  
		,CellPhoneNumber
		,AdministrativeRating  
		,InsuranceStatus  
		,BusinessHours  
		,PaymentTypes
		,Comment  
		,ProductID  
		,ProductName  
		,ProductRating  
		,EnrouteMiles  
		,EnrouteTimeMinutes
		,ServiceTimeMinutes
		,ReturnMiles  
		,ReturnTimeMinutes
		,EstimatedHours  
		,BaseRate
		,HourlyRate
		,EnrouteRate
		,EnrouteFreeMiles
		,ServiceRate
		,ServiceMiles
		,ServiceFreeMiles
		,EstimatedPrice  
		,WiseScore  
		,CallStatus  
		,RejectReason  
		,RejectComment  
		,IsPossibleCallback
		,@ProductSearchRadiusMiles AS ProductSearchRadiusMiles
		,NULL AS IsInProductSearchRadius
		,@ServiceRequestID
		,@now
		,'ISPSELECTION'  
 FROM @ISPSelection 
 WHERE @LogISPSelection = 1
 
 
-- Combine ISP Selection and ISP Do Not use results   
-- Collect products in a separate query 
INSERT INTO @ISPSelectionFinalResults  
SELECT	TOP 50  
		I.VendorID  
		,I.VendorLocationID  
		,VendorLocationVirtualID
		,Latitude  
		,Longitude  
		,VendorName  
		,VendorNumber  
		,[Source]  
		,ContractStatus  
		,Address1  
		,Address2  
		,City  
		,StateProvince  
		,PostalCode  
		,CountryCode  
		,DispatchPhoneNumber  
		,FaxPhoneNumber
		,OfficePhoneNumber  
		,CellPhoneNumber
		,AdministrativeRating  
		,InsuranceStatus  
		,BusinessHours  
		,PaymentTypes
		,Comment  
		,ProductID  
		,ProductName  
		,ProductRating  
		,EnrouteMiles  
		,EnrouteTimeMinutes
		,ServiceMiles
		,ServiceTimeMinutes
		,ReturnMiles  
		,ReturnTimeMinutes
		,EstimatedHours  
		,BaseRate
		,HourlyRate
		,EnrouteRate
		,EnrouteFreeMiles
		,ServiceRate
		,ServiceFreeMiles
		,EstimatedPrice  
		,WiseScore  
		,CallStatus  
		,RejectReason  
		,RejectComment  
		,IsPossibleCallback
		,'' AS [AllServices]
		,@ProductSearchRadiusMiles AS ProductSearchRadiusMiles
		,CASE WHEN (I.EnrouteMiles <= @ProductSearchRadiusMiles) OR Top3Contracted.VendorLocationID IS NOT NULL THEN 1 ELSE 0 END AS IsInProductSearchRadius 
FROM	@ISPSelection I
-- Identify top 3 contracted vendors
LEFT OUTER JOIN (
	SELECT TOP 3 VendorLocationID
	FROM @ISPSelection
	WHERE ContractStatus = 'Contracted'
	ORDER BY EnrouteMiles ASC, WiseScore DESC
	) Top3Contracted ON Top3Contracted.VendorLocationID = I.VendorLocationID
-- Apply product availability filtering (@ProductIDs list)
WHERE EXISTS	(
					SELECT	*
					FROM	VendorLocation vl
					JOIN	VendorLocationProduct vlp 
					ON		vlp.VendorLocationID = vl.ID
					JOIN	Product p on p.ID = vlp.ProductID 
					WHERE	vl.ID = I.VendorLocationID
					AND		(	ISNULL(@productIDs,'') = '' 
								OR  
								p.ID IN (SELECT item from [dbo].[fnSplitString](@productIDs,','))
							)
				)

ORDER BY WiseScore DESC, EstimatedPrice, EnrouteMiles, ProductRating DESC  

/* Add 'Do Not Use' vendors to the results (if selected above) */
INSERT INTO @ISPSelectionFinalResults
SELECT	TOP 100  
		I.VendorID  
		,VendorLocationID  
		,VendorLocationVirtualID
		,Latitude  
		,Longitude  
		,VendorName  
		,VendorNumber  
		,[Source]  
		,ContractStatus  
		,Address1  
		,Address2  
		,City  
		,StateProvince  
		,PostalCode  
		,CountryCode  
		,DispatchPhoneNumber  
		,FaxPhoneNumber
		,OfficePhoneNumber  
		,CellPhoneNumber
		,AdministrativeRating  
		,InsuranceStatus  
		,BusinessHours  
		,PaymentTypes
		,Comment  
		,ProductID  
		,ProductName  
		,ProductRating  
		,EnrouteMiles  
		,EnrouteTimeMinutes
		,ServiceTimeMinutes
		,ReturnMiles  
		,ReturnTimeMinutes
		,EstimatedHours  
		,BaseRate
		,HourlyRate
		,EnrouteRate
		,EnrouteFreeMiles
		,ServiceRate
		,ServiceMiles
		,ServiceFreeMiles
		,EstimatedPrice  
		,WiseScore  
		,CallStatus  
		,RejectReason  
		,RejectComment  
		,IsPossibleCallback
		, '' AS [AllServices] 
		,@ProductSearchRadiusMiles AS ProductSearchRadiusMiles
		,0 AS IsInProductSearchRadius
FROM	#ISPDoNotUse I
ORDER BY WiseScore DESC, EstimatedPrice, EnrouteMiles, ProductRating DESC  
 
-- Get all the products for the vendors collected in the above query.
;WITH wVLP
AS
(
	SELECT	vl.VendorID,
			vl.ID, 
			[dbo].[fnConcatenate](p.Name) AS AllServices
	FROM	VendorLocation vl
	JOIN	VendorLocationProduct vlp on vlp.VendorLocationID = vl.ID
	JOIN	Product p on p.ID = vlp.ProductID
	JOIN	@ISPSelectionFinalResults ISP ON vl.ID = ISP.VendorLocationID AND vl.VendorID = ISP.VendorID
	WHERE	vlp.IsActive = 1
	GROUP BY vl.VendorID,vl.ID
)
 
 -- Include 'All Services' provided by the selected ISPs in the results
UPDATE	@ISPSelectionFinalResults
SET		AllServices = W.AllServices
FROM	wVLP W,
		@ISPSelectionFinalResults ISP
WHERE	W.VendorID = ISP.VendorID
AND		W.ID = VendorLocationID

-- Remove Black Listed vendors from the result for this member
DELETE FROM @ISPSelectionFinalResults
WHERE VendorID IN	(
						SELECT VendorID
						FROM MembershipBlackListVendor
						WHERE MembershipID = @MembershipID
					)

/* Insert reults into ISP Selection log */
INSERT INTO ISPSelectionLog
            ([VendorID]
           ,[VendorLocationID]
           ,[VendorLocationVirtualID]
           ,[SelectionOrder]
           ,[ServiceRadiusMiles]
           ,[Latitude]
           ,[Longitude]
           ,[VendorName]
           ,[VendorNumber]
           ,[Source]
           ,[ContractStatus]
           ,[Address1]
           ,[Address2]
           ,[City]
           ,[StateProvince]
           ,[PostalCode]
           ,[CountryCode]
           ,[DispatchPhoneNumber]
           ,[FaxPhoneNumber]
           ,[OfficePhoneNumber]
           ,[CellPhoneNumber]
           ,[AdministrativeRating]
           ,[InsuranceStatus]
           ,[BusinessHours]
           ,[PaymentTypes]
           ,[Comment]
           ,[ProductID]
           ,[ProductName]
           ,[ProductRating]
           ,[EnrouteMiles]
           ,[EnrouteTimeMinutes]
           ,[ServiceMiles]
           ,[ServiceTimeMinutes]
           ,[ReturnMiles]
           ,[ReturnTimeMinutes]
           ,[EstimatedHours]
           ,[BaseRate]
           ,[HourlyRate]
           ,[EnrouteRate]
           ,[EnrouteFreeMiles]
           ,[ServiceRate]
           ,[ServiceFreeMiles]
           ,[EstimatedPrice]
           ,[WiseScore]
           ,[CallStatus]
           ,[RejectReason]
           ,[RejectComment]
           ,[IsPossibleCallback]
           ,[ProductSearchRadiusMiles]
           ,[IsInProductSearchRadius]
           ,[ServiceRequestID]
           ,[LogTime]
           ,[Resultset])
SELECT ISP.VendorID  
		,ISP.VendorLocationID 
		,ISP.VendorLocationVirtualID 
		,row_number() OVER(ORDER BY 
			ISP.IsInProductSearchRadius DESC,
			ISP.WiseScore DESC, 
			ISP.EstimatedPrice, 
			ISP.EnrouteMiles, 
			ISP.ProductRating DESC) AS SelectionOrder
		,@ProductSearchRadiusMiles
		,Latitude  
		,Longitude  
		,VendorName  
		,VendorNumber  
		,[Source]  
		,ContractStatus  
		,Address1  
		,Address2  
		,City  
		,StateProvince  
		,PostalCode  
		,CountryCode  
		,DispatchPhoneNumber  
		,FaxPhoneNumber
		,OfficePhoneNumber  
		,CellPhoneNumber
		,AdministrativeRating  
		,InsuranceStatus  
		,BusinessHours  
		,PaymentTypes
		,Comment  
		,ProductID  
		,ProductName  
		,ProductRating  
		,EnrouteMiles  
		,EnrouteTimeMinutes
		,ServiceTimeMinutes
		,ReturnMiles  
		,ReturnTimeMinutes
		,EstimatedHours  
		,BaseRate
		,HourlyRate
		,EnrouteRate
		,EnrouteFreeMiles
		,ServiceRate
		,ServiceMiles
		,ServiceFreeMiles
		,EstimatedPrice  
		,WiseScore  
		,CallStatus  
		,RejectReason  
		,RejectComment  
		,IsPossibleCallback
		,ProductSearchRadiusMiles
		,IsInProductSearchRadius
		,@ServiceRequestID
		,@now
		,'ISPSELECTION_FINAL'  
FROM @ISPSelectionFinalResults ISP
WHERE @LogISPSelectionFinal = 1
ORDER BY	
	ISP.IsInProductSearchRadius DESC,
	ISP.WiseScore DESC, 
	ISP.EstimatedPrice, 
	ISP.EnrouteMiles, 
	ISP.ProductRating DESC 

/* Return results */
SELECT	ISP.* 
FROM	@ISPSelectionFinalResults ISP
ORDER BY	
	ISP.IsInProductSearchRadius DESC,
	ISP.WiseScore DESC, 
	ISP.EstimatedPrice, 
	ISP.EnrouteMiles, 
	ISP.ProductRating DESC 

DROP TABLE #IspDoNotUse
DROP TABLE #IspDetail
DROP TABLE #tmpVendorLocation
DROP TABLE #MarketRates

END
GO