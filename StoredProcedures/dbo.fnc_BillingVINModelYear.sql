/****** Object:  UserDefinedFunction [dbo].[fnc_BillingVINModelYear]    Script Date: 04/29/2014 02:13:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_BillingVINModelYear]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_BillingVINModelYear]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop function dbo.fnc_BillingVINModelYear

-- select top 1000 dbo.fnc_BillingVINModelYear(VehicleVIN) as VINModelYear, *  from [case] where VehicleVin is not null

CREATE function [dbo].[fnc_BillingVINModelYear]
--ALTER function [dbo].[fnc_BillingVINModelYear]
(@pVIN as nvarchar(50)=null)
returns nvarchar(4)
as
begin

	declare @VINModelYear as nvarchar(4)

	select @VINModelYear = 

	case 
		 when substring(@pVIN,10,1) = 'x' then '1999'
		 when substring(@pVIN,10,1) = 'y' then '2000'
		 when substring(@pVIN,10,1) = '1' then '2001'
		 when substring(@pVIN,10,1) = '2' then '2002'
		 when substring(@pVIN,10,1) = '3' then '2003'
		 when substring(@pVIN,10,1) = '4' then '2004'
		 when substring(@pVIN,10,1) = '5' then '2005'
		 when substring(@pVIN,10,1) = '6' then '2006'
		 when substring(@pVIN,10,1) = '7' then '2007'
		 when substring(@pVIN,10,1) = '8' then '2008'
		 when substring(@pVIN,10,1) = '9' then '2009'
		 when substring(@pVIN,10,1) = 'a' then '2010'
		 when substring(@pVIN,10,1) = 'b' then '2011'
		 when substring(@pVIN,10,1) = 'c' then '2012'
		 when substring(@pVIN,10,1) = 'd' then '2013'
		 when substring(@pVIN,10,1) = 'e' then '2014'
		 when substring(@pVIN,10,1) = 'f' then '2015'
		 when substring(@pVIN,10,1) = 'g' then '2016'
		 when substring(@pVIN,10,1) = 'h' then '2017'
		 when substring(@pVIN,10,1) = 'i' then '2018'
		 when substring(@pVIN,10,1) = 'j' then '2019'				 
	else '' 
	end	

return @VINModelYear

end
GO
