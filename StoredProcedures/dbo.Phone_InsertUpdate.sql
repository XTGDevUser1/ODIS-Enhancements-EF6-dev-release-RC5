/****** Object:  StoredProcedure [dbo].[Phone_InsertUpdate]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Phone_InsertUpdate]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Phone_InsertUpdate] 
 END 
 GO  
 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--******************************************************************************************
--******************************************************************************************
--
--******************************************************************************************
--******************************************************************************************

CREATE PROCEDURE [dbo].[Phone_InsertUpdate]
			(
				@pEntityID int,
				@pPhonetype varchar(15),
				@pPhoneNumber varchar(50) = NULL,
				@pIndexPhoneNumber int = NULL,
				@pSequence int = NULL,
				@pClientMemberKey varchar(50),
				@pCreateBatchID	int = NULL,
				@pCreateDate datetime = NULL,
				@pCreateBy varchar(50) = NULL,
				@pModifyBatchID	int = NULL,
				@pModifyDate datetime = NULL,
				@pModifyBy varchar(50) = NULL
			)
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT OFF

declare @RecordID as int
declare @PhoneTypeID as int

SELECT @RecordID = m.ID  
			FROM dbo.member m with(nolock)
				where 1=1
				and m.ClientMemberKey = @pClientmemberKey
							
SELECT @PhoneTypeID = [ID]
			FROM dbo.PhoneType ad with(nolock)
			Where 1=1
				and ad.IsActive = 1
				and ad.Name = @pPhonetype


   MERGE [dbo].[PhoneEntity] AS target
    USING (select
				@pEntityID, 
				@RecordID,
				@PhoneTypeID,
				@pPhoneNumber,
				@pIndexPhoneNumber,
				@pSequence,
				@pCreateBatchID,
				@pCreateDate,
				@pCreateBy,
				@pModifyBatchID,
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
				[CreateBatchID],
				[CreateDate],
				[CreateBy],
				[ModifyBatchID],
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
				ModifyBatchID = source.ModifyBatchid,
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
				[CreateBatchID],
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
				source.[CreateBatchID],
				source.[CreateDate],
				source.[CreateBy]
           );
GO
