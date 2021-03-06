/****** Object:  UserDefinedFunction [dbo].[fnc_ProperCase]    Script Date: 04/29/2014 02:13:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_ProperCase]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_ProperCase]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnc_ProperCase] (@InputString VARCHAR(4000) )
RETURNS VARCHAR(4000)
AS
BEGIN
	DECLARE @Index INT
	DECLARE @Char CHAR(1)
	DECLARE @OutputString VARCHAR(255)
	
	SET @OutputString = LOWER(@InputString)
	SET @Index = 2
	SET @OutputString =	STUFF(@OutputString, 1, 1,UPPER(SUBSTRING(@InputString,1,1)))
	
	WHILE @Index <= LEN(@InputString)
	BEGIN
		SET @Char = SUBSTRING(@InputString, @Index, 1)
		IF @Char IN (' ', ';', ':', '!', '?', ',', '.', '_', '-', '/', '&','''','(')
			IF @Index + 1 <= LEN(@InputString)
			BEGIN
				IF @Char != '''' OR UPPER(SUBSTRING(@InputString, @Index + 1, 1)) != 'S'
				SET @OutputString = STUFF(@OutputString, @Index + 1, 1,UPPER(SUBSTRING(@InputString, @Index + 1, 1)))
			END
		SET @Index = @Index + 1
	END
	RETURN ISNULL(@OutputString,'')
END
GO
