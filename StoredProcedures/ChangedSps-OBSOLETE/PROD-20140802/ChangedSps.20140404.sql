IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Call_Summary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Call_Summary]
GO

--EXEC dms_Call_Summary @serviceRequestID = 1443  
CREATE PROC dms_Call_Summary(@serviceRequestID INT = NULL)  
AS  
BEGIN 
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
    -- Ignore time while comparing dates here
    -- KB: Considering Effective and Expiration Dates to calculate member status
	, CASE 
		WHEN	ISNULL(m.EffectiveDate,@minDate) <= @now AND ISNULL(m.ExpirationDate,@minDate) >= @now
		THEN	'Active'
		ELSE	'Inactive'
		END	AS Member_Status       
    , ISNULL((SELECT NAME FROM PhoneType WHERE ID = c.ContactPhoneTypeID),' ') as Member_CallbackPhoneTypeID    
    , ISNULL(c.ContactPhoneNumber,'') as Member_CallbackPhoneNumber    
    , ISNULL((SELECT NAME FROM PhoneType WHERE ID = c.ContactAltPhoneTypeID),' ') as Member_AltCallbackPhoneTypeID   
    , ISNULL(c.ContactAltPhoneNumber,'') as Member_AltCallbackPhoneNumber    
    , CONVERT(nvarchar(10),m.MemberSinceDate,101) as Member_MemberSinceDate
    , CONVERT(nvarchar(10),m.EffectiveDate,101) AS Member_EffectiveDate
    , CONVERT(nvarchar(10),m.ExpirationDate,101) AS Member_ExpirationDate
    , ISNULL(ae.Line1,'') AS Member_AddressLine1
    , ISNULL(ae.Line2,'') AS Member_AddressLine2
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
	,CASE	WHEN C.IsVehicleEligible IS NULL THEN '' 
			WHEN C.IsVehicleEligible = 1 THEN 'In Warranty'
			ELSE 'Out of Warranty' END AS Vehicle_IsEligible
-- SERVICE SECTION   
--	, 2 AS Service_DefaultNumberOfRows  
	
	, pc.Name as Service_ProductCategoryTow
	, CASE WHEN sr.IsPrimaryOverallCovered  = 1 THEN 'Covered' ELSE 'Not Covered' END AS Service_IsPrimaryOverallCovered
	
	, CASE WHEN sr.IsPossibleTow = 1 THEN 'Possible Tow' ELSE '' END AS Service_IsPossibleTow
	, CASE WHEN sr.IsSecondaryOverallCovered  = 1 THEN 'Covered' ELSE 'Not Covered' END AS Service_IsSecondaryOverallCovered
	
	, '$' + CONVERT(NVARCHAR(50),ISNULL(sr.CoverageLimit,0)) as Service_CoverageLimit  

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
	, CASE
		WHEN ContractedVendors.ContractID IS NOT NULL 
			AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'
		ELSE 'Not Contracted' 
		END AS ISP_Contracted
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
	LEFT JOIN	[Contract] vc on vc.VendorID = v.ID and vc.IsActive = 1 and vc.ContractStatusID = (Select ID From ContractStatus Where Name = 'Active')
	LEFT OUTER JOIN (
				SELECT DISTINCT vr.VendorID, vr.ProductID
				FROM dbo.fnGetCurrentProductRatesByVendorLocation() vr 
				) DefaultVendorRates ON v.ID = DefaultVendorRates.VendorID And @ProductID = DefaultVendorRates.ProductID
	LEFT OUTER JOIN (
				SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID
				FROM dbo.fnGetContractedVendors() cv
				) ContractedVendors ON v.ID = ContractedVendors.VendorID
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
 UPDATE @Hold SET GroupName = 'Member', DefaultRows = 5 WHERE CHARINDEX('Member_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Vehicle', DefaultRows = 3 WHERE CHARINDEX('Vehicle_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Service' ,DefaultRows = 5 WHERE CHARINDEX('Service_',ColumnName) > 0    
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
 UPDATE @Hold SET DataType = 'LabelTheme' WHERE CHARINDEX('Member_Status',ColumnName) > 0 OR CHARINDEX('Vehicle_IsEligible',ColumnName) > 0  
 UPDATE @Hold SET DataType = 'LabelThemeInline' WHERE CHARINDEX('Service_IsPrimaryOverallCovered',ColumnName) > 0
 UPDATE @Hold SET DataType = 'LabelThemeInline' WHERE CHARINDEX('Service_IsSecondaryOverallCovered',ColumnName) > 0   

 IF NOT EXISTS (SELECT * FROM @Hold WHERE ColumnName  = 'Service_IsPossibleTow' AND ColumnValue IS NOT NULL AND  ColumnValue != '')
 BEGIN
	DELETE FROM @Hold WHERE ColumnName  = 'Service_IsSecondaryOverallCovered'
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
	SET  @DefaultRows = (SELECT Sequence FROM @Hold WHERE ColumnName = 'Vehicle_IsEligible')
	IF(@DefaultRows IS NOT NULL)
	BEGIN
		SET @DefaultRows = (SELECT COUNT(*) FROM @Hold WHERE ColumnName LIKE 'Vehicle_%' AND Sequence <= @DefaultRows)
		UPDATE @Hold SET DefaultRows = @DefaultRows WHERE GroupName = 'Vehicle' 
	END
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
 WHERE id = object_id(N'[dbo].[dms_ProgramManagement_Service_Categories_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ProgramManagement_Service_Categories_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_ProgramManagement_Service_Categories_List_Get @programID = 2
 CREATE PROCEDURE [dbo].[dms_ProgramManagement_Service_Categories_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID INT  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
ProductCategoryIDOperator="-1" 
ProductCategoryNameOperator="-1" 
ProductCategoryDescriptionOperator="-1" 
ProgramIDOperator="-1" 
ProgramNameOperator="-1" 
ProgramDescriptionOperator="-1" 
VehicleCategoryIDOperator="-1" 
VehicleCategoryNameOperator="-1" 
VehicleCategoryDescriptionOperator="-1" 
VehicleTypeIDOperator="-1" 
VehicleTypeNameOperator="-1" 
vehicleTypeDescriptionOperator="-1" 
SequenceOperator="-1" 
IsActiveOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
ProductCategoryIDOperator INT NOT NULL,
ProductCategoryIDValue int NULL,
ProductCategoryNameOperator INT NOT NULL,
ProductCategoryNameValue nvarchar(100) NULL,
ProductCategoryDescriptionOperator INT NOT NULL,
ProductCategoryDescriptionValue nvarchar(100) NULL,
ProgramIDOperator INT NOT NULL,
ProgramIDValue int NULL,
ProgramNameOperator INT NOT NULL,
ProgramNameValue nvarchar(100) NULL,
ProgramDescriptionOperator INT NOT NULL,
ProgramDescriptionValue nvarchar(100) NULL,
VehicleCategoryIDOperator INT NOT NULL,
VehicleCategoryIDValue int NULL,
VehicleCategoryNameOperator INT NOT NULL,
VehicleCategoryNameValue nvarchar(100) NULL,
VehicleCategoryDescriptionOperator INT NOT NULL,
VehicleCategoryDescriptionValue nvarchar(100) NULL,
VehicleTypeIDOperator INT NOT NULL,
VehicleTypeIDValue int NULL,
VehicleTypeNameOperator INT NOT NULL,
VehicleTypeNameValue nvarchar(100) NULL,
vehicleTypeDescriptionOperator INT NOT NULL,
vehicleTypeDescriptionValue nvarchar(100) NULL,
SequenceOperator INT NOT NULL,
SequenceValue int NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue bit NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	ProductCategoryID int  NULL ,
	ProductCategoryName nvarchar(100)  NULL ,
	ProductCategoryDescription nvarchar(100)  NULL ,
	ProgramID int  NULL ,
	ProgramName nvarchar(100)  NULL ,
	ProgramDescription nvarchar(100)  NULL ,
	VehicleCategoryID int  NULL ,
	VehicleCategoryName nvarchar(100)  NULL ,
	VehicleCategoryDescription nvarchar(100)  NULL ,
	VehicleTypeID int  NULL ,
	VehicleTypeName nvarchar(100)  NULL ,
	vehicleTypeDescription nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsActive bit  NULL 
) 
CREATE TABLE #tmp_FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	ProductCategoryID int  NULL ,
	ProductCategoryName nvarchar(100)  NULL ,
	ProductCategoryDescription nvarchar(100)  NULL ,
	ProgramID int  NULL ,
	ProgramName nvarchar(100)  NULL ,
	ProgramDescription nvarchar(100)  NULL ,
	VehicleCategoryID int  NULL ,
	VehicleCategoryName nvarchar(100)  NULL ,
	VehicleCategoryDescription nvarchar(100)  NULL ,
	VehicleTypeID int  NULL ,
	VehicleTypeName nvarchar(100)  NULL ,
	vehicleTypeDescription nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsActive bit  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@ProductCategoryIDOperator','INT'),-1),
	T.c.value('@ProductCategoryIDValue','int') ,
	ISNULL(T.c.value('@ProductCategoryNameOperator','INT'),-1),
	T.c.value('@ProductCategoryNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProductCategoryDescriptionOperator','INT'),-1),
	T.c.value('@ProductCategoryDescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProgramIDOperator','INT'),-1),
	T.c.value('@ProgramIDValue','int') ,
	ISNULL(T.c.value('@ProgramNameOperator','INT'),-1),
	T.c.value('@ProgramNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProgramDescriptionOperator','INT'),-1),
	T.c.value('@ProgramDescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleCategoryIDOperator','INT'),-1),
	T.c.value('@VehicleCategoryIDValue','int') ,
	ISNULL(T.c.value('@VehicleCategoryNameOperator','INT'),-1),
	T.c.value('@VehicleCategoryNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleCategoryDescriptionOperator','INT'),-1),
	T.c.value('@VehicleCategoryDescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleTypeIDOperator','INT'),-1),
	T.c.value('@VehicleTypeIDValue','int') ,
	ISNULL(T.c.value('@VehicleTypeNameOperator','INT'),-1),
	T.c.value('@VehicleTypeNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@vehicleTypeDescriptionOperator','INT'),-1),
	T.c.value('@vehicleTypeDescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@SequenceOperator','INT'),-1),
	T.c.value('@SequenceValue','int') ,
	ISNULL(T.c.value('@IsActiveOperator','INT'),-1),
	T.c.value('@IsActiveValue','bit') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------

