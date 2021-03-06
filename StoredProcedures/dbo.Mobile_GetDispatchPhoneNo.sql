/****** Object:  StoredProcedure [dbo].[Mobile_GetDispatchPhoneNo]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Mobile_GetDispatchPhoneNo]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Mobile_GetDispatchPhoneNo] 
 END 
 GO  GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Mobile_GetDispatchPhoneNo] 
	@memberNumber as nvarchar(50)=null
	
AS
BEGIN
Declare @DispatchPhoneNo nvarchar(20)	

	SELECT @DispatchPhoneNo= PPH.DispatchPhoneNumber
	FROM Member M
	JOIN Membership MS ON MS.ID = M.MembershipID
	JOIN Program P ON M.ProgramID = P.ID
	--JOIN Client C ON P.ClientID = C.ID
	LEFT OUTER JOIN [dbo].[fnc_GetProgramDispatchNumber](NULL) PPH ON PPH.ProgramID = P.ID
	WHERE MS.MembershipNumber = @memberNumber 
	and m.IsPrimary = 1
	
	if @DispatchPhoneNo is null
		Begin
		  select null
		END
		else
		Begin
		  select @DispatchPhoneNo
		END
	
END
GO
