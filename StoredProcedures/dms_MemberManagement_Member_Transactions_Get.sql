IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_MemberManagement_Member_Transactions_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_MemberManagement_Member_Transactions_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_MemberManagement_Member_Transactions_Get] 'Status','DESC',811
CREATE PROCEDURE [dbo].[dms_MemberManagement_Member_Transactions_Get](
   @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC'
  ,@memberID int
)
AS  
BEGIN

CREATE TABLE #FinalResults( 
	[Type] nvarchar(100)  NULL ,
	[Number] int  NULL ,
	[Date] datetime  NULL ,
	[Status] nvarchar(250)  NULL 
) 

INSERT INTO #FinalResults
SELECT	'InboundCall' AS Type
		, IC.ID AS Number
		, IC.CreateDate AS Date
		, '' AS Status
FROM	InboundCall IC
WHERE	IC.MemberID = @memberID

UNION

SELECT	'EmergencyAssistance'
		, EA.ID 
		, EA.CreateDate
		, '' AS Status
FROM	[Case] C
JOIN	EmergencyAssistance EA ON EA.CaseID = C.ID
WHERE	C.MemberID = @memberID

UNION

SELECT	'ServiceRequest'
		, SR.ID
		, SR.CreateDate
		, SRS.Name AS Status
FROM	ServiceRequest SR
JOIN	ServiceRequestStatus SRS ON SRS.ID = SR.ServiceRequestStatusID
JOIN	[CASE] C ON C.ID = SR.CaseID
WHERE	C.MemberID = @memberID

UNION

SELECT	'Vehicle'
		, V.ID
		, V.CreateDate
		, '' 
FROM	Vehicle V
WHERE	V.MemberID = @memberID

SELECT * FROM #FinalResults
ORDER BY 
	 CASE WHEN @sortColumn = 'Type' AND @sortOrder = 'ASC'
	 THEN Type END ASC, 
	 CASE WHEN @sortColumn = 'Type' AND @sortOrder = 'DESC'
	 THEN Type END DESC ,

	 CASE WHEN @sortColumn = 'Number' AND @sortOrder = 'ASC'
	 THEN Number END ASC, 
	 CASE WHEN @sortColumn = 'Number' AND @sortOrder = 'DESC'
	 THEN Number END DESC ,

	 CASE WHEN @sortColumn = 'Date' AND @sortOrder = 'ASC'
	 THEN Date END ASC, 
	 CASE WHEN @sortColumn = 'Date' AND @sortOrder = 'DESC'
	 THEN Date END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN Status END DESC
	 
DROP TABLE #FinalResults
END

GO
