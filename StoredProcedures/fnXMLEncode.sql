IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnXMLEncode]') 
AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
 DROP FUNCTION [dbo].[fnXMLEncode]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--SELECT [dbo].[fnXMLEncode]('K & N')
 CREATE FUNCTION [dbo].[fnXMLEncode] 
 (
	@str NVARCHAR(MAX)
 )
 RETURNS NVARCHAR(MAX)
 AS
 BEGIN

	DECLARE @encodedString NVARCHAR(MAX) = ''

	IF LEN(LTRIM(RTRIM(@str))) = 0
		RETURN @encodedString 

	SET @encodedString =  (SELECT  @str FOR XML PATH(''))

	RETURN @encodedString

 END