;WITH wProgramConfig 
  AS
	(SELECT ROW_NUMBER() OVER ( PARTITION BY PPC.ID ORDER BY PP.Sequence) AS RowNum,
			PPC.ID,
			PPC.ProductCategoryID,
			PC.Name AS ProductCategoryName,
			PC.Description AS ProductCategoryDescription,
			PPC.ProgramID,
			P.Name AS ProgramName,
			P.Description AS ProgramDescription,
			PPC.VehicleCategoryID,
			VC.Name AS VehicleCategoryName,
			VC.Description AS VehicleCategoryDescription,
			PPC.VehicleTypeID,
			VT.Name AS VehicleTypeName,
			VT.Description AS vehicleTypeDescription,
			PPC.Sequence,
			PPC.IsActive
			FROM fnc_GetProgramsandParents(@programID) PP
			LEFT JOIN ProgramProductCategory PPC ON PP.ProgramID = PPC.ProgramID
			LEFT JOIN Program P ON P.ID = PPC.ProgramID
			LEFT JOIN ProductCategory PC ON PC.ID = PPC.ProductCategoryID
			LEFT JOIN VehicleCategory VC ON VC.ID = PPC.VehicleCategoryID
			LEFT JOIN VehicleType VT ON VT.ID=PPC.VehicleTypeID	
		)
INSERT INTO #tmp_FinalResults
SELECT 
			W.ID,
			W.ProductCategoryID,
			W.ProductCategoryName,
			W.ProductCategoryDescription,
			W.ProgramID,
			W.ProgramName,
			W.ProgramDescription,
			W.VehicleCategoryID,
			W.VehicleCategoryName,
			W.VehicleCategoryDescription,
			W.VehicleTypeID,
			W.VehicleTypeName,
			W.vehicleTypeDescription,
			W.Sequence,
			W.IsActive
FROM wProgramConfig W WHERE	W.RowNum = 1 AND W.ID IS NOT NULL ORDER BY W.Sequence
INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.ProductCategoryID,
	T.ProductCategoryName,
	T.ProductCategoryDescription,
	T.ProgramID,
	T.ProgramName,
	T.ProgramDescription,
	T.VehicleCategoryID,
	T.VehicleCategoryName,
	T.VehicleCategoryDescription,
	T.VehicleTypeID,
	T.VehicleTypeName,
	T.vehicleTypeDescription,
	T.Sequence,
	T.IsActive
