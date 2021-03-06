/****** Object:  StoredProcedure [dbo].[Mobile_Registration_Insert]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Mobile_Registration_Insert]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Mobile_Registration_Insert] 
 END 
 GO  
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Mobile_Registration_Insert]
 	@memberNumber nvarchar(50)=null,
 	@GUID nvarchar(50)=null,
 	@memberDeviceGUID nvarchar(255)=null,
 	@firstName nvarchar(50)=null,
 	@lastName nvarchar(50)=null,
 	@MemberDevicePhoneNumber nvarchar(20)=null,
 	@validGUID bit=null,
 	@activeMember  bit=null,
 	@memberExist bit=null,
 	@validRegistration bit=null,
 	@ErrorCode int=null,
 	@ErrorMessage nvarchar(200)=null,
 	@dispatchPhNo nvarchar(20)=null,
 	@appOrgName nvarchar(5)=null
AS
BEGIN
	Insert into mobile_registration(
	memberNumber,
	guid,
	memberdeviceguid,
	firstname,
	lastname,
	MemberDevicePhoneNumber,
	validguid,
	activemember,
	MemberExist,
	ValidRegistration,
	Errorcode,
	Errormessage,
	dispatchPhoneNo,
	appOrgName
	)
	values(
	@memberNumber ,
 	@GUID,
 	@memberDeviceGUID,
 	@firstName ,
 	@lastName ,
 	@MemberDevicePhoneNumber ,
 	@validGUID ,
 	@activeMember ,
 	@memberExist,
 	@validRegistration,
 	@ErrorCode,
 	@ErrorMessage,
 	@dispatchPhNo,
 	@appOrgName 
	)
	
	
END
GO
