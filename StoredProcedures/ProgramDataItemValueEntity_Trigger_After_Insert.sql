ALTER TRIGGER ProgramDataItemValueEntity_Trigger_After_Insert ON [dbo].[ProgramDataItemValueEntity] 
FOR INSERT
AS
	
	DECLARE @EntityName NVARCHAR(200);
	DECLARE @ScreenName NVARCHAR(200);
	DECLARE @FieldName NVARCHAR(200);
	DECLARE @Message NVARCHAR(MAX);
	DECLARE @ProgramID INT;

	DECLARE @EntityID INT;
	DECLARE @RecordID INT;
	DECLARE @ProgramDataItemID INT;
	DECLARE @Value NVARCHAR(MAX)
	
	

	SELECT @EntityID		  = currentRecord.EntityID FROM inserted currentRecord;	
	SELECT @RecordID		  = currentRecord.RecordID FROM inserted currentRecord;	
	SELECT @ProgramDataItemID = currentRecord.ProgramDataItemID FROM inserted currentRecord;	
	SELECT @Value			  = currentRecord.Value FROM inserted currentRecord;


	SELECT @EntityName = E.Name FROM Entity E WHERE E.ID = @EntityID
	SELECT @ScreenName = PDI.ScreenName,
		   @FieldName  = PDI.Name,
		   @ProgramID = PDI.ProgramID	 
	FROM   ProgramDataItem PDI WHERE PDI.ID = @ProgramDataItemID


	SET	   @Message = 'Executing Trigger AFTER INSERT ON ProgramDataItemValueEntity - Entity ID : ' + CAST(@EntityID AS NVARCHAR(100)) +  ' Record ID : ' + CAST(@RecordID AS NVARCHAR(100)) + ' Program Data Item : ' + CAST(@ProgramDataItemID AS NVARCHAR(100));
	INSERT INTO [Log]([Date],[Thread],[Level],[Logger],[Message]) VALUES(GETDATE(),0,'INFO','Trigger',@Message)
		
   -- BEGIN ACTUAL LOGIC

    IF @EntityName = 'Member' AND @ScreenName = 'RegisterMember' AND @FieldName = 'ClientReferenceNumber'
	BEGIN
		 -- UPDATE Client Reference Number Always
		 UPDATE Membership SET ClientReferenceNumber = @Value WHERE ID = (SELECT MembershipID FROM Member WHERE ID = @RecordID)

		 -- UPDATE Membership Number Based on Configuration
		 DECLARE	    @dms_programconfiguration_for_program_get AS TABLE(Name NVARCHAR(MAX),
															   Value NVARCHAR(MAX),
															   ControlType NVARCHAR(MAX),
															   DataType NVARCHAR(MAX),
															   Sequence INT)
		INSERT INTO @dms_programconfiguration_for_program_get EXEC dms_programconfiguration_for_program_get @ProgramID,'Application', 'Rule' 

		IF EXISTS (SELECT * FROM @dms_programconfiguration_for_program_get WHERE Name = 'InsertMembershipNumber' AND LOWER(Value) = 'yes')
		BEGIN
			 IF(LEN(@Value) > 0)
			 BEGIN
				UPDATE Membership SET MembershipNumber = @Value WHERE ID = (SELECT MembershipID FROM Member WHERE ID = @RecordID)
			 END
		END
	
	END

	IF @EntityName = 'Case' AND @ScreenName = 'StartCall' AND (@FieldName = 'ClaimNumber' OR @FieldName = 'CaseNumber')
	BEGIN
		Update [Case] SET ReferenceNumber = @Value WHERE ID = @RecordID
	END
	

   -- END LOGIC
	INSERT INTO [Log]([Date],[Thread],[Level],[Logger],[Message]) VALUES(GETDATE(),0,'INFO','Trigger','Trigger Execution Completed')
	
GO


