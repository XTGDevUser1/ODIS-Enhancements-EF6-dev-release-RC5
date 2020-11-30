IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_DispatchCommissionClient]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_DispatchCommissionClient] 
 END 
 GO  
CREATE VIEW [dbo].[vw_DispatchCommissionClient]
AS
SELECT ID ClientID, Name ClientName
FROM Client
WHERE Name IN (
	'BRS'
)
GO

