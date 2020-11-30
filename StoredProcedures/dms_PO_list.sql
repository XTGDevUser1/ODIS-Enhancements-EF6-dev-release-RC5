IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_PO_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_PO_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
 --EXEC [dbo].[dms_PO_list] @serviceRequestID = 1414, @sortColumn='PurchaseOrderPayStatusCode', @sortOrder = 'ASC'
 CREATE PROCEDURE [dbo].[dms_PO_list]( 
  @serviceRequestID INT = NULL
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON
 	
 	CREATE TABLE #tmpPODetails 	
 	(
 		ID INT NULL,
 		PONumber NVARCHAR(50) NULL,
 		PODate DATETIME NULL,
 		VendorName NVARCHAR(255) NULL,
 		POTotal MONEY NULL,
 		[Service] NVARCHAR(200) NULL,
 		POStatus NVARCHAR(50) NULL,
 		CancelReason NVARCHAR(255) NULL,
 		DataTransferDate DATETIME NULL,
 		ModifyDate DATETIME NULL,
 		OriginalPONumber NVARCHAR(50) NULL 	,
 		
 		InvoiceNumber nvarchar(100)  NULL ,
		InvoiceDate datetime  NULL ,
		InvoiceAmount money  NULL ,
		InvoiceStatus nvarchar(100)  NULL ,
		PaymentNumber nvarchar(100)  NULL ,
		PaymentDate datetime  NULL ,
		PaymentAmount money  NULL ,
		CheckClearedDate datetime  NULL ,
		InvoiceReceivedDate datetime NULL ,
		InvoiceReceiveMethod nvarchar(100) NULL ,
		InvoiceToBePaidDate datetime NULL,
		PurchaseOrderPayStatusCode nvarchar(255) NULL 	
 	)
 	
 	SET FMTONLY OFF;
 	
	INSERT INTO #tmpPODetails
	SELECT	  po.ID as ID
			, po.PurchaseOrderNumber as PONumber
			, po.IssueDate as PODate
			, v.Name as VendorName
			, po.TotalServiceAmount as POTotal
			, pc.[Description] as [Service]
			, pos.Name as POStatus
			--, cr.[Description] as CancelReason
			, CASE	WHEN po.CancellationReasonOther <> '' THEN po.CancellationReasonOther  
					WHEN po.GOAReasonOther <> '' THEN po.GOAReasonOther   
					ELSE cr.[Description]  
				END as CancelReason
			, po.DataTransferDate
			, po.ModifyDate
			,poo.PurchaseOrderNumber as OriginalPONumber
			, VI.InvoiceNumber
			, VI.InvoiceDate
			, VI.InvoiceAmount
			, VIS.Name AS [InvoiceStatus]
			--, VI.PaymentNumber
			,CASE 
			WHEN VI.PaymentTypeID = (SELECT ID From PaymentType WHERE Name = 'ACH') 
			THEN 'ACH' 
			ELSE VI.PaymentNumber
			END AS PaymentNumber
			, VI.PaymentDate 
			, VI.PaymentAmount 
			, VI.CheckClearedDate
			, VI.ReceivedDate
			, CM.Name
			, VI.ToBePaidDate
			,pops.[Description]
	FROM	PurchaseOrder po WITH (NOLOCK)
	LEFT OUTER JOIN PurchaseOrder poo WITH (NOLOCK) on poo.ID=po.OriginalPurchaseOrderID
	JOIN VendorLocation vl WITH (NOLOCK) on vl.ID = po.VendorLocationID
	JOIN Vendor v WITH (NOLOCK) on v.ID = vl.VendorID
	--Join PurchaseOrderDetail pod on pod.PurchaseOrderID = po.ID 
	--and pod.Sequence = 1
	--LEFT OUTER Join Product p on p.ID = pod.ProductID 
	LEFT OUTER JOIN Product p WITH (NOLOCK) on p.ID = po.ProductID 
	LEFT OUTER JOIN ProductCategory pc WITH (NOLOCK) on pc.ID = p.ProductCategoryID
	JOIN PurchaseOrderStatus pos WITH (NOLOCK) on pos.ID = po.PurchaseOrderStatusID
	LEFT JOIN PurchaseOrderPayStatusCode pops WITH (NOLOCK) on pops.ID = po.PayStatusCodeID
	LEFT JOIN PurchaseOrderCancellationReason cr WITH (NOLOCK) on cr.ID = po.CancellationReasonID
	LEFT OUTER JOIN VendorInvoice VI ON VI.PurchaseOrderID = PO.ID 
	LEFT OUTER JOIN VendorInvoiceStatus VIS ON VIS.ID = VI.VendorInvoiceStatusID 	
	LEFT OUTER JOIN ContactMethod CM ON CM.ID=VI.ReceiveContactMethodID
	WHERE	po.ServiceRequestID = @serviceRequestID and (po.IsActive = 1 or po.IsActive IS NULL )

SELECT W.*
FROM #tmpPODetails W
 ORDER BY 
     CASE WHEN @sortColumn IS NULL
     THEN W.ID END DESC,
	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'
	 THEN W.PONumber END ASC, 
	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'
	 THEN W.PONumber END DESC ,

	 CASE WHEN @sortColumn = 'PODate' AND @sortOrder = 'ASC'
	 THEN W.PODate END ASC, 
	 CASE WHEN @sortColumn = 'PODate' AND @sortOrder = 'DESC'
	 THEN W.PODate END DESC ,

	 CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'ASC'
	 THEN W.VendorName  END ASC, 
	 CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'DESC'
	 THEN W.VendorName  END DESC ,

	 CASE WHEN @sortColumn = 'POTotal' AND @sortOrder = 'ASC'
	 THEN W.POTotal END ASC, 
	 CASE WHEN @sortColumn = 'POTotal' AND @sortOrder = 'DESC'
	 THEN W.POTotal END DESC ,

	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'ASC'
	 THEN W.[Service] END ASC, 
	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'DESC'
	 THEN W.[Service] END DESC ,

	 CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'ASC'
	 THEN W.POStatus END ASC, 
	 CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'DESC'
	 THEN W.POStatus END DESC ,

	 CASE WHEN @sortColumn = 'CancelReason' AND @sortOrder = 'ASC'
	 THEN W.CancelReason END ASC, 
	 CASE WHEN @sortColumn = 'CancelReason' AND @sortOrder = 'DESC'
	 THEN W.CancelReason END DESC ,
	 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN W.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN W.InvoiceNumber END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'ASC'
	 THEN W.InvoiceDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'DESC'
	 THEN W.InvoiceDate END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'
	 THEN W.InvoiceAmount END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'
	 THEN W.InvoiceAmount END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'ASC'
	 THEN W.InvoiceStatus END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'DESC'
	 THEN W.InvoiceStatus END DESC ,

	 CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'ASC'
	 THEN W.PaymentNumber END ASC, 
	 CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'DESC'
	 THEN W.PaymentNumber END DESC ,

	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'ASC'
	 THEN W.PaymentDate END ASC, 
	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'DESC'
	 THEN W.PaymentDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'
	 THEN W.PaymentAmount END ASC, 
	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'
	 THEN W.PaymentAmount END DESC ,

	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'ASC'
	 THEN W.CheckClearedDate END ASC, 
	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'DESC'
	 THEN W.CheckClearedDate END DESC  ,

	 CASE WHEN @sortColumn = 'InvoiceReceivedDate' AND @sortOrder = 'ASC'
	 THEN W.InvoiceReceivedDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceReceivedDate' AND @sortOrder = 'DESC'
	 THEN W.InvoiceReceivedDate END DESC,

	 CASE WHEN @sortColumn = 'InvoiceReceiveMethod' AND @sortOrder = 'ASC'
	 THEN W.InvoiceReceiveMethod END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceReceiveMethod' AND @sortOrder = 'DESC'
	 THEN W.InvoiceReceiveMethod END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceToBePaidDate' AND @sortOrder = 'ASC'
	 THEN W.InvoiceToBePaidDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceToBePaidDate' AND @sortOrder = 'DESC'
	 THEN W.InvoiceToBePaidDate END DESC, 
	 
	 CASE WHEN @sortColumn = 'PurchaseOrderPayStatusCode' AND @sortOrder = 'ASC'
	 THEN W.PurchaseOrderPayStatusCode END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderPayStatusCode' AND @sortOrder = 'DESC'
	 THEN W.PurchaseOrderPayStatusCode END DESC 
	 
	DROP TABLE #tmpPODetails	 

END 
	 
	