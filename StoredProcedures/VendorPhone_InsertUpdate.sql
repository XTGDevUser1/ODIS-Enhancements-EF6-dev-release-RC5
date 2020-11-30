IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[VendorPhone_InsertUpdate]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[VendorPhone_InsertUpdate]
GO

--******************************************************************************************
--******************************************************************************************
--
--dbo.VendorPhone_InsertUpdate 58, '0000097689', 17, 2, '4093858000', NULL,NULL,'2016-01-26 00:00:00.000','DispatchVendorPost',NULL,NULL

--******************************************************************************************
--******************************************************************************************

CREATE PROCEDURE [dbo].[VendorPhone_InsertUpdate]
			(
				@pClientID int,
				@pClientVendorKey varchar(50),
				@pEntityID int,
				@pPhoneTypeID int,
				@pPhoneNumber varchar(50) = NULL,
				@pIndexPhoneNumber int = NULL,
				@pSequence int = NULL,
				@pCreateDate datetime = NULL,
				@pCreateBy varchar(50) = NULL,
				@pModifyDate datetime = NULL,
				@pModifyBy varchar(50) = NULL
			)
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT OFF

declare @RecordID as int

if @pEntityID = 17 
begin 
	SELECT @RecordID = m.ID  
			FROM dbo.Vendor m with(nolock)
				where 1=1
					and m.ClientVendorKey = @pClientVendorKey
End

if @pEntityID = 18
begin 
	SELECT @RecordID = l.ID  
			FROM dbo.Vendor m with(nolock)
					Join VendorLocation l on l.VendorID = m.ID
				where 1=1
					and m.ClientVendorKey = @pClientVendorKey
End

   MERGE [dbo].[PhoneEntity] AS target
    USING (select
				@pEntityID, 
				@RecordID,
				@pPhoneTypeID,
				@pPhoneNumber,
				@pIndexPhoneNumber,
				@pSequence,
				@pCreateDate,
				@pCreateBy,
				@pModifyDate,
				@pModifyBy
			)
			as source( 
				[EntityID], 
				[RecordID],
				[PhoneTypeID],
				[PhoneNumber],
				[IndexPhoneNumber],
				[Sequence],				
				[CreateDate],
				[CreateBy],
				[ModifyDate],
				[ModifyBy]
           )
    ON (target.RecordID = source.RecordID
		AND target.EntityID = source.EntityID
		and target.PhoneTypeID = source.PhoneTypeID
		)
    
    WHEN MATCHED THEN 
        UPDATE SET 
				PhoneNumber = '1 ' + source.PhoneNumber,
				ModifyDate = source.ModifyDate,
				ModifyBy = source.ModifyBy
	WHEN NOT MATCHED THEN	
	    INSERT	(
				[EntityID], 
				[RecordID],
				[PhoneTypeID],
				[PhoneNumber],
				[IndexPhoneNumber],
				[Sequence],
				[CreateDate],
				[CreateBy]
				)
	    VALUES (
				source.[EntityID], 
				source.[RecordID],
				source.[PhoneTypeID],
				'1 ' + source.[PhoneNumber],
				source.[IndexPhoneNumber],
				source.[Sequence],
				source.[CreateDate],
				source.[CreateBy]
           );
GO

