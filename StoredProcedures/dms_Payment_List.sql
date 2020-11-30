IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Payment_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Payment_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC dms_Payment_List @ServiceRequestID = 1058
-- EXEC dms_Payment_List @ServiceRequestID = 1058
CREATE PROC [dbo].[dms_Payment_List](@ServiceRequestID INT = NULL)
AS
BEGIN

--declare @ServiceRequestID INT = 664290

DECLARE @tmpPayments TABLE (
	PaymentID int,
	PaymentTypeID int,
	PaymentType nvarchar(100),
	PaymentStatusID int, 
	PaymentStatus nvarchar(100), 
	PaymentTransactionTypeID int, 
	TransactionType nvarchar(100),
	PaymentReasonID int, 
	PaymentReason nvarchar(100),
	OtherReason nvarchar(100),
	PaymentDate datetime, 
	Amount money, 
	CurrencyTypeID int, 
	CurrencyType nvarchar(5),
	CardNumber nvarchar(4000),
	CCPartial nvarchar(25), 
	CCOrderID nvarchar(100),
	CCTransactionReference nvarchar(100),
	ExpirationDate datetime, 
	ExpirationMonth int, 
	ExpirationYear int,
	NameOnCard nvarchar(50),
	CCAuthCode nvarchar(100),
	CCAuthType nvarchar(50),
	CCTransRef nvarchar(100),
	Address1 nvarchar(100),
	Address2 nvarchar(100),
	City nvarchar(100),
	StateProvince nvarchar(10),
	PostalCode nvarchar(20),
	CoutnryCode nvarchar(2),
	StateProvinceID int, 
	CountryID int, 
	Comments nvarchar(max),
	CreateDate datetime, 
	Username nvarchar(50)
)


INSERT INTO @tmpPayments
SELECT
	  p.ID as PaymentID
	, p.PaymentTypeID as PaymentTypeID
	, pt.Description as PaymentType
	, p.PaymentStatusID as PaymentStatusID
	, ps.Description as PaymentStatus
	, p.PaymentTransactionTypeID as PaymentTransactionTypeID
	, ptt.Description as TransactionType
	, p.PaymentReasonID as PaymentReasonID
	, CASE	WHEN pr.Name = 'Other' THEN  p.PaymentReasonOther
			ELSE pr.Description
		END PaymentReason
	, p.PaymentReasonOther as OtherReason
	, p.PaymentDate as PaymentDate
	, p.Amount as Amount
	, p.CurrencyTypeID as CurrencyTypeID
	, ct.Abbreviation as CurrencyType
	, p.CCAccountNumber as CardNumber
	, p.CCPartial as CCPartial
	, p.CCOrderID
	, p.CCTransactionReference
	, p.CCExpireDate as ExpirationDate
	,datepart(mm,p.CCExpireDate)as ExpirationMonth
	,datepart(yy,p.CCExpireDate)as ExpirationYear
	, p.CCNameOnCard as NameOnCard
	, PA.AuthorizationCode CCAuthCode
	, p.CCAuthType as CCAuthType
	, p.CCTransactionReference as CCTransRef
	, p.BillingLine1 as Address1
	, p.BillingLine2 as Address2
	, p.BillingCity as City
	, p.BillingStateProvince as StateProvince
	, p.BillingPostalCode as PostalCode
	, p.BillingCountryCode as CoutnryCode
	, p.BillingStateProvinceID as StateProvinceID
	, p.BillingCountryID as CountryID
	, p.Comments as Comments
	, p.CreateDate as CreateDate
	, p.CreateBy as Username			
FROM	Payment p
JOIN	PaymentType pt on pt.ID = p.PaymentTypeID
JOIN	PaymentStatus ps on ps.ID = p.PaymentStatusID
JOIN	PaymentTransactionType ptt on ptt.ID = p.PaymentTransactionTypeID
LEFT JOIN PaymentReason pr on pr.ID = p.PaymentReasonID
JOIN	CurrencyType ct on ct.ID = p.CurrencyTypeID 
LEFT JOIN PaymentAuthorization PA ON PA.PaymentID = P.ID
WHERE	p.ServiceRequestID = @ServiceRequestID 

