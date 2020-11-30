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
--EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = '<ROW><Filter IDType="Contact Phone Number" IDValue="2485250690"/></ROW>',@userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
-- EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = '<ROW><Filter IDType="Contact Phone Number" IDValue="8285635847" NameType="" NameValue="" LastName="" FilterType = "StartsWith" FromDate = "" ToDate = "" Preset ="" Clients ="1" Programs ="" ServiceRequestStatuses = "" ServiceTypes ="" IsGOA = "" IsRedispatched = "" IsPossibleTow ="" VehicleType ="1" VehicleYear ="2012" VehicleMake = "" VehicleModel = "" PaymentByCheque = "" PaymentByCard = "" MemberPaid ="" POStatuses =""/></ROW>', @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
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
		PaymentByCard BIT NULL,
		POCreateDate DATETIME NULL
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
	
	DECLARE @tmpWhereClause TABLE
	(	
		IDType NVARCHAR(255) NULL UNIQUE NonClustered,
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
	

	DECLARE @totalRows INT = 0,
		@IDType NVARCHAR(255) ,
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
		,@strPOStatuses NVARCHAR(MAX)
		,@strPrograms NVARCHAR(MAX)
		,@strServiceRequestStatuses NVARCHAR(MAX)
		,@strServiceTypes NVARCHAR(MAX)

	-- Extract some of the values into separate tables for ease of processing.
	SELECT	@strClients = Clients,
			@strPOStatuses = POStatuses,
			@strPrograms = Programs,
			@strServiceRequestStatuses = ServiceRequestStatuses,
			@strServiceTypes = ServiceTypes			
	FROM	@tmpWhereClause
	
	-- Clients
	DECLARE @tmpClients IntTableType
	INSERT INTO @tmpClients
	SELECT item FROM fnSplitString(@strClients,',')
	
	-- Programs
	DECLARE @tmpPrograms IntTableType
	INSERT INTO @tmpPrograms
	SELECT item FROM fnSplitString(@strPrograms,',')
	
	-- POStatuses
	DECLARE @tmpPOStatuses IntTableType
	INSERT INTO @tmpPOStatuses
	SELECT item FROM fnSplitString(@strPOStatuses,',')
	
	-- Service request statuses
	DECLARE @tmpServiceRequestStatuses IntTableType
	INSERT INTO @tmpServiceRequestStatuses
	SELECT item FROM fnSplitString(@strServiceRequestStatuses,',')
	
	-- Service types
	DECLARE @tmpServiceTypes IntTableType
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
	

	DECLARE @sql nvarchar(max) = ''
	
	SET @sql =        'SELECT'
	SET @sql = @sql + '  SR.ID AS RequestNumber'	
	SET @sql = @sql + ' ,SR.CaseID AS [Case]'	
	SET @sql = @sql + ' ,P.ProgramID'    
	SET @sql = @sql + ' ,P.ProgramName Program'   
	SET @sql = @sql + ' ,CL.id AS ClientID'  
	SET @sql = @sql + ' ,CL.Name Client'  
	SET @sql = @sql + ' ,M.FirstName'
	SET @sql = @sql + ' ,M.LastName'
	SET @sql = @sql + ' ,M.MiddleName'
	SET @sql = @sql + ' ,M.Suffix'
	SET @sql = @sql + ' ,M.Prefix'     
	SET @sql = @sql + ' ,CASE WHEN MS.MembershipNumber IS NULL THEN ''Ref#: '' + MS.ClientReferenceNUmber ELSE MS.MembershipNumber END AS MemberNumber'
	SET @sql = @sql + ' ,SR.CreateDate'	
	SET @sql = @sql + ' ,PO.CreateBy'	
	SET @sql = @sql + ' ,PO.ModifyBy'	
	SET @sql = @sql + ' ,SR.CreateBy'	
	SET @sql = @sql + ' ,SR.ModifyBy'	
	SET @sql = @sql + ' ,C.VehicleVIN AS VIN'	
	SET @sql = @sql + ' ,VT.ID AS VehicleTypeID'	
	SET @sql = @sql + ' ,VT.Name AS VehicleType'	
	SET @sql = @sql + ' ,PC.ID AS ServiceTypeID'	
	SET @sql = @sql + ' ,PC.Name AS ServiceType'	
	SET @sql = @sql + ' ,SRS.ID AS StatusID'	
	SET @sql = @sql + ' ,CASE ISNULL(SR.IsRedispatched,0) WHEN 1 THEN SRS.Name + CHAR(94) ELSE SRS.Name END AS [Status]'
	SET @sql = @sql + ' ,SR.ServiceRequestPriorityID AS [PriorityID]'
	SET @sql = @sql + ' ,SRP.Name AS [Priority]'
	SET @sql = @sql + ' ,V.Name AS [ISPName]'
	SET @sql = @sql + ' ,V.VendorNumber'
	SET @sql = @sql + ' ,PO.PurchaseOrderNumber AS [PONumber]'
	SET @sql = @sql + ' ,POS.ID AS PurchaseOrderStatusID'
	SET @sql = @sql + ' ,POS.Name AS PurchaseOrderStatus'
	SET @sql = @sql + ' ,PO.PurchaseOrderAmount'
	SET @sql = @sql + ' ,C.AssignedToUserID'
	SET @sql = @sql + ' ,SR.NextActionAssignedToUserID'		
	SET @sql = @sql + ' ,PO.IsGOA'
	SET @sql = @sql + ' ,SR.IsRedispatched'
	SET @sql = @sql + ' ,SR.IsPossibleTow'
	SET @sql = @sql + ' ,C.VehicleYear'
	SET @sql = @sql + ' ,C.VehicleMake'
	SET @sql = @sql + ' ,C.VehicleMakeOther'
	SET @sql = @sql + ' ,C.VehicleModel'
	SET @sql = @sql + ' ,C.VehicleModelOther'
	SET @sql = @sql + ' ,PO.IsPayByCompanyCreditCard'
	SET @sql = @sql + ' ,PO.CreateDate'		

	SET @sql = @sql + ' FROM ServiceRequest SR WITH (NOLOCK)'
	SET @sql = @sql + ' JOIN [Case] C WITH (NOLOCK) on C.ID = SR.CaseID'
	SET @sql = @sql + ' JOIN dbo.fnc_GetProgramsForUser(@userID) P ON C.ProgramID = P.ProgramID'
	SET @sql = @sql + ' JOIN Client CL WITH (NOLOCK) ON P.ClientID = CL.ID'
	SET @sql = @sql + ' LEFT OUTER JOIN Member M WITH (NOLOCK) ON C.MemberID = M.ID'
	SET @sql = @sql + ' JOIN ServiceRequestStatus SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID'
	SET @sql = @sql + ' LEFT OUTER JOIN ServiceRequestPriority SRP WITH (NOLOCK) ON SR.ServiceRequestPriorityID = SRP.ID '
	SET @sql = @sql + ' LEFT OUTER JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID'
	SET @sql = @sql + ' LEFT OUTER JOIN ProductCategory PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID'
	SET @sql = @sql + ' LEFT OUTER JOIN VehicleType VT WITH (NOLOCK) ON VT.ID = C.VehicleTypeID'
	SET @sql = @sql + ' LEFT OUTER JOIN PurchaseOrder PO WITH (NOLOCK) ON PO.ServiceRequestID = SR.ID AND PO.IsActive = 1'
					--+ CASE WHEN @IDType = 'Purchase Order' THEN ' AND ' + @IDValue ELSE '' END
	SET @sql = @sql + ' LEFT OUTER JOIN PurchaseOrderStatus POS WITH (NOLOCK) ON PO.PurchaseOrderStatusID = POS.ID'
	SET @sql = @sql + ' LEFT OUTER JOIN NextAction NA WITH (NOLOCK) ON SR.NextActionID=NA.ID'
	SET @sql = @sql + ' LEFT OUTER JOIN VendorLocation VL WITH (NOLOCK) ON PO.VendorLocationID = VL.ID'
	SET @sql = @sql + ' LEFT OUTER JOIN Vendor V WITH (NOLOCK) ON VL.VendorID = V.ID'
	
	SET @sql = @sql + ' WHERE  1=1'
	
	---- ID Value
	IF @IDType = 'Member' 
	SET @sql = @sql + ' AND (MS.MembershipNumber LIKE char(37) + @IDValue + char(37) OR MS.AltMembershipNumber LIKE  char(37) + @IDValue + char(37))'  
	
	IF @IDType = 'Service Request' 
	SET @sql = @sql + ' AND SR.ID = @IDValue'  

	IF @IDType = 'Purchase Order' 
	SET @sql = @sql + ' AND PO.PurchaseOrderNumber = @IDValue'  

	IF @IDType = 'ISP' 
	SET @sql = @sql + ' AND V.VendorNumber = @IDValue'  

	IF @IDType = 'VIN' 
	SET @sql = @sql + ' AND C.VehicleVIN = @IDValue'  

	
	--Name: ISP
	IF @NameType = 'ISP' AND @NameValue IS NOT NULL
		BEGIN
		IF @FilterType IN ('Starts With', 'Contains', 'Ends With') 
			SET @sql = @sql + ' AND V.Name LIKE'
							+ CASE WHEN @FilterType IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @NameValue'
							+ CASE WHEN @FilterType IN ('Starts With', 'Contains') THEN ' +CHAR(37)' ELSE '' END
		ELSE
			---- Is Equal To
			SET @sql = @sql + ' AND V.Name = @NameValue'  
		END

	
	----Name: Member
	IF @NameType = 'Member' AND (@NameValue IS NOT NULL OR @LastName IS NOT NULL)
		BEGIN
		IF @FilterType IN ('Starts With', 'Contains', 'Ends With') 
			BEGIN
			SET @sql = @sql + ' AND M.FirstName LIKE'
							+ CASE WHEN @FilterType IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @NameValue'
							+ CASE WHEN @FilterType IN ('Starts With', 'Contains') THEN ' +CHAR(37)' ELSE '' END
			SET @sql = @sql + ' AND M.LastName LIKE'
							+ CASE WHEN @FilterType IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @LastName'
							+ CASE WHEN @FilterType IN ('Starts With', 'Contains') THEN ' +CHAR(37)' ELSE '' END
			END	
		ELSE
			---- Is Equal To
			BEGIN
			IF @NameValue IS NOT NULL
				SET @sql = @sql + ' AND M.FirstName = @NameValue'  
			IF @LastName IS NOT NULL
				SET @sql = @sql + ' AND M.LastName = @LastName'	
			END
		END

		
	----Name: User
	IF @NameType = 'User' AND @NameValue IS NOT NULL
		BEGIN
		IF @FilterType IN ('Starts With', 'Contains', 'Ends With') 
			SET @sql = @sql + ' AND (SR.CreateBy LIKE'
							+ CASE WHEN @FilterType IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @NameValue'
							+ CASE WHEN @FilterType IN ('Starts With', 'Contains') THEN ' +CHAR(37)' ELSE '' END

							+ ' OR SR.ModifyBy LIKE'
							+ CASE WHEN @FilterType IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @NameValue'
							+ CASE WHEN @FilterType IN ('Starts With', 'Contains') THEN ' +CHAR(37)' ELSE '' END

							+ ' OR PO.ModifyBy LIKE'
							+ CASE WHEN @FilterType IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @NameValue'
							+ CASE WHEN @FilterType IN ('Starts With', 'Contains') THEN ' +CHAR(37)' ELSE '' END

							+ ' OR PO.ModifyBy LIKE'
							+ CASE WHEN @FilterType IN ('Contains', 'Ends With') THEN ' CHAR(37)+' ELSE '' END
							+ ' @NameValue'
							+ CASE WHEN @FilterType IN ('Starts With', 'Contains') THEN ' +CHAR(37)' ELSE '' END
							+ ' )'
		ELSE
			---- Is Equal To
			SET @sql = @sql + ' AND (SR.CreateBy = @NameValue'
							+ '   OR SR.ModifyBy = @NameValue'
							+ '   OR PO.CreateBy = @NameValue'
							+ '   OR PO.ModifyBy = @NameValue)'  
		END

		
	---- Date Range
	IF @Preset IS NOT NULL
	SET @sql = @sql + CASE @Preset WHEN 'Last 30 days' THEN ' AND DATEDIFF(M,SR.CreateDate,GETDATE()) <= 1'
								   WHEN 'Last 90 days' THEN ' AND DATEDIFF(M,SR.CreateDate,GETDATE()) <= 3'
								   ELSE ' AND DATEDIFF(WK,SR.CreateDate,GETDATE()) <= 1'
					  END
					  
	IF @Preset IS NULL AND @FromDate IS NOT NULL
	SET @sql = @sql + ' AND SR.CreateDate >= @FromDate'  

	IF @Preset IS NULL AND @ToDate IS NOT NULL
	SET @sql = @sql + ' AND SR.CreateDate <= @ToDate'	

	
	---- Clients
	IF ISNULL(@strClients,'') <> ''
	SET @sql = @sql + ' AND CL.ID IN (SELECT ID FROM @tmpClients)'


	---- Programs
	IF ISNULL(@strPrograms,'') <> ''
	SET @sql = @sql + ' AND P.ProgramID IN (SELECT ID FROM @tmpPrograms)'


	---- SR Statuses
	IF ISNULL(@strServiceRequestStatuses,'') <> ''
	SET @sql = @sql + ' AND SRS.ID IN (SELECT ID FROM @tmpServiceRequestStatuses)'


	---- Service types
	IF ISNULL(@strServiceTypes,'') <> ''
	SET @sql = @sql + ' AND PC.ID IN (SELECT ID FROM @tmpServiceTypes)'


	---- PurchaseOrder Statuses
	IF ISNULL(@strPOStatuses,'') <> ''
	SET @sql = @sql + ' AND PO.PurchaseOrderStatusID IN (SELECT ID FROM @tmpPOStatuses)'


	--- Special Flags
	IF @IsGOA IS NOT NULL
	SET @sql = @sql + ' AND PO.IsGOA = @IsGOA'

	IF @IsPossibleTow IS NOT NULL
	SET @sql = @sql + ' AND SR.IsPossibleTow = @IsPossibleTow'

	IF @IsRedispatched IS NOT NULL
	SET @sql = @sql + ' AND SR.IsRedispatched = @IsRedispatched'


	----Vehicle
	IF @VehicleType IS NOT NULL
	SET @sql = @sql + ' AND C.VehicleTypeID = @VehicleType'
	
	IF @VehicleYear IS NOT NULL
	SET @sql = @sql + ' AND C.VehicleYear = @VehicleYear'
	
	IF @VehicleMake IS NOT NULL
	SET @sql = @sql + ' AND (C.VehicleMake = @VehicleMake OR (@VehicleMake = ''Other'' AND C.VehicleMake = ''Other'' AND C.VehicleMakeOther = @VehicleMakeOther ))'
	
	IF @VehicleModel IS NOT NULL
	SET @sql = @sql + ' AND (C.VehicleModel = @VehicleModel OR (@VehicleModel = ''Other'' AND C.VehicleModel = ''Other'' AND C.VehicleModelOther = @VehicleModelOther ))'


	----Payment Types
	IF ISNULL(@PaymentByCheque,0) = 1 
	SET @sql = @sql + ' AND PO.IsPayByCompanyCreditCard = 0 AND PO.PurchaseOrderAmount > 0 '
	
	IF ISNULL(@PaymentByCard,0) = 1 
	SET @sql = @sql + ' AND PO.IsPayByCompanyCreditCard = 1 AND PO.PurchaseOrderAmount > 0 '

	IF ISNULL(@MemberPaid,0) = 1 
	SET @sql = @sql + ' AND PO.MemberServiceAmount = PO.PurchaseOrderAmount AND PO.PurchaseOrderAmount > 0 '


	SET @sql = @sql + ' OPTION (RECOMPILE)'
			
	---- DEBUG
	--SELECT @sql		
			

	INSERT INTO #Filtered
	EXEC sp_executesql @sql, 
		N'@UserID Uniqueidentifier, @IDType nvarchar(50), @IDValue nvarchar(50), 
		  @NameType nvarchar(50), @NameValue nvarchar(50), @LastName nvarchar(50), @FilterType nvarchar(50), 
		  @FromDate datetime, @ToDate datetime, @Preset nvarchar(50),
		  @IsGoa bit, @IsRedispatched BIT, @IsPossibleTow BIT, 
		  @VehicleType INT, @VehicleYear INT, 
		  @VehicleMake NVARCHAR(255), @VehicleMakeOther NVARCHAR(255), 
		  @VehicleModel NVARCHAR(255), @VehicleModelOther NVARCHAR(255), 
		  @PaymentByCheque BIT, @PaymentByCard BIT, @MemberPaid BIT, 
		  @tmpClients intTableType READONLY, @tmpPrograms intTableType READONLY, @tmpPOStatuses intTableType READONLY, 
		  @tmpServiceRequestStatuses intTableType READONLY, @tmpServiceTypes intTableType READONLY '
		, @UserID, @IDType, @IDValue, 
		  @NameType, @NameValue, @LastName, @FilterType, 
		  @FromDate, @ToDate, @Preset,
		  @IsGoa, @IsRedispatched, @IsPossibleTow, 
		  @VehicleType, @VehicleYear, 
		  @VehicleMake, @VehicleMakeOther, 
		  @VehicleModel, @VehicleModelOther, 
		  @PaymentByCheque, @PaymentByCard, @MemberPaid, 
		  @tmpClients, @tmpPrograms, @tmpPOStatuses, 
		  @tmpServiceRequestStatuses, @tmpServiceTypes	


	---- DEBUG:
	--SELECT 'Filtered', * FROM #Filtered
	
	---- Format the data [ Member name, vehiclemake, model, etc]

	;with CTEFormatted AS(
	SELECT	ROW_NUMBER() OVER (PARTITION BY RequestNumber ORDER BY POCreateDate DESC) AS RowNum, 
			RequestNumber,
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
			PaymentByCard,
			POCreateDate
			FROM	#Filtered R
	)
	INSERT INTO #Formatted(
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
			PaymentByCard)
				
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
	FROM	CTEFormatted 
	WHERE   RowNum = 1
	
	
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
	
	DROP TABLE #Filtered
	DROP TABLE #Formatted
	DROP TABLE #Sorted

END


GO


