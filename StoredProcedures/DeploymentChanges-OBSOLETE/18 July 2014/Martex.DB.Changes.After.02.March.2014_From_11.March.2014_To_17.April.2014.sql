-- Martex DB Changes After 02 March 2014


-- File : DBChanges.2014.03.04.sql Last Updated : 11 March 2014
Print 'VendorInvoice schema changes'
GO

ALTER TABLE VendorInvoice ALTER COLUMN BillingContactName  nvarchar(100)
GO

ALTER TABLE VendorInvoice ALTER COLUMN BillingBusinessName NVARCHAR(255)
GO

--BUG 167
Print 'TemporaryCreditCard schema changes'
GO
ALTER TABLE TemporaryCreditCard ADD LastChargedDate DATETIME NULL
GO

--Bug 169
ALTER TABLE TemporaryCreditCard ADD IsExceptionOverride bit 
GO

--CR --165
Print 'TemporaryCreditCard_Import schema changes'
GO
ALTER TABLE TemporaryCreditCard_Import ALTER COLUMN CPN_PAN_CreditCardNumber NVARCHAR(50) NULL
GO
ALTER TABLE TemporaryCreditCard_Import ADD PURCHASE_TYPE NVARCHAR(100) NULL
GO


Print 'ServiceRequest schema changes'
GO
ALTER TABLE ServiceRequest ADD PartsAndAccessoryCode NVARCHAR(50) NULL

ALTER TABLE ServiceRequest ADD CurrencyTypeID INT NULL

ALTER TABLE ServiceRequest ADD PrimaryCoverageLimit MONEY NULL

ALTER TABLE ServiceRequest ADD SecondaryCoverageLimit MONEY NULL

ALTER TABLE ServiceRequest ADD MileageUOM NVARCHAR(50) NULL

ALTER TABLE ServiceRequest ADD PrimaryCoverageLimitMileage INT NULL

ALTER TABLE ServiceRequest ADD SecondaryCoverageLimitMileage INT NULL

--ALTER TABLE ServiceRequest ADD IsServiceEligible BIT NULL

--ALTER TABLE ServiceRequest ADD ServiceCoverageDescription NVARCHAR(2000) NULL

--ALTER TABLE ServiceRequest ADD ServiceEligiblityMessage NVARCHAR(225) NULL

--ALTER TABLE ServiceRequest ADD IsServiceCovered BIT NULL

ALTER TABLE ServiceRequest ADD IsServiceGuaranteed BIT NULL

ALTER TABLE ServiceRequest ADD IsReimbursementOnly  BIT NULL

ALTER TABLE ServiceRequest ADD IsServiceCoverageBestValue BIT NULL

ALTER TABLE ServiceRequest ADD ProgramServiceEventLimitID INT NULL

ALTER TABLE ServiceRequest ADD PrimaryServiceCoverageDescription  NVARCHAR(2000) NULL

ALTER TABLE ServiceRequest ADD SecondaryServiceCoverageDescription NVARCHAR(2000) NULL

ALTER TABLE ServiceRequest ADD PrimaryServiceEligiblityMessage NVARCHAR(255) NULL

ALTER TABLE ServiceRequest ADD SecondaryServiceEligiblityMessage NVARCHAR(255) NULL

ALTER TABLE ServiceRequest ADD IsPrimaryOverallCovered  bit null

ALTER TABLE ServiceRequest ADD IsSecondaryOverallCovered  bit null
GO

ALTER TABLE [dbo].[ServiceRequest]  WITH CHECK ADD  CONSTRAINT [FK_ServiceRequest_CurrencyType] FOREIGN KEY([CurrencyTypeID])
REFERENCES [dbo].[CurrencyType] ([ID])
GO

ALTER TABLE [dbo].[ServiceRequest] CHECK CONSTRAINT [FK_ServiceRequest_CurrencyType]
GO


Print 'Purchase Order schema changes'
GO
Alter table PurchaseOrder Add CoverageLimitMileage money NULL

Alter table PurchaseOrder Add MileageUOM  NVARCHAR(50) NULL

Alter table PurchaseOrder Add IsServiceCoverageBestValue BIT NULL

Alter table PurchaseOrder Add ServiceEligibilityMessage  nvarchar(255) NULL

ALTER TABLE PurchaseOrder ADD IsServiceCoveredOverridden BIT NULL
GO

sp_RENAME 'PurchaseOrder.DipatchFeeBillToID', 'DispatchFeeBillToID' , 'COLUMN'
GO

--Bug 161
Print 'Data Fix - Correct PurchaseOrder ContractStatus values'
GO
UPDATE PurchaseOrder 
SET ContractStatus = 'Not Contracted'
WHERE ContractStatus = 'NotContracted'
GO

 

Print 'Claim schema changes'
GO
ALTER TABLE Claim ADD ACESFeeAmount MONEY NULL
GO


Print 'Membership schema changes'
GO
Alter table dbo.Membership Add AltMembershipNumber varchar(40) NULL
GO


-- File : DBChanges.2014.04.01.sql  Last Updated : 01 April 2014
Print 'ProgramProduct schema changes'
GO
ALTER TABLE ProgramProduct ADD IsServiceGuaranteed BIT NULL

ALTER TABLE ProgramProduct ADD ServiceCoverageDescription NVARCHAR(2000) NULL 

ALTER TABLE ProgramProduct ADD CurrencyTypeID INT NULL

ALTER TABLE ProgramProduct ADD ServiceMileageLimitUOM NVARCHAR(50) NULL
GO
EXEC sp_RENAME 'ProgramProduct.IsReimbersementOnly' , 'IsReimbursementOnly', 'COLUMN'
GO
ALTER TABLE [dbo].[ProgramProduct]  WITH CHECK ADD  CONSTRAINT [FK_ProgramProduct_CurrencyType] FOREIGN KEY([CurrencyTypeID])
REFERENCES [dbo].[CurrencyType] ([ID])
GO

ALTER TABLE [dbo].[ProgramProduct] CHECK CONSTRAINT [FK_ProgramProduct_CurrencyType]
GO

Print 'NextAction schema changes'
GO
ALTER TABLE NextAction ADD DefaultScheduleDateInterval INT NULL
ALTER TABLE NextAction ADD DefaultScheduleDateIntervalUOM NVARCHAR(20) NULL
GO

INSERT INTO NextAction Values(NULL,'CreditCardNeeded','Credit Card Needed',NULL,1,NULL,0,'Seconds')
GO


Print 'ProductCategory schema changes'
GO
ALTER TABLE ProductCategory ADD IsVehicleRequired BIT NULL
GO

Print 'ProductCategory set IsVehicleRequired value'
GO
UPDATE ProductCategory SET IsVehicleRequired=0 WHERE Name IN ('Info','Concierge', 'Home Locksmith')
UPDATE ProductCategory SET IsVehicleRequired=1 WHERE Name IN ('Tow','Tire','Lockout','Fluid','Jump','Winch','Mobile','Tech')
GO




-- CR --163
Print 'Add ServiceRequestException table'
GO 
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ServiceRequestException]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[ServiceRequestException](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ServiceRequestID] [int] NOT NULL,
	[RequestArea] [nvarchar](50) NULL,
	[ExceptionMessage] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_ServiceRequestException] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO

ALTER TABLE [dbo].[ServiceRequestException]  WITH CHECK ADD  CONSTRAINT [FK_ServiceRequestException_ServiceRequest] FOREIGN KEY([ServiceRequestID])
REFERENCES [dbo].[ServiceRequest] ([ID])
GO

ALTER TABLE [dbo].[ServiceRequestException] CHECK CONSTRAINT [FK_ServiceRequestException_ServiceRequest]
GO


Print 'Add Vendor Portal Securable MENU_LEFT_ISP_IMPERSONATE'
GO
DECLARE @sysAdminRoleID UNIQUEIDENTIFIER
SET		@sysAdminRoleID = (SELECT RoleID FROM aspnet_Roles WHERE LoweredRoleName = 'sysadmin' AND ApplicationId = (SELECT ApplicationId FROM aspnet_Applications WHERE LoweredApplicationName = 'VendorPortal'))

IF NOT EXISTS (SELECT * FROM Securable where FriendlyName = 'MENU_LEFT_ISP_IMPERSONATE')
BEGIN
INSERT INTO Securable(FriendlyName,ParentID) VALUES('MENU_LEFT_ISP_IMPERSONATE',(Select ID from Securable where FriendlyName='MENU_TOP_ADMIN'))
INSERT INTO AccessControlList(SecurableID,RoleID,AccessTypeID) VALUES(SCOPE_IDENTITY(),@sysAdminRoleID,(SELECT ID FROM AccessType WHERE Name = 'ReadWrite')) 
END

GO


Print 'Coach-Net Dealer Partner changes'
GO
-- File : DBChanges.2014.03.18.sql Last Updated : 18 March 2014
--
-- SCRIPT for setting up Coach-Net Dealer Partner logic
--

IF NOT EXISTS (SELECT * FROM Product WHERE Name = 'CoachNet Dealer Partner')
	BEGIN
		INSERT [dbo].[Product]
			( [ProductCategoryID]
			, [ProductTypeID]
			, [ProductSubTypeID]
			, [VehicleTypeID]
			, [VehicleCategoryID]
			, [Name]
			, [Description]
			, [Sequence]
			, [IsActive]
			, [CreateDate]
			, [CreateBy]
			, [ModifyDate]
			, [ModifyBy]
			, [IsShowOnPO]
			, [AccountingSystemGLCode]
			, [AccountingSystemItemCode]
			)
		VALUES
			( 
			 (SELECT ID FROM ProductCategory WHERE Name = 'Repair')
			, (SELECT ID FROM ProductType WHERE Name = 'Attribute')
			, (SELECT ID FROM ProductSubType WHERE Name = 'Client')
			, NULL
			, NULL
			, 'CoachNet Dealer Partner'
			, 'CoachNet Dealer Partner'
			, 0
			, 1
			, getdate()
			, 'System'
			, NULL
			, NULL
			, 0
			, NULL
			, NULL
			)
	END
GO

IF NOT EXISTS ( SELECT * FROM ProductISPSelectionRadius WHERE ProductID = (SELECT ID FROM Product WHERE Name = 'CoachNet Dealer Partner') )
BEGIN

INSERT INTO [dbo].[ProductISPSelectionRadius]
           ([ProductID]
           ,[MetroRadius]
           ,[RuralRadius])
     VALUES
           ((SELECT ID FROM Product WHERE Name = 'CoachNet Dealer Partner')
           ,25
           ,50)

END
GO

-- Add program configuration for Coach-Net and all MFGs
DECLARE @ProgramID INT

DECLARE db_cursor CURSOR FOR
	SELECT	COALESCE(pp.id, p.id) AS ProgramID
			--, COALESCE(pp.name, p.name) AS ProgramName
	FROM	MemberSearchProgramGrouping g
	JOIN	Program p ON p.id = g.ProgramID
	LEFT JOIN	Program pp on pp.ID = p.ParentProgramID
	JOIN	Client c on c.ID = p.ClientID
	WHERE	c.Name NOT LIKE '%Coach-Net%'
	GROUP BY COALESCE(pp.id, p.id), COALESCE(pp.name, p.name)

	UNION
	SELECT ID as ProgramID
		--,Name as ProgramName
	FROM Program
	WHERE Name = 'Coach-Net'
	
OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @ProgramID   

