IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Call_Summary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Call_Summary]
GO

--EXEC dms_Call_Summary @serviceRequestID = 1429  
CREATE PROC dms_Call_Summary(@serviceRequestID INT = NULL)  
AS  
BEGIN  
      DECLARE @Hold TABLE(ColumnName NVARCHAR(MAX),ColumnValue NVARCHAR(MAX),DataType NVARCHAR(MAX),Sequence INT,GroupName NVARCHAR(MAX),DefaultRows INT NULL)    
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
      SELECT      TOP 1 AE.Line1, 
                              AE.Line2, 
                              AE.Line3, 
                              AE.City, 
                              AE.StateProvince, 
                              AE.CountryCode, 
                              AE.PostalCode,
                              cl.TalkedTo,
                              cl.PhoneNumber,
                              V.Name As VendorName
            FROM  ContactLogLink cll
            JOIN  ContactLog cl on cl.ID = cll.ContactLogID
            JOIN  ContactLogLink cll2 on cll2.contactlogid = cl.id and cll2.entityid = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest') and cll2.RecordID = @serviceRequestID
            JOIN  VendorLocation VL ON cll.RecordID = VL.ID
            JOIN  Vendor V ON VL.VendorID = V.ID      
            JOIN  AddressEntity AE ON AE.RecordID = VL.ID AND AE.EntityID = (SELECT ID FROM Entity WHERE name = 'VendorLocation')
            WHERE cll.entityid = (SELECT ID FROM Entity WHERE name = 'VendorLocation')
            AND         cl.ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ServiceLocationSelection')
            ORDER BY cll.id DESC
      

  
      SET @XmlDocument = (SELECT DISTINCT    

-- PROGRAM SECTION
--    1 AS Program_DefaultNumberOfRows   
      cl.Name + ' - ' + p.name as Program_ClientProgramName    

-- MEMBER SECTION
--    , 5 AS Member_DefaultNumberOfRows
-- KB : 6/7 : TFS # 1339 : Presenting Case.Contactfirstname and Case.ContactLastName as member name and the values from member as company_name when the values differ.      
      , COALESCE(c.ContactFirstName,'') + COALESCE(' ' + c.ContactLastName,'') AS Member_Name
      , CASE
            WHEN  c.ContactFirstName <> m.Firstname
            AND         c.ContactLastName <> m.LastName
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
            WHEN  ISNULL(m.EffectiveDate,@minDate) <= @now AND ISNULL(m.ExpirationDate,@minDate) >= @now
            THEN  'Active'
            ELSE  'Inactive'
            END   AS Member_Status       
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
-- VEHICLE SECTION
--    , 3 AS Vehicle_DefalutNumberOfRows
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
--    , 2 AS Service_DefaultNumberOfRows  
      , ISNULL(
            COALESCE(pc.Name, '') + 
            COALESCE('/' + CASE WHEN sr.IsPossibleTow = 1 THEN 'Possible Tow' END, '')
            ,' ') as Service_ProductCategoryTow    
      , '$' + CONVERT(NVARCHAR(50),ISNULL(sr.CoverageLimit,0)) as Service_CoverageLimit  

-- LOCATION SECTION     
--    , 2 AS Location_DefaultNumberOfRows
      , ISNULL(sr.ServiceLocationAddress,' ') as Location_Address    
      , ISNULL(sr.ServiceLocationDescription,' ') as Location_Description  

-- DESTINATION SECTION     
--    , 2 AS Destination_DefaultNumberOfRows
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
--    , 3 AS ISP_DefaultNumberOfRows
      ,CASE 
            WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NOT NULL THEN 'Contracted'
            WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NULL THEN 'Not Contracted'
            WHEN vc.ID IS NOT NULL THEN 'Contracted' 
            ELSE 'Not Contracted'
            END as ISP_Contracted
      , ISNULL(v.Name,' ') as ISP_VendorName    
      , ISNULL(v.VendorNumber, ' ') AS ISP_VendorNumber
      , ISNULL(peISP.PhoneNumber,' ') as ISP_DispatchPhoneNumber 
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
--    , ISNULL(pos.Name, ' ' ) AS ISP_POStatus
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
--    , 2 AS SR_DefaultNumberOfRows
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
      --    SUBSTRING(CONVERT(VARCHAR(20), sr.CreateDate, 9), 13, 8) + ' ' +  
      --    SUBSTRING(CONVERT(VARCHAR(30), sr.CreateDate, 9), 25, 2) AS SR_CreateDate
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

      FROM        ServiceRequest sr      
      JOIN        [Case] c on c.ID = sr.CaseID    
      LEFT JOIN   PhoneType ptContact on ptContact.ID = c.ContactPhoneTypeID    
      JOIN        Program p on p.ID = c.ProgramID    
      JOIN        Client cl on cl.ID = p.ClientID    
      JOIN        Member m on m.ID = c.MemberID    
      JOIN        Membership ms on ms.ID = m.MembershipID    
      LEFT JOIN   AddressEntity ae ON ae.EntityID = (select ID from Entity where Name = 'Membership')    
      AND               ae.RecordID = ms.ID    
      AND               ae.AddressTypeID = (select ID from AddressType where Name = 'Home')   
      AND		  ae.ID = (SELECT MAX(aef.ID) FROM AddressEntity aef WHERE aef.RecordID = ms.ID)
      LEFT JOIN   Country country on country.ID = ae.CountryID     
      LEFT JOIN   PhoneEntity peMbr ON peMbr.EntityID = (select ID from Entity where Name = 'Membership')     
      AND               peMbr.RecordID = ms.ID    
      AND               peMbr.PhoneTypeID = (select ID from PhoneType where Name = 'Home')    
      LEFT JOIN   PhoneType ptMbr on ptMbr.ID = peMbr.PhoneTypeID    
      LEFT JOIN   ProductCategory pc on pc.ID = sr.ProductCategoryID    
      LEFT JOIN   (  
                        SELECT TOP 1 *  
                        FROM PurchaseOrder wPO   
                        WHERE wPO.ServiceRequestID = @serviceRequestID  
                        AND wPO.IsActive = 1
                        AND wPO.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending')
                        ORDER BY wPO.IssueDate DESC  
                        ) po on po.ServiceRequestID = sr.ID  
      LEFT JOIN   PurchaseOrderStatus pos on pos.ID = po.PurchaseOrderStatusID  
      LEFT JOIN   VendorLocation vl on vl.ID = po.VendorLocationID    
      LEFT JOIN   Vendor v on v.ID = vl.VendorID 
      LEFT JOIN   [Contract] vc on vc.VendorID = v.ID and vc.IsActive = 1 and vc.ContractStatusID = (Select ID From ContractStatus Where Name = 'Active')
      LEFT OUTER JOIN (
                        SELECT DISTINCT vr.VendorID, vr.ProductID
                        FROM dbo.fnGetCurrentProductRatesByVendorLocation() vr 
                        ) DefaultVendorRates ON v.ID = DefaultVendorRates.VendorID And @ProductID = DefaultVendorRates.ProductID      
      LEFT JOIN   PhoneEntity peISP on peISP.EntityID = (select ID from Entity where Name = 'VendorLocation')     
      AND               peISP.RecordID = vl.ID    
      AND               peISP.PhoneTypeID = (select ID from PhoneType where Name = 'Dispatch')    
      LEFT JOIN   PhoneType ptISP on ptISP.ID = peISP.PhoneTypeID    
      LEFT JOIN   AddressEntity aeISP ON aeISP.EntityID = (select ID from Entity where Name = 'VendorLocation')    
      AND               aeISP.RecordID = vl.ID    
      AND               aeISP.AddressTypeID = (select ID from AddressType where Name = 'Business')    
 -- CR # 524  
      LEFT JOIN   ServiceRequestStatus srs ON srs.ID=sr.ServiceRequestStatusID  
      LEFT JOIN   NextAction na ON na.ID=sr.NextActionID  
      LEFT JOIN   ClosedLoopStatus cls ON cls.ID=sr.ClosedLoopStatusID 
 -- End : CR # 524  
      LEFT JOIN   VendorLocation VLD ON VLD.ID = sr.DestinationVendorLocationID
      LEFT JOIN   PhoneEntity peDestination ON peDestination.RecordID = VLD.ID AND peDestination.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')  
      LEFT JOIN   NextAction NextAction on NextAction.ID = sr.NextActionID
      LEFT JOIN   [User] u on u.ID = sr.NextActionAssignedToUserID

      WHERE       sr.ID = @serviceRequestID    
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
 UPDATE @Hold SET DataType = 'LabelTheme' WHERE CHARINDEX('Member_Status',ColumnName) > 0    

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
   -- ContactPhoneNumber nvarchar NULL 
  
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
  
--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
INSERT INTO #FinalResultsFiltered
SELECT   
 T.CaseNumber,  
 T.ServiceRequestNumber,  
 T.CreateDate,  
 T.ServiceType,  
 T.[Status],  
 T.FirstName,  
 T.MiddleName,
 T.LastName,
 T.Suffix,
 T.VehicleYear,
 T.VehicleMake,
 T.VehicleMakeOther,
 T.VehicleModel,
 T.VehicleModelOther, 
 T.Vendor,  
 T.MembershipID,  
 T.POCount,
 T.ContactPhoneNumber
   
FROM (  
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
				  --'' AS ContactPhoneNumber
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
  
     ) T,  
@tmpForWhereClause TMP   
WHERE (   
 --(   
 -- ( TMP.CaseNumberOperator = -1 )   
 -- OR   
 -- ( TMP.CaseNumberOperator = 2 AND T.CaseNumber = TMP.CaseNumberValue )   
 --)     
 --AND   
 --(   
 -- ( TMP.ServiceRequestNumberOperator = -1 )    
 --OR   
 -- ( TMP.ServiceRequestNumberOperator = 2 AND T.ServiceRequestNumber = TMP.ServiceRequestNumberValue )  
 --)     
 --AND   
 --(   
 -- ( TMP.CreateDateOperator = -1 )   
 --OR   
 -- ( TMP.CreateDateOperator = 2 AND T.CreateDate = TMP.CreateDateValue )   
 --)     
 --AND   
 --(   
 -- ( TMP.ServiceTypeOperator = -1 )    
 --OR   
 -- ( TMP.ServiceTypeOperator = 2 AND T.ServiceType = TMP.ServiceTypeValue )    
 --)     
 --AND   
 --(   
 -- ( TMP.StatusOperator = -1 )    
 --OR   
 -- ( TMP.StatusOperator = 2 AND T.Status = TMP.StatusValue )    
 --)   
 --AND   
 --(   
 -- ( TMP.VendorOperator = -1 )   
 --OR   
 -- ( TMP.VendorOperator = 2 AND T.Vendor = TMP.VendorValue )    
 --) 
 --AND     
 (   
  ( TMP.MembershipIDOperator = -1 )    
 OR   
  ( TMP.MembershipIDOperator = 2 AND T.MembershipID = TMP.MembershipIDValue )  
 )    
 AND   
 1 = 1   
 )   
 
 
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
 FROM  #FinalResultsFormatted F,
		@tmpForWhereClause TMP
 --WHERE 
 --(	
 --(   
 -- ( TMP.MemberNameOperator = -1 )   
 --OR   
 -- ( TMP.MemberNameOperator = 2 AND F.MemberName = TMP.MemberNameValue )   
 --)   
 --AND 
 --(   
 -- ( TMP.VehicleOperator = -1 )   
 --OR   
 -- ( TMP.VehicleOperator = 2 AND F.Vehicle = TMP.VehicleValue )   
 --)  
 --AND   
 --(   
 -- ( TMP.POCountOperator = -1 )    
 --OR   
 -- ( TMP.POCountOperator = 2 AND F.POCount = TMP.POCountValue )   
 --)   
	 
 --AND 
	--(1=1)
 --)
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
 WHERE id = object_id(N'[dbo].[dms_PO_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_PO_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_PO_list] @serviceRequestID = 1414, @sortColumn='PurchaseOrderPayStatusCode', @sortOrder = 'ASC'
 CREATE PROCEDURE [dbo].[dms_PO_list]( 
  @serviceRequestID INT = NULL
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON
 	
 	CREATE TABLE #tmpPODetails 	
 	(
 		ID INT NULL,
 		PONumber NVARCHAR(50) NULL,
 		PODate DATETIME NULL,
 		VendorName NVARCHAR(255) NULL,
 		POTotal MONEY NULL,
 		[Service] NVARCHAR(200) NULL,
 		POStatus NVARCHAR(50) NULL,
 		CancelReason NVARCHAR(255) NULL,
 		DataTransferDate DATETIME NULL,
 		ModifyDate DATETIME NULL,
 		OriginalPONumber NVARCHAR(50) NULL 	,
 		
 		InvoiceNumber nvarchar(100)  NULL ,
		InvoiceDate datetime  NULL ,
		InvoiceAmount money  NULL ,
		InvoiceStatus nvarchar(100)  NULL ,
		PaymentNumber nvarchar(100)  NULL ,
		PaymentDate datetime  NULL ,
		PaymentAmount money  NULL ,
		CheckClearedDate datetime  NULL ,
		InvoiceReceivedDate datetime NULL ,
		InvoiceReceiveMethod nvarchar(100) NULL ,
		InvoiceToBePaidDate datetime NULL,
		PurchaseOrderPayStatusCode nvarchar(255) NULL 	
 	)
 	
 	SET FMTONLY OFF;
 	
	INSERT INTO #tmpPODetails
	SELECT	  po.ID as ID
			, po.PurchaseOrderNumber as PONumber
			, po.IssueDate as PODate
			, v.Name as VendorName
			, po.TotalServiceAmount as POTotal
			, pc.[Description] as [Service]
			, pos.Name as POStatus
			--, cr.[Description] as CancelReason
			, CASE	WHEN po.CancellationReasonOther <> '' THEN po.CancellationReasonOther  
					WHEN po.GOAReasonOther <> '' THEN po.GOAReasonOther   
					ELSE cr.[Description]  
				END as CancelReason
			, po.DataTransferDate
			, po.ModifyDate
			,poo.PurchaseOrderNumber as OriginalPONumber
			, VI.InvoiceNumber
			, VI.InvoiceDate
			, VI.InvoiceAmount
			, VIS.Name AS [InvoiceStatus]
			--, VI.PaymentNumber
			,CASE 
			WHEN VI.PaymentTypeID = (SELECT ID From PaymentType WHERE Name = 'ACH') 
			THEN 'ACH' 
			ELSE VI.PaymentNumber
			END AS PaymentNumber
			, VI.PaymentDate 
			, VI.PaymentAmount 
			, VI.CheckClearedDate
			, VI.ReceivedDate
			, CM.Name
			, VI.ToBePaidDate
			,pops.[Description]
	FROM	PurchaseOrder po WITH (NOLOCK)
	LEFT OUTER JOIN PurchaseOrder poo WITH (NOLOCK) on poo.ID=po.OriginalPurchaseOrderID
	JOIN VendorLocation vl WITH (NOLOCK) on vl.ID = po.VendorLocationID
	JOIN Vendor v WITH (NOLOCK) on v.ID = vl.VendorID
	--Join PurchaseOrderDetail pod on pod.PurchaseOrderID = po.ID 
	--and pod.Sequence = 1
	--LEFT OUTER Join Product p on p.ID = pod.ProductID 
	LEFT OUTER JOIN Product p WITH (NOLOCK) on p.ID = po.ProductID 
	LEFT OUTER JOIN ProductCategory pc WITH (NOLOCK) on pc.ID = p.ProductCategoryID
	JOIN PurchaseOrderStatus pos WITH (NOLOCK) on pos.ID = po.PurchaseOrderStatusID
	LEFT JOIN PurchaseOrderPayStatusCode pops WITH (NOLOCK) on pops.ID = po.PayStatusCodeID
	LEFT JOIN PurchaseOrderCancellationReason cr WITH (NOLOCK) on cr.ID = po.CancellationReasonID
	LEFT OUTER JOIN VendorInvoice VI ON VI.PurchaseOrderID = PO.ID 
	LEFT OUTER JOIN VendorInvoiceStatus VIS ON VIS.ID = VI.VendorInvoiceStatusID 	
	LEFT OUTER JOIN ContactMethod CM ON CM.ID=VI.ReceiveContactMethodID
	WHERE	po.ServiceRequestID = @serviceRequestID and (po.IsActive = 1 or po.IsActive IS NULL )

SELECT W.*
FROM #tmpPODetails W
 ORDER BY 
     CASE WHEN @sortColumn IS NULL
     THEN W.ID END DESC,
	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'
	 THEN W.PONumber END ASC, 
	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'
	 THEN W.PONumber END DESC ,

	 CASE WHEN @sortColumn = 'PODate' AND @sortOrder = 'ASC'
	 THEN W.PODate END ASC, 
	 CASE WHEN @sortColumn = 'PODate' AND @sortOrder = 'DESC'
	 THEN W.PODate END DESC ,

	 CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'ASC'
	 THEN W.VendorName  END ASC, 
	 CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'DESC'
	 THEN W.VendorName  END DESC ,

	 CASE WHEN @sortColumn = 'POTotal' AND @sortOrder = 'ASC'
	 THEN W.POTotal END ASC, 
	 CASE WHEN @sortColumn = 'POTotal' AND @sortOrder = 'DESC'
	 THEN W.POTotal END DESC ,

	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'ASC'
	 THEN W.[Service] END ASC, 
	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'DESC'
	 THEN W.[Service] END DESC ,

	 CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'ASC'
	 THEN W.POStatus END ASC, 
	 CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'DESC'
	 THEN W.POStatus END DESC ,

	 CASE WHEN @sortColumn = 'CancelReason' AND @sortOrder = 'ASC'
	 THEN W.CancelReason END ASC, 
	 CASE WHEN @sortColumn = 'CancelReason' AND @sortOrder = 'DESC'
	 THEN W.CancelReason END DESC ,
	 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN W.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN W.InvoiceNumber END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'ASC'
	 THEN W.InvoiceDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'DESC'
	 THEN W.InvoiceDate END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'
	 THEN W.InvoiceAmount END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'
	 THEN W.InvoiceAmount END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'ASC'
	 THEN W.InvoiceStatus END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'DESC'
	 THEN W.InvoiceStatus END DESC ,

	 CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'ASC'
	 THEN W.PaymentNumber END ASC, 
	 CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'DESC'
	 THEN W.PaymentNumber END DESC ,

	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'ASC'
	 THEN W.PaymentDate END ASC, 
	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'DESC'
	 THEN W.PaymentDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'
	 THEN W.PaymentAmount END ASC, 
	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'
	 THEN W.PaymentAmount END DESC ,

	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'ASC'
	 THEN W.CheckClearedDate END ASC, 
	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'DESC'
	 THEN W.CheckClearedDate END DESC  ,

	 CASE WHEN @sortColumn = 'InvoiceReceivedDate' AND @sortOrder = 'ASC'
	 THEN W.InvoiceReceivedDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceReceivedDate' AND @sortOrder = 'DESC'
	 THEN W.InvoiceReceivedDate END DESC,

	 CASE WHEN @sortColumn = 'InvoiceReceiveMethod' AND @sortOrder = 'ASC'
	 THEN W.InvoiceReceiveMethod END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceReceiveMethod' AND @sortOrder = 'DESC'
	 THEN W.InvoiceReceiveMethod END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceToBePaidDate' AND @sortOrder = 'ASC'
	 THEN W.InvoiceToBePaidDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceToBePaidDate' AND @sortOrder = 'DESC'
	 THEN W.InvoiceToBePaidDate END DESC, 
	 
	 CASE WHEN @sortColumn = 'PurchaseOrderPayStatusCode' AND @sortOrder = 'ASC'
	 THEN W.PurchaseOrderPayStatusCode END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderPayStatusCode' AND @sortOrder = 'DESC'
	 THEN W.PurchaseOrderPayStatusCode END DESC 
	 
	DROP TABLE #tmpPODetails	 

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
-- EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = '<ROW><Filter IDType="ServiceRequest" IDValue="1234" NameType="" NameValue="" LastName="" FilterType = "StartsWith" FromDate = "" ToDate = "" Preset ="" Clients ="1" Programs ="" ServiceRequestStatuses = "" ServiceTypes ="" IsGOA = "" IsRedispatched = "" IsPossibleTow ="" VehicleType ="1" VehicleYear ="2012" VehicleMake = "" VehicleModel = "" PaymentByCheque = "" PaymentByCard = "" MemberPaid ="" POStatuses =""/></ROW>', @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
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
	CREATE TABLE #Raw	
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
		PaymentByCard BIT NULL
	)
	
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
		PaymentByCard BIT NULL
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
	
	CREATE TABLE #tmpVehicle
	(
		VIN NVARCHAR(50) NULL,
		MemberID INT NULL,
		MembershipID INT NULL
	)
	
	DECLARE @totalRows INT = 0

	DECLARE @tmpWhereClause TABLE
	(	
		IDType NVARCHAR(255) NULL,
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
	
	DECLARE @IDType NVARCHAR(255) ,
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
	DECLARE @tmpClients TABLE
	(
		ID INT NOT NULL
	)	
	DECLARE @strPrograms NVARCHAR(MAX)
	DECLARE @tmpPrograms TABLE
	(
		ID INT NOT NULL
	)
	DECLARE @strServiceRequestStatuses NVARCHAR(MAX)
	DECLARE @tmpServiceRequestStatuses TABLE
	(
		ID INT NOT NULL
	)
	
	DECLARE @strServiceTypes NVARCHAR(MAX)
	DECLARE @tmpServiceTypes TABLE
	(
		ID INT NOT NULL
	)
	DECLARE @strPOStatuses NVARCHAR(MAX)
	DECLARE @tmpPOStatuses TABLE
	(
		ID INT NOT NULL
	)
	
	-- Extract some of the values into separate tables for ease of processing.
	SELECT	@strClients = Clients,
			@strPOStatuses = POStatuses,
			@strPrograms = Programs,
			@strServiceRequestStatuses = ServiceRequestStatuses,
			@strServiceTypes = ServiceTypes			
	FROM	@tmpWhereClause
	
	-- Clients
	INSERT INTO @tmpClients
	SELECT item FROM fnSplitString(@strClients,',')
	
	-- Programs
	INSERT INTO @tmpPrograms
	SELECT item FROM fnSplitString(@strPrograms,',')
	
	-- POStatuses
	INSERT INTO @tmpPOStatuses
	SELECT item FROM fnSplitString(@strPOStatuses,',')
	
	-- Service request statuses
	INSERT INTO @tmpServiceRequestStatuses
	SELECT item FROM fnSplitString(@strServiceRequestStatuses,',')
	
	-- Service types
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
	
	DECLARE @vinParam NVARCHAR(50) = NULL
	SELECT	@vinParam = IDValue 
	FROM	@tmpWhereClause
	WHERE	IDType = 'VIN'
	
	IF ISNULL(@vinParam,'') <> ''
	BEGIN
	
		INSERT INTO #tmpVehicle
		SELECT	V.VIN,
				V.MemberID,
				V.MembershipID
		FROM	Vehicle V WITH (NOLOCK)
		WHERE	V.VIN = @vinParam
		--V.VIN LIKE '%' + @vinParam + '%'
		
	END
	
	INSERT INTO #Filtered
	SELECT  
			--DISTINCT  
			SR.ID AS [RequestNumber],  
			SR.CaseID AS [Case],
			P.ProgramID,
			P.ProgramName AS [Program],
			CL.ID AS ClientID,
			CL.Name AS [Client], 			
			M.FirstName,
			M.LastName,
			M.MiddleName,
			M.Suffix,
			M.Prefix,   
			MS.MembershipNumber AS MemberNumber,  			
			SR.CreateDate,
			PO.CreateBy,
			PO.ModifyBy,
			SR.CreateBy,
			SR.ModifyBy,
			TV.VIN,
			VT.ID As VehicleTypeID,
			VT.Name AS VehicleType,						
			PC.ID AS [ServiceTypeID],
			PC.Name AS [ServiceType],			  
			SRS.ID AS [StatusID],
			CASE ISNULL(SR.IsRedispatched,0) WHEN 1 THEN SRS.Name + '^' ELSE SRS.Name END AS [Status],
			SR.ServiceRequestPriorityID AS [PriorityID],  
			SRP.Name AS [Priority],			
			V.Name AS [ISPName], 
			V.VendorNumber, 
			PO.PurchaseOrderNumber AS [PONumber], 
			POS.ID AS PurchaseOrderStatusID,
			POS.Name AS PurchaseOrderStatus,
			PO.PurchaseOrderAmount,			   
			C.AssignedToUserID,
			SR.NextActionAssignedToUserID,			
			PO.IsGOA,
			SR.IsRedispatched,
			SR.IsPossibleTow,
			C.VehicleYear,
			C.VehicleMake,
			C.VehicleMakeOther,
			C.VehicleModel,
			C.VehicleModelOther,
			PO.IsPayByCompanyCreditCard
			
	FROM	ServiceRequest SR WITH (NOLOCK)	
	--LEFT JOIN	@tmpWhereClause TMP ON 1=1	
	JOIN	[ServiceRequestStatus] SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID  
	LEFT JOIN	[ServiceRequestPriority] SRP WITH (NOLOCK) ON SR.ServiceRequestPriorityID = SRP.ID 
	JOIN	[Case] C WITH (NOLOCK) on C.ID = SR.CaseID
	JOIN	dbo.fnc_GetProgramsForUser(@userID) P ON C.ProgramID = P.ProgramID  
	
	JOIN	[Client] CL WITH (NOLOCK) ON P.ClientID = CL.ID
	JOIN	[Member] M WITH (NOLOCK) ON C.MemberID = M.ID  
	LEFT JOIN	Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID  
	LEFT JOIN [ProductCategory] PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID   
	LEFT JOIN [VehicleType] VT WITH (NOLOCK) ON VT.ID = C.VehicleTypeID
	LEFT JOIN (  
			SELECT ROW_NUMBER() OVER (PARTITION BY ServiceRequestID ORDER BY CreateDate DESC) AS RowNum,  
			ID,  
			PurchaseOrderNumber, 
			PurchaseOrderStatusID, 
			ServiceRequestID,  
			VendorLocationID,
			PurchaseOrderAmount,
			TPO.IsGOA,
			TPO.IsPayByCompanyCreditCard,
			TPO.CreateBy,
			TPO.ModifyBy			   
			FROM PurchaseOrder TPO WITH (NOLOCK)
			--LEFT JOIN	 @tmpWhereClause TMP   ON 1=1
			WHERE ( (@IDType IS NULL) OR (@IDType <> 'Purchase Order') OR (@IDType = 'Purchase Order' AND PurchaseOrderNumber = @IDValue))
	) PO ON SR.ID = PO.ServiceRequestID AND PO.RowNum = 1  
	
	LEFT JOIN	PurchaseOrderStatus POS WITH (NOLOCK) ON PO.PurchaseOrderStatusID = POS.ID
	LEFT JOIN	[NextAction] NA WITH (NOLOCK) ON SR.NextActionID=NA.ID 
	LEFT JOIN	[VendorLocation] VL WITH (NOLOCK) ON PO.VendorLocationID = VL.ID  
	LEFT JOIN	[Vendor] V WITH (NOLOCK) ON VL.VendorID = V.ID
	LEFT JOIN	#tmpVehicle TV ON (TV.MemberID IS NULL OR TV.MemberID = M.ID) 
	
	-- DEBUG:
	--SELECT * FROM @tmpWhereClause
	--SELECT * FROM #Raw
	
	-- Apply filter on the #Raw
	--INSERT INTO #Filtered 
	--		(
	--		RequestNumber,
	--		CaseID,
	--		ProgramID,
	--		Program,
	--		ClientID,
	--		Client,
	--		FirstName,
	--		LastName,
	--		MiddleName,
	--		Suffix,
	--		Prefix,
	--		MemberNumber,
	--		CreateDate,
	--		POCreateBy,
	--		POModifyBy,
	--		SRCreateBy,
	--		SRModifyBy,
	--		VIN,
	--		VehicleTypeID,
	--		VehicleType,
	--		ServiceTypeID,
	--		ServiceType,
	--		StatusID,
	--		[Status],
	--		PriorityID,
	--		[Priority],
	--		ISPName,
	--		VendorNumber,
	--		PONumber,
	--		PurchaseOrderStatusID,
	--		PurchaseOrderStatus,
	--		PurchaseOrderAmount,
	--		AssignedToUserID,
	--		NextActionAssignedToUserID,
	--		IsGOA,
	--		IsRedispatched,
	--		IsPossibleTow,
	--		VehicleYear,
	--		VehicleMake,
	--		VehicleMakeOther,
	--		VehicleModel,
	--		VehicleModelOther,
	--		PaymentByCard
	--		)
				
	--SELECT	RequestNumber,
	--		CaseID,
	--		ProgramID,
	--		Program,
	--		ClientID,
	--		Client,
	--		FirstName,
	--		R.LastName,
	--		MiddleName,
	--		Suffix,
	--		Prefix,
	--		MemberNumber,
	--		CreateDate,
	--		POCreateBy,
	--		POModifyBy,
	--		SRCreateBy,
	--		SRModifyBy,
	--		VIN,
	--		VehicleTypeID,
	--		R.VehicleType,
	--		ServiceTypeID, 
	--		ServiceType,		 
	--		StatusID,
	--		[Status],
	--		PriorityID,
	--		[Priority],
	--		ISPName,
	--		VendorNumber,
	--		PONumber,
	--		PurchaseOrderStatusID,
	--		PurchaseOrderStatus, 
	--		PurchaseOrderAmount,
	--		AssignedToUserID,
	--		NextActionAssignedToUserID,
	--		R.IsGOA,
	--		R.IsRedispatched,
	--		R.IsPossibleTow,
	--		R.VehicleYear,
	--		R.VehicleMake,
	--		R.VehicleMakeOther,
	--		R.VehicleModel,
	--		R.VehicleModelOther,
	--		R.PaymentByCard	
	--FROM	#Raw R
	--LEFT JOIN	@tmpWhereClause T ON 1=1
	WHERE	
	(
	
		-- IDs
		(
			(@IDType IS NULL)
			OR
			(@IDType = 'Purchase Order' AND PO.PurchaseOrderNumber = CONVERT(NVARCHAR(50),@IDValue))
			OR
			(@IDType = 'Service Request' AND @IDValue = CONVERT(NVARCHAR(50),SR.ID))
			OR
			(@IDType = 'ISP' AND V.VendorNumber =  CONVERT(NVARCHAR(50),@IDValue) )
			OR
			(@IDType = 'Member' AND MS.MembershipNumber = CONVERT(NVARCHAR(50),@IDValue))			 
			OR
			(@IDType = 'VIN' AND TV.VIN = CONVERT(NVARCHAR(50),@IDValue))
		)
	
		AND
		-- Names
		(
				(@FilterType IS NULL)
				OR
				(@FilterType = 'Is equal to' 
					AND (
							(@NameType = 'ISP' AND V.Name = @NameValue)
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName = @NameValue))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName = @LastName))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy = @NameValue 
																				OR 
																				SR.ModifyBy = @NameValue 
																				OR 
																				PO.CreateBy = @NameValue 
																				OR 
																				PO.ModifyBy = @NameValue 
																			)) )
											
											)
							)		
						)
				)
				OR
				(@FilterType = 'Starts with' 
					AND (
							(@NameType = 'ISP' AND V.Name LIKE  @NameValue + '%')
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName LIKE  @NameValue + '%'))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName LIKE  @LastName + '%'))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy LIKE  @NameValue + '%' 
																				OR 
																				SR.ModifyBy LIKE  @NameValue + '%'
																				OR 
																				PO.CreateBy LIKE  @NameValue + '%'
																				OR 
																				PO.ModifyBy LIKE  @NameValue + '%'
																			)) )
											
											)
							)		
						)
				)
				OR
				(@FilterType = 'Contains' 
					AND (
							(@NameType = 'ISP' AND V.Name LIKE  '%' + @NameValue + '%')
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName LIKE  '%' + @NameValue + '%'))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName LIKE  '%' + @LastName + '%'))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy LIKE  '%' + @NameValue + '%' 
																				OR 
																				SR.ModifyBy LIKE  '%' + @NameValue + '%' 
																				OR 
																				PO.CreateBy LIKE  '%' + @NameValue + '%' 
																				OR 
																				PO.ModifyBy LIKE  '%' + @NameValue + '%' 
																			)) )
											
											)
							)		
						)
				)
				OR
				(@FilterType = 'Ends with' 
					AND (
							(@NameType = 'ISP' AND V.Name LIKE  '%' + @NameValue)
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName LIKE  '%' + @NameValue))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName LIKE  '%' + @LastName))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy LIKE  '%' + @NameValue 
																				OR 
																				SR.ModifyBy LIKE  '%' + @NameValue 
																				OR 
																				PO.CreateBy LIKE  '%' + @NameValue 
																				OR 
																				PO.ModifyBy LIKE  '%' + @NameValue 
																			)) )
											
											)
							)		
						)
				)
			
		)
	
		AND
		-- Date Range
		(
				(@Preset IS NOT NULL AND	(
											(@Preset = 'Last 7 days' AND DATEDIFF(WK,SR.CreateDate,GETDATE()) <= 1)
											OR
											(@Preset = 'Last 30 days' AND DATEDIFF(M,SR.CreateDate,GETDATE()) <= 1)
											OR
											(@Preset = 'Last 90 days' AND DATEDIFF(M,SR.CreateDate,GETDATE()) <= 3)
											)
				)
				OR
				(
					(@Preset IS NULL AND	(	( @FromDate IS NULL OR (@FromDate IS NOT NULL AND SR.CreateDate >= @FromDate))
											AND
												( @ToDate IS NULL OR (@ToDate IS NOT NULL AND SR.CreateDate <= @ToDate))
											)
					)
				)
		)
		AND
		-- Clients
		(
				(	ISNULL(@strClients,'') = '' OR ( CL.ID IN (SELECT ID FROM @tmpClients) ))
		)
		AND
		-- Programs
		(
				(	ISNULL(@strPrograms,'') = '' OR ( P.ProgramID IN (SELECT ID FROM @tmpPrograms) ))
		)
		AND
		-- SR Statuses
		(
				(	ISNULL(@strServiceRequestStatuses,'') = '' OR ( SRS.ID IN (SELECT ID FROM @tmpServiceRequestStatuses) ))
		)
		AND
		-- Service types
		(
				(	ISNULL(@strServiceTypes,'') = '' OR ( PC.ID IN (SELECT ID FROM @tmpServiceTypes) ))
		)
		AND
		-- Special flags
		(
				( @IsGOA IS NULL OR (PO.IsGOA = @IsGOA))
				AND
				( @IsPossibleTow IS NULL OR (SR.IsPossibleTow = @IsPossibleTow))
				AND
				( @IsRedispatched IS NULL OR (SR.IsRedispatched = @IsRedispatched))
		)
		AND
		-- Vehicle
		(
				(@VehicleType IS NULL OR (C.VehicleTypeID = @VehicleType))
				AND
				(@VehicleYear IS NULL OR (C.VehicleYear = @VehicleYear))
				AND
				(@VehicleMake IS NULL OR ( (C.VehicleMake = @VehicleMake) OR (@VehicleMake = 'Other' AND C.VehicleMake = 'Other' AND C.VehicleMakeOther = @VehicleMakeOther ) ) )
				AND
				(@VehicleModel IS NULL OR ( (C.VehicleModel = @VehicleModel) OR (@VehicleModel = 'Other' AND C.VehicleModel = 'Other' AND C.VehicleModelOther = @VehicleModelOther) ) )
		)
		AND
		-- Payment Type
		(
				( @PaymentByCheque IS NULL OR ( @PaymentByCheque = 1 AND PO.IsPayByCompanyCreditCard = 0 AND PO.PurchaseOrderAmount > 0 ) )
				AND
				( @PaymentByCard IS NULL OR ( @PaymentByCard = 1 AND PO.IsPayByCompanyCreditCard = 1 AND PO.PurchaseOrderAmount > 0 ) )
				AND
				( @MemberPaid IS NULL OR ( @MemberPaid = 1 AND POS.Name = 'Issue-Paid' AND PO.PurchaseOrderAmount > 0 ))
		)
		AND
		-- PurchaseOrder status
		(
				(	ISNULL(@strPOStatuses,'') = '' OR ( PO.PurchaseOrderStatusID IN (SELECT ID FROM @tmpPOStatuses) ))
		)
	)
	
	-- DEBUG:
	--SELECT 'Filtered', * FROM #Filtered
	
	-- Format the data [ Member name, vehiclemake, model, etc]
	INSERT INTO #Formatted 
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
			PaymentByCard	
	FROM	#Filtered R
	
	
	
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
	
	DROP TABLE #Raw
	DROP TABLE #Filtered
	DROP TABLE #Formatted
	DROP TABLE #Sorted

