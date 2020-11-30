
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_SecurablePermissions]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_SecurablePermissions]
	GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE function fn_SecurablePermissions(@SecurableID INT) RETURNS @Permission TABLE(SecurableID INT,Permission NVARCHAR(MAX))
AS
BEGIN
	DECLARE @ResultTemp AS TABLE(SecurableID INT, 
								 SecurableName NVARCHAR(MAX), 
								 AccessTypeID INT,
								 AccessTypeName NVARCHAR(MAX),
								 RoleID UNIQUEIDENTIFIER,
								 RoleName NVARCHAR(MAX))

	INSERT INTO @ResultTemp
	SELECT		ACL.SecurableID,
				S.FriendlyName,
				ACL.AccessTypeID,
				AT.Name,
				ACL.RoleID,
				AR.RoleName
	FROM		AccessControlList ACL
	LEFT JOIN Securable S ON ACL.SecurableID = S.ID
	LEFT JOIN AccessType AT ON AT.ID = ACL.AccessTypeID
	LEFT JOIN aspnet_Roles AR ON ACL.RoleID = AR.RoleId
	LEFT JOIN aspnet_Applications AP ON AR.ApplicationId = AP.ApplicationId
	WHERE AP.ApplicationName = 'DMS'
	AND  ACL.SecurableID = @SecurableID

	;WITH wTemp AS(
					SELECT SecurableID,
						   SecurableName,
						   AccessTypeID,
						   AccessTypeName,
						   AccessTypeName  + ' : ' +
						   STUFF((SELECT	 '| '  + RoleName 
											  FROM @ResultTemp B
											  WHERE B.AccessTypeID = A.AccessTypeID 
											  ORDER BY RoleName
											  FOR XML PATH('')), 1, 2, '') As AllPermissions
					FROM @ResultTemp A
					GROUP BY 
					SecurableID,
					SecurableName,
					AccessTypeID,
					AccessTypeName
	)
	INSERT INTO @Permission
	SELECT  	W.SecurableID,
			    STUFF((SELECT	 ', '  +	  AllPermissions 
											  FROM wTemp B
											  ORDER BY B.AccessTypeName
											  FOR XML PATH('')), 1, 2, '')
	FROM	    wTemp W
	GROUP BY W.SecurableID
	RETURN
END


