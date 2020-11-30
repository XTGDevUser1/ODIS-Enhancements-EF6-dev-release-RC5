-- NP: Execute statement by statement. Includes Vehicle and related table changes.
-- EventSubscription : Manual Notification

IF NOT EXISTS ( SELECT * FROM EventSubscription 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'LockedRequestComment') 				
				)
BEGIN
	INSERT INTO EventSubscription ( EventID,
									EventTypeID,
									EventCategoryID, 
									ContactMethodID, 
									EventTemplateID, 
									IsActive, 
									CreateDate, 
									CreateBy, 
									NotificationRecipientTypeID, 
									NotificationRecipient)
	SELECT	(SELECT ID FROM Event WHERE Name = 'LockedRequestComment'),
			NULL,
			NULL,
			(SELECT ID FROM ContactMethod WHERE Name = 'DesktopNotification'),
			(SELECT ID FROM EventTemplate 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'ManualNotification') 
				AND		TemplateID = (SELECT ID FROM Template WHERE Name = 'ManualNotification') 
			),
			1,
			GETDATE(),
			'system',
			(SELECT ID FROM NotificationRecipientType WHERE Name = 'CurrentUser'),
			NULL

END
GO

-- ProgramConfiguration for NMC - ServiceLocationPreferredProduct
IF NOT EXISTS (	SELECT * 
				FROM	ProgramConfiguration 
				WHERE	Name = 'ServiceLocationPreferredProduct' 
				AND		ProgramID =  (SELECT ID FROM Program WHERE Name = 'NMC' ) )
BEGIN

	INSERT INTO ProgramConfiguration (	ProgramID,
										ConfigurationTypeID,
										ConfigurationCategoryID,
										Name,
										Value,
										IsActive,
										CreateDate,
										CreateBy )
	SELECT (SELECT ID FROM Program WHERE Name = 'NMC' ),
			(SELECT ID FROM ConfigurationType WHERE Name = 'Application'),
			(SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'),
			'ServiceLocationPreferredProduct',
			(SELECT ID FROM Product WHERE Name = 'CoachNet Dealer Partner'),
			1,
			GETDATE(),
			'system'

END

DECLARE @programID INT = (SELECT TOP 1 ID FROM Program where Name ='NMC')
IF NOT EXISTS(Select * from ProgramConfiguration where Name='AllowMemberExpirationUpdate' AND ProgramID = @programID )
BEGIN
INSERT INTO ProgramConfiguration VALUES(
	@programID,
	(SELECT TOP 1 ID FROM ConfigurationType WHERE Name ='Application'),
	(SELECT TOP 1 ID FROM ConfigurationCategory WHERE Name ='Rule'),
	NULL,
	NULL,
	'AllowMemberExpirationUpdate',
	'Yes',
	1,
	4,
	GETDATE(),
	'system',
	NULL,
	NULL
)
END

-- CASE Changes
ALTER TABLE [Case]
ADD VehicleWarrantyPeriod INT NULL

ALTER TABLE [Case]
ADD VehicleWarrantyPeriodUOM NVARCHAR(25)

ALTER TABLE [Case]
ADD VehicleWarrantyMileage INT NULL

ALTER TABLE [Case]
ADD VehicleWarrantyEndDate DATETIME NULL

ALTER TABLE [Case]
ADD IsVehicleEligible BIT NULL

--Vehicle Changes
ALTER TABLE Vehicle
ADD WarrantyPeriod INT NULL

ALTER TABLE Vehicle
ADD WarrantyPeriodUOM NVARCHAR(25)

ALTER TABLE Vehicle
ADD WarrantyMileage INT NULL

ALTER TABLE Vehicle
ADD WarrantyEndDate DATETIME NULL

--VehicleMakeModel Changes
ALTER TABLE VehicleMakeModel
ADD WarrantyPeriod INT NULL

ALTER TABLE VehicleMakeModel
ADD WarrantyPeriodUOM NVARCHAR(25)

ALTER TABLE VehicleMakeModel
ADD WarrantyMileage INT NULL

ALTER TABLE VehicleMakeModel
ADD WarrantyMileageUOM NVARCHAR(25)

--RVMakeModel Changes
ALTER TABLE RVMakeModel
ADD WarrantyPeriod INT NULL

ALTER TABLE RVMakeModel
ADD WarrantyPeriodUOM NVARCHAR(25)

ALTER TABLE RVMakeModel
ADD WarrantyMileage INT NULL

ALTER TABLE RVMakeModel
ADD WarrantyMileageUOM NVARCHAR(25)

--VehicleMakeModel Updates
UPDATE VehicleMakeModel SET
	WarrantyPeriod = 5,
	WarrantyPeriodUOM = 'Years',
	WarrantyMileage = 60000,
	WarrantyMileageUOM = 'Miles'
WHERE ID IN(
Select ID from VehicleMakeModel where make = 'Ford' 
		and model in ('E-350','E-450','E-550','E-650','E-750')
		or model in ('F-350','F-450','F-550','F-650','F-750')
)

--RVMakeModel Updates
UPDATE RVMakeModel SET
	WarrantyPeriod = 5,
	WarrantyPeriodUOM = 'Years',
	WarrantyMileage = 60000,
	WarrantyMileageUOM = 'Miles'
WHERE ID IN(
Select ID from RVMakeModel where make = 'Ford' and model like 'E-%' or model like 'F-%'
)