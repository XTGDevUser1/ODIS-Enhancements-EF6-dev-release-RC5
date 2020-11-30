--Get List of warranty Programs
/*
Select p.ID,p.name from ProgramConfiguration pc
Join program p on p.id = pc.programid
where pc.Name = 'WarrantyApplies'
*/
DECLARE @WarrantyPrograms Table (ProgramID int)
INSERT INTO @WarrantyPrograms (ProgramID) 
	(SELECT wp.ProgramID 
	 from dbo.fnc_GetChildPrograms(86) wp
	 --join ProgramConfiguration pc on wp.ProgramID = pc.ProgramID and pc.Name = 'WarrantyApplies'
	 )

--Update IsVehicleEligle field on the Case for warranty programs only
--Select 
UPDATE c SET
	IsVehicleEligible = Case WHEN ISNULL(c.VehicleCurrentMileage,0) > 60000 AND c.ProgramID <> 266 THEN 0 ELSE 1 END
From [Case] c
Join @WarrantyPrograms wp on wp.ProgramID = c.ProgramID
GO

--Update new eligibility data fields on the Service Request
--Select pp.ID,
UPDATE sr SET
	SecondaryCoverageLimit = pp2.ServiceCoverageLimit
	,MileageUOM = pp.ServiceMileageLimitUOM
	,PrimaryCoverageLimitMileage = pp.ServiceMileageLimit
	,SecondaryCoverageLimitMileage = pp2.ServiceMileageLimit
	,IsServiceGuaranteed = pp.IsServiceGuaranteed
	,IsReimbursementOnly = pp.IsReimbursementOnly
	,IsServiceCoverageBestValue = pp.IsServiceCoverageBestValue
	,ProgramServiceEventLimitID = NULL
	,PrimaryServiceCoverageDescription = pp.ServiceCoverageDescription
	,SecondaryServiceCoverageDescription = pp2.ServiceCoverageDescription
	,PrimaryServiceEligiblityMessage = 
		(
		Case WHEN c.MemberStatus = 'Inactive' THEN  'Member Inactive'
			WHEN c.IsVehicleEligible IS NOT NULL AND c.IsVehicleEligible = 0 
				THEN  'Vehicle Out of Warranty' 
			WHEN (pp.ID IS NOT NULL) AND (ISNULL(pp.IsServiceCoverageBestValue,0) = 1) AND (pp.IsReimbursementOnly =1) 
				THEN 'Reimbursement Only – Best Value'
			WHEN (pp.ID IS NOT NULL) AND (ISNULL(pp.IsServiceCoverageBestValue,0) = 1) 
				THEN 'Best Value'
			WHEN (pp.ID IS NOT NULL) AND (ISNULL(pp.ServiceCoverageLimit,0) = 0) AND (ISNULL(pp.ServiceMileageLimit,0) = 0) AND (pp.IsReimbursementOnly =1) 
				THEN 'Reimbursement Only - Provide Assistance'
			WHEN (pp.ID IS NOT NULL) AND (ISNULL(pp.ServiceCoverageLimit,0) = 0) AND (ISNULL(pp.ServiceMileageLimit,0) = 0) 
				THEN 'Assist Only'
			WHEN (pp.ID IS NOT NULL) AND (ISNULL(pp.ServiceCoverageLimit,0) = 0) AND (ISNULL(pp.ServiceMileageLimit,0) > 0) 
				THEN CONVERT(nvarchar(50), ISNULL(pp.ServiceMileageLimit,0)) + ' ' + pp.ServiceMileageLimitUOM + ' Limit'
				
			WHEN (pp.ID IS NOT NULL) AND (ISNULL(pp.ServiceCoverageLimit,0) > 0) AND (pp.IsReimbursementOnly =1) AND (ISNULL(pp.ServiceMileageLimit,0) > 0) 
				THEN 'Reimbursement Only – $' + CONVERT(nvarchar(50),Convert(int,ISNULL(pp.ServiceCoverageLimit,0.00))) + ' USD Limit'+ '; ' + CONVERT(nvarchar(50), ISNULL(pp.ServiceMileageLimit,0)) + ' ' + pp.ServiceMileageLimitUOM + ' Limit'
			WHEN (pp.ID IS NOT NULL) AND (ISNULL(pp.ServiceCoverageLimit,0) > 0) AND (pp.IsReimbursementOnly =1) 
				THEN 'Reimbursement Only – $' + CONVERT(nvarchar(50),Convert(int,ISNULL(pp.ServiceCoverageLimit,0.00))) + ' USD Limit'

			WHEN (pp.ID IS NOT NULL) AND (ISNULL(pp.ServiceCoverageLimit,0) > 0) AND (ISNULL(pp.ServiceMileageLimit,0) > 0) 
				THEN '$' + CONVERT(nvarchar(50),Convert(int,ISNULL(pp.ServiceCoverageLimit,0.00))) + ' USD Limit' + '; ' + CONVERT(nvarchar(50), ISNULL(pp.ServiceMileageLimit,0)) + ' ' + pp.ServiceMileageLimitUOM + ' Limit'
			WHEN (pp.ID IS NOT NULL) AND (ISNULL(pp.ServiceCoverageLimit,0) > 0) 
				THEN '$' + CONVERT(nvarchar(50),Convert(int,ISNULL(pp.ServiceCoverageLimit,0.00))) + ' USD Limit'
			WHEN (pp.ID IS NOT NULL) 
				THEN 'Undetermined'
			ELSE NULL
			END 
		)
	,SecondaryServiceEligiblityMessage =
		(
		Case WHEN sr.SecondaryProductID IS NULL THEN NULL 
			WHEN c.MemberStatus = 'Inactive' THEN  'Member Inactive'
			WHEN c.IsVehicleEligible IS NOT NULL AND c.IsVehicleEligible = 0 
				THEN  'Vehicle Out of Warranty' 
			WHEN (pp2.ID IS NOT NULL) AND (ISNULL(pp2.IsServiceCoverageBestValue,0) = 1) AND (pp2.IsReimbursementOnly =1) 
				THEN 'Reimbursement Only – Best Value'
			WHEN (pp2.ID IS NOT NULL) AND (ISNULL(pp2.IsServiceCoverageBestValue,0) = 1) 
				THEN 'Best Value'
			WHEN (pp2.ID IS NOT NULL) AND (ISNULL(pp2.ServiceCoverageLimit,0) = 0) AND (ISNULL(pp2.ServiceMileageLimit,0) = 0) AND (pp2.IsReimbursementOnly =1) 
				THEN 'Reimbursement Only - Provide Assistance'
			WHEN (pp2.ID IS NOT NULL) AND (ISNULL(pp2.ServiceCoverageLimit,0) = 0) AND (ISNULL(pp2.ServiceMileageLimit,0) = 0) 
				THEN 'Assist Only'
			WHEN (pp2.ID IS NOT NULL) AND (ISNULL(pp2.ServiceCoverageLimit,0) = 0) AND (ISNULL(pp2.ServiceMileageLimit,0) > 0) 
				THEN CONVERT(nvarchar(50), ISNULL(pp2.ServiceMileageLimit,0)) + ' ' + pp2.ServiceMileageLimitUOM + ' Limit'
				
			WHEN (pp2.ID IS NOT NULL) AND (ISNULL(pp2.ServiceCoverageLimit,0) > 0) AND (pp2.IsReimbursementOnly =1) AND (ISNULL(pp2.ServiceMileageLimit,0) > 0) 
				THEN 'Reimbursement Only – $' + CONVERT(nvarchar(50),Convert(int,ISNULL(pp2.ServiceCoverageLimit,0.00))) + ' USD Limit'+ '; ' + CONVERT(nvarchar(50), ISNULL(pp2.ServiceMileageLimit,0)) + ' ' + pp2.ServiceMileageLimitUOM + ' Limit'
			WHEN (pp2.ID IS NOT NULL) AND (ISNULL(pp2.ServiceCoverageLimit,0) > 0) AND (pp2.IsReimbursementOnly =1) 
				THEN 'Reimbursement Only – $' + CONVERT(nvarchar(50),Convert(int,ISNULL(pp2.ServiceCoverageLimit,0.00))) + ' USD Limit'

			WHEN (pp2.ID IS NOT NULL) AND (ISNULL(pp2.ServiceCoverageLimit,0) > 0) AND (ISNULL(pp2.ServiceMileageLimit,0) > 0) 
				THEN '$' + CONVERT(nvarchar(50),Convert(int,ISNULL(pp2.ServiceCoverageLimit,0.00))) + ' USD Limit' + '; ' + CONVERT(nvarchar(50), ISNULL(pp2.ServiceMileageLimit,0)) + ' ' + pp2.ServiceMileageLimitUOM + ' Limit'
			WHEN (pp2.ID IS NOT NULL) AND (ISNULL(pp2.ServiceCoverageLimit,0) > 0) 
				THEN '$' + CONVERT(nvarchar(50),Convert(int,ISNULL(pp2.ServiceCoverageLimit,0.00))) + ' USD Limit'
			WHEN (pp2.ID IS NOT NULL) 
				THEN 'Undetermined'
			ELSE NULL
			END 
		)
	,IsPrimaryOverallCovered = CASE 
									WHEN pp.ID IS NOT NULL AND (pp.IsServiceCoverageBestValue = 1 OR pp.ServiceCoverageLimit > 0) THEN 1
									ELSE 0
									END
	,IsSecondaryOverallCovered = CASE 
									WHEN sr.SecondaryProductID IS NULL THEN NULL
									WHEN pp2.ID IS NOT NULL AND
										 (pp2.IsServiceCoverageBestValue = 1 OR pp2.ServiceCoverageLimit > 0) THEN 1
									ELSE 0
									END

