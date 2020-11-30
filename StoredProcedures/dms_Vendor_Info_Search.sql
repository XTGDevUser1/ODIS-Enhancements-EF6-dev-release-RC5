  
  IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Info_Search]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Info_Search] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

  --EXEC dms_Vendor_Info_Search @DispatchPhoneNumber = '1 4695213697',@OfficePhoneNumber = '1 9254494909'  
 CREATE PROCEDURE [dbo].[dms_Vendor_Info_Search](   
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10    
 , @sortColumn nvarchar(100)  = ''   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @DispatchPhoneNumber nvarchar(50)=NULL 
 , @OfficePhoneNumber nvarchar(50)=NULL
 , @VendorSearchName nvarchar(50)=NULL  
-- , @FaxPhoneNumber nvarchar(50)  
  
--SET @DispatchPhoneNumber = '1 2146834715';  
--SET @OfficePhoneNumber = '1 5868722949'  
  
) AS   
 BEGIN   
    
  SET NOCOUNT ON  
  
DECLARE @idoc int  
IF @whereClauseXML IS NULL   
BEGIN  
 SET @whereClauseXML = '<ROW><Filter   
VendorIDOperator="-1"   
VendorLocationIDOperator="-1"   
SequenceOperator="-1"   
VendorNumberOperator="-1"   
VendorNameOperator="-1"   
VendorStatusOperator="-1"   
ContractStatusOperator="-1"   
Address1Operator="-1"   
VendorCityOperator="-1"   
DispatchPhoneTypeOperator="-1"   
DispatchPhoneNumberOperator="-1"   
OfficePhoneTypeOperator="-1"   
 ></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
VendorIDOperator INT NOT NULL,  
VendorIDValue int NULL,  
VendorLocationIDOperator INT NOT NULL,  
VendorLocationIDValue int NULL,  
SequenceOperator INT NOT NULL,  
SequenceValue int NULL,  
VendorNumberOperator INT NOT NULL,  
VendorNumberValue nvarchar(50) NULL,  
VendorNameOperator INT NOT NULL,  
VendorNameValue nvarchar(50) NULL,  
VendorStatusOperator INT NOT NULL,  
VendorStatusValue nvarchar(50) NULL,  
ContractStatusOperator INT NOT NULL,  
ContractStatusValue nvarchar(50) NULL,  
Address1Operator INT NOT NULL,  
Address1Value nvarchar(50) NULL,  
VendorCityOperator INT NOT NULL,  
VendorCityValue nvarchar(50) NULL,  
DispatchPhoneTypeOperator INT NOT NULL,  
DispatchPhoneTypeValue int NULL,  
DispatchPhoneNumberOperator INT NOT NULL,  
DispatchPhoneNumberValue nvarchar(50) NULL,  
OfficePhoneTypeOperator INT NOT NULL,  
OfficePhoneTypeValue int NULL  
)  
DECLARE @FinalResults TABLE (   
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 VendorID int  NULL ,  
 VendorLocationID int  NULL ,  
 Sequence int  NULL ,  
 VendorNumber nvarchar(50)  NULL ,  
 VendorName nvarchar(255)  NULL ,  
 VendorStatus nvarchar(50)  NULL ,  
 ContractStatus nvarchar(50)  NULL ,  
 Address1 nvarchar(255)  NULL ,  
 VendorCity nvarchar(255)  NULL ,  
 DispatchPhoneType int  NULL ,  
 DispatchPhoneNumber nvarchar(50)  NULL ,  
 OfficePhoneType int  NULL ,  
 OfficePhoneNumber nvarchar(50)  NULL   
)   
DECLARE @FinalResults1 TABLE (   
 --[RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 VendorID int  NULL ,  
 VendorLocationID int  NULL ,  
 Sequence int  NULL ,  
 VendorNumber nvarchar(50)  NULL ,  
 VendorName nvarchar(255)  NULL ,  
 VendorStatus nvarchar(50)  NULL ,  
 ContractStatus nvarchar(50)  NULL ,  
 Address1 nvarchar(255)  NULL ,  
 VendorCity nvarchar(255)  NULL ,  
 DispatchPhoneType int  NULL ,  
 DispatchPhoneNumber nvarchar(50)  NULL ,  
 OfficePhoneType int  NULL ,  
 OfficePhoneNumber nvarchar(50)  NULL   
)   
  
INSERT INTO @tmpForWhereClause  
SELECT    
 ISNULL(VendorIDOperator,-1),  
 VendorIDValue ,  
 ISNULL(VendorLocationIDOperator,-1),  
 VendorLocationIDValue ,  
 ISNULL(SequenceOperator,-1),  
 SequenceValue ,  
 ISNULL(VendorNumberOperator,-1),  
 VendorNumberValue ,  
 ISNULL(VendorNameOperator,-1),  
 VendorNameValue ,  
 ISNULL(VendorStatusOperator,-1),  
 VendorStatusValue ,  
 ISNULL(ContractStatusOperator,-1),  
 ContractStatusValue ,  
 ISNULL(Address1Operator,-1),  
 Address1Value ,  
 ISNULL(VendorCityOperator,-1),  
 VendorCityValue ,  
 ISNULL(DispatchPhoneTypeOperator,-1),  
 DispatchPhoneTypeValue ,  
 ISNULL(DispatchPhoneNumberOperator,-1),  
 DispatchPhoneNumberValue ,  
 ISNULL(OfficePhoneTypeOperator,-1),  
 OfficePhoneTypeValue   
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
VendorIDOperator INT,  
VendorIDValue int   
,VendorLocationIDOperator INT,  
VendorLocationIDValue int   
,SequenceOperator INT,  
SequenceValue int   
,VendorNumberOperator INT,  
VendorNumberValue nvarchar(50)   
,VendorNameOperator INT,  
VendorNameValue nvarchar(50)   
,VendorStatusOperator INT,  
VendorStatusValue nvarchar(50)   
,ContractStatusOperator INT,  
ContractStatusValue nvarchar(50)   
,Address1Operator INT,  
Address1Value nvarchar(50)   
,VendorCityOperator INT,  
VendorCityValue nvarchar(50)   
,DispatchPhoneTypeOperator INT,  
DispatchPhoneTypeValue int   
,DispatchPhoneNumberOperator INT,  
DispatchPhoneNumberValue nvarchar(50)   
,OfficePhoneTypeOperator INT,  
OfficePhoneTypeValue int   
 )   

