IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[vw_BillingInvoiceDefinitions]')   		AND type in (N'V')) 
BEGIN
DROP VIEW [dbo].[vw_BillingInvoiceDefinitions] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 

CREATE VIEW [dbo].[vw_BillingInvoiceDefinitions]
AS
Select TOP (2000000)
	c.ID ClientID
	,c.Name Client
	,bdi.ID DefinitionInvoiceID
	,bdi.Name Invoice
	,bdi.AccountingSystemAddressCode
	,bdi.AccountingSystemCustomerNumber
	,Case WHEN bdi.IsActive = 1 THEN 'Active' ELSE 'Inactive' END InvoiceStatus
	,bdi.PONumber ClientPONumber
	,bdil.ID DefinitionInvoiceLineID
	,bdil.Name LineItemName
	,bdil.[Description] LineItemDesc	
	,bdil.Sequence LineItemNumber
	,prod.ID ProductID
	,prod.Name Product
	,rt.ID RateTypeID
	,rt.Name RateType
	,bdil.Rate
	,bdil.FixedQuantity
	,bdil.Comment
	,bils.Name DefaultLineStatus
	,bdile.ID DefinitionInvoiceLineEventID
	,bdile.Name LineItemBillingEvent
	,bdile.IsEditable IsLineEventEditable
	,bdile.IsAdjustable IsLineEventAdjustable
	,bde.ID BillingDefinitionEventID
	,bde.DBObject 
	,bdile.EventFilter LineItemBillingEventFilter
	,bilgw.Name LineItemEventGenWhen
	,bidtls.Name DefaultInvoiceDetailStatus
	,ProgramList.Programs
	,prod.AccountingSystemGLCode
	,prod.AccountingSystemItemCode
From [dbo].[BillingDefinitionInvoice] bdi
Join Client c on c.ID = bdi.ClientID
Join dbo.BillingDefinitionInvoiceLine bdil on bdil.BillingDefinitionInvoiceID = bdi.ID and bdil.IsActive = 1
Left Outer Join dbo.BillingInvoiceLineStatus bils on bils.ID = bdil.DefaultInvoiceLineStatusID
Join dbo.RateType rt on bdil.RateTypeID = rt.ID
Join dbo.Product prod on prod.ID = bdil.ProductID
Join dbo.BillingDefinitionInvoiceLineEvent bdile on bdile.BillingDefinitionInvoiceLineID = bdil.ID and bdile.IsActive = 1
Join dbo.BillingDefinitionEvent bde on bde.ID = bdile.BillingDefinitionEventID
Left Outer Join dbo.BillingInvoiceLineEventGenWhen bilgw on bilgw.ID = bdile.EventGenWhenID
Left Outer Join dbo.BillingInvoiceDetailStatus bidtls on bidtls.ID = bdile.DefaultInvoiceDetailStatusID
Join (
	select distinct t1.BillingDefinitionInvoiceLineEventID,
	  STUFF(
			 (SELECT ', ' + '(' + convert(varchar(255), p.ID) + ') '  +  convert(varchar(255), Replace(p.Name,'&',' and '))
			  FROM BillingDefinitionInvoiceLineEventProgram t2
			  Join Program p on p.ID = t2.ProgramID
			  where t1.BillingDefinitionInvoiceLineEventID = t2.BillingDefinitionInvoiceLineEventID
			  FOR XML PATH (''))
			  , 1, 1, '')  AS Programs
	from BillingDefinitionInvoiceLineEventProgram t1
	Where t1.IsActive = 1
	) ProgramList ON ProgramList.BillingDefinitionInvoiceLineEventID = bdile.ID
Where 1=1
--and bdi.IsActive = 1
Order by c.Name, bdi.Name, bdil.Sequence
GO