IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Message_Get]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Message_Get] 
END 

GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_Message_Get](@messageScope NVARCHAR(100))
AS
BEGIN
	SELECT * FROM [Message]
	WHERE MessageScope = @messageScope
	AND   IsActive = 1
	ORDER BY
	[StartDate] DESC,
	[Sequence] ASC
END

