IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_IsPreferredVendorsByProduct]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_IsPreferredVendorsByProduct] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 	

CREATE PROC dms_IsPreferredVendorsByProduct(@VendorID INT = NULL,@ProductID INT  =  NULL)
AS
BEGIN

	DECLARE @IsPreferred AS BIT
	SET @IsPreferred = ISNULL((SELECT 1 From [dbo].[fnGetPreferredVendorsByProduct]() Where VendorID = @VendorID AND ProductID = @ProductID),0) 
	
	DECLARE  @Result AS TABLE(IsPreferred BIT NOT NULL)
	INSERT INTO @Result VALUES(@IsPreferred)
	SELECT * FROM @Result

END
