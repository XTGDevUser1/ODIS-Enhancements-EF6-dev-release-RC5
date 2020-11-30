IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_PurchaseOrder_IsNotInvoiceEligible]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_PurchaseOrder_IsNotInvoiceEligible] 
 END 
 GO  
 SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_PurchaseOrder_IsNotInvoiceEligible]
AS
BEGIN

      SET NOCOUNT ON
      
      UPDATE po SET isnotinvoiceeligible = 1
      FROM purchaseorder po
      WHERE ISNULL(po.isnotinvoiceeligible,0) <> 1
      AND NOT EXISTS (
            SELECT *
            FROM VendorInvoice vi
            WHERE vi.PurchaseOrderID = po.ID
            )
      AND DATEDIFF(dd, po.CreateDate, GetDate()) >= 90
      AND po.IsActive = 1

END