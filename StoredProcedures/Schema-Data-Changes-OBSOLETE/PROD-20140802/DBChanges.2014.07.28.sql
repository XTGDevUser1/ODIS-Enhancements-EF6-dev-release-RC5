IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NextAction]') AND type in (N'U'))
BEGIN

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [name] = N'DefaultAssignedToUserID' AND [object_id] = OBJECT_ID(N'NextAction'))
BEGIN

ALTER TABLE [NextAction]  ADD [DefaultAssignedToUserID] INT NULL
END 

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_NextAction_User]') AND parent_object_id = OBJECT_ID(N'[dbo].[NextAction]'))
ALTER TABLE [dbo].[NextAction]  WITH CHECK ADD  CONSTRAINT [FK_NextAction_User] FOREIGN KEY([DefaultAssignedToUserID])
REFERENCES [dbo].[User] ([ID])

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_NextAction_User]') AND parent_object_id = OBJECT_ID(N'[dbo].[NextAction]'))
ALTER TABLE [dbo].[NextAction] CHECK CONSTRAINT [FK_NextAction_User]

END