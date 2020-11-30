IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_ServiceRequestAgentTimeBilledSummary]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_ServiceRequestAgentTimeBilledSummary] 
 END 
 GO  
CREATE VIEW [dbo].[vw_ServiceRequestAgentTimeBilledSummary]
AS
SELECT CL.ID ClientID
	  ,CL.Name Client
	  ,P.ID ProgramID
	  ,P.Name as Program
      ,AT.ServiceRequestID
      ,MIN(AT.[BeginDate]) FirstAccessDate
      ,MAX(AT.[BeginDate]) LastAccessDate
      ,ROUND(SUM(CASE WHEN T.Name = 'FrontEnd' THEN ISNULL(AT.[EventSeconds],0) ELSE 0 END) / 60.0, 2) FrontEndMinutes 
      ,ROUND(SUM(CASE WHEN T.Name = 'BackEnd' THEN ISNULL(AT.[EventSeconds],0) ELSE 0 END) / 60.0, 2) BackEndMinutes 
      ,ROUND(SUM(CASE WHEN T.Name = 'Tech' THEN ISNULL(AT.[EventSeconds],0) ELSE 0 END) / 60.0, 2) TechMinutes 
      ,SUM(CASE WHEN T.Name = 'FrontEnd' THEN ISNULL(AT.[EventSeconds],0) ELSE 0 END) FrontEndSeconds 
      ,SUM(CASE WHEN T.Name = 'BackEnd' THEN ISNULL(AT.[EventSeconds],0) ELSE 0 END) BackEndSeconds 
      ,SUM(CASE WHEN T.Name = 'Tech' THEN ISNULL(AT.[EventSeconds],0) ELSE 0 END) TechSeconds 
      ,SUM(CASE WHEN ISNULL(AT.IsInboundCall,0) = 1 THEN 1 ELSE 0 END) InBoundCallCount
      ,SUM(ISNULL(AT.IssuedPOCount,0)) IssuedPOCount
      ,SUM(ISNULL(AT.DispatchISPCallCount,0)) DispatchISPCallCount
      ,SUM(ISNULL(AT.ServiceFacilityCallCount,0)) ServiceFacilityCallCount
FROM [ServiceRequestAgentTime] AT (NOLOCK)
LEFT JOIN [TimeType] T (NOLOCK) ON AT.TimeTypeID = T.ID
LEFT JOIN [Program] P (NOLOCK) ON AT.ProgramID = P.ID
LEFT JOIN [Client] CL (NOLOCK) ON P.ClientID = CL.ID
WHERE AT.AccountingInvoiceBatchID IS NOT NULL
GROUP BY
	CL.ID 
	,CL.Name 
	,P.ID 
	,P.Name
    ,AT.ServiceRequestID
GO

