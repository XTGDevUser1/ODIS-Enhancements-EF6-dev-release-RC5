IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_PO_MemberPayDispatchFee]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_PO_MemberPayDispatchFee] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 
--EXEC [dms_PO_MemberPayDispatchFee] 943, 100
--EXEC [dms_PO_MemberPayDispatchFee] 943, 100
CREATE PROCEDURE [dbo].[dms_PO_MemberPayDispatchFee]( 
  @poId INT = NULL 
, @purchaseOrderAmount money = 0  ---Value passed in to recalc dispatch fee upon changing PO line items (prior to PO save)
) 
AS 
BEGIN 
	DECLARE @internalDispatchFee money = 0, 
			@clientDispatchFee money = 0, 
			@creditCardProcessingFee money = 0, 
			@dispatchFee money = 0

	DECLARE @ServiceRequestID INT 
		,@ProgramID INT
		,@VehicleTypeID INT
		,@TotalServiceAmount money
		,@CoverageLimit money
		,@DealerIDNumber nvarchar(50)
		,@PartsAndAccessoryCode nvarchar(50)
		,@IsDirectTowDealer bit
		,@PrimaryProductID int
		
	SELECT 
		@ProgramID = C.ProgramID
		,@ServiceRequestID = SR.ID
		,@VehicleTypeID = c.VehicleTypeID
		,@TotalServiceAmount = po.TotalServiceAmount
		,@CoverageLimit = po.CoverageLimit
		,@DealerIDNumber = sr.DealerIDNumber
		,@PartsAndAccessoryCode = sr.PartsAndAccessoryCode
		,@IsDirectTowDealer = sr.IsDirectTowDealer
		,@PrimaryProductID = sr.PrimaryProductID
	FROM [Case] C with (nolock)
	JOIN ServiceRequest SR with (nolock) ON C.ID = SR.CaseID
	JOIN PurchaseOrder PO with (Nolock) ON PO.ServiceRequestID = SR.ID
	where PO.ID = @poId
	
	---- Added this logic to work around bug: Not re-setting coverage limit on SR when service changes 
	Select @CoverageLimit = ServiceCoverageLimit
	From ProgramProduct 
	Where ProgramID = @ProgramID and ProductID = @PrimaryProductID

	DECLARE @AutoVehicleTypeID INT = (SELECT ID FROM VehicleType WHERE Name = 'Auto')
	DECLARE @RVVehicleTypeID INT = (SELECT ID FROM VehicleType WHERE Name = 'RV')
	DECLARE @issuedPurchaseOrderStatusID INT = (SELECT ID FROM PurchaseOrderStatus where Name='Issued')


	/**** RV Share (Coach-net) **********************************************************/
	IF @ProgramID = (SELECT ID FROM Program where Name = 'RV Share')
		BEGIN
			DECLARE @RVShare_CostMarkUp money = 0.15
			
			SET @DispatchFee = ROUND(CASE WHEN @CoverageLimit = 0 THEN @purchaseOrderAmount * @RVShare_CostMarkUp ELSE 0.0 END, 2)
		END

	/**** Ford Direct Tow **********************************************************/
	IF @ProgramID = (SELECT ID FROM Program where Name = 'Ford Direct Tow')
		BEGIN
			DECLARE @FordDirectTow_DispatchFee money = 39.0
			
			--SET @dispatchFee = (CASE WHEN @DealerIDNumber IS NOT NULL AND @PartsAndAccessoryCode IS NOT NULL AND @IsDirectTowDealer = 1 THEN 0.0 ELSE @FordDirectTow_DispatchFee END)
			SET @dispatchFee = @FordDirectTow_DispatchFee
		END


	SELECT @internalDispatchFee AS InternalDispatchFee
		,@clientDispatchFee AS ClientDispatchFee
		,@creditCardProcessingFee AS CreditCardProcessingFee
		,@dispatchFee AS DispatchFee
		,CONVERT(nvarchar(100), @DispatchFee) AS StringDispatchFee
		,0 AS DispatchFeeAgentMinutes
		,0 AS DispatchFeeTechMinutes
		,0.00 AS DispatchFeeTimeCost

END
GO

