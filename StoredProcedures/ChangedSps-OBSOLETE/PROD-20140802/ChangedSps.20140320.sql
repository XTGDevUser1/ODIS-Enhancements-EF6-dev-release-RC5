IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_DeleteDataItem]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_DeleteDataItem] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Program_Management_DeleteDataItem 19
 CREATE PROCEDURE [dbo].[dms_Program_Management_DeleteDataItem]( 
 @id INT 
 )
 AS
 BEGIN
	DELETE FROM ProgramDataItemValue WHERE ProgramDataItemID = @id
	DELETE FROM ProgramDataItemValueEntity WHERE ProgramDataItemID = @id
	DELETE FROM ProgramDataItem WHERE ID = @id
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
		ms.Note as MembershipNote
	FROM Member m 
	JOIN Membership ms ON ms.ID = m.MembershipID
	JOIN Program p ON p.id = m.ProgramID
	LEFT OUTER JOIN Program parent ON parent.ID = p.ParentProgramID
	JOIN Client c ON c.ID = p.ClientID
	WHERE m.ID = @MemberID

END

GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_GetdistinctVehicleTypes]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_GetdistinctVehicleTypes] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
  --EXEC dms_Program_Management_GetdistinctVehicleTypes 4,8
 CREATE PROCEDURE [dbo].[dms_Program_Management_GetdistinctVehicleTypes]( 
   @programId INT=NULL,
   @programVehicleTypeId INT=NULL
  
 ) 
 AS 
 BEGIN 
 
	SET FMTONLY OFF;
 	SET NOCOUNT ON
 	
 	DECLARE @tmpVehicleType TABLE
	(
	ID INT NULL,
	Descipriton nvarchar(255) null,
	Name nvarchar(50) null
	)
	
	IF @programVehicleTypeId IS NULL
	BEGIN
		INSERT INTO @tmpVehicleType
		SELECT ID,[Description],Name 
		FROM VehicleType
		WHERE ID not in(SELECT DISTINCT VehicleTypeID from ProgramVehicleType WHERE ProgramID=@programId)
	END
	ELSE BEGIN
		INSERT INTO @tmpVehicleType
		
		SELECT ID,[Description],Name 
		FROM VehicleType
		WHERE ID not in(SELECT DISTINCT VehicleTypeID from ProgramVehicleType WHERE ProgramID=@programId)
		
		UNION 
		
		SELECT ID,[Description],Name FROM VehicleType
		WHERE ID=(SELECT VehicleTypeID FROM ProgramVehicleType where ID=@programVehicleTypeId)
	END
	
	SELECT * FROM @tmpVehicleType
	
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
	--and		pst.Name NOT IN ('Client')	
	ORDER BY SortOrder, VehicleCategorySequence, ProductCategory , ServiceGroup
	
	UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
	LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
	WHERE VP.VendorID=@VendorID

	UPDATE @FinalResults SET IsAvailByVendorLocation = 1 FROM  @FinalResults T
	LEFT JOIN VendorLocationProduct VLP ON VLP.ProductID = T.ProductID
	WHERE VLP.VendorLocationID=@VendorLocationID

	SELECT *  FROM @FinalResults WHERE IsAvailByVendor=1
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
 -- EXEC [dms_ServiceFacilitySelection_get] 32.780122,-96.801412,'Ford F350,Ford F450,Ford F550,Ford F650,Ford F750',50
CREATE PROCEDURE [dbo].[dms_ServiceFacilitySelection_get]  
 @ServiceLocationLatitude decimal(10,7)  
 ,@ServiceLocationLongitude decimal(10,7)  
 ,@ProductList nvarchar(4000) --comma delimited list of product names  
 ,@SearchRadiusMiles int  
AS  
BEGIN  

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
 DECLARE   
