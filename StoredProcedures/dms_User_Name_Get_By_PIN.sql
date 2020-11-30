/****** Object:  StoredProcedure [dbo].[dms_POThresholdPercentage_Get]    Script Date: 06/09/2016 16:50:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_User_Name_Get_By_PIN]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_User_Name_Get_By_PIN]
GO

/****** Object:  StoredProcedure [dbo].[dms_User_Name_Get_By_PIN]    Script Date: 06/09/2016 16:50:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
/*
	EXEC [dms_User_Name_Get_By_PIN] 9999

*/
CREATE PROCEDURE [dbo].[dms_User_Name_Get_By_PIN] (
	@PIN INT = NULL
)
AS
BEGIN
	SELECT u.ID AS UserID, au.Username FROM [User] u JOIN aspnet_Users au ON au.UserID = u.aspnet_UserID JOIN aspnet_Membership m ON m.UserID = au.UserID WHERE u.PIN = @PIN AND m.IsApproved=1
END