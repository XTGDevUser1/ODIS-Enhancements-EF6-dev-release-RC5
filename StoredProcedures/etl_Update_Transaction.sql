IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[etl_Update_Transaction]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[etl_Update_Transaction]
GO

CREATE PROCEDURE [dbo].[etl_Update_Transaction] 
	@BatchID int
AS
BEGIN

	/** TO DO - Need add ProgramID or ClientID to Membership table and use in joins; **/
	/** Can not depend on ClientMemberhipKey being unique across clients **/
	/** TO DO - Need logic to guard against inserting multiple addresses for Memberships where there is more than one primary **/

	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION	
		
		DECLARE @ProcessDate datetime
		SET @ProcessDate = GETDATE()

		UPDATE ServiceRequest
			SET 
			LegacyReferenceNumber = CAST(staging.POPONOI5 AS nvarchar(50))
				,DataTransferDate = @ProcessDate
		FROM dbo.etl_Staging_CFDSPO staging
		JOIN dbo.ServiceRequest ServiceRequest
			ON staging.POSRNBR = ServiceRequest.ID
		WHERE staging.BatchID = @BatchID
		AND staging.PODSCOMPLT = 'Y'
		AND staging.ProcessFlag = 'Y'
		AND ISNULL(staging.PODSPPONBR,0) = 0
		AND ServiceRequest.DataTransferDate IS NULL

		UPDATE Member
			SET ClientMemberKey = staging.POID + RIGHT('000' + CONVERT(nvarchar(3), ISNULL(staging.POIDSEQ, 0)),3) 
		FROM dbo.etl_Staging_CFDSPO staging
		JOIN dbo.ServiceRequest ServiceRequest
			ON staging.POSRNBR = ServiceRequest.ID
		JOIN dbo.[Case] [Case] 
			ON ServiceRequest.CaseID = [Case].ID
		JOIN dbo.Member Member
			ON [Case].MemberID = Member.ID
		WHERE staging.BatchID = @BatchID
		AND staging.PODSCOMPLT = 'Y'
		AND staging.ProcessFlag = 'Y'
		AND ISNULL(Member.ClientMemberKey, '') = ''
		AND ISNULL(Staging.POID,'') <> ''

		UPDATE Membership
			SET ClientMembershipKey = staging.POID 
		FROM dbo.etl_Staging_CFDSPO staging
		JOIN dbo.ServiceRequest ServiceRequest
			ON staging.POSRNBR = ServiceRequest.ID
		JOIN dbo.[Case] [Case] 
			ON ServiceRequest.CaseID = [Case].ID
		JOIN dbo.Member Member
			ON [Case].MemberID = Member.ID
		JOIN dbo.Membership Membership
			ON Member.MembershipID = Membership.ID
		WHERE staging.BatchID = @BatchID
		AND staging.PODSCOMPLT = 'Y'
		AND staging.ProcessFlag = 'Y'
		AND ISNULL(Membership.ClientMembershipKey, '') = ''
		AND ISNULL(Staging.POID,'') <> ''

		UPDATE PurchaseOrder
			SET 
			LegacyReferenceNumber = CAST(staging.POPONOI5 AS nvarchar(50))
				,DataTransferDate = @ProcessDate
		FROM dbo.etl_Staging_CFDSPO staging
		JOIN dbo.PurchaseOrder PurchaseOrder
			ON staging.PODSPPONBR = PurchaseOrder.PurchaseOrderNumber
		WHERE staging.BatchID = @BatchID
		AND staging.PODSCOMPLT = 'Y'
		AND staging.ProcessFlag = 'Y'
		AND ISNULL(Staging.PODSPPONBR,0) <> 0
		AND PurchaseOrder.DataTransferDate IS NULL
		
		UPDATE Vendor
			SET VendorNumber = staging.POVEND
		FROM dbo.etl_Staging_CFDSPO staging
		JOIN dbo.PurchaseOrder PurchaseOrder
			ON staging.PODSPPONBR = PurchaseOrder.PurchaseOrderNumber
		JOIN dbo.VendorLocation VendorLocation
			ON PurchaseOrder.VendorLocationID = VendorLocation.ID
		JOIN dbo.Vendor Vendor
			ON VendorLocation.VendorID = Vendor.ID
		WHERE staging.BatchID = @BatchID
		AND staging.PODSCOMPLT = 'Y'
		AND staging.ProcessFlag = 'Y'
		AND ISNULL(Vendor.VendorNumber,'') = ''
		AND ISNULL(staging.POVEND,'') <> ''
		
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

