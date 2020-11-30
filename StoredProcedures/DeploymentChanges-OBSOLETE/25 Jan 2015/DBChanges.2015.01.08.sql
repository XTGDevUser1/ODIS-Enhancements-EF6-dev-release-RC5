IF NOT EXISTS(SELECT * FROM Entity WHERE Name = 'Document')
BEGIN
	INSERT INTO Entity VALUES('Document',0)
END

IF NOT EXISTS(SELECT * FROM EventCategory WHERE Name = 'VendorPortal')
BEGIN
	INSERT INTO EventCategory VALUES('VendorPortal','Vendor Portal',NULL,1)
END

IF NOT EXISTS(SELECT * FROM Event WHERE Name  = 'UploadDocument' AND EventCategoryID = (SELECT ID FROM  EventCategory WHERE Name  = 'VendorPortal'))
BEGIN
	INSERT INTO Event VALUES(
	(SELECT ID FROM EventType WHERE Name  = 'User'),
	(SELECT ID FROM  EventCategory WHERE Name  = 'VendorPortal'),
	'UploadDocument',
	'Vendor Uploaded Document',
	1,
	1,
	'System',
	GETDATE()
	)
END


IF NOT EXISTS (SELECT ID FROM Template WHERE Name = 'VendorPortal_UploadDocument')
BEGIN
INSERT Template (Name, Subject, Body, IsActive, CreateDate, CreateBy, ModifyDate, ModifyBy)
VALUES ('VendorPortal_UploadDocument', NULL, 'Vendor:${VendorNumber} uploaded a document', 1, GETDATE(), 'system', NULL, NULL)
END

IF NOT EXISTS (SELECT * FROM ContactReason WHERE ContactCategoryID = (SELECT  ID FROM ContactCategory WHERE Name = 'VendorPortal') AND Name = 'UploadDocument')
BEGIN
	INSERT INTO ContactReason VALUES((SELECT  ID FROM ContactCategory WHERE Name = 'VendorPortal'),'UploadDocument','Vendor Uploaded Document',1,1,
	(SELECT MAX(Sequence) FROM ContactReason))
END

IF NOT EXISTS (SELECT * FROM ContactAction WHERE ContactCategoryID = (SELECT  ID FROM ContactCategory WHERE Name = 'VendorPortal') AND Name = 'NotifyVendorRepForUploadDocument')
BEGIN
	INSERT INTO ContactAction VALUES(
	(SELECT  ID FROM ContactCategory WHERE Name = 'VendorPortal'),
	'NotifyVendorRepForUploadDocument',
	'Notifying VendorRep When Document Uplaoded',1,1,1,NULL,NULL
	)
END

IF NOT EXISTS (SELECT * FROM ContactSource WHERE Name = 'VendorData' AND ContactCategoryID  = (SELECT ID FROM ContactCategory WHERE Name  = 'VendorPortal'))
BEGIN
	INSERT INTO ContactSource VALUES((SELECT ID FROM ContactCategory WHERE Name  = 'VendorPortal'),'VendorData','VendorData',1,1)
END

