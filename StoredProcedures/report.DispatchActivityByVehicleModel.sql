USE [DMS]
GO

/****** Object:  StoredProcedure [report].[DispatchActivityByVehicleModel]    Script Date: 2/8/2016 6:32:32 PM ******/
DROP PROCEDURE [report].[DispatchActivityByVehicleModel]
GO

/****** Object:  StoredProcedure [report].[DispatchActivityByVehicleModel]    Script Date: 2/8/2016 6:32:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--exec report.DispatchActivityByVehicleModel_NEW '1/1/2016','1/21/2016','165,266','2015,2016','F-650,F-750',1

CREATE PROCEDURE [report].[DispatchActivityByVehicleModel] (
	@BeginDate datetime
	,@EndDate datetime
	,@Programs nvarchar(max)
	,@VehicleYears nvarchar(max)
	,@VehicleModels nvarchar(max)
	,@DispatchOnly bit
)
AS
BEGIN

	----DEBUG
	--DECLARE
	--	@BeginDate datetime
	--	,@EndDate datetime
	--	,@Programs nvarchar(max)
	--	,@VehicleYears nvarchar(max)
	--	,@VehicleModels nvarchar(max)
	--	,@DispatchOnly bit 

	--SET @BeginDate = '1/1/2016'
	--SET @EndDate = '1/20/2016'
	--SET @Programs = '165,266'
	--SET @VehicleYears = '2015, 2016'
	--SET @VehicleModels = 'F-650,F-750'
	--SET @DispatchOnly = 1
	
	---- Hard-coded for Ford ...for now
	DECLARE @ClientID int
	DECLARE @VehicleMakes nvarchar(max)
	SET @ClientID = (SELECT ID FROM Client WHERE Name = 'Ford')
	SET @VehicleMakes = 'Ford'

	---- Table variables for year, make, model lists
	DECLARE @VehicleYearsList TABLE ([VehicleYear] nvarchar(20))
	INSERT INTO @VehicleYearsList
	SELECT Item From dbo.fnSplitString(@VehicleYears,',')

	DECLARE @VehicleMakeList TABLE ([VehicleMake] nvarchar(20))
	INSERT INTO @VehicleMakeList
	SELECT Item From dbo.fnSplitString(@VehicleMakes,',')

	DECLARE @VehicleModelList TABLE ([VehicleModel] nvarchar(20))
	INSERT INTO @VehicleModelList
	SELECT Item From dbo.fnSplitString(@VehicleModels,',')


	Select 
		Activity.ClientName
		,Activity.ProgramName
		,CASE WHEN Activity.PurchaseOrderNumber IS NOT NULL THEN 'PO: ' + Activity.PurchaseOrderNumber + CASE WHEN Activity.PurchaseOrderStatus = 'Cancelled' THEN ' (Cancelled)' ELSE '' END
			ELSE 'SR: ' + CONVERT(nvarchar(50), Activity.ServiceRequest) 
			END [Event]
		,CASE WHEN Activity.PurchaseOrderNumber IS NOT NULL THEN Activity.PurchaseOrderIssueDate 
			ELSE Activity.ServiceRequestDate 
			END EventDate
		--,Activity.ServiceRequest
		--,Activity.ServiceRequestDate
		--,Activity.PurchaseOrderNumber
		--,Activity.PurchaseOrderIssueDate
		--,Activity.PurchaseOrderStatus
		,Activity.EventContactName
		,Activity.ContactPhoneNumber
		,Activity.CustomerNumber
		,Activity.AccountName
		,Activity.VehicleVIN
		
		--,Activity.VehicleYear
		--,Activity.VehicleMake
		--,Activity.VehicleModel
		
		,Activity.VehicleDescription
		,Activity.[Service]
		,Activity.ServiceLocation
		,Activity.TowingDestination
		
	FROM (
		SELECT 
			prog.ClientID
			,client.Name ClientName
			,prog.Name ProgramName
			,sr.ID ServiceRequest
			,CONVERT(nvarchar(50),sr.CreateDate,101) ServiceRequestDate
			,po.PurchaseOrderNumber
			,CONVERT(nvarchar(50),po.IssueDate,101) PurchaseOrderIssueDate
			,pos.Name PurchaseOrderStatus

			---- Member / Person	  
			,COALESCE(ms.MembershipNumber,ms.ClientReferenceNumber) CustomerNumber
			,dbo.fnc_ProperCase(COALESCE(c.ContactFirstName + ' ', '') + COALESCE(c.ContactLastName,'')) EventContactName
			,c.ContactPhoneNumber
			,dbo.fnc_ProperCase(COALESCE(mbr.FirstName + ' ', '') + COALESCE(mbr.LastName,'')) AccountName

			---- Vehicle
			,UPPER(c.VehicleVIN) VehicleVIN	

			,RTRIM(c.VehicleYear) VehicleYear	
			,RTRIM(CASE WHEN c.VehicleMake = 'Other' THEN c.VehicleMakeOther ELSE c.VehicleMake END) VehicleMake 
			,RTRIM(CASE WHEN c.VehicleModel = 'Other' THEN c.VehicleModelOther ELSE c.VehicleModel END) VehicleModel	

			,RTRIM(COALESCE(c.VehicleYear + ' ','')) +	
			 RTRIM(CASE WHEN c.VehicleMake = 'Other' THEN COALESCE(c.VehicleMakeOther + ' ','') ELSE COALESCE(c.VehicleMake + ' ','') END) + 
			 RTRIM(CASE WHEN c.VehicleModel = 'Other' THEN COALESCE(c.VehicleModelOther,'') ELSE COALESCE(c.VehicleModel,'') END) VehicleDescription	

			,CASE WHEN ServiceCode.ServiceCode IS NOT NULL THEN ServiceCode.ServiceCode
				  END [Service]
			,CASE WHEN ServiceCode.ServiceCode IS NOT NULL THEN
					(CASE WHEN COALESCE(sr.ServiceLocationCity, sr.ServiceLocationStateProvince, sr.ServiceLocationPostalCode) IS NOT NULL THEN '' ELSE '' END) +
					(CASE WHEN sr.ServiceLocationCity IS NOT NULL THEN sr.ServiceLocationCity ELSE '' END) +
					(CASE WHEN sr.ServiceLocationStateProvince IS NOT NULL THEN ', ' + sr.ServiceLocationStateProvince ELSE '' END) +
					(CASE WHEN sr.ServiceLocationPostalCode IS NOT NULL THEN ', ' + sr.ServiceLocationPostalCode ELSE '' END) 
				  ELSE 'N/A'
				  END ServiceLocation
			 ,COALESCE(po.DestinationDescription + ';','') + COALESCE(po.DestinationAddress,'') TowingDestination
			 ,ISNULL(c.ReferenceNumber,'') ClientReferenceNumber
		FROM Program prog
		JOIN Client client with (nolock) on client.ID = prog.ClientID
		JOIN [Case] c on c.ProgramID = prog.ID
		JOIN ServiceRequest sr on sr.CaseID = c.ID 
		JOIN ServiceRequestStatus srs on srs.ID = sr.ServiceRequestStatusID AND srs.Name in ('Complete', 'Cancelled')
		
		JOIN @VehicleYearsList vy ON vy.VehicleYear = c.VehicleYear
		JOIN @VehicleMakeList vmake ON vmake.VehicleMake = RTRIM(CASE WHEN c.VehicleMake = 'Other' THEN c.VehicleMakeOther ELSE c.VehicleMake END)
		JOIN @VehicleModelList vmodel ON vmodel.VehicleModel = RTRIM(CASE WHEN c.VehicleModel = 'Other' THEN c.VehicleModelOther ELSE c.VehicleModel END)
		
		LEFT OUTER JOIN PurchaseOrder po on po.ServiceRequestID = sr.ID and po.IsActive = 1 and po.IsGOA = 0
		LEFT OUTER JOIN vw_ServiceCode ServiceCode with (nolock) on ServiceCode.ServiceRequestID = sr.ID and isnull(ServiceCode.PurchaseOrderID,0) = isnull(po.id,0)
		LEFT OUTER JOIN PurchaseOrderStatus pos on pos.ID = po.PurchaseOrderStatusID AND pos.Name in ('Issued', 'Cancelled')
		LEFT OUTER JOIN DMS.dbo.Member mbr on mbr.ID = c.MemberID
		LEFT OUTER JOIN DMS.dbo.Membership ms on ms.ID = mbr.MembershipID
		
		Where((SR.CreateDate >= @BeginDate AND SR.CreateDate < DATEADD(dd,1,@EndDate))
			OR (PO.IssueDate >= @BeginDate AND PO.IssueDate < DATEADD(dd,1,@EndDate))
			)
			AND Client.ID = @ClientID
		) Activity 
	WHERE 1=1 
	ORDER BY ClientName, ServiceRequestDate

END

GO


