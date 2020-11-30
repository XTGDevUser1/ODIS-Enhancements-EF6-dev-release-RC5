IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Vendor_InsertUpdate]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Vendor_InsertUpdate]
GO

--******************************************************************************************
--******************************************************************************************
--
--
--
--******************************************************************************************
--******************************************************************************************

--******************************************************************************************
--******************************************************************************************
--exe Vendor_InsertUpdate 107, '@pMemberNumber', '@pPrefix', '@pFirstName', '@pMiddleName', '@pLastName', '@pSuffix', '@pEmail', '@pEffectiveDate', '@pExpirationDate','@pMemberSinceDate','@pClientMemberKey','@pClientMembershipKey','@pIsPrimary','@pIsActive','@pCreateBatchID','@pCreateDate','@pCreateBy','@pModifyBatchID','@pModifyDate','@pModifyBy'

--dbo.Vendor_InsertUpdate 58, '0000097689', NULL, 2, 'SILSBEE KIA', NULL, NULL, NULL, NULL, 1,'2016-01-25 00:00:00.000','DispatchVendorPost',NULL,NULL

--dbo.Vendor_InsertUpdate 58, '0000097689', NULL, 2, 'SILSBEE KIA', NULL, NULL, NULL, NULL, 1,'2016-01-25 00:00:00.000','DispatchVendorPost','2016-01-25 00:00:00.001','DispatchVendorPost'

--dbo.Vendor_InsertUpdate 58, '0000097689', NULL, 2, 'SILSBEE KIA', NULL, NULL, NULL, NULL, 1,'2016-01-25 00:00:00.000','DispatchVendorPost',NULL,NULL

--select * from Vendor where ClientVendorKey = '0000097689' 
--******************************************************************************************
--******************************************************************************************

CREATE PROCEDURE [dbo].[Vendor_InsertUpdate]
			(
				@pClientID int = NULL,	
				@pClientVendorKey varchar(50),
				--@pVendorID int = NULL,	
				@pVendorNumber  varchar(50) = NULL,	
				@pSourceSystemID int = NULL,	
				@pName varchar(255) = NULL,
				@pContactFirstName varchar(50) = NULL,
				@pContactLastName varchar(50) = NULL,
				@pWebsite varchar(100) = NULL,
				@pEmail varchar(255) = NULL,
				@pIsActive bit = NULL,
				@pCreateDate datetime = NULL,
				@pCreateBy varchar(50) = NULL,
				@pModifyDate datetime = NULL,
				@pModifyBy varchar(50) = NULL

			)
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT OFF


   MERGE [dbo].[Vendor] AS target
    USING (select 
				
				@pClientID,	
				@pClientVendorKey,
				--@VendorID,
				@pVendorNumber,
				@pSourceSystemID,
				@pName,
				@pContactFirstName,
				@pContactLastName,
				@pWebsite,
				@pEmail,
				@pIsActive,
				@pCreateDate,
				@pCreateBy,
				@pModifyDate,
				@pModifyBy
			)
			as source( 
			
				[ClientID],
				[ClientVendorKey],
				--[VendorID],
				[VendorNumber],
				[SourceSystemID],
				[Name],
				[ContactFirstName],
				[ContactLastName],
				[Website],
				[Email],
				[IsActive],
				[CreateDate],
				[CreateBy],
				[ModifyDate],
				[ModifyBy]
           )
    ON (target.ClientVendorKey = source.ClientVendorKey and target.ClientID = source.ClientID )
    --ON (target.ClientVendorKey = source.ClientVendorKey	and target.VendorId = source.VendorId)
    
    
    WHEN MATCHED THEN 
        UPDATE SET 
				ClientID = source.ClientID,
				ClientVendorKey = source.ClientVendorKey,
				--VendorID = source.VendorID,
				VendorNumber = source.VendorNumber,
				SourceSystemID = source.SourceSystemID,
				Name = source.Name,
				ContactFirstName = source.ContactFirstName,
				ContactLastName = source.ContactLastName,
				Website = source.Website,
				Email = source.Email,
				IsActive = source.IsActive,
				ModifyDate = source.ModifyDate,
				ModifyBy = source.ModifyBy

	WHEN NOT MATCHED THEN	
	    INSERT (
				
				[ClientID],	
				[ClientVendorKey],
				--[VendorID],
				[VendorNumber],
				[SourceSystemID],
				[Name],
				[ContactFirstName],
				[ContactLastName],
				[Website],
				[Email],
				[IsActive],
				[CreateDate],
				[CreateBy]

           )
	    VALUES (
				
				source.[ClientID],	
				source.[ClientVendorKey],
				--soucrce.[VendorID],
				source.[VendorNumber],
				source.[SourceSystemID],
				source.[Name],
				source.[ContactFirstName],
				source.[ContactLastName],
				source.[Website],
				source.[Email],
				source.[IsActive],
				source.[CreateDate],
				source.[CreateBy]
           );
GO

