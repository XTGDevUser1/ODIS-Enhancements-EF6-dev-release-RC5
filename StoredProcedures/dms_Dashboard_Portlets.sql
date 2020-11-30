IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Dashboard_Portlets]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Dashboard_Portlets] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO


CREATE PROC [dbo].[dms_Dashboard_Portlets](@loggedInUserID UNIQUEIDENTIFIER = NULL)
AS
BEGIN

	DECLARE @Result AS TABLE(PortletID INT NOT NULL,
							 SecurableID INT NOT NULL,
							 FriendlyName NVARCHAR(MAX) NULL,
							 TargetAction NVARCHAR(MAX),
							 TargetController NVARCHAR(MAX),
							 TargetArea NVARCHAR(MAX),
							 ColumnPosition INT NOT NULL,
							 RowPosition INT NOT NULL,
							 Name NVARCHAR(MAX),
							 Description NVARCHAR(MAX),
							 IsShownOnSetting BIT NOT NULL,
							 PortletSectionID INT NOT NULL,
							 IsActive BIT NOT NULL)

	DECLARE @userRole NVARCHAR(128)
	SET     @userRole = (SELECT TOP 1 RoleId FROM aspnet_UsersInRoles WHERE UserId =  @loggedInUserID)
	INSERT INTO @Result
	SELECT		P.ID PortletID,
				P.SecurableID,
				S.FriendlyName,
				P.TargetAction,
				P.TargetController,
				P.TargetArea,
				COALESCE(UPD.ColumnPosition,UP.ColumnPosition,P.ColumnPosition) AS ColumnPosition,
				COALESCE(UPD.RowPosition,UP.RowPosition,P.RowPosition) AS RowPosition ,
				P.Name,
				P.Description,
				ISNULL(P.IsShownOnSetting,0) IsShownOnSetting,
				COALESCE(UPD.PortletSectionID,UP.PortletSectionID,P.PortletSectionID) AS PortletSectionID,
				ISNULL(UP.IsActive,1) IsActive
				FROM Portlet P  WITH (NOLOCK)
	LEFT JOIN	Securable S WITH (NOLOCK) ON P.SecurableID = S.ID
	LEFT JOIN	UserPortletDefaultByRole UPD WITH (NOLOCK) ON P.ID = UPD.PortletID AND UPD.RoleID = @userRole
	LEFT JOIN	UserPortlet UP WITH (NOLOCK) ON P.ID = UP.PortletID AND UP.AspNetUsersID = @loggedInUserID

	--Remove this Logic When in Production event it's available no issues
	--It's written becuase currently we don't have records in USerPorlet.
	-- When we know that we are going to have record then it's can be taken off.
	IF NOT EXISTS (SELECT * FROM  UserPortlet WHERE AspNetUsersID = @loggedInUserID)
	BEGIN
		INSERT INTO UserPortlet 
		SELECT @loggedInUserID,
			   R.PortletID,
			   R.ColumnPosition,
			   R.RowPosition,
			   1,
			   R.PortletSectionID
		FROM  @Result R
	END

	SELECT * FROM @Result
END








