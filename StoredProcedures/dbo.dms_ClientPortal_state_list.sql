/****** Object:  StoredProcedure [dbo].[dms_ClientPortal_state_list]    Script Date: 04/29/2014 02:13:21 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ClientPortal_state_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ClientPortal_state_list] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_ClientPortal_state_list](@countryID INT = NULL)
AS
BEGIN
	SELECT [ID],
		   [Name],
		   [Abbreviation] FROM StateProvince(NOLOCK)
	WHERE (@countryID IS NULL) OR (CountryID = @countryID)
	ORDER BY Sequence ASC
END
GO
