/*******************
* Operator Enums 
*  Conditions Enum :
* -1 - No filter
*  0 - Null
*  1 - Not Null
*  2 - Equals
*  3 - NotEquals
*  ---- for strings ---
*  4 - StartsWith
*  5 - EndsWith
*  6 - Contains
*  ---- for int, decimal, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_VerifyProgramServiceEventLimit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

 --EXEC dms_VerifyProgramServiceEventLimit 664653, 458,1,null, null, null  
CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit]  
      @ServiceRequestID int
      ,@ProgramID int
      ,@ProductCategoryID int
      ,@ProductID int 
      ,@VehicleTypeID int
      ,@VehicleCategoryID int 
      ,@SecondaryCategoryID INT = NULL
AS
BEGIN

	----Debug
	--DECLARE 
	--      @ServiceRequestID int = 581157
	--      ,@ProgramID int = 450
	--      ,@ProductCategoryID int = 1
	--      ,@ProductID int = NULL
	--      ,@VehicleTypeID int = 1
	--      ,@VehicleCategoryID int = 1
	--      ,@SecondaryCategoryID INT = 1

	SET NOCOUNT ON  
	SET FMTONLY OFF  

	DECLARE @MemberID INT
		,@ProgramServiceEventLimitID int
		,@ProgramServiceEventLimitStoredProcedureName nvarchar(255)
		,@ProgramServiceEventLimitDescription nvarchar(255)
		,@MemberEffectiveDate datetime
		,@MemberExpirationDate datetime
		,@MemberRenewalDate datetime
		,@MembershipID INT
		,@countEventsByMemberOnly BIT = 0

	SELECT	@MemberID = m.ID
			,@MembershipID = m.MembershipID
			,@MemberEffectiveDate = m.EffectiveDate
			,@MemberExpirationDate = m.ExpirationDate
			,@ProgramID = CASE WHEN @ProgramID IS NULL THEN m.ProgramID ELSE  @ProgramID END
	FROM ServiceRequest SR 
	JOIN [Case] c on c.id = SR.CaseID
	JOIN Member m on m.ID = c.MemberID
	WHERE SR.ID = @ServiceRequestID
	
	-- Determine last annual renewal date 
	SET @MemberRenewalDate = DATEADD(yy, (ROUND(DATEDIFF(dd, getdate(), @MemberExpirationDate)/365.00,0,1) + 1)*-1, @MemberExpirationDate)
	-- TFS : 1609
	IF ((SELECT COUNT(*) 
		FROM [dbo].[fnc_GetProgramConfigurationForProgram](@ProgramID,'Service') PCP
		JOIN ProgramConfiguration PC ON PC.ID = PCP.ProgramConfigurationID
		WHERE	PC.Name = 'CountEventsByMemberOnly'
		AND		PC.Value = 'Yes') > 0)
	BEGIN
		SET @countEventsByMemberOnly = 1
	END

	-- Original effective date may not be exactly one year from Expiration Date
	-- Adjust to original effective date if it is within a 30 days of the expected coverage begin date
	IF DATEDIFF(dd, @MemberEffectiveDate, @MemberRenewalDate) <= 30
		SET @MemberRenewalDate = @MemberEffectiveDate
	  
	If @ProductID IS NOT NULL
		SELECT @ProductCategoryID = ProductCategoryID
			  ,@VehicleCategoryID = VehicleCategoryID
			  ,@VehicleTypeID = VehicleTypeID
		FROM Product 
		WHERE ID = @ProductID

	-- Check for a custom stored procedure that verifies the event limits for this program
	SELECT TOP 1 
		@ProgramServiceEventLimitID = ID
		,@ProgramServiceEventLimitStoredProcedureName = StoredProcedureName
		,@ProgramServiceEventLimitDescription = [Description]
	FROM ProgramServiceEventLimit
	WHERE ProgramID = @ProgramID
	AND StoredProcedureName IS NOT NULL
	AND IsActive = 1
	
	
	IF @ProgramServiceEventLimitStoredProcedureName IS NOT NULL
		-- Custome stored procedure used to verify the event limits for the program
		BEGIN
		
		DECLARE @LimitEligibilityResults TABLE (
			ID int
			,ProgramID int
			,[Description] nvarchar(255)
			,Limit int
			,EventCount int
			,IsPrimary int
			,IsEligible int)
		
		INSERT INTO @LimitEligibilityResults	
		EXECUTE @ProgramServiceEventLimitStoredProcedureName 
		   @ServiceRequestID
		  ,@ProgramID
		  ,@ProductCategoryID
		  ,@ProductID
		  ,@VehicleTypeID
		  ,@VehicleCategoryID
		  ,@SecondaryCategoryID

		SELECT 
			@ProgramServiceEventLimitID ID
			,@ProgramID ProgramID
			,@ProgramServiceEventLimitDescription [Description]
			,Limit
			,EventCount
			,IsPrimary
			,IsEligible
		FROM @LimitEligibilityResults
			
		END
	
	ELSE		
		-- Event limits are configured for specific program products
		BEGIN
		Select 
				ServiceRequestEvent.ProgramServiceEventLimitID
				,ServiceRequestEvent.ProgramEventLimitDescription
				,ServiceRequestEvent.ProgramEventLimit
				,ServiceRequestEvent.ProgramID
				,ServiceRequestEvent.MemberID
				,ServiceRequestEvent.ProductCategoryID
				,ServiceRequestEvent.ProductID
				,MIN(MinEventDate) MinEventDate
				,count(*) EventCount
			Into #tmpProgramEventCount
			From (
				Select 
					  ppl.ID ProgramServiceEventLimitID
					  ,ppl.[Description] ProgramEventLimitDescription
					  ,ppl.Limit ProgramEventLimit
					  ,c.ProgramID 
					  ,CASE WHEN @countEventsByMemberOnly =1 THEN c.MemberID ELSE 0 END AS MemberID-- TFS 1609
					  ,sr.ID ServiceRequestID
					  ,ppl.ProductCategoryID
					  ,ppl.ProductID
					  ,pc.Name ProductCategoryName
					  ,MIN(po.IssueDate) MinEventDate 
				From [Case] c
				JOIN Member M ON C.MemberID = M.ID	
				Join ServiceRequest sr on c.ID = sr.CaseID
				Join PurchaseOrder po on sr.ID = po.ServiceRequestID and po.PurchaseOrderStatusID in (Select ID from PurchaseOrderStatus Where Name IN ('Issued', 'Issued-Paid')) and po.IsActive = 1
				Join Product p on po.ProductID = p.ID
				Join ProductCategory pc on pc.id = p.ProductCategoryID
				Join ProgramServiceEventLimit ppl on ppl.ProgramID = c.ProgramID 
					  and (ppl.ProductCategoryID IS NULL OR ppl.ProductCategoryID = pc.ID)
					  and (ppl.ProductID IS NULL OR ppl.ProductID = p.ID)
					  and ppl.IsActive = 1
					  and po.IssueDate > 
							CASE WHEN ppl.IsLimitDurationSinceMemberRenewal = 1
									AND @MemberRenewalDate > (
										CASE WHEN ppl.LimitDurationUOM = 'Day' THEN DATEADD(dd,-ppl.LimitDuration, getdate())
											 WHEN ppl.LimitDurationUOM = 'Month' THEN DATEADD(mm,-ppl.LimitDuration, getdate())
											 WHEN ppl.LimitDurationUOM = 'Year' THEN DATEADD(yy,-ppl.LimitDuration, getdate())
											 ELSE NULL
											 END
										) THEN @MemberRenewalDate
  								 WHEN ppl.LimitDurationUOM = 'Day' THEN DATEADD(dd,-ppl.LimitDuration, getdate())
								 WHEN ppl.LimitDurationUOM = 'Month' THEN DATEADD(mm,-ppl.LimitDuration, getdate())
								 WHEN ppl.LimitDurationUOM = 'Year' THEN DATEADD(yy,-ppl.LimitDuration, getdate())
								 ELSE NULL
							END 
				Where 
						-- TFS : 1609
					  ( (@countEventsByMemberOnly =1 AND c.MemberID = @MemberID)
						OR
						(@countEventsByMemberOnly = 0 AND M.MembershipID = @MembershipID)
					  )
					  --c.MemberID = @MemberID -- TFS : 1609
					  and c.ProgramID = @ProgramID
					  and po.IssueDate IS NOT NULL
					  and sr.ID <> @ServiceRequestID
				Group By 
					  ppl.ID
					  ,ppl.[Description]
					  ,ppl.Limit
					  ,c.programid
					  ,c.MemberID
					  ,sr.ID
					  ,ppl.ProductCategoryID
					  ,ppl.ProductID
					  ,pc.Name
				) ServiceRequestEvent
			Group By 
				ServiceRequestEvent.ProgramServiceEventLimitID
				,ServiceRequestEvent.ProgramEventLimit
				,ServiceRequestEvent.ProgramEventLimitDescription
				,ServiceRequestEvent.ProgramID
				,ServiceRequestEvent.MemberID
				,ServiceRequestEvent.ProductCategoryID
				,ServiceRequestEvent.ProductID


			Select 
				psel.ID --ProgramServiceEventLimitID
				,psel.ProgramID
				,psel.[Description]
				,psel.Limit
				,ISNULL(pec.EventCount, 0) EventCount
				,CASE WHEN psel.ProductCategoryID = @SecondaryCategoryID AND @ProductCategoryID <> @SecondaryCategoryID THEN 0 ELSE 1 END IsPrimary
				,CASE WHEN ISNULL(pec.EventCount, 0) < psel.Limit THEN 1 ELSE 0 END IsEligible
			From ProgramServiceEventLimit psel
			Left Outer Join #tmpProgramEventCount pec on pec.ProgramServiceEventLimitID = psel.ID
			Where psel.IsActive = 1
			AND psel.ProgramID = @ProgramID
			AND   (
					  (@ProductID IS NOT NULL 
							AND psel.ProductID = @ProductID)
					  OR
					  ((@ProductID IS NULL OR psel.ProductID IS NULL)
							AND (psel.ProductCategoryID = @ProductCategoryID OR psel.ProductCategoryID IS NULL) 
							AND (@VehicleCategoryID IS NULL OR psel.VehicleCategoryID IS NULL OR psel.VehicleCategoryID = @VehicleCategoryID)
							AND (@VehicleTypeID IS NULL OR psel.VehicleTypeID IS NULL OR psel.VehicleTypeID = @VehicleTypeID)
					  )
					  OR
					  (psel.ProductCategoryID = @SecondaryCategoryID AND @ProductCategoryID <> @SecondaryCategoryID
							AND (@VehicleCategoryID IS NULL OR psel.VehicleCategoryID IS NULL OR psel.VehicleCategoryID = @VehicleCategoryID)
							AND (@VehicleTypeID IS NULL OR psel.VehicleTypeID IS NULL OR psel.VehicleTypeID = @VehicleTypeID)
					  ))
			ORDER BY 
				(CASE WHEN ISNULL(pec.EventCount, 0) < psel.Limit THEN 1 ELSE 0 END) ASC
				,(CASE WHEN psel.ProductCategoryID = @SecondaryCategoryID THEN 0 ELSE 1 END) DESC
				,psel.ProductID DESC

			Drop table #tmpProgramEventCount
		END
END
