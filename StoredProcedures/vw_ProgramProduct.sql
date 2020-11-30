IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_ProgramProduct]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_ProgramProduct] 
 END 
 GO  
CREATE VIEW [dbo].[vw_ProgramProduct]
AS
Select TOP 2000000
p.ClientID
,cl.Name Client
,p.ID ProgramID
,p.Name Program
,p.ParentProgramID
,pprog.Name ParentProgram
,pp.ProductID
,pc.Name ProductCategory
,Prod.Name Product
,pp.ServiceCoverageDescription
,CASE WHEN IsServiceCoverageBestValue = 1 THEN 'Best Value' Else '$' + CONVERT(nvarchar(50), pp.ServiceCoverageLimit) END Coverage
,pp.IsMaterialsMemberPay
,CASE WHEN pp.IsServiceMileageUnlimited = 1 THEN 'Unlimited' Else CONVERT(nvarchar(50), pp.ServiceMileageLimit) + ' ' + pp.ServiceMileageLimitUOM END ServiceMileageLimit
,pp.IsServiceMileageOverageAllowed
,pp.IsReimbursementOnly
,pp.IsServiceGuaranteed
From ProgramProduct pp (NOLOCK)
Join Program p (NOLOCK) on p.ID = pp.ProgramID
Left Outer Join Program pprog (NOLOCK) on pprog.ID = p.ParentProgramID
Join Client cl (NOLOCK) on cl.ID = p.ClientID
Join Product prod (NOLOCK) on prod.ID = pp.ProductID
Join ProductCategory pc (NOLOCK) on pc.ID = prod.ProductCategoryID
Order by p.ParentProgramID, pp.ProgramID, prod.ProductCategoryID, prod.VehicleCategoryID, pp.ProductID
GO

