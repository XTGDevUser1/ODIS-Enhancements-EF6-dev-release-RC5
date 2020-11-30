-- DB CHANGES AND DATA
ALTER TABLE Claim
ADD PayeeType NVARCHAR(50) NULL

ALTER TABLE Claim
ADD PaymentAddressStateProvinceID INT NULL

ALTER TABLE Claim
ADD PaymentAddressCountryID INT NULL

ALTER TABLE Claim
ADD FOREIGN KEY (PaymentAddressStateProvinceID) REFERENCES StateProvince(ID)

ALTER TABLE Claim
ADD FOREIGN KEY (PaymentAddressCountryID) REFERENCES Country(ID)

ALTER TABLE Client 
ADD PaymentBalance money NULL

ALTER TABLE ClientPayment
ADD CheckDate DATETIME NULL

ALTER TABLE ClientPayment
ADD Comment nvarchar(max) NULL

ALTER TABLE ClientPayment
ADD ModifyBy nvarchar(200) NULL

ALTER TABLE ClientPayment
ADD ModifyDate DATETIME NULL


ALTER TABLE ClientPayment
ADD IsActive bit NULL

ALTER TABLE ClientPayment
DROP COLUMN AppliedAmount 

INSERT INTO [ApplicationConfiguration]
           ([ApplicationConfigurationTypeID]
           ,[ApplicationConfigurationCategoryID]
           ,[ControlTypeID]
           ,[Name]
           ,[DataTypeID]
           ,[Value]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES (1,NULL, NULL, NULL, 'DefaultACESPaymentListDays', '30', NULL, NULL, NULL, NULL)

INSERT INTO Securable Values('MENU_LEFT_CLAIMS_ACESPAYMENTS',(Select ID from Securable where FriendlyName='MENU_TOP_CLAIMS'),null)

INSERT INTO AccessControlList Values(
(Select ID From Securable where FriendlyName='MENU_LEFT_CLAIMS_ACESPAYMENTS'),
(Select RoleID from AccessControlList where SecurableID=(Select ID from Securable where FriendlyName='MENU_LEFT_CLAIMS_CLAIMS' )),
3)


INSERT INTO [Entity]
           ([Name]
           ,[IsAudited])
     VALUES
           ('ClientPayment', 0)

INSERT INTO [Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES
           (2, 10, 'AddClientPayment', 'Add Ford ACES Payment', 1, 1, NULL, NULL)

INSERT INTO [Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES
           (2, 10, 'UpdateClientPayment', 'Update Ford ACES Payment', 1, 1, NULL, NULL)

INSERT INTO [Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES
           (2, (SELECT TOP 1 ID FROM EventCategory where Name='Membership'), 'MergeMember', 'Merge Member', 1, 1, NULL, NULL)

