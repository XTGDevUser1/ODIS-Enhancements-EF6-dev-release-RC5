
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_program_data_item_get_for_client_reference]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_program_data_item_get_for_client_reference] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_program_data_item_get_for_client_reference] @programID = 21, @screenName='RegisterMember'
 CREATE PROCEDURE [dbo].[dms_program_data_item_get_for_client_reference]( 
   @programID	INT = NULL
 , @screenName NVARCHAR(100) = NULL 
  
 ) 
 AS 
 BEGIN 
  
    SET NOCOUNT ON
	SELECT	PDI.Label, 
			PDIC.Name AS ControlType, 
			pdiv.[Description] AS PossibleValues,
			PDI.IsRequired
	FROM	ProgramDataItem PDI WITH (NOLOCK)
	JOIN	dbo.fnc_GetProgramDataItemsForProgram(@programID,@screenName) FP ON FP.ProgramDataItemID = PDI.ID 
	JOIN	ControlType PDIC WITH (NOLOCK) ON PDIC.ID = PDI.ControlTypeID
	JOIN	DataType PDID WITH (NOLOCK) ON PDID.ID = PDI.DataTypeID
	LEFT JOIN ProgramDataItemValue PDIV WITH (NOLOCK) ON PDIV.ProgramDataItemID = PDI.ID
	ORDER BY 
			PDI.Sequence, 
			PDIV.sequence

END
