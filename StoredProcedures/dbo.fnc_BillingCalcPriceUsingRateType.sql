/****** Object:  UserDefinedFunction [dbo].[fnc_BillingCalcPriceUsingRateType]    Script Date: 04/29/2014 02:13:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_BillingCalcPriceUsingRateType]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_BillingCalcPriceUsingRateType]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop function dbo.fnc_BillingCalcPriceUsingRateType


CREATE function [dbo].[fnc_BillingCalcPriceUsingRateType]
--ALTER function [dbo].[fnc_BillingCalcPriceUsingRateType]
(	@pRateTypeName as nvarchar(50)=null,
	@pBaseQuantity as int=null,
	@pBaseAmount as money=null,
	@pBasePercentage as float=null)
returns money
as
begin

	declare @EventPrice as money

	select @EventPrice = 

	case
	
		when @pRateTypeName = 'AmountEach' then (@pBaseQuantity * @pBaseAmount)
	
		when @pRateTypeName = 'PercentageEach' then (@pBaseQuantity * @pBaseAmount * @pBasePercentage)
	
		when @pRateTypeName = 'AmountPassThru' then (@pBaseAmount)
	
		when @pRateTypeName = 'AmountFixed' then (@pBaseQuantity * @pBaseAmount)

		when @pRateTypeName = 'Manual' then null

		else 0.00

	end

return @EventPrice

end
GO
