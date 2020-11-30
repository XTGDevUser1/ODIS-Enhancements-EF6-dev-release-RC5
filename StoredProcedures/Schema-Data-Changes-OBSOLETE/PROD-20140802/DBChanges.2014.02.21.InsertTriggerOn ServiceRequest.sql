CREATE TRIGGER [dbo].[tr_STATUS_Inserted]
   ON [dbo].[ServiceRequest]
   AFTER INSERT
AS BEGIN
    SET NOCOUNT ON;    
    	   UPDATE [dbo].[ServiceRequest] 
	   SET [StatusDateModified] = GETDATE()
	   FROM [dbo].[ServiceRequest] S 
	   INNER JOIN Inserted I ON S.ID = I.ID                
    END
