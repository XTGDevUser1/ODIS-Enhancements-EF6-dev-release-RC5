ALTER TABLE	Vendor					
ADD 	VendorStatusID	int				NULL
,	VendorStatusNote	nvarchar	(	255	)	NULL
,	ContactName	nvarchar	(	255	)	NULL
,	CorporationName	nvarchar	(	255	)	NULL
,	IsDirectDeposit	bit				NULL
,	ApplicationDate	datetime				NULL
,	ApplicationSignedByName	nvarchar	(	255	)	NULL
,	ApplicationSignedByTitle	nvarchar	(	50	)	NULL
,	ApplicationComments	nvarchar	(	2000	)	NULL
,	InsuranceCarrierName	nvarchar	(	255	)	NULL
,	InsurancePolicyNumber	nvarchar	(	50	)	NULL
,	IsInsuranceCertificateOnFile	bit				NULL
,	IsW9OnFile	bit				NULL
,	IsEmployeeBackgroundChecked	bit				NULL
,	IsEmployeeBackgroundCheckedComment	nvarchar	(	255	)	NULL
,	IsEmployeeDrugTested	bit				NULL
,	IsEmployeeDrugTestedComment	nvarchar	(	255	)	NULL
,	IsDriverUniformed	bit				NULL
,	IsDriverUniformedComment	nvarchar	(	255	)	NULL
,	IsEachServiceTruckMarked	bit				NULL
,	IsEachServiceTruckMarkedComment	nvarchar	(	255	)	NULL
,	DepartmentOfTransportationNumber	nvarchar	(	50	)	NULL
,	MotorCarrierNumber	nvarchar	(	50	)	NULL
,	SourceSystem	nvarchar	(	50	)	NULL;						

								
ALTER TABLE	Vendor							
DROP COLUMN 	BankABANumber;	
							
ALTER TABLE	Vendor							
DROP COLUMN 	BankAccountNumber;	
							
ALTER TABLE	Vendor							
DROP COLUMN 	DealerNumber;								

CREATE TABLE	VendorStatus								
(	ID	int				IDENTITY(1,1) NOT NULL			
,	Name	nvarchar	(	50	)	NULL			
,	[Description]	nvarchar	(	255	)	NULL			
,	Sequence	int				NULL			
,	IsActive	bit				NULL
);			

CREATE TABLE	VendorStatusReason								
(	ID	int				IDENTITY(1,1) NOT NULL			
,	Name	nvarchar	(	50	)	NULL			
,	[Description]	nvarchar	(	255	)	NULL			
,	Sequence	int				NULL			
,	IsActive	bit				NULL			
);									
									
CREATE TABLE	VendorStatusLog								
(	ID	int				IDENTITY(1,1) NOT NULL			
,	VendorID	int				NULL			
,	VendorStatusIDBefore	int				NULL			
,	VendorStatusIDAfter	int				NULL			
,	VendorStatusReasonID	Int				NULL			
,	VendorStatusReasonOther	nvarchar	(	50	)	NULL			
,	Comment	nvarchar	(	2000	)	NULL			
,	CreateDate	datetime				NULL			
,	CreateBy	nvarchar	(	50	)	NULL			
);									

CREATE TABLE	VendorACH								
(	ID	int				NULL			
,	VendorID	int				NULL			
,	NameOnAccount	nvarchar	(	50	)	NULL			
,	AccountNumber	nvarchar	(	50	)	NULL			
,	AccountType	nvarchar	(	50	)	NULL	-- Checking(22) or Savings(33)		
,	BankName	nvarchar	(	50	)	NULL			
,	BankABANumber	nvarchar	(	30	)	NULL			
,	ACHStatusID	int				NULL			
,	ReceiptContactMethodID	int				NULL	-- ContactMethod Values		
,	ReceiptEmail	nvarchar	(	255	)	NULL			
,	IsVoidedCheckOnFile	bit				NULL			
,	IsACHSecurityBlock	bit				NULL			
,	ACHSecurityBlockNumber	nvarchar	(	50	)	NULL			
,	CreateDate	datetime				NULL			
,	CreateBy	nvarchar	(	50	)	NULL			
,	ModifyDate	datetime				NULL			
,	ModifyBy	nvarchar	(	50	)	NULL			
);									
									
									
CREATE TABLE	ACHStatus								
(	ID	int				IDENTITY(1,1) NOT NULL			
,	Name	nvarchar	(	50	)	NULL			
,	[Description]	nvarchar	(	255	)	NULL			
,	Sequence	int				NULL			
,	IsActive	bit				NULL			
);									

