USE [DMS]
GO
/****** Object:  UserDefinedFunction [dbo].[fnc_ETL_ServiceRequestContactAction]    Script Date: 04/08/2013 15:00:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Description:	Returns default product rates by location
-- =============================================
ALTER FUNCTION [dbo].[fnc_ETL_ServiceRequestContactAction] ()
RETURNS TABLE 
AS
RETURN 
(
	SELECT sr.id ServiceRequestID, cc.ID ContactCategoryID, cc.Name ContactCategoryName, ca.ID ContactActionID, ca.Name ContactActionName
	FROM contactlog cl
	JOIN contactloglink cll on cl.id = cll.contactlogid and cll.EntityID = (select ID from Entity where Name = 'ServiceRequest')
	JOIN servicerequest sr on sr.id = cll.recordid
	JOIN contactcategory cc on cl.contactcategoryid = cc.id
	JOIN contactlogReason clr on cl.id = clr.contactlogid
	JOIN contactreason cr on clr.ContactReasonID = cr.ID
	JOIN contactlogaction cla on cl.id = cla.contactlogid
	JOIN contactaction ca on cla.ContactActionID = ca.ID
	GROUP BY sr.id, cc.ID, cc.Name, ca.ID, ca.Name
)

