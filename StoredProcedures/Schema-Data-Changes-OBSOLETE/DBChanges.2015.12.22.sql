
ALTER TABLE ProductCategory
ADD IsShownOnScreen  BIT NULL

UPDATE ProductCategory SET IsShownOnScreen = 1 where Name IN ('Tow','Tire','Lockout','Fluid','Jump','Winch','Tech','Mobile','Info','Concierge','Home Locksmith')
UPDATE ProductCategory SET IsShownOnScreen = 0 where Name IN ('Repair','Billing','MemberProduct','ISPSelection')
