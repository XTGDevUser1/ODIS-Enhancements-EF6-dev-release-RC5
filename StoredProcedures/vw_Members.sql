IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_Members]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP VIEW [dbo].[vw_Members] 
 END 
 GO  
CREATE VIEW [dbo].[vw_Members]
AS

SELECT m.[ID] MemberID
      ,m.[MemberNumber]
      ,m.[ClientMemberKey]
      ,m.[MembershipID]
      ,ms.MembershipNumber
      ,ms.AltMembershipNumber
      ,ms.ClientMembershipKey
      ,ms.ClientReferenceNumber
      ,p.ClientID
      ,cl.Name Client
      ,m.[ProgramID]
      ,p.Name Program
      ,m.[Prefix]
      ,m.[FirstName]
      ,m.[MiddleName]
      ,m.[LastName]
      ,m.[Suffix]
      ,m.[Email]
      ,m.[EffectiveDate]
      ,m.[ExpirationDate]
      ,m.[MemberSinceDate]
      ,m.[IsPrimary]
      ,m.[IsActive]
      ,m.[CreateBatchID]
      ,m.[CreateDate]
      ,m.[CreateBy]
      ,m.[ModifyBatchID]
      ,m.[ModifyDate]
      ,m.[ModifyBy]
      ,m.[SourceSystemID]
      ,ss.Name SourceSystem
      ,m.[ReferenceProgram]
      ,m.[ClaimSubmissionNumber]
      ,m.[AccountSource]
      ,m.[ClientMemberType]
      ,m.[SellerVendorID]
      ,m.[ClientReference1]

FROM Member m (NOLOCK)
JOIN Membership ms (NOLOCK) on ms.ID = m.MembershipID
JOIN Program p (NOLOCK) on p.ID = m.ProgramID
JOIN Client cl (NOLOCK) on cl.ID = p.ClientID
JOIN SourceSystem ss (NOLOCK) on ss.ID = m.SourceSystemID
GO

