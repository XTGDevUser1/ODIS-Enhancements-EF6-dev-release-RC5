/****** Object:  StoredProcedure [dbo].[Member_InsertUpdate]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Member_InsertUpdate]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Member_InsertUpdate] 
 END 
 GO  

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--******************************************************************************************
--******************************************************************************************
--
--RRH	^1			11/01/13			adding AccountSource
--
--******************************************************************************************
--******************************************************************************************


--******************************************************************************************
--******************************************************************************************
--exe Member_InsertUpdate 107, '@pMemberNumber', '@pPrefix', '@pFirstName', '@pMiddleName', '@pLastName', '@pSuffix', '@pEmail', '@pEffectiveDate', '@pExpirationDate','@pMemberSinceDate','@pClientMemberKey','@pClientMembershipKey','@pIsPrimary','@pIsActive','@pCreateBatchID','@pCreateDate','@pCreateBy','@pModifyBatchID','@pModifyDate','@pModifyBy'
--[dbo].[Member_InsertUpdate] 107, '9831617', NULL, 'BOBBY WAYNE', NULL, 'NORRIS', NULL, NULL, '2000-08-02 00:00:00.000', '2014-08-25 00:00:00.000','2000-08-02 00:00:00.000','000000013686951000','000000013686951',1,1,1086,'2013-01-27 14:06:30.000','System',7156,'2013-09-19 16:33:55.040','DISPATCHPOST'
--dbo.Member_InsertUpdate 107, '9831617', NULL, 'BOBBY WAYNE', NULL, 'NORRIS', NULL, NULL, NULL, '2014-08-25 00:00:00.000','2000-08-02 00:00:00.000','000000013686951000','000000013686951',1,1,1086,'2013-01-27 14:06:30.000','System',7156,'2013-09-19 16:33:55.040','DISPATCHPOST'
--select * from member where firstname = 'BOBBY WAYNE' 
--******************************************************************************************
--******************************************************************************************

CREATE PROCEDURE [dbo].[Member_InsertUpdate]
			(
				@pProgramID int = NULL,	
				@pMemberNumber varchar(50),
				@pPrefix varchar(10) = NULL,	
				@pFirstName varchar(50) = NULL,
				@pMiddleName varchar(50) = NULL,
				@pLastName varchar(50) = NULL,
				@pSuffix varchar(10) = NULL,
				@pEmail varchar(255) = NULL,
				@pEffectiveDate	datetime = NULL,			 
				@pExpirationDate datetime = NULL,
				@pMemberSinceDate datetime = NULL,
				@pClientMemberKey varchar(50) = NULL,
				@pClientMembershipKey varchar(50) = NULL,
				@pIsPrimary bit = NULL,
				@pIsActive bit = NULL,
				@pCreateBatchID	int = NULL,
				@pCreateDate datetime = NULL,
				@pCreateBy varchar(50) = NULL,
				@pModifyBatchID	int = NULL,
				@pModifyDate datetime = NULL,
				@pModifyBy varchar(50) = NULL,
				--^1
				@pAccountSource varchar(50) = NULL,
				@pClientVendorKey varchar(50) = NULL
			)
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT OFF

declare @MembershipID as int
declare @VendorID as int 
declare @intCaseCount as int

set @intCaseCount = 0

select @MembershipID = id from Membership where ClientMembershipKey = @pClientMembershipKey
select @VendorID = id from Vendor where ClientVendorKey = @pClientVendorKey

--Added to handle deletes for EFG and others.  If Isactive is set to 0 only set if no cases exist for member
IF ISNULL(@pIsActive,1) = 0
	BEGIN
		SELECT @intCaseCount = Count(*) FROM [Case] c
		join Member m on m.ID = c.MemberID 
		WHERE m.ClientMemberKey = @pClientMemberKey 
		
		--IF cases exists, do not set IsActive = 0
		if @intCaseCount > 0 
			set @pIsActive = 1
			
	END
ELSE
	SET	@pIsActive = 1

   MERGE [dbo].[Member] AS target
    USING (select 
				@MembershipID,
				@pProgramID,	
				@pPrefix,
				@pFirstName,
				@pMiddleName,
				@pLastName,
				@pSuffix,
				--@pEmail,
				@pEffectiveDate,
				@pExpirationDate,
				@pMemberSinceDate,
				@pClientMemberKey,
				@pIsPrimary,
				@pIsActive,
				@pCreateBatchID,
				@pCreateDate,
				@pCreateBy,
				@pModifyBatchID,
				@pModifyDate,
				@pModifyBy,
				--^1
				@pAccountSource,
				@VendorID,
				@pMemberNumber
			)
			as source( 
				[MembershipID],
				[ProgramID],	
				[Prefix],
				[FirstName],
				[MiddleName],
				[LastName],
				[Suffix],
				--[Email],
				[EffectiveDate],
				[ExpirationDate],
				[MemberSinceDate],
				[ClientMemberKey],
				[IsPrimary],
				[IsActive],
				[CreateBatchID],
				[CreateDate],
				[CreateBy],
				[ModifyBatchID],
				[ModifyDate],
				[ModifyBy],
				--^1
				[AccountSource],
				[SellerVendorID],
				[MemberNumber]
           )
    ON (target.ClientMemberKey = source.ClientMemberKey)
    
    WHEN MATCHED THEN 
        UPDATE SET 
				ProgramID = source.ProgramID,
				Prefix = source.Prefix,
				FirstName = source.FirstName,
				MiddleName = source.MiddleName,
				LastName = source.LastName,
				Suffix = source.Suffix,
				--Email = source.Email,
				EffectiveDate = source.EffectiveDate,
				ExpirationDate = source.ExpirationDate,
				MemberSinceDate = source.MemberSinceDate,
				IsPrimary = source.IsPrimary,
				ModifyBatchID = source.ModifyBatchid,
				ModifyDate = source.ModifyDate,
				ModifyBy = source.ModifyBy,
				--^1
				AccountSource = source.AccountSource,
				IsActive = source.IsActive
			
	WHEN NOT MATCHED THEN	
	    INSERT (
				[MembershipID],
				[ProgramID],	
				[Prefix],
				[FirstName],
				[MiddleName],
				[LastName],
				[Suffix],
				--[Email],
				[EffectiveDate],
				[ExpirationDate],
				[MemberSinceDate],
				[ClientMemberKey],
				[IsPrimary],
				[IsActive],
				[CreateBatchID],
				[CreateDate],
				[CreateBy],
				SourceSystemID,
				--^1
				AccountSource,
				SellerVendorID,
				MemberNumber
           )
	    VALUES (
				source.[MembershipID],
				source.[ProgramID],	
				source.[Prefix],
				source.[FirstName],
				source.[MiddleName],
				source.[LastName],
				source.[Suffix],
				--source.[Email],
				source.[EffectiveDate],
				source.[ExpirationDate],
				source.[MemberSinceDate],
				source.[ClientMemberKey],
				source.[IsPrimary],
				source.[IsActive],
				source.[CreateBatchID],
				source.[CreateDate],
				source.[CreateBy],
				2,
				--^1
				source.AccountSource,
				source.SellerVendorID,
				source.MemberNumber
           );
GO

