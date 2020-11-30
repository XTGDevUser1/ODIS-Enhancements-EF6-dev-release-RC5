IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_programdataitems_for_program_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_programdataitems_for_program_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_programdataitems_for_program_get] 3,'RepairContactLog'
 
CREATE PROCEDURE [dbo].[dms_programdataitems_for_program_get]( 
	@ProgramID int = NULL,   
	@screenName NVARCHAR(100) = NULL
) 
AS
BEGIN
	DECLARE @Questions TABLE(
	  QuestionID int, 
	  QuestionText nvarchar(4000),
	  ControlType nvarchar(50),
	  DataType nvarchar(50),
	  IsRequired bit,
	  MaxLength INT,
	  SubQuestionID INT,
	  RelatedAnswer NVARCHAR(MAX),
	  Sequence int
	 ) 

	INSERT INTO @Questions
	SELECT	   
		   PDI.ID,
		   PDI.Label,
		   CT.Name,
		   DT.Name,
		   PDI.IsRequired,
		   PDI.MaxLength,
		   PDL.ProgramDataItemID,              
		   PDV.Value,
		   PDI.Sequence
	FROM	ProgramDataItem PDI 
	LEFT JOIN DataType DT ON DT.ID = PDI.DataTypeID
	LEFT JOIN ControlType CT ON CT.ID = PDI.ControlTypeID
	LEFT JOIN ProgramDataItemLink PDL ON PDL.ParentProgramDataItemID = PDI.ID
	LEFT JOIN ProgramDataItemValue PDV ON PDL.ProgramDataItemValueID = PDV.ID 
	WHERE  PDI.ScreenName = @screenName
	AND		PDI.ProgramID = @ProgramID
	ORDER BY PDI.Sequence

	SELECT * FROM @Questions

END
GO