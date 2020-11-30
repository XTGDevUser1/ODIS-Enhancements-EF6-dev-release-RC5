IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_Batches]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_Batches] 
 END 
 GO 
CREATE VIEW [dbo].[vw_Batches]
AS
SELECT b.[ID] BatchID
      ,b.[BatchTypeID]
      ,bt.Name BatchType
      ,b.[BatchStatusID]
      ,bs.Name BatchStatus
      ,b.[Direction]
      ,b.[Description]
      ,b.[TotalCount]
      ,b.[TotalAmount]
      ,b.[MasterETLLoadID]
      ,b.[TransactionETLLoadID]
      ,b.[CreateDate]
      ,b.[CreateBy]
      ,b.[ModifyDate]
      ,b.[ModifyBy]
FROM [dbo].[Batch] b (nolock)
JOIN BatchType bt (nolock) on bt.ID = b.BatchTypeID
JOIN BatchStatus bs (nolock) on bs.ID = b.BatchStatusID
GO

