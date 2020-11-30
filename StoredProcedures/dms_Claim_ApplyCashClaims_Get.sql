IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Claim_ApplyCashClaims_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Claim_ApplyCashClaims_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Claim_ApplyCashClaims_Get] 
-- EXEC [dbo].[dms_Claim_ApplyCashClaims_Get] 
CREATE PROCEDURE [dbo].[dms_Claim_ApplyCashClaims_Get]
AS  
BEGIN

-- Claim List
SELECT		CT.Name AS Type
			, C.ID AS ClaimNumber
			, C.ReceivedDate  
			, C.AmountRequested
			, CASE
                        WHEN ISNULL(C.PayeeType,'') = 'Member' THEN 'M-' + C.ContactName
                        WHEN ISNULL(C.PayeeType,'') = 'Vendor' THEN 'V-' + C.ContactName
                        ELSE C.ContactName
              END AS Payee
			, CS.Name AS Status
			, C.AmountApproved AS ApprovedAmount
			, C.ACESReferenceNumber
			, C.ACESSubmitDate
			, C.ACESOutcome
			, C.ACESAmount
			, CASE
				WHEN P.Name = 'Ford Fleet Care' THEN 1
				ELSE 0
			  END AS QFCFlag
			,'' Applied 
			,CAST( 0 as bit) Selected
			, C.ACESFeeAmount
FROM		Claim C
JOIN		ClaimType CT ON CT.ID = C.ClaimTypeID
LEFT JOIN   ACESClaimStatus ACS ON ACS.ID = C.ACESClaimStatusID
JOIN		ClaimStatus CS ON CS.ID = C.ClaimStatusID
LEFT JOIN	Member M WITH(NOLOCK) ON M.ID = C.MemberID
LEFT JOIN	Program P WITH(NOLOCK) ON P.ID = M.ProgramID
LEFT JOIN	Vendor V WITH(NOLOCK) ON V.ID = C.VendorID
WHERE		CT.IsFordACES = 1
AND			CS.Name = 'Approved'
AND			ACS.Name = 'Approved'
AND			C.IsActive = 1
AND			ISNULL(C.ACESClearedDate,'') = ''
ORDER BY	QFCFlag DESC, C.ReceivedDate ASC

END
GO

