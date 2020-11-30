

/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_clients_get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_clients_get]
GO



-- EXEC [dbo].[dms_clients_get] '20EE6D5C-6B06-43E1-A723-D53FD6D593B5'
-- EXEC [dbo].[dms_clients_get] 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
GO
/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 07/03/2012 18:54:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[dms_clients_get](@userID uniqueidentifier = NULL )
AS
BEGIN
	
	--Declare Results
	DECLARE @Results TABLE 
	( 
	   ClientID INT, 
	   ClientName VARCHAR(50) 
	)
 	

	SELECT DISTINCT C.[ID] AS ClientID ,C.[Name] as ClientName 
	FROM fnc_GetOrganizationsForUser(@userID) fO
	JOIN  OrganizationClient O ON fO.OrganizationID = O.OrganizationID
	JOIN Client C ON C.ID = O.ClientID 
	WHERE C.IsActive = 1
    ORDER BY C.Name
	   	
END