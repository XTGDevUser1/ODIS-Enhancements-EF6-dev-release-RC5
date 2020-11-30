IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[VendorLocation_InsertUpdate]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[VendorLocation_InsertUpdate]
GO

--******************************************************************************************
--******************************************************************************************
--
--dbo.VendorLocation_InsertUpdate 58, '0000097689', NULL, NULL, 255, 1,NULL,'2016-01-26 00:00:00.000','DispatchVendorPost',NULL,NULL

--dbo.VendorLocation_InsertUpdate 58, '0000097689', NULL, 255, 1, 1,'2016-01-26','DispatchVendorPost',NULL,NULL

--******************************************************************************************
--******************************************************************************************

CREATE PROCEDURE [dbo].[VendorLocation_InsertUpdate]
			(
				@pClientID int,
				@pClientVendorKey varchar(50),
				@pVendorID int = NULL,
				@pVendorLocationStatusID int = NULL,
				@pSequence int = NULL,
				@pLatitude decimal(5,2) = NULL,
				@pLongitude decimal(5,2) = NULL,
				@pGeographyLocation varchar(255) = NULL,
				@pEmail varchar(255) = NULL,
				@pBusinessHours varchar(100) = NULL,
				@pDealerNumber varchar(50) = NULL,
				@pIsOpen24Hours bit = NULL,
				@pPartsAndAccessoryCode varchar(50) = NULL,
				@pDispatchNote varchar(2000) = NULL,
				@pIsActive bit = NULL,
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
		select @pVendorID = id from Vendor where ClientVendorKey = @pClientVendorKey and ClientID = @pClientID 
end


   MERGE [dbo].[VendorLocation] AS target
    USING (select 
				--@pClientID ,
				@pVendorID,
				@pVendorLocationStatusID,
				@pSequence,
				@pLatitude,
				@pLongitude,
				@pGeographyLocation,
				@pEmail,
				@pBusinessHours,
				@pDealerNumber,
				@pIsOpen24Hours,
				@pPartsAndAccessoryCode,
				@pDispatchNote,
				@pIsActive,
				@pCreateBy,
				@pCreateDate,
				@pModifyDate,
				@pModifyBy
			)
			as source( 
				--[ClientID],
				[VendorID],
				--[VendorLocationID],
				[VendorLocationStatusID],
				[Sequence],
				[Latitude],
				[Longitude],
				[GeographyLocation],
				[Email],
				[BusinessHours],
				[DealerNumber],
				[IsOpen24Hours],
				[PartsAndAccessoryCode],
				[DispatchNote],
				[IsActive],
     			[CreateBy],
				[CreateDate],
				[ModifyDate],
				[ModifyBy]
           )
    ON (target.[VendorID] = source.[VendorID] )
    
    WHEN MATCHED THEN 
        UPDATE SET 
				--[ClientID] = source.[ClientID],
				--[VendorID] = source.[VendorID],
				--[VendorLocationID] = source.[VendorLocationID],
				[VendorLocationStatusID] = source.[VendorLocationStatusID],
				[Sequence] = source.[Sequence],
				[Latitude] = source.[Latitude],
				[Longitude] = source.[Longitude],
				[GeographyLocation] = source.[GeographyLocation],
				[Email] = source.[Email],
				[BusinessHours] = source.[BusinessHours],
				[DealerNumber] = source.[DealerNumber],
				[IsOpen24Hours] = source.[IsOpen24Hours],
				[PartsAndAccessoryCode] = source.[PartsAndAccessoryCode],
				[DispatchNote] = source.[DispatchNote],
				[IsActive] = source.[IsActive],
				[ModifyDate] = source.[ModifyDate],
				[ModifyBy] = source.[ModifyBy]
				
	WHEN NOT MATCHED THEN	
	    INSERT (
				--[ClientID],
				[VendorID],
				--[VendorLocationID],
				[VendorLocationStatusID],
				[Sequence],				
				[Latitude],
				[Longitude],
				[GeographyLocation],
				[Email],
				[BusinessHours],
				[DealerNumber],
				[IsOpen24Hours],
				[PartsAndAccessoryCode],
				[DispatchNote],
				[IsActive],
				[CreateBy],
				[CreateDate],
				[ModifyDate],
				[ModifyBy]
								
           )
	    VALUES (
				 --source.[ClientID],
				 source.[VendorID],
			     --source.[VendorLocationID],
			     source.[VendorLocationStatusID],
			     source.[Sequence],
				 source.[Latitude],
				 source.[Longitude],
				 source.[GeographyLocation],
				 source.[Email],
				 source.[BusinessHours],
				 source.[DealerNumber],
				 source.[IsOpen24Hours],
				 source.[PartsAndAccessoryCode],
				 source.[DispatchNote],
				 source.[IsActive],
				 source.[CreateBy],
				 source.[CreateDate],
				 source.[ModifyDate],
				 source.[ModifyBy] 
				);
GO

