IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_TemporaryCreditCard]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_TemporaryCreditCard] 
 END 
 GO  
CREATE VIEW [dbo].[vw_TemporaryCreditCard]
AS

SELECT 
	cl.ID ClientID
	,cl.Name Client
	,p.ID ProgramID
	,p.Name Program
	,tc.[ID] TemporaryCreditCardID
	,[CreditCardIssueNumber]
	,[CreditCardNumber]
	,[PurchaseOrderID]
	,[VendorInvoiceID]
	,tc.[IssueDate]
	,[IssueBy]
	,[IssueStatus]
	,[ReferencePurchaseOrderNumber]
	,[OriginalReferencePurchaseOrderNumber]
	,[ReferenceVendorNumber]
	,[ApprovedAmount]
	,[TotalChargedAmount]
	,[TemporaryCreditCardStatusID]
	,tcs.Name TemporaryCreditCardStatus
	,[ExceptionMessage]
	,[Note]
	,[PostingBatchID]
	,[AccountingPeriodID]
	,tc.[CreateDate]
	,tc.[CreateBy]
	,tc.[ModifyDate]
	,tc.[ModifyBy]
	,[LastChargedDate]
	,[IsExceptionOverride]
FROM TemporaryCreditCard tc (NOLOCK)
JOIN TemporaryCreditCardStatus tcs (NOLOCK) on tcs.ID = tc.TemporaryCreditCardStatusID
JOIN PurchaseOrder po (NOLOCK) on po.PurchaseOrderNumber = tc.ReferencePurchaseOrderNumber
JOIN ServiceRequest sr (NOLOCK) on sr.ID = po.ServiceRequestID
JOIN [Case] c (NOLOCK) on c.ID = sr.CaseID
JOIN Program p (NOLOCK) on p.ID = c.ProgramID
JOIN Client cl (NOLOCK) on cl.ID = p.ClientID
GO

