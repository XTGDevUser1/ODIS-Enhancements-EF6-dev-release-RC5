-- AddressEntity records for Hagerty Members
SELECT	AE.*
FROM	AddressEntity AE WITH (NOLOCK)
JOIN	Member M WITH (NOLOCK)  ON AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Member') AND AE.RecordID = M.ID
JOIN	Program P WITH (NOLOCK) ON M.ProgramID = P.ID
JOIN	Client C WITH (NOLOCK) ON P.ClientID = C.ID
WHERE	C.Name = 'Hagerty'
AND		AE.StateProvinceId is not null 
AND		AE.CountryID = 1 
AND		AE.Line1 is null 
AND		AE.Line2 is null 
AND		AE.PostalCode is not null 
AND		AE.Line3 is null
AND		AE.CreateBy NOT IN ( 'system', 'DispatchPost','API')

-- AddressEntity records for Hagerty Membership

SELECT	AE.*
FROM	AddressEntity AE WITH (NOLOCK)
JOIN	Membership MS WITH (NOLOCK) ON AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Membership') AND AE.RecordID = MS.ID
JOIN	Member M WITH (NOLOCK)  ON M.MembershipID = MS.ID
JOIN	Program P WITH (NOLOCK) ON M.ProgramID = P.ID
JOIN	Client C WITH (NOLOCK) ON P.ClientID = C.ID
WHERE	C.Name = 'Hagerty'
AND		AE.StateProvinceId is not null 
AND		AE.CountryID = 1 
AND		AE.Line1 is null 
AND		AE.Line2 is null 
AND		AE.PostalCode is not null 
AND		AE.Line3 is null
AND		AE.CreateBy NOT IN ( 'system', 'DispatchPost','API')

-- DELETE Bad records for Member and Membership
-- Member
DELETE FROM AddressEntity
WHERE	ID IN
(
SELECT	AE.ID
FROM	AddressEntity AE WITH (NOLOCK)
JOIN	Member M WITH (NOLOCK)  ON AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Member') AND AE.RecordID = M.ID
JOIN	Program P WITH (NOLOCK) ON M.ProgramID = P.ID
JOIN	Client C WITH (NOLOCK) ON P.ClientID = C.ID
WHERE	C.Name = 'Hagerty'
AND		AE.StateProvinceId is not null 
AND		AE.CountryID = 1 
AND		AE.Line1 is null 
AND		AE.Line2 is null 
AND		AE.PostalCode is not null 
AND		AE.Line3 is null
AND		AE.CreateBy NOT IN ( 'system', 'DispatchPost','API')

UNION ALL

SELECT	AE.ID
FROM	AddressEntity AE WITH (NOLOCK)
JOIN	Membership MS WITH (NOLOCK) ON AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Membership') AND AE.RecordID = MS.ID
JOIN	Member M WITH (NOLOCK)  ON M.MembershipID = MS.ID
JOIN	Program P WITH (NOLOCK) ON M.ProgramID = P.ID
JOIN	Client C WITH (NOLOCK) ON P.ClientID = C.ID
WHERE	C.Name = 'Hagerty'
AND		AE.StateProvinceId is not null 
AND		AE.CountryID = 1 
AND		AE.Line1 is null 
AND		AE.Line2 is null 
AND		AE.PostalCode is not null 
AND		AE.Line3 is null
AND		AE.CreateBy NOT IN ( 'system', 'DispatchPost','API')
)