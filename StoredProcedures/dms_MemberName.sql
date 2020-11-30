IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_MemberName]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_MemberName] 
 END 
 GO  
CREATE proc dms_MemberName(@membershipNumber NVARCHAR(100) = NULL)
AS
BEGIN
SELECT	M.ID MemberID,
		REPLACE(RTRIM(
		COALESCE(' ' + CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+
		COALESCE(' ' + LEFT(M.MiddleName,1),'')+
		COALESCE(' ' + CASE WHEN M.LastName = '' THEN NULL ELSE M.LastName END,'')+  
		COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')+
		COALESCE(' - Expiration:' + CONVERT(NVARCHAR(10),M.ExpirationDate,101),'')
		),'','') AS [Member]

FROM		Member M
JOIN		Membership MS WITH(NOLOCK) ON MS.ID = M.MembershipID
WHERE		(@membershipNumber IS NOT NULL AND MS.MembershipNumber = @membershipNumber)
AND			M.IsActive = 1
ORDER BY	M.IsPrimary DESC, M.FirstName
END
