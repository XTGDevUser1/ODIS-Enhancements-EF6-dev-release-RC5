IF NOT EXISTS ( SELECT * FROM ProgramConfiguration WHERE ProgramID = 
								(SELECT ID FROM Program WHERE Name = 'Ford')
								AND 
								Name = 'WarrantyApplies')
BEGIN

	INSERT INTO ProgramConfiguration ( ProgramID,
										ConfigurationTypeID,
										ConfigurationCategoryID,
										Name,
										Value,
										CreateBy,
										CreateDate,
										IsActive)
	SELECT (SELECT ID FROM Program WHERE Name = 'Ford'),
			(SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle'),
			(SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'),
			'WarrantyApplies',
			'Yes',
			'system',
			GETDATE(),
			1

END
GO

ALTER TABLE VehicleMakeModel
DROP COLUMN WarrantyMileage
GO

ALTER TABLE VehicleMakeModel
DROP COLUMN WarrantyMileageUOM
GO

ALTER TABLE VehicleMakeModel
ADD WarrantyMileageMiles int NULL,	
	WarrantyMileageKilometers int NULL

GO

ALTER TABLE RVMakeModel
DROP COLUMN WarrantyMileage
GO

ALTER TABLE RVMakeModel
DROP COLUMN WarrantyMileageUOM
GO

ALTER TABLE RVMakeModel
ADD WarrantyMileageMiles int NULL,	
	WarrantyMileageKilometers int NULL

GO

UPDATE VehicleMakeModel
SET		WarrantyPeriod = 5,
		WarrantyPeriodUOM = 'Years',
		WarrantyMileageMiles = 60000,
		WarrantyMileageKilometers = 60000*1.5
where make = 'Ford' 
		and model in ('E-350','E-450','E-550','E-650','E-750')
		or model in ('F-350','F-450','F-550','F-650','F-750')
GO

UPDATE RVMakeModel
SET		WarrantyPeriod = 5,
		WarrantyPeriodUOM = 'Years',
		WarrantyMileageMiles = 60000,
		WarrantyMileageKilometers = 60000*1.5
where make = 'Ford' 
		and model like 'E-%'
		or model like 'F-%'
GO

IF NOT EXISTS ( SELECT * FROM ProductISPSelectionRadius WHERE ProductID = (SELECT ID FROM Product WHERE Name = 'CoachNet Dealer Partner') )
BEGIN

INSERT INTO [dbo].[ProductISPSelectionRadius]
           ([ProductID]
           ,[MetroRadius]
           ,[RuralRadius])
     VALUES
           ((SELECT ID FROM Product WHERE Name = 'CoachNet Dealer Partner')
           ,25
           ,50)

END
GO

ALTER TABLE ServiceRequest
ADD PartsAndAccessoryCode NVARCHAR(50) NULL
GO