FROM #tmp_FinalResults T,
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
	 ( TMP.ProductCategoryIDOperator = -1 ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 0 AND T.ProductCategoryID IS NULL ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 1 AND T.ProductCategoryID IS NOT NULL ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 2 AND T.ProductCategoryID = TMP.ProductCategoryIDValue ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 3 AND T.ProductCategoryID <> TMP.ProductCategoryIDValue ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 7 AND T.ProductCategoryID > TMP.ProductCategoryIDValue ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 8 AND T.ProductCategoryID >= TMP.ProductCategoryIDValue ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 9 AND T.ProductCategoryID < TMP.ProductCategoryIDValue ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 10 AND T.ProductCategoryID <= TMP.ProductCategoryIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ProductCategoryNameOperator = -1 ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 0 AND T.ProductCategoryName IS NULL ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 1 AND T.ProductCategoryName IS NOT NULL ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 2 AND T.ProductCategoryName = TMP.ProductCategoryNameValue ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 3 AND T.ProductCategoryName <> TMP.ProductCategoryNameValue ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 4 AND T.ProductCategoryName LIKE TMP.ProductCategoryNameValue + '%') 
 OR 
	 ( TMP.ProductCategoryNameOperator = 5 AND T.ProductCategoryName LIKE '%' + TMP.ProductCategoryNameValue ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 6 AND T.ProductCategoryName LIKE '%' + TMP.ProductCategoryNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProductCategoryDescriptionOperator = -1 ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 0 AND T.ProductCategoryDescription IS NULL ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 1 AND T.ProductCategoryDescription IS NOT NULL ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 2 AND T.ProductCategoryDescription = TMP.ProductCategoryDescriptionValue ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 3 AND T.ProductCategoryDescription <> TMP.ProductCategoryDescriptionValue ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 4 AND T.ProductCategoryDescription LIKE TMP.ProductCategoryDescriptionValue + '%') 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 5 AND T.ProductCategoryDescription LIKE '%' + TMP.ProductCategoryDescriptionValue ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 6 AND T.ProductCategoryDescription LIKE '%' + TMP.ProductCategoryDescriptionValue + '%' ) 
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
	 ( TMP.VehicleCategoryIDOperator = -1 ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 0 AND T.VehicleCategoryID IS NULL ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 1 AND T.VehicleCategoryID IS NOT NULL ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 2 AND T.VehicleCategoryID = TMP.VehicleCategoryIDValue ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 3 AND T.VehicleCategoryID <> TMP.VehicleCategoryIDValue ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 7 AND T.VehicleCategoryID > TMP.VehicleCategoryIDValue ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 8 AND T.VehicleCategoryID >= TMP.VehicleCategoryIDValue ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 9 AND T.VehicleCategoryID < TMP.VehicleCategoryIDValue ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 10 AND T.VehicleCategoryID <= TMP.VehicleCategoryIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.VehicleCategoryNameOperator = -1 ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 0 AND T.VehicleCategoryName IS NULL ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 1 AND T.VehicleCategoryName IS NOT NULL ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 2 AND T.VehicleCategoryName = TMP.VehicleCategoryNameValue ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 3 AND T.VehicleCategoryName <> TMP.VehicleCategoryNameValue ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 4 AND T.VehicleCategoryName LIKE TMP.VehicleCategoryNameValue + '%') 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 5 AND T.VehicleCategoryName LIKE '%' + TMP.VehicleCategoryNameValue ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 6 AND T.VehicleCategoryName LIKE '%' + TMP.VehicleCategoryNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VehicleCategoryDescriptionOperator = -1 ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 0 AND T.VehicleCategoryDescription IS NULL ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 1 AND T.VehicleCategoryDescription IS NOT NULL ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 2 AND T.VehicleCategoryDescription = TMP.VehicleCategoryDescriptionValue ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 3 AND T.VehicleCategoryDescription <> TMP.VehicleCategoryDescriptionValue ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 4 AND T.VehicleCategoryDescription LIKE TMP.VehicleCategoryDescriptionValue + '%') 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 5 AND T.VehicleCategoryDescription LIKE '%' + TMP.VehicleCategoryDescriptionValue ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 6 AND T.VehicleCategoryDescription LIKE '%' + TMP.VehicleCategoryDescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VehicleTypeIDOperator = -1 ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 0 AND T.VehicleTypeID IS NULL ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 1 AND T.VehicleTypeID IS NOT NULL ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 2 AND T.VehicleTypeID = TMP.VehicleTypeIDValue ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 3 AND T.VehicleTypeID <> TMP.VehicleTypeIDValue ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 7 AND T.VehicleTypeID > TMP.VehicleTypeIDValue ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 8 AND T.VehicleTypeID >= TMP.VehicleTypeIDValue ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 9 AND T.VehicleTypeID < TMP.VehicleTypeIDValue ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 10 AND T.VehicleTypeID <= TMP.VehicleTypeIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.VehicleTypeNameOperator = -1 ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 0 AND T.VehicleTypeName IS NULL ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 1 AND T.VehicleTypeName IS NOT NULL ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 2 AND T.VehicleTypeName = TMP.VehicleTypeNameValue ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 3 AND T.VehicleTypeName <> TMP.VehicleTypeNameValue ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 4 AND T.VehicleTypeName LIKE TMP.VehicleTypeNameValue + '%') 
 OR 
	 ( TMP.VehicleTypeNameOperator = 5 AND T.VehicleTypeName LIKE '%' + TMP.VehicleTypeNameValue ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 6 AND T.VehicleTypeName LIKE '%' + TMP.VehicleTypeNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.vehicleTypeDescriptionOperator = -1 ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 0 AND T.vehicleTypeDescription IS NULL ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 1 AND T.vehicleTypeDescription IS NOT NULL ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 2 AND T.vehicleTypeDescription = TMP.vehicleTypeDescriptionValue ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 3 AND T.vehicleTypeDescription <> TMP.vehicleTypeDescriptionValue ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 4 AND T.vehicleTypeDescription LIKE TMP.vehicleTypeDescriptionValue + '%') 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 5 AND T.vehicleTypeDescription LIKE '%' + TMP.vehicleTypeDescriptionValue ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 6 AND T.vehicleTypeDescription LIKE '%' + TMP.vehicleTypeDescriptionValue + '%' ) 
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
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'ProductCategoryID' AND @sortOrder = 'ASC'
	 THEN T.ProductCategoryID END ASC, 
	 CASE WHEN @sortColumn = 'ProductCategoryID' AND @sortOrder = 'DESC'
	 THEN T.ProductCategoryID END DESC ,

	 CASE WHEN @sortColumn = 'ProductCategoryName' AND @sortOrder = 'ASC'
	 THEN T.ProductCategoryName END ASC, 
	 CASE WHEN @sortColumn = 'ProductCategoryName' AND @sortOrder = 'DESC'
	 THEN T.ProductCategoryName END DESC ,

	 CASE WHEN @sortColumn = 'ProductCategoryDescription' AND @sortOrder = 'ASC'
	 THEN T.ProductCategoryDescription END ASC, 
	 CASE WHEN @sortColumn = 'ProductCategoryDescription' AND @sortOrder = 'DESC'
	 THEN T.ProductCategoryDescription END DESC ,

	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'ASC'
	 THEN T.ProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'DESC'
	 THEN T.ProgramID END DESC ,

	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'ASC'
	 THEN T.ProgramName END ASC, 
	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'DESC'
	 THEN T.ProgramName END DESC ,

	 CASE WHEN @sortColumn = 'ProgramDescription' AND @sortOrder = 'ASC'
	 THEN T.ProgramDescription END ASC, 
	 CASE WHEN @sortColumn = 'ProgramDescription' AND @sortOrder = 'DESC'
	 THEN T.ProgramDescription END DESC ,

	 CASE WHEN @sortColumn = 'VehicleCategoryID' AND @sortOrder = 'ASC'
	 THEN T.VehicleCategoryID END ASC, 
	 CASE WHEN @sortColumn = 'VehicleCategoryID' AND @sortOrder = 'DESC'
	 THEN T.VehicleCategoryID END DESC ,

	 CASE WHEN @sortColumn = 'VehicleCategoryName' AND @sortOrder = 'ASC'
	 THEN T.VehicleCategoryName END ASC, 
	 CASE WHEN @sortColumn = 'VehicleCategoryName' AND @sortOrder = 'DESC'
	 THEN T.VehicleCategoryName END DESC ,

	 CASE WHEN @sortColumn = 'VehicleCategoryDescription' AND @sortOrder = 'ASC'
	 THEN T.VehicleCategoryDescription END ASC, 
	 CASE WHEN @sortColumn = 'VehicleCategoryDescription' AND @sortOrder = 'DESC'
	 THEN T.VehicleCategoryDescription END DESC ,

	 CASE WHEN @sortColumn = 'VehicleTypeID' AND @sortOrder = 'ASC'
	 THEN T.VehicleTypeID END ASC, 
	 CASE WHEN @sortColumn = 'VehicleTypeID' AND @sortOrder = 'DESC'
	 THEN T.VehicleTypeID END DESC ,

	 CASE WHEN @sortColumn = 'VehicleTypeName' AND @sortOrder = 'ASC'
	 THEN T.VehicleTypeName END ASC, 
	 CASE WHEN @sortColumn = 'VehicleTypeName' AND @sortOrder = 'DESC'
	 THEN T.VehicleTypeName END DESC ,

	 CASE WHEN @sortColumn = 'vehicleTypeDescription' AND @sortOrder = 'ASC'
	 THEN T.vehicleTypeDescription END ASC, 
	 CASE WHEN @sortColumn = 'vehicleTypeDescription' AND @sortOrder = 'DESC'
	 THEN T.vehicleTypeDescription END DESC ,

	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'
	 THEN T.Sequence END ASC, 
	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'
	 THEN T.Sequence END DESC ,

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
DROP TABLE #tmp_FinalResults
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
 -- EXEC [dms_Program_Management_Services_List_Get] @ProgramID =10 ,@pageSize = 25
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
		ProgramNameOperator="-1" 
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
		IsReimbursementOnlyOperator="-1" 
		 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
	ProgramNameOperator INT NOT NULL,
	ProgramNameValue NVARCHAR(50) NULL,
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
	IsReimbursementOnlyOperator INT NOT NULL,
	IsReimbursementOnlyValue bit NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramID INT NOT NULL,
	ProgramName NVARCHAR(50) NULL,
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
	IsReimbursementOnly bit  NULL 
) 

