IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[etl_Update_MemberIsActive]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[etl_Update_MemberIsActive]
GO

CREATE PROCEDURE [dbo].[etl_Update_MemberIsActive] 
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE dbo.Member
	SET IsActive = 1
	WHERE EffectiveDate <= GETDATE()
	AND (ExpirationDate IS NULL OR ExpirationDate >= GETDATE())

	UPDATE dbo.Member
	SET IsActive = 0
	WHERE EffectiveDate > GETDATE()
	OR (ExpirationDate IS NOT NULL AND ExpirationDate < GETDATE())

END
GO

