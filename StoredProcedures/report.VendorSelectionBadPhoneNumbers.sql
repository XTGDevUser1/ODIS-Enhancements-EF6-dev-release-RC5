USE [DMS]
GO

/****** Object:  StoredProcedure [report].[VendorSelectionBadPhoneNumbers]    Script Date: 10/27/2015 13:24:37 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[report].[VendorSelectionBadPhoneNumbers]') AND type in (N'P', N'PC'))
DROP PROCEDURE [report].[VendorSelectionBadPhoneNumbers]
GO

USE [DMS]
GO

/****** Object:  StoredProcedure [report].[VendorSelectionBadPhoneNumbers]    Script Date: 10/27/2015 13:24:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--EXEC report.VendorSelectionBadPhoneNumbers '10/1/2015','10/31/2015',1,5,0


CREATE PROCEDURE [report].[VendorSelectionBadPhoneNumbers] (
	@BeginDate date,
	@EndDate date,
	@VendorRegionID int,
	@MinPhoneCalls int = 0,
	@IsCalledPhoneSameAsDispatchPhone bit = 0
)
AS
BEGIN

	--DECLARE @MinPhoneCalls int = 5
	--DECLARE @IsCalledPhoneSameAsDispatchPhone bit = 1

	DECLARE @VendorEntityID int, @VendorLocationEntityID int, @DispatchPhoneTypeID int, @OfficePhoneTypeID int
	SET @VendorEntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
	SET @VendorLocationEntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
	SET @DispatchPhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Dispatch')
	SET @OfficePhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Office')

	SELECT 
		v.VendorNumber
		,v.Name VendorName
		,Case WHEN MAX(ContractedVendor.VendorID) IS NOT NULL THEN 'Yes' ELSE 'No' END IsContractedYN
		,REPLACE(MAX(vr.Name), ' Region', '') VendorRegionName
		,MAX(VendorLocations.[Count]) VendorLocationCount
		,ae.Line1 + ', ' + ae.City + ', ' + ae.StateProvince VendorLocation
		,cl.PhoneNumber PhoneNumberCalled
		,vlph.PhoneNumber DispatchPhoneNumber
		,vph.PhoneNumber OfficePhoneNumber
		,COUNT(*) TotalCalls 
		,SUM(Case WHEN cla.ContactActionDescription = 'No Answer' THEN 1 ELSE 0 END) NoAnswer 
		,SUM(Case WHEN cla.ContactActionDescription = 'Bad phone number' THEN 1 ELSE 0 END) BadPhoneNumber 
		,SUM(Case WHEN cla.ContactActionDescription = 'No longer in business' THEN 1 ELSE 0 END) NoLongerInBusiness 
	FROM vw_ContactLogs cl
	JOIN vw_ContactLogActions cla on cla.ContactLogID = cl.ContactLogID
	JOIN VendorLocation vl (NOLOCK) on vl.ID = cl.VendorLocationID 
	JOIN Vendor v (NOLOCK) ON v.ID = vl.VendorID
	JOIN VendorRegion vr (NOLOCK) ON vr.ID = v.VendorRegionID
	JOIN VendorStatus vs on vs.ID = v.VendorStatusID
	JOIN AddressEntity ae (NOLOCK) ON ae.EntityID = @VendorLocationEntityID AND ae.RecordID = vl.ID
	LEFT OUTER JOIN fnGetContractedVendors() ContractedVendor on ContractedVendor.VendorID = v.ID
	LEFT OUTER JOIN PhoneEntity vlph (NOLOCK) ON vlph.EntityID = @VendorLocationEntityID AND vlph.PhoneTypeID = @DispatchPhoneTypeID AND vlph.RecordID = vl.ID
	LEFT OUTER JOIN PhoneEntity vph (NOLOCK) ON vph.EntityID = @VendorEntityID AND vph.PhoneTypeID = @OfficePhoneTypeID AND vph.RecordID = v.ID
	LEFT OUTER JOIN (
		SELECT v.ID VendorID, COUNT(*) [Count]
		FROM Vendor v
		JOIN VendorLocation vl ON v.ID = vl.VendorID
		WHERE vl.IsActive = 1
		GROUP BY v.ID
		) VendorLocations ON VendorLocations.VendorID = v.ID
	WHERE 1=1
	and v.IsActive = 1
	and (@VendorRegionID IS NULL OR V.VendorRegionID = @VendorRegionID)
	and vs.Name IN ('Active','OnHold', 'DoNotUse')
	and cl.CreateDate > '8/1/2015'
	and cl.ContactCategoryDescription = 'Vendor Selection'
	and cla.ContactActionDescription in (
		'No answer'
		,'Bad phone number'
		,'No longer in business'
		)
	and (@IsCalledPhoneSameAsDispatchPhone = 0 OR cl.PhoneNumber = vlph.PhoneNumber)
	GROUP BY 
		v.VendorNumber
		,v.Name 
		,ae.Line1
		,ae.City
		,ae.StateProvince
		,cl.PhoneNumber
		,vlph.PhoneNumber
		,vph.PhoneNumber
		HAVING COUNT(*) >= @MinPhoneCalls

	ORDER BY TotalCalls DESC

END
GO


