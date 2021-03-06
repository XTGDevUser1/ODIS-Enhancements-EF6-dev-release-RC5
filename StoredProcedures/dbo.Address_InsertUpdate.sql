/****** Object:  StoredProcedure [dbo].[Address_InsertUpdate]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Address_InsertUpdate]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Address_InsertUpdate] 
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

--******************************************************************************************
--******************************************************************************************
--
--******************************************************************************************
--******************************************************************************************

CREATE PROCEDURE [dbo].[Address_InsertUpdate]
			(
				@pEntityID int,
				@pAddresstype varchar(15),
				@pLine1 varchar(100) = NULL,
				@pLine2 varchar(100) = NULL,
				@pLine3 varchar(100) = NULL,
				@pCity varchar(100) = NULL,
				@pStateProvince varchar(10) = NULL,
				@pPostalCode varchar(20) = NULL,
				@pStateProvinceID int = NULL,
				@pCountryID int = NULL,
				@pCountryCode varchar(2) = NULL,
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
declare @AddressTypeID as int

if @pEntityID = 5 
begin 
	SELECT @RecordID = m.ID  
				FROM dbo.Member m with(nolock)
				where 1=1
					and m.ClientMemberKey = @pClientmemberKey
End

if @pEntityID = 6 
begin 
	SELECT @RecordID = ms.ID  
				FROM dbo.Member m with(nolock)
				join dbo.Membership ms with(nolock) on m.MembershipID = ms.id
				where 1=1
					and m.ClientMemberKey = @pClientmemberKey
End

SELECT @AddressTypeID = [ID]
			FROM dbo.AddressType ad with(nolock)
			Where 1=1
				and ad.IsActive = 1
				and ad.Name = @pAddresstype

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
				@AddressTypeID,
				@pLine1,
				Case when isnull(@pLine2,'') = '' then null else @pLine2 end,
				Case when isnull(@pLine3,'') = '' then null else @pLine3 end,
				@pCity,
				@pStateProvince,
				@pPostalCode,
				@pStateProvinceID,
				@pCountryID,
				@pCountryCode,
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
				[CreateBatchID],
				[CreateDate],
				[CreateBy],
				[ModifyBatchID],
				[ModifyDate],
				[ModifyBy]
           )
    ON (target.RecordID = source.RecordID
		AND target.EntityID = source.EntityID
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
				ModifyBatchID = source.ModifyBatchid,
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
				[CreateBatchID],
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
				source.[CreateBatchID],
				source.[CreateDate],
				source.[CreateBy]
           );
GO