DECLARE @VendorLocationEntityID int,
	@VendorEntityID int,
	@DispatchPhoneTypeID int,
	@OfficePhoneTypeID int
SET @VendorLocationEntityID = (Select ID From Entity Where Name = 'VendorLocation')
SET @VendorEntityID = (Select ID From Entity Where Name = 'Vendor')
SET @DispatchPhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')  
SET @OfficePhoneTypeID = (Select ID From PhoneType Where Name = 'Office')  

--------------------- BEGIN -----------------------------  
----   Create a temp variable or a CTE with the actual SQL search query ----------  
----   and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
  
INSERT INTO @FinalResults1  
  
SELECT   
  v.ID  
 ,vl.ID   
 ,vl.Sequence  
 ,v.VendorNumber   
 ,v.Name
 ,vs.Name AS VendorStatus
 ,CASE WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted' ELSE 'Not Contracted' END
 ,ae.Line1 as Address1  
 --,ae.Line2 as Address2  
 ,REPLACE(RTRIM(  
   COALESCE(ae.City, '') +  
   COALESCE(', ' + ae.StateProvince,'') +   
   COALESCE(LTRIM(ae.PostalCode), '') +   
   COALESCE(' ' + ae.CountryCode, '')   
   ), ' ', ' ')   
 , pe24.PhoneTypeID   
 , pe24.PhoneNumber   
 , peOfc.PhoneTypeID   
 , peOfc.PhoneNumber   
FROM VendorLocation vl  
INNER JOIN Vendor v on v.ID = vl.VendorID  
JOIN VendorStatus vs on v.VendorStatusID  = vs.ID
LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID
LEFT OUTER JOIN AddressEntity ae on ae.RecordID = vl.ID and ae.EntityID = @VendorLocationEntityID    
LEFT OUTER JOIN PhoneEntity pe24 on pe24.RecordID = vl.ID and pe24.EntityID = @VendorLocationEntityID and pe24.PhoneTypeID = @DispatchPhoneTypeID   
LEFT OUTER JOIN PhoneEntity peOfc on peOfc.RecordID = v.ID and peOfc.EntityID = @VendorEntityID and peOfc.PhoneTypeID = @OfficePhoneTypeID 
--LEFT OUTER JOIN [Contract] c on c.VendorID = v.ID and c.IsActive = 1 AND c.ContractStatusID = (SELECT ID FROM ContractStatus WHERE Name = 'Active')
WHERE  
v.IsActive = 1 
--AND (v.VendorNumber IS NULL OR v.VendorNumber NOT LIKE '9X%' ) --KB: VendorNumber will be NULL for newly added vendors and these are getting excluded from the possible duplicates
AND
-- TP: Matching either phone number across both phone types is valid for this search; 
--     grouped OR condition -- A match on either phone number is valid
(ISNULL(pe24.PhoneNumber,'') IN (@DispatchPhoneNumber, @OfficePhoneNumber)
 OR
 ISNULL(peOfc.PhoneNumber,'') IN (@DispatchPhoneNumber, @OfficePhoneNumber)
)

