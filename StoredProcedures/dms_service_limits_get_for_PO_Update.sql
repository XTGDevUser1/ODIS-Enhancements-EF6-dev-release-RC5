IF EXISTS (SELECT * FROM dbo.sysobjects 
			WHERE id = object_id(N'[dbo].[dms_service_limits_get_for_PO_Update]')   		AND type in (N'P', N'PC')) 
BEGIN
	DROP PROCEDURE [dbo].[dms_service_limits_get_for_PO_Update] 
END 
GO
/****** Object:  StoredProcedure [dbo].[dms_service_limits_get_for_PO_Update]    Script Date: 03/31/2013 20:42:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [dbo].[dms_service_limits_get_for_PO_Update] @programID = 3,@vehicleCategoryID = 1, @purchaseOrderID = 276,@productID =141,@productRateID=1
 
 CREATE PROCEDURE [dbo].[dms_service_limits_get_for_PO_Update]( 
   @programID INT = NULL,
   @vehicleCategoryID INT = NULL,
   @purchaseOrderID INT = NULL, 
   @productID INT =NULL,
   @productRateID INT =NULL
 ) 
 AS 
 BEGIN 
 
 SET FMTONLY OFF
 Declare @update bit
 set @update=0;
 IF((select count(*) from RateType where Name in ('Base','Hourly') AND ID=@productRateID)>0 AND (select Count(*) from Product p
Inner join ProductSubType ps ON p.ProductSubTypeID=ps.ID
where ps.Name in('PrimaryService','SecondaryService')
AND p.ID=@productID)>0)
 BEGIN
 SET @update=1
 END
 SELECT @update as ProductChanged
 END
 
