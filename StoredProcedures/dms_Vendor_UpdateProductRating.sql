IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_UpdateProductRating]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_UpdateProductRating] 
 END 
 GO  
 SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_Vendor_UpdateProductRating]
AS
BEGIN

      /* Apply related service rating adjustment to contactlogs */
      UPDATE cl SET VendorServiceRatingAdjustment = ISPSelection.VendorServiceRatingAdjustment
      FROM ContactLog cl
      JOIN (
      SELECT 
            SR.ID ServiceRequestID
            ,SR.PrimaryProductID
            ,vl.ID VendorLocationID
            ,CL.ID ContactLogID
            ,ca.ID ContactActionID
            ,ca.VendorServiceRatingAdjustment
            ,ca.Name ContactActionName
      FROM dbo.ContactLog cl  
      JOIN dbo.ContactLogReason clr ON cl.ID = clr.ContactLogID
      JOIN dbo.ContactReason cr ON clr.ContactReasonID = cr.ID
      JOIN dbo.ContactLogLink SRcll ON SRcll.ContactLogID = cl.ID AND SRcll.EntityID = (SELECT ID FROM Entity WHERE Name  = 'ServiceRequest' )
      JOIN dbo.ServiceRequest sr ON sr.ID = SRcll.RecordID
      JOIN dbo.ContactLogLink ISPcll ON ISPcll.ContactLogID = cl.ID  AND ISPcll.EntityID = (SELECT ID FROM Entity WHERE Name  = 'VendorLocation' ) 
      JOIN dbo.VendorLocation vl ON vl.ID = ISPcll.RecordID
      JOIN dbo.Vendor v ON v.ID = vl.VendorID
      JOIN dbo.ContactLogAction cla ON cla.ContactLogID = CL.ID
      JOIN dbo.ContactAction ca ON ca.ID = cla.ContactActionID
      LEFT OUTER JOIN (
            SELECT ServiceRequestID, VendorLocationID, MIN(ID) PurchaseOrderID
            FROM PurchaseOrder 
            WHERE ISNULL(PurchaseOrderNumber, '') <> ''
            GROUP BY ServiceRequestID, VendorLocationID
            ) FirstPO ON FirstPO.ServiceRequestID = SRcll.RecordID AND FirstPO.VendorLocationID = vl.ID
      LEFT OUTER JOIN dbo.PurchaseOrder PO ON FirstPO.PurchaseOrderID = PO.ID AND FirstPO.VendorLocationID = vl.ID
      WHERE cl.VendorServiceRatingAdjustment IS NULL -- Contactlog has not been marked yet
      AND cr.Name = 'ISP Selection' 
      AND ca.VendorServiceRatingAdjustment IS NOT NULL -- ContactAction has an associated rating adjustment value
      AND SR.ServiceRequestStatusID IN (SELECT ID FROM ServiceRequestStatus WHERE Name IN ('Complete', 'Cancelled'))
      AND cl.DataTransferDate IS NULL -- Has not already been applied to vendor
      AND v.VendorStatusID <> (SELECT ID FROM VendorStatus WHERE Name = 'Temporary')
      AND ISNULL(v.VendorNumber,'') <> ''
      AND ISNULL(v.VendorNumber,'') NOT LIKE '9X%'
      GROUP BY
            SR.ID 
            ,SR.PrimaryProductID
            ,v.VendorNumber
            ,vl.ID 
            ,CL.ID 
            ,ca.ID 
            ,ca.VendorServiceRatingAdjustment
            ,ca.Name 
      ) ISPSelection ON ISPSelection.ContactLogID = cl.ID


      /* Update Vendor Location Product Rating */
      DECLARE @VendorProductRatingDefault INT

      SELECT @VendorProductRatingDefault = Value
      FROM ApplicationConfiguration
      WHERE Name = 'VendorProductRatingDefault'

      BEGIN TRY
            BEGIN TRANSACTION 

            SELECT 
                  cl.ID ContactLogID
                  ,vl.ID VendorLocationID
                  ,COALESCE(PO.ProductID, SR.PrimaryProductID) ProductID
                  ,cl.VendorServiceRatingAdjustment
            INTO #tmpRatingAdjustment
            FROM dbo.ContactLog cl  
            JOIN dbo.ContactLogLink SRcll ON SRcll.ContactLogID = cl.ID AND SRcll.EntityID = (SELECT ID FROM Entity WHERE Name  = 'ServiceRequest' )
            JOIN dbo.ServiceRequest sr ON sr.ID = SRcll.RecordID
            JOIN dbo.ContactLogLink ISPcll ON ISPcll.ContactLogID = cl.ID  AND ISPcll.EntityID = (SELECT ID FROM Entity WHERE Name  = 'VendorLocation' ) 
            JOIN dbo.VendorLocation vl ON vl.ID = ISPcll.RecordID
            JOIN dbo.Vendor v ON v.ID = vl.VendorID
            JOIN dbo.ContactLogAction cla ON cla.ContactLogID = CL.ID
            JOIN dbo.ContactAction ca ON ca.ID = cla.ContactActionID AND ca.VendorServiceRatingAdjustment IS NOT NULL
            LEFT OUTER JOIN (
                  SELECT ServiceRequestID, VendorLocationID, MIN(ID) PurchaseOrderID
                  FROM PurchaseOrder 
                  WHERE ISNULL(PurchaseOrderNumber, '') <> ''
                  GROUP BY ServiceRequestID, VendorLocationID
                  ) FirstPO ON FirstPO.ServiceRequestID = SRcll.RecordID AND FirstPO.VendorLocationID = vl.ID
            LEFT OUTER JOIN dbo.PurchaseOrder PO ON FirstPO.PurchaseOrderID = PO.ID AND FirstPO.VendorLocationID = vl.ID
            WHERE cl.VendorServiceRatingAdjustment IS NOT NULL
            AND cl.DataTransferDate IS NULL
            --AND PO.ID IS NOT NULL
            
            UPDATE vlp SET 
                  Rating = 
                        CASE 
                              WHEN ISNULL(vlp.Rating,@VendorProductRatingDefault) + RatingAdjustment.Total < 0 THEN 0
                              WHEN ISNULL(vlp.Rating,@VendorProductRatingDefault) + RatingAdjustment.Total > 100 THEN 100
                              ELSE ISNULL(vlp.Rating,@VendorProductRatingDefault) + RatingAdjustment.Total
                        END 
                  ,ModifyDate = GETDATE()
                  ,ModifyBy = 'system'
            FROM VendorLocationProduct vlp 
            JOIN (
                  SELECT VendorLocationID, ProductID, SUM(tmp.VendorServiceRatingAdjustment) Total
                  FROM #tmpRatingAdjustment tmp
                  GROUP BY VendorLocationID, ProductID
                  ) RatingAdjustment ON vlp.VendorLocationID = RatingAdjustment.VendorLocationID AND vlp.ProductID = RatingAdjustment.ProductID    

            /* Mark used contactlog entries */
            UPDATE cl SET
                  DataTransferDate = GETDATE()
                  ,ModifyDate = GETDATE()
                  ,ModifyBy = 'system'
            FROM #tmpRatingAdjustment tmp
            JOIN ContactLog cl ON tmp.ContactLogID = cl.ID 

            COMMIT TRANSACTION;
            
      END TRY
      BEGIN CATCH
            --SELECT
            --    ERROR_NUMBER() AS ErrorNumber
            --    ,ERROR_SEVERITY() AS ErrorSeverity
            --    ,ERROR_STATE() AS ErrorState
            --    ,ERROR_PROCEDURE() AS ErrorProcedure
            --    ,ERROR_LINE() AS ErrorLine
            --    ,ERROR_MESSAGE() AS ErrorMessage;
            IF @@TRANCOUNT > 0
                  ROLLBACK TRANSACTION;
      END CATCH

      
      DROP TABLE #tmpRatingAdjustment       
END 
