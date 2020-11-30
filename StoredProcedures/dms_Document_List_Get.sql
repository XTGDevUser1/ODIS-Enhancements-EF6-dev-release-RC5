IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Document_List_Get]')	AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Document_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
 --EXEC [dms_Document_List_Get] '',1,50,50,'Category','ASC','Vendor',5744,'VendorPortal'
 --EXEC [dms_Document_List_Get] '',1,50,50,'Category','ASC','Vendor',382,''
 CREATE PROCEDURE [dbo].[dms_Document_List_Get](    
   @whereClauseXML NVARCHAR(4000) = NULL     
  ,@startInd Int = 1     
  ,@endInd BIGINT = 5000     
  ,@pageSize int = 10      
  ,@sortColumn nvarchar(100)  = ''     
  ,@sortOrder nvarchar(100) = 'ASC'     
  ,@entityName nvarchar(50)
  ,@recordId int 
  ,@sourceSystem NVARCHAR(100) = NULL   
 )     
 AS     
 BEGIN     
SET NOCOUNT ON      
SET FMTONLY OFF    
   

CREATE TABLE #FinalResults     
(    
 [RowNum] [bigint] NOT NULL IDENTITY(1,1), 
 Category NVARCHAR(50) NULL,
 DocumentName NVARCHAR(255) NULL,
 Comment NVARCHAR(255) NULL,
 AddedBy NVARCHAR(50) NULL,
 DateAdded DATETIME NULL,
 DocumentId INT NULL,
 IsShownOnVendorPortal BIT NULL,
 IsShownOnClientPortal BIT NULL
)    

INSERT INTO #FinalResults
SELECT 
	DC.Name AS Category,
	D.Name AS DocumentName,
	D.Comment,
	D.CreateBy AS AddedBy,
	D.CreateDate AS DateAdded,
	D.ID AS DocumentId,
	D.IsShownOnVendorPortal,
	D.IsShownOnClientPortal
FROM [Document] (NOLOCK) D
INNER JOIN [DocumentCategory] DC ON D.DocumentCategoryID  = DC.ID
WHERE D.EntityID = (SELECT TOP 1 ID FROM Entity WHERE Name = @entityName) AND D.RecordID = @recordId AND D.IsActive = 1
	AND(
		(@sourceSystem IS NULL) 
		OR (@entityName = 'Vendor' AND D.IsShownOnVendorPortal=1) 
		OR (@sourceSystem = 'VendorPortal' AND @entityName = 'Vendor' 
			AND D.CreateBy IN (SELECT U.UserName
				FROM VendorUser VU
				JOIN aspnet_Users U ON U.UserID = VU.aspnet_UserID
				WHERE VU.VendorID = @recordId
			) AND D.IsShownOnVendorPortal=1 AND D.ISActive = 1
		)
		OR (@entityName = 'Client' AND D.IsShownOnClientPortal=1) 
		OR (@sourceSystem = 'ClientPortal' AND @entityName = 'Client' 
			AND D.CreateBy IN (SELECT U.UserName
				FROM ClientUser CU
				JOIN aspnet_Users U ON U.UserID = CU.aspnet_UserID
				WHERE CU.ClientID = @recordId
			) AND D.IsShownOnClientPortal=1 AND D.ISActive = 1
		)
	)


DECLARE @count INT       
SET @count = 0       
SELECT @count = MAX(RowNum) FROM #FinalResults    
SET @endInd = @startInd + @pageSize - 1    
IF @startInd  > @count       
BEGIN   
 DECLARE @numOfPages INT        
 SET @numOfPages = @count / @pageSize       
 IF @count % @pageSize > 1       
 BEGIN       
  SET @numOfPages = @numOfPages + 1       
 END       
 SET @startInd = ((@numOfPages - 1) * @pageSize) + 1       
 SET @endInd = @numOfPages * @pageSize       
END
    
SELECT	@count AS TotalRows,
		Category,
		DocumentName,
		Comment,
		AddedBy,
		DateAdded,
		DocumentId,
		IsShownOnVendorPortal,
		IsShownOnClientPortal
FROM #FinalResults WHERE RowNum BETWEEN @startInd AND @endInd    
ORDER BY 
	 CASE WHEN @sortColumn = 'Category' AND @sortOrder = 'ASC'
	 THEN Category END ASC, 
	 CASE WHEN @sortColumn = 'Category' AND @sortOrder = 'DESC'
	 THEN Category END DESC ,
	 
	 CASE WHEN @sortColumn = 'DocumentName' AND @sortOrder = 'ASC'
	 THEN DocumentName END ASC, 
	 CASE WHEN @sortColumn = 'DocumentName' AND @sortOrder = 'DESC'
	 THEN DocumentName END DESC ,
	 
	 CASE WHEN @sortColumn = 'Comment' AND @sortOrder = 'ASC'
	 THEN Comment END ASC, 
	 CASE WHEN @sortColumn = 'Comment' AND @sortOrder = 'DESC'
	 THEN Comment END DESC ,
	 
	 CASE WHEN @sortColumn = 'DateAdded' AND @sortOrder = 'ASC'
	 THEN DateAdded END ASC, 
	 CASE WHEN @sortColumn = 'DateAdded' AND @sortOrder = 'DESC'
	 THEN DateAdded END DESC ,
	 
	 CASE WHEN @sortColumn = 'IsShownOnVendorPortal' AND @sortOrder = 'ASC'
	 THEN IsShownOnVendorPortal END ASC, 
	 CASE WHEN @sortColumn = 'IsShownOnVendorPortal' AND @sortOrder = 'DESC'
	 THEN IsShownOnVendorPortal END DESC ,
	 
	 CASE WHEN @sortColumn = 'IsShownOnClientPortal' AND @sortOrder = 'ASC'
	 THEN DateAdded END ASC, 
	 CASE WHEN @sortColumn = 'IsShownOnClientPortal' AND @sortOrder = 'DESC'
	 THEN DateAdded END DESC 

DROP TABLE #FinalResults 	 
END