CREATE TABLE #FinalResults_temp( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramID INT NOT NULL,
	ProgramName NVARCHAR(50) NULL,
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
	IsReimbursementOnly bit  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@ProgramNameOperator','INT'),-1),
	T.c.value('@ProgramNameValue','NVARCHAR(50)') ,
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
	ISNULL(T.c.value('@IsReimbursementOnlyOperator','INT'),-1),
	T.c.value('@IsReimbursementOnlyValue','bit') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
;WITH wProgramConfig 
  AS
	(SELECT ROW_NUMBER() OVER ( PARTITION BY PPR.ID ORDER BY PP.Sequence) AS RowNum,
			  P.ID AS ProgramID
			, P.Name AS ProgramName  
			, PPR.ID AS ProgramProductID
			, PC.Name AS Category
			, PR.Name AS [Service]
			, PPR.StartDate
			, PPR.EndDate
			, PPR.ServiceCoverageLimit
			, PPR.IsServiceCoverageBestValue
			, PPR.MaterialsCoverageLimit
			, PPR.IsMaterialsMemberPay
			, PPR.ServiceMileageLimit
			, PPR.IsServiceMileageUnlimited
			, PPR.IsServiceMileageOverageAllowed
			, PPR.IsReimbursementOnly
			, PP.Sequence
			FROM fnc_GetProgramsandParents(@programID) PP
			LEFT JOIN ProgramProduct PPR ON PP.ProgramID = PPR.ProgramID
			JOIN Program P (NOLOCK) ON P.ID = PP.ProgramID
			JOIN Product PR (NOLOCK) ON PR.ID = PPR.ProductID
			JOIN ProductCategory PC (NOLOCK) ON PC.ID = PR.ProductCategoryID
	)

INSERT INTO #FinalResults_temp
SELECT
			  W.ProgramID
			, W.ProgramName  
			, W.ProgramProductID
			, W.Category
			, W.[Service]
			, W.StartDate
			, W.EndDate
			, W.ServiceCoverageLimit
			, W.IsServiceCoverageBestValue
			, W.MaterialsCoverageLimit
			, W.IsMaterialsMemberPay
			, W.ServiceMileageLimit
			, W.IsServiceMileageUnlimited
			, W.IsServiceMileageOverageAllowed
			, W.IsReimbursementOnly
FROM wProgramConfig W WHERE	W.RowNum = 1  ORDER BY W.Sequence
INSERT INTO #FinalResults
SELECT 
	T.ProgramID,
	T.ProgramName,
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
	T.IsReimbursementOnly
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
	 ( TMP.IsReimbursementOnlyOperator = -1 ) 
 OR 
	 ( TMP.IsReimbursementOnlyOperator = 0 AND T.IsReimbursementOnly IS NULL ) 
 OR 
	 ( TMP.IsReimbursementOnlyOperator = 1 AND T.IsReimbursementOnly IS NOT NULL ) 
 OR 
	 ( TMP.IsReimbursementOnlyOperator = 2 AND T.IsReimbursementOnly = TMP.IsReimbursementOnlyValue ) 
 OR 
	 ( TMP.IsReimbursementOnlyOperator = 3 AND T.IsReimbursementOnly <> TMP.IsReimbursementOnlyValue ) 
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

	 CASE WHEN @sortColumn = 'IsReimbursementOnly' AND @sortOrder = 'ASC'
	 THEN T.IsReimbursementOnly END ASC, 
	 CASE WHEN @sortColumn = 'IsReimbursementOnly' AND @sortOrder = 'DESC'
	 THEN T.IsReimbursementOnly END DESC,
	 
	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'ASC'
	 THEN T.ProgramName END ASC, 
	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'DESC'
	 THEN T.ProgramName END DESC  


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
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_vendor_list] @pageSize=5000 @whereClauseXML="<ROW>\r\n  <Filter VendorNumber=\'1,4\' />\r\n</ROW>"
 
 CREATE PROCEDURE [dbo].[dms_vendor_list](
   
 @whereClauseXML NVARCHAR(4000) = NULL 

 , @startInd Int = 1 

 , @endInd BIGINT = 5000 

 , @pageSize int = 10  

 , @sortColumn nvarchar(100)  = 'VendorName' 

 , @sortOrder nvarchar(100) = 'ASC' 

  

 ) 

 AS 

 BEGIN   
 SET FMTONLY OFF  
  SET NOCOUNT ON  
  
