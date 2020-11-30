USE [DMS]
GO

/****** Object:  View [dbo].[vw_MemberSearchLog]    Script Date: 04/26/2016 06:53:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

Create View [dbo].[vw_MemberSearchLog]
AS

	Select l.[Date]
	,Substring(l.[Message], CHARINDEX('MemberController - _Search(), Parameters', l.[Message]), LEN('MemberController - _Search(), Parameters')) MemberSearchIdentifier
	,RTRIM(LTRIM(Substring(l.[Message], CHARINDEX('[', l.[Message]) + 1,  CHARINDEX(']', l.[Message]) - CHARINDEX('[', l.[Message]) - 1 ))) Username
	,Substring(l.[Message], CHARINDEX(',"MemberNumber":', l.[Message]) + LEN(',"MemberNumber":'), CHARINDEX(',"LastName":', l.[Message]) - CHARINDEX(',"MemberNumber":', l.[Message]) - LEN(',"MemberNumber":')) MemberNumber
	,Substring(l.[Message], CHARINDEX(',"LastName":', l.[Message]) + LEN(',"LastName":'), CHARINDEX(',"FirstName":', l.[Message]) - CHARINDEX(',"LastName":', l.[Message]) - LEN(',"LastName":')) LastName
	,Substring(l.[Message], CHARINDEX(',"FirstName":', l.[Message]) + LEN(',"FirstName":'), CHARINDEX(',"MemberProgramID":', l.[Message]) - CHARINDEX(',"FirstName":', l.[Message]) - LEN(',"FirstName":')) FirstName
	,Substring(l.[Message], CHARINDEX(',"MemberProgramID":', l.[Message]) + LEN(',"MemberProgramID":'), CHARINDEX(',"ProgramID":', l.[Message]) - CHARINDEX(',"MemberProgramID":', l.[Message]) - LEN(',"MemberProgramID":')) MemberProgramID
	,CONVERT(int,Substring(l.[Message], CHARINDEX(',"ProgramID":', l.[Message]) + LEN(',"ProgramID":'), CHARINDEX(',"Phone":', l.[Message]) - CHARINDEX(',"ProgramID":', l.[Message]) - LEN(',"ProgramID":'))) ProgramID
	,(Select Name From Program Where ID = CONVERT(int,Substring(l.[Message], CHARINDEX(',"ProgramID":', l.[Message]) + LEN(',"ProgramID":'), CHARINDEX(',"Phone":', l.[Message]) - CHARINDEX(',"ProgramID":', l.[Message]) - LEN(',"ProgramID":')))) Program
	,Substring(l.[Message], CHARINDEX(',"Phone":', l.[Message]) + LEN(',"Phone":'), CHARINDEX(',"VIN":', l.[Message]) - CHARINDEX(',"Phone":', l.[Message]) - LEN(',"Phone":')) Phone
	,Substring(l.[Message], CHARINDEX(',"VIN":', l.[Message]) + LEN(',"VIN":'), CHARINDEX(',"State":', l.[Message]) - CHARINDEX(',"VIN":', l.[Message]) - LEN(',"VIN":')) VIN
	,Substring(l.[Message], CHARINDEX(',"State":', l.[Message]) + LEN(',"State":'), CHARINDEX(',"ZipCode":', l.[Message]) - CHARINDEX(',"State":', l.[Message]) - LEN(',"State":')) State
	,Substring(l.[Message], CHARINDEX(',"ZipCode":', l.[Message]) + LEN(',"ZipCode":'), CHARINDEX(',"MemberFoundFromMobile":', l.[Message]) - CHARINDEX(',"ZipCode":', l.[Message]) - LEN(',"ZipCode":')) ZipCode
	,Substring(l.[Message], CHARINDEX(',"MemberFoundFromMobile":', l.[Message]) + LEN(',"MemberFoundFromMobile":'), CHARINDEX(',"CommaSepratedMemberIDList":', l.[Message]) - CHARINDEX(',"MemberFoundFromMobile":', l.[Message]) - LEN(',"MemberFoundFromMobile":')) MemberFoundFromMobile
	,Case WHEN CHARINDEX(',"EmployeeInd":', l.[Message]) <> 0 THEN 
		Substring(l.[Message], CHARINDEX(',"CommaSepratedMemberIDList":', l.[Message]) + LEN(',"CommaSepratedMemberIDList":'), CHARINDEX(',"EmployeeInd":', l.[Message]) - CHARINDEX(',"CommaSepratedMemberIDList":', l.[Message]) - LEN(',"CommaSepratedMemberIDList":')) 
		ELSE NULL END CommaSepratedMemberIDList
	,Substring(l.[Message], CHARINDEX(',"EmployeeInd":', l.[Message]) + LEN(',"EmployeeInd":'), LEN(l.[Message]) - (CHARINDEX(',"EmployeeInd":', l.[Message]) + LEN(',"EmployeeInd":') + 1)) EmployeeInd
	--,l.[Message]
	from dbo.[log] l
	where 1=1
	and Substring(l.[Message], CHARINDEX('MemberController - _Search(), Parameters', l.[Message]), LEN('MemberController - _Search(), Parameters')) = 'MemberController - _Search(), Parameters'



GO

