IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Insurance_Expiry_ContactLog_Check]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Insurance_Expiry_ContactLog_Check] 
 END 
 GO  

 IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnCheckVendorInsuranceExpiryContactLog]') 
AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
 DROP FUNCTION [dbo].[fnCheckVendorInsuranceExpiryContactLog]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--SELECT [dbo].[fnCheckVendorInsuranceExpiryContactLog](316)
 CREATE FUNCTION [dbo].[fnCheckVendorInsuranceExpiryContactLog] 
 (
	@vendorID INT
 )
 RETURNS BIT
 AS
 BEGIN

	DECLARE @vendorEntityID INT = NULL,		
			@clCreateDate DATETIME = NULL

	SELECT @vendorEntityID = ID FROM Entity WHERE Name = 'Vendor'


	;WITH wCL
	AS
	(
		SELECT  TOP 1 CL.CreateDate
		FROM	ContactLog CL WITH (NOLOCK)
		JOIN	ContactLogReason CLR WITH (NOLOCK) ON CLR.ContactLogID = CL.ID
		JOIN	ContactReason CR WITH (NOLOCK) ON CLR.ContactReasonID = CR.ID
		JOIN	ContactLogLink CLL WITH (NOLOCK) ON CLL.ContactLogID = CL.ID AND CLL.EntityID = @vendorEntityID AND CLL.RecordID = @vendorID
		WHERE	CR.Name = 'VendorInsurance'
		ORDER BY CL.CreateDate DESC
	)

	SELECT	@clCreateDate = W.CreateDate
	FROM	wCL W
	
	RETURN	CASE WHEN @clCreateDate IS NULL OR DATEDIFF(HH, @clCreateDate, GETDATE()) > 12 THEN CAST (1 AS BIT)
			ELSE CAST(0 AS BIT) 
			END
 END
