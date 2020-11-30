
/****** Object:  UserDefinedFunction [dbo].[fnc_GetVendorIndicators]    Script Date: 08/26/2013 10:47:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetVendorIndicators]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_GetVendorIndicators]
GO



/****** Object:  UserDefinedFunction [dbo].[fnc_GetVendorIndicators]    Script Date: 08/26/2013 10:47:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
-- SELECT * FROM [dbo].[fnc_GetVendorIndicators] ('Vendor')
-- SELECT * FROM [dbo].[fnc_GetVendorIndicators] ('VendorLocation')


CREATE FUNCTION [dbo].[fnc_GetVendorIndicators] (@entityName nvarchar(255))  
RETURNS @tblIndicators TABLE ( RecordID INT, Indicators NVARCHAR(MAX) )
AS  
BEGIN

	IF @entityName = 'Vendor'
	BEGIN

		INSERT INTO @tblIndicators (RecordID, Indicators) 
		SELECT	v.ID VendorID			  
				,CASE WHEN SUM(CASE WHEN vlp_P.ID IS NOT NULL  
									  THEN 1 ELSE 0 END) > 0 THEN ' (P)' ELSE '' END 
				+ CASE WHEN SUM(CASE WHEN vlp_DT.ID IS NOT NULL AND vl.DealerNumber IS NOT NULL AND vl.PartsAndAccessoryCode IS NOT NULL 
									  THEN 1 ELSE 0 END) > 0 THEN ' (DT)' ELSE '' END Indicators
		FROM	dbo.Vendor v WITH (NOLOCK)   
		JOIN	dbo.VendorLocation vl WITH (NOLOCK) ON vl.VendorID = v.ID AND vl.IsActive = 1 AND vl.VendorLocationStatusID = (SELECT ID FROM VendorLocationStatus WHERE Name = 'Active')
		LEFT OUTER JOIN VendorLocationProduct vlp_DT WITH (NOLOCK) ON vlp_DT.VendorLocationID = vl.ID AND vlp_DT.ProductID = (SELECT ID from Product where Name = 'Ford Direct Tow') AND vlp_DT.IsActive = 1
		LEFT OUTER JOIN VendorLocationProduct vlp_P WITH (NOLOCK) ON vlp_P.VendorLocationID = vl.ID AND vlp_P.ProductID = (SELECT ID from Product where Name = 'CoachNet Dealer Partner') AND vlp_P.IsActive = 1
		WHERE 
			  (vlp_DT.ID IS NOT NULL 
			  AND vl.DealerNumber IS NOT NULL 
			  AND vl.PartsAndAccessoryCode IS NOT NULL)
			  OR
			  (vlp_P.ID IS NOT NULL)
		GROUP BY v.VendorNumber, 
			  v.ID
			  ,v.Name
		
	END
	ELSE IF @entityName = 'VendorLocation'
	BEGIN

		INSERT INTO @tblIndicators (RecordID, Indicators) 
		SELECT	DISTINCT vl.ID VendorLocationID
				,CASE WHEN vlp_P.ID IS NOT NULL 
										THEN ' (P)' ELSE '' END 
				+ CASE WHEN vlp_DT.ID IS NOT NULL AND vl.DealerNumber IS NOT NULL AND vl.PartsAndAccessoryCode IS NOT NULL 
										THEN ' (DT)' ELSE '' END Indicators
		FROM	dbo.VendorLocation vl WITH (NOLOCK)
		LEFT OUTER JOIN VendorLocationProduct vlp_DT WITH (NOLOCK) on vlp_DT.VendorLocationID = vl.ID and vlp_DT.ProductID = (Select ID from Product where Name = 'Ford Direct Tow') and vlp_DT.IsActive = 1
		LEFT OUTER JOIN VendorLocationProduct vlp_P WITH (NOLOCK) on vlp_P.VendorLocationID = vl.ID and vlp_P.ProductID = (Select ID from Product where Name = 'CoachNet Dealer Partner') and vlp_P.IsActive = 1
		WHERE	vl.IsActive = 1 AND vl.VendorLocationStatusID = (SELECT ID FROM VendorLocationStatus WHERE Name = 'Active')
				AND
				(
				(vlp_DT.ID IS NOT NULL 
				AND vl.DealerNumber IS NOT NULL 
				AND vl.PartsAndAccessoryCode IS NOT NULL)
				OR
				(vlp_P.ID IS NOT NULL)	
				)
	END

	RETURN;

END
