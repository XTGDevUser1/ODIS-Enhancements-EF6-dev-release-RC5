/****** Object:  UserDefinedFunction [dbo].[fnSplitString]    Script Date: 09/13/2010 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnSplitString]') 
AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
 DROP FUNCTION [dbo].[fnSplitString]
GO
/*
SELECT * FROM [dbo].[fnSplitString]('FWA,AVN',',')
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fnSplitString]
(
@sInputList VARCHAR(8000) -- List of delimited items
,@sDelimiter VARCHAR(8000) = ',' -- delimiter that separates items
)
RETURNS @List TABLE (item VARCHAR(8000))
AS

BEGIN

DECLARE @sItem VARCHAR(8000)

WHILE CHARINDEX(@sDelimiter,@sInputList,0) <> 0

 BEGIN

 SELECT

  @sItem=RTRIM(LTRIM(SUBSTRING(@sInputList,1,CHARINDEX(@sDelimiter,@sInputList,0)-1))),

  @sInputList=RTRIM(LTRIM(SUBSTRING(@sInputList,CHARINDEX(@sDelimiter,@sInputList,0)+LEN(@sDelimiter),LEN(@sInputList))))
 

 IF LEN(@sItem) > 0

  INSERT INTO @List SELECT @sItem

 END 

IF LEN(@sInputList) > 0

 INSERT INTO @List SELECT @sInputList -- Put the last item in

RETURN

END
