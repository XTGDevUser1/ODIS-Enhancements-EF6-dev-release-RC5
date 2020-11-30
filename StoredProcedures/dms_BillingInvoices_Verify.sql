IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_BillingInvoices_Verify]')   		AND type in (N'P', N'PC')) 
BEGIN
	DROP PROCEDURE [dbo].[dms_BillingInvoices_Verify] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 
 -- EXEC [dms_BillingInvoices_Verify] @invoicesCSV= '1,2,3,4,5,6,7,8'
CREATE PROCEDURE [dbo].[dms_BillingInvoices_Verify]( 
@invoicesCSV NVARCHAR(MAX)
)
AS
BEGIN

	--DECLARE @invoicesCSV NVARCHAR(MAX) = '1,2,3,4,5,6,7,8'

	DECLARE @tblInvoices TABLE
	(
		InvoiceID INT
	)

	INSERT INTO @tblInvoices
	SELECT CAST(item as INT) FROM [dbo].[fnSplitString](@invoicesCSV,',')

	--DEBUG: SELECT * FROM @tblInvoices
	
	
	DECLARE @tblExceptions TABLE
	(
		InvoiceID INT,
		InvoiceName NVARCHAR(255) NULL,
		InvoiceStatus NVARCHAR(100) NULL,
		ExceptionMessage NVARCHAR(MAX) NULL
			
	)

	DECLARE @readyStatusID INT
	SELECT @readyStatusID = ID FROM BillingInvoiceStatus WHERE Name = 'Ready'

	INSERT INTO @tblExceptions
	SELECT	BI.ID,
			BI.Name,
			BIS.Name,
			'Status not Ready or missing AccountingSystemCustomerNumber OR AccountingSystemAddressCode'
	FROM	@tblInvoices T
	JOIN	BillingInvoice BI WITH (NOLOCK) ON T.InvoiceID = BI.ID
	JOIN	BillingInvoiceStatus BIS WITH (NOLOCK) ON BI.InvoiceStatusID = BIS.ID
	WHERE	BI.InvoiceStatusID <> @readyStatusID
	OR		ISNULL(BI.AccountingSystemCustomerNumber,'') = ''
	OR		ISNULL(BI.AccountingSystemAddressCode,'') = ''

	INSERT INTO @tblExceptions
	SELECT	DISTINCT BI.ID,
			BI.Name,
			BIS.Name,
			'Missing AccountingSystemItemCode on one or more Invoice Lines'
	FROM	@tblInvoices T
	JOIN	BillingInvoiceLine BIL WITH (NOLOCK) ON T.InvoiceID = BIL.BillingInvoiceID
	JOIN	BillingInvoice BI WITH (NOLOCK) ON BIL.BillingInvoiceID = BI.ID
	JOIN	BillingInvoiceStatus BIS WITH (NOLOCK) ON BI.InvoiceStatusID = BIS.ID
	WHERE	ISNULL(BIL.AccountingSystemItemCode,'') = ''

	
	
	SELECT	T.InvoiceID,
			T.InvoiceName,
			[dbo].[fnConcatenate](T.ExceptionMessage) AS ExceptionMessage
	FROM	@tblExceptions T
	GROUP BY	T.InvoiceID,
				T.InvoiceName
	ORDER BY T.InvoiceName

END
GO