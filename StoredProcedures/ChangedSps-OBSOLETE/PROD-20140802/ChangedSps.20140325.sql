IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnGetDefaultProductRatesByMarketLocation]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnGetDefaultProductRatesByMarketLocation]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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
		Select mlpr2.ProductID, mlpr2.RateTypeID,mlpr2.Price RatePrice, mlpr2.Quantity RateQuantity
		From dbo.MarketLocation ml2
		--Added Join to eliminate issues with overlapping metro area radii
		JOIN (
			Select Min(mld.GeographyLocation.STDistance(@ServiceLocationGeography)) MinDistance
			From dbo.MarketLocation mld
			Where mld.MarketLocationTypeID = (Select ID From MarketLocationType Where Name = 'Metro')
				And mld.IsActive = 'TRUE'
				and mld.GeographyLocation.STDistance(@ServiceLocationGeography) <= mld.RadiusMiles * 1609.344
			) MetroDistance ON MetroDistance.MinDistance = ml2.GeographyLocation.STDistance(@ServiceLocationGeography)
		Left Outer Join dbo.MarketLocationProductRate mlpr2 On ml2.ID = mlpr2.MarketLocationID 

		--Select mlpr2.ProductID, mlpr2.RateTypeID, mlpr2.Price RatePrice, mlpr2.Quantity RateQuantity
		--From dbo.MarketLocation ml2
		--Left Outer Join dbo.MarketLocationProductRate mlpr2 On ml2.ID = mlpr2.MarketLocationID 
		----Left Outer Join dbo.RateType rt2 On cpr2.RateTypeID = rt2.ID
		--Where ml2.MarketLocationTypeID = (Select ID From MarketLocationType Where Name = 'Metro')
		--	And ml2.IsActive = 'TRUE'
		--	and ml2.GeographyLocation.STDistance(@ServiceLocationGeography) <= ml2.RadiusMiles * 1609.344
		
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
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Call_Summary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Call_Summary]
GO

--EXEC dms_Call_Summary @serviceRequestID = 1414  
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
	, ISNULL(
		COALESCE(pc.Name, '') + 
		COALESCE('/' + CASE WHEN sr.IsPossibleTow = 1 THEN 'Possible Tow' END, '')
		,' ') as Service_ProductCategoryTow    
	, '$' + CONVERT(NVARCHAR(50),ISNULL(sr.PrimaryCoverageLimit,0)) as Service_CoverageLimit  

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
 UPDATE @Hold SET GroupName = 'Service' ,DefaultRows = 2 WHERE CHARINDEX('Service_',ColumnName) > 0    
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

 DELETE FROM @Hold WHERE ColumnValue IS NULL

 DECLARE @DefaultRows INT
 SET  @DefaultRows = (SELECT Sequence FROM @Hold WHERE ColumnName = 'Member_AltCallbackPhoneNumber')
 IF @DefaultRows IS NOT NULL
 BEGIN
 SET @DefaultRows = (SELECT COUNT(*) FROM @Hold WHERE ColumnName LIKE 'Member_%' AND Sequence <= @DefaultRows)
 -- Re Setting values 
 UPDATE @Hold SET DefaultRows = @DefaultRows WHERE GroupName = 'Member' 
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
   
	 ; WITH wVendors  
	 AS  
	 (   
		Select   
				v.ID VendorID  
				--,v.Name + CASE WHEN v.DealerNumber IS NOT NULL THEN ' *** DLR#: ' + v.DealerNumber ELSE N'' END  VendorName  
				/*KB: There is no DealerNumber in Vendor table now. + CASE WHEN v.DealerNumber IS NOT NULL THEN ' *** Ford Direct Tow' ELSE N'' END */   
				,v.Name + CASE WHEN @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Direct Tow') AND vlp.ID IS NOT NULL AND vl.DealerNumber IS NOT NULL AND vl.PartsAndAccessoryCode IS NOT NULL 
					THEN ' (DT)' ELSE '' END VendorName
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
				
		From	dbo.VendorLocation vl   
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
	 )  
   
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
	SELECT  W.*,  
			VP.AllServices,  
			CMT.Comments,
			Faxph.PhoneNumber AS FaxPhoneNumber,
			Officeph.PhoneNumber AS OfficePhoneNumber,
			Cellph.PhoneNumber AS CellPhoneNumber,
			NULL,
			NULL 
   
	FROM	wVendors W  
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
				FROM	[dbo].[fnc_GetProgramConfigurationForProgram](@ProgramID,'ProgramInfo') P 
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
END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ServiceRequest_Vendor_Details_From_Map_Update]')   		AND type in (N'P', N'PC')) 
 BEGIN
