IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[VendorProduct_InsertUpdate]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[VendorProduct_InsertUpdate]
GO

--******************************************************************************************
--******************************************************************************************
--
--dbo.VendorProduct_InsertUpdate 58, '0000097689', NULL, NULL, 255, 1,NULL,'2016-01-26 00:00:00.000','DispatchVendorPost',NULL,NULL

--dbo.VendorProduct_InsertUpdate 58, '0000097689', NULL, 255, 1, 1,'2016-01-26','DispatchVendorPost',NULL,NULL

--******************************************************************************************
--******************************************************************************************

CREATE PROCEDURE [dbo].[VendorProduct_InsertUpdate]
			(
				@pClientID int,
				@pClientVendorKey varchar(50),
				@pVendorID int = NULL,
				--@pVendorLocationID int,
				@pProductID Int = NULL,
				@pIsActive bit = NULL,
				@pRating decimal(5,2) = NULL,
				@pCreateDate datetime = NULL,
				@pCreateBy varchar(50) = NULL,
				@pModifyDate datetime = NULL,
				@pModifyBy varchar(50) = NULL
				
			)
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT OFF

if @pVendorID is NULL
begin
		select @pVendorID = id from Vendor where ClientVendorKey = @pClientVendorKey
end


   MERGE [dbo].[VendorProduct] AS target
    USING (select 
				--@pClientID ,
				@pVendorID,
				--@pVendorLocationID ,
				@pProductID,
				@pIsActive,
				@pRating,
				@pCreateBy,
				@pCreateDate,
				@pModifyDate,
				@pModifyBy
			)
			as source( 
				--[ClientID],
				[VendorID],
				--[VendorLocationID],
				[ProductID],
				[IsActive],
				[Rating],
     			[CreateBy],
				[CreateDate],
				[ModifyDate],
				[ModifyBy]
           )
    ON (target.[VendorID] = source.[VendorID] and target.[ProductID] = source.[ProductID] )
    
    WHEN MATCHED THEN 
        UPDATE SET 
				--[ClientID] = source.[ClientID],
				--[VendorID] = source.[VendorID],
				--[VendorLocationID] = source.[VendorLocationID],
				--[ProductID] = source.[ProductID],
				[IsActive] = source.[IsActive],
				[Rating] = source.[Rating],
				[ModifyDate] = source.[ModifyDate],
				[ModifyBy] = source.[ModifyBy]
				
	WHEN NOT MATCHED THEN	
	    INSERT (
				--[ClientID],
				[VendorID],
				--[VendorLocationID],
				[ProductID],
				[IsActive],
				[Rating],
				[CreateBy],
				[CreateDate],
				[ModifyDate],
				[ModifyBy]
								
           )
	    VALUES (
				 --source.[ClientID],
				 source.[VendorID],
			     --source.[VendorLocationID],
				 source.[ProductID],
				 source.[IsActive],
				 source.[Rating],
				 source.[CreateBy],
				 source.[CreateDate],
				 source.[ModifyDate],
				 source.[ModifyBy] 
				);
GO