CREATE TABLE #FinalResultsFiltered  
(  
 ContractStatus NVARCHAR(100) NULL,  
 VendorID INT NULL,  
 VendorNumber NVARCHAR(50) NULL,  
 VendorName NVARCHAR(255) NULL,  
 City NVARCHAR(100) NULL,  
 StateProvince NVARCHAR(10) NULL,  
 CountryCode NVARCHAR(2) NULL,  
 OfficePhone NVARCHAR(50) NULL,  
 AdminRating INT NULL,  
 InsuranceExpirationDate DATETIME NULL,  
 PaymentMethod NVARCHAR(50) NULL,  
 VendorStatus NVARCHAR(50) NULL,  
 VendorRegion NVARCHAR(50) NULL,  
 PostalCode NVARCHAR(20) NULL  ,
 POCount INT NULL
)  
  
CREATE TABLE #FinalResultsSorted  
(  
 RowNum BIGINT NOT NULL IDENTITY(1,1),  
 ContractStatus NVARCHAR(100) NULL,  
 VendorID INT NULL,  
 VendorNumber NVARCHAR(50) NULL,  
 VendorName NVARCHAR(255) NULL,  
 City NVARCHAR(100) NULL,  
 StateProvince NVARCHAR(10) NULL,  
 CountryCode NVARCHAR(2) NULL,  
 OfficePhone NVARCHAR(50) NULL,  
 AdminRating INT NULL,  
 InsuranceExpirationDate DATETIME NULL,  
 PaymentMethod NVARCHAR(50) NULL,  
 VendorStatus NVARCHAR(50) NULL,  
 VendorRegion NVARCHAR(50) NULL,  
 PostalCode NVARCHAR(20) NULL ,
 POCount INT NULL 
)  
  
DECLARE @idoc int  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
VendorNameOperator NVARCHAR(50) NULL,  
VendorName NVARCHAR(MAX) NULL,  
VendorNumber NVARCHAR(50) NULL,  
CountryID INT NULL,  
StateProvinceID INT NULL,  
City nvarchar(255) NULL,  
VendorStatus NVARCHAR(100) NULL,  
VendorRegion NVARCHAR(100) NULL,  
PostalCode NVARCHAR(20) NULL,  
IsLevy BIT NULL  ,
HasPO BIT NULL,
IsFordDirectTow BIT NULL,
IsCNETDirectPartner BIT NULL
)  
  
DECLARE @VendorNameOperator NVARCHAR(50) ,  
@VendorName NVARCHAR(MAX) ,  
@VendorNumber NVARCHAR(50) ,  
@CountryID INT ,  
@StateProvinceID INT ,  
@City nvarchar(255) ,  
@VendorStatus NVARCHAR(100) ,  
@VendorRegion NVARCHAR(100) ,  
@PostalCode NVARCHAR(20) ,  
@IsLevy BIT,
@HasPO BIT   ,
@programID INT	= NULL,
@IsFordDirectTow BIT,
@IsCNETDirectPartner BIT
  
INSERT INTO @tmpForWhereClause  
SELECT    
 VendorNameOperator,  
 VendorName ,  
 VendorNumber,  
 CountryID,  
 StateProvinceID,  
 City,  
 VendorStatus,  
 VendorRegion,  
    PostalCode,  
    IsLevy ,
	HasPo,
	IsFordDirectTow,
	IsCNETDirectPartner
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
 VendorNameOperator NVARCHAR(50),  
 VendorName NVARCHAR(MAX),  
 VendorNumber NVARCHAR(50),   
 CountryID INT,  
 StateProvinceID INT,  
 City nvarchar(255),   
 VendorStatus NVARCHAR(100),  
 VendorRegion NVARCHAR(100),  
 PostalCode NVARCHAR(20),  
 IsLevy BIT ,
 HasPo BIT,
 IsFordDirectTow BIT,
 IsCNETDirectPartner BIT
)   
  
SELECT    
  @VendorNameOperator = VendorNameOperator ,  
  @VendorName = VendorName ,  
  @VendorNumber = VendorNumber,  
  @CountryID = CountryID,  
  @StateProvinceID = StateProvinceID,  
  @City = City,  
  @VendorStatus = VendorStatus,  
  @VendorRegion = VendorRegion,  
  @PostalCode = PostalCode,  
  @IsLevy = IsLevy  ,
  @HasPO = HasPO,
  @IsFordDirectTow = IsFordDirectTow,
  @IsCNETDirectPartner = IsCNETDirectPartner
FROM @tmpForWhereClause  
  
--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
-- LOGIC : START  

DECLARE @PoCount AS TABLE(VendorID INT NULL,PoCount INT NULL)
INSERT INTO @PoCount
SELECT V.ID,
	   COUNT(PO.ID) FROM PurchaseOrder PO 
	   LEFT JOIN VendorLocation VL ON PO.VendorLocationID = VL.ID
	   LEFT JOIN Vendor V ON VL.VendorID = V.ID
WHERE  PO.IsActive = 1
GROUP BY V.ID 
  
DECLARE @vendorEntityID INT, @businessAddressTypeID INT, @officePhoneTypeID INT  
SELECT @vendorEntityID = ID FROM Entity WHERE Name = 'Vendor'  
SELECT @businessAddressTypeID = ID FROM AddressType WHERE Name = 'Business'  
SELECT @officePhoneTypeID = ID FROM PhoneType WHERE Name = 'Office'  
  
;WITH wVendorAddresses  
AS  
(   
 SELECT ROW_NUMBER() OVER ( PARTITION BY RecordID, AddressTypeID ORDER BY ID ) AS RowNum,  
   *  
 FROM AddressEntity   
 WHERE EntityID = @vendorEntityID  
 AND  AddressTypeID = @businessAddressTypeID  
),
wVendorPhone
AS

(

	SELECT ROW_NUMBER() OVER ( PARTITION BY RecordID, PhoneTypeID ORDER BY ID DESC ) AS RowNum,

			*

	FROM	PhoneEntity 

	WHERE	EntityID = @vendorEntityID

	AND		PhoneTypeID = @officePhoneTypeID

)

