select * from ContactMethod
UPDATE ContactMethod SET IsShownOnVendor = 1 WHERE Name IN ('Email', 'Fax', 'Web', 'Mail')

GO

IF NOT EXISTS ( SELECT * FROM ApplicationConfiguration WHERE Name = 'POInvoiceDifferenceThreshold' )
BEGIN
	INSERT INTO [ApplicationConfiguration]
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
	(1, NULL, NULL, NULL, 'POInvoiceMaxElapsedTime', 90, NULL, NULL, NULL, NULL)
END
GO

INSERT INTO [dbo].[AddressEntity]
           ([EntityID]
           ,[RecordID]
           ,[AddressTypeID]
           ,[Line1]
           ,[Line2]
           ,[Line3]
           ,[City]
           ,[StateProvince]
           ,[PostalCode]
           ,[StateProvinceID]
           ,[CountryID]
           ,[CountryCode]
           ,[CreateBatchID]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyBatchID]
           ,[ModifyDate]
           ,[ModifyBy])
SELECT 
        ae.[EntityID]
      ,ae.[RecordID]
      ,(SELECT ID FROM AddressType WHERE Name = 'Billing')
      ,ae.[Line1]
      ,ae.[Line2]
      ,ae.[Line3]
      ,ae.[City]
      ,ae.[StateProvince]
      ,ae.[PostalCode]
      ,ae.[StateProvinceID]
      ,ae.[CountryID]
      ,ae.[CountryCode]
      ,ae.[CreateBatchID]
      ,ae.[CreateDate]
      ,ae.[CreateBy]
      ,ae.[ModifyBatchID]
      ,ae.[ModifyDate]
      ,ae.[ModifyBy]
FROM  [dbo].[AddressEntity] ae
JOIN vendor v on ae.RecordID = v.ID 
WHERE ae.EntityID = 17
and ae.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Business')
GO


IF NOT EXISTS (SELECT * FROM AddressTypeEntity WHERE ID = 17 AND AddressTypeID = 10)
BEGIN
INSERT INTO [AddressTypeEntity]([EntityID],[AddressTypeID],[IsShownOnScreen],[Sequence])VALUES(17, 10, 1, 4)
END

GO
UPDATE ContactMethod SET Sequence = Sequence - 1 WHERE Name = 'Email'
GO
UPDATE ContactMethod SET Sequence = Sequence +1 WHERE Name = 'Fax'
GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[VendorApplicationReferralSource](
[ID] [int] IDENTITY(1,1) NOT NULL,
[Name] [nvarchar](50) NULL,
[Description] [nvarchar](255) NULL,
IsActive] [bit] NOT NULL,
[Sequence] [int] NULL,
CONSTRAINT [PK_VendorApplicationReferralSource] PRIMARY KEY CLUSTERED 
(
[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

INSERT INTO [VendorApplicationReferralSource]
([Name]
,[Description]
,[IsActive]
,[Sequence])
VALUES
('Phone','Phone',1,1)

INSERT INTO [VendorApplicationReferralSource]
([Name]
,[Description]
,[IsActive]
,[Sequence])
VALUES
('Email','Email',1,2)

INSERT INTO [VendorApplicationReferralSource]
([Name]
,[Description]
,[IsActive]
,[Sequence])
VALUES
('Web','Web',1,3)

INSERT INTO [VendorApplicationReferralSource]
([Name]
,[Description]
,[IsActive]
,[Sequence])
VALUES
('VendorRep','Vendor Rep',1,4)

INSERT INTO [VendorApplicationReferralSource]
([Name]
,[Description]
,[IsActive]
,[Sequence])
VALUES
('TradeShow','Trade Show',1,5)

select * from VendorApplicationReferralSource


UPDATE Template SET Subject = 'Coach-Net Vendor Application Confirmation', 
					Body = 'Thank you for submitting an application to join our Vendor Network!  Our Vendor Representatives will process your application and we will contact you within the next 5 to 7 business days.'
WHERE	Name = 'VendorPortal_ApplicationConfirmation'

UPDATE Template SET 
					Body = '<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <style type="text/css">
        html
        {
            background-image: none;
        }
        body
        {
            font-family: Calibri,Tahoma,Verdana,Sans-Serif;
        }
        .mailBody
        {
            background-color: #F4F4F4 !important;
            border: 5px solid #F4F4F4 !important;
            left: 50% !important;
            margin: -165px auto 20px -215px !important;
            padding: 0 !important;
            position: absolute !important;
            top: 50% !important;
            width: 420px !important;
        }
        .clear
        {
            clear: both;
            height: 0;
            margin: 0;
            padding: 0;
        }
        
        #login .shadow
        {
            height: 33px;
            margin-left: -10px;
            margin-top: 5px;
            position: absolute;
            width: 434px;
            z-index: -1;
        }
        #login
        {
            background-color: #F4F4F4;
            border: 5px outset Black;
            left: 50%;
            margin: -165px auto 20px -215px;
            padding: 0;
            position: absolute;
            top: 50%;
            width: 420px;
        }
        #login .inner
        {
            background-color: #FFFFFF;
            border: 1px solid #CCCCCC;
            min-height: 230px;
            overflow: hidden;
        }
        #login .formLogin
        {
            height: 160px;
            margin: auto;
            padding: 100px 20px 20px;
            position: relative;
            width: 320px;
        }
    </style>
</head>
<body style="z-index: 20003; background-color: transparent;
    padding: 0px; min-height: 372px; min-width: 450px; padding: 5px; width: 450px">
    <div style="z-index: 20003; background-color: transparent; max-width: 450px; padding-left: 3px;
        padding-right: 3px; padding-top: 1px; ">
        <div class="inner" style="min-height: 70px;
            max-width: 450px; margin: -5px 0 -4px -3px; min-width: 444px;">            
        </div>
        <div class="formLogin" style="min-height: 70px; max-width: 450px; margin: -5px 0 -4px -3px;
            min-width: 444px; max-width: 450px;">
            <br />
            <h1>
                <span style="color: #005AA1;">Optimized Dispatch Intelligence System</span></h1>
            <br />
            Dear $user,
            <p>
                Please click the link to activate your account with ODIS</p>
            <a href="$url/Account/ActivateVendor/?id=$activationToken">Activate</a>
            
            <p>
                Regards,<br />
                ODIS</p>
        </div>
    </div>
</body>
</html>
'
WHERE	Name IN ('RegistrationConfirmation', 'TransitionRegistrationConfirmation')
