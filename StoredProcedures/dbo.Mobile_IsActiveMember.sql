/****** Object:  StoredProcedure [dbo].[Mobile_IsActiveMember]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Mobile_IsActiveMember]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Mobile_IsActiveMember] 
 END 
 GO  
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Mobile_IsActiveMember] 
	@memberNumber as nvarchar(50)=null
AS
BEGIN

Declare @noOfRecs int=0
Declare @MemberNumberNoPreceedingZeros varchar(50)
set @MemberNumberNoPreceedingZeros = REPLACE(LTRIM(REPLACE(@MemberNumber, '0', ' ')), ' ', '0')


	SELECT @noOfRecs = count(*)
		FROM Member M
		LEFT JOIN Membership MS ON MS.ID = M.MembershipID
		WHERE MS.MembershipNumber IN (@MemberNumber,@MemberNumberNoPreceedingZeros) 
		AND m.IsPrimary = 1
		--and m.ExpirationDate >= getdate()
		and m.ExpirationDate >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
		  
		if @noOfRecs > 0 
		Begin
		  select 1
		END
		else
		Begin
		  select 0
		END

/* - code replaced with the above on 12/5/2013 - Rob Mc - old code below

Declare @noOfRecs int=0

	SELECT @noOfRecs = count(*)
		FROM Member M
		LEFT JOIN Membership MS ON MS.ID = M.MembershipID
		WHERE MS.MembershipNumber =  @memberNumber
		AND m.IsPrimary = 1
		and m.ExpirationDate >= getdate()
		
		if @noOfRecs > 0 
		Begin
		  select 1
		END
		else
		Begin
		  select 0
		END
*/
	
end
GO
