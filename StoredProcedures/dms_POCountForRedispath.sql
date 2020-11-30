
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_POCountForRedispath]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_POCountForRedispath] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_POCountForRedispath] 1196
 CREATE PROCEDURE [dbo].[dms_POCountForRedispath]
 (
 @ServiceRequestID int=null
 )
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

   Select COUNT(distinct VendorLocationID) AS POCOUNT from  PurchaseOrder where ServiceRequestID=@ServiceRequestID 
   and OriginalPurchaseOrderID IS NULL AND IsActive = 1


END
