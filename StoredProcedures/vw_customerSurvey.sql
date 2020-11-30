/****** Object:  View [dbo].[vw_CustomerSurvey]    Script Date: 01/12/2017 03:36:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--DROP VIEW  [dbo].[vw_CustomerSurvey]

ALTER VIEW [dbo].[vw_CustomerSurvey]
AS


/*
SELECT [ID]
      ,[BatchID]
      --,COALESCE(sr.ClientID, po.ClientID) ClientID
      --,COALESCE(sr.ClientName, po.ClientName) ClientName
      --,COALESCE(sr.ProgramID, po.ProgramID) ProgramID
      --,COALESCE(sr.ProgramName, po.ProgramName) ProgramName
      ,cs.ClientID
      ,cs.ClientName
      ,cs.ProgramID
      ,cs.ProgramName
      ,cs.[ServiceRequestID]
      ,cs.[PurchaseOrderNumber]
      ,[SurveyType]
      ,[MemberNumber]
      ,[FirstName]
      ,[LastName]
      ,[EmailAddress]
      ,[HomePhone]
      ,[EmailDomain]
      ,[CCEmailAddress]
      ,[SourceID]
      ,[Prefix]
      ,[MiddleName]
      ,[Nickname]
      ,[Designation]
      ,[Company]
      ,[Title]
      ,[ContactType]
      ,[ConfirmedOptedIn]
      ,[OptedOut]
      ,[LinkedInURL]
      ,[TwitterURL]
      ,[FacebookURL]
      ,[PrimaryAddress]
      ,[WorkAddress1]
      ,[WorkAddress2]
      ,[WorkAddress3]
      ,[Gender]
      ,[WorkCity]
      ,[WorkStateCode]
      ,[WorkState]
      ,[WorkPostalCode]
      ,[WorkCountryCode]
      ,[WorkCountry]
      ,[HomeAddress1]
      ,[HomeAddress2]
      ,[HomeAddress3]
      ,[HomeCity]
      ,[HomeStateCode]
      ,[HomeState]
      ,[HomePostalCode]
      ,[HomeCountryCode]
      ,[HomeCountry]
      ,[PrimaryAddress1]
      ,[PrimaryAddress2]
      ,[PrimaryAddress3]
      ,[PrimaryCity]
      ,[PrimaryStateCode]
      ,[PrimaryState]
      ,[PrimaryPostalCode]
      ,[PrimaryCountryCode]
      ,[WorkPhone]
      ,[HomeFax]
      ,[WorkFax]
      ,[MobilePhone]
      ,[PagerNumber]
      ,[SocialSecurityNumber]
      ,[NationalIdentificationNumber]
      ,[PassportNumber]
      ,[PassportCountry]
      ,[DateofBirth]
      ,cs.[VehicleVIN]
      ,cs.[VehicleYear]
      ,cs.[VehicleModel]
      ,cs.[VehicleMake]
      ,[ServiceCode]
      ,[ServiceCodeDescription]
      ,[IsTechFlag]
      ,DispatchDatetime
      ,ReferenceNumber
	  ,ContactDateTime
      ,[ETA]
      ,[RepairDealerID]
      ,[Agent]
      ,[CallBackNumber]
      ,[AltCallBackNumber]
      ,[InvitedBy]
      ,[ResponseMethod]
      ,convert(datetime,[InvitedDate]) as [InvitedDate]
      ,convert(datetime,[StartedOn]) as [StartedOn]
      ,convert(datetime,[CompletedOn]) as [CompletedOn]
      ,[LastModifiedBy]
      ,[LastModifieidOn]
      ,[ReferenceID]
      ,[TargetedList]
      ,cs.[Language]
      ,[RespondentIP]
      ,[OnsiteServiceProvider]
      ,[VendorStateProvince]
      ,[PhoneProfessionalismGrade]
      ,[PhoneListeningGrade]
      ,[PhoneKnowledgeGrade]
      ,[TechProfessionalismGrade]
      ,[TechKnowledgeGrade]
      ,[TechWaitGrade]
      ,[ISPProfessionalismGrade]
      ,[ISPMeetNeedsGrade]
      ,[ISPTimelinessArrivalGrade]
      ,[ISPAssistTime]
      ,[HowLikelyToRecommend]
      ,[AdditionalComments]
      ,[PublishingApproval]
	  ,[DecidedBy] 
	  ,[DecidedDate]
	  ,[CustomerFeedbackID]
	  ,[IsIgnore]
  --FROM dart.Pinnacle_Reporting.dbo.vw_CustomerSurvey  cs
  FROM SurveyResponse CS
  --[dbo].[CustomerSurveySample] cs
  --LEFT OUTER JOIN dbo.vw_ServiceRequests sr on sr.ServiceRequestID = cs.ServiceRequestID
  --LEFT OUTER JOIN dbo.vw_PurchaseOrders po on po.PurchaseOrderNumber = cs.PurchaseOrderNumber    
  WHERE cs.CompletedOn IS NOT NULL 
  AND cs.CompletedOn > '11/1/2016'
  --AND cs.DecidedDate IS NULL
  AND cs.AdditionalComments IS NOT NULL
  */

  -- SurveyMonkey integration - Getting only those columns that are required for the grid in ODIS
  SELECT	CS.ID,
			CS.CustomerFeedbackID,
			CS.AdditionalComments,
			NULL AS DispatchDateTime,
			CS.IsIgnore,
			NULL AS SurveyType,
			SR.ID As ServiceRequestID,
			PO.PurchaseOrderNumber AS PurchaseOrderNumber,
			C.ContactFirstName AS FirstName,
			C.ContactLastName AS LastName,
			NULL AS ContactDateTime
  FROM		SurveyResponse CS
  JOIN		EventLog EL ON CS.ELogID = EL.ID
  JOIN		EventLogLink ELLForSR ON ELLForSR.EventLogID = EL.ID AND ELLForSR.EntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
  JOIN		EventLogLink ELLForPO ON ELLForPO.EventLogID = EL.ID AND ELLForPO.EntityID = (SELECT ID FROM Entity WHERE Name = 'PurchaseOrder')
  JOIN		ServiceRequest SR ON SR.ID = ELLForSR.RecordID
  JOIN		PurchaseOrder PO ON PO.ID = ELLForPO.RecordID
  JOIN		[Case] C ON SR.CaseID = C.ID
  WHERE		CS.AdditionalComments is not null
GO
