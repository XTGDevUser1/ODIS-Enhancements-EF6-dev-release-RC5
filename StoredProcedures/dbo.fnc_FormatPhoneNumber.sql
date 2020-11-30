
/****** Object:  UserDefinedFunction [dbo].[fnc_FormatPhoneNumber]    Script Date: 12/10/2012 20:03:06 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_FormatPhoneNumber]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_FormatPhoneNumber]
GO

USE [DMS]
GO

/****** Object:  UserDefinedFunction [dbo].[fnc_FormatPhoneNumber]    Script Date: 12/10/2012 20:03:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fnc_FormatPhoneNumber](@PhoneNo NVARCHAR(20), @IncludeCountryCode BIT = 0)
RETURNS NVARCHAR(25)
AS
BEGIN
DECLARE @Formatted NVARCHAR(25)
DECLARE @SpacePos INT = 1
DECLARE @ExtensionPos INT

IF @IncludeCountryCode = 0
		BEGIN
			IF (LEN(@PhoneNo) < 10)
				SET @Formatted = @PhoneNo
			ELSE
				BEGIN
				    SET @Formatted = LTRIM(RTRIM(@PhoneNo))
				    SET @SpacePos = CHARINDEX(' ',@Formatted,0)
				    SET @Formatted = SUBSTRING(@Formatted, @SpacePos + 1, LEN(@Formatted) - @SpacePos)
				    SET @ExtensionPos = CHARINDEX('x',@Formatted,0)
					IF @ExtensionPos > 0 
						SET @Formatted = LEFT(@Formatted, 3) + '-' + SUBSTRING(@Formatted, 4, 3) + '-' + RIGHT(@Formatted, 5 + (LEN(@Formatted) - @ExtensionPos))
					ELSE
						SET @Formatted = LEFT(@Formatted, 3) + '-' + SUBSTRING(@Formatted, 4, 3) + '-' + RIGHT(@Formatted, 4)
				END
		END
ELSE
		BEGIN
			IF (LEN(@PhoneNo) < 12)
				SET @Formatted = @PhoneNo
			ELSE	
				BEGIN
				
					SET @Formatted = LTRIM(RTRIM(@PhoneNo))
					SET @SpacePos = CHARINDEX(' ',@Formatted,0)
					SET @ExtensionPos = CHARINDEX('x',@Formatted,0)
					IF @ExtensionPos > 0 
						SET @Formatted = SUBSTRING(@Formatted, 0, @SpacePos) + '-' + SUBSTRING(@Formatted, @SpacePos + 1, 3) + '-' + SUBSTRING(@Formatted, @SpacePos + 4, 3) + '-' + RIGHT(@Formatted, 5 + (LEN(@Formatted) - @ExtensionPos))
					ELSE
						SET @Formatted = SUBSTRING(@Formatted, 0, @SpacePos) + '-' + SUBSTRING(@Formatted, @SpacePos + 1, 3) + '-' + SUBSTRING(@Formatted, @SpacePos + 4, 3) + '-' + RIGHT(@Formatted, 4)	
				END
		END
			
RETURN @Formatted
END
