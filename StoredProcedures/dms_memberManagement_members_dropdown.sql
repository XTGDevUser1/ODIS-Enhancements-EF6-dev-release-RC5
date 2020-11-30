IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_memberManagement_members_dropdown]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_memberManagement_members_dropdown] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
CREATE PROC [dbo].[dms_memberManagement_members_dropdown] (@MembershipID INT = NULL)
AS
BEGIN

DECLARE @now DATETIME, @minDate DATETIME
	
SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
SET @minDate = '1900-01-01'  

SELECT	  M.ID
		, MS.MembershipNumber
		, CASE	WHEN ISNULL(M.EffectiveDate,@minDate) <= @now AND ISNULL(M.ExpirationDate,@minDate) >= @now
					THEN 'Active'
					ELSE 'Inactive'
			END AS Status
		, REPLACE(RTRIM(
			  COALESCE(M.LastName,'')+  
			  COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')+  
			  COALESCE(', '+ CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+
			  COALESCE(' ' + LEFT(M.MiddleName,1),'')
			),'','') AS [MemberName]
FROM	Member M
JOIN	Membership MS ON MS.ID = M.MembershipID
WHERE	M.IsActive = 1
AND		M.MembershipID = @MembershipID
END






GO
