IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[etl_Update_VendorLocation]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[etl_Update_VendorLocation]
GO

CREATE PROCEDURE [dbo].[etl_Update_VendorLocation] 
	@BatchID int
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION	
		
		DECLARE 
			@VendorLocationTypeID int,
			@VendorLocationEntityID int;
		SET @VendorLocationTypeID = (SELECT ID FROM dbo.VendorLocationType WHERE Name = 'Physical');
		SET @VendorLocationEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'VendorLocation')

		/** Add New Vendors **/
		INSERT INTO dbo.VendorLocation
			([VendorID]
			,[VendorLocationTypeID]
			,[Sequence]
			,[Email]
			,[BusinessHours]
			,[DealerNumber]
			,[IsCreditCardAccepted]
			,[IsPersonalCheckAccepted]
			,[IsCashOnly]
			,[IsOpen24Hours]
			,[IsActive]
			,[Latitude]
			,[Longitude]
			,[GeographyLocation]
			,[CreateDate]
			,[CreateBy])
		SELECT 
			staging.[VendorID]
			,@VendorLocationTypeID 
			,staging.[Sequence]
			,staging.[Email]
			,staging.[BusinessHours]
			,staging.[DealerNumber]
			,staging.[IsCreditCardAccepted]
			,staging.[IsPersonalCheckAccepted]
			,staging.[IsCashOnly]
			,staging.[IsOpen24Hours]
			,staging.[IsActive]
			,staging.[Latitude]
			,staging.[Longitude]
			,CASE WHEN staging.Latitude IS NOT NULL and staging.Longitude is not null 
					and staging.Latitude <= 90 and staging.Latitude >= -90
					and staging.Longitude <= 180 and staging.Longitude >= -180
				THEN geography::Point(staging.Latitude, staging.Longitude, 4326)
				ELSE NULL
				END GeographyLocation
			,[DateAdded]
			,'System'
  		FROM [dbo].[etl_Staging_VendorLocation] staging
  		WHERE staging.[BatchID] = @BatchID
  		AND staging.[Operation] = 'I'
  		AND staging.[ProcessFlag] <> 'Y'
  		AND NOT EXISTS (
  			SELECT * 
  			FROM dbo.VendorLocation vl
 			WHERE vl.VendorID = staging.VendorID 
  				AND vl.Sequence = staging.Sequence);


		/** Update Existing Vendors **/
		UPDATE VendorLocation
		SET 
			[Email] = staging.[Email]
			,[BusinessHours] = staging.[BusinessHours]
			,[DealerNumber] = staging.[DealerNumber]
			,[IsCreditCardAccepted] = staging.[IsCreditCardAccepted]
			,[IsPersonalCheckAccepted] = staging.[IsPersonalCheckAccepted]
			,[IsCashOnly] = staging.[IsCashOnly]
			,[IsOpen24Hours] = staging.[IsOpen24Hours]
			,[IsActive] = staging.[IsActive]
			,[Latitude] = 
				CASE WHEN staging.Latitude IS NOT NULL and staging.Longitude is not null 
					and staging.Latitude <= 90 and staging.Latitude >= -90
					and staging.Longitude <= 180 and staging.Longitude >= -180
				THEN staging.[Latitude]
				ELSE VendorLocation.[Latitude]
				END
			,[Longitude] = 
				CASE WHEN staging.Latitude IS NOT NULL and staging.Longitude is not null 
					and staging.Latitude <= 90 and staging.Latitude >= -90
					and staging.Longitude <= 180 and staging.Longitude >= -180
				THEN staging.[Longitude]
				ELSE VendorLocation.[Longitude]
				END
			,[GeographyLocation] = 
				CASE WHEN staging.Latitude IS NOT NULL and staging.Longitude is not null 
					and staging.Latitude <= 90 and staging.Latitude >= -90
					and staging.Longitude <= 180 and staging.Longitude >= -180
				THEN geography::Point(staging.Latitude, staging.Longitude, 4326)
				ELSE VendorLocation.GeographyLocation
				END
			,[ModifyDate] = staging.DateAdded
			,[ModifyBy] = 'System'
  		FROM [dbo].[etl_Staging_VendorLocation] staging
  		JOIN dbo.VendorLocation VendorLocation
  			ON staging.VendorLocationID = VendorLocation.ID
  		WHERE staging.[BatchID] = @BatchID
  		AND staging.[Operation] = 'U'
  		AND staging.[ProcessFlag] <> 'Y';


		/** Update Existing Vendor Address Entry **/
		UPDATE [AddressEntity]
		SET [Line1] = staging.Line1
			,[Line2] = staging.Line2
			,[Line3] = staging.Line3
			,[City] = staging.City
			,[StateProvince] = staging.StateProvince
			,[PostalCode] = staging.PostalCode
			,[StateProvinceID] = sp.ID
			,[CountryID] = c.ID
			,[CountryCode] = staging.CountryCode
			,[ModifyDate] = staging.DateAdded
			,[ModifyBy] = 'System'
		FROM [dbo].[etl_Staging_VendorAddress] staging
		JOIN dbo.VendorLocation VendorLocation
			ON staging.VendorLocationID = VendorLocation.ID
		JOIN dbo.AddressType AddressType
			ON AddressType.Name = staging.AddressType
		JOIN dbo.AddressEntity AddressEntity
			ON AddressEntity.EntityID = @VendorLocationEntityID
			AND AddressEntity.RecordID = VendorLocation.ID
			AND AddressEntity.AddressTypeID = AddressType.ID
		JOIN dbo.Country c 
			ON c.ISOCode = staging.CountryCode
		LEFT OUTER JOIN dbo.StateProvince sp
			ON sp.Abbreviation = staging.StateProvince
			AND sp.CountryID = c.ID
  		WHERE staging.[BatchID] = @BatchID
  		AND staging.[Operation] = 'U'
  		AND staging.[ProcessFlag] <> 'Y';

	  	
		/** Add New Vendor Addresses - for newly added vendor location or existing vendor location **/
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
			,[CreateDate]
			,[CreateBy])
		SELECT 
			@VendorLocationEntityID
			,vl.ID
			,at.ID
			,staging.[Line1]
			,staging.[Line2]
			,staging.[Line3]
			,staging.[City]
			,sp.Abbreviation
			,staging.[PostalCode]
			,sp.ID
			,c.ID
			,staging.[CountryCode]
			,staging.[DateAdded]
			,'System'
		FROM [dbo].[etl_Staging_VendorAddress] staging
  		JOIN dbo.Vendor Vendor
  			ON Vendor.VendorNumber = staging.VendorNumber 
		JOIN dbo.VendorLocation vl
			ON Vendor.ID = vl.VendorID
			AND staging.Sequence = vl.Sequence
		JOIN dbo.AddressType at
			ON at.Name = staging.AddressType
		JOIN dbo.Country c 
			ON c.ISOCode = staging.CountryCode
		LEFT OUTER JOIN dbo.StateProvince sp
			ON sp.Abbreviation = staging.StateProvince
			AND sp.CountryID = c.ID
  		WHERE staging.[BatchID] = @BatchID
  		AND staging.[Operation] IN ('I','U')
  		AND staging.[ProcessFlag] <> 'Y'
  		AND NOT EXISTS (
  			SELECT * 
  			FROM dbo.AddressEntity ae
  			WHERE ae.RecordID = vl.ID
  				AND ae.EntityID = @VendorLocationEntityID
  				AND ae.AddressTypeID = at.ID);


  		/** Add new Phone entries **/
		INSERT INTO dbo.PhoneEntity
			([EntityID]
			,[RecordID]
			,[PhoneTypeID]
			,[PhoneNumber]
			,[IndexPhoneNumber]
			,[Sequence]
			,[CreateDate]
			,[CreateBy])
		SELECT 
			@VendorLocationEntityID
			,vl.ID
			,pt.ID
			,CASE WHEN staging.PhoneNumber = '0' THEN NULL ELSE '1 ' + staging.PhoneNumber END
			,NULL
			,0
			,staging.[DateAdded]
			,'System'
		FROM [dbo].[etl_Staging_VendorPhone] staging
		JOIN dbo.Vendor v 
			ON v.VendorNumber = staging.VendorNumber
		JOIN dbo.VendorLocation vl
			ON v.ID = vl.VendorID
			AND staging.Sequence = vl.Sequence
		JOIN dbo.PhoneType pt
			ON pt.Name = staging.PhoneType
  		WHERE staging.[BatchID] = @BatchID
  		AND staging.[Operation] IN ('I','U')
  		AND staging.[ProcessFlag] <> 'Y'
  		AND NOT EXISTS (
  			SELECT *
  			FROM dbo.PhoneEntity pe
  			WHERE pe.RecordID = vl.ID
  				AND pe.EntityID = @VendorLocationEntityID
  				AND pe.PhoneTypeID = pt.ID);

		
		/** Update existing phone number entries **/
		UPDATE PhoneEntity
		SET [EntityID] = @VendorLocationEntityID
			,[RecordID] = vl.ID
			,[PhoneTypeID] = PhoneType.ID
			,[PhoneNumber] = CASE WHEN staging.PhoneNumber = '0' THEN NULL ELSE '1 ' + staging.PhoneNumber END
			,[IndexPhoneNumber] = NULL
			,[Sequence] = 0
			,[ModifyDate] = staging.DateAdded
			,[ModifyBy] = 'System'
		FROM [dbo].[etl_Staging_VendorPhone] staging
		JOIN dbo.VendorLocation vl
			ON staging.VendorLocationID = vl.ID
		JOIN dbo.PhoneType PhoneType
			ON PhoneType.Name = Staging.PhoneType
		JOIN dbo.PhoneEntity PhoneEntity
			ON PhoneEntity.EntityID = @VendorLocationEntityID
			AND PhoneEntity.RecordID = vl.ID
			AND PhoneEntity.PhoneTypeID = PhoneType.ID
  		WHERE staging.[BatchID] = @BatchID
  		AND staging.[Operation] = 'U'
  		AND staging.[ProcessFlag] <> 'Y';

		/** Add new vendor location comments **/
		INSERT INTO dbo.Comment
			([CommentTypeID]
			,[EntityID]
			,[RecordID]
			,[Description]
			,[CreateDate]
			,[CreateBy])
		SELECT 
			NULL
			,@VendorLocationEntityID
			,VendorLocation.ID
			,staging.[Description]
			,[DateAdded]
			,'System'
		FROM [dbo].[etl_Staging_VendorComment] staging
  		JOIN dbo.Vendor Vendor
  			ON Vendor.VendorNumber = staging.VendorNumber 
		JOIN dbo.VendorLocation VendorLocation 
			ON Vendor.ID = VendorLocation.VendorID
			AND staging.Sequence = VendorLocation.Sequence
  		WHERE staging.[BatchID] = @BatchID
  		AND staging.[Operation] = 'I'
  		AND staging.[ProcessFlag] <> 'Y'
  		AND NOT EXISTS (
  			SELECT *
  			FROM dbo.Comment comment
  			WHERE comment.EntityID = @VendorLocationEntityID
  			AND comment.RecordID = VendorLocation.ID
  			);

		/** Update existing vendor location comment **/
		UPDATE Comment
			SET [Description] = staging.[Description]
		FROM [dbo].[etl_Staging_VendorComment] staging
		JOIN dbo.Comment Comment
			ON Comment.EntityID = @VendorLocationEntityID
			AND staging.VendorLocationID = Comment.RecordID
  		WHERE staging.[BatchID] = @BatchID
  		AND staging.[Operation] = 'U'
  		AND staging.[ProcessFlag] <> 'Y'

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

