USE [DMS]
GO

/****** Object:  View [dbo].[vw_Clients]    Script Date: 04/26/2016 06:53:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[vw_Clients]
AS
Select TOP 1000000
	c.ID ClientID
	,c.Name ClientName
	,c.[Description] ClientDescription
	,c.ClientTypeID
	,ct.Name ClientType
	,c.IsActive
	,c.AccountingSystemCustomerNumber
	,c.AccountingSystemAddressCode
	,c.AccountingSystemDivisionCode
	,c.Avatar
	,c.ClientRepID
	,cr.FirstName RepFirstName
	,cr.LastName RepLastName
	,cr.Email RepEmail
	,c.MainContactFirstName
	,c.MainContactLastName
	,c.MainContactPhone
	,c.MainContactEmail
	,c.FTPFolder
	,c.Website
	,c.CreateDate
	,c.CreateBy
	,c.ModifyDate
	,c.ModifyBy
	,bi.LastEndingInvoiceDate
From dbo.Client c
Join ClientType ct on ct.ID = c.ClientTypeID
Left Outer Join ClientRep cr on cr.ID = c.ClientRepID
Left Outer Join (
	Select ClientID, MAX(ScheduleRangeEnd) LastEndingInvoiceDate
	From dbo.BillingInvoice
	Group By ClientID
	)bi on c.ID = bi.ClientID
Order by c.Name



GO

