/****** Object:  StoredProcedure [dbo].[Update_ContactLog_AAATransfer_To_AgeroTransfer]    Script Date: 07/13/2016 09:55:00 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_ContactLog_AAATransfer_To_AgeroTransfer]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_ContactLog_AAATransfer_To_AgeroTransfer]
GO

/****** Object:  StoredProcedure [dbo].[Update_ContactLog_AAATransfer_To_AgeroTransfer]    Script Date: 07/13/2016 09:55:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--exec Update_ContactLog_AAATransfer_To_AgeroTransfer 664127

Create Procedure [dbo].[Update_ContactLog_AAATransfer_To_AgeroTransfer] 
	@ServiceRequestID int
AS
BEGIN

--select sr.ID,
Update cla Set 
	ContactActionID = (Select ID From ContactAction where Name = 'TransferredCallToAgero' and IsActive = 1)
from contactlog cl with (nolock)  
join contactloglink cll with (nolock) on cl.id = cll.contactlogid and cll.EntityID = (select ID from Entity where Name = 'ServiceRequest')  
join servicerequest sr with (nolock) on sr.id = cll.recordid  
join contactlogaction cla with (nolock) on cl.id = cla.contactlogid  
join contactaction ca with (nolock) on cla.ContactActionID = ca.ID  
where sr.ID = @ServiceRequestID
and ca.Name = 'TransferredCallToAAA'

END

GO


