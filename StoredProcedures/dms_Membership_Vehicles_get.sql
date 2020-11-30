IF EXISTS (SELECT * FROM dbo.sysobjects 
			WHERE id = object_id(N'[dbo].[dms_Membership_Vehicles_get]')   		AND type in (N'P', N'PC')) 
BEGIN
	DROP PROCEDURE [dbo].[dms_Membership_Vehicles_get] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 
-- EXEC [dms_Membership_Vehicles_get] 832
-- EXEC [dms_Membership_Vehicles_get] 832
CREATE PROCEDURE [dbo].[dms_Membership_Vehicles_get](   
 
 @membershipID INT  
)   
AS  
BEGIN  
 DECLARE @tmpVehicle TABLE ( 
 [RowNumber] [int] NOT NULL, 
 [ID] [int] NULL,  
 [VehicleCategoryID] [int] NULL,  
 [RVTypeID] [int] NULL,  
 [VehicleTypeID] [int] NULL,  
 [VehicleTypeName] NVARCHAR(100) NULL,  
 [MembershipID] [int] NULL,  
 [MemberID] [int] NULL,  
 [VIN] [nvarchar](50) NULL,  
 [Year] [nvarchar](4) NULL,  
 [Make] [nvarchar](50) NULL,  
 [MakeOther] [nvarchar](50) NULL,  
 [Model] [nvarchar](50) NULL,  
 [ModelOther] [nvarchar](50) NULL,  
 [LicenseNumber] [nvarchar](50) NULL,  
 [LicenseState] [nvarchar](2) NULL,  
 [LicenseCountry] INT NULL,
 [Description] [nvarchar](255) NULL,  
 [Color] [nvarchar](50) NULL,  
 [Length] [int] NULL,  
 [Height] [nvarchar](5) NULL,  
 [TireSize] [nvarchar](50) NULL,  
 [TireBrand] [nvarchar](50) NULL,  
 [TireBrandOther] [nvarchar](50) NULL,  
 [TrailerTypeID] [int] NULL,  
 [TrailerTypeOther] [nvarchar](50) NULL,  
 [SerialNumber] [nvarchar](50) NULL,  
 [NumberofAxles] [int] NULL,  
 [HitchTypeID] [int] NULL,  
 [HitchTypeOther] [nvarchar](50) NULL,  
 [TrailerBallSize] [nvarchar](50) NULL,  
 [TrailerBallSizeOther] [nvarchar](50) NULL,  
 [Transmission] [nvarchar](100) NULL,  
 [Engine] [nvarchar](100) NULL,  
 [GVWR] [int] NULL,  
 [Chassis] [nvarchar](100) NULL,  
 [PurchaseDate] [datetime] NULL,  
 [WarrantyStartDate] [datetime] NULL,  
 [StartMileage] [int] NULL,  
 [EndMileage] [int] NULL,  
 [MileageUOM] [nvarchar](50) NULL,  
 [IsFirstOwner] [bit] NULL,  
 [IsSportUtilityRV] [bit] NULL,  
 [Source] [nvarchar](50) NULL,  
 [IsActive] [bit] NOT NULL,  
 [CreateBatchID] [int] NULL,  
 [CreateDate] [datetime] NULL,  
 [CreateBy] [nvarchar](50) NULL,  
 [ModifyBatchID] [int] NULL,  
 [ModifyDate] [datetime] NULL,  
 [ModifyBy] [nvarchar](50) NULL,  
 FromCase INT NULL  
 ) 
 
 INSERT INTO @tmpVehicle
 SELECT  
 0,
 V.[ID],  
 [VehicleCategoryID],  
 [RVTypeID],  
 [VehicleTypeID],  
 VT.Name As VehicleTypeName,  
 [MembershipID],  
 [MemberID],  
 [VIN],  
 [Year],  
 Case Make WHEN 'Other' THEN MakeOther ELSE MAKE END AS 'Make', 
 [MakeOther],  
 Case Model WHEN 'Other' THEN ModelOther ELSE Model END AS 'Model', 
 [ModelOther],  
 [LicenseState]+'-'+[LicenseNumber] AS LicenseNumber,  
 [LicenseState],   
 [VehicleLicenseCountryID] AS LicenseCountry,
 V.[Description],  
 [Color],  
 [Length],  
 [Height],  
 [TireSize],  
 [TireBrand],  
 [TireBrandOther],  
 [TrailerTypeID],  
 [TrailerTypeOther],  
 [SerialNumber],  
 [NumberofAxles],  
 [HitchTypeID],  
 [HitchTypeOther],  
 [TrailerBallSize],  
 [TrailerBallSizeOther],  
 [Transmission],  
 [Engine],  
 [GVWR],  
 [Chassis],  
 [PurchaseDate],  
 [WarrantyStartDate],  
 [StartMileage],  
 [EndMileage],  
 [MileageUOM],  
 [IsFirstOwner],  
 [IsSportUtilityRV],  
 [Source],  
 V.[IsActive],  
 [CreateBatchID],  
 [CreateDate],  
 [CreateBy],  
 [ModifyBatchID],  
 [ModifyDate],  
 [ModifyBy],    
 0 AS FromCase  
 FROM Vehicle v   
 LEFT JOIN VehicleType VT on v.VehicleTypeID = VT.ID  
 WHERE v.MembershipID= @membershipID 
 AND v.IsActive = 1  
 ORDER BY   
 v.Year desc   
 
 
 SELECT 
 [ID],  
 [VehicleCategoryID] ,  
 [RVTypeID] ,  
 [VehicleTypeID] ,  
 [VehicleTypeName] ,  
 [MembershipID] ,  
 [MemberID] ,  
 [VIN] ,  
 [Year] ,  
 [Make],  
 [MakeOther] ,  
 [Model]  ,  
 [ModelOther] ,  
 [LicenseNumber],  
 [LicenseState],  
 [LicenseCountry],
 [Description] ,  
 [Color] ,  
 [Length] ,  
 [Height] ,  
 [TireSize] ,  
 [TireBrand] ,  
 [TireBrandOther] ,  
 [TrailerTypeID] ,  
 [TrailerTypeOther] ,  
 [SerialNumber] ,  
 [NumberofAxles] ,  
 [HitchTypeID] ,  
 [HitchTypeOther] ,  
 [TrailerBallSize] ,  
 [TrailerBallSizeOther] ,  
 [Transmission]  ,  
 [Engine]  ,  
 [GVWR] ,  
 [Chassis] ,  
 [PurchaseDate] ,  
 [WarrantyStartDate] ,  
 [StartMileage] ,  
 [EndMileage] ,  
 [MileageUOM] ,  
 [IsFirstOwner] ,  
 [IsSportUtilityRV],  
 [Source] ,  
 [IsActive] ,  
 [CreateBatchID],  
 [CreateDate] ,  
 [CreateBy] ,  
 [ModifyBatchID] ,  
 [ModifyDate] ,  
 [ModifyBy] ,  
 FromCase  
  FROM @tmpVehicle  
  ORDER BY [Year] DESC
 
 
END
GO

