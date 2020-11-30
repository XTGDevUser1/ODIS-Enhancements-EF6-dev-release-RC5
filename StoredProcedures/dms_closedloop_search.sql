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

