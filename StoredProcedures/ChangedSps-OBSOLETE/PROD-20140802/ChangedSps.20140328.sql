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
 --EXEC dms_VerifyProgramServiceEventLimit 1278380, 3,1,null, null, null
CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit]
      @MemberID int
      ,@ProgramID int
      ,@ProductCategoryID int
      ,@ProductID int
      ,@VehicleTypeID int
      ,@VehicleCategoryID int
AS
BEGIN
      SET NOCOUNT ON  
SET FMTONLY OFF  
      --Declare
      --    @MemberID int
      --    ,@ProgramID int
      --    ,@ProductCategoryID int
      --    ,@ProductID int
      --    ,@VehicleTypeID int
      --    ,@VehicleCategoryID int
      --Set @MemberID = 1278380
      --Set @ProgramID = 3
      --Set @ProductCategoryID = 1

      If @ProgramID IS NULL
            SELECT @ProgramID = ProgramID FROM Member WHERE ID = @MemberID

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
                  ,c.MemberID
                  ,sr.ID ServiceRequestID
                  ,ppl.ProductCategoryID
                  ,ppl.ProductID
                  ,pc.Name ProductCategoryName
                  ,MIN(po.IssueDate) MinEventDate 
            From [Case] c
            Join ServiceRequest sr on c.ID = sr.CaseID
            Join PurchaseOrder po on sr.ID = po.ServiceRequestID and po.PurchaseOrderStatusID in (Select ID from PurchaseOrderStatus Where Name IN ('Issued', 'Issued-Paid'))
            Join Product p on po.ProductID = p.ID
            Join ProductCategory pc on pc.id = p.ProductCategoryID
            Join ProgramServiceEventLimit ppl on ppl.ProgramID = c.ProgramID 
                  and (ppl.ProductCategoryID IS NULL OR ppl.ProductCategoryID = pc.ID)
                  and (ppl.ProductID IS NULL OR ppl.ProductID = p.ID)
                  and ppl.IsActive = 1
                  and po.IssueDate > 
                        CASE WHEN ppl.LimitDurationUOM = 'Day' THEN DATEADD(dd,-ppl.LimitDuration, getdate())
                              WHEN ppl.LimitDurationUOM = 'Month' THEN DATEADD(mm,-ppl.LimitDuration, getdate())
                              WHEN ppl.LimitDurationUOM = 'Year' THEN DATEADD(yy,-ppl.LimitDuration, getdate())
                              ELSE NULL
                              END 
            Where 
                  c.MemberID = @MemberID
                  and c.ProgramID = @ProgramID
                  --and (pc.ID = @ProductCategoryID 
                  --    OR p.ID = @ProductID
                  --    OR p.ProductCategoryID = @ProductCategoryID)
                  and po.IssueDate IS NOT NULL
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
            psel.ProgramID
            ,psel.[Description]
            ,psel.Limit
            ,ISNULL(pec.EventCount, 0) EventCount
            ,CASE WHEN pec.EventCount < psel.Limit THEN 1 ELSE 0 END IsEligible
            --,CASE WHEN (psel.ProductCategoryID = @ProductCategoryID 
            --          OR psel.ProductID = @ProductID
            --          OR @ProductCategoryID = (SELECT ProductCategoryID FROM Product WHERE ID = psel.ProductID)
            --          OR psel.ProductCategoryID = (SELECT ProductCategoryID FROM Product WHERE ID = @ProductID)) THEN 1 ELSE 0 END
      From ProgramServiceEventLimit psel
      Left Outer Join #tmpProgramEventCount pec on pec.ProgramServiceEventLimitID = psel.ID
      Where
            (psel.ProductCategoryID = @ProductCategoryID 
            OR psel.ProductID = @ProductID
            OR @ProductCategoryID = (SELECT ProductCategoryID FROM Product WHERE ID = psel.ProductID)
            OR psel.ProductCategoryID = (SELECT ProductCategoryID FROM Product WHERE ID = @ProductID))

      Drop table #tmpProgramEventCount

END
GO



GO
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
 WHERE id = object_id(N'[dbo].[dms_VerifyServiceBenefit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyServiceBenefit] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_VerifyServiceBenefit 1, 1, 1, 1
CREATE PROCEDURE [dbo].[dms_VerifyServiceBenefit]
      @ProgramID INT
      ,@ProductCategoryID INT
      ,@VehicleCategoryID INT
      ,@VehicleTypeID INT = NULL
AS
BEGIN 
SET NOCOUNT ON  
SET FMTONLY OFF  
      --DECLARE @ProgramID INT
      --DECLARE @ProductCategoryID INT
      --DECLARE @VehicleCategoryID INT
      --DECLARE @VehicleTypeID INT
      --SET @ProgramID = 1
      --SET @ProductCategoryID = 1
      --SET @VehicleCategoryID = 2
      --SET @VehicleTypeID = 1

      SELECT pc.Name ProductCategoryName
            ,pc.ID ProductCategoryID
            ,ISNULL(vc.Name,'') VehicleCategoryName
            ,vc.ID VehicleCategoryID
            ,MAX(CAST(pp.IsServiceCoverageBestValue AS INT)) IsServiceCoverageBestValue
            ,MAX(pp.ServiceCoverageLimit) ServiceCoverageLimit
            --,MAX(pp.CurrencyTypeID) CurrencyTypeID
            ,MAX(pp.ServiceMileageLimit) ServiceMileageLimit
            --,MAX(pp.ServiceMileageLimitUOM) ServiceMileageLimitUOM
            ,MAX(CASE WHEN pp.ServiceCoverageLimit IS NULL THEN 0 
                          WHEN pp.ServiceCoverageLimit = 0 AND pp.IsReimbersementOnly = 1 THEN 1 
                          WHEN pp.IsServiceCoverageBestValue = 1 THEN 1
                          WHEN pp.ServiceCoverageLimit > 0 THEN 1
                          ELSE 0 END) IsServiceEligible
      FROM  ProductCategory pc (NOLOCK) 
      JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID 
                        AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')
                        AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')
      LEFT OUTER JOIN   VehicleCategory vc on vc.id = p.VehicleCategoryID
      LEFT OUTER JOIN   ProgramProduct pp on p.id = pp.productid
      WHERE pp.ProgramID = @ProgramID
      AND         pc.ID = @ProductCategoryID
      AND         (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)
      AND         (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)
      GROUP BY 
            pc.Name     
            ,pc.ID 
            ,vc.Name
            ,vc.ID

END

GO
