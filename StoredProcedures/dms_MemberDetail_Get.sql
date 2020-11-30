
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_MemberDetail_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_MemberDetail_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  
CREATE PROCEDURE [dbo].[dms_MemberDetail_Get]( 
@clientID INT,
@memberID INT
) 
AS 
BEGIN
/*
* Name : dms_MemberDetail_Get
* Purpose : To get the details of a registered owner by client and member ID
* Execution sample : EXEC [dbo].[dms_MemberDetail_Get] 15,15272882
*/
DECLARE @minDate DATETIME = '1900-01-01'
DECLARE @now DATETIME = GETDATE()

SELECT
M.ID AS [MemberID]
, P.ID AS [ProgramID] 
, MS.MembershipNumber AS [MemberNumber]
, M.Prefix AS [Prefix]
, M.FirstName AS [FirstName]
, M.MiddleName AS [MiddleName]
, M.LastName AS [LastName]
, M.Suffix AS [Suffix]
, M.Email AS [Email]
, CONVERT(VARCHAR(10),M.MemberSinceDate,101) AS [MemberSinceDate]
, CONVERT(VARCHAR(10),M.EffectiveDate,101) AS [EffectiveDate]
, CONVERT(VARCHAR(10),M.ExpirationDate,101) AS [ExpirationDate]
, M.ClientMemberKey AS [ClientMemberKey]
, M.IsPrimary AS [IsPrimary]
--, CASE
--WHEN M.ExpirationDate <= getdate()
--THEN 'Active'
--ELSE 'Inactive' 
--END AS [CustomerStatus] -- Add more logic
, CASE	WHEN ISNULL(M.EffectiveDate,@minDate) <= @now AND ISNULL(M.ExpirationDate,@minDate) >= @now
					THEN 'Active'
					ELSE 'Inactive'
			END AS [CustomerStatus]
, AE.Line1 AS [Line1]
, AE.Line2 AS [Line2]
, AE.City AS [City]
, AE.StateProvince AS [StateProvince]
, AE.PostalCode AS [PostalCode]
, AE.CountryCode AS [Country]
, PEH.PhoneNumber AS [HomePhone]
, PEC.PhoneNumber AS [CellPhone]
, PEW.PhoneNumber AS [WorkPhone]
FROM Member M WITH (NOLOCK)
JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
LEFT JOIN AddressEntity AE WITH (NOLOCK) ON AE.RecordID = M.ID AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Member') AND AE.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Home')
LEFT JOIN PhoneEntity PEH WITH (NOLOCK) ON PEH.RecordID = M.ID AND PEH.EntityID = (SELECT ID FROM Entity WHERE Name = 'Member') AND PEH.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Home') 
LEFT JOIN PhoneEntity PEC WITH (NOLOCK) ON PEC.RecordID = M.ID AND PEC.EntityID = (SELECT ID FROM Entity WHERE Name = 'Member') AND PEC.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Cell') 
LEFT JOIN PhoneEntity PEW WITH (NOLOCK) ON PEW.RecordID = M.ID AND PEW.EntityID = (SELECT ID FROM Entity WHERE Name = 'Member') AND PEW.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Work') 
JOIN Program P WITH (NOLOCK) ON P.ID = M.ProgramID
JOIN Client CL WITH (NOLOCK) ON CL.ID = P.ClientID
WHERE CL.ID = @ClientID
AND M.ID = @MemberID 
END