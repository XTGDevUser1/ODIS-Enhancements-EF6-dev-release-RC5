IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[etl_Update_Member]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[etl_Update_Member]
GO

CREATE PROCEDURE [dbo].[etl_Update_Member] 
	@BatchID int
	,@ProcessGroup int
AS
BEGIN

	/** Update Staging entries with 'I' to include the memberID if the ClientMemberKey already exists in the DB
		Implemented to account for the same member changing to a different program
		** Done for NMC/Coach-Net and Hagerty programs only
	 **/
	UPDATE staging SET MemberID = Member.ID
	FROM dbo.[etl_Staging_Member] staging
	JOIN dbo.Member Member
		ON staging.ClientMemberKey = Member.ClientMemberKey
	WHERE staging.[BatchID] = @BatchID
	AND staging.ProcessGroup = @ProcessGroup
	AND staging.[Operation] IN ('I','U')
	AND staging.[ProcessFlag] <> 'Y'
	AND staging.ProgramID IN (SELECT ID FROM Program WHERE ClientID IN (1,18)) -- IS NMC, Hagerty



	/** TO DO - Need add ProgramID or ClientID to Membership table and use in joins; **/
	/** Can not depend on ClientMemberhipKey being unique across clients **/
	/** TO DO - Need logic to guard against inserting multiple addresses for Memberships where there is more than one primary **/

	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION	
		
		DECLARE @MembershipEntityID int, @MemberEntityID int
		SET @MembershipEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'Membership')
		SET @MemberEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'Member')

		/* Insert new Membership entries */
		INSERT INTO dbo.Membership
			([MembershipNumber]
			,[Email]
			,[ClientMembershipKey]
			,[IsActive]
			,[CreateBatchID]
			,[CreateDate]
			,[CreateBy])
		SELECT 
			staging.[MembershipNumber]
			,staging.[EmailAddress]
			,staging.[ClientMembershipKey]
			,'FALSE'
			,staging.[BatchID]
			,staging.[DateAdded]
			,'System'	
		FROM dbo.[etl_Staging_Membership] staging
  		WHERE staging.[BatchID] = @BatchID
		AND staging.ProcessGroup = @ProcessGroup
  		AND staging.[Operation] = 'I'
  		AND staging.[ProcessFlag] <> 'Y'
  		AND NOT EXISTS (
  			SELECT *
  			FROM dbo.Membership ms
  			JOIN dbo.Member m on ms.ID = m.MembershipID
  			WHERE ms.ClientMembershipKey = staging.ClientMembershipKey
  			--AND m.ProgramID = Staging.ProgramID
  			)


		/** Insert New Member entries **/
		INSERT INTO dbo.Member
			([MembershipID]
			,[ProgramID]
			,[MemberNumber]
			,[Prefix]
			,[FirstName]
			,[MiddleName]
			,[LastName]
			,[Suffix]
			,[Email]
			--,[EffectiveDate]
			--,[ExpirationDate]
			--,[MemberSinceDate]
			,[ClientMemberKey]
			,[IsPrimary]
			,[IsActive]
			,[CreateBatchID]
			,[CreateDate]
			,[CreateBy])
		SELECT 
			Membership.ID
			,staging.[ProgramID]
			,staging.[MembershipNumber]
			,staging.[Prefix]
			,staging.[FirstName]
			,NULL
			,staging.[LastName]
			,staging.[Suffix]
			,staging.[EmailAddress]
			--,staging.[EffectiveDate]
			--,CASE WHEN staging.[ExpirationDate] = '1753-01-01' THEN NULL ELSE staging.[ExpirationDate] END AS [ExpirationDate]
			--,staging.[MemberSinceDate]
			,staging.[ClientMemberKey]
			,staging.[IsPrimary]
			,'FALSE'
			,staging.[BatchID]
			,staging.[DateAdded]
			,'System'	
		FROM dbo.[etl_Staging_Member] staging
		JOIN dbo.Membership Membership 
			ON staging.ClientMembershipKey = Membership.ClientMembershipKey
			--AND staging.ProgramID = Membership.ProgramID
		WHERE staging.[BatchID] = @BatchID
		AND staging.ProcessGroup = @ProcessGroup
  		AND staging.[Operation] = 'I'
  		AND staging.[ProcessFlag] <> 'Y'
  		AND (
  				(staging.ProgramID NOT IN (SELECT ID FROM Program WHERE ClientID IN (1,18)) -- NOT NMC, Hagerty
  				AND 
  				NOT EXISTS (
  				SELECT *
  				FROM dbo.Member m
  				WHERE m.ProgramID = staging.ProgramID
  				AND m.ClientMemberKey = staging.ClientMemberKey)
  				)
  			OR
  				(staging.ProgramID IN (SELECT ID FROM Program WHERE ClientID IN (1,18)) -- IS NMC, Hagerty
  				AND 
  				NOT EXISTS (
  				SELECT *
  				FROM dbo.Member m
  				WHERE m.ClientMemberKey = staging.ClientMemberKey)
				)
			)

		/** Update Member Records **/
		UPDATE Member
		SET 
			[Prefix] = staging.[Prefix]
			,[FirstName] = staging.[FirstName]
			,[LastName] = staging.[LastName]
			,[Suffix] = staging.[Suffix]
			,[Email] = staging.[EmailAddress]
			--,[EffectiveDate] = staging.[EffectiveDate]
			--,[ExpirationDate] = CASE WHEN staging.[ExpirationDate] = '1753-01-01' THEN NULL ELSE staging.[ExpirationDate] END
			--,[MemberSinceDate] = staging.[MemberSinceDate]
			,[IsPrimary] = staging.[IsPrimary]
			,[ModifyBatchID] = staging.[BatchID]
			,[ModifyDate] = staging.[DateAdded]
			,[ModifyBy] = 'System'	
		FROM dbo.[etl_Staging_Member] staging
		JOIN dbo.Member Member
			ON staging.MemberID = Member.ID
		WHERE staging.[BatchID] = @BatchID
		AND staging.ProcessGroup = @ProcessGroup
  		AND staging.[Operation] = 'U'
  		AND staging.[ProcessFlag] <> 'Y'
			
			
		/* Update Member Program - NMC, Hagerty Only */
		UPDATE Member
		SET 
			[ProgramID] = staging.[ProgramID]
		FROM dbo.[etl_Staging_Member] staging
		JOIN dbo.Member Member
			ON staging.MemberID = Member.ID
		WHERE staging.[BatchID] = @BatchID
		AND staging.ProcessGroup = @ProcessGroup
  		AND staging.[Operation] IN ('I','U')
  		AND staging.[ProcessFlag] <> 'Y'
  		AND staging.ProgramID IN (SELECT ID FROM Program WHERE ClientID IN (1,18)) -- IS NMC, Hagerty


		/* Update Existing Memberships with Primary Member email information and changes to Membership Number */
		UPDATE Membership
			SET Email = staging.EmailAddress
				,MembershipNumber = staging.MembershipNumber
  		FROM dbo.[etl_Staging_Member] staging
  		JOIN dbo.Member Member
  			ON staging.MemberID = Member.ID
  		JOIN dbo.Membership Membership
  			ON Member.MembershipID = Membership.ID
  		WHERE staging.[BatchID] = @BatchID
		AND staging.ProcessGroup = @ProcessGroup
  		AND staging.[Operation] = 'U'
  		AND staging.[ProcessFlag] <> 'Y'
  		AND staging.IsPrimary = 'TRUE';


		/** Update Existing Membership Address Entry **/
		UPDATE AddressEntity
		SET [Line1] = staging.AddressLine1
			,[Line2] = staging.AddressLine2
			,[Line3] = staging.AddressLine3
			,[City] = staging.City
			,[StateProvince] = sp.Abbreviation
			,[PostalCode] = staging.PostalCode
			,[StateProvinceID] = sp.ID
			,[CountryID] = c.ID
			,[CountryCode] = staging.CountryCode
			,[ModifyBatchID] = staging.BatchID
			,[ModifyDate] = staging.DateAdded
			,[ModifyBy] = 'System'
  		FROM dbo.[etl_Staging_MemberAddress] staging
		JOIN dbo.Member Member
			ON staging.MemberID = Member.ID
			AND Member.IsPrimary = 'TRUE'
		JOIN dbo.Membership Membership 
			ON Member.MembershipID = Membership.ID
		JOIN dbo.AddressType AddressType
			ON AddressType.Name = staging.AddressType
		JOIN dbo.AddressEntity AddressEntity
			ON AddressEntity.EntityID = @MembershipEntityID
			AND AddressEntity.RecordID = Membership.ID
			AND AddressEntity.AddressTypeID = AddressType.ID
		JOIN dbo.Country c 
			ON c.ISOCode = staging.CountryCode
		LEFT OUTER JOIN dbo.StateProvince sp
			ON sp.Abbreviation = staging.StateProvince
			AND sp.CountryID = c.ID
  		WHERE staging.[BatchID] = @BatchID
		AND staging.ProcessGroup = @ProcessGroup
  		AND staging.[Operation] IN ('I','U')
  		AND staging.[ProcessFlag] <> 'Y';
	 

		/** Insert Home address for new Memberships **/
		INSERT INTO dbo.AddressEntity
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
			,[CreateBy])
		SELECT 
			@MembershipEntityID
			,Membership.ID
			,at.ID
			,staging.[AddressLine1]
			,staging.[AddressLine2]
			,staging.[AddressLine3]
			,staging.[City]
			,sp.Abbreviation
			,staging.[PostalCode]
			,sp.ID
			,c.ID
			,staging.[CountryCode]
			,staging.BatchID
			,staging.[DateAdded]
			,'System'
		FROM dbo.[etl_Staging_MemberAddress] staging
		JOIN dbo.Member Member
			ON staging.ProgramID = Member.ProgramID
			AND staging.ClientMemberKey = Member.ClientMemberKey
			AND Member.IsPrimary = 'TRUE'
		JOIN dbo.Membership Membership 
			ON Member.MembershipID = Membership.ID
		JOIN dbo.AddressType at
			ON at.Name = staging.AddressType
		JOIN dbo.Country c 
			ON c.ISOCode = staging.CountryCode
		LEFT OUTER JOIN dbo.StateProvince sp
			ON sp.Abbreviation = staging.StateProvince
			AND sp.CountryID = c.ID
  		WHERE staging.[BatchID] = @BatchID
		AND staging.ProcessGroup = @ProcessGroup
  		AND staging.[Operation] IN ('I','U')
  		AND staging.[ProcessFlag] <> 'Y'
  		AND NOT EXISTS (
  			SELECT * 
  			FROM dbo.AddressEntity ae
  			WHERE ae.RecordID = Membership.ID
  				AND ae.EntityID = @MembershipEntityID
  				AND ae.AddressTypeID = at.ID);


		/** Update Existing Member Address Entry **/
		UPDATE AddressEntity
		SET [Line1] = staging.AddressLine1
			,[Line2] = staging.AddressLine2
			,[Line3] = staging.AddressLine3
			,[City] = staging.City
			,[StateProvince] = sp.Abbreviation
			,[PostalCode] = staging.PostalCode
			,[StateProvinceID] = sp.ID
			,[CountryID] = c.ID
			,[CountryCode] = staging.CountryCode
			,[ModifyBatchID] = staging.BatchID
			,[ModifyDate] = staging.DateAdded
			,[ModifyBy] = 'System'
  		FROM dbo.[etl_Staging_MemberAddress] staging
		JOIN dbo.Member Member
			ON staging.MemberID = Member.ID
		JOIN dbo.AddressType AddressType
			ON AddressType.Name = staging.AddressType
		JOIN dbo.AddressEntity AddressEntity
			ON AddressEntity.EntityID = @MemberEntityID
			AND AddressEntity.RecordID = Member.ID
			AND AddressEntity.AddressTypeID = AddressType.ID
		JOIN dbo.Country c 
			ON c.ISOCode = staging.CountryCode
		LEFT OUTER JOIN dbo.StateProvince sp
			ON sp.Abbreviation = staging.StateProvince
			AND sp.CountryID = c.ID
  		WHERE staging.[BatchID] = @BatchID
		AND staging.ProcessGroup = @ProcessGroup
  		AND staging.[Operation] IN ('I','U')
  		AND staging.[ProcessFlag] <> 'Y';
	 
	 
		/** Insert new Member Address for new and updated Members **/
		INSERT INTO dbo.AddressEntity
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
			,[CreateBy])
		SELECT 
			@MemberEntityID
			,Member.ID
			,at.ID
			,staging.[AddressLine1]
			,staging.[AddressLine2]
			,staging.[AddressLine3]
			,staging.[City]
			,sp.Abbreviation
			,staging.[PostalCode]
			,sp.ID
			,c.ID
			,staging.[CountryCode]
			,staging.BatchID
			,staging.[DateAdded]
			,'System'
		FROM dbo.[etl_Staging_MemberAddress] staging
		JOIN dbo.Member Member
			ON staging.ProgramID = Member.ProgramID
			AND staging.ClientMemberKey = Member.ClientMemberKey
		JOIN dbo.AddressType at
			ON at.Name = staging.AddressType
		JOIN dbo.Country c 
			ON c.ISOCode = staging.CountryCode
		LEFT OUTER JOIN dbo.StateProvince sp
			ON sp.Abbreviation = staging.StateProvince
			AND sp.CountryID = c.ID
  		WHERE staging.[BatchID] = @BatchID
		AND staging.ProcessGroup = @ProcessGroup
  		AND staging.[Operation] IN ('I','U')
  		AND staging.[ProcessFlag] <> 'Y'
  		AND NOT EXISTS (
  			SELECT * 
  			FROM dbo.AddressEntity ae
  			WHERE ae.RecordID = Member.ID
  				AND ae.EntityID = @MemberEntityID
  				AND ae.AddressTypeID = at.ID);


	 	
		/** Update existing Member phone number entries **/
		UPDATE PhoneEntity
		SET [EntityID] = @MemberEntityID
			,[RecordID] = Member.ID
			,[PhoneTypeID] = PhoneType.ID
			,[PhoneNumber] = CASE WHEN staging.PhoneNumber = '0' THEN NULL ELSE '1 ' + staging.PhoneNumber END
			,[IndexPhoneNumber] = NULL
			,[Sequence] = 0
			,[ModifyBatchID] = staging.BatchID
			,[ModifyDate] = staging.DateAdded
			,[ModifyBy] = 'System'
		FROM dbo.[etl_Staging_MemberPhone] staging
		JOIN dbo.Member Member
			ON staging.MemberID = Member.ID
		JOIN dbo.PhoneType PhoneType
			ON PhoneType.Name = Staging.PhoneType
		JOIN dbo.PhoneEntity PhoneEntity
			ON PhoneEntity.EntityID = @MemberEntityID
			AND PhoneEntity.RecordID = Member.ID
			AND PhoneEntity.PhoneTypeID = PhoneType.ID
  		WHERE staging.[BatchID] = @BatchID
		AND staging.ProcessGroup = @ProcessGroup
  		AND staging.[Operation] = 'U'
  		AND staging.[ProcessFlag] <> 'Y';


  		/** Add new Phone entries **/
  		/** I and U Operations apply to the Member not the phone, so Updated members could have new phone numbers **/
		INSERT INTO dbo.PhoneEntity
			([EntityID]
			,[RecordID]
			,[PhoneTypeID]
			,[PhoneNumber]
			,[IndexPhoneNumber]
			,[Sequence]
			,[CreateBatchID]
			,[CreateDate]
			,[CreateBy])
		SELECT 
			@MemberEntityID
			,Member.ID
			,pt.ID
			,CASE WHEN staging.PhoneNumber = '0' THEN NULL ELSE '1 ' + staging.PhoneNumber END
			,NULL
			,0
			,staging.[BatchID]
			,staging.[DateAdded]
			,'System'
		FROM dbo.[etl_Staging_MemberPhone] staging
		JOIN dbo.Member Member
			ON staging.ProgramID = Member.ProgramID
			AND staging.ClientMemberKey = Member.ClientMemberKey
		JOIN dbo.PhoneType pt
			ON pt.Name = staging.PhoneType
  		WHERE staging.[BatchID] = @BatchID
		AND staging.ProcessGroup = @ProcessGroup
  		AND staging.[Operation] IN ('I','U')
  		AND staging.[ProcessFlag] <> 'Y'
  		AND NOT EXISTS (
  			SELECT *
  			FROM dbo.PhoneEntity pe
  			WHERE pe.RecordID = Member.ID
  				AND pe.EntityID = @MemberEntityID
  				AND pe.PhoneTypeID = pt.ID);

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

