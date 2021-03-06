IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_billing_invoices_tag]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_billing_invoices_tag] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_billing_invoices_tag] @invoicesXML = '<Invoices><ID>41</ID></Invoices>',@billedBatchID = 999,@unBilledBatchID=1, @currentUser='kbanda',@eventSource='',@eventDetails=''
 CREATE PROCEDURE [dbo].[dms_billing_invoices_tag](
	@invoicesXML XML,
	@billedBatchID BIGINT,
	@unBilledBatchID BIGINT,
	@currentUser NVARCHAR(50),
	@eventSource NVARCHAR(MAX),
	@eventName NVARCHAR(100) = 'PostInvoice',
	@eventDetails NVARCHAR(MAX),
	@entityName NVARCHAR(50) = 'BillingInvoice',
	@sessionID NVARCHAR(MAX) = NULL	
 )
 AS
 BEGIN
 
	DECLARE @now DATETIME = GETDATE()
	
	DECLARE @tblBillingInvoices TABLE
	(	
		ID INT IDENTITY(1,1),
		RecordID INT
	)
	
	INSERT INTO @tblBillingInvoices
	SELECT BI.ID
	FROM	BillingInvoice BI
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @invoicesXML.nodes('/Invoices/ID') T(c)
			) T ON BI.ID = T.ID
			
	DECLARE	@BillingInvoiceDetailStatus_POSTED as int,
			@BillingInvoiceLineStatus_POSTED as int,
			@BillingInvoiceStatus_POSTED as int,
			@BillingInvoiceDisposition_LOCKED as int,
			@BillingInvoiceDetailStatus_DELETED as int,
			
			@serviceRequestEntityID INT,
			@purchaseOrderEntityID INT,
			@claimEntityID INT,
			@vendorInvoiceEntityID INT,
			@billingInvoiceEntityID INT,
			@postInvoiceEventID INT	
	
	SELECT @BillingInvoiceDetailStatus_POSTED = (SELECT ID from BillingInvoiceDetailStatus where Name = 'POSTED')
	SELECT @BillingInvoiceLineStatus_POSTED = (SELECT ID from BillingInvoiceLineStatus where Name = 'POSTED')
	SELECT @BillingInvoiceStatus_POSTED = (SELECT ID from BillingInvoiceStatus where Name = 'POSTED')
	SELECT @BillingInvoiceDisposition_LOCKED = (SELECT ID from BillingInvoiceDetailDisposition where Name = 'LOCKED')
	SELECT @BillingInvoiceDetailStatus_DELETED = (SELECT ID from BillingInvoiceDetailStatus where Name = 'DELETED')
 
 
	SELECT @serviceRequestEntityID = ID FROM Entity WHERE Name = 'ServiceRequest'
	SELECT @purchaseOrderEntityID = ID FROM Entity WHERE Name = 'PurchaseOrder'
	SELECT @claimEntityID = ID FROM Entity WHERE Name = 'Claim'
	SELECT @vendorInvoiceEntityID = ID FROM Entity WHERE Name = 'VendorInvoice'
	SELECT @billingInvoiceEntityID = ID FROM Entity WHERE Name = 'BillingInvoice'
	
	SELECT @postInvoiceEventID = ID FROM [Event] WHERE Name = 'PostInvoice'
	
	DECLARE @index INT = 1, @maxRows INT = 0, @billingInvoiceID INT = 0
	
	SELECT @maxRows = MAX(ID) FROM @tblBillingInvoices
	
	--DEBUG: SELECT @index,@maxRows
	
	WHILE (@index <= @maxRows AND @maxRows > 0)
	BEGIN
		
		
		
		SELECT @billingInvoiceID = RecordID FROM @tblBillingInvoices WHERE ID = @index
		
		--DEBUG: SELECT 'Updating statuses' As StatusMessage,@billingInvoiceID AS InvoiceID
		
		-- Update Billing Invoice.
		UPDATE	BillingInvoice 
		SET		InvoiceStatusID = @BillingInvoiceStatus_POSTED,
				AccountingInvoiceBatchID = @billedBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		WHERE	ID = @billingInvoiceID		
		
		-- Update Billing InvoiceLines
		UPDATE	BillingInvoiceLine
		SET		InvoiceLineStatusID = @BillingInvoiceLineStatus_POSTED,
				ModifyBy = @currentUser,
				ModifyDate = @now
		WHERE	BillingInvoiceID = @billingInvoiceID
		
		-- Update BillingInvoiceDetail and related entities.
		UPDATE	BillingInvoiceDetail
		SET		AccountingInvoiceBatchID = CASE WHEN ISNULL(BID.IsExcluded,0) = 1
												THEN @unBilledBatchID
												ELSE @billedBatchID
											END,
				InvoiceDetailDispositionID = @BillingInvoiceDisposition_LOCKED,
				InvoiceDetailStatusID = @BillingInvoiceDetailStatus_POSTED,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	BillingInvoiceDetail BID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID AND BID.InvoiceDetailStatusID <> @BillingInvoiceDetailStatus_DELETED
		
		
		-- SRs
		UPDATE	ServiceRequest
		SET		AccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	ServiceRequest SR
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @serviceRequestEntityID AND BID.EntityKey = SR.ID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
				
		-- POs
		UPDATE	PurchaseOrder
		SET		AccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	PurchaseOrder PO
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @purchaseOrderEntityID AND BID.EntityKey = PO.ID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
		
		-- Claims PassThru
		UPDATE	Claim
		SET		PassthruAccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	Claim C
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @claimEntityID AND BID.EntityKey = C.ID
		JOIN	BillingDefinitionInvoiceLine BDIL ON BID.BillingDefinitionInvoiceLineID = BDIL.ID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
		AND		BDIL.Rate IS NULL
		
		-- Claims Fee
		UPDATE	Claim
		SET		FeeAccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	Claim C
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @claimEntityID AND BID.EntityKey = C.ID
		JOIN	BillingDefinitionInvoiceLine BDIL ON BID.BillingDefinitionInvoiceLineID = BDIL.ID
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
		AND		BDIL.Rate IS NOT NULL
		
		-- VendorInvoice
		UPDATE	VendorInvoice
		SET		AccountingInvoiceBatchID = BID.AccountingInvoiceBatchID,
				ModifyBy = @currentUser,
				ModifyDate = @now
		FROM	VendorInvoice VI
		JOIN	BillingInvoiceDetail BID ON BID.EntityID = @vendorInvoiceEntityID AND BID.EntityKey = VI.ID		
		JOIN	BillingInvoiceLine BIL ON BIL.ID = BID.BillingInvoiceLineID
		JOIN	BillingInvoice BI ON BI.ID = BIL.BillingInvoiceID
		WHERE	BI.ID = @billingInvoiceID
		
		
		INSERT INTO EventLog
		SELECT	@postInvoiceEventID,
				@sessionID,
				@eventSource,
				@eventDetails,
				NULL,
				NULL,
				GETDATE(),
				@currentUser
				
		INSERT INTO EventLogLink
		SELECT	SCOPE_IDENTITY(),
				@billingInvoiceEntityID,
				@billingInvoiceID			
	
		SET @index = @index + 1
		
		
	END
 
 
 END

GO

GO

