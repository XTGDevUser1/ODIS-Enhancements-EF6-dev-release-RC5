IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_MemberManagement_Member_Details_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_MemberManagement_Member_Details_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_MemberManagement_Member_Details_Get] 41
CREATE PROCEDURE [dbo].[dms_MemberManagement_Member_Details_Get](  
@memberID INT
)
AS
BEGIN


DECLARE @now DATETIME, @minDate DATETIME
	
SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
SET @minDate = '1900-01-01' 

	SELECT M.ID AS MemberID  
   , MS.ID AS MembershipID  
   , ISNULL(REPLACE(RTRIM(  
    COALESCE(M.FirstName,'') +  
    COALESCE(' ' + M.MiddleName,'') +  
    COALESCE(' ' + M.LastName,'') +  
    COALESCE(' ' + M.Suffix,'')   
    ), '  ', ' ')  
   ,'') AS [MemberName]    
   , MS.MembershipNumber  
   , CASE	
			WHEN M.IsActive = 0 THEN 'Deleted'
			WHEN ISNULL(M.EffectiveDate,@minDate) <= @now AND ISNULL(M.ExpirationDate,@minDate) >= @now
					THEN 'Active'
					ELSE 'Inactive'
			END AS Status  
   , AE.Line1  
   , AE.Line2  
   , AE.Line3  
   , ISNULL(REPLACE(RTRIM(  
    COALESCE(AE.City, '') +  
    COALESCE(', ' + RTRIM(AE.StateProvince), '') +   
    COALESCE(' ' + AE.PostalCode, '') +  
    COALESCE(' ' + AE.CountryCode, '')    
    ), '  ', ' ')  
    ,'') AS [CityStateZipCountry]  
   , C.Name AS [Client]  
   , P.Name AS [Program]  
   , MS.ClientReferenceNumber  
   , M.MemberSinceDate  
   , M.EffectiveDate  
   , M.ExpirationDate  
   , (SELECT TOP 1 VIN FROM Vehicle WHERE MembershipID = MS.ID ORDER BY ID DESC) AS VIN  
   , SS.Name AS [SourceSystem]  
   , M.CreateDate  
   , M.CreateBy
   , M.ModifyDate
   , M.ModifyBy  
 FROM Member M  
 JOIN Membership MS ON MS.ID = M.MembershipID  
 LEFT JOIN AddressEntity AE ON AE.RecordID = M.ID AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Member')  
 LEFT JOIN SourceSystem SS ON SS.ID = M.SourceSystemID  
 JOIN Program P WITH(NOLOCK) ON P.ID = M.ProgramID  
 JOIN Client C WITH(NOLOCK) ON C.ID = P.ClientID  
 WHERE M.ID = @MemberID  
 --AND  M.IsActive = 1  
END

GO
