
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Communication_Fax_Update]'))-- AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Communication_Fax_Update]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
   -- EXEC [dbo].[dms_Communication_Fax_Update] 'kbanda'
 CREATE PROCEDURE [dbo].[dms_Communication_Fax_Update](  
 @userName NVARCHAR(50) = NULL)
 AS
 BEGIN
 
DECLARE @tmpRecordstoUpdate TABLE
(
CommunicationLogID INT NOT NULL,
ContactLogID INT NOT NULL,
[Status] nvarchar(255) NULL,
FaxResult nvarchar(2000) NULL,
FaxInfo nvarchar(2000)NULL,
sRank INT NOT NULL,
CommunicationLogCreateBy NVARCHAR(100) NULL
)
 
	
    -- To Update the Records in Batch
	--WITH wResult AS(
	INSERT INTO @tmpRecordstoUpdate
	SELECT	CL.ID,
			CL.ContactLogID,
			CL.[Status],
			FR.[result] AS FaxResult,
			FR.[info] AS FaxInfo,
			ROW_NUMBER() OVER(PARTITION BY FR.Billing_Code ORDER BY FR.[Date] DESC) AS 'SRank',
			CL.CreateBy
			FROM CommunicationLog CL
			 INNER JOIN FaxResult FR ON
			 FR.[date] > DATEADD(dd, -14, getdate()) AND
			 FR.[billing_code] <> '' AND 
			 FR.[billing_code] = CL.ID
			 WHERE ContactMethodID = (SELECT ID FROM ContactMethod WHERE Name = 'Fax')
			 AND [Status] = 'PENDING'

	UPDATE CommunicationLog 
	SET [Status] = T.FaxResult,
		Comments = T.FaxInfo,
		ModifyDate = getdate(),
		ModifyBy = @username 
	FROM CommunicationLog 
	JOIN @tmpRecordstoUpdate T on T.CommunicationLogID = CommunicationLog.ID
	WHERE T.sRank = 1
				 
	--UPDATE wResult SET wResult.[Status] = wResult.FaxResult,
	--				   wResult.Comments = wResult.[FaxInfo],
	--				   wResult.ModifyDate = getdate(),
	--				   wResult.ModifyBy = @userName 
	--				   WHERE SRank = 1
					   
	-- Create New Records in Batch if Contact Log ID is not NULL				   
	--;WITH wResultInsert AS(
	--SELECT CL.*,FR.[result] AS FaxResult,FR.[info] AS FaxInfo FROM CommunicationLog CL
	--		 INNER JOIN FaxResult FR ON
	--		 FR.[billing_code] = CL.ID
	--		 WHERE ContactMethodID = (SELECT ID FROM ContactMethod WHERE Name = 'Fax')
	--		 AND
	--		 [Status] IN ('SUCCESS','FAILURE')
	--		 AND ContactLogID IS NOT NULL)
	INSERT INTO ContactLogAction(ContactActionID,ContactLogID,Comments,CreateDate,CreateBy)
		   SELECT DISTINCT
		     Case FaxResult 
				WHEN 'SUCCESS' THEN (SELECT ID FROM ContactAction WHERE Name = 'Sent')
				ELSE (SELECT ID FROM ContactAction WHERE Name = 'SendFailure')
			END as ContactActionID,
		   [ContactLogID],FaxInfo,GETDATE(),@userName
		   FROM @tmpRecordstoUpdate
		   WHERE sRank = 1

	-- KB: Notifications
	-- For every communicationlog record whose status was set to FAIL, create eventlog records with event
	DECLARE @eventIDForSendPOFaxFailed INT,
			@eventDescriptionForSendPOFaxFailed NVARCHAR(255),
			@poEntityID INT,
			@contactLogActionEntityID INT,
			@idx INT = 1,
			@maxRows INT,
			@eventLogID INT,
			@sendFailureContactActionID INT

	SELECT	@eventIDForSendPOFaxFailed = ID, @eventDescriptionForSendPOFaxFailed = [Description] FROM [Event] WITH (NOLOCK) WHERE Name = 'SendPOFaxFailed'
	SELECT	@poEntityID = ID FROM Entity WHERE Name = 'PurchaseOrder'
	SELECT	@contactLogActionEntityID = ID FROM Entity WHERE Name = 'ContactLogAction'
	SELECT	@sendFailureContactActionID = ID FROM ContactAction WHERE Name = 'SendFailure'

	CREATE TABLE #tmpCommunicationLogFaxFailed
	(
		RowNum INT IDENTITY(1,1) NOT NULL,
		CommunicationLogID INT NOT NULL,
		ContactLogID INT NOT NULL,
		PurchaseOrderID INT NULL,
		PurchaseOrderNumber NVARCHAR(50) NULL,
		ServiceRequestNumber INT NULL,
		FailureReason NVARCHAR(MAX) NULL,
		CommunicationLogCreateBy NVARCHAR(100) NULL
	)

	INSERT INTO #tmpCommunicationLogFaxFailed 
	SELECT	T.CommunicationLogID,
			T.ContactLogID,
			CLL.RecordID,
			PO.PurchaseOrderNumber,
			PO.ServiceRequestID,
			T.FaxInfo,
			T.CommunicationLogCreateBy
	FROM	@tmpRecordstoUpdate T
	LEFT JOIN	ContactLogLink CLL ON T.ContactLogID = CLL.ContactLogID AND CLL.EntityID = @poEntityID
	LEFT JOIN	PurchaseOrder PO ON PO.ID = CLL.RecordID
	WHERE	T.FaxResult = 'FAILURE'
	AND		T.sRank = 1

	SELECT @maxRows = MAX(RowNum) FROM #tmpCommunicationLogFaxFailed


	--DEBUG: SELECT * FROM #tmpCommunicationLogFaxFailed

	DECLARE @purchaseOrderID INT,
			@serviceRequestID INT,
			@purchaseOrderNumber NVARCHAR(50),
			@contactLogID INT,
			@failureReason NVARCHAR(MAX),
			@commLogCreateBy NVARCHAR(100)

	WHILE ( @idx <= @maxRows )
	BEGIN
		
		SELECT	@contactLogID		= T.ContactLogID,
				@failureReason		= T.FailureReason,
				@purchaseOrderID	= T.PurchaseOrderID,
				@purchaseOrderNumber = T.PurchaseOrderNumber,
				@serviceRequestID	= T.ServiceRequestNumber,
				@commLogCreateBy	= T.CommunicationLogCreateBy
		FROM	#tmpCommunicationLogFaxFailed T WHERE T.RowNum = @idx

		-- For each communication log record related to fax failure, log an event and create link records - one per 
		INSERT INTO EventLog (	EventID,
								Source,
								Description,
								Data,
								NotificationQueueDate,
								CreateDate,
								CreateBy)
		SELECT	@eventIDForSendPOFaxFailed,
				'Communication Service',
				@eventDescriptionForSendPOFaxFailed,
				'<MessageData><PONumber>' + @purchaseOrderNumber + 
							'</PONumber><ServiceRequest>' + CONVERT(NVARCHAR(50),@serviceRequestID) + 
							'</ServiceRequest><FaxFailureReason>' + @failureReason + 
							'</FaxFailureReason><CreateByUser>' +  @commLogCreateBy +
							'</CreateByUser></MessageData>',
				NULL,
				GETDATE(),
				'system'
		

		SET @eventLogID = SCOPE_IDENTITY()

		--DEBUG: SELECT @eventLogID AS EventLogID

		INSERT INTO EventLogLink ( EventLogID, EntityID, RecordID)
		SELECT	@eventLogID,
				@poEntityID,
				@purchaseOrderID

		;WITH wContactLogActions
		AS
		(
			SELECT	ROW_NUMBER() OVER ( PARTITION BY CLA.ContactActionID ORDER BY CLA.CreateDate DESC) As RowNum,
					CLA.ID As ContactLogActionID,
					CLA.ContactLogID
			FROM	ContactLogAction CLA 			
			WHERE	CLA.ContactLogID = @contactLogID
			AND		CLA.ContactActionID = @sendFailureContactActionID
		)

		INSERT INTO EventLogLink ( EventLogID, EntityID, RecordID)
		SELECT	@eventLogID,
				@contactLogActionEntityID,
				W.ContactLogActionID
		FROM	wContactLogActions W 
		WHERE	W.RowNum = 1


		SET @idx = @idx + 1
	END

	DROP TABLE #tmpCommunicationLogFaxFailed
END

GO
/****** Object:  StoredProcedure [dbo].[Membership_InsertUpdate]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Membership_InsertUpdate]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Membership_InsertUpdate] 
 END 

 GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--******************************************************************************************
--******************************************************************************************
--
--RRH	^1			03/28/2014			Project# 13533 - Adding AltMembershipNumber column for CNET
--		
--******************************************************************************************
--******************************************************************************************
--dbo.Membership_InsertUpdate	[BatchID],[ProcessGroup],[ProcessFlag],[ErrorDescription],[DateAdded],[Operation],[ProgramID],[MembershipID],[ClientMembershipKey],[MembershipNumber],[SequenceNumber],[EmailAddress]

CREATE procedure [dbo].[Membership_InsertUpdate]
		(
		@pMembershipNumber varchar(25) = NULL,
		@pEmailAddress varchar(255) = NULL,
		@pClientReferenceNumber varchar(50) = NULL,
		@pClientMembershipKey varchar(50) = NULL,
		@pIsActive bit,
		@pCreateBatchID	int = NULL,
		@pCreateDate datetime = NULL,
		@pCreateBy varchar(50) = NULL,
		@pModifyBatchID	int = NULL,
		@pModifyDate datetime = NULL,
		@pModifyBy varchar(50) = NULL,
		@pNote varchar(2000) = NULL,
		@pSourceSystem int = NULL,
		@pAltMembershipNumber varchar(40) = NULL --^1
		)
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT OFF

MERGE [dbo].[Membership] AS target

USING (
 		 select
 		 @pMembershipNumber,
 		 @pEmailAddress,
 		 @pClientReferenceNumber,
 		 @pClientMembershipKey,
 		 @pIsActive,
 		 @pCreateBatchID,
 		 @pCreateDate,
		 @pCreateBy,
		 @pModifyBatchID,
		 @pModifyDate,
		 @pModifyBy,
		 @pNote,
		 @pSourceSystem
		 --,@pAltMembershipNumber --^1
	)
as source(
		[MembershipNumber]
		,[Email]
		,[ClientReferenceNumber]
		,[ClientMembershipKey]
		,[IsActive]
		,[CreateBatchID]
		,[CreateDate]
		,[CreateBy]
		,[ModifyBatchID]
		,[ModifyDate]
		,[ModifyBy]
		,[Note]
		,[SourceSystem]
		--,[AltMembershipNumber] --^1
		)
    ON (
		target.ClientMembershipKey = source.ClientMembershipKey
		)
    WHEN MATCHED THEN 
        UPDATE SET
			MembershipNumber = source.MembershipNumber,
			Email = source.Email,
			ModifyBatchID = source.ModifyBatchid,
			ModifyDate = source.ModifyDate,
			ModifyBy = source.ModifyBy
			--,AltMembershipNumber = source.AltMembershipNumber  --^1
	WHEN NOT MATCHED THEN
		Insert 
			(
			[MembershipNumber]
			,[Email]
			,[ClientReferenceNumber]
			,[ClientMembershipKey]
			,[IsActive]
			,[CreateBatchid]
			,[CreateDate]
			,[CreateBy]
			,SourceSystemID
			--,AltMembershipNumber --^1
			)		
     VALUES
			(
			 source.MembershipNumber,
			 source.Email,
			 source.ClientReferenceNumber,
			 source.ClientMembershipKey,
			 source.IsActive,
			 source.CreateBatchID,
			 source.CreateDate,
			 source.CreateBy,
			 2
			 --,source.AltMembershipNumber --^1
			);
GO
GO
/****** Object:  StoredProcedure [dbo].[Member_InsertUpdate]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Member_InsertUpdate]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Member_InsertUpdate] 
 END 
 GO  

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--******************************************************************************************
--******************************************************************************************
--
--RRH	^1			11/01/13			adding AccountSource
--
--******************************************************************************************
--******************************************************************************************


--******************************************************************************************
--******************************************************************************************
--exe Member_InsertUpdate 107, '@pMemberNumber', '@pPrefix', '@pFirstName', '@pMiddleName', '@pLastName', '@pSuffix', '@pEmail', '@pEffectiveDate', '@pExpirationDate','@pMemberSinceDate','@pClientMemberKey','@pClientMembershipKey','@pIsPrimary','@pIsActive','@pCreateBatchID','@pCreateDate','@pCreateBy','@pModifyBatchID','@pModifyDate','@pModifyBy'
--[dbo].[Member_InsertUpdate] 107, '9831617', NULL, 'BOBBY WAYNE', NULL, 'NORRIS', NULL, NULL, '2000-08-02 00:00:00.000', '2014-08-25 00:00:00.000','2000-08-02 00:00:00.000','000000013686951000','000000013686951',1,1,1086,'2013-01-27 14:06:30.000','System',7156,'2013-09-19 16:33:55.040','DISPATCHPOST'
--dbo.Member_InsertUpdate 107, '9831617', NULL, 'BOBBY WAYNE', NULL, 'NORRIS', NULL, NULL, NULL, '2014-08-25 00:00:00.000','2000-08-02 00:00:00.000','000000013686951000','000000013686951',1,1,1086,'2013-01-27 14:06:30.000','System',7156,'2013-09-19 16:33:55.040','DISPATCHPOST'
--select * from member where firstname = 'BOBBY WAYNE' 
--******************************************************************************************
--******************************************************************************************

CREATE PROCEDURE [dbo].[Member_InsertUpdate]
			(
				@pProgramID int = NULL,	
				@pMemberNumber varchar(50),
				@pPrefix varchar(10) = NULL,	
				@pFirstName varchar(50) = NULL,
				@pMiddleName varchar(50) = NULL,
				@pLastName varchar(50) = NULL,
				@pSuffix varchar(10) = NULL,
				@pEmail varchar(255) = NULL,
				@pEffectiveDate	datetime = NULL,			 
				@pExpirationDate datetime = NULL,
				@pMemberSinceDate datetime = NULL,
				@pClientMemberKey varchar(50) = NULL,
				@pClientMembershipKey varchar(50) = NULL,
				@pIsPrimary bit = NULL,
				@pIsActive bit = NULL,
				@pCreateBatchID	int = NULL,
				@pCreateDate datetime = NULL,
				@pCreateBy varchar(50) = NULL,
				@pModifyBatchID	int = NULL,
				@pModifyDate datetime = NULL,
				@pModifyBy varchar(50) = NULL,
				--^1
				@pAccountSource varchar(50) = NULL
			)
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT OFF

declare @MembershipID as int

select @MembershipID = id from Membership where ClientMembershipKey = @pClientMembershipKey

   MERGE [dbo].[Member] AS target
    USING (select 
				@MembershipID,
				@pProgramID,	
				@pPrefix,
				@pFirstName,
				@pMiddleName,
				@pLastName,
				@pSuffix,
				--@pEmail,
				@pEffectiveDate,
				@pExpirationDate,
				@pMemberSinceDate,
				@pClientMemberKey,
				@pIsPrimary,
				@pIsActive,
				@pCreateBatchID,
				@pCreateDate,
				@pCreateBy,
				@pModifyBatchID,
				@pModifyDate,
				@pModifyBy,
				--^1
				@pAccountSource
			)
			as source( 
				[MembershipID],
				[ProgramID],	
				[Prefix],
				[FirstName],
				[MiddleName],
				[LastName],
				[Suffix],
				--[Email],
				[EffectiveDate],
				[ExpirationDate],
				[MemberSinceDate],
				[ClientMemberKey],
				[IsPrimary],
				[IsActive],
				[CreateBatchID],
				[CreateDate],
				[CreateBy],
				[ModifyBatchID],
				[ModifyDate],
				[ModifyBy],
				--^1
				[AccountSource]
           )
    ON (target.ClientMemberKey = source.ClientMemberKey)
    
    WHEN MATCHED THEN 
        UPDATE SET 
				ProgramID = source.ProgramID,
				Prefix = source.Prefix,
				FirstName = source.FirstName,
				MiddleName = source.MiddleName,
				LastName = source.LastName,
				Suffix = source.Suffix,
				--Email = source.Email,
				EffectiveDate = source.EffectiveDate,
				ExpirationDate = source.ExpirationDate,
				MemberSinceDate = source.MemberSinceDate,
				IsPrimary = source.IsPrimary,
				ModifyBatchID = source.ModifyBatchid,
				ModifyDate = source.ModifyDate,
				ModifyBy = source.ModifyBy,
				--^1
				AccountSource = source.AccountSource
	WHEN NOT MATCHED THEN	
	    INSERT (
				[MembershipID],
				[ProgramID],	
				[Prefix],
				[FirstName],
				[MiddleName],
				[LastName],
				[Suffix],
				--[Email],
				[EffectiveDate],
				[ExpirationDate],
				[MemberSinceDate],
				[ClientMemberKey],
				[IsPrimary],
				[IsActive],
				[CreateBatchID],
				[CreateDate],
				[CreateBy],
				SourceSystemID,
				--^1
				AccountSource
           )
	    VALUES (
				source.[MembershipID],
				source.[ProgramID],	
				source.[Prefix],
				source.[FirstName],
				source.[MiddleName],
				source.[LastName],
				source.[Suffix],
				--source.[Email],
				source.[EffectiveDate],
				source.[ExpirationDate],
				source.[MemberSinceDate],
				source.[ClientMemberKey],
				source.[IsPrimary],
				source.[IsActive],
				source.[CreateBatchID],
				source.[CreateDate],
				source.[CreateBy],
				2,
				--^1
				source.AccountSource
           );
GO

/****** Object:  StoredProcedure [dbo].[Mobile_callForService_Insert]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Mobile_callForService_Insert]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Mobile_callForService_Insert] 
 END 
 GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Mobile_callForService_Insert]
 	@memberNumber nvarchar(50)=null,
 	@GUID nvarchar(50)=null,
 	@memberDeviceGUID nvarchar(255)=null,
 	@firstName nvarchar(50)=null,
 	@lastName nvarchar(50)=null,
 	@MemberDevicePhoneNumber nvarchar(20)=null,
 	@locationLatitude nvarchar(10)=null,
 	@locationLongtitude nvarchar(10)=null,
 	@serviceType nvarchar(100)=null,
 	@ErrorCode int=null,
 	@ErrorMessage nvarchar(200)=null,
 	@appOrgName nvarchar(5)=null,
 	@PKID int output 
 	
AS
BEGIN
	Insert into Mobile_callForService(
	memberNumber,
	guid,
	memberDeviceGUID,
	firstname,
	lastname,
	MemberDevicePhoneNumber,
	locationLatitude,
	locationLongtitude,
	serviceType,
	Errorcode,
	Errormessage,
	appOrgName
	)
	values(
	@memberNumber ,
 	@GUID,
 	@memberDeviceGUID,
 	@firstName ,
 	@lastName ,
 	@MemberDevicePhoneNumber ,
 	@locationLatitude ,
 	@locationLongtitude ,
 	@serviceType ,
 	@ErrorCode,
 	@ErrorMessage,
 	@appOrgName 
 	)
	
	Select @PKID = @@Identity
END



/****** Object:  StoredProcedure [dbo].[Mobile_logAccess_Insert]    Script Date: 03/01/2013 13:12:09 ******/
SET ANSI_NULLS ON
GO

GO
/****** Object:  StoredProcedure [dbo].[Mobile_GetDispatchPhoneNo]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Mobile_GetDispatchPhoneNo]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Mobile_GetDispatchPhoneNo] 
 END 
 GO  
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


GO
/****** Object:  StoredProcedure [dbo].[Mobile_IsActiveMember]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Mobile_IsActiveMember]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Mobile_IsActiveMember] 
 END 
 
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


GO
/****** Object:  StoredProcedure [dbo].[Mobile_logAccess_Insert]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Mobile_logAccess_Insert]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Mobile_logAccess_Insert] 
 END 
  
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Mobile_logAccess_Insert]
 	@memberNumber nvarchar(50)=null,
 	@GUID nvarchar(50)=null,
 	@memberDeviceGUID nvarchar(255)=null,
 	@validGUID bit=null,
 	@deviceType nvarchar(25)=null,
 	@applicationVersion nvarchar(25)=null,
 	@dispatchPhNo nvarchar(20)=null,
 	@errorCode int=null,
 	@errorMessage nvarchar(200)=null,
 	@appOrgName nvarchar(5)=null
AS
BEGIN
	Insert into mobile_logAccess(
	memberNumber,
	guid,
	memberDeviceGUID,
	validguid,
	deviceType,
	applicationVersion,
	dispatchPhoneNo,
	errorCode,
	errorMessage,
	appOrgName
	)
	values(
	@memberNumber ,
 	@GUID,
 	@memberDeviceGUID ,
 	@validGUID ,
 	@deviceType,
 	@applicationVersion,
 	@dispatchPhNo,
 	@errorCode ,
 	@errorMessage,
 	@appOrgName  
	)
	
	
END



/****** Object:  StoredProcedure [dbo].[Mobile_Registration_Insert]    Script Date: 03/01/2013 13:12:22 ******/
SET ANSI_NULLS ON
GO

GO
/****** Object:  StoredProcedure [dbo].[Mobile_memberExist]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Mobile_memberExist]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Mobile_memberExist] 
 END 
 
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

GO
/****** Object:  StoredProcedure [dbo].[Mobile_Registration_Insert]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Mobile_Registration_Insert]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Mobile_Registration_Insert] 
 END 
 
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Mobile_Registration_Insert]
 	@memberNumber nvarchar(50)=null,
 	@GUID nvarchar(50)=null,
 	@memberDeviceGUID nvarchar(255)=null,
 	@firstName nvarchar(50)=null,
 	@lastName nvarchar(50)=null,
 	@MemberDevicePhoneNumber nvarchar(20)=null,
 	@validGUID bit=null,
 	@activeMember  bit=null,
 	@memberExist bit=null,
 	@validRegistration bit=null,
 	@ErrorCode int=null,
 	@ErrorMessage nvarchar(200)=null,
 	@dispatchPhNo nvarchar(20)=null,
 	@appOrgName nvarchar(5)=null
AS
BEGIN
	Insert into mobile_registration(
	memberNumber,
	guid,
	memberdeviceguid,
	firstname,
	lastname,
	MemberDevicePhoneNumber,
	validguid,
	activemember,
	MemberExist,
	ValidRegistration,
	Errorcode,
	Errormessage,
	dispatchPhoneNo,
	appOrgName
	)
	values(
	@memberNumber ,
 	@GUID,
 	@memberDeviceGUID,
 	@firstName ,
 	@lastName ,
 	@MemberDevicePhoneNumber ,
 	@validGUID ,
 	@activeMember ,
 	@memberExist,
 	@validRegistration,
 	@ErrorCode,
 	@ErrorMessage,
 	@dispatchPhNo,
 	@appOrgName 
	)
	
	
END
GO


GO
/****** Object:  StoredProcedure [dbo].[NMCFordCudlEXPORT_SELECT]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[NMCFordCudlEXPORT_SELECT]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[NMCFordCudlEXPORT_SELECT] 
 END 

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--dbo.NMCFordCudlEXPORT_SELECT '09/20/2013'
--dbo.NMCFordCudlEXPORT_SELECT '10/15/2013'

CREATE procedure [dbo].[NMCFordCudlEXPORT_SELECT]
(	
	@pProcessDate as date
)
AS


--******************************************************************************************
--******************************************************************************************
--
--		
--******************************************************************************************
--******************************************************************************************

--declare
--@date date = getdate()


						
			Select	
			1 pkid,	
			'000000000000' +
			RIGHT(REPLICATE(' ',17)+convert(varchar,upper(c.VehicleVIN)),17) +
			Case when pgm1.ID = 266 then '1416' else '1415' end +
			RIGHT(REPLICATE(' ',6)+convert(varchar,''),6) +
			RIGHT(REPLICATE('0',6)+convert(varchar,c.VehicleCurrentMileage),6) +
		    
			Case when sc.ServiceCode like '%tow%' then 'CCM002'
						when sc.ServiceCode like '%lock%' or sc.PurchaseOrderID like '%mech%' then 'CCM003' 
						when sc.ServiceCode like '%jump%' then 'CCM004'
						when sc.ServiceCode like '%Tire%' then 'CCM005'
						when sc.ServiceCode like '%Fluid%' then 'CCM006'
						when sc.ServiceCode like '%Winch%' then 'CCM007'
						else sc.ServiceCode
						end +
			 c.VehicleMileageUOM  + ': ' + cast(c.VehicleCurrentMileage as nvarchar(11)) + '; '+ sc.ServiceCode   as DataRow

		   into #results   
	
		from DMS.dbo.ServiceRequest sr with(nolock)
			  left join DMS.dbo.ServiceRequestStatus srs with(nolock) on sr.ServiceRequestStatusID = srs.ID 
			  left join DMS.dbo.[Case] c with(nolock) on sr.CaseID = c.ID 
			  left join DMS.dbo.Program pgm1 with(nolock) on c.ProgramID = pgm1.ID 
			  left join DMS.dbo.PurchaseOrder po with(nolock) on sr.ID = po.ServiceRequestID and po.IsActive = 1
			  left join DMS.dbo.Program pgm2 with(nolock) on pgm1.ParentProgramID = pgm2.ID 
			  left join DMS.dbo.Program pgm3 with(nolock) on pgm2.ParentProgramID = pgm3.ID 
			  left join DMS.dbo.vw_ServiceCode sc with (nolock) on sc.ServiceRequestID = sr.ID and ISNULL(sc.PurchaseOrderID,0) = ISNULL(po.id,0)
		where isnull(pgm3.id, isnull(pgm2.id, pgm1.id)) = 86						---Parent = Ford
				  and pgm1.ID <>343                                             ---Dosne't include FORD Direct Tow
				  and po.CreateDate between DATEADD(dd,-1,convert(date,@pProcessDate,112)) and convert(date,@pProcessDate,112)
				  and   po.id is not null                                       ---Only Pull Valid events with a PO created 
																				---need to verify how rebursements will be docuemnted
				  and (sc.ServiceCode like '%tow%' or sc.ServiceCode like '%lock%' or sc.ServiceCode like '%mech%'        
						or sc.ServiceCode like '%jump%' or sc.ServiceCode like '%Tire%' or sc.ServiceCode like '%Fluid%'
						or sc.ServiceCode like '%Winch%')
		
	Union all
	

		SELECT
				2, 
				'000000000000' +
				RIGHT(REPLICATE(' ',17)+convert(varchar,upper(c.VehicleVIN)),17) +
				Case when p1.ID = 266 then '1416' else '1415' end +
				RIGHT(REPLICATE(' ',12)+convert(varchar,c.CurrentMiles),12) +
			    'CCM002' + ---Was advised by Kristen Ellingson all claims were coded tow Not captured in Claims Process
			    'Miles' + ': ' + cast(c.CurrentMiles as nvarchar(11)) + '; '+ 
						(case	when SUBSTRING(c.VehicleVIN,6,1) in (3,4,5)then 'Tow - MD'
								when SUBSTRING(c.VehicleVIN,6,1) in (6,7)then  'Tow - HD' else 'TOW - LD' end )--as data

			
		  FROM [DMS].[dbo].[Claim] c with (nolock)
		  left join dms.dbo.ClaimType ct with (nolock) on c.ClaimTypeID = ct.ID 
		  left join dms.dbo.ClaimCategory cc with (nolock) on cc.ID = c.ClaimCategoryID
		  left join dms.dbo.ClaimStatus cs with (nolock) on cs.ID = c.ClaimStatusID
		  left join dms.dbo.Program p1 with (nolock) on c.ProgramID = p1.ID
		  left join DMS.dbo.Program p2 with (nolock) on p1.ParentProgramID = p2.ID 
		  left join DMS.dbo.Program p3 with (nolock) on p2.ParentProgramID = p3.ID 
		  left join dms.dbo.ContactMethod cm with (nolock) on c.ReceiveContactMethodID = cm.ID
		  left join dms.dbo.ProductCategory pc with (nolock) on pc.ID = c.ServiceProductCategoryID
		  
		  
		  where isnull(p3.id, isnull(p2.id, p1.id)) = 86
				and c.CreateDate between DATEADD(dd,-1,convert(date,@pProcessDate,112)) and convert(date,@pProcessDate,112)
				and c.CurrentMiles is not null	

						
						

select DataRow
from (
	select 0 as PKID,
		'HDRFORD_CUDL '+convert(varchar,dateadd(dd,-1,convert(date,@pProcessDate)),112)+
		'005000' as DataRow
			
	union all

		Select *
		from #results
			

	union all
	
		SELECT 3,'TRL' + RIGHT(REPLICATE('0',9)+convert(varchar,(select count(*) from #results)),9) + RIGHT(REPLICATE('0',9)+convert(varchar,(select count(*) from #results)),9)

	)a

order by PKID
GO


GO
/****** Object:  StoredProcedure [dbo].[NMCFordRDAEXPORT_SELECT]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[NMCFordRDAEXPORT_SELECT]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[NMCFordRDAEXPORT_SELECT] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--dbo.NMCFordRDAEXPORT_SELECT '09/1/13','09/9/13'
--dbo.NMCFordRDAEXPORT_SELECT '10/15/2013'

CREATE procedure [dbo].[NMCFordRDAEXPORT_SELECT]
(	
	@pBeginDate as date,
	@pEndDate as date
)
AS

--******************************************************************************************
--******************************************************************************************
--1/8/14 Removed blank spaces from around the VIN  Clay McNurlin
--		
--******************************************************************************************
--******************************************************************************************

declare @Enddate date
set @Enddate = DATEADD(dd,1,@pEndDate)

					
select 

		c.ContactLastName
		,c.ContactFirstName
		,substring(hpe.PhoneNumber,3,10) HomePhone
		,m.FirstName
		,m.LastName
		,ae.Line1
		,ae.Line2
		,ae.City
		,ae.StateProvince
		,ae.PostalCode
		,ltrim(rtrim(c.VehicleVIN)) VehicleVIN
		,c.VehicleYear
		,c.VehicleModel
		,c.VehicleMake
		,'' ManfactureCode
		,(Case	when sc.ServiceCode like '%tow%' then '56'
				when sc.ServiceCode like '%lock%' then '4'
				when sc.ServiceCode like '%mech%' then '7'
				when sc.ServiceCode like '%jump%' then '2'
				when sc.ServiceCode like '%Tire%' then '5'
				when sc.ServiceCode like '%Fluid%' then '1'
				when sc.ServiceCode like '%Winch%' then '9'
				end) ServiceCode
		,convert(varchar,sr.CreateDate,101) ContactDate
		,Convert(varchar(8),sr.CreateDate,114) ContactTime
		,convert(varchar,po.CreateDate,101)DispatchDate
		,convert(varchar(8),po.CreateDate,114) DispatchTime
		,v.VendorNumber POVEND
		,'' VendorName
		,'' VnAddLn1
		,'' VnAddLn2
		,'' vncity
		,vlae.StateProvince as VnStateProvince
		,'' vnzip
		,''	vnregn
		,''	blank1
		,right(replicate('0',2)+ rtrim(ltrim(str(datepart(hh,po.ETADATE)))),2) + right(replicate('0',2)+ rtrim(ltrim(str(datepart(MI,po.ETADATE)))),2) ETA_MIN
		,'' blank2
		,right(replicate('0',15)+ isnull(po.PurchaseOrderNumber,''),15) PurchaseOrderNumber
		,'' blank3
		,'' fromloc
		,(Case when isnull(sr.IsAccident,'') != '' then sr.IsAccident else 2 end) IsAccident
		,'' blank4
		,right(replicate('0',5)+ isnull(rvl.PartsAndAccessoryCode,''),5) PartsAndAccessoryCode
		,'' TowtoDLR2
		,'' Tows
		,'' Calls
		,'' locst
		,'' loczip
		,po.CreateBy
		,(case	when isnull(b.Description,'') = '' then '' else 'Y' end) POGLFLAG
		,right(replicate('0',10)+ convert(varchar,substring(isnull(hpe.PhoneNumber,''),3,10),10),10) HomePhone
		,right(replicate('0',10)+ convert(varchar,substring(isnull(c.ContactPhoneNumber,''),3,10),10),10) CallBackNumber
		,right(replicate('0',10)+ convert(varchar,substring(isnull(c.ContactAltPhoneNumber,''),3,10),10),10) AltCallBackNumber
		,right(replicate('0',10)+ convert(varchar,substring(isnull(cpe.PhoneNumber,''),3,10),10),10) CellPhone
		
from DMS.dbo.ServiceRequest sr with(nolock)
	left join dms.dbo.VendorLocation rvl with (nolock) on sr.DestinationVendorLocationID = rvl.id
	left join DMS.dbo.ServiceRequestStatus srs with(nolock) on sr.ServiceRequestStatusID = srs.ID 
	left join DMS.dbo.[Case] c with(nolock) on sr.CaseID = c.ID 
	left join DMS.dbo.Program pgm1 with(nolock) on c.ProgramID = pgm1.ID 
	left join DMS.dbo.PurchaseOrder po with(nolock) on sr.ID = po.ServiceRequestID and po.IsActive = 1
	left join dms.dbo.VendorLocation vl with (nolock) on po.VendorLocationID = vl.ID
	left join dms.dbo.Vendor v with (nolock) on vl.VendorID = v.ID
	left join DMS.dbo.Program pgm2 with(nolock) on pgm1.ParentProgramID = pgm2.ID 
	left join DMS.dbo.Program pgm3 with(nolock) on pgm2.ParentProgramID = pgm3.ID 
	left join dms.dbo.vw_ServiceCode sc with (nolock) on sc.ServiceRequestID = sr.ID and ISNULL(sc.PurchaseOrderID,0) = ISNULL(po.id,0)
	left join dms.dbo.Member m with (nolock) on c.MemberID = m.ID
	left join dms.dbo.PhoneEntity cpe with (nolock) on cpe.PhoneTypeID = 3 and cpe.EntityID = 5 and cpe.RecordID = c.MemberID
	left join dms.dbo.PhoneEntity hpe with (nolock) on hpe.PhoneTypeID = 1 and hpe.EntityID = 5 and hpe.RecordID = c.MemberID
	left join dms.dbo.AddressEntity ae with (nolock) on ae.AddressTypeID = 1 and ae.EntityID = 5 and ae.RecordID = c.MemberID
	left join dms.dbo.AddressEntity vlae with (nolock) on vlae.AddressTypeID = 2 and vlae.EntityID = 18 and vl.ID = vlae.RecordID
	left join
	(Select cll.recordid ServiceRequestID
		   ,ca.description
			from rogue.dms.dbo.ContactLogLink cll with (nolock) 
			left join rogue.dms.dbo.contactlog cl with (nolock) on cll.ContactLogID = cl.ID
			left join dms.dbo.ContactLogAction cla with (nolock)on cl.ID = cla.ContactLogID  
			left join dms.dbo.ContactAction ca with (nolock) on ca.ID = cla.ContactActionID 
			where cll.EntityID in (13,14) and cla.ContactActionID = 99
			 and cll.ID = (select MAX(cll2.ID) from rogue.dms.dbo.ContactLogLink cll2 with (nolock) 
										left join rogue.dms.dbo.contactlog cl2 with (nolock) on cll2.ContactLogID = cl2.ID
										left join dms.dbo.ContactLogAction cla2 with (nolock)on cl2.ID = cla2.ContactLogID
										where cll2.EntityID in (13,14) and cll2.RecordID = cll.recordid and cla2.ContactActionID = 99 )
			) b on b.ServiceRequestID=sr.id
	where	isnull(pgm3.id, isnull(pgm2.id, pgm1.id)) = 86								---Parent = Ford
			and pgm1.ID <> 343															---Dosne't include FORD Direct Tow
			and po.CreateDate between @pBeginDate and @Enddate --'10/1/13' and '10/9/13'
			and	po.id is not null														---Only Pull Valid events with a PO created 
																						---need to verify how rebursements will be docuemnted
			and (sc.ServiceCode like '%tow%' or sc.ServiceCode like '%lock%' or sc.ServiceCode like '%mech%'  	
				or sc.ServiceCode like '%jump%' or sc.ServiceCode like '%Tire%' or sc.ServiceCode like '%Fluid%'
				or sc.ServiceCode like '%Winch%' )
GO

GO

GO

GO
/****** Object:  StoredProcedure [dbo].[Phone_InsertUpdate]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Phone_InsertUpdate]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Phone_InsertUpdate] 
 END 
 GO  
 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--******************************************************************************************
--******************************************************************************************
--
--******************************************************************************************
--******************************************************************************************

CREATE PROCEDURE [dbo].[Phone_InsertUpdate]
			(
				@pEntityID int,
				@pPhonetype varchar(15),
				@pPhoneNumber varchar(50) = NULL,
				@pIndexPhoneNumber int = NULL,
				@pSequence int = NULL,
				@pClientMemberKey varchar(50),
				@pCreateBatchID	int = NULL,
				@pCreateDate datetime = NULL,
				@pCreateBy varchar(50) = NULL,
				@pModifyBatchID	int = NULL,
				@pModifyDate datetime = NULL,
				@pModifyBy varchar(50) = NULL
			)
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT OFF

declare @RecordID as int
declare @PhoneTypeID as int

SELECT @RecordID = m.ID  
			FROM dbo.member m with(nolock)
				where 1=1
				and m.ClientMemberKey = @pClientmemberKey
							
SELECT @PhoneTypeID = [ID]
			FROM dbo.PhoneType ad with(nolock)
			Where 1=1
				and ad.IsActive = 1
				and ad.Name = @pPhonetype


   MERGE [dbo].[PhoneEntity] AS target
    USING (select
				@pEntityID, 
				@RecordID,
				@PhoneTypeID,
				@pPhoneNumber,
				@pIndexPhoneNumber,
				@pSequence,
				@pCreateBatchID,
				@pCreateDate,
				@pCreateBy,
				@pModifyBatchID,
				@pModifyDate,
				@pModifyBy
			)
			as source( 
				[EntityID], 
				[RecordID],
				[PhoneTypeID],
				[PhoneNumber],
				[IndexPhoneNumber],
				[Sequence],				
				[CreateBatchID],
				[CreateDate],
				[CreateBy],
				[ModifyBatchID],
				[ModifyDate],
				[ModifyBy]
           )
    ON (target.RecordID = source.RecordID
		AND target.EntityID = source.EntityID
		and target.PhoneTypeID = source.PhoneTypeID
		)
    
    WHEN MATCHED THEN 
        UPDATE SET 
				PhoneNumber = '1 ' + source.PhoneNumber,
				ModifyBatchID = source.ModifyBatchid,
				ModifyDate = source.ModifyDate,
				ModifyBy = source.ModifyBy
	WHEN NOT MATCHED THEN	
	    INSERT	(
				[EntityID], 
				[RecordID],
				[PhoneTypeID],
				[PhoneNumber],
				[IndexPhoneNumber],
				[Sequence],
				[CreateBatchID],
				[CreateDate],
				[CreateBy]
				)
	    VALUES (
				source.[EntityID], 
				source.[RecordID],
				source.[PhoneTypeID],
				'1 ' + source.[PhoneNumber],
				source.[IndexPhoneNumber],
				source.[Sequence],
				source.[CreateBatchID],
				source.[CreateDate],
				source.[CreateBy]
           );
GO

GO
/****** Object:  StoredProcedure [dbo].[Vehicle_InsertUpdate]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[Vehicle_InsertUpdate]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[Vehicle_InsertUpdate] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--******************************************************************************************
--******************************************************************************************
--
-- Rhood		^1			added Vin into the filter criteria
--******************************************************************************************
--******************************************************************************************

CREATE PROCEDURE [dbo].[Vehicle_InsertUpdate]
			(
				@pVehicleCategoryID int = NULL,
				@pRVTypeID int = NULL,
				@pVehicleTypeID int = NULL,
				@pMembershipID int = NULL,
				@pMemberID int = NULL,
				@pVIN varchar(50) = NULL,
				@pYear varchar(4) = NULL,
				@pMake varchar(50) = NULL,
				@pMakeOther varchar(50) = NULL,
				@pModel varchar(50) = NULL,
				@pModelOther varchar(50) = NULL,
				@pLicenseNumber varchar(20) = NULL,
				@pLicenseState varchar(2) = NULL,
				@pDescription varchar(255) = NULL,
				@pColor varchar(50) = NULL,
				@pLength int = NULL,
				@pHeight varchar(50) = NULL,
				@pTireSize varchar(50) = NULL,
				@pTireBrand varchar(50) = NULL,
				@pTireBrandOther varchar(50) = NULL,
				@pTrailerTypeID int = NULL,
				@pTrailerTypeOther varchar(50) = NULL,
				@pSerialNumber varchar(50) = NULL,
				@pNumberofAxles int = NULL,
				@pHitchTypeID int = NULL,
				@pHitchTypeOther varchar(50) = NULL,
				@pTrailerBallSize varchar(50) = NULL,
				@pTrailerBallSizeOther varchar(50) = NULL,
				@pTransmission varchar(100) = NULL,
				@pEngine varchar(100) = NULL,
				@pGVWR int = NULL,
				@pChassis varchar(100) = NULL,
				@pPurchaseDate datetime = NULL,
				@pWarrantyStartDate datetime = NULL,
				@pStartMileage int = NULL,
				@pEndMileage int = NULL,
				@pMileageUOM varchar(50) = NULL,
				@pIsFirstOwner bit = NULL,
				@pIsSportUtilityRV bit = NULL,
				@pSource varchar(50) = NULL,
				@pIsActive bit = NULL,
				@pVehicleLicenseCountryID int = NULL,
				@pClientMemberKey varchar(50) = NULL,
				@pClientMembershipKey varchar(50) = NULL,
				@pCreateBatchID	int = NULL,
				@pCreateDate datetime = NULL,
				@pCreateBy varchar(50) = NULL,
				@pModifyBatchID	int = NULL,
				@pModifyDate datetime = NULL,
				@pModifyBy varchar(50) = NULL
			)
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT OFF

declare @MembershipID as int

select @MembershipID = id from Membership where ClientMembershipKey = @pClientMembershipKey

   MERGE [dbo].[Vehicle] AS target
    USING (select 
				@pVehicleCategoryID,
				@pRVTypeID,
				@pVehicleTypeID,
				@MembershipID,
				@pMemberID,
				@pVIN,
				@pYear,
				@pMake,
				@pMakeOther,
				@pModel,
				@pModelOther,
				@pLicenseNumber,
				@pLicenseState,
				@pDescription,
				@pColor,
				@pLength,
				@pHeight,
				@pTireSize,
				@pTireBrand,
				@pTireBrandOther,
				@pTrailerTypeID,
				@pTrailerTypeOther,
				@pSerialNumber,
				@pNumberofAxles,
				@pHitchTypeID,
				@pHitchTypeOther,
				@pTrailerBallSize,
				@pTrailerBallSizeOther,
				@pTransmission,
				@pEngine,
				@pGVWR,
				@pChassis,
				@pPurchaseDate,
				@pWarrantyStartDate,
				@pStartMileage,
				@pEndMileage,
				@pMileageUOM,
				@pIsFirstOwner,
				@pIsSportUtilityRV,
				@pSource,
				@pIsActive,
				@pVehicleLicenseCountryID,
				@pCreateBatchID,
				@pCreateDate,
				@pCreateBy,
				@pModifyBatchID,
				@pModifyDate,
				@pModifyBy
			)
			as source( 
				[VehicleCategoryID],
				[RVTypeID],
				[VehicleTypeID],
				[MembershipID],
				[MemberID],
				[VIN],
				[Year],
				[Make],
				[MakeOther],
				[Model],
				[ModelOther],
				[LicenseNumber],
				[LicenseState],
				[Description],
				[Color],
				[Length],
				[Height],
				[TireSize],
				[TireBrand],
				[TireBrandOther],
				[TrailerTypeID],
				[TrailerTypeOther],
				[SerialNumber],
				[NumberofAxles],
				[HitchTypeID],
				[HitchTypeOther],
				[TrailerBallSize],
				[TrailerBallSizeOther],
				[Transmission],
				[Engine],
				[GVWR],
				[Chassis],
				[PurchaseDate],
				[WarrantyStartDate],
				[StartMileage],
				[EndMileage],
				[MileageUOM],
				[IsFirstOwner],
				[IsSportUtilityRV],
				[Source],
				[IsActive],
				[VehicleLicenseCountryID],
				[CreateBatchID],
				[CreateDate],
				[CreateBy],
				[ModifyBatchID],
				[ModifyDate],
				[ModifyBy]
           )
    ON (target.MembershipID = source.MembershipID and target.vin = source.vin) --^1
    
    WHEN MATCHED THEN 
        UPDATE SET 
				[VIN] = source.[VIN],
				[Transmission] = source.[Transmission],
				[Year] = source.[Year],
				[Make] = source.[Make],
				[MakeOther] = source.[MakeOther],
				[Model] = source.[Model],
				[ModelOther] = source.[ModelOther],
				[Length] = source.[Length],
				[Chassis] = source.[Chassis],
				[PurchaseDate] = source.[PurchaseDate],
				[WarrantyStartDate] = source.[WarrantyStartDate],
				[StartMileage] = source.[StartMileage],
				[EndMileage] = source.[EndMileage],
				ModifyBatchID = source.ModifyBatchid,
				ModifyDate = source.ModifyDate,
				ModifyBy = source.ModifyBy
	WHEN NOT MATCHED THEN	
	    INSERT (
				[VehicleCategoryID],
				[RVTypeID],
				[VehicleTypeID],
				[MembershipID],
				[MemberID],
				[VIN],
				[Year],
				[Make],
				[MakeOther],
				[Model],
				[ModelOther],
				[LicenseNumber],
				[LicenseState],
				[Description],
				[Color],
				[Length],
				[Height],
				[TireSize],
				[TireBrand],
				[TireBrandOther],
				[TrailerTypeID],
				[TrailerTypeOther],
				[SerialNumber],
				[NumberofAxles],
				[HitchTypeID],
				[HitchTypeOther],
				[TrailerBallSize],
				[TrailerBallSizeOther],
				[Transmission],
				[Engine],
				[GVWR],
				[Chassis],
				[PurchaseDate],
				[WarrantyStartDate],
				[StartMileage],
				[EndMileage],
				[MileageUOM],
				[IsFirstOwner],
				[IsSportUtilityRV],
				[Source],
				[IsActive],
				[VehicleLicenseCountryID],
				[CreateBatchID],
				[CreateDate],
				[CreateBy]
           )
	    VALUES (
				source.[VehicleCategoryID],
				source.[RVTypeID],
				source.[VehicleTypeID],
				source.[MembershipID],
				source.[MemberID],
				source.[VIN],
				source.[Year],
				source.[Make],
				source.[MakeOther],
				source.[Model],
				source.[ModelOther],
				source.[LicenseNumber],
				source.[LicenseState],
				source.[Description],
				source.[Color],
				source.[Length],
				source.[Height],
				source.[TireSize],
				source.[TireBrand],
				source.[TireBrandOther],
				source.[TrailerTypeID],
				source.[TrailerTypeOther],
				source.[SerialNumber],
				source.[NumberofAxles],
				source.[HitchTypeID],
				source.[HitchTypeOther],
				source.[TrailerBallSize],
				source.[TrailerBallSizeOther],
				source.[Transmission],
				source.[Engine],
				source.[GVWR],
				source.[Chassis],
				source.[PurchaseDate],
				source.[WarrantyStartDate],
				source.[StartMileage],
				source.[EndMileage],
				source.[MileageUOM],
				source.[IsFirstOwner],
				source.[IsSportUtilityRV],
				source.[Source],
				source.[IsActive],
				source.[VehicleLicenseCountryID],
				source.[CreateBatchID],
				source.[CreateDate],
				source.[CreateBy]
           );
GO


/*******************
* Operator Enums 
*  Conditions Enum :
* -1 - No filter
*  0 - Null
*  1 - Not Null
*  2 - Equals
*  3 - NotEquals
*  ---- for strings ---
*  4 - StartsWith
*  5 - EndsWith
*  6 - Contains
*  ---- for int, decimal, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Members_Search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Members_Search]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter FirstNameOperator="4" FirstNameValue="jeevan"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
--EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter PhoneNumberOperator="2" PhoneNumberValue="8173078882"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
--EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter MemberNumberOperator="2" MemberNumberValue="123"></Filter></ROW>',@startInd=1,@endInd=20,@pageSize=100,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3
-- EXEC [dbo].[dms_Members_Search] @whereClauseXML=N'<ROW><Filter VINOperator="4" VINValue="K1234422323N1233"></Filter></ROW>',@startInd=1,@endInd=10,@pageSize=10,@sortColumn=N'MemberNumber',@sortOrder=N'ASC',@programID=3

CREATE PROCEDURE [dbo].[dms_Members_Search](   
   @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10   
 , @sortColumn nvarchar(100)  = 'MemberNumber'   
 , @sortOrder nvarchar(100) = 'ASC'   
 , @programID INT = NULL   
 )   
 AS   
 BEGIN   
    
	SET NOCOUNT ON    
	SET FMTONLY OFF;
	-- KB : Temporary resultsets. These resultsets are used to prepare mangeable resultsets.
	CREATE TABLE #FinalResultsFiltered(     

	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	Suffix nvarchar(50)  NULL ,    
	Prefix nvarchar(50)  NULL ,    
	City nvarchar(50)  NULL ,    
	StateProvince nvarchar(50)  NULL ,    
	PostalCode nvarchar(50)  NULL ,    
	HomePhoneNumber nvarchar(50)  NULL ,    
	WorkPhoneNumber nvarchar(50)  NULL ,    
	CellPhoneNumber nvarchar(50)  NULL ,  
	ProgramID INT NULL, -- KB: ADDED IDS  
	Program nvarchar(50)  NULL ,    
	POCount INT NULL,  
	ExpirationDate DATETIME NULL,   
	EffectiveDate DATETIME NULL,
	VIN nvarchar(50)  NULL ,    
	VehicleID INT NULL, -- KB: Added VehicleID
	[StateProvinceID] INT  NULL,
	MiddleName   nvarchar(50)  NULL , 
	)    

	CREATE TABLE #FinalResultsFormatted(      
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,  
	VehicleID INT NULL, -- KB: Added VehicleID  
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL     
	)    

	CREATE TABLE #FinalResultsSorted(     
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL , 
	VehicleID INT NULL, -- KB: Added VehicleID   
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL     
	)  
	CREATE TABLE #FinalResultsDistinct(     
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),    
	MemberID int  NULL ,   
	MembershipID INT NULL,   
	MemberNumber nvarchar(50)  NULL ,    
	Name nvarchar(200)  NULL ,    
	[Address] nvarchar(max)  NULL ,    
	PhoneNumber nvarchar(50)  NULL , 
	ProgramID INT NULL, -- KB: ADDED IDS   
	Program nvarchar(50)  NULL ,    
	POCount int  NULL ,    
	MemberStatus nvarchar(50)  NULL ,    
	LastName nvarchar(50)  NULL ,    
	FirstName nvarchar(50)  NULL ,    
	VIN nvarchar(50)  NULL ,  
	VehicleID INT NULL, -- KB: Added VehicleID  
	State nvarchar(50)  NULL ,    
	ZipCode nvarchar(50)  NULL     
	)  

	CREATE TABLE #SearchPrograms (
	ProgramID int, 
	ProgramName nvarchar(200),
	ClientID int
	)
	
	INSERT INTO #SearchPrograms (ProgramID, ProgramName, ClientID)
	SELECT ProgramID, ProgramName, ClientID
	--FROM [dbo].[fnc_GetMemberSearchPrograms](9) --@programID)
	FROM [dbo].[fnc_GetMemberSearchPrograms] (@programID)
	
	CREATE CLUSTERED INDEX IDX_SearchPrograms ON #SearchPrograms(ProgramID)
	--Select * From #SearchPrograms
	--Drop table #SearchPrograms
	
	DECLARE @idoc int    
	IF @whereClauseXML IS NULL     
	BEGIN    
	SET @whereClauseXML = '<ROW><Filter     
	MemberIDOperator="-1"     
	MemberNumberOperator="-1"     
	PhoneNumberOperator="-1"     
	ProgramOperator="-1"     
	LastNameOperator="-1"     
	FirstNameOperator="-1"     
	VINOperator="-1"     
	StateOperator="-1"    
	ZipCodeOperator = "-1"   
	></Filter></ROW>'    
	END    
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML    

	DECLARE @tmpForWhereClause TABLE    
	(    
	MemberIDOperator INT NOT NULL,    
	MemberIDValue int NULL,    
	MemberNumberOperator INT NOT NULL,    
	MemberNumberValue nvarchar(50) NULL,    
	PhoneNumberOperator INT NOT NULL,    
	PhoneNumberValue nvarchar(50) NULL,    
	ProgramOperator INT NOT NULL,    
	ProgramValue nvarchar(50) NULL,    
	LastNameOperator INT NOT NULL,    
	LastNameValue nvarchar(50) NULL,    
	FirstNameOperator INT NOT NULL,    
	FirstNameValue nvarchar(50) NULL,    
	VINOperator INT NOT NULL,    
	VINValue nvarchar(50) NULL,    
	StateOperator INT NOT NULL,    
	StateValue nvarchar(50) NULL,  
	ZipCodeOperator INT NOT NULL,    
	ZipCodeValue   nvarchar(50) NULL  
	)    

	-- Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'     

	INSERT INTO @tmpForWhereClause    
	SELECT      
			ISNULL(MemberIDOperator,-1),    
			MemberIDValue ,    
			ISNULL(MemberNumberOperator,-1),    
			MemberNumberValue ,    
			ISNULL(PhoneNumberOperator,-1),    
			PhoneNumberValue ,    
			ISNULL(ProgramOperator,-1),    
			ProgramValue ,    
			ISNULL(LastNameOperator,-1),    
			LastNameValue ,    
			ISNULL(FirstNameOperator,-1),    
			FirstNameValue ,    
			ISNULL(VINOperator,-1),    
			VINValue ,    
			ISNULL(StateOperator,-1),    
			StateValue,    
			ISNULL(ZipCodeOperator,-1),    
			ZipCodeValue    
	FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (    
			MemberIDOperator INT,    
			MemberIDValue int     
			,MemberNumberOperator INT,    
			MemberNumberValue nvarchar(50)     
			,PhoneNumberOperator INT,    
			PhoneNumberValue nvarchar(50)     
			,ProgramOperator INT,    
			ProgramValue nvarchar(50)     
			,LastNameOperator INT,    
			LastNameValue nvarchar(50)     
			,FirstNameOperator INT,    
			FirstNameValue nvarchar(50)     
			,VINOperator INT,    
			VINValue nvarchar(50)     
			,StateOperator INT,    
			StateValue nvarchar(50)     
			,ZipCodeOperator INT,    
			ZipCodeValue nvarchar(50)   
	)     
	
	
	DECLARE @vinParam nvarchar(50)    
	SELECT @vinParam = VINValue FROM @tmpForWhereClause    

	DECLARE @memberEntityID INT  
	SELECT @memberEntityID = ID FROM Entity WHERE Name = 'Member'  
	--------------------- BEGIN -----------------------------    
	----   Create a temp variable or a CTE with the actual SQL search query ----------    
	----   and use that CTE in the place of <table> in the following SQL statements ---    
	--------------------- END -----------------------------    
	DECLARE @phoneNumber NVARCHAR(100)  
	SET @phoneNumber = (SELECT PhoneNumberValue FROM @tmpForWhereClause)  

	DECLARE @memberID INT
	DECLARE @memberNumber NVARCHAR(50)
	DECLARE @programCode NVARCHAR(50)
	DECLARE @firstName NVARCHAR(50)
	DECLARE @lastName NVARCHAR(50)
	DECLARE @state NVARCHAR(50)
	DECLARE @zip NVARCHAR(50)

	SELECT	@memberID = MemberIDValue,
			@memberNumber = MemberNumberValue,
			@programCode = ProgramValue,
			@firstName = FirstNameValue,
			@lastName = LastNameValue,
			@state = StateValue,
			@zip = ZipCodeValue
	FROM	@tmpForWhereClause

	
	SET FMTONLY OFF;  
	  
	IF @phoneNumber IS NULL  
	BEGIN  

	-- If vehicle is given, then let's use Vehicle in the left join (as the first table) else don't even consider vehicle table.

		IF @vinParam IS NOT NULL
		BEGIN

			SELECT	* 
			INTO	#TmpVehicle1
			FROM	Vehicle V WITH (NOLOCK)
			WHERE	V.VIN LIKE '%' + @vinParam + '%'


			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber-- PH.PhoneNumber AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber -- PW.PhoneNumber AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber -- PC.PhoneNumber AS CellPhoneNumber  
					, P.ID As ProgramID  -- KB: ADDED IDS
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate   
					, m.EffectiveDate 
					, v.VIN  
					, v.ID AS VehicleID
					, A.[StateProvinceID]
					,M.MiddleName 

			FROM #TmpVehicle1 v
			LEFT JOIN Member M WITH (NOLOCK) ON  (v.MemberID IS NULL OR v.MemberID = m.ID) 
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID AND v.MembershipID = MS.ID
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID   
			
			WHERE   ( @memberID IS NULL  OR @memberID = M.ID )
					 AND
					 (@memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%'
					 OR MS.AltMembershipNumber LIKE  '%' + @memberNumber + '%')    -- Lakshmi - Old Membership Search
					 AND
					 ( @zip is NULL OR A.PostalCode LIKE @zip +'%' )
					 AND
					 ( @programCode IS NULL OR P.Code = @programCode)
					 AND
					 ( @lastName IS NULL OR M.LastName LIKE @lastName + '%')
					 AND
					 ( @firstName IS NULL OR M.FirstName LIKE @firstName + '%')
					 AND
					 ( @vinParam IS NULL OR V.VIN LIKE '%' + @vinParam + '%')
					 AND
					 ( @state IS NULL OR A.StateProvinceID = @state)
			AND		ISNULL(M.IsActive,0) = 1
					 
			DROP TABLE #TmpVehicle1

		END -- End of Vin param check
		ELSE
		BEGIN

			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber-- PH.PhoneNumber AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber -- PW.PhoneNumber AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber -- PC.PhoneNumber AS CellPhoneNumber
					, P.ID As ProgramID  -- KB: ADDED IDS  
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate   
					, m.EffectiveDate 
					, '' AS VIN
					, NULL AS VehicleID
					, A.[StateProvinceID]
					,M.MiddleName 
			FROM Member M WITH (NOLOCK)  
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID   

			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID    
			
			WHERE   ( @memberID IS NULL  OR @memberID = M.ID )
					 AND
					 (@memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%'
					 OR MS.AltMembershipNumber LIKE  '%' + @memberNumber + '%')			-- Lakshmi - Old Membership Search
					 AND
					 ( @zip is NULL OR A.PostalCode LIKE @zip +'%' )
					 AND
					 ( @programCode IS NULL OR P.Code = @programCode)
					 AND
					 ( @lastName IS NULL OR M.LastName LIKE @lastName + '%')
					 AND
					 ( @firstName IS NULL OR M.FirstName LIKE @firstName + '%')
					 --AND
					 --( @vinParam IS NULL OR V.VIN LIKE '%' + @vinParam + '%')
					 AND
					 ( @state IS NULL OR A.StateProvinceID = @state)
			AND		ISNULL(M.IsActive,0) = 1
		END		
		
	END  -- End of Phone number is null check.
	ELSE  
	BEGIN
	
		SELECT *  
		INTO #tmpPhone  
		FROM PhoneEntity PH WITH (NOLOCK)  
		WHERE PH.EntityID = @memberEntityID   
		AND  PH.PhoneNumber = @phoneNumber   

		-- Consider VIN param.
		IF @vinParam IS NOT NULL
		BEGIN
		
			SELECT	* 
			INTO	#TmpVehicle
			FROM	Vehicle V WITH (NOLOCK)
			WHERE	V.VIN LIKE '%' + @vinParam + '%' 

			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber 
					, P.ID As ProgramID  -- KB: ADDED IDS 
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate 
					, m.EffectiveDate  
					, v.VIN
					, v.ID AS VehicleID
					, A.[StateProvinceID] 
					, M.MiddleName 
			FROM #TmpVehicle v
			LEFT JOIN Member M WITH (NOLOCK) ON  (v.MemberID IS NULL OR v.MemberID = m.ID) 
			JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID AND v.MembershipID = MS.ID
			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID    
			--LEFT OUTER join Vehicle v WITH (NOLOCK) ON 
			--						(
			--							(v.MemberID IS NULL OR v.MemberID = m.ID) AND
			--								v.MembershipID = MS.ID

			--							--	(@vinParam IS NULL AND M.ID IS NULL) 
			--							--	OR
			--							--(@vinParam IS NOT NULL 
			--							--	AND 
			--							--	(v.MemberID = m.ID 
			--							--		OR (v.MembershipID = MS.ID AND v.MemberID IS NULL) 
			--							--		--AND V.VIN = @vinParam
			--							--	) 
			--							--) 
			--						)
			JOIN @tmpForWhereClause TMP ON 1=1  
			   
			WHERE  ( (@memberID IS NULL OR @memberID = M.ID)
					 AND
					 ( @memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%'
					 OR MS.AltMembershipNumber LIKE  '%' + @memberNumber + '%')						-- Lakshmi - Old Membership Search
					 AND
					 ( @zip is NULL OR A.PostalCode LIKE @zip +'%' )
					 AND
					 ( @programCode IS NULL OR P.Code = @programCode)
					 AND
					 ( @lastName IS NULL OR M.LastName LIKE @lastName + '%')
					 AND
					 ( @firstName IS NULL OR M.FirstName LIKE @firstName + '%')
					 AND
					 ( @vinParam IS NULL OR V.VIN LIKE '%' + @vinParam + '%')
					 AND
					 ( @state IS NULL OR A.StateProvinceID = @state)
				  )
			AND		ISNULL(M.IsActive,0) = 1

			DROP TABLE #TmpVehicle
		END -- End of Vin param check
		ELSE
		BEGIN
			INSERT INTO #FinalResultsFiltered  
			SELECT DISTINCT TOP 1000   
					M.id AS MemberID  
					, M.MembershipID  
					, MS.MembershipNumber AS MemberNumber  
					, M.FirstName  
					, M.LastName  
					, M.Suffix  
					, M.Prefix      
					, A.City  
					, A.StateProvince  
					, A.PostalCode  
					, NULL AS HomePhoneNumber  
					, NULL AS WorkPhoneNumber  
					, NULL AS CellPhoneNumber  
					, P.ID As ProgramID  -- KB: ADDED IDS
					, P.[Description] AS Program    
					, 0 AS POCount -- Computed later  
					, m.ExpirationDate
					, m.EffectiveDate   
					, '' AS VIN
					, NULL AS VehicleID  
					, A.[StateProvinceID] 
					, M.MiddleName 
			FROM	#tmpPhone PH
			JOIN	Member M WITH (NOLOCK)  ON PH.RecordID = M.ID
			JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID    

			LEFT JOIN AddressEntity A WITH (NOLOCK) ON A.RecordID = M.ID AND A.EntityID = @memberEntityID  
			JOIN #SearchPrograms FP ON FP.ProgramID = M.ProgramID    
			JOIN Program P WITH (NOLOCK) ON P.ID = FP.ProgramID    
			--LEFT OUTER join Vehicle v WITH (NOLOCK) ON 
			--						(
			--							(v.MemberID IS NULL OR v.MemberID = m.ID) AND
			--								v.MembershipID = MS.ID

			--							--	(@vinParam IS NULL AND M.ID IS NULL) 
			--							--	OR
			--							--(@vinParam IS NOT NULL 
			--							--	AND 
			--							--	(v.MemberID = m.ID 
			--							--		OR (v.MembershipID = MS.ID AND v.MemberID IS NULL) 
			--							--		--AND V.VIN = @vinParam
			--							--	) 
			--							--) 
			--						)
			JOIN @tmpForWhereClause TMP ON 1=1  
			   
			WHERE  ( (@memberID IS NULL OR @memberID = M.ID)
					 AND
					 ( @memberNumber IS NULL OR MS.MembershipNumber LIKE  '%' + @memberNumber + '%'
					 OR MS.AltMembershipNumber LIKE  '%' + @memberNumber + '%')					-- Lakshmi - Old Membership Search
					 AND
					 ( @zip is NULL OR A.PostalCode LIKE @zip +'%' )
					 AND
					 ( @programCode IS NULL OR P.Code = @programCode)
					 AND
					 ( @lastName IS NULL OR M.LastName LIKE @lastName + '%')
					 AND
					 ( @firstName IS NULL OR M.FirstName LIKE @firstName + '%')
					 --AND
					 --( @vinParam IS NULL OR V.VIN LIKE '%' + @vinParam + '%')
					 AND
					 ( @state IS NULL OR A.StateProvinceID = @state)
				  )
			AND		ISNULL(M.IsActive,0) = 1
		END
	END  -- End of phone number not null check

	-- DEBUG:   
	--SELECT COUNT(*) AS Filtered FROM #FinalResultsFiltered  

	-- Do all computations  
	INSERT INTO #FinalResultsFormatted  
	SELECT   F.MemberID  
	, F.MembershipID  
	, F.MemberNumber     
	--, REPLACE(RTRIM(COALESCE(F.LastName, '')   
	-- + COALESCE(' ' + F.Suffix, '')   
	-- + COALESCE(', ' + F.FirstName, '')), ' ', ' ')   
	-- + COALESCE(' ' + F.Prefix, '') AS Name  
	,REPLACE(RTRIM( 
	COALESCE(F.FirstName, '') + 
	COALESCE(' ' + left(F.MiddleName,1), '') + 
	COALESCE(' ' + F.LastName, '') +
	COALESCE(' ' + F.Suffix, '')
	), ' ', ' ') AS MemberName
	,(ISNULL(F.City,'') + ',' + ISNULL(F.StateProvince,'') + ' ' + ISNULL(F.PostalCode,'')) AS [Address]     
	, COALESCE(F.HomePhoneNumber, F.WorkPhoneNumber, F.CellPhoneNumber, '') As PhoneNumber 
	, F.ProgramID -- KB: ADDED IDS    
	, F.Program    
	,(SELECT COUNT(*) FROM [Case] WHERE MemberID = F.MemberID) AS POCount   
	-- Ignore time while comparing the dates here  
	--,CASE WHEN F.EffectiveDate <= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0) AND F.ExpirationDate >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)   
	--  THEN 'Active'   
	--  ELSE 'Inactive'   
	-- END 
	-- KB: Considering Effective and Expiration Dates to calculate member status
	,CASE WHEN ISNULL(F.EffectiveDate,@minDate) <= @now AND ISNULL(F.ExpirationDate,@minDate) >= @now
			THEN 'Active'
			ELSE 'Inactive'
	END AS MemberStatus
	, F.LastName  
	, F.FirstName  
	,CASE WHEN ISNULL(@vinParam,'') <> ''    
	THEN  F.VIN    
	ELSE  ''    
	END AS VIN   
	, F.VehicleID  
	, F.StateProvinceID AS [State]  
	, F.PostalCode AS ZipCode  

	FROM #FinalResultsFiltered F  

	IF @phoneNumber IS NULL  
	BEGIN  

		INSERT INTO #FinalResultsSorted  
		SELECT  F.MemberID,  
		F.MembershipID,    
		F.MemberNumber,     
		F.Name,    
		F.[Address],    
		COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber,  
		F.ProgramID, -- KB: ADDED IDS     
		F.Program,    
		F.POCount,    
		F.MemberStatus,    
		F.LastName,    
		F.FirstName ,    
		F.VIN ,
		F.VehicleID,    
		F.[State] ,    
		F.ZipCode   
		FROM  #FinalResultsFormatted F   
		LEFT JOIN PhoneEntity PH WITH (NOLOCK) ON PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PH.PhoneNumber)  
		LEFT JOIN PhoneEntity PW WITH (NOLOCK) ON PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PW.PhoneNumber)  
		LEFT JOIN PhoneEntity PC WITH (NOLOCK) ON PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID AND ( @phoneNumber IS NULL OR @phoneNumber = PC.PhoneNumber) 

		ORDER BY     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'    
		THEN F.MembershipID END ASC,     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'    
		THEN F.MembershipID END DESC ,    

		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'    
		THEN F.MemberNumber END ASC,     
		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'    
		THEN F.MemberNumber END DESC ,    

		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'    
		THEN F.Name END ASC,     
		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'    
		THEN F.Name END DESC ,    

		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'    
		THEN F.Address END ASC,     
		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'    
		THEN F.Address END DESC ,    

		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC ,    

		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,    

		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'    
		THEN F.POCount END ASC,     
		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'    
		THEN F.POCount END DESC ,    

		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'ASC'    
		THEN F.MemberStatus END ASC,     
		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'DESC'    
		THEN F.MemberStatus END DESC    

	END  
	ELSE  

	BEGIN  
	-- DEBUG  :SELECT COUNT(*) FROM #tmpPhone  

		INSERT INTO #FinalResultsSorted  
		SELECT  F.MemberID,  
		 F.MembershipID,    
		 F.MemberNumber,     
		 F.Name,    
		 F.[Address],    
		 COALESCE(PH.PhoneNumber, PW.PhoneNumber, PC.PhoneNumber, '') As PhoneNumber, 
		 F.ProgramID, --KB: ADDED IDS      
		 F.Program,    
		 F.POCount,    
		 F.MemberStatus,    
		 F.LastName,    
		 F.FirstName ,    
		F.VIN , 
		F.VehicleID,   
		F.[State] ,    
		F.ZipCode   
		FROM  #FinalResultsFormatted F   
		LEFT JOIN #tmpPhone PH WITH (NOLOCK) ON PH.RecordID = F.MemberID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID 
		LEFT JOIN #tmpPhone PW WITH (NOLOCK) ON PW.RecordID = F.MemberID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID 
		LEFT JOIN #tmpPhone PC WITH (NOLOCK) ON PC.RecordID = F.MemberID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID 
		WHERE (PH.PhoneNumber = @phoneNumber OR PW.PhoneNumber = @phoneNumber OR PC.PhoneNumber=@phoneNumber)
		ORDER BY     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'ASC'    
		THEN F.MembershipID END ASC,     
		CASE WHEN @sortColumn = 'MemberID' AND @sortOrder = 'DESC'    
		THEN F.MembershipID END DESC ,    

		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'    
		THEN F.MemberNumber END ASC,     
		CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'    
		THEN F.MemberNumber END DESC ,    

		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'    
		THEN F.Name END ASC,      
		CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'    
		THEN F.Name END DESC ,    

		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'    
		THEN F.Address END ASC,     
		CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'    
		THEN F.Address END DESC ,    

		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC ,    

		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,    

		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'ASC'    
		THEN F.POCount END ASC,     
		CASE WHEN @sortColumn = 'POCount' AND @sortOrder = 'DESC'    
		THEN F.POCount END DESC ,    

		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'ASC'    
		THEN F.MemberStatus END ASC,     
		CASE WHEN @sortColumn = 'MemberStatus' AND @sortOrder = 'DESC'    
		THEN F.MemberStatus END DESC
		
		DROP TABLE #tmpPhone    
	END     
-- DEBUG:
--SELECT * FROM #FinalResultsSorted

	-- Let's delete duplicates from #FinalResultsSorted and then insert into Distinct.
	
	;WITH wSorted 
	AS
	(
		SELECT ROW_NUMBER() OVER (PARTITION BY 
			F.MemberID,  
			F.MembershipID,    
			F.MemberNumber,     
			F.Name,    
			F.[Address],    
			F.PhoneNumber,    
			F.Program,    
			F.POCount,    
			F.MemberStatus,    
			F.VIN,
			F.VehicleID ORDER BY F.RowNum) AS sRowNumber	
		FROM #FinalResultsSorted F
	)
	
	DELETE FROM wSorted WHERE sRowNumber > 1
	
	INSERT INTO #FinalResultsDistinct(
			MemberID,  
			MembershipID,    
			MemberNumber,     
			Name,    
			[Address],    
			PhoneNumber,  
			ProgramID, -- KB: ADDED IDS      
			Program,    
			POCount,    
			MemberStatus,    
			VIN,
			VehicleID 
	)   
	SELECT	F.MemberID,  
			F.MembershipID,    
			F.MemberNumber,     
			F.Name,    
			F.[Address],    
			F.PhoneNumber,
			F.ProgramID, -- KB: ADDED IDS        
			F.Program,    
			F.POCount,    
			F.MemberStatus,    
			F.VIN,
			F.VehicleID
			
	FROM #FinalResultsSorted F
	ORDER BY 
	CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'    
		THEN F.PhoneNumber END ASC,     
		CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'    
		THEN F.PhoneNumber END DESC,
		F.RowNum  
		

	DECLARE @count INT       
	SET @count = 0       
	SELECT @count = MAX(RowNum) FROM #FinalResultsDistinct   
	SET @endInd = @startInd + @pageSize - 1    
	IF @startInd  > @count       
	BEGIN       
	DECLARE @numOfPages INT        
	SET @numOfPages = @count / @pageSize       
	IF @count % @pageSize > 1       
	BEGIN       
	SET @numOfPages = @numOfPages + 1       
	END       
	SET @startInd = ((@numOfPages - 1) * @pageSize) + 1       
	SET @endInd = @numOfPages * @pageSize       
	END     



	SELECT @count AS TotalRows, F.MemberID,  
		F.MembershipID,    
	   F.MemberNumber,     
	   F.Name,    
	   F.[Address],    
	   F.PhoneNumber,  
	   F.ProgramID, -- KB: ADDED IDS      
	   F.Program,    
	   F.POCount,    
	   F.MemberStatus,    
	   F.VIN,
	   F.VehicleID   
	   FROM    
	   #FinalResultsDistinct F WHERE RowNum BETWEEN @startInd AND @endInd    
	     
	DROP TABLE #FinalResultsFiltered  
	DROP TABLE #FinalResultsFormatted  
	DROP TABLE #FinalResultsSorted 
	DROP TABLE #FinalResultsDistinct


END
GO

-- Get Vendor Billing with logic added to check for Alternate
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get @VendorLocationID=356, @POID=619
 CREATE PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get( 
	@VendorLocationID INT =NULL
	, @POID INT = NULL
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET FMTONLY OFF
SELECT V.ID
	--, CASE
	--	WHEN ISNULL(CRS.ID,'') = '' THEN 'Not Contracted'
	--	ELSE 'Contracted'
	--	END AS 'ContractStatus'
	, CASE
		WHEN ContractedVendors.ContractID IS NOT NULL AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'
		ELSE 'Not Contracted' 
		END AS ContractStatus
	, V.Name
	, V.VendorNumber
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN ''
		WHEN ISNULL(VI.ID, '') <> '' THEN VI.BillingAddressLine1
		ELSE AE.Line1
		END AS Line1
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN ''
		WHEN ISNULL(VI.ID, '') <> '' THEN VI.BillingAddressLine2
		ELSE AE.Line2
	END AS Line2
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN ''
		WHEN ISNULL(VI.ID, '') <> '' THEN VI.BillingAddressLine3
		ELSE AE.Line3
	END AS Line3
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN 'No billing address on file'
		WHEN ISNULL(VI.ID,'') <> '' THEN
		ISNULL(REPLACE(RTRIM(
			COALESCE(VI.BillingAddressCity, '') +
			COALESCE(', ' + VI.BillingAddressStateProvince, '') +
			COALESCE(' ' + VI.BillingAddressPostalCode, '') +
			COALESCE(' ' + VI.BillingAddressCountryCode, '')
		), ' ', ' ')
	,'')
	ELSE ISNULL(REPLACE(RTRIM(
			COALESCE(AE.City, '') +
			COALESCE(', ' + AE.StateProvince, '') +
			COALESCE(' ' + AE.PostalCode, '') +
			COALESCE(' ' + AE.CountryCode, '')
		), ' ', ' ')
	,'')
	END AS BillingCityStZip
	, ISNULL(REPLACE(RTRIM(
		COALESCE(V.TaxSSN,'')+
		COALESCE(V.TaxEIN,'')
		), ' ', ' ')
	,'') AS TaxID
	, PE.PhoneNumber
	, V.Email
	, (V.ContactFirstName + ' ' + V.ContactLastName) AS ContactName
	, VI.ID AS VendorInvoiceID
FROM		Vendor V
JOIN		VendorLocation VL ON VL.VendorID = V.ID
LEFT JOIN	Contract C ON C.VendorID = V.ID
			AND C.IsActive = 1
LEFT JOIN ContractRateSchedule CRS ON CRS.ContractID = V.ID
			AND C.IsActive = 1
LEFT JOIN	AddressEntity AE ON AE.RecordID = V.ID
			AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
			AND	AE.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Billing')
LEFT JOIN	PhoneEntity PE ON PE.RecordID = V.ID
			AND	PE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
			AND PE.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Office')
LEFT JOIN	VendorInvoice VI ON VI.PurchaseOrderID = @POID
LEFT OUTER JOIN(
			SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID
			FROM dbo.fnGetContractedVendors() cv
			) ContractedVendors ON V.ID = ContractedVendors.VendorID 
WHERE VL.ID = @VendorLocationID
END
GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Location_Services_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Location_Services_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 --EXEC dms_Vendor_Location_Services_List_Get @VendorID=1, @VendorLocationID=1
CREATE PROCEDURE [dms_Vendor_Location_Services_List_Get](
	@VendorID INT = NULL
 ,	@VendorLocationID INT = NULL
 )
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
DECLARE @FinalResults AS TABLE(
	SortOrder INT NULL,
	ServiceGroup NVARCHAR(255) NULL,
	ServiceName nvarchar(100)  NULL ,
	ProductID int  NULL ,
	VehicleCategorySequence int  NULL ,
	ProductCategory nvarchar(100)  NULL ,
	IsAvailByVendor bit default 0 ,
	IsAvailByVendorLocation bit default 0
) 

INSERT INTO @FinalResults (SortOrder, ServiceGroup,ServiceName,ProductID,VehicleCategorySequence,ProductCategory)
	SELECT 
			 CASE	WHEN vc.name is NULL THEN 2 
					ELSE 1 
			 END AS SortOrder
			,CASE	WHEN vc.name is NULL THEN 'Other' 
					ELSE vc.name 
			 END AS ServiceGroup
			,REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
			--,ISNULL(vc.Name,'') + CASE WHEN ISNULL(vc.Name,'') <> '' THEN ' - ' ELSE '' END  + REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory			
	FROM Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
	LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('PrimaryService', 'SecondaryService')
	AND p.Name Not in ('Concierge', 'Information', 'Tech')
	AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee')

	UNION
	SELECT 
			3 AS SortOrder
			,'Additional' AS ServiceGroup
			,p.Name AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory
	FROM	Product p
	JOIN ProductCategory pc on p.productCategoryid = pc.id
	JOIN ProductType pt on p.ProductTypeID = pt.ID
	JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
	LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
	LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
	WHERE pt.Name = 'Service'
	AND pst.Name IN ('AdditionalService')
	AND p.Name Not in ('Concierge', 'Information', 'Tech')
	AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials')
	
	UNION ALL
	
	SELECT 
			 4 AS SortOrder
			,'Repair' AS ServiceGroup
			, p.Name AS ServiceName
			,p.ID AS ProductID
			,vc.Sequence VehicleCategorySequence
			,pc.Name ProductCategory
	FROM	Product p
	Join	ProductCategory pc on p.productCategoryid = pc.id
	Join	ProductType pt on p.ProductTypeID = pt.ID
	Join	ProductSubType pst on p.ProductSubTypeID = pst.id
	Left Outer Join VehicleCategory vc on p.VehicleCategoryID = vc.ID
	Left Outer Join VehicleType vt on p.VehicleTypeID = vt.ID
	Where	pt.Name = 'Attribute'
	and		pc.Name = 'Repair'
	and		pst.Name NOT IN ('Client')	
	ORDER BY SortOrder, VehicleCategorySequence, ProductCategory
	
	UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
	LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
	WHERE VP.VendorID=@VendorID

	UPDATE @FinalResults SET IsAvailByVendorLocation = 1 FROM  @FinalResults T
	LEFT JOIN VendorLocationProduct VLP ON VLP.ProductID = T.ProductID
	WHERE VLP.VendorLocationID=@VendorLocationID

	SELECT *  FROM @FinalResults WHERE IsAvailByVendor=1 OR IsAvailByVendorLocation = 1
END
GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Services_Repair_List_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Services_Repair_List_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 --EXEC dms_Vendor_Services_Repair_List_Get @VendorID=1
CREATE PROCEDURE dms_Vendor_Services_Repair_List_Get @VendorID INT
AS
BEGIN
	
SET NOCOUNT ON

DECLARE @FinalResults AS TABLE(
	ServiceName nvarchar(100)  NULL ,
	ProductID int  NULL ,
	VehicleCategorySequence int  NULL ,
	ProductCategory nvarchar(100)  NULL ,
	IsAvailByVendor bit default 0
) 

INSERT INTO @FinalResults (ServiceName,ProductID,VehicleCategorySequence,ProductCategory)
SELECT 
 pst.Name + ' - ' + p.Name AS ServiceName
,p.ID AS ProductID
,vc.Sequence VehicleCategorySequence
,pc.Name ProductCategory
FROM Product p
Join ProductCategory pc on p.productCategoryid = pc.id
Join ProductType pt on p.ProductTypeID = pt.ID
Join ProductSubType pst on p.ProductSubTypeID = pst.id
Left Outer Join VehicleCategory vc on p.VehicleCategoryID = vc.ID
Left Outer Join VehicleType vt on p.VehicleTypeID = vt.ID
Where pt.Name = 'Attribute'
and pc.Name = 'Repair'
and pst.Name NOT IN ('Client')
--order by pt.Name, pst.Name, pc.Name, p.Name, vc.Name, vt.Name

UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
WHERE VP.VendorID=@VendorID

Select * from @FinalResults
Order By ServiceName
END
GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_tempcc_match_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_tempcc_match_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vendor_tempcc_match_update] @tempccIdXML = '<Tempcc><ID>1</ID><ID>2</ID><ID>3</ID><ID>4</ID></Tempcc>',@currentUser = 'demouser'
 CREATE PROCEDURE [dbo].[dms_vendor_tempcc_match_update](
	@tempccIdXML XML,
	@currentUser NVARCHAR(50)
  )
 AS
 BEGIN
 
    SET FMTONLY OFF
	SET NOCOUNT ON

	DECLARE @now DATETIME = GETDATE()
	DECLARE @CCExpireDays int = 30
	DECLARE @MinCreateDate datetime

	DECLARE @Matched INT =0
		,@MatchedAmount money =0
		,@Unmatched int = 0
		,@UnmatchedAmount money = 0
		,@Posted INT=0
		,@PostedAmount money=0
		,@Cancelled INT=0
		,@CancelledAmount money=0
		,@Exception INT=0
		,@ExceptionAmount money=0
		,@MatchedIds nvarchar(max)=''

	DECLARE @MatchedTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Matched')
		,@UnMatchedTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'UnMatched')
		,@PostededTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Posted')
		,@CancelledTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Cancelled')
		,@ExceptionTemporaryCreditCardStatusID int = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Exception')

	-- Build table of selected items
	CREATE TABLE #SelectedTemporaryCC 
	(	
		ID INT IDENTITY(1,1),
		TemporaryCreditCardID INT
	)

	INSERT INTO #SelectedTemporaryCC
	SELECT tcc.ID
	FROM TemporaryCreditCard tcc WITH (NOLOCK)
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @tempccIdXML.nodes('/Tempcc/ID') T(c)
			) T ON tcc.ID = T.ID

	CREATE CLUSTERED INDEX IDX_SelectedTemporaryCC ON #SelectedTemporaryCC(TemporaryCreditCardID)

		
	/**************************************************************************************************/
	-- Update (Reset) Selected items to Unmatched where status is not Posted
	UPDATE tc SET 
		TemporaryCreditCardStatusID = @UnmatchedTemporaryCreditCardStatusID
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = NULL
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	WHERE tcs.Name <> 'Posted'


	/**************************************************************************************************/
	--Update for Exact match on PO# and CC#
	--Conditions:
	--	PO# AND CC# match exactly
	--	PO Status is Issued or Issued Paid
	--	PO has not been deleted
	--	PO does not already have a related Vendor Invoice
	--	Temporary CC has not already been posted
	--Match Status
	--	Total CC charge amount LESS THAN or EQUAL to the PO amount
	--Exception Status
	--	Total CC charge amount GREATER THAN the PO amount
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE
				 --Cancelled 
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Cancelled', 'Issued', 'Issued-Paid')) 
						AND vi.ID IS NULL 
						AND (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
						AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN @CancelledTemporaryCreditCardStatusID
				 --Matched
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > 0
                        AND (ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount
                              OR ISNULL(tc.IsExceptionOverride,0) = 1)
					THEN @MatchedTemporaryCreditCardStatusID
				 --Cancelled	
				 WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN @CancelledTemporaryCreditCardStatusID
				 --Exception
				 ELSE @ExceptionTemporaryCreditCardStatusID
				 END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				 --Cancelled 
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Cancelled', 'Issued', 'Issued-Paid')) 
						AND vi.ID IS NULL 
						AND (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
						AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN NULL
				 --Matched
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > 0
                        AND (ISNULL(tc.TotalChargedAmount,0) <= po.PurchaseOrderAmount
                              OR ISNULL(tc.IsExceptionOverride,0) = 1)
					THEN NULL
				 --Exception: PO has not been charged
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) = 0
					THEN 'Credit card has not been charged by the vendor'
				 --Exception: Charge more than PO Amount
				 WHEN po.IsActive = 1 
						AND po.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') 
						AND vi.ID IS NULL 
						AND ISNULL(tc.TotalChargedAmount,0) > po.PurchaseOrderAmount 
					THEN 'Charge amount exceeds PO amount'
				 --Cancelled	
				 WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN NULL
				 -- Other Exceptions	
				 WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 ELSE NULL
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = RIGHT(tc.CreditCardNumber,5)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID and vi.IsActive = 1
	WHERE 1=1
	AND tcs.Name = 'Unmatched'
		
		
		
	/**************************************************************************************************/
	-- Update For No matches on PO# or CC#
	-- Conditions:
	--	No potential PO matches exist
	--  No potential CC# matches exist
	-- Cancelled Status
	--	Temporary Credit Card Issue Status is Cancelled
	-- Exception Status
	--	Temporary Credit Card Issue Status is NOT Cancelled
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE 
				WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN @CancelledTemporaryCreditCardStatusID
				ELSE @ExceptionTemporaryCreditCardStatusID
				END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN NULL
				ELSE 'No matching PO# or CC#'
				END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	WHERE  1=1
	AND tcs.Name = 'Unmatched'
	AND NOT EXISTS (
		SELECT *
		FROM PurchaseOrder po
		WHERE
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		)
	AND NOT EXISTS (
		SELECT *
		FROM PurchaseOrder po
		WHERE  
		po.PurchaseOrderNumber <> LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND po.CompanyCreditCardNumber IS NOT NULL
		AND RIGHT(RTRIM(po.CompanyCreditCardNumber),5) = RIGHT(tc.CreditCardNumber,5)
		)


	/**************************************************************************************************/
	--Update to Exception Status - PO matches and CC# does not match
	-- Conditions
	--	PO# matches exactly
	--	CC# does not match or is blank
	UPDATE tc SET
		TemporaryCreditCardStatusID = 
			CASE
				WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN @CancelledTemporaryCreditCardStatusID
				WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN @CancelledTemporaryCreditCardStatusID
				ELSE @ExceptionTemporaryCreditCardStatusID
				END
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE 
				 --Cancelled	
				 WHEN vi.ID IS NOT NULL AND ISNULL(tc.TotalChargedAmount,0) = 0 THEN NULL
				 WHEN (tc.IssueStatus = 'Cancel' OR DATEADD(dd,@CCExpireDays,tc.IssueDate) <= @now)
					AND ISNULL(tc.TotalChargedAmount,0) = 0 
					THEN NULL
				 --Exceptions
				 WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 WHEN RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = '' THEN 'Matching PO does not have a credit card number'
				 ELSE 'CC# Mismatch'
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber = LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND	RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) <> RIGHT(tc.CreditCardNumber,5)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID and vi.IsActive = 1
	where tcs.Name = 'Unmatched'


	/**************************************************************************************************/
	--Update to Exception Status - PO does not match and CC# matches
	-- Conditions
	--	PO# does not match
	--	CC# matches exactly
	UPDATE tc SET
		TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID
		,ModifyBy = @currentUser
		,ModifyDate = @now
		,ExceptionMessage = 
			CASE WHEN po.IsActive = 0 THEN 'Matching PO has been deleted' 
				 WHEN po.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name like 'Issued%') THEN 'Matching PO not set to Issued status' 
				 WHEN vi.ID IS NOT NULL THEN 'Matching PO has already been invoiced' 
				 ELSE 'PO# Mismatch'
				 END
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	JOIN TemporaryCreditCardStatus tcs ON
		tc.TemporaryCreditCardStatusID = tcs.ID
	JOIN PurchaseOrder po ON
		po.PurchaseOrderNumber <> LTRIM(RTRIM(tc.ReferencePurchaseOrderNumber))
		AND	RIGHT(RTRIM(ISNULL(po.CompanyCreditCardNumber,'')),5) = RIGHT(tc.CreditCardNumber,5)
		AND po.CreateDate >= DATEADD(dd,1,tc.IssueDate)
	LEFT OUTER JOIN VendorInvoice vi on po.id = vi.PurchaseOrderID and vi.IsActive = 1
	where tcs.Name = 'Unmatched'


	/**************************************************************************************************/
	-- Prepare Results
	SELECT 
		@Matched = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @MatchedTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@MatchedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @MatchedTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Unmatched = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @UnMatchedTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@UnmatchedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @UnMatchedTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Posted = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @PostededTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@PostedAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @PostededTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Cancelled = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @CancelledTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@CancelledAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @CancelledTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)

		,@Exception = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID THEN 1 ELSE 0 END)
		,@ExceptionAmount = SUM(CASE WHEN tc.TemporaryCreditCardStatusID = @ExceptionTemporaryCreditCardStatusID THEN ISNULL(tc.TotalChargedAmount,0) ELSE 0 END)
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID

	-- Build string of 'Matched' IDs
	SELECT @MatchedIds = @MatchedIds + CONVERT(varchar(20),tc.ID) + ',' 
	FROM TemporaryCreditCard tc
	JOIN #SelectedTemporaryCC stcc ON
		stcc.TemporaryCreditCardID = tc.ID
	WHERE tc.TemporaryCreditCardStatusID = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Matched')

	-- Remove ending comma from string or IDs
	IF LEN(@MatchedIds) > 1 
		SET @MatchedIds = LEFT(@MatchedIds, LEN(@MatchedIds) - 1)

	DROP TABLE #SelectedTemporaryCC
	
	SELECT @Matched 'MatchedCount',
		   @MatchedAmount 'MatchedAmount',
		   --@Unmatched 'UnmatchedCount',
		   --@UnmatchedAmount 'UnmatchedAmount',
		   @Posted 'PostedCount',
		   @PostedAmount 'PostedAmount',
		   @Cancelled 'CancelledCount',
		   @CancelledAmount 'CancelledAmount',
		   @Exception 'ExceptionCount',
		   @ExceptionAmount 'ExceptionAmount',
		   @MatchedIds 'MatchedIds'
END
 