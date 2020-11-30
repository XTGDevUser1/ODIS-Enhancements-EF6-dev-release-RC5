IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Member_Products_Using_Category]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_Products_Using_Category] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- dms_Member_Products_Using_Category 897, 3
CREATE PROC [dbo].[dms_Member_Products_Using_Category](
	@memberID INT = NULL,
	@productCategoryID INT = NULL,
	@VIN nvarchar(50) = NULL
)
AS
BEGIN
IF (@productCategoryID IS NULL AND @VIN IS NULL)
BEGIN
	SELECT DISTINCT	ISNULL(REPLACE(RTRIM(
		COALESCE(p.Description, '') +
		COALESCE(', ' + pp.Description, '') +  
		COALESCE(', ' + pp.PhoneNumber, '') 
		), '  ', ' ')
		,'') AS [AdditionalProduct]
	, pp.Script AS [HelpText]
	
	FROM	MemberProduct mp (NOLOCK)
	JOIN	Membership ms (NOLOCK) ON mp.MembershipID = ms.ID
	JOIN	Product p (NOLOCK) ON p.ID = mp.ProductID
	JOIN	ProductProvider pp (NOLOCK) ON pp.ID = mp.ProductProviderID
	WHERE	(mp.MemberID = @memberID)
	
	UNION ALL
	SELECT DISTINCT	ISNULL(REPLACE(RTRIM(
		COALESCE(p.Description, '') +
		COALESCE(', ' + pp.Description, '') +  
		COALESCE(', ' + pp.PhoneNumber, '') 
		), '  ', ' ')
		,'') AS [AdditionalProduct]
	, pp.Script AS [HelpText]
	
	FROM	MemberProduct mp (NOLOCK)
	JOIN	Membership ms (NOLOCK) ON mp.MembershipID = ms.ID
	JOIN	Product p (NOLOCK) ON p.ID = mp.ProductID
	JOIN	ProductProvider pp (NOLOCK) ON pp.ID = mp.ProductProviderID
	WHERE	(mp.MemberID IS NULL AND ms.ID = (SELECT MembershipID FROM Member WHERE ID = @MemberID))				
			
	ORDER BY [AdditionalProduct]
END
ELSE
BEGIN
	SELECT	DISTINCT ISNULL(REPLACE(RTRIM(
			COALESCE(p.Description, '') +
			--COALESCE(', ' + CONVERT(VARCHAR(10),mp.StartDate,101),'') + 
			--COALESCE(' - ' + CONVERT(VARCHAR(10),mp.EndDate,101), '') +
			COALESCE(', ' + pp.Description, '') +  
			COALESCE(', ' + pp.PhoneNumber, '') 
			), '  ', ' ')
			,'') AS [AdditionalProduct]
		, pp.Script AS [HelpText]
		
	FROM	MemberProduct mp (NOLOCK)
	JOIN	Membership ms (NOLOCK) ON mp.MembershipID = ms.ID
	JOIN	Product p (NOLOCK) ON p.ID = mp.ProductID
	JOIN	ProductProvider pp (NOLOCK) ON pp.ID = mp.ProductProviderID
	JOIN	MemberProductProductCategory mppc (NOLOCK) ON mppc.ProductID = p.ID AND mppc.ProductCategoryID = @productCategoryID 
	WHERE	(mp.MemberID = @memberID) AND (mp.VIN IS NULL OR mp.VIN = @VIN)
	
	UNION ALL
	SELECT	DISTINCT ISNULL(REPLACE(RTRIM(
			COALESCE(p.Description, '') +
			--COALESCE(', ' + CONVERT(VARCHAR(10),mp.StartDate,101),'') + 
			--COALESCE(' - ' + CONVERT(VARCHAR(10),mp.EndDate,101), '') +
			COALESCE(', ' + pp.Description, '') +  
			COALESCE(', ' + pp.PhoneNumber, '') 
			), '  ', ' ')
			,'') AS [AdditionalProduct]
		, pp.Script AS [HelpText]
		
	FROM	MemberProduct mp (NOLOCK)
	JOIN	Membership ms (NOLOCK) ON mp.MembershipID = ms.ID
	JOIN	Product p (NOLOCK) ON p.ID = mp.ProductID
	JOIN	ProductProvider pp (NOLOCK) ON pp.ID = mp.ProductProviderID
	JOIN	MemberProductProductCategory mppc (NOLOCK) ON mppc.ProductID = p.ID AND mppc.ProductCategoryID = @productCategoryID 
	WHERE	(mp.MemberID IS NULL AND ms.ID = (SELECT MembershipID FROM Member WHERE ID = @MemberID))
							AND (mp.VIN IS NULL OR mp.VIN = @VIN) 
	ORDER BY [AdditionalProduct]
END
END