WHILE @@FETCH_STATUS = 0   
BEGIN   
	-- Add program configuration item 
	IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'ServiceLocationPreferredProduct')
		BEGIN
			INSERT [dbo].[ProgramConfiguration]
				([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
			VALUES 
				( @ProgramID
				, (SELECT ID FROM ConfigurationType WHERE Name = 'Application')
				, (SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation')
				, NULL
				, NULL
				, 'ServiceLocationPreferredProduct'
				, (SELECT ID FROM Product WHERE Name = 'CoachNet Dealer Partner')
				, 1
				, 1
				, getdate()
				, 'System'
				, NULL
				, NULL
				)
		END

    FETCH NEXT FROM db_cursor INTO @ProgramID   
END		

CLOSE db_cursor   
DEALLOCATE db_cursor

GO


CREATE TABLE #CoachNetDealerPartner_List(
	[VendorID] [int] NULL,
	[VendorNumber] [nvarchar](50) NULL,
	[Name] [nvarchar](50) NULL,
	[City] [nvarchar](50) NULL,
	[State] [nvarchar](2) NULL
) 

INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AB109922', N'LACOMBE RV', N'LACOMBE COUNTY', N'AB')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AB109933', N'WESTERN RV COUNTRY', N'RED DEER', N'AB')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AB117803', N'RANGELAND RV & TRAILER SALES', N'BALZAC', N'AB')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AB129679', N'HOLIDAY RV SUPER CENTRE', N'REDCLIFF', N'AB')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AB164421', N'BUCARS RV CENTRE', N'BALZAC', N'AB')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AB209525', N'CANADA RV FINANCE.COM', N'INNISFAIL', N'AB')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AB209527', N'ELDORADO RV', N'LETHBRIDGE', N'AB')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AB35403', N'GUARANTEE RV CENTRE', N'CALGARY', N'AB')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AB40877', N'RV CITY', N'MORINVILLE', N'AB')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AB40905', N'VELLNER LEISURE PRODUCTS', N'RED DEER', N'AB')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AB47596', N'WOODYS RV WORLD', N'RED DEER', N'AB')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AL128454', N'DANDY RV SUPERSTORE', N'ANNISTON', N'AL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AL21149', N'BANKSTON MOTOR HOMES', N'HUNTSVILLE', N'AL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AL27218', N'BURTON CAMPERS, INC', N'Calera', N'AL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AL48462', N'MADISON RV CENTER, INC.', N'MADISON', N'AL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AL48610', N'REED CAMPER SALES', N'Huntsville', N'AL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AZ169963', N'Integrity Rv', N'Mesa', N'Az')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AZ209521', N'AUTO CORRAL RV', N'MESA', N'AZ')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AZ209541', N'LAZY DAYS RV CENTER, INC.', N'TUCSON', N'AZ')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AZ218169', N'USA RV & MARINE INC', N'Lake Havasu City', N'AZ')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AZ48742', N'Cowboy Rv Mart', N'Lake Havasu City', N'Az')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AZ48818', N'AFFINITY RV INC', N'PRESCOT', N'AZ')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AZ48860', N'Home Town RV', N'Yuma', N'Az')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'AZ48939', N'SUNSHINE RV', N'Lake Havasu City', N'AZ')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'BC180770', N'TRAVELAND RV SUPERSTORE', N'LANGLEY', N'BC')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'BC180642', N'OCONNOR RV CENTRE', N'CHILLIWACK', N'BC')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'BC35434', N'VOYAGER RV CENTRE', N'WINFIELD', N'BC')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'BC35818', N'BIG BOYS TOYS LTD', N'NANOOSE BAY', N'BC')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'BC45771', N'FRASERWAY RV - PARENT', N'ABBOTSFORD', N'BC')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'BC48575', N'ARBUTUS RV & MARINE SALES', N'SIDNEY', N'BC')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'BC48585', N'MIKE ROSMAN RV SALES', N'Vernon', N'BC')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CA100587', N'RVS OF SACRAMENTO', N'SACRAMENTO', N'CA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CA103499', N'SKY RIVER RV', N'PASO ROBLES', N'CA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CA108293', N'DEMARTINI RV SALES', N'GRASS VALLEY', N'CA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CA110145', N'RICHARDSON RV CENTER', N'RIVERSIDE', N'CA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CA110145', N'RICHARDSON RV CENTER', N'RIVERSIDE', N'CA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CA11795', N'SIMI RV', N'SIMI VALLEY', N'CA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CA13636', N'PAUL EVERTS RV COUNTRY - FRESNO', N'FRESNO', N'CA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CA200192', N'RV SOLUTIONS', N'SAN DIEGO', N'CA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CA209534', N'ESC ADVISORS', N'SAN DIEGO', N'CA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CA209543', N'NATIONAL AUTO AND RV', N'NORCO', N'CA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CA209545', N'NIELS MOTOR HOMES', N'NORTH HILLS', N'CA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CA29577', N'HAPPY DAZE RVS', N'SACRAMENTO', N'CA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CA43874', N'MANTECA TRAILER & MOTORHOME', N'Manteca', N'CA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CA50196', N'RICHARDSON RV CENTER', N'MENIFEE', N'CA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CA50335', N'FOLSOM LAKE RV', N'RANCHO CORDOVA', N'CA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CO10154', N'PIKES PEAK TRAVELAND, INC.', N'COLORADO SPRINGS', N'CO')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CO143529', N'TRANSWEST TRUCK TRAILER RV', N'FREDERICK', N'CO')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CO159924', N'RV AMERICA', N'AURORA', N'CO')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'CO48390', N'STEVE CASEYS RECL SALES RV', N'WHEAT RIDGE', N'CO')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL10212', N'HOLIDAY RV', N'KEY LARGO', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL10261', N'LAZY DAYS RV CENTER, INC.', N'SEFFNER', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL110893', N'TROPICAL RV & AUTO EXCHANGE', N'FORT PIERCE', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL11105', N'RV WORLD OF NOKOMIS', N'NOKOMIS', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL115396', N'ALLIANCE COACH RV', N'Wildwood', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL120968', N'CAMP-OUT', N'MIAMI', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL128942', N'RV WORLD OF LAKELAND', N'LAKELAND', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL147000', N'CHARLOTTE RV', N'PORT CHARLOTTE', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL148312', N'FLORIDA RVS', N'JACKSONVILLE', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL169545', N'GREAT TIME RVS', N'PALM BEACH GARDENS', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL209537', N'FORT MYERS RV', N'FORT MYERS', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL211095', N'Alecs Truck, Trailer & RV', N'Miami', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL32283', N'LEISURE TIME RV', N'WINTER GARDEN', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL36348', N'DICK GORES R.V. WORLD', N'JACKSONVILLE', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL42326', N'CAMPERS CONNECTION', N'FT PIERCE', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL42345', N'TRADEWINDS RV', N'OCALA', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL49211', N'BATES RV', N'DOVER', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL49239', N'LAND YACHTZ', N'JUPITER', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL49549', N'FLORIDA OUTDOORS RV CENTER', N'STUART', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'FL50100', N'CAMPBELL RV', N'Sarasota', N'FL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'GA164098', N'UNITED RV', N'Chatsworth', N'GA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'GA181502', N'ELLIS TRAVEL TRAILERS', N'Statesboro', N'GA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'GA181615', N'MID-STATE RV CENTER', N'BYRON', N'GA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'GA183494', N'RV WORLD OF GEORGIA', N'BUFORD', N'GA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'GA209563', N'RW CAMPER SALES', N'Dalton', N'GA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'IA123647', N'US ADVENTURE RV', N'DAVENPORT', N'IA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'ID207309', N'BRETZ RV - BOISE & NAMPA', N'BOISE', N'ID')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'ID209517', N'AIRSTREAM ADVENTURES NORTHWEST', N'NAMPA', N'ID')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'ID35108', N'NELSONS OUTWEST RV', N'BOISE', N'ID')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'ID35108', N'NELSONS RV', N'Boise', N'ID')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'IL106695', N'COLMANS CAMPERS', N'SPRINGFIELD', N'IL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'IL156466', N'REND LAKE RV', N'BENTON', N'IL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'IL26495', N'LARRYS TRAILER SALES', N'ZEIGLER', N'IL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'IL44544', N'PONTIAC RV', N'PONTIAC', N'IL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'IL48653', N'BARRINGTON MOTOR SALES', N'BARTLETT', N'IL')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'IN12071', N'TOM RAPER', N'RICHMOND', N'IN')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'IN128364', N'CAMP-LAND RV', N'BURNS HARBOR', N'IN')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'IN209542', N'MAYES REMARKETING', N'WHITELAND', N'IN')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'IN209555', N'PETES RV CENTER', N'SCHERERVILLE', N'IN')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'KY209548', N'OWENSBORO RV', N'Owensboro', N'KY')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'KY29611', N'SUMMIT RV', N'ASHLAND', N'KY')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'KY48800', N'SKAGGS RV COUNTRY', N'ELIZABETHTOWN', N'KY')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'LA10392', N'THE RV SHOP', N'BATON ROUGE', N'LA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'MA16576', N'MACDONALDS RV', N'PLAINVILLE', N'MA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'MI12228', N'NORTHTOWN MOTOR HOMES', N'ROCKFORD', N'MI')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'MI27257', N'VEURINKS RV CENTER', N'GRAND RAPIDS', N'MI')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'MN40508', N'PLEASURELAND RV', N'ST CLOUD', N'MN')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'MN48707', N'SHOREWOOD RV CENTER', N'ANOKA', N'MN')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'MO128332', N'BYERLY RV CENTER', N'EUREKA', N'MO')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'MO48479', N'BILL THOMAS CAMPER SALES', N'WENTZVILLE', N'MO')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'MS27177', N'RELIABLE RV CENTER', N'BILOXI', N'MS')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'MT12279', N'TOUR AMERICA', N'BILLINGS', N'MT')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'MT151730', N'PIERCE RV CENTER', N'KALISPELL', N'MT')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'MT32311', N'PIERCE RV CENTER', N'BILLINGS', N'MT')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'MT35366', N'BRETZ RV & MARINE', N'MISSOULA', N'MT')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'MT48520', N'GULL BOAT & RV', N'MISSOULA', N'MT')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'NC10626', N'TOM JOHNSON CAMPING CENTER, INC.', N'MARION', N'NC')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'NC110395', N'BUMGARNER CAMPING CENTER', N'HUDSON', N'NC')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'NC152962', N'REX AND SONS RVS', N'WILMINGTON', N'NC')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'NC16660', N'BILL PLEMMONS - PARENT', N'Rural hall', N'NC')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'NC48802', N'HOWARD RV CENTER', N'WILMINGTON', N'NC')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'NC48871', N'CAROLINA COACH & CAMPER', N'CLAREMONT', N'NC')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'NJ30072', N'SCOTT MOTOR COACH', N'LAKEWOOD', N'NJ')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'NM32771', N'ROCKY MOUNTAIN RV & MARINE', N'ALBUQUERQUE', N'NM')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'NM48713', N'MYERS RV CENTER, INC', N'ALBUQUERQUE', N'NM')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'NV48500', N'SIERRA RV CENTER', N'RENO', N'NV')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'NV48580', N'SPRADS RV', N'Reno', N'NV')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'NY10583', N'WILKINS RV INC', N'BATH', N'NY')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'NY108689', N'MOMOT TRAILER SALES', N'PLATTSBURGH', N'NY')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'NY171149', N'CALEDONIA RV', N'CALEDONIA', N'NY')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'NY195802', N'COLTON RV', N'NORTH TONAWANDA', N'NY')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'NY39577', N'ALPIN HAUS', N'AMSTERDAM', N'NY')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'OH37813', N'RCD RV SUPERCENTER', N'HEBRON', N'OH')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'OH48636', N'DAVE ARBOGAST RV & BOAT DEPOT', N'TROY', N'OH')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'OK14547', N'LEISURE TIME RV', N'OKLAHOMA CITY', N'OK')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'OK29627', N'RV GENERAL STORE', N'NORMAN', N'OK')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'ON112033', N'OTTAWA CAMPING TRAILERS LTD.', N'Ottawa', N'ON')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'ON112052', N'LEISURE TRAILER SALES', N'TECUMSEH', N'ON')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'ON131487', N'PRIMO TRAILER SALES', N'OTTAWA', N'ON')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'ON196116', N'CHRISTIES CAMPER SALES LTD', N'SAULT STE. MARIE', N'ON')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'ON32610', N'CAN-AM RV CENTRE', N'LONDON', N'ON')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'ON35518', N'LUXURY MOTORHOMES', N'Carlton Place', N'ON')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'ON35524', N'FERGUSON RV WORLD INC.', N'ST. THOMAS', N'ON')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'ON35590', N'THE HITCH HOUSE', N'SHANTY BAY', N'ON')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'ON35603', N'THE RV WAREHOUSE INC', N'COOKSTOWN', N'ON')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'ON35625', N'RECREATION WORLD RV', N'THUNDER BAY', N'ON')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'ON40970', N'RUSTON RV CENTRE', N'Burlington', N'ON')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'ON40982', N'MOBILIFE RV CENTRE', N'KITCHENER', N'ON')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'ON41002', N'CAMP-OUT RV LTD.', N'STRATFORD', N'ON')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'OR134404', N'JOHNSON RV SALES', N'PORTLAND', N'OR')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'OR200187', N'AIRSTREAM ADVENTURES NORTHWEST', N'GLADSTONE', N'OR')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'OR204941', N'B YOUNG RV', N'PORTLAND', N'OR')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'OR209540', N'JOHNSON RV SALES', N'SANDY', N'OR')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'OR26109', N'HIGHWAY TRAILER SALES', N'SALEM', N'OR')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'OR32451', N'GIBS RV SUPERSTORE', N'COOS BAY', N'OR')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'PA10724', N'ANSLEY RV', N'DUNCANSVILLE', N'PA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'PA10737', N'STOLTZFUS RV', N'WEST CHESTER', N'PA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'SC12609', N'THE TRAIL CENTER, INC.', N'NORTH CHARLESTON', N'SC')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'SC48300', N'CAMPER COUNTRY OF MYRTLE BEACH', N'MYRTLE BEACH', N'SC')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'SK155137', N'TRX RV', N'SASKATOON', N'SK')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'SK42684', N'TRAVELAND LEISURE CENTRE LTD', N'Regina', N'SK')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'SK47951', N'HAPPY CAMPER RV', N'PRINCE ALBERT', N'SK')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'TN10779', N'CULLUM & MAXEY CAMPING CENTER', N'NASHVILLE', N'TN')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'TN169842', N'RVS FOR LESS', N'Knoxville', N'TN')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'TN21162', N'CROWDER RV CENTER', N'JOHNSON CITY', N'TN')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'TX105016', N'HOLIDAY WORLD OF HOUSTON', N'KATY', N'TX')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'TX10821', N'PPL MOTOR HOMES', N'HOUSTON', N'TX')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'TX12724', N'PHARR 1 RVS INC', N'LUBBOCK', N'TX')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'TX187531', N'RV-MAX', N'WHITESBORO', N'TX')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'TX21166', N'ANCIRA RV', N'BOERNE', N'TX')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'TX22514', N'CASEYS CAMPERS', N'BIG SPRING', N'TX')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'TX27203', N'VOGT RV CENTER', N'FT. WORTH', N'TX')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'TX27291', N'HOLIDAY WORLD OF HOUSTON - PARENT', N'LEAGUE CITY', N'TX')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'TX29886', N'CRESTVIEW RV', N'BUDA', N'TX')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'TX48877', N'RON HOOVER RV CENTER', N'BOERNE', N'TX')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'TX48962', N'CAMPER CLINIC II', N'BUDA', N'TX')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'TX50241', N'RV OUTLET MALL', N'GEORGETOWN', N'TX')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'TX50327', N'PROFESSIONAL SALES RV', N'COLLEYVILLE', N'TX')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'VA183342', N'THE DODD GROUP - PARENT', N'YORKTOWN', N'VA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'VA48451', N'REINES RV CENTER', N'MANASSAS', N'VA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'VT12791', N'PETES RV CENTER', N'SOUTH BURLINGTON', N'VT')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'WA108157', N'TACOMA RV CENTER', N'Fife', N'WA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'WA200191', N'AIRSTREAM ADVENTURES NORTHWEST', N'COVINGTON', N'WA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'WA207235', N'TORKLIFT CENTRAL RV CENTER', N'KENT', N'WA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'WA48775', N'POULSBO RV', N'EVERETT', N'WA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'WA48770', N'R N R RV CENTER', N'LIBERTY LAKE', N'WA')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'WI128670', N'KINGS CAMPERS', N'WAUSAU', N'WI')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'WI129158', N'WISCONSIN RV WORLD', N'DEFOREST', N'WI')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'WI146673', N'BURLINGTON RV SUPERSTORE', N'STURTEVANT', N'WI')
INSERT #CoachNetDealerPartner_List ([VendorID], [VendorNumber], [Name], [City], [State]) VALUES (NULL, N'WV209564', N'THE GREAT OUTDOORS MARINE', N'LAVALETTE', N'WV')

