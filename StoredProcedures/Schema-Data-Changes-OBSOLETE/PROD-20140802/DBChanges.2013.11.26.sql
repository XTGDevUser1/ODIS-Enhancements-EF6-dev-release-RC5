
ALTER TABLE VendorInvoice
ALTER COLUMN BillingContactName  nvarchar(100)

-- NMC_ETL
ALTER TABLE staging_MAS90.APVendorMaster
ADD CountryCode  nvarchar(2)