GO
/*******************
* Operator Enums 
*  Conditions Enum :
* -1 - No filter
*  0 - Null
*  1 - Not Null
*  2 - Equals
*  3 - NotEquals
*  ---- for strings ---
*  4 - StartsWith
*  5 - EndsWith
*  6 - Contains
*  ---- for int, decimal, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Billing_Invoice_Lines_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Billing_Invoice_Lines_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC [dms_Billing_Invoice_Lines_List_Get] @BillingInvoiceID=14
 CREATE PROCEDURE [dbo].[dms_Billing_Invoice_Lines_List_Get](   
   @whereClauseXML XML = NULL 
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10    
 , @sortColumn nvarchar(100)  = ''   
 , @sortOrder nvarchar(100) = ''   
 , @BillingInvoiceID INT = NULL  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON
DECLARE @tmpForWhereClause TABLE
(
ScheduleDateFrom DATETIME NULL,
ScheduleDateTo DATETIME NULL,
ClientID INT NULL,
BillingDefinitionInvoiceID INT NULL,
LineStatuses NVARCHAR(MAX) NULL,
InvoiceStatuses NVARCHAR(MAX) NULL,
BillingDefinitionInvoiceLines NVARCHAR(MAX) NULL
)
CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Product nvarchar(100)  NULL ,
	RateType nvarchar(100)  NULL ,
	BillingDefinitionInvoiceLine nvarchar(100)  NULL ,
	BillingInvoiceLineStatus nvarchar(100)  NULL ,
	ID int  NULL ,
	BillingInvoiceID int  NULL ,
	ProductID int  NULL ,
	RateTypeID int  NULL ,
	Name nvarchar(100)  NULL ,
	Description nvarchar(100)  NULL ,
	Comment nvarchar(100)  NULL ,
	AccountingSystemGLCode nvarchar(100)  NULL ,
	LineQuantity int  NULL ,
	LineCost money  NULL ,
	LineAmount money  NULL ,
	InvoiceLineStatusID int  NULL ,
	BillingDefinitionInvoiceLineID int  NULL ,
	AccountingSystemItemCode nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsActive bit  NULL ,
	CreateDate datetime  NULL ,
	CreateBy nvarchar(100)  NULL ,
	ModifyDate datetime  NULL ,
	ModifyBy nvarchar(100)  NULL 
) 
CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Product nvarchar(100)  NULL ,
	RateType nvarchar(100)  NULL ,
	BillingDefinitionInvoiceLine nvarchar(100)  NULL ,
	BillingInvoiceLineStatus nvarchar(100)  NULL ,
	ID int  NULL ,
	BillingInvoiceID int  NULL ,
	ProductID int  NULL ,
	RateTypeID int  NULL ,
	Name nvarchar(100)  NULL ,
	Description nvarchar(100)  NULL ,
	Comment nvarchar(100)  NULL ,
	AccountingSystemGLCode nvarchar(100)  NULL ,
	LineQuantity int  NULL ,
	LineCost money  NULL ,
	LineAmount money  NULL ,
	InvoiceLineStatusID int  NULL ,
	BillingDefinitionInvoiceLineID int  NULL ,
	AccountingSystemItemCode nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsActive bit  NULL ,
	CreateDate datetime  NULL ,
	CreateBy nvarchar(100)  NULL ,
	ModifyDate datetime  NULL ,
	ModifyBy nvarchar(100)  NULL 
) 
INSERT INTO @tmpForWhereClause
SELECT  
		T.c.value('@ScheduleDateFrom','datetime'),
		T.c.value('@ScheduleDateTo','datetime'),
		T.c.value('@ClientID','int') ,
		T.c.value('@BillingDefinitionInvoiceID','int') ,
		T.c.value('@LineStatuses','NVARCHAR(MAX)'),
		T.c.value('@InvoiceStatuses','NVARCHAR(MAX)'), 
		T.c.value('@BillingDefinitionInvoiceLines','NVARCHAR(MAX)') 
				
		
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @ScheduleDateFrom DATETIME ,
@ScheduleDateTo DATETIME ,
@ClientID INT ,
@BillingDefinitionInvoiceID INT ,
@LineStatuses NVARCHAR(MAX) ,
@InvoiceStatuses NVARCHAR(MAX),
@BillingDefinitionInvoiceLines NVARCHAR(MAX)

SELECT	@LineStatuses = T.LineStatuses,
		@BillingDefinitionInvoiceLines = T.BillingDefinitionInvoiceLines
FROM	@tmpForWhereClause T

INSERT INTO #tmpFinalResults    
Select	P.Name AS Product
	 , RT.Name AS RateType
	 , BDIL.Name AS BillingDefinitionInvoiceLine
	 , BILS.Name AS BillingInvoiceLineStatus
	 , BIL.* from BillingInvoiceLine BIL 
LEFT OUTER JOIN Product P ON P.ID = BIL.ProductID
LEFT OUTER JOIN RateType RT ON RT.ID = BIL.RateTypeID
LEFT OUTER JOIN BillingDefinitionInvoiceLine BDIL ON BDIL.ID = BIL.BillingDefinitionInvoiceLineID
LEFT OUTER JOIN BillingInvoiceLineStatus BILS ON BILS.ID = BIL.InvoiceLineStatusID
where BIL.BillingInvoiceID = @BillingInvoiceID
AND		ISNULL(BIL.IsActive,0) = 1
AND	(@LineStatuses IS NULL OR BILS.ID IN (SELECT item FROM fnSplitString(@LineStatuses,',') ))
AND	(@BillingDefinitionInvoiceLines IS NULL OR BDIL.ID IN (SELECT item FROM fnSplitString(@BillingDefinitionInvoiceLines,',') ))
ORDER BY BIL.Sequence

INSERT INTO #FinalResults
SELECT 
	T.Product,
	T.RateType,
	T.BillingDefinitionInvoiceLine,
	T.BillingInvoiceLineStatus,
	T.ID,
	T.BillingInvoiceID,
	T.ProductID,
	T.RateTypeID,
	T.Name,
	T.[Description],
	T.Comment,
	T.AccountingSystemGLCode,
	T.LineQuantity,
	T.LineCost,
	T.LineAmount,
	T.InvoiceLineStatusID,
	T.BillingDefinitionInvoiceLineID,
	T.AccountingSystemItemCode,
	T.Sequence,
	T.IsActive,
	T.CreateDate,
	T.CreateBy,
	T.ModifyDate,
	T.ModifyBy
FROM #tmpFinalResults T

 ORDER BY 
	 CASE WHEN @sortColumn = 'Product' AND @sortOrder = 'ASC'
	 THEN T.Product END ASC, 
	 CASE WHEN @sortColumn = 'Product' AND @sortOrder = 'DESC'
	 THEN T.Product END DESC ,

	 CASE WHEN @sortColumn = 'RateType' AND @sortOrder = 'ASC'
	 THEN T.RateType END ASC, 
	 CASE WHEN @sortColumn = 'RateType' AND @sortOrder = 'DESC'
	 THEN T.RateType END DESC ,

	 CASE WHEN @sortColumn = 'BillingDefinitionInvoiceLine' AND @sortOrder = 'ASC'
	 THEN T.BillingDefinitionInvoiceLine END ASC, 
	 CASE WHEN @sortColumn = 'BillingDefinitionInvoiceLine' AND @sortOrder = 'DESC'
	 THEN T.BillingDefinitionInvoiceLine END DESC ,

	 CASE WHEN @sortColumn = 'BillingInvoiceLineStatus' AND @sortOrder = 'ASC'
	 THEN T.BillingInvoiceLineStatus END ASC, 
	 CASE WHEN @sortColumn = 'BillingInvoiceLineStatus' AND @sortOrder = 'DESC'
	 THEN T.BillingInvoiceLineStatus END DESC ,

	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'BillingInvoiceID' AND @sortOrder = 'ASC'
	 THEN T.BillingInvoiceID END ASC, 
	 CASE WHEN @sortColumn = 'BillingInvoiceID' AND @sortOrder = 'DESC'
	 THEN T.BillingInvoiceID END DESC ,

	 CASE WHEN @sortColumn = 'ProductID' AND @sortOrder = 'ASC'
	 THEN T.ProductID END ASC, 
	 CASE WHEN @sortColumn = 'ProductID' AND @sortOrder = 'DESC'
	 THEN T.ProductID END DESC ,

	 CASE WHEN @sortColumn = 'RateTypeID' AND @sortOrder = 'ASC'
	 THEN T.RateTypeID END ASC, 
	 CASE WHEN @sortColumn = 'RateTypeID' AND @sortOrder = 'DESC'
	 THEN T.RateTypeID END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'ASC'
	 THEN T.Description END ASC, 
	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'DESC'
	 THEN T.Description END DESC ,

	 CASE WHEN @sortColumn = 'Comment' AND @sortOrder = 'ASC'
	 THEN T.Comment END ASC, 
	 CASE WHEN @sortColumn = 'Comment' AND @sortOrder = 'DESC'
	 THEN T.Comment END DESC ,

	 CASE WHEN @sortColumn = 'AccountingSystemGLCode' AND @sortOrder = 'ASC'
	 THEN T.AccountingSystemGLCode END ASC, 
	 CASE WHEN @sortColumn = 'AccountingSystemGLCode' AND @sortOrder = 'DESC'
	 THEN T.AccountingSystemGLCode END DESC ,

	 CASE WHEN @sortColumn = 'LineQuantity' AND @sortOrder = 'ASC'
	 THEN T.LineQuantity END ASC, 
	 CASE WHEN @sortColumn = 'LineQuantity' AND @sortOrder = 'DESC'
	 THEN T.LineQuantity END DESC ,

	 CASE WHEN @sortColumn = 'LineCost' AND @sortOrder = 'ASC'
	 THEN T.LineCost END ASC, 
	 CASE WHEN @sortColumn = 'LineCost' AND @sortOrder = 'DESC'
	 THEN T.LineCost END DESC ,

	 CASE WHEN @sortColumn = 'LineAmount' AND @sortOrder = 'ASC'
	 THEN T.LineAmount END ASC, 
	 CASE WHEN @sortColumn = 'LineAmount' AND @sortOrder = 'DESC'
	 THEN T.LineAmount END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceLineStatusID' AND @sortOrder = 'ASC'
	 THEN T.InvoiceLineStatusID END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceLineStatusID' AND @sortOrder = 'DESC'
	 THEN T.InvoiceLineStatusID END DESC ,

	 CASE WHEN @sortColumn = 'BillingDefinitionInvoiceLineID' AND @sortOrder = 'ASC'
	 THEN T.BillingDefinitionInvoiceLineID END ASC, 
	 CASE WHEN @sortColumn = 'BillingDefinitionInvoiceLineID' AND @sortOrder = 'DESC'
	 THEN T.BillingDefinitionInvoiceLineID END DESC ,

	 CASE WHEN @sortColumn = 'AccountingSystemItemCode' AND @sortOrder = 'ASC'
	 THEN T.AccountingSystemItemCode END ASC, 
	 CASE WHEN @sortColumn = 'AccountingSystemItemCode' AND @sortOrder = 'DESC'
	 THEN T.AccountingSystemItemCode END DESC ,

	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'
	 THEN T.Sequence END ASC, 
	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'
	 THEN T.Sequence END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC ,

	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'
	 THEN T.CreateDate END ASC, 
	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'
	 THEN T.CreateDate END DESC ,

	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
	 THEN T.CreateBy END ASC, 
	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
	 THEN T.CreateBy END DESC ,

	 CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'ASC'
	 THEN T.ModifyDate END ASC, 
	 CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'DESC'
	 THEN T.ModifyDate END DESC ,

	 CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'ASC'
	 THEN T.ModifyBy END ASC, 
	 CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'DESC'
	 THEN T.ModifyBy END DESC 

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
    
 SELECT @count AS TotalRows, * FROM #FinalResults WHERE RowNum BETWEEN @startInd AND @endInd    
     
 DROP TABLE #FinalResults    
 DROP TABLE #tmpFinalResults    

END

GO

GO

GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Call_Summary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Call_Summary]
GO

--EXEC dms_Call_Summary @serviceRequestID = 1414  
CREATE PROC dms_Call_Summary(@serviceRequestID INT = NULL)  
AS  
BEGIN 
	DECLARE @Hold TABLE(ColumnName NVARCHAR(MAX),ColumnValue NVARCHAR(MAX),DataType NVARCHAR(MAX),Sequence INT,GroupName NVARCHAR(MAX),DefaultRows INT NULL) 
DECLARE @ProgramDataItemValues TABLE(Name NVARCHAR(MAX),Value NVARCHAR(MAX),ScreenName NVARCHAR(MAX))       

;WITH wProgDataItemValues
AS
(
SELECT ROW_NUMBER() OVER ( PARTITION BY EntityID, RecordID, ProgramDataItemID ORDER BY CreateDate DESC) AS RowNum,
              *
FROM   ProgramDataItemValueEntity 
WHERE  RecordId = (SELECT CaseID FROM ServiceRequest WHERE ID=@serviceRequestID)
)

INSERT INTO @ProgramDataItemValues
SELECT 
        PDI.Name,
        W.Value,
        PDI.ScreenName
FROM   ProgramDataItem PDI
JOIN   wProgDataItemValues W ON PDI.ID = W.ProgramDataItemID
WHERE  W.RowNum = 1



	DECLARE @DocHandle int    
	DECLARE @XmlDocument NVARCHAR(MAX)   
	DECLARE @ProductID INT
	SET @ProductID = NULL
	SELECT  @ProductID = PrimaryProductID FROM ServiceRequest WHERE ID = @serviceRequestID

-- Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'

	SET FMTONLY OFF    
-- Sanghi : ISNull is required because generating XML will ommit the columns.     
-- Two Blank Space is required.  
	DECLARE @tmpServiceLocationVendor TABLE
	(
		Line1 NVARCHAR(100) NULL,
		Line2 NVARCHAR(100) NULL,
		Line3 NVARCHAR(100) NULL,
		City NVARCHAR(100) NULL,
		StateProvince NVARCHAR(100) NULL,
		CountryCode NVARCHAR(100) NULL,
		PostalCode NVARCHAR(100) NULL,
		
		TalkedTo NVARCHAR(50) NULL,
		PhoneNumber NVARCHAR(100) NULL,
		VendorName NVARCHAR(100) NULL
	)
	INSERT INTO @tmpServiceLocationVendor	
	SELECT	TOP 1	AE.Line1, 
					AE.Line2, 
					AE.Line3, 
					AE.City, 
					AE.StateProvince, 
					AE.CountryCode, 
					AE.PostalCode,
					cl.TalkedTo,
					cl.PhoneNumber,
					V.Name As VendorName
		FROM	ContactLogLink cll
		JOIN	ContactLog cl on cl.ID = cll.ContactLogID
		JOIN	ContactLogLink cll2 on cll2.contactlogid = cl.id and cll2.entityid = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest') and cll2.RecordID = @serviceRequestID
		JOIN	VendorLocation VL ON cll.RecordID = VL.ID
		JOIN	Vendor V ON VL.VendorID = V.ID 	
		JOIN	AddressEntity AE ON AE.RecordID = VL.ID AND AE.EntityID = (SELECT ID FROM Entity WHERE name = 'VendorLocation')
		WHERE	cll.entityid = (SELECT ID FROM Entity WHERE name = 'VendorLocation')
		AND		cl.ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ServiceLocationSelection')
		ORDER BY cll.id DESC
	

  
	SET @XmlDocument = (SELECT TOP 1    

-- PROGRAM SECTION
--	1 AS Program_DefaultNumberOfRows   
	cl.Name + ' - ' + p.name as Program_ClientProgramName    
    ,(SELECT 'Case Number:'+Value FROM @ProgramDataItemValues WHERE ScreenName='StartCall' AND Name='CaseNumber') AS Program_CaseNumber
    ,(SELECT 'Agent Name:'+Value FROM @ProgramDataItemValues WHERE ScreenName='StartCall' AND Name='AgentName') AS Program_AgentName
    ,(SELECT 'Claim Number:'+ Value FROM @ProgramDataItemValues WHERE ScreenName='StartCall' AND Name='ClaimNumber') AS Program_ClaimNumber
-- MEMBER SECTION
--	, 5 AS Member_DefaultNumberOfRows
-- KB : 6/7 : TFS # 1339 : Presenting Case.Contactfirstname and Case.ContactLastName as member name and the values from member as company_name when the values differ.	
   -- Ignore time while comparing dates here
    -- KB: Considering Effective and Expiration Dates to calculate member status
	, CASE 
		WHEN	ISNULL(m.EffectiveDate,@minDate) <= @now AND ISNULL(m.ExpirationDate,@minDate) >= @now
		THEN	'Active'
		ELSE	'Inactive'
		END	AS Member_Status     
	, COALESCE(c.ContactFirstName,'') + COALESCE(' ' + c.ContactLastName,'') AS Member_Name
	, CASE
		WHEN	c.ContactFirstName <> m.Firstname
		AND		c.ContactLastName <> m.LastName
		THEN
				REPLACE(RTRIM(    
				COALESCE(m.FirstName, '') +    
				COALESCE(m.MiddleName, '') +   
				COALESCE(m.Suffix, '') + 
				COALESCE(' ' + m.LastName, '') 
				), '  ', ' ')
		ELSE
				NULL
		END as Member_CompanyName
    , ISNULL(ms.MembershipNumber,' ') AS Member_MembershipNumber
    , ISNULL((SELECT NAME FROM PhoneType WHERE ID = c.ContactPhoneTypeID),' ') as Member_CallbackPhoneTypeID    
    , ISNULL(c.ContactPhoneNumber,'') as Member_CallbackPhoneNumber    
    , ISNULL((SELECT NAME FROM PhoneType WHERE ID = c.ContactAltPhoneTypeID),' ') as Member_AltCallbackPhoneTypeID   
    , ISNULL(c.ContactAltPhoneNumber,'') as Member_AltCallbackPhoneNumber    
    , CONVERT(nvarchar(10),m.MemberSinceDate,101) as Member_MemberSinceDate
    , CONVERT(nvarchar(10),m.EffectiveDate,101) AS Member_EffectiveDate
    , CONVERT(nvarchar(10),m.ExpirationDate,101) AS Member_ExpirationDate
    , ISNULL(ae.Line1,'') AS Member_AddressLine1
    , ISNULL(ae.Line2,'') AS Member_AddressLine2
    , ISNULL(REPLACE(RTRIM(    
		COALESCE(ae.City, '') +
		COALESCE(', ' + ae.StateProvince, '') +
		COALESCE(' ' + ae.PostalCode, '') +
		COALESCE(' ' + ae.CountryCode, '') 
		), '  ', ' ')
		, ' ' ) AS Member_AddressCityStateZip
	,'Client Ref #:' + ms.ClientReferenceNumber AS Member_ReceiptNumber
-- VEHICLE SECTION
--	, 3 AS Vehicle_DefalutNumberOfRows
	,CASE	WHEN C.IsVehicleEligible IS NULL THEN '' 
			WHEN C.IsVehicleEligible = 1 THEN 'In Warranty'
			ELSE 'Out of Warranty' END AS Vehicle_IsEligible
	, ISNULL(RTRIM (
		COALESCE(c.VehicleYear + ' ', '') +    
		COALESCE(CASE c.VehicleMake WHEN 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END+ ' ', '') +    
		COALESCE(CASE C.VehicleModel WHEN 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END, '')
		), ' ') as Vehicle_YearMakeModel    
	, ISNULL(c.VehicleVIN,' ') as Vehicle_VIN    
	, ISNULL(RTRIM (
		COALESCE(c.VehicleColor + '  ' , '') +
		COALESCE(c.VehicleLicenseState + '-','') + 
		COALESCE(c.VehicleLicenseNumber, '')
		), ' ' ) AS Vehicle_Color_LicenseStateNumber
    ,ISNULL(
			COALESCE((SELECT Name FROM VehicleType WHERE ID = c.VehicleTypeID) + '-','') +
			COALESCE((SELECT Name FROM VehicleCategory WHERE ID = c.VehicleCategoryID),'') 
		,'') AS Vehicle_Type_Category
    ,ISNULL(C.[VehicleDescription],'') AS Vehicle_Description
    ,CASE WHEN C.[VehicleLength] IS NULL THEN '' ELSE CONVERT(NVARCHAR(50),C.[VehicleLength]) END AS Vehicle_Length
-- SERVICE SECTION   
--	, 2 AS Service_DefaultNumberOfRows  
	
	, CASE WHEN sr.IsPrimaryOverallCovered  = 1 THEN 'Covered' ELSE 'Not Covered' END AS Service_IsPrimaryOverallCovered
	, pc.Name as Service_ProductCategoryTow
	, sr.PrimaryServiceEligiblityMessage as Service_PrimaryServiceEligiblityMessage

	, CASE WHEN sr.IsSecondaryOverallCovered  = 1 THEN 'Covered' ELSE 'Not Covered' END AS Service_IsSecondaryOverallCovered
	, CASE WHEN sr.IsPossibleTow = 1 THEN 'Possible Tow' ELSE '' END AS Service_IsPossibleTow
	, sr.SecondaryServiceEligiblityMessage as Service_SecondaryServiceEligiblityMessage

	--, '$' + CONVERT(NVARCHAR(50),ISNULL(sr.PrimaryCoverageLimit,0)) as Service_CoverageLimit  

-- LOCATION SECTION     
--	, 2 AS Location_DefaultNumberOfRows
	, ISNULL(sr.ServiceLocationAddress,' ') as Location_Address    
	, ISNULL(sr.ServiceLocationDescription,' ') as Location_Description  

-- DESTINATION SECTION     
--	, 2 AS Destination_DefaultNumberOfRows
	, ISNULL(sr.DestinationAddress,' ') as Destination_Address    
	, ISNULL(sr.DestinationDescription,' ') as Destination_Description 	
	, (SELECT VendorName FROM @tmpServiceLocationVendor ) AS Destination_VendorName
	, (SELECT PhoneNumber FROM @tmpServiceLocationVendor ) AS Destination_PhoneNumber
	, (SELECT TalkedTo FROM @tmpServiceLocationVendor ) AS Destination_TalkedTo
	, (SELECT ISNULL(Line1,'') FROM @tmpServiceLocationVendor ) AS Destination_AddressLine1
    , (SELECT ISNULL(Line2,'') FROM @tmpServiceLocationVendor) AS Destination_AddressLine2
    , (SELECT ISNULL(REPLACE(RTRIM(    
		COALESCE(City, '') +
		COALESCE(', ' + StateProvince, '') +
		COALESCE(' ' + PostalCode, '') +
		COALESCE(' ' + CountryCode, '') 
		), '  ', ' ')
		, ' ' ) FROM  @tmpServiceLocationVendor) AS Destination_AddressCityStateZip    
		
-- ISP SECTION
--	, 3 AS ISP_DefaultNumberOfRows
	--,CASE 
	--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NOT NULL THEN 'Contracted'
	--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NULL THEN 'Not Contracted'
	--	WHEN vc.ID IS NOT NULL THEN 'Contracted' 
	--	ELSE 'Not Contracted'
	--	END as ISP_Contracted
	, CASE
		WHEN ContractedVendors.ContractID IS NOT NULL 
			AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'
		ELSE 'Not Contracted' 
		END AS ISP_Contracted
	, ISNULL(v.Name,' ') as ISP_VendorName    
	, ISNULL(v.VendorNumber, ' ') AS ISP_VendorNumber
	--, ISNULL(peISP.PhoneNumber,' ') as ISP_DispatchPhoneNumber 
	, (SELECT TOP 1 PhoneNumber
		FROM PhoneEntity 
		WHERE RecordID = vl.ID
		AND EntityID = (Select ID From Entity Where Name = 'VendorLocation')
		AND PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')
		ORDER BY ID DESC
		) AS ISP_DispatchPhoneNumber
	, ISNULL(aeISP.Line1,'') AS ISP_AddressLine1
    , ISNULL(aeISP.Line2,'') AS ISP_AddressLine2
    , ISNULL(REPLACE(RTRIM(    
		COALESCE(aeISP.City, '') +
		COALESCE(', ' + aeISP.StateProvince, '') +
		COALESCE(' ' + aeISP.PostalCode, '') +
		COALESCE(' ' + aeISP.CountryCode, '') 
		), '  ', ' ')
		, ' ' ) AS ISP_AddressCityStateZip
	, COALESCE(ISNULL(po.PurchaseOrderNumber + '-', ' '),'') + ISNULL(pos.Name, ' ' ) AS ISP_PONumberStatus
--	, ISNULL(pos.Name, ' ' ) AS ISP_POStatus
	, COALESCE( '$' + CONVERT(NVARCHAR(10),po.PurchaseOrderAmount),'') 
		+ ' ' 
		+ ISNULL(CASE WHEN po.ID IS NOT NULL THEN PC.Name ELSE NULL END,'') AS ISP_POAmount_ProductCategory
	--, ISNULL(po.PurchaseOrderAmount, ' ' ) AS ISP_POAmount
	, 'Issued:' +
		REPLACE(CONVERT(VARCHAR(8), po.IssueDate, 10), '-', '/') + ' - ' +  
		SUBSTRING(CONVERT(VARCHAR(20), po.IssueDate, 9), 13, 8) + ' ' +  
		SUBSTRING(CONVERT(VARCHAR(30), po.IssueDate, 9), 25, 2) AS ISP_IssuedDate  
	, 'ETA:' +
		REPLACE(CONVERT(VARCHAR(8), po.ETADate, 10), '-', '/') + ' - ' +  
		SUBSTRING(CONVERT(VARCHAR(20), po.ETADate, 9), 13, 8) + ' ' +  
		SUBSTRING(CONVERT(VARCHAR(30), po.ETADate, 9), 25, 2) AS ISP_ETADate  

-- SERVICE REQUEST SECTION 
--	, 2 AS SR_DefaultNumberOfRows
	--Sanghi 03 - July - 2013 Updated Below Line.
	, CAST(CAST(ISNULL(sr.ID, ' ') AS NVARCHAR(MAX)) + ' - ' + ISNULL(srs.Name, ' ') AS NVARCHAR(MAX))  AS SR_Info 
	--, ISNULL(sr.ID,' ') as SR_ServiceRequestID      
	--,(ISNULL(srs.Name,'')) + CASE WHEN na.Name IS NULL THEN '' ELSE ' - ' + (ISNULL(na.Name,'')) END AS SR_ServiceRequestStatus
	--, ISNULL('Closed Loop: ' + cls.Name, ' ') as SR_ClosedLoopStatus
	, ISNULL(sr.CreateBy,' ') + ' ' + 
		    REPLACE(CONVERT(VARCHAR(8), sr.CreateDate, 10), '-', '/') + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(20), sr.CreateDate, 9), 13, 8) + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(30), sr.CreateDate, 9), 25, 2
			) AS SR_CreateInfo
	--, ISNULL(sr.CreateBy,' ')as SR_CreatedBy   
	--, REPLACE(CONVERT(VARCHAR(8), sr.CreateDate, 10), '-', '/') + ' - ' +  
	--	SUBSTRING(CONVERT(VARCHAR(20), sr.CreateDate, 9), 13, 8) + ' ' +  
	--	SUBSTRING(CONVERT(VARCHAR(30), sr.CreateDate, 9), 25, 2) AS SR_CreateDate
	--, ISNULL(NextAction.Name, ' ') + ISNULL(u.FirstName, ' ') + ' ' + ISNULL(u.LastName,' ') AS SR_NextActionInfo  
	, ISNULL(NextAction.Name + ' - ', ' ') + ISNULL(u.FirstName, ' ') + ' ' + ISNULL(u.LastName,' ') AS SR_NextActionName_AssignedTo
	, ISNULL( 	
			REPLACE(
			CONVERT(VARCHAR(8), sr.NextActionScheduledDate, 10), '-', '/') + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(20), sr.NextActionScheduledDate, 9), 13, 8) + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(30), sr.NextActionScheduledDate, 9), 25, 2
			) 
			, ' ') AS SR_NextActionScheduledDate
	--, ISNULL('AssignedTo: ' + u.FirstName, ' ') + ' ' + ISNULL(u.LastName,' ') AS SR_NextActionAssignedTo  

	FROM		ServiceRequest sr      
	JOIN		[Case] c on c.ID = sr.CaseID    
	LEFT JOIN	PhoneType ptContact on ptContact.ID = c.ContactPhoneTypeID    
	JOIN		Program p on p.ID = c.ProgramID    
	JOIN		Client cl on cl.ID = p.ClientID    
	JOIN		Member m on m.ID = c.MemberID    
	JOIN		Membership ms on ms.ID = m.MembershipID    
	LEFT JOIN	AddressEntity ae ON ae.EntityID = (select ID from Entity where Name = 'Membership')    
	AND			ae.RecordID = ms.ID    
	AND			ae.AddressTypeID = (select ID from AddressType where Name = 'Home')    
	LEFT JOIN	Country country on country.ID = ae.CountryID     
	LEFT JOIN	PhoneEntity peMbr ON peMbr.EntityID = (select ID from Entity where Name = 'Membership')     
	AND			peMbr.RecordID = ms.ID    
	AND			peMbr.PhoneTypeID = (select ID from PhoneType where Name = 'Home')    
	LEFT JOIN	PhoneType ptMbr on ptMbr.ID = peMbr.PhoneTypeID    
	LEFT JOIN	ProductCategory pc on pc.ID = sr.ProductCategoryID    
	LEFT JOIN	(  
				SELECT TOP 1 *  
				FROM PurchaseOrder wPO   
				WHERE wPO.ServiceRequestID = @serviceRequestID  
				AND wPO.IsActive = 1
				AND wPO.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending')
				ORDER BY wPO.IssueDate DESC  
				) po on po.ServiceRequestID = sr.ID  
	LEFT JOIN	PurchaseOrderStatus pos on pos.ID = po.PurchaseOrderStatusID  
	LEFT JOIN	VendorLocation vl on vl.ID = po.VendorLocationID    
	LEFT JOIN	Vendor v on v.ID = vl.VendorID 
	LEFT JOIN	[Contract] vc on vc.VendorID = v.ID and vc.IsActive = 1 and vc.ContractStatusID = (Select ID From ContractStatus Where Name = 'Active')
	LEFT OUTER JOIN (
				SELECT DISTINCT vr.VendorID, vr.ProductID
				FROM dbo.fnGetCurrentProductRatesByVendorLocation() vr 
				) DefaultVendorRates ON v.ID = DefaultVendorRates.VendorID And @ProductID = DefaultVendorRates.ProductID
	LEFT OUTER JOIN (
				SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID
				FROM dbo.fnGetContractedVendors() cv
				) ContractedVendors ON v.ID = ContractedVendors.VendorID
	--LEFT JOIN	PhoneEntity peISP on peISP.EntityID = (select ID from Entity where Name = 'VendorLocation')     
	--AND			peISP.RecordID = vl.ID    
	--AND			peISP.PhoneTypeID = (select ID from PhoneType where Name = 'Dispatch')  
	--LEFT JOIN	PhoneType ptISP on ptISP.ID = peISP.PhoneTypeID    
	--LEFT JOIN (
	--			SELECT TOP 1 ph.RecordID, ph.PhoneNumber
	--			FROM PhoneEntity ph 
	--			WHERE EntityID = (Select ID From Entity Where Name = 'VendorLocation')
	--			AND PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')
	--			ORDER BY ID 
	--		   )  peISP ON peISP.RecordID = vl.ID
	LEFT JOIN	AddressEntity aeISP ON aeISP.EntityID = (select ID from Entity where Name = 'VendorLocation')    
	AND			aeISP.RecordID = vl.ID    
	AND			aeISP.AddressTypeID = (select ID from AddressType where Name = 'Business')    
 -- CR # 524  
	LEFT JOIN	ServiceRequestStatus srs ON srs.ID=sr.ServiceRequestStatusID  
	LEFT JOIN	NextAction na ON na.ID=sr.NextActionID  
	LEFT JOIN	ClosedLoopStatus cls ON cls.ID=sr.ClosedLoopStatusID 
 -- End : CR # 524  
 	LEFT JOIN	VendorLocation VLD ON VLD.ID = sr.DestinationVendorLocationID
	LEFT JOIN	PhoneEntity peDestination ON peDestination.RecordID = VLD.ID AND peDestination.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')  
	LEFT JOIN	NextAction NextAction on NextAction.ID = sr.NextActionID
	LEFT JOIN	[User] u on u.ID = sr.NextActionAssignedToUserID

	WHERE		sr.ID = @ServiceRequestID    
	FOR XML PATH)    
    

EXEC sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument    
SELECT * INTO #Temp FROM OPENXML (@DocHandle, '/row',2)      
INSERT INTO @Hold    
SELECT T1.localName ,T2.text,'String',ROW_NUMBER() OVER(ORDER BY T1.ID),'',NULL FROM #Temp T1     
INNER JOIN #Temp T2 ON T1.id = T2.parentid    
WHERE T1.id > 0    
    
    
DROP TABLE #Temp    
    -- Group Values Based on Sequence Number    
 UPDATE @Hold SET GroupName = 'Member', DefaultRows = 6 WHERE CHARINDEX('Member_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Vehicle', DefaultRows = 3 WHERE CHARINDEX('Vehicle_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Service' ,DefaultRows = 6 WHERE CHARINDEX('Service_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Location', DefaultRows = 2 WHERE CHARINDEX('Location_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Destination', DefaultRows = 2 WHERE CHARINDEX('Destination_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'ISP', DefaultRows = 10 WHERE CHARINDEX('ISP_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Program', DefaultRows = 1 WHERE CHARINDEX('Program_',ColumnName) > 0   
 UPDATE  @Hold SET GroupName = 'Service Request', DefaultRows = 2 WHERE CHARINDEX('SR_',ColumnName) > 0   
     
 --CR # 524   
      
-- UPDATE @Hold SET GroupName ='Service Request' where ColumnName in ('ServiceRequestID','ServiceRequestStatus','NextAction',  
--'ClosedLoopStatus',  
--'CreateDate','CreatedBy','SR_NextAction','SR_NextActionAssignedTo')  
 -- End : CR # 524  
   
 UPDATE @Hold SET DataType = 'Phone' WHERE CHARINDEX('PhoneNumber',ColumnName) > 0    
 UPDATE @Hold SET DataType = 'LabelTheme' WHERE CHARINDEX('Member_Status',ColumnName) > 0 OR CHARINDEX('Vehicle_IsEligible',ColumnName) > 0  
 UPDATE @Hold SET DataType = 'LabelThemeInline' WHERE CHARINDEX('Service_IsPrimaryOverallCovered',ColumnName) > 0
 UPDATE @Hold SET DataType = 'LabelThemeInline' WHERE CHARINDEX('Service_IsSecondaryOverallCovered',ColumnName) > 0   

 IF NOT EXISTS (SELECT * FROM @Hold WHERE ColumnName  = 'Service_IsPossibleTow' AND ColumnValue IS NOT NULL AND  ColumnValue != '')
 BEGIN
	DELETE FROM @Hold WHERE ColumnName  = 'Service_IsSecondaryOverallCovered'
	DELETE FROM @Hold WHERE ColumnName  = 'Service_SecondaryServiceEligiblityMessage'
 END

 IF NOT EXISTS (SELECT * FROM @Hold WHERE ColumnName  = 'Service_ProductCategoryTow' AND ColumnValue IS NOT NULL AND  ColumnValue != '')
 BEGIN
	DELETE FROM @Hold WHERE ColumnName  = 'Service_IsPrimaryOverallCovered'
 END

 DELETE FROM @Hold WHERE ColumnValue IS NULL

 DECLARE @DefaultRows INT
 SET  @DefaultRows = (SELECT Sequence FROM @Hold WHERE ColumnName = 'Member_AltCallbackPhoneNumber')
 IF @DefaultRows IS NOT NULL
 BEGIN
 SET @DefaultRows = (SELECT COUNT(*) FROM @Hold WHERE ColumnName LIKE 'Member_%' AND Sequence <= @DefaultRows)
 -- Re Setting values 
 UPDATE @Hold SET DefaultRows = @DefaultRows WHERE GroupName = 'Member' 
 END

 -- Sanghi - 01-04-2014 CR : 248 Increase Number of Columns to be Displayed When Warranty is Applicable.
 -- Validate Vehicle_IsEligible COLUMN 
 IF EXISTS (SELECT * FROM @Hold WHERE ColumnName = 'Vehicle_IsEligible')
 BEGIN
	UPDATE @Hold SET DefaultRows = 4 WHERE GroupName = 'Vehicle' 
 END


 -- Update Label fields
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Member Since: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Member_MemberSinceDate')
 WHERE ColumnName = 'Member_MemberSinceDate'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Effective: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Member_EffectiveDate')
 WHERE ColumnName = 'Member_EffectiveDate'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Expiration: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Member_ExpirationDate')
 WHERE ColumnName = 'Member_ExpirationDate'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'PO: ' + ColumnValue FROM @Hold WHERE ColumnName = 'ISP_PONumberStatus')
 WHERE ColumnName = 'ISP_PONumberStatus'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Length: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Vehicle_Length')
 WHERE ColumnName = 'Vehicle_Length'
 
 
 SELECT * FROM @Hold WHERE ColumnValue IS NOT NULL ORDER BY Sequence ASC 
 
	
END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_CCImport_CreditCardIssueTransactions]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_CCImport_CreditCardIssueTransactions]
GO
CREATE PROC [dbo].dms_CCImport_CreditCardIssueTransactions(@processGUID UNIQUEIDENTIFIER = NULL)
AS
BEGIN

	DECLARE @Results AS TABLE(TotalRecordCount INT,
							  TotalRecordsIgnored INT,
							  TotalCreditCardAdded INT,
							  TotalTransactionAdded INT,
							  TotalErrorRecords INT)
							  
	-- Helpers
	DECLARE @TotalRecordCount INT	= 0
	DECLARE @TotalRecordsIgnored INT = 0
	DECLARE @TotalCreditCardAdded INT = 0
	DECLARE @TotalTransactionAdded INT = 0
	DECLARE @TotalErrorRecords INT	= 0	 			  

	-- Step 1 : Insert Records INTO Temporary Credit Card
	DECLARE @startROWParent INT 
	DECLARE @totalRowsParent INT
	DECLARE @creditCardIssueNumber NVARCHAR(50) 
	DECLARE @creditCardNumber NVARCHAR(50)
	DECLARE @purchaseType NVARCHAR(50)
	DECLARE @transactionSequence INT
	DECLARE @tempLookUpID INT
	DECLARE @newRecordID INT
	
	SET @startROWParent =  (SELECT MIN(RecordID) FROM TemporaryCreditCard_Import 
												 WHERE ProcessIdentifier = @processGUID)
	SET @totalRowsParent = (SELECT MAX(RecordID) FROM TemporaryCreditCard_Import 
												 WHERE ProcessIdentifier = @processGUID)
	
	WHILE(@startROWParent <= @totalRowsParent)  
	BEGIN
		SELECT  @creditCardIssueNumber = IMP.PurchaseID_CreditCardIssueNumber,
				@creditCardNumber = IMP.CPN_PAN_CreditCardNumber,
				@purchaseType = IMP.PURCHASE_TYPE
		FROM TemporaryCreditCard_Import IMP
		WHERE RecordID = @startROWParent
		
		IF(@creditCardNumber IS NULL OR @creditCardNumber = '' OR @purchaseType != 'ISP Claims')
			BEGIN
				INSERT INTO [Log]([Date],[Thread],[Level],[Logger], [Message]) VALUES(GETDATE(),01,'INFO','dms_CCImport_CreditCardIssueTransactions','Business Rule Failed for more information Use Record ID ' + CONVERT(NVARCHAR(100),@startROWParent) + ' TemporaryCreditCard_Import')
			END
		ELSE
			BEGIN
				IF(NOT EXISTS(SELECT * FROM TemporaryCreditCard TCC WHERE 
																TCC.CreditCardIssueNumber = @creditCardIssueNumber AND 
																TCC.CreditCardNumber = @creditCardNumber))
				 BEGIN
				INSERT INTO TemporaryCreditCard(CreditCardIssueNumber,			
								CreditCardNumber,			
								PurchaseOrderID,									
								VendorInvoiceID,				
								IssueDate,					
								IssueBy,
								IssueStatus,					
								ReferencePurchaseOrderNumber,				 
								OriginalReferencePurchaseOrderNumber,					 
								ReferenceVendorNumber,
								ApprovedAmount,					
								TotalChargedAmount,
								TemporaryCreditCardStatusID,									
								ExceptionMessage,				
								Note,						
								CreateDate,
								CreateBy,						
								ModifyDate,					
								ModifyBy) 
					SELECT PurchaseID_CreditCardIssueNumber,
						   CPN_PAN_CreditCardNumber,
						   PurchaseOrderID,
						   VendorInvoiceID,
						   CREATE_DATE_IssueDate_TransactionDate,
						   USER_NAME_IssueBy_TransactionBy,
						   IssueStatus,
						   CDF_PO_ReferencePurchaseOrderNumber,
						   CDF_PO_OriginalReferencePurchaseOrderNumber,
						   CDF_ISP_Vendor_ReferenceVendorNumber,
						   ApprovedAmount,
						   TotalChargeAmount,
						   TemporaryCreditCardStatusID,
						   ExceptionMessage,
						   Note,
						   CreateDate,
						   CreateBy,
						   ModifyDate,
						   ModifyBy
					FROM TemporaryCreditCard_Import S1 WHERE S1.RecordID = @startROWParent
				
				SET @newRecordID = SCOPE_IDENTITY()	
			
				UPDATE TemporaryCreditCard_Import SET TemporaryCreditCardID = @newRecordID
				WHERE RecordID = @startROWParent
			END
			END
		
		SET @startROWParent = @startROWParent + 1
	END
	
	-- Step 2 : Insert Records Into Temporary Credit Card Details
	SET @startROWParent =  (SELECT MIN(RecordID) FROM TemporaryCreditCard_Import 
												 WHERE ProcessIdentifier = @processGUID)
	
	SET @totalRowsParent = (SELECT MAX(RecordID) FROM TemporaryCreditCard_Import 
												 WHERE ProcessIdentifier = @processGUID)
												 
	WHILE(@startROWParent <= @totalRowsParent)  
	BEGIN
		SELECT  @creditCardIssueNumber = IMP.PurchaseID_CreditCardIssueNumber,
				@creditCardNumber = IMP.CPN_PAN_CreditCardNumber,
				@transactionSequence = IMP.HISTORY_ID_TransactionSequence,
				@purchaseType = IMP.PURCHASE_TYPE
		FROM TemporaryCreditCard_Import IMP
		WHERE RecordID = @startROWParent
		
		IF(@creditCardNumber IS NOT NULL AND @creditCardNumber != '' AND @purchaseType = 'ISP Claims')
		BEGIN
			IF(NOT EXISTS(SELECT tcc.ID, tccd.ID
					FROM TemporaryCreditCard tcc
					JOIN TemporaryCreditCardDetail tccd
						ON tcc.ID = tccd.TemporaryCreditCardID
					WHERE tcc.CreditCardIssueNumber = @creditCardIssueNumber
					AND tcc.CreditCardNumber = @creditCardNumber
					AND tccd.TransactionSequence = @transactionSequence
					))
					
		BEGIN
		SET @tempLookUpID = (SELECT tcc.ID FROM TemporaryCreditCard tcc
							   WHERE tcc.CreditCardIssueNumber = @creditCardIssueNumber
							   AND tcc.CreditCardNumber = @creditCardNumber)
							   
		INSERT INTO TemporaryCreditCardDetail(  TemporaryCreditCardID,
												TransactionSequence,
												TransactionDate,
												TransactionType,
												TransactionBy,
												RequestedAmount,
												ApprovedAmount,
												AvailableBalance,
												ChargeDate,
												ChargeAmount,
												ChargeDescription,
												CreateDate,
												CreateBy,
												ModifyDate,
												ModifyBy)
		SELECT @tempLookUpID, 
			   HISTORY_ID_TransactionSequence,
			   CREATE_DATE_IssueDate_TransactionDate,
			   ACTION_TYPE_TransactionType,
			   USER_NAME_IssueBy_TransactionBy,
			   REQUESTED_AMOUNT_RequestedAmount,
			   APPROVED_AMOUNT_ApprovedAmount,
			   AVAILABLE_BALANCE_AvailableBalance,
			   ChargeDate,
			   ChargeAmount,
			   ChargeDescription,
			   CreateDate,
			   CreateBy,
			   ModifyDate,
			   ModifyBy
		FROM TemporaryCreditCard_Import WHERE RecordID = @startROWParent
		
		SET @newRecordID = SCOPE_IDENTITY()
		UPDATE TemporaryCreditCard_Import SET TemporaryCreditCardDetailsID = @newRecordID
		WHERE RecordID = @startROWParent  
		
		END
		END
		
		SET @startROWParent = @startROWParent + 1
	END
	
	-- Step 3 Update Counts
	SET @TotalRecordCount = (SELECT COUNT(*) FROM TemporaryCreditCard_Import WHERE 
							 ProcessIdentifier = @processGUID)
	
	SET @TotalRecordsIgnored = (SELECT COUNT(*) FROM TemporaryCreditCard_Import
							   WHERE TemporaryCreditCardDetailsID IS NULL AND ProcessIdentifier = @processGUID
							   AND TemporaryCreditCardID IS NULL
							   ) 
							  
	
	SET @TotalCreditCardAdded = (SELECT COUNT(*) FROM TemporaryCreditCard_Import
							     WHERE TemporaryCreditCardID IS NOT NULL AND ProcessIdentifier = @processGUID)
							     
	SET @TotalTransactionAdded = (SELECT COUNT(*) FROM TemporaryCreditCard_Import
							     WHERE TemporaryCreditCardDetailsID IS NOT NULL AND ProcessIdentifier = @processGUID)
							   
	
	-- Step 4 Insert Counts
	INSERT INTO @Results(TotalRecordCount,
						 TotalRecordsIgnored,
						 TotalCreditCardAdded,
						 TotalTransactionAdded,
						 TotalErrorRecords)
	VALUES(@TotalRecordCount,@TotalRecordsIgnored,@TotalCreditCardAdded,@TotalTransactionAdded,
	@TotalErrorRecords)
	
	-- Step 5 Show Results
	SELECT * FROM @Results
END
	   




GO

GO

GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_CCImport_UpdateTempCreditCardDetails]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_CCImport_UpdateTempCreditCardDetails]
GO

--EXEC dms_CCImport_UpdateTempCreditCardDetails
CREATE PROC [dbo].[dms_CCImport_UpdateTempCreditCardDetails]
AS
BEGIN

BEGIN TRY
 

CREATE TABLE #TempCardsNotPosted (     
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
 ID int  NULL)

DECLARE @postedStatus INT
DECLARE @startROWParent INT 
DECLARE @totalRowsParent INT,
		@creditcardNumber INT,
		@totalApprovedAmount money,
		@totalChargedAmount money,
		@maxLastChargeDate datetime

SET @postedStatus = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name='Posted')

INSERT INTO #TempCardsNotPosted
SELECT DISTINCT TCCD.TemporaryCreditCardID FROM
TemporaryCreditCardDetail TCCD
JOIN TemporaryCreditCard TCC ON TCC.ID = TCCD.TemporaryCreditCardID
WHERE TCC.TemporaryCreditCardStatusID != @postedStatus

SET @startROWParent =  (SELECT MIN([RowNum]) FROM #TempCardsNotPosted)
SET @totalRowsParent = (SELECT MAX([RowNum]) FROM #TempCardsNotPosted)

WHILE(@startROWParent <= @totalRowsParent)  
BEGIN

SET @creditcardNumber = (SELECT ID FROM #TempCardsNotPosted WHERE [RowNum] = @startROWParent)
SET @maxLastChargeDate = (SELECT MAX(ChargeDate) FROM TemporaryCreditCardDetail WHERE TemporaryCreditCardID =  @creditcardNumber)

UPDATE TemporaryCreditCard
SET LastChargedDate = @maxLastChargeDate
WHERE ID =  @creditcardNumber

IF((SELECT Count(*) FROM TemporaryCreditCardDetail 
   WHERE TransactionType='Cancel' AND TemporaryCreditCardID = @creditcardNumber) > 0)
 BEGIN
	UPDATE TemporaryCreditCard 
	SET IssueStatus = 'Cancel'
	WHERE ID = @creditcardNumber
 END
 
 SET @totalApprovedAmount = (SELECT TOP 1 ApprovedAmount FROM TemporaryCreditCardDetail
							 WHERE TemporaryCreditCardID = @creditcardNumber AND TransactionType='Approve'
							 AND TransactionSequence IS NOT NULL
							 ORDER BY TransactionSequence DESC)
SET @totalChargedAmount = (SELECT SUM(ChargeAmount) FROM TemporaryCreditCardDetail
						   WHERE TemporaryCreditCardID = @creditcardNumber AND TransactionType='Charge')

UPDATE TemporaryCreditCard
SET ApprovedAmount = @totalApprovedAmount,
	TotalChargedAmount = @totalChargedAmount
WHERE ID = @creditcardNumber
						 
SET @startROWParent = @startROWParent + 1

END

DROP TABLE #TempCardsNotPosted



END TRY
BEGIN CATCH
		
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
	
END CATCH

END
GO

GO

GO
/*******************
* Operator Enums 
*  Conditions Enum :
* -1 - No filter
*  0 - Null
*  1 - Not Null
*  2 - Equals
*  3 - NotEquals
*  ---- for strings ---
*  4 - StartsWith
*  5 - EndsWith
*  6 - Contains
*  ---- for int, decimal, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Claims_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Claims_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dbo].[dms_Claims_List_Get]@sortColumn='AmountApproved' ,@endInd=50,@pageSize=50,@whereClauseXML='<ROW><Filter ClaimAmountFrom="0"/></ROW>',@sortOrder='DESC'
 CREATE PROCEDURE [dbo].[dms_Claims_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF;
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDType=""
IDValue=""
NameType=""
NameOperator=""
NameValue=""
ClaimTypes=""
ClaimStatuses=""
ClaimCategories=""
ClientID=""
ProgramID=""
ExportBatchID=""
 ></Filter></ROW>'
END

--CREATE TABLE #tmpForWhereClause
DECLARE @tmpForWhereClause TABLE
(
IDType			NVARCHAR(50) NULL,
IDValue			NVARCHAR(100) NULL,
NameType		NVARCHAR(50) NULL,
NameOperator	NVARCHAR(50) NULL,
NameValue		NVARCHAR(MAX) NULL,
ClaimTypes		NVARCHAR(MAX) NULL,
ClaimStatuses	NVARCHAR(MAX) NULL,
ClaimCategories	NVARCHAR(MAX) NULL,
ClientID		INT NULL,
ProgramID		INT NULL,
Preset			INT NULL,
ClaimDateFrom	DATETIME NULL,
ClaimDateTo		DATETIME NULL,
ClaimAmountFrom	MONEY NULL,
ClaimAmountTo	MONEY NULL,
CheckNumber		NVARCHAR(50) NULL,
CheckDateFrom	DATETIME NULL,
CheckDateTo		DATETIME NULL,
ExportBatchID	INT NULL,
ACESSubmitFromDate DATETIME NULL,
ACESSubmitToDate DATETIME NULL,
ACESClearedFromDate DATETIME NULL,
ACESClearedToDate DATETIME NULL,
ACESStatus NVARCHAR(MAX) NULL,
ReceivedFromDate DATETIME NULL,
ReceivedToDate DATETIME NULL
)
 CREATE TABLE #FinalResultsFiltered( 	
	ClaimID			INT  NULL ,
	ClaimType		NVARCHAR(100)  NULL ,
	ClaimDate		DATETIME  NULL ,
	AmountRequested MONEY  NULL ,
	Payeee			NVARCHAR(100)  NULL ,
	ClaimStatus		NVARCHAR(100)  NULL ,
	NextAction		NVARCHAR(100)  NULL ,
	AssignedTo		NVARCHAR(100)  NULL ,
	NextActionScheduledDate DATETIME  NULL ,
	ACESSubmitDate	DATETIME  NULL ,
	CheckNumber		NVARCHAR(100)  NULL ,
	PaymentDate		DATETIME  NULL ,
	PaymentAmount	MONEY  NULL,
	CheckClearedDate DATETIME NULL,
	AuthorizationCount	BIGINT NULL,
	InProcessCount	BIGINT NULL,
	CancelledCount	BIGINT NULL,
	ApprovedCount	BIGINT NULL,
	DeniedCount	BIGINT NULL,
	ReadyForPaymentCount BIGINT NULL,
	PaidCount		BIGINT NULL,
	ExceptionCount		BIGINT NULL,
	ClaimExceptionDetails NVARCHAR(MAX) NULL,
	MembershipNumber NVARCHAR(100) NULL,
	ProgramName NVARCHAR(100) NULL,
	BatchID INT NULL,
	AmountApproved MONEY  NULL ,
	ACESStatus nvarchar(100) NULL ,
	ACESClearedDate DATETIME NULL,
	ACESFeeAmount MONEY NULL
) 

CREATE TABLE #FinalResultsSorted( 
	[RowNum]		[BIGINT]	NOT NULL IDENTITY(1,1),
	ClaimID			INT  NULL ,
	ClaimType		NVARCHAR(100)  NULL ,
	ClaimDate		DATETIME  NULL ,
	AmountRequested MONEY  NULL ,
	Payeee			NVARCHAR(100)  NULL ,
	ClaimStatus		NVARCHAR(100)  NULL ,
	NextAction		NVARCHAR(100)  NULL ,
	AssignedTo		NVARCHAR(100)  NULL ,
	NextActionScheduledDate DATETIME  NULL ,
	ACESSubmitDate	DATETIME  NULL ,
	CheckNumber		NVARCHAR(100)  NULL ,
	PaymentDate		DATETIME  NULL ,
	PaymentAmount	MONEY  NULL,
	CheckClearedDate DATETIME NULL,
	AuthorizationCount	BIGINT NULL,
	InProcessCount	BIGINT NULL,
	CancelledCount	BIGINT NULL,
	ApprovedCount	BIGINT NULL,
	DeniedCount	BIGINT NULL,
	ReadyForPaymentCount BIGINT NULL,
	PaidCount		BIGINT NULL,
	ExceptionCount		BIGINT NULL ,
	ClaimExceptionDetails NVARCHAR(MAX)NULL,
	MembershipNumber NVARCHAR(100) NULL,
	ProgramName NVARCHAR(100) NULL,
	BatchID INT NULL,
	AmountApproved MONEY  NULL,
	ACESStatus nvarchar(100) NULL ,
	ACESClearedDate DATETIME NULL ,
	ACESFeeAmount MONEY NULL
) 

INSERT INTO @tmpForWhereClause
SELECT  
	T.c.value('@IDType','NVARCHAR(50)'),
	T.c.value('@IDValue','NVARCHAR(100)'),
	T.c.value('@NameType','NVARCHAR(50)'),
	T.c.value('@NameOperator','NVARCHAR(50)'),
	T.c.value('@NameValue','NVARCHAR(MAX)'),
	T.c.value('@ClaimTypes','NVARCHAR(MAX)'),
	T.c.value('@ClaimStatuses','NVARCHAR(MAX)'),
	T.c.value('@ClaimCategories','NVARCHAR(MAX)'),
	T.c.value('@ClientID','INT'),
	T.c.value('@ProgramID','INT'),
	T.c.value('@Preset','INT'),
	T.c.value('@ClaimDateFrom','DATETIME'),
	T.c.value('@ClaimDateTo','DATETIME'),
	T.c.value('@ClaimAmountFrom','MONEY'),
	T.c.value('@ClaimAmountTo','MONEY'),
	T.c.value('@CheckNumber','NVARCHAR(50)'),
	T.c.value('@CheckDateFrom','DATETIME'),
	T.c.value('@CheckDateTo','DATETIME'),
	T.c.value('@ExportBatchID','INT'),
	T.c.value('@ACESSubmitFromDate','DATETIME'),
	T.c.value('@ACESSubmitToDate','DATETIME'),
	T.c.value('@ACESClearedFromDate','DATETIME'),
	T.c.value('@ACESClearedToDate','DATETIME'),
	T.c.value('@ACESStatus','NVARCHAR(MAX)'),
	T.c.value('@ReceivedFromDate','DATETIME'),
	T.c.value('@ReceivedToDate','DATETIME')
	
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @IDType			NVARCHAR(50)= NULL,
@IDValue			NVARCHAR(100)= NULL,
@NameType		NVARCHAR(50)= NULL,
@NameOperator	NVARCHAR(50)= NULL,
@NameValue		NVARCHAR(MAX)= NULL,
@ClaimTypes		NVARCHAR(MAX)= NULL,
@ClaimStatuses	NVARCHAR(MAX)= NULL,
@ClaimCategories	NVARCHAR(MAX)= NULL,
@ClientID		INT= NULL,
@ProgramID		INT= NULL,
@preset			INT=NULL,
@ClaimDateFrom	DATETIME= NULL,
@ClaimDateTo		DATETIME= NULL,
@ClaimAmountFrom	MONEY= NULL,
@ClaimAmountTo	MONEY= NULL,
@CheckNumber		NVARCHAR(50)= NULL,
@CheckDateFrom	DATETIME= NULL,
@CheckDateTo		DATETIME= NULL,
@ExportBatchID	INT= NULL,
@ACESSubmitFromDate DATETIME= NULL,
@ACESSubmitToDate DATETIME= NULL,
@ACESClearedFromDate DATETIME= NULL,
@ACESClearedToDate DATETIME= NULL,
@ACESStatus NVARCHAR(MAX) = NULL,
@ReceivedFromDate DATETIME= NULL,
@ReceivedToDate DATETIME= NULL

SELECT 
		@IDType					= IDType				
		,@IDValue				= IDValue				
		,@NameType				= NameType			
		,@NameOperator			= NameOperator		
		,@NameValue				= NameValue			
		,@ClaimTypes			= ClaimTypes			
		,@ClaimStatuses			= ClaimStatuses		
		,@ClaimCategories		= ClaimCategories		
		,@ClientID				= ClientID			
		,@ProgramID				= ProgramID			
		,@preset				= Preset				
		,@ClaimDateFrom			= ClaimDateFrom		
		,@ClaimDateTo			= ClaimDateTo			
		,@ClaimAmountFrom		= ClaimAmountFrom		
		,@ClaimAmountTo			= ClaimAmountTo		
		,@CheckNumber			= CheckNumber			
		,@CheckDateFrom			= CheckDateFrom		
		,@CheckDateTo			= CheckDateTo			
		,@ExportBatchID			= ExportBatchID		
		,@ACESSubmitFromDate	= ACESSubmitFromDate	
		,@ACESSubmitToDate		= ACESSubmitToDate
		,@ACESClearedFromDate	= ACESClearedFromDate
		,@ACESClearedToDate		= ACESClearedToDate
		,@ACESStatus			= ACESStatus
		,@ReceivedFromDate      = ReceivedFromDate
        ,@ReceivedToDate        = ReceivedToDate
FROM	@tmpForWhereClause

--SELECT @preset
IF (@preset IS NOT NULL)
BEGIN
	DECLARE @fromDate DATETIME
	SET @fromDate = DATEADD(DD, DATEDIFF(DD,0, DATEADD(DD,-1 * @preset,GETDATE())),0)
	UPDATE @tmpForWhereClause 
	SET		ClaimDateFrom  = @fromDate,
			ClaimDateTo = DATEADD(DD,1,GETDATE())
		

END



--SELECT * FROM @tmpForWhereClause

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResultsFiltered
SELECT
		C.ID AS ClaimID
		, CT.Name AS ClaimType
		, C.ClaimDate
		, C.AmountRequested
		, CASE
                        WHEN ISNULL(C.PayeeType,'') = 'Member' THEN 'M-' + C.ContactName
                        WHEN ISNULL(C.PayeeType,'') = 'Vendor' THEN 'V-' + C.ContactName
                        ELSE C.ContactName
          END AS Payeee
		, CS.Name AS ClaimStatus
		, NA.Name AS NextAction
		, U.FirstName + ' ' + U.LastName AS AssignedTo
		, C.NextActionScheduledDate
		, C.ACESSubmitDate
		, C.CheckNumber
		, C.PaymentDate
		, C.PaymentAmount
		, C.CheckClearedDate
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, CE.[Description]
		, MS.MembershipNumber
		, P.Name
		, B.ID AS BatchID
		, C.AmountApproved
		, ACS.Name AS ACESClaimStatus
		, C.ACESClearedDate
		, C.ACESFeeAmount 
FROM	Claim C
JOIN	ClaimType CT WITH(NOLOCK) ON CT.ID = C.ClaimTypeID
LEFT JOIN ClaimStatus CS WITH(NOLOCK) ON CS.ID = C.ClaimStatusID 
LEFT JOIN ClaimException CE WITH(NOLOCK) ON CE.ClaimID = C.ID
LEFT JOIN NextAction NA WITH(NOLOCK) ON NA.ID = C.NextActionID
LEFT JOIN [User] U WITH(NOLOCK) ON U.ID = C.NextActionAssignedToUserID
LEFT JOIN Vendor V WITH (NOLOCK) ON C.VendorID = V.ID
LEFT JOIN Member M WITH (NOLOCK) ON C.MemberID = M.ID
LEFT JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
LEFT JOIN PurchaseOrder PO WITH (NOLOCK) ON C.PurchaseOrderID = PO.ID
LEFT JOIN Program P WITH (NOLOCK) ON P.ID = C.ProgramID
LEFT JOIN Batch B WITH(NOLOCK) ON B.ID=C.ExportBatchID
LEFT JOIN ACESClaimStatus ACS WITH(NOLOCK) ON ACS.ID=C.ACESClaimStatusID
WHERE C.IsActive = 1
AND		(ISNULL(LEN(@IDType),0) = 0 OR (	( @IDType = 'Claim' AND @IDValue	= CONVERT(NVARCHAR(100),C.ID))
											OR
											( @IDType = 'Vendor' AND @IDValue = V.VendorNumber)
											OR
											( @IDType = 'Member' AND @IDValue = MS.MembershipNumber)
										) )
AND		(ISNULL(LEN(@NameType),0) = 0 OR (	
											(@NameType = 'Member' AND (
																			-- TODO: Review the conditions against M.LastName. we might have to use first and last names.
																			(@NameOperator = 'Is equal to' AND @NameValue = M.LastName)
																			OR
																			(@NameOperator = 'Begins with' AND M.LastName LIKE  @NameValue + '%')
																			OR
																			(@NameOperator = 'Ends with' AND M.LastName LIKE  '%' + @NameValue)
																			OR
																			(@NameOperator = 'Contains' AND M.LastName LIKE  '%' + @NameValue + '%')

																		) )
												OR
											(@NameType = 'Vendor' AND (
																			(@NameOperator = 'Is equal to' AND @NameValue = V.Name)
																			OR
																			(@NameOperator = 'Begins with' AND V.Name LIKE  @NameValue + '%')
																			OR
																			(@NameOperator = 'Ends with' AND V.Name LIKE  '%' + @NameValue)
																			OR
																			(@NameOperator = 'Contains' AND V.Name LIKE  '%' + @NameValue + '%')

																		) )

											) )
AND		(ISNULL(LEN(@ClaimTypes),0) = 0  OR (C.ClaimTypeID IN ( SELECT item FROM [dbo].[fnSplitString](@ClaimTypes,',')) ) )
AND		(ISNULL(LEN(@ClaimStatuses),0) = 0  OR (C.ClaimStatusID IN ( SELECT item FROM [dbo].[fnSplitString](@ClaimStatuses,',')) ) )
AND		(ISNULL(LEN(@ClaimCategories),0) = 0  OR (C.ClaimCategoryID IN ( SELECT item FROM [dbo].[fnSplitString](@ClaimCategories,',')) ) )
AND		(ISNULL(@ClientID,0) = 0 OR @ClientID = 0 OR (P.ClientID = @ClientID  ) )
AND		(ISNULL(@ProgramID,0) = 0 OR @ProgramID = 0 OR (C.ProgramID = @ProgramID  ) )
AND		(C.ClaimDate IS NULL 
		OR
		C.ClaimDate IS NOT NULL
		AND		(@ClaimDateFrom IS NULL  OR ( C.ClaimDate >= @ClaimDateFrom ) )
		AND		(@ClaimDateTo IS NULL  OR ( C.ClaimDate < DATEADD(DD,1,@ClaimDateTo) ) )
		)
AND		(@ClaimAmountFrom IS NULL OR (ISNULL(C.AmountRequested,0) >= @ClaimAmountFrom))
AND		(@ClaimAmountTo IS NULL OR (ISNULL(C.AmountRequested,0) <= @ClaimAmountTo))
AND		(ISNULL(LEN(@CheckNumber),0) = 0 OR C.CheckNumber = @CheckNumber)
AND		(ISNULL(@ExportBatchID,0) = 0 OR @ExportBatchID = 0 OR (B.ID = @ExportBatchID  ) )
AND		(@CheckDateFrom IS NULL OR (C.CheckClearedDate >= @CheckDateFrom))
AND		(@CheckDateTo IS NULL OR (C.CheckClearedDate < DATEADD(DD,1,@CheckDateTo)))
AND		(@ACESSubmitFromDate IS NULL OR (C.ACESSubmitDate >= @ACESSubmitFromDate))
AND		(@ACESSubmitToDate IS NULL OR (C.ACESSubmitDate < DATEADD(DD,1,@ACESSubmitToDate)))	
AND		(@ACESClearedFromDate IS NULL OR (C.ACESClearedDate >= @ACESClearedFromDate))
AND		(@ACESClearedToDate IS NULL OR (C.ACESClearedDate < DATEADD(DD,1,@ACESClearedToDate)))		
AND		(@ACESStatus IS NULL OR (C.ACESClaimStatusID IN (SELECT item FROM [dbo].[fnSplitString](@ACESStatus,','))))
AND		(@ReceivedFromDate IS NULL OR (C.ReceivedDate >= @ReceivedFromDate))
AND		(@ReceivedToDate IS NULL OR (C.ReceivedDate < DATEADD(DD,1,@ReceivedToDate)))	


--FILTERING has to be taken care here
INSERT INTO #FinalResultsSorted
SELECT 
	T.ClaimID,
	T.ClaimType,
	T.ClaimDate,
	T.AmountRequested,
	T.Payeee,
	T.ClaimStatus,
	T.NextAction,
	T.AssignedTo,
	T.NextActionScheduledDate,
	T.ACESSubmitDate,
	T.CheckNumber,
	T.PaymentDate,
	T.PaymentAmount,
	T.CheckClearedDate,
	T.AuthorizationCount,
	T.InProcessCount,
	T.CancelledCount,
	T.ApprovedCount,
	T.DeniedCount,
	T.ReadyForPaymentCount,
	T.PaidCount,
	T.ExceptionCount,
   [dbo].[fnConcatenate](T.ClaimExceptionDetails) AS ClaimExceptionDetails,
    T.MembershipNumber,
    T.ProgramName,
    T.BatchID,
    T.AmountApproved,
    T.ACESStatus,
    T.ACESClearedDate,
	T.ACESFeeAmount 
FROM #FinalResultsFiltered T
GROUP BY 
	T.ClaimID,
	T.ClaimType,
	T.ClaimDate,
	T.AmountRequested,
	T.Payeee,
	T.ClaimStatus,
	T.NextAction,
	T.AssignedTo,
	T.NextActionScheduledDate,
	T.ACESSubmitDate,
	T.CheckNumber,
	T.PaymentDate,
	T.PaymentAmount,
	T.CheckClearedDate,
	T.AuthorizationCount,
	T.InProcessCount,
	T.CancelledCount,
	T.ApprovedCount,
	T.DeniedCount,
	T.ReadyForPaymentCount,
	T.PaidCount,
	T.ExceptionCount,
	T.MembershipNumber,
	T.ProgramName,
	T.BatchID,
	T.AmountApproved,
	T.ACESStatus,
	T.ACESClearedDate,
	T.ACESFeeAmount 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ClaimID' AND @sortOrder = 'ASC'
	 THEN T.ClaimID END ASC, 
	 CASE WHEN @sortColumn = 'ClaimID' AND @sortOrder = 'DESC'
	 THEN T.ClaimID END DESC ,

	 CASE WHEN @sortColumn = 'ClaimType' AND @sortOrder = 'ASC'
	 THEN T.ClaimType END ASC, 
	 CASE WHEN @sortColumn = 'ClaimType' AND @sortOrder = 'DESC'
	 THEN T.ClaimType END DESC ,

	 CASE WHEN @sortColumn = 'ClaimDate' AND @sortOrder = 'ASC'
	 THEN T.ClaimDate END ASC, 
	 CASE WHEN @sortColumn = 'ClaimDate' AND @sortOrder = 'DESC'
	 THEN T.ClaimDate END DESC ,

	 CASE WHEN @sortColumn = 'AmountRequested' AND @sortOrder = 'ASC'
	 THEN T.AmountRequested END ASC, 
	 CASE WHEN @sortColumn = 'AmountRequested' AND @sortOrder = 'DESC'
	 THEN T.AmountRequested END DESC ,

	 CASE WHEN @sortColumn = 'Payeee' AND @sortOrder = 'ASC'
	 THEN T.Payeee END ASC, 
	 CASE WHEN @sortColumn = 'Payeee' AND @sortOrder = 'DESC'
	 THEN T.Payeee END DESC ,

	 CASE WHEN @sortColumn = 'ClaimStatus' AND @sortOrder = 'ASC'
	 THEN T.ClaimStatus END ASC, 
	 CASE WHEN @sortColumn = 'ClaimStatus' AND @sortOrder = 'DESC'
	 THEN T.ClaimStatus END DESC ,

	 CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'ASC'
	 THEN T.NextAction END ASC, 
	 CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'DESC'
	 THEN T.NextAction END DESC ,

	 CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'ASC'
	 THEN T.AssignedTo END ASC, 
	 CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'DESC'
	 THEN T.AssignedTo END DESC ,

	 CASE WHEN @sortColumn = 'NextActionScheduledDate' AND @sortOrder = 'ASC'
	 THEN T.NextActionScheduledDate END ASC, 
	 CASE WHEN @sortColumn = 'NextActionScheduledDate' AND @sortOrder = 'DESC'
	 THEN T.NextActionScheduledDate END DESC ,

	 CASE WHEN @sortColumn = 'ACESSubmitDate' AND @sortOrder = 'ASC'
	 THEN T.ACESSubmitDate END ASC, 
	 CASE WHEN @sortColumn = 'ACESSubmitDate' AND @sortOrder = 'DESC'
	 THEN T.ACESSubmitDate END DESC ,

	 CASE WHEN @sortColumn = 'CheckNumber' AND @sortOrder = 'ASC'
	 THEN T.CheckNumber END ASC, 
	 CASE WHEN @sortColumn = 'CheckNumber' AND @sortOrder = 'DESC'
	 THEN T.CheckNumber END DESC ,

	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'ASC'
	 THEN T.PaymentDate END ASC, 
	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'DESC'
	 THEN T.PaymentDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'
	 THEN T.PaymentAmount END ASC, 
	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'
	 THEN T.PaymentAmount END DESC, 
	 
	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'ASC'
	 THEN T.CheckClearedDate END ASC, 
	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'DESC'
	 THEN T.CheckClearedDate END DESC,
	 
	 CASE WHEN @sortColumn = 'BatchID' AND @sortOrder = 'ASC'
	 THEN T.BatchID END ASC, 
	 CASE WHEN @sortColumn = 'BatchID' AND @sortOrder = 'DESC'
	 THEN T.BatchID END DESC,

	 CASE WHEN @sortColumn = 'AmountApproved' AND @sortOrder = 'ASC'
	 THEN T.AmountApproved END ASC, 
	 CASE WHEN @sortColumn = 'AmountApproved' AND @sortOrder = 'DESC'
	 THEN T.AmountApproved END DESC,

	 CASE WHEN @sortColumn = 'ACESStatus' AND @sortOrder = 'ASC'
	 THEN T.ACESStatus END ASC, 
	 CASE WHEN @sortColumn = 'ACESStatus' AND @sortOrder = 'DESC'
	 THEN T.ACESStatus END DESC,

	 CASE WHEN @sortColumn = 'ACESClearedDate' AND @sortOrder = 'ASC'
	 THEN T.ACESClearedDate END ASC, 
	 CASE WHEN @sortColumn = 'ACESClearedDate' AND @sortOrder = 'DESC'
	 THEN T.ACESClearedDate END DESC,

	 CASE WHEN @sortColumn = 'ACESFeeAmount' AND @sortOrder = 'ASC'
	 THEN T.ACESFeeAmount END ASC, 
	 CASE WHEN @sortColumn = 'ACESFeeAmount' AND @sortOrder = 'DESC'
	 THEN T.ACESFeeAmount END DESC


DECLARE @authorizationIssuedCount  BIGINT = 0,
		@inProcessCount BIGINT = 0,
		@cancelledCount BIGINT = 0,
		@approvedCount  BIGINT = 0,
		@deniedCount  BIGINT = 0,
		@readyForPaymentCount BIGINT = 0,
		@PaidCount BIGINT = 0,
		@exceptionCount BIGINT = 0


SELECT @authorizationIssuedCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'AuthorizationIssued'
SELECT @inProcessCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'In-Process'
SELECT @cancelledCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Cancelled'
SELECT @approvedCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Approved'
SELECT @deniedCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Denied'
SELECT @readyForPaymentCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'ReadyForPayment'
SELECT @PaidCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Paid'
SELECT @exceptionCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Exception'

-- DEBUG : SELECT * FROM #FinalResultsSorted WHERE ClaimStatus  ='Approved'

UPDATE #FinalResultsSorted
SET AuthorizationCount = @authorizationIssuedCount,
	InProcessCount = @inProcessCount,
	CancelledCount = @cancelledCount,
   	ApprovedCount = @approvedCount,
    DeniedCount = @deniedCount,
    ReadyForPaymentCount = @readyForPaymentCount,
    PaidCount = @PaidCount,
    ExceptionCount = @exceptionCount

DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM #FinalResultsSorted
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

SELECT @count AS TotalRows, * FROM #FinalResultsSorted WHERE RowNum BETWEEN @startInd AND @endInd

--DROP TABLE #tmpForWhereClause
DROP TABLE #FinalResultsFiltered
DROP TABLE #FinalResultsSorted

END

GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Claim_ApplyCashClaims_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Claim_ApplyCashClaims_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Claim_ApplyCashClaims_Get] 
CREATE PROCEDURE [dbo].[dms_Claim_ApplyCashClaims_Get]
AS  
BEGIN

-- Claim List
SELECT		CT.Name AS Type
			, C.ID AS ClaimNumber
			, C.ReceivedDate  
			, C.AmountRequested
			, CASE
                        WHEN ISNULL(C.PayeeType,'') = 'Member' THEN 'M-' + C.ContactName
                        WHEN ISNULL(C.PayeeType,'') = 'Vendor' THEN 'V-' + C.ContactName
                        ELSE C.ContactName
              END AS Payee
			, CS.Name AS Status
			, C.AmountApproved AS ApprovedAmount
			, C.ACESReferenceNumber
			, C.ACESSubmitDate
			, C.ACESOutcome
			, C.ACESAmount
			, CASE
				WHEN P.Name = 'Ford QFC' THEN 1
				ELSE 0
			  END AS QFCFlag
			,'' Applied 
			,CAST( 0 as bit) Selected
			, C.ACESFeeAmount
FROM		Claim C
JOIN		ClaimType CT ON CT.ID = C.ClaimTypeID
LEFT JOIN   ACESClaimStatus ACS ON ACS.ID = C.ACESClaimStatusID
JOIN		ClaimStatus CS ON CS.ID = C.ClaimStatusID
LEFT JOIN	Member M WITH(NOLOCK) ON M.ID = C.MemberID
LEFT JOIN	Program P WITH(NOLOCK) ON P.ID = M.ProgramID
LEFT JOIN	Vendor V WITH(NOLOCK) ON V.ID = C.VendorID
WHERE		CT.IsFordACES = 1
AND			CS.Name = 'Approved'
AND			ACS.Name = 'Approved'
AND			C.IsActive = 1
AND			ISNULL(C.ACESClearedDate,'') = ''
ORDER BY	QFCFlag DESC, C.ReceivedDate ASC

END
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Client_OpenPeriodProcess_EventLogs]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Client_OpenPeriodProcess_EventLogs] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 
CREATE PROC dms_Client_OpenPeriodProcess_EventLogs(@userName NVARCHAR(100),
												   @sessionID NVARCHAR(MAX),
												   @pageReference NVARCHAR(MAX),
												   @billingScheduleIDList NVARCHAR(MAX),
												   @billingDefinitionInvoiceIDList NVARCHAR(MAX))
AS
BEGIN
		
				DECLARE @BillingScheduleList AS TABLE(Serial INT IDENTITY(1,1), BillingScheduleID INT NULL)
				DECLARE @BillingDefinitionList AS TABLE(Serial INT IDENTITY(1,1),BillingDefinitionInvoiceID INT NULL)

				INSERT INTO @BillingScheduleList(BillingScheduleID)			   SELECT DISTINCT item from dbo.fnSplitString(@billingScheduleIDList,',')
				INSERT INTO @BillingDefinitionList(BillingDefinitionInvoiceID) SELECT item from dbo.fnSplitString(@billingDefinitionInvoiceIDList,',')
		
				DECLARE @eventLogID AS INT
				DECLARE @openBillingScheduleStatus AS INT
				DECLARE @scheduleID AS INT
				DECLARE @billingDefinitionID AS INT
				DECLARE @invoiceEntityID AS INT
				DECLARE @TotalRows AS INT
				DECLARE @ProcessingCounter AS INT = 1
				SELECT  @TotalRows = MAX(Serial) FROM @BillingScheduleList
				DECLARE @entityID AS INT 
				DECLARE @eventID AS INT
				SELECT  @entityID = ID FROM Entity WHERE Name = 'BillingSchedule'
				SELECT  @invoiceEntityID = ID FROM Entity WHERE Name = 'BillingInvoice'
				SELECT  @eventID =  ID FROM Event WHERE Name = 'OpenPeriod'
				SET @openBillingScheduleStatus = (SELECT ID From BillingScheduleStatus WHERE Name = 'OPEN')
		
				-- Create Event Logs for Billing Schedule ID List
				WHILE @ProcessingCounter <= @TotalRows
		BEGIN
			SET @scheduleID = (SELECT BillingScheduleID FROM @BillingScheduleList WHERE Serial = @ProcessingCounter)
			-- Create Event Logs Reocords
			INSERT INTO EventLog([EventID],				[SessionID],				[Source],			[Description],
								 [Data],				[NotificationQueueDate],	[CreateBy],			[CreateDate]) 
			VALUES				(@eventID,				@sessionID,					@pageReference,		 'Open Period - Billing Schedule ID = ' + CONVERT(NVARCHAR(50),@scheduleID),
								 NULL,					NULL,						@userName,			GETDATE())
			
			SET @eventLogID = SCOPE_IDENTITY()
			-- CREATE Link Records
			INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) VALUES(@eventLogID,@entityID,@scheduleID)
			

			-- CREATE LINK RECORDS FOR THE RECENTLY GENEREATED BillingInvoices.
			;WITH wGeneratedBillingInvoices
			AS
			(
				SELECT	ROW_NUMBER () OVER ( PARTITION BY BillingScheduleID, BillingDefinitionInvoiceID ORDER BY CreateDate DESC) AS RowNumber,
						ID AS BillingInvoiceID
				FROM	BillingInvoice BI WITH (NOLOCK)
				WHERE	BillingScheduleID = @scheduleID
			)

			INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) 
			SELECT	@eventLogID,@invoiceEntityID,W.BillingInvoiceID FROM wGeneratedBillingInvoices W WHERE W.RowNumber = 1


			UPDATE	BillingSchedule
			SET		ScheduleStatusID = @openBillingScheduleStatus
			WHERE	ID = @scheduleID


			SET @ProcessingCounter = @ProcessingCounter + 1
		END
END
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_client_update_billingeventedetail_status]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_client_update_billingeventedetail_status] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_client_update_billingeventedetail_status] @billingeventdetailIdXML = '<BillingInvoiceDetail><ID>1</ID><ID>2</ID></BillingInvoiceDetail>',@currentUser = 'demouser',@statusId=1,@eventId=70234
 CREATE PROCEDURE [dbo].[dms_client_update_billingeventedetail_status](
	@billingeventdetailIdXML XML,
	@currentUser NVARCHAR(50),
	@statusId int,
	@eventId int
	
 )
 AS
 BEGIN
 
    SET FMTONLY OFF
	SET NOCOUNT ON
	
	DECLARE @now DATETIME = GETDATE()
	
	
	DECLARE @entityId INT
	SET @entityId = (SELECT ID FROM Entity WHERE Name='BillingInvoiceDetail')
	
	CREATE TABLE #SelectedBillingInvoiceDetailStatus
	(	
		ID INT IDENTITY(1,1),
		BillingInvoiceDetailId INT
	)
	
	INSERT INTO #SelectedBillingInvoiceDetailStatus
	SELECT tcc.ID
	FROM BillingInvoiceDetail tcc WITH (NOLOCK)
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @billingeventdetailIdXML.nodes('/BillingInvoiceDetail/ID') T(c)
			) T ON tcc.ID = T.ID

	CREATE CLUSTERED INDEX IDX_SelectedBillingInvoiceDetailStatus ON #SelectedBillingInvoiceDetailStatus(BillingInvoiceDetailId)
	
	--Insert log records
	INSERT INTO EventLogLink
	SELECT @eventId,
	       @entityId,
	       BillingInvoiceDetailId
	FROM #SelectedBillingInvoiceDetailStatus
	
	--Update BillingInvoiceDetail
	UPDATE BillingInvoiceDetail
	SET InvoiceDetailStatusID = @statusId,
	    ModifyBy = @currentUser,
	    ModifyDate = @now
	WHERE ID IN(SELECT BillingInvoiceDetailId FROM #SelectedBillingInvoiceDetailStatus)
	
	DROP TABLE #SelectedBillingInvoiceDetailStatus
	
 END
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_client_update_billinginvoicedetail_disposition]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_client_update_billinginvoicedetail_disposition] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_client_update_billinginvoicedetail_disposition] @billingeventdetailIdXML = '<BillingInvoiceDetail><ID>1</ID><ID>2</ID></BillingInvoiceDetail>',@currentUser = 'demouser',@statusId=1,@eventId=70234
 CREATE PROCEDURE [dbo].[dms_client_update_billinginvoicedetail_disposition](
	@billingeventdetailIdXML XML,
	@currentUser NVARCHAR(50),
	@statusId int,
	@eventId int
	
 )
 AS
 BEGIN
 
    SET FMTONLY OFF
	SET NOCOUNT ON
	
	DECLARE @now DATETIME = GETDATE()
	
	
	DECLARE @entityId INT
	SET @entityId = (SELECT ID FROM Entity WHERE Name='BillingInvoiceDetail')
	
	CREATE TABLE #SelectedBillingInvoiceDetail
	(	
		ID INT IDENTITY(1,1),
		BillingInvoiceDetailId INT
	)
	
	INSERT INTO #SelectedBillingInvoiceDetail
	SELECT tcc.ID
	FROM BillingInvoiceDetail tcc WITH (NOLOCK)
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @billingeventdetailIdXML.nodes('/BillingInvoiceDetail/ID') T(c)
			) T ON tcc.ID = T.ID

	CREATE CLUSTERED INDEX IDX_SelectedBillingInvoiceDetail ON #SelectedBillingInvoiceDetail(BillingInvoiceDetailId)
	
	--Insert log records
	INSERT INTO EventLogLink
	SELECT @eventId,
	       @entityId,
	       BillingInvoiceDetailId
	FROM #SelectedBillingInvoiceDetail
	
	--Update BillingInvoiceDetail
	UPDATE BillingInvoiceDetail
	SET InvoiceDetailDispositionID = @statusId,
	    ModifyBy = @currentUser,
	    ModifyDate = @now
	WHERE ID IN(SELECT BillingInvoiceDetailId FROM #SelectedBillingInvoiceDetail)
	
	DROP TABLE #SelectedBillingInvoiceDetail
	
 END
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Communication_Fax_Update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Communication_Fax_Update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dbo].[dms_Communication_Fax_Update] 'kbanda'
 CREATE PROCEDURE [dbo].[dms_Communication_Fax_Update](@userName NVARCHAR(50) = NULL)
 AS
 BEGIN
 
DECLARE @tmpRecordstoUpdate TABLE
(
CommunicationLogID INT NOT NULL,
ContactLogID INT NOT NULL,
[Status] nvarchar(255) NULL,
FaxResult nvarchar(2000) NULL,
FaxInfo nvarchar(2000)NULL,
sRank INT NOT NULL,
CommunicationLogCreateBy NVARCHAR(100) NULL
)
 
	
    -- To Update the Records in Batch
	--WITH wResult AS(
	INSERT INTO @tmpRecordstoUpdate
	SELECT	CL.ID,
			CL.ContactLogID,
			CL.[Status],
			FR.[result] AS FaxResult,
			FR.[info] AS FaxInfo,
			ROW_NUMBER() OVER(PARTITION BY FR.Billing_Code ORDER BY FR.[Date] DESC) AS 'SRank',
			CL.CreateBy
			FROM CommunicationLog CL
			 INNER JOIN FaxResult FR ON
			 FR.[billing_code] <> '' AND 
			 FR.[billing_code] = CL.ID
			 WHERE ContactMethodID = (SELECT ID FROM ContactMethod WHERE Name = 'Fax')
			 AND [Status] = 'PENDING'

	UPDATE CommunicationLog 
	SET [Status] = T.FaxResult,
		Comments = T.FaxInfo,
		ModifyDate = getdate(),
		ModifyBy = @username 
	FROM CommunicationLog 
	JOIN @tmpRecordstoUpdate T on T.CommunicationLogID = CommunicationLog.ID
	WHERE T.sRank = 1
				 
	--UPDATE wResult SET wResult.[Status] = wResult.FaxResult,
	--				   wResult.Comments = wResult.[FaxInfo],
	--				   wResult.ModifyDate = getdate(),
	--				   wResult.ModifyBy = @userName 
	--				   WHERE SRank = 1
					   
	-- Create New Records in Batch if Contact Log ID is not NULL				   
	--;WITH wResultInsert AS(
	--SELECT CL.*,FR.[result] AS FaxResult,FR.[info] AS FaxInfo FROM CommunicationLog CL
	--		 INNER JOIN FaxResult FR ON
	--		 FR.[billing_code] = CL.ID
	--		 WHERE ContactMethodID = (SELECT ID FROM ContactMethod WHERE Name = 'Fax')
	--		 AND
	--		 [Status] IN ('SUCCESS','FAILURE')
	--		 AND ContactLogID IS NOT NULL)
	INSERT INTO ContactLogAction(ContactActionID,ContactLogID,Comments,CreateDate,CreateBy)
		   SELECT DISTINCT
		     Case FaxResult 
				WHEN 'SUCCESS' THEN (SELECT ID FROM ContactAction WHERE Name = 'Sent')
				ELSE (SELECT ID FROM ContactAction WHERE Name = 'SendFailure')
			END as ContactActionID,
		   [ContactLogID],FaxInfo,GETDATE(),@userName
		   FROM @tmpRecordstoUpdate
		   WHERE sRank = 1

	-- KB: Notifications
	-- For every communicationlog record whose status was set to FAIL, create eventlog records with event
	DECLARE @eventIDForSendPOFaxFailed INT,
			@eventDescriptionForSendPOFaxFailed NVARCHAR(255),
			@poEntityID INT,
			@contactLogActionEntityID INT,
			@idx INT = 1,
			@maxRows INT,
			@eventLogID INT,
			@sendFailureContactActionID INT

	SELECT	@eventIDForSendPOFaxFailed = ID, @eventDescriptionForSendPOFaxFailed = [Description] FROM [Event] WITH (NOLOCK) WHERE Name = 'SendPOFaxFailed'
	SELECT	@poEntityID = ID FROM Entity WHERE Name = 'PurchaseOrder'
	SELECT	@contactLogActionEntityID = ID FROM Entity WHERE Name = 'ContactLogAction'
	SELECT	@sendFailureContactActionID = ID FROM ContactAction WHERE Name = 'SendFailure'

	CREATE TABLE #tmpCommunicationLogFaxFailed
	(
		RowNum INT IDENTITY(1,1) NOT NULL,
		CommunicationLogID INT NOT NULL,
		ContactLogID INT NOT NULL,
		PurchaseOrderID INT NULL,
		PurchaseOrderNumber NVARCHAR(50) NULL,
		ServiceRequestNumber INT NULL,
		FailureReason NVARCHAR(MAX) NULL,
		CommunicationLogCreateBy NVARCHAR(100) NULL
	)

	INSERT INTO #tmpCommunicationLogFaxFailed 
	SELECT	T.CommunicationLogID,
			T.ContactLogID,
			CLL.RecordID,
			PO.PurchaseOrderNumber,
			PO.ServiceRequestID,
			T.FaxInfo,
			T.CommunicationLogCreateBy
	FROM	@tmpRecordstoUpdate T
	LEFT JOIN	ContactLogLink CLL ON T.ContactLogID = CLL.ContactLogID AND CLL.EntityID = @poEntityID
	LEFT JOIN	PurchaseOrder PO ON PO.ID = CLL.RecordID
	WHERE	T.FaxResult = 'FAILURE'
	AND		T.sRank = 1

	SELECT @maxRows = MAX(RowNum) FROM #tmpCommunicationLogFaxFailed


	--DEBUG: SELECT * FROM #tmpCommunicationLogFaxFailed

	DECLARE @purchaseOrderID INT,
			@serviceRequestID INT,
			@purchaseOrderNumber NVARCHAR(50),
			@contactLogID INT,
			@failureReason NVARCHAR(MAX),
			@commLogCreateBy NVARCHAR(100)

	WHILE ( @idx <= @maxRows )
	BEGIN
		
		SELECT	@contactLogID		= T.ContactLogID,
				@failureReason		= T.FailureReason,
				@purchaseOrderID	= T.PurchaseOrderID,
				@purchaseOrderNumber = T.PurchaseOrderNumber,
				@serviceRequestID	= T.ServiceRequestNumber,
				@commLogCreateBy	= T.CommunicationLogCreateBy
		FROM	#tmpCommunicationLogFaxFailed T WHERE T.RowNum = @idx

		-- For each communication log record related to fax failure, log an event and create link records - one per 
		INSERT INTO EventLog (	EventID,
								Source,
								Description,
								Data,
								NotificationQueueDate,
								CreateDate,
								CreateBy)
		SELECT	@eventIDForSendPOFaxFailed,
				'Communication Service',
				@eventDescriptionForSendPOFaxFailed,
				'<MessageData><PONumber>' + @purchaseOrderNumber + 
							'</PONumber><ServiceRequest>' + CONVERT(NVARCHAR(50),@serviceRequestID) + 
							'</ServiceRequest><FaxFailureReason>' + @failureReason + 
							'</FaxFailureReason><CreateByUser>' +  @commLogCreateBy +
							'</CreateByUser></MessageData>',
				NULL,
				GETDATE(),
				'system'
		

		SET @eventLogID = SCOPE_IDENTITY()

		--DEBUG: SELECT @eventLogID AS EventLogID

		INSERT INTO EventLogLink ( EventLogID, EntityID, RecordID)
		SELECT	@eventLogID,
				@poEntityID,
				@purchaseOrderID

		;WITH wContactLogActions
		AS
		(
			SELECT	ROW_NUMBER() OVER ( PARTITION BY CLA.ContactActionID ORDER BY CLA.CreateDate DESC) As RowNum,
					CLA.ID As ContactLogActionID,
					CLA.ContactLogID
			FROM	ContactLogAction CLA 			
			WHERE	CLA.ContactLogID = @contactLogID
			AND		CLA.ContactActionID = @sendFailureContactActionID
		)

		INSERT INTO EventLogLink ( EventLogID, EntityID, RecordID)
		SELECT	@eventLogID,
				@contactLogActionEntityID,
				W.ContactLogActionID
		FROM	wContactLogActions W 
		WHERE	W.RowNum = 1


		SET @idx = @idx + 1
	END



	DROP TABLE #tmpCommunicationLogFaxFailed
END



GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_CurrentUser_For_Event_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_CurrentUser_For_Event_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_CurrentUser_For_Event_Get] 'kbanda'
CREATE PROCEDURE [dbo].[dms_CurrentUser_For_Event_Get](
	@eventLogID INT,
	@eventSubscriptionID INT
)
AS
BEGIN
 
	/*
		Assumption : This stored procedure would be executed for DesktopNotifications.
		Logic : 
		If the event is SendPOFaxFailure - Determine the current user as follows:
			1.	Parse EL.Data and pull out <ServiceRequest><SR.ID>  </ServiceRequest>
			2.	Join to Case from that SR.ID and get Case.AssignedToUserID
			3.	Insert one CommunicatinQueue record
			4.	If this value is blank try next one
			iv.	If no current user assigned
			1.	Parse EL.Data and pull out <CreateByUser><username></CreateByUser>
			2.	Check to see if that <username> is online
			3.	If online then Insert one CommunicatinQueue record for that user
			v.	If still no user found or online, then check the Service Request and if the NextAction fields are blank.  If blank then:
			1.	Update the associated ServiceRequest next action fields.  These will be displayed on the Queue prompting someone to take action and re-send the PO
			a.	Set ServiceRequest.NextActionID = Re-send PO
			b.	Set ServiceRequest.NextActionAssignedToUserID = ‘Agent User’

		If the event is ManualNotification, determine the curren user(s) as follows: 
			1. Get the associated EventLogLinkRecords.
			2. For each of the link records:
				2.1 If the related entity on the link record is a user and the user is online, add the user details to the list.
				
		If the event is not SendPOFaxFailure - CurrentUser = ServiceRequest.Case.AssignedToUserID.
	*/

	DECLARE @eventName NVARCHAR(255),
			@eventData XML,
			@PONumber NVARCHAR(100),
			@ServiceRequest INT,
			@FaxFailureReason NVARCHAR(MAX),
			@CreateByUser NVARCHAR(50),

			@assignedToUserIDOnCase INT,
			@nextActionIDOnSR INT,
			@nextActionAssignedToOnSR INT,
			@resendPONextActionID INT,
			@agentUserID INT

	DECLARE @tmpCurrentUser TABLE
			(
				UserId UNIQUEIDENTIFIER NULL,
				UserName NVARCHAR(100) NULL
			)
	
	SELECT  @resendPONextActionID = ID FROM NextAction WITH (NOLOCK) WHERE Name = 'ResendPO'
	
	SELECT	@agentUserID = U.ID
	FROM	[User] U WITH (NOLOCK) 
	JOIN	aspnet_Users AU WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
	JOIN	aspnet_Applications A WITH (NOLOCK) ON A.ApplicationId = AU.ApplicationId
	WHERE	AU.UserName = 'Agent'
	AND		A.ApplicationName = 'DMS'

	SELECT	@eventData = EL.Data
	FROM	EventLog EL WITH (NOLOCK)
	JOIN	Event E WITH (NOLOCK) ON EL.EventID = E.ID
	WHERE	EL.ID = @eventLogID

	SELECT	@eventName = E.Name
	FROM	EventSubscription ES WITH (NOLOCK) 
	JOIN	Event E WITH (NOLOCK) ON ES.EventID = E.ID
	WHERE	ES.ID = @eventSubscriptionID
	

	SELECT	@PONumber = (SELECT  T.c.value('.','NVARCHAR(100)') FROM @eventData.nodes('/MessageData/PONumber') T(c)),
			@ServiceRequest = (SELECT  T.c.value('.','INT') FROM @eventData.nodes('/MessageData/ServiceRequest') T(c)),
			@FaxFailureReason = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventData.nodes('/MessageData/FaxFailureReason') T(c)),
			@CreateByUser = (SELECT  T.c.value('.','NVARCHAR(50)') FROM @eventData.nodes('/MessageData/CreateByUser') T(c))
		
	SELECT	@assignedToUserIDOnCase = C.AssignedToUserID
		FROM	[Case] C WITH (NOLOCK)
		JOIN	[ServiceRequest] SR WITH (NOLOCK) ON SR.CaseID = C.ID
		WHERE	SR.ID = @ServiceRequest

	IF (@eventName = 'SendPOFaxFailed')
	BEGIN	
				
		IF (@assignedToUserIDOnCase IS NOT NULL)
		BEGIN
			-- Return the user details.
			INSERT INTO @tmpCurrentUser ( UserId, UserName)
			SELECT	AU.UserId,
					AU.UserName
			FROM	aspnet_Users AU WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
			WHERE	U.ID = @assignedToUserIDOnCase

		END
		ELSE 
		BEGIN
			
			IF ( (SELECT [dbo].[fnIsUserConnected](@CreateByUser) ) = 1)
			BEGIN
				
				INSERT INTO @tmpCurrentUser
				SELECT	AU.UserId,
						AU.UserName
				FROM	aspnet_Users AU WITH (NOLOCK) 
				JOIN	aspnet_Applications A WITH (NOLOCK) ON AU.ApplicationId = A.ApplicationId			
				WHERE	AU.UserName = @CreateByUser
				AND		A.ApplicationName = 'DMS'
				
			END
			ELSE
			BEGIN

				SELECT	@nextActionIDOnSR = SR.NextActionID,
						@nextActionAssignedToOnSR = SR.NextActionAssignedToUserID
				FROM	ServiceRequest SR WITH (NOLOCK) 
				WHERE ID = @ServiceRequest 

				IF @nextActionAssignedToOnSR IS NULL AND @nextActionIDOnSR IS NULL
				BEGIN
					
					UPDATE	ServiceRequest
					SET		NextActionID = @resendPONextActionID,
							NextActionAssignedToUserID = @agentUserID
					WHERE	ID = @ServiceRequest

				END
			END				
		END	
	END
	
	ELSE IF (@eventName = 'ManualNotification' OR @eventName = 'LockedRequestComment')
	BEGIN
		
		DECLARE @userEntityID INT

		SET @userEntityID = (SELECT ID FROM Entity WHERE Name = 'User')
		;WITH wUsersFromEventLogLinks
		AS
		(
			SELECT	AU.UserId,
					AU.UserName,
					[dbo].[fnIsUserConnected](AU.UserName) IsConnected				
			FROM	EventLogLink ELL WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON ELL.RecordID = U.ID AND ELL.EntityID = @userEntityID
			JOIN	aspnet_Users AU WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
			WHERE	ELL.EventLogID = @eventLogID
		)

		INSERT INTO @tmpCurrentUser (UserId, UserName)
		SELECT	W.UserId, W.UserName
		FROM	wUsersFromEventLogLinks W
		WHERE	ISNULL(W.IsConnected,0) = 1


	END	
	ELSE
	BEGIN
		
		IF (@assignedToUserIDOnCase IS NOT NULL)
		BEGIN

			INSERT INTO @tmpCurrentUser ( UserId, UserName)
			SELECT	AU.UserId,
					AU.Username
			FROM	aspnet_Users AU WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON AU.UserId = U.aspnet_UserID
			JOIN	[aspnet_Applications] A WITH (NOLOCK) ON A.ApplicationId = AU.ApplicationId
			WHERE	A.ApplicationName = 'DMS'
			AND		U.ID = @assignedToUserIDOnCase

		END
			
	END	


	SELECT UserId, Username from @tmpCurrentUser

