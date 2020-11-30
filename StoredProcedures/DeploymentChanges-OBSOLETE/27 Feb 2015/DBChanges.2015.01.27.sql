
ALTER TABLE DocumentCategory 
ADD IsShownOnVendorPortal bit null

Update DocumentCategory SET IsShownOnVendorPortal = 1 where Name <> 'CoachingConcern'
