IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Member_From_Mobile_CallForService_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Member_From_Mobile_CallForService_Get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC dms_Member_From_Mobile_CallForService_Get '4192232323'
 CREATE PROCEDURE [dbo].[dms_Member_From_Mobile_CallForService_Get](
 @phoneNumber NVARCHAR(100)
 )
 AS
 BEGIN
 
	SELECT	TOP 1 * 
	FROM	Mobile_CallForService M
	WHERE	REPLACE(M.MemberDevicePhoneNumber,'-','') = @phoneNumber
	AND		DATEDIFF(hh,M.[DateTime],GETDATE()) < 1
	AND		ISNULL(M.ErrorCode,0) = 0
	ORDER BY 
	M.[DateTime] DESC
 
 END 