--AND (@DispatchPhoneNumber IS NULL) OR (pe24.PhoneNumber = @DispatchPhoneNumber)  
--OR (@OfficePhoneNumber IS NULL) OR (peOfc.PhoneNumber = @OfficePhoneNumber)  
--AND (@VendorSearchName IS NULL) OR (v.NAme LIKE '%'+@VendorSearchName+'%')  

INSERT INTO @FinalResults  
SELECT   
 T.VendorID,  
 T.VendorLocationID,  
 T.Sequence,  
 T.VendorNumber,  
 T.VendorName,  
 T.VendorStatus,  
 T.ContractStatus,  
 T.Address1,  
 T.VendorCity,  
 T.DispatchPhoneType,  
 T.DispatchPhoneNumber,  
 T.OfficePhoneType,  
 T.OfficePhoneNumber  
FROM @FinalResults1 T,  
@tmpForWhereClause TMP   
WHERE (   
  
 (   
  ( TMP.VendorIDOperator = -1 )   
 OR   
  ( TMP.VendorIDOperator = 0 AND T.VendorID IS NULL )   
 OR   
  ( TMP.VendorIDOperator = 1 AND T.VendorID IS NOT NULL )   
 OR   
  ( TMP.VendorIDOperator = 2 AND T.VendorID = TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 3 AND T.VendorID <> TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 7 AND T.VendorID > TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 8 AND T.VendorID >= TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 9 AND T.VendorID < TMP.VendorIDValue )   
 OR   
  ( TMP.VendorIDOperator = 10 AND T.VendorID <= TMP.VendorIDValue )   
  
 )   
  
 AND   
  
 (   
  ( TMP.VendorLocationIDOperator = -1 )   
 OR   
  ( TMP.VendorLocationIDOperator = 0 AND T.VendorLocationID IS NULL )   
 OR   
  ( TMP.VendorLocationIDOperator = 1 AND T.VendorLocationID IS NOT NULL )   
 OR   
  ( TMP.VendorLocationIDOperator = 2 AND T.VendorLocationID = TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 3 AND T.VendorLocationID <> TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 7 AND T.VendorLocationID > TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 8 AND T.VendorLocationID >= TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 9 AND T.VendorLocationID < TMP.VendorLocationIDValue )   
 OR   
  ( TMP.VendorLocationIDOperator = 10 AND T.VendorLocationID <= TMP.VendorLocationIDValue )   
  
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
  ( TMP.VendorNumberOperator = -1 )   
 OR   
  ( TMP.VendorNumberOperator = 0 AND T.VendorNumber IS NULL )   
 OR   
  ( TMP.VendorNumberOperator = 1 AND T.VendorNumber IS NOT NULL )   
 OR   
  ( TMP.VendorNumberOperator = 2 AND T.VendorNumber = TMP.VendorNumberValue )   
 OR   
  ( TMP.VendorNumberOperator = 3 AND T.VendorNumber <> TMP.VendorNumberValue )   
 OR   
  ( TMP.VendorNumberOperator = 4 AND T.VendorNumber LIKE TMP.VendorNumberValue + '%')   
 OR   
  ( TMP.VendorNumberOperator = 5 AND T.VendorNumber LIKE '%' + TMP.VendorNumberValue )   
 OR   
  ( TMP.VendorNumberOperator = 6 AND T.VendorNumber LIKE '%' + TMP.VendorNumberValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.VendorNameOperator = -1 )   
 OR   
  ( TMP.VendorNameOperator = 0 AND T.VendorName IS NULL )   
 OR   
  ( TMP.VendorNameOperator = 1 AND T.VendorName IS NOT NULL )   
 OR   
  ( TMP.VendorNameOperator = 2 AND T.VendorName = TMP.VendorNameValue )   
 OR   
  ( TMP.VendorNameOperator = 3 AND T.VendorName <> TMP.VendorNameValue )   
 OR   
  ( TMP.VendorNameOperator = 4 AND T.VendorName LIKE TMP.VendorNameValue + '%')   
 OR   
  ( TMP.VendorNameOperator = 5 AND T.VendorName LIKE '%' + TMP.VendorNameValue )   
 OR   
  ( TMP.VendorNameOperator = 6 AND T.VendorName LIKE '%' + TMP.VendorNameValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.VendorStatusOperator = -1 )   
 OR   
  ( TMP.VendorStatusOperator = 0 AND T.VendorStatus IS NULL )   
 OR   
  ( TMP.VendorStatusOperator = 1 AND T.VendorStatus IS NOT NULL )   
 OR   
  ( TMP.VendorStatusOperator = 2 AND T.VendorStatus = TMP.VendorStatusValue )   
 OR   
  ( TMP.VendorStatusOperator = 3 AND T.VendorStatus <> TMP.VendorStatusValue )   
 OR   
  ( TMP.VendorStatusOperator = 4 AND T.VendorStatus LIKE TMP.VendorStatusValue + '%')   
 OR   
  ( TMP.VendorStatusOperator = 5 AND T.VendorStatus LIKE '%' + TMP.VendorStatusValue )   
 OR   
  ( TMP.VendorStatusOperator = 6 AND T.VendorStatus LIKE '%' + TMP.VendorStatusValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.ContractStatusOperator = -1 )   
 OR   
  ( TMP.ContractStatusOperator = 0 AND T.ContractStatus IS NULL )   
 OR   
  ( TMP.ContractStatusOperator = 1 AND T.ContractStatus IS NOT NULL )   
 OR   
  ( TMP.ContractStatusOperator = 2 AND T.ContractStatus = TMP.ContractStatusValue )   
 OR   
  ( TMP.ContractStatusOperator = 3 AND T.ContractStatus <> TMP.ContractStatusValue )   
 OR   
  ( TMP.ContractStatusOperator = 4 AND T.ContractStatus LIKE TMP.ContractStatusValue + '%')   
 OR   
  ( TMP.ContractStatusOperator = 5 AND T.ContractStatus LIKE '%' + TMP.ContractStatusValue )   
 OR   
  ( TMP.ContractStatusOperator = 6 AND T.ContractStatus LIKE '%' + TMP.ContractStatusValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.Address1Operator = -1 )   
 OR   
  ( TMP.Address1Operator = 0 AND T.Address1 IS NULL )   
 OR   
  ( TMP.Address1Operator = 1 AND T.Address1 IS NOT NULL )   
 OR   
  ( TMP.Address1Operator = 2 AND T.Address1 = TMP.Address1Value )   
 OR   
  ( TMP.Address1Operator = 3 AND T.Address1 <> TMP.Address1Value )   
 OR   
  ( TMP.Address1Operator = 4 AND T.Address1 LIKE TMP.Address1Value + '%')   
 OR   
  ( TMP.Address1Operator = 5 AND T.Address1 LIKE '%' + TMP.Address1Value )   
 OR   
  ( TMP.Address1Operator = 6 AND T.Address1 LIKE '%' + TMP.Address1Value + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.VendorCityOperator = -1 )   
 OR   
  ( TMP.VendorCityOperator = 0 AND T.VendorCity IS NULL )   
 OR   
  ( TMP.VendorCityOperator = 1 AND T.VendorCity IS NOT NULL )   
 OR   
  ( TMP.VendorCityOperator = 2 AND T.VendorCity = TMP.VendorCityValue )   
 OR   
  ( TMP.VendorCityOperator = 3 AND T.VendorCity <> TMP.VendorCityValue )   
 OR   
  ( TMP.VendorCityOperator = 4 AND T.VendorCity LIKE TMP.VendorCityValue + '%')   
 OR   
  ( TMP.VendorCityOperator = 5 AND T.VendorCity LIKE '%' + TMP.VendorCityValue )   
 OR   
  ( TMP.VendorCityOperator = 6 AND T.VendorCity LIKE '%' + TMP.VendorCityValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.DispatchPhoneTypeOperator = -1 )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 0 AND T.DispatchPhoneType IS NULL )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 1 AND T.DispatchPhoneType IS NOT NULL )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 2 AND T.DispatchPhoneType = TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 3 AND T.DispatchPhoneType <> TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 7 AND T.DispatchPhoneType > TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 8 AND T.DispatchPhoneType >= TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 9 AND T.DispatchPhoneType < TMP.DispatchPhoneTypeValue )   
 OR   
  ( TMP.DispatchPhoneTypeOperator = 10 AND T.DispatchPhoneType <= TMP.DispatchPhoneTypeValue )   
  
 )   
  
 AND   
  
 (   
  ( TMP.DispatchPhoneNumberOperator = -1 )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 0 AND T.DispatchPhoneNumber IS NULL )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 1 AND T.DispatchPhoneNumber IS NOT NULL )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 2 AND T.DispatchPhoneNumber = TMP.DispatchPhoneNumberValue )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 3 AND T.DispatchPhoneNumber <> TMP.DispatchPhoneNumberValue )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 4 AND T.DispatchPhoneNumber LIKE TMP.DispatchPhoneNumberValue + '%')   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 5 AND T.DispatchPhoneNumber LIKE '%' + TMP.DispatchPhoneNumberValue )   
 OR   
  ( TMP.DispatchPhoneNumberOperator = 6 AND T.DispatchPhoneNumber LIKE '%' + TMP.DispatchPhoneNumberValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.OfficePhoneTypeOperator = -1 )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 0 AND T.OfficePhoneType IS NULL )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 1 AND T.OfficePhoneType IS NOT NULL )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 2 AND T.OfficePhoneType = TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 3 AND T.OfficePhoneType <> TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 7 AND T.OfficePhoneType > TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 8 AND T.OfficePhoneType >= TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 9 AND T.OfficePhoneType < TMP.OfficePhoneTypeValue )   
 OR   
  ( TMP.OfficePhoneTypeOperator = 10 AND T.OfficePhoneType <= TMP.OfficePhoneTypeValue )   
  
 )   
  
 AND   
 1 = 1   
 )   
 ORDER BY   
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'ASC'  
  THEN T.VendorID END ASC,   
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'DESC'  
  THEN T.VendorID END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorLocationID' AND @sortOrder = 'ASC'  
  THEN T.VendorLocationID END ASC,   
  CASE WHEN @sortColumn = 'VendorLocationID' AND @sortOrder = 'DESC'  
  THEN T.VendorLocationID END DESC ,  
  
  CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'  
  THEN T.Sequence END ASC,   
  CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'  
  THEN T.Sequence END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'  
  THEN T.VendorNumber END ASC,   
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'  
  THEN T.VendorNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'ASC'  
  THEN T.VendorName END ASC,   
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'DESC'  
  THEN T.VendorName END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'ASC'  
  THEN T.VendorStatus END ASC,   
  CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'DESC'  
  THEN T.VendorStatus END DESC ,  
  
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'ASC'  
  THEN T.ContractStatus END ASC,   
  CASE WHEN @sortColumn = 'ContractStatus' AND @sortOrder = 'DESC'  
  THEN T.ContractStatus END DESC ,  
  
  CASE WHEN @sortColumn = 'Address1' AND @sortOrder = 'ASC'  
  THEN T.Address1 END ASC,   
  CASE WHEN @sortColumn = 'Address1' AND @sortOrder = 'DESC'  
  THEN T.Address1 END DESC ,  
  
  CASE WHEN @sortColumn = 'VendorCity' AND @sortOrder = 'ASC'  
  THEN T.VendorCity END ASC,   
  CASE WHEN @sortColumn = 'VendorCity' AND @sortOrder = 'DESC'  
  THEN T.VendorCity END DESC ,  
  
  CASE WHEN @sortColumn = 'DispatchPhoneType' AND @sortOrder = 'ASC'  
  THEN T.DispatchPhoneType END ASC,   
  CASE WHEN @sortColumn = 'DispatchPhoneType' AND @sortOrder = 'DESC'  
  THEN T.DispatchPhoneType END DESC ,  
  
  CASE WHEN @sortColumn = 'DispatchPhoneNumber' AND @sortOrder = 'ASC'  
  THEN T.DispatchPhoneNumber END ASC,   
  CASE WHEN @sortColumn = 'DispatchPhoneNumber' AND @sortOrder = 'DESC'  
  THEN T.DispatchPhoneNumber END DESC ,  
  
  CASE WHEN @sortColumn = 'OfficePhoneType' AND @sortOrder = 'ASC'  
  THEN T.OfficePhoneType END ASC,   
  CASE WHEN @sortColumn = 'OfficePhoneType' AND @sortOrder = 'DESC'  
  THEN T.OfficePhoneType END DESC ,  
  
  CASE WHEN @sortColumn = 'OfficePhoneNumber' AND @sortOrder = 'ASC'  
  THEN T.OfficePhoneNumber END ASC,   
  CASE WHEN @sortColumn = 'OfficePhoneNumber' AND @sortOrder = 'DESC'  
  THEN T.OfficePhoneNumber END DESC   
  
  
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