-- Update selected Vendors (#CoachNetDealerPartner_List) with 'CoachNet Dealer Partner' product
-- Depends on #CoachNetDealerPartner_List in Production - Already added to Prod 
INSERT [dbo].[VendorProduct]
	([VendorID]
	, [ProductID]
	, [IsActive]
	, [Rating]
	, [CreateDate]
	, [CreateBy]
	)
SELECT v.ID
	,p.ID
	,1
	,NULL
	,getdate()
	,'System'
FROM Vendor v
JOIN #CoachNetDealerPartner_List dp ON dp.VendorNumber = v.VendorNumber
JOIN Product p On p.Name  = 'CoachNet Dealer Partner'
WHERE NOT EXISTS (
	SELECT *
	FROM VendorProduct vp
	JOIN Product p1 ON p1.ID = vp.ProductID
	WHERE p1.Name  = 'CoachNet Dealer Partner'
	AND vp.VendorID = v.ID
	)

INSERT [dbo].[VendorProduct]
	([VendorID]
	, [ProductID]
	, [IsActive]
	, [Rating]
	, [CreateDate]
	, [CreateBy]
	)
SELECT v.ID
	,p.ID
	,1
	,NULL
	,getdate()
	,'System'
FROM Vendor v
JOIN #CoachNetDealerPartner_List dp ON dp.VendorNumber = v.VendorNumber
JOIN Product p On p.Name = 'General RV'
WHERE NOT EXISTS (
	SELECT *
	FROM VendorProduct vp
	JOIN Product p1 ON p1.ID = vp.ProductID
	WHERE p1.Name = 'General RV'
	AND vp.VendorID = v.ID
	)

INSERT [dbo].[VendorLocationProduct]
	([VendorLocationID]
	, [ProductID]
	, [IsActive]
	, [Rating]
	, [CreateDate]
	, [CreateBy]
	)
SELECT vl.ID
	,p.ID
	,1
	,NULL
	,getdate()
	,'System'
FROM Vendor v
JOIN VendorLocation vl ON vl.VendorID = v.ID
JOIN #CoachNetDealerPartner_List dp ON dp.VendorNumber = v.VendorNumber
JOIN Product p On p.Name = 'CoachNet Dealer Partner'
WHERE NOT EXISTS (
	SELECT *
	FROM VendorLocationProduct vlp
	JOIN Product p1 ON p1.ID = vlp.ProductID
	WHERE p1.Name  = 'CoachNet Dealer Partner'
	AND vlp.VendorLocationID = vl.ID
	)
	
INSERT [dbo].[VendorLocationProduct]
	([VendorLocationID]
	, [ProductID]
	, [IsActive]
	, [Rating]
	, [CreateDate]
	, [CreateBy]
	)
SELECT vl.ID
	,p.ID
	,1
	,NULL
	,getdate()
	,'System'
FROM Vendor v
JOIN VendorLocation vl ON vl.VendorID = v.ID
JOIN #CoachNetDealerPartner_List dp ON dp.VendorNumber = v.VendorNumber
JOIN Product p On p.Name = 'General RV'
WHERE NOT EXISTS (
	SELECT *
	FROM VendorLocationProduct vlp
	JOIN Product p1 ON p1.ID = vlp.ProductID
	WHERE p1.Name = 'General RV'
	AND vlp.VendorLocationID = vl.ID
	)
	
DROP TABLE #CoachNetDealerPartner_List
GO




--Service request locked comments
Print 'Changes for Service Request locked comments'
GO
IF NOT EXISTS (SELECT * FROM Event WHERE Name = 'LockedRequestComment')
	BEGIN
		INSERT INTO [dbo].[Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
		VALUES
           (
           (SELECT ID FROM EventType WHERE Name = 'User')
           , (SELECT ID FROM EventCategory WHERE Name = 'ServiceRequest')
           , 'LockedRequestComment'
           , 'Locked Request Comment'
           , 1
           , 1
           , 'System'
           , getdate())
	END
GO

-- Add CommentType for Locked Request comment
IF NOT EXISTS (SELECT * FROM CommentType WHERE Name = 'LockedRequest')
	BEGIN
		INSERT INTO [dbo].[CommentType]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
		VALUES
           (
            'LockedRequest'
           , 'Locked Request'
           , 1
           , 1)
	END
GO


	
-- File : DBChanges.2014.03.19.sql Last Updated : 19 March 2014

Print 'CommunicationQueue and CommunicationLog schema changes'
GO
-- Changes to CommunicationQueue and CommunicationLog tables.
ALTER TABLE CommunicationQueue ADD EventLogID BIGINT NULL

ALTER TABLE CommunicationQueue ADD NotificationRecipient NVARCHAR(MAX) NULL

ALTER TABLE CommunicationLog ADD EventLogID BIGINT NULL

ALTER TABLE CommunicationLog ADD NotificationRecipient NVARCHAR(MAX) NULL
GO


--Sanghi 18 July 2014 Affecting 351923 Records

UPDATE CommunicationQueue 
SET		NotificationRecipient = CASE WHEN ContactMethodID IN (SELECT ID FROM ContactMethod WHERE Name IN ('Phone', 'Text','Fax','IVR'))
										THEN  PhoneNumber
										ELSE Email
										END


UPDATE CommunicationLog 
SET		NotificationRecipient = CASE WHEN ContactMethodID IN (SELECT ID FROM ContactMethod WHERE Name IN ('Phone', 'Text','Fax','IVR'))
										THEN  PhoneNumber
										ELSE Email
										END
GO

ALTER TABLE CommunicationQueue DROP COLUMN Email

ALTER TABLE CommunicationQueue DROP COLUMN PhoneNumber

ALTER TABLE CommunicationLog DROP COLUMN Email

ALTER TABLE CommunicationLog DROP COLUMN PhoneNumber
GO



PRINT 'Program configs for Register member field validation'
GO
--
-- Setup ProgramConfiguration for Register Member pop-up fields

--select * from configurationtype
--select * from configurationcategory
--select * From programconfiguration order by name

IF NOT EXISTS (SELECT * FROM ConfigurationType WHERE Name = 'RegisterMember')
	BEGIN
		INSERT [dbo].[ConfigurationType]
			([Name]
			,[Description]
			,[Sequence]
			,[IsActive]
			)
		VALUES 
			('RegisterMember'
			, 'Register Member'
			, 8
			, 1)
	END
GO	

-- insert ProgramConfiguration for controlling register member fields that are required
-- and for settting ExpirationDate based on EffectiveDate
DECLARE @ProgramID INT
DECLARE @ConfigurationTypeID INT
DECLARE @ConfigurationCategoryID  INT
DECLARE @CreateDate DateTime

SET @CreateDate = '8/1/2014'
SET @ConfigurationTypeID = (SELECT ID FROM ConfigurationType WHERE Name= 'RegisterMember')
SET @ConfigurationCategoryID = (SELECT ID FROM ConfigurationCategory WHERE Name= 'Validation')

DECLARE db_cursor CURSOR FOR  
      select p.ID ProgramID
      --c.id, c.name as Client, pp.id, pp.name as Parent, p.id, p.name as Program
      from program p
      join client c on c.id = p.clientid
      Join PhoneSystemConfiguration psc on psc.ProgramID = p.ID and psc.IsActive = 1
      left join program pp on pp.id = p.parentprogramid
      where 1=1
      --and c.name <> 'ARS'
      and p.isactive = 1
      and isnull(pp.id, '') = ''
      and Not Exists (
            Select *
            From ProgramConfiguration pc
            Where pc.ProgramID = p.ID 
            and pc.ConfigurationTypeID = @ConfigurationTypeID 
            and pc.ConfigurationCategoryID = @ConfigurationCategoryID
            )           
      order by c.name, pp.name, p.name

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @ProgramID   

WHILE @@FETCH_STATUS = 0   
BEGIN   

      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireProgram', 'Yes', 1, 1, @CreateDate, 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequirePrefix', 'No', 1, 1, @CreateDate, 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireFirstName', 'Yes', 1, 1, @CreateDate, 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireMiddleName', 'No', 1, 1, @CreateDate, 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireLastName', 'Yes', 1, 1, @CreateDate, 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireSuffix', 'No', 1, 1, @CreateDate, 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequirePhone', 'Yes', 1, 1, @CreateDate, 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireAddress1', 'Yes', 1, 1, @CreateDate, 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireAddress2', 'No', 1, 1, @CreateDate, 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireAddress3', 'No', 1, 1, @CreateDate, 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireCity', 'Yes', 1, 1, @CreateDate, 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireCountry', 'Yes', 1, 1, @CreateDate, 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireState', 'Yes', 1, 1, @CreateDate, 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireZip', 'Yes', 1, 1, @CreateDate, 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireEmail', 'No', 1, 1, @CreateDate, 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireEffectiveDate', 'Yes', 1, 1, @CreateDate, 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'RequireExpirationDate', 'Yes', 1, 1, @CreateDate, 'System', NULL, NULL)
      INSERT INTO ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy) VALUES (@ProgramID, @ConfigurationTypeID, @ConfigurationCategoryID, NULL, NULL, 'DaysAddedToEffectiveDate', 2, 1, 1, @CreateDate, 'System', NULL, NULL)

    FETCH NEXT FROM db_cursor INTO @ProgramID   
END   

CLOSE db_cursor   
DEALLOCATE db_cursor

GO


--Exceptions to the Default Settings 

-- PDG - Professional Dispatch Group
UPDATE ProgramConfiguration SET Value = 'No' WHERE Name = 'RequireAddress1' AND ProgramID = (SELECT ID FROM Program WHERE Name = 'PDG - Professional Dispatch Group')
UPDATE ProgramConfiguration SET Value = 'No' WHERE Name = 'RequireCity' AND ProgramID = (SELECT ID FROM Program WHERE Name = 'PDG - Professional Dispatch Group')
UPDATE ProgramConfiguration SET Value = 'No' WHERE Name = 'RequireCountry' AND ProgramID = (SELECT ID FROM Program WHERE Name = 'PDG - Professional Dispatch Group')
UPDATE ProgramConfiguration SET Value = 'No' WHERE Name = 'RequireState' AND ProgramID = (SELECT ID FROM Program WHERE Name = 'PDG - Professional Dispatch Group')
UPDATE ProgramConfiguration SET Value = 'No' WHERE Name = 'RequireZip' AND ProgramID = (SELECT ID FROM Program WHERE Name = 'PDG - Professional Dispatch Group')
UPDATE ProgramConfiguration SET Value = '14' WHERE Name = 'DaysAddedToEffectiveDate' AND ProgramID = (SELECT ID FROM Program WHERE Name = 'PDG - Professional Dispatch Group')
GO

-- PCG - Travel Guard
UPDATE ProgramConfiguration SET Value = 'No' WHERE Name = 'RequireAddress1' AND ProgramID = (SELECT ID FROM Program WHERE Name = 'PCG - Travel Guard')
UPDATE ProgramConfiguration SET Value = 'No' WHERE Name = 'RequireCity' AND ProgramID = (SELECT ID FROM Program WHERE Name = 'PCG - Travel Guard')
UPDATE ProgramConfiguration SET Value = 'No' WHERE Name = 'RequireCountry' AND ProgramID = (SELECT ID FROM Program WHERE Name = 'PCG - Travel Guard')
UPDATE ProgramConfiguration SET Value = 'No' WHERE Name = 'RequireState' AND ProgramID = (SELECT ID FROM Program WHERE Name = 'PCG - Travel Guard')
UPDATE ProgramConfiguration SET Value = 'No' WHERE Name = 'RequireZip' AND ProgramID = (SELECT ID FROM Program WHERE Name = 'PCG - Travel Guard')
UPDATE ProgramConfiguration SET Value = '14' WHERE Name = 'DaysAddedToEffectiveDate' AND ProgramID = (SELECT ID FROM Program WHERE Name = 'PCG - Travel Guard')
GO

-- NMC
UPDATE ProgramConfiguration SET Value = 'No' WHERE Name = 'RequireZip' AND ProgramID = (SELECT ID FROM Program WHERE Name = 'NMC')
UPDATE ProgramConfiguration SET Value = '14' WHERE Name = 'DaysAddedToEffectiveDate' AND ProgramID = (SELECT ID FROM Program WHERE Name = 'NMC')
GO



-- File : DBChanges.2014.03.20.sql Last Updated : 20 March 2014
Print 'Add Event UpdateMemberExpiration'
GO
IF NOT EXISTS (SELECT * FROM Event WHERE Name = 'UpdateMemberExpiration')
	BEGIN
		INSERT INTO Event (EventTypeID, 
							EventCategoryID,
							Name,
							Description,
							IsShownOnScreen,
							IsActive,
							CreateBy,
							CreateDate
							)			
		SELECT (SELECT ID FROM EventType WHERE Name = 'User')
			, (SELECT ID FROM EventCategory WHERE Name = 'Member')
			, 'UpdateMemberExpiration'
			, 'Update Member Expiration'
			, 1
			, 1
			, 'System'
			, getdate()
	END
GO



Print 'Add Securables for BUTTON_MEMBER_EDIT_EXPIRATION Button'
GO
-- Read Write Permission to manager,sysadmin,agent

DECLARE @managerRoleID UNIQUEIDENTIFIER
SET		@managerRoleID = (SELECT RoleID FROM aspnet_Roles WHERE LoweredRoleName = 'manager' AND ApplicationId = (SELECT ApplicationId FROM aspnet_Applications WHERE LoweredApplicationName = 'dms'))

DECLARE @sysAdminRoleID UNIQUEIDENTIFIER
SET		@sysAdminRoleID = (SELECT RoleID FROM aspnet_Roles WHERE LoweredRoleName = 'sysadmin' AND ApplicationId = (SELECT ApplicationId FROM aspnet_Applications WHERE LoweredApplicationName = 'dms'))

DECLARE @agentRoleID UNIQUEIDENTIFIER
SET		@agentRoleID = (SELECT RoleID FROM aspnet_Roles WHERE LoweredRoleName = 'agent' AND ApplicationId = (SELECT ApplicationId FROM aspnet_Applications WHERE LoweredApplicationName = 'dms'))

DECLARE @securableID INT
-- Create Securable for ADD COMMENT
IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_MEMBER_EDIT_EXPIRATION')
BEGIN
	
	INSERT INTO Securable(FriendlyName) VALUES('BUTTON_MEMBER_EDIT_EXPIRATION')	
	SET @securableID = (SELECT ID FROM Securable WHERE FriendlyName = 'BUTTON_MEMBER_EDIT_EXPIRATION')
	INSERT INTO AccessControlList(SecurableID,RoleID,AccessTypeID) VALUES(@securableID,@managerRoleID,(SELECT ID FROM AccessType WHERE Name = 'ReadWrite')) 
	INSERT INTO AccessControlList(SecurableID,RoleID,AccessTypeID) VALUES(@securableID,@sysAdminRoleID,(SELECT ID FROM AccessType WHERE Name = 'ReadWrite')) 
	INSERT INTO AccessControlList(SecurableID,RoleID,AccessTypeID) VALUES(@securableID,@agentRoleID,(SELECT ID FROM AccessType WHERE Name = 'ReadWrite')) 
END



Print 'Add CommentType Member'
GO
IF NOT EXISTS (SELECT * FROM CommentType WHERE Name = 'Member')
	BEGIN
		INSERT [dbo].[CommentType]
			([Name]
			,[Description]
			,[Sequence]
			,[IsActive]
			)
		VALUES
			('Member'
			,'Member'
			,1
			,1
			)
	END
GO


Print 'Spartan Chassis Program configuration items'
GO

IF NOT EXISTS ( SELECT * FROM ProgramConfiguration WHERE ProgramID = 
		(SELECT ID FROM Program WHERE Name = 'Spartan Chassis') AND 
		Name = 'WarrantyApplies')
