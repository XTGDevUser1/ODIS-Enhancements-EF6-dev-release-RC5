ALTER TABLE Client
ADD AccountingSystemDivisionCode numeric(2,0) NULL
GO

--SELECT * FROM Client WHERE AccountingSystemCustomerNumber IN ('Coach', 'PMC',' NMCA', 'SAFE')
UPDATE	Client
SET		AccountingSystemDivisionCode = 0
WHERE	AccountingSystemCustomerNumber IS NULL OR  AccountingSystemCustomerNumber NOT IN ('Coach', 'PMC',' NMCA', 'SAFE')
GO

UPDATE	Client
SET		AccountingSystemDivisionCode = 99
WHERE	AccountingSystemCustomerNumber IN ('Coach', 'PMC',' NMCA', 'SAFE')
GO