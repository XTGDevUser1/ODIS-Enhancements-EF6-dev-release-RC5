 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Capture_Claim_Number_Details_For_SR_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Capture_Claim_Number_Details_For_SR_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC [dms_Capture_Claim_Number_Details_For_SR_Get] 1467
 CREATE PROCEDURE [dbo].[dms_Capture_Claim_Number_Details_For_SR_Get](
	@serviceRequestId INT = NULL
)
AS 
 BEGIN  
 
 SET FMTONLY OFF
 
CREATE TABLE #FinalResults( 
      [RowNum] [bigint] NOT NULL IDENTITY(1,1),
      ID int  NULL ,
      [Description] nvarchar(100)  NULL ,
      IsCaptureClaimNumber bit  NULL
)     

CREATE TABLE #FinalResults_tmp( 
      [RowNum] [bigint] NOT NULL IDENTITY(1,1),
      ID int  NULL ,
      [Description] nvarchar(100)  NULL ,
      IsCaptureClaimNumber bit  NULL
) 

INSERT INTO #FinalResults
SELECT 
      PP.ID
    , PP.[Description]
    , PP.IsCaptureClaimNumber
FROM 
    ProductProvider PP
    JOIN MemberProduct MP WITH(NOLOCK) ON MP.ProductProviderID = PP.ID
    JOIN [Case] C WITH(NOLOCK) ON 
			(	MP.MemberID = C.MemberID      
				OR
				(MP.MemberID IS NULL AND MP.MembershipID = (SELECT MembershipID FROM Member WHERE ID = C.MemberID))
			) 
			AND 
			(mp.VIN IS NULL OR mp.VIN = C.VehicleVIN)
	JOIN ServiceRequest SR WITH(NOLOCK) ON SR.CaseID = C.ID
WHERE SR.ID = @serviceRequestId

DECLARE @productProviderDescription AS NVARCHAR(100) --= (SELECT TOP 1 [Description] FROM #FinalResults)
DECLARE @isCaptureClaimNumber AS BIT = 0
DECLARE @productProviderID AS INT 

INSERT INTO #FinalResults_tmp
SELECT ID,[Description],IsCaptureClaimNumber FROM #FinalResults 
WHERE IsCaptureClaimNumber = 1

IF((SELECT COUNT(*) FROM #FinalResults_tmp F) >0)
BEGIN
	SET @isCaptureClaimNumber = 1
	
	SET @productProviderDescription = (SELECT TOP 1 [Description] FROM #FinalResults_tmp)
	SET @productProviderID = (SELECT TOP 1 ID FROM #FinalResults_tmp)
END
ELSE
BEGIN
	SET @productProviderDescription = (SELECT TOP 1 [Description] FROM #FinalResults)
	SET @productProviderID = (SELECT TOP 1 ID FROM #FinalResults)
END



SELECT @productProviderID AS ProductProviderID,@productProviderDescription AS ProductProviderDescription, @isCaptureClaimNumber AS IsCaptureClaimNumber

DROP TABLE #FinalResults
DROP TABLE #FinalResults_tmp
 END