INSERT INTO #FinalResultsFiltered  
SELECT DISTINCT  
  --CASE WHEN C.VendorID IS NOT NULL   
  --  THEN 'Contracted'   
  --  ELSE 'Not Contracted'   
  --  END AS ContractStatus  
  --NULL As ContractStatus  
  CASE  
   WHEN ContractedVendors.ContractID IS NOT NULL   
    AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'  
   ELSE 'Not Contracted'   
  END AS ContractStatus  
  , V.ID AS VendorID  
  , V.VendorNumber AS VendorNumber  
  --, V.Name AS VendorName  
 -- ,v.Name +	
	--CASE WHEN VPCNDP.VendorID IS NOT NULL THEN ' (P)' ELSE '' END  + 
	--CASE WHEN VPFDT.VendorID IS NOT NULL 
	--		THEN ' (DT)' 
	--ELSE '' END VendorName
  , v.Name + COALESCE(F.Indicators,'') AS VendorName
  , AE.City AS City  
  , AE.StateProvince AS State  
  , AE.CountryCode AS Country  
  , PE.PhoneNumber AS OfficePhone  
  , V.AdministrativeRating AS AdminRating  
  , V.InsuranceExpirationDate AS InsuranceExpirationDate  
  , VACH.BankABANumber AS PaymentMethod -- To be calculated in the next step.  
  , VS.Name AS VendorStatus  
  , VR.Name AS VendorRegion  
  , AE.PostalCode  
  , ISNULL((SELECT PoCount FROM @PoCount POD WHERE POD.VendorID = V.ID),0) AS POCount
FROM Vendor V WITH (NOLOCK)  
LEFT JOIN [dbo].[fnc_GetVendorIndicators]('Vendor') F ON V.ID = F.RecordID
--LEFT JOIN   VendorLocation VL ON V.ID = VL.VendorID
--Left Outer Join VendorProduct VPFDT ON VPFDT.VendorID = V.ID and VPFDT.ProductID = (Select ID from Product where Name = 'Ford Direct Tow') and VPFDT.IsActive = 1
--Left Outer Join VendorProduct VPCNDP on VPCNDP.VendorID = V.ID and VPCNDP.ProductID = (Select ID from Product where Name = 'CoachNet Dealer Partner') and VPCNDP.IsActive = 1
--LEFT JOIN   PurchaseOrder PO ON VL.ID = PO.VendorLocationID AND ISNULL(PO.IsActive,0) = 1
LEFT JOIN [dbo].[fnGetDirectTowVendors]() VPFDT ON VPFDT.VendorID = V.ID
LEFT JOIN [dbo].[fnGetCoachNetDealerPartnerVendors]() VPCNDP ON VPCNDP.VendorID = V.ID
LEFT JOIN wVendorAddresses AE ON AE.RecordID = V.ID AND AE.RowNum = 1  
LEFT JOIN	wVendorPhone PE ON PE.RecordID = V.ID AND PE.RowNum = 1  
LEFT JOIN VendorStatus VS ON VS.ID = V.VendorStatusID  
LEFT JOIN VendorACH VACH ON VACH.VendorID = V.ID  
LEFT JOIN VendorRegion VR ON VR.ID=V.VendorRegionID  
LEFT OUTER JOIN(  
   SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID  
   FROM dbo.fnGetContractedVendors() cv  
   ) ContractedVendors ON v.ID = ContractedVendors.VendorID   
--LEFT OUTER JOIN (SELECT VendorID, MAX(CreateDate) AS [CreateDate] FROM [Contract] WHERE IsActive = 1 GROUP BY VendorID) C ON C.VendorID = V.ID  =
WHERE V.IsActive = 1  -- Not deleted    
AND  (@VendorNumber IS NULL OR @VendorNumber = V.VendorNumber)  
AND  (@CountryID IS NULL OR @CountryID = AE.CountryID)  
AND  (@StateProvinceID IS NULL OR @StateProvinceID = AE.StateProvinceID)  
AND  (@City IS NULL OR @City = AE.City)  
AND  (@PostalCode IS NULL OR @PostalCode = AE.PostalCode)  
AND  (@IsLevy IS NULL OR @IsLevy = ISNULL(V.IsLevyActive,0))  
AND  (@IsFordDirectTow IS NULL OR (@IsFordDirectTow = 1 AND COALESCE(F.Indicators,'') LIKE '%(DT)%'))  
AND  (@IsCNETDirectPartner IS NULL OR (@IsCNETDirectPartner = 1 AND COALESCE(F.Indicators,'') LIKE '%(P)%'))  
AND  (@VendorStatus IS NULL OR VS.ID IN (SELECT Item FROM [dbo].[fnSplitString](@VendorStatus,',') ) )  
AND  (@VendorRegion IS NULL OR VR.ID IN (SELECT Item FROM [dbo].[fnSplitString](@VendorRegion,',') ) )  
AND  (    
   (@VendorNameOperator IS NULL )  
   OR  
   (@VendorNameOperator = 'Begins with' AND V.Name LIKE  @VendorName + '%')  
   OR  
   (@VendorNameOperator = 'Is equal to' AND V.Name =  @VendorName )  
   OR  
   (@VendorNameOperator = 'Ends with' AND V.Name LIKE  '%' + @VendorName)  
   OR  
   (@VendorNameOperator = 'Contains' AND V.Name LIKE  '%' + @VendorName + '%')  
  )  
 --GROUP BY 

	--	ContractStatus,
	--	V.ID,
	--	V.VendorNumber,
	--	V.Name,
	--	AE.City,
	--	AE.StateProvince,
	--	AE.CountryCode,
	--	PE.PhoneNumber,
	--	V.AdministrativeRating,
	--	V.InsuranceExpirationDate,
	--	VACH.BankABANumber,
	--	VS.Name,
	--	VR.Name,
	--	AE.PostalCode,
	--	ContractedVendors.ContractRateScheduleID,
	--	ContractedVendors.ContractID
 --UPDATE #FinalResultsFiltered  
 --SET ContractStatus = CASE WHEN C.VendorID IS NOT NULL   
 --      THEN 'Contracted'   
 --      ELSE 'Not Contracted'   
 --      END,  
 -- PaymentMethod =  CASE  
 --      WHEN ISNULL(F.PaymentMethod,'') = '' THEN 'Check'  
 --      ELSE 'DirectDeposit'  
 --      END  
 --FROM #FinalResultsFiltered F  
 --LEFT OUTER JOIN (SELECT VendorID, MAX(CreateDate) AS [CreateDate] FROM [Contract] WHERE IsActive = 1 GROUP BY VendorID) C ON C.VendorID = F.VendorID  
   
 INSERT INTO #FinalResultsSorted  
 SELECT   ContractStatus  
  , VendorID  
  , VendorNumber  
  , VendorName  
  , City  
  , StateProvince  
  , CountryCode  
  , OfficePhone  
  , AdminRating  
  , InsuranceExpirationDate  
  , PaymentMethod  
  , VendorStatus  
  , VendorRegion  
  , PostalCode  
  , POCount
 FROM #FinalResultsFiltered T   
 WHERE	(@HasPO IS NULL OR @HasPO = 0 OR T.POCount > 0)
 ORDER BY   
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'ASC'  
  THEN T.ContractStatus END ASC,   
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'DESC'  
  THEN T.ContractStatus END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'ASC'  
  THEN T.VendorID END ASC,   
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'DESC'  
  THEN T.VendorID END DESC ,  
    
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'  
  THEN T.VendorNumber END ASC,   
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'  
  THEN T.VendorNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'ASC'  
  THEN T.VendorName END ASC,   
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'DESC'  
  THEN T.VendorName END DESC ,  
  
  CASE WHEN @sortColumn = 'City' AND @sortOrder = 'ASC'  
  THEN T.City END ASC,   
  CASE WHEN @sortColumn = 'City' AND @sortOrder = 'DESC'  
  THEN T.City END DESC ,  
    
  CASE WHEN @sortColumn = 'StateProvince' AND @sortOrder = 'ASC'  
  THEN T.StateProvince END ASC,   
  CASE WHEN @sortColumn = 'StateProvince' AND @sortOrder = 'DESC'  
  THEN T.StateProvince END DESC ,  
  
  CASE WHEN @sortColumn = 'CountryCode' AND @sortOrder = 'ASC'  
  THEN T.CountryCode END ASC,   
  CASE WHEN @sortColumn = 'CountryCode' AND @sortOrder = 'DESC'  
  THEN T.CountryCode END DESC ,  
    
  CASE WHEN @sortColumn = 'OfficePhone' AND @sortOrder = 'ASC'  
  THEN T.OfficePhone END ASC,   
  CASE WHEN @sortColumn = 'OfficePhone' AND @sortOrder = 'DESC'  
  THEN T.OfficePhone END DESC ,  
    
  CASE WHEN @sortColumn = 'AdminRating' AND @sortOrder = 'ASC'  
  THEN T.AdminRating END ASC,   
  CASE WHEN @sortColumn = 'AdminRating' AND @sortOrder = 'DESC'  
  THEN T.AdminRating END DESC ,  
    
  CASE WHEN @sortColumn = 'InsuranceExpirationDate' AND @sortOrder = 'ASC'  
  THEN T.InsuranceExpirationDate END ASC,   
  CASE WHEN @sortColumn = 'InsuranceExpirationDate' AND @sortOrder = 'DESC'  
  THEN T.InsuranceExpirationDate END DESC ,  
    
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'ASC'  
  THEN T.VendorStatus END ASC,   
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'DESC'  
  THEN T.VendorStatus END DESC ,  
    
  CASE WHEN @sortColumn = 'VendorRegion' AND @sortOrder = 'ASC'  
  THEN T.VendorRegion END ASC,   
  CASE WHEN @sortColumn = 'VendorRegion' AND @sortOrder = 'DESC'  
  THEN T.VendorRegion END DESC ,  
  --VendorRegion  
  CASE WHEN @sortColumn = 'PaymentMethod' AND @sortOrder = 'ASC'  
  THEN T.PaymentMethod END ASC,   
  CASE WHEN @sortColumn = 'PaymentMethod' AND @sortOrder = 'DESC'  
  THEN T.PaymentMethod END DESC ,  
     
  CASE WHEN @sortColumn = 'PostalCode' AND @sortOrder = 'ASC'  
  THEN T.PostalCode END ASC,   
  CASE WHEN @sortColumn = 'PostalCode' AND @sortOrder = 'DESC'  
  THEN T.PostalCode END DESC   ,
  
  CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'
	THEN T.POCount END ASC, 
	CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'
	 THEN T.POCount END DESC 

   
  
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
 WHERE id = object_id(N'[dbo].[dms_VerifyProgramServiceBenefit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC dms_VerifyProgramServiceBenefit 1, 1, 1, 1, 1, NULL, NULL  
CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit]  
        @ProgramID INT   
      , @ProductCategoryID INT  
      , @VehicleCategoryID INT  
      , @VehicleTypeID INT  
      , @SecondaryCategoryID INT = NULL  
      , @ServiceRequestID  INT = NULL  
      , @ProductID INT = NULL  
