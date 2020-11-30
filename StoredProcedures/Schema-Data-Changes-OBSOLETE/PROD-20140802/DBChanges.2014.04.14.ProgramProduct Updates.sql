
-- Set ServiceCoverageDescription on ProgramProduct Table
UPDATE pp Set ServiceCoverageDescription = 
		CASE
			WHEN pp.IsServiceCoverageBestValue = 1 AND ISNULL(pp.ServiceMileageLimit,0)=0
				THEN pr.Name + ': Best Value'
				
			WHEN pp.IsServiceCoverageBestValue = 1 AND ISNULL(pp.ServiceMileageLimit,0) > 0 
				THEN pr.Name + ': Best value with ' + CAST(pp.ServiceMileageLimit AS nvarchar(10)) + ' Miles' + ' Towing Limit'
				
			WHEN ISNULL(pp.ServiceCoverageLimit,0) > 0 AND ISNULL(pp.ServiceMileageLimit,0)= 0
				THEN pr.Name + ': $' + CAST(CONVERT(int,pp.ServiceCoverageLimit) AS nvarchar(10)) + ' USD Limit'
				
			WHEN ISNULL(pp.ServiceCoverageLimit,0)= 0 AND ISNULL(pp.ServiceMileageLimit,0) > 0 
				THEN pr.Name + ': ' + CAST(pp.ServiceMileageLimit AS nvarchar(10)) + ' Miles' + ' Towing Limit'
				
			WHEN ISNULL(pp.ServiceCoverageLimit,0) > 0 AND ISNULL(pp.ServiceMileageLimit,0)> 0
				THEN pr.Name + ': $' + CAST(CONVERT(int,pp.ServiceCoverageLimit) AS nvarchar(10)) + ' USD Limit' + ' with ' + CAST(pp.ServiceMileageLimit AS nvarchar(10)) + ' Miles' + ' Towing Limit'
				
			WHEN ISNULL(pp.ServiceCoverageLimit,0)=0 AND ISNULL(pp.ServiceMileageLimit,0)= 0
				AND pp.ProductID IN (Select ID From Product Where Name in ('Tech','Information','Concierge'))
				--AND pp.IsReimbursementOnly <> 1
				THEN pr.Name + ': No charge for service'
				
			WHEN ISNULL(pp.ServiceCoverageLimit,0)=0 AND ISNULL(pp.ServiceMileageLimit,0)= 0
				THEN pr.Name + ': Assist Only'
				ELSE ''
		  END 
FROM	ProgramProduct pp
JOIN	Program p on p.ID = pp.ProgramID
JOIN	Product pr on pr.ID = pp.ProductID
JOIN	ProductCategory pc on pc.ID = pr.ProductCategoryID
GO

-- Set special ServiceCoverageDescription values for Program 266 (Ford ESP)
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Fluid Delivery - HD: $200 USD Limit' WHERE ProgramID = 266 AND ProductID = 2
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Jump Start - HD: $200 USD Limit' WHERE ProgramID = 266 AND ProductID = 5
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Basic Lockout: $100 USD Limit for MD; $200 USD Limit for HD' WHERE ProgramID = 266 AND ProductID = 8
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Locksmith: $100 USD Limit for MD; $200 USD Limit for HD' WHERE ProgramID = 266 AND ProductID = 9
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Mobile Mechanic: $100 USD Limit for MD; $200 USD Limit for HD' WHERE ProgramID = 266 AND ProductID = 10
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Tire Change - HD: $200 USD Limit' WHERE ProgramID = 266 AND ProductID = 131
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Tire Repair - HD: $200 USD Limit' WHERE ProgramID = 266 AND ProductID = 132
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Tow - HD: $200 USD Limit with 35 Miles Towing Limit' WHERE ProgramID = 266 AND ProductID = 140
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Tow - HD - Landoll/Lowboy: $200 USD Limit with 35 Miles Towing Limit' WHERE ProgramID = 266 AND ProductID = 143
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Winch - HD: $200 USD Limit' WHERE ProgramID = 266 AND ProductID = 157
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Mobile Mechanic - Diesel: $100 USD Limit for MD; $200 USD Limit for HD' WHERE ProgramID = 266 AND ProductID = 11
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Mobile Mechanic - RV House: $100 USD Limit for MD; $200 USD Limit for HD' WHERE ProgramID = 266 AND ProductID = 12
UPDATE ProgramProduct Set ServiceCoverageDescription = 'Mobile Mechanic - Welder: $100 USD Limit for MD; $200 USD Limit for HD' WHERE ProgramID = 266 AND ProductID = 13
GO