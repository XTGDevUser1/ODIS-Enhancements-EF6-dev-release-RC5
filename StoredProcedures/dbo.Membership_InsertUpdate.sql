/****** Object:  StoredProcedure [dbo].[Membership_InsertUpdate]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Membership_InsertUpdate]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Membership_InsertUpdate] 
 END 
 GO  
 GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--******************************************************************************************
--******************************************************************************************
--
--RRH	^1			03/28/2014			Project# 13533 - Adding AltMembershipNumber column for CNET
--		
--******************************************************************************************
--******************************************************************************************
--dbo.Membership_InsertUpdate	[BatchID],[ProcessGroup],[ProcessFlag],[ErrorDescription],[DateAdded],[Operation],[ProgramID],[MembershipID],[ClientMembershipKey],[MembershipNumber],[SequenceNumber],[EmailAddress]

CREATE procedure [dbo].[Membership_InsertUpdate]
		(
		@pMembershipNumber varchar(25) = NULL,
		@pEmailAddress varchar(255) = NULL,
		@pClientReferenceNumber varchar(50) = NULL,
		@pClientMembershipKey varchar(50) = NULL,
		@pIsActive bit,
		@pCreateBatchID	int = NULL,
		@pCreateDate datetime = NULL,
		@pCreateBy varchar(50) = NULL,
		@pModifyBatchID	int = NULL,
		@pModifyDate datetime = NULL,
		@pModifyBy varchar(50) = NULL,
		@pNote varchar(2000) = NULL,
		@pSourceSystem int = NULL,
		@pAltMembershipNumber varchar(40) = NULL --^1
		)
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT OFF

MERGE [dbo].[Membership] AS target

USING (
 		 select
 		 @pMembershipNumber,
 		 @pEmailAddress,
 		 @pClientReferenceNumber,
 		 @pClientMembershipKey,
 		 @pIsActive,
 		 @pCreateBatchID,
 		 @pCreateDate,
		 @pCreateBy,
		 @pModifyBatchID,
		 @pModifyDate,
		 @pModifyBy,
		 @pNote,
		 @pSourceSystem,
		 @pAltMembershipNumber --^1
	)
as source(
		[MembershipNumber]
		,[Email]
		,[ClientReferenceNumber]
		,[ClientMembershipKey]
		,[IsActive]
		,[CreateBatchID]
		,[CreateDate]
		,[CreateBy]
		,[ModifyBatchID]
		,[ModifyDate]
		,[ModifyBy]
		,[Note]
		,[SourceSystem]
		,[AltMembershipNumber] --^1
		)
    ON (
		target.ClientMembershipKey = source.ClientMembershipKey
		)
    WHEN MATCHED THEN 
        UPDATE SET
			MembershipNumber = source.MembershipNumber,
			Email = source.Email,
			ModifyBatchID = source.ModifyBatchid,
			ModifyDate = source.ModifyDate,
			ModifyBy = source.ModifyBy,
			AltMembershipNumber = source.AltMembershipNumber  --^1
	WHEN NOT MATCHED THEN
		Insert 
			(
			[MembershipNumber]
			,[Email]
			,[ClientReferenceNumber]
			,[ClientMembershipKey]
			,[IsActive]
			,[CreateBatchid]
			,[CreateDate]
			,[CreateBy]
			,SourceSystemID
			,AltMembershipNumber --^1
			)		
     VALUES
			(
			 source.MembershipNumber,
			 source.Email,
			 source.ClientReferenceNumber,
			 source.ClientMembershipKey,
			 source.IsActive,
			 source.CreateBatchID,
			 source.CreateDate,
			 source.CreateBy,
			 2,
			 source.AltMembershipNumber --^1
			);
GO

