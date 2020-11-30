IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ClientPortal_member_registration]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ClientPortal_member_registration] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 
GO

/****** Object:  StoredProcedure [dbo].[dms_ClientPortal_member_registration]    Script Date: 07/23/2013 18:44:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--EXEC [dbo].[dms_ClientPortal_member_registration] 15287507, 2, 112233445566, 2, 'THISBE', 'J', 'BESTTEST', NULL, '8177779999', '8178889999', '123 MAIN STREET', NULL, NULL, 'FORT WORTH', 44, '77111', 1, 'THISBE.BESTTEST@GMAIL.COM', '2013-07-23', '2013-07-31', 'SYSTEM'

CREATE PROCEDURE [dbo].[dms_ClientPortal_member_registration](
	@memberID INT = NULL,
	@programID INT,
	@MembershipNumber NVARCHAR(25),
	@prefixID INT = NULL,
	@firstName NVARCHAR(50),
	@middleName NVARCHAR(50) = NULL,
	@lastName NVARCHAR(50),
	@suffixID INT = NULL,
	--@homePhoneTypeID INT,
	@homePhoneNumber NVARCHAR(50) = NULL,
	--@cellPhoneTypeID INT,
	@cellPhoneNumber NVARCHAR(50) = NULL,
	@addressLine1 NVARCHAR(100),
	@addressLine2 NVARCHAR(100) = NULL,
	@addressLine3 NVARCHAR(100) = NULL,
	--@addressTypeID INT,
	@city NVARCHAR(50),
	@stateID INT,
	@zipCode NVARCHAR(10)= NULL,
	@countryID INT,
	@email NVARCHAR(50) = NULL,
	@effectiveDate DATE,
	@expirationDate DATE,
	@userName NVARCHAR(50) = 'API'
	)
AS
BEGIN

	DECLARE @prefixName NVARCHAR(50)
	DECLARE @suffixName NVARCHAR(50)
	DECLARE @countryCode NVARCHAR(50)
	DECLARE @StateCode NVARCHAR(50)
	DECLARE @MemberEntityID INT
	DECLARE @MembershipEntityID INT
	DECLARE @HomeAddressTypeID INT
	DECLARE @HomePhoneTypeID INT
	DECLARE @CellPhoneTypeID INT
	DECLARE @MembershipID INT
	DECLARE @IsPrimary BIT = 0	
	DECLARE @IsNewMembership BIT = 0
	DECLARE @CurrentDate datetime
	DECLARE @sourceSystemID INT = NULL
	
	SET @prefixName			= (SELECT Name FROM Prefix WHERE ID = @prefixID)
	SET @suffixName			= (SELECT Name FROM  Suffix WHERE ID = @suffixID)
	SET @countryCode		= (SELECT ISOCode FROM Country WHERE ID = @countryID)
	SET @StateCode			= (SELECT Abbreviation FROM StateProvince WHERE ID = @stateID)
	SET @MemberEntityID		= (SELECT ID FROM Entity WHERE Name = 'Member')
	SET @membershipEntityID	= (SELECT ID FROM Entity WHERE Name = 'Membership')
	SET @HomeAddressTypeID  = (SELECT ID FROM AddressType WHERE Name = 'Home')
	SET @HomePhoneTypeID	= (SELECT ID FROM PhoneType WHERE Name = 'Home')
	SET @CellPhoneTypeID	= (SELECT ID FROM PhoneType WHERE Name = 'Cell')
	SET @CurrentDate		= GETDATE()
	SET @sourceSystemID		= (SELECT ID FROM SourceSystem WHERE Name = 'ClientPortal')
	
	
	--IF(@memberEntityID IS NULL)
	--RAISERROR('Unable to retrieve Entity Details for Member',16,1)
	
	--IF(@membershipEntityID IS NULL)
	--RAISERROR('Unable to retrieve Entity Details for Membership',16,1)
	
	BEGIN TRY
		BEGIN TRAN
		
			-- Get membership entity already if exists
			-- Allow program change if it is within the same client
  			SELECT TOP 1 @MembershipID = ms.id
  			FROM dbo.Membership ms
  			JOIN dbo.Member m on ms.ID = m.MembershipID
  			JOIN dbo.Program p on p.ID = m.ProgramID
  			WHERE ms.MembershipNumber = @MembershipNumber
  			AND p.ClientID = (SELECT ClientID FROM Program WHERE ID = @ProgramID)
  			AND (@memberID IS NULL OR m.ID = @MemberID)

			IF(@membershipID IS NULL) AND (@MemberID IS NOT NULL)
				RAISERROR('Unable to retrieve Membership Details for the supplied Member ID',16,1)

			-- Create new membership entity if not exists
			IF (@MembershipID IS NULL) 
			BEGIN
				-- TODO: Set ClientMembershipKey based on program rule
				INSERT INTO Membership(
					MembershipNumber,	SourceSystemID, -- KB: TFS: 2436 - Set SourceSystemID on Member and Membership.
					Email,				IsActive,			
					CreateDate,			CreateBy)
				VALUES (@MembershipNumber, @sourceSystemID,
					@email,				1,
					@CurrentDate,			@userName)
				
				-- Hold on to new Membership ID 
				SET @MembershipID = SCOPE_IDENTITY()

				-- If initial add of the membership then make this member the primary
				SET @IsPrimary = 1
				SET @IsNewMembership = 1
			END
			
			-- Determine if existing member is primary
			IF (@MemberID IS NOT NULL)
				SET @IsPrimary = ISNULL((SELECT IsPrimary FROM Member(NOLOCK) WHERE ID = @memberID),0)
				
			-- Insert or Update MemberShip Record if new membership or existing member is Primary
			IF (@MembershipID IS NOT NULL) AND @IsPrimary = 1 
			BEGIN
				
				DECLARE @MembershipAddressID INT
				DECLARE @MembershipHomePhoneID INT
			
				SET @MembershipAddressID	  = (SELECT ID FROM AddressEntity(NOLOCK) WHERE EntityID = @MembershipEntityID AND RecordID = @membershipID AND AddressTypeID = @HomeAddressTypeID)
				SET @MembershipHomePhoneID	  = (SELECT ID FROM PhoneEntity(NOLOCK) WHERE EntityID = @MembershipEntityID AND RecordID = @membershipID AND PhoneTypeID = @HomePhoneTypeID)

				-- Don't update membership if just added
				IF @IsNewMembership <> 1
					UPDATE Membership 
					SET 
						Email		= @email,
						ModifyBy	= @userName,
						ModifyDate	= @CurrentDate
					WHERE ID = @membershipID
					
				-- Create Membership Address Entity Record if not exists
				IF (@MembershipAddressID IS NULL)
					INSERT INTO AddressEntity(
							EntityID,				RecordID,		AddressTypeID,
							Line1,					Line2,			Line3,
							City,					StateProvince,	PostalCode,
							StateProvinceID,		CountryID,		CountryCode,
							CreateDate,				CreateBy)
					VALUES (					  
							@MembershipEntityID,	@MembershipID,	@HomeAddressTypeID,
							@addressLine1,			@addressLine2,	@addressLine3,
							@city,					@StateCode,		@zipCode,
							@stateID,				@countryID,		@countryCode,
							@CurrentDate,			@userName)
				
				-- Update Membership address
				IF (@MembershipAddressID IS NOT NULL)
					UPDATE AddressEntity 
					SET 
						AddressTypeID		= @HomeAddressTypeID,
						Line1				= @addressLine1,			
						Line2				= @addressLine2,			
						Line3				= @addressLine3,
						City				= @city,				
						StateProvince		= @StateCode,	
						PostalCode			= @zipCode,
						StateProvinceID		= @stateID,	
						CountryID			= @countryID,		
						CountryCode			= @countryCode,
						ModifyBy		    = @userName,			
						ModifyDate			= @CurrentDate
					WHERE 
						ID					= @MembershipAddressID

				-- Create Membership Home Phone Entity is not exists
				IF (@MembershipHomePhoneID IS NULL) AND (ISNULL(@HomePhoneNumber,'') <> '')
					INSERT INTO PhoneEntity  (
						EntityID,				RecordID,		PhoneTypeID,
						PhoneNumber,			CreateDate,		CreateBy)
					VALUES (
						@MembershipEntityID,	@MembershipID,	@homePhoneTypeID,
						@homePhoneNumber,		@CurrentDate,	@userName)		
						
				-- Update Existing Membership Home Phone Entity
				IF (@MembershipHomePhoneID IS NOT NULL)
					UPDATE PhoneEntity  
					SET
						PhoneNumber		= @homePhoneNumber,	
						ModifyDate		= @CurrentDate,
						ModifyBy		= @userName
					WHERE 
						ID				= @MembershipHomePhoneID
			END


			-- Insert member if not existing
			IF(@MemberID IS NULL)
			BEGIN
				-- Create Member Record
				INSERT INTO Member(
					MembershipID,	ProgramID,
					SourceSystemID,		
					Prefix,			FirstName,
					MiddleName,		LastName,
					Suffix,	    	Email,
					EffectiveDate,	ExpirationDate,
					IsPrimary,		IsActive,
					CreateDate,		CreateBy)
				VALUES(			   
					@MembershipID,	@programID,
					@sourceSystemID,
					@prefixName,	@firstName,
					@middleName,	@lastName,
					@suffixName,	@email,
					@effectiveDate,	@expirationDate,
					@IsPrimary,		1,				
					@CurrentDate,	@userName)
				
				
				-- Set member ID value
				SET @MemberID = SCOPE_IDENTITY()
				
			END
			ELSE IF (@memberID IS NOT NULL)
			BEGIN
				-- Update existing member record
				UPDATE Member SET
								   ProgramID	 = @programID,
								   Prefix		 = @prefixName,			
								   FirstName	 = @firstName,
								   MiddleName	 = @middleName,		
								   LastName		 = @lastName,
								   Suffix		 = @suffixName,	    	
								   Email		 = @email,
								   EffectiveDate = @effectiveDate,	
								   ExpirationDate= @expirationDate,
								   ModifyDate	 = @CurrentDate,		
								   ModifyBy      = @userName
							 WHERE ID = @memberID
			END
			
			
			-- Retrieve associated recordID
			DECLARE @MemberAddressID INT
			DECLARE @MemberHomePhoneID INT
			DECLARE @MemberCellPhoneID INT
			
			SET @MemberAddressID	  = (SELECT ID FROM AddressEntity(NOLOCK) WHERE EntityID = @MemberEntityID AND RecordID = @memberID AND AddressTypeID = @HomeAddressTypeID)
			SET @MemberHomePhoneID	  = (SELECT ID FROM PhoneEntity(NOLOCK) WHERE EntityID = @MemberEntityID AND RecordID = @memberID AND PhoneTypeID = @HomePhoneTypeID)
			SET @MemberCellPhoneID	  = (SELECT ID FROM PhoneEntity(NOLOCK) WHERE EntityID = @MemberEntityID AND RecordID = @memberID AND PhoneTypeID = @CellPhoneTypeID)

			-- Create Address Record
			IF (@MemberAddressID IS NULL)	
				INSERT INTO AddressEntity(
					EntityID,			RecordID,		AddressTypeID,
					Line1,				Line2,			Line3,
					City,				StateProvince,	PostalCode,
					StateProvinceID,	CountryID,		CountryCode,
					CreateBy,			CreateDate)
				VALUES(					  
					@MemberEntityID,	@MemberID,		@HomeAddressTypeID,
					@addressLine1,		@addressLine2,	@addressLine3,
					@city,				@StateCode,		@zipCode,
					@stateID,			@countryID,		@countryCode,
					@userName,			@CurrentDate)
			
			
			-- Update Address Entity
			IF (@MemberAddressID IS NOT NULL)	
			UPDATE	AddressEntity 
			SET 
				  AddressTypeID		= @HomeAddressTypeID,
				  Line1				= @addressLine1,			
				  Line2				= @addressLine2,			
				  Line3				= @addressLine3,
				  City				= @city,				
				  StateProvince		= @StateCode,	
				  PostalCode		= @zipCode,
				  StateProvinceID	= @stateID,	
				  CountryID			= @countryID,		
				  CountryCode		= @countryCode,
				  ModifyBy		    = @userName,			
				  ModifyDate		= @CurrentDate
			WHERE ID = @MemberAddressID
			
			-- Insert Home Phone entity if not exists
			IF (@MemberHomePhoneID IS NULL)	AND (ISNULL(@HomePhoneNumber,'') <> '')				
				INSERT INTO PhoneEntity  (
					EntityID,			RecordID,	  PhoneTypeID,
					PhoneNumber,	    CreateDate,   CreateBy)
				VALUES(					  
					@MemberEntityID,	@MemberID, @HomePhoneTypeID,
					@homePhoneNumber,	@CurrentDate, @userName)	
						
			-- Update Existing Member Home Phone Entity
			IF (@MemberHomePhoneID IS NOT NULL)					
				UPDATE PhoneEntity  
				SET
					  PhoneNumber	= @homePhoneNumber,	
					  ModifyDate	= @CurrentDate,
					  ModifyBy		= @userName
				WHERE ID = @MemberHomePhoneID
				
			-- Insert Member Cell Phone entity if not exists
			IF (@MemberCellPhoneID IS NULL)	AND (ISNULL(@CellPhoneNumber,'') <> '')				
				INSERT INTO PhoneEntity  (
					EntityID,			RecordID,	  PhoneTypeID,
					PhoneNumber,	    CreateDate,   CreateBy)
				VALUES(					  
					@MemberEntityID,	@MemberID, @CellPhoneTypeID,
					@CellPhoneNumber,	@CurrentDate, @userName)	
								
			-- Update Existing Member Cell Phone Entity
			IF (@MemberCellPhoneID IS NOT NULL)					
				UPDATE PhoneEntity  
				SET
					PhoneNumber = @cellPhoneNumber,	
					ModifyDate = @CurrentDate,
					ModifyBy = @userName
				WHERE ID = @MemberCellPhoneID				

		COMMIT TRAN
	END TRY
	
	
	BEGIN CATCH
		-- XACT_STATE =  0  means there is no transaction
		-- XACT_STATE =  1  means transaction is uncommittable
		-- XACT_STATE = -1  means it's active transaction and valid
		IF (XACT_STATE() = -1 OR XACT_STATE() = 1)
			BEGIN
				ROLLBACK TRANSACTION;
			END;
	
		DECLARE 
			@ErrorMessage    NVARCHAR(4000),
			@ErrorNumber     INT,
			@ErrorSeverity   INT,
			@ErrorState      INT,
			@ErrorLine       INT,
			@ErrorProcedure  NVARCHAR(200);

		-- Assign variables to error-handling functions that 
		-- capture information for RAISERROR.
		SELECT 
			@ErrorNumber = ERROR_NUMBER(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE(),
			@ErrorLine = ERROR_LINE(),
			@ErrorProcedure = ISNULL(ERROR_PROCEDURE(), '-');
		 RAISERROR 
			(
			@ErrorMessage, 
			@ErrorSeverity, 
			1,               
			@ErrorNumber,    -- parameter: original error number.
			@ErrorSeverity,  -- parameter: original error severity.
			@ErrorState,     -- parameter: original error state.
			@ErrorProcedure, -- parameter: original error procedure name.
			@ErrorLine       -- parameter: original error line number.
			);
	END CATCH
END

GO


