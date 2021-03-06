/****** Object:  StoredProcedure [dbo].[dms_ClientPortal_addressType_list]    Script Date: 04/29/2014 02:13:21 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ClientPortal_addressType_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ClientPortal_addressType_list] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_ClientPortal_addressType_list]
AS
BEGIN
	SELECT [ID],
		   [Name],
		   [Description] FROM AddressType(NOLOCK)
	WHERE IsActive = 1
	ORDER BY Sequence ASC
END
GO

GO

GO

GO
/****** Object:  StoredProcedure [dbo].[dms_ClientPortal_country_list]    Script Date: 04/29/2014 02:13:21 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ClientPortal_country_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ClientPortal_country_list] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_ClientPortal_country_list] 
AS
BEGIN
	SELECT [ID],
		   [Name],
		   [ISOCode] FROM Country (NOLOCK)
	WHERE IsActive = 1
	ORDER BY Sequence ASC
END
GO

GO

GO

GO
/****** Object:  StoredProcedure [dbo].[dms_ClientPortal_phoneTypes_list]    Script Date: 04/29/2014 02:13:21 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ClientPortal_phoneTypes_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ClientPortal_phoneTypes_list] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_ClientPortal_phoneTypes_list] 
AS
BEGIN
	SELECT [ID],
		   [Name],
		   [Description] FROM PhoneType(NOLOCK) 
	WHERE IsActive = 1
	ORDER BY Sequence ASC
END
GO

GO

GO

GO
/****** Object:  StoredProcedure [dbo].[dms_ClientPortal_prefix_list]    Script Date: 04/29/2014 02:13:21 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ClientPortal_prefix_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ClientPortal_prefix_list] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_ClientPortal_prefix_list] 
AS
BEGIN
	SELECT [ID],
		   [Name],
		   [Description] FROM Prefix (NOLOCK)
	ORDER BY Sequence ASC
END
GO

GO

GO

GO
/****** Object:  StoredProcedure [dbo].[dms_ClientPortal_program_list]    Script Date: 04/29/2014 02:13:21 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ClientPortal_program_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ClientPortal_program_list] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [dbo].[dms_ClientPortal_program_list] 18
CREATE PROCEDURE [dbo].[dms_ClientPortal_program_list] (
	@clientID	INT
 ) 
AS
BEGIN
	SELECT [ID],
		   [Name],
		   [Description] FROM Program (NOLOCK)
	WHERE ClientID = @ClientID
	AND IsActive = 1
	AND IsWebRegistrationEnabled = 1
	AND IsGroup <> 1
	ORDER BY Name
END
GO

GO

GO

GO
/****** Object:  StoredProcedure [dbo].[dms_ClientPortal_state_list]    Script Date: 04/29/2014 02:13:21 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ClientPortal_state_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ClientPortal_state_list] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_ClientPortal_state_list](@countryID INT = NULL)
AS
BEGIN
	SELECT [ID],
		   [Name],
		   [Abbreviation] FROM StateProvince(NOLOCK)
	WHERE (@countryID IS NULL) OR (CountryID = @countryID)
	ORDER BY Sequence ASC
END
GO

GO

GO

GO
/****** Object:  StoredProcedure [dbo].[dms_ClientPortal_suffix_list]    Script Date: 04/29/2014 02:13:21 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ClientPortal_suffix_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ClientPortal_suffix_list] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_ClientPortal_suffix_list] 
AS
BEGIN
	SELECT [ID],
		   [Name],
		   [Description] FROM Suffix(NOLOCK)
	ORDER BY Sequence ASC
END
GO

GO

GO

GO
/****** Object:  StoredProcedure [dbo].[dms_POComments]    Script Date: 04/29/2014 02:13:21 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_POComments]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_POComments] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[dms_POComments](@i5PurchaseOrderID INT, @serviceRequestID INT)
AS  
BEGIN  
	--DECLARE @i5purchaseorderID as INT
	--DECLARE @servicerequestID as INT

-- Get Comments
SELECT c.Description, c.CreateBy, c.CreateDate
FROM  Comment c
JOIN ServiceRequest sr on sr.ID = c.RecordID and c.EntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
WHERE
	c.EntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
	and c.RecordID = @serviceRequestID

UNION

-- Get all Send PO's
SELECT
	'Dispatch PO ' + cm.Name
	 + ' - ' +
	 CASE 
		WHEN cm.Name = 'Fax' THEN cl.PhoneNumber 
		WHEN cm.Name = 'Email' THEN cl.Email 
		WHEN cm.Name = 'Verbally' THEN ''
		ELSE ''
		END  AS Description
	, cl.CreateBy
	, cl.CreateDate
FROM PurchaseOrder po 
JOIN ContactLogLink cll ON cll.RecordID = po.ID AND cll.EntityID = (SELECT ID FROM Entity WHERE name = 'PurchaseOrder')
JOIN ContactLog cl ON cl.ID = cll.ContactLogID
JOIN ContactMethod cm ON cm.ID = cl.ContactMethodID
JOIN ContactLogAction cla ON cla.ContactLogID = cl.ID 
JOIN ContactAction cac ON cac.ID = cla.ContactActionID AND cac.Name = 'Pending' AND cac.ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ContactVendor')
WHERE
	po.LegacyReferenceNumber = @i5purchaseorderID
	AND po.IsActive = 1

UNION

-- Get all PO Cancel Comments
SELECT
	'Cancel Comment: ' + po.CancellationComment AS Description
	, el.CreateBy
	, el.CreateDate
FROM PurchaseOrder po
JOIN EventLogLink ell ON ell.RecordID = po.ID and ell.EntityID = (SELECT ID FROM Entity WHERE name = 'PurchaseOrder')
JOIN EventLog el ON el.ID = ell.EventLogID
JOIN Event e on e.ID = el.EventID AND e.Name = 'CancelPO'
WHERE
	po.LegacyReferenceNumber = @i5purchaseorderID 
	AND isnull(po.CancellationComment, '') <> ''
	AND po.IsActive = 1


UNION

-- Get all PO GOA Comments
SELECT
	'GOA Comment: ' + po.GOAComment AS Description
	, po.CreateBy
	, po.CreateDate
FROM PurchaseOrder po
WHERE
	po.LegacyReferenceNumber = @i5PurchaseOrderID
	AND po.IsActive = 1
	AND isnull(po.GOAComment,'') <> ''
	AND po.IsGOA = 1

ORDER BY CreateDate

END
GO

GO

GO

GO
/****** Object:  StoredProcedure [dbo].[dms_Program_Management_SaveServiceEventLimitInformation]    Script Date: 04/29/2014 02:13:22 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveServiceEventLimitInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveServiceEventLimitInformation] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_Program_Management_SaveServiceEventLimitInformation]( 
   @id INT = NULL
 , @programID INT = NULL
 , @productCategoryID INT = NULL
 , @productID INT = NULL
 , @vehicleTypeID INT = NULL
 , @vehicleCategoryID INT = NULL
 , @description NVARCHAR(MAX) = NULL
 , @limit INT = NULL
 , @limitDuration INT = NULL
 , @limitDurationUOM NVARCHAR(100) = NULL
 , @storedProcedureName NVARCHAR(100) = NULL
 , @currentUser NVARCHAR(100) = NULL 
 , @isActive BIT = NULL
 )
 AS
 BEGIN
 IF @id > 0 
	 BEGIN
		UPDATE ProgramServiceEventLimit 
		SET ProductCategoryID = @productCategoryID,
			ProductID = @productID,
			VehicleTypeID = @vehicleTypeID,
			VehicleCategoryID = @vehicleCategoryID,
			Description = @description,
			Limit = @limit,
			LimitDuration = @limitDuration,
			LimitDurationUOM=@limitDurationUOM,
			IsActive = @isActive,
			StoredProcedureName= @storedProcedureName
		WHERE ID = @id
	 END
ELSE
	BEGIN
		INSERT INTO ProgramServiceEventLimit (
			ProgramID,
			ProductCategoryID,
			ProductID,
			VehicleTypeID,
			VehicleCategoryID,
			Description,
			Limit,
			LimitDuration,
			LimitDurationUOM,
			StoredProcedureName,
			IsActive,
			CreateBy,
			CreateDate		
		)
		VALUES(
			@programID,
			@productCategoryID,
			@productID,
			@vehicleTypeID,
			@vehicleCategoryID,
			@description,
			@limit,
			@limitDuration,
			@limitDurationUOM,
			@storedProcedureName,
			@isActive,
			@currentUser,
			GETDATE()
		)
	END
END
GO

GO

GO

GO
/****** Object:  StoredProcedure [dbo].[dms_Send_History_List]    Script Date: 04/29/2014 02:13:22 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Send_History_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Send_History_List] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC [dbo].[dms_Send_History_List] 2
 CREATE PROCEDURE [dbo].[dms_Send_History_List]( 
  @PurchaseOrderId  INT = NULL
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
-- 	Select ca.Name as ContactMethod, cl.CreateDate as DateSent
--	From ContactLog cl
--	Join ContactLogLink cll on cll.ContactLogID = cl.ID
--	Join ContactLogAction cla on cla.ContactLogID = cl.ID 
--	Join ContactAction ca on ca.ID =  cla.ContactActionID 
--	and ca.Name in ('Pending','Sent','SendFailure') 
--	--and ca.ContactCategoryID = (Select ID From ContactCategory Where Name = 'ContactVendor')
--Where
--	cll.EntityID = (Select ID From Entity Where Name = 'PurchaseOrder')
--	AND
--	 cll.RecordID = @purchaseOrderId
Select cm.Name as ContactMethod
, CASE
When cm.Name = 'Fax' then cl.PhoneNumber + ' (' + cl.TalkedTo + ')'
When cm.Name = 'Email' then cl.Email
END as SentTo 

, ca.Name as ContactAction
, cl.CreateDate as DateSent
, cl.CreateBy as Username
From ContactLog cl
Join ContactLogLink cll on cll.ContactLogID = cl.ID
Join ContactLogAction cla on cla.ContactLogID = cl.ID 
Join ContactAction ca on ca.ID = cla.ContactActionID 
Join ContactMethod cm on cm.ID = cl.ContactMethodID
and ca.Name in ('Pending','Sent','SendFailure') 
Where
cll.EntityID = (Select ID From Entity Where Name = 'PurchaseOrder')
AND
cll.RecordID = @PurchaseOrderID 
	 END
GO

GO

GO

GO
/****** Object:  StoredProcedure [dbo].[dms_ServiceRequestList_BySalesChannel_Get]    Script Date: 04/29/2014 02:13:22 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ServiceRequestList_BySalesChannel_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ServiceRequestList_BySalesChannel_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC dms_ServiceRequestList_BySalesChannel_Get '4793','1/1/2013', '7/31/2013'
Create PROCEDURE [dbo].[dms_ServiceRequestList_BySalesChannel_Get]( 
	@SalesChannelIDs NVARCHAR(MAX),
	@startDate DATETIME,
	@endDate DATETIME
 ) 
AS 
 BEGIN
 
 
 --set @clientIDs = '4793,4448,4742,4425,4772,4748,4748,4748,4753,4757'
  
	DECLARE @tblClients TABLE (
	ClientID	nvarchar(50)
	)
	INSERT INTO @tblClients
	SELECT * FROM [dbo].[fnSplitString](@SalesChannelIDs,',')
	
	SELECT 
			CLT.ClientID AS [ClientID]
			, P.ID AS [ProgramID]
			, P.Name AS [ProgramName]
			, SR.ID AS [SRNumber]
			, SR.CreateDate AS [SRDate]
			, SRS.Name AS [SRStatus]
			, PC.Name AS [SRServiceTypeName]
			, PC.Description AS [SRServiceTypeDescription]
			, MS.MembershipNumber AS [MemberNumber]
			, M.Prefix AS [Prefix]
			, M.FirstName AS [FirstName]
			, M.MiddleName AS [MiddleName]
			, M.LastName AS [LastName]
			, M.Suffix AS [Suffix]
			, REPLACE(RTRIM(
			  COALESCE(M.LastName,'')+  
			  COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')+  
			  COALESCE(', '+ CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+
			  COALESCE(' ' + LEFT(M.MiddleName,1),'')
				),'','') AS [MemberName]
			, PO.ID AS [POID]
			, PO.PurchaseOrderNumber AS [PONumber]
			, PO.IssueDate AS [POIssueDate]
			, POS.Name AS [POStatus]
			, PO.CancellationReasonID AS [POCancellationReasonID]
			, POCR.Name AS [POCancellationReasonName]
			, PO.CancellationReasonOther AS [POCancellationReasonOther]
			, PO.CancellationComment AS [POCancellationComment]
			, PO.IsGOA AS [POIsGOA]
			, PO.GOAReasonID AS [POGOAReasonID]
			, POGR.Name AS [POGOAReasonName]
			, PO.GOAReasonOther AS [POGOAReasonOther]
			, PO.GOAComment AS [POGOAComment]
			, V.VendorNumber AS [ISPNumber]
			, V.Name AS [ISPName]
	FROM		ServiceRequest SR WITH (NOLOCK)
	LEFT JOIN	ServiceRequestStatus SRS WITH (NOLOCK) ON SRS.ID = SR.ServiceRequestStatusID
	LEFT JOIN	ProductCategory PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID
	LEFT JOIN	PurchaseOrder PO WITH (NOLOCK) ON PO.ServiceRequestID = SR.ID AND PO.IsActive = '1' AND PO.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued', 'Issued-Paid', 'Cancelled'))
	LEFT JOIN	PurchaseOrderStatus POS WITH (NOLOCK) ON POS.ID = PO.PurchaseOrderStatusID 
	LEFT JOIN	PurchaseOrderCancellationReason POCR WITH (NOLOCK) ON POCR.ID = PO.CancellationReasonID
	LEFT JOIN	PurchaseOrderGOAReason POGR WITH (NOLOCK) ON POGR.ID = PO.GOAReasonID
	LEFT JOIN	[Case] C WITH (NOLOCK) ON C.ID = SR.CaseID
	LEFT JOIN	Program P WITH (NOLOCK) ON P.ID = C.ProgramID
	LEFT JOIN	Member M WITH (NOLOCK) ON M.ID = C.MemberID
	LEFT JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
	LEFT JOIN	VendorLocation VL WITH (NOLOCK) ON VL.ID = PO.VendorLocationID
	LEFT JOIN	Vendor V WITH (NOLOCK) ON V.ID = VL.VendorID
	JOIN		@tblClients CLT ON CLT.ClientID	= M.AccountSource
	WHERE		SRS.Name IN ('Complete','Cancelled')
	AND			((@startDate IS NULL AND @endDate IS NULL) OR (SR.CreateDate BETWEEN @StartDate AND @EndDate))
	AND			PO.IsActive = '1' 
	AND			PO.PurchaseOrderStatusID <> (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending')
	ORDER BY
				SR.ID, 
				PO.PurchaseOrderNumber DESC
	
 END
GO

GO

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
		and p.Name Not in ('Concierge', 'Information', 'Tech')
		and p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee')
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
		and p.Name Not in ('Concierge', 'Information', 'Tech')
		and p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials')
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

GO

GO
/****** Object:  StoredProcedure [dbo].[dms_Vendor_PO_Details_Get]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_PO_Details_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_PO_Details_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC dms_Vendor_PO_Details_Get @VendorID=1
 CREATE PROCEDURE [dbo].[dms_Vendor_PO_Details_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @VendorID INT 
 ) 
 AS 
 BEGIN 
  SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
PurchaseOrderNumberOperator="-1" 
IssueDateOperator="-1" 
AddressOperator="-1" 
MemberNameOperator="-1" 
CreateByOperator="-1" 
StatusOperator="-1" 
ServiceOperator="-1" 
PurchaseOrderAmountOperator="-1" 
PaidDateOperator="-1" 
MemberNumberOperator="-1" 
ServiceRequestIDOperator="-1"
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
PurchaseOrderNumberOperator INT NOT NULL,
PurchaseOrderNumberValue nvarchar(100) NULL,
IssueDateOperator INT NOT NULL,
IssueDateValue datetime NULL,
AddressOperator INT NOT NULL,
AddressValue nvarchar(100) NULL,
MemberNameOperator INT NOT NULL,
MemberNameValue nvarchar(100) NULL,
CreateByOperator INT NOT NULL,
CreateByValue nvarchar(100) NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL,
ServiceOperator INT NOT NULL,
ServiceValue nvarchar(100) NULL,
PurchaseOrderAmountOperator INT NOT NULL,
PurchaseOrderAmountValue nvarchar(100) NULL,
PaidDateOperator INT NOT NULL,
PaidDateValue datetime NULL,
MemberNumberOperator INT NOT NULL,
MemberNumberValue int NULL,
ServiceRequestIDOperator INT NOT NULL,
ServiceRequestIDValue int NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	PurchaseOrderNumber nvarchar(100)  NULL ,
	IssueDate datetime  NULL ,
	Address nvarchar(100)  NULL ,
	MemberName nvarchar(100)  NULL ,
	CreateBy nvarchar(100)  NULL ,
	Status nvarchar(100)  NULL ,
	Service nvarchar(100)  NULL ,
	PurchaseOrderAmount nvarchar(100)  NULL ,
	PaidDate datetime  NULL ,
	MemberNumber int  NULL ,
	ServiceRequestID int  NULL   
) 
CREATE TABLE #FinalResults1( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	PurchaseOrderNumber nvarchar(100)  NULL ,
	IssueDate datetime  NULL ,
	Address nvarchar(100)  NULL ,
	MemberName nvarchar(100)  NULL ,
	CreateBy nvarchar(100)  NULL ,
	Status nvarchar(100)  NULL ,
	Service nvarchar(100)  NULL ,
	PurchaseOrderAmount nvarchar(100)  NULL ,
	PaidDate datetime  NULL ,
	MemberNumber int  NULL ,
	ServiceRequestID int  NULL   
) 
INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@PurchaseOrderNumberOperator','INT'),-1),
	T.c.value('@PurchaseOrderNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@IssueDateOperator','INT'),-1),
	T.c.value('@IssueDateValue','datetime') ,
	ISNULL(T.c.value('@AddressOperator','INT'),-1),
	T.c.value('@AddressValue','nvarchar(100)') ,
	ISNULL(T.c.value('@MemberNameOperator','INT'),-1),
	T.c.value('@MemberNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CreateByOperator','INT'),-1),
	T.c.value('@CreateByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ServiceOperator','INT'),-1),
	T.c.value('@ServiceValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PurchaseOrderAmountOperator','INT'),-1),
	T.c.value('@PurchaseOrderAmountValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PaidDateOperator','INT'),-1),
	T.c.value('@PaidDateValue','datetime') ,
	ISNULL(T.c.value('@MemberNumberOperator','INT'),-1),
	T.c.value('@MemberNumberValue','int') ,
	ISNULL(T.c.value('@ServiceRequestIDOperator','INT'),-1),
	T.c.value('@ServiceRequestIDValue','int')  
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)
INSERT INTO #FinalResults1
SELECT PO.ID
	 , PO.PurchaseOrderNumber
	 , ISNULL(CONVERT(NVARCHAR(10),PO.IssueDate,101),'') AS IssueDate
	 , ISNULL(REPLACE(RTRIM(
		COALESCE(PO.BillingAddressLine1, '') + 
	 	COALESCE(PO.BillingAddressLine2, '') +     
		COALESCE(PO.BillingAddressLine3, '') +     
		COALESCE(', ' + PO.BillingAddressCity, '') +
		COALESCE(', ' + RTRIM(PO.BillingAddressStateProvince), '') +
		COALESCE(' ' + PO.BillingAddressPostalCode, '') +
		COALESCE(' ' + PO.BillingAddressCountryCode, '') 
		), '  ', ' ')
	  ,'') AS [Address]
	 , ISNULL(REPLACE(RTRIM(
		COALESCE(M.FirstName, '') +
		COALESCE(' ' + M.MiddleName, '') +
		COALESCE(' ' + M.LastName, '') +
		COALESCE(' ' + M.Suffix, '') 
	    ), '  ', ' ' )
	  ,'') AS [MemberName] 
	 , PO.CreateBy
	 , POS.Name AS [Status]
	 , P.Name AS [Service]
	 , PO.PurchaseOrderAmount
	 , '01/01/2000' AS PaidDate --- WHere do we get this?	 
	 , M.MembershipID AS MemberNumber
	 , SR.ID AS ServiceRequestID
FROM PurchaseOrder PO
LEFT OUTER JOIN	VendorLocation VL 
				ON VL.ID = PO.VendorLocationID
LEFT OUTER JOIN	Vendor V
				ON V.ID = VL.VendorID
LEFT OUTER JOIN	ServiceRequest SR
				ON SR.ID = PO.ServiceRequestID
LEFT OUTER JOIN	[Case] C 
				ON C.ID = SR.CaseID
LEFT OUTER JOIN	Member M
				ON M.ID = C.MemberID
LEFT OUTER JOIN	PurchaseOrderStatus POS
				ON POS.ID = PO.PurchaseOrderStatusID
LEFT OUTER JOIN	Product P            -- Really need to verify through PODetail
				ON P.ID = PO.ProductID
				
WHERE		PO.IsActive = 1
AND			V.ID = @VendorID
ORDER BY	PO.PurchaseOrderNumber DESC
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.PurchaseOrderNumber,
	T.IssueDate,
	T.Address,
	T.MemberName,
	T.CreateBy,
	T.Status,
	T.Service,
	T.PurchaseOrderAmount,
	T.PaidDate,
	T.MemberNumber,
	T.ServiceRequestID
FROM  #FinalResults1 T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.IDOperator = -1 ) 
 OR 
	 ( TMP.IDOperator = 0 AND T.ID IS NULL ) 
 OR 
	 ( TMP.IDOperator = 1 AND T.ID IS NOT NULL ) 
 OR 
	 ( TMP.IDOperator = 2 AND T.ID = TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 3 AND T.ID <> TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 7 AND T.ID > TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 8 AND T.ID >= TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 9 AND T.ID < TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 10 AND T.ID <= TMP.IDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.PurchaseOrderNumberOperator = -1 ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 0 AND T.PurchaseOrderNumber IS NULL ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 1 AND T.PurchaseOrderNumber IS NOT NULL ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 2 AND T.PurchaseOrderNumber = TMP.PurchaseOrderNumberValue ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 3 AND T.PurchaseOrderNumber <> TMP.PurchaseOrderNumberValue ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 4 AND T.PurchaseOrderNumber LIKE TMP.PurchaseOrderNumberValue + '%') 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 5 AND T.PurchaseOrderNumber LIKE '%' + TMP.PurchaseOrderNumberValue ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 6 AND T.PurchaseOrderNumber LIKE '%' + TMP.PurchaseOrderNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.IssueDateOperator = -1 ) 
 OR 
	 ( TMP.IssueDateOperator = 0 AND T.IssueDate IS NULL ) 
 OR 
	 ( TMP.IssueDateOperator = 1 AND T.IssueDate IS NOT NULL ) 
 OR 
	 ( TMP.IssueDateOperator = 2 AND T.IssueDate = TMP.IssueDateValue ) 
 OR 
	 ( TMP.IssueDateOperator = 3 AND T.IssueDate <> TMP.IssueDateValue ) 
 OR 
	 ( TMP.IssueDateOperator = 7 AND T.IssueDate > TMP.IssueDateValue ) 
 OR 
	 ( TMP.IssueDateOperator = 8 AND T.IssueDate >= TMP.IssueDateValue ) 
 OR 
	 ( TMP.IssueDateOperator = 9 AND T.IssueDate < TMP.IssueDateValue ) 
 OR 
	 ( TMP.IssueDateOperator = 10 AND T.IssueDate <= TMP.IssueDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.AddressOperator = -1 ) 
 OR 
	 ( TMP.AddressOperator = 0 AND T.Address IS NULL ) 
 OR 
	 ( TMP.AddressOperator = 1 AND T.Address IS NOT NULL ) 
 OR 
	 ( TMP.AddressOperator = 2 AND T.Address = TMP.AddressValue ) 
 OR 
	 ( TMP.AddressOperator = 3 AND T.Address <> TMP.AddressValue ) 
 OR 
	 ( TMP.AddressOperator = 4 AND T.Address LIKE TMP.AddressValue + '%') 
 OR 
	 ( TMP.AddressOperator = 5 AND T.Address LIKE '%' + TMP.AddressValue ) 
 OR 
	 ( TMP.AddressOperator = 6 AND T.Address LIKE '%' + TMP.AddressValue + '%' ) 
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
	 ( TMP.CreateByOperator = -1 ) 
 OR 
	 ( TMP.CreateByOperator = 0 AND T.CreateBy IS NULL ) 
 OR 
	 ( TMP.CreateByOperator = 1 AND T.CreateBy IS NOT NULL ) 
 OR 
	 ( TMP.CreateByOperator = 2 AND T.CreateBy = TMP.CreateByValue ) 
 OR 
	 ( TMP.CreateByOperator = 3 AND T.CreateBy <> TMP.CreateByValue ) 
 OR 
	 ( TMP.CreateByOperator = 4 AND T.CreateBy LIKE TMP.CreateByValue + '%') 
 OR 
	 ( TMP.CreateByOperator = 5 AND T.CreateBy LIKE '%' + TMP.CreateByValue ) 
 OR 
	 ( TMP.CreateByOperator = 6 AND T.CreateBy LIKE '%' + TMP.CreateByValue + '%' ) 
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
	 ( TMP.PurchaseOrderAmountOperator = -1 ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 0 AND T.PurchaseOrderAmount IS NULL ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 1 AND T.PurchaseOrderAmount IS NOT NULL ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 2 AND T.PurchaseOrderAmount = TMP.PurchaseOrderAmountValue ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 3 AND T.PurchaseOrderAmount <> TMP.PurchaseOrderAmountValue ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 4 AND T.PurchaseOrderAmount LIKE TMP.PurchaseOrderAmountValue + '%') 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 5 AND T.PurchaseOrderAmount LIKE '%' + TMP.PurchaseOrderAmountValue ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 6 AND T.PurchaseOrderAmount LIKE '%' + TMP.PurchaseOrderAmountValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PaidDateOperator = -1 ) 
 OR 
	 ( TMP.PaidDateOperator = 0 AND T.PaidDate IS NULL ) 
 OR 
	 ( TMP.PaidDateOperator = 1 AND T.PaidDate IS NOT NULL ) 
 OR 
	 ( TMP.PaidDateOperator = 2 AND T.PaidDate = TMP.PaidDateValue ) 
 OR 
	 ( TMP.PaidDateOperator = 3 AND T.PaidDate <> TMP.PaidDateValue ) 
 OR 
	 ( TMP.PaidDateOperator = 7 AND T.PaidDate > TMP.PaidDateValue ) 
 OR 
	 ( TMP.PaidDateOperator = 8 AND T.PaidDate >= TMP.PaidDateValue ) 
 OR 
	 ( TMP.PaidDateOperator = 9 AND T.PaidDate < TMP.PaidDateValue ) 
 OR 
	 ( TMP.PaidDateOperator = 10 AND T.PaidDate <= TMP.PaidDateValue ) 

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
	 ( TMP.MemberNumberOperator = 7 AND T.MemberNumber > TMP.MemberNumberValue ) 
 OR 
	 ( TMP.MemberNumberOperator = 8 AND T.MemberNumber >= TMP.MemberNumberValue ) 
 OR 
	 ( TMP.MemberNumberOperator = 9 AND T.MemberNumber < TMP.MemberNumberValue ) 
 OR 
	 ( TMP.MemberNumberOperator = 10 AND T.MemberNumber <= TMP.MemberNumberValue ) 

 ) 
 
 AND 

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
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'ASC'
	 THEN T.PurchaseOrderNumber END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'DESC'
	 THEN T.PurchaseOrderNumber END DESC ,

	 CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'ASC'
	 THEN T.IssueDate END ASC, 
	 CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'DESC'
	 THEN T.IssueDate END DESC ,

	 CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'
	 THEN T.Address END ASC, 
	 CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'
	 THEN T.Address END DESC ,

	 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'
	 THEN T.MemberName END ASC, 
	 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'
	 THEN T.MemberName END DESC ,

	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
	 THEN T.CreateBy END ASC, 
	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
	 THEN T.CreateBy END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC ,

	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'ASC'
	 THEN T.Service END ASC, 
	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'DESC'
	 THEN T.Service END DESC ,

	 CASE WHEN @sortColumn = 'PurchaseOrderAmount' AND @sortOrder = 'ASC'
	 THEN T.PurchaseOrderAmount END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderAmount' AND @sortOrder = 'DESC'
	 THEN T.PurchaseOrderAmount END DESC ,

	 CASE WHEN @sortColumn = 'PaidDate' AND @sortOrder = 'ASC'
	 THEN T.PaidDate END ASC, 
	 CASE WHEN @sortColumn = 'PaidDate' AND @sortOrder = 'DESC'
	 THEN T.PaidDate END DESC ,
	 
	 CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'
	 THEN T.MemberNumber END ASC, 
	 CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'
	 THEN T.MemberNumber END DESC ,

	 CASE WHEN @sortColumn = 'ServiceRequestID' AND @sortOrder = 'ASC'
	 THEN T.ServiceRequestID END ASC, 
	 CASE WHEN @sortColumn = 'ServiceRequestID' AND @sortOrder = 'DESC'
	 THEN T.ServiceRequestID END DESC 



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
DROP TABLE #FinalResults1
END
GO

GO

GO

GO
/****** Object:  StoredProcedure [dbo].[dms_Vendor_Services_List_Get]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Services_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Services_List_Get] 
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
	FROM	Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
	LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('AdditionalService')
	AND p.Name Not in ('Concierge', 'Information', 'Tech')
	AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials')	
	
	UNION ALL
	
	SELECT 
			4 AS SortOrder
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

GO
/****** Object:  UserDefinedFunction [dbo].[fnc_BillingCalcPriceUsingRateType]    Script Date: 04/29/2014 02:13:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_BillingCalcPriceUsingRateType]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_BillingCalcPriceUsingRateType]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop function dbo.fnc_BillingCalcPriceUsingRateType


CREATE function [dbo].[fnc_BillingCalcPriceUsingRateType]
--ALTER function [dbo].[fnc_BillingCalcPriceUsingRateType]
(	@pRateTypeName as nvarchar(50)=null,
	@pBaseQuantity as int=null,
	@pBaseAmount as money=null,
	@pBasePercentage as float=null)
returns money
as
begin

	declare @EventPrice as money

	select @EventPrice = 

	case
	
		when @pRateTypeName = 'AmountEach' then (@pBaseQuantity * @pBaseAmount)
	
		when @pRateTypeName = 'PercentageEach' then (@pBaseQuantity * @pBaseAmount * @pBasePercentage)
	
		when @pRateTypeName = 'AmountPassThru' then (@pBaseAmount)
	
		when @pRateTypeName = 'AmountFixed' then (@pBaseQuantity * @pBaseAmount)

		when @pRateTypeName = 'Manual' then null

		else 0.00

	end

return @EventPrice

end
GO

GO

GO

GO
/****** Object:  UserDefinedFunction [dbo].[fnc_BillingVINModel]    Script Date: 04/29/2014 02:13:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_BillingVINModel]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_BillingVINModel]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop function dbo.fnc_BillingVINModel

-- select top 1000 dbo.fnc_BillingVINModel(VehicleVIN) as VINModel, *  from [case] where VehicleVin is not null

CREATE function [dbo].[fnc_BillingVINModel]
--ALTER function [dbo].[fnc_BillingVINModel]
(@pVIN as nvarchar(50)=null)
returns nvarchar(50)
as
begin

	declare @VINModel as nvarchar(50)

	select @VINModel = 

	case
		 when substring(@pVIN,2,1) <> 'F' then ''
		 when substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('e3','s3') then 'E-350'
		 when substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('e4','s4') then 'E-450'
		 when substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('f3','w3','x3') then 'F-350'
		 when substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('f4','w4','x4') then 'F-450'
		 when substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('f5','w5','x5') then 'F-550'
		 when substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('f6','w6','x6') then 'F-650'
		 when substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('f7','w7','x7') then 'F-750'
		 when substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('l4','l5') then 'LCF'
		 else 'Unidentified'
	end
	

return @VINModel

end
GO

GO

GO

GO
/****** Object:  UserDefinedFunction [dbo].[fnc_BillingVINModelYear]    Script Date: 04/29/2014 02:13:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_BillingVINModelYear]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_BillingVINModelYear]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop function dbo.fnc_BillingVINModelYear

-- select top 1000 dbo.fnc_BillingVINModelYear(VehicleVIN) as VINModelYear, *  from [case] where VehicleVin is not null

CREATE function [dbo].[fnc_BillingVINModelYear]
--ALTER function [dbo].[fnc_BillingVINModelYear]
(@pVIN as nvarchar(50)=null)
returns nvarchar(4)
as
begin

	declare @VINModelYear as nvarchar(4)

	select @VINModelYear = 

	case 
		 when substring(@pVIN,10,1) = 'x' then '1999'
		 when substring(@pVIN,10,1) = 'y' then '2000'
		 when substring(@pVIN,10,1) = '1' then '2001'
		 when substring(@pVIN,10,1) = '2' then '2002'
		 when substring(@pVIN,10,1) = '3' then '2003'
		 when substring(@pVIN,10,1) = '4' then '2004'
		 when substring(@pVIN,10,1) = '5' then '2005'
		 when substring(@pVIN,10,1) = '6' then '2006'
		 when substring(@pVIN,10,1) = '7' then '2007'
		 when substring(@pVIN,10,1) = '8' then '2008'
		 when substring(@pVIN,10,1) = '9' then '2009'
		 when substring(@pVIN,10,1) = 'a' then '2010'
		 when substring(@pVIN,10,1) = 'b' then '2011'
		 when substring(@pVIN,10,1) = 'c' then '2012'
		 when substring(@pVIN,10,1) = 'd' then '2013'
		 when substring(@pVIN,10,1) = 'e' then '2014'
		 when substring(@pVIN,10,1) = 'f' then '2015'
		 when substring(@pVIN,10,1) = 'g' then '2016'
		 when substring(@pVIN,10,1) = 'h' then '2017'
		 when substring(@pVIN,10,1) = 'i' then '2018'
		 when substring(@pVIN,10,1) = 'j' then '2019'				 
	else '' 
	end	

return @VINModelYear

end
GO

GO

GO

GO
/****** Object:  UserDefinedFunction [dbo].[fnc_ETL_CaseProgramDataItem]    Script Date: 04/29/2014 02:13:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_ETL_CaseProgramDataItem]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_ETL_CaseProgramDataItem]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- DescriptiON:	Returns default product rates by locatiON
-- =============================================
CREATE FUNCTION [dbo].[fnc_ETL_CaseProgramDataItem] ()
RETURNS TABLE 
AS
RETURN 
(
	SELECT pdive.RecordID CaseID, pdi.ProgramID, pdi.Name ProgramDataItemName, pdive.Value
	FROM servicerequest sr
	JOIN [case] c ON c.id = sr.caseid
	JOIN ProgramDataItemValueEntity pdive ON pdive.entityid = 2 and pdive.recordid = c.id
	JOIN ProgramDataItem pdi ON pdi.id = pdive.ProgramDataItemID
	JOIN (
		SELECT pdive1.RecordID, pdive1.ProgramDataItemID, MAX(pdive1.id) ID
		FROM ProgramDataItemValueEntity pdive1 
		WHERE pdive1.entityid = 2
		GROUP BY pdive1.RecordID, pdive1.ProgramDataItemID
		) LastCapture ON LastCapture.RecordID = pdive.RecordID and LastCapture.ProgramDataItemID = pdive.ProgramDataItemID and LastCapture.ID = pdive.ID
)
GO

GO

GO

GO
/****** Object:  UserDefinedFunction [dbo].[fnc_GetProgramConfigurationForProgramAndParents]    Script Date: 04/29/2014 02:13:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetProgramConfigurationForProgramAndParents]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_GetProgramConfigurationForProgramAndParents]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnc_GetProgramConfigurationForProgramAndParents] (@ProgramID int)
RETURNS @ProgramConfiguration TABLE
   (
    ProgramConfigurationID     int,
    Name nvarchar(50)
   )
AS
BEGIN

DECLARE @pid int;

DECLARE program_cursor CURSOR FOR SELECT ProgramID FROM fnc_GetProgramsandParents(@ProgramID)
OPEN program_cursor

FETCH NEXT FROM program_cursor INTO @pid; 

WHILE @@FETCH_STATUS = 0

BEGIN
		INSERT @ProgramConfiguration
		SELECT ID, Name FROM ProgramConfiguration Where ProgramID = @pid
		AND Name not in (SELECT Distinct Name from @ProgramConfiguration)
		AND IsActive = 1
		ORDER BY Sequence 
	
END

 		

RETURN 

END
GO

GO

GO

GO
/****** Object:  UserDefinedFunction [dbo].[fnc_GetProgramDataItemsForProgramByScreen]    Script Date: 04/29/2014 02:13:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetProgramDataItemsForProgramByScreen]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_GetProgramDataItemsForProgramByScreen]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnc_GetProgramDataItemsForProgramByScreen] (@ProgramID int, @ScreenName varchar(50))
RETURNS @ProgramDataItemsForProgramByScreen TABLE
   (
    ProgramDataItemID     int,
    Name nvarchar(50)
   )
AS
BEGIN

DECLARE @pid int;

DECLARE program_cursor CURSOR FOR SELECT ProgramID FROM fnc_GetProgramsandParents(@ProgramID)
OPEN program_cursor

FETCH NEXT FROM program_cursor INTO @pid; 

WHILE @@FETCH_STATUS = 0

BEGIN
		INSERT @ProgramDataItemsForProgramByScreen 
		SELECT ID, Name FROM ProgramDataItem Where ProgramID = @pid
		AND Name not in (SELECT Distinct Name from @ProgramDataItemsForProgramByScreen)
		AND IsActive = 1
		ORDER BY Sequence 
	
END

 		

RETURN 

END
GO

GO

GO

GO
/****** Object:  UserDefinedFunction [dbo].[fnc_GetVendorActiveContractRateSchedule]    Script Date: 04/29/2014 02:13:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetVendorActiveContractRateSchedule]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_GetVendorActiveContractRateSchedule]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Select * From [dbo].[fnc_GetVendorContractStatus]() Where VendorID = 4360 
CREATE FUNCTION [dbo].[fnc_GetVendorActiveContractRateSchedule] ()
RETURNS @VendorContract TABLE
   (
    VendorID int,
    ContractID int,
    ContractRateScheduleID int
   )
AS
BEGIN
	-- BOTH Contract and related Contract Rate Schedule must be active and within the effective date range
	-- Need to guard against the possibility of multiple active contract/rate schedules for the same vendor
	;WITH wResults 
	AS 
	(
	SELECT 
		v.ID VendorID
		,c.ID ContractID
		,crs.ID ContractRateScheduleID
	FROM dbo.Vendor v
	JOIN dbo.[Contract] c On 
		c.VendorID = v.ID 
		AND c.IsActive = 1 --Not Deleted
		AND c.ContractStatusID = (SELECT ID FROM ContractStatus WHERE Name = 'Active')
		AND c.StartDate <= GETDATE() 
		AND (c.EndDate IS NULL OR c.EndDate >= GETDATE())
	JOIN dbo.[ContractRateSchedule] crs ON 
		crs.ContractID = c.ID AND 
		crs.ContractRateScheduleStatusID = (SELECT ID FROM ContractRateScheduleStatus WHERE Name = 'Active') AND
		crs.StartDate <= GETDATE() AND
		(crs.EndDate IS NULL OR crs.EndDate >= GETDATE())
	WHERE 
	v.IsActive = 1
	)
	
	INSERT INTO @VendorContract
	SELECT 
		r.VendorID
		,r.ContractID
		,r.ContractRateScheduleID
	FROM wResults r
	JOIN (
		SELECT VendorID, ContractID, MAX(ContractRateScheduleID) ContractRateScheduleID
		FROM wResults
		GROUP BY  VendorID, ContractID
		) r2 ON 
		r.VendorID = r2.VendorID 
		AND r.ContractID = r2.ContractID
		AND r.ContractRateScheduleID = r2.ContractRateScheduleID

	RETURN
END
GO

GO

GO

GO

/****** Object:  UserDefinedFunction [dbo].[fnc_GetVendorIndicators]    Script Date: 08/26/2013 10:47:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetVendorIndicators]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_GetVendorIndicators]
GO



/****** Object:  UserDefinedFunction [dbo].[fnc_GetVendorIndicators]    Script Date: 08/26/2013 10:47:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
-- SELECT * FROM [dbo].[fnc_GetVendorIndicators] ('Vendor')
-- SELECT * FROM [dbo].[fnc_GetVendorIndicators] ('VendorLocation')


CREATE FUNCTION [dbo].[fnc_GetVendorIndicators] (@entityName nvarchar(255))  
RETURNS @tblIndicators TABLE ( RecordID INT, Indicators NVARCHAR(MAX) )
AS  
BEGIN

	IF @entityName = 'Vendor'
	BEGIN

		INSERT INTO @tblIndicators (RecordID, Indicators) 
		SELECT	v.ID VendorID			  
				,CASE WHEN SUM(CASE WHEN vlp_P.ID IS NOT NULL  
									  THEN 1 ELSE 0 END) > 0 THEN ' (P)' ELSE '' END 
				+ CASE WHEN SUM(CASE WHEN vlp_DT.ID IS NOT NULL AND vl.DealerNumber IS NOT NULL AND vl.PartsAndAccessoryCode IS NOT NULL 
									  THEN 1 ELSE 0 END) > 0 THEN ' (DT)' ELSE '' END Indicators
		FROM	dbo.Vendor v WITH (NOLOCK)   
		JOIN	dbo.VendorLocation vl WITH (NOLOCK) ON vl.VendorID = v.ID AND vl.IsActive = 1 AND vl.VendorLocationStatusID = (SELECT ID FROM VendorLocationStatus WHERE Name = 'Active')
		LEFT OUTER JOIN VendorLocationProduct vlp_DT WITH (NOLOCK) ON vlp_DT.VendorLocationID = vl.ID AND vlp_DT.ProductID = (SELECT ID from Product where Name = 'Ford Direct Tow') AND vlp_DT.IsActive = 1
		LEFT OUTER JOIN VendorLocationProduct vlp_P WITH (NOLOCK) ON vlp_P.VendorLocationID = vl.ID AND vlp_P.ProductID = (SELECT ID from Product where Name = 'CoachNet Dealer Partner') AND vlp_P.IsActive = 1
		WHERE 
			  (vlp_DT.ID IS NOT NULL 
			  AND vl.DealerNumber IS NOT NULL 
			  AND vl.PartsAndAccessoryCode IS NOT NULL)
			  OR
			  (vlp_P.ID IS NOT NULL)
		GROUP BY v.VendorNumber, 
			  v.ID
			  ,v.Name
		
	END
	ELSE IF @entityName = 'VendorLocation'
	BEGIN

		INSERT INTO @tblIndicators (RecordID, Indicators) 
		SELECT	DISTINCT vl.ID VendorLocationID
				,CASE WHEN vlp_P.ID IS NOT NULL 
										THEN ' (P)' ELSE '' END 
				+ CASE WHEN vlp_DT.ID IS NOT NULL AND vl.DealerNumber IS NOT NULL AND vl.PartsAndAccessoryCode IS NOT NULL 
										THEN ' (DT)' ELSE '' END Indicators
		FROM	dbo.VendorLocation vl WITH (NOLOCK)
		LEFT OUTER JOIN VendorLocationProduct vlp_DT WITH (NOLOCK) on vlp_DT.VendorLocationID = vl.ID and vlp_DT.ProductID = (Select ID from Product where Name = 'Ford Direct Tow') and vlp_DT.IsActive = 1
		LEFT OUTER JOIN VendorLocationProduct vlp_P WITH (NOLOCK) on vlp_P.VendorLocationID = vl.ID and vlp_P.ProductID = (Select ID from Product where Name = 'CoachNet Dealer Partner') and vlp_P.IsActive = 1
		WHERE	vl.IsActive = 1 AND vl.VendorLocationStatusID = (SELECT ID FROM VendorLocationStatus WHERE Name = 'Active')
				AND
				(
				(vlp_DT.ID IS NOT NULL 
				AND vl.DealerNumber IS NOT NULL 
				AND vl.PartsAndAccessoryCode IS NOT NULL)
				OR
				(vlp_P.ID IS NOT NULL)	
				)
	END

	RETURN;

END

GO

GO

GO
/****** Object:  UserDefinedFunction [dbo].[fnc_ProperCase]    Script Date: 04/29/2014 02:13:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_ProperCase]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_ProperCase]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnc_ProperCase] (@InputString VARCHAR(4000) )
RETURNS VARCHAR(4000)
AS
BEGIN
	DECLARE @Index INT
	DECLARE @Char CHAR(1)
	DECLARE @OutputString VARCHAR(255)
	
	SET @OutputString = LOWER(@InputString)
	SET @Index = 2
	SET @OutputString =	STUFF(@OutputString, 1, 1,UPPER(SUBSTRING(@InputString,1,1)))
	
	WHILE @Index <= LEN(@InputString)
	BEGIN
		SET @Char = SUBSTRING(@InputString, @Index, 1)
		IF @Char IN (' ', ';', ':', '!', '?', ',', '.', '_', '-', '/', '&','''','(')
			IF @Index + 1 <= LEN(@InputString)
			BEGIN
				IF @Char != '''' OR UPPER(SUBSTRING(@InputString, @Index + 1, 1)) != 'S'
				SET @OutputString = STUFF(@OutputString, @Index + 1, 1,UPPER(SUBSTRING(@InputString, @Index + 1, 1)))
			END
		SET @Index = @Index + 1
	END
	RETURN ISNULL(@OutputString,'')
END
GO

GO

GO

GO
