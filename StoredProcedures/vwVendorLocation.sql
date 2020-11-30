IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vwVendorLocation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vwVendorLocation] 
 END 
 GO  
CREATE VIEW [dbo].[vwVendorLocation]
AS
SELECT [ID]
      ,[VendorID]
      --,[VendorLocationTypeID]
      ,[Sequence]
      ,[Latitude]
      ,[Longitude]
      --,[GeographyLocation]
      --,[RadiusMiles]
      --,[DefaultLocationName]
      ,[Email]
      ,[BusinessHours]
      ,[DealerNumber]
      --,[IsCreditCardAccepted]
      --,[IsPersonalCheckAccepted]
      --,[IsCashOnly]
      ,[IsOpen24Hours]
      ,[IsActive]
      --,[Comment]
      --,[CreateBatchID]
      ,[CreateDate]
      ,[CreateBy]
      --,[ModifyBatchID]
      ,[ModifyDate]
      ,[ModifyBy]
  FROM [dbo].[VendorLocation]
GO

