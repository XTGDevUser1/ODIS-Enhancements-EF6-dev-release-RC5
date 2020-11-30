
CREATE TABLE #tmpVendorInvoice
(
	VendorInvoiceID INT NOT NULL,
	GLExpenseAccount NVARCHAR(50) NULL
)

;WITH wAPCheckRequest
AS
(
	SELECT	ROW_NUMBER() OVER ( PARTITION BY InvoiceNumber ORDER BY AddDateTime DESC) AS RowNumber,
			InvoiceNumber,
			GLExpenseAccount
	FROM	[ETLServer].[NMC_ETL].[staging_MAS90].APCheckRequest
	WHERE	GLExpenseAccount IS NOT NULL
)

INSERT INTO #tmpVendorInvoice
SELECT	InvoiceNumber,
		GLExpenseAccount
FROM	wAPCheckRequest
WHERE	RowNumber = 1

UPDATE	VendorInvoice 
SET		GLExpenseAccount = TMP.GLExpenseAccount
FROM	VendorInvoice VI
JOIN	#tmpVendorInvoice TMP ON VI.ID = TMP.VendorInvoiceID
WHERE	VI.GLExpenseAccount IS NULL
	
DROP TABLE #tmpVendorInvoice

--SELECT * FROM VendorInvoice WHERE GLExpenseAccount IS NULL


