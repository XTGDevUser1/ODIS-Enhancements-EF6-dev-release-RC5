IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_API_ServiceRequest_History_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_API_ServiceRequest_History_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_API_ServiceRequest_History_List] @ProgramID = "97",@MemberID = '9030686', @MembershipID = "5028652", @userID = 'beb5fa18-50ce-499d-bb62-ffb9585242ab'
-- EXEC [dbo].[dms_API_ServiceRequest_History_List] @ProgramID = "458",@MemberID = '9030686',@MembershipID = "5028652", @userID = 'c8888f91-5462-449d-98f7-1f8372d731f4', @sourceSystem='MemberMobile'

CREATE PROCEDURE [dbo].[dms_API_ServiceRequest_History_List]( 
	@MemberID	NVARCHAR(25)	= NULL,
	@MembershipID	NVARCHAR(25)	= NULL,
	@ProgramID	INT				= NULL,
	@StartDate	DateTime		= NULL,
	@EndDate		DateTime	= NULL,
	@userID UNIQUEIDENTIFIER	= NULL,
	@sourceSystem NVARCHAR(100) = NULL
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
		ServiceLocationAddress NVARCHAR(255) NULL,
		ServiceLocationDescription NVARCHAR(255) NULL,
		DestinationAddress NVARCHAR(255) NULL,
		DestinationDescription NVARCHAR(255) NULL,	 
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
		POCreateDate DATETIME NULL,
		TrackerID UNIQUEIDENTIFIER NULL,
		IsShowOnMobile BIT NULL,
		MapSnapshot NVARCHAR(MAX) NULL
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
		ServiceLocationAddress NVARCHAR(255) NULL,
		ServiceLocationDescription NVARCHAR(255) NULL,
		DestinationAddress NVARCHAR(255) NULL,
		DestinationDescription NVARCHAR(255) NULL,	 	 
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
		PaymentByCard BIT NULL,		
		TrackerID UNIQUEIDENTIFIER NULL,
		IsShowOnMobile BIT NULL,
		MapSnapshot NVARCHAR(MAX) NULL
	)

	IF @userID IS NULL
	BEGIN
		SELECT *
		FROM	#Formatted
		RETURN;
	END

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
	-- Location  
	SET @sql = @sql + ' ,SR.ServiceLocationAddress +'' ''+ SR.ServiceLocationCountryCode AS [ServiceLocationAddress]'
	SET @sql = @sql + ' ,SR.ServiceLocationDescription'
		-- Destination
	SET @sql = @sql + ' ,SR.DestinationAddress +'' ''+ SR.DestinationCountryCode AS [DestinationAddress]'
	SET @sql = @sql + ' ,SR.DestinationDescription'
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
	SET @sql = @sql + ' ,SR.TrackerID'		
	SET @sql = @sql + ' ,SR.IsShowOnMobile'
	SET @sql = @sql + ' ,CASE WHEN SR.ServiceRequestStatusID < 4 THEN SR.MapSnapshot ELSE NULL END AS MapSnapshot'	 	
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
	
	-- Exclude IsShowOnMobile = 0 records if SourceSytem = MemberMobile.
	IF @sourceSystem = 'MemberMobile'
	BEGIN
		SET @sql = @sql + ' AND ISNULL(SR.IsShowOnMobile,0) = 1'  
	END
	---- ID Value
	IF @MembershipID IS NOT NULL
	SET @sql = @sql + ' AND MS.MembershipNumber = @MembershipID'  
	

	IF @MemberID IS NOT NULL
	SET @sql = @sql + ' AND (M.ClientMemberKey = @MemberID )'  
	
	IF @ProgramID IS NOT NULL
	SET @sql = @sql + ' AND P.ProgramID = @ProgramID'  

	IF @StartDate IS NOT NULL
	SET @sql = @sql + ' AND SR.CreateDate > @StartDate' 

	IF @EndDate IS NOT NULL
	SET @sql = @sql + ' AND SR.CreateDate < @EndDate' 

	SET @sql = @sql + ' OPTION (RECOMPILE)'
			
	---- DEBUG
	--SELECT @sql		
			

	INSERT INTO #Filtered
	EXEC sp_executesql @sql, 
		N'@UserID Uniqueidentifier, @MembershipID nvarchar(25),@MemberID nvarchar(25), @ProgramID INT, 
		  @StartDate datetime, @EndDate datetime'
		, @UserID, @MembershipID, @MemberID, @ProgramID, 
		  @StartDate, @EndDate	


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
			ServiceLocationAddress,
			ServiceLocationDescription,
			DestinationAddress,
			DestinationDescription,	
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
			POCreateDate,
			R.TrackerID,
			R.IsShowOnMobile,
			R.MapSnapshot
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
			ServiceLocationAddress,
			ServiceLocationDescription,
			DestinationAddress,
			DestinationDescription,	
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
			PaymentByCard,
			TrackerID,
			IsShowOnMobile,
			MapSnapshot)
				
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
			ServiceLocationAddress,
			ServiceLocationDescription,
			DestinationAddress,
			DestinationDescription,	
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
			PaymentByCard,
			TrackerID,
			IsShowOnMobile,
			MapSnapshot
	FROM	CTEFormatted 
	WHERE   RowNum = 1

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
			ServiceLocationAddress,
			ServiceLocationDescription,
			DestinationAddress,
			DestinationDescription,	
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
			PaymentByCard,
			TrackerID,
			IsShowOnMobile,
			MapSnapshot
	FROM	#Formatted F
	ORDER BY F.CreateDate DESC
	
	DROP TABLE #Filtered
	DROP TABLE #Formatted

END


GO
