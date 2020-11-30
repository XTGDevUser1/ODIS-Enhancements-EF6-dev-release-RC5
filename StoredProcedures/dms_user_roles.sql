
/****** Object:  StoredProcedure [dbo].[dms_user_roles]    Script Date: 06/15/2012 21:23:03 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_user_roles]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_user_roles]
GO



/****** Object:  StoredProcedure [dbo].[dms_user_roles]    Script Date: 06/15/2012 21:23:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[dms_user_roles](@organizationID int)
AS
BEGIN
  
   SELECT [RoleId],[RoleName] FROM aspnet_Roles 
						      WHERE 
							  RoleId IN (SELECT RoleId FROM OrganizationRole WHERE OrganizationID = @organizationID)
END
GO



 GO
