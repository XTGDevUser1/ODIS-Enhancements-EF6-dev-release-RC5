IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_DashboardServiceRequestCount]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_DashboardServiceRequestCount] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
CREATE PROC dms_DashboardServiceRequestCount
AS
BEGIN
DECLARE @StartDate DATE = GETDATE() - 365
DECLARE @EndDate DATE = GETDATE()

DECLARE @result TABLE(
	StatusID INT,
	Sequence INT,
	Name NVARCHAR(50) ,
	SRCount INT,
	StartDate DATE,
	EndDate DATE
)

INSERT INTO @result(StatusID,Sequence,Name,SRCount,StartDate,EndDate)
SELECT SRS.ID,
		CASE
		WHEN SRS.Name = 'Entry' THEN 1
		WHEN SRS.Name = 'Submitted' THEN 2
		WHEN SRS.Name = 'Dispatched' THEN 3
		WHEN SRS.Name = 'Cancelled' THEN 4
		WHEN SRS.Name = 'Completed' THEN 5
		ELSE 5
	END as Sequence,
	SRS.Name,
	0,
	@StartDate,@EndDate FROM ServiceRequestStatus SRS

;with wResult AS(
	SELECT 
	SRS.ID AS 'SRStatusID',
	COUNT(*) AS 'SRCount'
	FROM ServiceRequest SR
	JOIN ServiceRequestStatus SRS ON SR.ServiceRequestStatusID = SRS.ID
	WHERE SR.CreateDate BETWEEN @StartDate AND @EndDate
	GROUP BY SRS.ID
)

UPDATE	@result 
SET		SRCount = WR.SRCount 
FROM	@result R
JOIN	wResult WR ON R.StatusID = WR.	SRStatusID

SELECT * FROM @result ORDER BY Sequence

END