@VendorEntityID int  
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

   
 ; WITH wVendors  
 AS  
 (   
 Select   
  v.ID VendorID  
  --,v.Name + CASE WHEN v.DealerNumber IS NOT NULL THEN ' *** DLR#: ' + v.DealerNumber ELSE N'' END  VendorName  
  ,v.Name /*KB: There is no DealerNumber in Vendor table now. + CASE WHEN v.DealerNumber IS NOT NULL THEN ' *** Ford Direct Tow' ELSE N'' END */ VendorName  
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
  ,Cn.ISOCode as Country,  
  vl.GeographyLocation     
 From dbo.VendorLocation vl   
 Join dbo.Vendor v   
  On vl.VendorID = v.ID  
 Join dbo.[AddressEntity] addr On addr.EntityID = @VendorLocationEntityID and addr.RecordID = vl.ID and addr.AddressTypeID = @BusinessAddressTypeID  
 Join dbo.Country Cn On addr.CountryID = Cn.ID    
 Join dbo.StateProvince SP on addr.StateProvinceID = SP.ID    
 Left Outer Join dbo.[PhoneEntity] ph   
  On ph.EntityID = @VendorLocationEntityID and ph.RecordID = vl.ID and ph.PhoneTypeID = @DispatchPhoneTypeID 
  
 
WHERE 
  v.IsActive = 1 AND v.VendorStatusID = @ActiveVendorStatusID  
  and vl.IsActive = 1 AND vl.VendorLocationStatusID = @ActiveVendorLocationStatusID  
  and vl.GeographyLocation.STDistance(@ServiceLocation) <= @SearchRadiusMiles * 1609.344  
  and Exists (  
   Select *  
   From VendorLocation vl1 
   Join VendorLocationProduct vlp on vlp.VendorLocationID = vl1.ID and vlp.IsActive = 1
   Join VendorProduct vp on vp.VendorID = vl1.VendorID and vp.ProductID = vlp.ProductID and vp.IsActive = 1 
   Join @tblProductList pl On vlp.ProductID = pl.ProductID  
   Where vp.IsActive = 1 
	and vlp.IsActive = 1
	and vlp.VendorLocationID = vl.ID
   )  
 --Order by ROUND(vl.GeographyLocation.STDistance(@ServiceLocation)/1609.344,1)  
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
 )  
   
 SELECT TOP 50
  W.*,  
  VP.AllServices,  
  CMT.Comments,
  Faxph.PhoneNumber AS FaxPhoneNumber,
  Officeph.PhoneNumber AS OfficePhoneNumber,
  Cellph.PhoneNumber AS CellPhoneNumber   
 FROM wVendors W  
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
-- Get last ContactLog result for the current sevice request for the ISP  
LEFT OUTER JOIN (    
 SELECT RecordID,  
  [dbo].[fnConcatenate](REPLACE([Description],',','~') +  
          + ' <LF> ' + ISNULL(CreateBy,'') + ' | ' + COALESCE( CONVERT( VARCHAR(10), GETDATE(), 101) +  
   STUFF( RIGHT( CONVERT( VARCHAR(26), GETDATE(), 109 ), 15 ), 10, 4, ' ' ),'')) AS [Comments]            
   FROM Comment         
   WHERE EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')  
   AND  [Description] IS NOT NULL  
   GROUP BY RecordID   
) CMT ON CMT.RecordID = W.VendorLocationID  

-- Get all other phone numbers.
LEFT OUTER JOIN  dbo.[PhoneEntity] Faxph   
ON Faxph.EntityID = @VendorLocationEntityID AND Faxph.RecordID = W.VendorLocationID AND Faxph.PhoneTypeID = @FaxPhoneTypeID  
-- CR : 1226 - Office phone number of the vendor and not vendor location.
LEFT OUTER JOIN  dbo.[PhoneEntity] Officeph   
ON Officeph.EntityID = @VendorEntityID AND Officeph.RecordID = W.VendorID AND Officeph.PhoneTypeID = @OfficePhoneTypeID

LEFT OUTER JOIN  dbo.[PhoneEntity] Cellph   -- CR: 1226
ON Cellph.EntityID = @VendorLocationEntityID AND Cellph.RecordID = W.VendorLocationID AND Cellph.PhoneTypeID = @CellPhoneTypeID  

ORDER BY ROUND(W.GeographyLocation.STDistance(@ServiceLocation)/1609.344,1)  

END

GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Notification_History_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Notification_History_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Notification_History_Get] 'demouser'
CREATE PROCEDURE [dbo].[dms_Notification_History_Get](
@userName NVARCHAR(100)
)
AS
BEGIN

	DECLARE @notificationHistoryDisplayHours INT = 48 -- Default value is set to 48.

	SELECT @notificationHistoryDisplayHours = CONVERT(INT,Value) FROM ApplicationConfiguration WHERE Name = 'NotificationHistoryDisplayHours'
	

	SELECT	CL.*
	FROM	CommunicationLog CL WITH (NOLOCK)
	JOIN	ContactMethod CM WITH (NOLOCK) ON CL.ContactMethodID = CM.ID
	WHERE	CL.NotificationRecipient = @userName
	AND		CM.Name = 'DesktopNotification'
	AND		DATEDIFF(HH,CL.CreateDate,GETDATE()) <= @notificationHistoryDisplayHours
	AND		CL.Status = 'SUCCESS'
	ORDER BY CL.CreateDate DESC

