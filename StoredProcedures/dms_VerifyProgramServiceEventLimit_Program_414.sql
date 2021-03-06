IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_VerifyProgramServiceEventLimit_Program_414]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit_Program_414] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* Special service event limit logic for CNET Limited (program 414) */

CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit_Program_414]  
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
	--      @ServiceRequestID int = 16256913
	--      ,@ProgramID int = 414
	--      ,@ProductCategoryID int = 1
	--      ,@ProductID int = NULL
	--      ,@VehicleTypeID int = 2
	--      ,@VehicleCategoryID int = 2
	--      ,@SecondaryCategoryID INT = NULL

	SET NOCOUNT ON  
	SET FMTONLY OFF  

	DECLARE @MemberID INT
		,@Description nvarchar(255)
		,@MemberExpirationDate datetime
		,@MemberRenewalDate datetime
		,@IsEligible bit 
	
	DECLARE @MembershipMembers TABLE (MembershipID int, MemberID int, IsServiceRequestMember bit)
	DECLARE @ProductEvents TABLE (ProductCategoryID int, ProductID int, ProductCategoryName nvarchar(100), EventCount int, LastEventDate datetime)


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
	  
	If @ProductID IS NOT NULL
		SELECT @ProductCategoryID = ProductCategoryID
			  ,@VehicleCategoryID = VehicleCategoryID
			  ,@VehicleTypeID = VehicleTypeID
		FROM Product 
		WHERE ID = @ProductID

	----DEBUG
	--SELECT @ProductID
	--SELECT * From @MembershipMembers
	
	-- Counting EACH PO as an occurrence VS each SR
	INSERT INTO @ProductEvents (ProductCategoryID, ProductID, ProductCategoryName, EventCount, LastEventDate)
	SELECT 
		  --sr.ID ServiceRequestID
		  p.ProductCategoryID
		  ,p.ID ProductID
		  ,pc.Name ProductCategoryName
		  ,Count(*) EventCount
		  ,MAX(po.IssueDate) LastEventDate 
	From [Case] c
	Join ServiceRequest sr on c.ID = sr.CaseID
	Join PurchaseOrder po on sr.ID = po.ServiceRequestID and po.PurchaseOrderStatusID in (Select ID from PurchaseOrderStatus Where Name IN ('Issued', 'Issued-Paid')) and po.IsActive = 1
	Join Product p on po.ProductID = p.ID
	Join ProductCategory pc on pc.id = p.ProductCategoryID
	Join @MembershipMembers mm on mm.MemberID = c.MemberID
	Where 1=1
		  and sr.ID <> @ServiceRequestID
		  and po.IssueDate IS NOT NULL
		  and po.IssueDate > @MemberRenewalDate
	Group By 
		  --sr.ID
		  p.ProductCategoryID
		  ,p.ID
		  ,pc.Name

	----DEBUG
	--SELECT @MemberRenewalDate, * from #ProductEvents
	
	---RULE
	--Event Limit: 1 Tow and 1 Non-Tow Service
	SET @IsEligible = 1
	IF (@ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tow')  --Requested service is Tow
		AND EXISTS(SELECT * FROM @ProductEvents WHERE ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tow'))) --Has at least one prior Tow
		OR
		(@ProductCategoryID <> (SELECT ID FROM ProductCategory WHERE Name = 'Tow') --Requested service is Non-Tow
		AND EXISTS(SELECT * FROM @ProductEvents WHERE ProductCategoryID <> (SELECT ID FROM ProductCategory WHERE Name = 'Tow'))) --Has at least one prior Non-Tow
		SET @IsEligible = 0


	---- RESULT SET
	SELECT TOP 1
		ID 
		,@ProgramID
		,[Description] 
		,Limit
		,EventCount = ISNULL((Select SUM(EventCount) FROM @ProductEvents),0)
		,1 AS IsPrimary
		,@IsEligible
	FROM ProgramServiceEventLimit
	WHERE ProgramID = @ProgramID
	
END