END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_PO_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_PO_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_PO_Details_Get @PONumber=7770395
 CREATE PROCEDURE [dbo].dms_Vendor_Invoice_PO_Details_Get( 
	@PONumber nvarchar(50) =NULL
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET FMTONLY OFF

SELECT		PO.ID
			, CASE
				WHEN ISNULL(PO.IsPayByCompanyCreditCard,'') = 1 THEN 'Paid with company credit card'
				ELSE ''
			  END AS [AlertText]
			, PO.PurchaseOrderNumber AS [PONumber]
			, POS.Name AS [POStatus]
			, PO.PurchaseOrderAmount AS [POAmount]
			, PC.Name AS [Service]
			, PO.IssueDate AS [IssueDate]
			, PO.ETADate AS [ETADate]
			, PO.VendorLocationID			
			, CASE
			WHEN ISNULL(CRS.ID,'') = '' THEN 'Not Contracted'
			ELSE 'Contracted'
			END AS 'ContractStatus'
			, V.Name AS [VendorName]
			, V.VendorNumber AS [VendorNumber]
			, ISNULL(PO.BillingAddressLine1,'') AS [VendorLocationLine1]
			, ISNULL(PO.BillingAddressLine2,'') AS [VendorLocationLine2]
			, ISNULL(PO.BillingAddressLine3,'') AS [VendorLocationLine3] 
			, ISNULL(REPLACE(RTRIM(
						COALESCE(PO.BillingAddressCity, '') + 
						COALESCE(', ' + RTRIM(PO.BillingAddressStateProvince), '') +     
						COALESCE(' ' + PO.BillingAddressPostalCode, '') +     					
						COALESCE(' ' + PO.BillingAddressCountryCode, '') 
					), '  ', ' ')
					,'') AS [VendorLocationCityStZip]
			, PO.DispatchPhoneNumber AS [DispatchPhoneNumber]
			, PO.FaxPhoneNumber AS [FaxPhoneNumber]
			, 'TalkedTo' AS [TalkedTo] -- TODO: Linked to ContactLog and get Talked To
			, CL.Name AS [Client]
			, P.Name AS [Program]
			, MS.MembershipNumber AS [MemberNumber]
			, C.MemberStatus
			, REPLACE(RTRIM(
				COALESCE(CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+
				COALESCE(' ' + LEFT(M.MiddleName,1),'')+
				COALESCE(' ' + CASE WHEN M.LastName = '' THEN NULL ELSE M.LastName END,'')+  
				COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')
				),'','') AS [CustomerName]
			, C.ContactPhoneNumber AS [CallbackNumber] 
			, C.ContactAltPhoneNumber AS [AlternateNumber]
			--, PO.SubTotal AS [SubTotal]  calculated from PO Details GRID
			, PO.TaxAmount AS [Tax]
			, PO.TotalServiceAmount AS [ServiceTotal]
			, PO.CoachNetServiceAmount AS [CoachNetPays]
			, PO.MemberServiceAmount AS [MemberPays]
			, VT.Name + ' - ' + VC.Name AS [VehicleType]
			, REPLACE(RTRIM(
				COALESCE(C.VehicleYear,'')+
				COALESCE(' ' + CASE WHEN C.VehicleMake = 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END,'')+
				COALESCE(' ' + CASE WHEN C.VehicleModel = 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END,'')
				), '','') AS [Vehicle]
			, ISNULL(C.VehicleVIN,'') AS [VIN]
			, ISNULL(C.VehicleColor,'') AS [Color]
			, REPLACE(RTRIM(
					COALESCE(C.VehicleLicenseState + ' - ','') +
					COALESCE(C.VehicleLicenseNumber,'') 
				),'','') AS [License]
			, ISNULL(C.VehicleCurrentMileage,'') AS [Mileage]
			, ISNULL(SR.ServiceLocationAddress,'') AS [Location]
			, ISNULL(SR.ServiceLocationDescription,'') AS [LocationDescription]
			, ISNULL(SR.DestinationAddress,'') AS [Destination]
			, ISNULL(SR.DestinationDescription,'') AS [DestinationDescription]
			, PO.CreateBy
			, PO.CreateDate
			, PO.ModifyBy
			, PO.ModifyDate	
			, CT.Abbreviation AS [CurrencyType]	
			, PO.IsPayByCompanyCreditCard AS IsPayByCC
			, PO.CompanyCreditCardNumber CompanyCC
			,PO.VendorTaxID
			,PO.Email
			,POPS.[Description] PurchaseOrderPayStatus
FROM		PurchaseOrder PO 
JOIN		PurchaseOrderStatus POS WITH (NOLOCK)ON POS.ID = PO.PurchaseOrderStatusID
LEFT JOIN PurchaseOrderPayStatusCode POPS WITH (NOLOCK) ON POPS.ID = PO.PayStatusCodeID
JOIN		ServiceRequest SR WITH (NOLOCK) ON SR.ID = PO.ServiceRequestID
LEFT JOIN	ServiceRequestStatus SRS WITH (NOLOCK) ON SRS.ID = SR.ServiceRequestStatusID
LEFT JOIN	ProductCategory PCSR ON PCSR.ID = SR.ProductCategoryID
JOIN		[Case] C WITH (NOLOCK) ON C.ID = SR.CaseID
JOIN		Program P WITH (NOLOCK) ON P.ID = C.ProgramID
JOIN		Client CL WITH (NOLOCK) ON CL.ID = P.ClientID
JOIN		Member M WITH (NOLOCK) ON M.ID = C.MemberID
JOIN		Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
JOIN		Product PR WITH (NOLOCK) ON PR.ID = PO.ProductID
JOIN		ProductCategory PC WITH (NOLOCK) ON PC.ID = PR.ProductCategoryID
LEFT JOIN	VehicleType VT WITH(NOLOCK) ON VT.ID = C.VehicleTypeID
LEFT JOIN	VehicleCategory VC WITH(NOLOCK) ON VC.ID = C.VehicleCategoryID
LEFT JOIN	RVType RT WITH (NOLOCK) ON RT.ID = C.VehicleRVTypeID
JOIN		VendorLocation VL WITH(NOLOCK) ON VL.ID = PO.VendorLocationID
JOIN		Vendor V WITH(NOLOCK) ON V.ID = VL.VendorID
LEFT JOIN [Contract] CO ON CO.VendorID = V.ID 	AND CO.IsActive = 1
LEFT JOIN ContractRateSchedule CRS ON CRS.ContractID = V.ID	AND CO.IsActive = 1
LEFT JOIN CurrencyType CT ON CT.ID=PO.CurrencyTypeID
WHERE		PO.PurchaseOrderNumber = @PONumber
			AND PO.IsActive = 1

END
GO
GO
