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