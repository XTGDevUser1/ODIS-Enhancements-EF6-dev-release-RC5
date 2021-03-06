/****** Object:  StoredProcedure [dbo].[Mobile_callForService_Insert]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Mobile_callForService_Insert]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Mobile_callForService_Insert] 
 END 
 GO  GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Mobile_callForService_Insert]
 	@memberNumber nvarchar(50)=null,
 	@GUID nvarchar(50)=null,
 	@memberDeviceGUID nvarchar(255)=null,
 	@firstName nvarchar(50)=null,
 	@lastName nvarchar(50)=null,
 	@MemberDevicePhoneNumber nvarchar(20)=null,
 	@locationLatitude nvarchar(10)=null,
 	@locationLongtitude nvarchar(10)=null,
 	@serviceType nvarchar(100)=null,
 	@ErrorCode int=null,
 	@ErrorMessage nvarchar(200)=null,
 	@appOrgName nvarchar(5)=null,
 	@PKID int output 
 	
AS
BEGIN
	Insert into Mobile_callForService(
	memberNumber,
	guid,
	memberDeviceGUID,
	firstname,
	lastname,
	MemberDevicePhoneNumber,
	locationLatitude,
	locationLongtitude,
	serviceType,
	Errorcode,
	Errormessage,
	appOrgName
	)
	values(
	@memberNumber ,
 	@GUID,
 	@memberDeviceGUID,
 	@firstName ,
 	@lastName ,
 	@MemberDevicePhoneNumber ,
 	@locationLatitude ,
 	@locationLongtitude ,
 	@serviceType ,
 	@ErrorCode,
 	@ErrorMessage,
 	@appOrgName 
 	)
	
	Select @PKID = @@Identity
END



/****** Object:  StoredProcedure [dbo].[Mobile_logAccess_Insert]    Script Date: 03/01/2013 13:12:09 ******/
SET ANSI_NULLS ON
GO
