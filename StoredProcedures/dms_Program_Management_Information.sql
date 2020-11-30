IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Program_Management_Information]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Program_Management_Information] 
END 
GO
CREATE PROC dms_Program_Management_Information(@ProgramID INT = NULL)
AS
BEGIN
	SELECT   
			   P.ID ProgramID
			 , C.ID AS ClientID
			 , C.Name AS ClientName
			 , P.ParentProgramID AS ParentID
			 , PP.Name AS ParentName
			 , P.Name AS ProgramName
			 , P.Description AS ProgramDescription
			 , P.IsActive AS IsActive
			 , P.Code AS Code
			 , P.IsServiceGuaranteed			
			 , P.CallFee
			 , P.DispatchFee
			 , P.IsAudited
			 , P.IsClosedLoopAutomated
			 , P.IsGroup
			 , P.IsWebRegistrationEnabled
			 , P.CreateBy
			 , P.CreateDate
			 , P.ModifyBy
			 , P.ModifyDate
			 , '' AS PageMode
	FROM       Program P (NOLOCK)
	JOIN       Client C (NOLOCK) ON C.ID = P.ClientID
	LEFT JOIN  Program PP (NOLOCK) ON PP.ID = P.ParentProgramID
	WHERE      P.ID = @ProgramID
END

