
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
   -- Ignore time while comparing dates here
    -- KB: Considering Effective and Expiration Dates to calculate member status
	, CASE 
		WHEN	ISNULL(m.EffectiveDate,@minDate) <= @now AND ISNULL(m.ExpirationDate,@minDate) >= @now
		THEN	'Active'
		ELSE	'Inactive'
		END	AS Member_Status     
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
 UPDATE @Hold SET DataType = 'LabelTheme' WHERE CHARINDEX('Member_Status',ColumnName) > 0 OR CHARINDEX('Vehicle_IsEligible',ColumnName) > 0  
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
 WHERE id = object_id(N'[dbo].[dms_ProgramManagement_ProgramServiceEventLimit_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ProgramManagement_ProgramServiceEventLimit_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_ProgramManagement_ProgramServiceEventLimit_List_Get
 CREATE PROCEDURE [dbo].[dms_ProgramManagement_ProgramServiceEventLimit_List_Get]( 
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
IDOperator="-1" 
ProgramOperator="-1" 
ProductCategoryOperator="-1" 
ProductOperator="-1" 
VehicleTypeOperator="-1" 
VehicleCategoryOperator="-1" 
PSELDescriptionOperator="-1" 
LimitOperator="-1" 
LimitDurationOperator="-1" 
LimitDurationUOMOperator="-1" 
StoredProcedureNameOperator="-1" 
IsActiveOperator="-1" 
CreateByOperator="-1" 
CreateDateOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
ProgramOperator INT NOT NULL,
ProgramValue nvarchar(100) NULL,
ProductCategoryOperator INT NOT NULL,
ProductCategoryValue nvarchar(100) NULL,
ProductOperator INT NOT NULL,
ProductValue nvarchar(100) NULL,
VehicleTypeOperator INT NOT NULL,
VehicleTypeValue nvarchar(100) NULL,
VehicleCategoryOperator INT NOT NULL,
VehicleCategoryValue nvarchar(100) NULL,
PSELDescriptionOperator INT NOT NULL,
PSELDescriptionValue nvarchar(100) NULL,
LimitOperator INT NOT NULL,
LimitValue int NULL,
LimitDurationOperator INT NOT NULL,
LimitDurationValue int NULL,
LimitDurationUOMOperator INT NOT NULL,
LimitDurationUOMValue nvarchar(100) NULL,
StoredProcedureNameOperator INT NOT NULL,
StoredProcedureNameValue nvarchar(100) NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue bit NULL,
CreateByOperator INT NOT NULL,
CreateByValue nvarchar(100) NULL,
CreateDateOperator INT NOT NULL,
CreateDateValue datetime NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	Program nvarchar(100)  NULL ,
	ProductCategory nvarchar(100)  NULL ,
	Product nvarchar(100)  NULL ,
	VehicleType nvarchar(100)  NULL ,
	VehicleCategory nvarchar(100)  NULL ,
	PSELDescription nvarchar(100)  NULL ,
	Limit int  NULL ,
	LimitDuration int  NULL ,
	LimitDurationUOM nvarchar(100)  NULL ,
	StoredProcedureName nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	CreateBy nvarchar(100)  NULL ,
	CreateDate datetime  NULL 
) 

 CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	Program nvarchar(100)  NULL ,
	ProductCategory nvarchar(100)  NULL ,
	Product nvarchar(100)  NULL ,
	VehicleType nvarchar(100)  NULL ,
	VehicleCategory nvarchar(100)  NULL ,
	PSELDescription nvarchar(100)  NULL ,
	Limit int  NULL ,
	LimitDuration int  NULL ,
	LimitDurationUOM nvarchar(100)  NULL ,
	StoredProcedureName nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	CreateBy nvarchar(100)  NULL ,
	CreateDate datetime  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@ProgramOperator','INT'),-1),
	T.c.value('@ProgramValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProductCategoryOperator','INT'),-1),
	T.c.value('@ProductCategoryValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProductOperator','INT'),-1),
	T.c.value('@ProductValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleTypeOperator','INT'),-1),
	T.c.value('@VehicleTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleCategoryOperator','INT'),-1),
	T.c.value('@VehicleCategoryValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PSELDescriptionOperator','INT'),-1),
	T.c.value('@PSELDescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@LimitOperator','INT'),-1),
	T.c.value('@LimitValue','int') ,
	ISNULL(T.c.value('@LimitDurationOperator','INT'),-1),
	T.c.value('@LimitDurationValue','int') ,
	ISNULL(T.c.value('@LimitDurationUOMOperator','INT'),-1),
	T.c.value('@LimitDurationUOMValue','nvarchar(100)') ,
	ISNULL(T.c.value('@StoredProcedureNameOperator','INT'),-1),
	T.c.value('@StoredProcedureNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@IsActiveOperator','INT'),-1),
	T.c.value('@IsActiveValue','bit') ,
	ISNULL(T.c.value('@CreateByOperator','INT'),-1),
	T.c.value('@CreateByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CreateDateOperator','INT'),-1),
	T.c.value('@CreateDateValue','datetime') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
