/****** Object:  StoredProcedure [dbo].[Mobile_memberExist]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Mobile_memberExist]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Mobile_memberExist] 
 END 
 GO  
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Mobile_memberExist] 
@memberNumber as nvarchar(50)=null,
@memberLastName as nvarchar(50)=null
AS
BEGIN



Declare @MemberNumberNoPreceedingZeros varchar(50)
set @MemberNumberNoPreceedingZeros = REPLACE(LTRIM(REPLACE(@MemberNumber, '0', ' ')), ' ', '0')

	SELECT DISTINCT COUNT(*)
		FROM Member M
		LEFT JOIN Membership MS ON MS.ID = M.MembershipID
		WHERE MS.MembershipNumber IN (@MemberNumber,@MemberNumberNoPreceedingZeros) 
		AND m.LastName = @memberLastName


/* - code replaced with the above on 12/5/2013 - Rob Mc - old code below

	SELECT DISTINCT COUNT(*)
		FROM Member M
		LEFT JOIN Membership MS ON MS.ID = M.MembershipID
		WHERE MS.MembershipNumber =  @memberNumber
		AND m.LastName = @memberLastName
*/

   
end
GO
