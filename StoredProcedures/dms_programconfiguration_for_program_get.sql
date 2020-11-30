--exec dms_programconfiguration_for_program_get 26,3,2

 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_programconfiguration_for_program_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_programconfiguration_for_program_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  /*
 EXEC [dbo].[dms_programconfiguration_for_program_get] 479,'RegisterMember','validation'
	EXEC [dbo].[dms_programconfiguration_for_program_get] 479,'ProgramInfo',null
	EXEC [dbo].[dms_programconfiguration_for_program_get] 1,'CallScript','Welcome'

	EXEC [dbo].[dms_programconfiguration_for_program_get] 104,'InstructionScript','Estimate'

 */
 CREATE PROCEDURE [dbo].[dms_programconfiguration_for_program_get]( 
   @programID INT,
   @configurationType nvarchar(50),
   @configurationCategory nvarchar(50) = NULL
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
	
	IF @configurationType = 'ProgramInfo'
	BEGIN
		
		SELECT	'Number Called' AS Name, 
				InboundNumber AS Value, 
				'Phone' AS ControlType, 
				'Phone' AS DataType, 
				0 AS Sequence
		FROM	PhoneSystemConfiguration PSC WITH (NOLOCK)
		WHERE	ProgramID = @programID

		UNION ALL

		SELECT	AC.Name, 
				AC.Value, 
				CT.Name AS ControlType, 
				DT.Name AS DataType, 
				1 AS Sequence
		FROM	ApplicationConfiguration  AC WITH (NOLOCK)
		LEFT JOIN ControlType CT WITH (NOLOCK) ON AC.ControlTypeID = CT.ID
		LEFT JOIN DataType DT WITH (NOLOCK) ON AC.DataTypeID = DT.ID
		WHERE ApplicationConfigurationTypeID = 5 

		UNION ALL

		SELECT	PC.Name, 
				PC.Value, 
				CT.Name AS ControlType, 
				DT.Name AS DataType,  
				1 + PC.Sequence AS Sequence
		FROM ProgramConfiguration PC
		JOIN [dbo].[fnc_GetProgramConfigurationForProgram](@programID,@configurationType) P ON P.ProgramConfigurationID = PC.ID
		LEFT JOIN ConfigurationCategory C ON PC.ConfigurationCategoryID = C.ID
		LEFT JOIN ControlType CT ON PC.ControlTypeID = CT.ID
		LEFT JOIN DataType DT ON PC.DataTypeID = DT.ID
		WHERE	(@configurationCategory IS NULL OR C.Name = @configurationCategory)
		ORDER BY Sequence, Name

	END
	ELSE
	BEGIN
	
		SELECT	PC.Name, 
				PC.Value, 
				CT.Name AS ControlType, 
				DT.Name AS DataType,  
				PC.Sequence AS Sequence
		FROM ProgramConfiguration PC
		JOIN [dbo].[fnc_GetProgramConfigurationForProgram](@programID,@configurationType) P ON P.ProgramConfigurationID = PC.ID
		LEFT JOIN ConfigurationCategory C ON PC.ConfigurationCategoryID = C.ID
		LEFT JOIN ControlType CT ON PC.ControlTypeID = CT.ID
		LEFT JOIN DataType DT ON PC.DataTypeID = DT.ID
		WHERE	(@configurationCategory IS NULL OR C.Name = @configurationCategory)
		ORDER BY Sequence, Name
	
	
	END
END