END
GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_billing_invoices_tag]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_billing_invoices_tag] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_billing_invoices_tag] @invoicesOrClaimsXML = '<Invoices><ID>41</ID></Invoices>',@batchID = 999, @currentUser='kbanda'
 CREATE PROCEDURE [dbo].[dms_billing_invoices_tag](
	@invoicesXML XML,
	@billedBatchID BIGINT,
	@unBilledBatchID BIGINT,
	@currentUser NVARCHAR(50),
	@eventSource NVARCHAR(MAX),
	@eventName NVARCHAR(100) = 'PostInvoice',
	@eventDetails NVARCHAR(MAX),
	@entityName NVARCHAR(50) = 'BillingInvoice',
	@sessionID NVARCHAR(MAX) = NULL	
 )
 AS
 BEGIN
 
	DECLARE @now DATETIME = GETDATE()
	
	DECLARE @tblBillingInvoices TABLE
	(	
		ID INT IDENTITY(1,1),
		RecordID INT
	)
	
	INSERT INTO @tblBillingInvoices
	SELECT BI.ID
	FROM	BillingInvoice BI
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @invoicesXML.nodes('/Invoices/ID') T(c)
			) T ON BI.ID = T.ID
			
	DECLARE	@BillingInvoiceDetailStatus_POSTED as int,
			@BillingInvoiceDetailStatus_EXCLUDED as INT,
			@BillingInvoiceLineStatus_POSTED as int,
			@BillingInvoiceStatus_POSTED as int,
			@BillingInvoiceDisposition_LOCKED as int,
			@BillingInvoiceStatus_DELETED as int,
			
			@serviceRequestEntityID INT,
			@purchaseOrderEntityID INT,
			@claimEntityID INT,
			@vendorInvoiceEntityID INT,
			@billingInvoiceEntityID INT,
			@postInvoiceEventID INT	
	
	SELECT @BillingInvoiceDetailStatus_POSTED = (SELECT ID from BillingInvoiceDetailStatus where Name = 'POSTED')
	SELECT @BillingInvoiceLineStatus_POSTED = (SELECT ID from BillingInvoiceLineStatus where Name = 'POSTED')
	SELECT @BillingInvoiceStatus_POSTED = (SELECT ID from BillingInvoiceStatus where Name = 'POSTED')
	SELECT @BillingInvoiceDisposition_LOCKED = (SELECT ID from BillingInvoiceDetailDisposition where Name = 'LOCKED')
	SELECT @BillingInvoiceStatus_DELETED = (SELECT ID from BillingInvoiceStatus where Name = 'DELETED')

	SELECT @BillingInvoiceDetailStatus_EXCLUDED = (SELECT ID from BillingInvoiceDetailStatus where Name = 'EXCLUDED')
 
 
	SELECT @serviceRequestEntityID = ID FROM Entity WHERE Name = 'ServiceRequest'
	SELECT @purchaseOrderEntityID = ID FROM Entity WHERE Name = 'PurchaseOrder'
	SELECT @claimEntityID = ID FROM Entity WHERE Name = 'Claim'
	SELECT @vendorInvoiceEntityID = ID FROM Entity WHERE Name = 'VendorInvoice'
	SELECT @billingInvoiceEntityID = ID FROM Entity WHERE Name = 'BillingInvoice'
	
	SELECT @postInvoiceEventID = ID FROM [Event] WHERE Name = 'PostInvoice'
	
	DECLARE @index INT = 1, @maxRows INT = 0, @billingInvoiceID INT = 0
	
	SELECT @maxRows = MAX(ID) FROM @tblBillingInvoices
	
	--DEBUG: SELECT @index,@maxRows
	
	WHILE (@index <= @maxRows AND @maxRows > 0)
	BEGIN
		
		
		
		SELECT @billingInvoiceID = RecordID FROM @tblBillingInvoices WHERE ID = @index
		
		--DEBUG: SELECT 'Updating statuses' As StatusMessage,@billingInvoiceID AS InvoiceID
		
		-- Update Billing Invoice.
		UPDATE	BillingInvoice 
		SET		InvoiceStatusID = @BillingInvoiceStatus_POSTED,
				AccountingInvoiceBatchID = @billedBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		WHERE	ID = @billingInvoiceID		
		
		-- Update Billing InvoiceLines
		UPDATE	BillingInvoiceLine
		SET		InvoiceLineStatusID = @BillingInvoiceLineStatus_POSTED,
				ModifyBy = @currentUser,
				ModifyDate = @now
		WHERE	BillingInvoiceID = @billingInvoiceID
		
		-- Update BillingInvoiceDetail and related entities.
		UPDATE	BillingInvoiceDetail
		SET		AccountingInvoiceBatchID = CASE WHEN ISNULL(BID.IsExcluded,0) = 1
												THEN @unBilledBatchID
												ELSE @billedBatchID
											END,
				InvoiceDetailDispositionID = @BillingInvoiceDisposition_LOCKED,
				--TFS: 203 --InvoiceDetailStatusID = @BillingInvoiceDetailStatus_POSTED,
				InvoiceDetailStatusID = CASE WHEN ISNULL(BID.IsExcluded, 0) = 1
                                                            THEN @BillingInvoiceDetailStatus_EXCLUDED
                                                            ELSE @BillingInvoiceDetailStatus_POSTED
                                                END, 
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	BillingInvoiceDetail BID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID AND BID.InvoiceDetailStatusID <> @BillingInvoiceStatus_DELETED
		
		
		-- SRs
		UPDATE	ServiceRequest
		SET		AccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	ServiceRequest SR
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @serviceRequestEntityID AND BID.EntityKey = SR.ID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
				
		-- POs
		UPDATE	PurchaseOrder
		SET		AccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	PurchaseOrder PO
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @purchaseOrderEntityID AND BID.EntityKey = PO.ID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
		
		-- Claims PassThru
		UPDATE	Claim
		SET		PassthruAccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	Claim C
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @claimEntityID AND BID.EntityKey = C.ID
		JOIN	BillingDefinitionInvoiceLine BDIL ON BID.BillingDefinitionInvoiceLineID = BDIL.ID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
		AND		BDIL.Rate IS NULL
		
		-- Claims Fee
		UPDATE	Claim
		SET		FeeAccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	Claim C
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @claimEntityID AND BID.EntityKey = C.ID
		JOIN	BillingDefinitionInvoiceLine BDIL ON BID.BillingDefinitionInvoiceLineID = BDIL.ID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
		AND		BDIL.Rate IS NOT NULL
		
		-- VendorInvoice
		UPDATE	VendorInvoice
		SET		AccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	VendorInvoice VI
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @vendorInvoiceEntityID AND BID.EntityKey = VI.ID		
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
		
		
		INSERT INTO EventLog
		SELECT	@postInvoiceEventID,
				@sessionID,
				@eventSource,
				@eventDetails,
				NULL,
				NULL,
				GETDATE(),
				@currentUser
				
		INSERT INTO EventLogLink
		SELECT	SCOPE_IDENTITY(),
				@billingInvoiceEntityID,
				@billingInvoiceID			
	
		SET @index = @index + 1
		
		
	END
 
 
 END

GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveDataItemInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveDataItemInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveDataItemInformation]( 
   @id INT = NULL
 , @programID INT = NULL
 , @controlTypeID INT = NULL
 , @dataTypeID INT = NULL
 , @name NVARCHAR(100) = NULL
 , @screenName NVARCHAR(100) = NULL
 , @label NVARCHAR(100) = NULL
 , @maxLength INT = NULL
 , @sequence INT = NULL
 , @isRequired BIT = NULL
 , @isActive BIT = NULL
 , @currentUser NVARCHAR(100) = NULL 
 )
 AS
 BEGIN
 IF @id > 0 
	 BEGIN
		UPDATE ProgramDataItem 
		SET ControlTypeID = @controlTypeID,
			DataTypeID = @dataTypeID,
			Name = @name,
			ScreenName = @screenName,
			Label = @label,
			Sequence = @sequence,
			MaxLength = @maxLength,
			IsRequired = @isRequired,
			IsActive = @isActive,
			ModifyBy = @currentUser,
			ModifyDate = GETDATE()
		WHERE ID = @id
	 END
ELSE
	BEGIN
		INSERT INTO ProgramDataItem (
			ProgramID,
			ControlTypeID,
			DataTypeID,
			Name,
			ScreenName,
			Label,
			Sequence,
			MaxLength,
			IsRequired,
			IsActive,
			CreateBy,
			CreateDate		
		)
		VALUES(
			@programID,
			@controlTypeID,
			@dataTypeID,
			@name,
			@screenName,
			@label,
			@sequence,
			@maxLength,
			@isRequired,
			@isActive,
			@currentUser,
			GETDATE()
		)
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
 WHERE id = object_id(N'[dbo].[dms_Program_Management_ProgramDataItemList]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_ProgramDataItemList] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_Program_Management_ProgramDataItemList] @programID=45
 CREATE PROCEDURE [dbo].[dms_Program_Management_ProgramDataItemList]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID INT = NULL 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
ProgramDataItemIDOperator="-1" 
ScreenNameOperator="-1" 
NameOperator="-1" 
LabelOperator="-1" 
IsActiveOperator="-1" 
ControlTypeOperator="-1" 
DataTypeOperator="-1" 
SequenceOperator="-1" 
IsRequiredOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
ProgramDataItemIDOperator INT NOT NULL,
ProgramDataItemIDValue int NULL,
ScreenNameOperator INT NOT NULL,
ScreenNameValue nvarchar(100) NULL,
NameOperator INT NOT NULL,
NameValue nvarchar(100) NULL,
LabelOperator INT NOT NULL,
LabelValue nvarchar(100) NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue bit NULL,
ControlTypeOperator INT NOT NULL,
ControlTypeValue nvarchar(100) NULL,
DataTypeOperator INT NOT NULL,
DataTypeValue nvarchar(100) NULL,
SequenceOperator INT NOT NULL,
SequenceValue int NULL,
IsRequiredOperator INT NOT NULL,
IsRequiredValue bit NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramDataItemID int  NULL ,
	ScreenName nvarchar(100)  NULL ,
	Name nvarchar(100)  NULL ,
	Label nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	ControlType nvarchar(100)  NULL ,
	DataType nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsRequired bit  NULL 
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramDataItemID int  NULL ,
	ScreenName nvarchar(100)  NULL ,
	Name nvarchar(100)  NULL ,
	Label nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	ControlType nvarchar(100)  NULL ,
	DataType nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsRequired bit  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@ProgramDataItemIDOperator','INT'),-1),
	T.c.value('@ProgramDataItemIDValue','int') ,
	ISNULL(T.c.value('@ScreenNameOperator','INT'),-1),
	T.c.value('@ScreenNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@NameOperator','INT'),-1),
	T.c.value('@NameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@LabelOperator','INT'),-1),
	T.c.value('@LabelValue','nvarchar(100)') ,
	ISNULL(T.c.value('@IsActiveOperator','INT'),-1),
	T.c.value('@IsActiveValue','bit') ,
	ISNULL(T.c.value('@ControlTypeOperator','INT'),-1),
	T.c.value('@ControlTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DataTypeOperator','INT'),-1),
	T.c.value('@DataTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@SequenceOperator','INT'),-1),
	T.c.value('@SequenceValue','int') ,
	ISNULL(T.c.value('@IsRequiredOperator','INT'),-1),
	T.c.value('@IsRequiredValue','bit') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT --ROW_NUMBER() OVER ( PARTITION BY PDI.Name ORDER BY PP.Sequence) AS RowNum,
		PDI.ID ProgramDataItemID,
		PDI.ScreenName,
		PDI.Name,
		PDI.Label,
		PDI.IsActive,--CASE ISNULL(PC.IsActive,0) WHEN 0 THEN 'No' ELSE 'Yes' END IsActiveText,
		CT.[Description] ControlType,
		DT.[Description] DataType,
		PDI.Sequence,
		PDI.IsRequired
