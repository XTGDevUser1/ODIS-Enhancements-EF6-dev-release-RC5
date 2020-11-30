IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MemberProduct_InsertUpdate]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[MemberProduct_InsertUpdate]
GO

CREATE PROCEDURE [dbo].[MemberProduct_InsertUpdate]
			(
				@pMemberID int=NULL,
				@pProductID Int = NULL,
				@pProductProviderID int =NULL,
				@pStartDate datetime = NULL,
				@pEndDate datetime =NULL,
				@pContractNumber nvarchar(50) = NULL,
				@pVIN nvarchar(50) =NULL,
				@pCreateBy varchar(50) = NULL,
				@pCreateDate	datetime = NULL,
				@pModifyDate datetime = NULL,
				@pModifyBy varchar(50) = NULL,
				@pClientMembershipKey varchar(50) = NULL,
				@pClientMemberKey varchar(50) = NULL,
				@pCreateBatchID int = NULL,
				@pModifyBatchID int = NULL
				
			)
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT OFF

declare @MembershipID as int

select @MembershipID = id from Membership where ClientMembershipKey = @pClientMembershipKey

   MERGE [dbo].[MemberProduct] AS target
    USING (select 
				@pMemberID ,
				@MembershipID ,
				@pProductID ,
				@pProductProviderID ,
				@pStartDate ,
				@pEndDate ,
				@pContractNumber ,
				@pVIN ,
				@pCreateBy ,
				@pCreateDate,
				@pModifyDate ,
				@pModifyBy
			)
			as source( 
				[MemberID],
				[MembershipID],
				[ProductID],
				[ProductProviderID],
				[StartDate],
				[EndDate],
				[ContractNumber],
				[VIN],
				[CreateBy],
				[CreateDate],
				[ModifyDate],
				[ModifyBy]
           )
    ON (target.[MembershipID] = source.[MembershipID] and target.[ProductID] = source.[ProductID] and isnull(target.[VIN],'') = isnull(source.[VIN],''))
    
    WHEN MATCHED THEN 
        UPDATE SET 
				[MemberID] = source.[MemberID],
				[MembershipID] = source.[MembershipID],
				[ProductID] = source.[ProductID],
				[ProductProviderID] = source.[ProductProviderID],
				[StartDate] = source.[StartDate],
				[EndDate] = source.[EndDate],
				[ContractNumber] = source.[ContractNumber],
				[VIN] = source.[VIN],
				[ModifyDate] = source.[ModifyDate],
				[ModifyBy] = source.[ModifyBy]
				
	WHEN NOT MATCHED THEN	
	    INSERT (
				[MemberID],
				[MembershipID],
				[ProductID],
				[ProductProviderID],
				[StartDate],
				[EndDate],
				[ContractNumber],
				[VIN],
				[CreateBy],
				[CreateDate],
				[ModifyDate],
				[ModifyBy]
								
           )
	    VALUES (
				 source.[MemberID],
				 source.[MembershipID],
			     source.[ProductID],
				 source.[ProductProviderID],
				 source.[StartDate],
				 source.[EndDate],
				 source.[ContractNumber],
			     source.[VIN],
				 source.[CreateBy],
				 source.[CreateDate],
				 source.[ModifyDate],
				 source.[ModifyBy]  );
GO