END

GO


GO

GO

GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Get_Member_Information]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Get_Member_Information]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- exec dms_Get_Member_Information 541
CREATE PROC [dbo].[dms_Get_Member_Information](@memberID INT = NULL)
AS
BEGIN
	-- KB: Get membership ID of the current member.
	DECLARE @membershipID INT
	SELECT @membershipID = MembershipID FROM Member WHERE ID = @memberID

	DECLARE @memberEntityID INT
	SELECT @memberEntityID = ID FROM Entity WHERE Name = 'Member'

	--KB: Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'

	SET FMTONLY OFF;
	
	;WITH wResults
	AS
	(
	SELECT DISTINCT MS.ID AS MembershipID,
	MS.MembershipNumber,
	CASE MS.IsActive WHEN 1 THEN 'Active' ELSE 'Inactive' END AS MembershipStatus, -- KB: I don't think we are using this.
	P.[Description] AS Program,
	P.ID AS ProgramID,
	AD.Line1 AS Line1,
	PH.PhoneNumber AS HomePhoneNumber, 
	PW.PhoneNumber AS WorkPhoneNumber, 
	PC.PhoneNumber AS CellPhoneNumber,
	ISNULL(AD.City,'') + ' ' + ISNULL(AD.StateProvince,'') + ' ' +  ISNULL(AD.PostalCode,'') AS CityStateZip,
	CN.Name AS 'CountryName',
	M.Email,
	M.ID AS MemberID,
	CASE M.IsPrimary WHEN 1 THEN '*' ELSE '' END AS MasterMember,
	--ISNULL(M.FirstName,'') + ' ' + ISNULL(M.LastName,'') + ' ' + ISNULL(M.Suffix,'') AS MemberName,
	REPLACE(RTRIM( 
	COALESCE(M.FirstName, '') + 
	COALESCE(' ' + left(M.MiddleName,1), '') + 
	COALESCE(' ' + M.LastName, '') +
	COALESCE(' ' + M.Suffix, '')
	), ' ', ' ') AS MemberName,	
	-- KB: Considering Effective and Expiration Dates to calculate member status
	CASE WHEN ISNULL(m.EffectiveDate,@minDate) <= @now AND ISNULL(m.ExpirationDate,@minDate) >= @now
				THEN 'Active'
				ELSE 'Inactive'
	END AS MemberStatus,
	M.ExpirationDate,
	M.EffectiveDate,
	C.ID AS ClientID,
	C.Name AS ClientName,
	MS.Note AS MembershipNote	  
	FROM Member M
	LEFT JOIN Membership MS ON MS.ID = M.MembershipID
	LEFT JOIN Program P ON M.ProgramID = P.ID
	LEFT JOIN Client C ON P.ClientID = C.ID
	LEFT JOIN PhoneEntity PH ON PH.RecordID = M.ID AND PH.PhoneTypeID = 1 AND PH.EntityID = @memberEntityID 
	LEFT JOIN PhoneEntity PW ON PW.RecordID = M.ID AND PW.PhoneTypeID = 2 AND PW.EntityID = @memberEntityID 
	LEFT JOIN PhoneEntity PC ON PC.RecordID = M.ID AND PC.PhoneTypeID = 3 AND PC.EntityID = @memberEntityID 
	LEFT JOIN AddressEntity AD ON AD.RecordID = M.ID AND AD.EntityID = @memberEntityID
	LEFT JOIN Country CN ON CN.ISOCode = AD.CountryCode
	WHERE MS.ID =  @membershipID -- KB: Performing the check against the right attribute.
	)
	SELECT * FROM wResults M ORDER BY MasterMember DESC,MemberName

