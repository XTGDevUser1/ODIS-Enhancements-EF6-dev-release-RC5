IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnIsUserConnected]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnIsUserConnected]
GO

CREATE FUNCTION dbo.fnIsUserConnected(@userName NVARCHAR(MAX)) RETURNS BIT
AS
BEGIN
	DECLARE @IsUserConnected BIT = 0

	IF((SELECT COUNT(NotificationID) FROM DesktopNotifications WHERE UserName = @userName AND IsConnected = 1) > 0)
	BEGIN
		SET @IsUserConnected = 1
	END

	RETURN @IsUserConnected
END

