IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Contract_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Contract_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_Vendor_Contract_Details_Get @ContractID=1
 CREATE PROCEDURE [dbo].dms_Vendor_Contract_Details_Get @ContractID INT
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
SELECT C.ID
	, CS.ID AS [ContractStatusID]
	, CS.Name as [ContractStatus]
	, C.StartDate
	, C.EndDate
	, C.SignedDate
	, C.SignedBy
	, C.SignedByTitle
	, VTA.ID AS VTAID
	, VTA.EffectiveDate
	, SS.Name AS Source
	, C.CreateBy
	, C.CreateDate
	, C.ModifyBy
	, C.ModifyDate
FROM Contract C
LEFT JOIN ContractStatus CS ON CS.ID = C.ContractStatusID
LEFT JOIN VendorTermsAgreement VTA ON VTA.ID = C.VendorTermsAgreementID
LEFT JOIN SourceSystem SS ON SS.ID = C.SourceSystemID
WHERE C.ID = @ContractID
END
GO
