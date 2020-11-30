IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[etl_Update_MemberStatus]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[etl_Update_MemberStatus]
GO

CREATE PROCEDURE [dbo].[etl_Update_MemberStatus] 
	@BatchID int
	,@ProcessGroup int
AS
BEGIN

	/** TO DO - Need add ProgramID or ClientID to Membership table and use in joins; **/
	/** Can not depend on ClientMemberhipKey being unique across clients **/
	/** TO DO - Need logic to guard against inserting multiple addresses for Memberships where there is more than one primary **/

	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION	
		
		/** Update Member Records with identified MemberID **/
		UPDATE Member
		SET 
			[EffectiveDate] = staging.[EffectiveDate]
			,[ExpirationDate] = CASE WHEN staging.[ExpirationDate] = '1753-01-01' THEN NULL ELSE staging.[ExpirationDate] END
			,[MemberSinceDate] = staging.[MemberSinceDate]
			,[ModifyBatchID] = staging.[BatchID]
			,[ModifyDate] = staging.[DateAdded]
			,[ModifyBy] = 'System'	
		FROM dbo.[etl_Staging_MemberStatus] staging
		JOIN dbo.Member Member
			ON staging.MemberID = Member.ID
		WHERE staging.[BatchID] = @BatchID
		AND staging.ProcessGroup = @ProcessGroup
  		AND staging.[Operation] IN ('I','U')
  		AND staging.[ProcessFlag] <> 'Y'
  		AND staging.MemberID IS NOT NULL
			
		/** Update Member Records without identified MemberID **/
		UPDATE Member
		SET 
			[EffectiveDate] = staging.[EffectiveDate]
			,[ExpirationDate] = CASE WHEN staging.[ExpirationDate] = '1753-01-01' THEN NULL ELSE staging.[ExpirationDate] END
			,[MemberSinceDate] = staging.[MemberSinceDate]
			,[ModifyBatchID] = staging.[BatchID]
			,[ModifyDate] = staging.[DateAdded]
			,[ModifyBy] = 'System'	
		FROM dbo.[etl_Staging_MemberStatus] staging
		JOIN dbo.Member Member
			ON staging.ProgramID = Member.ProgramID
			AND staging.ClientMemberKey = Member.ClientMemberKey
		WHERE staging.[BatchID] = @BatchID
		AND staging.ProcessGroup = @ProcessGroup
  		AND staging.[Operation] IN ('I','U')
  		AND staging.[ProcessFlag] <> 'Y'
  		AND staging.MemberID IS NULL
			
		COMMIT TRANSACTION;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		RETURN 1;
	END CATCH

	RETURN 0;
END
GO

