--
-- ODIS Application
-- DMS Database
/* Remove production values from Test/Training DB */
--
--

-- Set all Fax numbers to Martex Fax Number
Update PhoneEntity Set PhoneNumber = '1 8176334551' Where PhoneTypeID = (Select ID from PhoneType where Name = 'Fax')

-- Update existing PO's fax and email address
Update PurchaseOrder Set FaxPhoneNumber = '1 8176334551' 
Update PurchaseOrder Set Email = 'noreply@nmc.com' 

--Clear Vendor emails	
Update Vendor Set Email = 'noreply@nmc.com' where ISNULL(Email,'') <> '' and ISNULL(Email,'') <> 'noreply@nmc.com'

--Clear VendorLocation emails
Update VendorLocation Set Email = 'noreply@nmc.com' where ISNULL(Email,'') <> '' and ISNULL(Email,'') <> 'noreply@nmc.com'

-- Clear Member Emails
Update Member Set Email = 'noreply@nmc.com' where ISNULL(Email,'') <> '' and ISNULL(Email,'') <> 'noreply@nmc.com'

--Disable Closed Loop Phone
Update ApplicationConfiguration Set Value = NULL where Name = 'PhoneHTTPTrigger'

--Disable Closed Loop SMS
Update ApplicationConfiguration Set Value = NULL where Name = 'SMSServiceURI'

--Remove event subscription email address to prevent these from going out
Update EventSubscription Set Email = NULL ---'rhancock@nmc.com' where isnull(email,'')<>''

--Change email addresses on Feedback
Update FeedbackType set NotificationEmail = 'rhancock@nmc.com,vreed.com'

--Select * from [Case] where AssignedToUserID IS NULL


----------------------------------
-- Verify Changes are in place
select distinct phonenumber from phoneentity where phonetypeid = (Select ID from PhoneType where Name = 'Fax')
select distinct faxphonenumber from purchaseorder 
select distinct email from Vendor
select distinct email from VendorLocation
select distinct email from Member
select * from ApplicationConfiguration where Name = 'PhoneHTTPTrigger'
select * from ApplicationConfiguration where Name = 'SMSServiceURI'
select * from EventSubscription
select * from FeedbackType



----Clear Vendor fax numbers
--Select *
----Update pe Set pe.PhoneNumber = '1 8176334551'
--From Vendor v
--Join PhoneEntity pe on pe.EntityID = (Select ID From Entity where Name = 'Vendor')
--	and pe.RecordID = v.ID
--	and pe.PhoneTypeID = (Select ID from PhoneType where Name = 'Fax')
--	and ISNULL(pe.PhoneNumber, '') <> '1 8176334551'
--	and ISNULL(pe.PhoneNumber, '') <> ''

----Clear Vendor Location fax numbers
--Select *
----Update pe Set pe.PhoneNumber = '1 8176334551'
--From VendorLocation vl 
--Join PhoneEntity pe on pe.EntityID = (Select ID From Entity where Name = 'VendorLocation')
--	and pe.RecordID = vl.ID
--	and pe.PhoneTypeID = (Select ID from PhoneType where Name = 'Fax')
--	and ISNULL(pe.PhoneNumber, '') <> '1 8176334551'
--	and ISNULL(pe.PhoneNumber, '') <> ''