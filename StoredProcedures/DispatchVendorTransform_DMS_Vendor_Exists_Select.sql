IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DispatchVendorTransform_DMS_Vendor_Exists_Select]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[DispatchVendorTransform_DMS_Vendor_Exists_Select]
GO
--dbo.DispatchVendorTransform_DMS_Vendor_Exists_Select 58 ,'0000097689'

Create procedure [dbo].[DispatchVendorTransform_DMS_Vendor_Exists_Select]
(	
	@pClientId int,
	@pClientVendorKey varchar(50)
)
AS
--******************************************************************************************
--******************************************************************************************
--
--
--******************************************************************************************
--******************************************************************************************


Select	
		*
From [dbo].[Vendor] v with(nolock) 
	
Where 1=1
	AND v.ClientId = @pClientId
	AND v.ClientVendorKey = @pClientVendorKey
GO

