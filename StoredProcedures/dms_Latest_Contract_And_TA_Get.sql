IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Latest_Contract_And_TA_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Latest_Contract_And_TA_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
/*

	EXEC [dbo].[dms_Latest_Contract_And_TA_Get] 609
	EXEC [dbo].[dms_Latest_Contract_And_TA_Get] 316
*/
CREATE PROCEDURE [dbo].[dms_Latest_Contract_And_TA_Get](
	@vendorID INT
)
AS
BEGIN

	SELECT TOP 1
			C.ID AS ContractID,
			VTA.ID AS VendorTermsAgreementID,
			VTA.[FileName] AS VendorTermsAgreementFileName,
			CRS.ID AS ContractRateScheduleID
	FROM	[Contract] C WITH(NOLOCK)
	LEFT JOIN VendorTermsAgreement VTA WITH(NOLOCK) ON C.VendorTermsAgreementID = VTA.ID
	LEFT JOIN ContractRateSchedule CRS WITH(NOLOCK) ON CRS.ContractID = C.ID
	WHERE	C.VendorID = @vendorID 
	AND		C.IsActive = 1 
	AND		C.ContractStatusID = (Select ID FROM ContractStatus where Name = 'Active')
	AND		CRS.ContractRateScheduleStatusID = (Select ID FROM ContractRateScheduleStatus where Name = 'Active')
	ORDER BY C.CreateDate DESC, CRS.CreateDate DESC
END
