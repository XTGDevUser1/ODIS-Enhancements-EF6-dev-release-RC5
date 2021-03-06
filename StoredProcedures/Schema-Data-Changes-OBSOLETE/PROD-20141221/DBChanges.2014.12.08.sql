/****** Object:  Table [dbo].[ConcernType]    Script Date: 12/08/2014 16:08:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ConcernType]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[ConcernType](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Description] [nvarchar](255) NULL,
	[Sequence] [int] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_ConcernType] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[Concern]    Script Date: 12/08/2014 16:08:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Concern]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Concern](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ConcernTypeID] [int] NULL,
	[Name] [nvarchar](50) NULL,
	[Description] [nvarchar](255) NULL,
	[Sequence] [int] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_Concern] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[CoachingConcern]    Script Date: 12/08/2014 16:08:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CoachingConcern]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[CoachingConcern](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ConcernTypeID] [int] NULL,
	[ConcernID] [int] NULL,
	[AgentUserName] [nvarchar](50) NULL,
	[TeamManager] [nvarchar](50) NULL,
	[CallRecordingID] [int] NULL,
	[ServiceRequestID] [int] NULL,
	[PurchaseOrderID] [int] NULL,
	[Notes] [nvarchar](max) NULL,
	[IsAppealed] [bit] NULL,
	[AppealedDate] [datetime] NULL,
	[IsInternalAppeal] [bit] NULL,
	[InternalAppealDate] [datetime] NULL,
	[AppealApproved] [bit] NULL,
	[IsCoached] [bit] NULL,
	[CoachedDate] [datetime] NULL,
	[PendingDate] [datetime] NULL,
	[SevereQualityViolation] [bit] NULL,
	[ZeroToleranceViolation] [bit] NULL,
	[IsActive] [bit] NULL,
	[CreateDate] [datetime] NULL,
	[CreateBy] [nvarchar](50) NULL,
	[ModifyDate] [datetime] NULL,
	[ModifyBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_CoachingConcern] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  ForeignKey [FK_CoachingConcern_Concern]    Script Date: 12/08/2014 16:08:41 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_CoachingConcern_Concern]') AND parent_object_id = OBJECT_ID(N'[dbo].[CoachingConcern]'))
ALTER TABLE [dbo].[CoachingConcern]  WITH CHECK ADD  CONSTRAINT [FK_CoachingConcern_Concern] FOREIGN KEY([ConcernID])
REFERENCES [dbo].[Concern] ([ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_CoachingConcern_Concern]') AND parent_object_id = OBJECT_ID(N'[dbo].[CoachingConcern]'))
ALTER TABLE [dbo].[CoachingConcern] CHECK CONSTRAINT [FK_CoachingConcern_Concern]
GO
/****** Object:  ForeignKey [FK_CoachingConcern_ConcernType]    Script Date: 12/08/2014 16:08:41 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_CoachingConcern_ConcernType]') AND parent_object_id = OBJECT_ID(N'[dbo].[CoachingConcern]'))
ALTER TABLE [dbo].[CoachingConcern]  WITH CHECK ADD  CONSTRAINT [FK_CoachingConcern_ConcernType] FOREIGN KEY([ConcernTypeID])
REFERENCES [dbo].[ConcernType] ([ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_CoachingConcern_ConcernType]') AND parent_object_id = OBJECT_ID(N'[dbo].[CoachingConcern]'))
ALTER TABLE [dbo].[CoachingConcern] CHECK CONSTRAINT [FK_CoachingConcern_ConcernType]
GO
/****** Object:  ForeignKey [FK_Concern_ConcernType]    Script Date: 12/08/2014 16:08:41 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Concern_ConcernType]') AND parent_object_id = OBJECT_ID(N'[dbo].[Concern]'))
ALTER TABLE [dbo].[Concern]  WITH CHECK ADD  CONSTRAINT [FK_Concern_ConcernType] FOREIGN KEY([ConcernTypeID])
REFERENCES [dbo].[ConcernType] ([ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Concern_ConcernType]') AND parent_object_id = OBJECT_ID(N'[dbo].[Concern]'))
ALTER TABLE [dbo].[Concern] CHECK CONSTRAINT [FK_Concern_ConcernType]
GO


-- INSERT VALUES


-------------------------------------------------------------------------------------------------------------------------------
-- Insert ConcernType Records
IF NOT EXISTS (SELECT * FROM ConcernType WHERE Name = 'ClientComplaint')
BEGIN
	INSERT ConcernType (Name, Description, Sequence, IsActive)
	VALUES ('ClientComplaint','Client Complaint',1,1)
END

IF NOT EXISTS (SELECT * FROM ConcernType WHERE Name = 'MembershipVerification')
BEGIN
	INSERT ConcernType (Name, Description, Sequence, IsActive)
	VALUES ('MembershipVerification','Membership Verification',2,1)
END

IF NOT EXISTS (SELECT * FROM ConcernType WHERE Name = 'ODISPOTab')
BEGIN
	INSERT ConcernType (Name, Description, Sequence, IsActive)
	VALUES ('ODISPOTab','ODIS-PO Tab',3,1)
END

IF NOT EXISTS (SELECT * FROM ConcernType WHERE Name = 'ODISFinishTab')
BEGIN
	INSERT ConcernType (Name, Description, Sequence, IsActive)
	VALUES ('ODISFinishTab','ODIS-Finish Tab',4,1)
END

IF NOT EXISTS (SELECT * FROM ConcernType WHERE Name = 'ODISMapTab')
BEGIN
	INSERT ConcernType (Name, Description, Sequence, IsActive)
	VALUES ('ODISMapTab','ODIS-Map Tab',5,1)
END

IF NOT EXISTS (SELECT * FROM ConcernType WHERE Name = 'ODISTechTab')
BEGIN
	INSERT ConcernType (Name, Description, Sequence, IsActive)
	VALUES ('ODISTechTab','ODIS-Tech Tab',6,1)
END

IF NOT EXISTS (SELECT * FROM ConcernType WHERE Name = 'ODISVehicleTab')
BEGIN
	INSERT ConcernType (Name, Description, Sequence, IsActive)
	VALUES ('ODISVehicleTab','ODIS-Vehicle Tab',7,1)
END

IF NOT EXISTS (SELECT * FROM ConcernType WHERE Name = 'QACalibrationFeedback')
BEGIN
	INSERT ConcernType (Name, Description, Sequence, IsActive)
	VALUES ('QACalibrationFeedback','QA-Calibration Feedback',8,1)
END

IF NOT EXISTS (SELECT * FROM ConcernType WHERE Name = 'QACustomerExperience')
BEGIN
	INSERT ConcernType (Name, Description, Sequence, IsActive)
	VALUES ('QACustomerExperience','QA-Customer Experience',9,1)
END

IF NOT EXISTS (SELECT * FROM ConcernType WHERE Name = 'QADispatchFinish')
BEGIN
	INSERT ConcernType (Name, Description, Sequence, IsActive)
	VALUES ('QADispatchFinish','QA-Dispatch/Finish',10,1)
END

IF NOT EXISTS (SELECT * FROM ConcernType WHERE Name = 'QAMemberScreen')
BEGIN
	INSERT ConcernType (Name, Description, Sequence, IsActive)
	VALUES ('QAMemberScreen','QA-Member Screen',11,1)
END

IF NOT EXISTS (SELECT * FROM ConcernType WHERE Name = 'QAServiceMapScreen')
BEGIN
	INSERT ConcernType (Name, Description, Sequence, IsActive)
	VALUES ('QAServiceMapScreen','QA-Service/Map Screen',12,1)
END

IF NOT EXISTS (SELECT * FROM ConcernType WHERE Name = 'QAVehicleScreen')
BEGIN
	INSERT ConcernType (Name, Description, Sequence, IsActive)
	VALUES ('QAVehicleScreen','QA-Vehicle Screen',13,1)
END


--Select * from ConcernType
--Select * from Concern
-- ClientComplaint
DECLARE @clientCompalintConcernTypeID INT = (SELECT TOP 1 ID FROM ConcernType where Name='ClientComplaint')

IF NOT EXISTS(SELECT * FROM Concern where Name='AddedISPIncorrectly' AND ConcernTypeID = @clientCompalintConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@clientCompalintConcernTypeID,'AddedISPIncorrectly','Added ISP incorrectly',1,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='AddedISPIncorrectly' AND ConcernTypeID = @clientCompalintConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@clientCompalintConcernTypeID,'AddedRVWrong','Added RV wrong',2,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='AnsweredWithin3Seconds' AND ConcernTypeID = @clientCompalintConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@clientCompalintConcernTypeID,'AnsweredWithin3Seconds','Answered within 3 seconds',3,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='DidNotAddISPCorrectly' AND ConcernTypeID = @clientCompalintConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@clientCompalintConcernTypeID,'DidNotAddISPCorrectly','Did not add ISP correctly',4,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='DidNotFollowUp' AND ConcernTypeID = @clientCompalintConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@clientCompalintConcernTypeID,'DidNotFollowUp','Did not follow-up',5,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='DidNotRedispatch' AND ConcernTypeID = @clientCompalintConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@clientCompalintConcernTypeID,'DidNotRedispatch','Did not redispatch',6,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='DidNotVerifyConfirmSa?' AND ConcernTypeID = @clientCompalintConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@clientCompalintConcernTypeID,'DidNotVerifyConfirmSa?','Did not verify/confirm sa?',7,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='DocumentationMissing' AND ConcernTypeID = @clientCompalintConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@clientCompalintConcernTypeID,'DocumentationMissing','Documentation missing',8,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='GoldenRule' AND ConcernTypeID = @clientCompalintConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@clientCompalintConcernTypeID,'GoldenRule','Golden Rule',9,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='ImproperDecisionMaking' AND ConcernTypeID = @clientCompalintConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@clientCompalintConcernTypeID,'ImproperDecisionMaking','Improper decision making',10,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='IncorrectCoverageWarranty' AND ConcernTypeID = @clientCompalintConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@clientCompalintConcernTypeID,'IncorrectCoverageWarranty','Incorrect coverage/warranty',11,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='IncorrectDispatchProcedure' AND ConcernTypeID = @clientCompalintConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@clientCompalintConcernTypeID,'IncorrectDispatchProcedure','Incorrect dispatch procedure',12,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='LongETA<5Called' AND ConcernTypeID = @clientCompalintConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@clientCompalintConcernTypeID,'LongETA<5Called','Long ETA <5 called',13,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='MissingPertinentInformation' AND ConcernTypeID = @clientCompalintConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@clientCompalintConcernTypeID,'MissingPertinentInformation','Missing pertinent information',14,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='POTabError' AND ConcernTypeID = @clientCompalintConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@clientCompalintConcernTypeID,'POTabError','PO tab error',15,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='RudeToMember' AND ConcernTypeID = @clientCompalintConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@clientCompalintConcernTypeID,'RudeToMember','Rude to member',16,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='SoftSkillsCoaching' AND ConcernTypeID = @clientCompalintConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@clientCompalintConcernTypeID,'SoftSkillsCoaching','Soft skills coaching',17,1)
END

--MembershipVerification

DECLARE @membershipVerificationConcernTypeID INT = (SELECT TOP 1 ID FROM ConcernType where Name='MembershipVerification')

IF NOT EXISTS(SELECT * FROM Concern where Name='IncorrectlyAddingMember' AND ConcernTypeID = @membershipVerificationConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@membershipVerificationConcernTypeID,'IncorrectlyAddingMember','Incorrectly adding member',1,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='NewOwnerRegistration' AND ConcernTypeID = @membershipVerificationConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@membershipVerificationConcernTypeID,'NewOwnerRegistration','New owner registration',2,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='NotAddingCaller' AND ConcernTypeID = @membershipVerificationConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@membershipVerificationConcernTypeID,'NotAddingCaller','Not adding caller',3,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='ServicingWrongAssociation' AND ConcernTypeID = @membershipVerificationConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@membershipVerificationConcernTypeID,'ServicingWrongAssociation','Servicing wrong association',4,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='WrongCoverage' AND ConcernTypeID = @membershipVerificationConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@membershipVerificationConcernTypeID,'WrongCoverage','Wrong coverage',5,1)
END

--ODISPOTab

DECLARE @oDISPOTabConcernTypeID INT = (SELECT TOP 1 ID FROM ConcernType where Name='ODISPOTab')

IF NOT EXISTS(SELECT * FROM Concern where Name='IncorrectAmount' AND ConcernTypeID = @oDISPOTabConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@oDISPOTabConcernTypeID,'IncorrectAmount','Incorrect Amount',1,1)
END

--ODISFinishTab

DECLARE @oDISFinishTabConcernTypeID INT = (SELECT TOP 1 ID FROM ConcernType where Name='ODISFinishTab')

IF NOT EXISTS(SELECT * FROM Concern where Name='ClosedLoopIssue' AND ConcernTypeID = @oDISFinishTabConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@oDISFinishTabConcernTypeID,'ClosedLoopIssue','Closed loop issue',1,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='CodedCallIncorrectly' AND ConcernTypeID = @oDISFinishTabConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@oDISFinishTabConcernTypeID,'CodedCallIncorrectly','Coded call incorrectly',2,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='E-ClipIssue' AND ConcernTypeID = @oDISFinishTabConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@oDISFinishTabConcernTypeID,'E-ClipIssue','E-clip issue',3,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='NextAction' AND ConcernTypeID = @oDISFinishTabConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@oDISFinishTabConcernTypeID,'NextAction','Next Action',4,1)
END

--ODISMapTab

DECLARE @oDISMapTabConcernTypeID INT = (SELECT TOP 1 ID FROM ConcernType where Name='ODISMapTab')

IF NOT EXISTS(SELECT * FROM Concern where Name='LocationDestination' AND ConcernTypeID = @oDISMapTabConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@oDISMapTabConcernTypeID,'LocationDestination','Location/Destination',1,1)
END

--ODISTechTab

DECLARE @oDISTechTabConcernTypeID INT = (SELECT TOP 1 ID FROM ConcernType where Name='ODISTechTab')

IF NOT EXISTS(SELECT * FROM Concern where Name='DocumentationMissing' AND ConcernTypeID = @oDISTechTabConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@oDISTechTabConcernTypeID,'DocumentationMissing','Documentation missing',1,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='ImproperDecisionMaking' AND ConcernTypeID = @oDISTechTabConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@oDISTechTabConcernTypeID,'ImproperDecisionMaking','Improper decision making',2,1)
END

--ODISVehicleTab

DECLARE @oDISVehicleTabConcernTypeID INT = (SELECT TOP 1 ID FROM ConcernType where Name='ODISVehicleTab')

IF NOT EXISTS(SELECT * FROM Concern where Name='NoVehicleNotes' AND ConcernTypeID = @oDISVehicleTabConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@oDISVehicleTabConcernTypeID,'NoVehicleNotes','No vehicle notes',1,1)
END

--QACalibrationFeedback

DECLARE @qACalibrationFeedbackConcernTypeID INT = (SELECT TOP 1 ID FROM ConcernType where Name='QACalibrationFeedback')

IF NOT EXISTS(SELECT * FROM Concern where Name='FordCalibration' AND ConcernTypeID = @qACalibrationFeedbackConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qACalibrationFeedbackConcernTypeID,'FordCalibration','Ford Calibration',1,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='HagertyCalibration' AND ConcernTypeID = @qACalibrationFeedbackConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qACalibrationFeedbackConcernTypeID,'HagertyCalibration','Hagerty Calibration',2,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='NMCCalibration' AND ConcernTypeID = @qACalibrationFeedbackConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qACalibrationFeedbackConcernTypeID,'NMCCalibration','NMC Calibration',3,1)
END

--QACustomerExperience

DECLARE @qACustomerExperienceConcernTypeID INT = (SELECT TOP 1 ID FROM ConcernType where Name='QACustomerExperience')

IF NOT EXISTS(SELECT * FROM Concern where Name='DidNotFollowUp' AND ConcernTypeID = @qACustomerExperienceConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qACustomerExperienceConcernTypeID,'DidNotFollowUp','Did not follow up',1,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='Empathy' AND ConcernTypeID = @qACustomerExperienceConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qACustomerExperienceConcernTypeID,'Empathy','Empathy',2,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='ImproperHoldProcedure' AND ConcernTypeID = @qACustomerExperienceConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qACustomerExperienceConcernTypeID,'ImproperHoldProcedure','Improper hold procedure',3,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='IncorrectGreeting' AND ConcernTypeID = @qACustomerExperienceConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qACustomerExperienceConcernTypeID,'IncorrectGreeting','Incorrect greeting',4,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='ReassuranceStatement' AND ConcernTypeID = @qACustomerExperienceConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qACustomerExperienceConcernTypeID,'ReassuranceStatement','Reassurance statement',5,1)
END

--QADispatchFinish

DECLARE @qADispatchFinishConcernTypeID INT = (SELECT TOP 1 ID FROM ConcernType where Name='QADispatchFinish')

IF NOT EXISTS(SELECT * FROM Concern where Name='DocumentationError' AND ConcernTypeID = @qADispatchFinishConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qADispatchFinishConcernTypeID,'DocumentationError','Documentation error',1,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='ImproperDecisionMaking' AND ConcernTypeID = @qADispatchFinishConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qADispatchFinishConcernTypeID,'ImproperDecisionMaking','Improper decision making',2,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='ISPRateAdherence' AND ConcernTypeID = @qADispatchFinishConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qADispatchFinishConcernTypeID,'ISPRateAdherence','ISP rate adherence',3,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='ISPScripting' AND ConcernTypeID = @qADispatchFinishConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qADispatchFinishConcernTypeID,'ISPScripting','ISP scripting',4,1)
END

--QAMemberScreen

DECLARE @qAMemberScreenConcernTypeID INT = (SELECT TOP 1 ID FROM ConcernType where Name='QAMemberScreen')

IF NOT EXISTS(SELECT * FROM Concern where Name='DidNotAdviseMember' AND ConcernTypeID = @qAMemberScreenConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qAMemberScreenConcernTypeID,'DidNotAdviseMember','Did not advise member',1,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='DidNotUpdateAddress' AND ConcernTypeID = @qAMemberScreenConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qAMemberScreenConcernTypeID,'DidNotUpdateAddress','Did not update address',2,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='DidNotVerifyCallbackNumber' AND ConcernTypeID = @qAMemberScreenConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qAMemberScreenConcernTypeID,'DidNotVerifyCallbackNumber','Did not verify callback number',3,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='ImproperGreetingClosing' AND ConcernTypeID = @qAMemberScreenConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qAMemberScreenConcernTypeID,'ImproperGreetingClosing','Improper greeting/closing',4,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='MemberTransportation' AND ConcernTypeID = @qAMemberScreenConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qAMemberScreenConcernTypeID,'MemberTransportation','Member transportation',5,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='RegisteredRVIncorrectly' AND ConcernTypeID = @qAMemberScreenConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qAMemberScreenConcernTypeID,'RegisteredRVIncorrectly','Registered RV incorrectly',6,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='VerifySafety' AND ConcernTypeID = @qAMemberScreenConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qAMemberScreenConcernTypeID,'VerifySafety','Verify safety',7,1)
END

--QAServiceMapScreen

DECLARE @qAServiceMapScreenConcernTypeID INT = (SELECT TOP 1 ID FROM ConcernType where Name='QAServiceMapScreen')

IF NOT EXISTS(SELECT * FROM Concern where Name='DocumentationError' AND ConcernTypeID = @qAServiceMapScreenConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qAServiceMapScreenConcernTypeID,'DocumentationError','Documentation error',1,1)
END

--QAVehicleScreen

DECLARE @qAVehicleScreenConcernTypeID INT = (SELECT TOP 1 ID FROM ConcernType where Name='QAVehicleScreen')

IF NOT EXISTS(SELECT * FROM Concern where Name='DocumentationError' AND ConcernTypeID = @qAVehicleScreenConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qAVehicleScreenConcernTypeID,'DocumentationError','Documentation error',1,1)
END

IF NOT EXISTS(SELECT * FROM Concern where Name='InformationMissing' AND ConcernTypeID = @qAVehicleScreenConcernTypeID)
BEGIN
INSERT INTO Concern VALUES(@qAVehicleScreenConcernTypeID,'InformationMissing','Information missing',2,1)
END





DECLARE @parentID INT 
DECLARE @coachingConcernRecordID INT 
DECLARE @concernMaintainenceRecordID INT 
DECLARE @concernTypeMaintainenceRecordID INT 
DECLARE @qaDashboardRecordID INT
DECLARE @QA UNIQUEIDENTIFIER
DECLARE @Sysadmin  UNIQUEIDENTIFIER


SET @QA = (select R.RoleId from aspnet_Roles R join
aspnet_Applications  A
ON R.ApplicationId = A.ApplicationId
WHERE A.ApplicationName = 'DMS'
AND R.RoleName ='QA')

SET @Sysadmin = (select R.RoleId from aspnet_Roles R join
aspnet_Applications  A
ON R.ApplicationId = A.ApplicationId
WHERE A.ApplicationName = 'DMS'
AND R.RoleName ='SysAdmin')


IF NOT EXISTS(SELECT * FROM Securable where FriendlyName='MENU_TOP_QA')
BEGIN
INSERT INTO Securable(FriendlyName) VALUES ('MENU_TOP_QA')
END


SET @parentID = (SELECT ID FROM Securable WHERE FriendlyName = 'MENU_TOP_QA')

SET @coachingConcernRecordID = (SELECT ID FROM Securable WHERE FriendlyName = 'MENU_LEFT_QA_COACHING_CONCERN')
SET @concernMaintainenceRecordID = (SELECT ID FROM Securable WHERE FriendlyName = 'MENU_LEFT_QA_CONCERN_MAINTAINENCE')
SET @concernTypeMaintainenceRecordID = (SELECT ID FROM Securable WHERE FriendlyName = 'MENU_LEFT_QA_CONCERN_TYPE_MAINTAINENCE')
SET @qaDashboardRecordID = (SELECT ID FROM Securable WHERE FriendlyName = 'MENU_LEFT_QA_DASHBOARD')

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'MENU_LEFT_QA_COACHING_CONCERN')
BEGIN
	INSERT INTO Securable Values('MENU_LEFT_QA_COACHING_CONCERN',@parentID,NULL)	
	SET @coachingConcernRecordID = SCOPE_IDENTITY()
END


IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @parentID)
BEGIN
	INSERT INTO AccessControlList VALUES(@parentID,@Sysadmin,3)
	INSERT INTO AccessControlList VALUES(@parentID,@QA,3)
END


IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @coachingConcernRecordID)
BEGIN
	INSERT INTO AccessControlList VALUES(@coachingConcernRecordID,@Sysadmin,3)
	INSERT INTO AccessControlList VALUES(@coachingConcernRecordID,@QA,3)
END



IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'MENU_LEFT_QA_CONCERN_MAINTAINENCE')
BEGIN
	INSERT INTO Securable Values('MENU_LEFT_QA_CONCERN_MAINTAINENCE',@parentID,NULL)	
	SET @concernMaintainenceRecordID = SCOPE_IDENTITY()
END

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @concernMaintainenceRecordID)
BEGIN
	INSERT INTO AccessControlList VALUES(@concernMaintainenceRecordID,@Sysadmin,3)
	INSERT INTO AccessControlList VALUES(@concernMaintainenceRecordID,@QA,3)
END


IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'MENU_LEFT_QA_CONCERN_TYPE_MAINTAINENCE')
BEGIN
	INSERT INTO Securable Values('MENU_LEFT_QA_CONCERN_TYPE_MAINTAINENCE',@parentID,NULL)	
	SET @concernTypeMaintainenceRecordID = SCOPE_IDENTITY()
END

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @concernTypeMaintainenceRecordID)
BEGIN
	INSERT INTO AccessControlList VALUES(@concernTypeMaintainenceRecordID,@Sysadmin,3)
	INSERT INTO AccessControlList VALUES(@concernTypeMaintainenceRecordID,@QA,3)
END

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'MENU_LEFT_QA_DASHBOARD')
BEGIN
	INSERT INTO Securable Values('MENU_LEFT_QA_DASHBOARD',@parentID,NULL)	
	SET @qaDashboardRecordID = SCOPE_IDENTITY()
END

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @qaDashboardRecordID)
BEGIN
	INSERT INTO AccessControlList VALUES(@qaDashboardRecordID,@Sysadmin,3)
	INSERT INTO AccessControlList VALUES(@qaDashboardRecordID,@QA,3)
END

GO
