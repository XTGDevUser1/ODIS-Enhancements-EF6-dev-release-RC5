-- Extending AccessControlList by ClientTypeID

ALTER TABLE AccessControlList
ADD ClientTypeID INT NULL 
REFERENCES ClientType (ID) 