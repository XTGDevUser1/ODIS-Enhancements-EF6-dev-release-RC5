		
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Membsership_Information]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Membsership_Information] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 	
 -- EXEC [dbo].[dms_Membsership_Information] 1
 CREATE PROC [dbo].[dms_Membsership_Information](@memberID INT = NULL)
 AS
 BEGIN
	
	-- Dates used while calculating member status
DECLARE @now DATETIME, @minDate DATETIME
SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
SET @minDate = '1900-01-01'
	
	SELECT	m.ID AS MemberID,
		
		REPLACE(RTRIM( 
COALESCE(M.FirstName, '') + 
COALESCE(' ' + left(M.MiddleName,1), '') + 
COALESCE(' ' + M.LastName, '') +
COALESCE(' ' + M.Suffix, '')
), ' ', ' ') AS MemberName,
			
		-- KB: Considering Effective and Expiration Dates to calculate member status	
		CASE WHEN ISNULL(m.EffectiveDate,@minDate) <= @now AND ISNULL(m.ExpirationDate,@minDate) >= @now
				THEN 'Active'
				ELSE 'Inactive'
		END	AS MemberStatus,
		ms.MembershipNumber AS MemberNumber,
		c.Name AS Client,  
		--parent.Code AS Program,  
		p.[Description] as Program,
		(SELECT MAX(ServiceCoverageLimit)FROM ProgramProduct pp WHERE pp.ProgramID = p.ID) as Limit,		
		CONVERT(varchar(10),m.MemberSinceDate,101) AS MemberSince,
		CONVERT(VARCHAR(10),m.ExpirationDate,101)AS Expiration, 
		m.ExpirationDate AS ExpirationDate,
		m.EffectiveDate AS EffectiveDate,
		CONVERT(VARCHAR(10),m.EffectiveDate,101)AS Effective, 
		ms.ClientReferenceNumber as ClientRefNumber, 
		ms.CreateDate as Created, 
		ms.ModifyDate as LastUpdate,
		ms.Note as MembershipNote,
		M.FirstName,
		M.MiddleName,
		M.LastName,
		M.Prefix,
		M.Suffix
	FROM Member m 
	JOIN Membership ms ON ms.ID = m.MembershipID
	JOIN Program p ON p.id = m.ProgramID
	LEFT OUTER JOIN Program parent ON parent.ID = p.ParentProgramID
	JOIN Client c ON c.ID = p.ClientID
	WHERE m.ID = @MemberID

END
