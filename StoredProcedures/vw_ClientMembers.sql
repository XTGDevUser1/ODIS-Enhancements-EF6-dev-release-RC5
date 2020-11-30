IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_ClientMembers]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_ClientMembers] 
 END 
 GO  
CREATE VIEW [dbo].[vw_ClientMembers]
AS
Select cl.ID ClientID
	,cl.Name Client
	,m.ID MemberID
	,p.ID ProgramID
	,p.Name Program
	,m.ClientMemberKey
	,ms.MembershipNumber
	,m.MemberNumber
	,m.FirstName
	,m.LastName
From Member m
Join Program p on p.ID = m.ProgramID
Join Client cl on cl.ID = p.ClientID
Join Membership ms on ms.ID = m.MembershipID
GO