INSERT INTO @tmpPayments
SELECT
	  p.ID as PaymentID
	, p.PaymentTypeID as PaymentTypeID
	, pt.Description as PaymentType
	, p.PaymentStatusID as PaymentStatusID
	, ps.Description as PaymentStatus
	, p.PaymentTransactionTypeID as PaymentTransactionTypeID
	, ptt.Description as TransactionType
	, p.PaymentReasonID as PaymentReasonID
	, CASE	WHEN pr.Name = 'Other' THEN  p.PaymentReasonOther
			ELSE pr.Description
		END PaymentReason
	, p.PaymentReasonOther as OtherReason
	, p.PaymentDate as PaymentDate
	, p.Amount as Amount
	, p.CurrencyTypeID as CurrencyTypeID
	, ct.Abbreviation as CurrencyType
	, p.CCAccountNumber as CardNumber
	, p.CCPartial as CCPartial
	, p.CCOrderID
	, p.CCTransactionReference
	, p.CCExpireDate as ExpirationDate
	,datepart(mm,p.CCExpireDate)as ExpirationMonth
	,datepart(yy,p.CCExpireDate)as ExpirationYear
	, p.CCNameOnCard as NameOnCard
	, PA.AuthorizationCode CCAuthCode
	, p.CCAuthType as CCAuthType
	, p.CCTransactionReference as CCTransRef
	, p.BillingLine1 as Address1
	, p.BillingLine2 as Address2
	, p.BillingCity as City
	, p.BillingStateProvince as StateProvince
	, p.BillingPostalCode as PostalCode
	, p.BillingCountryCode as CoutnryCode
	, p.BillingStateProvinceID as StateProvinceID
	, p.BillingCountryID as CountryID
	, p.Comments as Comments
	, p.CreateDate as CreateDate
	, p.CreateBy as Username	
FROM	Payment p
JOIN	PaymentType pt on pt.ID = p.PaymentTypeID
JOIN	PaymentStatus ps on ps.ID = p.PaymentStatusID
JOIN	PaymentTransactionType ptt on ptt.ID = p.PaymentTransactionTypeID
LEFT JOIN PaymentReason pr on pr.ID = p.PaymentReasonID
JOIN	CurrencyType ct on ct.ID = p.CurrencyTypeID 
LEFT JOIN PaymentAuthorization PA ON PA.PaymentID = P.ID
WHERE	(p.ID = 1661 
		AND	    18631756 = (SELECT c.MemberID FROM ServiceRequest sr JOIN [Case] c ON c.ID = sr.CaseID WHERE sr.ID = @ServiceRequestID))
		OR
		(p.ID = 1664 
		AND	    18669801 = (SELECT c.MemberID FROM ServiceRequest sr JOIN [Case] c ON c.ID = sr.CaseID WHERE sr.ID = @ServiceRequestID))

SELECT	PaymentID
	, PaymentTypeID
	, PaymentType
	, PaymentStatusID
	, PaymentStatus
	, PaymentTransactionTypeID
	, TransactionType
	, PaymentReasonID
	, PaymentReason
	, OtherReason
	, PaymentDate
	, Amount
	, CurrencyTypeID
	, CurrencyType
	, CardNumber
	, CCPartial
	, CCOrderID
	, CCTransactionReference
	, ExpirationDate
	, ExpirationMonth
	, ExpirationYear
	, NameOnCard
	, CCAuthCode
	, CCAuthType
	, CCTransRef
	, Address1
	, Address2
	, City
	, StateProvince
	, PostalCode
	, CoutnryCode
	, StateProvinceID
	, CountryID
	, Comments
	, CreateDate
	, Username	
FROM @tmpPayments 
ORDER BY CreateDate DESC


END
GO

