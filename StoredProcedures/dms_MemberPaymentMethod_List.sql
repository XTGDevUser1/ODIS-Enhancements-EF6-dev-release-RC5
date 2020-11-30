IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_MemberPaymentMethod_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_MemberPaymentMethod_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_MemberPaymentMethod_List] @memberID = 18590370
CREATE PROC [dbo].[dms_MemberPaymentMethod_List](@memberID INT = NULL, @membershipID INT = NULL)
AS
BEGIN
SELECT
		  MPM.ID as PaymentID
		, MPM.PaymentTypeID as PaymentTypeID
		, PT.Description as PaymentType
		, MPM.CCAccountNumber as CardNumber
		, CASE WHEN MPM.CCPartial IS NOT NULL AND LEN( MPM.CCPartial) > 3 THEN RIGHT(MPM.CCPartial,4)
		  ELSE MPM.CCPartial
		  END AS Last4OfCC
		, MPM.CCPartial as CCPartial
		, MPM.CCExpireDate as ExpirationDate
		, datepart(mm,MPM.CCExpireDate)as ExpirationMonth
		, datepart(yy,MPM.CCExpireDate)as ExpirationYear
		, MPM.CCNameOnCard as NameOnCard
		, MPM.BillingLine1 as Address1
		, MPM.BillingLine2 as Address2
		, MPM.BillingCity as City
		, MPM.BillingStateProvince as StateProvince
		, MPM.BillingPostalCode as PostalCode
		, MPM.BillingCountryCode as CoutnryCode
		, MPM.BillingStateProvinceID as StateProvinceID
		, MPM.BillingCountryID as CountryID
		, MPM.Comments as Comments
		, MPM.CreateDate as CreateDate
		, MPM.CreateBy as Username			
		,ISNULL(REPLACE(RTRIM(
			COALESCE(MPM.BillingLine1,'') +
			COALESCE(' ' + MPM.BillingLine2,'') +
			COALESCE(', ' + MPM.BillingCity,'') +
			COALESCE(', ' + MPM.BillingStateProvince,'') +
			COALESCE(' ' + MPM.BillingPostalCode,'') +
			COALESCE(' ' + MPM.BillingCountryCode,'') 
			), '  ', ' ')
		,'') AS [BillingAddress]
		  
FROM		MemberPaymentMethod  MPM WITH(NOLOCK)
JOIN		PaymentType PT WITH(NOLOCK) on PT.ID = MPM.PaymentTypeID
WHERE		(
				(@memberID IS NULL OR @memberID = MPM.MemberID)
				OR			
				(@membershipID IS NULL OR @membershipID = MPM.MembershipID)
			)
ORDER BY	MPM.CreateDate DESC -- CR : 1296

END
