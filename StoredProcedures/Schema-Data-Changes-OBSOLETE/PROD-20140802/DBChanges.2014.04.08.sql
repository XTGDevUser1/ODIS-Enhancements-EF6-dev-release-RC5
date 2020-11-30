update template set body = '${FaxFailureReason}; SR-${ServiceRequest}; PO-${PONumber}' where name = 'PO_Fax_Failure_Notification'

update template set body = '[${SentFrom}] ${MessageText}' where name = 'ManualNotification'

update template set body = '[${SentFrom}] SR-${RequestNumber}: ${MessageText}' where name = 'LockedRequestComment'
GO

sp_RENAME 'PurchaseOrder.DipatchFeeBillToID', 'DispatchFeeBillToID' , 'COLUMN'
GO
 
ALTER TABLE PurchaseOrder
ADD IsServiceCoveredOverridden BIT NULL
GO