AS  
BEGIN   
  
 SET NOCOUNT ON    
 SET FMTONLY OFF    
   
 --KB: 
 --SET @ProductID = NULL

 DECLARE @SecondaryProductID INT  
  
 /*** Determine Primary and Secondary Product IDs ***/  
 /* Select Basic Lockout over Locksmith when a specific product is not provided */  
 IF @ProductID IS NULL AND @ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Lockout')  
 BEGIN  
  SET @ProductID = (SELECT ID FROM Product WHERE Name = 'Basic Lockout')  
 END  
  
 /* Select Tire Change over Tire Repair when a specific product is not provided */  
 IF @ProductID IS NULL AND @ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tire')  
 BEGIN  
  SET @ProductID = (SELECT ID FROM Product WHERE Name like 'Tire Change%' AND VehicleCategoryID = @VehicleCategoryID)  
 END  
  
 IF @ProductID IS NULL  
  SELECT @ProductID = p.ID   
  FROM  ProductCategory pc (NOLOCK)   
  JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID   
      AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')  
      AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')  
  WHERE  
  pc.ID = @ProductCategoryID   
  AND (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)  
  AND (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)  
  
  
 IF @SecondaryCategoryID IS NOT NULL  
  SELECT @SecondaryProductID = p.ID   
  FROM  ProductCategory pc (NOLOCK)   
  JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID   
      AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')  
      AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')  
  WHERE  
  pc.ID = @SecondaryCategoryID   
  AND (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)  
  AND (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)  
  
   
      SELECT ISNULL(pc.Name,'') ProductCategoryName  
            ,pc.ID ProductCategoryID  
            --,pc.Sequence  
            ,ISNULL(vc.Name,'') VehicleCategoryName  
            ,vc.ID VehicleCategoryID  
            ,pp.ProductID  
  
            ,CAST (pp.IsServiceCoverageBestValue AS BIT) AS IsServiceCoverageBestValue
            ,pp.ServiceCoverageLimit   
            ,pp.CurrencyTypeID   
            ,pp.ServiceMileageLimit   
            ,pp.ServiceMileageLimitUOM   
            --TO DO - Fix this logic  
            ,CASE WHEN pp.ServiceCoverageLimit IS NULL THEN 0   
                          WHEN pp.ServiceCoverageLimit = 0 AND pp.IsReimbursementOnly = 1 THEN 1   
                          WHEN pp.IsServiceCoverageBestValue = 1 THEN 1  
                          WHEN pp.ServiceCoverageLimit > 0 THEN 1  
                          ELSE 0 END IsServiceEligible  
            ,pp.IsServiceGuaranteed   
            ,pp.ServiceCoverageDescription  
            ,pp.IsReimbursementOnly  
            ,CASE WHEN pc.ID = @SecondaryCategoryID THEN 0 ELSE 1 END AS IsPrimary  
      FROM ProgramProduct pp (NOLOCK)  
      JOIN Product p ON p.ID = pp.ProductID  
      LEFT OUTER JOIN ProductCategory pc (NOLOCK) ON pc.ID = p.ProductCategoryID  
      LEFT OUTER JOIN VehicleCategory vc (NOLOCK) ON vc.id = p.VehicleCategoryID  
      WHERE pp.ProgramID = @ProgramID  
      AND (pp.ProductID = @ProductID OR pp.ProductID = @SecondaryProductID)  
   ORDER BY   
   (CASE WHEN pc.ID = @SecondaryCategoryID THEN 0 ELSE 1 END) DESC  
   ,pc.Sequence  
     
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
 WHERE id = object_id(N'[dbo].[dms_VerifyProgramServiceEventLimit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

 --EXEC dms_VerifyProgramServiceEventLimit 1, 3,1,null, null, null  
CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit]  
      @MemberID int
      ,@ProgramID int
      ,@ProductCategoryID int
      ,@ProductID int 
      ,@VehicleTypeID int
      ,@VehicleCategoryID int 
      ,@SecondaryCategoryID INT = NULL
