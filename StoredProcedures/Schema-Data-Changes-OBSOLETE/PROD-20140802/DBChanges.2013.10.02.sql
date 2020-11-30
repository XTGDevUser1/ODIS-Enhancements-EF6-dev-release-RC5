INSERT INTO [PaymentCategory]
([Name]
,[Description]
,[Sequence]
,[IsActive])
VALUES
('ACH','Electronic Transaction',5,1)
GO
DECLARE @PaymentCategoryID INT 
SET @PaymentCategoryID = (SELECT ID FROM PaymentCategory WHERE Name = 'ACH')

INSERT INTO [PaymentType]
([PaymentCategoryID]
,[Name]
,[Description]
,[Sequence]
,[IsActive]
,[IsShownOnVendor])
VALUES
(@PaymentCategoryID,'ACH','ACH',9,1,1)

GO 
 

UPDATE PaymentType Set IsShownOnVendor = 1 WHERE Name IN ('Cash','Check','Visa','MasterCard','AmericanExpress','Discover','PO')