Select 
	  PSEL.ID
	, P.[Description] AS Program
	, PC.[Description] AS ProductCategory
	, PD.Name AS Product
	, VT.Name AS VehicleType
	, VC.Name AS VehicleCategory
	, PSEL.Description AS PSELDescription
	, PSEL.Limit AS Limit
	, PSEL.LimitDuration
	, PSEL.LimitDurationUOM
	, PSEL.StoredProcedureName
	, PSEL.IsActive
	, PSEL.CreateBy
	, PSEL.CreateDate
FROM ProgramServiceEventLimit PSEL
LEFT JOIN Program P (NOLOCK) ON PSEL.ProgramID = P.ID
LEFT JOIN ProductCategory PC (NOLOCK) ON PSEL.ProductCategoryID = PC.ID
LEFT JOIN Product PD (NOLOCK) ON PSEL.ProductID = PD.ID
LEFT JOIN VehicleType VT (NOLOCK) ON PSEL.VehicleTypeID = VT.ID
LEFT JOIN VehicleCategory VC (NOLOCK) ON PSEL.VehicleCategoryID = VC.ID
WHERE P.ID = @programID


INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.Program,
	T.ProductCategory,
	T.Product,
	T.VehicleType,
	T.VehicleCategory,
	T.PSELDescription,
	T.Limit,
	T.LimitDuration,
	T.LimitDurationUOM,
	T.StoredProcedureName,
	T.IsActive,
	T.CreateBy,
	T.CreateDate
