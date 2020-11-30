IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_DynamicFields]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_DynamicFields]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_Program_DynamicFields 224,'RegisterMember'
CREATE PROC [dbo].[dms_Program_DynamicFields](@programID int = NULL,@screenName NVARCHAR(50) = NULL)
AS
BEGIN

;WITH wPDIs
AS
(	
	SELECT 
	ROW_NUMBER() OVER (Partition BY PDI.Name ORDER BY PDI.Name ASC, PDI.ID DESC) AS RowNum
	, pdi.ID
	, pdi.Name
	, pdi.ScreenName
	, pdi.Sequence as FieldSequence
	, pdi.Label, pdi.IsRequired
	, pdic.Name as ControlType
	, pdid.name as DataType, pdi.MaxLength
	, pdiv.Description as Value
	, pdiv.Sequence as ValueSequence
	FROM fnc_GetProgramDataItemsForProgram(@programid, @screenname) fP
	JOIN ProgramDataItem pdi on pdi.ID = fP.ProgramDataItemID 
	join ControlType pdic on pdic.ID = pdi.ControlTypeID
	join DataType pdid on pdid.ID = pdi.DataTypeID
	left join ProgramDataItemValue pdiv on pdiv.ProgramDataItemID = pdi.ID
	WHERE	ISNULL(pdi.IsActive,0) = 1
	AND		ISNULL(pdic.IsActive,0) = 1	
)

	
	SELECT 	
		W.ID
	,	W.Name
	,	W.ScreenName
	,	W.FieldSequence
	,	W.Label
	,	W.IsRequired
	,	W.ControlType
	,	W.DataType 
	,	W.[MaxLength]
	,	W.Value
	,	W.ValueSequence
	FROM	wPDIs W
	WHERE	W.RowNum = 1
	ORDER BY W.FieldSequence, W.ValueSequence

END