BEGIN
	INSERT INTO ProgramConfiguration ( 
		ProgramID,
		ConfigurationTypeID,
		ConfigurationCategoryID,
		Name,
		Value,
		CreateBy,
		CreateDate,
		IsActive)
	SELECT (SELECT ID FROM Program WHERE Name = 'Spartan Chassis'),
			(SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle'),
			(SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'),
			'WarrantyApplies',
			'Yes',
			'system',
			GETDATE(),
			1
END
GO



Print 'Ford Program configuration items'
GO

-- Warranty Applies
INSERT INTO ProgramConfiguration ( 
	ProgramID,
	ConfigurationTypeID,
	ConfigurationCategoryID,
	Name,
	Value,
	CreateBy,
	CreateDate,
	IsActive)
SELECT p.ID,
		(SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle'),
		(SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'),
		'WarrantyApplies',
		'Yes',
		'system',
		GETDATE(),
		1
FROM Program p
WHERE p.Name IN ('Ford Commercial Truck', 'Ford Extended Service Plan (RV & COMM)', 'Ford RV - Rental','Ford RV','Ford Transport')
AND NOT EXISTS (
	SELECT *
	FROM ProgramConfiguration pc
	WHERE pc.ProgramID = p.ID AND pc.Name = 'WarrantyApplies')			
			
GO

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE 
		ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford') 
		AND Name = 'VIN Number')
	BEGIN
		INSERT INTO [dbo].[ProgramConfiguration]
			([ProgramID]
			,[ConfigurationTypeID]
			,[ConfigurationCategoryID]
			,[ControlTypeID]
			,[DataTypeID]
			,[Name]
			,[Value]
			,[IsActive]
			,[Sequence]
			,[CreateDate]
			,[CreateBy]
			,[ModifyDate]
			,[ModifyBy]			
			)
		VALUES 
			(
			(SELECT ID FROM Program WHERE Name = 'Ford')
			, (SELECT ID FROM ConfigurationType WHERE Name = 'CallScript')
			, (SELECT ID FROM ConfigurationCategory WHERE Name = 'Welcome')
			, NULL
			, NULL
			, 'VIN Number'
			, 'What is your full 17 digit VIN number?'
			, 1
			, 3
			, getdate()
			, 'System'
			, NULL
			, NULL
			)
	END
	
IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE 
		ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford') 
		AND Name = 'MilesOnVehicle')
	BEGIN
		INSERT INTO [dbo].[ProgramConfiguration]
			([ProgramID]
			,[ConfigurationTypeID]
			,[ConfigurationCategoryID]
			,[ControlTypeID]
			,[DataTypeID]
			,[Name]
			,[Value]
			,[IsActive]
			,[Sequence]
			,[CreateDate]
			,[CreateBy]
			,[ModifyDate]
			,[ModifyBy]			
			)
		VALUES 
			(
			(SELECT ID FROM Program WHERE Name = 'Ford')
			, (SELECT ID FROM ConfigurationType WHERE Name = 'CallScript')
			, (SELECT ID FROM ConfigurationCategory WHERE Name = 'Welcome')
			, NULL
			, NULL
			, 'MilesOnVehicle'
			, 'How many miles on your vehicle?'
			, 1
			, 4
			, getdate()
			, 'System'
			, NULL
			, NULL
			)
	END
	
GO	

-- Setup Program Data Item for Mileage
IF NOT EXISTS (SELECT * FROM ProgramDataItem WHERE 
		ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford') AND 
		ScreenName = 'StartCall' AND 
		Name = 'CurrentMileage')
	BEGIN
		INSERT INTO [dbo].[ProgramDataItem]
			([ProgramID]
			, [ControlTypeID]
			, [DataTypeID]
			, [ScreenName]
			, [Name]
			, [Label]
			, [MaxLength]
			, [Sequence]
			, [IsRequired]
			, [IsActive]
			, [CreateDate]
			, [CreateBy]
			, [ModifyDate]
			, [ModifyBy]
			)
		VALUES
			((SELECT ID FROM Program WHERE Name = 'Ford')
			, (SELECT ID FROM ControlType WHERE Name = 'Textbox')
			, (SELECT ID FROM DataType WHERE Name = 'Numeric')
			, 'StartCall'
			, 'CurrentMileage'
			, 'Current Mileage'
			, 7
			, 1
			, 1
			, 1
			, getdate()
			, 'System'
			, NULL
			, NULL
			)
	END
GO


-- Additional ContactReason

IF NOT EXISTS (SELECT * FROM ContactReason WHERE Name = 'ReceivedCallFromAgero'
				AND ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'NewCall') )
	BEGIN  
		INSERT INTO [dbo].[ContactReason]
			([ContactCategoryID]
			, [Name]
			, [Description]
			, [IsActive]
			, [IsShownOnScreen]
			, [Sequence]
			)
		VALUES
			(
			(SELECT ID FROM ContactCategory WHERE Name = 'NewCall')
			, 'ReceivedCallFromAgero'
			, 'Received call from Agero'
			, 1
			, 1
			, 4
			)
	END
GO

IF NOT EXISTS (SELECT * FROM ContactAction WHERE Name = 'AgeroRefusedAssistCoachNetDispatched'
				AND ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'NewCall') )
	BEGIN
		INSERT INTO [dbo].[ContactAction]
			([ContactCategoryID]
			, [Name]
			, [Description]
			, [IsShownOnScreen]
			, [IsTalkedToRequired]
			, [IsActive]
			, [Sequence]
			, [VendorServiceRatingAdjustment]
			)
		VALUES
			(
			(SELECT ID FROM ContactCategory WHERE Name = 'NewCall')
			, 'AgeroRefusedAssistCoachNetDispatched'
			, 'Agero refused, CoachNet dispatched'
			, 1
			, NULL
			, 1
			, 20
			, NULL 
			)
	END
GO



Print 'Changes for Desktop Notification'
GO
-- Define an app config item for notification history
IF NOT EXISTS ( SELECT * FROM ApplicationConfiguration WHERE Name = 'NotificationHistoryDisplayHours')
BEGIN

	INSERT INTO ApplicationConfiguration ( ApplicationConfigurationTypeID,
											ApplicationConfigurationCategoryID,
											Name,
											Value,
											CreateDate,
											CreateBy
										)
	SELECT  ( SELECT ID FROM ApplicationConfigurationType WHERE Name = 'CommunicationQueue'),
			NULL,
			'NotificationHistoryDisplayHours',
			'48',
			GETDATE(),
			'system'
END
GO

--Print 'Add Securables for BUTTON_ADD_NOTIFICATION Button'
--GO
-- Securable for Add notification
-- Setup Add Notification
DECLARE @AddNotification INT
DECLARE @RoleID UNIQUEIDENTIFIER
DECLARE @AccessTypeID INT

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_ADD_NOTIFICATION')
	BEGIN
      INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
		VALUES('BUTTON_ADD_NOTIFICATION',NULL,NULL) 
	END

SET @AddNotification = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'BUTTON_ADD_NOTIFICATION')

SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='sysadmin')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @AddNotification AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@AddNotification,@RoleID,@AccessTypeID)
	END
	
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Manager')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @AddNotification AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@AddNotification,@RoleID,@AccessTypeID)
	END

SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Agent')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @AddNotification AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@AddNotification,@RoleID,@AccessTypeID)
	END
GO

-- File : DBChanges.2014.03.12.sql Last Updated : 21 March 2014
IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DesktopNotifications]') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[DesktopNotifications]
	(  [NotificationID] [bigint] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	   [UserName] [nvarchar](100) NOT NULL,
	   [ConnectionID] [nvarchar](max) NOT NULL,
	   [UserAgent] [nvarchar](max) NOT NULL,
	   [IsConnected] [bit] NOT NULL)
END
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NotificationRecipientType]') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[NotificationRecipientType](
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[Name] [nvarchar](50) NOT NULL,
		[Description] [nvarchar](255) NULL,
		[IsShownOnManualNotification] BIT NULL,
		[Sequence] [int] NULL,
		[IsActive] [bit] NULL,
	 CONSTRAINT [PK_NotificationRecipientType] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]


	SET IDENTITY_INSERT [dbo].[NotificationRecipientType] ON
	INSERT [dbo].[NotificationRecipientType] ([ID], [Name], [Description], [IsShownOnManualNotification], [Sequence], [IsActive]) VALUES (1, N'CurrentUser', N'Current User', 0, 1, 1)
	INSERT [dbo].[NotificationRecipientType] ([ID], [Name], [Description], [IsShownOnManualNotification], [Sequence], [IsActive]) VALUES (2, N'User', N'User', 1, 2, 1)
	INSERT [dbo].[NotificationRecipientType] ([ID], [Name], [Description], [IsShownOnManualNotification], [Sequence], [IsActive]) VALUES (3, N'Role', N'Role', 1, 3, 1)
	SET IDENTITY_INSERT [dbo].[NotificationRecipientType] OFF

END
GO


-- EventSubscription schema changes
ALTER TABLE [dbo].[EventSubscription] ADD NotificationRecipientTypeID INT NULL

ALTER TABLE [dbo].[EventSubscription] ADD NotificationRecipient NVARCHAR(MAX) NULL


ALTER TABLE [dbo].[EventSubscription]  WITH CHECK ADD  CONSTRAINT [FK_EventSubscription_NotificationRecipientType] FOREIGN KEY([RecipientTypeID])
REFERENCES [dbo].[NotificationRecipientType] ([ID])
GO

ALTER TABLE [dbo].[EventSubscription] CHECK CONSTRAINT [FK_EventSubscription_NotificationRecipientType]
GO

-- New Event - SendPOFaxFailed
IF NOT EXISTS ( SELECT * FROM Event WHERE Name = 'SendPOFaxFailed')
BEGIN
	INSERT INTO Event ( EventTypeID, EventCategoryID, Name, Description,IsShownOnScreen, IsActive, CreateBy, CreateDate)
	SELECT	(SELECT ID FROM EventType WHERE Name = 'System'),
			(SELECT ID FROM EventCategory WHERE Name = 'PurchaseOrder'),
			'SendPOFaxFailed',
			'Send PO Fax failed',
			0,
			1,
			'system',
			GETDATE()
END
GO

-- New ContactMethod - DesktopNotification
IF NOT EXISTS ( SELECT * FROM ContactMethod WHERE Name = 'DesktopNotification')
BEGIN
	INSERT INTO ContactMethod ( Name, Description, IsActive)
	SELECT 'DesktopNotification', 'Desktop Notification', 1
END
GO

-- Add a new entity - ContactLogAction
IF NOT EXISTS ( SELECT * FROM Entity WHERE Name = 'ContactLogAction')
BEGIN
	INSERT INTO Entity ( Name, IsAudited)
	SELECT	'ContactLogAction',0
END
GO

-- Template for notification
IF NOT EXISTS ( SELECT * FROM Template WHERE Name = 'PO_Fax_Failure_Notification' )
BEGIN
	INSERT INTO Template (Name, Subject, Body, IsActive)
	SELECT 'PO_Fax_Failure_Notification',
			NULL,
			'PO send failed <br/> Method: Fax <br/> Reason: ${FaxFailureReason} <br/> SR: ${ServiceRequest} <br/> PO: ${PONumber}',
			1
END
GO

-- EventTemplate
IF NOT EXISTS ( SELECT * FROM EventTemplate 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'SendPOFaxFailed') 
				AND		TemplateID = (SELECT ID FROM Template WHERE Name = 'PO_Fax_Failure_Notification')
				)
BEGIN
	INSERT INTO EventTemplate (EventID,TemplateID, IsDefault)
	SELECT	(SELECT ID FROM Event WHERE Name = 'SendPOFaxFailed'),
			(SELECT ID FROM Template WHERE Name = 'PO_Fax_Failure_Notification'),
			1

END
GO

-- EventSubscription

IF NOT EXISTS ( SELECT * FROM EventSubscription 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'SendPOFaxFailed') 				
				)
BEGIN
	INSERT INTO EventSubscription ( EventID, 
									EventCategoryID, 
									ContactMethodID, 
									EventTemplateID, 
									IsActive, 
									CreateDate, 
									CreateBy, 
									NotificationRecipientTypeID, 
									NotificationRecipient)
	SELECT	(SELECT ID FROM Event WHERE Name = 'SendPOFaxFailed'),
			NULL,
			(SELECT ID FROM ContactMethod WHERE Name = 'DesktopNotification'),
			(SELECT ID FROM EventTemplate 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'SendPOFaxFailed') 
				AND		TemplateID = (SELECT ID FROM Template WHERE Name = 'PO_Fax_Failure_Notification') 
			),
			1,
			GETDATE(),
			'system',
			(SELECT ID FROM NotificationRecipientType WHERE Name = 'CurrentUser'),
			NULL

END
GO

	
-- NextAction - ResendPO
IF NOT EXISTS ( SELECT * FROM NextAction WHERE Name = 'ResendPO')
BEGIN
	INSERT INTO NextAction ( Name, Description, IsActive)
	SELECT 'ResendPO', ' Re-send PO', 1
END
GO


-- Event - ManualNotification
IF NOT EXISTS ( SELECT * FROM Event WHERE Name = 'ManualNotification')
BEGIN
	INSERT INTO Event ( EventTypeID, EventCategoryID, Name, Description,IsShownOnScreen, IsActive, CreateBy, CreateDate)
	SELECT	(SELECT ID FROM EventType WHERE Name = 'User'),
			(SELECT ID FROM EventCategory WHERE Name = 'ServiceRequest'),
			'ManualNotification',
			'Manual Notification',
			0,
			1,
			'system',
			GETDATE()
END
GO

-- Template for ManualNotification
IF NOT EXISTS ( SELECT * FROM Template WHERE Name = 'ManualNotification' )
BEGIN
	INSERT INTO Template (Name, Subject, Body, IsActive)
	SELECT 'ManualNotification',
			NULL,
			'Message from ${SentFrom} : ${MessageText}',
			1
END
GO

-- EventTemplate - ManualNotification
IF NOT EXISTS ( SELECT * FROM EventTemplate 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'ManualNotification') 
				AND		TemplateID = (SELECT ID FROM Template WHERE Name = 'ManualNotification')
				)
BEGIN
	INSERT INTO EventTemplate (EventID,TemplateID, IsDefault)
	SELECT	(SELECT ID FROM Event WHERE Name = 'ManualNotification'),
			(SELECT ID FROM Template WHERE Name = 'ManualNotification'),
			1

END
GO

-- EventSubscription : Manual Notification

IF NOT EXISTS ( SELECT * FROM EventSubscription 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'ManualNotification') 				
				)
BEGIN
	INSERT INTO EventSubscription ( EventID,
									EventTypeID,
									EventCategoryID, 
									ContactMethodID, 
									EventTemplateID, 
									IsActive, 
									CreateDate, 
									CreateBy, 
									NotificationRecipientTypeID, 
									NotificationRecipient)
	SELECT	(SELECT ID FROM Event WHERE Name = 'ManualNotification'),
			NULL,
			NULL,
			(SELECT ID FROM ContactMethod WHERE Name = 'DesktopNotification'),
			(SELECT ID FROM EventTemplate 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'ManualNotification') 
				AND		TemplateID = (SELECT ID FROM Template WHERE Name = 'ManualNotification') 
			),
			1,
			GETDATE(),
			'system',
			(SELECT ID FROM NotificationRecipientType WHERE Name = 'CurrentUser'),
			NULL

END
GO



-- File : DBChanges.2014.03.26- Setup ProgramConfiguration for DOP and FirstOwner.sql  Last Updated : 26 March 2014
--
Print 'Setup to make fields on Vehicle Tab program driven - Date of Purchase and First Owner'
GO

-- Add program configuration item 
DECLARE @ProgramID INT
SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford')

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'ShowDateOfPurchase')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID
			, (SELECT ID FROM ConfigurationType WHERE Name = 'Application')
			, (SELECT ID FROM ConfigurationCategory WHERE Name = 'Rule')  
			, NULL
			, NULL
			, 'ShowDateOfPurchase'
			, 'No'
			, 1
			, 1
			, getdate()
			, 'System'
			, NULL
			, NULL
			)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'ShowFirstOwner')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID
			, (SELECT ID FROM ConfigurationType WHERE Name = 'Application')
			, (SELECT ID FROM ConfigurationCategory WHERE Name = 'Rule')  
			, NULL
			, NULL
			, 'ShowFirstOwner'
			, 'No'
			, 1
			, 1
			, getdate()
			, 'System'
			, NULL
			, NULL
			)
	END
GO


