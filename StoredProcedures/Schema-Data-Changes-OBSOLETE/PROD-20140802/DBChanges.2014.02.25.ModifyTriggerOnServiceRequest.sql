CREATE TRIGGER [dbo].[tr_STATUS_Modified]
   ON [dbo].[ServiceRequest]
   AFTER UPDATE
AS BEGIN
    SET NOCOUNT ON;    
    IF (UPDATE(ServiceRequestStatusID))
    Begin
	   UPDATE [dbo].[ServiceRequest] 
	   SET [StatusDateModified] = GETDATE()
	   FROM [dbo].[ServiceRequest] S 
	   INNER JOIN Inserted I ON S.ID = I.ID 
	   INNER JOIN Deleted D ON S.ID = D.ID                   
	   WHERE D.ServiceRequestStatusID <> I.ServiceRequestStatusID --This will handle updated records
	  
    END

END