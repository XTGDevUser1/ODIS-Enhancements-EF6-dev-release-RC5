ALTER Table Country ADD ISOCode3 NVARCHAR(3) NULL

UPDATE Country SET ISOCode3 = 'USA' WHERE ISOCode = 'US'
UPDATE Country SET ISOCode3 = 'CAN' WHERE ISOCode = 'CA'
UPDATE Country SET ISOCode3 = 'MEX' WHERE ISOCode = 'MX'
GO

-- NMC_ETL
ALTER TABLE staging_MAS90.APVendorMaster 
ALTER COLUMN CountryCode nvarchar(3)
