/****** Object:  UserDefinedFunction [dbo].[fnc_ETL_CaseProgramDataItem]    Script Date: 04/29/2014 02:13:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_ETL_CaseProgramDataItem]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_ETL_CaseProgramDataItem]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- DescriptiON:	Returns default product rates by locatiON
-- =============================================
CREATE FUNCTION [dbo].[fnc_ETL_CaseProgramDataItem] ()
RETURNS TABLE 
AS
RETURN 
(
	SELECT pdive.RecordID CaseID, pdi.ProgramID, pdi.Name ProgramDataItemName, pdive.Value
	FROM servicerequest sr
	JOIN [case] c ON c.id = sr.caseid
	JOIN ProgramDataItemValueEntity pdive ON pdive.entityid = 2 and pdive.recordid = c.id
	JOIN ProgramDataItem pdi ON pdi.id = pdive.ProgramDataItemID
	JOIN (
		SELECT pdive1.RecordID, pdive1.ProgramDataItemID, MAX(pdive1.id) ID
		FROM ProgramDataItemValueEntity pdive1 
		WHERE pdive1.entityid = 2
		GROUP BY pdive1.RecordID, pdive1.ProgramDataItemID
		) LastCapture ON LastCapture.RecordID = pdive.RecordID and LastCapture.ProgramDataItemID = pdive.ProgramDataItemID and LastCapture.ID = pdive.ID
)
GO
