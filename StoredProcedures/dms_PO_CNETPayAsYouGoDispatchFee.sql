/****** Object:  StoredProcedure [dbo].[dms_PO_CNETPayAsYouGoDispatchFee]    Script Date: 05/21/2016 18:28:52 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_PO_CNETPayAsYouGoDispatchFee]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_PO_CNETPayAsYouGoDispatchFee]
GO

/****** Object:  StoredProcedure [dbo].[dms_PO_CNETPayAsYouGoDispatchFee]    Script Date: 05/21/2016 18:28:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 CREATE PROCEDURE [dbo].[dms_PO_CNETPayAsYouGoDispatchFee]
	@POID int,
	@PurchaseOrderAmount money
AS

BEGIN

--Declare @PoID int = 537537

Declare @TechMinuteRate money
	,@AgentMinuteRate money
	,@MarkupRate money 
	,@NonMemberMarkupRate money

Set @MarkupRate = 1.3
Set @NonMemberMarkupRate = 1.15

Declare @DispatchFee money
	,@StartDateTime datetime
	,@DispatchFeeAgentMinutes int
	,@DispatchFeeTechMinutes int
	,@DispatchFeeTimeCost money

---- Get Tech minute rate from invoice definition
Select @TechMinuteRate = Invoice.Rate
From (
	Select Top 1 Rate  
	From BillingDefinitionInvoice bdi
	Join Client cl on cl.ID = bdi.ClientID
	Join BillingDefinitionInvoiceLine bdil on bdil.BillingDefinitionInvoiceID = bdi.ID and bdil.IsActive = 1
	Join Product p on p.ID = bdil.ProductID 
	Where cl.Name = 'Coach-net'
	And p.Name = 'Tech Billable Time Internal'
	) Invoice

---- Get Agent minute rate from invoice definition
Select @AgentMinuteRate = Invoice.Rate
From (
	Select Top 1 Rate  
	From BillingDefinitionInvoice bdi
	Join Client cl on cl.ID = bdi.ClientID
	Join BillingDefinitionInvoiceLine bdil on bdil.BillingDefinitionInvoiceID = bdi.ID and bdil.IsActive = 1
	Join Product p on p.ID = bdil.ProductID 
	Where cl.Name = 'Coach-net'
	And p.Name = 'Agent Billable Time Internal'
	) Invoice

---- If Member Added/Registered OR Member Expired then use Non-Member Markup Rate
Select @NonMemberMarkupRate = Case When ss.Name = 'Dispatch' OR m.ExpirationDate < c.CreateDate Then @NonMemberMarkupRate Else 1.0 End 
From PurchaseOrder po
Join ServiceRequest sr on sr.ID = po.ServiceRequestID
Join [Case] c on c.ID = sr.CaseID
Join Member m on m.ID = c.MemberID
Join SourceSystem ss on ss.ID = m.SourceSystemID
Where po.ID = @poid

---- No Dispatch Fee for GOAs
If Exists (Select * From PurchaseOrder Where ID = @poid And IsGOA = 1)
	Set @DispatchFee = 0.0
	
---- Determine Dispatch Fee based on Agent and Tech time spent on the SR
Else
	Begin
	
	Select @StartDateTime = MAX(po.CreateDate)
	From ServiceRequest sr 
	Join PurchaseOrder po on sr.ID = po.ServiceRequestID And po.IsActive = 1 
	Join PurchaseOrderStatus pos on pos.ID = po.PurchaseOrderStatusID and pos.Name = 'Issued'
	Where sr.ID = (Select ServiceRequestID From PurchaseOrder Where ID = @poid)
	And po.ID <> @poid

	Select 
		@DispatchFeeTechMinutes = ROUND(SUM(CASE WHEN tt.Name = 'Tech' THEN srt.EventSeconds ELSE 0 END) / 60.0, 0)
		,@DispatchFeeAgentMinutes = ROUND(SUM(CASE WHEN tt.Name IN ('FrontEnd', 'BackEnd') THEN srt.EventSeconds ELSE 0 END) / 60.0, 0)
		,@DispatchFeeTimeCost = (ROUND(SUM(CASE WHEN tt.Name = 'Tech' THEN srt.EventSeconds ELSE 0 END) / 60.0, 0) * @TechMinuteRate)
							  + (ROUND(SUM(CASE WHEN tt.Name IN ('FrontEnd', 'BackEnd') THEN srt.EventSeconds ELSE 0 END) / 60.0, 0) * @AgentMinuteRate)
		,@DispatchFee = ROUND(ROUND(SUM(CASE WHEN tt.Name = 'Tech' THEN srt.EventSeconds ELSE 0 END) / 60.0, 0) * @TechMinuteRate * @MarkupRate * @NonMemberMarkupRate, 2)
					  + ROUND(ROUND(SUM(CASE WHEN tt.Name IN ('FrontEnd', 'BackEnd') THEN srt.EventSeconds ELSE 0 END) / 60.0, 0) * @AgentMinuteRate * @MarkupRate * @NonMemberMarkupRate, 2)
	From PurchaseOrder po
	Join PurchaseOrderStatus pos on pos.ID = po.PurchaseOrderStatusID
	Join ServiceRequestAgentTime srt on srt.ServiceRequestID = po.ServiceRequestID
	Join TimeType tt on tt.ID = srt.TimeTypeID
	Where po.ID = @poid
	and (ISNULL(@PurchaseOrderAmount,0) = 0 OR po.PurchaseOrderAmount <> @PurchaseOrderAmount)
	and pos.Name = 'Pending'
	and po.IsActive = 1
	and (@StartDateTime IS NULL OR srt.BeginDate >= @StartDateTime)
	Group By srt.ServiceRequestID

	IF @DispatchFee IS NULL
	Select 
		@DispatchFeeTechMinutes = DispatchFeeTechMinutes
		,@DispatchFeeAgentMinutes = DispatchFeeAgentMinutes
		,@DispatchFeeTimeCost = DispatchFeeTimeCost
		,@DispatchFee = DispatchFee
	From PurchaseOrder
	Where ID = @POID

	End
	
	SELECT 0.00 AS InternalDispatchFee
		,ISNULL(@DispatchFee,0) AS ClientDispatchFee
		,0.00 AS CreditCardProcessingFee
		,ISNULL(@DispatchFee,0) AS DispatchFee
		,CONVERT(nvarchar(50), ISNULL(@DispatchFee,0)) AS StringDispatchFee
		,ISNULL(@DispatchFeeAgentMinutes,0) AS DispatchFeeAgentMinutes
		,ISNULL(@DispatchFeeTechMinutes,0) AS DispatchFeeTechMinutes
		,ISNULL(@DispatchFeeTimeCost,0) AS DispatchFeeTimeCost

END

GO


