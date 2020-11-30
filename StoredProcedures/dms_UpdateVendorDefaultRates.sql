
/****** Object:  StoredProcedure [dbo].[dms_UpdateVendorDefaultRates]    Script Date: 12/10/2012 20:17:00 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_UpdateVendorDefaultRates]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_UpdateVendorDefaultRates]
GO


/****** Object:  StoredProcedure [dbo].[dms_UpdateVendorDefaultRates]    Script Date: 12/10/2012 20:17:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Create default rates for non contracted vendors based on existing contracted rates in the area (state or metro)
CREATE PROCEDURE [dbo].[dms_UpdateVendorDefaultRates]
AS 
BEGIN

	Declare @CreateDate datetime
	Set @CreateDate = getdate()

	DECLARE @VendorLocationEntityID int, @BusinessAddressTypeID int, @MetroVendorLocationTypeID int, @StateVendorLocationTypeID int
	SET @VendorLocationEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'VendorLocation')
	SET @BusinessAddressTypeID = (SELECT ID FROM dbo.AddressType WHERE Name = 'Business')
	SET @MetroVendorLocationTypeID = (SELECT ID FROM dbo.VendorLocationType WHERE Name = 'Metro')
	SET @StateVendorLocationTypeID = (SELECT ID FROM dbo.VendorLocationType WHERE Name = 'State')

	/* Remove Existing Default Rates */
	Delete from ContractProductRate where ContractID IN (Select c.ID From dbo.[Contract] c Join dbo.Vendor v On c.VendorID = v.ID Where v.Name = 'NMC')


	CREATE TABLE #DefaultRates (
		VendorLocationID int
		,LocationName nvarchar(50)
		,ProductID int
		,RateTypeID int
		,ProductName nvarchar(50)
		,RateType nvarchar(50)
		,Price money
		,Quantity int)


	/* Create Global Default Contract Product Rates */
	INSERT INTO [dbo].[ContractProductRate]
			   ([ContractID]
			   ,[VendorLocationID]
			   ,[ProductID]
			   ,[RateTypeID]
			   ,[Price]
			   ,[Quantity]
			   ,[CreateDate]
			   ,[CreateBy])
	Select 
		c.ID
		,vl.ID
		,gdr.ProductID
		,gdr.RateTypeID
		,gdr.Price
		,gdr.Quantity
		,@CreateDate
		,'System'
	From vendor v
	Join vendorlocation vl on v.ID = vl.VendorID
	Join dbo.[Contract] c On c.VendorID = vl.VendorID
	Join VendorLocationType vlt On vl.VendorLocationTypeID = vlt.ID
	Join dbo.VendorGlobalDefaultRate gdr On 1=1
	Where v.Name = 'NMC'
	and vlt.Name = 'GlobalDefault'


	/* Pull average rates within the Metro area to set default rates for the metro */
	--;WITH Metro (
	--	VendorLocationID
	--	, LocationName
	--	, Latitude
	--	, Longitude
	--	, ProductID
	--	, RateTypeID
	--	, ProductName
	--	, RateType
	--	, Price
	--	, Quantity)
	--AS
	--	(
		Select 
			vl_default.ID VendorLocationID
			, vl_default_addr.City LocationName
			, vl_default.Latitude
			, vl_default.Longitude
			, cpr.ProductID
			, cpr.RateTypeID
			,Max(p.Name) ProductName
			, Max(rt.Name) RateType
			,Round(Avg(cpr.Price),1) Price
			, Round(Avg(cpr.Quantity),0) Quantity
		INTO #MetroRate
		From dbo.VendorLocation vl_default
		Join dbo.AddressEntity vl_default_addr 
			ON vl_default_addr.EntityID = @VendorLocationEntityID AND vl_default_addr.RecordID = vl_default.ID AND vl_default_addr.AddressTypeID = @BusinessAddressTypeID
		Join dbo.VendorLocation vl
			ON vl_default.GeographyLocation.STDistance(vl.GeographyLocation) <= vl_default.RadiusMiles * 1609.344
		Join dbo.ContractProductRate cpr On vl.ID = cpr.VendorLocationID
		Join dbo.Product p On cpr.ProductID = p.ID
		Join dbo.RateType rt On cpr.RateTypeID = rt.ID
		Where vl_default.VendorLocationTypeID = @MetroVendorLocationTypeID
			and p.ProductTypeID = 1
		Group By 
			vl_default.ID, vl_default_addr.City, vl_default.Latitude, vl_default.Longitude
			, cpr.ProductID, cpr.RateTypeID
	--)

	CREATE CLUSTERED INDEX IDX_MetroRate_ProductID ON #MetroRate(ProductID)

	Insert Into #DefaultRates
	Select m.VendorLocationID
		,m.LocationName
		,m.ProductID
		,m.RateTypeID
		,m.ProductName
		,m.RateType
		,m.Price
		,m.Quantity
	From dbo.ProductRateType prt
	Left Outer Join #MetroRate m
		On prt.ProductID = m.ProductID and prt.RateTypeID = m.RateTypeID and prt.IsOptional = 'FALSE'


	/* Enroute credit miles - exclude for default? */
	--Union
	--Select m.VendorLocationID
	--	,m.LocationName
	--	,m.ProductID
	--	,m.RateTypeID
	--	,m.ProductName
	--	,m.RateType
	--	,m.Price*-1
	--	,m.Quantity
	--From Metro m
	--Join dbo.ProductRateType prt
	--	On prt.ProductID = m.ProductID and prt.RateTypeID = m.RateTypeID
	--Where m.Quantity > 0


	/* Pull average rates with the State to get State Default Rates  */
	--;WITH StateRate (VendorLocationID, LocationName, ProductID, RateTypeID, ProductName, RateType, Price, Quantity)
	--AS
	--	(
   		Select 
			vl_default.ID VendorLocationID
			, vl_default_addr.[StateProvince] LocationName
			, cpr.ProductID
			, cpr.RateTypeID
			,Max(p.Name) ProductName
			, Max(rt.Name) RateType
			,ROUND(Avg(cpr.Price),1) Price
			, ROUND(Avg(cpr.Quantity),0) Quantity
		Into #StateRate
		From dbo.VendorLocation vl_default
		Join dbo.AddressEntity vl_default_addr 
			ON vl_default_addr.EntityID = @VendorLocationEntityID AND vl_default_addr.RecordID = vl_default.ID AND vl_default_addr.AddressTypeID = @BusinessAddressTypeID
		Join dbo.AddressEntity vl_addr
			ON vl_addr.EntityID = vl_default_addr.EntityID AND vl_addr.AddressTypeID = @BusinessAddressTypeID 
			AND vl_addr.[StateProvinceID] = vl_default_addr.[StateProvinceID]
		Join dbo.ContractProductRate cpr On vl_addr.RecordID = cpr.VendorLocationID
		Join dbo.Product p On cpr.ProductID = p.ID
		Join dbo.RateType rt On cpr.RateTypeID = rt.ID
		Where vl_default.VendorLocationTypeID = @StateVendorLocationTypeID
			and p.ProductTypeID = 1
		Group By
			vl_default.ID, vl_default_addr.[StateProvince]
			, cpr.ProductID, cpr.RateTypeID
	--)

	CREATE CLUSTERED INDEX IDX_StateRate_ProductID ON #StateRate(ProductID)

	Insert Into #DefaultRates
	Select s.VendorLocationID
		,s.LocationName
		,s.ProductID
		,s.RateTypeID
		,s.ProductName
		,s.RateType
		,s.Price
		,s.Quantity
	From dbo.ProductRateType prt
	Left Outer Join #StateRate s
		On prt.ProductID = s.ProductID and prt.RateTypeID = s.RateTypeID
	Where prt.IsOptional = 'FALSE'

	CREATE CLUSTERED INDEX IDX_DefaultRates_VendorLocationID ON #DefaultRates(VendorLocationID)

	/* Include Default Free Miles?  */
	--Union
	--Select s.VendorLocationID
	--	,s.LocationName
	--	,s.ProductID
	--	,s.RateTypeID
	--	,s.ProductName
	--	,s.RateType + ' Free Miles'
	--	,-1*s.Price
	--	,s.Quantity
	--From #StateRate s
	--Join dbo.ProductRateType prt
	--	On prt.ProductID = s.ProductID and prt.RateTypeID = s.RateTypeID
	--Where s.Quantity > 0


	/* Insert calculated default rates */
	INSERT INTO [dbo].[ContractProductRate]
			   ([ContractID]
			   ,[VendorLocationID]
			   ,[ProductID]
			   ,[RateTypeID]
			   ,[Price]
			   ,[Quantity]
			   ,[CreateDate]
			   ,[CreateBy])
	Select 
		c.ID
		,d.VendorLocationID
		,d.ProductID
		,d.RateTypeID
		,d.Price
		,d.Quantity
		,@CreateDate
		,'System'
	From #DefaultRates d
	Join dbo.VendorLocation vl 
		On vl.ID = d.VendorLocationID
	Join dbo.[Contract] c 
		On c.VendorID = vl.VendorID

	Drop Table #MetroRate
	Drop Table #StateRate
	Drop Table #DefaultRates

END

/*
Select vlt.Name, cpr.*
From Vendor v
Join VendorLocation vl on v.ID = vl.VendorID
Join VendorLocationType vlt on vlt.ID = vl.VendorLocationTypeID
Join [Contract] c on c.VendorID = v.ID and c.IsActive = 1
Join ContractProductRate cpr on cpr.VendorLocationId = vl.ID and cpr.ContractID = c.ID
Where v.Name = 'NMC'
Order by VendorLocationID, ProductID
*/	

GO