DECLARE @ProgramID INT
SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'NMC')

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'ShowDateOfPurchase')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID
			, (SELECT ID FROM ConfigurationType WHERE Name = 'Application')
			, (SELECT ID FROM ConfigurationCategory WHERE Name = 'Rule')  
			, NULL
			, NULL
			, 'ShowDateOfPurchase'
			, 'Yes'
			, 1
			, 1
			, getdate()
			, 'System'
			, NULL
			, NULL
			)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'ShowFirstOwner')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID
			, (SELECT ID FROM ConfigurationType WHERE Name = 'Application')
			, (SELECT ID FROM ConfigurationCategory WHERE Name = 'Rule')  
			, NULL
			, NULL
			, 'ShowFirstOwner'
			, 'Yes'
			, 1
			, 1
			, getdate()
			, 'System'
			, NULL
			, NULL
			)
	END
GO



-- File : DBChanges.2014.03.21.sql  Last Updated : 27 March 2014

-- NP: Execute statement by statement. Includes Vehicle and related table changes.
-- EventSubscription : Manual Notification

IF NOT EXISTS ( SELECT * FROM EventSubscription 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'LockedRequestComment') 				
				)
BEGIN
	INSERT INTO EventSubscription ( EventID,
									EventTypeID,
									EventCategoryID, 
									ContactMethodID, 
									EventTemplateID, 
									IsActive, 
									CreateDate, 
									CreateBy, 
									NotificationRecipientTypeID, 
									NotificationRecipient)
	SELECT	(SELECT ID FROM Event WHERE Name = 'LockedRequestComment'),
			NULL,
			NULL,
			(SELECT ID FROM ContactMethod WHERE Name = 'DesktopNotification'),
			(SELECT ID FROM EventTemplate 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'ManualNotification') 
				AND		TemplateID = (SELECT ID FROM Template WHERE Name = 'ManualNotification') 
			),
			1,
			GETDATE(),
			'system',
			(SELECT ID FROM NotificationRecipientType WHERE Name = 'CurrentUser'),
			NULL

END
GO


Print 'CASE Schema Changes'
GO
ALTER TABLE [Case] ADD VehicleWarrantyPeriod INT NULL

ALTER TABLE [Case] ADD VehicleWarrantyPeriodUOM NVARCHAR(25)

ALTER TABLE [Case] ADD VehicleWarrantyMileage INT NULL

ALTER TABLE [Case] ADD VehicleWarrantyEndDate DATETIME NULL

ALTER TABLE [Case] ADD IsVehicleEligible BIT NULL
GO

Print 'Vehicle Schema Changes'
GO
ALTER TABLE Vehicle ADD WarrantyPeriod INT NULL

ALTER TABLE Vehicle ADD WarrantyPeriodUOM NVARCHAR(25)

ALTER TABLE Vehicle ADD WarrantyMileage INT NULL

ALTER TABLE Vehicle ADD WarrantyEndDate DATETIME NULL
GO

Print 'VehicleMakeModel Schema Changes'
GO
ALTER TABLE VehicleMakeModel ADD WarrantyPeriod INT NULL

ALTER TABLE VehicleMakeModel ADD WarrantyPeriodUOM NVARCHAR(25)

ALTER TABLE VehicleMakeModel ADD WarrantyMileageMiles INT NULL

ALTER TABLE VehicleMakeModel ADD WarrantyMileageKilometers INT NULL
GO

Print 'RVMakeModel Schema Changes'
GO
ALTER TABLE RVMakeModel ADD WarrantyPeriod INT NULL

ALTER TABLE RVMakeModel ADD WarrantyPeriodUOM NVARCHAR(25)

ALTER TABLE RVMakeModel ADD WarrantyMileageMiles INT NULL

ALTER TABLE RVMakeModel ADD WarrantyMileageKilometers INT NULL
GO


Print 'Config warranty in VehicleMakeModel for Ford'
GO
UPDATE VehicleMakeModel SET
	WarrantyPeriod = 5,
	WarrantyPeriodUOM = 'Years',
	WarrantyMileageMiles = 60000,
	WarrantyMileageKilometers = 90000
WHERE ID IN(
Select ID from VehicleMakeModel where make = 'Ford' 
		and model in ('E-350','E-450','E-550')
		or model in ('F-350','F-450','F-550')
)
GO

UPDATE VehicleMakeModel SET
	WarrantyPeriod = 2,
	WarrantyPeriodUOM = 'Years',
	WarrantyMileageMiles = NULL,
	WarrantyMileageKilometers = NULL
WHERE ID IN(
Select ID from VehicleMakeModel where make = 'Ford' 
		and model in ('E-650','E-750')
		or model in ('F-650','F-750')
)
GO

--RVMakeModel Updates
Print 'Config warranty in RVMakeModel for Ford'
GO
UPDATE RVMakeModel SET
	WarrantyPeriod = 5,
	WarrantyPeriodUOM = 'Years',
	WarrantyMileageMiles = 60000,
	WarrantyMileageKilometers = 90000
WHERE ID IN(
Select ID from RVMakeModel where make = 'Ford' 
		and model in ('E-350','E-450','E-550')
		or model in ('F-350','F-450','F-550')
)
GO

UPDATE RVMakeModel SET
	WarrantyPeriod = 2,
	WarrantyPeriodUOM = 'Years',
	WarrantyMileageMiles = NULL,
	WarrantyMileageKilometers = NULL
WHERE ID IN(
Select ID from RVMakeModel where make = 'Ford' 
		and model in ('E-650','E-750')
		or model in ('F-650','F-750')
)
GO

-- File : DBChanges.2014.03.28.sql  Last Updated : 28 March 2014


Print 'Create ProgramServiceEventLimit table'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProgramServiceEventLimit]') AND type in (N'U'))
BEGIN

	CREATE TABLE [dbo].[ProgramServiceEventLimit](
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[ProgramID] [int] NULL,
		[ProductCategoryID] [int] NULL,
		[ProductID] [int] NULL,
		[VehicleTypeID] [int] NULL,
		[VehicleCategoryID] [int] NULL,
		[Description] [nvarchar](255) NULL,
		[Limit] [int] NULL,
		[LimitDuration] [int] NULL,
		[LimitDurationUOM] [nvarchar](50) NULL,
		[IsActive] [bit] NOT NULL,
		[CreateDate] [datetime] NULL,
		[CreateBy] [nvarchar](50) NULL,
		[StoredProcedureName] [nvarchar](255) NULL,
		[IsLimitDurationSinceMemberRenewal] [bit] NULL,
	 CONSTRAINT [PK__ProgramServiceEventLimit] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	SET IDENTITY_INSERT [dbo].[ProgramServiceEventLimit] ON
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (13, 165, 4, NULL, NULL, NULL, N'2 Fluid Deliveries every 12 months.  2 gallons gas or 5 gallons diesel.', 2, 12, N'Month', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 0)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (15, 266, 4, NULL, NULL, NULL, N'3 Fluid Deliveries every 12 months.  3 gallons gas or 5 gallons diesel.', 3, 12, N'Month', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 0)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (16, 266, 5, NULL, NULL, NULL, N'3 Jump Starts every 12 months', 3, 12, N'Month', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 0)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (18, 163, NULL, NULL, NULL, NULL, N'3 events during last 12 months', 3, 12, N'Month', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 0)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (21, 217, 4, NULL, NULL, NULL, N'1 Fluid delivery service every 7 days', 1, 7, N'Day', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 0)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (22, 217, 5, NULL, NULL, NULL, N'1 Jump start service every 7 days', 1, 7, N'Day', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 0)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (23, 217, 3, NULL, NULL, NULL, N'1 Lockout service every 7 days', 1, 7, N'Day', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 0)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (24, 217, 2, NULL, NULL, NULL, N'1 Tire service every 7 days', 1, 7, N'Day', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 0)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (25, 217, 6, NULL, NULL, NULL, N'1 Winch service every 7 days', 1, 7, N'Day', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 0)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (26, 217, 1, NULL, NULL, NULL, N'1 Tow service every 7 days', 1, 7, N'Day', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 0)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (27, 212, NULL, NULL, NULL, NULL, N'5 events during last 12 months', 5, 12, N'Month', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 0)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (28, 427, 2, NULL, NULL, NULL, N'5 events per membership year', 5, 12, N'Month', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 1)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (34, 320, NULL, NULL, NULL, NULL, N'4 events during membership year', 4, 12, N'Month', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 1)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (35, 320, NULL, NULL, NULL, NULL, N'1 event during last 3 months', 1, 3, N'Month', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 0)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (36, 7, NULL, NULL, NULL, NULL, N'3 events during membership year', 3, 12, N'Month', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 1)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (37, 7, NULL, NULL, NULL, NULL, N'1 event during last 30 days', 1, 30, N'Day', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 0)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (38, 217, NULL, NULL, NULL, NULL, N'3 events during last 12 months', 3, 12, N'Month', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 0)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (42, 98, NULL, NULL, NULL, NULL, N'3 events during last 12 months', 3, 12, N'Month', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 0)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (43, 188, NULL, NULL, NULL, NULL, N'3 events during last 12 months', 3, 12, N'Month', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 0)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (44, 6, NULL, NULL, NULL, NULL, N'5 events per membership year', 5, 12, N'Month', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', NULL, 1)
	INSERT [dbo].[ProgramServiceEventLimit] ([ID], [ProgramID], [ProductCategoryID], [ProductID], [VehicleTypeID], [VehicleCategoryID], [Description], [Limit], [LimitDuration], [LimitDurationUOM], [IsActive], [CreateDate], [CreateBy], [StoredProcedureName], [IsLimitDurationSinceMemberRenewal]) VALUES (46, 414, NULL, NULL, NULL, NULL, N'1 Tow and 1 other event per membership year', 1, 12, N'Month', 1, CAST(0x0000A33D00000000 AS DateTime), N'System', N'dms_VerifyProgramServiceEventLimit_Program_414', 1)
	SET IDENTITY_INSERT [dbo].[ProgramServiceEventLimit] OFF
END
GO



Print 'Vehicle entry config for Ford QFC'
GO

IF EXISTS (SELECT ID FROM Program WHERE Name = 'Ford QFC')
BEGIN
	
	IF NOT EXISTS (	SELECT * 
				FROM	ProgramConfiguration 
				WHERE	Name = 'VehicleLicenseStateRequired' 
				AND		ProgramID =  (SELECT ID FROM Program WHERE Name = 'Ford QFC'))
	BEGIN

		INSERT INTO ProgramConfiguration (	ProgramID,
											ConfigurationTypeID,
											ConfigurationCategoryID,
											Name,
											Value,
											IsActive,
											CreateDate,
											CreateBy )
		SELECT	(SELECT ID FROM Program WHERE Name = 'Ford QFC'),
				(SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle'),
				(SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'),
				'VehicleLicenseStateRequired',
				'Yes',
				1,
				GETDATE(),
				'system'

	END

	IF NOT EXISTS (	SELECT * 
				FROM	ProgramConfiguration 
				WHERE	Name = 'VehicleLicenseNumberRequired' 
				AND		ProgramID =  (SELECT ID FROM Program WHERE Name = 'Ford QFC') )
	BEGIN

		INSERT INTO ProgramConfiguration (	ProgramID,
											ConfigurationTypeID,
											ConfigurationCategoryID,
											Name,
											Value,
											IsActive,
											CreateDate,
											CreateBy )
		SELECT	(SELECT ID FROM Program WHERE Name = 'Ford QFC'),
				(SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle'),
				(SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'),
				'VehicleLicenseNumberRequired',
				'Yes',
				1,
				GETDATE(),
				'system'

	END

END
GO

-- File : DBChanges.2014.03.10.ModifyMembershipTable.sql  Last Updated : 29 March 2014



IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_VerifyServiceBenefit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyServiceBenefit] 
 END 
 GO  



-- File : DbChanges.2014.03.27-Create a new Event Name.sql  Last Updated : 01 April 2014

Print 'Add Event UpdateMemberInfoInCase'
GO
IF NOT EXISTS(SELECT * FROM Event WHERE Name = 'UpdateMemberInfoInCase')
      BEGIN
            INSERT INTO [dbo].[Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
            VALUES
           ((select [ID] from [dbo].[EventType] where Name='User')
           ,(select [ID] from [dbo].[EventCategory] where Name='ServiceRequest')
           ,'UpdateMemberInfoInCase'
           ,'Update Member Info In Case'
           ,1
           ,1
           ,NULL
           ,GETDATE())
      END
GO

-- File : DBChanges.2014.04.02.sql  Last Updated : 02 April 2014

PRINT 'Add Securable for BUTTON_EDIT_CCNUMBER'
GO
-- Setup Edit CC Securable and Event
DECLARE @EditCCNumber INT
DECLARE @RoleID UNIQUEIDENTIFIER
DECLARE @AccessTypeID INT

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_EDIT_CCNUMBER')
	BEGIN
      INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
		VALUES('BUTTON_EDIT_CCNUMBER',NULL,NULL) 
	END

SET @EditCCNumber = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'BUTTON_EDIT_CCNUMBER')

SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='sysadmin')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @EditCCNumber AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@EditCCNumber,@RoleID,@AccessTypeID)
	END
	
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Accounting')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @EditCCNumber AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@EditCCNumber,@RoleID,@AccessTypeID)
	END
	
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='VendorRep')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @EditCCNumber AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@EditCCNumber,@RoleID,@AccessTypeID)
	END	

GO


Print 'Add Event EditCCNumberOnPO'
GO
-- Setup Event for EditCCNumber
IF NOT EXISTS (SELECT * FROM Event WHERE Name = 'EditCCNumberOnPO')
	BEGIN
		INSERT INTO [dbo].[Event] (EventTypeID, EventCategoryID, Name, Description, IsShownOnScreen, IsActive, CreateBy, CreateDate)
		VALUES (
			(SELECT ID FROM EventType WHERE Name = 'User')
			, (SELECT ID FROM EventCategory WHERE Name = 'PurchaseOrder')
			, 'EditCCNumberOnPO'
			, 'Edit CC Number on PO'
			, 1
			, 1
			, 'System'
			, getdate()
			)
	END
GO


-- Template for ManualNotification
IF NOT EXISTS ( SELECT * FROM Template WHERE Name = 'LockedRequestComment' )
BEGIN
	INSERT INTO Template (Name, Subject, Body, IsActive)
	SELECT 'LockedRequestComment',
			NULL,
			'${SentFrom} - ${RequestNumber} : ${MessageText}',
			1
END
GO

-- EventTemplate - ManualNotification
IF NOT EXISTS ( SELECT * FROM EventTemplate 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'LockedRequestComment') 
				AND		TemplateID = (SELECT ID FROM Template WHERE Name = 'LockedRequestComment')
				)
BEGIN
	INSERT INTO EventTemplate (EventID,TemplateID, IsDefault)
	SELECT	(SELECT ID FROM Event WHERE Name = 'LockedRequestComment'),
			(SELECT ID FROM Template WHERE Name = 'LockedRequestComment'),
			1

END
GO

UPDATE	EventSubscription
SET		EventTemplateID = (SELECT ID FROM EventTemplate 
							WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'LockedRequestComment') 
							AND		TemplateID = (SELECT ID FROM Template WHERE Name = 'LockedRequestComment')
						)
WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'LockedRequestComment') 

GO

-- File : DBChanges.2014.04.03.sql Last Updated : 03 April 2014



--PO Change service
DECLARE @manager UNIQUEIDENTIFIER
DECLARE @vendorrep  UNIQUEIDENTIFIER
DECLARE @sysadmin UNIQUEIDENTIFIER
DECLARE @RoleID UNIQUEIDENTIFIER
DECLARE @AccessTypeID INT
DECLARE @Button INT

