IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Dashboard_DispatchChart_Labels]')   		AND type in (N'P', N'PC')) 
BEGIN
 DROP PROCEDURE [dbo].[dms_Dashboard_DispatchChart_Labels] 
END 
GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[dms_Dashboard_DispatchChart_Labels]
AS
BEGIN
DECLARE @startDate AS DATE 
SET @startDate = DATEADD(m,-11,GETDATE())
DECLARE @EndDate AS DATE = GETDATE() 

DECLARE @Label AS TABLE(
Label1 NVARCHAR(6),
Label2 NVARCHAR(6),
Label3 NVARCHAR(6),
Label4 NVARCHAR(6),
Label5 NVARCHAR(6),
Label6 NVARCHAR(6),
Label7 NVARCHAR(6),
Label8 NVARCHAR(6),
Label9 NVARCHAR(6),
Label10 NVARCHAR(6),
Label11 NVARCHAR(6),
Label12 NVARCHAR(6)
)

INSERT INTO @Label(Label1,Label2,Label3,Label4,Label5,Label6,Label7,Label8,Label9,Label10,Label11,Label12) 

SELECT 
	(CONVERT(VARCHAR(3), @StartDate,0) + '-' + RIGHT(YEAR(@StartDate),2) ),
	(CONVERT(VARCHAR(3), DATEADD(mm,1,@StartDate),0) + '-' + RIGHT(YEAR(DATEADD(M,1,@StartDate)),2) ),
	(CONVERT(VARCHAR(3), DATEADD(mm,2,@StartDate),0) + '-' + RIGHT(YEAR(DATEADD(M,2,@StartDate)),2) ),
	(CONVERT(VARCHAR(3), DATEADD(mm,3,@StartDate),0) + '-' + RIGHT(YEAR(DATEADD(M,3,@StartDate)),2) ),
	(CONVERT(VARCHAR(3), DATEADD(mm,4,@StartDate),0) + '-' + RIGHT(YEAR(DATEADD(M,4,@StartDate)),2) ),
	(CONVERT(VARCHAR(3), DATEADD(mm,5,@StartDate),0) + '-' + RIGHT(YEAR(DATEADD(M,5,@StartDate)),2) ),
	(CONVERT(VARCHAR(3), DATEADD(mm,6,@StartDate),0) + '-' + RIGHT(YEAR(DATEADD(M,6,@StartDate)),2) ),
	(CONVERT(VARCHAR(3), DATEADD(mm,7,@StartDate),0) + '-' + RIGHT(YEAR(DATEADD(M,7,@StartDate)),2) ),
	(CONVERT(VARCHAR(3), DATEADD(mm,8,@StartDate),0) + '-' + RIGHT(YEAR(DATEADD(M,8,@StartDate)),2) ),
	(CONVERT(VARCHAR(3), DATEADD(mm,9,@StartDate),0) + '-' + RIGHT(YEAR(DATEADD(M,9,@StartDate)),2) ),
	(CONVERT(VARCHAR(3), DATEADD(mm,10,@StartDate),0) + '-' + RIGHT(YEAR(DATEADD(M,10,@StartDate)),2) ),
	(CONVERT(VARCHAR(3), DATEADD(mm,11,@StartDate),0) + '-' + RIGHT(YEAR(DATEADD(M,11,@StartDate)),2) )

SELECT * FROM @Label

END

GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_VendorLocation_GeographyLocation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VendorLocation_GeographyLocation]
 END 
 GO  

CREATE PROC dbo.[dms_VendorLocation_GeographyLocation](@vendorLocationID INT = NULL)
AS
BEGIN
DECLARE @Result AS TABLE(
	
	Latitude DECIMAL(10,7) NULL,
	Longitude DECIMAL(10,7) NULL
)

INSERT INTO @Result SELECT GeographyLocation.Lat,GeographyLocation.Long FROM VendorLocation WHERE ID = @vendorLocationID

SELECT * FROM @Result

END

GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Dashboard_DispatchChart]')   		AND type in (N'P', N'PC')) 
BEGIN
 DROP PROCEDURE [dbo].[dms_Dashboard_DispatchChart] 
END 
GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[dms_Dashboard_DispatchChart]
AS
BEGIN
DECLARE @startDate AS DATE 
SET @startDate = DATEADD(m,-11,GETDATE())
DECLARE @EndDate AS DATE = GETDATE() 


--====================================================================================================================
-- Service Request Count
--
--
-- 1. Setup Stored Procedure to drive chart.... convert to cross-tab query
-- 2. Setup chart on Dashboard for Dispatch
-- 3. Use line chart
-- 4. Title = Serivce Request Count
-- 5. Vertical Axis = service request counts:  0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000
-- 6. Horizontal Axis = NMC, Ford, Hagerty, Others
-- 7. Show Jan to Dec


-- Line Graph

-- Show monthly totals of call counts by clients

-- Set 

--82559
DECLARE @Result AS TABLE(
Client NVARCHAR(50),
Month1 INT,
Month2 INT,
Month3 INT,
Month4 INT,
Month5 INT,
Month6 INT,
Month7 INT,
Month8 INT,
Month9 INT,
Month10 INT,
Month11 INT,
Month12 INT
)

