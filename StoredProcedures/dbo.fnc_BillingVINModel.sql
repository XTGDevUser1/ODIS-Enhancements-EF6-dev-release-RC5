/****** Object:  UserDefinedFunction [dbo].[fnc_BillingVINModel]    Script Date: 04/29/2014 02:13:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_BillingVINModel]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_BillingVINModel]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop function dbo.fnc_BillingVINModel

-- select top 1000 dbo.fnc_BillingVINModel(VehicleVIN) as VINModel, *  from [case] where VehicleVin is not null

CREATE function [dbo].[fnc_BillingVINModel]
	(@pVIN as nvarchar(50)=null)
RETURNS nvarchar(50)
AS
BEGIN

	DECLARE @VINModel as nvarchar(50)

	SELECT @VINModel = 

	CASE
		 WHEN substring(@pVIN,2,1) <> 'F' THEN ''
		 WHEN substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,3) in ('S6A','S6B','S7A','S7B','S7C','S7D','S8A','S9B','S9C','S6E','S7E','S6F','S7F','E6E','E7E','E6F','E7F','S9E','S8F','S9F','E9E','E8F','E9F','E9G','S7P','S7R','S6H','S7H','S6J','S7J','E6H','E7H','E6J','E7J') THEN 'Transit Connect'
		 WHEN substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,3) in ('E1Z' ,'E1Y' ,'E9Z' ,'E2Y' ,'E1C' ,'E1D' ,'E2C' ,'E2D' ,'K1Z' ,'K1Y' ,'K1C') THEN 'Transit-150'
		 WHEN substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,3) in ('R1Z' ,'R1Y' ,'R2Z' ,'R2Y' ,'R1C' ,'R1D' ,'R2C' ,'R2D' ,'R2X' ,'R2U' ,'R3X' ,'R3U' ,'R5P' ,'R7P' ,'R5Z' ,'R7Z') THEN 'Transit-250'
		 WHEN substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,3) in ('W2Z' ,'W2Y' ,'X2Z' ,'X2Y' ,'W2C' ,'W2D' ,'X2C' ,'W2X' ,'W2U' ,'W3X' ,'W3U' ,'X2X' ,'W7P' ,'W7Z') THEN 'Transit-350'
		 WHEN substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,3) in ('U4X' ,'F4X' ,'F4U' ,'S4X' ,'S4U' ,'F6P' ,'F8P' ,'F9P' ,'F6Z' ,'F8Z' ,'F9Z' ,'S6P' ,'S8P' ,'S9P' ,'S6Z' ,'S8Z' ,'S9Z') THEN 'Transit-350HD'
		 WHEN substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,3) in ('f53' ,'f5d') THEN 'F-53'
		 WHEN substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,3) in ('f59' ,'f5k') THEN 'F-59'
		 WHEN substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('e3','s3') THEN 'E-350'
		 WHEN substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('e4','s4') THEN 'E-450'
		 WHEN substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('f3','w3','x3') THEN 'F-350'
		 WHEN substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('f4','w4','x4') THEN 'F-450'
		 WHEN substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('f5','w5','x5') THEN 'F-550'
		 WHEN substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('f6','w6','x6') THEN 'F-650'
		 WHEN substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('f7','w7','x7') THEN 'F-750'
		 --WHEN substring(@pVIN,2,1) = 'F' and substring(@pVIN,5,2) in ('l4','l5') THEN 'LCF'
		 else NULL
	END
	
	RETURN @VINModel

END
GO
