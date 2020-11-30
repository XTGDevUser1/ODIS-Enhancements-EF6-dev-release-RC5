IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ServiceRequestAgentTime_TechLeadTime_Update]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_ServiceRequestAgentTime_TechLeadTime_Update]
GO

CREATE PROCEDURE [dbo].[dms_ServiceRequestAgentTime_TechLeadTime_Update] 
AS
BEGIN

	DECLARE @TimeTypeTech int,
		 @TechLeadTimeLimitSeconds int
	SET @TimeTypeTech = (SELECT ID FROM TimeType WHERE NAME = 'Tech')
	SET @TechLeadTimeLimitSeconds = 43200  --(12 hrs in seconds)

	SELECT 
		SRT.ServiceRequestID ServiceRequestID
		,SRT.BeginEventLogID BeginEventLogID
		,SRT.BeginDate BeginDate
		,SRT.UserName BeginUser
		,SRT.EndEventLogID EndEventLogID
		,SRT.EndDate EndDate
		,(SELECT MAX(SRTemp.EndDate) 
			FROM ServiceRequestAgentTime SRTemp WHERE
			SRTemp.ServiceRequestID = SRT.ServiceRequestID 
			AND SRTemp.EndDate is not null 
			AND SRTemp.EndDate <= SRT.BeginDate
			AND SRTemp.TimeTypeID <> @TimeTypeTech) as PriorEventEndDate
	INTO #tmpSRTTech
	FROM ServiceRequestAgentTime SRT
	WHERE SRT.TimeTypeID = @TimeTypeTech
	AND SRT.EndDate is not null
	AND SRT.BeginDate > '1/1/2014'
	AND (SELECT Top 1 TimeTypeID 
			FROM ServiceRequestAgentTime SRTemp WHERE
			SRTemp.ServiceRequestID = SRT.ServiceRequestID 
			AND SRTemp.EndDate is not null 
			AND SRTemp.EndDate <= SRT.BeginDate
			ORDER BY SRTemp.EndDate DESC) <> @TimeTypeTech
	AND NOT EXISTS (
			SELECT *
			FROM ServiceRequestAgentTime_TechLeadTime SRTTech
			WHERE SRTTech.ServiceRequestID = SRT.ServiceRequestID AND
				SRTTech.BeginEventLogID = SRT.BeginEventLogID)
			
	--Select * From #tmpSRTTech
	
	INSERT INTO [DMS].[dbo].[ServiceRequestAgentTime_TechLeadTime]
           ([ServiceRequestID]
           ,[BeginEventLogID]
           ,[TechLeadTimeSeconds])
	Select 
		SRTTech.ServiceRequestID
		,SRTTech.BeginEventLogID
		,CASE WHEN SRTTech.PriorEventEndDate is not null 
					AND (DATEDIFF(ss, ISNULL(SRTTech.PriorEventEndDate,'1/1/1900'), SRTTech.BeginDate)) < @TechLeadTimeLimitSeconds 
				THEN DATEDIFF(ss, SRTTech.PriorEventEndDate, SRTTech.BeginDate) 
				ELSE 0 END
	FROM #tmpSRTTech SRTTech

	Drop table #tmpSRTTech

END
GO

