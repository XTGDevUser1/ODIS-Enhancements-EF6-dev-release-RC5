
/****** Object:  View [dbo].[vw_Payments]    Script Date: 04/26/2016 06:52:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE View [dbo].[vw_Payments]
as

Select 
	p.ID PaymentID
	,p.ServiceRequestID
	,p.PaymentTypeID
	,pt.Name PaymentType
	,p.PaymentStatusID
	,ps.Name PaymentStatus
	,p.PaymentTransactionTypeID
	,ptt.Name PaymentTransactionType
	,p.PaymentReasonID
	,Case When pr.Name = 'Other' Then p.PaymentReasonOther Else pr.Name END PaymentReason
	,p.PaymentDate
	,p.Amount
	--,ptran.TransactionAmount
	,p.CurrencyTypeID
	,ct.Abbreviation CurrencyType
	,p.CCOrderID
	,p.CCPartial CreditCardNumber
	,p.CCExpireDate CreditCardExpirationDate
	,p.CCNameOnCard NameOnCreditCard
	,p.CCAuthCode CreditCardAuthorizationCode
	,p.CCAuthType CreditCardAuthorizationType
	,p.CCTransactionReference CreditCardTransactionReference
	,p.BillingLine1
	,p.BillingLine2
	,p.BillingCity
	,p.BillingStateProvince
	,p.BillingPostalCode
	,p.BillingCountryID
	,p.BillingCountryCode
	,p.Comments
	,p.CreateDate
	,p.CreateBy
	,p.ModifyDate
	,p.ModifyBy
	,pa.ID PaymentAuthorizationID
	,pa.AuthorizationDate
	,pa.AuthorizationCode
	,pa.AuthorizationType
	,pa.ReferenceNumber AuthorizationReferenceNumber
	,pa.Amount AuthorizationAmount
	,pa.ProcessorReferenceNumber
	,pa.CreateDate AuthorizationCreateDate
	,pa.CreateBy AuthorizationCreateBy
	,ptran.StoreNumber
from Payment p
Left Outer Join (
	Select pa1.*
	From PaymentAuthorization pa1 
	Join (
		Select PaymentID, MAX(SequenceNumber) SequenceNumber
		From PaymentAuthorization
		Group By PaymentID 
		) LastAuthorization on LastAuthorization.PaymentID = pa1.PaymentID and LastAuthorization.SequenceNumber = pa1.SequenceNumber 
	) pa on pa.PaymentID = p.ID
Left Outer Join PaymentType pt on pt.ID = p.PaymentTypeID
Left Outer Join PaymentCategory pc on pc.ID = pt.PaymentCategoryID
Left Outer Join PaymentStatus ps on ps.ID = p.PaymentStatusID
Left Outer Join PaymentReason pr on pr.ID = p.PaymentReasonID
Left Outer Join PaymentTransactionType ptt on ptt.ID = p.PaymentTransactionTypeID
Left Outer Join CurrencyType ct on ct.ID = p.CurrencyTypeID
Left Outer Join (
	Select ptran1.PaymentID, MAX(ptran1.StoreNumber) StoreNumber
	From PaymentTransaction ptran1
	Join PaymentStatus ps1 on ps1.ID = ptran1.PaymentStatusID
	Where ps1.Name = 'Approved'
	Group By ptran1.PaymentID
	) ptran on ptran.PaymentID = p.ID
GO