SET @manager = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Manager')
SET @vendorrep = (SELECT R.RoleId FROM aspnet_Roles R JOIN aspnet_Applications A ON R.ApplicationId = A.ApplicationId WHERE A.ApplicationName = 'DMS' AND R.RoleName ='VendorRep')
SET @sysadmin = (SELECT R.RoleId FROM aspnet_Roles R JOIN aspnet_Applications A ON R.ApplicationId = A.ApplicationId WHERE A.ApplicationName = 'DMS' AND R.RoleName ='sysadmin')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

-- Setup Securable
IF NOT EXISTS (SELECT ID FROM Securable WHERE FriendlyName = 'BUTTON_PO_SERVICECOVERED_EDIT')
	BEGIN
	INSERT INTO [dbo].[Securable] ([FriendlyName], [ParentID], [SecurityContext])
		VALUES ('BUTTON_PO_SERVICECOVERED_EDIT', NULL, NULL)
	END

SET @Button = (SELECT ID FROM Securable WHERE FriendlyName = 'BUTTON_PO_SERVICECOVERED_EDIT')

-- Setup Manager AccessControlList
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @Button AND RoleID = @manager)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@Button,@manager,@AccessTypeID)
	END


IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @Button AND RoleID = @vendorrep)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@Button,@vendorrep,@AccessTypeID)
	END


IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @Button AND RoleID = @sysadmin)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@Button,@sysadmin,@AccessTypeID)
	END
	
GO


-- Setup Event for Edit PO Service Coverage
IF NOT EXISTS (SELECT ID FROM Event WHERE Name = 'OverridePOServiceCovered')
	BEGIN
		INSERT 
			INTO [dbo].[Event] ([EventTypeID],[EventCategoryID],[Name],[Description],[IsShownOnScreen],[IsActive],[CreateBy],[CreateDate])
			VALUES (
				(SELECT ID FROM EventType WHERE Name = 'User')
				, (SELECT ID FROM EventCategory WHERE Name = 'PurchaseOrder')
				, 'OverridePOServiceCovered'
				, 'Override PO Service Covered'
				, 1
				, 1
				, 'System'
				, getdate()
				)
	END
GO



-- Setup Event for Edit PO Change Service 
IF NOT EXISTS (SELECT ID FROM Event WHERE Name = 'POChangeService')
	BEGIN
		INSERT 
			INTO [dbo].[Event] ([EventTypeID],[EventCategoryID],[Name],[Description],[IsShownOnScreen],[IsActive],[CreateBy],[CreateDate])
			VALUES (
				(SELECT ID FROM EventType WHERE Name = 'User')
				, (SELECT ID FROM EventCategory WHERE Name = 'PurchaseOrder')
				, 'POChangeService'
				, 'PO Change Service'
				, 1
				, 1
				, 'System'
				, getdate()
				)
	END
GO

IF NOT EXISTS (SELECT ID FROM Event WHERE Name = 'CopyPO')
	BEGIN
		INSERT 
			INTO [dbo].[Event] ([EventTypeID],[EventCategoryID],[Name],[Description],[IsShownOnScreen],[IsActive],[CreateBy],[CreateDate])
			VALUES (
				(SELECT ID FROM EventType WHERE Name = 'User')
				, (SELECT ID FROM EventCategory WHERE Name = 'PurchaseOrder')
				, 'CopyPO'
				, 'Copy PO'
				, 1
				, 1
				, 'System'
				, getdate()
				)
	END
GO




-- File : DBChanges.2014.04.08.sql Last Updated : 08 April 2014

update template set body = '${FaxFailureReason}; SR-${ServiceRequest}; PO-${PONumber}' where name = 'PO_Fax_Failure_Notification'
GO
update template set body = '[${SentFrom}] ${MessageText}' where name = 'ManualNotification'
GO
update template set body = '[${SentFrom}] SR-${RequestNumber}: ${MessageText}' where name = 'LockedRequestComment'
GO

