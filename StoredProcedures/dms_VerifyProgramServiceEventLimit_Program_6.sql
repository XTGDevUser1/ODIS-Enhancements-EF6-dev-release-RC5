IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_VerifyProgramServiceEventLimit_Program_6]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit_Program_6] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* Custom service event limit logic for Pinnacle (program ID 6) */

CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit_Program_6]  
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
	--      @ServiceRequestID int = 124110
	--      ,@ProgramID int = 6
	--      ,@ProductCategoryID int = 1
	--      ,@ProductID int = NULL
	--      ,@VehicleTypeID int = 1
	--      ,@VehicleCategoryID int = 1
	--      ,@SecondaryCategoryID INT = NULL

	SET NOCOUNT ON  
	SET FMTONLY OFF  

	DECLARE @MemberID INT
		,@Description nvarchar(255)
		,@MemberExpirationDate datetime
		,@MemberRenewalDate datetime
		,@IsEligible bit 
		,@EventLimit int
	
	DECLARE @MembershipMembers TABLE (MembershipID int, MemberID int, IsServiceRequestMember bit)
	DECLARE @ServiceEvents TABLE (ServiceRequestID int, EventDate datetime)

	SELECT @MemberID = m.ID
	  ,@MemberExpirationDate = m.ExpirationDate
	  ,@ProgramID = CASE WHEN @ProgramID IS NULL THEN m.ProgramID ELSE  @ProgramID END
	FROM ServiceRequest SR 
	JOIN [Case] c on c.id = SR.CaseID
	JOIN Member m on m.ID = c.MemberID
	WHERE SR.ID = @ServiceRequestID
	
	-- Determine last annual renewal date 
	SET @MemberRenewalDate = DATEADD(yy, (ROUND(DATEDIFF(dd, getdate(), @MemberExpirationDate)/365.00,0,1) + 1)*-1, @MemberExpirationDate)
	
	INSERT INTO @MembershipMembers (MembershipID, MemberID, IsServiceRequestMember)
	SELECT m.MembershipID, m.ID MemberID, CASE WHEN m.ID = @MemberID THEN 1 ELSE 0 END IsServiceRequestMember
	FROM Member m
	WHERE m.MembershipID = (
		SELECT ms.ID 
		FROM Membership ms
		JOIN Member m ON m.MembershipID = ms.ID
		WHERE m.ID = @MemberID)
	AND m.ProgramID = @ProgramID -- Insure that the member on the membership has the same program as the SR member
	
	SET @EventLimit = (SELECT CASE (SELECT COUNT(*) FROM @MembershipMembers)
		WHEN 1 THEN 5
		WHEN 2 THEN 8
		ELSE 10 END)
	  
	If @ProductID IS NOT NULL
		SELECT @ProductCategoryID = ProductCategoryID
			  ,@VehicleCategoryID = VehicleCategoryID
			  ,@VehicleTypeID = VehicleTypeID
		FROM Product 
		WHERE ID = @ProductID

	----DEBUG
	--SELECT @ProductID
	--SELECT * From @MembershipMembers
	
	-- Counting EACH SR with at least 1 issued PO; Could be more than one PO, but still counted as just 1 event
	INSERT INTO @ServiceEvents (ServiceRequestID, EventDate)
	SELECT 
		  sr.ID ServiceRequestID
		  ,sr.CreateDate
	From [Case] c
	Join ServiceRequest sr on c.ID = sr.CaseID
	Join @MembershipMembers mm on mm.MemberID = c.MemberID
	Where 1=1
		  and sr.ID <> @ServiceRequestID
		  and EXISTS (
			SELECT *
			FROM PurchaseOrder po 
			WHERE sr.ID = po.ServiceRequestID and 
				po.PurchaseOrderStatusID in (Select ID from PurchaseOrderStatus Where Name IN ('Issued', 'Issued-Paid')) and 
				po.IsActive = 1 and
				po.IssueDate IS NOT NULL and
				po.IssueDate > @MemberRenewalDate)

	--DEBUG
	--SELECT @MemberRenewalDate, * from @ServiceEvents
	
	---RULE
	--Event Limit: 5/8/10 Service Events (SRs with 1 or more issued POs) 
	SET @IsEligible = 1
	IF (SELECT COUNT(*) FROM @ServiceEvents) >= @EventLimit
		SET @IsEligible = 0


	---- RESULT SET
	SELECT TOP 1
		ID 
		,@ProgramID
		,[Description] 
		,@EventLimit
		,EventCount = ISNULL((Select COUNT(*) FROM @ServiceEvents),0)
		,1 AS IsPrimary
		,@IsEligible
	FROM ProgramServiceEventLimit
	WHERE ProgramID = @ProgramID
	
END

