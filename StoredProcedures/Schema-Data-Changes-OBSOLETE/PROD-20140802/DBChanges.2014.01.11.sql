
--===========================================
-- Database Script for Hagerty Integration
--===========================================
--
-- Steps:
-- 1 - Insert new Event records
-- 2 - Insert new ApplicationConfigration records for new Hagerty Web Service 
-- 3 - Insert new SourceSystem value for HagertyPlusService
-- 4 - Insert new Program records 
-- 5 - Create new HagertyProgramMap table and insert records



-- SETP 1 =============================
--****** Insert below two new events for Hagerty Plus Service call ****--
INSERT INTO [Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES
           (1
           ,2
           ,'RetrieveHagertyMember'
           ,'Retrieved Hagerty Member information'
           ,0
           ,1
           ,Null
           ,GetDate())
--GO


INSERT INTO [Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES
           (1
           ,2
           ,'InsertOrUpdateHagertyMember'
           ,'InsertOrUpdateHagertyMemberInformation'
           ,1
           ,1
           ,Null
           ,GetDate())
--GO

--select * from ApplicationConfigurationCategory

-- SETP 1 =============================
--***** Insert a new record for Hagerty Plus service *******---- 
INSERT INTO [ApplicationConfigurationCategory]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('Hagerty Plus'
           ,'Hagerty Member Lookup Service'
           ,NULL
           ,1)
--GO


--***** Insert below new records for Hagerty Web service User name, Password, and URL ****---

INSERT INTO [ApplicationConfiguration]
           ([ApplicationConfigurationTypeID]
           ,[ApplicationConfigurationCategoryID]
           ,[ControlTypeID]
           ,[DataTypeID]
           ,[Name]
           ,[Value]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           (2
           ,12
           ,null
           ,null
           ,'HagertyPlusServiceUserName'
           ,'HPlusProdNMC'
           ,Getdate()
           ,null
           ,null
           ,null)
--GO


INSERT INTO [ApplicationConfiguration]
           ([ApplicationConfigurationTypeID]
           ,[ApplicationConfigurationCategoryID]
           ,[ControlTypeID]
           ,[DataTypeID]
           ,[Name]
           ,[Value]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           (2
           ,12
           ,null
           ,null
           ,'HagertyPlusServicePassword'
           ,'G%jvwc4x4BcazW'
           ,Getdate()
           ,null
           ,null
           ,null)
--GO


INSERT INTO [ApplicationConfiguration]
           ([ApplicationConfigurationTypeID]
           ,[ApplicationConfigurationCategoryID]
           ,[ControlTypeID]
           ,[DataTypeID]
           ,[Name]
           ,[Value]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           (2
           ,12
           ,null
           ,null
           ,'HagertyPlusServiceURI'
           ,'https://services.hagerty.com/B2B/SecondaryHPlusService?singleWsdl'
           ,Getdate()
           ,null
           ,null
           ,null)
--GO

-- SETP 3 =============================
--********** Insert below new record into SourceSystem table for Hagerty Plus Web service ******----

INSERT INTO [SourceSystem]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('HagertyPlusService'
           ,'HagertyPlus Service'
           ,7
           ,1)
--GO


-- SETP 4 =============================
--********* Insert new programs and related entires for Hagerty cutover *********-----

DECLARE @SourceProgramID int

-- Program: Hagerty - Standard (Level 2) **
SELECT	@SourceProgramID = (SELECT ID FROM Program WHERE Name = 'Hagerty - Standard (Level 2)')

-- Program
 IF NOT EXISTS(SELECT * FROM Program WHERE Name = 'Hagerty - Standard (Level 2) **')
	BEGIN
		INSERT INTO Program
		(
			ParentProgramID,
			ClientID,
			Code,
			Name,
			Description,
			IsServiceGuaranteed,
			CallFee,
			DispatchFee,
			IsActive,
			IsAudited,
			IsClosedLoopAutomated,
			IsGroup,
			LegacyType,
			LegacyCode,
			CreateDate,
			CreateBy,
			ModifyDate,
			ModifyBy,
			IsWebRegistrationEnabled
		)
		SELECT 
			(SELECT ID FROM Program WHERE Name = 'Hagerty'),
			(SELECT ID From Client WHERE Name = 'Hagerty'),
			'HAGERTY_N_2',
			'Hagerty - Standard (Level 2) **',
			'Hagerty - Standard (Level 2) **',
			IsServiceGuaranteed,
			CallFee,
			DispatchFee,
			0,
			IsAudited,
			IsClosedLoopAutomated,
			IsGroup,
			LegacyType,
			LegacyCode,
			getdate(),
			'System',
			ModifyDate,
			ModifyBy,
			IsWebRegistrationEnabled	
		FROM	Program
		WHERE	ID = @SourceProgramID
	END

			
DECLARE @DestinationProgramID int
SELECT	@DestinationProgramID = (SELECT ID FROM Program WHERE Name = 'Hagerty - Standard (Level 2) **')

-- PhoneSystemConfiguration
if not exists(Select * from PhoneSystemConfiguration where ProgramID = @DestinationProgramID)
	BEGIN
		INSERT INTO PhoneSystemConfiguration
			(
				IVRScriptID,
				ProgramID,
				SkillsetID,
				InboundPhoneCompanyID,
				InboundNumber,
				PilotNumber,
				IsShownOnScreen,
				IsActive,
				CreateDate,
				CreateBy,
				ModifyDate,
				ModifyBy		
			)
			Select 
				IVRScriptID,
				@DestinationProgramID as ProgramID,
				SkillsetID,
				InboundPhoneCompanyID,
				InboundNumber,
				PilotNumber,
				0,
				0,
				getdate(),
				'System',
				ModifyDate,
				ModifyBy
			from PhoneSystemConfiguration
			where
				ProgramID = @SourceProgramID
	END

-- ProgramVehicleType
if not exists(Select * from ProgramVehicleType where ProgramID = @DestinationProgramID)
	BEGIN
		INSERT INTO ProgramVehicleType
			(
				ProgramID,
				VehicleTypeID,
				MaxAllowed,
				IsActive			
			)
			Select 
				@DestinationProgramID as ProgramID,
				VehicleTypeID,
				MaxAllowed,
				IsActive
			from ProgramVehicleType
			where
				ProgramID = @SourceProgramID
	END

-- ProgramConfiguration
if not exists(Select * from ProgramConfiguration where ProgramID = @DestinationProgramID)
	BEGIN
		INSERT INTO ProgramConfiguration
			(
				ProgramID,
				ConfigurationTypeID,
				ConfigurationCategoryID,
				ControlTypeID,
				DataTypeID,
				Name,
				Value,
				IsActive,
				Sequence,
				CreateDate,
				CreateBy,
				ModifyDate,
				ModifyBy
			)

		Select 
			@DestinationProgramID as ProgramID,
			ConfigurationTypeID,
			ConfigurationCategoryID,
			ControlTypeID,
			DataTypeID,
			Name,
			Value,
			IsActive,
			Sequence,
			getdate(),
			'System',
			ModifyDate,
			ModifyBy
		from ProgramConfiguration
		where
			ProgramID = @SourceProgramID
	END


-- ProgramProduct
if not exists(Select * from ProgramProduct where ProgramID = @DestinationProgramID)
	BEGIN
	
		INSERT INTO ProgramProduct
			(
				ProgramID,
				ProductID,
				StartDate,
				EndDate,
				ServiceCoverageLimit,
				IsServiceCoverageBestValue,
				MaterialsCoverageLimit,
				IsMaterialsMemberPay,
				ServiceMileageLimit,
				IsServiceMileageUnlimited,
				IsServiceMileageOverageAllowed,
				IsReimbersementOnly,
				CreateDate,
				CreateBy,
				ModifyDate,
				ModifyBy
			)
	
	
		Select 
			@DestinationProgramID as ProgramID,
			ProductID,
			StartDate,
			EndDate,
			ServiceCoverageLimit,
			IsServiceCoverageBestValue,
			MaterialsCoverageLimit,
			IsMaterialsMemberPay,
			ServiceMileageLimit,
			IsServiceMileageUnlimited,
			IsServiceMileageOverageAllowed,
			IsReimbersementOnly,
			getdate(),
			'System',
			ModifyDate,
			ModifyBy
		from ProgramProduct
		where
			ProgramID = @SourceProgramID
	END

--============================================
-- Program: Hagerty - Premier (Level 3) **
SELECT	@SourceProgramID = (SELECT ID FROM Program WHERE Name = 'Hagerty - Premium (Level 3)')

-- Program
 IF NOT EXISTS(SELECT * FROM Program WHERE Name = 'Hagerty - Premier (Level 3) **')
	BEGIN
		INSERT INTO Program
		(
			ParentProgramID,
			ClientID,
			Code,
			Name,
			Description,
			IsServiceGuaranteed,
			CallFee,
			DispatchFee,
			IsActive,
			IsAudited,
			IsClosedLoopAutomated,
			IsGroup,
			LegacyType,
			LegacyCode,
			CreateDate,
			CreateBy,
			ModifyDate,
			ModifyBy,
			IsWebRegistrationEnabled
		)
		SELECT 
			(SELECT ID FROM Program WHERE Name = 'Hagerty'),
			(SELECT ID From Client WHERE Name = 'Hagerty'),
			'HAGERTY_N_3',
			'Hagerty - Premier (Level 3) **',
			'Hagerty - Premier (Level 3) **',
			IsServiceGuaranteed,
			CallFee,
			DispatchFee,
			0,
			IsAudited,
			IsClosedLoopAutomated,
			IsGroup,
			LegacyType,
			LegacyCode,
			getdate(),
			'System',
			ModifyDate,
			ModifyBy,
			IsWebRegistrationEnabled	
		FROM	Program
		WHERE	ID = @SourceProgramID
	END
			
--DECLARE @DestinationProgramID int
SELECT	@DestinationProgramID = (SELECT ID FROM Program WHERE Name = 'Hagerty - Premier (Level 3) **')

-- PhoneSystemConfiguration
if not exists(Select * from PhoneSystemConfiguration where ProgramID = @DestinationProgramID)
	BEGIN
		INSERT INTO PhoneSystemConfiguration
			(
				IVRScriptID,
				ProgramID,
				SkillsetID,
				InboundPhoneCompanyID,
				InboundNumber,
				PilotNumber,
				IsShownOnScreen,
				IsActive,
				CreateDate,
				CreateBy,
				ModifyDate,
				ModifyBy		
			)
			Select 
				IVRScriptID,
				@DestinationProgramID as ProgramID,
				SkillsetID,
				InboundPhoneCompanyID,
				InboundNumber,
				PilotNumber,
				0,
				0,
				getdate(),
				'System',
				ModifyDate,
				ModifyBy
			from PhoneSystemConfiguration
			where
				ProgramID = @SourceProgramID
	END

-- ProgramVehicleType
if not exists(Select * from ProgramVehicleType where ProgramID = @DestinationProgramID)
	BEGIN
		INSERT INTO ProgramVehicleType
			(
				ProgramID,
				VehicleTypeID,
				MaxAllowed,
				IsActive			
			)
			Select 
				@DestinationProgramID as ProgramID,
				VehicleTypeID,
				MaxAllowed,
				IsActive
			from ProgramVehicleType
			where
				ProgramID = @SourceProgramID
	END

-- ProgramConfiguration
if not exists(Select * from ProgramConfiguration where ProgramID = @DestinationProgramID)
	BEGIN
		INSERT INTO ProgramConfiguration
			(
				ProgramID,
				ConfigurationTypeID,
				ConfigurationCategoryID,
				ControlTypeID,
				DataTypeID,
				Name,
				Value,
				IsActive,
				Sequence,
				CreateDate,
				CreateBy,
				ModifyDate,
				ModifyBy
			)

		Select 
			@DestinationProgramID as ProgramID,
			ConfigurationTypeID,
			ConfigurationCategoryID,
			ControlTypeID,
			DataTypeID,
			Name,
			Value,
			IsActive,
			Sequence,
			getdate(),
			'System',
			ModifyDate,
			ModifyBy
		from ProgramConfiguration
		where
			ProgramID = @SourceProgramID
	END


-- ProgramProduct
if not exists(Select * from ProgramProduct where ProgramID = @DestinationProgramID)
	BEGIN
	
		INSERT INTO ProgramProduct
			(
				ProgramID,
				ProductID,
				StartDate,
				EndDate,
				ServiceCoverageLimit,
				IsServiceCoverageBestValue,
				MaterialsCoverageLimit,
				IsMaterialsMemberPay,
				ServiceMileageLimit,
				IsServiceMileageUnlimited,
				IsServiceMileageOverageAllowed,
				IsReimbersementOnly,
				CreateDate,
				CreateBy,
				ModifyDate,
				ModifyBy
			)
	
	
		Select 
			@DestinationProgramID as ProgramID,
			ProductID,
			StartDate,
			EndDate,
			ServiceCoverageLimit,
			IsServiceCoverageBestValue,
			MaterialsCoverageLimit,
			IsMaterialsMemberPay,
			ServiceMileageLimit,
			IsServiceMileageUnlimited,
			IsServiceMileageOverageAllowed,
			IsReimbersementOnly,
			getdate(),
			'System',
			ModifyDate,
			ModifyBy
		from ProgramProduct
		where
			ProgramID = @SourceProgramID
	END

--============================================
-- Program: Hagerty - High Octane (Level 4) **
SELECT	@SourceProgramID = (SELECT ID FROM Program WHERE Name = 'Hagerty - High Octane (Level 4)')

-- Program
 IF NOT EXISTS(SELECT * FROM Program WHERE Name = 'Hagerty - High Octane (Level 4) **')
	BEGIN
		INSERT INTO Program
		(
			ParentProgramID,
			ClientID,
			Code,
			Name,
			Description,
			IsServiceGuaranteed,
			CallFee,
			DispatchFee,
			IsActive,
			IsAudited,
			IsClosedLoopAutomated,
			IsGroup,
			LegacyType,
			LegacyCode,
			CreateDate,
			CreateBy,
			ModifyDate,
			ModifyBy,
			IsWebRegistrationEnabled
		)
		SELECT 
			(SELECT ID FROM Program WHERE Name = 'Hagerty'),
			(SELECT ID From Client WHERE Name = 'Hagerty'),
			'HAGERTY_N_4',
			'Hagerty - High Octane (Level 4) **',
			'Hagerty - High Octane (Level 4) **',
			IsServiceGuaranteed,
			CallFee,
			DispatchFee,
			0,
			IsAudited,
			IsClosedLoopAutomated,
			IsGroup,
			LegacyType,
			LegacyCode,
			getdate(),
			'System',
			ModifyDate,
			ModifyBy,
			IsWebRegistrationEnabled	
		FROM	Program
		WHERE	ID = @SourceProgramID
	END
			
--DECLARE @DestinationProgramID int
SELECT	@DestinationProgramID = (SELECT ID FROM Program WHERE Name = 'Hagerty - High Octane (Level 4) **')

-- PhoneSystemConfiguration
if not exists(Select * from PhoneSystemConfiguration where ProgramID = @DestinationProgramID)
	BEGIN
		INSERT INTO PhoneSystemConfiguration
			(
				IVRScriptID,
				ProgramID,
				SkillsetID,
				InboundPhoneCompanyID,
				InboundNumber,
				PilotNumber,
				IsShownOnScreen,
				IsActive,
				CreateDate,
				CreateBy,
				ModifyDate,
				ModifyBy		
			)
			Select 
				IVRScriptID,
				@DestinationProgramID as ProgramID,
				SkillsetID,
				InboundPhoneCompanyID,
				InboundNumber,
				PilotNumber,
				0,
				0,
				getdate(),
				'System',
				ModifyDate,
				ModifyBy
			from PhoneSystemConfiguration
			where
				ProgramID = @SourceProgramID
	END

-- ProgramVehicleType
if not exists(Select * from ProgramVehicleType where ProgramID = @DestinationProgramID)
	BEGIN
		INSERT INTO ProgramVehicleType
			(
				ProgramID,
				VehicleTypeID,
				MaxAllowed,
				IsActive			
			)
			Select 
				@DestinationProgramID as ProgramID,
				VehicleTypeID,
				MaxAllowed,
				IsActive
			from ProgramVehicleType
			where
				ProgramID = @SourceProgramID
	END

-- ProgramConfiguration
if not exists(Select * from ProgramConfiguration where ProgramID = @DestinationProgramID)
	BEGIN
		INSERT INTO ProgramConfiguration
			(
				ProgramID,
				ConfigurationTypeID,
				ConfigurationCategoryID,
				ControlTypeID,
				DataTypeID,
				Name,
				Value,
				IsActive,
				Sequence,
				CreateDate,
				CreateBy,
				ModifyDate,
				ModifyBy
			)

		Select 
			@DestinationProgramID as ProgramID,
			ConfigurationTypeID,
			ConfigurationCategoryID,
			ControlTypeID,
			DataTypeID,
			Name,
			Value,
			IsActive,
			Sequence,
			getdate(),
			'System',
			ModifyDate,
			ModifyBy
		from ProgramConfiguration
		where
			ProgramID = @SourceProgramID
	END


-- ProgramProduct
if not exists(Select * from ProgramProduct where ProgramID = @DestinationProgramID)
	BEGIN
	
		INSERT INTO ProgramProduct
			(
				ProgramID,
				ProductID,
				StartDate,
				EndDate,
				ServiceCoverageLimit,
				IsServiceCoverageBestValue,
				MaterialsCoverageLimit,
				IsMaterialsMemberPay,
				ServiceMileageLimit,
				IsServiceMileageUnlimited,
				IsServiceMileageOverageAllowed,
				IsReimbersementOnly,
				CreateDate,
				CreateBy,
				ModifyDate,
				ModifyBy
			)
	
	
		Select 
			@DestinationProgramID as ProgramID,
			ProductID,
			StartDate,
			EndDate,
			ServiceCoverageLimit,
			IsServiceCoverageBestValue,
			MaterialsCoverageLimit,
			IsMaterialsMemberPay,
			ServiceMileageLimit,
			IsServiceMileageUnlimited,
			IsServiceMileageOverageAllowed,
			IsReimbersementOnly,
			getdate(),
			'System',
			ModifyDate,
			ModifyBy
		from ProgramProduct
		where
			ProgramID = @SourceProgramID
	END

--============================================
-- Program: Hagerty - Non Standard
SELECT	@SourceProgramID = (SELECT ID FROM Program WHERE Name = 'Hagerty - Secondary Tow')

-- Program
 IF NOT EXISTS(SELECT * FROM Program WHERE Name = 'Hagerty - Non Standard')
	BEGIN
		INSERT INTO Program
		(
			ParentProgramID,
			ClientID,
			Code,
			Name,
			Description,
			IsServiceGuaranteed,
			CallFee,
			DispatchFee,
			IsActive,
			IsAudited,
			IsClosedLoopAutomated,
			IsGroup,
			LegacyType,
			LegacyCode,
			CreateDate,
			CreateBy,
			ModifyDate,
			ModifyBy,
			IsWebRegistrationEnabled
		)
		SELECT 
			(SELECT ID FROM Program WHERE Name = 'Hagerty'),
			(SELECT ID From Client WHERE Name = 'Hagerty'),
			'HAGERTY_N_NONSTD',
			'Hagerty - Non Standard',
			'Hagerty - Non Standard',
			IsServiceGuaranteed,
			CallFee,
			DispatchFee,
			0,
			IsAudited,
			IsClosedLoopAutomated,
			IsGroup,
			LegacyType,
			LegacyCode,
			getdate(),
			'System',
			ModifyDate,
			ModifyBy,
			IsWebRegistrationEnabled	
		FROM	Program
		WHERE	ID = @SourceProgramID
	END
			
--DECLARE @DestinationProgramID int
SELECT	@DestinationProgramID = (SELECT ID FROM Program WHERE Name = 'Hagerty - Non Standard')

-- PhoneSystemConfiguration
if not exists(Select * from PhoneSystemConfiguration where ProgramID = @DestinationProgramID)
	BEGIN
		INSERT INTO PhoneSystemConfiguration
			(
				IVRScriptID,
				ProgramID,
				SkillsetID,
				InboundPhoneCompanyID,
				InboundNumber,
				PilotNumber,
				IsShownOnScreen,
				IsActive,
				CreateDate,
				CreateBy,
				ModifyDate,
				ModifyBy		
			)
			Select 
				IVRScriptID,
				@DestinationProgramID as ProgramID,
				SkillsetID,
				InboundPhoneCompanyID,
				InboundNumber,
				PilotNumber,
				0,
				0,
				getdate(),
				'System',
				ModifyDate,
				ModifyBy
			from PhoneSystemConfiguration
			where
				ProgramID = @SourceProgramID
	END

-- ProgramVehicleType
if not exists(Select * from ProgramVehicleType where ProgramID = @DestinationProgramID)
	BEGIN
		INSERT INTO ProgramVehicleType
			(
				ProgramID,
				VehicleTypeID,
				MaxAllowed,
				IsActive			
			)
			Select 
				@DestinationProgramID as ProgramID,
				VehicleTypeID,
				MaxAllowed,
				IsActive
			from ProgramVehicleType
			where
				ProgramID = @SourceProgramID
	END

-- ProgramConfiguration
if not exists(Select * from ProgramConfiguration where ProgramID = @DestinationProgramID)
	BEGIN
		INSERT INTO ProgramConfiguration
			(
				ProgramID,
				ConfigurationTypeID,
				ConfigurationCategoryID,
				ControlTypeID,
				DataTypeID,
				Name,
				Value,
				IsActive,
				Sequence,
				CreateDate,
				CreateBy,
				ModifyDate,
				ModifyBy
			)

		Select 
			@DestinationProgramID as ProgramID,
			ConfigurationTypeID,
			ConfigurationCategoryID,
			ControlTypeID,
			DataTypeID,
			Name,
			Value,
			IsActive,
			Sequence,
			getdate(),
			'System',
			ModifyDate,
			ModifyBy
		from ProgramConfiguration
		where
			ProgramID = @SourceProgramID
	END


-- ProgramProduct
if not exists(Select * from ProgramProduct where ProgramID = @DestinationProgramID)
	BEGIN
	
		INSERT INTO ProgramProduct
			(
				ProgramID,
				ProductID,
				StartDate,
				EndDate,
				ServiceCoverageLimit,
				IsServiceCoverageBestValue,
				MaterialsCoverageLimit,
				IsMaterialsMemberPay,
				ServiceMileageLimit,
				IsServiceMileageUnlimited,
				IsServiceMileageOverageAllowed,
				IsReimbersementOnly,
				CreateDate,
				CreateBy,
				ModifyDate,
				ModifyBy
			)
	
	
		Select 
			@DestinationProgramID as ProgramID,
			ProductID,
			StartDate,
			EndDate,
			ServiceCoverageLimit,
			IsServiceCoverageBestValue,
			MaterialsCoverageLimit,
			IsMaterialsMemberPay,
			ServiceMileageLimit,
			IsServiceMileageUnlimited,
			IsServiceMileageOverageAllowed,
			IsReimbersementOnly,
			getdate(),
			'System',
			ModifyDate,
			ModifyBy
		from ProgramProduct
		where
			ProgramID = @SourceProgramID
	END
GO


-- SETP 5 =============================
-- Create and load HagertyProgramMap table

CREATE TABLE [HagertyProgramMap]
(
 ID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
 CustomerType nvarchar(50),
 PlanType nvarchar(50),
 ProgramID int NOT NULL FOREIGN KEY REFERENCES Program(ID)
)
GO

DECLARE @125MileProgam AS INT
DECLARE @50MileProgam AS INT
DECLARE @10MileProgam AS INT
DECLARE @NonStandardProgam AS INT
SET @125MileProgam = (SELECT ID FROM Program WHERE Name = 'Hagerty - High Octane (Level 4) **') 
SET @50MileProgam = (SELECT ID FROM Program WHERE Name = 'Hagerty - Premier (Level 3) **')
SET @10MileProgam = (SELECT ID FROM Program WHERE Name = 'Hagerty - Standard (Level 2) **') 
SET @NonStandardProgam = (SELECT ID FROM Program WHERE Name = 'Hagerty - Non Standard') 

--***** Create a new table for Hagerty New Programs and its mapping ****---

--******* Insert below new records in to HagertyProgramMap Table ********---

INSERT INTO [HagertyProgramMap]
           ([CustomerType]
           ,[PlanType]
           ,[ProgramID]
           )
     VALUES
           ('PCS'
           ,'10 Mile'
           ,@10MileProgam
           )
--GO

INSERT INTO [HagertyProgramMap]
           ([CustomerType]
           ,[PlanType]
           ,[ProgramID]
           )
     VALUES
           ('Standard'
           ,'10 Mile'
           ,@10MileProgam
           )
--GO

INSERT INTO [HagertyProgramMap]
           ([CustomerType]
           ,[PlanType]
           ,[ProgramID]
           )
     VALUES
           ('PCS'
           ,'50 Mile'
           ,@50MileProgam
           )
--GO

INSERT INTO [HagertyProgramMap]
           ([CustomerType]
           ,[PlanType]
           ,[ProgramID]
           )
     VALUES
           ('Standard'
           ,'50 Mile'
           ,@50MileProgam
           )
--GO

INSERT INTO [HagertyProgramMap]
           ([CustomerType]
           ,[PlanType]
           ,[ProgramID]
           )
     VALUES
           ('PCS'
           ,'125 Mile'
           ,@125MileProgam
           )
--GO

INSERT INTO [HagertyProgramMap]
           ([CustomerType]
           ,[PlanType]
           ,[ProgramID]
           )
     VALUES
           ('Standard'
           ,'125 Mile'
           ,@125MileProgam
           )
--GO

INSERT INTO [HagertyProgramMap]
           ([CustomerType]
           ,[PlanType]
           ,[ProgramID]
           )
     VALUES
           ('Non-Standard'
           ,NULL
           ,@NonStandardProgam
           )
--GO


