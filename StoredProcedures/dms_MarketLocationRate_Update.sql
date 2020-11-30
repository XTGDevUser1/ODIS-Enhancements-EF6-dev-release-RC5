IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_MarketLocationRate_Update]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_MarketLocationRate_Update]
GO

--EXEC dbo.dms_MarketLocationRate_Update
CREATE PROCEDURE [dbo].[dms_MarketLocationRate_Update] 
AS
BEGIN

	DECLARE @HistoryMonths int = 18

	-- Find average pricing for contracted Vendors honoring contracted rates based on historical POs
	SELECT Dtl.VendorID, Dtl.ProductID, Dtl.ProductName, Dtl.RateTypeID, Dtl.RateName
	, ROUND(AVG(BaseLineRate),2) BaseLinePrice, COUNT(*) ActualCount
	INTO #tmpContractedVendorActual
	FROM
	(
		SELECT 
		v.VendorNumber, v.ID VendorID
		, pod.ProductID, p.Name ProductName, pod.ProductRateID RateTypeID, rt.Name RateName
		, CASE 
			WHEN pod.Rate > ISNULL(pod.ContractedRate,0) THEN pod.Rate
			WHEN COALESCE(VendorLocationRates.Price, DefaultVendorRates.Price) > 0 THEN COALESCE(VendorLocationRates.Price, DefaultVendorRates.Price)
			ELSE pod.ContractedRate
			END BaselineRate
		, COALESCE(VendorLocationRates.Price, DefaultVendorRates.Price) CurrentContractRate
		--, pod.ContractedRate POContractRate, pod.Rate PORate, pod.Quantity
		FROM PurchaseOrderDetail pod WITH (NOLOCK)
		JOIN PurchaseOrder po WITH (NOLOCK) on pod.PurchaseOrderID = po.id
		Join VendorLocation vl WITH (NOLOCK) on vl.ID = po.VendorLocationID
		Join Vendor v WITH (NOLOCK) on v.ID = vl.VendorID
		JOIN Product p WITH (NOLOCK) on p.ID = pod.ProductID
		JOIN RateType rt WITH (NOLOCK) on rt.ID = pod.ProductRateID
		LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() VendorLocationRates ON   
			  v.ID = VendorLocationRates.VendorID AND   
			  p.ID = VendorLocationRates.ProductID AND   
			  rt.ID = VendorLocationRates.RateTypeID AND  
			  VendorLocationRates.VendorLocationID = vl.ID   
		LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() DefaultVendorRates ON   
			  v.ID = DefaultVendorRates.VendorID AND   
			  p.ID = DefaultVendorRates.ProductID AND   
			  rt.ID = DefaultVendorRates.RateTypeID AND  
			  DeFaultVendorRates.VendorLocationID IS NULL  
		WHERE 1=1
		AND po.CreateDate >= DATEADD(mm,@HistoryMonths*-1, GETDATE())
		AND rt.ID NOT IN (3,7)   --Exclude Free Mile Rates
		and p.ID NOT IN (202,203,204,205,207,208,209,210,211)
		AND ISNULL(pod.Rate,0) <> 0
		-- Accept actual rate that are equal to the contracted rates or not more than 50% more than the contracted rates
		AND (ISNULL(pod.ContractedRate,0)*1.5 >= pod.Rate 
			OR COALESCE(VendorLocationRates.Price, DefaultVendorRates.Price,0)*1.5 >= pod.Rate)
		AND po.IsActive = 1
		AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued','Issued-Paid'))
		AND (
			--Check that non-tow service included Base and Enroute rate detail
			EXISTS (
			SELECT pod1.PurchaseOrderID
			FROM PurchaseOrderDetail pod1 WITH (NOLOCK)
			JOIN Product p WITH (NOLOCK) ON pod1.ProductID = p.ID AND p.ProductCategoryID <> 1
			WHERE pod1.ProductRateID IN (SELECT ID FROM RateType WHERE Name IN ('Base','Enroute'))
			AND pod1.ExtendedAmount > 0
			AND pod1.PurchaseOrderID = po.ID
			GROUP BY pod1.PurchaseOrderID HAVING COUNT(*) > 1
				)
			OR
			--Check that tow service included Base and Service rate details
			EXISTS (
			SELECT pod1.PurchaseOrderID
			FROM PurchaseOrderDetail pod1 WITH (NOLOCK)
			JOIN Product p WITH (NOLOCK) ON pod1.ProductID = p.ID AND p.ProductCategoryID = 1
			WHERE pod1.ProductRateID IN (SELECT ID FROM RateType WHERE Name IN ('Base','Service'))
			AND pod1.ExtendedAmount > 0
			AND pod1.PurchaseOrderID = po.ID
			GROUP BY pod1.PurchaseOrderID HAVING COUNT(*) > 1
				)
			OR
			--Check for Hourly Service rate details
			EXISTS (
			SELECT pod1.PurchaseOrderID
			FROM PurchaseOrderDetail pod1 WITH (NOLOCK)
			JOIN Product p WITH (NOLOCK) ON pod1.ProductID = p.ID AND p.ProductCategoryID = 1
			WHERE pod1.ProductRateID IN (SELECT ID FROM RateType WHERE Name IN ('Hourly'))
			AND pod1.ExtendedAmount > 0
			AND pod1.PurchaseOrderID = po.ID
			GROUP BY pod1.PurchaseOrderID 
				)
			)
		) DTL
	GROUP BY Dtl.VendorID, Dtl.ProductID, Dtl.ProductName, Dtl.RateTypeID, Dtl.RateName
	ORDER BY Dtl.VendorID, Dtl.ProductID, Dtl.ProductName, Dtl.RateTypeID, Dtl.RateName


	--Include ALL other contracted rates for Vendors honoring their rates above
	--Logic: If the Vendor honored his rates for the service on the PO then the rest of his contract rates should be good
	SELECT VendorID, ProductID, ProductName, RateTypeID, RateName, BaseLinePrice, ActualCount
	INTO #tmpVendorBaseline
	FROM #tmpContractedVendorActual
	UNION
	SELECT DefaultVendorRates.VendorID, DefaultVendorRates.ProductID, p.Name ProductName, DefaultVendorRates.RateTypeID, DefaultVendorRates.RateName, DefaultVendorRates.Price BaseLinePrice, 0 As ActualCount
	FROM dbo.fnGetCurrentProductRatesByVendorLocation() DefaultVendorRates
	Join Product p on p.ID = DefaultVendorRates.ProductID   
	WHERE EXISTS(
		SELECT *
		FROM #tmpContractedVendorActual tmp
		WHERE tmp.VendorID = DefaultVendorRates.VendorID
		)
	AND NOT EXISTS (
		SELECT *
		FROM #tmpContractedVendorActual tmp
		WHERE tmp.VendorID = DefaultVendorRates.VendorID AND
			tmp.ProductID = DefaultVendorRates.ProductID AND
			tmp.RateTypeID = DefaultVendorRates.RateTypeID
		)
	AND DefaultVendorRates.RateTypeID NOT IN (3,7,9)
	AND ISNULL(DefaultVendorRates.Price,0) <> 0
	ORDER BY VendorID, ProductID, RateTypeID


	--Determine adjusted Baseline Prices to evaluate validity of non-contracted rates below
	DECLARE @PriceAdjust money
	SET @PriceAdjust = 1.3 --price bump from Contracted to Adjusted Non-Contract rates

	-- Determine Maximum allowable prices to eliminate outlier prices
	-- Use AVG contracted price + StdDev of contracted prices + @PriceAdjust 

	-- Determine BaseLine ADJUSTED Avg
	-- Adjust AVG by STD Deviation + 30%
	Select ProductID, RateTypeID, RateName
	,ROUND(MAX(BaseLinePrice),1) MaxBaseLinePrice, ROUND(STDEV(BaseLinePrice),1) StdDevBaseLinePrice   
	,(ROUND(STDEV(BaseLinePrice),1) + ROUND(AVG(BaseLinePrice),1)) * @PriceAdjust BaseLinePrice
	,COUNT(*) [Count]
	Into #tmpContractedVendorBaselineAvg
	From #tmpVendorBaseline
	Group By ProductID, RateTypeID, RateName
	Order By ProductID, RateTypeID, RateName

	CREATE CLUSTERED INDEX IDX_ProductID ON #tmpContractedVendorBaselineAvg (ProductID, RateTypeID) 


	-- Average pricing for non-contracted Vendors, eliminating any pricing that exceeds the adjusted Baseline pricing determined above
	SELECT Dtl.VendorID, Dtl.ProductID, Dtl.ProductName, Dtl.RateTypeID, Dtl.RateName
	, ROUND(AVG(Rate),1) BaseLinePrice, COUNT(*) ActualCount
	INTO #tmpNonContractVendors
	FROM
	(
		SELECT 
		v.VendorNumber, v.ID VendorID
		, pod.ProductID, p.Name ProductName, pod.ProductRateID RateTypeID, rt.Name RateName
		,pod.Rate
		FROM PurchaseOrderDetail pod WITH (NOLOCK)
		JOIN PurchaseOrder po WITH (NOLOCK) on pod.PurchaseOrderID = po.id
		Join VendorLocation vl WITH (NOLOCK) on vl.ID = po.VendorLocationID
		Join Vendor v WITH (NOLOCK) on v.ID = vl.VendorID
		JOIN Product p WITH (NOLOCK) on p.ID = pod.ProductID
		JOIN RateType rt WITH (NOLOCK) on rt.ID = pod.ProductRateID
		Join #tmpContractedVendorBaselineAvg BaseAvg on BaseAvg.ProductID = p.ID and BaseAvg.RateTypeID = rt.ID
		WHERE 1=1
		AND po.CreateDate >= DATEADD(mm,@HistoryMonths*-1, GETDATE())
		AND rt.ID NOT IN (3,7, 9)   --Exclude Free Mile Rates and Return rate
		and p.ID NOT IN (202,203,204,205,207,208,209,210,211)
		AND ISNULL(pod.Rate,0) <> 0
		--Include this to eliminate outlier prices
		AND pod.Rate <= BaseAvg.BaseLinePrice
		AND ISNULL(pod.ContractedRate,0) = 0
		AND po.IsActive = 1
		AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued','Issued-Paid'))
		AND (
			--Check that non-tow service included Base and Enroute rate detail
			EXISTS (
			SELECT pod1.PurchaseOrderID
			FROM PurchaseOrderDetail pod1 WITH (NOLOCK)
			JOIN Product p WITH (NOLOCK) ON pod1.ProductID = p.ID AND p.ProductCategoryID <> 1
			WHERE pod1.ProductRateID IN (SELECT ID FROM RateType WHERE Name IN ('Base','Enroute'))
			AND pod1.ExtendedAmount > 0
			AND pod1.PurchaseOrderID = po.ID
			GROUP BY pod1.PurchaseOrderID HAVING COUNT(*) > 1
				)
			OR
			--Check that tow service included Base and Service rate details
			EXISTS (
			SELECT pod1.PurchaseOrderID
			FROM PurchaseOrderDetail pod1 WITH (NOLOCK)
			JOIN Product p WITH (NOLOCK) ON pod1.ProductID = p.ID AND p.ProductCategoryID = 1
			WHERE pod1.ProductRateID IN (SELECT ID FROM RateType WHERE Name IN ('Base','Service'))
			AND pod1.ExtendedAmount > 0
			AND pod1.PurchaseOrderID = po.ID
			GROUP BY pod1.PurchaseOrderID HAVING COUNT(*) > 1
				)
			OR
			--Check for Hourly Service rate details
			EXISTS (
			SELECT pod1.PurchaseOrderID
			FROM PurchaseOrderDetail pod1 WITH (NOLOCK)
			JOIN Product p WITH (NOLOCK) ON pod1.ProductID = p.ID AND p.ProductCategoryID = 1
			WHERE pod1.ProductRateID IN (SELECT ID FROM RateType WHERE Name IN ('Hourly'))
			AND pod1.ExtendedAmount > 0
			AND pod1.PurchaseOrderID = po.ID
			GROUP BY pod1.PurchaseOrderID 
				)
			)
		) DTL
	GROUP BY Dtl.VendorID, Dtl.ProductID, Dtl.ProductName, Dtl.RateTypeID, Dtl.RateName
	ORDER BY Dtl.VendorID, Dtl.ProductID, Dtl.ProductName, Dtl.RateTypeID, Dtl.RateName

	INSERT INTO #tmpVendorBaseline (VendorID, ProductID, ProductName, RateTypeID, RateName, BaseLinePrice, ActualCount)
	SELECT VendorID, ProductID, ProductName, RateTypeID, RateName, BaseLinePrice, ActualCount
	FROM #tmpNonContractVendors
		
	CREATE CLUSTERED INDEX IDX_VendorID ON #tmpVendorBaseline (VendorID)


	-- Use identified pricing above to find averages based on METRO market location
	Select ml.ID MarketLocationID, ml.Name, cvb.ProductID, cvb.ProductName, cvb.RateTypeID, cvb.RateName
	, ROUND(MAX(BaseLinePrice),1) MaxPrice, ROUND(STDEV(BaseLinePrice),1) StdDev, ROUND(AVG(cvb.BaseLinePrice),1) AvgPrice, SUM(ActualCount) ActualCount
	Into #tmpMarketLocation
	From MarketLocation ml WITH (NOLOCK)
	Join dbo.VendorLocation vl
		ON ml.MarketLocationTypeID = 1 and ml.GeographyLocation.STDistance(vl.GeographyLocation) <= ml.RadiusMiles * 1609.344
	Join #tmpVendorBaseline cvb 
		ON cvb.VendorID = vl.VendorID
	Where ml.MarketLocationTypeID = 1
	Group by ml.ID , ml.Name, cvb.ProductID, cvb.ProductName, cvb.RateTypeID, cvb.RateName
	--Order by ml.ID , ml.Name, cvb.ProductID, cvb.ProductName, cvb.RateTypeID, cvb.RateName


	-- Use identified pricing above to find averages based on STATE market location
	Insert Into #tmpMarketLocation
	Select ml.ID MarketLocationID, ml.Name, cvb.ProductID, cvb.ProductName, cvb.RateTypeID, cvb.RateName
	, ROUND(MAX(BaseLinePrice),1) MaxPrice, ROUND(STDEV(BaseLinePrice),1) StdDev, ROUND(AVG(cvb.BaseLinePrice),1) AvgPrice, SUM(ActualCount) ActualCount
	--Into #tmpMarketLocation
	From MarketLocation ml WITH (NOLOCK)
	Join AddressEntity ae 
		on ae.EntityID = 18 and ae.AddressTypeID = (Select ID From AddressType Where Name = 'Business') and ml.Name = ae.CountryCode + '_' + ae.StateProvince
	Join dbo.VendorLocation vl 
		on vl.ID = ae.RecordID
	Join #tmpVendorBaseline cvb 
		ON cvb.VendorID = vl.VendorID
	Where ml.MarketLocationTypeID = 2
	Group by ml.ID , ml.Name, cvb.ProductID, cvb.ProductName, cvb.RateTypeID, cvb.RateName
	Order by ml.ID , ml.Name, cvb.ProductID, cvb.ProductName, cvb.RateTypeID, cvb.RateName


	--Begin process of using identified AVG rates to update Market Location rates
	Select ml.ID MarketLocationID, ml.Name, mlp.ProductID, p.Name ProductName
	, mlp.RateTypeID, rt.Name RateName
	,tmp.MaxPrice, tmp.StdDev
	--Round to tenths for Service and Enroute, else round to nearest dollar
	,Case WHEN tmp.RateTypeID IN (2,6) THEN Round(tmp.AvgPrice,1) ELSE Round(tmp.AvgPrice,0) END AvgPrice
	, tmp.ActualCount
	, mlp.Price MarketPrice
	,Round((tmp.AvgPrice - mlp.Price)/tmp.AvgPrice,2) PercentDifferenceFromAVG
	Into #tmpMarketAnalysis
	From MarketLocation ml WITH (NOLOCK)
	Join MarketLocationProductRate mlp WITH (NOLOCK) on ml.ID = mlp.MarketLocationID
	Join Product p WITH (NOLOCK) on p.ID = mlp.ProductID
	Join RateType rt WITH (NOLOCK) on rt.ID = mlp.RateTypeID
	Left Outer Join #tmpMarketLocation tmp on tmp.MarketLocationID = ml.ID and tmp.ProductID = mlp.ProductID and tmp.RateTypeID = mlp.RateTypeID
	Where rt.ID not in (3,7,9)   --Exclude Free Mile Rates (enroute,service) and Return rates
	Order by ml.ID, ml.Name, mlp.ProductID, p.Name, mlp.RateTypeID


	-- If the new price and the existing market price are different
	-- AND the difference between the new price and the existing market price is less than 20% different 
	-- OR the new price is less than 20% different from the overall average (all markets) 
	-- OR the new price (average) is based on 20 or more occurrences
	-- THEN update to the new price (average)
	--Select ma.*, Overall.AvgPrice
	Update ma Set MarketPrice = ma.AvgPrice
	From #tmpMarketAnalysis ma
	JOin (
		Select ProductID, RateTypeID, Round(AVG(AvgPrice),0) AvgPrice
		From #tmpMarketAnalysis
		where AvgPrice IS NOT NULL
		Group By ProductID, RateTypeID
		) Overall on overall.ProductID = ma.ProductID and overall.RateTypeID = ma.RateTypeID
	where 1=1
	--and ma.AvgPrice <> ma.MarketPrice
	and (Abs(ma.PercentDifferenceFromAVG) < .2
		or ABS(ma.AvgPrice - overall.AvgPrice)/overall.AvgPrice < .2
		or ma.ActualCount >= 20)

	-- If the new price does not meet the above criteria, split the difference between the new price and the overall average
	--Select ma.*, Overall.AvgPrice,
	Update ma Set MarketPrice =
	----Round to tenths for Service and Enroute, else round to nearest dollar
	 CASE WHEN ma.RateTypeID = 2 THEN ROUND(((Overall.AvgPrice - ma.AvgPrice)*.5) + ma.AvgPrice,1) 
		ELSE ROUND(((Overall.AvgPrice - ma.AvgPrice)*.5) + ma.AvgPrice,0) 
		END 
	From #tmpMarketAnalysis ma
	JOin (
		Select ProductID, RateTypeID, Round(AVG(AvgPrice),0) AvgPrice
		From #tmpMarketAnalysis
		where AvgPrice IS NOT NULL
		Group By ProductID, RateTypeID
		) Overall on overall.ProductID = ma.ProductID and overall.RateTypeID = ma.RateTypeID
	where 1=1
	and Abs(ma.PercentDifferenceFromAVG) > .2
	and ABS(ma.AvgPrice - overall.AvgPrice)/overall.AvgPrice > .2
	and ma.ActualCount < 20


	----UPDATE Market Location rates
	--Select tmp.MarketPrice, ml.name, mlp.*
	Update mlp Set Price = tmp.MarketPrice, ModifyDate = getdate(), ModifyBy = 'System', RateBasisEventCount = tmp.ActualCount
	From MarketLocation ml
	Join MarketLocationProductRate mlp on ml.ID = mlp.MarketLocationID
	Join Product p on p.ID = mlp.ProductID
	Join RateType rt on rt.ID = mlp.RateTypeID
	Join #tmpMarketAnalysis tmp on 
		tmp.MarketLocationID = ml.ID and 
		tmp.ProductID = mlp.ProductID and 
		tmp.RateTypeID = mlp.RateTypeID

	DROP TABLE #tmpMarketAnalysis
	DROP TABLE #tmpMarketLocation
	DROP TABLE #tmpNonContractVendors
	DROP TABLE #tmpContractedVendorBaselineAvg
	DROP TABLE #tmpContractedVendorActual
	DROP TABLE #tmpVendorBaseline

END

/*

Select NewMktRate.Market, NewMktRate.Product, NewMktRate.RateType, NewMktRate.Price NewPrice, OldMktRate.Price OldPrice
, ROUND((NewMktRate.Price - OldMktRate.Price)/ OldMktRate.Price, 2)
From vw_MarketLocationProductRate NewMktRate 
Join rogue.DMS.dbo.vw_MarketLocationProductRate OldMktRate on 
	NewMktRate.Market = OldMktRate.Market and
	NewMktRate.ProductID = OldMktRate.ProductID and
	NewMktRate.RateTypeID = OldMktRate.RateTypeID
Where ROUND((NewMktRate.Price - OldMktRate.Price)/ OldMktRate.Price, 2) > .30

*/
GO