DROP PROCEDURE [dbo].[dms_ServiceRequest_Vendor_Details_From_Map_Update]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  
 -- EXEC [dms_ServiceRequest_Vendor_Details_From_Map_Update] 1414
CREATE PROCEDURE [dbo].[dms_ServiceRequest_Vendor_Details_From_Map_Update]  
 @serviceRequestID INT	= NULL 
AS  
BEGIN

	UPDATE	ServiceRequest
	SET		DealerIDNumber = VL.DealerNumber,
			PartsAndAccessoryCode = VL.PartsAndAccessoryCode,
			IsDirectTowDealer = CASE WHEN VLP.ID IS NULL THEN 0 ELSE 1 END
	FROM	ServiceRequest SR
	JOIN	VendorLocation VL ON SR.DestinationVendorLocationID = VL.ID
	LEFT JOIN	VendorLocationProduct VLP ON VLP.VendorLocationID = VL.ID AND VLP.ProductID = 
						(
							SELECT ID FROM Product WHERE Name = 'Ford Direct Tow' 
						)
	WHERE	SR.ID = @serviceRequestID
	


END
GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_tempcc_match_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_tempcc_match_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vendor_tempcc_match_update] @tempccIdXML = '<Tempcc><ID>1</ID><ID>2</ID><ID>3</ID><ID>4</ID></Tempcc>',@currentUser = 'demouser'
 CREATE PROCEDURE [dbo].[dms_vendor_tempcc_match_update](
	@tempccIdXML XML,
	@currentUser NVARCHAR(50)
  )
 AS
 BEGIN
 
    SET FMTONLY OFF
	SET NOCOUNT ON

	DECLARE @now DATETIME = GETDATE()
	DECLARE @CCExpireDays int = 30
	DECLARE @MinCreateDate datetime

	DECLARE @Matched INT =0
		,@MatchedAmount money =0
		,@Unmatched int = 0
		,@UnmatchedAmount money = 0
		,@Posted INT=0
		,@PostedAmount money=0
		,@Cancelled INT=0
		,@CancelledAmount money=0
		,@Exception INT=0
		,@ExceptionAmount money=0
		,@MatchedIds nvarchar(max)=''

	DECLARE @MatchedTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Matched')
		,@UnMatchedTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'UnMatched')
		,@PostededTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Posted')
		,@CancelledTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Cancelled')
		,@ExceptionTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Exception')

	-- Build table of selected items
	CREATE TABLE #SelectedTemporaryCC 
	(	
		ID INT IDENTITY(1,1),
		TemporaryCreditCardID INT
	)

	INSERT INTO #SelectedTemporaryCC
	SELECT tcc.ID
	FROM TemporaryCreditCard tcc WITH (NOLOCK)
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @tempccIdXML.nodes('/Tempcc/ID') T(c)
			) T ON tcc.ID = T.ID

	CREATE CLUSTERED INDEX IDX_SelectedTemporaryCC ON #SelectedTemporaryCC(TemporaryCreditCardID)

		
	/**************************************************************************************************/
	-- Update (Reset) Selected items to Unmatched where status is not Posted
	UPDATE tc SET 
		TemporaryCreditCardStatusID = @UnmatchedTemporaryCreditCardStatusID
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = NULL
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	WHERE tcs.Name <> 'Posted'


	/**************************************************************************************************/
	--Update for Exact match on PO# and CC#
	--Conditions:
	--	PO# AND CC# match exactly
	--	PO Status is Issued or Issued Paid
	--	PO has not been deleted
	--	PO does not already have a related Vendor Invoice
	--	Temporary CC has not already been posted
	--Match Status
	--	Total CC charge amount LESS THAN or EQUAL to the PO amount
	--Exception Status
	--	Total CC charge amount GREATER THAN the PO amount
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE
				 --Cancelled 
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Cancelled%') 
						AND vi.ID IS NULL 
						AND (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
						AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN @CancelledTemporaryCreditCardStatusID
				 --Matched
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
                        AND (ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount
                              OR ISNULL(tc.IsExceptionOverride,0) = 1)
					THEN @MatchedTemporaryCreditCardStatusID
				 --Cancelled	
				 WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN @CancelledTemporaryCreditCardStatusID
				 --Exception
				 ELSE @ExceptionTemporaryCreditCardStatusID
				 END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				 --Cancelled 
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Cancelled%') 
						AND vi.ID IS NULL 
						AND (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
						AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN NULL
				 --Matched
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
                        AND (ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount
                              OR ISNULL(tc.IsExceptionOverride,0) = 1)
					THEN NULL
				 --Exception: Charge more than PO Amount
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > po.PurchaseOrderAmount 
					THEN 'Charge amount exceeds PO amount'
				 --Cancelled	
				 WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN NULL
				 -- Other Exceptions	
				 WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 ELSE NULL
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = RIGHT(tc.CreditCardNumber,5)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID
	WHERE 1=1
	AND tcs.Name = 'Unmatched'
		
		
		
	/**************************************************************************************************/
	-- Update For No matches on PO# or CC#
	-- Conditions:
	--	No potential PO matches exist
	--  No potential CC# matches exist
	-- Cancelled Status
	--	Temporary Credit Card Issue Status is Cancelled
	-- Exception Status
	--	Temporary Credit Card Issue Status is NOT Cancelled
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE 
				WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN @CancelledTemporaryCreditCardStatusID
				ELSE @ExceptionTemporaryCreditCardStatusID
				END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN NULL
				ELSE 'No matching PO# or CC#'
				END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	WHERE  1=1
	AND tcs.Name = 'Unmatched'
	AND NOT EXISTS (
		SELECT *
		FROM PurchaseOrder po
		WHERE
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		)
	AND NOT EXISTS (
		SELECT *
		FROM PurchaseOrder po
		WHERE  
		po.PurchaseOrderNumber <> LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND po.CompanyCreditCardNumber IS NOT NULL
		AND RIGHT(RTRIM(po.CompanyCreditCardNumber),5) = RIGHT(tc.CreditCardNumber,5)
		)


	/**************************************************************************************************/
	--Update to Exception Status - PO matches and CC# does not match
	-- Conditions
	--	PO# matches exactly
	--	CC# does not match or is blank
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE
				WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN @CancelledTemporaryCreditCardStatusID
				WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN @CancelledTemporaryCreditCardStatusID
				ELSE @ExceptionTemporaryCreditCardStatusID
				END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				 --Cancelled	
				 WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN NULL
				 WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN NULL
				 --Exceptions
				 WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 WHEN RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = '' THEN 'Matching PO does not have a credit card number'
				 ELSE 'CC# Mismatch'
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND	RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) <> RIGHT(tc.CreditCardNumber,5)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID
	where tcs.Name = 'Unmatched'


	/**************************************************************************************************/
	--Update to Exception Status - PO does not match and CC# matches
	-- Conditions
	--	PO# does not match
	--	CC# matches exactly
	UPDATE tc SET
		TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 ELSE 'PO# Mismatch'
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber <> LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND	RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = RIGHT(tc.CreditCardNumber,5)
		AND po.CreateDate >= DATEADD(dd,1,tc.IssueDate)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID
	where tcs.Name = 'Unmatched'


	/**************************************************************************************************/
	-- Prepare Results
	SELECT 
		@Matched = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @MatchedTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@MatchedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @MatchedTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Unmatched = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @UnMatchedTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@UnmatchedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @UnMatchedTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Posted = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @PostededTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@PostedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @PostededTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Cancelled = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @CancelledTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@CancelledAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @CancelledTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Exception = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@ExceptionAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID

	-- Build string of 'Matched' IDs
	SELECT @MatchedIds = @MatchedIds + CONVERT(varchar(20),tc.ID) + ',' 
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	WHERE tc.TemporaryCreditCardStatusID = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Matched')

	-- Remove ending comma from string or IDs
	IF LEN(@MatchedIds) > 1 
		SET @MatchedIds = LEFT(@MatchedIds, LEN(@MatchedIds) - 1)

	DROP TABLE #SelectedTemporaryCC
	
	SELECT @Matched 'MatchedCount',
		   @MatchedAmount 'MatchedAmount',
		   --@Unmatched 'UnmatchedCount',
		   --@UnmatchedAmount 'UnmatchedAmount',
		   @Posted 'PostedCount',
		   @PostedAmount 'PostedAmount',
		   @Cancelled 'CancelledCount',
		   @CancelledAmount 'CancelledAmount',
		   @Exception 'ExceptionCount',
		   @ExceptionAmount 'ExceptionAmount',
		   @MatchedIds 'MatchedIds'
END


GO
