IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[etl_Update_VendorAdminRating]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[etl_Update_VendorAdminRating]
GO

CREATE PROCEDURE [dbo].[etl_Update_VendorAdminRating]
AS
BEGIN

	Update v Set AdministrativeRating = 
		CASE WHEN ContractRate.ContractID IS NOT NULL THEN 59 ELSE 20 END +
		CASE WHEN v.InsuranceExpirationDate >= getdate() THEN 10 ELSE 0 END +
		CASE WHEN v.BankABANumber IS NOT NULL AND v.BankAccountNumber IS NOT NULL THEN 10 ELSE 0 END +
		CASE WHEN [24Hours].VendorID IS NOT NULL THEN 10 ELSE 0 END +
		CASE WHEN v.TaxIDNumber IS NOT NULL AND LEN(v.TaxIDNumber) = 9 THEN 10 ELSE 0 END
	From dbo.Vendor v
	Left Outer Join dbo.[Contract] c On v.ID = c.VendorID
	Left Outer Join (
		Select ContractID
		From dbo.ContractProductRate cpr
		Join dbo.Product p On cpr.ProductID = p.ID
		Where p.ProductTypeID = 1
		and RateTypeID IN (1,4)
		Group By ContractID
		) ContractRate on c.ID = ContractRate.ContractID
	Left Outer Join (
		Select VendorID
		From dbo.VendorLocation 
		Where IsOpen24Hours = 'TRUE'
		Group By VendorID
		) [24Hours] On [24Hours].VendorID = v.ID
	Where v.IsActive = 'TRUE'

END
GO

