IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[VendorAddress_InsertUpdate]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[VendorAddress_InsertUpdate]
GO

--******************************************************************************************
--******************************************************************************************
--
--
--
--******************************************************************************************
--******************************************************************************************

--******************************************************************************************

--dbo.VendorAddress_InsertUpdate 58, '0000097689', 17, 2, '1565 HIGHWAY 96 BYPASS', NULL, NULL, 'City', 'State', StaetID,'PostalCode','CountryCode','CountryID','2016-01-26 00:00:00.000','DispatchVendorPost',NULL,NULL

--dbo.VendorAddress_InsertUpdate 58, '0000097689', 17, 2, '1565 HIGHWAY 96 BYPASS', NULL, NULL, 'City', 'State', StaetID,'PostalCode','CountryCode','CountryID','2016-01-26 00:00:00.000','DispatchVendorPost',NULL,NULL

--select * from VendorAddress where ClientVendorKey = '0000097689' 
--******************************************************************************************
--******************************************************************************************

CREATE PROCEDURE [dbo].[VendorAddress_InsertUpdate]
			(
				@pClientID int,
				@pClientVendorKey varchar(50),
				@pEntityID int,
				@pAddressTypeID int,
				@pLine1 varchar(100) = NULL,
				@pLine2 varchar(100) = NULL,
				@pLine3 varchar(100) = NULL,
				@pCity varchar(100) = NULL,
				@pStateProvince varchar(10) = NULL,
				@pStateProvinceID int = NULL,
				@pPostalCode varchar(20) = NULL,
				@pCountryCode varchar(2) = NULL,
				@pCountryID int = NULL,
				@pCreateDate datetime = NULL,
				@pCreateBy varchar(50) = NULL,
				@pModifyDate datetime = NULL,
				@pModifyBy varchar(50) = NULL
			)
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT OFF

declare @RecordID as int
declare @AddressTypeID as int

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

--SELECT @AddressTypeID = [ID]
--			FROM dbo.AddressType ad with(nolock)
--			Where 1=1
--				and ad.IsActive = 1
--				and ad.Name = @pAddresstype

if @pCountryID is null 
begin 
    select @pCountryID = (select top 1 sp.CountryID 
    from StateProvince sp
    where sp.Abbreviation = @pStateProvince
    order by CountryID)
    
    select @pCountryCode = (select top 1 ISOCode 
    from Country c
    where ID = @pCountryID)
    
end


select @pStateProvinceID = (select top 1 sp.ID 
    from StateProvince sp
    where sp.Abbreviation = @pStateProvince
    and sp.CountryID = @pCountryID
    order by CountryID)




   MERGE [dbo].[AddressEntity] AS target
    USING (select
				@pEntityID, 
				@RecordID,
				@pAddressTypeID,
				@pLine1,
				Case when isnull(@pLine2,'') = '' then null else @pLine2 end,
				Case when isnull(@pLine3,'') = '' then null else @pLine3 end,
				@pCity,
				@pStateProvince,
				@pPostalCode,
				@pStateProvinceID,
				@pCountryID,
				@pCountryCode,
				@pCreateDate,
				@pCreateBy,
				@pModifyDate,
				@pModifyBy
			)
			as source( 
				[EntityID], 
				[RecordID],
				[AddressTypeID],
				[Line1],
				[Line2],
				[Line3],
				[City],
				[StateProvince],
				[PostalCode],
				[StateProvinceID],
				[CountryID],
				[CountryCode],
				[CreateDate],
				[CreateBy],
				[ModifyDate],
				[ModifyBy]
           )
    ON (target.RecordID = source.RecordID
		AND target.EntityID = source.EntityID
		AND target.AddressTypeID = source.AddressTypeID
		)
    
    WHEN MATCHED THEN 
        UPDATE SET 
				Line1 = source.Line1,
				Line2 = source.Line2,
				Line3 = source.Line3,
				City = source.City,
				StateProvince = source.StateProvince,
				PostalCode = source.PostalCode,
				StateProvinceID = source.StateProvinceID,
				CountryID = source.CountryID,
				CountryCode = source.CountryCode,
				ModifyDate = source.ModifyDate,
				ModifyBy = source.ModifyBy
	WHEN NOT MATCHED THEN	
	    INSERT	(
				[EntityID], 
				[RecordID],
				[AddressTypeID],
				[Line1],
				[Line2],
				[Line3],
				[City],
				[StateProvince],
				[PostalCode],
				[StateProvinceID],
				[CountryID],
				[CountryCode],
				[CreateDate],
				[CreateBy]
				)
	    VALUES (
				source.[EntityID], 
				source.[RecordID],
				source.[AddressTypeID],
				source.[Line1],
				source.[Line2],
				source.[Line3],
				source.[City],
				source.[StateProvince],
				source.[PostalCode],
				source.[StateProvinceID],
				source.[CountryID],
				source.[CountryCode],
				source.[CreateDate],
				source.[CreateBy]
           );
GO

