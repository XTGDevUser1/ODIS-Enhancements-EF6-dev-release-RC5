/****** Object:  StoredProcedure [dbo].[Mobile_logAccess_Insert]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Mobile_logAccess_Insert]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Mobile_logAccess_Insert] 
 END 
 GO  
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Mobile_logAccess_Insert]
 	@memberNumber nvarchar(50)=null,
 	@GUID nvarchar(50)=null,
 	@memberDeviceGUID nvarchar(255)=null,
 	@validGUID bit=null,
 	@deviceType nvarchar(25)=null,
 	@applicationVersion nvarchar(25)=null,
 	@dispatchPhNo nvarchar(20)=null,
 	@errorCode int=null,
 	@errorMessage nvarchar(200)=null,
 	@appOrgName nvarchar(5)=null
AS
BEGIN
	Insert into mobile_logAccess(
	memberNumber,
	guid,
	memberDeviceGUID,
	validguid,
	deviceType,
	applicationVersion,
	dispatchPhoneNo,
	errorCode,
	errorMessage,
	appOrgName
	)
	values(
	@memberNumber ,
 	@GUID,
 	@memberDeviceGUID ,
 	@validGUID ,
 	@deviceType,
 	@applicationVersion,
 	@dispatchPhNo,
 	@errorCode ,
 	@errorMessage,
 	@appOrgName  
	)
	
	
END



/****** Object:  StoredProcedure [dbo].[Mobile_Registration_Insert]    Script Date: 03/01/2013 13:12:22 ******/
SET ANSI_NULLS ON
GO