--/*
ALTER view [dbo].[vw_BillingServiceRequestsPurchaseOrders]
as
select	ServiceRequestID,
		ServiceRequestStatus,
		ServiceRequestDate,
		ServiceRequestDatetime,
		ClientID,
		ClientName,
		ProgramID,
		ProgramName,
		ProgramCode,
		MemberID,
		LastName,
		FirstName,
		MembershipNumber,
		MemberSinceDate,
		EffectiveDate,
		ExpirationDate,
		MemberCreateDate,
		MemberCreateDatetime,
		PurchaseOrderID,
		PurchaseOrderNumber,
		PurchaseOrderDate,
		PurchaseOrderDatetime,
		PurchaseOrderStatus,
		PurchaseOrderIsActive,
		ContactLastName,
		ContactFirstName,
		VIN,
		VehicleYear,
		VehicleMake,
		VehicleModel,
		VINModelYear,
		VINModel,
		VehicleCurrentMileage,
		VehicleMileageUOM,
		VehicleLicenseNumber,
		VehicleLicenseState,
		SRPrimaryProductCat,
		SRPrimaryProductID,
		SRPrimaryProductDescription,
		SRPrimaryProductCategoryDescription,
		SRSecondaryProductID,
		SRSecondProductDescription,
		SRSecondaryProductCategoryDescription,
		ServiceCode,
		POProductID,
		POProductDescription,
		POPProductCategoryDescription,
		PODetailProductID,
		PODetailProductDescription,
		PODetailProductCategoryDescription,
		ServiceLocationAddress,
		ServiceLocationCity,
		ServiceLocationStateProvince,
		DestinationDescription,
		DestinationCity,
		DestinationStateProvince,
		TotalServiceAmount,
		CoachNetServiceAmount,
		MemberServiceAmount,
		PurchaseOrderAmount,
		ServiceRequestCCPaymentsReceived,
		IsPaidByCompanyCC,
		BillingApprovalCode,
		IsCancelledSR,
		IsDispatchIntended,
		IsDispatched,
		IsCancelledPO,
		GOAReason,
		IsVendorPay,
		IsMemberPay,
		IsReDispatch,
		IsTechAssistance,
		IsDiagnostics,
		IsVerifyService,
		IsISPSelection,
		IsInfoContact,
		IsNoMemberOnService,
		IsMbrManuallyCreated,
		IsImpoundRelease,
		IsOutOfWarranty,
		
		IsDirectTowApprovedDestination,
		DispatchFee,
		DispatchFeeBillToName,
		VendorID,
		VendorNumber,
		VendorLocationID,
		DealerNumber,
		PACode,

		PrimaryVehicleDiagnosticCodeID,
		PrimaryVehicleDiagnosticCodeName,
		VehicleDiagnosticCodeCount,
		InboundContactsTOTAL,
		InboundContactsNEWCALL,
		InboundContactsCUSTOMER,
		InboundContactsVENDOR,
		InboundContactsCLOSEDLOOP,
		InboundContactsOTHER,
		OutboundContactsTOTAL,
		OutboundContactsNEWCALL,
		OutboundContactsCUSTOMER,
		OutboundContactsVENDOR,
		OutboundContactsCLOSEDLOOP,
		OutboundContactsOTHER,
		cast(case when IsDispatchIntended = 1 then 1 else 0 end as int) as DISPATCH,
		cast(case when IsDispatchIntended = 0 then 1 else 0 end as int) as NON_DISPATCH,
		cast(case 
				when IsDispatchIntended = 0 
				and (IsTechAssistance = 1
					 or IsDiagnostics = 1
					 or IsVerifyService = 1
					 or IsISPSelection = 1)
				then 1 else 0 
				end
			as int) as CUSTOMER_ASSISTANCE,
		cast(case 
				when IsDispatchIntended = 0 
				and IsTechAssistance = 0
				and	IsDiagnostics = 0
				and	IsVerifyService = 0
				and	IsISPSelection = 0
				and IsInfoContact = 1
				then 1 else 0 
				end
			as int) as INFO,
		cast(case 
				when IsDispatchIntended = 0 
				and IsTechAssistance = 0
				and	IsDiagnostics = 0
				and	IsVerifyService = 0
				and	IsISPSelection = 0
				and IsInfoContact = 0
				then 1 else 0 
				end
			as int) as OTHER,
		cast(case 
				when IsDispatched = 1
				and IsVendorPay = 1
				then 1 else 0
				end 
			as int) as PASS_THRU,

		AccountingInvoiceBatchID_ServiceRequest,
		AccountingInvoiceBatchID_PurchaseOrder,

		ServiceRequestComments,
		ServiceRequestCommentsClaimNum,
		ServiceRequestCommentsPACode,
		ServiceRequestCommentsDealerID,

		(select ID from dbo.Entity with (nolock) where Name = 'ServiceRequest') as EntityID_ServiceRequest,
		ServiceRequestID as  EntityKey_ServiceRequest,
		(select ID from dbo.Entity with (nolock) where Name = 'PurchaseOrder') as EntityID_PurchaseOrder,
		PurchaseOrderID as  EntityKey_PurchaseOrder


from
		(select	sr.ID as ServiceRequestID,
				srs.Name as ServiceRequestStatus,
				convert(date, sr.CreateDate) as ServiceRequestDate,
				sr.CreateDate as ServiceRequestDatetime,
				cl.ID as ClientID,
				cl.Name as ClientName,
				(CASE WHEN ISNULL(ca.ProgramID,0) <> 0 THEN COALESCE(mbr.ProgramID, ca.ProgramID, 0) ELSE 0 END) as ProgramID,
				pro.Name as ProgramName,
				pro.Code as ProgramCode,
				mbr.ID as MemberID,
				mbr.LastName,
				mbr.FirstName,
				mbrs.MembershipNumber,
				mbr.MemberSinceDate,
				mbr.EffectiveDate,
				convert(date, mbr.CreateDate) as MemberCreateDate,
				mbr.CreateDate as MemberCreateDatetime,
				mbr.ExpirationDate,
				ca.ContactLastName,
				ca.ContactFirstName,

				ca.VehicleVIN as VIN,
				ca.VehicleYear,
				ca.VehicleMake,
				ca.VehicleModel,
				dbo.fnc_BillingVINModelYear(ca.VehicleVIN) as VINModelYear,
				dbo.fnc_BillingVINModel(ca.VehicleVIN) as VINModel,
				ca.VehicleCurrentMileage,
				ca.VehicleMileageUOM,
				ca.VehicleLicenseNumber,
				ca.VehicleLicenseState,
								
				-- SR Product Category
				srpc.Name as SRPrimaryProductCat,
				
				-- SR Primary Product
				srpr.ID as SRPrimaryProductID,
				srpr.[Description] as SRPrimaryProductDescription,
				srprpc.[Description] as SRPrimaryProductCategoryDescription,
				
				-- SR Secondary Product
				srpr2.ID as SRSecondaryProductID,
				srpr2.[Description] as SRSecondProductDescription,
				srprpc2.[Description] as SRSecondaryProductCategoryDescription,
				
				-- PO Product
				popr.ID as POProductID,
				popr.[Description] as POProductDescription,
				popc.[Description] as POPProductCategoryDescription,
				
				-- PO Detail Product
				p4.ID as PODetailProductID,
				p4.[Description] as PODetailProductDescription,
				p4pc.[Description] as PODetailProductCategoryDescription,
				
				scv.ServiceCode,
				
				sr.ServiceLocationAddress,
				sr.ServiceLocationCity,
				sr.ServiceLocationStateProvince,

				sr.DestinationDescription,
				sr.DestinationCity,
				sr.DestinationStateProvince,
								
				po.ID as PurchaseOrderID,
				po.PurchaseOrderNumber,
				convert(date, po.CreateDate) as PurchaseOrderDate,
				po.CreateDate as PurchaseOrderDatetime,
				pos.Name as PurchaseOrderStatus,
				po.IsActive as PurchaseOrderIsActive,
				po.TotalServiceAmount,
				po.CoachNetServiceAmount,
				po.MemberServiceAmount,
				po.PurchaseOrderAmount,
				CC.ServiceRequestCCPaymentsReceived,
				
				cast(
				 case
				 when po.IsPayByCompanyCreditCard = 1 and po.CompanyCreditCardNumber is not null then 1
				 else 0
				end 
				as int) as IsPaidByCompanyCC,
				
				cast(null as nvarchar(50)) as BillingApprovalCode,  -- NEED TO GET QFC BILLING CODE HERE

				cast(
				case
				 when srs.Name = 'Cancelled' then 1
				 else 0
				end as int) as IsCancelledSR,
				cast(
					case
					when	po.ID is null and COALESCE(popc.Name, srpc.Name) = 'Tech' then 0 -- 1. No PO and Tech then No DispatchIntended
					when	po.ID is not null then 1 -- 2. Has a PO, then DispatchIntended
					when	-- 3. When Member Data, Vehicle Data, Is of Dispatch Concern, and Location then DispatchIntended
							(mbrs.MembershipNumber is not null -- Member Data
							 and	(ca.VehicleYear is not null -- Vehicle Data
									 or ca.VehicleMake is not null
									 or ca.VehicleModel is not null)
							 and	COALESCE(popc.Name, srpc.Name) in ('Tow', 'Tire', 'Lockout', 'Fluid', 'Jump', 'Winch', 'Tech', 'Mobile', 'Repair') -- is of Dispatch Concern
							 and	sr.ServiceLocationAddress is not null
							 and	sr.ServiceLocationCity is not null
							 and	sr.ServiceLocationStateProvince is not null) then 1
					else 0
					end as int) as IsDispatchIntended,
					cast(
					case
					 when po.ID is not null then 1
					 else 0
					end as int)	as IsDispatched,
					cast(
					case
					 when pos.Name = 'Cancelled' then 1
					 else 0
					end as int)as IsCancelledPO,
					pocr.[Description] as CancelledPOReason,
					isnull(cast(po.IsGOA as int), 0) as IsGOA,
					goa.[Description] as GOAReason,
					case
					 when po.PurchaseOrderAmount > 0.00 then 1
					 else 0
					end as IsVendorPay,
					case
					-- when (po.MemberServiceAmount = po.TotalServiceAmount) and po.PurchaseOrderAmount = 0.00 then 1
					 when (po.MemberServiceAmount = po.TotalServiceAmount) and po.TotalServiceAmount <> 0.00 then 1
					 else 0
					end as IsMemberPay,
					cast(
					case
					 when isnull(CLOG.ReDispatchContact, 0) > 0 then 1
					 else 0
					end as int) as IsReDispatch,
					cast(
					case
					 when COALESCE(popc.Name, srpc.Name) = 'Tech' or IsWorkedByTech = 1 then 1
					 else 0
					end as int) as IsTechAssistance,
					cast(
					case
					 when isnull(DIAG.VehicleDiagnosticCodeCount, 0) > 0 then 1
					 else 0
					end as int) as IsDiagnostics,
					cast(
					case
					 when isnull(CLOG.VerifyServiceContact, 0) > 0 then 1
					 else 0
					end as int) as IsVerifyService,
					cast(
					case
					 when isnull(CLOG.ISPSelectionContact, 0) > 0 then 1
					 else 0
					end as int) as IsISPSelection,
					cast(
					case
					 when COALESCE(popc.Name, srpc.Name) like '%Info%' then 1 -- Info Product
					 when isnull(CLOG.InfoContact, 0) > 0 then 1 -- Coded with Info Contact
					 else 0
					end as int) as IsInfoContact,
					cast(
					case
					 when mbr.ID is null then 1
					 else 0
					end as int) as IsNoMemberOnService,
					cast(
					case
					 when mbr.CreateBy not in ('System', 'DISPATCHPOST') then 1
					 else 0
					end as int) as IsMbrManuallyCreated,
					cast(
					case
					 when IMP.PurchaseOrderID is not null then 1
					 else 0
					end as int) as IsImpoundRelease,
					cast(
					case
					 when isnull(CLOG.OutOfWarrantyContact, 0) > 0 then 1
					 else 0
					end as int) as IsOutOfWarranty,

					DT.IsDirectTowApprovedDestination,
					po.DispatchFee,
					bt.Name as DispatchFeeBillToName,
					
					-- Direct Tow
					DT.VendorID,
					DT.VendorNumber,
					DT.VendorLocationID,
					DT.DealerNumber,
					DT.PACode,
					
					-- Diagnostics
					DIAG.PrimaryVehicleDiagnosticCodeID,
					DIAG.PrimaryVehicleDiagnosticCodeName,
					isnull(DIAG.VehicleDiagnosticCodeCount, 0) as VehicleDiagnosticCodeCount,

					-- Contacts
					InboundContactsTOTAL,
					InboundContactsNEWCALL,
					InboundContactsCUSTOMER,
					InboundContactsVENDOR,
					InboundContactsCLOSEDLOOP,
					InboundContactsOTHER,
					OutboundContactsTOTAL,
					OutboundContactsNEWCALL,
					OutboundContactsCUSTOMER,
					OutboundContactsVENDOR,
					OutboundContactsCLOSEDLOOP,
					OutboundContactsOTHER,
					
					sr.AccountingInvoiceBatchID as AccountingInvoiceBatchID_ServiceRequest,
					po.AccountingInvoiceBatchID as AccountingInvoiceBatchID_PurchaseOrder,

					-- Comments
					CMT.ServiceRequestComments,
					CMT.ServiceRequestCommentsClaimNum,
					CMT.ServiceRequestCommentsPACode,
					CMT.ServiceRequestCommentsDealerID
		
		from	dbo.ServiceRequest sr with (nolock)
		left outer join dbo.ProductCategory srpc with (nolock) on srpc.ID = sr.ProductCategoryID
		left outer join dbo.ServiceRequestStatus srs with (nolock) on srs.ID = sr.ServiceRequestStatusID
		left outer join dbo.[Case] ca with (nolock) on ca.ID = sr.CaseID
		left outer join dbo.CaseStatus cas with (nolock) on cas.ID = ca.CaseStatusID
		left outer join PurchaseOrder po with (nolock) on sr.ID = po.ServiceRequestID
		left outer join dbo.ContactMethod cm with (nolock) on cm.ID = po.ContactMethodID
		left outer join dbo.PurchaseOrderType pot with (nolock) on pot.ID = po.PurchaseOrderTypeID
		left outer join dbo.PurchaseOrderStatus pos with (nolock) on pos.ID = po.PurchaseOrderStatusID
		left outer join dbo.PurchaseOrderCancellationReason pocr with (nolock) on pocr.ID = po.CancellationReasonID
		left outer join dbo.CurrencyType ct with (nolock) on ct.ID = po.CurrencyTypeID
		left outer join dbo.PaymentType pt with (nolock) on pt.ID = po.MemberPaymentTypeID
		left outer join dbo.PurchaseOrderGOAReason goa with (nolock) on goa.ID = po.GOAReasonID
		left outer join dbo.Product popr with (nolock) on popr.ID = po.ProductID
		left outer join dbo.ProductCategory popc with (nolock) on popc.ID = popr.ProductCategoryID

		left outer join dbo.Member mbr with (nolock) on mbr.ID = ca.MemberID
		left outer join dbo.Membership mbrs with (nolock) on mbrs.ID = mbr.MembershipID
		left outer join dbo.Program pro with (nolock) on pro.ID = (CASE WHEN ISNULL(ca.ProgramID,0) <> 0 THEN COALESCE(mbr.ProgramID, ca.ProgramID, 0) ELSE 0 END)
		left outer join dbo.Program pra with (nolock) on pra.ID = pro.ParentProgramID
		left outer join dbo.Client cl with (nolock) on cl.ID = pro.ClientID
		left outer join dbo.Product srpr with (nolock) on srpr.ID = sr.PrimaryProductID
		left outer join dbo.ProductCategory srprpc with (nolock) on srprpc.ID = srpr.ProductCategoryID
		left outer join dbo.Product srpr2 with (nolock) on srpr2.ID = sr.SecondaryProductID
		left outer join dbo.ProductCategory srprpc2 with (nolock) on srprpc2.ID = srpr2.ProductCategoryID
		left outer join dbo.BillTo bt with (nolock) on bt.ID = po.DispatchFeeBillToID
		
		-- To Get the Service Code
		left outer join vw_ServiceCode scv on scv.ServiceRequestID = sr.ID
				and isnull(scv.PurchaseOrderID, -999) = isnull(po.ID, -999)

		left outer join	
		
				(select distinct pod.PurchaseOrderID, pod.ProductID from dbo.PurchaseOrderDetail pod with (nolock)) b  
						on	b.PurchaseOrderID = po.ID  
							and --if the po detail records have the same product as the po record then use it to define the product for the call
							b.ProductID =	(Case when po.ProductID = (select distinct pod1.productid from dbo.PurchaseOrderDetail pod1 with (nolock) 
											where pod1.PurchaseOrderID = po.ID and pod1.ProductID = po.ProductID) then po.ProductID
								--if the productid from the Purchase order detail doesn't match the product id on the po record then use the max id from the purchase order detail
											else (select distinct max(pod2.productid) from dbo.PurchaseOrderDetail pod2 with (nolock) 
											where pod2.PurchaseOrderID = po.ID) end)
			--Get the lable for the Product Name
		left outer join dbo.Product p4 with (nolock) on p4.ID = b.ProductID	
		left outer join dbo.ProductCategory p4pc with (nolock) on p4pc.ID = p4.ProductCategoryID	


		left outer join -- Diagnostics

				(select	srvdc.ServiceRequestID,
						srvdc.VehicleDiagnosticCodeID as PrimaryVehicleDiagnosticCodeID,
						vdc.Name as PrimaryVehicleDiagnosticCodeName,
						(select count(*)
						 from	ServiceRequestVehicleDiagnosticCode dc1 with (nolock)
						 where	dc1.ServiceRequestID = srvdc.ServiceRequestID) as VehicleDiagnosticCodeCount
				 from	ServiceRequestVehicleDiagnosticCode srvdc with (nolock)
				 join	VehicleDiagnosticCode vdc with (nolock) on vdc.ID = srvdc.VehicleDiagnosticCodeID
				 where	srvdc.IsPrimary = 1) DIAG on DIAG.ServiceRequestID = SR.ID

		left outer join -- Contact Logs

				(select	sr2.ID as ServiceRequestID,
						-- Inbound
						count(distinct 
							  case when cl.Direction = 'Inbound' then cl.ID
							  else null
							  end) as InboundContactsTOTAL,
						count(distinct
							  case when cl.Direction = 'Inbound' and cc.Name = 'NewCall' then cl.ID
							  else null
							  end) as InboundContactsNEWCALL,
						count(distinct
							  case when cl.Direction = 'Inbound' and cc.Name in ('ContactCustomer', 'CustomerCallback') then cl.ID
							  else null
							  end) as InboundContactsCUSTOMER,
						count(distinct
							  case when cl.Direction = 'Inbound' and cc.Name in ('ContactVendor', 'VendorCallback', 'VendorSelection') then cl.ID
							  else null
							  end) as InboundContactsVENDOR,
						count(distinct
							  case when cl.Direction = 'Inbound' and cc.Name in ('ClosedLoop') then cl.ID
							  else null
							  end) as InboundContactsCLOSEDLOOP,
						count(distinct
							  case when cl.Direction = 'Inbound' and cc.Name not in 
							  ('NewCall', 'ContactCustomer', 'CustomerCallback', 'ContactVendor', 'VendorCallback', 'VendorSelection', 'ClosedLoop')
							  then cl.ID
							  else null
							  end) as InboundContactsOTHER,
						-- Outbound
						count(distinct 
							  case when cl.Direction = 'Outbound' then cl.ID
							  else null
							  end) as OutboundContactsTOTAL,
						count(distinct
							  case when cl.Direction = 'Outbound' and cc.Name = 'NewCall' then cl.ID
							  else null
							  end) as OutboundContactsNEWCALL,
						count(distinct
							  case when cl.Direction = 'Outbound' and cc.Name in ('ContactCustomer', 'CustomerCallback') then cl.ID
							  else null
							  end) as OutboundContactsCUSTOMER,
						count(distinct
							  case when cl.Direction = 'Outbound' and cc.Name in ('ContactVendor', 'VendorCallback', 'VendorSelection') then cl.ID
							  else null
							  end) as OutboundContactsVENDOR,
						count(distinct
							  case when cl.Direction = 'Outbound' and cc.Name in ('ClosedLoop') then cl.ID
							  else null
							  end) as OutboundContactsCLOSEDLOOP,
						count(distinct
							  case when cl.Direction = 'Outbound' and cc.Name not in 
							  ('NewCall', 'ContactCustomer', 'CustomerCallback', 'ContactVendor', 'VendorCallback', 'VendorSelection', 'ClosedLoop')
							  then cl.ID
							  else null
							  end) as OutboundContactsOTHER,
						count(distinct
							  case when ca.Name like '%Information%'
							  then cl.ID
							  else null
							  end) as InfoContact,
						count(distinct
							  case when cr.Name = 'Verify Service'
							  then cl.ID
							  else null
							  end) as VerifyServiceContact,
						count(distinct
							  case when cr.Name = 'ISP Selection'
							  then cl.ID
							  else null
							  end) as ISPSelectionContact,				  				  
						count(distinct
							  case when cr.Name = 'Re-dispatch'
							  then cl.ID
							  else null
							  end) as ReDispatchContact,
						count(distinct
							  case when ca.Name = 'OutOfWarranty'
							  then cl.ID
							  else null
							  end) as OutOfWarrantyContact
				from	contactlog cl with (nolock)
				join	contactloglink cll with (nolock) on cl.id = cll.contactlogid and cll.EntityID = (select ID from Entity where Name = 'ServiceRequest')
				join	servicerequest sr2 with (nolock) on sr2.id = cll.recordid
				join	contactcategory cc with (nolock) on cl.contactcategoryid = cc.id
				join	contactlogReason clr with (nolock) on cl.id = clr.contactlogid
				join	contactreason cr with (nolock) on clr.ContactReasonID = cr.ID
				join	contactlogaction cla with (nolock) on cl.id = cla.contactlogid
				join	contactaction ca with (nolock) on cla.ContactActionID = ca.ID
				group by
						sr2.ID) CLOG on CLOG.ServiceRequestID = SR.ID

		left outer join -- Impound Release Fees
					
					(select	distinct po.ID as PurchaseOrderID
					 from	dbo.PurchaseOrder po with (nolock)
					 join	dbo.PurchaseOrderDetail pod with (nolock) on pod.PurchaseOrderID = po.ID
					 join	dbo.Product pr with (nolock) on pr.ID = pod.ProductID
					 where	pr.Name = 'Impound Release Fee'
					) IMP on IMP.PurchaseOrderID = po.ID


		left outer join	-- Direct Tow Destination Attributes
		
					(select	v.ID as VendorID,
							v.VendorNumber,
							vl.ID as VendorLocationID,
							vl.DealerNumber,
							cast(null as nvarchar(50)) as PACode,
							cast(1 as int) as IsDirectTowApprovedDestination
					from	Vendor v with (nolock)
					left outer join	VendorLocation vl with (nolock) on vl.VendorID = v.ID
					left outer join	VendorLocationProduct vlp with (nolock) on vlp.VendorLocationID = vl.ID
					left outer join	Product pr with (nolock) on pr.ID = vlp.ProductID
					where	1=1
					and		pr.Name = 'Ford Direct Tow') DT on DT.VendorLocationID = sr.DestinationVendorLocationID
					
		left outer join -- Service Request CC Payments Received

					(select	sr.ID as ServiceRequestID,
							sum(pmt.Amount) ServiceRequestCCPaymentsReceived
					from	Payment pmt with (nolock)
					join	PaymentStatus ps on ps.ID = pmt.PaymentStatusID
							and ps.Name = 'Approved'
					join	PaymentType pt on pt.ID = pmt.PaymentTypeID
					join	PaymentCategory pc on pc.ID = pt.PaymentCategoryID
							and pc.Name = 'CreditCard'
					join	ServiceRequest sr on sr.ID = pmt.ServiceRequestID
					join	PaymentReason pr on pr.ID = pmt.PaymentReasonID
					group by
							sr.ID) CC on CC.ServiceRequestID = sr.ID
							
		Left outer join dbo.vw_ServiceRequestComments CMT on CMT.ServiceRequestID = sr.ID -- Service Request Comments


			) DTL
	where	1=1


GO
--*/

Print 'Data Fix - Set missing StateProvinceID and CountryID on Address records'
GO
-- File : DBChanges.2014.04.11.Update Address Entity Null Values.sql   Last Updated : 11 April 2014
--Sanghi 18 July -- Affecting 360929 Thrice Please check
CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	AddressEntityID int  NULL ,
	StateProvince nvarchar(100)  NULL ,
	StateProvinceID INT  NULL,
	AECountryID INT NULL,
	AECountryCode NVARCHAR(20) NULL,
	SPCountryID INT NULL,
	CountryCode NVARCHAR(20) NULL
) 
INSERT INTO #tmpFinalResults

SELECT DISTINCT
	AE.ID,
	AE.StateProvince,
	SP.ID,
	AE.CountryID ,
	AE.CountryCode,
	SP.CountryID ,
	C.ISOCode 
from AddressEntity AE
LEFT JOIN StateProvince SP ON Sp.Abbreviation = AE.StateProvince
LEFT JOIN Country C ON C.ID = SP.CountryID
WHERE AE.StateProvince IS NOT NULL AND AE.StateProvinceID IS NULL
AND		AE.StateProvince NOT IN ( 'MI','MO','NL') AND SP.ID IS NOT NULL

--Select * from #tmpFinalResults

UPDATE      AE
SET         StateProvinceID = TFR.StateProvinceID
		,   CountryCode = CASE 
							WHEN 	TFR.AECountryCode = NULL THEN TFR.CountryCode
							ELSE TFR.AECountryCode
						END
		,	CountryID = CASE 
							WHEN 	TFR.AECountryID = NULL THEN TFR.SPCountryID
							ELSE TFR.AECountryID
						END
							
FROM        AddressEntity AE
INNER JOIN  #tmpFinalResults TFR
ON          AE.ID = TFR.AddressEntityID

DROP TABLE  #tmpFinalResults
GO
	

