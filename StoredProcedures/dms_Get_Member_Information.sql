 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Get_Member_Information]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Get_Member_Information]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- exec dms_Get_Member_Information 541
CREATE PROC [dbo].[dms_Get_Member_Information](@memberID INT = NULL)
AS
BEGIN
	-- KB: Get membership ID of the current member.
	DECLARE @membershipID INT
	SELECT @membershipID = MembershipID FROM Member WHERE ID = @memberID

	DECLARE @memberEntityID INT
	SELECT @memberEntityID = ID FROM Entity WHERE Name = 'Member'

	--KB: Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'

	SET FMTONLY OFF;
	
	;WITH wResults
	AS
	(
	SELECT DISTINCT MS.ID AS MembershipID,
	M.ClientMemberType,
	MS.MembershipNumber,
	CASE MS.IsActive WHEN 1 THEN 'Active' ELSE 'Inactive' END AS MembershipStatus, -- KB: I don't think we are using this.
	P.[Description] AS Program,
	P.ID AS ProgramID,
	AD.Line1 AS Line1,
	PH.PhoneNumber AS HomePhoneNumber, 
	PW.PhoneNumber AS WorkPhoneNumber, 
	PC.PhoneNumber AS CellPhoneNumber,
	ISNULL(AD.City,'') + ' ' + ISNULL(AD.StateProvince,'') + ' ' +  ISNULL(AD.PostalCode,'') AS CityStateZip,
	CN.Name AS 'CountryName',
	M.Email,
	M.ID AS MemberID,
	CASE M.IsPrimary WHEN 1 THEN '*' ELSE '' END AS MasterMember,
	--ISNULL(M.FirstName,'') + ' ' + ISNULL(M.LastName,'') + ' ' + ISNULL(M.Suffix,'') AS MemberName,
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
	END AS MemberStatus,
	M.ExpirationDate,
	M.EffectiveDate,
	C.ID AS ClientID,
	C.Name AS ClientName,
	MS.Note AS MembershipNote	,
	M.FirstName,
	M.MiddleName,
	M.LastName,
	M.Suffix,
	M.Prefix
	FROM Member M
	LEFT JOIN Membership MS ON MS.ID = M.MembershipID
	LEFT JOIN Program P ON M.ProgramID = P.ID
	LEFT JOIN Client C ON P.ClientID = C.ID
	LEFT JOIN PhoneEntity PH ON PH.RecordID = M.ID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID 
	LEFT JOIN PhoneEntity PW ON PW.RecordID = M.ID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID 
	LEFT JOIN PhoneEntity PC ON PC.RecordID = M.ID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID 
	LEFT JOIN AddressEntity AD ON AD.RecordID = M.ID AND AD.EntityID = @memberEntityID
	LEFT JOIN Country CN ON CN.ISOCode = AD.CountryCode
	WHERE MS.ID =  @membershipID -- KB: Performing the check against the right attribute.
	)
	SELECT * FROM wResults M ORDER BY MasterMember DESC,MemberName

END