INSERT INTO @Result(Client,Month1,Month2,Month3,Month4,Month5,Month6,Month7,Month8,Month9,Month10,Month11,Month12)

SELECT 
	CASE  
		WHEN cl.Name = 'Coach-Net' THEN 'Coach-Net'
		WHEN cl.Name = 'National Motor Club' THEN 'NMC'
		WHEN cl.Name = 'Ford' Then 'Ford'
		WHEN cl.Name = 'Hagerty' Then 'Hagerty'
		ELSE 'Other'
	  END as Client
	--, datepart(mm,sr.CreateDate) AS 'Month'
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,@startDate) THEN count(sr.id)
	  END,0) AS Jan
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,1,@startDate))) THEN count(sr.id)
	  END,0) as Feb
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,2,@startDate))) THEN count(sr.id)
	  END,0) as Mar
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,3,@startDate))) THEN count(sr.id)
	  END,0) as Apr
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,4,@startDate))) THEN count(sr.id)
	  END,0) as May
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,5,@startDate))) THEN count(sr.id)
	  END,0) as Jun
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,6,@startDate))) THEN count(sr.id)
	  END,0) AS Jul
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,7,@startDate))) THEN count(sr.id)
	  END,0) as Aug
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,8,@startDate))) THEN count(sr.id)
	  END,0) as Sep
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,9,@startDate))) THEN count(sr.id)
	  END,0) as Oct
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,10,@startDate))) THEN count(sr.id)
	  END,0) as Nov
	, ISNULL(CASE
		WHEN datepart(mm,sr.CreateDate) = datepart(mm,(DATEADD(m,11,@startDate))) THEN count(sr.id)
	  END,0) as Dec
FROM ServiceRequest sr
JOIN ServiceRequestStatus srs ON srs.ID = sr.ServiceRequestStatusID
JOIN [Case] c ON c.ID = sr.CaseID
JOIN Program p on p.ID = c.ProgramID
JOIN Program pp on pp.ID = p.ParentProgramID
JOIN Client cl on cl.ID = p.ClientID
WHERE
	sr.CreateDate between @StartDate and @EndDate
	AND sr.ServiceRequestStatusID IN (SELECT ID FROM ServiceRequestStatus WHERE Name IN ('Complete','Cancelled'))
GROUP BY
		CASE
		WHEN cl.Name = 'Coach-Net' THEN 'Coach-Net'
		WHEN cl.Name = 'National Motor Club' THEN 'NMC'
		WHEN cl.Name = 'Ford' Then 'Ford'
		WHEN cl.Name = 'Hagerty' Then 'Hagerty'
		ELSE 'Other'
	  END
	  , datepart(mm,sr.createdate)
ORDER BY
	CASE
		WHEN cl.Name = 'Coach-Net' THEN 'Coach-Net'
		WHEN cl.Name = 'National Motor Club' THEN 'NMC'
		WHEN cl.Name = 'Ford' Then 'Ford'
		WHEN cl.Name = 'Hagerty' Then 'Hagerty'
		ELSE 'Other'
	END 
	, datepart(mm,sr.CreateDate)
	
SELECT Client,
	  SUM(Month1) AS 'Month1',
	  SUM(Month2) AS 'Month2',
	  SUM(Month3) AS 'Month3' ,
	  SUM(Month4) AS 'Month4' ,
	  SUM(Month5) AS 'Month5' ,
	  SUM(Month6) AS 'Month6' ,
	  SUM(Month7) AS 'Month7' ,
	  SUM(Month8) AS 'Month8' ,
	  SUM(Month9) AS 'Month9' ,
	  SUM(Month10) AS 'Month10' ,
	  SUM(Month11) AS 'Month11' ,
	  SUM(Month12) AS 'Month12' 
FROM @Result
GROUP BY Client
END


GO



IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Dashboard_ServiceCallActivity]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Dashboard_ServiceCallActivity]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
CREATE PROC dms_Vendor_Dashboard_ServiceCallActivity(@VendorID INT = NULL)
AS
BEGIN
	/* Month numbers for the last 12 months */
	DECLARE @Months TABLE (MonthNumber int)
	
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-0, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-1, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-2, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-3, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-4, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-5, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-6, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-7, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-8, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-9, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-10, getdate())))
	INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-11, getdate())))
	--INSERT INTO @Months (MonthNumber) VALUES (MONTH(DATEADD(mm,-12, getdate())))

	SELECT m.MonthNumber, ISNULL(va.TotalCalls,0) TotalCalls, ISNULL(va.AcceptedCalls,0) AcceptedCalls
	FROM @Months m
	LEFT OUTER JOIN (
		SELECT 
			MONTH(VendorContactLog.CreateDate) MonthNumber
			,COUNT(*) TotalCalls
			,SUM(CASE WHEN VendorContactLog.ContactAction = 'Accepted' THEN 1 ELSE 0 END) AcceptedCalls
		FROM [dbo].[fnc_GetVendorLocationProduct_ContactLog] () VendorContactLog
		WHERE VendorContactLog.VendorID = @VendorID
		GROUP BY MONTH(VendorContactLog.CreateDate)
		) va ON va.MonthNumber = m.MonthNumber
	--ORDER BY m.MonthNumber
END

GO