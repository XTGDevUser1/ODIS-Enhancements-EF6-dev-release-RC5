/****** Object:  StoredProcedure [dbo].[dms_ServiceRequestEstimate]    Script Date: 05/21/2016 18:32:06 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ServiceRequestEstimate]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_ServiceRequestEstimate]
GO

/****** Object:  StoredProcedure [dbo].[dms_ServiceRequestEstimate]    Script Date: 05/21/2016 18:32:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 /*
 EXEC [dms_ServiceRequestEstimate] 1605
 */
CREATE PROCEDURE [dbo].[dms_ServiceRequestEstimate]
(
	@ServiceRequestID INT
)
AS
BEGIN

DECLARE @ServiceTimeCostEstimate money,
	@ProductCategory nvarchar(50),
	@NonMemberMarkupRate money
	
Set @NonMemberMarkupRate = 1.15

---- If Member Added/Registered OR Member Expired then use Non-Member Markup Rate
Select @NonMemberMarkupRate = Case When ss.Name = 'Dispatch' OR m.ExpirationDate < c.CreateDate Then @NonMemberMarkupRate Else 1 End 
From ServiceRequest sr 
Join [Case] c on c.ID = sr.CaseID
Join Member m on m.ID = c.MemberID
Join SourceSystem ss on ss.ID = m.SourceSystemID
Where sr.ID = @ServiceRequestID
	
Select @ProductCategory = pc.Name
From ServiceRequest sr 
Join ProductCategory pc on pc.ID = sr.ProductCategoryID
Where sr.ID = @ServiceRequestID

If @ProductCategory = 'Info' Or @ProductCategory IS NULL
	Select 0.00 As Estimate, 0.00 As EstimatedTimeCost
Else If @ProductCategory IN ('Tech','Concierge')
	Select 50.00 As Estimate, 0.00 As EstimatedTimeCost
Else
	BEGIN
	
	Select 
	--sr.ID, c.ProgramID
	--, sr.ProductCategoryID
	--, sr.VehicleCategoryID,
	@ServiceTimeCostEstimate = COALESCE(ProgramTimeEst.ServiceTimeCostEstimate, ClientTimeEst.ServiceTimeCostEstimate) * @NonMemberMarkupRate
	From [Case] c
	Join Program p on p.ID = c.ProgramID
	Join ServiceRequest sr on sr.CaseID = c.ID
	Left Join ClientProgramServiceTimeEstimate ProgramTimeEst on 
		ProgramTimeEst.ProgramID = c.ProgramID 
		and ProgramTimeEst.ProductCategoryID = sr.ProductCategoryID 
		and ProgramTimeEst.VehicleCategoryID = sr.VehicleCategoryID
	Left Join ClientProgramServiceTimeEstimate ClientTimeEst on 
		ClientTimeEst.ClientID = p.ClientID 
		and	ClientTimeEst.ProductCategoryID = sr.ProductCategoryID 
		and ClientTimeEst.VehicleCategoryID = sr.VehicleCategoryID
		and ClientTimeEst.ProgramID IS NULL
	Where sr.ID = @ServiceRequestID
	--sr.CreateDate > '2/1/2016'
	--and sr.PrimaryProductID is not NULL and sr.PrimaryProductID NOT IN (202,203,204)
	--and c.ProgramID = 537

	--Select ProductCategoryID, VehicleCategoryID, ServiceTimeCostEstimate From ClientProgramServiceTimeEstimate Where 


	--Select ServiceMiles from ServiceRequest where ID = @ServiceRequestID
	DECLARE @ISPSelectionFinalResults TABLE (  
	[VendorID] [int] NOT NULL,  
	[VendorLocationID] [int] NOT NULL,  
	[VendorLocationVirtualID] [int] NULL,  
	[Latitude] [decimal](10, 7) NULL,  
	[Longitude] [decimal](10, 7) NULL,  
	[VendorName] [nvarchar](255) NULL,  
	[VendorNumber] [nvarchar](50) NULL,  
	[Source] [varchar](8) NOT NULL,  
	[ContractStatus] [nvarchar](50) NOT NULL,  
	[Address1] [nvarchar](100) NULL,  
	[Address2] [nvarchar](100) NULL,  
	[City] [nvarchar](100) NULL,  
	[StateProvince] [nvarchar](10) NULL,  
	[PostalCode] [nvarchar](20) NULL,  
	[CountryCode] [nvarchar](2) NULL,  
	[DispatchPhoneNumber] [nvarchar](50) NULL,  
	[AlternateDispatchPhoneNumber] [nvarchar](50) NULL, -- TFS: 105
	[FaxPhoneNumber] [nvarchar](50) NULL,   
	[OfficePhoneNumber] [nvarchar](50) NULL,  
	[CellPhoneNumber] [nvarchar](50) NULL, -- CR : 1226  
	[AdministrativeRating] [int] NULL,  
	[InsuranceStatus] [varchar](11) NOT NULL,  
	[BusinessHours] [nvarchar](100) NOT NULL,  
	[PaymentTypes] [nvarchar] (100) NULL,    
	[Comment] [nvarchar](2000) NULL,  
	[ProductID] [int] NOT NULL,  
	[ProductName] [nvarchar](50) NULL,  
	[ProductRating] [decimal](5, 2) NULL,  
	[EnrouteMiles] [float] NULL,  
	[EnrouteTimeMinutes] [int] NULL,  
	[ServiceMiles] [decimal](10, 2) NULL,  
	[ServiceTimeMinutes] [int] NULL,  
	[ReturnMiles] [float] NULL,  
	[ReturnTimeMinutes] [int] NULL,  
	[EstimatedHours] [float] NULL,  
	[BaseRate] [money] NULL,  
	[HourlyRate] [money] NULL,  
	[EnrouteRate] [money] NULL,  
	[EnrouteFreeMiles] [int] NULL,  
	[ServiceRate] [money] NULL,  
	[ServiceFreeMiles] [int] NULL,  
	[EstimatedPrice] [float] NULL,  
	[WiseScore] [float] NULL,  
	[CallStatus] [varchar](9) NOT NULL,  
	[RejectReason] [nvarchar](255) NULL,  
	[RejectComment] [nvarchar](max) NULL,  
	[IsPossibleCallback] [bit] NOT NULL,  
	[AllServices] [NVARCHAR](MAX) NULL,  
	[ProductSearchRadiusMiles] [int] NULL,  
	[IsInProductSearchRadius] [bit] NULL,
	[IsPreferred] [int] NULL  
	) 

	INSERT INTO @ISPSelectionFinalResults
	EXEC [dbo].[dms_ISPSelection_get]  @ServiceRequestID,NULL,NULL,NULL,75,NULL,NULL,NULL,0,'Location',NULL

	Select 
		--AVG(EstimatedPrice), @ServiceTimeCostEstimate, 
		ISNULL( CONVERT(decimal(10,2), ROUND(AVG(EstimatedPrice) + ISNULL(@ServiceTimeCostEstimate,0.0),0)),0) As Estimate
		,ISNULL(@ServiceTimeCostEstimate,0.0) EstimatedTimeCost
	FROM ISPSelectionLog ISPLog	 
	WHERE ServiceRequestID = @ServiceRequestID
	AND LogTime = (
		SELECT MAX(LogTime) 
		FROM ISPSelectionLog
		WHERE ServiceRequestID = @ServiceRequestID)
	AND ISPLog.SelectionOrder <= 5
	
	END


END
GO

