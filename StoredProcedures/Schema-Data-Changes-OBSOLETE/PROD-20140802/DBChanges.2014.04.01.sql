ALTER TABLE ProgramServiceEventLimit
ADD PRIMARY KEY (ID)

ALTER TABLE ProgramProduct
ADD IsServiceGuaranteed BIT NULL

ALTER TABLE ProgramProduct
ADD ServiceCoverageDescription NVARCHAR(2000) NULL 

ALTER TABLE ProgramProduct
ADD CurrencyTypeID INT NULL

ALTER TABLE ProgramProduct
ADD ServiceMileageLimitUOM NVARCHAR(50) NULL

ALTER TABLE ProductCategory
ADD IsVehicleRequired BIT NULL

UPDATE ProductCategory SET IsVehicleRequired=0 WHERE Name IN ('Info','Concierge', 'Home Locksmith')
UPDATE ProductCategory SET IsVehicleRequired=1 WHERE Name IN ('Tow','Tire','Lockout','Fluid','Jump','Winch','Mobile','Tech')

ALTER TABLE ProgramServiceEventLimit
ADD CreateDate  DATETIME NULL

ALTER TABLE ProgramServiceEventLimit
ADD CreateBy NVARCHAR(50) NULL


ALTER TABLE ServiceRequest
ADD CurrencyTypeID INT NULL

ALTER TABLE ServiceRequest
ADD PrimaryCoverageLimit MONEY NULL

ALTER TABLE ServiceRequest
ADD SecondaryCoverageLimit MONEY NULL

ALTER TABLE ServiceRequest
ADD MileageUOM NVARCHAR(50) NULL

ALTER TABLE ServiceRequest
ADD PrimaryCoverageLimitMileage INT NULL

ALTER TABLE ServiceRequest
ADD SecondaryCoverageLimitMileage INT NULL

ALTER TABLE ServiceRequest
ADD IsServiceEligible BIT NULL

ALTER TABLE ServiceRequest
ADD ServiceCoverageDescription NVARCHAR(2000) NULL

ALTER TABLE ServiceRequest
ADD ServiceEligiblityMessage NVARCHAR(225) NULL

ALTER TABLE ServiceRequest
ADD IsServiceCovered BIT NULL

ALTER TABLE ServiceRequest
ADD IsServiceGuaranteed BIT NULL

ALTER TABLE ServiceRequest
ADD IsReimbursementOnly  BIT NULL

ALTER TABLE ServiceRequest
ADD IsServiceCoverageBestValue BIT NULL

ALTER TABLE ServiceRequest
ADD ProgramServiceEventLimitID INT NULL

EXEC sp_RENAME 'ProgramProduct.IsReimbersementOnly' , 'IsReimbursementOnly', 'COLUMN'


IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_VerifyServiceBenefit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyServiceBenefit] 
 END 
 GO  



DECLARE @ClientID INT
DECLARE @ProgramID INT
SET @ClientID = (SELECT ID FROM Client WHERE Name = 'National Motor Club')
--SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'NMCA')
SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Commercial Truck')


Update ProgramProduct Set IsServiceCoverageBestValue = 1 Where ServiceCoverageLimit >= 999.99

UPDATE pp Set ServiceCoverageDescription = 
		CASE
			WHEN pp.IsServiceCoverageBestValue = 1 AND ISNULL(pp.ServiceMileageLimit,0)=0
				THEN pr.Name + ' - Best Value'
			WHEN pp.IsServiceCoverageBestValue = 1 AND ISNULL(pp.ServiceMileageLimit,0) > 0 
				THEN pr.Name + ' - Best value with ' + CAST(pp.ServiceMileageLimit AS nvarchar(10)) + ' Mile' + ' Limit'
			WHEN ISNULL(pp.ServiceCoverageLimit,0) > 0 AND ISNULL(pp.ServiceMileageLimit,0)= 0
				THEN pr.Name + ' - $' + CAST(pp.ServiceCoverageLimit AS nvarchar(10)) + ' Limit'
			WHEN ISNULL(pp.ServiceCoverageLimit,0)= 0 AND ISNULL(pp.ServiceMileageLimit,0) > 0 
				THEN pr.Name + ' - ' + CAST(pp.ServiceMileageLimit AS nvarchar(10)) + ' Mile' + ' Limit'
			WHEN ISNULL(pp.ServiceCoverageLimit,0) > 0 AND ISNULL(pp.ServiceMileageLimit,0)> 0
				THEN pr.Name + ' - $' + CAST(pp.ServiceCoverageLimit AS nvarchar(10)) + ' Limit' + ' with ' + CAST(pp.ServiceMileageLimit AS nvarchar(10)) + ' Mile' + ' Limit'
			WHEN ISNULL(pp.ServiceCoverageLimit,0)=0 AND ISNULL(pp.ServiceMileageLimit,0)= 0
				AND pp.ProductID IN (Select ID From Product Where Name in ('Tech','Information','Concierge'))
				--AND pp.IsReimbersementOnly <> 1
				THEN pr.Name + ' - No charge for service'
			WHEN ISNULL(pp.ServiceCoverageLimit,0)=0 AND ISNULL(pp.ServiceMileageLimit,0)= 0
				THEN pr.Name + ' - Assist Only'
				ELSE ''
		  END 
FROM	ProgramProduct pp
JOIN	Program p on p.ID = pp.ProgramID
JOIN	Product pr on pr.ID = pp.ProductID
JOIN	ProductCategory pc on pc.ID = pr.ProductCategoryID