FROM fnc_GetProgramsandParents(@ProgramID) PP
JOIN ProgramDataItem PDI ON PP.ProgramID = PDI.ProgramID AND PDI.IsActive = 1	
LEFT JOIN ControlType CT ON CT.ID = PDI.ControlTypeID
LEFT JOIN DataType DT ON DT.ID = PDI.DataTypeID
WHERE PDI.ProgramID=@programID		
INSERT INTO #FinalResults
SELECT 
	T.ProgramDataItemID,
	T.ScreenName,
	T.Name,
	T.Label,
	T.IsActive,
	T.ControlType,
	T.DataType,
	T.Sequence,
	T.IsRequired
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.ProgramDataItemIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 0 AND T.ProgramDataItemID IS NULL ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 1 AND T.ProgramDataItemID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 2 AND T.ProgramDataItemID = TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 3 AND T.ProgramDataItemID <> TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 7 AND T.ProgramDataItemID > TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 8 AND T.ProgramDataItemID >= TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 9 AND T.ProgramDataItemID < TMP.ProgramDataItemIDValue ) 
 OR 
	 ( TMP.ProgramDataItemIDOperator = 10 AND T.ProgramDataItemID <= TMP.ProgramDataItemIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScreenNameOperator = -1 ) 
 OR 
	 ( TMP.ScreenNameOperator = 0 AND T.ScreenName IS NULL ) 
 OR 
	 ( TMP.ScreenNameOperator = 1 AND T.ScreenName IS NOT NULL ) 
 OR 
	 ( TMP.ScreenNameOperator = 2 AND T.ScreenName = TMP.ScreenNameValue ) 
 OR 
	 ( TMP.ScreenNameOperator = 3 AND T.ScreenName <> TMP.ScreenNameValue ) 
 OR 
	 ( TMP.ScreenNameOperator = 4 AND T.ScreenName LIKE TMP.ScreenNameValue + '%') 
 OR 
	 ( TMP.ScreenNameOperator = 5 AND T.ScreenName LIKE '%' + TMP.ScreenNameValue ) 
 OR 
	 ( TMP.ScreenNameOperator = 6 AND T.ScreenName LIKE '%' + TMP.ScreenNameValue + '%' ) 
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
	 ( TMP.LabelOperator = -1 ) 
 OR 
	 ( TMP.LabelOperator = 0 AND T.Label IS NULL ) 
 OR 
	 ( TMP.LabelOperator = 1 AND T.Label IS NOT NULL ) 
 OR 
	 ( TMP.LabelOperator = 2 AND T.Label = TMP.LabelValue ) 
 OR 
	 ( TMP.LabelOperator = 3 AND T.Label <> TMP.LabelValue ) 
 OR 
	 ( TMP.LabelOperator = 4 AND T.Label LIKE TMP.LabelValue + '%') 
 OR 
	 ( TMP.LabelOperator = 5 AND T.Label LIKE '%' + TMP.LabelValue ) 
 OR 
	 ( TMP.LabelOperator = 6 AND T.Label LIKE '%' + TMP.LabelValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.IsActiveOperator = -1 ) 
 OR 
	 ( TMP.IsActiveOperator = 0 AND T.IsActive IS NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 1 AND T.IsActive IS NOT NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 2 AND T.IsActive = TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 3 AND T.IsActive <> TMP.IsActiveValue ) 
 ) 

 AND 

 ( 
	 ( TMP.ControlTypeOperator = -1 ) 
 OR 
	 ( TMP.ControlTypeOperator = 0 AND T.ControlType IS NULL ) 
 OR 
	 ( TMP.ControlTypeOperator = 1 AND T.ControlType IS NOT NULL ) 
 OR 
	 ( TMP.ControlTypeOperator = 2 AND T.ControlType = TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 3 AND T.ControlType <> TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 4 AND T.ControlType LIKE TMP.ControlTypeValue + '%') 
 OR 
	 ( TMP.ControlTypeOperator = 5 AND T.ControlType LIKE '%' + TMP.ControlTypeValue ) 
 OR 
	 ( TMP.ControlTypeOperator = 6 AND T.ControlType LIKE '%' + TMP.ControlTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DataTypeOperator = -1 ) 
 OR 
	 ( TMP.DataTypeOperator = 0 AND T.DataType IS NULL ) 
 OR 
	 ( TMP.DataTypeOperator = 1 AND T.DataType IS NOT NULL ) 
 OR 
	 ( TMP.DataTypeOperator = 2 AND T.DataType = TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 3 AND T.DataType <> TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 4 AND T.DataType LIKE TMP.DataTypeValue + '%') 
 OR 
	 ( TMP.DataTypeOperator = 5 AND T.DataType LIKE '%' + TMP.DataTypeValue ) 
 OR 
	 ( TMP.DataTypeOperator = 6 AND T.DataType LIKE '%' + TMP.DataTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.SequenceOperator = -1 ) 
 OR 
	 ( TMP.SequenceOperator = 0 AND T.Sequence IS NULL ) 
 OR 
	 ( TMP.SequenceOperator = 1 AND T.Sequence IS NOT NULL ) 
 OR 
	 ( TMP.SequenceOperator = 2 AND T.Sequence = TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 3 AND T.Sequence <> TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 7 AND T.Sequence > TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 8 AND T.Sequence >= TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 9 AND T.Sequence < TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 10 AND T.Sequence <= TMP.SequenceValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsRequiredOperator = -1 ) 
 OR 
	 ( TMP.IsRequiredOperator = 0 AND T.IsRequired IS NULL ) 
 OR 
	 ( TMP.IsRequiredOperator = 1 AND T.IsRequired IS NOT NULL ) 
 OR 
	 ( TMP.IsRequiredOperator = 2 AND T.IsRequired = TMP.IsRequiredValue ) 
 OR 
	 ( TMP.IsRequiredOperator = 3 AND T.IsRequired <> TMP.IsRequiredValue ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ProgramDataItemID' AND @sortOrder = 'ASC'
	 THEN T.ProgramDataItemID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramDataItemID' AND @sortOrder = 'DESC'
	 THEN T.ProgramDataItemID END DESC ,

	 CASE WHEN @sortColumn = 'ScreenName' AND @sortOrder = 'ASC'
	 THEN T.ScreenName END ASC, 
	 CASE WHEN @sortColumn = 'ScreenName' AND @sortOrder = 'DESC'
	 THEN T.ScreenName END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Label' AND @sortOrder = 'ASC'
	 THEN T.Label END ASC, 
	 CASE WHEN @sortColumn = 'Label' AND @sortOrder = 'DESC'
	 THEN T.Label END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC ,

	 CASE WHEN @sortColumn = 'ControlType' AND @sortOrder = 'ASC'
	 THEN T.ControlType END ASC, 
	 CASE WHEN @sortColumn = 'ControlType' AND @sortOrder = 'DESC'
	 THEN T.ControlType END DESC ,

	 CASE WHEN @sortColumn = 'DataType' AND @sortOrder = 'ASC'
	 THEN T.DataType END ASC, 
	 CASE WHEN @sortColumn = 'DataType' AND @sortOrder = 'DESC'
	 THEN T.DataType END DESC ,

	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'
	 THEN T.Sequence END ASC, 
	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'
	 THEN T.Sequence END DESC ,

	 CASE WHEN @sortColumn = 'IsRequired' AND @sortOrder = 'ASC'
	 THEN T.IsRequired END ASC, 
	 CASE WHEN @sortColumn = 'IsRequired' AND @sortOrder = 'DESC'
	 THEN T.IsRequired END DESC 


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
 WHERE id = object_id(N'[dbo].[dms_CurrentUser_For_Event_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_CurrentUser_For_Event_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_CurrentUser_For_Event_Get] 'kbanda'
CREATE PROCEDURE [dbo].[dms_CurrentUser_For_Event_Get](
	@eventLogID INT,
	@eventSubscriptionID INT
)
AS
BEGIN
 
	/*
		Assumption : This stored procedure would be executed for DesktopNotifications.
		Logic : 
		If the event is SendPOFaxFailure - Determine the current user as follows:
			1.	Parse EL.Data and pull out <ServiceRequest><SR.ID>  </ServiceRequest>
			2.	Join to Case from that SR.ID and get Case.AssignedToUserID
			3.	Insert one CommunicatinQueue record
			4.	If this value is blank try next one
			iv.	If no current user assigned
			1.	Parse EL.Data and pull out <CreateByUser><username></CreateByUser>
			2.	Check to see if that <username> is online
			3.	If online then Insert one CommunicatinQueue record for that user
			v.	If still no user found or online, then check the Service Request and if the NextAction fields are blank.  If blank then:
			1.	Update the associated ServiceRequest next action fields.  These will be displayed on the Queue prompting someone to take action and re-send the PO
			a.	Set ServiceRequest.NextActionID = Re-send PO
			b.	Set ServiceRequest.NextActionAssignedToUserID = ‘Agent User’

		If the event is ManualNotification, determine the curren user(s) as follows: 
			1. Get the associated EventLogLinkRecords.
			2. For each of the link records:
				2.1 If the related entity on the link record is a user and the user is online, add the user details to the list.
				
		If the event is not SendPOFaxFailure - CurrentUser = ServiceRequest.Case.AssignedToUserID.
	*/

	DECLARE @eventName NVARCHAR(255),
			@eventData XML,
			@PONumber NVARCHAR(100),
			@ServiceRequest INT,
			@FaxFailureReason NVARCHAR(MAX),
			@CreateByUser NVARCHAR(50),

			@assignedToUserIDOnCase INT,
			@nextActionIDOnSR INT,
			@nextActionAssignedToOnSR INT,
			@resendPONextActionID INT,
			@agentUserID INT

	DECLARE @tmpCurrentUser TABLE
			(
				UserId UNIQUEIDENTIFIER NULL,
				UserName NVARCHAR(100) NULL
			)
	
	SELECT  @resendPONextActionID = ID FROM NextAction WITH (NOLOCK) WHERE Name = 'ResendPO'
	
	SELECT	@agentUserID = U.ID
	FROM	[User] U WITH (NOLOCK) 
	JOIN	aspnet_Users AU WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
	JOIN	aspnet_Applications A WITH (NOLOCK) ON A.ApplicationId = AU.ApplicationId
	WHERE	AU.UserName = 'Agent'
	AND		A.ApplicationName = 'DMS'

	SELECT	@eventData = EL.Data
	FROM	EventLog EL WITH (NOLOCK)
	JOIN	Event E WITH (NOLOCK) ON EL.EventID = E.ID
	WHERE	EL.ID = @eventLogID

	SELECT	@eventName = E.Name
	FROM	EventSubscription ES WITH (NOLOCK) 
	JOIN	Event E WITH (NOLOCK) ON ES.EventID = E.ID
	WHERE	ES.ID = @eventSubscriptionID
	

	SELECT	@PONumber = (SELECT  T.c.value('.','NVARCHAR(100)') FROM @eventData.nodes('/MessageData/PONumber') T(c)),
			@ServiceRequest = (SELECT  T.c.value('.','INT') FROM @eventData.nodes('/MessageData/ServiceRequest') T(c)),
			@FaxFailureReason = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventData.nodes('/MessageData/FaxFailureReason') T(c)),
			@CreateByUser = (SELECT  T.c.value('.','NVARCHAR(50)') FROM @eventData.nodes('/MessageData/CreateByUser') T(c))
		
	SELECT	@assignedToUserIDOnCase = C.AssignedToUserID
		FROM	[Case] C WITH (NOLOCK)
		JOIN	[ServiceRequest] SR WITH (NOLOCK) ON SR.CaseID = C.ID
		WHERE	SR.ID = @ServiceRequest

	IF (@eventName = 'SendPOFaxFailed')
	BEGIN	
				
		IF (@assignedToUserIDOnCase IS NOT NULL)
		BEGIN
			-- Return the user details.
			INSERT INTO @tmpCurrentUser ( UserId, UserName)
			SELECT	AU.UserId,
					AU.UserName
			FROM	aspnet_Users AU WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
			WHERE	U.ID = @assignedToUserIDOnCase

		END
		ELSE 
		BEGIN
			
			IF ( (SELECT [dbo].[fnIsUserConnected](@CreateByUser) ) = 1)
			BEGIN
				
				INSERT INTO @tmpCurrentUser
				SELECT	AU.UserId,
						AU.UserName
				FROM	aspnet_Users AU WITH (NOLOCK) 
				JOIN	aspnet_Applications A WITH (NOLOCK) ON AU.ApplicationId = A.ApplicationId			
				WHERE	AU.UserName = @CreateByUser
				AND		A.ApplicationName = 'DMS'
				
			END
			ELSE
			BEGIN

				SELECT	@nextActionIDOnSR = SR.NextActionID,
						@nextActionAssignedToOnSR = SR.NextActionAssignedToUserID
				FROM	ServiceRequest SR WITH (NOLOCK) 
				WHERE ID = @ServiceRequest 

				IF @nextActionAssignedToOnSR IS NULL AND @nextActionIDOnSR IS NULL
				BEGIN
					
					UPDATE	ServiceRequest
					SET		NextActionID = @resendPONextActionID,
							NextActionAssignedToUserID = @agentUserID
					WHERE	ID = @ServiceRequest

				END
			END				
		END	
	END
	
	ELSE IF (@eventName = 'ManualNotification' OR @eventName = 'LockedRequestComment')
	BEGIN
		
		DECLARE @userEntityID INT

		SET @userEntityID = (SELECT ID FROM Entity WHERE Name = 'User')
		;WITH wUsersFromEventLogLinks
		AS
		(
			SELECT	AU.UserId,
					AU.UserName,
					[dbo].[fnIsUserConnected](AU.UserName) IsConnected				
			FROM	EventLogLink ELL WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON ELL.RecordID = U.ID AND ELL.EntityID = @userEntityID
			JOIN	aspnet_Users AU WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
			WHERE	ELL.EventLogID = @eventLogID
		)

		INSERT INTO @tmpCurrentUser (UserId, UserName)
		SELECT	W.UserId, W.UserName
		FROM	wUsersFromEventLogLinks W
		WHERE	ISNULL(W.IsConnected,0) = 1


	END	
	ELSE
	BEGIN
		
		IF (@assignedToUserIDOnCase IS NOT NULL)
		BEGIN

			INSERT INTO @tmpCurrentUser ( UserId, UserName)
			SELECT	AU.UserId,
					AU.Username
			FROM	aspnet_Users AU WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON AU.UserId = U.aspnet_UserID
			JOIN	[aspnet_Applications] A WITH (NOLOCK) ON A.ApplicationId = AU.ApplicationId
			WHERE	A.ApplicationName = 'DMS'
			AND		U.ID = @assignedToUserIDOnCase

		END
			
	END	


	SELECT UserId, Username from @tmpCurrentUser

END

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
CREATE PROCEDURE dms_Vendor_Services_List_Get @VendorID INT
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