AS
BEGIN

SET @ProductID = NULL

--Debug
--DECLARE 
--      @MemberID int = 7779982
--      ,@ProgramID int = 3
--      ,@ProductCategoryID int = 1
--      ,@ProductID int = NULL
--      ,@VehicleTypeID int = 1
--      ,@VehicleCategoryID int = 1
--      ,@SecondaryCategoryID INT = 1

SET NOCOUNT ON  
SET FMTONLY OFF  

      If @ProgramID IS NULL
            SELECT @ProgramID = ProgramID FROM Member WHERE ID = @MemberID
            
        If @ProductID IS NOT NULL
            SELECT @ProductCategoryID = ProductCategoryID
                  ,@VehicleCategoryID = VehicleCategoryID
                  ,@VehicleTypeID = VehicleTypeID
            FROM Product 
            WHERE ID = @ProductID

      Select 
            ServiceRequestEvent.ProgramServiceEventLimitID
            ,ServiceRequestEvent.ProgramEventLimitDescription
            ,ServiceRequestEvent.ProgramEventLimit
            ,ServiceRequestEvent.ProgramID
            ,ServiceRequestEvent.MemberID
            ,ServiceRequestEvent.ProductCategoryID
            ,ServiceRequestEvent.ProductID
            ,MIN(MinEventDate) MinEventDate
            ,count(*) EventCount
      Into #tmpProgramEventCount
      From (
            Select 
                  ppl.ID ProgramServiceEventLimitID
                  ,ppl.[Description] ProgramEventLimitDescription
                  ,ppl.Limit ProgramEventLimit
                  ,c.ProgramID 
                  ,c.MemberID
                  ,sr.ID ServiceRequestID
                  ,ppl.ProductCategoryID
                  ,ppl.ProductID
                  ,pc.Name ProductCategoryName
                  ,MIN(po.IssueDate) MinEventDate 
            From [Case] c
            Join ServiceRequest sr on c.ID = sr.CaseID
            Join PurchaseOrder po on sr.ID = po.ServiceRequestID and po.PurchaseOrderStatusID in (Select ID from PurchaseOrderStatus Where Name IN ('Issued', 'Issued-Paid'))
            Join Product p on po.ProductID = p.ID
            Join ProductCategory pc on pc.id = p.ProductCategoryID
            Join ProgramServiceEventLimit ppl on ppl.ProgramID = c.ProgramID 
                  and (ppl.ProductCategoryID IS NULL OR ppl.ProductCategoryID = pc.ID)
                  and (ppl.ProductID IS NULL OR ppl.ProductID = p.ID)
                  and ppl.IsActive = 1
                  and po.IssueDate > 
                        CASE WHEN ppl.LimitDurationUOM = 'Day' THEN DATEADD(dd,-ppl.LimitDuration, getdate())
                              WHEN ppl.LimitDurationUOM = 'Month' THEN DATEADD(mm,-ppl.LimitDuration, getdate())
                              WHEN ppl.LimitDurationUOM = 'Year' THEN DATEADD(yy,-ppl.LimitDuration, getdate())
                              ELSE NULL
                              END 
            Where 
                  c.MemberID = @MemberID
                  and c.ProgramID = @ProgramID
                  and po.IssueDate IS NOT NULL
            Group By 
                  ppl.ID
                  ,ppl.[Description]
                  ,ppl.Limit
                  ,c.programid
                  ,c.MemberID
                  ,sr.ID
                  ,ppl.ProductCategoryID
                  ,ppl.ProductID
                  ,pc.Name
            ) ServiceRequestEvent
      Group By 
            ServiceRequestEvent.ProgramServiceEventLimitID
            ,ServiceRequestEvent.ProgramEventLimit
            ,ServiceRequestEvent.ProgramEventLimitDescription
            ,ServiceRequestEvent.ProgramID
            ,ServiceRequestEvent.MemberID
            ,ServiceRequestEvent.ProductCategoryID
            ,ServiceRequestEvent.ProductID


      Select 
            psel.ID --ProgramServiceEventLimitID
            ,psel.ProgramID
            ,psel.[Description]
            ,psel.Limit
            ,ISNULL(pec.EventCount, 0) EventCount
            ,CASE WHEN psel.ProductCategoryID = @SecondaryCategoryID AND @ProductCategoryID <> @SecondaryCategoryID THEN 0 ELSE 1 END IsPrimary
            ,CASE WHEN ISNULL(pec.EventCount, 0) < psel.Limit THEN 1 ELSE 0 END IsEligible
      From ProgramServiceEventLimit psel
      Left Outer Join #tmpProgramEventCount pec on pec.ProgramServiceEventLimitID = psel.ID
      Where psel.ProgramID = @ProgramID
      AND   (
                  (@ProductID IS NOT NULL 
                        AND psel.ProductID = @ProductID)
                  OR
                  (@ProductID IS NULL 
                        AND psel.ProductCategoryID = @ProductCategoryID 
                        AND (@VehicleCategoryID IS NULL OR psel.VehicleCategoryID IS NULL OR psel.VehicleCategoryID = @VehicleCategoryID)
                        AND (@VehicleTypeID IS NULL OR psel.VehicleTypeID IS NULL OR psel.VehicleTypeID = @VehicleTypeID)
                  )
                  OR
                  (psel.ProductCategoryID = @SecondaryCategoryID AND @ProductCategoryID <> @SecondaryCategoryID
                        AND (@VehicleCategoryID IS NULL OR psel.VehicleCategoryID IS NULL OR psel.VehicleCategoryID = @VehicleCategoryID)
                        AND (@VehicleTypeID IS NULL OR psel.VehicleTypeID IS NULL OR psel.VehicleTypeID = @VehicleTypeID)
                  ))
        ORDER BY (CASE WHEN psel.ProductCategoryID = @SecondaryCategoryID THEN 0 ELSE 1 END) DESC
            ,psel.ProductID DESC

     Drop table #tmpProgramEventCount

END
GO
GO
