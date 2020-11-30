IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_portal_user_profile_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_portal_user_profile_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

-- EXEC  [dbo].[dms_vendor_portal_user_profile_get] 'sysadmin'  
 
CREATE PROCEDURE [dbo].[dms_vendor_portal_user_profile_get](  
@loggedInUsername NVARCHAR(50)
)
AS

BEGIN
	--DECLARE @loggedInUsername NVARCHAR(50) = 'kbanda_vendor'

	SELECT	(SELECT Value FROM ApplicationConfiguration WHERE Name = 'VendorServicesPhoneNumber') AS VendorServicesPhoneNumber,
			(SELECT Value FROM ApplicationConfiguration WHERE Name = 'VendorServicesFaxNumber') AS VendorServicesFaxNumber,
			U.UserId,			
			VU.FirstName,
			M.Email,
			VU.LastName,
			ISNULL(VU.ID,0) AS VendorUserID,
			VU.PostLoginPromptID,
			VU.ChangePassword,
			VU.ReceiveNotification,
			ISNULL(V.ID,0) AS VendorID,
			V.Name AS VendorName,
			V.VendorNumber,
			CAST(CASE WHEN V.ID IS NULL THEN 1 ELSE ISNULL(V.IsActive,0) END AS BIT) AS VendorIsActive,
			VR.ContactFirstName AS VendorRegionContactFirstName,
			VR.ContactLastName AS VendorRegionContactLastName,
			VR.Email AS VendorRegionEmail,
			VR.PhoneNumber AS VendorRegionPhoneNumber,
			VR.Name AS VendorRegionName,
			CAST(CASE WHEN V.ID IS NULL THEN 1 ELSE ISNULL(M.IsLockedOut,0) END AS BIT) AS IsVendorLockedOut
	FROM	aspnet_Users U WITH (NOLOCK)
	JOIN	aspnet_Membership M WITH (NOLOCK) ON M.UserId = U.UserId
	JOIN	aspnet_Applications AP WITH (NOLOCK) ON U.ApplicationId = AP.ApplicationId
	LEFT JOIN	VendorUser VU WITH (NOLOCK) ON U.UserId = VU.aspnet_UserID
	LEFT JOIN	Vendor V WITH (NOLOCK) ON V.ID = VU.VendorID
	LEFT JOIN VendorRegion VR WITH (NOLOCK) ON VR.ID = V.VendorRegionID	
	WHERE	U.UserName = @loggedInUsername
	AND		AP.ApplicationName = 'VendorPortal'

END
GO

