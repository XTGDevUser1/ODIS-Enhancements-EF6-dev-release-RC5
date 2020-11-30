IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_EventDetailForFinish_Get]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_EventDetailForFinish_Get]
	GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SELECT * FROM dbo.fn_EventDetailForFinish_Get(2,2)
CREATE function fn_EventDetailForFinish_Get(@eventDetail NVARCHAR(MAX), @eventName NVARCHAR(100)) RETURNS NVARCHAR(MAX)
AS
BEGIN
	--DECLARE @eventDetail XML = '<EventDetail><ServiceRequestID>400316</ServiceRequestID><ContactCategory>2</ContactCategory><ServiceRequestStatus>Complete</ServiceRequestStatus><NextAction>ManualClosedLoop</NextAction><ScheduledDate>2015-08-29</ScheduledDate><AssignedTo>1</AssignedTo><Priority>High</Priority><ClosedLoopStatus></ClosedLoopStatus><NextSend></NextSend><Comments>Comments by Phani for testing</Comments><CreateBy>afreestone</CreateBy><ModifyBy>sysadmin</ModifyBy></EventDetail>',

	DECLARE @eventDetailXML xml
	DECLARE	@result NVARCHAR(MAX) = NULL


	SELECT @eventDetailXML = 
	
	CASE WHEN CHARINDEX('</Comments>',@eventDetail) - CHARINDEX('<Comments>', @eventDetail)  - Len('</Comments>') <= 0
		THEN @eventDetail
		ELSE
	SUBSTRING(@eventDetail,0,CHARINDEX('<Comments>',@eventDetail) + LEN('<Comments>'))
								+
							[dbo].[fnXMLEncode](SUBSTRING(@eventDetail, CHARINDEX('<Comments>', @eventDetail) + 10
														, CHARINDEX('</Comments>',@eventDetail) - CHARINDEX('<Comments>', @eventDetail) - Len('</Comments>')))
								+
							SUBSTRING(@eventDetail,CHARINDEX('</Comments>',@eventDetail), LEN(@eventDetail) - CHARINDEX('</Comments>',@eventDetail)+1)
		END
	IF @eventName = 'SaveFinishTab'
	BEGIN
		DECLARE @nextAction NVARCHAR(255),
				@scheduledDate NVARCHAR(255),
				@assignedTo INT = NULL
				
		SET @nextAction = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/NextAction') T(c))
		SET @scheduledDate = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/ScheduledDate') T(c))
		SET @assignedTo = (SELECT  T.c.value('.','INT') FROM @eventDetailXML.nodes('/EventDetail/AssignedTo') T(c))
		SET @result = ISNULL(@nextAction,'') + '<br>'
		SET @result = @result + ISNULL(@scheduledDate,'') + '<br>'
		SET @result = @result + (SELECT Case WHEN ISNULL(@assignedTo,0) = 0 
																THEN '' 
																ELSE (SELECT U.FirstName + ' ' + U.LastName
																		FROM [User] U WITH (NOLOCK)
																		WHERE U.Id = @assignedTo)
																END) + '<br>' 	
	END
	ELSE IF @eventName = 'NextActionSet'
	BEGIN
		DECLARE @nextActionAssignedToUserNextActionSet NVARCHAR(510),
				@scheduledDateNextActionSet NVARCHAR(255),
				@serviceRequestIDNextActionSet NVARCHAR(100),
				@nextActionNextActionSet NVARCHAR(100)
				
		SET @nextActionAssignedToUserNextActionSet = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/NextActionAssignedToUser') T(c))
		SET @scheduledDateNextActionSet = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/ScheduledDate') T(c))
		--SET @serviceRequestIDNextActionSet = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/ServiceRequestID') T(c))
		SET @nextActionNextActionSet = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/NextAction') T(c))
		
		SET @result = ISNULL(@nextActionNextActionSet,'') + '<br>'
		--SET @result = @result + ISNULL(@serviceRequestIDNextActionSet,'') + '<br>'
		IF(@scheduledDateNextActionSet IS NOT NULL)
		BEGIN
			SET @result = @result + ISNULL(@scheduledDateNextActionSet,'') + '<br>'
		END
		SET @result = @result + ISNULL(@nextActionAssignedToUserNextActionSet,'')+'<br>'
		
	END
	ELSE IF @eventName = 'NextActionCleared'
	BEGIN
		DECLARE @serviceRequestIDNextActionCleared NVARCHAR(100),
				@nextActionCleared NVARCHAR(100)

		--SET @serviceRequestIDNextActionCleared = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/ServiceRequestID') T(c))
		SET @nextActionCleared = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/ClearedNextAction') T(c))
		
		SET @result = ISNULL(@nextActionCleared,'') + '<br>'
		--SET @result = @result + ISNULL(@serviceRequestIDNextActionCleared,'') + '<br>'
	END
	ELSE IF @eventName = 'NextActionStarted'
	BEGIN
		DECLARE @serviceRequestIDNextActionStarted NVARCHAR(100),
				@nextActionClearedStarted NVARCHAR(100),
				@nextactionstartedAt  NVARCHAR(100),
				@nextActionClearedAt NVARCHAR(100)

		SET @serviceRequestIDNextActionStarted = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/ServiceRequestID') T(c))
		SET @nextActionClearedStarted = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/ClearedNextAction') T(c))
		SET @nextactionstartedAt  = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/NextActionStarted') T(c))
		
		
		SET @result = 'Next Action : ' + ISNULL(@nextActionClearedStarted,'') + '<br>'
		SET @result = @result + 'Started At : ' + ISNULL(@nextactionstartedAt,'') + '<br>'
		SET @result = @result + 'Service Request ID : '+ ISNULL(@serviceRequestIDNextActionStarted,'') + '<br>'
	END
	ELSE IF @eventName = 'CaptureEstimate'
	BEGIN
		DECLARE @estimate NVARCHAR(100),
				@decision NVARCHAR(100),
				@reason NVARCHAR(100)

		SET @estimate = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/Estimate') T(c))
		SET @decision = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/Decision') T(c))
		SET @reason   = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/DeclineReason') T(c))

		SET @result =  'Estimate : ' + ISNULL(@estimate,'') + '<br>'
		SET @result =  @result + ' Decision : ' + ISNULL(@decision,'') + '<br>'
		
		IF LEN(ISNULL(@reason,'')) > 0   
		BEGIN			
			SET @result =  @result + ' DeclineReason : ' + ISNULL(@reason,'') + '<br>'
		END

	END

	ELSE IF @eventName = 'POThresholdApproved'
	BEGIN
		DECLARE @poOverThresholdManagerResponse NVARCHAR(100),
				@poOverThresholdManager NVARCHAR(100),
				@poOverThresholdComments NVARCHAR(100),
				@poOverThresholdServiceTotal NVARCHAR(100),
				@poOverThresholdServiceMax NVARCHAR(100)

		SET @poOverThresholdManagerResponse = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/POOverThresholdManagerResponse') T(c))
		SET @poOverThresholdManager = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/PoOverThresholdManager') T(c))
		SET @poOverThresholdComments   = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/PoOverThresholdManagerComments') T(c))

		SET @poOverThresholdServiceTotal   = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/POOverThresholdServiceTotal') T(c))
		SET @poOverThresholdServiceMax   = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/PoOverThresholdServiceMax') T(c))


		SET @result =  ISNULL(@poOverThresholdManagerResponse,'') + '<br>'
		SET @result =  @result + ISNULL(@poOverThresholdManager,'') + '<br>'
		SET @result =  @result + 'Service Total: '+ ISNULL(@poOverThresholdServiceTotal,'') + '<br>'
		SET @result =  @result + 'Service Max: ' + ISNULL(@poOverThresholdServiceMax,'') + '<br>'
		SET @result =  @result + ISNULL(@poOverThresholdComments,'') 
	END
	ELSE IF @eventName IN ('UpdateCustomerFeedback','CloseCustomerFeedback')
	BEGIN
		DECLARE @oldStatusUpdateCustomerFeedback NVARCHAR(100),
				@newStatusUpdateCustomerFeedback NVARCHAR(100)

		SET @oldStatusUpdateCustomerFeedback = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/OldStatus') T(c))
		SET @newStatusUpdateCustomerFeedback = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventDetailXML.nodes('/EventDetail/NewStatus') T(c))

		SET @result = ''
		IF(len(@oldStatusUpdateCustomerFeedback)>0)
		BEGIN
			SET @result = @result + 'Old Status: ' + ISNULL(@oldStatusUpdateCustomerFeedback,'') + '<br>'
		END
		IF(len(@newStatusUpdateCustomerFeedback)>0)
		BEGIN
			SET @result =  @result + 'New Status: ' + ISNULL(@newStatusUpdateCustomerFeedback,'') + '<br>'		
		END
	END
	RETURN @result

END


/*

<EventDetail>
	<POOverThresholdManagerResponse>Approved</POOverThresholdManagerResponse>
	<PoOverThresholdManager>demoagent</PoOverThresholdManager>
	<PoOverThresholdManagerComments>Approved to test</PoOverThresholdManagerComments>
</EventDetail>

*/