
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetVendorLocationProduct_ContactLog]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_GetVendorLocationProduct_ContactLog]
GO



/****** Object:  UserDefinedFunction [dbo].[fnc_GetVendorLocationProduct_ContactLog]    Script Date: 08/26/2013 10:58:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Select * From [dbo].[fnc_GetVendorLocationProduct_ContactLog]()
CREATE FUNCTION [dbo].[fnc_GetVendorLocationProduct_ContactLog] ()
RETURNS TABLE 
AS
RETURN 
(
      Select 
            v.ID VendorID
            ,vl.ID VendorLocationID
            ,sr.ID ServiceRequestID
            ,COALESCE(PO.ProductID, SR.PrimaryProductID) ProductID
            ,po.ID PurchaseOrderID
            ,po.PurchaseOrderNumber
            ,ca.Name ContactAction
            ,cl.VendorServiceRatingAdjustment
            ,cl.TalkedTo
            ,cl.CreateDate
            ,cl.DataTransferDate
            ,cl.ID AS ContactLogID
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
      --WHERE cl.VendorServiceRatingAdjustment IS NOT NULL
      --AND cl.DataTransferDate IS NOT NULL
) 
GO