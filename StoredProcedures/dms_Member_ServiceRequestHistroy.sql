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
	 
	DECLARE @MembershipID int

	SELECT	@MembershipID = MembershipIDValue
	FROM	@tmpForWhereClause
 
  
	INSERT INTO #FinalResultsFiltered
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
	WHERE ms.ID = @MembershipID 
 
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
	FROM  #FinalResultsFormatted F
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