-- File : DBChanges.2014.04.14.sql   Last Updated : 14 April 2014
Print 'Make changes for Non-member contact category'
GO
-- Add New ContactCategory
IF NOT EXISTS (SELECT * FROM ContactCategory WHERE Name = 'Non-Member')
	BEGIN
		INSERT INTO [dbo].[ContactCategory] ([Name],[Description],[IsShownOnFinish],[IsActive],[Sequence],[IsShownOnActivity])
		VALUES ('Non-Member', 'Non-Member', 1, 1, 12, 0)
	END
GO

-- Add New ContactReason
DECLARE @ContactCategory INT = (SELECT ID FROM ContactCategory WHERE Name = 'Non-Member')
IF NOT EXISTS (SELECT ID FROM ContactReason WHERE Name = 'Non-Member' AND ContactCategoryID = @ContactCategory)
	BEGIN
		INSERT INTO [dbo].[ContactReason] ([ContactCategoryID],[Name],[Description],[IsActive],[IsShownOnScreen],[Sequence])
		VALUES (@ContactCategory, 'Non-Member', 'Non-Member', 1, 1, 5)
	END
GO

-- Add New ContactAction
DECLARE @ContactCategory INT = (SELECT ID FROM ContactCategory WHERE Name = 'Non-Member')
IF NOT EXISTS (SELECT ID FROM ContactAction WHERE Name = 'Transferred Call to Agero'  AND ContactCategoryID = @ContactCategory)
	BEGIN
		INSERT INTO [dbo].[ContactAction] ([ContactCategoryID],[Name],[Description],[IsShownOnScreen],[IsTalkedToRequired],[IsActive],[Sequence],[VendorServiceRatingAdjustment])
		VALUES (@ContactCategory, 'Transferred Call to Agero', 'Transferred to Agero', 1, 0, 1, 1, NULL)
	END

IF NOT EXISTS (SELECT ID FROM ContactAction WHERE Name = 'Wrong Number'  AND ContactCategoryID = @ContactCategory)
	BEGIN
		INSERT INTO [dbo].[ContactAction] ([ContactCategoryID],[Name],[Description],[IsShownOnScreen],[IsTalkedToRequired],[IsActive],[Sequence],[VendorServiceRatingAdjustment])
		VALUES (@ContactCategory, 'Wrong Number', 'Wrong Number', 1, 0, 1, 2, NULL)
	END
	
IF NOT EXISTS (SELECT ID FROM ContactAction WHERE Name = 'Hang up'  AND ContactCategoryID = @ContactCategory)
	BEGIN
		INSERT INTO [dbo].[ContactAction] ([ContactCategoryID],[Name],[Description],[IsShownOnScreen],[IsTalkedToRequired],[IsActive],[Sequence],[VendorServiceRatingAdjustment])
		VALUES (@ContactCategory, 'Hang up', 'Hang up', 1, 0, 1, 3, NULL)
	END

IF NOT EXISTS (SELECT ID FROM ContactAction WHERE Name = 'Havasu forward'  AND ContactCategoryID = @ContactCategory)
	BEGIN
		INSERT INTO [dbo].[ContactAction] ([ContactCategoryID],[Name],[Description],[IsShownOnScreen],[IsTalkedToRequired],[IsActive],[Sequence],[VendorServiceRatingAdjustment])
		VALUES (@ContactCategory, 'Havasu forward', 'Havasu forward', 1, 0, 1, 4, NULL)
	END		

IF NOT EXISTS (SELECT ID FROM ContactAction WHERE Name = 'Transferred to Member Service'  AND ContactCategoryID = @ContactCategory)
	BEGIN
		INSERT INTO [dbo].[ContactAction] ([ContactCategoryID],[Name],[Description],[IsShownOnScreen],[IsTalkedToRequired],[IsActive],[Sequence],[VendorServiceRatingAdjustment])
		VALUES (@ContactCategory, 'Transferred to Member Service', 'Transferred to Member Service', 1, 0, 1, 5, NULL)
	END		

IF NOT EXISTS (SELECT ID FROM ContactAction WHERE Name = 'Questions to become a member' AND ContactCategoryID = @ContactCategory)
	BEGIN
		INSERT INTO [dbo].[ContactAction] ([ContactCategoryID],[Name],[Description],[IsShownOnScreen],[IsTalkedToRequired],[IsActive],[Sequence],[VendorServiceRatingAdjustment])
		VALUES (@ContactCategory, 'Questions to become a member', 'Questions to become a member', 1, 0, 1, 6, NULL)
	END		
	
IF NOT EXISTS (SELECT ID FROM ContactAction WHERE Name = 'Dead air' AND ContactCategoryID = @ContactCategory)
	BEGIN
		INSERT INTO [dbo].[ContactAction] ([ContactCategoryID],[Name],[Description],[IsShownOnScreen],[IsTalkedToRequired],[IsActive],[Sequence],[VendorServiceRatingAdjustment])
		VALUES (@ContactCategory, 'Dead air', 'Dead air', 1, 0, 1, 7, NULL)
	END		
	

GO

-- File : DBChanges.2014.04.14- Lockout questions for Trailer Vehicle Type.sql  Last Updated : 15 April 2014

Print 'Changes for Travel Trailer questions'
GO 
DECLARE @ProductCategoryQuestionID AS INT

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Is this a Class A RV or a travel trailer? '
                                    
                                  
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Is this a Class A RV or a travel trailer? ')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


---------------------------------------------------------------------------------



SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Is the vehicle running?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Is the vehicle running?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End

----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Where are the keys located?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Where are the keys located?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Trunk accessible from cabin?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Trunk accessible from cabin?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Is key a transponder key?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Is key a transponder key?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Do you have the key code?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Do you have the key code?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Reason key is not working?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Reason key is not working?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Power door locks?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Power door locks?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


----------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Side-Impact air bags?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Side-Impact air bags?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


----------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Do you need a locksmith?'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Do you need a locksmith?')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End


----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------

SELECT @ProductCategoryQuestionID = [ID] FROM [dbo].[ProductCategoryQuestion] 
                                    WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
                                    and [QuestionText]='Provide Description'
                                    
IF (SELECT count(*) FROM [dbo].[ProductCategoryQuestionVehicleType]
    WHERE [ProductCategoryQuestionID] = @ProductCategoryQuestionID
    AND [VehicleTypeID] = ( SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')) = 0
    
BEGIN
INSERT INTO [ProductCategoryQuestionVehicleType]
           ([ProductCategoryQuestionID]
           ,[VehicleTypeID]
           ,[VehicleCategoryID]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ((SELECT  TOP 1 [ID] FROM [dbo].[ProductCategoryQuestion] 
             WHERE [ProductCategoryID]= (SELECT ID FROM [dbo].[ProductCategory] WHERE Name='Lockout') 
             and [QuestionText]='Provide Description')
           ,(SELECT ID FROM [dbo].[VehicleType] WHERE Name='Trailer')
           ,NULL
           ,NULL
           ,1)
End
GO

-- File : DBChanges.2014.04.17.sql  Last Updated : 17 April 2014
INSERT INTO Securable VALUES('MENU_LEFT_ADMIN_SECURABLE_MANAGEMENT',NULL,NULL)

DECLARE @SecurableID INT
SET @SecurableID = (SELECT ID FROM Securable WHERE FriendlyName = 'MENU_LEFT_ADMIN_SECURABLE_MANAGEMENT')
DECLARE @RoleID UNIQUEIDENTIFIER
SET @RoleID = (SELECT RoleID FROM aspnet_Roles R
			   JOIN aspnet_Applications  A
			   ON R.ApplicationId = A.ApplicationId
			   WHERE A.ApplicationName = 'DMS'
			   AND R.LoweredRoleName = 'sysadmin')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE RoleID = @RoleID AND SecurableID = @SecurableID)
BEGIN
	INSERT INTO AccessControlList VALUES(@SecurableID,@RoleID,(SELECT ID FROM AccessType WHERE Name = 'ReadWrite'))
END

Go


--
-- SCRIPT to load ProgramDataItem and Values for FORD Nearest qualified dealer question on location selection
--
DECLARE @ProgramID int
DECLARE @ProgramDataItemID int
DECLARE @CreateDate datetime

SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Commercial Truck')
SET @CreateDate = '8/1/2014'

--SELECT ID FROM ProgramDataItem WHERE ProgramID = @ProgramID AND ScreenName = 'LocationContactLog' AND Name = 'OverMileageReason'

IF NOT EXISTS (SELECT ID FROM ProgramDataItem WHERE ProgramID = @ProgramID AND ScreenName = 'LocationContactLog' AND Name = 'OverMileageReason')
BEGIN
	INSERT INTO ProgramDataItem (ProgramID, controltypeid, datatypeid, screenname, name, label, maxlength, sequence, isrequired, isactive, createdate, createby, modifydate, modifyby)
	VALUES (@ProgramID, 3, 1, 'LocationContactLog', 'OverMileageReason', 'If over the mileage limit, select the reason', 50, 6, 0, 1, @CreateDate, 'system', NULL, NULL)
	
	SET @ProgramDataItemID = @@IDENTITY
	
	INSERT INTO ProgramDataItemValue (ProgramDataItemID, value, [description], sequence, createdate, createby, modifydate, modifyby)
	VALUES (@ProgramDataItemID, 1, 'Nearest qualified dealer', 1, @CreateDate, 'system', NULL, NULL)

	INSERT INTO ProgramDataItemValue (ProgramDataItemID, value, description, sequence, createdate, createby, modifydate, modifyby)
	VALUES (@ProgramDataItemID, 2, 'Customer request', 2, @CreateDate, 'system', NULL, NULL)
END
GO


Print 'ApplicationConfiguration Update for Windows Services'
GO
-- This confguration variable was previously coded into the Communication Service but was never set
-- Without this variable the service defaults to a 30 second interval
-- This confiugration variable is used by both the Communication Service and the Notification Service; Hence both services are always on the same interval
IF NOT EXISTS (Select * from ApplicationConfiguration where Name = 'EventNotificationServiceSleepInterval')
BEGIN
INSERT INTO [dbo].[ApplicationConfiguration]
           ([ApplicationConfigurationTypeID]
           ,[ApplicationConfigurationCategoryID]
           ,[ControlTypeID]
           ,[DataTypeID]
           ,[Name]
           ,[Value]
           ,[CreateDate]
           ,[CreateBy])
     VALUES
           (10
           ,NULL
           ,NULL
           ,2
           ,'EventNotificationServiceSleepInterval'
           ,15000
           ,'8/1/2014'
           ,'system')
END
GO


/*
-- File : DBChanges.2014.04.14.ProgramProduct Updates.sql  Last Updated : 15 April 2014
Print 'Apply the many configuration changes for ProgramProduct'
GO
-- Set ServiceCoverageDescription on ProgramProduct Table
-- Sanghi 18 - July 2014 Affecting 7K Approx
UPDATE pp Set ServiceCoverageDescription = 
		CASE
			WHEN pp.IsServiceCoverageBestValue = 1 AND ISNULL(pp.ServiceMileageLimit,0)=0
				THEN pr.Name + ': Best Value'
				
			WHEN pp.IsServiceCoverageBestValue = 1 AND ISNULL(pp.ServiceMileageLimit,0) > 0 
				THEN pr.Name + ': Best value with ' + CAST(pp.ServiceMileageLimit AS nvarchar(10)) + ' Miles' + ' Towing Limit'
				
			WHEN ISNULL(pp.ServiceCoverageLimit,0) > 0 AND ISNULL(pp.ServiceMileageLimit,0)= 0
				THEN pr.Name + ': $' + CAST(CONVERT(int,pp.ServiceCoverageLimit) AS nvarchar(10)) + ' USD Limit'
				
			WHEN ISNULL(pp.ServiceCoverageLimit,0)= 0 AND ISNULL(pp.ServiceMileageLimit,0) > 0 
				THEN pr.Name + ': ' + CAST(pp.ServiceMileageLimit AS nvarchar(10)) + ' Miles' + ' Towing Limit'
				
			WHEN ISNULL(pp.ServiceCoverageLimit,0) > 0 AND ISNULL(pp.ServiceMileageLimit,0)> 0
				THEN pr.Name + ': $' + CAST(CONVERT(int,pp.ServiceCoverageLimit) AS nvarchar(10)) + ' USD Limit' + ' with ' + CAST(pp.ServiceMileageLimit AS nvarchar(10)) + ' Miles' + ' Towing Limit'
				
			WHEN ISNULL(pp.ServiceCoverageLimit,0)=0 AND ISNULL(pp.ServiceMileageLimit,0)= 0
				AND pp.ProductID IN (Select ID From Product Where Name in ('Tech','Information','Concierge'))
				--AND pp.IsReimbursementOnly <> 1
				THEN pr.Name + ': No charge for service'
				
			WHEN ISNULL(pp.ServiceCoverageLimit,0)=0 AND ISNULL(pp.ServiceMileageLimit,0)= 0
				THEN pr.Name + ': Assist Only'
				ELSE ''
		  END 
FROM	ProgramProduct pp
JOIN	Program p on p.ID = pp.ProgramID
JOIN	Product pr on pr.ID = pp.ProductID
JOIN	ProductCategory pc on pc.ID = pr.ProductCategoryID
GO

-- Set special ServiceCoverageDescription values for Program 266 (Ford ESP)
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Fluid Delivery - HD: $200 USD Limit' WHERE ProgramID = 266 AND ProductID = 2
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Jump Start - HD: $200 USD Limit' WHERE ProgramID = 266 AND ProductID = 5
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Basic Lockout: $100 USD Limit for MD; $200 USD Limit for HD' WHERE ProgramID = 266 AND ProductID = 8
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Locksmith: $100 USD Limit for MD; $200 USD Limit for HD' WHERE ProgramID = 266 AND ProductID = 9
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Mobile Mechanic: $100 USD Limit for MD; $200 USD Limit for HD' WHERE ProgramID = 266 AND ProductID = 10
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Tire Change - HD: $200 USD Limit' WHERE ProgramID = 266 AND ProductID = 131
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Tire Repair - HD: $200 USD Limit' WHERE ProgramID = 266 AND ProductID = 132
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Tow - HD: $200 USD Limit with 35 Miles Towing Limit' WHERE ProgramID = 266 AND ProductID = 140
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Tow - HD - Landoll/Lowboy: $200 USD Limit with 35 Miles Towing Limit' WHERE ProgramID = 266 AND ProductID = 143
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Winch - HD: $200 USD Limit' WHERE ProgramID = 266 AND ProductID = 157
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Mobile Mechanic - Diesel: $100 USD Limit for MD; $200 USD Limit for HD' WHERE ProgramID = 266 AND ProductID = 11
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Mobile Mechanic - RV House: $100 USD Limit for MD; $200 USD Limit for HD' WHERE ProgramID = 266 AND ProductID = 12
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Mobile Mechanic - Welder: $100 USD Limit for MD; $200 USD Limit for HD' WHERE ProgramID = 266 AND ProductID = 13
GO
*/



--TFS
UPDATE QueueStatus SET Color = '#EBCCD1' WHERE Color = '#EE6F4C'

-- TFS 637
UPDATE QueueStatus SET Color = '#F2DEDE' WHERE Color = '#EBCCD1'

UPDATE QueueStatus SET Color = '#FCF8E3' WHERE Color = '#F1DD40'


-- Added to prevent Notification Service from selecting historical data upon initial deployment of the service
UPDATE EventLog SET NotificationQueueDate = GETDATE() WHERE EventID NOT IN (SELECT EventID FROM EventSubscription)
GO


