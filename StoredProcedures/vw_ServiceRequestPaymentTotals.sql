USE [DMS]
GO

/****** Object:  View [dbo].[vw_ServiceRequestPaymentTotals]    Script Date: 04/26/2016 06:52:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE View [dbo].[vw_ServiceRequestPaymentTotals]
AS

Select 
	ServiceRequestID
	,MAX(PaymentType) PaymentType
	,MAX(PaymentReason) PaymentReason
	,MIN(PaymentDate) PaymentDate
	,SUM(CASE WHEN PaymentTransactionType IN ('Void', 'Credit') THEN Amount*-1.0 ELSE Amount END) Amount
From vw_Payments
Group By ServiceRequestID

GO

