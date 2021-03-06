/****** Object:  StoredProcedure [dbo].[dms_ClientPortal_program_list]    Script Date: 04/29/2014 02:13:21 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ClientPortal_program_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ClientPortal_program_list] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [dbo].[dms_ClientPortal_program_list] 18
CREATE PROCEDURE [dbo].[dms_ClientPortal_program_list] (
	@clientID	INT
 ) 
AS
BEGIN
	SELECT [ID],
		   [Name],
		   [Description] FROM Program (NOLOCK)
	WHERE ClientID = @ClientID
	AND IsActive = 1
	AND IsWebRegistrationEnabled = 1
	AND IsGroup <> 1
	ORDER BY Name
END
GO