From [Case] c
Join ServiceRequest sr on c.ID = sr.CaseID
Left Outer Join ProgramProduct pp on c.ProgramID = pp.ProgramID and pp.ProductID = sr.PrimaryProductID
Left Outer Join ProgramProduct pp2 on c.ProgramID = pp2.ProgramID and pp2.ProductID = sr.SecondaryProductID
Where sr.PrimaryServiceEligiblityMessage IS NULL
GO


-- Update SR for different limit for Ford ESP program
UPDATE sr SET
	PrimaryServiceEligiblityMessage = REPLACE(PrimaryServiceEligiblityMessage,'100','200')
	,SecondaryServiceEligiblityMessage = REPLACE(SecondaryServiceEligiblityMessage,'100','200')
FROM [Case] c
JOIN ServiceRequest sr ON sr.CaseID = c.ID
WHERE c.ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Extended Service Plan (RV & COMM)')
	AND (SUBSTRING(c.VehicleVIN, 6, 1) IN ('6','7')
		OR c.VehicleModel IN ('F-650', 'F-750'))
	AND (CHARINDEX('100', sr.PrimaryServiceEligiblityMessage) > 0
		OR CHARINDEX('100', sr.SecondaryServiceEligiblityMessage) > 0)
GO

--Update 9999 to 0, unless it is Ford ESP