FROM #tmpFinalResults T,
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
	 ( TMP.ProgramOperator = -1 ) 
 OR 
	 ( TMP.ProgramOperator = 0 AND T.Program IS NULL ) 
 OR 
	 ( TMP.ProgramOperator = 1 AND T.Program IS NOT NULL ) 
 OR 
	 ( TMP.ProgramOperator = 2 AND T.Program = TMP.ProgramValue ) 
 OR 
	 ( TMP.ProgramOperator = 3 AND T.Program <> TMP.ProgramValue ) 
 OR 
	 ( TMP.ProgramOperator = 4 AND T.Program LIKE TMP.ProgramValue + '%') 
 OR 
	 ( TMP.ProgramOperator = 5 AND T.Program LIKE '%' + TMP.ProgramValue ) 
 OR 
	 ( TMP.ProgramOperator = 6 AND T.Program LIKE '%' + TMP.ProgramValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProductCategoryOperator = -1 ) 
 OR 
	 ( TMP.ProductCategoryOperator = 0 AND T.ProductCategory IS NULL ) 
 OR 
	 ( TMP.ProductCategoryOperator = 1 AND T.ProductCategory IS NOT NULL ) 
 OR 
	 ( TMP.ProductCategoryOperator = 2 AND T.ProductCategory = TMP.ProductCategoryValue ) 
 OR 
	 ( TMP.ProductCategoryOperator = 3 AND T.ProductCategory <> TMP.ProductCategoryValue ) 
 OR 
	 ( TMP.ProductCategoryOperator = 4 AND T.ProductCategory LIKE TMP.ProductCategoryValue + '%') 
 OR 
	 ( TMP.ProductCategoryOperator = 5 AND T.ProductCategory LIKE '%' + TMP.ProductCategoryValue ) 
 OR 
	 ( TMP.ProductCategoryOperator = 6 AND T.ProductCategory LIKE '%' + TMP.ProductCategoryValue + '%' ) 
 ) 

 AND 

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
	 ( TMP.VehicleTypeOperator = -1 ) 
 OR 
	 ( TMP.VehicleTypeOperator = 0 AND T.VehicleType IS NULL ) 
 OR 
	 ( TMP.VehicleTypeOperator = 1 AND T.VehicleType IS NOT NULL ) 
 OR 
	 ( TMP.VehicleTypeOperator = 2 AND T.VehicleType = TMP.VehicleTypeValue ) 
 OR 
	 ( TMP.VehicleTypeOperator = 3 AND T.VehicleType <> TMP.VehicleTypeValue ) 
 OR 
	 ( TMP.VehicleTypeOperator = 4 AND T.VehicleType LIKE TMP.VehicleTypeValue + '%') 
 OR 
	 ( TMP.VehicleTypeOperator = 5 AND T.VehicleType LIKE '%' + TMP.VehicleTypeValue ) 
 OR 
	 ( TMP.VehicleTypeOperator = 6 AND T.VehicleType LIKE '%' + TMP.VehicleTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VehicleCategoryOperator = -1 ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 0 AND T.VehicleCategory IS NULL ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 1 AND T.VehicleCategory IS NOT NULL ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 2 AND T.VehicleCategory = TMP.VehicleCategoryValue ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 3 AND T.VehicleCategory <> TMP.VehicleCategoryValue ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 4 AND T.VehicleCategory LIKE TMP.VehicleCategoryValue + '%') 
 OR 
	 ( TMP.VehicleCategoryOperator = 5 AND T.VehicleCategory LIKE '%' + TMP.VehicleCategoryValue ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 6 AND T.VehicleCategory LIKE '%' + TMP.VehicleCategoryValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PSELDescriptionOperator = -1 ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 0 AND T.PSELDescription IS NULL ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 1 AND T.PSELDescription IS NOT NULL ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 2 AND T.PSELDescription = TMP.PSELDescriptionValue ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 3 AND T.PSELDescription <> TMP.PSELDescriptionValue ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 4 AND T.PSELDescription LIKE TMP.PSELDescriptionValue + '%') 
 OR 
	 ( TMP.PSELDescriptionOperator = 5 AND T.PSELDescription LIKE '%' + TMP.PSELDescriptionValue ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 6 AND T.PSELDescription LIKE '%' + TMP.PSELDescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LimitOperator = -1 ) 
 OR 
	 ( TMP.LimitOperator = 0 AND T.Limit IS NULL ) 
 OR 
	 ( TMP.LimitOperator = 1 AND T.Limit IS NOT NULL ) 
 OR 
	 ( TMP.LimitOperator = 2 AND T.Limit = TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 3 AND T.Limit <> TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 7 AND T.Limit > TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 8 AND T.Limit >= TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 9 AND T.Limit < TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 10 AND T.Limit <= TMP.LimitValue ) 

 ) 

 AND 

 ( 
	 ( TMP.LimitDurationOperator = -1 ) 
 OR 
	 ( TMP.LimitDurationOperator = 0 AND T.LimitDuration IS NULL ) 
 OR 
	 ( TMP.LimitDurationOperator = 1 AND T.LimitDuration IS NOT NULL ) 
 OR 
	 ( TMP.LimitDurationOperator = 2 AND T.LimitDuration = TMP.LimitDurationValue ) 
 OR 
	 ( TMP.LimitDurationOperator = 3 AND T.LimitDuration <> TMP.LimitDurationValue ) 
 OR 
	 ( TMP.LimitDurationOperator = 7 AND T.LimitDuration > TMP.LimitDurationValue ) 
 OR 
	 ( TMP.LimitDurationOperator = 8 AND T.LimitDuration >= TMP.LimitDurationValue ) 
 OR 
	 ( TMP.LimitDurationOperator = 9 AND T.LimitDuration < TMP.LimitDurationValue ) 
 OR 
	 ( TMP.LimitDurationOperator = 10 AND T.LimitDuration <= TMP.LimitDurationValue ) 

 ) 

 AND 

 ( 
	 ( TMP.LimitDurationUOMOperator = -1 ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 0 AND T.LimitDurationUOM IS NULL ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 1 AND T.LimitDurationUOM IS NOT NULL ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 2 AND T.LimitDurationUOM = TMP.LimitDurationUOMValue ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 3 AND T.LimitDurationUOM <> TMP.LimitDurationUOMValue ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 4 AND T.LimitDurationUOM LIKE TMP.LimitDurationUOMValue + '%') 
 OR 
	 ( TMP.LimitDurationUOMOperator = 5 AND T.LimitDurationUOM LIKE '%' + TMP.LimitDurationUOMValue ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 6 AND T.LimitDurationUOM LIKE '%' + TMP.LimitDurationUOMValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.StoredProcedureNameOperator = -1 ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 0 AND T.StoredProcedureName IS NULL ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 1 AND T.StoredProcedureName IS NOT NULL ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 2 AND T.StoredProcedureName = TMP.StoredProcedureNameValue ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 3 AND T.StoredProcedureName <> TMP.StoredProcedureNameValue ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 4 AND T.StoredProcedureName LIKE TMP.StoredProcedureNameValue + '%') 
 OR 
	 ( TMP.StoredProcedureNameOperator = 5 AND T.StoredProcedureName LIKE '%' + TMP.StoredProcedureNameValue ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 6 AND T.StoredProcedureName LIKE '%' + TMP.StoredProcedureNameValue + '%' ) 
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
	 ( TMP.CreateDateOperator = -1 ) 
 OR 
	 ( TMP.CreateDateOperator = 0 AND T.CreateDate IS NULL ) 
 OR 
	 ( TMP.CreateDateOperator = 1 AND T.CreateDate IS NOT NULL ) 
 OR 
	 ( TMP.CreateDateOperator = 2 AND T.CreateDate = TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 3 AND T.CreateDate <> TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 7 AND T.CreateDate > TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 8 AND T.CreateDate >= TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 9 AND T.CreateDate < TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 10 AND T.CreateDate <= TMP.CreateDateValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'
	 THEN T.Program END ASC, 
	 CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'
	 THEN T.Program END DESC ,

	 CASE WHEN @sortColumn = 'ProductCategory' AND @sortOrder = 'ASC'
	 THEN T.ProductCategory END ASC, 
	 CASE WHEN @sortColumn = 'ProductCategory' AND @sortOrder = 'DESC'
	 THEN T.ProductCategory END DESC ,

	 CASE WHEN @sortColumn = 'Product' AND @sortOrder = 'ASC'
	 THEN T.Product END ASC, 
	 CASE WHEN @sortColumn = 'Product' AND @sortOrder = 'DESC'
	 THEN T.Product END DESC ,

	 CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'ASC'
	 THEN T.VehicleType END ASC, 
	 CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'DESC'
	 THEN T.VehicleType END DESC ,

	 CASE WHEN @sortColumn = 'VehicleCategory' AND @sortOrder = 'ASC'
	 THEN T.VehicleCategory END ASC, 
	 CASE WHEN @sortColumn = 'VehicleCategory' AND @sortOrder = 'DESC'
	 THEN T.VehicleCategory END DESC ,

	 CASE WHEN @sortColumn = 'PSELDescription' AND @sortOrder = 'ASC'
	 THEN T.PSELDescription END ASC, 
	 CASE WHEN @sortColumn = 'PSELDescription' AND @sortOrder = 'DESC'
	 THEN T.PSELDescription END DESC ,

	 CASE WHEN @sortColumn = 'Limit' AND @sortOrder = 'ASC'
	 THEN T.Limit END ASC, 
	 CASE WHEN @sortColumn = 'Limit' AND @sortOrder = 'DESC'
	 THEN T.Limit END DESC ,

	 CASE WHEN @sortColumn = 'LimitDuration' AND @sortOrder = 'ASC'
	 THEN T.LimitDuration END ASC, 
	 CASE WHEN @sortColumn = 'LimitDuration' AND @sortOrder = 'DESC'
	 THEN T.LimitDuration END DESC ,

	 CASE WHEN @sortColumn = 'LimitDurationUOM' AND @sortOrder = 'ASC'
	 THEN T.LimitDurationUOM END ASC, 
	 CASE WHEN @sortColumn = 'LimitDurationUOM' AND @sortOrder = 'DESC'
	 THEN T.LimitDurationUOM END DESC ,

	 CASE WHEN @sortColumn = 'StoredProcedureName' AND @sortOrder = 'ASC'
	 THEN T.StoredProcedureName END ASC, 
	 CASE WHEN @sortColumn = 'StoredProcedureName' AND @sortOrder = 'DESC'
	 THEN T.StoredProcedureName END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC ,

	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
	 THEN T.CreateBy END ASC, 
	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
	 THEN T.CreateBy END DESC ,

	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'
	 THEN T.CreateDate END ASC, 
	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'
	 THEN T.CreateDate END DESC 


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
 WHERE id = object_id(N'[dbo].[dms_Program_Coverage_Information_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Coverage_Information_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_Program_Coverage_Information_List_Get @programID =100
 CREATE PROCEDURE [dbo].[dms_Program_Coverage_Information_List_Get]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID int = NULL 
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
NameOperator="-1" 
LimitOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
NameOperator INT NOT NULL,
NameValue nvarchar(50) NULL,
LimitOperator INT NOT NULL,
LimitValue nvarchar(50) NULL
)
DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Name nvarchar(50)  NULL ,
	Limit nvarchar(50)  NULL ,
	Vehicle nvarchar(50)  NULL 
) 

DECLARE @tmpFinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Name nvarchar(50)  NULL ,
	Limit nvarchar(50)  NULL ,
	Vehicle nvarchar(50)  NULL 
) 

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(NameOperator,-1),
	NameValue ,
	ISNULL(LimitOperator,-1),
	LimitValue 
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
NameOperator INT,
NameValue nvarchar(50) 
,LimitOperator INT,
LimitValue money 
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @tmpFinalResults
SELECT	pc.Name
, max(CASE
WHEN pp.ServiceCoverageLimit > 0 THEN '$' + CONVERT(NVARCHAR(10),CONVERT(NUMERIC(10),pp.ServiceCoverageLimit))
WHEN pp.ServiceCoverageLimit = 0 AND pp.IsServiceCoverageBestValue = 1 THEN 'Best Value'
WHEN pp.ServiceCoverageLimit = 0 AND pp.IsServiceCoverageBestValue = 0 THEN '$0'
WHEN pp.ServiceCoverageLimit >= 0 AND pp.IsReimbursementOnly = 1 THEN '$' + CONVERT(NVARCHAR(10),CONVERT(NUMERIC(10),pp.ServiceCoverageLimit)) + '-' + 'Reimbursement'
WHEN pp.ServiceCoverageLimit = 0 AND pp.IsReimbursementOnly = 0 THEN 'Assit Only'
ELSE ''
END) +
coalesce(max(CASE WHEN convert(nvarchar(3),pp.ServiceMileageLimit) > 0 THEN ' - ' + convert(nvarchar(3),pp.ServiceMileageLimit) + ' miles' ELSE '' END), '')
AS Limit
, max(CASE WHEN RIGHT(p.Name,2) = 'LD' THEN 'LD' ELSE '' END) +
coalesce('-' + max(CASE WHEN RIGHT(p.Name,2) = 'MD' THEN 'MD' END),'') +
coalesce('-'+max(CASE WHEN RIGHT(p.Name,2) = 'HD' THEN 'HD' END),'') AS Vehicle
FROM	ProgramProduct pp
JOIN	Product p (NOLOCK) ON p.id = pp.ProductID
JOIN	ProductCategory pc (NOLOCK) ON pc.id = p.productcategoryid
WHERE	pc.Name NOT IN ('Info','Repair','Billing')
AND	 pp.ProgramID = @ProgramID
GROUP BY pc.Name, pc.sequence
ORDER BY pc.Sequence
INSERT INTO @FinalResults
SELECT 
	T.Name,
	T.Limit,
	T.Vehicle
