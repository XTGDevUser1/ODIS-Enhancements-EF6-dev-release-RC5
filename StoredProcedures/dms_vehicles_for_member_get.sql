IF EXISTS (SELECT * FROM dbo.sysobjects 
			WHERE id = object_id(N'[dbo].[dms_vehicles_for_member_get]')   		AND type in (N'P', N'PC')) 
BEGIN
	DROP PROCEDURE [dbo].[dms_vehicles_for_member_get] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 
-- EXEC [dms_vehicles_for_member_get] 5,840,832
CREATE PROCEDURE [dbo].[dms_vehicles_for_member_get](   
 @programID INT,  
 @memberID INT,  
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
  
 DECLARE @pullVehiclesFromCaseHistory NVARCHAR(100)  
 SET @pullVehiclesFromCaseHistory = NULL  
  
 
SELECT	@pullVehiclesFromCaseHistory = Value
FROM	ProgramConfiguration pc
JOIN	fnc_GetPRogramConfigurationForProgram(@programid, 'Vehicle') F ON pc.ID = F.ProgramConfigurationIDWHERE	pc.Name = 'PullVehiclesFromCaseHistory'
;WITH vehicleTmp
AS
(
 SELECT  
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
 [VehicleLicenseCountryID],
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
   AND (isnull(v.MemberID, '') = ''  
    OR v.MemberID = @memberID)  
   AND v.IsActive = 'TRUE'  
 --ORDER BY   
  -- v.Year desc   
 UNION ALL  
 SELECT   
    C.ID,   
    VehicleCategoryID as CategoryID  
  , VehicleRVTYpeID as RVTypeID  
  , VehicleTypeID as TypeID  
  , VT.Name As VehicleTypeName  
  , NULL AS MembershipID  
  , MemberID  
  , VehicleVIN as VIN  
  , VehicleYear as [Year]  
  , Case VehicleMake WHEN 'Other' THEN VehicleMakeOther ELSE VehicleMake END AS 'Make' 
  , VehicleMakeOther as MakeOther  
  , Case VehicleModel WHEN 'Other' THEN VehicleModelOther ELSE VehicleModel END AS 'Model'  
  , VehicleModelOther as ModelOther    
  , VehicleLicenseState + '-'+ VehicleLicenseNumber as LicenseNumber  
  , VehicleLicenseState as LicenseState  
  , VehicleLicenseCountryID
  , VehicleDescription as Description  
  , VehicleColor as Color  
  , VehicleLength as Length  
  , VehicleHeight as Height  
  , VehicleTireSize as TireSize  
  , VehicleTireBrand AS TireBrand  
  , VehicleTireBrandOther AS TireBrandOther  
  , TrailerTypeID  
  , TrailerTypeOther  
  , TrailerSerialNumber AS SerialNumber  
  , TrailerNumberofAxles AS NumberOfAxles  
  , TrailerHitchTypeID AS HitchTypeID  
  , TrailerHitchTypeOther AS HitchTypeOther  
  , TrailerBallSize  
  , TrailerBallSizeOther    
  , VehicleTransmission as Transmission  
  , VehicleEngine as Engine  
  , VehicleGVWR as GVWR  
  , VehicleChassis as Chassis  
  , VehiclePurchaseDate as PurchaseDate  
  , VehicleWarrantyStartDate as WarrantyStartDate  
  , VehicleStartMileage as BeginMileage  
  , VehicleEndMileage as EndMileage  
  , VehicleMileageUOM as MileageUOM  
  , VehicleIsFirstOwner as IsFirstOwner  
  , VehicleIsSportUtilityRV as IsSportUtilityRV   
  , VehicleSource as Source  
  , CAST(1 AS BIT) As IsActive  
  , 0 AS CreateBatchID  
  , CreateDate  
  , CreateBy  
  , 0 AS ModifyBatchID  
  , (Isnull(ModifyDate,CreateDate)) as ModifyDate  
  , ModifyBy  
  , 1 AS FromCase  
 FROM [Case] C  
 LEFT JOIN VehicleType VT ON C.VehicleTypeID = VT.ID  
 WHERE @pullVehiclesFromCaseHistory = 'Yes'  
 AND  VehicleID is null   
 AND  MemberID = @memberID  
 AND  COALESCE(VehicleMake,VehicleModel,VehicleYear,'') <>''  
-- ORDER BY [YEAR] DESC 
 )
 INSERT INTO @tmpVehicle 
 Select ROW_NUMBER() 
			OVER(PARTITION BY [Year],Make,MakeOther,Model,ModelOther,Color,VIN,LicenseState,VehicleLicenseCountryID,LicenseNumber ORDER BY FromCase ) AS RowNumber, 
			* from 
			vehicleTmp ORDER BY [YEAR] DESC
   
   
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
  where [RowNumber]=1 Order by [Year] desc
 
END  