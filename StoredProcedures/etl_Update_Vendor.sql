IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[etl_Update_Vendor]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[etl_Update_Vendor]
GO

CREATE PROCEDURE [dbo].[etl_Update_Vendor] 
	@BatchID int
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRANSACTION;
	
	DECLARE @VendorEntityID int
	SET @VendorEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'Vendor')
	
	/** Add New Vendors **/
	INSERT INTO dbo.vendor
		([VendorNumber]
		,[Name]
		,[TaxIDNumber]
		,[AdministrativeRating]
		,[BankABANumber]
		,[BankAccountNumber]
		,[Website]
		,[Email]
		,[InsuranceExpirationDate]
		,[DealerNumber]
		,[IsActive]
		,[IsDoNotUse]
		,[CreateBatchID]
		,[CreateDate]
		,[CreateBy])
	SELECT 
		staging.[VendorNumber]
		,staging.[Name]
		,staging.[TaxIDNumber]
		,staging.[AdministrativeRating]
		,staging.[BankABANumber]
		,staging.[BankAccountNumber]
		,staging.[Website]
		,staging.[Email]
		,staging.[InsuranceExpirationDate]
		,staging.[DealerNumber]
		,staging.[IsActive]
		,staging.[IsDoNotUse]
		,staging.[BatchID]
		,staging.[DateAdded]
		,'System'
  	FROM dbo.[etl_Staging_Vendor] staging
  	WHERE staging.[BatchID] = @BatchID
  	AND staging.[Operation] = 'I'
  	AND staging.[ProcessFlag] <> 'Y'
  	AND NOT EXISTS (
  		SELECT * 
  		FROM dbo.Vendor v
  		WHERE v.VendorNumber = staging.VendorNumber);


	/** Update Existing Vendors **/
	UPDATE vendor
	SET [Name] = staging.Name
		,[TaxIDNumber] = staging.TaxIDNumber
		,[AdministrativeRating] = staging.AdministrativeRating
		,[BankABANumber] = staging.BankABANumber
		,[BankAccountNumber] = staging.BankAccountNumber
		,[Website] = staging.Website
		,[Email] = staging.Email
		,[InsuranceExpirationDate] = staging.InsuranceExpirationDate
		,[DealerNumber] = staging.DealerNumber
		,[IsActive] = staging.IsActive
		,[IsDoNotUse] = staging.IsDoNotUse
		,[ModifyBatchID] = staging.BatchID
		,[ModifyDate] = staging.DateAdded
		,[ModifyBy] = 'System'
  	FROM dbo.[etl_Staging_Vendor] staging
  	JOIN dbo.vendor vendor
  		ON staging.VendorID = vendor.ID
  	WHERE staging.[BatchID] = @BatchID
  	AND staging.[Operation] = 'U'
  	AND staging.[ProcessFlag] <> 'Y';


	/** Update Existing Vendor Address Entry **/
	UPDATE [AddressEntity]
	SET [Line1] = staging.Line1
		,[Line2] = staging.Line2
		,[Line3] = staging.Line3
		,[City] = staging.City
		,[StateProvince] = sp.Abbreviation
		,[PostalCode] = staging.PostalCode
		,[StateProvinceID] = sp.ID
		,[CountryID] = c.ID
		,[CountryCode] = staging.CountryCode
		,[ModifyBatchID] = staging.BatchID
		,[ModifyDate] = staging.DateAdded
		,[ModifyBy] = 'System'
	FROM dbo.[etl_Staging_VendorAddress] staging
	JOIN dbo.Vendor Vendor
		ON staging.VendorID = Vendor.ID
	JOIN dbo.AddressType AddressType
		ON AddressType.Name = staging.AddressType
	JOIN dbo.AddressEntity AddressEntity
		ON AddressEntity.EntityID = @VendorEntityID
		AND AddressEntity.RecordID = Vendor.ID
		AND AddressEntity.AddressTypeID = AddressType.ID
	JOIN dbo.Country c 
		ON c.ISOCode = staging.CountryCode
	LEFT OUTER JOIN dbo.StateProvince sp
		ON sp.Abbreviation = staging.StateProvince
		AND sp.CountryID = c.ID
  	WHERE staging.[BatchID] = @BatchID
  	AND staging.[Operation] = 'U'
  	AND staging.[ProcessFlag] <> 'Y';


	/** Add New Vendor Addresses - for newly added vendor or existing vendor**/
  	/** I and U Operations apply to the Vendor not the address, so Updated vendors could have new addresses **/
	INSERT INTO dbo.[AddressEntity]
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
		@VendorEntityID
		,v.ID
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
		,staging.BatchID
		,staging.[DateAdded]
		,'System'
	FROM dbo.[etl_Staging_VendorAddress] staging
	JOIN dbo.Vendor v 
		ON v.VendorNumber = staging.VendorNumber
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
  		WHERE ae.RecordID = v.ID
  			AND ae.EntityID = @VendorEntityID
  			AND ae.AddressTypeID = at.ID);

 	
	/** Update existing phone number entries **/
	UPDATE PhoneEntity
	SET [EntityID] = @VendorEntityID
		,[RecordID] = Vendor.ID
		,[PhoneTypeID] = PhoneType.ID
		,[PhoneNumber] = CASE WHEN staging.PhoneNumber = '0' THEN NULL ELSE '1 ' + staging.PhoneNumber END
		,[IndexPhoneNumber] = NULL
		,[Sequence] = 0
		,[ModifyBatchID] = staging.BatchID
		,[ModifyDate] = staging.DateAdded
		,[ModifyBy] = 'System'
	FROM dbo.[etl_Staging_VendorPhone] staging
	JOIN dbo.Vendor Vendor
		ON staging.VendorID = Vendor.ID
	JOIN dbo.PhoneType PhoneType
		ON PhoneType.Name = Staging.PhoneType
	JOIN dbo.PhoneEntity PhoneEntity
		ON PhoneEntity.EntityID = @VendorEntityID
		AND PhoneEntity.RecordID = Vendor.ID
		AND PhoneEntity.PhoneTypeID = PhoneType.ID
  	WHERE staging.[BatchID] = @BatchID
  	AND staging.[Operation] = 'U'
  	AND staging.[ProcessFlag] <> 'Y';


  	/** Add new Phone entries **/
  	/** I and U Operations apply to the Vendor not the phone, so Updated vendors could have new phone numbers **/
	INSERT INTO dbo.[PhoneEntity]
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
		@VendorEntityID
		,v.ID
		,pt.ID
		,CASE WHEN staging.PhoneNumber = '0' THEN NULL ELSE '1 ' + staging.PhoneNumber END
		,NULL
		,0
		,staging.[BatchID]
		,staging.[DateAdded]
		,'System'
	FROM dbo.[etl_Staging_VendorPhone] staging
	JOIN dbo.Vendor v 
		ON v.VendorNumber = staging.VendorNumber
	JOIN dbo.PhoneType pt
		ON pt.Name = staging.PhoneType
  	WHERE staging.[BatchID] = @BatchID
  	AND staging.[Operation] IN ('I','U')
  	AND staging.[ProcessFlag] <> 'Y'
  	AND NOT EXISTS (
  		SELECT *
  		FROM dbo.PhoneEntity pe
  		WHERE pe.RecordID = v.ID
  			AND pe.EntityID = @VendorEntityID
  			AND pe.PhoneTypeID = pt.ID);

	COMMIT TRANSACTION;

	/* Add Tire Repair to Tire Stores that do not already have Tire Repair */
	/* This update is necessary to allow these vendors to be selected by the ISP Selection logic */
	DECLARE @ProductList table (ProductID int)
	INSERT INTO @ProductList (ProductID) Values (130)
	INSERT INTO @ProductList (ProductID) Values (132)
	INSERT INTO @ProductList (ProductID) Values (134)

	INSERT INTO [DMS].[dbo].[VendorLocationProduct]
			   ([VendorLocationID]
			   ,[ProductID]
			   ,[IsActive]
			   ,[Rating]
			   ,[CreateDate]
			   ,[CreateBy])
	Select 
		TireLocation.VendorLocationID
		,Prod.ProductID
		,1
		,Case When TireLocation.Rating = 0 Then 70 Else TireLocation.Rating End
		,getdate()
		,'System'
	From (
		Select vl.ID VendorLocationID, min(vlp.Rating) Rating
		--v.vendornumber, vl.* 
		from vendor v
		join vendorlocation vl on v.id = vl.vendorid
		join vendorlocationproduct vlp on vlp.vendorlocationID = vl.ID
		where 
		v.IsActive = 1
		-- Has Tire Sales Attributes
		and exists (
			Select *
			from vendorlocation vl1 
			join vendorlocationproduct vlp1 on vlp1.vendorlocationid = vl1.id
			join product p On vlp1.ProductID = p.id and p.ProductCategoryID = 2 and p.ProductTypeID = 2 and p.ProductSubTypeID = 10
			Where vl1.id = vl.id
			)
		-- Does not have Tire Repair Service
		and not exists (
			Select *
			from vendorlocation vl1 
			join vendorlocationproduct vlp1 on vlp1.vendorlocationid = vl1.id
			join @ProductList prod ON prod.ProductID = vlp1.ProductID
			Where vl1.id = vl.id
			)
		Group By Vl.ID	
		) TireLocation
	JOIN @ProductList Prod On 1=1
	
END
GO

