ALTER TABLE VendorACH
ADD SourceSystemID INT NULL 
GO

ALTER TABLE VendorACH
ADD FOREIGN KEY (SourceSystemID) REFERENCES SourceSystem(ID)
GO

ALTER TABLE VendorACH
ADD BankAddressLine1 NVARCHAR(100) NULL
GO

ALTER TABLE VendorACH
ADD BankAddressLine2 NVARCHAR(100) NULL
GO

ALTER TABLE VendorACH
ADD BankAddressLine3 NVARCHAR(100) NULL

GO

ALTER TABLE VendorACH
ADD BankAddressCity NVARCHAR(100) NULL
GO

ALTER TABLE VendorACH
ADD BankAddressPostalCode NVARCHAR(20) NULL
GO

ALTER TABLE VendorACH
ADD BankAddressStateProvinceID INT NULL
GO

ALTER TABLE VendorACH
ADD FOREIGN KEY (BankAddressStateProvinceID) REFERENCES StateProvince(ID)
GO


ALTER TABLE VendorACH
ADD BankAddressStateProvince NVARCHAR(10) NULL
GO

ALTER TABLE VendorACH
ADD BankAddressCountryID INT NULL
GO

ALTER TABLE VendorACH
ADD FOREIGN KEY (BankAddressCountryID) REFERENCES Country(ID)
GO

ALTER TABLE VendorACH
ADD BankAddressCountryCode NVARCHAR(2) NULL
GO

ALTER TABLE VendorACH
ADD BankPhoneNumber NVARCHAR(50) NULL
GO

INSERT INTO [dbo].[ApplicationConfiguration]
           ([ApplicationConfigurationTypeID]
           ,[ApplicationConfigurationCategoryID]
           ,[ControlTypeID]
           ,[DataTypeID]
           ,[Name]
           ,[Value]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           (11, NULL, NULL, NULL, 'ManualInvoiceWaitInDays', '30', NULL, NULL, NULL, NULL)
GO


UPDATE [Event] SET Name = 'Add Contract' where Name = 'AddContract'
GO

INSERT INTO VendorTermsAgreement
SELECT GETDATE(),'T&A.pdf',1,GETDATE(),'system',NULL,NULL
GO