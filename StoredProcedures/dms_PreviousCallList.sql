
/****** Object:  StoredProcedure [dbo].[dms_PreviousCallList]    Script Date: 08/17/2012 19:43:46 ******/

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_PreviousCallList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_PreviousCallList]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[dms_PreviousCallList](@RecordID int)
AS
BEGIN
declare @entityID INT
SET @entityID = (SELECT ID FROM Entity WHERE [Name] LIKE 'EmergencyAssistance%')
SELECT CS.ID AS ContactSourceID,
	   CS.Description AS ContactSourceName,
	   CL.ID AS ContactLogID,
	   CL.Company,
	   CL.TalkedTo,
	   CL.PhoneNumber,
	   CL.CreateDate,
	   CL.CreateBy,
	   CA.Name AS ContactActionName
FROM ContactLog CL
INNER JOIN ContactLogLink CLL ON CLL.ContactLogID = CL.ID
INNER JOIN ContactSource CS ON CL.ContactSourceID = CS.ID
INNER JOIN ContactLogAction CLA ON CLA.ContactLogID = CL.ID
INNER JOIN ContactAction CA ON CA.ID = CLA.ContactActionID
WHERE CLL.EntityID = @entityID AND CLL.RecordID = @RecordID
ORDER BY CL.CreateDate
END

