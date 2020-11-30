/****** Object:  StoredProcedure [dbo].[dms_VendorLocation_PaymentTypes]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_VendorLocation_PaymentTypes]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_VendorLocation_PaymentTypes]
GO

-- EXEC dms_VendorLocation_PaymentTypes 316, 'VendorLocation'
CREATE PROC [dbo].[dms_VendorLocation_PaymentTypes](
@vendorLocationID INT = NULL,
@EntityName nvarchar(50)=''
)  
AS
BEGIN
DECLARE @result AS TABLE(
[ProductID] INT NOT NULL,
[Description] NVARCHAR(50),
[IsSelected] BIT DEFAULT 0
)

INSERT INTO @result
SELECT PT.ID,
         PT.Description,
         CASE WHEN VLPT.ID IS NULL THEN 0 ELSE 1 END IsSelected
FROM PaymentType PT
JOIN PaymentTypeEntity pte ON pte.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') 
      AND pte.PaymentTypeID = pt.ID
LEFT JOIN VendorLocationPaymentType VLPT ON VLPT.PaymentTypeID = PT.ID 
AND VLPT.IsActive = 1 
AND	ISNULL(PTE.IsShownOnScreen,0) = 1
AND VLPT.VendorLocationID = @vendorLocationID

WHERE 
            PT.IsActive = 1
ORDER BY 
            PT.Sequence
            
SELECT * FROM @result
END


