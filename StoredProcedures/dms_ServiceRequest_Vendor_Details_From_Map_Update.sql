IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ServiceRequest_Vendor_Details_From_Map_Update]')   		AND type in (N'P', N'PC')) 
 BEGIN
DROP PROCEDURE [dbo].[dms_ServiceRequest_Vendor_Details_From_Map_Update]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  
 -- EXEC [dms_ServiceRequest_Vendor_Details_From_Map_Update] 1414
CREATE PROCEDURE [dbo].[dms_ServiceRequest_Vendor_Details_From_Map_Update]  
 @serviceRequestID INT	= NULL 
AS  
BEGIN

	UPDATE	ServiceRequest
	SET		DealerIDNumber = VL.DealerNumber,
			PartsAndAccessoryCode = VL.PartsAndAccessoryCode,
			IsDirectTowDealer = CASE WHEN VLP.ID IS NULL THEN 0 ELSE 1 END
	FROM	ServiceRequest SR
	JOIN	VendorLocation VL ON SR.DestinationVendorLocationID = VL.ID
	LEFT JOIN	VendorLocationProduct VLP ON VLP.VendorLocationID = VL.ID AND VLP.ProductID = 
						(
							SELECT ID FROM Product WHERE Name = 'Ford Direct Tow' 
						)
	WHERE	SR.ID = @serviceRequestID
	


END
GO
