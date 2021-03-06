

/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ClosedLoopActivity_get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_ClosedLoopActivity_get]
GO



-- EXEC [dbo].[dms_clients_get] '20EE6D5C-6B06-43E1-A723-D53FD6D593B5'
-- EXEC [dbo].[dms_clients_get] 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
GO
/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 07/03/2012 18:54:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[dms_ClosedLoopActivity_get](@ServiceRequestID int = NULL )
AS
BEGIN
	
	SELECT DISTINCT CLA.CREATEDATE, CA.[DESCRIPTION] FROM CONTACTLOGACTION CLA
  JOIN CONTACTLOG CL ON CL.ID = CLA.CONTACTLOGID 
  JOIN CONTACTLOGLINK CLL ON CLL.CONTACTLOGID = CL.ID AND CLL.RECORDID = @ServiceRequestID
  JOIN ENTITY E ON E.ID = CLL.ENTITYID AND E.NAME = 'SERVICEREQUEST' 
  JOIN CONTACTCATEGORY CC ON CC.ID = CL.CONTACTCATEGORYID AND CC.NAME = 'CLOSEDLOOP'
  JOIN CONTACTACTION CA ON CA.ID = CLA.CONTACTACTIONID 
  ORDER BY CLA.CREATEDATE DESC
	   	
END
GO