FROM @tmpFinalResults T,
@tmpForWhereClause TMP 
WHERE ( 

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
	 ( TMP.LimitOperator = -1 ) 
 OR 
	 ( TMP.LimitOperator = 0 AND T.Limit IS NULL ) 
 OR 
	 ( TMP.LimitOperator = 1 AND T.Limit IS NOT NULL ) 
 OR 
	 ( TMP.LimitOperator = 2 AND T.Limit = TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 3 AND T.Limit <> TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 7 AND T.Limit > TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 8 AND T.Limit >= TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 9 AND T.Limit < TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 10 AND T.Limit <= TMP.LimitValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Limit' AND @sortOrder = 'ASC'
	 THEN T.Limit END ASC, 
	 CASE WHEN @sortColumn = 'Limit' AND @sortOrder = 'DESC'
	 THEN T.Limit END DESC ,

	 CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'ASC'
	 THEN T.Vehicle END ASC, 
	 CASE WHEN @sortColumn = 'Vehicle' AND @sortOrder = 'DESC'
	 THEN T.Vehicle END DESC 


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
 WHERE id = object_id(N'[dbo].[dms_Program_Management_DeleteProgramServiceEventLimit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_DeleteProgramServiceEventLimit] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Program_Management_DeleteDataItem 19
 CREATE PROCEDURE [dbo].[dms_Program_Management_DeleteProgramServiceEventLimit]( 
 @id INT 
 )
 AS
 BEGIN
	DELETE FROM ProgramServiceEventLimit WHERE ID = @id
 END
 
GO
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
      @ServiceRequestID int
      ,@ProgramID int
      ,@ProductCategoryID int
      ,@ProductID int 
      ,@VehicleTypeID int
      ,@VehicleCategoryID int 
      ,@SecondaryCategoryID INT = NULL
AS
BEGIN

	----Debug
	--DECLARE 
	--      @ServiceRequestID int = 7779982
	--      ,@ProgramID int = 3
	--      ,@ProductCategoryID int = 1
	--      ,@ProductID int = NULL
	--      ,@VehicleTypeID int = 1
	--      ,@VehicleCategoryID int = 1
	--      ,@SecondaryCategoryID INT = 1

	SET NOCOUNT ON  
	SET FMTONLY OFF  

	DECLARE @MemberID INT
		,@ProgramServiceEventLimitID int
		,@ProgramServiceEventLimitStoredProcedureName nvarchar(255)
		,@ProgramServiceEventLimitDescription nvarchar(255)
		,@MemberExpirationDate datetime
		,@MemberRenewalDate datetime

	SELECT @MemberID = m.ID
	  ,@MemberExpirationDate = m.ExpirationDate
	  ,@ProgramID = CASE WHEN @ProgramID IS NULL THEN m.ProgramID ELSE  @ProgramID END
	FROM ServiceRequest SR 
	JOIN [Case] c on c.id = SR.CaseID
	JOIN Member m on m.ID = c.MemberID
	WHERE SR.ID = @ServiceRequestID
	
	-- Determine last annual renewal date 
	SET @MemberRenewalDate = DATEADD(yy, (ROUND(DATEDIFF(dd, getdate(), @MemberExpirationDate)/365.00,0,1) + 1)*-1, @MemberExpirationDate)
	  
	If @ProductID IS NOT NULL
		SELECT @ProductCategoryID = ProductCategoryID
			  ,@VehicleCategoryID = VehicleCategoryID
			  ,@VehicleTypeID = VehicleTypeID
		FROM Product 
		WHERE ID = @ProductID

	-- Check for a custom stored procedure that verifies the event limits for this program
	SELECT TOP 1 
		@ProgramServiceEventLimitID = ID
		,@ProgramServiceEventLimitStoredProcedureName = StoredProcedureName
		,@ProgramServiceEventLimitDescription = [Description]
	FROM ProgramServiceEventLimit
	WHERE ProgramID = @ProgramID
	AND StoredProcedureName IS NOT NULL
	AND IsActive = 1
	
	
	IF @ProgramServiceEventLimitStoredProcedureName IS NOT NULL
		-- Custome stored procedure used to verify the event limits for the program
		BEGIN
		
		DECLARE @LimitEligibilityResults TABLE (
			ID int
			,ProgramID int
			,[Description] nvarchar(255)
			,Limit int
			,EventCount int
			,IsPrimary int
			,IsEligible int)
		
		INSERT INTO @LimitEligibilityResults	
		EXECUTE @ProgramServiceEventLimitStoredProcedureName 
		   @ServiceRequestID
		  ,@ProgramID
		  ,@ProductCategoryID
		  ,@ProductID
		  ,@VehicleTypeID
		  ,@VehicleCategoryID
		  ,@SecondaryCategoryID

		SELECT 
			@ProgramServiceEventLimitID ID
			,@ProgramID ProgramID
			,@ProgramServiceEventLimitDescription [Description]
			,Limit
			,EventCount
			,IsPrimary
			,IsEligible
		FROM @LimitEligibilityResults
			
		END
	
	ELSE
		-- Event limits are configured for specific program products
		BEGIN
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
							CASE WHEN ppl.IsLimitDurationSinceMemberRenewal = 1
									AND @MemberRenewalDate > (
										CASE WHEN ppl.LimitDurationUOM = 'Day' THEN DATEADD(dd,-ppl.LimitDuration, getdate())
											 WHEN ppl.LimitDurationUOM = 'Month' THEN DATEADD(mm,-ppl.LimitDuration, getdate())
											 WHEN ppl.LimitDurationUOM = 'Year' THEN DATEADD(yy,-ppl.LimitDuration, getdate())
											 ELSE NULL
											 END
										) THEN @MemberRenewalDate
  								 WHEN ppl.LimitDurationUOM = 'Day' THEN DATEADD(dd,-ppl.LimitDuration, getdate())
								 WHEN ppl.LimitDurationUOM = 'Month' THEN DATEADD(mm,-ppl.LimitDuration, getdate())
								 WHEN ppl.LimitDurationUOM = 'Year' THEN DATEADD(yy,-ppl.LimitDuration, getdate())
								 ELSE NULL
							END 
				Where 
					  c.MemberID = @MemberID
					  and c.ProgramID = @ProgramID
					  and po.IssueDate IS NOT NULL
					  and sr.ID <> @ServiceRequestID
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
			Where psel.IsActive = 1
			AND psel.ProgramID = @ProgramID
			AND   (
					  (@ProductID IS NOT NULL 
							AND psel.ProductID = @ProductID)
					  OR
					  (@ProductID IS NULL 
							AND (psel.ProductCategoryID = @ProductCategoryID OR psel.ProductCategoryID IS NULL) 
							AND (@VehicleCategoryID IS NULL OR psel.VehicleCategoryID IS NULL OR psel.VehicleCategoryID = @VehicleCategoryID)
							AND (@VehicleTypeID IS NULL OR psel.VehicleTypeID IS NULL OR psel.VehicleTypeID = @VehicleTypeID)
					  )
					  OR
					  (psel.ProductCategoryID = @SecondaryCategoryID AND @ProductCategoryID <> @SecondaryCategoryID
							AND (@VehicleCategoryID IS NULL OR psel.VehicleCategoryID IS NULL OR psel.VehicleCategoryID = @VehicleCategoryID)
							AND (@VehicleTypeID IS NULL OR psel.VehicleTypeID IS NULL OR psel.VehicleTypeID = @VehicleTypeID)
					  ))
			ORDER BY 
				(CASE WHEN ISNULL(pec.EventCount, 0) < psel.Limit THEN 1 ELSE 0 END) ASC
				,(CASE WHEN psel.ProductCategoryID = @SecondaryCategoryID THEN 0 ELSE 1 END) DESC
				,psel.ProductID DESC

			Drop table #tmpProgramEventCount
		END

END
GO
