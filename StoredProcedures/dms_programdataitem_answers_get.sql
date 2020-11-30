IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_programdataitem_answers_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_programdataitem_answers_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_programdataitem_answers_get] 81,'RepairContactLog'
 
CREATE PROCEDURE [dbo].[dms_programdataitem_answers_get]( 
	@ProgramID int = NULL,   
	@screenName NVARCHAR(100) = NULL
) 
AS
BEGIN
	
	SELECT  PDI.ID As ProgramDataItemID,
			PDIV.ID As ProgramDataItemValueID,
			PDIV.Value,
			PDIV.Sequence
	FROM	ProgramDataItemValue PDIV
	JOIN	ProgramDataItem PDI ON PDIV.ProgramDataItemID = PDI.ID
	WHERE	PDI.ScreenName = @screenName
	AND		PDI.ProgramID = @ProgramID
	ORDER BY PDIV.Sequence

END
GO