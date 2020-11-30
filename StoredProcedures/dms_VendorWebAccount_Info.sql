IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_VendorWebAccount_Info]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VendorWebAccount_Info]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
CREATE PROC [dbo].[dms_VendorWebAccount_Info](@VendorID INT = NULL)
AS
BEGIN
	SELECT 
	  VU.VendorID
	, U.Username
	, VU.FirstName + ' ' + VU.LastName AS [FirstLastName]
	, M.Email
	, DATEADD(HH,-5,U.LastActivityDate) LastActivityDate
	, DATEADD(HH,-5,M.LastPasswordChangedDate) LastPasswordChangedDate
	, M.IsApproved
	, M.IsLockedOut
	, LC.Username AS LegacyUsername
	, LC.Password AS LegacyPassword
	, U.ApplicationId
	, U.UserId
	FROM VendorUser VU
	JOIN aspnet_Users U ON U.UserID = VU.aspnet_UserID
	JOIN aspnet_Membership M ON M.USerID = U.UserID
	LEFT JOIN VendorLegacyCredentials LC ON LC.VendorID = VU.VendorID
	WHERE VU.VendorID = @VendorID
END
GO

