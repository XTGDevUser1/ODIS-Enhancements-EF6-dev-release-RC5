

/****** Object:  StoredProcedure [dbo].[dms_users_organization]    Script Date: 06/15/2012 21:23:12 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_users_organization]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_users_organization]
GO
-- EXEC [dbo].[dms_users_organization] 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'

/****** Object:  StoredProcedure [dbo].[dms_users_organization]    Script Date: 06/15/2012 21:23:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[dms_users_organization](@userID uniqueidentifier)
AS
BEGIN

	SELECT OrganizationID as ID, Name FROM dbo.fnc_GetOrganizationsForUser(@userID)
	   		
END





GO

