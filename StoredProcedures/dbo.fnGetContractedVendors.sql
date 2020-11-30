IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnGetContractedVendors]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnGetContractedVendors]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO 
-- Select * From [dbo].[fnGetContractedVendors]() Where VendorID = 4360   
CREATE FUNCTION [dbo].[fnGetContractedVendors] ()  
RETURNS TABLE   
AS  
RETURN   
(  
 -- Contract must me active and within date range  
 -- Related Contract Rate Schedule must be active and within date range  
 SELECT   
  v.ID VendorID, v.VendorNumber, MAX(c.ID) ContractID, MAX(crs.ID) ContractRateScheduleID  
 FROM dbo.Vendor v  
 JOIN dbo.[Contract] c On c.VendorID = v.ID   
 JOIN dbo.[ContractRateSchedule] crs ON   
  crs.ContractID = c.ID AND   
  crs.ContractRateScheduleStatusID = (SELECT ID FROM ContractRateScheduleStatus WHERE Name = 'Active') AND  
  crs.StartDate <= GETDATE() AND  
  (crs.EndDate IS NULL OR crs.EndDate >= GETDATE())  
 JOIN dbo.[ContractRateScheduleProduct] crsp On crsp.ContractRateScheduleID = crs.ID   
 WHERE   
 v.IsActive = 1 --Vendor Not Deleted  
 AND v.VendorStatusID = (SELECT ID FROM VendorStatus WHERE Name = 'Active')  
 AND c.IsActive = 1 --Contract Not Deleted  
 AND c.ContractStatusID = (SELECT ID FROM ContractStatus WHERE Name = 'Active')  
 AND c.StartDate <= GETDATE()   
 AND (c.EndDate IS NULL OR c.EndDate >= GETDATE())  
 GROUP BY v.ID, v.VendorNumber  
)  