END


GO

GO

GO

 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_GoToPODetails_row]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_GoToPODetails_row] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_GoToPODetails_row] 1414, 100,100,100,null,null,25   
--32.780122,-96.801412,'TX','US',32.864132,-96.942948,
 CREATE PROCEDURE [dbo].[dms_GoToPODetails_row](
-- @ServiceLocationLatitude decimal(10,7)
-- ,@ServiceLocationLongitude decimal(10,7)
--,@ServiceLocationStateProvince varchar(20)
--,@ServiceLocationCountryCode varchar(20)
--,@DestinationLocationLatitude  decimal(10,7)
--,@DestinationLocationLongitude  decimal(10,7)
@ServiceRequestID int 
	,@EnrouteMiles decimal(18,4) 
	,@ReturnMiles  decimal(18,4) 
	,@EstimatedHours decimal(18,4) 
	,@ProductID int 
	,@VendorLocationID int 
	,@VendorID int = NULL
) 
AS 
BEGIN

	SET FMTONLY OFF;
 	SET NOCOUNT ON;
 	
	DECLARE @ServiceLocationLatitude decimal(10,7)
		,@ServiceLocationLongitude decimal(10,7)
		,@ServiceLocationStateProvince varchar(20)
		,@ServiceLocationCountryCode varchar(20)
		,@DestinationLocationLatitude  decimal(10,7)
		,@DestinationLocationLongitude  decimal(10,7)
		,@ServiceMiles decimal(10,2)
		,@PrimaryCoverageLimitMileage int

	DECLARE @ServiceLocation as geography  

	SELECT 
		@ServiceLocationLatitude =ServiceLocationLatitude
		,@ServiceLocationLongitude=ServiceLocationLongitude
		,@ServiceLocationStateProvince=ServiceLocationStateProvince
		,@ServiceLocationCountryCode=ServiceLocationCountryCode
		,@DestinationLocationLatitude=DestinationLatitude
		,@DestinationLocationLongitude=DestinationLongitude
		,@ServiceMiles= ISNULL(ServiceMiles,0)
		,@PrimaryCoverageLimitMileage = ISNULL(PrimaryCoverageLimitMileage,0)
		FROM ServiceRequest Where 
		ID=@ServiceRequestID

	-- KB: Take the product from service request, if the param is null.
	IF (@ProductID IS NULL)
	BEGIN
	SELECT @ProductID = PrimaryProductID FROM ServiceRequest Where ID=@ServiceRequestID 
	END
	--PR: Take the VendorID From VendorLocation
	IF(@VendorID IS NULL)
	BEGIN
	SELECT @VendorID= VendorID from VendorLocation where ID=@VendorLocationID
	END

	SET @ServiceLocation = geography::Point(ISNULL(@ServiceLocationLatitude,0), ISNULL(@ServiceLocationLongitude,0), 4326)  
      
	SELECT 
		  @VendorLocationID AS VendorLocationID
		  ,RateDetail.ProductID
		  ,RateDetail.ProductName
		  ,RateDetail.RateTypeID
		  ,RateTypeName
		  ,RateDetail.Sequence
		  ,RateDetail.ContractedRate
		  ,RateDetail.RatePrice
		  ,RateDetail.RateQuantity
		  ,RateDetail.UnitOfMeasure
		  ,RateDetail.UnitOfMeasureSource
		  ,CASE 
				WHEN RateDetail.UnitOfMeasure = 'Each' THEN 1 
				WHEN RateDetail.UnitOfMeasure = 'Hour' THEN @EstimatedHours
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and RateDetail.RateQuantity = 0 THEN @EnrouteMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity = 0 and ISNULL(@PrimaryCoverageLimitMileage,0) > 0 and @ServiceMiles > ISNULL(@PrimaryCoverageLimitMileage,0) THEN ISNULL(@PrimaryCoverageLimitMileage,0)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity = 0 THEN @ServiceMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and RateDetail.RateQuantity <> 0 THEN (CASE WHEN RateDetail.RateQuantity > @EnrouteMiles THEN @EnrouteMiles ELSE RateDetail.RateQuantity END)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity <> 0 THEN (CASE WHEN RateDetail.RateQuantity > @ServiceMiles THEN @ServiceMiles ELSE RateDetail.RateQuantity END)
		  ELSE 0 END Quantity
	,ROUND(CASE 
		  WHEN RateDetail.UnitOfMeasure = 'Each' THEN RateDetail.RatePrice 
	WHEN RateDetail.UnitOfMeasure = 'Hour' THEN RateDetail.RatePrice * @EstimatedHours
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and RateDetail.RateQuantity = 0 THEN RateDetail.RatePrice * @EnrouteMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity = 0 and ISNULL(@PrimaryCoverageLimitMileage,0) > 0 and @ServiceMiles > ISNULL(@PrimaryCoverageLimitMileage,0)  THEN RateDetail.RatePrice * ISNULL(@PrimaryCoverageLimitMileage,0)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity = 0 THEN RateDetail.RatePrice * @ServiceMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and RateDetail.RateQuantity <> 0 THEN RateDetail.RatePrice * (CASE WHEN RateDetail.RateQuantity > @EnrouteMiles THEN @EnrouteMiles ELSE RateDetail.RateQuantity END)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and RateDetail.RateQuantity <> 0 THEN RateDetail.RatePrice * (CASE WHEN RateDetail.RateQuantity > @ServiceMiles THEN @ServiceMiles ELSE RateDetail.RateQuantity END)
		  ELSE 0 END,2) ExtendedAmount
	,0 IsMemberPay
	INTO #PODetail
	FROM
		  (
		  Select 
				p.ID ProductID
				,p.Name ProductName
				,prt.RateTypeID 
				,rt.Name RateTypeName
				,prt.Sequence
				,CASE WHEN VendorLocationRate.Price IS NOT NULL THEN VendorLocationRate.Price
						  WHEN VendorDefaultRate.Price IS NOT NULL THEN VendorDefaultRate.Price
						  ELSE 0 END AS ContractedRate
				,CASE WHEN VendorLocationRate.Price IS NOT NULL THEN VendorLocationRate.Price
						  WHEN VendorDefaultRate.Price IS NOT NULL THEN VendorDefaultRate.Price
						  ELSE 0 END AS RatePrice
				,CASE WHEN VendorLocationRate.Price IS NOT NULL THEN VendorLocationRate.Quantity
						  WHEN VendorDefaultRate.Price IS NOT NULL THEN VendorDefaultRate.Quantity
						  ELSE 0 END AS RateQuantity
				,rt.UnitOfMeasure 
				,rt.UnitOfMeasureSource 
		  From dbo.Product p 
		  Join dbo.ProductRateType prt 
				On prt.ProductID = p.ID
		  Left Outer Join dbo.RateType rt 
				On prt.RateTypeID = rt.ID
		  LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() VendorLocationRate 
				ON VendorLocationRate.VendorID = @VendorID AND 
				p.ID = VendorLocationRate.ProductID AND 
				prt.RateTypeID = VendorLocationRate.RateTypeID AND
				VendorLocationRate.VendorLocationID = @VendorLocationID 
		  LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() VendorDefaultRate
				ON VendorDefaultRate.VendorID = @VendorID AND 
				p.ID = VendorDefaultRate.ProductID AND 
				prt.RateTypeID = VendorDefaultRate.RateTypeID AND
				VendorDefaultRate.VendorLocationID IS NULL
		  WHERE p.id = @ProductID
				and prt.IsOptional = 0
		  ) RateDetail

	--TP: Added logic to inject additional Member Pay line item for over program towing limit
	IF @PrimaryCoverageLimitMileage > 0 AND @ServiceMiles > @PrimaryCoverageLimitMileage
		INSERT INTO #PODetail
		SELECT VendorLocationID
			,ProductID
			,ProductName
			,RateTypeID
			,RateTypeName
			,Sequence
			,ContractedRate
			,RatePrice
			,RateQuantity
			,UnitOfMeasure
			,UnitOfMeasureSource
			,(@ServiceMiles - @PrimaryCoverageLimitMileage) Quantity
			,(@ServiceMiles - @PrimaryCoverageLimitMileage) * RatePrice ExtendedAmount
			,IsMemberPay = 1
		FROM #PODetail 
		WHERE RateTypeName = 'Service'
		ORDER BY Sequence

	SELECT 
		VendorLocationID
		,ProductID
		,ProductName
		,RateTypeID
		,RateTypeName
		,Sequence
		,ContractedRate
		,RatePrice
		,RateQuantity
		,UnitOfMeasure
		,UnitOfMeasureSource
		,Quantity
		,ExtendedAmount
		,IsMemberPay 
	FROM #PODetail
	ORDER BY Sequence

	DROP TABLE #PODetail
	

END

GO
GO