SET IDENTITY_INSERT [dbo].[VendorStatusReason] ON
INSERT [dbo].[VendorStatusReason] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (1, N'NewVendor', N'New Vendor', 1, 1)
INSERT [dbo].[VendorStatusReason] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (2, N'TaxLien', N'Tax Lien', 2, 1)
INSERT [dbo].[VendorStatusReason] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (3, N'PerformanceReview', N'Performance Review', 3, 1)
INSERT [dbo].[VendorStatusReason] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (4, N'OutOfBusiness', N'Out Of Business', 4, 1)
INSERT [dbo].[VendorStatusReason] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (5, N'Other', N'Other', 5, 1)
SET IDENTITY_INSERT [dbo].[VendorStatusReason] OFF

SET IDENTITY_INSERT [dbo].[VendorStatus] ON
INSERT [dbo].[VendorStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (1, N'Active', N'Active', 1, 1)
INSERT [dbo].[VendorStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (2, N'Pending', N'Pending', 2, 1)
INSERT [dbo].[VendorStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (3, N'DoNotUse', N'Do Not Use', 3, 1)
INSERT [dbo].[VendorStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (4, N'OnHold', N'On Hold', 4, 1)
INSERT [dbo].[VendorStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (5, N'Inactive', N'Inactive', 5, 1)
SET IDENTITY_INSERT [dbo].[VendorStatus] OFF

SET IDENTITY_INSERT [dbo].[ACHStatus] ON
INSERT [dbo].[ACHStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (1, N'PendingValidation', N'Pending Validation', 1, 1)
INSERT [dbo].[ACHStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (2, N'Valid', N'Valid', 2, 1)
INSERT [dbo].[ACHStatus] ([ID], [Name], [Description], [Sequence], [IsActive]) VALUES (3, N'Invalid', N'Invalid', 3, 1)
SET IDENTITY_INSERT [dbo].[ACHStatus] OFF

INSERT INTO [dbo].[AddressType]
           ([Name]
           ,[Description]
           ,[IsActive]
           ,[Sequence])
     VALUES
           ('Insurance'
           ,'Insurance'
           ,1
           ,5);

INSERT INTO [dbo].[AddressType]
           ([Name]
           ,[Description]
           ,[IsActive]
           ,[Sequence])
     VALUES
           ('Bank'
           ,'Bank'
           ,1
           ,5);
           
INSERT INTO [dbo].[PhoneType]
           ([Name]
           ,[Description]
           ,[IsActive]
           ,[Sequence])
     VALUES
           ('Insurance'
           ,'Insurance'
           ,1
           ,8);

INSERT INTO [dbo].[PhoneType]
           ([Name]
           ,[Description]
           ,[IsActive]
           ,[Sequence])
     VALUES
           ('Bank'
           ,'Bank'
           ,1
           ,9);

INSERT INTO [dbo].[NextNumber]
           ([Name]
           ,[Value])
     VALUES
           ('VendorNumber'
           ,100000)

ALTER TABLE [dbo].[PaymentType]
ADD IsShownOnVendor bit NULL;

ALTER TABLE [dbo].[ContactMethod]
ADD IsShownOnVendor bit NULL;


INSERT INTO [dbo].[ContactMethod]
           ([Name]
           ,[Description]
           ,[ClassName]
           ,[IsShownOnPO]
           ,[Sequence]
           ,[IsActive]
           ,[IsShownOnPayment]
           ,[IsShownOnVendor])
     VALUES
           ('Mail'
           ,'Mail'
           ,'icon-mail'
           ,0
           ,7
           ,1
           ,0
           ,1)

